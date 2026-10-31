namespace Sedulous.UI;

/// An adapter with the observer plumbing already done, which is all most adapters need beyond
/// their own data.
abstract class ListAdapterBase : IListAdapter
{
	/// BORROWED: the list owns this and outlives the adapter's use of it.
	private IListAdapterObserver mObserver = null;

	public abstract int32 ItemCount { get; }
	public abstract View CreateView(int32 viewType);
	public abstract void BindView(View view, int32 position);

	public virtual int32 GetItemViewType(int32 position) => 0;
	public virtual int32 ViewTypeCount => 1;
	public virtual float GetItemHeight(int32 position) => -1.0f;

	public void SetObserver(IListAdapterObserver observer) => mObserver = observer;

	/// PUBLIC, because the thing that knows the data changed is as often the model holding
	/// the adapter as the adapter itself. Protected would leave a model with no way to say so.
	public void NotifyDataSetChanged()
	{
		if (mObserver != null)
			mObserver.OnDataSetChanged();
	}

	/// The narrow notification: only the named rows are rebound, in place.
	public void NotifyRangeChanged(int32 start, int32 count)
	{
		if (mObserver != null)
			mObserver.OnItemRangeChanged(start, count);
	}
}
