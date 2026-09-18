using Sedulous.Core;

namespace Sedulous.Physics;

[Scriptable(.AllPublic)]
enum JointKind : uint8
{
	case Fixed;
	case Point;
	case Hinge;
	case Slider;
	case Distance;
}
