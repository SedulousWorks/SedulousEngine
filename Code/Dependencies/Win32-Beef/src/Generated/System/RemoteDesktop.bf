using Win32.System.Com;
using Win32.Foundation;
using Win32.Media.Audio;
using Win32.Media.Audio.Apo;
using Win32.System.Com.StructuredStorage;
using Win32.System.WinRT;
using Win32.UI.WindowsAndMessaging;
using Win32.Security;
using System;

namespace Win32.System.RemoteDesktop;

#region Constants
public static
{
	public const uint32 WTS_DOMAIN_LENGTH = 255;
	public const uint32 WTS_USERNAME_LENGTH = 255;
	public const uint32 WTS_PASSWORD_LENGTH = 255;
	public const uint32 WTS_DIRECTORY_LENGTH = 256;
	public const uint32 WTS_INITIALPROGRAM_LENGTH = 256;
	public const uint32 WTS_PROTOCOL_NAME_LENGTH = 8;
	public const uint32 WTS_DRIVER_NAME_LENGTH = 8;
	public const uint32 WTS_DEVICE_NAME_LENGTH = 19;
	public const uint32 WTS_IMEFILENAME_LENGTH = 32;
	public const uint32 WTS_CLIENTNAME_LENGTH = 20;
	public const uint32 WTS_CLIENTADDRESS_LENGTH = 30;
	public const uint32 WTS_CLIENT_PRODUCT_ID_LENGTH = 32;
	public const uint32 WTS_MAX_PROTOCOL_CACHE = 4;
	public const uint32 WTS_MAX_CACHE_RESERVED = 20;
	public const uint32 WTS_MAX_RESERVED = 100;
	public const uint32 WTS_MAX_COUNTERS = 100;
	public const uint32 WTS_MAX_DISPLAY_IOCTL_DATA = 256;
	public const uint32 WTS_PERF_DISABLE_NOTHING = 0;
	public const uint32 WTS_PERF_DISABLE_WALLPAPER = 1;
	public const uint32 WTS_PERF_DISABLE_FULLWINDOWDRAG = 2;
	public const uint32 WTS_PERF_DISABLE_MENUANIMATIONS = 4;
	public const uint32 WTS_PERF_DISABLE_THEMING = 8;
	public const uint32 WTS_PERF_ENABLE_ENHANCED_GRAPHICS = 16;
	public const uint32 WTS_PERF_DISABLE_CURSOR_SHADOW = 32;
	public const uint32 WTS_PERF_DISABLE_CURSORSETTINGS = 64;
	public const uint32 WTS_PERF_ENABLE_FONT_SMOOTHING = 128;
	public const uint32 WTS_PERF_ENABLE_DESKTOP_COMPOSITION = 256;
	public const uint32 WTS_VALUE_TYPE_ULONG = 1;
	public const uint32 WTS_VALUE_TYPE_STRING = 2;
	public const uint32 WTS_VALUE_TYPE_BINARY = 3;
	public const uint32 WTS_VALUE_TYPE_GUID = 4;
	public const uint32 WTS_KEY_EXCHANGE_ALG_RSA = 1;
	public const uint32 WTS_KEY_EXCHANGE_ALG_DH = 2;
	public const uint32 WTS_LICENSE_PROTOCOL_VERSION = 65536;
	public const uint32 WTS_LICENSE_PREAMBLE_VERSION = 3;
	public const uint32 WRDS_DOMAIN_LENGTH = 255;
	public const uint32 WRDS_USERNAME_LENGTH = 255;
	public const uint32 WRDS_PASSWORD_LENGTH = 255;
	public const uint32 WRDS_DIRECTORY_LENGTH = 256;
	public const uint32 WRDS_INITIALPROGRAM_LENGTH = 256;
	public const uint32 WRDS_PROTOCOL_NAME_LENGTH = 8;
	public const uint32 WRDS_DRIVER_NAME_LENGTH = 8;
	public const uint32 WRDS_DEVICE_NAME_LENGTH = 19;
	public const uint32 WRDS_IMEFILENAME_LENGTH = 32;
	public const uint32 WRDS_CLIENTNAME_LENGTH = 20;
	public const uint32 WRDS_CLIENTADDRESS_LENGTH = 30;
	public const uint32 WRDS_CLIENT_PRODUCT_ID_LENGTH = 32;
	public const uint32 WRDS_MAX_PROTOCOL_CACHE = 4;
	public const uint32 WRDS_MAX_CACHE_RESERVED = 20;
	public const uint32 WRDS_MAX_RESERVED = 100;
	public const uint32 WRDS_MAX_COUNTERS = 100;
	public const uint32 WRDS_MAX_DISPLAY_IOCTL_DATA = 256;
	public const uint32 WRDS_PERF_DISABLE_NOTHING = 0;
	public const uint32 WRDS_PERF_DISABLE_WALLPAPER = 1;
	public const uint32 WRDS_PERF_DISABLE_FULLWINDOWDRAG = 2;
	public const uint32 WRDS_PERF_DISABLE_MENUANIMATIONS = 4;
	public const uint32 WRDS_PERF_DISABLE_THEMING = 8;
	public const uint32 WRDS_PERF_ENABLE_ENHANCED_GRAPHICS = 16;
	public const uint32 WRDS_PERF_DISABLE_CURSOR_SHADOW = 32;
	public const uint32 WRDS_PERF_DISABLE_CURSORSETTINGS = 64;
	public const uint32 WRDS_PERF_ENABLE_FONT_SMOOTHING = 128;
	public const uint32 WRDS_PERF_ENABLE_DESKTOP_COMPOSITION = 256;
	public const uint32 WRDS_VALUE_TYPE_ULONG = 1;
	public const uint32 WRDS_VALUE_TYPE_STRING = 2;
	public const uint32 WRDS_VALUE_TYPE_BINARY = 3;
	public const uint32 WRDS_VALUE_TYPE_GUID = 4;
	public const uint32 WRDS_KEY_EXCHANGE_ALG_RSA = 1;
	public const uint32 WRDS_KEY_EXCHANGE_ALG_DH = 2;
	public const uint32 WRDS_LICENSE_PROTOCOL_VERSION = 65536;
	public const uint32 WRDS_LICENSE_PREAMBLE_VERSION = 3;
	public const uint32 SINGLE_SESSION = 1;
	public const uint32 FORCE_REJOIN = 2;
	public const uint32 FORCE_REJOIN_IN_CLUSTERMODE = 3;
	public const uint32 RESERVED_FOR_LEGACY = 4;
	public const uint32 KEEP_EXISTING_SESSIONS = 8;
	public const uint32 CHANNEL_EVENT_INITIALIZED = 0;
	public const uint32 CHANNEL_EVENT_CONNECTED = 1;
	public const uint32 CHANNEL_EVENT_V1_CONNECTED = 2;
	public const uint32 CHANNEL_EVENT_DISCONNECTED = 3;
	public const uint32 CHANNEL_EVENT_TERMINATED = 4;
	public const uint32 CHANNEL_EVENT_DATA_RECEIVED = 10;
	public const uint32 CHANNEL_EVENT_WRITE_COMPLETE = 11;
	public const uint32 CHANNEL_EVENT_WRITE_CANCELLED = 12;
	public const uint32 CHANNEL_RC_OK = 0;
	public const uint32 CHANNEL_RC_ALREADY_INITIALIZED = 1;
	public const uint32 CHANNEL_RC_NOT_INITIALIZED = 2;
	public const uint32 CHANNEL_RC_ALREADY_CONNECTED = 3;
	public const uint32 CHANNEL_RC_NOT_CONNECTED = 4;
	public const uint32 CHANNEL_RC_TOO_MANY_CHANNELS = 5;
	public const uint32 CHANNEL_RC_BAD_CHANNEL = 6;
	public const uint32 CHANNEL_RC_BAD_CHANNEL_HANDLE = 7;
	public const uint32 CHANNEL_RC_NO_BUFFER = 8;
	public const uint32 CHANNEL_RC_BAD_INIT_HANDLE = 9;
	public const uint32 CHANNEL_RC_NOT_OPEN = 10;
	public const uint32 CHANNEL_RC_BAD_PROC = 11;
	public const uint32 CHANNEL_RC_NO_MEMORY = 12;
	public const uint32 CHANNEL_RC_UNKNOWN_CHANNEL_NAME = 13;
	public const uint32 CHANNEL_RC_ALREADY_OPEN = 14;
	public const uint32 CHANNEL_RC_NOT_IN_VIRTUALCHANNELENTRY = 15;
	public const uint32 CHANNEL_RC_NULL_DATA = 16;
	public const uint32 CHANNEL_RC_ZERO_LENGTH = 17;
	public const uint32 CHANNEL_RC_INVALID_INSTANCE = 18;
	public const uint32 CHANNEL_RC_UNSUPPORTED_VERSION = 19;
	public const uint32 CHANNEL_RC_INITIALIZATION_ERROR = 20;
	public const uint32 VIRTUAL_CHANNEL_VERSION_WIN2000 = 1;
	public const uint32 CHANNEL_CHUNK_LENGTH = 1600;
	public const uint32 CHANNEL_BUFFER_SIZE = 65535;
	public const uint32 CHANNEL_FLAG_FIRST = 1;
	public const uint32 CHANNEL_FLAG_LAST = 2;
	public const uint32 CHANNEL_FLAG_MIDDLE = 0;
	public const uint32 CHANNEL_FLAG_FAIL = 256;
	public const uint32 CHANNEL_OPTION_INITIALIZED = 2147483648;
	public const uint32 CHANNEL_OPTION_ENCRYPT_RDP = 1073741824;
	public const uint32 CHANNEL_OPTION_ENCRYPT_SC = 536870912;
	public const uint32 CHANNEL_OPTION_ENCRYPT_CS = 268435456;
	public const uint32 CHANNEL_OPTION_PRI_HIGH = 134217728;
	public const uint32 CHANNEL_OPTION_PRI_MED = 67108864;
	public const uint32 CHANNEL_OPTION_PRI_LOW = 33554432;
	public const uint32 CHANNEL_OPTION_COMPRESS_RDP = 8388608;
	public const uint32 CHANNEL_OPTION_COMPRESS = 4194304;
	public const uint32 CHANNEL_OPTION_SHOW_PROTOCOL = 2097152;
	public const uint32 CHANNEL_OPTION_REMOTE_CONTROL_PERSISTENT = 1048576;
	public const uint32 CHANNEL_MAX_COUNT = 30;
	public const uint32 CHANNEL_NAME_LEN = 7;
	public const uint32 MAX_POLICY_ATTRIBUTES = 20;
	public const uint32 WTS_CURRENT_SESSION = 4294967295;
	public const uint32 USERNAME_LENGTH = 20;
	public const uint32 CLIENTNAME_LENGTH = 20;
	public const uint32 CLIENTADDRESS_LENGTH = 30;
	public const uint32 WTS_WSD_LOGOFF = 1;
	public const uint32 WTS_WSD_SHUTDOWN = 2;
	public const uint32 WTS_WSD_REBOOT = 4;
	public const uint32 WTS_WSD_POWEROFF = 8;
	public const uint32 WTS_WSD_FASTREBOOT = 16;
	public const uint32 MAX_ELAPSED_TIME_LENGTH = 15;
	public const uint32 MAX_DATE_TIME_LENGTH = 56;
	public const uint32 WINSTATIONNAME_LENGTH = 32;
	public const uint32 DOMAIN_LENGTH = 17;
	public const uint32 WTS_DRIVE_LENGTH = 3;
	public const uint32 WTS_LISTENER_NAME_LENGTH = 32;
	public const uint32 WTS_COMMENT_LENGTH = 60;
	public const uint32 WTS_LISTENER_CREATE = 1;
	public const uint32 WTS_LISTENER_UPDATE = 16;
	public const uint32 WTS_SECURITY_QUERY_INFORMATION = 1;
	public const uint32 WTS_SECURITY_SET_INFORMATION = 2;
	public const uint32 WTS_SECURITY_RESET = 4;
	public const uint32 WTS_SECURITY_VIRTUAL_CHANNELS = 8;
	public const uint32 WTS_SECURITY_REMOTE_CONTROL = 16;
	public const uint32 WTS_SECURITY_LOGON = 32;
	public const uint32 WTS_SECURITY_LOGOFF = 64;
	public const uint32 WTS_SECURITY_MESSAGE = 128;
	public const uint32 WTS_SECURITY_CONNECT = 256;
	public const uint32 WTS_SECURITY_DISCONNECT = 512;
	public const uint32 WTS_SECURITY_GUEST_ACCESS = 32;
	public const uint32 WTS_PROTOCOL_TYPE_CONSOLE = 0;
	public const uint32 WTS_PROTOCOL_TYPE_ICA = 1;
	public const uint32 WTS_PROTOCOL_TYPE_RDP = 2;
	public const uint32 WTS_SESSIONSTATE_UNKNOWN = 4294967295;
	public const uint32 WTS_SESSIONSTATE_LOCK = 0;
	public const uint32 WTS_SESSIONSTATE_UNLOCK = 1;
	public const uint32 PRODUCTINFO_COMPANYNAME_LENGTH = 256;
	public const uint32 PRODUCTINFO_PRODUCTID_LENGTH = 4;
	public const uint32 VALIDATIONINFORMATION_LICENSE_LENGTH = 16384;
	public const uint32 VALIDATIONINFORMATION_HARDWAREID_LENGTH = 20;
	public const uint32 WTS_EVENT_NONE = 0;
	public const uint32 WTS_EVENT_CREATE = 1;
	public const uint32 WTS_EVENT_DELETE = 2;
	public const uint32 WTS_EVENT_RENAME = 4;
	public const uint32 WTS_EVENT_CONNECT = 8;
	public const uint32 WTS_EVENT_DISCONNECT = 16;
	public const uint32 WTS_EVENT_LOGON = 32;
	public const uint32 WTS_EVENT_LOGOFF = 64;
	public const uint32 WTS_EVENT_STATECHANGE = 128;
	public const uint32 WTS_EVENT_LICENSE = 256;
	public const uint32 WTS_EVENT_ALL = 2147483647;
	public const uint32 WTS_EVENT_FLUSH = 2147483648;
	public const uint32 REMOTECONTROL_KBDSHIFT_HOTKEY = 1;
	public const uint32 REMOTECONTROL_KBDCTRL_HOTKEY = 2;
	public const uint32 REMOTECONTROL_KBDALT_HOTKEY = 4;
	public const uint32 WTS_CHANNEL_OPTION_DYNAMIC = 1;
	public const uint32 WTS_CHANNEL_OPTION_DYNAMIC_PRI_LOW = 0;
	public const uint32 WTS_CHANNEL_OPTION_DYNAMIC_PRI_MED = 2;
	public const uint32 WTS_CHANNEL_OPTION_DYNAMIC_PRI_HIGH = 4;
	public const uint32 WTS_CHANNEL_OPTION_DYNAMIC_PRI_REAL = 6;
	public const uint32 WTS_CHANNEL_OPTION_DYNAMIC_NO_COMPRESS = 8;
	public const uint32 NOTIFY_FOR_ALL_SESSIONS = 1;
	public const uint32 NOTIFY_FOR_THIS_SESSION = 0;
	public const uint32 WTS_PROCESS_INFO_LEVEL_0 = 0;
	public const uint32 WTS_PROCESS_INFO_LEVEL_1 = 1;
	public const uint32 PLUGIN_CAPABILITY_EXTERNAL_REDIRECTION = 1;
	public const uint32 MaxFQDN_Len = 256;
	public const uint32 MaxNetBiosName_Len = 16;
	public const uint32 MaxNumOfExposed_IPs = 12;
	public const uint32 MaxUserName_Len = 104;
	public const uint32 MaxDomainName_Len = 256;
	public const uint32 MaxFarm_Len = 256;
	public const uint32 MaxAppName_Len = 256;
	public const uint32 WKS_FLAG_CLEAR_CREDS_ON_LAST_RESOURCE = 1;
	public const uint32 WKS_FLAG_PASSWORD_ENCRYPTED = 2;
	public const uint32 WKS_FLAG_CREDS_AUTHENTICATED = 4;
	public const uint32 SB_SYNCH_CONFLICT_MAX_WRITE_ATTEMPTS = 100;
	public const uint32 ACQUIRE_TARGET_LOCK_TIMEOUT = 300000;
	public const uint32 RENDER_HINT_CLEAR = 0;
	public const uint32 RENDER_HINT_VIDEO = 1;
	public const uint32 RENDER_HINT_MAPPEDWINDOW = 2;
	public const String WTS_PROPERTY_DEFAULT_CONFIG = "DefaultConfig";
	public const uint32 TS_VC_LISTENER_STATIC_CHANNEL = 1;
	public const uint32 WRdsGraphicsChannels_LossyChannelMaxMessageSize = 988;
	public const uint32 RFX_RDP_MSG_PREFIX = 0;
	public const uint32 RFX_GFX_MSG_PREFIX = 48;
	public const uint32 RFX_GFX_MSG_PREFIX_MASK = 48;
	public const uint32 RFX_GFX_MAX_SUPPORTED_MONITORS = 16;
	public const uint32 RFX_CLIENT_ID_LENGTH = 32;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_CONNECT = 701;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_DISCONNECT = 702;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_RECONNECT = 703;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_DELETE_SAVED_CREDENTIALS = 704;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_UPDATE_SESSION_DISPLAYSETTINGS = 705;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_ATTACH_EVENT = 706;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_DETACH_EVENT = 707;
	public const uint32 DISPID_PROP_REMOTEDESKTOPCLIENT_SETTINGS = 710;
	public const uint32 DISPID_PROP_REMOTEDESKTOPCLIENT_ACTIONS = 711;
	public const uint32 DISPID_PROP_REMOTEDESKTOPCLIENT_TOUCH_POINTER = 712;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_SET_RDPPROPERTY = 720;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_GET_RDPPROPERTY = 721;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_APPLY_SETTINGS = 722;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_RETRIEVE_SETTINGS = 723;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_SUSPEND_SCREEN_UPDATES = 730;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_RESUME_SCREEN_UPDATES = 731;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_EXECUTE_REMOTE_ACTION = 732;
	public const uint32 DISPID_METHOD_REMOTEDESKTOPCLIENT_GET_SNAPSHOT = 733;
	public const uint32 DISPID_PROP_REMOTEDESKTOPCLIENT_TOUCHPOINTER_ENABLED = 740;
	public const uint32 DISPID_PROP_REMOTEDESKTOPCLIENT_TOUCHPOINTER_EVENTSENABLED = 741;
	public const uint32 DISPID_PROP_REMOTEDESKTOPCLIENT_TOUCHPOINTER_POINTERSPEED = 742;
	public const uint32 DISPID_AX_CONNECTING = 750;
	public const uint32 DISPID_AX_CONNECTED = 751;
	public const uint32 DISPID_AX_LOGINCOMPLETED = 752;
	public const uint32 DISPID_AX_DISCONNECTED = 753;
	public const uint32 DISPID_AX_STATUSCHANGED = 754;
	public const uint32 DISPID_AX_AUTORECONNECTING = 755;
	public const uint32 DISPID_AX_AUTORECONNECTED = 756;
	public const uint32 DISPID_AX_DIALOGDISPLAYING = 757;
	public const uint32 DISPID_AX_DIALOGDISMISSED = 758;
	public const uint32 DISPID_AX_NETWORKSTATUSCHANGED = 759;
	public const uint32 DISPID_AX_ADMINMESSAGERECEIVED = 760;
	public const uint32 DISPID_AX_KEYCOMBINATIONPRESSED = 761;
	public const uint32 DISPID_AX_REMOTEDESKTOPSIZECHANGED = 762;
	public const uint32 DISPID_AX_TOUCHPOINTERCURSORMOVED = 800;
	public const Guid RDCLIENT_BITMAP_RENDER_SERVICE = .(0xe4cc08cb, 0x942e, 0x4b19, 0x85, 0x04, 0xbd, 0x5a, 0x89, 0xa7, 0x47, 0xf5);
	public const Guid WTS_QUERY_ALLOWED_INITIAL_APP = .(0xc77d1b30, 0x5be1, 0x4c6b, 0xa0, 0xe1, 0xbd, 0x6d, 0x2e, 0x5c, 0x9f, 0xcc);
	public const Guid WTS_QUERY_LOGON_SCREEN_SIZE = .(0x8b8e0fe7, 0x0804, 0x4a0e, 0xb2, 0x79, 0x86, 0x60, 0xb1, 0xdf, 0x00, 0x49);
	public const Guid WTS_QUERY_AUDIOENUM_DLL = .(0x9bf4fa97, 0xc883, 0x4c2a, 0x80, 0xab, 0x5a, 0x39, 0xc9, 0xaf, 0x00, 0xdb);
	public const Guid WTS_QUERY_MF_FORMAT_SUPPORT = .(0x41869ad0, 0x6332, 0x4dc8, 0x95, 0xd5, 0xdb, 0x74, 0x9e, 0x2f, 0x1d, 0x94);
	public const Guid WRDS_SERVICE_ID_GRAPHICS_GUID = .(0xd2993f4d, 0x02cf, 0x4280, 0x8c, 0x48, 0x16, 0x24, 0xb4, 0x4f, 0x87, 0x06);
	public const Guid PROPERTY_DYNAMIC_TIME_ZONE_INFORMATION = .(0x0cdfd28e, 0xd0b9, 0x4c1f, 0xa5, 0xeb, 0x6d, 0x1f, 0x6c, 0x65, 0x35, 0xb9);
	public const Guid PROPERTY_TYPE_GET_FAST_RECONNECT = .(0x6212d757, 0x0043, 0x4862, 0x99, 0xc3, 0x9f, 0x30, 0x59, 0xac, 0x2a, 0x3b);
	public const Guid PROPERTY_TYPE_GET_FAST_RECONNECT_USER_SID = .(0x197c427a, 0x0135, 0x4b6d, 0x9c, 0x5e, 0xe6, 0x57, 0x9a, 0x0a, 0xb6, 0x25);
	public const Guid PROPERTY_TYPE_ENABLE_UNIVERSAL_APPS_FOR_CUSTOM_SHELL = .(0xed2c3fda, 0x338d, 0x4d3f, 0x81, 0xa3, 0xe7, 0x67, 0x31, 0x0d, 0x90, 0x8e);
	public const Guid CONNECTION_PROPERTY_IDLE_TIME_WARNING = .(0x693f7ff5, 0x0c4e, 0x4d17, 0xb8, 0xe0, 0x1f, 0x70, 0x32, 0x5e, 0x5d, 0x58);
	public const Guid CONNECTION_PROPERTY_CURSOR_BLINK_DISABLED = .(0x4b150580, 0xfea4, 0x4d3c, 0x9d, 0xe4, 0x74, 0x33, 0xa6, 0x66, 0x18, 0xf7);
}
#endregion

#region TypeDefs
typealias HwtsVirtualChannelHandle = int;

#endregion


#region Enums

[AllowDuplicates]
public enum AE_POSITION_FLAGS : int32
{
	POSITION_INVALID = 0,
	POSITION_DISCONTINUOUS = 1,
	POSITION_CONTINUOUS = 2,
	POSITION_QPC_ERROR = 4,
}


[AllowDuplicates]
public enum AAAuthSchemes : int32
{
	AA_AUTH_MIN = 0,
	AA_AUTH_BASIC = 1,
	AA_AUTH_NTLM = 2,
	AA_AUTH_SC = 3,
	AA_AUTH_LOGGEDONCREDENTIALS = 4,
	AA_AUTH_NEGOTIATE = 5,
	AA_AUTH_ANY = 6,
	AA_AUTH_COOKIE = 7,
	AA_AUTH_DIGEST = 8,
	AA_AUTH_ORGID = 9,
	AA_AUTH_CONID = 10,
	AA_AUTH_SSPI_NTLM = 11,
	AA_AUTH_MAX = 12,
}


[AllowDuplicates]
public enum AAAccountingDataType : int32
{
	AA_MAIN_SESSION_CREATION = 0,
	AA_SUB_SESSION_CREATION = 1,
	AA_SUB_SESSION_CLOSED = 2,
	AA_MAIN_SESSION_CLOSED = 3,
}


[AllowDuplicates]
public enum SESSION_TIMEOUT_ACTION_TYPE : int32
{
	SESSION_TIMEOUT_ACTION_DISCONNECT = 0,
	SESSION_TIMEOUT_ACTION_SILENT_REAUTH = 1,
}


[AllowDuplicates]
public enum PolicyAttributeType : int32
{
	EnableAllRedirections = 0,
	DisableAllRedirections = 1,
	DriveRedirectionDisabled = 2,
	PrinterRedirectionDisabled = 3,
	PortRedirectionDisabled = 4,
	ClipboardRedirectionDisabled = 5,
	PnpRedirectionDisabled = 6,
	AllowOnlySDRServers = 7,
}


[AllowDuplicates]
public enum AATrustClassID : int32
{
	AA_UNTRUSTED = 0,
	AA_TRUSTEDUSER_UNTRUSTEDCLIENT = 1,
	AA_TRUSTEDUSER_TRUSTEDCLIENT = 2,
}


[AllowDuplicates]
public enum WTS_CONNECTSTATE_CLASS : int32
{
	WTSActive = 0,
	WTSConnected = 1,
	WTSConnectQuery = 2,
	WTSShadow = 3,
	WTSDisconnected = 4,
	WTSIdle = 5,
	WTSListen = 6,
	WTSReset = 7,
	WTSDown = 8,
	WTSInit = 9,
}


[AllowDuplicates]
public enum WTS_INFO_CLASS : int32
{
	WTSInitialProgram = 0,
	WTSApplicationName = 1,
	WTSWorkingDirectory = 2,
	WTSOEMId = 3,
	WTSSessionId = 4,
	WTSUserName = 5,
	WTSWinStationName = 6,
	WTSDomainName = 7,
	WTSConnectState = 8,
	WTSClientBuildNumber = 9,
	WTSClientName = 10,
	WTSClientDirectory = 11,
	WTSClientProductId = 12,
	WTSClientHardwareId = 13,
	WTSClientAddress = 14,
	WTSClientDisplay = 15,
	WTSClientProtocolType = 16,
	WTSIdleTime = 17,
	WTSLogonTime = 18,
	WTSIncomingBytes = 19,
	WTSOutgoingBytes = 20,
	WTSIncomingFrames = 21,
	WTSOutgoingFrames = 22,
	WTSClientInfo = 23,
	WTSSessionInfo = 24,
	WTSSessionInfoEx = 25,
	WTSConfigInfo = 26,
	WTSValidationInfo = 27,
	WTSSessionAddressV4 = 28,
	WTSIsRemoteSession = 29,
}


[AllowDuplicates]
public enum WTS_CONFIG_CLASS : int32
{
	WTSUserConfigInitialProgram = 0,
	WTSUserConfigWorkingDirectory = 1,
	WTSUserConfigfInheritInitialProgram = 2,
	WTSUserConfigfAllowLogonTerminalServer = 3,
	WTSUserConfigTimeoutSettingsConnections = 4,
	WTSUserConfigTimeoutSettingsDisconnections = 5,
	WTSUserConfigTimeoutSettingsIdle = 6,
	WTSUserConfigfDeviceClientDrives = 7,
	WTSUserConfigfDeviceClientPrinters = 8,
	WTSUserConfigfDeviceClientDefaultPrinter = 9,
	WTSUserConfigBrokenTimeoutSettings = 10,
	WTSUserConfigReconnectSettings = 11,
	WTSUserConfigModemCallbackSettings = 12,
	WTSUserConfigModemCallbackPhoneNumber = 13,
	WTSUserConfigShadowingSettings = 14,
	WTSUserConfigTerminalServerProfilePath = 15,
	WTSUserConfigTerminalServerHomeDir = 16,
	WTSUserConfigTerminalServerHomeDirDrive = 17,
	WTSUserConfigfTerminalServerRemoteHomeDir = 18,
	WTSUserConfigUser = 19,
}


[AllowDuplicates]
public enum WTS_CONFIG_SOURCE : int32
{
	WTSUserConfigSourceSAM = 0,
}


[AllowDuplicates]
public enum WTS_VIRTUAL_CLASS : int32
{
	WTSVirtualClientData = 0,
	WTSVirtualFileHandle = 1,
}


[AllowDuplicates]
public enum WTS_TYPE_CLASS : int32
{
	WTSTypeProcessInfoLevel0 = 0,
	WTSTypeProcessInfoLevel1 = 1,
	WTSTypeSessionInfoLevel1 = 2,
}


[AllowDuplicates]
public enum WTSSBX_MACHINE_DRAIN : int32
{
	WTSSBX_MACHINE_DRAIN_UNSPEC = 0,
	WTSSBX_MACHINE_DRAIN_OFF = 1,
	WTSSBX_MACHINE_DRAIN_ON = 2,
}


[AllowDuplicates]
public enum WTSSBX_MACHINE_SESSION_MODE : int32
{
	WTSSBX_MACHINE_SESSION_MODE_UNSPEC = 0,
	WTSSBX_MACHINE_SESSION_MODE_SINGLE = 1,
	WTSSBX_MACHINE_SESSION_MODE_MULTIPLE = 2,
}


[AllowDuplicates]
public enum WTSSBX_ADDRESS_FAMILY : int32
{
	WTSSBX_ADDRESS_FAMILY_AF_UNSPEC = 0,
	WTSSBX_ADDRESS_FAMILY_AF_INET = 1,
	WTSSBX_ADDRESS_FAMILY_AF_INET6 = 2,
	WTSSBX_ADDRESS_FAMILY_AF_IPX = 3,
	WTSSBX_ADDRESS_FAMILY_AF_NETBIOS = 4,
}


[AllowDuplicates]
public enum WTSSBX_MACHINE_STATE : int32
{
	WTSSBX_MACHINE_STATE_UNSPEC = 0,
	WTSSBX_MACHINE_STATE_READY = 1,
	WTSSBX_MACHINE_STATE_SYNCHRONIZING = 2,
}


[AllowDuplicates]
public enum WTSSBX_SESSION_STATE : int32
{
	WTSSBX_SESSION_STATE_UNSPEC = 0,
	WTSSBX_SESSION_STATE_ACTIVE = 1,
	WTSSBX_SESSION_STATE_DISCONNECTED = 2,
}


[AllowDuplicates]
public enum WTSSBX_NOTIFICATION_TYPE : int32
{
	WTSSBX_NOTIFICATION_REMOVED = 1,
	WTSSBX_NOTIFICATION_CHANGED = 2,
	WTSSBX_NOTIFICATION_ADDED = 4,
	WTSSBX_NOTIFICATION_RESYNC = 8,
}


[AllowDuplicates]
public enum TSSD_AddrV46Type : int32
{
	TSSD_ADDR_UNDEFINED = 0,
	TSSD_ADDR_IPv4 = 4,
	TSSD_ADDR_IPv6 = 6,
}


[AllowDuplicates]
public enum TSSB_NOTIFICATION_TYPE : int32
{
	TSSB_NOTIFY_INVALID = 0,
	TSSB_NOTIFY_TARGET_CHANGE = 1,
	TSSB_NOTIFY_SESSION_CHANGE = 2,
	TSSB_NOTIFY_CONNECTION_REQUEST_CHANGE = 4,
}


[AllowDuplicates]
public enum TARGET_STATE : int32
{
	TARGET_UNKNOWN = 1,
	TARGET_INITIALIZING = 2,
	TARGET_RUNNING = 3,
	TARGET_DOWN = 4,
	TARGET_HIBERNATED = 5,
	TARGET_CHECKED_OUT = 6,
	TARGET_STOPPED = 7,
	TARGET_INVALID = 8,
	TARGET_STARTING = 9,
	TARGET_STOPPING = 10,
	TARGET_MAXSTATE = 11,
}


[AllowDuplicates]
public enum TARGET_CHANGE_TYPE : int32
{
	TARGET_CHANGE_UNSPEC = 1,
	TARGET_EXTERNALIP_CHANGED = 2,
	TARGET_INTERNALIP_CHANGED = 4,
	TARGET_JOINED = 8,
	TARGET_REMOVED = 16,
	TARGET_STATE_CHANGED = 32,
	TARGET_IDLE = 64,
	TARGET_PENDING = 128,
	TARGET_INUSE = 256,
	TARGET_PATCH_STATE_CHANGED = 512,
	TARGET_FARM_MEMBERSHIP_CHANGED = 1024,
}


[AllowDuplicates]
public enum TARGET_TYPE : int32
{
	UNKNOWN = 0,
	FARM = 1,
	NONFARM = 2,
}


[AllowDuplicates]
public enum TARGET_PATCH_STATE : int32
{
	TARGET_PATCH_UNKNOWN = 0,
	TARGET_PATCH_NOT_STARTED = 1,
	TARGET_PATCH_IN_PROGRESS = 2,
	TARGET_PATCH_COMPLETED = 3,
	TARGET_PATCH_FAILED = 4,
}


[AllowDuplicates]
public enum CLIENT_MESSAGE_TYPE : int32
{
	CLIENT_MESSAGE_CONNECTION_INVALID = 0,
	CLIENT_MESSAGE_CONNECTION_STATUS = 1,
	CLIENT_MESSAGE_CONNECTION_ERROR = 2,
}


[AllowDuplicates]
public enum CONNECTION_CHANGE_NOTIFICATION : int32
{
	CONNECTION_REQUEST_INVALID = 0,
	CONNECTION_REQUEST_PENDING = 1,
	CONNECTION_REQUEST_FAILED = 2,
	CONNECTION_REQUEST_TIMEDOUT = 3,
	CONNECTION_REQUEST_SUCCEEDED = 4,
	CONNECTION_REQUEST_CANCELLED = 5,
	CONNECTION_REQUEST_LB_COMPLETED = 6,
	CONNECTION_REQUEST_QUERY_PL_COMPLETED = 7,
	CONNECTION_REQUEST_ORCH_COMPLETED = 8,
}


[AllowDuplicates]
public enum RD_FARM_TYPE : int32
{
	RD_FARM_RDSH = 0,
	RD_FARM_TEMP_VM = 1,
	RD_FARM_MANUAL_PERSONAL_VM = 2,
	RD_FARM_AUTO_PERSONAL_VM = 3,
	RD_FARM_MANUAL_PERSONAL_RDSH = 4,
	RD_FARM_AUTO_PERSONAL_RDSH = 5,
	RD_FARM_TYPE_UNKNOWN = -1,
}


[AllowDuplicates]
public enum PLUGIN_TYPE : int32
{
	UNKNOWN_PLUGIN = 0,
	POLICY_PLUGIN = 1,
	RESOURCE_PLUGIN = 2,
	LOAD_BALANCING_PLUGIN = 4,
	PLACEMENT_PLUGIN = 8,
	ORCHESTRATION_PLUGIN = 16,
	PROVISIONING_PLUGIN = 32,
	TASK_PLUGIN = 64,
}


[AllowDuplicates]
public enum TSSESSION_STATE : int32
{
	STATE_INVALID = -1,
	STATE_ACTIVE = 0,
	STATE_CONNECTED = 1,
	STATE_CONNECTQUERY = 2,
	STATE_SHADOW = 3,
	STATE_DISCONNECTED = 4,
	STATE_IDLE = 5,
	STATE_LISTEN = 6,
	STATE_RESET = 7,
	STATE_DOWN = 8,
	STATE_INIT = 9,
	STATE_MAX = 10,
}


[AllowDuplicates]
public enum TARGET_OWNER : int32
{
	OWNER_UNKNOWN = 0,
	OWNER_MS_TS_PLUGIN = 1,
	OWNER_MS_VM_PLUGIN = 2,
}


[AllowDuplicates]
public enum VM_NOTIFY_STATUS : int32
{
	VM_NOTIFY_STATUS_PENDING = 0,
	VM_NOTIFY_STATUS_IN_PROGRESS = 1,
	VM_NOTIFY_STATUS_COMPLETE = 2,
	VM_NOTIFY_STATUS_FAILED = 3,
	VM_NOTIFY_STATUS_CANCELED = 4,
}


[AllowDuplicates]
public enum VM_HOST_NOTIFY_STATUS : int32
{
	VM_HOST_STATUS_INIT_PENDING = 0,
	VM_HOST_STATUS_INIT_IN_PROGRESS = 1,
	VM_HOST_STATUS_INIT_COMPLETE = 2,
	VM_HOST_STATUS_INIT_FAILED = 3,
}


[AllowDuplicates]
public enum RDV_TASK_STATUS : int32
{
	RDV_TASK_STATUS_UNKNOWN = 0,
	RDV_TASK_STATUS_SEARCHING = 1,
	RDV_TASK_STATUS_DOWNLOADING = 2,
	RDV_TASK_STATUS_APPLYING = 3,
	RDV_TASK_STATUS_REBOOTING = 4,
	RDV_TASK_STATUS_REBOOTED = 5,
	RDV_TASK_STATUS_SUCCESS = 6,
	RDV_TASK_STATUS_FAILED = 7,
	RDV_TASK_STATUS_TIMEOUT = 8,
}


[AllowDuplicates]
public enum TS_SB_SORT_BY : int32
{
	TS_SB_SORT_BY_NONE = 0,
	TS_SB_SORT_BY_NAME = 1,
	TS_SB_SORT_BY_PROP = 2,
}


[AllowDuplicates]
public enum TSPUB_PLUGIN_PD_RESOLUTION_TYPE : int32
{
	TSPUB_PLUGIN_PD_QUERY_OR_CREATE = 0,
	TSPUB_PLUGIN_PD_QUERY_EXISTING = 1,
}


[AllowDuplicates]
public enum TSPUB_PLUGIN_PD_ASSIGNMENT_TYPE : int32
{
	TSPUB_PLUGIN_PD_ASSIGNMENT_NEW = 0,
	TSPUB_PLUGIN_PD_ASSIGNMENT_EXISTING = 1,
}


[AllowDuplicates]
public enum WRdsGraphicsChannelType : int32
{
	WRdsGraphicsChannelType_GuaranteedDelivery = 0,
	WRdsGraphicsChannelType_BestEffortDelivery = 1,
}


[AllowDuplicates]
public enum WTS_RCM_SERVICE_STATE : int32
{
	WTS_SERVICE_NONE = 0,
	WTS_SERVICE_START = 1,
	WTS_SERVICE_STOP = 2,
}


[AllowDuplicates]
public enum WTS_RCM_DRAIN_STATE : int32
{
	WTS_DRAIN_STATE_NONE = 0,
	WTS_DRAIN_IN_DRAIN = 1,
	WTS_DRAIN_NOT_IN_DRAIN = 2,
}


[AllowDuplicates]
public enum WTS_LOGON_ERROR_REDIRECTOR_RESPONSE : int32
{
	WTS_LOGON_ERR_INVALID = 0,
	WTS_LOGON_ERR_NOT_HANDLED = 1,
	WTS_LOGON_ERR_HANDLED_SHOW = 2,
	WTS_LOGON_ERR_HANDLED_DONT_SHOW = 3,
	WTS_LOGON_ERR_HANDLED_DONT_SHOW_START_OVER = 4,
}


[AllowDuplicates]
public enum WTS_CERT_TYPE : int32
{
	WTS_CERT_TYPE_INVALID = 0,
	WTS_CERT_TYPE_PROPRIETORY = 1,
	WTS_CERT_TYPE_X509 = 2,
}


[AllowDuplicates]
public enum WRDS_CONNECTION_SETTING_LEVEL : int32
{
	WRDS_CONNECTION_SETTING_LEVEL_INVALID = 0,
	WRDS_CONNECTION_SETTING_LEVEL_1 = 1,
}


[AllowDuplicates]
public enum WRDS_LISTENER_SETTING_LEVEL : int32
{
	WRDS_LISTENER_SETTING_LEVEL_INVALID = 0,
	WRDS_LISTENER_SETTING_LEVEL_1 = 1,
}


[AllowDuplicates]
public enum WRDS_SETTING_TYPE : int32
{
	WRDS_SETTING_TYPE_INVALID = 0,
	WRDS_SETTING_TYPE_MACHINE = 1,
	WRDS_SETTING_TYPE_USER = 2,
	WRDS_SETTING_TYPE_SAM = 3,
}


[AllowDuplicates]
public enum WRDS_SETTING_STATUS : int32
{
	WRDS_SETTING_STATUS_NOTAPPLICABLE = -1,
	WRDS_SETTING_STATUS_DISABLED = 0,
	WRDS_SETTING_STATUS_ENABLED = 1,
	WRDS_SETTING_STATUS_NOTCONFIGURED = 2,
}


[AllowDuplicates]
public enum WRDS_SETTING_LEVEL : int32
{
	WRDS_SETTING_LEVEL_INVALID = 0,
	WRDS_SETTING_LEVEL_1 = 1,
}


[AllowDuplicates]
public enum PasswordEncodingType : int32
{
	PasswordEncodingUTF8 = 0,
	PasswordEncodingUTF16LE = 1,
	PasswordEncodingUTF16BE = 2,
}


[AllowDuplicates]
public enum RemoteActionType : int32
{
	RemoteActionCharms = 0,
	RemoteActionAppbar = 1,
	RemoteActionSnap = 2,
	RemoteActionStartScreen = 3,
	RemoteActionAppSwitch = 4,
}


[AllowDuplicates]
public enum SnapshotEncodingType : int32
{
	SnapshotEncodingDataUri = 0,
}


[AllowDuplicates]
public enum SnapshotFormatType : int32
{
	SnapshotFormatPng = 0,
	SnapshotFormatJpeg = 1,
	SnapshotFormatBmp = 2,
}


[AllowDuplicates]
public enum KeyCombinationType : int32
{
	KeyCombinationHome = 0,
	KeyCombinationLeft = 1,
	KeyCombinationUp = 2,
	KeyCombinationRight = 3,
	KeyCombinationDown = 4,
	KeyCombinationScroll = 5,
}

#endregion

#region Function Pointers
public function void PCHANNEL_INIT_EVENT_FN(void* pInitHandle, uint32 event, void* pData, uint32 dataLength);

public function void PCHANNEL_OPEN_EVENT_FN(uint32 openHandle, uint32 event, void* pData, uint32 dataLength, uint32 totalLength, uint32 dataFlags);

public function uint32 PVIRTUALCHANNELINIT(void** ppInitHandle, CHANNEL_DEF* pChannel, int32 channelCount, uint32 versionRequested, PCHANNEL_INIT_EVENT_FN pChannelInitEventProc);

public function uint32 PVIRTUALCHANNELOPEN(void* pInitHandle, uint32* pOpenHandle, PSTR pChannelName, PCHANNEL_OPEN_EVENT_FN pChannelOpenEventProc);

public function uint32 PVIRTUALCHANNELCLOSE(uint32 openHandle);

public function uint32 PVIRTUALCHANNELWRITE(uint32 openHandle, void* pData, uint32 dataLength, void* pUserData);

public function BOOL PVIRTUALCHANNELENTRY(CHANNEL_ENTRY_POINTS* pEntryPoints);

#endregion

#region Structs
[CRepr]
public struct AE_CURRENT_POSITION
{
	public uint64 u64DevicePosition;
	public uint64 u64StreamPosition;
	public uint64 u64PaddingFrames;
	public int64 hnsQPCPosition;
	public float f32FramesPerSecond;
	public AE_POSITION_FLAGS Flag;
}

[CRepr]
public struct AAAccountingData
{
	public BSTR userName;
	public BSTR clientName;
	public AAAuthSchemes authType;
	public BSTR resourceName;
	public int32 portNumber;
	public BSTR protocolName;
	public int32 numberOfBytesReceived;
	public int32 numberOfBytesTransfered;
	public BSTR reasonForDisconnect;
	public Guid mainSessionId;
	public int32 subSessionId;
}

[CRepr]
public struct WTS_SERVER_INFOW
{
	public PWSTR pServerName;
}

[CRepr]
public struct WTS_SERVER_INFOA
{
	public PSTR pServerName;
}

[CRepr]
public struct WTS_SESSION_INFOW
{
	public uint32 SessionId;
	public PWSTR pWinStationName;
	public WTS_CONNECTSTATE_CLASS State;
}

[CRepr]
public struct WTS_SESSION_INFOA
{
	public uint32 SessionId;
	public PSTR pWinStationName;
	public WTS_CONNECTSTATE_CLASS State;
}

[CRepr]
public struct WTS_SESSION_INFO_1W
{
	public uint32 ExecEnvId;
	public WTS_CONNECTSTATE_CLASS State;
	public uint32 SessionId;
	public PWSTR pSessionName;
	public PWSTR pHostName;
	public PWSTR pUserName;
	public PWSTR pDomainName;
	public PWSTR pFarmName;
}

[CRepr]
public struct WTS_SESSION_INFO_1A
{
	public uint32 ExecEnvId;
	public WTS_CONNECTSTATE_CLASS State;
	public uint32 SessionId;
	public PSTR pSessionName;
	public PSTR pHostName;
	public PSTR pUserName;
	public PSTR pDomainName;
	public PSTR pFarmName;
}

[CRepr]
public struct WTS_PROCESS_INFOW
{
	public uint32 SessionId;
	public uint32 ProcessId;
	public PWSTR pProcessName;
	public PSID pUserSid;
}

[CRepr]
public struct WTS_PROCESS_INFOA
{
	public uint32 SessionId;
	public uint32 ProcessId;
	public PSTR pProcessName;
	public PSID pUserSid;
}

[CRepr]
public struct WTSCONFIGINFOW
{
	public uint32 version;
	public uint32 fConnectClientDrivesAtLogon;
	public uint32 fConnectPrinterAtLogon;
	public uint32 fDisablePrinterRedirection;
	public uint32 fDisableDefaultMainClientPrinter;
	public uint32 ShadowSettings;
	public char16[21] LogonUserName;
	public char16[18] LogonDomain;
	public char16[261] WorkDirectory;
	public char16[261] InitialProgram;
	public char16[261] ApplicationName;
}

[CRepr]
public struct WTSCONFIGINFOA
{
	public uint32 version;
	public uint32 fConnectClientDrivesAtLogon;
	public uint32 fConnectPrinterAtLogon;
	public uint32 fDisablePrinterRedirection;
	public uint32 fDisableDefaultMainClientPrinter;
	public uint32 ShadowSettings;
	public CHAR[21] LogonUserName;
	public CHAR[18] LogonDomain;
	public CHAR[261] WorkDirectory;
	public CHAR[261] InitialProgram;
	public CHAR[261] ApplicationName;
}

[CRepr]
public struct WTSINFOW
{
	public WTS_CONNECTSTATE_CLASS State;
	public uint32 SessionId;
	public uint32 IncomingBytes;
	public uint32 OutgoingBytes;
	public uint32 IncomingFrames;
	public uint32 OutgoingFrames;
	public uint32 IncomingCompressedBytes;
	public uint32 OutgoingCompressedBytes;
	public char16[32] WinStationName;
	public char16[17] Domain;
	public char16[21] UserName;
	public LARGE_INTEGER ConnectTime;
	public LARGE_INTEGER DisconnectTime;
	public LARGE_INTEGER LastInputTime;
	public LARGE_INTEGER LogonTime;
	public LARGE_INTEGER CurrentTime;
}

[CRepr]
public struct WTSINFOA
{
	public WTS_CONNECTSTATE_CLASS State;
	public uint32 SessionId;
	public uint32 IncomingBytes;
	public uint32 OutgoingBytes;
	public uint32 IncomingFrames;
	public uint32 OutgoingFrames;
	public uint32 IncomingCompressedBytes;
	public uint32 OutgoingCompressedBy;
	public CHAR[32] WinStationName;
	public CHAR[17] Domain;
	public CHAR[21] UserName;
	public LARGE_INTEGER ConnectTime;
	public LARGE_INTEGER DisconnectTime;
	public LARGE_INTEGER LastInputTime;
	public LARGE_INTEGER LogonTime;
	public LARGE_INTEGER CurrentTime;
}

[CRepr]
public struct WTSINFOEX_LEVEL1_W
{
	public uint32 SessionId;
	public WTS_CONNECTSTATE_CLASS SessionState;
	public int32 SessionFlags;
	public char16[33] WinStationName;
	public char16[21] UserName;
	public char16[18] DomainName;
	public LARGE_INTEGER LogonTime;
	public LARGE_INTEGER ConnectTime;
	public LARGE_INTEGER DisconnectTime;
	public LARGE_INTEGER LastInputTime;
	public LARGE_INTEGER CurrentTime;
	public uint32 IncomingBytes;
	public uint32 OutgoingBytes;
	public uint32 IncomingFrames;
	public uint32 OutgoingFrames;
	public uint32 IncomingCompressedBytes;
	public uint32 OutgoingCompressedBytes;
}

[CRepr]
public struct WTSINFOEX_LEVEL1_A
{
	public uint32 SessionId;
	public WTS_CONNECTSTATE_CLASS SessionState;
	public int32 SessionFlags;
	public CHAR[33] WinStationName;
	public CHAR[21] UserName;
	public CHAR[18] DomainName;
	public LARGE_INTEGER LogonTime;
	public LARGE_INTEGER ConnectTime;
	public LARGE_INTEGER DisconnectTime;
	public LARGE_INTEGER LastInputTime;
	public LARGE_INTEGER CurrentTime;
	public uint32 IncomingBytes;
	public uint32 OutgoingBytes;
	public uint32 IncomingFrames;
	public uint32 OutgoingFrames;
	public uint32 IncomingCompressedBytes;
	public uint32 OutgoingCompressedBytes;
}

[CRepr, Union]
public struct WTSINFOEX_LEVEL_W
{
	public WTSINFOEX_LEVEL1_W WTSInfoExLevel1;
}

[CRepr, Union]
public struct WTSINFOEX_LEVEL_A
{
	public WTSINFOEX_LEVEL1_A WTSInfoExLevel1;
}

[CRepr]
public struct WTSINFOEXW
{
	public uint32 Level;
	public WTSINFOEX_LEVEL_W Data;
}

[CRepr]
public struct WTSINFOEXA
{
	public uint32 Level;
	public WTSINFOEX_LEVEL_A Data;
}

[CRepr]
public struct WTSCLIENTW
{
	public char16[21] ClientName;
	public char16[18] Domain;
	public char16[21] UserName;
	public char16[261] WorkDirectory;
	public char16[261] InitialProgram;
	public uint8 EncryptionLevel;
	public uint32 ClientAddressFamily;
	public uint16[31] ClientAddress;
	public uint16 HRes;
	public uint16 VRes;
	public uint16 ColorDepth;
	public char16[261] ClientDirectory;
	public uint32 ClientBuildNumber;
	public uint32 ClientHardwareId;
	public uint16 ClientProductId;
	public uint16 OutBufCountHost;
	public uint16 OutBufCountClient;
	public uint16 OutBufLength;
	public char16[261] DeviceId;
}

[CRepr]
public struct WTSCLIENTA
{
	public CHAR[21] ClientName;
	public CHAR[18] Domain;
	public CHAR[21] UserName;
	public CHAR[261] WorkDirectory;
	public CHAR[261] InitialProgram;
	public uint8 EncryptionLevel;
	public uint32 ClientAddressFamily;
	public uint16[31] ClientAddress;
	public uint16 HRes;
	public uint16 VRes;
	public uint16 ColorDepth;
	public CHAR[261] ClientDirectory;
	public uint32 ClientBuildNumber;
	public uint32 ClientHardwareId;
	public uint16 ClientProductId;
	public uint16 OutBufCountHost;
	public uint16 OutBufCountClient;
	public uint16 OutBufLength;
	public CHAR[261] DeviceId;
}

[CRepr]
public struct PRODUCT_INFOA
{
	public CHAR[256] CompanyName;
	public CHAR[4] ProductID;
}

[CRepr]
public struct PRODUCT_INFOW
{
	public char16[256] CompanyName;
	public char16[4] ProductID;
}

[CRepr]
public struct WTS_VALIDATION_INFORMATIONA
{
	public PRODUCT_INFOA ProductInfo;
	public uint8[16384] License;
	public uint32 LicenseLength;
	public uint8[20] HardwareID;
	public uint32 HardwareIDLength;
}

[CRepr]
public struct WTS_VALIDATION_INFORMATIONW
{
	public PRODUCT_INFOW ProductInfo;
	public uint8[16384] License;
	public uint32 LicenseLength;
	public uint8[20] HardwareID;
	public uint32 HardwareIDLength;
}

[CRepr]
public struct WTS_CLIENT_ADDRESS
{
	public uint32 AddressFamily;
	public uint8[20] Address;
}

[CRepr]
public struct WTS_CLIENT_DISPLAY
{
	public uint32 HorizontalResolution;
	public uint32 VerticalResolution;
	public uint32 ColorDepth;
}

[CRepr]
public struct WTSUSERCONFIGA
{
	public uint32 Source;
	public uint32 InheritInitialProgram;
	public uint32 AllowLogonTerminalServer;
	public uint32 TimeoutSettingsConnections;
	public uint32 TimeoutSettingsDisconnections;
	public uint32 TimeoutSettingsIdle;
	public uint32 DeviceClientDrives;
	public uint32 DeviceClientPrinters;
	public uint32 ClientDefaultPrinter;
	public uint32 BrokenTimeoutSettings;
	public uint32 ReconnectSettings;
	public uint32 ShadowingSettings;
	public uint32 TerminalServerRemoteHomeDir;
	public CHAR[261] InitialProgram;
	public CHAR[261] WorkDirectory;
	public CHAR[261] TerminalServerProfilePath;
	public CHAR[261] TerminalServerHomeDir;
	public CHAR[4] TerminalServerHomeDirDrive;
}

[CRepr]
public struct WTSUSERCONFIGW
{
	public uint32 Source;
	public uint32 InheritInitialProgram;
	public uint32 AllowLogonTerminalServer;
	public uint32 TimeoutSettingsConnections;
	public uint32 TimeoutSettingsDisconnections;
	public uint32 TimeoutSettingsIdle;
	public uint32 DeviceClientDrives;
	public uint32 DeviceClientPrinters;
	public uint32 ClientDefaultPrinter;
	public uint32 BrokenTimeoutSettings;
	public uint32 ReconnectSettings;
	public uint32 ShadowingSettings;
	public uint32 TerminalServerRemoteHomeDir;
	public char16[261] InitialProgram;
	public char16[261] WorkDirectory;
	public char16[261] TerminalServerProfilePath;
	public char16[261] TerminalServerHomeDir;
	public char16[4] TerminalServerHomeDirDrive;
}

[CRepr]
public struct WTS_SESSION_ADDRESS
{
	public uint32 AddressFamily;
	public uint8[20] Address;
}

[CRepr]
public struct WTS_PROCESS_INFO_EXW
{
	public uint32 SessionId;
	public uint32 ProcessId;
	public PWSTR pProcessName;
	public PSID pUserSid;
	public uint32 NumberOfThreads;
	public uint32 HandleCount;
	public uint32 PagefileUsage;
	public uint32 PeakPagefileUsage;
	public uint32 WorkingSetSize;
	public uint32 PeakWorkingSetSize;
	public LARGE_INTEGER UserTime;
	public LARGE_INTEGER KernelTime;
}

[CRepr]
public struct WTS_PROCESS_INFO_EXA
{
	public uint32 SessionId;
	public uint32 ProcessId;
	public PSTR pProcessName;
	public PSID pUserSid;
	public uint32 NumberOfThreads;
	public uint32 HandleCount;
	public uint32 PagefileUsage;
	public uint32 PeakPagefileUsage;
	public uint32 WorkingSetSize;
	public uint32 PeakWorkingSetSize;
	public LARGE_INTEGER UserTime;
	public LARGE_INTEGER KernelTime;
}

[CRepr]
public struct WTSLISTENERCONFIGW
{
	public uint32 version;
	public uint32 fEnableListener;
	public uint32 MaxConnectionCount;
	public uint32 fPromptForPassword;
	public uint32 fInheritColorDepth;
	public uint32 ColorDepth;
	public uint32 fInheritBrokenTimeoutSettings;
	public uint32 BrokenTimeoutSettings;
	public uint32 fDisablePrinterRedirection;
	public uint32 fDisableDriveRedirection;
	public uint32 fDisableComPortRedirection;
	public uint32 fDisableLPTPortRedirection;
	public uint32 fDisableClipboardRedirection;
	public uint32 fDisableAudioRedirection;
	public uint32 fDisablePNPRedirection;
	public uint32 fDisableDefaultMainClientPrinter;
	public uint32 LanAdapter;
	public uint32 PortNumber;
	public uint32 fInheritShadowSettings;
	public uint32 ShadowSettings;
	public uint32 TimeoutSettingsConnection;
	public uint32 TimeoutSettingsDisconnection;
	public uint32 TimeoutSettingsIdle;
	public uint32 SecurityLayer;
	public uint32 MinEncryptionLevel;
	public uint32 UserAuthentication;
	public char16[61] Comment;
	public char16[21] LogonUserName;
	public char16[18] LogonDomain;
	public char16[261] WorkDirectory;
	public char16[261] InitialProgram;
}

[CRepr]
public struct WTSLISTENERCONFIGA
{
	public uint32 version;
	public uint32 fEnableListener;
	public uint32 MaxConnectionCount;
	public uint32 fPromptForPassword;
	public uint32 fInheritColorDepth;
	public uint32 ColorDepth;
	public uint32 fInheritBrokenTimeoutSettings;
	public uint32 BrokenTimeoutSettings;
	public uint32 fDisablePrinterRedirection;
	public uint32 fDisableDriveRedirection;
	public uint32 fDisableComPortRedirection;
	public uint32 fDisableLPTPortRedirection;
	public uint32 fDisableClipboardRedirection;
	public uint32 fDisableAudioRedirection;
	public uint32 fDisablePNPRedirection;
	public uint32 fDisableDefaultMainClientPrinter;
	public uint32 LanAdapter;
	public uint32 PortNumber;
	public uint32 fInheritShadowSettings;
	public uint32 ShadowSettings;
	public uint32 TimeoutSettingsConnection;
	public uint32 TimeoutSettingsDisconnection;
	public uint32 TimeoutSettingsIdle;
	public uint32 SecurityLayer;
	public uint32 MinEncryptionLevel;
	public uint32 UserAuthentication;
	public CHAR[61] Comment;
	public CHAR[21] LogonUserName;
	public CHAR[18] LogonDomain;
	public CHAR[261] WorkDirectory;
	public CHAR[261] InitialProgram;
}

[CRepr]
public struct WTSSBX_IP_ADDRESS
{
	public WTSSBX_ADDRESS_FAMILY AddressFamily;
	public uint8[16] Address;
	public uint16 PortNumber;
	public uint32 dwScope;
}

[CRepr]
public struct WTSSBX_MACHINE_CONNECT_INFO
{
	public char16[257] wczMachineFQDN;
	public char16[17] wczMachineNetBiosName;
	public uint32 dwNumOfIPAddr;
	public WTSSBX_IP_ADDRESS[12] IPaddr;
}

[CRepr]
public struct WTSSBX_MACHINE_INFO
{
	public WTSSBX_MACHINE_CONNECT_INFO ClientConnectInfo;
	public char16[257] wczFarmName;
	public WTSSBX_IP_ADDRESS InternalIPAddress;
	public uint32 dwMaxSessionsLimit;
	public uint32 ServerWeight;
	public WTSSBX_MACHINE_SESSION_MODE SingleSessionMode;
	public WTSSBX_MACHINE_DRAIN InDrain;
	public WTSSBX_MACHINE_STATE MachineState;
}

[CRepr]
public struct WTSSBX_SESSION_INFO
{
	public char16[105] wszUserName;
	public char16[257] wszDomainName;
	public char16[257] ApplicationType;
	public uint32 dwSessionId;
	public FILETIME CreateTime;
	public FILETIME DisconnectTime;
	public WTSSBX_SESSION_STATE SessionState;
}

[CRepr, Packed(1)]
public struct CHANNEL_DEF
{
	public CHAR[8] name;
	public uint32 options;
}

[CRepr]
public struct CHANNEL_PDU_HEADER
{
	public uint32 length;
	public uint32 flags;
}

[CRepr]
public struct CHANNEL_ENTRY_POINTS
{
	public uint32 cbSize;
	public uint32 protocolVersion;
	public PVIRTUALCHANNELINIT pVirtualChannelInit;
	public PVIRTUALCHANNELOPEN pVirtualChannelOpen;
	public PVIRTUALCHANNELCLOSE pVirtualChannelClose;
	public PVIRTUALCHANNELWRITE pVirtualChannelWrite;
}

[CRepr]
public struct CLIENT_DISPLAY
{
	public uint32 HorizontalResolution;
	public uint32 VerticalResolution;
	public uint32 ColorDepth;
}

[CRepr]
public struct TSSD_ConnectionPoint
{
	public uint8[16] ServerAddressB;
	public TSSD_AddrV46Type AddressType;
	public uint16 PortNumber;
	public uint32 AddressScope;
}

[CRepr]
public struct VM_NOTIFY_ENTRY
{
	public char16[128] VmName;
	public char16[128] VmHost;
}

[CRepr]
public struct VM_PATCH_INFO
{
	public uint32 dwNumEntries;
	public PWSTR* pVmNames;
}

[CRepr]
public struct VM_NOTIFY_INFO
{
	public uint32 dwNumEntries;
	public VM_NOTIFY_ENTRY** ppVmEntries;
}

[CRepr]
public struct pluginResource
{
	public char16[256] alias;
	public char16[256] name;
	public PWSTR resourceFileContents;
	public char16[256] fileExtension;
	public char16[256] resourcePluginType;
	public uint8 isDiscoverable;
	public int32 resourceType;
	public uint32 pceIconSize;
	public uint8* iconContents;
	public uint32 pcePluginBlobSize;
	public uint8* blobContents;
}

[CRepr]
public struct pluginResource2FileAssociation
{
	public char16[256] extName;
	public uint8 primaryHandler;
	public uint32 pceIconSize;
	public uint8* iconContents;
}

[CRepr]
public struct pluginResource2
{
	public pluginResource resourceV1;
	public uint32 pceFileAssocListSize;
	public pluginResource2FileAssociation* fileAssocList;
	public PWSTR securityDescriptor;
	public uint32 pceFolderListSize;
	public uint16** folderList;
}

[CRepr]
public struct BITMAP_RENDERER_STATISTICS
{
	public uint32 dwFramesDelivered;
	public uint32 dwFramesDropped;
}

[CRepr, Packed(1)]
public struct RFX_GFX_RECT
{
	public int32 left;
	public int32 top;
	public int32 right;
	public int32 bottom;
}

[CRepr, Packed(1)]
public struct RFX_GFX_MSG_HEADER
{
	public uint16 uMSGType;
	public uint16 cbSize;
}

[CRepr, Packed(1)]
public struct RFX_GFX_MONITOR_INFO
{
	public int32 left;
	public int32 top;
	public int32 right;
	public int32 bottom;
	public uint32 physicalWidth;
	public uint32 physicalHeight;
	public uint32 orientation;
	public BOOL primary;
}

[CRepr]
public struct RFX_GFX_MSG_CLIENT_DESKTOP_INFO_REQUEST
{
	public RFX_GFX_MSG_HEADER channelHdr;
}

[CRepr, Packed(1)]
public struct RFX_GFX_MSG_CLIENT_DESKTOP_INFO_RESPONSE
{
	public RFX_GFX_MSG_HEADER channelHdr;
	public uint32 reserved;
	public uint32 monitorCount;
	public RFX_GFX_MONITOR_INFO[16] MonitorData;
	public char16[32] clientUniqueId;
}

[CRepr, Packed(1)]
public struct RFX_GFX_MSG_DESKTOP_CONFIG_CHANGE_NOTIFY
{
	public RFX_GFX_MSG_HEADER channelHdr;
	public uint32 ulWidth;
	public uint32 ulHeight;
	public uint32 ulBpp;
	public uint32 Reserved;
}

[CRepr]
public struct RFX_GFX_MSG_DESKTOP_CONFIG_CHANGE_CONFIRM
{
	public RFX_GFX_MSG_HEADER channelHdr;
}

[CRepr, Packed(1)]
public struct RFX_GFX_MSG_DESKTOP_INPUT_RESET
{
	public RFX_GFX_MSG_HEADER channelHdr;
	public uint32 ulWidth;
	public uint32 ulHeight;
}

[CRepr, Packed(1)]
public struct RFX_GFX_MSG_DISCONNECT_NOTIFY
{
	public RFX_GFX_MSG_HEADER channelHdr;
	public uint32 DisconnectReason;
}

[CRepr]
public struct RFX_GFX_MSG_DESKTOP_RESEND_REQUEST
{
	public RFX_GFX_MSG_HEADER channelHdr;
	public RFX_GFX_RECT RedrawRect;
}

[CRepr]
public struct RFX_GFX_MSG_RDP_DATA
{
	public RFX_GFX_MSG_HEADER channelHdr;
	public uint8* rdpData mut => &rdpData_impl;
	private uint8[ANYSIZE_ARRAY] rdpData_impl;
}

[CRepr]
public struct WTS_SOCKADDR
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		[CRepr]
		public struct _ipv6_e__Struct
		{
			public uint16 sin6_port;
			public uint32 sin6_flowinfo;
			public uint16[8] sin6_addr;
			public uint32 sin6_scope_id;
		}
		[CRepr]
		public struct _ipv4_e__Struct
		{
			public uint16 sin_port;
			public uint32 IN_ADDR;
			public uint8[8] sin_zero;
		}
		public _ipv4_e__Struct ipv4;
		public _ipv6_e__Struct ipv6;
	}
	public uint16 sin_family;
	public _u_e__Union u;
}

[CRepr]
public struct WTS_SMALL_RECT
{
	public int16 Left;
	public int16 Top;
	public int16 Right;
	public int16 Bottom;
}

[CRepr]
public struct WTS_SERVICE_STATE
{
	public WTS_RCM_SERVICE_STATE RcmServiceState;
	public WTS_RCM_DRAIN_STATE RcmDrainState;
}

[CRepr]
public struct WTS_SESSION_ID
{
	public Guid SessionUniqueGuid;
	public uint32 SessionId;
}

[CRepr]
public struct WTS_USER_CREDENTIAL
{
	public char16[256] UserName;
	public char16[256] Password;
	public char16[256] Domain;
}

[CRepr]
public struct WTS_SYSTEMTIME
{
	public uint16 wYear;
	public uint16 wMonth;
	public uint16 wDayOfWeek;
	public uint16 wDay;
	public uint16 wHour;
	public uint16 wMinute;
	public uint16 wSecond;
	public uint16 wMilliseconds;
}

[CRepr]
public struct WTS_TIME_ZONE_INFORMATION
{
	public int32 Bias;
	public char16[32] StandardName;
	public WTS_SYSTEMTIME StandardDate;
	public int32 StandardBias;
	public char16[32] DaylightName;
	public WTS_SYSTEMTIME DaylightDate;
	public int32 DaylightBias;
}

[CRepr]
public struct WRDS_DYNAMIC_TIME_ZONE_INFORMATION
{
	public int32 Bias;
	public char16[32] StandardName;
	public WTS_SYSTEMTIME StandardDate;
	public int32 StandardBias;
	public char16[32] DaylightName;
	public WTS_SYSTEMTIME DaylightDate;
	public int32 DaylightBias;
	public char16[128] TimeZoneKeyName;
	public uint16 DynamicDaylightTimeDisabled;
}

[CRepr]
public struct WTS_CLIENT_DATA
{
	public BOOLEAN fDisableCtrlAltDel;
	public BOOLEAN fDoubleClickDetect;
	public BOOLEAN fEnableWindowsKey;
	public BOOLEAN fHideTitleBar;
	public BOOL fInheritAutoLogon;
	public BOOLEAN fPromptForPassword;
	public BOOLEAN fUsingSavedCreds;
	public char16[256] Domain;
	public char16[256] UserName;
	public char16[256] Password;
	public BOOLEAN fPasswordIsScPin;
	public BOOL fInheritInitialProgram;
	public char16[257] WorkDirectory;
	public char16[257] InitialProgram;
	public BOOLEAN fMaximizeShell;
	public uint8 EncryptionLevel;
	public uint32 PerformanceFlags;
	public char16[9] ProtocolName;
	public uint16 ProtocolType;
	public BOOL fInheritColorDepth;
	public uint16 HRes;
	public uint16 VRes;
	public uint16 ColorDepth;
	public char16[9] DisplayDriverName;
	public char16[20] DisplayDeviceName;
	public BOOLEAN fMouse;
	public uint32 KeyboardLayout;
	public uint32 KeyboardType;
	public uint32 KeyboardSubType;
	public uint32 KeyboardFunctionKey;
	public char16[33] imeFileName;
	public uint32 ActiveInputLocale;
	public BOOLEAN fNoAudioPlayback;
	public BOOLEAN fRemoteConsoleAudio;
	public char16[9] AudioDriverName;
	public WTS_TIME_ZONE_INFORMATION ClientTimeZone;
	public char16[21] ClientName;
	public uint32 SerialNumber;
	public uint32 ClientAddressFamily;
	public char16[31] ClientAddress;
	public WTS_SOCKADDR ClientSockAddress;
	public char16[257] ClientDirectory;
	public uint32 ClientBuildNumber;
	public uint16 ClientProductId;
	public uint16 OutBufCountHost;
	public uint16 OutBufCountClient;
	public uint16 OutBufLength;
	public uint32 ClientSessionId;
	public char16[33] ClientDigProductId;
	public BOOLEAN fDisableCpm;
	public BOOLEAN fDisableCdm;
	public BOOLEAN fDisableCcm;
	public BOOLEAN fDisableLPT;
	public BOOLEAN fDisableClip;
	public BOOLEAN fDisablePNP;
}

[CRepr]
public struct WTS_USER_DATA
{
	public char16[257] WorkDirectory;
	public char16[257] InitialProgram;
	public WTS_TIME_ZONE_INFORMATION UserTimeZone;
}

[CRepr]
public struct WTS_POLICY_DATA
{
	public BOOLEAN fDisableEncryption;
	public BOOLEAN fDisableAutoReconnect;
	public uint32 ColorDepth;
	public uint8 MinEncryptionLevel;
	public BOOLEAN fDisableCpm;
	public BOOLEAN fDisableCdm;
	public BOOLEAN fDisableCcm;
	public BOOLEAN fDisableLPT;
	public BOOLEAN fDisableClip;
	public BOOLEAN fDisablePNPRedir;
}

[CRepr]
public struct WTS_PROTOCOL_CACHE
{
	public uint32 CacheReads;
	public uint32 CacheHits;
}

[CRepr, Union]
public struct WTS_CACHE_STATS_UN
{
	public WTS_PROTOCOL_CACHE[4] ProtocolCache;
	public uint32 TShareCacheStats;
	public uint32[20] Reserved;
}

[CRepr]
public struct WTS_CACHE_STATS
{
	public uint32 Specific;
	public WTS_CACHE_STATS_UN Data;
	public uint16 ProtocolType;
	public uint16 Length;
}

[CRepr]
public struct WTS_PROTOCOL_COUNTERS
{
	public uint32 WdBytes;
	public uint32 WdFrames;
	public uint32 WaitForOutBuf;
	public uint32 Frames;
	public uint32 Bytes;
	public uint32 CompressedBytes;
	public uint32 CompressFlushes;
	public uint32 Errors;
	public uint32 Timeouts;
	public uint32 AsyncFramingError;
	public uint32 AsyncOverrunError;
	public uint32 AsyncOverflowError;
	public uint32 AsyncParityError;
	public uint32 TdErrors;
	public uint16 ProtocolType;
	public uint16 Length;
	public uint16 Specific;
	public uint32[100] Reserved;
}

[CRepr]
public struct WTS_PROTOCOL_STATUS
{
	public WTS_PROTOCOL_COUNTERS Output;
	public WTS_PROTOCOL_COUNTERS Input;
	public WTS_CACHE_STATS Cache;
	public uint32 AsyncSignal;
	public uint32 AsyncSignalMask;
	public LARGE_INTEGER[100] Counters;
}

[CRepr]
public struct WTS_DISPLAY_IOCTL
{
	public uint8[256] pDisplayIOCtlData;
	public uint32 cbDisplayIOCtlData;
}

[CRepr]
public struct WTS_PROPERTY_VALUE
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		[CRepr]
		public struct _bVal_e__Struct
		{
			public uint32 size;
			public PSTR pbVal;
		}
		[CRepr]
		public struct _strVal_e__Struct
		{
			public uint32 size;
			public PWSTR pstrVal;
		}
		public uint32 ulVal;
		public _strVal_e__Struct strVal;
		public _bVal_e__Struct bVal;
		public Guid guidVal;
	}
	public uint16 Type;
	public _u_e__Union u;
}

[CRepr]
public struct WTS_LICENSE_CAPABILITIES
{
	public uint32 KeyExchangeAlg;
	public uint32 ProtocolVer;
	public BOOL fAuthenticateServer;
	public WTS_CERT_TYPE CertType;
	public uint32 cbClientName;
	public uint8[42] rgbClientName;
}

[CRepr]
public struct WRDS_LISTENER_SETTINGS_1
{
	public uint32 MaxProtocolListenerConnectionCount;
	public uint32 SecurityDescriptorSize;
	public uint8* pSecurityDescriptor;
}

[CRepr, Union]
public struct WRDS_LISTENER_SETTING
{
	public WRDS_LISTENER_SETTINGS_1 WRdsListenerSettings1;
}

[CRepr]
public struct WRDS_LISTENER_SETTINGS
{
	public WRDS_LISTENER_SETTING_LEVEL WRdsListenerSettingLevel;
	public WRDS_LISTENER_SETTING WRdsListenerSetting;
}

[CRepr]
public struct WRDS_CONNECTION_SETTINGS_1
{
	public BOOLEAN fInheritInitialProgram;
	public BOOLEAN fInheritColorDepth;
	public BOOLEAN fHideTitleBar;
	public BOOLEAN fInheritAutoLogon;
	public BOOLEAN fMaximizeShell;
	public BOOLEAN fDisablePNP;
	public BOOLEAN fPasswordIsScPin;
	public BOOLEAN fPromptForPassword;
	public BOOLEAN fDisableCpm;
	public BOOLEAN fDisableCdm;
	public BOOLEAN fDisableCcm;
	public BOOLEAN fDisableLPT;
	public BOOLEAN fDisableClip;
	public BOOLEAN fResetBroken;
	public BOOLEAN fDisableEncryption;
	public BOOLEAN fDisableAutoReconnect;
	public BOOLEAN fDisableCtrlAltDel;
	public BOOLEAN fDoubleClickDetect;
	public BOOLEAN fEnableWindowsKey;
	public BOOLEAN fUsingSavedCreds;
	public BOOLEAN fMouse;
	public BOOLEAN fNoAudioPlayback;
	public BOOLEAN fRemoteConsoleAudio;
	public uint8 EncryptionLevel;
	public uint16 ColorDepth;
	public uint16 ProtocolType;
	public uint16 HRes;
	public uint16 VRes;
	public uint16 ClientProductId;
	public uint16 OutBufCountHost;
	public uint16 OutBufCountClient;
	public uint16 OutBufLength;
	public uint32 KeyboardLayout;
	public uint32 MaxConnectionTime;
	public uint32 MaxDisconnectionTime;
	public uint32 MaxIdleTime;
	public uint32 PerformanceFlags;
	public uint32 KeyboardType;
	public uint32 KeyboardSubType;
	public uint32 KeyboardFunctionKey;
	public uint32 ActiveInputLocale;
	public uint32 SerialNumber;
	public uint32 ClientAddressFamily;
	public uint32 ClientBuildNumber;
	public uint32 ClientSessionId;
	public char16[257] WorkDirectory;
	public char16[257] InitialProgram;
	public char16[256] UserName;
	public char16[256] Domain;
	public char16[256] Password;
	public char16[9] ProtocolName;
	public char16[9] DisplayDriverName;
	public char16[20] DisplayDeviceName;
	public char16[33] imeFileName;
	public char16[9] AudioDriverName;
	public char16[21] ClientName;
	public char16[31] ClientAddress;
	public char16[257] ClientDirectory;
	public char16[33] ClientDigProductId;
	public WTS_SOCKADDR ClientSockAddress;
	public WTS_TIME_ZONE_INFORMATION ClientTimeZone;
	public WRDS_LISTENER_SETTINGS WRdsListenerSettings;
	public Guid EventLogActivityId;
	public uint32 ContextSize;
	public uint8* ContextData;
}

[CRepr]
public struct WRDS_SETTINGS_1
{
	public WRDS_SETTING_STATUS WRdsDisableClipStatus;
	public uint32 WRdsDisableClipValue;
	public WRDS_SETTING_STATUS WRdsDisableLPTStatus;
	public uint32 WRdsDisableLPTValue;
	public WRDS_SETTING_STATUS WRdsDisableCcmStatus;
	public uint32 WRdsDisableCcmValue;
	public WRDS_SETTING_STATUS WRdsDisableCdmStatus;
	public uint32 WRdsDisableCdmValue;
	public WRDS_SETTING_STATUS WRdsDisableCpmStatus;
	public uint32 WRdsDisableCpmValue;
	public WRDS_SETTING_STATUS WRdsDisablePnpStatus;
	public uint32 WRdsDisablePnpValue;
	public WRDS_SETTING_STATUS WRdsEncryptionLevelStatus;
	public uint32 WRdsEncryptionValue;
	public WRDS_SETTING_STATUS WRdsColorDepthStatus;
	public uint32 WRdsColorDepthValue;
	public WRDS_SETTING_STATUS WRdsDisableAutoReconnecetStatus;
	public uint32 WRdsDisableAutoReconnecetValue;
	public WRDS_SETTING_STATUS WRdsDisableEncryptionStatus;
	public uint32 WRdsDisableEncryptionValue;
	public WRDS_SETTING_STATUS WRdsResetBrokenStatus;
	public uint32 WRdsResetBrokenValue;
	public WRDS_SETTING_STATUS WRdsMaxIdleTimeStatus;
	public uint32 WRdsMaxIdleTimeValue;
	public WRDS_SETTING_STATUS WRdsMaxDisconnectTimeStatus;
	public uint32 WRdsMaxDisconnectTimeValue;
	public WRDS_SETTING_STATUS WRdsMaxConnectTimeStatus;
	public uint32 WRdsMaxConnectTimeValue;
	public WRDS_SETTING_STATUS WRdsKeepAliveStatus;
	public BOOLEAN WRdsKeepAliveStartValue;
	public uint32 WRdsKeepAliveIntervalValue;
}

[CRepr, Union]
public struct WRDS_CONNECTION_SETTING
{
	public WRDS_CONNECTION_SETTINGS_1 WRdsConnectionSettings1;
}

[CRepr]
public struct WRDS_CONNECTION_SETTINGS
{
	public WRDS_CONNECTION_SETTING_LEVEL WRdsConnectionSettingLevel;
	public WRDS_CONNECTION_SETTING WRdsConnectionSetting;
}

[CRepr, Union]
public struct WRDS_SETTING
{
	public WRDS_SETTINGS_1 WRdsSettings1;
}

[CRepr]
public struct WRDS_SETTINGS
{
	public WRDS_SETTING_TYPE WRdsSettingType;
	public WRDS_SETTING_LEVEL WRdsSettingLevel;
	public WRDS_SETTING WRdsSetting;
}

[CRepr]
public struct WTSSESSION_NOTIFICATION
{
	public uint32 cbSize;
	public uint32 dwSessionId;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_TSUserExInterfaces = .(0x0910dd01, 0xdf8c, 0x11d1, 0xae, 0x27, 0x00, 0xc0, 0x4f, 0xa3, 0x58, 0x13);


	public const Guid CLSID_ADsTSUserEx = .(0xe2e9cae6, 0x1e7b, 0x4b8e, 0xba, 0xbd, 0xe9, 0xbf, 0x62, 0x92, 0xac, 0x29);


	public const Guid CLSID_Workspace = .(0x4f1dfca6, 0x3aad, 0x48e1, 0x84, 0x06, 0x4b, 0xc2, 0x1a, 0x50, 0x1d, 0x7c);


}
#endregion

#region COM Types
[CRepr]struct IAudioEndpoint : IUnknown
{
	public new const Guid IID = .(0x30a99515, 0x1527, 0x4451, 0xaf, 0x9f, 0x00, 0xc5, 0xf0, 0x23, 0x4d, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WAVEFORMATEX** ppFormat) GetFrameFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFramesPerPacket) GetFramesPerPacket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* pLatency) GetLatency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 streamFlags) SetStreamFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE eventHandle) SetEventHandle;
	}


	public HRESULT GetFrameFormat(WAVEFORMATEX** ppFormat) mut => VT.[Friend]GetFrameFormat(&this, ppFormat);

	public HRESULT GetFramesPerPacket(uint32* pFramesPerPacket) mut => VT.[Friend]GetFramesPerPacket(&this, pFramesPerPacket);

	public HRESULT GetLatency(int64* pLatency) mut => VT.[Friend]GetLatency(&this, pLatency);

	public HRESULT SetStreamFlags(uint32 streamFlags) mut => VT.[Friend]SetStreamFlags(&this, streamFlags);

	public HRESULT SetEventHandle(HANDLE eventHandle) mut => VT.[Friend]SetEventHandle(&this, eventHandle);
}

[CRepr]struct IAudioEndpointRT : IUnknown
{
	public new const Guid IID = .(0xdfd2005f, 0xa6e5, 0x4d39, 0xa2, 0x65, 0x93, 0x9a, 0xda, 0x9f, 0xbb, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int64* pPadding, AE_CURRENT_POSITION* pAeCurrentPosition) GetCurrentPadding;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) ProcessingComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetPinInactive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetPinActive;
	}


	public void GetCurrentPadding(int64* pPadding, AE_CURRENT_POSITION* pAeCurrentPosition) mut => VT.[Friend]GetCurrentPadding(&this, pPadding, pAeCurrentPosition);

	public void ProcessingComplete() mut => VT.[Friend]ProcessingComplete(&this);

	public HRESULT SetPinInactive() mut => VT.[Friend]SetPinInactive(&this);

	public HRESULT SetPinActive() mut => VT.[Friend]SetPinActive(&this);
}

[CRepr]struct IAudioInputEndpointRT : IUnknown
{
	public new const Guid IID = .(0x8026ab61, 0x92b2, 0x43c1, 0xa1, 0xdf, 0x5c, 0x37, 0xeb, 0xd0, 0x8d, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, APO_CONNECTION_PROPERTY* pConnectionProperty, AE_CURRENT_POSITION* pAeTimeStamp) GetInputDataPointer;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, uint32 u32FrameCount, uint pDataPointer) ReleaseInputDataPointer;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) PulseEndpoint;
	}


	public void GetInputDataPointer(APO_CONNECTION_PROPERTY* pConnectionProperty, AE_CURRENT_POSITION* pAeTimeStamp) mut => VT.[Friend]GetInputDataPointer(&this, pConnectionProperty, pAeTimeStamp);

	public void ReleaseInputDataPointer(uint32 u32FrameCount, uint pDataPointer) mut => VT.[Friend]ReleaseInputDataPointer(&this, u32FrameCount, pDataPointer);

	public void PulseEndpoint() mut => VT.[Friend]PulseEndpoint(&this);
}

[CRepr]struct IAudioOutputEndpointRT : IUnknown
{
	public new const Guid IID = .(0x8fa906e4, 0xc31c, 0x4e31, 0x93, 0x2e, 0x19, 0xa6, 0x63, 0x85, 0xe9, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint(SelfOuter* self, uint32 u32FrameCount, AE_CURRENT_POSITION* pAeTimeStamp) GetOutputDataPointer;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, APO_CONNECTION_PROPERTY* pConnectionProperty) ReleaseOutputDataPointer;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) PulseEndpoint;
	}


	public uint GetOutputDataPointer(uint32 u32FrameCount, AE_CURRENT_POSITION* pAeTimeStamp) mut => VT.[Friend]GetOutputDataPointer(&this, u32FrameCount, pAeTimeStamp);

	public void ReleaseOutputDataPointer(APO_CONNECTION_PROPERTY* pConnectionProperty) mut => VT.[Friend]ReleaseOutputDataPointer(&this, pConnectionProperty);

	public void PulseEndpoint() mut => VT.[Friend]PulseEndpoint(&this);
}

[CRepr]struct IAudioDeviceEndpoint : IUnknown
{
	public new const Guid IID = .(0xd4952f5a, 0xa0b2, 0x4cc4, 0x8b, 0x82, 0x93, 0x58, 0x48, 0x8d, 0xd8, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64 MaxPeriod, uint32 u32LatencyCoefficient) SetBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbIsRTCapable) GetRTCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbisEventCapable) GetEventDrivenCapable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hTargetProcess, int64 hnsPeriod, int64 hnsBufferDuration, uint32 u32LatencyCoefficient, uint32* pu32SharedMemorySize, uint* phSharedMemory) WriteExclusiveModeParametersToSharedMemory;
	}


	public HRESULT SetBuffer(int64 MaxPeriod, uint32 u32LatencyCoefficient) mut => VT.[Friend]SetBuffer(&this, MaxPeriod, u32LatencyCoefficient);

	public HRESULT GetRTCaps(BOOL* pbIsRTCapable) mut => VT.[Friend]GetRTCaps(&this, pbIsRTCapable);

	public HRESULT GetEventDrivenCapable(BOOL* pbisEventCapable) mut => VT.[Friend]GetEventDrivenCapable(&this, pbisEventCapable);

	public HRESULT WriteExclusiveModeParametersToSharedMemory(uint hTargetProcess, int64 hnsPeriod, int64 hnsBufferDuration, uint32 u32LatencyCoefficient, uint32* pu32SharedMemorySize, uint* phSharedMemory) mut => VT.[Friend]WriteExclusiveModeParametersToSharedMemory(&this, hTargetProcess, hnsPeriod, hnsBufferDuration, u32LatencyCoefficient, pu32SharedMemorySize, phSharedMemory);
}

[CRepr]struct IAudioEndpointControl : IUnknown
{
	public new const Guid IID = .(0xc684b72a, 0x6df4, 0x4774, 0xbd, 0xf9, 0x76, 0xb7, 0x75, 0x09, 0xb6, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
	}


	public HRESULT Start() mut => VT.[Friend]Start(&this);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);
}

[CRepr]struct IADsTSUserEx : IDispatch
{
	public new const Guid IID = .(0xc4930e79, 0x2989, 0x4462, 0x8a, 0x60, 0x2f, 0xcf, 0x2f, 0x29, 0x55, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_TerminalServicesProfilePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pNewVal) put_TerminalServicesProfilePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_TerminalServicesHomeDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pNewVal) put_TerminalServicesHomeDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_TerminalServicesHomeDrive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pNewVal) put_TerminalServicesHomeDrive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_AllowLogon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_AllowLogon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_EnableRemoteControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_EnableRemoteControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_MaxDisconnectionTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_MaxDisconnectionTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_MaxConnectionTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_MaxConnectionTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_MaxIdleTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_MaxIdleTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pNewVal) get_ReconnectionAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_ReconnectionAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pNewVal) get_BrokenConnectionAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_BrokenConnectionAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pNewVal) get_ConnectClientDrivesAtLogon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_ConnectClientDrivesAtLogon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_ConnectClientPrintersAtLogon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_ConnectClientPrintersAtLogon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_DefaultToMainPrinter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NewVal) put_DefaultToMainPrinter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_TerminalServicesWorkDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pNewVal) put_TerminalServicesWorkDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_TerminalServicesInitialProgram;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pNewVal) put_TerminalServicesInitialProgram;
	}


	public HRESULT get_TerminalServicesProfilePath(BSTR* pVal) mut => VT.[Friend]get_TerminalServicesProfilePath(&this, pVal);

	public HRESULT put_TerminalServicesProfilePath(BSTR pNewVal) mut => VT.[Friend]put_TerminalServicesProfilePath(&this, pNewVal);

	public HRESULT get_TerminalServicesHomeDirectory(BSTR* pVal) mut => VT.[Friend]get_TerminalServicesHomeDirectory(&this, pVal);

	public HRESULT put_TerminalServicesHomeDirectory(BSTR pNewVal) mut => VT.[Friend]put_TerminalServicesHomeDirectory(&this, pNewVal);

	public HRESULT get_TerminalServicesHomeDrive(BSTR* pVal) mut => VT.[Friend]get_TerminalServicesHomeDrive(&this, pVal);

	public HRESULT put_TerminalServicesHomeDrive(BSTR pNewVal) mut => VT.[Friend]put_TerminalServicesHomeDrive(&this, pNewVal);

	public HRESULT get_AllowLogon(int32* pVal) mut => VT.[Friend]get_AllowLogon(&this, pVal);

	public HRESULT put_AllowLogon(int32 NewVal) mut => VT.[Friend]put_AllowLogon(&this, NewVal);

	public HRESULT get_EnableRemoteControl(int32* pVal) mut => VT.[Friend]get_EnableRemoteControl(&this, pVal);

	public HRESULT put_EnableRemoteControl(int32 NewVal) mut => VT.[Friend]put_EnableRemoteControl(&this, NewVal);

	public HRESULT get_MaxDisconnectionTime(int32* pVal) mut => VT.[Friend]get_MaxDisconnectionTime(&this, pVal);

	public HRESULT put_MaxDisconnectionTime(int32 NewVal) mut => VT.[Friend]put_MaxDisconnectionTime(&this, NewVal);

	public HRESULT get_MaxConnectionTime(int32* pVal) mut => VT.[Friend]get_MaxConnectionTime(&this, pVal);

	public HRESULT put_MaxConnectionTime(int32 NewVal) mut => VT.[Friend]put_MaxConnectionTime(&this, NewVal);

	public HRESULT get_MaxIdleTime(int32* pVal) mut => VT.[Friend]get_MaxIdleTime(&this, pVal);

	public HRESULT put_MaxIdleTime(int32 NewVal) mut => VT.[Friend]put_MaxIdleTime(&this, NewVal);

	public HRESULT get_ReconnectionAction(int32* pNewVal) mut => VT.[Friend]get_ReconnectionAction(&this, pNewVal);

	public HRESULT put_ReconnectionAction(int32 NewVal) mut => VT.[Friend]put_ReconnectionAction(&this, NewVal);

	public HRESULT get_BrokenConnectionAction(int32* pNewVal) mut => VT.[Friend]get_BrokenConnectionAction(&this, pNewVal);

	public HRESULT put_BrokenConnectionAction(int32 NewVal) mut => VT.[Friend]put_BrokenConnectionAction(&this, NewVal);

	public HRESULT get_ConnectClientDrivesAtLogon(int32* pNewVal) mut => VT.[Friend]get_ConnectClientDrivesAtLogon(&this, pNewVal);

	public HRESULT put_ConnectClientDrivesAtLogon(int32 NewVal) mut => VT.[Friend]put_ConnectClientDrivesAtLogon(&this, NewVal);

	public HRESULT get_ConnectClientPrintersAtLogon(int32* pVal) mut => VT.[Friend]get_ConnectClientPrintersAtLogon(&this, pVal);

	public HRESULT put_ConnectClientPrintersAtLogon(int32 NewVal) mut => VT.[Friend]put_ConnectClientPrintersAtLogon(&this, NewVal);

	public HRESULT get_DefaultToMainPrinter(int32* pVal) mut => VT.[Friend]get_DefaultToMainPrinter(&this, pVal);

	public HRESULT put_DefaultToMainPrinter(int32 NewVal) mut => VT.[Friend]put_DefaultToMainPrinter(&this, NewVal);

	public HRESULT get_TerminalServicesWorkDirectory(BSTR* pVal) mut => VT.[Friend]get_TerminalServicesWorkDirectory(&this, pVal);

	public HRESULT put_TerminalServicesWorkDirectory(BSTR pNewVal) mut => VT.[Friend]put_TerminalServicesWorkDirectory(&this, pNewVal);

	public HRESULT get_TerminalServicesInitialProgram(BSTR* pVal) mut => VT.[Friend]get_TerminalServicesInitialProgram(&this, pVal);

	public HRESULT put_TerminalServicesInitialProgram(BSTR pNewVal) mut => VT.[Friend]put_TerminalServicesInitialProgram(&this, pNewVal);
}

[CRepr]struct ITSGAuthorizeConnectionSink : IUnknown
{
	public new const Guid IID = .(0xc27ece33, 0x7781, 0x4318, 0x98, 0xef, 0x1c, 0xf2, 0xda, 0x7b, 0x70, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrIn, Guid mainSessionId, uint32 cbSoHResponse, uint8* pbSoHResponse, uint32 idleTimeout, uint32 sessionTimeout, SESSION_TIMEOUT_ACTION_TYPE sessionTimeoutAction, AATrustClassID trustClass, uint32* policyAttributes) OnConnectionAuthorized;
	}


	public HRESULT OnConnectionAuthorized(HRESULT hrIn, Guid mainSessionId, uint32 cbSoHResponse, uint8* pbSoHResponse, uint32 idleTimeout, uint32 sessionTimeout, SESSION_TIMEOUT_ACTION_TYPE sessionTimeoutAction, AATrustClassID trustClass, uint32* policyAttributes) mut => VT.[Friend]OnConnectionAuthorized(&this, hrIn, mainSessionId, cbSoHResponse, pbSoHResponse, idleTimeout, sessionTimeout, sessionTimeoutAction, trustClass, policyAttributes);
}

[CRepr]struct ITSGAuthorizeResourceSink : IUnknown
{
	public new const Guid IID = .(0xfeddfcd4, 0xfa12, 0x4435, 0xae, 0x55, 0x7a, 0xd1, 0xa9, 0x77, 0x9a, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrIn, Guid mainSessionId, int32 subSessionId, BSTR* allowedResourceNames, uint32 numAllowedResourceNames, BSTR* failedResourceNames, uint32 numFailedResourceNames) OnChannelAuthorized;
	}


	public HRESULT OnChannelAuthorized(HRESULT hrIn, Guid mainSessionId, int32 subSessionId, BSTR* allowedResourceNames, uint32 numAllowedResourceNames, BSTR* failedResourceNames, uint32 numFailedResourceNames) mut => VT.[Friend]OnChannelAuthorized(&this, hrIn, mainSessionId, subSessionId, allowedResourceNames, numAllowedResourceNames, failedResourceNames, numFailedResourceNames);
}

[CRepr]struct ITSGPolicyEngine : IUnknown
{
	public new const Guid IID = .(0x8bc24f08, 0x6223, 0x42f4, 0xa5, 0xb4, 0x8e, 0x37, 0xcd, 0x13, 0x5b, 0xbd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid mainSessionId, BSTR username, AAAuthSchemes authType, BSTR clientMachineIP, BSTR clientMachineName, uint8* sohData, uint32 numSOHBytes, uint8* cookieData, uint32 numCookieBytes, HANDLE_PTR userToken, ITSGAuthorizeConnectionSink* pSink) AuthorizeConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid mainSessionId, int32 subSessionId, BSTR username, BSTR* resourceNames, uint32 numResources, BSTR* alternateResourceNames, uint32 numAlternateResourceName, uint32 portNumber, BSTR operation, uint8* cookie, uint32 numBytesInCookie, ITSGAuthorizeResourceSink* pSink) AuthorizeResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* quarantineEnabled) IsQuarantineEnabled;
	}


	public HRESULT AuthorizeConnection(Guid mainSessionId, BSTR username, AAAuthSchemes authType, BSTR clientMachineIP, BSTR clientMachineName, uint8* sohData, uint32 numSOHBytes, uint8* cookieData, uint32 numCookieBytes, HANDLE_PTR userToken, ITSGAuthorizeConnectionSink* pSink) mut => VT.[Friend]AuthorizeConnection(&this, mainSessionId, username, authType, clientMachineIP, clientMachineName, sohData, numSOHBytes, cookieData, numCookieBytes, userToken, pSink);

	public HRESULT AuthorizeResource(Guid mainSessionId, int32 subSessionId, BSTR username, BSTR* resourceNames, uint32 numResources, BSTR* alternateResourceNames, uint32 numAlternateResourceName, uint32 portNumber, BSTR operation, uint8* cookie, uint32 numBytesInCookie, ITSGAuthorizeResourceSink* pSink) mut => VT.[Friend]AuthorizeResource(&this, mainSessionId, subSessionId, username, resourceNames, numResources, alternateResourceNames, numAlternateResourceName, portNumber, operation, cookie, numBytesInCookie, pSink);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT IsQuarantineEnabled(BOOL* quarantineEnabled) mut => VT.[Friend]IsQuarantineEnabled(&this, quarantineEnabled);
}

[CRepr]struct ITSGAccountingEngine : IUnknown
{
	public new const Guid IID = .(0x4ce2a0c9, 0xe874, 0x4f1a, 0x86, 0xf4, 0x06, 0xbb, 0xb9, 0x11, 0x53, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AAAccountingDataType accountingDataType, AAAccountingData accountingData) DoAccounting;
	}


	public HRESULT DoAccounting(AAAccountingDataType accountingDataType, AAAccountingData accountingData) mut => VT.[Friend]DoAccounting(&this, accountingDataType, accountingData);
}

[CRepr]struct ITSGAuthenticateUserSink : IUnknown
{
	public new const Guid IID = .(0x2c3e2e73, 0xa782, 0x47f9, 0x8d, 0xfb, 0x77, 0xee, 0x1e, 0xd2, 0x7a, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR userName, BSTR userDomain, uint context, HANDLE_PTR userToken) OnUserAuthenticated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint context, HRESULT genericErrorCode, HRESULT specificErrorCode) OnUserAuthenticationFailed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint context) ReauthenticateUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint context) DisconnectUser;
	}


	public HRESULT OnUserAuthenticated(BSTR userName, BSTR userDomain, uint context, HANDLE_PTR userToken) mut => VT.[Friend]OnUserAuthenticated(&this, userName, userDomain, context, userToken);

	public HRESULT OnUserAuthenticationFailed(uint context, HRESULT genericErrorCode, HRESULT specificErrorCode) mut => VT.[Friend]OnUserAuthenticationFailed(&this, context, genericErrorCode, specificErrorCode);

	public HRESULT ReauthenticateUser(uint context) mut => VT.[Friend]ReauthenticateUser(&this, context);

	public HRESULT DisconnectUser(uint context) mut => VT.[Friend]DisconnectUser(&this, context);
}

[CRepr]struct ITSGAuthenticationEngine : IUnknown
{
	public new const Guid IID = .(0x9ee3e5bf, 0x04ab, 0x4691, 0x99, 0x8c, 0xd7, 0xf6, 0x22, 0x32, 0x1a, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid mainSessionId, uint8* cookieData, uint32 numCookieBytes, uint context, ITSGAuthenticateUserSink* pSink) AuthenticateUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid mainSessionId, uint context) CancelAuthentication;
	}


	public HRESULT AuthenticateUser(Guid mainSessionId, uint8* cookieData, uint32 numCookieBytes, uint context, ITSGAuthenticateUserSink* pSink) mut => VT.[Friend]AuthenticateUser(&this, mainSessionId, cookieData, numCookieBytes, context, pSink);

	public HRESULT CancelAuthentication(Guid mainSessionId, uint context) mut => VT.[Friend]CancelAuthentication(&this, mainSessionId, context);
}

[CRepr]struct IWTSSBPlugin : IUnknown
{
	public new const Guid IID = .(0xdc44be78, 0xb18d, 0x4399, 0xb2, 0x10, 0x64, 0x1b, 0xf6, 0x7a, 0x00, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* PluginCapabilities) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTSSBX_NOTIFICATION_TYPE NotificationType, int32 MachineId, WTSSBX_MACHINE_INFO* pMachineInfo) WTSSBX_MachineChangeNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTSSBX_NOTIFICATION_TYPE NotificationType, int32 MachineId, uint32 NumOfSessions, WTSSBX_SESSION_INFO* SessionInfo) WTSSBX_SessionChangeNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR UserName, PWSTR DomainName, PWSTR ApplicationType, PWSTR FarmName, int32* pMachineId) WTSSBX_GetMostSuitableServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Terminated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR UserName, PWSTR DomainName, PWSTR ApplicationType, WTSSBX_IP_ADDRESS* RedirectorInternalIP, uint32* pSessionId, WTSSBX_MACHINE_CONNECT_INFO* pMachineConnectInfo) WTSSBX_GetUserExternalSession;
	}


	public HRESULT Initialize(uint32* PluginCapabilities) mut => VT.[Friend]Initialize(&this, PluginCapabilities);

	public HRESULT WTSSBX_MachineChangeNotification(WTSSBX_NOTIFICATION_TYPE NotificationType, int32 MachineId, WTSSBX_MACHINE_INFO* pMachineInfo) mut => VT.[Friend]WTSSBX_MachineChangeNotification(&this, NotificationType, MachineId, pMachineInfo);

	public HRESULT WTSSBX_SessionChangeNotification(WTSSBX_NOTIFICATION_TYPE NotificationType, int32 MachineId, uint32 NumOfSessions, WTSSBX_SESSION_INFO* SessionInfo) mut => VT.[Friend]WTSSBX_SessionChangeNotification(&this, NotificationType, MachineId, NumOfSessions, SessionInfo);

	public HRESULT WTSSBX_GetMostSuitableServer(PWSTR UserName, PWSTR DomainName, PWSTR ApplicationType, PWSTR FarmName, int32* pMachineId) mut => VT.[Friend]WTSSBX_GetMostSuitableServer(&this, UserName, DomainName, ApplicationType, FarmName, pMachineId);

	public HRESULT Terminated() mut => VT.[Friend]Terminated(&this);

	public HRESULT WTSSBX_GetUserExternalSession(PWSTR UserName, PWSTR DomainName, PWSTR ApplicationType, WTSSBX_IP_ADDRESS* RedirectorInternalIP, uint32* pSessionId, WTSSBX_MACHINE_CONNECT_INFO* pMachineConnectInfo) mut => VT.[Friend]WTSSBX_GetUserExternalSession(&this, UserName, DomainName, ApplicationType, RedirectorInternalIP, pSessionId, pMachineConnectInfo);
}

[CRepr]struct IWorkspaceClientExt : IUnknown
{
	public new const Guid IID = .(0x12b952f4, 0x41ca, 0x4f21, 0xa8, 0x29, 0xa6, 0xd0, 0x7d, 0x9a, 0x16, 0xe5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrWorkspaceId) GetResourceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrWorkspaceDisplayName) GetResourceDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IssueDisconnect;
	}


	public HRESULT GetResourceId(BSTR* bstrWorkspaceId) mut => VT.[Friend]GetResourceId(&this, bstrWorkspaceId);

	public HRESULT GetResourceDisplayName(BSTR* bstrWorkspaceDisplayName) mut => VT.[Friend]GetResourceDisplayName(&this, bstrWorkspaceDisplayName);

	public HRESULT IssueDisconnect() mut => VT.[Friend]IssueDisconnect(&this);
}

[CRepr]struct IWorkspace : IUnknown
{
	public new const Guid IID = .(0xb922bbb8, 0x4c55, 0x4fea, 0x84, 0x96, 0xbe, 0xb0, 0xb4, 0x42, 0x85, 0xe5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** psaWkspNames) GetWorkspaceNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceId, SAFEARRAY* psaParams) StartRemoteApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulProcessId) GetProcessId;
	}


	public HRESULT GetWorkspaceNames(SAFEARRAY** psaWkspNames) mut => VT.[Friend]GetWorkspaceNames(&this, psaWkspNames);

	public HRESULT StartRemoteApplication(BSTR bstrWorkspaceId, SAFEARRAY* psaParams) mut => VT.[Friend]StartRemoteApplication(&this, bstrWorkspaceId, psaParams);

	public HRESULT GetProcessId(uint32* pulProcessId) mut => VT.[Friend]GetProcessId(&this, pulProcessId);
}

[CRepr]struct IWorkspace2 : IWorkspace
{
	public new const Guid IID = .(0x96d8d7cf, 0x783e, 0x4286, 0x83, 0x4c, 0xeb, 0xc0, 0xe9, 0x5f, 0x78, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWorkspace.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceId, BSTR bstrRequestingAppId, BSTR bstrRequestingAppFamilyName, int16 bLaunchIntoImmersiveClient, BSTR bstrImmersiveClientActivationContext, SAFEARRAY* psaParams) StartRemoteApplicationEx;
	}


	public HRESULT StartRemoteApplicationEx(BSTR bstrWorkspaceId, BSTR bstrRequestingAppId, BSTR bstrRequestingAppFamilyName, int16 bLaunchIntoImmersiveClient, BSTR bstrImmersiveClientActivationContext, SAFEARRAY* psaParams) mut => VT.[Friend]StartRemoteApplicationEx(&this, bstrWorkspaceId, bstrRequestingAppId, bstrRequestingAppFamilyName, bLaunchIntoImmersiveClient, bstrImmersiveClientActivationContext, psaParams);
}

[CRepr]struct IWorkspace3 : IWorkspace2
{
	public new const Guid IID = .(0x1becbe4a, 0xd654, 0x423b, 0xaf, 0xeb, 0xbe, 0x8d, 0x53, 0x2c, 0x13, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWorkspace2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrClaimsHint, BSTR bstrUserHint, uint32 claimCookie, uint32 hwndCredUiParent, RECT rectCredUiParent, BSTR* pbstrAccessToken) GetClaimsToken2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAccessToken, uint64 ullAccessTokenExpiration, BSTR bstrRefreshToken) SetClaimsToken;
	}


	public HRESULT GetClaimsToken2(BSTR bstrClaimsHint, BSTR bstrUserHint, uint32 claimCookie, uint32 hwndCredUiParent, RECT rectCredUiParent, BSTR* pbstrAccessToken) mut => VT.[Friend]GetClaimsToken2(&this, bstrClaimsHint, bstrUserHint, claimCookie, hwndCredUiParent, rectCredUiParent, pbstrAccessToken);

	public HRESULT SetClaimsToken(BSTR bstrAccessToken, uint64 ullAccessTokenExpiration, BSTR bstrRefreshToken) mut => VT.[Friend]SetClaimsToken(&this, bstrAccessToken, ullAccessTokenExpiration, bstrRefreshToken);
}

[CRepr]struct IWorkspaceRegistration : IUnknown
{
	public new const Guid IID = .(0xb922bbb8, 0x4c55, 0x4fea, 0x84, 0x96, 0xbe, 0xb0, 0xb4, 0x42, 0x85, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWorkspaceClientExt* pUnk, uint32* pdwCookie) AddResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookieConnection) RemoveResource;
	}


	public HRESULT AddResource(IWorkspaceClientExt* pUnk, uint32* pdwCookie) mut => VT.[Friend]AddResource(&this, pUnk, pdwCookie);

	public HRESULT RemoveResource(uint32 dwCookieConnection) mut => VT.[Friend]RemoveResource(&this, dwCookieConnection);
}

[CRepr]struct IWorkspaceRegistration2 : IWorkspaceRegistration
{
	public new const Guid IID = .(0xcf59f654, 0x39bb, 0x44d8, 0x94, 0xd0, 0x46, 0x35, 0x72, 0x89, 0x57, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWorkspaceRegistration.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWorkspaceClientExt* pUnk, BSTR bstrEventLogUploadAddress, uint32* pdwCookie, Guid correlationId) AddResourceEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookieConnection, Guid correlationId) RemoveResourceEx;
	}


	public HRESULT AddResourceEx(IWorkspaceClientExt* pUnk, BSTR bstrEventLogUploadAddress, uint32* pdwCookie, Guid correlationId) mut => VT.[Friend]AddResourceEx(&this, pUnk, bstrEventLogUploadAddress, pdwCookie, correlationId);

	public HRESULT RemoveResourceEx(uint32 dwCookieConnection, Guid correlationId) mut => VT.[Friend]RemoveResourceEx(&this, dwCookieConnection, correlationId);
}

[CRepr]struct IWorkspaceScriptable : IDispatch
{
	public new const Guid IID = .(0xefea49a2, 0xdda5, 0x429d, 0x8f, 0x42, 0xb2, 0x3b, 0x92, 0xc4, 0xc3, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceId) DisconnectWorkspace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceId, BSTR bstrUserName, BSTR bstrPassword, BSTR bstrWorkspaceParams, int32 lTimeout, int32 lFlags) StartWorkspace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceId, int16 bCountUnauthenticatedCredentials, int16* pbCredExist) IsWorkspaceCredentialSpecified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbSSOEnabled) IsWorkspaceSSOEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceId) ClearWorkspaceCredential;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceId, BSTR bstrUserName) OnAuthenticated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceFriendlyName) DisconnectWorkspaceByFriendlyName;
	}


	public HRESULT DisconnectWorkspace(BSTR bstrWorkspaceId) mut => VT.[Friend]DisconnectWorkspace(&this, bstrWorkspaceId);

	public HRESULT StartWorkspace(BSTR bstrWorkspaceId, BSTR bstrUserName, BSTR bstrPassword, BSTR bstrWorkspaceParams, int32 lTimeout, int32 lFlags) mut => VT.[Friend]StartWorkspace(&this, bstrWorkspaceId, bstrUserName, bstrPassword, bstrWorkspaceParams, lTimeout, lFlags);

	public HRESULT IsWorkspaceCredentialSpecified(BSTR bstrWorkspaceId, int16 bCountUnauthenticatedCredentials, int16* pbCredExist) mut => VT.[Friend]IsWorkspaceCredentialSpecified(&this, bstrWorkspaceId, bCountUnauthenticatedCredentials, pbCredExist);

	public HRESULT IsWorkspaceSSOEnabled(int16* pbSSOEnabled) mut => VT.[Friend]IsWorkspaceSSOEnabled(&this, pbSSOEnabled);

	public HRESULT ClearWorkspaceCredential(BSTR bstrWorkspaceId) mut => VT.[Friend]ClearWorkspaceCredential(&this, bstrWorkspaceId);

	public HRESULT OnAuthenticated(BSTR bstrWorkspaceId, BSTR bstrUserName) mut => VT.[Friend]OnAuthenticated(&this, bstrWorkspaceId, bstrUserName);

	public HRESULT DisconnectWorkspaceByFriendlyName(BSTR bstrWorkspaceFriendlyName) mut => VT.[Friend]DisconnectWorkspaceByFriendlyName(&this, bstrWorkspaceFriendlyName);
}

[CRepr]struct IWorkspaceScriptable2 : IWorkspaceScriptable
{
	public new const Guid IID = .(0xefea49a2, 0xdda5, 0x429d, 0x8f, 0x42, 0xb3, 0x3b, 0xa2, 0xc4, 0xc3, 0x48);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWorkspaceScriptable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceId, BSTR bstrWorkspaceFriendlyName, BSTR bstrRedirectorName, BSTR bstrUserName, BSTR bstrPassword, BSTR bstrAppContainer, BSTR bstrWorkspaceParams, int32 lTimeout, int32 lFlags) StartWorkspaceEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceId, BSTR bstrWorkspaceFriendlyName) ResourceDismissed;
	}


	public HRESULT StartWorkspaceEx(BSTR bstrWorkspaceId, BSTR bstrWorkspaceFriendlyName, BSTR bstrRedirectorName, BSTR bstrUserName, BSTR bstrPassword, BSTR bstrAppContainer, BSTR bstrWorkspaceParams, int32 lTimeout, int32 lFlags) mut => VT.[Friend]StartWorkspaceEx(&this, bstrWorkspaceId, bstrWorkspaceFriendlyName, bstrRedirectorName, bstrUserName, bstrPassword, bstrAppContainer, bstrWorkspaceParams, lTimeout, lFlags);

	public HRESULT ResourceDismissed(BSTR bstrWorkspaceId, BSTR bstrWorkspaceFriendlyName) mut => VT.[Friend]ResourceDismissed(&this, bstrWorkspaceId, bstrWorkspaceFriendlyName);
}

[CRepr]struct IWorkspaceScriptable3 : IWorkspaceScriptable2
{
	public new const Guid IID = .(0x531e6512, 0x2cbf, 0x4bd2, 0x80, 0xa5, 0xd9, 0x0a, 0x71, 0x63, 0x6a, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWorkspaceScriptable2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWorkspaceId, BSTR bstrWorkspaceFriendlyName, BSTR bstrRedirectorName, BSTR bstrUserName, BSTR bstrPassword, BSTR bstrAppContainer, BSTR bstrWorkspaceParams, int32 lTimeout, int32 lFlags, BSTR bstrEventLogUploadAddress, Guid correlationId) StartWorkspaceEx2;
	}


	public HRESULT StartWorkspaceEx2(BSTR bstrWorkspaceId, BSTR bstrWorkspaceFriendlyName, BSTR bstrRedirectorName, BSTR bstrUserName, BSTR bstrPassword, BSTR bstrAppContainer, BSTR bstrWorkspaceParams, int32 lTimeout, int32 lFlags, BSTR bstrEventLogUploadAddress, Guid correlationId) mut => VT.[Friend]StartWorkspaceEx2(&this, bstrWorkspaceId, bstrWorkspaceFriendlyName, bstrRedirectorName, bstrUserName, bstrPassword, bstrAppContainer, bstrWorkspaceParams, lTimeout, lFlags, bstrEventLogUploadAddress, correlationId);
}

[CRepr]struct IWorkspaceReportMessage : IUnknown
{
	public new const Guid IID = .(0xa7c06739, 0x500f, 0x4e8c, 0x99, 0xa8, 0x2b, 0xd6, 0x95, 0x58, 0x99, 0xeb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMessage) RegisterErrorLogMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWkspId, uint32 dwErrorType, BSTR bstrErrorMessageType, uint32 dwErrorCode, int16* pfErrorExist) IsErrorMessageRegistered;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWkspId, uint32 dwErrorType, BSTR bstrErrorMessageType, uint32 dwErrorCode) RegisterErrorEvent;
	}


	public HRESULT RegisterErrorLogMessage(BSTR bstrMessage) mut => VT.[Friend]RegisterErrorLogMessage(&this, bstrMessage);

	public HRESULT IsErrorMessageRegistered(BSTR bstrWkspId, uint32 dwErrorType, BSTR bstrErrorMessageType, uint32 dwErrorCode, int16* pfErrorExist) mut => VT.[Friend]IsErrorMessageRegistered(&this, bstrWkspId, dwErrorType, bstrErrorMessageType, dwErrorCode, pfErrorExist);

	public HRESULT RegisterErrorEvent(BSTR bstrWkspId, uint32 dwErrorType, BSTR bstrErrorMessageType, uint32 dwErrorCode) mut => VT.[Friend]RegisterErrorEvent(&this, bstrWkspId, dwErrorType, bstrErrorMessageType, dwErrorCode);
}

[CRepr]struct _ITSWkspEvents : IDispatch
{
	public new const Guid IID = .(0xb922bbb8, 0x4c55, 0x4fea, 0x84, 0x96, 0xbe, 0xb0, 0xb4, 0x42, 0x85, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct ITsSbPlugin : IUnknown
{
	public new const Guid IID = .(0x48cd7406, 0xcaab, 0x465f, 0xa5, 0xd6, 0xba, 0xa8, 0x63, 0xb9, 0xea, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbProvider* pProvider, ITsSbPluginNotifySink* pNotifySink, ITsSbPluginPropertySet* pPropertySet) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) Terminate;
	}


	public HRESULT Initialize(ITsSbProvider* pProvider, ITsSbPluginNotifySink* pNotifySink, ITsSbPluginPropertySet* pPropertySet) mut => VT.[Friend]Initialize(&this, pProvider, pNotifySink, pPropertySet);

	public HRESULT Terminate(HRESULT hr) mut => VT.[Friend]Terminate(&this, hr);
}

[CRepr]struct ITsSbResourcePlugin : ITsSbPlugin
{
	public new const Guid IID = .(0xea8db42c, 0x98ed, 0x4535, 0xa8, 0x8b, 0x2a, 0x16, 0x4f, 0x35, 0x49, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbPlugin.VTable
	{
	}

}

[CRepr]struct ITsSbServiceNotification : IUnknown
{
	public new const Guid IID = .(0x86cb68ae, 0x86e0, 0x4f57, 0x8a, 0x64, 0xbb, 0x74, 0x06, 0xbc, 0x55, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NotifyServiceFailure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NotifyServiceSuccess;
	}


	public HRESULT NotifyServiceFailure() mut => VT.[Friend]NotifyServiceFailure(&this);

	public HRESULT NotifyServiceSuccess() mut => VT.[Friend]NotifyServiceSuccess(&this);
}

[CRepr]struct ITsSbLoadBalancing : ITsSbPlugin
{
	public new const Guid IID = .(0x24329274, 0x9eb7, 0x11dc, 0xae, 0x98, 0xf2, 0xb4, 0x56, 0xd8, 0x95, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbPlugin.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbClientConnection* pConnection, ITsSbLoadBalancingNotifySink* pLBSink) GetMostSuitableTarget;
	}


	public HRESULT GetMostSuitableTarget(ITsSbClientConnection* pConnection, ITsSbLoadBalancingNotifySink* pLBSink) mut => VT.[Friend]GetMostSuitableTarget(&this, pConnection, pLBSink);
}

[CRepr]struct ITsSbPlacement : ITsSbPlugin
{
	public new const Guid IID = .(0xdaadee5f, 0x6d32, 0x480e, 0x9e, 0x36, 0xdd, 0xab, 0x23, 0x29, 0xf0, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbPlugin.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbClientConnection* pConnection, ITsSbPlacementNotifySink* pPlacementSink) QueryEnvironmentForTarget;
	}


	public HRESULT QueryEnvironmentForTarget(ITsSbClientConnection* pConnection, ITsSbPlacementNotifySink* pPlacementSink) mut => VT.[Friend]QueryEnvironmentForTarget(&this, pConnection, pPlacementSink);
}

[CRepr]struct ITsSbOrchestration : ITsSbPlugin
{
	public new const Guid IID = .(0x64fc1172, 0x9eb7, 0x11dc, 0x8b, 0x00, 0x3a, 0xba, 0x56, 0xd8, 0x95, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbPlugin.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbClientConnection* pConnection, ITsSbOrchestrationNotifySink* pOrchestrationNotifySink) PrepareTargetForConnect;
	}


	public HRESULT PrepareTargetForConnect(ITsSbClientConnection* pConnection, ITsSbOrchestrationNotifySink* pOrchestrationNotifySink) mut => VT.[Friend]PrepareTargetForConnect(&this, pConnection, pOrchestrationNotifySink);
}

[CRepr]struct ITsSbEnvironment : IUnknown
{
	public new const Guid IID = .(0x8c87f7f7, 0xbf51, 0x4a5c, 0x87, 0xbf, 0x8e, 0x94, 0xfb, 0x6e, 0x22, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pVal) get_ServerWeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbEnvironmentPropertySet** ppPropertySet) get_EnvironmentPropertySet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbEnvironmentPropertySet* pVal) put_EnvironmentPropertySet;
	}


	public HRESULT get_Name(BSTR* pVal) mut => VT.[Friend]get_Name(&this, pVal);

	public HRESULT get_ServerWeight(uint32* pVal) mut => VT.[Friend]get_ServerWeight(&this, pVal);

	public HRESULT get_EnvironmentPropertySet(ITsSbEnvironmentPropertySet** ppPropertySet) mut => VT.[Friend]get_EnvironmentPropertySet(&this, ppPropertySet);

	public HRESULT put_EnvironmentPropertySet(ITsSbEnvironmentPropertySet* pVal) mut => VT.[Friend]put_EnvironmentPropertySet(&this, pVal);
}

[CRepr]struct ITsSbLoadBalanceResult : IUnknown
{
	public new const Guid IID = .(0x24fdb7ac, 0xfea6, 0x11dc, 0x96, 0x72, 0x9a, 0x89, 0x56, 0xd8, 0x95, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_TargetName;
	}


	public HRESULT get_TargetName(BSTR* pVal) mut => VT.[Friend]get_TargetName(&this, pVal);
}

[CRepr]struct ITsSbTarget : IUnknown
{
	public new const Guid IID = .(0x16616ecc, 0x272d, 0x411d, 0xb3, 0x24, 0x12, 0x68, 0x93, 0x03, 0x38, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_TargetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Val) put_TargetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_FarmName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Val) put_FarmName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* TargetFqdnName) get_TargetFQDN;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Val) put_TargetFQDN;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* TargetNetbiosName) get_TargetNetbios;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Val) put_TargetNetbios;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TSSD_ConnectionPoint* SOCKADDR, uint32* numAddresses) get_IpAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TSSD_ConnectionPoint* SOCKADDR, uint32 numAddresses) put_IpAddresses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TARGET_STATE* pState) get_TargetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TARGET_STATE State) put_TargetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbTargetPropertySet** ppPropertySet) get_TargetPropertySet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbTargetPropertySet* pVal) put_TargetPropertySet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_EnvironmentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Val) put_EnvironmentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pNumSessions) get_NumSessions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pNumPendingConnections) get_NumPendingConnections;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pTargetLoad) get_TargetLoad;
	}


	public HRESULT get_TargetName(BSTR* pVal) mut => VT.[Friend]get_TargetName(&this, pVal);

	public HRESULT put_TargetName(BSTR Val) mut => VT.[Friend]put_TargetName(&this, Val);

	public HRESULT get_FarmName(BSTR* pVal) mut => VT.[Friend]get_FarmName(&this, pVal);

	public HRESULT put_FarmName(BSTR Val) mut => VT.[Friend]put_FarmName(&this, Val);

	public HRESULT get_TargetFQDN(BSTR* TargetFqdnName) mut => VT.[Friend]get_TargetFQDN(&this, TargetFqdnName);

	public HRESULT put_TargetFQDN(BSTR Val) mut => VT.[Friend]put_TargetFQDN(&this, Val);

	public HRESULT get_TargetNetbios(BSTR* TargetNetbiosName) mut => VT.[Friend]get_TargetNetbios(&this, TargetNetbiosName);

	public HRESULT put_TargetNetbios(BSTR Val) mut => VT.[Friend]put_TargetNetbios(&this, Val);

	public HRESULT get_IpAddresses(TSSD_ConnectionPoint* SOCKADDR, uint32* numAddresses) mut => VT.[Friend]get_IpAddresses(&this, SOCKADDR, numAddresses);

	public HRESULT put_IpAddresses(TSSD_ConnectionPoint* SOCKADDR, uint32 numAddresses) mut => VT.[Friend]put_IpAddresses(&this, SOCKADDR, numAddresses);

	public HRESULT get_TargetState(TARGET_STATE* pState) mut => VT.[Friend]get_TargetState(&this, pState);

	public HRESULT put_TargetState(TARGET_STATE State) mut => VT.[Friend]put_TargetState(&this, State);

	public HRESULT get_TargetPropertySet(ITsSbTargetPropertySet** ppPropertySet) mut => VT.[Friend]get_TargetPropertySet(&this, ppPropertySet);

	public HRESULT put_TargetPropertySet(ITsSbTargetPropertySet* pVal) mut => VT.[Friend]put_TargetPropertySet(&this, pVal);

	public HRESULT get_EnvironmentName(BSTR* pVal) mut => VT.[Friend]get_EnvironmentName(&this, pVal);

	public HRESULT put_EnvironmentName(BSTR Val) mut => VT.[Friend]put_EnvironmentName(&this, Val);

	public HRESULT get_NumSessions(uint32* pNumSessions) mut => VT.[Friend]get_NumSessions(&this, pNumSessions);

	public HRESULT get_NumPendingConnections(uint32* pNumPendingConnections) mut => VT.[Friend]get_NumPendingConnections(&this, pNumPendingConnections);

	public HRESULT get_TargetLoad(uint32* pTargetLoad) mut => VT.[Friend]get_TargetLoad(&this, pTargetLoad);
}

[CRepr]struct ITsSbSession : IUnknown
{
	public new const Guid IID = .(0xd453aac7, 0xb1d8, 0x4c5e, 0xba, 0x34, 0x9a, 0xfb, 0x4c, 0x8c, 0x55, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pVal) get_SessionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* targetName) get_TargetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR targetName) put_TargetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* userName) get_Username;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* domain) get_Domain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TSSESSION_STATE* pState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TSSESSION_STATE State) put_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pTime) get_CreateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME Time) put_CreateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pTime) get_DisconnectTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME Time) put_DisconnectTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* app) get_InitialProgram;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Application) put_InitialProgram;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLIENT_DISPLAY* pClientDisplay) get_ClientDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLIENT_DISPLAY pClientDisplay) put_ClientDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pVal) get_ProtocolType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Val) put_ProtocolType;
	}


	public HRESULT get_SessionId(uint32* pVal) mut => VT.[Friend]get_SessionId(&this, pVal);

	public HRESULT get_TargetName(BSTR* targetName) mut => VT.[Friend]get_TargetName(&this, targetName);

	public HRESULT put_TargetName(BSTR targetName) mut => VT.[Friend]put_TargetName(&this, targetName);

	public HRESULT get_Username(BSTR* userName) mut => VT.[Friend]get_Username(&this, userName);

	public HRESULT get_Domain(BSTR* domain) mut => VT.[Friend]get_Domain(&this, domain);

	public HRESULT get_State(TSSESSION_STATE* pState) mut => VT.[Friend]get_State(&this, pState);

	public HRESULT put_State(TSSESSION_STATE State) mut => VT.[Friend]put_State(&this, State);

	public HRESULT get_CreateTime(FILETIME* pTime) mut => VT.[Friend]get_CreateTime(&this, pTime);

	public HRESULT put_CreateTime(FILETIME Time) mut => VT.[Friend]put_CreateTime(&this, Time);

	public HRESULT get_DisconnectTime(FILETIME* pTime) mut => VT.[Friend]get_DisconnectTime(&this, pTime);

	public HRESULT put_DisconnectTime(FILETIME Time) mut => VT.[Friend]put_DisconnectTime(&this, Time);

	public HRESULT get_InitialProgram(BSTR* app) mut => VT.[Friend]get_InitialProgram(&this, app);

	public HRESULT put_InitialProgram(BSTR Application) mut => VT.[Friend]put_InitialProgram(&this, Application);

	public HRESULT get_ClientDisplay(CLIENT_DISPLAY* pClientDisplay) mut => VT.[Friend]get_ClientDisplay(&this, pClientDisplay);

	public HRESULT put_ClientDisplay(CLIENT_DISPLAY pClientDisplay) mut => VT.[Friend]put_ClientDisplay(&this, pClientDisplay);

	public HRESULT get_ProtocolType(uint32* pVal) mut => VT.[Friend]get_ProtocolType(&this, pVal);

	public HRESULT put_ProtocolType(uint32 Val) mut => VT.[Friend]put_ProtocolType(&this, Val);
}

[CRepr]struct ITsSbResourceNotification : IUnknown
{
	public new const Guid IID = .(0x65d3e85a, 0xc39b, 0x11dc, 0xb9, 0x2d, 0x3c, 0xd2, 0x55, 0xd8, 0x95, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TSSESSION_STATE changeType, ITsSbSession* pSession) NotifySessionChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 TargetChangeType, ITsSbTarget* pTarget) NotifyTargetChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONNECTION_CHANGE_NOTIFICATION ChangeType, ITsSbClientConnection* pConnection) NotifyClientConnectionStateChange;
	}


	public HRESULT NotifySessionChange(TSSESSION_STATE changeType, ITsSbSession* pSession) mut => VT.[Friend]NotifySessionChange(&this, changeType, pSession);

	public HRESULT NotifyTargetChange(uint32 TargetChangeType, ITsSbTarget* pTarget) mut => VT.[Friend]NotifyTargetChange(&this, TargetChangeType, pTarget);

	public HRESULT NotifyClientConnectionStateChange(CONNECTION_CHANGE_NOTIFICATION ChangeType, ITsSbClientConnection* pConnection) mut => VT.[Friend]NotifyClientConnectionStateChange(&this, ChangeType, pConnection);
}

[CRepr]struct ITsSbResourceNotificationEx : IUnknown
{
	public new const Guid IID = .(0xa8a47fde, 0xca91, 0x44d2, 0xb8, 0x97, 0x3a, 0xa2, 0x8a, 0x43, 0xb2, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR targetName, BSTR userName, BSTR domain, uint32 sessionId, TSSESSION_STATE sessionState) NotifySessionChangeEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR targetName, uint32 targetChangeType) NotifyTargetChangeEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR userName, BSTR domain, BSTR initialProgram, BSTR poolName, BSTR targetName, CONNECTION_CHANGE_NOTIFICATION connectionChangeType) NotifyClientConnectionStateChangeEx;
	}


	public HRESULT NotifySessionChangeEx(BSTR targetName, BSTR userName, BSTR domain, uint32 sessionId, TSSESSION_STATE sessionState) mut => VT.[Friend]NotifySessionChangeEx(&this, targetName, userName, domain, sessionId, sessionState);

	public HRESULT NotifyTargetChangeEx(BSTR targetName, uint32 targetChangeType) mut => VT.[Friend]NotifyTargetChangeEx(&this, targetName, targetChangeType);

	public HRESULT NotifyClientConnectionStateChangeEx(BSTR userName, BSTR domain, BSTR initialProgram, BSTR poolName, BSTR targetName, CONNECTION_CHANGE_NOTIFICATION connectionChangeType) mut => VT.[Friend]NotifyClientConnectionStateChangeEx(&this, userName, domain, initialProgram, poolName, targetName, connectionChangeType);
}

[CRepr]struct ITsSbTaskInfo : IUnknown
{
	public new const Guid IID = .(0x523d1083, 0x89be, 0x48dd, 0x99, 0xea, 0x04, 0xe8, 0x2f, 0xfa, 0x72, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pName) get_TargetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pStartTime) get_StartTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pEndTime) get_EndTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pDeadline) get_Deadline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pIdentifier) get_Identifier;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pLabel) get_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY** pContext) get_Context;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pPlugin) get_Plugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RDV_TASK_STATUS* pStatus) get_Status;
	}


	public HRESULT get_TargetId(BSTR* pName) mut => VT.[Friend]get_TargetId(&this, pName);

	public HRESULT get_StartTime(FILETIME* pStartTime) mut => VT.[Friend]get_StartTime(&this, pStartTime);

	public HRESULT get_EndTime(FILETIME* pEndTime) mut => VT.[Friend]get_EndTime(&this, pEndTime);

	public HRESULT get_Deadline(FILETIME* pDeadline) mut => VT.[Friend]get_Deadline(&this, pDeadline);

	public HRESULT get_Identifier(BSTR* pIdentifier) mut => VT.[Friend]get_Identifier(&this, pIdentifier);

	public HRESULT get_Label(BSTR* pLabel) mut => VT.[Friend]get_Label(&this, pLabel);

	public HRESULT get_Context(SAFEARRAY** pContext) mut => VT.[Friend]get_Context(&this, pContext);

	public HRESULT get_Plugin(BSTR* pPlugin) mut => VT.[Friend]get_Plugin(&this, pPlugin);

	public HRESULT get_Status(RDV_TASK_STATUS* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);
}

[CRepr]struct ITsSbTaskPlugin : ITsSbPlugin
{
	public new const Guid IID = .(0xfa22ef0f, 0x8705, 0x41be, 0x93, 0xbc, 0x44, 0xbd, 0xbc, 0xf1, 0xc9, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbPlugin.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbTaskPluginNotifySink* pITsSbTaskPluginNotifySink) InitializeTaskPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pszHostName, uint32 SbTaskInfoSize, ITsSbTaskInfo** pITsSbTaskInfo) SetTaskQueue;
	}


	public HRESULT InitializeTaskPlugin(ITsSbTaskPluginNotifySink* pITsSbTaskPluginNotifySink) mut => VT.[Friend]InitializeTaskPlugin(&this, pITsSbTaskPluginNotifySink);

	public HRESULT SetTaskQueue(BSTR pszHostName, uint32 SbTaskInfoSize, ITsSbTaskInfo** pITsSbTaskInfo) mut => VT.[Friend]SetTaskQueue(&this, pszHostName, SbTaskInfoSize, pITsSbTaskInfo);
}

[CRepr]struct ITsSbPropertySet : IPropertyBag
{
	public new const Guid IID = .(0x5c025171, 0xbb1e, 0x4baf, 0xa2, 0x12, 0x6d, 0x5e, 0x97, 0x74, 0xb3, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPropertyBag.VTable
	{
	}

}

[CRepr]struct ITsSbPluginPropertySet : ITsSbPropertySet
{
	public new const Guid IID = .(0x95006e34, 0x7eff, 0x4b6c, 0xbb, 0x40, 0x49, 0xa4, 0xfd, 0xa7, 0xce, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbPropertySet.VTable
	{
	}

}

[CRepr]struct ITsSbClientConnectionPropertySet : ITsSbPropertySet
{
	public new const Guid IID = .(0xe51995b0, 0x46d6, 0x11dd, 0xaa, 0x21, 0xce, 0xdc, 0x55, 0xd8, 0x95, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbPropertySet.VTable
	{
	}

}

[CRepr]struct ITsSbTargetPropertySet : ITsSbPropertySet
{
	public new const Guid IID = .(0xf7bda5d6, 0x994c, 0x4e11, 0xa0, 0x79, 0x27, 0x63, 0xb6, 0x18, 0x30, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbPropertySet.VTable
	{
	}

}

[CRepr]struct ITsSbEnvironmentPropertySet : ITsSbPropertySet
{
	public new const Guid IID = .(0xd0d1bf7e, 0x7acf, 0x11dd, 0xa2, 0x43, 0xe5, 0x11, 0x56, 0xd8, 0x95, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbPropertySet.VTable
	{
	}

}

[CRepr]struct ITsSbBaseNotifySink : IUnknown
{
	public new const Guid IID = .(0x808a6537, 0x1282, 0x4989, 0x9e, 0x09, 0xf4, 0x39, 0x38, 0xb7, 0x17, 0x22);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrError) OnError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLIENT_MESSAGE_TYPE messageType, uint32 messageID) OnReportStatus;
	}


	public HRESULT OnError(HRESULT hrError) mut => VT.[Friend]OnError(&this, hrError);

	public HRESULT OnReportStatus(CLIENT_MESSAGE_TYPE messageType, uint32 messageID) mut => VT.[Friend]OnReportStatus(&this, messageType, messageID);
}

[CRepr]struct ITsSbPluginNotifySink : ITsSbBaseNotifySink
{
	public new const Guid IID = .(0x44dfe30b, 0xc3be, 0x40f5, 0xbf, 0x82, 0x7a, 0x95, 0xbb, 0x79, 0x5a, 0xdf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbBaseNotifySink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) OnInitialized;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnTerminated;
	}


	public HRESULT OnInitialized(HRESULT hr) mut => VT.[Friend]OnInitialized(&this, hr);

	public HRESULT OnTerminated() mut => VT.[Friend]OnTerminated(&this);
}

[CRepr]struct ITsSbLoadBalancingNotifySink : ITsSbBaseNotifySink
{
	public new const Guid IID = .(0x5f8a8297, 0x3244, 0x4e6a, 0x95, 0x8a, 0x27, 0xc8, 0x22, 0xc1, 0xe1, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbBaseNotifySink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbLoadBalanceResult* pLBResult, BOOL fIsNewConnection) OnGetMostSuitableTarget;
	}


	public HRESULT OnGetMostSuitableTarget(ITsSbLoadBalanceResult* pLBResult, BOOL fIsNewConnection) mut => VT.[Friend]OnGetMostSuitableTarget(&this, pLBResult, fIsNewConnection);
}

[CRepr]struct ITsSbPlacementNotifySink : ITsSbBaseNotifySink
{
	public new const Guid IID = .(0x68a0c487, 0x2b4f, 0x46c2, 0x94, 0xa1, 0x6c, 0xe6, 0x85, 0x18, 0x36, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbBaseNotifySink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbEnvironment* pEnvironment) OnQueryEnvironmentCompleted;
	}


	public HRESULT OnQueryEnvironmentCompleted(ITsSbEnvironment* pEnvironment) mut => VT.[Friend]OnQueryEnvironmentCompleted(&this, pEnvironment);
}

[CRepr]struct ITsSbOrchestrationNotifySink : ITsSbBaseNotifySink
{
	public new const Guid IID = .(0x36c37d61, 0x926b, 0x442f, 0xbc, 0xa5, 0x11, 0x8c, 0x6d, 0x50, 0xdc, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbBaseNotifySink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbTarget* pTarget) OnReadyToConnect;
	}


	public HRESULT OnReadyToConnect(ITsSbTarget* pTarget) mut => VT.[Friend]OnReadyToConnect(&this, pTarget);
}

[CRepr]struct ITsSbTaskPluginNotifySink : ITsSbBaseNotifySink
{
	public new const Guid IID = .(0x6aaf899e, 0xc2ec, 0x45ee, 0xaa, 0x37, 0x45, 0xe6, 0x08, 0x95, 0x26, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbBaseNotifySink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR szTargetName, FILETIME TaskStartTime, FILETIME TaskEndTime, FILETIME TaskDeadline, BSTR szTaskLabel, BSTR szTaskIdentifier, BSTR szTaskPlugin, uint32 dwTaskStatus, SAFEARRAY* saContext) OnSetTaskTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR szTargetName, BSTR szTaskIdentifier) OnDeleteTaskTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR szTargetName, BSTR TaskIdentifier, RDV_TASK_STATUS TaskStatus) OnUpdateTaskStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR szHostName) OnReportTasks;
	}


	public HRESULT OnSetTaskTime(BSTR szTargetName, FILETIME TaskStartTime, FILETIME TaskEndTime, FILETIME TaskDeadline, BSTR szTaskLabel, BSTR szTaskIdentifier, BSTR szTaskPlugin, uint32 dwTaskStatus, SAFEARRAY* saContext) mut => VT.[Friend]OnSetTaskTime(&this, szTargetName, TaskStartTime, TaskEndTime, TaskDeadline, szTaskLabel, szTaskIdentifier, szTaskPlugin, dwTaskStatus, saContext);

	public HRESULT OnDeleteTaskTime(BSTR szTargetName, BSTR szTaskIdentifier) mut => VT.[Friend]OnDeleteTaskTime(&this, szTargetName, szTaskIdentifier);

	public HRESULT OnUpdateTaskStatus(BSTR szTargetName, BSTR TaskIdentifier, RDV_TASK_STATUS TaskStatus) mut => VT.[Friend]OnUpdateTaskStatus(&this, szTargetName, TaskIdentifier, TaskStatus);

	public HRESULT OnReportTasks(BSTR szHostName) mut => VT.[Friend]OnReportTasks(&this, szHostName);
}

[CRepr]struct ITsSbClientConnection : IUnknown
{
	public new const Guid IID = .(0x18857499, 0xad61, 0x4b1b, 0xb7, 0xdf, 0xcb, 0xcd, 0x41, 0xfb, 0x83, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_UserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Domain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_InitialProgram;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbLoadBalanceResult** ppVal) get_LoadBalanceResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_FarmName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR contextId, VARIANT context, VARIANT* existingContext) PutContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR contextId, VARIANT* context) GetContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbEnvironment** ppEnvironment) get_Environment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) get_ConnectionError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_SamUserAccount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbClientConnectionPropertySet** ppPropertySet) get_ClientConnectionPropertySet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* ppVal) get_IsFirstAssignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RD_FARM_TYPE* pRdFarmType) get_RdFarmType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int8** pszUserSidString) get_UserSidString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbSession** ppSession) GetDisconnectedSession;
	}


	public HRESULT get_UserName(BSTR* pVal) mut => VT.[Friend]get_UserName(&this, pVal);

	public HRESULT get_Domain(BSTR* pVal) mut => VT.[Friend]get_Domain(&this, pVal);

	public HRESULT get_InitialProgram(BSTR* pVal) mut => VT.[Friend]get_InitialProgram(&this, pVal);

	public HRESULT get_LoadBalanceResult(ITsSbLoadBalanceResult** ppVal) mut => VT.[Friend]get_LoadBalanceResult(&this, ppVal);

	public HRESULT get_FarmName(BSTR* pVal) mut => VT.[Friend]get_FarmName(&this, pVal);

	public HRESULT PutContext(BSTR contextId, VARIANT context, VARIANT* existingContext) mut => VT.[Friend]PutContext(&this, contextId, context, existingContext);

	public HRESULT GetContext(BSTR contextId, VARIANT* context) mut => VT.[Friend]GetContext(&this, contextId, context);

	public HRESULT get_Environment(ITsSbEnvironment** ppEnvironment) mut => VT.[Friend]get_Environment(&this, ppEnvironment);

	public HRESULT get_ConnectionError() mut => VT.[Friend]get_ConnectionError(&this);

	public HRESULT get_SamUserAccount(BSTR* pVal) mut => VT.[Friend]get_SamUserAccount(&this, pVal);

	public HRESULT get_ClientConnectionPropertySet(ITsSbClientConnectionPropertySet** ppPropertySet) mut => VT.[Friend]get_ClientConnectionPropertySet(&this, ppPropertySet);

	public HRESULT get_IsFirstAssignment(BOOL* ppVal) mut => VT.[Friend]get_IsFirstAssignment(&this, ppVal);

	public HRESULT get_RdFarmType(RD_FARM_TYPE* pRdFarmType) mut => VT.[Friend]get_RdFarmType(&this, pRdFarmType);

	public HRESULT get_UserSidString(int8** pszUserSidString) mut => VT.[Friend]get_UserSidString(&this, pszUserSidString);

	public HRESULT GetDisconnectedSession(ITsSbSession** ppSession) mut => VT.[Friend]GetDisconnectedSession(&this, ppSession);
}

[CRepr]struct ITsSbProvider : IUnknown
{
	public new const Guid IID = .(0x87a4098f, 0x6d7b, 0x44dd, 0xbc, 0x17, 0x8c, 0xe4, 0x4e, 0x37, 0x0d, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR TargetName, BSTR EnvironmentName, ITsSbTarget** ppTarget) CreateTargetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR TargetName, ITsSbLoadBalanceResult** ppLBResult) CreateLoadBalanceResultObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR TargetName, BSTR UserName, BSTR Domain, uint32 SessionId, ITsSbSession** ppSession) CreateSessionObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbPluginPropertySet** ppPropertySet) CreatePluginPropertySet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbTargetPropertySet** ppPropertySet) CreateTargetPropertySetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, uint32 ServerWeight, ITsSbEnvironment** ppEnvironment) CreateEnvironmentObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbResourcePluginStore** ppStore) GetResourcePluginStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbFilterPluginStore** ppStore) GetFilterPluginStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 notificationType, BSTR ResourceToMonitor, ITsSbResourceNotification* pPluginNotification) RegisterForNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 notificationType, BSTR ResourceToMonitor) UnRegisterForNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbGlobalStore** ppGlobalStore) GetInstanceOfGlobalStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbEnvironmentPropertySet** ppPropertySet) CreateEnvironmentPropertySetObject;
	}


	public HRESULT CreateTargetObject(BSTR TargetName, BSTR EnvironmentName, ITsSbTarget** ppTarget) mut => VT.[Friend]CreateTargetObject(&this, TargetName, EnvironmentName, ppTarget);

	public HRESULT CreateLoadBalanceResultObject(BSTR TargetName, ITsSbLoadBalanceResult** ppLBResult) mut => VT.[Friend]CreateLoadBalanceResultObject(&this, TargetName, ppLBResult);

	public HRESULT CreateSessionObject(BSTR TargetName, BSTR UserName, BSTR Domain, uint32 SessionId, ITsSbSession** ppSession) mut => VT.[Friend]CreateSessionObject(&this, TargetName, UserName, Domain, SessionId, ppSession);

	public HRESULT CreatePluginPropertySet(ITsSbPluginPropertySet** ppPropertySet) mut => VT.[Friend]CreatePluginPropertySet(&this, ppPropertySet);

	public HRESULT CreateTargetPropertySetObject(ITsSbTargetPropertySet** ppPropertySet) mut => VT.[Friend]CreateTargetPropertySetObject(&this, ppPropertySet);

	public HRESULT CreateEnvironmentObject(BSTR Name, uint32 ServerWeight, ITsSbEnvironment** ppEnvironment) mut => VT.[Friend]CreateEnvironmentObject(&this, Name, ServerWeight, ppEnvironment);

	public HRESULT GetResourcePluginStore(ITsSbResourcePluginStore** ppStore) mut => VT.[Friend]GetResourcePluginStore(&this, ppStore);

	public HRESULT GetFilterPluginStore(ITsSbFilterPluginStore** ppStore) mut => VT.[Friend]GetFilterPluginStore(&this, ppStore);

	public HRESULT RegisterForNotification(uint32 notificationType, BSTR ResourceToMonitor, ITsSbResourceNotification* pPluginNotification) mut => VT.[Friend]RegisterForNotification(&this, notificationType, ResourceToMonitor, pPluginNotification);

	public HRESULT UnRegisterForNotification(uint32 notificationType, BSTR ResourceToMonitor) mut => VT.[Friend]UnRegisterForNotification(&this, notificationType, ResourceToMonitor);

	public HRESULT GetInstanceOfGlobalStore(ITsSbGlobalStore** ppGlobalStore) mut => VT.[Friend]GetInstanceOfGlobalStore(&this, ppGlobalStore);

	public HRESULT CreateEnvironmentPropertySetObject(ITsSbEnvironmentPropertySet** ppPropertySet) mut => VT.[Friend]CreateEnvironmentPropertySetObject(&this, ppPropertySet);
}

[CRepr]struct ITsSbResourcePluginStore : IUnknown
{
	public new const Guid IID = .(0x5c38f65f, 0xbcf1, 0x4036, 0xa6, 0xbf, 0x9e, 0x3c, 0xcc, 0xae, 0x0b, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR TargetName, BSTR FarmName, ITsSbTarget** ppTarget) QueryTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSessionId, BSTR TargetName, ITsSbSession** ppSession) QuerySessionBySessionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbTarget* pTarget) AddTargetToStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbSession* pSession) AddSessionToStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbEnvironment* pEnvironment) AddEnvironmentToStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR EnvironmentName, BOOL bIgnoreOwner) RemoveEnvironmentFromStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount, SAFEARRAY** pVal) EnumerateFarms;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR EnvironmentName, ITsSbEnvironment** ppEnvironment) QueryEnvironment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount, ITsSbEnvironment*** pVal) EnumerateEnvironments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbTarget* pTarget, BOOL bForceWrite) SaveTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbEnvironment* pEnvironment, BOOL bForceWrite) SaveEnvironment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbSession* pSession) SaveSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR TargetName, BSTR PropertyName, VARIANT* pProperty) SetTargetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR EnvironmentName, BSTR PropertyName, VARIANT* pProperty) SetEnvironmentProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR targetName, TARGET_STATE newState, TARGET_STATE* pOldState) SetTargetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbSession* sbSession) SetSessionState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR FarmName, BSTR EnvName, TS_SB_SORT_BY sortByFieldId, BSTR sortyByPropName, uint32* pdwCount, ITsSbTarget*** pVal) EnumerateTargets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR targetName, BSTR userName, BSTR userDomain, BSTR poolName, BSTR initialProgram, TSSESSION_STATE* pSessionState, uint32* pdwCount, ITsSbSession*** ppVal) EnumerateSessions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR farmName, BSTR propertyName, VARIANT* pVarValue) GetFarmProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR targetName, BSTR hostName) DeleteTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbTarget* pTarget, BSTR PropertyName, VARIANT* pProperty) SetTargetPropertyWithVersionCheck;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbEnvironment* pEnvironment, BSTR PropertyName, VARIANT* pProperty) SetEnvironmentPropertyWithVersionCheck;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR targetName, uint32 dwTimeout, IUnknown** ppContext) AcquireTargetLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pContext) ReleaseTargetLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PoolName, BSTR ServerFQDN, TARGET_STATE NewState, TARGET_STATE TestState, TARGET_STATE* pInitState) TestAndSetServerState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PoolName, BSTR serverName) SetServerWaitingToStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PoolName, BSTR ServerFQDN, TARGET_STATE* pState) GetServerState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ServerFQDN, uint32 DrainMode) SetServerDrainMode;
	}


	public HRESULT QueryTarget(BSTR TargetName, BSTR FarmName, ITsSbTarget** ppTarget) mut => VT.[Friend]QueryTarget(&this, TargetName, FarmName, ppTarget);

	public HRESULT QuerySessionBySessionId(uint32 dwSessionId, BSTR TargetName, ITsSbSession** ppSession) mut => VT.[Friend]QuerySessionBySessionId(&this, dwSessionId, TargetName, ppSession);

	public HRESULT AddTargetToStore(ITsSbTarget* pTarget) mut => VT.[Friend]AddTargetToStore(&this, pTarget);

	public HRESULT AddSessionToStore(ITsSbSession* pSession) mut => VT.[Friend]AddSessionToStore(&this, pSession);

	public HRESULT AddEnvironmentToStore(ITsSbEnvironment* pEnvironment) mut => VT.[Friend]AddEnvironmentToStore(&this, pEnvironment);

	public HRESULT RemoveEnvironmentFromStore(BSTR EnvironmentName, BOOL bIgnoreOwner) mut => VT.[Friend]RemoveEnvironmentFromStore(&this, EnvironmentName, bIgnoreOwner);

	public HRESULT EnumerateFarms(uint32* pdwCount, SAFEARRAY** pVal) mut => VT.[Friend]EnumerateFarms(&this, pdwCount, pVal);

	public HRESULT QueryEnvironment(BSTR EnvironmentName, ITsSbEnvironment** ppEnvironment) mut => VT.[Friend]QueryEnvironment(&this, EnvironmentName, ppEnvironment);

	public HRESULT EnumerateEnvironments(uint32* pdwCount, ITsSbEnvironment*** pVal) mut => VT.[Friend]EnumerateEnvironments(&this, pdwCount, pVal);

	public HRESULT SaveTarget(ITsSbTarget* pTarget, BOOL bForceWrite) mut => VT.[Friend]SaveTarget(&this, pTarget, bForceWrite);

	public HRESULT SaveEnvironment(ITsSbEnvironment* pEnvironment, BOOL bForceWrite) mut => VT.[Friend]SaveEnvironment(&this, pEnvironment, bForceWrite);

	public HRESULT SaveSession(ITsSbSession* pSession) mut => VT.[Friend]SaveSession(&this, pSession);

	public HRESULT SetTargetProperty(BSTR TargetName, BSTR PropertyName, VARIANT* pProperty) mut => VT.[Friend]SetTargetProperty(&this, TargetName, PropertyName, pProperty);

	public HRESULT SetEnvironmentProperty(BSTR EnvironmentName, BSTR PropertyName, VARIANT* pProperty) mut => VT.[Friend]SetEnvironmentProperty(&this, EnvironmentName, PropertyName, pProperty);

	public HRESULT SetTargetState(BSTR targetName, TARGET_STATE newState, TARGET_STATE* pOldState) mut => VT.[Friend]SetTargetState(&this, targetName, newState, pOldState);

	public HRESULT SetSessionState(ITsSbSession* sbSession) mut => VT.[Friend]SetSessionState(&this, sbSession);

	public HRESULT EnumerateTargets(BSTR FarmName, BSTR EnvName, TS_SB_SORT_BY sortByFieldId, BSTR sortyByPropName, uint32* pdwCount, ITsSbTarget*** pVal) mut => VT.[Friend]EnumerateTargets(&this, FarmName, EnvName, sortByFieldId, sortyByPropName, pdwCount, pVal);

	public HRESULT EnumerateSessions(BSTR targetName, BSTR userName, BSTR userDomain, BSTR poolName, BSTR initialProgram, TSSESSION_STATE* pSessionState, uint32* pdwCount, ITsSbSession*** ppVal) mut => VT.[Friend]EnumerateSessions(&this, targetName, userName, userDomain, poolName, initialProgram, pSessionState, pdwCount, ppVal);

	public HRESULT GetFarmProperty(BSTR farmName, BSTR propertyName, VARIANT* pVarValue) mut => VT.[Friend]GetFarmProperty(&this, farmName, propertyName, pVarValue);

	public HRESULT DeleteTarget(BSTR targetName, BSTR hostName) mut => VT.[Friend]DeleteTarget(&this, targetName, hostName);

	public HRESULT SetTargetPropertyWithVersionCheck(ITsSbTarget* pTarget, BSTR PropertyName, VARIANT* pProperty) mut => VT.[Friend]SetTargetPropertyWithVersionCheck(&this, pTarget, PropertyName, pProperty);

	public HRESULT SetEnvironmentPropertyWithVersionCheck(ITsSbEnvironment* pEnvironment, BSTR PropertyName, VARIANT* pProperty) mut => VT.[Friend]SetEnvironmentPropertyWithVersionCheck(&this, pEnvironment, PropertyName, pProperty);

	public HRESULT AcquireTargetLock(BSTR targetName, uint32 dwTimeout, IUnknown** ppContext) mut => VT.[Friend]AcquireTargetLock(&this, targetName, dwTimeout, ppContext);

	public HRESULT ReleaseTargetLock(IUnknown* pContext) mut => VT.[Friend]ReleaseTargetLock(&this, pContext);

	public HRESULT TestAndSetServerState(BSTR PoolName, BSTR ServerFQDN, TARGET_STATE NewState, TARGET_STATE TestState, TARGET_STATE* pInitState) mut => VT.[Friend]TestAndSetServerState(&this, PoolName, ServerFQDN, NewState, TestState, pInitState);

	public HRESULT SetServerWaitingToStart(BSTR PoolName, BSTR serverName) mut => VT.[Friend]SetServerWaitingToStart(&this, PoolName, serverName);

	public HRESULT GetServerState(BSTR PoolName, BSTR ServerFQDN, TARGET_STATE* pState) mut => VT.[Friend]GetServerState(&this, PoolName, ServerFQDN, pState);

	public HRESULT SetServerDrainMode(BSTR ServerFQDN, uint32 DrainMode) mut => VT.[Friend]SetServerDrainMode(&this, ServerFQDN, DrainMode);
}

[CRepr]struct ITsSbFilterPluginStore : IUnknown
{
	public new const Guid IID = .(0x85b44b0f, 0xed78, 0x413f, 0x97, 0x02, 0xfa, 0x6d, 0x3b, 0x5e, 0xe7, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbPropertySet* pPropertySet) SaveProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITsSbPropertySet** ppPropertySet) EnumerateProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR propertyName) DeleteProperties;
	}


	public HRESULT SaveProperties(ITsSbPropertySet* pPropertySet) mut => VT.[Friend]SaveProperties(&this, pPropertySet);

	public HRESULT EnumerateProperties(ITsSbPropertySet** ppPropertySet) mut => VT.[Friend]EnumerateProperties(&this, ppPropertySet);

	public HRESULT DeleteProperties(BSTR propertyName) mut => VT.[Friend]DeleteProperties(&this, propertyName);
}

[CRepr]struct ITsSbGlobalStore : IUnknown
{
	public new const Guid IID = .(0x9ab60f7b, 0xbd72, 0x4d9f, 0x8a, 0x3a, 0xa0, 0xea, 0x55, 0x74, 0xe6, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ProviderName, BSTR TargetName, BSTR FarmName, ITsSbTarget** ppTarget) QueryTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ProviderName, uint32 dwSessionId, BSTR TargetName, ITsSbSession** ppSession) QuerySessionBySessionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ProviderName, uint32* pdwCount, SAFEARRAY** pVal) EnumerateFarms;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ProviderName, BSTR FarmName, BSTR EnvName, uint32* pdwCount, ITsSbTarget*** pVal) EnumerateTargets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ProviderName, uint32* pdwCount, ITsSbEnvironment*** ppVal) EnumerateEnvironmentsByProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ProviderName, BSTR targetName, BSTR userName, BSTR userDomain, BSTR poolName, BSTR initialProgram, TSSESSION_STATE* pSessionState, uint32* pdwCount, ITsSbSession*** ppVal) EnumerateSessions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR farmName, BSTR propertyName, VARIANT* pVarValue) GetFarmProperty;
	}


	public HRESULT QueryTarget(BSTR ProviderName, BSTR TargetName, BSTR FarmName, ITsSbTarget** ppTarget) mut => VT.[Friend]QueryTarget(&this, ProviderName, TargetName, FarmName, ppTarget);

	public HRESULT QuerySessionBySessionId(BSTR ProviderName, uint32 dwSessionId, BSTR TargetName, ITsSbSession** ppSession) mut => VT.[Friend]QuerySessionBySessionId(&this, ProviderName, dwSessionId, TargetName, ppSession);

	public HRESULT EnumerateFarms(BSTR ProviderName, uint32* pdwCount, SAFEARRAY** pVal) mut => VT.[Friend]EnumerateFarms(&this, ProviderName, pdwCount, pVal);

	public HRESULT EnumerateTargets(BSTR ProviderName, BSTR FarmName, BSTR EnvName, uint32* pdwCount, ITsSbTarget*** pVal) mut => VT.[Friend]EnumerateTargets(&this, ProviderName, FarmName, EnvName, pdwCount, pVal);

	public HRESULT EnumerateEnvironmentsByProvider(BSTR ProviderName, uint32* pdwCount, ITsSbEnvironment*** ppVal) mut => VT.[Friend]EnumerateEnvironmentsByProvider(&this, ProviderName, pdwCount, ppVal);

	public HRESULT EnumerateSessions(BSTR ProviderName, BSTR targetName, BSTR userName, BSTR userDomain, BSTR poolName, BSTR initialProgram, TSSESSION_STATE* pSessionState, uint32* pdwCount, ITsSbSession*** ppVal) mut => VT.[Friend]EnumerateSessions(&this, ProviderName, targetName, userName, userDomain, poolName, initialProgram, pSessionState, pdwCount, ppVal);

	public HRESULT GetFarmProperty(BSTR farmName, BSTR propertyName, VARIANT* pVarValue) mut => VT.[Friend]GetFarmProperty(&this, farmName, propertyName, pVarValue);
}

[CRepr]struct ITsSbProvisioningPluginNotifySink : IUnknown
{
	public new const Guid IID = .(0xaca87a8e, 0x818b, 0x4581, 0xa0, 0x32, 0x49, 0xc3, 0xdf, 0xb9, 0xc7, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VM_NOTIFY_INFO* pVmNotifyInfo) OnJobCreated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VM_NOTIFY_ENTRY* pVmNotifyEntry, VM_NOTIFY_STATUS VmNotifyStatus, HRESULT ErrorCode, BSTR ErrorDescr) OnVirtualMachineStatusChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT ResultCode, BSTR ResultDescription) OnJobCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnJobCancelled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VM_NOTIFY_ENTRY* pVmNotifyEntry) LockVirtualMachine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR VmHost, VM_HOST_NOTIFY_STATUS VmHostNotifyStatus, HRESULT ErrorCode, BSTR ErrorDescr) OnVirtualMachineHostStatusChanged;
	}


	public HRESULT OnJobCreated(VM_NOTIFY_INFO* pVmNotifyInfo) mut => VT.[Friend]OnJobCreated(&this, pVmNotifyInfo);

	public HRESULT OnVirtualMachineStatusChanged(VM_NOTIFY_ENTRY* pVmNotifyEntry, VM_NOTIFY_STATUS VmNotifyStatus, HRESULT ErrorCode, BSTR ErrorDescr) mut => VT.[Friend]OnVirtualMachineStatusChanged(&this, pVmNotifyEntry, VmNotifyStatus, ErrorCode, ErrorDescr);

	public HRESULT OnJobCompleted(HRESULT ResultCode, BSTR ResultDescription) mut => VT.[Friend]OnJobCompleted(&this, ResultCode, ResultDescription);

	public HRESULT OnJobCancelled() mut => VT.[Friend]OnJobCancelled(&this);

	public HRESULT LockVirtualMachine(VM_NOTIFY_ENTRY* pVmNotifyEntry) mut => VT.[Friend]LockVirtualMachine(&this, pVmNotifyEntry);

	public HRESULT OnVirtualMachineHostStatusChanged(BSTR VmHost, VM_HOST_NOTIFY_STATUS VmHostNotifyStatus, HRESULT ErrorCode, BSTR ErrorDescr) mut => VT.[Friend]OnVirtualMachineHostStatusChanged(&this, VmHost, VmHostNotifyStatus, ErrorCode, ErrorDescr);
}

[CRepr]struct ITsSbProvisioning : ITsSbPlugin
{
	public new const Guid IID = .(0x2f6f0dbb, 0x9e4f, 0x462b, 0x9c, 0x3f, 0xfc, 0xcc, 0x3d, 0xcb, 0x62, 0x32);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITsSbPlugin.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR JobXmlString, BSTR JobGuid, ITsSbProvisioningPluginNotifySink* pSink) CreateVirtualMachines;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR JobXmlString, BSTR JobGuid, ITsSbProvisioningPluginNotifySink* pSink, VM_PATCH_INFO* pVMPatchInfo) PatchVirtualMachines;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR JobXmlString, BSTR JobGuid, ITsSbProvisioningPluginNotifySink* pSink) DeleteVirtualMachines;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR JobGuid) CancelJob;
	}


	public HRESULT CreateVirtualMachines(BSTR JobXmlString, BSTR JobGuid, ITsSbProvisioningPluginNotifySink* pSink) mut => VT.[Friend]CreateVirtualMachines(&this, JobXmlString, JobGuid, pSink);

	public HRESULT PatchVirtualMachines(BSTR JobXmlString, BSTR JobGuid, ITsSbProvisioningPluginNotifySink* pSink, VM_PATCH_INFO* pVMPatchInfo) mut => VT.[Friend]PatchVirtualMachines(&this, JobXmlString, JobGuid, pSink, pVMPatchInfo);

	public HRESULT DeleteVirtualMachines(BSTR JobXmlString, BSTR JobGuid, ITsSbProvisioningPluginNotifySink* pSink) mut => VT.[Friend]DeleteVirtualMachines(&this, JobXmlString, JobGuid, pSink);

	public HRESULT CancelJob(BSTR JobGuid) mut => VT.[Friend]CancelJob(&this, JobGuid);
}

[CRepr]struct ITsSbGenericNotifySink : IUnknown
{
	public new const Guid IID = .(0x4c4c8c4f, 0x300b, 0x46ad, 0x91, 0x64, 0x84, 0x68, 0xa7, 0xe7, 0x56, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT Status) OnCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftTimeout) GetWaitTimeout;
	}


	public HRESULT OnCompleted(HRESULT Status) mut => VT.[Friend]OnCompleted(&this, Status);

	public HRESULT GetWaitTimeout(FILETIME* pftTimeout) mut => VT.[Friend]GetWaitTimeout(&this, pftTimeout);
}

[CRepr]struct ItsPubPlugin : IUnknown
{
	public new const Guid IID = .(0x70c04b05, 0xf347, 0x412b, 0x82, 0x2f, 0x36, 0xc9, 0x9c, 0x54, 0xca, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR userID, int32* pceAppListSize, pluginResource** resourceList) GetResourceList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR alias, int32 flags, pluginResource* resource) GetResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* lastUpdateTime) GetCacheLastUpdateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_pluginName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_pluginVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* resourceType, PWSTR resourceLocation, PWSTR endPointName, PWSTR userID, PWSTR alias) ResolveResource;
	}


	public HRESULT GetResourceList(PWSTR userID, int32* pceAppListSize, pluginResource** resourceList) mut => VT.[Friend]GetResourceList(&this, userID, pceAppListSize, resourceList);

	public HRESULT GetResource(PWSTR alias, int32 flags, pluginResource* resource) mut => VT.[Friend]GetResource(&this, alias, flags, resource);

	public HRESULT GetCacheLastUpdateTime(uint64* lastUpdateTime) mut => VT.[Friend]GetCacheLastUpdateTime(&this, lastUpdateTime);

	public HRESULT get_pluginName(BSTR* pVal) mut => VT.[Friend]get_pluginName(&this, pVal);

	public HRESULT get_pluginVersion(BSTR* pVal) mut => VT.[Friend]get_pluginVersion(&this, pVal);

	public HRESULT ResolveResource(uint32* resourceType, PWSTR resourceLocation, PWSTR endPointName, PWSTR userID, PWSTR alias) mut => VT.[Friend]ResolveResource(&this, resourceType, resourceLocation, endPointName, userID, alias);
}

[CRepr]struct ItsPubPlugin2 : ItsPubPlugin
{
	public new const Guid IID = .(0xfa4ce418, 0xaad7, 0x4ec6, 0xba, 0xd1, 0x0a, 0x32, 0x1b, 0xa4, 0x65, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ItsPubPlugin.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR userID, int32* pceAppListSize, pluginResource2** resourceList) GetResource2List;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR alias, int32 flags, pluginResource2* resource) GetResource2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR userId, PWSTR poolId, TSPUB_PLUGIN_PD_RESOLUTION_TYPE ePdResolutionType, TSPUB_PLUGIN_PD_ASSIGNMENT_TYPE* pPdAssignmentType, PWSTR endPointName) ResolvePersonalDesktop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR userId, PWSTR poolId, PWSTR endpointName) DeletePersonalDesktopAssignment;
	}


	public HRESULT GetResource2List(PWSTR userID, int32* pceAppListSize, pluginResource2** resourceList) mut => VT.[Friend]GetResource2List(&this, userID, pceAppListSize, resourceList);

	public HRESULT GetResource2(PWSTR alias, int32 flags, pluginResource2* resource) mut => VT.[Friend]GetResource2(&this, alias, flags, resource);

	public HRESULT ResolvePersonalDesktop(PWSTR userId, PWSTR poolId, TSPUB_PLUGIN_PD_RESOLUTION_TYPE ePdResolutionType, TSPUB_PLUGIN_PD_ASSIGNMENT_TYPE* pPdAssignmentType, PWSTR endPointName) mut => VT.[Friend]ResolvePersonalDesktop(&this, userId, poolId, ePdResolutionType, pPdAssignmentType, endPointName);

	public HRESULT DeletePersonalDesktopAssignment(PWSTR userId, PWSTR poolId, PWSTR endpointName) mut => VT.[Friend]DeletePersonalDesktopAssignment(&this, userId, poolId, endpointName);
}

[CRepr]struct IWorkspaceResTypeRegistry : IDispatch
{
	public new const Guid IID = .(0x1d428c79, 0x6e2e, 0x4351, 0xa3, 0x61, 0xc0, 0x40, 0x1a, 0x03, 0xa0, 0xba);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fMachineWide, BSTR bstrFileExtension, BSTR bstrLauncher) AddResourceType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fMachineWide, BSTR bstrFileExtension) DeleteResourceType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fMachineWide, SAFEARRAY** psaFileExtensions) GetRegisteredFileExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fMachineWide, BSTR bstrFileExtension, BSTR* pbstrLauncher) GetResourceTypeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fMachineWide, BSTR bstrFileExtension, BSTR bstrLauncher) ModifyResourceType;
	}


	public HRESULT AddResourceType(int16 fMachineWide, BSTR bstrFileExtension, BSTR bstrLauncher) mut => VT.[Friend]AddResourceType(&this, fMachineWide, bstrFileExtension, bstrLauncher);

	public HRESULT DeleteResourceType(int16 fMachineWide, BSTR bstrFileExtension) mut => VT.[Friend]DeleteResourceType(&this, fMachineWide, bstrFileExtension);

	public HRESULT GetRegisteredFileExtensions(int16 fMachineWide, SAFEARRAY** psaFileExtensions) mut => VT.[Friend]GetRegisteredFileExtensions(&this, fMachineWide, psaFileExtensions);

	public HRESULT GetResourceTypeInfo(int16 fMachineWide, BSTR bstrFileExtension, BSTR* pbstrLauncher) mut => VT.[Friend]GetResourceTypeInfo(&this, fMachineWide, bstrFileExtension, pbstrLauncher);

	public HRESULT ModifyResourceType(int16 fMachineWide, BSTR bstrFileExtension, BSTR bstrLauncher) mut => VT.[Friend]ModifyResourceType(&this, fMachineWide, bstrFileExtension, bstrLauncher);
}

[CRepr]struct IWTSPlugin : IUnknown
{
	public new const Guid IID = .(0xa1230201, 0x1439, 0x4e62, 0xa4, 0x14, 0x19, 0x0d, 0x0a, 0xc3, 0xd4, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWTSVirtualChannelManager* pChannelMgr) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Connected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDisconnectCode) Disconnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Terminated;
	}


	public HRESULT Initialize(IWTSVirtualChannelManager* pChannelMgr) mut => VT.[Friend]Initialize(&this, pChannelMgr);

	public HRESULT Connected() mut => VT.[Friend]Connected(&this);

	public HRESULT Disconnected(uint32 dwDisconnectCode) mut => VT.[Friend]Disconnected(&this, dwDisconnectCode);

	public HRESULT Terminated() mut => VT.[Friend]Terminated(&this);
}

[CRepr]struct IWTSListener : IUnknown
{
	public new const Guid IID = .(0xa1230206, 0x9a39, 0x4d58, 0x86, 0x74, 0xcd, 0xb4, 0xdf, 0xf4, 0xe7, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyBag** ppPropertyBag) GetConfiguration;
	}


	public HRESULT GetConfiguration(IPropertyBag** ppPropertyBag) mut => VT.[Friend]GetConfiguration(&this, ppPropertyBag);
}

[CRepr]struct IWTSListenerCallback : IUnknown
{
	public new const Guid IID = .(0xa1230203, 0xd6a7, 0x11d8, 0xb9, 0xfd, 0x00, 0x0b, 0xdb, 0xd1, 0xf1, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWTSVirtualChannel* pChannel, BSTR data, BOOL* pbAccept, IWTSVirtualChannelCallback** ppCallback) OnNewChannelConnection;
	}


	public HRESULT OnNewChannelConnection(IWTSVirtualChannel* pChannel, BSTR data, BOOL* pbAccept, IWTSVirtualChannelCallback** ppCallback) mut => VT.[Friend]OnNewChannelConnection(&this, pChannel, data, pbAccept, ppCallback);
}

[CRepr]struct IWTSVirtualChannelCallback : IUnknown
{
	public new const Guid IID = .(0xa1230204, 0xd6a7, 0x11d8, 0xb9, 0xfd, 0x00, 0x0b, 0xdb, 0xd1, 0xf1, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbSize, uint8* pBuffer) OnDataReceived;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnClose;
	}


	public HRESULT OnDataReceived(uint32 cbSize, uint8* pBuffer) mut => VT.[Friend]OnDataReceived(&this, cbSize, pBuffer);

	public HRESULT OnClose() mut => VT.[Friend]OnClose(&this);
}

[CRepr]struct IWTSVirtualChannelManager : IUnknown
{
	public new const Guid IID = .(0xa1230205, 0xd6a7, 0x11d8, 0xb9, 0xfd, 0x00, 0x0b, 0xdb, 0xd1, 0xf1, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszChannelName, uint32 uFlags, IWTSListenerCallback* pListenerCallback, IWTSListener** ppListener) CreateListener;
	}


	public HRESULT CreateListener(uint8* pszChannelName, uint32 uFlags, IWTSListenerCallback* pListenerCallback, IWTSListener** ppListener) mut => VT.[Friend]CreateListener(&this, pszChannelName, uFlags, pListenerCallback, ppListener);
}

[CRepr]struct IWTSVirtualChannel : IUnknown
{
	public new const Guid IID = .(0xa1230207, 0xd6a7, 0x11d8, 0xb9, 0xfd, 0x00, 0x0b, 0xdb, 0xd1, 0xf1, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbSize, uint8* pBuffer, IUnknown* pReserved) Write;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT Write(uint32 cbSize, uint8* pBuffer, IUnknown* pReserved) mut => VT.[Friend]Write(&this, cbSize, pBuffer, pReserved);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IWTSPluginServiceProvider : IUnknown
{
	public new const Guid IID = .(0xd3e07363, 0x087c, 0x476c, 0x86, 0xa7, 0xdb, 0xb1, 0x5f, 0x46, 0xdd, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid ServiceId, IUnknown** ppunkObject) GetService;
	}


	public HRESULT GetService(Guid ServiceId, IUnknown** ppunkObject) mut => VT.[Friend]GetService(&this, ServiceId, ppunkObject);
}

[CRepr]struct IWTSBitmapRenderer : IUnknown
{
	public new const Guid IID = .(0x5b7acc97, 0xf3c9, 0x46f7, 0x8c, 0x5b, 0xfa, 0x68, 0x5d, 0x34, 0x41, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid imageFormat, uint32 dwWidth, uint32 dwHeight, int32 cbStride, uint32 cbImageBuffer, uint8* pImageBuffer) Render;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BITMAP_RENDERER_STATISTICS* pStatistics) GetRendererStatistics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveMapping;
	}


	public HRESULT Render(Guid imageFormat, uint32 dwWidth, uint32 dwHeight, int32 cbStride, uint32 cbImageBuffer, uint8* pImageBuffer) mut => VT.[Friend]Render(&this, imageFormat, dwWidth, dwHeight, cbStride, cbImageBuffer, pImageBuffer);

	public HRESULT GetRendererStatistics(BITMAP_RENDERER_STATISTICS* pStatistics) mut => VT.[Friend]GetRendererStatistics(&this, pStatistics);

	public HRESULT RemoveMapping() mut => VT.[Friend]RemoveMapping(&this);
}

[CRepr]struct IWTSBitmapRendererCallback : IUnknown
{
	public new const Guid IID = .(0xd782928e, 0xfe4e, 0x4e77, 0xae, 0x90, 0x9c, 0xd0, 0xb3, 0xe3, 0xb3, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT rcNewSize) OnTargetSizeChanged;
	}


	public HRESULT OnTargetSizeChanged(RECT rcNewSize) mut => VT.[Friend]OnTargetSizeChanged(&this, rcNewSize);
}

[CRepr]struct IWTSBitmapRenderService : IUnknown
{
	public new const Guid IID = .(0xea326091, 0x05fe, 0x40c1, 0xb4, 0x9c, 0x3d, 0x2e, 0xf4, 0x62, 0x6a, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 mappingId, IWTSBitmapRendererCallback* pMappedRendererCallback, IWTSBitmapRenderer** ppMappedRenderer) GetMappedRenderer;
	}


	public HRESULT GetMappedRenderer(uint64 mappingId, IWTSBitmapRendererCallback* pMappedRendererCallback, IWTSBitmapRenderer** ppMappedRenderer) mut => VT.[Friend]GetMappedRenderer(&this, mappingId, pMappedRendererCallback, ppMappedRenderer);
}

[CRepr]struct IWRdsGraphicsChannelEvents : IUnknown
{
	public new const Guid IID = .(0x67f2368c, 0xd674, 0x4fae, 0x66, 0xa5, 0xd2, 0x06, 0x28, 0xa6, 0x40, 0xd2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbSize, uint8* pBuffer) OnDataReceived;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnClose;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT OpenResult, IUnknown* pOpenContext) OnChannelOpened;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pWriteContext, BOOL bCancelled, uint8* pBuffer, uint32 cbBuffer) OnDataSent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 bandwidth, uint32 RTT, uint64 lastSentByteIndex) OnMetricsUpdate;
	}


	public HRESULT OnDataReceived(uint32 cbSize, uint8* pBuffer) mut => VT.[Friend]OnDataReceived(&this, cbSize, pBuffer);

	public HRESULT OnClose() mut => VT.[Friend]OnClose(&this);

	public HRESULT OnChannelOpened(HRESULT OpenResult, IUnknown* pOpenContext) mut => VT.[Friend]OnChannelOpened(&this, OpenResult, pOpenContext);

	public HRESULT OnDataSent(IUnknown* pWriteContext, BOOL bCancelled, uint8* pBuffer, uint32 cbBuffer) mut => VT.[Friend]OnDataSent(&this, pWriteContext, bCancelled, pBuffer, cbBuffer);

	public HRESULT OnMetricsUpdate(uint32 bandwidth, uint32 RTT, uint64 lastSentByteIndex) mut => VT.[Friend]OnMetricsUpdate(&this, bandwidth, RTT, lastSentByteIndex);
}

[CRepr]struct IWRdsGraphicsChannel : IUnknown
{
	public new const Guid IID = .(0x684b7a0b, 0xedff, 0x43ad, 0xd5, 0xa2, 0x4a, 0x8d, 0x53, 0x88, 0xf4, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbSize, uint8* pBuffer, IUnknown* pContext) Write;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWRdsGraphicsChannelEvents* pChannelEvents, IUnknown* pOpenContext) Open;
	}


	public HRESULT Write(uint32 cbSize, uint8* pBuffer, IUnknown* pContext) mut => VT.[Friend]Write(&this, cbSize, pBuffer, pContext);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT Open(IWRdsGraphicsChannelEvents* pChannelEvents, IUnknown* pOpenContext) mut => VT.[Friend]Open(&this, pChannelEvents, pOpenContext);
}

[CRepr]struct IWRdsGraphicsChannelManager : IUnknown
{
	public new const Guid IID = .(0x0fd57159, 0xe83e, 0x476a, 0xa8, 0xb9, 0x4a, 0x79, 0x76, 0xe7, 0x1e, 0x18);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszChannelName, WRdsGraphicsChannelType channelType, IWRdsGraphicsChannel** ppVirtualChannel) CreateChannel;
	}


	public HRESULT CreateChannel(uint8* pszChannelName, WRdsGraphicsChannelType channelType, IWRdsGraphicsChannel** ppVirtualChannel) mut => VT.[Friend]CreateChannel(&this, pszChannelName, channelType, ppVirtualChannel);
}

[CRepr]struct IWTSProtocolManager : IUnknown
{
	public new const Guid IID = .(0xf9eaf6cc, 0xed79, 0x4f01, 0x82, 0x1d, 0x1f, 0x88, 0x1b, 0x9f, 0x66, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszListenerName, IWTSProtocolListener** pProtocolListener) CreateListener;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SERVICE_STATE* pTSServiceStateChange) NotifyServiceStateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SESSION_ID* SessionId) NotifySessionOfServiceStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SESSION_ID* SessionId) NotifySessionOfServiceStop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SESSION_ID* SessionId, uint32 EventId) NotifySessionStateChange;
	}


	public HRESULT CreateListener(PWSTR wszListenerName, IWTSProtocolListener** pProtocolListener) mut => VT.[Friend]CreateListener(&this, wszListenerName, pProtocolListener);

	public HRESULT NotifyServiceStateChange(WTS_SERVICE_STATE* pTSServiceStateChange) mut => VT.[Friend]NotifyServiceStateChange(&this, pTSServiceStateChange);

	public HRESULT NotifySessionOfServiceStart(WTS_SESSION_ID* SessionId) mut => VT.[Friend]NotifySessionOfServiceStart(&this, SessionId);

	public HRESULT NotifySessionOfServiceStop(WTS_SESSION_ID* SessionId) mut => VT.[Friend]NotifySessionOfServiceStop(&this, SessionId);

	public HRESULT NotifySessionStateChange(WTS_SESSION_ID* SessionId, uint32 EventId) mut => VT.[Friend]NotifySessionStateChange(&this, SessionId, EventId);
}

[CRepr]struct IWTSProtocolListener : IUnknown
{
	public new const Guid IID = .(0x23083765, 0x45f0, 0x4394, 0x8f, 0x69, 0x32, 0xb2, 0xbc, 0x0e, 0xf4, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWTSProtocolListenerCallback* pCallback) StartListen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopListen;
	}


	public HRESULT StartListen(IWTSProtocolListenerCallback* pCallback) mut => VT.[Friend]StartListen(&this, pCallback);

	public HRESULT StopListen() mut => VT.[Friend]StopListen(&this);
}

[CRepr]struct IWTSProtocolListenerCallback : IUnknown
{
	public new const Guid IID = .(0x23083765, 0x1a2d, 0x4de2, 0x97, 0xde, 0x4a, 0x35, 0xf2, 0x60, 0xf0, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWTSProtocolConnection* pConnection, IWTSProtocolConnectionCallback** pCallback) OnConnected;
	}


	public HRESULT OnConnected(IWTSProtocolConnection* pConnection, IWTSProtocolConnectionCallback** pCallback) mut => VT.[Friend]OnConnected(&this, pConnection, pCallback);
}

[CRepr]struct IWTSProtocolConnection : IUnknown
{
	public new const Guid IID = .(0x23083765, 0x9095, 0x4648, 0x98, 0xbf, 0xef, 0x81, 0xc9, 0x14, 0x03, 0x2d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWTSProtocolLogonErrorRedirector** ppLogonErrorRedir) GetLogonErrorRedirector;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_POLICY_DATA* pPolicyData) SendPolicyData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AcceptConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_CLIENT_DATA* pClientData) GetClientData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_USER_CREDENTIAL* pUserCreds) GetUserCredentials;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWTSProtocolLicenseConnection** ppLicenseConnection) GetLicenseConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SESSION_ID* SessionId) AuthenticateClientToSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SESSION_ID* SessionId) NotifySessionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR* pKeyboardHandle, HANDLE_PTR* pMouseHandle, HANDLE_PTR* pBeepHandle, HANDLE_PTR* pVideoHandle) GetProtocolHandles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 SessionId) ConnectNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 SessionId, HANDLE_PTR UserToken, PWSTR pDomainName, PWSTR pUserName) IsUserAllowedToLogon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR hUserToken, BOOL bSingleSessionPerUserEnabled, uint32* pSessionIdArray, uint32* pdwSessionIdentifierCount) SessionArbitrationEnumeration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR hClientToken, PWSTR wszUserName, PWSTR wszDomainName, WTS_SESSION_ID* SessionId) LogonNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_POLICY_DATA* pPolicyData, WTS_USER_DATA* pClientData) GetUserData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisconnectNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_PROTOCOL_STATUS* pProtocolStatus) GetProtocolStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pLastInputTime) GetLastInputTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulError) SetErrorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Frequency, uint32 Duration) SendBeep;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR szEndpointName, BOOL bStatic, uint32 RequestedPriority, uint* phChannel) CreateVirtualChannel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid QueryType, uint32 ulNumEntriesIn, uint32 ulNumEntriesOut, WTS_PROPERTY_VALUE* pPropertyEntriesIn, WTS_PROPERTY_VALUE* pPropertyEntriesOut) QueryProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWTSProtocolShadowConnection** ppShadowConnection) GetShadowConnection;
	}


	public HRESULT GetLogonErrorRedirector(IWTSProtocolLogonErrorRedirector** ppLogonErrorRedir) mut => VT.[Friend]GetLogonErrorRedirector(&this, ppLogonErrorRedir);

	public HRESULT SendPolicyData(WTS_POLICY_DATA* pPolicyData) mut => VT.[Friend]SendPolicyData(&this, pPolicyData);

	public HRESULT AcceptConnection() mut => VT.[Friend]AcceptConnection(&this);

	public HRESULT GetClientData(WTS_CLIENT_DATA* pClientData) mut => VT.[Friend]GetClientData(&this, pClientData);

	public HRESULT GetUserCredentials(WTS_USER_CREDENTIAL* pUserCreds) mut => VT.[Friend]GetUserCredentials(&this, pUserCreds);

	public HRESULT GetLicenseConnection(IWTSProtocolLicenseConnection** ppLicenseConnection) mut => VT.[Friend]GetLicenseConnection(&this, ppLicenseConnection);

	public HRESULT AuthenticateClientToSession(WTS_SESSION_ID* SessionId) mut => VT.[Friend]AuthenticateClientToSession(&this, SessionId);

	public HRESULT NotifySessionId(WTS_SESSION_ID* SessionId) mut => VT.[Friend]NotifySessionId(&this, SessionId);

	public HRESULT GetProtocolHandles(HANDLE_PTR* pKeyboardHandle, HANDLE_PTR* pMouseHandle, HANDLE_PTR* pBeepHandle, HANDLE_PTR* pVideoHandle) mut => VT.[Friend]GetProtocolHandles(&this, pKeyboardHandle, pMouseHandle, pBeepHandle, pVideoHandle);

	public HRESULT ConnectNotify(uint32 SessionId) mut => VT.[Friend]ConnectNotify(&this, SessionId);

	public HRESULT IsUserAllowedToLogon(uint32 SessionId, HANDLE_PTR UserToken, PWSTR pDomainName, PWSTR pUserName) mut => VT.[Friend]IsUserAllowedToLogon(&this, SessionId, UserToken, pDomainName, pUserName);

	public HRESULT SessionArbitrationEnumeration(HANDLE_PTR hUserToken, BOOL bSingleSessionPerUserEnabled, uint32* pSessionIdArray, uint32* pdwSessionIdentifierCount) mut => VT.[Friend]SessionArbitrationEnumeration(&this, hUserToken, bSingleSessionPerUserEnabled, pSessionIdArray, pdwSessionIdentifierCount);

	public HRESULT LogonNotify(HANDLE_PTR hClientToken, PWSTR wszUserName, PWSTR wszDomainName, WTS_SESSION_ID* SessionId) mut => VT.[Friend]LogonNotify(&this, hClientToken, wszUserName, wszDomainName, SessionId);

	public HRESULT GetUserData(WTS_POLICY_DATA* pPolicyData, WTS_USER_DATA* pClientData) mut => VT.[Friend]GetUserData(&this, pPolicyData, pClientData);

	public HRESULT DisconnectNotify() mut => VT.[Friend]DisconnectNotify(&this);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT GetProtocolStatus(WTS_PROTOCOL_STATUS* pProtocolStatus) mut => VT.[Friend]GetProtocolStatus(&this, pProtocolStatus);

	public HRESULT GetLastInputTime(uint64* pLastInputTime) mut => VT.[Friend]GetLastInputTime(&this, pLastInputTime);

	public HRESULT SetErrorInfo(uint32 ulError) mut => VT.[Friend]SetErrorInfo(&this, ulError);

	public HRESULT SendBeep(uint32 Frequency, uint32 Duration) mut => VT.[Friend]SendBeep(&this, Frequency, Duration);

	public HRESULT CreateVirtualChannel(PSTR szEndpointName, BOOL bStatic, uint32 RequestedPriority, uint* phChannel) mut => VT.[Friend]CreateVirtualChannel(&this, szEndpointName, bStatic, RequestedPriority, phChannel);

	public HRESULT QueryProperty(Guid QueryType, uint32 ulNumEntriesIn, uint32 ulNumEntriesOut, WTS_PROPERTY_VALUE* pPropertyEntriesIn, WTS_PROPERTY_VALUE* pPropertyEntriesOut) mut => VT.[Friend]QueryProperty(&this, QueryType, ulNumEntriesIn, ulNumEntriesOut, pPropertyEntriesIn, pPropertyEntriesOut);

	public HRESULT GetShadowConnection(IWTSProtocolShadowConnection** ppShadowConnection) mut => VT.[Friend]GetShadowConnection(&this, ppShadowConnection);
}

[CRepr]struct IWTSProtocolConnectionCallback : IUnknown
{
	public new const Guid IID = .(0x23083765, 0x75eb, 0x41fe, 0xb4, 0xfb, 0xe0, 0x86, 0x24, 0x2a, 0xfa, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnReady;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Reason, uint32 Source) BrokenConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopScreenUpdates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SMALL_RECT* rect) RedrawWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_DISPLAY_IOCTL* DisplayIOCtl) DisplayIOCtl;
	}


	public HRESULT OnReady() mut => VT.[Friend]OnReady(&this);

	public HRESULT BrokenConnection(uint32 Reason, uint32 Source) mut => VT.[Friend]BrokenConnection(&this, Reason, Source);

	public HRESULT StopScreenUpdates() mut => VT.[Friend]StopScreenUpdates(&this);

	public HRESULT RedrawWindow(WTS_SMALL_RECT* rect) mut => VT.[Friend]RedrawWindow(&this, rect);

	public HRESULT DisplayIOCtl(WTS_DISPLAY_IOCTL* DisplayIOCtl) mut => VT.[Friend]DisplayIOCtl(&this, DisplayIOCtl);
}

[CRepr]struct IWTSProtocolShadowConnection : IUnknown
{
	public new const Guid IID = .(0xee3b0c14, 0x37fb, 0x456b, 0xba, 0xb3, 0x6d, 0x6c, 0xd5, 0x1e, 0x13, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pTargetServerName, uint32 TargetSessionId, uint8 HotKeyVk, uint16 HotkeyModifiers, IWTSProtocolShadowCallback* pShadowCallback) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pParam1, uint32 Param1Size, uint8* pParam2, uint32 Param2Size, uint8* pParam3, uint32 Param3Size, uint8* pParam4, uint32 Param4Size, PWSTR pClientName) DoTarget;
	}


	public HRESULT Start(PWSTR pTargetServerName, uint32 TargetSessionId, uint8 HotKeyVk, uint16 HotkeyModifiers, IWTSProtocolShadowCallback* pShadowCallback) mut => VT.[Friend]Start(&this, pTargetServerName, TargetSessionId, HotKeyVk, HotkeyModifiers, pShadowCallback);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT DoTarget(uint8* pParam1, uint32 Param1Size, uint8* pParam2, uint32 Param2Size, uint8* pParam3, uint32 Param3Size, uint8* pParam4, uint32 Param4Size, PWSTR pClientName) mut => VT.[Friend]DoTarget(&this, pParam1, Param1Size, pParam2, Param2Size, pParam3, Param3Size, pParam4, Param4Size, pClientName);
}

[CRepr]struct IWTSProtocolShadowCallback : IUnknown
{
	public new const Guid IID = .(0x503a2504, 0xaae5, 0x4ab1, 0x93, 0xe0, 0x6d, 0x1c, 0x4b, 0xc6, 0xf7, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopShadow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pTargetServerName, uint32 TargetSessionId, uint8* pParam1, uint32 Param1Size, uint8* pParam2, uint32 Param2Size, uint8* pParam3, uint32 Param3Size, uint8* pParam4, uint32 Param4Size, PWSTR pClientName) InvokeTargetShadow;
	}


	public HRESULT StopShadow() mut => VT.[Friend]StopShadow(&this);

	public HRESULT InvokeTargetShadow(PWSTR pTargetServerName, uint32 TargetSessionId, uint8* pParam1, uint32 Param1Size, uint8* pParam2, uint32 Param2Size, uint8* pParam3, uint32 Param3Size, uint8* pParam4, uint32 Param4Size, PWSTR pClientName) mut => VT.[Friend]InvokeTargetShadow(&this, pTargetServerName, TargetSessionId, pParam1, Param1Size, pParam2, Param2Size, pParam3, Param3Size, pParam4, Param4Size, pClientName);
}

[CRepr]struct IWTSProtocolLicenseConnection : IUnknown
{
	public new const Guid IID = .(0x23083765, 0x178c, 0x4079, 0x8e, 0x4a, 0xfe, 0xa6, 0x49, 0x6a, 0x4d, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_LICENSE_CAPABILITIES* ppLicenseCapabilities, uint32* pcbLicenseCapabilities) RequestLicensingCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pClientLicense, uint32 cbClientLicense) SendClientLicense;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* Reserve1, uint32 Reserve2, uint8* ppClientLicense, uint32* pcbClientLicense) RequestClientLicense;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulComplete) ProtocolComplete;
	}


	public HRESULT RequestLicensingCapabilities(WTS_LICENSE_CAPABILITIES* ppLicenseCapabilities, uint32* pcbLicenseCapabilities) mut => VT.[Friend]RequestLicensingCapabilities(&this, ppLicenseCapabilities, pcbLicenseCapabilities);

	public HRESULT SendClientLicense(uint8* pClientLicense, uint32 cbClientLicense) mut => VT.[Friend]SendClientLicense(&this, pClientLicense, cbClientLicense);

	public HRESULT RequestClientLicense(uint8* Reserve1, uint32 Reserve2, uint8* ppClientLicense, uint32* pcbClientLicense) mut => VT.[Friend]RequestClientLicense(&this, Reserve1, Reserve2, ppClientLicense, pcbClientLicense);

	public HRESULT ProtocolComplete(uint32 ulComplete) mut => VT.[Friend]ProtocolComplete(&this, ulComplete);
}

[CRepr]struct IWTSProtocolLogonErrorRedirector : IUnknown
{
	public new const Guid IID = .(0xfd9b61a7, 0x2916, 0x4627, 0x8d, 0xee, 0x43, 0x28, 0x71, 0x1a, 0xd6, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnBeginPainting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMessage, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) RedirectStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCaption, PWSTR pszMessage, uint32 uType, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) RedirectMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 ntsStatus, int32 ntsSubstatus, PWSTR pszCaption, PWSTR pszMessage, uint32 uType, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) RedirectLogonError;
	}


	public HRESULT OnBeginPainting() mut => VT.[Friend]OnBeginPainting(&this);

	public HRESULT RedirectStatus(PWSTR pszMessage, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) mut => VT.[Friend]RedirectStatus(&this, pszMessage, pResponse);

	public HRESULT RedirectMessage(PWSTR pszCaption, PWSTR pszMessage, uint32 uType, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) mut => VT.[Friend]RedirectMessage(&this, pszCaption, pszMessage, uType, pResponse);

	public HRESULT RedirectLogonError(int32 ntsStatus, int32 ntsSubstatus, PWSTR pszCaption, PWSTR pszMessage, uint32 uType, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) mut => VT.[Friend]RedirectLogonError(&this, ntsStatus, ntsSubstatus, pszCaption, pszMessage, uType, pResponse);
}

[CRepr]struct IWRdsProtocolSettings : IUnknown
{
	public new const Guid IID = .(0x654a5a6a, 0x2550, 0x47eb, 0xb6, 0xf7, 0xeb, 0xd6, 0x37, 0x47, 0x52, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WRDS_SETTING_TYPE WRdsSettingType, WRDS_SETTING_LEVEL WRdsSettingLevel, WRDS_SETTINGS* pWRdsSettings) GetSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WRDS_SETTINGS* pWRdsSettings, WRDS_CONNECTION_SETTING_LEVEL WRdsConnectionSettingLevel, WRDS_CONNECTION_SETTINGS* pWRdsConnectionSettings) MergeSettings;
	}


	public HRESULT GetSettings(WRDS_SETTING_TYPE WRdsSettingType, WRDS_SETTING_LEVEL WRdsSettingLevel, WRDS_SETTINGS* pWRdsSettings) mut => VT.[Friend]GetSettings(&this, WRdsSettingType, WRdsSettingLevel, pWRdsSettings);

	public HRESULT MergeSettings(WRDS_SETTINGS* pWRdsSettings, WRDS_CONNECTION_SETTING_LEVEL WRdsConnectionSettingLevel, WRDS_CONNECTION_SETTINGS* pWRdsConnectionSettings) mut => VT.[Friend]MergeSettings(&this, pWRdsSettings, WRdsConnectionSettingLevel, pWRdsConnectionSettings);
}

[CRepr]struct IWRdsProtocolManager : IUnknown
{
	public new const Guid IID = .(0xdc796967, 0x3abb, 0x40cd, 0xa4, 0x46, 0x10, 0x52, 0x76, 0xb5, 0x89, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWRdsProtocolSettings* pIWRdsSettings, WRDS_SETTINGS* pWRdsSettings) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszListenerName, IWRdsProtocolListener** pProtocolListener) CreateListener;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SERVICE_STATE* pTSServiceStateChange) NotifyServiceStateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SESSION_ID* SessionId) NotifySessionOfServiceStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SESSION_ID* SessionId) NotifySessionOfServiceStop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SESSION_ID* SessionId, uint32 EventId) NotifySessionStateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WRDS_SETTINGS* pWRdsSettings) NotifySettingsChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Uninitialize;
	}


	public HRESULT Initialize(IWRdsProtocolSettings* pIWRdsSettings, WRDS_SETTINGS* pWRdsSettings) mut => VT.[Friend]Initialize(&this, pIWRdsSettings, pWRdsSettings);

	public HRESULT CreateListener(PWSTR wszListenerName, IWRdsProtocolListener** pProtocolListener) mut => VT.[Friend]CreateListener(&this, wszListenerName, pProtocolListener);

	public HRESULT NotifyServiceStateChange(WTS_SERVICE_STATE* pTSServiceStateChange) mut => VT.[Friend]NotifyServiceStateChange(&this, pTSServiceStateChange);

	public HRESULT NotifySessionOfServiceStart(WTS_SESSION_ID* SessionId) mut => VT.[Friend]NotifySessionOfServiceStart(&this, SessionId);

	public HRESULT NotifySessionOfServiceStop(WTS_SESSION_ID* SessionId) mut => VT.[Friend]NotifySessionOfServiceStop(&this, SessionId);

	public HRESULT NotifySessionStateChange(WTS_SESSION_ID* SessionId, uint32 EventId) mut => VT.[Friend]NotifySessionStateChange(&this, SessionId, EventId);

	public HRESULT NotifySettingsChange(WRDS_SETTINGS* pWRdsSettings) mut => VT.[Friend]NotifySettingsChange(&this, pWRdsSettings);

	public HRESULT Uninitialize() mut => VT.[Friend]Uninitialize(&this);
}

[CRepr]struct IWRdsProtocolListener : IUnknown
{
	public new const Guid IID = .(0xfcbc131b, 0xc686, 0x451d, 0xa7, 0x73, 0xe2, 0x79, 0xe2, 0x30, 0xf5, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WRDS_LISTENER_SETTING_LEVEL WRdsListenerSettingLevel, WRDS_LISTENER_SETTINGS* pWRdsListenerSettings) GetSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWRdsProtocolListenerCallback* pCallback) StartListen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopListen;
	}


	public HRESULT GetSettings(WRDS_LISTENER_SETTING_LEVEL WRdsListenerSettingLevel, WRDS_LISTENER_SETTINGS* pWRdsListenerSettings) mut => VT.[Friend]GetSettings(&this, WRdsListenerSettingLevel, pWRdsListenerSettings);

	public HRESULT StartListen(IWRdsProtocolListenerCallback* pCallback) mut => VT.[Friend]StartListen(&this, pCallback);

	public HRESULT StopListen() mut => VT.[Friend]StopListen(&this);
}

[CRepr]struct IWRdsProtocolListenerCallback : IUnknown
{
	public new const Guid IID = .(0x3ab27e5b, 0x4449, 0x4dc1, 0xb7, 0x4a, 0x91, 0x62, 0x1d, 0x4f, 0xe9, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWRdsProtocolConnection* pConnection, WRDS_CONNECTION_SETTINGS* pWRdsConnectionSettings, IWRdsProtocolConnectionCallback** pCallback) OnConnected;
	}


	public HRESULT OnConnected(IWRdsProtocolConnection* pConnection, WRDS_CONNECTION_SETTINGS* pWRdsConnectionSettings, IWRdsProtocolConnectionCallback** pCallback) mut => VT.[Friend]OnConnected(&this, pConnection, pWRdsConnectionSettings, pCallback);
}

[CRepr]struct IWRdsProtocolConnection : IUnknown
{
	public new const Guid IID = .(0x324ed94f, 0xfdaf, 0x4ff6, 0x81, 0xa8, 0x42, 0xab, 0xe7, 0x55, 0x83, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWRdsProtocolLogonErrorRedirector** ppLogonErrorRedir) GetLogonErrorRedirector;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AcceptConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_CLIENT_DATA* pClientData) GetClientData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pNumMonitors, uint32* pPrimaryMonitor) GetClientMonitorData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_USER_CREDENTIAL* pUserCreds) GetUserCredentials;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWRdsProtocolLicenseConnection** ppLicenseConnection) GetLicenseConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SESSION_ID* SessionId) AuthenticateClientToSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SESSION_ID* SessionId, HANDLE_PTR SessionHandle) NotifySessionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR* pKeyboardHandle, HANDLE_PTR* pMouseHandle, HANDLE_PTR* pBeepHandle) GetInputHandles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR* pVideoHandle) GetVideoHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 SessionId) ConnectNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 SessionId, HANDLE_PTR UserToken, PWSTR pDomainName, PWSTR pUserName) IsUserAllowedToLogon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR hUserToken, BOOL bSingleSessionPerUserEnabled, uint32* pSessionIdArray, uint32* pdwSessionIdentifierCount) SessionArbitrationEnumeration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE_PTR hClientToken, PWSTR wszUserName, PWSTR wszDomainName, WTS_SESSION_ID* SessionId, WRDS_CONNECTION_SETTINGS* pWRdsConnectionSettings) LogonNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 DisconnectReason) PreDisconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisconnectNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_PROTOCOL_STATUS* pProtocolStatus) GetProtocolStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pLastInputTime) GetLastInputTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulError) SetErrorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR szEndpointName, BOOL bStatic, uint32 RequestedPriority, uint* phChannel) CreateVirtualChannel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid QueryType, uint32 ulNumEntriesIn, uint32 ulNumEntriesOut, WTS_PROPERTY_VALUE* pPropertyEntriesIn, WTS_PROPERTY_VALUE* pPropertyEntriesOut) QueryProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWRdsProtocolShadowConnection** ppShadowConnection) GetShadowConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 SessionId) NotifyCommandProcessCreated;
	}


	public HRESULT GetLogonErrorRedirector(IWRdsProtocolLogonErrorRedirector** ppLogonErrorRedir) mut => VT.[Friend]GetLogonErrorRedirector(&this, ppLogonErrorRedir);

	public HRESULT AcceptConnection() mut => VT.[Friend]AcceptConnection(&this);

	public HRESULT GetClientData(WTS_CLIENT_DATA* pClientData) mut => VT.[Friend]GetClientData(&this, pClientData);

	public HRESULT GetClientMonitorData(uint32* pNumMonitors, uint32* pPrimaryMonitor) mut => VT.[Friend]GetClientMonitorData(&this, pNumMonitors, pPrimaryMonitor);

	public HRESULT GetUserCredentials(WTS_USER_CREDENTIAL* pUserCreds) mut => VT.[Friend]GetUserCredentials(&this, pUserCreds);

	public HRESULT GetLicenseConnection(IWRdsProtocolLicenseConnection** ppLicenseConnection) mut => VT.[Friend]GetLicenseConnection(&this, ppLicenseConnection);

	public HRESULT AuthenticateClientToSession(WTS_SESSION_ID* SessionId) mut => VT.[Friend]AuthenticateClientToSession(&this, SessionId);

	public HRESULT NotifySessionId(WTS_SESSION_ID* SessionId, HANDLE_PTR SessionHandle) mut => VT.[Friend]NotifySessionId(&this, SessionId, SessionHandle);

	public HRESULT GetInputHandles(HANDLE_PTR* pKeyboardHandle, HANDLE_PTR* pMouseHandle, HANDLE_PTR* pBeepHandle) mut => VT.[Friend]GetInputHandles(&this, pKeyboardHandle, pMouseHandle, pBeepHandle);

	public HRESULT GetVideoHandle(HANDLE_PTR* pVideoHandle) mut => VT.[Friend]GetVideoHandle(&this, pVideoHandle);

	public HRESULT ConnectNotify(uint32 SessionId) mut => VT.[Friend]ConnectNotify(&this, SessionId);

	public HRESULT IsUserAllowedToLogon(uint32 SessionId, HANDLE_PTR UserToken, PWSTR pDomainName, PWSTR pUserName) mut => VT.[Friend]IsUserAllowedToLogon(&this, SessionId, UserToken, pDomainName, pUserName);

	public HRESULT SessionArbitrationEnumeration(HANDLE_PTR hUserToken, BOOL bSingleSessionPerUserEnabled, uint32* pSessionIdArray, uint32* pdwSessionIdentifierCount) mut => VT.[Friend]SessionArbitrationEnumeration(&this, hUserToken, bSingleSessionPerUserEnabled, pSessionIdArray, pdwSessionIdentifierCount);

	public HRESULT LogonNotify(HANDLE_PTR hClientToken, PWSTR wszUserName, PWSTR wszDomainName, WTS_SESSION_ID* SessionId, WRDS_CONNECTION_SETTINGS* pWRdsConnectionSettings) mut => VT.[Friend]LogonNotify(&this, hClientToken, wszUserName, wszDomainName, SessionId, pWRdsConnectionSettings);

	public HRESULT PreDisconnect(uint32 DisconnectReason) mut => VT.[Friend]PreDisconnect(&this, DisconnectReason);

	public HRESULT DisconnectNotify() mut => VT.[Friend]DisconnectNotify(&this);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT GetProtocolStatus(WTS_PROTOCOL_STATUS* pProtocolStatus) mut => VT.[Friend]GetProtocolStatus(&this, pProtocolStatus);

	public HRESULT GetLastInputTime(uint64* pLastInputTime) mut => VT.[Friend]GetLastInputTime(&this, pLastInputTime);

	public HRESULT SetErrorInfo(uint32 ulError) mut => VT.[Friend]SetErrorInfo(&this, ulError);

	public HRESULT CreateVirtualChannel(PSTR szEndpointName, BOOL bStatic, uint32 RequestedPriority, uint* phChannel) mut => VT.[Friend]CreateVirtualChannel(&this, szEndpointName, bStatic, RequestedPriority, phChannel);

	public HRESULT QueryProperty(Guid QueryType, uint32 ulNumEntriesIn, uint32 ulNumEntriesOut, WTS_PROPERTY_VALUE* pPropertyEntriesIn, WTS_PROPERTY_VALUE* pPropertyEntriesOut) mut => VT.[Friend]QueryProperty(&this, QueryType, ulNumEntriesIn, ulNumEntriesOut, pPropertyEntriesIn, pPropertyEntriesOut);

	public HRESULT GetShadowConnection(IWRdsProtocolShadowConnection** ppShadowConnection) mut => VT.[Friend]GetShadowConnection(&this, ppShadowConnection);

	public HRESULT NotifyCommandProcessCreated(uint32 SessionId) mut => VT.[Friend]NotifyCommandProcessCreated(&this, SessionId);
}

[CRepr]struct IWRdsProtocolConnectionCallback : IUnknown
{
	public new const Guid IID = .(0xf1d70332, 0xd070, 0x4ef1, 0xa0, 0x88, 0x78, 0x31, 0x35, 0x36, 0xc2, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnReady;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Reason, uint32 Source) BrokenConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopScreenUpdates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_SMALL_RECT* rect) RedrawWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pConnectionId) GetConnectionId;
	}


	public HRESULT OnReady() mut => VT.[Friend]OnReady(&this);

	public HRESULT BrokenConnection(uint32 Reason, uint32 Source) mut => VT.[Friend]BrokenConnection(&this, Reason, Source);

	public HRESULT StopScreenUpdates() mut => VT.[Friend]StopScreenUpdates(&this);

	public HRESULT RedrawWindow(WTS_SMALL_RECT* rect) mut => VT.[Friend]RedrawWindow(&this, rect);

	public HRESULT GetConnectionId(uint32* pConnectionId) mut => VT.[Friend]GetConnectionId(&this, pConnectionId);
}

[CRepr]struct IWRdsProtocolShadowConnection : IUnknown
{
	public new const Guid IID = .(0x9ae85ce6, 0xcade, 0x4548, 0x8f, 0xeb, 0x99, 0x01, 0x65, 0x97, 0xf6, 0x0a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pTargetServerName, uint32 TargetSessionId, uint8 HotKeyVk, uint16 HotkeyModifiers, IWRdsProtocolShadowCallback* pShadowCallback) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pParam1, uint32 Param1Size, uint8* pParam2, uint32 Param2Size, uint8* pParam3, uint32 Param3Size, uint8* pParam4, uint32 Param4Size, PWSTR pClientName) DoTarget;
	}


	public HRESULT Start(PWSTR pTargetServerName, uint32 TargetSessionId, uint8 HotKeyVk, uint16 HotkeyModifiers, IWRdsProtocolShadowCallback* pShadowCallback) mut => VT.[Friend]Start(&this, pTargetServerName, TargetSessionId, HotKeyVk, HotkeyModifiers, pShadowCallback);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT DoTarget(uint8* pParam1, uint32 Param1Size, uint8* pParam2, uint32 Param2Size, uint8* pParam3, uint32 Param3Size, uint8* pParam4, uint32 Param4Size, PWSTR pClientName) mut => VT.[Friend]DoTarget(&this, pParam1, Param1Size, pParam2, Param2Size, pParam3, Param3Size, pParam4, Param4Size, pClientName);
}

[CRepr]struct IWRdsProtocolShadowCallback : IUnknown
{
	public new const Guid IID = .(0xe0667ce0, 0x0372, 0x40d6, 0xad, 0xb2, 0xa0, 0xf3, 0x32, 0x26, 0x74, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopShadow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pTargetServerName, uint32 TargetSessionId, uint8* pParam1, uint32 Param1Size, uint8* pParam2, uint32 Param2Size, uint8* pParam3, uint32 Param3Size, uint8* pParam4, uint32 Param4Size, PWSTR pClientName) InvokeTargetShadow;
	}


	public HRESULT StopShadow() mut => VT.[Friend]StopShadow(&this);

	public HRESULT InvokeTargetShadow(PWSTR pTargetServerName, uint32 TargetSessionId, uint8* pParam1, uint32 Param1Size, uint8* pParam2, uint32 Param2Size, uint8* pParam3, uint32 Param3Size, uint8* pParam4, uint32 Param4Size, PWSTR pClientName) mut => VT.[Friend]InvokeTargetShadow(&this, pTargetServerName, TargetSessionId, pParam1, Param1Size, pParam2, Param2Size, pParam3, Param3Size, pParam4, Param4Size, pClientName);
}

[CRepr]struct IWRdsProtocolLicenseConnection : IUnknown
{
	public new const Guid IID = .(0x1d6a145f, 0xd095, 0x4424, 0x95, 0x7a, 0x40, 0x7f, 0xae, 0x82, 0x2d, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_LICENSE_CAPABILITIES* ppLicenseCapabilities, uint32* pcbLicenseCapabilities) RequestLicensingCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pClientLicense, uint32 cbClientLicense) SendClientLicense;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* Reserve1, uint32 Reserve2, uint8* ppClientLicense, uint32* pcbClientLicense) RequestClientLicense;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulComplete) ProtocolComplete;
	}


	public HRESULT RequestLicensingCapabilities(WTS_LICENSE_CAPABILITIES* ppLicenseCapabilities, uint32* pcbLicenseCapabilities) mut => VT.[Friend]RequestLicensingCapabilities(&this, ppLicenseCapabilities, pcbLicenseCapabilities);

	public HRESULT SendClientLicense(uint8* pClientLicense, uint32 cbClientLicense) mut => VT.[Friend]SendClientLicense(&this, pClientLicense, cbClientLicense);

	public HRESULT RequestClientLicense(uint8* Reserve1, uint32 Reserve2, uint8* ppClientLicense, uint32* pcbClientLicense) mut => VT.[Friend]RequestClientLicense(&this, Reserve1, Reserve2, ppClientLicense, pcbClientLicense);

	public HRESULT ProtocolComplete(uint32 ulComplete) mut => VT.[Friend]ProtocolComplete(&this, ulComplete);
}

[CRepr]struct IWRdsProtocolLogonErrorRedirector : IUnknown
{
	public new const Guid IID = .(0x519fe83b, 0x142a, 0x4120, 0xa3, 0xd5, 0xa4, 0x05, 0xd3, 0x15, 0x28, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnBeginPainting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMessage, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) RedirectStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCaption, PWSTR pszMessage, uint32 uType, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) RedirectMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 ntsStatus, int32 ntsSubstatus, PWSTR pszCaption, PWSTR pszMessage, uint32 uType, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) RedirectLogonError;
	}


	public HRESULT OnBeginPainting() mut => VT.[Friend]OnBeginPainting(&this);

	public HRESULT RedirectStatus(PWSTR pszMessage, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) mut => VT.[Friend]RedirectStatus(&this, pszMessage, pResponse);

	public HRESULT RedirectMessage(PWSTR pszCaption, PWSTR pszMessage, uint32 uType, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) mut => VT.[Friend]RedirectMessage(&this, pszCaption, pszMessage, uType, pResponse);

	public HRESULT RedirectLogonError(int32 ntsStatus, int32 ntsSubstatus, PWSTR pszCaption, PWSTR pszMessage, uint32 uType, WTS_LOGON_ERROR_REDIRECTOR_RESPONSE* pResponse) mut => VT.[Friend]RedirectLogonError(&this, ntsStatus, ntsSubstatus, pszCaption, pszMessage, uType, pResponse);
}

[CRepr]struct IWRdsWddmIddProps : IUnknown
{
	public new const Guid IID = .(0x1382df4d, 0xa289, 0x43d1, 0xa1, 0x84, 0x14, 0x47, 0x26, 0xf9, 0xaf, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pDisplayDriverHardwareId, uint32 Count) GetHardwareId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 SessionId, HANDLE_PTR DriverHandle) OnDriverLoad;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 SessionId) OnDriverUnload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Enabled) EnableWddmIdd;
	}


	public HRESULT GetHardwareId(char16* pDisplayDriverHardwareId, uint32 Count) mut => VT.[Friend]GetHardwareId(&this, pDisplayDriverHardwareId, Count);

	public HRESULT OnDriverLoad(uint32 SessionId, HANDLE_PTR DriverHandle) mut => VT.[Friend]OnDriverLoad(&this, SessionId, DriverHandle);

	public HRESULT OnDriverUnload(uint32 SessionId) mut => VT.[Friend]OnDriverUnload(&this, SessionId);

	public HRESULT EnableWddmIdd(BOOL Enabled) mut => VT.[Friend]EnableWddmIdd(&this, Enabled);
}

[CRepr]struct IWRdsProtocolConnectionSettings : IUnknown
{
	public new const Guid IID = .(0x83fcf5d3, 0xf6f4, 0xea94, 0x9c, 0xd2, 0x32, 0xf2, 0x80, 0xe1, 0xe5, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid PropertyID, WTS_PROPERTY_VALUE* pPropertyEntriesIn) SetConnectionSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid PropertyID, WTS_PROPERTY_VALUE* pPropertyEntriesOut) GetConnectionSetting;
	}


	public HRESULT SetConnectionSetting(Guid PropertyID, WTS_PROPERTY_VALUE* pPropertyEntriesIn) mut => VT.[Friend]SetConnectionSetting(&this, PropertyID, pPropertyEntriesIn);

	public HRESULT GetConnectionSetting(Guid PropertyID, WTS_PROPERTY_VALUE* pPropertyEntriesOut) mut => VT.[Friend]GetConnectionSetting(&this, PropertyID, pPropertyEntriesOut);
}

[CRepr]struct IWRdsEnhancedFastReconnectArbitrator : IUnknown
{
	public new const Guid IID = .(0x5718ae9b, 0x47f2, 0x499f, 0xb6, 0x34, 0xd8, 0x17, 0x5b, 0xd5, 0x11, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pSessionIdArray, uint32 dwSessionCount, int32* pResultSessionId) GetSessionForEnhancedFastReconnect;
	}


	public HRESULT GetSessionForEnhancedFastReconnect(int32* pSessionIdArray, uint32 dwSessionCount, int32* pResultSessionId) mut => VT.[Friend]GetSessionForEnhancedFastReconnect(&this, pSessionIdArray, dwSessionCount, pResultSessionId);
}

[CRepr]struct IRemoteDesktopClientSettings : IDispatch
{
	public new const Guid IID = .(0x48a0f2a7, 0x2713, 0x431f, 0xbb, 0xac, 0x6f, 0x45, 0x58, 0xe7, 0xd6, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR rdpFileContents) ApplySettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* rdpFileContents) RetrieveSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR propertyName, VARIANT* value) GetRdpProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR propertyName, VARIANT value) SetRdpProperty;
	}


	public HRESULT ApplySettings(BSTR rdpFileContents) mut => VT.[Friend]ApplySettings(&this, rdpFileContents);

	public HRESULT RetrieveSettings(BSTR* rdpFileContents) mut => VT.[Friend]RetrieveSettings(&this, rdpFileContents);

	public HRESULT GetRdpProperty(BSTR propertyName, VARIANT* value) mut => VT.[Friend]GetRdpProperty(&this, propertyName, value);

	public HRESULT SetRdpProperty(BSTR propertyName, VARIANT value) mut => VT.[Friend]SetRdpProperty(&this, propertyName, value);
}

[CRepr]struct IRemoteDesktopClientActions : IDispatch
{
	public new const Guid IID = .(0x7d54bc4e, 0x1028, 0x45d4, 0x8b, 0x0a, 0xb9, 0xb6, 0xbf, 0xfb, 0xa1, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SuspendScreenUpdates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResumeScreenUpdates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RemoteActionType remoteAction) ExecuteRemoteAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SnapshotEncodingType snapshotEncoding, SnapshotFormatType snapshotFormat, uint32 snapshotWidth, uint32 snapshotHeight, BSTR* snapshotData) GetSnapshot;
	}


	public HRESULT SuspendScreenUpdates() mut => VT.[Friend]SuspendScreenUpdates(&this);

	public HRESULT ResumeScreenUpdates() mut => VT.[Friend]ResumeScreenUpdates(&this);

	public HRESULT ExecuteRemoteAction(RemoteActionType remoteAction) mut => VT.[Friend]ExecuteRemoteAction(&this, remoteAction);

	public HRESULT GetSnapshot(SnapshotEncodingType snapshotEncoding, SnapshotFormatType snapshotFormat, uint32 snapshotWidth, uint32 snapshotHeight, BSTR* snapshotData) mut => VT.[Friend]GetSnapshot(&this, snapshotEncoding, snapshotFormat, snapshotWidth, snapshotHeight, snapshotData);
}

[CRepr]struct IRemoteDesktopClientTouchPointer : IDispatch
{
	public new const Guid IID = .(0x260ec22d, 0x8cbc, 0x44b5, 0x9e, 0x88, 0x2a, 0x37, 0xf6, 0xc9, 0x3a, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 enabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* enabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 eventsEnabled) put_EventsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* eventsEnabled) get_EventsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 pointerSpeed) put_PointerSpeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pointerSpeed) get_PointerSpeed;
	}


	public HRESULT put_Enabled(int16 enabled) mut => VT.[Friend]put_Enabled(&this, enabled);

	public HRESULT get_Enabled(int16* enabled) mut => VT.[Friend]get_Enabled(&this, enabled);

	public HRESULT put_EventsEnabled(int16 eventsEnabled) mut => VT.[Friend]put_EventsEnabled(&this, eventsEnabled);

	public HRESULT get_EventsEnabled(int16* eventsEnabled) mut => VT.[Friend]get_EventsEnabled(&this, eventsEnabled);

	public HRESULT put_PointerSpeed(uint32 pointerSpeed) mut => VT.[Friend]put_PointerSpeed(&this, pointerSpeed);

	public HRESULT get_PointerSpeed(uint32* pointerSpeed) mut => VT.[Friend]get_PointerSpeed(&this, pointerSpeed);
}

[CRepr]struct IRemoteDesktopClient : IDispatch
{
	public new const Guid IID = .(0x57d25668, 0x625a, 0x4905, 0xbe, 0x4e, 0x30, 0x4c, 0xaa, 0x13, 0xf8, 0x9c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 width, uint32 height) Reconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRemoteDesktopClientSettings** settings) get_Settings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRemoteDesktopClientActions** actions) get_Actions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRemoteDesktopClientTouchPointer** touchPointer) get_TouchPointer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR serverName) DeleteSavedCredentials;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 width, uint32 height) UpdateSessionDisplaySettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR eventName, IDispatch* callback) attachEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR eventName, IDispatch* callback) detachEvent;
	}


	public HRESULT Connect() mut => VT.[Friend]Connect(&this);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);

	public HRESULT Reconnect(uint32 width, uint32 height) mut => VT.[Friend]Reconnect(&this, width, height);

	public HRESULT get_Settings(IRemoteDesktopClientSettings** settings) mut => VT.[Friend]get_Settings(&this, settings);

	public HRESULT get_Actions(IRemoteDesktopClientActions** actions) mut => VT.[Friend]get_Actions(&this, actions);

	public HRESULT get_TouchPointer(IRemoteDesktopClientTouchPointer** touchPointer) mut => VT.[Friend]get_TouchPointer(&this, touchPointer);

	public HRESULT DeleteSavedCredentials(BSTR serverName) mut => VT.[Friend]DeleteSavedCredentials(&this, serverName);

	public HRESULT UpdateSessionDisplaySettings(uint32 width, uint32 height) mut => VT.[Friend]UpdateSessionDisplaySettings(&this, width, height);

	public HRESULT attachEvent(BSTR eventName, IDispatch* callback) mut => VT.[Friend]attachEvent(&this, eventName, callback);

	public HRESULT detachEvent(BSTR eventName, IDispatch* callback) mut => VT.[Friend]detachEvent(&this, eventName, callback);
}

[CRepr]struct IRemoteSystemAdditionalInfoProvider : IUnknown
{
	public new const Guid IID = .(0xeeaa3d5f, 0xec63, 0x4d27, 0xaf, 0x38, 0xe8, 0x6b, 0x1d, 0x72, 0x92, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HSTRING* deduplicationId, in Guid riid, void** mapView) GetAdditionalInfo;
	}


	public HRESULT GetAdditionalInfo(HSTRING* deduplicationId, in Guid riid, void** mapView) mut => VT.[Friend]GetAdditionalInfo(&this, deduplicationId, riid, mapView);
}

#endregion

#region Functions
public static
{
	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSStopRemoteControlSession(uint32 LogonId);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSStartRemoteControlSessionW(PWSTR pTargetServerName, uint32 TargetLogonId, uint8 HotkeyVk, uint16 HotkeyModifiers);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSStartRemoteControlSessionA(PSTR pTargetServerName, uint32 TargetLogonId, uint8 HotkeyVk, uint16 HotkeyModifiers);
	public static BOOL WTSStartRemoteControlSession(PSTR pTargetServerName, uint32 TargetLogonId, uint8 HotkeyVk, uint16 HotkeyModifiers) => WTSStartRemoteControlSessionA(pTargetServerName, TargetLogonId, HotkeyVk, HotkeyModifiers);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSConnectSessionA(uint32 LogonId, uint32 TargetLogonId, PSTR pPassword, BOOL bWait);
	public static BOOL WTSConnectSession(uint32 LogonId, uint32 TargetLogonId, PSTR pPassword, BOOL bWait) => WTSConnectSessionA(LogonId, TargetLogonId, pPassword, bWait);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSConnectSessionW(uint32 LogonId, uint32 TargetLogonId, PWSTR pPassword, BOOL bWait);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateServersW(PWSTR pDomainName, uint32 Reserved, uint32 Version, WTS_SERVER_INFOW** ppServerInfo, uint32* pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateServersA(PSTR pDomainName, uint32 Reserved, uint32 Version, WTS_SERVER_INFOA** ppServerInfo, uint32* pCount);
	public static BOOL WTSEnumerateServers(PSTR pDomainName, uint32 Reserved, uint32 Version, WTS_SERVER_INFOA** ppServerInfo, uint32* pCount) => WTSEnumerateServersA(pDomainName, Reserved, Version, ppServerInfo, pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WTSOpenServerW(PWSTR pServerName);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WTSOpenServerA(PSTR pServerName);
	public static HANDLE WTSOpenServer(PSTR pServerName) => WTSOpenServerA(pServerName);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WTSOpenServerExW(PWSTR pServerName);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE WTSOpenServerExA(PSTR pServerName);
	public static HANDLE WTSOpenServerEx(PSTR pServerName) => WTSOpenServerExA(pServerName);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WTSCloseServer(HANDLE hServer);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateSessionsW(HANDLE hServer, uint32 Reserved, uint32 Version, WTS_SESSION_INFOW** ppSessionInfo, uint32* pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateSessionsA(HANDLE hServer, uint32 Reserved, uint32 Version, WTS_SESSION_INFOA** ppSessionInfo, uint32* pCount);
	public static BOOL WTSEnumerateSessions(HANDLE hServer, uint32 Reserved, uint32 Version, WTS_SESSION_INFOA** ppSessionInfo, uint32* pCount) => WTSEnumerateSessionsA(hServer, Reserved, Version, ppSessionInfo, pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateSessionsExW(HANDLE hServer, uint32* pLevel, uint32 Filter, WTS_SESSION_INFO_1W** ppSessionInfo, uint32* pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateSessionsExA(HANDLE hServer, uint32* pLevel, uint32 Filter, WTS_SESSION_INFO_1A** ppSessionInfo, uint32* pCount);
	public static BOOL WTSEnumerateSessionsEx(HANDLE hServer, uint32* pLevel, uint32 Filter, WTS_SESSION_INFO_1A** ppSessionInfo, uint32* pCount) => WTSEnumerateSessionsExA(hServer, pLevel, Filter, ppSessionInfo, pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateProcessesW(HANDLE hServer, uint32 Reserved, uint32 Version, WTS_PROCESS_INFOW** ppProcessInfo, uint32* pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateProcessesA(HANDLE hServer, uint32 Reserved, uint32 Version, WTS_PROCESS_INFOA** ppProcessInfo, uint32* pCount);
	public static BOOL WTSEnumerateProcesses(HANDLE hServer, uint32 Reserved, uint32 Version, WTS_PROCESS_INFOA** ppProcessInfo, uint32* pCount) => WTSEnumerateProcessesA(hServer, Reserved, Version, ppProcessInfo, pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSTerminateProcess(HANDLE hServer, uint32 ProcessId, uint32 ExitCode);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSQuerySessionInformationW(HANDLE hServer, uint32 SessionId, WTS_INFO_CLASS WTSInfoClass, PWSTR* ppBuffer, uint32* pBytesReturned);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSQuerySessionInformationA(HANDLE hServer, uint32 SessionId, WTS_INFO_CLASS WTSInfoClass, PSTR* ppBuffer, uint32* pBytesReturned);
	public static BOOL WTSQuerySessionInformation(HANDLE hServer, uint32 SessionId, WTS_INFO_CLASS WTSInfoClass, PSTR* ppBuffer, uint32* pBytesReturned) => WTSQuerySessionInformationA(hServer, SessionId, WTSInfoClass, ppBuffer, pBytesReturned);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSQueryUserConfigW(PWSTR pServerName, PWSTR pUserName, WTS_CONFIG_CLASS WTSConfigClass, PWSTR* ppBuffer, uint32* pBytesReturned);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSQueryUserConfigA(PSTR pServerName, PSTR pUserName, WTS_CONFIG_CLASS WTSConfigClass, PSTR* ppBuffer, uint32* pBytesReturned);
	public static BOOL WTSQueryUserConfig(PSTR pServerName, PSTR pUserName, WTS_CONFIG_CLASS WTSConfigClass, PSTR* ppBuffer, uint32* pBytesReturned) => WTSQueryUserConfigA(pServerName, pUserName, WTSConfigClass, ppBuffer, pBytesReturned);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSSetUserConfigW(PWSTR pServerName, PWSTR pUserName, WTS_CONFIG_CLASS WTSConfigClass, PWSTR pBuffer, uint32 DataLength);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSSetUserConfigA(PSTR pServerName, PSTR pUserName, WTS_CONFIG_CLASS WTSConfigClass, PSTR pBuffer, uint32 DataLength);
	public static BOOL WTSSetUserConfig(PSTR pServerName, PSTR pUserName, WTS_CONFIG_CLASS WTSConfigClass, PSTR pBuffer, uint32 DataLength) => WTSSetUserConfigA(pServerName, pUserName, WTSConfigClass, pBuffer, DataLength);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSSendMessageW(HANDLE hServer, uint32 SessionId, PWSTR pTitle, uint32 TitleLength, PWSTR pMessage, uint32 MessageLength, MESSAGEBOX_STYLE Style, uint32 Timeout, MESSAGEBOX_RESULT* pResponse, BOOL bWait);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSSendMessageA(HANDLE hServer, uint32 SessionId, PSTR pTitle, uint32 TitleLength, PSTR pMessage, uint32 MessageLength, MESSAGEBOX_STYLE Style, uint32 Timeout, MESSAGEBOX_RESULT* pResponse, BOOL bWait);
	public static BOOL WTSSendMessage(HANDLE hServer, uint32 SessionId, PSTR pTitle, uint32 TitleLength, PSTR pMessage, uint32 MessageLength, MESSAGEBOX_STYLE Style, uint32 Timeout, MESSAGEBOX_RESULT* pResponse, BOOL bWait) => WTSSendMessageA(hServer, SessionId, pTitle, TitleLength, pMessage, MessageLength, Style, Timeout, pResponse, bWait);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSDisconnectSession(HANDLE hServer, uint32 SessionId, BOOL bWait);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSLogoffSession(HANDLE hServer, uint32 SessionId, BOOL bWait);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSShutdownSystem(HANDLE hServer, uint32 ShutdownFlag);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSWaitSystemEvent(HANDLE hServer, uint32 EventMask, uint32* pEventFlags);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HwtsVirtualChannelHandle WTSVirtualChannelOpen(HANDLE hServer, uint32 SessionId, PSTR pVirtualName);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HwtsVirtualChannelHandle WTSVirtualChannelOpenEx(uint32 SessionId, PSTR pVirtualName, uint32 flags);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSVirtualChannelClose(HANDLE hChannelHandle);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSVirtualChannelRead(HANDLE hChannelHandle, uint32 TimeOut, PSTR Buffer, uint32 BufferSize, uint32* pBytesRead);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSVirtualChannelWrite(HANDLE hChannelHandle, PSTR Buffer, uint32 Length, uint32* pBytesWritten);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSVirtualChannelPurgeInput(HANDLE hChannelHandle);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSVirtualChannelPurgeOutput(HANDLE hChannelHandle);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSVirtualChannelQuery(HANDLE hChannelHandle, WTS_VIRTUAL_CLASS param1, void** ppBuffer, uint32* pBytesReturned);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WTSFreeMemory(void* pMemory);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSRegisterSessionNotification(HWND hWnd, uint32 dwFlags);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSUnRegisterSessionNotification(HWND hWnd);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSRegisterSessionNotificationEx(HANDLE hServer, HWND hWnd, uint32 dwFlags);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSUnRegisterSessionNotificationEx(HANDLE hServer, HWND hWnd);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSQueryUserToken(uint32 SessionId, HANDLE* phToken);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSFreeMemoryExW(WTS_TYPE_CLASS WTSTypeClass, void* pMemory, uint32 NumberOfEntries);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSFreeMemoryExA(WTS_TYPE_CLASS WTSTypeClass, void* pMemory, uint32 NumberOfEntries);
	public static BOOL WTSFreeMemoryEx(WTS_TYPE_CLASS WTSTypeClass, void* pMemory, uint32 NumberOfEntries) => WTSFreeMemoryExA(WTSTypeClass, pMemory, NumberOfEntries);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateProcessesExW(HANDLE hServer, uint32* pLevel, uint32 SessionId, PWSTR* ppProcessInfo, uint32* pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateProcessesExA(HANDLE hServer, uint32* pLevel, uint32 SessionId, PSTR* ppProcessInfo, uint32* pCount);
	public static BOOL WTSEnumerateProcessesEx(HANDLE hServer, uint32* pLevel, uint32 SessionId, PSTR* ppProcessInfo, uint32* pCount) => WTSEnumerateProcessesExA(hServer, pLevel, SessionId, ppProcessInfo, pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateListenersW(HANDLE hServer, void* pReserved, uint32 Reserved, uint16** pListeners, uint32* pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnumerateListenersA(HANDLE hServer, void* pReserved, uint32 Reserved, int8** pListeners, uint32* pCount);
	public static BOOL WTSEnumerateListeners(HANDLE hServer, void* pReserved, uint32 Reserved, int8** pListeners, uint32* pCount) => WTSEnumerateListenersA(hServer, pReserved, Reserved, pListeners, pCount);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSQueryListenerConfigW(HANDLE hServer, void* pReserved, uint32 Reserved, PWSTR pListenerName, WTSLISTENERCONFIGW* pBuffer);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSQueryListenerConfigA(HANDLE hServer, void* pReserved, uint32 Reserved, PSTR pListenerName, WTSLISTENERCONFIGA* pBuffer);
	public static BOOL WTSQueryListenerConfig(HANDLE hServer, void* pReserved, uint32 Reserved, PSTR pListenerName, WTSLISTENERCONFIGA* pBuffer) => WTSQueryListenerConfigA(hServer, pReserved, Reserved, pListenerName, pBuffer);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSCreateListenerW(HANDLE hServer, void* pReserved, uint32 Reserved, PWSTR pListenerName, WTSLISTENERCONFIGW* pBuffer, uint32 flag);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSCreateListenerA(HANDLE hServer, void* pReserved, uint32 Reserved, PSTR pListenerName, WTSLISTENERCONFIGA* pBuffer, uint32 flag);
	public static BOOL WTSCreateListener(HANDLE hServer, void* pReserved, uint32 Reserved, PSTR pListenerName, WTSLISTENERCONFIGA* pBuffer, uint32 flag) => WTSCreateListenerA(hServer, pReserved, Reserved, pListenerName, pBuffer, flag);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSSetListenerSecurityW(HANDLE hServer, void* pReserved, uint32 Reserved, PWSTR pListenerName, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSSetListenerSecurityA(HANDLE hServer, void* pReserved, uint32 Reserved, PSTR pListenerName, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor);
	public static BOOL WTSSetListenerSecurity(HANDLE hServer, void* pReserved, uint32 Reserved, PSTR pListenerName, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor) => WTSSetListenerSecurityA(hServer, pReserved, Reserved, pListenerName, SecurityInformation, pSecurityDescriptor);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSGetListenerSecurityW(HANDLE hServer, void* pReserved, uint32 Reserved, PWSTR pListenerName, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32 nLength, uint32* lpnLengthNeeded);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSGetListenerSecurityA(HANDLE hServer, void* pReserved, uint32 Reserved, PSTR pListenerName, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32 nLength, uint32* lpnLengthNeeded);
	public static BOOL WTSGetListenerSecurity(HANDLE hServer, void* pReserved, uint32 Reserved, PSTR pListenerName, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32 nLength, uint32* lpnLengthNeeded) => WTSGetListenerSecurityA(hServer, pReserved, Reserved, pListenerName, SecurityInformation, pSecurityDescriptor, nLength, lpnLengthNeeded);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSEnableChildSessions(BOOL bEnable);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSIsChildSessionsEnabled(BOOL* pbEnabled);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTSGetChildSessionId(uint32* pSessionId);

	[Import("WTSAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WTSSetRenderHint(uint64* pRenderHintID, HWND hwndOwner, uint32 renderHintType, uint32 cbHintDataLength, uint8* pHintData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ProcessIdToSessionId(uint32 dwProcessId, uint32* pSessionId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WTSGetActiveConsoleSessionId();

}
#endregion
