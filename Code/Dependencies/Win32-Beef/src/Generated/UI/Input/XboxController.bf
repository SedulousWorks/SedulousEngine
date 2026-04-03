using Win32.Foundation;
using System;

namespace Win32.UI.Input.XboxController;

#region Constants
public static
{
	public const String XINPUT_DLL_A = "xinput1_4.dll";
	public const String XINPUT_DLL_W = "xinput1_4.dll";
	public const String XINPUT_DLL = "xinput1_4.dll";
	public const uint32 XUSER_MAX_COUNT = 4;
	public const uint32 XUSER_INDEX_ANY = 255;
}
#endregion

#region Enums

[AllowDuplicates]
public enum XINPUT_VIRTUAL_KEY : uint16
{
	VK_PAD_A = 22528,
	VK_PAD_B = 22529,
	VK_PAD_X = 22530,
	VK_PAD_Y = 22531,
	VK_PAD_RSHOULDER = 22532,
	VK_PAD_LSHOULDER = 22533,
	VK_PAD_LTRIGGER = 22534,
	VK_PAD_RTRIGGER = 22535,
	VK_PAD_DPAD_UP = 22544,
	VK_PAD_DPAD_DOWN = 22545,
	VK_PAD_DPAD_LEFT = 22546,
	VK_PAD_DPAD_RIGHT = 22547,
	VK_PAD_START = 22548,
	VK_PAD_BACK = 22549,
	VK_PAD_LTHUMB_PRESS = 22550,
	VK_PAD_RTHUMB_PRESS = 22551,
	VK_PAD_LTHUMB_UP = 22560,
	VK_PAD_LTHUMB_DOWN = 22561,
	VK_PAD_LTHUMB_RIGHT = 22562,
	VK_PAD_LTHUMB_LEFT = 22563,
	VK_PAD_LTHUMB_UPLEFT = 22564,
	VK_PAD_LTHUMB_UPRIGHT = 22565,
	VK_PAD_LTHUMB_DOWNRIGHT = 22566,
	VK_PAD_LTHUMB_DOWNLEFT = 22567,
	VK_PAD_RTHUMB_UP = 22576,
	VK_PAD_RTHUMB_DOWN = 22577,
	VK_PAD_RTHUMB_RIGHT = 22578,
	VK_PAD_RTHUMB_LEFT = 22579,
	VK_PAD_RTHUMB_UPLEFT = 22580,
	VK_PAD_RTHUMB_UPRIGHT = 22581,
	VK_PAD_RTHUMB_DOWNRIGHT = 22582,
	VK_PAD_RTHUMB_DOWNLEFT = 22583,
}


[AllowDuplicates]
public enum BATTERY_TYPE : uint32
{
	BATTERY_TYPE_DISCONNECTED = 0,
	BATTERY_TYPE_WIRED = 1,
	BATTERY_TYPE_ALKALINE = 2,
	BATTERY_TYPE_NIMH = 3,
	BATTERY_TYPE_UNKNOWN = 255,
}


[AllowDuplicates]
public enum BATTERY_LEVEL : uint32
{
	BATTERY_LEVEL_EMPTY = 0,
	BATTERY_LEVEL_LOW = 1,
	BATTERY_LEVEL_MEDIUM = 2,
	BATTERY_LEVEL_FULL = 3,
}


[AllowDuplicates]
public enum BATTERY_DEVTYPE : uint32
{
	BATTERY_DEVTYPE_GAMEPAD = 0,
	BATTERY_DEVTYPE_HEADSET = 1,
}


[AllowDuplicates]
public enum XINPUT_DEVTYPE : uint32
{
	XINPUT_DEVTYPE_GAMEPAD = 1,
}


[AllowDuplicates]
public enum XINPUT_DEVSUBTYPE : uint32
{
	XINPUT_DEVSUBTYPE_GAMEPAD = 1,
	XINPUT_DEVSUBTYPE_UNKNOWN = 0,
	XINPUT_DEVSUBTYPE_WHEEL = 2,
	XINPUT_DEVSUBTYPE_ARCADE_STICK = 3,
	XINPUT_DEVSUBTYPE_FLIGHT_STICK = 4,
	XINPUT_DEVSUBTYPE_DANCE_PAD = 5,
	XINPUT_DEVSUBTYPE_GUITAR = 6,
	XINPUT_DEVSUBTYPE_GUITAR_ALTERNATE = 7,
	XINPUT_DEVSUBTYPE_DRUM_KIT = 8,
	XINPUT_DEVSUBTYPE_GUITAR_BASS = 11,
	XINPUT_DEVSUBTYPE_ARCADE_PAD = 19,
}


[AllowDuplicates]
public enum XINPUT_CAPABILITIES_FLAGS : uint16
{
	XINPUT_CAPS_VOICE_SUPPORTED = 4,
	XINPUT_CAPS_FFB_SUPPORTED = 1,
	XINPUT_CAPS_WIRELESS = 2,
	XINPUT_CAPS_PMD_SUPPORTED = 8,
	XINPUT_CAPS_NO_NAVIGATION = 16,
}


[AllowDuplicates]
public enum XINPUT_GAMEPAD_BUTTON_FLAGS : uint16
{
	XINPUT_GAMEPAD_DPAD_UP = 1,
	XINPUT_GAMEPAD_DPAD_DOWN = 2,
	XINPUT_GAMEPAD_DPAD_LEFT = 4,
	XINPUT_GAMEPAD_DPAD_RIGHT = 8,
	XINPUT_GAMEPAD_START = 16,
	XINPUT_GAMEPAD_BACK = 32,
	XINPUT_GAMEPAD_LEFT_THUMB = 64,
	XINPUT_GAMEPAD_RIGHT_THUMB = 128,
	XINPUT_GAMEPAD_LEFT_SHOULDER = 256,
	XINPUT_GAMEPAD_RIGHT_SHOULDER = 512,
	XINPUT_GAMEPAD_A = 4096,
	XINPUT_GAMEPAD_B = 8192,
	XINPUT_GAMEPAD_X = 16384,
	XINPUT_GAMEPAD_Y = 32768,
	XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE = 7849,
	XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE = 8689,
	XINPUT_GAMEPAD_TRIGGER_THRESHOLD = 30,
}


[AllowDuplicates]
public enum XINPUT_KEYSTROKE_FLAGS : uint16
{
	XINPUT_KEYSTROKE_KEYDOWN = 1,
	XINPUT_KEYSTROKE_KEYUP = 2,
	XINPUT_KEYSTROKE_REPEAT = 4,
}


[AllowDuplicates]
public enum XINPUT_FLAG : uint32
{
	XINPUT_FLAG_ALL = 0,
	XINPUT_FLAG_GAMEPAD = 1,
}

#endregion


#region Structs
[CRepr]
public struct XINPUT_GAMEPAD
{
	public XINPUT_GAMEPAD_BUTTON_FLAGS wButtons;
	public uint8 bLeftTrigger;
	public uint8 bRightTrigger;
	public int16 sThumbLX;
	public int16 sThumbLY;
	public int16 sThumbRX;
	public int16 sThumbRY;
}

[CRepr]
public struct XINPUT_STATE
{
	public uint32 dwPacketNumber;
	public XINPUT_GAMEPAD Gamepad;
}

[CRepr]
public struct XINPUT_VIBRATION
{
	public uint16 wLeftMotorSpeed;
	public uint16 wRightMotorSpeed;
}

[CRepr]
public struct XINPUT_CAPABILITIES
{
	public XINPUT_DEVTYPE Type;
	public XINPUT_DEVSUBTYPE SubType;
	public XINPUT_CAPABILITIES_FLAGS Flags;
	public XINPUT_GAMEPAD Gamepad;
	public XINPUT_VIBRATION Vibration;
}

[CRepr]
public struct XINPUT_BATTERY_INFORMATION
{
	public BATTERY_TYPE BatteryType;
	public BATTERY_LEVEL BatteryLevel;
}

[CRepr]
public struct XINPUT_KEYSTROKE
{
	public XINPUT_VIRTUAL_KEY VirtualKey;
	public char16 Unicode;
	public XINPUT_KEYSTROKE_FLAGS Flags;
	public uint8 UserIndex;
	public uint8 HidCode;
}

#endregion

#region Functions
public static
{
	[Import("XINPUTUAP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 XInputGetState(uint32 dwUserIndex, XINPUT_STATE* pState);

	[Import("XINPUTUAP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 XInputSetState(uint32 dwUserIndex, XINPUT_VIBRATION* pVibration);

	[Import("XINPUTUAP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 XInputGetCapabilities(uint32 dwUserIndex, XINPUT_FLAG dwFlags, XINPUT_CAPABILITIES* pCapabilities);

	[Import("XINPUTUAP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void XInputEnable(BOOL enable);

	[Import("XINPUTUAP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 XInputGetAudioDeviceIds(uint32 dwUserIndex, char16* pRenderDeviceId, uint32* pRenderCount, char16* pCaptureDeviceId, uint32* pCaptureCount);

	[Import("XINPUTUAP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 XInputGetBatteryInformation(uint32 dwUserIndex, BATTERY_DEVTYPE devType, XINPUT_BATTERY_INFORMATION* pBatteryInformation);

	[Import("XINPUTUAP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 XInputGetKeystroke(uint32 dwUserIndex, uint32 dwReserved, XINPUT_KEYSTROKE* pKeystroke);

}
#endregion
