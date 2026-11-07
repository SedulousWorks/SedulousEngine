using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// EventDispatcher: routes abstract input into the node tree. Ported from eepp's
// Scene::EventDispatcher, but the core is platform-agnostic: instead of hooking a window's
// Input, it exposes an Inject* API that a GUI.Shell bridge feeds with already-abstracted events
// (from InputSurface/InputRouter). It hit-tests via the root's OverFind, keeps the hover and press
// paths, the focus and the pointer capture, and starts each input event's route (Node.RouteEvent:
// capture, target, bubble). Its refs to nodes are plain, dropped when a subtree leaves the tree
// (NotifySubtreeRemoved); what it must keep alive (an open popup, a tooltip, a drag's layer and
// preview, a gesture's node) it holds a reference to.

/// How a popup closes (after the web's popover kinds): `Auto` on a press outside it and on `back`
/// (Escape, the pad's East), and when another auto popup that it does not hold opens; `Manual` only
/// from code (a dialog); `Hint` (a tooltip) on any press or key, never closing the others, never
/// taking focus or the pointer.
enum PopupKind : uint8
{
	Auto,
	Manual,
	Hint,
}

/// How a popup opens. A class: it owns what it is told when it closes.
class PopupOptions
{
	public PopupKind Kind = .Auto;
	/// Everything below it is inert while it is open: no pointer, no keys, no bindings.
	public bool Modal = false;
	/// Focus moves into it (its first focusable node, else itself if focusable) and comes back
	/// when it closes; it is a containing navigation scope meanwhile.
	public bool TakesFocus = false;
	/// What it is placed against, again every layout pass: a node (not owned), else a rectangle
	/// in the root's space (a point for a context menu), else nothing (it keeps its own position).
	public Node Anchor = null;
	public Rect AnchorRect = .();
	public bool HasAnchorRect = false;
	/// In the middle of the root, again every layout pass, by its size (a picker over the window);
	/// its anchor is then not asked.
	public bool Centered = false;
	public PopupPlacement Placement = .();
	/// Sized by what it holds, measured again every layout pass (a tooltip, whose font a sheet
	/// gives it after it opens); else its own size when it opened.
	public bool FitContent = false;
	/// The pointer passes through it to what is below (a drag's preview).
	public bool PassesPointer = false;
	/// Closed, it goes back where it stood before it opened, rather than leaving the tree (a
	/// script's own popup or menu: nothing else keeps it, so leaving would free it).
	public bool ReturnHome = false;
	/// Told when it closes, and why (after the `toggle` event). Owned.
	public delegate void(PopupCloseReason reason) OnClosed ~ delete _;
	/// Closed, it plays the sheet's exit (`:leaving`) before it goes: out of the popups at once
	/// (input, focus and OnClosed move on), still drawn on top, taking no input, until what the
	/// sheet started has ended (a dialog fading out). Else it goes at once (a menu).
	public bool LeavesOnClose = false;
	/// Told when it has gone: out of the top layer and the tree (or back home), after its exit
	/// when it plays one; not when it opens again first. Owned.
	public delegate void() OnGone ~ delete _;
}

/// A drag's layer in the top layer: the root's size, passing the pointer through, its children
/// (the preview, the hint) each at the point the dispatcher gives it, at its own size.
class DragLayer : Node
{
	private struct Placed
	{
		/// Its child: compared, never followed.
		public Node Child;
		public Float2 At;

		public this(Node child, Float2 at)
		{
			Child = child;
			At = at;
		}
	}

	private List<Placed> mPlaced = new .() ~ delete _;

	public void Place(Node child, Float2 at)
	{
		for (int i = 0; i < mPlaced.Count; i++)
		{
			if (mPlaced[i].Child == child)
			{
				mPlaced[i].At = at;
				RequestLayout();
				return;
			}
		}
		mPlaced.Add(.(child, at));
		RequestLayout();
	}

	// A child gone (a hint replaced) is forgotten, matched by identity, never followed.
	public override void OnChildrenChanged()
	{
		for (int i = mPlaced.Count - 1; i >= 0; i--)
		{
			if (!Holds(mPlaced[i].Child))
				mPlaced.RemoveAt(i);
		}
	}

	public override void OnLayout()
	{
		for (let p in mPlaced)
		{
			if (Holds(p.Child))
			{
				let size = p.Child.Measure(LayoutConstraints());
				p.Child.Arrange(.(p.At.X, p.At.Y, size.X, size.Y));
			}
		}
	}

	// Whether `child` is one of its children, by identity.
	private bool Holds(Node child)
	{
		for (int i = 0; i < ChildCount; i++)
		{
			if (GetChildAt(i) == child)
				return true;
		}
		return false;
	}
}

/// Where a GUI's roots are on the screen, told by a host that places its windows: a drag goes on
/// over another root of the GUI, and one let go over no root ends outside, at a screen point.
/// Points are each root's pointer units (as input arrives).
interface IRootPlaces
{
	/// The dispatcher of the root under `screen`, and the point in it; null over none.
	EventDispatcher DispatcherAt(Float2 screen, out Float2 local);
	/// Where `local` in `dispatcher`'s root is on the screen; false when that is not known.
	bool ToScreen(EventDispatcher dispatcher, Float2 local, out Float2 screen);
}

class EventDispatcher
{
	/// A finger down: its id, where it went down and where it is now (device pixels).
	public struct Finger
	{
		public uint64 Id = 0;
		public Float2 Start = .();
		public Float2 Now = .();

		public this() { }

		public this(uint64 id, Float2 start, Float2 now)
		{
			Id = id;
			Start = start;
			Now = now;
		}
	}

	public const float cRepeatDelay = 0.4f; // before the first repeat
	public const float cRepeatSlowest = 0.16f; // the first repeats' interval
	public const float cRepeatFastest = 0.05f; // once held long
	public const float cRepeatRampTime = 1.2f; // from slowest to fastest

	private const float cClickInterval = 0.45f; // seconds between the presses of a double click
	// Lengths in DIPs, as a person's hand measures them: scaled by the display (Dips) to the device
	// pixels positions come in (Android's touch slop is 8dp, scaled the same way).
	private const float cClickSlop = 6.0f; // between the presses of a double click
	private const float cTapSlop = 24.0f; // between two taps
	private const float cStickDeadZone = 0.2f; // a stick at rest wobbles within this
	private const float cStickSpeed = 1400.0f; // pixels a second, pushed all the way
	private const float cPanSlop = 8.0f; // DIPs a finger moved: panning, not tapping
	private const float cFlingMinSpeed = 60.0f; // DIPs a second: slower let go just stops
	private const float cPanWindow = 0.1f; // seconds of the finger's path its speed is read over
	private const float cTooltipWarm = 0.6f; // seconds after one hid that the next shows at once
	private const float cTooltipGrace = 0.3f; // seconds an interactive one waits for the pointer
	private const float cLongPress = 0.5f;
	private const uint64 cNoFinger = uint64.MaxValue;
	private const int cPanSamples = 8;

	public this(Node root)
	{
		mRoot = root;
	}

	public Node Root => mRoot;

	/// The system-clipboard adapter (borrowed; supplied by the GUI.Shell bridge or the app).
	/// Widgets reach it through EventDispatcher.Clipboard; null means no clipboard, so cut, copy
	/// and paste do nothing.
	public IClipboard Clipboard
	{
		get => mClipboard;
		set => mClipboard = value;
	}

	// === Modal windows refused (an unattended run) ===

	/// Asked before a modal window opens here (Window.OpenModal): false keeps it from opening and
	/// it answers as cancelled, so nothing waits for a person no one is there to be (an agent
	/// running an action). Unset: every one opens. Take the one there to restore it after (scopes
	/// nest). OWNERSHIP of `interceptor` transfers; one there already is deleted.
	public void SetModalInterceptor(delegate bool(Node window) interceptor)
	{
		delete mModalInterceptor;
		mModalInterceptor = interceptor;
	}

	/// The interceptor there, taken out (none there now). OWNERSHIP passes to the caller.
	public delegate bool(Node window) TakeModalInterceptor()
	{
		let interceptor = mModalInterceptor;
		mModalInterceptor = null;
		return interceptor;
	}

	/// Whether a modal window may open here now.
	public bool AllowsModal(Node window) => (mModalInterceptor == null) || mModalInterceptor(window);

	public Node OverNode => mOverNode;
	/// Whether the keyboard or the pad drives it now (the last input was a key, a pad button or a
	/// direction, not the pointer): a menu opened then lights its first item.
	public bool IsUsingKeyboard => mInputKind != .Pointer;

	// === The input kind ===

	/// What drives the GUI now: the pointer, the keyboard or a pad. The focus ring follows it
	/// (shown for the keys and the pad, hidden for the pointer, as Godot's does), a pad hides the
	/// cursor, a sheet reads it as `@media (input: ...)`, and the root hears `inputkind`. Set, a
	/// host's tracker saw another kind of input (Sedulous.Input's, which GUI.Shell's bridge passes
	/// on as it changes: a mouse moved, a stick pushed, which reach no widget). The dispatcher also
	/// follows what it is given (a press, a key, a pad button or direction), so a host without a
	/// tracker, or a test, still drives it.
	public Sedulous.GUI.InputKind InputKind
	{
		get => mInputKind;
		set => ApplyInputKind(value);
	}

	/// The input kind, read as a binding's dependency (a button prompt follows it).
	public Sedulous.GUI.InputKind ObserveInputKind()
	{
		mInputKindChanged.Track();
		return mInputKind;
	}

	// === Tooltips ===
	// The nearest tooltip text up the parent chain from the hovered node shows as a hint popup
	// after the delay, on this dispatcher's clock (the GUI's update ticks it); just after one hid,
	// the next shows at once. Any press or key hides it until the pointer moves to another. A
	// finger shows one by a long press on a node with no context menu.

	public float TooltipDelay
	{
		get => mTipDelay;
		set => mTipDelay = Math.Max(0.0f, value);
	}

	/// While the keys move the focus, the focused control's tooltip shows after the delay, below
	/// it (on by default). The pointer's tooltip goes first.
	public bool KeyboardTooltips
	{
		get => mKeyboardTooltips;
		set => mKeyboardTooltips = value;
	}

	/// The tooltip shown now, or null.
	public Node ShownTooltip => ((mTip != null) && IsPopupOpen(mTip)) ? mTip : null;

	/// Asks for the focused node's context menu, at its bottom-left (Shift+F10, the Menu key): a
	/// `contextmenu` event there. True when something opened one.
	public bool InjectContextMenu()
	{
		let target = KeyTarget();
		if (target == null)
			return false;
		UseKeyboard();
		let e = scope MouseEvent(.ContextMenu, target, target.ConvertToWorldSpace(.(0.0f, target.Size.Y)));
		return target.RouteEvent(e);
	}

	/// What the last arrow, d-pad or stick move weighed.
	public NavTrace LastNavigation => mLastNavigation;

	/// The focused node, read as a binding's dependency (a command's availability follows it).
	public Node ObserveFocus()
	{
		mFocusChanged.Track();
		return mFocusNode;
	}

	public Float2 MousePosition => mMousePos;

	/// True if the focused node wants platform text input (the GUI.Shell bridge reconciles the
	/// window's IME state against this each frame).
	public bool WantsTextInput => (mFocusNode != null) && mFocusNode.WantsTextInput;
	/// Whether the focused node's text input is secret (a password).
	public bool IsTextInputSecret => (mFocusNode != null) && mFocusNode.IsTextInputSecret;

	// === Injection (fed by the shell bridge) ===
	// Each returns whether the GUI used the input: a handler took it, or the pointer is over a node
	// that takes it (IsPointerOver), so a game host knows a click was the UI's.

	/// `modifiers` held during the move (a drag that scrubs finer with Shift).
	public bool InjectMouseMove(Float2 position, uint32 modifiers = 0) => PointerMove(position, .Mouse, 0, modifiers);

	public bool InjectMouseDown(Float2 position, MouseButton button, uint32 modifiers = 0) => PointerDown(position, button, modifiers, .Mouse, 0);

	public bool InjectMouseUp(Float2 position, MouseButton button, uint32 modifiers = 0) => PointerUp(position, button, modifiers, .Mouse, 0);

	// === Touch === The first finger down drives the pointer as the mouse does (a press, moves, a
	// release, a click), its events marked as touch; every finger down is followed, where it went
	// down and where it is (two make a gesture), but no other drives the pointer. A finger hovers
	// only while it is down, so nothing stays hovered after a tap.
	//
	// A finger is a tap or a pan (gpui-ce's machine): once it moves past cPanSlop the nearest
	// scroller under where it went down that can move that way takes it, the press is cancelled
	// (the row under the finger is not clicked), and the content follows the finger; let go moving,
	// the scroller flings. A finger that lands on a flinging scroller catches it: the fling stops
	// and that touch clicks nothing.

	public bool InjectTouchDown(uint64 finger, Float2 position)
	{
		if (FindFinger(finger) < 0)
			mFingers.Add(.(finger, position, position));
		if (BeginGesture())
			return true; // a second finger over a node that takes gestures
		if (mTouchActive)
			return false; // a second finger: followed, not the pointer
		mTouchActive = true;
		mTouchFinger = finger;
		mPanning = false;
		mPanScroller = null;
		mPanSampleCount = 0;
		bool caught = false;
		for (var n = HitTest(position); n != null; n = n.Parent)
		{
			if (n.IsFlinging)
			{
				n.StopFling();
				caught = true;
			}
		}
		let used = PointerDown(position, .Left, 0, .Touch, finger);
		AddPanSample(position);
		if (caught)
		{
			CancelPointer(); // a catch, not a tap
			mLongPressArmed = false;
			return true;
		}
		return used;
	}

	public bool InjectTouchMove(uint64 finger, Float2 position)
	{
		let at = FindFinger(finger);
		if (at >= 0)
			mFingers[at].Now = position;
		if (mGesturing && IsGestureFinger(finger))
		{
			MoveGesture();
			return true;
		}
		if (!mTouchActive || (finger != mTouchFinger))
			return false;
		AddPanSample(position);
		if (!mPanning && !mDragActive && !mTouchDragArmed)
		{
			let moved = Float2(position.X - mPressAt.X, position.Y - mPressAt.Y);
			// Panned only along an axis the touch-action where it went down leaves to the GUI;
			// along another, the finger goes on as the pointer (the node's own drag).
			let under = HitTest(mPressAt);
			let allowed = (under != null) ? under.EffectiveTouchActions : cTouchAuto;
			let axis = (Abs(moved.X) > Abs(moved.Y)) ? cTouchPanX : cTouchPanY;
			if (((Abs(moved.X) > Dips(cPanSlop)) || (Abs(moved.Y) > Dips(cPanSlop))) && ((allowed & axis) != 0))
			{
				let scroller = PanScrollerFor(moved);
				if (scroller != null)
				{
					mPanning = true;
					mPanScroller = scroller;
					mPanLast = mPressAt; // the content keeps to the finger from where it went down
					CancelPointer();
					mLongPressArmed = false;
				}
			}
		}
		if (mPanning)
		{
			if (mPanScroller != null)
				mPanScroller.ScrollBy(InNodeUnits(mPanScroller, mPanLast, .(mPanLast.X - position.X, mPanLast.Y - position.Y)));
			mPanLast = position;
			mMousePos = position;
			return true;
		}
		return PointerMove(position, .Touch, finger);
	}

	public bool InjectTouchUp(uint64 finger, Float2 position)
	{
		let at = FindFinger(finger);
		if (at >= 0)
			mFingers.RemoveAt(at);
		if (mGesturing && IsGestureFinger(finger))
		{
			EndGesture(.GestureEnd); // the other finger, still down, does nothing more
			return true;
		}
		if (!mTouchActive || (finger != mTouchFinger))
			return false;
		mTouchActive = false;
		if (mPanning)
		{
			AddPanSample(position);
			mPanning = false;
			let v = PanVelocity();
			if ((mPanScroller != null) && (Abs(v.X) + Abs(v.Y) > Dips(cFlingMinSpeed)))
				mPanScroller.Fling(InNodeUnits(mPanScroller, position, .(-v.X, -v.Y)));
			mPanScroller = null;
			UpdateHoverPath(null, position);
			return true;
		}
		if (mTouchDragArmed && !mDragActive)
			CancelPointer(); // held to drag and let go still: neither a drag nor a tap
		mTouchDragArmed = false;
		let used = PointerUp(position, .Left, 0, .Touch, finger);
		UpdateHoverPath(null, position); // the finger lifted: nothing is under it
		return used;
	}

	/// The fingers down, in the order they went down.
	public Span<Finger> Fingers => (Span<Finger>)mFingers;

	/// A finger the platform took back (a system gesture): no release follows. Its gesture is
	/// cancelled, its press cancelled, its pan ended where it is.
	public bool InjectTouchCancel(uint64 finger)
	{
		let at = FindFinger(finger);
		if (at >= 0)
			mFingers.RemoveAt(at);
		if (mGesturing && IsGestureFinger(finger))
		{
			EndGesture(.GestureCancel);
			return true;
		}
		if (!mTouchActive || (finger != mTouchFinger))
			return false;
		if (!mPanning)
			CancelPointer();
		mTouchActive = false;
		mPanning = false;
		mPanScroller = null;
		mLongPressArmed = false;
		mTouchDragArmed = false;
		UpdateHoverPath(null, mMousePos);
		return true;
	}

	/// A trackpad's pinch at the pointer (the platform's gesture, its fingers never touches):
	/// begun, updated by `scaleDelta` (above 1 spreading), ended. The same gesture events as two
	/// fingers make, for a node whose touch-action leaves pinch-zoom out, marked as the mouse's; no
	/// rotation and no translation.
	public bool InjectPinch(EventType phase, float scaleDelta)
	{
		if (phase == .GestureStart)
		{
			if (mGesturing)
				return false;
			let target = HitTest(mMousePos);
			if ((target == null) || ((target.EffectiveTouchActions & cTouchPinchZoom) != 0))
				return false;
			mGestureIds[0] = cNoFinger;
			mGestureIds[1] = cNoFinger;
			mGestureFocus0 = mMousePos;
			mGestureScale = 1.0f;
			mGestureRotation = 0.0f;
			mGestureTranslation = .(0.0f, 0.0f);
			mGesturePointer = .Mouse;
			SetGestureTarget(target);
			mGesturing = true;
			RouteGesture(.GestureStart, 1.0f, 0.0f, .(0.0f, 0.0f));
			return true;
		}
		if (!mGesturing || (mGesturePointer != .Mouse))
			return false;
		if (phase == .GestureChange)
		{
			if (mGestureTarget.RootNode != mRoot)
			{
				EndGesture(.GestureCancel);
				return true;
			}
			mGestureScale *= scaleDelta;
			RouteGesture(.GestureChange, scaleDelta, 0.0f, .(0.0f, 0.0f));
			return true;
		}
		EndGesture((phase == .GestureCancel) ? .GestureCancel : .GestureEnd);
		return true;
	}

	/// Two fingers are making a gesture.
	public bool IsGesturing => mGesturing;

	/// Ends the gesture in progress as cancelled (a finger the platform took back): its target
	/// hears `gesturecancel`.
	public void CancelGesture()
	{
		if (mGesturing)
			EndGesture(.GestureCancel);
	}

	/// A finger is panning a scroller (its press was cancelled).
	public bool IsPanning => mPanning;
	public bool IsTouchActive => mTouchActive;

	public int32 FindFinger(uint64 id)
	{
		for (int i = 0; i < mFingers.Count; i++)
		{
			if (mFingers[i].Id == id)
				return (int32)i;
		}
		return -1;
	}

	/// Cancels the press in progress: the pressed node hears PointerCancel (a widget drops its
	/// drag), no release or click follows, and the press path and any capture clear. A scroller
	/// that starts panning under a finger calls it, so the row under the finger is not clicked at
	/// the end of the scroll.
	public void CancelPointer()
	{
		let pressed = mDownNode;
		if (pressed != null)
			pressed.AddRef();
		defer
		{
			if (pressed != null)
				pressed.ReleaseRef();
		}
		mDownNode = null;
		ClearPressPath();
		if ((pressed != null) && pressed.IsTreeEnabled)
		{
			let e = scope MouseEvent(.PointerCancel, pressed, mMousePos);
			e.Pointer = mTouchActive ? .Touch : .Mouse;
			e.PointerId = mTouchActive ? mTouchFinger : 0;
			pressed.RouteEvent(e);
		}
		if (mCaptureNode != null)
			ReleasePointer(mCaptureNode);
	}

	public bool InjectMouseWheel(Float2 position, Float2 delta, uint32 modifiers = 0)
	{
		var hit = HitTest(position);
		// Up from the node under the pointer: a scroller takes it, one at its end leaves it to the
		// one around it. A disabled control takes no wheel but does not stop it: it starts at the
		// nearest enabled node up from it (a list of cards, some disabled, scrolls).
		while ((hit != null) && !hit.IsTreeEnabled)
			hit = hit.Parent;
		bool used = false;
		if (hit != null)
		{
			let e = scope WheelEvent(hit, position, delta, modifiers);
			used = hit.RouteEvent(e);
		}
		return used || IsPointerTaken(hit);
	}

	// === Capturing the next key ===

	/// The next key or pad button goes to `onKey` before the keymap, navigation or any widget sees
	/// it (a rebinding screen). A modifier pressed alone is taken as it is released (so Ctrl then S
	/// is Ctrl+S); the text a taken key types is dropped. Escape calls `onCancel` instead, unless
	/// `takeEscape`. A capture asked for while one waits replaces it (its cancel is called).
	/// OWNERSHIP of both delegates transfers.
	public void CaptureNextKey(delegate void(Keystroke stroke) onKey, delegate void() onCancel = null, bool takeEscape = false)
	{
		CancelKeyCapture();
		delete mCapture.OnKey;
		mCapture.OnKey = onKey;
		delete mCapture.OnCancel;
		mCapture.OnCancel = onCancel;
		mCapture.TakeEscape = takeEscape;
		mCapture.Waiting = true;
		mCapture.PendingModifier = 0;
	}

	/// Stops a capture waiting, calling its cancel.
	public void CancelKeyCapture()
	{
		if (!mCapture.Waiting)
			return;
		mCapture.Waiting = false;
		let cancel = mCapture.OnCancel;
		mCapture.OnCancel = null;
		delete mCapture.OnKey;
		mCapture.OnKey = null;
		if (cancel != null)
			cancel();
		delete cancel;
	}

	public bool IsCapturingKey => mCapture.Waiting;

	// === Access keys ===

	/// Whether access keys are underlined now: while Alt is held, or always.
	public bool AreMnemonicsShown => mMnemonicsAlways || mAltHeld;

	/// Underlines access keys always, not only while Alt is held (a platform that does).
	public bool MnemonicsAlwaysShown
	{
		get => mMnemonicsAlways;
		set
		{
			if (value == mMnemonicsAlways)
				return;
			let was = AreMnemonicsShown;
			mMnemonicsAlways = value;
			if (was != AreMnemonicsShown)
				RedrawMnemonics();
		}
	}

	public bool InjectKeyDown(uint32 keyCode, uint32 modifiers = 0) => KeyDownFrom(.Keyboard, keyCode, modifiers);

	/// The chord that frees a focus capturing every key (Node.CapturesAllKeys): Shift+F1 by
	/// default, as a game in an editor's panel offers it.
	public Keystroke CaptureRelease
	{
		get => mCaptureRelease;
		set => mCaptureRelease = value;
	}

	/// A key down, from the keyboard or standing in for a pad's button (its East as Escape).
	public bool KeyDownFrom(Sedulous.GUI.InputKind from, uint32 keyCode, uint32 modifiers)
	{
		NoteInput();
		DropHiddenFocus();
		ApplyInputKind(from);
		mCapture.DropText = false;
		if ((keyCode == (uint32)KeyCode.LeftAlt) || (keyCode == (uint32)KeyCode.RightAlt))
			SetAltHeld(true);
		if (mCapture.Waiting)
		{
			let key = (KeyCode)keyCode;
			if ((key == .Escape) && (modifiers == 0) && !mCapture.TakeEscape)
			{
				CancelKeyCapture();
				return true;
			}
			if (ModifierOfKey(key) != 0)
			{
				mCapture.PendingModifier = keyCode; // alone if it is released before another key
				return true;
			}
			mCapture.DropText = true; // what it types is not text now
			TakeCapturedKey(.(keyCode, modifiers, false));
			return true;
		}
		// A keyboard drag: Escape (a pad's East) cancels, Return or Space drops at the focus, the
		// rest move the focus as ever, and the focus is asked again.
		if (mDragActive && mDragFromKeyboard)
		{
			if (keyCode == (uint32)KeyCode.Escape)
			{
				CancelDrag();
				return true;
			}
			if (((keyCode == (uint32)KeyCode.Return) || (keyCode == (uint32)KeyCode.Space)) && (modifiers == 0))
			{
				QueryAtFocus();
				Drop();
				return true;
			}
		}
		// A pointer drag takes the keys: Escape (a pad's East) cancels it, a modifier asks again.
		if (mDragActive && !mDragFromKeyboard)
		{
			if (keyCode == (uint32)KeyCode.Escape)
				CancelDrag();
			else if (modifiers != mDragModifiers)
			{
				mDragModifiers = modifiers;
				QueryDrop(mMousePos);
			}
			return true;
		}
		// A focus that captures every key (a game in a panel) takes this one, whatever it is, and
		// the GUI acts on none; its release chord alone frees it.
		if ((mFocusNode != null) && mFocusNode.CapturesAllKeys)
		{
			let strokeModifiers = modifiers & ~ModifierOfKey((KeyCode)keyCode);
			if (Keystroke(keyCode, strokeModifiers, false) == mCaptureRelease)
			{
				let released = mFocusNode;
				released.CapturesAllKeys = false;
				released.SendEvent(scope NamedEvent(released, "keysreleased"));
				return true;
			}
			RouteKey(.KeyDown, keyCode, modifiers);
			return true;
		}
		// A key hides a tooltip, and keeps it hidden until the pointer moves on (as a press does).
		if (mTipProvider != null)
			mTipSuppressed = true;
		ClosePopupsOfKind(.Hint, .Code);
		// The focused widget, and its ancestors (capture, then bubble from the focus), first.
		if (RouteKey(.KeyDown, keyCode, modifiers))
		{
			if (mDragActive && mDragFromKeyboard)
				QueryAtFocus(); // the focus's own key (a list's arrows) moved where it would drop
			return true;
		}
		// Tab and Shift+Tab traverse focus when nothing took them; from a widget that captures Tab
		// they are its keys, and Ctrl+Tab and Ctrl+Shift+Tab traverse instead.
		if (keyCode == (uint32)KeyCode.Tab)
		{
			let captured = (mFocusNode != null) && mFocusNode.TabCaptures;
			let traverse = captured ? KeyModCtrl : (uint32)0;
			if ((modifiers & ~KeyModShift) == traverse)
				return ((modifiers & KeyModShift) != 0) ? FocusPrevious() : FocusNext();
			if (captured && ((modifiers & ~KeyModShift) == 0))
				return true; // the widget's own key, though it did nothing with it
		}
		// Then the bindings (a keystroke bound to a command where the focus path's contexts allow).
		let strokeModifiers = modifiers & ~ModifierOfKey((KeyCode)keyCode); // Left Shift alone is "leftshift"
		if ((mKeystrokes != null) && mKeystrokes(.(keyCode, strokeModifiers, false)))
			return true;
		// Alt and an access key no binding took: the widget it marks, in the open menu or the focus
		// scope, takes focus and acts.
		if ((modifiers == KeyModAlt) && ActivateMnemonic(MnemonicOfKey((KeyCode)keyCode)))
			return true;
		if (modifiers != 0)
			return false;
		// What is left is navigation's: an arrow moves focus, Return or Space activates.
		switch ((KeyCode)keyCode)
		{
		case .Up: return MoveFocus(.Up);
		case .Down: return MoveFocus(.Down);
		case .Left: return MoveFocus(.Left);
		case .Right: return MoveFocus(.Right);
		case .Return, .Space: return Activate();
		default: return false;
		}
	}

	/// What Tab steps through now, in order, added to `outStops` (borrowed): the tab-focusable
	/// widgets shown and enabled, inside a modal while one is open, or inside the dialog focus is
	/// in (the debug overlay numbers them).
	public void TabStops(List<Node> outStops)
	{
		let stops = outStops;
		var within = FocusScopeRoot;
		let contain = ContainingScopeOf(mFocusNode);
		if ((contain != null) && IsInSubtree(contain, within))
			within = contain;
		CollectTabStops(within, stops);
		// A focus group is one stop, where its first member stood: the member focused now, else
		// its entry (remembered, default, current, first).
		for (int i = 0; i < stops.Count; i++)
		{
			let group = OutermostFocusGroup(stops[i], within);
			if (group == null)
				continue;
			let stop = ((mFocusNode != null) && IsInSubtree(mFocusNode, group) && mFocusNode.TabFocusable)
				? mFocusNode
				: EntryInto(group, stops[i]);
			stops[i] = stop;
			for (int j = stops.Count - 1; j >= i + 1; j--)
			{
				if (OutermostFocusGroup(stops[j], within) == group)
					stops.RemoveAt(j);
			}
		}
		// tab-index: a negative one is skipped; positive ones first, lowest first, a tie and the
		// zeros in tree order (insertion sort keeps it: the stops are few).
		int kept = 0;
		for (int i = 0; i < stops.Count; i++)
		{
			if (stops[i].TabIndex >= 0)
				stops[kept++] = stops[i];
		}
		if (kept < stops.Count) // RemoveRange asserts its index is inside, even for nothing
			stops.RemoveRange(kept, stops.Count - kept);
		for (int i = 1; i < stops.Count; i++)
		{
			for (int j = i; (j > 0) && EventDispatcherDetail.TabsBefore(stops[j], stops[j - 1]); j--)
			{
				let swap = stops[j];
				stops[j] = stops[j - 1];
				stops[j - 1] = swap;
			}
		}
	}

	/// Moves focus to the best widget in `direction` (inside a modal while one is open, within
	/// focus scopes); with nothing focused, to the GUI's entry. True when focus moved. The
	/// gamepad's d-pad and stick arrive here as the arrows do.
	public bool MoveFocus(NavDirection direction)
	{
		UseKeyboard();
		let root = FocusScopeRoot;
		if (root == null)
			return false;
		HitTest(.(0.0f, 0.0f)); // the layout as it is now (a pending pass runs first)
		let target = NavigateFrom(root, mFocusNode, direction, mLastNavigation);
		if ((target == null) || (target == mFocusNode))
			return false;
		FocusNode = target;
		return true;
	}

	/// A gamepad button (the d-pad goes to PressDirection): the bindings first (East is `back`'s by
	/// default); left to it, South activates and East is Escape, for a widget's own Escape (an edit
	/// cancelled).
	public void InjectPadButton(PadButton button)
	{
		if (PadCaptured)
			return;
		NoteInput();
		DropHiddenFocus();
		ApplyInputKind(.Pad);
		UseKeyboard();
		if (mCapture.Waiting)
		{
			TakeCapturedKey(.((uint32)button, 0, true));
			return;
		}
		if ((mKeystrokes != null) && mKeystrokes(.((uint32)button, 0, true)))
			return;
		if (button == .South)
			Activate();
		else if (button == .East)
			KeyDownFrom(.Pad, (uint32)KeyCode.Escape, 0); // not taken as `back`: a widget's own Escape
	}

	/// Told on input a user gave this root (a press, a key, the gamepad): its GUI makes it the
	/// active root. OWNERSHIP of `onInput` transfers.
	public void SetOnInput(delegate void() onInput)
	{
		delete mOnInput;
		mOnInput = onInput;
	}

	/// Where unhandled keystrokes go: the SceneRoot's keymap (true when it took one). OWNERSHIP of
	/// `router` transfers.
	public void SetKeystrokeRouter(delegate bool(Keystroke stroke) router)
	{
		delete mKeystrokes;
		mKeystrokes = router;
	}

	/// The press in progress already activated what it pressed (a button acting on the press, a
	/// repeating one): its release makes no click.
	public void SuppressClick()
	{
		mClickSuppressed = true;
	}

	/// Activates the focused widget (Return, Space, a gamepad's South): what a click does.
	public bool Activate()
	{
		if (mDragActive && mDragFromKeyboard)
		{
			// The pad's South while dragging from the keys: dropped at the focus.
			QueryAtFocus();
			Drop();
			return true;
		}
		return (mFocusNode != null) && mFocusNode.IsTreeEnabled && mFocusNode.HandleActivate();
	}

	public bool InjectKeyUp(uint32 keyCode, uint32 modifiers = 0)
	{
		if ((keyCode == (uint32)KeyCode.LeftAlt) || (keyCode == (uint32)KeyCode.RightAlt))
			SetAltHeld(false);
		if (mCapture.Waiting)
		{
			// A modifier released with nothing pressed after it: the modifier key itself.
			if (mCapture.PendingModifier == keyCode)
				TakeCapturedKey(.(keyCode, modifiers & ~ModifierOfKey((KeyCode)keyCode), false));
			return true;
		}
		if (mDragActive && !mDragFromKeyboard)
		{
			if (modifiers != mDragModifiers)
			{
				mDragModifiers = modifiers;
				QueryDrop(mMousePos);
			}
			return true;
		}
		return RouteKey(.KeyUp, keyCode, modifiers);
	}

	public bool InjectText(StringView text)
	{
		if (mCapture.Waiting || mCapture.DropText)
		{
			mCapture.DropText = false; // a captured key's text
			return true;
		}
		let target = KeyTarget();
		if (target == null)
			return false;
		let e = scope TextInputEvent(target, text);
		return target.RouteEvent(e);
	}

	/// An IME's composition so far (empty: it ended), to the focused node, which shows it in place;
	/// the committed text follows as InjectText. `cursor` is in characters.
	public bool InjectComposition(StringView text, int32 cursor = 0)
	{
		let target = KeyTarget();
		if (target == null)
			return false;
		let e = scope CompositionEvent(target, text, cursor);
		return target.RouteEvent(e);
	}

	/// Where the focused node has text typed, in input space (as positions are injected), and the
	/// caret's x there: where a host's IME shows its candidates. False when it types none.
	public bool GetTextInputArea(out Rect outArea, out float outCaretX)
	{
		outArea = .();
		outCaretX = 0.0f;
		if ((mFocusNode == null) || !mFocusNode.WantsTextInput)
			return false;
		if (!mFocusNode.GetTextInputArea(let local, let localCaret))
			return false;
		let a = mFocusNode.ConvertToWorldSpace(.(local.X, local.Y));
		let b = mFocusNode.ConvertToWorldSpace(.(local.X + local.Width, local.Y + local.Height));
		let c = mFocusNode.ConvertToWorldSpace(.(localCaret, local.Y));
		outArea = .(Math.Min(a.X, b.X), Math.Min(a.Y, b.Y), Abs(b.X - a.X), Abs(b.Y - a.Y));
		outCaretX = c.X - outArea.X;
		return true;
	}

	// === Pointer capture ===

	/// Sends the pointer's moves and its release to `node` wherever the pointer goes, until
	/// released or the press ends (a press captures the pressed node on its own). A node that
	/// loses the capture (released, taken by another, or leaving the tree) is told
	/// (PointerCaptureLost).
	public void CapturePointer(Node node)
	{
		if (mCaptureNode == node)
			return;
		let previous = mCaptureNode;
		mCaptureNode = node;
		if (previous != null)
			SendCaptureLost(previous);
	}

	public void ReleasePointer(Node node)
	{
		if (mCaptureNode != node)
			return;
		mCaptureNode = null;
		SendCaptureLost(node);
	}

	public Node PointerCapture => mCaptureNode;
	/// Seconds of its clock (Tick advances it): what click counting and type-ahead read.
	public float Time => mTime;

	/// The pointer's look now: the nearest set `cursor` up from the node under the pointer (from
	/// the captured node while one holds the pointer, so a drag keeps its look), else Default. The
	/// host shows it (the shell bridge does).
	public Sedulous.GUI.Cursor Cursor
	{
		get
		{
			if (mDragActive) // a drag shows what a drop would do
				return (mDropEffect == .Copy) ? .Copy : (mDropEffect == .Link) ? .Alias : (mDropEffect == .Move) ? .Move : .NoDrop;
			if (mInputKind == .Pad)
				return .None; // a pad in use: the pointer is not
			let from = (mCaptureNode != null) ? mCaptureNode : (mDownNode != null) ? mDownNode : mOverNode;
			for (var n = from; n != null; n = n.Parent)
			{
				let cursor = n.CursorNow;
				if (cursor != .Auto)
					return cursor;
			}
			return .Default;
		}
	}

	/// Whether a pointer at `position` (device pixels) is over the GUI: over a node that takes the
	/// pointer (Node.TakesPointer), not only over a layout container. A game host asks before
	/// treating a click as its own.
	public bool IsPointerOver(Float2 position) => IsPointerTaken(HitTest(position));
	/// What the pointer at `position` reaches, as input finds it: an open popup's first (a menu, a
	/// dialog), then the root's; null under a modal popup, where everything is inert.
	public Node NodeAt(Float2 position) => HitTest(position);

	// === Focus ===

	/// A focused node no longer shown (it or a node above it hidden, or out of the layout) gives
	/// the focus up, as a removed one does: the keys go to its scope then, never to what cannot be
	/// seen (a screen's button left focused as the screen hides is not pressed by Return). Run each
	/// tick and before a key or a pad button.
	public void DropHiddenFocus()
	{
		if ((mFocusNode != null) && !mFocusNode.IsTreeVisible)
			FocusNode = null;
	}

	/// Asks for focus on `node` (or its entry) once the next style pass has run: it cannot take
	/// focus now, most often because a class that hid it was just taken off and the sheet has not
	/// applied yet. One request waits at a time; the latest wins. BORROWED.
	public void RequestFocusAfterStyle(Node node)
	{
		mPendingFocus = node;
	}

	/// The focus waiting for the next style pass, or null.
	public Node PendingFocus => mPendingFocus;

	/// Grants the waiting request, at the end of a style pass: its node, or the entry inside it,
	/// takes focus if it can now; if it still cannot, the request is dropped, never kept for a
	/// later frame that shows the node for some other reason.
	public void GrantPendingFocus()
	{
		let waiting = mPendingFocus;
		mPendingFocus = null;
		if (waiting == null)
			return;
		if (let target = FocusTargetOf(waiting))
			FocusNode = target;
	}

	/// The focused node. Set, focus moves there (null: nowhere); what leaves or is inert takes no
	/// focus.
	public Node FocusNode
	{
		get => mFocusNode;
		set
		{
			if (value != null)
				mPendingFocus = null; // a focus given now outranks one still waiting for the sheet
			if ((value == mFocusNode) || ((value != null) && value.IsTreeInert))
				return;
			let previous = mFocusNode;
			mFocusNode = value;
			mFocusChanged.Notify(); // the focus path: which commands are available
			if (previous != null)
				previous.HandleFocusLost();
			if (mFocusNode != null)
			{
				RememberInScopes(mFocusNode); // coming back to a scope returns here
				mFocusNode.FocusVisible = mInputKind != .Pointer;
				mFocusNode.HandleFocusGained();
				// Scrollers around it bring it into view: those inside the popup it is in, not the
				// ones its owner sits in (a popup is placed in the root's space, not scrolled with
				// them: a page scrolled to a menu opened in it, a little further each time it
				// opened).
				for (var n = mFocusNode; (n != null) && !n.InTopLayer; n = n.Parent)
				{
					let p = n.Parent;
					if (p != null)
						p.OnDescendantFocused(mFocusNode);
				}
			}
			if (mDragActive && mDragFromKeyboard)
				QueryAtFocus(); // a keyboard drag asks where the focus went
		}
	}

	// === Drag and drop ===
	// A left press (a finger's after a long press) that moves past the threshold offers a drag up
	// from the pressed node (DragRequest); the first source that fills it starts it, a node owning
	// its press ends the walk. While it goes, each move, modifier change and scroll asks the node
	// under the pointer and up its ancestors what a drop would do (DropQuery): the first that takes
	// it is the target, the cursor and the preview show the effect, and a reason shows by the
	// pointer. A release over the target drops; Escape, a right press, the pad's East or the source
	// leaving the tree cancels; the source is told how it ended.

	/// How far a press moves before it drags, in DIPs (scaled by the display; Godot's is 10,
	/// Zero's 6).
	public float DragThreshold
	{
		get => mDragThreshold;
		set => mDragThreshold = Math.Max(0.0f, value);
	}

	/// Starts a drag from code (Godot's force_drag): `source` gives no request itself. The request
	/// stays the caller's; the drag copies its payload, holds its preview and takes its Follow.
	public void StartDrag(Node source, DragRequest request)
	{
		BeginDrag(source, request, mMousePos);
	}

	public bool IsDragging => mDragActive;

	/// Where the GUI's roots are on the screen (its GUIContext's, set by the host); null: this
	/// root alone, a drag past its edge outside. Borrowed.
	public IRootPlaces RootPlaces
	{
		get => mRootPlaces;
		set => mRootPlaces = value;
	}

	/// The dispatcher whose root a drag from here is over now (its own, or another root's of the
	/// GUI); null while it is over none (outside every root) or no drag goes.
	public EventDispatcher DragOver => (mDragActive && !mDragOutside) ? mDragOver : null;

	/// Another root of the GUI goes: a drag from here over it is over none until it moves, and
	/// forgets the target and the layer it had there.
	public void ForgetRoot(EventDispatcher gone)
	{
		if (gone == this)
			return;
		if (mDragOver == gone)
		{
			mDragOver = this;
			mDragOutside = true;
			if ((mDropTarget != null) && (mDropTarget.RootNode == gone.mRoot))
				mDropTarget = null; // its tree goes with it: nothing to tell
		}
		if (mDragLayerIn == gone)
			mDragLayerIn = null;
	}

	public Sedulous.GUI.DragPayload DragPayload => mDragPayload;
	public Node DragSource => mDragSource;
	public Node DropTarget => mDropTarget;
	/// The effect a drop would have now, and the target's reason (or a refusal's).
	public Sedulous.GUI.DropEffect DropEffect => mDropEffect;
	public StringView DropReason => mDropReason;
	/// The preview following the pointer, and the hint beside it (null while none shows).
	public Node DragPreview => mDragPreview;
	public Node DropHint => mDropHint;

	public void CancelDrag()
	{
		if (mDragActive)
			FinishDrag(.None, null, true);
	}

	/// How deep the band at a scroller's edge is that scrolls it while a drag is near it, and how
	/// fast it scrolls at its edge (it ramps up with depth).
	public void SetDragScrollBand(float band, float speed = 900.0f)
	{
		mDragScrollBand = Math.Max(1.0f, band);
		mDragScrollSpeed = Math.Max(0.0f, speed);
	}

	/// How long a drag rests on a node before it opens (a tree node, an expander, a tab).
	public float DragHoverOpenDelay
	{
		get => mDragHoverOpenDelay;
		set => mDragHoverOpenDelay = Math.Max(0.0f, value);
	}

	/// Files the OS dropped at `position` (the same path as a drag): a `files` payload (its value
	/// the paths, copied, kept by the dispatcher until the next file drop) asked of the node there
	/// and up, and dropped on the one that takes it; none taking it, the GUI's own handler has
	/// them. True when something took them. (The OS gives no hover: nothing shows while a file is
	/// dragged over.)
	public bool InjectFileDrop(Float2 position, Span<StringView> paths)
	{
		if (paths.IsEmpty)
			return false;
		if (mDragActive)
			CancelDrag();
		NoteInput();
		EventDispatcherDetail.ClearVariants(mDroppedFiles);
		for (let path in paths)
			mDroppedFiles.Add(TextVariant(path));
		delete mDragPayload;
		mDragPayload = new .();
		mDragPayload.Type.Set("files");
		mDragPayload.Value = System.Variant.Create(mDroppedFiles);
		if (paths.Length == 1)
			mDragPayload.Label.Set(paths[0]);
		else
			mDragPayload.Label.AppendF("{} files", paths.Length);
		mDragPayload.Allowed = DropEffectsCopy;
		mDragActive = true;
		mDragSource = null;
		mDragModifiers = 0;
		QueryDrop(position);
		let taken = (mDropTarget != null) && (mDropEffect != .None);
		Drop();
		if (!taken && (mOnFileDrop != null))
			return mOnFileDrop(paths, RootPoint(position));
		return taken;
	}

	/// What has the files no node takes (the GUI's own handler: an import, an open). OWNERSHIP of
	/// `handler` transfers.
	public void SetOnFileDrop(delegate bool(Span<StringView> paths, Float2 at) handler)
	{
		delete mOnFileDrop;
		mOnFileDrop = handler;
	}

	/// `drag.pick` (Godot's accessibility drag): the focused node, or one above it, starts a drag
	/// of what it would drag; the focus then moves as ever (the arrows, Tab, the pad), each node
	/// it reaches asked as the pointer would ask it, and `drag.drop` (Return, Space, the pad's
	/// South) drops at the focus; Escape (East) cancels.
	public bool PickDrag()
	{
		if (mDragActive)
			CancelDrag();
		for (var n = mFocusNode; n != null; n = n.Parent)
		{
			if (!n.IsTreeEnabled)
				return false;
			let request = scope DragRequest();
			request.Press = .(n.Size.X * 0.5f, n.Size.Y * 0.5f);
			request.FromKeyboard = true;
			if (n.HandleDragRequested(request))
			{
				request.FromKeyboard = true;
				UseKeyboard();
				mDragModifiers = 0;
				BeginDrag(n, request, FocusPoint());
				return true;
			}
		}
		return false;
	}

	/// A drag from the keys or the pad is going (the focus is what is asked).
	public bool IsKeyboardDrag => mDragActive && mDragFromKeyboard;

	/// Asks the target again where the pointer is (the content moved under a still pointer).
	public void RequeryDrag()
	{
		if (mDragFromKeyboard)
			QueryAtFocus();
		else if (mDragActive)
			QueryDrop(mMousePos);
	}

	// === Popups: the top layer ===
	// A popup stays in its owner's subtree (its styles, its events' route) and is promoted into
	// this root's top layer while open: drawn after the whole tree in opening order, unclipped,
	// hit-tested first, placed against its anchor every layout pass, entering (`:entering`) each
	// time it opens. Opening an auto popup closes the open ones that do not hold its owner (nesting
	// comes from the tree); closing one closes those it holds. A closed popup leaves the tree (its
	// owner keeps it).

	/// Opens `popup` as a child of `owner` (attached there if it is not yet). OWNERSHIP of
	/// `options` transfers (deleted at once when the popup is open already).
	public void OpenPopup(Node owner, Node popup, PopupOptions options)
	{
		if (FindPopup(popup) >= 0)
		{
			delete options;
			return;
		}
		// Opened again while its exit plays: whole again, its exit and going forgotten. Held to the
		// end: the tree and the leaving entry may have held its only references.
		Node held = null;
		defer { if (held != null) held.ReleaseRef(); }
		for (int i = mLeaving.Count - 1; i >= 0; i--)
		{
			let leaving = mLeaving[i];
			if (leaving.Popup != popup)
				continue;
			if (held == null)
			{
				popup.AddRef();
				held = popup;
			}
			popup.InTopLayer = false;
			popup.RemoveFromParent(); // ends its leaving
			let home = (leaving.Home.Table != null) ? leaving.Home.Table.Resolve(leaving.Home.Slot, leaving.Home.Generation) : null;
			if (home != null)
				home.AddChildAt(popup, Math.Min(leaving.HomeIndex, home.ChildCount));
			mLeaving.RemoveAt(i);
			delete leaving;
		}
		if (options.Kind != .Manual)
		{
			// An auto popup closes the popups that do not hold its owner (a hint, the other hints).
			for (int i = mPopups.Count - 1; i >= 0; i--)
			{
				if (i >= mPopups.Count)
					continue; // closed with one above it
				let e = mPopups[i];
				if (e.Options.Modal || (e.Options.Kind == .Manual))
					break; // what is below a dialog stays as it is
				let closes = (options.Kind == .Hint) ? (e.Options.Kind == .Hint) : !IsInSubtree(owner, e.Popup);
				if (closes)
					ClosePopupAt(i, .Replaced);
			}
		}
		let entry = new PopupEntry();
		if (options.ReturnHome && (popup.Parent != null))
		{
			entry.Home = popup.Parent.TakeElementRef();
			entry.HomeIndex = popup.Parent.GetChildIndex(popup);
		}
		if (popup.Parent != owner)
		{
			// Held across the move: its old parent may hold the only reference (a dialog written
			// in a page).
			popup.AddRef();
			popup.RemoveFromParent();
			owner.AddChild(popup);
			popup.ReleaseRef();
		}
		popup.AddRef();
		entry.Popup = popup;
		entry.Size = popup.Size;
		let focusing = (options.TakesFocus || options.Modal) && (options.Kind != .Hint);
		if (focusing)
		{
			// The focus it takes, and the nodes holding it: given back on close to the first that
			// is still there.
			for (var n = mFocusNode; n != null; n = n.Parent)
				entry.SavedFocus.Add(n.TakeElementRef());
			entry.ScopeBefore = popup.NavScope;
			if (popup.NavScope == .None)
				popup.NavScope = .Contain;
		}
		entry.Options = options;
		popup.InTopLayer = true;
		popup.RouteStop = options.Modal;
		mPopups.Add(entry);
		PlacePopups();
		popup.Enter(); // the sheet's entrance plays (`:entering`), each time it opens
		if (focusing)
		{
			let stops = scope List<Node>();
			CollectTabStops(popup, stops);
			FocusNode = !stops.IsEmpty ? stops[0] : (popup.TabFocusable ? popup : null);
		}
		// Told after focus moved in, so a listener may move it on (a dialog's default button).
		let opened = scope ToggleEvent(popup, true, .Code);
		popup.RouteEvent(opened);
	}

	/// Closes `popup` and the popups it holds. False when it is not open.
	public bool ClosePopup(Node popup, PopupCloseReason reason = .Code)
	{
		let index = FindPopup(popup);
		if (index < 0)
			return false;
		ClosePopupAt(index, reason);
		return true;
	}

	public void CloseAllPopups(PopupCloseReason reason = .Code)
	{
		while (!mPopups.IsEmpty)
			ClosePopupAt(0, reason);
	}

	/// Input went to another root of the GUI (another window): its auto popups and hints close, as
	/// a press outside them would close them (what is below a dialog stays).
	public void CloseLightPopups(PopupCloseReason reason = .OutsidePress)
	{
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			if (i >= mPopups.Count)
				continue;
			if (mPopups[i].Options.Kind == .Manual)
				break;
			ClosePopupAt(i, reason);
		}
	}

	public bool IsPopupOpen(Node popup) => FindPopup(popup) >= 0;

	/// Closes the topmost auto popup, not past a dialog (a manual popup answers for itself); false
	/// when none is open there. The `back` command's first answer.
	public bool CloseTopAutoPopup(PopupCloseReason reason)
	{
		let top = TopAutoPopup();
		if (top < 0)
			return false;
		ClosePopupAt(top, reason);
		return true;
	}

	public bool HasTopAutoPopup => TopAutoPopup() >= 0;
	public int PopupCount => mPopups.Count;
	/// The open popups, bottom first.
	public Node PopupAt(int index) => ((index >= 0) && (index < mPopups.Count)) ? mPopups[index].Popup : null;
	/// Borrowed.
	public PopupOptions PopupOptionsAt(int index) => ((index >= 0) && (index < mPopups.Count)) ? mPopups[index].Options : null;
	public Node TopPopup => mPopups.IsEmpty ? null : mPopups.Back.Popup;

	/// Places every anchored popup against its anchor within the root: on its side, flipped,
	/// shrunk and clamped (PlacePopup), a centred one in the root's middle. Run every layout pass
	/// and before drawing, so a popup follows its anchor.
	public void PlacePopups()
	{
		if (mRoot == null)
			return;
		let bounds = Rect(0.0f, 0.0f, mRoot.Size.X, mRoot.Size.Y);
		for (int i = 0; i < mPopups.Count; i++)
		{
			let e = mPopups[i];
			Rect anchor = .();
			var placement = e.Options.Placement;
			if (e.Options.Centered)
			{
				// Below a line across the root as far down as half the room it leaves, centred
				// along it: in the middle both ways.
				if (e.Options.FitContent)
					e.Size = e.Popup.Measure(LayoutConstraints());
				anchor = .(0.0f, Math.Max(0.0f, (bounds.Height - e.Size.Y) * 0.5f), bounds.Width, 0.0f);
				placement.Side = .Below;
				placement.Align = .Center;
				placement.Gap = 0.0f;
				placement.Shift = 0.0f;
			}
			else if (e.Options.Anchor != null)
			{
				let a = e.Options.Anchor;
				let p0 = a.ConvertToRootSpace(.(0.0f, 0.0f));
				let p1 = a.ConvertToRootSpace(a.Size);
				anchor = .(Math.Min(p0.X, p1.X), Math.Min(p0.Y, p1.Y), Abs(p1.X - p0.X), Abs(p1.Y - p0.Y));
			}
			else if (e.Options.HasAnchorRect)
				anchor = e.Options.AnchorRect;
			else
				continue;
			let popup = e.Popup;
			if (e.Options.FitContent && !e.Options.Centered)
				e.Size = popup.Measure(LayoutConstraints());
			// Its sides and alignment in the anchor's direction, else its own (its owner's).
			let rightToLeft = ((e.Options.Anchor != null) && !e.Options.Centered) ? e.Options.Anchor.IsRightToLeft : popup.IsRightToLeft;
			if (placement.AlignContent)
			{
				// By its content's edge, its padding and border as styled now (not when it opened).
				let chrome = popup.Chrome;
				let along = (placement.Side == .Below) || (placement.Side == .Above);
				placement.Shift -= along ? (rightToLeft ? chrome.Right : chrome.Left) : chrome.Top;
			}
			var placed = PlacePopup(anchor, e.Size, bounds, placement, rightToLeft);
			// On the device grid, as its arrange puts it, so the two agree: its near edge down and
			// its far edge up, so the grid never makes it smaller than it measured (a menu a
			// fraction short of its rows would scroll).
			let scale = Math.Max(popup.PixelScale, 0.01f);
			placed.Size = .(EventDispatcherDetail.SnapFar(placed.Position.X + placed.Size.X, scale) - EventDispatcherDetail.SnapNear(placed.Position.X, scale),
				EventDispatcherDetail.SnapFar(placed.Position.Y + placed.Size.Y, scale) - EventDispatcherDetail.SnapNear(placed.Position.Y, scale));
			placed.Position = .(EventDispatcherDetail.SnapNear(placed.Position.X, scale), EventDispatcherDetail.SnapNear(placed.Position.Y, scale));
			if (e.Options.FitContent)
			{
				// Sized by what it holds: arranged, its style left auto, so the next measure follows
				// its content (a tooltip whose font arrives after it opened).
				popup.Arrange(.(placed.Position.X, placed.Position.Y, placed.Size.X, placed.Size.Y));
				continue;
			}
			using (Node.StyleWriteScope(popup)) // the layer's, not code's: no pins
			{
				if ((placed.Position.X != popup.Position.X) || (placed.Position.Y != popup.Position.Y))
					popup.Position = placed.Position;
				if ((placed.Size.X != popup.Size.X) || (placed.Size.Y != popup.Size.Y))
					popup.Size = placed.Size;
			}
		}
	}

	/// A popup's size changed from code while it is open (a list grew): placed from it again.
	public void SetPopupSize(Node popup, Float2 size)
	{
		let index = FindPopup(popup);
		if (index < 0)
		{
			popup.Size = size;
			return;
		}
		mPopups[index].Size = size;
		popup.Size = size;
		PlacePopups();
	}

	/// The rectangle (root space) an open popup is placed against moved (a code editor's caret,
	/// scrolled or typed on): placed against it from now on. False when it is not open.
	public bool SetPopupAnchorRect(Node popup, Rect anchor)
	{
		let index = FindPopup(popup);
		if (index < 0)
			return false;
		let options = mPopups[index].Options;
		options.Anchor = null;
		options.AnchorRect = anchor;
		options.HasAnchorRect = true;
		PlacePopups();
		return true;
	}

	/// Draws the top layer (the root's draw does, after its tree): each popup in opening order, a
	/// modal one over its backdrop (its `::backdrop` part, over a dim of the whole root).
	public void DrawPopups(DrawContext ctx)
	{
		PlacePopups();
		// Those playing their exit first, under the open ones (a dialog fading out, a menu opened
		// since over it).
		for (let leaving in mLeaving)
		{
			let popup = leaving.Popup;
			if (popup.Parent == null)
				continue;
			if (leaving.Modal && (mRoot != null))
				popup.DrawBackdrop(ctx, Rect(0.0f, 0.0f, mRoot.Size.X, mRoot.Size.Y));
			popup.Draw(ctx);
		}
		for (int i = 0; i < mPopups.Count; i++)
		{
			let popup = mPopups[i].Popup; // held: drawing changes nothing, but be sure
			popup.AddRef();
			defer popup.ReleaseRef();
			if (mPopups[i].Options.Modal && (mRoot != null))
			{
				let all = Rect(0.0f, 0.0f, mRoot.Size.X, mRoot.Size.Y);
				popup.DrawBackdrop(ctx, all);
			}
			popup.Draw(ctx);
		}
	}

	/// Whether `node` takes input now: everything while no modal popup is open, else what is in
	/// the topmost modal one or above it.
	public bool IsInputLive(Node node) => IsLive(node);

	/// Where focus, Tab and the arrows stay: the topmost popup taking focus, else the root.
	public Node FocusScopeRoot
	{
		get
		{
			for (int i = mPopups.Count - 1; i >= 0; i--)
			{
				let o = mPopups[i].Options;
				if ((o.TakesFocus || o.Modal) && (o.Kind != .Hint))
					return mPopups[i].Popup;
			}
			return mRoot;
		}
	}

	/// The topmost popup under a world point, and in it the node there (hints pass the pointer
	/// through); null when the point is in none.
	public Node FindInPopups(Float2 worldPoint)
	{
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			if ((mPopups[i].Options.Kind != .Hint) && !mPopups[i].Options.PassesPointer)
			{
				let hit = mPopups[i].Popup.OverFind(worldPoint);
				if (hit != null)
					return hit;
			}
		}
		return null;
	}

	// === Tab navigation ===
	// Move focus to the next / previous tab-focusable node in tree pre-order (visible + enabled),
	// wrapping around. Returns true if focus moved. With nothing focused, Next targets the first
	// stop and Previous the last.

	public bool FocusNext()
	{
		UseKeyboard();
		return MoveTabFocus(1);
	}

	public bool FocusPrevious()
	{
		UseKeyboard();
		return MoveTabFocus(-1);
	}

	// === A held direction ===
	// A gamepad's d-pad or stick held in a direction: a step at once, then, after a delay, again
	// and again, faster the longer it is held. Each step reaches the focused widget as an arrow key
	// does, so a slider moves its value and a list its selection, and only what it leaves moves
	// focus. (A keyboard's held arrow repeats by the system's own key repeat.) The GUI's update
	// (GUIContext.Update) ticks it.

	public void PressDirection(NavDirection direction)
	{
		if (PadCaptured)
			return;
		NoteInput();
		ApplyInputKind(.Pad);
		mHolding = true;
		mHeldDirection = direction;
		mHeldFor = 0.0f;
		mNextRepeatAt = cRepeatDelay;
		StepDirection(direction);
	}

	public void ReleaseDirection(NavDirection direction)
	{
		if (mHolding && (mHeldDirection == direction))
			mHolding = false;
	}

	public bool IsHoldingDirection => mHolding;

	/// A pad's right stick, each axis -1 to 1 (down and right positive): while it is pushed past
	/// its dead zone, Tick scrolls the nearest scroller around the focus (or, with no focus, under
	/// the pointer), faster the further it is pushed.
	public Float2 ScrollStick
	{
		get => mScrollStick;
		set => mScrollStick = PadCaptured ? Float2(0.0f, 0.0f) : value;
	}

	/// A focus that captures every key (a game in a panel) takes the gamepad too: it reads the pad
	/// itself, and the GUI neither moves focus, activates nor scrolls by it meanwhile.
	public bool PadCaptured => (mFocusNode != null) && mFocusNode.CapturesAllKeys;

	public void Tick(float seconds)
	{
		mTime += seconds; // the clock click counting, tooltips and long presses read
		SettleLeavingPopups();
		DropHiddenFocus();
		if (mDragActive)
			TickDrag(seconds);
		UpdateTooltip(seconds);
		ScrollByStick(seconds);
		if (mLongPressArmed && mTouchActive)
		{
			mPressHeld += seconds;
			if (mPressHeld >= cLongPress)
				LongPress();
		}
		if (mHolding && PadCaptured)
			mHolding = false; // held as the game took the focus: no further step is the GUI's
		if (!mHolding)
			return;
		mHeldFor += seconds;
		for (int32 guard = 0; (guard < 8) && (mHeldFor >= mNextRepeatAt); guard++)
		{
			StepDirection(mHeldDirection);
			// From the first interval down to the fastest, over the time held past the delay.
			let ramp = Math.Min(1.0f, (mHeldFor - cRepeatDelay) / cRepeatRampTime);
			mNextRepeatAt += cRepeatSlowest + (cRepeatFastest - cRepeatSlowest) * ramp;
		}
	}

	/// One step of a held direction, as an arrow key takes it: the focused widget first (a slider
	/// steps its value, a list its selection), navigation with what it leaves.
	public void StepDirection(NavDirection direction)
	{
		UseKeyboard();
		let key = (direction == .Up) ? KeyCode.Up
			: (direction == .Down) ? KeyCode.Down
			: (direction == .Left) ? KeyCode.Left
			: KeyCode.Right;
		if (!RouteKey(.KeyDown, (uint32)key, 0))
			MoveFocus(direction);
	}

	/// A subtree is leaving the tree (Node.RemoveChild tells the dispatcher before it detaches):
	/// every ref into it is dropped, since the tree no longer keeps those nodes alive. A sort that
	/// rebuilds a table's header frees the hovered header cell, and the next mouse move would
	/// otherwise leave a freed node. A popup inside it is simply gone; a popup whose opener leaves
	/// is dismissed while the opener still lives.
	public void NotifySubtreeRemoved(Node removed)
	{
		// Popups leaving with the subtree (their owner went): dropped, topmost first, focus given
		// back to what they took it from when that stays.
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			if ((i < mPopups.Count) && IsInSubtree(mPopups[i].Popup, removed))
				DropPopupAt(i, .OwnerRemoved, removed);
		}
		if (IsInSubtree(mTipProvider, removed))
			mTipProvider = null;
		PrunePath(mHoverPath, removed, true);
		mOverNode = mHoverPath.IsEmpty ? null : mHoverPath[mHoverPath.Count - 1];
		PrunePath(mPressPath, removed, false);
		if (IsInSubtree(mDownNode, removed))
			mDownNode = null;
		if (IsInSubtree(mPanScroller, removed))
			mPanScroller = null; // the finger pans nothing now
		if (IsInSubtree(mCaptureNode, removed))
		{
			let lost = mCaptureNode;
			mCaptureNode = null;
			SendCaptureLost(lost); // told while it still lives
		}
		if (IsInSubtree(mFocusNode, removed))
			FocusNode = null;
		if (IsInSubtree(mPendingFocus, removed))
			mPendingFocus = null;
		if (IsInSubtree(mDropTarget, removed))
			mDropTarget = null;
		if (IsInSubtree(mDragSource, removed))
		{
			mDragSource = null; // gone: it is told nothing
			CancelDrag();
		}
	}

	private Node HitTest(Float2 position)
	{
		// Input sees the layout as it is now: a layout still waiting for the frame's pass runs
		// first (nothing to do when none waits).
		for (int32 round = 0; (mRoot != null) && (round < 8) && (mRoot.IsLayoutDirty || mRoot.HasLayoutDirtyDescendant); round++)
			mRoot.ArrangeAgain();
		PlacePopups();
		var hit = FindInPopups(position);
		if ((hit == null) && (mRoot != null))
			hit = mRoot.OverFind(position);
		// Below the topmost modal popup everything is inert: a hit there is swallowed.
		if (!IsLive(hit))
			return null;
		return hit;
	}

	private bool PointerMove(Float2 position, PointerType pointer, uint64 id, uint32 modifiers = 0)
	{
		mMousePos = position;
		if (mLongPressArmed && (Abs(position.X - mPressAt.X) + Abs(position.Y - mPressAt.Y) > Dips(cTapSlop)))
			mLongPressArmed = false; // the finger moved: a drag or a scroll, not a long press
		// A drag in progress: the pointer only asks where a drop would land.
		if (mDragActive)
		{
			mDragModifiers = modifiers;
			QueryDrop(position);
			return true;
		}
		// A press moved past the threshold: a drag, if a source up from the pressed node gives one.
		if ((mDownNode != null) && !mDragTried && ((pointer == .Mouse) || mTouchDragArmed) &&
			(Abs(position.X - mPressAt.X) + Abs(position.Y - mPressAt.Y) > Dips(mDragThreshold)))
		{
			if (TryDrag(position, modifiers, pointer))
				return true;
		}
		let hit = HitTest(position);
		UpdateHoverPath(hit, position);
		// The captured node (explicitly, or the pressed one while a button is held) keeps the
		// moves, so a drag goes on when the pointer leaves it; otherwise the hovered node.
		let target = PointerTarget(hit);
		bool used = false;
		if ((target != null) && target.IsTreeEnabled)
		{
			let e = scope MouseEvent(.MouseMove, target, position, .Left, modifiers);
			e.Pointer = pointer;
			e.PointerId = id;
			used = target.RouteEvent(e);
		}
		return used || IsPointerTaken(hit);
	}

	private bool PointerDown(Float2 position, MouseButton button, uint32 modifiers, PointerType pointer, uint64 id)
	{
		NoteInput();
		// A pointer in use: the focus ring hides (shown again by the next key or d-pad move).
		ApplyInputKind(.Pointer);
		mKeysMovedFocus = false; // the focus's tooltip waits for the keys again
		mMousePos = position;
		if (mDragActive)
		{
			// A second press while dragging (a right one, as Godot): cancelled, the press eaten.
			CancelDrag();
			mSwallowing = true;
			return true;
		}
		mDragTried = button != .Left; // only a left press (a finger's) drags
		mTouchDragArmed = false;
		let hit = HitTest(position);
		UpdateHoverPath(hit, position);
		// Any press hides a tooltip. A press closes the auto popups above the one it is in; one in
		// no popup is consumed with the rest of its gesture: closing a menu never acts on what lies
		// under it, and the opener pressed again closes without reopening.
		ClosePopupsOfKind(.Hint, .OutsidePress);
		if (DismissOutside(hit))
		{
			mSwallowing = true;
			mDownNode = null;
			return true;
		}
		CountClick(position, button, pointer);
		mLongPressArmed = (pointer == .Touch) && (hit != null);
		mPressHeld = 0.0f;
		mPressAt = position;
		mDownNode = hit;
		mClickSuppressed = false;
		SetPressPath(hit);
		// Click-to-focus: the nearest widget that takes focus, at or above what was hit; none (a
		// click on a backdrop or a label) clears focus, as browsers do, so navigation starts again
		// from the GUI's entry rather than from the backdrop. A node that keeps the focus, met
		// first, leaves it where it is (a completion list's row).
		var focusable = hit;
		bool keep = false;
		while ((focusable != null) && !(focusable.TabFocusable && focusable.IsTreeEnabled))
		{
			if (focusable.KeepsFocus)
			{
				keep = true;
				break;
			}
			focusable = focusable.Parent;
		}
		if (!keep)
			FocusNode = focusable;
		// A disabled widget still takes the press (nothing behind it does) but is not told.
		bool used = false;
		if ((hit != null) && hit.IsTreeEnabled)
		{
			let e = scope MouseEvent(.MouseDown, hit, position, button, modifiers);
			e.ClickCount = mClickCount;
			e.Pointer = pointer;
			e.PointerId = id;
			used = hit.RouteEvent(e);
		}
		return used || IsPointerTaken(hit);
	}

	private bool PointerUp(Float2 position, MouseButton button, uint32 modifiers, PointerType pointer, uint64 id)
	{
		mMousePos = position;
		mLongPressArmed = false;
		if (mSwallowing)
		{
			mSwallowing = false; // the end of a press that closed a popup: nothing more of it
			return true;
		}
		// A release while dragging drops on the target, if one takes it (asked once more where it
		// is), and ends the drag; the press was cancelled when it began.
		if (mDragActive)
		{
			mDragModifiers = modifiers;
			QueryDrop(position);
			Drop();
			return true;
		}
		let hit = HitTest(position);
		// The nodes are held for the rest of this call: a handler may mutate the tree (a header
		// click re-sorts a model and the view rebuilds its header cells), dropping the last owning
		// reference to the very node still on the call stack.
		let target = PointerTarget(hit); // the captured or pressed node gets the release
		let down = mDownNode;
		EventDispatcherDetail.Hold(hit);
		EventDispatcherDetail.Hold(target);
		EventDispatcherDetail.Hold(down);
		defer
		{
			EventDispatcherDetail.Let(down);
			EventDispatcherDetail.Let(target);
			EventDispatcherDetail.Let(hit);
		}
		bool used = false;
		if ((target != null) && target.IsTreeEnabled)
		{
			let e = scope MouseEvent(.MouseUp, target, position, button, modifiers);
			e.ClickCount = mClickCount;
			e.Pointer = pointer;
			e.PointerId = id;
			used = target.RouteEvent(e);
		}
		// A right release asks for a context menu where it was, from the node there up.
		if ((button == .Right) && (hit != null) && hit.IsTreeEnabled && IsInSubtree(hit, mRoot))
		{
			let menu = scope MouseEvent(.ContextMenu, hit, position, button, modifiers);
			menu.Pointer = pointer;
			used = hit.RouteEvent(menu) || used;
		}
		// A click (activation) for the left button only, on the nearest node holding both the
		// pressed node and the one released over (a press dragged onto a sibling clicks their
		// container, not either), as the DOM does. Right and middle presses still deliver down and
		// up (a context menu) but never activate a control. A cancelled press has no pressed node,
		// so no click.
		if ((button == .Left) && (mDownNode != null) && (hit != null) && !mClickSuppressed)
		{
			let clicked = CommonAncestor(mDownNode, hit);
			if ((clicked != null) && clicked.IsTreeEnabled)
			{
				let e = scope MouseEvent(.MouseClick, clicked, position, button, modifiers);
				e.ClickCount = mClickCount;
				e.Pointer = pointer;
				e.PointerId = id;
				used = clicked.RouteEvent(e) || used;
			}
		}
		mDownNode = null;
		ClearPressPath();
		if (mCaptureNode != null)
			ReleasePointer(mCaptureNode); // a capture ends with the press, as the DOM's does
		return used || IsPointerTaken(hit);
	}

	// The node a pointer move or release goes to: the captured node, else the pressed one while a
	// button is held, else the one under the pointer.
	private Node PointerTarget(Node hit) => (mCaptureNode != null) ? mCaptureNode : (mDownNode != null) ? mDownNode : hit;

	// Whether `hit`, or a node above it short of the root, takes the pointer.
	private bool IsPointerTaken(Node hit)
	{
		for (var n = hit; (n != null) && (n != mRoot); n = n.Parent)
		{
			if (n.TakesPointer)
				return true;
		}
		return false;
	}

	// Keys go to the focused widget, or, with nothing focused, to the root (its capture and bubble
	// listeners still hear them); a disabled one hears nothing.
	private Node KeyTarget()
	{
		var target = (mFocusNode != null) ? mFocusNode : mRoot;
		if (!IsLive(target))
			target = FocusScopeRoot; // below a modal: the keys are the modal's
		return ((target != null) && target.IsTreeEnabled) ? target : null;
	}

	private bool RouteKey(EventType type, uint32 keyCode, uint32 modifiers)
	{
		HitTest(.(0.0f, 0.0f)); // keys see the layout as it is now, as the pointer does
		let target = KeyTarget();
		if (target == null)
			return false;
		let e = scope KeyEvent(type, target, keyCode, modifiers);
		return target.RouteEvent(e);
	}

	// The nearest node holding both (each counting as holding itself); null in different trees.
	private static Node CommonAncestor(Node a, Node b)
	{
		for (var n = a; n != null; n = n.Parent)
		{
			if (IsInSubtree(b, n))
				return n;
		}
		return null;
	}

	// The hover path follows the node under the pointer: the nodes that leave it are told
	// (deepest first) and the nodes that join it (outermost first), each one on its own, and every
	// node on it reads as hovered, so `:hover` holds for a card while a button inside it is under
	// the pointer, as CSS has it.
	private void UpdateHoverPath(Node hit, Float2 position)
	{
		let path = scope List<Node>();
		for (var n = hit; n != null; n = n.Parent)
			path.Insert(0, n); // root first
		int common = 0;
		while ((common < mHoverPath.Count) && (common < path.Count) && (mHoverPath[common] == path[common]))
			common++;
		if ((common == mHoverPath.Count) && (common == path.Count))
			return;
		// Held while their handlers run: an enter or a leave may change the tree.
		let leaving = scope List<Node>();
		for (int i = mHoverPath.Count - 1; i >= common; i--)
		{
			mHoverPath[i].AddRef();
			leaving.Add(mHoverPath[i]);
		}
		let joining = scope List<Node>();
		for (int i = common; i < path.Count; i++)
		{
			path[i].AddRef();
			joining.Add(path[i]);
		}
		defer
		{
			for (let node in leaving)
				node.ReleaseRef();
			for (let node in joining)
				node.ReleaseRef();
		}
		mHoverPath.Clear();
		mHoverPath.AddRange(path);
		mOverNode = hit;
		for (let node in leaving)
		{
			node.Hovered = false;
			let e = scope MouseEvent(.MouseLeave, node, position);
			node.DeliverRouted(e);
		}
		for (let node in joining)
		{
			node.Hovered = true;
			let e = scope MouseEvent(.MouseEnter, node, position);
			node.DeliverRouted(e);
		}
	}

	// The press path: the pressed node and the nodes holding it read as pressed (`:active`) until
	// the release.
	private void SetPressPath(Node hit)
	{
		ClearPressPath();
		if ((hit == null) || !hit.IsTreeEnabled)
			return;
		for (var n = hit; n != null; n = n.Parent)
		{
			n.Pressed = true;
			mPressPath.Add(n);
		}
	}

	private void ClearPressPath()
	{
		let path = scope List<Node>();
		path.AddRange(mPressPath);
		mPressPath.Clear();
		for (let n in path)
			n.Pressed = false;
	}

	// Drops the part of a hover or press path inside a subtree that is leaving the tree.
	private static void PrunePath(List<Node> path, Node removed, bool hover)
	{
		for (int i = 0; i < path.Count; i++)
		{
			if (IsInSubtree(path[i], removed))
			{
				for (int j = i; j < path.Count; j++)
				{
					if (hover)
						path[j].Hovered = false;
					else
						path[j].Pressed = false;
				}
				path.RemoveRange(i, path.Count - i);
				return;
			}
		}
	}

	private void SendCaptureLost(Node node)
	{
		node.AddRef();
		defer node.ReleaseRef();
		let e = scope Event(.PointerCaptureLost, node);
		node.DeliverRouted(e);
	}

	// === Gestures === Two fingers down over a node whose touch-action leaves pinch-zoom out (the
	// node, or what holds both fingers' nodes) make one gesture from the moment the second lands:
	// the first finger's press is cancelled, and the node hears gesturestart, gesturechange as the
	// fingers move (scale, rotation and translation together, as Safari's and aui's), and
	// gestureend when one lifts. Over a node that leaves pinch-zoom to the GUI, a second finger
	// does nothing, as before.

	private bool BeginGesture()
	{
		if (mGesturing || (mFingers.Count != 2))
			return false;
		let target = CommonAncestor(HitTest(mFingers[0].Now), HitTest(mFingers[1].Now));
		if ((target == null) || ((target.EffectiveTouchActions & cTouchPinchZoom) != 0))
			return false;
		if (mTouchActive)
		{
			CancelPointer(); // the first finger's press: a gesture, not a tap
			mLongPressArmed = false;
			mTouchDragArmed = false;
			mPanning = false;
			mPanScroller = null;
			mTouchActive = false;
			UpdateHoverPath(null, mFingers[0].Now);
		}
		mGestureIds[0] = mFingers[0].Id;
		mGestureIds[1] = mFingers[1].Id;
		let a = mFingers[0].Now;
		let b = mFingers[1].Now;
		mGestureSpan0 = Math.Max(Distance(a, b), 1.0f);
		mGestureAngle = Atan2(b.Y - a.Y, b.X - a.X);
		mGestureFocus0 = .((a.X + b.X) * 0.5f, (a.Y + b.Y) * 0.5f);
		mGestureScale = 1.0f;
		mGestureRotation = 0.0f;
		mGestureTranslation = .(0.0f, 0.0f);
		mGesturePointer = .Touch;
		SetGestureTarget(target);
		mGesturing = true;
		RouteGesture(.GestureStart, 1.0f, 0.0f, .(0.0f, 0.0f));
		return true;
	}

	private bool IsGestureFinger(uint64 id) => (mGesturePointer == .Touch) && ((id == mGestureIds[0]) || (id == mGestureIds[1]));

	private void MoveGesture()
	{
		let ia = FindFinger(mGestureIds[0]);
		let ib = FindFinger(mGestureIds[1]);
		if ((ia < 0) || (ib < 0))
			return;
		if (mGestureTarget.RootNode != mRoot)
		{
			EndGesture(.GestureCancel); // its node left the tree
			return;
		}
		let a = mFingers[ia].Now;
		let b = mFingers[ib].Now;
		let scale = Math.Max(Distance(a, b), 1.0f) / mGestureSpan0;
		let angle = Atan2(b.Y - a.Y, b.X - a.X);
		var turned = angle - mGestureAngle; // the shorter way round: past a half turn it wraps
		if (turned > Pi)
			turned -= 2.0f * Pi;
		else if (turned < -Pi)
			turned += 2.0f * Pi;
		mGestureAngle = angle;
		let focus = Float2((a.X + b.X) * 0.5f, (a.Y + b.Y) * 0.5f);
		// In the GUI's units, as positions are: not the node's own, which its gesture may turn.
		let translation = InNodeUnits(mRoot, mGestureFocus0, .(focus.X - mGestureFocus0.X, focus.Y - mGestureFocus0.Y));
		let scaleDelta = scale / mGestureScale;
		let translationDelta = Float2(translation.X - mGestureTranslation.X, translation.Y - mGestureTranslation.Y);
		mGestureScale = scale;
		mGestureRotation += turned;
		mGestureTranslation = translation;
		RouteGesture(.GestureChange, scaleDelta, turned, translationDelta);
	}

	private void EndGesture(EventType type)
	{
		mGesturing = false;
		let target = mGestureTarget; // the gesture's reference, let go after
		mGestureTarget = null;
		defer
		{
			if (target != null)
				target.ReleaseRef();
		}
		if ((target != null) && (target.RootNode == mRoot))
		{
			let e = scope GestureEvent(type, target);
			e.Pointer = mGesturePointer;
			e.Focus = GestureFocus();
			e.Scale = mGestureScale;
			e.Rotation = mGestureRotation;
			e.Translation = mGestureTranslation;
			target.RouteEvent(e);
		}
	}

	private Float2 GestureFocus()
	{
		let ia = FindFinger(mGestureIds[0]);
		let ib = FindFinger(mGestureIds[1]);
		if ((ia < 0) || (ib < 0))
			return mGestureFocus0;
		let a = mFingers[ia].Now;
		let b = mFingers[ib].Now;
		return .((a.X + b.X) * 0.5f, (a.Y + b.Y) * 0.5f);
	}

	private void RouteGesture(EventType type, float scaleDelta, float rotationDelta, Float2 translationDelta)
	{
		let e = scope GestureEvent(type, mGestureTarget);
		e.Pointer = mGesturePointer;
		e.Focus = GestureFocus();
		e.Scale = mGestureScale;
		e.Rotation = mGestureRotation;
		e.Translation = mGestureTranslation;
		e.ScaleDelta = scaleDelta;
		e.RotationDelta = rotationDelta;
		e.TranslationDelta = translationDelta;
		mGestureTarget.RouteEvent(e);
	}

	// The gesture's node, a reference held.
	private void SetGestureTarget(Node target)
	{
		if (target != null)
			target.AddRef();
		if (mGestureTarget != null)
			mGestureTarget.ReleaseRef();
		mGestureTarget = target;
	}

	/// `dips` in the device pixels positions come in: the root's display scale times it.
	private float Dips(float dips) => dips * ((mRoot != null) ? mRoot.PixelScale : 1.0f);

	// A second press of the same button near in time and place is a double click, a third a
	// triple (positions in device pixels).
	private void CountClick(Float2 position, MouseButton button, PointerType pointer)
	{
		let dx = position.X - mLastPressAt.X;
		let dy = position.Y - mLastPressAt.Y;
		let slop = Dips((pointer == .Touch) ? cTapSlop : cClickSlop); // a finger wobbles more
		let near = dx * dx + dy * dy <= slop * slop;
		let soon = mTime - mLastPressTime <= cClickInterval;
		mClickCount = ((button == mLastPressButton) && near && soon && (mClickCount > 0)) ? mClickCount + 1 : 1;
		mLastPressTime = mTime;
		mLastPressAt = position;
		mLastPressButton = button;
	}

	// The right stick: past its dead zone, rescaled from there and squared (fine near the centre,
	// fast at the rim), each axis moving the nearest scroller that scrolls that way.
	private void ScrollByStick(float seconds)
	{
		let push = Float2(EventDispatcherDetail.StickShape(mScrollStick.X, cStickDeadZone), EventDispatcherDetail.StickShape(mScrollStick.Y, cStickDeadZone));
		if ((push.X == 0.0f) && (push.Y == 0.0f))
			return;
		let from = (mFocusNode != null) ? mFocusNode : (mHoverPath.IsEmpty ? null : mHoverPath[mHoverPath.Count - 1]);
		for (uint32 axis = 0; axis < 2; axis++)
		{
			let p = (axis == 0) ? push.X : push.Y;
			if (p == 0.0f)
				continue;
			for (var n = from; n != null; n = n.Parent)
			{
				if (!n.IsScrollContainer || (((axis == 0) ? n.ScrollRange.X : n.ScrollRange.Y) <= 0.0f))
					continue;
				let by = p * cStickSpeed * seconds;
				n.ScrollBy((axis == 0) ? Float2(by, 0.0f) : Float2(0.0f, by));
				break;
			}
		}
	}

	// A move of `delta` at world point `at`, in `node`'s own units (a finger moves in the window's
	// pixels; a scroller scrolls in its logical units, which a display scale or a transform makes
	// differ).
	private static Float2 InNodeUnits(Node node, Float2 at, Float2 delta)
	{
		let from = node.ConvertToNodeSpace(at);
		let to = node.ConvertToNodeSpace(.(at.X + delta.X, at.Y + delta.Y));
		return .(to.X - from.X, to.Y - from.Y);
	}

	// The nearest scroller at or above where the finger went down that can move along the way it
	// moved (its larger axis).
	private Node PanScrollerFor(Float2 moved)
	{
		let across = Abs(moved.X) > Abs(moved.Y);
		for (var n = HitTest(mPressAt); n != null; n = n.Parent)
		{
			if (!n.IsScrollContainer)
				continue;
			let range = n.ScrollRange;
			if ((across ? range.X : range.Y) > 0.0f)
				return n;
		}
		return null;
	}

	private void AddPanSample(Float2 position)
	{
		// A ring of the last few points on the dispatcher's clock.
		mPanSamples[mPanSampleCount % cPanSamples] = .(mTime, position);
		mPanSampleCount++;
	}

	// The finger's speed over its last cPanWindow: from the oldest sample within it to the latest.
	private Float2 PanVelocity()
	{
		if (mPanSampleCount < 2)
			return .(0.0f, 0.0f);
		let last = mPanSamples[(mPanSampleCount - 1) % cPanSamples];
		var first = last;
		let kept = Math.Min(mPanSampleCount, cPanSamples);
		for (int i = 1; i < kept; i++)
		{
			let s = mPanSamples[(mPanSampleCount - 1 - i) % cPanSamples];
			if (last.Time - s.Time > cPanWindow)
				break;
			first = s;
		}
		let dt = last.Time - first.Time;
		if (dt <= 0.004f)
			return .(0.0f, 0.0f);
		return .((last.Position.X - first.Position.X) / dt, (last.Position.Y - first.Position.Y) / dt);
	}

	// True if `node` is `ancestor` or a descendant of it.
	private static bool IsInSubtree(Node node, Node ancestor)
	{
		if (ancestor == null)
			return false;
		for (var n = node; n != null; n = n.Parent)
		{
			if (n == ancestor)
				return true;
		}
		return false;
	}

	// === Drag and drop's own ===

	// The modifiers' choice among the effects the source allows (Ctrl copy, Shift move, both
	// link), else move, copy or link, whichever it allows first.
	private Sedulous.GUI.DropEffect PreferredEffect()
	{
		let ctrl = (mDragModifiers & KeyModCtrl) != 0;
		let shift = (mDragModifiers & KeyModShift) != 0;
		let asked = (ctrl && shift) ? Sedulous.GUI.DropEffect.Link : ctrl ? Sedulous.GUI.DropEffect.Copy : shift ? Sedulous.GUI.DropEffect.Move : Sedulous.GUI.DropEffect.None;
		if ((asked != .None) && ((mDragPayload.Allowed & DropEffectFlag(asked)) != 0))
			return asked;
		Sedulous.GUI.DropEffect[3] order = .(.Move, .Copy, .Link);
		for (let e in order)
		{
			if ((mDragPayload.Allowed & DropEffectFlag(e)) != 0)
				return e;
		}
		return .None;
	}

	// Whether a press on `node` would offer a drag that something takes (asked without starting
	// it: a source's answer must not change anything).
	private bool HasDragSource(Node node)
	{
		for (var n = node; n != null; n = n.Parent)
		{
			let local = n.ConvertToNodeSpace(mPressAt);
			if (n.OwnsPressDrag(local))
				return false;
			let request = scope DragRequest();
			request.Press = local;
			request.Pointer = .Touch;
			if (n.HandleDragRequested(request))
				return true;
		}
		return false;
	}

	// A press past the threshold: the drag offered up from the pressed node.
	private bool TryDrag(Float2 position, uint32 modifiers, PointerType pointer)
	{
		mDragTried = true;
		for (var n = mDownNode; n != null; n = n.Parent)
		{
			if (!n.IsTreeEnabled)
				return false;
			let local = n.ConvertToNodeSpace(mPressAt);
			if (n.OwnsPressDrag(local))
				return false; // its press is its own (a slider, a scroll bar, a field)
			let request = scope DragRequest();
			request.Press = local;
			request.Modifiers = modifiers;
			request.Pointer = pointer;
			if (n.HandleDragRequested(request))
			{
				mDragModifiers = modifiers;
				BeginDrag(n, request, position);
				return true;
			}
		}
		return false;
	}

	private void BeginDrag(Node source, DragRequest request, Float2 at)
	{
		if (mDragActive)
			CancelDrag();
		source.AddRef();
		defer source.ReleaseRef();
		CancelPointer(); // the press is the drag's now: no release or click follows
		HideTooltip();
		mDragActive = true;
		mDragSource = source;
		mDragFromKeyboard = request.FromKeyboard;
		mDragPayload.Set(request.Payload);
		if (mDragPayload.Label.IsEmpty)
			mDragPayload.Label.Set(mDragPayload.Type);
		source.DragSourceState = true;

		// The preview, held where the press was on the source (GPUI), or beside the pointer.
		SetDragPreview(request.Preview);
		if (request.HasGrabOffset)
			mGrabOffset = request.GrabOffset;
		else if (mDragPreview != null)
			mGrabOffset = request.Press;
		else
			mGrabOffset = .(-14.0f, -12.0f);
		delete mDragFollow;
		mDragFollow = request.Follow;
		request.Follow = null;
		if ((mDragPreview == null) && (mDragFollow == null))
			mDragPreview = source.CreateDragPreview(mDragPayload); // its reference is the drag's
		if (mRoot != null)
		{
			if (mDragLayer != null)
				mDragLayer.ReleaseRef();
			mDragLayer = new DragLayer();
			mDragLayer.Position = .(0.0f, 0.0f);
			mDragLayer.Size = mRoot.Size;
			if (mDragPreview != null)
			{
				mDragPreview.HitTestVisible = false;
				mDragLayer.AddChild(mDragPreview);
			}
			let options = new PopupOptions();
			options.Kind = .Manual;
			options.PassesPointer = true;
			OpenPopup(mRoot, mDragLayer, options);
			mDragLayerIn = this;
		}
		mDragOver = this;
		mDragOutside = false;

		let started = scope DragEvent(.DragStart, source, mDragPayload);
		started.Position = RootPoint(at);
		started.Modifiers = mDragModifiers;
		source.SendEvent(started);
		QueryDrop(at);
	}

	// The drag's preview, a reference held (null: none).
	private void SetDragPreview(Node preview)
	{
		if (preview != null)
			preview.AddRef();
		if (mDragPreview != null)
			mDragPreview.ReleaseRef();
		mDragPreview = preview;
	}

	// Where a drag's pointer is: over this root, over another root of the GUI (a window of its
	// own), or outside every root. Where the roots' places are not known (Wayland, no host), past
	// its own root's edge is outside (a drop nothing there takes ends outside).
	private void LocateDrag(Float2 at)
	{
		mDragOver = this;
		mDragOverAt = at;
		mDragOutside = false;
		mDragScreenKnown = false;
		if (mDragFromKeyboard)
			return; // the focus is what is asked
		if ((mRootPlaces != null) && mRootPlaces.ToScreen(this, at, let screen))
		{
			mDragScreenKnown = true;
			mDragScreen = screen;
			let over = mRootPlaces.DispatcherAt(screen, let local);
			if (over != null)
			{
				mDragOver = over;
				mDragOverAt = local;
			}
			else
				mDragOutside = true;
			return;
		}
		if (mRoot != null)
		{
			let p = RootPoint(at);
			let size = mRoot.Size;
			mDragOutside = (p.X < 0.0f) || (p.Y < 0.0f) || (p.X >= size.X) || (p.Y >= size.Y);
		}
	}

	// The drag's layer (its preview and hint) in the root the pointer is over, a popup there.
	private void MoveDragLayerTo(EventDispatcher over)
	{
		if ((mDragLayer == null) || (mDragLayerIn == over) || (over.mRoot == null))
			return;
		if ((mDragLayerIn != null) && mDragLayerIn.IsPopupOpen(mDragLayer))
			mDragLayerIn.ClosePopup(mDragLayer, .Code);
		mDragLayer.Size = over.mRoot.Size;
		let options = new PopupOptions();
		options.Kind = .Manual;
		options.PassesPointer = true;
		over.OpenPopup(over.mRoot, mDragLayer, options);
		mDragLayerIn = over;
	}

	// What a drop at `at` would do: asked of the node there and up its ancestors (in the root the
	// pointer is over, which may be another root's of the GUI).
	private void QueryDrop(Float2 at)
	{
		mMousePos = at;
		if (mDragFollow != null)
			mDragFollow(RootPoint(at)); // the source moves first: what it leaves is asked
		LocateDrag(at);
		if (!mDragOutside)
			MoveDragLayerTo(mDragOver);
		let overAt = mDragOverAt;
		// Over no root of the placed ones: nothing to ask. Past its own root's edge where the
		// places are not known, what lies there is still asked (a node may reach past it).
		let hit = (mDragOutside && mDragScreenKnown) ? null : mDragOver.HitTest(overAt);
		NoteDragRest(hit);
		let query = scope DropQuery(mDragPayload);
		query.Modifiers = mDragModifiers;
		query.Preferred = PreferredEffect();
		Node target = null;
		for (var n = hit; n != null; n = n.Parent)
		{
			if (!n.IsTreeEnabled)
				break;
			query.Local = n.ConvertToNodeSpace(overAt);
			query.Effect = .None;
			n.HandleDragQuery(query);
			if (query.Effect != .None)
			{
				target = n;
				break;
			}
			if (query.Refused)
				break; // refused with a reason: the walk ends, the reason shows
		}
		SetDropTarget(target, query, at);
	}

	private void SetDropTarget(Node target, DropQuery query, Float2 at)
	{
		let rootAt = DragRootPoint();
		if (target != mDropTarget)
		{
			let left = mDropTarget;
			if (left != null)
			{
				mDropTarget = null;
				left.DropTargetState = false;
				let e = scope DragEvent(.DragLeave, left, mDragPayload);
				FillDragEvent(e, query, rootAt);
				left.HandleDragEvent(e);
			}
			mDropTarget = target;
			if (target != null)
			{
				target.DropTargetState = true;
				let e = scope DragEvent(.DragEnter, target, mDragPayload);
				FillDragEvent(e, query, rootAt);
				target.HandleDragEvent(e);
			}
		}
		if (mDropTarget != null)
		{
			let e = scope DragEvent(.DragOver, mDropTarget, mDragPayload);
			FillDragEvent(e, query, rootAt);
			mDropTarget.HandleDragEvent(e);
		}
		mDropEffect = (target != null) ? query.Effect : .None;
		mDropPlace = query.Place;
		ShowDropState(query.Reason, query.Refused, rootAt);
	}

	// A drag event's fields as a query answered them.
	private void FillDragEvent(DragEvent e, DropQuery query, Float2 rootAt)
	{
		e.Effect = query.Effect;
		e.Position = rootAt;
		e.Modifiers = mDragModifiers;
		e.Place = query.Place;
	}

	// The preview at the pointer with the effect shown, and the reason's hint beside it.
	private void ShowDropState(StringView reason, bool refused, Float2 rootAt)
	{
		if (mDragLayer == null)
			return;
		if (mDragPreview != null)
		{
			mDragPreview.OnDragPreviewEffect(mDropEffect);
			mDragLayer.Place(mDragPreview, .(rootAt.X - mGrabOffset.X, rootAt.Y - mGrabOffset.Y));
		}
		let showHint = reason.Length != 0;
		if (showHint && ((mDropReason != reason) || (mDropRefused != refused) || (mDropHint == null)))
		{
			let old = mDropHint;
			if (old != null)
				old.RemoveFromParent();
			mDropHint = (mDragSource != null) ? mDragSource.CreateDropHint(reason, refused) : null; // its reference is the drag's
			if (old != null)
				old.ReleaseRef();
			if (mDropHint != null)
			{
				mDropHint.HitTestVisible = false;
				mDragLayer.AddChild(mDropHint);
			}
		}
		else if (!showHint && (mDropHint != null))
		{
			mDropHint.RemoveFromParent();
			mDropHint.ReleaseRef();
			mDropHint = null;
		}
		mDropReason.Set(reason);
		mDropRefused = refused;
		if (mDropHint != null)
		{
			// Below the preview (beside the pointer when it has none), never over it.
			var at = Float2(rootAt.X + 16.0f, rootAt.Y + 22.0f);
			if (mDragPreview != null)
			{
				let size = mDragPreview.Measure(LayoutConstraints());
				at = .(rootAt.X - mGrabOffset.X, rootAt.Y - mGrabOffset.Y + size.Y + 4.0f);
			}
			mDragLayer.Place(mDropHint, at);
		}
	}

	private void Drop()
	{
		let target = mDropTarget;
		let effect = mDropEffect;
		if ((target == null) || (effect == .None))
		{
			FinishDrag(.None, null, false);
			return;
		}
		target.AddRef();
		defer target.ReleaseRef();
		let dropped = scope DragEvent(.Drop, target, mDragPayload);
		dropped.Effect = effect;
		dropped.Position = DragRootPoint();
		dropped.Modifiers = mDragModifiers;
		dropped.Place = mDropPlace;
		target.HandleDragEvent(dropped);
		FinishDrag(effect, target, false);
	}

	// The drag ends: the layer goes, the states clear, the source is told.
	private void FinishDrag(Sedulous.GUI.DropEffect effect, Node target, bool cancelled)
	{
		if (!mDragActive)
			return;
		mDragActive = false;
		let source = mDragSource;
		if (source != null)
			source.AddRef();
		defer
		{
			if (source != null)
				source.ReleaseRef();
		}
		// The drag's, told to the source, then gone. Moved out as Raptor's is, the dispatcher's own
		// left empty and alive: a drag ended by one of a drop's listeners leaves the rest reading it.
		let payload = scope DragPayload();
		payload.Set(mDragPayload);
		mDragPayload.Reset();
		let left = mDropTarget;
		if (left != null)
		{
			mDropTarget = null;
			left.DropTargetState = false;
			if (target == null)
			{
				let leave = scope DragEvent(.DragLeave, left, payload);
				leave.Position = DragRootPoint();
				left.HandleDragEvent(leave);
			}
		}
		if ((mDragLayer != null) && (mDragLayerIn != null) && mDragLayerIn.IsPopupOpen(mDragLayer))
			mDragLayerIn.ClosePopup(mDragLayer, .Code);
		if (mDragLayer != null)
		{
			mDragLayer.ReleaseRef();
			mDragLayer = null;
		}
		mDragLayerIn = null;
		let outside = mDragOutside && (target == null) && !cancelled;
		let screenKnown = mDragScreenKnown;
		let screen = mDragScreen;
		mDragOver = null;
		mDragOutside = false;
		SetDragPreview(null);
		delete mDragFollow;
		mDragFollow = null;
		if (mDropHint != null)
		{
			mDropHint.ReleaseRef();
			mDropHint = null;
		}
		mDragSource = null;
		mDropEffect = .None;
		mDropReason.Clear();
		mDropRefused = false;
		mDragFromKeyboard = false;
		mDragRestNode = null;
		if (source != null)
		{
			source.DragSourceState = false;
			var result = DragResult();
			result.Effect = effect;
			result.Target = target;
			result.Cancelled = cancelled;
			result.Outside = outside;
			result.ScreenKnown = screenKnown;
			result.Screen = screen;
			let ended = scope DragEvent(.DragEnd, source, payload);
			ended.Effect = effect;
			ended.Position = RootPoint(mMousePos);
			source.HandleDragEnd(result, ended);
		}
	}

	// A drag's tick: the scroller under the pointer near its edge scrolls (the innermost that can
	// move that way, and only one the drag can land in: the drop target is it or inside it, so a
	// panel dragged to dock past a list does not scroll the list), and a drag resting on a node a
	// moment opens it.
	private void TickDrag(float seconds)
	{
		if ((mDragOver != this) || mDragOutside)
			return; // over another root (whose own content it does not scroll) or none
		let hit = HitTest(mMousePos);
		bool moved = false;
		for (var n = hit; (n != null) && !moved; n = n.Parent)
		{
			if (!n.IsScrollContainer || !IsInSubtree(mDropTarget, n))
				continue;
			let p = n.ConvertToNodeSpace(mMousePos);
			let size = n.Size;
			let range = n.ScrollRange;
			let offset = n.ScrollOffset;
			let low = n.ScrollMin;
			let high = n.ScrollMax;
			let v = Float2((range.X > 0.0f) ? DragScrollSpeed(p.X, size.X, offset.X, low.X, high.X) : 0.0f,
				(range.Y > 0.0f) ? DragScrollSpeed(p.Y, size.Y, offset.Y, low.Y, high.Y) : 0.0f);
			if ((v.X != 0.0f) || (v.Y != 0.0f))
			{
				n.ScrollBy(.(v.X * seconds, v.Y * seconds));
				moved = true;
			}
		}
		// Resting: the same node under the pointer since it arrived there.
		NoteDragRest(hit);
		if (!moved && !mDragRestOpened)
		{
			mDragRest += seconds;
			if (mDragRest >= mDragHoverOpenDelay)
			{
				mDragRestOpened = true;
				for (var n = hit; n != null; n = n.Parent)
				{
					if (n.HandleDragHoverOpen(n.ConvertToNodeSpace(mMousePos)))
					{
						moved = true;
						break;
					}
				}
			}
		}
		if (moved)
			QueryDrop(mMousePos); // the content moved under the pointer
	}

	// How fast a drag at `at` along an axis `length` long scrolls a scroller at `now` within
	// `min` to `max`: back within the band at its start, on within the band at its end.
	private float DragScrollSpeed(float at, float length, float now, float min, float max)
	{
		if ((at < mDragScrollBand) && (now > min))
			return -mDragScrollSpeed * (1.0f - Math.Max(0.0f, at) / mDragScrollBand);
		if ((at > length - mDragScrollBand) && (now < max))
			return mDragScrollSpeed * (1.0f - Math.Max(0.0f, length - at) / mDragScrollBand);
		return 0.0f;
	}

	// A keyboard drag's point: the focus's centre (in device pixels, as input arrives).
	private Float2 FocusPoint()
	{
		if (mFocusNode == null)
			return mMousePos;
		return mFocusNode.ConvertToWorldSpace(.(mFocusNode.Size.X * 0.5f, mFocusNode.Size.Y * 0.5f));
	}

	// A keyboard drag asks the focus and up its ancestors (not what lies under a point).
	private void QueryAtFocus()
	{
		if (!mDragActive)
			return;
		let at = FocusPoint();
		mMousePos = at;
		let query = scope DropQuery(mDragPayload);
		query.Preferred = PreferredEffect();
		query.FromKeyboard = true;
		Node target = null;
		for (var n = mFocusNode; n != null; n = n.Parent)
		{
			if (!n.IsTreeEnabled)
				break;
			query.Local = n.ConvertToNodeSpace(at);
			query.Effect = .None;
			n.HandleDragQuery(query);
			if (query.Effect != .None)
			{
				target = n;
				break;
			}
			if (query.Refused)
				break;
		}
		SetDropTarget(target, query, at);
	}

	// The node a drag rests on: another one starts the clock again.
	private void NoteDragRest(Node hit)
	{
		if (hit == mDragRestNode)
			return;
		mDragRestNode = hit;
		mDragRest = 0.0f;
		mDragRestOpened = false;
	}

	// A point in the root's space (what hit-tests and places the preview), from the device pixels
	// input arrives in.
	private Float2 RootPoint(Float2 at) => (mRoot != null) ? mRoot.ConvertToNodeSpace(at) : at;

	// The drag's pointer in the root it is over (this root's when outside every root).
	private Float2 DragRootPoint()
	{
		if ((mDragOver != null) && (mDragOver != this) && !mDragOutside)
			return mDragOver.RootPoint(mDragOverAt);
		return RootPoint(mMousePos);
	}

	// === Tooltips and long presses ===

	private static Node TooltipProvider(Node node)
	{
		for (var n = node; n != null; n = n.Parent)
		{
			if (n.TooltipText.Length != 0)
				return n;
		}
		return null;
	}

	private void UpdateTooltip(float seconds)
	{
		if (mDragActive)
			return; // no tooltips while dragging (the hint says what a drop would do)
		var provider = mTouchActive ? mTipProvider : TooltipProvider(mOverNode);
		// While the keys move the focus, the focused control's; the pointer's first.
		bool fromFocus = false;
		if ((provider == null) && !mTouchActive && mKeyboardTooltips && (mInputKind != .Pointer) && mKeysMovedFocus && (mFocusNode != null))
		{
			provider = TooltipProvider(mFocusNode);
			fromFocus = provider != null;
		}
		// An interactive tooltip holds while the pointer is in it, and a moment after the pointer
		// leaves both it and its control, so the pointer can cross the gap into it.
		let shown = ShownTooltip;
		if ((shown != null) && mTipInteractive && (provider != mTipProvider))
		{
			if ((mOverNode != null) && IsInSubtree(mOverNode, shown))
			{
				mTipGrace = 0.0f;
				return;
			}
			mTipGrace += seconds;
			if (mTipGrace < cTooltipGrace)
				return;
		}
		mTipGrace = 0.0f;
		if (provider != mTipProvider)
		{
			HideTooltip();
			mTipProvider = provider;
			mTipTimer = 0.0f;
			mTipSuppressed = false;
		}
		// The same provider with other text (a code editor's word under the pointer): hidden, so
		// the new text shows at once, warm, by the pointer where it is now.
		if ((provider != null) && !mTipInteractive && (ShownTooltip != null) && (provider.TooltipText != mTipText))
			HideTooltip();
		if ((provider == null) || mTipSuppressed || mTouchActive || (ShownTooltip != null))
			return;
		mTipTimer += seconds;
		let warm = mTime - mTipHiddenAt <= cTooltipWarm; // one just hid: the next at once
		if (mTipTimer >= (warm ? 0.0f : mTipDelay))
			ShowTooltip(provider, mMousePos, fromFocus);
	}

	private void ShowTooltip(Node provider, Float2 at, bool belowProvider = false)
	{
		if (mRoot == null)
			return;
		let content = provider.CreateTooltipContent(provider.TooltipText);
		if (content == null)
			return;
		mTipText.Set(provider.TooltipText);
		// The root holds it, but it reads and opens as its provider runs.
		let rightToLeft = provider.IsRightToLeft;
		content.SetLayoutDirection(rightToLeft ? .RightToLeft : .LeftToRight);
		let options = new PopupOptions();
		// Interactive: a popup the pointer may enter and press in, which a press outside or Escape
		// closes, rather than a hint any press or key hides.
		mTipInteractive = provider.IsTooltipInteractive;
		options.Kind = mTipInteractive ? .Auto : .Hint;
		if (mTipInteractive)
			content.HitTestVisible = true;
		options.HasAnchorRect = true;
		if (belowProvider)
		{
			// The focused control's: below it, where the pointer is not.
			let p0 = provider.ConvertToRootSpace(.(0.0f, 0.0f));
			let p1 = provider.ConvertToRootSpace(provider.Size);
			options.AnchorRect = .(Math.Min(p0.X, p1.X), Math.Min(p0.Y, p1.Y), Abs(p1.X - p0.X), Abs(p1.Y - p0.Y));
			options.Placement = EventDispatcherDetail.Placement(.Below, .Start, 4.0f, false);
		}
		else
		{
			let p = mRoot.ConvertToNodeSpace(at);
			// Clear of the pointer toward the inline end.
			options.AnchorRect = .(rightToLeft ? p.X - 12.0f : p.X + 12.0f, p.Y, 0.0f, 0.0f);
			options.Placement = EventDispatcherDetail.Placement(.Below, .Start, 18.0f, false);
		}
		options.FitContent = true; // as its text measures, once its sheet styles it
		options.OnClosed = new (reason) =>
			{
				mTipHiddenAt = mTime;
				if (reason != .Code)
					mTipSuppressed = true; // a press or a key: not again until the pointer moves on
			};
		HideTooltip();
		if (mTip != null)
			mTip.ReleaseRef();
		mTip = content; // its reference is the dispatcher's
		mTipProvider = provider;
		OpenPopup(mRoot, mTip, options);
	}

	private void HideTooltip()
	{
		if ((mTip != null) && IsPopupOpen(mTip))
			ClosePopup(mTip, .Code);
	}

	// A finger held still: a context menu at the pressed node; none taken, its tooltip.
	private void LongPress()
	{
		mLongPressArmed = false;
		let target = mDownNode;
		if ((target == null) || !target.IsTreeEnabled)
			return;
		target.AddRef();
		defer target.ReleaseRef();
		// Over a drag source, a finger held still arms its drag (a finger's move pans a scroller
		// first): the next move past the threshold drags, and no context menu opens.
		if (HasDragSource(target))
		{
			mTouchDragArmed = true;
			return;
		}
		let e = scope MouseEvent(.ContextMenu, target, mPressAt);
		e.Pointer = .Touch;
		e.PointerId = mTouchFinger;
		let taken = target.RouteEvent(e);
		CancelPointer(); // no release or click follows the long press
		if (!taken)
		{
			let provider = TooltipProvider(target);
			if (provider != null)
				ShowTooltip(provider, mPressAt);
		}
	}

	// === The top layer's own ===

	private int32 FindPopup(Node popup)
	{
		for (int i = 0; i < mPopups.Count; i++)
		{
			if (mPopups[i].Popup == popup)
				return (int32)i;
		}
		return -1;
	}

	// The topmost auto popup's index (a hint skipped, none past a manual one), or -1.
	private int32 TopAutoPopup()
	{
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			if (mPopups[i].Options.Kind == .Hint)
				continue;
			return (mPopups[i].Options.Kind == .Auto) ? (int32)i : -1;
		}
		return -1;
	}

	// The topmost modal popup's index, or -1.
	private int32 TopModal()
	{
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			if (mPopups[i].Options.Modal)
				return (int32)i;
		}
		return -1;
	}

	// Whether `node` takes input: anything while no modal is open; else what is in the topmost
	// modal popup or in a popup above it. Never what is leaving or inert.
	private bool IsLive(Node node)
	{
		if ((node != null) && node.IsTreeInert)
			return false;
		let modal = TopModal();
		if ((modal < 0) || (node == null))
			return true;
		for (int i = modal; i < mPopups.Count; i++)
		{
			if (IsInSubtree(node, mPopups[i].Popup))
				return true;
		}
		return false;
	}

	// Closes the auto popups above the one `hit` is in (all of them when it is in none), not past
	// a modal one. True when the press is to be consumed: it closed some and lands in no popup that
	// stays (a press in a parent menu closing its submenu goes on to the parent).
	private bool DismissOutside(Node hit)
	{
		int inside = -1;
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			if (IsInSubtree(hit, mPopups[i].Popup))
			{
				inside = i;
				break;
			}
		}
		bool closed = false;
		for (int i = mPopups.Count - 1; (i >= 0) && (i > inside); i--)
		{
			if (i >= mPopups.Count)
				continue; // closed with the one holding it
			let o = mPopups[i].Options;
			if (o.Modal && (o.Kind != .Auto))
				break;
			if (o.Kind != .Auto)
				continue;
			ClosePopupAt(i, .OutsidePress);
			closed = true;
		}
		return closed && (inside < 0);
	}

	private void ClosePopupsOfKind(PopupKind kind, PopupCloseReason reason)
	{
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			if ((i < mPopups.Count) && (mPopups[i].Options.Kind == kind))
				ClosePopupAt(i, reason);
		}
	}

	// Closes the popup at `index`: the popups it holds first, then it (told, out of the top layer,
	// out of the tree), focus given back while it was inside.
	private void ClosePopupAt(int index, PopupCloseReason reason)
	{
		let closing = mPopups[index].Popup;
		for (int i = mPopups.Count - 1; i >= index + 1; i--)
		{
			if ((i < mPopups.Count) && IsInSubtree(mPopups[i].Popup, closing))
				ClosePopupAt(i, reason);
		}
		let at = FindPopup(closing);
		if (at < 0)
			return; // closed meanwhile (a handler closed it)
		let popup = mPopups[at].Popup;
		popup.AddRef();
		defer popup.ReleaseRef();
		let closed = scope ToggleEvent(popup, false, reason);
		popup.RouteEvent(closed);
		let still = FindPopup(popup);
		if (still < 0)
			return;
		let entry = mPopups[still];
		mPopups.RemoveAt(still);
		defer delete entry;
		let focusInside = (mFocusNode == null) || IsInSubtree(mFocusNode, popup);
		// One that plays an exit stays drawn on top, taking no input, until it has played it.
		let leaves = entry.Options.LeavesOnClose && (popup.Parent != null) && popup.RootNode.HasStylePass;
		Demote(popup, entry);
		if (leaves)
		{
			popup.InTopLayer = true; // drawn over the tree while it leaves
			let leaving = new LeavingPopup();
			popup.AddRef();
			leaving.Popup = popup;
			leaving.Home = entry.Home;
			leaving.HomeIndex = entry.HomeIndex;
			leaving.Modal = entry.Options.Modal;
			leaving.OnGone = entry.Options.OnGone; // the delegate moves to it
			entry.Options.OnGone = null;
			mLeaving.Add(leaving);
			popup.Leave();
		}
		else
		{
			popup.RemoveFromParent(); // a closed popup leaves the tree; its owner keeps it
			// Or it goes back where it stood (ReturnHome), while that is still there.
			let home = (entry.Home.Table != null) ? entry.Home.Table.Resolve(entry.Home.Slot, entry.Home.Generation) : null;
			if (home != null)
				home.AddChildAt(popup, Math.Min(entry.HomeIndex, home.ChildCount));
		}
		if (focusInside && !entry.SavedFocus.IsEmpty)
			RestoreFocus(entry, null);
		if (entry.Options.OnClosed != null)
			entry.Options.OnClosed(reason);
		if (!leaves && (entry.Options.OnGone != null))
			entry.Options.OnGone();
	}

	// The popups whose exit has ended (they left their parent): out of the top layer, back home
	// where they came from, told they are gone.
	private void SettleLeavingPopups()
	{
		for (int i = 0; i < mLeaving.Count;)
		{
			let popup = mLeaving[i].Popup;
			if ((popup.Parent != null) && popup.IsLeaving)
			{
				i++;
				continue;
			}
			let gone = mLeaving[i];
			mLeaving.RemoveAt(i);
			defer delete gone;
			popup.InTopLayer = false;
			if (popup.Parent == null)
			{
				let home = (gone.Home.Table != null) ? gone.Home.Table.Resolve(gone.Home.Slot, gone.Home.Generation) : null;
				if (home != null)
					home.AddChildAt(popup, Math.Min(gone.HomeIndex, home.ChildCount));
			}
			if (gone.OnGone != null)
				gone.OnGone();
		}
	}

	// A popup leaving with a subtree: out of the stack, told, focus given back when it can be.
	private void DropPopupAt(int index, PopupCloseReason reason, Node leaving)
	{
		let entry = mPopups[index];
		mPopups.RemoveAt(index);
		defer delete entry;
		let focusInside = (mFocusNode == null) || IsInSubtree(mFocusNode, entry.Popup);
		Demote(entry.Popup, entry);
		if (focusInside && !entry.SavedFocus.IsEmpty)
			RestoreFocus(entry, leaving);
		if (entry.Options.OnClosed != null)
			entry.Options.OnClosed(reason);
	}

	private static void Demote(Node popup, PopupEntry entry)
	{
		popup.InTopLayer = false;
		popup.RouteStop = false;
		if (!entry.SavedFocus.IsEmpty || entry.Options.TakesFocus || entry.Options.Modal)
			popup.NavScope = entry.ScopeBefore;
	}

	// Focus back to what the popup took it from, else the nearest holder of that still here,
	// enabled and focusable; none: no focus.
	private void RestoreFocus(PopupEntry entry, Node leaving)
	{
		for (let saved in entry.SavedFocus)
		{
			let n = (saved.Table != null) ? saved.Table.Resolve(saved.Slot, saved.Generation) : null;
			if ((n == null) || (n.RootNode != mRoot) || ((leaving != null) && IsInSubtree(n, leaving)))
				continue;
			if (n.TabFocusable && n.IsTreeEnabled && n.IsTreeVisible && IsLive(n))
			{
				FocusNode = n;
				return;
			}
		}
		FocusNode = null;
	}

	// The outermost focus group holding `node` below `within` (null when none).
	private static Node OutermostFocusGroup(Node node, Node within)
	{
		Node group = null;
		for (var n = (node != null) ? node.Parent : null; (n != null) && (n != within); n = n.Parent)
		{
			if (n.FocusGroup)
				group = n;
		}
		return group;
	}

	// Gather tab-focusable nodes under `node` in pre-order (skipping hidden subtrees, those out of
	// the layout too, and disabled nodes).
	private static void CollectTabStops(Node node, List<Node> outStops)
	{
		if ((node == null) || !node.Visible || !node.Displayed)
			return;
		if (node.TabFocusable && node.IsTreeEnabled)
			outStops.Add(node);
		for (int i = 0; i < node.ChildCount; i++)
			CollectTabStops(node.GetChildAt(i), outStops);
	}

	private bool MoveTabFocus(int32 direction)
	{
		// nav-next / nav-prev first.
		if (mFocusNode != null)
		{
			let root = FocusScopeRoot;
			bool stop = false;
			Node overridden = null;
			if (root != null)
				overridden = FollowOverride(root, mFocusNode, (direction > 0) ? .NavOverrideNext : .NavOverridePrevious, out stop);
			if (overridden != null)
			{
				FocusNode = overridden;
				return true;
			}
			if (stop)
				return false;
		}
		let stops = scope List<Node>();
		TabStops(stops);
		let count = stops.Count;
		if (count == 0)
			return false;

		// Find the current focus among the stops.
		int current = count; // not in the list
		for (int i = 0; i < count; i++)
		{
			if (stops[i] == mFocusNode)
			{
				current = i;
				break;
			}
		}

		int next;
		if (current == count)
			next = (direction > 0) ? 0 : count - 1; // nothing focused: first / last
		else
			next = (direction > 0) ? ((current + 1) % count) : ((current + count - 1) % count);

		FocusNode = stops[next];
		return true;
	}

	private void SetAltHeld(bool held)
	{
		if (held == mAltHeld)
			return;
		let was = AreMnemonicsShown;
		mAltHeld = held;
		if (was != AreMnemonicsShown)
			RedrawMnemonics();
	}

	// What draws an access key draws again (it and its parts), in the tree and its popups.
	private void RedrawMnemonics()
	{
		EventDispatcherDetail.RedrawMnemonicsIn(mRoot, false);
		for (let entry in mPopups)
			EventDispatcherDetail.RedrawMnemonicsIn(entry.Popup, false);
	}

	// The character a key types for an access key: its letter (lower case) or digit, else 0.
	private static char32 MnemonicOfKey(KeyCode key)
	{
		for (int i = 0; i < 26; i++)
		{
			if (sLetterKeys[i] == key)
				return (char32)((int)'a' + i);
		}
		if (((uint32)key >= (uint32)KeyCode.Num0) && ((uint32)key <= (uint32)KeyCode.Num9))
			return (char32)((uint32)'0' + ((uint32)key - (uint32)KeyCode.Num0));
		return '\0';
	}

	// The first shown, enabled widget marked `key` in the open menu (else the focus scope) takes
	// focus where it can and acts. False when none is marked so.
	private bool ActivateMnemonic(char32 key)
	{
		if (key == '\0')
			return false;
		var within = FocusScopeRoot;
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			if (mPopups[i].Options.Kind != .Hint) // a tooltip is never where keys go
			{
				within = mPopups[i].Popup;
				break;
			}
		}
		let found = EventDispatcherDetail.FindMnemonic(within, key);
		if (found == null)
			return false;
		UseKeyboard();
		if (found.TabFocusable)
			FocusNode = found;
		found.HandleActivate();
		return true;
	}

	private void TakeCapturedKey(Keystroke stroke)
	{
		mCapture.Waiting = false;
		let onKey = mCapture.OnKey;
		mCapture.OnKey = null;
		delete mCapture.OnCancel;
		mCapture.OnCancel = null;
		if (onKey != null)
			onKey(stroke);
		delete onKey;
	}

	private void NoteInput()
	{
		if (mOnInput != null)
			mOnInput();
	}

	// A key or d-pad move (a navigation): the focus ring shows; the pointer's kind gives way to
	// the keys'.
	private void UseKeyboard()
	{
		if (mInputKind == .Pointer)
			ApplyInputKind(.Keyboard);
		mKeysMovedFocus = true;
		if (mFocusNode != null)
			mFocusNode.FocusVisible = true;
	}

	private void ApplyInputKind(Sedulous.GUI.InputKind kind)
	{
		if (kind == mInputKind)
			return;
		mInputKind = kind;
		if (kind == .Pointer)
			mKeysMovedFocus = false;
		if (mFocusNode != null)
			mFocusNode.FocusVisible = kind != .Pointer;
		mInputKindChanged.Notify();
		if (mRoot != null)
		{
			mRoot.Invalidate(); // the cursor, and what a sheet shows for it
			mRoot.SendEvent(scope Event(.InputKindChanged, mRoot));
		}
	}

	private class PopupEntry
	{
		/// A reference held.
		public Node Popup ~ _?.ReleaseRef();
		public PopupOptions Options ~ delete _;
		/// Its own size, which placement shrinks from.
		public Float2 Size = .(0.0f, 0.0f);
		/// The focus it took, then the nodes holding it.
		public List<Node.ElementRef> SavedFocus = new .() ~ delete _;
		public NavScope ScopeBefore = .None;
		/// Where it goes back to when it closes (ReturnHome): weak, since it may be this root
		/// itself, which owns this dispatcher (a strong reference would keep the root alive).
		public Node.ElementRef Home = .();
		public int HomeIndex = 0;
	}

	// A closed popup playing its exit (LeavesOnClose).
	private class LeavingPopup
	{
		/// A reference held.
		public Node Popup ~ _?.ReleaseRef();
		/// Where it goes back to once gone (weak, as PopupEntry's).
		public Node.ElementRef Home = .();
		public int HomeIndex = 0;
		public bool Modal = false;
		public delegate void() OnGone ~ delete _;
	}

	// CaptureNextKey's wait.
	private class KeyCapture
	{
		public delegate void(Keystroke stroke) OnKey ~ delete _;
		public delegate void() OnCancel ~ delete _;
		public bool TakeEscape = false;
		public bool Waiting = false;
		/// The key it took types text next: dropped.
		public bool DropText = false;
		/// A modifier key down, taken alone if released first.
		public uint32 PendingModifier = 0;
	}

	private struct PanSample
	{
		public float Time = 0.0f;
		public Float2 Position = .(0.0f, 0.0f);

		public this() { }

		public this(float time, Float2 position)
		{
			Time = time;
			Position = position;
		}
	}

	private Node mRoot; // not owned (the SceneRoot owns this dispatcher)
	private List<Finger> mFingers = new .() ~ delete _; // every finger down (the first, when active, is the pointer)
	// The gesture in progress: its node, its two fingers, and its totals so far.
	private bool mGesturing = false;
	private Node mGestureTarget = null ~ _?.ReleaseRef(); // a reference held
	private uint64[2] mGestureIds = default;
	private PointerType mGesturePointer = .Touch; // two fingers, or a trackpad's pinch
	private float mGestureSpan0 = 1.0f;
	private float mGestureAngle = 0.0f; // the fingers' line, as last seen
	private Float2 mGestureFocus0 = .(0.0f, 0.0f);
	private float mGestureScale = 1.0f;
	private float mGestureRotation = 0.0f;
	private Float2 mGestureTranslation = .(0.0f, 0.0f);
	private IClipboard mClipboard = null; // borrowed system-clipboard adapter (optional)
	private delegate bool(Node window) mModalInterceptor ~ delete _; // SetModalInterceptor
	private Node mOverNode = null; // the deepest node of the hover path
	private NavTrace mLastNavigation = new .() ~ delete _; // what the last directional move weighed
	private List<Node> mHoverPath = new .() ~ delete _; // root first: every node under the pointer
	private List<Node> mPressPath = new .() ~ delete _; // the pressed node and the nodes holding it
	private Node mCaptureNode = null; // explicit pointer capture (CapturePointer)
	private float mTime = 0.0f; // seconds, advanced by Tick (click counting)
	private float mLastPressTime = -1000.0f;
	private Float2 mLastPressAt = .(0.0f, 0.0f);
	private MouseButton mLastPressButton = .Left;
	private uint32 mClickCount = 0;
	private bool mTouchActive = false; // the first finger is down (it drives the pointer)
	private uint64 mTouchFinger = 0;
	private Node mDownNode = null;
	private PanSample[cPanSamples] mPanSamples = default;
	private int mPanSampleCount = 0;
	private Float2 mScrollStick = .(0.0f, 0.0f); // a pad's right stick (ScrollByStick)
	private bool mPanning = false; // the finger pans mPanScroller
	private Node mPanScroller = null; // cleared when its subtree leaves
	private Float2 mPanLast = .(0.0f, 0.0f); // where the finger was at the last pan step
	private bool mClickSuppressed = false; // the press activated already (SuppressClick)
	private Node mFocusNode = null;
	/// A focus asked before the sheet showed its node (RequestFocusAfterStyle). BORROWED.
	private Node mPendingFocus = null;
	private List<PopupEntry> mPopups = new .() ~ DeleteContainerAndItems!(_); // the top layer, bottom first
	private Keystroke mCaptureRelease = .((uint32)KeyCode.F1, KeyModShift, false);
	private List<LeavingPopup> mLeaving = new .() ~ DeleteContainerAndItems!(_); // closed popups playing their exit: drawn under the open ones, no input
	private bool mSwallowing = false; // a press that closed a popup: its release is consumed too
	// Tooltips: the node whose text shows or waits, the content shown, the clock.
	private Node mTipProvider = null;
	private Node mTip = null ~ _?.ReleaseRef(); // a reference held
	private String mTipText = new .() ~ delete _; // what the shown one says, to see its provider's change
	private float mTipTimer = 0.0f;
	private float mTipDelay = 0.5f;
	private float mTipHiddenAt = -1000.0f;
	private bool mTipSuppressed = false;
	private bool mTipInteractive = false; // the one shown takes the pointer
	private float mTipGrace = 0.0f;
	private bool mKeyboardTooltips = true;
	private bool mKeysMovedFocus = false; // keys moved the focus since the pointer was last used
	// A long press: armed by a finger's press, disarmed by moving or lifting it.
	private bool mLongPressArmed = false;
	private float mPressHeld = 0.0f;
	private Float2 mPressAt = .(0.0f, 0.0f);
	private bool mDragActive = false; // drag and drop in progress
	private bool mDragTried = true; // this press offered its drag already
	private bool mTouchDragArmed = false; // a finger held long enough over a source
	private bool mDragFromKeyboard = false;
	private float mDragThreshold = 6.0f;
	private uint32 mDragModifiers = 0;
	private Sedulous.GUI.DropEffect mDropEffect = .None;
	private int32 mDropPlace = 0;
	private String mDropReason = new .() ~ delete _;
	private bool mDropRefused = false;
	private Float2 mGrabOffset = .(0.0f, 0.0f);
	private DragLayer mDragLayer = null ~ _?.ReleaseRef(); // a reference held
	private Node mDragPreview = null ~ _?.ReleaseRef(); // a reference held
	private delegate void(Float2 pointer) mDragFollow ~ delete _; // a source that shows itself where the drag is
	private Node mDropHint = null ~ _?.ReleaseRef(); // a reference held
	private delegate bool(Span<StringView> paths, Float2 at) mOnFileDrop ~ delete _;
	private List<System.Variant> mDroppedFiles = new .() ~ { EventDispatcherDetail.ClearVariants(_); delete _; }; // the last file drop's paths
	private float mDragScrollBand = 24.0f;
	private float mDragScrollSpeed = 900.0f;
	private float mDragHoverOpenDelay = 0.6f;
	private Node mDragRestNode = null; // compared, never followed
	private IRootPlaces mRootPlaces = null; // the GUI's (its host's); borrowed
	private EventDispatcher mDragOver = null; // the root's a drag is over (this, or another root's)
	private Float2 mDragOverAt = .(); // the pointer in that root
	private bool mDragOutside = false; // over no root
	private bool mDragScreenKnown = false; // where on the screen is known (a host placed the roots)
	private Float2 mDragScreen = .();
	private EventDispatcher mDragLayerIn = null; // where the drag's layer is a popup
	private float mDragRest = 0.0f;
	private bool mDragRestOpened = false;
	private Node mDragSource = null;
	private Node mDropTarget = null; // the current target
	private Sedulous.GUI.DragPayload mDragPayload = new .() ~ delete _;
	private Float2 mMousePos = .(0.0f, 0.0f);
	private Observable mFocusChanged = new .() ~ delete _; // told when focus moves
	private delegate bool(Keystroke stroke) mKeystrokes ~ delete _; // the keymap (SceneRoot)
	private bool mAltHeld = false; // access keys show while it is
	private bool mMnemonicsAlways = false; // access keys always show
	private KeyCapture mCapture = new .() ~ delete _;
	private delegate void() mOnInput ~ delete _; // this root took input (GUIContext)
	// What drives the GUI: the keys until the pointer is used, so a menu opening with focus on its
	// first button shows it (as games do).
	private Sedulous.GUI.InputKind mInputKind = .Keyboard;
	private Observable mInputKindChanged = new .() ~ delete _;
	private bool mHolding = false; // a direction held (PressDirection)
	private NavDirection mHeldDirection = .Down;
	private float mHeldFor = 0.0f;
	private float mNextRepeatAt = 0.0f;
}

/// What EventDispatcher.bf keeps out of the public surface.
internal static class EventDispatcherDetail
{
	/// Whether Tab reaches `a` before `b` by their tab-index: a positive one first, lowest first.
	public static bool TabsBefore(Node a, Node b)
	{
		let x = a.TabIndex;
		let y = b.TabIndex;
		return (x > 0) && ((y == 0) || (x < y));
	}

	/// `v` on the device grid `scale` makes, rounded down: a popup's near edge (the 0.001 keeps
	/// a value a hair under a grid line on it).
	public static float SnapNear(float v, float scale) => Floor(v * scale + 0.001f) / scale;

	/// `v` on the device grid `scale` makes, rounded up: a popup's far edge.
	public static float SnapFar(float v, float scale) => Ceil(v * scale - 0.001f) / scale;

	public static PopupPlacement Placement(PopupSide side, PopupAlign align, float gap, bool shrink)
	{
		var placement = PopupPlacement();
		placement.Side = side;
		placement.Align = align;
		placement.Gap = gap;
		placement.Shrink = shrink;
		return placement;
	}

	/// A stick's axis past its dead zone, rescaled from there and squared.
	public static float StickShape(float v, float deadZone)
	{
		let a = Abs(v);
		if (a <= deadZone)
			return 0.0f;
		let t = Math.Min(1.0f, (a - deadZone) / (1.0f - deadZone));
		return ((v < 0.0f) ? -t : t) * t;
	}

	/// A reference held for the length of a call (none for null).
	public static void Hold(Node node)
	{
		if (node != null)
			node.AddRef();
	}

	public static void Let(Node node)
	{
		if (node != null)
			node.ReleaseRef();
	}

	public static void ClearVariants(List<System.Variant> list)
	{
		for (var item in list)
			item.Dispose();
		list.Clear();
	}

	public static void RedrawMnemonicsIn(Node node, bool marked)
	{
		if (node == null)
			return;
		let here = marked || (node.Mnemonic != '\0');
		if (here)
			node.Invalidate();
		for (int i = 0; i < node.ChildCount; i++)
			RedrawMnemonicsIn(node.GetChildAt(i), here);
	}

	/// The first shown, enabled node marked `key` from `node` down (pre-order), or null.
	public static Node FindMnemonic(Node node, char32 key)
	{
		if ((node == null) || !node.Visible || !node.Displayed || !node.IsTreeEnabled)
			return null;
		if (node.Mnemonic == key)
			return node;
		for (int i = 0; i < node.ChildCount; i++)
		{
			let found = FindMnemonic(node.GetChildAt(i), key);
			if (found != null)
				return found;
		}
		return null;
	}
}
