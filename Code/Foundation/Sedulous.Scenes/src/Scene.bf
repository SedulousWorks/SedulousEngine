namespace Sedulous.Scenes;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// A scene containing entities, transforms, and component managers.
/// Multiple scenes can coexist — each is fully isolated (own physics world, own components, etc.).
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
		public EntityHandle NextSibling;
		public bool Dirty;
	}

	private List<TransformData> mTransforms = new .() ~ delete _;

	// --- Scene modules ---

	private List<SceneModule> mModules = new .() ~ delete _;
	private Dictionary<Type, SceneModule> mModulesByType = new .() ~ delete _;

	// --- Phase update functions (collected from all modules) ---

	private struct PhaseEntry
	{
		public delegate void(float) Function;
		public float Priority;
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

	/// Scene name (for debugging/identification).
	public String Name { get; set; } = new .("Scene") ~ delete _;

	public this()
	{
		for (int i = 0; i < (int)ScenePhase.COUNT; i++)
			mPhaseFunctions[i] = new .();
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
		transform.NextSibling = .Invalid;
		transform.Dirty = false;

		mAliveCount++;

		let handle = EntityHandle() { Index = (uint32)index, Generation = slot.Generation };
		mEntityIdMap[id] = handle;
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
			// Stale entry — clean up
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

	/// Sets the parent of an entity. Pass EntityHandle.Invalid to unparent.
	public void SetParent(EntityHandle child, EntityHandle parent)
	{
		if (!IsValid(child))
			return;
		if (parent.IsAssigned && !IsValid(parent))
			return;
		if (child == parent)
			return;

		// Remove from current parent's child list
		RemoveFromParent(child);

		var childTransform = ref mTransforms[(int32)child.Index];
		childTransform.Parent = parent;

		// Add to new parent's child list
		if (parent.IsAssigned)
		{
			var parentTransform = ref mTransforms[(int32)parent.Index];
			childTransform.NextSibling = parentTransform.FirstChild;
			parentTransform.FirstChild = child;
		}

		MarkDirty(child);
	}

	/// Gets the parent of an entity.
	public EntityHandle GetParent(EntityHandle entity)
	{
		if (!IsValid(entity))
			return .Invalid;

		return mTransforms[(int32)entity.Index].Parent;
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
				Priority = reg.Priority
			});
		}

		// Collect fixed update registrations
		for (let reg in module.FixedUpdateRegistrations)
		{
			mFixedUpdateFunctions.Add(.()
			{
				Function = reg.Function,
				Priority = reg.Priority
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

	// ==================== Update ====================

	/// Runs the full scene update loop. Called by SceneSubsystem.
	public void Update(float deltaTime)
	{
		mIsUpdating = true;

		RunPhase(.Initialize, deltaTime);
		RunPhase(.PreUpdate, deltaTime);
		RunPhase(.Update, deltaTime);
		RunPhase(.PostUpdate, deltaTime);

		// Transform propagation (internal, not user-registered)
		UpdateTransforms();

		RunPhase(.PostTransform, deltaTime);

		mIsUpdating = false;

		// Process deferred destroys
		ProcessDeferredDestroys();
	}

	/// Runs fixed update functions. Called by SceneSubsystem at fixed timestep.
	public void FixedUpdate(float fixedDeltaTime)
	{
		for (let entry in mFixedUpdateFunctions)
			entry.Function(fixedDeltaTime);
	}

	// ==================== Internal ====================

	private void RunPhase(ScenePhase phase, float deltaTime)
	{
		for (let entry in mPhaseFunctions[(int)phase])
			entry.Function(deltaTime);
	}

	private void UpdateTransforms()
	{
		// Snapshot current world matrices as "previous" before recomputing.
		// Done for ALL entities (not just dirty ones) so that entities whose
		// transforms didn't change this frame still have a valid prev matrix.
		for (int32 i = 0; i < mTransforms.Count; i++)
		{
			if (mEntities[i].Alive)
				mTransforms[i].PrevWorldMatrix = mTransforms[i].WorldMatrix;
		}

		// Update dirty transforms top-down
		for (int32 i = 0; i < mTransforms.Count; i++)
		{
			var data = ref mTransforms[i];
			if (!data.Dirty || !mEntities[i].Alive)
				continue;

			// Only process roots here — children are updated recursively
			if (!data.Parent.IsAssigned)
				UpdateTransformRecursive(i, .Identity);
		}
	}

	private void UpdateTransformRecursive(int32 index, Matrix parentWorld)
	{
		var data = ref mTransforms[index];
		data.WorldMatrix = data.Local.ToMatrix() * parentWorld;
		data.Dirty = false;

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
	}

	private void RemoveFromParent(EntityHandle child)
	{
		var childTransform = ref mTransforms[(int32)child.Index];
		let parentHandle = childTransform.Parent;

		if (!parentHandle.IsAssigned)
			return;

		var parentTransform = ref mTransforms[(int32)parentHandle.Index];

		// Remove from linked list
		if (parentTransform.FirstChild == child)
		{
			parentTransform.FirstChild = childTransform.NextSibling;
		}
		else
		{
			var prev = parentTransform.FirstChild;
			while (prev.IsAssigned && IsValid(prev))
			{
				var prevTransform = ref mTransforms[(int32)prev.Index];
				if (prevTransform.NextSibling == child)
				{
					prevTransform.NextSibling = childTransform.NextSibling;
					break;
				}
				prev = prevTransform.NextSibling;
			}
		}

		childTransform.Parent = .Invalid;
		childTransform.NextSibling = .Invalid;
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
