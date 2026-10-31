namespace Sedulous.UI;

/// How a grid track, meaning one row or one column, decides its size.
enum TrackSizeMode
{
	/// As large as the largest thing in it.
	case Auto;
	/// Exactly this many units, whatever is in it.
	case Fixed;
	/// A share of what is LEFT after the fixed and auto tracks have taken theirs, in
	/// proportion to its weight.
	case Flex;
}
