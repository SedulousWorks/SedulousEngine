namespace Sedulous.VG;

/// Determines how the interior of a path is calculated
public enum FillRule
{
	/// A point is inside if a ray crosses an odd number of path edges
	EvenOdd,
	/// A point is inside if the winding number is non-zero
	NonZero
}
