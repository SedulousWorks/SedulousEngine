namespace Sedulous.Editor.Core;

using Sedulous.Core;
using Sedulous.Platform.Input;

/// IKeyboard adapter owned by a GameEditorPage. Gates polled key state
/// on page focus so gameplay hotkeys (Space / P / Escape / etc.) only
/// fire while the Game tab is active. Without this, the module ticks
/// during play but reads the same keyboard the editor's chrome reads -
/// typing into a Name field would also start the next wave.
///
/// The page flips `Focused` from `OnActivated` / `OnDeactivated`. When
/// unfocused: IsKeyDown / IsKeyPressed / IsKeyReleased all return false
/// and Modifiers reports None, regardless of physical state.
///
/// OnKeyEvent / OnTextInput passthrough to the platform - the page only
/// ticks module.OnUpdate while active, so subscribed handlers that
/// only run from inside that tick are naturally scoped. (TD polls;
/// it doesn't subscribe - if a future module subscribes expecting
/// focus gating, EventAccessor would need its own filtering wrapper.)
class GameKeyboardAdapter : IKeyboard
{
	private IKeyboard mPlatform;
	private bool mFocused;

	public this(IKeyboard platform)
	{
		mPlatform = platform;
	}

	public bool Focused
	{
		get => mFocused;
		set => mFocused = value;
	}

	public bool IsKeyDown(KeyCode key) =>
		mFocused && (mPlatform?.IsKeyDown(key) ?? false);

	public bool IsKeyPressed(KeyCode key) =>
		mFocused && (mPlatform?.IsKeyPressed(key) ?? false);

	public bool IsKeyReleased(KeyCode key) =>
		mFocused && (mPlatform?.IsKeyReleased(key) ?? false);

	public KeyModifiers Modifiers =>
		mFocused ? (mPlatform?.Modifiers ?? .None) : .None;

	public EventAccessor<KeyEventDelegate> OnKeyEvent => mPlatform?.OnKeyEvent;
	public EventAccessor<TextInputDelegate> OnTextInput => mPlatform?.OnTextInput;
}
