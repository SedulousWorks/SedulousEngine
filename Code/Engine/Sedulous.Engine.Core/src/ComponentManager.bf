namespace Sedulous.Engine.Core;

using System;
using System.Collections;

/// Manages a pool of components of type T.
/// IS-A SceneModule - one instance per scene, owns the pool, handles lifecycle.
///
/// Provides:
///   - CreateComponent(entity) -> ComponentHandle<T>
///   - DestroyComponent(handle)
///   - Get(handle) -> T (nullable)
///   - GetForEntity(entity) -> T (nullable, linear scan)
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
	public ComponentHandle<T> CreateComponent(EntityHandle entity)
	{
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

		OnComponentDestroyed(slot.Component);

		delete slot.Component;
		slot.Component = null;
		slot.Occupied = false;
		mFreeList.Add((int32)handle.Index);
		mActiveCount--;
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

	/// Finds the first component attached to the given entity.
	/// Linear scan - cache the result if called frequently.
	public T GetForEntity(EntityHandle entity)
	{
		for (let slot in ref mSlots)
		{
			if (slot.Occupied && slot.Component.Owner == entity)
				return slot.Component;
		}
		return null;
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

	/// Called when an entity is destroyed - destroys all components owned by that entity.
	public override void OnEntityDestroyed(EntityHandle entity)
	{
		for (int32 i = 0; i < mSlots.Count; i++)
		{
			var slot = ref mSlots[i];
			if (slot.Occupied && slot.Component.Owner == entity)
			{
				OnComponentDestroyed(slot.Component);
				delete slot.Component;
				slot.Component = null;
				slot.Occupied = false;
				mFreeList.Add(i);
				mActiveCount--;
			}
		}
	}

	/// Called when an entity's active state changes - syncs to all components owned by that entity.
	public override void OnEntityActiveChanged(EntityHandle entity, bool active)
	{
		for (var slot in ref mSlots)
		{
			if (slot.Occupied && slot.Component.Owner == entity)
				slot.Component.IsActive = active;
		}
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
