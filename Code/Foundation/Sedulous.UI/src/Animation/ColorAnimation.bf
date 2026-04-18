namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Animates a Color value from a start to end color using a delegate setter.
public class ColorAnimation : Animation
{
	private Color mFrom;
	private Color mTo;
	private delegate void(Color) mSetter ~ delete _;

	/// Create a color animation.
	/// The setter delegate is owned by this animation and will be deleted.
	public this(Color from, Color to, float duration, delegate void(Color) setter, EasingFunction easing = null)
		: base(duration, easing)
	{
		mFrom = from;
		mTo = to;
		mSetter = setter;
	}

	public Color From => mFrom;
	public Color To => mTo;

	protected override void Apply(float t)
	{
		mSetter(mFrom.Interpolate(mTo, t));
	}
}
