using System;

namespace Sedulous.UI;

/// Routes input to views, tracking hover, press and capture by ViewId.
///
/// Every event goes through three phases, as in the DOM: CAPTURE from the root down, TARGET at
/// the view itself, then BUBBLE back up. An ancestor can therefore intercept before the target
/// sees anything, which is what a modal or a drag handle needs.
class InputManager
{
	/// BORROWED: the context owns this.
	private UIContext mContext;

	/// The longest gap between clicks, in seconds, and the furthest apart they may land, in
	/// pixels, still to count as a double click.
	public float DoubleClickTime = 0.5f;
	public float DoubleClickDistance = 4.0f;

	private ViewId mHoveredId = .();
	private ViewId mPressedId = .();
	private float mMouseX = 0.0f;
	private float mMouseY = 0.0f;
	private CursorType mCurrentCursor = .Default;
	/// The modifiers from the most recent key event, stamped into mouse events so that
	/// Ctrl and Shift clicking behave.
	private KeyModifiers mCurrentModifiers = .None;

	private MouseButton mPressedButton = .Left;
	private float mLastClickTime = 0.0f;
	private float mLastClickX = 0.0f;
	private float mLastClickY = 0.0f;
	private int32 mClickCount = 0;

	/// Pooled and reused every event, so routing input allocates nothing per frame.
	private MouseEventArgs mMouseArgs = new .() ~ delete _;
	private MouseWheelEventArgs mWheelArgs = new .() ~ delete _;
	private KeyEventArgs mKeyArgs = new .() ~ delete _;
	private TextInputEventArgs mTextArgs = new .() ~ delete _;

	/// The capture path, built once per dispatch into a fixed buffer rather than a list: input
	/// runs on every event and a tree deeper than this is pathological.
	private const int cMaxAncestors = 64;
	private View[cMaxAncestors] mAncestorChain = .();

	public this(UIContext context)
	{
		mContext = context;
	}

	public ViewId HoveredId => mHoveredId;
	public ViewId PressedId => mPressedId;
	public float MouseX => mMouseX;
	public float MouseY => mMouseY;
	public CursorType CurrentCursor => mCurrentCursor;
	public KeyModifiers CurrentModifiers => mCurrentModifiers;

	/// Forgets a view that is going away, so a deleted view cannot stay hovered or pressed.
	public void OnViewDeleted(View view)
	{
		if (mHoveredId == view.Id)
			mHoveredId = ViewId.Invalid;
		if (mPressedId == view.Id)
			mPressedId = ViewId.Invalid;
	}

	// ---- Mouse ---------------------------------------------------------------------------------
	// Coordinates arrive in PHYSICAL pixels and are divided by the DPI scale on the way in, so
	// everything below works in the same logical units as layout.

	public bool ProcessMouseMove(float physicalX, float physicalY)
	{
		let dpiScale = mContext.DpiScale;
		mMouseX = physicalX / dpiScale;
		mMouseY = physicalY / dpiScale;

		// A drag takes priority: while one runs the pointer belongs to it, not to whatever it
		// happens to be passing over.
		if (mContext.DragDrop.UpdateDrag(mMouseX, mMouseY))
			return true;

		let focus = mContext.GetFocusManager();
		if (focus.HasCapture)
		{
			if (let captured = focus.CapturedView)
			{
				let local = captured.ScreenToLocal(.(mMouseX, mMouseY));
				mMouseArgs.Set(local.X, local.Y);
				captured.OnMouseMove(mMouseArgs);
			}
			return true;
		}

		UpdateHover(mMouseX, mMouseY);

		if (let hovered = mContext.GetViewById(mHoveredId))
		{
			let local = hovered.ScreenToLocal(.(mMouseX, mMouseY));
			mMouseArgs.Set(local.X, local.Y);
			hovered.OnMouseMove(mMouseArgs);
			// The ROOT answering is not a hit: the host should still see the event.
			return hovered != mContext.ActiveInputRoot;
		}

		return false;
	}

	public bool ProcessMouseDown(MouseButton button, float physicalX, float physicalY,
		float totalTime)
	{
		let dpiScale = mContext.DpiScale;
		mMouseX = physicalX / dpiScale;
		mMouseY = physicalY / dpiScale;

		mContext.Tooltips.OnMouseDown();

		UpdateHover(mMouseX, mMouseY);
		let hitView = mContext.GetViewById(mHoveredId);

		// The popup layer gets first refusal, so a click outside an open menu closes it. A LEFT
		// click that closes something is consumed; a right click is not, so it can still open a
		// context menu where it landed.
		if (let root = mContext.ActiveInputRoot)
		{
			let popupLayer = root.PeekPopupLayer;
			if ((popupLayer != null) && (popupLayer.PopupCount > 0))
			{
				if (popupLayer.HandleClickOutside(hitView, (int32)button))
					return true;
			}
		}

		if (hitView != null)
			FocusNearestFocusable(hitView);
		else
			mContext.GetFocusManager().ClearFocus();

		UpdateClickCount(totalTime);

		mPressedId = (hitView != null) ? hitView.Id : ViewId.Invalid;
		mPressedButton = button;

		// A single left press on a drag source starts a POTENTIAL drag. The source is found by
		// walking up, so a label inside a draggable row drags the row.
		if ((hitView != null) && (button == .Left) && (mClickCount == 1))
		{
			var dragView = hitView;
			while (dragView != null)
			{
				if (let source = dragView.AsDragSource())
				{
					mContext.DragDrop.BeginPotentialDrag(dragView, source, mMouseX, mMouseY,
						button);
					break;
				}
				dragView = dragView.Parent;
			}
		}

		if (hitView == null)
			return false;

		let local = hitView.ScreenToLocal(.(mMouseX, mMouseY));
		mMouseArgs.Set(local.X, local.Y, button, mClickCount, totalTime, mCurrentModifiers);
		DispatchMouseDown(hitView, mMouseArgs);
		return hitView != mContext.ActiveInputRoot;
	}

	public bool ProcessMouseUp(MouseButton button, float physicalX, float physicalY)
	{
		let dpiScale = mContext.DpiScale;
		mMouseX = physicalX / dpiScale;
		mMouseY = physicalY / dpiScale;

		if (mContext.DragDrop.EndDrag(mMouseX, mMouseY))
			return true;

		let focus = mContext.GetFocusManager();
		if (focus.HasCapture)
			focus.ReleaseCapture();

		// The release goes to whatever was PRESSED, not to what is under the pointer now: a
		// button dragged off and released still gets its mouse up.
		let pressedView = mContext.GetViewById(mPressedId);
		mPressedId = ViewId.Invalid;

		var handled = false;
		if (pressedView != null)
		{
			let local = pressedView.ScreenToLocal(.(mMouseX, mMouseY));
			mMouseArgs.Set(local.X, local.Y, button);
			DispatchMouseUp(pressedView, mMouseArgs);
			handled = pressedView != mContext.ActiveInputRoot;
		}

		UpdateHover(mMouseX, mMouseY);
		return handled;
	}

	/// The wheel goes to what is UNDER the pointer rather than to what has focus: scrolling is
	/// about where you are looking.
	public bool ProcessMouseWheel(float physicalX, float physicalY, float deltaX, float deltaY,
		KeyModifiers modifiers = .None)
	{
		let dpiScale = mContext.DpiScale;
		let x = physicalX / dpiScale;
		let y = physicalY / dpiScale;

		mWheelArgs.Reset();
		mWheelArgs.X = x;
		mWheelArgs.Y = y;
		mWheelArgs.DeltaX = deltaX;
		mWheelArgs.DeltaY = deltaY;
		mWheelArgs.Modifiers = modifiers;

		let root = mContext.ActiveInputRoot;
		if (root == null)
			return false;

		if (let target = root.HitTest(.(x, y)))
		{
			DispatchMouseWheel(target, mWheelArgs);
			return target != root;
		}

		return false;
	}

	// ---- Keyboard ------------------------------------------------------------------------------

	public bool ProcessKeyDown(KeyCode key, KeyModifiers modifiers, bool isRepeat,
		float timestamp = 0.0f)
	{
		mCurrentModifiers = modifiers;

		if ((key == .Escape) && mContext.DragDrop.IsDragging)
		{
			mContext.DragDrop.CancelDrag();
			return true;
		}

		let focus = mContext.GetFocusManager();
		let focused = focus.FocusedView;

		// Tab normally drives traversal and never reaches a view. A view that EDITS tabs, a code
		// editor inserting indentation, opts in with WantsTabKey: it sees Tab through ordinary
		// dispatch first, and traversal runs below as the fallback if it leaves Tab unhandled.
		let isTab = (key == .Tab) && !isRepeat;
		if (isTab && ((focused == null) || !focused.WantsTabKey))
		{
			TraverseFocus(focus, modifiers);
			return true;
		}

		if (focused != null)
		{
			mKeyArgs.Set(key, modifiers, isRepeat, timestamp);
			DispatchKeyDown(focused, mKeyArgs);
			if (mKeyArgs.Handled)
				return true;
		}

		if (isTab)
		{
			TraverseFocus(focus, modifiers);
			return true;
		}

		// Return activates, but only AFTER ordinary dispatch. Converting it beforehand would
		// lock a text control out of ever seeing Return in OnKeyDown, which is what commit on
		// Enter and a multiline newline need, and would swallow it even where OnActivate does
		// nothing at all. A button does not handle Return in OnKeyDown, so it activates as
		// before.
		if ((focused != null) && !isRepeat && (key == .Return))
		{
			focused.OnActivate();
			return true;
		}

		if ((focused != null) && !isRepeat)
		{
			FocusDirection? direction = null;
			switch (key)
			{
			case .Up: direction = .Up;
			case .Down: direction = .Down;
			case .Left: direction = .Left;
			case .Right: direction = .Right;
			default:
			}

			if ((direction != null) && focus.MoveFocus(direction.Value))
				return true;
		}

		if (mContext.GetShortcuts().TryDispatch(key, modifiers))
			return true;

		// An accelerator is an Alt gesture, so the whole tree is only searched when Alt is down.
		if (modifiers.HasFlag(.Alt))
		{
			let root = mContext.ActiveInputRoot;
			if ((root != null) && SearchAccelerator(root, key, modifiers))
				return true;
		}

		return false;
	}

	public bool ProcessKeyUp(KeyCode key, KeyModifiers modifiers, float timestamp = 0.0f)
	{
		mCurrentModifiers = modifiers;

		let focused = mContext.GetFocusManager().FocusedView;
		if (focused == null)
			return false;

		mKeyArgs.Set(key, modifiers, false, timestamp);
		DispatchKeyUp(focused, mKeyArgs);
		return mKeyArgs.Handled;
	}

	public bool ProcessTextInput(char32 character)
	{
		let focused = mContext.GetFocusManager().FocusedView;
		if (focused == null)
			return false;

		mTextArgs.Reset();
		mTextArgs.Character = character;
		DispatchTextInput(focused, mTextArgs);
		return mTextArgs.Handled;
	}

	// ---- Internals -----------------------------------------------------------------------------

	private static void TraverseFocus(FocusManager focus, KeyModifiers modifiers)
	{
		if (modifiers.HasFlag(.Shift))
			focus.FocusPrev();
		else
			focus.FocusNext();
	}

	/// A second press counts as a double click only when it is close enough in BOTH time and
	/// distance: two quick clicks at opposite ends of a list are two clicks.
	private void UpdateClickCount(float totalTime)
	{
		let timeDelta = totalTime - mLastClickTime;
		let dx = mMouseX - mLastClickX;
		let dy = mMouseY - mLastClickY;

		if ((timeDelta < DoubleClickTime)
			&& ((dx * dx + dy * dy) < DoubleClickDistance * DoubleClickDistance))
			mClickCount++;
		else
			mClickCount = 1;

		mLastClickTime = totalTime;
		mLastClickX = mMouseX;
		mLastClickY = mMouseY;
	}

	private bool SearchAccelerator(View view, KeyCode key, KeyModifiers modifiers)
	{
		if (let handler = view.AsAcceleratorHandler())
		{
			if (handler.HandleAccelerator(key, modifiers))
				return true;
		}

		if (let group = view as ViewGroup)
		{
			for (int i < group.ChildCount)
			{
				if (SearchAccelerator(group.GetChildAt(i), key, modifiers))
					return true;
			}
		}

		return false;
	}

	/// Recomputes what the pointer is over, telling the views that gained and lost it.
	///
	/// The invalidation is VISUAL: a hover tint changes no geometry, and relayouting the tree on
	/// every pointer move would be ruinous.
	private void UpdateHover(float x, float y)
	{
		let root = mContext.ActiveInputRoot;
		let hitView = (root != null) ? root.HitTest(.(x, y)) : null;
		let newHoverId = (hitView != null) ? hitView.Id : ViewId.Invalid;

		if (newHoverId != mHoveredId)
		{
			if (let oldHovered = mContext.GetViewById(mHoveredId))
			{
				oldHovered.OnMouseLeave();
				oldHovered.InvalidateVisual();
			}

			mHoveredId = newHoverId;

			if (hitView != null)
			{
				hitView.OnMouseEnter();
				hitView.InvalidateVisual();
			}

			mContext.Tooltips.OnHoverChanged(hitView);
		}

		mCurrentCursor = (hitView != null) ? hitView.EffectiveCursor(.(x, y)) : .Default;
	}

	/// Focuses the nearest focusable at or above a view, so clicking a label inside a control
	/// focuses the control.
	///
	/// POINTER acquired: focus is retained, but the control draws no ring.
	private void FocusNearestFocusable(View view)
	{
		var current = view;
		while (current != null)
		{
			if (current.IsFocusable)
			{
				mContext.GetFocusManager().SetFocus(current, .Pointer);
				return;
			}
			current = current.Parent;
		}

		mContext.GetFocusManager().ClearFocus();
	}

	/// The chain from the ROOT down to the target, which is the order capture walks.
	private int BuildAncestorChain(View target)
	{
		var count = 0;
		var current = target;
		while ((current != null) && (count < cMaxAncestors))
		{
			mAncestorChain[count++] = current;
			current = current.Parent;
		}

		// Built leaf first, since walking up is the only way to build it, then reversed.
		for (int i = 0; i < count / 2; i++)
		{
			let swap = mAncestorChain[i];
			mAncestorChain[i] = mAncestorChain[count - 1 - i];
			mAncestorChain[count - 1 - i] = swap;
		}

		return count;
	}

	// ---- Dispatch ------------------------------------------------------------------------------
	// Each of these PINS its target for the whole dispatch: a handler may detach and free the
	// view, and the phases after it read its bounds and its parent.

	private void DispatchMouseDown(View target, MouseEventArgs args)
	{
		target.AddRef();
		defer target.ReleaseRef();

		let chainLength = BuildAncestorChain(target);
		args.Phase = .Capture;
		for (int i = 0; i < chainLength - 1; i++)
		{
			if (args.Handled)
				return;
			mAncestorChain[i].OnMouseDownCapture(args);
		}

		if (args.Handled)
			return;

		args.Phase = .Target;
		target.OnMouseDown(args);

		// The coordinates move into each ancestor's space as the bubble climbs.
		args.Phase = .Bubble;
		args.X += target.Bounds.X;
		args.Y += target.Bounds.Y;
		var current = target.Parent;
		while ((current != null) && !args.Handled)
		{
			current.OnMouseDown(args);
			args.X += current.Bounds.X;
			args.Y += current.Bounds.Y;
			current = current.Parent;
		}
	}

	private void DispatchMouseUp(View target, MouseEventArgs args)
	{
		target.AddRef();
		defer target.ReleaseRef();

		let chainLength = BuildAncestorChain(target);
		args.Phase = .Capture;
		for (int i = 0; i < chainLength - 1; i++)
		{
			if (args.Handled)
				return;
			mAncestorChain[i].OnMouseUpCapture(args);
		}

		if (args.Handled)
			return;

		args.Phase = .Target;
		target.OnMouseUp(args);

		args.Phase = .Bubble;
		args.X += target.Bounds.X;
		args.Y += target.Bounds.Y;
		var current = target.Parent;
		while ((current != null) && !args.Handled)
		{
			current.OnMouseUp(args);
			args.X += current.Bounds.X;
			args.Y += current.Bounds.Y;
			current = current.Parent;
		}
	}

	private void DispatchMouseWheel(View target, MouseWheelEventArgs args)
	{
		target.AddRef();
		defer target.ReleaseRef();

		let chainLength = BuildAncestorChain(target);
		args.Phase = .Capture;
		for (int i = 0; i < chainLength - 1; i++)
		{
			if (args.Handled)
				return;
			mAncestorChain[i].OnMouseWheelCapture(args);
		}

		if (args.Handled)
			return;

		args.Phase = .Target;
		target.OnMouseWheel(args);

		// A wheel event does NOT move into ancestor space: it carries a delta, not a position
		// anything reads.
		args.Phase = .Bubble;
		var current = target.Parent;
		while ((current != null) && !args.Handled)
		{
			current.OnMouseWheel(args);
			current = current.Parent;
		}
	}

	private void DispatchKeyDown(View target, KeyEventArgs args)
	{
		target.AddRef();
		defer target.ReleaseRef();

		let chainLength = BuildAncestorChain(target);
		args.Phase = .Capture;
		for (int i = 0; i < chainLength - 1; i++)
		{
			if (args.Handled)
				return;
			mAncestorChain[i].OnKeyDownCapture(args);
		}

		if (args.Handled)
			return;

		args.Phase = .Target;
		target.OnKeyDown(args);

		args.Phase = .Bubble;
		var current = target.Parent;
		while ((current != null) && !args.Handled)
		{
			current.OnKeyDown(args);
			current = current.Parent;
		}
	}

	private void DispatchKeyUp(View target, KeyEventArgs args)
	{
		target.AddRef();
		defer target.ReleaseRef();

		let chainLength = BuildAncestorChain(target);
		args.Phase = .Capture;
		for (int i = 0; i < chainLength - 1; i++)
		{
			if (args.Handled)
				return;
			mAncestorChain[i].OnKeyUpCapture(args);
		}

		if (args.Handled)
			return;

		args.Phase = .Target;
		target.OnKeyUp(args);

		args.Phase = .Bubble;
		var current = target.Parent;
		while ((current != null) && !args.Handled)
		{
			current.OnKeyUp(args);
			current = current.Parent;
		}
	}

	private void DispatchTextInput(View target, TextInputEventArgs args)
	{
		target.AddRef();
		defer target.ReleaseRef();

		let chainLength = BuildAncestorChain(target);
		args.Phase = .Capture;
		for (int i = 0; i < chainLength - 1; i++)
		{
			if (args.Handled)
				return;
			mAncestorChain[i].OnTextInputCapture(args);
		}

		if (args.Handled)
			return;

		args.Phase = .Target;
		target.OnTextInput(args);

		args.Phase = .Bubble;
		var current = target.Parent;
		while ((current != null) && !args.Handled)
		{
			current.OnTextInput(args);
			current = current.Parent;
		}
	}
}
