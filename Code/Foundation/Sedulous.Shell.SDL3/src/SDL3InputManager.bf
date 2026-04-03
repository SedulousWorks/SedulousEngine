using System;
using System.Collections;
using SDL3;
using Sedulous.Shell.Input;

namespace Sedulous.Shell.SDL3;

/// SDL3 implementation of input management.
class SDL3InputManager : IInputManager
{
	private SDL3Keyboard mKeyboard = new .() ~ delete _;
	private SDL3Mouse mMouse = new .() ~ delete _;
	private SDL3Touch mTouch = new .() ~ delete _;
	private List<SDL3Gamepad> mGamepads = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mDroppedFiles = new .() ~ DeleteContainerAndItems!(_);

	public const int MaxGamepads = 8;

	public IKeyboard Keyboard => mKeyboard;
	public IMouse Mouse => mMouse;
	public ITouch Touch => mTouch;
	public int GamepadCount => mGamepads.Count;
	public int DroppedFileCount => mDroppedFiles.Count;

	public this()
	{
		// Pre-allocate gamepad slots
		for (int i = 0; i < MaxGamepads; i++)
		{
			mGamepads.Add(new SDL3Gamepad(i));
		}
	}

	public IGamepad GetGamepad(int index)
	{
		if (index >= 0 && index < mGamepads.Count)
			return mGamepads[index];
		return null;
	}

	public StringView GetDroppedFile(int index)
	{
		if (index >= 0 && index < mDroppedFiles.Count)
			return mDroppedFiles[index];
		return default;
	}

	public void Update()
	{
		// Frame update is handled by BeginFrame calls
	}

	/// Called at the start of each frame before processing events.
	public void BeginFrame()
	{
		mKeyboard.BeginFrame();
		mMouse.BeginFrame();
		for (let gamepad in mGamepads)
			gamepad.BeginFrame();

		// Clear dropped files from previous frame
		ClearAndDeleteItems(mDroppedFiles);
	}

	/// Sets the focus window for mouse relative mode.
	public void SetFocusWindow(SDL_Window* window)
	{
		mMouse.SetFocusWindow(window);
	}

	/// Handles an SDL event, routing it to the appropriate input device.
	public void HandleEvent(SDL_Event* e)
	{
		switch ((SDL_EventType)e.type)
		{
		case .SDL_EVENT_KEY_DOWN, .SDL_EVENT_KEY_UP:
			mKeyboard.HandleKeyEvent(&e.key);

		case .SDL_EVENT_TEXT_INPUT:
			mKeyboard.HandleTextInput(&e.text);

		case .SDL_EVENT_MOUSE_MOTION:
			mMouse.HandleMotionEvent(&e.motion);

		case .SDL_EVENT_MOUSE_BUTTON_DOWN, .SDL_EVENT_MOUSE_BUTTON_UP:
			mMouse.HandleButtonEvent(&e.button);

		case .SDL_EVENT_MOUSE_WHEEL:
			mMouse.HandleWheelEvent(&e.wheel);

		case .SDL_EVENT_FINGER_DOWN:
			mTouch.HandleFingerDown(&e.tfinger);

		case .SDL_EVENT_FINGER_UP:
			mTouch.HandleFingerUp(&e.tfinger);

		case .SDL_EVENT_FINGER_MOTION:
			mTouch.HandleFingerMotion(&e.tfinger);

		case .SDL_EVENT_GAMEPAD_ADDED:
			HandleGamepadAdded(e.gdevice.which);

		case .SDL_EVENT_GAMEPAD_REMOVED:
			HandleGamepadRemoved(e.gdevice.which);

		case .SDL_EVENT_GAMEPAD_BUTTON_DOWN, .SDL_EVENT_GAMEPAD_BUTTON_UP:
			HandleGamepadButton(&e.gbutton);

		case .SDL_EVENT_GAMEPAD_AXIS_MOTION:
			HandleGamepadAxis(&e.gaxis);

		case .SDL_EVENT_DROP_FILE:
			HandleFileDrop(&e.drop);

		default:
		}
	}

	private void HandleGamepadAdded(SDL_JoystickID instanceId)
	{
		// Find an empty slot
		for (let gamepad in mGamepads)
		{
			if (!gamepad.Connected)
			{
				gamepad.Open(instanceId);
				break;
			}
		}
	}

	private void HandleGamepadRemoved(SDL_JoystickID instanceId)
	{
		for (let gamepad in mGamepads)
		{
			if (gamepad.Connected && gamepad.InstanceID == instanceId)
			{
				gamepad.Close();
				break;
			}
		}
	}

	private void HandleGamepadButton(SDL_GamepadButtonEvent* e)
	{
		for (let gamepad in mGamepads)
		{
			if (gamepad.Connected && gamepad.InstanceID == e.which)
			{
				gamepad.HandleButtonEvent(e);
				break;
			}
		}
	}

	private void HandleGamepadAxis(SDL_GamepadAxisEvent* e)
	{
		for (let gamepad in mGamepads)
		{
			if (gamepad.Connected && gamepad.InstanceID == e.which)
			{
				gamepad.HandleAxisEvent(e);
				break;
			}
		}
	}

	private void HandleFileDrop(SDL_DropEvent* e)
	{
		if (e.data != null)
		{
			let path = new String(StringView(e.data));
			mDroppedFiles.Add(path);
		}
	}

	/// Opens any gamepads that are already connected at startup.
	public void InitializeGamepads()
	{
		int32 count = 0;
		let gamepads = SDL_GetGamepads(&count);
		if (gamepads != null && count > 0)
		{
			for (int32 i = 0; i < count && i < MaxGamepads; i++)
			{
				mGamepads[i].Open(gamepads[i]);
			}
		}
	}
}
