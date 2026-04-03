using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.Models;

/// Animation interpolation type
public enum AnimationInterpolation
{
	Linear,
	Step,
	CubicSpline
}

/// Animation channel target path
public enum AnimationPath
{
	Translation,
	Rotation,
	Scale,
	Weights // Morph target weights
}

/// Keyframe data for an animation
public struct AnimationKeyframe
{
	public float Time;
	public Vector4 Value; // Translation (xyz), Rotation (xyzw), Scale (xyz), or single Weight

	public this(float time, Vector4 value)
	{
		Time = time;
		Value = value;
	}
}

/// An animation channel targeting a specific bone/node property
public class AnimationChannel
{
	private List<AnimationKeyframe> mKeyframes ~ delete _;

	/// Target bone index
	public int32 TargetBone;

	/// Property being animated
	public AnimationPath Path;

	/// Interpolation method
	public AnimationInterpolation Interpolation = .Linear;

	public List<AnimationKeyframe> Keyframes => mKeyframes;

	public this()
	{
		mKeyframes = new List<AnimationKeyframe>();
	}

	/// Add a keyframe
	public void AddKeyframe(float time, Vector4 value)
	{
		mKeyframes.Add(AnimationKeyframe(time, value));
	}

	/// Sample the animation at a given time
	public Vector4 Sample(float time)
	{
		if (mKeyframes.Count == 0)
			return .Zero;

		if (mKeyframes.Count == 1)
			return mKeyframes[0].Value;

		// Clamp to animation bounds
		if (time <= mKeyframes[0].Time)
			return mKeyframes[0].Value;
		if (time >= mKeyframes[mKeyframes.Count - 1].Time)
			return mKeyframes[mKeyframes.Count - 1].Value;

		// Find surrounding keyframes
		int32 i = 0;
		while (i < mKeyframes.Count - 1 && mKeyframes[i + 1].Time < time)
			i++;

		let k0 = mKeyframes[i];
		let k1 = mKeyframes[i + 1];

		float t = (time - k0.Time) / (k1.Time - k0.Time);

		switch (Interpolation)
		{
		case .Step:
			return k0.Value;
		case .Linear:
			if (Path == .Rotation)
			{
				// Quaternion slerp
				let q0 = Quaternion(k0.Value.X, k0.Value.Y, k0.Value.Z, k0.Value.W);
				let q1 = Quaternion(k1.Value.X, k1.Value.Y, k1.Value.Z, k1.Value.W);
				let result = Quaternion.Slerp(q0, q1, t);
				return Vector4(result.X, result.Y, result.Z, result.W);
			}
			else
			{
				return Vector4.Lerp(k0.Value, k1.Value, t);
			}
		case .CubicSpline:
			// TODO: Implement cubic spline interpolation
			return Vector4.Lerp(k0.Value, k1.Value, t);
		}
	}
}

/// A complete animation
public class ModelAnimation
{
	private String mName ~ delete _;
	private List<AnimationChannel> mChannels ~ DeleteContainerAndItems!(_);

	public StringView Name => mName;
	public List<AnimationChannel> Channels => mChannels;

	/// Duration of the animation in seconds
	public float Duration;

	public this()
	{
		mName = new String();
		mChannels = new List<AnimationChannel>();
	}

	public void SetName(StringView name)
	{
		mName.Set(name);
	}

	/// Add a channel (takes ownership)
	public void AddChannel(AnimationChannel channel)
	{
		mChannels.Add(channel);
	}

	/// Calculate duration from keyframes
	public void CalculateDuration()
	{
		Duration = 0;
		for (let channel in mChannels)
		{
			for (let keyframe in channel.Keyframes)
			{
				if (keyframe.Time > Duration)
					Duration = keyframe.Time;
			}
		}
	}
}
