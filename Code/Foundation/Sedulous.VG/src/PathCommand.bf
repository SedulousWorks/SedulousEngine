namespace Sedulous.VG;

/// Commands that define path geometry
public enum PathCommand : uint8
{
	/// Move the pen to a new position (1 point)
	MoveTo,
	/// Draw a straight line to a point (1 point)
	LineTo,
	/// Draw a quadratic Bezier curve (1 control point + 1 endpoint = 2 points)
	QuadTo,
	/// Draw a cubic Bezier curve (2 control points + 1 endpoint = 3 points)
	CubicTo,
	/// Close the current sub-path back to the last MoveTo
	Close
}
