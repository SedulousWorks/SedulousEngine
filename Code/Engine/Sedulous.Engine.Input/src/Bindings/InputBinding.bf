namespace Sedulous.Engine.Input;

using System;
using Sedulous.Shell.Input;

/// Identifies the source device for an input binding.
enum InputSource
{
	Keyboard,
	Mouse,
	Gamepad,
	Touch
}

/// Abstract base for input bindings.
/// Maps physical inputs to normalized values.
abstract class InputBinding
{
	/// Human-readable name for display (e.g., "Space", "Left Mouse Button").
	public String DisplayName { get; protected set; } = new .() ~ delete _;

	/// Source device type.
	public abstract InputSource Source { get; }

	/// Reads current value from the input manager.
	public abstract InputValue GetValue(IInputManager inputManager);

	/// Returns true if this binding was just activated this frame.
	public abstract bool WasPressed(IInputManager inputManager);

	/// Returns true if this binding was just deactivated this frame.
	public abstract bool WasReleased(IInputManager inputManager);

	/// Creates a deep copy of this binding.
	public abstract InputBinding Clone();

	/// Updates the display name based on current binding configuration.
	protected virtual void UpdateDisplayName()
	{
	}
}
