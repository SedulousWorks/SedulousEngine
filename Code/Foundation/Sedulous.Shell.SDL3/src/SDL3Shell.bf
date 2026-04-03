using System;
using SDL3;
using Sedulous.Shell;
using Sedulous.Shell.Input;

namespace Sedulous.Shell.SDL3;

using internal Sedulous.Shell.SDL3;

/// SDL3 implementation of the shell.
class SDL3Shell : IShell
{
	private SDL3WindowManager mWindowManager = new .() ~ delete _;
	private SDL3InputManager mInputManager = new .() ~ delete _;
	private SDL3Clipboard mClipboard = new .() ~ delete _;
	private SDL3DialogService mDialogService ~ delete _;
	private bool mIsRunning;
	private bool mInitialized;

	public IWindowManager WindowManager => mWindowManager;
	public IInputManager InputManager => mInputManager;
	public IClipboard Clipboard => mClipboard;
	public IDialogService Dialogs => mDialogService;
	public bool IsRunning => mIsRunning;

	public Result<void> Initialize()
	{
		if (mInitialized)
			return .Err;

		// Initialize SDL subsystems
		if (!SDL_Init(.SDL_INIT_VIDEO | .SDL_INIT_AUDIO | .SDL_INIT_EVENTS | .SDL_INIT_GAMEPAD))
		{
			return .Err;
		}

		// Initialize any connected gamepads
		mInputManager.InitializeGamepads();

		// Create dialog service
		mDialogService = new SDL3DialogService(mWindowManager);

		mInitialized = true;
		mIsRunning = true;
		return .Ok;
	}

	public void Shutdown()
	{
		if (!mInitialized)
			return;

		mIsRunning = false;

		// Destroy all windows
		mWindowManager.DestroyAllWindows();

		// Quit SDL
		SDL_Quit();

		mInitialized = false;
	}

	public void ProcessEvents()
	{
		if (!mIsRunning)
			return;

		// Begin frame for input devices
		mInputManager.BeginFrame();

		// Poll all pending events
		SDL_Event e = .();
		while (SDL_PollEvent(&e))
		{
			switch ((SDL_EventType)e.type)
			{
			case .SDL_EVENT_QUIT:
				mIsRunning = false;

			// Window events
			case .SDL_EVENT_WINDOW_SHOWN,
				 .SDL_EVENT_WINDOW_HIDDEN,
				 .SDL_EVENT_WINDOW_EXPOSED,
				 .SDL_EVENT_WINDOW_MOVED,
				 .SDL_EVENT_WINDOW_RESIZED,
				 .SDL_EVENT_WINDOW_MINIMIZED,
				 .SDL_EVENT_WINDOW_MAXIMIZED,
				 .SDL_EVENT_WINDOW_RESTORED,
				 .SDL_EVENT_WINDOW_MOUSE_ENTER,
				 .SDL_EVENT_WINDOW_MOUSE_LEAVE,
				 .SDL_EVENT_WINDOW_FOCUS_GAINED,
				 .SDL_EVENT_WINDOW_FOCUS_LOST,
				 .SDL_EVENT_WINDOW_CLOSE_REQUESTED,
				 .SDL_EVENT_WINDOW_ENTER_FULLSCREEN,
				 .SDL_EVENT_WINDOW_LEAVE_FULLSCREEN,
				 .SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED:
				mWindowManager.HandleWindowEvent(&e.window);

				// Update focus window for mouse relative mode
				if ((SDL_EventType)e.type == .SDL_EVENT_WINDOW_FOCUS_GAINED)
				{
					if (let window = mWindowManager.GetSDL3Window(e.window.windowID))
						mInputManager.SetFocusWindow(window.Handle);
				}

			// Input events - delegate to input manager
			default:
				mInputManager.HandleEvent(&e);
			}
		}
	}

	public void RequestExit()
	{
		mIsRunning = false;
	}
}
