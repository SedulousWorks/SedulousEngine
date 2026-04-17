namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Routes input events to views. Tracks hover, pressed, and capture state
/// via ViewId (not raw pointers) for safe resolution after view deletion.
/// Owned by UIContext.
public class InputManager
{
	private UIContext mContext;

	// Pooled event args — one per type, reused each event.
	private MouseEventArgs mMouseArgs = new .() ~ delete _;
	private MouseWheelEventArgs mWheelArgs = new .() ~ delete _;

	// State tracked as ViewIds for deletion safety.
	private ViewId mHoveredId;
	private ViewId mPressedId;
	private MouseButton mPressedButton;

	// Double-click detection.
	private float mLastClickTime;
	private float mLastClickX;
	private float mLastClickY;
	private MouseButton mLastClickButton;
	private int32 mClickCount;
	private const float DoubleClickTime = 0.5f;
	private const float DoubleClickDistance = 4.0f;

	// Current mouse position (logical coords).
	private float mMouseX;
	private float mMouseY;
	private float mTotalTime;

	public ViewId HoveredId => mHoveredId;
	public ViewId PressedId => mPressedId;
	public float MouseX => mMouseX;
	public float MouseY => mMouseY;

	public this(UIContext context)
	{
		mContext = context;
	}

	/// Resolve the currently hovered view (null if dead).
	public View Hovered => mContext.GetElementById(mHoveredId);

	/// Called by UIInputHelper each frame with current mouse position.
	public void ProcessMouseMove(float x, float y)
	{
		mMouseX = x;
		mMouseY = y;

		// If a view has capture, it gets all mouse events regardless of hit.
		let focusMgr = mContext.FocusManager;
		if (focusMgr.HasCapture)
		{
			let captured = focusMgr.CapturedView;
			if (captured != null)
			{
				let local = ToLocal(captured, x, y);
				mMouseArgs.Set(local.X, local.Y);
				captured.OnMouseMove(mMouseArgs);
			}
			return;
		}

		UpdateHover(x, y);
	}

	/// Called when a mouse button is pressed.
	public void ProcessMouseDown(MouseButton button, float x, float y, float totalTime)
	{
		mMouseX = x;
		mMouseY = y;
		mTotalTime = totalTime;

		// Refresh hover on mouse-down (hover may be stale if mouse didn't move).
		UpdateHover(x, y);

		let target = Hovered;
		if (target == null) return;

		// Focus the clicked view (or its nearest focusable ancestor).
		FocusOnClick(target);

		// Track pressed view.
		mPressedId = target.Id;
		mPressedButton = button;

		// Compute click count.
		let timeDelta = totalTime - mLastClickTime;
		let dist = Math.Sqrt((x - mLastClickX) * (x - mLastClickX) + (y - mLastClickY) * (y - mLastClickY));

		if (button == mLastClickButton && timeDelta < DoubleClickTime && dist < DoubleClickDistance)
			mClickCount++;
		else
			mClickCount = 1;

		mLastClickTime = totalTime;
		mLastClickX = x;
		mLastClickY = y;
		mLastClickButton = button;

		let local = ToLocal(target, x, y);
		mMouseArgs.Set(local.X, local.Y, button, mClickCount);
		target.OnMouseDown(mMouseArgs);

		// Update button visual state.
		if (let btn = target as Button)
			btn.IsPressed = true;
	}

	/// Called when a mouse button is released.
	public void ProcessMouseUp(MouseButton button, float x, float y)
	{
		mMouseX = x;
		mMouseY = y;

		// Release capture if active.
		let focusMgr = mContext.FocusManager;
		if (focusMgr.HasCapture)
		{
			let captured = focusMgr.CapturedView;
			if (captured != null)
			{
				let local = ToLocal(captured, x, y);
				mMouseArgs.Set(local.X, local.Y, button);
				captured.OnMouseUp(mMouseArgs);
			}
			focusMgr.ReleaseCapture();
		}

		let pressedView = mContext.GetElementById(mPressedId);

		// Clear pressed state.
		if (let btn = pressedView as Button)
			btn.IsPressed = false;

		// Check if released over the same view that was pressed → click.
		let hitView = mContext.Root.HitTest(.(x, y));
		if (hitView != null && pressedView != null && hitView.Id == mPressedId)
		{
			// Fire click.
			if (let btn = pressedView as Button)
				btn.FireClick();
		}

		mPressedId = .Invalid;
	}

	/// Called when the mouse wheel is scrolled.
	public void ProcessMouseWheel(float x, float y, float deltaX, float deltaY)
	{
		mWheelArgs.Reset();
		mWheelArgs.X = x;
		mWheelArgs.Y = y;
		mWheelArgs.DeltaX = deltaX;
		mWheelArgs.DeltaY = deltaY;

		// Mouse wheel bubbles up from hit target to root.
		var target = mContext.Root.HitTest(.(x, y));
		while (target != null && !mWheelArgs.Handled)
		{
			target.OnMouseWheel(mWheelArgs);
			target = target.Parent;
		}
	}

	/// Notify that a view was deleted — clear any references.
	public void OnElementDeleted(View view)
	{
		if (mHoveredId == view.Id) mHoveredId = .Invalid;
		if (mPressedId == view.Id) mPressedId = .Invalid;
	}

	// === Internal ===

	private void UpdateHover(float x, float y)
	{
		let hitView = mContext.Root.HitTest(.(x, y));
		let newHoverId = (hitView != null) ? hitView.Id : ViewId.Invalid;

		if (newHoverId != mHoveredId)
		{
			// Leave old hover.
			let oldHover = mContext.GetElementById(mHoveredId);
			if (oldHover != null)
			{
				oldHover.OnMouseLeave();
				if (let btn = oldHover as Button)
					btn.IsHovered = false;
			}

			// Enter new hover.
			mHoveredId = newHoverId;
			if (hitView != null)
			{
				hitView.OnMouseEnter();
				if (let btn = hitView as Button)
					btn.IsHovered = true;
			}
		}
	}

	private void FocusOnClick(View target)
	{
		// Walk up to find the nearest focusable ancestor.
		var v = target;
		while (v != null)
		{
			if (v.IsFocusable)
			{
				mContext.FocusManager.SetFocus(v);
				return;
			}
			v = v.Parent;
		}
		// Clicked a non-focusable area → clear focus.
		mContext.FocusManager.ClearFocus();
	}

	/// Convert screen-space coords to view-local coords by walking up the parent chain.
	private Vector2 ToLocal(View view, float screenX, float screenY)
	{
		var x = screenX;
		var y = screenY;
		// Walk up and subtract each ancestor's bounds offset.
		var v = view;
		while (v != null && v.Parent != null)
		{
			x -= v.Bounds.X;
			y -= v.Bounds.Y;
			v = v.Parent;
		}
		return .(x, y);
	}
}
