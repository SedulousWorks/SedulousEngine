namespace Sedulous.VG;

/// How a stroke ends.
enum VGLineCap
{
	/// Flat, at exactly the endpoint.
	case Butt;
	/// Rounded, extending half the stroke width past the endpoint.
	case Round;
	/// Square, extending half the stroke width past the endpoint.
	case Square;
}
