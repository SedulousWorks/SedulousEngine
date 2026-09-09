namespace Sedulous.Physics;

enum JointKind : uint8
{
	case Fixed;
	case Point;
	case Hinge;
	case Slider;
	case Distance;
}
