namespace Sedulous.UI;

/// What a drag and drop will actually do.
enum DragDropEffects : int32
{
	/// No drop allowed.
	None = 0,
	/// Moved from source to target.
	Move = 1,
	/// Copied to the target.
	Copy = 2,
	/// A link or reference is made at the target.
	Link = 4
}
