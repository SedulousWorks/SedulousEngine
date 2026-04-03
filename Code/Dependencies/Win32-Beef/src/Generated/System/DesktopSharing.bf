using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.System.DesktopSharing;

#region Constants
public static
{
	public const uint32 DISPID_RDPSRAPI_METHOD_OPEN = 100;
	public const uint32 DISPID_RDPSRAPI_METHOD_CLOSE = 101;
	public const uint32 DISPID_RDPSRAPI_METHOD_SETSHAREDRECT = 102;
	public const uint32 DISPID_RDPSRAPI_METHOD_GETSHAREDRECT = 103;
	public const uint32 DISPID_RDPSRAPI_METHOD_VIEWERCONNECT = 104;
	public const uint32 DISPID_RDPSRAPI_METHOD_VIEWERDISCONNECT = 105;
	public const uint32 DISPID_RDPSRAPI_METHOD_TERMINATE_CONNECTION = 106;
	public const uint32 DISPID_RDPSRAPI_METHOD_CREATE_INVITATION = 107;
	public const uint32 DISPID_RDPSRAPI_METHOD_REQUEST_CONTROL = 108;
	public const uint32 DISPID_RDPSRAPI_METHOD_VIRTUAL_CHANNEL_CREATE = 109;
	public const uint32 DISPID_RDPSRAPI_METHOD_VIRTUAL_CHANNEL_SEND_DATA = 110;
	public const uint32 DISPID_RDPSRAPI_METHOD_VIRTUAL_CHANNEL_SET_ACCESS = 111;
	public const uint32 DISPID_RDPSRAPI_METHOD_PAUSE = 112;
	public const uint32 DISPID_RDPSRAPI_METHOD_RESUME = 113;
	public const uint32 DISPID_RDPSRAPI_METHOD_SHOW_WINDOW = 114;
	public const uint32 DISPID_RDPSRAPI_METHOD_REQUEST_COLOR_DEPTH_CHANGE = 115;
	public const uint32 DISPID_RDPSRAPI_METHOD_STARTREVCONNECTLISTENER = 116;
	public const uint32 DISPID_RDPSRAPI_METHOD_CONNECTTOCLIENT = 117;
	public const uint32 DISPID_RDPSRAPI_METHOD_SET_RENDERING_SURFACE = 118;
	public const uint32 DISPID_RDPSRAPI_METHOD_SEND_MOUSE_BUTTON_EVENT = 119;
	public const uint32 DISPID_RDPSRAPI_METHOD_SEND_MOUSE_MOVE_EVENT = 120;
	public const uint32 DISPID_RDPSRAPI_METHOD_SEND_MOUSE_WHEEL_EVENT = 121;
	public const uint32 DISPID_RDPSRAPI_METHOD_SEND_KEYBOARD_EVENT = 122;
	public const uint32 DISPID_RDPSRAPI_METHOD_SEND_SYNC_EVENT = 123;
	public const uint32 DISPID_RDPSRAPI_METHOD_BEGIN_TOUCH_FRAME = 124;
	public const uint32 DISPID_RDPSRAPI_METHOD_ADD_TOUCH_INPUT = 125;
	public const uint32 DISPID_RDPSRAPI_METHOD_END_TOUCH_FRAME = 126;
	public const uint32 DISPID_RDPSRAPI_METHOD_CONNECTUSINGTRANSPORTSTREAM = 127;
	public const uint32 DISPID_RDPSRAPI_METHOD_SENDCONTROLLEVELCHANGERESPONSE = 148;
	public const uint32 DISPID_RDPSRAPI_METHOD_GETFRAMEBUFFERBITS = 149;
	public const uint32 DISPID_RDPSRAPI_PROP_DISPIDVALUE = 200;
	public const uint32 DISPID_RDPSRAPI_PROP_ID = 201;
	public const uint32 DISPID_RDPSRAPI_PROP_SESSION_PROPERTIES = 202;
	public const uint32 DISPID_RDPSRAPI_PROP_ATTENDEES = 203;
	public const uint32 DISPID_RDPSRAPI_PROP_INVITATIONS = 204;
	public const uint32 DISPID_RDPSRAPI_PROP_INVITATION = 205;
	public const uint32 DISPID_RDPSRAPI_PROP_CHANNELMANAGER = 206;
	public const uint32 DISPID_RDPSRAPI_PROP_VIRTUAL_CHANNEL_GETNAME = 207;
	public const uint32 DISPID_RDPSRAPI_PROP_VIRTUAL_CHANNEL_GETFLAGS = 208;
	public const uint32 DISPID_RDPSRAPI_PROP_VIRTUAL_CHANNEL_GETPRIORITY = 209;
	public const uint32 DISPID_RDPSRAPI_PROP_WINDOWID = 210;
	public const uint32 DISPID_RDPSRAPI_PROP_APPLICATION = 211;
	public const uint32 DISPID_RDPSRAPI_PROP_WINDOWSHARED = 212;
	public const uint32 DISPID_RDPSRAPI_PROP_WINDOWNAME = 213;
	public const uint32 DISPID_RDPSRAPI_PROP_APPNAME = 214;
	public const uint32 DISPID_RDPSRAPI_PROP_APPLICATION_FILTER = 215;
	public const uint32 DISPID_RDPSRAPI_PROP_WINDOW_LIST = 216;
	public const uint32 DISPID_RDPSRAPI_PROP_APPLICATION_LIST = 217;
	public const uint32 DISPID_RDPSRAPI_PROP_APPFILTER_ENABLED = 218;
	public const uint32 DISPID_RDPSRAPI_PROP_APPFILTERENABLED = 219;
	public const uint32 DISPID_RDPSRAPI_PROP_SHARED = 220;
	public const uint32 DISPID_RDPSRAPI_PROP_INVITATIONITEM = 221;
	public const uint32 DISPID_RDPSRAPI_PROP_DBG_CLX_CMDLINE = 222;
	public const uint32 DISPID_RDPSRAPI_PROP_APPFLAGS = 223;
	public const uint32 DISPID_RDPSRAPI_PROP_WNDFLAGS = 224;
	public const uint32 DISPID_RDPSRAPI_PROP_PROTOCOL_TYPE = 225;
	public const uint32 DISPID_RDPSRAPI_PROP_LOCAL_PORT = 226;
	public const uint32 DISPID_RDPSRAPI_PROP_LOCAL_IP = 227;
	public const uint32 DISPID_RDPSRAPI_PROP_PEER_PORT = 228;
	public const uint32 DISPID_RDPSRAPI_PROP_PEER_IP = 229;
	public const uint32 DISPID_RDPSRAPI_PROP_ATTENDEE_FLAGS = 230;
	public const uint32 DISPID_RDPSRAPI_PROP_CONINFO = 231;
	public const uint32 DISPID_RDPSRAPI_PROP_CONNECTION_STRING = 232;
	public const uint32 DISPID_RDPSRAPI_PROP_GROUP_NAME = 233;
	public const uint32 DISPID_RDPSRAPI_PROP_PASSWORD = 234;
	public const uint32 DISPID_RDPSRAPI_PROP_ATTENDEELIMIT = 235;
	public const uint32 DISPID_RDPSRAPI_PROP_REVOKED = 236;
	public const uint32 DISPID_RDPSRAPI_PROP_DISCONNECTED_STRING = 237;
	public const uint32 DISPID_RDPSRAPI_PROP_USESMARTSIZING = 238;
	public const uint32 DISPID_RDPSRAPI_PROP_SESSION_COLORDEPTH = 239;
	public const uint32 DISPID_RDPSRAPI_PROP_REASON = 240;
	public const uint32 DISPID_RDPSRAPI_PROP_CODE = 241;
	public const uint32 DISPID_RDPSRAPI_PROP_CTRL_LEVEL = 242;
	public const uint32 DISPID_RDPSRAPI_PROP_REMOTENAME = 243;
	public const uint32 DISPID_RDPSRAPI_PROP_COUNT = 244;
	public const uint32 DISPID_RDPSRAPI_PROP_FRAMEBUFFER_HEIGHT = 251;
	public const uint32 DISPID_RDPSRAPI_PROP_FRAMEBUFFER_WIDTH = 252;
	public const uint32 DISPID_RDPSRAPI_PROP_FRAMEBUFFER_BPP = 253;
	public const uint32 DISPID_RDPSRAPI_PROP_FRAMEBUFFER = 254;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_ATTENDEE_CONNECTED = 301;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_ATTENDEE_DISCONNECTED = 302;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_ATTENDEE_UPDATE = 303;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_ERROR = 304;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_VIEWER_CONNECTED = 305;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_VIEWER_DISCONNECTED = 306;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_VIEWER_AUTHENTICATED = 307;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_VIEWER_CONNECTFAILED = 308;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_CTRLLEVEL_CHANGE_REQUEST = 309;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_GRAPHICS_STREAM_PAUSED = 310;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_GRAPHICS_STREAM_RESUMED = 311;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_VIRTUAL_CHANNEL_JOIN = 312;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_VIRTUAL_CHANNEL_LEAVE = 313;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_VIRTUAL_CHANNEL_DATARECEIVED = 314;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_VIRTUAL_CHANNEL_SENDCOMPLETED = 315;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_APPLICATION_OPEN = 316;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_APPLICATION_CLOSE = 317;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_APPLICATION_UPDATE = 318;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_WINDOW_OPEN = 319;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_WINDOW_CLOSE = 320;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_WINDOW_UPDATE = 321;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_APPFILTER_UPDATE = 322;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_SHARED_RECT_CHANGED = 323;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_FOCUSRELEASED = 324;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_SHARED_DESKTOP_SETTINGS_CHANGED = 325;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_CTRLLEVEL_CHANGE_RESPONSE = 338;
	public const uint32 DISPID_RDPAPI_EVENT_ON_BOUNDING_RECT_CHANGED = 340;
	public const uint32 DISPID_RDPSRAPI_METHOD_STREAM_ALLOCBUFFER = 421;
	public const uint32 DISPID_RDPSRAPI_METHOD_STREAM_FREEBUFFER = 422;
	public const uint32 DISPID_RDPSRAPI_METHOD_STREAMSENDDATA = 423;
	public const uint32 DISPID_RDPSRAPI_METHOD_STREAMREADDATA = 424;
	public const uint32 DISPID_RDPSRAPI_METHOD_STREAMOPEN = 425;
	public const uint32 DISPID_RDPSRAPI_METHOD_STREAMCLOSE = 426;
	public const uint32 DISPID_RDPSRAPI_PROP_STREAMBUFFER_STORAGE = 555;
	public const uint32 DISPID_RDPSRAPI_PROP_STREAMBUFFER_PAYLOADSIZE = 558;
	public const uint32 DISPID_RDPSRAPI_PROP_STREAMBUFFER_PAYLOADOFFSET = 559;
	public const uint32 DISPID_RDPSRAPI_PROP_STREAMBUFFER_CONTEXT = 560;
	public const uint32 DISPID_RDPSRAPI_PROP_STREAMBUFFER_FLAGS = 561;
	public const uint32 DISPID_RDPSRAPI_PROP_STREAMBUFFER_STORESIZE = 562;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_STREAM_SENDCOMPLETED = 632;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_STREAM_DATARECEIVED = 633;
	public const uint32 DISPID_RDPSRAPI_EVENT_ON_STREAM_CLOSED = 634;
	public const uint32 DISPID_RDPSRAPI_EVENT_VIEW_MOUSE_BUTTON_RECEIVED = 700;
	public const uint32 DISPID_RDPSRAPI_EVENT_VIEW_MOUSE_MOVE_RECEIVED = 701;
	public const uint32 DISPID_RDPSRAPI_EVENT_VIEW_MOUSE_WHEEL_RECEIVED = 702;
}
#endregion

#region Enums

[AllowDuplicates]
public enum CTRL_LEVEL : int32
{
	CTRL_LEVEL_MIN = 0,
	CTRL_LEVEL_INVALID = 0,
	CTRL_LEVEL_NONE = 1,
	CTRL_LEVEL_VIEW = 2,
	CTRL_LEVEL_INTERACTIVE = 3,
	CTRL_LEVEL_REQCTRL_VIEW = 4,
	CTRL_LEVEL_REQCTRL_INTERACTIVE = 5,
	CTRL_LEVEL_MAX = 5,
}


[AllowDuplicates]
public enum ATTENDEE_DISCONNECT_REASON : int32
{
	ATTENDEE_DISCONNECT_REASON_MIN = 0,
	ATTENDEE_DISCONNECT_REASON_APP = 0,
	ATTENDEE_DISCONNECT_REASON_ERR = 1,
	ATTENDEE_DISCONNECT_REASON_CLI = 2,
	ATTENDEE_DISCONNECT_REASON_MAX = 2,
}


[AllowDuplicates]
public enum CHANNEL_PRIORITY : int32
{
	CHANNEL_PRIORITY_LO = 0,
	CHANNEL_PRIORITY_MED = 1,
	CHANNEL_PRIORITY_HI = 2,
}


[AllowDuplicates]
public enum CHANNEL_FLAGS : int32
{
	CHANNEL_FLAGS_LEGACY = 1,
	CHANNEL_FLAGS_UNCOMPRESSED = 2,
	CHANNEL_FLAGS_DYNAMIC = 4,
}


[AllowDuplicates]
public enum CHANNEL_ACCESS_ENUM : int32
{
	CHANNEL_ACCESS_ENUM_NONE = 0,
	CHANNEL_ACCESS_ENUM_SENDRECEIVE = 1,
}


[AllowDuplicates]
public enum RDPENCOMAPI_ATTENDEE_FLAGS : int32
{
	ATTENDEE_FLAGS_LOCAL = 1,
}


[AllowDuplicates]
public enum RDPSRAPI_WND_FLAGS : int32
{
	WND_FLAG_PRIVILEGED = 1,
}


[AllowDuplicates]
public enum RDPSRAPI_APP_FLAGS : int32
{
	APP_FLAG_PRIVILEGED = 1,
}


[AllowDuplicates]
public enum RDPSRAPI_MOUSE_BUTTON_TYPE : int32
{
	RDPSRAPI_MOUSE_BUTTON_BUTTON1 = 0,
	RDPSRAPI_MOUSE_BUTTON_BUTTON2 = 1,
	RDPSRAPI_MOUSE_BUTTON_BUTTON3 = 2,
	RDPSRAPI_MOUSE_BUTTON_XBUTTON1 = 3,
	RDPSRAPI_MOUSE_BUTTON_XBUTTON2 = 4,
	RDPSRAPI_MOUSE_BUTTON_XBUTTON3 = 5,
}


[AllowDuplicates]
public enum RDPSRAPI_KBD_CODE_TYPE : int32
{
	RDPSRAPI_KBD_CODE_SCANCODE = 0,
	RDPSRAPI_KBD_CODE_UNICODE = 1,
}


[AllowDuplicates]
public enum RDPSRAPI_KBD_SYNC_FLAG : int32
{
	RDPSRAPI_KBD_SYNC_FLAG_SCROLL_LOCK = 1,
	RDPSRAPI_KBD_SYNC_FLAG_NUM_LOCK = 2,
	RDPSRAPI_KBD_SYNC_FLAG_CAPS_LOCK = 4,
	RDPSRAPI_KBD_SYNC_FLAG_KANA_LOCK = 8,
}


[AllowDuplicates]
public enum RDPENCOMAPI_CONSTANTS : int32
{
	CONST_MAX_CHANNEL_MESSAGE_SIZE = 1024,
	CONST_MAX_CHANNEL_NAME_LEN = 8,
	CONST_MAX_LEGACY_CHANNEL_MESSAGE_SIZE = 409600,
	CONST_ATTENDEE_ID_EVERYONE = -1,
	CONST_ATTENDEE_ID_HOST = 0,
	CONST_CONN_INTERVAL = 50,
	CONST_ATTENDEE_ID_DEFAULT = -1,
}

#endregion


#region Structs
[CRepr]
public struct __ReferenceRemainingTypes__
{
	public CTRL_LEVEL __ctrlLevel__;
	public ATTENDEE_DISCONNECT_REASON __attendeeDisconnectReason__;
	public CHANNEL_PRIORITY __channelPriority__;
	public CHANNEL_FLAGS __channelFlags__;
	public CHANNEL_ACCESS_ENUM __channelAccessEnum__;
	public RDPENCOMAPI_ATTENDEE_FLAGS __rdpencomapiAttendeeFlags__;
	public RDPSRAPI_WND_FLAGS __rdpsrapiWndFlags__;
	public RDPSRAPI_APP_FLAGS __rdpsrapiAppFlags__;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_RDPViewer = .(0x32be5ed2, 0x5c86, 0x480f, 0xa9, 0x14, 0x0f, 0xf8, 0x88, 0x5a, 0x1b, 0x3f);


	public const Guid CLSID_RDPSRAPISessionProperties = .(0xdd7594ff, 0xea2a, 0x4c06, 0x8f, 0xdf, 0x13, 0x2d, 0xe4, 0x8b, 0x65, 0x10);


	public const Guid CLSID_RDPSRAPIInvitationManager = .(0x53d9c9db, 0x75ab, 0x4271, 0x94, 0x8a, 0x4c, 0x4e, 0xb3, 0x6a, 0x8f, 0x2b);


	public const Guid CLSID_RDPSRAPIInvitation = .(0x49174dc6, 0x0731, 0x4b5e, 0x8e, 0xe1, 0x83, 0xa6, 0x3d, 0x38, 0x68, 0xfa);


	public const Guid CLSID_RDPSRAPIAttendeeManager = .(0xd7b13a01, 0xf7d4, 0x42a6, 0x85, 0x95, 0x12, 0xfc, 0x8c, 0x24, 0xe8, 0x51);


	public const Guid CLSID_RDPSRAPIAttendee = .(0x74f93bb5, 0x755f, 0x488e, 0x8a, 0x29, 0x23, 0x90, 0x10, 0x8a, 0xef, 0x55);


	public const Guid CLSID_RDPSRAPIAttendeeDisconnectInfo = .(0xb47d7250, 0x5bdb, 0x405d, 0xb4, 0x87, 0xca, 0xad, 0x9c, 0x56, 0xf4, 0xf8);


	public const Guid CLSID_RDPSRAPIApplicationFilter = .(0xe35ace89, 0xc7e8, 0x427e, 0xa4, 0xf9, 0xb9, 0xda, 0x07, 0x28, 0x26, 0xbd);


	public const Guid CLSID_RDPSRAPIApplicationList = .(0x9e31c815, 0x7433, 0x4876, 0x97, 0xfb, 0xed, 0x59, 0xfe, 0x2b, 0xaa, 0x22);


	public const Guid CLSID_RDPSRAPIApplication = .(0xc116a484, 0x4b25, 0x4b9f, 0x8a, 0x54, 0xb9, 0x34, 0xb0, 0x6e, 0x57, 0xfa);


	public const Guid CLSID_RDPSRAPIWindowList = .(0x9c21e2b8, 0x5dd4, 0x42cc, 0x81, 0xba, 0x1c, 0x09, 0x98, 0x52, 0xe6, 0xfa);


	public const Guid CLSID_RDPSRAPIWindow = .(0x03cf46db, 0xce45, 0x4d36, 0x86, 0xed, 0xed, 0x28, 0xb7, 0x43, 0x98, 0xbf);


	public const Guid CLSID_RDPSRAPITcpConnectionInfo = .(0xbe49db3f, 0xebb6, 0x4278, 0x8c, 0xe0, 0xd5, 0x45, 0x58, 0x33, 0xea, 0xee);


	public const Guid CLSID_RDPSession = .(0x9b78f0e6, 0x3e05, 0x4a5b, 0xb2, 0xe8, 0xe7, 0x43, 0xa8, 0x95, 0x6b, 0x65);


	public const Guid CLSID_RDPSRAPIFrameBuffer = .(0xa4f66bcc, 0x538e, 0x4101, 0x95, 0x1d, 0x30, 0x84, 0x7a, 0xdb, 0x51, 0x01);


	public const Guid CLSID_RDPTransportStreamBuffer = .(0x8d4a1c69, 0xf17f, 0x4549, 0xa6, 0x99, 0x76, 0x1c, 0x6e, 0x6b, 0x5c, 0x0a);


	public const Guid CLSID_RDPTransportStreamEvents = .(0x31e3ab20, 0x5350, 0x483f, 0x9d, 0xc6, 0x67, 0x48, 0x66, 0x5e, 0xfd, 0xeb);


}
#endregion

#region COM Types
[CRepr]struct IRDPSRAPIDebug : IUnknown
{
	public new const Guid IID = .(0xaa1e42b5, 0x496d, 0x4ca4, 0xa6, 0x90, 0x34, 0x8d, 0xcb, 0x2e, 0xc4, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR CLXCmdLine) put_CLXCmdLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pCLXCmdLine) get_CLXCmdLine;
	}


	public HRESULT put_CLXCmdLine(BSTR CLXCmdLine) mut => VT.[Friend]put_CLXCmdLine(&this, CLXCmdLine);

	public HRESULT get_CLXCmdLine(BSTR* pCLXCmdLine) mut => VT.[Friend]get_CLXCmdLine(&this, pCLXCmdLine);
}

[CRepr]struct IRDPSRAPIPerfCounterLogger : IUnknown
{
	public new const Guid IID = .(0x071c2533, 0x0fa4, 0x4e8f, 0xae, 0x83, 0x9c, 0x10, 0xb4, 0x30, 0x5a, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 lValue) LogValue;
	}


	public HRESULT LogValue(int64 lValue) mut => VT.[Friend]LogValue(&this, lValue);
}

[CRepr]struct IRDPSRAPIPerfCounterLoggingManager : IUnknown
{
	public new const Guid IID = .(0x9a512c86, 0xac6e, 0x4a8e, 0xb1, 0xa4, 0xfc, 0xef, 0x36, 0x3f, 0x6e, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCounterName, IRDPSRAPIPerfCounterLogger** ppLogger) CreateLogger;
	}


	public HRESULT CreateLogger(BSTR bstrCounterName, IRDPSRAPIPerfCounterLogger** ppLogger) mut => VT.[Friend]CreateLogger(&this, bstrCounterName, ppLogger);
}

[CRepr]struct IRDPSRAPIAudioStream : IUnknown
{
	public new const Guid IID = .(0xe3e30ef9, 0x89c6, 0x4541, 0xba, 0x3b, 0x19, 0x33, 0x6a, 0xc6, 0xd3, 0x1c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pnPeriodInHundredNsIntervals) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppbData, uint32* pcbData, uint64* pTimestamp) GetBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FreeBuffer;
	}


	public HRESULT Initialize(int64* pnPeriodInHundredNsIntervals) mut => VT.[Friend]Initialize(&this, pnPeriodInHundredNsIntervals);

	public HRESULT Start() mut => VT.[Friend]Start(&this);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT GetBuffer(uint8** ppbData, uint32* pcbData, uint64* pTimestamp) mut => VT.[Friend]GetBuffer(&this, ppbData, pcbData, pTimestamp);

	public HRESULT FreeBuffer() mut => VT.[Friend]FreeBuffer(&this);
}

[CRepr]struct IRDPSRAPIClipboardUseEvents : IUnknown
{
	public new const Guid IID = .(0xd559f59a, 0x7a27, 0x4138, 0x87, 0x63, 0x24, 0x7c, 0xe5, 0xf6, 0x59, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 clipboardFormat, IDispatch* pAttendee, int16* pRetVal) OnPasteFromClipboard;
	}


	public HRESULT OnPasteFromClipboard(uint32 clipboardFormat, IDispatch* pAttendee, int16* pRetVal) mut => VT.[Friend]OnPasteFromClipboard(&this, clipboardFormat, pAttendee, pRetVal);
}

[CRepr]struct IRDPSRAPIWindow : IDispatch
{
	public new const Guid IID = .(0xbeafe0f9, 0xc77b, 0x4933, 0xba, 0x9f, 0xa2, 0x4c, 0xdd, 0xcc, 0x27, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIApplication** pApplication) get_Application;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pRetVal) get_Shared;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 NewVal) put_Shared;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRetVal) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) get_Flags;
	}


	public HRESULT get_Id(int32* pRetVal) mut => VT.[Friend]get_Id(&this, pRetVal);

	public HRESULT get_Application(IRDPSRAPIApplication** pApplication) mut => VT.[Friend]get_Application(&this, pApplication);

	public HRESULT get_Shared(int16* pRetVal) mut => VT.[Friend]get_Shared(&this, pRetVal);

	public HRESULT put_Shared(int16 NewVal) mut => VT.[Friend]put_Shared(&this, NewVal);

	public HRESULT get_Name(BSTR* pRetVal) mut => VT.[Friend]get_Name(&this, pRetVal);

	public HRESULT Show() mut => VT.[Friend]Show(&this);

	public HRESULT get_Flags(uint32* pdwFlags) mut => VT.[Friend]get_Flags(&this, pdwFlags);
}

[CRepr]struct IRDPSRAPIWindowList : IDispatch
{
	public new const Guid IID = .(0x8a05ce44, 0x715a, 0x4116, 0xa1, 0x89, 0xa1, 0x18, 0xf3, 0x0a, 0x07, 0xbd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 item, IRDPSRAPIWindow** pWindow) get_Item;
	}


	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Item(int32 item, IRDPSRAPIWindow** pWindow) mut => VT.[Friend]get_Item(&this, item, pWindow);
}

[CRepr]struct IRDPSRAPIApplication : IDispatch
{
	public new const Guid IID = .(0x41e7a09d, 0xeb7a, 0x436e, 0x93, 0x5d, 0x78, 0x0c, 0xa2, 0x62, 0x83, 0x24);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIWindowList** pWindowList) get_Windows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pRetVal) get_Shared;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 NewVal) put_Shared;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pRetVal) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) get_Flags;
	}


	public HRESULT get_Windows(IRDPSRAPIWindowList** pWindowList) mut => VT.[Friend]get_Windows(&this, pWindowList);

	public HRESULT get_Id(int32* pRetVal) mut => VT.[Friend]get_Id(&this, pRetVal);

	public HRESULT get_Shared(int16* pRetVal) mut => VT.[Friend]get_Shared(&this, pRetVal);

	public HRESULT put_Shared(int16 NewVal) mut => VT.[Friend]put_Shared(&this, NewVal);

	public HRESULT get_Name(BSTR* pRetVal) mut => VT.[Friend]get_Name(&this, pRetVal);

	public HRESULT get_Flags(uint32* pdwFlags) mut => VT.[Friend]get_Flags(&this, pdwFlags);
}

[CRepr]struct IRDPSRAPIApplicationList : IDispatch
{
	public new const Guid IID = .(0xd4b4aeb3, 0x22dc, 0x4837, 0xb3, 0xb6, 0x42, 0xea, 0x25, 0x17, 0x84, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 item, IRDPSRAPIApplication** pApplication) get_Item;
	}


	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Item(int32 item, IRDPSRAPIApplication** pApplication) mut => VT.[Friend]get_Item(&this, item, pApplication);
}

[CRepr]struct IRDPSRAPIApplicationFilter : IDispatch
{
	public new const Guid IID = .(0xd20f10ca, 0x6637, 0x4f06, 0xb1, 0xd5, 0x27, 0x7e, 0xa7, 0xe5, 0x16, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIApplicationList** pApplications) get_Applications;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIWindowList** pWindows) get_Windows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pRetVal) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 NewVal) put_Enabled;
	}


	public HRESULT get_Applications(IRDPSRAPIApplicationList** pApplications) mut => VT.[Friend]get_Applications(&this, pApplications);

	public HRESULT get_Windows(IRDPSRAPIWindowList** pWindows) mut => VT.[Friend]get_Windows(&this, pWindows);

	public HRESULT get_Enabled(int16* pRetVal) mut => VT.[Friend]get_Enabled(&this, pRetVal);

	public HRESULT put_Enabled(int16 NewVal) mut => VT.[Friend]put_Enabled(&this, NewVal);
}

[CRepr]struct IRDPSRAPISessionProperties : IDispatch
{
	public new const Guid IID = .(0x339b24f2, 0x9bc0, 0x4f16, 0x9a, 0xac, 0xf1, 0x65, 0x43, 0x3d, 0x13, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PropertyName, VARIANT* pVal) get_Property;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PropertyName, VARIANT newVal) put_Property;
	}


	public HRESULT get_Property(BSTR PropertyName, VARIANT* pVal) mut => VT.[Friend]get_Property(&this, PropertyName, pVal);

	public HRESULT put_Property(BSTR PropertyName, VARIANT newVal) mut => VT.[Friend]put_Property(&this, PropertyName, newVal);
}

[CRepr]struct IRDPSRAPIInvitation : IDispatch
{
	public new const Guid IID = .(0x4fac1d43, 0xfc51, 0x45bb, 0xb1, 0xb4, 0x2b, 0x53, 0xaa, 0x56, 0x2f, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrVal) get_ConnectionString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrVal) get_GroupName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrVal) get_Password;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_AttendeeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_AttendeeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pRetVal) get_Revoked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 NewVal) put_Revoked;
	}


	public HRESULT get_ConnectionString(BSTR* pbstrVal) mut => VT.[Friend]get_ConnectionString(&this, pbstrVal);

	public HRESULT get_GroupName(BSTR* pbstrVal) mut => VT.[Friend]get_GroupName(&this, pbstrVal);

	public HRESULT get_Password(BSTR* pbstrVal) mut => VT.[Friend]get_Password(&this, pbstrVal);

	public HRESULT get_AttendeeLimit(int32* pRetVal) mut => VT.[Friend]get_AttendeeLimit(&this, pRetVal);

	public HRESULT put_AttendeeLimit(int32 NewVal) mut => VT.[Friend]put_AttendeeLimit(&this, NewVal);

	public HRESULT get_Revoked(int16* pRetVal) mut => VT.[Friend]get_Revoked(&this, pRetVal);

	public HRESULT put_Revoked(int16 NewVal) mut => VT.[Friend]put_Revoked(&this, NewVal);
}

[CRepr]struct IRDPSRAPIInvitationManager : IDispatch
{
	public new const Guid IID = .(0x4722b049, 0x92c3, 0x4c2d, 0x8a, 0x65, 0xf7, 0x34, 0x8f, 0x64, 0x4d, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT item, IRDPSRAPIInvitation** ppInvitation) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRetVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAuthString, BSTR bstrGroupName, BSTR bstrPassword, int32 AttendeeLimit, IRDPSRAPIInvitation** ppInvitation) CreateInvitation;
	}


	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Item(VARIANT item, IRDPSRAPIInvitation** ppInvitation) mut => VT.[Friend]get_Item(&this, item, ppInvitation);

	public HRESULT get_Count(int32* pRetVal) mut => VT.[Friend]get_Count(&this, pRetVal);

	public HRESULT CreateInvitation(BSTR bstrAuthString, BSTR bstrGroupName, BSTR bstrPassword, int32 AttendeeLimit, IRDPSRAPIInvitation** ppInvitation) mut => VT.[Friend]CreateInvitation(&this, bstrAuthString, bstrGroupName, bstrPassword, AttendeeLimit, ppInvitation);
}

[CRepr]struct IRDPSRAPITcpConnectionInfo : IDispatch
{
	public new const Guid IID = .(0xf74049a4, 0x3d06, 0x4028, 0x81, 0x93, 0x0a, 0x8c, 0x29, 0xbc, 0x24, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProtocol) get_Protocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPort) get_LocalPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbsrLocalIP) get_LocalIP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPort) get_PeerPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrIP) get_PeerIP;
	}


	public HRESULT get_Protocol(int32* plProtocol) mut => VT.[Friend]get_Protocol(&this, plProtocol);

	public HRESULT get_LocalPort(int32* plPort) mut => VT.[Friend]get_LocalPort(&this, plPort);

	public HRESULT get_LocalIP(BSTR* pbsrLocalIP) mut => VT.[Friend]get_LocalIP(&this, pbsrLocalIP);

	public HRESULT get_PeerPort(int32* plPort) mut => VT.[Friend]get_PeerPort(&this, plPort);

	public HRESULT get_PeerIP(BSTR* pbstrIP) mut => VT.[Friend]get_PeerIP(&this, pbstrIP);
}

[CRepr]struct IRDPSRAPIAttendee : IDispatch
{
	public new const Guid IID = .(0xec0671b3, 0x1b78, 0x4b80, 0xa4, 0x64, 0x91, 0x32, 0x24, 0x75, 0x43, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_RemoteName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CTRL_LEVEL* pVal) get_ControlLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CTRL_LEVEL pNewVal) put_ControlLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIInvitation** ppVal) get_Invitation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TerminateConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFlags) get_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppVal) get_ConnectivityInfo;
	}


	public HRESULT get_Id(int32* pId) mut => VT.[Friend]get_Id(&this, pId);

	public HRESULT get_RemoteName(BSTR* pVal) mut => VT.[Friend]get_RemoteName(&this, pVal);

	public HRESULT get_ControlLevel(CTRL_LEVEL* pVal) mut => VT.[Friend]get_ControlLevel(&this, pVal);

	public HRESULT put_ControlLevel(CTRL_LEVEL pNewVal) mut => VT.[Friend]put_ControlLevel(&this, pNewVal);

	public HRESULT get_Invitation(IRDPSRAPIInvitation** ppVal) mut => VT.[Friend]get_Invitation(&this, ppVal);

	public HRESULT TerminateConnection() mut => VT.[Friend]TerminateConnection(&this);

	public HRESULT get_Flags(int32* plFlags) mut => VT.[Friend]get_Flags(&this, plFlags);

	public HRESULT get_ConnectivityInfo(IUnknown** ppVal) mut => VT.[Friend]get_ConnectivityInfo(&this, ppVal);
}

[CRepr]struct IRDPSRAPIAttendeeManager : IDispatch
{
	public new const Guid IID = .(0xba3a37e8, 0x33da, 0x4749, 0x8d, 0xa0, 0x07, 0xfa, 0x34, 0xda, 0x79, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 id, IRDPSRAPIAttendee** ppItem) get_Item;
	}


	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Item(int32 id, IRDPSRAPIAttendee** ppItem) mut => VT.[Friend]get_Item(&this, id, ppItem);
}

[CRepr]struct IRDPSRAPIAttendeeDisconnectInfo : IDispatch
{
	public new const Guid IID = .(0xc187689f, 0x447c, 0x44a1, 0x9c, 0x14, 0xff, 0xfb, 0xb3, 0xb7, 0xec, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIAttendee** retval) get_Attendee;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ATTENDEE_DISCONNECT_REASON* pReason) get_Reason;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Code;
	}


	public HRESULT get_Attendee(IRDPSRAPIAttendee** retval) mut => VT.[Friend]get_Attendee(&this, retval);

	public HRESULT get_Reason(ATTENDEE_DISCONNECT_REASON* pReason) mut => VT.[Friend]get_Reason(&this, pReason);

	public HRESULT get_Code(int32* pVal) mut => VT.[Friend]get_Code(&this, pVal);
}

[CRepr]struct IRDPSRAPIVirtualChannel : IDispatch
{
	public new const Guid IID = .(0x05e12f95, 0x28b3, 0x4c9a, 0x87, 0x80, 0xd0, 0x24, 0x85, 0x74, 0xa1, 0xe0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrData, int32 lAttendeeId, uint32 ChannelSendFlags) SendData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAttendeeId, CHANNEL_ACCESS_ENUM AccessType) SetAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFlags) get_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CHANNEL_PRIORITY* pPriority) get_Priority;
	}


	public HRESULT SendData(BSTR bstrData, int32 lAttendeeId, uint32 ChannelSendFlags) mut => VT.[Friend]SendData(&this, bstrData, lAttendeeId, ChannelSendFlags);

	public HRESULT SetAccess(int32 lAttendeeId, CHANNEL_ACCESS_ENUM AccessType) mut => VT.[Friend]SetAccess(&this, lAttendeeId, AccessType);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT get_Flags(int32* plFlags) mut => VT.[Friend]get_Flags(&this, plFlags);

	public HRESULT get_Priority(CHANNEL_PRIORITY* pPriority) mut => VT.[Friend]get_Priority(&this, pPriority);
}

[CRepr]struct IRDPSRAPIVirtualChannelManager : IDispatch
{
	public new const Guid IID = .(0x0d11c661, 0x5d0d, 0x4ee4, 0x89, 0xdf, 0x21, 0x66, 0xae, 0x1f, 0xdf, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT item, IRDPSRAPIVirtualChannel** pChannel) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrChannelName, CHANNEL_PRIORITY Priority, uint32 ChannelFlags, IRDPSRAPIVirtualChannel** ppChannel) CreateVirtualChannel;
	}


	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Item(VARIANT item, IRDPSRAPIVirtualChannel** pChannel) mut => VT.[Friend]get_Item(&this, item, pChannel);

	public HRESULT CreateVirtualChannel(BSTR bstrChannelName, CHANNEL_PRIORITY Priority, uint32 ChannelFlags, IRDPSRAPIVirtualChannel** ppChannel) mut => VT.[Friend]CreateVirtualChannel(&this, bstrChannelName, Priority, ChannelFlags, ppChannel);
}

[CRepr]struct IRDPSRAPIViewer : IDispatch
{
	public new const Guid IID = .(0xc6bfcd38, 0x8ce9, 0x404d, 0x8a, 0xe8, 0xf3, 0x1d, 0x00, 0xc6, 0x5c, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrConnectionString, BSTR bstrName, BSTR bstrPassword) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIAttendeeManager** ppVal) get_Attendees;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIInvitationManager** ppVal) get_Invitations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIApplicationFilter** ppVal) get_ApplicationFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIVirtualChannelManager** ppVal) get_VirtualChannelManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 vbSmartSizing) put_SmartSizing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbSmartSizing) get_SmartSizing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CTRL_LEVEL CtrlLevel) RequestControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDisconnectedText) put_DisconnectedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDisconnectedText) get_DisconnectedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Bpp) RequestColorDepthChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPISessionProperties** ppVal) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrConnectionString, BSTR bstrUserName, BSTR bstrPassword, BSTR* pbstrReverseConnectString) StartReverseConnectListener;
	}


	public HRESULT Connect(BSTR bstrConnectionString, BSTR bstrName, BSTR bstrPassword) mut => VT.[Friend]Connect(&this, bstrConnectionString, bstrName, bstrPassword);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);

	public HRESULT get_Attendees(IRDPSRAPIAttendeeManager** ppVal) mut => VT.[Friend]get_Attendees(&this, ppVal);

	public HRESULT get_Invitations(IRDPSRAPIInvitationManager** ppVal) mut => VT.[Friend]get_Invitations(&this, ppVal);

	public HRESULT get_ApplicationFilter(IRDPSRAPIApplicationFilter** ppVal) mut => VT.[Friend]get_ApplicationFilter(&this, ppVal);

	public HRESULT get_VirtualChannelManager(IRDPSRAPIVirtualChannelManager** ppVal) mut => VT.[Friend]get_VirtualChannelManager(&this, ppVal);

	public HRESULT put_SmartSizing(int16 vbSmartSizing) mut => VT.[Friend]put_SmartSizing(&this, vbSmartSizing);

	public HRESULT get_SmartSizing(int16* pvbSmartSizing) mut => VT.[Friend]get_SmartSizing(&this, pvbSmartSizing);

	public HRESULT RequestControl(CTRL_LEVEL CtrlLevel) mut => VT.[Friend]RequestControl(&this, CtrlLevel);

	public HRESULT put_DisconnectedText(BSTR bstrDisconnectedText) mut => VT.[Friend]put_DisconnectedText(&this, bstrDisconnectedText);

	public HRESULT get_DisconnectedText(BSTR* pbstrDisconnectedText) mut => VT.[Friend]get_DisconnectedText(&this, pbstrDisconnectedText);

	public HRESULT RequestColorDepthChange(int32 Bpp) mut => VT.[Friend]RequestColorDepthChange(&this, Bpp);

	public HRESULT get_Properties(IRDPSRAPISessionProperties** ppVal) mut => VT.[Friend]get_Properties(&this, ppVal);

	public HRESULT StartReverseConnectListener(BSTR bstrConnectionString, BSTR bstrUserName, BSTR bstrPassword, BSTR* pbstrReverseConnectString) mut => VT.[Friend]StartReverseConnectListener(&this, bstrConnectionString, bstrUserName, bstrPassword, pbstrReverseConnectString);
}

[CRepr]struct IRDPViewerInputSink : IUnknown
{
	public new const Guid IID = .(0xbb590853, 0xa6c5, 0x4a7b, 0x8d, 0xd4, 0x76, 0xb6, 0x9e, 0xea, 0x12, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RDPSRAPI_MOUSE_BUTTON_TYPE buttonType, int16 vbButtonDown, uint32 xPos, uint32 yPos) SendMouseButtonEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 xPos, uint32 yPos) SendMouseMoveEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wheelRotation) SendMouseWheelEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RDPSRAPI_KBD_CODE_TYPE codeType, uint16 keycode, int16 vbKeyUp, int16 vbRepeat, int16 vbExtended) SendKeyboardEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 syncFlags) SendSyncEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BeginTouchFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 contactId, uint32 event, int32 x, int32 y) AddTouchInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndTouchFrame;
	}


	public HRESULT SendMouseButtonEvent(RDPSRAPI_MOUSE_BUTTON_TYPE buttonType, int16 vbButtonDown, uint32 xPos, uint32 yPos) mut => VT.[Friend]SendMouseButtonEvent(&this, buttonType, vbButtonDown, xPos, yPos);

	public HRESULT SendMouseMoveEvent(uint32 xPos, uint32 yPos) mut => VT.[Friend]SendMouseMoveEvent(&this, xPos, yPos);

	public HRESULT SendMouseWheelEvent(uint16 wheelRotation) mut => VT.[Friend]SendMouseWheelEvent(&this, wheelRotation);

	public HRESULT SendKeyboardEvent(RDPSRAPI_KBD_CODE_TYPE codeType, uint16 keycode, int16 vbKeyUp, int16 vbRepeat, int16 vbExtended) mut => VT.[Friend]SendKeyboardEvent(&this, codeType, keycode, vbKeyUp, vbRepeat, vbExtended);

	public HRESULT SendSyncEvent(uint32 syncFlags) mut => VT.[Friend]SendSyncEvent(&this, syncFlags);

	public HRESULT BeginTouchFrame() mut => VT.[Friend]BeginTouchFrame(&this);

	public HRESULT AddTouchInput(uint32 contactId, uint32 event, int32 x, int32 y) mut => VT.[Friend]AddTouchInput(&this, contactId, event, x, y);

	public HRESULT EndTouchFrame() mut => VT.[Friend]EndTouchFrame(&this);
}

[CRepr]struct IRDPSRAPIFrameBuffer : IDispatch
{
	public new const Guid IID = .(0x3d67e7d2, 0xb27b, 0x448e, 0x81, 0xb3, 0xc6, 0x11, 0x0e, 0xd8, 0xb4, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plWidth) get_Width;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHeight) get_Height;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBpp) get_Bpp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 x, int32 y, int32 Width, int32 Heigth, SAFEARRAY** ppBits) GetFrameBufferBits;
	}


	public HRESULT get_Width(int32* plWidth) mut => VT.[Friend]get_Width(&this, plWidth);

	public HRESULT get_Height(int32* plHeight) mut => VT.[Friend]get_Height(&this, plHeight);

	public HRESULT get_Bpp(int32* plBpp) mut => VT.[Friend]get_Bpp(&this, plBpp);

	public HRESULT GetFrameBufferBits(int32 x, int32 y, int32 Width, int32 Heigth, SAFEARRAY** ppBits) mut => VT.[Friend]GetFrameBufferBits(&this, x, y, Width, Heigth, ppBits);
}

[CRepr]struct IRDPSRAPITransportStreamBuffer : IUnknown
{
	public new const Guid IID = .(0x81c80290, 0x5085, 0x44b0, 0xb4, 0x60, 0xf8, 0x65, 0xc3, 0x9c, 0xb4, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppbStorage) get_Storage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaxStore) get_StorageSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetVal) get_PayloadSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lVal) put_PayloadSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetVal) get_PayloadOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRetVal) put_PayloadOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFlags) get_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags) put_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppContext) get_Context;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pContext) put_Context;
	}


	public HRESULT get_Storage(uint8** ppbStorage) mut => VT.[Friend]get_Storage(&this, ppbStorage);

	public HRESULT get_StorageSize(int32* plMaxStore) mut => VT.[Friend]get_StorageSize(&this, plMaxStore);

	public HRESULT get_PayloadSize(int32* plRetVal) mut => VT.[Friend]get_PayloadSize(&this, plRetVal);

	public HRESULT put_PayloadSize(int32 lVal) mut => VT.[Friend]put_PayloadSize(&this, lVal);

	public HRESULT get_PayloadOffset(int32* plRetVal) mut => VT.[Friend]get_PayloadOffset(&this, plRetVal);

	public HRESULT put_PayloadOffset(int32 lRetVal) mut => VT.[Friend]put_PayloadOffset(&this, lRetVal);

	public HRESULT get_Flags(int32* plFlags) mut => VT.[Friend]get_Flags(&this, plFlags);

	public HRESULT put_Flags(int32 lFlags) mut => VT.[Friend]put_Flags(&this, lFlags);

	public HRESULT get_Context(IUnknown** ppContext) mut => VT.[Friend]get_Context(&this, ppContext);

	public HRESULT put_Context(IUnknown* pContext) mut => VT.[Friend]put_Context(&this, pContext);
}

[CRepr]struct IRDPSRAPITransportStreamEvents : IUnknown
{
	public new const Guid IID = .(0xea81c254, 0xf5af, 0x4e40, 0x98, 0x2e, 0x3e, 0x63, 0xbb, 0x59, 0x52, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IRDPSRAPITransportStreamBuffer* pBuffer) OnWriteCompleted;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IRDPSRAPITransportStreamBuffer* pBuffer) OnReadCompleted;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, HRESULT hrReason) OnStreamClosed;
	}


	public void OnWriteCompleted(IRDPSRAPITransportStreamBuffer* pBuffer) mut => VT.[Friend]OnWriteCompleted(&this, pBuffer);

	public void OnReadCompleted(IRDPSRAPITransportStreamBuffer* pBuffer) mut => VT.[Friend]OnReadCompleted(&this, pBuffer);

	public void OnStreamClosed(HRESULT hrReason) mut => VT.[Friend]OnStreamClosed(&this, hrReason);
}

[CRepr]struct IRDPSRAPITransportStream : IUnknown
{
	public new const Guid IID = .(0x36cfa065, 0x43bb, 0x4ef7, 0xae, 0xd7, 0x9b, 0x88, 0xa5, 0x05, 0x30, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 maxPayload, IRDPSRAPITransportStreamBuffer** ppBuffer) AllocBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPITransportStreamBuffer* pBuffer) FreeBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPITransportStreamBuffer* pBuffer) WriteBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPITransportStreamBuffer* pBuffer) ReadBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPITransportStreamEvents* pCallbacks) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT AllocBuffer(int32 maxPayload, IRDPSRAPITransportStreamBuffer** ppBuffer) mut => VT.[Friend]AllocBuffer(&this, maxPayload, ppBuffer);

	public HRESULT FreeBuffer(IRDPSRAPITransportStreamBuffer* pBuffer) mut => VT.[Friend]FreeBuffer(&this, pBuffer);

	public HRESULT WriteBuffer(IRDPSRAPITransportStreamBuffer* pBuffer) mut => VT.[Friend]WriteBuffer(&this, pBuffer);

	public HRESULT ReadBuffer(IRDPSRAPITransportStreamBuffer* pBuffer) mut => VT.[Friend]ReadBuffer(&this, pBuffer);

	public HRESULT Open(IRDPSRAPITransportStreamEvents* pCallbacks) mut => VT.[Friend]Open(&this, pCallbacks);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IRDPSRAPISharingSession : IDispatch
{
	public new const Guid IID = .(0xeeb20886, 0xe470, 0x4cf6, 0x84, 0x2b, 0x27, 0x39, 0xc0, 0xec, 0x5c, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 colorDepth) put_ColorDepth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pColorDepth) get_ColorDepth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPISessionProperties** ppVal) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIAttendeeManager** ppVal) get_Attendees;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIInvitationManager** ppVal) get_Invitations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIApplicationFilter** ppVal) get_ApplicationFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIVirtualChannelManager** ppVal) get_VirtualChannelManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrConnectionString) ConnectToClient;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 left, int32 top, int32 right, int32 bottom) SetDesktopSharedRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pleft, int32* ptop, int32* pright, int32* pbottom) GetDesktopSharedRect;
	}


	public HRESULT Open() mut => VT.[Friend]Open(&this);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT put_ColorDepth(int32 colorDepth) mut => VT.[Friend]put_ColorDepth(&this, colorDepth);

	public HRESULT get_ColorDepth(int32* pColorDepth) mut => VT.[Friend]get_ColorDepth(&this, pColorDepth);

	public HRESULT get_Properties(IRDPSRAPISessionProperties** ppVal) mut => VT.[Friend]get_Properties(&this, ppVal);

	public HRESULT get_Attendees(IRDPSRAPIAttendeeManager** ppVal) mut => VT.[Friend]get_Attendees(&this, ppVal);

	public HRESULT get_Invitations(IRDPSRAPIInvitationManager** ppVal) mut => VT.[Friend]get_Invitations(&this, ppVal);

	public HRESULT get_ApplicationFilter(IRDPSRAPIApplicationFilter** ppVal) mut => VT.[Friend]get_ApplicationFilter(&this, ppVal);

	public HRESULT get_VirtualChannelManager(IRDPSRAPIVirtualChannelManager** ppVal) mut => VT.[Friend]get_VirtualChannelManager(&this, ppVal);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT ConnectToClient(BSTR bstrConnectionString) mut => VT.[Friend]ConnectToClient(&this, bstrConnectionString);

	public HRESULT SetDesktopSharedRect(int32 left, int32 top, int32 right, int32 bottom) mut => VT.[Friend]SetDesktopSharedRect(&this, left, top, right, bottom);

	public HRESULT GetDesktopSharedRect(int32* pleft, int32* ptop, int32* pright, int32* pbottom) mut => VT.[Friend]GetDesktopSharedRect(&this, pleft, ptop, pright, pbottom);
}

[CRepr]struct IRDPSRAPISharingSession2 : IRDPSRAPISharingSession
{
	public new const Guid IID = .(0xfee4ee57, 0xe3e8, 0x4205, 0x8f, 0xb0, 0x8f, 0xd1, 0xd0, 0x67, 0x5c, 0x21);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRDPSRAPISharingSession.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPITransportStream* pStream, BSTR bstrGroup, BSTR bstrAuthenticatedAttendeeName) ConnectUsingTransportStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIFrameBuffer** ppVal) get_FrameBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRDPSRAPIAttendee* pAttendee, CTRL_LEVEL RequestedLevel, int32 ReasonCode) SendControlLevelChangeResponse;
	}


	public HRESULT ConnectUsingTransportStream(IRDPSRAPITransportStream* pStream, BSTR bstrGroup, BSTR bstrAuthenticatedAttendeeName) mut => VT.[Friend]ConnectUsingTransportStream(&this, pStream, bstrGroup, bstrAuthenticatedAttendeeName);

	public HRESULT get_FrameBuffer(IRDPSRAPIFrameBuffer** ppVal) mut => VT.[Friend]get_FrameBuffer(&this, ppVal);

	public HRESULT SendControlLevelChangeResponse(IRDPSRAPIAttendee* pAttendee, CTRL_LEVEL RequestedLevel, int32 ReasonCode) mut => VT.[Friend]SendControlLevelChangeResponse(&this, pAttendee, RequestedLevel, ReasonCode);
}

[CRepr]struct _IRDPSessionEvents : IDispatch
{
	public new const Guid IID = .(0x98a97042, 0x6698, 0x40e9, 0x8e, 0xfd, 0xb3, 0x20, 0x09, 0x90, 0x00, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

#endregion
