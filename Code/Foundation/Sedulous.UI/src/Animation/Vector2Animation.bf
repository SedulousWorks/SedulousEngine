namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Animates a Vector2 value from a start to end using a delegate setter.
public class Vector2Animation : Animation
{
	private Vector2 mFrom;
	private Vector2 mTo;
	private delegate void(Vector2) mSetter ~ delete _;

	/// Create a Vector2 animation.
	/// The setter delegate is owned by this animation and will be deleted.
	public this(Vector2 from, Vector2 to, float duration, delegate void(Vector2) setter, EasingFunction easing = null)
		: base(duration, easing)
	{
		mFrom = from;
		mTo = to;
		mSetter = setter;
	}

	public Vector2 From => mFrom;
	public Vector2 To => mTo;

	protected override void Apply(float t)
	{
		let value = Vector2(
			mFrom.X + (mTo.X - mFrom.X) * t,
			mFrom.Y + (mTo.Y - mFrom.Y) * t);
		mSetter(value);
	}
}
