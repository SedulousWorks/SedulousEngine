using System;
using Sedulous.Shell;

namespace Sedulous.Input;

/// Where a runtime reads its devices.
///
/// A seam rather than a direct shell reference, because the same map has to evaluate
/// against different devices depending on who is asking: the game host hands over the
/// whole shell, while play-in-editor hands over the game viewport's GATED facades so an
/// unfocused viewport forwards nothing.
///
/// Every accessor may return null, and a count may be zero. Devices come and go, and
/// evaluation reads absence as released rather than as an error.
interface IInputSourceProvider
{
	IKeyboard Keyboard { get; }
	IMouse Mouse { get; }
	int32 GamepadCount { get; }
	IGamepad GetGamepad(int32 index);

	/// Touch coordinates are NORMALISED window space, which is what the touch bindings'
	/// region model is expressed in.
	///
	/// Defaulted, because not every provider has one.
	ITouch Touch => null;

	/// This frame's tagged event stream, gated the same way the facades are.
	///
	/// Polling cannot carry ORDER or PAYLOAD: a key sequence and the characters of text
	/// input both need these. Valid until the next shell pump. Defaulted empty so a pure
	/// polling provider, a test fake, stays valid.
	Span<InputEvent> Events => .();
}
