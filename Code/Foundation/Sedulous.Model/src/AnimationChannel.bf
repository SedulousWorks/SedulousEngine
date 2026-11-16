using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Model;

/// One animated property of one bone, as a list of keyframes plus how to read between
/// them.
class AnimationChannel
{
	private List<AnimationKeyframe> mKeyframes = new .() ~ delete _;

	/// The bone this channel drives.
	public int32 TargetBone;
	public AnimationPath Path = .Translation;
	public AnimationInterpolation Interpolation = .Linear;

	public Span<AnimationKeyframe> Keyframes => .(mKeyframes.Ptr, mKeyframes.Count);
	public int KeyframeCount => mKeyframes.Count;

	public void AddKeyframe(float time, Float4 value) => mKeyframes.Add(.(time, value));
	/// A cubic spline keyframe with its tangents.
	public void AddKeyframe(float time, Float4 value, Float4 inTangent, Float4 outTangent)
		=> mKeyframes.Add(.(time, value, inTangent, outTangent));

	/// The value at a time, clamped to the channel's own range at both ends.
	///
	/// Clamped rather than extrapolated: a clip sampled past its end should hold its last
	/// pose, not carry on rotating.
	public Float4 Sample(float time)
	{
		if (mKeyframes.IsEmpty)
			return .Zero;
		if (mKeyframes.Count == 1)
			return mKeyframes[0].Value;

		if (time <= mKeyframes[0].Time)
			return mKeyframes[0].Value;
		if (time >= mKeyframes[mKeyframes.Count - 1].Time)
			return mKeyframes[mKeyframes.Count - 1].Value;

		int index = 0;
		while ((index < mKeyframes.Count - 1) && (mKeyframes[index + 1].Time < time))
			index++;

		let first = mKeyframes[index];
		let second = mKeyframes[index + 1];
		let t = (time - first.Time) / (second.Time - first.Time);

		switch (Interpolation)
		{
		case .Step:
			return first.Value;

		case .CubicSpline:
			{
				// glTF's Hermite: the tangents are per second, so scaled by the keys' gap; a
				// rotation is the same blend of its components, normalized.
				let dt = second.Time - first.Time;
				let t2 = t * t;
				let t3 = t2 * t;
				let v = first.Value * (2.0f * t3 - 3.0f * t2 + 1.0f)
					+ first.OutTangent * (dt * (t3 - 2.0f * t2 + t))
					+ second.Value * (-2.0f * t3 + 3.0f * t2)
					+ second.InTangent * (dt * (t3 - t2));
				if (Path == .Rotation)
				{
					let q = Normalized(Quaternion(v.X, v.Y, v.Z, v.W));
					return .(q.X, q.Y, q.Z, q.W);
				}
				return v;
			}

		case .Linear:
			// A rotation is a quaternion, and interpolating its four numbers separately
			// does not produce a rotation: the result is off the unit sphere and the pose
			// shears. Slerp is what keeps it a rotation.
			if (Path == .Rotation)
			{
				let a = Quaternion(first.Value.X, first.Value.Y, first.Value.Z, first.Value.W);
				let b = Quaternion(second.Value.X, second.Value.Y, second.Value.Z, second.Value.W);
				let result = Slerp(a, b, t);
				return .(result.X, result.Y, result.Z, result.W);
			}
			return Lerp4(first.Value, second.Value, t);
		}
	}

	private static Float4 Lerp4(Float4 a, Float4 b, float t) => a + (b - a) * t;
}
