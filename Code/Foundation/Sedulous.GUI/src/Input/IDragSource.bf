namespace Sedulous.GUI;

/// Interface for elements that can initiate drag operations.
public interface IDragSource
{
	/// Returns whether a drag can be started from this element.
	bool CanStartDrag();

	/// Creates drag data for the drag operation.
	/// Returns null to cancel the drag.
	DragData CreateDragData();

	/// Gets the allowed drop effects for this drag.
	DragDropEffects GetAllowedEffects();

	/// Creates the visual representation for the drag adorner.
	/// Called when the drag actually starts (after threshold).
	void CreateDragVisual(DragAdorner adorner);

	/// Called when the drag operation actually starts (after threshold).
	void OnDragStarted(DragEventArgs args);

	/// Called when the drag completes (success or cancel).
	void OnDragCompleted(DragEventArgs args);
}
