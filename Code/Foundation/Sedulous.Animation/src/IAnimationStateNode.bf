namespace Sedulous.Animation;

using System;

/// Interface for nodes that produce an animation pose.
/// Implemented by ClipStateNode and blend trees.
interface IAnimationStateNode
{
	/// Evaluates this node at the given normalized time [0..1], writing bone transforms to outPoses.
	void Evaluate(Skeleton skeleton, float normalizedTime, Span<BoneTransform> outPoses);

	/// Duration of this node's animation in seconds.
	float Duration { get; }

	/// Fires animation events that were crossed between prevNormalizedTime and currentNormalizedTime.
	void FireEvents(float prevNormalizedTime, float currentNormalizedTime, bool looping, AnimationEventHandler handler);
}

/// A state node that wraps a single AnimationClip.
class ClipStateNode : IAnimationStateNode
{
	/// The animation clip to sample.
	public AnimationClip Clip;

	public this(AnimationClip clip)
	{
		Clip = clip;
	}

	public void Evaluate(Skeleton skeleton, float normalizedTime, Span<BoneTransform> outPoses)
	{
		if (Clip == null || skeleton == null)
			return;

		// Convert normalized time [0..1] to absolute time
		let absoluteTime = normalizedTime * Clip.Duration;
		AnimationSampler.SampleClip(Clip, skeleton, absoluteTime, outPoses);
	}

	public float Duration => Clip != null ? Clip.Duration : 0.0f;

	public void FireEvents(float prevNormalizedTime, float currentNormalizedTime, bool looping, AnimationEventHandler handler)
	{
		if (Clip == null || handler == null || Clip.Events.Count == 0 || Clip.Duration <= 0)
			return;

		let prevAbsTime = prevNormalizedTime * Clip.Duration;
		let currentAbsTime = currentNormalizedTime * Clip.Duration;

		if (looping && currentNormalizedTime < prevNormalizedTime)
		{
			// Time wrapped around: fire events in (prevAbsTime, Duration] then [0, currentAbsTime]
			for (let evt in Clip.Events)
			{
				if (evt.Time > prevAbsTime && evt.Time <= Clip.Duration)
					handler(evt.Name, evt.Time);
			}
			for (let evt in Clip.Events)
			{
				if (evt.Time <= currentAbsTime)
					handler(evt.Name, evt.Time);
			}
		}
		else
		{
			// Normal forward: fire events in (prevAbsTime, currentAbsTime]
			Clip.FireEvents(prevAbsTime, currentAbsTime, handler);
		}
	}
}
