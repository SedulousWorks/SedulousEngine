namespace Sedulous.Engine.Core;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Jobs;

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
		public EntityHandle NextSibling;
		public bool Dirty;
	}

	private List<TransformData> mTransforms = new .() ~ delete _;

	/// Head of the root entity linked list (entities with no parent).
	private EntityHandle mFirstRoot = .Invalid;

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

		// Append to root list (new entities start as roots)
		AppendToList(handle, ref mFirstRoot);

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
			AppendToList(child, ref parentTransform.FirstChild);
		}
		else
		{
			AppendToList(child, ref mFirstRoot);
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
			// Prepend
			if (parent.IsAssigned)
			{
				var parentTransform = ref mTransforms[(int32)parent.Index];
				childTransform.NextSibling = parentTransform.FirstChild;
				parentTransform.FirstChild = child;
			}
			else
			{
				childTransform.NextSibling = mFirstRoot;
				mFirstRoot = child;
			}
		}
		else
		{
			// Insert after the specified sibling
			var afterTransform = ref mTransforms[(int32)afterSibling.Index];
			childTransform.NextSibling = afterTransform.NextSibling;
			afterTransform.NextSibling = child;
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
			InsertIntoList(entity, ref parentTransform.FirstChild, targetIndex);
		}
		else
		{
			InsertIntoList(entity, ref mFirstRoot, targetIndex);
		}

		MarkDirty(entity);
	}

	/// Inserts an entity into a sibling linked list at the given index.
	private void InsertIntoList(EntityHandle entity, ref EntityHandle listHead, int32 targetIndex)
	{
		var childTransform = ref mTransforms[(int32)entity.Index];

		if (targetIndex <= 0 || !listHead.IsAssigned)
		{
			// Prepend
			childTransform.NextSibling = listHead;
			listHead = entity;
		}
		else
		{
			// Walk to the sibling before the target position
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
			childTransform.NextSibling = prevTransform.NextSibling;
			prevTransform.NextSibling = entity;
		}
	}

	/// Appends an entity to the end of a sibling linked list.
	private void AppendToList(EntityHandle entity, ref EntityHandle listHead)
	{
		var childTransform = ref mTransforms[(int32)entity.Index];
		childTransform.NextSibling = .Invalid;

		if (!listHead.IsAssigned)
		{
			listHead = entity;
			return;
		}

		// Walk to the end
		var tail = listHead;
		while (true)
		{
			let next = mTransforms[(int32)tail.Index].NextSibling;
			if (!next.IsAssigned || !IsValid(next))
				break;
			tail = next;
		}

		mTransforms[(int32)tail.Index].NextSibling = entity;
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

	/// Collects all components attached to the given entity across all managers.
	public void GetComponents(EntityHandle entity, List<Component> outComponents)
	{
		Console.WriteLine("[Scene.GetComponents] entity idx={} gen={}, scanning {} modules", entity.Index, entity.Generation, mModules.Count);
		for (let module in mModules)
		{
			if (let manager = module as ComponentManagerBase)
			{
				let comp = manager.GetComponent(entity);
				Console.WriteLine("[Scene.GetComponents]   Manager '{}': comp={}", manager.GetType().GetName(.. scope .()), comp != null ? "found" : "null");
				if (comp != null)
					outComponents.Add(comp);
			}
			else
			{
				Console.WriteLine("[Scene.GetComponents]   Module '{}': not a ComponentManagerBase", module.GetType().GetName(.. scope .()));
			}
		}
	}

	// ==================== Update ====================

	/// Runs the full scene update loop. Called by SceneSubsystem.
	public void Update(float deltaTime)
	{
		mIsUpdating = true;

		RunPhase(.Initialize, deltaTime);
		RunPhase(.PreUpdate, deltaTime);
		RunPhase(.Update, deltaTime);
		RunAsyncPhase(deltaTime);
		RunPhase(.PostUpdate, deltaTime);

		// Transform propagation (internal, not user-registered)
		UpdateTransforms();

		RunPhase(.PostTransform, deltaTime);

		mIsUpdating = false;

		// Process deferred destroys
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

	/// Runs the AsyncUpdate phase - all registered functions execute concurrently.
	/// Each function should only access its own component pool.
	private void RunAsyncPhase(float deltaTime)
	{
		let asyncFunctions = mPhaseFunctions[(int)ScenePhase.AsyncUpdate];
		let count = (int32)asyncFunctions.Count;
		if (count == 0)
			return;

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

	private void UpdateTransforms()
	{
	    let count = (int32)mTransforms.Count;
	    if (count == 0) return;

	    // Pass 1: Snapshot previous world matrices
	    for (int32 i = 0; i < count; i++)
	    {
	        if (mEntities[i].Alive)
	            mTransforms[i].PrevWorldMatrix = mTransforms[i].WorldMatrix;
	    }

	    // Pass 2: Collect dirty roots, then update each subtree
	    for (int32 i = 0; i < count; i++)
	    {
	        if (mTransforms[i].Dirty && mEntities[i].Alive && !mTransforms[i].Parent.IsAssigned)
	            UpdateTransformRecursive(i, .Identity);
	    }
	}

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

		if (parentHandle.IsAssigned)
		{
			// Remove from parent's child list
			var parentTransform = ref mTransforms[(int32)parentHandle.Index];

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
		}
		else
		{
			// Remove from root list
			if (mFirstRoot == child)
			{
				mFirstRoot = childTransform.NextSibling;
			}
			else
			{
				var prev = mFirstRoot;
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
