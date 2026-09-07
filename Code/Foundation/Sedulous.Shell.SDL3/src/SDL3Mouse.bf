using System;
using SDL3;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// Pointer state, double buffered like the keyboard.
///
/// Deltas and scroll are per FRAME and reset by BeginFrame: they are "how much since last
/// time", so a frame with no motion has to read zero rather than the last motion again.
class SDL3Mouse : IMouse
{
	private SDL_Window* mWindow;
	private float mX, mY, mDeltaX, mDeltaY, mScrollX, mScrollY;
	private bool[(int)MouseButton.Count] mCurrent;
	private bool[(int)MouseButton.Count] mPrevious;
	private bool mRelative;
	private bool mCursorVisible = true;
	private bool mGlobalCapture;
	private CursorType mCursor = .Default;
	/// Created on first use and kept: making one per frame is a syscall per frame.
	private SDL_Cursor*[(int)CursorType.Count] mCursors;

	public float X => mX;
	public float Y => mY;

	/// Desktop space, asked of SDL each time rather than tracked: nothing feeds it through
	/// the event stream, and it is read rarely.
	public float GlobalX
	{
		get
		{
			float x = 0, y = 0;
			SDL3.SDL_GetGlobalMouseState(&x, &y);
			return x;
		}
	}

	public float GlobalY
	{
		get
		{
			float x = 0, y = 0;
			SDL3.SDL_GetGlobalMouseState(&x, &y);
			return y;
		}
	}

	public float DeltaX => mDeltaX;
	public float DeltaY => mDeltaY;
	public float ScrollX => mScrollX;
	public float ScrollY => mScrollY;

	public bool IsButtonDown(MouseButton button) => mCurrent[Index(button)];
	public bool IsButtonPressed(MouseButton button) => mCurrent[Index(button)] && !mPrevious[Index(button)];
	public bool IsButtonReleased(MouseButton button) => !mCurrent[Index(button)] && mPrevious[Index(button)];

	public bool RelativeMode => mRelative;

	/// What a first person camera uses: the pointer stops moving and only deltas arrive.
	public void SetRelativeMode(bool enabled)
	{
		mRelative = enabled;
		if (mWindow != null)
			SDL3.SDL_SetWindowRelativeMouseMode(mWindow, enabled);
	}

	public bool CursorVisible => mCursorVisible;

	public void SetCursorVisible(bool visible)
	{
		mCursorVisible = visible;
		if (visible)
			SDL3.SDL_ShowCursor();
		else
			SDL3.SDL_HideCursor();
	}

	/// Cached per type. A cursor SDL cannot make leaves the current one alone, which is
	/// better than the pointer disappearing.
	public void SetCursor(CursorType cursor)
	{
		mCursor = cursor;
		let index = (int)cursor;
		if ((index < 0) || (index >= (int)CursorType.Count))
			return;

		if (mCursors[index] == null)
			mCursors[index] = SDL3.SDL_CreateSystemCursor(SystemCursor(cursor));
		if (mCursors[index] != null)
			SDL3.SDL_SetCursor(mCursors[index]);
	}

	/// Keeps events coming while a button is held outside the window, which is what makes a
	/// drag that leaves the window still work.
	public void SetGlobalCapture(bool enabled)
	{
		mGlobalCapture = enabled;
		SDL3.SDL_CaptureMouse(enabled);
	}

	public void SetWindow(SDL_Window* window) => mWindow = window;

	/// Frees the cached cursors. Called BEFORE SDL_Quit, because freeing one afterwards
	/// calls into a torn down video subsystem.
	public void ReleaseCursors()
	{
		for (int i < (int)CursorType.Count)
		{
			if (mCursors[i] != null)
			{
				SDL3.SDL_DestroyCursor(mCursors[i]);
				mCursors[i] = null;
			}
		}
	}

	/// Deltas ACCUMULATE within a frame: several motion events can arrive between pumps and
	/// the frame wants their sum, not the last one.
	public void OnMotion(float x, float y, float relativeX, float relativeY)
	{
		mX = x;
		mY = y;
		mDeltaX += relativeX;
		mDeltaY += relativeY;
	}

	public void OnButton(uint32 sdlButton, bool down)
	{
		let button = SDL3KeyMap.Mouse(sdlButton);
		if (button != .Count)
			mCurrent[Index(button)] = down;
	}

	public void OnWheel(float x, float y)
	{
		mScrollX += x;
		mScrollY += y;
	}

	public void BeginFrame()
	{
		mPrevious = mCurrent;
		mDeltaX = 0; mDeltaY = 0;
		mScrollX = 0; mScrollY = 0;
	}

	private static int Index(MouseButton button)
	{
		let index = (int)button;
		return ((index >= 0) && (index < (int)MouseButton.Count)) ? index : 0;
	}

	private static SDL_SystemCursor SystemCursor(CursorType cursor)
	{
		switch (cursor)
		{
		case .Pointer: return .SDL_SYSTEM_CURSOR_POINTER;
		case .Text: return .SDL_SYSTEM_CURSOR_TEXT;
		case .Wait: return .SDL_SYSTEM_CURSOR_WAIT;
		case .Crosshair: return .SDL_SYSTEM_CURSOR_CROSSHAIR;
		case .ResizeNWSE: return .SDL_SYSTEM_CURSOR_NWSE_RESIZE;
		case .ResizeNESW: return .SDL_SYSTEM_CURSOR_NESW_RESIZE;
		case .ResizeEW: return .SDL_SYSTEM_CURSOR_EW_RESIZE;
		case .ResizeNS: return .SDL_SYSTEM_CURSOR_NS_RESIZE;
		case .Move: return .SDL_SYSTEM_CURSOR_MOVE;
		case .NotAllowed: return .SDL_SYSTEM_CURSOR_NOT_ALLOWED;
		default: return .SDL_SYSTEM_CURSOR_DEFAULT;
		}
	}
}
