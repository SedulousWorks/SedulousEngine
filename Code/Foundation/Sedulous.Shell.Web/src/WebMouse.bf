using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// The mouse, as a fold over the frame's DOM pointer events.
///
/// Positions are in the CANVAS's pixels, not the browser's CSS pixels: the shell scales them
/// by the device pixel ratio so a caller reading X and Y gets coordinates in the same space
/// the canvas renders in. Without that, everything a retina display draws is picked at half
/// the position it appears.
class WebMouse : IMouse
{
	private const int cCount = (int)MouseButton.Count;

	/// Each button's state and the frame's edges: a click whose press and release share a frame
	/// reads as both.
	private ButtonLatch[cCount] mButtons;
	private float mX;
	private float mY;
	private float mDeltaX;
	private float mDeltaY;
	private float mScrollX;
	private float mScrollY;
	/// BORROWED: the manager's canvas selector, which a lock is asked for.
	private char8* mCanvas = null;
	/// SetRelativeMode.
	private bool mLockAsked;
	/// The browser holds the lock for the canvas.
	private bool mLocked;
	private bool mCursorVisible = true;

	public float X => mX;
	public float Y => mY;
	/// A browser never reports a desktop position, so global is the canvas position.
	public float GlobalX => mX;
	public float GlobalY => mY;
	public float DeltaX => mDeltaX;
	public float DeltaY => mDeltaY;
	public float ScrollX => mScrollX;
	public float ScrollY => mScrollY;

	public bool IsButtonDown(MouseButton button) => mButtons[Index(button)].Down;
	public bool IsButtonPressed(MouseButton button) => mButtons[Index(button)].Pressed;
	public bool IsButtonReleased(MouseButton button) => mButtons[Index(button)].Released;

	/// Relative mode is the browser's pointer lock. A page may lock the pointer only from a user
	/// action, so a lock asked outside one waits: the next press on the canvas asks the browser
	/// (RequestLockOnPress). RelativeMode reads the lock the browser holds, which its Escape ends;
	/// the ask stays, so a press locks it again until the game frees it.
	public bool RelativeMode => mLocked;
	public void SetRelativeMode(bool enabled)
	{
		mLockAsked = enabled;
#if BF_PLATFORM_WASM
		if (enabled && !mLocked && (mCanvas != null))
			EmscriptenHtml5.emscripten_request_pointerlock(mCanvas, false); // granted only in a user action
		else if (!enabled && mLocked)
			EmscriptenHtml5.emscripten_exit_pointerlock();
#endif
	}

	public bool CursorVisible => mCursorVisible;
	public void SetCursorVisible(bool visible) => mCursorVisible = visible;
	/// A cursor shape is a CSS property of the canvas, which needs a DOM write this shell
	/// does not have a channel for yet.
	public void SetCursor(CursorType cursor) {}
	/// There is nothing outside the page to capture.
	public void SetGlobalCapture(bool enabled) {}

	public void OnMotion(float x, float y, float deltaX, float deltaY)
	{
		mX = x;
		mY = y;
		mDeltaX += deltaX;
		mDeltaY += deltaY;
	}

	public void OnButton(MouseButton button, bool down) => mButtons[Index(button)].Set(down);

	/// The canvas a lock is asked for (its selector, kept by the manager).
	public void SetCanvas(char8* selector) => mCanvas = selector;

	/// From a press on the canvas, a user action: a lock still asked is asked of the browser now.
	public void RequestLockOnPress()
	{
#if BF_PLATFORM_WASM
		if (mLockAsked && !mLocked && (mCanvas != null))
			EmscriptenHtml5.emscripten_request_pointerlock(mCanvas, false);
#endif
	}

	/// The browser's pointerlockchange: whether the canvas holds the lock now.
	public void OnLockChanged(bool locked) => mLocked = locked;

	public void OnWheel(float scrollX, float scrollY)
	{
		mScrollX += scrollX;
		mScrollY += scrollY;
	}

	public void BeginFrame()
	{
		for (var button in ref mButtons)
			button.BeginFrame();
		mDeltaX = 0.0f;
		mDeltaY = 0.0f;
		mScrollX = 0.0f;
		mScrollY = 0.0f;
	}

	/// Every button released, for a focus loss: a button held while the page loses focus never
	/// gets its mouseup.
	public void ReleaseAll()
	{
		for (var button in ref mButtons)
			button.Set(false);
	}

	private static int Index(MouseButton button)
	{
		let raw = (int)button;
		return ((raw >= 0) && (raw < cCount)) ? raw : 0;
	}
}
