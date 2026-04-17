namespace Sedulous.UI;

using System;
using System.Collections;

/// Pool of views keyed by view type. Recycles views that scroll out of
/// the viewport so ListView doesn't allocate per-scroll.
public class ViewRecycler
{
	private Dictionary<int32, List<View>> mPools = new .() ~ {
		for (let kv in _)
		{
			for (let v in kv.value) delete v;
			delete kv.value;
		}
		delete _;
	};

	/// Diagnostic counters.
	public int32 CreatedCount { get; private set; }
	public int32 RecycledCount { get; private set; }
	public int32 ReusedCount { get; private set; }

	/// Try to get a recycled view of the given type. Returns null if none.
	public View Acquire(int32 viewType)
	{
		if (mPools.TryGetValue(viewType, let pool) && pool.Count > 0)
		{
			let view = pool.PopBack();
			ReusedCount++;
			return view;
		}
		return null;
	}

	/// Return a view to the pool for reuse.
	public void Recycle(View view, int32 viewType)
	{
		if (!mPools.TryGetValue(viewType, var pool))
		{
			pool = new List<View>();
			mPools[viewType] = pool;
		}
		pool.Add(view);
		RecycledCount++;
	}

	/// Get or create a view via the adapter. Reuses from pool if available.
	public View GetOrCreate(IListAdapter adapter, int32 position)
	{
		let viewType = adapter.GetItemViewType(position);
		var view = Acquire(viewType);
		if (view == null)
		{
			view = adapter.CreateView(viewType);
			CreatedCount++;
		}
		adapter.BindView(view, position);
		return view;
	}

	/// Clear all pools and delete pooled views.
	public void Clear()
	{
		for (let kv in mPools)
		{
			for (let v in kv.value) delete v;
			kv.value.Clear();
		}
	}
}
