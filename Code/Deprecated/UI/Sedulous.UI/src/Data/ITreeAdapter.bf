namespace Sedulous.UI;

/// A tree's data source, addressed by NODE ID rather than by position.
///
/// A node id outlives an expand or collapse where a flat position does not, which is what lets
/// selection and expansion survive the tree changing shape.
interface ITreeAdapter
{
	int32 RootCount { get; }

	/// How many children a node has. An id of -1 means the root level.
	int32 GetChildCount(int32 nodeId);

	/// The id of a parent's Nth child. A parent of -1 means the roots.
	int32 GetChildId(int32 parentId, int32 childIndex);

	/// How deep a node sits, nought being a root.
	int32 GetDepth(int32 nodeId);

	/// Whether a node can be expanded at all.
	bool HasChildren(int32 nodeId);

	/// OWNERSHIP transfers.
	View CreateView(int32 viewType);

	/// Binds a node into a view.
	///
	/// To indent a row so its content clears the expander column, take the offset from the
	/// tree's own ContentInset(depth) rather than writing a pixel constant: a literal drifts
	/// from the tree's indent width and the chevron ends up overlapping the text.
	void BindView(View view, int32 nodeId, int32 depth, bool isExpanded);

	int32 GetItemViewType(int32 nodeId);

	/// BORROWED.
	void SetObserver(ITreeAdapterObserver observer);
}
