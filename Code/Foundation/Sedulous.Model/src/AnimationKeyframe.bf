using Sedulous.Core;

namespace Sedulous.Model;

/// One keyframe: a time and a value whose meaning comes from the channel's path.
///
/// A single Float4 for every path, which is what lets one channel type drive translation,
/// rotation, scale and a weight without a variant per kind: xyz for a vector, xyzw for a
/// quaternion, x alone for a weight.
struct AnimationKeyframe
{
	public float Time;
	public Float4 Value;
	/// A cubic spline's tangents (per second, as glTF stores them); zero otherwise.
	public Float4 InTangent;
	public Float4 OutTangent;

	public this() { Time = 0.0f; Value = .Zero; InTangent = .Zero; OutTangent = .Zero; }
	public this(float time, Float4 value) { Time = time; Value = value; InTangent = .Zero; OutTangent = .Zero; }
	public this(float time, Float4 value, Float4 inTangent, Float4 outTangent)
	{
		Time = time;
		Value = value;
		InTangent = inTangent;
		OutTangent = outTangent;
	}
}
