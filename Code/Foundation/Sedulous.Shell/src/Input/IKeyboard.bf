using System;
using Sedulous.Core;

namespace Sedulous.Shell.Input;

/// Keyboard input interface.
public interface IKeyboard
{
	/// Returns true if the key is currently held down.
	bool IsKeyDown(KeyCode key);

	/// Returns true if the key was just pressed this frame.
	bool IsKeyPressed(KeyCode key);

	/// Returns true if the key was just released this frame.
	bool IsKeyReleased(KeyCode key);

	/// Gets the current modifier key state.
	KeyModifiers Modifiers { get; }

	/// Called when a key is pressed or released.
	EventAccessor<KeyEventDelegate> OnKeyEvent { get; }

	/// Called when text input is received.
	EventAccessor<TextInputDelegate> OnTextInput { get; }
}
