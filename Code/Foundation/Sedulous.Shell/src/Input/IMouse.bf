using System;
using Sedulous.Core;

namespace Sedulous.Shell.Input;

/// Mouse input interface.
public interface IMouse
{
	/// Gets the current X position in pixels.
	float X { get; }

	/// Gets the current Y position in pixels.
	float Y { get; }

	/// Gets the X movement since last frame.
	float DeltaX { get; }

	/// Gets the Y movement since last frame.
	float DeltaY { get; }

	/// Gets the horizontal scroll amount this frame.
	float ScrollX { get; }

	/// Gets the vertical scroll amount this frame.
	float ScrollY { get; }

	/// Returns true if the button is currently held down.
	bool IsButtonDown(MouseButton button);

	/// Returns true if the button was just pressed this frame.
	bool IsButtonPressed(MouseButton button);

	/// Returns true if the button was just released this frame.
	bool IsButtonReleased(MouseButton button);

	/// Gets or sets whether relative mouse mode is enabled.
	/// In relative mode, the cursor is hidden and mouse motion is captured.
	bool RelativeMode { get; set; }

	/// Gets or sets whether the cursor is visible.
	bool Visible { get; set; }

	/// Gets or sets the current cursor type.
	CursorType Cursor { get; set; }

	/// Called when the mouse moves.
	EventAccessor<MouseMoveDelegate> OnMove { get; }

	/// Called when a mouse button is pressed or released.
	EventAccessor<MouseButtonDelegate> OnButton { get; }

	/// Called when the mouse wheel is scrolled.
	EventAccessor<MouseScrollDelegate> OnScroll { get; }
}
