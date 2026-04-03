namespace Sedulous.Animation;

using System;
using Sedulous.Core.Mathematics;

/// Samples animation clips at specific times to produce bone transforms.
public static class AnimationSampler
{
	/// Samples a Vector3 track at the given time.
	public static Vector3 SampleVector3(AnimationTrack<Vector3> track, float time, Vector3 defaultValue = default)
	{
		if (track == null || track.Keyframes.Count == 0)
			return defaultValue;

		let (prevIdx, nextIdx, t) = track.FindKeyframes(time);
		if (prevIdx < 0)
			return defaultValue;

		let prev = track.Keyframes[prevIdx];
		let next = track.Keyframes[nextIdx];

		switch (track.Interpolation)
		{
		case .Step:
			return prev.Value;

		case .Linear:
			return Vector3.Lerp(prev.Value, next.Value, t);

		case .CubicSpline:
			return CubicSplineVector3(prev, next, t, next.Time - prev.Time);
		}
	}

	/// Samples a Quaternion track at the given time.
	public static Quaternion SampleQuaternion(AnimationTrack<Quaternion> track, float time, Quaternion defaultValue = default)
	{
		if (track == null || track.Keyframes.Count == 0)
			return defaultValue;

		let (prevIdx, nextIdx, t) = track.FindKeyframes(time);
		if (prevIdx < 0)
			return defaultValue;

		let prev = track.Keyframes[prevIdx];
		let next = track.Keyframes[nextIdx];

		switch (track.Interpolation)
		{
		case .Step:
			return prev.Value;

		case .Linear:
			return Quaternion.Slerp(prev.Value, next.Value, t);

		case .CubicSpline:
			return CubicSplineQuaternion(prev, next, t, next.Time - prev.Time);
		}
	}

	/// Samples an animation clip at the given time, outputting bone transforms.
	/// @param clip The animation clip to sample.
	/// @param skeleton The skeleton to use for default poses.
	/// @param time The time in seconds to sample at.
	/// @param outPoses Output array for bone transforms (must be skeleton.BoneCount in size).
	public static void SampleClip(AnimationClip clip, Skeleton skeleton, float time, Span<BoneTransform> outPoses)
	{
		// Initialize with bind poses
		for (int i = 0; i < skeleton.BoneCount && i < outPoses.Length; i++)
		{
			let bone = skeleton.Bones[i];
			if (bone != null)
				outPoses[i] = bone.LocalBindPose;
			else
				outPoses[i] = .Identity;
		}

		// Handle looping
		float sampleTime = time;
		if (clip.IsLooping && clip.Duration > 0)
		{
			sampleTime = time % clip.Duration;
			if (sampleTime < 0)
				sampleTime += clip.Duration;
		}
		else
		{
			sampleTime = Math.Clamp(time, 0, clip.Duration);
		}

		// Sample position tracks
		for (let track in clip.PositionTracks)
		{
			if (track.BoneIndex >= 0 && track.BoneIndex < outPoses.Length)
			{
				outPoses[track.BoneIndex].Position = SampleVector3(track, sampleTime, outPoses[track.BoneIndex].Position);
			}
		}

		// Sample rotation tracks
		for (let track in clip.RotationTracks)
		{
			if (track.BoneIndex >= 0 && track.BoneIndex < outPoses.Length)
			{
				outPoses[track.BoneIndex].Rotation = SampleQuaternion(track, sampleTime, outPoses[track.BoneIndex].Rotation);
			}
		}

		// Sample scale tracks
		for (let track in clip.ScaleTracks)
		{
			if (track.BoneIndex >= 0 && track.BoneIndex < outPoses.Length)
			{
				outPoses[track.BoneIndex].Scale = SampleVector3(track, sampleTime, outPoses[track.BoneIndex].Scale);
			}
		}
	}

	/// Blends two pose arrays together.
	/// @param poseA First pose array.
	/// @param poseB Second pose array.
	/// @param blendFactor 0 = fully poseA, 1 = fully poseB.
	/// @param outPoses Output pose array.
	public static void BlendPoses(Span<BoneTransform> poseA, Span<BoneTransform> poseB, float blendFactor, Span<BoneTransform> outPoses)
	{
		let count = Math.Min(Math.Min(poseA.Length, poseB.Length), outPoses.Length);
		for (int i = 0; i < count; i++)
		{
			outPoses[i] = BoneTransform.Lerp(poseA[i], poseB[i], blendFactor);
		}
	}

	/// Additively blends a pose onto a base pose.
	/// @param basePose The base pose.
	/// @param additivePose The additive pose (relative to reference pose).
	/// @param weight Weight of the additive pose (0-1).
	/// @param outPoses Output pose array.
	public static void AdditivePoses(Span<BoneTransform> basePose, Span<BoneTransform> additivePose, float weight, Span<BoneTransform> outPoses)
	{
		let count = Math.Min(Math.Min(basePose.Length, additivePose.Length), outPoses.Length);
		for (int i = 0; i < count; i++)
		{
			// Additive blending: base + (additive * weight)
			outPoses[i].Position = basePose[i].Position + additivePose[i].Position * weight;
			outPoses[i].Rotation = Quaternion.Slerp(.Identity, additivePose[i].Rotation, weight) * basePose[i].Rotation;
			outPoses[i].Scale = basePose[i].Scale * Vector3.Lerp(.One, additivePose[i].Scale, weight);
		}
	}

	// Cubic spline interpolation helpers
	private static Vector3 CubicSplineVector3(Keyframe<Vector3> prev, Keyframe<Vector3> next, float t, float duration)
	{
		let t2 = t * t;
		let t3 = t2 * t;

		let p0 = prev.Value;
		let m0 = prev.OutTangent * duration;
		let p1 = next.Value;
		let m1 = next.InTangent * duration;

		// Hermite basis functions
		let h00 = 2 * t3 - 3 * t2 + 1;
		let h10 = t3 - 2 * t2 + t;
		let h01 = -2 * t3 + 3 * t2;
		let h11 = t3 - t2;

		return p0 * h00 + m0 * h10 + p1 * h01 + m1 * h11;
	}

	private static Quaternion CubicSplineQuaternion(Keyframe<Quaternion> prev, Keyframe<Quaternion> next, float t, float duration)
	{
		// For quaternions, we use normalized lerp for cubic spline
		// A more accurate method would use squad interpolation
		let t2 = t * t;
		let t3 = t2 * t;

		// Simplified Hermite interpolation with normalization
		let h00 = 2 * t3 - 3 * t2 + 1;
		let h01 = -2 * t3 + 3 * t2;

		// Blend the quaternions
		var result = Quaternion.Slerp(prev.Value, next.Value, h01 / (h00 + h01));
		return Quaternion.Normalize(result);
	}
}
