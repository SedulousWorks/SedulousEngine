using System;

namespace Sedulous.Animation;

/// A state that plays ONE clip, which is BORROWED.
class ClipStateNode : IAnimationStateNode
{
	private AnimationClip mClip;

	public this(AnimationClip clip)
	{
		mClip = clip;
	}

	public AnimationClip Clip => mClip;

	public void Evaluate(Skeleton skeleton, float normalizedTime, Span<BoneTransform> outPoses)
	{
		if (mClip == null)
			return;
		AnimationSampler.SampleClip(mClip, skeleton, normalizedTime * mClip.Duration, outPoses);
	}

	public float Duration => (mClip != null) ? mClip.Duration : 0.0f;

	public void FireEvents(float prevNorm, float currentNorm, bool looping,
		AnimationEventHandler handler)
	{
		ClipEvents.Fire(mClip, prevNorm, currentNorm, looping, handler);
	}
}
