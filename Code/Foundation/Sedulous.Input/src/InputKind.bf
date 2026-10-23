using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Input;

/// The kind of input the player is using now.
///
/// A game shows a button prompt for the device in hand, hides the cursor on a pad and the
/// focus ring under a mouse. None of that needs a GUI (a prompt in the 3D world), so the
/// tracker lives here, beside the actions, and a GUI's host passes its kind on.
enum InputKind : uint8
{
	/// The mouse, or a finger.
	case Pointer;
	case Keyboard;
	case Pad;

	/// The name a sheet or a script uses for it: "pointer", "keyboard" or "pad".
	public StringView Name
	{
		get
		{
			switch (this)
			{
			case .Keyboard: return "keyboard";
			case .Pad: return "pad";
			case .Pointer: return "pointer";
			}
		}
	}
}

/// Follows the kind of input in use from deliberate input only, so a resting stick or a
/// nudged desk does not flip it: a key pressed, a mouse button pressed, the mouse moved past a
/// few pixels or its wheel turned, a finger put down, a pad button pressed, a stick or trigger
/// pushed past the press point from inside it (a fresh push: one held there does not count
/// again, as Godot counts a stick only on its press).
///
/// When a frame has several, a press outranks motion, and a pad outranks the keyboard, the
/// keyboard the mouse. No reference engine tracks this; Godot shows the focus ring on
/// navigation and hides it on a pointer press, which is the rule a GUI builds on it.
class InputKindTracker
{
	private struct Entry
	{
		public delegate void(InputKind) Callback;
		public uint32 Token;
		public bool Removed;
	}

	/// A pad's analog inputs at the last frame, one bit each: the two sticks, then the two
	/// triggers.
	private const int cAnalogCount = 4;

	private InputKind mKind = .Pointer;
	private float mStickThreshold = ActionRuntime.cPressPoint;
	private float mPointerThreshold = 3.0f;
	/// Per pad: its analog inputs past the threshold at the last frame.
	private List<uint32> mPadAnalog = new .() ~ delete _;
	private int32 mFingers = 0;
	private List<Entry> mListeners = new .() ~ { for (let entry in _) delete entry.Callback; delete _; };
	private uint32 mNextToken = 0;
	private bool mNotifying = false;

	public InputKind Kind => mKind;

	/// Reads this frame's input from `devices` (after the shell's pump, once a frame) and
	/// changes the kind when deliberate input of another kind came, telling the listeners.
	public void Update(IInputSourceProvider devices)
	{
		if (Observe(devices) case .Ok(let seen))
			SetKind(seen);
	}

	/// Sets the kind (a host starting on a pad, a test); listeners hear a change.
	public void SetKind(InputKind kind)
	{
		if (kind == mKind)
			return;
		mKind = kind;
		mNotifying = true;
		for (int i < mListeners.Count)
		{
			if (!mListeners[i].Removed)
				mListeners[i].Callback(kind);
		}
		mNotifying = false;
		for (int i = 0; i < mListeners.Count;)
		{
			if (mListeners[i].Removed)
			{
				delete mListeners[i].Callback;
				mListeners.RemoveAt(i);
			}
			else
				i++;
		}
	}

	/// Told each change of kind; the tracker OWNS the delegate. Returns a token for
	/// RemoveListener.
	public uint32 AddListener(delegate void(InputKind) listener)
	{
		mListeners.Add(.() { Callback = listener, Token = ++mNextToken, Removed = false });
		return mNextToken;
	}

	/// False when the token is none of its. One removed from inside a listener goes once they
	/// return.
	public bool RemoveListener(uint32 token)
	{
		for (int i < mListeners.Count)
		{
			if ((mListeners[i].Token != token) || mListeners[i].Removed)
				continue;
			if (mNotifying)
				mListeners[i].Removed = true;
			else
			{
				delete mListeners[i].Callback;
				mListeners.RemoveAt(i);
			}
			return true;
		}
		return false;
	}

	/// How far a stick or a trigger must be pushed to count (0.5, the actions' press point).
	public float StickThreshold
	{
		get => mStickThreshold;
		set => mStickThreshold = Math.Clamp(value, 0.0f, 1.0f);
	}

	/// How far the mouse must move in a frame to count, in its pixels (3).
	public float PointerThreshold
	{
		get => mPointerThreshold;
		set => mPointerThreshold = Math.Max(0.0f, value);
	}

	private Result<InputKind> Observe(IInputSourceProvider devices)
	{
		// A finger put down (read every frame, so the count stays current whatever wins).
		bool fingerDown = false;
		if (let touch = devices.Touch)
		{
			let fingers = touch.TouchCount;
			fingerDown = fingers > mFingers;
			mFingers = fingers;
		}

		bool pad = false;
		let pads = devices.GamepadCount;
		while (mPadAnalog.Count < pads)
			mPadAnalog.Add(0);
		for (int32 p < pads)
		{
			let gamepad = devices.GetGamepad(p);
			if ((gamepad == null) || !gamepad.Connected)
			{
				mPadAnalog[p] = 0;
				continue;
			}
			for (uint32 code < (uint32)GamepadButton.Count)
				pad = pad || gamepad.IsButtonPressed((GamepadButton)code);
			float[cAnalogCount] magnitudes = .(
				Length(gamepad.Axis(.LeftX), gamepad.Axis(.LeftY)),
				Length(gamepad.Axis(.RightX), gamepad.Axis(.RightY)),
				gamepad.Axis(.LeftTrigger),
				gamepad.Axis(.RightTrigger));
			uint32 now = 0;
			for (int i < cAnalogCount)
			{
				if (magnitudes[i] > mStickThreshold)
					now |= 1u << i;
			}
			// Pushed past it this frame, not held there.
			pad = pad || ((now & ~mPadAnalog[p]) != 0);
			mPadAnalog[p] = now;
		}
		if (pad)
			return .Ok(.Pad);

		if (let keyboard = devices.Keyboard)
		{
			for (uint32 code = 1; code < (uint32)KeyCode.Count; code++)
			{
				if (keyboard.IsKeyPressed((KeyCode)code))
					return .Ok(.Keyboard);
			}
		}

		bool pointer = fingerDown;
		if (let mouse = devices.Mouse)
		{
			for (uint32 code < (uint32)MouseButton.Count)
				pointer = pointer || mouse.IsButtonPressed((MouseButton)code);
			let dx = mouse.DeltaX;
			let dy = mouse.DeltaY;
			pointer = pointer || (dx * dx + dy * dy > mPointerThreshold * mPointerThreshold)
				|| (mouse.ScrollX != 0.0f) || (mouse.ScrollY != 0.0f);
		}
		if (pointer)
			return .Ok(.Pointer);
		return .Err;
	}

	private static float Length(float x, float y) => Math.Sqrt(x * x + y * y);
}
