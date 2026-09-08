namespace Sedulous.VG;

/// What one step of a path does. The number of POINTS each consumes is part of the
/// contract: a command stream and a point stream are walked together, so a mismatch
/// silently reinterprets everything after it.
enum PathCommand : uint8
{
	/// Move the pen, starting a new subpath. One point.
	case MoveTo;
	/// A straight line. One point.
	case LineTo;
	/// A quadratic curve: one control point, then the end.
	case QuadTo;
	/// A cubic curve: two control points, then the end.
	case CubicTo;
	/// Back to where the current subpath began. NO points: the destination is already
	/// known.
	case Close;
}
