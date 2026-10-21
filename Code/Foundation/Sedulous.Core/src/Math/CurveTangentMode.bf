namespace Sedulous.Core;

/// How a key's tangents are kept, which ApplyCurveTangentModes sets them by.
enum CurveTangentMode : uint8
{
	/// In and out as set, each its own: what a key read from older data keeps.
	case Broken;
	/// Both the slope between the keys either side, or to the one neighbour at an end.
	case Auto;
	/// In follows out: one slope through the key.
	case Smooth;
	/// Both zero.
	case Flat;
}
