using Sedulous.Core;

namespace Sedulous.Particles;

struct CurveKeyColor
{
	public float Time = 0.0f;
	public Float4 Color = .(1, 1, 1, 1);

	public this() {}

	public this(float time, Float4 color)
	{
		Time = time;
		Color = color;
	}
}
