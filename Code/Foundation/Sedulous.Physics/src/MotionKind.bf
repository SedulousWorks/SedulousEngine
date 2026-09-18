using Sedulous.Core;

namespace Sedulous.Physics;

[Scriptable(.AllPublic)]
enum MotionKind : uint8
{
	case Static;
	case Kinematic;
	case Dynamic;
}
