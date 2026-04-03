using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Delegate for getting a float property value.
public delegate float FloatGetter(UIElement element);

/// Delegate for setting a float property value.
public delegate void FloatSetter(UIElement element, float value);

/// Animates a float property on a UIElement.
public class FloatAnimation : Animation
{
	private float mFrom;
	private float mTo;
	private float mOriginalValue;
	private bool mFromSet = false;

	// Property accessors
	private FloatGetter mGetter ~ delete _;
	private FloatSetter mSetter ~ delete _;

	/// Creates a float animation.
	public this()
	{
	}

	/// Creates a float animation with getter/setter.
	public this(FloatGetter getter, FloatSetter setter)
	{
		mGetter = getter;
		mSetter = setter;
	}

	/// The starting value. If not set, uses current property value.
	public float From
	{
		get => mFrom;
		set
		{
			mFrom = value;
			mFromSet = true;
		}
	}

	/// The ending value.
	public float To
	{
		get => mTo;
		set => mTo = value;
	}

	/// Sets the property getter.
	public void SetGetter(FloatGetter getter)
	{
		if (mGetter != null) delete mGetter;
		mGetter = getter;
	}

	/// Sets the property setter.
	public void SetSetter(FloatSetter setter)
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

		let value = Tweening.Lerp(mFrom, mTo, progress);
		mSetter(target, value);
	}

	protected override void OnReset()
	{
		let target = Target;
		if (target != null && mSetter != null)
			mSetter(target, mOriginalValue);
	}

	// === Factory methods for common properties ===

	/// Creates an opacity animation from one value to another.
	public static FloatAnimation Opacity(float from, float to)
	{
		let anim = new FloatAnimation(
			new (e) => e.Opacity,
			new (e, v) => e.Opacity = v
		);
		anim.From = from;
		anim.To = to;
		return anim;
	}

	/// Creates an opacity animation to a target value.
	public static FloatAnimation Opacity(float to)
	{
		let anim = new FloatAnimation(
			new (e) => e.Opacity,
			new (e, v) => e.Opacity = v
		);
		anim.To = to;
		return anim;
	}

	/// Creates a width animation (for fixed-width elements).
	public static FloatAnimation Width(float to)
	{
		let anim = new FloatAnimation(
			new (e) => e.Width.IsFixed ? e.Width.Value : e.ArrangedBounds.Width,
			new (e, v) => e.Width = .Fixed(v)
		);
		anim.To = to;
		return anim;
	}

	/// Creates a width animation from one value to another.
	public static FloatAnimation Width(float from, float to)
	{
		let anim = new FloatAnimation(
			new (e) => e.Width.IsFixed ? e.Width.Value : e.ArrangedBounds.Width,
			new (e, v) => e.Width = .Fixed(v)
		);
		anim.From = from;
		anim.To = to;
		return anim;
	}

	/// Creates a height animation (for fixed-height elements).
	public static FloatAnimation Height(float to)
	{
		let anim = new FloatAnimation(
			new (e) => e.Height.IsFixed ? e.Height.Value : e.ArrangedBounds.Height,
			new (e, v) => e.Height = .Fixed(v)
		);
		anim.To = to;
		return anim;
	}

	/// Creates a height animation from one value to another.
	public static FloatAnimation Height(float from, float to)
	{
		let anim = new FloatAnimation(
			new (e) => e.Height.IsFixed ? e.Height.Value : e.ArrangedBounds.Height,
			new (e, v) => e.Height = .Fixed(v)
		);
		anim.From = from;
		anim.To = to;
		return anim;
	}
}
