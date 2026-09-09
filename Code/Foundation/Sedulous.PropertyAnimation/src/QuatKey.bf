using Sedulous.Core;

namespace Sedulous.PropertyAnimation;

/// One rotation keyframe. The segments between them are spherically interpolated, along the
/// shorter arc.
struct QuatKey
{
	public float Time = 0.0f;
	public Quaternion Value = .Identity;

	public this() {}

	public this(float time, Quaternion value)
	{
		Time = time;
		Value = value;
	}
}
