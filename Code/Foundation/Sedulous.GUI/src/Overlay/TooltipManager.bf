namespace Sedulous.GUI;

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
	private bool mInteractive;

	/// Seconds before tooltip appears after hover starts.
	public float ShowDelay = 0.5f;

	/// Seconds before tooltip auto-hides.
	public float AutoHideDelay = 5.0f;

	private float mShowTime;

	public this(UIContext context)
	{
		mContext = context;
		mTooltipView = new TooltipView();
	}

	public ~this()
	{
		// During destruction, PopupLayer may already be freed.
		// TooltipView was shown with ownsView=false so PopupLayer won't delete it.
		// Null parent/context to prevent destructor from accessing freed objects.
		mTooltipView.[Friend]Parent = null;
		mTooltipView.[Friend]Context = null;
		delete mTooltipView;
	}

	/// Called when hover target changes.
	public void OnHoverChanged(View newTarget)
	{
		let newId = (newTarget != null) ? newTarget.Id : ViewId.Invalid;
		if (newId != mHoverTarget)
		{
			// Don't dismiss if hover moved onto the tooltip itself.
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

	/// Called when mouse is pressed - hide tooltip unless interactive
	/// and click is on the tooltip itself.
	public void OnMouseDown()
	{
		if (mShowing && mInteractive)
		{
			let hoveredId = mContext.InputManager?.HoveredId ?? .Invalid;
			let hovered = mContext.GetViewById(hoveredId);
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
				let target = mContext.GetViewById(mHoverTarget);
				if (target != null)
					Show(target);
				else
					mHoverTarget = .Invalid; // View was deleted
			}
		}
		else
		{
			mShowTime += deltaTime;
			if (mShowTime >= AutoHideDelay)
				Hide();
		}
	}

	public void OnViewDeleted(View view)
	{
		if (mHoverTarget == view.Id) mHoverTarget = .Invalid;
	}

	private void Show(View target)
	{
		// Check for custom tooltip content provider first.
		View content = null;
		if (let provider = target as ITooltipProvider)
		{
			content = provider.CreateTooltipContent();
			if (content == null) return;
			mTooltipView.SetContent(content);
		}
		else
		{
			// Fall back to plain text label.
			StringView text = (target.TooltipText != null) ? target.TooltipText : StringView();
			if (text.IsEmpty)
				return;

			let label = new Label(text);
			mTooltipView.SetContent(label);
		}

		mInteractive = target.IsTooltipInteractive;
		mTooltipView.IsHitTestVisible = mInteractive;

		// Get the popup layer from the active root.
		let root = mContext.ActiveInputRoot;
		if (root == null) return;
		let popupLayer = root.PopupLayer;

		// Show at (0,0) first so tooltip gets context-attached (needed for measurement).
		popupLayer.ShowPopup(mTooltipView, null, 0, 0,
			closeOnClickOutside: false, isModal: false, ownsView: false);
		mShowing = true;
		mShowTime = 0;

		// Measure then reposition.
		let logical = root.LogicalSize;
		let layerConstraints = BoxConstraints.Loose(logical.X, logical.Y);
		mTooltipView.Measure(layerConstraints);

		let screen = RectangleF(0, 0, logical.X, logical.Y);
		let popupSize = mTooltipView.MeasuredSize;

		// Compute screen-space position of the target.
		let targetScreen = target.LocalToScreen(.(0));
		let (x, y) = PositionTooltip(target.TooltipPlacement,
			targetScreen.X, targetScreen.Y, target.Width, target.Height,
			popupSize, screen);

		popupLayer.UpdatePopupPosition(mTooltipView, x, y);
	}

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
			if (y + popupSize.Y > screen.Height)
				y = targetY - popupSize.Y;
		case .Top:
			x = targetX;
			y = targetY - popupSize.Y;
			if (y < screen.Y)
				y = targetY + targetH;
		case .Right:
			x = targetX + targetW;
			y = targetY;
			if (x + popupSize.X > screen.Width)
				x = targetX - popupSize.X;
		case .Left:
			x = targetX - popupSize.X;
			y = targetY;
			if (x < screen.X)
				x = targetX + targetW;
		}

		// Final clamp to screen.
		x = Math.Clamp(x, screen.X, Math.Max(screen.X, screen.X + screen.Width - popupSize.X));
		y = Math.Clamp(y, screen.Y, Math.Max(screen.Y, screen.Y + screen.Height - popupSize.Y));
		return (x, y);
	}

	private void Hide()
	{
		if (mShowing)
		{
			let root = mContext.ActiveInputRoot;
			if (root != null)
				root.PopupLayer.ClosePopup(mTooltipView);
			mShowing = false;
		}
		mHoverTime = 0;
	}

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
}
