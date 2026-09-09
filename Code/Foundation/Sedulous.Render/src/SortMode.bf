namespace Sedulous.Render;

/// How a category's draws are depth ordered, which is packed into the sort key.
enum SortMode : uint8
{
	/// Opaque work: early depth rejection, and state clustering within a depth band.
	case FrontToBack;
	/// Blended work, where the order IS the result.
	case BackToFront;
}
