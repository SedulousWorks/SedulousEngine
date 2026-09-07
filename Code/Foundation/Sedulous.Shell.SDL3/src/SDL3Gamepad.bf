using System;
using Sedulous.Core;
using SDL3;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// One connected pad.
///
/// Owns its SDL handle and closes it, so unplugging a pad frees the device with no separate
/// bookkeeping. Must go before SDL_Quit, which the input manager guarantees.
class SDL3Gamepad : IGamepad
{
	private SDL_Gamepad* mPad;
	private uint32 mId;
	private int32 mIndex;
	private String mName = new .() ~ delete _;
	private bool[(int)GamepadButton.Count] mCurrent;
	private bool[(int)GamepadButton.Count] mPrevious;

	public this(SDL_Gamepad* pad, uint32 id, int32 index, StringView name)
	{
		mPad = pad;
		mId = id;
		mIndex = index;
		mName.Set(name);
	}

	public ~this()
	{
		if (mPad != null)
			SDL3.SDL_CloseGamepad(mPad);
	}

	public uint32 Id => mId;
	public SDL_Gamepad* Handle => mPad;

	public int32 Index => mIndex;
	public StringView Name => mName;

	/// A pad that has been unplugged reports disconnected but stays in the list until the
	/// manager sweeps it, so an index a caller is holding does not shift under it mid frame.
	public bool Connected => mPad != null;

	public bool IsButtonDown(GamepadButton button) => mCurrent[Index_(button)];
	public bool IsButtonPressed(GamepadButton button) => mCurrent[Index_(button)] && !mPrevious[Index_(button)];
	public bool IsButtonReleased(GamepadButton button) => !mCurrent[Index_(button)] && mPrevious[Index_(button)];

	/// Sticks come back in [-1, 1] and triggers in [0, 1], which is what SDL's signed
	/// sixteen bit range divides down to.
	public float Axis(GamepadAxis axis)
	{
		if (mPad == null)
			return 0.0f;
		let sdlAxis = SdlAxis(axis);
		if (sdlAxis == .SDL_GAMEPAD_AXIS_INVALID)
			return 0.0f;

		let raw = SDL3.SDL_GetGamepadAxis(mPad, sdlAxis);
		if ((axis == .LeftTrigger) || (axis == .RightTrigger))
			return (float)raw / 32767.0f;
		// The negative side of the range is one larger, so dividing by 32767 would let a
		// full deflection read slightly past minus one.
		return (raw < 0) ? ((float)raw / 32768.0f) : ((float)raw / 32767.0f);
	}

	public void SetRumble(float lowFrequency, float highFrequency, uint32 durationMs)
	{
		if (mPad == null)
			return;
		let low = (uint16)(Clamp(lowFrequency, 0.0f, 1.0f) * 65535.0f);
		let high = (uint16)(Clamp(highFrequency, 0.0f, 1.0f) * 65535.0f);
		SDL3.SDL_RumbleGamepad(mPad, low, high, durationMs);
	}

	public void SetIndex(int32 index) => mIndex = index;
	public void SetButton(GamepadButton button, bool down) => mCurrent[Index_(button)] = down;

	/// The device is gone but the object stays, so a caller mid frame reads disconnected
	/// rather than following a freed handle.
	public void Disconnect() => mPad = null;

	public void BeginFrame()
	{
		mPrevious = mCurrent;
	}

	private static int Index_(GamepadButton button)
	{
		let index = (int)button;
		return ((index >= 0) && (index < (int)GamepadButton.Count)) ? index : 0;
	}

	private static SDL_GamepadAxis SdlAxis(GamepadAxis axis)
	{
		switch (axis)
		{
		case .LeftX: return .SDL_GAMEPAD_AXIS_LEFTX;
		case .LeftY: return .SDL_GAMEPAD_AXIS_LEFTY;
		case .RightX: return .SDL_GAMEPAD_AXIS_RIGHTX;
		case .RightY: return .SDL_GAMEPAD_AXIS_RIGHTY;
		case .LeftTrigger: return .SDL_GAMEPAD_AXIS_LEFT_TRIGGER;
		case .RightTrigger: return .SDL_GAMEPAD_AXIS_RIGHT_TRIGGER;
		default: return .SDL_GAMEPAD_AXIS_INVALID;
		}
	}
}
