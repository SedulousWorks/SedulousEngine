namespace Sedulous.Editor.Terrain;

/// What a sculpt dab does to the heightfield under the brush.
enum SculptMode : uint8
{
	case Raise;
	case Lower;
	/// Pulls toward the local neighbourhood average.
	case Smooth;
	/// Pulls toward a picked target height; Ctrl+click sets the target.
	case Flatten;
}
