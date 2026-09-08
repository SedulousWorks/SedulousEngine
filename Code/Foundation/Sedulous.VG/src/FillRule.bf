namespace Sedulous.VG;

/// How the interior of a path is decided.
enum FillRule
{
	/// Inside when a ray from the point crosses an odd number of edges. Overlapping
	/// subpaths cancel, which is how a hole is cut without stating that it is one.
	case EvenOdd;
	/// Inside when the winding number is non zero, so direction decides: a hole is a
	/// subpath wound the other way.
	case NonZero;
}
