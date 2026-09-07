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

		case .Linear, .CubicSpline:
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
			// Cubic spline falls through to linear, as it does in Raptor. A file asking
			// for it gets a straight line between its keys rather than a refusal.
			return Lerp4(first.Value, second.Value, t);
		}
	}

	private static Float4 Lerp4(Float4 a, Float4 b, float t) => a + (b - a) * t;
}
