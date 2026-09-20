using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// A rotate drag's result: the world axis being turned about and the angle so far.
struct RotateDelta
{
	public Float3 Axis = .Zero;
	public float Angle = 0.0f;

	public this() {}
	public this(Float3 axis, float angle)
	{
		Axis = axis;
		Angle = angle;
	}
}
