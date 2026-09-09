using System;
using System.Collections;

namespace Sedulous.Animation;

/// The keyframes for ONE property of ONE bone.
class AnimationTrack<T> where T : struct
{
	public int32 BoneIndex = 0;
	public InterpolationMode Interpolation = .Linear;

	public List<Keyframe<T>> Keyframes = new .() ~ delete _;

	public void AddKeyframe(float time, T value)
	{
		Keyframes.Add(.(time, value));
	}

	public void AddKeyframe(float time, T value, T inTangent, T outTangent)
	{
		Keyframes.Add(.(time, value, inTangent, outTangent));
	}

	/// A STABLE insertion sort, which is the right one here: keyframes arrive from an import
	/// already in time order, so this is a linear pass that touches nothing, and two keys at
	/// the same time keep the order they were authored in.
	public void SortKeyframes()
	{
		for (int i = 1; i < Keyframes.Count; i++)
		{
			let key = Keyframes[i];
			var j = i;
			while ((j > 0) && (Keyframes[j - 1].Time > key.Time))
			{
				Keyframes[j] = Keyframes[j - 1];
				j--;
			}
			Keyframes[j] = key;
		}
	}

	/// The interval around a time, CLAMPED at both ends: before the first key and after the
	/// last one both hold, rather than extrapolating off the end of the animation.
	public KeyframeLookup FindKeyframes(float time)
	{
		let count = (int32)Keyframes.Count;
		if (count == 0)
			return .(-1, -1, 0.0f);
		if (count == 1)
			return .(0, 0, 0.0f);
		if (time <= Keyframes[0].Time)
			return .(0, 0, 0.0f);
		if (time >= Keyframes[count - 1].Time)
			return .(count - 1, count - 1, 0.0f);

		// A binary search rather than a walk: a long clip scrubbed to an arbitrary time is
		// the editor's normal case, not a rare one.
		var low = (int32)0;
		var high = count - 1;
		while (low < (high - 1))
		{
			let mid = (low + high) / 2;
			if (Keyframes[mid].Time <= time)
				low = mid;
			else
				high = mid;
		}

		let span = Keyframes[high].Time - Keyframes[low].Time;
		let t = (span > 0.0f) ? ((time - Keyframes[low].Time) / span) : 0.0f;
		return .(low, high, t);
	}
}
