namespace Sedulous.Spline;

/// How a point's handles are decided.
enum SplineHandleMode : uint8
{
	/// Derived from the neighbours by the Catmull-Rom rule and recomputed after an edit.
	/// Drop points, get a smooth curve through them.
	case Auto;
	/// User handles the editor keeps collinear, so the curve stays C1.
	case Smooth;
	/// Independent handles, for a corner or a road grade arc.
	case Broken;
}
