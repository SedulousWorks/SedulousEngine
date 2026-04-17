namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Manages tooltip display timing. Owns a single reusable TooltipView.
/// Ticked by UIContext each frame.
public class TooltipManager
{
	private UIContext mContext;
	private TooltipView mTooltipView;
	private ViewId mHoverTarget;
	private float mHoverTime;
	private bool mShowing;
	private bool mInteractive;   // tooltip stays when hovered

	public float ShowDelay = 0.5f;    // seconds before showing
	public float AutoHideDelay = 5.0f; // seconds before auto-hiding
	private float mShowTime;

	public this(UIContext context)
	{
		mContext = context;
		mTooltipView = new TooltipView();
	}

	public ~this()
	{
		Hide(); // remove from PopupLayer before deleting
		delete mTooltipView;
	}

	/// Called when hover target changes. Reset timer.
	public void OnHoverChanged(View newTarget)
	{
		let newId = (newTarget != null) ? newTarget.Id : ViewId.Invalid;
		if (newId != mHoverTarget)
		{
			// Don't dismiss if the hover moved onto the tooltip itself.
			// For interactive tooltips, keep showing so user can interact.
			// For non-interactive, still keep showing to prevent flicker
			// when tooltip overlaps anchor after flipping.
			if (mShowing && newTarget != null && IsTooltipOrDescendant(newTarget))
				return;

			// Don't dismiss if hover moved back to the original target
			// while an interactive tooltip is showing.
			if (mShowing && mInteractive && newId == mHoverTarget)
				return;

			Hide();
			mHoverTarget = newId;
			mHoverTime = 0;
		}
	}

	/// Check if a view is the tooltip view or a descendant of it.
	private bool IsTooltipOrDescendant(View view)
	{
		var v = view;
		while (v != null)
		{
			if (v === mTooltipView) return true;
			v = v.Parent;
		}
		return false;
	}

	/// Called when mouse is pressed — hide tooltip (unless interactive
	/// and the click is on the tooltip itself).
	public void OnMouseDown()
	{
		if (mShowing && mInteractive)
		{
			// Check if the current hover target is the tooltip — if so, don't hide.
			let hovered = mContext.InputManager.Hovered;
			if (hovered != null && IsTooltipOrDescendant(hovered))
				return;
		}
		Hide();
	}

	/// Tick each frame. Shows tooltip after delay, auto-hides after timeout.
	public void Update(float deltaTime)
	{
		if (!mHoverTarget.IsValid)
			return;

		if (!mShowing)
		{
			mHoverTime += deltaTime;
			if (mHoverTime >= ShowDelay)
			{
				let target = mContext.GetElementById(mHoverTarget);
				if (target != null)
					Show(target);
			}
		}
		else
		{
			mShowTime += deltaTime;
			if (mShowTime >= AutoHideDelay)
				Hide();
		}
	}

	private void Show(View target)
	{
		// Check for custom tooltip content provider first.
		if (let provider = target as ITooltipProvider)
		{
			let content = provider.CreateTooltipContent();
			if (content == null) return;
			mTooltipView.SetContent(content);
		}
		else
		{
			// Fall back to plain text.
			StringView text = (target.TooltipText != null) ? target.TooltipText : StringView();
			if (text.IsEmpty)
				return;
			mTooltipView.SetText(text);
		}

		mInteractive = target.IsTooltipInteractive;
		mTooltipView.IsHitTestVisible = mInteractive;

		// Show at (0,0) first so the tooltip gets context-attached
		// (needed for font measurement in labels).
		mContext.PopupLayer.ShowPopup(mTooltipView, null, 0, 0,
			closeOnClickOutside: false, isModal: false, ownsView: false);
		mShowing = true;
		mShowTime = 0;

		// Now measure with context available, then reposition.
		mTooltipView.Measure(.AtMost(300), .AtMost(200));

		let screen = RectangleF(0, 0, mContext.Root.ViewportSize.X, mContext.Root.ViewportSize.Y);
		let popupSize = mTooltipView.MeasuredSize;

		// Compute screen-space position of the target.
		float screenX = target.Bounds.X, screenY = target.Bounds.Y;
		var v = target.Parent;
		while (v != null)
		{
			screenX += v.Bounds.X;
			screenY += v.Bounds.Y;
			v = v.Parent;
		}

		let (x, y) = PositionTooltip(target.TooltipPlacement,
			screenX, screenY, target.Width, target.Height,
			popupSize, screen);

		mContext.PopupLayer.UpdatePopupPosition(mTooltipView, x, y);
	}

	/// Position tooltip relative to target based on placement, with flip fallback.
	private static (float x, float y) PositionTooltip(TooltipPlacement placement,
		float targetX, float targetY, float targetW, float targetH,
		Vector2 popupSize, RectangleF screen)
	{
		float x, y;
		switch (placement)
		{
		case .Bottom:
			x = targetX;
			y = targetY + targetH;
			// Flip above if clipping bottom.
			if (y + popupSize.Y > screen.Height)
				y = targetY - popupSize.Y;
		case .Top:
			x = targetX;
			y = targetY - popupSize.Y;
			// Flip below if clipping top.
			if (y < screen.Y)
				y = targetY + targetH;
		case .Right:
			x = targetX + targetW;
			y = targetY;
			// Flip left if clipping right.
			if (x + popupSize.X > screen.Width)
				x = targetX - popupSize.X;
		case .Left:
			x = targetX - popupSize.X;
			y = targetY;
			// Flip right if clipping left.
			if (x < screen.X)
				x = targetX + targetW;
		}

		// Final clamp to screen.
		x = Math.Clamp(x, screen.X, screen.X + screen.Width - popupSize.X);
		y = Math.Clamp(y, screen.Y, screen.Y + screen.Height - popupSize.Y);
		return (x, y);
	}

	private void Hide()
	{
		if (mShowing)
		{
			mContext.PopupLayer.ClosePopup(mTooltipView);
			mShowing = false;
		}
		mHoverTime = 0;
	}
}
