namespace Sedulous.UI;

/// Implemented by a view that can be dragged.
///
/// Found by walking the parent chain of the pressed view, so a label inside a draggable row
/// drags the row.
interface IDragSource
{
	/// The payload. OWNERSHIP transfers. Null CANCELS the drag before it starts, which is how
	/// a source declines based on what was actually grabbed.
	DragData CreateDragData();

	/// The visual carried under the pointer. OWNERSHIP transfers. Null takes the default
	/// translucent indicator.
	View CreateDragVisual(DragData data);

	/// The drag has really started, meaning the movement threshold was passed. The place to
	/// set the adorner offset or cursors.
	void OnDragStarted(DragData data);

	/// The drag finished, whether it completed or was cancelled.
	void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled);
}
