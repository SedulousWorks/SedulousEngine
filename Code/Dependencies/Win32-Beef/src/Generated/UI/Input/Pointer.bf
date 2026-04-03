using Win32.UI.WindowsAndMessaging;
using Win32.Foundation;
using Win32.UI.Controls;
using System;

namespace Win32.UI.Input.Pointer;

#region Enums

[AllowDuplicates]
public enum POINTER_FLAGS : uint32
{
	POINTER_FLAG_NONE = 0,
	POINTER_FLAG_NEW = 1,
	POINTER_FLAG_INRANGE = 2,
	POINTER_FLAG_INCONTACT = 4,
	POINTER_FLAG_FIRSTBUTTON = 16,
	POINTER_FLAG_SECONDBUTTON = 32,
	POINTER_FLAG_THIRDBUTTON = 64,
	POINTER_FLAG_FOURTHBUTTON = 128,
	POINTER_FLAG_FIFTHBUTTON = 256,
	POINTER_FLAG_PRIMARY = 8192,
	POINTER_FLAG_CONFIDENCE = 16384,
	POINTER_FLAG_CANCELED = 32768,
	POINTER_FLAG_DOWN = 65536,
	POINTER_FLAG_UPDATE = 131072,
	POINTER_FLAG_UP = 262144,
	POINTER_FLAG_WHEEL = 524288,
	POINTER_FLAG_HWHEEL = 1048576,
	POINTER_FLAG_CAPTURECHANGED = 2097152,
	POINTER_FLAG_HASTRANSFORM = 4194304,
}


[AllowDuplicates]
public enum TOUCH_FEEDBACK_MODE : uint32
{
	TOUCH_FEEDBACK_DEFAULT = 1,
	TOUCH_FEEDBACK_INDIRECT = 2,
	TOUCH_FEEDBACK_NONE = 3,
}


[AllowDuplicates]
public enum POINTER_BUTTON_CHANGE_TYPE : int32
{
	POINTER_CHANGE_NONE = 0,
	POINTER_CHANGE_FIRSTBUTTON_DOWN = 1,
	POINTER_CHANGE_FIRSTBUTTON_UP = 2,
	POINTER_CHANGE_SECONDBUTTON_DOWN = 3,
	POINTER_CHANGE_SECONDBUTTON_UP = 4,
	POINTER_CHANGE_THIRDBUTTON_DOWN = 5,
	POINTER_CHANGE_THIRDBUTTON_UP = 6,
	POINTER_CHANGE_FOURTHBUTTON_DOWN = 7,
	POINTER_CHANGE_FOURTHBUTTON_UP = 8,
	POINTER_CHANGE_FIFTHBUTTON_DOWN = 9,
	POINTER_CHANGE_FIFTHBUTTON_UP = 10,
}

#endregion


#region Structs
[CRepr]
public struct POINTER_INFO
{
	public POINTER_INPUT_TYPE pointerType;
	public uint32 pointerId;
	public uint32 frameId;
	public POINTER_FLAGS pointerFlags;
	public HANDLE sourceDevice;
	public HWND hwndTarget;
	public POINT ptPixelLocation;
	public POINT ptHimetricLocation;
	public POINT ptPixelLocationRaw;
	public POINT ptHimetricLocationRaw;
	public uint32 dwTime;
	public uint32 historyCount;
	public int32 InputData;
	public uint32 dwKeyStates;
	public uint64 PerformanceCount;
	public POINTER_BUTTON_CHANGE_TYPE ButtonChangeType;
}

[CRepr]
public struct POINTER_TOUCH_INFO
{
	public POINTER_INFO pointerInfo;
	public uint32 touchFlags;
	public uint32 touchMask;
	public RECT rcContact;
	public RECT rcContactRaw;
	public uint32 orientation;
	public uint32 pressure;
}

[CRepr]
public struct POINTER_PEN_INFO
{
	public POINTER_INFO pointerInfo;
	public uint32 penFlags;
	public uint32 penMask;
	public uint32 pressure;
	public uint32 rotation;
	public int32 tiltX;
	public int32 tiltY;
}

[CRepr]
public struct INPUT_INJECTION_VALUE
{
	public uint16 page;
	public uint16 usage;
	public int32 value;
	public uint16 index;
}

[CRepr]
public struct INPUT_TRANSFORM
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public float _11;
			public float _12;
			public float _13;
			public float _14;
			public float _21;
			public float _22;
			public float _23;
			public float _24;
			public float _31;
			public float _32;
			public float _33;
			public float _34;
			public float _41;
			public float _42;
			public float _43;
			public float _44;
		}
		public using _Anonymous_e__Struct Anonymous;
		public float[16] m;
	}
	public using _Anonymous_e__Union Anonymous;
}

#endregion

#region Functions
public static
{
	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetUnpredictedMessagePos();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitializeTouchInjection(uint32 maxCount, TOUCH_FEEDBACK_MODE dwMode);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InjectTouchInput(uint32 count, POINTER_TOUCH_INFO* contacts);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerType(uint32 pointerId, POINTER_INPUT_TYPE* pointerType);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerCursorId(uint32 pointerId, uint32* cursorId);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerInfo(uint32 pointerId, POINTER_INFO* pointerInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerInfoHistory(uint32 pointerId, uint32* entriesCount, POINTER_INFO* pointerInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerFrameInfo(uint32 pointerId, uint32* pointerCount, POINTER_INFO* pointerInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerFrameInfoHistory(uint32 pointerId, uint32* entriesCount, uint32* pointerCount, POINTER_INFO* pointerInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerTouchInfo(uint32 pointerId, POINTER_TOUCH_INFO* touchInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerTouchInfoHistory(uint32 pointerId, uint32* entriesCount, POINTER_TOUCH_INFO* touchInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerFrameTouchInfo(uint32 pointerId, uint32* pointerCount, POINTER_TOUCH_INFO* touchInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerFrameTouchInfoHistory(uint32 pointerId, uint32* entriesCount, uint32* pointerCount, POINTER_TOUCH_INFO* touchInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerPenInfo(uint32 pointerId, POINTER_PEN_INFO* penInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerPenInfoHistory(uint32 pointerId, uint32* entriesCount, POINTER_PEN_INFO* penInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerFramePenInfo(uint32 pointerId, uint32* pointerCount, POINTER_PEN_INFO* penInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerFramePenInfoHistory(uint32 pointerId, uint32* entriesCount, uint32* pointerCount, POINTER_PEN_INFO* penInfo);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SkipPointerFrameMessages(uint32 pointerId);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InjectSyntheticPointerInput(HSYNTHETICPOINTERDEVICE device, POINTER_TYPE_INFO* pointerInfo, uint32 count);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnableMouseInPointer(BOOL fEnable);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsMouseInPointerEnabled();

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerInputTransform(uint32 pointerId, uint32 historyCount, INPUT_TRANSFORM* inputTransform);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerDevices(uint32* deviceCount, POINTER_DEVICE_INFO* pointerDevices);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerDevice(HANDLE device, POINTER_DEVICE_INFO* pointerDevice);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerDeviceProperties(HANDLE device, uint32* propertyCount, POINTER_DEVICE_PROPERTY* pointerProperties);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerDeviceRects(HANDLE device, RECT* pointerDeviceRect, RECT* displayRect);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPointerDeviceCursors(HANDLE device, uint32* cursorCount, POINTER_DEVICE_CURSOR_INFO* deviceCursors);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetRawPointerDeviceData(uint32 pointerId, uint32 historyCount, uint32 propertiesCount, POINTER_DEVICE_PROPERTY* pProperties, int32* pValues);

}
#endregion
