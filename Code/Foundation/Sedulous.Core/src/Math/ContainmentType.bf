namespace Sedulous.Core;

/// How one volume sits relative to another.
enum ContainmentType : uint8
{
	case Disjoint;
	case Contains;
	case Intersects;
}
