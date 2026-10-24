using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// The platform input bridge.
//
// Keeps the GUI core platform-agnostic: the core EventDispatcher exposes an abstract Inject* API;
// this bridge is the ONLY place that knows about the platform input layer (Sedulous.Shell). It
// translates a stream of shell InputEvents (already gated/transformed by InputSurface/InputRouter)
// into dispatcher injections, mapping platform enums to GUI enums and window-space positions to
// content space via a ContentFit.
//
// The InputSurface consumption lives here, never in the core.

/// Translates platform input events into EventDispatcher injections. The dispatcher, the text
/// input window, the cursor's mouse and the input kind tracker are all borrowed.
class GuiInputBridge
{
	/// A shell key run and the GUI key it starts at: the two list the run in the same order.
	private struct Run
	{
		public Sedulous.Shell.KeyCode First;
		public Sedulous.Shell.KeyCode Last;
		public KeyCode To;

		public this(Sedulous.Shell.KeyCode first, Sedulous.Shell.KeyCode last, KeyCode to)
		{
			First = first;
			Last = last;
			To = to;
		}
	}

	private struct PumpedFinger
	{
		public uint64 Id = 0;
		public Float2 At = .(0.0f, 0.0f);

		public this(uint64 id, Float2 at)
		{
			Id = id;
			At = at;
		}
	}

	private const float cStickPress = 0.5f;
	private const float cStickRelease = 0.33f;

	private EventDispatcher mDispatcher;
	private Sedulous.Shell.IWindow mTextInputTarget = null; // window whose IME follows GUI focus (optional)
	private Sedulous.Shell.IMouse mCursorTarget = null; // mouse whose cursor follows the GUI's (optional)
	private Sedulous.Shell.CursorType mShownCursor = .Count; // last applied (Count: none yet)
	private bool mCursorHidden = false; // the bridge hid the cursor (a pad in use)
	private Sedulous.Input.InputKindTracker mInputKind = null; // the host's (optional)
	private Sedulous.Input.InputKind mPassedKind = .Pointer; // its last kind passed on
	private ContentFit mFit = .();
	private int32[5] mTextInputArea = .(-1, -1, -1, -1, -1); // what the window was last told (SyncTextInputArea)
	private bool mHasFit = false;
	private Float2 mWindowSize = .(0.0f, 0.0f); // for placing touch events (SetWindowSize)
	private bool mTouchSeen = false; // a finger was used: the mouse may be SDL's copy of it
	private Float2 mLastTouchAt = .(0.0f, 0.0f); // where the driving finger last was (content space)
	private List<PumpedFinger> mPumpedFingers = new .() ~ delete _; // the polled fingers as last seen
	private int32 mStickX = 0;
	private int32 mStickY = 0;

	public this(EventDispatcher dispatcher)
	{
		mDispatcher = dispatcher;
	}

	/// The content fit maps window/region-space event positions into GUI content space. Without
	/// one, positions pass through unchanged (identity).
	public void SetContentFit(ContentFit fit)
	{
		mFit = fit;
		mHasFit = true;
	}

	public void ClearContentFit()
	{
		mHasFit = false;
	}

	/// The window's size in the coordinates its mouse reports in: touch events arrive normalized
	/// over the window, and Dispatch() places them with it (without it, touch events are not
	/// forwarded). PumpFromSurface() needs none: its surface places fingers.
	public void SetWindowSize(Float2 size)
	{
		mWindowSize = size;
	}

	/// The window whose platform text input (IME) follows GUI focus. Once set, the bridge enables
	/// text input while a text-editing widget holds focus and disables it otherwise - reconciled
	/// after each Dispatch()/PumpFromSurface(), so no per-widget or per-app wiring is needed. Pass
	/// null to disable the feature.
	public void SetTextInputTarget(Sedulous.Shell.IWindow window)
	{
		mTextInputTarget = window;
	}

	/// The mouse whose cursor follows the GUI's (CSS `cursor` on the node under the pointer),
	/// reconciled after each Dispatch()/PumpFromSurface(). Pass null to leave the cursor alone.
	public void SetCursorTarget(Sedulous.Shell.IMouse mouse)
	{
		mCursorTarget = mouse;
		mShownCursor = .Count; // apply on the next sync
	}

	/// The host's input kind tracker (Sedulous.Input's, which the host updates each frame from its
	/// devices): the bridge passes each change of its kind on to the dispatcher, for what reaches
	/// no widget (a mouse moved, a stick pushed). Its kind when attached is not passed: the
	/// dispatcher starts as it does. Null detaches it.
	public void SetInputKindTracker(Sedulous.Input.InputKindTracker tracker)
	{
		mInputKind = tracker;
		if (tracker != null)
			mPassedKind = tracker.Kind;
	}

	public void SyncInputKind()
	{
		if ((mInputKind == null) || (mDispatcher == null) || (mInputKind.Kind == mPassedKind))
			return;
		mPassedKind = mInputKind.Kind;
		mDispatcher.InputKind = MapInputKind(mPassedKind);
	}

	public static Sedulous.GUI.InputKind MapInputKind(Sedulous.Input.InputKind kind)
	{
		switch (kind)
		{
		case .Keyboard: return .Keyboard;
		case .Pad: return .Pad;
		case .Pointer: break;
		}
		return .Pointer;
	}

	/// The tracker's kind passed on, then the cursor: the GUI's (CSS `cursor`), hidden while it
	/// says none (a pad in use). Only a cursor the bridge hid is shown again by it, so a game that
	/// hides the cursor itself (mouse look) is left alone.
	public void SyncCursor()
	{
		SyncInputKind();
		if ((mCursorTarget == null) || (mDispatcher == null))
			return;
		let wanted = mDispatcher.Cursor;
		let hide = wanted == .None;
		if (hide != mCursorHidden)
		{
			mCursorHidden = hide;
			mCursorTarget.SetCursorVisible(!hide);
		}
		if (hide)
			return;
		let cursor = MapCursor(wanted);
		if (cursor == mShownCursor)
			return;
		mShownCursor = cursor;
		mCursorTarget.SetCursor(cursor);
	}

	/// Files the OS dropped (IShell.DrainDroppedFiles): the ones for `windowId` (0: any; a drop
	/// that names no window counts as this one's), grouped by where they landed (a drop of several
	/// arrives a file at a time), each group placed in content space and handed to the dispatcher
	/// as one drop. True when something took one.
	public bool DispatchFileDrops(Span<Sedulous.Shell.DroppedFile> drops, uint32 windowId = 0)
	{
		if (mDispatcher == null)
			return false;
		bool taken = false;
		int i = 0;
		while (i < drops.Length)
		{
			let first = drops[i];
			let paths = scope List<StringView>();
			int j = i;
			for (; (j < drops.Length) && (drops[j].Window == first.Window) && (drops[j].X == first.X) && (drops[j].Y == first.Y); j++)
				paths.Add(drops[j].Path);
			// A drop the OS names no window for (0) is taken as this one's.
			if ((windowId == 0) || (first.Window == windowId) || (first.Window == 0))
				taken = mDispatcher.InjectFileDrop(ToContent(.(first.X, first.Y)), paths) || taken;
			i = j;
		}
		return taken;
	}

	/// Reconcile the target window's text-input state with the focused node's wish. Called
	/// automatically from Dispatch()/PumpFromSurface(); exposed for apps that drive focus by other
	/// means.
	public void SyncTextInput()
	{
		if ((mTextInputTarget == null) || (mDispatcher == null))
			return;
		let want = mDispatcher.WantsTextInput;
		let kind = mDispatcher.IsTextInputSecret ? Sedulous.Shell.TextInputKind.Secret : Sedulous.Shell.TextInputKind.Text;
		if (want && (!mTextInputTarget.IsTextInputActive || (mTextInputTarget.ActiveTextInputKind != kind)))
			mTextInputTarget.StartTextInput(kind); // a move between a field and a password switches kind
		else if (!want && mTextInputTarget.IsTextInputActive)
			mTextInputTarget.StopTextInput();
		SyncTextInputArea();
	}

	/// Tells the window where the focused field types (its line, the caret across it), in window
	/// coordinates, when that moved: the IME shows its candidates beside it.
	public void SyncTextInputArea()
	{
		if (!mDispatcher.GetTextInputArea(let area, let caretX))
			return;
		Float2 a = .(area.X, area.Y);
		Float2 b = .(area.X + area.Width, area.Y + area.Height);
		Float2 caret = .(area.X + caretX, area.Y);
		if (mHasFit)
		{
			a = mFit.FromContent(a);
			b = mFit.FromContent(b);
			caret = mFit.FromContent(caret);
		}
		int32[5] shown = .((int32)Math.Min(a.X, b.X), (int32)Math.Min(a.Y, b.Y),
			(int32)(Math.Abs(b.X - a.X) + 0.5f), (int32)(Math.Abs(b.Y - a.Y) + 0.5f),
			(int32)(caret.X - Math.Min(a.X, b.X)));
		bool same = true;
		for (int i = 0; i < 5; i++)
			same = same && (shown[i] == mTextInputArea[i]);
		if (same)
			return;
		for (int i = 0; i < 5; i++)
			mTextInputArea[i] = shown[i];
		mTextInputTarget.SetTextInputArea(shown[0], shown[1], shown[2], shown[3], shown[4]);
	}

	/// Translate one platform input event into a dispatcher injection. Returns true if the GUI
	/// used it (a handler took it, or the pointer is over a node that takes it), so a game host
	/// leaves it alone; false if the GUI did not (or the event is not routed: an unmapped button,
	/// or SDL's mouse copy of a finger, which the touch events already brought). Reconciles text
	/// input and the cursor afterwards, since a routed event (a click, a Tab) can change focus and
	/// what is under the pointer.
	public bool Dispatch(Sedulous.Shell.InputEvent event)
	{
		if (mDispatcher == null)
			return false;
		bool routed = true;
		switch (event.Kind)
		{
		case .MouseMove:
			{
				let at = ToContent(.(event.X, event.Y));
				routed = !IsTouchCopy(at) && mDispatcher.InjectMouseMove(at, MapModifiers(event.Modifiers));
			}
		case .MouseButtonDown:
			{
				let at = ToContent(.(event.X, event.Y));
				routed = !IsTouchCopy(at) && mDispatcher.InjectMouseDown(at, MapButton(event.Button), MapModifiers(event.Modifiers));
			}
		case .MouseButtonUp:
			{
				let at = ToContent(.(event.X, event.Y));
				routed = !IsTouchCopy(at) && mDispatcher.InjectMouseUp(at, MapButton(event.Button), MapModifiers(event.Modifiers));
			}
		case .TouchDown, .TouchMove, .TouchUp:
			{
				if ((mWindowSize.X <= 0.0f) || (mWindowSize.Y <= 0.0f))
					routed = false; // no window size: a finger cannot be placed
				else
				{
					let at = ToContent(.(event.X * mWindowSize.X, event.Y * mWindowSize.Y));
					routed = ForwardTouch(event.Kind, event.TouchId, at);
				}
			}
		case .TouchCancel:
			routed = mDispatcher.InjectTouchCancel(event.TouchId);
		case .PinchBegin:
			routed = mDispatcher.InjectPinch(.GestureStart, 1.0f);
		case .PinchUpdate:
			routed = mDispatcher.InjectPinch(.GestureChange, event.Value);
		case .PinchEnd:
			routed = mDispatcher.InjectPinch(.GestureEnd, 1.0f);
		case .MouseWheel:
			// For wheel, X/Y is the scroll delta; position is the last known cursor spot.
			routed = mDispatcher.InjectMouseWheel(mDispatcher.MousePosition, .(event.X, event.Y), MapModifiers(event.Modifiers));
		case .KeyDown:
			routed = mDispatcher.InjectKeyDown(MapKey(event.Key), MapModifiers(event.Modifiers));
		case .KeyUp:
			routed = mDispatcher.InjectKeyUp(MapKey(event.Key), MapModifiers(event.Modifiers));
		case .TextInput:
			{
				// A copy: the text is a fixed array inside a by-value parameter.
				var copy = event;
				routed = mDispatcher.InjectText(StringView(&copy.Text[0]));
			}
		case .TextEditing:
			{
				var copy = event;
				routed = mDispatcher.InjectComposition(StringView(&copy.Text[0]), event.EditCursor);
			}
		case .GamepadButtonDown, .GamepadButtonUp:
			routed = DispatchPadButton(event.PadButton, event.Kind == .GamepadButtonDown);
		case .GamepadAxis:
			routed = DispatchStick(event.PadAxis, event.Value);
		default:
			routed = false;
		}
		SyncTextInput();
		SyncCursor();
		return routed;
	}

	/// Poll a gated InputSurface (its mouse is already content-space) and drive the dispatcher:
	/// hover from the cursor, click from press/release edges, plus wheel. The recommended path for
	/// a viewport-hosted GUI - the surface handles transform + gating, and a fresh InjectMouseMove
	/// each frame keeps hover current. (Keyboard/text still come through the event-based
	/// Dispatch() path.)
	public void PumpFromSurface(Sedulous.Shell.InputSurface surface)
	{
		PumpDevices(surface.Mouse, surface.Touch, surface.Keyboard);
	}

	/// PumpFromSurface's poll from devices however they come (an engine's active input source,
	/// already in content space): the fingers, the mouse, its buttons' edges and its wheel;
	/// `keyboard` gives the modifiers. Any may be null.
	public void PumpDevices(Sedulous.Shell.IMouse mouse, Sedulous.Shell.ITouch touch, Sedulous.Shell.IKeyboard keyboard)
	{
		if (mDispatcher == null)
			return;
		// Fingers first (in the mouse's coordinates): the first one down drives the pointer; it
		// went down, moved or lifted since the last pump.
		if (touch != null)
			PumpTouch(touch);
		if (mouse == null)
		{
			SyncTextInput();
			SyncCursor();
			return;
		}

		let position = Float2(mouse.X, mouse.Y);
		if (IsTouchCopy(position))
		{
			SyncTextInput();
			SyncCursor();
			return; // the mouse is SDL's copy of a finger this frame
		}
		// Current keyboard modifiers, so a modified click or drag (Shift+click to extend a text
		// selection, a Shift drag scrubbing finer) carries them even on the poll-based path.
		let modifiers = (keyboard != null) ? MapModifiers(keyboard.Modifiers) : 0;
		mDispatcher.InjectMouseMove(position, modifiers);

		Sedulous.Shell.MouseButton[3] buttons = .(.Left, .Middle, .Right);
		for (let button in buttons)
		{
			if (mouse.IsButtonPressed(button))
				mDispatcher.InjectMouseDown(position, MapButton(button), modifiers);
			if (mouse.IsButtonReleased(button))
				mDispatcher.InjectMouseUp(position, MapButton(button), modifiers);
		}

		let scrollX = mouse.ScrollX;
		let scrollY = mouse.ScrollY;
		if ((scrollX != 0.0f) || (scrollY != 0.0f))
			mDispatcher.InjectMouseWheel(position, .(scrollX, scrollY), modifiers);

		SyncTextInput(); // a click this frame may have focused (or blurred) an editable widget
		SyncCursor();
	}

	/// Whether the pointer is over the GUI now (a node that takes it), for a host that polls.
	public bool IsPointerOverGui => (mDispatcher != null) && mDispatcher.IsPointerOver(mDispatcher.MousePosition);

	private Float2 ToContent(Float2 windowPos)
	{
		if (!mHasFit)
			return windowPos;
		mFit.ToContent(windowPos, let result); // set regardless
		return result;
	}

	// A finger's event to the dispatcher, remembering where it was for IsTouchCopy.
	private bool ForwardTouch(Sedulous.Shell.InputEventKind kind, uint64 finger, Float2 at)
	{
		mTouchSeen = true;
		mLastTouchAt = at;
		switch (kind)
		{
		case .TouchDown: return mDispatcher.InjectTouchDown(finger, at);
		case .TouchMove: return mDispatcher.InjectTouchMove(finger, at);
		default: return mDispatcher.InjectTouchUp(finger, at);
		}
	}

	// The polled fingers against the ones last seen: down when one appears, moves while it stays,
	// up when it is gone (every finger: two make a gesture).
	private void PumpTouch(Sedulous.Shell.ITouch touch)
	{
		let now = scope List<PumpedFinger>();
		for (int32 i = 0; i < touch.TouchCount; i++)
		{
			if (touch.GetTouchPoint(i, let point))
				now.Add(.(point.Id, .(point.PointerX, point.PointerY)));
		}
		for (let was in mPumpedFingers)
		{
			bool stays = false;
			for (int n = 0; n < now.Count; n++)
			{
				let @is = now[n];
				stays = stays || (@is.Id == was.Id);
			}
			if (!stays)
				ForwardTouch(.TouchUp, was.Id, was.At);
		}
		for (int n = 0; n < now.Count; n++)
		{
			let @is = now[n];
			int was = -1;
			for (int f = 0; f < mPumpedFingers.Count; f++)
			{
				if (mPumpedFingers[f].Id == @is.Id)
					was = f;
			}
			if (was < 0)
				ForwardTouch(.TouchDown, @is.Id, @is.At);
			else if ((mPumpedFingers[was].At.X != @is.At.X) || (mPumpedFingers[was].At.Y != @is.At.Y))
				ForwardTouch(.TouchMove, @is.Id, @is.At);
		}
		mPumpedFingers.Clear();
		mPumpedFingers.AddRange(now);
	}

	// SDL copies a finger into mouse events by default: a mouse event while a finger is down, or
	// at the place a finger last was, is taken for that copy and ignored. The mouse moving
	// anywhere else is the mouse again.
	private bool IsTouchCopy(Float2 at)
	{
		if (!mTouchSeen)
			return false;
		if (mDispatcher.IsTouchActive)
			return true;
		let dx = at.X - mLastTouchAt.X;
		let dy = at.Y - mLastTouchAt.Y;
		if (dx * dx + dy * dy <= 4.0f)
			return true;
		mTouchSeen = false;
		return false;
	}

	// The GUI's cursor as the shell has it; the shell has no grab, help, copy or alias cursors, so
	// those take the nearest it has.
	private static Sedulous.Shell.CursorType MapCursor(Sedulous.GUI.Cursor cursor)
	{
		switch (cursor)
		{
		case .Pointer: return .Pointer;
		case .Text: return .Text;
		case .Move, .Grab, .Grabbing: return .Move;
		case .NotAllowed, .NoDrop: return .NotAllowed;
		case .Copy, .Alias: return .Pointer; // no copy or alias cursor: the preview's badge says
		case .Wait: return .Wait;
		case .Progress: return .Progress;
		case .Crosshair: return .Crosshair;
		case .EwResize: return .ResizeEW;
		case .NsResize: return .ResizeNS;
		case .NwseResize: return .ResizeNWSE;
		case .NeswResize: return .ResizeNESW;
		default: return .Default;
		}
	}

	// The shell's MouseButton order is Left/Middle/Right - map explicitly, not by value.
	private static MouseButton MapButton(Sedulous.Shell.MouseButton button)
	{
		switch (button)
		{
		case .Left: return .Left;
		case .Right: return .Right;
		case .Middle: return .Middle;
		case .X1: return .X1;
		case .X2: return .X2;
		default: return .Left;
		}
	}

	/// Map the platform key code to the GUI's platform-agnostic KeyCode (as a uint32). Every key
	/// the GUI or a binding names; text still arrives through TextInput (a key's code is for
	/// shortcuts, not for what it types).
	public static uint32 MapKey(Sedulous.Shell.KeyCode key)
	{
		KeyCode mapped = .Unknown;
		switch (key)
		{
		case .Return: mapped = .Return;
		case .Escape: mapped = .Escape;
		case .Backspace: mapped = .Backspace;
		case .Tab: mapped = .Tab;
		case .Space: mapped = .Space;
		case .Delete: mapped = .Delete;
		case .Insert: mapped = .Insert;
		case .Home: mapped = .Home;
		case .End: mapped = .End;
		case .PageUp: mapped = .PageUp;
		case .PageDown: mapped = .PageDown;
		case .Left: mapped = .Left;
		case .Right: mapped = .Right;
		case .Up: mapped = .Up;
		case .Down: mapped = .Down;
		default:
			// Letters, digits and F1 to F12: the editing shortcuts and every binding.
			let k = (uint32)key;
			if ((k >= (uint32)Sedulous.Shell.KeyCode.A) && (k <= (uint32)Sedulous.Shell.KeyCode.Z))
				mapped = sLetterKeys[(int)(k - (uint32)Sedulous.Shell.KeyCode.A)];
			else if ((k >= (uint32)Sedulous.Shell.KeyCode.Num0) && (k <= (uint32)Sedulous.Shell.KeyCode.Num9))
				mapped = (KeyCode)((uint32)KeyCode.Num0 + (k - (uint32)Sedulous.Shell.KeyCode.Num0));
			else if ((k >= (uint32)Sedulous.Shell.KeyCode.F1) && (k <= (uint32)Sedulous.Shell.KeyCode.F12))
				mapped = (KeyCode)((uint32)KeyCode.F1 + (k - (uint32)Sedulous.Shell.KeyCode.F1));
			else if (key == .Menu)
				mapped = .Menu;
			else
				mapped = MapKeyRange(key);
		}
		return (uint32)mapped;
	}

	// The rest of the keyboard: runs of keys the shell and the GUI list in the same order.
	private static KeyCode MapKeyRange(Sedulous.Shell.KeyCode key)
	{
		Run[5] runs = .(
			Run(.F13, .F24, .F13),
			Run(.Minus, .Slash, .Minus),
			Run(.CapsLock, .Pause, .CapsLock),
			Run(.Keypad0, .KeypadDecimal, .Keypad0),
			Run(.LeftCtrl, .RightGui, .LeftCtrl));
		// Each run as long on both sides (a key added to one list breaks the build, not the map).
		Compiler.Assert((uint32)Sedulous.Shell.KeyCode.F24 - (uint32)Sedulous.Shell.KeyCode.F13 == (uint32)KeyCode.F24 - (uint32)KeyCode.F13);
		Compiler.Assert((uint32)Sedulous.Shell.KeyCode.Slash - (uint32)Sedulous.Shell.KeyCode.Minus == (uint32)KeyCode.Slash - (uint32)KeyCode.Minus);
		Compiler.Assert((uint32)Sedulous.Shell.KeyCode.Pause - (uint32)Sedulous.Shell.KeyCode.CapsLock == (uint32)KeyCode.Pause - (uint32)KeyCode.CapsLock);
		Compiler.Assert((uint32)Sedulous.Shell.KeyCode.KeypadDecimal - (uint32)Sedulous.Shell.KeyCode.Keypad0 == (uint32)KeyCode.KeypadDecimal - (uint32)KeyCode.Keypad0);
		Compiler.Assert((uint32)Sedulous.Shell.KeyCode.RightGui - (uint32)Sedulous.Shell.KeyCode.LeftCtrl == (uint32)KeyCode.RightSuper - (uint32)KeyCode.LeftCtrl);
		let k = (uint32)key;
		for (let run in runs)
		{
			if ((k >= (uint32)run.First) && (k <= (uint32)run.Last))
				return (KeyCode)((uint32)run.To + (k - (uint32)run.First));
		}
		return .Unknown;
	}

	// A gamepad: the d-pad holds a direction (focus moves, then repeats); the face, shoulder and
	// menu buttons are keystrokes for the keymap (South activates when unbound).
	private bool DispatchPadButton(Sedulous.Shell.GamepadButton button, bool down)
	{
		NavDirection direction = .Up;
		bool isDirection = true;
		switch (button)
		{
		case .DPadUp: direction = .Up;
		case .DPadDown: direction = .Down;
		case .DPadLeft: direction = .Left;
		case .DPadRight: direction = .Right;
		default: isDirection = false;
		}
		if (isDirection)
		{
			if (down)
				mDispatcher.PressDirection(direction);
			else
				mDispatcher.ReleaseDirection(direction);
			return true;
		}
		if (!down)
			return true;
		PadButton pad = .South;
		if (!MapPadButton(button, out pad))
			return false;
		mDispatcher.InjectPadButton(pad);
		return true;
	}

	// The left stick as a d-pad: past half way it holds a direction, back under a third it lets go
	// (the gap keeps a stick resting near the threshold from chattering). The right stick scrolls.
	private bool DispatchStick(Sedulous.Shell.GamepadAxis axis, float value)
	{
		// The right stick scrolls the nearest scroller around the focus (the dispatcher's).
		if ((axis == .RightX) || (axis == .RightY))
		{
			var stick = mDispatcher.ScrollStick;
			if (axis == .RightX)
				stick.X = value;
			else
				stick.Y = value;
			mDispatcher.ScrollStick = stick;
			return true;
		}
		if ((axis != .LeftX) && (axis != .LeftY))
			return false;
		let horizontal = axis == .LeftX;
		var held = horizontal ? mStickX : mStickY; // -1, 0, +1
		int32 now = (value > cStickPress) ? 1 : (value < -cStickPress) ? -1 : ((Math.Abs(value) < cStickRelease) ? 0 : held);
		if (now == held)
			return true;
		if (held != 0)
			mDispatcher.ReleaseDirection(DirectionOf(horizontal, held));
		held = now;
		if (horizontal)
			mStickX = held;
		else
			mStickY = held;
		if (held != 0)
			mDispatcher.PressDirection(DirectionOf(horizontal, held));
		return true;
	}

	private static NavDirection DirectionOf(bool horizontal, int32 sign)
	{
		return horizontal ? ((sign > 0) ? .Right : .Left) : ((sign > 0) ? .Down : .Up);
	}

	/// A shell gamepad button as a keystroke's pad button; false for the d-pad and the rest.
	public static bool MapPadButton(Sedulous.Shell.GamepadButton button, out PadButton outPad)
	{
		outPad = .South;
		switch (button)
		{
		case .South: outPad = .South; return true;
		case .East: outPad = .East; return true;
		case .West: outPad = .West; return true;
		case .North: outPad = .North; return true;
		case .Start: outPad = .Start; return true;
		case .Back: outPad = .Back; return true;
		case .LeftShoulder: outPad = .LeftShoulder; return true;
		case .RightShoulder: outPad = .RightShoulder; return true;
		default: return false;
		}
	}

	public static uint32 MapModifiers(Sedulous.Shell.KeyModifiers mods)
	{
		uint32 result = 0;
		// HasAny, not HasFlag: Shift is both shift bits, and either one alone is a Shift.
		if (mods.HasAny(.Shift))
			result |= KeyModShift;
		if (mods.HasAny(.Ctrl))
			result |= KeyModCtrl;
		if (mods.HasAny(.Alt))
			result |= KeyModAlt;
		if (mods.HasAny(.Gui))
			result |= KeyModSuper;
		return result;
	}
}

/// One action of the game's input map and what it does in the GUI. Views: the caller keeps the
/// text alive while it is used.
struct InputMapCommand
{
	/// Its name in the input map ("Back", "Confirm").
	public StringView Action;
	/// The command it runs.
	public StringView Command;
	/// Where (a key-context predicate; empty: everywhere).
	public StringView Context;
	/// The action set to read it from (empty: any).
	public StringView Set;

	public this(StringView action, StringView command)
	{
		Action = action;
		Command = command;
		Context = default;
		Set = default;
	}

	public this(StringView action, StringView command, StringView context, StringView set)
	{
		Action = action;
		Command = command;
		Context = context;
		Set = set;
	}
}

static
{
	/// Binds, in `keymap`, each of `actions` to the keys and gamepad buttons the game's input map
	/// gives it, so the menu's Back is the player's Back, rebinding included: Escape and the East
	/// button by default. How many bindings it made.
	public static uint32 BindFromInputMap(Keymap keymap, Sedulous.Input.InputMap map, Span<InputMapCommand> actions)
	{
		uint32 made = 0;
		for (let wanted in actions)
		{
			for (let set in map.Sets)
			{
				if ((wanted.Set.Length != 0) && (set.Name != wanted.Set))
					continue;
				for (let action in set.Actions)
				{
					if (action.Name != wanted.Action)
						continue;
					for (let binding in action.Bindings)
					{
						Keystroke stroke = .();
						if (binding.Source == .Key)
						{
							stroke.Code = GuiInputBridge.MapKey((Sedulous.Shell.KeyCode)binding.Code);
							stroke.Modifiers = GuiInputBridge.MapModifiers((Sedulous.Shell.KeyModifiers)binding.Modifiers);
							if (stroke.Code == (uint32)KeyCode.Unknown)
								continue;
						}
						else if (binding.Source == .GamepadButton)
						{
							PadButton pad = .South;
							if (!GuiInputBridge.MapPadButton((Sedulous.Shell.GamepadButton)binding.Code, out pad))
								continue;
							stroke = Keystroke((uint32)pad, 0, true);
						}
						else
						{
							continue; // axes, mouse and touch are not keystrokes
						}
						if (keymap.Bind(stroke, wanted.Command, wanted.Context))
							made++;
					}
				}
			}
		}
		return made;
	}
}

/// Adapts the platform shell's process-global text clipboard to the GUI core's abstract
/// IClipboard seam. The app constructs one over its shell and hands it to the dispatcher once
/// (dispatcher.Clipboard = clipboard); TextField cut/copy/paste then reach the OS clipboard with no
/// further wiring. Mirrors how the null shell's in-memory clipboard backs headless tests. The
/// shell is borrowed.
class ShellClipboard : IClipboard
{
	private Sedulous.Shell.IShell mShell; // borrowed

	public this(Sedulous.Shell.IShell shell)
	{
		mShell = shell;
	}

	public bool HasText => (mShell != null) && mShell.HasClipboardText;

	public void GetText(String outText)
	{
		if (mShell == null)
			return;
		// Through a copy: a shell may replace what it is handed, and this appends.
		let text = scope String();
		mShell.GetClipboardText(text);
		outText.Append(text);
	}

	public void SetText(StringView text)
	{
		if (mShell != null)
			mShell.SetClipboardText(text);
	}
}
