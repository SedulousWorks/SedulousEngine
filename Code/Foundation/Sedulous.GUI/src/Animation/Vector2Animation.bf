using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Delegate for getting a Vector2 property value.
public delegate Vector2 Vector2Getter(UIElement element);

/// Delegate for setting a Vector2 property value.
public delegate void Vector2Setter(UIElement element, Vector2 value);

/// Animates a Vector2 property on a UIElement.
/// Useful for animating positions, offsets, and 2D transforms.
public class Vector2Animation : Animation
{
	private Vector2 mFrom;
	private Vector2 mTo;
	private Vector2 mOriginalValue;
	private bool mFromSet = false;

	// Property accessors
	private Vector2Getter mGetter ~ delete _;
	private Vector2Setter mSetter ~ delete _;

	/// Creates a Vector2 animation.
	public this()
	{
	}

	/// Creates a Vector2 animation with getter/setter.
	public this(Vector2Getter getter, Vector2Setter setter)
	{
		mGetter = getter;
		mSetter = setter;
	}

	/// The starting value. If not set, uses current property value.
	public Vector2 From
	{
		get => mFrom;
		set
		{
			mFrom = value;
			mFromSet = true;
		}
	}

	/// The ending value.
	public Vector2 To
	{
		get => mTo;
		set => mTo = value;
	}

	/// Sets the property getter.
	public void SetGetter(Vector2Getter getter)
	{
		if (mGetter != null) delete mGetter;
		mGetter = getter;
	}

	/// Sets the property setter.
	public void SetSetter(Vector2Setter setter)
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

		let value = Vector2(
			Tweening.Lerp(mFrom.X, mTo.X, progress),
			Tweening.Lerp(mFrom.Y, mTo.Y, progress)
		);
		mSetter(target, value);
	}

	protected override void OnReset()
	{
		let target = Target;
		if (target != null && mSetter != null)
			mSetter(target, mOriginalValue);
	}

	// === Factory methods for common properties ===

	/// Creates a render transform origin animation.
	public static Vector2Animation RenderTransformOrigin(Vector2 from, Vector2 to)
	{
		let anim = new Vector2Animation(
			new (e) => e.RenderTransformOrigin,
			new (e, v) => e.RenderTransformOrigin = v
		);
		anim.From = from;
		anim.To = to;
		return anim;
	}

	/// Creates a render transform origin animation to a target value.
	public static Vector2Animation RenderTransformOrigin(Vector2 to)
	{
		let anim = new Vector2Animation(
			new (e) => e.RenderTransformOrigin,
			new (e, v) => e.RenderTransformOrigin = v
		);
		anim.To = to;
		return anim;
	}

	/// Creates an animation from one Vector2 to another using custom getter/setter.
	public static Vector2Animation Create(Vector2Getter getter, Vector2Setter setter, Vector2 from, Vector2 to)
	{
		let anim = new Vector2Animation(getter, setter);
		anim.From = from;
		anim.To = to;
		return anim;
	}

	/// Creates an animation to a target Vector2 using custom getter/setter.
	public static Vector2Animation Create(Vector2Getter getter, Vector2Setter setter, Vector2 to)
	{
		let anim = new Vector2Animation(getter, setter);
		anim.To = to;
		return anim;
	}
}
