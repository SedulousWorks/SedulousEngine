using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// A color stop in a gradient at a normalized offset (0-1)
public struct GradientStop
{
	/// Position along the gradient (0.0 = start, 1.0 = end)
	public float Offset;
	/// Color at this stop
	public Color Color;

	public this(float offset, Color color)
	{
		Offset = offset;
		Color = color;
	}
}
