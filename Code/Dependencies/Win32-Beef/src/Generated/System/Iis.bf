using Win32.Foundation;
using Win32.System.Com;
using Win32.Security.Cryptography;
using System;

namespace Win32.System.Iis;

#region Constants
public static
{
	public const String IISADMIN_EXTENSIONS_REG_KEYA = "SOFTWARE\\Microsoft\\InetStp\\Extensions";
	public const String IISADMIN_EXTENSIONS_REG_KEYW = "SOFTWARE\\Microsoft\\InetStp\\Extensions";
	public const String IISADMIN_EXTENSIONS_REG_KEY = "SOFTWARE\\Microsoft\\InetStp\\Extensions";
	public const String IISADMIN_EXTENSIONS_CLSID_MD_KEYA = "LM/IISADMIN/EXTENSIONS/DCOMCLSIDS";
	public const String IISADMIN_EXTENSIONS_CLSID_MD_KEYW = "LM/IISADMIN/EXTENSIONS/DCOMCLSIDS";
	public const String IISADMIN_EXTENSIONS_CLSID_MD_KEY = "LM/IISADMIN/EXTENSIONS/DCOMCLSIDS";
	public const uint32 ADMINDATA_MAX_NAME_LEN = 256;
	public const Guid CLSID_MSAdminBase_W = .(0xa9e69610, 0xb80d, 0x11d0, 0xb9, 0xb9, 0x00, 0xa0, 0xc9, 0x22, 0xe7, 0x50);
	public const uint32 IMGCHG_SIZE = 1;
	public const uint32 IMGCHG_VIEW = 2;
	public const uint32 IMGCHG_COMPLETE = 4;
	public const uint32 IMGCHG_ANIMATE = 8;
	public const uint32 IMGCHG_MASK = 15;
	public const uint32 IMGLOAD_NOTLOADED = 1048576;
	public const uint32 IMGLOAD_LOADING = 2097152;
	public const uint32 IMGLOAD_STOPPED = 4194304;
	public const uint32 IMGLOAD_ERROR = 8388608;
	public const uint32 IMGLOAD_COMPLETE = 16777216;
	public const uint32 IMGLOAD_MASK = 32505856;
	public const uint32 IMGBITS_NONE = 33554432;
	public const uint32 IMGBITS_PARTIAL = 67108864;
	public const uint32 IMGBITS_TOTAL = 134217728;
	public const uint32 IMGBITS_MASK = 234881024;
	public const uint32 IMGANIM_ANIMATED = 268435456;
	public const uint32 IMGANIM_MASK = 268435456;
	public const uint32 IMGTRANS_OPAQUE = 536870912;
	public const uint32 IMGTRANS_MASK = 536870912;
	public const uint32 DWN_COLORMODE = 63;
	public const uint32 DWN_DOWNLOADONLY = 64;
	public const uint32 DWN_FORCEDITHER = 128;
	public const uint32 DWN_RAWIMAGE = 256;
	public const uint32 DWN_MIRRORIMAGE = 512;
	public const Guid CLSID_IImgCtx = .(0x3050f3d6, 0x98b5, 0x11cf, 0xbb, 0x82, 0x00, 0xaa, 0x00, 0xbd, 0xce, 0x0b);
	public const String IIS_MD_LOCAL_MACHINE_PATH = "LM";
	public const String IIS_MD_INSTANCE_ROOT = "Root";
	public const String IIS_MD_ISAPI_FILTERS = "/Filters";
	public const String IIS_MD_SVC_INFO_PATH = "Info";
	public const String IIS_MD_ADSI_SCHEMA_PATH_A = "/Schema";
	public const String IIS_MD_ADSI_SCHEMA_PATH_W = "/Schema";
	public const uint32 IIS_MD_ADSI_METAID_BEGIN = 130000;
	public const uint32 IIS_MD_UT_SERVER = 1;
	public const uint32 IIS_MD_UT_FILE = 2;
	public const uint32 IIS_MD_UT_WAM = 100;
	public const uint32 ASP_MD_UT_APP = 101;
	public const uint32 IIS_MD_UT_END_RESERVED = 2000;
	public const uint32 IIS_MD_ID_BEGIN_RESERVED = 1;
	public const uint32 IIS_MD_ID_END_RESERVED = 32767;
	public const uint32 ASP_MD_ID_BEGIN_RESERVED = 28672;
	public const uint32 ASP_MD_ID_END_RESERVED = 29951;
	public const uint32 WAM_MD_ID_BEGIN_RESERVED = 29952;
	public const uint32 WAM_MD_ID_END_RESERVED = 32767;
	public const uint32 FP_MD_ID_BEGIN_RESERVED = 32768;
	public const uint32 FP_MD_ID_END_RESERVED = 36863;
	public const uint32 SMTP_MD_ID_BEGIN_RESERVED = 36864;
	public const uint32 SMTP_MD_ID_END_RESERVED = 40959;
	public const uint32 POP3_MD_ID_BEGIN_RESERVED = 40960;
	public const uint32 POP3_MD_ID_END_RESERVED = 45055;
	public const uint32 NNTP_MD_ID_BEGIN_RESERVED = 45056;
	public const uint32 NNTP_MD_ID_END_RESERVED = 49151;
	public const uint32 IMAP_MD_ID_BEGIN_RESERVED = 49152;
	public const uint32 IMAP_MD_ID_END_RESERVED = 53247;
	public const uint32 MSCS_MD_ID_BEGIN_RESERVED = 53248;
	public const uint32 MSCS_MD_ID_END_RESERVED = 57343;
	public const uint32 APPCTR_MD_ID_BEGIN_RESERVED = 57344;
	public const uint32 APPCTR_MD_ID_END_RESERVED = 61439;
	public const uint32 USER_MD_ID_BASE_RESERVED = 65535;
	public const uint32 IIS_MD_SERVER_BASE = 1000;
	public const uint32 MD_MAX_BANDWIDTH = 1000;
	public const uint32 MD_KEY_TYPE = 1002;
	public const uint32 MD_MAX_BANDWIDTH_BLOCKED = 1003;
	public const uint32 MD_SCHEMA_METAID = 1004;
	public const uint32 MD_SERVER_COMMAND = 1012;
	public const uint32 MD_CONNECTION_TIMEOUT = 1013;
	public const uint32 MD_MAX_CONNECTIONS = 1014;
	public const uint32 MD_SERVER_COMMENT = 1015;
	public const uint32 MD_SERVER_STATE = 1016;
	public const uint32 MD_SERVER_AUTOSTART = 1017;
	public const uint32 MD_SERVER_SIZE = 1018;
	public const uint32 MD_SERVER_LISTEN_BACKLOG = 1019;
	public const uint32 MD_SERVER_LISTEN_TIMEOUT = 1020;
	public const uint32 MD_DOWNLEVEL_ADMIN_INSTANCE = 1021;
	public const uint32 MD_LEVELS_TO_SCAN = 1022;
	public const uint32 MD_SERVER_BINDINGS = 1023;
	public const uint32 MD_MAX_ENDPOINT_CONNECTIONS = 1024;
	public const uint32 MD_SERVER_CONFIGURATION_INFO = 1027;
	public const uint32 MD_IISADMIN_EXTENSIONS = 1028;
	public const uint32 MD_DISABLE_SOCKET_POOLING = 1029;
	public const uint32 MD_METADATA_ID_REGISTRATION = 1030;
	public const uint32 IIS_MD_HTTP_BASE = 2000;
	public const uint32 MD_SECURE_BINDINGS = 2021;
	public const uint32 MD_BINDINGS = 2022;
	public const uint32 MD_ENABLEDPROTOCOLS = 2023;
	public const uint32 MD_FILTER_LOAD_ORDER = 2040;
	public const uint32 MD_FILTER_IMAGE_PATH = 2041;
	public const uint32 MD_FILTER_STATE = 2042;
	public const uint32 MD_FILTER_ENABLED = 2043;
	public const uint32 MD_FILTER_FLAGS = 2044;
	public const uint32 MD_FILTER_DESCRIPTION = 2045;
	public const uint32 MD_FILTER_ENABLE_CACHE = 2046;
	public const uint32 MD_ADV_NOTIFY_PWD_EXP_IN_DAYS = 2063;
	public const uint32 MD_ADV_CACHE_TTL = 2064;
	public const uint32 MD_NET_LOGON_WKS = 2065;
	public const uint32 MD_USE_HOST_NAME = 2066;
	public const uint32 MD_AUTH_CHANGE_FLAGS = 2068;
	public const uint32 MD_PROCESS_NTCR_IF_LOGGED_ON = 2070;
	public const uint32 MD_FRONTPAGE_WEB = 2072;
	public const uint32 MD_IN_PROCESS_ISAPI_APPS = 2073;
	public const uint32 MD_AUTH_CHANGE_URL = 2060;
	public const uint32 MD_AUTH_EXPIRED_URL = 2061;
	public const uint32 MD_AUTH_EXPIRED_UNSECUREURL = 2067;
	public const uint32 MD_ALLOW_PATH_INFO_FOR_SCRIPT_MAPPINGS = 2095;
	public const uint32 MD_APP_FRIENDLY_NAME = 2102;
	public const uint32 MD_APP_ROOT = 2103;
	public const uint32 MD_APP_ISOLATED = 2104;
	public const uint32 MD_APP_WAM_CLSID = 2105;
	public const uint32 MD_APP_PACKAGE_ID = 2106;
	public const uint32 MD_APP_PACKAGE_NAME = 2107;
	public const uint32 MD_APP_OOP_RECOVER_LIMIT = 2110;
	public const uint32 MD_APP_PERIODIC_RESTART_TIME = 2111;
	public const uint32 MD_APP_PERIODIC_RESTART_REQUESTS = 2112;
	public const uint32 MD_APP_PERIODIC_RESTART_SCHEDULE = 2113;
	public const uint32 MD_APP_SHUTDOWN_TIME_LIMIT = 2114;
	public const uint32 MD_ADMIN_INSTANCE = 2115;
	public const uint32 MD_NOT_DELETABLE = 2116;
	public const uint32 MD_APP_TRACE_URL_LIST = 2118;
	public const uint32 MD_CENTRAL_W3C_LOGGING_ENABLED = 2119;
	public const uint32 MD_CUSTOM_ERROR_DESC = 2120;
	public const uint32 MD_CAL_VC_PER_CONNECT = 2130;
	public const uint32 MD_CAL_AUTH_RESERVE_TIMEOUT = 2131;
	public const uint32 MD_CAL_SSL_RESERVE_TIMEOUT = 2132;
	public const uint32 MD_CAL_W3_ERROR = 2133;
	public const uint32 MD_CPU_CGI_ENABLED = 2140;
	public const uint32 MD_CPU_APP_ENABLED = 2141;
	public const uint32 MD_CPU_LIMITS_ENABLED = 2143;
	public const uint32 MD_CPU_RESET_INTERVAL = 2144;
	public const uint32 MD_CPU_LOGGING_INTERVAL = 2145;
	public const uint32 MD_CPU_LOGGING_OPTIONS = 2146;
	public const uint32 MD_CPU_CGI_LIMIT = 2148;
	public const uint32 MD_CPU_LIMIT_LOGEVENT = 2149;
	public const uint32 MD_CPU_LIMIT_PRIORITY = 2150;
	public const uint32 MD_CPU_LIMIT_PROCSTOP = 2151;
	public const uint32 MD_CPU_LIMIT_PAUSE = 2152;
	public const uint32 MD_SET_HOST_NAME = 2154;
	public const uint32 MD_CPU_DISABLE_ALL_LOGGING = 0;
	public const uint32 MD_CPU_ENABLE_ALL_PROC_LOGGING = 1;
	public const uint32 MD_CPU_ENABLE_CGI_LOGGING = 2;
	public const uint32 MD_CPU_ENABLE_APP_LOGGING = 4;
	public const uint32 MD_CPU_ENABLE_EVENT = 1;
	public const uint32 MD_CPU_ENABLE_PROC_TYPE = 2;
	public const uint32 MD_CPU_ENABLE_USER_TIME = 4;
	public const uint32 MD_CPU_ENABLE_KERNEL_TIME = 8;
	public const uint32 MD_CPU_ENABLE_PAGE_FAULTS = 16;
	public const uint32 MD_CPU_ENABLE_TOTAL_PROCS = 32;
	public const uint32 MD_CPU_ENABLE_ACTIVE_PROCS = 64;
	public const uint32 MD_CPU_ENABLE_TERMINATED_PROCS = 128;
	public const uint32 MD_CPU_ENABLE_LOGGING = 2147483648;
	public const uint32 MD_ISAPI_RESTRICTION_LIST = 2163;
	public const uint32 MD_CGI_RESTRICTION_LIST = 2164;
	public const uint32 MD_RESTRICTION_LIST_CUSTOM_DESC = 2165;
	public const uint32 MD_SECURITY_SETUP_REQUIRED = 2166;
	public const uint32 MD_APP_DEPENDENCIES = 2167;
	public const uint32 MD_WEB_SVC_EXT_RESTRICTION_LIST = 2168;
	public const uint32 MD_MD_SERVER_SS_AUTH_MAPPING = 2200;
	public const uint32 MD_CERT_NO_REVOC_CHECK = 1;
	public const uint32 MD_CERT_CACHE_RETRIEVAL_ONLY = 2;
	public const uint32 MD_CERT_CHECK_REVOCATION_FRESHNESS_TIME = 4;
	public const uint32 MD_CERT_NO_USAGE_CHECK = 65536;
	public const uint32 MD_HC_COMPRESSION_DIRECTORY = 2210;
	public const uint32 MD_HC_CACHE_CONTROL_HEADER = 2211;
	public const uint32 MD_HC_EXPIRES_HEADER = 2212;
	public const uint32 MD_HC_DO_DYNAMIC_COMPRESSION = 2213;
	public const uint32 MD_HC_DO_STATIC_COMPRESSION = 2214;
	public const uint32 MD_HC_DO_ON_DEMAND_COMPRESSION = 2215;
	public const uint32 MD_HC_DO_DISK_SPACE_LIMITING = 2216;
	public const uint32 MD_HC_NO_COMPRESSION_FOR_HTTP_10 = 2217;
	public const uint32 MD_HC_NO_COMPRESSION_FOR_PROXIES = 2218;
	public const uint32 MD_HC_NO_COMPRESSION_FOR_RANGE = 2219;
	public const uint32 MD_HC_SEND_CACHE_HEADERS = 2220;
	public const uint32 MD_HC_MAX_DISK_SPACE_USAGE = 2221;
	public const uint32 MD_HC_IO_BUFFER_SIZE = 2222;
	public const uint32 MD_HC_COMPRESSION_BUFFER_SIZE = 2223;
	public const uint32 MD_HC_MAX_QUEUE_LENGTH = 2224;
	public const uint32 MD_HC_FILES_DELETED_PER_DISK_FREE = 2225;
	public const uint32 MD_HC_MIN_FILE_SIZE_FOR_COMP = 2226;
	public const uint32 MD_HC_COMPRESSION_DLL = 2237;
	public const uint32 MD_HC_FILE_EXTENSIONS = 2238;
	public const uint32 MD_HC_MIME_TYPE = 2239;
	public const uint32 MD_HC_PRIORITY = 2240;
	public const uint32 MD_HC_DYNAMIC_COMPRESSION_LEVEL = 2241;
	public const uint32 MD_HC_ON_DEMAND_COMP_LEVEL = 2242;
	public const uint32 MD_HC_CREATE_FLAGS = 2243;
	public const uint32 MD_HC_SCRIPT_FILE_EXTENSIONS = 2244;
	public const uint32 MD_HC_DO_NAMESPACE_DYNAMIC_COMPRESSION = 2255;
	public const uint32 MD_HC_DO_NAMESPACE_STATIC_COMPRESSION = 2256;
	public const uint32 MD_WIN32_ERROR = 1099;
	public const uint32 IIS_MD_VR_BASE = 3000;
	public const uint32 MD_VR_PATH = 3001;
	public const uint32 MD_VR_USERNAME = 3002;
	public const uint32 MD_VR_PASSWORD = 3003;
	public const uint32 MD_VR_PASSTHROUGH = 3006;
	public const uint32 MD_VR_NO_CACHE = 3007;
	public const uint32 MD_VR_IGNORE_TRANSLATE = 3008;
	public const uint32 IIS_MD_LOG_BASE = 4000;
	public const uint32 MD_LOG_TYPE = 4000;
	public const uint32 MD_LOGFILE_DIRECTORY = 4001;
	public const uint32 MD_LOG_UNUSED1 = 4002;
	public const uint32 MD_LOGFILE_PERIOD = 4003;
	public const uint32 MD_LOGFILE_TRUNCATE_SIZE = 4004;
	public const uint32 MD_LOG_PLUGIN_MOD_ID = 4005;
	public const uint32 MD_LOG_PLUGIN_UI_ID = 4006;
	public const uint32 MD_LOGSQL_DATA_SOURCES = 4007;
	public const uint32 MD_LOGSQL_TABLE_NAME = 4008;
	public const uint32 MD_LOGSQL_USER_NAME = 4009;
	public const uint32 MD_LOGSQL_PASSWORD = 4010;
	public const uint32 MD_LOG_PLUGIN_ORDER = 4011;
	public const uint32 MD_LOG_PLUGINS_AVAILABLE = 4012;
	public const uint32 MD_LOGEXT_FIELD_MASK = 4013;
	public const uint32 MD_LOGEXT_FIELD_MASK2 = 4014;
	public const uint32 MD_LOGFILE_LOCALTIME_ROLLOVER = 4015;
	public const uint32 IIS_MD_LOG_LAST = 4015;
	public const uint32 MD_GLOBAL_BINARY_LOGGING_ENABLED = 4016;
	public const uint32 MD_LOG_TYPE_DISABLED = 0;
	public const uint32 MD_LOG_TYPE_ENABLED = 1;
	public const uint32 MD_LOGFILE_PERIOD_NONE = 0;
	public const uint32 MD_LOGFILE_PERIOD_MAXSIZE = 0;
	public const uint32 MD_LOGFILE_PERIOD_DAILY = 1;
	public const uint32 MD_LOGFILE_PERIOD_WEEKLY = 2;
	public const uint32 MD_LOGFILE_PERIOD_MONTHLY = 3;
	public const uint32 MD_LOGFILE_PERIOD_HOURLY = 4;
	public const uint32 MD_EXTLOG_DATE = 1;
	public const uint32 MD_EXTLOG_TIME = 2;
	public const uint32 MD_EXTLOG_CLIENT_IP = 4;
	public const uint32 MD_EXTLOG_USERNAME = 8;
	public const uint32 MD_EXTLOG_SITE_NAME = 16;
	public const uint32 MD_EXTLOG_COMPUTER_NAME = 32;
	public const uint32 MD_EXTLOG_SERVER_IP = 64;
	public const uint32 MD_EXTLOG_METHOD = 128;
	public const uint32 MD_EXTLOG_URI_STEM = 256;
	public const uint32 MD_EXTLOG_URI_QUERY = 512;
	public const uint32 MD_EXTLOG_HTTP_STATUS = 1024;
	public const uint32 MD_EXTLOG_WIN32_STATUS = 2048;
	public const uint32 MD_EXTLOG_BYTES_SENT = 4096;
	public const uint32 MD_EXTLOG_BYTES_RECV = 8192;
	public const uint32 MD_EXTLOG_TIME_TAKEN = 16384;
	public const uint32 MD_EXTLOG_SERVER_PORT = 32768;
	public const uint32 MD_EXTLOG_USER_AGENT = 65536;
	public const uint32 MD_EXTLOG_COOKIE = 131072;
	public const uint32 MD_EXTLOG_REFERER = 262144;
	public const uint32 MD_EXTLOG_PROTOCOL_VERSION = 524288;
	public const uint32 MD_EXTLOG_HOST = 1048576;
	public const uint32 MD_EXTLOG_HTTP_SUB_STATUS = 2097152;
	public const uint32 IIS_MD_LOGCUSTOM_BASE = 4500;
	public const uint32 MD_LOGCUSTOM_PROPERTY_NAME = 4501;
	public const uint32 MD_LOGCUSTOM_PROPERTY_HEADER = 4502;
	public const uint32 MD_LOGCUSTOM_PROPERTY_ID = 4503;
	public const uint32 MD_LOGCUSTOM_PROPERTY_MASK = 4504;
	public const uint32 MD_LOGCUSTOM_PROPERTY_DATATYPE = 4505;
	public const uint32 MD_LOGCUSTOM_SERVICES_STRING = 4506;
	public const uint32 MD_CPU_LOGGING_MASK = 4507;
	public const uint32 MD_LOGCUSTOM_PROPERTY_NODE_ID = 4508;
	public const uint32 IIS_MD_LOGCUSTOM_LAST = 4508;
	public const uint32 MD_LOGCUSTOM_DATATYPE_INT = 0;
	public const uint32 MD_LOGCUSTOM_DATATYPE_UINT = 1;
	public const uint32 MD_LOGCUSTOM_DATATYPE_LONG = 2;
	public const uint32 MD_LOGCUSTOM_DATATYPE_ULONG = 3;
	public const uint32 MD_LOGCUSTOM_DATATYPE_FLOAT = 4;
	public const uint32 MD_LOGCUSTOM_DATATYPE_DOUBLE = 5;
	public const uint32 MD_LOGCUSTOM_DATATYPE_LPSTR = 6;
	public const uint32 MD_LOGCUSTOM_DATATYPE_LPWSTR = 7;
	public const uint32 MD_NOTIFY_SECURE_PORT = 1;
	public const uint32 MD_NOTIFY_NONSECURE_PORT = 2;
	public const uint32 MD_NOTIFY_READ_RAW_DATA = 32768;
	public const uint32 MD_NOTIFY_PREPROC_HEADERS = 16384;
	public const uint32 MD_NOTIFY_AUTHENTICATION = 8192;
	public const uint32 MD_NOTIFY_URL_MAP = 4096;
	public const uint32 MD_NOTIFY_ACCESS_DENIED = 2048;
	public const uint32 MD_NOTIFY_SEND_RESPONSE = 64;
	public const uint32 MD_NOTIFY_SEND_RAW_DATA = 1024;
	public const uint32 MD_NOTIFY_LOG = 512;
	public const uint32 MD_NOTIFY_END_OF_REQUEST = 128;
	public const uint32 MD_NOTIFY_END_OF_NET_SESSION = 256;
	public const uint32 MD_NOTIFY_AUTH_COMPLETE = 67108864;
	public const uint32 MD_NOTIFY_ORDER_HIGH = 524288;
	public const uint32 MD_NOTIFY_ORDER_MEDIUM = 262144;
	public const uint32 MD_NOTIFY_ORDER_LOW = 131072;
	public const uint32 MD_NOTIFY_ORDER_DEFAULT = 131072;
	public const uint32 IIS_MD_FTP_BASE = 5000;
	public const uint32 MD_EXIT_MESSAGE = 5001;
	public const uint32 MD_GREETING_MESSAGE = 5002;
	public const uint32 MD_MAX_CLIENTS_MESSAGE = 5003;
	public const uint32 MD_MSDOS_DIR_OUTPUT = 5004;
	public const uint32 MD_ALLOW_ANONYMOUS = 5005;
	public const uint32 MD_ANONYMOUS_ONLY = 5006;
	public const uint32 MD_LOG_ANONYMOUS = 5007;
	public const uint32 MD_LOG_NONANONYMOUS = 5008;
	public const uint32 MD_ALLOW_REPLACE_ON_RENAME = 5009;
	public const uint32 MD_SHOW_4_DIGIT_YEAR = 5010;
	public const uint32 MD_BANNER_MESSAGE = 5011;
	public const uint32 MD_USER_ISOLATION = 5012;
	public const uint32 MD_FTP_LOG_IN_UTF_8 = 5013;
	public const uint32 MD_AD_CONNECTIONS_USERNAME = 5014;
	public const uint32 MD_AD_CONNECTIONS_PASSWORD = 5015;
	public const uint32 MD_PASSIVE_PORT_RANGE = 5016;
	public const uint32 MD_SUPPRESS_DEFAULT_BANNER = 5017;
	public const uint32 MD_FTP_PASV_RESPONSE_IP = 5018;
	public const uint32 MD_FTP_KEEP_PARTIAL_UPLOADS = 5019;
	public const uint32 MD_FTP_UTF8_FILE_NAMES = 5020;
	public const uint32 MD_FTPS_SECURE_CONTROL_CHANNEL = 5050;
	public const uint32 MD_FTPS_SECURE_DATA_CHANNEL = 5051;
	public const uint32 MD_FTPS_SECURE_ANONYMOUS = 5052;
	public const uint32 MD_FTPS_128_BITS = 5053;
	public const uint32 MD_FTPS_ALLOW_CCC = 5054;
	public const uint32 IIS_MD_SSL_BASE = 5500;
	public const uint32 MD_SSL_PUBLIC_KEY = 5500;
	public const uint32 MD_SSL_PRIVATE_KEY = 5501;
	public const uint32 MD_SSL_KEY_PASSWORD = 5502;
	public const uint32 MD_SSL_KEY_REQUEST = 5503;
	public const uint32 MD_SSL_USE_DS_MAPPER = 5519;
	public const uint32 MD_SSL_ALWAYS_NEGO_CLIENT_CERT = 5521;
	public const uint32 IIS_MD_FILE_PROP_BASE = 6000;
	public const uint32 MD_AUTHORIZATION = 6000;
	public const uint32 MD_REALM = 6001;
	public const uint32 MD_HTTP_EXPIRES = 6002;
	public const uint32 MD_HTTP_PICS = 6003;
	public const uint32 MD_HTTP_CUSTOM = 6004;
	public const uint32 MD_DIRECTORY_BROWSING = 6005;
	public const uint32 MD_DEFAULT_LOAD_FILE = 6006;
	public const uint32 MD_CUSTOM_ERROR = 6008;
	public const uint32 MD_FOOTER_DOCUMENT = 6009;
	public const uint32 MD_FOOTER_ENABLED = 6010;
	public const uint32 MD_HTTP_REDIRECT = 6011;
	public const uint32 MD_DEFAULT_LOGON_DOMAIN = 6012;
	public const uint32 MD_LOGON_METHOD = 6013;
	public const uint32 MD_SCRIPT_MAPS = 6014;
	public const uint32 MD_MIME_MAP = 6015;
	public const uint32 MD_ACCESS_PERM = 6016;
	public const uint32 MD_IP_SEC = 6019;
	public const uint32 MD_ANONYMOUS_USER_NAME = 6020;
	public const uint32 MD_ANONYMOUS_PWD = 6021;
	public const uint32 MD_ANONYMOUS_USE_SUBAUTH = 6022;
	public const uint32 MD_DONT_LOG = 6023;
	public const uint32 MD_ADMIN_ACL = 6027;
	public const uint32 MD_SSI_EXEC_DISABLED = 6028;
	public const uint32 MD_DO_REVERSE_DNS = 6029;
	public const uint32 MD_SSL_ACCESS_PERM = 6030;
	public const uint32 MD_AUTHORIZATION_PERSISTENCE = 6031;
	public const uint32 MD_NTAUTHENTICATION_PROVIDERS = 6032;
	public const uint32 MD_SCRIPT_TIMEOUT = 6033;
	public const uint32 MD_CACHE_EXTENSIONS = 6034;
	public const uint32 MD_CREATE_PROCESS_AS_USER = 6035;
	public const uint32 MD_CREATE_PROC_NEW_CONSOLE = 6036;
	public const uint32 MD_POOL_IDC_TIMEOUT = 6037;
	public const uint32 MD_ALLOW_KEEPALIVES = 6038;
	public const uint32 MD_IS_CONTENT_INDEXED = 6039;
	public const uint32 MD_CC_NO_CACHE = 6041;
	public const uint32 MD_CC_MAX_AGE = 6042;
	public const uint32 MD_CC_OTHER = 6043;
	public const uint32 MD_REDIRECT_HEADERS = 6044;
	public const uint32 MD_UPLOAD_READAHEAD_SIZE = 6045;
	public const uint32 MD_PUT_READ_SIZE = 6046;
	public const uint32 MD_USE_DIGEST_SSP = 6047;
	public const uint32 MD_ENABLE_URL_AUTHORIZATION = 6048;
	public const uint32 MD_URL_AUTHORIZATION_STORE_NAME = 6049;
	public const uint32 MD_URL_AUTHORIZATION_SCOPE_NAME = 6050;
	public const uint32 MD_MAX_REQUEST_ENTITY_ALLOWED = 6051;
	public const uint32 MD_PASSPORT_REQUIRE_AD_MAPPING = 6052;
	public const uint32 MD_URL_AUTHORIZATION_IMPERSONATION_LEVEL = 6053;
	public const uint32 MD_HTTP_FORWARDER_CUSTOM = 6054;
	public const uint32 MD_CUSTOM_DEPLOYMENT_DATA = 6055;
	public const uint32 MD_HTTPERRORS_EXISTING_RESPONSE = 6056;
	public const uint32 ASP_MD_SERVER_BASE = 7000;
	public const uint32 MD_ASP_BUFFERINGON = 7000;
	public const uint32 MD_ASP_LOGERRORREQUESTS = 7001;
	public const uint32 MD_ASP_SCRIPTERRORSSENTTOBROWSER = 7002;
	public const uint32 MD_ASP_SCRIPTERRORMESSAGE = 7003;
	public const uint32 MD_ASP_SCRIPTFILECACHESIZE = 7004;
	public const uint32 MD_ASP_SCRIPTENGINECACHEMAX = 7005;
	public const uint32 MD_ASP_SCRIPTTIMEOUT = 7006;
	public const uint32 MD_ASP_SESSIONTIMEOUT = 7007;
	public const uint32 MD_ASP_ENABLEPARENTPATHS = 7008;
	public const uint32 MD_ASP_MEMFREEFACTOR = 7009;
	public const uint32 MD_ASP_MINUSEDBLOCKS = 7010;
	public const uint32 MD_ASP_ALLOWSESSIONSTATE = 7011;
	public const uint32 MD_ASP_SCRIPTLANGUAGE = 7012;
	public const uint32 MD_ASP_QUEUETIMEOUT = 7013;
	public const uint32 MD_ASP_ALLOWOUTOFPROCCOMPONENTS = 7014;
	public const uint32 MD_ASP_ALLOWOUTOFPROCCMPNTS = 7014;
	public const uint32 MD_ASP_EXCEPTIONCATCHENABLE = 7015;
	public const uint32 MD_ASP_CODEPAGE = 7016;
	public const uint32 MD_ASP_SCRIPTLANGUAGELIST = 7017;
	public const uint32 MD_ASP_ENABLESERVERDEBUG = 7018;
	public const uint32 MD_ASP_ENABLECLIENTDEBUG = 7019;
	public const uint32 MD_ASP_TRACKTHREADINGMODEL = 7020;
	public const uint32 MD_ASP_ENABLEASPHTMLFALLBACK = 7021;
	public const uint32 MD_ASP_ENABLECHUNKEDENCODING = 7022;
	public const uint32 MD_ASP_ENABLETYPELIBCACHE = 7023;
	public const uint32 MD_ASP_ERRORSTONTLOG = 7024;
	public const uint32 MD_ASP_PROCESSORTHREADMAX = 7025;
	public const uint32 MD_ASP_REQEUSTQUEUEMAX = 7026;
	public const uint32 MD_ASP_ENABLEAPPLICATIONRESTART = 7027;
	public const uint32 MD_ASP_QUEUECONNECTIONTESTTIME = 7028;
	public const uint32 MD_ASP_SESSIONMAX = 7029;
	public const uint32 MD_ASP_THREADGATEENABLED = 7030;
	public const uint32 MD_ASP_THREADGATETIMESLICE = 7031;
	public const uint32 MD_ASP_THREADGATESLEEPDELAY = 7032;
	public const uint32 MD_ASP_THREADGATESLEEPMAX = 7033;
	public const uint32 MD_ASP_THREADGATELOADLOW = 7034;
	public const uint32 MD_ASP_THREADGATELOADHIGH = 7035;
	public const uint32 MD_ASP_DISKTEMPLATECACHEDIRECTORY = 7036;
	public const uint32 MD_ASP_MAXDISKTEMPLATECACHEFILES = 7040;
	public const uint32 MD_ASP_EXECUTEINMTA = 7041;
	public const uint32 MD_ASP_LCID = 7042;
	public const uint32 MD_ASP_KEEPSESSIONIDSECURE = 7043;
	public const uint32 MD_ASP_SERVICE_FLAGS = 7044;
	public const uint32 MD_ASP_SERVICE_FLAG_TRACKER = 7045;
	public const uint32 MD_ASP_SERVICE_FLAG_FUSION = 7046;
	public const uint32 MD_ASP_SERVICE_FLAG_PARTITIONS = 7047;
	public const uint32 MD_ASP_SERVICE_PARTITION_ID = 7048;
	public const uint32 MD_ASP_SERVICE_SXS_NAME = 7049;
	public const uint32 MD_ASP_SERVICE_ENABLE_TRACKER = 1;
	public const uint32 MD_ASP_SERVICE_ENABLE_SXS = 2;
	public const uint32 MD_ASP_SERVICE_USE_PARTITION = 4;
	public const uint32 MD_ASP_CALCLINENUMBER = 7050;
	public const uint32 MD_ASP_RUN_ONEND_ANON = 7051;
	public const uint32 MD_ASP_BUFFER_LIMIT = 7052;
	public const uint32 MD_ASP_MAX_REQUEST_ENTITY_ALLOWED = 7053;
	public const uint32 MD_ASP_MAXREQUESTENTITY = 7053;
	public const uint32 MD_ASP_ID_LAST = 7053;
	public const uint32 WAM_MD_SERVER_BASE = 7500;
	public const uint32 MD_WAM_USER_NAME = 7501;
	public const uint32 MD_WAM_PWD = 7502;
	public const uint32 WEBDAV_MD_SERVER_BASE = 8500;
	public const uint32 MD_WEBDAV_MAX_ATTRIBUTES_PER_ELEMENT = 8501;
	public const uint32 IIS_MD_APPPOOL_BASE = 9000;
	public const uint32 MD_APPPOOL_PERIODIC_RESTART_TIME = 9001;
	public const uint32 MD_APPPOOL_PERIODIC_RESTART_REQUEST_COUNT = 9002;
	public const uint32 MD_APPPOOL_MAX_PROCESS_COUNT = 9003;
	public const uint32 MD_APPPOOL_PINGING_ENABLED = 9004;
	public const uint32 MD_APPPOOL_IDLE_TIMEOUT = 9005;
	public const uint32 MD_APPPOOL_RAPID_FAIL_PROTECTION_ENABLED = 9006;
	public const uint32 MD_APPPOOL_SMP_AFFINITIZED = 9007;
	public const uint32 MD_APPPOOL_SMP_AFFINITIZED_PROCESSOR_MASK = 9008;
	public const uint32 MD_APPPOOL_ORPHAN_PROCESSES_FOR_DEBUGGING = 9009;
	public const uint32 MD_APPPOOL_STARTUP_TIMELIMIT = 9011;
	public const uint32 MD_APPPOOL_SHUTDOWN_TIMELIMIT = 9012;
	public const uint32 MD_APPPOOL_PING_INTERVAL = 9013;
	public const uint32 MD_APPPOOL_PING_RESPONSE_TIMELIMIT = 9014;
	public const uint32 MD_APPPOOL_DISALLOW_OVERLAPPING_ROTATION = 9015;
	public const uint32 MD_APPPOOL_UL_APPPOOL_QUEUE_LENGTH = 9017;
	public const uint32 MD_APPPOOL_DISALLOW_ROTATION_ON_CONFIG_CHANGE = 9018;
	public const uint32 MD_APPPOOL_PERIODIC_RESTART_SCHEDULE = 9020;
	public const uint32 MD_APPPOOL_IDENTITY_TYPE = 9021;
	public const uint32 MD_CPU_ACTION = 9022;
	public const uint32 MD_CPU_LIMIT = 9023;
	public const uint32 MD_APPPOOL_PERIODIC_RESTART_MEMORY = 9024;
	public const uint32 MD_APPPOOL_COMMAND = 9026;
	public const uint32 MD_APPPOOL_STATE = 9027;
	public const uint32 MD_APPPOOL_AUTO_START = 9028;
	public const uint32 MD_RAPID_FAIL_PROTECTION_INTERVAL = 9029;
	public const uint32 MD_RAPID_FAIL_PROTECTION_MAX_CRASHES = 9030;
	public const uint32 MD_APPPOOL_ORPHAN_ACTION_EXE = 9031;
	public const uint32 MD_APPPOOL_ORPHAN_ACTION_PARAMS = 9032;
	public const uint32 MB_DONT_IMPERSONATE = 9033;
	public const uint32 MD_LOAD_BALANCER_CAPABILITIES = 9034;
	public const uint32 MD_APPPOOL_AUTO_SHUTDOWN_EXE = 9035;
	public const uint32 MD_APPPOOL_AUTO_SHUTDOWN_PARAMS = 9036;
	public const uint32 MD_APP_POOL_LOG_EVENT_ON_RECYCLE = 9037;
	public const uint32 MD_APPPOOL_PERIODIC_RESTART_PRIVATE_MEMORY = 9038;
	public const uint32 MD_APPPOOL_MANAGED_RUNTIME_VERSION = 9039;
	public const uint32 MD_APPPOOL_32_BIT_APP_ON_WIN64 = 9040;
	public const uint32 MD_APPPOOL_MANAGED_PIPELINE_MODE = 9041;
	public const uint32 MD_APP_POOL_LOG_EVENT_ON_PROCESSMODEL = 9042;
	public const uint32 MD_APP_POOL_PROCESSMODEL_IDLE_TIMEOUT = 1;
	public const uint32 MD_APP_POOL_RECYCLE_TIME = 1;
	public const uint32 MD_APP_POOL_RECYCLE_REQUESTS = 2;
	public const uint32 MD_APP_POOL_RECYCLE_SCHEDULE = 4;
	public const uint32 MD_APP_POOL_RECYCLE_MEMORY = 8;
	public const uint32 MD_APP_POOL_RECYCLE_ISAPI_UNHEALTHY = 16;
	public const uint32 MD_APP_POOL_RECYCLE_ON_DEMAND = 32;
	public const uint32 MD_APP_POOL_RECYCLE_CONFIG_CHANGE = 64;
	public const uint32 MD_APP_POOL_RECYCLE_PRIVATE_MEMORY = 128;
	public const uint32 MD_CPU_NO_ACTION = 0;
	public const uint32 MD_CPU_KILL_W3WP = 1;
	public const uint32 MD_CPU_TRACE = 2;
	public const uint32 MD_CPU_THROTTLE = 3;
	public const uint32 MD_APPPOOL_COMMAND_START = 1;
	public const uint32 MD_APPPOOL_COMMAND_STOP = 2;
	public const uint32 MD_APPPOOL_STATE_STARTING = 1;
	public const uint32 MD_APPPOOL_STATE_STARTED = 2;
	public const uint32 MD_APPPOOL_STATE_STOPPING = 3;
	public const uint32 MD_APPPOOL_STATE_STOPPED = 4;
	public const uint32 MD_APPPOOL_IDENTITY_TYPE_LOCALSYSTEM = 0;
	public const uint32 MD_APPPOOL_IDENTITY_TYPE_LOCALSERVICE = 1;
	public const uint32 MD_APPPOOL_IDENTITY_TYPE_NETWORKSERVICE = 2;
	public const uint32 MD_APPPOOL_IDENTITY_TYPE_SPECIFICUSER = 3;
	public const uint32 MD_LOAD_BALANCER_CAPABILITIES_BASIC = 1;
	public const uint32 MD_LOAD_BALANCER_CAPABILITIES_SOPHISTICATED = 2;
	public const uint32 IIS_MD_APP_BASE = 9100;
	public const uint32 MD_APP_APPPOOL_ID = 9101;
	public const uint32 MD_APP_ALLOW_TRANSIENT_REGISTRATION = 9102;
	public const uint32 MD_APP_AUTO_START = 9103;
	public const uint32 MD_APPPOOL_PERIODIC_RESTART_CONNECTIONS = 9104;
	public const uint32 MD_APPPOOL_APPPOOL_ID = 9201;
	public const uint32 MD_APPPOOL_ALLOW_TRANSIENT_REGISTRATION = 9202;
	public const uint32 IIS_MD_GLOBAL_BASE = 9200;
	public const uint32 MD_MAX_GLOBAL_BANDWIDTH = 9201;
	public const uint32 MD_MAX_GLOBAL_CONNECTIONS = 9202;
	public const uint32 MD_GLOBAL_STANDARD_APP_MODE_ENABLED = 9203;
	public const uint32 MD_HEADER_WAIT_TIMEOUT = 9204;
	public const uint32 MD_MIN_FILE_BYTES_PER_SEC = 9205;
	public const uint32 MD_GLOBAL_LOG_IN_UTF_8 = 9206;
	public const uint32 MD_DEMAND_START_THRESHOLD = 9207;
	public const uint32 MD_GLOBAL_SESSIONKEY = 9999;
	public const uint32 MD_ROOT_ENABLE_EDIT_WHILE_RUNNING = 9998;
	public const uint32 MD_GLOBAL_CHANGE_NUMBER = 9997;
	public const uint32 MD_ROOT_ENABLE_HISTORY = 9996;
	public const uint32 MD_ROOT_MAX_HISTORY_FILES = 9995;
	public const uint32 MD_GLOBAL_EDIT_WHILE_RUNNING_MAJOR_VERSION_NUMBER = 9994;
	public const uint32 MD_GLOBAL_EDIT_WHILE_RUNNING_MINOR_VERSION_NUMBER = 9993;
	public const uint32 MD_GLOBAL_XMLSCHEMATIMESTAMP = 9992;
	public const uint32 MD_GLOBAL_BINSCHEMATIMESTAMP = 9991;
	public const uint32 MD_COMMENTS = 9990;
	public const uint32 MD_LOCATION = 9989;
	public const uint32 MD_MAX_ERROR_FILES = 9988;
	public const uint32 MD_STOP_LISTENING = 9987;
	public const uint32 MD_AUTH_ANONYMOUS = 1;
	public const uint32 MD_AUTH_BASIC = 2;
	public const uint32 MD_AUTH_NT = 4;
	public const uint32 MD_AUTH_MD5 = 16;
	public const uint32 MD_AUTH_PASSPORT = 64;
	public const uint32 MD_AUTH_SINGLEREQUEST = 64;
	public const uint32 MD_AUTH_SINGLEREQUESTIFPROXY = 128;
	public const uint32 MD_AUTH_SINGLEREQUESTALWAYSIFPROXY = 256;
	public const uint32 MD_ACCESS_READ = 1;
	public const uint32 MD_ACCESS_WRITE = 2;
	public const uint32 MD_ACCESS_EXECUTE = 4;
	public const uint32 MD_ACCESS_SOURCE = 16;
	public const uint32 MD_ACCESS_SCRIPT = 512;
	public const uint32 MD_ACCESS_NO_REMOTE_WRITE = 1024;
	public const uint32 MD_ACCESS_NO_REMOTE_READ = 4096;
	public const uint32 MD_ACCESS_NO_REMOTE_EXECUTE = 8192;
	public const uint32 MD_ACCESS_NO_REMOTE_SCRIPT = 16384;
	public const uint32 MD_ACCESS_NO_PHYSICAL_DIR = 32768;
	public const uint32 MD_ACCESS_SSL = 8;
	public const uint32 MD_ACCESS_NEGO_CERT = 32;
	public const uint32 MD_ACCESS_REQUIRE_CERT = 64;
	public const uint32 MD_ACCESS_MAP_CERT = 128;
	public const uint32 MD_ACCESS_SSL128 = 256;
	public const uint32 MD_ACCESS_MASK = 65535;
	public const uint32 MD_DIRBROW_SHOW_DATE = 2;
	public const uint32 MD_DIRBROW_SHOW_TIME = 4;
	public const uint32 MD_DIRBROW_SHOW_SIZE = 8;
	public const uint32 MD_DIRBROW_SHOW_EXTENSION = 16;
	public const uint32 MD_DIRBROW_LONG_DATE = 32;
	public const uint32 MD_DIRBROW_ENABLED = 2147483648;
	public const uint32 MD_DIRBROW_LOADDEFAULT = 1073741824;
	public const uint32 MD_LOGON_INTERACTIVE = 0;
	public const uint32 MD_LOGON_BATCH = 1;
	public const uint32 MD_LOGON_NETWORK = 2;
	public const uint32 MD_LOGON_NETWORK_CLEARTEXT = 3;
	public const uint32 MD_PASSPORT_NO_MAPPING = 0;
	public const uint32 MD_PASSPORT_TRY_MAPPING = 1;
	public const uint32 MD_PASSPORT_NEED_MAPPING = 2;
	public const uint32 MD_NOTIFEXAUTH_NTLMSSL = 1;
	public const uint32 MD_FILTER_STATE_LOADED = 1;
	public const uint32 MD_FILTER_STATE_UNLOADED = 4;
	public const uint32 MD_SERVER_STATE_STARTING = 1;
	public const uint32 MD_SERVER_STATE_STARTED = 2;
	public const uint32 MD_SERVER_STATE_STOPPING = 3;
	public const uint32 MD_SERVER_STATE_STOPPED = 4;
	public const uint32 MD_SERVER_STATE_PAUSING = 5;
	public const uint32 MD_SERVER_STATE_PAUSED = 6;
	public const uint32 MD_SERVER_STATE_CONTINUING = 7;
	public const uint32 MD_SERVER_COMMAND_START = 1;
	public const uint32 MD_SERVER_COMMAND_STOP = 2;
	public const uint32 MD_SERVER_COMMAND_PAUSE = 3;
	public const uint32 MD_SERVER_COMMAND_CONTINUE = 4;
	public const uint32 MD_SERVER_SIZE_SMALL = 0;
	public const uint32 MD_SERVER_SIZE_MEDIUM = 1;
	public const uint32 MD_SERVER_SIZE_LARGE = 2;
	public const uint32 MD_SERVER_CONFIG_SSL_40 = 1;
	public const uint32 MD_SERVER_CONFIG_SSL_128 = 2;
	public const uint32 MD_SERVER_CONFIG_ALLOW_ENCRYPT = 4;
	public const uint32 MD_SERVER_CONFIG_AUTO_PW_SYNC = 8;
	public const uint32 MD_SCRIPTMAPFLAG_SCRIPT = 1;
	public const uint32 MD_SCRIPTMAPFLAG_CHECK_PATH_INFO = 4;
	public const uint32 MD_SCRIPTMAPFLAG_ALLOWED_ON_READ_DIR = 1;
	public const uint32 MD_AUTH_CHANGE_UNSECURE = 1;
	public const uint32 MD_AUTH_CHANGE_DISABLE = 2;
	public const uint32 MD_AUTH_ADVNOTIFY_DISABLE = 4;
	public const uint32 MD_NETLOGON_WKS_NONE = 0;
	public const uint32 MD_NETLOGON_WKS_IP = 1;
	public const uint32 MD_NETLOGON_WKS_DNS = 2;
	public const uint32 MD_ERROR_SUB400_INVALID_DESTINATION = 1;
	public const uint32 MD_ERROR_SUB400_INVALID_DEPTH = 2;
	public const uint32 MD_ERROR_SUB400_INVALID_IF = 3;
	public const uint32 MD_ERROR_SUB400_INVALID_OVERWRITE = 4;
	public const uint32 MD_ERROR_SUB400_INVALID_TRANSLATE = 5;
	public const uint32 MD_ERROR_SUB400_INVALID_REQUEST_BODY = 6;
	public const uint32 MD_ERROR_SUB400_INVALID_CONTENT_LENGTH = 7;
	public const uint32 MD_ERROR_SUB400_INVALID_TIMEOUT = 8;
	public const uint32 MD_ERROR_SUB400_INVALID_LOCK_TOKEN = 9;
	public const uint32 MD_ERROR_SUB400_INVALID_XFF_HEADER = 10;
	public const uint32 MD_ERROR_SUB400_INVALID_WEBSOCKET_REQUEST = 11;
	public const uint32 MD_ERROR_SUB401_LOGON = 1;
	public const uint32 MD_ERROR_SUB401_LOGON_CONFIG = 2;
	public const uint32 MD_ERROR_SUB401_LOGON_ACL = 3;
	public const uint32 MD_ERROR_SUB401_FILTER = 4;
	public const uint32 MD_ERROR_SUB401_APPLICATION = 5;
	public const uint32 MD_ERROR_SUB401_URLAUTH_POLICY = 7;
	public const uint32 MD_ERROR_SUB403_EXECUTE_ACCESS_DENIED = 1;
	public const uint32 MD_ERROR_SUB403_READ_ACCESS_DENIED = 2;
	public const uint32 MD_ERROR_SUB403_WRITE_ACCESS_DENIED = 3;
	public const uint32 MD_ERROR_SUB403_SSL_REQUIRED = 4;
	public const uint32 MD_ERROR_SUB403_SSL128_REQUIRED = 5;
	public const uint32 MD_ERROR_SUB403_ADDR_REJECT = 6;
	public const uint32 MD_ERROR_SUB403_CERT_REQUIRED = 7;
	public const uint32 MD_ERROR_SUB403_SITE_ACCESS_DENIED = 8;
	public const uint32 MD_ERROR_SUB403_TOO_MANY_USERS = 9;
	public const uint32 MD_ERROR_SUB403_INVALID_CNFG = 10;
	public const uint32 MD_ERROR_SUB403_PWD_CHANGE = 11;
	public const uint32 MD_ERROR_SUB403_MAPPER_DENY_ACCESS = 12;
	public const uint32 MD_ERROR_SUB403_CERT_REVOKED = 13;
	public const uint32 MD_ERROR_SUB403_DIR_LIST_DENIED = 14;
	public const uint32 MD_ERROR_SUB403_CAL_EXCEEDED = 15;
	public const uint32 MD_ERROR_SUB403_CERT_BAD = 16;
	public const uint32 MD_ERROR_SUB403_CERT_TIME_INVALID = 17;
	public const uint32 MD_ERROR_SUB403_APPPOOL_DENIED = 18;
	public const uint32 MD_ERROR_SUB403_INSUFFICIENT_PRIVILEGE_FOR_CGI = 19;
	public const uint32 MD_ERROR_SUB403_PASSPORT_LOGIN_FAILURE = 20;
	public const uint32 MD_ERROR_SUB403_SOURCE_ACCESS_DENIED = 21;
	public const uint32 MD_ERROR_SUB403_INFINITE_DEPTH_DENIED = 22;
	public const uint32 MD_ERROR_SUB403_LOCK_TOKEN_REQUIRED = 23;
	public const uint32 MD_ERROR_SUB403_VALIDATION_FAILURE = 24;
	public const uint32 MD_ERROR_SUB404_SITE_NOT_FOUND = 1;
	public const uint32 MD_ERROR_SUB404_DENIED_BY_POLICY = 2;
	public const uint32 MD_ERROR_SUB404_DENIED_BY_MIMEMAP = 3;
	public const uint32 MD_ERROR_SUB404_NO_HANDLER = 4;
	public const uint32 MD_ERROR_SUB404_URL_SEQUENCE_DENIED = 5;
	public const uint32 MD_ERROR_SUB404_VERB_DENIED = 6;
	public const uint32 MD_ERROR_SUB404_FILE_EXTENSION_DENIED = 7;
	public const uint32 MD_ERROR_SUB404_HIDDEN_SEGMENT = 8;
	public const uint32 MD_ERROR_SUB404_FILE_ATTRIBUTE_HIDDEN = 9;
	public const uint32 MD_ERROR_SUB404_URL_DOUBLE_ESCAPED = 11;
	public const uint32 MD_ERROR_SUB404_URL_HAS_HIGH_BIT_CHARS = 12;
	public const uint32 MD_ERROR_SUB404_URL_TOO_LONG = 14;
	public const uint32 MD_ERROR_SUB404_QUERY_STRING_TOO_LONG = 15;
	public const uint32 MD_ERROR_SUB404_STATICFILE_DAV = 16;
	public const uint32 MD_ERROR_SUB404_PRECONDITIONED_HANDLER = 17;
	public const uint32 MD_ERROR_SUB404_QUERY_STRING_SEQUENCE_DENIED = 18;
	public const uint32 MD_ERROR_SUB404_DENIED_BY_FILTERING_RULE = 19;
	public const uint32 MD_ERROR_SUB404_TOO_MANY_URL_SEGMENTS = 20;
	public const uint32 MD_ERROR_SUB413_CONTENT_LENGTH_TOO_LARGE = 1;
	public const uint32 MD_ERROR_SUB423_LOCK_TOKEN_SUBMITTED = 1;
	public const uint32 MD_ERROR_SUB423_NO_CONFLICTING_LOCK = 2;
	public const uint32 MD_ERROR_SUB500_UNC_ACCESS = 16;
	public const uint32 MD_ERROR_SUB500_URLAUTH_NO_STORE = 17;
	public const uint32 MD_ERROR_SUB500_URLAUTH_STORE_ERROR = 18;
	public const uint32 MD_ERROR_SUB500_BAD_METADATA = 19;
	public const uint32 MD_ERROR_SUB500_URLAUTH_NO_SCOPE = 20;
	public const uint32 MD_ERROR_SUB500_HANDLERS_MODULE = 21;
	public const uint32 MD_ERROR_SUB500_ASPNET_MODULES = 22;
	public const uint32 MD_ERROR_SUB500_ASPNET_HANDLERS = 23;
	public const uint32 MD_ERROR_SUB500_ASPNET_IMPERSONATION = 24;
	public const uint32 MD_ERROR_SUB502_TIMEOUT = 1;
	public const uint32 MD_ERROR_SUB502_PREMATURE_EXIT = 2;
	public const uint32 MD_ERROR_SUB502_ARR_CONNECTION_ERROR = 3;
	public const uint32 MD_ERROR_SUB502_ARR_NO_SERVER = 4;
	public const uint32 MD_ERROR_SUB503_CPU_LIMIT = 1;
	public const uint32 MD_ERROR_SUB503_APP_CONCURRENT = 2;
	public const uint32 MD_ERROR_SUB503_ASPNET_QUEUE_FULL = 3;
	public const uint32 MD_ERROR_SUB503_FASTCGI_QUEUE_FULL = 4;
	public const uint32 MD_ERROR_SUB503_CONNECTION_LIMIT = 5;
	public const uint32 MD_ACR_READ = 1;
	public const uint32 MD_ACR_WRITE = 2;
	public const uint32 MD_ACR_RESTRICTED_WRITE = 32;
	public const uint32 MD_ACR_UNSECURE_PROPS_READ = 128;
	public const uint32 MD_ACR_ENUM_KEYS = 8;
	public const uint32 MD_ACR_WRITE_DAC = 262144;
	public const uint32 MD_USER_ISOLATION_NONE = 0;
	public const uint32 MD_USER_ISOLATION_BASIC = 1;
	public const uint32 MD_USER_ISOLATION_AD = 2;
	public const uint32 MD_USER_ISOLATION_LAST = 2;
	public const String IIS_CLASS_COMPUTER = "IIsComputer";
	public const String IIS_CLASS_WEB_SERVICE = "IIsWebService";
	public const String IIS_CLASS_WEB_SERVER = "IIsWebServer";
	public const String IIS_CLASS_WEB_INFO = "IIsWebInfo";
	public const String IIS_CLASS_WEB_DIR = "IIsWebDirectory";
	public const String IIS_CLASS_WEB_VDIR = "IIsWebVirtualDir";
	public const String IIS_CLASS_WEB_FILE = "IIsWebFile";
	public const String IIS_CLASS_FTP_SERVICE = "IIsFtpService";
	public const String IIS_CLASS_FTP_SERVER = "IIsFtpServer";
	public const String IIS_CLASS_FTP_INFO = "IIsFtpInfo";
	public const String IIS_CLASS_FTP_VDIR = "IIsFtpVirtualDir";
	public const String IIS_CLASS_FILTERS = "IIsFilters";
	public const String IIS_CLASS_FILTER = "IIsFilter";
	public const String IIS_CLASS_LOG_MODULES = "IIsLogModules";
	public const String IIS_CLASS_LOG_MODULE = "IIsLogModule";
	public const String IIS_CLASS_MIMEMAP = "IIsMimeMap";
	public const String IIS_CLASS_CERTMAPPER = "IIsCertMapper";
	public const String IIS_CLASS_COMPRESS_SCHEMES = "IIsCompressionSchemes";
	public const String IIS_CLASS_COMPRESS_SCHEME = "IIsCompressionScheme";
	public const String IIS_CLASS_COMPUTER_W = "IIsComputer";
	public const String IIS_CLASS_WEB_SERVICE_W = "IIsWebService";
	public const String IIS_CLASS_WEB_SERVER_W = "IIsWebServer";
	public const String IIS_CLASS_WEB_INFO_W = "IIsWebInfo";
	public const String IIS_CLASS_WEB_DIR_W = "IIsWebDirectory";
	public const String IIS_CLASS_WEB_VDIR_W = "IIsWebVirtualDir";
	public const String IIS_CLASS_WEB_FILE_W = "IIsWebFile";
	public const String IIS_CLASS_FTP_SERVICE_W = "IIsFtpService";
	public const String IIS_CLASS_FTP_SERVER_W = "IIsFtpServer";
	public const String IIS_CLASS_FTP_INFO_W = "IIsFtpInfo";
	public const String IIS_CLASS_FTP_VDIR_W = "IIsFtpVirtualDir";
	public const String IIS_CLASS_FILTERS_W = "IIsFilters";
	public const String IIS_CLASS_FILTER_W = "IIsFilter";
	public const String IIS_CLASS_LOG_MODULES_W = "IIsLogModules";
	public const String IIS_CLASS_LOG_MODULE_W = "IIsLogModule";
	public const String IIS_CLASS_MIMEMAP_W = "IIsMimeMap";
	public const String IIS_CLASS_CERTMAPPER_W = "IIsCertMapper";
	public const String IIS_CLASS_COMPRESS_SCHEMES_W = "IIsCompressionSchemes";
	public const String IIS_CLASS_COMPRESS_SCHEME_W = "IIsCompressionScheme";
	public const Guid CLSID_IisServiceControl = .(0xe8fb8621, 0x588f, 0x11d2, 0x9d, 0x61, 0x00, 0xc0, 0x4f, 0x79, 0xc5, 0xfe);
	public const Guid LIBID_IISRSTALib = .(0xe8fb8614, 0x588f, 0x11d2, 0x9d, 0x61, 0x00, 0xc0, 0x4f, 0x79, 0xc5, 0xfe);
	public const String IIS_WEBSOCKET = "websockets";
	public const String IIS_WEBSOCKET_SERVER_VARIABLE = "IIS_WEBSOCK";
	public const Guid LIBID_WAMREGLib = .(0x29822aa8, 0xf302, 0x11d0, 0x99, 0x53, 0x00, 0xc0, 0x4f, 0xd9, 0x19, 0xc1);
	public const Guid CLSID_WamAdmin = .(0x61738644, 0xf196, 0x11d0, 0x99, 0x53, 0x00, 0xc0, 0x4f, 0xd9, 0x19, 0xc1);
	public const uint32 APPSTATUS_STOPPED = 0;
	public const uint32 APPSTATUS_RUNNING = 1;
	public const uint32 APPSTATUS_NOTDEFINED = 2;
	public const uint32 METADATA_MAX_NAME_LEN = 256;
	public const uint32 METADATA_PERMISSION_READ = 1;
	public const uint32 METADATA_PERMISSION_WRITE = 2;
	public const uint32 METADATA_NO_ATTRIBUTES = 0;
	public const uint32 METADATA_INHERIT = 1;
	public const uint32 METADATA_PARTIAL_PATH = 2;
	public const uint32 METADATA_SECURE = 4;
	public const uint32 METADATA_REFERENCE = 8;
	public const uint32 METADATA_VOLATILE = 16;
	public const uint32 METADATA_ISINHERITED = 32;
	public const uint32 METADATA_INSERT_PATH = 64;
	public const uint32 METADATA_LOCAL_MACHINE_ONLY = 128;
	public const uint32 METADATA_NON_SECURE_ONLY = 256;
	public const uint32 METADATA_DONT_EXPAND = 512;
	public const uint32 MD_BACKUP_OVERWRITE = 1;
	public const uint32 MD_BACKUP_SAVE_FIRST = 2;
	public const uint32 MD_BACKUP_FORCE_BACKUP = 4;
	public const uint32 MD_BACKUP_NEXT_VERSION = 4294967295;
	public const uint32 MD_BACKUP_HIGHEST_VERSION = 4294967294;
	public const uint32 MD_BACKUP_MAX_VERSION = 9999;
	public const uint32 MD_BACKUP_MAX_LEN = 100;
	public const String MD_DEFAULT_BACKUP_LOCATION = "MDBackUp";
	public const uint32 MD_HISTORY_LATEST = 1;
	public const uint32 MD_EXPORT_INHERITED = 1;
	public const uint32 MD_EXPORT_NODE_ONLY = 2;
	public const uint32 MD_IMPORT_INHERITED = 1;
	public const uint32 MD_IMPORT_NODE_ONLY = 2;
	public const uint32 MD_IMPORT_MERGE = 4;
	public const String MD_INSERT_PATH_STRINGA = "<%INSERT_PATH%>";
	public const String MD_INSERT_PATH_STRING = "<%INSERT_PATH%>";
	public const uint32 METADATA_MASTER_ROOT_HANDLE = 0;
	public const uint32 MD_CHANGE_TYPE_DELETE_OBJECT = 1;
	public const uint32 MD_CHANGE_TYPE_ADD_OBJECT = 2;
	public const uint32 MD_CHANGE_TYPE_SET_DATA = 4;
	public const uint32 MD_CHANGE_TYPE_DELETE_DATA = 8;
	public const uint32 MD_CHANGE_TYPE_RENAME_OBJECT = 16;
	public const uint32 MD_CHANGE_TYPE_RESTORE = 32;
	public const uint32 MD_MAX_CHANGE_ENTRIES = 100;
	public const int32 MD_ERROR_NOT_INITIALIZED = -2146646016;
	public const int32 MD_ERROR_DATA_NOT_FOUND = -2146646015;
	public const int32 MD_ERROR_INVALID_VERSION = -2146646014;
	public const int32 MD_WARNING_PATH_NOT_FOUND = 837635;
	public const int32 MD_WARNING_DUP_NAME = 837636;
	public const int32 MD_WARNING_INVALID_DATA = 837637;
	public const int32 MD_ERROR_SECURE_CHANNEL_FAILURE = -2146646010;
	public const int32 MD_WARNING_PATH_NOT_INSERTED = 837639;
	public const int32 MD_ERROR_CANNOT_REMOVE_SECURE_ATTRIBUTE = -2146646008;
	public const int32 MD_WARNING_SAVE_FAILED = 837641;
	public const int32 MD_ERROR_IISAO_INVALID_SCHEMA = -2146646000;
	public const int32 MD_ERROR_READ_METABASE_FILE = -2146645991;
	public const int32 MD_ERROR_NO_SESSION_KEY = -2146645987;
	public const Guid LIBID_ASPTypeLibrary = .(0xd97a6da0, 0xa85c, 0x11cf, 0x83, 0xae, 0x00, 0xa0, 0xc9, 0x0c, 0x2b, 0xd8);
	public const Guid CLSID_Request = .(0x920c25d0, 0x25d9, 0x11d0, 0xa5, 0x5f, 0x00, 0xa0, 0xc9, 0x0c, 0x20, 0x91);
	public const Guid CLSID_Response = .(0x46e19ba0, 0x25dd, 0x11d0, 0xa5, 0x5f, 0x00, 0xa0, 0xc9, 0x0c, 0x20, 0x91);
	public const Guid CLSID_Session = .(0x509f8f20, 0x25de, 0x11d0, 0xa5, 0x5f, 0x00, 0xa0, 0xc9, 0x0c, 0x20, 0x91);
	public const Guid CLSID_Server = .(0xa506d160, 0x25e0, 0x11d0, 0xa5, 0x5f, 0x00, 0xa0, 0xc9, 0x0c, 0x20, 0x91);
	public const Guid CLSID_ScriptingContext = .(0xd97a6da0, 0xa868, 0x11cf, 0x83, 0xae, 0x11, 0xb0, 0xc9, 0x0c, 0x2b, 0xd8);
	public const uint32 HSE_VERSION_MAJOR = 8;
	public const uint32 HSE_VERSION_MINOR = 0;
	public const uint32 HSE_LOG_BUFFER_LEN = 80;
	public const uint32 HSE_MAX_EXT_DLL_NAME_LEN = 256;
	public const uint32 HSE_STATUS_SUCCESS = 1;
	public const uint32 HSE_STATUS_SUCCESS_AND_KEEP_CONN = 2;
	public const uint32 HSE_STATUS_PENDING = 3;
	public const uint32 HSE_STATUS_ERROR = 4;
	public const uint32 HSE_REQ_BASE = 0;
	public const uint32 HSE_REQ_SEND_URL_REDIRECT_RESP = 1;
	public const uint32 HSE_REQ_SEND_URL = 2;
	public const uint32 HSE_REQ_SEND_RESPONSE_HEADER = 3;
	public const uint32 HSE_REQ_DONE_WITH_SESSION = 4;
	public const uint32 HSE_REQ_END_RESERVED = 1000;
	public const uint32 HSE_REQ_MAP_URL_TO_PATH = 1001;
	public const uint32 HSE_REQ_GET_SSPI_INFO = 1002;
	public const uint32 HSE_APPEND_LOG_PARAMETER = 1003;
	public const uint32 HSE_REQ_IO_COMPLETION = 1005;
	public const uint32 HSE_REQ_TRANSMIT_FILE = 1006;
	public const uint32 HSE_REQ_REFRESH_ISAPI_ACL = 1007;
	public const uint32 HSE_REQ_IS_KEEP_CONN = 1008;
	public const uint32 HSE_REQ_ASYNC_READ_CLIENT = 1010;
	public const uint32 HSE_REQ_GET_IMPERSONATION_TOKEN = 1011;
	public const uint32 HSE_REQ_MAP_URL_TO_PATH_EX = 1012;
	public const uint32 HSE_REQ_ABORTIVE_CLOSE = 1014;
	public const uint32 HSE_REQ_GET_CERT_INFO_EX = 1015;
	public const uint32 HSE_REQ_SEND_RESPONSE_HEADER_EX = 1016;
	public const uint32 HSE_REQ_CLOSE_CONNECTION = 1017;
	public const uint32 HSE_REQ_IS_CONNECTED = 1018;
	public const uint32 HSE_REQ_MAP_UNICODE_URL_TO_PATH = 1023;
	public const uint32 HSE_REQ_MAP_UNICODE_URL_TO_PATH_EX = 1024;
	public const uint32 HSE_REQ_EXEC_UNICODE_URL = 1025;
	public const uint32 HSE_REQ_EXEC_URL = 1026;
	public const uint32 HSE_REQ_GET_EXEC_URL_STATUS = 1027;
	public const uint32 HSE_REQ_SEND_CUSTOM_ERROR = 1028;
	public const uint32 HSE_REQ_IS_IN_PROCESS = 1030;
	public const uint32 HSE_REQ_REPORT_UNHEALTHY = 1032;
	public const uint32 HSE_REQ_NORMALIZE_URL = 1033;
	public const uint32 HSE_REQ_VECTOR_SEND = 1037;
	public const uint32 HSE_REQ_GET_ANONYMOUS_TOKEN = 1038;
	public const uint32 HSE_REQ_GET_CACHE_INVALIDATION_CALLBACK = 1040;
	public const uint32 HSE_REQ_GET_UNICODE_ANONYMOUS_TOKEN = 1041;
	public const uint32 HSE_REQ_GET_TRACE_INFO = 1042;
	public const uint32 HSE_REQ_SET_FLUSH_FLAG = 1043;
	public const uint32 HSE_REQ_GET_TRACE_INFO_EX = 1044;
	public const uint32 HSE_REQ_RAISE_TRACE_EVENT = 1045;
	public const uint32 HSE_REQ_GET_CONFIG_OBJECT = 1046;
	public const uint32 HSE_REQ_GET_WORKER_PROCESS_SETTINGS = 1047;
	public const uint32 HSE_REQ_GET_PROTOCOL_MANAGER_CUSTOM_INTERFACE_CALLBACK = 1048;
	public const uint32 HSE_REQ_CANCEL_IO = 1049;
	public const uint32 HSE_REQ_GET_CHANNEL_BINDING_TOKEN = 1050;
	public const uint32 HSE_TERM_ADVISORY_UNLOAD = 1;
	public const uint32 HSE_TERM_MUST_UNLOAD = 2;
	public const uint32 HSE_IO_SYNC = 1;
	public const uint32 HSE_IO_ASYNC = 2;
	public const uint32 HSE_IO_DISCONNECT_AFTER_SEND = 4;
	public const uint32 HSE_IO_SEND_HEADERS = 8;
	public const uint32 HSE_IO_NODELAY = 4096;
	public const uint32 HSE_IO_FINAL_SEND = 16;
	public const uint32 HSE_IO_CACHE_RESPONSE = 32;
	public const uint32 HSE_IO_TRY_SKIP_CUSTOM_ERRORS = 64;
	public const uint32 HSE_URL_FLAGS_READ = 1;
	public const uint32 HSE_URL_FLAGS_WRITE = 2;
	public const uint32 HSE_URL_FLAGS_EXECUTE = 4;
	public const uint32 HSE_URL_FLAGS_SSL = 8;
	public const uint32 HSE_URL_FLAGS_DONT_CACHE = 16;
	public const uint32 HSE_URL_FLAGS_NEGO_CERT = 32;
	public const uint32 HSE_URL_FLAGS_REQUIRE_CERT = 64;
	public const uint32 HSE_URL_FLAGS_MAP_CERT = 128;
	public const uint32 HSE_URL_FLAGS_SSL128 = 256;
	public const uint32 HSE_URL_FLAGS_SCRIPT = 512;
	public const uint32 HSE_URL_FLAGS_MASK = 1023;
	public const uint32 HSE_EXEC_URL_NO_HEADERS = 2;
	public const uint32 HSE_EXEC_URL_IGNORE_CURRENT_INTERCEPTOR = 4;
	public const uint32 HSE_EXEC_URL_IGNORE_VALIDATION_AND_RANGE = 16;
	public const uint32 HSE_EXEC_URL_DISABLE_CUSTOM_ERROR = 32;
	public const uint32 HSE_EXEC_URL_SSI_CMD = 64;
	public const uint32 HSE_EXEC_URL_HTTP_CACHE_ELIGIBLE = 128;
	public const uint32 HSE_VECTOR_ELEMENT_TYPE_MEMORY_BUFFER = 0;
	public const uint32 HSE_VECTOR_ELEMENT_TYPE_FILE_HANDLE = 1;
	public const uint32 HSE_APP_FLAG_IN_PROCESS = 0;
	public const uint32 HSE_APP_FLAG_ISOLATED_OOP = 1;
	public const uint32 HSE_APP_FLAG_POOLED_OOP = 2;
	public const uint32 SF_MAX_USERNAME = 257;
	public const uint32 SF_MAX_PASSWORD = 257;
	public const uint32 SF_MAX_AUTH_TYPE = 33;
	public const uint32 SF_MAX_FILTER_DESC_LEN = 257;
	public const uint32 SF_DENIED_LOGON = 1;
	public const uint32 SF_DENIED_RESOURCE = 2;
	public const uint32 SF_DENIED_FILTER = 4;
	public const uint32 SF_DENIED_APPLICATION = 8;
	public const uint32 SF_DENIED_BY_CONFIG = 65536;
	public const uint32 SF_NOTIFY_SECURE_PORT = 1;
	public const uint32 SF_NOTIFY_NONSECURE_PORT = 2;
	public const uint32 SF_NOTIFY_READ_RAW_DATA = 32768;
	public const uint32 SF_NOTIFY_PREPROC_HEADERS = 16384;
	public const uint32 SF_NOTIFY_AUTHENTICATION = 8192;
	public const uint32 SF_NOTIFY_URL_MAP = 4096;
	public const uint32 SF_NOTIFY_ACCESS_DENIED = 2048;
	public const uint32 SF_NOTIFY_SEND_RESPONSE = 64;
	public const uint32 SF_NOTIFY_SEND_RAW_DATA = 1024;
	public const uint32 SF_NOTIFY_LOG = 512;
	public const uint32 SF_NOTIFY_END_OF_REQUEST = 128;
	public const uint32 SF_NOTIFY_END_OF_NET_SESSION = 256;
	public const uint32 SF_NOTIFY_AUTH_COMPLETE = 67108864;
	public const uint32 SF_NOTIFY_ORDER_HIGH = 524288;
	public const uint32 SF_NOTIFY_ORDER_MEDIUM = 262144;
	public const uint32 SF_NOTIFY_ORDER_LOW = 131072;
	public const uint32 SF_NOTIFY_ORDER_DEFAULT = 131072;
	public const uint32 DISPID_HTTPREQUEST_BASE = 1;
	public const uint32 DISPID_HTTPREQUEST_OPEN = 1;
	public const uint32 DISPID_HTTPREQUEST_SETREQUESTHEADER = 2;
	public const uint32 DISPID_HTTPREQUEST_GETRESPONSEHEADER = 3;
	public const uint32 DISPID_HTTPREQUEST_GETALLRESPONSEHEADERS = 4;
	public const uint32 DISPID_HTTPREQUEST_SEND = 5;
	public const uint32 DISPID_HTTPREQUEST_OPTION = 6;
	public const uint32 DISPID_HTTPREQUEST_STATUS = 7;
	public const uint32 DISPID_HTTPREQUEST_STATUSTEXT = 8;
	public const uint32 DISPID_HTTPREQUEST_RESPONSETEXT = 9;
	public const uint32 DISPID_HTTPREQUEST_RESPONSEBODY = 10;
	public const uint32 DISPID_HTTPREQUEST_RESPONSESTREAM = 11;
	public const uint32 DISPID_HTTPREQUEST_ABORT = 12;
	public const uint32 DISPID_HTTPREQUEST_SETPROXY = 13;
	public const uint32 DISPID_HTTPREQUEST_SETCREDENTIALS = 14;
	public const uint32 DISPID_HTTPREQUEST_WAITFORRESPONSE = 15;
	public const uint32 DISPID_HTTPREQUEST_SETTIMEOUTS = 16;
	public const uint32 DISPID_HTTPREQUEST_SETCLIENTCERTIFICATE = 17;
	public const uint32 DISPID_HTTPREQUEST_SETAUTOLOGONPOLICY = 18;
	public const uint32 HTTP_TRACE_EVENT_FLAG_STATIC_DESCRIPTIVE_FIELDS = 1;
	public const uint32 HTTP_TRACE_LEVEL_START = 6;
	public const uint32 HTTP_TRACE_LEVEL_END = 7;
	public const Guid GUID_IIS_ALL_TRACE_PROVIDERS = .(0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
	public const Guid GUID_IIS_WWW_SERVER_TRACE_PROVIDER = .(0x3a2a4e84, 0x4c21, 0x4981, 0xae, 0x10, 0x3f, 0xda, 0x0d, 0x9b, 0x0f, 0x83);
	public const Guid GUID_IIS_WWW_SERVER_V2_TRACE_PROVIDER = .(0xde4649c9, 0x15e8, 0x4fea, 0x9d, 0x85, 0x1c, 0xdd, 0xa5, 0x20, 0xc3, 0x34);
	public const Guid GUID_IIS_ASPNET_TRACE_PROVIDER = .(0xaff081fe, 0x0247, 0x4275, 0x9c, 0x4e, 0x02, 0x1f, 0x3d, 0xc1, 0xda, 0x35);
	public const Guid GUID_IIS_ASP_TRACE_TRACE_PROVIDER = .(0x06b94d9a, 0xb15e, 0x456e, 0xa4, 0xef, 0x37, 0xc9, 0x84, 0xa2, 0xcb, 0x4b);
	public const Guid GUID_IIS_WWW_GLOBAL_TRACE_PROVIDER = .(0xd55d3bc9, 0xcba9, 0x44df, 0x82, 0x7e, 0x13, 0x2d, 0x3a, 0x45, 0x96, 0xc2);
	public const Guid GUID_IIS_ISAPI_TRACE_PROVIDER = .(0xa1c2040e, 0x8840, 0x4c31, 0xba, 0x11, 0x98, 0x71, 0x03, 0x1a, 0x19, 0xea);
	public const String WEB_CORE_DLL_NAME = "hwebcore.dll";
	public const String WEB_CORE_ACTIVATE_DLL_ENTRY = "WebCoreActivate";
	public const String WEB_CORE_SHUTDOWN_DLL_ENTRY = "WebCoreShutdown";
	public const String WEB_CORE_SET_METADATA_DLL_ENTRY = "WebCoreSetMetadata";
}
#endregion

#region Enums

[AllowDuplicates]
public enum FTP_ACCESS : int32
{
	FTP_ACCESS_NONE = 0,
	FTP_ACCESS_READ = 1,
	FTP_ACCESS_WRITE = 2,
	FTP_ACCESS_READ_WRITE = 3,
}


[AllowDuplicates]
public enum FTP_PROCESS_STATUS : int32
{
	FTP_PROCESS_CONTINUE = 0,
	FTP_PROCESS_CLOSE_SESSION = 1,
	FTP_PROCESS_TERMINATE_SESSION = 2,
	FTP_PROCESS_REJECT_COMMAND = 3,
}


[AllowDuplicates]
public enum METADATATYPES : int32
{
	ALL_METADATA = 0,
	DWORD_METADATA = 1,
	STRING_METADATA = 2,
	BINARY_METADATA = 3,
	EXPANDSZ_METADATA = 4,
	MULTISZ_METADATA = 5,
	INVALID_END_METADATA = 6,
}


[AllowDuplicates]
public enum SF_REQ_TYPE : int32
{
	SF_REQ_SEND_RESPONSE_HEADER = 0,
	SF_REQ_ADD_HEADERS_ON_DENIAL = 1,
	SF_REQ_SET_NEXT_READ_SIZE = 2,
	SF_REQ_SET_PROXY_INFO = 3,
	SF_REQ_GET_CONNID = 4,
	SF_REQ_SET_CERTIFICATE_INFO = 5,
	SF_REQ_GET_PROPERTY = 6,
	SF_REQ_NORMALIZE_URL = 7,
	SF_REQ_DISABLE_NOTIFICATIONS = 8,
}


[AllowDuplicates]
public enum SF_PROPERTY_IIS : int32
{
	SF_PROPERTY_SSL_CTXT = 0,
	SF_PROPERTY_INSTANCE_NUM_ID = 1,
}


[AllowDuplicates]
public enum SF_STATUS_TYPE : int32
{
	SF_STATUS_REQ_FINISHED = 134217728,
	SF_STATUS_REQ_FINISHED_KEEP_CONN = 134217729,
	SF_STATUS_REQ_NEXT_NOTIFICATION = 134217730,
	SF_STATUS_REQ_HANDLED_NOTIFICATION = 134217731,
	SF_STATUS_REQ_ERROR = 134217732,
	SF_STATUS_REQ_READ_NEXT = 134217733,
}


[AllowDuplicates]
public enum HTTP_TRACE_TYPE : int32
{
	HTTP_TRACE_TYPE_BYTE = 17,
	HTTP_TRACE_TYPE_USHORT = 18,
	HTTP_TRACE_TYPE_ULONG = 19,
	HTTP_TRACE_TYPE_ULONGLONG = 21,
	HTTP_TRACE_TYPE_CHAR = 16,
	HTTP_TRACE_TYPE_SHORT = 2,
	HTTP_TRACE_TYPE_LONG = 3,
	HTTP_TRACE_TYPE_LONGLONG = 20,
	HTTP_TRACE_TYPE_LPCWSTR = 31,
	HTTP_TRACE_TYPE_LPCSTR = 30,
	HTTP_TRACE_TYPE_LPCGUID = 72,
	HTTP_TRACE_TYPE_BOOL = 11,
}

#endregion

#region Function Pointers
public function void PFN_HSE_IO_COMPLETION(EXTENSION_CONTROL_BLOCK* pECB, void* pContext, uint32 cbIO, uint32 dwError);

public function HRESULT PFN_HSE_CACHE_INVALIDATION_CALLBACK(PWSTR pszUrl);

public function HRESULT PFN_HSE_GET_PROTOCOL_MANAGER_CUSTOM_INTERFACE_CALLBACK(PWSTR pszProtocolManagerDll, PWSTR pszProtocolManagerDllInitFunction, uint32 dwCustomInterfaceId, void** ppCustomInterface);

public function BOOL PFN_GETEXTENSIONVERSION(HSE_VERSION_INFO* pVer);

public function uint32 PFN_HTTPEXTENSIONPROC(EXTENSION_CONTROL_BLOCK* pECB);

public function BOOL PFN_TERMINATEEXTENSION(uint32 dwFlags);

public function HRESULT PFN_WEB_CORE_SET_METADATA_DLL_ENTRY(PWSTR pszMetadataType, PWSTR pszValue);

public function HRESULT PFN_WEB_CORE_ACTIVATE(PWSTR pszAppHostConfigFile, PWSTR pszRootWebConfigFile, PWSTR pszInstanceName);

public function HRESULT PFN_WEB_CORE_SHUTDOWN(uint32 fImmediate);

#endregion

#region Structs
[CRepr]
public struct CONFIGURATION_ENTRY
{
	public BSTR bstrKey;
	public BSTR bstrValue;
}

[CRepr]
public struct LOGGING_PARAMETERS
{
	public PWSTR pszSessionId;
	public PWSTR pszSiteName;
	public PWSTR pszUserName;
	public PWSTR pszHostName;
	public PWSTR pszRemoteIpAddress;
	public uint32 dwRemoteIpPort;
	public PWSTR pszLocalIpAddress;
	public uint32 dwLocalIpPort;
	public uint64 BytesSent;
	public uint64 BytesReceived;
	public PWSTR pszCommand;
	public PWSTR pszCommandParameters;
	public PWSTR pszFullPath;
	public uint32 dwElapsedMilliseconds;
	public uint32 FtpStatus;
	public uint32 FtpSubStatus;
	public HRESULT hrStatus;
	public PWSTR pszInformation;
}

[CRepr]
public struct PRE_PROCESS_PARAMETERS
{
	public PWSTR pszSessionId;
	public PWSTR pszSiteName;
	public PWSTR pszUserName;
	public PWSTR pszHostName;
	public PWSTR pszRemoteIpAddress;
	public uint32 dwRemoteIpPort;
	public PWSTR pszLocalIpAddress;
	public uint32 dwLocalIpPort;
	public PWSTR pszCommand;
	public PWSTR pszCommandParameters;
	public FILETIME SessionStartTime;
	public uint64 BytesSentPerSession;
	public uint64 BytesReceivedPerSession;
}

[CRepr]
public struct POST_PROCESS_PARAMETERS
{
	public PWSTR pszSessionId;
	public PWSTR pszSiteName;
	public PWSTR pszUserName;
	public PWSTR pszHostName;
	public PWSTR pszRemoteIpAddress;
	public uint32 dwRemoteIpPort;
	public PWSTR pszLocalIpAddress;
	public uint32 dwLocalIpPort;
	public uint64 BytesSent;
	public uint64 BytesReceived;
	public PWSTR pszCommand;
	public PWSTR pszCommandParameters;
	public PWSTR pszFullPath;
	public PWSTR pszPhysicalPath;
	public uint32 FtpStatus;
	public uint32 FtpSubStatus;
	public HRESULT hrStatus;
	public FILETIME SessionStartTime;
	public uint64 BytesSentPerSession;
	public uint64 BytesReceivedPerSession;
}

[CRepr]
public struct METADATA_RECORD
{
	public uint32 dwMDIdentifier;
	public uint32 dwMDAttributes;
	public uint32 dwMDUserType;
	public uint32 dwMDDataType;
	public uint32 dwMDDataLen;
	public uint8* pbMDData;
	public uint32 dwMDDataTag;
}

[CRepr]
public struct METADATA_GETALL_RECORD
{
	public uint32 dwMDIdentifier;
	public uint32 dwMDAttributes;
	public uint32 dwMDUserType;
	public uint32 dwMDDataType;
	public uint32 dwMDDataLen;
	public uint32 dwMDDataOffset;
	public uint32 dwMDDataTag;
}

[CRepr]
public struct METADATA_GETALL_INTERNAL_RECORD
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint dwMDDataOffset;
		public uint8* pbMDData;
	}
	public uint32 dwMDIdentifier;
	public uint32 dwMDAttributes;
	public uint32 dwMDUserType;
	public uint32 dwMDDataType;
	public uint32 dwMDDataLen;
	public using _Anonymous_e__Union Anonymous;
	public uint32 dwMDDataTag;
}

[CRepr]
public struct METADATA_HANDLE_INFO
{
	public uint32 dwMDPermissions;
	public uint32 dwMDSystemChangeNumber;
}

[CRepr]
public struct MD_CHANGE_OBJECT_W
{
	public PWSTR pszMDPath;
	public uint32 dwMDChangeType;
	public uint32 dwMDNumDataIDs;
	public uint32* pdwMDDataIDs;
}

[CRepr]
public struct _IIS_CRYPTO_BLOB
{
}

[CRepr]
public struct HSE_VERSION_INFO
{
	public uint32 dwExtensionVersion;
	public CHAR[256] lpszExtensionDesc;
}

[CRepr]
public struct EXTENSION_CONTROL_BLOCK
{
	public uint32 cbSize;
	public uint32 dwVersion;
	public void* ConnID;
	public uint32 dwHttpStatusCode;
	public CHAR[80] lpszLogData;
	public PSTR lpszMethod;
	public PSTR lpszQueryString;
	public PSTR lpszPathInfo;
	public PSTR lpszPathTranslated;
	public uint32 cbTotalBytes;
	public uint32 cbAvailable;
	public uint8* lpbData;
	public PSTR lpszContentType;
	public int GetServerVariable;
	public int WriteClient;
	public int ReadClient;
	public int ServerSupportFunction;
}

[CRepr]
public struct HSE_URL_MAPEX_INFO
{
	public CHAR[260] lpszPath;
	public uint32 dwFlags;
	public uint32 cchMatchingPath;
	public uint32 cchMatchingURL;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
}

[CRepr]
public struct HSE_UNICODE_URL_MAPEX_INFO
{
	public char16[260] lpszPath;
	public uint32 dwFlags;
	public uint32 cchMatchingPath;
	public uint32 cchMatchingURL;
}

[CRepr]
public struct HSE_TF_INFO
{
	public PFN_HSE_IO_COMPLETION pfnHseIO;
	public void* pContext;
	public HANDLE hFile;
	public PSTR pszStatusCode;
	public uint32 BytesToWrite;
	public uint32 Offset;
	public void* pHead;
	public uint32 HeadLength;
	public void* pTail;
	public uint32 TailLength;
	public uint32 dwFlags;
}

[CRepr]
public struct HSE_SEND_HEADER_EX_INFO
{
	public PSTR pszStatus;
	public PSTR pszHeader;
	public uint32 cchStatus;
	public uint32 cchHeader;
	public BOOL fKeepConn;
}

[CRepr]
public struct HSE_EXEC_URL_USER_INFO
{
	public HANDLE hImpersonationToken;
	public PSTR pszCustomUserName;
	public PSTR pszCustomAuthType;
}

[CRepr]
public struct HSE_EXEC_URL_ENTITY_INFO
{
	public uint32 cbAvailable;
	public void* lpbData;
}

[CRepr]
public struct HSE_EXEC_URL_STATUS
{
	public uint16 uHttpStatusCode;
	public uint16 uHttpSubStatus;
	public uint32 dwWin32Error;
}

[CRepr]
public struct HSE_EXEC_URL_INFO
{
	public PSTR pszUrl;
	public PSTR pszMethod;
	public PSTR pszChildHeaders;
	public HSE_EXEC_URL_USER_INFO* pUserInfo;
	public HSE_EXEC_URL_ENTITY_INFO* pEntity;
	public uint32 dwExecUrlFlags;
}

[CRepr]
public struct HSE_EXEC_UNICODE_URL_USER_INFO
{
	public HANDLE hImpersonationToken;
	public PWSTR pszCustomUserName;
	public PSTR pszCustomAuthType;
}

[CRepr]
public struct HSE_EXEC_UNICODE_URL_INFO
{
	public PWSTR pszUrl;
	public PSTR pszMethod;
	public PSTR pszChildHeaders;
	public HSE_EXEC_UNICODE_URL_USER_INFO* pUserInfo;
	public HSE_EXEC_URL_ENTITY_INFO* pEntity;
	public uint32 dwExecUrlFlags;
}

[CRepr]
public struct HSE_CUSTOM_ERROR_INFO
{
	public PSTR pszStatus;
	public uint16 uHttpSubError;
	public BOOL fAsync;
}

[CRepr]
public struct HSE_VECTOR_ELEMENT
{
	public uint32 ElementType;
	public void* pvContext;
	public uint64 cbOffset;
	public uint64 cbSize;
}

[CRepr]
public struct HSE_RESPONSE_VECTOR
{
	public uint32 dwFlags;
	public PSTR pszStatus;
	public PSTR pszHeaders;
	public uint32 nElementCount;
	public HSE_VECTOR_ELEMENT* lpElementArray;
}

[CRepr]
public struct CERT_CONTEXT_EX
{
	public CERT_CONTEXT CertContext;
	public uint32 cbAllocated;
	public uint32 dwCertificateFlags;
}

[CRepr]
public struct HSE_TRACE_INFO
{
	public BOOL fTraceRequest;
	public uint8[16] TraceContextId;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
}

[CRepr]
public struct HTTP_FILTER_CONTEXT
{
	public uint32 cbSize;
	public uint32 Revision;
	public void* ServerContext;
	public uint32 ulReserved;
	public BOOL fIsSecurePort;
	public void* pFilterContext;
	public int GetServerVariable;
	public int AddResponseHeaders;
	public int WriteClient;
	public int AllocMem;
	public int ServerSupportFunction;
}

[CRepr]
public struct HTTP_FILTER_RAW_DATA
{
	public void* pvInData;
	public uint32 cbInData;
	public uint32 cbInBuffer;
	public uint32 dwReserved;
}

[CRepr]
public struct HTTP_FILTER_PREPROC_HEADERS
{
	public int GetHeader;
	public int SetHeader;
	public int AddHeader;
	public uint32 HttpStatus;
	public uint32 dwReserved;
}

[CRepr]
public struct HTTP_FILTER_AUTHENT
{
	public PSTR pszUser;
	public uint32 cbUserBuff;
	public PSTR pszPassword;
	public uint32 cbPasswordBuff;
}

[CRepr]
public struct HTTP_FILTER_URL_MAP
{
	public PSTR pszURL;
	public PSTR pszPhysicalPath;
	public uint32 cbPathBuff;
}

[CRepr]
public struct HTTP_FILTER_URL_MAP_EX
{
	public PSTR pszURL;
	public PSTR pszPhysicalPath;
	public uint32 cbPathBuff;
	public uint32 dwFlags;
	public uint32 cchMatchingPath;
	public uint32 cchMatchingURL;
	public PSTR pszScriptMapEntry;
}

[CRepr]
public struct HTTP_FILTER_ACCESS_DENIED
{
	public PSTR pszURL;
	public PSTR pszPhysicalPath;
	public uint32 dwReason;
}

[CRepr]
public struct HTTP_FILTER_LOG
{
	public PSTR pszClientHostName;
	public PSTR pszClientUserName;
	public PSTR pszServerName;
	public PSTR pszOperation;
	public PSTR pszTarget;
	public PSTR pszParameters;
	public uint32 dwHttpStatus;
	public uint32 dwWin32Status;
	public uint32 dwBytesSent;
	public uint32 dwBytesRecvd;
	public uint32 msTimeForProcessing;
}

[CRepr]
public struct HTTP_FILTER_AUTH_COMPLETE_INFO
{
	public int GetHeader;
	public int SetHeader;
	public int AddHeader;
	public int GetUserToken;
	public uint32 HttpStatus;
	public BOOL fResetAuth;
	public uint32 dwReserved;
}

[CRepr]
public struct HTTP_FILTER_VERSION
{
	public uint32 dwServerFilterVersion;
	public uint32 dwFilterVersion;
	public CHAR[257] lpszFilterDesc;
	public uint32 dwFlags;
}

[CRepr]
public struct HTTP_TRACE_EVENT
{
	public Guid* pProviderGuid;
	public uint32 dwArea;
	public Guid* pAreaGuid;
	public uint32 dwEvent;
	public PWSTR pszEventName;
	public uint32 dwEventVersion;
	public uint32 dwVerbosity;
	public Guid* pActivityGuid;
	public Guid* pRelatedActivityGuid;
	public uint32 dwTimeStamp;
	public uint32 dwFlags;
	public uint32 cEventItems;
	public HTTP_TRACE_EVENT_ITEM* pEventItems;
}

[CRepr]
public struct HTTP_TRACE_EVENT_ITEM
{
	public PWSTR pszName;
	public HTTP_TRACE_TYPE dwDataType;
	public uint8* pbData;
	public uint32 cbData;
	public PWSTR pszDataDescription;
}

[CRepr]
public struct HTTP_TRACE_CONFIGURATION
{
	public Guid* pProviderGuid;
	public uint32 dwAreas;
	public uint32 dwVerbosity;
	public BOOL fProviderEnabled;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_FtpProvider = .(0x70bdc667, 0x33b2, 0x45f0, 0xac, 0x52, 0xc3, 0xca, 0x46, 0xf7, 0xa6, 0x56);


}
#endregion

#region COM Types
[CRepr]struct IFtpProviderConstruct : IUnknown
{
	public new const Guid IID = .(0x4d1a3f7b, 0x412d, 0x447c, 0xb1, 0x99, 0x64, 0xf9, 0x67, 0xe9, 0xa2, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SAFEARRAY* configurationEntries) Construct;
	}


	public HRESULT Construct(SAFEARRAY* configurationEntries) mut => VT.[Friend]Construct(&this, configurationEntries);
}

[CRepr]struct IFtpAuthenticationProvider : IUnknown
{
	public new const Guid IID = .(0x4659f95c, 0xd5a8, 0x4707, 0xb2, 0xfc, 0x6f, 0xd5, 0x79, 0x42, 0x46, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName, PWSTR pszPassword, PWSTR* ppszCanonicalUserName, BOOL* pfAuthenticated) AuthenticateUser;
	}


	public HRESULT AuthenticateUser(PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName, PWSTR pszPassword, PWSTR* ppszCanonicalUserName, BOOL* pfAuthenticated) mut => VT.[Friend]AuthenticateUser(&this, pszSessionId, pszSiteName, pszUserName, pszPassword, ppszCanonicalUserName, pfAuthenticated);
}

[CRepr]struct AsyncIFtpAuthenticationProvider : IUnknown
{
	public new const Guid IID = .(0xc24efb65, 0x9f3e, 0x4996, 0x8f, 0xb1, 0xce, 0x16, 0x69, 0x16, 0xba, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName, PWSTR pszPassword) Begin_AuthenticateUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszCanonicalUserName, BOOL* pfAuthenticated) Finish_AuthenticateUser;
	}


	public HRESULT Begin_AuthenticateUser(PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName, PWSTR pszPassword) mut => VT.[Friend]Begin_AuthenticateUser(&this, pszSessionId, pszSiteName, pszUserName, pszPassword);

	public HRESULT Finish_AuthenticateUser(PWSTR* ppszCanonicalUserName, BOOL* pfAuthenticated) mut => VT.[Friend]Finish_AuthenticateUser(&this, ppszCanonicalUserName, pfAuthenticated);
}

[CRepr]struct IFtpRoleProvider : IUnknown
{
	public new const Guid IID = .(0x909c850d, 0x8ca0, 0x4674, 0x96, 0xb8, 0xcc, 0x29, 0x41, 0x53, 0x57, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName, PWSTR pszRole, BOOL* pfIsInRole) IsUserInRole;
	}


	public HRESULT IsUserInRole(PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName, PWSTR pszRole, BOOL* pfIsInRole) mut => VT.[Friend]IsUserInRole(&this, pszSessionId, pszSiteName, pszUserName, pszRole, pfIsInRole);
}

[CRepr]struct AsyncIFtpRoleProvider : IUnknown
{
	public new const Guid IID = .(0x3e83bf99, 0x70ec, 0x41ca, 0x84, 0xb6, 0xac, 0xa7, 0xc7, 0xa6, 0x2c, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName, PWSTR pszRole) Begin_IsUserInRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsInRole) Finish_IsUserInRole;
	}


	public HRESULT Begin_IsUserInRole(PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName, PWSTR pszRole) mut => VT.[Friend]Begin_IsUserInRole(&this, pszSessionId, pszSiteName, pszUserName, pszRole);

	public HRESULT Finish_IsUserInRole(BOOL* pfIsInRole) mut => VT.[Friend]Finish_IsUserInRole(&this, pfIsInRole);
}

[CRepr]struct IFtpHomeDirectoryProvider : IUnknown
{
	public new const Guid IID = .(0x0933b392, 0x18dd, 0x4097, 0x8b, 0x9c, 0x83, 0x32, 0x5c, 0x35, 0xd9, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName, PWSTR* ppszHomeDirectoryData) GetUserHomeDirectoryData;
	}


	public HRESULT GetUserHomeDirectoryData(PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName, PWSTR* ppszHomeDirectoryData) mut => VT.[Friend]GetUserHomeDirectoryData(&this, pszSessionId, pszSiteName, pszUserName, ppszHomeDirectoryData);
}

[CRepr]struct AsyncIFtpHomeDirectoryProvider : IUnknown
{
	public new const Guid IID = .(0x73f81638, 0x6295, 0x42bd, 0xa2, 0xbe, 0x4a, 0x65, 0x7f, 0x7c, 0x47, 0x9c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName) Begin_GetUserHomeDirectoryData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszHomeDirectoryData) Finish_GetUserHomeDirectoryData;
	}


	public HRESULT Begin_GetUserHomeDirectoryData(PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszUserName) mut => VT.[Friend]Begin_GetUserHomeDirectoryData(&this, pszSessionId, pszSiteName, pszUserName);

	public HRESULT Finish_GetUserHomeDirectoryData(PWSTR* ppszHomeDirectoryData) mut => VT.[Friend]Finish_GetUserHomeDirectoryData(&this, ppszHomeDirectoryData);
}

[CRepr]struct IFtpLogProvider : IUnknown
{
	public new const Guid IID = .(0xa18a94cc, 0x8299, 0x4408, 0x81, 0x6c, 0x7c, 0x3b, 0xac, 0xa1, 0xa4, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LOGGING_PARAMETERS* pLoggingParameters) Log;
	}


	public HRESULT Log(LOGGING_PARAMETERS* pLoggingParameters) mut => VT.[Friend]Log(&this, pLoggingParameters);
}

[CRepr]struct AsyncIFtpLogProvider : IUnknown
{
	public new const Guid IID = .(0x00a0ae46, 0x2498, 0x48b2, 0x95, 0xe6, 0xdf, 0x67, 0x8e, 0xd7, 0xd4, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LOGGING_PARAMETERS* pLoggingParameters) Begin_Log;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_Log;
	}


	public HRESULT Begin_Log(LOGGING_PARAMETERS* pLoggingParameters) mut => VT.[Friend]Begin_Log(&this, pLoggingParameters);

	public HRESULT Finish_Log() mut => VT.[Friend]Finish_Log(&this);
}

[CRepr]struct IFtpAuthorizationProvider : IUnknown
{
	public new const Guid IID = .(0xa50ae7a1, 0xa35a, 0x42b4, 0xa4, 0xf3, 0xf4, 0xf7, 0x05, 0x7a, 0x05, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszVirtualPath, PWSTR pszUserName, FTP_ACCESS* pFtpAccess) GetUserAccessPermission;
	}


	public HRESULT GetUserAccessPermission(PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszVirtualPath, PWSTR pszUserName, FTP_ACCESS* pFtpAccess) mut => VT.[Friend]GetUserAccessPermission(&this, pszSessionId, pszSiteName, pszVirtualPath, pszUserName, pFtpAccess);
}

[CRepr]struct AsyncIFtpAuthorizationProvider : IUnknown
{
	public new const Guid IID = .(0x860dc339, 0x07e5, 0x4a5c, 0x9c, 0x61, 0x88, 0x20, 0xce, 0xa0, 0x12, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszVirtualPath, PWSTR pszUserName) Begin_GetUserAccessPermission;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FTP_ACCESS* pFtpAccess) Finish_GetUserAccessPermission;
	}


	public HRESULT Begin_GetUserAccessPermission(PWSTR pszSessionId, PWSTR pszSiteName, PWSTR pszVirtualPath, PWSTR pszUserName) mut => VT.[Friend]Begin_GetUserAccessPermission(&this, pszSessionId, pszSiteName, pszVirtualPath, pszUserName);

	public HRESULT Finish_GetUserAccessPermission(FTP_ACCESS* pFtpAccess) mut => VT.[Friend]Finish_GetUserAccessPermission(&this, pFtpAccess);
}

[CRepr]struct IFtpPreprocessProvider : IUnknown
{
	public new const Guid IID = .(0xa3c19b60, 0x5a28, 0x471a, 0x8f, 0x93, 0xab, 0x30, 0x41, 0x1c, 0xee, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PRE_PROCESS_PARAMETERS* pPreProcessParameters, FTP_PROCESS_STATUS* pFtpProcessStatus) HandlePreprocess;
	}


	public HRESULT HandlePreprocess(PRE_PROCESS_PARAMETERS* pPreProcessParameters, FTP_PROCESS_STATUS* pFtpProcessStatus) mut => VT.[Friend]HandlePreprocess(&this, pPreProcessParameters, pFtpProcessStatus);
}

[CRepr]struct AsyncIFtpPreprocessProvider : IUnknown
{
	public new const Guid IID = .(0x6ff5fd8f, 0xfd8e, 0x48b1, 0xa3, 0xe0, 0xbf, 0x70, 0x73, 0xdb, 0x4d, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PRE_PROCESS_PARAMETERS* pPreProcessParameters) Begin_HandlePreprocess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FTP_PROCESS_STATUS* pFtpProcessStatus) Finish_HandlePreprocess;
	}


	public HRESULT Begin_HandlePreprocess(PRE_PROCESS_PARAMETERS* pPreProcessParameters) mut => VT.[Friend]Begin_HandlePreprocess(&this, pPreProcessParameters);

	public HRESULT Finish_HandlePreprocess(FTP_PROCESS_STATUS* pFtpProcessStatus) mut => VT.[Friend]Finish_HandlePreprocess(&this, pFtpProcessStatus);
}

[CRepr]struct IFtpPostprocessProvider : IUnknown
{
	public new const Guid IID = .(0x4522cbc6, 0x16cd, 0x49ad, 0x86, 0x53, 0x9a, 0x2c, 0x57, 0x9e, 0x42, 0x80);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POST_PROCESS_PARAMETERS* pPostProcessParameters, FTP_PROCESS_STATUS* pFtpProcessStatus) HandlePostprocess;
	}


	public HRESULT HandlePostprocess(POST_PROCESS_PARAMETERS* pPostProcessParameters, FTP_PROCESS_STATUS* pFtpProcessStatus) mut => VT.[Friend]HandlePostprocess(&this, pPostProcessParameters, pFtpProcessStatus);
}

[CRepr]struct AsyncIFtpPostprocessProvider : IUnknown
{
	public new const Guid IID = .(0xa16b2542, 0x9694, 0x4eb1, 0xa5, 0x64, 0x6c, 0x2e, 0x91, 0xfd, 0xc1, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POST_PROCESS_PARAMETERS* pPostProcessParameters) Begin_HandlePostprocess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FTP_PROCESS_STATUS* pFtpProcessStatus) Finish_HandlePostprocess;
	}


	public HRESULT Begin_HandlePostprocess(POST_PROCESS_PARAMETERS* pPostProcessParameters) mut => VT.[Friend]Begin_HandlePostprocess(&this, pPostProcessParameters);

	public HRESULT Finish_HandlePostprocess(FTP_PROCESS_STATUS* pFtpProcessStatus) mut => VT.[Friend]Finish_HandlePostprocess(&this, pFtpProcessStatus);
}

[CRepr]struct IADMEXT : IUnknown
{
	public new const Guid IID = .(0x51dfe970, 0xf6f2, 0x11d0, 0xb9, 0xbd, 0x00, 0xa0, 0xc9, 0x22, 0xe7, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsidDcom, uint32 dwEnumIndex) EnumDcomCLSIDs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Terminate;
	}


	public HRESULT Initialize() mut => VT.[Friend]Initialize(&this);

	public HRESULT EnumDcomCLSIDs(Guid* pclsidDcom, uint32 dwEnumIndex) mut => VT.[Friend]EnumDcomCLSIDs(&this, pclsidDcom, dwEnumIndex);

	public HRESULT Terminate() mut => VT.[Friend]Terminate(&this);
}

[CRepr]struct IMSAdminBaseW : IUnknown
{
	public new const Guid IID = .(0x70b51430, 0xb6ca, 0x11d0, 0xb9, 0xb9, 0x00, 0xa0, 0xc9, 0x22, 0xe7, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath) AddKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath) DeleteKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath) DeleteChildKeys;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, char16* pszMDName, uint32 dwMDEnumObjectIndex) EnumKeys;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDSourceHandle, PWSTR pszMDSourcePath, uint32 hMDDestHandle, PWSTR pszMDDestPath, BOOL bMDOverwriteFlag, BOOL bMDCopyFlag) CopyKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, PWSTR pszMDNewName) RenameKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, METADATA_RECORD* pmdrMDData) SetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, METADATA_RECORD* pmdrMDData, uint32* pdwMDRequiredDataLen) GetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, uint32 dwMDIdentifier, uint32 dwMDDataType) DeleteData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, METADATA_RECORD* pmdrMDData, uint32 dwMDEnumDataIndex, uint32* pdwMDRequiredDataLen) EnumData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, uint32 dwMDAttributes, uint32 dwMDUserType, uint32 dwMDDataType, uint32* pdwMDNumDataEntries, uint32* pdwMDDataSetNumber, uint32 dwMDBufferSize, uint8* pbMDBuffer, uint32* pdwMDRequiredBufferSize) GetAllData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, uint32 dwMDUserType, uint32 dwMDDataType) DeleteAllData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDSourceHandle, PWSTR pszMDSourcePath, uint32 hMDDestHandle, PWSTR pszMDDestPath, uint32 dwMDAttributes, uint32 dwMDUserType, uint32 dwMDDataType, BOOL bMDCopyFlag) CopyData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, uint32 dwMDIdentifier, uint32 dwMDDataType, uint32 dwMDBufferSize, char16* pszBuffer, uint32* pdwMDRequiredBufferSize) GetDataPaths;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, uint32 dwMDAccessRequested, uint32 dwMDTimeOut, uint32* phMDNewHandle) OpenKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle) CloseKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, uint32 dwMDTimeOut, uint32 dwMDAccessRequested) ChangePermissions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SaveData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, METADATA_HANDLE_INFO* pmdhiInfo) GetHandleInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwSystemChangeNumber) GetSystemChangeNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, uint32* pdwMDDataSetNumber) GetDataSetNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, FILETIME* pftMDLastChangeTime, BOOL bLocalTime) SetLastChangeTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, FILETIME* pftMDLastChangeTime, BOOL bLocalTime) GetLastChangeTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) KeyExchangePhase1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) KeyExchangePhase2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMDBackupLocation, uint32 dwMDVersion, uint32 dwMDFlags) Backup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMDBackupLocation, uint32 dwMDVersion, uint32 dwMDFlags) Restore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszMDBackupLocation, uint32* pdwMDVersion, FILETIME* pftMDBackupTime, uint32 dwMDEnumIndex) EnumBackups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMDBackupLocation, uint32 dwMDVersion) DeleteBackup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSAdminBaseW** piadmbwInterface) UnmarshalInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GetServerGuid;
	}


	public HRESULT AddKey(uint32 hMDHandle, PWSTR pszMDPath) mut => VT.[Friend]AddKey(&this, hMDHandle, pszMDPath);

	public HRESULT DeleteKey(uint32 hMDHandle, PWSTR pszMDPath) mut => VT.[Friend]DeleteKey(&this, hMDHandle, pszMDPath);

	public HRESULT DeleteChildKeys(uint32 hMDHandle, PWSTR pszMDPath) mut => VT.[Friend]DeleteChildKeys(&this, hMDHandle, pszMDPath);

	public HRESULT EnumKeys(uint32 hMDHandle, PWSTR pszMDPath, char16* pszMDName, uint32 dwMDEnumObjectIndex) mut => VT.[Friend]EnumKeys(&this, hMDHandle, pszMDPath, pszMDName, dwMDEnumObjectIndex);

	public HRESULT CopyKey(uint32 hMDSourceHandle, PWSTR pszMDSourcePath, uint32 hMDDestHandle, PWSTR pszMDDestPath, BOOL bMDOverwriteFlag, BOOL bMDCopyFlag) mut => VT.[Friend]CopyKey(&this, hMDSourceHandle, pszMDSourcePath, hMDDestHandle, pszMDDestPath, bMDOverwriteFlag, bMDCopyFlag);

	public HRESULT RenameKey(uint32 hMDHandle, PWSTR pszMDPath, PWSTR pszMDNewName) mut => VT.[Friend]RenameKey(&this, hMDHandle, pszMDPath, pszMDNewName);

	public HRESULT SetData(uint32 hMDHandle, PWSTR pszMDPath, METADATA_RECORD* pmdrMDData) mut => VT.[Friend]SetData(&this, hMDHandle, pszMDPath, pmdrMDData);

	public HRESULT GetData(uint32 hMDHandle, PWSTR pszMDPath, METADATA_RECORD* pmdrMDData, uint32* pdwMDRequiredDataLen) mut => VT.[Friend]GetData(&this, hMDHandle, pszMDPath, pmdrMDData, pdwMDRequiredDataLen);

	public HRESULT DeleteData(uint32 hMDHandle, PWSTR pszMDPath, uint32 dwMDIdentifier, uint32 dwMDDataType) mut => VT.[Friend]DeleteData(&this, hMDHandle, pszMDPath, dwMDIdentifier, dwMDDataType);

	public HRESULT EnumData(uint32 hMDHandle, PWSTR pszMDPath, METADATA_RECORD* pmdrMDData, uint32 dwMDEnumDataIndex, uint32* pdwMDRequiredDataLen) mut => VT.[Friend]EnumData(&this, hMDHandle, pszMDPath, pmdrMDData, dwMDEnumDataIndex, pdwMDRequiredDataLen);

	public HRESULT GetAllData(uint32 hMDHandle, PWSTR pszMDPath, uint32 dwMDAttributes, uint32 dwMDUserType, uint32 dwMDDataType, uint32* pdwMDNumDataEntries, uint32* pdwMDDataSetNumber, uint32 dwMDBufferSize, uint8* pbMDBuffer, uint32* pdwMDRequiredBufferSize) mut => VT.[Friend]GetAllData(&this, hMDHandle, pszMDPath, dwMDAttributes, dwMDUserType, dwMDDataType, pdwMDNumDataEntries, pdwMDDataSetNumber, dwMDBufferSize, pbMDBuffer, pdwMDRequiredBufferSize);

	public HRESULT DeleteAllData(uint32 hMDHandle, PWSTR pszMDPath, uint32 dwMDUserType, uint32 dwMDDataType) mut => VT.[Friend]DeleteAllData(&this, hMDHandle, pszMDPath, dwMDUserType, dwMDDataType);

	public HRESULT CopyData(uint32 hMDSourceHandle, PWSTR pszMDSourcePath, uint32 hMDDestHandle, PWSTR pszMDDestPath, uint32 dwMDAttributes, uint32 dwMDUserType, uint32 dwMDDataType, BOOL bMDCopyFlag) mut => VT.[Friend]CopyData(&this, hMDSourceHandle, pszMDSourcePath, hMDDestHandle, pszMDDestPath, dwMDAttributes, dwMDUserType, dwMDDataType, bMDCopyFlag);

	public HRESULT GetDataPaths(uint32 hMDHandle, PWSTR pszMDPath, uint32 dwMDIdentifier, uint32 dwMDDataType, uint32 dwMDBufferSize, char16* pszBuffer, uint32* pdwMDRequiredBufferSize) mut => VT.[Friend]GetDataPaths(&this, hMDHandle, pszMDPath, dwMDIdentifier, dwMDDataType, dwMDBufferSize, pszBuffer, pdwMDRequiredBufferSize);

	public HRESULT OpenKey(uint32 hMDHandle, PWSTR pszMDPath, uint32 dwMDAccessRequested, uint32 dwMDTimeOut, uint32* phMDNewHandle) mut => VT.[Friend]OpenKey(&this, hMDHandle, pszMDPath, dwMDAccessRequested, dwMDTimeOut, phMDNewHandle);

	public HRESULT CloseKey(uint32 hMDHandle) mut => VT.[Friend]CloseKey(&this, hMDHandle);

	public HRESULT ChangePermissions(uint32 hMDHandle, uint32 dwMDTimeOut, uint32 dwMDAccessRequested) mut => VT.[Friend]ChangePermissions(&this, hMDHandle, dwMDTimeOut, dwMDAccessRequested);

	public HRESULT SaveData() mut => VT.[Friend]SaveData(&this);

	public HRESULT GetHandleInfo(uint32 hMDHandle, METADATA_HANDLE_INFO* pmdhiInfo) mut => VT.[Friend]GetHandleInfo(&this, hMDHandle, pmdhiInfo);

	public HRESULT GetSystemChangeNumber(uint32* pdwSystemChangeNumber) mut => VT.[Friend]GetSystemChangeNumber(&this, pdwSystemChangeNumber);

	public HRESULT GetDataSetNumber(uint32 hMDHandle, PWSTR pszMDPath, uint32* pdwMDDataSetNumber) mut => VT.[Friend]GetDataSetNumber(&this, hMDHandle, pszMDPath, pdwMDDataSetNumber);

	public HRESULT SetLastChangeTime(uint32 hMDHandle, PWSTR pszMDPath, FILETIME* pftMDLastChangeTime, BOOL bLocalTime) mut => VT.[Friend]SetLastChangeTime(&this, hMDHandle, pszMDPath, pftMDLastChangeTime, bLocalTime);

	public HRESULT GetLastChangeTime(uint32 hMDHandle, PWSTR pszMDPath, FILETIME* pftMDLastChangeTime, BOOL bLocalTime) mut => VT.[Friend]GetLastChangeTime(&this, hMDHandle, pszMDPath, pftMDLastChangeTime, bLocalTime);

	public HRESULT KeyExchangePhase1() mut => VT.[Friend]KeyExchangePhase1(&this);

	public HRESULT KeyExchangePhase2() mut => VT.[Friend]KeyExchangePhase2(&this);

	public HRESULT Backup(PWSTR pszMDBackupLocation, uint32 dwMDVersion, uint32 dwMDFlags) mut => VT.[Friend]Backup(&this, pszMDBackupLocation, dwMDVersion, dwMDFlags);

	public HRESULT Restore(PWSTR pszMDBackupLocation, uint32 dwMDVersion, uint32 dwMDFlags) mut => VT.[Friend]Restore(&this, pszMDBackupLocation, dwMDVersion, dwMDFlags);

	public HRESULT EnumBackups(char16* pszMDBackupLocation, uint32* pdwMDVersion, FILETIME* pftMDBackupTime, uint32 dwMDEnumIndex) mut => VT.[Friend]EnumBackups(&this, pszMDBackupLocation, pdwMDVersion, pftMDBackupTime, dwMDEnumIndex);

	public HRESULT DeleteBackup(PWSTR pszMDBackupLocation, uint32 dwMDVersion) mut => VT.[Friend]DeleteBackup(&this, pszMDBackupLocation, dwMDVersion);

	public HRESULT UnmarshalInterface(IMSAdminBaseW** piadmbwInterface) mut => VT.[Friend]UnmarshalInterface(&this, piadmbwInterface);

	public HRESULT GetServerGuid() mut => VT.[Friend]GetServerGuid(&this);
}

[CRepr]struct IMSAdminBase2W : IMSAdminBaseW
{
	public new const Guid IID = .(0x8298d101, 0xf992, 0x43b7, 0x8e, 0xca, 0x50, 0x52, 0xd8, 0x85, 0xb9, 0x95);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMSAdminBaseW.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMDBackupLocation, uint32 dwMDVersion, uint32 dwMDFlags, PWSTR pszPasswd) BackupWithPasswd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMDBackupLocation, uint32 dwMDVersion, uint32 dwMDFlags, PWSTR pszPasswd) RestoreWithPasswd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPasswd, PWSTR pszFileName, PWSTR pszSourcePath, uint32 dwMDFlags) Export;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPasswd, PWSTR pszFileName, PWSTR pszSourcePath, PWSTR pszDestPath, uint32 dwMDFlags) Import;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMDHistoryLocation, uint32 dwMDMajorVersion, uint32 dwMDMinorVersion, uint32 dwMDFlags) RestoreHistory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszMDHistoryLocation, uint32* pdwMDMajorVersion, uint32* pdwMDMinorVersion, FILETIME* pftMDHistoryTime, uint32 dwMDEnumIndex) EnumHistory;
	}


	public HRESULT BackupWithPasswd(PWSTR pszMDBackupLocation, uint32 dwMDVersion, uint32 dwMDFlags, PWSTR pszPasswd) mut => VT.[Friend]BackupWithPasswd(&this, pszMDBackupLocation, dwMDVersion, dwMDFlags, pszPasswd);

	public HRESULT RestoreWithPasswd(PWSTR pszMDBackupLocation, uint32 dwMDVersion, uint32 dwMDFlags, PWSTR pszPasswd) mut => VT.[Friend]RestoreWithPasswd(&this, pszMDBackupLocation, dwMDVersion, dwMDFlags, pszPasswd);

	public HRESULT Export(PWSTR pszPasswd, PWSTR pszFileName, PWSTR pszSourcePath, uint32 dwMDFlags) mut => VT.[Friend]Export(&this, pszPasswd, pszFileName, pszSourcePath, dwMDFlags);

	public HRESULT Import(PWSTR pszPasswd, PWSTR pszFileName, PWSTR pszSourcePath, PWSTR pszDestPath, uint32 dwMDFlags) mut => VT.[Friend]Import(&this, pszPasswd, pszFileName, pszSourcePath, pszDestPath, dwMDFlags);

	public HRESULT RestoreHistory(PWSTR pszMDHistoryLocation, uint32 dwMDMajorVersion, uint32 dwMDMinorVersion, uint32 dwMDFlags) mut => VT.[Friend]RestoreHistory(&this, pszMDHistoryLocation, dwMDMajorVersion, dwMDMinorVersion, dwMDFlags);

	public HRESULT EnumHistory(char16* pszMDHistoryLocation, uint32* pdwMDMajorVersion, uint32* pdwMDMinorVersion, FILETIME* pftMDHistoryTime, uint32 dwMDEnumIndex) mut => VT.[Friend]EnumHistory(&this, pszMDHistoryLocation, pdwMDMajorVersion, pdwMDMinorVersion, pftMDHistoryTime, dwMDEnumIndex);
}

[CRepr]struct IMSAdminBase3W : IMSAdminBase2W
{
	public new const Guid IID = .(0xf612954d, 0x3b0b, 0x4c56, 0x95, 0x63, 0x22, 0x7b, 0x7b, 0xe6, 0x24, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMSAdminBase2W.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 hMDHandle, PWSTR pszMDPath, uint32 cchMDBufferSize, char16* pszBuffer, uint32* pcchMDRequiredBufferSize) GetChildPaths;
	}


	public HRESULT GetChildPaths(uint32 hMDHandle, PWSTR pszMDPath, uint32 cchMDBufferSize, char16* pszBuffer, uint32* pcchMDRequiredBufferSize) mut => VT.[Friend]GetChildPaths(&this, hMDHandle, pszMDPath, cchMDBufferSize, pszBuffer, pcchMDRequiredBufferSize);
}

[CRepr]struct IMSImpExpHelpW : IUnknown
{
	public new const Guid IID = .(0x29ff67ff, 0x8050, 0x480f, 0x9f, 0x30, 0xcc, 0x41, 0x63, 0x5f, 0x2f, 0x9d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFileName, PWSTR pszKeyType, uint32 dwMDBufferSize, char16* pszBuffer, uint32* pdwMDRequiredBufferSize) EnumeratePathsInFile;
	}


	public HRESULT EnumeratePathsInFile(PWSTR pszFileName, PWSTR pszKeyType, uint32 dwMDBufferSize, char16* pszBuffer, uint32* pdwMDRequiredBufferSize) mut => VT.[Friend]EnumeratePathsInFile(&this, pszFileName, pszKeyType, dwMDBufferSize, pszBuffer, pdwMDRequiredBufferSize);
}

[CRepr]struct IMSAdminBaseSinkW : IUnknown
{
	public new const Guid IID = .(0xa9e69612, 0xb80d, 0x11d0, 0xb9, 0xb9, 0x00, 0xa0, 0xc9, 0x22, 0xe7, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMDNumElements, MD_CHANGE_OBJECT_W* pcoChangeList) SinkNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShutdownNotify;
	}


	public HRESULT SinkNotify(uint32 dwMDNumElements, MD_CHANGE_OBJECT_W* pcoChangeList) mut => VT.[Friend]SinkNotify(&this, dwMDNumElements, pcoChangeList);

	public HRESULT ShutdownNotify() mut => VT.[Friend]ShutdownNotify(&this);
}

[CRepr]struct AsyncIMSAdminBaseSinkW : IUnknown
{
	public new const Guid IID = .(0xa9e69613, 0xb80d, 0x11d0, 0xb9, 0xb9, 0x00, 0xa0, 0xc9, 0x22, 0xe7, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMDNumElements, MD_CHANGE_OBJECT_W* pcoChangeList) Begin_SinkNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_SinkNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Begin_ShutdownNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_ShutdownNotify;
	}


	public HRESULT Begin_SinkNotify(uint32 dwMDNumElements, MD_CHANGE_OBJECT_W* pcoChangeList) mut => VT.[Friend]Begin_SinkNotify(&this, dwMDNumElements, pcoChangeList);

	public HRESULT Finish_SinkNotify() mut => VT.[Friend]Finish_SinkNotify(&this);

	public HRESULT Begin_ShutdownNotify() mut => VT.[Friend]Begin_ShutdownNotify(&this);

	public HRESULT Finish_ShutdownNotify() mut => VT.[Friend]Finish_ShutdownNotify(&this);
}

#endregion

#region Functions
public static
{
	[Import("RpcProxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetExtensionVersion(HSE_VERSION_INFO* pVer);

	[Import("RpcProxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpExtensionProc(EXTENSION_CONTROL_BLOCK* pECB);

	[Import("RpcProxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HttpFilterProc(HTTP_FILTER_CONTEXT* pfc, uint32 NotificationType, void* pvNotification);

	[Import("RpcProxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFilterVersion(HTTP_FILTER_VERSION* pVer);

}
#endregion
