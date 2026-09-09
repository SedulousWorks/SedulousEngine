namespace Sedulous.Physics;

/// What a shape IS.
///
/// Heightfield is appended rather than inserted, which keeps every value already written
/// into cooked data meaning what it did.
enum ShapeKind : uint8
{
	case Box;
	case Sphere;
	case Capsule;
	case Cooked;
	case Plane;
	case Heightfield;
}
