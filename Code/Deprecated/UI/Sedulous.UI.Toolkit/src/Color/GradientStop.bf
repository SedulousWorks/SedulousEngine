using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// One stop in a colour ramp: a time in 0 to 1 and a colour that may go past white, which is
/// why it is a Float4 rather than a Color.
struct GradientStop
{
	public float Time = 0.0f;
	public Float4 Color = .(0, 0, 0, 0);

	public this() {}

	public this(float time, Float4 color)
	{
		Time = time;
		Color = color;
	}
}
