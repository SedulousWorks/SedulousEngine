using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// The keyboard, as a fold over the frame's DOM key events.
///
/// Two arrays and a roll: pressed and released are edges against the PREVIOUS frame, which is
/// why BeginFrame copies current into previous before any of this frame's events land.
class WebKeyboard : IKeyboard
{
	private const int cCount = (int)KeyCode.Count;

	private bool[cCount] mCurrent;
	private bool[cCount] mPrevious;
	private KeyModifiers mModifiers;

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

	/// Every key released, for a focus loss: the browser stops delivering keyup once the page
	/// loses focus, so a key held across an alt-tab would otherwise stay down forever.
	public void ReleaseAll()
	{
		mCurrent = default;
		mModifiers = .None;
	}

	private static int Index(KeyCode key)
	{
		let raw = (int)key;
		return ((raw >= 0) && (raw < cCount)) ? raw : 0;
	}
}
