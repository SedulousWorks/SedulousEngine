using System;

namespace Sedulous.UI;

/// One entry of a `transition:` list.
struct TransitionSpec
{
	/// COUNT means `all`, since no real property has that value.
	public StyleProperty Property = .COUNT;
	/// In seconds.
	public float Duration = 0.0f;
	public float Delay = 0.0f;
	public TransitionEasing Easing = .Ease;

	public this() {}

	[Commutable]
	public static bool operator==(TransitionSpec a, TransitionSpec b) =>
		(a.Property == b.Property) && (a.Duration == b.Duration) && (a.Delay == b.Delay)
		&& (a.Easing == b.Easing);
}
