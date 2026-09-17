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

	private bool[cCount] mCurrent;
	private bool[cCount] mPrevious;
	private float mX;
	private float mY;
	private float mDeltaX;
	private float mDeltaY;
	private float mScrollX;
	private float mScrollY;
	private bool mRelative;
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

	public bool IsButtonDown(MouseButton button) => mCurrent[Index(button)];
	public bool IsButtonPressed(MouseButton button) =>
		mCurrent[Index(button)] && !mPrevious[Index(button)];
	public bool IsButtonReleased(MouseButton button) =>
		!mCurrent[Index(button)] && mPrevious[Index(button)];

	/// Pointer lock is a REQUEST a browser only grants from a user gesture, so this records
	/// the wish and the lock itself is not wired.
	public bool RelativeMode => mRelative;
	public void SetRelativeMode(bool enabled) => mRelative = enabled;

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

	public void OnButton(MouseButton button, bool down) => mCurrent[Index(button)] = down;

	public void OnWheel(float scrollX, float scrollY)
	{
		mScrollX += scrollX;
		mScrollY += scrollY;
	}

	public void BeginFrame()
	{
		mPrevious = mCurrent;
		mDeltaX = 0.0f;
		mDeltaY = 0.0f;
		mScrollX = 0.0f;
		mScrollY = 0.0f;
	}

	/// Every button released, for a focus loss: a button held while the page loses focus never
	/// gets its mouseup.
	public void ReleaseAll()
	{
		mCurrent = default;
	}

	private static int Index(MouseButton button)
	{
		let raw = (int)button;
		return ((raw >= 0) && (raw < cCount)) ? raw : 0;
	}
}
