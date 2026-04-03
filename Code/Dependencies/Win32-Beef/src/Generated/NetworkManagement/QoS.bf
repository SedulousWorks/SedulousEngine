using Win32.Networking.WinSock;
using Win32.Foundation;
using Win32.NetworkManagement.Ndis;
using Win32.System.IO;
using System;

namespace Win32.NetworkManagement.QoS;

#region Constants
public static
{
	public const uint32 QOS_MAX_OBJECT_STRING_LENGTH = 256;
	public const uint32 QOS_TRAFFIC_GENERAL_ID_BASE = 4000;
	public const uint32 SERVICETYPE_NOTRAFFIC = 0;
	public const uint32 SERVICETYPE_BESTEFFORT = 1;
	public const uint32 SERVICETYPE_CONTROLLEDLOAD = 2;
	public const uint32 SERVICETYPE_GUARANTEED = 3;
	public const uint32 SERVICETYPE_NETWORK_UNAVAILABLE = 4;
	public const uint32 SERVICETYPE_GENERAL_INFORMATION = 5;
	public const uint32 SERVICETYPE_NOCHANGE = 6;
	public const uint32 SERVICETYPE_NONCONFORMING = 9;
	public const uint32 SERVICETYPE_NETWORK_CONTROL = 10;
	public const uint32 SERVICETYPE_QUALITATIVE = 13;
	public const uint32 SERVICE_BESTEFFORT = 2147549184;
	public const uint32 SERVICE_CONTROLLEDLOAD = 2147614720;
	public const uint32 SERVICE_GUARANTEED = 2147745792;
	public const uint32 SERVICE_QUALITATIVE = 2149580800;
	public const uint32 SERVICE_NO_TRAFFIC_CONTROL = 2164260864;
	public const uint32 SERVICE_NO_QOS_SIGNALING = 1073741824;
	public const uint32 QOS_NOT_SPECIFIED = 4294967295;
	public const uint32 POSITIVE_INFINITY_RATE = 4294967294;
	public const uint32 QOS_GENERAL_ID_BASE = 2000;
	public const uint32 TC_NONCONF_BORROW = 0;
	public const uint32 TC_NONCONF_SHAPE = 1;
	public const uint32 TC_NONCONF_DISCARD = 2;
	public const uint32 TC_NONCONF_BORROW_PLUS = 3;
	public const uint32 class_NULL = 0;
	public const uint32 class_SESSION = 1;
	public const uint32 class_SESSION_GROUP = 2;
	public const uint32 class_RSVP_HOP = 3;
	public const uint32 class_INTEGRITY = 4;
	public const uint32 class_TIME_VALUES = 5;
	public const uint32 class_ERROR_SPEC = 6;
	public const uint32 class_SCOPE = 7;
	public const uint32 class_STYLE = 8;
	public const uint32 class_FLOWSPEC = 9;
	public const uint32 class_IS_FLOWSPEC = 9;
	public const uint32 class_FILTER_SPEC = 10;
	public const uint32 class_SENDER_TEMPLATE = 11;
	public const uint32 class_SENDER_TSPEC = 12;
	public const uint32 class_ADSPEC = 13;
	public const uint32 class_POLICY_DATA = 14;
	public const uint32 class_CONFIRM = 15;
	public const uint32 class_MAX = 15;
	public const uint32 ctype_SESSION_ipv4 = 1;
	public const uint32 ctype_SESSION_ipv4GPI = 3;
	public const uint32 SESSFLG_E_Police = 1;
	public const uint32 ctype_RSVP_HOP_ipv4 = 1;
	public const uint32 Opt_Share_mask = 24;
	public const uint32 Opt_Distinct = 8;
	public const uint32 Opt_Shared = 16;
	public const uint32 Opt_SndSel_mask = 7;
	public const uint32 Opt_Wildcard = 1;
	public const uint32 Opt_Explicit = 2;
	public const uint32 ctype_STYLE = 1;
	public const uint32 ctype_FILTER_SPEC_ipv4 = 1;
	public const uint32 ctype_FILTER_SPEC_ipv4GPI = 4;
	public const uint32 ctype_SENDER_TEMPLATE_ipv4 = 1;
	public const uint32 ctype_SENDER_TEMPLATE_ipv4GPI = 4;
	public const uint32 ctype_SCOPE_list_ipv4 = 1;
	public const uint32 ctype_ERROR_SPEC_ipv4 = 1;
	public const uint32 ERROR_SPECF_InPlace = 1;
	public const uint32 ERROR_SPECF_NotGuilty = 2;
	public const uint32 ERR_FORWARD_OK = 32768;
	public const uint32 ERR_Usage_globl = 0;
	public const uint32 ERR_Usage_local = 16;
	public const uint32 ERR_Usage_serv = 17;
	public const uint32 ERR_global_mask = 4095;
	public const uint32 ctype_POLICY_DATA = 1;
	public const uint32 GENERAL_INFO = 1;
	public const uint32 GUARANTEED_SERV = 2;
	public const uint32 PREDICTIVE_SERV = 3;
	public const uint32 CONTROLLED_DELAY_SERV = 4;
	public const uint32 CONTROLLED_LOAD_SERV = 5;
	public const uint32 QUALITATIVE_SERV = 6;
	public const uint32 INTSERV_VERS_MASK = 240;
	public const uint32 INTSERV_VERSION0 = 0;
	public const uint32 ISSH_BREAK_BIT = 128;
	public const uint32 ISPH_FLG_INV = 128;
	public const uint32 ctype_SENDER_TSPEC = 2;
	public const uint32 ctype_FLOWSPEC_Intserv0 = 2;
	public const uint32 ctype_ADSPEC_INTSERV = 2;
	public const uint32 RSVP_PATH = 1;
	public const uint32 RSVP_RESV = 2;
	public const uint32 RSVP_PATH_ERR = 3;
	public const uint32 RSVP_RESV_ERR = 4;
	public const uint32 RSVP_PATH_TEAR = 5;
	public const uint32 RSVP_RESV_TEAR = 6;
	public const uint32 RSVP_Err_NONE = 0;
	public const uint32 RSVP_Erv_Nonev = 0;
	public const uint32 RSVP_Err_ADMISSION = 1;
	public const uint32 RSVP_Erv_Other = 0;
	public const uint32 RSVP_Erv_DelayBnd = 1;
	public const uint32 RSVP_Erv_Bandwidth = 2;
	public const uint32 RSVP_Erv_MTU = 3;
	public const uint32 RSVP_Erv_Flow_Rate = 32769;
	public const uint32 RSVP_Erv_Bucket_szie = 32770;
	public const uint32 RSVP_Erv_Peak_Rate = 32771;
	public const uint32 RSVP_Erv_Min_Policied_size = 32772;
	public const uint32 RSVP_Err_POLICY = 2;
	public const uint32 POLICY_ERRV_NO_MORE_INFO = 1;
	public const uint32 POLICY_ERRV_UNSUPPORTED_CREDENTIAL_TYPE = 2;
	public const uint32 POLICY_ERRV_INSUFFICIENT_PRIVILEGES = 3;
	public const uint32 POLICY_ERRV_EXPIRED_CREDENTIALS = 4;
	public const uint32 POLICY_ERRV_IDENTITY_CHANGED = 5;
	public const uint32 POLICY_ERRV_UNKNOWN = 0;
	public const uint32 POLICY_ERRV_GLOBAL_DEF_FLOW_COUNT = 1;
	public const uint32 POLICY_ERRV_GLOBAL_GRP_FLOW_COUNT = 2;
	public const uint32 POLICY_ERRV_GLOBAL_USER_FLOW_COUNT = 3;
	public const uint32 POLICY_ERRV_GLOBAL_UNAUTH_USER_FLOW_COUNT = 4;
	public const uint32 POLICY_ERRV_SUBNET_DEF_FLOW_COUNT = 5;
	public const uint32 POLICY_ERRV_SUBNET_GRP_FLOW_COUNT = 6;
	public const uint32 POLICY_ERRV_SUBNET_USER_FLOW_COUNT = 7;
	public const uint32 POLICY_ERRV_SUBNET_UNAUTH_USER_FLOW_COUNT = 8;
	public const uint32 POLICY_ERRV_GLOBAL_DEF_FLOW_DURATION = 9;
	public const uint32 POLICY_ERRV_GLOBAL_GRP_FLOW_DURATION = 10;
	public const uint32 POLICY_ERRV_GLOBAL_USER_FLOW_DURATION = 11;
	public const uint32 POLICY_ERRV_GLOBAL_UNAUTH_USER_FLOW_DURATION = 12;
	public const uint32 POLICY_ERRV_SUBNET_DEF_FLOW_DURATION = 13;
	public const uint32 POLICY_ERRV_SUBNET_GRP_FLOW_DURATION = 14;
	public const uint32 POLICY_ERRV_SUBNET_USER_FLOW_DURATION = 15;
	public const uint32 POLICY_ERRV_SUBNET_UNAUTH_USER_FLOW_DURATION = 16;
	public const uint32 POLICY_ERRV_GLOBAL_DEF_FLOW_RATE = 17;
	public const uint32 POLICY_ERRV_GLOBAL_GRP_FLOW_RATE = 18;
	public const uint32 POLICY_ERRV_GLOBAL_USER_FLOW_RATE = 19;
	public const uint32 POLICY_ERRV_GLOBAL_UNAUTH_USER_FLOW_RATE = 20;
	public const uint32 POLICY_ERRV_SUBNET_DEF_FLOW_RATE = 21;
	public const uint32 POLICY_ERRV_SUBNET_GRP_FLOW_RATE = 22;
	public const uint32 POLICY_ERRV_SUBNET_USER_FLOW_RATE = 23;
	public const uint32 POLICY_ERRV_SUBNET_UNAUTH_USER_FLOW_RATE = 24;
	public const uint32 POLICY_ERRV_GLOBAL_DEF_PEAK_RATE = 25;
	public const uint32 POLICY_ERRV_GLOBAL_GRP_PEAK_RATE = 26;
	public const uint32 POLICY_ERRV_GLOBAL_USER_PEAK_RATE = 27;
	public const uint32 POLICY_ERRV_GLOBAL_UNAUTH_USER_PEAK_RATE = 28;
	public const uint32 POLICY_ERRV_SUBNET_DEF_PEAK_RATE = 29;
	public const uint32 POLICY_ERRV_SUBNET_GRP_PEAK_RATE = 30;
	public const uint32 POLICY_ERRV_SUBNET_USER_PEAK_RATE = 31;
	public const uint32 POLICY_ERRV_SUBNET_UNAUTH_USER_PEAK_RATE = 32;
	public const uint32 POLICY_ERRV_GLOBAL_DEF_SUM_FLOW_RATE = 33;
	public const uint32 POLICY_ERRV_GLOBAL_GRP_SUM_FLOW_RATE = 34;
	public const uint32 POLICY_ERRV_GLOBAL_USER_SUM_FLOW_RATE = 35;
	public const uint32 POLICY_ERRV_GLOBAL_UNAUTH_USER_SUM_FLOW_RATE = 36;
	public const uint32 POLICY_ERRV_SUBNET_DEF_SUM_FLOW_RATE = 37;
	public const uint32 POLICY_ERRV_SUBNET_GRP_SUM_FLOW_RATE = 38;
	public const uint32 POLICY_ERRV_SUBNET_USER_SUM_FLOW_RATE = 39;
	public const uint32 POLICY_ERRV_SUBNET_UNAUTH_USER_SUM_FLOW_RATE = 40;
	public const uint32 POLICY_ERRV_GLOBAL_DEF_SUM_PEAK_RATE = 41;
	public const uint32 POLICY_ERRV_GLOBAL_GRP_SUM_PEAK_RATE = 42;
	public const uint32 POLICY_ERRV_GLOBAL_USER_SUM_PEAK_RATE = 43;
	public const uint32 POLICY_ERRV_GLOBAL_UNAUTH_USER_SUM_PEAK_RATE = 44;
	public const uint32 POLICY_ERRV_SUBNET_DEF_SUM_PEAK_RATE = 45;
	public const uint32 POLICY_ERRV_SUBNET_GRP_SUM_PEAK_RATE = 46;
	public const uint32 POLICY_ERRV_SUBNET_USER_SUM_PEAK_RATE = 47;
	public const uint32 POLICY_ERRV_SUBNET_UNAUTH_USER_SUM_PEAK_RATE = 48;
	public const uint32 POLICY_ERRV_UNKNOWN_USER = 49;
	public const uint32 POLICY_ERRV_NO_PRIVILEGES = 50;
	public const uint32 POLICY_ERRV_EXPIRED_USER_TOKEN = 51;
	public const uint32 POLICY_ERRV_NO_RESOURCES = 52;
	public const uint32 POLICY_ERRV_PRE_EMPTED = 53;
	public const uint32 POLICY_ERRV_USER_CHANGED = 54;
	public const uint32 POLICY_ERRV_NO_ACCEPTS = 55;
	public const uint32 POLICY_ERRV_NO_MEMORY = 56;
	public const uint32 POLICY_ERRV_CRAZY_FLOWSPEC = 57;
	public const uint32 RSVP_Err_NO_PATH = 3;
	public const uint32 RSVP_Err_NO_SENDER = 4;
	public const uint32 RSVP_Err_BAD_STYLE = 5;
	public const uint32 RSVP_Err_UNKNOWN_STYLE = 6;
	public const uint32 RSVP_Err_BAD_DSTPORT = 7;
	public const uint32 RSVP_Err_BAD_SNDPORT = 8;
	public const uint32 RSVP_Err_AMBIG_FILTER = 9;
	public const uint32 RSVP_Err_PREEMPTED = 12;
	public const uint32 RSVP_Err_UNKN_OBJ_CLASS = 13;
	public const uint32 RSVP_Err_UNKNOWN_CTYPE = 14;
	public const uint32 RSVP_Err_API_ERROR = 20;
	public const uint32 RSVP_Err_TC_ERROR = 21;
	public const uint32 RSVP_Erv_Conflict_Serv = 1;
	public const uint32 RSVP_Erv_No_Serv = 2;
	public const uint32 RSVP_Erv_Crazy_Flowspec = 3;
	public const uint32 RSVP_Erv_Crazy_Tspec = 4;
	public const uint32 RSVP_Err_TC_SYS_ERROR = 22;
	public const uint32 RSVP_Err_RSVP_SYS_ERROR = 23;
	public const uint32 RSVP_Erv_MEMORY = 1;
	public const uint32 RSVP_Erv_API = 2;
	public const uint32 LPM_PE_USER_IDENTITY = 2;
	public const uint32 LPM_PE_APP_IDENTITY = 3;
	public const uint32 ERROR_NO_MORE_INFO = 1;
	public const uint32 UNSUPPORTED_CREDENTIAL_TYPE = 2;
	public const uint32 INSUFFICIENT_PRIVILEGES = 3;
	public const uint32 EXPIRED_CREDENTIAL = 4;
	public const uint32 IDENTITY_CHANGED = 5;
	public const uint32 LPM_OK = 0;
	public const uint32 INV_LPM_HANDLE = 1;
	public const uint32 LPM_TIME_OUT = 2;
	public const uint32 INV_REQ_HANDLE = 3;
	public const uint32 DUP_RESULTS = 4;
	public const uint32 INV_RESULTS = 5;
	public const uint32 LPM_PE_ALL_TYPES = 0;
	public const uint32 LPM_API_VERSION_1 = 1;
	public const uint32 PCM_VERSION_1 = 1;
	public const uint32 LPV_RESERVED = 0;
	public const uint32 LPV_MIN_PRIORITY = 1;
	public const uint32 LPV_MAX_PRIORITY = 65280;
	public const uint32 LPV_DROP_MSG = 65533;
	public const uint32 LPV_DONT_CARE = 65534;
	public const uint32 LPV_REJECT = 65535;
	public const uint32 FORCE_IMMEDIATE_REFRESH = 1;
	public const uint32 LPM_RESULT_READY = 0;
	public const uint32 LPM_RESULT_DEFER = 1;
	public const uint32 RCVD_PATH_TEAR = 1;
	public const uint32 RCVD_RESV_TEAR = 2;
	public const uint32 ADM_CTRL_FAILED = 3;
	public const uint32 STATE_TIMEOUT = 4;
	public const uint32 FLOW_DURATION = 5;
	public const uint32 RESOURCES_ALLOCATED = 1;
	public const uint32 RESOURCES_MODIFIED = 2;
	public const uint32 CURRENT_TCI_VERSION = 2;
	public const uint32 TC_NOTIFY_IFC_UP = 1;
	public const uint32 TC_NOTIFY_IFC_CLOSE = 2;
	public const uint32 TC_NOTIFY_IFC_CHANGE = 3;
	public const uint32 TC_NOTIFY_PARAM_CHANGED = 4;
	public const uint32 TC_NOTIFY_FLOW_CLOSE = 5;
	public const uint32 MAX_STRING_LENGTH = 256;
	public const uint32 QOS_OUTGOING_DEFAULT_MINIMUM_BANDWIDTH = 4294967295;
	public const uint32 QOS_QUERYFLOW_FRESH = 1;
	public const uint32 QOS_NON_ADAPTIVE_FLOW = 2;
	public const uint32 RSVP_OBJECT_ID_BASE = 1000;
	public const uint32 RSVP_DEFAULT_STYLE = 0;
	public const uint32 RSVP_WILDCARD_STYLE = 1;
	public const uint32 RSVP_FIXED_FILTER_STYLE = 2;
	public const uint32 RSVP_SHARED_EXPLICIT_STYLE = 3;
	public const uint32 AD_FLAG_BREAK_BIT = 1;
	public const uint32 mIOC_IN = 2147483648;
	public const uint32 mIOC_OUT = 1073741824;
	public const uint32 mIOC_VENDOR = 67108864;
	public const uint32 mCOMPANY = 402653184;
	public const uint32 ioctl_code = 1;
	public const uint32 QOSSPBASE = 50000;
	public const uint32 ALLOWED_TO_SEND_DATA = 50001;
	public const uint32 ABLE_TO_RECV_RSVP = 50002;
	public const uint32 LINE_RATE = 50003;
	public const uint32 LOCAL_TRAFFIC_CONTROL = 50004;
	public const uint32 LOCAL_QOSABILITY = 50005;
	public const uint32 END_TO_END_QOSABILITY = 50006;
	public const uint32 INFO_NOT_AVAILABLE = 4294967295;
	public const uint32 ANY_DEST_ADDR = 4294967295;
	public const uint32 MODERATELY_DELAY_SENSITIVE = 4294967293;
	public const uint32 HIGHLY_DELAY_SENSITIVE = 4294967294;
	public const uint32 QOSSP_ERR_BASE = 56000;
	public const uint32 GQOS_NO_ERRORCODE = 0;
	public const uint32 GQOS_NO_ERRORVALUE = 0;
	public const uint32 GQOS_ERRORCODE_UNKNOWN = 4294967295;
	public const uint32 GQOS_ERRORVALUE_UNKNOWN = 4294967295;
	public const uint32 GQOS_NET_ADMISSION = 56100;
	public const uint32 GQOS_NET_POLICY = 56200;
	public const uint32 GQOS_RSVP = 56300;
	public const uint32 GQOS_API = 56400;
	public const uint32 GQOS_KERNEL_TC_SYS = 56500;
	public const uint32 GQOS_RSVP_SYS = 56600;
	public const uint32 GQOS_KERNEL_TC = 56700;
	public const uint32 PE_TYPE_APPID = 3;
	public const uint32 PE_ATTRIB_TYPE_POLICY_LOCATOR = 1;
	public const uint32 POLICY_LOCATOR_SUB_TYPE_ASCII_DN = 1;
	public const uint32 POLICY_LOCATOR_SUB_TYPE_UNICODE_DN = 2;
	public const uint32 POLICY_LOCATOR_SUB_TYPE_ASCII_DN_ENC = 3;
	public const uint32 POLICY_LOCATOR_SUB_TYPE_UNICODE_DN_ENC = 4;
	public const uint32 PE_ATTRIB_TYPE_CREDENTIAL = 2;
	public const uint32 CREDENTIAL_SUB_TYPE_ASCII_ID = 1;
	public const uint32 CREDENTIAL_SUB_TYPE_UNICODE_ID = 2;
	public const uint32 CREDENTIAL_SUB_TYPE_KERBEROS_TKT = 3;
	public const uint32 CREDENTIAL_SUB_TYPE_X509_V3_CERT = 4;
	public const uint32 CREDENTIAL_SUB_TYPE_PGP_CERT = 5;
	public const uint32 TCBASE = 7500;
	public const uint32 ERROR_INCOMPATIBLE_TCI_VERSION = 7501;
	public const uint32 ERROR_INVALID_SERVICE_TYPE = 7502;
	public const uint32 ERROR_INVALID_TOKEN_RATE = 7503;
	public const uint32 ERROR_INVALID_PEAK_RATE = 7504;
	public const uint32 ERROR_INVALID_SD_MODE = 7505;
	public const uint32 ERROR_INVALID_QOS_PRIORITY = 7506;
	public const uint32 ERROR_INVALID_TRAFFIC_CLASS = 7507;
	public const uint32 ERROR_INVALID_ADDRESS_TYPE = 7508;
	public const uint32 ERROR_DUPLICATE_FILTER = 7509;
	public const uint32 ERROR_FILTER_CONFLICT = 7510;
	public const uint32 ERROR_ADDRESS_TYPE_NOT_SUPPORTED = 7511;
	public const uint32 ERROR_TC_SUPPORTED_OBJECTS_EXIST = 7512;
	public const uint32 ERROR_INCOMPATABLE_QOS = 7513;
	public const uint32 ERROR_TC_NOT_SUPPORTED = 7514;
	public const uint32 ERROR_TC_OBJECT_LENGTH_INVALID = 7515;
	public const uint32 ERROR_INVALID_FLOW_MODE = 7516;
	public const uint32 ERROR_INVALID_DIFFSERV_FLOW = 7517;
	public const uint32 ERROR_DS_MAPPING_EXISTS = 7518;
	public const uint32 ERROR_INVALID_SHAPE_RATE = 7519;
	public const uint32 ERROR_INVALID_DS_CLASS = 7520;
	public const uint32 ERROR_TOO_MANY_CLIENTS = 7521;
	public const Guid GUID_QOS_REMAINING_BANDWIDTH = .(0xc4c51720, 0x40ec, 0x11d1, 0x2c, 0x91, 0x00, 0xaa, 0x00, 0x57, 0x49, 0x15);
	public const Guid GUID_QOS_BESTEFFORT_BANDWIDTH = .(0xed885290, 0x40ec, 0x11d1, 0x2c, 0x91, 0x00, 0xaa, 0x00, 0x57, 0x49, 0x15);
	public const Guid GUID_QOS_LATENCY = .(0xfc408ef0, 0x40ec, 0x11d1, 0x2c, 0x91, 0x00, 0xaa, 0x00, 0x57, 0x49, 0x15);
	public const Guid GUID_QOS_FLOW_COUNT = .(0x1147f880, 0x40ed, 0x11d1, 0x2c, 0x91, 0x00, 0xaa, 0x00, 0x57, 0x49, 0x15);
	public const Guid GUID_QOS_NON_BESTEFFORT_LIMIT = .(0x185c44e0, 0x40ed, 0x11d1, 0x2c, 0x91, 0x00, 0xaa, 0x00, 0x57, 0x49, 0x15);
	public const Guid GUID_QOS_MAX_OUTSTANDING_SENDS = .(0x161ffa86, 0x6120, 0x11d1, 0x2c, 0x91, 0x00, 0xaa, 0x00, 0x57, 0x49, 0x15);
	public const Guid GUID_QOS_STATISTICS_BUFFER = .(0xbb2c0980, 0xe900, 0x11d1, 0xb0, 0x7e, 0x00, 0x80, 0xc7, 0x13, 0x82, 0xbf);
	public const Guid GUID_QOS_FLOW_MODE = .(0x5c82290a, 0x515a, 0x11d2, 0x8e, 0x58, 0x00, 0xc0, 0x4f, 0xc9, 0xbf, 0xcb);
	public const Guid GUID_QOS_ISSLOW_FLOW = .(0xabf273a4, 0xee07, 0x11d2, 0xbe, 0x1b, 0x00, 0xa0, 0xc9, 0x9e, 0xe6, 0x3b);
	public const Guid GUID_QOS_TIMER_RESOLUTION = .(0xba10cc88, 0xf13e, 0x11d2, 0xbe, 0x1b, 0x00, 0xa0, 0xc9, 0x9e, 0xe6, 0x3b);
	public const Guid GUID_QOS_FLOW_IP_CONFORMING = .(0x07f99a8b, 0xfcd2, 0x11d2, 0xbe, 0x1e, 0x00, 0xa0, 0xc9, 0x9e, 0xe6, 0x3b);
	public const Guid GUID_QOS_FLOW_IP_NONCONFORMING = .(0x087a5987, 0xfcd2, 0x11d2, 0xbe, 0x1e, 0x00, 0xa0, 0xc9, 0x9e, 0xe6, 0x3b);
	public const Guid GUID_QOS_FLOW_8021P_CONFORMING = .(0x08c1e013, 0xfcd2, 0x11d2, 0xbe, 0x1e, 0x00, 0xa0, 0xc9, 0x9e, 0xe6, 0x3b);
	public const Guid GUID_QOS_FLOW_8021P_NONCONFORMING = .(0x09023f91, 0xfcd2, 0x11d2, 0xbe, 0x1e, 0x00, 0xa0, 0xc9, 0x9e, 0xe6, 0x3b);
	public const Guid GUID_QOS_ENABLE_AVG_STATS = .(0xbafb6d11, 0x27c4, 0x4801, 0xa4, 0x6f, 0xef, 0x80, 0x80, 0xc1, 0x88, 0xc8);
	public const Guid GUID_QOS_ENABLE_WINDOW_ADJUSTMENT = .(0xaa966725, 0xd3e9, 0x4c55, 0xb3, 0x35, 0x2a, 0x00, 0x27, 0x9a, 0x1e, 0x64);
	public const uint32 FSCTL_TCP_BASE = 18;
	public const String DD_TCP_DEVICE_NAME = "\\Device\\Tcp";
	public const uint32 IF_MIB_STATS_ID = 1;
	public const uint32 IP_MIB_STATS_ID = 1;
	public const uint32 IP_MIB_ADDRTABLE_ENTRY_ID = 258;
	public const uint32 IP_INTFC_INFO_ID = 259;
	public const uint32 MAX_PHYSADDR_SIZE = 8;
	public const uint32 SIPAEV_PREBOOT_CERT = 0;
	public const uint32 SIPAEV_POST_CODE = 1;
	public const uint32 SIPAEV_UNUSED = 2;
	public const uint32 SIPAEV_NO_ACTION = 3;
	public const uint32 SIPAEV_SEPARATOR = 4;
	public const uint32 SIPAEV_ACTION = 5;
	public const uint32 SIPAEV_EVENT_TAG = 6;
	public const uint32 SIPAEV_S_CRTM_CONTENTS = 7;
	public const uint32 SIPAEV_S_CRTM_VERSION = 8;
	public const uint32 SIPAEV_CPU_MICROCODE = 9;
	public const uint32 SIPAEV_PLATFORM_CONFIG_FLAGS = 10;
	public const uint32 SIPAEV_TABLE_OF_DEVICES = 11;
	public const uint32 SIPAEV_COMPACT_HASH = 12;
	public const uint32 SIPAEV_IPL = 13;
	public const uint32 SIPAEV_IPL_PARTITION_DATA = 14;
	public const uint32 SIPAEV_NONHOST_CODE = 15;
	public const uint32 SIPAEV_NONHOST_CONFIG = 16;
	public const uint32 SIPAEV_NONHOST_INFO = 17;
	public const uint32 SIPAEV_OMIT_BOOT_DEVICE_EVENTS = 18;
	public const uint32 SIPAEV_EFI_EVENT_BASE = 2147483648;
	public const uint32 SIPAEV_EFI_VARIABLE_DRIVER_CONFIG = 2147483649;
	public const uint32 SIPAEV_EFI_VARIABLE_BOOT = 2147483650;
	public const uint32 SIPAEV_EFI_BOOT_SERVICES_APPLICATION = 2147483651;
	public const uint32 SIPAEV_EFI_BOOT_SERVICES_DRIVER = 2147483652;
	public const uint32 SIPAEV_EFI_RUNTIME_SERVICES_DRIVER = 2147483653;
	public const uint32 SIPAEV_EFI_GPT_EVENT = 2147483654;
	public const uint32 SIPAEV_EFI_ACTION = 2147483655;
	public const uint32 SIPAEV_EFI_PLATFORM_FIRMWARE_BLOB = 2147483656;
	public const uint32 SIPAEV_EFI_HANDOFF_TABLES = 2147483657;
	public const uint32 SIPAEV_EFI_PLATFORM_FIRMWARE_BLOB2 = 2147483658;
	public const uint32 SIPAEV_EFI_HANDOFF_TABLES2 = 2147483659;
	public const uint32 SIPAEV_EFI_HCRTM_EVENT = 2147483664;
	public const uint32 SIPAEV_EFI_VARIABLE_AUTHORITY = 2147483872;
	public const uint32 SIPAEV_EFI_SPDM_FIRMWARE_BLOB = 2147483873;
	public const uint32 SIPAEV_EFI_SPDM_FIRMWARE_CONFIG = 2147483874;
	public const uint32 SIPAEV_TXT_EVENT_BASE = 1024;
	public const uint32 SIPAEV_TXT_PCR_MAPPING = 1025;
	public const uint32 SIPAEV_TXT_HASH_START = 1026;
	public const uint32 SIPAEV_TXT_COMBINED_HASH = 1027;
	public const uint32 SIPAEV_TXT_MLE_HASH = 1028;
	public const uint32 SIPAEV_TXT_BIOSAC_REG_DATA = 1034;
	public const uint32 SIPAEV_TXT_CPU_SCRTM_STAT = 1035;
	public const uint32 SIPAEV_TXT_LCP_CONTROL_HASH = 1036;
	public const uint32 SIPAEV_TXT_ELEMENTS_HASH = 1037;
	public const uint32 SIPAEV_TXT_STM_HASH = 1038;
	public const uint32 SIPAEV_TXT_OSSINITDATA_CAP_HASH = 1039;
	public const uint32 SIPAEV_TXT_SINIT_PUBKEY_HASH = 1040;
	public const uint32 SIPAEV_TXT_LCP_HASH = 1041;
	public const uint32 SIPAEV_TXT_LCP_DETAILS_HASH = 1042;
	public const uint32 SIPAEV_TXT_LCP_AUTHORITIES_HASH = 1043;
	public const uint32 SIPAEV_TXT_NV_INFO_HASH = 1044;
	public const uint32 SIPAEV_TXT_COLD_BOOT_BIOS_HASH = 1045;
	public const uint32 SIPAEV_TXT_KM_HASH = 1046;
	public const uint32 SIPAEV_TXT_BPM_HASH = 1047;
	public const uint32 SIPAEV_TXT_KM_INFO_HASH = 1048;
	public const uint32 SIPAEV_TXT_BPM_INFO_HASH = 1049;
	public const uint32 SIPAEV_TXT_BOOT_POL_HASH = 1050;
	public const uint32 SIPAEV_TXT_RANDOM_VALUE = 1278;
	public const uint32 SIPAEV_TXT_CAP_VALUE = 1279;
	public const uint32 SIPAEV_AMD_SL_EVENT_BASE = 32768;
	public const uint32 SIPAEV_AMD_SL_LOAD = 32769;
	public const uint32 SIPAEV_AMD_SL_PSP_FW_SPLT = 32770;
	public const uint32 SIPAEV_AMD_SL_TSME_RB_FUSE = 32771;
	public const uint32 SIPAEV_AMD_SL_PUB_KEY = 32772;
	public const uint32 SIPAEV_AMD_SL_SVN = 32773;
	public const uint32 SIPAEV_AMD_SL_LOAD_1 = 32774;
	public const uint32 SIPAEV_AMD_SL_SEPARATOR = 32775;
	public const uint32 SIPAEVENTTYPE_NONMEASURED = 2147483648;
	public const uint32 SIPAEVENTTYPE_AGGREGATION = 1073741824;
	public const uint32 SIPAEVENTTYPE_CONTAINER = 65536;
	public const uint32 SIPAEVENTTYPE_INFORMATION = 131072;
	public const uint32 SIPAEVENTTYPE_ERROR = 196608;
	public const uint32 SIPAEVENTTYPE_PREOSPARAMETER = 262144;
	public const uint32 SIPAEVENTTYPE_OSPARAMETER = 327680;
	public const uint32 SIPAEVENTTYPE_AUTHORITY = 393216;
	public const uint32 SIPAEVENTTYPE_LOADEDMODULE = 458752;
	public const uint32 SIPAEVENTTYPE_TRUSTPOINT = 524288;
	public const uint32 SIPAEVENTTYPE_ELAM = 589824;
	public const uint32 SIPAEVENTTYPE_VBS = 655360;
	public const uint32 SIPAEVENTTYPE_KSR = 720896;
	public const uint32 SIPAEVENTTYPE_DRTM = 786432;
	public const uint32 SIPAERROR_FIRMWAREFAILURE = 196609;
	public const uint32 SIPAERROR_INTERNALFAILURE = 196611;
	public const uint32 SIPAEVENT_INFORMATION = 131073;
	public const uint32 SIPAEVENT_BOOTCOUNTER = 131074;
	public const uint32 SIPAEVENT_TRANSFER_CONTROL = 131075;
	public const uint32 SIPAEVENT_APPLICATION_RETURN = 131076;
	public const uint32 SIPAEVENT_BITLOCKER_UNLOCK = 131077;
	public const uint32 SIPAEVENT_EVENTCOUNTER = 131078;
	public const uint32 SIPAEVENT_COUNTERID = 131079;
	public const uint32 SIPAEVENT_MORBIT_NOT_CANCELABLE = 131080;
	public const uint32 SIPAEVENT_APPLICATION_SVN = 131081;
	public const uint32 SIPAEVENT_SVN_CHAIN_STATUS = 131082;
	public const uint32 SIPAEVENT_MORBIT_API_STATUS = 131083;
	public const uint32 SIPAEVENT_BOOTDEBUGGING = 262145;
	public const uint32 SIPAEVENT_BOOT_REVOCATION_LIST = 262146;
	public const uint32 SIPAEVENT_OSKERNELDEBUG = 327681;
	public const uint32 SIPAEVENT_CODEINTEGRITY = 327682;
	public const uint32 SIPAEVENT_TESTSIGNING = 327683;
	public const uint32 SIPAEVENT_DATAEXECUTIONPREVENTION = 327684;
	public const uint32 SIPAEVENT_SAFEMODE = 327685;
	public const uint32 SIPAEVENT_WINPE = 327686;
	public const uint32 SIPAEVENT_PHYSICALADDRESSEXTENSION = 327687;
	public const uint32 SIPAEVENT_OSDEVICE = 327688;
	public const uint32 SIPAEVENT_SYSTEMROOT = 327689;
	public const uint32 SIPAEVENT_HYPERVISOR_LAUNCH_TYPE = 327690;
	public const uint32 SIPAEVENT_HYPERVISOR_PATH = 327691;
	public const uint32 SIPAEVENT_HYPERVISOR_IOMMU_POLICY = 327692;
	public const uint32 SIPAEVENT_HYPERVISOR_DEBUG = 327693;
	public const uint32 SIPAEVENT_DRIVER_LOAD_POLICY = 327694;
	public const uint32 SIPAEVENT_SI_POLICY = 327695;
	public const uint32 SIPAEVENT_HYPERVISOR_MMIO_NX_POLICY = 327696;
	public const uint32 SIPAEVENT_HYPERVISOR_MSR_FILTER_POLICY = 327697;
	public const uint32 SIPAEVENT_VSM_LAUNCH_TYPE = 327698;
	public const uint32 SIPAEVENT_OS_REVOCATION_LIST = 327699;
	public const uint32 SIPAEVENT_SMT_STATUS = 327700;
	public const uint32 SIPAEVENT_VSM_IDK_INFO = 327712;
	public const uint32 SIPAEVENT_FLIGHTSIGNING = 327713;
	public const uint32 SIPAEVENT_PAGEFILE_ENCRYPTION_ENABLED = 327714;
	public const uint32 SIPAEVENT_VSM_IDKS_INFO = 327715;
	public const uint32 SIPAEVENT_HIBERNATION_DISABLED = 327716;
	public const uint32 SIPAEVENT_DUMPS_DISABLED = 327717;
	public const uint32 SIPAEVENT_DUMP_ENCRYPTION_ENABLED = 327718;
	public const uint32 SIPAEVENT_DUMP_ENCRYPTION_KEY_DIGEST = 327719;
	public const uint32 SIPAEVENT_LSAISO_CONFIG = 327720;
	public const uint32 SIPAEVENT_SBCP_INFO = 327721;
	public const uint32 SIPAEVENT_HYPERVISOR_BOOT_DMA_PROTECTION = 327728;
	public const uint32 SIPAEVENT_NOAUTHORITY = 393217;
	public const uint32 SIPAEVENT_AUTHORITYPUBKEY = 393218;
	public const uint32 SIPAEVENT_FILEPATH = 458753;
	public const uint32 SIPAEVENT_IMAGESIZE = 458754;
	public const uint32 SIPAEVENT_HASHALGORITHMID = 458755;
	public const uint32 SIPAEVENT_AUTHENTICODEHASH = 458756;
	public const uint32 SIPAEVENT_AUTHORITYISSUER = 458757;
	public const uint32 SIPAEVENT_AUTHORITYSERIAL = 458758;
	public const uint32 SIPAEVENT_IMAGEBASE = 458759;
	public const uint32 SIPAEVENT_AUTHORITYPUBLISHER = 458760;
	public const uint32 SIPAEVENT_AUTHORITYSHA1THUMBPRINT = 458761;
	public const uint32 SIPAEVENT_IMAGEVALIDATED = 458762;
	public const uint32 SIPAEVENT_MODULE_SVN = 458763;
	public const uint32 SIPAEVENT_ELAM_KEYNAME = 589825;
	public const uint32 SIPAEVENT_ELAM_CONFIGURATION = 589826;
	public const uint32 SIPAEVENT_ELAM_POLICY = 589827;
	public const uint32 SIPAEVENT_ELAM_MEASURED = 589828;
	public const uint32 SIPAEVENT_VBS_VSM_REQUIRED = 655361;
	public const uint32 SIPAEVENT_VBS_SECUREBOOT_REQUIRED = 655362;
	public const uint32 SIPAEVENT_VBS_IOMMU_REQUIRED = 655363;
	public const uint32 SIPAEVENT_VBS_MMIO_NX_REQUIRED = 655364;
	public const uint32 SIPAEVENT_VBS_MSR_FILTERING_REQUIRED = 655365;
	public const uint32 SIPAEVENT_VBS_MANDATORY_ENFORCEMENT = 655366;
	public const uint32 SIPAEVENT_VBS_HVCI_POLICY = 655367;
	public const uint32 SIPAEVENT_VBS_MICROSOFT_BOOT_CHAIN_REQUIRED = 655368;
	public const uint32 SIPAEVENT_VBS_DUMP_USES_AMEROOT = 655369;
	public const uint32 SIPAEVENT_VBS_VSM_NOSECRETS_ENFORCED = 655370;
	public const uint32 SIPAEVENT_KSR_SIGNATURE = 720897;
	public const uint32 SIPAEVENT_DRTM_STATE_AUTH = 786433;
	public const uint32 SIPAEVENT_DRTM_SMM_LEVEL = 786434;
	public const uint32 SIPAEVENT_DRTM_AMD_SMM_HASH = 786435;
	public const uint32 SIPAEVENT_DRTM_AMD_SMM_SIGNER_KEY = 786436;
	public const uint32 FVEB_UNLOCK_FLAG_NONE = 0;
	public const uint32 FVEB_UNLOCK_FLAG_CACHED = 1;
	public const uint32 FVEB_UNLOCK_FLAG_MEDIA = 2;
	public const uint32 FVEB_UNLOCK_FLAG_TPM = 4;
	public const uint32 FVEB_UNLOCK_FLAG_PIN = 16;
	public const uint32 FVEB_UNLOCK_FLAG_EXTERNAL = 32;
	public const uint32 FVEB_UNLOCK_FLAG_RECOVERY = 64;
	public const uint32 FVEB_UNLOCK_FLAG_PASSPHRASE = 128;
	public const uint32 FVEB_UNLOCK_FLAG_NBP = 256;
	public const uint32 FVEB_UNLOCK_FLAG_AUK_OSFVEINFO = 512;
	public const uint32 OSDEVICE_TYPE_UNKNOWN = 0;
	public const uint32 OSDEVICE_TYPE_BLOCKIO_HARDDISK = 65537;
	public const uint32 OSDEVICE_TYPE_BLOCKIO_REMOVABLEDISK = 65538;
	public const uint32 OSDEVICE_TYPE_BLOCKIO_CDROM = 65539;
	public const uint32 OSDEVICE_TYPE_BLOCKIO_PARTITION = 65540;
	public const uint32 OSDEVICE_TYPE_BLOCKIO_FILE = 65541;
	public const uint32 OSDEVICE_TYPE_BLOCKIO_RAMDISK = 65542;
	public const uint32 OSDEVICE_TYPE_BLOCKIO_VIRTUALHARDDISK = 65543;
	public const uint32 OSDEVICE_TYPE_SERIAL = 131072;
	public const uint32 OSDEVICE_TYPE_UDP = 196608;
	public const uint32 OSDEVICE_TYPE_VMBUS = 262144;
	public const uint32 OSDEVICE_TYPE_COMPOSITE = 327680;
	public const uint32 SIPAHDRSIGNATURE = 1279476311;
	public const uint32 SIPALOGVERSION = 1;
	public const uint32 SIPAKSRHDRSIGNATURE = 1297240907;
	public const uint32 WBCL_DIGEST_ALG_ID_SHA_1 = 4;
	public const uint32 WBCL_DIGEST_ALG_ID_SHA_2_256 = 11;
	public const uint32 WBCL_DIGEST_ALG_ID_SHA_2_384 = 12;
	public const uint32 WBCL_DIGEST_ALG_ID_SHA_2_512 = 13;
	public const uint32 WBCL_DIGEST_ALG_ID_SM3_256 = 18;
	public const uint32 WBCL_DIGEST_ALG_ID_SHA3_256 = 39;
	public const uint32 WBCL_DIGEST_ALG_ID_SHA3_384 = 40;
	public const uint32 WBCL_DIGEST_ALG_ID_SHA3_512 = 41;
	public const uint32 WBCL_DIGEST_ALG_BITMAP_SHA_1 = 1;
	public const uint32 WBCL_DIGEST_ALG_BITMAP_SHA_2_256 = 2;
	public const uint32 WBCL_DIGEST_ALG_BITMAP_SHA_2_384 = 4;
	public const uint32 WBCL_DIGEST_ALG_BITMAP_SHA_2_512 = 8;
	public const uint32 WBCL_DIGEST_ALG_BITMAP_SM3_256 = 16;
	public const uint32 WBCL_DIGEST_ALG_BITMAP_SHA3_256 = 32;
	public const uint32 WBCL_DIGEST_ALG_BITMAP_SHA3_384 = 64;
	public const uint32 WBCL_DIGEST_ALG_BITMAP_SHA3_512 = 128;
	public const uint32 WBCL_HASH_LEN_SHA1 = 20;
	public const int32 IS_GUAR_RSPEC = 130;
	public const int32 GUAR_ADSPARM_C = 131;
	public const int32 GUAR_ADSPARM_D = 132;
	public const int32 GUAR_ADSPARM_Ctot = 133;
	public const int32 GUAR_ADSPARM_Dtot = 134;
	public const int32 GUAR_ADSPARM_Csum = 135;
	public const int32 GUAR_ADSPARM_Dsum = 136;
}
#endregion

#region TypeDefs
typealias LPM_HANDLE = int;

typealias RHANDLE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum int_serv_wkp : int32
{
	IS_WKP_HOP_CNT = 4,
	IS_WKP_PATH_BW = 6,
	IS_WKP_MIN_LATENCY = 8,
	IS_WKP_COMPOSED_MTU = 10,
	IS_WKP_TB_TSPEC = 127,
	IS_WKP_Q_TSPEC = 128,
}


[AllowDuplicates]
public enum QOS_TRAFFIC_TYPE : int32
{
	QOSTrafficTypeBestEffort = 0,
	QOSTrafficTypeBackground = 1,
	QOSTrafficTypeExcellentEffort = 2,
	QOSTrafficTypeAudioVideo = 3,
	QOSTrafficTypeVoice = 4,
	QOSTrafficTypeControl = 5,
}


[AllowDuplicates]
public enum QOS_SET_FLOW : int32
{
	QOSSetTrafficType = 0,
	QOSSetOutgoingRate = 1,
	QOSSetOutgoingDSCPValue = 2,
}


[AllowDuplicates]
public enum QOS_FLOWRATE_REASON : int32
{
	QOSFlowRateNotApplicable = 0,
	QOSFlowRateContentChange = 1,
	QOSFlowRateCongestion = 2,
	QOSFlowRateHigherContentEncoding = 3,
	QOSFlowRateUserCaused = 4,
}


[AllowDuplicates]
public enum QOS_SHAPING : int32
{
	QOSShapeOnly = 0,
	QOSShapeAndMark = 1,
	QOSUseNonConformantMarkings = 2,
}


[AllowDuplicates]
public enum QOS_QUERY_FLOW : int32
{
	QOSQueryFlowFundamentals = 0,
	QOSQueryPacketPriority = 1,
	QOSQueryOutgoingRate = 2,
}


[AllowDuplicates]
public enum QOS_NOTIFY_FLOW : int32
{
	QOSNotifyCongested = 0,
	QOSNotifyUncongested = 1,
	QOSNotifyAvailable = 2,
}


[AllowDuplicates]
public enum FilterType : int32
{
	FILTERSPECV4 = 1,
	FILTERSPECV6 = 2,
	FILTERSPECV6_FLOW = 3,
	FILTERSPECV4_GPI = 4,
	FILTERSPECV6_GPI = 5,
	FILTERSPEC_END = 6,
}

#endregion

#region Function Pointers
public function void* PALLOCMEM(uint32 Size);

public function void PFREEMEM(void* pv);

public function uint32* CBADMITRESULT(LPM_HANDLE LpmHandle, RHANDLE RequestHandle, uint32 ulPcmActionFlags, int32 LpmError, int32 PolicyDecisionsCount, POLICY_DECISION* pPolicyDecisions);

public function uint32* CBGETRSVPOBJECTS(LPM_HANDLE LpmHandle, RHANDLE RequestHandle, int32 LpmError, int32 RsvpObjectsCount, RsvpObjHdr** ppRsvpObjects);

public function void TCI_NOTIFY_HANDLER(HANDLE ClRegCtx, HANDLE ClIfcCtx, uint32 Event, HANDLE SubCode, uint32 BufSize, void* Buffer);

public function void TCI_ADD_FLOW_COMPLETE_HANDLER(HANDLE ClFlowCtx, uint32 Status);

public function void TCI_MOD_FLOW_COMPLETE_HANDLER(HANDLE ClFlowCtx, uint32 Status);

public function void TCI_DEL_FLOW_COMPLETE_HANDLER(HANDLE ClFlowCtx, uint32 Status);

#endregion

#region Structs
[CRepr]
public struct QOS_OBJECT_HDR
{
	public uint32 ObjectType;
	public uint32 ObjectLength;
}

[CRepr]
public struct QOS_SD_MODE
{
	public QOS_OBJECT_HDR ObjectHdr;
	public uint32 ShapeDiscardMode;
}

[CRepr]
public struct QOS_SHAPING_RATE
{
	public QOS_OBJECT_HDR ObjectHdr;
	public uint32 ShapingRate;
}

[CRepr]
public struct RsvpObjHdr
{
	public uint16 obj_length;
	public uint8 obj_class;
	public uint8 obj_ctype;
}

[CRepr]
public struct Session_IPv4
{
	public IN_ADDR sess_destaddr;
	public uint8 sess_protid;
	public uint8 sess_flags;
	public uint16 sess_destport;
}

[CRepr]
public struct RSVP_SESSION
{
	[CRepr, Union]
	public struct _sess_u_e__Union
	{
		public Session_IPv4 sess_ipv4;
	}
	public RsvpObjHdr sess_header;
	public _sess_u_e__Union sess_u;
}

[CRepr]
public struct Rsvp_Hop_IPv4
{
	public IN_ADDR hop_ipaddr;
	public uint32 hop_LIH;
}

[CRepr]
public struct RSVP_HOP
{
	[CRepr, Union]
	public struct _hop_u_e__Union
	{
		public Rsvp_Hop_IPv4 hop_ipv4;
	}
	public RsvpObjHdr hop_header;
	public _hop_u_e__Union hop_u;
}

[CRepr]
public struct RESV_STYLE
{
	public RsvpObjHdr style_header;
	public uint32 style_word;
}

[CRepr]
public struct Filter_Spec_IPv4
{
	public IN_ADDR filt_ipaddr;
	public uint16 filt_unused;
	public uint16 filt_port;
}

[CRepr]
public struct Filter_Spec_IPv4GPI
{
	public IN_ADDR filt_ipaddr;
	public uint32 filt_gpi;
}

[CRepr]
public struct FILTER_SPEC
{
	[CRepr, Union]
	public struct _filt_u_e__Union
	{
		public Filter_Spec_IPv4 filt_ipv4;
		public Filter_Spec_IPv4GPI filt_ipv4gpi;
	}
	public RsvpObjHdr filt_header;
	public _filt_u_e__Union filt_u;
}

[CRepr]
public struct Scope_list_ipv4
{
	public IN_ADDR* scopl_ipaddr mut => &scopl_ipaddr_impl;
	private IN_ADDR[ANYSIZE_ARRAY] scopl_ipaddr_impl;
}

[CRepr]
public struct RSVP_SCOPE
{
	[CRepr, Union]
	public struct _scope_u_e__Union
	{
		public Scope_list_ipv4 scopl_ipv4;
	}
	public RsvpObjHdr scopl_header;
	public _scope_u_e__Union scope_u;
}

[CRepr]
public struct Error_Spec_IPv4
{
	public IN_ADDR errs_errnode;
	public uint8 errs_flags;
	public uint8 errs_code;
	public uint16 errs_value;
}

[CRepr]
public struct ERROR_SPEC
{
	[CRepr, Union]
	public struct _errs_u_e__Union
	{
		public Error_Spec_IPv4 errs_ipv4;
	}
	public RsvpObjHdr errs_header;
	public _errs_u_e__Union errs_u;
}

[CRepr]
public struct POLICY_DATA
{
	public RsvpObjHdr PolicyObjHdr;
	public uint16 usPeOffset;
	public uint16 usReserved;
}

[CRepr]
public struct POLICY_ELEMENT
{
	public uint16 usPeLength;
	public uint16 usPeType;
	public uint8[4] ucPeData;
}

[CRepr]
public struct IntServMainHdr
{
	public uint8 ismh_version;
	public uint8 ismh_unused;
	public uint16 ismh_len32b;
}

[CRepr]
public struct IntServServiceHdr
{
	public uint8 issh_service;
	public uint8 issh_flags;
	public uint16 issh_len32b;
}

[CRepr]
public struct IntServParmHdr
{
	public uint8 isph_parm_num;
	public uint8 isph_flags;
	public uint16 isph_len32b;
}

[CRepr]
public struct GenTspecParms
{
	public float TB_Tspec_r;
	public float TB_Tspec_b;
	public float TB_Tspec_p;
	public uint32 TB_Tspec_m;
	public uint32 TB_Tspec_M;
}

[CRepr]
public struct GenTspec
{
	public IntServServiceHdr gen_Tspec_serv_hdr;
	public IntServParmHdr gen_Tspec_parm_hdr;
	public GenTspecParms gen_Tspec_parms;
}

[CRepr]
public struct QualTspecParms
{
	public uint32 TB_Tspec_M;
}

[CRepr]
public struct QualTspec
{
	public IntServServiceHdr qual_Tspec_serv_hdr;
	public IntServParmHdr qual_Tspec_parm_hdr;
	public QualTspecParms qual_Tspec_parms;
}

[CRepr]
public struct QualAppFlowSpec
{
	public IntServServiceHdr Q_spec_serv_hdr;
	public IntServParmHdr Q_spec_parm_hdr;
	public QualTspecParms Q_spec_parms;
}

[CRepr]
public struct IntServTspecBody
{
	[CRepr, Union]
	public struct _tspec_u_e__Union
	{
		public GenTspec gen_stspec;
		public QualTspec qual_stspec;
	}
	public IntServMainHdr st_mh;
	public _tspec_u_e__Union tspec_u;
}

[CRepr]
public struct SENDER_TSPEC
{
	public RsvpObjHdr stspec_header;
	public IntServTspecBody stspec_body;
}

[CRepr]
public struct CtrlLoadFlowspec
{
	public IntServServiceHdr CL_spec_serv_hdr;
	public IntServParmHdr CL_spec_parm_hdr;
	public GenTspecParms CL_spec_parms;
}

[CRepr]
public struct GuarRspec
{
	public float Guar_R;
	public uint32 Guar_S;
}

[CRepr]
public struct GuarFlowSpec
{
	public IntServServiceHdr Guar_serv_hdr;
	public IntServParmHdr Guar_Tspec_hdr;
	public GenTspecParms Guar_Tspec_parms;
	public IntServParmHdr Guar_Rspec_hdr;
	public GuarRspec Guar_Rspec;
}

[CRepr]
public struct IntServFlowSpec
{
	[CRepr, Union]
	public struct _spec_u_e__Union
	{
		public CtrlLoadFlowspec CL_spec;
		public GuarFlowSpec G_spec;
		public QualAppFlowSpec Q_spec;
	}
	public IntServMainHdr spec_mh;
	public _spec_u_e__Union spec_u;
}

[CRepr]
public struct IS_FLOWSPEC
{
	public RsvpObjHdr flow_header;
	public IntServFlowSpec flow_body;
}

[CRepr]
public struct FLOW_DESC
{
	[CRepr, Union]
	public struct _u1_e__Union
	{
		public SENDER_TSPEC* stspec;
		public IS_FLOWSPEC* isflow;
	}
	[CRepr, Union]
	public struct _u2_e__Union
	{
		public FILTER_SPEC* stemp;
		public FILTER_SPEC* fspec;
	}
	public _u1_e__Union u1;
	public _u2_e__Union u2;
}

[CRepr]
public struct Gads_parms_t
{
	public IntServServiceHdr Gads_serv_hdr;
	public IntServParmHdr Gads_Ctot_hdr;
	public uint32 Gads_Ctot;
	public IntServParmHdr Gads_Dtot_hdr;
	public uint32 Gads_Dtot;
	public IntServParmHdr Gads_Csum_hdr;
	public uint32 Gads_Csum;
	public IntServParmHdr Gads_Dsum_hdr;
	public uint32 Gads_Dsum;
}

[CRepr]
public struct GenAdspecParams
{
	public IntServServiceHdr gen_parm_hdr;
	public IntServParmHdr gen_parm_hopcnt_hdr;
	public uint32 gen_parm_hopcnt;
	public IntServParmHdr gen_parm_pathbw_hdr;
	public float gen_parm_path_bw;
	public IntServParmHdr gen_parm_minlat_hdr;
	public uint32 gen_parm_min_latency;
	public IntServParmHdr gen_parm_compmtu_hdr;
	public uint32 gen_parm_composed_MTU;
}

[CRepr]
public struct IS_ADSPEC_BODY
{
	public IntServMainHdr adspec_mh;
	public GenAdspecParams adspec_genparms;
}

[CRepr]
public struct ADSPEC
{
	public RsvpObjHdr adspec_header;
	public IS_ADSPEC_BODY adspec_body;
}

[CRepr]
public struct ID_ERROR_OBJECT
{
	public uint16 usIdErrLength;
	public uint8 ucAType;
	public uint8 ucSubType;
	public uint16 usReserved;
	public uint16 usIdErrorValue;
	public uint8[4] ucIdErrData;
}

[CRepr]
public struct RSVP_MSG_OBJS
{
	public int32 RsvpMsgType;
	public RSVP_SESSION* pRsvpSession;
	public RSVP_HOP* pRsvpFromHop;
	public RSVP_HOP* pRsvpToHop;
	public RESV_STYLE* pResvStyle;
	public RSVP_SCOPE* pRsvpScope;
	public int32 FlowDescCount;
	public FLOW_DESC* pFlowDescs;
	public int32 PdObjectCount;
	public POLICY_DATA** ppPdObjects;
	public ERROR_SPEC* pErrorSpec;
	public ADSPEC* pAdspec;
}

[CRepr]
public struct POLICY_DECISION
{
	public uint32 lpvResult;
	public uint16 wPolicyErrCode;
	public uint16 wPolicyErrValue;
}

[CRepr]
public struct LPM_INIT_INFO
{
	public uint32 PcmVersionNumber;
	public uint32 ResultTimeLimit;
	public int32 ConfiguredLpmCount;
	public PALLOCMEM AllocMemory;
	public PFREEMEM FreeMemory;
	public CBADMITRESULT PcmAdmitResultCallback;
	public CBGETRSVPOBJECTS GetRsvpObjectsCallback;
}

[CRepr]
public struct LPMIPTABLE
{
	public uint32 ulIfIndex;
	public uint32 MediaType;
	public IN_ADDR IfIpAddr;
	public IN_ADDR IfNetMask;
}

[CRepr]
public struct QOS_PACKET_PRIORITY
{
	public uint32 ConformantDSCPValue;
	public uint32 NonConformantDSCPValue;
	public uint32 ConformantL2Value;
	public uint32 NonConformantL2Value;
}

[CRepr]
public struct QOS_FLOW_FUNDAMENTALS
{
	public BOOL BottleneckBandwidthSet;
	public uint64 BottleneckBandwidth;
	public BOOL AvailableBandwidthSet;
	public uint64 AvailableBandwidth;
	public BOOL RTTSet;
	public uint32 RTT;
}

[CRepr]
public struct QOS_FLOWRATE_OUTGOING
{
	public uint64 Bandwidth;
	public QOS_SHAPING ShapingBehavior;
	public QOS_FLOWRATE_REASON Reason;
}

[CRepr]
public struct QOS_VERSION
{
	public uint16 MajorVersion;
	public uint16 MinorVersion;
}

[CRepr]
public struct QOS_FRIENDLY_NAME
{
	public QOS_OBJECT_HDR ObjectHdr;
	public char16[256] FriendlyName;
}

[CRepr]
public struct QOS_TRAFFIC_CLASS
{
	public QOS_OBJECT_HDR ObjectHdr;
	public uint32 TrafficClass;
}

[CRepr]
public struct QOS_DS_CLASS
{
	public QOS_OBJECT_HDR ObjectHdr;
	public uint32 DSField;
}

[CRepr]
public struct QOS_DIFFSERV
{
	public QOS_OBJECT_HDR ObjectHdr;
	public uint32 DSFieldCount;
	public uint8* DiffservRule mut => &DiffservRule_impl;
	private uint8[ANYSIZE_ARRAY] DiffservRule_impl;
}

[CRepr]
public struct QOS_DIFFSERV_RULE
{
	public uint8 InboundDSField;
	public uint8 ConformingOutboundDSField;
	public uint8 NonConformingOutboundDSField;
	public uint8 ConformingUserPriority;
	public uint8 NonConformingUserPriority;
}

[CRepr]
public struct QOS_TCP_TRAFFIC
{
	public QOS_OBJECT_HDR ObjectHdr;
}

[CRepr]
public struct TCI_CLIENT_FUNC_LIST
{
	public TCI_NOTIFY_HANDLER ClNotifyHandler;
	public TCI_ADD_FLOW_COMPLETE_HANDLER ClAddFlowCompleteHandler;
	public TCI_MOD_FLOW_COMPLETE_HANDLER ClModifyFlowCompleteHandler;
	public TCI_DEL_FLOW_COMPLETE_HANDLER ClDeleteFlowCompleteHandler;
}

[CRepr]
public struct ADDRESS_LIST_DESCRIPTOR
{
	public uint32 MediaType;
	public NETWORK_ADDRESS_LIST AddressList;
}

[CRepr]
public struct TC_IFC_DESCRIPTOR
{
	public uint32 Length;
	public PWSTR pInterfaceName;
	public PWSTR pInterfaceID;
	public ADDRESS_LIST_DESCRIPTOR AddressListDesc;
}

[CRepr]
public struct TC_SUPPORTED_INFO_BUFFER
{
	public uint16 InstanceIDLength;
	public char16[256] InstanceID;
	public uint64 InterfaceLuid;
	public ADDRESS_LIST_DESCRIPTOR AddrListDesc;
}

[CRepr]
public struct TC_GEN_FILTER
{
	public uint16 AddressType;
	public uint32 PatternSize;
	public void* Pattern;
	public void* Mask;
}

[CRepr]
public struct TC_GEN_FLOW
{
	public FLOWSPEC SendingFlowspec;
	public FLOWSPEC ReceivingFlowspec;
	public uint32 TcObjectsLength;
	public QOS_OBJECT_HDR* TcObjects mut => &TcObjects_impl;
	private QOS_OBJECT_HDR[ANYSIZE_ARRAY] TcObjects_impl;
}

[CRepr]
public struct IP_PATTERN
{
	[CRepr, Union]
	public struct _S_un_e__Union
	{
		[CRepr]
		public struct _S_un_ports_e__Struct
		{
			public uint16 s_srcport;
			public uint16 s_dstport;
		}
		[CRepr]
		public struct _S_un_icmp_e__Struct
		{
			public uint8 s_type;
			public uint8 s_code;
			public uint16 filler;
		}
		public _S_un_ports_e__Struct S_un_ports;
		public _S_un_icmp_e__Struct S_un_icmp;
		public uint32 S_Spi;
	}
	public uint32 Reserved1;
	public uint32 Reserved2;
	public uint32 SrcAddr;
	public uint32 DstAddr;
	public _S_un_e__Union S_un;
	public uint8 ProtocolId;
	public uint8[3] Reserved3;
}

[CRepr]
public struct IPX_PATTERN
{
	[CRepr]
	public struct _Src_e__Struct
	{
		public uint32 NetworkAddress;
		public uint8[6] NodeAddress;
		public uint16 Socket;
	}
	public _Src_e__Struct Src;
	public _Src_e__Struct Dest;
}

[CRepr]
public struct ENUMERATION_BUFFER
{
	public uint32 Length;
	public uint32 OwnerProcessId;
	public uint16 FlowNameLength;
	public char16[256] FlowName;
	public TC_GEN_FLOW* pFlow;
	public uint32 NumberOfFilters;
	public TC_GEN_FILTER* GenericFilter mut => &GenericFilter_impl;
	private TC_GEN_FILTER[ANYSIZE_ARRAY] GenericFilter_impl;
}

[CRepr, Union]
public struct IN_ADDR_IPV4
{
	public uint32 Addr;
	public uint8[4] AddrBytes;
}

[CRepr]
public struct IN_ADDR_IPV6
{
	public uint8[16] Addr;
}

[CRepr]
public struct RSVP_FILTERSPEC_V4
{
	public IN_ADDR_IPV4 Address;
	public uint16 Unused;
	public uint16 Port;
}

[CRepr]
public struct RSVP_FILTERSPEC_V6
{
	public IN_ADDR_IPV6 Address;
	public uint16 UnUsed;
	public uint16 Port;
}

[CRepr]
public struct RSVP_FILTERSPEC_V6_FLOW
{
	public IN_ADDR_IPV6 Address;
	public uint8 UnUsed;
	public uint8[3] FlowLabel;
}

[CRepr]
public struct RSVP_FILTERSPEC_V4_GPI
{
	public IN_ADDR_IPV4 Address;
	public uint32 GeneralPortId;
}

[CRepr]
public struct RSVP_FILTERSPEC_V6_GPI
{
	public IN_ADDR_IPV6 Address;
	public uint32 GeneralPortId;
}

[CRepr]
public struct RSVP_FILTERSPEC
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public RSVP_FILTERSPEC_V4 FilterSpecV4;
		public RSVP_FILTERSPEC_V6 FilterSpecV6;
		public RSVP_FILTERSPEC_V6_FLOW FilterSpecV6Flow;
		public RSVP_FILTERSPEC_V4_GPI FilterSpecV4Gpi;
		public RSVP_FILTERSPEC_V6_GPI FilterSpecV6Gpi;
	}
	public FilterType Type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct FLOWDESCRIPTOR
{
	public FLOWSPEC FlowSpec;
	public uint32 NumFilters;
	public RSVP_FILTERSPEC* FilterList;
}

[CRepr]
public struct RSVP_POLICY
{
	public uint16 Len;
	public uint16 Type;
	public uint8[4] Info;
}

[CRepr]
public struct RSVP_POLICY_INFO
{
	public QOS_OBJECT_HDR ObjectHdr;
	public uint32 NumPolicyElement;
	public RSVP_POLICY* PolicyElement mut => &PolicyElement_impl;
	private RSVP_POLICY[ANYSIZE_ARRAY] PolicyElement_impl;
}

[CRepr]
public struct RSVP_RESERVE_INFO
{
	public QOS_OBJECT_HDR ObjectHdr;
	public uint32 Style;
	public uint32 ConfirmRequest;
	public RSVP_POLICY_INFO* PolicyElementList;
	public uint32 NumFlowDesc;
	public FLOWDESCRIPTOR* FlowDescList;
}

[CRepr]
public struct RSVP_STATUS_INFO
{
	public QOS_OBJECT_HDR ObjectHdr;
	public uint32 StatusCode;
	public uint32 ExtendedStatus1;
	public uint32 ExtendedStatus2;
}

[CRepr]
public struct QOS_DESTADDR
{
	public QOS_OBJECT_HDR ObjectHdr;
	public SOCKADDR* SocketAddress;
	public uint32 SocketAddressLength;
}

[CRepr]
public struct AD_GENERAL_PARAMS
{
	public uint32 IntServAwareHopCount;
	public uint32 PathBandwidthEstimate;
	public uint32 MinimumLatency;
	public uint32 PathMTU;
	public uint32 Flags;
}

[CRepr]
public struct AD_GUARANTEED
{
	public uint32 CTotal;
	public uint32 DTotal;
	public uint32 CSum;
	public uint32 DSum;
}

[CRepr]
public struct PARAM_BUFFER
{
	public uint32 ParameterId;
	public uint32 Length;
	public uint8* Buffer mut => &Buffer_impl;
	private uint8[ANYSIZE_ARRAY] Buffer_impl;
}

[CRepr]
public struct CONTROL_SERVICE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public AD_GUARANTEED Guaranteed;
		public PARAM_BUFFER* ParamBuffer mut => &ParamBuffer_impl;
		private PARAM_BUFFER[ANYSIZE_ARRAY] ParamBuffer_impl;
	}
	public uint32 Length;
	public uint32 Service;
	public AD_GENERAL_PARAMS Overrides;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct RSVP_ADSPEC
{
	public QOS_OBJECT_HDR ObjectHdr;
	public AD_GENERAL_PARAMS GeneralParams;
	public uint32 NumberOfServices;
	public CONTROL_SERVICE* Services mut => &Services_impl;
	private CONTROL_SERVICE[ANYSIZE_ARRAY] Services_impl;
}

[CRepr]
public struct IDPE_ATTR
{
	public uint16 PeAttribLength;
	public uint8 PeAttribType;
	public uint8 PeAttribSubType;
	public uint8[4] PeAttribValue;
}

[CRepr, Packed(1)]
public struct WBCL_Iterator
{
	public void* firstElementPtr;
	public uint32 logSize;
	public void* currentElementPtr;
	public uint32 currentElementSize;
	public uint16 digestSize;
	public uint16 logFormat;
	public uint32 numberOfDigests;
	public void* digestSizes;
	public uint32 supportedAlgorithms;
	public uint16 hashAlgorithm;
}

[CRepr, Packed(1)]
public struct TCG_PCClientPCREventStruct
{
	public uint32 pcrIndex;
	public uint32 eventType;
	public uint8[20] digest;
	public uint32 eventDataSize;
	public uint8* event mut => &event_impl;
	private uint8[ANYSIZE_ARRAY] event_impl;
}

[CRepr, Packed(1)]
public struct TCG_PCClientTaggedEventStruct
{
	public uint32 EventID;
	public uint32 EventDataSize;
	public uint8* EventData mut => &EventData_impl;
	private uint8[ANYSIZE_ARRAY] EventData_impl;
}

[CRepr, Packed(1)]
public struct WBCL_LogHdr
{
	public uint32 signature;
	public uint32 version;
	public uint32 entries;
	public uint32 length;
}

[CRepr, Packed(1)]
public struct SIPAEVENT_VSM_IDK_RSA_INFO
{
	public uint32 KeyBitLength;
	public uint32 PublicExpLengthBytes;
	public uint32 ModulusSizeBytes;
	public uint8* PublicKeyData mut => &PublicKeyData_impl;
	private uint8[ANYSIZE_ARRAY] PublicKeyData_impl;
}

[CRepr, Packed(1)]
public struct SIPAEVENT_VSM_IDK_INFO_PAYLOAD
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public SIPAEVENT_VSM_IDK_RSA_INFO RsaKeyInfo;
	}
	public uint32 KeyAlgID;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Packed(1)]
public struct SIPAEVENT_SI_POLICY_PAYLOAD
{
	public uint64 PolicyVersion;
	public uint16 PolicyNameLength;
	public uint16 HashAlgID;
	public uint32 DigestLength;
	public uint8* VarLengthData mut => &VarLengthData_impl;
	private uint8[ANYSIZE_ARRAY] VarLengthData_impl;
}

[CRepr, Packed(1)]
public struct SIPAEVENT_REVOCATION_LIST_PAYLOAD
{
	public int64 CreationTime;
	public uint32 DigestLength;
	public uint16 HashAlgID;
	public uint8* Digest mut => &Digest_impl;
	private uint8[ANYSIZE_ARRAY] Digest_impl;
}

[CRepr, Packed(1)]
public struct SIPAEVENT_KSR_SIGNATURE_PAYLOAD
{
	public uint32 SignAlgID;
	public uint32 SignatureLength;
	public uint8* Signature mut => &Signature_impl;
	private uint8[ANYSIZE_ARRAY] Signature_impl;
}

[CRepr, Packed(1)]
public struct SIPAEVENT_SBCP_INFO_PAYLOAD_V1
{
	public uint32 PayloadVersion;
	public uint32 VarDataOffset;
	public uint16 HashAlgID;
	public uint16 DigestLength;
	public uint32 Options;
	public uint32 SignersCount;
	public uint8* VarData mut => &VarData_impl;
	private uint8[ANYSIZE_ARRAY] VarData_impl;
}

#endregion

#region Functions
public static
{
	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSCreateHandle(QOS_VERSION* Version, HANDLE* QOSHandle);

	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSCloseHandle(HANDLE QOSHandle);

	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSStartTrackingClient(HANDLE QOSHandle, SOCKADDR* DestAddr, uint32 Flags);

	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSStopTrackingClient(HANDLE QOSHandle, SOCKADDR* DestAddr, uint32 Flags);

	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSEnumerateFlows(HANDLE QOSHandle, uint32* Size, void* Buffer);

	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSAddSocketToFlow(HANDLE QOSHandle, SOCKET Socket, SOCKADDR* DestAddr, QOS_TRAFFIC_TYPE TrafficType, uint32 Flags, uint32* FlowId);

	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSRemoveSocketFromFlow(HANDLE QOSHandle, SOCKET Socket, uint32 FlowId, uint32 Flags);

	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSSetFlow(HANDLE QOSHandle, uint32 FlowId, QOS_SET_FLOW Operation, uint32 Size, void* Buffer, uint32 Flags, OVERLAPPED* Overlapped);

	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSQueryFlow(HANDLE QOSHandle, uint32 FlowId, QOS_QUERY_FLOW Operation, uint32* Size, void* Buffer, uint32 Flags, OVERLAPPED* Overlapped);

	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSNotifyFlow(HANDLE QOSHandle, uint32 FlowId, QOS_NOTIFY_FLOW Operation, uint32* Size, void* Buffer, uint32 Flags, OVERLAPPED* Overlapped);

	[Import("qwave.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QOSCancel(HANDLE QOSHandle, OVERLAPPED* Overlapped);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcRegisterClient(uint32 TciVersion, HANDLE ClRegCtx, TCI_CLIENT_FUNC_LIST* ClientHandlerList, HANDLE* pClientHandle);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcEnumerateInterfaces(HANDLE ClientHandle, uint32* pBufferSize, TC_IFC_DESCRIPTOR* InterfaceBuffer);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcOpenInterfaceA(PSTR pInterfaceName, HANDLE ClientHandle, HANDLE ClIfcCtx, HANDLE* pIfcHandle);
	public static uint32 TcOpenInterface(PSTR pInterfaceName, HANDLE ClientHandle, HANDLE ClIfcCtx, HANDLE* pIfcHandle) => TcOpenInterfaceA(pInterfaceName, ClientHandle, ClIfcCtx, pIfcHandle);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcOpenInterfaceW(PWSTR pInterfaceName, HANDLE ClientHandle, HANDLE ClIfcCtx, HANDLE* pIfcHandle);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcCloseInterface(HANDLE IfcHandle);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcQueryInterface(HANDLE IfcHandle, Guid* pGuidParam, BOOLEAN NotifyChange, uint32* pBufferSize, void* Buffer);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcSetInterface(HANDLE IfcHandle, Guid* pGuidParam, uint32 BufferSize, void* Buffer);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcQueryFlowA(PSTR pFlowName, Guid* pGuidParam, uint32* pBufferSize, void* Buffer);
	public static uint32 TcQueryFlow(PSTR pFlowName, Guid* pGuidParam, uint32* pBufferSize, void* Buffer) => TcQueryFlowA(pFlowName, pGuidParam, pBufferSize, Buffer);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcQueryFlowW(PWSTR pFlowName, Guid* pGuidParam, uint32* pBufferSize, void* Buffer);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcSetFlowA(PSTR pFlowName, Guid* pGuidParam, uint32 BufferSize, void* Buffer);
	public static uint32 TcSetFlow(PSTR pFlowName, Guid* pGuidParam, uint32 BufferSize, void* Buffer) => TcSetFlowA(pFlowName, pGuidParam, BufferSize, Buffer);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcSetFlowW(PWSTR pFlowName, Guid* pGuidParam, uint32 BufferSize, void* Buffer);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcAddFlow(HANDLE IfcHandle, HANDLE ClFlowCtx, uint32 Flags, TC_GEN_FLOW* pGenericFlow, HANDLE* pFlowHandle);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcGetFlowNameA(HANDLE FlowHandle, uint32 StrSize, uint8* pFlowName);
	public static uint32 TcGetFlowName(HANDLE FlowHandle, uint32 StrSize, uint8* pFlowName) => TcGetFlowNameA(FlowHandle, StrSize, pFlowName);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcGetFlowNameW(HANDLE FlowHandle, uint32 StrSize, char16* pFlowName);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcModifyFlow(HANDLE FlowHandle, TC_GEN_FLOW* pGenericFlow);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcAddFilter(HANDLE FlowHandle, TC_GEN_FILTER* pGenericFilter, HANDLE* pFilterHandle);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcDeregisterClient(HANDLE ClientHandle);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcDeleteFlow(HANDLE FlowHandle);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcDeleteFilter(HANDLE FilterHandle);

	[Import("TRAFFIC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TcEnumerateFlows(HANDLE IfcHandle, HANDLE* pEnumHandle, uint32* pFlowCount, uint32* pBufSize, ENUMERATION_BUFFER* Buffer);

}
#endregion
