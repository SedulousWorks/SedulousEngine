namespace Sedulous.UI;

/// Interface for views that can initiate a drag operation.
/// Implement on a View subclass to make it draggable.
public interface IDragSource
{
	/// Create the data payload for this drag.
	/// Return null to cancel the drag before it starts.
	DragData CreateDragData();

	/// Create a visual preview shown during drag.
	/// Return null for a default semi-transparent indicator.
	/// The returned view is owned by the DragDropManager (deleted on drag end).
	View CreateDragVisual(DragData data);

	/// Called when the drag actually starts (threshold exceeded).
	/// Use this to customize DragDropManager properties (AdornerOffset, cursors).
	void OnDragStarted(DragData data);

	/// Called when the drag ends (completed or cancelled).
	void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled);
}
