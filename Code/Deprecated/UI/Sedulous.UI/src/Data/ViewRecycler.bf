using System.Collections;

namespace Sedulous.UI;

/// Pools list item views by view type so a scrolling list re-binds rather than rebuilds.
///
/// This is what keeps a long list cheap: the cost is the number of views ON SCREEN, not the
/// number of items, however far it scrolls.
class ViewRecycler
{
	/// OWNED: a pooled view is held here between uses.
	private Dictionary<int32, List<View>> mPools = new .() ~ ReleasePools(_);
	private int32 mCreatedCount = 0;
	private int32 mRecycledCount = 0;
	private int32 mReusedCount = 0;

	public this() {}

	private static void ReleasePools(Dictionary<int32, List<View>> pools)
	{
		for (let pool in pools.Values)
		{
			for (let view in pool)
				view.ReleaseRef();
			delete pool;
		}
		delete pools;
	}

	/// The diagnostic counters, which is how a list's recycling is checked without watching
	/// allocations: a healthy scroll creates a screenful and reuses everything after.
	public int32 CreatedCount => mCreatedCount;
	public int32 RecycledCount => mRecycledCount;
	public int32 ReusedCount => mReusedCount;

	/// A pooled view of a type, or null when the pool is empty. OWNERSHIP transfers.
	public View Acquire(int32 viewType)
	{
		if (mPools.TryGetValue(viewType, let pool) && !pool.IsEmpty)
		{
			let view = pool.PopBack();
			mReusedCount++;
			return view;
		}
		return null;
	}

	/// Returns a view to its pool. CONSUMES the caller's reference.
	public void Recycle(View view, int32 viewType)
	{
		if (view == null)
			return;

		if (!mPools.TryGetValue(viewType, var pool))
		{
			pool = new List<View>();
			mPools[viewType] = pool;
		}

		pool.Add(view);
		mRecycledCount++;
	}

	/// A bound view for a position, reused from the pool where possible and created only when
	/// not. OWNERSHIP transfers.
	public View GetOrCreate(IListAdapter adapter, int32 position)
	{
		let viewType = adapter.GetItemViewType(position);
		var view = Acquire(viewType);
		if (view == null)
		{
			view = adapter.CreateView(viewType);
			mCreatedCount++;
		}

		adapter.BindView(view, position);
		return view;
	}

	/// Empties every pool, releasing the views held in them.
	public void Clear()
	{
		for (let pool in mPools.Values)
		{
			for (let view in pool)
				view.ReleaseRef();
			pool.Clear();
		}
	}
}
