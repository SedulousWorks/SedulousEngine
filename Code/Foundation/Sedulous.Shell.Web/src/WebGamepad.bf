using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// One browser gamepad, read through the W3C STANDARD MAPPING.
///
/// That mapping is what makes fixed indices mean fixed buttons: 0 is the south face button on
/// every pad the browser recognises. A pad it cannot map reports an empty mapping string and
/// its indices mean nothing, which is why BrowserButton is a table rather than a cast.
class WebGamepad : IGamepad
{
	private const int cMaxButtons = 20; // the standard mapping's button count
	private const int cMaxAxes = 8;

	private int32 mIndex;
	private String mName = new .() ~ delete _;
	private bool mConnected;
	private bool[cMaxButtons] mButtons;
	private bool[cMaxButtons] mPreviousButtons;
	private float[cMaxAxes] mAxes;
	private float[cMaxButtons] mAnalog;

	public int32 Index => mIndex;
	public StringView Name => mName;
	public bool Connected => mConnected;

	public bool IsButtonDown(GamepadButton button)
	{
		let index = BrowserButton(button);
		return (index >= 0) && mButtons[index];
	}

	public bool IsButtonPressed(GamepadButton button)
	{
		let index = BrowserButton(button);
		return (index >= 0) && mButtons[index] && !mPreviousButtons[index];
	}

	public bool IsButtonReleased(GamepadButton button)
	{
		let index = BrowserButton(button);
		return (index >= 0) && !mButtons[index] && mPreviousButtons[index];
	}

	public float Axis(GamepadAxis axis)
	{
		switch (axis)
		{
		case .LeftX: return mAxes[0];
		case .LeftY: return mAxes[1];
		case .RightX: return mAxes[2];
		case .RightY: return mAxes[3];
		// The triggers are ANALOG BUTTONS in the standard mapping, not axes.
		case .LeftTrigger: return mAnalog[6];
		case .RightTrigger: return mAnalog[7];
		default: return 0.0f;
		}
	}

	/// The Gamepad API's haptics are a separate promise based interface that html5.h does not
	/// bind, so there is nothing to drive.
	public void SetRumble(float lowFrequency, float highFrequency, uint32 durationMs) {}

	public void BeginFrame()
	{
		mPreviousButtons = mButtons;
	}

	public void SetDisconnected()
	{
		mConnected = false;
		mButtons = default;
	}

	public void Ingest(int32 index, EmscriptenGamepadEvent* state)
	{
		mIndex = index;
		mConnected = state.Connected;

		if (mName.IsEmpty)
			mName.Append(&state.Id[0]);

		let buttons = Math.Min((int)state.NumButtons, cMaxButtons);
		for (int i < buttons)
		{
			mButtons[i] = state.DigitalButton[i];
			mAnalog[i] = (float)state.AnalogButton[i];
		}
		for (int i = buttons; i < cMaxButtons; i++)
		{
			mButtons[i] = false;
			mAnalog[i] = 0.0f;
		}

		let axes = Math.Min((int)state.NumAxes, cMaxAxes);
		for (int i < axes)
			mAxes[i] = (float)state.Axis[i];
		for (int i = axes; i < cMaxAxes; i++)
			mAxes[i] = 0.0f;
	}

	/// The standard mapping's index for each of ours, or minus one where the browser has no
	/// counterpart: the paddles, the touchpad and the miscellaneous button are not in it.
	private static int32 BrowserButton(GamepadButton button)
	{
		switch (button)
		{
		case .South: return 0;
		case .East: return 1;
		case .West: return 2;
		case .North: return 3;
		case .LeftShoulder: return 4;
		case .RightShoulder: return 5;
		case .Back: return 8;
		case .Start: return 9;
		case .LeftStick: return 10;
		case .RightStick: return 11;
		case .DPadUp: return 12;
		case .DPadDown: return 13;
		case .DPadLeft: return 14;
		case .DPadRight: return 15;
		case .Guide: return 16;
		default: return -1;
		}
	}
}
