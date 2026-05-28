namespace Sedulous.Engine.Core;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Jobs;
using Sedulous.Profiler;

#define UPDATE_TRANSFORMS_THREADED

/// A scene containing entities, transforms, and component managers.
/// Multiple scenes can coexist - each is fully isolated (own physics world, own components, etc.).
public class Scene : IDisposable
{
	// --- Entity storage ---

	private struct EntitySlot
	{
		public uint32 Generation;
		public bool Active;
		public bool Alive;
		public Guid PersistentId;
		public String Name; // nullable, owned
	}

	private List<EntitySlot> mEntities = new .() ~ delete _;
	private List<int32> mEntityFreeList = new .() ~ delete _;
	private Dictionary<Guid, EntityHandle> mEntityIdMap = new .() ~ delete _;
	private int32 mAliveCount = 0;

	// --- Transform hierarchy ---

	private struct TransformData
	{
		public Transform Local;
		public Matrix WorldMatrix;
		/// Previous frame's world matrix, for motion vector computation.
		/// Snapshot taken at the start of each UpdateTransforms before the
		/// current frame's matrices are recomputed.
		public Matrix PrevWorldMatrix;
		public EntityHandle Parent;
		public EntityHandle FirstChild;
		/// Tail of the child sibling list. Paired with FirstChild to make
		/// AppendToList O(1) instead of walking the list to find the end
		/// (which caused O(N²) batch-spawn cost in flat hierarchies).
		public EntityHandle LastChild;
		public EntityHandle NextSibling;
		/// Back-pointer in the sibling linked list. Makes RemoveFromParent
		/// O(1) - no need to walk from the head to find the predecessor.
		public EntityHandle PrevSibling;
		/// "Needs world-matrix recompute". Set by MarkDirty (which cascades
		/// to children and ancestors). Cleared immediately by
		/// UpdateTransformRecursive after the recompute. Internal state -
		/// consumers wanting "did this move this frame?" should read
		/// UpdatedThisFrame instead.
		public bool Dirty;
		/// "World matrix was recomputed in the most recent UpdateTransforms".
		/// Set by UpdateTransformRecursive, cleared at the start of the
		/// next UpdateTransforms via mTransformsUpdatedThisFrame.
		/// Read this in the PostTransform phase (consumers of "what moved").
		public bool UpdatedThisFrame;
	}

	private List<TransformData> mTransforms = new .() ~ delete _;

	/// Entity indices whose world matrix was recomputed during the most
	/// recent UpdateTransforms. Cleared and rebuilt each frame. Doubles
	/// as the iteration source for PostTransform consumers (bounds
	/// caches, etc.) AND as the deferred clear list for UpdatedThisFrame.
	///
	/// Lifetime hazard: an entity that updated this frame and was then
	/// destroyed (either immediately or via mPendingDestroys) leaves its
	/// index in this list with the slot already marked Alive=false.
	/// Consumers iterating this list MUST gate slot reads on
	/// `mEntities[i].Alive` (or call IsValid with the rebuilt handle) -
	/// the index stays in-range, but the slot's components are gone and
	/// reading them would be a use-after-free in spirit.
	private List<int32> mTransformsUpdatedThisFrame = new .() ~ delete _;

	/// Head of the root entity linked list (entities with no parent).
	private EntityHandle mFirstRoot = .Invalid;
	/// Tail of the root entity linked list. Paired with mFirstRoot so
	/// CreateEntity's append step is O(1). Without this, mass-spawn
	/// workloads (e.g. the stress test creating 8000 roots per batch)
	/// degraded into O(N²) territory as AppendToList walked from the
	/// head every call.
	private EntityHandle mLastRoot = .Invalid;

	// --- Scene modules ---

	private List<SceneModule> mModules = new .() ~ delete _;
	private Dictionary<Type, SceneModule> mModulesByType = new .() ~ delete _;

	// --- Prefab modification tracking ---

	private LocalModifications mLocalModifications = new .() ~ delete _;

	// --- Phase update functions (collected from all modules) ---

	private struct PhaseEntry
	{
		public delegate void(float) Function;
		public float Priority;
		public bool SimulationOnly;
	}

	private List<PhaseEntry>[(int)ScenePhase.COUNT] mPhaseFunctions;

	// --- Fixed update functions (separate from phase functions) ---

	private List<PhaseEntry> mFixedUpdateFunctions = new .() ~ delete _;

	// --- Deferred destruction ---

	private List<EntityHandle> mPendingDestroys = new .() ~ delete _;
	private bool mIsUpdating = false;
	private bool mDisposed = false;

	// --- Properties ---

	/// Number of alive entities.
	public int32 EntityCount => mAliveCount;

	/// Monotonic structural-revision counter. Incremented when entities are
	/// added/destroyed or when render-relevant component state changes (mesh,
	/// material, submesh, visibility). Renderers key per-scene caches on this
	/// so they can skip rebuilding work when the scene is structurally stable
	/// across frames. Transform/animation changes do NOT bump this - those
	/// only affect per-instance data, not render grouping.
	public uint64 Revision => mRevision;
	private uint64 mRevision = 1;

	/// Bumps the revision counter. Call from any code path that changes the
	/// structural shape of the scene as renderers see it (entity create/destroy,
	/// mesh swap, material swap, visibility toggle, layer mask change).
	[Inline]
	public void BumpRevision()
	{
		mRevision++;
	}

	/// Scene name (for debugging/identification).
	public String Name { get; set; } = new .("Scene") ~ delete _;

	/// Whether simulation-phase update functions run.
	/// When false, functions registered with simulationOnly=true are skipped.
	/// Transforms and presentation functions always run.
	/// Default: true (runtime). Editor sets to false for edit mode.
	/// Managed by Start()/Stop() - prefer those over setting directly.
	public bool SimulationEnabled = true;

	/// Whether the scene has been started (is in play/simulation mode).
	public bool IsStarted { get; private set; }

	/// Time scale multiplier for this scene. Affects deltaTime passed to update functions.
	/// 0 = paused (functions still run but with zero delta - use for game pause).
	/// 0.5 = slow motion, 1.0 = normal (default), 2.0 = fast forward.
	/// Does not affect FixedUpdate timestep (physics always uses fixed delta).
	public float TimeScale = 1.0f;

	/// Unscaled delta time from the last Update call (before TimeScale is applied).
	/// Use for systems that must run during pause (UI animations, input, etc.).
	public float UnscaledDeltaTime { get; private set; }

	public this()
	{
		for (int i = 0; i < (int)ScenePhase.COUNT; i++)
			mPhaseFunctions[i] = new .();
	}

	// ==================== Simulation Lifecycle ====================

	/// Starts the scene - enables simulation and notifies all modules.
	/// Call when entering play mode. Modules receive OnSceneStarted()
	/// to initialize runtime state (physics bodies, audio sources, AI, etc.).
	/// No-op if already started.
	public void Start()
	{
		if (IsStarted) return;
		IsStarted = true;
		SimulationEnabled = true;

		for (let module in mModules)
			module.OnSceneStarted();
	}

	/// Stops the scene - notifies all modules and disables simulation.
	/// Call when exiting play mode. Modules receive OnSceneStopped()
	/// to clean up runtime state. No-op if not started.
	public void Stop()
	{
		if (!IsStarted) return;

		for (let module in mModules)
			module.OnSceneStopped();

		IsStarted = false;
		SimulationEnabled = false;
	}

	// ==================== Entity Management ====================

	/// Creates a new entity with an auto-generated Guid.
	public EntityHandle CreateEntity(StringView name = default)
	{
		return CreateEntityInternal(Guid.Create(), name);
	}

	/// Creates an entity with a specific Guid (for deserialization).
	public EntityHandle CreateEntity(Guid id, StringView name = default)
	{
		return CreateEntityInternal(id, name);
	}

	private EntityHandle CreateEntityInternal(Guid id, StringView name)
	{
		int32 index;
		if (mEntityFreeList.Count > 0)
		{
			index = mEntityFreeList.PopBack();
		}
		else
		{
			index = (int32)mEntities.Count;
			mEntities.Add(.());
			mTransforms.Add(.());
		}

		var slot = ref mEntities[index];
		slot.Generation++;
		slot.Alive = true;
		slot.Active = true;
		slot.PersistentId = id;

		if (!name.IsEmpty)
		{
			if (slot.Name == null)
				slot.Name = new .(name);
			else
				slot.Name.Set(name);
		}

		// Initialize transform
		var transform = ref mTransforms[index];
		transform.Local = .Identity;
		transform.WorldMatrix = .Identity;
		transform.Parent = .Invalid;
		transform.FirstChild = .Invalid;
		transform.LastChild = .Invalid;
		transform.NextSibling = .Invalid;
		transform.PrevSibling = .Invalid;
		transform.Dirty = false;
		transform.UpdatedThisFrame = false;

		mAliveCount++;
		mRevision++;

		let handle = EntityHandle() { Index = (uint32)index, Generation = slot.Generation };
		mEntityIdMap[id] = handle;

		// Append to root list (new entities start as roots)
		AppendToList(handle, ref mFirstRoot, ref mLastRoot);

		return handle;
	}

	/// Destroys an entity. If called during an update, destruction is deferred.
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

	/// Whether the entity handle is valid (alive and generation matches).
	public bool IsValid(EntityHandle entity)
	{
		if (!entity.IsAssigned || entity.Index >= (uint32)mEntities.Count)
			return false;

		let slot = ref mEntities[(int32)entity.Index];
		return slot.Alive && slot.Generation == entity.Generation;
	}

	/// Gets the persistent Guid of an entity.
	public Guid GetEntityId(EntityHandle entity)
	{
		if (!IsValid(entity))
			return .Empty;

		return mEntities[(int32)entity.Index].PersistentId;
	}

	/// Finds an entity by its persistent Guid. Returns .Invalid if not found.
	public EntityHandle FindEntity(Guid id)
	{
		if (mEntityIdMap.TryGetValue(id, let handle))
		{
			if (IsValid(handle))
				return handle;
			// Stale entry - clean up
			mEntityIdMap.Remove(id);
		}
		return .Invalid;
	}

	/// Gets the name of an entity, or empty if unnamed.
	public StringView GetEntityName(EntityHandle entity)
	{
		if (!IsValid(entity))
			return default;

		let slot = ref mEntities[(int32)entity.Index];
		return (slot.Name != null) ? StringView(slot.Name) : default;
	}

	/// Sets the name of an entity.
	public void SetEntityName(EntityHandle entity, StringView name)
	{
		if (!IsValid(entity))
			return;

		var slot = ref mEntities[(int32)entity.Index];
		if (slot.Name == null)
			slot.Name = new String(name);
		else
			slot.Name.Set(name);
	}

	/// Gets whether an entity is active.
	public bool IsActive(EntityHandle entity)
	{
		if (!IsValid(entity))
			return false;

		return mEntities[(int32)entity.Index].Active;
	}

	/// Sets whether an entity is active. Propagates to all components on this entity.
	public void SetActive(EntityHandle entity, bool active)
	{
		if (!IsValid(entity))
			return;

		mEntities[(int32)entity.Index].Active = active;

		// Notify all modules to sync component active state
		for (let module in mModules)
			module.OnEntityActiveChanged(entity, active);
	}

	// ==================== Entity Iteration ====================

	/// Iterates all alive entity handles.
	public EntityEnumerator Entities => .(this);

	public struct EntityEnumerator : IEnumerator<EntityHandle>
	{
		private Scene mScene;
		private int32 mIndex;

		public this(Scene scene)
		{
			mScene = scene;
			mIndex = -1;
		}

		public Result<EntityHandle> GetNext() mut
		{
			while (++mIndex < mScene.mEntities.Count)
			{
				let slot = ref mScene.mEntities[mIndex];
				if (slot.Alive)
					return .Ok(.() { Index = (uint32)mIndex, Generation = slot.Generation });
			}
			return .Err;
		}
	}

	// ==================== Transform Hierarchy ====================

	/// Sets the local transform of an entity.
	public void SetLocalTransform(EntityHandle entity, Transform transform)
	{
		if (!IsValid(entity))
			return;

		var data = ref mTransforms[(int32)entity.Index];
		data.Local = transform;
		MarkDirty(entity);
	}

	/// Gets the local transform of an entity.
	public Transform GetLocalTransform(EntityHandle entity)
	{
		if (!IsValid(entity))
			return .Identity;

		return mTransforms[(int32)entity.Index].Local;
	}

	/// Gets the computed world matrix of an entity.
	public Matrix GetWorldMatrix(EntityHandle entity)
	{
		if (!IsValid(entity))
			return .Identity;

		return mTransforms[(int32)entity.Index].WorldMatrix;
	}

	/// Gets the previous frame's world matrix. Returns Identity for entities
	/// that haven't been alive for more than one frame yet.
	public Matrix GetPrevWorldMatrix(EntityHandle entity)
	{
		if (!IsValid(entity))
			return .Identity;

		return mTransforms[(int32)entity.Index].PrevWorldMatrix;
	}

	public (Matrix Previous, Matrix Current) GetWorldMatrices(EntityHandle entity)
	{
		if (!IsValid(entity))
			return (.Identity, .Identity);

		return (mTransforms[(int32)entity.Index].PrevWorldMatrix, mTransforms[(int32)entity.Index].WorldMatrix);
	}

	/// True if the entity's world matrix was recomputed during the most
	/// recent UpdateTransforms - i.e. SetLocalTransform was called this
	/// frame, the entity was reparented this frame, or a dirty ancestor's
	/// update cascaded through it.
	///
	/// Intended for PostTransform-phase consumers (cached world bounds,
	/// physics sync, audio listener position, etc.). PostUpdate is too
	/// early (UpdateTransforms hasn't run yet); reads outside the
	/// PostTransform window are still valid but the "this frame" window
	/// extends until the start of the next UpdateTransforms.
	///
	/// Returns false for invalid handles.
	public bool IsTransformUpdatedThisFrame(EntityHandle entity)
	{
		if (!IsValid(entity))
			return false;
		return mTransforms[(int32)entity.Index].UpdatedThisFrame;
	}

	/// Entity-index list of every transform whose world matrix was
	/// recomputed during the most recent UpdateTransforms. Cheaper than
	/// iterating all entities and testing IsTransformUpdatedThisFrame
	/// when only a small fraction moved.
	///
	/// Lifetime hazard: if an entity updates this frame and is then
	/// destroyed (immediately, or via DestroyEntity during PostTransform
	/// which routes through mPendingDestroys), its index stays in this
	/// list with the slot already marked Alive=false. Iterating
	/// consumers MUST gate slot/component reads on
	/// `IsValid(handle)` or check `mEntities[i].Alive` directly - the
	/// index is in-bounds but the slot is gone.
	///
	/// Read-only. Lifetime is bounded by the next UpdateTransforms call,
	/// which clears and rewrites this list.
	public List<int32> TransformsUpdatedThisFrame => mTransformsUpdatedThisFrame;

	/// Sets the parent of an entity. Pass EntityHandle.Invalid to unparent.
	public void SetParent(EntityHandle child, EntityHandle parent)
	{
		if (!IsValid(child))
			return;
		if (parent.IsAssigned && !IsValid(parent))
			return;
		if (child == parent)
			return;

		// Remove from current parent's child list (or root list)
		RemoveFromParent(child);

		var childTransform = ref mTransforms[(int32)child.Index];
		childTransform.Parent = parent;

		if (parent.IsAssigned)
		{
			var parentTransform = ref mTransforms[(int32)parent.Index];
			AppendToList(child, ref parentTransform.FirstChild, ref parentTransform.LastChild);
		}
		else
		{
			AppendToList(child, ref mFirstRoot, ref mLastRoot);
		}

		MarkDirty(child);
	}

	/// Sets the parent of an entity, inserting it after a specific sibling.
	/// If afterSibling is .Invalid, the child is prepended (becomes first child).
	public void SetParentAfter(EntityHandle child, EntityHandle parent, EntityHandle afterSibling)
	{
		if (!IsValid(child))
			return;
		if (parent.IsAssigned && !IsValid(parent))
			return;
		if (child == parent)
			return;

		RemoveFromParent(child);

		var childTransform = ref mTransforms[(int32)child.Index];
		childTransform.Parent = parent;

		if (!afterSibling.IsAssigned)
		{
			// Prepend - new entity becomes the head; the old head's
			// PrevSibling now points at us. If the list was empty, we're
			// also the new tail.
			childTransform.PrevSibling = .Invalid;
			if (parent.IsAssigned)
			{
				var parentTransform = ref mTransforms[(int32)parent.Index];
				childTransform.NextSibling = parentTransform.FirstChild;
				if (parentTransform.FirstChild.IsAssigned)
					mTransforms[(int32)parentTransform.FirstChild.Index].PrevSibling = child;
				else
					parentTransform.LastChild = child;
				parentTransform.FirstChild = child;
			}
			else
			{
				childTransform.NextSibling = mFirstRoot;
				if (mFirstRoot.IsAssigned)
					mTransforms[(int32)mFirstRoot.Index].PrevSibling = child;
				else
					mLastRoot = child;
				mFirstRoot = child;
			}
		}
		else
		{
			// Insert after the specified sibling - splice in. If afterSibling
			// was the tail, we're the new tail; otherwise the old next's
			// PrevSibling now points at us.
			var afterTransform = ref mTransforms[(int32)afterSibling.Index];
			let oldNext = afterTransform.NextSibling;
			childTransform.PrevSibling = afterSibling;
			childTransform.NextSibling = oldNext;
			afterTransform.NextSibling = child;
			if (oldNext.IsAssigned)
			{
				mTransforms[(int32)oldNext.Index].PrevSibling = child;
			}
			else
			{
				// afterSibling was the tail - update the appropriate tail ref
				if (parent.IsAssigned)
				{
					var parentTransform = ref mTransforms[(int32)parent.Index];
					parentTransform.LastChild = child;
				}
				else
				{
					mLastRoot = child;
				}
			}
		}

		MarkDirty(child);
	}

	/// Gets the first root entity (head of root linked list).
	public EntityHandle FirstRoot => mFirstRoot;

	/// Gets the parent of an entity.
	public EntityHandle GetParent(EntityHandle entity)
	{
		if (!IsValid(entity))
			return .Invalid;

		return mTransforms[(int32)entity.Index].Parent;
	}

	/// Gets the first child of an entity.
	public EntityHandle GetFirstChild(EntityHandle entity)
	{
		if (!IsValid(entity))
			return .Invalid;

		return mTransforms[(int32)entity.Index].FirstChild;
	}

	/// Gets the next sibling of an entity.
	public EntityHandle GetNextSibling(EntityHandle entity)
	{
		if (!IsValid(entity))
			return .Invalid;

		return mTransforms[(int32)entity.Index].NextSibling;
	}

	/// Gets the number of direct children of an entity.
	public int32 GetChildCount(EntityHandle entity)
	{
		if (!IsValid(entity))
			return 0;

		int32 count = 0;
		var child = mTransforms[(int32)entity.Index].FirstChild;
		while (child.IsAssigned && IsValid(child))
		{
			count++;
			child = mTransforms[(int32)child.Index].NextSibling;
		}
		return count;
	}

	/// Fills the list with the direct children of an entity, in sibling order.
	public void GetChildren(EntityHandle entity, List<EntityHandle> outChildren)
	{
		if (!IsValid(entity))
			return;

		var child = mTransforms[(int32)entity.Index].FirstChild;
		while (child.IsAssigned && IsValid(child))
		{
			outChildren.Add(child);
			child = mTransforms[(int32)child.Index].NextSibling;
		}
	}

	/// Gets the sibling index of an entity (0-based).
	/// Works for both parented entities and root entities.
	public int32 GetSiblingIndex(EntityHandle entity)
	{
		if (!IsValid(entity))
			return -1;

		let parent = mTransforms[(int32)entity.Index].Parent;
		let listHead = parent.IsAssigned ? mTransforms[(int32)parent.Index].FirstChild : mFirstRoot;

		int32 index = 0;
		var child = listHead;
		while (child.IsAssigned && IsValid(child))
		{
			if (child == entity)
				return index;
			index++;
			child = mTransforms[(int32)child.Index].NextSibling;
		}
		return -1;
	}

	/// Moves an entity to a specific sibling index among its siblings.
	/// Works for both parented entities and root entities. Clamps to valid range.
	public void SetSiblingIndex(EntityHandle entity, int32 targetIndex)
	{
		if (!IsValid(entity))
			return;

		let parent = GetParent(entity);

		// Remove from current position (parent or root list)
		RemoveFromParent(entity);

		// Re-insert at target position
		var childTransform = ref mTransforms[(int32)entity.Index];
		childTransform.Parent = parent;

		if (parent.IsAssigned)
		{
			var parentTransform = ref mTransforms[(int32)parent.Index];
			InsertIntoList(entity, ref parentTransform.FirstChild, ref parentTransform.LastChild, targetIndex);
		}
		else
		{
			InsertIntoList(entity, ref mFirstRoot, ref mLastRoot, targetIndex);
		}

		MarkDirty(entity);
	}

	/// Inserts an entity into a doubly-linked sibling list at the given index.
	/// Maintains PrevSibling on the inserted entity + its neighbors, and
	/// updates the tail ref if the insertion lands at the end (or the list
	/// was empty).
	private void InsertIntoList(EntityHandle entity, ref EntityHandle listHead, ref EntityHandle listTail, int32 targetIndex)
	{
		var childTransform = ref mTransforms[(int32)entity.Index];

		if (!listHead.IsAssigned)
		{
			// Empty list - entity is both head and tail.
			childTransform.PrevSibling = .Invalid;
			childTransform.NextSibling = .Invalid;
			listHead = entity;
			listTail = entity;
			return;
		}

		if (targetIndex <= 0)
		{
			// Prepend - new head, old head's PrevSibling now points at us.
			childTransform.PrevSibling = .Invalid;
			childTransform.NextSibling = listHead;
			mTransforms[(int32)listHead.Index].PrevSibling = entity;
			listHead = entity;
			return;
		}

		// Walk to the sibling at target position - 1 (the predecessor).
		var prev = listHead;
		int32 i = 0;
		while (i < targetIndex - 1 && IsValid(prev))
		{
			let next = mTransforms[(int32)prev.Index].NextSibling;
			if (!next.IsAssigned || !IsValid(next))
				break;
			prev = next;
			i++;
		}

		var prevTransform = ref mTransforms[(int32)prev.Index];
		let oldNext = prevTransform.NextSibling;
		childTransform.PrevSibling = prev;
		childTransform.NextSibling = oldNext;
		prevTransform.NextSibling = entity;
		if (oldNext.IsAssigned)
			mTransforms[(int32)oldNext.Index].PrevSibling = entity;
		else
			listTail = entity;  // Inserted at the end - new tail.
	}

	/// Appends an entity to the end of a doubly-linked sibling list in O(1).
	/// Caller supplies refs to both the head and tail of the list:
	///   - Root list: listHead = mFirstRoot, listTail = mLastRoot.
	///   - Child list: listHead = parent.FirstChild, listTail = parent.LastChild.
	/// Both refs are updated in place when the list was previously empty or
	/// when the new entity becomes the new tail.
	private void AppendToList(EntityHandle entity, ref EntityHandle listHead, ref EntityHandle listTail)
	{
		var entityTransform = ref mTransforms[(int32)entity.Index];
		entityTransform.NextSibling = .Invalid;
		entityTransform.PrevSibling = listTail;

		if (!listHead.IsAssigned)
		{
			listHead = entity;
			listTail = entity;
			return;
		}

		mTransforms[(int32)listTail.Index].NextSibling = entity;
		listTail = entity;
	}

	// ==================== Module Management ====================

	/// Adds a scene module (typically a ComponentManager).
	public void AddModule(SceneModule module)
	{
		let type = module.GetType();
		if (mModulesByType.ContainsKey(type))
			return;

		mModules.Add(module);
		mModulesByType[type] = module;
		module.OnSceneCreate(this);

		// Collect update registrations into phase lists
		for (let reg in module.UpdateRegistrations)
		{
			mPhaseFunctions[(int)reg.Phase].Add(.()
			{
				Function = reg.Function,
				Priority = reg.Priority,
				SimulationOnly = reg.SimulationOnly
			});
		}

		// Collect fixed update registrations
		for (let reg in module.FixedUpdateRegistrations)
		{
			mFixedUpdateFunctions.Add(.()
			{
				Function = reg.Function,
				Priority = reg.Priority,
				SimulationOnly = reg.SimulationOnly
			});
		}

		// Re-sort phase functions by priority (higher = earlier)
		for (int i = 0; i < (int)ScenePhase.COUNT; i++)
			mPhaseFunctions[i].Sort(scope (a, b) => b.Priority <=> a.Priority);

		mFixedUpdateFunctions.Sort(scope (a, b) => b.Priority <=> a.Priority);
	}

	/// Gets a module by type.
	public T GetModule<T>() where T : SceneModule
	{
		if (mModulesByType.TryGetValue(typeof(T), let module))
			return (T)module;
		return null;
	}

	/// Gets all registered modules. Used by serialization.
	public Span<SceneModule> Modules => mModules;

	/// Prefab modification tracker. Tracks which properties on which
	/// entities differ from their prefab template.
	public LocalModifications LocalModifications => mLocalModifications;

	/// Collects all components attached to the given entity across all managers.
	public void GetComponents(EntityHandle entity, List<Component> outComponents)
	{
		for (let module in mModules)
		{
			if (let manager = module as ComponentManagerBase)
			{
				let comp = manager.GetComponent(entity);
				if (comp != null)
					outComponents.Add(comp);
			}
		}
	}

	// ==================== Update ====================

	/// Runs the full scene update loop. Called by SceneSubsystem.
	/// deltaTime is scaled by TimeScale before being passed to update functions.
	/// UnscaledDeltaTime is available for pause-immune systems.
	public void Update(float deltaTime)
	{
		UnscaledDeltaTime = deltaTime;
		let scaledDelta = deltaTime * TimeScale;

		mIsUpdating = true;

		using (Profiler.Begin("Scene.Initialize"))
			RunPhase(.Initialize, scaledDelta);
		using (Profiler.Begin("Scene.PreUpdate"))
			RunPhase(.PreUpdate, scaledDelta);
		using (Profiler.Begin("Scene.Update"))
			RunPhase(.Update, scaledDelta);
		using (Profiler.Begin("Scene.AsyncUpdate"))
			RunAsyncPhase(scaledDelta);
		using (Profiler.Begin("Scene.PostUpdate"))
			RunPhase(.PostUpdate, scaledDelta);

		// Transform propagation (internal, not user-registered)
		using (Profiler.Begin("Scene.UpdateTransforms"))
			UpdateTransforms();

		using (Profiler.Begin("Scene.PostTransform"))
			RunPhase(.PostTransform, scaledDelta);

		mIsUpdating = false;

		using (Profiler.Begin("Scene.ProcessDeferredDestroys"))
			ProcessDeferredDestroys();
	}

	/// Initializes any components created since the last frame.
	/// Called before FixedUpdate so new physics bodies, audio sources, etc.
	/// are ready before their first simulation step.
	public void InitializePendingComponents()
	{
		for (let module in mModules)
		{
			if (let cmBase = module as ComponentManagerBase)
				cmBase.InitializePendingComponents();
		}
	}

	/// Runs fixed update functions. Called by SceneSubsystem at fixed timestep.
	/// Skips simulation-only functions when SimulationEnabled is false.
	public void FixedUpdate(float fixedDeltaTime)
	{
		for (let entry in mFixedUpdateFunctions)
		{
			if (entry.SimulationOnly && !SimulationEnabled)
				continue;
			entry.Function(fixedDeltaTime);
		}
	}

	// ==================== Internal ====================

	private void RunPhase(ScenePhase phase, float deltaTime)
	{
		for (let entry in mPhaseFunctions[(int)phase])
		{
			if (entry.SimulationOnly && !SimulationEnabled)
				continue;
			entry.Function(deltaTime);
		}
	}

	/// Runs the AsyncUpdate phase - all registered functions execute concurrently.
	/// Each function should only access its own component pool.
	/// Skips simulation-only functions when SimulationEnabled is false.
	private void RunAsyncPhase(float deltaTime)
	{
		let asyncFunctions = mPhaseFunctions[(int)ScenePhase.AsyncUpdate];
		let count = (int32)asyncFunctions.Count;
		if (count == 0)
			return;

		if (!SimulationEnabled)
		{
			// Run only non-simulation functions sequentially
			for (int32 i = 0; i < count; i++)
			{
				if (!asyncFunctions[i].SimulationOnly)
					asyncFunctions[i].Function(deltaTime);
			}
			return;
		}

		if (count == 1)
		{
			// Single function - no parallelism needed
			asyncFunctions[0].Function(deltaTime);
			return;
		}

		// Dispatch all async functions concurrently
		JobSystem.ParallelFor(0, count, scope [&](begin, end) => {
			for (int32 i = begin; i < end; i++)
				asyncFunctions[i].Function(deltaTime);
		});
	}

#if !UPDATE_TRANSFORMS_THREADED

	private void UpdateTransforms()
	{
	    let count = (int32)mTransforms.Count;
	    if (count == 0) return;

	    // Pass 1: walk last frame's update list (still in
	    // mTransformsUpdatedThisFrame at this point, not yet cleared).
	    // Two jobs in one loop for cache-locality:
	    //   a) clear UpdatedThisFrame so this frame's consumers see a
	    //      fresh signal.
	    //   b) for entities that moved last frame but AREN'T dirty
	    //      this frame ("just stopped"), snapshot PrevWorldMatrix =
	    //      WorldMatrix so their motion-vector reads zero this frame.
	    //      Entities still moving this frame skip the snapshot here
	    //      and let UpdateTransformRecursive do the inline save
	    //      (avoids redundant copy in the stress-test case).
	    for (let idx in mTransformsUpdatedThisFrame)
	    {
	        var data = ref mTransforms[idx];
	        data.UpdatedThisFrame = false;
	        if (!data.Dirty && mEntities[idx].Alive)
	            data.PrevWorldMatrix = data.WorldMatrix;
	    }
	    mTransformsUpdatedThisFrame.Clear();

	    // Reserve capacity to current entity count so per-frame Adds
	    // don't trigger growth-time reallocations. List capacity is
	    // sticky: this is a one-shot allocation matching peak entity
	    // count after the first call at scale.
	    mTransformsUpdatedThisFrame.Reserve(count);

	    // Pass 2: Collect dirty roots, then update each subtree.
	    // UpdateTransformRecursive saves PrevWorldMatrix = WorldMatrix
	    // inline before overwriting WorldMatrix.
	    for (int32 i = 0; i < count; i++)
	    {
	        if (mTransforms[i].Dirty && mEntities[i].Alive && !mTransforms[i].Parent.IsAssigned)
	            UpdateTransformRecursive(i, .Identity);
	    }
	}
#else
	private void UpdateTransforms()
	{
	    let count = (int32)mTransforms.Count;
	    if (count == 0) return;

	    let workerCount = JobSystem.IsInitialized ? JobSystem.WorkerCount : 0;

	    // Pass 1: walk last frame's update list to clear UpdatedThisFrame
	    // flags and snapshot PrevWorldMatrix for "just stopped" entities.
	    //
	    // Thread-safety: entries in mTransformsUpdatedThisFrame point to
	    // UNIQUE slots (MarkDirty's "if already dirty, return" guard
	    // ensures an entity is enqueued at most once per dirty cycle, and
	    // UpdateTransformRecursive only Adds an entity whose Dirty was
	    // true when recursion started). So workers writing to
	    // data.UpdatedThisFrame / data.PrevWorldMatrix on disjoint slots
	    // don't race. Reads of data.Dirty / mEntities[idx].Alive are
	    // never raced because those slots are also unique to one chunk.
	    using (Profiler.Begin("UpdateTransforms.Pass1"))
	    {
	    let lastFrameCount = (int32)mTransformsUpdatedThisFrame.Count;
	    if (lastFrameCount >= 256 && workerCount > 0)
	    {
	        JobSystem.ParallelFor(0, lastFrameCount, scope [&](begin, end) => {
	            for (int32 i = begin; i < end; i++)
	            {
	                let idx = mTransformsUpdatedThisFrame[i];
	                var data = ref mTransforms[idx];
	                data.UpdatedThisFrame = false;
	                if (!data.Dirty && mEntities[idx].Alive)
	                    data.PrevWorldMatrix = data.WorldMatrix;
	            }
	        });
	    }
	    else
	    {
	        for (let idx in mTransformsUpdatedThisFrame)
	        {
	            var data = ref mTransforms[idx];
	            data.UpdatedThisFrame = false;
	            if (!data.Dirty && mEntities[idx].Alive)
	                data.PrevWorldMatrix = data.WorldMatrix;
	        }
	    }
	    mTransformsUpdatedThisFrame.Clear();
	    mTransformsUpdatedThisFrame.Reserve(count);
	    }

	    // Pass 2: collect dirty roots (serial), then dispatch each subtree
	    // recursion in parallel. Each dirty root has no parent (filter
	    // below) so all root subtrees are pairwise disjoint - workers
	    // writing to different subtrees never touch the same slot.
	    //
	    // Per-thread accumulator pattern (same as MeshComponentManager.
	    // ExtractRenderData): each worker chunk claims a unique index via
	    // Interlocked.Increment and appends "updated this frame" indices
	    // into its own List<int32>. After ParallelFor returns, a single-
	    // threaded merge concatenates them into mTransformsUpdatedThisFrame.
	    // This avoids racing on the shared list's Add (Count + grow are
	    // not thread-safe).
	    let dirtyRoots = scope List<int32>();
	    using (Profiler.Begin("UpdateTransforms.Pass2.CollectRoots"))
	    {
	        for (int32 i = 0; i < count; i++)
	        {
	            if (mTransforms[i].Dirty && mEntities[i].Alive && !mTransforms[i].Parent.IsAssigned)
	                dirtyRoots.Add(i);
	        }
	    }

	    let rootCount = (int32)dirtyRoots.Count;
	    if (rootCount == 0) return;

	    if (rootCount < 64 || workerCount == 0)
	    {
	        // Too few roots to justify ParallelFor dispatch overhead, or
	        // no workers - fall back to serial. The serial recursion uses
	        // the same UpdateTransformRecursive (parallel-safe variant);
	        // it appends to mTransformsUpdatedThisFrame directly since
	        // there's no contention.
	        using (Profiler.Begin("UpdateTransforms.Pass2.RecurseSerial"))
	        {
	            for (let rootIdx in dirtyRoots)
	                UpdateTransformRecursive(rootIdx, .Identity, mTransformsUpdatedThisFrame);
	        }
	        return;
	    }

	    let chunkCount = Math.Min(rootCount, workerCount + 1);
	    let threadLists = scope List<int32>[chunkCount];
	    for (int i = 0; i < chunkCount; i++)
	        threadLists[i] = scope:: List<int32>();

	    int32 nextChunkIdx = 0;

	    using (Profiler.Begin("UpdateTransforms.Pass2.RecurseParallel"))
	    {
	        JobSystem.ParallelFor(0, rootCount, scope [&](begin, end) => {
	            let chunkIdx = System.Threading.Interlocked.Increment(ref nextChunkIdx) - 1;
	            let localList = threadLists[chunkIdx];
	            for (int32 r = begin; r < end; r++)
	                UpdateTransformRecursive(dirtyRoots[r], .Identity, localList);
	        });
	    }

	    // Merge per-thread accumulators into mTransformsUpdatedThisFrame.
	    // Reserve once to avoid per-Add growth churn.
	    using (Profiler.Begin("UpdateTransforms.Pass2.Merge"))
	    {
	        int32 totalUpdated = 0;
	        for (let list in threadLists)
	            totalUpdated += (int32)list.Count;
	        mTransformsUpdatedThisFrame.Reserve(mTransformsUpdatedThisFrame.Count + totalUpdated);
	        for (let list in threadLists)
	            for (let idx in list)
	                mTransformsUpdatedThisFrame.Add(idx);
	    }
	}
#endif

	/*private void UpdateTransforms()
	{
		let count = (int32)mTransforms.Count;
		if (count == 0) return;

		// Pass 1: Snapshot current world matrices as "previous" before recomputing.
		// Done for ALL alive entities so motion vectors work even for static objects.
		// Embarrassingly parallel - each entity writes only to its own slot.
		JobSystem.ParallelFor(0, count, scope [&](begin, end) => {
			for (int32 i = begin; i < end; i++)
			{
				if (mEntities[i].Alive)
					mTransforms[i].PrevWorldMatrix = mTransforms[i].WorldMatrix;
			}
		});

		// Pass 2: Collect dirty roots, then update each subtree.
		// Each root's subtree is independent - safe for parallel dispatch.
		let dirtyRoots = scope List<int32>();
		for (int32 i = 0; i < count; i++)
		{
			if (mTransforms[i].Dirty && mEntities[i].Alive && !mTransforms[i].Parent.IsAssigned)
				dirtyRoots.Add(i);
		}

		if (dirtyRoots.Count > 0)
		{
			let rootCount = (int32)dirtyRoots.Count;
			JobSystem.ParallelFor(0, rootCount, scope [&](begin, end) => {
				for (int32 r = begin; r < end; r++)
					UpdateTransformRecursive(dirtyRoots[r], .Identity);
			});
		}
	}*/

#if !UPDATE_TRANSFORMS_THREADED
	private void UpdateTransformRecursive(int32 index, Matrix parentWorld)
	{
		var data = ref mTransforms[index];
		// Snapshot previous world matrix before overwriting. Pass 1
		// already handled "moved last, stopped this" entities; for
		// "moving this frame" entities this save is the only place
		// PrevWorldMatrix gets set, and the value we capture (current
		// WorldMatrix, pre-recompute) is exactly "last frame's world".
		data.PrevWorldMatrix = data.WorldMatrix;
		data.WorldMatrix = data.Local.ToMatrix() * parentWorld;
		data.Dirty = false;
		data.UpdatedThisFrame = true;
		mTransformsUpdatedThisFrame.Add(index);

		// Update children
		var childHandle = data.FirstChild;
		while (childHandle.IsAssigned)
		{
			if (IsValid(childHandle))
			{
				UpdateTransformRecursive((int32)childHandle.Index, data.WorldMatrix);
				childHandle = mTransforms[(int32)childHandle.Index].NextSibling;
			}
			else
			{
				break;
			}
		}
	}
#else
	/// Parallel-safe recursion variant. Appends updated entity indices
	/// to a caller-provided `updatedList` instead of the shared
	/// `mTransformsUpdatedThisFrame`. Callers from a ParallelFor worker
	/// pass their own per-thread list; the serial fallback in
	/// UpdateTransforms passes mTransformsUpdatedThisFrame directly.
	///
	/// Other field writes (WorldMatrix, PrevWorldMatrix, Dirty,
	/// UpdatedThisFrame) target this entity's slot exclusively - dirty
	/// roots have no parent so their subtrees are pairwise disjoint, and
	/// the recursion only visits the current root's descendants.
	private void UpdateTransformRecursive(int32 index, Matrix parentWorld, List<int32> updatedList)
	{
		var data = ref mTransforms[index];
		// Snapshot previous world matrix before overwriting. Pass 1
		// already handled "moved last, stopped this" entities; for
		// "moving this frame" entities this save is the only place
		// PrevWorldMatrix gets set, and the value we capture (current
		// WorldMatrix, pre-recompute) is exactly "last frame's world".
		data.PrevWorldMatrix = data.WorldMatrix;
		data.WorldMatrix = data.Local.ToMatrix() * parentWorld;
		data.Dirty = false;
		data.UpdatedThisFrame = true;
		updatedList.Add(index);

		// Update children
		var childHandle = data.FirstChild;
		while (childHandle.IsAssigned)
		{
			if (IsValid(childHandle))
			{
				UpdateTransformRecursive((int32)childHandle.Index, data.WorldMatrix, updatedList);
				childHandle = mTransforms[(int32)childHandle.Index].NextSibling;
			}
			else
			{
				break;
			}
		}
	}
#endif

	private void MarkDirty(EntityHandle entity)
	{
		if (!entity.IsAssigned)
			return;

		var data = ref mTransforms[(int32)entity.Index];
		if (data.Dirty)
			return;

		data.Dirty = true;

		// Mark all children dirty too
		var childHandle = data.FirstChild;
		while (childHandle.IsAssigned && IsValid(childHandle))
		{
			MarkDirty(childHandle);
			childHandle = mTransforms[(int32)childHandle.Index].NextSibling;
		}

		// Mark ancestors dirty so UpdateTransforms reaches this subtree.
		// UpdateTransforms only processes dirty roots - if a child is dirty
		// but its root isn't, the child's world matrix never gets recomputed.
		if (data.Parent.IsAssigned)
			MarkDirty(data.Parent);
	}

	/// O(1) doubly-linked unlink. Uses childTransform.PrevSibling /
	/// NextSibling to splice the entity out without walking from the head.
	/// Updates the appropriate head/tail pointer when the child was at an
	/// end of the list.
	private void RemoveFromParent(EntityHandle child)
	{
		var childTransform = ref mTransforms[(int32)child.Index];
		let parentHandle = childTransform.Parent;
		let prev = childTransform.PrevSibling;
		let next = childTransform.NextSibling;

		// Splice this entity out: connect prev <-> next directly.
		if (prev.IsAssigned)
			mTransforms[(int32)prev.Index].NextSibling = next;
		if (next.IsAssigned)
			mTransforms[(int32)next.Index].PrevSibling = prev;

		if (parentHandle.IsAssigned)
		{
			// Update parent's head/tail if we were at either end.
			var parentTransform = ref mTransforms[(int32)parentHandle.Index];
			if (parentTransform.FirstChild == child)
				parentTransform.FirstChild = next;
			if (parentTransform.LastChild == child)
				parentTransform.LastChild = prev;
		}
		else
		{
			// Update root head/tail.
			if (mFirstRoot == child)
				mFirstRoot = next;
			if (mLastRoot == child)
				mLastRoot = prev;
		}

		childTransform.Parent = .Invalid;
		childTransform.NextSibling = .Invalid;
		childTransform.PrevSibling = .Invalid;
	}

	private void DestroyEntityImmediate(EntityHandle entity)
	{
		if (!IsValid(entity))
			return;

		let index = (int32)entity.Index;

		// Destroy children first (recursive)
		var childHandle = mTransforms[index].FirstChild;
		while (childHandle.IsAssigned)
		{
			let nextSibling = IsValid(childHandle) ? mTransforms[(int32)childHandle.Index].NextSibling : EntityHandle.Invalid;
			DestroyEntityImmediate(childHandle);
			childHandle = nextSibling;
		}

		// Unparent
		RemoveFromParent(entity);

		// Notify all modules
		for (let module in mModules)
			module.OnEntityDestroyed(entity);

		// Clean up V2 prefab modification tracking
		mLocalModifications.ClearEntity(entity);

		// Remove from ID map
		var slot = ref mEntities[index];
		mEntityIdMap.Remove(slot.PersistentId);

		// Free entity slot
		if (slot.Name != null)
		{
			delete slot.Name;
			slot.Name = null;
		}
		slot.Alive = false;
		slot.Active = false;
		slot.PersistentId = .Empty;
		mEntityFreeList.Add(index);
		mAliveCount--;
		mRevision++;

		// Clear transform
		var transform = ref mTransforms[index];
		transform = .();
	}

	private void ProcessDeferredDestroys()
	{
		for (let entity in mPendingDestroys)
			DestroyEntityImmediate(entity);
		mPendingDestroys.Clear();
	}

	public ~this()
	{
		Dispose();
	}

	public void Dispose()
	{
		if (mDisposed)
			return;
		mDisposed = true;

		// Destroy all modules (this cleans up their component pools)
		for (let module in mModules.Reversed)
		{
			module.OnSceneDestroy();
			module.Dispose();
			delete module;
		}
		mModules.Clear();
		mModulesByType.Clear();

		// Clean up entity names
		for (var slot in ref mEntities)
		{
			if (slot.Name != null)
				delete slot.Name;
		}

		// Clean up phase function lists
		for (int i = 0; i < (int)ScenePhase.COUNT; i++)
			delete mPhaseFunctions[i];
	}
}
