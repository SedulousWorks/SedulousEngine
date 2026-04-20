namespace Sedulous.Animation;

using System;
using System.Collections;

/// An entry in a 1D blend tree, mapping a threshold value to a clip.
struct BlendTree1DEntry
{
	/// The threshold value along the blend parameter axis.
	public float Threshold;

	/// The animation clip at this threshold.
	public AnimationClip Clip;

	public this(float threshold, AnimationClip clip)
	{
		Threshold = threshold;
		Clip = clip;
	}
}

/// Blends N animation clips along a single float parameter axis.
/// Entries must be sorted by threshold. The parameter value selects
/// which two neighboring entries to blend between.
class BlendTree1D : IAnimationStateNode
{
	/// Entries sorted by threshold.
	public List<BlendTree1DEntry> Entries = new .() ~ delete _;

	/// Current blend parameter value (set by the graph player each frame).
	public float Parameter;

	public void Evaluate(Skeleton skeleton, float normalizedTime, Span<BoneTransform> outPoses)
	{
		if (skeleton == null || Entries.Count == 0)
			return;

		if (Entries.Count == 1)
		{
			// Single entry - just sample it
			let clip = Entries[0].Clip;
			if (clip != null)
			{
				let absTime = normalizedTime * clip.Duration;
				AnimationSampler.SampleClip(clip, skeleton, absTime, outPoses);
			}
			return;
		}

		// Find the two entries surrounding the parameter value
		int lowIdx = 0;
		int highIdx = 1;

		if (Parameter <= Entries[0].Threshold)
		{
			// Below minimum - use first entry
			let clip = Entries[0].Clip;
			if (clip != null)
			{
				let absTime = normalizedTime * clip.Duration;
				AnimationSampler.SampleClip(clip, skeleton, absTime, outPoses);
			}
			return;
		}

		if (Parameter >= Entries[Entries.Count - 1].Threshold)
		{
			// Above maximum - use last entry
			let clip = Entries[Entries.Count - 1].Clip;
			if (clip != null)
			{
				let absTime = normalizedTime * clip.Duration;
				AnimationSampler.SampleClip(clip, skeleton, absTime, outPoses);
			}
			return;
		}

		// Find bracketing entries
		for (int i = 0; i < Entries.Count - 1; i++)
		{
			if (Parameter >= Entries[i].Threshold && Parameter <= Entries[i + 1].Threshold)
			{
				lowIdx = i;
				highIdx = i + 1;
				break;
			}
		}

		let clipA = Entries[lowIdx].Clip;
		let clipB = Entries[highIdx].Clip;

		if (clipA == null && clipB == null)
			return;

		if (clipA == null)
		{
			let absTime = normalizedTime * clipB.Duration;
			AnimationSampler.SampleClip(clipB, skeleton, absTime, outPoses);
			return;
		}

		if (clipB == null)
		{
			let absTime = normalizedTime * clipA.Duration;
			AnimationSampler.SampleClip(clipA, skeleton, absTime, outPoses);
			return;
		}

		// Compute blend factor between the two
		let range = Entries[highIdx].Threshold - Entries[lowIdx].Threshold;
		let blendFactor = range > 0 ? (Parameter - Entries[lowIdx].Threshold) / range : 0.0f;

		// Sample both clips
		BoneTransform[] posesA = scope BoneTransform[skeleton.BoneCount];
		BoneTransform[] posesB = scope BoneTransform[skeleton.BoneCount];

		let absTimeA = normalizedTime * clipA.Duration;
		let absTimeB = normalizedTime * clipB.Duration;

		AnimationSampler.SampleClip(clipA, skeleton, absTimeA, posesA);
		AnimationSampler.SampleClip(clipB, skeleton, absTimeB, posesB);

		// Blend
		AnimationSampler.BlendPoses(posesA, posesB, blendFactor, outPoses);
	}

	public float Duration
	{
		get
		{
			if (Entries.Count == 0)
				return 0.0f;

			// Return the duration of the clip closest to current parameter
			float bestDist = float.MaxValue;
			float bestDuration = 0.0f;

			for (let entry in Entries)
			{
				let dist = Math.Abs(entry.Threshold - Parameter);
				if (dist < bestDist && entry.Clip != null)
				{
					bestDist = dist;
					bestDuration = entry.Clip.Duration;
				}
			}

			return bestDuration;
		}
	}

	public void FireEvents(float prevNormalizedTime, float currentNormalizedTime, bool looping, AnimationEventHandler handler)
	{
		// Blend trees don't fire clip events (multiple clips blending simultaneously).
	}

	/// Adds an entry and keeps the list sorted by threshold.
	public void AddEntry(float threshold, AnimationClip clip)
	{
		let entry = BlendTree1DEntry(threshold, clip);

		// Insert in sorted order
		for (int i = 0; i < Entries.Count; i++)
		{
			if (threshold < Entries[i].Threshold)
			{
				Entries.Insert(i, entry);
				return;
			}
		}

		Entries.Add(entry);
	}
}
