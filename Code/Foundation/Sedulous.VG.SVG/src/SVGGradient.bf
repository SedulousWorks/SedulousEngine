using System;
using System.Collections;
using Sedulous.VG;

namespace Sedulous.VG.SVG;

/// A parsed gradient definition, resolved against a referencing element later.
///
/// It is stored as parsed rather than as a fill, because the same definition can be
/// referenced by several elements and its default units are RELATIVE to whichever one is
/// using it.
class SVGGradient
{
	public bool Radial = false;

	/// The line, in fractions of the referencing element's box unless user space is set.
	public float X1 = 0.0f;
	public float Y1 = 0.0f;
	public float X2 = 1.0f;
	public float Y2 = 0.0f;

	/// The circle. A focal point is not supported, matching what the fill can express.
	public float Cx = 0.5f;
	public float Cy = 0.5f;
	public float R = 0.5f;

	/// From gradientUnits. False, the SVG default, means the geometry above is a fraction
	/// of the referencing element's bounding box; true means document coordinates.
	public bool UserSpace = false;

	public VGGradientSpread Spread = .Pad;
	public List<GradientStop> Stops = new .() ~ delete _;
}
