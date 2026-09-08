using Sedulous.Core;

namespace Sedulous.VG;

/// One colour at a normalised offset along a gradient.
struct GradientStop
{
	/// Zero at the start of the gradient, one at its end.
	public float Offset = 0.0f;
	public Color Color = .White;

	public this() {}

	public this(float offset, Color color)
	{
		Offset = offset;
		Color = color;
	}
}
