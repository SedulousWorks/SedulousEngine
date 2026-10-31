using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// The colours every vector field's axis labels use.
///
/// Red, green and blue for X, Y and Z is the convention every 3D tool shares, so a number's
/// axis is readable without reading its letter. W takes a warm neutral, because it is not a
/// spatial axis and should not look like one.
static class AxisColors
{
	public static readonly Color X = Color.Rgb(220, 80, 80);
	public static readonly Color Y = Color.Rgb(80, 200, 80);
	public static readonly Color Z = Color.Rgb(80, 120, 220);
	public static readonly Color W = Color.Rgb(200, 180, 120);
}
