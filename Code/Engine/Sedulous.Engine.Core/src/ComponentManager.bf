namespace Sedulous.Engine.Core;

using System;
using System.Collections;

/// Manages a pool of components of type T.
/// IS-A SceneModule - one instance per scene, owns the pool, handles lifecycle.
///
/// **Invariant: at most one component of type T per entity.** The entity ->
/// slot reverse map (mEntityToSlot) stores a single int32 per entity, so a
/// second component of the same type on the same entity would silently
/// orphan the first from lookup. CreateComponent asserts against this in
/// debug builds. Callers that need multiple instances of the same data
/// per entity should either compose them into a single component or use
/// a different ComponentManager<T> subclass.
///
/// Provides:
///   - CreateComponent(entity) -> ComponentHandle<T>
///   - DestroyComponent(handle)
///   - Get(handle) -> T (nullable)
///   - GetForEntity(entity) -> T (nullable, O(1) via reverse map)
///   - Iteration over active components
public abstract class ComponentManager<T> : ComponentManagerBase, IComponentManagerSerializer where T : Component, class, new, delete
{
	/// Pool slot - holds the component and generation counter.
	private struct Slot
	{
		public T Component;
		public uint32 Generation;
		public bool Occupied;
	}

	private List<Slot> mSlots = new .() ~ delete _;
	private List<int32> mFreeList = new .() ~ delete _;
	private List<int32> mPendingInit = new .() ~ delete _;
	private int32 mActiveCount = 0;

	/// Reverse map: entity.Index -> slot index in mSlots, or NoSlot if no
	/// component on that entity. Kept in lock-step with slot create/destroy
	/// so GetForEntity is O(1) instead of an O(n) linear scan.
	private List<int32> mEntityToSlot = new .() ~ delete _;
	private const int32 NoSlot = -1;

	/// Number of active components.
	public int32 ActiveCount => mActiveCount;

	/// Total slot count (including free slots). For parallel iteration by index.
	public int32 SlotCount => (int32)mSlots.Count;

	/// Gets the component at a slot index, or null if the slot is empty.
	/// For parallel iteration - callers must check null and IsActive.
	public T GetAtSlot(int32 index)
	{
		if (index < 0 || index >= mSlots.Count) return null;
		let slot = mSlots[index];
		return slot.Occupied ? slot.Component : null;
	}

	/// Creates a component and attaches it to the given entity.
	/// Returns a handle for future access.
	///
	/// Asserts (debug builds) that the entity does not already have a
	/// component of type T. The single-component-per-entity invariant
	/// is required by mEntityToSlot, which can only point at one slot
	/// per entity.
	public ComponentHandle<T> CreateComponent(EntityHandle entity)
	{
		// Lazy-extend the reverse map; most managers won't have a component for
		// every entity so we don't pre-allocate.
		while ((int)entity.Index >= mEntityToSlot.Count)
			mEntityToSlot.Add(NoSlot);

		// Enforce the one-component-per-entity invariant. Without this, the
		// second CreateComponent would orphan the first from the reverse map
		// and break OnEntityDestroyed / GetForEntity semantics.
		Runtime.Assert(mEntityToSlot[(int)entity.Index] == NoSlot,
			"ComponentManager<T>: entity already has a component of this type");

		int32 index;
		if (mFreeList.Count > 0)
		{
			index = mFreeList.PopBack();
		}
		else
		{
			index = (int32)mSlots.Count;
			mSlots.Add(.());
		}

		var slot = ref mSlots[index];
		slot.Generation++;
		slot.Occupied = true;

		let component = new T();
		component.Owner = entity;
		component.IsActive = Scene?.IsActive(entity) ?? true;
		component.Initialized = false;
		slot.Component = component;

		mActiveCount++;
		mPendingInit.Add(index);

		mEntityToSlot[(int)entity.Index] = index;

		OnComponentCreated(component);

		return .() { Index = (uint32)index, Generation = slot.Generation };
	}

	/// Destroys a component by handle.
	public void DestroyComponent(ComponentHandle<T> handle)
	{
		if (!handle.IsAssigned || handle.Index >= (uint32)mSlots.Count)
			return;

		var slot = ref mSlots[(int32)handle.Index];
		if (!slot.Occupied || slot.Generation != handle.Generation)
			return;

		let owner = slot.Component.Owner;

		OnComponentDestroyed(slot.Component);

		delete slot.Component;
		slot.Component = null;
		slot.Occupied = false;
		mFreeList.Add((int32)handle.Index);
		mActiveCount--;

		// Clear the reverse-map entry. The one-component-per-entity invariant
		// (enforced by CreateComponent's assert) guarantees the map points at
		// this slot.
		if ((int)owner.Index < mEntityToSlot.Count)
			mEntityToSlot[(int)owner.Index] = NoSlot;
	}

	/// Resolves a handle to the component. Returns null if invalid or destroyed.
	public T Get(ComponentHandle<T> handle)
	{
		if (!handle.IsAssigned || handle.Index >= (uint32)mSlots.Count)
			return null;

		let slot = ref mSlots[(int32)handle.Index];
		if (!slot.Occupied || slot.Generation != handle.Generation)
			return null;

		return slot.Component;
	}

	/// Finds the component attached to the given entity, or null.
	/// O(1) via the entity->slot reverse map. The slot.Component.Owner check
	/// is a backstop against stale lookups where the entity index was
	/// destroyed and recycled to a new entity with a different Generation
	/// before the map was updated (in practice OnEntityDestroyed clears the
	/// map first, but the guard removes a footgun class).
	public T GetForEntity(EntityHandle entity)
	{
		if ((int)entity.Index >= mEntityToSlot.Count)
			return null;
		let slotIdx = mEntityToSlot[(int)entity.Index];
		if (slotIdx < 0)
			return null;
		let slot = ref mSlots[slotIdx];
		if (!slot.Occupied || slot.Component.Owner != entity)
			return null;
		return slot.Component;
	}

	/// Returns the component for the entity at the given index, or null.
	/// Convenience for frame-aware iteration paths that walk a list of
	/// raw entity indices (e.g. Scene.TransformsUpdatedThisFrame). Caller
	/// is responsible for index-recycling correctness, but in practice
	/// the map is cleared on entity destroy so a non-null result
	/// references the currently-alive component for that index.
	public T GetByEntityIndex(int32 entityIndex)
	{
		if (entityIndex < 0 || entityIndex >= mEntityToSlot.Count)
			return null;
		let slotIdx = mEntityToSlot[entityIndex];
		if (slotIdx < 0)
			return null;
		let slot = ref mSlots[slotIdx];
		return slot.Occupied ? slot.Component : null;
	}

	/// Non-generic: whether the given entity has a component of this type.
	public override bool HasComponent(EntityHandle entity)
	{
		return GetForEntity(entity) != null;
	}

	/// Non-generic: gets the component for the entity, or null.
	public override Component GetComponent(EntityHandle entity)
	{
		return GetForEntity(entity);
	}

	/// Serializes a component's data. Default implementation delegates to ISerializableComponent.
	/// Override for custom serialization logic.
	public virtual void SerializeComponent(T component, IComponentSerializer serializer)
	{
		if (let serializable = component as ISerializableComponent)
			serializable.Serialize(serializer);
	}

	/// Gets the serialization version for components of this type.
	/// Default implementation checks ISerializableComponent, returns 1 otherwise.
	public virtual int32 GetSerializationVersion()
	{
		// Can't check at compile time for generic T, so return a default.
		// Managers with ISerializableComponent components should override or
		// the version is read from the first component instance.
		return 1;
	}

	// ==================== IComponentManagerSerializer ====================

	/// Whether this manager has a component for the given entity.
	public bool HasComponentForEntity(EntityHandle entity)
	{
		return GetForEntity(entity) != null;
	}

	/// Serializes the component belonging to the given entity (write mode).
	public void SerializeEntityComponent(EntityHandle entity, IComponentSerializer serializer)
	{
		let component = GetForEntity(entity);
		if (component != null)
			SerializeComponent(component, serializer);
	}

	/// Creates a component for the entity and deserializes its data (read mode).
	public void DeserializeEntityComponent(EntityHandle entity, IComponentSerializer serializer)
	{
		let handle = CreateComponent(entity);
		let component = Get(handle);
		if (component != null)
			SerializeComponent(component, serializer);
	}

	// ==================== Handle Validation ====================

	/// Checks whether a handle is still valid.
	public bool IsValid(ComponentHandle<T> handle)
	{
		if (!handle.IsAssigned || handle.Index >= (uint32)mSlots.Count)
			return false;

		let slot = ref mSlots[(int32)handle.Index];
		return slot.Occupied && slot.Generation == handle.Generation;
	}

	/// Iterates all active components.
	public ComponentEnumerator ActiveComponents => .(&mSlots);

	/// Called when a component is created (inside CreateComponent). Properties
	/// are NOT set yet - use OnComponentInitialized for setup that depends on config.
	protected virtual void OnComponentCreated(T component) { }

	/// Called once per component after properties have been set, at the start
	/// of the next scene update (before FixedUpdate). Safe to create physics
	/// bodies, resolve resources, etc. Override for deferred initialization.
	protected virtual void OnComponentInitialized(T component) { }

	/// Called when a component is about to be destroyed. Override for cleanup.
	protected virtual void OnComponentDestroyed(T component) { }

	/// Initializes all pending components (calls OnComponentInitialized).
	/// Called by Scene before FixedUpdate each frame.
	public override void InitializePendingComponents()
	{
		if (mPendingInit.Count == 0) return;

		for (let index in mPendingInit)
		{
			var slot = ref mSlots[index];
			if (slot.Occupied && !slot.Component.Initialized)
			{
				slot.Component.Initialized = true;
				OnComponentInitialized(slot.Component);
			}
		}
		mPendingInit.Clear();
	}

	/// Called when an entity is destroyed - destroys the component (if any)
	/// owned by that entity. O(1) via the reverse map, under the one-component-
	/// per-entity invariant enforced by CreateComponent.
	public override void OnEntityDestroyed(EntityHandle entity)
	{
		if ((int)entity.Index >= mEntityToSlot.Count) return;
		let slotIdx = mEntityToSlot[(int)entity.Index];
		if (slotIdx < 0) return;

		var slot = ref mSlots[slotIdx];
		if (slot.Occupied && slot.Component.Owner == entity)
		{
			OnComponentDestroyed(slot.Component);
			delete slot.Component;
			slot.Component = null;
			slot.Occupied = false;
			mFreeList.Add(slotIdx);
			mActiveCount--;
		}

		mEntityToSlot[(int)entity.Index] = NoSlot;
	}

	/// Called when an entity's active state changes - syncs to the component
	/// (if any) owned by that entity. O(1) via the reverse map.
	public override void OnEntityActiveChanged(EntityHandle entity, bool active)
	{
		if ((int)entity.Index >= mEntityToSlot.Count) return;
		let slotIdx = mEntityToSlot[(int)entity.Index];
		if (slotIdx < 0) return;
		var slot = ref mSlots[slotIdx];
		if (slot.Occupied && slot.Component.Owner == entity)
			slot.Component.IsActive = active;
	}

	/// Creates a component on the given entity. Non-generic accessor for editor use.
	public override Component CreateComponentOnEntity(EntityHandle entity)
	{
		let handle = CreateComponent(entity);
		return Get(handle);
	}

	/// Destroys the component on the given entity. Non-generic accessor for
	/// editor use. O(1) via the reverse map.
	public override void DestroyComponentOnEntity(EntityHandle entity)
	{
		if ((int)entity.Index >= mEntityToSlot.Count) return;
		let slotIdx = mEntityToSlot[(int)entity.Index];
		if (slotIdx < 0) return;
		let slot = ref mSlots[slotIdx];
		if (!slot.Occupied || slot.Component.Owner != entity) return;
		ComponentHandle<T> handle = .() { Index = (uint32)slotIdx, Generation = slot.Generation };
		DestroyComponent(handle);
	}

	/// Display name for this component type. Defaults to the type name without "Component" suffix.
	public override void GetComponentDisplayName(String outName)
	{
		typeof(T).GetName(outName);
		if (outName.EndsWith("Component"))
			outName.RemoveToEnd(outName.Length - 9);
	}

	public override void Dispose()
	{
		// Destroy all remaining components
		for (var slot in ref mSlots)
		{
			if (slot.Occupied)
			{
				OnComponentDestroyed(slot.Component);
				delete slot.Component;
				slot.Component = null;
				slot.Occupied = false;
			}
		}
		mActiveCount = 0;
		mFreeList.Clear();
		mEntityToSlot.Clear();

		base.Dispose();
	}

	/// Enumerator over active components in the pool.
	public struct ComponentEnumerator : IEnumerator<T>
	{
		private List<Slot>* mSlots;
		private int32 mIndex;

		public this(List<Slot>* slots)
		{
			mSlots = slots;
			mIndex = -1;
		}

		public Result<T> GetNext() mut
		{
			while (++mIndex < (*mSlots).Count)
			{
				if ((*mSlots)[mIndex].Occupied)
					return .Ok((*mSlots)[mIndex].Component);
			}
			return .Err;
		}
	}
}
