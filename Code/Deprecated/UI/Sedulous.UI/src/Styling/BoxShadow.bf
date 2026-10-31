using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A `box-shadow`: the CSS tuple.
///
/// Offsets, blur and spread are in logical units at resolve time; the vector graphics layer
/// draws the whole thing as one blurred rounded rectangle.
struct BoxShadow
{
	public float OffsetX = 0.0f;
	public float OffsetY = 0.0f;
	public float Blur = 0.0f;
	public float Spread = 0.0f;
	public Color Color = .(0.0f, 0.0f, 0.0f, 0.5f);
	/// Drawn INSIDE the box rather than around it.
	public bool Inset = false;

	public this() {}

	[Commutable]
	public static bool operator==(BoxShadow a, BoxShadow b) =>
		(a.OffsetX == b.OffsetX) && (a.OffsetY == b.OffsetY) && (a.Blur == b.Blur)
		&& (a.Spread == b.Spread) && (a.Color == b.Color) && (a.Inset == b.Inset);
}
