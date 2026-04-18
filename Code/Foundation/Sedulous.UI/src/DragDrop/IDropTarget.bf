namespace Sedulous.UI;

/// Interface for views that can accept dropped data.
/// Implement on a View subclass to make it a drop target.
public interface IDropTarget
{
	/// Check if this target can accept the given drag data at this position.
	/// Called each frame while dragging over this target.
	DragDropEffects CanAcceptDrop(DragData data, float localX, float localY);

	/// Called when a drag enters this target's bounds.
	void OnDragEnter(DragData data, float localX, float localY);

	/// Called each frame while a drag is over this target.
	void OnDragOver(DragData data, float localX, float localY);

	/// Called when a drag leaves this target's bounds.
	void OnDragLeave(DragData data);

	/// Called when data is dropped on this target. Returns the actual effect performed.
	DragDropEffects OnDrop(DragData data, float localX, float localY);
}
