using System;
using Sedulous.Core;

namespace Sedulous.Animation;

/// Sampling clips into poses, and blending poses together. STATELESS: every one of these is
/// a pure function of what it is handed, which is what lets the graph call them freely.
static class AnimationSampler
{
	/// Hermite between two keys, with the tangents scaled by the interval they span: a
	/// tangent is a rate, so it means nothing until it is told over how long.
	public static Float3 CubicSplineVec3(Keyframe<Float3> prev, Keyframe<Float3> next, float t,
		float duration)
	{
		let t2 = t * t;
		let t3 = t2 * t;
		let p0 = prev.Value;
		let m0 = prev.OutTangent * duration;
		let p1 = next.Value;
		let m1 = next.InTangent * duration;

		let h00 = 2.0f * t3 - 3.0f * t2 + 1.0f;
		let h10 = t3 - 2.0f * t2 + t;
		let h01 = -2.0f * t3 + 3.0f * t2;
		let h11 = t3 - t2;
		return p0 * h00 + m0 * h10 + p1 * h01 + m1 * h11;
	}

	/// The rotation's spline, glTF's rule: the same Hermite as a vector's, on the four
	/// components with their tangents, then normalized. The tangents had been ignored, so every
	/// key eased in and out.
	public static Quaternion CubicSplineQuat(Keyframe<Quaternion> prev, Keyframe<Quaternion> next,
		float t, float duration)
	{
		let t2 = t * t;
		let t3 = t2 * t;
		let h00 = 2.0f * t3 - 3.0f * t2 + 1.0f;
		let h10 = (t3 - 2.0f * t2 + t) * duration;
		let h01 = -2.0f * t3 + 3.0f * t2;
		let h11 = (t3 - t2) * duration;
		let p0 = prev.Value;
		let m0 = prev.OutTangent;
		let m1 = next.InTangent;
		// The keys on one hemisphere, as a slerp would take them.
		let side = ((p0.X * next.Value.X + p0.Y * next.Value.Y + p0.Z * next.Value.Z
			+ p0.W * next.Value.W) < 0.0f) ? -1.0f : 1.0f;
		let p1 = Quaternion(next.Value.X * side, next.Value.Y * side, next.Value.Z * side, next.Value.W * side);
		return Normalized(Quaternion(p0.X * h00 + m0.X * h10 + p1.X * h01 + m1.X * h11 * side,
			p0.Y * h00 + m0.Y * h10 + p1.Y * h01 + m1.Y * h11 * side,
			p0.Z * h00 + m0.Z * h10 + p1.Z * h01 + m1.Z * h11 * side,
			p0.W * h00 + m0.W * h10 + p1.W * h01 + m1.W * h11 * side));
	}

	/// A vector track at a time. The default is answered for an empty track, so a bone with
	/// no track keeps whatever it already had.
	public static Float3 SampleVec3(AnimationTrack<Float3> track, float time,
		Float3 defaultValue = .(0, 0, 0))
	{
		if ((track == null) || track.Keyframes.IsEmpty)
			return defaultValue;

		let lookup = track.FindKeyframes(time);
		if (!lookup.IsValid)
			return defaultValue;

		let prev = track.Keyframes[lookup.Prev];
		let next = track.Keyframes[lookup.Next];
		switch (track.Interpolation)
		{
		case .Step: return prev.Value;
		case .Linear: return Lerp(prev.Value, next.Value, lookup.T);
		case .CubicSpline:
			return CubicSplineVec3(prev, next, lookup.T, next.Time - prev.Time);
		}
	}

	public static Quaternion SampleQuat(AnimationTrack<Quaternion> track, float time,
		Quaternion defaultValue = Quaternion.Identity)
	{
		if ((track == null) || track.Keyframes.IsEmpty)
			return defaultValue;

		let lookup = track.FindKeyframes(time);
		if (!lookup.IsValid)
			return defaultValue;

		let prev = track.Keyframes[lookup.Prev];
		let next = track.Keyframes[lookup.Next];
		switch (track.Interpolation)
		{
		case .Step: return prev.Value;
		case .Linear: return Slerp(prev.Value, next.Value, lookup.T);
		case .CubicSpline:
			return CubicSplineQuat(prev, next, lookup.T, next.Time - prev.Time);
		}
	}

	/// Samples a clip into a set of poses.
	///
	/// Every bone starts at its BIND pose, so a bone the clip says nothing about keeps the
	/// shape the skeleton was built with rather than collapsing to nothing.
	public static void SampleClip(AnimationClip clip, Skeleton skeleton, float time,
		Span<BoneTransform> outPoses)
	{
		let boneCount = skeleton.BoneCount;
		for (int32 i = 0; (i < boneCount) && (i < outPoses.Length); i++)
		{
			let bone = skeleton.GetBone(i);
			outPoses[i] = (bone != null) ? bone.LocalBindPose : BoneTransform();
		}

		var sampleTime = time;
		if (clip.IsLooping && (clip.Duration > 0.0f))
		{
			// A POSITIVE modulo, so a time before the start wraps to the end of the clip
			// rather than sampling a negative one.
			sampleTime = time - clip.Duration * Floor(time / clip.Duration);
			if (sampleTime < 0.0f)
				sampleTime += clip.Duration;
		}
		else
		{
			sampleTime = Clamp(time, 0.0f, clip.Duration);
		}

		for (let track in clip.PositionTracks)
		{
			let bone = track.BoneIndex;
			if ((bone >= 0) && (bone < outPoses.Length))
				outPoses[bone].Position = SampleVec3(track, sampleTime, outPoses[bone].Position);
		}
		for (let track in clip.RotationTracks)
		{
			let bone = track.BoneIndex;
			if ((bone >= 0) && (bone < outPoses.Length))
				outPoses[bone].Rotation = SampleQuat(track, sampleTime, outPoses[bone].Rotation);
		}
		for (let track in clip.ScaleTracks)
		{
			let bone = track.BoneIndex;
			if ((bone >= 0) && (bone < outPoses.Length))
				outPoses[bone].Scale = SampleVec3(track, sampleTime, outPoses[bone].Scale);
		}
	}

	/// A straight blend of two poses: nought is all of the first, one is all of the second.
	public static void BlendPoses(Span<BoneTransform> a, Span<BoneTransform> b, float factor,
		Span<BoneTransform> outPoses)
	{
		let count = Min(Min(a.Length, b.Length), outPoses.Length);
		for (int i = 0; i < count; i++)
			outPoses[i] = BoneTransform.Lerp(a[i], b[i], factor);
	}

	/// An ADDITIVE blend: the base, plus the additive scaled by the weight.
	///
	/// Additive because that is what an overlay is: a wave played over a walk adds to the
	/// arm's motion rather than replacing it. The rotation composes rather than lerping, and
	/// the scale multiplies, since neither is a difference you can simply add.
	public static void AdditivePoses(Span<BoneTransform> basePose, Span<BoneTransform> additive,
		float weight, Span<BoneTransform> outPoses)
	{
		let count = Min(Min(basePose.Length, additive.Length), outPoses.Length);
		for (int i = 0; i < count; i++)
		{
			outPoses[i].Position = basePose[i].Position + additive[i].Position * weight;
			outPoses[i].Rotation =
				Slerp(Quaternion.Identity, additive[i].Rotation, weight) * basePose[i].Rotation;
			outPoses[i].Scale = basePose[i].Scale * Lerp(Float3.One, additive[i].Scale, weight);
		}
	}
}
