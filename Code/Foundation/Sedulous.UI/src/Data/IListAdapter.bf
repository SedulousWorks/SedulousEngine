namespace Sedulous.UI;

using System;

/// Observer for adapter data changes. ListView implements this.
public interface IListAdapterObserver
{
	/// Entire data set changed — rebuild everything.
	void OnDataSetChanged();

	/// Items in [start, start+count) changed — rebind those views.
	void OnItemRangeChanged(int32 start, int32 count);
}

/// Data source for ListView. Adapter owns both view creation and data
/// binding. Supports multiple view types for heterogeneous lists.
public interface IListAdapter
{
	/// Total number of items.
	int32 ItemCount { get; }

	/// View type for an item (for recycling pools). Default: 0.
	int32 GetItemViewType(int32 position) => 0;

	/// Create a new view for the given type. Owned by ListView/Recycler.
	View CreateView(int32 viewType);

	/// Bind data at `position` into an existing view.
	void BindView(View view, int32 position);

	/// Number of distinct view types (for recycler pool sizing).
	int32 ViewTypeCount => 1;

	/// Height for a specific item. Return <= 0 to use ListView.ItemHeight.
	/// Override for variable-height items.
	float GetItemHeight(int32 position) => -1;

	/// Set the observer for data change notifications.
	void SetObserver(IListAdapterObserver observer);
}

/// Base class for adapters with built-in observer support.
/// Subclass this instead of implementing IListAdapter directly for
/// automatic change notification.
public abstract class ListAdapterBase : IListAdapter
{
	private IListAdapterObserver mObserver;

	public abstract int32 ItemCount { get; }
	public abstract View CreateView(int32 viewType);
	public abstract void BindView(View view, int32 position);

	public void SetObserver(IListAdapterObserver observer)
	{
		mObserver = observer;
	}

	/// Call when the entire data set changes.
	public void NotifyDataSetChanged()
	{
		mObserver?.OnDataSetChanged();
	}

	/// Call when items in [start, start+count) changed.
	public void NotifyRangeChanged(int32 start, int32 count)
	{
		mObserver?.OnItemRangeChanged(start, count);
	}
}
