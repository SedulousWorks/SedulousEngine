using System;

namespace Sedulous.Shell;

/// Every input device for one shell run, plus the frame's raw event stream.
interface IInputManager
{
	IKeyboard Keyboard { get; }
	IMouse Mouse { get; }
	ITouch Touch { get; }
	int32 GamepadCount { get; }
	IGamepad GetGamepad(int32 index);

	/// This frame's events, which the device snapshots above are a fold over. Cleared by
	/// Update.
	Span<InputEvent> Events { get; }

	/// The window under the pointer, and the one with keyboard focus. 0 means none.
	///
	/// Routing authority: a surface only takes the pointer if it is in the hovered window,
	/// so two windows showing viewports do not both react to one movement.
	uint32 HoverWindow { get; }
	uint32 FocusedWindow { get; }

	/// Rolls current state into previous and clears deltas and events. The shell calls
	/// this once a frame, BEFORE pumping OS events.
	void Update();
}
