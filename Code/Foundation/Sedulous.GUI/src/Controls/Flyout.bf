using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// Placement options for flyouts.
public enum FlyoutPlacement
{
	/// Place above the anchor.
	Top,
	/// Place below the anchor.
	Bottom,
	/// Place to the left of the anchor.
	Left,
	/// Place to the right of the anchor.
	Right,
	/// Automatically choose based on available space.
	Auto
}

/// A lightweight popup panel that appears near an anchor element.
/// Unlike dialogs, flyouts are non-modal and close when clicking outside.
public class Flyout : ContentControl, IPopupOwner
{
	// Placement
	private FlyoutPlacement mPlacement = .Bottom;

	// Appearance
	private Color mFlyoutBorderColor = Color(80, 80, 80, 255);
	private float mFlyoutBorderThickness = 1;

	// State
	private UIElement mAnchor;

	// Events
	private EventAccessor<delegate void(Flyout)> mClosed = new .() ~ delete _;

	/// Creates a new Flyout.
	public this()
	{
		IsFocusable = true;
		IsTabStop = false;
		Background = Color(50, 50, 50, 255);
		Foreground = Color(220, 220, 220, 255);
		Padding = .(12, 8, 12, 8);
		CornerRadius = 4;  // Use inherited property with flyout-specific default
		// Don't stretch to fill container - size to content
		HorizontalAlignment = .Left;
		VerticalAlignment = .Top;
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies theme defaults for flyout styling.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		let palette = theme?.Palette ?? Palette();
		let style = GetThemeStyle();

		// Apply surface/background colors from theme
		if (palette.Surface.A > 0)
			Background = palette.Surface;
		if (palette.Text.A > 0)
			Foreground = palette.Text;

		// Border from theme
		mFlyoutBorderColor = palette.Border.A > 0 ? palette.Border : Color(80, 80, 80, 255);
		mFlyoutBorderThickness = style.BorderThickness > 0 ? style.BorderThickness : 1;

		// Corner radius from theme
		if (theme != null && theme.DefaultCornerRadius > 0)
			CornerRadius = theme.DefaultCornerRadius;
	}

	/// Event fired when the flyout is closed (either programmatically or by clicking outside).
	public EventAccessor<delegate void(Flyout)> Closed => mClosed;

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Flyout";

	/// The placement of the flyout relative to its anchor.
	public FlyoutPlacement Placement
	{
		get => mPlacement;
		set => mPlacement = value;
	}

	/// Shows the flyout anchored to the specified element.
	public void ShowAt(UIElement anchor)
	{
		if (anchor == null || anchor.Context == null)
			return;

		mAnchor = anchor;
		let context = anchor.Context;

		// Measure to get desired size
		let constraints = SizeConstraints.FromMaximum(context.ViewportWidth, context.ViewportHeight);
		Measure(constraints);

		// Calculate position based on placement
		let anchorBounds = anchor.ArrangedBounds;
		let flyoutSize = DesiredSize;
		var targetX = anchorBounds.X;
		var targetY = anchorBounds.Y;

		// Determine actual placement (Auto picks based on available space)
		var actualPlacement = mPlacement;
		if (actualPlacement == .Auto)
		{
			// Default to Bottom, but use Top if not enough space below
			let spaceBelow = context.ViewportHeight - anchorBounds.Bottom;
			let spaceAbove = anchorBounds.Top;
			actualPlacement = (spaceBelow >= flyoutSize.Height || spaceBelow >= spaceAbove) ? .Bottom : .Top;
		}

		switch (actualPlacement)
		{
		case .Top:
			targetX = anchorBounds.X;
			targetY = anchorBounds.Top - flyoutSize.Height;
		case .Bottom:
			targetX = anchorBounds.X;
			targetY = anchorBounds.Bottom;
		case .Left:
			targetX = anchorBounds.Left - flyoutSize.Width;
			targetY = anchorBounds.Y;
		case .Right:
			targetX = anchorBounds.Right;
			targetY = anchorBounds.Y;
		case .Auto:
			// Already handled above
			targetY = anchorBounds.Bottom;
		}

		// Create a zero-size anchor rect at the target position
		// PopupLayer will position the popup at this point and handle viewport clamping
		let positionRect = RectangleF(targetX, targetY, 0, 0);

		// Show via popup layer
		context.PopupLayer.ShowPopup(this, anchor, positionRect, true);

		OnAttachedToContext(context);

		// Focus the flyout or its first focusable child
		if (IsFocusable)
			context.FocusManager?.SetFocus(this);
	}

	/// Hides the flyout.
	public void Hide()
	{
		if (Context == null)
			return;

		Context.PopupLayer.ClosePopup(this);
		// Note: mAnchor and mClosed are handled by OnPopupClosed which is called by ClosePopup
	}

	/// IPopupOwner implementation - called when popup is closed externally (click-outside).
	public void OnPopupClosed(UIElement popup)
	{
		if (popup == this)
		{
			mAnchor = null;
			mClosed.[Friend]Invoke(this);
		}
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure content
		var size = base.MeasureOverride(constraints);

		// Add padding
		size.Width += Padding.Left + Padding.Right;
		size.Height += Padding.Top + Padding.Bottom;

		return size;
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		// Arrange content with padding
		let innerBounds = RectangleF(
			contentBounds.X + Padding.Left,
			contentBounds.Y + Padding.Top,
			contentBounds.Width - Padding.Left - Padding.Right,
			contentBounds.Height - Padding.Top - Padding.Bottom
		);

		if (Content != null && Content.Visibility != .Collapsed)
			Content.Arrange(innerBounds);
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw background with rounded corners
		if (Background.A > 0)
		{
			if (CornerRadius > 0)
				ctx.FillRoundedRect(bounds, CornerRadius, Background);
			else
				ctx.FillRect(bounds, Background);
		}

		// Render content
		Content?.Render(ctx);

		// Draw border
		if (mFlyoutBorderColor.A > 0 && mFlyoutBorderThickness > 0)
		{
			if (CornerRadius > 0)
				ctx.DrawRoundedRect(bounds, CornerRadius, mFlyoutBorderColor, mFlyoutBorderThickness);
			else
				ctx.DrawRect(bounds, mFlyoutBorderColor, mFlyoutBorderThickness);
		}
	}

	// === Input ===

	protected override void OnKeyDown(KeyEventArgs e)
	{
		if (e.Key == .Escape)
		{
			Hide();
			e.Handled = true;
		}

		if (!e.Handled)
			base.OnKeyDown(e);
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Test content
		if (Content != null)
		{
			let contentHit = Content.HitTest(point);
			if (contentHit != null)
				return contentHit;
		}

		return this;
	}
}
