using System;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// What a tree row carries while it is being dragged: where it came from.
///
/// A FLAT POSITION rather than a node id, because the drop is resolved against the flattened
/// list the view actually shows and the adapter's move speaks the same coordinates.
class TreeDragData : DragData
{
	public int32 SourcePosition = 0;
	/// What the row IS, for a drop outside the tree, set by the tree's owner through
	/// DraggableTreeView.OnDecorateDragData: a hierarchy row names its entity ("entity" and
	/// the entity's id and name). Empty for a tree that names nothing.
	public String ItemKind = new .() ~ delete _;
	public Guid ItemId;
	public String ItemName = new .() ~ delete _;

	public this(int32 sourcePosition) : base("tree/reorder")
	{
		SourcePosition = sourcePosition;
	}
}
