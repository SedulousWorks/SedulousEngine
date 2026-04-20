namespace Sedulous.UI.Shell;

using Sedulous.UI;
using Sedulous.Shell.Input;
using System;

/// Polling-based input helper for routing shell keyboard/mouse state to a UIContext.
/// Handles navigation keys, text input emulation from key codes, Ctrl/Alt shortcuts,
/// and key repeat with configurable delay/rate.
///
/// Text input emulation converts key-down events to text characters using
/// InputMapping.KeyToChar (US-layout fallback). When SDL_StartTextInput is
/// available, the OnTextInput event path is used instead.
public class UIInputHelper
{
	private typealias ShellKeyCode = Sedulous.Shell.Input.KeyCode;

	// Key repeat state
	private ShellKeyCode mHeldKey = .Unknown;
	private float mKeyHoldTime = 0;
	private float mLastRepeatTime = 0;

	// Previous frame mouse button states for edge detection.
	private bool mPrevLeftDown;
	private bool mPrevRightDown;
	private bool mPrevMiddleDown;

	// Total time for mouse down timestamps.
	private float mTotalTime;

	public float KeyRepeatDelay = 0.4f;
	public float KeyRepeatRate = 0.03f;

	private static ShellKeyCode[?] sNavigationKeys = .(
		.Tab, .Left, .Right, .Up, .Down,
		.Home, .End, .PageUp, .PageDown,
		.Backspace, .Delete, .Return, .Escape
	);

	private static ShellKeyCode[?] sCtrlShortcutKeys = .(
		.A, .C, .V, .X, .Z, .Y
	);

	private static ShellKeyCode[?] sLetterKeys = .(
		.A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M,
		.N, .O, .P, .Q, .R, .S, .T, .U, .V, .W, .X, .Y, .Z
	);

	private static ShellKeyCode[?] sPrintableKeys = .(
		.A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M,
		.N, .O, .P, .Q, .R, .S, .T, .U, .V, .W, .X, .Y, .Z,
		.Num0, .Num1, .Num2, .Num3, .Num4, .Num5, .Num6, .Num7, .Num8, .Num9,
		.Space, .Minus, .Equals, .LeftBracket, .RightBracket, .Backslash,
		.Semicolon, .Apostrophe, .Grave, .Comma, .Period, .Slash,
		.Keypad0, .Keypad1, .Keypad2, .Keypad3, .Keypad4, .Keypad5,
		.Keypad6, .Keypad7, .Keypad8, .Keypad9, .KeypadPeriod,
		.KeypadDivide, .KeypadMultiply, .KeypadMinus, .KeypadPlus
	);

	private static ShellKeyCode[?] sRepeatableKeys = .(
		.Backspace, .Delete, .Left, .Right, .Up, .Down, .Home, .End,
		.A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M,
		.N, .O, .P, .Q, .R, .S, .T, .U, .V, .W, .X, .Y, .Z,
		.Num0, .Num1, .Num2, .Num3, .Num4, .Num5, .Num6, .Num7, .Num8, .Num9,
		.Space, .Minus, .Equals, .LeftBracket, .RightBracket, .Backslash,
		.Semicolon, .Apostrophe, .Grave, .Comma, .Period, .Slash,
		.Keypad0, .Keypad1, .Keypad2, .Keypad3, .Keypad4, .Keypad5,
		.Keypad6, .Keypad7, .Keypad8, .Keypad9, .KeypadPeriod,
		.KeypadDivide, .KeypadMultiply, .KeypadMinus, .KeypadPlus
	);

	private static ShellKeyCode[?] sFunctionKeys = .(
		.F1, .F2, .F3, .F4, .F5, .F6, .F7, .F8, .F9, .F10, .F11, .F12
	);

	/// Poll all shell input and route to UIContext. Call once per frame.
	public void Update(IInputManager shellInput, UIContext context, float deltaTime)
	{
		mTotalTime += deltaTime;

		let mouse = shellInput.Mouse;
		let kb = shellInput.Keyboard;

		// Mouse input.
		if (mouse != null)
			ProcessMouseInput(mouse, context);

		// Keyboard input.
		if (kb != null)
			ProcessKeyboardInput(kb, context, deltaTime);
	}

	/// Route mouse input from a polled mouse to a UIContext.
	public void ProcessMouseInput(IMouse mouse, UIContext context)
	{
		ProcessMouseInput(mouse, context, mouse.X, mouse.Y);
	}

	/// Route mouse input with explicit override coordinates.
	/// Used for cross-window drag routing where the mouse position
	/// must be transformed to a different window's coordinate space.
	public void ProcessMouseInput(IMouse mouse, UIContext context, float overrideX, float overrideY)
	{
		// Mouse move - only when mouse actually moved.
		if (mouse.DeltaX != 0 || mouse.DeltaY != 0)
			context.InputManager.ProcessMouseMove(overrideX, overrideY);

		// Mouse button edges.
		ProcessMouseButton(mouse, context, .Left, ref mPrevLeftDown, overrideX, overrideY);
		ProcessMouseButton(mouse, context, .Right, ref mPrevRightDown, overrideX, overrideY);
		ProcessMouseButton(mouse, context, .Middle, ref mPrevMiddleDown, overrideX, overrideY);

		// Mouse wheel.
		if (mouse.ScrollX != 0 || mouse.ScrollY != 0)
			context.InputManager.ProcessMouseWheel(overrideX, overrideY, mouse.ScrollX, mouse.ScrollY);
	}

	/// Process all keyboard input from a polled keyboard and route to a UIContext.
	public void ProcessKeyboardInput(IKeyboard keyboard, UIContext context, float deltaTime)
	{
		let mods = InputMapping.MapModifiers(keyboard.Modifiers);

		// Tab -> focus navigation (not a key event).
		if (keyboard.IsKeyPressed(.Tab) && !mods.HasFlag(.Ctrl))
		{
			if (mods.HasFlag(.Shift))
				context.FocusManager.FocusPrev();
			else
				context.FocusManager.FocusNext();
		}

		// Navigation and editing keys -> KeyDown.
		for (let key in sNavigationKeys)
		{
			if (key == .Tab) continue; // handled above
			if (keyboard.IsKeyPressed(key))
				context.InputManager.ProcessKeyDown(InputMapping.MapKey(key), mods, false);
		}

		// Function keys -> KeyDown.
		for (let key in sFunctionKeys)
		{
			if (keyboard.IsKeyPressed(key))
				context.InputManager.ProcessKeyDown(InputMapping.MapKey(key), mods, false);
		}

		// Ctrl+key shortcuts -> KeyDown.
		if (mods.HasFlag(.Ctrl))
		{
			for (let key in sCtrlShortcutKeys)
			{
				if (keyboard.IsKeyPressed(key))
					context.InputManager.ProcessKeyDown(InputMapping.MapKey(key), mods, false);
			}
		}

		// Alt+letter for menu accelerators -> KeyDown.
		if (mods.HasFlag(.Alt))
		{
			for (let key in sLetterKeys)
			{
				if (keyboard.IsKeyPressed(key))
					context.InputManager.ProcessKeyDown(InputMapping.MapKey(key), mods, false);
			}
		}

		// Text input for printable keys (emulation via KeyToChar).
		if (!mods.HasFlag(.Ctrl) && !mods.HasFlag(.Alt))
		{
			for (let key in sPrintableKeys)
			{
				if (keyboard.IsKeyPressed(key))
				{
					let c = InputMapping.KeyToChar(key, mods.HasFlag(.Shift));
					if (c != '\0')
						context.InputManager.ProcessTextInput(c);
				}
			}
		}

		// Key repeat.
		HandleKeyRepeat(keyboard, context, mods, deltaTime);
	}

	// === Internal ===

	private void ProcessMouseButton(IMouse mouse, UIContext context,
		Sedulous.Shell.Input.MouseButton shellBtn, ref bool prevDown, float mx, float my)
	{
		let down = mouse.IsButtonDown(shellBtn);
		let uiBtn = InputMapping.MapMouseButton(shellBtn);

		if (down && !prevDown)
			context.InputManager.ProcessMouseDown(uiBtn, mx, my, mTotalTime);
		else if (!down && prevDown)
			context.InputManager.ProcessMouseUp(uiBtn, mx, my);

		prevDown = down;
	}

	private void HandleKeyRepeat(IKeyboard keyboard, UIContext context,
		Sedulous.UI.KeyModifiers mods, float deltaTime)
	{
		// Detect newly pressed repeatable key.
		for (let key in sRepeatableKeys)
		{
			if (keyboard.IsKeyPressed(key))
			{
				mHeldKey = key;
				mKeyHoldTime = 0;
				mLastRepeatTime = 0;
				return;
			}
		}

		if (mHeldKey == .Unknown) return;

		if (!keyboard.IsKeyDown(mHeldKey))
		{
			mHeldKey = .Unknown;
			mKeyHoldTime = 0;
			mLastRepeatTime = 0;
			return;
		}

		mKeyHoldTime += deltaTime;
		if (mKeyHoldTime < KeyRepeatDelay) return;

		mLastRepeatTime += deltaTime;
		while (mLastRepeatTime >= KeyRepeatRate)
		{
			mLastRepeatTime -= KeyRepeatRate;

			// Navigation keys repeat as KeyDown.
			if (mHeldKey == .Backspace || mHeldKey == .Delete ||
				mHeldKey == .Left || mHeldKey == .Right ||
				mHeldKey == .Up || mHeldKey == .Down ||
				mHeldKey == .Home || mHeldKey == .End)
			{
				context.InputManager.ProcessKeyDown(InputMapping.MapKey(mHeldKey), mods, true);
			}
			else if (!mods.HasFlag(.Ctrl) && !mods.HasFlag(.Alt))
			{
				// Text keys repeat as text input.
				let c = InputMapping.KeyToChar(mHeldKey, mods.HasFlag(.Shift));
				if (c != '\0')
					context.InputManager.ProcessTextInput(c);
			}
		}
	}
}
