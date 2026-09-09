using System;

namespace Sedulous.Animation;

/// Anything that produces a pose: a clip, or a blend tree over several.
///
/// Raptor tags each node with a kind and casts on the tag, because it builds with no RTTI.
/// Beef has the real thing, so a caller that needs the concrete node asks for it with `as`
/// and there is no tag to keep in agreement with the class.
interface IAnimationStateNode
{
	/// Evaluates at a NORMALISED time, nought to one, so a state machine can cross fade two
	/// clips of different lengths without knowing either one's duration.
	void Evaluate(Skeleton skeleton, float normalizedTime, Span<BoneTransform> outPoses);

	/// The length in seconds of whatever this would play right now.
	float Duration { get; }

	/// Fires whatever the span crossed, both times NORMALISED.
	void FireEvents(float prevNormalizedTime, float currentNormalizedTime, bool looping,
		AnimationEventHandler handler);
}
