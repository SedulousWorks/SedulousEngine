using System;

namespace Sedulous.UI;

/// A sheet's `filter` (or `backdrop-filter`): a blur's sigma in dp, and the colour filters a
/// layer's composite applies, a saturation (0 grey, 1 unchanged) and a brightness factor.
struct StyleFilter
{
	public float Blur = 0.0f;
	public float Saturation = 1.0f;
	public float Brightness = 1.0f;

	public this() {}

	public bool FiltersColour => (Saturation != 1.0f) || (Brightness != 1.0f);

	[Commutable]
	public static bool operator==(StyleFilter a, StyleFilter b) =>
		(a.Blur == b.Blur) && (a.Saturation == b.Saturation) && (a.Brightness == b.Brightness);
}
