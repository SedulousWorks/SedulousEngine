using Win32.Foundation;
using Win32.Devices.Properties;
using Win32.Graphics.Gdi;
using Win32.UI.Controls;
using Win32.System.Com;
using Win32.System.IO;
using Win32.System.Registry;
using System;

namespace Win32.Devices.Fax;

#region Constants
public static
{
	public const uint32 prv_DEFAULT_PREFETCH_SIZE = 100;
	public const uint32 FS_INITIALIZING = 536870912;
	public const uint32 FS_DIALING = 536870913;
	public const uint32 FS_TRANSMITTING = 536870914;
	public const uint32 FS_RECEIVING = 536870916;
	public const uint32 FS_COMPLETED = 536870920;
	public const uint32 FS_HANDLED = 536870928;
	public const uint32 FS_LINE_UNAVAILABLE = 536870944;
	public const uint32 FS_BUSY = 536870976;
	public const uint32 FS_NO_ANSWER = 536871040;
	public const uint32 FS_BAD_ADDRESS = 536871168;
	public const uint32 FS_NO_DIAL_TONE = 536871424;
	public const uint32 FS_DISCONNECTED = 536871936;
	public const uint32 FS_FATAL_ERROR = 536872960;
	public const uint32 FS_NOT_FAX_CALL = 536875008;
	public const uint32 FS_CALL_DELAYED = 536879104;
	public const uint32 FS_CALL_BLACKLISTED = 536887296;
	public const uint32 FS_USER_ABORT = 538968064;
	public const uint32 FS_ANSWERED = 545259520;
	public const uint32 FAXDEVRECEIVE_SIZE = 4096;
	public const uint32 FAXDEVREPORTSTATUS_SIZE = 4096;
	public const String MS_FAXROUTE_PRINTING_GUID = "{aec1b37c-9af2-11d0-abf7-00c04fd91a4e}";
	public const String MS_FAXROUTE_FOLDER_GUID = "{92041a90-9af2-11d0-abf7-00c04fd91a4e}";
	public const String MS_FAXROUTE_EMAIL_GUID = "{6bbf7bfe-9af2-11d0-abf7-00c04fd91a4e}";
	public const int32 FAX_ERR_START = 7001;
	public const int32 FAX_ERR_SRV_OUTOFMEMORY = 7001;
	public const int32 FAX_ERR_GROUP_NOT_FOUND = 7002;
	public const int32 FAX_ERR_BAD_GROUP_CONFIGURATION = 7003;
	public const int32 FAX_ERR_GROUP_IN_USE = 7004;
	public const int32 FAX_ERR_RULE_NOT_FOUND = 7005;
	public const int32 FAX_ERR_NOT_NTFS = 7006;
	public const int32 FAX_ERR_DIRECTORY_IN_USE = 7007;
	public const int32 FAX_ERR_FILE_ACCESS_DENIED = 7008;
	public const int32 FAX_ERR_MESSAGE_NOT_FOUND = 7009;
	public const int32 FAX_ERR_DEVICE_NUM_LIMIT_EXCEEDED = 7010;
	public const int32 FAX_ERR_NOT_SUPPORTED_ON_THIS_SKU = 7011;
	public const int32 FAX_ERR_VERSION_MISMATCH = 7012;
	public const int32 FAX_ERR_RECIPIENTS_LIMIT = 7013;
	public const int32 FAX_ERR_END = 7013;
	public const HRESULT FAX_E_SRV_OUTOFMEMORY = -2147214503;
	public const HRESULT FAX_E_GROUP_NOT_FOUND = -2147214502;
	public const HRESULT FAX_E_BAD_GROUP_CONFIGURATION = -2147214501;
	public const HRESULT FAX_E_GROUP_IN_USE = -2147214500;
	public const HRESULT FAX_E_RULE_NOT_FOUND = -2147214499;
	public const HRESULT FAX_E_NOT_NTFS = -2147214498;
	public const HRESULT FAX_E_DIRECTORY_IN_USE = -2147214497;
	public const HRESULT FAX_E_FILE_ACCESS_DENIED = -2147214496;
	public const HRESULT FAX_E_MESSAGE_NOT_FOUND = -2147214495;
	public const HRESULT FAX_E_DEVICE_NUM_LIMIT_EXCEEDED = -2147214494;
	public const HRESULT FAX_E_NOT_SUPPORTED_ON_THIS_SKU = -2147214493;
	public const HRESULT FAX_E_VERSION_MISMATCH = -2147214492;
	public const HRESULT FAX_E_RECIPIENTS_LIMIT = -2147214491;
	public const uint32 JT_UNKNOWN = 0;
	public const uint32 JT_SEND = 1;
	public const uint32 JT_RECEIVE = 2;
	public const uint32 JT_ROUTING = 3;
	public const uint32 JT_FAIL_RECEIVE = 4;
	public const uint32 JS_PENDING = 0;
	public const uint32 JS_INPROGRESS = 1;
	public const uint32 JS_DELETING = 2;
	public const uint32 JS_FAILED = 4;
	public const uint32 JS_PAUSED = 8;
	public const uint32 JS_NOLINE = 16;
	public const uint32 JS_RETRYING = 32;
	public const uint32 JS_RETRIES_EXCEEDED = 64;
	public const uint32 FPS_DIALING = 536870913;
	public const uint32 FPS_SENDING = 536870914;
	public const uint32 FPS_RECEIVING = 536870916;
	public const uint32 FPS_COMPLETED = 536870920;
	public const uint32 FPS_HANDLED = 536870928;
	public const uint32 FPS_UNAVAILABLE = 536870944;
	public const uint32 FPS_BUSY = 536870976;
	public const uint32 FPS_NO_ANSWER = 536871040;
	public const uint32 FPS_BAD_ADDRESS = 536871168;
	public const uint32 FPS_NO_DIAL_TONE = 536871424;
	public const uint32 FPS_DISCONNECTED = 536871936;
	public const uint32 FPS_FATAL_ERROR = 536872960;
	public const uint32 FPS_NOT_FAX_CALL = 536875008;
	public const uint32 FPS_CALL_DELAYED = 536879104;
	public const uint32 FPS_CALL_BLACKLISTED = 536887296;
	public const uint32 FPS_INITIALIZING = 536903680;
	public const uint32 FPS_OFFLINE = 536936448;
	public const uint32 FPS_RINGING = 537001984;
	public const uint32 FPS_AVAILABLE = 537919488;
	public const uint32 FPS_ABORTING = 538968064;
	public const uint32 FPS_ROUTING = 541065216;
	public const uint32 FPS_ANSWERED = 545259520;
	public const uint32 FPF_RECEIVE = 1;
	public const uint32 FPF_SEND = 2;
	public const uint32 FPF_VIRTUAL = 4;
	public const uint32 FEI_DIALING = 1;
	public const uint32 FEI_SENDING = 2;
	public const uint32 FEI_RECEIVING = 3;
	public const uint32 FEI_COMPLETED = 4;
	public const uint32 FEI_BUSY = 5;
	public const uint32 FEI_NO_ANSWER = 6;
	public const uint32 FEI_BAD_ADDRESS = 7;
	public const uint32 FEI_NO_DIAL_TONE = 8;
	public const uint32 FEI_DISCONNECTED = 9;
	public const uint32 FEI_FATAL_ERROR = 10;
	public const uint32 FEI_NOT_FAX_CALL = 11;
	public const uint32 FEI_CALL_DELAYED = 12;
	public const uint32 FEI_CALL_BLACKLISTED = 13;
	public const uint32 FEI_RINGING = 14;
	public const uint32 FEI_ABORTING = 15;
	public const uint32 FEI_ROUTING = 16;
	public const uint32 FEI_MODEM_POWERED_ON = 17;
	public const uint32 FEI_MODEM_POWERED_OFF = 18;
	public const uint32 FEI_IDLE = 19;
	public const uint32 FEI_FAXSVC_ENDED = 20;
	public const uint32 FEI_ANSWERED = 21;
	public const uint32 FEI_JOB_QUEUED = 22;
	public const uint32 FEI_DELETED = 23;
	public const uint32 FEI_INITIALIZING = 24;
	public const uint32 FEI_LINE_UNAVAILABLE = 25;
	public const uint32 FEI_HANDLED = 26;
	public const uint32 FEI_FAXSVC_STARTED = 27;
	public const uint32 FEI_NEVENTS = 27;
	public const uint32 FAX_JOB_SUBMIT = 1;
	public const uint32 FAX_JOB_QUERY = 2;
	public const uint32 FAX_CONFIG_QUERY = 4;
	public const uint32 FAX_CONFIG_SET = 8;
	public const uint32 FAX_PORT_QUERY = 16;
	public const uint32 FAX_PORT_SET = 32;
	public const uint32 FAX_JOB_MANAGE = 64;
	public const String CF_MSFAXSRV_DEVICE_ID = "FAXSRV_DeviceID";
	public const String CF_MSFAXSRV_FSP_GUID = "FAXSRV_FSPGuid";
	public const String CF_MSFAXSRV_SERVER_NAME = "FAXSRV_ServerName";
	public const String CF_MSFAXSRV_ROUTEEXT_NAME = "FAXSRV_RoutingExtName";
	public const String CF_MSFAXSRV_ROUTING_METHOD_GUID = "FAXSRV_RoutingMethodGuid";
	public const uint32 STI_UNICODE = 1;
	public const Guid CLSID_Sti = .(0xb323f8e0, 0x2e68, 0x11d0, 0x90, 0xea, 0x00, 0xaa, 0x00, 0x60, 0xf8, 0x6c);
	public const Guid GUID_DeviceArrivedLaunch = .(0x740d9ee6, 0x70f1, 0x11d1, 0xad, 0x10, 0x00, 0xa0, 0x24, 0x38, 0xad, 0x48);
	public const Guid GUID_ScanImage = .(0xa6c5a715, 0x8c6e, 0x11d2, 0x97, 0x7a, 0x00, 0x00, 0xf8, 0x7a, 0x92, 0x6f);
	public const Guid GUID_ScanPrintImage = .(0xb441f425, 0x8c6e, 0x11d2, 0x97, 0x7a, 0x00, 0x00, 0xf8, 0x7a, 0x92, 0x6f);
	public const Guid GUID_ScanFaxImage = .(0xc00eb793, 0x8c6e, 0x11d2, 0x97, 0x7a, 0x00, 0x00, 0xf8, 0x7a, 0x92, 0x6f);
	public const Guid GUID_STIUserDefined1 = .(0xc00eb795, 0x8c6e, 0x11d2, 0x97, 0x7a, 0x00, 0x00, 0xf8, 0x7a, 0x92, 0x6f);
	public const Guid GUID_STIUserDefined2 = .(0xc77ae9c5, 0x8c6e, 0x11d2, 0x97, 0x7a, 0x00, 0x00, 0xf8, 0x7a, 0x92, 0x6f);
	public const Guid GUID_STIUserDefined3 = .(0xc77ae9c6, 0x8c6e, 0x11d2, 0x97, 0x7a, 0x00, 0x00, 0xf8, 0x7a, 0x92, 0x6f);
	public const uint32 STI_VERSION_FLAG_MASK = 4278190080;
	public const uint32 STI_VERSION_FLAG_UNICODE = 16777216;
	public const uint32 STI_VERSION_REAL = 2;
	public const uint32 STI_VERSION_MIN_ALLOWED = 2;
	public const uint32 STI_VERSION = 2;
	public const uint32 STI_MAX_INTERNAL_NAME_LENGTH = 128;
	public const uint32 STI_GENCAP_NOTIFICATIONS = 1;
	public const uint32 STI_GENCAP_POLLING_NEEDED = 2;
	public const uint32 STI_GENCAP_GENERATE_ARRIVALEVENT = 4;
	public const uint32 STI_GENCAP_AUTO_PORTSELECT = 8;
	public const uint32 STI_GENCAP_WIA = 16;
	public const uint32 STI_GENCAP_SUBSET = 32;
	public const uint32 WIA_INCOMPAT_XP = 1;
	public const uint32 STI_HW_CONFIG_UNKNOWN = 1;
	public const uint32 STI_HW_CONFIG_SCSI = 2;
	public const uint32 STI_HW_CONFIG_USB = 4;
	public const uint32 STI_HW_CONFIG_SERIAL = 8;
	public const uint32 STI_HW_CONFIG_PARALLEL = 16;
	public const uint32 STI_DEVSTATUS_ONLINE_STATE = 1;
	public const uint32 STI_DEVSTATUS_EVENTS_STATE = 2;
	public const uint32 STI_ONLINESTATE_OPERATIONAL = 1;
	public const uint32 STI_ONLINESTATE_PENDING = 2;
	public const uint32 STI_ONLINESTATE_ERROR = 4;
	public const uint32 STI_ONLINESTATE_PAUSED = 8;
	public const uint32 STI_ONLINESTATE_PAPER_JAM = 16;
	public const uint32 STI_ONLINESTATE_PAPER_PROBLEM = 32;
	public const uint32 STI_ONLINESTATE_OFFLINE = 64;
	public const uint32 STI_ONLINESTATE_IO_ACTIVE = 128;
	public const uint32 STI_ONLINESTATE_BUSY = 256;
	public const uint32 STI_ONLINESTATE_TRANSFERRING = 512;
	public const uint32 STI_ONLINESTATE_INITIALIZING = 1024;
	public const uint32 STI_ONLINESTATE_WARMING_UP = 2048;
	public const uint32 STI_ONLINESTATE_USER_INTERVENTION = 4096;
	public const uint32 STI_ONLINESTATE_POWER_SAVE = 8192;
	public const uint32 STI_EVENTHANDLING_ENABLED = 1;
	public const uint32 STI_EVENTHANDLING_POLLING = 2;
	public const uint32 STI_EVENTHANDLING_PENDING = 4;
	public const uint32 STI_DIAGCODE_HWPRESENCE = 1;
	public const uint32 STI_TRACE_INFORMATION = 1;
	public const uint32 STI_TRACE_WARNING = 2;
	public const uint32 STI_TRACE_ERROR = 4;
	public const uint32 STI_SUBSCRIBE_FLAG_WINDOW = 1;
	public const uint32 STI_SUBSCRIBE_FLAG_EVENT = 2;
	public const uint32 MAX_NOTIFICATION_DATA = 64;
	public const String STI_ADD_DEVICE_BROADCAST_ACTION = "Arrival";
	public const String STI_REMOVE_DEVICE_BROADCAST_ACTION = "Removal";
	public const String STI_ADD_DEVICE_BROADCAST_STRING = "STI\\";
	public const String STI_REMOVE_DEVICE_BROADCAST_STRING = "STI\\";
	public const uint32 STI_DEVICE_CREATE_STATUS = 1;
	public const uint32 STI_DEVICE_CREATE_DATA = 2;
	public const uint32 STI_DEVICE_CREATE_BOTH = 3;
	public const uint32 STI_DEVICE_CREATE_MASK = 65535;
	public const uint32 STIEDFL_ALLDEVICES = 0;
	public const uint32 STIEDFL_ATTACHEDONLY = 1;
	public const uint32 STI_RAW_RESERVED = 4096;
	public const int32 STI_OK = 0;
	public const int32 STI_ERROR_NO_ERROR = 0;
	public const int32 STI_NOTCONNECTED = 1;
	public const int32 STI_CHANGENOEFFECT = 1;
	public const HRESULT STIERR_OLD_VERSION = -2147023746;
	public const HRESULT STIERR_BETA_VERSION = -2147023743;
	public const HRESULT STIERR_BADDRIVER = -2147024777;
	public const int32 STIERR_DEVICENOTREG = -2147221164;
	public const HRESULT STIERR_OBJECTNOTFOUND = -2147024894;
	public const int32 STIERR_INVALID_PARAM = -2147024809;
	public const int32 STIERR_NOINTERFACE = -2147467262;
	public const int32 STIERR_GENERIC = -2147467259;
	public const int32 STIERR_OUTOFMEMORY = -2147024882;
	public const int32 STIERR_UNSUPPORTED = -2147467263;
	public const HRESULT STIERR_NOT_INITIALIZED = -2147024875;
	public const HRESULT STIERR_ALREADY_INITIALIZED = -2147023649;
	public const HRESULT STIERR_DEVICE_LOCKED = -2147024863;
	public const int32 STIERR_READONLY = -2147024891;
	public const int32 STIERR_NOTINITIALIZED = -2147024891;
	public const HRESULT STIERR_NEEDS_LOCK = -2147024738;
	public const HRESULT STIERR_SHARING_VIOLATION = -2147024864;
	public const HRESULT STIERR_HANDLEEXISTS = -2147024713;
	public const HRESULT STIERR_INVALID_DEVICE_NAME = -2147024773;
	public const HRESULT STIERR_INVALID_HW_TYPE = -2147024883;
	public const HRESULT STIERR_NOEVENTS = -2147024637;
	public const HRESULT STIERR_DEVICE_NOTREADY = -2147024875;
	public const String REGSTR_VAL_TYPE_W = "Type";
	public const String REGSTR_VAL_VENDOR_NAME_W = "Vendor";
	public const String REGSTR_VAL_DEVICETYPE_W = "DeviceType";
	public const String REGSTR_VAL_DEVICESUBTYPE_W = "DeviceSubType";
	public const String REGSTR_VAL_DEV_NAME_W = "DeviceName";
	public const String REGSTR_VAL_DRIVER_DESC_W = "DriverDesc";
	public const String REGSTR_VAL_FRIENDLY_NAME_W = "FriendlyName";
	public const String REGSTR_VAL_GENERIC_CAPS_W = "Capabilities";
	public const String REGSTR_VAL_HARDWARE_W = "HardwareConfig";
	public const String REGSTR_VAL_HARDWARE = "HardwareConfig";
	public const String REGSTR_VAL_DEVICE_NAME_W = "DriverDesc";
	public const String REGSTR_VAL_DATA_W = "DeviceData";
	public const String REGSTR_VAL_GUID_W = "GUID";
	public const String REGSTR_VAL_GUID = "GUID";
	public const String REGSTR_VAL_LAUNCH_APPS_W = "LaunchApplications";
	public const String REGSTR_VAL_LAUNCH_APPS = "LaunchApplications";
	public const String REGSTR_VAL_LAUNCHABLE_W = "Launchable";
	public const String REGSTR_VAL_LAUNCHABLE = "Launchable";
	public const String REGSTR_VAL_SHUTDOWNDELAY_W = "ShutdownIfUnusedDelay";
	public const String REGSTR_VAL_SHUTDOWNDELAY = "ShutdownIfUnusedDelay";
	public const String IS_DIGITAL_CAMERA_STR = "IsDigitalCamera";
	public const uint32 IS_DIGITAL_CAMERA_VAL = 1;
	public const String SUPPORTS_MSCPLUS_STR = "SupportsMSCPlus";
	public const uint32 SUPPORTS_MSCPLUS_VAL = 1;
	public const String STI_DEVICE_VALUE_TWAIN_NAME = "TwainDS";
	public const String STI_DEVICE_VALUE_ISIS_NAME = "ISISDriverName";
	public const String STI_DEVICE_VALUE_ICM_PROFILE = "ICMProfile";
	public const String STI_DEVICE_VALUE_DEFAULT_LAUNCHAPP = "DefaultLaunchApp";
	public const String STI_DEVICE_VALUE_TIMEOUT = "PollTimeout";
	public const String STI_DEVICE_VALUE_DISABLE_NOTIFICATIONS = "DisableNotifications";
	public const String REGSTR_VAL_BAUDRATE = "BaudRate";
	public const String STI_DEVICE_VALUE_TWAIN_NAME_A = "TwainDS";
	public const String STI_DEVICE_VALUE_ISIS_NAME_A = "ISISDriverName";
	public const String STI_DEVICE_VALUE_ICM_PROFILE_A = "ICMProfile";
	public const String STI_DEVICE_VALUE_DEFAULT_LAUNCHAPP_A = "DefaultLaunchApp";
	public const String STI_DEVICE_VALUE_TIMEOUT_A = "PollTimeout";
	public const String STI_DEVICE_VALUE_DISABLE_NOTIFICATIONS_A = "DisableNotifications";
	public const String REGSTR_VAL_BAUDRATE_A = "BaudRate";
	public const DEVPROPKEY DEVPKEY_WIA_DeviceType = .(.(0x6bdd1fc6, 0x810f, 0x11d0, 0xbe, 0xc7, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f), 2);
	public const DEVPROPKEY DEVPKEY_WIA_USDClassId = .(.(0x6bdd1fc6, 0x810f, 0x11d0, 0xbe, 0xc7, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f), 3);
	public const uint32 STI_USD_GENCAP_NATIVE_PUSHSUPPORT = 1;
	public const uint32 STI_DEVICE_CREATE_FOR_MONITOR = 16777216;
	public const int32 lDEFAULT_PREFETCH_SIZE = 100;
	public const uint16 wcharREASSIGN_RECIPIENTS_DELIMITER = 59;
}
#endregion

#region Enums

[AllowDuplicates]
public enum FAX_ENUM_LOG_LEVELS : int32
{
	FAXLOG_LEVEL_NONE = 0,
	FAXLOG_LEVEL_MIN = 1,
	FAXLOG_LEVEL_MED = 2,
	FAXLOG_LEVEL_MAX = 3,
}


[AllowDuplicates]
public enum FAX_ENUM_LOG_CATEGORIES : int32
{
	FAXLOG_CATEGORY_INIT = 1,
	FAXLOG_CATEGORY_OUTBOUND = 2,
	FAXLOG_CATEGORY_INBOUND = 3,
	FAXLOG_CATEGORY_UNKNOWN = 4,
}


[AllowDuplicates]
public enum FAX_ENUM_JOB_COMMANDS : int32
{
	JC_UNKNOWN = 0,
	JC_DELETE = 1,
	JC_PAUSE = 2,
	JC_RESUME = 3,
}


[AllowDuplicates]
public enum FAX_ENUM_JOB_SEND_ATTRIBUTES : int32
{
	JSA_NOW = 0,
	JSA_SPECIFIC_TIME = 1,
	JSA_DISCOUNT_PERIOD = 2,
}


[AllowDuplicates]
public enum FAX_ENUM_DELIVERY_REPORT_TYPES : int32
{
	DRT_NONE = 0,
	DRT_EMAIL = 1,
	DRT_INBOX = 2,
}


[AllowDuplicates]
public enum FAX_ENUM_PORT_OPEN_TYPE : int32
{
	PORT_OPEN_QUERY = 1,
	PORT_OPEN_MODIFY = 2,
}


[AllowDuplicates]
public enum FAX_JOB_STATUS_ENUM : int32
{
	fjsPENDING = 1,
	fjsINPROGRESS = 2,
	fjsFAILED = 8,
	fjsPAUSED = 16,
	fjsNOLINE = 32,
	fjsRETRYING = 64,
	fjsRETRIES_EXCEEDED = 128,
	fjsCOMPLETED = 256,
	fjsCANCELED = 512,
	fjsCANCELING = 1024,
	fjsROUTING = 2048,
}


[AllowDuplicates]
public enum FAX_JOB_EXTENDED_STATUS_ENUM : int32
{
	fjesNONE = 0,
	fjesDISCONNECTED = 1,
	fjesINITIALIZING = 2,
	fjesDIALING = 3,
	fjesTRANSMITTING = 4,
	fjesANSWERED = 5,
	fjesRECEIVING = 6,
	fjesLINE_UNAVAILABLE = 7,
	fjesBUSY = 8,
	fjesNO_ANSWER = 9,
	fjesBAD_ADDRESS = 10,
	fjesNO_DIAL_TONE = 11,
	fjesFATAL_ERROR = 12,
	fjesCALL_DELAYED = 13,
	fjesCALL_BLACKLISTED = 14,
	fjesNOT_FAX_CALL = 15,
	fjesPARTIALLY_RECEIVED = 16,
	fjesHANDLED = 17,
	fjesCALL_COMPLETED = 18,
	fjesCALL_ABORTED = 19,
	fjesPROPRIETARY = 16777216,
}


[AllowDuplicates]
public enum FAX_JOB_OPERATIONS_ENUM : int32
{
	fjoVIEW = 1,
	fjoPAUSE = 2,
	fjoRESUME = 4,
	fjoRESTART = 8,
	fjoDELETE = 16,
	fjoRECIPIENT_INFO = 32,
	fjoSENDER_INFO = 64,
}


[AllowDuplicates]
public enum FAX_JOB_TYPE_ENUM : int32
{
	fjtSEND = 0,
	fjtRECEIVE = 1,
	fjtROUTING = 2,
}


[AllowDuplicates]
public enum FAX_SERVER_EVENTS_TYPE_ENUM : int32
{
	fsetNONE = 0,
	fsetIN_QUEUE = 1,
	fsetOUT_QUEUE = 2,
	fsetCONFIG = 4,
	fsetACTIVITY = 8,
	fsetQUEUE_STATE = 16,
	fsetIN_ARCHIVE = 32,
	fsetOUT_ARCHIVE = 64,
	fsetFXSSVC_ENDED = 128,
	fsetDEVICE_STATUS = 256,
	fsetINCOMING_CALL = 512,
}


[AllowDuplicates]
public enum FAX_SERVER_APIVERSION_ENUM : int32
{
	fsAPI_VERSION_0 = 0,
	fsAPI_VERSION_1 = 65536,
	fsAPI_VERSION_2 = 131072,
	fsAPI_VERSION_3 = 196608,
}


[AllowDuplicates]
public enum FAX_SMTP_AUTHENTICATION_TYPE_ENUM : int32
{
	fsatANONYMOUS = 0,
	fsatBASIC = 1,
	fsatNTLM = 2,
}


[AllowDuplicates]
public enum FAX_RECEIPT_TYPE_ENUM : int32
{
	frtNONE = 0,
	frtMAIL = 1,
	frtMSGBOX = 4,
}


[AllowDuplicates]
public enum FAX_ACCESS_RIGHTS_ENUM : int32
{
	farSUBMIT_LOW = 1,
	farSUBMIT_NORMAL = 2,
	farSUBMIT_HIGH = 4,
	farQUERY_JOBS = 8,
	farMANAGE_JOBS = 16,
	farQUERY_CONFIG = 32,
	farMANAGE_CONFIG = 64,
	farQUERY_IN_ARCHIVE = 128,
	farMANAGE_IN_ARCHIVE = 256,
	farQUERY_OUT_ARCHIVE = 512,
	farMANAGE_OUT_ARCHIVE = 1024,
}


[AllowDuplicates]
public enum FAX_PRIORITY_TYPE_ENUM : int32
{
	fptLOW = 0,
	fptNORMAL = 1,
	fptHIGH = 2,
}


[AllowDuplicates]
public enum FAX_COVERPAGE_TYPE_ENUM : int32
{
	fcptNONE = 0,
	fcptLOCAL = 1,
	fcptSERVER = 2,
}


[AllowDuplicates]
public enum FAX_SCHEDULE_TYPE_ENUM : int32
{
	fstNOW = 0,
	fstSPECIFIC_TIME = 1,
	fstDISCOUNT_PERIOD = 2,
}


[AllowDuplicates]
public enum FAX_PROVIDER_STATUS_ENUM : int32
{
	fpsSUCCESS = 0,
	fpsSERVER_ERROR = 1,
	fpsBAD_GUID = 2,
	fpsBAD_VERSION = 3,
	fpsCANT_LOAD = 4,
	fpsCANT_LINK = 5,
	fpsCANT_INIT = 6,
}


[AllowDuplicates]
public enum FAX_DEVICE_RECEIVE_MODE_ENUM : int32
{
	fdrmNO_ANSWER = 0,
	fdrmAUTO_ANSWER = 1,
	fdrmMANUAL_ANSWER = 2,
}


[AllowDuplicates]
public enum FAX_LOG_LEVEL_ENUM : int32
{
	fllNONE = 0,
	fllMIN = 1,
	fllMED = 2,
	fllMAX = 3,
}


[AllowDuplicates]
public enum FAX_GROUP_STATUS_ENUM : int32
{
	fgsALL_DEV_VALID = 0,
	fgsEMPTY = 1,
	fgsALL_DEV_NOT_VALID = 2,
	fgsSOME_DEV_NOT_VALID = 3,
}


[AllowDuplicates]
public enum FAX_RULE_STATUS_ENUM : int32
{
	frsVALID = 0,
	frsEMPTY_GROUP = 1,
	frsALL_GROUP_DEV_NOT_VALID = 2,
	frsSOME_GROUP_DEV_NOT_VALID = 3,
	frsBAD_DEVICE = 4,
}


[AllowDuplicates]
public enum FAX_ACCOUNT_EVENTS_TYPE_ENUM : int32
{
	faetNONE = 0,
	faetIN_QUEUE = 1,
	faetOUT_QUEUE = 2,
	faetIN_ARCHIVE = 4,
	faetOUT_ARCHIVE = 8,
	faetFXSSVC_ENDED = 16,
}


[AllowDuplicates]
public enum FAX_ACCESS_RIGHTS_ENUM_2 : int32
{
	far2SUBMIT_LOW = 1,
	far2SUBMIT_NORMAL = 2,
	far2SUBMIT_HIGH = 4,
	far2QUERY_OUT_JOBS = 8,
	far2MANAGE_OUT_JOBS = 16,
	far2QUERY_CONFIG = 32,
	far2MANAGE_CONFIG = 64,
	far2QUERY_ARCHIVES = 128,
	far2MANAGE_ARCHIVES = 256,
	far2MANAGE_RECEIVE_FOLDER = 512,
}


[AllowDuplicates]
public enum FAX_ROUTING_RULE_CODE_ENUM : int32
{
	frrcANY_CODE = 0,
}


[AllowDuplicates]
public enum FAXROUTE_ENABLE : int32
{
	QUERY_STATUS = -1,
	STATUS_DISABLE = 0,
	STATUS_ENABLE = 1,
}


[AllowDuplicates]
public enum FAX_ENUM_DEVICE_ID_SOURCE : int32
{
	DEV_ID_SRC_FAX = 0,
	DEV_ID_SRC_TAPI = 1,
}


[AllowDuplicates]
public enum SendToMode : int32
{
	SEND_TO_FAX_RECIPIENT_ATTACHMENT = 0,
}


[AllowDuplicates]
public enum STI_DEVICE_MJ_TYPE : int32
{
	StiDeviceTypeDefault = 0,
	StiDeviceTypeScanner = 1,
	StiDeviceTypeDigitalCamera = 2,
	StiDeviceTypeStreamingVideo = 3,
}

#endregion

#region Function Pointers
public function BOOL PFAXCONNECTFAXSERVERA(PSTR MachineName, HANDLE* FaxHandle);

public function BOOL PFAXCONNECTFAXSERVERW(PWSTR MachineName, HANDLE* FaxHandle);

public function BOOL PFAXCLOSE(HANDLE FaxHandle);

public function BOOL PFAXOPENPORT(HANDLE FaxHandle, uint32 DeviceId, uint32 Flags, HANDLE* FaxPortHandle);

public function BOOL PFAXCOMPLETEJOBPARAMSA(FAX_JOB_PARAMA** JobParams, FAX_COVERPAGE_INFOA** CoverpageInfo);

public function BOOL PFAXCOMPLETEJOBPARAMSW(FAX_JOB_PARAMW** JobParams, FAX_COVERPAGE_INFOW** CoverpageInfo);

public function BOOL PFAXSENDDOCUMENTA(HANDLE FaxHandle, PSTR FileName, FAX_JOB_PARAMA* JobParams, FAX_COVERPAGE_INFOA* CoverpageInfo, uint32* FaxJobId);

public function BOOL PFAXSENDDOCUMENTW(HANDLE FaxHandle, PWSTR FileName, FAX_JOB_PARAMW* JobParams, FAX_COVERPAGE_INFOW* CoverpageInfo, uint32* FaxJobId);

public function BOOL PFAX_RECIPIENT_CALLBACKA(HANDLE FaxHandle, uint32 RecipientNumber, void* Context, FAX_JOB_PARAMA* JobParams, FAX_COVERPAGE_INFOA* CoverpageInfo);

public function BOOL PFAX_RECIPIENT_CALLBACKW(HANDLE FaxHandle, uint32 RecipientNumber, void* Context, FAX_JOB_PARAMW* JobParams, FAX_COVERPAGE_INFOW* CoverpageInfo);

public function BOOL PFAXSENDDOCUMENTFORBROADCASTA(HANDLE FaxHandle, PSTR FileName, uint32* FaxJobId, PFAX_RECIPIENT_CALLBACKA FaxRecipientCallback, void* Context);

public function BOOL PFAXSENDDOCUMENTFORBROADCASTW(HANDLE FaxHandle, PWSTR FileName, uint32* FaxJobId, PFAX_RECIPIENT_CALLBACKW FaxRecipientCallback, void* Context);

public function BOOL PFAXENUMJOBSA(HANDLE FaxHandle, FAX_JOB_ENTRYA** JobEntry, uint32* JobsReturned);

public function BOOL PFAXENUMJOBSW(HANDLE FaxHandle, FAX_JOB_ENTRYW** JobEntry, uint32* JobsReturned);

public function BOOL PFAXGETJOBA(HANDLE FaxHandle, uint32 JobId, FAX_JOB_ENTRYA** JobEntry);

public function BOOL PFAXGETJOBW(HANDLE FaxHandle, uint32 JobId, FAX_JOB_ENTRYW** JobEntry);

public function BOOL PFAXSETJOBA(HANDLE FaxHandle, uint32 JobId, uint32 Command, FAX_JOB_ENTRYA* JobEntry);

public function BOOL PFAXSETJOBW(HANDLE FaxHandle, uint32 JobId, uint32 Command, FAX_JOB_ENTRYW* JobEntry);

public function BOOL PFAXGETPAGEDATA(HANDLE FaxHandle, uint32 JobId, uint8** Buffer, uint32* BufferSize, uint32* ImageWidth, uint32* ImageHeight);

public function BOOL PFAXGETDEVICESTATUSA(HANDLE FaxPortHandle, FAX_DEVICE_STATUSA** DeviceStatus);

public function BOOL PFAXGETDEVICESTATUSW(HANDLE FaxPortHandle, FAX_DEVICE_STATUSW** DeviceStatus);

public function BOOL PFAXABORT(HANDLE FaxHandle, uint32 JobId);

public function BOOL PFAXGETCONFIGURATIONA(HANDLE FaxHandle, FAX_CONFIGURATIONA** FaxConfig);

public function BOOL PFAXGETCONFIGURATIONW(HANDLE FaxHandle, FAX_CONFIGURATIONW** FaxConfig);

public function BOOL PFAXSETCONFIGURATIONA(HANDLE FaxHandle, FAX_CONFIGURATIONA* FaxConfig);

public function BOOL PFAXSETCONFIGURATIONW(HANDLE FaxHandle, FAX_CONFIGURATIONW* FaxConfig);

public function BOOL PFAXGETLOGGINGCATEGORIESA(HANDLE FaxHandle, FAX_LOG_CATEGORYA** Categories, uint32* NumberCategories);

public function BOOL PFAXGETLOGGINGCATEGORIESW(HANDLE FaxHandle, FAX_LOG_CATEGORYW** Categories, uint32* NumberCategories);

public function BOOL PFAXSETLOGGINGCATEGORIESA(HANDLE FaxHandle, FAX_LOG_CATEGORYA* Categories, uint32 NumberCategories);

public function BOOL PFAXSETLOGGINGCATEGORIESW(HANDLE FaxHandle, FAX_LOG_CATEGORYW* Categories, uint32 NumberCategories);

public function BOOL PFAXENUMPORTSA(HANDLE FaxHandle, FAX_PORT_INFOA** PortInfo, uint32* PortsReturned);

public function BOOL PFAXENUMPORTSW(HANDLE FaxHandle, FAX_PORT_INFOW** PortInfo, uint32* PortsReturned);

public function BOOL PFAXGETPORTA(HANDLE FaxPortHandle, FAX_PORT_INFOA** PortInfo);

public function BOOL PFAXGETPORTW(HANDLE FaxPortHandle, FAX_PORT_INFOW** PortInfo);

public function BOOL PFAXSETPORTA(HANDLE FaxPortHandle, FAX_PORT_INFOA* PortInfo);

public function BOOL PFAXSETPORTW(HANDLE FaxPortHandle, FAX_PORT_INFOW* PortInfo);

public function BOOL PFAXENUMROUTINGMETHODSA(HANDLE FaxPortHandle, FAX_ROUTING_METHODA** RoutingMethod, uint32* MethodsReturned);

public function BOOL PFAXENUMROUTINGMETHODSW(HANDLE FaxPortHandle, FAX_ROUTING_METHODW** RoutingMethod, uint32* MethodsReturned);

public function BOOL PFAXENABLEROUTINGMETHODA(HANDLE FaxPortHandle, PSTR RoutingGuid, BOOL Enabled);

public function BOOL PFAXENABLEROUTINGMETHODW(HANDLE FaxPortHandle, PWSTR RoutingGuid, BOOL Enabled);

public function BOOL PFAXENUMGLOBALROUTINGINFOA(HANDLE FaxHandle, FAX_GLOBAL_ROUTING_INFOA** RoutingInfo, uint32* MethodsReturned);

public function BOOL PFAXENUMGLOBALROUTINGINFOW(HANDLE FaxHandle, FAX_GLOBAL_ROUTING_INFOW** RoutingInfo, uint32* MethodsReturned);

public function BOOL PFAXSETGLOBALROUTINGINFOA(HANDLE FaxPortHandle, FAX_GLOBAL_ROUTING_INFOA* RoutingInfo);

public function BOOL PFAXSETGLOBALROUTINGINFOW(HANDLE FaxPortHandle, FAX_GLOBAL_ROUTING_INFOW* RoutingInfo);

public function BOOL PFAXGETROUTINGINFOA(HANDLE FaxPortHandle, PSTR RoutingGuid, uint8** RoutingInfoBuffer, uint32* RoutingInfoBufferSize);

public function BOOL PFAXGETROUTINGINFOW(HANDLE FaxPortHandle, PWSTR RoutingGuid, uint8** RoutingInfoBuffer, uint32* RoutingInfoBufferSize);

public function BOOL PFAXSETROUTINGINFOA(HANDLE FaxPortHandle, PSTR RoutingGuid, uint8* RoutingInfoBuffer, uint32 RoutingInfoBufferSize);

public function BOOL PFAXSETROUTINGINFOW(HANDLE FaxPortHandle, PWSTR RoutingGuid, uint8* RoutingInfoBuffer, uint32 RoutingInfoBufferSize);

public function BOOL PFAXINITIALIZEEVENTQUEUE(HANDLE FaxHandle, HANDLE CompletionPort, uint CompletionKey, HWND hWnd, uint32 MessageStart);

public function void PFAXFREEBUFFER(void* Buffer);

public function BOOL PFAXSTARTPRINTJOBA(PSTR PrinterName, FAX_PRINT_INFOA* PrintInfo, uint32* FaxJobId, FAX_CONTEXT_INFOA* FaxContextInfo);

public function BOOL PFAXSTARTPRINTJOBW(PWSTR PrinterName, FAX_PRINT_INFOW* PrintInfo, uint32* FaxJobId, FAX_CONTEXT_INFOW* FaxContextInfo);

public function BOOL PFAXPRINTCOVERPAGEA(FAX_CONTEXT_INFOA* FaxContextInfo, FAX_COVERPAGE_INFOA* CoverPageInfo);

public function BOOL PFAXPRINTCOVERPAGEW(FAX_CONTEXT_INFOW* FaxContextInfo, FAX_COVERPAGE_INFOW* CoverPageInfo);

public function BOOL PFAXREGISTERSERVICEPROVIDERW(PWSTR DeviceProvider, PWSTR FriendlyName, PWSTR ImageName, PWSTR TspName);

public function BOOL PFAXUNREGISTERSERVICEPROVIDERW(PWSTR DeviceProvider);

public function BOOL PFAX_ROUTING_INSTALLATION_CALLBACKW(HANDLE FaxHandle, void* Context, PWSTR MethodName, PWSTR FriendlyName, PWSTR FunctionName, PWSTR Guid);

public function BOOL PFAXREGISTERROUTINGEXTENSIONW(HANDLE FaxHandle, PWSTR ExtensionName, PWSTR FriendlyName, PWSTR ImageName, PFAX_ROUTING_INSTALLATION_CALLBACKW CallBack, void* Context);

public function BOOL PFAXACCESSCHECK(HANDLE FaxHandle, uint32 AccessMask);

public function BOOL PFAX_SERVICE_CALLBACK(HANDLE FaxHandle, uint32 DeviceId, uint Param1, uint Param2, uint Param3);

public function void PFAX_LINECALLBACK(HANDLE FaxHandle, uint32 hDevice, uint32 dwMessage, uint dwInstance, uint dwParam1, uint dwParam2, uint dwParam3);

public function BOOL PFAX_SEND_CALLBACK(HANDLE FaxHandle, uint32 CallHandle, uint32 Reserved1, uint32 Reserved2);

public function BOOL PFAXDEVINITIALIZE(uint32 param0, HANDLE param1, PFAX_LINECALLBACK* param2, PFAX_SERVICE_CALLBACK param3);

public function BOOL PFAXDEVVIRTUALDEVICECREATION(uint32* DeviceCount, char16* DeviceNamePrefix, uint32* DeviceIdPrefix, HANDLE CompletionPort, uint CompletionKey);

public function BOOL PFAXDEVSTARTJOB(uint32 param0, uint32 param1, HANDLE* param2, HANDLE param3, uint param4);

public function BOOL PFAXDEVENDJOB(HANDLE param0);

public function BOOL PFAXDEVSEND(HANDLE param0, FAX_SEND* param1, PFAX_SEND_CALLBACK param2);

public function BOOL PFAXDEVRECEIVE(HANDLE param0, uint32 param1, FAX_RECEIVE* param2);

public function BOOL PFAXDEVREPORTSTATUS(HANDLE param0, FAX_DEV_STATUS* param1, uint32 param2, uint32* param3);

public function BOOL PFAXDEVABORTOPERATION(HANDLE param0);

public function BOOL PFAXDEVCONFIGURE(HPROPSHEETPAGE* param0);

public function HRESULT PFAXDEVSHUTDOWN();

public function int32 PFAXROUTEADDFILE(uint32 JobId, PWSTR FileName, Guid* Guid);

public function int32 PFAXROUTEDELETEFILE(uint32 JobId, PWSTR FileName);

public function BOOL PFAXROUTEGETFILE(uint32 JobId, uint32 Index, PWSTR FileNameBuffer, uint32* RequiredSize);

public function BOOL PFAXROUTEENUMFILE(uint32 JobId, Guid* GuidOwner, Guid* GuidCaller, PWSTR FileName, void* Context);

public function BOOL PFAXROUTEENUMFILES(uint32 JobId, Guid* Guid, PFAXROUTEENUMFILE FileEnumerator, void* Context);

public function BOOL PFAXROUTEMODIFYROUTINGDATA(uint32 JobId, PWSTR RoutingGuid, uint8* RoutingData, uint32 RoutingDataSize);

public function BOOL PFAXROUTEINITIALIZE(HANDLE param0, FAX_ROUTE_CALLBACKROUTINES* param1);

public function BOOL PFAXROUTEMETHOD(FAX_ROUTE* param0, void** param1, uint32* param2);

public function BOOL PFAXROUTEDEVICEENABLE(PWSTR param0, uint32 param1, int32 param2);

public function BOOL PFAXROUTEDEVICECHANGENOTIFICATION(uint32 param0, BOOL param1);

public function BOOL PFAXROUTEGETROUTINGINFO(PWSTR param0, uint32 param1, uint8* param2, uint32* param3);

public function BOOL PFAXROUTESETROUTINGINFO(PWSTR param0, uint32 param1, uint8* param2, uint32 param3);

public function uint32 PFAX_EXT_GET_DATA(uint32 param0, FAX_ENUM_DEVICE_ID_SOURCE param1, PWSTR param2, uint8** param3, uint32* param4);

public function uint32 PFAX_EXT_SET_DATA(HINSTANCE param0, uint32 param1, FAX_ENUM_DEVICE_ID_SOURCE param2, PWSTR param3, uint8* param4, uint32 param5);

public function HRESULT PFAX_EXT_CONFIG_CHANGE(uint32 param0, PWSTR param1, uint8* param2, uint32 param3);

public function HANDLE PFAX_EXT_REGISTER_FOR_EVENTS(HINSTANCE param0, uint32 param1, FAX_ENUM_DEVICE_ID_SOURCE param2, PWSTR param3, PFAX_EXT_CONFIG_CHANGE param4);

public function uint32 PFAX_EXT_UNREGISTER_FOR_EVENTS(HANDLE param0);

public function void PFAX_EXT_FREE_BUFFER(void* param0);

public function HRESULT PFAX_EXT_INITIALIZE_CONFIG(PFAX_EXT_GET_DATA param0, PFAX_EXT_SET_DATA param1, PFAX_EXT_REGISTER_FOR_EVENTS param2, PFAX_EXT_UNREGISTER_FOR_EVENTS param3, PFAX_EXT_FREE_BUFFER param4);

#endregion

#region Structs
[CRepr]
public struct FAX_LOG_CATEGORYA
{
	public PSTR Name;
	public uint32 Category;
	public uint32 Level;
}

[CRepr]
public struct FAX_LOG_CATEGORYW
{
	public PWSTR Name;
	public uint32 Category;
	public uint32 Level;
}

[CRepr]
public struct FAX_TIME
{
	public uint16 Hour;
	public uint16 Minute;
}

[CRepr]
public struct FAX_CONFIGURATIONA
{
	public uint32 SizeOfStruct;
	public uint32 Retries;
	public uint32 RetryDelay;
	public uint32 DirtyDays;
	public BOOL Branding;
	public BOOL UseDeviceTsid;
	public BOOL ServerCp;
	public BOOL PauseServerQueue;
	public FAX_TIME StartCheapTime;
	public FAX_TIME StopCheapTime;
	public BOOL ArchiveOutgoingFaxes;
	public PSTR ArchiveDirectory;
	public PSTR Reserved;
}

[CRepr]
public struct FAX_CONFIGURATIONW
{
	public uint32 SizeOfStruct;
	public uint32 Retries;
	public uint32 RetryDelay;
	public uint32 DirtyDays;
	public BOOL Branding;
	public BOOL UseDeviceTsid;
	public BOOL ServerCp;
	public BOOL PauseServerQueue;
	public FAX_TIME StartCheapTime;
	public FAX_TIME StopCheapTime;
	public BOOL ArchiveOutgoingFaxes;
	public PWSTR ArchiveDirectory;
	public PWSTR Reserved;
}

[CRepr]
public struct FAX_DEVICE_STATUSA
{
	public uint32 SizeOfStruct;
	public PSTR CallerId;
	public PSTR Csid;
	public uint32 CurrentPage;
	public uint32 DeviceId;
	public PSTR DeviceName;
	public PSTR DocumentName;
	public uint32 JobType;
	public PSTR PhoneNumber;
	public PSTR RoutingString;
	public PSTR SenderName;
	public PSTR RecipientName;
	public uint32 Size;
	public FILETIME StartTime;
	public uint32 Status;
	public PSTR StatusString;
	public FILETIME SubmittedTime;
	public uint32 TotalPages;
	public PSTR Tsid;
	public PSTR UserName;
}

[CRepr]
public struct FAX_DEVICE_STATUSW
{
	public uint32 SizeOfStruct;
	public PWSTR CallerId;
	public PWSTR Csid;
	public uint32 CurrentPage;
	public uint32 DeviceId;
	public PWSTR DeviceName;
	public PWSTR DocumentName;
	public uint32 JobType;
	public PWSTR PhoneNumber;
	public PWSTR RoutingString;
	public PWSTR SenderName;
	public PWSTR RecipientName;
	public uint32 Size;
	public FILETIME StartTime;
	public uint32 Status;
	public PWSTR StatusString;
	public FILETIME SubmittedTime;
	public uint32 TotalPages;
	public PWSTR Tsid;
	public PWSTR UserName;
}

[CRepr]
public struct FAX_JOB_ENTRYA
{
	public uint32 SizeOfStruct;
	public uint32 JobId;
	public PSTR UserName;
	public uint32 JobType;
	public uint32 QueueStatus;
	public uint32 Status;
	public uint32 Size;
	public uint32 PageCount;
	public PSTR RecipientNumber;
	public PSTR RecipientName;
	public PSTR Tsid;
	public PSTR SenderName;
	public PSTR SenderCompany;
	public PSTR SenderDept;
	public PSTR BillingCode;
	public uint32 ScheduleAction;
	public SYSTEMTIME ScheduleTime;
	public uint32 DeliveryReportType;
	public PSTR DeliveryReportAddress;
	public PSTR DocumentName;
}

[CRepr]
public struct FAX_JOB_ENTRYW
{
	public uint32 SizeOfStruct;
	public uint32 JobId;
	public PWSTR UserName;
	public uint32 JobType;
	public uint32 QueueStatus;
	public uint32 Status;
	public uint32 Size;
	public uint32 PageCount;
	public PWSTR RecipientNumber;
	public PWSTR RecipientName;
	public PWSTR Tsid;
	public PWSTR SenderName;
	public PWSTR SenderCompany;
	public PWSTR SenderDept;
	public PWSTR BillingCode;
	public uint32 ScheduleAction;
	public SYSTEMTIME ScheduleTime;
	public uint32 DeliveryReportType;
	public PWSTR DeliveryReportAddress;
	public PWSTR DocumentName;
}

[CRepr]
public struct FAX_PORT_INFOA
{
	public uint32 SizeOfStruct;
	public uint32 DeviceId;
	public uint32 State;
	public uint32 Flags;
	public uint32 Rings;
	public uint32 Priority;
	public PSTR DeviceName;
	public PSTR Tsid;
	public PSTR Csid;
}

[CRepr]
public struct FAX_PORT_INFOW
{
	public uint32 SizeOfStruct;
	public uint32 DeviceId;
	public uint32 State;
	public uint32 Flags;
	public uint32 Rings;
	public uint32 Priority;
	public PWSTR DeviceName;
	public PWSTR Tsid;
	public PWSTR Csid;
}

[CRepr]
public struct FAX_ROUTING_METHODA
{
	public uint32 SizeOfStruct;
	public uint32 DeviceId;
	public BOOL Enabled;
	public PSTR DeviceName;
	public PSTR Guid;
	public PSTR FriendlyName;
	public PSTR FunctionName;
	public PSTR ExtensionImageName;
	public PSTR ExtensionFriendlyName;
}

[CRepr]
public struct FAX_ROUTING_METHODW
{
	public uint32 SizeOfStruct;
	public uint32 DeviceId;
	public BOOL Enabled;
	public PWSTR DeviceName;
	public PWSTR Guid;
	public PWSTR FriendlyName;
	public PWSTR FunctionName;
	public PWSTR ExtensionImageName;
	public PWSTR ExtensionFriendlyName;
}

[CRepr]
public struct FAX_GLOBAL_ROUTING_INFOA
{
	public uint32 SizeOfStruct;
	public uint32 Priority;
	public PSTR Guid;
	public PSTR FriendlyName;
	public PSTR FunctionName;
	public PSTR ExtensionImageName;
	public PSTR ExtensionFriendlyName;
}

[CRepr]
public struct FAX_GLOBAL_ROUTING_INFOW
{
	public uint32 SizeOfStruct;
	public uint32 Priority;
	public PWSTR Guid;
	public PWSTR FriendlyName;
	public PWSTR FunctionName;
	public PWSTR ExtensionImageName;
	public PWSTR ExtensionFriendlyName;
}

[CRepr]
public struct FAX_COVERPAGE_INFOA
{
	public uint32 SizeOfStruct;
	public PSTR CoverPageName;
	public BOOL UseServerCoverPage;
	public PSTR RecName;
	public PSTR RecFaxNumber;
	public PSTR RecCompany;
	public PSTR RecStreetAddress;
	public PSTR RecCity;
	public PSTR RecState;
	public PSTR RecZip;
	public PSTR RecCountry;
	public PSTR RecTitle;
	public PSTR RecDepartment;
	public PSTR RecOfficeLocation;
	public PSTR RecHomePhone;
	public PSTR RecOfficePhone;
	public PSTR SdrName;
	public PSTR SdrFaxNumber;
	public PSTR SdrCompany;
	public PSTR SdrAddress;
	public PSTR SdrTitle;
	public PSTR SdrDepartment;
	public PSTR SdrOfficeLocation;
	public PSTR SdrHomePhone;
	public PSTR SdrOfficePhone;
	public PSTR Note;
	public PSTR Subject;
	public SYSTEMTIME TimeSent;
	public uint32 PageCount;
}

[CRepr]
public struct FAX_COVERPAGE_INFOW
{
	public uint32 SizeOfStruct;
	public PWSTR CoverPageName;
	public BOOL UseServerCoverPage;
	public PWSTR RecName;
	public PWSTR RecFaxNumber;
	public PWSTR RecCompany;
	public PWSTR RecStreetAddress;
	public PWSTR RecCity;
	public PWSTR RecState;
	public PWSTR RecZip;
	public PWSTR RecCountry;
	public PWSTR RecTitle;
	public PWSTR RecDepartment;
	public PWSTR RecOfficeLocation;
	public PWSTR RecHomePhone;
	public PWSTR RecOfficePhone;
	public PWSTR SdrName;
	public PWSTR SdrFaxNumber;
	public PWSTR SdrCompany;
	public PWSTR SdrAddress;
	public PWSTR SdrTitle;
	public PWSTR SdrDepartment;
	public PWSTR SdrOfficeLocation;
	public PWSTR SdrHomePhone;
	public PWSTR SdrOfficePhone;
	public PWSTR Note;
	public PWSTR Subject;
	public SYSTEMTIME TimeSent;
	public uint32 PageCount;
}

[CRepr]
public struct FAX_JOB_PARAMA
{
	public uint32 SizeOfStruct;
	public PSTR RecipientNumber;
	public PSTR RecipientName;
	public PSTR Tsid;
	public PSTR SenderName;
	public PSTR SenderCompany;
	public PSTR SenderDept;
	public PSTR BillingCode;
	public uint32 ScheduleAction;
	public SYSTEMTIME ScheduleTime;
	public uint32 DeliveryReportType;
	public PSTR DeliveryReportAddress;
	public PSTR DocumentName;
	public uint32 CallHandle;
	public uint[3] Reserved;
}

[CRepr]
public struct FAX_JOB_PARAMW
{
	public uint32 SizeOfStruct;
	public PWSTR RecipientNumber;
	public PWSTR RecipientName;
	public PWSTR Tsid;
	public PWSTR SenderName;
	public PWSTR SenderCompany;
	public PWSTR SenderDept;
	public PWSTR BillingCode;
	public uint32 ScheduleAction;
	public SYSTEMTIME ScheduleTime;
	public uint32 DeliveryReportType;
	public PWSTR DeliveryReportAddress;
	public PWSTR DocumentName;
	public uint32 CallHandle;
	public uint[3] Reserved;
}

[CRepr]
public struct FAX_EVENTA
{
	public uint32 SizeOfStruct;
	public FILETIME TimeStamp;
	public uint32 DeviceId;
	public uint32 EventId;
	public uint32 JobId;
}

[CRepr]
public struct FAX_EVENTW
{
	public uint32 SizeOfStruct;
	public FILETIME TimeStamp;
	public uint32 DeviceId;
	public uint32 EventId;
	public uint32 JobId;
}

[CRepr]
public struct FAX_PRINT_INFOA
{
	public uint32 SizeOfStruct;
	public PSTR DocName;
	public PSTR RecipientName;
	public PSTR RecipientNumber;
	public PSTR SenderName;
	public PSTR SenderCompany;
	public PSTR SenderDept;
	public PSTR SenderBillingCode;
	public PSTR Reserved;
	public PSTR DrEmailAddress;
	public PSTR OutputFileName;
}

[CRepr]
public struct FAX_PRINT_INFOW
{
	public uint32 SizeOfStruct;
	public PWSTR DocName;
	public PWSTR RecipientName;
	public PWSTR RecipientNumber;
	public PWSTR SenderName;
	public PWSTR SenderCompany;
	public PWSTR SenderDept;
	public PWSTR SenderBillingCode;
	public PWSTR Reserved;
	public PWSTR DrEmailAddress;
	public PWSTR OutputFileName;
}

[CRepr]
public struct FAX_CONTEXT_INFOA
{
	public uint32 SizeOfStruct;
	public HDC hDC;
	public CHAR[16] ServerName;
}

[CRepr]
public struct FAX_CONTEXT_INFOW
{
	public uint32 SizeOfStruct;
	public HDC hDC;
	public char16[16] ServerName;
}

[CRepr]
public struct FAX_SEND
{
	public uint32 SizeOfStruct;
	public PWSTR FileName;
	public PWSTR CallerName;
	public PWSTR CallerNumber;
	public PWSTR ReceiverName;
	public PWSTR ReceiverNumber;
	public BOOL Branding;
	public uint32 CallHandle;
	public uint32[3] Reserved;
}

[CRepr]
public struct FAX_RECEIVE
{
	public uint32 SizeOfStruct;
	public PWSTR FileName;
	public PWSTR ReceiverName;
	public PWSTR ReceiverNumber;
	public uint32[4] Reserved;
}

[CRepr]
public struct FAX_DEV_STATUS
{
	public uint32 SizeOfStruct;
	public uint32 StatusId;
	public uint32 StringId;
	public uint32 PageCount;
	public PWSTR CSI;
	public PWSTR CallerId;
	public PWSTR RoutingInfo;
	public uint32 ErrorCode;
	public uint32[3] Reserved;
}

[CRepr]
public struct FAX_ROUTE_CALLBACKROUTINES
{
	public uint32 SizeOfStruct;
	public PFAXROUTEADDFILE FaxRouteAddFile;
	public PFAXROUTEDELETEFILE FaxRouteDeleteFile;
	public PFAXROUTEGETFILE FaxRouteGetFile;
	public PFAXROUTEENUMFILES FaxRouteEnumFiles;
	public PFAXROUTEMODIFYROUTINGDATA FaxRouteModifyRoutingData;
}

[CRepr]
public struct FAX_ROUTE
{
	public uint32 SizeOfStruct;
	public uint32 JobId;
	public uint64 ElapsedTime;
	public uint64 ReceiveTime;
	public uint32 PageCount;
	public PWSTR Csid;
	public PWSTR Tsid;
	public PWSTR CallerId;
	public PWSTR RoutingInfo;
	public PWSTR ReceiverName;
	public PWSTR ReceiverNumber;
	public PWSTR DeviceName;
	public uint32 DeviceId;
	public uint8* RoutingInfoData;
	public uint32 RoutingInfoDataSize;
}

[CRepr]
public struct STI_DEV_CAPS
{
	public uint32 dwGeneric;
}

[CRepr]
public struct STI_DEVICE_INFORMATIONW
{
	public uint32 dwSize;
	public uint32 DeviceType;
	public char16[128] szDeviceInternalName;
	public STI_DEV_CAPS DeviceCapabilitiesA;
	public uint32 dwHardwareConfiguration;
	public PWSTR pszVendorDescription;
	public PWSTR pszDeviceDescription;
	public PWSTR pszPortName;
	public PWSTR pszPropProvider;
	public PWSTR pszLocalName;
}

[CRepr]
public struct STI_WIA_DEVICE_INFORMATIONW
{
	public uint32 dwSize;
	public uint32 DeviceType;
	public char16[128] szDeviceInternalName;
	public STI_DEV_CAPS DeviceCapabilitiesA;
	public uint32 dwHardwareConfiguration;
	public PWSTR pszVendorDescription;
	public PWSTR pszDeviceDescription;
	public PWSTR pszPortName;
	public PWSTR pszPropProvider;
	public PWSTR pszLocalName;
	public PWSTR pszUiDll;
	public PWSTR pszServer;
}

[CRepr]
public struct STI_DEVICE_STATUS
{
	public uint32 dwSize;
	public uint32 StatusMask;
	public uint32 dwOnlineState;
	public uint32 dwHardwareStatusCode;
	public uint32 dwEventHandlingState;
	public uint32 dwPollingInterval;
}

[CRepr]
public struct _ERROR_INFOW
{
	public uint32 dwSize;
	public uint32 dwGenericError;
	public uint32 dwVendorError;
	public char16[255] szExtendedErrorText;
}

[CRepr]
public struct STI_DIAG
{
	public uint32 dwSize;
	public uint32 dwBasicDiagCode;
	public uint32 dwVendorDiagCode;
	public uint32 dwStatusMask;
	public _ERROR_INFOW sErrorInfo;
}

[CRepr]
public struct STISUBSCRIBE
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwFilter;
	public HWND hWndNotify;
	public HANDLE hEvent;
	public uint32 uiNotificationMessage;
}

[CRepr]
public struct STINOTIFY
{
	public uint32 dwSize;
	public Guid guidNotificationCode;
	public uint8[64] abNotificationData;
}

[CRepr]
public struct STI_USD_CAPS
{
	public uint32 dwVersion;
	public uint32 dwGenericCaps;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_FaxServer = .(0xcda8acb0, 0x8cf5, 0x4f6c, 0x9b, 0xa2, 0x59, 0x31, 0xd4, 0x0c, 0x8c, 0xae);


	public const Guid CLSID_FaxDeviceProviders = .(0xeb8fe768, 0x875a, 0x4f5f, 0x82, 0xc5, 0x03, 0xf2, 0x3a, 0xac, 0x1b, 0xd7);


	public const Guid CLSID_FaxDevices = .(0x5589e28e, 0x23cb, 0x4919, 0x88, 0x08, 0xe6, 0x10, 0x18, 0x46, 0xe8, 0x0d);


	public const Guid CLSID_FaxInboundRouting = .(0xe80248ed, 0xad65, 0x4218, 0x81, 0x08, 0x99, 0x19, 0x24, 0xd4, 0xe7, 0xed);


	public const Guid CLSID_FaxFolders = .(0xc35211d7, 0x5776, 0x48cb, 0xaf, 0x44, 0xc3, 0x1b, 0xe3, 0xb2, 0xcf, 0xe5);


	public const Guid CLSID_FaxLoggingOptions = .(0x1bf9eea6, 0xece0, 0x4785, 0xa1, 0x8b, 0xde, 0x56, 0xe9, 0xee, 0xf9, 0x6a);


	public const Guid CLSID_FaxActivity = .(0xcfef5d0e, 0xe84d, 0x462e, 0xaa, 0xbb, 0x87, 0xd3, 0x1e, 0xb0, 0x4f, 0xef);


	public const Guid CLSID_FaxOutboundRouting = .(0xc81b385e, 0xb869, 0x4afd, 0x86, 0xc0, 0x61, 0x64, 0x98, 0xed, 0x9b, 0xe2);


	public const Guid CLSID_FaxReceiptOptions = .(0x6982487b, 0x227b, 0x4c96, 0xa6, 0x1c, 0x24, 0x83, 0x48, 0xb0, 0x5a, 0xb6);


	public const Guid CLSID_FaxSecurity = .(0x10c4ddde, 0xabf0, 0x43df, 0x96, 0x4f, 0x7f, 0x3a, 0xc2, 0x1a, 0x4c, 0x7b);


	public const Guid CLSID_FaxDocument = .(0x0f3f9f91, 0xc838, 0x415e, 0xa4, 0xf3, 0x3e, 0x82, 0x8c, 0xa4, 0x45, 0xe0);


	public const Guid CLSID_FaxSender = .(0x265d84d0, 0x1850, 0x4360, 0xb7, 0xc8, 0x75, 0x8b, 0xbb, 0x5f, 0x0b, 0x96);


	public const Guid CLSID_FaxRecipients = .(0xea9bdf53, 0x10a9, 0x4d4f, 0xa0, 0x67, 0x63, 0xc8, 0xf8, 0x4f, 0x01, 0xb0);


	public const Guid CLSID_FaxIncomingArchive = .(0x8426c56a, 0x35a1, 0x4c6f, 0xaf, 0x93, 0xfc, 0x95, 0x24, 0x22, 0xe2, 0xc2);


	public const Guid CLSID_FaxIncomingQueue = .(0x69131717, 0xf3f1, 0x40e3, 0x80, 0x9d, 0xa6, 0xcb, 0xf7, 0xbd, 0x85, 0xe5);


	public const Guid CLSID_FaxOutgoingArchive = .(0x43c28403, 0xe04f, 0x474d, 0x99, 0x0c, 0xb9, 0x46, 0x69, 0x14, 0x8f, 0x59);


	public const Guid CLSID_FaxOutgoingQueue = .(0x7421169e, 0x8c43, 0x4b0d, 0xbb, 0x16, 0x64, 0x5c, 0x8f, 0xa4, 0x03, 0x57);


	public const Guid CLSID_FaxIncomingMessageIterator = .(0x6088e1d8, 0x3fc8, 0x45c2, 0x87, 0xb1, 0x90, 0x9a, 0x29, 0x60, 0x7e, 0xa9);


	public const Guid CLSID_FaxIncomingMessage = .(0x1932fcf7, 0x9d43, 0x4d5a, 0x89, 0xff, 0x03, 0x86, 0x1b, 0x32, 0x17, 0x36);


	public const Guid CLSID_FaxOutgoingJobs = .(0x92bf2a6c, 0x37be, 0x43fa, 0xa3, 0x7d, 0xcb, 0x0e, 0x5f, 0x75, 0x3b, 0x35);


	public const Guid CLSID_FaxOutgoingJob = .(0x71bb429c, 0x0ef9, 0x4915, 0xbe, 0xc5, 0xa5, 0xd8, 0x97, 0xa3, 0xe9, 0x24);


	public const Guid CLSID_FaxOutgoingMessageIterator = .(0x8a3224d0, 0xd30b, 0x49de, 0x98, 0x13, 0xcb, 0x38, 0x57, 0x90, 0xfb, 0xbb);


	public const Guid CLSID_FaxOutgoingMessage = .(0x91b4a378, 0x4ad8, 0x4aef, 0xa4, 0xdc, 0x97, 0xd9, 0x6e, 0x93, 0x9a, 0x3a);


	public const Guid CLSID_FaxIncomingJobs = .(0xa1bb8a43, 0x8866, 0x4fb7, 0xa1, 0x5d, 0x62, 0x66, 0xc8, 0x75, 0xa5, 0xcc);


	public const Guid CLSID_FaxIncomingJob = .(0xc47311ec, 0xae32, 0x41b8, 0xae, 0x4b, 0x3e, 0xae, 0x06, 0x29, 0xd0, 0xc9);


	public const Guid CLSID_FaxDeviceProvider = .(0x17cf1aa3, 0xf5eb, 0x484a, 0x9c, 0x9a, 0x44, 0x40, 0xa5, 0xba, 0xab, 0xfc);


	public const Guid CLSID_FaxDevice = .(0x59e3a5b2, 0xd676, 0x484b, 0xa6, 0xde, 0x72, 0x0b, 0xfa, 0x89, 0xb5, 0xaf);


	public const Guid CLSID_FaxActivityLogging = .(0xf0a0294e, 0x3bbd, 0x48b8, 0x8f, 0x13, 0x8c, 0x59, 0x1a, 0x55, 0xbd, 0xbc);


	public const Guid CLSID_FaxEventLogging = .(0xa6850930, 0xa0f6, 0x4a6f, 0x95, 0xb7, 0xdb, 0x2e, 0xbf, 0x3d, 0x02, 0xe3);


	public const Guid CLSID_FaxOutboundRoutingGroups = .(0xccbea1a5, 0xe2b4, 0x4b57, 0x94, 0x21, 0xb0, 0x4b, 0x62, 0x89, 0x46, 0x4b);


	public const Guid CLSID_FaxOutboundRoutingGroup = .(0x0213f3e0, 0x6791, 0x4d77, 0xa2, 0x71, 0x04, 0xd2, 0x35, 0x7c, 0x50, 0xd6);


	public const Guid CLSID_FaxDeviceIds = .(0xcdc539ea, 0x7277, 0x460e, 0x8d, 0xe0, 0x48, 0xa0, 0xa5, 0x76, 0x0d, 0x1f);


	public const Guid CLSID_FaxOutboundRoutingRules = .(0xd385beca, 0xe624, 0x4473, 0xbf, 0xaa, 0x9f, 0x40, 0x00, 0x83, 0x1f, 0x54);


	public const Guid CLSID_FaxOutboundRoutingRule = .(0x6549eebf, 0x08d1, 0x475a, 0x82, 0x8b, 0x3b, 0xf1, 0x05, 0x95, 0x2f, 0xa0);


	public const Guid CLSID_FaxInboundRoutingExtensions = .(0x189a48ed, 0x623c, 0x4c0d, 0x80, 0xf2, 0xd6, 0x6c, 0x7b, 0x9e, 0xfe, 0xc2);


	public const Guid CLSID_FaxInboundRoutingExtension = .(0x1d7dfb51, 0x7207, 0x4436, 0xa0, 0xd9, 0x24, 0xe3, 0x2e, 0xe5, 0x69, 0x88);


	public const Guid CLSID_FaxInboundRoutingMethods = .(0x25fcb76a, 0xb750, 0x4b82, 0x92, 0x66, 0xfb, 0xbb, 0xae, 0x89, 0x22, 0xba);


	public const Guid CLSID_FaxInboundRoutingMethod = .(0x4b9fd75c, 0x0194, 0x4b72, 0x9c, 0xe5, 0x02, 0xa8, 0x20, 0x5a, 0xc7, 0xd4);


	public const Guid CLSID_FaxJobStatus = .(0x7bf222f4, 0xbe8d, 0x442f, 0x84, 0x1d, 0x61, 0x32, 0x74, 0x24, 0x23, 0xbb);


	public const Guid CLSID_FaxRecipient = .(0x60bf3301, 0x7df8, 0x4bd8, 0x91, 0x48, 0x7b, 0x58, 0x01, 0xf9, 0xef, 0xdf);


	public const Guid CLSID_FaxConfiguration = .(0x5857326f, 0xe7b3, 0x41a7, 0x9c, 0x19, 0xa9, 0x1b, 0x46, 0x3e, 0x2d, 0x56);


	public const Guid CLSID_FaxAccountSet = .(0xfbc23c4b, 0x79e0, 0x4291, 0xbc, 0x56, 0xc1, 0x2e, 0x25, 0x3b, 0xbf, 0x3a);


	public const Guid CLSID_FaxAccounts = .(0xda1f94aa, 0xee2c, 0x47c0, 0x8f, 0x4f, 0x2a, 0x21, 0x70, 0x75, 0xb7, 0x6e);


	public const Guid CLSID_FaxAccount = .(0xa7e0647f, 0x4524, 0x4464, 0xa5, 0x6d, 0xb9, 0xfe, 0x66, 0x6f, 0x71, 0x5e);


	public const Guid CLSID_FaxAccountFolders = .(0x85398f49, 0xc034, 0x4a3f, 0x82, 0x1c, 0xdb, 0x7d, 0x68, 0x5e, 0x81, 0x29);


	public const Guid CLSID_FaxAccountIncomingQueue = .(0x9bcf6094, 0xb4da, 0x45f4, 0xb8, 0xd6, 0xdd, 0xeb, 0x21, 0x86, 0x65, 0x2c);


	public const Guid CLSID_FaxAccountOutgoingQueue = .(0xfeeceefb, 0xc149, 0x48ba, 0xba, 0xb8, 0xb7, 0x91, 0xe1, 0x01, 0xf6, 0x2f);


	public const Guid CLSID_FaxAccountIncomingArchive = .(0x14b33db5, 0x4c40, 0x4ecf, 0x9e, 0xf8, 0xa3, 0x60, 0xcb, 0xe8, 0x09, 0xed);


	public const Guid CLSID_FaxAccountOutgoingArchive = .(0x851e7af5, 0x433a, 0x4739, 0xa2, 0xdf, 0xad, 0x24, 0x5c, 0x2c, 0xb9, 0x8e);


	public const Guid CLSID_FaxSecurity2 = .(0x735c1248, 0xec89, 0x4c30, 0xa1, 0x27, 0x65, 0x6e, 0x92, 0xe3, 0xc4, 0xea);


}
#endregion

#region COM Types
[CRepr]struct IFaxJobStatus : IDispatch
{
	public new const Guid IID = .(0x8b86f485, 0xfd7f, 0x4824, 0x88, 0x6b, 0x40, 0xc5, 0xca, 0xa6, 0x17, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_STATUS_ENUM* pStatus) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPages) get_Pages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSize) get_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCurrentPage) get_CurrentPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDeviceId) get_DeviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCSID) get_CSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTSID) get_TSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_EXTENDED_STATUS_ENUM* pExtendedStatusCode) get_ExtendedStatusCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrExtendedStatus) get_ExtendedStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_OPERATIONS_ENUM* pAvailableOperations) get_AvailableOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetries) get_Retries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_TYPE_ENUM* pJobType) get_JobType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateScheduledTime) get_ScheduledTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateTransmissionStart) get_TransmissionStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateTransmissionEnd) get_TransmissionEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCallerId) get_CallerId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrRoutingInformation) get_RoutingInformation;
	}


	public HRESULT get_Status(FAX_JOB_STATUS_ENUM* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);

	public HRESULT get_Pages(int32* plPages) mut => VT.[Friend]get_Pages(&this, plPages);

	public HRESULT get_Size(int32* plSize) mut => VT.[Friend]get_Size(&this, plSize);

	public HRESULT get_CurrentPage(int32* plCurrentPage) mut => VT.[Friend]get_CurrentPage(&this, plCurrentPage);

	public HRESULT get_DeviceId(int32* plDeviceId) mut => VT.[Friend]get_DeviceId(&this, plDeviceId);

	public HRESULT get_CSID(BSTR* pbstrCSID) mut => VT.[Friend]get_CSID(&this, pbstrCSID);

	public HRESULT get_TSID(BSTR* pbstrTSID) mut => VT.[Friend]get_TSID(&this, pbstrTSID);

	public HRESULT get_ExtendedStatusCode(FAX_JOB_EXTENDED_STATUS_ENUM* pExtendedStatusCode) mut => VT.[Friend]get_ExtendedStatusCode(&this, pExtendedStatusCode);

	public HRESULT get_ExtendedStatus(BSTR* pbstrExtendedStatus) mut => VT.[Friend]get_ExtendedStatus(&this, pbstrExtendedStatus);

	public HRESULT get_AvailableOperations(FAX_JOB_OPERATIONS_ENUM* pAvailableOperations) mut => VT.[Friend]get_AvailableOperations(&this, pAvailableOperations);

	public HRESULT get_Retries(int32* plRetries) mut => VT.[Friend]get_Retries(&this, plRetries);

	public HRESULT get_JobType(FAX_JOB_TYPE_ENUM* pJobType) mut => VT.[Friend]get_JobType(&this, pJobType);

	public HRESULT get_ScheduledTime(double* pdateScheduledTime) mut => VT.[Friend]get_ScheduledTime(&this, pdateScheduledTime);

	public HRESULT get_TransmissionStart(double* pdateTransmissionStart) mut => VT.[Friend]get_TransmissionStart(&this, pdateTransmissionStart);

	public HRESULT get_TransmissionEnd(double* pdateTransmissionEnd) mut => VT.[Friend]get_TransmissionEnd(&this, pdateTransmissionEnd);

	public HRESULT get_CallerId(BSTR* pbstrCallerId) mut => VT.[Friend]get_CallerId(&this, pbstrCallerId);

	public HRESULT get_RoutingInformation(BSTR* pbstrRoutingInformation) mut => VT.[Friend]get_RoutingInformation(&this, pbstrRoutingInformation);
}

[CRepr]struct IFaxServer : IDispatch
{
	public new const Guid IID = .(0x475b6469, 0x90a5, 0x4878, 0xa5, 0x77, 0x17, 0xa8, 0x6e, 0x8e, 0x34, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrServerName) get_ServerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxDeviceProviders** ppFaxDeviceProviders) GetDeviceProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxDevices** ppFaxDevices) GetDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxInboundRouting** ppFaxInboundRouting) get_InboundRouting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxFolders** pFaxFolders) get_Folders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxLoggingOptions** ppFaxLoggingOptions) get_LoggingOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMajorVersion) get_MajorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMinorVersion) get_MinorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMajorBuild) get_MajorBuild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMinorBuild) get_MinorBuild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbDebug) get_Debug;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxActivity** ppFaxActivity) get_Activity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxOutboundRouting** ppFaxOutboundRouting) get_OutboundRouting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxReceiptOptions** ppFaxReceiptOptions) get_ReceiptOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxSecurity** ppFaxSecurity) get_Security;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGUID, VARIANT* pvProperty) GetExtensionProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGUID, VARIANT vProperty) SetExtensionProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_SERVER_EVENTS_TYPE_ENUM EventTypes) ListenToServerEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGUID, BSTR bstrFriendlyName, BSTR bstrImageName, BSTR TspName, int32 lFSPIVersion) RegisterDeviceProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUniqueName) UnregisterDeviceProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrExtensionName, BSTR bstrFriendlyName, BSTR bstrImageName, VARIANT vMethods) RegisterInboundRoutingExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrExtensionUniqueName) UnregisterInboundRoutingExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_SERVER_EVENTS_TYPE_ENUM* pEventTypes) get_RegisteredEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_SERVER_APIVERSION_ENUM* pAPIVersion) get_APIVersion;
	}


	public HRESULT Connect(BSTR bstrServerName) mut => VT.[Friend]Connect(&this, bstrServerName);

	public HRESULT get_ServerName(BSTR* pbstrServerName) mut => VT.[Friend]get_ServerName(&this, pbstrServerName);

	public HRESULT GetDeviceProviders(IFaxDeviceProviders** ppFaxDeviceProviders) mut => VT.[Friend]GetDeviceProviders(&this, ppFaxDeviceProviders);

	public HRESULT GetDevices(IFaxDevices** ppFaxDevices) mut => VT.[Friend]GetDevices(&this, ppFaxDevices);

	public HRESULT get_InboundRouting(IFaxInboundRouting** ppFaxInboundRouting) mut => VT.[Friend]get_InboundRouting(&this, ppFaxInboundRouting);

	public HRESULT get_Folders(IFaxFolders** pFaxFolders) mut => VT.[Friend]get_Folders(&this, pFaxFolders);

	public HRESULT get_LoggingOptions(IFaxLoggingOptions** ppFaxLoggingOptions) mut => VT.[Friend]get_LoggingOptions(&this, ppFaxLoggingOptions);

	public HRESULT get_MajorVersion(int32* plMajorVersion) mut => VT.[Friend]get_MajorVersion(&this, plMajorVersion);

	public HRESULT get_MinorVersion(int32* plMinorVersion) mut => VT.[Friend]get_MinorVersion(&this, plMinorVersion);

	public HRESULT get_MajorBuild(int32* plMajorBuild) mut => VT.[Friend]get_MajorBuild(&this, plMajorBuild);

	public HRESULT get_MinorBuild(int32* plMinorBuild) mut => VT.[Friend]get_MinorBuild(&this, plMinorBuild);

	public HRESULT get_Debug(int16* pbDebug) mut => VT.[Friend]get_Debug(&this, pbDebug);

	public HRESULT get_Activity(IFaxActivity** ppFaxActivity) mut => VT.[Friend]get_Activity(&this, ppFaxActivity);

	public HRESULT get_OutboundRouting(IFaxOutboundRouting** ppFaxOutboundRouting) mut => VT.[Friend]get_OutboundRouting(&this, ppFaxOutboundRouting);

	public HRESULT get_ReceiptOptions(IFaxReceiptOptions** ppFaxReceiptOptions) mut => VT.[Friend]get_ReceiptOptions(&this, ppFaxReceiptOptions);

	public HRESULT get_Security(IFaxSecurity** ppFaxSecurity) mut => VT.[Friend]get_Security(&this, ppFaxSecurity);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);

	public HRESULT GetExtensionProperty(BSTR bstrGUID, VARIANT* pvProperty) mut => VT.[Friend]GetExtensionProperty(&this, bstrGUID, pvProperty);

	public HRESULT SetExtensionProperty(BSTR bstrGUID, VARIANT vProperty) mut => VT.[Friend]SetExtensionProperty(&this, bstrGUID, vProperty);

	public HRESULT ListenToServerEvents(FAX_SERVER_EVENTS_TYPE_ENUM EventTypes) mut => VT.[Friend]ListenToServerEvents(&this, EventTypes);

	public HRESULT RegisterDeviceProvider(BSTR bstrGUID, BSTR bstrFriendlyName, BSTR bstrImageName, BSTR TspName, int32 lFSPIVersion) mut => VT.[Friend]RegisterDeviceProvider(&this, bstrGUID, bstrFriendlyName, bstrImageName, TspName, lFSPIVersion);

	public HRESULT UnregisterDeviceProvider(BSTR bstrUniqueName) mut => VT.[Friend]UnregisterDeviceProvider(&this, bstrUniqueName);

	public HRESULT RegisterInboundRoutingExtension(BSTR bstrExtensionName, BSTR bstrFriendlyName, BSTR bstrImageName, VARIANT vMethods) mut => VT.[Friend]RegisterInboundRoutingExtension(&this, bstrExtensionName, bstrFriendlyName, bstrImageName, vMethods);

	public HRESULT UnregisterInboundRoutingExtension(BSTR bstrExtensionUniqueName) mut => VT.[Friend]UnregisterInboundRoutingExtension(&this, bstrExtensionUniqueName);

	public HRESULT get_RegisteredEvents(FAX_SERVER_EVENTS_TYPE_ENUM* pEventTypes) mut => VT.[Friend]get_RegisteredEvents(&this, pEventTypes);

	public HRESULT get_APIVersion(FAX_SERVER_APIVERSION_ENUM* pAPIVersion) mut => VT.[Friend]get_APIVersion(&this, pAPIVersion);
}

[CRepr]struct IFaxDeviceProviders : IDispatch
{
	public new const Guid IID = .(0x9fb76f62, 0x4c7e, 0x43a5, 0xb6, 0xfd, 0x50, 0x28, 0x93, 0xf7, 0xe1, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vIndex, IFaxDeviceProvider** pFaxDeviceProvider) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(VARIANT vIndex, IFaxDeviceProvider** pFaxDeviceProvider) mut => VT.[Friend]get_Item(&this, vIndex, pFaxDeviceProvider);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);
}

[CRepr]struct IFaxDevices : IDispatch
{
	public new const Guid IID = .(0x9e46783e, 0xf34f, 0x482e, 0xa3, 0x60, 0x04, 0x16, 0xbe, 0xcb, 0xbd, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vIndex, IFaxDevice** pFaxDevice) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lId, IFaxDevice** ppFaxDevice) get_ItemById;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(VARIANT vIndex, IFaxDevice** pFaxDevice) mut => VT.[Friend]get_Item(&this, vIndex, pFaxDevice);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get_ItemById(int32 lId, IFaxDevice** ppFaxDevice) mut => VT.[Friend]get_ItemById(&this, lId, ppFaxDevice);
}

[CRepr]struct IFaxInboundRouting : IDispatch
{
	public new const Guid IID = .(0x8148c20f, 0x9d52, 0x45b1, 0xbf, 0x96, 0x38, 0xfc, 0x12, 0x71, 0x35, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxInboundRoutingExtensions** pFaxInboundRoutingExtensions) GetExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxInboundRoutingMethods** pFaxInboundRoutingMethods) GetMethods;
	}


	public HRESULT GetExtensions(IFaxInboundRoutingExtensions** pFaxInboundRoutingExtensions) mut => VT.[Friend]GetExtensions(&this, pFaxInboundRoutingExtensions);

	public HRESULT GetMethods(IFaxInboundRoutingMethods** pFaxInboundRoutingMethods) mut => VT.[Friend]GetMethods(&this, pFaxInboundRoutingMethods);
}

[CRepr]struct IFaxFolders : IDispatch
{
	public new const Guid IID = .(0xdce3b2a8, 0xa7ab, 0x42bc, 0x9d, 0x0a, 0x31, 0x49, 0x45, 0x72, 0x61, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxOutgoingQueue** pFaxOutgoingQueue) get_OutgoingQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxIncomingQueue** pFaxIncomingQueue) get_IncomingQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxIncomingArchive** pFaxIncomingArchive) get_IncomingArchive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxOutgoingArchive** pFaxOutgoingArchive) get_OutgoingArchive;
	}


	public HRESULT get_OutgoingQueue(IFaxOutgoingQueue** pFaxOutgoingQueue) mut => VT.[Friend]get_OutgoingQueue(&this, pFaxOutgoingQueue);

	public HRESULT get_IncomingQueue(IFaxIncomingQueue** pFaxIncomingQueue) mut => VT.[Friend]get_IncomingQueue(&this, pFaxIncomingQueue);

	public HRESULT get_IncomingArchive(IFaxIncomingArchive** pFaxIncomingArchive) mut => VT.[Friend]get_IncomingArchive(&this, pFaxIncomingArchive);

	public HRESULT get_OutgoingArchive(IFaxOutgoingArchive** pFaxOutgoingArchive) mut => VT.[Friend]get_OutgoingArchive(&this, pFaxOutgoingArchive);
}

[CRepr]struct IFaxLoggingOptions : IDispatch
{
	public new const Guid IID = .(0x34e64fb9, 0x6b31, 0x4d32, 0x8b, 0x27, 0xd2, 0x86, 0xc0, 0xc3, 0x36, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxEventLogging** pFaxEventLogging) get_EventLogging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxActivityLogging** pFaxActivityLogging) get_ActivityLogging;
	}


	public HRESULT get_EventLogging(IFaxEventLogging** pFaxEventLogging) mut => VT.[Friend]get_EventLogging(&this, pFaxEventLogging);

	public HRESULT get_ActivityLogging(IFaxActivityLogging** pFaxActivityLogging) mut => VT.[Friend]get_ActivityLogging(&this, pFaxActivityLogging);
}

[CRepr]struct IFaxActivity : IDispatch
{
	public new const Guid IID = .(0x4b106f97, 0x3df5, 0x40f2, 0xbc, 0x3c, 0x44, 0xcb, 0x81, 0x15, 0xeb, 0xdf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plIncomingMessages) get_IncomingMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRoutingMessages) get_RoutingMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plOutgoingMessages) get_OutgoingMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plQueuedMessages) get_QueuedMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
	}


	public HRESULT get_IncomingMessages(int32* plIncomingMessages) mut => VT.[Friend]get_IncomingMessages(&this, plIncomingMessages);

	public HRESULT get_RoutingMessages(int32* plRoutingMessages) mut => VT.[Friend]get_RoutingMessages(&this, plRoutingMessages);

	public HRESULT get_OutgoingMessages(int32* plOutgoingMessages) mut => VT.[Friend]get_OutgoingMessages(&this, plOutgoingMessages);

	public HRESULT get_QueuedMessages(int32* plQueuedMessages) mut => VT.[Friend]get_QueuedMessages(&this, plQueuedMessages);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);
}

[CRepr]struct IFaxOutboundRouting : IDispatch
{
	public new const Guid IID = .(0x25dc05a4, 0x9909, 0x41bd, 0xa9, 0x5b, 0x7e, 0x5d, 0x1d, 0xec, 0x1d, 0x43);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxOutboundRoutingGroups** pFaxOutboundRoutingGroups) GetGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxOutboundRoutingRules** pFaxOutboundRoutingRules) GetRules;
	}


	public HRESULT GetGroups(IFaxOutboundRoutingGroups** pFaxOutboundRoutingGroups) mut => VT.[Friend]GetGroups(&this, pFaxOutboundRoutingGroups);

	public HRESULT GetRules(IFaxOutboundRoutingRules** pFaxOutboundRoutingRules) mut => VT.[Friend]GetRules(&this, pFaxOutboundRoutingRules);
}

[CRepr]struct IFaxReceiptOptions : IDispatch
{
	public new const Guid IID = .(0x378efaeb, 0x5fcb, 0x4afb, 0xb2, 0xee, 0xe1, 0x6e, 0x80, 0x61, 0x44, 0x87);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_SMTP_AUTHENTICATION_TYPE_ENUM* pType) get_AuthenticationType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_SMTP_AUTHENTICATION_TYPE_ENUM Type) put_AuthenticationType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSMTPServer) get_SMTPServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSMTPServer) put_SMTPServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSMTPPort) get_SMTPPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSMTPPort) put_SMTPPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSMTPSender) get_SMTPSender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSMTPSender) put_SMTPSender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSMTPUser) get_SMTPUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSMTPUser) put_SMTPUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_RECEIPT_TYPE_ENUM* pAllowedReceipts) get_AllowedReceipts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_RECEIPT_TYPE_ENUM AllowedReceipts) put_AllowedReceipts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSMTPPassword) get_SMTPPassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSMTPPassword) put_SMTPPassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbUseForInboundRouting) get_UseForInboundRouting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bUseForInboundRouting) put_UseForInboundRouting;
	}


	public HRESULT get_AuthenticationType(FAX_SMTP_AUTHENTICATION_TYPE_ENUM* pType) mut => VT.[Friend]get_AuthenticationType(&this, pType);

	public HRESULT put_AuthenticationType(FAX_SMTP_AUTHENTICATION_TYPE_ENUM Type) mut => VT.[Friend]put_AuthenticationType(&this, Type);

	public HRESULT get_SMTPServer(BSTR* pbstrSMTPServer) mut => VT.[Friend]get_SMTPServer(&this, pbstrSMTPServer);

	public HRESULT put_SMTPServer(BSTR bstrSMTPServer) mut => VT.[Friend]put_SMTPServer(&this, bstrSMTPServer);

	public HRESULT get_SMTPPort(int32* plSMTPPort) mut => VT.[Friend]get_SMTPPort(&this, plSMTPPort);

	public HRESULT put_SMTPPort(int32 lSMTPPort) mut => VT.[Friend]put_SMTPPort(&this, lSMTPPort);

	public HRESULT get_SMTPSender(BSTR* pbstrSMTPSender) mut => VT.[Friend]get_SMTPSender(&this, pbstrSMTPSender);

	public HRESULT put_SMTPSender(BSTR bstrSMTPSender) mut => VT.[Friend]put_SMTPSender(&this, bstrSMTPSender);

	public HRESULT get_SMTPUser(BSTR* pbstrSMTPUser) mut => VT.[Friend]get_SMTPUser(&this, pbstrSMTPUser);

	public HRESULT put_SMTPUser(BSTR bstrSMTPUser) mut => VT.[Friend]put_SMTPUser(&this, bstrSMTPUser);

	public HRESULT get_AllowedReceipts(FAX_RECEIPT_TYPE_ENUM* pAllowedReceipts) mut => VT.[Friend]get_AllowedReceipts(&this, pAllowedReceipts);

	public HRESULT put_AllowedReceipts(FAX_RECEIPT_TYPE_ENUM AllowedReceipts) mut => VT.[Friend]put_AllowedReceipts(&this, AllowedReceipts);

	public HRESULT get_SMTPPassword(BSTR* pbstrSMTPPassword) mut => VT.[Friend]get_SMTPPassword(&this, pbstrSMTPPassword);

	public HRESULT put_SMTPPassword(BSTR bstrSMTPPassword) mut => VT.[Friend]put_SMTPPassword(&this, bstrSMTPPassword);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT get_UseForInboundRouting(int16* pbUseForInboundRouting) mut => VT.[Friend]get_UseForInboundRouting(&this, pbUseForInboundRouting);

	public HRESULT put_UseForInboundRouting(int16 bUseForInboundRouting) mut => VT.[Friend]put_UseForInboundRouting(&this, bUseForInboundRouting);
}

[CRepr]struct IFaxSecurity : IDispatch
{
	public new const Guid IID = .(0x77b508c1, 0x09c0, 0x47a2, 0x91, 0xeb, 0xfc, 0xe7, 0xfd, 0xf2, 0x69, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvDescriptor) get_Descriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vDescriptor) put_Descriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_ACCESS_RIGHTS_ENUM* pGrantedRights) get_GrantedRights;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plInformationType) get_InformationType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lInformationType) put_InformationType;
	}


	public HRESULT get_Descriptor(VARIANT* pvDescriptor) mut => VT.[Friend]get_Descriptor(&this, pvDescriptor);

	public HRESULT put_Descriptor(VARIANT vDescriptor) mut => VT.[Friend]put_Descriptor(&this, vDescriptor);

	public HRESULT get_GrantedRights(FAX_ACCESS_RIGHTS_ENUM* pGrantedRights) mut => VT.[Friend]get_GrantedRights(&this, pGrantedRights);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT get_InformationType(int32* plInformationType) mut => VT.[Friend]get_InformationType(&this, plInformationType);

	public HRESULT put_InformationType(int32 lInformationType) mut => VT.[Friend]put_InformationType(&this, lInformationType);
}

[CRepr]struct IFaxDocument : IDispatch
{
	public new const Guid IID = .(0xb207a246, 0x09e3, 0x4a4e, 0xa7, 0xdc, 0xfe, 0xa3, 0x1d, 0x29, 0x45, 0x8f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBody) get_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBody) put_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxSender** ppFaxSender) get_Sender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxRecipients** ppFaxRecipients) get_Recipients;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCoverPage) get_CoverPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCoverPage) put_CoverPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubject) get_Subject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSubject) put_Subject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrNote) get_Note;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNote) put_Note;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateScheduleTime) get_ScheduleTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dateScheduleTime) put_ScheduleTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrReceiptAddress) get_ReceiptAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReceiptAddress) put_ReceiptAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDocumentName) get_DocumentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDocumentName) put_DocumentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCallHandle) get_CallHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCallHandle) put_CallHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_COVERPAGE_TYPE_ENUM* pCoverPageType) get_CoverPageType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_COVERPAGE_TYPE_ENUM CoverPageType) put_CoverPageType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_SCHEDULE_TYPE_ENUM* pScheduleType) get_ScheduleType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_SCHEDULE_TYPE_ENUM ScheduleType) put_ScheduleType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_RECEIPT_TYPE_ENUM* pReceiptType) get_ReceiptType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_RECEIPT_TYPE_ENUM ReceiptType) put_ReceiptType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbUseGrouping) get_GroupBroadcastReceipts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bUseGrouping) put_GroupBroadcastReceipts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_PRIORITY_TYPE_ENUM* pPriority) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_PRIORITY_TYPE_ENUM Priority) put_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppTapiConnection) get_TapiConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pTapiConnection) putref_TapiConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFaxServerName, VARIANT* pvFaxOutgoingJobIDs) Submit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer* pFaxServer, VARIANT* pvFaxOutgoingJobIDs) ConnectedSubmit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbAttachFax) get_AttachFaxToReceipt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bAttachFax) put_AttachFaxToReceipt;
	}


	public HRESULT get_Body(BSTR* pbstrBody) mut => VT.[Friend]get_Body(&this, pbstrBody);

	public HRESULT put_Body(BSTR bstrBody) mut => VT.[Friend]put_Body(&this, bstrBody);

	public HRESULT get_Sender(IFaxSender** ppFaxSender) mut => VT.[Friend]get_Sender(&this, ppFaxSender);

	public HRESULT get_Recipients(IFaxRecipients** ppFaxRecipients) mut => VT.[Friend]get_Recipients(&this, ppFaxRecipients);

	public HRESULT get_CoverPage(BSTR* pbstrCoverPage) mut => VT.[Friend]get_CoverPage(&this, pbstrCoverPage);

	public HRESULT put_CoverPage(BSTR bstrCoverPage) mut => VT.[Friend]put_CoverPage(&this, bstrCoverPage);

	public HRESULT get_Subject(BSTR* pbstrSubject) mut => VT.[Friend]get_Subject(&this, pbstrSubject);

	public HRESULT put_Subject(BSTR bstrSubject) mut => VT.[Friend]put_Subject(&this, bstrSubject);

	public HRESULT get_Note(BSTR* pbstrNote) mut => VT.[Friend]get_Note(&this, pbstrNote);

	public HRESULT put_Note(BSTR bstrNote) mut => VT.[Friend]put_Note(&this, bstrNote);

	public HRESULT get_ScheduleTime(double* pdateScheduleTime) mut => VT.[Friend]get_ScheduleTime(&this, pdateScheduleTime);

	public HRESULT put_ScheduleTime(double dateScheduleTime) mut => VT.[Friend]put_ScheduleTime(&this, dateScheduleTime);

	public HRESULT get_ReceiptAddress(BSTR* pbstrReceiptAddress) mut => VT.[Friend]get_ReceiptAddress(&this, pbstrReceiptAddress);

	public HRESULT put_ReceiptAddress(BSTR bstrReceiptAddress) mut => VT.[Friend]put_ReceiptAddress(&this, bstrReceiptAddress);

	public HRESULT get_DocumentName(BSTR* pbstrDocumentName) mut => VT.[Friend]get_DocumentName(&this, pbstrDocumentName);

	public HRESULT put_DocumentName(BSTR bstrDocumentName) mut => VT.[Friend]put_DocumentName(&this, bstrDocumentName);

	public HRESULT get_CallHandle(int32* plCallHandle) mut => VT.[Friend]get_CallHandle(&this, plCallHandle);

	public HRESULT put_CallHandle(int32 lCallHandle) mut => VT.[Friend]put_CallHandle(&this, lCallHandle);

	public HRESULT get_CoverPageType(FAX_COVERPAGE_TYPE_ENUM* pCoverPageType) mut => VT.[Friend]get_CoverPageType(&this, pCoverPageType);

	public HRESULT put_CoverPageType(FAX_COVERPAGE_TYPE_ENUM CoverPageType) mut => VT.[Friend]put_CoverPageType(&this, CoverPageType);

	public HRESULT get_ScheduleType(FAX_SCHEDULE_TYPE_ENUM* pScheduleType) mut => VT.[Friend]get_ScheduleType(&this, pScheduleType);

	public HRESULT put_ScheduleType(FAX_SCHEDULE_TYPE_ENUM ScheduleType) mut => VT.[Friend]put_ScheduleType(&this, ScheduleType);

	public HRESULT get_ReceiptType(FAX_RECEIPT_TYPE_ENUM* pReceiptType) mut => VT.[Friend]get_ReceiptType(&this, pReceiptType);

	public HRESULT put_ReceiptType(FAX_RECEIPT_TYPE_ENUM ReceiptType) mut => VT.[Friend]put_ReceiptType(&this, ReceiptType);

	public HRESULT get_GroupBroadcastReceipts(int16* pbUseGrouping) mut => VT.[Friend]get_GroupBroadcastReceipts(&this, pbUseGrouping);

	public HRESULT put_GroupBroadcastReceipts(int16 bUseGrouping) mut => VT.[Friend]put_GroupBroadcastReceipts(&this, bUseGrouping);

	public HRESULT get_Priority(FAX_PRIORITY_TYPE_ENUM* pPriority) mut => VT.[Friend]get_Priority(&this, pPriority);

	public HRESULT put_Priority(FAX_PRIORITY_TYPE_ENUM Priority) mut => VT.[Friend]put_Priority(&this, Priority);

	public HRESULT get_TapiConnection(IDispatch** ppTapiConnection) mut => VT.[Friend]get_TapiConnection(&this, ppTapiConnection);

	public HRESULT putref_TapiConnection(IDispatch* pTapiConnection) mut => VT.[Friend]putref_TapiConnection(&this, pTapiConnection);

	public HRESULT Submit(BSTR bstrFaxServerName, VARIANT* pvFaxOutgoingJobIDs) mut => VT.[Friend]Submit(&this, bstrFaxServerName, pvFaxOutgoingJobIDs);

	public HRESULT ConnectedSubmit(IFaxServer* pFaxServer, VARIANT* pvFaxOutgoingJobIDs) mut => VT.[Friend]ConnectedSubmit(&this, pFaxServer, pvFaxOutgoingJobIDs);

	public HRESULT get_AttachFaxToReceipt(int16* pbAttachFax) mut => VT.[Friend]get_AttachFaxToReceipt(&this, pbAttachFax);

	public HRESULT put_AttachFaxToReceipt(int16 bAttachFax) mut => VT.[Friend]put_AttachFaxToReceipt(&this, bAttachFax);
}

[CRepr]struct IFaxSender : IDispatch
{
	public new const Guid IID = .(0x0d879d7d, 0xf57a, 0x4cc6, 0xa6, 0xf9, 0x3e, 0xe5, 0xd5, 0x27, 0xb4, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBillingCode) get_BillingCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBillingCode) put_BillingCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCity) get_City;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCity) put_City;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCompany) get_Company;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCompany) put_Company;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCountry) get_Country;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCountry) put_Country;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDepartment) get_Department;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDepartment) put_Department;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrEmail) get_Email;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrEmail) put_Email;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFaxNumber) get_FaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFaxNumber) put_FaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrHomePhone) get_HomePhone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrHomePhone) put_HomePhone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTSID) get_TSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTSID) put_TSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrOfficePhone) get_OfficePhone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOfficePhone) put_OfficePhone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrOfficeLocation) get_OfficeLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOfficeLocation) put_OfficeLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrState) put_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrStreetAddress) get_StreetAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrStreetAddress) put_StreetAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTitle) get_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTitle) put_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrZipCode) get_ZipCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrZipCode) put_ZipCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) LoadDefaultSender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SaveDefaultSender;
	}


	public HRESULT get_BillingCode(BSTR* pbstrBillingCode) mut => VT.[Friend]get_BillingCode(&this, pbstrBillingCode);

	public HRESULT put_BillingCode(BSTR bstrBillingCode) mut => VT.[Friend]put_BillingCode(&this, bstrBillingCode);

	public HRESULT get_City(BSTR* pbstrCity) mut => VT.[Friend]get_City(&this, pbstrCity);

	public HRESULT put_City(BSTR bstrCity) mut => VT.[Friend]put_City(&this, bstrCity);

	public HRESULT get_Company(BSTR* pbstrCompany) mut => VT.[Friend]get_Company(&this, pbstrCompany);

	public HRESULT put_Company(BSTR bstrCompany) mut => VT.[Friend]put_Company(&this, bstrCompany);

	public HRESULT get_Country(BSTR* pbstrCountry) mut => VT.[Friend]get_Country(&this, pbstrCountry);

	public HRESULT put_Country(BSTR bstrCountry) mut => VT.[Friend]put_Country(&this, bstrCountry);

	public HRESULT get_Department(BSTR* pbstrDepartment) mut => VT.[Friend]get_Department(&this, pbstrDepartment);

	public HRESULT put_Department(BSTR bstrDepartment) mut => VT.[Friend]put_Department(&this, bstrDepartment);

	public HRESULT get_Email(BSTR* pbstrEmail) mut => VT.[Friend]get_Email(&this, pbstrEmail);

	public HRESULT put_Email(BSTR bstrEmail) mut => VT.[Friend]put_Email(&this, bstrEmail);

	public HRESULT get_FaxNumber(BSTR* pbstrFaxNumber) mut => VT.[Friend]get_FaxNumber(&this, pbstrFaxNumber);

	public HRESULT put_FaxNumber(BSTR bstrFaxNumber) mut => VT.[Friend]put_FaxNumber(&this, bstrFaxNumber);

	public HRESULT get_HomePhone(BSTR* pbstrHomePhone) mut => VT.[Friend]get_HomePhone(&this, pbstrHomePhone);

	public HRESULT put_HomePhone(BSTR bstrHomePhone) mut => VT.[Friend]put_HomePhone(&this, bstrHomePhone);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrName) mut => VT.[Friend]put_Name(&this, bstrName);

	public HRESULT get_TSID(BSTR* pbstrTSID) mut => VT.[Friend]get_TSID(&this, pbstrTSID);

	public HRESULT put_TSID(BSTR bstrTSID) mut => VT.[Friend]put_TSID(&this, bstrTSID);

	public HRESULT get_OfficePhone(BSTR* pbstrOfficePhone) mut => VT.[Friend]get_OfficePhone(&this, pbstrOfficePhone);

	public HRESULT put_OfficePhone(BSTR bstrOfficePhone) mut => VT.[Friend]put_OfficePhone(&this, bstrOfficePhone);

	public HRESULT get_OfficeLocation(BSTR* pbstrOfficeLocation) mut => VT.[Friend]get_OfficeLocation(&this, pbstrOfficeLocation);

	public HRESULT put_OfficeLocation(BSTR bstrOfficeLocation) mut => VT.[Friend]put_OfficeLocation(&this, bstrOfficeLocation);

	public HRESULT get_State(BSTR* pbstrState) mut => VT.[Friend]get_State(&this, pbstrState);

	public HRESULT put_State(BSTR bstrState) mut => VT.[Friend]put_State(&this, bstrState);

	public HRESULT get_StreetAddress(BSTR* pbstrStreetAddress) mut => VT.[Friend]get_StreetAddress(&this, pbstrStreetAddress);

	public HRESULT put_StreetAddress(BSTR bstrStreetAddress) mut => VT.[Friend]put_StreetAddress(&this, bstrStreetAddress);

	public HRESULT get_Title(BSTR* pbstrTitle) mut => VT.[Friend]get_Title(&this, pbstrTitle);

	public HRESULT put_Title(BSTR bstrTitle) mut => VT.[Friend]put_Title(&this, bstrTitle);

	public HRESULT get_ZipCode(BSTR* pbstrZipCode) mut => VT.[Friend]get_ZipCode(&this, pbstrZipCode);

	public HRESULT put_ZipCode(BSTR bstrZipCode) mut => VT.[Friend]put_ZipCode(&this, bstrZipCode);

	public HRESULT LoadDefaultSender() mut => VT.[Friend]LoadDefaultSender(&this);

	public HRESULT SaveDefaultSender() mut => VT.[Friend]SaveDefaultSender(&this);
}

[CRepr]struct IFaxRecipient : IDispatch
{
	public new const Guid IID = .(0x9a3da3a0, 0x538d, 0x42b6, 0x94, 0x44, 0xaa, 0xa5, 0x7d, 0x0c, 0xe2, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFaxNumber) get_FaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFaxNumber) put_FaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_Name;
	}


	public HRESULT get_FaxNumber(BSTR* pbstrFaxNumber) mut => VT.[Friend]get_FaxNumber(&this, pbstrFaxNumber);

	public HRESULT put_FaxNumber(BSTR bstrFaxNumber) mut => VT.[Friend]put_FaxNumber(&this, bstrFaxNumber);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrName) mut => VT.[Friend]put_Name(&this, bstrName);
}

[CRepr]struct IFaxRecipients : IDispatch
{
	public new const Guid IID = .(0xb9c9de5a, 0x894e, 0x4492, 0x9f, 0xa3, 0x08, 0xc6, 0x27, 0xc1, 0x1d, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, IFaxRecipient** ppFaxRecipient) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFaxNumber, BSTR bstrRecipientName, IFaxRecipient** ppFaxRecipient) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex) Remove;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(int32 lIndex, IFaxRecipient** ppFaxRecipient) mut => VT.[Friend]get_Item(&this, lIndex, ppFaxRecipient);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT Add(BSTR bstrFaxNumber, BSTR bstrRecipientName, IFaxRecipient** ppFaxRecipient) mut => VT.[Friend]Add(&this, bstrFaxNumber, bstrRecipientName, ppFaxRecipient);

	public HRESULT Remove(int32 lIndex) mut => VT.[Friend]Remove(&this, lIndex);
}

[CRepr]struct IFaxIncomingArchive : IDispatch
{
	public new const Guid IID = .(0x76062cc7, 0xf714, 0x4fbd, 0xaa, 0x06, 0xed, 0x6e, 0x4a, 0x4b, 0x70, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbUseArchive) get_UseArchive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bUseArchive) put_UseArchive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrArchiveFolder) get_ArchiveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrArchiveFolder) put_ArchiveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbSizeQuotaWarning) get_SizeQuotaWarning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bSizeQuotaWarning) put_SizeQuotaWarning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHighQuotaWaterMark) get_HighQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lHighQuotaWaterMark) put_HighQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plLowQuotaWaterMark) get_LowQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lLowQuotaWaterMark) put_LowQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAgeLimit) get_AgeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAgeLimit) put_AgeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSizeLow) get_SizeLow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSizeHigh) get_SizeHigh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrefetchSize, IFaxIncomingMessageIterator** pFaxIncomingMessageIterator) GetMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMessageId, IFaxIncomingMessage** pFaxIncomingMessage) GetMessage;
	}


	public HRESULT get_UseArchive(int16* pbUseArchive) mut => VT.[Friend]get_UseArchive(&this, pbUseArchive);

	public HRESULT put_UseArchive(int16 bUseArchive) mut => VT.[Friend]put_UseArchive(&this, bUseArchive);

	public HRESULT get_ArchiveFolder(BSTR* pbstrArchiveFolder) mut => VT.[Friend]get_ArchiveFolder(&this, pbstrArchiveFolder);

	public HRESULT put_ArchiveFolder(BSTR bstrArchiveFolder) mut => VT.[Friend]put_ArchiveFolder(&this, bstrArchiveFolder);

	public HRESULT get_SizeQuotaWarning(int16* pbSizeQuotaWarning) mut => VT.[Friend]get_SizeQuotaWarning(&this, pbSizeQuotaWarning);

	public HRESULT put_SizeQuotaWarning(int16 bSizeQuotaWarning) mut => VT.[Friend]put_SizeQuotaWarning(&this, bSizeQuotaWarning);

	public HRESULT get_HighQuotaWaterMark(int32* plHighQuotaWaterMark) mut => VT.[Friend]get_HighQuotaWaterMark(&this, plHighQuotaWaterMark);

	public HRESULT put_HighQuotaWaterMark(int32 lHighQuotaWaterMark) mut => VT.[Friend]put_HighQuotaWaterMark(&this, lHighQuotaWaterMark);

	public HRESULT get_LowQuotaWaterMark(int32* plLowQuotaWaterMark) mut => VT.[Friend]get_LowQuotaWaterMark(&this, plLowQuotaWaterMark);

	public HRESULT put_LowQuotaWaterMark(int32 lLowQuotaWaterMark) mut => VT.[Friend]put_LowQuotaWaterMark(&this, lLowQuotaWaterMark);

	public HRESULT get_AgeLimit(int32* plAgeLimit) mut => VT.[Friend]get_AgeLimit(&this, plAgeLimit);

	public HRESULT put_AgeLimit(int32 lAgeLimit) mut => VT.[Friend]put_AgeLimit(&this, lAgeLimit);

	public HRESULT get_SizeLow(int32* plSizeLow) mut => VT.[Friend]get_SizeLow(&this, plSizeLow);

	public HRESULT get_SizeHigh(int32* plSizeHigh) mut => VT.[Friend]get_SizeHigh(&this, plSizeHigh);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT GetMessages(int32 lPrefetchSize, IFaxIncomingMessageIterator** pFaxIncomingMessageIterator) mut => VT.[Friend]GetMessages(&this, lPrefetchSize, pFaxIncomingMessageIterator);

	public HRESULT GetMessage(BSTR bstrMessageId, IFaxIncomingMessage** pFaxIncomingMessage) mut => VT.[Friend]GetMessage(&this, bstrMessageId, pFaxIncomingMessage);
}

[CRepr]struct IFaxIncomingQueue : IDispatch
{
	public new const Guid IID = .(0x902e64ef, 0x8fd8, 0x4b75, 0x97, 0x25, 0x60, 0x14, 0xdf, 0x16, 0x15, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbBlocked) get_Blocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bBlocked) put_Blocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxIncomingJobs** pFaxIncomingJobs) GetJobs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrJobId, IFaxIncomingJob** pFaxIncomingJob) GetJob;
	}


	public HRESULT get_Blocked(int16* pbBlocked) mut => VT.[Friend]get_Blocked(&this, pbBlocked);

	public HRESULT put_Blocked(int16 bBlocked) mut => VT.[Friend]put_Blocked(&this, bBlocked);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT GetJobs(IFaxIncomingJobs** pFaxIncomingJobs) mut => VT.[Friend]GetJobs(&this, pFaxIncomingJobs);

	public HRESULT GetJob(BSTR bstrJobId, IFaxIncomingJob** pFaxIncomingJob) mut => VT.[Friend]GetJob(&this, bstrJobId, pFaxIncomingJob);
}

[CRepr]struct IFaxOutgoingArchive : IDispatch
{
	public new const Guid IID = .(0xc9c28f40, 0x8d80, 0x4e53, 0x81, 0x0f, 0x9a, 0x79, 0x91, 0x9b, 0x49, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbUseArchive) get_UseArchive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bUseArchive) put_UseArchive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrArchiveFolder) get_ArchiveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrArchiveFolder) put_ArchiveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbSizeQuotaWarning) get_SizeQuotaWarning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bSizeQuotaWarning) put_SizeQuotaWarning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHighQuotaWaterMark) get_HighQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lHighQuotaWaterMark) put_HighQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plLowQuotaWaterMark) get_LowQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lLowQuotaWaterMark) put_LowQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAgeLimit) get_AgeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAgeLimit) put_AgeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSizeLow) get_SizeLow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSizeHigh) get_SizeHigh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrefetchSize, IFaxOutgoingMessageIterator** pFaxOutgoingMessageIterator) GetMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMessageId, IFaxOutgoingMessage** pFaxOutgoingMessage) GetMessage;
	}


	public HRESULT get_UseArchive(int16* pbUseArchive) mut => VT.[Friend]get_UseArchive(&this, pbUseArchive);

	public HRESULT put_UseArchive(int16 bUseArchive) mut => VT.[Friend]put_UseArchive(&this, bUseArchive);

	public HRESULT get_ArchiveFolder(BSTR* pbstrArchiveFolder) mut => VT.[Friend]get_ArchiveFolder(&this, pbstrArchiveFolder);

	public HRESULT put_ArchiveFolder(BSTR bstrArchiveFolder) mut => VT.[Friend]put_ArchiveFolder(&this, bstrArchiveFolder);

	public HRESULT get_SizeQuotaWarning(int16* pbSizeQuotaWarning) mut => VT.[Friend]get_SizeQuotaWarning(&this, pbSizeQuotaWarning);

	public HRESULT put_SizeQuotaWarning(int16 bSizeQuotaWarning) mut => VT.[Friend]put_SizeQuotaWarning(&this, bSizeQuotaWarning);

	public HRESULT get_HighQuotaWaterMark(int32* plHighQuotaWaterMark) mut => VT.[Friend]get_HighQuotaWaterMark(&this, plHighQuotaWaterMark);

	public HRESULT put_HighQuotaWaterMark(int32 lHighQuotaWaterMark) mut => VT.[Friend]put_HighQuotaWaterMark(&this, lHighQuotaWaterMark);

	public HRESULT get_LowQuotaWaterMark(int32* plLowQuotaWaterMark) mut => VT.[Friend]get_LowQuotaWaterMark(&this, plLowQuotaWaterMark);

	public HRESULT put_LowQuotaWaterMark(int32 lLowQuotaWaterMark) mut => VT.[Friend]put_LowQuotaWaterMark(&this, lLowQuotaWaterMark);

	public HRESULT get_AgeLimit(int32* plAgeLimit) mut => VT.[Friend]get_AgeLimit(&this, plAgeLimit);

	public HRESULT put_AgeLimit(int32 lAgeLimit) mut => VT.[Friend]put_AgeLimit(&this, lAgeLimit);

	public HRESULT get_SizeLow(int32* plSizeLow) mut => VT.[Friend]get_SizeLow(&this, plSizeLow);

	public HRESULT get_SizeHigh(int32* plSizeHigh) mut => VT.[Friend]get_SizeHigh(&this, plSizeHigh);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT GetMessages(int32 lPrefetchSize, IFaxOutgoingMessageIterator** pFaxOutgoingMessageIterator) mut => VT.[Friend]GetMessages(&this, lPrefetchSize, pFaxOutgoingMessageIterator);

	public HRESULT GetMessage(BSTR bstrMessageId, IFaxOutgoingMessage** pFaxOutgoingMessage) mut => VT.[Friend]GetMessage(&this, bstrMessageId, pFaxOutgoingMessage);
}

[CRepr]struct IFaxOutgoingQueue : IDispatch
{
	public new const Guid IID = .(0x80b1df24, 0xd9ac, 0x4333, 0xb3, 0x73, 0x48, 0x7c, 0xed, 0xc8, 0x0c, 0xe5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbBlocked) get_Blocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bBlocked) put_Blocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbPaused) get_Paused;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bPaused) put_Paused;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbAllowPersonalCoverPages) get_AllowPersonalCoverPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bAllowPersonalCoverPages) put_AllowPersonalCoverPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbUseDeviceTSID) get_UseDeviceTSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bUseDeviceTSID) put_UseDeviceTSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetries) get_Retries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRetries) put_Retries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetryDelay) get_RetryDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRetryDelay) put_RetryDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateDiscountRateStart) get_DiscountRateStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dateDiscountRateStart) put_DiscountRateStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateDiscountRateEnd) get_DiscountRateEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dateDiscountRateEnd) put_DiscountRateEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAgeLimit) get_AgeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAgeLimit) put_AgeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbBranding) get_Branding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bBranding) put_Branding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxOutgoingJobs** pFaxOutgoingJobs) GetJobs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrJobId, IFaxOutgoingJob** pFaxOutgoingJob) GetJob;
	}


	public HRESULT get_Blocked(int16* pbBlocked) mut => VT.[Friend]get_Blocked(&this, pbBlocked);

	public HRESULT put_Blocked(int16 bBlocked) mut => VT.[Friend]put_Blocked(&this, bBlocked);

	public HRESULT get_Paused(int16* pbPaused) mut => VT.[Friend]get_Paused(&this, pbPaused);

	public HRESULT put_Paused(int16 bPaused) mut => VT.[Friend]put_Paused(&this, bPaused);

	public HRESULT get_AllowPersonalCoverPages(int16* pbAllowPersonalCoverPages) mut => VT.[Friend]get_AllowPersonalCoverPages(&this, pbAllowPersonalCoverPages);

	public HRESULT put_AllowPersonalCoverPages(int16 bAllowPersonalCoverPages) mut => VT.[Friend]put_AllowPersonalCoverPages(&this, bAllowPersonalCoverPages);

	public HRESULT get_UseDeviceTSID(int16* pbUseDeviceTSID) mut => VT.[Friend]get_UseDeviceTSID(&this, pbUseDeviceTSID);

	public HRESULT put_UseDeviceTSID(int16 bUseDeviceTSID) mut => VT.[Friend]put_UseDeviceTSID(&this, bUseDeviceTSID);

	public HRESULT get_Retries(int32* plRetries) mut => VT.[Friend]get_Retries(&this, plRetries);

	public HRESULT put_Retries(int32 lRetries) mut => VT.[Friend]put_Retries(&this, lRetries);

	public HRESULT get_RetryDelay(int32* plRetryDelay) mut => VT.[Friend]get_RetryDelay(&this, plRetryDelay);

	public HRESULT put_RetryDelay(int32 lRetryDelay) mut => VT.[Friend]put_RetryDelay(&this, lRetryDelay);

	public HRESULT get_DiscountRateStart(double* pdateDiscountRateStart) mut => VT.[Friend]get_DiscountRateStart(&this, pdateDiscountRateStart);

	public HRESULT put_DiscountRateStart(double dateDiscountRateStart) mut => VT.[Friend]put_DiscountRateStart(&this, dateDiscountRateStart);

	public HRESULT get_DiscountRateEnd(double* pdateDiscountRateEnd) mut => VT.[Friend]get_DiscountRateEnd(&this, pdateDiscountRateEnd);

	public HRESULT put_DiscountRateEnd(double dateDiscountRateEnd) mut => VT.[Friend]put_DiscountRateEnd(&this, dateDiscountRateEnd);

	public HRESULT get_AgeLimit(int32* plAgeLimit) mut => VT.[Friend]get_AgeLimit(&this, plAgeLimit);

	public HRESULT put_AgeLimit(int32 lAgeLimit) mut => VT.[Friend]put_AgeLimit(&this, lAgeLimit);

	public HRESULT get_Branding(int16* pbBranding) mut => VT.[Friend]get_Branding(&this, pbBranding);

	public HRESULT put_Branding(int16 bBranding) mut => VT.[Friend]put_Branding(&this, bBranding);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT GetJobs(IFaxOutgoingJobs** pFaxOutgoingJobs) mut => VT.[Friend]GetJobs(&this, pFaxOutgoingJobs);

	public HRESULT GetJob(BSTR bstrJobId, IFaxOutgoingJob** pFaxOutgoingJob) mut => VT.[Friend]GetJob(&this, bstrJobId, pFaxOutgoingJob);
}

[CRepr]struct IFaxIncomingMessageIterator : IDispatch
{
	public new const Guid IID = .(0xfd73ecc4, 0x6f06, 0x4f52, 0x82, 0xa8, 0xf7, 0xba, 0x06, 0xae, 0x31, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxIncomingMessage** pFaxIncomingMessage) get_Message;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPrefetchSize) get_PrefetchSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrefetchSize) put_PrefetchSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEOF) get_AtEOF;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MoveFirst;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MoveNext;
	}


	public HRESULT get_Message(IFaxIncomingMessage** pFaxIncomingMessage) mut => VT.[Friend]get_Message(&this, pFaxIncomingMessage);

	public HRESULT get_PrefetchSize(int32* plPrefetchSize) mut => VT.[Friend]get_PrefetchSize(&this, plPrefetchSize);

	public HRESULT put_PrefetchSize(int32 lPrefetchSize) mut => VT.[Friend]put_PrefetchSize(&this, lPrefetchSize);

	public HRESULT get_AtEOF(int16* pbEOF) mut => VT.[Friend]get_AtEOF(&this, pbEOF);

	public HRESULT MoveFirst() mut => VT.[Friend]MoveFirst(&this);

	public HRESULT MoveNext() mut => VT.[Friend]MoveNext(&this);
}

[CRepr]struct IFaxIncomingMessage : IDispatch
{
	public new const Guid IID = .(0x7cab88fa, 0x2ef9, 0x4851, 0xb2, 0xf3, 0x1d, 0x14, 0x8f, 0xed, 0x84, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPages) get_Pages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSize) get_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDeviceName) get_DeviceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetries) get_Retries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateTransmissionStart) get_TransmissionStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateTransmissionEnd) get_TransmissionEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCSID) get_CSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTSID) get_TSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCallerId) get_CallerId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrRoutingInformation) get_RoutingInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTiffPath) CopyTiff;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
	}


	public HRESULT get_Id(BSTR* pbstrId) mut => VT.[Friend]get_Id(&this, pbstrId);

	public HRESULT get_Pages(int32* plPages) mut => VT.[Friend]get_Pages(&this, plPages);

	public HRESULT get_Size(int32* plSize) mut => VT.[Friend]get_Size(&this, plSize);

	public HRESULT get_DeviceName(BSTR* pbstrDeviceName) mut => VT.[Friend]get_DeviceName(&this, pbstrDeviceName);

	public HRESULT get_Retries(int32* plRetries) mut => VT.[Friend]get_Retries(&this, plRetries);

	public HRESULT get_TransmissionStart(double* pdateTransmissionStart) mut => VT.[Friend]get_TransmissionStart(&this, pdateTransmissionStart);

	public HRESULT get_TransmissionEnd(double* pdateTransmissionEnd) mut => VT.[Friend]get_TransmissionEnd(&this, pdateTransmissionEnd);

	public HRESULT get_CSID(BSTR* pbstrCSID) mut => VT.[Friend]get_CSID(&this, pbstrCSID);

	public HRESULT get_TSID(BSTR* pbstrTSID) mut => VT.[Friend]get_TSID(&this, pbstrTSID);

	public HRESULT get_CallerId(BSTR* pbstrCallerId) mut => VT.[Friend]get_CallerId(&this, pbstrCallerId);

	public HRESULT get_RoutingInformation(BSTR* pbstrRoutingInformation) mut => VT.[Friend]get_RoutingInformation(&this, pbstrRoutingInformation);

	public HRESULT CopyTiff(BSTR bstrTiffPath) mut => VT.[Friend]CopyTiff(&this, bstrTiffPath);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);
}

[CRepr]struct IFaxOutgoingJobs : IDispatch
{
	public new const Guid IID = .(0x2c56d8e6, 0x8c2f, 0x4573, 0x94, 0x4c, 0xe5, 0x05, 0xf8, 0xf5, 0xae, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vIndex, IFaxOutgoingJob** pFaxOutgoingJob) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(VARIANT vIndex, IFaxOutgoingJob** pFaxOutgoingJob) mut => VT.[Friend]get_Item(&this, vIndex, pFaxOutgoingJob);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);
}

[CRepr]struct IFaxOutgoingJob : IDispatch
{
	public new const Guid IID = .(0x6356daad, 0x6614, 0x4583, 0xbf, 0x7a, 0x3a, 0xd6, 0x7b, 0xbf, 0xc7, 0x1c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubject) get_Subject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDocumentName) get_DocumentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPages) get_Pages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSize) get_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubmissionId) get_SubmissionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateOriginalScheduledTime) get_OriginalScheduledTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateSubmissionTime) get_SubmissionTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_RECEIPT_TYPE_ENUM* pReceiptType) get_ReceiptType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_PRIORITY_TYPE_ENUM* pPriority) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxSender** ppFaxSender) get_Sender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxRecipient** ppFaxRecipient) get_Recipient;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCurrentPage) get_CurrentPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDeviceId) get_DeviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_STATUS_ENUM* pStatus) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_EXTENDED_STATUS_ENUM* pExtendedStatusCode) get_ExtendedStatusCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrExtendedStatus) get_ExtendedStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_OPERATIONS_ENUM* pAvailableOperations) get_AvailableOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetries) get_Retries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateScheduledTime) get_ScheduledTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateTransmissionStart) get_TransmissionStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateTransmissionEnd) get_TransmissionEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCSID) get_CSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTSID) get_TSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbGroupBroadcastReceipts) get_GroupBroadcastReceipts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Restart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTiffPath) CopyTiff;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT get_Subject(BSTR* pbstrSubject) mut => VT.[Friend]get_Subject(&this, pbstrSubject);

	public HRESULT get_DocumentName(BSTR* pbstrDocumentName) mut => VT.[Friend]get_DocumentName(&this, pbstrDocumentName);

	public HRESULT get_Pages(int32* plPages) mut => VT.[Friend]get_Pages(&this, plPages);

	public HRESULT get_Size(int32* plSize) mut => VT.[Friend]get_Size(&this, plSize);

	public HRESULT get_SubmissionId(BSTR* pbstrSubmissionId) mut => VT.[Friend]get_SubmissionId(&this, pbstrSubmissionId);

	public HRESULT get_Id(BSTR* pbstrId) mut => VT.[Friend]get_Id(&this, pbstrId);

	public HRESULT get_OriginalScheduledTime(double* pdateOriginalScheduledTime) mut => VT.[Friend]get_OriginalScheduledTime(&this, pdateOriginalScheduledTime);

	public HRESULT get_SubmissionTime(double* pdateSubmissionTime) mut => VT.[Friend]get_SubmissionTime(&this, pdateSubmissionTime);

	public HRESULT get_ReceiptType(FAX_RECEIPT_TYPE_ENUM* pReceiptType) mut => VT.[Friend]get_ReceiptType(&this, pReceiptType);

	public HRESULT get_Priority(FAX_PRIORITY_TYPE_ENUM* pPriority) mut => VT.[Friend]get_Priority(&this, pPriority);

	public HRESULT get_Sender(IFaxSender** ppFaxSender) mut => VT.[Friend]get_Sender(&this, ppFaxSender);

	public HRESULT get_Recipient(IFaxRecipient** ppFaxRecipient) mut => VT.[Friend]get_Recipient(&this, ppFaxRecipient);

	public HRESULT get_CurrentPage(int32* plCurrentPage) mut => VT.[Friend]get_CurrentPage(&this, plCurrentPage);

	public HRESULT get_DeviceId(int32* plDeviceId) mut => VT.[Friend]get_DeviceId(&this, plDeviceId);

	public HRESULT get_Status(FAX_JOB_STATUS_ENUM* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);

	public HRESULT get_ExtendedStatusCode(FAX_JOB_EXTENDED_STATUS_ENUM* pExtendedStatusCode) mut => VT.[Friend]get_ExtendedStatusCode(&this, pExtendedStatusCode);

	public HRESULT get_ExtendedStatus(BSTR* pbstrExtendedStatus) mut => VT.[Friend]get_ExtendedStatus(&this, pbstrExtendedStatus);

	public HRESULT get_AvailableOperations(FAX_JOB_OPERATIONS_ENUM* pAvailableOperations) mut => VT.[Friend]get_AvailableOperations(&this, pAvailableOperations);

	public HRESULT get_Retries(int32* plRetries) mut => VT.[Friend]get_Retries(&this, plRetries);

	public HRESULT get_ScheduledTime(double* pdateScheduledTime) mut => VT.[Friend]get_ScheduledTime(&this, pdateScheduledTime);

	public HRESULT get_TransmissionStart(double* pdateTransmissionStart) mut => VT.[Friend]get_TransmissionStart(&this, pdateTransmissionStart);

	public HRESULT get_TransmissionEnd(double* pdateTransmissionEnd) mut => VT.[Friend]get_TransmissionEnd(&this, pdateTransmissionEnd);

	public HRESULT get_CSID(BSTR* pbstrCSID) mut => VT.[Friend]get_CSID(&this, pbstrCSID);

	public HRESULT get_TSID(BSTR* pbstrTSID) mut => VT.[Friend]get_TSID(&this, pbstrTSID);

	public HRESULT get_GroupBroadcastReceipts(int16* pbGroupBroadcastReceipts) mut => VT.[Friend]get_GroupBroadcastReceipts(&this, pbGroupBroadcastReceipts);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT Restart() mut => VT.[Friend]Restart(&this);

	public HRESULT CopyTiff(BSTR bstrTiffPath) mut => VT.[Friend]CopyTiff(&this, bstrTiffPath);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IFaxOutgoingMessageIterator : IDispatch
{
	public new const Guid IID = .(0xf5ec5d4f, 0xb840, 0x432f, 0x99, 0x80, 0x11, 0x2f, 0xe4, 0x2a, 0x9b, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxOutgoingMessage** pFaxOutgoingMessage) get_Message;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEOF) get_AtEOF;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPrefetchSize) get_PrefetchSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrefetchSize) put_PrefetchSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MoveFirst;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MoveNext;
	}


	public HRESULT get_Message(IFaxOutgoingMessage** pFaxOutgoingMessage) mut => VT.[Friend]get_Message(&this, pFaxOutgoingMessage);

	public HRESULT get_AtEOF(int16* pbEOF) mut => VT.[Friend]get_AtEOF(&this, pbEOF);

	public HRESULT get_PrefetchSize(int32* plPrefetchSize) mut => VT.[Friend]get_PrefetchSize(&this, plPrefetchSize);

	public HRESULT put_PrefetchSize(int32 lPrefetchSize) mut => VT.[Friend]put_PrefetchSize(&this, lPrefetchSize);

	public HRESULT MoveFirst() mut => VT.[Friend]MoveFirst(&this);

	public HRESULT MoveNext() mut => VT.[Friend]MoveNext(&this);
}

[CRepr]struct IFaxOutgoingMessage : IDispatch
{
	public new const Guid IID = .(0xf0ea35de, 0xcaa5, 0x4a7c, 0x82, 0xc7, 0x2b, 0x60, 0xba, 0x5f, 0x2b, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubmissionId) get_SubmissionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubject) get_Subject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDocumentName) get_DocumentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetries) get_Retries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPages) get_Pages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSize) get_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateOriginalScheduledTime) get_OriginalScheduledTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateSubmissionTime) get_SubmissionTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_PRIORITY_TYPE_ENUM* pPriority) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxSender** ppFaxSender) get_Sender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxRecipient** ppFaxRecipient) get_Recipient;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDeviceName) get_DeviceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateTransmissionStart) get_TransmissionStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateTransmissionEnd) get_TransmissionEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCSID) get_CSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTSID) get_TSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTiffPath) CopyTiff;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
	}


	public HRESULT get_SubmissionId(BSTR* pbstrSubmissionId) mut => VT.[Friend]get_SubmissionId(&this, pbstrSubmissionId);

	public HRESULT get_Id(BSTR* pbstrId) mut => VT.[Friend]get_Id(&this, pbstrId);

	public HRESULT get_Subject(BSTR* pbstrSubject) mut => VT.[Friend]get_Subject(&this, pbstrSubject);

	public HRESULT get_DocumentName(BSTR* pbstrDocumentName) mut => VT.[Friend]get_DocumentName(&this, pbstrDocumentName);

	public HRESULT get_Retries(int32* plRetries) mut => VT.[Friend]get_Retries(&this, plRetries);

	public HRESULT get_Pages(int32* plPages) mut => VT.[Friend]get_Pages(&this, plPages);

	public HRESULT get_Size(int32* plSize) mut => VT.[Friend]get_Size(&this, plSize);

	public HRESULT get_OriginalScheduledTime(double* pdateOriginalScheduledTime) mut => VT.[Friend]get_OriginalScheduledTime(&this, pdateOriginalScheduledTime);

	public HRESULT get_SubmissionTime(double* pdateSubmissionTime) mut => VT.[Friend]get_SubmissionTime(&this, pdateSubmissionTime);

	public HRESULT get_Priority(FAX_PRIORITY_TYPE_ENUM* pPriority) mut => VT.[Friend]get_Priority(&this, pPriority);

	public HRESULT get_Sender(IFaxSender** ppFaxSender) mut => VT.[Friend]get_Sender(&this, ppFaxSender);

	public HRESULT get_Recipient(IFaxRecipient** ppFaxRecipient) mut => VT.[Friend]get_Recipient(&this, ppFaxRecipient);

	public HRESULT get_DeviceName(BSTR* pbstrDeviceName) mut => VT.[Friend]get_DeviceName(&this, pbstrDeviceName);

	public HRESULT get_TransmissionStart(double* pdateTransmissionStart) mut => VT.[Friend]get_TransmissionStart(&this, pdateTransmissionStart);

	public HRESULT get_TransmissionEnd(double* pdateTransmissionEnd) mut => VT.[Friend]get_TransmissionEnd(&this, pdateTransmissionEnd);

	public HRESULT get_CSID(BSTR* pbstrCSID) mut => VT.[Friend]get_CSID(&this, pbstrCSID);

	public HRESULT get_TSID(BSTR* pbstrTSID) mut => VT.[Friend]get_TSID(&this, pbstrTSID);

	public HRESULT CopyTiff(BSTR bstrTiffPath) mut => VT.[Friend]CopyTiff(&this, bstrTiffPath);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);
}

[CRepr]struct IFaxIncomingJobs : IDispatch
{
	public new const Guid IID = .(0x011f04e9, 0x4fd6, 0x4c23, 0x95, 0x13, 0xb6, 0xb6, 0x6b, 0xb2, 0x6b, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vIndex, IFaxIncomingJob** pFaxIncomingJob) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(VARIANT vIndex, IFaxIncomingJob** pFaxIncomingJob) mut => VT.[Friend]get_Item(&this, vIndex, pFaxIncomingJob);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);
}

[CRepr]struct IFaxIncomingJob : IDispatch
{
	public new const Guid IID = .(0x207529e6, 0x654a, 0x4916, 0x9f, 0x88, 0x4d, 0x23, 0x2e, 0xe8, 0xa1, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSize) get_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCurrentPage) get_CurrentPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDeviceId) get_DeviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_STATUS_ENUM* pStatus) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_EXTENDED_STATUS_ENUM* pExtendedStatusCode) get_ExtendedStatusCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrExtendedStatus) get_ExtendedStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_OPERATIONS_ENUM* pAvailableOperations) get_AvailableOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetries) get_Retries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateTransmissionStart) get_TransmissionStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateTransmissionEnd) get_TransmissionEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCSID) get_CSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTSID) get_TSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCallerId) get_CallerId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrRoutingInformation) get_RoutingInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_JOB_TYPE_ENUM* pJobType) get_JobType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTiffPath) CopyTiff;
	}


	public HRESULT get_Size(int32* plSize) mut => VT.[Friend]get_Size(&this, plSize);

	public HRESULT get_Id(BSTR* pbstrId) mut => VT.[Friend]get_Id(&this, pbstrId);

	public HRESULT get_CurrentPage(int32* plCurrentPage) mut => VT.[Friend]get_CurrentPage(&this, plCurrentPage);

	public HRESULT get_DeviceId(int32* plDeviceId) mut => VT.[Friend]get_DeviceId(&this, plDeviceId);

	public HRESULT get_Status(FAX_JOB_STATUS_ENUM* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);

	public HRESULT get_ExtendedStatusCode(FAX_JOB_EXTENDED_STATUS_ENUM* pExtendedStatusCode) mut => VT.[Friend]get_ExtendedStatusCode(&this, pExtendedStatusCode);

	public HRESULT get_ExtendedStatus(BSTR* pbstrExtendedStatus) mut => VT.[Friend]get_ExtendedStatus(&this, pbstrExtendedStatus);

	public HRESULT get_AvailableOperations(FAX_JOB_OPERATIONS_ENUM* pAvailableOperations) mut => VT.[Friend]get_AvailableOperations(&this, pAvailableOperations);

	public HRESULT get_Retries(int32* plRetries) mut => VT.[Friend]get_Retries(&this, plRetries);

	public HRESULT get_TransmissionStart(double* pdateTransmissionStart) mut => VT.[Friend]get_TransmissionStart(&this, pdateTransmissionStart);

	public HRESULT get_TransmissionEnd(double* pdateTransmissionEnd) mut => VT.[Friend]get_TransmissionEnd(&this, pdateTransmissionEnd);

	public HRESULT get_CSID(BSTR* pbstrCSID) mut => VT.[Friend]get_CSID(&this, pbstrCSID);

	public HRESULT get_TSID(BSTR* pbstrTSID) mut => VT.[Friend]get_TSID(&this, pbstrTSID);

	public HRESULT get_CallerId(BSTR* pbstrCallerId) mut => VT.[Friend]get_CallerId(&this, pbstrCallerId);

	public HRESULT get_RoutingInformation(BSTR* pbstrRoutingInformation) mut => VT.[Friend]get_RoutingInformation(&this, pbstrRoutingInformation);

	public HRESULT get_JobType(FAX_JOB_TYPE_ENUM* pJobType) mut => VT.[Friend]get_JobType(&this, pJobType);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT CopyTiff(BSTR bstrTiffPath) mut => VT.[Friend]CopyTiff(&this, bstrTiffPath);
}

[CRepr]struct IFaxDeviceProvider : IDispatch
{
	public new const Guid IID = .(0x290eac63, 0x83ec, 0x449c, 0x84, 0x17, 0xf1, 0x48, 0xdf, 0x8c, 0x68, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFriendlyName) get_FriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrImageName) get_ImageName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrUniqueName) get_UniqueName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTapiProviderName) get_TapiProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMajorVersion) get_MajorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMinorVersion) get_MinorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMajorBuild) get_MajorBuild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMinorBuild) get_MinorBuild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbDebug) get_Debug;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_PROVIDER_STATUS_ENUM* pStatus) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plInitErrorCode) get_InitErrorCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvDeviceIds) get_DeviceIds;
	}


	public HRESULT get_FriendlyName(BSTR* pbstrFriendlyName) mut => VT.[Friend]get_FriendlyName(&this, pbstrFriendlyName);

	public HRESULT get_ImageName(BSTR* pbstrImageName) mut => VT.[Friend]get_ImageName(&this, pbstrImageName);

	public HRESULT get_UniqueName(BSTR* pbstrUniqueName) mut => VT.[Friend]get_UniqueName(&this, pbstrUniqueName);

	public HRESULT get_TapiProviderName(BSTR* pbstrTapiProviderName) mut => VT.[Friend]get_TapiProviderName(&this, pbstrTapiProviderName);

	public HRESULT get_MajorVersion(int32* plMajorVersion) mut => VT.[Friend]get_MajorVersion(&this, plMajorVersion);

	public HRESULT get_MinorVersion(int32* plMinorVersion) mut => VT.[Friend]get_MinorVersion(&this, plMinorVersion);

	public HRESULT get_MajorBuild(int32* plMajorBuild) mut => VT.[Friend]get_MajorBuild(&this, plMajorBuild);

	public HRESULT get_MinorBuild(int32* plMinorBuild) mut => VT.[Friend]get_MinorBuild(&this, plMinorBuild);

	public HRESULT get_Debug(int16* pbDebug) mut => VT.[Friend]get_Debug(&this, pbDebug);

	public HRESULT get_Status(FAX_PROVIDER_STATUS_ENUM* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);

	public HRESULT get_InitErrorCode(int32* plInitErrorCode) mut => VT.[Friend]get_InitErrorCode(&this, plInitErrorCode);

	public HRESULT get_DeviceIds(VARIANT* pvDeviceIds) mut => VT.[Friend]get_DeviceIds(&this, pvDeviceIds);
}

[CRepr]struct IFaxDevice : IDispatch
{
	public new const Guid IID = .(0x49306c59, 0xb52e, 0x4867, 0x9d, 0xf4, 0xca, 0x58, 0x41, 0xc9, 0x56, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDeviceName) get_DeviceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProviderUniqueName) get_ProviderUniqueName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbPoweredOff) get_PoweredOff;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbReceivingNow) get_ReceivingNow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbSendingNow) get_SendingNow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvUsedRoutingMethods) get_UsedRoutingMethods;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbSendEnabled) get_SendEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bSendEnabled) put_SendEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_DEVICE_RECEIVE_MODE_ENUM* pReceiveMode) get_ReceiveMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_DEVICE_RECEIVE_MODE_ENUM ReceiveMode) put_ReceiveMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRingsBeforeAnswer) get_RingsBeforeAnswer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRingsBeforeAnswer) put_RingsBeforeAnswer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCSID) get_CSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCSID) put_CSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTSID) get_TSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTSID) put_TSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGUID, VARIANT* pvProperty) GetExtensionProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGUID, VARIANT vProperty) SetExtensionProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMethodGUID, int16 bUse) UseRoutingMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbRingingNow) get_RingingNow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AnswerCall;
	}


	public HRESULT get_Id(int32* plId) mut => VT.[Friend]get_Id(&this, plId);

	public HRESULT get_DeviceName(BSTR* pbstrDeviceName) mut => VT.[Friend]get_DeviceName(&this, pbstrDeviceName);

	public HRESULT get_ProviderUniqueName(BSTR* pbstrProviderUniqueName) mut => VT.[Friend]get_ProviderUniqueName(&this, pbstrProviderUniqueName);

	public HRESULT get_PoweredOff(int16* pbPoweredOff) mut => VT.[Friend]get_PoweredOff(&this, pbPoweredOff);

	public HRESULT get_ReceivingNow(int16* pbReceivingNow) mut => VT.[Friend]get_ReceivingNow(&this, pbReceivingNow);

	public HRESULT get_SendingNow(int16* pbSendingNow) mut => VT.[Friend]get_SendingNow(&this, pbSendingNow);

	public HRESULT get_UsedRoutingMethods(VARIANT* pvUsedRoutingMethods) mut => VT.[Friend]get_UsedRoutingMethods(&this, pvUsedRoutingMethods);

	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_SendEnabled(int16* pbSendEnabled) mut => VT.[Friend]get_SendEnabled(&this, pbSendEnabled);

	public HRESULT put_SendEnabled(int16 bSendEnabled) mut => VT.[Friend]put_SendEnabled(&this, bSendEnabled);

	public HRESULT get_ReceiveMode(FAX_DEVICE_RECEIVE_MODE_ENUM* pReceiveMode) mut => VT.[Friend]get_ReceiveMode(&this, pReceiveMode);

	public HRESULT put_ReceiveMode(FAX_DEVICE_RECEIVE_MODE_ENUM ReceiveMode) mut => VT.[Friend]put_ReceiveMode(&this, ReceiveMode);

	public HRESULT get_RingsBeforeAnswer(int32* plRingsBeforeAnswer) mut => VT.[Friend]get_RingsBeforeAnswer(&this, plRingsBeforeAnswer);

	public HRESULT put_RingsBeforeAnswer(int32 lRingsBeforeAnswer) mut => VT.[Friend]put_RingsBeforeAnswer(&this, lRingsBeforeAnswer);

	public HRESULT get_CSID(BSTR* pbstrCSID) mut => VT.[Friend]get_CSID(&this, pbstrCSID);

	public HRESULT put_CSID(BSTR bstrCSID) mut => VT.[Friend]put_CSID(&this, bstrCSID);

	public HRESULT get_TSID(BSTR* pbstrTSID) mut => VT.[Friend]get_TSID(&this, pbstrTSID);

	public HRESULT put_TSID(BSTR bstrTSID) mut => VT.[Friend]put_TSID(&this, bstrTSID);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT GetExtensionProperty(BSTR bstrGUID, VARIANT* pvProperty) mut => VT.[Friend]GetExtensionProperty(&this, bstrGUID, pvProperty);

	public HRESULT SetExtensionProperty(BSTR bstrGUID, VARIANT vProperty) mut => VT.[Friend]SetExtensionProperty(&this, bstrGUID, vProperty);

	public HRESULT UseRoutingMethod(BSTR bstrMethodGUID, int16 bUse) mut => VT.[Friend]UseRoutingMethod(&this, bstrMethodGUID, bUse);

	public HRESULT get_RingingNow(int16* pbRingingNow) mut => VT.[Friend]get_RingingNow(&this, pbRingingNow);

	public HRESULT AnswerCall() mut => VT.[Friend]AnswerCall(&this);
}

[CRepr]struct IFaxActivityLogging : IDispatch
{
	public new const Guid IID = .(0x1e29078b, 0x5a69, 0x497b, 0x95, 0x92, 0x49, 0xb7, 0xe7, 0xfa, 0xdd, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbLogIncoming) get_LogIncoming;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bLogIncoming) put_LogIncoming;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbLogOutgoing) get_LogOutgoing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bLogOutgoing) put_LogOutgoing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDatabasePath) get_DatabasePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDatabasePath) put_DatabasePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
	}


	public HRESULT get_LogIncoming(int16* pbLogIncoming) mut => VT.[Friend]get_LogIncoming(&this, pbLogIncoming);

	public HRESULT put_LogIncoming(int16 bLogIncoming) mut => VT.[Friend]put_LogIncoming(&this, bLogIncoming);

	public HRESULT get_LogOutgoing(int16* pbLogOutgoing) mut => VT.[Friend]get_LogOutgoing(&this, pbLogOutgoing);

	public HRESULT put_LogOutgoing(int16 bLogOutgoing) mut => VT.[Friend]put_LogOutgoing(&this, bLogOutgoing);

	public HRESULT get_DatabasePath(BSTR* pbstrDatabasePath) mut => VT.[Friend]get_DatabasePath(&this, pbstrDatabasePath);

	public HRESULT put_DatabasePath(BSTR bstrDatabasePath) mut => VT.[Friend]put_DatabasePath(&this, bstrDatabasePath);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);
}

[CRepr]struct IFaxEventLogging : IDispatch
{
	public new const Guid IID = .(0x0880d965, 0x20e8, 0x42e4, 0x8e, 0x17, 0x94, 0x4f, 0x19, 0x2c, 0xaa, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_LOG_LEVEL_ENUM* pInitEventLevel) get_InitEventsLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_LOG_LEVEL_ENUM InitEventLevel) put_InitEventsLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_LOG_LEVEL_ENUM* pInboundEventLevel) get_InboundEventsLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_LOG_LEVEL_ENUM InboundEventLevel) put_InboundEventsLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_LOG_LEVEL_ENUM* pOutboundEventLevel) get_OutboundEventsLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_LOG_LEVEL_ENUM OutboundEventLevel) put_OutboundEventsLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_LOG_LEVEL_ENUM* pGeneralEventLevel) get_GeneralEventsLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_LOG_LEVEL_ENUM GeneralEventLevel) put_GeneralEventsLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
	}


	public HRESULT get_InitEventsLevel(FAX_LOG_LEVEL_ENUM* pInitEventLevel) mut => VT.[Friend]get_InitEventsLevel(&this, pInitEventLevel);

	public HRESULT put_InitEventsLevel(FAX_LOG_LEVEL_ENUM InitEventLevel) mut => VT.[Friend]put_InitEventsLevel(&this, InitEventLevel);

	public HRESULT get_InboundEventsLevel(FAX_LOG_LEVEL_ENUM* pInboundEventLevel) mut => VT.[Friend]get_InboundEventsLevel(&this, pInboundEventLevel);

	public HRESULT put_InboundEventsLevel(FAX_LOG_LEVEL_ENUM InboundEventLevel) mut => VT.[Friend]put_InboundEventsLevel(&this, InboundEventLevel);

	public HRESULT get_OutboundEventsLevel(FAX_LOG_LEVEL_ENUM* pOutboundEventLevel) mut => VT.[Friend]get_OutboundEventsLevel(&this, pOutboundEventLevel);

	public HRESULT put_OutboundEventsLevel(FAX_LOG_LEVEL_ENUM OutboundEventLevel) mut => VT.[Friend]put_OutboundEventsLevel(&this, OutboundEventLevel);

	public HRESULT get_GeneralEventsLevel(FAX_LOG_LEVEL_ENUM* pGeneralEventLevel) mut => VT.[Friend]get_GeneralEventsLevel(&this, pGeneralEventLevel);

	public HRESULT put_GeneralEventsLevel(FAX_LOG_LEVEL_ENUM GeneralEventLevel) mut => VT.[Friend]put_GeneralEventsLevel(&this, GeneralEventLevel);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);
}

[CRepr]struct IFaxOutboundRoutingGroups : IDispatch
{
	public new const Guid IID = .(0x235cbef7, 0xc2de, 0x4bfd, 0xb8, 0xda, 0x75, 0x09, 0x7c, 0x82, 0xc8, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vIndex, IFaxOutboundRoutingGroup** pFaxOutboundRoutingGroup) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IFaxOutboundRoutingGroup** pFaxOutboundRoutingGroup) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vIndex) Remove;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(VARIANT vIndex, IFaxOutboundRoutingGroup** pFaxOutboundRoutingGroup) mut => VT.[Friend]get_Item(&this, vIndex, pFaxOutboundRoutingGroup);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT Add(BSTR bstrName, IFaxOutboundRoutingGroup** pFaxOutboundRoutingGroup) mut => VT.[Friend]Add(&this, bstrName, pFaxOutboundRoutingGroup);

	public HRESULT Remove(VARIANT vIndex) mut => VT.[Friend]Remove(&this, vIndex);
}

[CRepr]struct IFaxOutboundRoutingGroup : IDispatch
{
	public new const Guid IID = .(0xca6289a1, 0x7e25, 0x4f87, 0x9a, 0x0b, 0x93, 0x36, 0x57, 0x34, 0x96, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_GROUP_STATUS_ENUM* pStatus) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxDeviceIds** pFaxDeviceIds) get_DeviceIds;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT get_Status(FAX_GROUP_STATUS_ENUM* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);

	public HRESULT get_DeviceIds(IFaxDeviceIds** pFaxDeviceIds) mut => VT.[Friend]get_DeviceIds(&this, pFaxDeviceIds);
}

[CRepr]struct IFaxDeviceIds : IDispatch
{
	public new const Guid IID = .(0x2f0f813f, 0x4ce9, 0x443e, 0x8c, 0xa1, 0x73, 0x8c, 0xfa, 0xee, 0xe1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, int32* plDeviceId) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDeviceId) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDeviceId, int32 lNewOrder) SetOrder;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(int32 lIndex, int32* plDeviceId) mut => VT.[Friend]get_Item(&this, lIndex, plDeviceId);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT Add(int32 lDeviceId) mut => VT.[Friend]Add(&this, lDeviceId);

	public HRESULT Remove(int32 lIndex) mut => VT.[Friend]Remove(&this, lIndex);

	public HRESULT SetOrder(int32 lDeviceId, int32 lNewOrder) mut => VT.[Friend]SetOrder(&this, lDeviceId, lNewOrder);
}

[CRepr]struct IFaxOutboundRoutingRules : IDispatch
{
	public new const Guid IID = .(0xdcefa1e7, 0xae7d, 0x4ed6, 0x85, 0x21, 0x36, 0x9e, 0xdc, 0xca, 0x51, 0x20);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, IFaxOutboundRoutingRule** pFaxOutboundRoutingRule) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCountryCode, int32 lAreaCode, IFaxOutboundRoutingRule** pFaxOutboundRoutingRule) ItemByCountryAndArea;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCountryCode, int32 lAreaCode) RemoveByCountryAndArea;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCountryCode, int32 lAreaCode, int16 bUseDevice, BSTR bstrGroupName, int32 lDeviceId, IFaxOutboundRoutingRule** pFaxOutboundRoutingRule) Add;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(int32 lIndex, IFaxOutboundRoutingRule** pFaxOutboundRoutingRule) mut => VT.[Friend]get_Item(&this, lIndex, pFaxOutboundRoutingRule);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT ItemByCountryAndArea(int32 lCountryCode, int32 lAreaCode, IFaxOutboundRoutingRule** pFaxOutboundRoutingRule) mut => VT.[Friend]ItemByCountryAndArea(&this, lCountryCode, lAreaCode, pFaxOutboundRoutingRule);

	public HRESULT RemoveByCountryAndArea(int32 lCountryCode, int32 lAreaCode) mut => VT.[Friend]RemoveByCountryAndArea(&this, lCountryCode, lAreaCode);

	public HRESULT Remove(int32 lIndex) mut => VT.[Friend]Remove(&this, lIndex);

	public HRESULT Add(int32 lCountryCode, int32 lAreaCode, int16 bUseDevice, BSTR bstrGroupName, int32 lDeviceId, IFaxOutboundRoutingRule** pFaxOutboundRoutingRule) mut => VT.[Friend]Add(&this, lCountryCode, lAreaCode, bUseDevice, bstrGroupName, lDeviceId, pFaxOutboundRoutingRule);
}

[CRepr]struct IFaxOutboundRoutingRule : IDispatch
{
	public new const Guid IID = .(0xe1f795d5, 0x07c2, 0x469f, 0xb0, 0x27, 0xac, 0xac, 0xc2, 0x32, 0x19, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCountryCode) get_CountryCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAreaCode) get_AreaCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_RULE_STATUS_ENUM* pStatus) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbUseDevice) get_UseDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bUseDevice) put_UseDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDeviceId) get_DeviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 DeviceId) put_DeviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGroupName) get_GroupName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName) put_GroupName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
	}


	public HRESULT get_CountryCode(int32* plCountryCode) mut => VT.[Friend]get_CountryCode(&this, plCountryCode);

	public HRESULT get_AreaCode(int32* plAreaCode) mut => VT.[Friend]get_AreaCode(&this, plAreaCode);

	public HRESULT get_Status(FAX_RULE_STATUS_ENUM* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);

	public HRESULT get_UseDevice(int16* pbUseDevice) mut => VT.[Friend]get_UseDevice(&this, pbUseDevice);

	public HRESULT put_UseDevice(int16 bUseDevice) mut => VT.[Friend]put_UseDevice(&this, bUseDevice);

	public HRESULT get_DeviceId(int32* plDeviceId) mut => VT.[Friend]get_DeviceId(&this, plDeviceId);

	public HRESULT put_DeviceId(int32 DeviceId) mut => VT.[Friend]put_DeviceId(&this, DeviceId);

	public HRESULT get_GroupName(BSTR* pbstrGroupName) mut => VT.[Friend]get_GroupName(&this, pbstrGroupName);

	public HRESULT put_GroupName(BSTR bstrGroupName) mut => VT.[Friend]put_GroupName(&this, bstrGroupName);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);
}

[CRepr]struct IFaxInboundRoutingExtensions : IDispatch
{
	public new const Guid IID = .(0x2f6c9673, 0x7b26, 0x42de, 0x8e, 0xb0, 0x91, 0x5d, 0xcd, 0x2a, 0x4f, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vIndex, IFaxInboundRoutingExtension** pFaxInboundRoutingExtension) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(VARIANT vIndex, IFaxInboundRoutingExtension** pFaxInboundRoutingExtension) mut => VT.[Friend]get_Item(&this, vIndex, pFaxInboundRoutingExtension);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);
}

[CRepr]struct IFaxInboundRoutingExtension : IDispatch
{
	public new const Guid IID = .(0x885b5e08, 0xc26c, 0x4ef9, 0xaf, 0x83, 0x51, 0x58, 0x0a, 0x75, 0x0b, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFriendlyName) get_FriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrImageName) get_ImageName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrUniqueName) get_UniqueName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMajorVersion) get_MajorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMinorVersion) get_MinorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMajorBuild) get_MajorBuild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMinorBuild) get_MinorBuild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbDebug) get_Debug;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_PROVIDER_STATUS_ENUM* pStatus) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plInitErrorCode) get_InitErrorCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvMethods) get_Methods;
	}


	public HRESULT get_FriendlyName(BSTR* pbstrFriendlyName) mut => VT.[Friend]get_FriendlyName(&this, pbstrFriendlyName);

	public HRESULT get_ImageName(BSTR* pbstrImageName) mut => VT.[Friend]get_ImageName(&this, pbstrImageName);

	public HRESULT get_UniqueName(BSTR* pbstrUniqueName) mut => VT.[Friend]get_UniqueName(&this, pbstrUniqueName);

	public HRESULT get_MajorVersion(int32* plMajorVersion) mut => VT.[Friend]get_MajorVersion(&this, plMajorVersion);

	public HRESULT get_MinorVersion(int32* plMinorVersion) mut => VT.[Friend]get_MinorVersion(&this, plMinorVersion);

	public HRESULT get_MajorBuild(int32* plMajorBuild) mut => VT.[Friend]get_MajorBuild(&this, plMajorBuild);

	public HRESULT get_MinorBuild(int32* plMinorBuild) mut => VT.[Friend]get_MinorBuild(&this, plMinorBuild);

	public HRESULT get_Debug(int16* pbDebug) mut => VT.[Friend]get_Debug(&this, pbDebug);

	public HRESULT get_Status(FAX_PROVIDER_STATUS_ENUM* pStatus) mut => VT.[Friend]get_Status(&this, pStatus);

	public HRESULT get_InitErrorCode(int32* plInitErrorCode) mut => VT.[Friend]get_InitErrorCode(&this, plInitErrorCode);

	public HRESULT get_Methods(VARIANT* pvMethods) mut => VT.[Friend]get_Methods(&this, pvMethods);
}

[CRepr]struct IFaxInboundRoutingMethods : IDispatch
{
	public new const Guid IID = .(0x783fca10, 0x8908, 0x4473, 0x9d, 0x69, 0xf6, 0x7f, 0xbe, 0xa0, 0xc6, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vIndex, IFaxInboundRoutingMethod** pFaxInboundRoutingMethod) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(VARIANT vIndex, IFaxInboundRoutingMethod** pFaxInboundRoutingMethod) mut => VT.[Friend]get_Item(&this, vIndex, pFaxInboundRoutingMethod);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);
}

[CRepr]struct IFaxInboundRoutingMethod : IDispatch
{
	public new const Guid IID = .(0x45700061, 0xad9d, 0x4776, 0xa8, 0xc4, 0x64, 0x06, 0x54, 0x92, 0xcf, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGUID) get_GUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFunctionName) get_FunctionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrExtensionFriendlyName) get_ExtensionFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrExtensionImageName) get_ExtensionImageName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPriority) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPriority) put_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT get_GUID(BSTR* pbstrGUID) mut => VT.[Friend]get_GUID(&this, pbstrGUID);

	public HRESULT get_FunctionName(BSTR* pbstrFunctionName) mut => VT.[Friend]get_FunctionName(&this, pbstrFunctionName);

	public HRESULT get_ExtensionFriendlyName(BSTR* pbstrExtensionFriendlyName) mut => VT.[Friend]get_ExtensionFriendlyName(&this, pbstrExtensionFriendlyName);

	public HRESULT get_ExtensionImageName(BSTR* pbstrExtensionImageName) mut => VT.[Friend]get_ExtensionImageName(&this, pbstrExtensionImageName);

	public HRESULT get_Priority(int32* plPriority) mut => VT.[Friend]get_Priority(&this, plPriority);

	public HRESULT put_Priority(int32 lPriority) mut => VT.[Friend]put_Priority(&this, lPriority);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);
}

[CRepr]struct IFaxDocument2 : IFaxDocument
{
	public new const Guid IID = .(0xe1347661, 0xf9ef, 0x4d6d, 0xb4, 0xa5, 0xc0, 0xa0, 0x68, 0xb6, 0x5c, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFaxDocument.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubmissionId) get_SubmissionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvBodies) get_Bodies;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vBodies) put_Bodies;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFaxServerName, VARIANT* pvFaxOutgoingJobIDs, int32* plErrorBodyFile) Submit2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer* pFaxServer, VARIANT* pvFaxOutgoingJobIDs, int32* plErrorBodyFile) ConnectedSubmit2;
	}


	public HRESULT get_SubmissionId(BSTR* pbstrSubmissionId) mut => VT.[Friend]get_SubmissionId(&this, pbstrSubmissionId);

	public HRESULT get_Bodies(VARIANT* pvBodies) mut => VT.[Friend]get_Bodies(&this, pvBodies);

	public HRESULT put_Bodies(VARIANT vBodies) mut => VT.[Friend]put_Bodies(&this, vBodies);

	public HRESULT Submit2(BSTR bstrFaxServerName, VARIANT* pvFaxOutgoingJobIDs, int32* plErrorBodyFile) mut => VT.[Friend]Submit2(&this, bstrFaxServerName, pvFaxOutgoingJobIDs, plErrorBodyFile);

	public HRESULT ConnectedSubmit2(IFaxServer* pFaxServer, VARIANT* pvFaxOutgoingJobIDs, int32* plErrorBodyFile) mut => VT.[Friend]ConnectedSubmit2(&this, pFaxServer, pvFaxOutgoingJobIDs, plErrorBodyFile);
}

[CRepr]struct IFaxConfiguration : IDispatch
{
	public new const Guid IID = .(0x10f4d0f7, 0x0994, 0x4543, 0xab, 0x6e, 0x50, 0x69, 0x49, 0x12, 0x8c, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbUseArchive) get_UseArchive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bUseArchive) put_UseArchive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrArchiveLocation) get_ArchiveLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrArchiveLocation) put_ArchiveLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbSizeQuotaWarning) get_SizeQuotaWarning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bSizeQuotaWarning) put_SizeQuotaWarning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHighQuotaWaterMark) get_HighQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lHighQuotaWaterMark) put_HighQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plLowQuotaWaterMark) get_LowQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lLowQuotaWaterMark) put_LowQuotaWaterMark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plArchiveAgeLimit) get_ArchiveAgeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lArchiveAgeLimit) put_ArchiveAgeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSizeLow) get_ArchiveSizeLow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSizeHigh) get_ArchiveSizeHigh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbOutgoingBlocked) get_OutgoingQueueBlocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bOutgoingBlocked) put_OutgoingQueueBlocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbOutgoingPaused) get_OutgoingQueuePaused;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bOutgoingPaused) put_OutgoingQueuePaused;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbAllowPersonalCoverPages) get_AllowPersonalCoverPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bAllowPersonalCoverPages) put_AllowPersonalCoverPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbUseDeviceTSID) get_UseDeviceTSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bUseDeviceTSID) put_UseDeviceTSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetries) get_Retries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRetries) put_Retries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRetryDelay) get_RetryDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRetryDelay) put_RetryDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateDiscountRateStart) get_DiscountRateStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dateDiscountRateStart) put_DiscountRateStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdateDiscountRateEnd) get_DiscountRateEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dateDiscountRateEnd) put_DiscountRateEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plOutgoingQueueAgeLimit) get_OutgoingQueueAgeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lOutgoingQueueAgeLimit) put_OutgoingQueueAgeLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbBranding) get_Branding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bBranding) put_Branding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIncomingBlocked) get_IncomingQueueBlocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bIncomingBlocked) put_IncomingQueueBlocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbAutoCreateAccountOnConnect) get_AutoCreateAccountOnConnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bAutoCreateAccountOnConnect) put_AutoCreateAccountOnConnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIncomingFaxesArePublic) get_IncomingFaxesArePublic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bIncomingFaxesArePublic) put_IncomingFaxesArePublic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
	}


	public HRESULT get_UseArchive(int16* pbUseArchive) mut => VT.[Friend]get_UseArchive(&this, pbUseArchive);

	public HRESULT put_UseArchive(int16 bUseArchive) mut => VT.[Friend]put_UseArchive(&this, bUseArchive);

	public HRESULT get_ArchiveLocation(BSTR* pbstrArchiveLocation) mut => VT.[Friend]get_ArchiveLocation(&this, pbstrArchiveLocation);

	public HRESULT put_ArchiveLocation(BSTR bstrArchiveLocation) mut => VT.[Friend]put_ArchiveLocation(&this, bstrArchiveLocation);

	public HRESULT get_SizeQuotaWarning(int16* pbSizeQuotaWarning) mut => VT.[Friend]get_SizeQuotaWarning(&this, pbSizeQuotaWarning);

	public HRESULT put_SizeQuotaWarning(int16 bSizeQuotaWarning) mut => VT.[Friend]put_SizeQuotaWarning(&this, bSizeQuotaWarning);

	public HRESULT get_HighQuotaWaterMark(int32* plHighQuotaWaterMark) mut => VT.[Friend]get_HighQuotaWaterMark(&this, plHighQuotaWaterMark);

	public HRESULT put_HighQuotaWaterMark(int32 lHighQuotaWaterMark) mut => VT.[Friend]put_HighQuotaWaterMark(&this, lHighQuotaWaterMark);

	public HRESULT get_LowQuotaWaterMark(int32* plLowQuotaWaterMark) mut => VT.[Friend]get_LowQuotaWaterMark(&this, plLowQuotaWaterMark);

	public HRESULT put_LowQuotaWaterMark(int32 lLowQuotaWaterMark) mut => VT.[Friend]put_LowQuotaWaterMark(&this, lLowQuotaWaterMark);

	public HRESULT get_ArchiveAgeLimit(int32* plArchiveAgeLimit) mut => VT.[Friend]get_ArchiveAgeLimit(&this, plArchiveAgeLimit);

	public HRESULT put_ArchiveAgeLimit(int32 lArchiveAgeLimit) mut => VT.[Friend]put_ArchiveAgeLimit(&this, lArchiveAgeLimit);

	public HRESULT get_ArchiveSizeLow(int32* plSizeLow) mut => VT.[Friend]get_ArchiveSizeLow(&this, plSizeLow);

	public HRESULT get_ArchiveSizeHigh(int32* plSizeHigh) mut => VT.[Friend]get_ArchiveSizeHigh(&this, plSizeHigh);

	public HRESULT get_OutgoingQueueBlocked(int16* pbOutgoingBlocked) mut => VT.[Friend]get_OutgoingQueueBlocked(&this, pbOutgoingBlocked);

	public HRESULT put_OutgoingQueueBlocked(int16 bOutgoingBlocked) mut => VT.[Friend]put_OutgoingQueueBlocked(&this, bOutgoingBlocked);

	public HRESULT get_OutgoingQueuePaused(int16* pbOutgoingPaused) mut => VT.[Friend]get_OutgoingQueuePaused(&this, pbOutgoingPaused);

	public HRESULT put_OutgoingQueuePaused(int16 bOutgoingPaused) mut => VT.[Friend]put_OutgoingQueuePaused(&this, bOutgoingPaused);

	public HRESULT get_AllowPersonalCoverPages(int16* pbAllowPersonalCoverPages) mut => VT.[Friend]get_AllowPersonalCoverPages(&this, pbAllowPersonalCoverPages);

	public HRESULT put_AllowPersonalCoverPages(int16 bAllowPersonalCoverPages) mut => VT.[Friend]put_AllowPersonalCoverPages(&this, bAllowPersonalCoverPages);

	public HRESULT get_UseDeviceTSID(int16* pbUseDeviceTSID) mut => VT.[Friend]get_UseDeviceTSID(&this, pbUseDeviceTSID);

	public HRESULT put_UseDeviceTSID(int16 bUseDeviceTSID) mut => VT.[Friend]put_UseDeviceTSID(&this, bUseDeviceTSID);

	public HRESULT get_Retries(int32* plRetries) mut => VT.[Friend]get_Retries(&this, plRetries);

	public HRESULT put_Retries(int32 lRetries) mut => VT.[Friend]put_Retries(&this, lRetries);

	public HRESULT get_RetryDelay(int32* plRetryDelay) mut => VT.[Friend]get_RetryDelay(&this, plRetryDelay);

	public HRESULT put_RetryDelay(int32 lRetryDelay) mut => VT.[Friend]put_RetryDelay(&this, lRetryDelay);

	public HRESULT get_DiscountRateStart(double* pdateDiscountRateStart) mut => VT.[Friend]get_DiscountRateStart(&this, pdateDiscountRateStart);

	public HRESULT put_DiscountRateStart(double dateDiscountRateStart) mut => VT.[Friend]put_DiscountRateStart(&this, dateDiscountRateStart);

	public HRESULT get_DiscountRateEnd(double* pdateDiscountRateEnd) mut => VT.[Friend]get_DiscountRateEnd(&this, pdateDiscountRateEnd);

	public HRESULT put_DiscountRateEnd(double dateDiscountRateEnd) mut => VT.[Friend]put_DiscountRateEnd(&this, dateDiscountRateEnd);

	public HRESULT get_OutgoingQueueAgeLimit(int32* plOutgoingQueueAgeLimit) mut => VT.[Friend]get_OutgoingQueueAgeLimit(&this, plOutgoingQueueAgeLimit);

	public HRESULT put_OutgoingQueueAgeLimit(int32 lOutgoingQueueAgeLimit) mut => VT.[Friend]put_OutgoingQueueAgeLimit(&this, lOutgoingQueueAgeLimit);

	public HRESULT get_Branding(int16* pbBranding) mut => VT.[Friend]get_Branding(&this, pbBranding);

	public HRESULT put_Branding(int16 bBranding) mut => VT.[Friend]put_Branding(&this, bBranding);

	public HRESULT get_IncomingQueueBlocked(int16* pbIncomingBlocked) mut => VT.[Friend]get_IncomingQueueBlocked(&this, pbIncomingBlocked);

	public HRESULT put_IncomingQueueBlocked(int16 bIncomingBlocked) mut => VT.[Friend]put_IncomingQueueBlocked(&this, bIncomingBlocked);

	public HRESULT get_AutoCreateAccountOnConnect(int16* pbAutoCreateAccountOnConnect) mut => VT.[Friend]get_AutoCreateAccountOnConnect(&this, pbAutoCreateAccountOnConnect);

	public HRESULT put_AutoCreateAccountOnConnect(int16 bAutoCreateAccountOnConnect) mut => VT.[Friend]put_AutoCreateAccountOnConnect(&this, bAutoCreateAccountOnConnect);

	public HRESULT get_IncomingFaxesArePublic(int16* pbIncomingFaxesArePublic) mut => VT.[Friend]get_IncomingFaxesArePublic(&this, pbIncomingFaxesArePublic);

	public HRESULT put_IncomingFaxesArePublic(int16 bIncomingFaxesArePublic) mut => VT.[Friend]put_IncomingFaxesArePublic(&this, bIncomingFaxesArePublic);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);
}

[CRepr]struct IFaxServer2 : IFaxServer
{
	public new const Guid IID = .(0x571ced0f, 0x5609, 0x4f40, 0x91, 0x76, 0x54, 0x7e, 0x3a, 0x72, 0xca, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFaxServer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxConfiguration** ppFaxConfiguration) get_Configuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount** ppCurrentAccount) get_CurrentAccount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccountSet** ppFaxAccountSet) get_FaxAccountSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxSecurity2** ppFaxSecurity2) get_Security2;
	}


	public HRESULT get_Configuration(IFaxConfiguration** ppFaxConfiguration) mut => VT.[Friend]get_Configuration(&this, ppFaxConfiguration);

	public HRESULT get_CurrentAccount(IFaxAccount** ppCurrentAccount) mut => VT.[Friend]get_CurrentAccount(&this, ppCurrentAccount);

	public HRESULT get_FaxAccountSet(IFaxAccountSet** ppFaxAccountSet) mut => VT.[Friend]get_FaxAccountSet(&this, ppFaxAccountSet);

	public HRESULT get_Security2(IFaxSecurity2** ppFaxSecurity2) mut => VT.[Friend]get_Security2(&this, ppFaxSecurity2);
}

[CRepr]struct IFaxAccountSet : IDispatch
{
	public new const Guid IID = .(0x7428fbae, 0x841e, 0x47b8, 0x86, 0xf4, 0x22, 0x88, 0x94, 0x6d, 0xca, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccounts** ppFaxAccounts) GetAccounts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAccountName, IFaxAccount** pFaxAccount) GetAccount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAccountName, IFaxAccount** pFaxAccount) AddAccount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAccountName) RemoveAccount;
	}


	public HRESULT GetAccounts(IFaxAccounts** ppFaxAccounts) mut => VT.[Friend]GetAccounts(&this, ppFaxAccounts);

	public HRESULT GetAccount(BSTR bstrAccountName, IFaxAccount** pFaxAccount) mut => VT.[Friend]GetAccount(&this, bstrAccountName, pFaxAccount);

	public HRESULT AddAccount(BSTR bstrAccountName, IFaxAccount** pFaxAccount) mut => VT.[Friend]AddAccount(&this, bstrAccountName, pFaxAccount);

	public HRESULT RemoveAccount(BSTR bstrAccountName) mut => VT.[Friend]RemoveAccount(&this, bstrAccountName);
}

[CRepr]struct IFaxAccounts : IDispatch
{
	public new const Guid IID = .(0x93ea8162, 0x8be7, 0x42d1, 0xae, 0x7b, 0xec, 0x74, 0xe2, 0xd9, 0x89, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnk) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vIndex, IFaxAccount** pFaxAccount) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnk) mut => VT.[Friend]get__NewEnum(&this, ppUnk);

	public HRESULT get_Item(VARIANT vIndex, IFaxAccount** pFaxAccount) mut => VT.[Friend]get_Item(&this, vIndex, pFaxAccount);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);
}

[CRepr]struct IFaxAccount : IDispatch
{
	public new const Guid IID = .(0x68535b33, 0x5dc4, 0x4086, 0xbe, 0x26, 0xb7, 0x6f, 0x9b, 0x71, 0x10, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrAccountName) get_AccountName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccountFolders** ppFolders) get_Folders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_ACCOUNT_EVENTS_TYPE_ENUM EventTypes) ListenToAccountEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_ACCOUNT_EVENTS_TYPE_ENUM* pRegisteredEvents) get_RegisteredEvents;
	}


	public HRESULT get_AccountName(BSTR* pbstrAccountName) mut => VT.[Friend]get_AccountName(&this, pbstrAccountName);

	public HRESULT get_Folders(IFaxAccountFolders** ppFolders) mut => VT.[Friend]get_Folders(&this, ppFolders);

	public HRESULT ListenToAccountEvents(FAX_ACCOUNT_EVENTS_TYPE_ENUM EventTypes) mut => VT.[Friend]ListenToAccountEvents(&this, EventTypes);

	public HRESULT get_RegisteredEvents(FAX_ACCOUNT_EVENTS_TYPE_ENUM* pRegisteredEvents) mut => VT.[Friend]get_RegisteredEvents(&this, pRegisteredEvents);
}

[CRepr]struct IFaxOutgoingJob2 : IFaxOutgoingJob
{
	public new const Guid IID = .(0x418a8d96, 0x59a0, 0x4789, 0xb1, 0x76, 0xed, 0xf3, 0xdc, 0x8f, 0xa8, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFaxOutgoingJob.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbHasCoverPage) get_HasCoverPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrReceiptAddress) get_ReceiptAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_SCHEDULE_TYPE_ENUM* pScheduleType) get_ScheduleType;
	}


	public HRESULT get_HasCoverPage(int16* pbHasCoverPage) mut => VT.[Friend]get_HasCoverPage(&this, pbHasCoverPage);

	public HRESULT get_ReceiptAddress(BSTR* pbstrReceiptAddress) mut => VT.[Friend]get_ReceiptAddress(&this, pbstrReceiptAddress);

	public HRESULT get_ScheduleType(FAX_SCHEDULE_TYPE_ENUM* pScheduleType) mut => VT.[Friend]get_ScheduleType(&this, pScheduleType);
}

[CRepr]struct IFaxAccountFolders : IDispatch
{
	public new const Guid IID = .(0x6463f89d, 0x23d8, 0x46a9, 0x8f, 0x86, 0xc4, 0x7b, 0x77, 0xca, 0x79, 0x26);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccountOutgoingQueue** pFaxOutgoingQueue) get_OutgoingQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccountIncomingQueue** pFaxIncomingQueue) get_IncomingQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccountIncomingArchive** pFaxIncomingArchive) get_IncomingArchive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccountOutgoingArchive** pFaxOutgoingArchive) get_OutgoingArchive;
	}


	public HRESULT get_OutgoingQueue(IFaxAccountOutgoingQueue** pFaxOutgoingQueue) mut => VT.[Friend]get_OutgoingQueue(&this, pFaxOutgoingQueue);

	public HRESULT get_IncomingQueue(IFaxAccountIncomingQueue** pFaxIncomingQueue) mut => VT.[Friend]get_IncomingQueue(&this, pFaxIncomingQueue);

	public HRESULT get_IncomingArchive(IFaxAccountIncomingArchive** pFaxIncomingArchive) mut => VT.[Friend]get_IncomingArchive(&this, pFaxIncomingArchive);

	public HRESULT get_OutgoingArchive(IFaxAccountOutgoingArchive** pFaxOutgoingArchive) mut => VT.[Friend]get_OutgoingArchive(&this, pFaxOutgoingArchive);
}

[CRepr]struct IFaxAccountIncomingQueue : IDispatch
{
	public new const Guid IID = .(0xdd142d92, 0x0186, 0x4a95, 0xa0, 0x90, 0xcb, 0xc3, 0xea, 0xdb, 0xa6, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxIncomingJobs** pFaxIncomingJobs) GetJobs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrJobId, IFaxIncomingJob** pFaxIncomingJob) GetJob;
	}


	public HRESULT GetJobs(IFaxIncomingJobs** pFaxIncomingJobs) mut => VT.[Friend]GetJobs(&this, pFaxIncomingJobs);

	public HRESULT GetJob(BSTR bstrJobId, IFaxIncomingJob** pFaxIncomingJob) mut => VT.[Friend]GetJob(&this, bstrJobId, pFaxIncomingJob);
}

[CRepr]struct IFaxAccountOutgoingQueue : IDispatch
{
	public new const Guid IID = .(0x0f1424e9, 0xf22d, 0x4553, 0xb7, 0xa5, 0x0d, 0x24, 0xbd, 0x0d, 0x7e, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxOutgoingJobs** pFaxOutgoingJobs) GetJobs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrJobId, IFaxOutgoingJob** pFaxOutgoingJob) GetJob;
	}


	public HRESULT GetJobs(IFaxOutgoingJobs** pFaxOutgoingJobs) mut => VT.[Friend]GetJobs(&this, pFaxOutgoingJobs);

	public HRESULT GetJob(BSTR bstrJobId, IFaxOutgoingJob** pFaxOutgoingJob) mut => VT.[Friend]GetJob(&this, bstrJobId, pFaxOutgoingJob);
}

[CRepr]struct IFaxOutgoingMessage2 : IFaxOutgoingMessage
{
	public new const Guid IID = .(0xb37df687, 0xbc88, 0x4b46, 0xb3, 0xbe, 0xb4, 0x58, 0xb3, 0xea, 0x9e, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFaxOutgoingMessage.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbHasCoverPage) get_HasCoverPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_RECEIPT_TYPE_ENUM* pReceiptType) get_ReceiptType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrReceiptAddress) get_ReceiptAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbRead) get_Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bRead) put_Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
	}


	public HRESULT get_HasCoverPage(int16* pbHasCoverPage) mut => VT.[Friend]get_HasCoverPage(&this, pbHasCoverPage);

	public HRESULT get_ReceiptType(FAX_RECEIPT_TYPE_ENUM* pReceiptType) mut => VT.[Friend]get_ReceiptType(&this, pReceiptType);

	public HRESULT get_ReceiptAddress(BSTR* pbstrReceiptAddress) mut => VT.[Friend]get_ReceiptAddress(&this, pbstrReceiptAddress);

	public HRESULT get_Read(int16* pbRead) mut => VT.[Friend]get_Read(&this, pbRead);

	public HRESULT put_Read(int16 bRead) mut => VT.[Friend]put_Read(&this, bRead);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);
}

[CRepr]struct IFaxAccountIncomingArchive : IDispatch
{
	public new const Guid IID = .(0xa8a5b6ef, 0xe0d6, 0x4aee, 0x95, 0x5c, 0x91, 0x62, 0x5b, 0xec, 0x9d, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSizeLow) get_SizeLow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSizeHigh) get_SizeHigh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrefetchSize, IFaxIncomingMessageIterator** pFaxIncomingMessageIterator) GetMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMessageId, IFaxIncomingMessage** pFaxIncomingMessage) GetMessage;
	}


	public HRESULT get_SizeLow(int32* plSizeLow) mut => VT.[Friend]get_SizeLow(&this, plSizeLow);

	public HRESULT get_SizeHigh(int32* plSizeHigh) mut => VT.[Friend]get_SizeHigh(&this, plSizeHigh);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT GetMessages(int32 lPrefetchSize, IFaxIncomingMessageIterator** pFaxIncomingMessageIterator) mut => VT.[Friend]GetMessages(&this, lPrefetchSize, pFaxIncomingMessageIterator);

	public HRESULT GetMessage(BSTR bstrMessageId, IFaxIncomingMessage** pFaxIncomingMessage) mut => VT.[Friend]GetMessage(&this, bstrMessageId, pFaxIncomingMessage);
}

[CRepr]struct IFaxAccountOutgoingArchive : IDispatch
{
	public new const Guid IID = .(0x5463076d, 0xec14, 0x491f, 0x92, 0x6e, 0xb3, 0xce, 0xda, 0x5e, 0x56, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSizeLow) get_SizeLow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSizeHigh) get_SizeHigh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrefetchSize, IFaxOutgoingMessageIterator** pFaxOutgoingMessageIterator) GetMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMessageId, IFaxOutgoingMessage** pFaxOutgoingMessage) GetMessage;
	}


	public HRESULT get_SizeLow(int32* plSizeLow) mut => VT.[Friend]get_SizeLow(&this, plSizeLow);

	public HRESULT get_SizeHigh(int32* plSizeHigh) mut => VT.[Friend]get_SizeHigh(&this, plSizeHigh);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT GetMessages(int32 lPrefetchSize, IFaxOutgoingMessageIterator** pFaxOutgoingMessageIterator) mut => VT.[Friend]GetMessages(&this, lPrefetchSize, pFaxOutgoingMessageIterator);

	public HRESULT GetMessage(BSTR bstrMessageId, IFaxOutgoingMessage** pFaxOutgoingMessage) mut => VT.[Friend]GetMessage(&this, bstrMessageId, pFaxOutgoingMessage);
}

[CRepr]struct IFaxSecurity2 : IDispatch
{
	public new const Guid IID = .(0x17d851f4, 0xd09b, 0x48fc, 0x99, 0xc9, 0x8f, 0x24, 0xc4, 0xdb, 0x9a, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvDescriptor) get_Descriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vDescriptor) put_Descriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FAX_ACCESS_RIGHTS_ENUM_2* pGrantedRights) get_GrantedRights;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plInformationType) get_InformationType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lInformationType) put_InformationType;
	}


	public HRESULT get_Descriptor(VARIANT* pvDescriptor) mut => VT.[Friend]get_Descriptor(&this, pvDescriptor);

	public HRESULT put_Descriptor(VARIANT vDescriptor) mut => VT.[Friend]put_Descriptor(&this, vDescriptor);

	public HRESULT get_GrantedRights(FAX_ACCESS_RIGHTS_ENUM_2* pGrantedRights) mut => VT.[Friend]get_GrantedRights(&this, pGrantedRights);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT get_InformationType(int32* plInformationType) mut => VT.[Friend]get_InformationType(&this, plInformationType);

	public HRESULT put_InformationType(int32 lInformationType) mut => VT.[Friend]put_InformationType(&this, lInformationType);
}

[CRepr]struct IFaxIncomingMessage2 : IFaxIncomingMessage
{
	public new const Guid IID = .(0xf9208503, 0xe2bc, 0x48f3, 0x9e, 0xc0, 0xe6, 0x23, 0x6f, 0x9b, 0x50, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFaxIncomingMessage.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubject) get_Subject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSubject) put_Subject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSenderName) get_SenderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSenderName) put_SenderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSenderFaxNumber) get_SenderFaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSenderFaxNumber) put_SenderFaxNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbHasCoverPage) get_HasCoverPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bHasCoverPage) put_HasCoverPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrRecipients) get_Recipients;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRecipients) put_Recipients;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbWasReAssigned) get_WasReAssigned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbRead) get_Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bRead) put_Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReAssign;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
	}


	public HRESULT get_Subject(BSTR* pbstrSubject) mut => VT.[Friend]get_Subject(&this, pbstrSubject);

	public HRESULT put_Subject(BSTR bstrSubject) mut => VT.[Friend]put_Subject(&this, bstrSubject);

	public HRESULT get_SenderName(BSTR* pbstrSenderName) mut => VT.[Friend]get_SenderName(&this, pbstrSenderName);

	public HRESULT put_SenderName(BSTR bstrSenderName) mut => VT.[Friend]put_SenderName(&this, bstrSenderName);

	public HRESULT get_SenderFaxNumber(BSTR* pbstrSenderFaxNumber) mut => VT.[Friend]get_SenderFaxNumber(&this, pbstrSenderFaxNumber);

	public HRESULT put_SenderFaxNumber(BSTR bstrSenderFaxNumber) mut => VT.[Friend]put_SenderFaxNumber(&this, bstrSenderFaxNumber);

	public HRESULT get_HasCoverPage(int16* pbHasCoverPage) mut => VT.[Friend]get_HasCoverPage(&this, pbHasCoverPage);

	public HRESULT put_HasCoverPage(int16 bHasCoverPage) mut => VT.[Friend]put_HasCoverPage(&this, bHasCoverPage);

	public HRESULT get_Recipients(BSTR* pbstrRecipients) mut => VT.[Friend]get_Recipients(&this, pbstrRecipients);

	public HRESULT put_Recipients(BSTR bstrRecipients) mut => VT.[Friend]put_Recipients(&this, bstrRecipients);

	public HRESULT get_WasReAssigned(int16* pbWasReAssigned) mut => VT.[Friend]get_WasReAssigned(&this, pbWasReAssigned);

	public HRESULT get_Read(int16* pbRead) mut => VT.[Friend]get_Read(&this, pbRead);

	public HRESULT put_Read(int16 bRead) mut => VT.[Friend]put_Read(&this, bRead);

	public HRESULT ReAssign() mut => VT.[Friend]ReAssign(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);
}

[CRepr]struct IFaxServerNotify : IDispatch
{
	public new const Guid IID = .(0x2e037b27, 0xcf8a, 0x4abd, 0xb1, 0xe0, 0x57, 0x04, 0x94, 0x3b, 0xea, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct _IFaxServerNotify2 : IDispatch
{
	public new const Guid IID = .(0xec9c69b9, 0x5fe7, 0x4805, 0x94, 0x67, 0x82, 0xfc, 0xd9, 0x6a, 0xf9, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, BSTR bstrJobId) OnIncomingJobAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, BSTR bstrJobId) OnIncomingJobRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, BSTR bstrJobId, IFaxJobStatus* pJobStatus) OnIncomingJobChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, BSTR bstrJobId) OnOutgoingJobAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, BSTR bstrJobId) OnOutgoingJobRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, BSTR bstrJobId, IFaxJobStatus* pJobStatus) OnOutgoingJobChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, BSTR bstrMessageId) OnIncomingMessageAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, BSTR bstrMessageId) OnIncomingMessageRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, BSTR bstrMessageId) OnOutgoingMessageAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, BSTR bstrMessageId) OnOutgoingMessageRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnReceiptOptionsChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnActivityLoggingConfigChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnSecurityConfigChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnEventLoggingConfigChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnOutgoingQueueConfigChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnOutgoingArchiveConfigChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnIncomingArchiveConfigChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnDevicesConfigChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnOutboundRoutingGroupsConfigChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnOutboundRoutingRulesConfigChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, int32 lIncomingMessages, int32 lRoutingMessages, int32 lOutgoingMessages, int32 lQueuedMessages) OnServerActivityChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, int16 bOutgoingQueueBlocked, int16 bOutgoingQueuePaused, int16 bIncomingQueueBlocked) OnQueuesStatusChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, int32 lCallId, int32 lDeviceId, BSTR bstrCallerId) OnNewCall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnServerShutDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer, int32 lDeviceId, int16 bPoweredOff, int16 bSending, int16 bReceiving, int16 bRinging) OnDeviceStatusChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnGeneralServerConfigChanged;
	}


	public HRESULT OnIncomingJobAdded(IFaxServer2* pFaxServer, BSTR bstrJobId) mut => VT.[Friend]OnIncomingJobAdded(&this, pFaxServer, bstrJobId);

	public HRESULT OnIncomingJobRemoved(IFaxServer2* pFaxServer, BSTR bstrJobId) mut => VT.[Friend]OnIncomingJobRemoved(&this, pFaxServer, bstrJobId);

	public HRESULT OnIncomingJobChanged(IFaxServer2* pFaxServer, BSTR bstrJobId, IFaxJobStatus* pJobStatus) mut => VT.[Friend]OnIncomingJobChanged(&this, pFaxServer, bstrJobId, pJobStatus);

	public HRESULT OnOutgoingJobAdded(IFaxServer2* pFaxServer, BSTR bstrJobId) mut => VT.[Friend]OnOutgoingJobAdded(&this, pFaxServer, bstrJobId);

	public HRESULT OnOutgoingJobRemoved(IFaxServer2* pFaxServer, BSTR bstrJobId) mut => VT.[Friend]OnOutgoingJobRemoved(&this, pFaxServer, bstrJobId);

	public HRESULT OnOutgoingJobChanged(IFaxServer2* pFaxServer, BSTR bstrJobId, IFaxJobStatus* pJobStatus) mut => VT.[Friend]OnOutgoingJobChanged(&this, pFaxServer, bstrJobId, pJobStatus);

	public HRESULT OnIncomingMessageAdded(IFaxServer2* pFaxServer, BSTR bstrMessageId) mut => VT.[Friend]OnIncomingMessageAdded(&this, pFaxServer, bstrMessageId);

	public HRESULT OnIncomingMessageRemoved(IFaxServer2* pFaxServer, BSTR bstrMessageId) mut => VT.[Friend]OnIncomingMessageRemoved(&this, pFaxServer, bstrMessageId);

	public HRESULT OnOutgoingMessageAdded(IFaxServer2* pFaxServer, BSTR bstrMessageId) mut => VT.[Friend]OnOutgoingMessageAdded(&this, pFaxServer, bstrMessageId);

	public HRESULT OnOutgoingMessageRemoved(IFaxServer2* pFaxServer, BSTR bstrMessageId) mut => VT.[Friend]OnOutgoingMessageRemoved(&this, pFaxServer, bstrMessageId);

	public HRESULT OnReceiptOptionsChange(IFaxServer2* pFaxServer) mut => VT.[Friend]OnReceiptOptionsChange(&this, pFaxServer);

	public HRESULT OnActivityLoggingConfigChange(IFaxServer2* pFaxServer) mut => VT.[Friend]OnActivityLoggingConfigChange(&this, pFaxServer);

	public HRESULT OnSecurityConfigChange(IFaxServer2* pFaxServer) mut => VT.[Friend]OnSecurityConfigChange(&this, pFaxServer);

	public HRESULT OnEventLoggingConfigChange(IFaxServer2* pFaxServer) mut => VT.[Friend]OnEventLoggingConfigChange(&this, pFaxServer);

	public HRESULT OnOutgoingQueueConfigChange(IFaxServer2* pFaxServer) mut => VT.[Friend]OnOutgoingQueueConfigChange(&this, pFaxServer);

	public HRESULT OnOutgoingArchiveConfigChange(IFaxServer2* pFaxServer) mut => VT.[Friend]OnOutgoingArchiveConfigChange(&this, pFaxServer);

	public HRESULT OnIncomingArchiveConfigChange(IFaxServer2* pFaxServer) mut => VT.[Friend]OnIncomingArchiveConfigChange(&this, pFaxServer);

	public HRESULT OnDevicesConfigChange(IFaxServer2* pFaxServer) mut => VT.[Friend]OnDevicesConfigChange(&this, pFaxServer);

	public HRESULT OnOutboundRoutingGroupsConfigChange(IFaxServer2* pFaxServer) mut => VT.[Friend]OnOutboundRoutingGroupsConfigChange(&this, pFaxServer);

	public HRESULT OnOutboundRoutingRulesConfigChange(IFaxServer2* pFaxServer) mut => VT.[Friend]OnOutboundRoutingRulesConfigChange(&this, pFaxServer);

	public HRESULT OnServerActivityChange(IFaxServer2* pFaxServer, int32 lIncomingMessages, int32 lRoutingMessages, int32 lOutgoingMessages, int32 lQueuedMessages) mut => VT.[Friend]OnServerActivityChange(&this, pFaxServer, lIncomingMessages, lRoutingMessages, lOutgoingMessages, lQueuedMessages);

	public HRESULT OnQueuesStatusChange(IFaxServer2* pFaxServer, int16 bOutgoingQueueBlocked, int16 bOutgoingQueuePaused, int16 bIncomingQueueBlocked) mut => VT.[Friend]OnQueuesStatusChange(&this, pFaxServer, bOutgoingQueueBlocked, bOutgoingQueuePaused, bIncomingQueueBlocked);

	public HRESULT OnNewCall(IFaxServer2* pFaxServer, int32 lCallId, int32 lDeviceId, BSTR bstrCallerId) mut => VT.[Friend]OnNewCall(&this, pFaxServer, lCallId, lDeviceId, bstrCallerId);

	public HRESULT OnServerShutDown(IFaxServer2* pFaxServer) mut => VT.[Friend]OnServerShutDown(&this, pFaxServer);

	public HRESULT OnDeviceStatusChange(IFaxServer2* pFaxServer, int32 lDeviceId, int16 bPoweredOff, int16 bSending, int16 bReceiving, int16 bRinging) mut => VT.[Friend]OnDeviceStatusChange(&this, pFaxServer, lDeviceId, bPoweredOff, bSending, bReceiving, bRinging);

	public HRESULT OnGeneralServerConfigChanged(IFaxServer2* pFaxServer) mut => VT.[Friend]OnGeneralServerConfigChanged(&this, pFaxServer);
}

[CRepr]struct IFaxServerNotify2 : IDispatch
{
	public new const Guid IID = .(0x616ca8d6, 0xa77a, 0x4062, 0xab, 0xfd, 0x0e, 0x47, 0x12, 0x41, 0xc7, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct _IFaxAccountNotify : IDispatch
{
	public new const Guid IID = .(0xb9b3bc81, 0xac1b, 0x46f3, 0xb3, 0x9d, 0x0a, 0xdc, 0x30, 0xe1, 0xb7, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount* pFaxAccount, BSTR bstrJobId) OnIncomingJobAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount* pFaxAccount, BSTR bstrJobId) OnIncomingJobRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount* pFaxAccount, BSTR bstrJobId, IFaxJobStatus* pJobStatus) OnIncomingJobChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount* pFaxAccount, BSTR bstrJobId) OnOutgoingJobAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount* pFaxAccount, BSTR bstrJobId) OnOutgoingJobRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount* pFaxAccount, BSTR bstrJobId, IFaxJobStatus* pJobStatus) OnOutgoingJobChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount* pFaxAccount, BSTR bstrMessageId, int16 fAddedToReceiveFolder) OnIncomingMessageAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount* pFaxAccount, BSTR bstrMessageId, int16 fRemovedFromReceiveFolder) OnIncomingMessageRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount* pFaxAccount, BSTR bstrMessageId) OnOutgoingMessageAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxAccount* pFaxAccount, BSTR bstrMessageId) OnOutgoingMessageRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFaxServer2* pFaxServer) OnServerShutDown;
	}


	public HRESULT OnIncomingJobAdded(IFaxAccount* pFaxAccount, BSTR bstrJobId) mut => VT.[Friend]OnIncomingJobAdded(&this, pFaxAccount, bstrJobId);

	public HRESULT OnIncomingJobRemoved(IFaxAccount* pFaxAccount, BSTR bstrJobId) mut => VT.[Friend]OnIncomingJobRemoved(&this, pFaxAccount, bstrJobId);

	public HRESULT OnIncomingJobChanged(IFaxAccount* pFaxAccount, BSTR bstrJobId, IFaxJobStatus* pJobStatus) mut => VT.[Friend]OnIncomingJobChanged(&this, pFaxAccount, bstrJobId, pJobStatus);

	public HRESULT OnOutgoingJobAdded(IFaxAccount* pFaxAccount, BSTR bstrJobId) mut => VT.[Friend]OnOutgoingJobAdded(&this, pFaxAccount, bstrJobId);

	public HRESULT OnOutgoingJobRemoved(IFaxAccount* pFaxAccount, BSTR bstrJobId) mut => VT.[Friend]OnOutgoingJobRemoved(&this, pFaxAccount, bstrJobId);

	public HRESULT OnOutgoingJobChanged(IFaxAccount* pFaxAccount, BSTR bstrJobId, IFaxJobStatus* pJobStatus) mut => VT.[Friend]OnOutgoingJobChanged(&this, pFaxAccount, bstrJobId, pJobStatus);

	public HRESULT OnIncomingMessageAdded(IFaxAccount* pFaxAccount, BSTR bstrMessageId, int16 fAddedToReceiveFolder) mut => VT.[Friend]OnIncomingMessageAdded(&this, pFaxAccount, bstrMessageId, fAddedToReceiveFolder);

	public HRESULT OnIncomingMessageRemoved(IFaxAccount* pFaxAccount, BSTR bstrMessageId, int16 fRemovedFromReceiveFolder) mut => VT.[Friend]OnIncomingMessageRemoved(&this, pFaxAccount, bstrMessageId, fRemovedFromReceiveFolder);

	public HRESULT OnOutgoingMessageAdded(IFaxAccount* pFaxAccount, BSTR bstrMessageId) mut => VT.[Friend]OnOutgoingMessageAdded(&this, pFaxAccount, bstrMessageId);

	public HRESULT OnOutgoingMessageRemoved(IFaxAccount* pFaxAccount, BSTR bstrMessageId) mut => VT.[Friend]OnOutgoingMessageRemoved(&this, pFaxAccount, bstrMessageId);

	public HRESULT OnServerShutDown(IFaxServer2* pFaxServer) mut => VT.[Friend]OnServerShutDown(&this, pFaxServer);
}

[CRepr]struct IFaxAccountNotify : IDispatch
{
	public new const Guid IID = .(0x0b5e5bd1, 0xb8a9, 0x47a0, 0xa3, 0x23, 0xef, 0x4a, 0x29, 0x3b, 0xa0, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IStillImageW : IUnknown
{
	public new const Guid IID = .(0x641bd880, 0x2dc8, 0x11d0, 0x90, 0xea, 0x00, 0xaa, 0x00, 0x60, 0xf8, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE hinst, uint32 dwVersion) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwType, uint32 dwFlags, uint32* pdwItemsReturned, void** ppBuffer) GetDeviceList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszDeviceName, void** ppBuffer) GetDeviceInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszDeviceName, uint32 dwMode, IStiDevice** pDevice, IUnknown* punkOuter) CreateDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszDeviceName, PWSTR pValueName, uint32* pType, uint8* pData, uint32* cbData) GetDeviceValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszDeviceName, PWSTR pValueName, uint32 Type, uint8* pData, uint32 cbData) SetDeviceValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszDeviceName, uint32* pdwEventCode, char16* pwszEventName) GetSTILaunchInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszAppName, PWSTR pwszCommandLine) RegisterLaunchApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszAppName) UnregisterLaunchApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszDeviceName, BOOL bNewState) EnableHwNotifications;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszDeviceName, BOOL* pbCurrentState) GetHwNotificationState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszDeviceName) RefreshDeviceBus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszDeviceName, PWSTR pwszAppName, STINOTIFY* pStiNotify) LaunchApplicationForDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STI_DEVICE_INFORMATIONW* param0) SetupDeviceParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMessageType, PWSTR pszMessage) WriteToErrorLog;
	}


	public HRESULT Initialize(HINSTANCE hinst, uint32 dwVersion) mut => VT.[Friend]Initialize(&this, hinst, dwVersion);

	public HRESULT GetDeviceList(uint32 dwType, uint32 dwFlags, uint32* pdwItemsReturned, void** ppBuffer) mut => VT.[Friend]GetDeviceList(&this, dwType, dwFlags, pdwItemsReturned, ppBuffer);

	public HRESULT GetDeviceInfo(PWSTR pwszDeviceName, void** ppBuffer) mut => VT.[Friend]GetDeviceInfo(&this, pwszDeviceName, ppBuffer);

	public HRESULT CreateDevice(PWSTR pwszDeviceName, uint32 dwMode, IStiDevice** pDevice, IUnknown* punkOuter) mut => VT.[Friend]CreateDevice(&this, pwszDeviceName, dwMode, pDevice, punkOuter);

	public HRESULT GetDeviceValue(PWSTR pwszDeviceName, PWSTR pValueName, uint32* pType, uint8* pData, uint32* cbData) mut => VT.[Friend]GetDeviceValue(&this, pwszDeviceName, pValueName, pType, pData, cbData);

	public HRESULT SetDeviceValue(PWSTR pwszDeviceName, PWSTR pValueName, uint32 Type, uint8* pData, uint32 cbData) mut => VT.[Friend]SetDeviceValue(&this, pwszDeviceName, pValueName, Type, pData, cbData);

	public HRESULT GetSTILaunchInformation(char16* pwszDeviceName, uint32* pdwEventCode, char16* pwszEventName) mut => VT.[Friend]GetSTILaunchInformation(&this, pwszDeviceName, pdwEventCode, pwszEventName);

	public HRESULT RegisterLaunchApplication(PWSTR pwszAppName, PWSTR pwszCommandLine) mut => VT.[Friend]RegisterLaunchApplication(&this, pwszAppName, pwszCommandLine);

	public HRESULT UnregisterLaunchApplication(PWSTR pwszAppName) mut => VT.[Friend]UnregisterLaunchApplication(&this, pwszAppName);

	public HRESULT EnableHwNotifications(PWSTR pwszDeviceName, BOOL bNewState) mut => VT.[Friend]EnableHwNotifications(&this, pwszDeviceName, bNewState);

	public HRESULT GetHwNotificationState(PWSTR pwszDeviceName, BOOL* pbCurrentState) mut => VT.[Friend]GetHwNotificationState(&this, pwszDeviceName, pbCurrentState);

	public HRESULT RefreshDeviceBus(PWSTR pwszDeviceName) mut => VT.[Friend]RefreshDeviceBus(&this, pwszDeviceName);

	public HRESULT LaunchApplicationForDevice(PWSTR pwszDeviceName, PWSTR pwszAppName, STINOTIFY* pStiNotify) mut => VT.[Friend]LaunchApplicationForDevice(&this, pwszDeviceName, pwszAppName, pStiNotify);

	public HRESULT SetupDeviceParameters(STI_DEVICE_INFORMATIONW* param0) mut => VT.[Friend]SetupDeviceParameters(&this, param0);

	public HRESULT WriteToErrorLog(uint32 dwMessageType, PWSTR pszMessage) mut => VT.[Friend]WriteToErrorLog(&this, dwMessageType, pszMessage);
}

[CRepr]struct IStiDevice : IUnknown
{
	public new const Guid IID = .(0x6cfa5a80, 0x2dc8, 0x11d0, 0x90, 0xea, 0x00, 0xaa, 0x00, 0x60, 0xf8, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE hinst, PWSTR pwszDeviceName, uint32 dwVersion, uint32 dwMode) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STI_DEV_CAPS* pDevCaps) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STI_DEVICE_STATUS* pDevStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeviceReset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STI_DIAG* pBuffer) Diagnostic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 EscapeFunction, void* lpInData, uint32 cbInDataSize, void* pOutData, uint32 dwOutDataSize, uint32* pdwActualData) Escape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLastDeviceError) GetLastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwTimeOut) LockDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnLockDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) RawReadData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) RawWriteData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) RawReadCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) RawWriteCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STISUBSCRIBE* lpSubsribe) Subscribe;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STINOTIFY* lpNotify) GetLastNotificationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnSubscribe;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, _ERROR_INFOW* pLastErrorInfo) GetLastErrorInfo;
	}


	public HRESULT Initialize(HINSTANCE hinst, PWSTR pwszDeviceName, uint32 dwVersion, uint32 dwMode) mut => VT.[Friend]Initialize(&this, hinst, pwszDeviceName, dwVersion, dwMode);

	public HRESULT GetCapabilities(STI_DEV_CAPS* pDevCaps) mut => VT.[Friend]GetCapabilities(&this, pDevCaps);

	public HRESULT GetStatus(STI_DEVICE_STATUS* pDevStatus) mut => VT.[Friend]GetStatus(&this, pDevStatus);

	public HRESULT DeviceReset() mut => VT.[Friend]DeviceReset(&this);

	public HRESULT Diagnostic(STI_DIAG* pBuffer) mut => VT.[Friend]Diagnostic(&this, pBuffer);

	public HRESULT Escape(uint32 EscapeFunction, void* lpInData, uint32 cbInDataSize, void* pOutData, uint32 dwOutDataSize, uint32* pdwActualData) mut => VT.[Friend]Escape(&this, EscapeFunction, lpInData, cbInDataSize, pOutData, dwOutDataSize, pdwActualData);

	public HRESULT GetLastError(uint32* pdwLastDeviceError) mut => VT.[Friend]GetLastError(&this, pdwLastDeviceError);

	public HRESULT LockDevice(uint32 dwTimeOut) mut => VT.[Friend]LockDevice(&this, dwTimeOut);

	public HRESULT UnLockDevice() mut => VT.[Friend]UnLockDevice(&this);

	public HRESULT RawReadData(void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawReadData(&this, lpBuffer, lpdwNumberOfBytes, lpOverlapped);

	public HRESULT RawWriteData(void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawWriteData(&this, lpBuffer, nNumberOfBytes, lpOverlapped);

	public HRESULT RawReadCommand(void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawReadCommand(&this, lpBuffer, lpdwNumberOfBytes, lpOverlapped);

	public HRESULT RawWriteCommand(void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawWriteCommand(&this, lpBuffer, nNumberOfBytes, lpOverlapped);

	public HRESULT Subscribe(STISUBSCRIBE* lpSubsribe) mut => VT.[Friend]Subscribe(&this, lpSubsribe);

	public HRESULT GetLastNotificationData(STINOTIFY* lpNotify) mut => VT.[Friend]GetLastNotificationData(&this, lpNotify);

	public HRESULT UnSubscribe() mut => VT.[Friend]UnSubscribe(&this);

	public HRESULT GetLastErrorInfo(_ERROR_INFOW* pLastErrorInfo) mut => VT.[Friend]GetLastErrorInfo(&this, pLastErrorInfo);
}

[CRepr]struct IStiDeviceControl : IUnknown
{
	public new const Guid IID = .(0x128a9860, 0x52dc, 0x11d0, 0x9e, 0xdf, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwDeviceType, uint32 dwMode, PWSTR pwszPortName, uint32 dwFlags) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) RawReadData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) RawWriteData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) RawReadCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) RawWriteCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 EscapeFunction, void* lpInData, uint32 cbInDataSize, void* pOutData, uint32 dwOutDataSize, uint32* pdwActualData) RawDeviceControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpdwLastError) GetLastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* lpszDevicePath, uint32 cwDevicePathSize) GetMyDevicePortName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* lph) GetMyDeviceHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwOpenMode) GetMyDeviceOpenMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMessageType, PWSTR pszMessage, uint32 dwErrorCode) WriteToErrorLog;
	}


	public HRESULT Initialize(uint32 dwDeviceType, uint32 dwMode, PWSTR pwszPortName, uint32 dwFlags) mut => VT.[Friend]Initialize(&this, dwDeviceType, dwMode, pwszPortName, dwFlags);

	public HRESULT RawReadData(void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawReadData(&this, lpBuffer, lpdwNumberOfBytes, lpOverlapped);

	public HRESULT RawWriteData(void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawWriteData(&this, lpBuffer, nNumberOfBytes, lpOverlapped);

	public HRESULT RawReadCommand(void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawReadCommand(&this, lpBuffer, lpdwNumberOfBytes, lpOverlapped);

	public HRESULT RawWriteCommand(void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawWriteCommand(&this, lpBuffer, nNumberOfBytes, lpOverlapped);

	public HRESULT RawDeviceControl(uint32 EscapeFunction, void* lpInData, uint32 cbInDataSize, void* pOutData, uint32 dwOutDataSize, uint32* pdwActualData) mut => VT.[Friend]RawDeviceControl(&this, EscapeFunction, lpInData, cbInDataSize, pOutData, dwOutDataSize, pdwActualData);

	public HRESULT GetLastError(uint32* lpdwLastError) mut => VT.[Friend]GetLastError(&this, lpdwLastError);

	public HRESULT GetMyDevicePortName(char16* lpszDevicePath, uint32 cwDevicePathSize) mut => VT.[Friend]GetMyDevicePortName(&this, lpszDevicePath, cwDevicePathSize);

	public HRESULT GetMyDeviceHandle(HANDLE* lph) mut => VT.[Friend]GetMyDeviceHandle(&this, lph);

	public HRESULT GetMyDeviceOpenMode(uint32* pdwOpenMode) mut => VT.[Friend]GetMyDeviceOpenMode(&this, pdwOpenMode);

	public HRESULT WriteToErrorLog(uint32 dwMessageType, PWSTR pszMessage, uint32 dwErrorCode) mut => VT.[Friend]WriteToErrorLog(&this, dwMessageType, pszMessage, dwErrorCode);
}

[CRepr]struct IStiUSD : IUnknown
{
	public new const Guid IID = .(0x0c9bb460, 0x51ac, 0x11d0, 0x90, 0xea, 0x00, 0xaa, 0x00, 0x60, 0xf8, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStiDeviceControl* pHelDcb, uint32 dwStiVersion, HKEY hParametersKey) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STI_USD_CAPS* pDevCaps) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STI_DEVICE_STATUS* pDevStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeviceReset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STI_DIAG* pBuffer) Diagnostic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 EscapeFunction, void* lpInData, uint32 cbInDataSize, void* pOutData, uint32 cbOutDataSize, uint32* pdwActualData) Escape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLastDeviceError) GetLastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) LockDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnLockDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) RawReadData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) RawWriteData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) RawReadCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) RawWriteCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE hEvent) SetNotificationHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STINOTIFY* lpNotify) GetNotificationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, _ERROR_INFOW* pLastErrorInfo) GetLastErrorInfo;
	}


	public HRESULT Initialize(IStiDeviceControl* pHelDcb, uint32 dwStiVersion, HKEY hParametersKey) mut => VT.[Friend]Initialize(&this, pHelDcb, dwStiVersion, hParametersKey);

	public HRESULT GetCapabilities(STI_USD_CAPS* pDevCaps) mut => VT.[Friend]GetCapabilities(&this, pDevCaps);

	public HRESULT GetStatus(STI_DEVICE_STATUS* pDevStatus) mut => VT.[Friend]GetStatus(&this, pDevStatus);

	public HRESULT DeviceReset() mut => VT.[Friend]DeviceReset(&this);

	public HRESULT Diagnostic(STI_DIAG* pBuffer) mut => VT.[Friend]Diagnostic(&this, pBuffer);

	public HRESULT Escape(uint32 EscapeFunction, void* lpInData, uint32 cbInDataSize, void* pOutData, uint32 cbOutDataSize, uint32* pdwActualData) mut => VT.[Friend]Escape(&this, EscapeFunction, lpInData, cbInDataSize, pOutData, cbOutDataSize, pdwActualData);

	public HRESULT GetLastError(uint32* pdwLastDeviceError) mut => VT.[Friend]GetLastError(&this, pdwLastDeviceError);

	public HRESULT LockDevice() mut => VT.[Friend]LockDevice(&this);

	public HRESULT UnLockDevice() mut => VT.[Friend]UnLockDevice(&this);

	public HRESULT RawReadData(void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawReadData(&this, lpBuffer, lpdwNumberOfBytes, lpOverlapped);

	public HRESULT RawWriteData(void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawWriteData(&this, lpBuffer, nNumberOfBytes, lpOverlapped);

	public HRESULT RawReadCommand(void* lpBuffer, uint32* lpdwNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawReadCommand(&this, lpBuffer, lpdwNumberOfBytes, lpOverlapped);

	public HRESULT RawWriteCommand(void* lpBuffer, uint32 nNumberOfBytes, OVERLAPPED* lpOverlapped) mut => VT.[Friend]RawWriteCommand(&this, lpBuffer, nNumberOfBytes, lpOverlapped);

	public HRESULT SetNotificationHandle(HANDLE hEvent) mut => VT.[Friend]SetNotificationHandle(&this, hEvent);

	public HRESULT GetNotificationData(STINOTIFY* lpNotify) mut => VT.[Friend]GetNotificationData(&this, lpNotify);

	public HRESULT GetLastErrorInfo(_ERROR_INFOW* pLastErrorInfo) mut => VT.[Friend]GetLastErrorInfo(&this, pLastErrorInfo);
}

#endregion

#region Functions
public static
{
	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxConnectFaxServerA(PSTR MachineName, HANDLE* FaxHandle);
	public static BOOL FaxConnectFaxServer(PSTR MachineName, HANDLE* FaxHandle) => FaxConnectFaxServerA(MachineName, FaxHandle);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxConnectFaxServerW(PWSTR MachineName, HANDLE* FaxHandle);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxClose(HANDLE FaxHandle);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxOpenPort(HANDLE FaxHandle, uint32 DeviceId, uint32 Flags, HANDLE* FaxPortHandle);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxCompleteJobParamsA(FAX_JOB_PARAMA** JobParams, FAX_COVERPAGE_INFOA** CoverpageInfo);
	public static BOOL FaxCompleteJobParams(FAX_JOB_PARAMA** JobParams, FAX_COVERPAGE_INFOA** CoverpageInfo) => FaxCompleteJobParamsA(JobParams, CoverpageInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxCompleteJobParamsW(FAX_JOB_PARAMW** JobParams, FAX_COVERPAGE_INFOW** CoverpageInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSendDocumentA(HANDLE FaxHandle, PSTR FileName, FAX_JOB_PARAMA* JobParams, FAX_COVERPAGE_INFOA* CoverpageInfo, uint32* FaxJobId);
	public static BOOL FaxSendDocument(HANDLE FaxHandle, PSTR FileName, FAX_JOB_PARAMA* JobParams, FAX_COVERPAGE_INFOA* CoverpageInfo, uint32* FaxJobId) => FaxSendDocumentA(FaxHandle, FileName, JobParams, CoverpageInfo, FaxJobId);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSendDocumentW(HANDLE FaxHandle, PWSTR FileName, FAX_JOB_PARAMW* JobParams, FAX_COVERPAGE_INFOW* CoverpageInfo, uint32* FaxJobId);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSendDocumentForBroadcastA(HANDLE FaxHandle, PSTR FileName, uint32* FaxJobId, PFAX_RECIPIENT_CALLBACKA FaxRecipientCallback, void* Context);
	public static BOOL FaxSendDocumentForBroadcast(HANDLE FaxHandle, PSTR FileName, uint32* FaxJobId, PFAX_RECIPIENT_CALLBACKA FaxRecipientCallback, void* Context) => FaxSendDocumentForBroadcastA(FaxHandle, FileName, FaxJobId, FaxRecipientCallback, Context);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSendDocumentForBroadcastW(HANDLE FaxHandle, PWSTR FileName, uint32* FaxJobId, PFAX_RECIPIENT_CALLBACKW FaxRecipientCallback, void* Context);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxEnumJobsA(HANDLE FaxHandle, FAX_JOB_ENTRYA** JobEntry, uint32* JobsReturned);
	public static BOOL FaxEnumJobs(HANDLE FaxHandle, FAX_JOB_ENTRYA** JobEntry, uint32* JobsReturned) => FaxEnumJobsA(FaxHandle, JobEntry, JobsReturned);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxEnumJobsW(HANDLE FaxHandle, FAX_JOB_ENTRYW** JobEntry, uint32* JobsReturned);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetJobA(HANDLE FaxHandle, uint32 JobId, FAX_JOB_ENTRYA** JobEntry);
	public static BOOL FaxGetJob(HANDLE FaxHandle, uint32 JobId, FAX_JOB_ENTRYA** JobEntry) => FaxGetJobA(FaxHandle, JobId, JobEntry);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetJobW(HANDLE FaxHandle, uint32 JobId, FAX_JOB_ENTRYW** JobEntry);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetJobA(HANDLE FaxHandle, uint32 JobId, uint32 Command, FAX_JOB_ENTRYA* JobEntry);
	public static BOOL FaxSetJob(HANDLE FaxHandle, uint32 JobId, uint32 Command, FAX_JOB_ENTRYA* JobEntry) => FaxSetJobA(FaxHandle, JobId, Command, JobEntry);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetJobW(HANDLE FaxHandle, uint32 JobId, uint32 Command, FAX_JOB_ENTRYW* JobEntry);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetPageData(HANDLE FaxHandle, uint32 JobId, uint8** Buffer, uint32* BufferSize, uint32* ImageWidth, uint32* ImageHeight);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetDeviceStatusA(HANDLE FaxPortHandle, FAX_DEVICE_STATUSA** DeviceStatus);
	public static BOOL FaxGetDeviceStatus(HANDLE FaxPortHandle, FAX_DEVICE_STATUSA** DeviceStatus) => FaxGetDeviceStatusA(FaxPortHandle, DeviceStatus);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetDeviceStatusW(HANDLE FaxPortHandle, FAX_DEVICE_STATUSW** DeviceStatus);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxAbort(HANDLE FaxHandle, uint32 JobId);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetConfigurationA(HANDLE FaxHandle, FAX_CONFIGURATIONA** FaxConfig);
	public static BOOL FaxGetConfiguration(HANDLE FaxHandle, FAX_CONFIGURATIONA** FaxConfig) => FaxGetConfigurationA(FaxHandle, FaxConfig);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetConfigurationW(HANDLE FaxHandle, FAX_CONFIGURATIONW** FaxConfig);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetConfigurationA(HANDLE FaxHandle, FAX_CONFIGURATIONA* FaxConfig);
	public static BOOL FaxSetConfiguration(HANDLE FaxHandle, FAX_CONFIGURATIONA* FaxConfig) => FaxSetConfigurationA(FaxHandle, FaxConfig);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetConfigurationW(HANDLE FaxHandle, FAX_CONFIGURATIONW* FaxConfig);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetLoggingCategoriesA(HANDLE FaxHandle, FAX_LOG_CATEGORYA** Categories, uint32* NumberCategories);
	public static BOOL FaxGetLoggingCategories(HANDLE FaxHandle, FAX_LOG_CATEGORYA** Categories, uint32* NumberCategories) => FaxGetLoggingCategoriesA(FaxHandle, Categories, NumberCategories);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetLoggingCategoriesW(HANDLE FaxHandle, FAX_LOG_CATEGORYW** Categories, uint32* NumberCategories);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetLoggingCategoriesA(HANDLE FaxHandle, FAX_LOG_CATEGORYA* Categories, uint32 NumberCategories);
	public static BOOL FaxSetLoggingCategories(HANDLE FaxHandle, FAX_LOG_CATEGORYA* Categories, uint32 NumberCategories) => FaxSetLoggingCategoriesA(FaxHandle, Categories, NumberCategories);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetLoggingCategoriesW(HANDLE FaxHandle, FAX_LOG_CATEGORYW* Categories, uint32 NumberCategories);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxEnumPortsA(HANDLE FaxHandle, FAX_PORT_INFOA** PortInfo, uint32* PortsReturned);
	public static BOOL FaxEnumPorts(HANDLE FaxHandle, FAX_PORT_INFOA** PortInfo, uint32* PortsReturned) => FaxEnumPortsA(FaxHandle, PortInfo, PortsReturned);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxEnumPortsW(HANDLE FaxHandle, FAX_PORT_INFOW** PortInfo, uint32* PortsReturned);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetPortA(HANDLE FaxPortHandle, FAX_PORT_INFOA** PortInfo);
	public static BOOL FaxGetPort(HANDLE FaxPortHandle, FAX_PORT_INFOA** PortInfo) => FaxGetPortA(FaxPortHandle, PortInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetPortW(HANDLE FaxPortHandle, FAX_PORT_INFOW** PortInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetPortA(HANDLE FaxPortHandle, FAX_PORT_INFOA* PortInfo);
	public static BOOL FaxSetPort(HANDLE FaxPortHandle, FAX_PORT_INFOA* PortInfo) => FaxSetPortA(FaxPortHandle, PortInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetPortW(HANDLE FaxPortHandle, FAX_PORT_INFOW* PortInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxEnumRoutingMethodsA(HANDLE FaxPortHandle, FAX_ROUTING_METHODA** RoutingMethod, uint32* MethodsReturned);
	public static BOOL FaxEnumRoutingMethods(HANDLE FaxPortHandle, FAX_ROUTING_METHODA** RoutingMethod, uint32* MethodsReturned) => FaxEnumRoutingMethodsA(FaxPortHandle, RoutingMethod, MethodsReturned);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxEnumRoutingMethodsW(HANDLE FaxPortHandle, FAX_ROUTING_METHODW** RoutingMethod, uint32* MethodsReturned);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxEnableRoutingMethodA(HANDLE FaxPortHandle, PSTR RoutingGuid, BOOL Enabled);
	public static BOOL FaxEnableRoutingMethod(HANDLE FaxPortHandle, PSTR RoutingGuid, BOOL Enabled) => FaxEnableRoutingMethodA(FaxPortHandle, RoutingGuid, Enabled);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxEnableRoutingMethodW(HANDLE FaxPortHandle, PWSTR RoutingGuid, BOOL Enabled);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxEnumGlobalRoutingInfoA(HANDLE FaxHandle, FAX_GLOBAL_ROUTING_INFOA** RoutingInfo, uint32* MethodsReturned);
	public static BOOL FaxEnumGlobalRoutingInfo(HANDLE FaxHandle, FAX_GLOBAL_ROUTING_INFOA** RoutingInfo, uint32* MethodsReturned) => FaxEnumGlobalRoutingInfoA(FaxHandle, RoutingInfo, MethodsReturned);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxEnumGlobalRoutingInfoW(HANDLE FaxHandle, FAX_GLOBAL_ROUTING_INFOW** RoutingInfo, uint32* MethodsReturned);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetGlobalRoutingInfoA(HANDLE FaxHandle, FAX_GLOBAL_ROUTING_INFOA* RoutingInfo);
	public static BOOL FaxSetGlobalRoutingInfo(HANDLE FaxHandle, FAX_GLOBAL_ROUTING_INFOA* RoutingInfo) => FaxSetGlobalRoutingInfoA(FaxHandle, RoutingInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetGlobalRoutingInfoW(HANDLE FaxHandle, FAX_GLOBAL_ROUTING_INFOW* RoutingInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetRoutingInfoA(HANDLE FaxPortHandle, PSTR RoutingGuid, uint8** RoutingInfoBuffer, uint32* RoutingInfoBufferSize);
	public static BOOL FaxGetRoutingInfo(HANDLE FaxPortHandle, PSTR RoutingGuid, uint8** RoutingInfoBuffer, uint32* RoutingInfoBufferSize) => FaxGetRoutingInfoA(FaxPortHandle, RoutingGuid, RoutingInfoBuffer, RoutingInfoBufferSize);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxGetRoutingInfoW(HANDLE FaxPortHandle, PWSTR RoutingGuid, uint8** RoutingInfoBuffer, uint32* RoutingInfoBufferSize);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetRoutingInfoA(HANDLE FaxPortHandle, PSTR RoutingGuid, uint8* RoutingInfoBuffer, uint32 RoutingInfoBufferSize);
	public static BOOL FaxSetRoutingInfo(HANDLE FaxPortHandle, PSTR RoutingGuid, uint8* RoutingInfoBuffer, uint32 RoutingInfoBufferSize) => FaxSetRoutingInfoA(FaxPortHandle, RoutingGuid, RoutingInfoBuffer, RoutingInfoBufferSize);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxSetRoutingInfoW(HANDLE FaxPortHandle, PWSTR RoutingGuid, uint8* RoutingInfoBuffer, uint32 RoutingInfoBufferSize);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxInitializeEventQueue(HANDLE FaxHandle, HANDLE CompletionPort, uint CompletionKey, HWND hWnd, uint32 MessageStart);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FaxFreeBuffer(void* Buffer);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxStartPrintJobA(PSTR PrinterName, FAX_PRINT_INFOA* PrintInfo, uint32* FaxJobId, FAX_CONTEXT_INFOA* FaxContextInfo);
	public static BOOL FaxStartPrintJob(PSTR PrinterName, FAX_PRINT_INFOA* PrintInfo, uint32* FaxJobId, FAX_CONTEXT_INFOA* FaxContextInfo) => FaxStartPrintJobA(PrinterName, PrintInfo, FaxJobId, FaxContextInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxStartPrintJobW(PWSTR PrinterName, FAX_PRINT_INFOW* PrintInfo, uint32* FaxJobId, FAX_CONTEXT_INFOW* FaxContextInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxPrintCoverPageA(FAX_CONTEXT_INFOA* FaxContextInfo, FAX_COVERPAGE_INFOA* CoverPageInfo);
	public static BOOL FaxPrintCoverPage(FAX_CONTEXT_INFOA* FaxContextInfo, FAX_COVERPAGE_INFOA* CoverPageInfo) => FaxPrintCoverPageA(FaxContextInfo, CoverPageInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxPrintCoverPageW(FAX_CONTEXT_INFOW* FaxContextInfo, FAX_COVERPAGE_INFOW* CoverPageInfo);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxRegisterServiceProviderW(PWSTR DeviceProvider, PWSTR FriendlyName, PWSTR ImageName, PWSTR TspName);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxUnregisterServiceProviderW(PWSTR DeviceProvider);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxRegisterRoutingExtensionW(HANDLE FaxHandle, PWSTR ExtensionName, PWSTR FriendlyName, PWSTR ImageName, PFAX_ROUTING_INSTALLATION_CALLBACKW CallBack, void* Context);

	[Import("WINFAX.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FaxAccessCheck(HANDLE FaxHandle, uint32 AccessMask);

	[Import("fxsutility.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CanSendToFaxRecipient();

	[Import("fxsutility.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SendToFaxRecipient(SendToMode sndMode, PWSTR lpFileName);

	[Import("STI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StiCreateInstanceW(HINSTANCE hinst, uint32 dwVer, IStillImageW** ppSti, IUnknown* punkOuter);

}
#endregion
