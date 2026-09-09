using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Animation;

/// Blends clips along ONE axis: a speed parameter walking through idle, walk and run.
///
/// The entries are kept SORTED by threshold, so finding the pair around a value is a walk
/// rather than a search of everything.
class BlendTree1D : IAnimationStateNode
{
	/// The graph parameter that drives this, which the player syncs into the value below
	/// each update.
	public int32 ParameterIndex = -1;
	public float Parameter = 0.0f;

	public List<BlendTree1DEntry> Entries = new .() ~ delete _;

	/// Appends, then walks it left into its sorted place.
	public void AddEntry(float threshold, AnimationClip clip)
	{
		Entries.Add(.(threshold, clip));
		for (int i = Entries.Count - 1; i > 0; i--)
		{
			if (Entries[i - 1].Threshold <= Entries[i].Threshold)
				break;
			let swap = Entries[i - 1];
			Entries[i - 1] = Entries[i];
			Entries[i] = swap;
		}
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
		// Past either end, the end entry plays alone: the axis is CLAMPED, not extrapolated.
		if (Parameter <= Entries[0].Threshold)
		{
			SampleEntry(0, skeleton, normalizedTime, outPoses);
			return;
		}
		if (Parameter >= Entries[Entries.Count - 1].Threshold)
		{
			SampleEntry(Entries.Count - 1, skeleton, normalizedTime, outPoses);
			return;
		}

		var lowIndex = 0;
		var highIndex = 1;
		for (int i = 0; (i + 1) < Entries.Count; i++)
		{
			if ((Parameter >= Entries[i].Threshold) && (Parameter <= Entries[i + 1].Threshold))
			{
				lowIndex = i;
				highIndex = i + 1;
				break;
			}
		}

		let clipA = Entries[lowIndex].Clip;
		let clipB = Entries[highIndex].Clip;
		// An empty slot on one side plays the other alone rather than blending toward
		// nothing, which would fade the character into its bind pose.
		if ((clipA == null) && (clipB == null))
			return;
		if (clipA == null)
		{
			SampleEntry(highIndex, skeleton, normalizedTime, outPoses);
			return;
		}
		if (clipB == null)
		{
			SampleEntry(lowIndex, skeleton, normalizedTime, outPoses);
			return;
		}

		let range = Entries[highIndex].Threshold - Entries[lowIndex].Threshold;
		let blend = (range > 0.0f) ? ((Parameter - Entries[lowIndex].Threshold) / range) : 0.0f;

		let boneCount = skeleton.BoneCount;
		let a = scope BoneTransform[boneCount];
		let b = scope BoneTransform[boneCount];
		// Each clip is sampled at ITS OWN duration scaled by the shared normalised time,
		// which is what keeps a walk and a run in step through the blend.
		AnimationSampler.SampleClip(clipA, skeleton, normalizedTime * clipA.Duration, a);
		AnimationSampler.SampleClip(clipB, skeleton, normalizedTime * clipB.Duration, b);
		AnimationSampler.BlendPoses(a, b, blend, outPoses);
	}

	/// The NEAREST entry's duration, which is the same pick the events make, so the timing
	/// and the events never disagree about which clip is dominant.
	public float Duration
	{
		get
		{
			var bestDistance = float.MaxValue;
			var bestDuration = 0.0f;
			for (let entry in Entries)
			{
				let distance = Abs(entry.Threshold - Parameter);
				if ((distance < bestDistance) && (entry.Clip != null))
				{
					bestDistance = distance;
					bestDuration = entry.Clip.Duration;
				}
			}
			return bestDuration;
		}
	}

	public void FireEvents(float prevNorm, float currentNorm, bool looping,
		AnimationEventHandler handler)
	{
		ClipEvents.Fire(DominantClip, prevNorm, currentNorm, looping, handler);
	}

	private AnimationClip DominantClip
	{
		get
		{
			var bestDistance = float.MaxValue;
			AnimationClip best = null;
			for (let entry in Entries)
			{
				let distance = Abs(entry.Threshold - Parameter);
				if ((distance < bestDistance) && (entry.Clip != null))
				{
					bestDistance = distance;
					best = entry.Clip;
				}
			}
			return best;
		}
	}

	private void SampleEntry(int index, Skeleton skeleton, float normalizedTime,
		Span<BoneTransform> outPoses)
	{
		let clip = Entries[index].Clip;
		if (clip != null)
			AnimationSampler.SampleClip(clip, skeleton, normalizedTime * clip.Duration, outPoses);
	}
}
