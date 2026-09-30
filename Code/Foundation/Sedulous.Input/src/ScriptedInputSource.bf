using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Input;

/// What one timeline entry does to the virtual devices.
enum ScriptedInputKind
{
	/// A key goes down or up.
	Key,
	/// A mouse button goes down or up.
	MouseButton,
	/// The pointer moves to X, Y (window space).
	MouseMove,
	/// The wheel turns by X, Y.
	MouseWheel,
	/// A gamepad button goes down or up.
	PadButton,
	/// A gamepad axis takes Value.
	PadAxis
}

/// One entry of a scripted input timeline: at `At` seconds since the script started, a key,
/// button or axis changes. Device level on purpose: a playtest goes through the project's
/// input map the way a player does.
struct ScriptedInput
{
	public double At;
	public ScriptedInputKind Kind;
	public KeyCode Key;
	public MouseButton Button;
	public GamepadButton PadButton;
	public GamepadAxis PadAxis;
	public int32 Gamepad;
	public bool Down;
	public float X;
	public float Y;
	public float Value;
}

/// An input source driven by a timeline instead of devices: a virtual keyboard, mouse and
/// gamepads, and the event stream their changes make, for a playtest no one plays by hand.
///
/// Advance once per frame with the time since the script started: every entry due by then
/// applies in order, and the edges (pressed, released) and the events are that frame's, so
/// a press and its release landing in one frame still read as a press. Nothing real is
/// merged in: where the user's mouse is must not change a playtest.
class ScriptedInputSource : IInputSourceProvider
{
	/// The gamepads a timeline can address, 0 to 3.
	public const int32 cMaxGamepads = 4;

	private List<ScriptedInput> mTimeline = new .() ~ delete _;
	private int mNext = 0;
	private double mTime = 0;
	private ScriptedKeyboard mKeyboard = new .() ~ delete _;
	private ScriptedMouse mMouse = new .() ~ delete _;
	private ScriptedGamepad[cMaxGamepads] mPads;
	private int32 mPadCount = 0;
	private List<InputEvent> mEvents = new .() ~ delete _;

	public this()
	{
		for (int32 i < cMaxGamepads)
			mPads[i] = new .(i);
	}

	public ~this()
	{
		for (let pad in mPads)
			delete pad;
	}

	public IKeyboard Keyboard => mKeyboard;
	public IMouse Mouse => mMouse;
	/// The pads the timeline addresses: one past the highest index it names.
	public int32 GamepadCount => mPadCount;
	public IGamepad GetGamepad(int32 index) => ((index >= 0) && (index < mPadCount)) ? mPads[index] : null;
	public Span<InputEvent> Events => mEvents;

	/// The time the last Advance moved to, in seconds since the script started.
	public double Time => mTime;
	/// Every entry has applied.
	public bool Finished => mNext >= mTimeline.Count;
	public int Count => mTimeline.Count;

	/// Adds an entry, kept in time order; entries at the same time apply in the order added.
	/// Refused (false) for a gamepad index outside 0 to cMaxGamepads - 1.
	public bool Add(ScriptedInput input)
	{
		if (((input.Kind == .PadButton) || (input.Kind == .PadAxis)) && ((input.Gamepad < 0) || (input.Gamepad >= cMaxGamepads)))
			return false;
		var index = mTimeline.Count;
		while ((index > 0) && (mTimeline[index - 1].At > input.At))
			index--;
		mTimeline.Insert(index, input);
		if ((input.Kind == .PadButton) || (input.Kind == .PadAxis))
			mPadCount = Math.Max(mPadCount, input.Gamepad + 1);
		return true;
	}

	/// One frame: this frame's edges and events are cleared, then every entry due by `time`
	/// applies.
	public void Advance(double time)
	{
		mTime = time;
		mEvents.Clear();
		mKeyboard.BeginFrame();
		mMouse.BeginFrame();
		for (let pad in mPads)
			pad.BeginFrame();
		while ((mNext < mTimeline.Count) && (mTimeline[mNext].At <= time))
		{
			Apply(mTimeline[mNext]);
			mNext++;
		}
	}

	/// Lets go of everything held, as a frame of its own: a run that ends with a key down
	/// must not leave the game believing it is still held.
	public void ReleaseAll()
	{
		mEvents.Clear();
		mKeyboard.BeginFrame();
		mMouse.BeginFrame();
		for (let pad in mPads)
			pad.BeginFrame();
		for (int k < (int)KeyCode.Count)
		{
			if (mKeyboard.Down[k])
				Apply(Entry(.Key, (KeyCode)k, false));
		}
		for (int b < (int)MouseButton.Count)
		{
			if (mMouse.Down[b])
			{
				var input = ScriptedInput();
				input.Kind = .MouseButton;
				input.Button = (MouseButton)b;
				Apply(input);
			}
		}
		for (let pad in mPads)
		{
			for (int b < (int)GamepadButton.Count)
			{
				if (pad.Down[b])
				{
					var input = ScriptedInput();
					input.Kind = .PadButton;
					input.Gamepad = pad.Index;
					input.PadButton = (GamepadButton)b;
					Apply(input);
				}
			}
			for (int a < (int)GamepadAxis.Count)
			{
				if (pad.Axes[a] != 0)
				{
					var input = ScriptedInput();
					input.Kind = .PadAxis;
					input.Gamepad = pad.Index;
					input.PadAxis = (GamepadAxis)a;
					Apply(input);
				}
			}
		}
	}

	private static ScriptedInput Entry(ScriptedInputKind kind, KeyCode key, bool down)
	{
		var input = ScriptedInput();
		input.Kind = kind;
		input.Key = key;
		input.Down = down;
		return input;
	}

	private void Apply(ScriptedInput input)
	{
		var event = InputEvent();
		switch (input.Kind)
		{
		case .Key:
			if (!mKeyboard.Set(input.Key, input.Down))
				return;
			event.Kind = input.Down ? .KeyDown : .KeyUp;
			event.Key = input.Key;
			event.Modifiers = mKeyboard.Modifiers;
		case .MouseButton:
			if (!mMouse.SetButton(input.Button, input.Down))
				return;
			event.Kind = input.Down ? .MouseButtonDown : .MouseButtonUp;
			event.Button = input.Button;
			event.X = mMouse.X;
			event.Y = mMouse.Y;
		case .MouseMove:
			event.Kind = .MouseMove;
			event.DX = input.X - mMouse.X;
			event.DY = input.Y - mMouse.Y;
			mMouse.MoveTo(input.X, input.Y);
			event.X = input.X;
			event.Y = input.Y;
		case .MouseWheel:
			mMouse.Wheel(input.X, input.Y);
			event.Kind = .MouseWheel;
			event.X = input.X;
			event.Y = input.Y;
		case .PadButton:
			if (!mPads[input.Gamepad].SetButton(input.PadButton, input.Down))
				return;
			event.Kind = input.Down ? .GamepadButtonDown : .GamepadButtonUp;
			event.Gamepad = input.Gamepad;
			event.PadButton = input.PadButton;
		case .PadAxis:
			mPads[input.Gamepad].Axes[(int)input.PadAxis] = input.Value;
			event.Kind = .GamepadAxis;
			event.Gamepad = input.Gamepad;
			event.PadAxis = input.PadAxis;
			event.Value = input.Value;
		}
		mEvents.Add(event);
	}

	/// A key, mouse button, pad button or pad axis by its enum case name, case-insensitive:
	/// "D", "Space", "LeftShift"; "Left"; "South", "DPadUp"; "LeftX", "RightTrigger".
	public static bool ParseKey(StringView name, out KeyCode outKey) => ParseName<KeyCode>(name, (int)KeyCode.Count, out outKey);
	public static bool ParseMouseButton(StringView name, out MouseButton outButton) => ParseName<MouseButton>(name, (int)MouseButton.Count, out outButton);
	public static bool ParsePadButton(StringView name, out GamepadButton outButton) => ParseName<GamepadButton>(name, (int)GamepadButton.Count, out outButton);
	public static bool ParsePadAxis(StringView name, out GamepadAxis outAxis) => ParseName<GamepadAxis>(name, (int)GamepadAxis.Count, out outAxis);

	private static bool ParseName<T>(StringView name, int count, out T outValue) where T : enum
	{
		outValue = default;
		let text = scope String();
		for (int i < count)
		{
			let value = (T)i;
			text.Clear();
			value.ToString(text);
			if (StringView(text).Equals(name, true))
			{
				outValue = value;
				return true;
			}
		}
		return false;
	}
}

class ScriptedKeyboard : IKeyboard
{
	public bool[(int)KeyCode.Count] Down;
	private bool[(int)KeyCode.Count] mPressed;
	private bool[(int)KeyCode.Count] mReleased;

	public void BeginFrame()
	{
		mPressed = default;
		mReleased = default;
	}

	/// False when the key already was in that state: no edge, no event.
	public bool Set(KeyCode key, bool down)
	{
		let k = (int)key;
		if ((k <= 0) || (k >= (int)KeyCode.Count) || (Down[k] == down))
			return false;
		Down[k] = down;
		if (down)
			mPressed[k] = true;
		else
			mReleased[k] = true;
		return true;
	}

	public bool IsKeyDown(KeyCode key) => ((int)key < (int)KeyCode.Count) && Down[(int)key];
	public bool IsKeyPressed(KeyCode key) => ((int)key < (int)KeyCode.Count) && mPressed[(int)key];
	public bool IsKeyReleased(KeyCode key) => ((int)key < (int)KeyCode.Count) && mReleased[(int)key];

	public KeyModifiers Modifiers
	{
		get
		{
			KeyModifiers m = .None;
			if (Down[(int)KeyCode.LeftShift]) m |= .LeftShift;
			if (Down[(int)KeyCode.RightShift]) m |= .RightShift;
			if (Down[(int)KeyCode.LeftCtrl]) m |= .LeftCtrl;
			if (Down[(int)KeyCode.RightCtrl]) m |= .RightCtrl;
			if (Down[(int)KeyCode.LeftAlt]) m |= .LeftAlt;
			if (Down[(int)KeyCode.RightAlt]) m |= .RightAlt;
			if (Down[(int)KeyCode.LeftGui]) m |= .LeftGui;
			if (Down[(int)KeyCode.RightGui]) m |= .RightGui;
			return m;
		}
	}
}

class ScriptedMouse : IMouse
{
	public bool[(int)MouseButton.Count] Down;
	private bool[(int)MouseButton.Count] mPressed;
	private bool[(int)MouseButton.Count] mReleased;
	private float mX = 0;
	private float mY = 0;
	private float mDeltaX = 0;
	private float mDeltaY = 0;
	private float mScrollX = 0;
	private float mScrollY = 0;
	private bool mRelative = false;
	private bool mCursorVisible = true;

	public void BeginFrame()
	{
		mPressed = default;
		mReleased = default;
		mDeltaX = 0;
		mDeltaY = 0;
		mScrollX = 0;
		mScrollY = 0;
	}

	public bool SetButton(MouseButton button, bool down)
	{
		let b = (int)button;
		if ((b >= (int)MouseButton.Count) || (Down[b] == down))
			return false;
		Down[b] = down;
		if (down)
			mPressed[b] = true;
		else
			mReleased[b] = true;
		return true;
	}

	public void MoveTo(float x, float y)
	{
		mDeltaX += x - mX;
		mDeltaY += y - mY;
		mX = x;
		mY = y;
	}

	public void Wheel(float x, float y)
	{
		mScrollX += x;
		mScrollY += y;
	}

	public float X => mX;
	public float Y => mY;
	public float GlobalX => mX;
	public float GlobalY => mY;
	public float DeltaX => mDeltaX;
	public float DeltaY => mDeltaY;
	public float ScrollX => mScrollX;
	public float ScrollY => mScrollY;
	public bool IsButtonDown(MouseButton button) => ((int)button < (int)MouseButton.Count) && Down[(int)button];
	public bool IsButtonPressed(MouseButton button) => ((int)button < (int)MouseButton.Count) && mPressed[(int)button];
	public bool IsButtonReleased(MouseButton button) => ((int)button < (int)MouseButton.Count) && mReleased[(int)button];
	public bool RelativeMode => mRelative;
	public void SetRelativeMode(bool enabled) { mRelative = enabled; }
	public bool CursorVisible => mCursorVisible;
	public void SetCursorVisible(bool visible) { mCursorVisible = visible; }
	public void SetCursor(CursorType cursor) {}
	public void SetGlobalCapture(bool enabled) {}
}

class ScriptedGamepad : IGamepad
{
	private int32 mIndex;
	private String mName = new .() ~ delete _;
	public bool[(int)GamepadButton.Count] Down;
	private bool[(int)GamepadButton.Count] mPressed;
	private bool[(int)GamepadButton.Count] mReleased;
	public float[(int)GamepadAxis.Count] Axes;

	public this(int32 index)
	{
		mIndex = index;
		mName.AppendF("Scripted pad {}", index);
	}

	public void BeginFrame()
	{
		mPressed = default;
		mReleased = default;
	}

	public bool SetButton(GamepadButton button, bool down)
	{
		let b = (int)button;
		if ((b >= (int)GamepadButton.Count) || (Down[b] == down))
			return false;
		Down[b] = down;
		if (down)
			mPressed[b] = true;
		else
			mReleased[b] = true;
		return true;
	}

	public int32 Index => mIndex;
	public StringView Name => mName;
	public bool Connected => true;
	public bool IsButtonDown(GamepadButton button) => ((int)button < (int)GamepadButton.Count) && Down[(int)button];
	public bool IsButtonPressed(GamepadButton button) => ((int)button < (int)GamepadButton.Count) && mPressed[(int)button];
	public bool IsButtonReleased(GamepadButton button) => ((int)button < (int)GamepadButton.Count) && mReleased[(int)button];
	public float Axis(GamepadAxis axis) => ((int)axis < (int)GamepadAxis.Count) ? Axes[(int)axis] : 0;
	public void SetRumble(float lowFrequency, float highFrequency, uint32 durationMs) {}
}
