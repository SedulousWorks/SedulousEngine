using System;

namespace Sedulous.Shell.Input;

/// Manages all input devices.
public interface IInputManager
{
	/// Gets the keyboard input device.
	IKeyboard Keyboard { get; }

	/// Gets the mouse input device.
	IMouse Mouse { get; }

	/// Gets the touch input device.
	ITouch Touch { get; }

	/// Gets the number of connected gamepads.
	int GamepadCount { get; }

	/// Gets a gamepad by index.
	/// Returns null if the index is out of range.
	IGamepad GetGamepad(int index);

	/// Gets the number of files dropped this frame.
	int DroppedFileCount { get; }

	/// Gets a dropped file path by index.
	/// Returns null if index is out of range.
	StringView GetDroppedFile(int index);

	/// Updates input state. Called once per frame after processing events.
	void Update();
}
