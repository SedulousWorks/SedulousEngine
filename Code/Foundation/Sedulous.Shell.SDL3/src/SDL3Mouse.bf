using System;
using SDL3;
using Sedulous.Shell.Input;
using Sedulous.Core;

namespace Sedulous.Shell.SDL3;

/// SDL3 implementation of mouse input.
class SDL3Mouse : IMouse
{
	private float mX;
	private float mY;
	private float mDeltaX;
	private float mDeltaY;
	private float mScrollX;
	private float mScrollY;
	private bool[5] mCurrentButtons;
	private bool[5] mPreviousButtons;
	private SDL_Window* mFocusWindow;

	private EventAccessor<MouseMoveDelegate> mOnMove = new .() ~ delete _;
	private EventAccessor<MouseButtonDelegate> mOnButton = new .() ~ delete _;
	private EventAccessor<MouseScrollDelegate> mOnScroll = new .() ~ delete _;

	// Cursor management
	private CursorType mCurrentCursor = .Default;
	private SDL_Cursor*[(int)SDL_SystemCursor.SDL_SYSTEM_CURSOR_COUNT] mCursors;
	private bool mCursorsInitialized = false;

	public float X => mX;
	public float Y => mY;
	public float DeltaX => mDeltaX;
	public float DeltaY => mDeltaY;
	public float ScrollX => mScrollX;
	public float ScrollY => mScrollY;

	public EventAccessor<MouseMoveDelegate> OnMove => mOnMove;
	public EventAccessor<MouseButtonDelegate> OnButton => mOnButton;
	public EventAccessor<MouseScrollDelegate> OnScroll => mOnScroll;

	public bool RelativeMode
	{
		get => mFocusWindow != null && SDL_GetWindowRelativeMouseMode(mFocusWindow);
		set
		{
			if (mFocusWindow != null)
				SDL_SetWindowRelativeMouseMode(mFocusWindow, value);
		}
	}

	public bool Visible
	{
		get => SDL_CursorVisible();
		set
		{
			if (value)
				SDL_ShowCursor();
			else
				SDL_HideCursor();
		}
	}

	public CursorType Cursor
	{
		get => mCurrentCursor;
		set
		{
			if (mCurrentCursor == value)
				return;

			mCurrentCursor = value;
			let sdlCursor = GetOrCreateCursor(CursorTypeToSDL(value));
			if (sdlCursor != null)
				SDL_SetCursor(sdlCursor);
		}
	}

	public bool IsButtonDown(MouseButton button)
	{
		let index = (int)button;
		if (index < 0 || index >= 5)
			return false;
		return mCurrentButtons[index];
	}

	public bool IsButtonPressed(MouseButton button)
	{
		let index = (int)button;
		if (index < 0 || index >= 5)
			return false;
		return mCurrentButtons[index] && !mPreviousButtons[index];
	}

	public bool IsButtonReleased(MouseButton button)
	{
		let index = (int)button;
		if (index < 0 || index >= 5)
			return false;
		return !mCurrentButtons[index] && mPreviousButtons[index];
	}

	/// Called before processing new events.
	public void BeginFrame()
	{
		mPreviousButtons = mCurrentButtons;
		mDeltaX = 0;
		mDeltaY = 0;
		mScrollX = 0;
		mScrollY = 0;
	}

	/// Sets the current focus window for relative mode.
	public void SetFocusWindow(SDL_Window* window)
	{
		mFocusWindow = window;
	}

	/// Handles an SDL mouse motion event.
	public void HandleMotionEvent(SDL_MouseMotionEvent* e)
	{
		mX = e.x;
		mY = e.y;
		mDeltaX += e.xrel;
		mDeltaY += e.yrel;
		mOnMove.[Friend]Invoke(mX, mY);
	}

	/// Handles an SDL mouse button event.
	public void HandleButtonEvent(SDL_MouseButtonEvent* e)
	{
		let button = ConvertButton(e.button);
		let index = (int)button;
		if (index >= 0 && index < 5)
		{
			mCurrentButtons[index] = e.down;
			mOnButton.[Friend]Invoke(button, e.down);
		}
	}

	/// Handles an SDL mouse wheel event.
	public void HandleWheelEvent(SDL_MouseWheelEvent* e)
	{
		mScrollX += e.x;
		mScrollY += e.y;
		mOnScroll.[Friend]Invoke(e.x, e.y);
	}

	private static MouseButton ConvertButton(uint8 sdlButton)
	{
		switch (sdlButton)
		{
		case 1: return .Left;
		case 2: return .Middle;
		case 3: return .Right;
		case 4: return .X1;
		case 5: return .X2;
		default: return .Left;
		}
	}

	/// Converts CursorType to SDL_SystemCursor.
	private static SDL_SystemCursor CursorTypeToSDL(CursorType cursor)
	{
		switch (cursor)
		{
		case .Default:    return .SDL_SYSTEM_CURSOR_DEFAULT;
		case .Text:       return .SDL_SYSTEM_CURSOR_TEXT;
		case .Wait:       return .SDL_SYSTEM_CURSOR_WAIT;
		case .Crosshair:  return .SDL_SYSTEM_CURSOR_CROSSHAIR;
		case .Progress:   return .SDL_SYSTEM_CURSOR_PROGRESS;
		case .ResizeNWSE: return .SDL_SYSTEM_CURSOR_NWSE_RESIZE;
		case .ResizeNESW: return .SDL_SYSTEM_CURSOR_NESW_RESIZE;
		case .ResizeEW:   return .SDL_SYSTEM_CURSOR_EW_RESIZE;
		case .ResizeNS:   return .SDL_SYSTEM_CURSOR_NS_RESIZE;
		case .Move:       return .SDL_SYSTEM_CURSOR_MOVE;
		case .NotAllowed: return .SDL_SYSTEM_CURSOR_NOT_ALLOWED;
		case .Pointer:    return .SDL_SYSTEM_CURSOR_POINTER;
		case .ResizeNW:   return .SDL_SYSTEM_CURSOR_NW_RESIZE;
		case .ResizeN:    return .SDL_SYSTEM_CURSOR_N_RESIZE;
		case .ResizeNE:   return .SDL_SYSTEM_CURSOR_NE_RESIZE;
		case .ResizeE:    return .SDL_SYSTEM_CURSOR_E_RESIZE;
		case .ResizeSE:   return .SDL_SYSTEM_CURSOR_SE_RESIZE;
		case .ResizeS:    return .SDL_SYSTEM_CURSOR_S_RESIZE;
		case .ResizeSW:   return .SDL_SYSTEM_CURSOR_SW_RESIZE;
		case .ResizeW:    return .SDL_SYSTEM_CURSOR_W_RESIZE;
		}
	}

	/// Gets or creates a cached SDL cursor.
	private SDL_Cursor* GetOrCreateCursor(SDL_SystemCursor type)
	{
		let index = (int)type;
		if (index < 0 || index >= mCursors.Count)
			return null;

		if (mCursors[index] == null)
			mCursors[index] = SDL_CreateSystemCursor(type);

		return mCursors[index];
	}

	/// Destroys all cached cursors.
	public void Dispose()
	{
		for (var cursor in ref mCursors)
		{
			if (cursor != null)
			{
				SDL_DestroyCursor(cursor);
				cursor = null;
			}
		}
	}
}
