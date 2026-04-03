using Win32.Foundation;
using Win32.Security;
using System;

namespace Win32.Devices.AllJoyn;

#region Constants
public static
{
	public const uint32 QCC_TRUE = 1;
	public const uint32 QCC_FALSE = 0;
	public const uint32 ALLJOYN_MESSAGE_FLAG_NO_REPLY_EXPECTED = 1;
	public const uint32 ALLJOYN_MESSAGE_FLAG_AUTO_START = 2;
	public const uint32 ALLJOYN_MESSAGE_FLAG_ALLOW_REMOTE_MSG = 4;
	public const uint32 ALLJOYN_MESSAGE_FLAG_SESSIONLESS = 16;
	public const uint32 ALLJOYN_MESSAGE_FLAG_GLOBAL_BROADCAST = 32;
	public const uint32 ALLJOYN_MESSAGE_FLAG_ENCRYPTED = 128;
	public const uint32 ALLJOYN_TRAFFIC_TYPE_MESSAGES = 1;
	public const uint32 ALLJOYN_TRAFFIC_TYPE_RAW_UNRELIABLE = 2;
	public const uint32 ALLJOYN_TRAFFIC_TYPE_RAW_RELIABLE = 4;
	public const uint32 ALLJOYN_PROXIMITY_ANY = 255;
	public const uint32 ALLJOYN_PROXIMITY_PHYSICAL = 1;
	public const uint32 ALLJOYN_PROXIMITY_NETWORK = 2;
	public const String ALLJOYN_NAMED_PIPE_CONNECT_SPEC = "npipe:";
	public const uint32 ALLJOYN_READ_READY = 1;
	public const uint32 ALLJOYN_WRITE_READY = 2;
	public const uint32 ALLJOYN_DISCONNECTED = 4;
	public const uint8 ALLJOYN_LITTLE_ENDIAN = 108;
	public const uint8 ALLJOYN_BIG_ENDIAN = 66;
	public const uint32 ALLJOYN_MESSAGE_DEFAULT_TIMEOUT = 25000;
	public const uint16 ALLJOYN_CRED_PASSWORD = 1;
	public const uint16 ALLJOYN_CRED_USER_NAME = 2;
	public const uint16 ALLJOYN_CRED_CERT_CHAIN = 4;
	public const uint16 ALLJOYN_CRED_PRIVATE_KEY = 8;
	public const uint16 ALLJOYN_CRED_LOGON_ENTRY = 16;
	public const uint16 ALLJOYN_CRED_EXPIRATION = 32;
	public const uint16 ALLJOYN_CRED_NEW_PASSWORD = 4097;
	public const uint16 ALLJOYN_CRED_ONE_TIME_PWD = 8193;
	public const uint8 ALLJOYN_PROP_ACCESS_READ = 1;
	public const uint8 ALLJOYN_PROP_ACCESS_WRITE = 2;
	public const uint8 ALLJOYN_PROP_ACCESS_RW = 3;
	public const uint8 ALLJOYN_MEMBER_ANNOTATE_NO_REPLY = 1;
	public const uint8 ALLJOYN_MEMBER_ANNOTATE_DEPRECATED = 2;
	public const uint8 ALLJOYN_MEMBER_ANNOTATE_SESSIONCAST = 4;
	public const uint8 ALLJOYN_MEMBER_ANNOTATE_SESSIONLESS = 8;
	public const uint8 ALLJOYN_MEMBER_ANNOTATE_UNICAST = 16;
	public const uint8 ALLJOYN_MEMBER_ANNOTATE_GLOBAL_BROADCAST = 32;
}
#endregion

#region TypeDefs
typealias alljoyn_aboutdata = int;

typealias alljoyn_aboutdatalistener = int;

typealias alljoyn_aboutlistener = int;

typealias alljoyn_aboutobj = int;

typealias alljoyn_aboutobjectdescription = int;

typealias alljoyn_aboutproxy = int;

typealias alljoyn_applicationstatelistener = int;

typealias alljoyn_authlistener = int;

typealias alljoyn_autopinger = int;

typealias alljoyn_busattachment = int;

typealias alljoyn_buslistener = int;

typealias alljoyn_busobject = int;

typealias alljoyn_credentials = int;

typealias alljoyn_interfacedescription = int;

typealias alljoyn_keystore = int;

typealias alljoyn_keystorelistener = int;

typealias alljoyn_message = int;

typealias alljoyn_msgarg = int;

typealias alljoyn_observer = int;

typealias alljoyn_observerlistener = int;

typealias alljoyn_permissionconfigurationlistener = int;

typealias alljoyn_permissionconfigurator = int;

typealias alljoyn_pinglistener = int;

typealias alljoyn_proxybusobject = int;

typealias alljoyn_proxybusobject_ref = int;

typealias alljoyn_securityapplicationproxy = int;

typealias alljoyn_sessionlistener = int;

typealias alljoyn_sessionopts = int;

typealias alljoyn_sessionportlistener = int;

#endregion


#region Enums

[AllowDuplicates]
public enum alljoyn_about_announceflag : int32
{
	UNANNOUNCED = 0,
	ANNOUNCED = 1,
}


[AllowDuplicates]
public enum QStatus : int32
{
	ER_OK = 0,
	ER_FAIL = 1,
	ER_UTF_CONVERSION_FAILED = 2,
	ER_BUFFER_TOO_SMALL = 3,
	ER_OS_ERROR = 4,
	ER_OUT_OF_MEMORY = 5,
	ER_SOCKET_BIND_ERROR = 6,
	ER_INIT_FAILED = 7,
	ER_WOULDBLOCK = 8,
	ER_NOT_IMPLEMENTED = 9,
	ER_TIMEOUT = 10,
	ER_SOCK_OTHER_END_CLOSED = 11,
	ER_BAD_ARG_1 = 12,
	ER_BAD_ARG_2 = 13,
	ER_BAD_ARG_3 = 14,
	ER_BAD_ARG_4 = 15,
	ER_BAD_ARG_5 = 16,
	ER_BAD_ARG_6 = 17,
	ER_BAD_ARG_7 = 18,
	ER_BAD_ARG_8 = 19,
	ER_INVALID_ADDRESS = 20,
	ER_INVALID_DATA = 21,
	ER_READ_ERROR = 22,
	ER_WRITE_ERROR = 23,
	ER_OPEN_FAILED = 24,
	ER_PARSE_ERROR = 25,
	ER_END_OF_DATA = 26,
	ER_CONN_REFUSED = 27,
	ER_BAD_ARG_COUNT = 28,
	ER_WARNING = 29,
	ER_EOF = 30,
	ER_DEADLOCK = 31,
	ER_COMMON_ERRORS = 4096,
	ER_STOPPING_THREAD = 4097,
	ER_ALERTED_THREAD = 4098,
	ER_XML_MALFORMED = 4099,
	ER_AUTH_FAIL = 4100,
	ER_AUTH_USER_REJECT = 4101,
	ER_NO_SUCH_ALARM = 4102,
	ER_TIMER_FALLBEHIND = 4103,
	ER_SSL_ERRORS = 4104,
	ER_SSL_INIT = 4105,
	ER_SSL_CONNECT = 4106,
	ER_SSL_VERIFY = 4107,
	ER_EXTERNAL_THREAD = 4108,
	ER_CRYPTO_ERROR = 4109,
	ER_CRYPTO_TRUNCATED = 4110,
	ER_CRYPTO_KEY_UNAVAILABLE = 4111,
	ER_BAD_HOSTNAME = 4112,
	ER_CRYPTO_KEY_UNUSABLE = 4113,
	ER_EMPTY_KEY_BLOB = 4114,
	ER_CORRUPT_KEYBLOB = 4115,
	ER_INVALID_KEY_ENCODING = 4116,
	ER_DEAD_THREAD = 4117,
	ER_THREAD_RUNNING = 4118,
	ER_THREAD_STOPPING = 4119,
	ER_BAD_STRING_ENCODING = 4120,
	ER_CRYPTO_INSUFFICIENT_SECURITY = 4121,
	ER_CRYPTO_ILLEGAL_PARAMETERS = 4122,
	ER_CRYPTO_HASH_UNINITIALIZED = 4123,
	ER_THREAD_NO_WAIT = 4124,
	ER_TIMER_EXITING = 4125,
	ER_INVALID_GUID = 4126,
	ER_THREADPOOL_EXHAUSTED = 4127,
	ER_THREADPOOL_STOPPING = 4128,
	ER_INVALID_STREAM = 4129,
	ER_TIMER_FULL = 4130,
	ER_IODISPATCH_STOPPING = 4131,
	ER_SLAP_INVALID_PACKET_LEN = 4132,
	ER_SLAP_HDR_CHECKSUM_ERROR = 4133,
	ER_SLAP_INVALID_PACKET_TYPE = 4134,
	ER_SLAP_LEN_MISMATCH = 4135,
	ER_SLAP_PACKET_TYPE_MISMATCH = 4136,
	ER_SLAP_CRC_ERROR = 4137,
	ER_SLAP_ERROR = 4138,
	ER_SLAP_OTHER_END_CLOSED = 4139,
	ER_TIMER_NOT_ALLOWED = 4140,
	ER_NOT_CONN = 4141,
	ER_XML_CONVERTER_ERROR = 8192,
	ER_XML_INVALID_RULES_COUNT = 8193,
	ER_XML_INTERFACE_MEMBERS_MISSING = 8194,
	ER_XML_INVALID_MEMBER_TYPE = 8195,
	ER_XML_INVALID_MEMBER_ACTION = 8196,
	ER_XML_MEMBER_DENY_ACTION_WITH_OTHER = 8197,
	ER_XML_INVALID_ANNOTATIONS_COUNT = 8198,
	ER_XML_INVALID_ELEMENT_NAME = 8199,
	ER_XML_INVALID_ATTRIBUTE_VALUE = 8200,
	ER_XML_INVALID_SECURITY_LEVEL_ANNOTATION_VALUE = 8201,
	ER_XML_INVALID_ELEMENT_CHILDREN_COUNT = 8202,
	ER_XML_INVALID_POLICY_VERSION = 8203,
	ER_XML_INVALID_POLICY_SERIAL_NUMBER = 8204,
	ER_XML_INVALID_ACL_PEER_TYPE = 8205,
	ER_XML_INVALID_ACL_PEER_CHILDREN_COUNT = 8206,
	ER_XML_ACL_ALL_TYPE_PEER_WITH_OTHERS = 8207,
	ER_XML_INVALID_ACL_PEER_PUBLIC_KEY = 8208,
	ER_XML_ACL_PEER_NOT_UNIQUE = 8209,
	ER_XML_ACL_PEER_PUBLIC_KEY_SET = 8210,
	ER_XML_ACLS_MISSING = 8211,
	ER_XML_ACL_PEERS_MISSING = 8212,
	ER_XML_INVALID_OBJECT_PATH = 8213,
	ER_XML_INVALID_INTERFACE_NAME = 8214,
	ER_XML_INVALID_MEMBER_NAME = 8215,
	ER_XML_INVALID_MANIFEST_VERSION = 8216,
	ER_XML_INVALID_OID = 8217,
	ER_XML_INVALID_BASE64 = 8218,
	ER_XML_INTERFACE_NAME_NOT_UNIQUE = 8219,
	ER_XML_MEMBER_NAME_NOT_UNIQUE = 8220,
	ER_XML_OBJECT_PATH_NOT_UNIQUE = 8221,
	ER_XML_ANNOTATION_NOT_UNIQUE = 8222,
	ER_NONE = 65535,
	ER_BUS_ERRORS = 36864,
	ER_BUS_READ_ERROR = 36865,
	ER_BUS_WRITE_ERROR = 36866,
	ER_BUS_BAD_VALUE_TYPE = 36867,
	ER_BUS_BAD_HEADER_FIELD = 36868,
	ER_BUS_BAD_SIGNATURE = 36869,
	ER_BUS_BAD_OBJ_PATH = 36870,
	ER_BUS_BAD_MEMBER_NAME = 36871,
	ER_BUS_BAD_INTERFACE_NAME = 36872,
	ER_BUS_BAD_ERROR_NAME = 36873,
	ER_BUS_BAD_BUS_NAME = 36874,
	ER_BUS_NAME_TOO_LONG = 36875,
	ER_BUS_BAD_LENGTH = 36876,
	ER_BUS_BAD_VALUE = 36877,
	ER_BUS_BAD_HDR_FLAGS = 36878,
	ER_BUS_BAD_BODY_LEN = 36879,
	ER_BUS_BAD_HEADER_LEN = 36880,
	ER_BUS_UNKNOWN_SERIAL = 36881,
	ER_BUS_UNKNOWN_PATH = 36882,
	ER_BUS_UNKNOWN_INTERFACE = 36883,
	ER_BUS_ESTABLISH_FAILED = 36884,
	ER_BUS_UNEXPECTED_SIGNATURE = 36885,
	ER_BUS_INTERFACE_MISSING = 36886,
	ER_BUS_PATH_MISSING = 36887,
	ER_BUS_MEMBER_MISSING = 36888,
	ER_BUS_REPLY_SERIAL_MISSING = 36889,
	ER_BUS_ERROR_NAME_MISSING = 36890,
	ER_BUS_INTERFACE_NO_SUCH_MEMBER = 36891,
	ER_BUS_NO_SUCH_OBJECT = 36892,
	ER_BUS_OBJECT_NO_SUCH_MEMBER = 36893,
	ER_BUS_OBJECT_NO_SUCH_INTERFACE = 36894,
	ER_BUS_NO_SUCH_INTERFACE = 36895,
	ER_BUS_MEMBER_NO_SUCH_SIGNATURE = 36896,
	ER_BUS_NOT_NUL_TERMINATED = 36897,
	ER_BUS_NO_SUCH_PROPERTY = 36898,
	ER_BUS_SET_WRONG_SIGNATURE = 36899,
	ER_BUS_PROPERTY_VALUE_NOT_SET = 36900,
	ER_BUS_PROPERTY_ACCESS_DENIED = 36901,
	ER_BUS_NO_TRANSPORTS = 36902,
	ER_BUS_BAD_TRANSPORT_ARGS = 36903,
	ER_BUS_NO_ROUTE = 36904,
	ER_BUS_NO_ENDPOINT = 36905,
	ER_BUS_BAD_SEND_PARAMETER = 36906,
	ER_BUS_UNMATCHED_REPLY_SERIAL = 36907,
	ER_BUS_BAD_SENDER_ID = 36908,
	ER_BUS_TRANSPORT_NOT_STARTED = 36909,
	ER_BUS_EMPTY_MESSAGE = 36910,
	ER_BUS_NOT_OWNER = 36911,
	ER_BUS_SET_PROPERTY_REJECTED = 36912,
	ER_BUS_CONNECT_FAILED = 36913,
	ER_BUS_REPLY_IS_ERROR_MESSAGE = 36914,
	ER_BUS_NOT_AUTHENTICATING = 36915,
	ER_BUS_NO_LISTENER = 36916,
	ER_BUS_NOT_ALLOWED = 36918,
	ER_BUS_WRITE_QUEUE_FULL = 36919,
	ER_BUS_ENDPOINT_CLOSING = 36920,
	ER_BUS_INTERFACE_MISMATCH = 36921,
	ER_BUS_MEMBER_ALREADY_EXISTS = 36922,
	ER_BUS_PROPERTY_ALREADY_EXISTS = 36923,
	ER_BUS_IFACE_ALREADY_EXISTS = 36924,
	ER_BUS_ERROR_RESPONSE = 36925,
	ER_BUS_BAD_XML = 36926,
	ER_BUS_BAD_CHILD_PATH = 36927,
	ER_BUS_OBJ_ALREADY_EXISTS = 36928,
	ER_BUS_OBJ_NOT_FOUND = 36929,
	ER_BUS_CANNOT_EXPAND_MESSAGE = 36930,
	ER_BUS_NOT_COMPRESSED = 36931,
	ER_BUS_ALREADY_CONNECTED = 36932,
	ER_BUS_NOT_CONNECTED = 36933,
	ER_BUS_ALREADY_LISTENING = 36934,
	ER_BUS_KEY_UNAVAILABLE = 36935,
	ER_BUS_TRUNCATED = 36936,
	ER_BUS_KEY_STORE_NOT_LOADED = 36937,
	ER_BUS_NO_AUTHENTICATION_MECHANISM = 36938,
	ER_BUS_BUS_ALREADY_STARTED = 36939,
	ER_BUS_BUS_NOT_STARTED = 36940,
	ER_BUS_KEYBLOB_OP_INVALID = 36941,
	ER_BUS_INVALID_HEADER_CHECKSUM = 36942,
	ER_BUS_MESSAGE_NOT_ENCRYPTED = 36943,
	ER_BUS_INVALID_HEADER_SERIAL = 36944,
	ER_BUS_TIME_TO_LIVE_EXPIRED = 36945,
	ER_BUS_HDR_EXPANSION_INVALID = 36946,
	ER_BUS_MISSING_COMPRESSION_TOKEN = 36947,
	ER_BUS_NO_PEER_GUID = 36948,
	ER_BUS_MESSAGE_DECRYPTION_FAILED = 36949,
	ER_BUS_SECURITY_FATAL = 36950,
	ER_BUS_KEY_EXPIRED = 36951,
	ER_BUS_CORRUPT_KEYSTORE = 36952,
	ER_BUS_NO_CALL_FOR_REPLY = 36953,
	ER_BUS_NOT_A_COMPLETE_TYPE = 36954,
	ER_BUS_POLICY_VIOLATION = 36955,
	ER_BUS_NO_SUCH_SERVICE = 36956,
	ER_BUS_TRANSPORT_NOT_AVAILABLE = 36957,
	ER_BUS_INVALID_AUTH_MECHANISM = 36958,
	ER_BUS_KEYSTORE_VERSION_MISMATCH = 36959,
	ER_BUS_BLOCKING_CALL_NOT_ALLOWED = 36960,
	ER_BUS_SIGNATURE_MISMATCH = 36961,
	ER_BUS_STOPPING = 36962,
	ER_BUS_METHOD_CALL_ABORTED = 36963,
	ER_BUS_CANNOT_ADD_INTERFACE = 36964,
	ER_BUS_CANNOT_ADD_HANDLER = 36965,
	ER_BUS_KEYSTORE_NOT_LOADED = 36966,
	ER_BUS_NO_SUCH_HANDLE = 36971,
	ER_BUS_HANDLES_NOT_ENABLED = 36972,
	ER_BUS_HANDLES_MISMATCH = 36973,
	ER_BUS_NO_SESSION = 36975,
	ER_BUS_ELEMENT_NOT_FOUND = 36976,
	ER_BUS_NOT_A_DICTIONARY = 36977,
	ER_BUS_WAIT_FAILED = 36978,
	ER_BUS_BAD_SESSION_OPTS = 36980,
	ER_BUS_CONNECTION_REJECTED = 36981,
	ER_DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER = 36982,
	ER_DBUS_REQUEST_NAME_REPLY_IN_QUEUE = 36983,
	ER_DBUS_REQUEST_NAME_REPLY_EXISTS = 36984,
	ER_DBUS_REQUEST_NAME_REPLY_ALREADY_OWNER = 36985,
	ER_DBUS_RELEASE_NAME_REPLY_RELEASED = 36986,
	ER_DBUS_RELEASE_NAME_REPLY_NON_EXISTENT = 36987,
	ER_DBUS_RELEASE_NAME_REPLY_NOT_OWNER = 36988,
	ER_DBUS_START_REPLY_ALREADY_RUNNING = 36990,
	ER_ALLJOYN_BINDSESSIONPORT_REPLY_ALREADY_EXISTS = 36992,
	ER_ALLJOYN_BINDSESSIONPORT_REPLY_FAILED = 36993,
	ER_ALLJOYN_JOINSESSION_REPLY_NO_SESSION = 36995,
	ER_ALLJOYN_JOINSESSION_REPLY_UNREACHABLE = 36996,
	ER_ALLJOYN_JOINSESSION_REPLY_CONNECT_FAILED = 36997,
	ER_ALLJOYN_JOINSESSION_REPLY_REJECTED = 36998,
	ER_ALLJOYN_JOINSESSION_REPLY_BAD_SESSION_OPTS = 36999,
	ER_ALLJOYN_JOINSESSION_REPLY_FAILED = 37000,
	ER_ALLJOYN_LEAVESESSION_REPLY_NO_SESSION = 37002,
	ER_ALLJOYN_LEAVESESSION_REPLY_FAILED = 37003,
	ER_ALLJOYN_ADVERTISENAME_REPLY_TRANSPORT_NOT_AVAILABLE = 37004,
	ER_ALLJOYN_ADVERTISENAME_REPLY_ALREADY_ADVERTISING = 37005,
	ER_ALLJOYN_ADVERTISENAME_REPLY_FAILED = 37006,
	ER_ALLJOYN_CANCELADVERTISENAME_REPLY_FAILED = 37008,
	ER_ALLJOYN_FINDADVERTISEDNAME_REPLY_TRANSPORT_NOT_AVAILABLE = 37009,
	ER_ALLJOYN_FINDADVERTISEDNAME_REPLY_ALREADY_DISCOVERING = 37010,
	ER_ALLJOYN_FINDADVERTISEDNAME_REPLY_FAILED = 37011,
	ER_ALLJOYN_CANCELFINDADVERTISEDNAME_REPLY_FAILED = 37013,
	ER_BUS_UNEXPECTED_DISPOSITION = 37014,
	ER_BUS_INTERFACE_ACTIVATED = 37015,
	ER_ALLJOYN_UNBINDSESSIONPORT_REPLY_BAD_PORT = 37016,
	ER_ALLJOYN_UNBINDSESSIONPORT_REPLY_FAILED = 37017,
	ER_ALLJOYN_BINDSESSIONPORT_REPLY_INVALID_OPTS = 37018,
	ER_ALLJOYN_JOINSESSION_REPLY_ALREADY_JOINED = 37019,
	ER_BUS_SELF_CONNECT = 37020,
	ER_BUS_SECURITY_NOT_ENABLED = 37021,
	ER_BUS_LISTENER_ALREADY_SET = 37022,
	ER_BUS_PEER_AUTH_VERSION_MISMATCH = 37023,
	ER_ALLJOYN_SETLINKTIMEOUT_REPLY_NOT_SUPPORTED = 37024,
	ER_ALLJOYN_SETLINKTIMEOUT_REPLY_NO_DEST_SUPPORT = 37025,
	ER_ALLJOYN_SETLINKTIMEOUT_REPLY_FAILED = 37026,
	ER_ALLJOYN_ACCESS_PERMISSION_WARNING = 37027,
	ER_ALLJOYN_ACCESS_PERMISSION_ERROR = 37028,
	ER_BUS_DESTINATION_NOT_AUTHENTICATED = 37029,
	ER_BUS_ENDPOINT_REDIRECTED = 37030,
	ER_BUS_AUTHENTICATION_PENDING = 37031,
	ER_BUS_NOT_AUTHORIZED = 37032,
	ER_PACKET_BUS_NO_SUCH_CHANNEL = 37033,
	ER_PACKET_BAD_FORMAT = 37034,
	ER_PACKET_CONNECT_TIMEOUT = 37035,
	ER_PACKET_CHANNEL_FAIL = 37036,
	ER_PACKET_TOO_LARGE = 37037,
	ER_PACKET_BAD_PARAMETER = 37038,
	ER_PACKET_BAD_CRC = 37039,
	ER_RENDEZVOUS_SERVER_DEACTIVATED_USER = 37067,
	ER_RENDEZVOUS_SERVER_UNKNOWN_USER = 37068,
	ER_UNABLE_TO_CONNECT_TO_RENDEZVOUS_SERVER = 37069,
	ER_NOT_CONNECTED_TO_RENDEZVOUS_SERVER = 37070,
	ER_UNABLE_TO_SEND_MESSAGE_TO_RENDEZVOUS_SERVER = 37071,
	ER_INVALID_RENDEZVOUS_SERVER_INTERFACE_MESSAGE = 37072,
	ER_INVALID_PERSISTENT_CONNECTION_MESSAGE_RESPONSE = 37073,
	ER_INVALID_ON_DEMAND_CONNECTION_MESSAGE_RESPONSE = 37074,
	ER_INVALID_HTTP_METHOD_USED_FOR_RENDEZVOUS_SERVER_INTERFACE_MESSAGE = 37075,
	ER_RENDEZVOUS_SERVER_ERR500_INTERNAL_ERROR = 37076,
	ER_RENDEZVOUS_SERVER_ERR503_STATUS_UNAVAILABLE = 37077,
	ER_RENDEZVOUS_SERVER_ERR401_UNAUTHORIZED_REQUEST = 37078,
	ER_RENDEZVOUS_SERVER_UNRECOVERABLE_ERROR = 37079,
	ER_RENDEZVOUS_SERVER_ROOT_CERTIFICATE_UNINITIALIZED = 37080,
	ER_BUS_NO_SUCH_ANNOTATION = 37081,
	ER_BUS_ANNOTATION_ALREADY_EXISTS = 37082,
	ER_SOCK_CLOSING = 37083,
	ER_NO_SUCH_DEVICE = 37084,
	ER_P2P = 37085,
	ER_P2P_TIMEOUT = 37086,
	ER_P2P_NOT_CONNECTED = 37087,
	ER_BAD_TRANSPORT_MASK = 37088,
	ER_PROXIMITY_CONNECTION_ESTABLISH_FAIL = 37089,
	ER_PROXIMITY_NO_PEERS_FOUND = 37090,
	ER_BUS_OBJECT_NOT_REGISTERED = 37091,
	ER_P2P_DISABLED = 37092,
	ER_P2P_BUSY = 37093,
	ER_BUS_INCOMPATIBLE_DAEMON = 37094,
	ER_P2P_NO_GO = 37095,
	ER_P2P_NO_STA = 37096,
	ER_P2P_FORBIDDEN = 37097,
	ER_ALLJOYN_ONAPPSUSPEND_REPLY_FAILED = 37098,
	ER_ALLJOYN_ONAPPSUSPEND_REPLY_UNSUPPORTED = 37099,
	ER_ALLJOYN_ONAPPRESUME_REPLY_FAILED = 37100,
	ER_ALLJOYN_ONAPPRESUME_REPLY_UNSUPPORTED = 37101,
	ER_BUS_NO_SUCH_MESSAGE = 37102,
	ER_ALLJOYN_REMOVESESSIONMEMBER_REPLY_NO_SESSION = 37103,
	ER_ALLJOYN_REMOVESESSIONMEMBER_NOT_BINDER = 37104,
	ER_ALLJOYN_REMOVESESSIONMEMBER_NOT_MULTIPOINT = 37105,
	ER_ALLJOYN_REMOVESESSIONMEMBER_NOT_FOUND = 37106,
	ER_ALLJOYN_REMOVESESSIONMEMBER_INCOMPATIBLE_REMOTE_DAEMON = 37107,
	ER_ALLJOYN_REMOVESESSIONMEMBER_REPLY_FAILED = 37108,
	ER_BUS_REMOVED_BY_BINDER = 37109,
	ER_BUS_MATCH_RULE_NOT_FOUND = 37110,
	ER_ALLJOYN_PING_FAILED = 37111,
	ER_ALLJOYN_PING_REPLY_UNREACHABLE = 37112,
	ER_UDP_MSG_TOO_LONG = 37113,
	ER_UDP_DEMUX_NO_ENDPOINT = 37114,
	ER_UDP_NO_NETWORK = 37115,
	ER_UDP_UNEXPECTED_LENGTH = 37116,
	ER_UDP_UNEXPECTED_FLOW = 37117,
	ER_UDP_DISCONNECT = 37118,
	ER_UDP_NOT_IMPLEMENTED = 37119,
	ER_UDP_NO_LISTENER = 37120,
	ER_UDP_STOPPING = 37121,
	ER_ARDP_BACKPRESSURE = 37122,
	ER_UDP_BACKPRESSURE = 37123,
	ER_ARDP_INVALID_STATE = 37124,
	ER_ARDP_TTL_EXPIRED = 37125,
	ER_ARDP_PERSIST_TIMEOUT = 37126,
	ER_ARDP_PROBE_TIMEOUT = 37127,
	ER_ARDP_REMOTE_CONNECTION_RESET = 37128,
	ER_UDP_BUSHELLO = 37129,
	ER_UDP_MESSAGE = 37130,
	ER_UDP_INVALID = 37131,
	ER_UDP_UNSUPPORTED = 37132,
	ER_UDP_ENDPOINT_STALLED = 37133,
	ER_ARDP_INVALID_RESPONSE = 37134,
	ER_ARDP_INVALID_CONNECTION = 37135,
	ER_UDP_LOCAL_DISCONNECT = 37136,
	ER_UDP_EARLY_EXIT = 37137,
	ER_UDP_LOCAL_DISCONNECT_FAIL = 37138,
	ER_ARDP_DISCONNECTING = 37139,
	ER_ALLJOYN_PING_REPLY_INCOMPATIBLE_REMOTE_ROUTING_NODE = 37140,
	ER_ALLJOYN_PING_REPLY_TIMEOUT = 37141,
	ER_ALLJOYN_PING_REPLY_UNKNOWN_NAME = 37142,
	ER_ALLJOYN_PING_REPLY_FAILED = 37143,
	ER_TCP_MAX_UNTRUSTED = 37144,
	ER_ALLJOYN_PING_REPLY_IN_PROGRESS = 37145,
	ER_LANGUAGE_NOT_SUPPORTED = 37146,
	ER_ABOUT_FIELD_ALREADY_SPECIFIED = 37147,
	ER_UDP_NOT_DISCONNECTED = 37148,
	ER_UDP_ENDPOINT_NOT_STARTED = 37149,
	ER_UDP_ENDPOINT_REMOVED = 37150,
	ER_ARDP_VERSION_NOT_SUPPORTED = 37151,
	ER_CONNECTION_LIMIT_EXCEEDED = 37152,
	ER_ARDP_WRITE_BLOCKED = 37153,
	ER_PERMISSION_DENIED = 37154,
	ER_ABOUT_DEFAULT_LANGUAGE_NOT_SPECIFIED = 37155,
	ER_ABOUT_SESSIONPORT_NOT_BOUND = 37156,
	ER_ABOUT_ABOUTDATA_MISSING_REQUIRED_FIELD = 37157,
	ER_ABOUT_INVALID_ABOUTDATA_LISTENER = 37158,
	ER_BUS_PING_GROUP_NOT_FOUND = 37159,
	ER_BUS_REMOVED_BY_BINDER_SELF = 37160,
	ER_INVALID_CONFIG = 37161,
	ER_ABOUT_INVALID_ABOUTDATA_FIELD_VALUE = 37162,
	ER_ABOUT_INVALID_ABOUTDATA_FIELD_APPID_SIZE = 37163,
	ER_BUS_TRANSPORT_ACCESS_DENIED = 37164,
	ER_INVALID_CERTIFICATE = 37165,
	ER_CERTIFICATE_NOT_FOUND = 37166,
	ER_DUPLICATE_CERTIFICATE = 37167,
	ER_UNKNOWN_CERTIFICATE = 37168,
	ER_MISSING_DIGEST_IN_CERTIFICATE = 37169,
	ER_DIGEST_MISMATCH = 37170,
	ER_DUPLICATE_KEY = 37171,
	ER_NO_COMMON_TRUST = 37172,
	ER_MANIFEST_NOT_FOUND = 37173,
	ER_INVALID_CERT_CHAIN = 37174,
	ER_NO_TRUST_ANCHOR = 37175,
	ER_INVALID_APPLICATION_STATE = 37176,
	ER_FEATURE_NOT_AVAILABLE = 37177,
	ER_KEY_STORE_ALREADY_INITIALIZED = 37178,
	ER_KEY_STORE_ID_NOT_YET_SET = 37179,
	ER_POLICY_NOT_NEWER = 37180,
	ER_MANIFEST_REJECTED = 37181,
	ER_INVALID_CERTIFICATE_USAGE = 37182,
	ER_INVALID_SIGNAL_EMISSION_TYPE = 37183,
	ER_APPLICATION_STATE_LISTENER_ALREADY_EXISTS = 37184,
	ER_APPLICATION_STATE_LISTENER_NO_SUCH_LISTENER = 37185,
	ER_MANAGEMENT_ALREADY_STARTED = 37186,
	ER_MANAGEMENT_NOT_STARTED = 37187,
	ER_BUS_DESCRIPTION_ALREADY_EXISTS = 37188,
}


[AllowDuplicates]
public enum alljoyn_typeid : int32
{
	ALLJOYN_INVALID = 0,
	ALLJOYN_ARRAY = 97,
	ALLJOYN_BOOLEAN = 98,
	ALLJOYN_DOUBLE = 100,
	ALLJOYN_DICT_ENTRY = 101,
	ALLJOYN_SIGNATURE = 103,
	ALLJOYN_HANDLE = 104,
	ALLJOYN_INT32 = 105,
	ALLJOYN_INT16 = 110,
	ALLJOYN_OBJECT_PATH = 111,
	ALLJOYN_UINT16 = 113,
	ALLJOYN_STRUCT = 114,
	ALLJOYN_STRING = 115,
	ALLJOYN_UINT64 = 116,
	ALLJOYN_UINT32 = 117,
	ALLJOYN_VARIANT = 118,
	ALLJOYN_INT64 = 120,
	ALLJOYN_BYTE = 121,
	ALLJOYN_STRUCT_OPEN = 40,
	ALLJOYN_STRUCT_CLOSE = 41,
	ALLJOYN_DICT_ENTRY_OPEN = 123,
	ALLJOYN_DICT_ENTRY_CLOSE = 125,
	ALLJOYN_BOOLEAN_ARRAY = 25185,
	ALLJOYN_DOUBLE_ARRAY = 25697,
	ALLJOYN_INT32_ARRAY = 26977,
	ALLJOYN_INT16_ARRAY = 28257,
	ALLJOYN_UINT16_ARRAY = 29025,
	ALLJOYN_UINT64_ARRAY = 29793,
	ALLJOYN_UINT32_ARRAY = 30049,
	ALLJOYN_INT64_ARRAY = 30817,
	ALLJOYN_BYTE_ARRAY = 31073,
	ALLJOYN_WILDCARD = 42,
}


[AllowDuplicates]
public enum alljoyn_applicationstate : int32
{
	NOT_CLAIMABLE = 0,
	CLAIMABLE = 1,
	CLAIMED = 2,
	NEED_UPDATE = 3,
}


[AllowDuplicates]
public enum alljoyn_claimcapability_masks : int32
{
	CAPABLE_ECDHE_NULL = 1,
	CAPABLE_ECDHE_ECDSA = 4,
	CAPABLE_ECDHE_SPEKE = 8,
}


[AllowDuplicates]
public enum alljoyn_claimcapabilityadditionalinfo_masks : int32
{
	PASSWORD_GENERATED_BY_SECURITY_MANAGER = 1,
	PASSWORD_GENERATED_BY_APPLICATION = 2,
}


[AllowDuplicates]
public enum alljoyn_messagetype : int32
{
	ALLJOYN_MESSAGE_INVALID = 0,
	ALLJOYN_MESSAGE_METHOD_CALL = 1,
	ALLJOYN_MESSAGE_METHOD_RET = 2,
	ALLJOYN_MESSAGE_ERROR = 3,
	ALLJOYN_MESSAGE_SIGNAL = 4,
}


[AllowDuplicates]
public enum alljoyn_interfacedescription_securitypolicy : int32
{
	AJ_IFC_SECURITY_INHERIT = 0,
	AJ_IFC_SECURITY_REQUIRED = 1,
	AJ_IFC_SECURITY_OFF = 2,
}


[AllowDuplicates]
public enum alljoyn_sessionlostreason : int32
{
	ALLJOYN_SESSIONLOST_INVALID = 0,
	ALLJOYN_SESSIONLOST_REMOTE_END_LEFT_SESSION = 1,
	ALLJOYN_SESSIONLOST_REMOTE_END_CLOSED_ABRUPTLY = 2,
	ALLJOYN_SESSIONLOST_REMOVED_BY_BINDER = 3,
	ALLJOYN_SESSIONLOST_LINK_TIMEOUT = 4,
	ALLJOYN_SESSIONLOST_REASON_OTHER = 5,
}

#endregion

#region Function Pointers
public function void alljoyn_applicationstatelistener_state_ptr(int8* busName, int8* publicKey, alljoyn_applicationstate applicationState, void* context);

public function QStatus alljoyn_keystorelistener_loadrequest_ptr(void* context, alljoyn_keystorelistener listener, alljoyn_keystore keyStore);

public function QStatus alljoyn_keystorelistener_storerequest_ptr(void* context, alljoyn_keystorelistener listener, alljoyn_keystore keyStore);

public function QStatus alljoyn_keystorelistener_acquireexclusivelock_ptr(void* context, alljoyn_keystorelistener listener);

public function void alljoyn_keystorelistener_releaseexclusivelock_ptr(void* context, alljoyn_keystorelistener listener);

public function int32 alljoyn_authlistener_requestcredentials_ptr(void* context, PSTR authMechanism, PSTR peerName, uint16 authCount, PSTR userName, uint16 credMask, alljoyn_credentials credentials);

public function QStatus alljoyn_authlistener_requestcredentialsasync_ptr(void* context, alljoyn_authlistener listener, PSTR authMechanism, PSTR peerName, uint16 authCount, PSTR userName, uint16 credMask, void* authContext);

public function int32 alljoyn_authlistener_verifycredentials_ptr(void* context, PSTR authMechanism, PSTR peerName, alljoyn_credentials credentials);

public function QStatus alljoyn_authlistener_verifycredentialsasync_ptr(void* context, alljoyn_authlistener listener, PSTR authMechanism, PSTR peerName, alljoyn_credentials credentials, void* authContext);

public function void alljoyn_authlistener_securityviolation_ptr(void* context, QStatus status, alljoyn_message msg);

public function void alljoyn_authlistener_authenticationcomplete_ptr(void* context, PSTR authMechanism, PSTR peerName, int32 success);

public function void alljoyn_buslistener_listener_registered_ptr(void* context, alljoyn_busattachment bus);

public function void alljoyn_buslistener_listener_unregistered_ptr(void* context);

public function void alljoyn_buslistener_found_advertised_name_ptr(void* context, PSTR name, uint16 transport, PSTR namePrefix);

public function void alljoyn_buslistener_lost_advertised_name_ptr(void* context, PSTR name, uint16 transport, PSTR namePrefix);

public function void alljoyn_buslistener_name_owner_changed_ptr(void* context, PSTR busName, PSTR previousOwner, PSTR newOwner);

public function void alljoyn_buslistener_bus_stopping_ptr(void* context);

public function void alljoyn_buslistener_bus_disconnected_ptr(void* context);

public function void alljoyn_buslistener_bus_prop_changed_ptr(void* context, PSTR prop_name, alljoyn_msgarg prop_value);

public function PSTR alljoyn_interfacedescription_translation_callback_ptr(PSTR sourceLanguage, PSTR targetLanguage, PSTR sourceText);

public function void alljoyn_messagereceiver_methodhandler_ptr(alljoyn_busobject bus, alljoyn_interfacedescription_member* member, alljoyn_message message);

public function void alljoyn_messagereceiver_replyhandler_ptr(alljoyn_message message, void* context);

public function void alljoyn_messagereceiver_signalhandler_ptr(alljoyn_interfacedescription_member* member, PSTR srcPath, alljoyn_message message);

public function QStatus alljoyn_busobject_prop_get_ptr(void* context, PSTR ifcName, PSTR propName, alljoyn_msgarg val);

public function QStatus alljoyn_busobject_prop_set_ptr(void* context, PSTR ifcName, PSTR propName, alljoyn_msgarg val);

public function void alljoyn_busobject_object_registration_ptr(void* context);

public function void alljoyn_proxybusobject_listener_introspectcb_ptr(QStatus status, alljoyn_proxybusobject obj, void* context);

public function void alljoyn_proxybusobject_listener_getpropertycb_ptr(QStatus status, alljoyn_proxybusobject obj, alljoyn_msgarg value, void* context);

public function void alljoyn_proxybusobject_listener_getallpropertiescb_ptr(QStatus status, alljoyn_proxybusobject obj, alljoyn_msgarg values, void* context);

public function void alljoyn_proxybusobject_listener_setpropertycb_ptr(QStatus status, alljoyn_proxybusobject obj, void* context);

public function void alljoyn_proxybusobject_listener_propertieschanged_ptr(alljoyn_proxybusobject obj, PSTR ifaceName, alljoyn_msgarg changed, alljoyn_msgarg invalidated, void* context);

public function QStatus alljoyn_permissionconfigurationlistener_factoryreset_ptr(void* context);

public function void alljoyn_permissionconfigurationlistener_policychanged_ptr(void* context);

public function void alljoyn_permissionconfigurationlistener_startmanagement_ptr(void* context);

public function void alljoyn_permissionconfigurationlistener_endmanagement_ptr(void* context);

public function void alljoyn_sessionlistener_sessionlost_ptr(void* context, uint32 sessionId, alljoyn_sessionlostreason reason);

public function void alljoyn_sessionlistener_sessionmemberadded_ptr(void* context, uint32 sessionId, PSTR uniqueName);

public function void alljoyn_sessionlistener_sessionmemberremoved_ptr(void* context, uint32 sessionId, PSTR uniqueName);

public function int32 alljoyn_sessionportlistener_acceptsessionjoiner_ptr(void* context, uint16 sessionPort, PSTR joiner, alljoyn_sessionopts opts);

public function void alljoyn_sessionportlistener_sessionjoined_ptr(void* context, uint16 sessionPort, uint32 id, PSTR joiner);

public function void alljoyn_about_announced_ptr(void* context, PSTR busName, uint16 version, uint16 port, alljoyn_msgarg objectDescriptionArg, alljoyn_msgarg aboutDataArg);

public function void alljoyn_busattachment_joinsessioncb_ptr(QStatus status, uint32 sessionId, alljoyn_sessionopts opts, void* context);

public function void alljoyn_busattachment_setlinktimeoutcb_ptr(QStatus status, uint32 timeout, void* context);

public function QStatus alljoyn_aboutdatalistener_getaboutdata_ptr(void* context, alljoyn_msgarg msgArg, PSTR language);

public function QStatus alljoyn_aboutdatalistener_getannouncedaboutdata_ptr(void* context, alljoyn_msgarg msgArg);

public function void alljoyn_autopinger_destination_lost_ptr(void* context, PSTR group, PSTR destination);

public function void alljoyn_autopinger_destination_found_ptr(void* context, PSTR group, PSTR destination);

public function void alljoyn_observer_object_discovered_ptr(void* context, alljoyn_proxybusobject_ref proxyref);

public function void alljoyn_observer_object_lost_ptr(void* context, alljoyn_proxybusobject_ref proxyref);

#endregion

#region Structs
[CRepr]
public struct _alljoyn_abouticon_handle
{
}

[CRepr]
public struct alljoyn_certificateid
{
	public uint8* serial;
	public uint serialLen;
	public int8* issuerPublicKey;
	public uint8* issuerAki;
	public uint issuerAkiLen;
}

[CRepr]
public struct alljoyn_certificateidarray
{
	public uint count;
	public alljoyn_certificateid* ids;
}

[CRepr]
public struct alljoyn_manifestarray
{
	public uint count;
	public int8** xmls;
}

[CRepr]
public struct alljoyn_applicationstatelistener_callbacks
{
	public alljoyn_applicationstatelistener_state_ptr state;
}

[CRepr]
public struct alljoyn_keystorelistener_callbacks
{
	public alljoyn_keystorelistener_loadrequest_ptr load_request;
	public alljoyn_keystorelistener_storerequest_ptr store_request;
}

[CRepr]
public struct alljoyn_keystorelistener_with_synchronization_callbacks
{
	public alljoyn_keystorelistener_loadrequest_ptr load_request;
	public alljoyn_keystorelistener_storerequest_ptr store_request;
	public alljoyn_keystorelistener_acquireexclusivelock_ptr acquire_exclusive_lock;
	public alljoyn_keystorelistener_releaseexclusivelock_ptr release_exclusive_lock;
}

[CRepr]
public struct alljoyn_authlistener_callbacks
{
	public alljoyn_authlistener_requestcredentials_ptr request_credentials;
	public alljoyn_authlistener_verifycredentials_ptr verify_credentials;
	public alljoyn_authlistener_securityviolation_ptr security_violation;
	public alljoyn_authlistener_authenticationcomplete_ptr authentication_complete;
}

[CRepr]
public struct alljoyn_authlistenerasync_callbacks
{
	public alljoyn_authlistener_requestcredentialsasync_ptr request_credentials;
	public alljoyn_authlistener_verifycredentialsasync_ptr verify_credentials;
	public alljoyn_authlistener_securityviolation_ptr security_violation;
	public alljoyn_authlistener_authenticationcomplete_ptr authentication_complete;
}

[CRepr]
public struct alljoyn_buslistener_callbacks
{
	public alljoyn_buslistener_listener_registered_ptr listener_registered;
	public alljoyn_buslistener_listener_unregistered_ptr listener_unregistered;
	public alljoyn_buslistener_found_advertised_name_ptr found_advertised_name;
	public alljoyn_buslistener_lost_advertised_name_ptr lost_advertised_name;
	public alljoyn_buslistener_name_owner_changed_ptr name_owner_changed;
	public alljoyn_buslistener_bus_stopping_ptr bus_stopping;
	public alljoyn_buslistener_bus_disconnected_ptr bus_disconnected;
	public alljoyn_buslistener_bus_prop_changed_ptr property_changed;
}

[CRepr]
public struct alljoyn_interfacedescription_member
{
	public alljoyn_interfacedescription iface;
	public alljoyn_messagetype memberType;
	public PSTR name;
	public PSTR signature;
	public PSTR returnSignature;
	public PSTR argNames;
	public void* internal_member;
}

[CRepr]
public struct alljoyn_interfacedescription_property
{
	public PSTR name;
	public PSTR signature;
	public uint8 access;
	public void* internal_property;
}

[CRepr]
public struct alljoyn_busobject_callbacks
{
	public alljoyn_busobject_prop_get_ptr property_get;
	public alljoyn_busobject_prop_set_ptr property_set;
	public alljoyn_busobject_object_registration_ptr object_registered;
	public alljoyn_busobject_object_registration_ptr object_unregistered;
}

[CRepr]
public struct alljoyn_busobject_methodentry
{
	public alljoyn_interfacedescription_member* member;
	public alljoyn_messagereceiver_methodhandler_ptr method_handler;
}

[CRepr]
public struct alljoyn_permissionconfigurationlistener_callbacks
{
	public alljoyn_permissionconfigurationlistener_factoryreset_ptr factory_reset;
	public alljoyn_permissionconfigurationlistener_policychanged_ptr policy_changed;
	public alljoyn_permissionconfigurationlistener_startmanagement_ptr start_management;
	public alljoyn_permissionconfigurationlistener_endmanagement_ptr end_management;
}

[CRepr]
public struct alljoyn_sessionlistener_callbacks
{
	public alljoyn_sessionlistener_sessionlost_ptr session_lost;
	public alljoyn_sessionlistener_sessionmemberadded_ptr session_member_added;
	public alljoyn_sessionlistener_sessionmemberremoved_ptr session_member_removed;
}

[CRepr]
public struct alljoyn_sessionportlistener_callbacks
{
	public alljoyn_sessionportlistener_acceptsessionjoiner_ptr accept_session_joiner;
	public alljoyn_sessionportlistener_sessionjoined_ptr session_joined;
}

[CRepr]
public struct alljoyn_aboutlistener_callback
{
	public alljoyn_about_announced_ptr about_listener_announced;
}

[CRepr]
public struct _alljoyn_abouticonobj_handle
{
}

[CRepr]
public struct _alljoyn_abouticonproxy_handle
{
}

[CRepr]
public struct alljoyn_aboutdatalistener_callbacks
{
	public alljoyn_aboutdatalistener_getaboutdata_ptr about_datalistener_getaboutdata;
	public alljoyn_aboutdatalistener_getannouncedaboutdata_ptr about_datalistener_getannouncedaboutdata;
}

[CRepr]
public struct alljoyn_pinglistener_callback
{
	public alljoyn_autopinger_destination_found_ptr destination_found;
	public alljoyn_autopinger_destination_lost_ptr destination_lost;
}

[CRepr]
public struct alljoyn_observerlistener_callback
{
	public alljoyn_observer_object_discovered_ptr object_discovered;
	public alljoyn_observer_object_lost_ptr object_lost;
}

#endregion

#region Functions
public static
{
	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE AllJoynConnectToBus(PWSTR connectionSpec);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllJoynCloseBusHandle(HANDLE busHandle);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllJoynSendToBus(HANDLE connectedBusHandle, void* buffer, uint32 bytesToWrite, uint32* bytesTransferred, void* reserved);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllJoynReceiveFromBus(HANDLE connectedBusHandle, void* buffer, uint32 bytesToRead, uint32* bytesTransferred, void* reserved);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllJoynEventSelect(HANDLE connectedBusHandle, HANDLE eventHandle, uint32 eventTypes);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllJoynEnumEvents(HANDLE connectedBusHandle, HANDLE eventToReset, uint32* eventTypes);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE AllJoynCreateBus(uint32 outBufferSize, uint32 inBufferSize, SECURITY_ATTRIBUTES* lpSecurityAttributes);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AllJoynAcceptBusConnection(HANDLE serverBusHandle, HANDLE abortEvent);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_unity_deferred_callbacks_process();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_unity_set_deferred_callback_mainthread_only(int32 mainthread_only);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR QCC_StatusText(QStatus status);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_msgarg alljoyn_msgarg_create();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_msgarg alljoyn_msgarg_create_and_set(PSTR signature);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_msgarg_destroy(alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_msgarg alljoyn_msgarg_array_create(uint size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_msgarg alljoyn_msgarg_array_element(alljoyn_msgarg arg, uint index);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set(alljoyn_msgarg arg, PSTR signature);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get(alljoyn_msgarg arg, PSTR signature);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_msgarg alljoyn_msgarg_copy(alljoyn_msgarg source);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_msgarg_clone(alljoyn_msgarg destination, alljoyn_msgarg source);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_msgarg_equal(alljoyn_msgarg lhv, alljoyn_msgarg rhv);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_array_set(alljoyn_msgarg args, uint* numArgs, PSTR signature);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_array_get(alljoyn_msgarg args, uint numArgs, PSTR signature);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_msgarg_tostring(alljoyn_msgarg arg, PSTR str, uint buf, uint indent);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_msgarg_array_tostring(alljoyn_msgarg args, uint numArgs, PSTR str, uint buf, uint indent);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_msgarg_signature(alljoyn_msgarg arg, PSTR str, uint buf);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_msgarg_array_signature(alljoyn_msgarg values, uint numValues, PSTR str, uint buf);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_msgarg_hassignature(alljoyn_msgarg arg, PSTR signature);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_getdictelement(alljoyn_msgarg arg, PSTR elemSig);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_typeid alljoyn_msgarg_gettype(alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_msgarg_clear(alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_msgarg_stabilize(alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_array_set_offset(alljoyn_msgarg args, uint argOffset, uint* numArgs, PSTR signature);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_and_stabilize(alljoyn_msgarg arg, PSTR signature);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_uint8(alljoyn_msgarg arg, uint8 y);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_bool(alljoyn_msgarg arg, int32 b);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_int16(alljoyn_msgarg arg, int16 n);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_uint16(alljoyn_msgarg arg, uint16 q);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_int32(alljoyn_msgarg arg, int32 i);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_uint32(alljoyn_msgarg arg, uint32 u);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_int64(alljoyn_msgarg arg, int64 x);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_uint64(alljoyn_msgarg arg, uint64 t);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_double(alljoyn_msgarg arg, double d);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_string(alljoyn_msgarg arg, PSTR s);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_objectpath(alljoyn_msgarg arg, PSTR o);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_signature(alljoyn_msgarg arg, PSTR g);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_uint8(alljoyn_msgarg arg, uint8* y);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_bool(alljoyn_msgarg arg, int32* b);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_int16(alljoyn_msgarg arg, int16* n);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_uint16(alljoyn_msgarg arg, uint16* q);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_int32(alljoyn_msgarg arg, int32* i);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_uint32(alljoyn_msgarg arg, uint32* u);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_int64(alljoyn_msgarg arg, int64* x);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_uint64(alljoyn_msgarg arg, uint64* t);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_double(alljoyn_msgarg arg, double* d);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_string(alljoyn_msgarg arg, int8** s);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_objectpath(alljoyn_msgarg arg, int8** o);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_signature(alljoyn_msgarg arg, int8** g);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_variant(alljoyn_msgarg arg, alljoyn_msgarg v);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_uint8_array(alljoyn_msgarg arg, uint length, uint8* ay);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_bool_array(alljoyn_msgarg arg, uint length, int32* ab);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_int16_array(alljoyn_msgarg arg, uint length, int16* an);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_uint16_array(alljoyn_msgarg arg, uint length, uint16* aq);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_int32_array(alljoyn_msgarg arg, uint length, int32* ai);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_uint32_array(alljoyn_msgarg arg, uint length, uint32* au);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_int64_array(alljoyn_msgarg arg, uint length, int64* ax);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_uint64_array(alljoyn_msgarg arg, uint length, uint64* at);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_double_array(alljoyn_msgarg arg, uint length, double* ad);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_string_array(alljoyn_msgarg arg, uint length, int8** @as);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_objectpath_array(alljoyn_msgarg arg, uint length, int8** ao);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_set_signature_array(alljoyn_msgarg arg, uint length, int8** ag);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_uint8_array(alljoyn_msgarg arg, uint* length, uint8* ay);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_bool_array(alljoyn_msgarg arg, uint* length, int32* ab);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_int16_array(alljoyn_msgarg arg, uint* length, int16* an);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_uint16_array(alljoyn_msgarg arg, uint* length, uint16* aq);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_int32_array(alljoyn_msgarg arg, uint* length, int32* ai);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_uint32_array(alljoyn_msgarg arg, uint* length, uint32* au);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_int64_array(alljoyn_msgarg arg, uint* length, int64* ax);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_uint64_array(alljoyn_msgarg arg, uint* length, uint64* at);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_double_array(alljoyn_msgarg arg, uint* length, double* ad);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_get_variant_array(alljoyn_msgarg arg, PSTR signature, uint* length, alljoyn_msgarg* av);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_msgarg_get_array_numberofelements(alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_msgarg_get_array_element(alljoyn_msgarg arg, uint index, alljoyn_msgarg* element);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_msgarg_get_array_elementsignature(alljoyn_msgarg arg, uint index);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_msgarg alljoyn_msgarg_getkey(alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_msgarg alljoyn_msgarg_getvalue(alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_setdictentry(alljoyn_msgarg arg, alljoyn_msgarg key, alljoyn_msgarg value);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_msgarg_setstruct(alljoyn_msgarg arg, alljoyn_msgarg struct_members, uint num_members);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_msgarg_getnummembers(alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_msgarg alljoyn_msgarg_getmember(alljoyn_msgarg arg, uint index);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_aboutdata alljoyn_aboutdata_create_empty();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_aboutdata alljoyn_aboutdata_create(PSTR defaultLanguage);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_aboutdata alljoyn_aboutdata_create_full(alljoyn_msgarg arg, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_aboutdata_destroy(alljoyn_aboutdata data);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_createfromxml(alljoyn_aboutdata data, PSTR aboutDataXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 alljoyn_aboutdata_isvalid(alljoyn_aboutdata data, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_createfrommsgarg(alljoyn_aboutdata data, alljoyn_msgarg arg, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setappid(alljoyn_aboutdata data, uint8* appId, uint num);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setappid_fromstring(alljoyn_aboutdata data, PSTR appId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getappid(alljoyn_aboutdata data, uint8** appId, uint* num);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setdefaultlanguage(alljoyn_aboutdata data, PSTR defaultLanguage);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getdefaultlanguage(alljoyn_aboutdata data, int8** defaultLanguage);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setdevicename(alljoyn_aboutdata data, PSTR deviceName, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getdevicename(alljoyn_aboutdata data, int8** deviceName, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setdeviceid(alljoyn_aboutdata data, PSTR deviceId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getdeviceid(alljoyn_aboutdata data, int8** deviceId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setappname(alljoyn_aboutdata data, PSTR appName, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getappname(alljoyn_aboutdata data, int8** appName, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setmanufacturer(alljoyn_aboutdata data, PSTR manufacturer, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getmanufacturer(alljoyn_aboutdata data, int8** manufacturer, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setmodelnumber(alljoyn_aboutdata data, PSTR modelNumber);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getmodelnumber(alljoyn_aboutdata data, int8** modelNumber);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setsupportedlanguage(alljoyn_aboutdata data, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_aboutdata_getsupportedlanguages(alljoyn_aboutdata data, int8** languageTags, uint num);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setdescription(alljoyn_aboutdata data, PSTR description, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getdescription(alljoyn_aboutdata data, int8** description, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setdateofmanufacture(alljoyn_aboutdata data, PSTR dateOfManufacture);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getdateofmanufacture(alljoyn_aboutdata data, int8** dateOfManufacture);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setsoftwareversion(alljoyn_aboutdata data, PSTR softwareVersion);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getsoftwareversion(alljoyn_aboutdata data, int8** softwareVersion);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getajsoftwareversion(alljoyn_aboutdata data, int8** ajSoftwareVersion);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_sethardwareversion(alljoyn_aboutdata data, PSTR hardwareVersion);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_gethardwareversion(alljoyn_aboutdata data, int8** hardwareVersion);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setsupporturl(alljoyn_aboutdata data, PSTR supportUrl);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getsupporturl(alljoyn_aboutdata data, int8** supportUrl);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_setfield(alljoyn_aboutdata data, PSTR name, alljoyn_msgarg value, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getfield(alljoyn_aboutdata data, PSTR name, alljoyn_msgarg* value, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_aboutdata_getfields(alljoyn_aboutdata data, int8** fields, uint num_fields);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getaboutdata(alljoyn_aboutdata data, alljoyn_msgarg msgArg, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutdata_getannouncedaboutdata(alljoyn_aboutdata data, alljoyn_msgarg msgArg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 alljoyn_aboutdata_isfieldrequired(alljoyn_aboutdata data, PSTR fieldName);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 alljoyn_aboutdata_isfieldannounced(alljoyn_aboutdata data, PSTR fieldName);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 alljoyn_aboutdata_isfieldlocalized(alljoyn_aboutdata data, PSTR fieldName);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_aboutdata_getfieldsignature(alljoyn_aboutdata data, PSTR fieldName);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _alljoyn_abouticon_handle* alljoyn_abouticon_create();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_abouticon_destroy(_alljoyn_abouticon_handle* icon);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_abouticon_getcontent(_alljoyn_abouticon_handle* icon, uint8** data, uint* size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_abouticon_setcontent(_alljoyn_abouticon_handle* icon, PSTR type, uint8* data, uint csize, uint8 ownsData);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_abouticon_geturl(_alljoyn_abouticon_handle* icon, int8** type, int8** url);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_abouticon_seturl(_alljoyn_abouticon_handle* icon, PSTR type, PSTR url);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_abouticon_clear(_alljoyn_abouticon_handle* icon);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_abouticon_setcontent_frommsgarg(_alljoyn_abouticon_handle* icon, alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 alljoyn_permissionconfigurator_getdefaultclaimcapabilities();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getapplicationstate(alljoyn_permissionconfigurator configurator, alljoyn_applicationstate* state);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_setapplicationstate(alljoyn_permissionconfigurator configurator, alljoyn_applicationstate state);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getpublickey(alljoyn_permissionconfigurator configurator, int8** publicKey);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_permissionconfigurator_publickey_destroy(int8* publicKey);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getmanifesttemplate(alljoyn_permissionconfigurator configurator, int8** manifestTemplateXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_permissionconfigurator_manifesttemplate_destroy(int8* manifestTemplateXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_setmanifesttemplatefromxml(alljoyn_permissionconfigurator configurator, int8* manifestTemplateXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getclaimcapabilities(alljoyn_permissionconfigurator configurator, uint16* claimCapabilities);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_setclaimcapabilities(alljoyn_permissionconfigurator configurator, uint16 claimCapabilities);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getclaimcapabilitiesadditionalinfo(alljoyn_permissionconfigurator configurator, uint16* additionalInfo);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_setclaimcapabilitiesadditionalinfo(alljoyn_permissionconfigurator configurator, uint16 additionalInfo);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_reset(alljoyn_permissionconfigurator configurator);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_claim(alljoyn_permissionconfigurator configurator, int8* caKey, int8* identityCertificateChain, uint8* groupId, uint groupSize, int8* groupAuthority, int8** manifestsXmls, uint manifestsCount);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_updateidentity(alljoyn_permissionconfigurator configurator, int8* identityCertificateChain, int8** manifestsXmls, uint manifestsCount);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getidentity(alljoyn_permissionconfigurator configurator, int8** identityCertificateChain);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_permissionconfigurator_certificatechain_destroy(int8* certificateChain);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getmanifests(alljoyn_permissionconfigurator configurator, alljoyn_manifestarray* manifestArray);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_permissionconfigurator_manifestarray_cleanup(alljoyn_manifestarray* manifestArray);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_installmanifests(alljoyn_permissionconfigurator configurator, int8** manifestsXmls, uint manifestsCount, int32 @append);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getidentitycertificateid(alljoyn_permissionconfigurator configurator, alljoyn_certificateid* certificateId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_permissionconfigurator_certificateid_cleanup(alljoyn_certificateid* certificateId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_updatepolicy(alljoyn_permissionconfigurator configurator, int8* policyXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getpolicy(alljoyn_permissionconfigurator configurator, int8** policyXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getdefaultpolicy(alljoyn_permissionconfigurator configurator, int8** policyXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_permissionconfigurator_policy_destroy(int8* policyXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_resetpolicy(alljoyn_permissionconfigurator configurator);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_getmembershipsummaries(alljoyn_permissionconfigurator configurator, alljoyn_certificateidarray* certificateIds);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_permissionconfigurator_certificateidarray_cleanup(alljoyn_certificateidarray* certificateIdArray);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_installmembership(alljoyn_permissionconfigurator configurator, int8* membershipCertificateChain);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_removemembership(alljoyn_permissionconfigurator configurator, uint8* serial, uint serialLen, int8* issuerPublicKey, uint8* issuerAki, uint issuerAkiLen);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_startmanagement(alljoyn_permissionconfigurator configurator);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_permissionconfigurator_endmanagement(alljoyn_permissionconfigurator configurator);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_applicationstatelistener alljoyn_applicationstatelistener_create(alljoyn_applicationstatelistener_callbacks* callbacks, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_applicationstatelistener_destroy(alljoyn_applicationstatelistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_keystorelistener alljoyn_keystorelistener_create(alljoyn_keystorelistener_callbacks* callbacks, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_keystorelistener alljoyn_keystorelistener_with_synchronization_create(alljoyn_keystorelistener_with_synchronization_callbacks* callbacks, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_keystorelistener_destroy(alljoyn_keystorelistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_keystorelistener_putkeys(alljoyn_keystorelistener listener, alljoyn_keystore keyStore, PSTR source, PSTR password);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_keystorelistener_getkeys(alljoyn_keystorelistener listener, alljoyn_keystore keyStore, PSTR sink, uint* sink_sz);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_sessionopts alljoyn_sessionopts_create(uint8 traffic, int32 isMultipoint, uint8 proximity, uint16 transports);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_sessionopts_destroy(alljoyn_sessionopts opts);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 alljoyn_sessionopts_get_traffic(alljoyn_sessionopts opts);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_sessionopts_set_traffic(alljoyn_sessionopts opts, uint8 traffic);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_sessionopts_get_multipoint(alljoyn_sessionopts opts);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_sessionopts_set_multipoint(alljoyn_sessionopts opts, int32 isMultipoint);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 alljoyn_sessionopts_get_proximity(alljoyn_sessionopts opts);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_sessionopts_set_proximity(alljoyn_sessionopts opts, uint8 proximity);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 alljoyn_sessionopts_get_transports(alljoyn_sessionopts opts);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_sessionopts_set_transports(alljoyn_sessionopts opts, uint16 transports);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_sessionopts_iscompatible(alljoyn_sessionopts one, alljoyn_sessionopts other);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_sessionopts_cmp(alljoyn_sessionopts one, alljoyn_sessionopts other);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_message alljoyn_message_create(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_message_destroy(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_message_isbroadcastsignal(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_message_isglobalbroadcast(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_message_issessionless(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 alljoyn_message_getflags(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_message_isexpired(alljoyn_message msg, uint32* tillExpireMS);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_message_isunreliable(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_message_isencrypted(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_message_getauthmechanism(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_messagetype alljoyn_message_gettype(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_message_getargs(alljoyn_message msg, uint* numArgs, alljoyn_msgarg* args);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_msgarg alljoyn_message_getarg(alljoyn_message msg, uint argN);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_message_parseargs(alljoyn_message msg, PSTR signature);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 alljoyn_message_getcallserial(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_message_getsignature(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_message_getobjectpath(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_message_getinterface(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_message_getmembername(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 alljoyn_message_getreplyserial(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_message_getsender(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_message_getreceiveendpointname(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_message_getdestination(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 alljoyn_message_getcompressiontoken(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 alljoyn_message_getsessionid(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_message_geterrorname(alljoyn_message msg, PSTR errorMessage, uint* errorMessage_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_message_tostring(alljoyn_message msg, PSTR str, uint buf);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_message_description(alljoyn_message msg, PSTR str, uint buf);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 alljoyn_message_gettimestamp(alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_message_eql(alljoyn_message one, alljoyn_message other);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_message_setendianess(int8 endian);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_authlistener_requestcredentialsresponse(alljoyn_authlistener listener, void* authContext, int32 accept, alljoyn_credentials credentials);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_authlistener_verifycredentialsresponse(alljoyn_authlistener listener, void* authContext, int32 accept);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_authlistener alljoyn_authlistener_create(alljoyn_authlistener_callbacks* callbacks, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_authlistener alljoyn_authlistenerasync_create(alljoyn_authlistenerasync_callbacks* callbacks, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_authlistener_destroy(alljoyn_authlistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_authlistenerasync_destroy(alljoyn_authlistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_authlistener_setsharedsecret(alljoyn_authlistener listener, uint8* sharedSecret, uint sharedSecretSize);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_credentials alljoyn_credentials_create();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_credentials_destroy(alljoyn_credentials cred);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_credentials_isset(alljoyn_credentials cred, uint16 creds);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_credentials_setpassword(alljoyn_credentials cred, PSTR pwd);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_credentials_setusername(alljoyn_credentials cred, PSTR userName);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_credentials_setcertchain(alljoyn_credentials cred, PSTR certChain);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_credentials_setprivatekey(alljoyn_credentials cred, PSTR pk);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_credentials_setlogonentry(alljoyn_credentials cred, PSTR logonEntry);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_credentials_setexpiration(alljoyn_credentials cred, uint32 expiration);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_credentials_getpassword(alljoyn_credentials cred);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_credentials_getusername(alljoyn_credentials cred);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_credentials_getcertchain(alljoyn_credentials cred);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_credentials_getprivateKey(alljoyn_credentials cred);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_credentials_getlogonentry(alljoyn_credentials cred);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 alljoyn_credentials_getexpiration(alljoyn_credentials cred);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_credentials_clear(alljoyn_credentials cred);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_buslistener alljoyn_buslistener_create(alljoyn_buslistener_callbacks* callbacks, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_buslistener_destroy(alljoyn_buslistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_member_getannotationscount(alljoyn_interfacedescription_member member);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_interfacedescription_member_getannotationatindex(alljoyn_interfacedescription_member member, uint index, PSTR name, uint* name_size, PSTR value, uint* value_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_member_getannotation(alljoyn_interfacedescription_member member, PSTR name, PSTR value, uint* value_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_member_getargannotationscount(alljoyn_interfacedescription_member member, PSTR argName);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_interfacedescription_member_getargannotationatindex(alljoyn_interfacedescription_member member, PSTR argName, uint index, PSTR name, uint* name_size, PSTR value, uint* value_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_member_getargannotation(alljoyn_interfacedescription_member member, PSTR argName, PSTR name, PSTR value, uint* value_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_property_getannotationscount(alljoyn_interfacedescription_property property);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_interfacedescription_property_getannotationatindex(alljoyn_interfacedescription_property property, uint index, PSTR name, uint* name_size, PSTR value, uint* value_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_property_getannotation(alljoyn_interfacedescription_property property, PSTR name, PSTR value, uint* value_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_interfacedescription_activate(alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_addannotation(alljoyn_interfacedescription iface, PSTR name, PSTR value);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_getannotation(alljoyn_interfacedescription iface, PSTR name, PSTR value, uint* value_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_getannotationscount(alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_interfacedescription_getannotationatindex(alljoyn_interfacedescription iface, uint index, PSTR name, uint* name_size, PSTR value, uint* value_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_getmember(alljoyn_interfacedescription iface, PSTR name, alljoyn_interfacedescription_member* member);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_addmember(alljoyn_interfacedescription iface, alljoyn_messagetype type, PSTR name, PSTR inputSig, PSTR outSig, PSTR argNames, uint8 annotation);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_addmemberannotation(alljoyn_interfacedescription iface, PSTR member, PSTR name, PSTR value);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_getmemberannotation(alljoyn_interfacedescription iface, PSTR member, PSTR name, PSTR value, uint* value_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_getmembers(alljoyn_interfacedescription iface, alljoyn_interfacedescription_member* members, uint numMembers);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_hasmember(alljoyn_interfacedescription iface, PSTR name, PSTR inSig, PSTR outSig);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_addmethod(alljoyn_interfacedescription iface, PSTR name, PSTR inputSig, PSTR outSig, PSTR argNames, uint8 annotation, PSTR accessPerms);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_getmethod(alljoyn_interfacedescription iface, PSTR name, alljoyn_interfacedescription_member* member);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_addsignal(alljoyn_interfacedescription iface, PSTR name, PSTR sig, PSTR argNames, uint8 annotation, PSTR accessPerms);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_getsignal(alljoyn_interfacedescription iface, PSTR name, alljoyn_interfacedescription_member* member);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_getproperty(alljoyn_interfacedescription iface, PSTR name, alljoyn_interfacedescription_property* property);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_getproperties(alljoyn_interfacedescription iface, alljoyn_interfacedescription_property* props, uint numProps);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_addproperty(alljoyn_interfacedescription iface, PSTR name, PSTR signature, uint8 access);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_addpropertyannotation(alljoyn_interfacedescription iface, PSTR property, PSTR name, PSTR value);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_getpropertyannotation(alljoyn_interfacedescription iface, PSTR property, PSTR name, PSTR value, uint* str_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_hasproperty(alljoyn_interfacedescription iface, PSTR name);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_hasproperties(alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_interfacedescription_getname(alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_introspect(alljoyn_interfacedescription iface, PSTR str, uint buf, uint indent);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_issecure(alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_interfacedescription_securitypolicy alljoyn_interfacedescription_getsecuritypolicy(alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_interfacedescription_setdescriptionlanguage(alljoyn_interfacedescription iface, PSTR language);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_getdescriptionlanguages(alljoyn_interfacedescription iface, int8** languages, uint size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_getdescriptionlanguages2(alljoyn_interfacedescription iface, PSTR languages, uint languagesSize);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_interfacedescription_setdescription(alljoyn_interfacedescription iface, PSTR description);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_setdescriptionforlanguage(alljoyn_interfacedescription iface, PSTR description, PSTR languageTag);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_getdescriptionforlanguage(alljoyn_interfacedescription iface, PSTR description, uint maxLanguageLength, PSTR languageTag);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_setmemberdescription(alljoyn_interfacedescription iface, PSTR member, PSTR description);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_setmemberdescriptionforlanguage(alljoyn_interfacedescription iface, PSTR member, PSTR description, PSTR languageTag);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_getmemberdescriptionforlanguage(alljoyn_interfacedescription iface, PSTR member, PSTR description, uint maxLanguageLength, PSTR languageTag);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_setargdescription(alljoyn_interfacedescription iface, PSTR member, PSTR argName, PSTR description);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_setargdescriptionforlanguage(alljoyn_interfacedescription iface, PSTR member, PSTR arg, PSTR description, PSTR languageTag);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_getargdescriptionforlanguage(alljoyn_interfacedescription iface, PSTR member, PSTR arg, PSTR description, uint maxLanguageLength, PSTR languageTag);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_setpropertydescription(alljoyn_interfacedescription iface, PSTR name, PSTR description);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_setpropertydescriptionforlanguage(alljoyn_interfacedescription iface, PSTR name, PSTR description, PSTR languageTag);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_interfacedescription_getpropertydescriptionforlanguage(alljoyn_interfacedescription iface, PSTR property, PSTR description, uint maxLanguageLength, PSTR languageTag);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_interfacedescription_setdescriptiontranslationcallback(alljoyn_interfacedescription iface, alljoyn_interfacedescription_translation_callback_ptr translationCallback);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_interfacedescription_translation_callback_ptr alljoyn_interfacedescription_getdescriptiontranslationcallback(alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_hasdescription(alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_interfacedescription_addargannotation(alljoyn_interfacedescription iface, PSTR member, PSTR argName, PSTR name, PSTR value);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_getmemberargannotation(alljoyn_interfacedescription iface, PSTR member, PSTR argName, PSTR name, PSTR value, uint* value_size);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_eql(alljoyn_interfacedescription one, alljoyn_interfacedescription other);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_member_eql(alljoyn_interfacedescription_member one, alljoyn_interfacedescription_member other);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_interfacedescription_property_eql(alljoyn_interfacedescription_property one, alljoyn_interfacedescription_property other);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_busobject alljoyn_busobject_create(PSTR path, int32 isPlaceholder, alljoyn_busobject_callbacks* callbacks_in, void* context_in);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busobject_destroy(alljoyn_busobject bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_busobject_getpath(alljoyn_busobject bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busobject_emitpropertychanged(alljoyn_busobject bus, PSTR ifcName, PSTR propName, alljoyn_msgarg val, uint32 id);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busobject_emitpropertieschanged(alljoyn_busobject bus, PSTR ifcName, int8** propNames, uint numProps, uint32 id);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_busobject_getname(alljoyn_busobject bus, PSTR buffer, uint bufferSz);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_addinterface(alljoyn_busobject bus, alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_addmethodhandler(alljoyn_busobject bus, alljoyn_interfacedescription_member member, alljoyn_messagereceiver_methodhandler_ptr handler, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_addmethodhandlers(alljoyn_busobject bus, alljoyn_busobject_methodentry* entries, uint numEntries);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_methodreply_args(alljoyn_busobject bus, alljoyn_message msg, alljoyn_msgarg args, uint numArgs);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_methodreply_err(alljoyn_busobject bus, alljoyn_message msg, PSTR error, PSTR errorMessage);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_methodreply_status(alljoyn_busobject bus, alljoyn_message msg, QStatus status);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_busattachment alljoyn_busobject_getbusattachment(alljoyn_busobject bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_signal(alljoyn_busobject bus, PSTR destination, uint32 sessionId, alljoyn_interfacedescription_member signal, alljoyn_msgarg args, uint numArgs, uint16 timeToLive, uint8 flags, alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_cancelsessionlessmessage_serial(alljoyn_busobject bus, uint32 serialNumber);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_cancelsessionlessmessage(alljoyn_busobject bus, alljoyn_message msg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_busobject_issecure(alljoyn_busobject bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_busobject_getannouncedinterfacenames(alljoyn_busobject bus, int8** interfaces, uint numInterfaces);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_setannounceflag(alljoyn_busobject bus, alljoyn_interfacedescription iface, alljoyn_about_announceflag isAnnounced);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busobject_addinterface_announced(alljoyn_busobject bus, alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject alljoyn_proxybusobject_create(alljoyn_busattachment bus, PSTR service, PSTR path, uint32 sessionId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject alljoyn_proxybusobject_create_secure(alljoyn_busattachment bus, PSTR service, PSTR path, uint32 sessionId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_proxybusobject_destroy(alljoyn_proxybusobject proxyObj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_addinterface(alljoyn_proxybusobject proxyObj, alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_addinterface_by_name(alljoyn_proxybusobject proxyObj, PSTR name);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_proxybusobject_getchildren(alljoyn_proxybusobject proxyObj, alljoyn_proxybusobject* children, uint numChildren);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject alljoyn_proxybusobject_getchild(alljoyn_proxybusobject proxyObj, PSTR path);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_addchild(alljoyn_proxybusobject proxyObj, alljoyn_proxybusobject child);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_removechild(alljoyn_proxybusobject proxyObj, PSTR path);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_introspectremoteobject(alljoyn_proxybusobject proxyObj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_introspectremoteobjectasync(alljoyn_proxybusobject proxyObj, alljoyn_proxybusobject_listener_introspectcb_ptr callback, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_getproperty(alljoyn_proxybusobject proxyObj, PSTR iface, PSTR property, alljoyn_msgarg value);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_getpropertyasync(alljoyn_proxybusobject proxyObj, PSTR iface, PSTR property, alljoyn_proxybusobject_listener_getpropertycb_ptr callback, uint32 timeout, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_getallproperties(alljoyn_proxybusobject proxyObj, PSTR iface, alljoyn_msgarg values);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_getallpropertiesasync(alljoyn_proxybusobject proxyObj, PSTR iface, alljoyn_proxybusobject_listener_getallpropertiescb_ptr callback, uint32 timeout, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_setproperty(alljoyn_proxybusobject proxyObj, PSTR iface, PSTR property, alljoyn_msgarg value);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_registerpropertieschangedlistener(alljoyn_proxybusobject proxyObj, PSTR iface, int8** properties, uint numProperties, alljoyn_proxybusobject_listener_propertieschanged_ptr callback, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_unregisterpropertieschangedlistener(alljoyn_proxybusobject proxyObj, PSTR iface, alljoyn_proxybusobject_listener_propertieschanged_ptr callback);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_setpropertyasync(alljoyn_proxybusobject proxyObj, PSTR iface, PSTR property, alljoyn_msgarg value, alljoyn_proxybusobject_listener_setpropertycb_ptr callback, uint32 timeout, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_methodcall(alljoyn_proxybusobject proxyObj, PSTR ifaceName, PSTR methodName, alljoyn_msgarg args, uint numArgs, alljoyn_message replyMsg, uint32 timeout, uint8 flags);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_methodcall_member(alljoyn_proxybusobject proxyObj, alljoyn_interfacedescription_member method, alljoyn_msgarg args, uint numArgs, alljoyn_message replyMsg, uint32 timeout, uint8 flags);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_methodcall_noreply(alljoyn_proxybusobject proxyObj, PSTR ifaceName, PSTR methodName, alljoyn_msgarg args, uint numArgs, uint8 flags);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_methodcall_member_noreply(alljoyn_proxybusobject proxyObj, alljoyn_interfacedescription_member method, alljoyn_msgarg args, uint numArgs, uint8 flags);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_methodcallasync(alljoyn_proxybusobject proxyObj, PSTR ifaceName, PSTR methodName, alljoyn_messagereceiver_replyhandler_ptr replyFunc, alljoyn_msgarg args, uint numArgs, void* context, uint32 timeout, uint8 flags);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_methodcallasync_member(alljoyn_proxybusobject proxyObj, alljoyn_interfacedescription_member method, alljoyn_messagereceiver_replyhandler_ptr replyFunc, alljoyn_msgarg args, uint numArgs, void* context, uint32 timeout, uint8 flags);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_parsexml(alljoyn_proxybusobject proxyObj, PSTR xml, PSTR identifier);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_secureconnection(alljoyn_proxybusobject proxyObj, int32 forceAuth);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_proxybusobject_secureconnectionasync(alljoyn_proxybusobject proxyObj, int32 forceAuth);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_interfacedescription alljoyn_proxybusobject_getinterface(alljoyn_proxybusobject proxyObj, PSTR iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_proxybusobject_getinterfaces(alljoyn_proxybusobject proxyObj, alljoyn_interfacedescription* ifaces, uint numIfaces);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_proxybusobject_getpath(alljoyn_proxybusobject proxyObj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_proxybusobject_getservicename(alljoyn_proxybusobject proxyObj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_proxybusobject_getuniquename(alljoyn_proxybusobject proxyObj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 alljoyn_proxybusobject_getsessionid(alljoyn_proxybusobject proxyObj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_proxybusobject_implementsinterface(alljoyn_proxybusobject proxyObj, PSTR iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject alljoyn_proxybusobject_copy(alljoyn_proxybusobject source);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_proxybusobject_isvalid(alljoyn_proxybusobject proxyObj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_proxybusobject_issecure(alljoyn_proxybusobject proxyObj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_proxybusobject_enablepropertycaching(alljoyn_proxybusobject proxyObj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_permissionconfigurationlistener alljoyn_permissionconfigurationlistener_create(alljoyn_permissionconfigurationlistener_callbacks* callbacks, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_permissionconfigurationlistener_destroy(alljoyn_permissionconfigurationlistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_sessionlistener alljoyn_sessionlistener_create(alljoyn_sessionlistener_callbacks* callbacks, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_sessionlistener_destroy(alljoyn_sessionlistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_sessionportlistener alljoyn_sessionportlistener_create(alljoyn_sessionportlistener_callbacks* callbacks, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_sessionportlistener_destroy(alljoyn_sessionportlistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_aboutlistener alljoyn_aboutlistener_create(alljoyn_aboutlistener_callback* callback, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_aboutlistener_destroy(alljoyn_aboutlistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_busattachment alljoyn_busattachment_create(PSTR applicationName, int32 allowRemoteMessages);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_busattachment alljoyn_busattachment_create_concurrency(PSTR applicationName, int32 allowRemoteMessages, uint32 concurrency);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busattachment_destroy(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_start(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_stop(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_join(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 alljoyn_busattachment_getconcurrency(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_busattachment_getconnectspec(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busattachment_enableconcurrentcallbacks(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_createinterface(alljoyn_busattachment bus, PSTR name, alljoyn_interfacedescription* iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_createinterface_secure(alljoyn_busattachment bus, PSTR name, alljoyn_interfacedescription* iface, alljoyn_interfacedescription_securitypolicy secPolicy);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_connect(alljoyn_busattachment bus, PSTR connectSpec);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busattachment_registerbuslistener(alljoyn_busattachment bus, alljoyn_buslistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busattachment_unregisterbuslistener(alljoyn_busattachment bus, alljoyn_buslistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_findadvertisedname(alljoyn_busattachment bus, PSTR namePrefix);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_findadvertisednamebytransport(alljoyn_busattachment bus, PSTR namePrefix, uint16 transports);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_cancelfindadvertisedname(alljoyn_busattachment bus, PSTR namePrefix);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_cancelfindadvertisednamebytransport(alljoyn_busattachment bus, PSTR namePrefix, uint16 transports);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_advertisename(alljoyn_busattachment bus, PSTR name, uint16 transports);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_canceladvertisename(alljoyn_busattachment bus, PSTR name, uint16 transports);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_interfacedescription alljoyn_busattachment_getinterface(alljoyn_busattachment bus, PSTR name);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_joinsession(alljoyn_busattachment bus, PSTR sessionHost, uint16 sessionPort, alljoyn_sessionlistener listener, uint32* sessionId, alljoyn_sessionopts opts);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_joinsessionasync(alljoyn_busattachment bus, PSTR sessionHost, uint16 sessionPort, alljoyn_sessionlistener listener, alljoyn_sessionopts opts, alljoyn_busattachment_joinsessioncb_ptr callback, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_registerbusobject(alljoyn_busattachment bus, alljoyn_busobject obj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_registerbusobject_secure(alljoyn_busattachment bus, alljoyn_busobject obj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busattachment_unregisterbusobject(alljoyn_busattachment bus, alljoyn_busobject object);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_requestname(alljoyn_busattachment bus, PSTR requestedName, uint32 flags);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_releasename(alljoyn_busattachment bus, PSTR name);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_bindsessionport(alljoyn_busattachment bus, uint16* sessionPort, alljoyn_sessionopts opts, alljoyn_sessionportlistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_unbindsessionport(alljoyn_busattachment bus, uint16 sessionPort);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_enablepeersecurity(alljoyn_busattachment bus, PSTR authMechanisms, alljoyn_authlistener listener, PSTR keyStoreFileName, int32 isShared);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_enablepeersecuritywithpermissionconfigurationlistener(alljoyn_busattachment bus, PSTR authMechanisms, alljoyn_authlistener authListener, PSTR keyStoreFileName, int32 isShared, alljoyn_permissionconfigurationlistener permissionConfigurationListener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_busattachment_ispeersecurityenabled(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_createinterfacesfromxml(alljoyn_busattachment bus, PSTR xml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_busattachment_getinterfaces(alljoyn_busattachment bus, alljoyn_interfacedescription* ifaces, uint numIfaces);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_deleteinterface(alljoyn_busattachment bus, alljoyn_interfacedescription iface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_busattachment_isstarted(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_busattachment_isstopping(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 alljoyn_busattachment_isconnected(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_disconnect(alljoyn_busattachment bus, PSTR unused);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject alljoyn_busattachment_getdbusproxyobj(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject alljoyn_busattachment_getalljoynproxyobj(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject alljoyn_busattachment_getalljoyndebugobj(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_busattachment_getuniquename(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_busattachment_getglobalguidstring(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_registersignalhandler(alljoyn_busattachment bus, alljoyn_messagereceiver_signalhandler_ptr signal_handler, alljoyn_interfacedescription_member member, PSTR srcPath);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_registersignalhandlerwithrule(alljoyn_busattachment bus, alljoyn_messagereceiver_signalhandler_ptr signal_handler, alljoyn_interfacedescription_member member, PSTR matchRule);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_unregistersignalhandler(alljoyn_busattachment bus, alljoyn_messagereceiver_signalhandler_ptr signal_handler, alljoyn_interfacedescription_member member, PSTR srcPath);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_unregistersignalhandlerwithrule(alljoyn_busattachment bus, alljoyn_messagereceiver_signalhandler_ptr signal_handler, alljoyn_interfacedescription_member member, PSTR matchRule);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_unregisterallhandlers(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_registerkeystorelistener(alljoyn_busattachment bus, alljoyn_keystorelistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_reloadkeystore(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busattachment_clearkeystore(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_clearkeys(alljoyn_busattachment bus, PSTR guid);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_setkeyexpiration(alljoyn_busattachment bus, PSTR guid, uint32 timeout);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_getkeyexpiration(alljoyn_busattachment bus, PSTR guid, uint32* timeout);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_addlogonentry(alljoyn_busattachment bus, PSTR authMechanism, PSTR userName, PSTR password);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_addmatch(alljoyn_busattachment bus, PSTR rule);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_removematch(alljoyn_busattachment bus, PSTR rule);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_setsessionlistener(alljoyn_busattachment bus, uint32 sessionId, alljoyn_sessionlistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_leavesession(alljoyn_busattachment bus, uint32 sessionId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_secureconnection(alljoyn_busattachment bus, PSTR name, int32 forceAuth);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_secureconnectionasync(alljoyn_busattachment bus, PSTR name, int32 forceAuth);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_removesessionmember(alljoyn_busattachment bus, uint32 sessionId, PSTR memberName);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_setlinktimeout(alljoyn_busattachment bus, uint32 sessionid, uint32* linkTimeout);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_setlinktimeoutasync(alljoyn_busattachment bus, uint32 sessionid, uint32 linkTimeout, alljoyn_busattachment_setlinktimeoutcb_ptr callback, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_namehasowner(alljoyn_busattachment bus, PSTR name, int32* hasOwner);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_getpeerguid(alljoyn_busattachment bus, PSTR name, PSTR guid, uint* guidSz);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_setdaemondebug(alljoyn_busattachment bus, PSTR module, uint32 level);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 alljoyn_busattachment_gettimestamp();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_ping(alljoyn_busattachment bus, PSTR name, uint32 timeout);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busattachment_registeraboutlistener(alljoyn_busattachment bus, alljoyn_aboutlistener aboutListener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busattachment_unregisteraboutlistener(alljoyn_busattachment bus, alljoyn_aboutlistener aboutListener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_busattachment_unregisterallaboutlisteners(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_whoimplements_interfaces(alljoyn_busattachment bus, int8** implementsInterfaces, uint numberInterfaces);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_whoimplements_interface(alljoyn_busattachment bus, PSTR implementsInterface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_cancelwhoimplements_interfaces(alljoyn_busattachment bus, int8** implementsInterfaces, uint numberInterfaces);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_cancelwhoimplements_interface(alljoyn_busattachment bus, PSTR implementsInterface);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_permissionconfigurator alljoyn_busattachment_getpermissionconfigurator(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_registerapplicationstatelistener(alljoyn_busattachment bus, alljoyn_applicationstatelistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_unregisterapplicationstatelistener(alljoyn_busattachment bus, alljoyn_applicationstatelistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_busattachment_deletedefaultkeystore(PSTR applicationName);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _alljoyn_abouticonobj_handle* alljoyn_abouticonobj_create(alljoyn_busattachment bus, _alljoyn_abouticon_handle* icon);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_abouticonobj_destroy(_alljoyn_abouticonobj_handle* icon);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _alljoyn_abouticonproxy_handle* alljoyn_abouticonproxy_create(alljoyn_busattachment bus, PSTR busName, uint32 sessionId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_abouticonproxy_destroy(_alljoyn_abouticonproxy_handle* proxy);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_abouticonproxy_geticon(_alljoyn_abouticonproxy_handle* proxy, _alljoyn_abouticon_handle* icon);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_abouticonproxy_getversion(_alljoyn_abouticonproxy_handle* proxy, uint16* version);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_aboutdatalistener alljoyn_aboutdatalistener_create(alljoyn_aboutdatalistener_callbacks* callbacks, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_aboutdatalistener_destroy(alljoyn_aboutdatalistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_aboutobj alljoyn_aboutobj_create(alljoyn_busattachment bus, alljoyn_about_announceflag isAnnounced);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_aboutobj_destroy(alljoyn_aboutobj obj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutobj_announce(alljoyn_aboutobj obj, uint16 sessionPort, alljoyn_aboutdata aboutData);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutobj_announce_using_datalistener(alljoyn_aboutobj obj, uint16 sessionPort, alljoyn_aboutdatalistener aboutListener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutobj_unannounce(alljoyn_aboutobj obj);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_aboutobjectdescription alljoyn_aboutobjectdescription_create();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_aboutobjectdescription alljoyn_aboutobjectdescription_create_full(alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutobjectdescription_createfrommsgarg(alljoyn_aboutobjectdescription description, alljoyn_msgarg arg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_aboutobjectdescription_destroy(alljoyn_aboutobjectdescription description);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_aboutobjectdescription_getpaths(alljoyn_aboutobjectdescription description, int8** paths, uint numPaths);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_aboutobjectdescription_getinterfaces(alljoyn_aboutobjectdescription description, PSTR path, int8** interfaces, uint numInterfaces);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint alljoyn_aboutobjectdescription_getinterfacepaths(alljoyn_aboutobjectdescription description, PSTR interfaceName, int8** paths, uint numPaths);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_aboutobjectdescription_clear(alljoyn_aboutobjectdescription description);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 alljoyn_aboutobjectdescription_haspath(alljoyn_aboutobjectdescription description, PSTR path);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 alljoyn_aboutobjectdescription_hasinterface(alljoyn_aboutobjectdescription description, PSTR interfaceName);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 alljoyn_aboutobjectdescription_hasinterfaceatpath(alljoyn_aboutobjectdescription description, PSTR path, PSTR interfaceName);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutobjectdescription_getmsgarg(alljoyn_aboutobjectdescription description, alljoyn_msgarg msgArg);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_aboutproxy alljoyn_aboutproxy_create(alljoyn_busattachment bus, PSTR busName, uint32 sessionId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_aboutproxy_destroy(alljoyn_aboutproxy proxy);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutproxy_getobjectdescription(alljoyn_aboutproxy proxy, alljoyn_msgarg objectDesc);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutproxy_getaboutdata(alljoyn_aboutproxy proxy, PSTR language, alljoyn_msgarg data);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_aboutproxy_getversion(alljoyn_aboutproxy proxy, uint16* version);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_pinglistener alljoyn_pinglistener_create(alljoyn_pinglistener_callback* callback, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_pinglistener_destroy(alljoyn_pinglistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_autopinger alljoyn_autopinger_create(alljoyn_busattachment bus);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_autopinger_destroy(alljoyn_autopinger autopinger);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_autopinger_pause(alljoyn_autopinger autopinger);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_autopinger_resume(alljoyn_autopinger autopinger);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_autopinger_addpinggroup(alljoyn_autopinger autopinger, PSTR group, alljoyn_pinglistener listener, uint32 pinginterval);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_autopinger_removepinggroup(alljoyn_autopinger autopinger, PSTR group);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_autopinger_setpinginterval(alljoyn_autopinger autopinger, PSTR group, uint32 pinginterval);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_autopinger_adddestination(alljoyn_autopinger autopinger, PSTR group, PSTR destination);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_autopinger_removedestination(alljoyn_autopinger autopinger, PSTR group, PSTR destination, int32 removeall);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_getversion();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR alljoyn_getbuildinfo();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 alljoyn_getnumericversion();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_init();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_shutdown();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_routerinit();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_routerinitwithconfig(int8* configXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_routershutdown();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject_ref alljoyn_proxybusobject_ref_create(alljoyn_proxybusobject proxy);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject alljoyn_proxybusobject_ref_get(alljoyn_proxybusobject_ref @ref);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_proxybusobject_ref_incref(alljoyn_proxybusobject_ref @ref);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_proxybusobject_ref_decref(alljoyn_proxybusobject_ref @ref);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_observerlistener alljoyn_observerlistener_create(alljoyn_observerlistener_callback* callback, void* context);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_observerlistener_destroy(alljoyn_observerlistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_observer alljoyn_observer_create(alljoyn_busattachment bus, int8** mandatoryInterfaces, uint numMandatoryInterfaces);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_observer_destroy(alljoyn_observer observer);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_observer_registerlistener(alljoyn_observer observer, alljoyn_observerlistener listener, int32 triggerOnExisting);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_observer_unregisterlistener(alljoyn_observer observer, alljoyn_observerlistener listener);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_observer_unregisteralllisteners(alljoyn_observer observer);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject_ref alljoyn_observer_get(alljoyn_observer observer, PSTR uniqueBusName, PSTR objectPath);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject_ref alljoyn_observer_getfirst(alljoyn_observer observer);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_proxybusobject_ref alljoyn_observer_getnext(alljoyn_observer observer, alljoyn_proxybusobject_ref proxyref);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_passwordmanager_setcredentials(PSTR authMechanism, PSTR password);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 alljoyn_securityapplicationproxy_getpermissionmanagementsessionport();

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern alljoyn_securityapplicationproxy alljoyn_securityapplicationproxy_create(alljoyn_busattachment bus, int8* appBusName, uint32 sessionId);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_securityapplicationproxy_destroy(alljoyn_securityapplicationproxy proxy);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_claim(alljoyn_securityapplicationproxy proxy, int8* caKey, int8* identityCertificateChain, uint8* groupId, uint groupSize, int8* groupAuthority, int8** manifestsXmls, uint manifestsCount);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_getmanifesttemplate(alljoyn_securityapplicationproxy proxy, int8** manifestTemplateXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_securityapplicationproxy_manifesttemplate_destroy(int8* manifestTemplateXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_getapplicationstate(alljoyn_securityapplicationproxy proxy, alljoyn_applicationstate* applicationState);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_getclaimcapabilities(alljoyn_securityapplicationproxy proxy, uint16* capabilities);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_getclaimcapabilitiesadditionalinfo(alljoyn_securityapplicationproxy proxy, uint16* additionalInfo);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_getpolicy(alljoyn_securityapplicationproxy proxy, int8** policyXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_getdefaultpolicy(alljoyn_securityapplicationproxy proxy, int8** policyXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_securityapplicationproxy_policy_destroy(int8* policyXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_updatepolicy(alljoyn_securityapplicationproxy proxy, int8* policyXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_updateidentity(alljoyn_securityapplicationproxy proxy, int8* identityCertificateChain, int8** manifestsXmls, uint manifestsCount);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_installmembership(alljoyn_securityapplicationproxy proxy, int8* membershipCertificateChain);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_reset(alljoyn_securityapplicationproxy proxy);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_resetpolicy(alljoyn_securityapplicationproxy proxy);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_startmanagement(alljoyn_securityapplicationproxy proxy);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_endmanagement(alljoyn_securityapplicationproxy proxy);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_geteccpublickey(alljoyn_securityapplicationproxy proxy, int8** eccPublicKey);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_securityapplicationproxy_eccpublickey_destroy(int8* eccPublicKey);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_signmanifest(int8* unsignedManifestXml, int8* identityCertificatePem, int8* signingPrivateKeyPem, int8** signedManifestXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_securityapplicationproxy_manifest_destroy(int8* signedManifestXml);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_computemanifestdigest(int8* unsignedManifestXml, int8* identityCertificatePem, uint8** digest, uint* digestSize);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void alljoyn_securityapplicationproxy_digest_destroy(uint8* digest);

	[Import("MSAJApi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern QStatus alljoyn_securityapplicationproxy_setmanifestsignature(int8* unsignedManifestXml, int8* identityCertificatePem, uint8* signature, uint signatureSize, int8** signedManifestXml);

}
#endregion
