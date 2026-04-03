using Win32.Foundation;
using Win32.System.Registry;
using Win32.System.Com;
using System;

namespace Win32.System.DeploymentServices;

#region Constants
public static
{
	public const uint32 WDS_CLI_TRANSFER_ASYNCHRONOUS = 1;
	public const uint32 WDS_CLI_NO_SPARSE_FILE = 2;
	public const uint32 PXE_DHCP_SERVER_PORT = 67;
	public const uint32 PXE_DHCP_CLIENT_PORT = 68;
	public const uint32 PXE_SERVER_PORT = 4011;
	public const uint32 PXE_DHCPV6_SERVER_PORT = 547;
	public const uint32 PXE_DHCPV6_CLIENT_PORT = 546;
	public const uint32 PXE_DHCP_FILE_SIZE = 128;
	public const uint32 PXE_DHCP_SERVER_SIZE = 64;
	public const uint32 PXE_DHCP_HWAADR_SIZE = 16;
	public const uint32 PXE_DHCP_MAGIC_COOKIE_SIZE = 4;
	public const uint32 PXE_REG_INDEX_TOP = 0;
	public const uint32 PXE_REG_INDEX_BOTTOM = 4294967295;
	public const uint32 PXE_CALLBACK_RECV_REQUEST = 0;
	public const uint32 PXE_CALLBACK_SHUTDOWN = 1;
	public const uint32 PXE_CALLBACK_SERVICE_CONTROL = 2;
	public const uint32 PXE_CALLBACK_MAX = 3;
	public const uint32 PXE_GSI_TRACE_ENABLED = 1;
	public const uint32 PXE_GSI_SERVER_DUID = 2;
	public const uint32 PXE_MAX_ADDRESS = 16;
	public const uint32 PXE_ADDR_BROADCAST = 1;
	public const uint32 PXE_ADDR_USE_PORT = 2;
	public const uint32 PXE_ADDR_USE_ADDR = 4;
	public const uint32 PXE_ADDR_USE_DHCP_RULES = 8;
	public const uint32 PXE_DHCPV6_RELAY_HOP_COUNT_LIMIT = 32;
	public const uint32 PXE_BA_NBP = 1;
	public const uint32 PXE_BA_CUSTOM = 2;
	public const uint32 PXE_BA_IGNORE = 3;
	public const uint32 PXE_BA_REJECTED = 4;
	public const uint32 PXE_TRACE_VERBOSE = 65536;
	public const uint32 PXE_TRACE_INFO = 131072;
	public const uint32 PXE_TRACE_WARNING = 262144;
	public const uint32 PXE_TRACE_ERROR = 524288;
	public const uint32 PXE_TRACE_FATAL = 1048576;
	public const uint32 PXE_PROV_ATTR_FILTER = 0;
	public const uint32 PXE_PROV_ATTR_FILTER_IPV6 = 1;
	public const uint32 PXE_PROV_ATTR_IPV6_CAPABLE = 2;
	public const uint32 PXE_PROV_FILTER_ALL = 0;
	public const uint32 PXE_PROV_FILTER_DHCP_ONLY = 1;
	public const uint32 PXE_PROV_FILTER_PXE_ONLY = 2;
	public const uint32 MC_SERVER_CURRENT_VERSION = 1;
	public const uint32 TRANSPORTPROVIDER_CURRENT_VERSION = 1;
	public const uint32 WDS_MC_TRACE_VERBOSE = 65536;
	public const uint32 WDS_MC_TRACE_INFO = 131072;
	public const uint32 WDS_MC_TRACE_WARNING = 262144;
	public const uint32 WDS_MC_TRACE_ERROR = 524288;
	public const uint32 WDS_MC_TRACE_FATAL = 1048576;
	public const uint32 WDS_TRANSPORTCLIENT_CURRENT_API_VERSION = 1;
	public const uint32 WDS_TRANSPORTCLIENT_PROTOCOL_MULTICAST = 1;
	public const uint32 WDS_TRANSPORTCLIENT_NO_CACHE = 0;
	public const uint32 WDS_TRANSPORTCLIENT_STATUS_IN_PROGRESS = 1;
	public const uint32 WDS_TRANSPORTCLIENT_STATUS_SUCCESS = 2;
	public const uint32 WDS_TRANSPORTCLIENT_STATUS_FAILURE = 3;
	public const uint32 WDSTRANSPORT_RESOURCE_UTILIZATION_UNKNOWN = 255;
	public const uint32 WDSBP_PK_TYPE_DHCP = 1;
	public const uint32 WDSBP_PK_TYPE_WDSNBP = 2;
	public const uint32 WDSBP_PK_TYPE_BCD = 4;
	public const uint32 WDSBP_PK_TYPE_DHCPV6 = 8;
	public const uint32 WDSBP_OPT_TYPE_NONE = 0;
	public const uint32 WDSBP_OPT_TYPE_BYTE = 1;
	public const uint32 WDSBP_OPT_TYPE_USHORT = 2;
	public const uint32 WDSBP_OPT_TYPE_ULONG = 3;
	public const uint32 WDSBP_OPT_TYPE_WSTR = 4;
	public const uint32 WDSBP_OPT_TYPE_STR = 5;
	public const uint32 WDSBP_OPT_TYPE_IP4 = 6;
	public const uint32 WDSBP_OPT_TYPE_IP6 = 7;
	public const uint32 WDSBP_OPTVAL_ACTION_APPROVAL = 1;
	public const uint32 WDSBP_OPTVAL_ACTION_REFERRAL = 3;
	public const uint32 WDSBP_OPTVAL_ACTION_ABORT = 5;
	public const uint32 WDSBP_OPTVAL_PXE_PROMPT_OPTIN = 1;
	public const uint32 WDSBP_OPTVAL_PXE_PROMPT_NOPROMPT = 2;
	public const uint32 WDSBP_OPTVAL_PXE_PROMPT_OPTOUT = 3;
	public const uint32 WDSBP_OPTVAL_NBP_VER_7 = 1792;
	public const uint32 WDSBP_OPTVAL_NBP_VER_8 = 2048;
	public const uint32 FACILITY_WDSMCSERVER = 289;
	public const uint32 FACILITY_WDSMCCLIENT = 290;
	public const HRESULT WDSMCSERVER_CATEGORY = 1;
	public const HRESULT WDSMCCLIENT_CATEGORY = 2;
	public const HRESULT WDSMCS_E_SESSION_SHUTDOWN_IN_PROGRESS = -1054801664;
	public const HRESULT WDSMCS_E_REQCALLBACKS_NOT_REG = -1054801663;
	public const HRESULT WDSMCS_E_INCOMPATIBLE_VERSION = -1054801662;
	public const HRESULT WDSMCS_E_CONTENT_NOT_FOUND = -1054801661;
	public const HRESULT WDSMCS_E_CLIENT_NOT_FOUND = -1054801660;
	public const HRESULT WDSMCS_E_NAMESPACE_NOT_FOUND = -1054801659;
	public const HRESULT WDSMCS_E_CONTENT_PROVIDER_NOT_FOUND = -1054801658;
	public const HRESULT WDSMCS_E_NAMESPACE_ALREADY_EXISTS = -1054801657;
	public const HRESULT WDSMCS_E_NAMESPACE_SHUTDOWN_IN_PROGRESS = -1054801656;
	public const HRESULT WDSMCS_E_NAMESPACE_ALREADY_STARTED = -1054801655;
	public const HRESULT WDSMCS_E_NS_START_FAILED_NO_CLIENTS = -1054801654;
	public const HRESULT WDSMCS_E_START_TIME_IN_PAST = -1054801653;
	public const HRESULT WDSMCS_E_PACKET_NOT_HASHED = -1054801652;
	public const HRESULT WDSMCS_E_PACKET_NOT_SIGNED = -1054801651;
	public const HRESULT WDSMCS_E_PACKET_HAS_SECURITY = -1054801650;
	public const HRESULT WDSMCS_E_PACKET_NOT_CHECKSUMED = -1054801649;
	public const HRESULT WDSMCS_E_CLIENT_DOESNOT_SUPPORT_SECURITY_MODE = -1054801648;
	public const HRESULT EVT_WDSMCS_S_PARAMETERS_READ = 1092682240;
	public const HRESULT EVT_WDSMCS_E_PARAMETERS_READ_FAILED = -1054801407;
	public const HRESULT EVT_WDSMCS_E_DUPLICATE_MULTICAST_ADDR = -1054801406;
	public const HRESULT EVT_WDSMCS_E_NON_WDS_DUPLICATE_MULTICAST_ADDR = -1054801405;
	public const HRESULT EVT_WDSMCS_E_CP_DLL_LOAD_FAILED = -1054801328;
	public const HRESULT EVT_WDSMCS_E_CP_INIT_FUNC_MISSING = -1054801327;
	public const HRESULT EVT_WDSMCS_E_CP_INIT_FUNC_FAILED = -1054801326;
	public const HRESULT EVT_WDSMCS_E_CP_INCOMPATIBLE_SERVER_VERSION = -1054801325;
	public const HRESULT EVT_WDSMCS_E_CP_CALLBACKS_NOT_REG = -1054801324;
	public const HRESULT EVT_WDSMCS_E_CP_SHUTDOWN_FUNC_FAILED = -1054801323;
	public const HRESULT EVT_WDSMCS_E_CP_MEMORY_LEAK = -1054801322;
	public const HRESULT EVT_WDSMCS_E_CP_OPEN_INSTANCE_FAILED = -1054801321;
	public const HRESULT EVT_WDSMCS_E_CP_CLOSE_INSTANCE_FAILED = -1054801320;
	public const HRESULT EVT_WDSMCS_E_CP_OPEN_CONTENT_FAILED = -1054801319;
	public const HRESULT EVT_WDSMCS_W_CP_DLL_LOAD_FAILED_NOT_CRITICAL = -2128543142;
	public const HRESULT EVT_WDSMCS_E_CP_DLL_LOAD_FAILED_CRITICAL = -1054801317;
	public const HRESULT EVT_WDSMCS_E_NSREG_START_TIME_IN_PAST = -1054801152;
	public const HRESULT EVT_WDSMCS_E_NSREG_CONTENT_PROVIDER_NOT_REG = -1054801151;
	public const HRESULT EVT_WDSMCS_E_NSREG_NAMESPACE_EXISTS = -1054801150;
	public const HRESULT EVT_WDSMCS_E_NSREG_FAILURE = -1054801149;
	public const HRESULT WDSTPC_E_CALLBACKS_NOT_REG = -1054735616;
	public const HRESULT WDSTPC_E_ALREADY_COMPLETED = -1054735615;
	public const HRESULT WDSTPC_E_ALREADY_IN_PROGRESS = -1054735614;
	public const HRESULT WDSTPC_E_UNKNOWN_ERROR = -1054735613;
	public const HRESULT WDSTPC_E_NOT_INITIALIZED = -1054735612;
	public const HRESULT WDSTPC_E_KICKED_POLICY_NOT_MET = -1054735611;
	public const HRESULT WDSTPC_E_KICKED_FALLBACK = -1054735610;
	public const HRESULT WDSTPC_E_KICKED_FAIL = -1054735609;
	public const HRESULT WDSTPC_E_KICKED_UNKNOWN = -1054735608;
	public const HRESULT WDSTPC_E_MULTISTREAM_NOT_ENABLED = -1054735607;
	public const HRESULT WDSTPC_E_ALREADY_IN_LOWEST_SESSION = -1054735606;
	public const HRESULT WDSTPC_E_CLIENT_DEMOTE_NOT_SUPPORTED = -1054735605;
	public const HRESULT WDSTPC_E_NO_IP4_INTERFACE = -1054735604;
	public const HRESULT WDSTPTC_E_WIM_APPLY_REQUIRES_REFERENCE_IMAGE = -1054735603;
	public const uint32 FACILITY_WDSTPTMGMT = 272;
	public const HRESULT WDSTPTMGMT_CATEGORY = 1;
	public const HRESULT WDSTPTMGMT_E_INVALID_PROPERTY = -1055915776;
	public const HRESULT WDSTPTMGMT_E_INVALID_OPERATION = -1055915775;
	public const HRESULT WDSTPTMGMT_E_INVALID_CLASS = -1055915774;
	public const HRESULT WDSTPTMGMT_E_CONTENT_PROVIDER_ALREADY_REGISTERED = -1055915773;
	public const HRESULT WDSTPTMGMT_E_CONTENT_PROVIDER_NOT_REGISTERED = -1055915772;
	public const HRESULT WDSTPTMGMT_E_INVALID_CONTENT_PROVIDER_NAME = -1055915771;
	public const HRESULT WDSTPTMGMT_E_TRANSPORT_SERVER_ROLE_NOT_CONFIGURED = -1055915770;
	public const HRESULT WDSTPTMGMT_E_NAMESPACE_ALREADY_REGISTERED = -1055915769;
	public const HRESULT WDSTPTMGMT_E_NAMESPACE_NOT_REGISTERED = -1055915768;
	public const HRESULT WDSTPTMGMT_E_CANNOT_REINITIALIZE_OBJECT = -1055915767;
	public const HRESULT WDSTPTMGMT_E_INVALID_NAMESPACE_NAME = -1055915766;
	public const HRESULT WDSTPTMGMT_E_INVALID_NAMESPACE_DATA = -1055915765;
	public const HRESULT WDSTPTMGMT_E_NAMESPACE_READ_ONLY = -1055915764;
	public const HRESULT WDSTPTMGMT_E_INVALID_NAMESPACE_START_TIME = -1055915763;
	public const HRESULT WDSTPTMGMT_E_INVALID_DIAGNOSTICS_COMPONENTS = -1055915762;
	public const HRESULT WDSTPTMGMT_E_CANNOT_REFRESH_DIRTY_OBJECT = -1055915761;
	public const HRESULT WDSTPTMGMT_E_INVALID_SERVICE_IP_ADDRESS_RANGE = -1055915760;
	public const HRESULT WDSTPTMGMT_E_INVALID_SERVICE_PORT_RANGE = -1055915759;
	public const HRESULT WDSTPTMGMT_E_INVALID_NAMESPACE_START_PARAMETERS = -1055915758;
	public const HRESULT WDSTPTMGMT_E_TRANSPORT_SERVER_UNAVAILABLE = -1055915757;
	public const HRESULT WDSTPTMGMT_E_NAMESPACE_NOT_ON_SERVER = -1055915756;
	public const HRESULT WDSTPTMGMT_E_NAMESPACE_REMOVED_FROM_SERVER = -1055915755;
	public const HRESULT WDSTPTMGMT_E_INVALID_IP_ADDRESS = -1055915754;
	public const HRESULT WDSTPTMGMT_E_INVALID_IPV4_MULTICAST_ADDRESS = -1055915753;
	public const HRESULT WDSTPTMGMT_E_INVALID_IPV6_MULTICAST_ADDRESS = -1055915752;
	public const HRESULT WDSTPTMGMT_E_IPV6_NOT_SUPPORTED = -1055915751;
	public const HRESULT WDSTPTMGMT_E_INVALID_IPV6_MULTICAST_ADDRESS_SOURCE = -1055915750;
	public const HRESULT WDSTPTMGMT_E_INVALID_MULTISTREAM_STREAM_COUNT = -1055915749;
	public const HRESULT WDSTPTMGMT_E_INVALID_AUTO_DISCONNECT_THRESHOLD = -1055915748;
	public const HRESULT WDSTPTMGMT_E_MULTICAST_SESSION_POLICY_NOT_SUPPORTED = -1055915747;
	public const HRESULT WDSTPTMGMT_E_INVALID_SLOW_CLIENT_HANDLING_TYPE = -1055915746;
	public const HRESULT WDSTPTMGMT_E_NETWORK_PROFILES_NOT_SUPPORTED = -1055915745;
	public const HRESULT WDSTPTMGMT_E_UDP_PORT_POLICY_NOT_SUPPORTED = -1055915744;
	public const HRESULT WDSTPTMGMT_E_TFTP_MAX_BLOCKSIZE_NOT_SUPPORTED = -1055915743;
	public const HRESULT WDSTPTMGMT_E_TFTP_VAR_WINDOW_NOT_SUPPORTED = -1055915742;
	public const HRESULT WDSTPTMGMT_E_INVALID_TFTP_MAX_BLOCKSIZE = -1055915741;
	public const int32 WdsCliFlagEnumFilterVersion = 1;
	public const int32 WdsCliFlagEnumFilterFirmware = 2;
	public const int32 WDS_LOG_TYPE_CLIENT_ERROR = 1;
	public const int32 WDS_LOG_TYPE_CLIENT_STARTED = 2;
	public const int32 WDS_LOG_TYPE_CLIENT_FINISHED = 3;
	public const int32 WDS_LOG_TYPE_CLIENT_IMAGE_SELECTED = 4;
	public const int32 WDS_LOG_TYPE_CLIENT_APPLY_STARTED = 5;
	public const int32 WDS_LOG_TYPE_CLIENT_APPLY_FINISHED = 6;
	public const int32 WDS_LOG_TYPE_CLIENT_GENERIC_MESSAGE = 7;
	public const int32 WDS_LOG_TYPE_CLIENT_UNATTEND_MODE = 8;
	public const int32 WDS_LOG_TYPE_CLIENT_TRANSFER_START = 9;
	public const int32 WDS_LOG_TYPE_CLIENT_TRANSFER_END = 10;
	public const int32 WDS_LOG_TYPE_CLIENT_TRANSFER_DOWNGRADE = 11;
	public const int32 WDS_LOG_TYPE_CLIENT_DOMAINJOINERROR = 12;
	public const int32 WDS_LOG_TYPE_CLIENT_POST_ACTIONS_START = 13;
	public const int32 WDS_LOG_TYPE_CLIENT_POST_ACTIONS_END = 14;
	public const int32 WDS_LOG_TYPE_CLIENT_APPLY_STARTED_2 = 15;
	public const int32 WDS_LOG_TYPE_CLIENT_APPLY_FINISHED_2 = 16;
	public const int32 WDS_LOG_TYPE_CLIENT_DOMAINJOINERROR_2 = 17;
	public const int32 WDS_LOG_TYPE_CLIENT_DRIVER_PACKAGE_NOT_ACCESSIBLE = 18;
	public const int32 WDS_LOG_TYPE_CLIENT_OFFLINE_DRIVER_INJECTION_START = 19;
	public const int32 WDS_LOG_TYPE_CLIENT_OFFLINE_DRIVER_INJECTION_END = 20;
	public const int32 WDS_LOG_TYPE_CLIENT_OFFLINE_DRIVER_INJECTION_FAILURE = 21;
	public const int32 WDS_LOG_TYPE_CLIENT_IMAGE_SELECTED2 = 22;
	public const int32 WDS_LOG_TYPE_CLIENT_IMAGE_SELECTED3 = 23;
	public const int32 WDS_LOG_TYPE_CLIENT_MAX_CODE = 24;
	public const int32 WDS_LOG_LEVEL_DISABLED = 0;
	public const int32 WDS_LOG_LEVEL_ERROR = 1;
	public const int32 WDS_LOG_LEVEL_WARNING = 2;
	public const int32 WDS_LOG_LEVEL_INFO = 3;
}
#endregion

#region Enums

[AllowDuplicates]
public enum CPU_ARCHITECTURE : uint32
{
	CPU_ARCHITECTURE_AMD64 = 9,
	CPU_ARCHITECTURE_IA64 = 6,
	CPU_ARCHITECTURE_INTEL = 0,
}


[AllowDuplicates]
public enum PFN_WDS_CLI_CALLBACK_MESSAGE_ID : uint32
{
	WDS_CLI_MSG_START = 0,
	WDS_CLI_MSG_COMPLETE = 1,
	WDS_CLI_MSG_PROGRESS = 2,
	WDS_CLI_MSG_TEXT = 3,
}


[AllowDuplicates]
public enum WDS_TRANSPORTCLIENT_REQUEST_AUTH_LEVEL : uint32
{
	WDS_TRANSPORTCLIENT_AUTH = 1,
	WDS_TRANSPORTCLIENT_NO_AUTH = 2,
}


[AllowDuplicates]
public enum WDS_CLI_IMAGE_TYPE : int32
{
	WDS_CLI_IMAGE_TYPE_UNKNOWN = 0,
	WDS_CLI_IMAGE_TYPE_WIM = 1,
	WDS_CLI_IMAGE_TYPE_VHD = 2,
	WDS_CLI_IMAGE_TYPE_VHDX = 3,
}


[AllowDuplicates]
public enum WDS_CLI_FIRMWARE_TYPE : int32
{
	WDS_CLI_FIRMWARE_UNKNOWN = 0,
	WDS_CLI_FIRMWARE_BIOS = 1,
	WDS_CLI_FIRMWARE_EFI = 2,
}


[AllowDuplicates]
public enum WDS_CLI_IMAGE_PARAM_TYPE : int32
{
	WDS_CLI_IMAGE_PARAM_UNKNOWN = 0,
	WDS_CLI_IMAGE_PARAM_SPARSE_FILE = 1,
	WDS_CLI_IMAGE_PARAM_SUPPORTED_FIRMWARES = 2,
}


[AllowDuplicates]
public enum TRANSPORTPROVIDER_CALLBACK_ID : int32
{
	WDS_TRANSPORTPROVIDER_CREATE_INSTANCE = 0,
	WDS_TRANSPORTPROVIDER_COMPARE_CONTENT = 1,
	WDS_TRANSPORTPROVIDER_OPEN_CONTENT = 2,
	WDS_TRANSPORTPROVIDER_USER_ACCESS_CHECK = 3,
	WDS_TRANSPORTPROVIDER_GET_CONTENT_SIZE = 4,
	WDS_TRANSPORTPROVIDER_READ_CONTENT = 5,
	WDS_TRANSPORTPROVIDER_CLOSE_CONTENT = 6,
	WDS_TRANSPORTPROVIDER_CLOSE_INSTANCE = 7,
	WDS_TRANSPORTPROVIDER_SHUTDOWN = 8,
	WDS_TRANSPORTPROVIDER_DUMP_STATE = 9,
	WDS_TRANSPORTPROVIDER_REFRESH_SETTINGS = 10,
	WDS_TRANSPORTPROVIDER_GET_CONTENT_METADATA = 11,
	WDS_TRANSPORTPROVIDER_MAX_CALLBACKS = 12,
}


[AllowDuplicates]
public enum TRANSPORTCLIENT_CALLBACK_ID : int32
{
	WDS_TRANSPORTCLIENT_SESSION_START = 0,
	WDS_TRANSPORTCLIENT_RECEIVE_CONTENTS = 1,
	WDS_TRANSPORTCLIENT_SESSION_COMPLETE = 2,
	WDS_TRANSPORTCLIENT_RECEIVE_METADATA = 3,
	WDS_TRANSPORTCLIENT_SESSION_STARTEX = 4,
	WDS_TRANSPORTCLIENT_SESSION_NEGOTIATE = 5,
	WDS_TRANSPORTCLIENT_MAX_CALLBACKS = 6,
}


[AllowDuplicates]
public enum WDSTRANSPORT_FEATURE_FLAGS : int32
{
	WdsTptFeatureAdminPack = 1,
	WdsTptFeatureTransportServer = 2,
	WdsTptFeatureDeploymentServer = 4,
}


[AllowDuplicates]
public enum WDSTRANSPORT_PROTOCOL_FLAGS : int32
{
	WdsTptProtocolUnicast = 1,
	WdsTptProtocolMulticast = 2,
}


[AllowDuplicates]
public enum WDSTRANSPORT_NAMESPACE_TYPE : int32
{
	WdsTptNamespaceTypeUnknown = 0,
	WdsTptNamespaceTypeAutoCast = 1,
	WdsTptNamespaceTypeScheduledCastManualStart = 2,
	WdsTptNamespaceTypeScheduledCastAutoStart = 3,
}


[AllowDuplicates]
public enum WDSTRANSPORT_DISCONNECT_TYPE : int32
{
	WdsTptDisconnectUnknown = 0,
	WdsTptDisconnectFallback = 1,
	WdsTptDisconnectAbort = 2,
}


[AllowDuplicates]
public enum WDSTRANSPORT_SERVICE_NOTIFICATION : int32
{
	WdsTptServiceNotifyUnknown = 0,
	WdsTptServiceNotifyReadSettings = 1,
}


[AllowDuplicates]
public enum WDSTRANSPORT_IP_ADDRESS_TYPE : int32
{
	WdsTptIpAddressUnknown = 0,
	WdsTptIpAddressIpv4 = 1,
	WdsTptIpAddressIpv6 = 2,
}


[AllowDuplicates]
public enum WDSTRANSPORT_IP_ADDRESS_SOURCE_TYPE : int32
{
	WdsTptIpAddressSourceUnknown = 0,
	WdsTptIpAddressSourceDhcp = 1,
	WdsTptIpAddressSourceRange = 2,
}


[AllowDuplicates]
public enum WDSTRANSPORT_NETWORK_PROFILE_TYPE : int32
{
	WdsTptNetworkProfileUnknown = 0,
	WdsTptNetworkProfileCustom = 1,
	WdsTptNetworkProfile10Mbps = 2,
	WdsTptNetworkProfile100Mbps = 3,
	WdsTptNetworkProfile1Gbps = 4,
}


[AllowDuplicates]
public enum WDSTRANSPORT_DIAGNOSTICS_COMPONENT_FLAGS : int32
{
	WdsTptDiagnosticsComponentPxe = 1,
	WdsTptDiagnosticsComponentTftp = 2,
	WdsTptDiagnosticsComponentImageServer = 4,
	WdsTptDiagnosticsComponentMulticast = 8,
}


[AllowDuplicates]
public enum WDSTRANSPORT_SLOW_CLIENT_HANDLING_TYPE : int32
{
	WdsTptSlowClientHandlingUnknown = 0,
	WdsTptSlowClientHandlingNone = 1,
	WdsTptSlowClientHandlingAutoDisconnect = 2,
	WdsTptSlowClientHandlingMultistream = 3,
}


[AllowDuplicates]
public enum WDSTRANSPORT_UDP_PORT_POLICY : int32
{
	WdsTptUdpPortPolicyDynamic = 0,
	WdsTptUdpPortPolicyFixed = 1,
}


[AllowDuplicates]
public enum WDSTRANSPORT_TFTP_CAPABILITY : int32
{
	WdsTptTftpCapMaximumBlockSize = 1,
	WdsTptTftpCapVariableWindow = 2,
}

#endregion

#region Function Pointers
public function void PFN_WdsCliTraceFunction(PWSTR pwszFormat, int8* Params);

public function void PFN_WdsCliCallback(PFN_WDS_CLI_CALLBACK_MESSAGE_ID dwMessageId, WPARAM wParam, LPARAM lParam, void* pvUserData);

public function void PFN_WdsTransportClientSessionStart(HANDLE hSessionKey, void* pCallerData, ULARGE_INTEGER* ullFileSize);

public function void PFN_WdsTransportClientSessionStartEx(HANDLE hSessionKey, void* pCallerData, TRANSPORTCLIENT_SESSION_INFO* Info);

public function void PFN_WdsTransportClientReceiveMetadata(HANDLE hSessionKey, void* pCallerData, void* pMetadata, uint32 ulSize);

public function void PFN_WdsTransportClientReceiveContents(HANDLE hSessionKey, void* pCallerData, void* pContents, uint32 ulSize, ULARGE_INTEGER* pullContentOffset);

public function void PFN_WdsTransportClientSessionComplete(HANDLE hSessionKey, void* pCallerData, uint32 dwError);

public function void PFN_WdsTransportClientSessionNegotiate(HANDLE hSessionKey, void* pCallerData, TRANSPORTCLIENT_SESSION_INFO* pInfo, HANDLE hNegotiateKey);

#endregion

#region Structs
[CRepr]
public struct WDS_CLI_CRED
{
	public PWSTR pwszUserName;
	public PWSTR pwszDomain;
	public PWSTR pwszPassword;
}

[CRepr, Packed(1)]
public struct PXE_DHCP_OPTION
{
	public uint8 OptionType;
	public uint8 OptionLength;
	public uint8* OptionValue mut => &OptionValue_impl;
	private uint8[ANYSIZE_ARRAY] OptionValue_impl;
}

[CRepr, Packed(1)]
public struct PXE_DHCP_MESSAGE
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous_e__Union
	{
		public uint8[4] bMagicCookie;
		public uint32 uMagicCookie;
	}
	public uint8 Operation;
	public uint8 HardwareAddressType;
	public uint8 HardwareAddressLength;
	public uint8 HopCount;
	public uint32 TransactionID;
	public uint16 SecondsSinceBoot;
	public uint16 Reserved;
	public uint32 ClientIpAddress;
	public uint32 YourIpAddress;
	public uint32 BootstrapServerAddress;
	public uint32 RelayAgentIpAddress;
	public uint8[16] HardwareAddress;
	public uint8[64] HostName;
	public uint8[128] BootFileName;
	public using _Anonymous_e__Union Anonymous;
	public PXE_DHCP_OPTION Option;
}

[CRepr, Packed(1)]
public struct PXE_DHCPV6_OPTION
{
	public uint16 OptionCode;
	public uint16 DataLength;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr, Packed(1)]
public struct PXE_DHCPV6_MESSAGE_HEADER
{
	public uint8 MessageType;
	public uint8* Message mut => &Message_impl;
	private uint8[ANYSIZE_ARRAY] Message_impl;
}

[CRepr, Packed(1)]
public struct PXE_DHCPV6_MESSAGE
{
	public uint8 MessageType;
	public uint8 TransactionIDByte1;
	public uint8 TransactionIDByte2;
	public uint8 TransactionIDByte3;
	public PXE_DHCPV6_OPTION* Options mut => &Options_impl;
	private PXE_DHCPV6_OPTION[ANYSIZE_ARRAY] Options_impl;
}

[CRepr, Packed(1)]
public struct PXE_DHCPV6_RELAY_MESSAGE
{
	public uint8 MessageType;
	public uint8 HopCount;
	public uint8[16] LinkAddress;
	public uint8[16] PeerAddress;
	public PXE_DHCPV6_OPTION* Options mut => &Options_impl;
	private PXE_DHCPV6_OPTION[ANYSIZE_ARRAY] Options_impl;
}

[CRepr]
public struct PXE_PROVIDER
{
	public uint32 uSizeOfStruct;
	public PWSTR pwszName;
	public PWSTR pwszFilePath;
	public BOOL bIsCritical;
	public uint32 uIndex;
}

[CRepr]
public struct PXE_ADDRESS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint8[16] bAddress;
		public uint32 uIpAddress;
	}
	public uint32 uFlags;
	public using _Anonymous_e__Union Anonymous;
	public uint32 uAddrLen;
	public uint16 uPort;
}

[CRepr]
public struct PXE_DHCPV6_NESTED_RELAY_MESSAGE
{
	public PXE_DHCPV6_RELAY_MESSAGE* pRelayMessage;
	public uint32 cbRelayMessage;
	public void* pInterfaceIdOption;
	public uint16 cbInterfaceIdOption;
}

[CRepr]
public struct WDS_TRANSPORTPROVIDER_INIT_PARAMS
{
	public uint32 ulLength;
	public uint32 ulMcServerVersion;
	public HKEY hRegistryKey;
	public HANDLE hProvider;
}

[CRepr]
public struct WDS_TRANSPORTPROVIDER_SETTINGS
{
	public uint32 ulLength;
	public uint32 ulProviderVersion;
}

[CRepr]
public struct TRANSPORTCLIENT_SESSION_INFO
{
	public uint32 ulStructureLength;
	public ULARGE_INTEGER ullFileSize;
	public uint32 ulBlockSize;
}

[CRepr]
public struct WDS_TRANSPORTCLIENT_REQUEST
{
	public uint32 ulLength;
	public uint32 ulApiVersion;
	public WDS_TRANSPORTCLIENT_REQUEST_AUTH_LEVEL ulAuthLevel;
	public PWSTR pwszServer;
	public PWSTR pwszNamespace;
	public PWSTR pwszObjectName;
	public uint32 ulCacheSize;
	public uint32 ulProtocol;
	public void* pvProtocolData;
	public uint32 ulProtocolDataLength;
}

[CRepr]
public struct WDS_TRANSPORTCLIENT_CALLBACKS
{
	public PFN_WdsTransportClientSessionStart SessionStart;
	public PFN_WdsTransportClientSessionStartEx SessionStartEx;
	public PFN_WdsTransportClientReceiveContents ReceiveContents;
	public PFN_WdsTransportClientReceiveMetadata ReceiveMetadata;
	public PFN_WdsTransportClientSessionComplete SessionComplete;
	public PFN_WdsTransportClientSessionNegotiate SessionNegotiate;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_WdsTransportCacheable = .(0x70590b16, 0xf146, 0x46bd, 0xbd, 0x9d, 0x4a, 0xaa, 0x90, 0x08, 0x4b, 0xf5);


	public const Guid CLSID_WdsTransportCollection = .(0xc7f18b09, 0x391e, 0x436e, 0xb1, 0x0b, 0xc3, 0xef, 0x46, 0xf2, 0xc3, 0x4f);


	public const Guid CLSID_WdsTransportManager = .(0xf21523f6, 0x837c, 0x4a58, 0xaf, 0x99, 0x8a, 0x7e, 0x27, 0xf8, 0xff, 0x59);


	public const Guid CLSID_WdsTransportServer = .(0xea19b643, 0x4adf, 0x4413, 0x94, 0x2c, 0x14, 0xf3, 0x79, 0x11, 0x87, 0x60);


	public const Guid CLSID_WdsTransportSetupManager = .(0xc7beeaad, 0x9f04, 0x4923, 0x9f, 0x0c, 0xfb, 0xf5, 0x2b, 0xc7, 0x59, 0x0f);


	public const Guid CLSID_WdsTransportConfigurationManager = .(0x8743f674, 0x904c, 0x47ca, 0x85, 0x12, 0x35, 0xfe, 0x98, 0xf6, 0xb0, 0xac);


	public const Guid CLSID_WdsTransportNamespaceManager = .(0xf08cdb63, 0x85de, 0x4a28, 0xa1, 0xa9, 0x5c, 0xa3, 0xe7, 0xef, 0xda, 0x73);


	public const Guid CLSID_WdsTransportServicePolicy = .(0x65aceadc, 0x2f0b, 0x4f43, 0x9f, 0x4d, 0x81, 0x18, 0x65, 0xd8, 0xce, 0xad);


	public const Guid CLSID_WdsTransportDiagnosticsPolicy = .(0xeb3333e1, 0xa7ad, 0x46f5, 0x80, 0xd6, 0x6b, 0x74, 0x02, 0x04, 0xe5, 0x09);


	public const Guid CLSID_WdsTransportMulticastSessionPolicy = .(0x3c6bc3f4, 0x6418, 0x472a, 0xb6, 0xf1, 0x52, 0xd4, 0x57, 0x19, 0x54, 0x37);


	public const Guid CLSID_WdsTransportNamespace = .(0xd8385768, 0x0732, 0x4ec1, 0x95, 0xea, 0x16, 0xda, 0x58, 0x19, 0x08, 0xa1);


	public const Guid CLSID_WdsTransportNamespaceAutoCast = .(0xb091f5a8, 0x6a99, 0x478d, 0xb2, 0x3b, 0x09, 0xe8, 0xfe, 0xe0, 0x45, 0x74);


	public const Guid CLSID_WdsTransportNamespaceScheduledCast = .(0xbadc1897, 0x7025, 0x44eb, 0x91, 0x08, 0xfb, 0x61, 0xc4, 0x05, 0x57, 0x92);


	public const Guid CLSID_WdsTransportNamespaceScheduledCastManualStart = .(0xd3e1a2aa, 0xcaac, 0x460e, 0xb9, 0x8a, 0x47, 0xf9, 0xf3, 0x18, 0xa1, 0xfa);


	public const Guid CLSID_WdsTransportNamespaceScheduledCastAutoStart = .(0xa1107052, 0x122c, 0x4b81, 0x9b, 0x7c, 0x38, 0x6e, 0x68, 0x55, 0x38, 0x3f);


	public const Guid CLSID_WdsTransportContent = .(0x0a891fe7, 0x4a3f, 0x4c65, 0xb6, 0xf2, 0x14, 0x67, 0x61, 0x96, 0x79, 0xea);


	public const Guid CLSID_WdsTransportSession = .(0x749ac4e0, 0x67bc, 0x4743, 0xbf, 0xe5, 0xca, 0xcb, 0x1f, 0x26, 0xf5, 0x7f);


	public const Guid CLSID_WdsTransportClient = .(0x66d2c5e9, 0x0ff6, 0x49ec, 0x97, 0x33, 0xda, 0xfb, 0x1e, 0x01, 0xdf, 0x1c);


	public const Guid CLSID_WdsTransportTftpClient = .(0x50343925, 0x7c5c, 0x4c8c, 0x96, 0xc4, 0xad, 0x9f, 0xa5, 0x00, 0x5f, 0xba);


	public const Guid CLSID_WdsTransportTftpManager = .(0xc8e9dca2, 0x3241, 0x4e4d, 0xb8, 0x06, 0xbc, 0x74, 0x01, 0x9d, 0xfe, 0xda);


	public const Guid CLSID_WdsTransportContentProvider = .(0xe0be741f, 0x5a75, 0x4eb9, 0x8a, 0x2d, 0x5e, 0x18, 0x9b, 0x45, 0xf3, 0x27);


}
#endregion

#region COM Types
[CRepr]struct IWdsTransportCacheable : IDispatch
{
	public new const Guid IID = .(0x46ad894b, 0x0bab, 0x47dc, 0x84, 0xb2, 0x7b, 0x55, 0x3f, 0x1d, 0x8f, 0x80);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbDirty) get_Dirty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Discard;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
	}


	public HRESULT get_Dirty(int16* pbDirty) mut => VT.[Friend]get_Dirty(&this, pbDirty);

	public HRESULT Discard() mut => VT.[Friend]Discard(&this);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);
}

[CRepr]struct IWdsTransportCollection : IDispatch
{
	public new const Guid IID = .(0xb8ba4b1a, 0x2ff4, 0x43ab, 0x99, 0x6c, 0xb2, 0xb1, 0x0a, 0x91, 0xa6, 0xeb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulIndex, IDispatch** ppVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppVal) get__NewEnum;
	}


	public HRESULT get_Count(uint32* pulCount) mut => VT.[Friend]get_Count(&this, pulCount);

	public HRESULT get_Item(uint32 ulIndex, IDispatch** ppVal) mut => VT.[Friend]get_Item(&this, ulIndex, ppVal);

	public HRESULT get__NewEnum(IUnknown** ppVal) mut => VT.[Friend]get__NewEnum(&this, ppVal);
}

[CRepr]struct IWdsTransportManager : IDispatch
{
	public new const Guid IID = .(0x5b0d35f5, 0x1b13, 0x4afd, 0xb8, 0x78, 0x65, 0x26, 0xdc, 0x34, 0x0b, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bszServerName, IWdsTransportServer** ppWdsTransportServer) GetWdsTransportServer;
	}


	public HRESULT GetWdsTransportServer(BSTR bszServerName, IWdsTransportServer** ppWdsTransportServer) mut => VT.[Friend]GetWdsTransportServer(&this, bszServerName, ppWdsTransportServer);
}

[CRepr]struct IWdsTransportServer : IDispatch
{
	public new const Guid IID = .(0x09ccd093, 0x830d, 0x4344, 0xa3, 0x0a, 0x73, 0xae, 0x8e, 0x8f, 0xca, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportSetupManager** ppWdsTransportSetupManager) get_SetupManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportConfigurationManager** ppWdsTransportConfigurationManager) get_ConfigurationManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportNamespaceManager** ppWdsTransportNamespaceManager) get_NamespaceManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulClientId, WDSTRANSPORT_DISCONNECT_TYPE DisconnectionType) DisconnectClient;
	}


	public HRESULT get_Name(BSTR* pbszName) mut => VT.[Friend]get_Name(&this, pbszName);

	public HRESULT get_SetupManager(IWdsTransportSetupManager** ppWdsTransportSetupManager) mut => VT.[Friend]get_SetupManager(&this, ppWdsTransportSetupManager);

	public HRESULT get_ConfigurationManager(IWdsTransportConfigurationManager** ppWdsTransportConfigurationManager) mut => VT.[Friend]get_ConfigurationManager(&this, ppWdsTransportConfigurationManager);

	public HRESULT get_NamespaceManager(IWdsTransportNamespaceManager** ppWdsTransportNamespaceManager) mut => VT.[Friend]get_NamespaceManager(&this, ppWdsTransportNamespaceManager);

	public HRESULT DisconnectClient(uint32 ulClientId, WDSTRANSPORT_DISCONNECT_TYPE DisconnectionType) mut => VT.[Friend]DisconnectClient(&this, ulClientId, DisconnectionType);
}

[CRepr]struct IWdsTransportServer2 : IWdsTransportServer
{
	public new const Guid IID = .(0x256e999f, 0x6df4, 0x4538, 0x81, 0xb9, 0x85, 0x7b, 0x9a, 0xb8, 0xfb, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportServer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportTftpManager** ppWdsTransportTftpManager) get_TftpManager;
	}


	public HRESULT get_TftpManager(IWdsTransportTftpManager** ppWdsTransportTftpManager) mut => VT.[Friend]get_TftpManager(&this, ppWdsTransportTftpManager);
}

[CRepr]struct IWdsTransportSetupManager : IDispatch
{
	public new const Guid IID = .(0xf7238425, 0xefa8, 0x40a4, 0xae, 0xf9, 0xc9, 0x8d, 0x96, 0x9c, 0x0b, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pullVersion) get_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulInstalledFeatures) get_InstalledFeatures;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulProtocols) get_Protocols;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bszName, BSTR bszDescription, BSTR bszFilePath, BSTR bszInitializationRoutine) RegisterContentProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bszName) DeregisterContentProvider;
	}


	public HRESULT get_Version(uint64* pullVersion) mut => VT.[Friend]get_Version(&this, pullVersion);

	public HRESULT get_InstalledFeatures(uint32* pulInstalledFeatures) mut => VT.[Friend]get_InstalledFeatures(&this, pulInstalledFeatures);

	public HRESULT get_Protocols(uint32* pulProtocols) mut => VT.[Friend]get_Protocols(&this, pulProtocols);

	public HRESULT RegisterContentProvider(BSTR bszName, BSTR bszDescription, BSTR bszFilePath, BSTR bszInitializationRoutine) mut => VT.[Friend]RegisterContentProvider(&this, bszName, bszDescription, bszFilePath, bszInitializationRoutine);

	public HRESULT DeregisterContentProvider(BSTR bszName) mut => VT.[Friend]DeregisterContentProvider(&this, bszName);
}

[CRepr]struct IWdsTransportSetupManager2 : IWdsTransportSetupManager
{
	public new const Guid IID = .(0x02be79da, 0x7e9e, 0x4366, 0x8b, 0x6e, 0x2a, 0xa9, 0xa9, 0x1b, 0xe4, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportSetupManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulTftpCapabilities) get_TftpCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportCollection** ppProviderCollection) get_ContentProviders;
	}


	public HRESULT get_TftpCapabilities(uint32* pulTftpCapabilities) mut => VT.[Friend]get_TftpCapabilities(&this, pulTftpCapabilities);

	public HRESULT get_ContentProviders(IWdsTransportCollection** ppProviderCollection) mut => VT.[Friend]get_ContentProviders(&this, ppProviderCollection);
}

[CRepr]struct IWdsTransportConfigurationManager : IDispatch
{
	public new const Guid IID = .(0x84cc4779, 0x42dd, 0x4792, 0x89, 0x1e, 0x13, 0x21, 0xd6, 0xd7, 0x4b, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportServicePolicy** ppWdsTransportServicePolicy) get_ServicePolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportDiagnosticsPolicy** ppWdsTransportDiagnosticsPolicy) get_DiagnosticsPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bRealtimeStatus, int16* pbServicesRunning) get_WdsTransportServicesRunning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableWdsTransportServices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableWdsTransportServices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StartWdsTransportServices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopWdsTransportServices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestartWdsTransportServices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_SERVICE_NOTIFICATION ServiceNotification) NotifyWdsTransportServices;
	}


	public HRESULT get_ServicePolicy(IWdsTransportServicePolicy** ppWdsTransportServicePolicy) mut => VT.[Friend]get_ServicePolicy(&this, ppWdsTransportServicePolicy);

	public HRESULT get_DiagnosticsPolicy(IWdsTransportDiagnosticsPolicy** ppWdsTransportDiagnosticsPolicy) mut => VT.[Friend]get_DiagnosticsPolicy(&this, ppWdsTransportDiagnosticsPolicy);

	public HRESULT get_WdsTransportServicesRunning(int16 bRealtimeStatus, int16* pbServicesRunning) mut => VT.[Friend]get_WdsTransportServicesRunning(&this, bRealtimeStatus, pbServicesRunning);

	public HRESULT EnableWdsTransportServices() mut => VT.[Friend]EnableWdsTransportServices(&this);

	public HRESULT DisableWdsTransportServices() mut => VT.[Friend]DisableWdsTransportServices(&this);

	public HRESULT StartWdsTransportServices() mut => VT.[Friend]StartWdsTransportServices(&this);

	public HRESULT StopWdsTransportServices() mut => VT.[Friend]StopWdsTransportServices(&this);

	public HRESULT RestartWdsTransportServices() mut => VT.[Friend]RestartWdsTransportServices(&this);

	public HRESULT NotifyWdsTransportServices(WDSTRANSPORT_SERVICE_NOTIFICATION ServiceNotification) mut => VT.[Friend]NotifyWdsTransportServices(&this, ServiceNotification);
}

[CRepr]struct IWdsTransportConfigurationManager2 : IWdsTransportConfigurationManager
{
	public new const Guid IID = .(0xd0d85caf, 0xa153, 0x4f1d, 0xa9, 0xdd, 0x96, 0xf4, 0x31, 0xc5, 0x07, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportConfigurationManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportMulticastSessionPolicy** ppWdsTransportMulticastSessionPolicy) get_MulticastSessionPolicy;
	}


	public HRESULT get_MulticastSessionPolicy(IWdsTransportMulticastSessionPolicy** ppWdsTransportMulticastSessionPolicy) mut => VT.[Friend]get_MulticastSessionPolicy(&this, ppWdsTransportMulticastSessionPolicy);
}

[CRepr]struct IWdsTransportNamespaceManager : IDispatch
{
	public new const Guid IID = .(0x3e22d9f6, 0x3777, 0x4d98, 0x83, 0xe1, 0xf9, 0x86, 0x96, 0x71, 0x7b, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_NAMESPACE_TYPE NamespaceType, BSTR bszNamespaceName, BSTR bszContentProvider, BSTR bszConfiguration, IWdsTransportNamespace** ppWdsTransportNamespace) CreateNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bszNamespaceName, IWdsTransportNamespace** ppWdsTransportNamespace) RetrieveNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bszContentProvider, BSTR bszNamespaceName, int16 bIncludeTombstones, IWdsTransportCollection** ppWdsTransportNamespaces) RetrieveNamespaces;
	}


	public HRESULT CreateNamespace(WDSTRANSPORT_NAMESPACE_TYPE NamespaceType, BSTR bszNamespaceName, BSTR bszContentProvider, BSTR bszConfiguration, IWdsTransportNamespace** ppWdsTransportNamespace) mut => VT.[Friend]CreateNamespace(&this, NamespaceType, bszNamespaceName, bszContentProvider, bszConfiguration, ppWdsTransportNamespace);

	public HRESULT RetrieveNamespace(BSTR bszNamespaceName, IWdsTransportNamespace** ppWdsTransportNamespace) mut => VT.[Friend]RetrieveNamespace(&this, bszNamespaceName, ppWdsTransportNamespace);

	public HRESULT RetrieveNamespaces(BSTR bszContentProvider, BSTR bszNamespaceName, int16 bIncludeTombstones, IWdsTransportCollection** ppWdsTransportNamespaces) mut => VT.[Friend]RetrieveNamespaces(&this, bszContentProvider, bszNamespaceName, bIncludeTombstones, ppWdsTransportNamespaces);
}

[CRepr]struct IWdsTransportTftpManager : IDispatch
{
	public new const Guid IID = .(0x1327a7c8, 0xae8a, 0x4fb3, 0x81, 0x50, 0x13, 0x62, 0x27, 0xc3, 0x7e, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportCollection** ppWdsTransportTftpClients) RetrieveTftpClients;
	}


	public HRESULT RetrieveTftpClients(IWdsTransportCollection** ppWdsTransportTftpClients) mut => VT.[Friend]RetrieveTftpClients(&this, ppWdsTransportTftpClients);
}

[CRepr]struct IWdsTransportServicePolicy : IWdsTransportCacheable
{
	public new const Guid IID = .(0xb9468578, 0x9f2b, 0x48cc, 0xb2, 0x7a, 0xa6, 0x07, 0x99, 0xc2, 0x75, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportCacheable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, WDSTRANSPORT_IP_ADDRESS_SOURCE_TYPE* pSourceType) get_IpAddressSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, WDSTRANSPORT_IP_ADDRESS_SOURCE_TYPE SourceType) put_IpAddressSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, BSTR* pbszStartIpAddress) get_StartIpAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, BSTR bszStartIpAddress) put_StartIpAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, BSTR* pbszEndIpAddress) get_EndIpAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, BSTR bszEndIpAddress) put_EndIpAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulStartPort) get_StartPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulStartPort) put_StartPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulEndPort) get_EndPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulEndPort) put_EndPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_NETWORK_PROFILE_TYPE* pProfileType) get_NetworkProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_NETWORK_PROFILE_TYPE ProfileType) put_NetworkProfile;
	}


	public HRESULT get_IpAddressSource(WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, WDSTRANSPORT_IP_ADDRESS_SOURCE_TYPE* pSourceType) mut => VT.[Friend]get_IpAddressSource(&this, AddressType, pSourceType);

	public HRESULT put_IpAddressSource(WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, WDSTRANSPORT_IP_ADDRESS_SOURCE_TYPE SourceType) mut => VT.[Friend]put_IpAddressSource(&this, AddressType, SourceType);

	public HRESULT get_StartIpAddress(WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, BSTR* pbszStartIpAddress) mut => VT.[Friend]get_StartIpAddress(&this, AddressType, pbszStartIpAddress);

	public HRESULT put_StartIpAddress(WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, BSTR bszStartIpAddress) mut => VT.[Friend]put_StartIpAddress(&this, AddressType, bszStartIpAddress);

	public HRESULT get_EndIpAddress(WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, BSTR* pbszEndIpAddress) mut => VT.[Friend]get_EndIpAddress(&this, AddressType, pbszEndIpAddress);

	public HRESULT put_EndIpAddress(WDSTRANSPORT_IP_ADDRESS_TYPE AddressType, BSTR bszEndIpAddress) mut => VT.[Friend]put_EndIpAddress(&this, AddressType, bszEndIpAddress);

	public HRESULT get_StartPort(uint32* pulStartPort) mut => VT.[Friend]get_StartPort(&this, pulStartPort);

	public HRESULT put_StartPort(uint32 ulStartPort) mut => VT.[Friend]put_StartPort(&this, ulStartPort);

	public HRESULT get_EndPort(uint32* pulEndPort) mut => VT.[Friend]get_EndPort(&this, pulEndPort);

	public HRESULT put_EndPort(uint32 ulEndPort) mut => VT.[Friend]put_EndPort(&this, ulEndPort);

	public HRESULT get_NetworkProfile(WDSTRANSPORT_NETWORK_PROFILE_TYPE* pProfileType) mut => VT.[Friend]get_NetworkProfile(&this, pProfileType);

	public HRESULT put_NetworkProfile(WDSTRANSPORT_NETWORK_PROFILE_TYPE ProfileType) mut => VT.[Friend]put_NetworkProfile(&this, ProfileType);
}

[CRepr]struct IWdsTransportServicePolicy2 : IWdsTransportServicePolicy
{
	public new const Guid IID = .(0x65c19e5c, 0xaa7e, 0x4b91, 0x89, 0x44, 0x91, 0xe0, 0xe5, 0x57, 0x27, 0x97);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportServicePolicy.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_UDP_PORT_POLICY* pUdpPortPolicy) get_UdpPortPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_UDP_PORT_POLICY UdpPortPolicy) put_UdpPortPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulTftpMaximumBlockSize) get_TftpMaximumBlockSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulTftpMaximumBlockSize) put_TftpMaximumBlockSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnableTftpVariableWindowExtension) get_EnableTftpVariableWindowExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnableTftpVariableWindowExtension) put_EnableTftpVariableWindowExtension;
	}


	public HRESULT get_UdpPortPolicy(WDSTRANSPORT_UDP_PORT_POLICY* pUdpPortPolicy) mut => VT.[Friend]get_UdpPortPolicy(&this, pUdpPortPolicy);

	public HRESULT put_UdpPortPolicy(WDSTRANSPORT_UDP_PORT_POLICY UdpPortPolicy) mut => VT.[Friend]put_UdpPortPolicy(&this, UdpPortPolicy);

	public HRESULT get_TftpMaximumBlockSize(uint32* pulTftpMaximumBlockSize) mut => VT.[Friend]get_TftpMaximumBlockSize(&this, pulTftpMaximumBlockSize);

	public HRESULT put_TftpMaximumBlockSize(uint32 ulTftpMaximumBlockSize) mut => VT.[Friend]put_TftpMaximumBlockSize(&this, ulTftpMaximumBlockSize);

	public HRESULT get_EnableTftpVariableWindowExtension(int16* pbEnableTftpVariableWindowExtension) mut => VT.[Friend]get_EnableTftpVariableWindowExtension(&this, pbEnableTftpVariableWindowExtension);

	public HRESULT put_EnableTftpVariableWindowExtension(int16 bEnableTftpVariableWindowExtension) mut => VT.[Friend]put_EnableTftpVariableWindowExtension(&this, bEnableTftpVariableWindowExtension);
}

[CRepr]struct IWdsTransportDiagnosticsPolicy : IWdsTransportCacheable
{
	public new const Guid IID = .(0x13b33efc, 0x7856, 0x4f61, 0x9a, 0x59, 0x8d, 0xe6, 0x7b, 0x6b, 0x87, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportCacheable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulComponents) get_Components;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulComponents) put_Components;
	}


	public HRESULT get_Enabled(int16* pbEnabled) mut => VT.[Friend]get_Enabled(&this, pbEnabled);

	public HRESULT put_Enabled(int16 bEnabled) mut => VT.[Friend]put_Enabled(&this, bEnabled);

	public HRESULT get_Components(uint32* pulComponents) mut => VT.[Friend]get_Components(&this, pulComponents);

	public HRESULT put_Components(uint32 ulComponents) mut => VT.[Friend]put_Components(&this, ulComponents);
}

[CRepr]struct IWdsTransportMulticastSessionPolicy : IWdsTransportCacheable
{
	public new const Guid IID = .(0x4e5753cf, 0x68ec, 0x4504, 0xa9, 0x51, 0x4a, 0x00, 0x32, 0x66, 0x60, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportCacheable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_SLOW_CLIENT_HANDLING_TYPE* pSlowClientHandling) get_SlowClientHandling;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_SLOW_CLIENT_HANDLING_TYPE SlowClientHandling) put_SlowClientHandling;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulThreshold) get_AutoDisconnectThreshold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulThreshold) put_AutoDisconnectThreshold;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulStreamCount) get_MultistreamStreamCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulStreamCount) put_MultistreamStreamCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbClientFallback) get_SlowClientFallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bClientFallback) put_SlowClientFallback;
	}


	public HRESULT get_SlowClientHandling(WDSTRANSPORT_SLOW_CLIENT_HANDLING_TYPE* pSlowClientHandling) mut => VT.[Friend]get_SlowClientHandling(&this, pSlowClientHandling);

	public HRESULT put_SlowClientHandling(WDSTRANSPORT_SLOW_CLIENT_HANDLING_TYPE SlowClientHandling) mut => VT.[Friend]put_SlowClientHandling(&this, SlowClientHandling);

	public HRESULT get_AutoDisconnectThreshold(uint32* pulThreshold) mut => VT.[Friend]get_AutoDisconnectThreshold(&this, pulThreshold);

	public HRESULT put_AutoDisconnectThreshold(uint32 ulThreshold) mut => VT.[Friend]put_AutoDisconnectThreshold(&this, ulThreshold);

	public HRESULT get_MultistreamStreamCount(uint32* pulStreamCount) mut => VT.[Friend]get_MultistreamStreamCount(&this, pulStreamCount);

	public HRESULT put_MultistreamStreamCount(uint32 ulStreamCount) mut => VT.[Friend]put_MultistreamStreamCount(&this, ulStreamCount);

	public HRESULT get_SlowClientFallback(int16* pbClientFallback) mut => VT.[Friend]get_SlowClientFallback(&this, pbClientFallback);

	public HRESULT put_SlowClientFallback(int16 bClientFallback) mut => VT.[Friend]put_SlowClientFallback(&this, bClientFallback);
}

[CRepr]struct IWdsTransportNamespace : IDispatch
{
	public new const Guid IID = .(0xfa561f57, 0xfbef, 0x4ed3, 0xb0, 0x56, 0x12, 0x7c, 0xb1, 0xb3, 0x3b, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_NAMESPACE_TYPE* pType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bszName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszFriendlyName) get_FriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bszFriendlyName) put_FriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bszDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszContentProvider) get_ContentProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bszContentProvider) put_ContentProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszConfiguration) get_Configuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bszConfiguration) put_Configuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbRegistered) get_Registered;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbTombstoned) get_Tombstoned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pTombstoneTime) get_TombstoneTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbTransmissionStarted) get_TransmissionStarted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Register;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bTerminateSessions) Deregister;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportNamespace** ppWdsTransportNamespaceClone) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportCollection** ppWdsTransportContents) RetrieveContents;
	}


	public HRESULT get_Type(WDSTRANSPORT_NAMESPACE_TYPE* pType) mut => VT.[Friend]get_Type(&this, pType);

	public HRESULT get_Id(uint32* pulId) mut => VT.[Friend]get_Id(&this, pulId);

	public HRESULT get_Name(BSTR* pbszName) mut => VT.[Friend]get_Name(&this, pbszName);

	public HRESULT put_Name(BSTR bszName) mut => VT.[Friend]put_Name(&this, bszName);

	public HRESULT get_FriendlyName(BSTR* pbszFriendlyName) mut => VT.[Friend]get_FriendlyName(&this, pbszFriendlyName);

	public HRESULT put_FriendlyName(BSTR bszFriendlyName) mut => VT.[Friend]put_FriendlyName(&this, bszFriendlyName);

	public HRESULT get_Description(BSTR* pbszDescription) mut => VT.[Friend]get_Description(&this, pbszDescription);

	public HRESULT put_Description(BSTR bszDescription) mut => VT.[Friend]put_Description(&this, bszDescription);

	public HRESULT get_ContentProvider(BSTR* pbszContentProvider) mut => VT.[Friend]get_ContentProvider(&this, pbszContentProvider);

	public HRESULT put_ContentProvider(BSTR bszContentProvider) mut => VT.[Friend]put_ContentProvider(&this, bszContentProvider);

	public HRESULT get_Configuration(BSTR* pbszConfiguration) mut => VT.[Friend]get_Configuration(&this, pbszConfiguration);

	public HRESULT put_Configuration(BSTR bszConfiguration) mut => VT.[Friend]put_Configuration(&this, bszConfiguration);

	public HRESULT get_Registered(int16* pbRegistered) mut => VT.[Friend]get_Registered(&this, pbRegistered);

	public HRESULT get_Tombstoned(int16* pbTombstoned) mut => VT.[Friend]get_Tombstoned(&this, pbTombstoned);

	public HRESULT get_TombstoneTime(double* pTombstoneTime) mut => VT.[Friend]get_TombstoneTime(&this, pTombstoneTime);

	public HRESULT get_TransmissionStarted(int16* pbTransmissionStarted) mut => VT.[Friend]get_TransmissionStarted(&this, pbTransmissionStarted);

	public HRESULT Register() mut => VT.[Friend]Register(&this);

	public HRESULT Deregister(int16 bTerminateSessions) mut => VT.[Friend]Deregister(&this, bTerminateSessions);

	public HRESULT Clone(IWdsTransportNamespace** ppWdsTransportNamespaceClone) mut => VT.[Friend]Clone(&this, ppWdsTransportNamespaceClone);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT RetrieveContents(IWdsTransportCollection** ppWdsTransportContents) mut => VT.[Friend]RetrieveContents(&this, ppWdsTransportContents);
}

[CRepr]struct IWdsTransportNamespaceAutoCast : IWdsTransportNamespace
{
	public new const Guid IID = .(0xad931a72, 0xc4bd, 0x4c41, 0x8f, 0xbc, 0x59, 0xc9, 0xc7, 0x48, 0xdf, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportNamespace.VTable
	{
	}

}

[CRepr]struct IWdsTransportNamespaceScheduledCast : IWdsTransportNamespace
{
	public new const Guid IID = .(0x3840cecf, 0xd76c, 0x416e, 0xa4, 0xcc, 0x31, 0xc7, 0x41, 0xd2, 0x87, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportNamespace.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StartTransmission;
	}


	public HRESULT StartTransmission() mut => VT.[Friend]StartTransmission(&this);
}

[CRepr]struct IWdsTransportNamespaceScheduledCastManualStart : IWdsTransportNamespaceScheduledCast
{
	public new const Guid IID = .(0x013e6e4c, 0xe6a7, 0x4fb5, 0xb7, 0xff, 0xd9, 0xf5, 0xda, 0x80, 0x5c, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportNamespaceScheduledCast.VTable
	{
	}

}

[CRepr]struct IWdsTransportNamespaceScheduledCastAutoStart : IWdsTransportNamespaceScheduledCast
{
	public new const Guid IID = .(0xd606af3d, 0xea9c, 0x4219, 0x96, 0x1e, 0x74, 0x91, 0xd6, 0x18, 0xd9, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWdsTransportNamespaceScheduledCast.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulMinimumClients) get_MinimumClients;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulMinimumClients) put_MinimumClients;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pStartTime) get_StartTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double StartTime) put_StartTime;
	}


	public HRESULT get_MinimumClients(uint32* pulMinimumClients) mut => VT.[Friend]get_MinimumClients(&this, pulMinimumClients);

	public HRESULT put_MinimumClients(uint32 ulMinimumClients) mut => VT.[Friend]put_MinimumClients(&this, ulMinimumClients);

	public HRESULT get_StartTime(double* pStartTime) mut => VT.[Friend]get_StartTime(&this, pStartTime);

	public HRESULT put_StartTime(double StartTime) mut => VT.[Friend]put_StartTime(&this, StartTime);
}

[CRepr]struct IWdsTransportContent : IDispatch
{
	public new const Guid IID = .(0xd405d711, 0x0296, 0x4ab4, 0xa8, 0x60, 0xac, 0x7d, 0x32, 0xe6, 0x57, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportNamespace** ppWdsTransportNamespace) get_Namespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportCollection** ppWdsTransportSessions) RetrieveSessions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Terminate;
	}


	public HRESULT get_Namespace(IWdsTransportNamespace** ppWdsTransportNamespace) mut => VT.[Friend]get_Namespace(&this, ppWdsTransportNamespace);

	public HRESULT get_Id(uint32* pulId) mut => VT.[Friend]get_Id(&this, pulId);

	public HRESULT get_Name(BSTR* pbszName) mut => VT.[Friend]get_Name(&this, pbszName);

	public HRESULT RetrieveSessions(IWdsTransportCollection** ppWdsTransportSessions) mut => VT.[Friend]RetrieveSessions(&this, ppWdsTransportSessions);

	public HRESULT Terminate() mut => VT.[Friend]Terminate(&this);
}

[CRepr]struct IWdsTransportSession : IDispatch
{
	public new const Guid IID = .(0xf4efea88, 0x65b1, 0x4f30, 0xa4, 0xb9, 0x27, 0x93, 0x98, 0x77, 0x96, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportContent** ppWdsTransportContent) get_Content;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszNetworkInterfaceName) get_NetworkInterfaceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszNetworkInterfaceAddress) get_NetworkInterfaceAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulTransferRate) get_TransferRate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulMasterClientId) get_MasterClientId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportCollection** ppWdsTransportClients) RetrieveClients;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Terminate;
	}


	public HRESULT get_Content(IWdsTransportContent** ppWdsTransportContent) mut => VT.[Friend]get_Content(&this, ppWdsTransportContent);

	public HRESULT get_Id(uint32* pulId) mut => VT.[Friend]get_Id(&this, pulId);

	public HRESULT get_NetworkInterfaceName(BSTR* pbszNetworkInterfaceName) mut => VT.[Friend]get_NetworkInterfaceName(&this, pbszNetworkInterfaceName);

	public HRESULT get_NetworkInterfaceAddress(BSTR* pbszNetworkInterfaceAddress) mut => VT.[Friend]get_NetworkInterfaceAddress(&this, pbszNetworkInterfaceAddress);

	public HRESULT get_TransferRate(uint32* pulTransferRate) mut => VT.[Friend]get_TransferRate(&this, pulTransferRate);

	public HRESULT get_MasterClientId(uint32* pulMasterClientId) mut => VT.[Friend]get_MasterClientId(&this, pulMasterClientId);

	public HRESULT RetrieveClients(IWdsTransportCollection** ppWdsTransportClients) mut => VT.[Friend]RetrieveClients(&this, ppWdsTransportClients);

	public HRESULT Terminate() mut => VT.[Friend]Terminate(&this);
}

[CRepr]struct IWdsTransportClient : IDispatch
{
	public new const Guid IID = .(0xb5dbc93a, 0xcabe, 0x46ca, 0x83, 0x7f, 0x3e, 0x44, 0xe9, 0x3c, 0x65, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWdsTransportSession** ppWdsTransportSession) get_Session;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszMacAddress) get_MacAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszIpAddress) get_IpAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulPercentCompletion) get_PercentCompletion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulJoinDuration) get_JoinDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulCpuUtilization) get_CpuUtilization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulMemoryUtilization) get_MemoryUtilization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulNetworkUtilization) get_NetworkUtilization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszUserIdentity) get_UserIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WDSTRANSPORT_DISCONNECT_TYPE DisconnectionType) Disconnect;
	}


	public HRESULT get_Session(IWdsTransportSession** ppWdsTransportSession) mut => VT.[Friend]get_Session(&this, ppWdsTransportSession);

	public HRESULT get_Id(uint32* pulId) mut => VT.[Friend]get_Id(&this, pulId);

	public HRESULT get_Name(BSTR* pbszName) mut => VT.[Friend]get_Name(&this, pbszName);

	public HRESULT get_MacAddress(BSTR* pbszMacAddress) mut => VT.[Friend]get_MacAddress(&this, pbszMacAddress);

	public HRESULT get_IpAddress(BSTR* pbszIpAddress) mut => VT.[Friend]get_IpAddress(&this, pbszIpAddress);

	public HRESULT get_PercentCompletion(uint32* pulPercentCompletion) mut => VT.[Friend]get_PercentCompletion(&this, pulPercentCompletion);

	public HRESULT get_JoinDuration(uint32* pulJoinDuration) mut => VT.[Friend]get_JoinDuration(&this, pulJoinDuration);

	public HRESULT get_CpuUtilization(uint32* pulCpuUtilization) mut => VT.[Friend]get_CpuUtilization(&this, pulCpuUtilization);

	public HRESULT get_MemoryUtilization(uint32* pulMemoryUtilization) mut => VT.[Friend]get_MemoryUtilization(&this, pulMemoryUtilization);

	public HRESULT get_NetworkUtilization(uint32* pulNetworkUtilization) mut => VT.[Friend]get_NetworkUtilization(&this, pulNetworkUtilization);

	public HRESULT get_UserIdentity(BSTR* pbszUserIdentity) mut => VT.[Friend]get_UserIdentity(&this, pbszUserIdentity);

	public HRESULT Disconnect(WDSTRANSPORT_DISCONNECT_TYPE DisconnectionType) mut => VT.[Friend]Disconnect(&this, DisconnectionType);
}

[CRepr]struct IWdsTransportTftpClient : IDispatch
{
	public new const Guid IID = .(0xb022d3ae, 0x884d, 0x4d85, 0xb1, 0x46, 0x53, 0x32, 0x0e, 0x76, 0xef, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszFileName) get_FileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszIpAddress) get_IpAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulTimeout) get_Timeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pul64CurrentOffset) get_CurrentFileOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pul64FileSize) get_FileSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulBlockSize) get_BlockSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulWindowSize) get_WindowSize;
	}


	public HRESULT get_FileName(BSTR* pbszFileName) mut => VT.[Friend]get_FileName(&this, pbszFileName);

	public HRESULT get_IpAddress(BSTR* pbszIpAddress) mut => VT.[Friend]get_IpAddress(&this, pbszIpAddress);

	public HRESULT get_Timeout(uint32* pulTimeout) mut => VT.[Friend]get_Timeout(&this, pulTimeout);

	public HRESULT get_CurrentFileOffset(uint64* pul64CurrentOffset) mut => VT.[Friend]get_CurrentFileOffset(&this, pul64CurrentOffset);

	public HRESULT get_FileSize(uint64* pul64FileSize) mut => VT.[Friend]get_FileSize(&this, pul64FileSize);

	public HRESULT get_BlockSize(uint32* pulBlockSize) mut => VT.[Friend]get_BlockSize(&this, pulBlockSize);

	public HRESULT get_WindowSize(uint32* pulWindowSize) mut => VT.[Friend]get_WindowSize(&this, pulWindowSize);
}

[CRepr]struct IWdsTransportContentProvider : IDispatch
{
	public new const Guid IID = .(0xb9489f24, 0xf219, 0x4acf, 0xaa, 0xd7, 0x26, 0x5c, 0x7c, 0x08, 0xa6, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszFilePath) get_FilePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbszInitializationRoutine) get_InitializationRoutine;
	}


	public HRESULT get_Name(BSTR* pbszName) mut => VT.[Friend]get_Name(&this, pbszName);

	public HRESULT get_Description(BSTR* pbszDescription) mut => VT.[Friend]get_Description(&this, pbszDescription);

	public HRESULT get_FilePath(BSTR* pbszFilePath) mut => VT.[Friend]get_FilePath(&this, pbszFilePath);

	public HRESULT get_InitializationRoutine(BSTR* pbszInitializationRoutine) mut => VT.[Friend]get_InitializationRoutine(&this, pbszInitializationRoutine);
}

#endregion

#region Functions
public static
{
	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliClose(HANDLE Handle);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliRegisterTrace(PFN_WdsCliTraceFunction pfn);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliFreeStringArray(PWSTR* ppwszArray, uint32 ulCount);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliFindFirstImage(HANDLE hSession, HANDLE* phFindHandle);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliFindNextImage(HANDLE Handle);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetEnumerationFlags(HANDLE Handle, uint32* pdwFlags);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageHandleFromFindHandle(HANDLE FindHandle, HANDLE* phImageHandle);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageHandleFromTransferHandle(HANDLE hTransfer, HANDLE* phImageHandle);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliCreateSession(PWSTR pwszServer, WDS_CLI_CRED* pCred, HANDLE* phSession);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliAuthorizeSession(HANDLE hSession, WDS_CLI_CRED* pCred);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliInitializeLog(HANDLE hSession, CPU_ARCHITECTURE ulClientArchitecture, PWSTR pwszClientId, PWSTR pwszClientAddress);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliLog(HANDLE hSession, uint32 ulLogLevel, uint32 ulMessageCode);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageName(HANDLE hIfh, PWSTR* ppwszValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageDescription(HANDLE hIfh, PWSTR* ppwszValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageType(HANDLE hIfh, WDS_CLI_IMAGE_TYPE* pImageType);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageFiles(HANDLE hIfh, PWSTR** pppwszFiles, uint32* pdwCount);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageLanguage(HANDLE hIfh, PWSTR* ppwszValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageLanguages(HANDLE hIfh, int8*** pppszValues, uint32* pdwNumValues);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageVersion(HANDLE hIfh, PWSTR* ppwszValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImagePath(HANDLE hIfh, PWSTR* ppwszValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageIndex(HANDLE hIfh, uint32* pdwValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageArchitecture(HANDLE hIfh, CPU_ARCHITECTURE* pdwValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageLastModifiedTime(HANDLE hIfh, SYSTEMTIME** ppSysTimeValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageSize(HANDLE hIfh, uint64* pullValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageHalName(HANDLE hIfh, PWSTR* ppwszValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageGroup(HANDLE hIfh, PWSTR* ppwszValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageNamespace(HANDLE hIfh, PWSTR* ppwszValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetImageParameter(HANDLE hIfh, WDS_CLI_IMAGE_PARAM_TYPE ParamType, void* pResponse, uint32 uResponseLen);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetTransferSize(HANDLE hIfh, uint64* pullValue);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WdsCliSetTransferBufferSize(uint32 ulSizeInBytes);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliTransferImage(HANDLE hImage, PWSTR pwszLocalPath, uint32 dwFlags, uint32 dwReserved, PFN_WdsCliCallback pfnWdsCliCallback, void* pvUserData, HANDLE* phTransfer);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliTransferFile(PWSTR pwszServer, PWSTR pwszNamespace, PWSTR pwszRemoteFilePath, PWSTR pwszLocalFilePath, uint32 dwFlags, uint32 dwReserved, PFN_WdsCliCallback pfnWdsCliCallback, void* pvUserData, HANDLE* phTransfer);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliCancelTransfer(HANDLE hTransfer);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliWaitForTransfer(HANDLE hTransfer);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliObtainDriverPackages(HANDLE hImage, PWSTR* ppwszServerName, PWSTR** pppwszDriverPackages, uint32* pulCount);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliObtainDriverPackagesEx(HANDLE hSession, PWSTR pwszMachineInfo, PWSTR* ppwszServerName, PWSTR** pppwszDriverPackages, uint32* pulCount);

	[Import("WDSCLIENTAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsCliGetDriverQueryXml(PWSTR pwszWinDirPath, PWSTR* ppwszDriverQuery);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeProviderRegister(PWSTR pszProviderName, PWSTR pszModulePath, uint32 Index, BOOL bIsCritical, HKEY* phProviderKey);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeProviderUnRegister(PWSTR pszProviderName);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeProviderQueryIndex(PWSTR pszProviderName, uint32* puIndex);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeProviderEnumFirst(HANDLE* phEnum);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeProviderEnumNext(HANDLE hEnum, PXE_PROVIDER** ppProvider);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeProviderEnumClose(HANDLE hEnum);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeProviderFreeInfo(PXE_PROVIDER* pProvider);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeRegisterCallback(HANDLE hProvider, uint32 CallbackType, void* pCallbackFunction, void* pContext);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeSendReply(HANDLE hClientRequest, void* pPacket, uint32 uPacketLen, PXE_ADDRESS* pAddress);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeAsyncRecvDone(HANDLE hClientRequest, uint32 Action);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeTrace(HANDLE hProvider, uint32 Severity, PWSTR pszFormat);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeTraceV(HANDLE hProvider, uint32 Severity, PWSTR pszFormat, int8* Params);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* PxePacketAllocate(HANDLE hProvider, HANDLE hClientRequest, uint32 uSize);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxePacketFree(HANDLE hProvider, HANDLE hClientRequest, void* pPacket);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeProviderSetAttribute(HANDLE hProvider, uint32 Attribute, void* pParameterBuffer, uint32 uParamLen);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpInitialize(void* pRecvPacket, uint32 uRecvPacketLen, void* pReplyPacket, uint32 uMaxReplyPacketLen, uint32* puReplyPacketLen);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpv6Initialize(void* pRequest, uint32 cbRequest, void* pReply, uint32 cbReply, uint32* pcbReplyUsed);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpAppendOption(void* pReplyPacket, uint32 uMaxReplyPacketLen, uint32* puReplyPacketLen, uint8 bOption, uint8 bOptionLen, void* pValue);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpv6AppendOption(void* pReply, uint32 cbReply, uint32* pcbReplyUsed, uint16 wOptionType, uint16 cbOption, void* pOption);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpAppendOptionRaw(void* pReplyPacket, uint32 uMaxReplyPacketLen, uint32* puReplyPacketLen, uint16 uBufferLen, void* pBuffer);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpv6AppendOptionRaw(void* pReply, uint32 cbReply, uint32* pcbReplyUsed, uint16 cbBuffer, void* pBuffer);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpIsValid(void* pPacket, uint32 uPacketLen, BOOL bRequestPacket, BOOL* pbPxeOptionPresent);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpv6IsValid(void* pPacket, uint32 uPacketLen, BOOL bRequestPacket, BOOL* pbPxeOptionPresent);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpGetOptionValue(void* pPacket, uint32 uPacketLen, uint32 uInstance, uint8 bOption, uint8* pbOptionLen, void** ppOptionValue);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpv6GetOptionValue(void* pPacket, uint32 uPacketLen, uint32 uInstance, uint16 wOption, uint16* pwOptionLen, void** ppOptionValue);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpGetVendorOptionValue(void* pPacket, uint32 uPacketLen, uint8 bOption, uint32 uInstance, uint8* pbOptionLen, void** ppOptionValue);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpv6GetVendorOptionValue(void* pPacket, uint32 uPacketLen, uint32 dwEnterpriseNumber, uint16 wOption, uint32 uInstance, uint16* pwOptionLen, void** ppOptionValue);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpv6ParseRelayForw(void* pRelayForwPacket, uint32 uRelayForwPacketLen, PXE_DHCPV6_NESTED_RELAY_MESSAGE* pRelayMessages, uint32 nRelayMessages, uint32* pnRelayMessages, uint8** ppInnerPacket, uint32* pcbInnerPacket);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeDhcpv6CreateRelayRepl(PXE_DHCPV6_NESTED_RELAY_MESSAGE* pRelayMessages, uint32 nRelayMessages, uint8* pInnerPacket, uint32 cbInnerPacket, void* pReplyBuffer, uint32 cbReplyBuffer, uint32* pcbReplyBuffer);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeGetServerInfo(uint32 uInfoType, void* pBuffer, uint32 uBufferLen);

	[Import("WDSPXE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PxeGetServerInfoEx(uint32 uInfoType, void* pBuffer, uint32 uBufferLen, uint32* puBufferUsed);

	[Import("WDSMC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsTransportServerRegisterCallback(HANDLE hProvider, TRANSPORTPROVIDER_CALLBACK_ID CallbackId, void* pfnCallback);

	[Import("WDSMC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsTransportServerCompleteRead(HANDLE hProvider, uint32 ulBytesRead, void* pvUserData, HRESULT hReadResult);

	[Import("WDSMC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsTransportServerTrace(HANDLE hProvider, uint32 Severity, PWSTR pwszFormat);

	[Import("WDSMC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsTransportServerTraceV(HANDLE hProvider, uint32 Severity, PWSTR pwszFormat, int8* Params);

	[Import("WDSMC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* WdsTransportServerAllocateBuffer(HANDLE hProvider, uint32 ulBufferSize);

	[Import("WDSMC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WdsTransportServerFreeBuffer(HANDLE hProvider, void* pvBuffer);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientInitialize();

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientInitializeSession(WDS_TRANSPORTCLIENT_REQUEST* pSessionRequest, void* pCallerData, HANDLE* hSessionKey);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientRegisterCallback(HANDLE hSessionKey, TRANSPORTCLIENT_CALLBACK_ID CallbackId, void* pfnCallback);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientStartSession(HANDLE hSessionKey);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientCompleteReceive(HANDLE hSessionKey, uint32 ulSize, ULARGE_INTEGER* pullOffset);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientCancelSession(HANDLE hSessionKey);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientCancelSessionEx(HANDLE hSessionKey, uint32 dwErrorCode);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientWaitForCompletion(HANDLE hSessionKey, uint32 uTimeout);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientQueryStatus(HANDLE hSessionKey, uint32* puStatus, uint32* puErrorCode);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientCloseSession(HANDLE hSessionKey);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientAddRefBuffer(void* pvBuffer);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientReleaseBuffer(void* pvBuffer);

	[Import("WDSTPTC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsTransportClientShutdown();

	[Import("WDSBP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsBpParseInitialize(void* pPacket, uint32 uPacketLen, uint8* pbPacketType, HANDLE* phHandle);

	[Import("WDSBP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsBpParseInitializev6(void* pPacket, uint32 uPacketLen, uint8* pbPacketType, HANDLE* phHandle);

	[Import("WDSBP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsBpInitialize(uint8 bPacketType, HANDLE* phHandle);

	[Import("WDSBP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsBpCloseHandle(HANDLE hHandle);

	[Import("WDSBP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsBpQueryOption(HANDLE hHandle, uint32 uOption, uint32 uValueLen, void* pValue, uint32* puBytes);

	[Import("WDSBP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsBpAddOption(HANDLE hHandle, uint32 uOption, uint32 uValueLen, void* pValue);

	[Import("WDSBP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WdsBpGetOptionBuffer(HANDLE hHandle, uint32 uBufferLen, void* pBuffer, uint32* puBytes);

}
#endregion
