using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// The keyboard, as a fold over the frame's DOM key events.
///
/// Each key is a ButtonLatch: pressed and released are the edges the frame's events brought, so
/// a key pressed and released within one frame reads as both, as the SDL3 shell's do.
class WebKeyboard : IKeyboard
{
	private const int cCount = (int)KeyCode.Count;

	private ButtonLatch[cCount] mKeys;
	private KeyModifiers mModifiers;

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

	/// Every key released, for a focus loss: the browser stops delivering keyup once the page
	/// loses focus, so a key held across an alt-tab would otherwise stay down forever.
	public void ReleaseAll()
	{
		for (var key in ref mKeys)
			key.Set(false);
		mModifiers = .None;
	}

	private static int Index(KeyCode key)
	{
		let raw = (int)key;
		return ((raw >= 0) && (raw < cCount)) ? raw : 0;
	}
}
