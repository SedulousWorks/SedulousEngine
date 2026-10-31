using Sedulous.Core;

namespace Sedulous.UI;

/// Animates a colour, alpha included.
class ColorAnimation : Animation
{
	private Color mFrom;
	private Color mTo;
	/// OWNED.
	private delegate void(Color) mSetter ~ delete _;

	/// OWNERSHIP of the setter transfers.
	public this(Color from, Color to, float duration, delegate void(Color) setter,
		EasingFunction easing = null) : base(duration, easing)
	{
		mFrom = from;
		mTo = to;
		mSetter = setter;
	}

	public Color From => mFrom;
	public Color To => mTo;

	protected override void Apply(float t) => mSetter(Lerp(mFrom, mTo, t));
}
