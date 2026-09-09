using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Animation;

/// Blends clips across a TWO dimensional space, which is what a directional locomotion set
/// is: forward and strafe on two axes, with a clip at each compass point.
///
/// The weights are INVERSE DISTANCE: an entry close to the parameter dominates, and one far
/// away contributes almost nothing, with no triangulation of the space to maintain.
class BlendTree2D : IAnimationStateNode
{
	public int32 ParameterIndexX = -1;
	public int32 ParameterIndexY = -1;
	public float ParameterX = 0.0f;
	public float ParameterY = 0.0f;

	public List<BlendTree2DEntry> Entries = new .() ~ delete _;

	public void AddEntry(Float2 position, AnimationClip clip)
	{
		Entries.Add(.(position, clip));
	}

	public void AddEntry(float x, float y, AnimationClip clip)
	{
		Entries.Add(.(.(x, y), clip));
	}

	public void Evaluate(Skeleton skeleton, float normalizedTime, Span<BoneTransform> outPoses)
	{
		if (Entries.IsEmpty)
			return;
		if (Entries.Count == 1)
		{
			SampleEntry(0, skeleton, normalizedTime, outPoses);
			return;
		}

		let parameter = Float2(ParameterX, ParameterY);
		let weights = scope float[Entries.Count];
		var totalWeight = 0.0f;

		for (int i = 0; i < Entries.Count; i++)
		{
			let distance = Length(parameter - Entries[i].Position);
			// Sitting ON an entry plays it alone: the inverse of nothing is not a number.
			if (distance < 0.0001f)
			{
				SampleEntry(i, skeleton, normalizedTime, outPoses);
				return;
			}
			weights[i] = 1.0f / distance;
			totalWeight += weights[i];
		}

		if (totalWeight > 0.0f)
		{
			for (int i < weights.Count)
				weights[i] /= totalWeight;
		}

		let boneCount = skeleton.BoneCount;
		let temp = scope BoneTransform[boneCount];
		var firstSample = true;

		for (int i = 0; i < Entries.Count; i++)
		{
			// Below a thousandth an entry cannot be seen, and sampling a whole clip to
			// contribute that is the most expensive thing a tree can do for nothing.
			if ((weights[i] < 0.001f) || (Entries[i].Clip == null))
				continue;

			let clip = Entries[i].Clip;
			AnimationSampler.SampleClip(clip, skeleton, normalizedTime * clip.Duration, temp);

			if (firstSample)
			{
				for (int b = 0; (b < boneCount) && (b < outPoses.Length); b++)
					outPoses[b] = temp[b];
				firstSample = false;
				// One entry carrying essentially all of the weight is the answer already.
				if (weights[i] > 0.999f)
					return;
				continue;
			}

			// Folded in one at a time, each against the weight ACCUMULATED so far, which is
			// what makes a running blend equal to the weighted average of them all.
			var accumulated = 0.0f;
			for (int j = 0; j < i; j++)
			{
				if ((weights[j] >= 0.001f) && (Entries[j].Clip != null))
					accumulated += weights[j];
			}
			let relative = weights[i] / (accumulated + weights[i]);
			AnimationSampler.BlendPoses(outPoses, temp, relative, outPoses);
		}
	}

	/// The weighted average duration, so the whole tree's clock runs at the pace the blend
	/// actually looks like rather than at one clip's.
	public float Duration
	{
		get
		{
			let parameter = Float2(ParameterX, ParameterY);
			var totalWeight = 0.0f;
			var totalDuration = 0.0f;

			for (let entry in Entries)
			{
				if (entry.Clip == null)
					continue;
				let distance = Length(parameter - entry.Position);
				if (distance < 0.0001f)
					return entry.Clip.Duration;
				let weight = 1.0f / distance;
				totalWeight += weight;
				totalDuration += weight * entry.Clip.Duration;
			}

			return (totalWeight > 0.0f) ? (totalDuration / totalWeight) : 0.0f;
		}
	}

	public void FireEvents(float prevNorm, float currentNorm, bool looping,
		AnimationEventHandler handler)
	{
		// The nearest entry, which is the largest inverse distance weight.
		let parameter = Float2(ParameterX, ParameterY);
		var bestDistance = float.MaxValue;
		AnimationClip best = null;
		for (let entry in Entries)
		{
			if (entry.Clip == null)
				continue;
			let distance = Length(parameter - entry.Position);
			if (distance < bestDistance)
			{
				bestDistance = distance;
				best = entry.Clip;
			}
		}
		ClipEvents.Fire(best, prevNorm, currentNorm, looping, handler);
	}

	private void SampleEntry(int index, Skeleton skeleton, float normalizedTime,
		Span<BoneTransform> outPoses)
	{
		let clip = Entries[index].Clip;
		if (clip != null)
			AnimationSampler.SampleClip(clip, skeleton, normalizedTime * clip.Duration, outPoses);
	}
}
