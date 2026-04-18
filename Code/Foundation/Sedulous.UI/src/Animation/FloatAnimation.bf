namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Animates a float value from a start to end value using a delegate setter.
public class FloatAnimation : Animation
{
	private float mFrom;
	private float mTo;
	private delegate void(float) mSetter ~ delete _;

	/// Create a float animation.
	/// The setter delegate is owned by this animation and will be deleted.
	public this(float from, float to, float duration, delegate void(float) setter, EasingFunction easing = null)
		: base(duration, easing)
	{
		mFrom = from;
		mTo = to;
		mSetter = setter;
	}

	public float From => mFrom;
	public float To => mTo;

	protected override void Apply(float t)
	{
		mSetter(mFrom + (mTo - mFrom) * t);
	}
}
