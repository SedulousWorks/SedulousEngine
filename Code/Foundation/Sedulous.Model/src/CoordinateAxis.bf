namespace Sedulous.Model;

/// An axis of a coordinate system.
///
/// Recorded as the source file reported it, so a later stage can correct for a file
/// authored Z up without guessing which way the model was meant to stand.
enum CoordinateAxis : uint32
{
	case PositiveX;
	case NegativeX;
	case PositiveY;
	case NegativeY;
	case PositiveZ;
	case NegativeZ;
}
