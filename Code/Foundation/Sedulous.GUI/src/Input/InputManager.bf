namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;


/// Routes input events to views. Tracks hover, pressed, and capture state
/// using ViewIds for deletion safety. Pooled event args avoid allocation
/// in the hot input path.
public class InputManager
{
	private UIContext mContext;

	// ViewId-based tracking (survives view deletion)
	private ViewId mHoveredId;
	private ViewId mPressedId;
	private MouseButton mPressedButton;

	// Mouse state
	private float mMouseX;
	private float mMouseY;

	// Double-click detection
	private float mLastClickTime;
	private float mLastClickX;
	private float mLastClickY;
	private int32 mClickCount;

	/// Maximum time between clicks for a double-click (seconds).
	public float DoubleClickTime = 0.5f;

	/// Maximum distance between clicks for a double-click (pixels).
	public float DoubleClickDistance = 4.0f;

	// Pooled event args (reused each frame)
	private MouseEventArgs mMouseArgs = new .();
	private MouseWheelEventArgs mWheelArgs = new .();
	private KeyEventArgs mKeyArgs = new .();
	private TextInputEventArgs mTextArgs = new .();

	/// Current hovered view ID.
	public ViewId HoveredId => mHoveredId;

	/// Current pressed view ID.
	public ViewId PressedId => mPressedId;

	/// Current mouse position in logical coordinates.
	public float MouseX => mMouseX;
	public float MouseY => mMouseY;

	/// Current cursor type based on the hovered view's EffectiveCursor.
	/// Platform layer should read this each frame to set the system cursor.
	public CursorType CurrentCursor { get; private set; } = .Default;

	public this(UIContext context)
	{
		mContext = context;
	}

	// =================================================================
	// Mouse events
	// =================================================================

	/// Process mouse movement. Coordinates in physical pixels.
	public void ProcessMouseMove(float physicalX, float physicalY)
	{
		let dpiScale = mContext.DpiScale;
		mMouseX = physicalX / dpiScale;
		mMouseY = physicalY / dpiScale;

		// Drag-drop takes priority over normal mouse processing.
		let dragDrop = mContext.DragDropManager;
		if (dragDrop != null && dragDrop.UpdateDrag(mMouseX, mMouseY))
			return;

		let focus = mContext.FocusManager;

		// If captured, route to capture target.
		if (focus.HasCapture)
		{
			let captured = focus.CapturedView;
			if (captured != null)
			{
				let local = captured.ScreenToLocal(.(mMouseX, mMouseY));
				mMouseArgs.Set(local.X, local.Y);
				captured.OnMouseMove(mMouseArgs);
			}
			return;
		}

		UpdateHover(mMouseX, mMouseY);

		let hovered = mContext.GetViewById(mHoveredId);
		if (hovered != null)
		{
			let local = hovered.ScreenToLocal(.(mMouseX, mMouseY));
			mMouseArgs.Set(local.X, local.Y);
			hovered.OnMouseMove(mMouseArgs);
		}
	}

	/// Process mouse button press. Coordinates in physical pixels.
	public void ProcessMouseDown(MouseButton button, float physicalX, float physicalY, float totalTime)
	{
		let dpiScale = mContext.DpiScale;
		mMouseX = physicalX / dpiScale;
		mMouseY = physicalY / dpiScale;

		// Hide tooltip on click.
		mContext.Tooltips?.OnMouseDown();

		UpdateHover(mMouseX, mMouseY);

		let hitView = mContext.GetViewById(mHoveredId);

		// Popup click-outside detection.
		let root = mContext.ActiveInputRoot;
		if (root != null)
		{
			let popupLayer = root.PopupLayer;
			if (popupLayer != null && popupLayer.PopupCount > 0)
			{
				bool hitIsPopup = false;
				var v = hitView;
				while (v != null)
				{
					if (v.Parent is PopupLayer) { hitIsPopup = true; break; }
					v = v.Parent;
				}

				if (!hitIsPopup)
				{
					if (popupLayer.HandleClickOutside((int32)button))
						return; // LMB consumed by popup close
				}
			}
		}

		// Focus the clicked view (find nearest focusable ancestor).
		if (hitView != null)
			FocusNearestFocusable(hitView);
		else
			mContext.FocusManager.ClearFocus();

		// Double-click detection.
		let timeDelta = totalTime - mLastClickTime;
		let distSq = (mMouseX - mLastClickX) * (mMouseX - mLastClickX) +
			(mMouseY - mLastClickY) * (mMouseY - mLastClickY);

		if (timeDelta < DoubleClickTime && distSq < DoubleClickDistance * DoubleClickDistance)
			mClickCount++;
		else
			mClickCount = 1;

		mLastClickTime = totalTime;
		mLastClickX = mMouseX;
		mLastClickY = mMouseY;

		// Track pressed state.
		mPressedId = hitView != null ? hitView.Id : .Invalid;
		mPressedButton = button;

		// Initiate potential drag on single left-click if view or ancestor is IDragSource.
		if (hitView != null && button == .Left && mClickCount == 1)
		{
			let dragDrop = mContext.DragDropManager;
			if (dragDrop != null)
			{
				var dragView = hitView;
				while (dragView != null)
				{
					if (let source = dragView as IDragSource)
					{
						dragDrop.BeginPotentialDrag(dragView, source, mMouseX, mMouseY, button);
						break;
					}
					dragView = dragView.Parent;
				}
			}
		}

		// Dispatch - bubble up parent chain.
		if (hitView != null)
		{
			let local = hitView.ScreenToLocal(.(mMouseX, mMouseY));
			mMouseArgs.Set(local.X, local.Y, button, mClickCount, totalTime);
			DispatchMouseDown(hitView, mMouseArgs);
		}
	}

	/// Process mouse button release. Coordinates in physical pixels.
	public void ProcessMouseUp(MouseButton button, float physicalX, float physicalY)
	{
		let dpiScale = mContext.DpiScale;
		mMouseX = physicalX / dpiScale;
		mMouseY = physicalY / dpiScale;

		// Drag-drop end takes priority.
		let dragDrop = mContext.DragDropManager;
		if (dragDrop != null && dragDrop.EndDrag(mMouseX, mMouseY))
			return;

		let focus = mContext.FocusManager;

		// Release capture if active.
		if (focus.HasCapture)
			focus.ReleaseCapture();

		let pressedView = mContext.GetViewById(mPressedId);

		// Clear pressed state.
		mPressedId = .Invalid;

		// Check if released over the same view that was pressed -> click.
		let root = mContext.ActiveInputRoot;
		if (root != null)
		{
			let hitView = root.HitTest(.(mMouseX, mMouseY));
			if (hitView != null && pressedView != null && hitView.Id == pressedView.Id)
			{
				// Fire click on the view (controls handle this in OnMouseUp).
			}
		}

		// Dispatch mouse up.
		if (pressedView != null)
		{
			let local = pressedView.ScreenToLocal(.(mMouseX, mMouseY));
			mMouseArgs.Set(local.X, local.Y, button);
			DispatchMouseUp(pressedView, mMouseArgs);
		}

		UpdateHover(mMouseX, mMouseY);
	}

	/// Process mouse wheel. Coordinates in physical pixels.
	public void ProcessMouseWheel(float physicalX, float physicalY, float deltaX, float deltaY, KeyModifiers modifiers = .None)
	{
		let dpiScale = mContext.DpiScale;
		let scaledX = physicalX / dpiScale;
		let scaledY = physicalY / dpiScale;

		mWheelArgs.Reset();
		mWheelArgs.X = scaledX;
		mWheelArgs.Y = scaledY;
		mWheelArgs.DeltaX = deltaX;
		mWheelArgs.DeltaY = deltaY;
		mWheelArgs.Modifiers = modifiers;

		// Mouse wheel: capture -> target -> bubble.
		let root = mContext.ActiveInputRoot;
		if (root == null) return;

		let target = root.HitTest(.(scaledX, scaledY));
		if (target != null)
			DispatchMouseWheel(target, mWheelArgs);
	}

	// =================================================================
	// Keyboard events
	// =================================================================

	/// Process key press.
	public void ProcessKeyDown(KeyCode key, KeyModifiers modifiers, bool isRepeat, float timestamp = 0)
	{
		// Escape cancels active drag.
		let dragDrop = mContext.DragDropManager;
		if (key == .Escape && dragDrop != null && dragDrop.IsDragging)
		{
			dragDrop.CancelDrag();
			return;
		}

		let focus = mContext.FocusManager;

		// Tab navigation.
		if (key == .Tab && !isRepeat)
		{
			if (modifiers.HasFlag(.Shift))
				focus.FocusPrev();
			else
				focus.FocusNext();
			return;
		}

		let focused = focus.FocusedView;

		// Activate for gamepad-style navigation (Enter key).
		if (focused != null && !isRepeat && key == .Return)
		{
			focused.OnActivate();
			return;
		}

		// Dispatch to focused view (capture -> target -> bubble).
		if (focused != null)
		{
			mKeyArgs.Set(key, modifiers, isRepeat, timestamp);
			DispatchKeyDown(focused, mKeyArgs);
			if (mKeyArgs.Handled)
				return;
		}

		// Arrow key fallback: if the focused view didn't handle the arrow key,
		// try directional focus navigation.
		if (focused != null && !isRepeat)
		{
			FocusDirection? dir = null;
			switch (key)
			{
			case .Up:    dir = .Up;
			case .Down:  dir = .Down;
			case .Left:  dir = .Left;
			case .Right: dir = .Right;
			default:
			}

			if (dir.HasValue)
			{
				if (focus.MoveFocus(dir.Value))
					return;
			}
		}

		// Shortcut manager (scoped first, then global).
		let shortcuts = mContext.Shortcuts;
		if (shortcuts != null && shortcuts.TryDispatch(key, modifiers))
			return;

		// Alt+key: search tree top-down for IAcceleratorHandler.
		if (modifiers.HasFlag(.Alt))
		{
			let root = mContext.ActiveInputRoot;
			if (root != null && SearchAccelerator(root, key, modifiers))
				return;
		}
	}

	/// Process key release.
	public void ProcessKeyUp(KeyCode key, KeyModifiers modifiers, float timestamp = 0)
	{
		let focused = mContext.FocusManager.FocusedView;
		if (focused == null) return;

		mKeyArgs.Set(key, modifiers, false, timestamp);
		DispatchKeyUp(focused, mKeyArgs);
	}

	/// Process text input (post-IME composition).
	public void ProcessTextInput(char32 character)
	{
		let focused = mContext.FocusManager.FocusedView;
		if (focused == null) return;

		mTextArgs.Reset();
		mTextArgs.Character = character;
		DispatchTextInput(focused, mTextArgs);
	}

	// =================================================================
	// Deletion safety
	// =================================================================

	/// Notify that a view was deleted - clear any references to it.
	public void OnViewDeleted(View view)
	{
		if (mHoveredId == view.Id) mHoveredId = .Invalid;
		if (mPressedId == view.Id) mPressedId = .Invalid;
	}

	// =================================================================
	// Internal
	// =================================================================

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

	private void UpdateHover(float x, float y)
	{
		let root = mContext.ActiveInputRoot;
		let hitView = (root != null) ? root.HitTest(.(x, y)) : null;
		let newHoverId = (hitView != null) ? hitView.Id : ViewId.Invalid;

		if (newHoverId != mHoveredId)
		{
			// Fire leave on old.
			let oldHovered = mContext.GetViewById(mHoveredId);
			if (oldHovered != null)
				oldHovered.OnMouseLeave();

			mHoveredId = newHoverId;

			// Fire enter on new.
			if (hitView != null)
				hitView.OnMouseEnter();

			// Notify tooltip manager of hover change.
			mContext.Tooltips?.OnHoverChanged(hitView);
		}

		// Update cursor.
		if (hitView != null)
			CurrentCursor = hitView.EffectiveCursor;
		else
			CurrentCursor = .Default;
	}

	private void FocusNearestFocusable(View view)
	{
		var v = view;
		while (v != null)
		{
			if (v.IsFocusable)
			{
				mContext.FocusManager.SetFocus(v);
				return;
			}
			v = v.Parent;
		}
		// Clicked a non-focusable area -> clear focus.
		mContext.FocusManager.ClearFocus();
	}

	// === Ancestor chain for capture phase ===

	/// Reusable buffer for building the ancestor chain (root first).
	private View[64] mAncestorChain;

	/// Build the ancestor chain from root to target (inclusive).
	/// Returns the count of views in the chain.
	private int BuildAncestorChain(View target)
	{
		// Walk up to root, store in reverse
		int count = 0;
		var v = target;
		while (v != null && count < 64)
		{
			mAncestorChain[count++] = v;
			v = v.Parent;
		}
		// Reverse to get root-first order
		for (int i = 0; i < count / 2; i++)
		{
			let temp = mAncestorChain[i];
			mAncestorChain[i] = mAncestorChain[count - 1 - i];
			mAncestorChain[count - 1 - i] = temp;
		}
		return count;
	}

	// === Three-phase dispatch: Capture -> Target -> Bubble ===

	/// Dispatch a mouse down event through all three phases.
	/// Capture walks root->target calling OnMouseDownCapture.
	/// If not handled, target gets OnMouseDown.
	/// Then bubble walks target->root calling OnMouseDown on ancestors.
	/// Coords on args start in target-local space and are translated
	/// to each ancestor's local space during bubble.
	private void DispatchMouseDown(View target, MouseEventArgs args)
	{
		let chainLen = BuildAncestorChain(target);

		// Capture phase: root -> target (exclusive — target gets Target phase)
		args.Phase = .Capture;
		for (int i = 0; i < chainLen - 1; i++)
		{
			if (args.Handled) return;
			mAncestorChain[i].OnMouseDownCapture(args);
		}

		// Target phase
		if (args.Handled) return;
		args.Phase = .Target;
		target.OnMouseDown(args);

		// Bubble phase: target's parent -> root
		args.Phase = .Bubble;
		args.X += target.Bounds.X;
		args.Y += target.Bounds.Y;
		var v = target.Parent;
		while (v != null && !args.Handled)
		{
			v.OnMouseDown(args);
			args.X += v.Bounds.X;
			args.Y += v.Bounds.Y;
			v = v.Parent;
		}
	}

	private void DispatchMouseUp(View target, MouseEventArgs args)
	{
		let chainLen = BuildAncestorChain(target);

		args.Phase = .Capture;
		for (int i = 0; i < chainLen - 1; i++)
		{
			if (args.Handled) return;
			mAncestorChain[i].OnMouseUpCapture(args);
		}

		if (args.Handled) return;
		args.Phase = .Target;
		target.OnMouseUp(args);

		args.Phase = .Bubble;
		args.X += target.Bounds.X;
		args.Y += target.Bounds.Y;
		var v = target.Parent;
		while (v != null && !args.Handled)
		{
			v.OnMouseUp(args);
			args.X += v.Bounds.X;
			args.Y += v.Bounds.Y;
			v = v.Parent;
		}
	}

	private void DispatchKeyDown(View target, KeyEventArgs args)
	{
		let chainLen = BuildAncestorChain(target);

		args.Phase = .Capture;
		for (int i = 0; i < chainLen - 1; i++)
		{
			if (args.Handled) return;
			mAncestorChain[i].OnKeyDownCapture(args);
		}

		if (args.Handled) return;
		args.Phase = .Target;
		target.OnKeyDown(args);

		args.Phase = .Bubble;
		var v = target.Parent;
		while (v != null && !args.Handled)
		{
			v.OnKeyDown(args);
			v = v.Parent;
		}
	}

	private void DispatchKeyUp(View target, KeyEventArgs args)
	{
		let chainLen = BuildAncestorChain(target);

		args.Phase = .Capture;
		for (int i = 0; i < chainLen - 1; i++)
		{
			if (args.Handled) return;
			mAncestorChain[i].OnKeyUpCapture(args);
		}

		if (args.Handled) return;
		args.Phase = .Target;
		target.OnKeyUp(args);

		args.Phase = .Bubble;
		var v = target.Parent;
		while (v != null && !args.Handled)
		{
			v.OnKeyUp(args);
			v = v.Parent;
		}
	}

	private void DispatchMouseWheel(View target, MouseWheelEventArgs args)
	{
		let chainLen = BuildAncestorChain(target);

		args.Phase = .Capture;
		for (int i = 0; i < chainLen - 1; i++)
		{
			if (args.Handled) return;
			mAncestorChain[i].OnMouseWheelCapture(args);
		}

		if (args.Handled) return;
		args.Phase = .Target;
		target.OnMouseWheel(args);

		args.Phase = .Bubble;
		var v = target.Parent;
		while (v != null && !args.Handled)
		{
			v.OnMouseWheel(args);
			v = v.Parent;
		}
	}

	private void DispatchTextInput(View target, TextInputEventArgs args)
	{
		let chainLen = BuildAncestorChain(target);

		args.Phase = .Capture;
		for (int i = 0; i < chainLen - 1; i++)
		{
			if (args.Handled) return;
			mAncestorChain[i].OnTextInputCapture(args);
		}

		if (args.Handled) return;
		args.Phase = .Target;
		target.OnTextInput(args);

		// Text input doesn't traditionally bubble, but for consistency
		// with the three-phase model we allow it.
		args.Phase = .Bubble;
		var v = target.Parent;
		while (v != null && !args.Handled)
		{
			v.OnTextInput(args);
			v = v.Parent;
		}
	}

	public ~this()
	{
		delete mMouseArgs;
		delete mWheelArgs;
		delete mKeyArgs;
		delete mTextArgs;
	}
}
