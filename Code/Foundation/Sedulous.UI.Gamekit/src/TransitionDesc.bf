using Sedulous.Core;

namespace Sedulous.UI.Gamekit;

/// One declared transition: what it does, how long it takes and how it eases.
///
/// A null easing means the stack picks: ease out on the way in, ease in on the way out, which
/// is the pairing that reads as a screen arriving and then leaving rather than two unrelated
/// movements.
struct TransitionDesc
{
	public TransitionKind Kind = .None;
	public float Duration = 0.2f;
	/// Null takes the stack's default for the direction being played.
	public EasingFunction Easing = null;

	public this() {}

	public this(TransitionKind kind)
	{
		Kind = kind;
	}

	public this(TransitionKind kind, float duration)
	{
		Kind = kind;
		Duration = duration;
	}

	public this(TransitionKind kind, float duration, EasingFunction easing)
	{
		Kind = kind;
		Duration = duration;
		Easing = easing;
	}
}
