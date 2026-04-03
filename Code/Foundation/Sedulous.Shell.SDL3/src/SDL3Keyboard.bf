using System;
using SDL3;
using Sedulous.Shell.Input;
using Sedulous.Core;

namespace Sedulous.Shell.SDL3;

/// SDL3 implementation of keyboard input.
class SDL3Keyboard : IKeyboard
{
	private bool[(int)KeyCode.Count] mCurrentState;
	private bool[(int)KeyCode.Count] mPreviousState;
	private KeyModifiers mModifiers;

	private EventAccessor<KeyEventDelegate> mOnKeyEvent = new .() ~ delete _;
	private EventAccessor<TextInputDelegate> mOnTextInput = new .() ~ delete _;

	public KeyModifiers Modifiers => mModifiers;

	public EventAccessor<KeyEventDelegate> OnKeyEvent => mOnKeyEvent;
	public EventAccessor<TextInputDelegate> OnTextInput => mOnTextInput;

	public bool IsKeyDown(KeyCode key)
	{
		if ((int)key < 0 || (int)key >= (int)KeyCode.Count)
			return false;
		return mCurrentState[(int)key];
	}

	public bool IsKeyPressed(KeyCode key)
	{
		if ((int)key < 0 || (int)key >= (int)KeyCode.Count)
			return false;
		return mCurrentState[(int)key] && !mPreviousState[(int)key];
	}

	public bool IsKeyReleased(KeyCode key)
	{
		if ((int)key < 0 || (int)key >= (int)KeyCode.Count)
			return false;
		return !mCurrentState[(int)key] && mPreviousState[(int)key];
	}

	/// Called before processing new events to snapshot state.
	public void BeginFrame()
	{
		mPreviousState = mCurrentState;
	}

	/// Handles an SDL keyboard event.
	public void HandleKeyEvent(SDL_KeyboardEvent* e)
	{
		let scancode = (int)e.scancode;
		if (scancode >= 0 && scancode < (int)KeyCode.Count)
		{
			let down = e.down;
			mCurrentState[scancode] = down;
			mOnKeyEvent.[Friend]Invoke((KeyCode)scancode, down);
		}

		// Update modifiers
		mModifiers = ConvertModifiers(e.mod);
	}

	/// Handles an SDL text input event.
	public void HandleTextInput(SDL_TextInputEvent* e)
	{
		let text = StringView(&e.text[0]);
		mOnTextInput.[Friend]Invoke(text);
	}

	private static KeyModifiers ConvertModifiers(SDL_Keymod mod)
	{
		KeyModifiers result = .None;
		if (mod.HasFlag(.SDL_KMOD_LSHIFT)) result |= .LeftShift;
		if (mod.HasFlag(.SDL_KMOD_RSHIFT)) result |= .RightShift;
		if (mod.HasFlag(.SDL_KMOD_LCTRL)) result |= .LeftCtrl;
		if (mod.HasFlag(.SDL_KMOD_RCTRL)) result |= .RightCtrl;
		if (mod.HasFlag(.SDL_KMOD_LALT)) result |= .LeftAlt;
		if (mod.HasFlag(.SDL_KMOD_RALT)) result |= .RightAlt;
		if (mod.HasFlag(.SDL_KMOD_LGUI)) result |= .LeftGui;
		if (mod.HasFlag(.SDL_KMOD_RGUI)) result |= .RightGui;
		if (mod.HasFlag(.SDL_KMOD_NUM)) result |= .NumLock;
		if (mod.HasFlag(.SDL_KMOD_CAPS)) result |= .CapsLock;
		if (mod.HasFlag(.SDL_KMOD_SCROLL)) result |= .ScrollLock;
		return result;
	}
}
