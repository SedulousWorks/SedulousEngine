namespace Sedulous.UI;

/// Describes the type of operation a drag-and-drop will perform.
public enum DragDropEffects : int32
{
	/// No drop allowed.
	None = 0,
	/// The data will be moved from source to target.
	Move = 1,
	/// The data will be copied to the target.
	Copy = 2,
	/// A link/reference will be created at the target.
	Link = 4
}
