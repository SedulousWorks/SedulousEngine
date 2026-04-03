using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Delegate for getting a Thickness property value.
public delegate Thickness ThicknessGetter(UIElement element);

/// Delegate for setting a Thickness property value.
public delegate void ThicknessSetter(UIElement element, Thickness value);

/// Animates a Thickness property (margin, padding).
public class ThicknessAnimation : Animation
{
	private Thickness mFrom;
	private Thickness mTo;
	private Thickness mOriginalValue;
	private bool mFromSet = false;

	// Property accessors
	private ThicknessGetter mGetter ~ delete _;
	private ThicknessSetter mSetter ~ delete _;

	/// Creates a thickness animation.
	public this()
	{
	}

	/// Creates a thickness animation with getter/setter.
	public this(ThicknessGetter getter, ThicknessSetter setter)
	{
		mGetter = getter;
		mSetter = setter;
	}

	/// The starting value. If not set, uses current property value.
	public Thickness From
	{
		get => mFrom;
		set
		{
			mFrom = value;
			mFromSet = true;
		}
	}

	/// The ending value.
	public Thickness To
	{
		get => mTo;
		set => mTo = value;
	}

	/// Sets the property getter.
	public void SetGetter(ThicknessGetter getter)
	{
		if (mGetter != null) delete mGetter;
		mGetter = getter;
	}

	/// Sets the property setter.
	public void SetSetter(ThicknessSetter setter)
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

		let value = Thickness(
			Tweening.Lerp(mFrom.Left, mTo.Left, progress),
			Tweening.Lerp(mFrom.Top, mTo.Top, progress),
			Tweening.Lerp(mFrom.Right, mTo.Right, progress),
			Tweening.Lerp(mFrom.Bottom, mTo.Bottom, progress)
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

	/// Creates a margin animation to a target value.
	public static ThicknessAnimation Margin(Thickness to)
	{
		let anim = new ThicknessAnimation(
			new (e) => e.Margin,
			new (e, v) => e.Margin = v
		);
		anim.To = to;
		return anim;
	}

	/// Creates a margin animation from one value to another.
	public static ThicknessAnimation Margin(Thickness from, Thickness to)
	{
		let anim = new ThicknessAnimation(
			new (e) => e.Margin,
			new (e, v) => e.Margin = v
		);
		anim.From = from;
		anim.To = to;
		return anim;
	}

	/// Creates a padding animation to a target value.
	public static ThicknessAnimation Padding(Thickness to)
	{
		let anim = new ThicknessAnimation(
			new (e) => e.Padding,
			new (e, v) => e.Padding = v
		);
		anim.To = to;
		return anim;
	}

	/// Creates a padding animation from one value to another.
	public static ThicknessAnimation Padding(Thickness from, Thickness to)
	{
		let anim = new ThicknessAnimation(
			new (e) => e.Padding,
			new (e, v) => e.Padding = v
		);
		anim.From = from;
		anim.To = to;
		return anim;
	}
}
