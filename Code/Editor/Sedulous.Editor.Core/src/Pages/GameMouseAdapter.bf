namespace Sedulous.Editor.Core;

using Sedulous.Core;
using Sedulous.Shell.Input;

/// IMouse adapter owned by a GameEditorPage. The editor renders the
/// game into a sub-rect of the editor window (the page's ViewportView),
/// so a module that polls shell.InputManager.Mouse directly sees
/// window-relative pixel coords - off by the viewport's screen origin
/// and out-of-range whenever the pointer is over chrome. This adapter
/// overrides X / Y with the last viewport-local position fed in by
/// `GameInputHandler.OnMouseMove`; everything else is a passthrough
/// to the underlying shell mouse.
///
/// Button-state polling stays passthrough: SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH
/// already makes the first click on a refocused window register, and the
/// page only ticks module.OnUpdate while it's the active tab, so unfocused
/// click ghosts don't reach the game.
///
/// Event subscribers (OnMove / OnButton / OnScroll) passthrough to the
/// shell. TD polls; it doesn't subscribe. If a future module subscribes
/// expecting viewport-local coords, the right fix is to forward through
/// `GameInputHandler` rather than wrap EventAccessor here.
class GameMouseAdapter : IMouse
{
	private IMouse mShell;
	private float mLocalX;
	private float mLocalY;
	// Scroll is sourced from GameInputHandler.OnMouseWheel rather than
	// passed through from shell. Shell IMouse accumulates the wheel
	// delta anywhere in the editor window, so passthrough would let the
	// scene editor (or any docked panel) drive the game's camera zoom
	// when the user scrolls in it. The page resets these to zero each
	// frame in EndFrame after module.OnUpdate consumed them.
	private float mLocalScrollX;
	private float mLocalScrollY;

	public this(IMouse shell)
	{
		mShell = shell;
	}

	/// Called by GameInputHandler whenever the pointer moves inside the
	/// page viewport. Coords are already viewport-local pixels (what the
	/// game's screen UI lays out against, and what the game's raycast
	/// path expects).
	public void OnViewportPointerMove(float x, float y)
	{
		mLocalX = x;
		mLocalY = y;
	}

	/// Called by GameInputHandler when the wheel scrolls over the page
	/// viewport. Deltas accumulate within a frame (rare for the wheel,
	/// but matches IMouse's "this frame's scroll" contract); EndFrame
	/// zeroes them after the module's OnUpdate runs.
	public void OnViewportPointerWheel(float deltaX, float deltaY)
	{
		mLocalScrollX += deltaX;
		mLocalScrollY += deltaY;
	}

	/// Clear per-frame scroll. The page calls this after module.OnUpdate
	/// so the next frame starts with zero scroll unless OnViewportPointerWheel
	/// fires again. Position state stays at last-known.
	public void EndFrame()
	{
		mLocalScrollX = 0;
		mLocalScrollY = 0;
	}

	public float X => mLocalX;
	public float Y => mLocalY;
	public float GlobalX => mShell?.GlobalX ?? 0;
	public float GlobalY => mShell?.GlobalY ?? 0;
	public float DeltaX => mShell?.DeltaX ?? 0;
	public float DeltaY => mShell?.DeltaY ?? 0;
	public float ScrollX => mLocalScrollX;
	public float ScrollY => mLocalScrollY;

	public bool IsButtonDown(MouseButton button) =>
		(mShell?.IsButtonDown(button)) ?? false;
	public bool IsButtonPressed(MouseButton button) =>
		(mShell?.IsButtonPressed(button)) ?? false;
	public bool IsButtonReleased(MouseButton button) =>
		(mShell?.IsButtonReleased(button)) ?? false;

	public bool RelativeMode
	{
		get => mShell?.RelativeMode ?? false;
		set { if (mShell != null) mShell.RelativeMode = value; }
	}

	public bool Visible
	{
		get => mShell?.Visible ?? true;
		set { if (mShell != null) mShell.Visible = value; }
	}

	public CursorType Cursor
	{
		get => mShell?.Cursor ?? .Default;
		set { if (mShell != null) mShell.Cursor = value; }
	}

	public EventAccessor<MouseMoveDelegate> OnMove => mShell?.OnMove;
	public EventAccessor<MouseButtonDelegate> OnButton => mShell?.OnButton;
	public EventAccessor<MouseScrollDelegate> OnScroll => mShell?.OnScroll;
}
