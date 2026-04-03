using Win32.System.Com;
using Win32.Foundation;
using Win32.System.IO;
using Win32.Security.Cryptography;
using System;

namespace Win32.System.Rpc;

#region Constants
public static
{
	public const uint32 RPC_C_BINDING_INFINITE_TIMEOUT = 10;
	public const uint32 RPC_C_BINDING_MIN_TIMEOUT = 0;
	public const uint32 RPC_C_BINDING_DEFAULT_TIMEOUT = 5;
	public const uint32 RPC_C_BINDING_MAX_TIMEOUT = 9;
	public const int32 RPC_C_CANCEL_INFINITE_TIMEOUT = -1;
	public const uint32 RPC_C_LISTEN_MAX_CALLS_DEFAULT = 1234;
	public const uint32 RPC_C_PROTSEQ_MAX_REQS_DEFAULT = 10;
	public const uint32 RPC_C_BIND_TO_ALL_NICS = 1;
	public const uint32 RPC_C_USE_INTERNET_PORT = 1;
	public const uint32 RPC_C_USE_INTRANET_PORT = 2;
	public const uint32 RPC_C_DONT_FAIL = 4;
	public const uint32 RPC_C_RPCHTTP_USE_LOAD_BALANCE = 8;
	public const uint32 RPC_C_TRY_ENFORCE_MAX_CALLS = 16;
	public const uint32 RPC_C_MQ_TEMPORARY = 0;
	public const uint32 RPC_C_MQ_PERMANENT = 1;
	public const uint32 RPC_C_MQ_CLEAR_ON_OPEN = 2;
	public const uint32 RPC_C_MQ_USE_EXISTING_SECURITY = 4;
	public const uint32 RPC_C_MQ_AUTHN_LEVEL_NONE = 0;
	public const uint32 RPC_C_MQ_AUTHN_LEVEL_PKT_INTEGRITY = 8;
	public const uint32 RPC_C_MQ_AUTHN_LEVEL_PKT_PRIVACY = 16;
	public const uint32 RPC_C_MQ_EXPRESS = 0;
	public const uint32 RPC_C_MQ_RECOVERABLE = 1;
	public const uint32 RPC_C_MQ_JOURNAL_NONE = 0;
	public const uint32 RPC_C_MQ_JOURNAL_DEADLETTER = 1;
	public const uint32 RPC_C_MQ_JOURNAL_ALWAYS = 2;
	public const uint32 RPC_C_OPT_MQ_DELIVERY = 1;
	public const uint32 RPC_C_OPT_MQ_PRIORITY = 2;
	public const uint32 RPC_C_OPT_MQ_JOURNAL = 3;
	public const uint32 RPC_C_OPT_MQ_ACKNOWLEDGE = 4;
	public const uint32 RPC_C_OPT_MQ_AUTHN_SERVICE = 5;
	public const uint32 RPC_C_OPT_MQ_AUTHN_LEVEL = 6;
	public const uint32 RPC_C_OPT_MQ_TIME_TO_REACH_QUEUE = 7;
	public const uint32 RPC_C_OPT_MQ_TIME_TO_BE_RECEIVED = 8;
	public const uint32 RPC_C_OPT_BINDING_NONCAUSAL = 9;
	public const uint32 RPC_C_OPT_SECURITY_CALLBACK = 10;
	public const uint32 RPC_C_OPT_UNIQUE_BINDING = 11;
	public const uint32 RPC_C_OPT_MAX_OPTIONS = 12;
	public const uint32 RPC_C_OPT_CALL_TIMEOUT = 12;
	public const uint32 RPC_C_OPT_DONT_LINGER = 13;
	public const uint32 RPC_C_OPT_TRANS_SEND_BUFFER_SIZE = 5;
	public const uint32 RPC_C_OPT_TRUST_PEER = 14;
	public const uint32 RPC_C_OPT_ASYNC_BLOCK = 15;
	public const uint32 RPC_C_OPT_OPTIMIZE_TIME = 16;
	public const uint32 RPC_C_FULL_CERT_CHAIN = 1;
	public const uint32 RPC_C_STATS_CALLS_IN = 0;
	public const uint32 RPC_C_STATS_CALLS_OUT = 1;
	public const uint32 RPC_C_STATS_PKTS_IN = 2;
	public const uint32 RPC_C_STATS_PKTS_OUT = 3;
	public const uint32 RPC_C_AUTHN_NONE = 0;
	public const uint32 RPC_C_AUTHN_DCE_PRIVATE = 1;
	public const uint32 RPC_C_AUTHN_DCE_PUBLIC = 2;
	public const uint32 RPC_C_AUTHN_DEC_PUBLIC = 4;
	public const uint32 RPC_C_AUTHN_GSS_NEGOTIATE = 9;
	public const uint32 RPC_C_AUTHN_WINNT = 10;
	public const uint32 RPC_C_AUTHN_GSS_SCHANNEL = 14;
	public const uint32 RPC_C_AUTHN_GSS_KERBEROS = 16;
	public const uint32 RPC_C_AUTHN_DPA = 17;
	public const uint32 RPC_C_AUTHN_MSN = 18;
	public const uint32 RPC_C_AUTHN_DIGEST = 21;
	public const uint32 RPC_C_AUTHN_KERNEL = 20;
	public const uint32 RPC_C_AUTHN_NEGO_EXTENDER = 30;
	public const uint32 RPC_C_AUTHN_PKU2U = 31;
	public const uint32 RPC_C_AUTHN_LIVE_SSP = 32;
	public const uint32 RPC_C_AUTHN_LIVEXP_SSP = 35;
	public const uint32 RPC_C_AUTHN_CLOUD_AP = 36;
	public const uint32 RPC_C_AUTHN_MSONLINE = 82;
	public const uint32 RPC_C_AUTHN_MQ = 100;
	public const int32 RPC_C_AUTHN_DEFAULT = -1;
	public const int32 RPC_C_SECURITY_QOS_VERSION = 1;
	public const int32 RPC_C_SECURITY_QOS_VERSION_1 = 1;
	public const int32 RPC_C_SECURITY_QOS_VERSION_2 = 2;
	public const uint32 RPC_C_HTTP_AUTHN_SCHEME_BASIC = 1;
	public const uint32 RPC_C_HTTP_AUTHN_SCHEME_NTLM = 2;
	public const uint32 RPC_C_HTTP_AUTHN_SCHEME_PASSPORT = 4;
	public const uint32 RPC_C_HTTP_AUTHN_SCHEME_DIGEST = 8;
	public const uint32 RPC_C_HTTP_AUTHN_SCHEME_NEGOTIATE = 16;
	public const uint32 RPC_C_HTTP_AUTHN_SCHEME_CERT = 65536;
	public const int32 RPC_C_SECURITY_QOS_VERSION_3 = 3;
	public const int32 RPC_C_SECURITY_QOS_VERSION_4 = 4;
	public const int32 RPC_C_SECURITY_QOS_VERSION_5 = 5;
	public const uint32 RPC_PROTSEQ_TCP = 1;
	public const uint32 RPC_PROTSEQ_NMP = 2;
	public const uint32 RPC_PROTSEQ_LRPC = 3;
	public const uint32 RPC_PROTSEQ_HTTP = 4;
	public const uint32 RPC_BHT_OBJECT_UUID_VALID = 1;
	public const uint32 RPC_BHO_EXCLUSIVE_AND_GUARANTEED = 4;
	public const uint32 RPC_C_AUTHZ_NONE = 0;
	public const uint32 RPC_C_AUTHZ_NAME = 1;
	public const uint32 RPC_C_AUTHZ_DCE = 2;
	public const uint32 RPC_C_AUTHZ_DEFAULT = 4294967295;
	public const uint32 DCE_C_ERROR_STRING_LEN = 256;
	public const uint32 RPC_C_EP_ALL_ELTS = 0;
	public const uint32 RPC_C_EP_MATCH_BY_IF = 1;
	public const uint32 RPC_C_EP_MATCH_BY_OBJ = 2;
	public const uint32 RPC_C_EP_MATCH_BY_BOTH = 3;
	public const uint32 RPC_C_VERS_ALL = 1;
	public const uint32 RPC_C_VERS_COMPATIBLE = 2;
	public const uint32 RPC_C_VERS_EXACT = 3;
	public const uint32 RPC_C_VERS_MAJOR_ONLY = 4;
	public const uint32 RPC_C_VERS_UPTO = 5;
	public const uint32 RPC_C_MGMT_INQ_IF_IDS = 0;
	public const uint32 RPC_C_MGMT_INQ_PRINC_NAME = 1;
	public const uint32 RPC_C_MGMT_INQ_STATS = 2;
	public const uint32 RPC_C_MGMT_IS_SERVER_LISTEN = 3;
	public const uint32 RPC_C_MGMT_STOP_SERVER_LISTEN = 4;
	public const uint32 RPC_C_PARM_MAX_PACKET_LENGTH = 1;
	public const uint32 RPC_C_PARM_BUFFER_LENGTH = 2;
	public const uint32 RPC_IF_AUTOLISTEN = 1;
	public const uint32 RPC_IF_OLE = 2;
	public const uint32 RPC_IF_ALLOW_UNKNOWN_AUTHORITY = 4;
	public const uint32 RPC_IF_ALLOW_SECURE_ONLY = 8;
	public const uint32 RPC_IF_ALLOW_CALLBACKS_WITH_NO_AUTH = 16;
	public const uint32 RPC_IF_ALLOW_LOCAL_ONLY = 32;
	public const uint32 RPC_IF_SEC_NO_CACHE = 64;
	public const uint32 RPC_IF_SEC_CACHE_PER_PROC = 128;
	public const uint32 RPC_IF_ASYNC_CALLBACK = 256;
	public const uint32 RPC_FW_IF_FLAG_DCOM = 1;
	public const uint32 RPC_C_NOTIFY_ON_SEND_COMPLETE = 1;
	public const uint32 MaxNumberOfEEInfoParams = 4;
	public const uint32 RPC_EEINFO_VERSION = 1;
	public const uint32 EEInfoPreviousRecordsMissing = 1;
	public const uint32 EEInfoNextRecordsMissing = 2;
	public const uint32 EEInfoUseFileTime = 4;
	public const uint32 EEInfoGCCOM = 11;
	public const uint32 EEInfoGCFRS = 12;
	public const uint32 RPC_CALL_ATTRIBUTES_VERSION = 2;
	public const uint32 RPC_QUERY_SERVER_PRINCIPAL_NAME = 2;
	public const uint32 RPC_QUERY_CLIENT_PRINCIPAL_NAME = 4;
	public const uint32 RPC_QUERY_CALL_LOCAL_ADDRESS = 8;
	public const uint32 RPC_QUERY_CLIENT_PID = 16;
	public const uint32 RPC_QUERY_IS_CLIENT_LOCAL = 32;
	public const uint32 RPC_QUERY_NO_AUTH_REQUIRED = 64;
	public const uint32 RPC_QUERY_CLIENT_ID = 128;
	public const uint32 RPC_CALL_STATUS_CANCELLED = 1;
	public const uint32 RPC_CALL_STATUS_DISCONNECTED = 2;
	public const uint32 RPC_CONTEXT_HANDLE_DEFAULT_FLAGS = 0;
	public const uint32 RPC_CONTEXT_HANDLE_FLAGS = 805306368;
	public const uint32 RPC_CONTEXT_HANDLE_SERIALIZE = 268435456;
	public const uint32 RPC_CONTEXT_HANDLE_DONT_SERIALIZE = 536870912;
	public const uint32 RPC_TYPE_STRICT_CONTEXT_HANDLE = 1073741824;
	public const uint32 RPC_TYPE_DISCONNECT_EVENT_CONTEXT_HANDLE = 2147483648;
	public const uint32 RPC_NCA_FLAGS_DEFAULT = 0;
	public const uint32 RPC_NCA_FLAGS_IDEMPOTENT = 1;
	public const uint32 RPC_NCA_FLAGS_BROADCAST = 2;
	public const uint32 RPC_NCA_FLAGS_MAYBE = 4;
	public const uint32 RPCFLG_HAS_GUARANTEE = 16;
	public const uint32 RPCFLG_WINRT_REMOTE_ASYNC = 32;
	public const uint32 RPC_BUFFER_COMPLETE = 4096;
	public const uint32 RPC_BUFFER_PARTIAL = 8192;
	public const uint32 RPC_BUFFER_EXTRA = 16384;
	public const uint32 RPC_BUFFER_ASYNC = 32768;
	public const uint32 RPC_BUFFER_NONOTIFY = 65536;
	public const uint32 RPCFLG_MESSAGE = 16777216;
	public const uint32 RPCFLG_AUTO_COMPLETE = 134217728;
	public const uint32 RPCFLG_LOCAL_CALL = 268435456;
	public const uint32 RPCFLG_INPUT_SYNCHRONOUS = 536870912;
	public const uint32 RPCFLG_ASYNCHRONOUS = 1073741824;
	public const uint32 RPCFLG_NON_NDR = 2147483648;
	public const uint32 RPCFLG_HAS_MULTI_SYNTAXES = 33554432;
	public const uint32 RPCFLG_HAS_CALLBACK = 67108864;
	public const uint32 RPCFLG_ACCESSIBILITY_BIT1 = 1048576;
	public const uint32 RPCFLG_ACCESSIBILITY_BIT2 = 2097152;
	public const uint32 RPCFLG_ACCESS_LOCAL = 4194304;
	public const uint32 NDR_CUSTOM_OR_DEFAULT_ALLOCATOR = 268435456;
	public const uint32 NDR_DEFAULT_ALLOCATOR = 536870912;
	public const uint32 RPCFLG_NDR64_CONTAINS_ARM_LAYOUT = 67108864;
	public const uint32 RPCFLG_SENDER_WAITING_FOR_REPLY = 8388608;
	public const uint32 RPC_FLAGS_VALID_BIT = 32768;
	public const uint32 NT351_INTERFACE_SIZE = 64;
	public const uint32 RPC_INTERFACE_HAS_PIPES = 1;
	public const uint32 RPC_SYSTEM_HANDLE_FREE_UNRETRIEVED = 1;
	public const uint32 RPC_SYSTEM_HANDLE_FREE_RETRIEVED = 2;
	public const uint32 RPC_SYSTEM_HANDLE_FREE_ALL = 3;
	public const uint32 RPC_SYSTEM_HANDLE_FREE_ERROR_ON_CLOSE = 4;
	public const uint32 TRANSPORT_TYPE_CN = 1;
	public const uint32 TRANSPORT_TYPE_DG = 2;
	public const uint32 TRANSPORT_TYPE_LPC = 4;
	public const uint32 TRANSPORT_TYPE_WMSG = 8;
	public const uint32 RPC_P_ADDR_FORMAT_TCP_IPV4 = 1;
	public const uint32 RPC_P_ADDR_FORMAT_TCP_IPV6 = 2;
	public const uint32 RPC_C_OPT_SESSION_ID = 6;
	public const uint32 RPC_C_OPT_COOKIE_AUTH = 7;
	public const uint32 RPC_C_OPT_RESOURCE_TYPE_UUID = 8;
	public const uint32 RPC_PROXY_CONNECTION_TYPE_IN_PROXY = 0;
	public const uint32 RPC_PROXY_CONNECTION_TYPE_OUT_PROXY = 1;
	public const uint32 RPC_C_OPT_PRIVATE_SUPPRESS_WAKE = 1;
	public const uint32 RPC_C_OPT_PRIVATE_DO_NOT_DISTURB = 2;
	public const uint32 RPC_C_OPT_PRIVATE_BREAK_ON_SUSPEND = 3;
	public const uint32 RPC_C_PROFILE_DEFAULT_ELT = 0;
	public const uint32 RPC_C_PROFILE_ALL_ELT = 1;
	public const uint32 RPC_C_PROFILE_ALL_ELTS = 1;
	public const uint32 RPC_C_PROFILE_MATCH_BY_IF = 2;
	public const uint32 RPC_C_PROFILE_MATCH_BY_MBR = 3;
	public const uint32 RPC_C_PROFILE_MATCH_BY_BOTH = 4;
	public const int32 RPC_C_NS_DEFAULT_EXP_AGE = -1;
	public const uint32 TARGET_IS_NT100_OR_LATER = 1;
	public const uint32 TARGET_IS_NT63_OR_LATER = 1;
	public const uint32 TARGET_IS_NT62_OR_LATER = 1;
	public const uint32 TARGET_IS_NT61_OR_LATER = 1;
	public const uint32 TARGET_IS_NT60_OR_LATER = 1;
	public const uint32 TARGET_IS_NT51_OR_LATER = 1;
	public const uint32 TARGET_IS_NT50_OR_LATER = 1;
	public const uint32 TARGET_IS_NT40_OR_LATER = 1;
	public const uint32 TARGET_IS_NT351_OR_WIN95_OR_LATER = 1;
	public const uint32 cbNDRContext = 20;
	public const uint32 USER_CALL_IS_ASYNC = 256;
	public const uint32 USER_CALL_NEW_CORRELATION_DESC = 512;
	public const int32 MIDL_WINRT_TYPE_SERIALIZATION_INFO_CURRENT_VERSION = 1;
	public const uint32 USER_MARSHAL_FC_BYTE = 1;
	public const uint32 USER_MARSHAL_FC_CHAR = 2;
	public const uint32 USER_MARSHAL_FC_SMALL = 3;
	public const uint32 USER_MARSHAL_FC_USMALL = 4;
	public const uint32 USER_MARSHAL_FC_WCHAR = 5;
	public const uint32 USER_MARSHAL_FC_SHORT = 6;
	public const uint32 USER_MARSHAL_FC_USHORT = 7;
	public const uint32 USER_MARSHAL_FC_LONG = 8;
	public const uint32 USER_MARSHAL_FC_ULONG = 9;
	public const uint32 USER_MARSHAL_FC_FLOAT = 10;
	public const uint32 USER_MARSHAL_FC_HYPER = 11;
	public const uint32 USER_MARSHAL_FC_DOUBLE = 12;
	public const uint32 INVALID_FRAGMENT_ID = 0;
	public const uint32 NDR64_FC_EXPLICIT_HANDLE = 0;
	public const uint32 NDR64_FC_BIND_GENERIC = 1;
	public const uint32 NDR64_FC_BIND_PRIMITIVE = 2;
	public const uint32 NDR64_FC_AUTO_HANDLE = 3;
	public const uint32 NDR64_FC_CALLBACK_HANDLE = 4;
	public const uint32 NDR64_FC_NO_HANDLE = 5;
	public const uint32 __RPCPROXY_H_VERSION__ = 475;
	public const int32 MidlInterceptionInfoVersionOne = 1;
	public const int32 MidlWinrtTypeSerializationInfoVersionOne = 1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum RPC_C_QOS_CAPABILITIES : uint32
{
	RPC_C_QOS_CAPABILITIES_DEFAULT = 0,
	RPC_C_QOS_CAPABILITIES_MUTUAL_AUTH = 1,
	RPC_C_QOS_CAPABILITIES_MAKE_FULLSIC = 2,
	RPC_C_QOS_CAPABILITIES_ANY_AUTHORITY = 4,
	RPC_C_QOS_CAPABILITIES_IGNORE_DELEGATE_FAILURE = 8,
	RPC_C_QOS_CAPABILITIES_LOCAL_MA_HINT = 16,
	RPC_C_QOS_CAPABILITIES_SCHANNEL_FULL_AUTH_IDENTITY = 32,
}


[AllowDuplicates]
public enum RPC_C_QOS_IDENTITY : uint32
{
	RPC_C_QOS_IDENTITY_STATIC = 0,
	RPC_C_QOS_IDENTITY_DYNAMIC = 1,
}


[AllowDuplicates]
public enum RPC_C_AUTHN_INFO_TYPE : uint32
{
	RPC_C_AUTHN_INFO_NONE = 0,
	RPC_C_AUTHN_INFO_TYPE_HTTP = 1,
}


[AllowDuplicates]
public enum RPC_C_HTTP_FLAGS : uint32
{
	RPC_C_HTTP_FLAG_USE_SSL = 1,
	RPC_C_HTTP_FLAG_USE_FIRST_AUTH_SCHEME = 2,
	RPC_C_HTTP_FLAG_IGNORE_CERT_CN_INVALID = 8,
	RPC_C_HTTP_FLAG_ENABLE_CERT_REVOCATION_CHECK = 16,
}


[AllowDuplicates]
public enum RPC_C_HTTP_AUTHN_TARGET : uint32
{
	RPC_C_HTTP_AUTHN_TARGET_SERVER = 1,
	RPC_C_HTTP_AUTHN_TARGET_PROXY = 2,
}


[AllowDuplicates]
public enum RPC_STATUS : int32
{
	RPC_S_INVALID_STRING_BINDING = 1700,
	RPC_S_WRONG_KIND_OF_BINDING = 1701,
	RPC_S_INVALID_BINDING = 1702,
	RPC_S_PROTSEQ_NOT_SUPPORTED = 1703,
	RPC_S_INVALID_RPC_PROTSEQ = 1704,
	RPC_S_INVALID_STRING_UUID = 1705,
	RPC_S_INVALID_ENDPOINT_FORMAT = 1706,
	RPC_S_INVALID_NET_ADDR = 1707,
	RPC_S_NO_ENDPOINT_FOUND = 1708,
	RPC_S_INVALID_TIMEOUT = 1709,
	RPC_S_OBJECT_NOT_FOUND = 1710,
	RPC_S_ALREADY_REGISTERED = 1711,
	RPC_S_TYPE_ALREADY_REGISTERED = 1712,
	RPC_S_ALREADY_LISTENING = 1713,
	RPC_S_NO_PROTSEQS_REGISTERED = 1714,
	RPC_S_NOT_LISTENING = 1715,
	RPC_S_UNKNOWN_MGR_TYPE = 1716,
	RPC_S_UNKNOWN_IF = 1717,
	RPC_S_NO_BINDINGS = 1718,
	RPC_S_NO_PROTSEQS = 1719,
	RPC_S_CANT_CREATE_ENDPOINT = 1720,
	RPC_S_OUT_OF_RESOURCES = 1721,
	RPC_S_SERVER_UNAVAILABLE = 1722,
	RPC_S_SERVER_TOO_BUSY = 1723,
	RPC_S_INVALID_NETWORK_OPTIONS = 1724,
	RPC_S_NO_CALL_ACTIVE = 1725,
	RPC_S_CALL_FAILED = 1726,
	RPC_S_CALL_FAILED_DNE = 1727,
	RPC_S_PROTOCOL_ERROR = 1728,
	RPC_S_PROXY_ACCESS_DENIED = 1729,
	RPC_S_UNSUPPORTED_TRANS_SYN = 1730,
	RPC_S_UNSUPPORTED_TYPE = 1732,
	RPC_S_INVALID_TAG = 1733,
	RPC_S_INVALID_BOUND = 1734,
	RPC_S_NO_ENTRY_NAME = 1735,
	RPC_S_INVALID_NAME_SYNTAX = 1736,
	RPC_S_UNSUPPORTED_NAME_SYNTAX = 1737,
	RPC_S_UUID_NO_ADDRESS = 1739,
	RPC_S_DUPLICATE_ENDPOINT = 1740,
	RPC_S_UNKNOWN_AUTHN_TYPE = 1741,
	RPC_S_MAX_CALLS_TOO_SMALL = 1742,
	RPC_S_STRING_TOO_LONG = 1743,
	RPC_S_PROTSEQ_NOT_FOUND = 1744,
	RPC_S_PROCNUM_OUT_OF_RANGE = 1745,
	RPC_S_BINDING_HAS_NO_AUTH = 1746,
	RPC_S_UNKNOWN_AUTHN_SERVICE = 1747,
	RPC_S_UNKNOWN_AUTHN_LEVEL = 1748,
	RPC_S_INVALID_AUTH_IDENTITY = 1749,
	RPC_S_UNKNOWN_AUTHZ_SERVICE = 1750,
	EPT_S_INVALID_ENTRY = 1751,
	EPT_S_CANT_PERFORM_OP = 1752,
	EPT_S_NOT_REGISTERED = 1753,
	RPC_S_NOTHING_TO_EXPORT = 1754,
	RPC_S_INCOMPLETE_NAME = 1755,
	RPC_S_INVALID_VERS_OPTION = 1756,
	RPC_S_NO_MORE_MEMBERS = 1757,
	RPC_S_NOT_ALL_OBJS_UNEXPORTED = 1758,
	RPC_S_INTERFACE_NOT_FOUND = 1759,
	RPC_S_ENTRY_ALREADY_EXISTS = 1760,
	RPC_S_ENTRY_NOT_FOUND = 1761,
	RPC_S_NAME_SERVICE_UNAVAILABLE = 1762,
	RPC_S_INVALID_NAF_ID = 1763,
	RPC_S_CANNOT_SUPPORT = 1764,
	RPC_S_NO_CONTEXT_AVAILABLE = 1765,
	RPC_S_INTERNAL_ERROR = 1766,
	RPC_S_ZERO_DIVIDE = 1767,
	RPC_S_ADDRESS_ERROR = 1768,
	RPC_S_FP_DIV_ZERO = 1769,
	RPC_S_FP_UNDERFLOW = 1770,
	RPC_S_FP_OVERFLOW = 1771,
	RPC_S_CALL_IN_PROGRESS = 1791,
	RPC_S_NO_MORE_BINDINGS = 1806,
	RPC_S_NO_INTERFACES = 1817,
	RPC_S_CALL_CANCELLED = 1818,
	RPC_S_BINDING_INCOMPLETE = 1819,
	RPC_S_COMM_FAILURE = 1820,
	RPC_S_UNSUPPORTED_AUTHN_LEVEL = 1821,
	RPC_S_NO_PRINC_NAME = 1822,
	RPC_S_NOT_RPC_ERROR = 1823,
	RPC_S_UUID_LOCAL_ONLY = 1824,
	RPC_S_SEC_PKG_ERROR = 1825,
	RPC_S_NOT_CANCELLED = 1826,
	RPC_S_COOKIE_AUTH_FAILED = 1833,
	RPC_S_DO_NOT_DISTURB = 1834,
	RPC_S_SYSTEM_HANDLE_COUNT_EXCEEDED = 1835,
	RPC_S_SYSTEM_HANDLE_TYPE_MISMATCH = 1836,
	RPC_S_GROUP_MEMBER_NOT_FOUND = 1898,
	EPT_S_CANT_CREATE = 1899,
	RPC_S_INVALID_OBJECT = 1900,
	RPC_S_SEND_INCOMPLETE = 1913,
	RPC_S_INVALID_ASYNC_HANDLE = 1914,
	RPC_S_INVALID_ASYNC_CALL = 1915,
	RPC_S_ENTRY_TYPE_MISMATCH = 1922,
	RPC_S_NOT_ALL_OBJS_EXPORTED = 1923,
	RPC_S_INTERFACE_NOT_EXPORTED = 1924,
	RPC_S_PROFILE_NOT_ADDED = 1925,
	RPC_S_PRF_ELT_NOT_ADDED = 1926,
	RPC_S_PRF_ELT_NOT_REMOVED = 1927,
	RPC_S_GRP_ELT_NOT_ADDED = 1928,
	RPC_S_GRP_ELT_NOT_REMOVED = 1929,
}


[AllowDuplicates]
public enum GROUP_NAME_SYNTAX : uint32
{
	RPC_C_NS_SYNTAX_DEFAULT = 0,
	RPC_C_NS_SYNTAX_DCE = 3,
}


[AllowDuplicates]
public enum SEC_WINNT_AUTH_IDENTITY : uint32
{
	SEC_WINNT_AUTH_IDENTITY_ANSI = 1,
	SEC_WINNT_AUTH_IDENTITY_UNICODE = 2,
}


[AllowDuplicates]
public enum RPC_BINDING_HANDLE_OPTIONS_FLAGS : uint32
{
	RPC_BHO_NONCAUSAL = 1,
	RPC_BHO_DONTLINGER = 2,
}


[AllowDuplicates]
public enum RPC_HTTP_REDIRECTOR_STAGE : int32
{
	RPCHTTP_RS_REDIRECT = 1,
	RPCHTTP_RS_ACCESS_1 = 2,
	RPCHTTP_RS_SESSION = 3,
	RPCHTTP_RS_ACCESS_2 = 4,
	RPCHTTP_RS_INTERFACE = 5,
}


[AllowDuplicates]
public enum RPC_ADDRESS_CHANGE_TYPE : int32
{
	PROTOCOL_NOT_LOADED = 1,
	PROTOCOL_LOADED = 2,
	PROTOCOL_ADDRESS_CHANGE = 3,
}


[AllowDuplicates]
public enum LRPC_SYSTEM_HANDLE_MARSHAL_DIRECTION : int32
{
	MarshalDirectionMarshal = 0,
	MarshalDirectionUnmarshal = 1,
}


[AllowDuplicates]
public enum RpcPerfCounters : int32
{
	RpcCurrentUniqueUser = 1,
	RpcBackEndConnectionAttempts = 2,
	RpcBackEndConnectionFailed = 3,
	RpcRequestsPerSecond = 4,
	RpcIncomingConnections = 5,
	RpcIncomingBandwidth = 6,
	RpcOutgoingBandwidth = 7,
	RpcAttemptedLbsDecisions = 8,
	RpcFailedLbsDecisions = 9,
	RpcAttemptedLbsMessages = 10,
	RpcFailedLbsMessages = 11,
	RpcLastCounter = 12,
}


[AllowDuplicates]
public enum RPC_NOTIFICATION_TYPES : int32
{
	RpcNotificationTypeNone = 0,
	RpcNotificationTypeEvent = 1,
	RpcNotificationTypeApc = 2,
	RpcNotificationTypeIoc = 3,
	RpcNotificationTypeHwnd = 4,
	RpcNotificationTypeCallback = 5,
}


[AllowDuplicates]
public enum RPC_ASYNC_EVENT : int32
{
	RpcCallComplete = 0,
	RpcSendComplete = 1,
	RpcReceiveComplete = 2,
	RpcClientDisconnect = 3,
	RpcClientCancel = 4,
}


[AllowDuplicates]
public enum ExtendedErrorParamTypes : int32
{
	eeptAnsiString = 1,
	eeptUnicodeString = 2,
	eeptLongVal = 3,
	eeptShortVal = 4,
	eeptPointerVal = 5,
	eeptNone = 6,
	eeptBinary = 7,
}


[AllowDuplicates]
public enum RpcLocalAddressFormat : int32
{
	rlafInvalid = 0,
	rlafIPv4 = 1,
	rlafIPv6 = 2,
}


[AllowDuplicates]
public enum RpcCallType : int32
{
	rctInvalid = 0,
	rctNormal = 1,
	rctTraining = 2,
	rctGuaranteed = 3,
}


[AllowDuplicates]
public enum RpcCallClientLocality : int32
{
	rcclInvalid = 0,
	rcclLocal = 1,
	rcclRemote = 2,
	rcclClientUnknownLocality = 3,
}


[AllowDuplicates]
public enum RPC_NOTIFICATIONS : int32
{
	RpcNotificationCallNone = 0,
	RpcNotificationClientDisconnect = 1,
	RpcNotificationCallCancel = 2,
}


[AllowDuplicates]
public enum USER_MARSHAL_CB_TYPE : int32
{
	USER_MARSHAL_CB_BUFFER_SIZE = 0,
	USER_MARSHAL_CB_MARSHALL = 1,
	USER_MARSHAL_CB_UNMARSHALL = 2,
	USER_MARSHAL_CB_FREE = 3,
}


[AllowDuplicates]
public enum IDL_CS_CONVERT : int32
{
	IDL_CS_NO_CONVERT = 0,
	IDL_CS_IN_PLACE_CONVERT = 1,
	IDL_CS_NEW_BUFFER_CONVERT = 2,
}


[AllowDuplicates]
public enum XLAT_SIDE : int32
{
	XLAT_SERVER = 1,
	XLAT_CLIENT = 2,
}


[AllowDuplicates]
public enum system_handle_t : int32
{
	SYSTEM_HANDLE_FILE = 0,
	SYSTEM_HANDLE_SEMAPHORE = 1,
	SYSTEM_HANDLE_EVENT = 2,
	SYSTEM_HANDLE_MUTEX = 3,
	SYSTEM_HANDLE_PROCESS = 4,
	SYSTEM_HANDLE_TOKEN = 5,
	SYSTEM_HANDLE_SECTION = 6,
	SYSTEM_HANDLE_REG_KEY = 7,
	SYSTEM_HANDLE_THREAD = 8,
	SYSTEM_HANDLE_COMPOSITION_OBJECT = 9,
	SYSTEM_HANDLE_SOCKET = 10,
	SYSTEM_HANDLE_JOB = 11,
	SYSTEM_HANDLE_PIPE = 12,
	SYSTEM_HANDLE_MAX = 12,
	SYSTEM_HANDLE_INVALID = 255,
}


[AllowDuplicates]
public enum STUB_PHASE : int32
{
	STUB_UNMARSHAL = 0,
	STUB_CALL_SERVER = 1,
	STUB_MARSHAL = 2,
	STUB_CALL_SERVER_NO_HRESULT = 3,
}


[AllowDuplicates]
public enum PROXY_PHASE : int32
{
	PROXY_CALCSIZE = 0,
	PROXY_GETBUFFER = 1,
	PROXY_MARSHAL = 2,
	PROXY_SENDRECEIVE = 3,
	PROXY_UNMARSHAL = 4,
}


[AllowDuplicates]
public enum MIDL_ES_CODE : int32
{
	MES_ENCODE = 0,
	MES_DECODE = 1,
	MES_ENCODE_NDR64 = 2,
}


[AllowDuplicates]
public enum MIDL_ES_HANDLE_STYLE : int32
{
	MES_INCREMENTAL_HANDLE = 0,
	MES_FIXED_BUFFER_HANDLE = 1,
	MES_DYNAMIC_BUFFER_HANDLE = 2,
}


[AllowDuplicates]
public enum EXPR_TOKEN : int32
{
	FC_EXPR_START = 0,
	FC_EXPR_ILLEGAL = 0,
	FC_EXPR_CONST32 = 1,
	FC_EXPR_CONST64 = 2,
	FC_EXPR_VAR = 3,
	FC_EXPR_OPER = 4,
	FC_EXPR_NOOP = 5,
	FC_EXPR_END = 6,
}

#endregion

#region Function Pointers
public function void RPC_OBJECT_INQ_FN(Guid* ObjectUuid, Guid* TypeUuid, RPC_STATUS* Status);

public function RPC_STATUS RPC_IF_CALLBACK_FN(void* InterfaceUuid, void* Context);

public function void RPC_SECURITY_CALLBACK_FN(void* Context);

public function RPC_STATUS RPC_NEW_HTTP_PROXY_CHANNEL(RPC_HTTP_REDIRECTOR_STAGE RedirectorStage, uint16* ServerName, uint16* ServerPort, uint16* RemoteUser, uint16* AuthType, void* ResourceUuid, void* SessionId, void* Interface, void* Reserved, uint32 Flags, uint16** NewServerName, uint16** NewServerPort);

public function void RPC_HTTP_PROXY_FREE_STRING(uint16* String);

public function void RPC_AUTH_KEY_RETRIEVAL_FN(void* Arg, uint16* ServerPrincName, uint32 KeyVer, void** Key, RPC_STATUS* Status);

public function int32 RPC_MGMT_AUTHORIZATION_FN(void* ClientBinding, uint32 RequestedMgmtOperation, RPC_STATUS* Status);

public function void RPC_INTERFACE_GROUP_IDLE_CALLBACK_FN(void* IfGroup, void* IdleCallbackContext, uint32 IsGroupIdle);

public function RPC_STATUS RPC_FORWARD_FUNCTION(Guid* InterfaceId, RPC_VERSION* InterfaceVersion, Guid* ObjectId, uint8* Rpcpro, void** ppDestEndpoint);

public function void RPC_ADDRESS_CHANGE_FN(void* arg);

public function void RPC_DISPATCH_FUNCTION(RPC_MESSAGE* Message);

public function void PRPC_RUNDOWN(void* AssociationContext);

public function void RPCLT_PDU_FILTER_FUNC(void* Buffer, uint32 BufferLength, int32 fDatagram);

public function void RPC_SETFILTER_FUNC(RPCLT_PDU_FILTER_FUNC pfnFilter);

public function RPC_STATUS RPC_BLOCKING_FN(void* hWnd, void* Context, void* hSyncEvent);

public function RPC_STATUS I_RpcProxyIsValidMachineFn(uint16* Machine, uint16* DotMachine, uint32 PortNumber);

public function RPC_STATUS I_RpcProxyGetClientAddressFn(void* Context, PSTR Buffer, uint32* BufferLength);

public function RPC_STATUS I_RpcProxyGetConnectionTimeoutFn(uint32* ConnectionTimeout);

public function RPC_STATUS I_RpcPerformCalloutFn(void* Context, RDR_CALLOUT_STATE* CallOutState, RPC_HTTP_REDIRECTOR_STAGE Stage);

public function void I_RpcFreeCalloutStateFn(RDR_CALLOUT_STATE* CallOutState);

public function RPC_STATUS I_RpcProxyGetClientSessionAndResourceUUID(void* Context, int32* SessionIdPresent, Guid* SessionId, int32* ResourceIdPresent, Guid* ResourceId);

public function RPC_STATUS I_RpcProxyFilterIfFn(void* Context, Guid* IfUuid, uint16 IfMajorVersion, int32* fAllow);

public function void I_RpcProxyUpdatePerfCounterFn(RpcPerfCounters Counter, int32 ModifyTrend, uint32 Size);

public function void I_RpcProxyUpdatePerfCounterBackendServerFn(uint16* MachineName, int32 IsConnectEvent);

public function void PFN_RPCNOTIFICATION_ROUTINE(RPC_ASYNC_STATE* pAsync, void* Context, RPC_ASYNC_EVENT Event);

public function void NDR_RUNDOWN(void* context);

public function void NDR_NOTIFY_ROUTINE();

public function void NDR_NOTIFY2_ROUTINE(uint8 flag);

public function void EXPR_EVAL(MIDL_STUB_MESSAGE* param0);

public function void* GENERIC_BINDING_ROUTINE(void* param0);

public function void GENERIC_UNBIND_ROUTINE(void* param0, uint8* param1);

public function void XMIT_HELPER_ROUTINE(MIDL_STUB_MESSAGE* param0);

public function uint32 USER_MARSHAL_SIZING_ROUTINE(uint32* param0, uint32 param1, void* param2);

public function uint8* USER_MARSHAL_MARSHALLING_ROUTINE(uint32* param0, uint8* param1, void* param2);

public function uint8* USER_MARSHAL_UNMARSHALLING_ROUTINE(uint32* param0, uint8* param1, void* param2);

public function void USER_MARSHAL_FREEING_ROUTINE(uint32* param0, void* param1);

public function void CS_TYPE_NET_SIZE_ROUTINE(void* hBinding, uint32 ulNetworkCodeSet, uint32 ulLocalBufferSize, IDL_CS_CONVERT* conversionType, uint32* pulNetworkBufferSize, uint32* pStatus);

public function void CS_TYPE_LOCAL_SIZE_ROUTINE(void* hBinding, uint32 ulNetworkCodeSet, uint32 ulNetworkBufferSize, IDL_CS_CONVERT* conversionType, uint32* pulLocalBufferSize, uint32* pStatus);

public function void CS_TYPE_TO_NETCS_ROUTINE(void* hBinding, uint32 ulNetworkCodeSet, void* pLocalData, uint32 ulLocalDataLength, uint8* pNetworkData, uint32* pulNetworkDataLength, uint32* pStatus);

public function void CS_TYPE_FROM_NETCS_ROUTINE(void* hBinding, uint32 ulNetworkCodeSet, uint8* pNetworkData, uint32 ulNetworkDataLength, uint32 ulLocalBufferSize, void* pLocalData, uint32* pulLocalDataLength, uint32* pStatus);

public function void CS_TAG_GETTING_ROUTINE(void* hBinding, int32 fServerSide, uint32* pulSendingTag, uint32* pulDesiredReceivingTag, uint32* pulReceivingTag, uint32* pStatus);

public function void STUB_THUNK(MIDL_STUB_MESSAGE* param0);

public function int32 SERVER_ROUTINE();

public function void* RPC_CLIENT_ALLOC(uint Size);

public function void RPC_CLIENT_FREE(void* Ptr);

public function void MIDL_ES_ALLOC(void* state, int8** pbuffer, uint32* psize);

public function void MIDL_ES_WRITE(void* state, PSTR buffer, uint32 size);

public function void MIDL_ES_READ(void* state, int8** pbuffer, uint32* psize);

#endregion

#region Structs
[CRepr]
public struct NDR_SCONTEXT_1
{
	public void*[2] pad;
	public void* userContext;
}

[CRepr]
public struct RPC_BINDING_VECTOR
{
	public uint32 Count;
	public void** BindingH mut => &BindingH_impl;
	private void*[ANYSIZE_ARRAY] BindingH_impl;
}

[CRepr]
public struct UUID_VECTOR
{
	public uint32 Count;
	public Guid** Uuid mut => &Uuid_impl;
	private Guid*[ANYSIZE_ARRAY] Uuid_impl;
}

[CRepr]
public struct RPC_IF_ID
{
	public Guid Uuid;
	public uint16 VersMajor;
	public uint16 VersMinor;
}

[CRepr]
public struct RPC_PROTSEQ_VECTORA
{
	public uint32 Count;
	public uint8** Protseq mut => &Protseq_impl;
	private uint8*[ANYSIZE_ARRAY] Protseq_impl;
}

[CRepr]
public struct RPC_PROTSEQ_VECTORW
{
	public uint32 Count;
	public uint16** Protseq mut => &Protseq_impl;
	private uint16*[ANYSIZE_ARRAY] Protseq_impl;
}

[CRepr]
public struct RPC_POLICY
{
	public uint32 Length;
	public uint32 EndpointFlags;
	public uint32 NICFlags;
}

[CRepr]
public struct RPC_STATS_VECTOR
{
	public uint32 Count;
	public uint32* Stats mut => &Stats_impl;
	private uint32[ANYSIZE_ARRAY] Stats_impl;
}

[CRepr]
public struct RPC_IF_ID_VECTOR
{
	public uint32 Count;
	public RPC_IF_ID** IfId mut => &IfId_impl;
	private RPC_IF_ID*[ANYSIZE_ARRAY] IfId_impl;
}

[CRepr]
public struct RPC_SECURITY_QOS
{
	public uint32 Version;
	public RPC_C_QOS_CAPABILITIES Capabilities;
	public RPC_C_QOS_IDENTITY IdentityTracking;
	public RPC_C_IMP_LEVEL ImpersonationType;
}

[CRepr]
public struct SEC_WINNT_AUTH_IDENTITY_W
{
	public uint16* User;
	public uint32 UserLength;
	public uint16* Domain;
	public uint32 DomainLength;
	public uint16* Password;
	public uint32 PasswordLength;
	public SEC_WINNT_AUTH_IDENTITY Flags;
}

[CRepr]
public struct SEC_WINNT_AUTH_IDENTITY_A
{
	public uint8* User;
	public uint32 UserLength;
	public uint8* Domain;
	public uint32 DomainLength;
	public uint8* Password;
	public uint32 PasswordLength;
	public SEC_WINNT_AUTH_IDENTITY Flags;
}

[CRepr]
public struct RPC_HTTP_TRANSPORT_CREDENTIALS_W
{
	public SEC_WINNT_AUTH_IDENTITY_W* TransportCredentials;
	public RPC_C_HTTP_FLAGS Flags;
	public RPC_C_HTTP_AUTHN_TARGET AuthenticationTarget;
	public uint32 NumberOfAuthnSchemes;
	public uint32* AuthnSchemes;
	public uint16* ServerCertificateSubject;
}

[CRepr]
public struct RPC_HTTP_TRANSPORT_CREDENTIALS_A
{
	public SEC_WINNT_AUTH_IDENTITY_A* TransportCredentials;
	public RPC_C_HTTP_FLAGS Flags;
	public RPC_C_HTTP_AUTHN_TARGET AuthenticationTarget;
	public uint32 NumberOfAuthnSchemes;
	public uint32* AuthnSchemes;
	public uint8* ServerCertificateSubject;
}

[CRepr]
public struct RPC_HTTP_TRANSPORT_CREDENTIALS_V2_W
{
	public SEC_WINNT_AUTH_IDENTITY_W* TransportCredentials;
	public RPC_C_HTTP_FLAGS Flags;
	public RPC_C_HTTP_AUTHN_TARGET AuthenticationTarget;
	public uint32 NumberOfAuthnSchemes;
	public uint32* AuthnSchemes;
	public uint16* ServerCertificateSubject;
	public SEC_WINNT_AUTH_IDENTITY_W* ProxyCredentials;
	public uint32 NumberOfProxyAuthnSchemes;
	public uint32* ProxyAuthnSchemes;
}

[CRepr]
public struct RPC_HTTP_TRANSPORT_CREDENTIALS_V2_A
{
	public SEC_WINNT_AUTH_IDENTITY_A* TransportCredentials;
	public RPC_C_HTTP_FLAGS Flags;
	public RPC_C_HTTP_AUTHN_TARGET AuthenticationTarget;
	public uint32 NumberOfAuthnSchemes;
	public uint32* AuthnSchemes;
	public uint8* ServerCertificateSubject;
	public SEC_WINNT_AUTH_IDENTITY_A* ProxyCredentials;
	public uint32 NumberOfProxyAuthnSchemes;
	public uint32* ProxyAuthnSchemes;
}

[CRepr]
public struct RPC_HTTP_TRANSPORT_CREDENTIALS_V3_W
{
	public void* TransportCredentials;
	public RPC_C_HTTP_FLAGS Flags;
	public RPC_C_HTTP_AUTHN_TARGET AuthenticationTarget;
	public uint32 NumberOfAuthnSchemes;
	public uint32* AuthnSchemes;
	public uint16* ServerCertificateSubject;
	public void* ProxyCredentials;
	public uint32 NumberOfProxyAuthnSchemes;
	public uint32* ProxyAuthnSchemes;
}

[CRepr]
public struct RPC_HTTP_TRANSPORT_CREDENTIALS_V3_A
{
	public void* TransportCredentials;
	public RPC_C_HTTP_FLAGS Flags;
	public RPC_C_HTTP_AUTHN_TARGET AuthenticationTarget;
	public uint32 NumberOfAuthnSchemes;
	public uint32* AuthnSchemes;
	public uint8* ServerCertificateSubject;
	public void* ProxyCredentials;
	public uint32 NumberOfProxyAuthnSchemes;
	public uint32* ProxyAuthnSchemes;
}

[CRepr]
public struct RPC_SECURITY_QOS_V2_W
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public RPC_HTTP_TRANSPORT_CREDENTIALS_W* HttpCredentials;
	}
	public uint32 Version;
	public RPC_C_QOS_CAPABILITIES Capabilities;
	public RPC_C_QOS_IDENTITY IdentityTracking;
	public RPC_C_IMP_LEVEL ImpersonationType;
	public RPC_C_AUTHN_INFO_TYPE AdditionalSecurityInfoType;
	public _u_e__Union u;
}

[CRepr]
public struct RPC_SECURITY_QOS_V2_A
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public RPC_HTTP_TRANSPORT_CREDENTIALS_A* HttpCredentials;
	}
	public uint32 Version;
	public RPC_C_QOS_CAPABILITIES Capabilities;
	public RPC_C_QOS_IDENTITY IdentityTracking;
	public RPC_C_IMP_LEVEL ImpersonationType;
	public RPC_C_AUTHN_INFO_TYPE AdditionalSecurityInfoType;
	public _u_e__Union u;
}

[CRepr]
public struct RPC_SECURITY_QOS_V3_W
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public RPC_HTTP_TRANSPORT_CREDENTIALS_W* HttpCredentials;
	}
	public uint32 Version;
	public RPC_C_QOS_CAPABILITIES Capabilities;
	public RPC_C_QOS_IDENTITY IdentityTracking;
	public RPC_C_IMP_LEVEL ImpersonationType;
	public RPC_C_AUTHN_INFO_TYPE AdditionalSecurityInfoType;
	public _u_e__Union u;
	public void* Sid;
}

[CRepr]
public struct RPC_SECURITY_QOS_V3_A
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public RPC_HTTP_TRANSPORT_CREDENTIALS_A* HttpCredentials;
	}
	public uint32 Version;
	public RPC_C_QOS_CAPABILITIES Capabilities;
	public RPC_C_QOS_IDENTITY IdentityTracking;
	public RPC_C_IMP_LEVEL ImpersonationType;
	public RPC_C_AUTHN_INFO_TYPE AdditionalSecurityInfoType;
	public _u_e__Union u;
	public void* Sid;
}

[CRepr]
public struct RPC_SECURITY_QOS_V4_W
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public RPC_HTTP_TRANSPORT_CREDENTIALS_W* HttpCredentials;
	}
	public uint32 Version;
	public RPC_C_QOS_CAPABILITIES Capabilities;
	public RPC_C_QOS_IDENTITY IdentityTracking;
	public RPC_C_IMP_LEVEL ImpersonationType;
	public RPC_C_AUTHN_INFO_TYPE AdditionalSecurityInfoType;
	public _u_e__Union u;
	public void* Sid;
	public uint32 EffectiveOnly;
}

[CRepr]
public struct RPC_SECURITY_QOS_V4_A
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public RPC_HTTP_TRANSPORT_CREDENTIALS_A* HttpCredentials;
	}
	public uint32 Version;
	public RPC_C_QOS_CAPABILITIES Capabilities;
	public RPC_C_QOS_IDENTITY IdentityTracking;
	public RPC_C_IMP_LEVEL ImpersonationType;
	public RPC_C_AUTHN_INFO_TYPE AdditionalSecurityInfoType;
	public _u_e__Union u;
	public void* Sid;
	public uint32 EffectiveOnly;
}

[CRepr]
public struct RPC_SECURITY_QOS_V5_W
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public RPC_HTTP_TRANSPORT_CREDENTIALS_W* HttpCredentials;
	}
	public uint32 Version;
	public RPC_C_QOS_CAPABILITIES Capabilities;
	public RPC_C_QOS_IDENTITY IdentityTracking;
	public RPC_C_IMP_LEVEL ImpersonationType;
	public RPC_C_AUTHN_INFO_TYPE AdditionalSecurityInfoType;
	public _u_e__Union u;
	public void* Sid;
	public uint32 EffectiveOnly;
	public void* ServerSecurityDescriptor;
}

[CRepr]
public struct RPC_SECURITY_QOS_V5_A
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public RPC_HTTP_TRANSPORT_CREDENTIALS_A* HttpCredentials;
	}
	public uint32 Version;
	public RPC_C_QOS_CAPABILITIES Capabilities;
	public RPC_C_QOS_IDENTITY IdentityTracking;
	public RPC_C_IMP_LEVEL ImpersonationType;
	public RPC_C_AUTHN_INFO_TYPE AdditionalSecurityInfoType;
	public _u_e__Union u;
	public void* Sid;
	public uint32 EffectiveOnly;
	public void* ServerSecurityDescriptor;
}

[CRepr]
public struct RPC_BINDING_HANDLE_TEMPLATE_V1_W
{
	[CRepr, Union]
	public struct _u1_e__Union
	{
		public uint16* Reserved;
	}
	public uint32 Version;
	public uint32 Flags;
	public uint32 ProtocolSequence;
	public uint16* NetworkAddress;
	public uint16* StringEndpoint;
	public _u1_e__Union u1;
	public Guid ObjectUuid;
}

[CRepr]
public struct RPC_BINDING_HANDLE_TEMPLATE_V1_A
{
	[CRepr, Union]
	public struct _u1_e__Union
	{
		public uint8* Reserved;
	}
	public uint32 Version;
	public uint32 Flags;
	public uint32 ProtocolSequence;
	public uint8* NetworkAddress;
	public uint8* StringEndpoint;
	public _u1_e__Union u1;
	public Guid ObjectUuid;
}

[CRepr]
public struct RPC_BINDING_HANDLE_SECURITY_V1_W
{
	public uint32 Version;
	public uint16* ServerPrincName;
	public uint32 AuthnLevel;
	public uint32 AuthnSvc;
	public SEC_WINNT_AUTH_IDENTITY_W* AuthIdentity;
	public RPC_SECURITY_QOS* SecurityQos;
}

[CRepr]
public struct RPC_BINDING_HANDLE_SECURITY_V1_A
{
	public uint32 Version;
	public uint8* ServerPrincName;
	public uint32 AuthnLevel;
	public uint32 AuthnSvc;
	public SEC_WINNT_AUTH_IDENTITY_A* AuthIdentity;
	public RPC_SECURITY_QOS* SecurityQos;
}

[CRepr]
public struct RPC_BINDING_HANDLE_OPTIONS_V1
{
	public uint32 Version;
	public RPC_BINDING_HANDLE_OPTIONS_FLAGS Flags;
	public uint32 ComTimeout;
	public uint32 CallTimeout;
}

[CRepr]
public struct RPC_CLIENT_INFORMATION1
{
	public uint8* UserName;
	public uint8* ComputerName;
	public uint16 Privilege;
	public uint32 AuthFlags;
}

[CRepr]
public struct RPC_ENDPOINT_TEMPLATEW
{
	public uint32 Version;
	public uint16* ProtSeq;
	public uint16* Endpoint;
	public void* SecurityDescriptor;
	public uint32 Backlog;
}

[CRepr]
public struct RPC_ENDPOINT_TEMPLATEA
{
	public uint32 Version;
	public uint8* ProtSeq;
	public uint8* Endpoint;
	public void* SecurityDescriptor;
	public uint32 Backlog;
}

[CRepr]
public struct RPC_INTERFACE_TEMPLATEA
{
	public uint32 Version;
	public void* IfSpec;
	public Guid* MgrTypeUuid;
	public void* MgrEpv;
	public uint32 Flags;
	public uint32 MaxCalls;
	public uint32 MaxRpcSize;
	public RPC_IF_CALLBACK_FN IfCallback;
	public UUID_VECTOR* UuidVector;
	public uint8* Annotation;
	public void* SecurityDescriptor;
}

[CRepr]
public struct RPC_INTERFACE_TEMPLATEW
{
	public uint32 Version;
	public void* IfSpec;
	public Guid* MgrTypeUuid;
	public void* MgrEpv;
	public uint32 Flags;
	public uint32 MaxCalls;
	public uint32 MaxRpcSize;
	public RPC_IF_CALLBACK_FN IfCallback;
	public UUID_VECTOR* UuidVector;
	public uint16* Annotation;
	public void* SecurityDescriptor;
}

[CRepr]
public struct RPC_VERSION
{
	public uint16 MajorVersion;
	public uint16 MinorVersion;
}

[CRepr]
public struct RPC_SYNTAX_IDENTIFIER
{
	public Guid SyntaxGUID;
	public RPC_VERSION SyntaxVersion;
}

[CRepr]
public struct RPC_MESSAGE
{
	public void* Handle;
	public uint32 DataRepresentation;
	public void* Buffer;
	public uint32 BufferLength;
	public uint32 ProcNum;
	public RPC_SYNTAX_IDENTIFIER* TransferSyntax;
	public void* RpcInterfaceInformation;
	public void* ReservedForRuntime;
	public void* ManagerEpv;
	public void* ImportContext;
	public uint32 RpcFlags;
}

[CRepr]
public struct RPC_DISPATCH_TABLE
{
	public uint32 DispatchTableCount;
	public RPC_DISPATCH_FUNCTION DispatchTable;
	public int Reserved;
}

[CRepr]
public struct RPC_PROTSEQ_ENDPOINT
{
	public uint8* RpcProtocolSequence;
	public uint8* Endpoint;
}

[CRepr]
public struct RPC_SERVER_INTERFACE
{
	public uint32 Length;
	public RPC_SYNTAX_IDENTIFIER InterfaceId;
	public RPC_SYNTAX_IDENTIFIER TransferSyntax;
	public RPC_DISPATCH_TABLE* DispatchTable;
	public uint32 RpcProtseqEndpointCount;
	public RPC_PROTSEQ_ENDPOINT* RpcProtseqEndpoint;
	public void* DefaultManagerEpv;
	public void* InterpreterInfo;
	public uint32 Flags;
}

[CRepr]
public struct RPC_CLIENT_INTERFACE
{
	public uint32 Length;
	public RPC_SYNTAX_IDENTIFIER InterfaceId;
	public RPC_SYNTAX_IDENTIFIER TransferSyntax;
	public RPC_DISPATCH_TABLE* DispatchTable;
	public uint32 RpcProtseqEndpointCount;
	public RPC_PROTSEQ_ENDPOINT* RpcProtseqEndpoint;
	public uint Reserved;
	public void* InterpreterInfo;
	public uint32 Flags;
}

[CRepr]
public struct RPC_SEC_CONTEXT_KEY_INFO
{
	public uint32 EncryptAlgorithm;
	public uint32 KeySize;
	public uint32 SignatureAlgorithm;
}

[CRepr]
public struct RPC_TRANSFER_SYNTAX
{
	public Guid Uuid;
	public uint16 VersMajor;
	public uint16 VersMinor;
}

[CRepr]
public struct RPC_C_OPT_COOKIE_AUTH_DESCRIPTOR
{
	public uint32 BufferSize;
	public PSTR Buffer;
}

[CRepr]
public struct RDR_CALLOUT_STATE
{
	public RPC_STATUS LastError;
	public void* LastEEInfo;
	public RPC_HTTP_REDIRECTOR_STAGE LastCalledStage;
	public uint16* ServerName;
	public uint16* ServerPort;
	public uint16* RemoteUser;
	public uint16* AuthType;
	public uint8 ResourceTypePresent;
	public uint8 SessionIdPresent;
	public uint8 InterfacePresent;
	public Guid ResourceType;
	public Guid SessionId;
	public RPC_SYNTAX_IDENTIFIER Interface;
	public void* CertContext;
}

[CRepr]
public struct I_RpcProxyCallbackInterface
{
	public I_RpcProxyIsValidMachineFn IsValidMachineFn;
	public I_RpcProxyGetClientAddressFn GetClientAddressFn;
	public I_RpcProxyGetConnectionTimeoutFn GetConnectionTimeoutFn;
	public I_RpcPerformCalloutFn PerformCalloutFn;
	public I_RpcFreeCalloutStateFn FreeCalloutStateFn;
	public I_RpcProxyGetClientSessionAndResourceUUID GetClientSessionAndResourceUUIDFn;
	public I_RpcProxyFilterIfFn ProxyFilterIfFn;
	public I_RpcProxyUpdatePerfCounterFn RpcProxyUpdatePerfCounterFn;
	public I_RpcProxyUpdatePerfCounterBackendServerFn RpcProxyUpdatePerfCounterBackendServerFn;
}

[CRepr, Union]
public struct RPC_ASYNC_NOTIFICATION_INFO
{
	[CRepr]
	public struct _IntPtr_e__Struct
	{
		public HWND hWnd;
		public uint32 Msg;
	}
	[CRepr]
	public struct _APC_e__Struct
	{
		public PFN_RPCNOTIFICATION_ROUTINE NotificationRoutine;
		public HANDLE hThread;
	}
	[CRepr]
	public struct _IOC_e__Struct
	{
		public HANDLE hIOPort;
		public uint32 dwNumberOfBytesTransferred;
		public uint dwCompletionKey;
		public OVERLAPPED* lpOverlapped;
	}
	public _APC_e__Struct APC;
	public _IOC_e__Struct IOC;
	public _IntPtr_e__Struct IntPtr;
	public HANDLE hEvent;
	public PFN_RPCNOTIFICATION_ROUTINE NotificationRoutine;
}

[CRepr]
public struct RPC_ASYNC_STATE
{
	public uint32 Size;
	public uint32 Signature;
	public int32 Lock;
	public uint32 Flags;
	public void* StubInfo;
	public void* UserInfo;
	public void* RuntimeInfo;
	public RPC_ASYNC_EVENT Event;
	public RPC_NOTIFICATION_TYPES NotificationType;
	public RPC_ASYNC_NOTIFICATION_INFO u;
	public int[4] Reserved;
}

[CRepr]
public struct BinaryParam
{
	public void* Buffer;
	public int16 Size;
}

[CRepr]
public struct RPC_EE_INFO_PARAM
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public PSTR AnsiString;
		public PWSTR UnicodeString;
		public int32 LVal;
		public int16 SVal;
		public uint64 PVal;
		public BinaryParam BVal;
	}
	public ExtendedErrorParamTypes ParameterType;
	public _u_e__Union u;
}

[CRepr]
public struct RPC_EXTENDED_ERROR_INFO
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		public SYSTEMTIME SystemTime;
		public FILETIME FileTime;
	}
	public uint32 Version;
	public PWSTR ComputerName;
	public uint32 ProcessID;
	public _u_e__Union u;
	public uint32 GeneratingComponent;
	public uint32 Status;
	public uint16 DetectionLocation;
	public uint16 Flags;
	public int32 NumberOfParameters;
	public RPC_EE_INFO_PARAM[4] Parameters;
}

[CRepr]
public struct RPC_ERROR_ENUM_HANDLE
{
	public uint32 Signature;
	public void* CurrentPos;
	public void* Head;
}

[CRepr]
public struct RPC_CALL_LOCAL_ADDRESS_V1
{
	public uint32 Version;
	public void* Buffer;
	public uint32 BufferSize;
	public RpcLocalAddressFormat AddressFormat;
}

[CRepr]
public struct RPC_CALL_ATTRIBUTES_V1_W
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 ServerPrincipalNameBufferLength;
	public uint16* ServerPrincipalName;
	public uint32 ClientPrincipalNameBufferLength;
	public uint16* ClientPrincipalName;
	public uint32 AuthenticationLevel;
	public uint32 AuthenticationService;
	public BOOL NullSession;
}

[CRepr]
public struct RPC_CALL_ATTRIBUTES_V1_A
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 ServerPrincipalNameBufferLength;
	public uint8* ServerPrincipalName;
	public uint32 ClientPrincipalNameBufferLength;
	public uint8* ClientPrincipalName;
	public uint32 AuthenticationLevel;
	public uint32 AuthenticationService;
	public BOOL NullSession;
}

[CRepr]
public struct RPC_CALL_ATTRIBUTES_V2_W
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 ServerPrincipalNameBufferLength;
	public uint16* ServerPrincipalName;
	public uint32 ClientPrincipalNameBufferLength;
	public uint16* ClientPrincipalName;
	public uint32 AuthenticationLevel;
	public uint32 AuthenticationService;
	public BOOL NullSession;
	public BOOL KernelModeCaller;
	public uint32 ProtocolSequence;
	public RpcCallClientLocality IsClientLocal;
	public HANDLE ClientPID;
	public uint32 CallStatus;
	public RpcCallType CallType;
	public RPC_CALL_LOCAL_ADDRESS_V1* CallLocalAddress;
	public uint16 OpNum;
	public Guid InterfaceUuid;
}

[CRepr]
public struct RPC_CALL_ATTRIBUTES_V2_A
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 ServerPrincipalNameBufferLength;
	public uint8* ServerPrincipalName;
	public uint32 ClientPrincipalNameBufferLength;
	public uint8* ClientPrincipalName;
	public uint32 AuthenticationLevel;
	public uint32 AuthenticationService;
	public BOOL NullSession;
	public BOOL KernelModeCaller;
	public uint32 ProtocolSequence;
	public uint32 IsClientLocal;
	public HANDLE ClientPID;
	public uint32 CallStatus;
	public RpcCallType CallType;
	public RPC_CALL_LOCAL_ADDRESS_V1* CallLocalAddress;
	public uint16 OpNum;
	public Guid InterfaceUuid;
}

[CRepr]
public struct RPC_CALL_ATTRIBUTES_V3_W
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 ServerPrincipalNameBufferLength;
	public uint16* ServerPrincipalName;
	public uint32 ClientPrincipalNameBufferLength;
	public uint16* ClientPrincipalName;
	public uint32 AuthenticationLevel;
	public uint32 AuthenticationService;
	public BOOL NullSession;
	public BOOL KernelModeCaller;
	public uint32 ProtocolSequence;
	public RpcCallClientLocality IsClientLocal;
	public HANDLE ClientPID;
	public uint32 CallStatus;
	public RpcCallType CallType;
	public RPC_CALL_LOCAL_ADDRESS_V1* CallLocalAddress;
	public uint16 OpNum;
	public Guid InterfaceUuid;
	public uint32 ClientIdentifierBufferLength;
	public uint8* ClientIdentifier;
}

[CRepr]
public struct RPC_CALL_ATTRIBUTES_V3_A
{
	public uint32 Version;
	public uint32 Flags;
	public uint32 ServerPrincipalNameBufferLength;
	public uint8* ServerPrincipalName;
	public uint32 ClientPrincipalNameBufferLength;
	public uint8* ClientPrincipalName;
	public uint32 AuthenticationLevel;
	public uint32 AuthenticationService;
	public BOOL NullSession;
	public BOOL KernelModeCaller;
	public uint32 ProtocolSequence;
	public uint32 IsClientLocal;
	public HANDLE ClientPID;
	public uint32 CallStatus;
	public RpcCallType CallType;
	public RPC_CALL_LOCAL_ADDRESS_V1* CallLocalAddress;
	public uint16 OpNum;
	public Guid InterfaceUuid;
	public uint32 ClientIdentifierBufferLength;
	public uint8* ClientIdentifier;
}

[CRepr]
public struct RPC_IMPORT_CONTEXT_P
{
	public void* LookupContext;
	public void* ProposedHandle;
	public RPC_BINDING_VECTOR* Bindings;
}

[CRepr]
public struct _NDR_SCONTEXT
{
	public void*[2] pad;
	public void* userContext;
}

[CRepr]
public struct SCONTEXT_QUEUE
{
	public uint32 NumberOfObjects;
	public NDR_SCONTEXT_1** ArrayOfObjects;
}

[CRepr]
public struct ARRAY_INFO
{
	public int32 Dimension;
	public uint32* BufferConformanceMark;
	public uint32* BufferVarianceMark;
	public uint32* MaxCountArray;
	public uint32* OffsetArray;
	public uint32* ActualCountArray;
}

[CRepr]
public struct _NDR_ASYNC_MESSAGE
{
}

[CRepr]
public struct _NDR_CORRELATION_INFO
{
}

[CRepr]
public struct NDR_ALLOC_ALL_NODES_CONTEXT
{
}

[CRepr]
public struct NDR_POINTER_QUEUE_STATE
{
}

[CRepr]
public struct _NDR_PROC_CONTEXT
{
}

[CRepr]
public struct MIDL_STUB_MESSAGE
{
	public RPC_MESSAGE* RpcMsg;
	public uint8* Buffer;
	public uint8* BufferStart;
	public uint8* BufferEnd;
	public uint8* BufferMark;
	public uint32 BufferLength;
	public uint32 MemorySize;
	public uint8* Memory;
	public uint8 IsClient;
	public uint8 Pad;
	public uint16 uFlags2;
	public int32 ReuseBuffer;
	public NDR_ALLOC_ALL_NODES_CONTEXT* pAllocAllNodesContext;
	public NDR_POINTER_QUEUE_STATE* pPointerQueueState;
	public int32 IgnoreEmbeddedPointers;
	public uint8* PointerBufferMark;
	public uint8 CorrDespIncrement;
	public uint8 uFlags;
	public uint16 UniquePtrCount;
	public uint MaxCount;
	public uint32 Offset;
	public uint32 ActualCount;
	public int pfnAllocate;
	public int pfnFree;
	public uint8* StackTop;
	public uint8* pPresentedType;
	public uint8* pTransmitType;
	public void* SavedHandle;
	public MIDL_STUB_DESC* StubDesc;
	public FULL_PTR_XLAT_TABLES* FullPtrXlatTables;
	public uint32 FullPtrRefId;
	public uint32 PointerLength;
	public int32 _bitfield;
	public uint32 dwDestContext;
	public void* pvDestContext;
	public NDR_SCONTEXT_1** SavedContextHandles;
	public int32 ParamNumber;
	public IRpcChannelBuffer* pRpcChannelBuffer;
	public ARRAY_INFO* pArrayInfo;
	public uint32* SizePtrCountArray;
	public uint32* SizePtrOffsetArray;
	public uint32* SizePtrLengthArray;
	public void* pArgQueue;
	public uint32 dwStubPhase;
	public void* LowStackMark;
	public _NDR_ASYNC_MESSAGE* pAsyncMsg;
	public _NDR_CORRELATION_INFO* pCorrInfo;
	public uint8* pCorrMemory;
	public void* pMemoryList;
	public int pCSInfo;
	public uint8* ConformanceMark;
	public uint8* VarianceMark;
	public int Unused;
	public _NDR_PROC_CONTEXT* pContext;
	public void* ContextHandleHash;
	public void* pUserMarshalList;
	public int Reserved51_3;
	public int Reserved51_4;
	public int Reserved51_5;
}

[CRepr]
public struct GENERIC_BINDING_ROUTINE_PAIR
{
	public GENERIC_BINDING_ROUTINE pfnBind;
	public GENERIC_UNBIND_ROUTINE pfnUnbind;
}

[CRepr]
public struct GENERIC_BINDING_INFO
{
	public void* pObj;
	public uint32 Size;
	public GENERIC_BINDING_ROUTINE pfnBind;
	public GENERIC_UNBIND_ROUTINE pfnUnbind;
}

[CRepr]
public struct XMIT_ROUTINE_QUINTUPLE
{
	public XMIT_HELPER_ROUTINE pfnTranslateToXmit;
	public XMIT_HELPER_ROUTINE pfnTranslateFromXmit;
	public XMIT_HELPER_ROUTINE pfnFreeXmit;
	public XMIT_HELPER_ROUTINE pfnFreeInst;
}

[CRepr]
public struct USER_MARSHAL_ROUTINE_QUADRUPLE
{
	public USER_MARSHAL_SIZING_ROUTINE pfnBufferSize;
	public USER_MARSHAL_MARSHALLING_ROUTINE pfnMarshall;
	public USER_MARSHAL_UNMARSHALLING_ROUTINE pfnUnmarshall;
	public USER_MARSHAL_FREEING_ROUTINE pfnFree;
}

[CRepr]
public struct USER_MARSHAL_CB
{
	public uint32 Flags;
	public MIDL_STUB_MESSAGE* pStubMsg;
	public uint8* pReserve;
	public uint32 Signature;
	public USER_MARSHAL_CB_TYPE CBType;
	public uint8* pFormat;
	public uint8* pTypeFormat;
}

[CRepr]
public struct MALLOC_FREE_STRUCT
{
	public int pfnAllocate;
	public int pfnFree;
}

[CRepr]
public struct COMM_FAULT_OFFSETS
{
	public int16 CommOffset;
	public int16 FaultOffset;
}

[CRepr]
public struct NDR_CS_SIZE_CONVERT_ROUTINES
{
	public CS_TYPE_NET_SIZE_ROUTINE pfnNetSize;
	public CS_TYPE_TO_NETCS_ROUTINE pfnToNetCs;
	public CS_TYPE_LOCAL_SIZE_ROUTINE pfnLocalSize;
	public CS_TYPE_FROM_NETCS_ROUTINE pfnFromNetCs;
}

[CRepr]
public struct NDR_CS_ROUTINES
{
	public NDR_CS_SIZE_CONVERT_ROUTINES* pSizeConvertRoutines;
	public CS_TAG_GETTING_ROUTINE* pTagGettingRoutines;
}

[CRepr]
public struct NDR_EXPR_DESC
{
	public uint16* pOffset;
	public uint8* pFormatExpr;
}

[CRepr]
public struct MIDL_STUB_DESC
{
	[CRepr, Union]
	public struct _IMPLICIT_HANDLE_INFO_e__Union
	{
		public void** pAutoHandle;
		public void** pPrimitiveHandle;
		public GENERIC_BINDING_INFO* pGenericBindingInfo;
	}
	public void* RpcInterfaceInformation;
	public int pfnAllocate;
	public int pfnFree;
	public _IMPLICIT_HANDLE_INFO_e__Union IMPLICIT_HANDLE_INFO;
	public NDR_RUNDOWN* apfnNdrRundownRoutines;
	public GENERIC_BINDING_ROUTINE_PAIR* aGenericBindingRoutinePairs;
	public EXPR_EVAL* apfnExprEval;
	public XMIT_ROUTINE_QUINTUPLE* aXmitQuintuple;
	public uint8* pFormatTypes;
	public int32 fCheckBounds;
	public uint32 Version;
	public MALLOC_FREE_STRUCT* pMallocFreeStruct;
	public int32 MIDLVersion;
	public COMM_FAULT_OFFSETS* CommFaultOffsets;
	public USER_MARSHAL_ROUTINE_QUADRUPLE* aUserMarshalQuadruple;
	public NDR_NOTIFY_ROUTINE* NotifyRoutineTable;
	public uint mFlags;
	public NDR_CS_ROUTINES* CsRoutineTables;
	public void* ProxyServerInfo;
	public NDR_EXPR_DESC* pExprInfo;
}

[CRepr]
public struct MIDL_FORMAT_STRING
{
	public int16 Pad;
	public uint8* Format mut => &Format_impl;
	private uint8[ANYSIZE_ARRAY] Format_impl;
}

[CRepr]
public struct MIDL_METHOD_PROPERTY
{
	public uint32 Id;
	public uint Value;
}

[CRepr]
public struct MIDL_METHOD_PROPERTY_MAP
{
	public uint32 Count;
	public MIDL_METHOD_PROPERTY* Properties;
}

[CRepr]
public struct MIDL_INTERFACE_METHOD_PROPERTIES
{
	public uint16 MethodCount;
	public MIDL_METHOD_PROPERTY_MAP** MethodProperties;
}

[CRepr]
public struct MIDL_SERVER_INFO
{
	public MIDL_STUB_DESC* pStubDesc;
	public SERVER_ROUTINE* DispatchTable;
	public uint8* ProcString;
	public uint16* FmtStringOffset;
	public STUB_THUNK* ThunkTable;
	public RPC_SYNTAX_IDENTIFIER* pTransferSyntax;
	public uint nCount;
	public MIDL_SYNTAX_INFO* pSyntaxInfo;
}

[CRepr]
public struct MIDL_STUBLESS_PROXY_INFO
{
	public MIDL_STUB_DESC* pStubDesc;
	public uint8* ProcFormatString;
	public uint16* FormatStringOffset;
	public RPC_SYNTAX_IDENTIFIER* pTransferSyntax;
	public uint nCount;
	public MIDL_SYNTAX_INFO* pSyntaxInfo;
}

[CRepr]
public struct MIDL_SYNTAX_INFO
{
	public RPC_SYNTAX_IDENTIFIER TransferSyntax;
	public RPC_DISPATCH_TABLE* DispatchTable;
	public uint8* ProcString;
	public uint16* FmtStringOffset;
	public uint8* TypeString;
	public void* aUserMarshalQuadruple;
	public MIDL_INTERFACE_METHOD_PROPERTIES* pMethodProperties;
	public uint pReserved2;
}

[CRepr, Union]
public struct CLIENT_CALL_RETURN
{
	public void* Pointer;
	public int Simple;
}

[CRepr]
public struct FULL_PTR_XLAT_TABLES
{
	public void* RefIdToPointer;
	public void* PointerToRefId;
	public uint32 NextRefId;
	public XLAT_SIDE XlatSide;
}

[CRepr]
public struct MIDL_INTERCEPTION_INFO
{
	public uint32 Version;
	public uint8* ProcString;
	public uint16* ProcFormatOffsetTable;
	public uint32 ProcCount;
	public uint8* TypeString;
}

[CRepr]
public struct MIDL_WINRT_TYPE_SERIALIZATION_INFO
{
	public uint32 Version;
	public uint8* TypeFormatString;
	public uint16 FormatStringSize;
	public uint16 TypeOffset;
	public MIDL_STUB_DESC* StubDesc;
}

[CRepr]
public struct NDR_USER_MARSHAL_INFO_LEVEL1
{
	public void* Buffer;
	public uint32 BufferSize;
	public int pfnAllocate;
	public int pfnFree;
	public IRpcChannelBuffer* pRpcChannelBuffer;
	public uint[5] Reserved;
}

[CRepr]
public struct NDR_USER_MARSHAL_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public NDR_USER_MARSHAL_INFO_LEVEL1 Level1;
	}
	public uint32 InformationLevel;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct MIDL_TYPE_PICKLING_INFO
{
	public uint32 Version;
	public uint32 Flags;
	public uint[3] Reserved;
}

[CRepr]
public struct NDR64_PROC_FLAGS
{
	public uint32 _bitfield;
}

[CRepr]
public struct NDR64_RPC_FLAGS
{
	public uint16 _bitfield;
}

[CRepr]
public struct NDR64_PROC_FORMAT
{
	public uint32 Flags;
	public uint32 StackSize;
	public uint32 ConstantClientBufferSize;
	public uint32 ConstantServerBufferSize;
	public uint16 RpcFlags;
	public uint16 FloatDoubleMask;
	public uint16 NumberOfParams;
	public uint16 ExtensionSize;
}

[CRepr]
public struct NDR64_PARAM_FLAGS
{
	public uint16 _bitfield;
}

[CRepr]
public struct NDR64_PARAM_FORMAT
{
	public void* Type;
	public NDR64_PARAM_FLAGS Attributes;
	public uint16 Reserved;
	public uint32 StackOffset;
}

[CRepr]
public struct NDR64_RANGE_FORMAT
{
	public uint8 FormatCode;
	public uint8 RangeType;
	public uint16 Reserved;
	public int64 MinValue;
	public int64 MaxValue;
}

[CRepr]
public struct NDR64_CONTEXT_HANDLE_FLAGS
{
	public uint8 _bitfield;
}

[CRepr]
public struct NDR64_CONTEXT_HANDLE_FORMAT
{
	public uint8 FormatCode;
	public uint8 ContextFlags;
	public uint8 RundownRoutineIndex;
	public uint8 Ordinal;
}

[CRepr]
public struct NDR64_BIND_PRIMITIVE
{
	public uint8 HandleType;
	public uint8 Flags;
	public uint16 StackOffset;
	public uint16 Reserved;
}

[CRepr]
public struct NDR64_BIND_GENERIC
{
	public uint8 HandleType;
	public uint8 Flags;
	public uint16 StackOffset;
	public uint8 RoutineIndex;
	public uint8 Size;
}

[CRepr]
public struct NDR64_BIND_CONTEXT
{
	public uint8 HandleType;
	public uint8 Flags;
	public uint16 StackOffset;
	public uint8 RoutineIndex;
	public uint8 Ordinal;
}

[CRepr, Union]
public struct NDR64_BINDINGS
{
	public NDR64_BIND_PRIMITIVE Primitive;
	public NDR64_BIND_GENERIC Generic;
	public NDR64_BIND_CONTEXT Context;
}

[CRepr]
public struct NDR64_BIND_AND_NOTIFY_EXTENSION
{
	public NDR64_BIND_CONTEXT Binding;
	public uint16 NotifyIndex;
}

[CRepr]
public struct NDR64_SYSTEM_HANDLE_FORMAT
{
	public uint8 FormatCode;
	public uint8 HandleType;
	public uint32 DesiredAccess;
}

[CRepr]
public struct NDR64_POINTER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Flags;
	public uint16 Reserved;
	public void* Pointee;
}

[CRepr]
public struct NDR64_NO_REPEAT_FORMAT
{
	public uint8 FormatCode;
	public uint8 Flags;
	public uint16 Reserved1;
	public uint32 Reserved2;
}

[CRepr]
public struct NDR64_POINTER_INSTANCE_HEADER_FORMAT
{
	public uint32 Offset;
	public uint32 Reserved;
}

[CRepr]
public struct NDR64_POINTER_REPEAT_FLAGS
{
	public uint8 _bitfield;
}

[CRepr]
public struct NDR64_REPEAT_FORMAT
{
	public uint8 FormatCode;
	public NDR64_POINTER_REPEAT_FLAGS Flags;
	public uint16 Reserved;
	public uint32 Increment;
	public uint32 OffsetToArray;
	public uint32 NumberOfPointers;
}

[CRepr]
public struct NDR64_FIXED_REPEAT_FORMAT
{
	public NDR64_REPEAT_FORMAT RepeatFormat;
	public uint32 Iterations;
	public uint32 Reserved;
}

[CRepr]
public struct NDR64_IID_FLAGS
{
	public uint8 _bitfield;
}

[CRepr]
public struct NDR64_CONSTANT_IID_FORMAT
{
	public uint8 FormatCode;
	public uint8 Flags;
	public uint16 Reserved;
	public Guid Guid;
}

[CRepr]
public struct NDR64_IID_FORMAT
{
	public uint8 FormatCode;
	public uint8 Flags;
	public uint16 Reserved;
	public void* IIDDescriptor;
}

[CRepr]
public struct NDR64_STRUCTURE_FLAGS
{
	public uint8 _bitfield;
}

[CRepr]
public struct NDR64_STRUCTURE_HEADER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public NDR64_STRUCTURE_FLAGS Flags;
	public uint8 Reserve;
	public uint32 MemorySize;
}

[CRepr]
public struct NDR64_CONF_STRUCTURE_HEADER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public NDR64_STRUCTURE_FLAGS Flags;
	public uint8 Reserve;
	public uint32 MemorySize;
	public void* ArrayDescription;
}

[CRepr]
public struct NDR64_BOGUS_STRUCTURE_HEADER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public NDR64_STRUCTURE_FLAGS Flags;
	public uint8 Reserve;
	public uint32 MemorySize;
	public void* OriginalMemberLayout;
	public void* OriginalPointerLayout;
	public void* PointerLayout;
}

[CRepr]
public struct NDR64_CONF_BOGUS_STRUCTURE_HEADER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public NDR64_STRUCTURE_FLAGS Flags;
	public uint8 Dimensions;
	public uint32 MemorySize;
	public void* OriginalMemberLayout;
	public void* OriginalPointerLayout;
	public void* PointerLayout;
	public void* ConfArrayDescription;
}

[CRepr]
public struct NDR64_SIMPLE_MEMBER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Reserved1;
	public uint16 Reserved2;
	public uint32 Reserved3;
}

[CRepr]
public struct NDR64_MEMPAD_FORMAT
{
	public uint8 FormatCode;
	public uint8 Reserve1;
	public uint16 MemPad;
	public uint32 Reserved2;
}

[CRepr]
public struct NDR64_EMBEDDED_COMPLEX_FORMAT
{
	public uint8 FormatCode;
	public uint8 Reserve1;
	public uint16 Reserve2;
	public void* Type;
}

[CRepr]
public struct NDR64_BUFFER_ALIGN_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public uint16 Reserved;
	public uint32 Reserved2;
}

[CRepr]
public struct NDR64_SIMPLE_REGION_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public uint16 RegionSize;
	public uint32 Reserved;
}

[CRepr]
public struct NDR64_ENCAPSULATED_UNION
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public uint8 Flags;
	public uint8 SwitchType;
	public uint32 MemoryOffset;
	public uint32 MemorySize;
	public uint32 Reserved;
}

[CRepr]
public struct NDR64_NON_ENCAPSULATED_UNION
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public uint8 Flags;
	public uint8 SwitchType;
	public uint32 MemorySize;
	public void* Switch;
	public uint32 Reserved;
}

[CRepr]
public struct NDR64_UNION_ARM_SELECTOR
{
	public uint8 Reserved1;
	public uint8 Alignment;
	public uint16 Reserved2;
	public uint32 Arms;
}

[CRepr]
public struct NDR64_UNION_ARM
{
	public int64 CaseValue;
	public void* Type;
	public uint32 Reserved;
}

[CRepr]
public struct NDR64_ARRAY_FLAGS
{
	public uint8 _bitfield;
}

[CRepr]
public struct NDR64_ARRAY_ELEMENT_INFO
{
	public uint32 ElementMemSize;
	public void* Element;
}

[CRepr]
public struct NDR64_FIX_ARRAY_HEADER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public NDR64_ARRAY_FLAGS Flags;
	public uint8 Reserved;
	public uint32 TotalSize;
}

[CRepr]
public struct NDR64_CONF_ARRAY_HEADER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public NDR64_ARRAY_FLAGS Flags;
	public uint8 Reserved;
	public uint32 ElementSize;
	public void* ConfDescriptor;
}

[CRepr]
public struct NDR64_CONF_VAR_ARRAY_HEADER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public NDR64_ARRAY_FLAGS Flags;
	public uint8 Reserved;
	public uint32 ElementSize;
	public void* ConfDescriptor;
	public void* VarDescriptor;
}

[CRepr]
public struct NDR64_VAR_ARRAY_HEADER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public NDR64_ARRAY_FLAGS Flags;
	public uint8 Reserved;
	public uint32 TotalSize;
	public uint32 ElementSize;
	public void* VarDescriptor;
}

[CRepr]
public struct NDR64_BOGUS_ARRAY_HEADER_FORMAT
{
	public uint8 FormatCode;
	public uint8 Alignment;
	public NDR64_ARRAY_FLAGS Flags;
	public uint8 NumberDims;
	public uint32 NumberElements;
	public void* Element;
}

[CRepr]
public struct NDR64_CONF_VAR_BOGUS_ARRAY_HEADER_FORMAT
{
	public NDR64_BOGUS_ARRAY_HEADER_FORMAT FixedArrayFormat;
	public void* ConfDescription;
	public void* VarDescription;
	public void* OffsetDescription;
}

[CRepr]
public struct NDR64_STRING_FLAGS
{
	public uint8 _bitfield;
}

[CRepr]
public struct NDR64_STRING_HEADER_FORMAT
{
	public uint8 FormatCode;
	public NDR64_STRING_FLAGS Flags;
	public uint16 ElementSize;
}

[CRepr]
public struct NDR64_NON_CONFORMANT_STRING_FORMAT
{
	public NDR64_STRING_HEADER_FORMAT Header;
	public uint32 TotalSize;
}

[CRepr]
public struct NDR64_RANGED_STRING_FORMAT
{
	public NDR64_STRING_HEADER_FORMAT Header;
	public uint32 Reserved;
	public uint64 Min;
	public uint64 Max;
}

[CRepr]
public struct NDR64_CONFORMANT_STRING_FORMAT
{
	public NDR64_STRING_HEADER_FORMAT Header;
}

[CRepr]
public struct NDR64_SIZED_CONFORMANT_STRING_FORMAT
{
	public NDR64_STRING_HEADER_FORMAT Header;
	public void* SizeDescription;
}

[CRepr]
public struct NDR64_EXPR_OPERATOR
{
	public uint8 ExprType;
	public uint8 Operator;
	public uint8 CastType;
	public uint8 Reserved;
}

[CRepr]
public struct NDR64_EXPR_CONST32
{
	public uint8 ExprType;
	public uint8 Reserved;
	public uint16 Reserved1;
	public uint32 ConstValue;
}

[CRepr]
public struct NDR64_EXPR_CONST64
{
	public uint8 ExprType;
	public uint8 Reserved;
	public uint16 Reserved1;
	public int64 ConstValue;
}

[CRepr]
public struct NDR64_EXPR_VAR
{
	public uint8 ExprType;
	public uint8 VarType;
	public uint16 Reserved;
	public uint32 Offset;
}

[CRepr]
public struct NDR64_EXPR_NOOP
{
	public uint8 ExprType;
	public uint8 Size;
	public uint16 Reserved;
}

[CRepr]
public struct NDR64_TRANSMIT_AS_FLAGS
{
	public uint8 _bitfield;
}

[CRepr]
public struct NDR64_TRANSMIT_AS_FORMAT
{
	public uint8 FormatCode;
	public uint8 Flags;
	public uint16 RoutineIndex;
	public uint16 TransmittedTypeWireAlignment;
	public uint16 MemoryAlignment;
	public uint32 PresentedTypeMemorySize;
	public uint32 TransmittedTypeBufferSize;
	public void* TransmittedType;
}

[CRepr]
public struct NDR64_USER_MARSHAL_FLAGS
{
	public uint8 _bitfield;
}

[CRepr]
public struct NDR64_USER_MARSHAL_FORMAT
{
	public uint8 FormatCode;
	public uint8 Flags;
	public uint16 RoutineIndex;
	public uint16 TransmittedTypeWireAlignment;
	public uint16 MemoryAlignment;
	public uint32 UserTypeMemorySize;
	public uint32 TransmittedTypeBufferSize;
	public void* TransmittedType;
}

[CRepr]
public struct NDR64_PIPE_FLAGS
{
	public uint8 _bitfield;
}

[CRepr]
public struct NDR64_PIPE_FORMAT
{
	public uint8 FormatCode;
	public uint8 Flags;
	public uint8 Alignment;
	public uint8 Reserved;
	public void* Type;
	public uint32 MemorySize;
	public uint32 BufferSize;
}

[CRepr]
public struct NDR64_RANGE_PIPE_FORMAT
{
	public uint8 FormatCode;
	public uint8 Flags;
	public uint8 Alignment;
	public uint8 Reserved;
	public void* Type;
	public uint32 MemorySize;
	public uint32 BufferSize;
	public uint32 MinValue;
	public uint32 MaxValue;
}

[CRepr]
public struct NDR64_TYPE_STRICT_CONTEXT_HANDLE
{
	public uint8 FormatCode;
	public uint8 RealFormatCode;
	public uint16 Reserved;
	public void* Type;
	public uint32 CtxtFlags;
	public uint32 CtxtID;
}

#endregion

#region Functions
public static
{
	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IUnknown_QueryInterface_Proxy(IUnknown* This, in Guid riid, void** ppvObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IUnknown_AddRef_Proxy(IUnknown* This);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IUnknown_Release_Proxy(IUnknown* This);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingCopy(void* SourceBinding, void** DestinationBinding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingFree(void** Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingSetOption(void* hBinding, uint32 option, uint optionValue);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqOption(void* hBinding, uint32 option, uint* pOptionValue);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingFromStringBindingA(uint8* StringBinding, void** Binding);
	public static RPC_STATUS RpcBindingFromStringBinding(uint8* StringBinding, void** Binding) => RpcBindingFromStringBindingA(StringBinding, Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingFromStringBindingW(uint16* StringBinding, void** Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSsGetContextBinding(void* ContextHandle, void** Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqMaxCalls(void* Binding, uint32* MaxCalls);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqObject(void* Binding, Guid* ObjectUuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingReset(void* Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingSetObject(void* Binding, Guid* ObjectUuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtInqDefaultProtectLevel(uint32 AuthnSvc, uint32* AuthnLevel);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingToStringBindingA(void* Binding, uint8** StringBinding);
	public static RPC_STATUS RpcBindingToStringBinding(void* Binding, uint8** StringBinding) => RpcBindingToStringBindingA(Binding, StringBinding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingToStringBindingW(void* Binding, uint16** StringBinding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingVectorFree(RPC_BINDING_VECTOR** BindingVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcStringBindingComposeA(uint8* ObjUuid, uint8* ProtSeq, uint8* NetworkAddr, uint8* Endpoint, uint8* Options, uint8** StringBinding);
	public static RPC_STATUS RpcStringBindingCompose(uint8* ObjUuid, uint8* ProtSeq, uint8* NetworkAddr, uint8* Endpoint, uint8* Options, uint8** StringBinding) => RpcStringBindingComposeA(ObjUuid, ProtSeq, NetworkAddr, Endpoint, Options, StringBinding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcStringBindingComposeW(uint16* ObjUuid, uint16* ProtSeq, uint16* NetworkAddr, uint16* Endpoint, uint16* Options, uint16** StringBinding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcStringBindingParseA(uint8* StringBinding, uint8** ObjUuid, uint8** Protseq, uint8** NetworkAddr, uint8** Endpoint, uint8** NetworkOptions);
	public static RPC_STATUS RpcStringBindingParse(uint8* StringBinding, uint8** ObjUuid, uint8** Protseq, uint8** NetworkAddr, uint8** Endpoint, uint8** NetworkOptions) => RpcStringBindingParseA(StringBinding, ObjUuid, Protseq, NetworkAddr, Endpoint, NetworkOptions);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcStringBindingParseW(uint16* StringBinding, uint16** ObjUuid, uint16** Protseq, uint16** NetworkAddr, uint16** Endpoint, uint16** NetworkOptions);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcStringFreeA(uint8** String);
	public static RPC_STATUS RpcStringFree(uint8** String) => RpcStringFreeA(String);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcStringFreeW(uint16** String);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcIfInqId(void* RpcIfHandle, RPC_IF_ID* RpcIfId);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNetworkIsProtseqValidA(uint8* Protseq);
	public static RPC_STATUS RpcNetworkIsProtseqValid(uint8* Protseq) => RpcNetworkIsProtseqValidA(Protseq);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNetworkIsProtseqValidW(uint16* Protseq);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtInqComTimeout(void* Binding, uint32* Timeout);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtSetComTimeout(void* Binding, uint32 Timeout);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtSetCancelTimeout(int32 Timeout);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNetworkInqProtseqsA(RPC_PROTSEQ_VECTORA** ProtseqVector);
	public static RPC_STATUS RpcNetworkInqProtseqs(RPC_PROTSEQ_VECTORA** ProtseqVector) => RpcNetworkInqProtseqsA(ProtseqVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNetworkInqProtseqsW(RPC_PROTSEQ_VECTORW** ProtseqVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcObjectInqType(Guid* ObjUuid, Guid* TypeUuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcObjectSetInqFn(RPC_OBJECT_INQ_FN InquiryFn);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcObjectSetType(Guid* ObjUuid, Guid* TypeUuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcProtseqVectorFreeA(RPC_PROTSEQ_VECTORA** ProtseqVector);
	public static RPC_STATUS RpcProtseqVectorFree(RPC_PROTSEQ_VECTORA** ProtseqVector) => RpcProtseqVectorFreeA(ProtseqVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcProtseqVectorFreeW(RPC_PROTSEQ_VECTORW** ProtseqVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInqBindings(RPC_BINDING_VECTOR** BindingVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInqBindingsEx(void* SecurityDescriptor, RPC_BINDING_VECTOR** BindingVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInqIf(void* IfSpec, Guid* MgrTypeUuid, void** MgrEpv);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerListen(uint32 MinimumCallThreads, uint32 MaxCalls, uint32 DontWait);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerRegisterIf(void* IfSpec, Guid* MgrTypeUuid, void* MgrEpv);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerRegisterIfEx(void* IfSpec, Guid* MgrTypeUuid, void* MgrEpv, uint32 Flags, uint32 MaxCalls, RPC_IF_CALLBACK_FN IfCallback);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerRegisterIf2(void* IfSpec, Guid* MgrTypeUuid, void* MgrEpv, uint32 Flags, uint32 MaxCalls, uint32 MaxRpcSize, RPC_IF_CALLBACK_FN IfCallbackFn);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerRegisterIf3(void* IfSpec, Guid* MgrTypeUuid, void* MgrEpv, uint32 Flags, uint32 MaxCalls, uint32 MaxRpcSize, RPC_IF_CALLBACK_FN IfCallback, void* SecurityDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUnregisterIf(void* IfSpec, Guid* MgrTypeUuid, uint32 WaitForCallsToComplete);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUnregisterIfEx(void* IfSpec, Guid* MgrTypeUuid, int32 RundownContextHandles);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseAllProtseqs(uint32 MaxCalls, void* SecurityDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseAllProtseqsEx(uint32 MaxCalls, void* SecurityDescriptor, RPC_POLICY* Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseAllProtseqsIf(uint32 MaxCalls, void* IfSpec, void* SecurityDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseAllProtseqsIfEx(uint32 MaxCalls, void* IfSpec, void* SecurityDescriptor, RPC_POLICY* Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqA(uint8* Protseq, uint32 MaxCalls, void* SecurityDescriptor);
	public static RPC_STATUS RpcServerUseProtseq(uint8* Protseq, uint32 MaxCalls, void* SecurityDescriptor) => RpcServerUseProtseqA(Protseq, MaxCalls, SecurityDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqExA(uint8* Protseq, uint32 MaxCalls, void* SecurityDescriptor, RPC_POLICY* Policy);
	public static RPC_STATUS RpcServerUseProtseqEx(uint8* Protseq, uint32 MaxCalls, void* SecurityDescriptor, RPC_POLICY* Policy) => RpcServerUseProtseqExA(Protseq, MaxCalls, SecurityDescriptor, Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqW(uint16* Protseq, uint32 MaxCalls, void* SecurityDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqExW(uint16* Protseq, uint32 MaxCalls, void* SecurityDescriptor, RPC_POLICY* Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqEpA(uint8* Protseq, uint32 MaxCalls, uint8* Endpoint, void* SecurityDescriptor);
	public static RPC_STATUS RpcServerUseProtseqEp(uint8* Protseq, uint32 MaxCalls, uint8* Endpoint, void* SecurityDescriptor) => RpcServerUseProtseqEpA(Protseq, MaxCalls, Endpoint, SecurityDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqEpExA(uint8* Protseq, uint32 MaxCalls, uint8* Endpoint, void* SecurityDescriptor, RPC_POLICY* Policy);
	public static RPC_STATUS RpcServerUseProtseqEpEx(uint8* Protseq, uint32 MaxCalls, uint8* Endpoint, void* SecurityDescriptor, RPC_POLICY* Policy) => RpcServerUseProtseqEpExA(Protseq, MaxCalls, Endpoint, SecurityDescriptor, Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqEpW(uint16* Protseq, uint32 MaxCalls, uint16* Endpoint, void* SecurityDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqEpExW(uint16* Protseq, uint32 MaxCalls, uint16* Endpoint, void* SecurityDescriptor, RPC_POLICY* Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqIfA(uint8* Protseq, uint32 MaxCalls, void* IfSpec, void* SecurityDescriptor);
	public static RPC_STATUS RpcServerUseProtseqIf(uint8* Protseq, uint32 MaxCalls, void* IfSpec, void* SecurityDescriptor) => RpcServerUseProtseqIfA(Protseq, MaxCalls, IfSpec, SecurityDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqIfExA(uint8* Protseq, uint32 MaxCalls, void* IfSpec, void* SecurityDescriptor, RPC_POLICY* Policy);
	public static RPC_STATUS RpcServerUseProtseqIfEx(uint8* Protseq, uint32 MaxCalls, void* IfSpec, void* SecurityDescriptor, RPC_POLICY* Policy) => RpcServerUseProtseqIfExA(Protseq, MaxCalls, IfSpec, SecurityDescriptor, Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqIfW(uint16* Protseq, uint32 MaxCalls, void* IfSpec, void* SecurityDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUseProtseqIfExW(uint16* Protseq, uint32 MaxCalls, void* IfSpec, void* SecurityDescriptor, RPC_POLICY* Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcServerYield();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtStatsVectorFree(RPC_STATS_VECTOR** StatsVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtInqStats(void* Binding, RPC_STATS_VECTOR** Statistics);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtIsServerListening(void* Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtStopServerListening(void* Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtWaitServerListen();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtSetServerStackSize(uint32 ThreadStackSize);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcSsDontSerializeContext();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtEnableIdleCleanup();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtInqIfIds(void* Binding, RPC_IF_ID_VECTOR** IfIdVector);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcIfIdVectorFree(RPC_IF_ID_VECTOR** IfIdVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtInqServerPrincNameA(void* Binding, uint32 AuthnSvc, uint8** ServerPrincName);
	public static RPC_STATUS RpcMgmtInqServerPrincName(void* Binding, uint32 AuthnSvc, uint8** ServerPrincName) => RpcMgmtInqServerPrincNameA(Binding, AuthnSvc, ServerPrincName);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtInqServerPrincNameW(void* Binding, uint32 AuthnSvc, uint16** ServerPrincName);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInqDefaultPrincNameA(uint32 AuthnSvc, uint8** PrincName);
	public static RPC_STATUS RpcServerInqDefaultPrincName(uint32 AuthnSvc, uint8** PrincName) => RpcServerInqDefaultPrincNameA(AuthnSvc, PrincName);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInqDefaultPrincNameW(uint32 AuthnSvc, uint16** PrincName);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcEpResolveBinding(void* Binding, void* IfSpec);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingInqEntryNameA(void* Binding, uint32 EntryNameSyntax, uint8** EntryName);
	public static RPC_STATUS RpcNsBindingInqEntryName(void* Binding, uint32 EntryNameSyntax, uint8** EntryName) => RpcNsBindingInqEntryNameA(Binding, EntryNameSyntax, EntryName);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingInqEntryNameW(void* Binding, uint32 EntryNameSyntax, uint16** EntryName);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingCreateA(RPC_BINDING_HANDLE_TEMPLATE_V1_A* Template, RPC_BINDING_HANDLE_SECURITY_V1_A* Security, RPC_BINDING_HANDLE_OPTIONS_V1* Options, void** Binding);
	public static RPC_STATUS RpcBindingCreate(RPC_BINDING_HANDLE_TEMPLATE_V1_A* Template, RPC_BINDING_HANDLE_SECURITY_V1_A* Security, RPC_BINDING_HANDLE_OPTIONS_V1* Options, void** Binding) => RpcBindingCreateA(Template, Security, Options, Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingCreateW(RPC_BINDING_HANDLE_TEMPLATE_V1_W* Template, RPC_BINDING_HANDLE_SECURITY_V1_W* Security, RPC_BINDING_HANDLE_OPTIONS_V1* Options, void** Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInqBindingHandle(void** Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcImpersonateClient(void* BindingHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcImpersonateClient2(void* BindingHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcRevertToSelfEx(void* BindingHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcRevertToSelf();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcImpersonateClientContainer(void* BindingHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcRevertContainerImpersonation();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqAuthClientA(void* ClientBinding, void** Privs, uint8** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, uint32* AuthzSvc);
	public static RPC_STATUS RpcBindingInqAuthClient(void* ClientBinding, void** Privs, uint8** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, uint32* AuthzSvc) => RpcBindingInqAuthClientA(ClientBinding, Privs, ServerPrincName, AuthnLevel, AuthnSvc, AuthzSvc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqAuthClientW(void* ClientBinding, void** Privs, uint16** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, uint32* AuthzSvc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqAuthClientExA(void* ClientBinding, void** Privs, uint8** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, uint32* AuthzSvc, uint32 Flags);
	public static RPC_STATUS RpcBindingInqAuthClientEx(void* ClientBinding, void** Privs, uint8** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, uint32* AuthzSvc, uint32 Flags) => RpcBindingInqAuthClientExA(ClientBinding, Privs, ServerPrincName, AuthnLevel, AuthnSvc, AuthzSvc, Flags);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqAuthClientExW(void* ClientBinding, void** Privs, uint16** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, uint32* AuthzSvc, uint32 Flags);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqAuthInfoA(void* Binding, uint8** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, void** AuthIdentity, uint32* AuthzSvc);
	public static RPC_STATUS RpcBindingInqAuthInfo(void* Binding, uint8** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, void** AuthIdentity, uint32* AuthzSvc) => RpcBindingInqAuthInfoA(Binding, ServerPrincName, AuthnLevel, AuthnSvc, AuthIdentity, AuthzSvc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqAuthInfoW(void* Binding, uint16** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, void** AuthIdentity, uint32* AuthzSvc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingSetAuthInfoA(void* Binding, uint8* ServerPrincName, uint32 AuthnLevel, uint32 AuthnSvc, void* AuthIdentity, uint32 AuthzSvc);
	public static RPC_STATUS RpcBindingSetAuthInfo(void* Binding, uint8* ServerPrincName, uint32 AuthnLevel, uint32 AuthnSvc, void* AuthIdentity, uint32 AuthzSvc) => RpcBindingSetAuthInfoA(Binding, ServerPrincName, AuthnLevel, AuthnSvc, AuthIdentity, AuthzSvc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingSetAuthInfoExA(void* Binding, uint8* ServerPrincName, uint32 AuthnLevel, uint32 AuthnSvc, void* AuthIdentity, uint32 AuthzSvc, RPC_SECURITY_QOS* SecurityQos);
	public static RPC_STATUS RpcBindingSetAuthInfoEx(void* Binding, uint8* ServerPrincName, uint32 AuthnLevel, uint32 AuthnSvc, void* AuthIdentity, uint32 AuthzSvc, RPC_SECURITY_QOS* SecurityQos) => RpcBindingSetAuthInfoExA(Binding, ServerPrincName, AuthnLevel, AuthnSvc, AuthIdentity, AuthzSvc, SecurityQos);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingSetAuthInfoW(void* Binding, uint16* ServerPrincName, uint32 AuthnLevel, uint32 AuthnSvc, void* AuthIdentity, uint32 AuthzSvc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingSetAuthInfoExW(void* Binding, uint16* ServerPrincName, uint32 AuthnLevel, uint32 AuthnSvc, void* AuthIdentity, uint32 AuthzSvc, RPC_SECURITY_QOS* SecurityQOS);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqAuthInfoExA(void* Binding, uint8** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, void** AuthIdentity, uint32* AuthzSvc, uint32 RpcQosVersion, RPC_SECURITY_QOS* SecurityQOS);
	public static RPC_STATUS RpcBindingInqAuthInfoEx(void* Binding, uint8** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, void** AuthIdentity, uint32* AuthzSvc, uint32 RpcQosVersion, RPC_SECURITY_QOS* SecurityQOS) => RpcBindingInqAuthInfoExA(Binding, ServerPrincName, AuthnLevel, AuthnSvc, AuthIdentity, AuthzSvc, RpcQosVersion, SecurityQOS);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingInqAuthInfoExW(void* Binding, uint16** ServerPrincName, uint32* AuthnLevel, uint32* AuthnSvc, void** AuthIdentity, uint32* AuthzSvc, uint32 RpcQosVersion, RPC_SECURITY_QOS* SecurityQOS);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerCompleteSecurityCallback(void* BindingHandle, RPC_STATUS Status);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerRegisterAuthInfoA(uint8* ServerPrincName, uint32 AuthnSvc, RPC_AUTH_KEY_RETRIEVAL_FN GetKeyFn, void* Arg);
	public static RPC_STATUS RpcServerRegisterAuthInfo(uint8* ServerPrincName, uint32 AuthnSvc, RPC_AUTH_KEY_RETRIEVAL_FN GetKeyFn, void* Arg) => RpcServerRegisterAuthInfoA(ServerPrincName, AuthnSvc, GetKeyFn, Arg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerRegisterAuthInfoW(uint16* ServerPrincName, uint32 AuthnSvc, RPC_AUTH_KEY_RETRIEVAL_FN GetKeyFn, void* Arg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingServerFromClient(void* ClientBinding, void** ServerBinding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcRaiseException(RPC_STATUS exception);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcTestCancel();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerTestCancel(void* BindingHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcCancelThread(void* Thread);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcCancelThreadEx(void* Thread, int32 Timeout);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS UuidCreate(Guid* Uuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS UuidCreateSequential(Guid* Uuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS UuidToStringA(in Guid Uuid, uint8** StringUuid);
	public static RPC_STATUS UuidToString(in Guid Uuid, uint8** StringUuid) => UuidToStringA(Uuid, StringUuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS UuidFromStringA(uint8* StringUuid, Guid* Uuid);
	public static RPC_STATUS UuidFromString(uint8* StringUuid, Guid* Uuid) => UuidFromStringA(StringUuid, Uuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS UuidToStringW(in Guid Uuid, uint16** StringUuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS UuidFromStringW(uint16* StringUuid, Guid* Uuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 UuidCompare(Guid* Uuid1, Guid* Uuid2, RPC_STATUS* Status);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS UuidCreateNil(Guid* NilUuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 UuidEqual(Guid* Uuid1, Guid* Uuid2, RPC_STATUS* Status);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 UuidHash(Guid* Uuid, RPC_STATUS* Status);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 UuidIsNil(Guid* Uuid, RPC_STATUS* Status);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcEpRegisterNoReplaceA(void* IfSpec, RPC_BINDING_VECTOR* BindingVector, UUID_VECTOR* UuidVector, uint8* Annotation);
	public static RPC_STATUS RpcEpRegisterNoReplace(void* IfSpec, RPC_BINDING_VECTOR* BindingVector, UUID_VECTOR* UuidVector, uint8* Annotation) => RpcEpRegisterNoReplaceA(IfSpec, BindingVector, UuidVector, Annotation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcEpRegisterNoReplaceW(void* IfSpec, RPC_BINDING_VECTOR* BindingVector, UUID_VECTOR* UuidVector, uint16* Annotation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcEpRegisterA(void* IfSpec, RPC_BINDING_VECTOR* BindingVector, UUID_VECTOR* UuidVector, uint8* Annotation);
	public static RPC_STATUS RpcEpRegister(void* IfSpec, RPC_BINDING_VECTOR* BindingVector, UUID_VECTOR* UuidVector, uint8* Annotation) => RpcEpRegisterA(IfSpec, BindingVector, UuidVector, Annotation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcEpRegisterW(void* IfSpec, RPC_BINDING_VECTOR* BindingVector, UUID_VECTOR* UuidVector, uint16* Annotation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcEpUnregister(void* IfSpec, RPC_BINDING_VECTOR* BindingVector, UUID_VECTOR* UuidVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS DceErrorInqTextA(RPC_STATUS RpcStatus, uint8* ErrorText);
	public static RPC_STATUS DceErrorInqText(RPC_STATUS RpcStatus, uint8* ErrorText) => DceErrorInqTextA(RpcStatus, ErrorText);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS DceErrorInqTextW(RPC_STATUS RpcStatus, uint16* ErrorText);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtEpEltInqBegin(void* EpBinding, uint32 InquiryType, RPC_IF_ID* IfId, uint32 VersOption, Guid* ObjectUuid, void*** InquiryContext);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtEpEltInqDone(void*** InquiryContext);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtEpEltInqNextA(void** InquiryContext, RPC_IF_ID* IfId, void** Binding, Guid* ObjectUuid, uint8** Annotation);
	public static RPC_STATUS RpcMgmtEpEltInqNext(void** InquiryContext, RPC_IF_ID* IfId, void** Binding, Guid* ObjectUuid, uint8** Annotation) => RpcMgmtEpEltInqNextA(InquiryContext, IfId, Binding, ObjectUuid, Annotation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtEpEltInqNextW(void** InquiryContext, RPC_IF_ID* IfId, void** Binding, Guid* ObjectUuid, uint16** Annotation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtEpUnregister(void* EpBinding, RPC_IF_ID* IfId, void* Binding, Guid* ObjectUuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcMgmtSetAuthorizationFn(RPC_MGMT_AUTHORIZATION_FN AuthorizationFn);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RpcExceptionFilter(uint32 ExceptionCode);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInterfaceGroupCreateW(RPC_INTERFACE_TEMPLATEW* Interfaces, uint32 NumIfs, RPC_ENDPOINT_TEMPLATEW* Endpoints, uint32 NumEndpoints, uint32 IdlePeriod, RPC_INTERFACE_GROUP_IDLE_CALLBACK_FN IdleCallbackFn, void* IdleCallbackContext, void** IfGroup);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInterfaceGroupCreateA(RPC_INTERFACE_TEMPLATEA* Interfaces, uint32 NumIfs, RPC_ENDPOINT_TEMPLATEA* Endpoints, uint32 NumEndpoints, uint32 IdlePeriod, RPC_INTERFACE_GROUP_IDLE_CALLBACK_FN IdleCallbackFn, void* IdleCallbackContext, void** IfGroup);
	public static RPC_STATUS RpcServerInterfaceGroupCreate(RPC_INTERFACE_TEMPLATEA* Interfaces, uint32 NumIfs, RPC_ENDPOINT_TEMPLATEA* Endpoints, uint32 NumEndpoints, uint32 IdlePeriod, RPC_INTERFACE_GROUP_IDLE_CALLBACK_FN IdleCallbackFn, void* IdleCallbackContext, void** IfGroup) => RpcServerInterfaceGroupCreateA(Interfaces, NumIfs, Endpoints, NumEndpoints, IdlePeriod, IdleCallbackFn, IdleCallbackContext, IfGroup);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInterfaceGroupClose(void* IfGroup);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInterfaceGroupActivate(void* IfGroup);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInterfaceGroupDeactivate(void* IfGroup, uint32 ForceDeactivation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInterfaceGroupInqBindings(void* IfGroup, RPC_BINDING_VECTOR** BindingVector);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcNegotiateTransferSyntax(RPC_MESSAGE* Message);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcGetBuffer(RPC_MESSAGE* Message);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcGetBufferWithObject(RPC_MESSAGE* Message, Guid* ObjectUuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcSendReceive(RPC_MESSAGE* Message);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcFreeBuffer(RPC_MESSAGE* Message);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcSend(RPC_MESSAGE* Message);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcReceive(RPC_MESSAGE* Message, uint32 Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcFreePipeBuffer(RPC_MESSAGE* Message);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcReallocPipeBuffer(RPC_MESSAGE* Message, uint32 NewSize);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void I_RpcRequestMutex(void** Mutex);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void I_RpcClearMutex(void* Mutex);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void I_RpcDeleteMutex(void* Mutex);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* I_RpcAllocate(uint32 Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void I_RpcFree(void* Object);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void I_RpcPauseExecution(uint32 Milliseconds);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcGetExtendedError();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcSystemHandleTypeSpecificWork(void* Handle, uint8 ActualType, uint8 IdlType, LRPC_SYSTEM_HANDLE_MARSHAL_DIRECTION MarshalDirection);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* I_RpcGetCurrentCallHandle();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcNsInterfaceExported(uint32 EntryNameSyntax, uint16* EntryName, RPC_SERVER_INTERFACE* RpcInterfaceInformation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcNsInterfaceUnexported(uint32 EntryNameSyntax, uint16* EntryName, RPC_SERVER_INTERFACE* RpcInterfaceInformation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingToStaticStringBindingW(void* Binding, uint16** StringBinding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingInqSecurityContext(void* Binding, void** SecurityContextHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingInqSecurityContextKeyInfo(void* Binding, void* KeyInfo);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingInqWireIdForSnego(void* Binding, uint8* WireId);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingInqMarshalledTargetInfo(void* Binding, uint32* MarshalledTargetInfoSize, uint8** MarshalledTargetInfo);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingInqLocalClientPID(void* Binding, uint32* Pid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingHandleToAsyncHandle(void* Binding, void** AsyncHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcNsBindingSetEntryNameW(void* Binding, uint32 EntryNameSyntax, uint16* EntryName);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcNsBindingSetEntryNameA(void* Binding, uint32 EntryNameSyntax, uint8* EntryName);
	public static RPC_STATUS I_RpcNsBindingSetEntryName(void* Binding, uint32 EntryNameSyntax, uint8* EntryName) => I_RpcNsBindingSetEntryNameA(Binding, EntryNameSyntax, EntryName);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerUseProtseqEp2A(uint8* NetworkAddress, uint8* Protseq, uint32 MaxCalls, uint8* Endpoint, void* SecurityDescriptor, void* Policy);
	public static RPC_STATUS I_RpcServerUseProtseqEp2(uint8* NetworkAddress, uint8* Protseq, uint32 MaxCalls, uint8* Endpoint, void* SecurityDescriptor, void* Policy) => I_RpcServerUseProtseqEp2A(NetworkAddress, Protseq, MaxCalls, Endpoint, SecurityDescriptor, Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerUseProtseqEp2W(uint16* NetworkAddress, uint16* Protseq, uint32 MaxCalls, uint16* Endpoint, void* SecurityDescriptor, void* Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerUseProtseq2W(uint16* NetworkAddress, uint16* Protseq, uint32 MaxCalls, void* SecurityDescriptor, void* Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerUseProtseq2A(uint8* NetworkAddress, uint8* Protseq, uint32 MaxCalls, void* SecurityDescriptor, void* Policy);
	public static RPC_STATUS I_RpcServerUseProtseq2(uint8* NetworkAddress, uint8* Protseq, uint32 MaxCalls, void* SecurityDescriptor, void* Policy) => I_RpcServerUseProtseq2A(NetworkAddress, Protseq, MaxCalls, SecurityDescriptor, Policy);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerStartService(uint16* Protseq, uint16* Endpoint, void* IfSpec);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingInqDynamicEndpointW(void* Binding, uint16** DynamicEndpoint);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingInqDynamicEndpointA(void* Binding, uint8** DynamicEndpoint);
	public static RPC_STATUS I_RpcBindingInqDynamicEndpoint(void* Binding, uint8** DynamicEndpoint) => I_RpcBindingInqDynamicEndpointA(Binding, DynamicEndpoint);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerCheckClientRestriction(void* Context);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingInqTransportType(void* Binding, uint32* Type);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcIfInqTransferSyntaxes(void* RpcIfHandle, RPC_TRANSFER_SYNTAX* TransferSyntaxes, uint32 TransferSyntaxSize, uint32* TransferSyntaxCount);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_UuidCreate(Guid* Uuid);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingCopy(void* SourceBinding, void** DestinationBinding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingIsClientLocal(void* BindingHandle, uint32* ClientLocalFlag);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingCreateNP(uint16* ServerName, uint16* ServiceName, uint16* NetworkOptions, void** Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void I_RpcSsDontSerializeContext();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerRegisterForwardFunction(RPC_FORWARD_FUNCTION* pForwardFunction);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_ADDRESS_CHANGE_FN* I_RpcServerInqAddressChangeFn();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerSetAddressChangeFn(RPC_ADDRESS_CHANGE_FN* pAddressChangeFn);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerInqLocalConnAddress(void* Binding, void* Buffer, uint32* BufferSize, uint32* AddressFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerInqRemoteConnAddress(void* Binding, void* Buffer, uint32* BufferSize, uint32* AddressFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void I_RpcSessionStrictContextHandle();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcTurnOnEEInfoPropagation();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerInqTransportType(uint32* Type);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 I_RpcMapWin32Status(RPC_STATUS Status);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void I_RpcRecordCalloutFailure(RPC_STATUS RpcStatus, RDR_CALLOUT_STATE* CallOutState, uint16* DllName);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcMgmtEnableDedicatedThreadPool();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcGetDefaultSD(void** ppSecurityDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcOpenClientProcess(void* Binding, uint32 DesiredAccess, void** ClientProcess);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingIsServerLocal(void* Binding, uint32* ServerLocalFlag);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingSetPrivateOption(void* hBinding, uint32 option, uint optionValue);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerSubscribeForDisconnectNotification(void* Binding, void* hEvent);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerGetAssociationID(void* Binding, uint32* AssociationID);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 I_RpcServerDisableExceptionFilter();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerSubscribeForDisconnectNotification2(void* Binding, void* hEvent, Guid* SubscriptionId);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcServerUnsubscribeForDisconnectNotification(void* Binding, Guid SubscriptionId);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingExportA(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, RPC_BINDING_VECTOR* BindingVec, UUID_VECTOR* ObjectUuidVec);
	public static RPC_STATUS RpcNsBindingExport(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, RPC_BINDING_VECTOR* BindingVec, UUID_VECTOR* ObjectUuidVec) => RpcNsBindingExportA(EntryNameSyntax, EntryName, IfSpec, BindingVec, ObjectUuidVec);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingUnexportA(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, UUID_VECTOR* ObjectUuidVec);
	public static RPC_STATUS RpcNsBindingUnexport(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, UUID_VECTOR* ObjectUuidVec) => RpcNsBindingUnexportA(EntryNameSyntax, EntryName, IfSpec, ObjectUuidVec);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingExportW(uint32 EntryNameSyntax, uint16* EntryName, void* IfSpec, RPC_BINDING_VECTOR* BindingVec, UUID_VECTOR* ObjectUuidVec);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingUnexportW(uint32 EntryNameSyntax, uint16* EntryName, void* IfSpec, UUID_VECTOR* ObjectUuidVec);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingExportPnPA(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, UUID_VECTOR* ObjectVector);
	public static RPC_STATUS RpcNsBindingExportPnP(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, UUID_VECTOR* ObjectVector) => RpcNsBindingExportPnPA(EntryNameSyntax, EntryName, IfSpec, ObjectVector);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingUnexportPnPA(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, UUID_VECTOR* ObjectVector);
	public static RPC_STATUS RpcNsBindingUnexportPnP(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, UUID_VECTOR* ObjectVector) => RpcNsBindingUnexportPnPA(EntryNameSyntax, EntryName, IfSpec, ObjectVector);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingExportPnPW(uint32 EntryNameSyntax, uint16* EntryName, void* IfSpec, UUID_VECTOR* ObjectVector);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingUnexportPnPW(uint32 EntryNameSyntax, uint16* EntryName, void* IfSpec, UUID_VECTOR* ObjectVector);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingLookupBeginA(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, Guid* ObjUuid, uint32 BindingMaxCount, void** LookupContext);
	public static RPC_STATUS RpcNsBindingLookupBegin(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, Guid* ObjUuid, uint32 BindingMaxCount, void** LookupContext) => RpcNsBindingLookupBeginA(EntryNameSyntax, EntryName, IfSpec, ObjUuid, BindingMaxCount, LookupContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingLookupBeginW(uint32 EntryNameSyntax, uint16* EntryName, void* IfSpec, Guid* ObjUuid, uint32 BindingMaxCount, void** LookupContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingLookupNext(void* LookupContext, RPC_BINDING_VECTOR** BindingVec);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingLookupDone(void** LookupContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupDeleteA(GROUP_NAME_SYNTAX GroupNameSyntax, uint8* GroupName);
	public static RPC_STATUS RpcNsGroupDelete(GROUP_NAME_SYNTAX GroupNameSyntax, uint8* GroupName) => RpcNsGroupDeleteA(GroupNameSyntax, GroupName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupMbrAddA(uint32 GroupNameSyntax, uint8* GroupName, uint32 MemberNameSyntax, uint8* MemberName);
	public static RPC_STATUS RpcNsGroupMbrAdd(uint32 GroupNameSyntax, uint8* GroupName, uint32 MemberNameSyntax, uint8* MemberName) => RpcNsGroupMbrAddA(GroupNameSyntax, GroupName, MemberNameSyntax, MemberName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupMbrRemoveA(uint32 GroupNameSyntax, uint8* GroupName, uint32 MemberNameSyntax, uint8* MemberName);
	public static RPC_STATUS RpcNsGroupMbrRemove(uint32 GroupNameSyntax, uint8* GroupName, uint32 MemberNameSyntax, uint8* MemberName) => RpcNsGroupMbrRemoveA(GroupNameSyntax, GroupName, MemberNameSyntax, MemberName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupMbrInqBeginA(uint32 GroupNameSyntax, uint8* GroupName, uint32 MemberNameSyntax, void** InquiryContext);
	public static RPC_STATUS RpcNsGroupMbrInqBegin(uint32 GroupNameSyntax, uint8* GroupName, uint32 MemberNameSyntax, void** InquiryContext) => RpcNsGroupMbrInqBeginA(GroupNameSyntax, GroupName, MemberNameSyntax, InquiryContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupMbrInqNextA(void* InquiryContext, uint8** MemberName);
	public static RPC_STATUS RpcNsGroupMbrInqNext(void* InquiryContext, uint8** MemberName) => RpcNsGroupMbrInqNextA(InquiryContext, MemberName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupDeleteW(GROUP_NAME_SYNTAX GroupNameSyntax, uint16* GroupName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupMbrAddW(uint32 GroupNameSyntax, uint16* GroupName, uint32 MemberNameSyntax, uint16* MemberName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupMbrRemoveW(uint32 GroupNameSyntax, uint16* GroupName, uint32 MemberNameSyntax, uint16* MemberName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupMbrInqBeginW(uint32 GroupNameSyntax, uint16* GroupName, uint32 MemberNameSyntax, void** InquiryContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupMbrInqNextW(void* InquiryContext, uint16** MemberName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsGroupMbrInqDone(void** InquiryContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileDeleteA(uint32 ProfileNameSyntax, uint8* ProfileName);
	public static RPC_STATUS RpcNsProfileDelete(uint32 ProfileNameSyntax, uint8* ProfileName) => RpcNsProfileDeleteA(ProfileNameSyntax, ProfileName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileEltAddA(uint32 ProfileNameSyntax, uint8* ProfileName, RPC_IF_ID* IfId, uint32 MemberNameSyntax, uint8* MemberName, uint32 Priority, uint8* Annotation);
	public static RPC_STATUS RpcNsProfileEltAdd(uint32 ProfileNameSyntax, uint8* ProfileName, RPC_IF_ID* IfId, uint32 MemberNameSyntax, uint8* MemberName, uint32 Priority, uint8* Annotation) => RpcNsProfileEltAddA(ProfileNameSyntax, ProfileName, IfId, MemberNameSyntax, MemberName, Priority, Annotation);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileEltRemoveA(uint32 ProfileNameSyntax, uint8* ProfileName, RPC_IF_ID* IfId, uint32 MemberNameSyntax, uint8* MemberName);
	public static RPC_STATUS RpcNsProfileEltRemove(uint32 ProfileNameSyntax, uint8* ProfileName, RPC_IF_ID* IfId, uint32 MemberNameSyntax, uint8* MemberName) => RpcNsProfileEltRemoveA(ProfileNameSyntax, ProfileName, IfId, MemberNameSyntax, MemberName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileEltInqBeginA(uint32 ProfileNameSyntax, uint8* ProfileName, uint32 InquiryType, RPC_IF_ID* IfId, uint32 VersOption, uint32 MemberNameSyntax, uint8* MemberName, void** InquiryContext);
	public static RPC_STATUS RpcNsProfileEltInqBegin(uint32 ProfileNameSyntax, uint8* ProfileName, uint32 InquiryType, RPC_IF_ID* IfId, uint32 VersOption, uint32 MemberNameSyntax, uint8* MemberName, void** InquiryContext) => RpcNsProfileEltInqBeginA(ProfileNameSyntax, ProfileName, InquiryType, IfId, VersOption, MemberNameSyntax, MemberName, InquiryContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileEltInqNextA(void* InquiryContext, RPC_IF_ID* IfId, uint8** MemberName, uint32* Priority, uint8** Annotation);
	public static RPC_STATUS RpcNsProfileEltInqNext(void* InquiryContext, RPC_IF_ID* IfId, uint8** MemberName, uint32* Priority, uint8** Annotation) => RpcNsProfileEltInqNextA(InquiryContext, IfId, MemberName, Priority, Annotation);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileDeleteW(uint32 ProfileNameSyntax, uint16* ProfileName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileEltAddW(uint32 ProfileNameSyntax, uint16* ProfileName, RPC_IF_ID* IfId, uint32 MemberNameSyntax, uint16* MemberName, uint32 Priority, uint16* Annotation);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileEltRemoveW(uint32 ProfileNameSyntax, uint16* ProfileName, RPC_IF_ID* IfId, uint32 MemberNameSyntax, uint16* MemberName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileEltInqBeginW(uint32 ProfileNameSyntax, uint16* ProfileName, uint32 InquiryType, RPC_IF_ID* IfId, uint32 VersOption, uint32 MemberNameSyntax, uint16* MemberName, void** InquiryContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileEltInqNextW(void* InquiryContext, RPC_IF_ID* IfId, uint16** MemberName, uint32* Priority, uint16** Annotation);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsProfileEltInqDone(void** InquiryContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsEntryObjectInqBeginA(uint32 EntryNameSyntax, uint8* EntryName, void** InquiryContext);
	public static RPC_STATUS RpcNsEntryObjectInqBegin(uint32 EntryNameSyntax, uint8* EntryName, void** InquiryContext) => RpcNsEntryObjectInqBeginA(EntryNameSyntax, EntryName, InquiryContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsEntryObjectInqBeginW(uint32 EntryNameSyntax, uint16* EntryName, void** InquiryContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsEntryObjectInqNext(void* InquiryContext, Guid* ObjUuid);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsEntryObjectInqDone(void** InquiryContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsEntryExpandNameA(uint32 EntryNameSyntax, uint8* EntryName, uint8** ExpandedName);
	public static RPC_STATUS RpcNsEntryExpandName(uint32 EntryNameSyntax, uint8* EntryName, uint8** ExpandedName) => RpcNsEntryExpandNameA(EntryNameSyntax, EntryName, ExpandedName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtBindingUnexportA(uint32 EntryNameSyntax, uint8* EntryName, RPC_IF_ID* IfId, uint32 VersOption, UUID_VECTOR* ObjectUuidVec);
	public static RPC_STATUS RpcNsMgmtBindingUnexport(uint32 EntryNameSyntax, uint8* EntryName, RPC_IF_ID* IfId, uint32 VersOption, UUID_VECTOR* ObjectUuidVec) => RpcNsMgmtBindingUnexportA(EntryNameSyntax, EntryName, IfId, VersOption, ObjectUuidVec);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtEntryCreateA(uint32 EntryNameSyntax, uint8* EntryName);
	public static RPC_STATUS RpcNsMgmtEntryCreate(uint32 EntryNameSyntax, uint8* EntryName) => RpcNsMgmtEntryCreateA(EntryNameSyntax, EntryName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtEntryDeleteA(uint32 EntryNameSyntax, uint8* EntryName);
	public static RPC_STATUS RpcNsMgmtEntryDelete(uint32 EntryNameSyntax, uint8* EntryName) => RpcNsMgmtEntryDeleteA(EntryNameSyntax, EntryName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtEntryInqIfIdsA(uint32 EntryNameSyntax, uint8* EntryName, RPC_IF_ID_VECTOR** IfIdVec);
	public static RPC_STATUS RpcNsMgmtEntryInqIfIds(uint32 EntryNameSyntax, uint8* EntryName, RPC_IF_ID_VECTOR** IfIdVec) => RpcNsMgmtEntryInqIfIdsA(EntryNameSyntax, EntryName, IfIdVec);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtHandleSetExpAge(void* NsHandle, uint32 ExpirationAge);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtInqExpAge(uint32* ExpirationAge);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtSetExpAge(uint32 ExpirationAge);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsEntryExpandNameW(uint32 EntryNameSyntax, uint16* EntryName, uint16** ExpandedName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtBindingUnexportW(uint32 EntryNameSyntax, uint16* EntryName, RPC_IF_ID* IfId, uint32 VersOption, UUID_VECTOR* ObjectUuidVec);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtEntryCreateW(uint32 EntryNameSyntax, uint16* EntryName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtEntryDeleteW(uint32 EntryNameSyntax, uint16* EntryName);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsMgmtEntryInqIfIdsW(uint32 EntryNameSyntax, uint16* EntryName, RPC_IF_ID_VECTOR** IfIdVec);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingImportBeginA(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, Guid* ObjUuid, void** ImportContext);
	public static RPC_STATUS RpcNsBindingImportBegin(uint32 EntryNameSyntax, uint8* EntryName, void* IfSpec, Guid* ObjUuid, void** ImportContext) => RpcNsBindingImportBeginA(EntryNameSyntax, EntryName, IfSpec, ObjUuid, ImportContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingImportBeginW(uint32 EntryNameSyntax, uint16* EntryName, void* IfSpec, Guid* ObjUuid, void** ImportContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingImportNext(void* ImportContext, void** Binding);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingImportDone(void** ImportContext);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcNsBindingSelect(RPC_BINDING_VECTOR* BindingVec, void** Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcAsyncRegisterInfo(RPC_ASYNC_STATE* pAsync);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcAsyncInitializeHandle(RPC_ASYNC_STATE* pAsync, uint32 Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcAsyncGetCallStatus(RPC_ASYNC_STATE* pAsync);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcAsyncCompleteCall(RPC_ASYNC_STATE* pAsync, void* Reply);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcAsyncAbortCall(RPC_ASYNC_STATE* pAsync, uint32 ExceptionCode);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcAsyncCancelCall(RPC_ASYNC_STATE* pAsync, BOOL fAbort);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcErrorStartEnumeration(RPC_ERROR_ENUM_HANDLE* EnumHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcErrorGetNextRecord(RPC_ERROR_ENUM_HANDLE* EnumHandle, BOOL CopyStrings, RPC_EXTENDED_ERROR_INFO* ErrorInfo);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcErrorEndEnumeration(RPC_ERROR_ENUM_HANDLE* EnumHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcErrorResetEnumeration(RPC_ERROR_ENUM_HANDLE* EnumHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcErrorGetNumberOfRecords(RPC_ERROR_ENUM_HANDLE* EnumHandle, int32* Records);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcErrorSaveErrorInfo(RPC_ERROR_ENUM_HANDLE* EnumHandle, void** ErrorBlob, uint* BlobSize);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcErrorLoadErrorInfo(void* ErrorBlob, uint BlobSize, RPC_ERROR_ENUM_HANDLE* EnumHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcErrorAddRecord(RPC_EXTENDED_ERROR_INFO* ErrorInfo);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcErrorClearInformation();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcGetAuthorizationContextForClient(void* ClientBinding, BOOL ImpersonateOnReturn, void* Reserved1, LARGE_INTEGER* pExpirationTime, LUID Reserved2, uint32 Reserved3, void* Reserved4, void** pAuthzClientContext);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcFreeAuthorizationContext(void** pAuthzClientContext);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSsContextLockExclusive(void* ServerBindingHandle, void* UserContext);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSsContextLockShared(void* ServerBindingHandle, void* UserContext);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInqCallAttributesW(void* ClientBinding, void* RpcCallAttributes);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerInqCallAttributesA(void* ClientBinding, void* RpcCallAttributes);
	public static RPC_STATUS RpcServerInqCallAttributes(void* ClientBinding, void* RpcCallAttributes) => RpcServerInqCallAttributesA(ClientBinding, RpcCallAttributes);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerSubscribeForNotification(void* Binding, RPC_NOTIFICATIONS Notification, RPC_NOTIFICATION_TYPES NotificationType, RPC_ASYNC_NOTIFICATION_INFO* NotificationInfo);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcServerUnsubscribeForNotification(void* Binding, RPC_NOTIFICATIONS Notification, uint32* NotificationsQueued);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingBind(RPC_ASYNC_STATE* pAsync, void* Binding, void* IfSpec);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcBindingUnbind(void* Binding);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcAsyncSetHandle(RPC_MESSAGE* Message, RPC_ASYNC_STATE* pAsync);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcAsyncAbortCall(RPC_ASYNC_STATE* pAsync, uint32 ExceptionCode);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 I_RpcExceptionFilter(uint32 ExceptionCode);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcBindingInqClientTokenAttributes(void* Binding, LUID* TokenId, LUID* AuthenticationId, LUID* ModifiedId);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcNsGetBuffer(RPC_MESSAGE* Message);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcNsSendReceive(RPC_MESSAGE* Message, void** Handle);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void I_RpcNsRaiseException(RPC_MESSAGE* Message, RPC_STATUS Status);

	[Import("RPCNS4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS I_RpcReBindBuffer(RPC_MESSAGE* Message);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* NDRCContextBinding(int CContext);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NDRCContextMarshall(int CContext, void* pBuff);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NDRCContextUnmarshall(int* pCContext, void* hBinding, void* pBuff, uint32 DataRepresentation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NDRSContextMarshall(NDR_SCONTEXT_1* CContext, void* pBuff, NDR_RUNDOWN userRunDownIn);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NDR_SCONTEXT_1* NDRSContextUnmarshall(void* pBuff, uint32 DataRepresentation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NDRSContextMarshallEx(void* BindingHandle, NDR_SCONTEXT_1* CContext, void* pBuff, NDR_RUNDOWN userRunDownIn);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NDRSContextMarshall2(void* BindingHandle, NDR_SCONTEXT_1* CContext, void* pBuff, NDR_RUNDOWN userRunDownIn, void* CtxGuard, uint32 Flags);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NDR_SCONTEXT_1* NDRSContextUnmarshallEx(void* BindingHandle, void* pBuff, uint32 DataRepresentation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NDR_SCONTEXT_1* NDRSContextUnmarshall2(void* BindingHandle, void* pBuff, uint32 DataRepresentation, void* CtxGuard, uint32 Flags);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcSsDestroyClientContext(void** ContextHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrSimpleTypeMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8 FormatChar);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrPointerMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrSimpleStructMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrConformantStructMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrConformantVaryingStructMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrComplexStructMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrFixedArrayMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrConformantArrayMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrConformantVaryingArrayMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrVaryingArrayMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrComplexArrayMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrNonConformantStringMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrConformantStringMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrEncapsulatedUnionMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrNonEncapsulatedUnionMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrByteCountPointerMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrXmitOrRepAsMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrUserMarshalMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrInterfacePointerMarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrClientContextMarshall(MIDL_STUB_MESSAGE* pStubMsg, int ContextHandle, int32 fCheck);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrServerContextMarshall(MIDL_STUB_MESSAGE* pStubMsg, NDR_SCONTEXT_1* ContextHandle, NDR_RUNDOWN RundownRoutine);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrServerContextNewMarshall(MIDL_STUB_MESSAGE* pStubMsg, NDR_SCONTEXT_1* ContextHandle, NDR_RUNDOWN RundownRoutine, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrSimpleTypeUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8 FormatChar);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrRangeUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrCorrelationInitialize(MIDL_STUB_MESSAGE* pStubMsg, void* pMemory, uint32 CacheSize, uint32 flags);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrCorrelationPass(MIDL_STUB_MESSAGE* pStubMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrCorrelationFree(MIDL_STUB_MESSAGE* pStubMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrPointerUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrSimpleStructUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrConformantStructUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrConformantVaryingStructUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrComplexStructUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrFixedArrayUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrConformantArrayUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrConformantVaryingArrayUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrVaryingArrayUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrComplexArrayUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrNonConformantStringUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrConformantStringUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrEncapsulatedUnionUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrNonEncapsulatedUnionUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrByteCountPointerUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrXmitOrRepAsUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrUserMarshalUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrInterfacePointerUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8** ppMemory, uint8* pFormat, uint8 fMustAlloc);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrClientContextUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, int* pContextHandle, void* BindHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NDR_SCONTEXT_1* NdrServerContextUnmarshall(MIDL_STUB_MESSAGE* pStubMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NDR_SCONTEXT_1* NdrContextHandleInitialize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NDR_SCONTEXT_1* NdrServerContextNewUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrPointerBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrSimpleStructBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConformantStructBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConformantVaryingStructBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrComplexStructBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrFixedArrayBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConformantArrayBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConformantVaryingArrayBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrVaryingArrayBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrComplexArrayBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConformantStringBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrNonConformantStringBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrEncapsulatedUnionBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrNonEncapsulatedUnionBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrByteCountPointerBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrXmitOrRepAsBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrUserMarshalBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrInterfacePointerBufferSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrContextHandleSize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrPointerMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrSimpleStructMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrConformantStructMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrConformantVaryingStructMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrComplexStructMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrFixedArrayMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrConformantArrayMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrConformantVaryingArrayMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrVaryingArrayMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrComplexArrayMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrConformantStringMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrNonConformantStringMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrEncapsulatedUnionMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrNonEncapsulatedUnionMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrXmitOrRepAsMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrUserMarshalMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NdrInterfacePointerMemorySize(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrPointerFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrSimpleStructFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConformantStructFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConformantVaryingStructFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrComplexStructFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrFixedArrayFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConformantArrayFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConformantVaryingArrayFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrVaryingArrayFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrComplexArrayFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrEncapsulatedUnionFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrNonEncapsulatedUnionFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrByteCountPointerFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrXmitOrRepAsFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrUserMarshalFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrInterfacePointerFree(MIDL_STUB_MESSAGE* pStubMsg, uint8* pMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConvert2(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat, int32 NumberParams);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrConvert(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrUserMarshalSimpleTypeConvert(uint32* pFlags, uint8* pBuffer, uint8 FormatChar);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrClientInitializeNew(RPC_MESSAGE* pRpcMsg, MIDL_STUB_MESSAGE* pStubMsg, MIDL_STUB_DESC* pStubDescriptor, uint32 ProcNum);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrServerInitializeNew(RPC_MESSAGE* pRpcMsg, MIDL_STUB_MESSAGE* pStubMsg, MIDL_STUB_DESC* pStubDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrServerInitializePartial(RPC_MESSAGE* pRpcMsg, MIDL_STUB_MESSAGE* pStubMsg, MIDL_STUB_DESC* pStubDescriptor, uint32 RequestedBufferSize);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrClientInitialize(RPC_MESSAGE* pRpcMsg, MIDL_STUB_MESSAGE* pStubMsg, MIDL_STUB_DESC* pStubDescriptor, uint32 ProcNum);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrServerInitialize(RPC_MESSAGE* pRpcMsg, MIDL_STUB_MESSAGE* pStubMsg, MIDL_STUB_DESC* pStubDescriptor);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrServerInitializeUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, MIDL_STUB_DESC* pStubDescriptor, RPC_MESSAGE* pRpcMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrServerInitializeMarshall(RPC_MESSAGE* pRpcMsg, MIDL_STUB_MESSAGE* pStubMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrGetBuffer(MIDL_STUB_MESSAGE* pStubMsg, uint32 BufferLength, void* Handle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrNsGetBuffer(MIDL_STUB_MESSAGE* pStubMsg, uint32 BufferLength, void* Handle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrSendReceive(MIDL_STUB_MESSAGE* pStubMsg, uint8* pBufferEnd);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* NdrNsSendReceive(MIDL_STUB_MESSAGE* pStubMsg, uint8* pBufferEnd, void** pAutoHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrFreeBuffer(MIDL_STUB_MESSAGE* pStubMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NdrGetDcomProtocolVersion(MIDL_STUB_MESSAGE* pStubMsg, RPC_VERSION* pVersion);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLIENT_CALL_RETURN NdrClientCall2(MIDL_STUB_DESC* pStubDescriptor, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLIENT_CALL_RETURN NdrAsyncClientCall(MIDL_STUB_DESC* pStubDescriptor, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLIENT_CALL_RETURN NdrDcomAsyncClientCall(MIDL_STUB_DESC* pStubDescriptor, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrAsyncServerCall(RPC_MESSAGE* pRpcMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 NdrDcomAsyncStubCall(IRpcStubBuffer* pThis, IRpcChannelBuffer* pChannel, RPC_MESSAGE* pRpcMsg, uint32* pdwStubPhase);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 NdrStubCall2(void* pThis, void* pChannel, RPC_MESSAGE* pRpcMsg, uint32* pdwStubPhase);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrServerCall2(RPC_MESSAGE* pRpcMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS NdrMapCommAndFaultStatus(MIDL_STUB_MESSAGE* pStubMsg, uint32* pCommStatus, uint32* pFaultStatus, RPC_STATUS Status);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* RpcSsAllocate(uint Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcSsDisableAllocate();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcSsEnableAllocate();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcSsFree(void* NodeToFree);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* RpcSsGetThreadHandle();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcSsSetClientAllocFree(RPC_CLIENT_ALLOC ClientAlloc, RPC_CLIENT_FREE ClientFree);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcSsSetThreadHandle(void* Id);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcSsSwapClientAllocFree(RPC_CLIENT_ALLOC ClientAlloc, RPC_CLIENT_FREE ClientFree, RPC_CLIENT_ALLOC* OldClientAlloc, RPC_CLIENT_FREE* OldClientFree);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* RpcSmAllocate(uint Size, RPC_STATUS* pStatus);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSmClientFree(void* pNodeToFree);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSmDestroyClientContext(void** ContextHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSmDisableAllocate();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSmEnableAllocate();

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSmFree(void* NodeToFree);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* RpcSmGetThreadHandle(RPC_STATUS* pStatus);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSmSetClientAllocFree(RPC_CLIENT_ALLOC ClientAlloc, RPC_CLIENT_FREE ClientFree);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSmSetThreadHandle(void* Id);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcSmSwapClientAllocFree(RPC_CLIENT_ALLOC ClientAlloc, RPC_CLIENT_FREE ClientFree, RPC_CLIENT_ALLOC* OldClientAlloc, RPC_CLIENT_FREE* OldClientFree);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrRpcSsEnableAllocate(MIDL_STUB_MESSAGE* pMessage);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrRpcSsDisableAllocate(MIDL_STUB_MESSAGE* pMessage);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrRpcSmSetClientToOsf(MIDL_STUB_MESSAGE* pMessage);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* NdrRpcSmClientAllocate(uint Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrRpcSmClientFree(void* NodeToFree);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* NdrRpcSsDefaultAllocate(uint Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrRpcSsDefaultFree(void* NodeToFree);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FULL_PTR_XLAT_TABLES* NdrFullPointerXlatInit(uint32 NumberOfPointers, XLAT_SIDE XlatSide);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrFullPointerXlatFree(FULL_PTR_XLAT_TABLES* pXlatTables);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* NdrAllocate(MIDL_STUB_MESSAGE* pStubMsg, uint Len);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrClearOutParameters(MIDL_STUB_MESSAGE* pStubMsg, uint8* pFormat, void* ArgAddr);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* NdrOleAllocate(uint Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrOleFree(void* NodeToFree);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS NdrGetUserMarshalInfo(uint32* pFlags, uint32 InformationLevel, NDR_USER_MARSHAL_INFO* pMarshalInfo);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS NdrCreateServerInterfaceFromStub(IRpcStubBuffer* pStub, RPC_SERVER_INTERFACE* pServerIf);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLIENT_CALL_RETURN NdrClientCall3(MIDL_STUBLESS_PROXY_INFO* pProxyInfo, uint32 nProcNum, void* pReturnValue);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLIENT_CALL_RETURN Ndr64AsyncClientCall(MIDL_STUBLESS_PROXY_INFO* pProxyInfo, uint32 nProcNum, void* pReturnValue);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLIENT_CALL_RETURN Ndr64DcomAsyncClientCall(MIDL_STUBLESS_PROXY_INFO* pProxyInfo, uint32 nProcNum, void* pReturnValue);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void Ndr64AsyncServerCall64(RPC_MESSAGE* pRpcMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void Ndr64AsyncServerCallAll(RPC_MESSAGE* pRpcMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 Ndr64DcomAsyncStubCall(IRpcStubBuffer* pThis, IRpcChannelBuffer* pChannel, RPC_MESSAGE* pRpcMsg, uint32* pdwStubPhase);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 NdrStubCall3(void* pThis, void* pChannel, RPC_MESSAGE* pRpcMsg, uint32* pdwStubPhase);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrServerCallAll(RPC_MESSAGE* pRpcMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrServerCallNdr64(RPC_MESSAGE* pRpcMsg);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrPartialIgnoreClientMarshall(MIDL_STUB_MESSAGE* pStubMsg, void* pMemory);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrPartialIgnoreServerUnmarshall(MIDL_STUB_MESSAGE* pStubMsg, void** ppMemory);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrPartialIgnoreClientBufferSize(MIDL_STUB_MESSAGE* pStubMsg, void* pMemory);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrPartialIgnoreServerInitialize(MIDL_STUB_MESSAGE* pStubMsg, void** ppMemory, uint8* pFormat);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RpcUserFree(void* AsyncHandle, void* pBuffer);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS MesEncodeIncrementalHandleCreate(void* UserState, MIDL_ES_ALLOC AllocFn, MIDL_ES_WRITE WriteFn, void** pHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS MesDecodeIncrementalHandleCreate(void* UserState, MIDL_ES_READ ReadFn, void** pHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS MesIncrementalHandleReset(void* Handle, void* UserState, MIDL_ES_ALLOC AllocFn, MIDL_ES_WRITE WriteFn, MIDL_ES_READ ReadFn, MIDL_ES_CODE Operation);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS MesEncodeFixedBufferHandleCreate(PSTR pBuffer, uint32 BufferSize, uint32* pEncodedSize, void** pHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS MesEncodeDynBufferHandleCreate(int8** pBuffer, uint32* pEncodedSize, void** pHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS MesDecodeBufferHandleCreate(PSTR Buffer, uint32 BufferSize, void** pHandle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS MesBufferHandleReset(void* Handle, uint32 HandleStyle, MIDL_ES_CODE Operation, int8** pBuffer, uint32 BufferSize, uint32* pEncodedSize);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS MesHandleFree(void* Handle);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS MesInqProcEncodingId(void* Handle, RPC_SYNTAX_IDENTIFIER* pInterfaceId, uint32* pProcNum);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint NdrMesSimpleTypeAlignSize(void* param0);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesSimpleTypeDecode(void* Handle, void* pObject, int16 Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesSimpleTypeEncode(void* Handle, MIDL_STUB_DESC* pStubDesc, void* pObject, int16 Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint NdrMesTypeAlignSize(void* Handle, MIDL_STUB_DESC* pStubDesc, uint8* pFormatString, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesTypeEncode(void* Handle, MIDL_STUB_DESC* pStubDesc, uint8* pFormatString, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesTypeDecode(void* Handle, MIDL_STUB_DESC* pStubDesc, uint8* pFormatString, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint NdrMesTypeAlignSize2(void* Handle, MIDL_TYPE_PICKLING_INFO* pPicklingInfo, MIDL_STUB_DESC* pStubDesc, uint8* pFormatString, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesTypeEncode2(void* Handle, MIDL_TYPE_PICKLING_INFO* pPicklingInfo, MIDL_STUB_DESC* pStubDesc, uint8* pFormatString, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesTypeDecode2(void* Handle, MIDL_TYPE_PICKLING_INFO* pPicklingInfo, MIDL_STUB_DESC* pStubDesc, uint8* pFormatString, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesTypeFree2(void* Handle, MIDL_TYPE_PICKLING_INFO* pPicklingInfo, MIDL_STUB_DESC* pStubDesc, uint8* pFormatString, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesProcEncodeDecode(void* Handle, MIDL_STUB_DESC* pStubDesc, uint8* pFormatString);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLIENT_CALL_RETURN NdrMesProcEncodeDecode2(void* Handle, MIDL_STUB_DESC* pStubDesc, uint8* pFormatString);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint NdrMesTypeAlignSize3(void* Handle, MIDL_TYPE_PICKLING_INFO* pPicklingInfo, MIDL_STUBLESS_PROXY_INFO* pProxyInfo, uint32** ArrTypeOffset, uint32 nTypeIndex, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesTypeEncode3(void* Handle, MIDL_TYPE_PICKLING_INFO* pPicklingInfo, MIDL_STUBLESS_PROXY_INFO* pProxyInfo, uint32** ArrTypeOffset, uint32 nTypeIndex, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesTypeDecode3(void* Handle, MIDL_TYPE_PICKLING_INFO* pPicklingInfo, MIDL_STUBLESS_PROXY_INFO* pProxyInfo, uint32** ArrTypeOffset, uint32 nTypeIndex, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesTypeFree3(void* Handle, MIDL_TYPE_PICKLING_INFO* pPicklingInfo, MIDL_STUBLESS_PROXY_INFO* pProxyInfo, uint32** ArrTypeOffset, uint32 nTypeIndex, void* pObject);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLIENT_CALL_RETURN NdrMesProcEncodeDecode3(void* Handle, MIDL_STUBLESS_PROXY_INFO* pProxyInfo, uint32 nProcNum, void* pReturnValue);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesSimpleTypeDecodeAll(void* Handle, MIDL_STUBLESS_PROXY_INFO* pProxyInfo, void* pObject, int16 Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NdrMesSimpleTypeEncodeAll(void* Handle, MIDL_STUBLESS_PROXY_INFO* pProxyInfo, void* pObject, int16 Size);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint NdrMesSimpleTypeAlignSizeAll(void* Handle, MIDL_STUBLESS_PROXY_INFO* pProxyInfo);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcCertGeneratePrincipalNameW(CERT_CONTEXT* Context, uint32 Flags, uint16** pBuffer);

	[Import("RPCRT4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern RPC_STATUS RpcCertGeneratePrincipalNameA(CERT_CONTEXT* Context, uint32 Flags, uint8** pBuffer);
	public static RPC_STATUS RpcCertGeneratePrincipalName(CERT_CONTEXT* Context, uint32 Flags, uint8** pBuffer) => RpcCertGeneratePrincipalNameA(Context, Flags, pBuffer);

}
#endregion
