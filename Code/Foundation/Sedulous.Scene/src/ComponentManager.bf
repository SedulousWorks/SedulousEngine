using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;

namespace Sedulous.Scene;

/// A typed component pool, stored as a SPARSE SET. T is plain value data.
///
///   Dense    a truly contiguous list with no holes, for cache friendly iteration and
///            straight extraction into a system or the GPU.
///   Owners   the owning entity per dense slot, parallel to it.
///   Sparse   entity index to dense index, for O(1) has, get and remove by entity.
///
/// Removal SWAPS THE LAST element into the hole, which is what keeps the dense list
/// packed. A component is referenced by its owning entity and never by a stashed pointer,
/// because the pool moves under one. At most one component of type T per entity.
///
/// A manager needing stable addresses or polymorphism in the pool can swap the storage
/// behind this same surface with no consumer noticing.
class ComponentManager<T> : ComponentManagerBase where T : struct, new
{
	private const uint32 cInvalid = 0xFFFFFFFF;

	/// Packed component data, no holes.
	private List<T> mDense = new .() ~ delete _;
	/// The owning entity per dense slot.
	private List<EntityHandle> mOwners = new .() ~ delete _;
	/// entity index to dense index.
	private Dictionary<uint32, uint32> mSparse = new .() ~ delete _;
	/// Entities awaiting their initialisation hook.
	private List<EntityHandle> mPendingInit = new .() ~ delete _;

	/// Adds a component for `entity`, one per type per entity.
	///
	/// Returns a POINTER into the pool, which is transient: do not keep it across a
	/// structural change, re-resolve through Get. Initialisation is DEFERRED to the next
	/// InitializePendingComponents, so a component can see its siblings before it runs.
	public T* Add(EntityHandle entity)
	{
		Debug.Assert(!HasComponent(entity), "one component of a type per entity");

		let slot = mDense.Count;
		// CONSTRUCTED, not zeroed: a component's field initialisers are its defaults, and
		// `default` would silently replace them with zero.
		mDense.Add(T());
		mOwners.Add(entity);
		mSparse[entity.Index] = (uint32)slot;
		mPendingInit.Add(entity);
		OnComponentCreated(&mDense[slot], entity);
		return &mDense[slot];
	}

	public override bool HasComponent(EntityHandle entity) => DenseIndex(entity) != cInvalid;
	public bool Has(EntityHandle entity) => HasComponent(entity);

	public override bool AddDefaultComponent(EntityHandle entity)
	{
		if (HasComponent(entity))
			return false;
		Add(entity);
		return true;
	}

	/// The live component for `entity`, or null when it is absent or the handle is stale.
	public T* Get(EntityHandle entity)
	{
		let index = DenseIndex(entity);
		return (index != cInvalid) ? &mDense[(int)index] : null;
	}

	public override void RemoveComponent(EntityHandle entity)
	{
		let index = DenseIndex(entity);
		if (index == cInvalid)
			return;

		// Narrowed ONCE, past the sentinel check: the sparse map stores uint32 while a pool
		// index is an int, and those are only the same width on a 64 bit target.
		let slot = (int)index;
		OnComponentDestroyed(&mDense[slot], entity);

		// Swap the last element into the hole, which is what keeps the pool packed.
		let last = mDense.Count - 1;
		if (slot != last)
		{
			mDense[slot] = mDense[last];
			mOwners[slot] = mOwners[last];
			mSparse[mOwners[slot].Index] = (uint32)slot;
		}
		mDense.PopBack();
		mOwners.PopBack();
		mSparse.Remove(entity.Index);
	}

	public void Remove(EntityHandle entity) => RemoveComponent(entity);

	public override void* GetComponentAddress(EntityHandle entity) => (void*)Get(entity);

	public override uint32 ComponentCount => (uint32)mDense.Count;
	public uint32 Count => (uint32)mDense.Count;

	/// The contiguous fast path: the packed components, and the owners parallel to them.
	public Span<T> Dense => mDense;
	public Span<EntityHandle> Owners => mOwners;

	/// Visits every component with its owning entity, dense and with no holes.
	public void ForEach(delegate void(T* component, EntityHandle owner) fn)
	{
		for (int i = 0; i < mDense.Count; i++)
			fn(&mDense[i], mOwners[i]);
	}

	public override Span<EntityHandle> OwnerHandles => Owners;
	public override Type ComponentType => typeof(T);

	/// Runs the initialisation hook for everything added since the last call, skipping
	/// anything already removed again.
	public override void InitializePendingComponents()
	{
		for (let entity in mPendingInit)
		{
			let component = Get(entity);
			if (component != null)
				OnComponentInitialized(component, entity);
		}
		mPendingInit.Clear();
	}

	/// Sweeps whatever is still held, so a component that owns heap data is torn down by the
	/// same hook a removal uses.
	///
	/// A Beef List of structs frees only the storage, so a manager that never had its
	/// components removed would otherwise leak whatever they own.
	public ~this()
	{
		for (int i = 0; i < mDense.Count; i++)
			OnComponentDestroyed(&mDense[i], mOwners[i]);
	}

	// ---- lifecycle hooks, on the MANAGER rather than the component ----

	protected virtual void OnComponentCreated(T* component, EntityHandle entity) {}
	protected virtual void OnComponentInitialized(T* component, EntityHandle entity) {}
	protected virtual void OnComponentDestroyed(T* component, EntityHandle entity) {}

	/// The dense index of a live, generation matching component, or cInvalid.
	private uint32 DenseIndex(EntityHandle entity)
	{
		if (!mSparse.TryGetValue(entity.Index, let dense))
			return cInvalid;

		// The stored owner carries the WHOLE handle, so a stale one, whose slot was reused,
		// fails the generation check and reads as absent.
		return (mOwners[(int)dense] == entity) ? dense : cInvalid;
	}
}
