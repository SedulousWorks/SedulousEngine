using System;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// Key state, double buffered so a frame can ask what CHANGED rather than only what is
/// held.
///
/// Pressed and Released are the edges, and a control that fires on a press rather than on a
/// hold is the reason they exist. The previous frame is copied at the START of the pump, so
/// events arriving during it land on the current frame and the comparison stays honest.
class SDL3Keyboard : IKeyboard
{
	private bool[(int)KeyCode.Count] mCurrent;
	private bool[(int)KeyCode.Count] mPrevious;
	private KeyModifiers mModifiers = .None;

	public bool IsKeyDown(KeyCode key) => mCurrent[Index(key)];
	public bool IsKeyPressed(KeyCode key) => mCurrent[Index(key)] && !mPrevious[Index(key)];
	public bool IsKeyReleased(KeyCode key) => !mCurrent[Index(key)] && mPrevious[Index(key)];
	public KeyModifiers Modifiers => mModifiers;

	public void SetKey(KeyCode key, bool down) => mCurrent[Index(key)] = down;
	public void SetModifiers(KeyModifiers modifiers) => mModifiers = modifiers;

	public void BeginFrame()
	{
		mPrevious = mCurrent;
	}

	/// Anything out of range folds onto Unknown, which is slot zero and always up, rather
	/// than indexing past the array.
	private static int Index(KeyCode key)
	{
		let index = (int)key;
		return ((index >= 0) && (index < (int)KeyCode.Count)) ? index : 0;
	}
}
