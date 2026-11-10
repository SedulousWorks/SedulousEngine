namespace Sedulous.Core;

/// Which side of a plane a volume falls on. Front is the normal's positive side.
enum PlaneIntersectionType : uint8
{
	case Front;
	case Back;
	case Intersecting;
}
