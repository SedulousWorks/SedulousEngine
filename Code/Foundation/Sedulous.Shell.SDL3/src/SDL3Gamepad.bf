using System;
using SDL3;
using Sedulous.Shell.Input;

namespace Sedulous.Shell.SDL3;

/// SDL3 implementation of gamepad input.
class SDL3Gamepad : IGamepad
{
	private int mIndex;
	private String mName = new .() ~ delete _;
	private SDL_Gamepad* mGamepad;
	private SDL_JoystickID mInstanceID;
	private bool mConnected;

	private bool[(int)GamepadButton.Count] mCurrentButtons;
	private bool[(int)GamepadButton.Count] mPreviousButtons;
	private float[(int)GamepadAxis.Count] mAxes;

	public int Index => mIndex;
	public StringView Name => mName;
	public bool Connected => mConnected;

	public this(int index)
	{
		mIndex = index;
	}

	public bool IsButtonDown(GamepadButton button)
	{
		let index = (int)button;
		if (index < 0 || index >= (int)GamepadButton.Count)
			return false;
		return mCurrentButtons[index];
	}

	public bool IsButtonPressed(GamepadButton button)
	{
		let index = (int)button;
		if (index < 0 || index >= (int)GamepadButton.Count)
			return false;
		return mCurrentButtons[index] && !mPreviousButtons[index];
	}

	public bool IsButtonReleased(GamepadButton button)
	{
		let index = (int)button;
		if (index < 0 || index >= (int)GamepadButton.Count)
			return false;
		return !mCurrentButtons[index] && mPreviousButtons[index];
	}

	public float GetAxis(GamepadAxis axis)
	{
		let index = (int)axis;
		if (index < 0 || index >= (int)GamepadAxis.Count)
			return 0;
		return mAxes[index];
	}

	public void SetRumble(float lowFreq, float highFreq, uint32 durationMs)
	{
		if (mGamepad != null)
		{
			let low = (uint16)(lowFreq * 65535);
			let high = (uint16)(highFreq * 65535);
			SDL_RumbleGamepad(mGamepad, low, high, durationMs);
		}
	}

	/// Called before processing new events.
	public void BeginFrame()
	{
		mPreviousButtons = mCurrentButtons;
	}

	/// Opens the gamepad with the given instance ID.
	public void Open(SDL_JoystickID instanceId)
	{
		if (mGamepad != null)
			Close();

		mGamepad = SDL_OpenGamepad(instanceId);
		if (mGamepad != null)
		{
			mInstanceID = instanceId;
			mConnected = true;
			let namePtr = SDL_GetGamepadName(mGamepad);
			if (namePtr != null)
				mName.Set(StringView(namePtr));
			else
				mName.Set("Unknown Gamepad");
		}
	}

	/// Closes the gamepad.
	public void Close()
	{
		if (mGamepad != null)
		{
			SDL_CloseGamepad(mGamepad);
			mGamepad = null;
			mConnected = false;
			mName.Clear();
		}
	}

	/// Gets the instance ID.
	public SDL_JoystickID InstanceID => mInstanceID;

	/// Handles a gamepad button event.
	public void HandleButtonEvent(SDL_GamepadButtonEvent* e)
	{
		let button = ConvertButton((SDL_GamepadButton)e.button);
		let index = (int)button;
		if (index >= 0 && index < (int)GamepadButton.Count)
		{
			mCurrentButtons[index] = e.down;
		}
	}

	/// Handles a gamepad axis event.
	public void HandleAxisEvent(SDL_GamepadAxisEvent* e)
	{
		let axis = ConvertAxis((SDL_GamepadAxis)e.axis);
		let index = (int)axis;
		if (index >= 0 && index < (int)GamepadAxis.Count)
		{
			// Convert from -32768..32767 to -1..1 for sticks
			// or 0..32767 to 0..1 for triggers
			if (axis == .LeftTrigger || axis == .RightTrigger)
				mAxes[index] = (float)e.value / 32767.0f;
			else
				mAxes[index] = (float)e.value / 32767.0f;
		}
	}

	private static GamepadButton ConvertButton(SDL_GamepadButton sdlButton)
	{
		switch (sdlButton)
		{
		case .SDL_GAMEPAD_BUTTON_SOUTH: return .South;
		case .SDL_GAMEPAD_BUTTON_EAST: return .East;
		case .SDL_GAMEPAD_BUTTON_WEST: return .West;
		case .SDL_GAMEPAD_BUTTON_NORTH: return .North;
		case .SDL_GAMEPAD_BUTTON_BACK: return .Back;
		case .SDL_GAMEPAD_BUTTON_GUIDE: return .Guide;
		case .SDL_GAMEPAD_BUTTON_START: return .Start;
		case .SDL_GAMEPAD_BUTTON_LEFT_STICK: return .LeftStick;
		case .SDL_GAMEPAD_BUTTON_RIGHT_STICK: return .RightStick;
		case .SDL_GAMEPAD_BUTTON_LEFT_SHOULDER: return .LeftShoulder;
		case .SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER: return .RightShoulder;
		case .SDL_GAMEPAD_BUTTON_DPAD_UP: return .DPadUp;
		case .SDL_GAMEPAD_BUTTON_DPAD_DOWN: return .DPadDown;
		case .SDL_GAMEPAD_BUTTON_DPAD_LEFT: return .DPadLeft;
		case .SDL_GAMEPAD_BUTTON_DPAD_RIGHT: return .DPadRight;
		case .SDL_GAMEPAD_BUTTON_MISC1: return .Misc1;
		case .SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1: return .RightPaddle1;
		case .SDL_GAMEPAD_BUTTON_LEFT_PADDLE1: return .LeftPaddle1;
		case .SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2: return .RightPaddle2;
		case .SDL_GAMEPAD_BUTTON_LEFT_PADDLE2: return .LeftPaddle2;
		case .SDL_GAMEPAD_BUTTON_TOUCHPAD: return .Touchpad;
		default: return .South;
		}
	}

	private static GamepadAxis ConvertAxis(SDL_GamepadAxis sdlAxis)
	{
		switch (sdlAxis)
		{
		case .SDL_GAMEPAD_AXIS_LEFTX: return .LeftX;
		case .SDL_GAMEPAD_AXIS_LEFTY: return .LeftY;
		case .SDL_GAMEPAD_AXIS_RIGHTX: return .RightX;
		case .SDL_GAMEPAD_AXIS_RIGHTY: return .RightY;
		case .SDL_GAMEPAD_AXIS_LEFT_TRIGGER: return .LeftTrigger;
		case .SDL_GAMEPAD_AXIS_RIGHT_TRIGGER: return .RightTrigger;
		default: return .LeftX;
		}
	}
}
