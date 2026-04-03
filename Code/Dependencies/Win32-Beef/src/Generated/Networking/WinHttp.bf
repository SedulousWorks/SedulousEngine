using Win32.Networking.WinSock;
using Win32.Foundation;
using System;

namespace Win32.Networking.WinHttp;

#region Constants
public static
{
	public const uint32 WINHTTP_FLAG_ASYNC = 268435456;
	public const uint32 WINHTTP_FLAG_SECURE_DEFAULTS = 805306368;
	public const uint32 SECURITY_FLAG_IGNORE_UNKNOWN_CA = 256;
	public const uint32 SECURITY_FLAG_IGNORE_CERT_DATE_INVALID = 8192;
	public const uint32 SECURITY_FLAG_IGNORE_CERT_CN_INVALID = 4096;
	public const uint32 SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE = 512;
	public const uint32 WINHTTP_AUTOPROXY_AUTO_DETECT = 1;
	public const uint32 WINHTTP_AUTOPROXY_CONFIG_URL = 2;
	public const uint32 WINHTTP_AUTOPROXY_HOST_KEEPCASE = 4;
	public const uint32 WINHTTP_AUTOPROXY_HOST_LOWERCASE = 8;
	public const uint32 WINHTTP_AUTOPROXY_ALLOW_AUTOCONFIG = 256;
	public const uint32 WINHTTP_AUTOPROXY_ALLOW_STATIC = 512;
	public const uint32 WINHTTP_AUTOPROXY_ALLOW_CM = 1024;
	public const uint32 WINHTTP_AUTOPROXY_RUN_INPROCESS = 65536;
	public const uint32 WINHTTP_AUTOPROXY_RUN_OUTPROCESS_ONLY = 131072;
	public const uint32 WINHTTP_AUTOPROXY_NO_DIRECTACCESS = 262144;
	public const uint32 WINHTTP_AUTOPROXY_NO_CACHE_CLIENT = 524288;
	public const uint32 WINHTTP_AUTOPROXY_NO_CACHE_SVC = 1048576;
	public const uint32 WINHTTP_AUTOPROXY_SORT_RESULTS = 4194304;
	public const uint32 WINHTTP_AUTO_DETECT_TYPE_DHCP = 1;
	public const uint32 WINHTTP_AUTO_DETECT_TYPE_DNS_A = 2;
	public const uint32 NETWORKING_KEY_BUFSIZE = 128;
	public const uint32 WINHTTP_PROXY_TYPE_DIRECT = 1;
	public const uint32 WINHTTP_PROXY_TYPE_PROXY = 2;
	public const uint32 WINHTTP_PROXY_TYPE_AUTO_PROXY_URL = 4;
	public const uint32 WINHTTP_PROXY_TYPE_AUTO_DETECT = 8;
	public const uint32 WINHTTP_REQUEST_STAT_FLAG_TCP_FAST_OPEN = 1;
	public const uint32 WINHTTP_REQUEST_STAT_FLAG_TLS_SESSION_RESUMPTION = 2;
	public const uint32 WINHTTP_REQUEST_STAT_FLAG_TLS_FALSE_START = 4;
	public const uint32 WINHTTP_REQUEST_STAT_FLAG_PROXY_TLS_SESSION_RESUMPTION = 8;
	public const uint32 WINHTTP_REQUEST_STAT_FLAG_PROXY_TLS_FALSE_START = 16;
	public const uint32 WINHTTP_REQUEST_STAT_FLAG_FIRST_REQUEST = 32;
	public const uint32 WINHTTP_MATCH_CONNECTION_GUID_FLAG_REQUIRE_MARKED_CONNECTION = 1;
	public const uint32 WINHTTP_MATCH_CONNECTION_GUID_FLAGS_MASK = 1;
	public const uint32 WINHTTP_RESOLVER_CACHE_CONFIG_FLAG_SOFT_LIMIT = 1;
	public const uint32 WINHTTP_RESOLVER_CACHE_CONFIG_FLAG_BYPASS_CACHE = 2;
	public const uint32 WINHTTP_RESOLVER_CACHE_CONFIG_FLAG_USE_DNS_TTL = 4;
	public const uint32 WINHTTP_RESOLVER_CACHE_CONFIG_FLAG_CONN_USE_TTL = 8;
	public const uint32 WINHTTP_TIME_FORMAT_BUFSIZE = 62;
	public const uint32 WINHTTP_OPTION_CALLBACK = 1;
	public const uint32 WINHTTP_OPTION_RESOLVE_TIMEOUT = 2;
	public const uint32 WINHTTP_OPTION_CONNECT_TIMEOUT = 3;
	public const uint32 WINHTTP_OPTION_CONNECT_RETRIES = 4;
	public const uint32 WINHTTP_OPTION_SEND_TIMEOUT = 5;
	public const uint32 WINHTTP_OPTION_RECEIVE_TIMEOUT = 6;
	public const uint32 WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT = 7;
	public const uint32 WINHTTP_OPTION_HANDLE_TYPE = 9;
	public const uint32 WINHTTP_OPTION_READ_BUFFER_SIZE = 12;
	public const uint32 WINHTTP_OPTION_WRITE_BUFFER_SIZE = 13;
	public const uint32 WINHTTP_OPTION_PARENT_HANDLE = 21;
	public const uint32 WINHTTP_OPTION_EXTENDED_ERROR = 24;
	public const uint32 WINHTTP_OPTION_SECURITY_FLAGS = 31;
	public const uint32 WINHTTP_OPTION_SECURITY_CERTIFICATE_STRUCT = 32;
	public const uint32 WINHTTP_OPTION_URL = 34;
	public const uint32 WINHTTP_OPTION_SECURITY_KEY_BITNESS = 36;
	public const uint32 WINHTTP_OPTION_PROXY = 38;
	public const uint32 WINHTTP_OPTION_PROXY_RESULT_ENTRY = 39;
	public const uint32 WINHTTP_OPTION_USER_AGENT = 41;
	public const uint32 WINHTTP_OPTION_CONTEXT_VALUE = 45;
	public const uint32 WINHTTP_OPTION_CLIENT_CERT_CONTEXT = 47;
	public const uint32 WINHTTP_OPTION_REQUEST_PRIORITY = 58;
	public const uint32 WINHTTP_OPTION_HTTP_VERSION = 59;
	public const uint32 WINHTTP_OPTION_DISABLE_FEATURE = 63;
	public const uint32 WINHTTP_OPTION_CODEPAGE = 68;
	public const uint32 WINHTTP_OPTION_MAX_CONNS_PER_SERVER = 73;
	public const uint32 WINHTTP_OPTION_MAX_CONNS_PER_1_0_SERVER = 74;
	public const uint32 WINHTTP_OPTION_AUTOLOGON_POLICY = 77;
	public const uint32 WINHTTP_OPTION_SERVER_CERT_CONTEXT = 78;
	public const uint32 WINHTTP_OPTION_ENABLE_FEATURE = 79;
	public const uint32 WINHTTP_OPTION_WORKER_THREAD_COUNT = 80;
	public const uint32 WINHTTP_OPTION_PASSPORT_COBRANDING_TEXT = 81;
	public const uint32 WINHTTP_OPTION_PASSPORT_COBRANDING_URL = 82;
	public const uint32 WINHTTP_OPTION_CONFIGURE_PASSPORT_AUTH = 83;
	public const uint32 WINHTTP_OPTION_SECURE_PROTOCOLS = 84;
	public const uint32 WINHTTP_OPTION_ENABLETRACING = 85;
	public const uint32 WINHTTP_OPTION_PASSPORT_SIGN_OUT = 86;
	public const uint32 WINHTTP_OPTION_PASSPORT_RETURN_URL = 87;
	public const uint32 WINHTTP_OPTION_REDIRECT_POLICY = 88;
	public const uint32 WINHTTP_OPTION_MAX_HTTP_AUTOMATIC_REDIRECTS = 89;
	public const uint32 WINHTTP_OPTION_MAX_HTTP_STATUS_CONTINUE = 90;
	public const uint32 WINHTTP_OPTION_MAX_RESPONSE_HEADER_SIZE = 91;
	public const uint32 WINHTTP_OPTION_MAX_RESPONSE_DRAIN_SIZE = 92;
	public const uint32 WINHTTP_OPTION_CONNECTION_INFO = 93;
	public const uint32 WINHTTP_OPTION_CLIENT_CERT_ISSUER_LIST = 94;
	public const uint32 WINHTTP_OPTION_SPN = 96;
	public const uint32 WINHTTP_OPTION_GLOBAL_PROXY_CREDS = 97;
	public const uint32 WINHTTP_OPTION_GLOBAL_SERVER_CREDS = 98;
	public const uint32 WINHTTP_OPTION_UNLOAD_NOTIFY_EVENT = 99;
	public const uint32 WINHTTP_OPTION_REJECT_USERPWD_IN_URL = 100;
	public const uint32 WINHTTP_OPTION_USE_GLOBAL_SERVER_CREDENTIALS = 101;
	public const uint32 WINHTTP_OPTION_RECEIVE_PROXY_CONNECT_RESPONSE = 103;
	public const uint32 WINHTTP_OPTION_IS_PROXY_CONNECT_RESPONSE = 104;
	public const uint32 WINHTTP_OPTION_SERVER_SPN_USED = 106;
	public const uint32 WINHTTP_OPTION_PROXY_SPN_USED = 107;
	public const uint32 WINHTTP_OPTION_SERVER_CBT = 108;
	public const uint32 WINHTTP_OPTION_UNSAFE_HEADER_PARSING = 110;
	public const uint32 WINHTTP_OPTION_ASSURED_NON_BLOCKING_CALLBACKS = 111;
	public const uint32 WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET = 114;
	public const uint32 WINHTTP_OPTION_WEB_SOCKET_CLOSE_TIMEOUT = 115;
	public const uint32 WINHTTP_OPTION_WEB_SOCKET_KEEPALIVE_INTERVAL = 116;
	public const uint32 WINHTTP_OPTION_DECOMPRESSION = 118;
	public const uint32 WINHTTP_OPTION_WEB_SOCKET_RECEIVE_BUFFER_SIZE = 122;
	public const uint32 WINHTTP_OPTION_WEB_SOCKET_SEND_BUFFER_SIZE = 123;
	public const uint32 WINHTTP_OPTION_TCP_PRIORITY_HINT = 128;
	public const uint32 WINHTTP_OPTION_CONNECTION_FILTER = 131;
	public const uint32 WINHTTP_OPTION_ENABLE_HTTP_PROTOCOL = 133;
	public const uint32 WINHTTP_OPTION_HTTP_PROTOCOL_USED = 134;
	public const uint32 WINHTTP_OPTION_KDC_PROXY_SETTINGS = 136;
	public const uint32 WINHTTP_OPTION_PROXY_DISABLE_SERVICE_CALLS = 137;
	public const uint32 WINHTTP_OPTION_ENCODE_EXTRA = 138;
	public const uint32 WINHTTP_OPTION_DISABLE_STREAM_QUEUE = 139;
	public const uint32 WINHTTP_OPTION_IPV6_FAST_FALLBACK = 140;
	public const uint32 WINHTTP_OPTION_CONNECTION_STATS_V0 = 141;
	public const uint32 WINHTTP_OPTION_REQUEST_TIMES = 142;
	public const uint32 WINHTTP_OPTION_EXPIRE_CONNECTION = 143;
	public const uint32 WINHTTP_OPTION_DISABLE_SECURE_PROTOCOL_FALLBACK = 144;
	public const uint32 WINHTTP_OPTION_HTTP_PROTOCOL_REQUIRED = 145;
	public const uint32 WINHTTP_OPTION_REQUEST_STATS = 146;
	public const uint32 WINHTTP_OPTION_SERVER_CERT_CHAIN_CONTEXT = 147;
	public const uint32 WINHTTP_OPTION_CONNECTION_STATS_V1 = 150;
	public const uint32 WINHTTP_OPTION_SECURITY_INFO = 151;
	public const uint32 WINHTTP_OPTION_TCP_KEEPALIVE = 152;
	public const uint32 WINHTTP_OPTION_TCP_FAST_OPEN = 153;
	public const uint32 WINHTTP_OPTION_TLS_FALSE_START = 154;
	public const uint32 WINHTTP_OPTION_IGNORE_CERT_REVOCATION_OFFLINE = 155;
	public const uint32 WINHTTP_OPTION_SOURCE_ADDRESS = 156;
	public const uint32 WINHTTP_OPTION_HEAP_EXTENSION = 157;
	public const uint32 WINHTTP_OPTION_TLS_PROTOCOL_INSECURE_FALLBACK = 158;
	public const uint32 WINHTTP_OPTION_STREAM_ERROR_CODE = 159;
	public const uint32 WINHTTP_OPTION_REQUIRE_STREAM_END = 160;
	public const uint32 WINHTTP_OPTION_ENABLE_HTTP2_PLUS_CLIENT_CERT = 161;
	public const uint32 WINHTTP_OPTION_FAILED_CONNECTION_RETRIES = 162;
	public const uint32 WINHTTP_OPTION_SET_GLOBAL_CALLBACK = 163;
	public const uint32 WINHTTP_OPTION_HTTP2_KEEPALIVE = 164;
	public const uint32 WINHTTP_OPTION_RESOLUTION_HOSTNAME = 165;
	public const uint32 WINHTTP_OPTION_SET_TOKEN_BINDING = 166;
	public const uint32 WINHTTP_OPTION_TOKEN_BINDING_PUBLIC_KEY = 167;
	public const uint32 WINHTTP_OPTION_REFERER_TOKEN_BINDING_HOSTNAME = 168;
	public const uint32 WINHTTP_OPTION_HTTP2_PLUS_TRANSFER_ENCODING = 169;
	public const uint32 WINHTTP_OPTION_RESOLVER_CACHE_CONFIG = 170;
	public const uint32 WINHTTP_OPTION_DISABLE_CERT_CHAIN_BUILDING = 171;
	public const uint32 WINHTTP_OPTION_BACKGROUND_CONNECTIONS = 172;
	public const uint32 WINHTTP_OPTION_FIRST_AVAILABLE_CONNECTION = 173;
	public const uint32 WINHTTP_OPTION_ENABLE_TEST_SIGNING = 174;
	public const uint32 WINHTTP_OPTION_NTSERVICE_FLAG_TEST = 175;
	public const uint32 WINHTTP_OPTION_DISABLE_PROXY_LINK_LOCAL_NAME_RESOLUTION = 176;
	public const uint32 WINHTTP_OPTION_TCP_PRIORITY_STATUS = 177;
	public const uint32 WINHTTP_OPTION_CONNECTION_GUID = 178;
	public const uint32 WINHTTP_OPTION_MATCH_CONNECTION_GUID = 179;
	public const uint32 WINHTTP_OPTION_PROXY_CONFIG_INFO = 180;
	public const uint32 WINHTTP_OPTION_AGGREGATE_PROXY_CONFIG = 181;
	public const uint32 WINHTTP_OPTION_SELECTED_PROXY_CONFIG_INFO = 182;
	public const uint32 WINHTTP_OPTION_HTTP2_RECEIVE_WINDOW = 183;
	public const uint32 WINHTTP_LAST_OPTION = 183;
	public const uint32 WINHTTP_OPTION_USERNAME = 4096;
	public const uint32 WINHTTP_OPTION_PASSWORD = 4097;
	public const uint32 WINHTTP_OPTION_PROXY_USERNAME = 4098;
	public const uint32 WINHTTP_OPTION_PROXY_PASSWORD = 4099;
	public const uint32 WINHTTP_CONNS_PER_SERVER_UNLIMITED = 4294967295;
	public const uint32 WINHTTP_CONNECTION_RETRY_CONDITION_408 = 1;
	public const uint32 WINHTTP_CONNECTION_RETRY_CONDITION_SSL_HANDSHAKE = 2;
	public const uint32 WINHTTP_CONNECTION_RETRY_CONDITION_STALE_CONNECTION = 4;
	public const uint32 WINHTTP_DECOMPRESSION_FLAG_GZIP = 1;
	public const uint32 WINHTTP_DECOMPRESSION_FLAG_DEFLATE = 2;
	public const uint32 WINHTTP_PROTOCOL_FLAG_HTTP2 = 1;
	public const uint32 WINHTTP_PROTOCOL_FLAG_HTTP3 = 2;
	public const uint32 WINHTTP_AUTOLOGON_SECURITY_LEVEL_MEDIUM = 0;
	public const uint32 WINHTTP_AUTOLOGON_SECURITY_LEVEL_LOW = 1;
	public const uint32 WINHTTP_AUTOLOGON_SECURITY_LEVEL_HIGH = 2;
	public const uint32 WINHTTP_AUTOLOGON_SECURITY_LEVEL_DEFAULT = 0;
	public const uint32 WINHTTP_OPTION_REDIRECT_POLICY_NEVER = 0;
	public const uint32 WINHTTP_OPTION_REDIRECT_POLICY_DISALLOW_HTTPS_TO_HTTP = 1;
	public const uint32 WINHTTP_OPTION_REDIRECT_POLICY_ALWAYS = 2;
	public const uint32 WINHTTP_OPTION_REDIRECT_POLICY_LAST = 2;
	public const uint32 WINHTTP_OPTION_REDIRECT_POLICY_DEFAULT = 1;
	public const uint32 WINHTTP_DISABLE_PASSPORT_AUTH = 0;
	public const uint32 WINHTTP_ENABLE_PASSPORT_AUTH = 268435456;
	public const uint32 WINHTTP_DISABLE_PASSPORT_KEYRING = 536870912;
	public const uint32 WINHTTP_ENABLE_PASSPORT_KEYRING = 1073741824;
	public const uint32 WINHTTP_DISABLE_COOKIES = 1;
	public const uint32 WINHTTP_DISABLE_REDIRECTS = 2;
	public const uint32 WINHTTP_DISABLE_AUTHENTICATION = 4;
	public const uint32 WINHTTP_DISABLE_KEEP_ALIVE = 8;
	public const uint32 WINHTTP_ENABLE_SSL_REVOCATION = 1;
	public const uint32 WINHTTP_ENABLE_SSL_REVERT_IMPERSONATION = 2;
	public const uint32 WINHTTP_DISABLE_SPN_SERVER_PORT = 0;
	public const uint32 WINHTTP_ENABLE_SPN_SERVER_PORT = 1;
	public const uint32 WINHTTP_OPTION_SPN_MASK = 1;
	public const uint32 WINHTTP_HANDLE_TYPE_SESSION = 1;
	public const uint32 WINHTTP_HANDLE_TYPE_CONNECT = 2;
	public const uint32 WINHTTP_HANDLE_TYPE_REQUEST = 3;
	public const uint32 WINHTTP_AUTH_SCHEME_PASSPORT = 4;
	public const uint32 WINHTTP_AUTH_SCHEME_DIGEST = 8;
	public const uint32 WINHTTP_AUTH_TARGET_SERVER = 0;
	public const uint32 WINHTTP_AUTH_TARGET_PROXY = 1;
	public const uint32 SECURITY_FLAG_SECURE = 1;
	public const uint32 SECURITY_FLAG_STRENGTH_WEAK = 268435456;
	public const uint32 SECURITY_FLAG_STRENGTH_MEDIUM = 1073741824;
	public const uint32 SECURITY_FLAG_STRENGTH_STRONG = 536870912;
	public const uint32 WINHTTP_CALLBACK_STATUS_FLAG_CERT_REV_FAILED = 1;
	public const uint32 WINHTTP_CALLBACK_STATUS_FLAG_INVALID_CERT = 2;
	public const uint32 WINHTTP_CALLBACK_STATUS_FLAG_CERT_REVOKED = 4;
	public const uint32 WINHTTP_CALLBACK_STATUS_FLAG_INVALID_CA = 8;
	public const uint32 WINHTTP_CALLBACK_STATUS_FLAG_CERT_CN_INVALID = 16;
	public const uint32 WINHTTP_CALLBACK_STATUS_FLAG_CERT_DATE_INVALID = 32;
	public const uint32 WINHTTP_CALLBACK_STATUS_FLAG_CERT_WRONG_USAGE = 64;
	public const uint32 WINHTTP_CALLBACK_STATUS_FLAG_SECURITY_CHANNEL_ERROR = 2147483648;
	public const uint32 WINHTTP_FLAG_SECURE_PROTOCOL_SSL2 = 8;
	public const uint32 WINHTTP_FLAG_SECURE_PROTOCOL_SSL3 = 32;
	public const uint32 WINHTTP_FLAG_SECURE_PROTOCOL_TLS1 = 128;
	public const uint32 WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_1 = 512;
	public const uint32 WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_2 = 2048;
	public const uint32 WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_3 = 8192;
	public const uint32 WINHTTP_CALLBACK_STATUS_RESOLVING_NAME = 1;
	public const uint32 WINHTTP_CALLBACK_STATUS_NAME_RESOLVED = 2;
	public const uint32 WINHTTP_CALLBACK_STATUS_CONNECTING_TO_SERVER = 4;
	public const uint32 WINHTTP_CALLBACK_STATUS_CONNECTED_TO_SERVER = 8;
	public const uint32 WINHTTP_CALLBACK_STATUS_SENDING_REQUEST = 16;
	public const uint32 WINHTTP_CALLBACK_STATUS_REQUEST_SENT = 32;
	public const uint32 WINHTTP_CALLBACK_STATUS_RECEIVING_RESPONSE = 64;
	public const uint32 WINHTTP_CALLBACK_STATUS_RESPONSE_RECEIVED = 128;
	public const uint32 WINHTTP_CALLBACK_STATUS_CLOSING_CONNECTION = 256;
	public const uint32 WINHTTP_CALLBACK_STATUS_CONNECTION_CLOSED = 512;
	public const uint32 WINHTTP_CALLBACK_STATUS_HANDLE_CREATED = 1024;
	public const uint32 WINHTTP_CALLBACK_STATUS_HANDLE_CLOSING = 2048;
	public const uint32 WINHTTP_CALLBACK_STATUS_DETECTING_PROXY = 4096;
	public const uint32 WINHTTP_CALLBACK_STATUS_REDIRECT = 16384;
	public const uint32 WINHTTP_CALLBACK_STATUS_INTERMEDIATE_RESPONSE = 32768;
	public const uint32 WINHTTP_CALLBACK_STATUS_SECURE_FAILURE = 65536;
	public const uint32 WINHTTP_CALLBACK_STATUS_HEADERS_AVAILABLE = 131072;
	public const uint32 WINHTTP_CALLBACK_STATUS_DATA_AVAILABLE = 262144;
	public const uint32 WINHTTP_CALLBACK_STATUS_READ_COMPLETE = 524288;
	public const uint32 WINHTTP_CALLBACK_STATUS_WRITE_COMPLETE = 1048576;
	public const uint32 WINHTTP_CALLBACK_STATUS_REQUEST_ERROR = 2097152;
	public const uint32 WINHTTP_CALLBACK_STATUS_SENDREQUEST_COMPLETE = 4194304;
	public const uint32 WINHTTP_CALLBACK_STATUS_GETPROXYFORURL_COMPLETE = 16777216;
	public const uint32 WINHTTP_CALLBACK_STATUS_CLOSE_COMPLETE = 33554432;
	public const uint32 WINHTTP_CALLBACK_STATUS_SHUTDOWN_COMPLETE = 67108864;
	public const uint32 WINHTTP_CALLBACK_STATUS_SETTINGS_WRITE_COMPLETE = 268435456;
	public const uint32 WINHTTP_CALLBACK_STATUS_SETTINGS_READ_COMPLETE = 536870912;
	public const uint32 API_RECEIVE_RESPONSE = 1;
	public const uint32 API_QUERY_DATA_AVAILABLE = 2;
	public const uint32 API_READ_DATA = 3;
	public const uint32 API_WRITE_DATA = 4;
	public const uint32 API_SEND_REQUEST = 5;
	public const uint32 API_GET_PROXY_FOR_URL = 6;
	public const uint32 WINHTTP_CALLBACK_FLAG_DETECTING_PROXY = 4096;
	public const uint32 WINHTTP_CALLBACK_FLAG_REDIRECT = 16384;
	public const uint32 WINHTTP_CALLBACK_FLAG_INTERMEDIATE_RESPONSE = 32768;
	public const uint32 WINHTTP_CALLBACK_FLAG_SECURE_FAILURE = 65536;
	public const uint32 WINHTTP_CALLBACK_FLAG_SENDREQUEST_COMPLETE = 4194304;
	public const uint32 WINHTTP_CALLBACK_FLAG_HEADERS_AVAILABLE = 131072;
	public const uint32 WINHTTP_CALLBACK_FLAG_DATA_AVAILABLE = 262144;
	public const uint32 WINHTTP_CALLBACK_FLAG_READ_COMPLETE = 524288;
	public const uint32 WINHTTP_CALLBACK_FLAG_WRITE_COMPLETE = 1048576;
	public const uint32 WINHTTP_CALLBACK_FLAG_REQUEST_ERROR = 2097152;
	public const uint32 WINHTTP_CALLBACK_FLAG_GETPROXYFORURL_COMPLETE = 16777216;
	public const uint32 WINHTTP_CALLBACK_FLAG_ALL_NOTIFICATIONS = 4294967295;
	public const uint32 WINHTTP_QUERY_MIME_VERSION = 0;
	public const uint32 WINHTTP_QUERY_CONTENT_TYPE = 1;
	public const uint32 WINHTTP_QUERY_CONTENT_TRANSFER_ENCODING = 2;
	public const uint32 WINHTTP_QUERY_CONTENT_ID = 3;
	public const uint32 WINHTTP_QUERY_CONTENT_DESCRIPTION = 4;
	public const uint32 WINHTTP_QUERY_CONTENT_LENGTH = 5;
	public const uint32 WINHTTP_QUERY_CONTENT_LANGUAGE = 6;
	public const uint32 WINHTTP_QUERY_ALLOW = 7;
	public const uint32 WINHTTP_QUERY_PUBLIC = 8;
	public const uint32 WINHTTP_QUERY_DATE = 9;
	public const uint32 WINHTTP_QUERY_EXPIRES = 10;
	public const uint32 WINHTTP_QUERY_LAST_MODIFIED = 11;
	public const uint32 WINHTTP_QUERY_MESSAGE_ID = 12;
	public const uint32 WINHTTP_QUERY_URI = 13;
	public const uint32 WINHTTP_QUERY_DERIVED_FROM = 14;
	public const uint32 WINHTTP_QUERY_COST = 15;
	public const uint32 WINHTTP_QUERY_LINK = 16;
	public const uint32 WINHTTP_QUERY_PRAGMA = 17;
	public const uint32 WINHTTP_QUERY_VERSION = 18;
	public const uint32 WINHTTP_QUERY_STATUS_CODE = 19;
	public const uint32 WINHTTP_QUERY_STATUS_TEXT = 20;
	public const uint32 WINHTTP_QUERY_RAW_HEADERS = 21;
	public const uint32 WINHTTP_QUERY_RAW_HEADERS_CRLF = 22;
	public const uint32 WINHTTP_QUERY_CONNECTION = 23;
	public const uint32 WINHTTP_QUERY_ACCEPT = 24;
	public const uint32 WINHTTP_QUERY_ACCEPT_CHARSET = 25;
	public const uint32 WINHTTP_QUERY_ACCEPT_ENCODING = 26;
	public const uint32 WINHTTP_QUERY_ACCEPT_LANGUAGE = 27;
	public const uint32 WINHTTP_QUERY_AUTHORIZATION = 28;
	public const uint32 WINHTTP_QUERY_CONTENT_ENCODING = 29;
	public const uint32 WINHTTP_QUERY_FORWARDED = 30;
	public const uint32 WINHTTP_QUERY_FROM = 31;
	public const uint32 WINHTTP_QUERY_IF_MODIFIED_SINCE = 32;
	public const uint32 WINHTTP_QUERY_LOCATION = 33;
	public const uint32 WINHTTP_QUERY_ORIG_URI = 34;
	public const uint32 WINHTTP_QUERY_REFERER = 35;
	public const uint32 WINHTTP_QUERY_RETRY_AFTER = 36;
	public const uint32 WINHTTP_QUERY_SERVER = 37;
	public const uint32 WINHTTP_QUERY_TITLE = 38;
	public const uint32 WINHTTP_QUERY_USER_AGENT = 39;
	public const uint32 WINHTTP_QUERY_WWW_AUTHENTICATE = 40;
	public const uint32 WINHTTP_QUERY_PROXY_AUTHENTICATE = 41;
	public const uint32 WINHTTP_QUERY_ACCEPT_RANGES = 42;
	public const uint32 WINHTTP_QUERY_SET_COOKIE = 43;
	public const uint32 WINHTTP_QUERY_COOKIE = 44;
	public const uint32 WINHTTP_QUERY_REQUEST_METHOD = 45;
	public const uint32 WINHTTP_QUERY_REFRESH = 46;
	public const uint32 WINHTTP_QUERY_CONTENT_DISPOSITION = 47;
	public const uint32 WINHTTP_QUERY_AGE = 48;
	public const uint32 WINHTTP_QUERY_CACHE_CONTROL = 49;
	public const uint32 WINHTTP_QUERY_CONTENT_BASE = 50;
	public const uint32 WINHTTP_QUERY_CONTENT_LOCATION = 51;
	public const uint32 WINHTTP_QUERY_CONTENT_MD5 = 52;
	public const uint32 WINHTTP_QUERY_CONTENT_RANGE = 53;
	public const uint32 WINHTTP_QUERY_ETAG = 54;
	public const uint32 WINHTTP_QUERY_HOST = 55;
	public const uint32 WINHTTP_QUERY_IF_MATCH = 56;
	public const uint32 WINHTTP_QUERY_IF_NONE_MATCH = 57;
	public const uint32 WINHTTP_QUERY_IF_RANGE = 58;
	public const uint32 WINHTTP_QUERY_IF_UNMODIFIED_SINCE = 59;
	public const uint32 WINHTTP_QUERY_MAX_FORWARDS = 60;
	public const uint32 WINHTTP_QUERY_PROXY_AUTHORIZATION = 61;
	public const uint32 WINHTTP_QUERY_RANGE = 62;
	public const uint32 WINHTTP_QUERY_TRANSFER_ENCODING = 63;
	public const uint32 WINHTTP_QUERY_UPGRADE = 64;
	public const uint32 WINHTTP_QUERY_VARY = 65;
	public const uint32 WINHTTP_QUERY_VIA = 66;
	public const uint32 WINHTTP_QUERY_WARNING = 67;
	public const uint32 WINHTTP_QUERY_EXPECT = 68;
	public const uint32 WINHTTP_QUERY_PROXY_CONNECTION = 69;
	public const uint32 WINHTTP_QUERY_UNLESS_MODIFIED_SINCE = 70;
	public const uint32 WINHTTP_QUERY_PROXY_SUPPORT = 75;
	public const uint32 WINHTTP_QUERY_AUTHENTICATION_INFO = 76;
	public const uint32 WINHTTP_QUERY_PASSPORT_URLS = 77;
	public const uint32 WINHTTP_QUERY_PASSPORT_CONFIG = 78;
	public const uint32 WINHTTP_QUERY_MAX = 78;
	public const uint32 WINHTTP_QUERY_EX_ALL_HEADERS = 21;
	public const uint32 WINHTTP_QUERY_CUSTOM = 65535;
	public const uint32 WINHTTP_QUERY_FLAG_REQUEST_HEADERS = 2147483648;
	public const uint32 WINHTTP_QUERY_FLAG_SYSTEMTIME = 1073741824;
	public const uint32 WINHTTP_QUERY_FLAG_NUMBER = 536870912;
	public const uint32 WINHTTP_QUERY_FLAG_NUMBER64 = 134217728;
	public const uint32 WINHTTP_QUERY_FLAG_TRAILERS = 33554432;
	public const uint32 WINHTTP_QUERY_FLAG_WIRE_ENCODING = 16777216;
	public const uint32 HTTP_STATUS_CONTINUE = 100;
	public const uint32 HTTP_STATUS_SWITCH_PROTOCOLS = 101;
	public const uint32 HTTP_STATUS_OK = 200;
	public const uint32 HTTP_STATUS_CREATED = 201;
	public const uint32 HTTP_STATUS_ACCEPTED = 202;
	public const uint32 HTTP_STATUS_PARTIAL = 203;
	public const uint32 HTTP_STATUS_NO_CONTENT = 204;
	public const uint32 HTTP_STATUS_RESET_CONTENT = 205;
	public const uint32 HTTP_STATUS_PARTIAL_CONTENT = 206;
	public const uint32 HTTP_STATUS_WEBDAV_MULTI_STATUS = 207;
	public const uint32 HTTP_STATUS_AMBIGUOUS = 300;
	public const uint32 HTTP_STATUS_MOVED = 301;
	public const uint32 HTTP_STATUS_REDIRECT = 302;
	public const uint32 HTTP_STATUS_REDIRECT_METHOD = 303;
	public const uint32 HTTP_STATUS_NOT_MODIFIED = 304;
	public const uint32 HTTP_STATUS_USE_PROXY = 305;
	public const uint32 HTTP_STATUS_REDIRECT_KEEP_VERB = 307;
	public const uint32 HTTP_STATUS_PERMANENT_REDIRECT = 308;
	public const uint32 HTTP_STATUS_BAD_REQUEST = 400;
	public const uint32 HTTP_STATUS_DENIED = 401;
	public const uint32 HTTP_STATUS_PAYMENT_REQ = 402;
	public const uint32 HTTP_STATUS_FORBIDDEN = 403;
	public const uint32 HTTP_STATUS_NOT_FOUND = 404;
	public const uint32 HTTP_STATUS_BAD_METHOD = 405;
	public const uint32 HTTP_STATUS_NONE_ACCEPTABLE = 406;
	public const uint32 HTTP_STATUS_PROXY_AUTH_REQ = 407;
	public const uint32 HTTP_STATUS_REQUEST_TIMEOUT = 408;
	public const uint32 HTTP_STATUS_CONFLICT = 409;
	public const uint32 HTTP_STATUS_GONE = 410;
	public const uint32 HTTP_STATUS_LENGTH_REQUIRED = 411;
	public const uint32 HTTP_STATUS_PRECOND_FAILED = 412;
	public const uint32 HTTP_STATUS_REQUEST_TOO_LARGE = 413;
	public const uint32 HTTP_STATUS_URI_TOO_LONG = 414;
	public const uint32 HTTP_STATUS_UNSUPPORTED_MEDIA = 415;
	public const uint32 HTTP_STATUS_RETRY_WITH = 449;
	public const uint32 HTTP_STATUS_SERVER_ERROR = 500;
	public const uint32 HTTP_STATUS_NOT_SUPPORTED = 501;
	public const uint32 HTTP_STATUS_BAD_GATEWAY = 502;
	public const uint32 HTTP_STATUS_SERVICE_UNAVAIL = 503;
	public const uint32 HTTP_STATUS_GATEWAY_TIMEOUT = 504;
	public const uint32 HTTP_STATUS_VERSION_NOT_SUP = 505;
	public const uint32 HTTP_STATUS_FIRST = 100;
	public const uint32 HTTP_STATUS_LAST = 505;
	public const uint32 ICU_NO_ENCODE = 536870912;
	public const uint32 ICU_NO_META = 134217728;
	public const uint32 ICU_ENCODE_SPACES_ONLY = 67108864;
	public const uint32 ICU_BROWSER_MODE = 33554432;
	public const uint32 ICU_ENCODE_PERCENT = 4096;
	public const uint32 ICU_ESCAPE_AUTHORITY = 8192;
	public const uint32 WINHTTP_ADDREQ_INDEX_MASK = 65535;
	public const uint32 WINHTTP_ADDREQ_FLAGS_MASK = 4294901760;
	public const uint32 WINHTTP_ADDREQ_FLAG_ADD_IF_NEW = 268435456;
	public const uint32 WINHTTP_ADDREQ_FLAG_ADD = 536870912;
	public const uint32 WINHTTP_ADDREQ_FLAG_COALESCE_WITH_COMMA = 1073741824;
	public const uint32 WINHTTP_ADDREQ_FLAG_COALESCE_WITH_SEMICOLON = 16777216;
	public const uint32 WINHTTP_ADDREQ_FLAG_COALESCE = 1073741824;
	public const uint32 WINHTTP_ADDREQ_FLAG_REPLACE = 2147483648;
	public const uint32 WINHTTP_EXTENDED_HEADER_FLAG_UNICODE = 1;
	public const uint32 WINHTTP_IGNORE_REQUEST_TOTAL_LENGTH = 0;
	public const uint32 WINHTTP_ERROR_BASE = 12000;
	public const uint32 ERROR_WINHTTP_OUT_OF_HANDLES = 12001;
	public const uint32 ERROR_WINHTTP_TIMEOUT = 12002;
	public const uint32 ERROR_WINHTTP_INTERNAL_ERROR = 12004;
	public const uint32 ERROR_WINHTTP_INVALID_URL = 12005;
	public const uint32 ERROR_WINHTTP_UNRECOGNIZED_SCHEME = 12006;
	public const uint32 ERROR_WINHTTP_NAME_NOT_RESOLVED = 12007;
	public const uint32 ERROR_WINHTTP_INVALID_OPTION = 12009;
	public const uint32 ERROR_WINHTTP_OPTION_NOT_SETTABLE = 12011;
	public const uint32 ERROR_WINHTTP_SHUTDOWN = 12012;
	public const uint32 ERROR_WINHTTP_LOGIN_FAILURE = 12015;
	public const uint32 ERROR_WINHTTP_OPERATION_CANCELLED = 12017;
	public const uint32 ERROR_WINHTTP_INCORRECT_HANDLE_TYPE = 12018;
	public const uint32 ERROR_WINHTTP_INCORRECT_HANDLE_STATE = 12019;
	public const uint32 ERROR_WINHTTP_CANNOT_CONNECT = 12029;
	public const uint32 ERROR_WINHTTP_CONNECTION_ERROR = 12030;
	public const uint32 ERROR_WINHTTP_RESEND_REQUEST = 12032;
	public const uint32 ERROR_WINHTTP_CLIENT_AUTH_CERT_NEEDED = 12044;
	public const uint32 ERROR_WINHTTP_CANNOT_CALL_BEFORE_OPEN = 12100;
	public const uint32 ERROR_WINHTTP_CANNOT_CALL_BEFORE_SEND = 12101;
	public const uint32 ERROR_WINHTTP_CANNOT_CALL_AFTER_SEND = 12102;
	public const uint32 ERROR_WINHTTP_CANNOT_CALL_AFTER_OPEN = 12103;
	public const uint32 ERROR_WINHTTP_HEADER_NOT_FOUND = 12150;
	public const uint32 ERROR_WINHTTP_INVALID_SERVER_RESPONSE = 12152;
	public const uint32 ERROR_WINHTTP_INVALID_HEADER = 12153;
	public const uint32 ERROR_WINHTTP_INVALID_QUERY_REQUEST = 12154;
	public const uint32 ERROR_WINHTTP_HEADER_ALREADY_EXISTS = 12155;
	public const uint32 ERROR_WINHTTP_REDIRECT_FAILED = 12156;
	public const uint32 ERROR_WINHTTP_AUTO_PROXY_SERVICE_ERROR = 12178;
	public const uint32 ERROR_WINHTTP_BAD_AUTO_PROXY_SCRIPT = 12166;
	public const uint32 ERROR_WINHTTP_UNABLE_TO_DOWNLOAD_SCRIPT = 12167;
	public const uint32 ERROR_WINHTTP_UNHANDLED_SCRIPT_TYPE = 12176;
	public const uint32 ERROR_WINHTTP_SCRIPT_EXECUTION_ERROR = 12177;
	public const uint32 ERROR_WINHTTP_NOT_INITIALIZED = 12172;
	public const uint32 ERROR_WINHTTP_SECURE_FAILURE = 12175;
	public const uint32 ERROR_WINHTTP_SECURE_CERT_DATE_INVALID = 12037;
	public const uint32 ERROR_WINHTTP_SECURE_CERT_CN_INVALID = 12038;
	public const uint32 ERROR_WINHTTP_SECURE_INVALID_CA = 12045;
	public const uint32 ERROR_WINHTTP_SECURE_CERT_REV_FAILED = 12057;
	public const uint32 ERROR_WINHTTP_SECURE_CHANNEL_ERROR = 12157;
	public const uint32 ERROR_WINHTTP_SECURE_INVALID_CERT = 12169;
	public const uint32 ERROR_WINHTTP_SECURE_CERT_REVOKED = 12170;
	public const uint32 ERROR_WINHTTP_SECURE_CERT_WRONG_USAGE = 12179;
	public const uint32 ERROR_WINHTTP_AUTODETECTION_FAILED = 12180;
	public const uint32 ERROR_WINHTTP_HEADER_COUNT_EXCEEDED = 12181;
	public const uint32 ERROR_WINHTTP_HEADER_SIZE_OVERFLOW = 12182;
	public const uint32 ERROR_WINHTTP_CHUNKED_ENCODING_HEADER_SIZE_OVERFLOW = 12183;
	public const uint32 ERROR_WINHTTP_RESPONSE_DRAIN_OVERFLOW = 12184;
	public const uint32 ERROR_WINHTTP_CLIENT_CERT_NO_PRIVATE_KEY = 12185;
	public const uint32 ERROR_WINHTTP_CLIENT_CERT_NO_ACCESS_PRIVATE_KEY = 12186;
	public const uint32 ERROR_WINHTTP_CLIENT_AUTH_CERT_NEEDED_PROXY = 12187;
	public const uint32 ERROR_WINHTTP_SECURE_FAILURE_PROXY = 12188;
	public const uint32 ERROR_WINHTTP_RESERVED_189 = 12189;
	public const uint32 ERROR_WINHTTP_HTTP_PROTOCOL_MISMATCH = 12190;
	public const uint32 ERROR_WINHTTP_GLOBAL_CALLBACK_FAILED = 12191;
	public const uint32 ERROR_WINHTTP_FEATURE_DISABLED = 12192;
	public const uint32 WINHTTP_ERROR_LAST = 12192;
	public const uint32 WINHTTP_RESET_STATE = 1;
	public const uint32 WINHTTP_RESET_SWPAD_CURRENT_NETWORK = 2;
	public const uint32 WINHTTP_RESET_SWPAD_ALL = 4;
	public const uint32 WINHTTP_RESET_SCRIPT_CACHE = 8;
	public const uint32 WINHTTP_RESET_ALL = 65535;
	public const uint32 WINHTTP_RESET_NOTIFY_NETWORK_CHANGED = 65536;
	public const uint32 WINHTTP_RESET_OUT_OF_PROC = 131072;
	public const uint32 WINHTTP_RESET_DISCARD_RESOLVERS = 262144;
	public const uint32 WINHTTP_WEB_SOCKET_MAX_CLOSE_REASON_LENGTH = 123;
	public const uint32 WINHTTP_WEB_SOCKET_MIN_KEEPALIVE_VALUE = 15000;
}
#endregion

#region Enums

[AllowDuplicates]
public enum INTERNET_PORT : uint32
{
	INTERNET_DEFAULT_HTTP_PORT = 80,
	INTERNET_DEFAULT_HTTPS_PORT = 443,
	INTERNET_DEFAULT_PORT = 0,
}


[AllowDuplicates]
public enum WINHTTP_OPEN_REQUEST_FLAGS : uint32
{
	WINHTTP_FLAG_BYPASS_PROXY_CACHE = 256,
	WINHTTP_FLAG_ESCAPE_DISABLE = 64,
	WINHTTP_FLAG_ESCAPE_DISABLE_QUERY = 128,
	WINHTTP_FLAG_ESCAPE_PERCENT = 4,
	WINHTTP_FLAG_NULL_CODEPAGE = 8,
	WINHTTP_FLAG_REFRESH = 256,
	WINHTTP_FLAG_SECURE = 8388608,
}


[AllowDuplicates]
public enum WIN_HTTP_CREATE_URL_FLAGS : uint32
{
	ICU_ESCAPE = 2147483648,
	ICU_REJECT_USERPWD = 16384,
	ICU_DECODE = 268435456,
}


[AllowDuplicates]
public enum WINHTTP_ACCESS_TYPE : uint32
{
	WINHTTP_ACCESS_TYPE_NO_PROXY = 1,
	WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0,
	WINHTTP_ACCESS_TYPE_NAMED_PROXY = 3,
	WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY = 4,
}


[AllowDuplicates]
public enum WINHTTP_CREDS_AUTHSCHEME : uint32
{
	WINHTTP_AUTH_SCHEME_BASIC = 1,
	WINHTTP_AUTH_SCHEME_NTLM = 2,
	WINHTTP_AUTH_SCHEME_NEGOTIATE = 16,
}


[AllowDuplicates]
public enum WINHTTP_INTERNET_SCHEME : uint32
{
	WINHTTP_INTERNET_SCHEME_HTTP = 1,
	WINHTTP_INTERNET_SCHEME_HTTPS = 2,
	WINHTTP_INTERNET_SCHEME_FTP = 3,
	WINHTTP_INTERNET_SCHEME_SOCKS = 4,
}


[AllowDuplicates]
public enum WINHTTP_REQUEST_TIME_ENTRY : int32
{
	WinHttpProxyDetectionStart = 0,
	WinHttpProxyDetectionEnd = 1,
	WinHttpConnectionAcquireStart = 2,
	WinHttpConnectionAcquireWaitEnd = 3,
	WinHttpConnectionAcquireEnd = 4,
	WinHttpNameResolutionStart = 5,
	WinHttpNameResolutionEnd = 6,
	WinHttpConnectionEstablishmentStart = 7,
	WinHttpConnectionEstablishmentEnd = 8,
	WinHttpTlsHandshakeClientLeg1Start = 9,
	WinHttpTlsHandshakeClientLeg1End = 10,
	WinHttpTlsHandshakeClientLeg2Start = 11,
	WinHttpTlsHandshakeClientLeg2End = 12,
	WinHttpTlsHandshakeClientLeg3Start = 13,
	WinHttpTlsHandshakeClientLeg3End = 14,
	WinHttpStreamWaitStart = 15,
	WinHttpStreamWaitEnd = 16,
	WinHttpSendRequestStart = 17,
	WinHttpSendRequestHeadersCompressionStart = 18,
	WinHttpSendRequestHeadersCompressionEnd = 19,
	WinHttpSendRequestHeadersEnd = 20,
	WinHttpSendRequestEnd = 21,
	WinHttpReceiveResponseStart = 22,
	WinHttpReceiveResponseHeadersDecompressionStart = 23,
	WinHttpReceiveResponseHeadersDecompressionEnd = 24,
	WinHttpReceiveResponseHeadersEnd = 25,
	WinHttpReceiveResponseBodyDecompressionDelta = 26,
	WinHttpReceiveResponseEnd = 27,
	WinHttpProxyTunnelStart = 28,
	WinHttpProxyTunnelEnd = 29,
	WinHttpProxyTlsHandshakeClientLeg1Start = 30,
	WinHttpProxyTlsHandshakeClientLeg1End = 31,
	WinHttpProxyTlsHandshakeClientLeg2Start = 32,
	WinHttpProxyTlsHandshakeClientLeg2End = 33,
	WinHttpProxyTlsHandshakeClientLeg3Start = 34,
	WinHttpProxyTlsHandshakeClientLeg3End = 35,
	WinHttpRequestTimeLast = 36,
	WinHttpRequestTimeMax = 64,
}


[AllowDuplicates]
public enum WINHTTP_REQUEST_STAT_ENTRY : int32
{
	WinHttpConnectFailureCount = 0,
	WinHttpProxyFailureCount = 1,
	WinHttpTlsHandshakeClientLeg1Size = 2,
	WinHttpTlsHandshakeServerLeg1Size = 3,
	WinHttpTlsHandshakeClientLeg2Size = 4,
	WinHttpTlsHandshakeServerLeg2Size = 5,
	WinHttpRequestHeadersSize = 6,
	WinHttpRequestHeadersCompressedSize = 7,
	WinHttpResponseHeadersSize = 8,
	WinHttpResponseHeadersCompressedSize = 9,
	WinHttpResponseBodySize = 10,
	WinHttpResponseBodyCompressedSize = 11,
	WinHttpProxyTlsHandshakeClientLeg1Size = 12,
	WinHttpProxyTlsHandshakeServerLeg1Size = 13,
	WinHttpProxyTlsHandshakeClientLeg2Size = 14,
	WinHttpProxyTlsHandshakeServerLeg2Size = 15,
	WinHttpRequestStatLast = 16,
	WinHttpRequestStatMax = 32,
}


[AllowDuplicates]
public enum WINHTTP_SECURE_DNS_SETTING : int32
{
	WinHttpSecureDnsSettingDefault = 0,
	WinHttpSecureDnsSettingForcePlaintext = 1,
	WinHttpSecureDnsSettingRequireEncryption = 2,
	WinHttpSecureDnsSettingTryEncryptionWithFallback = 3,
	WinHttpSecureDnsSettingMax = 4,
}


[AllowDuplicates]
public enum WINHTTP_WEB_SOCKET_OPERATION : int32
{
	WINHTTP_WEB_SOCKET_SEND_OPERATION = 0,
	WINHTTP_WEB_SOCKET_RECEIVE_OPERATION = 1,
	WINHTTP_WEB_SOCKET_CLOSE_OPERATION = 2,
	WINHTTP_WEB_SOCKET_SHUTDOWN_OPERATION = 3,
}


[AllowDuplicates]
public enum WINHTTP_WEB_SOCKET_BUFFER_TYPE : int32
{
	WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE = 0,
	WINHTTP_WEB_SOCKET_BINARY_FRAGMENT_BUFFER_TYPE = 1,
	WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE = 2,
	WINHTTP_WEB_SOCKET_UTF8_FRAGMENT_BUFFER_TYPE = 3,
	WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE = 4,
}


[AllowDuplicates]
public enum WINHTTP_WEB_SOCKET_CLOSE_STATUS : int32
{
	WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS = 1000,
	WINHTTP_WEB_SOCKET_ENDPOINT_TERMINATED_CLOSE_STATUS = 1001,
	WINHTTP_WEB_SOCKET_PROTOCOL_ERROR_CLOSE_STATUS = 1002,
	WINHTTP_WEB_SOCKET_INVALID_DATA_TYPE_CLOSE_STATUS = 1003,
	WINHTTP_WEB_SOCKET_EMPTY_CLOSE_STATUS = 1005,
	WINHTTP_WEB_SOCKET_ABORTED_CLOSE_STATUS = 1006,
	WINHTTP_WEB_SOCKET_INVALID_PAYLOAD_CLOSE_STATUS = 1007,
	WINHTTP_WEB_SOCKET_POLICY_VIOLATION_CLOSE_STATUS = 1008,
	WINHTTP_WEB_SOCKET_MESSAGE_TOO_BIG_CLOSE_STATUS = 1009,
	WINHTTP_WEB_SOCKET_UNSUPPORTED_EXTENSIONS_CLOSE_STATUS = 1010,
	WINHTTP_WEB_SOCKET_SERVER_ERROR_CLOSE_STATUS = 1011,
	WINHTTP_WEB_SOCKET_SECURE_HANDSHAKE_ERROR_CLOSE_STATUS = 1015,
}

#endregion

#region Function Pointers
public function void WINHTTP_STATUS_CALLBACK(void* hInternet, uint dwContext, uint32 dwInternetStatus, void* lpvStatusInformation, uint32 dwStatusInformationLength);

#endregion

#region Structs
#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct WINHTTP_CONNECTION_INFO
{
	public uint32 cbSize;
	public SOCKADDR_STORAGE LocalAddress;
	public SOCKADDR_STORAGE RemoteAddress;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct WINHTTP_REQUEST_TIMES
{
	public uint32 cTimes;
	public uint64[64] rgullTimes;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct WINHTTP_REQUEST_STATS
{
	public uint64 ullFlags;
	public uint32 ulIndex;
	public uint32 cStats;
	public uint64[32] rgullStats;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct WINHTTP_MATCH_CONNECTION_GUID
{
	public Guid ConnectionGuid;
	public uint64 ullFlags;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct WINHTTP_RESOLVER_CACHE_CONFIG
{
	public uint32 ulMaxResolverCacheEntries;
	public uint32 ulMaxCacheEntryAge;
	public uint32 ulMinCacheEntryTtl;
	public WINHTTP_SECURE_DNS_SETTING SecureDnsSetting;
	public uint64 ullConnResolutionWaitTime;
	public uint64 ullFlags;
}
#endif

[CRepr]
public struct WINHTTP_ASYNC_RESULT
{
	public uint dwResult;
	public uint32 dwError;
}

[CRepr]
public struct HTTP_VERSION_INFO
{
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
}

[CRepr]
public struct URL_COMPONENTS
{
	public uint32 dwStructSize;
	public PWSTR lpszScheme;
	public uint32 dwSchemeLength;
	public WINHTTP_INTERNET_SCHEME nScheme;
	public PWSTR lpszHostName;
	public uint32 dwHostNameLength;
	public uint16 nPort;
	public PWSTR lpszUserName;
	public uint32 dwUserNameLength;
	public PWSTR lpszPassword;
	public uint32 dwPasswordLength;
	public PWSTR lpszUrlPath;
	public uint32 dwUrlPathLength;
	public PWSTR lpszExtraInfo;
	public uint32 dwExtraInfoLength;
}

[CRepr]
public struct WINHTTP_PROXY_INFO
{
	public WINHTTP_ACCESS_TYPE dwAccessType;
	public PWSTR lpszProxy;
	public PWSTR lpszProxyBypass;
}

[CRepr]
public struct WINHTTP_AUTOPROXY_OPTIONS
{
	public uint32 dwFlags;
	public uint32 dwAutoDetectFlags;
	public PWSTR lpszAutoConfigUrl;
	public void* lpvReserved;
	public uint32 dwReserved;
	public BOOL fAutoLogonIfChallenged;
}

[CRepr]
public struct WINHTTP_PROXY_RESULT_ENTRY
{
	public BOOL fProxy;
	public BOOL fBypass;
	public WINHTTP_INTERNET_SCHEME ProxyScheme;
	public PWSTR pwszProxy;
	public uint16 ProxyPort;
}

[CRepr]
public struct WINHTTP_PROXY_RESULT
{
	public uint32 cEntries;
	public WINHTTP_PROXY_RESULT_ENTRY* pEntries;
}

[CRepr]
public struct WINHTTP_PROXY_RESULT_EX
{
	public uint32 cEntries;
	public WINHTTP_PROXY_RESULT_ENTRY* pEntries;
	public HANDLE hProxyDetectionHandle;
	public uint32 dwProxyInterfaceAffinity;
}

[CRepr]
public struct WINHTTP_PROXY_NETWORKING_KEY
{
	public uint8[128] pbBuffer;
}

[CRepr]
public struct WINHTTP_PROXY_SETTINGS
{
	public uint32 dwStructSize;
	public uint32 dwFlags;
	public uint32 dwCurrentSettingsVersion;
	public PWSTR pwszConnectionName;
	public PWSTR pwszProxy;
	public PWSTR pwszProxyBypass;
	public PWSTR pwszAutoconfigUrl;
	public PWSTR pwszAutoconfigSecondaryUrl;
	public uint32 dwAutoDiscoveryFlags;
	public PWSTR pwszLastKnownGoodAutoConfigUrl;
	public uint32 dwAutoconfigReloadDelayMins;
	public FILETIME ftLastKnownDetectTime;
	public uint32 dwDetectedInterfaceIpCount;
	public uint32* pdwDetectedInterfaceIp;
	public uint32 cNetworkKeys;
	public WINHTTP_PROXY_NETWORKING_KEY* pNetworkKeys;
}

[CRepr]
public struct WINHTTP_CERTIFICATE_INFO
{
	public FILETIME ftExpiry;
	public FILETIME ftStart;
	public PWSTR lpszSubjectInfo;
	public PWSTR lpszIssuerInfo;
	public PWSTR lpszProtocolName;
	public PWSTR lpszSignatureAlgName;
	public PWSTR lpszEncryptionAlgName;
	public uint32 dwKeySize;
}

#if BF_32_BIT
[CRepr, Packed(4)]
public struct WINHTTP_CONNECTION_INFO
{
	public uint32 cbSize;
	public SOCKADDR_STORAGE LocalAddress;
	public SOCKADDR_STORAGE RemoteAddress;
}
#endif

#if BF_32_BIT
[CRepr, Packed(4)]
public struct WINHTTP_REQUEST_TIMES
{
	public uint32 cTimes;
	public uint64[64] rgullTimes;
}
#endif

#if BF_32_BIT
[CRepr, Packed(4)]
public struct WINHTTP_REQUEST_STATS
{
	public uint64 ullFlags;
	public uint32 ulIndex;
	public uint32 cStats;
	public uint64[32] rgullStats;
}
#endif

#if BF_32_BIT
[CRepr, Packed(4)]
public struct WINHTTP_MATCH_CONNECTION_GUID
{
	public Guid ConnectionGuid;
	public uint64 ullFlags;
}
#endif

[CRepr]
public struct WINHTTP_EXTENDED_HEADER
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PWSTR pwszName;
		public PSTR pszName;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public PWSTR pwszValue;
		public PSTR pszValue;
	}
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr, Union]
public struct WINHTTP_HEADER_NAME
{
	public PWSTR pwszName;
	public PSTR pszName;
}

#if BF_32_BIT
[CRepr, Packed(4)]
public struct WINHTTP_RESOLVER_CACHE_CONFIG
{
	public uint32 ulMaxResolverCacheEntries;
	public uint32 ulMaxCacheEntryAge;
	public uint32 ulMinCacheEntryTtl;
	public WINHTTP_SECURE_DNS_SETTING SecureDnsSetting;
	public uint64 ullConnResolutionWaitTime;
	public uint64 ullFlags;
}
#endif

[CRepr]
public struct WINHTTP_CONNECTION_GROUP
{
	public uint32 cConnections;
	public Guid guidGroup;
}

[CRepr]
public struct WINHTTP_HOST_CONNECTION_GROUP
{
	public PWSTR pwszHost;
	public uint32 cConnectionGroups;
	public WINHTTP_CONNECTION_GROUP* pConnectionGroups;
}

[CRepr]
public struct WINHTTP_QUERY_CONNECTION_GROUP_RESULT
{
	public uint32 cHosts;
	public WINHTTP_HOST_CONNECTION_GROUP* pHostConnectionGroups;
}

[CRepr]
public struct WINHTTP_HTTP2_RECEIVE_WINDOW
{
	public uint32 ulStreamWindow;
	public uint32 ulStreamWindowUpdateDelta;
}

[CRepr]
public struct WINHTTP_FAILED_CONNECTION_RETRIES
{
	public uint32 dwMaxRetries;
	public uint32 dwAllowedRetryConditions;
}

[CRepr]
public struct WINHTTP_CREDS
{
	public PSTR lpszUserName;
	public PSTR lpszPassword;
	public PSTR lpszRealm;
	public WINHTTP_CREDS_AUTHSCHEME dwAuthScheme;
	public PSTR lpszHostName;
	public uint32 dwPort;
}

[CRepr]
public struct WINHTTP_CREDS_EX
{
	public PSTR lpszUserName;
	public PSTR lpszPassword;
	public PSTR lpszRealm;
	public WINHTTP_CREDS_AUTHSCHEME dwAuthScheme;
	public PSTR lpszHostName;
	public uint32 dwPort;
	public PSTR lpszUrl;
}

[CRepr]
public struct WINHTTP_CURRENT_USER_IE_PROXY_CONFIG
{
	public BOOL fAutoDetect;
	public PWSTR lpszAutoConfigUrl;
	public PWSTR lpszProxy;
	public PWSTR lpszProxyBypass;
}

[CRepr]
public struct WINHTTP_WEB_SOCKET_ASYNC_RESULT
{
	public WINHTTP_ASYNC_RESULT AsyncResult;
	public WINHTTP_WEB_SOCKET_OPERATION Operation;
}

[CRepr]
public struct WINHTTP_WEB_SOCKET_STATUS
{
	public uint32 dwBytesTransferred;
	public WINHTTP_WEB_SOCKET_BUFFER_TYPE eBufferType;
}

#endregion

#region Functions
public static
{
	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WINHTTP_STATUS_CALLBACK WinHttpSetStatusCallback(void* hInternet, WINHTTP_STATUS_CALLBACK lpfnInternetCallback, uint32 dwNotificationFlags, uint dwReserved);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpTimeFromSystemTime(SYSTEMTIME* pst, char16* pwszTime);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpTimeToSystemTime(PWSTR pwszTime, SYSTEMTIME* pst);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpCrackUrl(char16* pwszUrl, uint32 dwUrlLength, uint32 dwFlags, URL_COMPONENTS* lpUrlComponents);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpCreateUrl(URL_COMPONENTS* lpUrlComponents, WIN_HTTP_CREATE_URL_FLAGS dwFlags, char16* pwszUrl, uint32* pdwUrlLength);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpCheckPlatform();

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpGetDefaultProxyConfiguration(WINHTTP_PROXY_INFO* pProxyInfo);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpSetDefaultProxyConfiguration(WINHTTP_PROXY_INFO* pProxyInfo);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* WinHttpOpen(PWSTR pszAgentW, WINHTTP_ACCESS_TYPE dwAccessType, PWSTR pszProxyW, PWSTR pszProxyBypassW, uint32 dwFlags);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpCloseHandle(void* hInternet);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* WinHttpConnect(void* hSession, PWSTR pswzServerName, INTERNET_PORT nServerPort, uint32 dwReserved);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpReadData(void* hRequest, void* lpBuffer, uint32 dwNumberOfBytesToRead, uint32* lpdwNumberOfBytesRead);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpReadDataEx(void* hRequest, void* lpBuffer, uint32 dwNumberOfBytesToRead, uint32* lpdwNumberOfBytesRead, uint64 ullFlags, uint32 cbProperty, void* pvProperty);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpWriteData(void* hRequest, void* lpBuffer, uint32 dwNumberOfBytesToWrite, uint32* lpdwNumberOfBytesWritten);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpQueryDataAvailable(void* hRequest, uint32* lpdwNumberOfBytesAvailable);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpQueryOption(void* hInternet, uint32 dwOption, void* lpBuffer, uint32* lpdwBufferLength);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpSetOption(void* hInternet, uint32 dwOption, void* lpBuffer, uint32 dwBufferLength);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpSetTimeouts(void* hInternet, int32 nResolveTimeout, int32 nConnectTimeout, int32 nSendTimeout, int32 nReceiveTimeout);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* WinHttpOpenRequest(void* hConnect, PWSTR pwszVerb, PWSTR pwszObjectName, PWSTR pwszVersion, PWSTR pwszReferrer, PWSTR* ppwszAcceptTypes, WINHTTP_OPEN_REQUEST_FLAGS dwFlags);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpAddRequestHeaders(void* hRequest, char16* lpszHeaders, uint32 dwHeadersLength, uint32 dwModifiers);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpAddRequestHeadersEx(void* hRequest, uint32 dwModifiers, uint64 ullFlags, uint64 ullExtra, uint32 cHeaders, WINHTTP_EXTENDED_HEADER* pHeaders);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpSendRequest(void* hRequest, char16* lpszHeaders, uint32 dwHeadersLength, void* lpOptional, uint32 dwOptionalLength, uint32 dwTotalLength, uint dwContext);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpSetCredentials(void* hRequest, uint32 AuthTargets, uint32 AuthScheme, PWSTR pwszUserName, PWSTR pwszPassword, void* pAuthParams);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpQueryAuthSchemes(void* hRequest, uint32* lpdwSupportedSchemes, uint32* lpdwFirstScheme, uint32* pdwAuthTarget);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpReceiveResponse(void* hRequest, void* lpReserved);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpQueryHeaders(void* hRequest, uint32 dwInfoLevel, PWSTR pwszName, void* lpBuffer, uint32* lpdwBufferLength, uint32* lpdwIndex);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpQueryHeadersEx(void* hRequest, uint32 dwInfoLevel, uint64 ullFlags, uint32 uiCodePage, uint32* pdwIndex, WINHTTP_HEADER_NAME* pHeaderName, void* pBuffer, uint32* pdwBufferLength, WINHTTP_EXTENDED_HEADER** ppHeaders, uint32* pdwHeadersCount);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpQueryConnectionGroup(void* hInternet, Guid* pGuidConnection, uint64 ullFlags, WINHTTP_QUERY_CONNECTION_GROUP_RESULT** ppResult);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WinHttpFreeQueryConnectionGroupResult(WINHTTP_QUERY_CONNECTION_GROUP_RESULT* pResult);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpDetectAutoProxyConfigUrl(uint32 dwAutoDetectFlags, PWSTR* ppwstrAutoConfigUrl);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpGetProxyForUrl(void* hSession, PWSTR lpcwszUrl, WINHTTP_AUTOPROXY_OPTIONS* pAutoProxyOptions, WINHTTP_PROXY_INFO* pProxyInfo);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpCreateProxyResolver(void* hSession, void** phResolver);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpGetProxyForUrlEx(void* hResolver, PWSTR pcwszUrl, WINHTTP_AUTOPROXY_OPTIONS* pAutoProxyOptions, uint pContext);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpGetProxyForUrlEx2(void* hResolver, PWSTR pcwszUrl, WINHTTP_AUTOPROXY_OPTIONS* pAutoProxyOptions, uint32 cbInterfaceSelectionContext, uint8* pInterfaceSelectionContext, uint pContext);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpGetProxyResult(void* hResolver, WINHTTP_PROXY_RESULT* pProxyResult);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpGetProxyResultEx(void* hResolver, WINHTTP_PROXY_RESULT_EX* pProxyResultEx);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WinHttpFreeProxyResult(WINHTTP_PROXY_RESULT* pProxyResult);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WinHttpFreeProxyResultEx(WINHTTP_PROXY_RESULT_EX* pProxyResultEx);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpResetAutoProxy(void* hSession, uint32 dwFlags);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHttpGetIEProxyConfigForCurrentUser(WINHTTP_CURRENT_USER_IE_PROXY_CONFIG* pProxyConfig);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpWriteProxySettings(void* hSession, BOOL fForceUpdate, WINHTTP_PROXY_SETTINGS* pWinHttpProxySettings);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpReadProxySettings(void* hSession, PWSTR pcwszConnectionName, BOOL fFallBackToDefaultSettings, BOOL fSetAutoDiscoverForDefaultSettings, uint32* pdwSettingsVersion, BOOL* pfDefaultSettingsAreReturned, WINHTTP_PROXY_SETTINGS* pWinHttpProxySettings);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WinHttpFreeProxySettings(WINHTTP_PROXY_SETTINGS* pWinHttpProxySettings);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpGetProxySettingsVersion(void* hSession, uint32* pdwProxySettingsVersion);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpSetProxySettingsPerUser(BOOL fProxySettingsPerUser);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* WinHttpWebSocketCompleteUpgrade(void* hRequest, uint pContext);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpWebSocketSend(void* hWebSocket, WINHTTP_WEB_SOCKET_BUFFER_TYPE eBufferType, void* pvBuffer, uint32 dwBufferLength);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpWebSocketReceive(void* hWebSocket, void* pvBuffer, uint32 dwBufferLength, uint32* pdwBytesRead, WINHTTP_WEB_SOCKET_BUFFER_TYPE* peBufferType);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpWebSocketShutdown(void* hWebSocket, uint16 usStatus, void* pvReason, uint32 dwReasonLength);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpWebSocketClose(void* hWebSocket, uint16 usStatus, void* pvReason, uint32 dwReasonLength);

	[Import("WINHTTP.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WinHttpWebSocketQueryCloseStatus(void* hWebSocket, uint16* pusStatus, void* pvReason, uint32 dwReasonLength, uint32* pdwReasonLengthConsumed);

}
#endregion
