using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// Every input device for a canvas, fed by the browser's HTML5 listeners.
///
/// Keys are listened for on the WINDOW and pointers on the CANVAS. That split is deliberate: a
/// canvas only receives key events while it holds DOM focus, which it loses to any other
/// element on the page, whereas the pointer must not fire for clicks outside the canvas.
///
/// The listeners do not touch the devices. They queue, and Update drains the queue once a
/// frame, so a frame reads one coherent snapshot. See WebRawEvent.
class WebInputManager : IInputManager
{
	private const int cMaxGamepads = 4;

	private WebKeyboard mKeyboard = new .() ~ delete _;
	private WebMouse mMouse = new .() ~ delete _;
	private WebTouch mTouch = new .() ~ delete _;
	private WebGamepad[cMaxGamepads] mSlots = .(null, null, null, null);
	private List<IGamepad> mConnected = new .() ~ delete _;

	private List<WebRawEvent> mQueue = new .() ~ delete _;
	private List<InputEvent> mEvents = new .() ~ delete _;

	private String mSelector = new .() ~ delete _;
	private uint32 mMainWindow;
	private float mPointerScaleX = 1.0f;
	private float mPointerScaleY = 1.0f;

	public this()
	{
		for (int i < cMaxGamepads)
			mSlots[i] = new WebGamepad();
	}

	public ~this()
	{
		for (int i < cMaxGamepads)
			delete mSlots[i];
	}

	public IKeyboard Keyboard => mKeyboard;
	public IMouse Mouse => mMouse;
	public ITouch Touch => mTouch;

	public int32 GamepadCount => (int32)mConnected.Count;

	public IGamepad GetGamepad(int32 index)
	{
		if ((index < 0) || (index >= (int32)mConnected.Count))
			return null;
		return mConnected[index];
	}

	public Span<InputEvent> Events => .(mEvents.Ptr, mEvents.Count);

	/// One canvas, so whatever is hovered or focused is that window.
	public uint32 HoverWindow => mMainWindow;
	public uint32 FocusedWindow => mMainWindow;

	/// Wires the listeners to the page. Called once by the shell, after the canvas exists.
	public void RegisterCallbacks(StringView selector, uint32 mainWindowId)
	{
		mMainWindow = mainWindowId;
		mSelector.Set(selector);

#if BF_PLATFORM_WASM
		let self = Internal.UnsafeCastToPtr(this);
		let canvas = mSelector.CStr();
		let window = EmscriptenHtml5.TargetWindow;

		EmscriptenHtml5.emscripten_set_keydown_callback_on_thread(window, self, false, => OnKey,
			EmscriptenHtml5.PthreadMain);
		EmscriptenHtml5.emscripten_set_keyup_callback_on_thread(window, self, false, => OnKey,
			EmscriptenHtml5.PthreadMain);

		EmscriptenHtml5.emscripten_set_mousemove_callback_on_thread(canvas, self, false,
			=> OnMouseMove, EmscriptenHtml5.PthreadMain);
		EmscriptenHtml5.emscripten_set_mousedown_callback_on_thread(canvas, self, false,
			=> OnMouseButton, EmscriptenHtml5.PthreadMain);
		EmscriptenHtml5.emscripten_set_mouseup_callback_on_thread(canvas, self, false,
			=> OnMouseButton, EmscriptenHtml5.PthreadMain);
		EmscriptenHtml5.emscripten_set_wheel_callback_on_thread(canvas, self, false, => OnWheel,
			EmscriptenHtml5.PthreadMain);

		EmscriptenHtml5.emscripten_set_touchstart_callback_on_thread(canvas, self, false,
			=> OnTouch, EmscriptenHtml5.PthreadMain);
		EmscriptenHtml5.emscripten_set_touchmove_callback_on_thread(canvas, self, false,
			=> OnTouch, EmscriptenHtml5.PthreadMain);
		EmscriptenHtml5.emscripten_set_touchend_callback_on_thread(canvas, self, false,
			=> OnTouch, EmscriptenHtml5.PthreadMain);
		EmscriptenHtml5.emscripten_set_touchcancel_callback_on_thread(canvas, self, false,
			=> OnTouch, EmscriptenHtml5.PthreadMain);

		// Focus loss, so keys and buttons held when the page goes away do not stay held.
		EmscriptenHtml5.emscripten_set_blur_callback_on_thread(window, self, false, => OnBlur,
			EmscriptenHtml5.PthreadMain);

		// Gamepads are POLLED in Update: a browser reveals a pad only after the user presses
		// something on it, so there is nothing to register for.
#endif
	}

	/// Rolls the frame, then applies everything the browser queued since the last one.
	public void Update()
	{
		RefreshPointerScale();

		mKeyboard.BeginFrame();
		mMouse.BeginFrame();
		for (int i < cMaxGamepads)
			mSlots[i].BeginFrame();

		mEvents.Clear();
		for (let raw in mQueue)
			Apply(raw);
		mQueue.Clear();

		PollGamepads();
	}

	/// The CSS pixel to backing pixel scale for pointer coordinates.
	///
	/// Pointer events report CSS pixels while the window reports the canvas's BACKING size, and
	/// on any display with a device pixel ratio above one those differ. Unscaled, every click
	/// lands at a fraction of where it looks. Derived from the two live sizes rather than from
	/// the ratio, so whatever policy sized the backing store is honoured automatically.
	private void RefreshPointerScale()
	{
		mPointerScaleX = 1.0f;
		mPointerScaleY = 1.0f;

#if BF_PLATFORM_WASM
		if (mSelector.IsEmpty)
			return;

		let canvas = mSelector.CStr();
		double cssWidth = 0.0;
		double cssHeight = 0.0;
		int32 backingWidth = 0;
		int32 backingHeight = 0;

		if ((EmscriptenHtml5.emscripten_get_element_css_size(canvas, &cssWidth, &cssHeight)
				!= .Success)
			|| (EmscriptenHtml5.emscripten_get_canvas_element_size(canvas, &backingWidth,
				&backingHeight) != .Success))
			return;

		if ((cssWidth > 0.0) && (backingWidth > 0))
			mPointerScaleX = (float)((double)backingWidth / cssWidth);
		if ((cssHeight > 0.0) && (backingHeight > 0))
			mPointerScaleY = (float)((double)backingHeight / cssHeight);
#endif
	}

	private void Apply(WebRawEvent raw)
	{
		switch (raw.Type)
		{
		case .Key:
			mKeyboard.SetKey(raw.Key, raw.Down);
			mKeyboard.SetModifiers(raw.Modifiers);

			InputEvent key = .();
			key.Kind = raw.Down ? .KeyDown : .KeyUp;
			key.Window = mMainWindow;
			key.Key = raw.Key;
			key.Modifiers = raw.Modifiers;
			mEvents.Add(key);

		case .MouseMove:
			let x = raw.X * mPointerScaleX;
			let y = raw.Y * mPointerScaleY;
			let dx = raw.DX * mPointerScaleX;
			let dy = raw.DY * mPointerScaleY;
			mMouse.OnMotion(x, y, dx, dy);

			InputEvent move = .();
			move.Kind = .MouseMove;
			move.Window = mMainWindow;
			move.X = x;
			move.Y = y;
			move.DX = dx;
			move.DY = dy;
			mEvents.Add(move);

		case .MouseButton:
			mMouse.OnButton(raw.Button, raw.Down);

			InputEvent button = .();
			button.Kind = raw.Down ? .MouseButtonDown : .MouseButtonUp;
			button.Window = mMainWindow;
			button.Button = raw.Button;
			mEvents.Add(button);

		case .Wheel:
			mMouse.OnWheel(raw.ScrollX, raw.ScrollY);

			InputEvent wheel = .();
			wheel.Kind = .MouseWheel;
			wheel.Window = mMainWindow;
			wheel.X = raw.ScrollX;
			wheel.Y = raw.ScrollY;
			mEvents.Add(wheel);

		case .Touch:
			let touchX = raw.X * mPointerScaleX;
			let touchY = raw.Y * mPointerScaleY;
			if (raw.Phase == .End)
				mTouch.Remove(raw.TouchId);
			else
				mTouch.Upsert(raw.TouchId, touchX, touchY);

			InputEvent touch = .();
			touch.Kind = (raw.Phase == .Start) ? .TouchDown
				: ((raw.Phase == .Move) ? .TouchMove : .TouchUp);
			touch.Window = mMainWindow;
			touch.TouchId = raw.TouchId;
			touch.X = touchX;
			touch.Y = touchY;
			mEvents.Add(touch);
		}
	}

	/// Rebuilds the connected list and emits this frame's button transitions.
	private void PollGamepads()
	{
		mConnected.Clear();

#if BF_PLATFORM_WASM
		EmscriptenHtml5.emscripten_sample_gamepad_data();
		let reported = EmscriptenHtml5.emscripten_get_num_gamepads();
		// NEGATIVE means the browser has no Gamepad API at all, which is not zero pads.
		if (reported < 0)
			return;

		let count = Math.Min((int)reported, cMaxGamepads);
		for (int i < count)
		{
			EmscriptenGamepadEvent state = .();
			if ((EmscriptenHtml5.emscripten_get_gamepad_status((int32)i, &state) != .Success)
				|| !state.Connected)
			{
				mSlots[i].SetDisconnected();
				continue;
			}

			let pad = mSlots[i];
			pad.Ingest((int32)i, &state);
			mConnected.Add(pad);
			EmitGamepadTransitions(pad, (int32)i);
		}
#endif
	}

	private void EmitGamepadTransitions(WebGamepad pad, int32 index)
	{
		for (var button = GamepadButton.South; button < .Count; button++)
		{
			if (pad.IsButtonPressed(button))
			{
				InputEvent down = .();
				down.Kind = .GamepadButtonDown;
				down.Window = mMainWindow;
				down.PadButton = button;
				down.Gamepad = index;
				mEvents.Add(down);
			}
			else if (pad.IsButtonReleased(button))
			{
				InputEvent up = .();
				up.Kind = .GamepadButtonUp;
				up.Window = mMainWindow;
				up.PadButton = button;
				up.Gamepad = index;
				mEvents.Add(up);
			}
		}
	}

	// ---- the browser's listeners ----
	//
	// Plain function pointers, so the manager arrives as userData. Each one QUEUES and returns
	// false, which lets the event keep propagating: a page that wants to handle it too still
	// can, and the browser's own defaults, scrolling and text selection, are left to the page's
	// CSS rather than suppressed from here.

	private static WebInputManager FromUserData(void* userData) =>
		(WebInputManager)Internal.UnsafeCastToObject(userData);

	private static bool OnKey(int32 eventType, EmscriptenKeyboardEvent* event, void* userData)
	{
		let self = FromUserData(userData);
		let code = StringView(&event.Code[0]);

		WebRawEvent raw = .();
		raw.Type = .Key;
		raw.Key = WebKeyMap.FromDom(code);
		raw.Modifiers = WebKeyMap.Modifiers(event.CtrlKey, event.ShiftKey, event.AltKey,
			event.MetaKey);
		raw.Down = eventType == EmscriptenEventType.KeyDown;
		self.mQueue.Add(raw);
		return false;
	}

	private static bool OnMouseMove(int32 eventType, EmscriptenMouseEvent* event, void* userData)
	{
		let self = FromUserData(userData);

		WebRawEvent raw = .();
		raw.Type = .MouseMove;
		raw.X = (float)event.TargetX;
		raw.Y = (float)event.TargetY;
		raw.DX = (float)event.MovementX;
		raw.DY = (float)event.MovementY;
		self.mQueue.Add(raw);
		return false;
	}

	private static bool OnMouseButton(int32 eventType, EmscriptenMouseEvent* event, void* userData)
	{
		let self = FromUserData(userData);

		WebRawEvent raw = .();
		raw.Type = .MouseButton;
		raw.Button = FromDomButton(event.Button);
		raw.Down = eventType == EmscriptenEventType.MouseDown;
		self.mQueue.Add(raw);
		return false;
	}

	private static bool OnWheel(int32 eventType, EmscriptenWheelEvent* event, void* userData)
	{
		let self = FromUserData(userData);

		// deltaMode says what the browser COUNTED IN, and it varies by device: a trackpad
		// reports pixels and many mice report lines. Reading either as the other scrolls by
		// about a factor of sixteen.
		var scale = 1.0;
		switch (event.DeltaMode)
		{
		case EmscriptenWheelEvent.DeltaModeLine: scale = 1.0 / 16.0;
		case EmscriptenWheelEvent.DeltaModePage: scale = 1.0;
		default: scale = 1.0 / 100.0; // pixels
		}

		WebRawEvent raw = .();
		raw.Type = .Wheel;
		// Negated: the DOM counts a downward scroll POSITIVE, and every other backend here
		// reports a scroll away from the user as positive.
		raw.ScrollX = (float)(-event.DeltaX * scale);
		raw.ScrollY = (float)(-event.DeltaY * scale);
		self.mQueue.Add(raw);
		return false;
	}

	private static bool OnTouch(int32 eventType, EmscriptenTouchEvent* event, void* userData)
	{
		let self = FromUserData(userData);

		let phase = (eventType == EmscriptenEventType.TouchStart) ? WebRawEvent.TouchPhase.Start
			: ((eventType == EmscriptenEventType.TouchMove) ? WebRawEvent.TouchPhase.Move
				: WebRawEvent.TouchPhase.End);

		let count = Math.Min((int)event.NumTouches, EmscriptenTouchEvent.MaxTouches);
		for (int i < count)
		{
			// A touch event carries EVERY live finger, and only the changed ones are what it is
			// about. Acting on all of them moves fingers that did not move.
			if (!event.Touches[i].IsChanged)
				continue;

			WebRawEvent raw = .();
			raw.Type = .Touch;
			raw.TouchId = (uint64)event.Touches[i].Identifier;
			raw.X = (float)event.Touches[i].TargetX;
			raw.Y = (float)event.Touches[i].TargetY;
			raw.Phase = phase;
			self.mQueue.Add(raw);
		}
		return false;
	}

	private static bool OnBlur(int32 eventType, EmscriptenFocusEvent* event, void* userData)
	{
		// Released at once rather than queued: the browser will not send the keyup or mouseup
		// for anything held, so waiting for the next frame only delays a state that is already
		// wrong.
		let self = FromUserData(userData);
		self.mKeyboard.ReleaseAll();
		self.mMouse.ReleaseAll();
		self.mTouch.Clear();
		return false;
	}

	/// The DOM's button number. Its middle and right are the other way round from ours.
	private static MouseButton FromDomButton(uint16 button)
	{
		switch (button)
		{
		case 0: return .Left;
		case 1: return .Middle;
		case 2: return .Right;
		case 3: return .X1;
		case 4: return .X2;
		default: return .Left;
		}
	}
}
