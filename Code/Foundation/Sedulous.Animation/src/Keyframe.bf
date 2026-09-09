namespace Sedulous.Animation;

/// One keyed value at a time. The tangents are read only by a cubic spline.
struct Keyframe<T> where T : struct
{
	public float Time = 0.0f;
	public T Value = default;
	public T InTangent = default;
	public T OutTangent = default;

	public this() {}

	public this(float time, T value)
	{
		Time = time;
		Value = value;
	}

	public this(float time, T value, T inTangent, T outTangent)
	{
		Time = time;
		Value = value;
		InTangent = inTangent;
		OutTangent = outTangent;
	}
}
