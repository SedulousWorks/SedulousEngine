using Sedulous.Core;

namespace Sedulous.UI;

/// Animates a single number through a setter.
class FloatAnimation : Animation
{
	private float mFrom;
	private float mTo;
	/// OWNED: the setter is deleted with the animation.
	private delegate void(float) mSetter ~ delete _;

	/// OWNERSHIP of the setter transfers.
	public this(float from, float to, float duration, delegate void(float) setter,
		EasingFunction easing = null) : base(duration, easing)
	{
		mFrom = from;
		mTo = to;
		mSetter = setter;
	}

	public float From => mFrom;
	public float To => mTo;

	protected override void Apply(float t) => mSetter(mFrom + (mTo - mFrom) * t);
}
