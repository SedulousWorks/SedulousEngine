using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Gamekit;

/// One game screen or page: a main menu, a pause menu, a HUD, a game over card.
///
/// A screen FILLS its parent, which is the screen tier's root view, and its children place
/// themselves inside it through their own layout and alignment, so a screen behaves like a
/// panel that always expands to the box it is given.
///
/// Screens are authored as markup whose root element is `<screen mode=.. transition=..
/// default-focus=..>`, registered by [[GamekitMarkup]], or wrapped around a plain document root
/// by the stack.
///
/// The LIFECYCLE hooks below are called by the ScreenStack, NOT by attach and detach: a screen
/// covered by a pause menu is still attached and still laid out, and that difference is exactly
/// what OnHidden and OnShown report. Default no ops, so a screen overrides only what it cares
/// about.
class UIScreen : ViewGroup
{
	private ScreenMode mMode = .Modal;
	private TransitionDesc mIn = .();
	private TransitionDesc mOut = .();
	private String mDefaultFocus = new .() ~ delete _;

	public this() {}

	// ---- Authored configuration ---------------------------------------------------------------

	public ScreenMode Mode
	{
		get => mMode;
		set => mMode = value;
	}

	public TransitionDesc InTransition
	{
		get => mIn;
		set => mIn = value;
	}

	public TransitionDesc OutTransition
	{
		get => mOut;
		set => mOut = value;
	}

	/// A screen usually enters and exits with the same effect, the stack reversing the exit, so
	/// setting both at once is the common authoring case.
	public void SetTransition(TransitionDesc transition)
	{
		mIn = transition;
		mOut = transition;
	}

	/// Name of the child focused when this screen becomes active, so a pad or keyboard user
	/// lands on something. Empty means the stack focuses the first focusable descendant.
	public StringView DefaultFocus => mDefaultFocus;

	public void SetDefaultFocus(StringView name) => mDefaultFocus.Set(name);

	/// Whether this screen blocks input from reaching screens below it. Modal and Opaque do.
	public bool ShieldsInput => mMode != .Overlay;

	/// Whether this screen fully hides the screens below it. Only Opaque does.
	public bool HidesBelow => mMode == .Opaque;

	// ---- Lifecycle, invoked by the ScreenStack ------------------------------------------------

	/// Pushed onto the stack.
	public virtual void OnEnter() {}

	/// Popped off the stack.
	public virtual void OnExit() {}

	/// Became the top: pushed, or uncovered by a pop above.
	public virtual void OnShown() {}

	/// Covered by a newer screen pushed on top.
	public virtual void OnHidden() {}

	// ---- Markup attribute parsers -------------------------------------------------------------

	/// Anything unrecognised is Modal, the safe default: a screen that fails to shield input
	/// lets clicks fall through to whatever it covers, which is worse than shielding too much.
	public void SetModeFromString(StringView value)
	{
		if (value == "overlay")
			mMode = .Overlay;
		else if (value == "opaque")
			mMode = .Opaque;
		else
			mMode = .Modal;
	}

	public void SetInTransitionFromString(StringView value) => mIn.Kind = ParseKind(value);

	public void SetOutTransitionFromString(StringView value) => mOut.Kind = ParseKind(value);

	/// Sets both directions, which is what the plain `transition` attribute means.
	public void SetTransitionFromString(StringView value)
	{
		let kind = ParseKind(value);
		mIn.Kind = kind;
		mOut.Kind = kind;
	}

	/// Only the kind is named by an attribute; the duration keeps the descriptor default.
	private static TransitionKind ParseKind(StringView value)
	{
		switch (value)
		{
		case "fade": return .Fade;
		case "slide-left": return .SlideLeft;
		case "slide-right": return .SlideRight;
		case "slide-up": return .SlideUp;
		case "slide-down": return .SlideDown;
		case "scale": return .Scale;
		default: return .None;
		}
	}

	// ---- Layout -------------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let pad = ResolveBoxMetrics().Chrome;
		let inner = constraints.Deflate(pad).Loosen();
		var maxWidth = 0.0f;
		var maxHeight = 0.0f;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone)
				continue;

			child.Measure(inner);
			let marginBox = child.MarginBoxSize;
			maxWidth = Max(maxWidth, marginBox.X);
			maxHeight = Max(maxHeight, marginBox.Y);
		}

		// A screen FILLS the tier: take the available box when the parent bounds it, which is
		// the usual case under a root view, and fall back to the children's extent when it
		// does not.
		MeasuredSize = .(constraints.BoundedMaxWidth(maxWidth + pad.TotalHorizontal),
			constraints.BoundedMaxHeight(maxHeight + pad.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let pad = ResolveBoxMetrics().Chrome;
		let contentWidth = width - pad.TotalHorizontal;
		let contentHeight = height - pad.TotalVertical;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone)
				continue;

			child.Layout(pad.Left, pad.Top, Max(0.0f, contentWidth), Max(0.0f, contentHeight));
		}
	}
}
