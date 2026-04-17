namespace Sedulous.UI;

using System;

/// Tree-shaped data source. FlattenedTreeAdapter wraps this to present
/// as IListAdapter for ListView-based virtualization.
public interface ITreeAdapter
{
	/// Number of root-level items.
	int32 RootCount { get; }

	/// Number of children for a node. nodeId = -1 means root level.
	int32 GetChildCount(int32 nodeId);

	/// Get the nodeId of the Nth child of a parent. parentId = -1 for roots.
	int32 GetChildId(int32 parentId, int32 childIndex);

	/// Get the depth of a node (0 = root).
	int32 GetDepth(int32 nodeId);

	/// Whether a node has children (can be expanded).
	bool HasChildren(int32 nodeId);

	/// Create a view for a tree item. viewType from GetItemViewType.
	View CreateView(int32 viewType);

	/// Bind data into a view for the given nodeId.
	void BindView(View view, int32 nodeId, int32 depth, bool isExpanded);

	/// View type for a node (for recycler pools).
	int32 GetItemViewType(int32 nodeId) => 0;
}
