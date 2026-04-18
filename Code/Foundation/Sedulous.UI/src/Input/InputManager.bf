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

	/// Current cursor type based on the hovered view's EffectiveCursor.
	/// Platform layer should read this each frame to set the system cursor.
	public CursorType CurrentCursor { get; private set; } = .Default;

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

		// Dispatch OnMouseMove to the hovered view (needed for hover-tracking
		// in context menus, tooltips, sliders, etc.).
		let hovered = Hovered;
		if (hovered != null)
		{
			let local = ToLocal(hovered, x, y);
			mMouseArgs.Set(local.X, local.Y);
			hovered.OnMouseMove(mMouseArgs);
		}
	}

	/// Called when a mouse button is pressed.
	public void ProcessMouseDown(MouseButton button, float x, float y, float totalTime)
	{
		mMouseX = x;
		mMouseY = y;
		mTotalTime = totalTime;

		// Hide tooltip on any mouse down.
		mContext.TooltipManager?.OnMouseDown();

		// Refresh hover first so we know what was clicked.
		UpdateHover(x, y);

		// If popups are showing and the click didn't land on a popup,
		// dismiss CloseOnClickOutside popups.
		let popupLayer = mContext.PopupLayer;
		if (popupLayer != null && popupLayer.PopupCount > 0)
		{
			let hitView = Hovered;
			bool hitIsPopup = false;
			// Walk up from hit view — if any ancestor is a popup entry, don't dismiss.
			var v = hitView;
			while (v != null)
			{
				if (v.Parent is PopupLayer)
				{ hitIsPopup = true; break; }
				v = v.Parent;
			}

			if (!hitIsPopup)
			{
				if (popupLayer.HandleClickOutside(button))
					return; // LMB consumed
			}
		}

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

		// Dispatch to target, then bubble up parents if not handled.
		BubbleMouseDown(target, x, y, button, mClickCount, totalTime);

		// Update button visual state.
		if (let btn = target as Button)
			btn.IsPressed = true;
	}

	/// Fire OnMouseDown on the target, then bubble up parent chain
	/// until someone sets Handled or we reach the root.
	private void BubbleMouseDown(View target, float screenX, float screenY, MouseButton button, int32 clickCount, float timestamp)
	{
		var v = target;
		while (v != null)
		{
			let local = ToLocal(v, screenX, screenY);
			mMouseArgs.Set(local.X, local.Y, button, clickCount, timestamp);
			v.OnMouseDown(mMouseArgs);
			if (mMouseArgs.Handled) break;
			v = v.Parent;
		}
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

	// === Keyboard ===

	private KeyEventArgs mKeyArgs = new .() ~ delete _;

	/// Route a key-down event to the focused view. If Alt is held,
	/// searches for IAcceleratorHandler top-down first.
	public void ProcessKeyDown(KeyCode key, KeyModifiers modifiers, bool isRepeat)
	{
		// Alt+key: search tree for IAcceleratorHandler.
		if (modifiers.HasFlag(.Alt))
		{
			if (SearchAccelerator(mContext.Root, key, modifiers))
				return;
		}

		let focused = mContext.FocusManager.FocusedView;
		if (focused == null) return;

		// Bubble key-down up the parent chain until handled.
		var v = focused;
		while (v != null)
		{
			mKeyArgs.Set(key, modifiers, isRepeat);
			v.OnKeyDown(mKeyArgs);
			if (mKeyArgs.Handled) break;
			v = v.Parent;
		}
	}

	/// Route a key-up event to the focused view, bubbling up if unhandled.
	public void ProcessKeyUp(KeyCode key, KeyModifiers modifiers)
	{
		let focused = mContext.FocusManager.FocusedView;
		if (focused == null) return;

		var v = focused;
		while (v != null)
		{
			mKeyArgs.Set(key, modifiers, false);
			v.OnKeyUp(mKeyArgs);
			if (mKeyArgs.Handled) break;
			v = v.Parent;
		}
	}

	// === Text Input ===

	private TextInputEventArgs mTextInputArgs = new .() ~ delete _;

	/// Route a text input character to the focused view.
	public void ProcessTextInput(char32 character)
	{
		let focused = mContext.FocusManager.FocusedView;
		if (focused == null) return;

		mTextInputArgs.Character = character;
		mTextInputArgs.Handled = false;
		focused.OnTextInput(mTextInputArgs);
	}

	/// Search the tree top-down for an IAcceleratorHandler that handles
	/// the given Alt+key combination.
	private bool SearchAccelerator(View view, KeyCode key, KeyModifiers modifiers)
	{
		if (let handler = view as IAcceleratorHandler)
		{
			if (handler.HandleAccelerator(key, modifiers))
				return true;
		}
		if (let group = view as ViewGroup)
		{
			for (int i = 0; i < group.ChildCount; i++)
			{
				if (SearchAccelerator(group.GetChildAt(i), key, modifiers))
					return true;
			}
		}
		return false;
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
				oldHover.OnMouseLeave();

			// Enter new hover.
			mHoveredId = newHoverId;
			if (hitView != null)
				hitView.OnMouseEnter();

			// Notify tooltip manager of hover change.
			mContext.TooltipManager?.OnHoverChanged(hitView);
		}

		// Update cursor from hovered view.
		let cursorView = (hitView != null) ? hitView : mContext.GetElementById(mHoveredId);
		CurrentCursor = (cursorView != null) ? cursorView.EffectiveCursor : .Default;
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
	/// Accounts for RenderTransform on each ancestor.
	private Vector2 ToLocal(View view, float screenX, float screenY)
	{
		var x = screenX;
		var y = screenY;
		// Walk up and subtract each ancestor's bounds offset + inverse transform.
		var v = view;
		while (v != null && v.Parent != null)
		{
			x -= v.Bounds.X;
			y -= v.Bounds.Y;

			if (v.RenderTransform != Matrix.Identity)
			{
				let ox = v.Width * v.RenderTransformOrigin.X;
				let oy = v.Height * v.RenderTransformOrigin.Y;
				Matrix invTransform;
				if (Matrix.TryInvert(v.RenderTransform, out invTransform))
				{
					let px = x - ox;
					let py = y - oy;
					x = px * invTransform.M11 + py * invTransform.M21 + invTransform.M41 + ox;
					y = px * invTransform.M12 + py * invTransform.M22 + invTransform.M42 + oy;
				}
			}

			v = v.Parent;
		}
		return .(x, y);
	}
}
