namespace Sedulous.RHI;

/// Properties of one ray tracing geometry that let the driver skip work.
enum GeometryFlags : uint32
{
	case None = 0;
	/// No any hit shader runs: the geometry never discards a hit, so traversal can stop at
	/// the first one it finds.
	case Opaque = 1;
	/// The any hit shader must run at most once per primitive, which a caller needs when
	/// that shader has side effects.
	case NoDuplicateAnyHitInvocation = 2;
}
