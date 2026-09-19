namespace Sedulous.Core;

/// How one volume sits relative to another.
[Scriptable(.AllPublic)]
enum ContainmentType : uint8
{
	case Disjoint;
	case Contains;
	case Intersects;
}
