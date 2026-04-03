using Win32.Foundation;
using System;

namespace Win32.UI.Input;

#region TypeDefs
typealias HRAWINPUT = int;

#endregion


#region Enums

[AllowDuplicates]
public enum RAW_INPUT_DATA_COMMAND_FLAGS : uint32
{
	RID_HEADER = 268435461,
	RID_INPUT = 268435459,
}


[AllowDuplicates]
public enum RAW_INPUT_DEVICE_INFO_COMMAND : uint32
{
	RIDI_PREPARSEDDATA = 536870917,
	RIDI_DEVICENAME = 536870919,
	RIDI_DEVICEINFO = 536870923,
}


[AllowDuplicates]
public enum RID_DEVICE_INFO_TYPE : uint32
{
	RIM_TYPEMOUSE = 0,
	RIM_TYPEKEYBOARD = 1,
	RIM_TYPEHID = 2,
}


[AllowDuplicates]
public enum RAWINPUTDEVICE_FLAGS : uint32
{
	RIDEV_REMOVE = 1,
	RIDEV_EXCLUDE = 16,
	RIDEV_PAGEONLY = 32,
	RIDEV_NOLEGACY = 48,
	RIDEV_INPUTSINK = 256,
	RIDEV_CAPTUREMOUSE = 512,
	RIDEV_NOHOTKEYS = 512,
	RIDEV_APPKEYS = 1024,
	RIDEV_EXINPUTSINK = 4096,
	RIDEV_DEVNOTIFY = 8192,
}


[AllowDuplicates]
public enum INPUT_MESSAGE_DEVICE_TYPE : int32
{
	IMDT_UNAVAILABLE = 0,
	IMDT_KEYBOARD = 1,
	IMDT_MOUSE = 2,
	IMDT_TOUCH = 4,
	IMDT_PEN = 8,
	IMDT_TOUCHPAD = 16,
}


[AllowDuplicates]
public enum INPUT_MESSAGE_ORIGIN_ID : int32
{
	IMO_UNAVAILABLE = 0,
	IMO_HARDWARE = 1,
	IMO_INJECTED = 2,
	IMO_SYSTEM = 4,
}

#endregion


#region Structs
[CRepr]
public struct RAWINPUTHEADER
{
	public uint32 dwType;
	public uint32 dwSize;
	public HANDLE hDevice;
	public WPARAM wParam;
}

[CRepr]
public struct RAWMOUSE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 usButtonFlags;
			public uint16 usButtonData;
		}
		public uint32 ulButtons;
		public using _Anonymous_e__Struct Anonymous;
	}
	public uint16 usFlags;
	public using _Anonymous_e__Union Anonymous;
	public uint32 ulRawButtons;
	public int32 lLastX;
	public int32 lLastY;
	public uint32 ulExtraInformation;
}

[CRepr]
public struct RAWKEYBOARD
{
	public uint16 MakeCode;
	public uint16 Flags;
	public uint16 Reserved;
	public uint16 VKey;
	public uint32 Message;
	public uint32 ExtraInformation;
}

[CRepr]
public struct RAWHID
{
	public uint32 dwSizeHid;
	public uint32 dwCount;
	public uint8* bRawData mut => &bRawData_impl;
	private uint8[ANYSIZE_ARRAY] bRawData_impl;
}

[CRepr]
public struct RAWINPUT
{
	[CRepr, Union]
	public struct _data_e__Union
	{
		public RAWMOUSE mouse;
		public RAWKEYBOARD keyboard;
		public RAWHID hid;
	}
	public RAWINPUTHEADER header;
	public _data_e__Union data;
}

[CRepr]
public struct RID_DEVICE_INFO_MOUSE
{
	public uint32 dwId;
	public uint32 dwNumberOfButtons;
	public uint32 dwSampleRate;
	public BOOL fHasHorizontalWheel;
}

[CRepr]
public struct RID_DEVICE_INFO_KEYBOARD
{
	public uint32 dwType;
	public uint32 dwSubType;
	public uint32 dwKeyboardMode;
	public uint32 dwNumberOfFunctionKeys;
	public uint32 dwNumberOfIndicators;
	public uint32 dwNumberOfKeysTotal;
}

[CRepr]
public struct RID_DEVICE_INFO_HID
{
	public uint32 dwVendorId;
	public uint32 dwProductId;
	public uint32 dwVersionNumber;
	public uint16 usUsagePage;
	public uint16 usUsage;
}

[CRepr]
public struct RID_DEVICE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public RID_DEVICE_INFO_MOUSE mouse;
		public RID_DEVICE_INFO_KEYBOARD keyboard;
		public RID_DEVICE_INFO_HID hid;
	}
	public uint32 cbSize;
	public RID_DEVICE_INFO_TYPE dwType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct RAWINPUTDEVICE
{
	public uint16 usUsagePage;
	public uint16 usUsage;
	public RAWINPUTDEVICE_FLAGS dwFlags;
	public HWND hwndTarget;
}

[CRepr]
public struct RAWINPUTDEVICELIST
{
	public HANDLE hDevice;
	public RID_DEVICE_INFO_TYPE dwType;
}

[CRepr]
public struct INPUT_MESSAGE_SOURCE
{
	public INPUT_MESSAGE_DEVICE_TYPE deviceType;
	public INPUT_MESSAGE_ORIGIN_ID originId;
}

#endregion

#region Functions
public static
{
	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetRawInputData(HRAWINPUT hRawInput, RAW_INPUT_DATA_COMMAND_FLAGS uiCommand, void* pData, uint32* pcbSize, uint32 cbSizeHeader);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetRawInputDeviceInfoA(HANDLE hDevice, RAW_INPUT_DEVICE_INFO_COMMAND uiCommand, void* pData, uint32* pcbSize);
	public static uint32 GetRawInputDeviceInfo(HANDLE hDevice, RAW_INPUT_DEVICE_INFO_COMMAND uiCommand, void* pData, uint32* pcbSize) => GetRawInputDeviceInfoA(hDevice, uiCommand, pData, pcbSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetRawInputDeviceInfoW(HANDLE hDevice, RAW_INPUT_DEVICE_INFO_COMMAND uiCommand, void* pData, uint32* pcbSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetRawInputBuffer(RAWINPUT* pData, uint32* pcbSize, uint32 cbSizeHeader);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterRawInputDevices(RAWINPUTDEVICE* pRawInputDevices, uint32 uiNumDevices, uint32 cbSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetRegisteredRawInputDevices(RAWINPUTDEVICE* pRawInputDevices, uint32* puiNumDevices, uint32 cbSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetRawInputDeviceList(RAWINPUTDEVICELIST* pRawInputDeviceList, uint32* puiNumDevices, uint32 cbSize);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT DefRawInputProc(RAWINPUT** paRawInput, int32 nInput, uint32 cbSizeHeader);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCurrentInputMessageSource(INPUT_MESSAGE_SOURCE* inputMessageSource);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCIMSSM(INPUT_MESSAGE_SOURCE* inputMessageSource);

}
#endregion
