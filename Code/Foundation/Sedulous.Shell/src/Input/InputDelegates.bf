using System;

namespace Sedulous.Shell.Input;

/// Delegate for key press/release events.
public delegate void KeyEventDelegate(KeyCode key, bool down);

/// Delegate for text input events.
public delegate void TextInputDelegate(StringView text);

/// Delegate for mouse move events.
public delegate void MouseMoveDelegate(float x, float y);

/// Delegate for mouse button events.
public delegate void MouseButtonDelegate(MouseButton button, bool down);

/// Delegate for mouse scroll events.
public delegate void MouseScrollDelegate(float x, float y);

/// Delegate for touch events (down, up, move).
public delegate void TouchEventDelegate(TouchPoint point);

/// Delegate for gamepad button events.
public delegate void GamepadButtonDelegate(GamepadButton button, bool down);

/// Delegate for gamepad axis events.
public delegate void GamepadAxisDelegate(GamepadAxis axis, float value);

/// Delegate for gamepad connection events.
public delegate void GamepadConnectionDelegate(int index, bool connected);
