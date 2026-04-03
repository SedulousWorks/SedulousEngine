using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Placement options for tooltips.
public enum TooltipPlacement
{
	/// Tooltip appears near the mouse cursor (default).
	Mouse,
	/// Tooltip appears above the target element.
	Top,
	/// Tooltip appears below the target element.
	Bottom,
	/// Tooltip appears to the left of the target element.
	Left,
	/// Tooltip appears to the right of the target element.
	Right
}

/// Manages tooltip display timing and positioning for a GUIContext.
/// Tracks hovering over elements and shows tooltips after a delay.
public class TooltipService
{
	// The tooltip instance (reused for all tooltips)
	private Tooltip mTooltip ~ delete _;

	// Current hover tracking
	private ElementHandle<UIElement> mCurrentTarget;
	private double mHoverStartTime = -1;
	private double mShowTime = -1;
	private bool mIsShowing = false;

	// Configuration
	private float mShowDelay = 0.5f;
	private float mHideDelay = 0.0f;
	private float mAutoHideDelay = 5.0f;  // 0 = no auto-hide
	private float mOffsetX = 10;
	private float mOffsetY = 20;
	private float mElementOffset = 4;  // Gap between element and tooltip for element-relative placement
	private TooltipPlacement mPlacement = .Mouse;

	// Owning context
	private GUIContext mContext;

	/// Creates a TooltipService for the given context.
	public this(GUIContext context)
	{
		mContext = context;
		mTooltip = new Tooltip();
	}

	/// The delay in seconds before showing a tooltip (default 0.5s).
	public float ShowDelay
	{
		get => mShowDelay;
		set => mShowDelay = Math.Max(0, value);
	}

	/// The delay in seconds before hiding a tooltip after mouse leaves (default 0s).
	public float HideDelay
	{
		get => mHideDelay;
		set => mHideDelay = Math.Max(0, value);
	}

	/// The delay in seconds before auto-hiding a tooltip while still hovering (default 5s).
	/// Set to 0 to disable auto-hide (tooltip stays as long as element is hovered).
	public float AutoHideDelay
	{
		get => mAutoHideDelay;
		set => mAutoHideDelay = Math.Max(0, value);
	}

	/// Horizontal offset from cursor for tooltip positioning.
	public float OffsetX
	{
		get => mOffsetX;
		set => mOffsetX = value;
	}

	/// Vertical offset from cursor for tooltip positioning.
	public float OffsetY
	{
		get => mOffsetY;
		set => mOffsetY = value;
	}

	/// Gap between element and tooltip for element-relative placement (default 4).
	public float ElementOffset
	{
		get => mElementOffset;
		set => mElementOffset = value;
	}

	/// Tooltip placement relative to cursor or target element (default: Mouse).
	public TooltipPlacement Placement
	{
		get => mPlacement;
		set => mPlacement = value;
	}

	/// Updates the tooltip service. Called by GUIContext.Update().
	public void Update(double totalTime)
	{
		let inputManager = mContext.InputManager;
		if (inputManager == null)
			return;

		let hoveredElement = inputManager.HoveredElement;

		// Check if hovered element changed
		let currentTarget = mCurrentTarget.TryResolve();
		if (hoveredElement != currentTarget)
		{
			// Element changed
			if (mIsShowing)
			{
				// Hide current tooltip
				HideTooltip();
			}

			mCurrentTarget = hoveredElement;

			// Start hover timer if new element has tooltip text
			if (hoveredElement != null && HasTooltipText(hoveredElement))
			{
				mHoverStartTime = totalTime;
			}
			else
			{
				mHoverStartTime = -1;
			}
		}

		// Check if we should show the tooltip
		if (!mIsShowing && mHoverStartTime >= 0)
		{
			let elapsed = (float)(totalTime - mHoverStartTime);
			if (elapsed >= mShowDelay)
			{
				ShowTooltip(hoveredElement, inputManager.LastMousePosition, totalTime);
			}
		}

		// Check if we should auto-hide the tooltip
		if (mIsShowing && mAutoHideDelay > 0 && mShowTime >= 0)
		{
			let showElapsed = (float)(totalTime - mShowTime);
			if (showElapsed >= mAutoHideDelay)
			{
				HideTooltip();
			}
		}
		// Note: Tooltip stays at its initial position and does not follow the cursor.
		// This is standard tooltip behavior in most UI frameworks.
	}

	/// Shows the tooltip for the specified element.
	private void ShowTooltip(UIElement element, Vector2 mousePos, double totalTime)
	{
		if (element == null)
			return;

		let tooltipText = GetTooltipText(element);
		if (tooltipText.IsEmpty)
			return;

		// Set tooltip text
		mTooltip.Text = tooltipText;

		// Measure the tooltip
		let constraints = SizeConstraints.FromMaximum(mContext.ViewportWidth, mContext.ViewportHeight);
		mTooltip.Measure(constraints);
		let desiredSize = mTooltip.DesiredSize;

		// Calculate position based on placement
		float x, y;
		let elementBounds = element.ArrangedBounds;
		let viewportW = mContext.ViewportWidth;
		let viewportH = mContext.ViewportHeight;

		switch (mPlacement)
		{
		case .Mouse:
			// Position near cursor
			x = mousePos.X + mOffsetX;
			y = mousePos.Y + mOffsetY;

		case .Top:
			// Center above element, flip to bottom if not enough space
			x = elementBounds.X + (elementBounds.Width - desiredSize.Width) / 2;
			if (elementBounds.Top - desiredSize.Height - mElementOffset >= 5)
				y = elementBounds.Top - desiredSize.Height - mElementOffset;
			else
				y = elementBounds.Bottom + mElementOffset;  // Flip to bottom

		case .Bottom:
			// Center below element, flip to top if not enough space
			x = elementBounds.X + (elementBounds.Width - desiredSize.Width) / 2;
			if (elementBounds.Bottom + desiredSize.Height + mElementOffset <= viewportH - 5)
				y = elementBounds.Bottom + mElementOffset;
			else
				y = elementBounds.Top - desiredSize.Height - mElementOffset;  // Flip to top

		case .Left:
			// Center to the left of element, flip to right if not enough space
			y = elementBounds.Y + (elementBounds.Height - desiredSize.Height) / 2;
			if (elementBounds.Left - desiredSize.Width - mElementOffset >= 5)
				x = elementBounds.Left - desiredSize.Width - mElementOffset;
			else
				x = elementBounds.Right + mElementOffset;  // Flip to right

		case .Right:
			// Center to the right of element, flip to left if not enough space
			y = elementBounds.Y + (elementBounds.Height - desiredSize.Height) / 2;
			if (elementBounds.Right + desiredSize.Width + mElementOffset <= viewportW - 5)
				x = elementBounds.Right + mElementOffset;
			else
				x = elementBounds.Left - desiredSize.Width - mElementOffset;  // Flip to left
		}

		// Keep within viewport (final safety clamp)
		let adjustedX = Math.Clamp(x, 5, viewportW - desiredSize.Width - 5);
		let adjustedY = Math.Clamp(y, 5, viewportH - desiredSize.Height - 5);

		// Arrange tooltip
		let bounds = RectangleF(adjustedX, adjustedY, desiredSize.Width, desiredSize.Height);
		mTooltip.Arrange(bounds);

		// Show via popup layer (use a small anchor rect at the tooltip position)
		// Tooltips don't close on click-outside since TooltipService manages them
		let anchorRect = RectangleF(adjustedX, adjustedY, 1, 1);
		mContext.PopupLayer.ShowPopup(mTooltip, null, anchorRect, false);

		mIsShowing = true;
		mShowTime = totalTime;
	}

	/// Hides the current tooltip.
	public void HideTooltip()
	{
		if (mIsShowing)
		{
			mContext.PopupLayer.ClosePopup(mTooltip);
			mIsShowing = false;
		}
		mHoverStartTime = -1;
		mShowTime = -1;
	}

	/// Checks if an element has tooltip text.
	private bool HasTooltipText(UIElement element)
	{
		// Check if it's a Control with TooltipText set
		if (let control = element as Control)
		{
			return !control.TooltipText.IsEmpty;
		}
		return false;
	}

	/// Gets the tooltip text for an element.
	private StringView GetTooltipText(UIElement element)
	{
		if (let control = element as Control)
		{
			return control.TooltipText;
		}
		return "";
	}
}
