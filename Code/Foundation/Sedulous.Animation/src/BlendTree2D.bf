namespace Sedulous.Animation;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// An entry in a 2D blend tree, mapping a 2D position to a clip.
struct BlendTree2DEntry
{
	/// Position in 2D parameter space.
	public Vector2 Position;

	/// The animation clip at this position.
	public AnimationClip Clip;

	public this(Vector2 position, AnimationClip clip)
	{
		Position = position;
		Clip = clip;
	}
}

/// Blends N animation clips in a 2D parameter space using inverse-distance weighting.
class BlendTree2D : IAnimationStateNode
{
	/// Entries in 2D space.
	public List<BlendTree2DEntry> Entries = new .() ~ delete _;

	/// Current X parameter value (set by the graph player each frame).
	public float ParameterX;

	/// Current Y parameter value (set by the graph player each frame).
	public float ParameterY;

	public void Evaluate(Skeleton skeleton, float normalizedTime, Span<BoneTransform> outPoses)
	{
		if (skeleton == null || Entries.Count == 0)
			return;

		if (Entries.Count == 1)
		{
			let clip = Entries[0].Clip;
			if (clip != null)
			{
				let absTime = normalizedTime * clip.Duration;
				AnimationSampler.SampleClip(clip, skeleton, absTime, outPoses);
			}
			return;
		}

		// Compute inverse-distance weights
		float[] weights = scope float[Entries.Count];
		float totalWeight = 0.0f;
		let paramPos = Vector2(ParameterX, ParameterY);

		for (int i = 0; i < Entries.Count; i++)
		{
			let diff = paramPos - Entries[i].Position;
			let dist = diff.Length();

			if (dist < 0.0001f)
			{
				// Essentially on top of this entry - use it exclusively
				let clip = Entries[i].Clip;
				if (clip != null)
				{
					let absTime = normalizedTime * clip.Duration;
					AnimationSampler.SampleClip(clip, skeleton, absTime, outPoses);
				}
				return;
			}

			weights[i] = 1.0f / dist;
			totalWeight += weights[i];
		}

		// Normalize weights
		if (totalWeight > 0)
		{
			for (int i = 0; i < weights.Count; i++)
				weights[i] /= totalWeight;
		}

		// Sample and blend all entries
		BoneTransform[] tempPoses = scope BoneTransform[skeleton.BoneCount];
		bool firstSample = true;

		for (int i = 0; i < Entries.Count; i++)
		{
			if (weights[i] < 0.001f || Entries[i].Clip == null)
				continue;

			let clip = Entries[i].Clip;
			let absTime = normalizedTime * clip.Duration;
			AnimationSampler.SampleClip(clip, skeleton, absTime, tempPoses);

			if (firstSample)
			{
				// First contributing entry - copy directly with weight consideration
				for (int b = 0; b < skeleton.BoneCount && b < outPoses.Length; b++)
					outPoses[b] = tempPoses[b];
				firstSample = false;

				// If this is the only significant entry, we're done
				if (weights[i] > 0.999f)
					return;

				// Scale the first contribution - we'll accumulate weighted blends
				// For proper multi-way blending, we start from the first and blend toward others
				continue;
			}

			// Blend this entry's contribution on top
			// Compute the relative weight of this entry vs accumulated
			float accumulated = 0;
			for (int j = 0; j < i; j++)
			{
				if (weights[j] >= 0.001f && Entries[j].Clip != null)
					accumulated += weights[j];
			}

			let relativeWeight = weights[i] / (accumulated + weights[i]);
			AnimationSampler.BlendPoses(outPoses, tempPoses, relativeWeight, outPoses);
		}
	}

	public float Duration
	{
		get
		{
			if (Entries.Count == 0)
				return 0.0f;

			// Weighted average duration based on current parameter position
			let paramPos = Vector2(ParameterX, ParameterY);
			float totalWeight = 0.0f;
			float totalDuration = 0.0f;

			for (let entry in Entries)
			{
				if (entry.Clip == null)
					continue;

				let diff = paramPos - entry.Position;
				let dist = diff.Length();

				if (dist < 0.0001f)
					return entry.Clip.Duration;

				let w = 1.0f / dist;
				totalWeight += w;
				totalDuration += w * entry.Clip.Duration;
			}

			return totalWeight > 0 ? totalDuration / totalWeight : 0.0f;
		}
	}

	public void FireEvents(float prevNormalizedTime, float currentNormalizedTime, bool looping, AnimationEventHandler handler)
	{
		// Blend trees don't fire clip events (multiple clips blending simultaneously).
	}

	/// Adds an entry at the given 2D position.
	public void AddEntry(Vector2 position, AnimationClip clip)
	{
		Entries.Add(.(position, clip));
	}

	/// Adds an entry at the given X,Y coordinates.
	public void AddEntry(float x, float y, AnimationClip clip)
	{
		Entries.Add(.(.(x, y), clip));
	}
}
