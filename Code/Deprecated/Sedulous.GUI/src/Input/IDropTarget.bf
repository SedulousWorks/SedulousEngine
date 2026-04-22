namespace Sedulous.GUI;

/// Interface for elements that can receive dropped items.
public interface IDropTarget
{
	/// Returns whether this target can accept the given drag data.
	/// Called to determine if OnDragEnter should be invoked.
	bool CanAcceptDrop(DragData data);

	/// Called when a drag enters this target.
	/// Set args.Effect to indicate acceptance (e.g., .Move, .Copy).
	/// Set to .None to reject the drop at this location.
	void OnDragEnter(DragEventArgs args);

	/// Called while dragging over this target.
	/// Update args.Effect based on position if needed.
	void OnDragOver(DragEventArgs args);

	/// Called when a drag leaves this target.
	void OnDragLeave(DragEventArgs args);

	/// Called when drop occurs on this target.
	/// Set args.Handled = true if drop was successful.
	void OnDrop(DragEventArgs args);
}
