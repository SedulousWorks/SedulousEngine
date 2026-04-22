using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// Defines how a popup is positioned relative to its anchor.
public enum PopupPlacement
{
	/// Position below the anchor, aligned to left edge.
	Bottom,
	/// Position below the anchor, centered.
	BottomCenter,
	/// Position above the anchor, aligned to left edge.
	Top,
	/// Position above the anchor, centered.
	TopCenter,
	/// Position to the right of the anchor.
	Right,
	/// Position to the left of the anchor.
	Left,
	/// Position at the mouse cursor location.
	Mouse,
	/// Position at absolute coordinates (use HorizontalOffset/VerticalOffset).
	Absolute,
	/// Position centered in the viewport (for dialogs).
	Center
}

/// Options for popup behavior.
public enum PopupBehavior
{
	/// No special behavior.
	None = 0,
	/// Close when clicking outside the popup.
	CloseOnClickOutside = 1,
	/// Close when pressing Escape.
	CloseOnEscape = 2,
	/// Close when the anchor loses focus.
	CloseOnAnchorLostFocus = 4,
	/// Block input to elements below (modal).
	Modal = 8,
	/// Show a dimmed overlay behind the popup (requires Modal).
	DimBackground = 16,

	/// Default behavior for popups (close on click outside and escape).
	Default = CloseOnClickOutside | CloseOnEscape,
	/// Default behavior for modal dialogs.
	ModalDialog = Modal | DimBackground | CloseOnEscape
}

/// A popup window that floats above the main UI.
/// Popups can be positioned relative to an anchor element or at absolute coordinates.
public class Popup : ContentControl, IPopupOwner
{
	private UIElement mAnchor;
	private PopupPlacement mPlacement = .Bottom;
	private PopupBehavior mBehavior = .Default;
	private float mHorizontalOffset;
	private float mVerticalOffset;
	private bool mIsOpen;

	// Events
	private EventAccessor<delegate void(Popup)> mOpenedEvent = new .() ~ delete _;
	private EventAccessor<delegate void(Popup)> mClosedEvent = new .() ~ delete _;

	/// Creates a new Popup.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;
		Visibility = .Collapsed;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Popup";

	/// The element this popup is anchored to.
	public UIElement Anchor
	{
		get => mAnchor;
		set => mAnchor = value;
	}

	/// How the popup is positioned relative to its anchor.
	public PopupPlacement Placement
	{
		get => mPlacement;
		set => mPlacement = value;
	}

	/// Behavior flags controlling how the popup opens/closes.
	public PopupBehavior Behavior
	{
		get => mBehavior;
		set => mBehavior = value;
	}

	/// Horizontal offset from the calculated position.
	public float HorizontalOffset
	{
		get => mHorizontalOffset;
		set => mHorizontalOffset = value;
	}

	/// Vertical offset from the calculated position.
	public float VerticalOffset
	{
		get => mVerticalOffset;
		set => mVerticalOffset = value;
	}

	/// Whether the popup is currently open.
	public bool IsOpen => mIsOpen;

	/// Whether this popup is modal (blocks input to elements below).
	public bool IsModal => mBehavior.HasFlag(.Modal);

	/// Fired when the popup opens.
	public EventAccessor<delegate void(Popup)> Opened => mOpenedEvent;

	/// Fired when the popup closes.
	public EventAccessor<delegate void(Popup)> Closed => mClosedEvent;

	/// Internal open implementation - called after context is set.
	private void OpenInternal()
	{
		if (mIsOpen)
			return;

		if (Context == null)
			return;

		mIsOpen = true;
		Visibility = .Visible;

		// Calculate anchor bounds based on placement
		let anchorBounds = CalculateAnchorBounds();

		// Show via PopupLayer
		let closeOnClickOutside = mBehavior.HasFlag(.CloseOnClickOutside);
		Context.PopupLayer?.ShowPopup(this, mAnchor ?? this, anchorBounds, closeOnClickOutside);

		// Ensure we're attached to context (like Flyout does)
		OnAttachedToContext(Context);

		mOpenedEvent.[Friend]Invoke(this);
		InvalidateLayout();
	}

	/// Opens the popup at the specified screen position.
	public void OpenAt(GUIContext context, float x, float y)
	{
		if (context == null)
			return;

		OnAttachedToContext(context);
		mPlacement = .Absolute;
		mHorizontalOffset = x;
		mVerticalOffset = y;
		OpenInternal();
	}

	/// Opens the popup anchored to an element.
	/// Gets context from the anchor element.
	public void OpenAt(UIElement anchor, PopupPlacement placement = .Bottom)
	{
		if (anchor == null || anchor.Context == null)
			return;

		// Get context from anchor (like Flyout does)
		OnAttachedToContext(anchor.Context);

		mAnchor = anchor;
		mPlacement = placement;
		OpenInternal();
	}

	/// Opens the popup at the current mouse position.
	public void OpenAtMouse(GUIContext context)
	{
		if (context == null)
			return;

		OnAttachedToContext(context);
		let mousePos = context.InputManager?.LastMousePosition ?? .(0, 0);
		mPlacement = .Absolute;
		mHorizontalOffset = mousePos.X;
		mVerticalOffset = mousePos.Y;
		OpenInternal();
	}

	/// Closes the popup.
	public void Close()
	{
		if (!mIsOpen)
			return;

		if (Context == null)
			return;

		// Remove from PopupLayer - this will call OnPopupClosed which handles state cleanup
		Context.PopupLayer?.ClosePopup(this);
		// Note: mAnchor, mIsOpen, Visibility, and mClosedEvent are handled by OnPopupClosed
	}

	/// Calculates the anchor bounds based on the current placement and anchor.
	private RectangleF CalculateAnchorBounds()
	{
		switch (mPlacement)
		{
		case .Absolute, .Mouse:
			// Use offset as the anchor point
			return .(mHorizontalOffset, mVerticalOffset, 0, 0);

		case .Center:
			// Center in viewport - use viewport center as anchor
			if (Context != null)
			{
				let centerX = Context.ViewportWidth / 2;
				let centerY = Context.ViewportHeight / 2;
				return .(centerX, centerY, 0, 0);
			}
			return .(0, 0, 0, 0);

		default:
			// Use anchor element bounds
			if (mAnchor != null)
			{
				var bounds = mAnchor.ArrangedBounds;
				// Apply offsets
				bounds.X += mHorizontalOffset;
				bounds.Y += mVerticalOffset;
				return bounds;
			}
			return .(mHorizontalOffset, mVerticalOffset, 0, 0);
		}
	}

	/// Called by PopupLayer when the popup is closed (externally via click-outside, or via Close()).
	public void OnPopupClosed(UIElement popup)
	{
		if (popup == this)
		{
			mIsOpen = false;
			Visibility = .Collapsed;
			mAnchor = null;
			mClosedEvent.[Friend]Invoke(this);
		}
	}

	/// Handle Escape key to close popup if behavior allows.
	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (e.Key == .Escape && mBehavior.HasFlag(.CloseOnEscape))
		{
			Close();
			e.Handled = true;
		}
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Test content first
		if (Content != null)
		{
			let contentHit = Content.HitTest(point);
			if (contentHit != null)
				return contentHit;
		}

		return this;
	}

	// === Rendering ===

	/// Render the popup with shadow and border.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Shadow (drawn regardless of image mode)
		let shadowOffset = 4.0f;
		ctx.FillRect(.(bounds.X + shadowOffset, bounds.Y + shadowOffset, bounds.Width, bounds.Height),
			Color(0, 0, 0, 60));

		// Try image-based background first (replaces background + border)
		let bgImage = GetStateBackgroundImage();
		if (bgImage.HasValue && bgImage.Value.IsValid)
		{
			ctx.DrawImageBrush(bgImage.Value, bounds);
		}
		else
		{
			// Background
			let bgColor = Background.A > 0 ? Background : Color(50, 50, 55, 255);
			ctx.FillRect(bounds, bgColor);

			// Border
			let borderColor = BorderColor.A > 0 ? BorderColor : Color(80, 80, 90, 255);
			ctx.DrawRect(bounds, borderColor, BorderThickness > 0 ? BorderThickness : 1);
		}

		// Render content
		if (HasContent)
		{
			Content.Render(ctx);
		}
	}
}
