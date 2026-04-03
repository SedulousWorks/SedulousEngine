namespace Sedulous.GUI;

/// Represents the allowed effects for a drag-drop operation.
public enum DragDropEffects
{
	/// No drop is allowed.
	None = 0,
	/// Data is copied to the drop target.
	Copy = 1,
	/// Data is moved to the drop target.
	Move = 2,
	/// Data is linked to the drop target.
	Link = 4,
	/// All effects are allowed.
	All = Copy | Move | Link
}
