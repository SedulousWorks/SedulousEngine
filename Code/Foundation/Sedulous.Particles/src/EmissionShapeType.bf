using Sedulous.Core;

namespace Sedulous.Particles;

[Scriptable(.AllPublic)]
enum EmissionShapeType : uint8
{
	case Point;
	case Sphere;
	case Hemisphere;
	case Box;
	case Cone;
	case Ring;
	case Circle;
	case Edge;
}
