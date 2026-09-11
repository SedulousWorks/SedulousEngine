using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// What a tree row carries while it is being dragged: where it came from.
///
/// A FLAT POSITION rather than a node id, because the drop is resolved against the flattened
/// list the view actually shows and the adapter's move speaks the same coordinates.
class TreeDragData : DragData
{
	public int32 SourcePosition = 0;

	public this(int32 sourcePosition) : base("tree/reorder")
	{
		SourcePosition = sourcePosition;
	}
}
