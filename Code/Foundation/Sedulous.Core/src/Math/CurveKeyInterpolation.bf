namespace Sedulous.Core;

/// How the segment LEAVING a key is interpolated toward the next key.
enum CurveKeyInterpolation : uint8
{
	/// Hold this key's value until the next key.
	case Constant;
	/// Straight lerp to the next key.
	case Linear;
	/// Cubic Hermite using this key's tangentOut and the next key's tangentIn.
	case Cubic;
}
