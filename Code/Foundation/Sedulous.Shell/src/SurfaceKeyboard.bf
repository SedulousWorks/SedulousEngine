namespace Sedulous.Shell;

/// The surface's keyboard: the raw one gated by focus.
///
/// An unfocused surface reads every key as up and no modifiers, so two viewports cannot
/// both act on the same keystroke.
class SurfaceKeyboard : IKeyboard
{
	private InputSurface mSurface;

	public this(InputSurface surface) { mSurface = surface; }

	public bool IsKeyDown(KeyCode key)
		=> mSurface.Focused && mSurface.Raw.Keyboard.IsKeyDown(key);
	public bool IsKeyPressed(KeyCode key)
		=> mSurface.Focused && mSurface.Raw.Keyboard.IsKeyPressed(key);
	public bool IsKeyReleased(KeyCode key)
		=> mSurface.Focused && mSurface.Raw.Keyboard.IsKeyReleased(key);

	public KeyModifiers Modifiers
		=> mSurface.Focused ? mSurface.Raw.Keyboard.Modifiers : .None;
}
