namespace Sedulous.Animation;

using System;
using Sedulous.Core.Mathematics;

/// Samples property animation tracks at specific times, applying easing.
public static class PropertyAnimationSampler
{
	/// Samples a float track at the given time.
	public static float SampleFloat(PropertyAnimationTrack<float> track, float time, float defaultValue = 0)
	{
		if (track == null || track.Keyframes.Count == 0)
			return defaultValue;

		let (prevIdx, nextIdx, rawT) = track.FindKeyframes(time);
		if (prevIdx < 0)
			return defaultValue;

		let prev = track.Keyframes[prevIdx];
		let next = track.Keyframes[nextIdx];
		let t = EasingTypeUtil.Apply(track.Easing, rawT);

		switch (track.Interpolation)
		{
		case .Step:
			return prev.Value;
		case .Linear:
			return prev.Value + (next.Value - prev.Value) * t;
		case .CubicSpline:
			return CubicSplineFloat(prev, next, t, next.Time - prev.Time);
		}
	}

	/// Samples a Vector2 track at the given time.
	public static Vector2 SampleVector2(PropertyAnimationTrack<Vector2> track, float time, Vector2 defaultValue = default)
	{
		if (track == null || track.Keyframes.Count == 0)
			return defaultValue;

		let (prevIdx, nextIdx, rawT) = track.FindKeyframes(time);
		if (prevIdx < 0)
			return defaultValue;

		let prev = track.Keyframes[prevIdx];
		let next = track.Keyframes[nextIdx];
		let t = EasingTypeUtil.Apply(track.Easing, rawT);

		switch (track.Interpolation)
		{
		case .Step:
			return prev.Value;
		case .Linear:
			return Vector2.Lerp(prev.Value, next.Value, t);
		case .CubicSpline:
			return CubicSplineVector2(prev, next, t, next.Time - prev.Time);
		}
	}

	/// Samples a Vector3 track at the given time.
	public static Vector3 SampleVector3(PropertyAnimationTrack<Vector3> track, float time, Vector3 defaultValue = default)
	{
		if (track == null || track.Keyframes.Count == 0)
			return defaultValue;

		let (prevIdx, nextIdx, rawT) = track.FindKeyframes(time);
		if (prevIdx < 0)
			return defaultValue;

		let prev = track.Keyframes[prevIdx];
		let next = track.Keyframes[nextIdx];
		let t = EasingTypeUtil.Apply(track.Easing, rawT);

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

	/// Samples a Vector4 track at the given time.
	public static Vector4 SampleVector4(PropertyAnimationTrack<Vector4> track, float time, Vector4 defaultValue = default)
	{
		if (track == null || track.Keyframes.Count == 0)
			return defaultValue;

		let (prevIdx, nextIdx, rawT) = track.FindKeyframes(time);
		if (prevIdx < 0)
			return defaultValue;

		let prev = track.Keyframes[prevIdx];
		let next = track.Keyframes[nextIdx];
		let t = EasingTypeUtil.Apply(track.Easing, rawT);

		switch (track.Interpolation)
		{
		case .Step:
			return prev.Value;
		case .Linear:
			return Vector4.Lerp(prev.Value, next.Value, t);
		case .CubicSpline:
			return CubicSplineVector4(prev, next, t, next.Time - prev.Time);
		}
	}

	/// Samples a Quaternion track at the given time.
	public static Quaternion SampleQuaternion(PropertyAnimationTrack<Quaternion> track, float time, Quaternion defaultValue = default)
	{
		if (track == null || track.Keyframes.Count == 0)
			return defaultValue;

		let (prevIdx, nextIdx, rawT) = track.FindKeyframes(time);
		if (prevIdx < 0)
			return defaultValue;

		let prev = track.Keyframes[prevIdx];
		let next = track.Keyframes[nextIdx];
		let t = EasingTypeUtil.Apply(track.Easing, rawT);

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

	// ---- Cubic Spline Helpers (Hermite basis) ----

	private static float CubicSplineFloat(Keyframe<float> prev, Keyframe<float> next, float t, float duration)
	{
		let t2 = t * t;
		let t3 = t2 * t;

		let p0 = prev.Value;
		let m0 = prev.OutTangent * duration;
		let p1 = next.Value;
		let m1 = next.InTangent * duration;

		let h00 = 2 * t3 - 3 * t2 + 1;
		let h10 = t3 - 2 * t2 + t;
		let h01 = -2 * t3 + 3 * t2;
		let h11 = t3 - t2;

		return p0 * h00 + m0 * h10 + p1 * h01 + m1 * h11;
	}

	private static Vector2 CubicSplineVector2(Keyframe<Vector2> prev, Keyframe<Vector2> next, float t, float duration)
	{
		let t2 = t * t;
		let t3 = t2 * t;

		let p0 = prev.Value;
		let m0 = prev.OutTangent * duration;
		let p1 = next.Value;
		let m1 = next.InTangent * duration;

		let h00 = 2 * t3 - 3 * t2 + 1;
		let h10 = t3 - 2 * t2 + t;
		let h01 = -2 * t3 + 3 * t2;
		let h11 = t3 - t2;

		return p0 * h00 + m0 * h10 + p1 * h01 + m1 * h11;
	}

	private static Vector3 CubicSplineVector3(Keyframe<Vector3> prev, Keyframe<Vector3> next, float t, float duration)
	{
		let t2 = t * t;
		let t3 = t2 * t;

		let p0 = prev.Value;
		let m0 = prev.OutTangent * duration;
		let p1 = next.Value;
		let m1 = next.InTangent * duration;

		let h00 = 2 * t3 - 3 * t2 + 1;
		let h10 = t3 - 2 * t2 + t;
		let h01 = -2 * t3 + 3 * t2;
		let h11 = t3 - t2;

		return p0 * h00 + m0 * h10 + p1 * h01 + m1 * h11;
	}

	private static Vector4 CubicSplineVector4(Keyframe<Vector4> prev, Keyframe<Vector4> next, float t, float duration)
	{
		let t2 = t * t;
		let t3 = t2 * t;

		let p0 = prev.Value;
		let m0 = prev.OutTangent * duration;
		let p1 = next.Value;
		let m1 = next.InTangent * duration;

		let h00 = 2 * t3 - 3 * t2 + 1;
		let h10 = t3 - 2 * t2 + t;
		let h01 = -2 * t3 + 3 * t2;
		let h11 = t3 - t2;

		return p0 * h00 + m0 * h10 + p1 * h01 + m1 * h11;
	}

	private static Quaternion CubicSplineQuaternion(Keyframe<Quaternion> prev, Keyframe<Quaternion> next, float t, float duration)
	{
		let t2 = t * t;
		let t3 = t2 * t;

		let h00 = 2 * t3 - 3 * t2 + 1;
		let h01 = -2 * t3 + 3 * t2;

		var result = Quaternion.Slerp(prev.Value, next.Value, h01 / (h00 + h01));
		return Quaternion.Normalize(result);
	}
}
