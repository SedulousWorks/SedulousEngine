namespace Sedulous.GUI.Shell;

using Sedulous.GUI;

/// Polling-based keyboard input helper for routing shell keyboard state to a GUIContext.
/// Handles navigation keys, text input from key codes, Ctrl/Alt shortcuts,
/// and key repeat with configurable delay/rate.
/// Create an instance and call ProcessKeyboardInput() each frame.
class GUIInputHelper
{
	private typealias ShellKeyCode = Sedulous.Shell.Input.KeyCode;
	// Key repeat state
	private ShellKeyCode mHeldKey = .Unknown;
	private float mKeyHoldTime = 0;
	private float mLastRepeatTime = 0;

	public float KeyRepeatDelay = 0.4f;
	public float KeyRepeatRate = 0.03f;

	private static ShellKeyCode[?] sNavigationKeys = .(
		.Tab, .Left, .Right, .Up, .Down,
		.Home, .End, .PageUp, .PageDown,
		.Backspace, .Delete, .Return
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

	/// Process all keyboard input from a polled keyboard and route to a GUIContext.
	/// Call this once per frame.
	public void ProcessKeyboardInput(Sedulous.Shell.Input.IKeyboard keyboard, GUIContext context, float deltaTime)
	{
		let mods = InputMapping.MapModifiers(keyboard.Modifiers);

		// Navigation and editing keys
		for (let key in sNavigationKeys)
			ForwardKeyIfPressed(keyboard, context, key, mods);

		// Ctrl+key shortcuts
		if (mods.HasFlag(.Ctrl))
		{
			for (let key in sCtrlShortcutKeys)
				ForwardKeyIfPressed(keyboard, context, key, mods);
		}

		// Alt key itself + Alt+letter for menu accelerators
		ForwardKeyIfPressed(keyboard, context, .LeftAlt, mods);
		ForwardKeyIfPressed(keyboard, context, .RightAlt, mods);
		if (mods.HasFlag(.Alt))
		{
			for (let key in sLetterKeys)
				ForwardKeyIfPressed(keyboard, context, key, mods);
		}

		// Text input for printable keys
		if (!mods.HasFlag(.Ctrl) && !mods.HasFlag(.Alt))
		{
			for (let key in sPrintableKeys)
			{
				if (keyboard.IsKeyPressed(key))
				{
					let c = InputMapping.KeyToChar(key, mods.HasFlag(.Shift));
					if (c != '\0')
						context.ProcessTextInput(c);
				}
			}
		}

		// Key repeat
		HandleKeyRepeat(keyboard, context, mods, deltaTime);
	}

	/// Route mouse input from a polled mouse to a GUIContext.
	/// Call this once per frame.
	public static void ProcessMouseInput(Sedulous.Shell.Input.IMouse mouse, Sedulous.Shell.Input.IKeyboard keyboard, GUIContext context)
	{
		let mods = keyboard != null ? InputMapping.MapModifiers(keyboard.Modifiers) : Sedulous.GUI.KeyModifiers.None;
		let mx = mouse.X;
		let my = mouse.Y;

		if (mouse.DeltaX != 0 || mouse.DeltaY != 0)
			context.ProcessMouseMove(mx, my);

		CheckMouseButton(mouse, context, .Left, mx, my, mods);
		CheckMouseButton(mouse, context, .Right, mx, my, mods);
		CheckMouseButton(mouse, context, .Middle, mx, my, mods);

		if (mouse.ScrollX != 0 || mouse.ScrollY != 0)
			context.ProcessMouseWheel(mx, my, mouse.ScrollY, mods);
	}

	private static void ForwardKeyIfPressed(Sedulous.Shell.Input.IKeyboard keyboard, GUIContext context, ShellKeyCode shellKey, Sedulous.GUI.KeyModifiers mods)
	{
		if (keyboard.IsKeyPressed(shellKey))
			context.ProcessKeyDown(InputMapping.MapKey(shellKey), mods);
	}

	private static void CheckMouseButton(Sedulous.Shell.Input.IMouse mouse, GUIContext context, Sedulous.Shell.Input.MouseButton shellButton, float x, float y, Sedulous.GUI.KeyModifiers mods)
	{
		let uiButton = InputMapping.MapMouseButton(shellButton);
		if (mouse.IsButtonPressed(shellButton))
			context.ProcessMouseDown(x, y, uiButton, mods);
		else if (mouse.IsButtonReleased(shellButton))
			context.ProcessMouseUp(x, y, uiButton, mods);
	}

	private void HandleKeyRepeat(Sedulous.Shell.Input.IKeyboard keyboard, GUIContext context, Sedulous.GUI.KeyModifiers mods, float deltaTime)
	{
		// Detect newly pressed repeatable key
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

		if (mHeldKey == .Unknown)
			return;

		if (!keyboard.IsKeyDown(mHeldKey))
		{
			mHeldKey = .Unknown;
			mKeyHoldTime = 0;
			mLastRepeatTime = 0;
			return;
		}

		mKeyHoldTime += deltaTime;
		if (mKeyHoldTime < KeyRepeatDelay)
			return;

		mLastRepeatTime += deltaTime;
		while (mLastRepeatTime >= KeyRepeatRate)
		{
			mLastRepeatTime -= KeyRepeatRate;

			// Navigation keys repeat as KeyDown
			if (mHeldKey == .Backspace || mHeldKey == .Delete ||
				mHeldKey == .Left || mHeldKey == .Right ||
				mHeldKey == .Up || mHeldKey == .Down ||
				mHeldKey == .Home || mHeldKey == .End)
			{
				context.ProcessKeyDown(InputMapping.MapKey(mHeldKey), mods);
			}
			else if (!mods.HasFlag(.Ctrl) && !mods.HasFlag(.Alt))
			{
				// Text keys repeat as text input
				let c = InputMapping.KeyToChar(mHeldKey, mods.HasFlag(.Shift));
				if (c != '\0')
					context.ProcessTextInput(c);
			}
		}
	}
}
