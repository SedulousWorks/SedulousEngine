using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.LegacyGUI;

/// Delegate for getting a Color property value from a UIElement.
public delegate Color32 ColorGetter(UIElement element);

/// Delegate for setting a Color property value on a UIElement.
public delegate void ColorSetter(UIElement element, Color32 value);

/// Animates a Color property on a UIElement (Control or Panel).
public class ColorAnimation : Animation
{
	private Color32 mFrom;
	private Color32 mTo;
	private Color32 mOriginalValue;
	private bool mFromSet = false;

	// Property accessors
	private ColorGetter mGetter ~ delete _;
	private ColorSetter mSetter ~ delete _;

	/// Creates a color animation.
	public this()
	{
	}

	/// Creates a color animation with getter/setter.
	public this(ColorGetter getter, ColorSetter setter)
	{
		mGetter = getter;
		mSetter = setter;
	}

	/// The starting value. If not set, uses current property value.
	public Color32 From
	{
		get => mFrom;
		set
		{
			mFrom = value;
			mFromSet = true;
		}
	}

	/// The ending value.
	public Color32 To
	{
		get => mTo;
		set => mTo = value;
	}

	/// Sets the property getter.
	public void SetGetter(ColorGetter getter)
	{
		if (mGetter != null) delete mGetter;
		mGetter = getter;
	}

	/// Sets the property setter.
	public void SetSetter(ColorSetter setter)
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

		// Use Color.Interpolate for smooth color blending
		let value = mFrom.Interpolate(mTo, progress);
		mSetter(target, value);
	}

	protected override void OnReset()
	{
		let target = Target;
		if (target != null && mSetter != null)
			mSetter(target, mOriginalValue);
	}

	// === Factory methods ===

	/// Gets the background color from either a Control or Panel.
	private static Color32 GetBackground(UIElement e)
	{
		if (let ctrl = e as Control)
			return ctrl.Background;
		if (let panel = e as Panel)
			return panel.Background;
		return Color32.Transparent;
	}

	/// Sets the background color on either a Control or Panel.
	private static void SetBackground(UIElement e, Color32 v)
	{
		if (let ctrl = e as Control)
			ctrl.Background = v;
		else if (let panel = e as Panel)
			panel.Background = v;
	}

	/// Creates a background color animation to a target color.
	/// Works with both Control and Panel elements.
	public static ColorAnimation Background(Color32 to)
	{
		let anim = new ColorAnimation(
			new => GetBackground,
			new => SetBackground
		);
		anim.To = to;
		return anim;
	}

	/// Creates a background color animation from one color to another.
	/// Works with both Control and Panel elements.
	public static ColorAnimation Background(Color32 from, Color32 to)
	{
		let anim = new ColorAnimation(
			new => GetBackground,
			new => SetBackground
		);
		anim.From = from;
		anim.To = to;
		return anim;
	}

	/// Creates a foreground color animation to a target color.
	/// Works with Control elements only.
	public static ColorAnimation Foreground(Color32 to)
	{
		let anim = new ColorAnimation(
			new (e) => { if (let c = e as Control) return c.Foreground; return Color32.Transparent; },
			new (e, v) => { if (let c = e as Control) c.Foreground = v; }
		);
		anim.To = to;
		return anim;
	}

	/// Creates a foreground color animation from one color to another.
	/// Works with Control elements only.
	public static ColorAnimation Foreground(Color32 from, Color32 to)
	{
		let anim = new ColorAnimation(
			new (e) => { if (let c = e as Control) return c.Foreground; return Color32.Transparent; },
			new (e, v) => { if (let c = e as Control) c.Foreground = v; }
		);
		anim.From = from;
		anim.To = to;
		return anim;
	}

	/// Creates a border color animation to a target color.
	/// Works with Control elements only.
	public static ColorAnimation BorderColor(Color32 to)
	{
		let anim = new ColorAnimation(
			new (e) => { if (let c = e as Control) return c.BorderColor; return Color32.Transparent; },
			new (e, v) => { if (let c = e as Control) c.BorderColor = v; }
		);
		anim.To = to;
		return anim;
	}

	/// Creates a border color animation from one color to another.
	/// Works with Control elements only.
	public static ColorAnimation BorderColor(Color32 from, Color32 to)
	{
		let anim = new ColorAnimation(
			new (e) => { if (let c = e as Control) return c.BorderColor; return Color32.Transparent; },
			new (e, v) => { if (let c = e as Control) c.BorderColor = v; }
		);
		anim.From = from;
		anim.To = to;
		return anim;
	}
}
