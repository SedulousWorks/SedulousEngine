namespace Sedulous.Animation;

using System;
using System.Collections;

/// The type of value a property animation track animates.
public enum AnimatedValueType : int32
{
	Float,
	Vector2,
	Vector3,
	Vector4,
	Quaternion
}

/// Abstract base class for property animation tracks.
public abstract class PropertyAnimationTrackBase
{
	/// The property path this track animates (e.g. "Transform.Position").
	public String PropertyPath ~ delete _;

	/// Interpolation mode for keyframes.
	public InterpolationMode Interpolation = .Linear;

	/// Easing function applied to the interpolation factor.
	public EasingType Easing = .Linear;

	/// The value type of this track.
	public abstract AnimatedValueType ValueType { get; }

	/// Sorts keyframes by time.
	public abstract void SortKeyframes();

	/// Returns the time of the last keyframe, or 0 if empty.
	public abstract float GetDuration();

	public this(StringView propertyPath)
	{
		PropertyPath = new .(propertyPath);
	}
}

/// A property animation track containing keyframes of a specific type.
public class PropertyAnimationTrack<T> : PropertyAnimationTrackBase
{
	/// Keyframes sorted by time.
	public List<Keyframe<T>> Keyframes = new .() ~ delete _;

	public override AnimatedValueType ValueType
	{
		get
		{
			if (typeof(T) == typeof(float))
				return .Float;
			if (typeof(T) == typeof(Sedulous.Core.Mathematics.Vector2))
				return .Vector2;
			if (typeof(T) == typeof(Sedulous.Core.Mathematics.Vector3))
				return .Vector3;
			if (typeof(T) == typeof(Sedulous.Core.Mathematics.Vector4))
				return .Vector4;
			if (typeof(T) == typeof(Sedulous.Core.Mathematics.Quaternion))
				return .Quaternion;
			return .Float;
		}
	}

	public this(StringView propertyPath) : base(propertyPath)
	{
	}

	/// Adds a keyframe to the track.
	public void AddKeyframe(float time, T value)
	{
		Keyframes.Add(.(time, value));
	}

	/// Adds a keyframe with tangents for cubic spline interpolation.
	public void AddKeyframe(float time, T value, T inTangent, T outTangent)
	{
		Keyframes.Add(.(time, value, inTangent, outTangent));
	}

	/// Sorts keyframes by time.
	public override void SortKeyframes()
	{
		Keyframes.Sort(scope (a, b) => a.Time <=> b.Time);
	}

	/// Returns the time of the last keyframe, or 0 if empty.
	public override float GetDuration()
	{
		if (Keyframes.Count == 0)
			return 0;
		return Keyframes[Keyframes.Count - 1].Time;
	}

	/// Finds the keyframe indices surrounding the given time.
	/// Returns (prevIndex, nextIndex, t) where t is the interpolation factor.
	public (int32 prev, int32 next, float t) FindKeyframes(float time)
	{
		if (Keyframes.Count == 0)
			return (-1, -1, 0);

		if (Keyframes.Count == 1)
			return (0, 0, 0);

		// Before first keyframe
		if (time <= Keyframes[0].Time)
			return (0, 0, 0);

		// After last keyframe
		if (time >= Keyframes[Keyframes.Count - 1].Time)
		{
			let lastIdx = (int32)(Keyframes.Count - 1);
			return (lastIdx, lastIdx, 0);
		}

		// Binary search for the interval containing time
		int32 low = 0;
		int32 high = (int32)(Keyframes.Count - 1);

		while (low < high - 1)
		{
			let mid = (low + high) / 2;
			if (Keyframes[mid].Time <= time)
				low = mid;
			else
				high = mid;
		}

		let duration = Keyframes[high].Time - Keyframes[low].Time;
		let t = duration > 0 ? (time - Keyframes[low].Time) / duration : 0;
		return (low, high, t);
	}
}
