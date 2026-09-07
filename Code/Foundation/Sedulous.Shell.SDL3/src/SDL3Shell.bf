using System;
using System.Collections;
using SDL3;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// The desktop shell: one SDL3 backend covering Wayland, X11, Win32 and Cocoa.
///
/// We own the entry point, so SDL_SetMainReady is called before SDL_Init to stop SDL taking
/// main for itself.
///
/// DEGRADES rather than fails: with no display, MainWindow is null and IsRunning is false,
/// so a host exits immediately instead of crashing. That is what lets the whole shell be
/// exercised headlessly.
class SDL3Shell : IShell
{
	private SDL3WindowManager mWindows = new .() ~ delete _;
	private SDL3InputManager mInput = new .() ~ delete _;
	private SDL3DialogService mDialogs ~ delete _;
	private bool mInitialized;
	private bool mRunning = true;
	private delegate bool() mCloseHandler ~ delete _;
	/// Collected during the pump and drained per frame by the host.
	private List<DroppedFile> mDropped = new .() ~ DeleteContainerAndItems!(_);

	public this(WindowSettings settings = .())
	{
		mDialogs = new SDL3DialogService(mWindows);

		SDL3.SDL_SetMainReady();
		if (!SDL3.SDL_Init(.SDL_INIT_VIDEO | .SDL_INIT_GAMEPAD))
		{
			mRunning = false;
			return;
		}
		mInitialized = true;

		if (mWindows.CreateWindow(settings) case .Ok(let main))
		{
			if (let window = mWindows.Find(main.Id))
				mInput.SetWindow(window.Handle);
		}
		else
		{
			mRunning = false;
		}
	}

	public ~this()
	{
		// Devices and windows first, then SDL: anything SDL owned that is freed after
		// SDL_Quit calls into a subsystem that no longer exists.
		mInput.ReleaseDevices();
		mWindows.DestroyAllNow();
		if (mInitialized)
			SDL3.SDL_Quit();
	}

	public IWindowManager WindowManager => mWindows;
	public IWindow MainWindow => mWindows.MainWindow;
	public IInputManager Input => mInput;
	public IDialogService Dialogs => mDialogs;

	/// Running until an exit is asked for or the main window goes.
	public bool IsRunning
	{
		get
		{
			let main = mWindows.MainWindow;
			return mRunning && (main != null) && main.IsOpen;
		}
	}

	public void RequestExit() => mRunning = false;

	/// TAKES OWNERSHIP of the handler, replacing any previous one.
	public void SetMainWindowCloseHandler(delegate bool() handler)
	{
		delete mCloseHandler;
		mCloseHandler = handler;
	}

	public void DrainDroppedFiles(List<DroppedFile> outFiles)
	{
		for (let dropped in mDropped)
			outFiles.Add(dropped);
		mDropped.Clear();
	}

	public void SetClipboardText(StringView text)
	{
		let owned = scope String(text); // Null terminated for the C call.
		SDL3.SDL_SetClipboardText(owned);
	}

	/// SDL allocates the text and the caller frees it.
	public void GetClipboardText(String outText)
	{
		outText.Clear();
		let text = SDL3.SDL_GetClipboardText();
		if (text == null)
			return;
		outText.Append(StringView(text));
		SDL3.SDL_free(text);
	}

	public bool HasClipboardText => SDL3.SDL_HasClipboardText();

	/// Drains SDL's queue into this frame's state.
	///
	/// The devices are rolled FIRST, so everything the loop then delivers belongs to this
	/// frame and the pressed and released edges compare against the last one.
	///
	/// Every input event is both EMITTED and folded into the device snapshot. The stream is
	/// the source of truth and the snapshot is a fold over it; maintaining them separately
	/// is how polling and event handling come to disagree.
	public void ProcessEvents()
	{
		mInput.Update();
		mWindows.ClearEvents();

		SDL_Event event = default;
		while (SDL3.SDL_PollEvent(&event))
		{
			// SDL types the field as a raw integer so user events, which are outside the
			// enumeration, still fit. Everything switched on here IS in it.
			switch ((SDL_EventType)event.type)
			{
			case .SDL_EVENT_DROP_FILE:
				if (event.drop.data != null)
				{
					let dropped = new DroppedFile();
					dropped.Window = (uint32)event.drop.windowID;
					dropped.X = event.drop.x;
					dropped.Y = event.drop.y;
					dropped.Path.Append(StringView(event.drop.data));
					mDropped.Add(dropped);
				}

			case .SDL_EVENT_QUIT:
				// Interceptable, like the close button: an application with unsaved work
				// gets to ask before it goes.
				if (!RequestMainWindowClose())
					break;
				if (let main = mWindows.MainWindow)
				{
					main.Close();
					mWindows.PushEvent(CloseEvent(main.Id));
				}
				mRunning = false;

			case .SDL_EVENT_WINDOW_CLOSE_REQUESTED:
				HandleCloseRequested((uint32)event.window.windowID);

			case .SDL_EVENT_WINDOW_RESIZED:
				let resizedId = (uint32)event.window.windowID;
				if (let window = mWindows.Find(resizedId))
				{
					let width = (uint32)event.window.data1;
					let height = (uint32)event.window.data2;
					window.OnResized(width, height);

					var e = WindowEvent();
					e.Type = .Resized;
					e.WindowId = resizedId;
					e.Width = width;
					e.Height = height;
					mWindows.PushEvent(e);
				}

			case .SDL_EVENT_WINDOW_FOCUS_GAINED:
				let focusedId = (uint32)event.window.windowID;
				// The routing authority for the keyboard and the pads, which are not bound
				// to a window the way the pointer is.
				mInput.SetFocusWindow(focusedId);
				mWindows.PushEvent(SimpleEvent(.FocusGained, focusedId));

			case .SDL_EVENT_WINDOW_FOCUS_LOST:
				let blurredId = (uint32)event.window.windowID;
				// Only if it is still the focused one: focus can have moved on already.
				if (mInput.FocusedWindow == blurredId)
					mInput.SetFocusWindow(0);
				mWindows.PushEvent(SimpleEvent(.FocusLost, blurredId));

			case .SDL_EVENT_WINDOW_MOUSE_ENTER:
				mInput.SetHoverWindow((uint32)event.window.windowID);

			case .SDL_EVENT_WINDOW_MOUSE_LEAVE:
				if (mInput.HoverWindow == (uint32)event.window.windowID)
					mInput.SetHoverWindow(0);

			case .SDL_EVENT_KEY_DOWN, .SDL_EVENT_KEY_UP:
				var e = InputEvent();
				e.Kind = event.key.down ? .KeyDown : .KeyUp;
				e.Window = (uint32)event.key.windowID;
				e.Key = SDL3KeyMap.Key(event.key.scancode);
				e.Modifiers = SDL3KeyMap.Modifiers(event.key.mod);
				mInput.EmitEvent(e);
				// A key this shell does not name still reaches the stream, so a consumer
				// that works in scancodes is not cut off; it is simply not folded into the
				// snapshot, which is indexed by KeyCode.
				if (e.Key != .Unknown)
				{
					mInput.KeyboardDevice.SetKey(e.Key, event.key.down);
					mInput.KeyboardDevice.SetModifiers(e.Modifiers);
				}

			case .SDL_EVENT_MOUSE_MOTION:
				mInput.SetHoverWindow((uint32)event.motion.windowID);
				var e = InputEvent();
				e.Kind = .MouseMove;
				e.Window = (uint32)event.motion.windowID;
				e.X = event.motion.x;
				e.Y = event.motion.y;
				e.DX = event.motion.xrel;
				e.DY = event.motion.yrel;
				mInput.EmitEvent(e);
				mInput.MouseDevice.OnMotion(event.motion.x, event.motion.y,
					event.motion.xrel, event.motion.yrel);

			case .SDL_EVENT_MOUSE_BUTTON_DOWN, .SDL_EVENT_MOUSE_BUTTON_UP:
				let down = ((SDL_EventType)event.type == .SDL_EVENT_MOUSE_BUTTON_DOWN);
				var e = InputEvent();
				e.Kind = down ? .MouseButtonDown : .MouseButtonUp;
				e.Window = (uint32)event.button.windowID;
				e.Button = SDL3KeyMap.Mouse((uint32)event.button.button);
				e.X = event.button.x;
				e.Y = event.button.y;
				mInput.EmitEvent(e);
				mInput.MouseDevice.OnButton((uint32)event.button.button, down);

			case .SDL_EVENT_MOUSE_WHEEL:
				var e = InputEvent();
				e.Kind = .MouseWheel;
				e.Window = (uint32)event.wheel.windowID;
				e.X = event.wheel.x;
				e.Y = event.wheel.y;
				mInput.EmitEvent(e);
				mInput.MouseDevice.OnWheel(event.wheel.x, event.wheel.y);

			case .SDL_EVENT_FINGER_DOWN, .SDL_EVENT_FINGER_MOTION:
				var e = InputEvent();
				e.Kind = ((SDL_EventType)event.type == .SDL_EVENT_FINGER_DOWN) ? .TouchDown : .TouchMove;
				e.Window = (uint32)event.tfinger.windowID;
				e.TouchId = (uint64)event.tfinger.fingerID;
				e.X = event.tfinger.x;
				e.Y = event.tfinger.y;
				e.Value = event.tfinger.pressure;
				mInput.EmitEvent(e);
				mInput.TouchDevice.AddOrUpdate(.(e.TouchId, e.X, e.Y, e.Value));

			case .SDL_EVENT_FINGER_UP:
				var e = InputEvent();
				e.Kind = .TouchUp;
				e.Window = (uint32)event.tfinger.windowID;
				e.TouchId = (uint64)event.tfinger.fingerID;
				e.X = event.tfinger.x;
				e.Y = event.tfinger.y;
				mInput.EmitEvent(e);
				mInput.TouchDevice.Remove(e.TouchId);

			case .SDL_EVENT_GAMEPAD_ADDED:
				mInput.AddGamepad((uint32)event.gdevice.which);

			case .SDL_EVENT_GAMEPAD_REMOVED:
				mInput.RemoveGamepad((uint32)event.gdevice.which);

			case .SDL_EVENT_GAMEPAD_BUTTON_DOWN, .SDL_EVENT_GAMEPAD_BUTTON_UP:
				if (let pad = mInput.FindGamepadById((uint32)event.gbutton.which))
				{
					let button = SDL3KeyMap.Button((SDL_GamepadButton)event.gbutton.button);
					// A button this shell does not name is DROPPED rather than folded onto
					// a neighbour, which would fire the wrong action.
					if (button != .Count)
					{
						let down = ((SDL_EventType)event.type == .SDL_EVENT_GAMEPAD_BUTTON_DOWN);
						var e = InputEvent();
						e.Kind = down ? .GamepadButtonDown : .GamepadButtonUp;
						// Pads are not bound to a window, so they are tagged with whichever
						// one has the focus.
						e.Window = mInput.FocusedWindow;
						e.Gamepad = pad.Index;
						e.PadButton = button;
						mInput.EmitEvent(e);
						pad.SetButton(button, down);
					}
				}

			case .SDL_EVENT_GAMEPAD_AXIS_MOTION:
				if (let pad = mInput.FindGamepadById((uint32)event.gaxis.which))
				{
					let axis = SDL3KeyMap.Axis((SDL_GamepadAxis)event.gaxis.axis);
					if (axis != .Count)
					{
						var e = InputEvent();
						e.Kind = .GamepadAxis;
						e.Window = mInput.FocusedWindow;
						e.Gamepad = pad.Index;
						e.PadAxis = axis;
						e.Value = (float)event.gaxis.value / 32767.0f;
						mInput.EmitEvent(e);
						// Not folded: the pad reads its axes live from SDL, so there is no
						// snapshot to update.
					}
				}

			default:
			}
		}
	}

	/// Asks the installed handler whether the main window may close. No handler means yes.
	public bool RequestMainWindowClose()
	{
		if (mCloseHandler == null)
			return true;
		return mCloseHandler();
	}

	/// A vetoed main window close does NOTHING: no event, no teardown. The application
	/// carries on and exits later on its own terms.
	private void HandleCloseRequested(uint32 id)
	{
		let main = mWindows.MainWindow;
		let isMain = (main != null) && (main.Id == id);

		if (isMain && !RequestMainWindowClose())
			return;

		mWindows.PushEvent(CloseEvent(id));

		// A secondary window closing is the application's business, delivered as an event.
		// The main one closing stops the shell.
		if (isMain)
		{
			main.Close();
			mRunning = false;
		}
	}

	private static WindowEvent CloseEvent(uint32 id) => SimpleEvent(.CloseRequested, id);

	private static WindowEvent SimpleEvent(WindowEventType type, uint32 id)
	{
		var e = WindowEvent();
		e.Type = type;
		e.WindowId = id;
		return e;
	}
}
