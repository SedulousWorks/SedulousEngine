using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Messaging;

namespace Sedulous.Scene;

/// An isolated world of entities with a transform hierarchy and its own systems.
///
/// Two parallel pools indexed by the same entity slot:
///
///   the entity table       generation guarded, reusing slots through a free list, with a
///                          persistent id to handle map and the active and name state.
///   the transform tree     a local TRS and cached world matrix per entity, in a doubly
///                          linked parent, child and sibling tree spliced in O(1), with a
///                          dirty cascade and a two pass update that snapshots the previous
///                          world matrix and recomputes only dirty subtrees.
///
/// Destruction is recursive, children first. A destroy asked for DURING an update is
/// deferred to the frame's cleanup, so iteration stays stable.
class Scene
{
	private String mName = new .() ~ delete _;

	/// The entity pool, indexed by slot, and the transform pool parallel to it.
	private List<EntitySlot> mEntities = new .() ~ DeleteContainerAndItems!(_);
	private List<TransformData> mTransforms = new .() ~ delete _;
	/// Slots free for reuse.
	private List<uint32> mFreeList = new .() ~ delete _;
	private Dictionary<Guid, EntityHandle> mIdMap = new .() ~ delete _;
	private List<uint32> mTransformsUpdatedThisFrame = new .() ~ delete _;

	private EntityHandle mFirstRoot = .Invalid;
	private EntityHandle mLastRoot = .Invalid;

	/// Per scene and DETERMINISTIC, so the same seed reproduces the same ids.
	private Sedulous.Core.Random mRng = .();

	private List<PrefabInstanceState> mPrefabInstances = new .() ~ DeleteContainerAndItems!(_);
	private List<PendingPrefabInstance> mPendingPrefabs = new .() ~ DeleteContainerAndItems!(_);

	private uint32 mAliveCount = 0;
	private uint64 mRevision = 0;

	/// BORROWED from the run scope that injected it. There is no owned fallback: a scope
	/// injects before assembly, so a system binding in OnSceneCreate sees the very bus its
	/// emits land on. Null on a scene with no scope, which never emits.
	private EventBus mEventBus = null;

	private List<SceneSystem> mSystems = new .() ~ DeleteContainerAndItems!(_);
	private Dictionary<uint64, SceneSystem> mSystemsByType = new .() ~ delete _;
	/// Non owning, sorted by UpdateOrder.
	private List<SceneSystem> mSortedSystems = new .() ~ delete _;

	private List<UnresolvedComponent> mUnresolvedComponents = new .() ~ DeleteContainerAndItems!(_);
	private List<UnresolvedSettings> mUnresolvedSettings = new .() ~ DeleteContainerAndItems!(_);
	private List<EntityHandle> mPendingDestroys = new .() ~ delete _;

	private bool mIsUpdating = false;
	private bool mStarted = false;
	private bool mSimulationEnabled = true;
	private float mTimeScale = 1.0f;
	private FixedStepper mStepper = .();
	private float mFixedAlpha = 0.0f;

	public this(StringView name = default)
	{
		mName.Set(name);
	}

	public StringView Name => mName;
	public void SetName(StringView name) => mName.Set(name);

	public uint32 EntityCount => mAliveCount;

	/// Bumped by every structural change, so a consumer can tell "nothing moved" from
	/// "something did" without diffing anything.
	public uint64 Revision => mRevision;

	// ---- entity lifecycle ----

	/// A new entity with a fresh id: a root, active, at the identity transform.
	public EntityHandle CreateEntity(StringView name = default)
	{
		// The generator is deterministic and LOADING does not advance it past the entities
		// it loaded, so a fresh id can land on one already in the scene. Re-roll until it
		// is free: two entities sharing an id corrupts a save.
		var id = Guid.Generate(ref mRng);
		while (FindEntity(id).IsAssigned)
			id = Guid.Generate(ref mRng);
		return CreateEntityInternal(id, name);
	}

	/// A new entity with a SPECIFIC id, which is what loading a scene from disk needs.
	public EntityHandle CreateEntity(Guid id, StringView name = default)
		=> CreateEntityInternal(id, name);

	/// Destroys an entity and its whole subtree. A no op for a stale handle.
	///
	/// Called DURING an update, by a system destroying entities, it is deferred to the
	/// frame's cleanup so whatever is iterating stays on solid ground.
	public void DestroyEntity(EntityHandle entity)
	{
		if (!IsValid(entity))
			return;

		if (mIsUpdating)
		{
			mPendingDestroys.Add(entity);
			return;
		}
		DestroyEntityImmediate(entity);
	}

	public bool IsValid(EntityHandle entity)
	{
		if (!entity.IsAssigned || (entity.Index >= (uint32)mEntities.Count))
			return false;
		let slot = mEntities[entity.Index];
		return slot.Alive && (slot.Generation == entity.Generation);
	}

	public Guid GetEntityId(EntityHandle entity)
		=> IsValid(entity) ? mEntities[entity.Index].PersistentId : Guid();

	public EntityHandle FindEntity(Guid id)
	{
		if (!mIdMap.TryGetValue(id, let found))
			return .Invalid;
		if (IsValid(found))
			return found;

		// The map outlived the entity: drop the entry rather than answer with it.
		mIdMap.Remove(id);
		return .Invalid;
	}

	public StringView GetEntityName(EntityHandle entity)
		=> IsValid(entity) ? mEntities[entity.Index].Name : default;

	public void SetEntityName(EntityHandle entity, StringView name)
	{
		if (!IsValid(entity))
			return;
		mEntities[entity.Index].Name.Set(name);
		mRevision++;
	}

	public bool IsActive(EntityHandle entity) => IsValid(entity) && mEntities[entity.Index].Active;

	/// The EFFECTIVE state: this entity's own flag AND every ancestor's.
	///
	/// O(1), because the bit is cached and recomputed only where it can change. ALL runtime
	/// gating reads this and never IsActive: deactivating a parent must dark the whole
	/// subtree without touching any child's own flag.
	public bool IsEffectivelyActive(EntityHandle entity)
		=> IsValid(entity) && mEntities[entity.Index].EffectiveActive;

	public void SetActive(EntityHandle entity, bool active)
	{
		if (!IsValid(entity))
			return;
		if (mEntities[entity.Index].Active == active)
			return;

		mEntities[entity.Index].Active = active;
		// Settle the cache BEFORE notifying, so a listener asking IsEffectivelyActive from
		// the hook sees the new truth. The hook itself only reports an own flag change: it
		// is not the gating mechanism, which is the poll above.
		RefreshEffectiveActive(entity);
		mRevision++;

		for (let system in mSortedSystems)
			system.OnEntityActiveChanged(entity, active);
	}

	/// Visits every live entity, in slot order.
	public void ForEachEntity(delegate void(EntityHandle) fn)
	{
		for (uint32 i < (uint32)mEntities.Count)
		{
			if (mEntities[i].Alive)
				fn(.(i, mEntities[i].Generation));
		}
	}

	// ---- naming and lookup ----

	/// The first live entity with this exact name, in slot order. Names are NOT unique, so
	/// this is a convenience: prefer FindEntity by id for identity.
	public EntityHandle FindEntityByName(StringView name)
	{
		for (uint32 i < (uint32)mEntities.Count)
		{
			if (mEntities[i].Alive && (mEntities[i].Name == name))
				return .(i, mEntities[i].Generation);
		}
		return .Invalid;
	}

	/// The direct child of `parent` with this name, in sibling order. An invalid parent
	/// means the scene's roots.
	public EntityHandle FindChildByName(EntityHandle parent, StringView name)
	{
		var child = parent.IsAssigned ? GetFirstChild(parent) : mFirstRoot;
		while (child.IsAssigned && IsValid(child))
		{
			if (GetEntityName(child) == name)
				return child;
			child = GetNextSibling(child);
		}
		return .Invalid;
	}

	/// Resolves a slash separated path from the roots, such as "Player/Weapon/Muzzle".
	///
	/// Empty, leading, trailing and doubled separators are tolerated, because a path
	/// assembled by concatenation grows them and refusing would be pedantry. Each segment
	/// matches a child at that depth; a miss anywhere gives an invalid handle.
	public EntityHandle FindEntityByPath(StringView path)
	{
		var current = EntityHandle.Invalid;
		var matchedAny = false;
		int begin = 0;

		for (int i = 0; i <= path.Length; i++)
		{
			if ((i != path.Length) && (path[i] != '/'))
				continue;

			let segment = path.Substring(begin, i - begin);
			begin = i + 1;
			if (segment.IsEmpty)
				continue;

			current = FindChildByName(current, segment);
			if (!current.IsAssigned)
				return .Invalid;
			matchedAny = true;
		}
		return matchedAny ? current : .Invalid;
	}

	// ---- prefab instances ----
	//
	// Runtime bookkeeping only. Scene.Resource drives it; the scene just holds it, because
	// the scene is what owns the entities the records point at.

	/// Takes ownership of one instance's state.
	public void AddPrefabInstance(PrefabInstanceState state)
	{
		if (state != null)
			mPrefabInstances.Add(state);
	}

	/// The instance whose root is `rootEntityId`, or null.
	///
	/// BORROWED, and only until the instance is torn down. A rebuild, a revert or a
	/// snapshot restore destroys and recreates these, so hold the root GUID across one of
	/// those and ask again. Same discipline as an entity: keep the id, not the pointer.
	public PrefabInstanceState FindPrefabInstanceByRoot(Guid rootEntityId)
	{
		for (let state in mPrefabInstances)
		{
			if (state.RootEntityId == rootEntityId)
				return state;
		}
		return null;
	}

	/// Drops the state whose root is `rootEntityId`. The ENTITIES are the caller's
	/// business: this is bookkeeping, not a destroy.
	public void RemovePrefabInstance(Guid rootEntityId)
	{
		for (int i = 0; i < mPrefabInstances.Count; i++)
		{
			if (mPrefabInstances[i].RootEntityId == rootEntityId)
			{
				delete mPrefabInstances[i];
				mPrefabInstances.RemoveAt(i);
				return;
			}
		}
	}

	/// Visits every instance whose ROOT still resolves, PRUNING as it goes: a state whose
	/// root entity was destroyed is dropped here rather than through a destroy hook, so
	/// nothing has to be kept in step.
	public void ForEachPrefabInstance(delegate void(PrefabInstanceState) fn)
	{
		int write = 0;
		for (int i = 0; i < mPrefabInstances.Count; i++)
		{
			if (!FindEntity(mPrefabInstances[i].RootEntityId).IsAssigned)
			{
				delete mPrefabInstances[i];
				continue;
			}
			if (write != i)
				mPrefabInstances[write] = mPrefabInstances[i];
			fn(mPrefabInstances[write]);
			write++;
		}
		mPrefabInstances.Count = write;
	}

	public int PrefabInstanceCount => mPrefabInstances.Count;

	/// Drops ALL instance bookkeeping. Restoring a snapshot repopulates it from the stream.
	public void ClearPrefabInstances() => ClearAndDeleteItems!(mPrefabInstances);

	public void AddPendingPrefabInstance(PendingPrefabInstance pending)
	{
		if (pending != null)
			mPendingPrefabs.Add(pending);
	}

	/// Moves out every parked descriptor; the caller owns what it gets.
	public void TakePendingPrefabInstances(List<PendingPrefabInstance> outPending)
	{
		outPending.AddRange(mPendingPrefabs);
		mPendingPrefabs.Clear();
	}

	public int PendingPrefabInstanceCount => mPendingPrefabs.Count;

	/// A NON consuming walk of the parked descriptors, so a load then save with no resolve
	/// in between re-emits them verbatim and stays lossless.
	public void ForEachPendingPrefabInstance(delegate void(PendingPrefabInstance) fn)
	{
		for (let pending in mPendingPrefabs)
		{
			if (pending != null)
				fn(pending);
		}
	}

	// ---- transform hierarchy ----

	public void SetLocalTransform(EntityHandle entity, Transform transform)
	{
		if (!IsValid(entity))
			return;
		mTransforms[entity.Index].Local = transform;
		MarkDirty(entity);
	}

	public Transform GetLocalTransform(EntityHandle entity)
		=> IsValid(entity) ? mTransforms[entity.Index].Local : Transform();

	public void SetLocalPosition(EntityHandle entity, Float3 position)
	{
		if (!IsValid(entity))
			return;
		mTransforms[entity.Index].Local.Position = position;
		MarkDirty(entity);
	}

	/// The world matrix from the most recent UpdateTransforms. Identity until the first one.
	public Float4x4 GetWorldMatrix(EntityHandle entity)
		=> IsValid(entity) ? mTransforms[entity.Index].WorldMatrix : Float4x4.Identity();

	public Float4x4 GetPrevWorldMatrix(EntityHandle entity)
		=> IsValid(entity) ? mTransforms[entity.Index].PrevWorldMatrix : Float4x4.Identity();

	/// The translation ROW of the world matrix, this being a row vector convention.
	public Float3 GetWorldPosition(EntityHandle entity)
	{
		let world = GetWorldMatrix(entity);
		return .(world.M[3][0], world.M[3][1], world.M[3][2]);
	}

	/// Whether the world matrix was recomputed in the most recent UpdateTransforms: it
	/// moved, was reparented, or a dirty ancestor cascaded through it. Read in
	/// PostTransform.
	public bool IsTransformUpdatedThisFrame(EntityHandle entity)
		=> IsValid(entity) && mTransforms[entity.Index].UpdatedThisFrame;

	public EntityHandle GetParent(EntityHandle entity)
		=> IsValid(entity) ? mTransforms[entity.Index].Parent : .Invalid;

	/// The first entity in the ROOT sibling list. Walk it with GetNextSibling for list
	/// order, which is the order the hierarchy shows and serialization preserves.
	public EntityHandle FirstRoot => mFirstRoot;

	public EntityHandle GetFirstChild(EntityHandle entity)
		=> IsValid(entity) ? mTransforms[entity.Index].FirstChild : .Invalid;

	public EntityHandle GetNextSibling(EntityHandle entity)
		=> IsValid(entity) ? mTransforms[entity.Index].NextSibling : .Invalid;

	public uint32 GetChildCount(EntityHandle entity)
	{
		if (!IsValid(entity))
			return 0;

		uint32 count = 0;
		var child = mTransforms[entity.Index].FirstChild;
		while (child.IsAssigned && IsValid(child))
		{
			count++;
			child = mTransforms[child.Index].NextSibling;
		}
		return count;
	}

	/// Reparents `child` under `parent`, appending at the END of its children. An invalid
	/// parent makes it a root, and passing the parent it already has re-appends it, so this
	/// doubles as move to end.
	///
	/// A reparent that would form a CYCLE is refused rather than corrupting the tree.
	public void SetParent(EntityHandle child, EntityHandle parent)
	{
		if (!IsValid(child))
			return;
		if (parent.IsAssigned && !IsValid(parent))
			return;
		if (child == parent)
			return;
		if (parent.IsAssigned && IsDescendantOf(parent, child))
			return;

		RemoveFromParent(child);
		mTransforms[child.Index].Parent = parent;
		if (parent.IsAssigned)
			AppendToList(child, ref mTransforms[parent.Index].FirstChild,
				ref mTransforms[parent.Index].LastChild);
		else
			AppendToList(child, ref mFirstRoot, ref mLastRoot);

		MarkDirty(child);
		// The ancestor chain changed, so the subtree's effective state has to resettle.
		RefreshEffectiveActive(child);
		mRevision++;
	}

	/// The editor's reparent: the entity STAYS PUT in the world and its local transform is
	/// recomputed against the new parent.
	///
	/// The world matrices are composed fresh from the local chain rather than read from the
	/// cache, so this is right even when the cached transforms are dirty. A refused move
	/// changes nothing.
	public void SetParent(EntityHandle child, EntityHandle parent, bool keepWorldTransform)
	{
		if (!keepWorldTransform)
		{
			SetParent(child, parent);
			return;
		}
		if (!IsValid(child))
			return;

		let childWorld = ComposeWorldMatrix(child);
		let before = mRevision;
		SetParent(child, parent);
		if (mRevision != before)
			ApplyWorldAsLocal(child, childWorld);
	}

	/// Sibling ORDERING: moves `child` under `sibling`'s parent, immediately before it, or
	/// into the root list when `sibling` is a root. Same guards as SetParent, and O(1).
	public void MoveBefore(EntityHandle child, EntityHandle sibling)
	{
		if (!IsValid(child) || !IsValid(sibling))
			return;
		if (child == sibling)
			return;
		if (mTransforms[sibling.Index].PrevSibling == child)
			return;

		let parent = mTransforms[sibling.Index].Parent;
		if (parent.IsAssigned && IsDescendantOf(parent, child))
			return;

		RemoveFromParent(child);

		let prevOfSibling = mTransforms[sibling.Index].PrevSibling;
		mTransforms[child.Index].Parent = parent;
		mTransforms[child.Index].NextSibling = sibling;
		mTransforms[child.Index].PrevSibling = prevOfSibling;

		if (prevOfSibling.IsAssigned)
			mTransforms[prevOfSibling.Index].NextSibling = child;
		else if (parent.IsAssigned)
			mTransforms[parent.Index].FirstChild = child;
		else
			mFirstRoot = child;

		mTransforms[sibling.Index].PrevSibling = child;

		MarkDirty(child);
		// The splice may have changed the parent as well as the position.
		RefreshEffectiveActive(child);
		mRevision++;
	}

	public void MoveBefore(EntityHandle child, EntityHandle sibling, bool keepWorldTransform)
	{
		if (!keepWorldTransform)
		{
			MoveBefore(child, sibling);
			return;
		}
		if (!IsValid(child))
			return;

		let childWorld = ComposeWorldMatrix(child);
		let before = mRevision;
		MoveBefore(child, sibling);
		if (mRevision != before)
			ApplyWorldAsLocal(child, childWorld);
	}

	/// A world matrix composed FRESH up the parent chain, independent of the cache, which
	/// is only current right after UpdateTransforms.
	public Float4x4 ComposeWorldMatrix(EntityHandle entity)
	{
		var world = Float4x4.Identity();
		var current = entity;
		while (IsValid(current))
		{
			world = world * mTransforms[current.Index].Local.ToMatrix();
			current = mTransforms[current.Index].Parent;
		}
		return world;
	}

	/// The two pass world matrix update.
	///
	/// First clear last frame's updated flags and snapshot the previous world matrix for
	/// anything that STOPPED moving; then recompute the dirty subtrees, parent before
	/// child.
	public void UpdateTransforms()
	{
		let count = (uint32)mTransforms.Count;
		if (count == 0)
			return;

		for (let index in mTransformsUpdatedThisFrame)
		{
			if (index >= (uint32)mTransforms.Count)
				continue;
			mTransforms[index].UpdatedThisFrame = false;
			if (!mTransforms[index].Dirty && mEntities[index].Alive)
				mTransforms[index].PrevWorldMatrix = mTransforms[index].WorldMatrix;
		}
		mTransformsUpdatedThisFrame.Clear();

		// Recurse from every dirty subtree TOP: a dirty entity whose parent is clean, or
		// who has none. MarkDirty propagates downward, so an interior dirty node always has
		// a dirty parent. A freshly REPARENTED entity under a clean parent is a top that a
		// roots only scan misses, and its world matrix would stay stale until something
		// moved the parent, which is how a pasted child ends up drawn at the origin.
		for (uint32 i < count)
		{
			if (!mTransforms[i].Dirty || !mEntities[i].Alive)
				continue;

			let parent = mTransforms[i].Parent;
			if (!parent.IsAssigned)
				UpdateTransformRecursive(i, Float4x4.Identity());
			else if (!mTransforms[parent.Index].Dirty)
				// The parent is clean, so its cached world matrix is current.
				UpdateTransformRecursive(i, mTransforms[parent.Index].WorldMatrix);
		}
	}

	/// The entity indices whose world matrix was recomputed most recently.
	///
	/// LIFETIME HAZARD: an index here may belong to an entity destroyed since, so gate a
	/// read on IsValid. Rewritten every UpdateTransforms.
	public Span<uint32> TransformsUpdatedThisFrame => mTransformsUpdatedThisFrame;

	// ---- per scene systems ----

	/// Constructs and adds a system, one per type, which the scene OWNS. Its OnSceneCreate
	/// runs at once.
	public T AddSystem<T>() where T : SceneSystem, new, delete
	{
		let system = new T();
		mSystems.Add(system);
		mSystemsByType[TypeKey<T>()] = system;
		InsertSortedSystem(system);
		system.OnSceneCreate(this);
		return system;
	}

	public T GetSystem<T>() where T : SceneSystem
	{
		if (mSystemsByType.TryGetValue(TypeKey<T>(), let found))
			return (T)found;
		return null;
	}

	public bool HasSystem<T>() where T : SceneSystem => mSystemsByType.ContainsKey(TypeKey<T>());

	/// Every system, managers and plain alike, in UpdateOrder. What a settings inspector
	/// and a scene save both walk.
	public Span<SceneSystem> Systems => mSortedSystems;

	/// Visits every component manager, in UpdateOrder.
	public void ForEachManager(delegate void(ComponentManagerBase) fn)
	{
		for (let system in mSortedSystems)
		{
			if (let manager = system.AsComponentManager)
				fn(manager);
		}
	}

	/// The serializable manager with this id on disk, or null. What routes a component
	/// record back to its pool on load.
	public ComponentManagerBase FindManagerBySerializationId(StringView typeId)
	{
		for (let system in mSortedSystems)
		{
			if (let manager = system.AsComponentManager)
			{
				if (manager.IsSerializable && (manager.SerializationTypeId == typeId))
					return manager;
			}
		}
		return null;
	}

	/// The manager storing `componentType`, or null.
	///
	/// This is the scene side of "get this entity's component of that type": a caller holds
	/// the scene, the entity and the manager, and re-resolves the LIVE component on every
	/// access. Never a stashed component pointer: the pool swap removes, so an address can
	/// move or, worse, come to point at a different entity's component. The MANAGER pointer
	/// is scene owned and stable for the scene's life, so this lookup happens once.
	public ComponentManagerBase FindManagerByComponentType(Type componentType)
	{
		for (let system in mSortedSystems)
		{
			if (let manager = system.AsComponentManager)
			{
				if (manager.ComponentType == componentType)
					return manager;
			}
		}
		return null;
	}

	/// Removes and destroys the system registered under `systemType`; a manager's pool dies
	/// with it. Returns whether there was one.
	///
	/// The hot reload seam: a plugin contributed manager leaves a live scene BEFORE its
	/// module's registrations reverse, while the code that built it is still mapped.
	public bool RemoveSystem(uint64 systemType)
	{
		if (!mSystemsByType.TryGetValue(systemType, let system))
			return false;

		mSystemsByType.Remove(systemType);
		mSortedSystems.Remove(system);
		if (mSystems.Remove(system))
			delete system;
		return true;
	}

	public bool RemoveSystem<T>() where T : SceneSystem => RemoveSystem(TypeKey<T>());

	// ---- records awaiting the code that understands them ----

	public void AddUnresolvedComponent(UnresolvedComponent record)
		=> mUnresolvedComponents.Add(record);

	public Span<UnresolvedComponent> UnresolvedComponents => mUnresolvedComponents;

	/// Moves out every record for `typeId`; the caller takes ownership of what it gets.
	public void TakeUnresolvedComponents(StringView typeId, List<UnresolvedComponent> outRecords)
	{
		for (int i = mUnresolvedComponents.Count - 1; i >= 0; i--)
		{
			if (mUnresolvedComponents[i].TypeId == typeId)
			{
				outRecords.Add(mUnresolvedComponents[i]);
				mUnresolvedComponents.RemoveAt(i);
			}
		}
	}

	public void ClearUnresolvedComponents() => ClearAndDeleteItems!(mUnresolvedComponents);

	public void AddUnresolvedSettings(UnresolvedSettings record) => mUnresolvedSettings.Add(record);

	public Span<UnresolvedSettings> UnresolvedSettingsRecords => mUnresolvedSettings;

	/// Moves out the record for `systemId`, if there is one. Ownership goes with it.
	public UnresolvedSettings TakeUnresolvedSettings(StringView systemId)
	{
		for (int i = 0; i < mUnresolvedSettings.Count; i++)
		{
			if (mUnresolvedSettings[i].SystemId == systemId)
			{
				let record = mUnresolvedSettings[i];
				mUnresolvedSettings.RemoveAt(i);
				return record;
			}
		}
		return null;
	}

	// ---- events ----

	/// This scene's bus: the BORROWED scope bus, so a scene's emit and the run's bus are
	/// the same object and there is no relay to cross. Null on a scene with no scope.
	public EventBus Events => mEventBus;

	/// Borrows a scope's bus. The owning scope drains it, not the scene. Set before the
	/// scene ticks; null clears it.
	public void SetEventBus(EventBus bus) => mEventBus = bus;

	// ---- play and edit state ----

	public bool IsStarted => mStarted;
	public bool SimulationEnabled => mSimulationEnabled;
	public void SetSimulationEnabled(bool enabled) => mSimulationEnabled = enabled;

	// ---- per scene time ----

	/// Each scene owns its time scale and its accumulator, so pausing or slowing one scene
	/// never touches another beside it.
	public float TimeScale
	{
		get => mTimeScale;
		set => mTimeScale = (value < 0.0f) ? 0.0f : value;
	}

	/// The fixed lane's step and its spiral of death clamp.
	public void SetFixedTiming(float step, uint32 maxSteps)
	{
		mStepper.Step = step;
		mStepper.MaxSteps = maxSteps;
	}

	public float FixedTimeStep => mStepper.Step;

	/// The interpolation weight for a fixed rate consumer, such as physics pose smoothing.
	/// Published by AdvanceTime after its steps.
	public float FixedAlpha => mFixedAlpha;

	/// The frame drive: accumulate `scaledDelta`, which is already context and scene
	/// scaled, run a fixed update per whole step, and publish the leftover as FixedAlpha.
	/// A test wanting exact control calls FixedUpdate itself.
	public uint32 AdvanceTime(float scaledDelta)
	{
		let steps = mStepper.Advance(scaledDelta);
		for (uint32 i < steps)
			FixedUpdate(mStepper.Step);
		mFixedAlpha = mStepper.Alpha;
		return steps;
	}

	/// Enters play: simulation on, systems told.
	public void Start()
	{
		if (mStarted)
			return;

		// Authored locals become world matrices BEFORE a system hears about it: world
		// matrices are identity until the first update, and a start callback that samples
		// them, building a physics body or reading a spawn point, must see the authored
		// layout rather than everything piled at the origin.
		UpdateTransforms();

		mStarted = true;
		mSimulationEnabled = true;
		for (let system in mSortedSystems)
			system.OnSceneStarted();
	}

	public void Stop()
	{
		if (!mStarted)
			return;
		for (let system in mSortedSystems)
			system.OnSceneStopped();
		mStarted = false;
	}

	// ---- the update loop ----

	/// One frame: pending component initialisation, the gameplay phases, the transform
	/// recompute, extraction, then deferred destruction.
	///
	/// Phases run in ScenePhase order and, within a phase, systems in UpdateOrder. A
	/// simulation only system is skipped while simulation is off.
	public void Update(float deltaTime)
	{
		mIsUpdating = true;

		InitializePendingComponents();
		RunPhase(.PreUpdate, deltaTime);
		RunPhase(.Update, deltaTime);
		RunPhase(.AsyncUpdate, deltaTime);
		RunPhase(.PostUpdate, deltaTime);

		// The scene drains NO event bus: only the owning run scope does, since the scene
		// has no bus of its own.
		UpdateTransforms();
		RunPhase(.PostTransform, deltaTime);

		mIsUpdating = false;
		ProcessPendingDestroys();
	}

	public void FixedUpdate(float fixedDeltaTime)
	{
		for (let system in mSortedSystems)
		{
			if (system.IsSimulationOnly && !mSimulationEnabled)
				continue;
			system.OnFixedUpdate(fixedDeltaTime);
		}
	}

	/// Initialises components added since the last call, across every manager.
	public void InitializePendingComponents()
	{
		for (let system in mSortedSystems)
		{
			if (let manager = system.AsComponentManager)
				manager.InitializePendingComponents();
		}
	}

	// ---- internals ----

	private static uint64 TypeKey<T>()
	{
		let name = scope String();
		typeof(T).GetFullName(name);
		return TypeIdOf(name);
	}

	private EntityHandle CreateEntityInternal(Guid id, StringView name)
	{
		uint32 index;
		if (!mFreeList.IsEmpty)
		{
			index = mFreeList.PopBack();
		}
		else
		{
			index = (uint32)mEntities.Count;
			mEntities.Add(new EntitySlot());
			mTransforms.Add(.());
		}

		let slot = mEntities[index];
		slot.Generation++;
		slot.Alive = true;
		slot.Active = true;
		// Created as an active ROOT, so there is no ancestor to dark it.
		slot.EffectiveActive = true;
		slot.PersistentId = id;
		slot.Name.Set(name);

		// Identity local, no links, not dirty.
		mTransforms[index] = .();

		mAliveCount++;
		mRevision++;

		let handle = EntityHandle(index, slot.Generation);
		mIdMap[id] = handle;
		// A new entity starts at the root.
		AppendToList(handle, ref mFirstRoot, ref mLastRoot);
		return handle;
	}

	private void DestroyEntityImmediate(EntityHandle entity)
	{
		let index = entity.Index;

		// The subtree goes first. The next sibling is snapshot before each child dies,
		// since the link it would be read through is cleared by the destroy.
		var child = mTransforms[index].FirstChild;
		while (child.IsAssigned)
		{
			let nextSibling = IsValid(child) ? mTransforms[child.Index].NextSibling
				: EntityHandle.Invalid;
			DestroyEntityImmediate(child);
			child = nextSibling;
		}

		RemoveFromParent(entity);

		// Managers free their components here.
		for (let system in mSortedSystems)
			system.OnEntityDestroyed(entity);

		let slot = mEntities[index];
		mIdMap.Remove(slot.PersistentId);
		slot.Reset();

		mFreeList.Add(index);
		mAliveCount--;
		mRevision++;
		mTransforms[index] = .();
	}

	/// Recomputes the cached effective active bit for `entity`'s whole subtree against its
	/// CURRENT parent chain.
	///
	/// A branch whose own flag is false is not descended into: its descendants are already
	/// cached false whatever is above them, and that induction is what keeps the walk cheap.
	private void RefreshEffectiveActive(EntityHandle entity)
	{
		if (!IsValid(entity))
			return;

		let parent = mTransforms[entity.Index].Parent;
		let parentEffective = parent.IsAssigned ? mEntities[parent.Index].EffectiveActive : true;

		let stack = scope List<(uint32 index, bool parentEffective)>();
		stack.Add((entity.Index, parentEffective));

		while (!stack.IsEmpty)
		{
			let item = stack.PopBack();
			let slot = mEntities[item.index];
			let effective = slot.Active && item.parentEffective;

			if ((slot.EffectiveActive == effective) && !slot.Active)
				continue;

			slot.EffectiveActive = effective;
			var child = mTransforms[item.index].FirstChild;
			while (child.IsAssigned)
			{
				stack.Add((child.Index, effective));
				child = mTransforms[child.Index].NextSibling;
			}
		}
	}

	/// Marks an entity dirty, cascading DOWN the subtree and UP to its ancestors.
	///
	/// Up as well as down, because UpdateTransforms walks from dirty tops: a dirty child
	/// under a clean parent would otherwise never be reached from above.
	private void MarkDirty(EntityHandle entity)
	{
		if (!entity.IsAssigned)
			return;
		if (mTransforms[entity.Index].Dirty)
			return;

		mTransforms[entity.Index].Dirty = true;

		var child = mTransforms[entity.Index].FirstChild;
		while (child.IsAssigned && IsValid(child))
		{
			let next = mTransforms[child.Index].NextSibling;
			MarkDirty(child);
			child = next;
		}

		let parent = mTransforms[entity.Index].Parent;
		if (parent.IsAssigned)
			MarkDirty(parent);
	}

	/// Rewrites `child`'s LOCAL transform so its world matrix stays `childWorld` under its
	/// current parent: the keep world half of a reparent. Row vector, so the local is the
	/// world times the parent's inverse.
	private void ApplyWorldAsLocal(EntityHandle child, Float4x4 childWorld)
	{
		let parent = mTransforms[child.Index].Parent;
		let local = parent.IsAssigned
			? childWorld * Inverse(ComposeWorldMatrix(parent))
			: childWorld;
		SetLocalTransform(child, Transform.FromMatrix(local));
	}

	private void UpdateTransformRecursive(uint32 index, Float4x4 parentWorld)
	{
		mTransforms[index].PrevWorldMatrix = mTransforms[index].WorldMatrix;
		mTransforms[index].WorldMatrix = mTransforms[index].Local.ToMatrix() * parentWorld;
		mTransforms[index].Dirty = false;
		mTransforms[index].UpdatedThisFrame = true;
		mTransformsUpdatedThisFrame.Add(index);

		let myWorld = mTransforms[index].WorldMatrix;
		var child = mTransforms[index].FirstChild;
		while (child.IsAssigned && IsValid(child))
		{
			let childIndex = child.Index;
			UpdateTransformRecursive(childIndex, myWorld);
			child = mTransforms[childIndex].NextSibling;
		}
	}

	/// O(1) append to a head and tail sibling list; the tail pointer is what avoids a walk.
	private void AppendToList(EntityHandle entity, ref EntityHandle head, ref EntityHandle tail)
	{
		mTransforms[entity.Index].NextSibling = .Invalid;
		mTransforms[entity.Index].PrevSibling = tail;

		if (!head.IsAssigned)
		{
			head = entity;
			tail = entity;
			return;
		}
		mTransforms[tail.Index].NextSibling = entity;
		tail = entity;
	}

	/// O(1) splice out through the back pointer, with no walk to find the predecessor.
	private void RemoveFromParent(EntityHandle child)
	{
		let parent = mTransforms[child.Index].Parent;
		let prev = mTransforms[child.Index].PrevSibling;
		let next = mTransforms[child.Index].NextSibling;

		if (prev.IsAssigned)
			mTransforms[prev.Index].NextSibling = next;
		if (next.IsAssigned)
			mTransforms[next.Index].PrevSibling = prev;

		if (parent.IsAssigned)
		{
			if (mTransforms[parent.Index].FirstChild == child)
				mTransforms[parent.Index].FirstChild = next;
			if (mTransforms[parent.Index].LastChild == child)
				mTransforms[parent.Index].LastChild = prev;
		}
		else
		{
			if (mFirstRoot == child)
				mFirstRoot = next;
			if (mLastRoot == child)
				mLastRoot = prev;
		}

		mTransforms[child.Index].Parent = .Invalid;
		mTransforms[child.Index].NextSibling = .Invalid;
		mTransforms[child.Index].PrevSibling = .Invalid;
	}

	/// Whether `entity` IS `ancestor` or sits below it. Walked upward, which is the short
	/// direction.
	private bool IsDescendantOf(EntityHandle entity, EntityHandle ancestor)
	{
		var current = entity;
		while (current.IsAssigned && IsValid(current))
		{
			if (current == ancestor)
				return true;
			current = mTransforms[current.Index].Parent;
		}
		return false;
	}

	private void RunPhase(ScenePhase phase, float deltaTime)
	{
		for (let system in mSortedSystems)
		{
			if (system.IsSimulationOnly && !mSimulationEnabled)
				continue;
			system.OnUpdate(phase, deltaTime);
		}
	}

	/// Insertion sort by UpdateOrder, ascending and STABLE: two systems with the same order
	/// keep the order they were added in, which is the only tie break an author controls.
	private void InsertSortedSystem(SceneSystem system)
	{
		mSortedSystems.Add(system);
		int i = mSortedSystems.Count - 1;
		while ((i > 0) && (mSortedSystems[i - 1].UpdateOrder > system.UpdateOrder))
		{
			mSortedSystems[i] = mSortedSystems[i - 1];
			mSortedSystems[i - 1] = system;
			i--;
		}
	}

	/// Destroys what was queued during the update.
	///
	/// SNAPSHOT first, because destroying a subtree can queue more, and the stale entries a
	/// nested destroy leaves behind are skipped by the validity check.
	private void ProcessPendingDestroys()
	{
		if (mPendingDestroys.IsEmpty)
			return;

		let batch = scope List<EntityHandle>();
		batch.AddRange(mPendingDestroys);
		mPendingDestroys.Clear();

		for (let entity in batch)
		{
			if (IsValid(entity))
				DestroyEntityImmediate(entity);
		}
	}
}
