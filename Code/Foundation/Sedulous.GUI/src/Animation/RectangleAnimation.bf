using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Delegate for getting a RectangleF property value.
public delegate RectangleF RectangleGetter(UIElement element);

/// Delegate for setting a RectangleF property value.
public delegate void RectangleSetter(UIElement element, RectangleF value);

/// Animates a RectangleF property on a UIElement.
/// Useful for animating bounds, clip regions, or other rectangular areas.
public class RectangleAnimation : Animation
{
	private RectangleF mFrom;
	private RectangleF mTo;
	private RectangleF mOriginalValue;
	private bool mFromSet = false;

	// Property accessors
	private RectangleGetter mGetter ~ delete _;
	private RectangleSetter mSetter ~ delete _;

	/// Creates a Rectangle animation.
	public this()
	{
	}

	/// Creates a Rectangle animation with getter/setter.
	public this(RectangleGetter getter, RectangleSetter setter)
	{
		mGetter = getter;
		mSetter = setter;
	}

	/// The starting value. If not set, uses current property value.
	public RectangleF From
	{
		get => mFrom;
		set
		{
			mFrom = value;
			mFromSet = true;
		}
	}

	/// The ending value.
	public RectangleF To
	{
		get => mTo;
		set => mTo = value;
	}

	/// Sets the property getter.
	public void SetGetter(RectangleGetter getter)
	{
		if (mGetter != null) delete mGetter;
		mGetter = getter;
	}

	/// Sets the property setter.
	public void SetSetter(RectangleSetter setter)
	{
		if (mSetter != null) delete mSetter;
		mSetter = setter;
	}

	protected override void OnStart()
	{
		let target = Target;
		if (target == null || mGetter == null)
			return;

		mOriginalValue = mGetter(target);
		if (!mFromSet)
			mFrom = mOriginalValue;
	}

	protected override void OnUpdate(float progress)
	{
		let target = Target;
		if (target == null || mSetter == null)
			return;

		let value = RectangleF(
			Tweening.Lerp(mFrom.X, mTo.X, progress),
			Tweening.Lerp(mFrom.Y, mTo.Y, progress),
			Tweening.Lerp(mFrom.Width, mTo.Width, progress),
			Tweening.Lerp(mFrom.Height, mTo.Height, progress)
		);
		mSetter(target, value);
	}

	protected override void OnReset()
	{
		let target = Target;
		if (target != null && mSetter != null)
			mSetter(target, mOriginalValue);
	}

	// === Factory methods ===

	/// Creates a rectangle animation from one value to another using custom getter/setter.
	public static RectangleAnimation Create(RectangleGetter getter, RectangleSetter setter, RectangleF from, RectangleF to)
	{
		let anim = new RectangleAnimation(getter, setter);
		anim.From = from;
		anim.To = to;
		return anim;
	}

	/// Creates a rectangle animation to a target value using custom getter/setter.
	public static RectangleAnimation Create(RectangleGetter getter, RectangleSetter setter, RectangleF to)
	{
		let anim = new RectangleAnimation(getter, setter);
		anim.To = to;
		return anim;
	}
}
