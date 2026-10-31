namespace Sedulous.UI;

/// A list's data source, owning both view CREATION and data binding.
///
/// The split is what makes recycling possible: a view is created once per view type and then
/// re-bound to a different item as the list scrolls, rather than being rebuilt per row.
interface IListAdapter
{
	int32 ItemCount { get; }

	/// Which recycling pool an item's view belongs to. A list with one row shape leaves this
	/// alone.
	int32 GetItemViewType(int32 position);

	/// A new view for a type. OWNERSHIP transfers.
	View CreateView(int32 viewType);

	/// Binds the data at a position into an EXISTING view, which may have been showing another
	/// item a moment ago.
	void BindView(View view, int32 position);

	/// How many distinct view types there are, for sizing the recycler's pools.
	int32 ViewTypeCount { get; }

	/// An item's own height. Nought or less defers to the list's uniform item height, which is
	/// what a variable height list overrides.
	float GetItemHeight(int32 position);

	/// BORROWED: the observer outlives the adapter's use of it.
	void SetObserver(IListAdapterObserver observer);
}
