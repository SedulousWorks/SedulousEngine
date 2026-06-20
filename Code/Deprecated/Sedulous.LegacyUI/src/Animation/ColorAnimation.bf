namespace Sedulous.LegacyUI;

using System;
using Sedulous.Core.Mathematics;

/// Animates a Color value from a start to end color using a delegate setter.
public class ColorAnimation : Animation
{
	private Color32 mFrom;
	private Color32 mTo;
	private delegate void(Color32) mSetter ~ delete _;

	/// Create a color animation.
	/// The setter delegate is owned by this animation and will be deleted.
	public this(Color32 from, Color32 to, float duration, delegate void(Color32) setter, EasingFunction easing = null)
		: base(duration, easing)
	{
		mFrom = from;
		mTo = to;
		mSetter = setter;
	}

	public Color32 From => mFrom;
	public Color32 To => mTo;

	protected override void Apply(float t)
	{
		mSetter(mFrom.Interpolate(mTo, t));
	}
}
