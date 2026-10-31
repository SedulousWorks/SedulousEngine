namespace Sedulous.UI;

/// Told when an adapter's data changed, so the list showing it can react.
///
/// The two notifications differ in cost: a whole data set change rebuilds every view, where a
/// range change only re-binds the ones affected. A list that rebuilt for every edit would
/// throw away its recycled views and its scroll position on each keystroke.
interface IListAdapterObserver
{
	/// The whole data set changed: rebuild everything.
	void OnDataSetChanged();

	/// The items in [start, start + count) changed: re-bind just those views.
	void OnItemRangeChanged(int32 start, int32 count);
}
