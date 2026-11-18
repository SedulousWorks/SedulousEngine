using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.Resource;

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
	/// Components marked leaving (MarkLeaving), removed by RemoveLeaving. Few, and only within
	/// a step.
	private List<EntityHandle> mLeaving = new .() ~ delete _;

	/// Adds a component for `entity`, one per type per entity.
	///
	/// Returns a POINTER into the pool, which is transient: do not keep it across a
	/// structural change, re-resolve through Get. Initialisation is DEFERRED to the next
	/// InitializePendingComponents, so a component can see its siblings before it runs.
	public T* Add(EntityHandle entity)
	{
		// Taken off and given back before it left (a script's removeFrom, then addTo, in one
		// step): it was never taken off, so it keeps its values and is not destroyed.
		if (!mLeaving.IsEmpty && Unmark(entity))
			return &mDense[(int)RawIndex(entity)];
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
		let index = RawIndex(entity); // a leaving one too: this is how it leaves
		if (index == cInvalid)
			return;
		if (!mLeaving.IsEmpty)
			Unmark(entity);

		// Narrowed ONCE, past the sentinel check: the sparse map stores uint32 while a pool
		// index is an int, and those are only the same width on a 64 bit target.
		let slot = (int)index;

		// Unlinked first, then the hook is told, on the value copied out: a hook (a
		// behaviour's onDestroy) may add or remove components of this manager, which moves
		// the pool, so the index found above and any address into the pool are only good
		// until it runs.
		T removed = mDense[slot];

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

		OnComponentDestroyed(&removed, entity);
	}

	public void Remove(EntityHandle entity) => RemoveComponent(entity);

	public override bool MarkLeaving(EntityHandle entity)
	{
		if (RawIndex(entity) == cInvalid)
			return false;
		if (!IsLeaving(entity))
			mLeaving.Add(entity);
		return true;
	}

	public override void RemoveLeaving()
	{
		// Taken out first: a destroy hook may mark more, which a later call removes.
		let leaving = scope List<EntityHandle>();
		leaving.AddRange(mLeaving);
		mLeaving.Clear();
		for (let entity in leaving)
			RemoveComponent(entity);
	}

	public override void* GetComponentAddress(EntityHandle entity) => (void*)Get(entity);

	public override uint32 ComponentCount => (uint32)mDense.Count;
	public uint32 Count => (uint32)mDense.Count;

	/// The contiguous fast path: the packed components, and the owners parallel to them. The
	/// raw pool: a component marked leaving is in it until the step ends.
	public Span<T> Dense => mDense;
	public Span<EntityHandle> Owners => mOwners;

	/// Visits every component with its owning entity, dense and with no holes, passing by those
	/// leaving (MarkLeaving), one marked during the walk included.
	public void ForEach(delegate void(T* component, EntityHandle owner) fn)
	{
		for (int i = 0; i < mDense.Count; i++)
		{
			if (mLeaving.IsEmpty || !IsLeaving(mOwners[i]))
				fn(&mDense[i], mOwners[i]);
		}
	}

	public override Span<EntityHandle> OwnerHandles => Owners;
	public override Type ComponentType => typeof(T);

	/// The settings block's ids, and every component's: each one's Ref<T> fields, read by
	/// reflection, so whatever re-pointed one since it was bound is seen.
	public override void CollectResourceIds(HashSet<Guid> outIds)
	{
		base.CollectResourceIds(outIds);
		let type = typeof(T);
		for (int i = 0; i < mDense.Count; i++)
			ReferenceIds.Collect(type, &mDense[i], outIds);
	}

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
	/// Told after a removed component left the pool, with its value: the manager no longer
	/// finds it, and the pointer is to that value, not into the pool.
	protected virtual void OnComponentDestroyed(T* component, EntityHandle entity) {}

	/// The dense index of a live, generation matching component not leaving, or cInvalid.
	private uint32 DenseIndex(EntityHandle entity)
	{
		let dense = RawIndex(entity);
		return ((dense != cInvalid) && !mLeaving.IsEmpty && IsLeaving(entity)) ? cInvalid : dense;
	}

	/// Whether `entity`'s component is marked leaving.
	private bool IsLeaving(EntityHandle entity)
	{
		for (let leaving in mLeaving)
		{
			if (leaving == entity)
				return true;
		}
		return false;
	}

	private bool Unmark(EntityHandle entity)
	{
		for (int i < mLeaving.Count)
		{
			if (mLeaving[i] == entity)
			{
				mLeaving.RemoveAt(i);
				return true;
			}
		}
		return false;
	}

	/// The dense index of a live, generation matching component, leaving or not, or cInvalid.
	private uint32 RawIndex(EntityHandle entity)
	{
		if (!mSparse.TryGetValue(entity.Index, let dense))
			return cInvalid;

		// The stored owner carries the WHOLE handle, so a stale one, whose slot was reused,
		// fails the generation check and reads as absent.
		return (mOwners[(int)dense] == entity) ? dense : cInvalid;
	}
}
