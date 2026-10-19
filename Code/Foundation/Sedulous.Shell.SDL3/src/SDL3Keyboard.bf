using System;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// Key state, with the edges latched so a frame can ask what CHANGED rather than only what
/// is held.
///
/// Pressed and Released are the edges, and a control that fires on a press rather than on a
/// hold is the reason they exist. They are the edges the frame's events brought, cleared at
/// the START of the pump, so a key tapped down and up within one frame reads as both.
class SDL3Keyboard : IKeyboard
{
	private ButtonLatch[(int)KeyCode.Count] mKeys;
	private KeyModifiers mModifiers = .None;

	public bool IsKeyDown(KeyCode key) => mKeys[Index(key)].Down;
	public bool IsKeyPressed(KeyCode key) => mKeys[Index(key)].Pressed;
	public bool IsKeyReleased(KeyCode key) => mKeys[Index(key)].Released;
	public KeyModifiers Modifiers => mModifiers;

	public void SetKey(KeyCode key, bool down) => mKeys[Index(key)].Set(down);
	public void SetModifiers(KeyModifiers modifiers) => mModifiers = modifiers;

	public void BeginFrame()
	{
		for (var key in ref mKeys)
			key.BeginFrame();
	}

	/// Anything out of range folds onto Unknown, which is slot zero and always up, rather
	/// than indexing past the array.
	private static int Index(KeyCode key)
	{
		let index = (int)key;
		return ((index >= 0) && (index < (int)KeyCode.Count)) ? index : 0;
	}
}
