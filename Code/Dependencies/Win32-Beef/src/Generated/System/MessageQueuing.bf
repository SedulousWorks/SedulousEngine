using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.System.MessageQueuing;

#region Constants
public static
{
	public const uint32 PRLT = 0;
	public const uint32 PRLE = 1;
	public const uint32 PRGT = 2;
	public const uint32 PRGE = 3;
	public const uint32 PREQ = 4;
	public const uint32 PRNE = 5;
	public const uint32 QUERY_SORTASCEND = 0;
	public const uint32 QUERY_SORTDESCEND = 1;
	public const uint32 MQ_MOVE_ACCESS = 4;
	public const uint32 MQ_ACTION_RECEIVE = 0;
	public const uint32 MQ_ACTION_PEEK_CURRENT = 2147483648;
	public const uint32 MQ_ACTION_PEEK_NEXT = 2147483649;
	public const uint32 MQ_LOOKUP_PEEK_CURRENT = 1073741840;
	public const uint32 MQ_LOOKUP_PEEK_NEXT = 1073741841;
	public const uint32 MQ_LOOKUP_PEEK_PREV = 1073741842;
	public const uint32 MQ_LOOKUP_PEEK_FIRST = 1073741844;
	public const uint32 MQ_LOOKUP_PEEK_LAST = 1073741848;
	public const uint32 MQ_LOOKUP_RECEIVE_CURRENT = 1073741856;
	public const uint32 MQ_LOOKUP_RECEIVE_NEXT = 1073741857;
	public const uint32 MQ_LOOKUP_RECEIVE_PREV = 1073741858;
	public const uint32 MQ_LOOKUP_RECEIVE_FIRST = 1073741860;
	public const uint32 MQ_LOOKUP_RECEIVE_LAST = 1073741864;
	public const uint32 MQ_LOOKUP_RECEIVE_ALLOW_PEEK = 1073742112;
	public const uint32 PROPID_M_BASE = 0;
	public const uint32 PROPID_M_CLASS = 1;
	public const uint32 PROPID_M_MSGID = 2;
	public const uint32 PROPID_M_CORRELATIONID = 3;
	public const uint32 PROPID_M_PRIORITY = 4;
	public const uint32 PROPID_M_DELIVERY = 5;
	public const uint32 PROPID_M_ACKNOWLEDGE = 6;
	public const uint32 PROPID_M_JOURNAL = 7;
	public const uint32 PROPID_M_APPSPECIFIC = 8;
	public const uint32 PROPID_M_BODY = 9;
	public const uint32 PROPID_M_BODY_SIZE = 10;
	public const uint32 PROPID_M_LABEL = 11;
	public const uint32 PROPID_M_LABEL_LEN = 12;
	public const uint32 PROPID_M_TIME_TO_REACH_QUEUE = 13;
	public const uint32 PROPID_M_TIME_TO_BE_RECEIVED = 14;
	public const uint32 PROPID_M_RESP_QUEUE = 15;
	public const uint32 PROPID_M_RESP_QUEUE_LEN = 16;
	public const uint32 PROPID_M_ADMIN_QUEUE = 17;
	public const uint32 PROPID_M_ADMIN_QUEUE_LEN = 18;
	public const uint32 PROPID_M_VERSION = 19;
	public const uint32 PROPID_M_SENDERID = 20;
	public const uint32 PROPID_M_SENDERID_LEN = 21;
	public const uint32 PROPID_M_SENDERID_TYPE = 22;
	public const uint32 PROPID_M_PRIV_LEVEL = 23;
	public const uint32 PROPID_M_AUTH_LEVEL = 24;
	public const uint32 PROPID_M_AUTHENTICATED = 25;
	public const uint32 PROPID_M_HASH_ALG = 26;
	public const uint32 PROPID_M_ENCRYPTION_ALG = 27;
	public const uint32 PROPID_M_SENDER_CERT = 28;
	public const uint32 PROPID_M_SENDER_CERT_LEN = 29;
	public const uint32 PROPID_M_SRC_MACHINE_ID = 30;
	public const uint32 PROPID_M_SENTTIME = 31;
	public const uint32 PROPID_M_ARRIVEDTIME = 32;
	public const uint32 PROPID_M_DEST_QUEUE = 33;
	public const uint32 PROPID_M_DEST_QUEUE_LEN = 34;
	public const uint32 PROPID_M_EXTENSION = 35;
	public const uint32 PROPID_M_EXTENSION_LEN = 36;
	public const uint32 PROPID_M_SECURITY_CONTEXT = 37;
	public const uint32 PROPID_M_CONNECTOR_TYPE = 38;
	public const uint32 PROPID_M_XACT_STATUS_QUEUE = 39;
	public const uint32 PROPID_M_XACT_STATUS_QUEUE_LEN = 40;
	public const uint32 PROPID_M_TRACE = 41;
	public const uint32 PROPID_M_BODY_TYPE = 42;
	public const uint32 PROPID_M_DEST_SYMM_KEY = 43;
	public const uint32 PROPID_M_DEST_SYMM_KEY_LEN = 44;
	public const uint32 PROPID_M_SIGNATURE = 45;
	public const uint32 PROPID_M_SIGNATURE_LEN = 46;
	public const uint32 PROPID_M_PROV_TYPE = 47;
	public const uint32 PROPID_M_PROV_NAME = 48;
	public const uint32 PROPID_M_PROV_NAME_LEN = 49;
	public const uint32 PROPID_M_FIRST_IN_XACT = 50;
	public const uint32 PROPID_M_LAST_IN_XACT = 51;
	public const uint32 PROPID_M_XACTID = 52;
	public const uint32 PROPID_M_AUTHENTICATED_EX = 53;
	public const uint32 PROPID_M_RESP_FORMAT_NAME = 54;
	public const uint32 PROPID_M_RESP_FORMAT_NAME_LEN = 55;
	public const uint32 PROPID_M_DEST_FORMAT_NAME = 58;
	public const uint32 PROPID_M_DEST_FORMAT_NAME_LEN = 59;
	public const uint32 PROPID_M_LOOKUPID = 60;
	public const uint32 PROPID_M_SOAP_ENVELOPE = 61;
	public const uint32 PROPID_M_SOAP_ENVELOPE_LEN = 62;
	public const uint32 PROPID_M_COMPOUND_MESSAGE = 63;
	public const uint32 PROPID_M_COMPOUND_MESSAGE_SIZE = 64;
	public const uint32 PROPID_M_SOAP_HEADER = 65;
	public const uint32 PROPID_M_SOAP_BODY = 66;
	public const uint32 PROPID_M_DEADLETTER_QUEUE = 67;
	public const uint32 PROPID_M_DEADLETTER_QUEUE_LEN = 68;
	public const uint32 PROPID_M_ABORT_COUNT = 69;
	public const uint32 PROPID_M_MOVE_COUNT = 70;
	public const uint32 PROPID_M_LAST_MOVE_TIME = 75;
	public const uint32 PROPID_M_MSGID_SIZE = 20;
	public const uint32 PROPID_M_CORRELATIONID_SIZE = 20;
	public const uint32 PROPID_M_XACTID_SIZE = 20;
	public const uint32 MQMSG_PRIV_LEVEL_BODY_AES = 5;
	public const uint32 MQMSG_AUTHENTICATED_QM_MESSAGE = 11;
	public const uint32 MQMSG_NOT_FIRST_IN_XACT = 0;
	public const uint32 MQMSG_FIRST_IN_XACT = 1;
	public const uint32 MQMSG_NOT_LAST_IN_XACT = 0;
	public const uint32 MQMSG_LAST_IN_XACT = 1;
	public const uint32 PROPID_Q_BASE = 100;
	public const uint32 PROPID_Q_INSTANCE = 101;
	public const uint32 PROPID_Q_TYPE = 102;
	public const uint32 PROPID_Q_PATHNAME = 103;
	public const uint32 PROPID_Q_JOURNAL = 104;
	public const uint32 PROPID_Q_QUOTA = 105;
	public const uint32 PROPID_Q_BASEPRIORITY = 106;
	public const uint32 PROPID_Q_JOURNAL_QUOTA = 107;
	public const uint32 PROPID_Q_LABEL = 108;
	public const uint32 PROPID_Q_CREATE_TIME = 109;
	public const uint32 PROPID_Q_MODIFY_TIME = 110;
	public const uint32 PROPID_Q_AUTHENTICATE = 111;
	public const uint32 PROPID_Q_PRIV_LEVEL = 112;
	public const uint32 PROPID_Q_TRANSACTION = 113;
	public const uint32 PROPID_Q_PATHNAME_DNS = 124;
	public const uint32 PROPID_Q_MULTICAST_ADDRESS = 125;
	public const uint32 PROPID_Q_ADS_PATH = 126;
	public const uint32 PROPID_QM_BASE = 200;
	public const uint32 PROPID_QM_SITE_ID = 201;
	public const uint32 PROPID_QM_MACHINE_ID = 202;
	public const uint32 PROPID_QM_PATHNAME = 203;
	public const uint32 PROPID_QM_CONNECTION = 204;
	public const uint32 PROPID_QM_ENCRYPTION_PK = 205;
	public const uint32 PROPID_QM_ENCRYPTION_PK_BASE = 231;
	public const uint32 PROPID_QM_ENCRYPTION_PK_ENHANCED = 232;
	public const uint32 PROPID_QM_PATHNAME_DNS = 233;
	public const uint32 PROPID_QM_ENCRYPTION_PK_AES = 244;
	public const uint32 PROPID_PC_BASE = 5800;
	public const uint32 PROPID_PC_VERSION = 5801;
	public const uint32 PROPID_PC_DS_ENABLED = 5802;
	public const uint32 PROPID_MGMT_MSMQ_BASE = 0;
	public const uint32 PROPID_MGMT_MSMQ_ACTIVEQUEUES = 1;
	public const uint32 PROPID_MGMT_MSMQ_PRIVATEQ = 2;
	public const uint32 PROPID_MGMT_MSMQ_DSSERVER = 3;
	public const uint32 PROPID_MGMT_MSMQ_CONNECTED = 4;
	public const uint32 PROPID_MGMT_MSMQ_TYPE = 5;
	public const uint32 PROPID_MGMT_MSMQ_BYTES_IN_ALL_QUEUES = 6;
	public const String MSMQ_CONNECTED = "CONNECTED";
	public const String MSMQ_DISCONNECTED = "DISCONNECTED";
	public const uint32 PROPID_MGMT_QUEUE_BASE = 0;
	public const uint32 PROPID_MGMT_QUEUE_PATHNAME = 1;
	public const uint32 PROPID_MGMT_QUEUE_FORMATNAME = 2;
	public const uint32 PROPID_MGMT_QUEUE_TYPE = 3;
	public const uint32 PROPID_MGMT_QUEUE_LOCATION = 4;
	public const uint32 PROPID_MGMT_QUEUE_XACT = 5;
	public const uint32 PROPID_MGMT_QUEUE_FOREIGN = 6;
	public const uint32 PROPID_MGMT_QUEUE_MESSAGE_COUNT = 7;
	public const uint32 PROPID_MGMT_QUEUE_BYTES_IN_QUEUE = 8;
	public const uint32 PROPID_MGMT_QUEUE_JOURNAL_MESSAGE_COUNT = 9;
	public const uint32 PROPID_MGMT_QUEUE_BYTES_IN_JOURNAL = 10;
	public const uint32 PROPID_MGMT_QUEUE_STATE = 11;
	public const uint32 PROPID_MGMT_QUEUE_NEXTHOPS = 12;
	public const uint32 PROPID_MGMT_QUEUE_EOD_LAST_ACK = 13;
	public const uint32 PROPID_MGMT_QUEUE_EOD_LAST_ACK_TIME = 14;
	public const uint32 PROPID_MGMT_QUEUE_EOD_LAST_ACK_COUNT = 15;
	public const uint32 PROPID_MGMT_QUEUE_EOD_FIRST_NON_ACK = 16;
	public const uint32 PROPID_MGMT_QUEUE_EOD_LAST_NON_ACK = 17;
	public const uint32 PROPID_MGMT_QUEUE_EOD_NEXT_SEQ = 18;
	public const uint32 PROPID_MGMT_QUEUE_EOD_NO_READ_COUNT = 19;
	public const uint32 PROPID_MGMT_QUEUE_EOD_NO_ACK_COUNT = 20;
	public const uint32 PROPID_MGMT_QUEUE_EOD_RESEND_TIME = 21;
	public const uint32 PROPID_MGMT_QUEUE_EOD_RESEND_INTERVAL = 22;
	public const uint32 PROPID_MGMT_QUEUE_EOD_RESEND_COUNT = 23;
	public const uint32 PROPID_MGMT_QUEUE_EOD_SOURCE_INFO = 24;
	public const uint32 PROPID_MGMT_QUEUE_CONNECTION_HISTORY = 25;
	public const uint32 PROPID_MGMT_QUEUE_SUBQUEUE_COUNT = 26;
	public const uint32 PROPID_MGMT_QUEUE_SUBQUEUE_NAMES = 27;
	public const uint32 PROPID_MGMT_QUEUE_USED_QUOTA = 8;
	public const uint32 PROPID_MGMT_QUEUE_JOURNAL_USED_QUOTA = 10;
	public const String MGMT_QUEUE_TYPE_PUBLIC = "PUBLIC";
	public const String MGMT_QUEUE_TYPE_PRIVATE = "PRIVATE";
	public const String MGMT_QUEUE_TYPE_MACHINE = "MACHINE";
	public const String MGMT_QUEUE_TYPE_CONNECTOR = "CONNECTOR";
	public const String MGMT_QUEUE_TYPE_MULTICAST = "MULTICAST";
	public const String MGMT_QUEUE_STATE_LOCAL = "LOCAL CONNECTION";
	public const String MGMT_QUEUE_STATE_NONACTIVE = "INACTIVE";
	public const String MGMT_QUEUE_STATE_WAITING = "WAITING";
	public const String MGMT_QUEUE_STATE_NEED_VALIDATE = "NEED VALIDATION";
	public const String MGMT_QUEUE_STATE_ONHOLD = "ONHOLD";
	public const String MGMT_QUEUE_STATE_CONNECTED = "CONNECTED";
	public const String MGMT_QUEUE_STATE_DISCONNECTING = "DISCONNECTING";
	public const String MGMT_QUEUE_STATE_DISCONNECTED = "DISCONNECTED";
	public const String MGMT_QUEUE_STATE_LOCKED = "LOCKED";
	public const String MGMT_QUEUE_LOCAL_LOCATION = "LOCAL";
	public const String MGMT_QUEUE_REMOTE_LOCATION = "REMOTE";
	public const String MGMT_QUEUE_UNKNOWN_TYPE = "UNKNOWN";
	public const String MGMT_QUEUE_CORRECT_TYPE = "YES";
	public const String MGMT_QUEUE_INCORRECT_TYPE = "NO";
	public const String MGMT_QUEUE_TRANSACTIONAL_TYPE = "YES";
	public const String MGMT_QUEUE_NOT_TRANSACTIONAL_TYPE = "NO";
	public const String MGMT_QUEUE_FOREIGN_TYPE = "YES";
	public const String MGMT_QUEUE_NOT_FOREIGN_TYPE = "NO";
	public const String MO_MACHINE_TOKEN = "MACHINE";
	public const String MO_QUEUE_TOKEN = "QUEUE";
	public const String MACHINE_ACTION_CONNECT = "CONNECT";
	public const String MACHINE_ACTION_DISCONNECT = "DISCONNECT";
	public const String MACHINE_ACTION_TIDY = "TIDY";
	public const String QUEUE_ACTION_PAUSE = "PAUSE";
	public const String QUEUE_ACTION_RESUME = "RESUME";
	public const String QUEUE_ACTION_EOD_RESEND = "EOD_RESEND";
	public const uint32 LONG_LIVED = 4294967294;
	public const uint32 MQSEC_DELETE_MESSAGE = 1;
	public const uint32 MQSEC_PEEK_MESSAGE = 2;
	public const uint32 MQSEC_WRITE_MESSAGE = 4;
	public const uint32 MQSEC_DELETE_JOURNAL_MESSAGE = 8;
	public const uint32 MQSEC_SET_QUEUE_PROPERTIES = 16;
	public const uint32 MQSEC_GET_QUEUE_PROPERTIES = 32;
	public const uint32 MQSEC_QUEUE_GENERIC_EXECUTE = 0;
	public const HRESULT MQ_OK = 0;
	public const HRESULT MQ_ERROR_RESOLVE_ADDRESS = -1072824167;
	public const HRESULT MQ_ERROR_TOO_MANY_PROPERTIES = -1072824166;
	public const HRESULT MQ_ERROR_MESSAGE_NOT_AUTHENTICATED = -1072824165;
	public const HRESULT MQ_ERROR_MESSAGE_LOCKED_UNDER_TRANSACTION = -1072824164;
}
#endregion

#region Enums

[AllowDuplicates]
public enum MQCALG : int32
{
	MQMSG_CALG_MD2 = 32769,
	MQMSG_CALG_MD4 = 32770,
	MQMSG_CALG_MD5 = 32771,
	MQMSG_CALG_SHA = 32772,
	MQMSG_CALG_SHA1 = 32772,
	MQMSG_CALG_MAC = 32773,
	MQMSG_CALG_RSA_SIGN = 9216,
	MQMSG_CALG_DSS_SIGN = 8704,
	MQMSG_CALG_RSA_KEYX = 41984,
	MQMSG_CALG_DES = 26113,
	MQMSG_CALG_RC2 = 26114,
	MQMSG_CALG_RC4 = 26625,
	MQMSG_CALG_SEAL = 26626,
}


[AllowDuplicates]
public enum MQTRANSACTION : int32
{
	MQ_NO_TRANSACTION = 0,
	MQ_MTS_TRANSACTION = 1,
	MQ_XA_TRANSACTION = 2,
	MQ_SINGLE_MESSAGE = 3,
}


[AllowDuplicates]
public enum RELOPS : int32
{
	REL_NOP = 0,
	REL_EQ = 1,
	REL_NEQ = 2,
	REL_LT = 3,
	REL_GT = 4,
	REL_LE = 5,
	REL_GE = 6,
}


[AllowDuplicates]
public enum MQCERT_REGISTER : int32
{
	MQCERT_REGISTER_ALWAYS = 1,
	MQCERT_REGISTER_IF_NOT_EXIST = 2,
}


[AllowDuplicates]
public enum MQMSGCURSOR : int32
{
	MQMSG_FIRST = 0,
	MQMSG_CURRENT = 1,
	MQMSG_NEXT = 2,
}


[AllowDuplicates]
public enum MQMSGCLASS : int32
{
	MQMSG_CLASS_NORMAL = 0,
	MQMSG_CLASS_REPORT = 1,
	MQMSG_CLASS_ACK_REACH_QUEUE = 2,
	MQMSG_CLASS_ACK_RECEIVE = 16384,
	MQMSG_CLASS_NACK_BAD_DST_Q = 32768,
	MQMSG_CLASS_NACK_PURGED = 32769,
	MQMSG_CLASS_NACK_REACH_QUEUE_TIMEOUT = 32770,
	MQMSG_CLASS_NACK_Q_EXCEED_QUOTA = 32771,
	MQMSG_CLASS_NACK_ACCESS_DENIED = 32772,
	MQMSG_CLASS_NACK_HOP_COUNT_EXCEEDED = 32773,
	MQMSG_CLASS_NACK_BAD_SIGNATURE = 32774,
	MQMSG_CLASS_NACK_BAD_ENCRYPTION = 32775,
	MQMSG_CLASS_NACK_COULD_NOT_ENCRYPT = 32776,
	MQMSG_CLASS_NACK_NOT_TRANSACTIONAL_Q = 32777,
	MQMSG_CLASS_NACK_NOT_TRANSACTIONAL_MSG = 32778,
	MQMSG_CLASS_NACK_UNSUPPORTED_CRYPTO_PROVIDER = 32779,
	MQMSG_CLASS_NACK_SOURCE_COMPUTER_GUID_CHANGED = 32780,
	MQMSG_CLASS_NACK_Q_DELETED = 49152,
	MQMSG_CLASS_NACK_Q_PURGED = 49153,
	MQMSG_CLASS_NACK_RECEIVE_TIMEOUT = 49154,
	MQMSG_CLASS_NACK_RECEIVE_TIMEOUT_AT_SENDER = 49155,
}


[AllowDuplicates]
public enum MQMSGDELIVERY : int32
{
	MQMSG_DELIVERY_EXPRESS = 0,
	MQMSG_DELIVERY_RECOVERABLE = 1,
}


[AllowDuplicates]
public enum MQMSGACKNOWLEDGEMENT : int32
{
	MQMSG_ACKNOWLEDGMENT_NONE = 0,
	MQMSG_ACKNOWLEDGMENT_POS_ARRIVAL = 1,
	MQMSG_ACKNOWLEDGMENT_POS_RECEIVE = 2,
	MQMSG_ACKNOWLEDGMENT_NEG_ARRIVAL = 4,
	MQMSG_ACKNOWLEDGMENT_NEG_RECEIVE = 8,
	MQMSG_ACKNOWLEDGMENT_NACK_REACH_QUEUE = 4,
	MQMSG_ACKNOWLEDGMENT_FULL_REACH_QUEUE = 5,
	MQMSG_ACKNOWLEDGMENT_NACK_RECEIVE = 12,
	MQMSG_ACKNOWLEDGMENT_FULL_RECEIVE = 14,
}


[AllowDuplicates]
public enum MQMSGJOURNAL : int32
{
	MQMSG_JOURNAL_NONE = 0,
	MQMSG_DEADLETTER = 1,
	MQMSG_JOURNAL = 2,
}


[AllowDuplicates]
public enum MQMSGTRACE : int32
{
	MQMSG_TRACE_NONE = 0,
	MQMSG_SEND_ROUTE_TO_REPORT_QUEUE = 1,
}


[AllowDuplicates]
public enum MQMSGSENDERIDTYPE : int32
{
	MQMSG_SENDERID_TYPE_NONE = 0,
	MQMSG_SENDERID_TYPE_SID = 1,
}


[AllowDuplicates]
public enum MQMSGPRIVLEVEL : int32
{
	MQMSG_PRIV_LEVEL_NONE = 0,
	MQMSG_PRIV_LEVEL_BODY_BASE = 1,
	MQMSG_PRIV_LEVEL_BODY_ENHANCED = 3,
}


[AllowDuplicates]
public enum MQMSGAUTHLEVEL : int32
{
	MQMSG_AUTH_LEVEL_NONE = 0,
	MQMSG_AUTH_LEVEL_ALWAYS = 1,
	MQMSG_AUTH_LEVEL_MSMQ10 = 2,
	MQMSG_AUTH_LEVEL_SIG10 = 2,
	MQMSG_AUTH_LEVEL_MSMQ20 = 4,
	MQMSG_AUTH_LEVEL_SIG20 = 4,
	MQMSG_AUTH_LEVEL_SIG30 = 8,
}


[AllowDuplicates]
public enum MQMSGIDSIZE : int32
{
	MQMSG_MSGID_SIZE = 20,
	MQMSG_CORRELATIONID_SIZE = 20,
	MQMSG_XACTID_SIZE = 20,
}


[AllowDuplicates]
public enum MQMSGMAX : int32
{
	MQ_MAX_MSG_LABEL_LEN = 249,
}


[AllowDuplicates]
public enum MQMSGAUTHENTICATION : int32
{
	MQMSG_AUTHENTICATION_NOT_REQUESTED = 0,
	MQMSG_AUTHENTICATION_REQUESTED = 1,
	MQMSG_AUTHENTICATED_SIG10 = 1,
	MQMSG_AUTHENTICATION_REQUESTED_EX = 3,
	MQMSG_AUTHENTICATED_SIG20 = 3,
	MQMSG_AUTHENTICATED_SIG30 = 5,
	MQMSG_AUTHENTICATED_SIGXML = 9,
}


[AllowDuplicates]
public enum MQSHARE : int32
{
	MQ_DENY_NONE = 0,
	MQ_DENY_RECEIVE_SHARE = 1,
}


[AllowDuplicates]
public enum MQACCESS : int32
{
	MQ_RECEIVE_ACCESS = 1,
	MQ_SEND_ACCESS = 2,
	MQ_PEEK_ACCESS = 32,
	MQ_ADMIN_ACCESS = 128,
}


[AllowDuplicates]
public enum MQJOURNAL : int32
{
	MQ_JOURNAL_NONE = 0,
	MQ_JOURNAL = 1,
}


[AllowDuplicates]
public enum MQTRANSACTIONAL : int32
{
	MQ_TRANSACTIONAL_NONE = 0,
	MQ_TRANSACTIONAL = 1,
}


[AllowDuplicates]
public enum MQAUTHENTICATE : int32
{
	MQ_AUTHENTICATE_NONE = 0,
	MQ_AUTHENTICATE = 1,
}


[AllowDuplicates]
public enum MQPRIVLEVEL : int32
{
	MQ_PRIV_LEVEL_NONE = 0,
	MQ_PRIV_LEVEL_OPTIONAL = 1,
	MQ_PRIV_LEVEL_BODY = 2,
}


[AllowDuplicates]
public enum MQPRIORITY : int32
{
	MQ_MIN_PRIORITY = 0,
	MQ_MAX_PRIORITY = 7,
}


[AllowDuplicates]
public enum MQMAX : int32
{
	MQ_MAX_Q_NAME_LEN = 124,
	MQ_MAX_Q_LABEL_LEN = 124,
}


[AllowDuplicates]
public enum QUEUE_TYPE : int32
{
	MQ_TYPE_PUBLIC = 0,
	MQ_TYPE_PRIVATE = 1,
	MQ_TYPE_MACHINE = 2,
	MQ_TYPE_CONNECTOR = 3,
	MQ_TYPE_MULTICAST = 4,
}


[AllowDuplicates]
public enum FOREIGN_STATUS : int32
{
	MQ_STATUS_FOREIGN = 0,
	MQ_STATUS_NOT_FOREIGN = 1,
	MQ_STATUS_UNKNOWN = 2,
}


[AllowDuplicates]
public enum XACT_STATUS : int32
{
	MQ_XACT_STATUS_XACT = 0,
	MQ_XACT_STATUS_NOT_XACT = 1,
	MQ_XACT_STATUS_UNKNOWN = 2,
}


[AllowDuplicates]
public enum QUEUE_STATE : int32
{
	MQ_QUEUE_STATE_LOCAL_CONNECTION = 0,
	MQ_QUEUE_STATE_DISCONNECTED = 1,
	MQ_QUEUE_STATE_WAITING = 2,
	MQ_QUEUE_STATE_NEEDVALIDATE = 3,
	MQ_QUEUE_STATE_ONHOLD = 4,
	MQ_QUEUE_STATE_NONACTIVE = 5,
	MQ_QUEUE_STATE_CONNECTED = 6,
	MQ_QUEUE_STATE_DISCONNECTING = 7,
	MQ_QUEUE_STATE_LOCKED = 8,
}


[AllowDuplicates]
public enum MQDEFAULT : int32
{
	DEFAULT_M_PRIORITY = 3,
	DEFAULT_M_DELIVERY = 0,
	DEFAULT_M_ACKNOWLEDGE = 0,
	DEFAULT_M_JOURNAL = 0,
	DEFAULT_M_APPSPECIFIC = 0,
	DEFAULT_M_PRIV_LEVEL = 0,
	DEFAULT_M_AUTH_LEVEL = 0,
	DEFAULT_M_SENDERID_TYPE = 1,
	DEFAULT_Q_JOURNAL = 0,
	DEFAULT_Q_BASEPRIORITY = 0,
	DEFAULT_Q_QUOTA = -1,
	DEFAULT_Q_JOURNAL_QUOTA = -1,
	DEFAULT_Q_TRANSACTION = 0,
	DEFAULT_Q_AUTHENTICATE = 0,
	DEFAULT_Q_PRIV_LEVEL = 1,
	DEFAULT_M_LOOKUPID = 0,
}


[AllowDuplicates]
public enum MQERROR : int32
{
	MQ_ERROR = -1072824319,
	MQ_ERROR_PROPERTY = -1072824318,
	MQ_ERROR_QUEUE_NOT_FOUND = -1072824317,
	MQ_ERROR_QUEUE_NOT_ACTIVE = -1072824316,
	MQ_ERROR_QUEUE_EXISTS = -1072824315,
	MQ_ERROR_INVALID_PARAMETER = -1072824314,
	MQ_ERROR_INVALID_HANDLE = -1072824313,
	MQ_ERROR_OPERATION_CANCELLED = -1072824312,
	MQ_ERROR_SHARING_VIOLATION = -1072824311,
	MQ_ERROR_SERVICE_NOT_AVAILABLE = -1072824309,
	MQ_ERROR_MACHINE_NOT_FOUND = -1072824307,
	MQ_ERROR_ILLEGAL_SORT = -1072824304,
	MQ_ERROR_ILLEGAL_USER = -1072824303,
	MQ_ERROR_NO_DS = -1072824301,
	MQ_ERROR_ILLEGAL_QUEUE_PATHNAME = -1072824300,
	MQ_ERROR_ILLEGAL_PROPERTY_VALUE = -1072824296,
	MQ_ERROR_ILLEGAL_PROPERTY_VT = -1072824295,
	MQ_ERROR_BUFFER_OVERFLOW = -1072824294,
	MQ_ERROR_IO_TIMEOUT = -1072824293,
	MQ_ERROR_ILLEGAL_CURSOR_ACTION = -1072824292,
	MQ_ERROR_MESSAGE_ALREADY_RECEIVED = -1072824291,
	MQ_ERROR_ILLEGAL_FORMATNAME = -1072824290,
	MQ_ERROR_FORMATNAME_BUFFER_TOO_SMALL = -1072824289,
	MQ_ERROR_UNSUPPORTED_FORMATNAME_OPERATION = -1072824288,
	MQ_ERROR_ILLEGAL_SECURITY_DESCRIPTOR = -1072824287,
	MQ_ERROR_SENDERID_BUFFER_TOO_SMALL = -1072824286,
	MQ_ERROR_SECURITY_DESCRIPTOR_TOO_SMALL = -1072824285,
	MQ_ERROR_CANNOT_IMPERSONATE_CLIENT = -1072824284,
	MQ_ERROR_ACCESS_DENIED = -1072824283,
	MQ_ERROR_PRIVILEGE_NOT_HELD = -1072824282,
	MQ_ERROR_INSUFFICIENT_RESOURCES = -1072824281,
	MQ_ERROR_USER_BUFFER_TOO_SMALL = -1072824280,
	MQ_ERROR_MESSAGE_STORAGE_FAILED = -1072824278,
	MQ_ERROR_SENDER_CERT_BUFFER_TOO_SMALL = -1072824277,
	MQ_ERROR_INVALID_CERTIFICATE = -1072824276,
	MQ_ERROR_CORRUPTED_INTERNAL_CERTIFICATE = -1072824275,
	MQ_ERROR_INTERNAL_USER_CERT_EXIST = -1072824274,
	MQ_ERROR_NO_INTERNAL_USER_CERT = -1072824273,
	MQ_ERROR_CORRUPTED_SECURITY_DATA = -1072824272,
	MQ_ERROR_CORRUPTED_PERSONAL_CERT_STORE = -1072824271,
	MQ_ERROR_COMPUTER_DOES_NOT_SUPPORT_ENCRYPTION = -1072824269,
	MQ_ERROR_BAD_SECURITY_CONTEXT = -1072824267,
	MQ_ERROR_COULD_NOT_GET_USER_SID = -1072824266,
	MQ_ERROR_COULD_NOT_GET_ACCOUNT_INFO = -1072824265,
	MQ_ERROR_ILLEGAL_MQCOLUMNS = -1072824264,
	MQ_ERROR_ILLEGAL_PROPID = -1072824263,
	MQ_ERROR_ILLEGAL_RELATION = -1072824262,
	MQ_ERROR_ILLEGAL_PROPERTY_SIZE = -1072824261,
	MQ_ERROR_ILLEGAL_RESTRICTION_PROPID = -1072824260,
	MQ_ERROR_ILLEGAL_MQQUEUEPROPS = -1072824259,
	MQ_ERROR_PROPERTY_NOTALLOWED = -1072824258,
	MQ_ERROR_INSUFFICIENT_PROPERTIES = -1072824257,
	MQ_ERROR_MACHINE_EXISTS = -1072824256,
	MQ_ERROR_ILLEGAL_MQQMPROPS = -1072824255,
	MQ_ERROR_DS_IS_FULL = -1072824254,
	MQ_ERROR_DS_ERROR = -1072824253,
	MQ_ERROR_INVALID_OWNER = -1072824252,
	MQ_ERROR_UNSUPPORTED_ACCESS_MODE = -1072824251,
	MQ_ERROR_RESULT_BUFFER_TOO_SMALL = -1072824250,
	MQ_ERROR_DELETE_CN_IN_USE = -1072824248,
	MQ_ERROR_NO_RESPONSE_FROM_OBJECT_SERVER = -1072824247,
	MQ_ERROR_OBJECT_SERVER_NOT_AVAILABLE = -1072824246,
	MQ_ERROR_QUEUE_NOT_AVAILABLE = -1072824245,
	MQ_ERROR_DTC_CONNECT = -1072824244,
	MQ_ERROR_TRANSACTION_IMPORT = -1072824242,
	MQ_ERROR_TRANSACTION_USAGE = -1072824240,
	MQ_ERROR_TRANSACTION_SEQUENCE = -1072824239,
	MQ_ERROR_MISSING_CONNECTOR_TYPE = -1072824235,
	MQ_ERROR_STALE_HANDLE = -1072824234,
	MQ_ERROR_TRANSACTION_ENLIST = -1072824232,
	MQ_ERROR_QUEUE_DELETED = -1072824230,
	MQ_ERROR_ILLEGAL_CONTEXT = -1072824229,
	MQ_ERROR_ILLEGAL_SORT_PROPID = -1072824228,
	MQ_ERROR_LABEL_TOO_LONG = -1072824227,
	MQ_ERROR_LABEL_BUFFER_TOO_SMALL = -1072824226,
	MQ_ERROR_MQIS_SERVER_EMPTY = -1072824225,
	MQ_ERROR_MQIS_READONLY_MODE = -1072824224,
	MQ_ERROR_SYMM_KEY_BUFFER_TOO_SMALL = -1072824223,
	MQ_ERROR_SIGNATURE_BUFFER_TOO_SMALL = -1072824222,
	MQ_ERROR_PROV_NAME_BUFFER_TOO_SMALL = -1072824221,
	MQ_ERROR_ILLEGAL_OPERATION = -1072824220,
	MQ_ERROR_WRITE_NOT_ALLOWED = -1072824219,
	MQ_ERROR_WKS_CANT_SERVE_CLIENT = -1072824218,
	MQ_ERROR_DEPEND_WKS_LICENSE_OVERFLOW = -1072824217,
	MQ_CORRUPTED_QUEUE_WAS_DELETED = -1072824216,
	MQ_ERROR_REMOTE_MACHINE_NOT_AVAILABLE = -1072824215,
	MQ_ERROR_UNSUPPORTED_OPERATION = -1072824214,
	MQ_ERROR_ENCRYPTION_PROVIDER_NOT_SUPPORTED = -1072824213,
	MQ_ERROR_CANNOT_SET_CRYPTO_SEC_DESCR = -1072824212,
	MQ_ERROR_CERTIFICATE_NOT_PROVIDED = -1072824211,
	MQ_ERROR_Q_DNS_PROPERTY_NOT_SUPPORTED = -1072824210,
	MQ_ERROR_CANT_CREATE_CERT_STORE = -1072824209,
	MQ_ERROR_CANNOT_CREATE_CERT_STORE = -1072824209,
	MQ_ERROR_CANT_OPEN_CERT_STORE = -1072824208,
	MQ_ERROR_CANNOT_OPEN_CERT_STORE = -1072824208,
	MQ_ERROR_ILLEGAL_ENTERPRISE_OPERATION = -1072824207,
	MQ_ERROR_CANNOT_GRANT_ADD_GUID = -1072824206,
	MQ_ERROR_CANNOT_LOAD_MSMQOCM = -1072824205,
	MQ_ERROR_NO_ENTRY_POINT_MSMQOCM = -1072824204,
	MQ_ERROR_NO_MSMQ_SERVERS_ON_DC = -1072824203,
	MQ_ERROR_CANNOT_JOIN_DOMAIN = -1072824202,
	MQ_ERROR_CANNOT_CREATE_ON_GC = -1072824201,
	MQ_ERROR_GUID_NOT_MATCHING = -1072824200,
	MQ_ERROR_PUBLIC_KEY_NOT_FOUND = -1072824199,
	MQ_ERROR_PUBLIC_KEY_DOES_NOT_EXIST = -1072824198,
	MQ_ERROR_ILLEGAL_MQPRIVATEPROPS = -1072824197,
	MQ_ERROR_NO_GC_IN_DOMAIN = -1072824196,
	MQ_ERROR_NO_MSMQ_SERVERS_ON_GC = -1072824195,
	MQ_ERROR_CANNOT_GET_DN = -1072824194,
	MQ_ERROR_CANNOT_HASH_DATA_EX = -1072824193,
	MQ_ERROR_CANNOT_SIGN_DATA_EX = -1072824192,
	MQ_ERROR_CANNOT_CREATE_HASH_EX = -1072824191,
	MQ_ERROR_FAIL_VERIFY_SIGNATURE_EX = -1072824190,
	MQ_ERROR_CANNOT_DELETE_PSC_OBJECTS = -1072824189,
	MQ_ERROR_NO_MQUSER_OU = -1072824188,
	MQ_ERROR_CANNOT_LOAD_MQAD = -1072824187,
	MQ_ERROR_CANNOT_LOAD_MQDSSRV = -1072824186,
	MQ_ERROR_PROPERTIES_CONFLICT = -1072824185,
	MQ_ERROR_MESSAGE_NOT_FOUND = -1072824184,
	MQ_ERROR_CANT_RESOLVE_SITES = -1072824183,
	MQ_ERROR_NOT_SUPPORTED_BY_DEPENDENT_CLIENTS = -1072824182,
	MQ_ERROR_OPERATION_NOT_SUPPORTED_BY_REMOTE_COMPUTER = -1072824181,
	MQ_ERROR_NOT_A_CORRECT_OBJECT_CLASS = -1072824180,
	MQ_ERROR_MULTI_SORT_KEYS = -1072824179,
	MQ_ERROR_GC_NEEDED = -1072824178,
	MQ_ERROR_DS_BIND_ROOT_FOREST = -1072824177,
	MQ_ERROR_DS_LOCAL_USER = -1072824176,
	MQ_ERROR_Q_ADS_PROPERTY_NOT_SUPPORTED = -1072824175,
	MQ_ERROR_BAD_XML_FORMAT = -1072824174,
	MQ_ERROR_UNSUPPORTED_CLASS = -1072824173,
	MQ_ERROR_UNINITIALIZED_OBJECT = -1072824172,
	MQ_ERROR_CANNOT_CREATE_PSC_OBJECTS = -1072824171,
	MQ_ERROR_CANNOT_UPDATE_PSC_OBJECTS = -1072824170,
}


[AllowDuplicates]
public enum MQWARNING : int32
{
	MQ_INFORMATION_PROPERTY = 1074659329,
	MQ_INFORMATION_ILLEGAL_PROPERTY = 1074659330,
	MQ_INFORMATION_PROPERTY_IGNORED = 1074659331,
	MQ_INFORMATION_UNSUPPORTED_PROPERTY = 1074659332,
	MQ_INFORMATION_DUPLICATE_PROPERTY = 1074659333,
	MQ_INFORMATION_OPERATION_PENDING = 1074659334,
	MQ_INFORMATION_FORMATNAME_BUFFER_TOO_SMALL = 1074659337,
	MQ_INFORMATION_INTERNAL_USER_CERT_EXIST = 1074659338,
	MQ_INFORMATION_OWNER_IGNORED = 1074659339,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_MSMQQuery = .(0xd7d6e073, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);


	public const Guid CLSID_MSMQMessage = .(0xd7d6e075, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);


	public const Guid CLSID_MSMQQueue = .(0xd7d6e079, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);


	public const Guid CLSID_MSMQEvent = .(0xd7d6e07a, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);


	public const Guid CLSID_MSMQQueueInfo = .(0xd7d6e07c, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);


	public const Guid CLSID_MSMQQueueInfos = .(0xd7d6e07e, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);


	public const Guid CLSID_MSMQTransaction = .(0xd7d6e080, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);


	public const Guid CLSID_MSMQCoordinatedTransactionDispenser = .(0xd7d6e082, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);


	public const Guid CLSID_MSMQTransactionDispenser = .(0xd7d6e084, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);


	public const Guid CLSID_MSMQApplication = .(0xd7d6e086, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);


	public const Guid CLSID_MSMQDestination = .(0xeba96b18, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);


	public const Guid CLSID_MSMQCollection = .(0xf72b9031, 0x2f0c, 0x43e8, 0x92, 0x4e, 0xe6, 0x05, 0x2c, 0xdc, 0x49, 0x3f);


	public const Guid CLSID_MSMQManagement = .(0x39ce96fe, 0xf4c5, 0x4484, 0xa1, 0x43, 0x4c, 0x2d, 0x5d, 0x32, 0x42, 0x29);


	public const Guid CLSID_MSMQOutgoingQueueManagement = .(0x0188401c, 0x247a, 0x4fed, 0x99, 0xc6, 0xbf, 0x14, 0x11, 0x9d, 0x70, 0x55);


	public const Guid CLSID_MSMQQueueManagement = .(0x33b6d07e, 0xf27d, 0x42fa, 0xb2, 0xd7, 0xbf, 0x82, 0xe1, 0x1e, 0x93, 0x74);


}
#endregion

#region COM Types
[CRepr]struct IMSMQQuery : IDispatch
{
	public new const Guid IID = .(0xd7d6e072, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, IMSMQQueueInfos** ppqinfos) LookupQueue;
	}


	public HRESULT LookupQueue(VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, IMSMQQueueInfos** ppqinfos) mut => VT.[Friend]LookupQueue(&this, QueueGuid, ServiceTypeGuid, Label, CreateTime, ModifyTime, RelServiceType, RelLabel, RelCreateTime, RelModifyTime, ppqinfos);
}

[CRepr]struct IMSMQQueueInfo : IDispatch
{
	public new const Guid IID = .(0xd7d6e07b, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidQueue) get_QueueGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidServiceType) get_ServiceTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGuidServiceType) put_ServiceTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLabel) get_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLabel) put_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPathName) get_PathName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPathName) put_PathName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFormatName) get_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFormatName) put_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisTransactional) get_IsTransactional;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPrivLevel) get_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrivLevel) put_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournal) get_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournal) put_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plQuota) get_Quota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lQuota) put_Quota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBasePriority) get_BasePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lBasePriority) put_BasePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarCreateTime) get_CreateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarModifyTime) get_ModifyTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthenticate) get_Authenticate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthenticate) put_Authenticate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournalQuota) get_JournalQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournalQuota) put_JournalQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisWorldReadable) get_IsWorldReadable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* IsTransactional, VARIANT* IsWorldReadable) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Access, int32 ShareMode, IMSMQQueue** ppq) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Update;
	}


	public HRESULT get_QueueGuid(BSTR* pbstrGuidQueue) mut => VT.[Friend]get_QueueGuid(&this, pbstrGuidQueue);

	public HRESULT get_ServiceTypeGuid(BSTR* pbstrGuidServiceType) mut => VT.[Friend]get_ServiceTypeGuid(&this, pbstrGuidServiceType);

	public HRESULT put_ServiceTypeGuid(BSTR bstrGuidServiceType) mut => VT.[Friend]put_ServiceTypeGuid(&this, bstrGuidServiceType);

	public HRESULT get_Label(BSTR* pbstrLabel) mut => VT.[Friend]get_Label(&this, pbstrLabel);

	public HRESULT put_Label(BSTR bstrLabel) mut => VT.[Friend]put_Label(&this, bstrLabel);

	public HRESULT get_PathName(BSTR* pbstrPathName) mut => VT.[Friend]get_PathName(&this, pbstrPathName);

	public HRESULT put_PathName(BSTR bstrPathName) mut => VT.[Friend]put_PathName(&this, bstrPathName);

	public HRESULT get_FormatName(BSTR* pbstrFormatName) mut => VT.[Friend]get_FormatName(&this, pbstrFormatName);

	public HRESULT put_FormatName(BSTR bstrFormatName) mut => VT.[Friend]put_FormatName(&this, bstrFormatName);

	public HRESULT get_IsTransactional(int16* pisTransactional) mut => VT.[Friend]get_IsTransactional(&this, pisTransactional);

	public HRESULT get_PrivLevel(int32* plPrivLevel) mut => VT.[Friend]get_PrivLevel(&this, plPrivLevel);

	public HRESULT put_PrivLevel(int32 lPrivLevel) mut => VT.[Friend]put_PrivLevel(&this, lPrivLevel);

	public HRESULT get_Journal(int32* plJournal) mut => VT.[Friend]get_Journal(&this, plJournal);

	public HRESULT put_Journal(int32 lJournal) mut => VT.[Friend]put_Journal(&this, lJournal);

	public HRESULT get_Quota(int32* plQuota) mut => VT.[Friend]get_Quota(&this, plQuota);

	public HRESULT put_Quota(int32 lQuota) mut => VT.[Friend]put_Quota(&this, lQuota);

	public HRESULT get_BasePriority(int32* plBasePriority) mut => VT.[Friend]get_BasePriority(&this, plBasePriority);

	public HRESULT put_BasePriority(int32 lBasePriority) mut => VT.[Friend]put_BasePriority(&this, lBasePriority);

	public HRESULT get_CreateTime(VARIANT* pvarCreateTime) mut => VT.[Friend]get_CreateTime(&this, pvarCreateTime);

	public HRESULT get_ModifyTime(VARIANT* pvarModifyTime) mut => VT.[Friend]get_ModifyTime(&this, pvarModifyTime);

	public HRESULT get_Authenticate(int32* plAuthenticate) mut => VT.[Friend]get_Authenticate(&this, plAuthenticate);

	public HRESULT put_Authenticate(int32 lAuthenticate) mut => VT.[Friend]put_Authenticate(&this, lAuthenticate);

	public HRESULT get_JournalQuota(int32* plJournalQuota) mut => VT.[Friend]get_JournalQuota(&this, plJournalQuota);

	public HRESULT put_JournalQuota(int32 lJournalQuota) mut => VT.[Friend]put_JournalQuota(&this, lJournalQuota);

	public HRESULT get_IsWorldReadable(int16* pisWorldReadable) mut => VT.[Friend]get_IsWorldReadable(&this, pisWorldReadable);

	public HRESULT Create(VARIANT* IsTransactional, VARIANT* IsWorldReadable) mut => VT.[Friend]Create(&this, IsTransactional, IsWorldReadable);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Open(int32 Access, int32 ShareMode, IMSMQQueue** ppq) mut => VT.[Friend]Open(&this, Access, ShareMode, ppq);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Update() mut => VT.[Friend]Update(&this);
}

[CRepr]struct IMSMQQueueInfo2 : IDispatch
{
	public new const Guid IID = .(0xfd174a80, 0x89cf, 0x11d2, 0xb0, 0xf2, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidQueue) get_QueueGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidServiceType) get_ServiceTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGuidServiceType) put_ServiceTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLabel) get_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLabel) put_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPathName) get_PathName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPathName) put_PathName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFormatName) get_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFormatName) put_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisTransactional) get_IsTransactional;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPrivLevel) get_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrivLevel) put_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournal) get_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournal) put_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plQuota) get_Quota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lQuota) put_Quota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBasePriority) get_BasePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lBasePriority) put_BasePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarCreateTime) get_CreateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarModifyTime) get_ModifyTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthenticate) get_Authenticate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthenticate) put_Authenticate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournalQuota) get_JournalQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournalQuota) put_JournalQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisWorldReadable) get_IsWorldReadable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* IsTransactional, VARIANT* IsWorldReadable) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Access, int32 ShareMode, IMSMQQueue2** ppq) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Update;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPathNameDNS) get_PathNameDNS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSecurity) get_Security;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSecurity) put_Security;
	}


	public HRESULT get_QueueGuid(BSTR* pbstrGuidQueue) mut => VT.[Friend]get_QueueGuid(&this, pbstrGuidQueue);

	public HRESULT get_ServiceTypeGuid(BSTR* pbstrGuidServiceType) mut => VT.[Friend]get_ServiceTypeGuid(&this, pbstrGuidServiceType);

	public HRESULT put_ServiceTypeGuid(BSTR bstrGuidServiceType) mut => VT.[Friend]put_ServiceTypeGuid(&this, bstrGuidServiceType);

	public HRESULT get_Label(BSTR* pbstrLabel) mut => VT.[Friend]get_Label(&this, pbstrLabel);

	public HRESULT put_Label(BSTR bstrLabel) mut => VT.[Friend]put_Label(&this, bstrLabel);

	public HRESULT get_PathName(BSTR* pbstrPathName) mut => VT.[Friend]get_PathName(&this, pbstrPathName);

	public HRESULT put_PathName(BSTR bstrPathName) mut => VT.[Friend]put_PathName(&this, bstrPathName);

	public HRESULT get_FormatName(BSTR* pbstrFormatName) mut => VT.[Friend]get_FormatName(&this, pbstrFormatName);

	public HRESULT put_FormatName(BSTR bstrFormatName) mut => VT.[Friend]put_FormatName(&this, bstrFormatName);

	public HRESULT get_IsTransactional(int16* pisTransactional) mut => VT.[Friend]get_IsTransactional(&this, pisTransactional);

	public HRESULT get_PrivLevel(int32* plPrivLevel) mut => VT.[Friend]get_PrivLevel(&this, plPrivLevel);

	public HRESULT put_PrivLevel(int32 lPrivLevel) mut => VT.[Friend]put_PrivLevel(&this, lPrivLevel);

	public HRESULT get_Journal(int32* plJournal) mut => VT.[Friend]get_Journal(&this, plJournal);

	public HRESULT put_Journal(int32 lJournal) mut => VT.[Friend]put_Journal(&this, lJournal);

	public HRESULT get_Quota(int32* plQuota) mut => VT.[Friend]get_Quota(&this, plQuota);

	public HRESULT put_Quota(int32 lQuota) mut => VT.[Friend]put_Quota(&this, lQuota);

	public HRESULT get_BasePriority(int32* plBasePriority) mut => VT.[Friend]get_BasePriority(&this, plBasePriority);

	public HRESULT put_BasePriority(int32 lBasePriority) mut => VT.[Friend]put_BasePriority(&this, lBasePriority);

	public HRESULT get_CreateTime(VARIANT* pvarCreateTime) mut => VT.[Friend]get_CreateTime(&this, pvarCreateTime);

	public HRESULT get_ModifyTime(VARIANT* pvarModifyTime) mut => VT.[Friend]get_ModifyTime(&this, pvarModifyTime);

	public HRESULT get_Authenticate(int32* plAuthenticate) mut => VT.[Friend]get_Authenticate(&this, plAuthenticate);

	public HRESULT put_Authenticate(int32 lAuthenticate) mut => VT.[Friend]put_Authenticate(&this, lAuthenticate);

	public HRESULT get_JournalQuota(int32* plJournalQuota) mut => VT.[Friend]get_JournalQuota(&this, plJournalQuota);

	public HRESULT put_JournalQuota(int32 lJournalQuota) mut => VT.[Friend]put_JournalQuota(&this, lJournalQuota);

	public HRESULT get_IsWorldReadable(int16* pisWorldReadable) mut => VT.[Friend]get_IsWorldReadable(&this, pisWorldReadable);

	public HRESULT Create(VARIANT* IsTransactional, VARIANT* IsWorldReadable) mut => VT.[Friend]Create(&this, IsTransactional, IsWorldReadable);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Open(int32 Access, int32 ShareMode, IMSMQQueue2** ppq) mut => VT.[Friend]Open(&this, Access, ShareMode, ppq);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Update() mut => VT.[Friend]Update(&this);

	public HRESULT get_PathNameDNS(BSTR* pbstrPathNameDNS) mut => VT.[Friend]get_PathNameDNS(&this, pbstrPathNameDNS);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);

	public HRESULT get_Security(VARIANT* pvarSecurity) mut => VT.[Friend]get_Security(&this, pvarSecurity);

	public HRESULT put_Security(VARIANT varSecurity) mut => VT.[Friend]put_Security(&this, varSecurity);
}

[CRepr]struct IMSMQQueueInfo3 : IDispatch
{
	public new const Guid IID = .(0xeba96b1d, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidQueue) get_QueueGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidServiceType) get_ServiceTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGuidServiceType) put_ServiceTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLabel) get_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLabel) put_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPathName) get_PathName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPathName) put_PathName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFormatName) get_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFormatName) put_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisTransactional) get_IsTransactional;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPrivLevel) get_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrivLevel) put_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournal) get_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournal) put_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plQuota) get_Quota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lQuota) put_Quota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBasePriority) get_BasePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lBasePriority) put_BasePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarCreateTime) get_CreateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarModifyTime) get_ModifyTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthenticate) get_Authenticate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthenticate) put_Authenticate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournalQuota) get_JournalQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournalQuota) put_JournalQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisWorldReadable) get_IsWorldReadable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* IsTransactional, VARIANT* IsWorldReadable) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Access, int32 ShareMode, IMSMQQueue3** ppq) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Update;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPathNameDNS) get_PathNameDNS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSecurity) get_Security;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSecurity) put_Security;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisTransactional) get_IsTransactional2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisWorldReadable) get_IsWorldReadable2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMulticastAddress) get_MulticastAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMulticastAddress) put_MulticastAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrADsPath) get_ADsPath;
	}


	public HRESULT get_QueueGuid(BSTR* pbstrGuidQueue) mut => VT.[Friend]get_QueueGuid(&this, pbstrGuidQueue);

	public HRESULT get_ServiceTypeGuid(BSTR* pbstrGuidServiceType) mut => VT.[Friend]get_ServiceTypeGuid(&this, pbstrGuidServiceType);

	public HRESULT put_ServiceTypeGuid(BSTR bstrGuidServiceType) mut => VT.[Friend]put_ServiceTypeGuid(&this, bstrGuidServiceType);

	public HRESULT get_Label(BSTR* pbstrLabel) mut => VT.[Friend]get_Label(&this, pbstrLabel);

	public HRESULT put_Label(BSTR bstrLabel) mut => VT.[Friend]put_Label(&this, bstrLabel);

	public HRESULT get_PathName(BSTR* pbstrPathName) mut => VT.[Friend]get_PathName(&this, pbstrPathName);

	public HRESULT put_PathName(BSTR bstrPathName) mut => VT.[Friend]put_PathName(&this, bstrPathName);

	public HRESULT get_FormatName(BSTR* pbstrFormatName) mut => VT.[Friend]get_FormatName(&this, pbstrFormatName);

	public HRESULT put_FormatName(BSTR bstrFormatName) mut => VT.[Friend]put_FormatName(&this, bstrFormatName);

	public HRESULT get_IsTransactional(int16* pisTransactional) mut => VT.[Friend]get_IsTransactional(&this, pisTransactional);

	public HRESULT get_PrivLevel(int32* plPrivLevel) mut => VT.[Friend]get_PrivLevel(&this, plPrivLevel);

	public HRESULT put_PrivLevel(int32 lPrivLevel) mut => VT.[Friend]put_PrivLevel(&this, lPrivLevel);

	public HRESULT get_Journal(int32* plJournal) mut => VT.[Friend]get_Journal(&this, plJournal);

	public HRESULT put_Journal(int32 lJournal) mut => VT.[Friend]put_Journal(&this, lJournal);

	public HRESULT get_Quota(int32* plQuota) mut => VT.[Friend]get_Quota(&this, plQuota);

	public HRESULT put_Quota(int32 lQuota) mut => VT.[Friend]put_Quota(&this, lQuota);

	public HRESULT get_BasePriority(int32* plBasePriority) mut => VT.[Friend]get_BasePriority(&this, plBasePriority);

	public HRESULT put_BasePriority(int32 lBasePriority) mut => VT.[Friend]put_BasePriority(&this, lBasePriority);

	public HRESULT get_CreateTime(VARIANT* pvarCreateTime) mut => VT.[Friend]get_CreateTime(&this, pvarCreateTime);

	public HRESULT get_ModifyTime(VARIANT* pvarModifyTime) mut => VT.[Friend]get_ModifyTime(&this, pvarModifyTime);

	public HRESULT get_Authenticate(int32* plAuthenticate) mut => VT.[Friend]get_Authenticate(&this, plAuthenticate);

	public HRESULT put_Authenticate(int32 lAuthenticate) mut => VT.[Friend]put_Authenticate(&this, lAuthenticate);

	public HRESULT get_JournalQuota(int32* plJournalQuota) mut => VT.[Friend]get_JournalQuota(&this, plJournalQuota);

	public HRESULT put_JournalQuota(int32 lJournalQuota) mut => VT.[Friend]put_JournalQuota(&this, lJournalQuota);

	public HRESULT get_IsWorldReadable(int16* pisWorldReadable) mut => VT.[Friend]get_IsWorldReadable(&this, pisWorldReadable);

	public HRESULT Create(VARIANT* IsTransactional, VARIANT* IsWorldReadable) mut => VT.[Friend]Create(&this, IsTransactional, IsWorldReadable);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Open(int32 Access, int32 ShareMode, IMSMQQueue3** ppq) mut => VT.[Friend]Open(&this, Access, ShareMode, ppq);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Update() mut => VT.[Friend]Update(&this);

	public HRESULT get_PathNameDNS(BSTR* pbstrPathNameDNS) mut => VT.[Friend]get_PathNameDNS(&this, pbstrPathNameDNS);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);

	public HRESULT get_Security(VARIANT* pvarSecurity) mut => VT.[Friend]get_Security(&this, pvarSecurity);

	public HRESULT put_Security(VARIANT varSecurity) mut => VT.[Friend]put_Security(&this, varSecurity);

	public HRESULT get_IsTransactional2(int16* pisTransactional) mut => VT.[Friend]get_IsTransactional2(&this, pisTransactional);

	public HRESULT get_IsWorldReadable2(int16* pisWorldReadable) mut => VT.[Friend]get_IsWorldReadable2(&this, pisWorldReadable);

	public HRESULT get_MulticastAddress(BSTR* pbstrMulticastAddress) mut => VT.[Friend]get_MulticastAddress(&this, pbstrMulticastAddress);

	public HRESULT put_MulticastAddress(BSTR bstrMulticastAddress) mut => VT.[Friend]put_MulticastAddress(&this, bstrMulticastAddress);

	public HRESULT get_ADsPath(BSTR* pbstrADsPath) mut => VT.[Friend]get_ADsPath(&this, pbstrADsPath);
}

[CRepr]struct IMSMQQueueInfo4 : IDispatch
{
	public new const Guid IID = .(0xeba96b21, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidQueue) get_QueueGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidServiceType) get_ServiceTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGuidServiceType) put_ServiceTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLabel) get_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLabel) put_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPathName) get_PathName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPathName) put_PathName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFormatName) get_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFormatName) put_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisTransactional) get_IsTransactional;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPrivLevel) get_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrivLevel) put_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournal) get_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournal) put_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plQuota) get_Quota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lQuota) put_Quota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBasePriority) get_BasePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lBasePriority) put_BasePriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarCreateTime) get_CreateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarModifyTime) get_ModifyTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthenticate) get_Authenticate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthenticate) put_Authenticate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournalQuota) get_JournalQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournalQuota) put_JournalQuota;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisWorldReadable) get_IsWorldReadable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* IsTransactional, VARIANT* IsWorldReadable) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Access, int32 ShareMode, IMSMQQueue4** ppq) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Update;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPathNameDNS) get_PathNameDNS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSecurity) get_Security;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSecurity) put_Security;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisTransactional) get_IsTransactional2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisWorldReadable) get_IsWorldReadable2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMulticastAddress) get_MulticastAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMulticastAddress) put_MulticastAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrADsPath) get_ADsPath;
	}


	public HRESULT get_QueueGuid(BSTR* pbstrGuidQueue) mut => VT.[Friend]get_QueueGuid(&this, pbstrGuidQueue);

	public HRESULT get_ServiceTypeGuid(BSTR* pbstrGuidServiceType) mut => VT.[Friend]get_ServiceTypeGuid(&this, pbstrGuidServiceType);

	public HRESULT put_ServiceTypeGuid(BSTR bstrGuidServiceType) mut => VT.[Friend]put_ServiceTypeGuid(&this, bstrGuidServiceType);

	public HRESULT get_Label(BSTR* pbstrLabel) mut => VT.[Friend]get_Label(&this, pbstrLabel);

	public HRESULT put_Label(BSTR bstrLabel) mut => VT.[Friend]put_Label(&this, bstrLabel);

	public HRESULT get_PathName(BSTR* pbstrPathName) mut => VT.[Friend]get_PathName(&this, pbstrPathName);

	public HRESULT put_PathName(BSTR bstrPathName) mut => VT.[Friend]put_PathName(&this, bstrPathName);

	public HRESULT get_FormatName(BSTR* pbstrFormatName) mut => VT.[Friend]get_FormatName(&this, pbstrFormatName);

	public HRESULT put_FormatName(BSTR bstrFormatName) mut => VT.[Friend]put_FormatName(&this, bstrFormatName);

	public HRESULT get_IsTransactional(int16* pisTransactional) mut => VT.[Friend]get_IsTransactional(&this, pisTransactional);

	public HRESULT get_PrivLevel(int32* plPrivLevel) mut => VT.[Friend]get_PrivLevel(&this, plPrivLevel);

	public HRESULT put_PrivLevel(int32 lPrivLevel) mut => VT.[Friend]put_PrivLevel(&this, lPrivLevel);

	public HRESULT get_Journal(int32* plJournal) mut => VT.[Friend]get_Journal(&this, plJournal);

	public HRESULT put_Journal(int32 lJournal) mut => VT.[Friend]put_Journal(&this, lJournal);

	public HRESULT get_Quota(int32* plQuota) mut => VT.[Friend]get_Quota(&this, plQuota);

	public HRESULT put_Quota(int32 lQuota) mut => VT.[Friend]put_Quota(&this, lQuota);

	public HRESULT get_BasePriority(int32* plBasePriority) mut => VT.[Friend]get_BasePriority(&this, plBasePriority);

	public HRESULT put_BasePriority(int32 lBasePriority) mut => VT.[Friend]put_BasePriority(&this, lBasePriority);

	public HRESULT get_CreateTime(VARIANT* pvarCreateTime) mut => VT.[Friend]get_CreateTime(&this, pvarCreateTime);

	public HRESULT get_ModifyTime(VARIANT* pvarModifyTime) mut => VT.[Friend]get_ModifyTime(&this, pvarModifyTime);

	public HRESULT get_Authenticate(int32* plAuthenticate) mut => VT.[Friend]get_Authenticate(&this, plAuthenticate);

	public HRESULT put_Authenticate(int32 lAuthenticate) mut => VT.[Friend]put_Authenticate(&this, lAuthenticate);

	public HRESULT get_JournalQuota(int32* plJournalQuota) mut => VT.[Friend]get_JournalQuota(&this, plJournalQuota);

	public HRESULT put_JournalQuota(int32 lJournalQuota) mut => VT.[Friend]put_JournalQuota(&this, lJournalQuota);

	public HRESULT get_IsWorldReadable(int16* pisWorldReadable) mut => VT.[Friend]get_IsWorldReadable(&this, pisWorldReadable);

	public HRESULT Create(VARIANT* IsTransactional, VARIANT* IsWorldReadable) mut => VT.[Friend]Create(&this, IsTransactional, IsWorldReadable);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Open(int32 Access, int32 ShareMode, IMSMQQueue4** ppq) mut => VT.[Friend]Open(&this, Access, ShareMode, ppq);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Update() mut => VT.[Friend]Update(&this);

	public HRESULT get_PathNameDNS(BSTR* pbstrPathNameDNS) mut => VT.[Friend]get_PathNameDNS(&this, pbstrPathNameDNS);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);

	public HRESULT get_Security(VARIANT* pvarSecurity) mut => VT.[Friend]get_Security(&this, pvarSecurity);

	public HRESULT put_Security(VARIANT varSecurity) mut => VT.[Friend]put_Security(&this, varSecurity);

	public HRESULT get_IsTransactional2(int16* pisTransactional) mut => VT.[Friend]get_IsTransactional2(&this, pisTransactional);

	public HRESULT get_IsWorldReadable2(int16* pisWorldReadable) mut => VT.[Friend]get_IsWorldReadable2(&this, pisWorldReadable);

	public HRESULT get_MulticastAddress(BSTR* pbstrMulticastAddress) mut => VT.[Friend]get_MulticastAddress(&this, pbstrMulticastAddress);

	public HRESULT put_MulticastAddress(BSTR bstrMulticastAddress) mut => VT.[Friend]put_MulticastAddress(&this, bstrMulticastAddress);

	public HRESULT get_ADsPath(BSTR* pbstrADsPath) mut => VT.[Friend]get_ADsPath(&this, pbstrADsPath);
}

[CRepr]struct IMSMQQueue : IDispatch
{
	public new const Guid IID = .(0xd7d6e076, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAccess) get_Access;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plShareMode) get_ShareMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfo) get_QueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisOpen) get_IsOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) Receive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) Peek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQEvent* Event, VARIANT* Cursor, VARIANT* ReceiveTimeout) EnableNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) ReceiveCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) PeekNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) PeekCurrent;
	}


	public HRESULT get_Access(int32* plAccess) mut => VT.[Friend]get_Access(&this, plAccess);

	public HRESULT get_ShareMode(int32* plShareMode) mut => VT.[Friend]get_ShareMode(&this, plShareMode);

	public HRESULT get_QueueInfo(IMSMQQueueInfo** ppqinfo) mut => VT.[Friend]get_QueueInfo(&this, ppqinfo);

	public HRESULT get_Handle(int32* plHandle) mut => VT.[Friend]get_Handle(&this, plHandle);

	public HRESULT get_IsOpen(int16* pisOpen) mut => VT.[Friend]get_IsOpen(&this, pisOpen);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT Receive(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]Receive(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT Peek(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]Peek(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT EnableNotification(IMSMQEvent* Event, VARIANT* Cursor, VARIANT* ReceiveTimeout) mut => VT.[Friend]EnableNotification(&this, Event, Cursor, ReceiveTimeout);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT ReceiveCurrent(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]ReceiveCurrent(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT PeekNext(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]PeekNext(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT PeekCurrent(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]PeekCurrent(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);
}

[CRepr]struct IMSMQQueue2 : IDispatch
{
	public new const Guid IID = .(0xef0574e0, 0x06d8, 0x11d3, 0xb1, 0x00, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAccess) get_Access;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plShareMode) get_ShareMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2** ppqinfo) get_QueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisOpen) get_IsOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) Receive_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) Peek_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQEvent2* Event, VARIANT* Cursor, VARIANT* ReceiveTimeout) EnableNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) ReceiveCurrent_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) PeekNext_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) PeekCurrent_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage2** ppmsg) Receive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage2** ppmsg) Peek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage2** ppmsg) ReceiveCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage2** ppmsg) PeekNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage2** ppmsg) PeekCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT get_Access(int32* plAccess) mut => VT.[Friend]get_Access(&this, plAccess);

	public HRESULT get_ShareMode(int32* plShareMode) mut => VT.[Friend]get_ShareMode(&this, plShareMode);

	public HRESULT get_QueueInfo(IMSMQQueueInfo2** ppqinfo) mut => VT.[Friend]get_QueueInfo(&this, ppqinfo);

	public HRESULT get_Handle(int32* plHandle) mut => VT.[Friend]get_Handle(&this, plHandle);

	public HRESULT get_IsOpen(int16* pisOpen) mut => VT.[Friend]get_IsOpen(&this, pisOpen);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT Receive_v1(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]Receive_v1(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT Peek_v1(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]Peek_v1(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT EnableNotification(IMSMQEvent2* Event, VARIANT* Cursor, VARIANT* ReceiveTimeout) mut => VT.[Friend]EnableNotification(&this, Event, Cursor, ReceiveTimeout);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT ReceiveCurrent_v1(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]ReceiveCurrent_v1(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT PeekNext_v1(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]PeekNext_v1(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT PeekCurrent_v1(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]PeekCurrent_v1(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT Receive(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage2** ppmsg) mut => VT.[Friend]Receive(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT Peek(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage2** ppmsg) mut => VT.[Friend]Peek(&this, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT ReceiveCurrent(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage2** ppmsg) mut => VT.[Friend]ReceiveCurrent(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT PeekNext(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage2** ppmsg) mut => VT.[Friend]PeekNext(&this, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT PeekCurrent(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage2** ppmsg) mut => VT.[Friend]PeekCurrent(&this, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQQueue3 : IDispatch
{
	public new const Guid IID = .(0xeba96b1b, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAccess) get_Access;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plShareMode) get_ShareMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo3** ppqinfo) get_QueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisOpen) get_IsOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) Receive_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) Peek_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQEvent3* Event, VARIANT* Cursor, VARIANT* ReceiveTimeout) EnableNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) ReceiveCurrent_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) PeekNext_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) PeekCurrent_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) Receive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) Peek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) ReceiveCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) PeekNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) PeekCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarHandle) get_Handle2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) ReceiveByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) ReceiveNextByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) ReceivePreviousByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) ReceiveFirstByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) ReceiveLastByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) PeekByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) PeekNextByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) PeekPreviousByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) PeekFirstByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) PeekLastByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Purge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisOpen) get_IsOpen2;
	}


	public HRESULT get_Access(int32* plAccess) mut => VT.[Friend]get_Access(&this, plAccess);

	public HRESULT get_ShareMode(int32* plShareMode) mut => VT.[Friend]get_ShareMode(&this, plShareMode);

	public HRESULT get_QueueInfo(IMSMQQueueInfo3** ppqinfo) mut => VT.[Friend]get_QueueInfo(&this, ppqinfo);

	public HRESULT get_Handle(int32* plHandle) mut => VT.[Friend]get_Handle(&this, plHandle);

	public HRESULT get_IsOpen(int16* pisOpen) mut => VT.[Friend]get_IsOpen(&this, pisOpen);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT Receive_v1(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]Receive_v1(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT Peek_v1(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]Peek_v1(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT EnableNotification(IMSMQEvent3* Event, VARIANT* Cursor, VARIANT* ReceiveTimeout) mut => VT.[Friend]EnableNotification(&this, Event, Cursor, ReceiveTimeout);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT ReceiveCurrent_v1(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]ReceiveCurrent_v1(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT PeekNext_v1(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]PeekNext_v1(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT PeekCurrent_v1(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]PeekCurrent_v1(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT Receive(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]Receive(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT Peek(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]Peek(&this, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT ReceiveCurrent(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]ReceiveCurrent(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT PeekNext(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]PeekNext(&this, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT PeekCurrent(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]PeekCurrent(&this, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);

	public HRESULT get_Handle2(VARIANT* pvarHandle) mut => VT.[Friend]get_Handle2(&this, pvarHandle);

	public HRESULT ReceiveByLookupId(VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]ReceiveByLookupId(&this, LookupId, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT ReceiveNextByLookupId(VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]ReceiveNextByLookupId(&this, LookupId, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT ReceivePreviousByLookupId(VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]ReceivePreviousByLookupId(&this, LookupId, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT ReceiveFirstByLookupId(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]ReceiveFirstByLookupId(&this, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT ReceiveLastByLookupId(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]ReceiveLastByLookupId(&this, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT PeekByLookupId(VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]PeekByLookupId(&this, LookupId, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT PeekNextByLookupId(VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]PeekNextByLookupId(&this, LookupId, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT PeekPreviousByLookupId(VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]PeekPreviousByLookupId(&this, LookupId, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT PeekFirstByLookupId(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]PeekFirstByLookupId(&this, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT PeekLastByLookupId(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage3** ppmsg) mut => VT.[Friend]PeekLastByLookupId(&this, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT Purge() mut => VT.[Friend]Purge(&this);

	public HRESULT get_IsOpen2(int16* pisOpen) mut => VT.[Friend]get_IsOpen2(&this, pisOpen);
}

[CRepr]struct IMSMQQueue4 : IDispatch
{
	public new const Guid IID = .(0xeba96b20, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAccess) get_Access;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plShareMode) get_ShareMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo4** ppqinfo) get_QueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisOpen) get_IsOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) Receive_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) Peek_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQEvent3* Event, VARIANT* Cursor, VARIANT* ReceiveTimeout) EnableNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) ReceiveCurrent_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) PeekNext_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) PeekCurrent_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) Receive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) Peek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) ReceiveCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) PeekNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) PeekCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarHandle) get_Handle2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) ReceiveByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) ReceiveNextByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) ReceivePreviousByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) ReceiveFirstByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) ReceiveLastByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) PeekByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) PeekNextByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) PeekPreviousByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) PeekFirstByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) PeekLastByLookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Purge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisOpen) get_IsOpen2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) ReceiveByLookupIdAllowPeek;
	}


	public HRESULT get_Access(int32* plAccess) mut => VT.[Friend]get_Access(&this, plAccess);

	public HRESULT get_ShareMode(int32* plShareMode) mut => VT.[Friend]get_ShareMode(&this, plShareMode);

	public HRESULT get_QueueInfo(IMSMQQueueInfo4** ppqinfo) mut => VT.[Friend]get_QueueInfo(&this, ppqinfo);

	public HRESULT get_Handle(int32* plHandle) mut => VT.[Friend]get_Handle(&this, plHandle);

	public HRESULT get_IsOpen(int16* pisOpen) mut => VT.[Friend]get_IsOpen(&this, pisOpen);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT Receive_v1(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]Receive_v1(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT Peek_v1(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]Peek_v1(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT EnableNotification(IMSMQEvent3* Event, VARIANT* Cursor, VARIANT* ReceiveTimeout) mut => VT.[Friend]EnableNotification(&this, Event, Cursor, ReceiveTimeout);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT ReceiveCurrent_v1(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]ReceiveCurrent_v1(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT PeekNext_v1(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]PeekNext_v1(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT PeekCurrent_v1(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, IMSMQMessage** ppmsg) mut => VT.[Friend]PeekCurrent_v1(&this, WantDestinationQueue, WantBody, ReceiveTimeout, ppmsg);

	public HRESULT Receive(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]Receive(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT Peek(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]Peek(&this, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT ReceiveCurrent(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]ReceiveCurrent(&this, Transaction, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT PeekNext(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]PeekNext(&this, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT PeekCurrent(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* ReceiveTimeout, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]PeekCurrent(&this, WantDestinationQueue, WantBody, ReceiveTimeout, WantConnectorType, ppmsg);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);

	public HRESULT get_Handle2(VARIANT* pvarHandle) mut => VT.[Friend]get_Handle2(&this, pvarHandle);

	public HRESULT ReceiveByLookupId(VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]ReceiveByLookupId(&this, LookupId, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT ReceiveNextByLookupId(VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]ReceiveNextByLookupId(&this, LookupId, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT ReceivePreviousByLookupId(VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]ReceivePreviousByLookupId(&this, LookupId, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT ReceiveFirstByLookupId(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]ReceiveFirstByLookupId(&this, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT ReceiveLastByLookupId(VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]ReceiveLastByLookupId(&this, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT PeekByLookupId(VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]PeekByLookupId(&this, LookupId, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT PeekNextByLookupId(VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]PeekNextByLookupId(&this, LookupId, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT PeekPreviousByLookupId(VARIANT LookupId, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]PeekPreviousByLookupId(&this, LookupId, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT PeekFirstByLookupId(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]PeekFirstByLookupId(&this, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT PeekLastByLookupId(VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]PeekLastByLookupId(&this, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);

	public HRESULT Purge() mut => VT.[Friend]Purge(&this);

	public HRESULT get_IsOpen2(int16* pisOpen) mut => VT.[Friend]get_IsOpen2(&this, pisOpen);

	public HRESULT ReceiveByLookupIdAllowPeek(VARIANT LookupId, VARIANT* Transaction, VARIANT* WantDestinationQueue, VARIANT* WantBody, VARIANT* WantConnectorType, IMSMQMessage4** ppmsg) mut => VT.[Friend]ReceiveByLookupIdAllowPeek(&this, LookupId, Transaction, WantDestinationQueue, WantBody, WantConnectorType, ppmsg);
}

[CRepr]struct IMSMQMessage : IDispatch
{
	public new const Guid IID = .(0xd7d6e074, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plClass) get_Class;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPrivLevel) get_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrivLevel) put_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthLevel) get_AuthLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthLevel) put_AuthLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisAuthenticated) get_IsAuthenticated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDelivery) get_Delivery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDelivery) put_Delivery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plTrace) get_Trace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lTrace) put_Trace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPriority) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPriority) put_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournal) get_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournal) put_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfoResponse) get_ResponseQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo* pqinfoResponse) putref_ResponseQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAppSpecific) get_AppSpecific;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAppSpecific) put_AppSpecific;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidSrcMachine) get_SourceMachineGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcbBody) get_BodyLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarBody) get_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varBody) put_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfoAdmin) get_AdminQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo* pqinfoAdmin) putref_AdminQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarMsgId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarMsgId) get_CorrelationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varMsgId) put_CorrelationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAck) get_Ack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAck) put_Ack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLabel) get_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLabel) put_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaxTimeToReachQueue) get_MaxTimeToReachQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMaxTimeToReachQueue) put_MaxTimeToReachQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaxTimeToReceive) get_MaxTimeToReceive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMaxTimeToReceive) put_MaxTimeToReceive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHashAlg) get_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lHashAlg) put_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plEncryptAlg) get_EncryptAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lEncryptAlg) put_EncryptAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSentTime) get_SentTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* plArrivedTime) get_ArrivedTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfoDest) get_DestinationQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSenderCert) get_SenderCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSenderCert) put_SenderCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSenderId) get_SenderId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSenderIdType) get_SenderIdType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSenderIdType) put_SenderIdType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueue* DestinationQueue, VARIANT* Transaction) Send;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AttachCurrentSecurityContext;
	}


	public HRESULT get_Class(int32* plClass) mut => VT.[Friend]get_Class(&this, plClass);

	public HRESULT get_PrivLevel(int32* plPrivLevel) mut => VT.[Friend]get_PrivLevel(&this, plPrivLevel);

	public HRESULT put_PrivLevel(int32 lPrivLevel) mut => VT.[Friend]put_PrivLevel(&this, lPrivLevel);

	public HRESULT get_AuthLevel(int32* plAuthLevel) mut => VT.[Friend]get_AuthLevel(&this, plAuthLevel);

	public HRESULT put_AuthLevel(int32 lAuthLevel) mut => VT.[Friend]put_AuthLevel(&this, lAuthLevel);

	public HRESULT get_IsAuthenticated(int16* pisAuthenticated) mut => VT.[Friend]get_IsAuthenticated(&this, pisAuthenticated);

	public HRESULT get_Delivery(int32* plDelivery) mut => VT.[Friend]get_Delivery(&this, plDelivery);

	public HRESULT put_Delivery(int32 lDelivery) mut => VT.[Friend]put_Delivery(&this, lDelivery);

	public HRESULT get_Trace(int32* plTrace) mut => VT.[Friend]get_Trace(&this, plTrace);

	public HRESULT put_Trace(int32 lTrace) mut => VT.[Friend]put_Trace(&this, lTrace);

	public HRESULT get_Priority(int32* plPriority) mut => VT.[Friend]get_Priority(&this, plPriority);

	public HRESULT put_Priority(int32 lPriority) mut => VT.[Friend]put_Priority(&this, lPriority);

	public HRESULT get_Journal(int32* plJournal) mut => VT.[Friend]get_Journal(&this, plJournal);

	public HRESULT put_Journal(int32 lJournal) mut => VT.[Friend]put_Journal(&this, lJournal);

	public HRESULT get_ResponseQueueInfo(IMSMQQueueInfo** ppqinfoResponse) mut => VT.[Friend]get_ResponseQueueInfo(&this, ppqinfoResponse);

	public HRESULT putref_ResponseQueueInfo(IMSMQQueueInfo* pqinfoResponse) mut => VT.[Friend]putref_ResponseQueueInfo(&this, pqinfoResponse);

	public HRESULT get_AppSpecific(int32* plAppSpecific) mut => VT.[Friend]get_AppSpecific(&this, plAppSpecific);

	public HRESULT put_AppSpecific(int32 lAppSpecific) mut => VT.[Friend]put_AppSpecific(&this, lAppSpecific);

	public HRESULT get_SourceMachineGuid(BSTR* pbstrGuidSrcMachine) mut => VT.[Friend]get_SourceMachineGuid(&this, pbstrGuidSrcMachine);

	public HRESULT get_BodyLength(int32* pcbBody) mut => VT.[Friend]get_BodyLength(&this, pcbBody);

	public HRESULT get_Body(VARIANT* pvarBody) mut => VT.[Friend]get_Body(&this, pvarBody);

	public HRESULT put_Body(VARIANT varBody) mut => VT.[Friend]put_Body(&this, varBody);

	public HRESULT get_AdminQueueInfo(IMSMQQueueInfo** ppqinfoAdmin) mut => VT.[Friend]get_AdminQueueInfo(&this, ppqinfoAdmin);

	public HRESULT putref_AdminQueueInfo(IMSMQQueueInfo* pqinfoAdmin) mut => VT.[Friend]putref_AdminQueueInfo(&this, pqinfoAdmin);

	public HRESULT get_Id(VARIANT* pvarMsgId) mut => VT.[Friend]get_Id(&this, pvarMsgId);

	public HRESULT get_CorrelationId(VARIANT* pvarMsgId) mut => VT.[Friend]get_CorrelationId(&this, pvarMsgId);

	public HRESULT put_CorrelationId(VARIANT varMsgId) mut => VT.[Friend]put_CorrelationId(&this, varMsgId);

	public HRESULT get_Ack(int32* plAck) mut => VT.[Friend]get_Ack(&this, plAck);

	public HRESULT put_Ack(int32 lAck) mut => VT.[Friend]put_Ack(&this, lAck);

	public HRESULT get_Label(BSTR* pbstrLabel) mut => VT.[Friend]get_Label(&this, pbstrLabel);

	public HRESULT put_Label(BSTR bstrLabel) mut => VT.[Friend]put_Label(&this, bstrLabel);

	public HRESULT get_MaxTimeToReachQueue(int32* plMaxTimeToReachQueue) mut => VT.[Friend]get_MaxTimeToReachQueue(&this, plMaxTimeToReachQueue);

	public HRESULT put_MaxTimeToReachQueue(int32 lMaxTimeToReachQueue) mut => VT.[Friend]put_MaxTimeToReachQueue(&this, lMaxTimeToReachQueue);

	public HRESULT get_MaxTimeToReceive(int32* plMaxTimeToReceive) mut => VT.[Friend]get_MaxTimeToReceive(&this, plMaxTimeToReceive);

	public HRESULT put_MaxTimeToReceive(int32 lMaxTimeToReceive) mut => VT.[Friend]put_MaxTimeToReceive(&this, lMaxTimeToReceive);

	public HRESULT get_HashAlgorithm(int32* plHashAlg) mut => VT.[Friend]get_HashAlgorithm(&this, plHashAlg);

	public HRESULT put_HashAlgorithm(int32 lHashAlg) mut => VT.[Friend]put_HashAlgorithm(&this, lHashAlg);

	public HRESULT get_EncryptAlgorithm(int32* plEncryptAlg) mut => VT.[Friend]get_EncryptAlgorithm(&this, plEncryptAlg);

	public HRESULT put_EncryptAlgorithm(int32 lEncryptAlg) mut => VT.[Friend]put_EncryptAlgorithm(&this, lEncryptAlg);

	public HRESULT get_SentTime(VARIANT* pvarSentTime) mut => VT.[Friend]get_SentTime(&this, pvarSentTime);

	public HRESULT get_ArrivedTime(VARIANT* plArrivedTime) mut => VT.[Friend]get_ArrivedTime(&this, plArrivedTime);

	public HRESULT get_DestinationQueueInfo(IMSMQQueueInfo** ppqinfoDest) mut => VT.[Friend]get_DestinationQueueInfo(&this, ppqinfoDest);

	public HRESULT get_SenderCertificate(VARIANT* pvarSenderCert) mut => VT.[Friend]get_SenderCertificate(&this, pvarSenderCert);

	public HRESULT put_SenderCertificate(VARIANT varSenderCert) mut => VT.[Friend]put_SenderCertificate(&this, varSenderCert);

	public HRESULT get_SenderId(VARIANT* pvarSenderId) mut => VT.[Friend]get_SenderId(&this, pvarSenderId);

	public HRESULT get_SenderIdType(int32* plSenderIdType) mut => VT.[Friend]get_SenderIdType(&this, plSenderIdType);

	public HRESULT put_SenderIdType(int32 lSenderIdType) mut => VT.[Friend]put_SenderIdType(&this, lSenderIdType);

	public HRESULT Send(IMSMQQueue* DestinationQueue, VARIANT* Transaction) mut => VT.[Friend]Send(&this, DestinationQueue, Transaction);

	public HRESULT AttachCurrentSecurityContext() mut => VT.[Friend]AttachCurrentSecurityContext(&this);
}

[CRepr]struct IMSMQQueueInfos : IDispatch
{
	public new const Guid IID = .(0xd7d6e07d, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfoNext) Next;
	}


	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Next(IMSMQQueueInfo** ppqinfoNext) mut => VT.[Friend]Next(&this, ppqinfoNext);
}

[CRepr]struct IMSMQQueueInfos2 : IDispatch
{
	public new const Guid IID = .(0xeba96b0f, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2** ppqinfoNext) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Next(IMSMQQueueInfo2** ppqinfoNext) mut => VT.[Friend]Next(&this, ppqinfoNext);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQQueueInfos3 : IDispatch
{
	public new const Guid IID = .(0xeba96b1e, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo3** ppqinfoNext) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Next(IMSMQQueueInfo3** ppqinfoNext) mut => VT.[Friend]Next(&this, ppqinfoNext);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQQueueInfos4 : IDispatch
{
	public new const Guid IID = .(0xeba96b22, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo4** ppqinfoNext) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Next(IMSMQQueueInfo4** ppqinfoNext) mut => VT.[Friend]Next(&this, ppqinfoNext);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQEvent : IDispatch
{
	public new const Guid IID = .(0xd7d6e077, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IMSMQEvent2 : IMSMQEvent
{
	public new const Guid IID = .(0xeba96b12, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMSMQEvent.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQEvent3 : IMSMQEvent2
{
	public new const Guid IID = .(0xeba96b1c, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMSMQEvent2.VTable
	{
	}

}

[CRepr]struct IMSMQTransaction : IDispatch
{
	public new const Guid IID = .(0xd7d6e07f, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plTransaction) get_Transaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* fRetaining, VARIANT* grfTC, VARIANT* grfRM) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* fRetaining, VARIANT* fAsync) Abort;
	}


	public HRESULT get_Transaction(int32* plTransaction) mut => VT.[Friend]get_Transaction(&this, plTransaction);

	public HRESULT Commit(VARIANT* fRetaining, VARIANT* grfTC, VARIANT* grfRM) mut => VT.[Friend]Commit(&this, fRetaining, grfTC, grfRM);

	public HRESULT Abort(VARIANT* fRetaining, VARIANT* fAsync) mut => VT.[Friend]Abort(&this, fRetaining, fAsync);
}

[CRepr]struct IMSMQCoordinatedTransactionDispenser : IDispatch
{
	public new const Guid IID = .(0xd7d6e081, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQTransaction** ptransaction) BeginTransaction;
	}


	public HRESULT BeginTransaction(IMSMQTransaction** ptransaction) mut => VT.[Friend]BeginTransaction(&this, ptransaction);
}

[CRepr]struct IMSMQTransactionDispenser : IDispatch
{
	public new const Guid IID = .(0xd7d6e083, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQTransaction** ptransaction) BeginTransaction;
	}


	public HRESULT BeginTransaction(IMSMQTransaction** ptransaction) mut => VT.[Friend]BeginTransaction(&this, ptransaction);
}

[CRepr]struct IMSMQQuery2 : IDispatch
{
	public new const Guid IID = .(0xeba96b0e, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, IMSMQQueueInfos2** ppqinfos) LookupQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT LookupQueue(VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, IMSMQQueueInfos2** ppqinfos) mut => VT.[Friend]LookupQueue(&this, QueueGuid, ServiceTypeGuid, Label, CreateTime, ModifyTime, RelServiceType, RelLabel, RelCreateTime, RelModifyTime, ppqinfos);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQQuery3 : IDispatch
{
	public new const Guid IID = .(0xeba96b19, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, IMSMQQueueInfos3** ppqinfos) LookupQueue_v2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, VARIANT* MulticastAddress, VARIANT* RelMulticastAddress, IMSMQQueueInfos3** ppqinfos) LookupQueue;
	}


	public HRESULT LookupQueue_v2(VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, IMSMQQueueInfos3** ppqinfos) mut => VT.[Friend]LookupQueue_v2(&this, QueueGuid, ServiceTypeGuid, Label, CreateTime, ModifyTime, RelServiceType, RelLabel, RelCreateTime, RelModifyTime, ppqinfos);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);

	public HRESULT LookupQueue(VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, VARIANT* MulticastAddress, VARIANT* RelMulticastAddress, IMSMQQueueInfos3** ppqinfos) mut => VT.[Friend]LookupQueue(&this, QueueGuid, ServiceTypeGuid, Label, CreateTime, ModifyTime, RelServiceType, RelLabel, RelCreateTime, RelModifyTime, MulticastAddress, RelMulticastAddress, ppqinfos);
}

[CRepr]struct IMSMQQuery4 : IDispatch
{
	public new const Guid IID = .(0xeba96b24, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, IMSMQQueueInfos4** ppqinfos) LookupQueue_v2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, VARIANT* MulticastAddress, VARIANT* RelMulticastAddress, IMSMQQueueInfos4** ppqinfos) LookupQueue;
	}


	public HRESULT LookupQueue_v2(VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, IMSMQQueueInfos4** ppqinfos) mut => VT.[Friend]LookupQueue_v2(&this, QueueGuid, ServiceTypeGuid, Label, CreateTime, ModifyTime, RelServiceType, RelLabel, RelCreateTime, RelModifyTime, ppqinfos);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);

	public HRESULT LookupQueue(VARIANT* QueueGuid, VARIANT* ServiceTypeGuid, VARIANT* Label, VARIANT* CreateTime, VARIANT* ModifyTime, VARIANT* RelServiceType, VARIANT* RelLabel, VARIANT* RelCreateTime, VARIANT* RelModifyTime, VARIANT* MulticastAddress, VARIANT* RelMulticastAddress, IMSMQQueueInfos4** ppqinfos) mut => VT.[Friend]LookupQueue(&this, QueueGuid, ServiceTypeGuid, Label, CreateTime, ModifyTime, RelServiceType, RelLabel, RelCreateTime, RelModifyTime, MulticastAddress, RelMulticastAddress, ppqinfos);
}

[CRepr]struct IMSMQMessage2 : IDispatch
{
	public new const Guid IID = .(0xd9933be0, 0xa567, 0x11d2, 0xb0, 0xf3, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plClass) get_Class;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPrivLevel) get_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrivLevel) put_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthLevel) get_AuthLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthLevel) put_AuthLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisAuthenticated) get_IsAuthenticated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDelivery) get_Delivery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDelivery) put_Delivery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plTrace) get_Trace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lTrace) put_Trace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPriority) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPriority) put_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournal) get_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournal) put_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfoResponse) get_ResponseQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo* pqinfoResponse) putref_ResponseQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAppSpecific) get_AppSpecific;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAppSpecific) put_AppSpecific;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidSrcMachine) get_SourceMachineGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcbBody) get_BodyLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarBody) get_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varBody) put_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfoAdmin) get_AdminQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo* pqinfoAdmin) putref_AdminQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarMsgId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarMsgId) get_CorrelationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varMsgId) put_CorrelationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAck) get_Ack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAck) put_Ack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLabel) get_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLabel) put_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaxTimeToReachQueue) get_MaxTimeToReachQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMaxTimeToReachQueue) put_MaxTimeToReachQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaxTimeToReceive) get_MaxTimeToReceive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMaxTimeToReceive) put_MaxTimeToReceive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHashAlg) get_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lHashAlg) put_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plEncryptAlg) get_EncryptAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lEncryptAlg) put_EncryptAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSentTime) get_SentTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* plArrivedTime) get_ArrivedTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2** ppqinfoDest) get_DestinationQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSenderCert) get_SenderCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSenderCert) put_SenderCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSenderId) get_SenderId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSenderIdType) get_SenderIdType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSenderIdType) put_SenderIdType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueue2* DestinationQueue, VARIANT* Transaction) Send;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AttachCurrentSecurityContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSenderVersion) get_SenderVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarExtension) get_Extension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varExtension) put_Extension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidConnectorType) get_ConnectorTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGuidConnectorType) put_ConnectorTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2** ppqinfoXactStatus) get_TransactionStatusQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarDestSymmKey) get_DestinationSymmetricKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varDestSymmKey) put_DestinationSymmetricKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSignature) get_Signature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSignature) put_Signature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthProvType) get_AuthenticationProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthProvType) put_AuthenticationProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrAuthProvName) get_AuthenticationProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAuthProvName) put_AuthenticationProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSenderId) put_SenderId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMsgClass) get_MsgClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMsgClass) put_MsgClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarXactId) get_TransactionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisFirstInXact) get_IsFirstInTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisLastInXact) get_IsLastInTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2** ppqinfoResponse) get_ResponseQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2* pqinfoResponse) putref_ResponseQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2** ppqinfoAdmin) get_AdminQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2* pqinfoAdmin) putref_AdminQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* psReceivedAuthenticationLevel) get_ReceivedAuthenticationLevel;
	}


	public HRESULT get_Class(int32* plClass) mut => VT.[Friend]get_Class(&this, plClass);

	public HRESULT get_PrivLevel(int32* plPrivLevel) mut => VT.[Friend]get_PrivLevel(&this, plPrivLevel);

	public HRESULT put_PrivLevel(int32 lPrivLevel) mut => VT.[Friend]put_PrivLevel(&this, lPrivLevel);

	public HRESULT get_AuthLevel(int32* plAuthLevel) mut => VT.[Friend]get_AuthLevel(&this, plAuthLevel);

	public HRESULT put_AuthLevel(int32 lAuthLevel) mut => VT.[Friend]put_AuthLevel(&this, lAuthLevel);

	public HRESULT get_IsAuthenticated(int16* pisAuthenticated) mut => VT.[Friend]get_IsAuthenticated(&this, pisAuthenticated);

	public HRESULT get_Delivery(int32* plDelivery) mut => VT.[Friend]get_Delivery(&this, plDelivery);

	public HRESULT put_Delivery(int32 lDelivery) mut => VT.[Friend]put_Delivery(&this, lDelivery);

	public HRESULT get_Trace(int32* plTrace) mut => VT.[Friend]get_Trace(&this, plTrace);

	public HRESULT put_Trace(int32 lTrace) mut => VT.[Friend]put_Trace(&this, lTrace);

	public HRESULT get_Priority(int32* plPriority) mut => VT.[Friend]get_Priority(&this, plPriority);

	public HRESULT put_Priority(int32 lPriority) mut => VT.[Friend]put_Priority(&this, lPriority);

	public HRESULT get_Journal(int32* plJournal) mut => VT.[Friend]get_Journal(&this, plJournal);

	public HRESULT put_Journal(int32 lJournal) mut => VT.[Friend]put_Journal(&this, lJournal);

	public HRESULT get_ResponseQueueInfo_v1(IMSMQQueueInfo** ppqinfoResponse) mut => VT.[Friend]get_ResponseQueueInfo_v1(&this, ppqinfoResponse);

	public HRESULT putref_ResponseQueueInfo_v1(IMSMQQueueInfo* pqinfoResponse) mut => VT.[Friend]putref_ResponseQueueInfo_v1(&this, pqinfoResponse);

	public HRESULT get_AppSpecific(int32* plAppSpecific) mut => VT.[Friend]get_AppSpecific(&this, plAppSpecific);

	public HRESULT put_AppSpecific(int32 lAppSpecific) mut => VT.[Friend]put_AppSpecific(&this, lAppSpecific);

	public HRESULT get_SourceMachineGuid(BSTR* pbstrGuidSrcMachine) mut => VT.[Friend]get_SourceMachineGuid(&this, pbstrGuidSrcMachine);

	public HRESULT get_BodyLength(int32* pcbBody) mut => VT.[Friend]get_BodyLength(&this, pcbBody);

	public HRESULT get_Body(VARIANT* pvarBody) mut => VT.[Friend]get_Body(&this, pvarBody);

	public HRESULT put_Body(VARIANT varBody) mut => VT.[Friend]put_Body(&this, varBody);

	public HRESULT get_AdminQueueInfo_v1(IMSMQQueueInfo** ppqinfoAdmin) mut => VT.[Friend]get_AdminQueueInfo_v1(&this, ppqinfoAdmin);

	public HRESULT putref_AdminQueueInfo_v1(IMSMQQueueInfo* pqinfoAdmin) mut => VT.[Friend]putref_AdminQueueInfo_v1(&this, pqinfoAdmin);

	public HRESULT get_Id(VARIANT* pvarMsgId) mut => VT.[Friend]get_Id(&this, pvarMsgId);

	public HRESULT get_CorrelationId(VARIANT* pvarMsgId) mut => VT.[Friend]get_CorrelationId(&this, pvarMsgId);

	public HRESULT put_CorrelationId(VARIANT varMsgId) mut => VT.[Friend]put_CorrelationId(&this, varMsgId);

	public HRESULT get_Ack(int32* plAck) mut => VT.[Friend]get_Ack(&this, plAck);

	public HRESULT put_Ack(int32 lAck) mut => VT.[Friend]put_Ack(&this, lAck);

	public HRESULT get_Label(BSTR* pbstrLabel) mut => VT.[Friend]get_Label(&this, pbstrLabel);

	public HRESULT put_Label(BSTR bstrLabel) mut => VT.[Friend]put_Label(&this, bstrLabel);

	public HRESULT get_MaxTimeToReachQueue(int32* plMaxTimeToReachQueue) mut => VT.[Friend]get_MaxTimeToReachQueue(&this, plMaxTimeToReachQueue);

	public HRESULT put_MaxTimeToReachQueue(int32 lMaxTimeToReachQueue) mut => VT.[Friend]put_MaxTimeToReachQueue(&this, lMaxTimeToReachQueue);

	public HRESULT get_MaxTimeToReceive(int32* plMaxTimeToReceive) mut => VT.[Friend]get_MaxTimeToReceive(&this, plMaxTimeToReceive);

	public HRESULT put_MaxTimeToReceive(int32 lMaxTimeToReceive) mut => VT.[Friend]put_MaxTimeToReceive(&this, lMaxTimeToReceive);

	public HRESULT get_HashAlgorithm(int32* plHashAlg) mut => VT.[Friend]get_HashAlgorithm(&this, plHashAlg);

	public HRESULT put_HashAlgorithm(int32 lHashAlg) mut => VT.[Friend]put_HashAlgorithm(&this, lHashAlg);

	public HRESULT get_EncryptAlgorithm(int32* plEncryptAlg) mut => VT.[Friend]get_EncryptAlgorithm(&this, plEncryptAlg);

	public HRESULT put_EncryptAlgorithm(int32 lEncryptAlg) mut => VT.[Friend]put_EncryptAlgorithm(&this, lEncryptAlg);

	public HRESULT get_SentTime(VARIANT* pvarSentTime) mut => VT.[Friend]get_SentTime(&this, pvarSentTime);

	public HRESULT get_ArrivedTime(VARIANT* plArrivedTime) mut => VT.[Friend]get_ArrivedTime(&this, plArrivedTime);

	public HRESULT get_DestinationQueueInfo(IMSMQQueueInfo2** ppqinfoDest) mut => VT.[Friend]get_DestinationQueueInfo(&this, ppqinfoDest);

	public HRESULT get_SenderCertificate(VARIANT* pvarSenderCert) mut => VT.[Friend]get_SenderCertificate(&this, pvarSenderCert);

	public HRESULT put_SenderCertificate(VARIANT varSenderCert) mut => VT.[Friend]put_SenderCertificate(&this, varSenderCert);

	public HRESULT get_SenderId(VARIANT* pvarSenderId) mut => VT.[Friend]get_SenderId(&this, pvarSenderId);

	public HRESULT get_SenderIdType(int32* plSenderIdType) mut => VT.[Friend]get_SenderIdType(&this, plSenderIdType);

	public HRESULT put_SenderIdType(int32 lSenderIdType) mut => VT.[Friend]put_SenderIdType(&this, lSenderIdType);

	public HRESULT Send(IMSMQQueue2* DestinationQueue, VARIANT* Transaction) mut => VT.[Friend]Send(&this, DestinationQueue, Transaction);

	public HRESULT AttachCurrentSecurityContext() mut => VT.[Friend]AttachCurrentSecurityContext(&this);

	public HRESULT get_SenderVersion(int32* plSenderVersion) mut => VT.[Friend]get_SenderVersion(&this, plSenderVersion);

	public HRESULT get_Extension(VARIANT* pvarExtension) mut => VT.[Friend]get_Extension(&this, pvarExtension);

	public HRESULT put_Extension(VARIANT varExtension) mut => VT.[Friend]put_Extension(&this, varExtension);

	public HRESULT get_ConnectorTypeGuid(BSTR* pbstrGuidConnectorType) mut => VT.[Friend]get_ConnectorTypeGuid(&this, pbstrGuidConnectorType);

	public HRESULT put_ConnectorTypeGuid(BSTR bstrGuidConnectorType) mut => VT.[Friend]put_ConnectorTypeGuid(&this, bstrGuidConnectorType);

	public HRESULT get_TransactionStatusQueueInfo(IMSMQQueueInfo2** ppqinfoXactStatus) mut => VT.[Friend]get_TransactionStatusQueueInfo(&this, ppqinfoXactStatus);

	public HRESULT get_DestinationSymmetricKey(VARIANT* pvarDestSymmKey) mut => VT.[Friend]get_DestinationSymmetricKey(&this, pvarDestSymmKey);

	public HRESULT put_DestinationSymmetricKey(VARIANT varDestSymmKey) mut => VT.[Friend]put_DestinationSymmetricKey(&this, varDestSymmKey);

	public HRESULT get_Signature(VARIANT* pvarSignature) mut => VT.[Friend]get_Signature(&this, pvarSignature);

	public HRESULT put_Signature(VARIANT varSignature) mut => VT.[Friend]put_Signature(&this, varSignature);

	public HRESULT get_AuthenticationProviderType(int32* plAuthProvType) mut => VT.[Friend]get_AuthenticationProviderType(&this, plAuthProvType);

	public HRESULT put_AuthenticationProviderType(int32 lAuthProvType) mut => VT.[Friend]put_AuthenticationProviderType(&this, lAuthProvType);

	public HRESULT get_AuthenticationProviderName(BSTR* pbstrAuthProvName) mut => VT.[Friend]get_AuthenticationProviderName(&this, pbstrAuthProvName);

	public HRESULT put_AuthenticationProviderName(BSTR bstrAuthProvName) mut => VT.[Friend]put_AuthenticationProviderName(&this, bstrAuthProvName);

	public HRESULT put_SenderId(VARIANT varSenderId) mut => VT.[Friend]put_SenderId(&this, varSenderId);

	public HRESULT get_MsgClass(int32* plMsgClass) mut => VT.[Friend]get_MsgClass(&this, plMsgClass);

	public HRESULT put_MsgClass(int32 lMsgClass) mut => VT.[Friend]put_MsgClass(&this, lMsgClass);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);

	public HRESULT get_TransactionId(VARIANT* pvarXactId) mut => VT.[Friend]get_TransactionId(&this, pvarXactId);

	public HRESULT get_IsFirstInTransaction(int16* pisFirstInXact) mut => VT.[Friend]get_IsFirstInTransaction(&this, pisFirstInXact);

	public HRESULT get_IsLastInTransaction(int16* pisLastInXact) mut => VT.[Friend]get_IsLastInTransaction(&this, pisLastInXact);

	public HRESULT get_ResponseQueueInfo(IMSMQQueueInfo2** ppqinfoResponse) mut => VT.[Friend]get_ResponseQueueInfo(&this, ppqinfoResponse);

	public HRESULT putref_ResponseQueueInfo(IMSMQQueueInfo2* pqinfoResponse) mut => VT.[Friend]putref_ResponseQueueInfo(&this, pqinfoResponse);

	public HRESULT get_AdminQueueInfo(IMSMQQueueInfo2** ppqinfoAdmin) mut => VT.[Friend]get_AdminQueueInfo(&this, ppqinfoAdmin);

	public HRESULT putref_AdminQueueInfo(IMSMQQueueInfo2* pqinfoAdmin) mut => VT.[Friend]putref_AdminQueueInfo(&this, pqinfoAdmin);

	public HRESULT get_ReceivedAuthenticationLevel(int16* psReceivedAuthenticationLevel) mut => VT.[Friend]get_ReceivedAuthenticationLevel(&this, psReceivedAuthenticationLevel);
}

[CRepr]struct IMSMQMessage3 : IDispatch
{
	public new const Guid IID = .(0xeba96b1a, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plClass) get_Class;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPrivLevel) get_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrivLevel) put_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthLevel) get_AuthLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthLevel) put_AuthLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisAuthenticated) get_IsAuthenticated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDelivery) get_Delivery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDelivery) put_Delivery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plTrace) get_Trace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lTrace) put_Trace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPriority) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPriority) put_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournal) get_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournal) put_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfoResponse) get_ResponseQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo* pqinfoResponse) putref_ResponseQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAppSpecific) get_AppSpecific;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAppSpecific) put_AppSpecific;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidSrcMachine) get_SourceMachineGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcbBody) get_BodyLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarBody) get_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varBody) put_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfoAdmin) get_AdminQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo* pqinfoAdmin) putref_AdminQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarMsgId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarMsgId) get_CorrelationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varMsgId) put_CorrelationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAck) get_Ack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAck) put_Ack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLabel) get_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLabel) put_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaxTimeToReachQueue) get_MaxTimeToReachQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMaxTimeToReachQueue) put_MaxTimeToReachQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaxTimeToReceive) get_MaxTimeToReceive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMaxTimeToReceive) put_MaxTimeToReceive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHashAlg) get_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lHashAlg) put_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plEncryptAlg) get_EncryptAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lEncryptAlg) put_EncryptAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSentTime) get_SentTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* plArrivedTime) get_ArrivedTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo3** ppqinfoDest) get_DestinationQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSenderCert) get_SenderCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSenderCert) put_SenderCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSenderId) get_SenderId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSenderIdType) get_SenderIdType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSenderIdType) put_SenderIdType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* DestinationQueue, VARIANT* Transaction) Send;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AttachCurrentSecurityContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSenderVersion) get_SenderVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarExtension) get_Extension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varExtension) put_Extension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidConnectorType) get_ConnectorTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGuidConnectorType) put_ConnectorTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo3** ppqinfoXactStatus) get_TransactionStatusQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarDestSymmKey) get_DestinationSymmetricKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varDestSymmKey) put_DestinationSymmetricKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSignature) get_Signature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSignature) put_Signature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthProvType) get_AuthenticationProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthProvType) put_AuthenticationProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrAuthProvName) get_AuthenticationProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAuthProvName) put_AuthenticationProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSenderId) put_SenderId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMsgClass) get_MsgClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMsgClass) put_MsgClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarXactId) get_TransactionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisFirstInXact) get_IsFirstInTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisLastInXact) get_IsLastInTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2** ppqinfoResponse) get_ResponseQueueInfo_v2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2* pqinfoResponse) putref_ResponseQueueInfo_v2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2** ppqinfoAdmin) get_AdminQueueInfo_v2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2* pqinfoAdmin) putref_AdminQueueInfo_v2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* psReceivedAuthenticationLevel) get_ReceivedAuthenticationLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo3** ppqinfoResponse) get_ResponseQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo3* pqinfoResponse) putref_ResponseQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo3** ppqinfoAdmin) get_AdminQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo3* pqinfoAdmin) putref_AdminQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppdestResponse) get_ResponseDestination;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pdestResponse) putref_ResponseDestination;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppdestDestination) get_Destination;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarLookupId) get_LookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisAuthenticated) get_IsAuthenticated2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisFirstInXact) get_IsFirstInTransaction2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisLastInXact) get_IsLastInTransaction2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AttachCurrentSecurityContext2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSoapEnvelope) get_SoapEnvelope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarCompoundMessage) get_CompoundMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSoapHeader) put_SoapHeader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSoapBody) put_SoapBody;
	}


	public HRESULT get_Class(int32* plClass) mut => VT.[Friend]get_Class(&this, plClass);

	public HRESULT get_PrivLevel(int32* plPrivLevel) mut => VT.[Friend]get_PrivLevel(&this, plPrivLevel);

	public HRESULT put_PrivLevel(int32 lPrivLevel) mut => VT.[Friend]put_PrivLevel(&this, lPrivLevel);

	public HRESULT get_AuthLevel(int32* plAuthLevel) mut => VT.[Friend]get_AuthLevel(&this, plAuthLevel);

	public HRESULT put_AuthLevel(int32 lAuthLevel) mut => VT.[Friend]put_AuthLevel(&this, lAuthLevel);

	public HRESULT get_IsAuthenticated(int16* pisAuthenticated) mut => VT.[Friend]get_IsAuthenticated(&this, pisAuthenticated);

	public HRESULT get_Delivery(int32* plDelivery) mut => VT.[Friend]get_Delivery(&this, plDelivery);

	public HRESULT put_Delivery(int32 lDelivery) mut => VT.[Friend]put_Delivery(&this, lDelivery);

	public HRESULT get_Trace(int32* plTrace) mut => VT.[Friend]get_Trace(&this, plTrace);

	public HRESULT put_Trace(int32 lTrace) mut => VT.[Friend]put_Trace(&this, lTrace);

	public HRESULT get_Priority(int32* plPriority) mut => VT.[Friend]get_Priority(&this, plPriority);

	public HRESULT put_Priority(int32 lPriority) mut => VT.[Friend]put_Priority(&this, lPriority);

	public HRESULT get_Journal(int32* plJournal) mut => VT.[Friend]get_Journal(&this, plJournal);

	public HRESULT put_Journal(int32 lJournal) mut => VT.[Friend]put_Journal(&this, lJournal);

	public HRESULT get_ResponseQueueInfo_v1(IMSMQQueueInfo** ppqinfoResponse) mut => VT.[Friend]get_ResponseQueueInfo_v1(&this, ppqinfoResponse);

	public HRESULT putref_ResponseQueueInfo_v1(IMSMQQueueInfo* pqinfoResponse) mut => VT.[Friend]putref_ResponseQueueInfo_v1(&this, pqinfoResponse);

	public HRESULT get_AppSpecific(int32* plAppSpecific) mut => VT.[Friend]get_AppSpecific(&this, plAppSpecific);

	public HRESULT put_AppSpecific(int32 lAppSpecific) mut => VT.[Friend]put_AppSpecific(&this, lAppSpecific);

	public HRESULT get_SourceMachineGuid(BSTR* pbstrGuidSrcMachine) mut => VT.[Friend]get_SourceMachineGuid(&this, pbstrGuidSrcMachine);

	public HRESULT get_BodyLength(int32* pcbBody) mut => VT.[Friend]get_BodyLength(&this, pcbBody);

	public HRESULT get_Body(VARIANT* pvarBody) mut => VT.[Friend]get_Body(&this, pvarBody);

	public HRESULT put_Body(VARIANT varBody) mut => VT.[Friend]put_Body(&this, varBody);

	public HRESULT get_AdminQueueInfo_v1(IMSMQQueueInfo** ppqinfoAdmin) mut => VT.[Friend]get_AdminQueueInfo_v1(&this, ppqinfoAdmin);

	public HRESULT putref_AdminQueueInfo_v1(IMSMQQueueInfo* pqinfoAdmin) mut => VT.[Friend]putref_AdminQueueInfo_v1(&this, pqinfoAdmin);

	public HRESULT get_Id(VARIANT* pvarMsgId) mut => VT.[Friend]get_Id(&this, pvarMsgId);

	public HRESULT get_CorrelationId(VARIANT* pvarMsgId) mut => VT.[Friend]get_CorrelationId(&this, pvarMsgId);

	public HRESULT put_CorrelationId(VARIANT varMsgId) mut => VT.[Friend]put_CorrelationId(&this, varMsgId);

	public HRESULT get_Ack(int32* plAck) mut => VT.[Friend]get_Ack(&this, plAck);

	public HRESULT put_Ack(int32 lAck) mut => VT.[Friend]put_Ack(&this, lAck);

	public HRESULT get_Label(BSTR* pbstrLabel) mut => VT.[Friend]get_Label(&this, pbstrLabel);

	public HRESULT put_Label(BSTR bstrLabel) mut => VT.[Friend]put_Label(&this, bstrLabel);

	public HRESULT get_MaxTimeToReachQueue(int32* plMaxTimeToReachQueue) mut => VT.[Friend]get_MaxTimeToReachQueue(&this, plMaxTimeToReachQueue);

	public HRESULT put_MaxTimeToReachQueue(int32 lMaxTimeToReachQueue) mut => VT.[Friend]put_MaxTimeToReachQueue(&this, lMaxTimeToReachQueue);

	public HRESULT get_MaxTimeToReceive(int32* plMaxTimeToReceive) mut => VT.[Friend]get_MaxTimeToReceive(&this, plMaxTimeToReceive);

	public HRESULT put_MaxTimeToReceive(int32 lMaxTimeToReceive) mut => VT.[Friend]put_MaxTimeToReceive(&this, lMaxTimeToReceive);

	public HRESULT get_HashAlgorithm(int32* plHashAlg) mut => VT.[Friend]get_HashAlgorithm(&this, plHashAlg);

	public HRESULT put_HashAlgorithm(int32 lHashAlg) mut => VT.[Friend]put_HashAlgorithm(&this, lHashAlg);

	public HRESULT get_EncryptAlgorithm(int32* plEncryptAlg) mut => VT.[Friend]get_EncryptAlgorithm(&this, plEncryptAlg);

	public HRESULT put_EncryptAlgorithm(int32 lEncryptAlg) mut => VT.[Friend]put_EncryptAlgorithm(&this, lEncryptAlg);

	public HRESULT get_SentTime(VARIANT* pvarSentTime) mut => VT.[Friend]get_SentTime(&this, pvarSentTime);

	public HRESULT get_ArrivedTime(VARIANT* plArrivedTime) mut => VT.[Friend]get_ArrivedTime(&this, plArrivedTime);

	public HRESULT get_DestinationQueueInfo(IMSMQQueueInfo3** ppqinfoDest) mut => VT.[Friend]get_DestinationQueueInfo(&this, ppqinfoDest);

	public HRESULT get_SenderCertificate(VARIANT* pvarSenderCert) mut => VT.[Friend]get_SenderCertificate(&this, pvarSenderCert);

	public HRESULT put_SenderCertificate(VARIANT varSenderCert) mut => VT.[Friend]put_SenderCertificate(&this, varSenderCert);

	public HRESULT get_SenderId(VARIANT* pvarSenderId) mut => VT.[Friend]get_SenderId(&this, pvarSenderId);

	public HRESULT get_SenderIdType(int32* plSenderIdType) mut => VT.[Friend]get_SenderIdType(&this, plSenderIdType);

	public HRESULT put_SenderIdType(int32 lSenderIdType) mut => VT.[Friend]put_SenderIdType(&this, lSenderIdType);

	public HRESULT Send(IDispatch* DestinationQueue, VARIANT* Transaction) mut => VT.[Friend]Send(&this, DestinationQueue, Transaction);

	public HRESULT AttachCurrentSecurityContext() mut => VT.[Friend]AttachCurrentSecurityContext(&this);

	public HRESULT get_SenderVersion(int32* plSenderVersion) mut => VT.[Friend]get_SenderVersion(&this, plSenderVersion);

	public HRESULT get_Extension(VARIANT* pvarExtension) mut => VT.[Friend]get_Extension(&this, pvarExtension);

	public HRESULT put_Extension(VARIANT varExtension) mut => VT.[Friend]put_Extension(&this, varExtension);

	public HRESULT get_ConnectorTypeGuid(BSTR* pbstrGuidConnectorType) mut => VT.[Friend]get_ConnectorTypeGuid(&this, pbstrGuidConnectorType);

	public HRESULT put_ConnectorTypeGuid(BSTR bstrGuidConnectorType) mut => VT.[Friend]put_ConnectorTypeGuid(&this, bstrGuidConnectorType);

	public HRESULT get_TransactionStatusQueueInfo(IMSMQQueueInfo3** ppqinfoXactStatus) mut => VT.[Friend]get_TransactionStatusQueueInfo(&this, ppqinfoXactStatus);

	public HRESULT get_DestinationSymmetricKey(VARIANT* pvarDestSymmKey) mut => VT.[Friend]get_DestinationSymmetricKey(&this, pvarDestSymmKey);

	public HRESULT put_DestinationSymmetricKey(VARIANT varDestSymmKey) mut => VT.[Friend]put_DestinationSymmetricKey(&this, varDestSymmKey);

	public HRESULT get_Signature(VARIANT* pvarSignature) mut => VT.[Friend]get_Signature(&this, pvarSignature);

	public HRESULT put_Signature(VARIANT varSignature) mut => VT.[Friend]put_Signature(&this, varSignature);

	public HRESULT get_AuthenticationProviderType(int32* plAuthProvType) mut => VT.[Friend]get_AuthenticationProviderType(&this, plAuthProvType);

	public HRESULT put_AuthenticationProviderType(int32 lAuthProvType) mut => VT.[Friend]put_AuthenticationProviderType(&this, lAuthProvType);

	public HRESULT get_AuthenticationProviderName(BSTR* pbstrAuthProvName) mut => VT.[Friend]get_AuthenticationProviderName(&this, pbstrAuthProvName);

	public HRESULT put_AuthenticationProviderName(BSTR bstrAuthProvName) mut => VT.[Friend]put_AuthenticationProviderName(&this, bstrAuthProvName);

	public HRESULT put_SenderId(VARIANT varSenderId) mut => VT.[Friend]put_SenderId(&this, varSenderId);

	public HRESULT get_MsgClass(int32* plMsgClass) mut => VT.[Friend]get_MsgClass(&this, plMsgClass);

	public HRESULT put_MsgClass(int32 lMsgClass) mut => VT.[Friend]put_MsgClass(&this, lMsgClass);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);

	public HRESULT get_TransactionId(VARIANT* pvarXactId) mut => VT.[Friend]get_TransactionId(&this, pvarXactId);

	public HRESULT get_IsFirstInTransaction(int16* pisFirstInXact) mut => VT.[Friend]get_IsFirstInTransaction(&this, pisFirstInXact);

	public HRESULT get_IsLastInTransaction(int16* pisLastInXact) mut => VT.[Friend]get_IsLastInTransaction(&this, pisLastInXact);

	public HRESULT get_ResponseQueueInfo_v2(IMSMQQueueInfo2** ppqinfoResponse) mut => VT.[Friend]get_ResponseQueueInfo_v2(&this, ppqinfoResponse);

	public HRESULT putref_ResponseQueueInfo_v2(IMSMQQueueInfo2* pqinfoResponse) mut => VT.[Friend]putref_ResponseQueueInfo_v2(&this, pqinfoResponse);

	public HRESULT get_AdminQueueInfo_v2(IMSMQQueueInfo2** ppqinfoAdmin) mut => VT.[Friend]get_AdminQueueInfo_v2(&this, ppqinfoAdmin);

	public HRESULT putref_AdminQueueInfo_v2(IMSMQQueueInfo2* pqinfoAdmin) mut => VT.[Friend]putref_AdminQueueInfo_v2(&this, pqinfoAdmin);

	public HRESULT get_ReceivedAuthenticationLevel(int16* psReceivedAuthenticationLevel) mut => VT.[Friend]get_ReceivedAuthenticationLevel(&this, psReceivedAuthenticationLevel);

	public HRESULT get_ResponseQueueInfo(IMSMQQueueInfo3** ppqinfoResponse) mut => VT.[Friend]get_ResponseQueueInfo(&this, ppqinfoResponse);

	public HRESULT putref_ResponseQueueInfo(IMSMQQueueInfo3* pqinfoResponse) mut => VT.[Friend]putref_ResponseQueueInfo(&this, pqinfoResponse);

	public HRESULT get_AdminQueueInfo(IMSMQQueueInfo3** ppqinfoAdmin) mut => VT.[Friend]get_AdminQueueInfo(&this, ppqinfoAdmin);

	public HRESULT putref_AdminQueueInfo(IMSMQQueueInfo3* pqinfoAdmin) mut => VT.[Friend]putref_AdminQueueInfo(&this, pqinfoAdmin);

	public HRESULT get_ResponseDestination(IDispatch** ppdestResponse) mut => VT.[Friend]get_ResponseDestination(&this, ppdestResponse);

	public HRESULT putref_ResponseDestination(IDispatch* pdestResponse) mut => VT.[Friend]putref_ResponseDestination(&this, pdestResponse);

	public HRESULT get_Destination(IDispatch** ppdestDestination) mut => VT.[Friend]get_Destination(&this, ppdestDestination);

	public HRESULT get_LookupId(VARIANT* pvarLookupId) mut => VT.[Friend]get_LookupId(&this, pvarLookupId);

	public HRESULT get_IsAuthenticated2(int16* pisAuthenticated) mut => VT.[Friend]get_IsAuthenticated2(&this, pisAuthenticated);

	public HRESULT get_IsFirstInTransaction2(int16* pisFirstInXact) mut => VT.[Friend]get_IsFirstInTransaction2(&this, pisFirstInXact);

	public HRESULT get_IsLastInTransaction2(int16* pisLastInXact) mut => VT.[Friend]get_IsLastInTransaction2(&this, pisLastInXact);

	public HRESULT AttachCurrentSecurityContext2() mut => VT.[Friend]AttachCurrentSecurityContext2(&this);

	public HRESULT get_SoapEnvelope(BSTR* pbstrSoapEnvelope) mut => VT.[Friend]get_SoapEnvelope(&this, pbstrSoapEnvelope);

	public HRESULT get_CompoundMessage(VARIANT* pvarCompoundMessage) mut => VT.[Friend]get_CompoundMessage(&this, pvarCompoundMessage);

	public HRESULT put_SoapHeader(BSTR bstrSoapHeader) mut => VT.[Friend]put_SoapHeader(&this, bstrSoapHeader);

	public HRESULT put_SoapBody(BSTR bstrSoapBody) mut => VT.[Friend]put_SoapBody(&this, bstrSoapBody);
}

[CRepr]struct IMSMQMessage4 : IDispatch
{
	public new const Guid IID = .(0xeba96b23, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plClass) get_Class;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPrivLevel) get_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPrivLevel) put_PrivLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthLevel) get_AuthLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthLevel) put_AuthLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisAuthenticated) get_IsAuthenticated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDelivery) get_Delivery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDelivery) put_Delivery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plTrace) get_Trace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lTrace) put_Trace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPriority) get_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPriority) put_Priority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournal) get_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lJournal) put_Journal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfoResponse) get_ResponseQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo* pqinfoResponse) putref_ResponseQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAppSpecific) get_AppSpecific;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAppSpecific) put_AppSpecific;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidSrcMachine) get_SourceMachineGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcbBody) get_BodyLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarBody) get_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varBody) put_Body;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo** ppqinfoAdmin) get_AdminQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo* pqinfoAdmin) putref_AdminQueueInfo_v1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarMsgId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarMsgId) get_CorrelationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varMsgId) put_CorrelationId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAck) get_Ack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAck) put_Ack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLabel) get_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLabel) put_Label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaxTimeToReachQueue) get_MaxTimeToReachQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMaxTimeToReachQueue) put_MaxTimeToReachQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaxTimeToReceive) get_MaxTimeToReceive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMaxTimeToReceive) put_MaxTimeToReceive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plHashAlg) get_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lHashAlg) put_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plEncryptAlg) get_EncryptAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lEncryptAlg) put_EncryptAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSentTime) get_SentTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* plArrivedTime) get_ArrivedTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo4** ppqinfoDest) get_DestinationQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSenderCert) get_SenderCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSenderCert) put_SenderCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSenderId) get_SenderId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSenderIdType) get_SenderIdType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSenderIdType) put_SenderIdType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* DestinationQueue, VARIANT* Transaction) Send;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AttachCurrentSecurityContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSenderVersion) get_SenderVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarExtension) get_Extension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varExtension) put_Extension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGuidConnectorType) get_ConnectorTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGuidConnectorType) put_ConnectorTypeGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo4** ppqinfoXactStatus) get_TransactionStatusQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarDestSymmKey) get_DestinationSymmetricKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varDestSymmKey) put_DestinationSymmetricKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSignature) get_Signature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSignature) put_Signature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plAuthProvType) get_AuthenticationProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAuthProvType) put_AuthenticationProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrAuthProvName) get_AuthenticationProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAuthProvName) put_AuthenticationProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varSenderId) put_SenderId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMsgClass) get_MsgClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMsgClass) put_MsgClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarXactId) get_TransactionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisFirstInXact) get_IsFirstInTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisLastInXact) get_IsLastInTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2** ppqinfoResponse) get_ResponseQueueInfo_v2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2* pqinfoResponse) putref_ResponseQueueInfo_v2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2** ppqinfoAdmin) get_AdminQueueInfo_v2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo2* pqinfoAdmin) putref_AdminQueueInfo_v2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* psReceivedAuthenticationLevel) get_ReceivedAuthenticationLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo4** ppqinfoResponse) get_ResponseQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo4* pqinfoResponse) putref_ResponseQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo4** ppqinfoAdmin) get_AdminQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueueInfo4* pqinfoAdmin) putref_AdminQueueInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppdestResponse) get_ResponseDestination;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pdestResponse) putref_ResponseDestination;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppdestDestination) get_Destination;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarLookupId) get_LookupId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisAuthenticated) get_IsAuthenticated2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisFirstInXact) get_IsFirstInTransaction2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pisLastInXact) get_IsLastInTransaction2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AttachCurrentSecurityContext2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSoapEnvelope) get_SoapEnvelope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarCompoundMessage) get_CompoundMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSoapHeader) put_SoapHeader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSoapBody) put_SoapBody;
	}


	public HRESULT get_Class(int32* plClass) mut => VT.[Friend]get_Class(&this, plClass);

	public HRESULT get_PrivLevel(int32* plPrivLevel) mut => VT.[Friend]get_PrivLevel(&this, plPrivLevel);

	public HRESULT put_PrivLevel(int32 lPrivLevel) mut => VT.[Friend]put_PrivLevel(&this, lPrivLevel);

	public HRESULT get_AuthLevel(int32* plAuthLevel) mut => VT.[Friend]get_AuthLevel(&this, plAuthLevel);

	public HRESULT put_AuthLevel(int32 lAuthLevel) mut => VT.[Friend]put_AuthLevel(&this, lAuthLevel);

	public HRESULT get_IsAuthenticated(int16* pisAuthenticated) mut => VT.[Friend]get_IsAuthenticated(&this, pisAuthenticated);

	public HRESULT get_Delivery(int32* plDelivery) mut => VT.[Friend]get_Delivery(&this, plDelivery);

	public HRESULT put_Delivery(int32 lDelivery) mut => VT.[Friend]put_Delivery(&this, lDelivery);

	public HRESULT get_Trace(int32* plTrace) mut => VT.[Friend]get_Trace(&this, plTrace);

	public HRESULT put_Trace(int32 lTrace) mut => VT.[Friend]put_Trace(&this, lTrace);

	public HRESULT get_Priority(int32* plPriority) mut => VT.[Friend]get_Priority(&this, plPriority);

	public HRESULT put_Priority(int32 lPriority) mut => VT.[Friend]put_Priority(&this, lPriority);

	public HRESULT get_Journal(int32* plJournal) mut => VT.[Friend]get_Journal(&this, plJournal);

	public HRESULT put_Journal(int32 lJournal) mut => VT.[Friend]put_Journal(&this, lJournal);

	public HRESULT get_ResponseQueueInfo_v1(IMSMQQueueInfo** ppqinfoResponse) mut => VT.[Friend]get_ResponseQueueInfo_v1(&this, ppqinfoResponse);

	public HRESULT putref_ResponseQueueInfo_v1(IMSMQQueueInfo* pqinfoResponse) mut => VT.[Friend]putref_ResponseQueueInfo_v1(&this, pqinfoResponse);

	public HRESULT get_AppSpecific(int32* plAppSpecific) mut => VT.[Friend]get_AppSpecific(&this, plAppSpecific);

	public HRESULT put_AppSpecific(int32 lAppSpecific) mut => VT.[Friend]put_AppSpecific(&this, lAppSpecific);

	public HRESULT get_SourceMachineGuid(BSTR* pbstrGuidSrcMachine) mut => VT.[Friend]get_SourceMachineGuid(&this, pbstrGuidSrcMachine);

	public HRESULT get_BodyLength(int32* pcbBody) mut => VT.[Friend]get_BodyLength(&this, pcbBody);

	public HRESULT get_Body(VARIANT* pvarBody) mut => VT.[Friend]get_Body(&this, pvarBody);

	public HRESULT put_Body(VARIANT varBody) mut => VT.[Friend]put_Body(&this, varBody);

	public HRESULT get_AdminQueueInfo_v1(IMSMQQueueInfo** ppqinfoAdmin) mut => VT.[Friend]get_AdminQueueInfo_v1(&this, ppqinfoAdmin);

	public HRESULT putref_AdminQueueInfo_v1(IMSMQQueueInfo* pqinfoAdmin) mut => VT.[Friend]putref_AdminQueueInfo_v1(&this, pqinfoAdmin);

	public HRESULT get_Id(VARIANT* pvarMsgId) mut => VT.[Friend]get_Id(&this, pvarMsgId);

	public HRESULT get_CorrelationId(VARIANT* pvarMsgId) mut => VT.[Friend]get_CorrelationId(&this, pvarMsgId);

	public HRESULT put_CorrelationId(VARIANT varMsgId) mut => VT.[Friend]put_CorrelationId(&this, varMsgId);

	public HRESULT get_Ack(int32* plAck) mut => VT.[Friend]get_Ack(&this, plAck);

	public HRESULT put_Ack(int32 lAck) mut => VT.[Friend]put_Ack(&this, lAck);

	public HRESULT get_Label(BSTR* pbstrLabel) mut => VT.[Friend]get_Label(&this, pbstrLabel);

	public HRESULT put_Label(BSTR bstrLabel) mut => VT.[Friend]put_Label(&this, bstrLabel);

	public HRESULT get_MaxTimeToReachQueue(int32* plMaxTimeToReachQueue) mut => VT.[Friend]get_MaxTimeToReachQueue(&this, plMaxTimeToReachQueue);

	public HRESULT put_MaxTimeToReachQueue(int32 lMaxTimeToReachQueue) mut => VT.[Friend]put_MaxTimeToReachQueue(&this, lMaxTimeToReachQueue);

	public HRESULT get_MaxTimeToReceive(int32* plMaxTimeToReceive) mut => VT.[Friend]get_MaxTimeToReceive(&this, plMaxTimeToReceive);

	public HRESULT put_MaxTimeToReceive(int32 lMaxTimeToReceive) mut => VT.[Friend]put_MaxTimeToReceive(&this, lMaxTimeToReceive);

	public HRESULT get_HashAlgorithm(int32* plHashAlg) mut => VT.[Friend]get_HashAlgorithm(&this, plHashAlg);

	public HRESULT put_HashAlgorithm(int32 lHashAlg) mut => VT.[Friend]put_HashAlgorithm(&this, lHashAlg);

	public HRESULT get_EncryptAlgorithm(int32* plEncryptAlg) mut => VT.[Friend]get_EncryptAlgorithm(&this, plEncryptAlg);

	public HRESULT put_EncryptAlgorithm(int32 lEncryptAlg) mut => VT.[Friend]put_EncryptAlgorithm(&this, lEncryptAlg);

	public HRESULT get_SentTime(VARIANT* pvarSentTime) mut => VT.[Friend]get_SentTime(&this, pvarSentTime);

	public HRESULT get_ArrivedTime(VARIANT* plArrivedTime) mut => VT.[Friend]get_ArrivedTime(&this, plArrivedTime);

	public HRESULT get_DestinationQueueInfo(IMSMQQueueInfo4** ppqinfoDest) mut => VT.[Friend]get_DestinationQueueInfo(&this, ppqinfoDest);

	public HRESULT get_SenderCertificate(VARIANT* pvarSenderCert) mut => VT.[Friend]get_SenderCertificate(&this, pvarSenderCert);

	public HRESULT put_SenderCertificate(VARIANT varSenderCert) mut => VT.[Friend]put_SenderCertificate(&this, varSenderCert);

	public HRESULT get_SenderId(VARIANT* pvarSenderId) mut => VT.[Friend]get_SenderId(&this, pvarSenderId);

	public HRESULT get_SenderIdType(int32* plSenderIdType) mut => VT.[Friend]get_SenderIdType(&this, plSenderIdType);

	public HRESULT put_SenderIdType(int32 lSenderIdType) mut => VT.[Friend]put_SenderIdType(&this, lSenderIdType);

	public HRESULT Send(IDispatch* DestinationQueue, VARIANT* Transaction) mut => VT.[Friend]Send(&this, DestinationQueue, Transaction);

	public HRESULT AttachCurrentSecurityContext() mut => VT.[Friend]AttachCurrentSecurityContext(&this);

	public HRESULT get_SenderVersion(int32* plSenderVersion) mut => VT.[Friend]get_SenderVersion(&this, plSenderVersion);

	public HRESULT get_Extension(VARIANT* pvarExtension) mut => VT.[Friend]get_Extension(&this, pvarExtension);

	public HRESULT put_Extension(VARIANT varExtension) mut => VT.[Friend]put_Extension(&this, varExtension);

	public HRESULT get_ConnectorTypeGuid(BSTR* pbstrGuidConnectorType) mut => VT.[Friend]get_ConnectorTypeGuid(&this, pbstrGuidConnectorType);

	public HRESULT put_ConnectorTypeGuid(BSTR bstrGuidConnectorType) mut => VT.[Friend]put_ConnectorTypeGuid(&this, bstrGuidConnectorType);

	public HRESULT get_TransactionStatusQueueInfo(IMSMQQueueInfo4** ppqinfoXactStatus) mut => VT.[Friend]get_TransactionStatusQueueInfo(&this, ppqinfoXactStatus);

	public HRESULT get_DestinationSymmetricKey(VARIANT* pvarDestSymmKey) mut => VT.[Friend]get_DestinationSymmetricKey(&this, pvarDestSymmKey);

	public HRESULT put_DestinationSymmetricKey(VARIANT varDestSymmKey) mut => VT.[Friend]put_DestinationSymmetricKey(&this, varDestSymmKey);

	public HRESULT get_Signature(VARIANT* pvarSignature) mut => VT.[Friend]get_Signature(&this, pvarSignature);

	public HRESULT put_Signature(VARIANT varSignature) mut => VT.[Friend]put_Signature(&this, varSignature);

	public HRESULT get_AuthenticationProviderType(int32* plAuthProvType) mut => VT.[Friend]get_AuthenticationProviderType(&this, plAuthProvType);

	public HRESULT put_AuthenticationProviderType(int32 lAuthProvType) mut => VT.[Friend]put_AuthenticationProviderType(&this, lAuthProvType);

	public HRESULT get_AuthenticationProviderName(BSTR* pbstrAuthProvName) mut => VT.[Friend]get_AuthenticationProviderName(&this, pbstrAuthProvName);

	public HRESULT put_AuthenticationProviderName(BSTR bstrAuthProvName) mut => VT.[Friend]put_AuthenticationProviderName(&this, bstrAuthProvName);

	public HRESULT put_SenderId(VARIANT varSenderId) mut => VT.[Friend]put_SenderId(&this, varSenderId);

	public HRESULT get_MsgClass(int32* plMsgClass) mut => VT.[Friend]get_MsgClass(&this, plMsgClass);

	public HRESULT put_MsgClass(int32 lMsgClass) mut => VT.[Friend]put_MsgClass(&this, lMsgClass);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);

	public HRESULT get_TransactionId(VARIANT* pvarXactId) mut => VT.[Friend]get_TransactionId(&this, pvarXactId);

	public HRESULT get_IsFirstInTransaction(int16* pisFirstInXact) mut => VT.[Friend]get_IsFirstInTransaction(&this, pisFirstInXact);

	public HRESULT get_IsLastInTransaction(int16* pisLastInXact) mut => VT.[Friend]get_IsLastInTransaction(&this, pisLastInXact);

	public HRESULT get_ResponseQueueInfo_v2(IMSMQQueueInfo2** ppqinfoResponse) mut => VT.[Friend]get_ResponseQueueInfo_v2(&this, ppqinfoResponse);

	public HRESULT putref_ResponseQueueInfo_v2(IMSMQQueueInfo2* pqinfoResponse) mut => VT.[Friend]putref_ResponseQueueInfo_v2(&this, pqinfoResponse);

	public HRESULT get_AdminQueueInfo_v2(IMSMQQueueInfo2** ppqinfoAdmin) mut => VT.[Friend]get_AdminQueueInfo_v2(&this, ppqinfoAdmin);

	public HRESULT putref_AdminQueueInfo_v2(IMSMQQueueInfo2* pqinfoAdmin) mut => VT.[Friend]putref_AdminQueueInfo_v2(&this, pqinfoAdmin);

	public HRESULT get_ReceivedAuthenticationLevel(int16* psReceivedAuthenticationLevel) mut => VT.[Friend]get_ReceivedAuthenticationLevel(&this, psReceivedAuthenticationLevel);

	public HRESULT get_ResponseQueueInfo(IMSMQQueueInfo4** ppqinfoResponse) mut => VT.[Friend]get_ResponseQueueInfo(&this, ppqinfoResponse);

	public HRESULT putref_ResponseQueueInfo(IMSMQQueueInfo4* pqinfoResponse) mut => VT.[Friend]putref_ResponseQueueInfo(&this, pqinfoResponse);

	public HRESULT get_AdminQueueInfo(IMSMQQueueInfo4** ppqinfoAdmin) mut => VT.[Friend]get_AdminQueueInfo(&this, ppqinfoAdmin);

	public HRESULT putref_AdminQueueInfo(IMSMQQueueInfo4* pqinfoAdmin) mut => VT.[Friend]putref_AdminQueueInfo(&this, pqinfoAdmin);

	public HRESULT get_ResponseDestination(IDispatch** ppdestResponse) mut => VT.[Friend]get_ResponseDestination(&this, ppdestResponse);

	public HRESULT putref_ResponseDestination(IDispatch* pdestResponse) mut => VT.[Friend]putref_ResponseDestination(&this, pdestResponse);

	public HRESULT get_Destination(IDispatch** ppdestDestination) mut => VT.[Friend]get_Destination(&this, ppdestDestination);

	public HRESULT get_LookupId(VARIANT* pvarLookupId) mut => VT.[Friend]get_LookupId(&this, pvarLookupId);

	public HRESULT get_IsAuthenticated2(int16* pisAuthenticated) mut => VT.[Friend]get_IsAuthenticated2(&this, pisAuthenticated);

	public HRESULT get_IsFirstInTransaction2(int16* pisFirstInXact) mut => VT.[Friend]get_IsFirstInTransaction2(&this, pisFirstInXact);

	public HRESULT get_IsLastInTransaction2(int16* pisLastInXact) mut => VT.[Friend]get_IsLastInTransaction2(&this, pisLastInXact);

	public HRESULT AttachCurrentSecurityContext2() mut => VT.[Friend]AttachCurrentSecurityContext2(&this);

	public HRESULT get_SoapEnvelope(BSTR* pbstrSoapEnvelope) mut => VT.[Friend]get_SoapEnvelope(&this, pbstrSoapEnvelope);

	public HRESULT get_CompoundMessage(VARIANT* pvarCompoundMessage) mut => VT.[Friend]get_CompoundMessage(&this, pvarCompoundMessage);

	public HRESULT put_SoapHeader(BSTR bstrSoapHeader) mut => VT.[Friend]put_SoapHeader(&this, bstrSoapHeader);

	public HRESULT put_SoapBody(BSTR bstrSoapBody) mut => VT.[Friend]put_SoapBody(&this, bstrSoapBody);
}

[CRepr]struct IMSMQPrivateEvent : IDispatch
{
	public new const Guid IID = .(0xd7ab3341, 0xc9d3, 0x11d1, 0xbb, 0x47, 0x00, 0x80, 0xc7, 0xc5, 0xa2, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* phwnd) get_Hwnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueue* pq, int32 msgcursor) FireArrivedEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQQueue* pq, HRESULT hrStatus, int32 msgcursor) FireArrivedErrorEvent;
	}


	public HRESULT get_Hwnd(int32* phwnd) mut => VT.[Friend]get_Hwnd(&this, phwnd);

	public HRESULT FireArrivedEvent(IMSMQQueue* pq, int32 msgcursor) mut => VT.[Friend]FireArrivedEvent(&this, pq, msgcursor);

	public HRESULT FireArrivedErrorEvent(IMSMQQueue* pq, HRESULT hrStatus, int32 msgcursor) mut => VT.[Friend]FireArrivedErrorEvent(&this, pq, hrStatus, msgcursor);
}

[CRepr]struct _DMSMQEventEvents : IDispatch
{
	public new const Guid IID = .(0xd7d6e078, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IMSMQTransaction2 : IMSMQTransaction
{
	public new const Guid IID = .(0x2ce0c5b0, 0x6e67, 0x11d2, 0xb0, 0xe6, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMSMQTransaction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varTransaction) InitNew;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT InitNew(VARIANT varTransaction) mut => VT.[Friend]InitNew(&this, varTransaction);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQTransaction3 : IMSMQTransaction2
{
	public new const Guid IID = .(0xeba96b13, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMSMQTransaction2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarITransaction) get_ITransaction;
	}


	public HRESULT get_ITransaction(VARIANT* pvarITransaction) mut => VT.[Friend]get_ITransaction(&this, pvarITransaction);
}

[CRepr]struct IMSMQCoordinatedTransactionDispenser2 : IDispatch
{
	public new const Guid IID = .(0xeba96b10, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQTransaction2** ptransaction) BeginTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT BeginTransaction(IMSMQTransaction2** ptransaction) mut => VT.[Friend]BeginTransaction(&this, ptransaction);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQCoordinatedTransactionDispenser3 : IDispatch
{
	public new const Guid IID = .(0xeba96b14, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQTransaction3** ptransaction) BeginTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT BeginTransaction(IMSMQTransaction3** ptransaction) mut => VT.[Friend]BeginTransaction(&this, ptransaction);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQTransactionDispenser2 : IDispatch
{
	public new const Guid IID = .(0xeba96b11, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQTransaction2** ptransaction) BeginTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT BeginTransaction(IMSMQTransaction2** ptransaction) mut => VT.[Friend]BeginTransaction(&this, ptransaction);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQTransactionDispenser3 : IDispatch
{
	public new const Guid IID = .(0xeba96b15, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQTransaction3** ptransaction) BeginTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT BeginTransaction(IMSMQTransaction3** ptransaction) mut => VT.[Friend]BeginTransaction(&this, ptransaction);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQApplication : IDispatch
{
	public new const Guid IID = .(0xd7d6e085, 0xdccd, 0x11d0, 0xaa, 0x4b, 0x00, 0x60, 0x97, 0x0d, 0xeb, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR MachineName, BSTR* pbstrGuid) MachineIdOfMachineName;
	}


	public HRESULT MachineIdOfMachineName(BSTR MachineName, BSTR* pbstrGuid) mut => VT.[Friend]MachineIdOfMachineName(&this, MachineName, pbstrGuid);
}

[CRepr]struct IMSMQApplication2 : IMSMQApplication
{
	public new const Guid IID = .(0x12a30900, 0x7300, 0x11d2, 0xb0, 0xe6, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMSMQApplication.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Flags, VARIANT* ExternalCertificate) RegisterCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGuid, BSTR* pbstrMachineName) MachineNameOfMachineId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* psMSMQVersionMajor) get_MSMQVersionMajor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* psMSMQVersionMinor) get_MSMQVersionMinor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* psMSMQVersionBuild) get_MSMQVersionBuild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfIsDsEnabled) get_IsDsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT RegisterCertificate(VARIANT* Flags, VARIANT* ExternalCertificate) mut => VT.[Friend]RegisterCertificate(&this, Flags, ExternalCertificate);

	public HRESULT MachineNameOfMachineId(BSTR bstrGuid, BSTR* pbstrMachineName) mut => VT.[Friend]MachineNameOfMachineId(&this, bstrGuid, pbstrMachineName);

	public HRESULT get_MSMQVersionMajor(int16* psMSMQVersionMajor) mut => VT.[Friend]get_MSMQVersionMajor(&this, psMSMQVersionMajor);

	public HRESULT get_MSMQVersionMinor(int16* psMSMQVersionMinor) mut => VT.[Friend]get_MSMQVersionMinor(&this, psMSMQVersionMinor);

	public HRESULT get_MSMQVersionBuild(int16* psMSMQVersionBuild) mut => VT.[Friend]get_MSMQVersionBuild(&this, psMSMQVersionBuild);

	public HRESULT get_IsDsEnabled(int16* pfIsDsEnabled) mut => VT.[Friend]get_IsDsEnabled(&this, pfIsDsEnabled);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQApplication3 : IMSMQApplication2
{
	public new const Guid IID = .(0xeba96b1f, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMSMQApplication2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvActiveQueues) get_ActiveQueues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvPrivateQueues) get_PrivateQueues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDirectoryServiceServer) get_DirectoryServiceServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfIsConnected) get_IsConnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvBytesInAllQueues) get_BytesInAllQueues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMachine) put_Machine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMachine) get_Machine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Tidy;
	}


	public HRESULT get_ActiveQueues(VARIANT* pvActiveQueues) mut => VT.[Friend]get_ActiveQueues(&this, pvActiveQueues);

	public HRESULT get_PrivateQueues(VARIANT* pvPrivateQueues) mut => VT.[Friend]get_PrivateQueues(&this, pvPrivateQueues);

	public HRESULT get_DirectoryServiceServer(BSTR* pbstrDirectoryServiceServer) mut => VT.[Friend]get_DirectoryServiceServer(&this, pbstrDirectoryServiceServer);

	public HRESULT get_IsConnected(int16* pfIsConnected) mut => VT.[Friend]get_IsConnected(&this, pfIsConnected);

	public HRESULT get_BytesInAllQueues(VARIANT* pvBytesInAllQueues) mut => VT.[Friend]get_BytesInAllQueues(&this, pvBytesInAllQueues);

	public HRESULT put_Machine(BSTR bstrMachine) mut => VT.[Friend]put_Machine(&this, bstrMachine);

	public HRESULT get_Machine(BSTR* pbstrMachine) mut => VT.[Friend]get_Machine(&this, pbstrMachine);

	public HRESULT Connect() mut => VT.[Friend]Connect(&this);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);

	public HRESULT Tidy() mut => VT.[Friend]Tidy(&this);
}

[CRepr]struct IMSMQDestination : IDispatch
{
	public new const Guid IID = .(0xeba96b16, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfIsOpen) get_IsOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppIADs) get_IADs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pIADs) putref_IADs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrADsPath) get_ADsPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrADsPath) put_ADsPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPathName) get_PathName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPathName) put_PathName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFormatName) get_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFormatName) put_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppDestinations) get_Destinations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pDestinations) putref_Destinations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppcolProperties) get_Properties;
	}


	public HRESULT Open() mut => VT.[Friend]Open(&this);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT get_IsOpen(int16* pfIsOpen) mut => VT.[Friend]get_IsOpen(&this, pfIsOpen);

	public HRESULT get_IADs(IDispatch** ppIADs) mut => VT.[Friend]get_IADs(&this, ppIADs);

	public HRESULT putref_IADs(IDispatch* pIADs) mut => VT.[Friend]putref_IADs(&this, pIADs);

	public HRESULT get_ADsPath(BSTR* pbstrADsPath) mut => VT.[Friend]get_ADsPath(&this, pbstrADsPath);

	public HRESULT put_ADsPath(BSTR bstrADsPath) mut => VT.[Friend]put_ADsPath(&this, bstrADsPath);

	public HRESULT get_PathName(BSTR* pbstrPathName) mut => VT.[Friend]get_PathName(&this, pbstrPathName);

	public HRESULT put_PathName(BSTR bstrPathName) mut => VT.[Friend]put_PathName(&this, bstrPathName);

	public HRESULT get_FormatName(BSTR* pbstrFormatName) mut => VT.[Friend]get_FormatName(&this, pbstrFormatName);

	public HRESULT put_FormatName(BSTR bstrFormatName) mut => VT.[Friend]put_FormatName(&this, bstrFormatName);

	public HRESULT get_Destinations(IDispatch** ppDestinations) mut => VT.[Friend]get_Destinations(&this, ppDestinations);

	public HRESULT putref_Destinations(IDispatch* pDestinations) mut => VT.[Friend]putref_Destinations(&this, pDestinations);

	public HRESULT get_Properties(IDispatch** ppcolProperties) mut => VT.[Friend]get_Properties(&this, ppcolProperties);
}

[CRepr]struct IMSMQPrivateDestination : IDispatch
{
	public new const Guid IID = .(0xeba96b17, 0x2168, 0x11d3, 0x89, 0x8c, 0x00, 0xe0, 0x2c, 0x07, 0x4f, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarHandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varHandle) put_Handle;
	}


	public HRESULT get_Handle(VARIANT* pvarHandle) mut => VT.[Friend]get_Handle(&this, pvarHandle);

	public HRESULT put_Handle(VARIANT varHandle) mut => VT.[Friend]put_Handle(&this, varHandle);
}

[CRepr]struct IMSMQCollection : IDispatch
{
	public new const Guid IID = .(0x0188ac2f, 0xecb3, 0x4173, 0x97, 0x79, 0x63, 0x5c, 0xa2, 0x03, 0x9c, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Index, VARIANT* pvarRet) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunk) _NewEnum;
	}


	public HRESULT Item(VARIANT* Index, VARIANT* pvarRet) mut => VT.[Friend]Item(&this, Index, pvarRet);

	public HRESULT get_Count(int32* pCount) mut => VT.[Friend]get_Count(&this, pCount);

	public HRESULT _NewEnum(IUnknown** ppunk) mut => VT.[Friend]_NewEnum(&this, ppunk);
}

[CRepr]struct IMSMQManagement : IDispatch
{
	public new const Guid IID = .(0xbe5f0241, 0xe489, 0x4957, 0x8c, 0xc4, 0xa4, 0x52, 0xfc, 0xf3, 0xe2, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Machine, VARIANT* Pathname, VARIANT* FormatName) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFormatName) get_FormatName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMachine) get_Machine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMessageCount) get_MessageCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plForeignStatus) get_ForeignStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plQueueType) get_QueueType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfIsLocal) get_IsLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plTransactionalStatus) get_TransactionalStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvBytesInQueue) get_BytesInQueue;
	}


	public HRESULT Init(VARIANT* Machine, VARIANT* Pathname, VARIANT* FormatName) mut => VT.[Friend]Init(&this, Machine, Pathname, FormatName);

	public HRESULT get_FormatName(BSTR* pbstrFormatName) mut => VT.[Friend]get_FormatName(&this, pbstrFormatName);

	public HRESULT get_Machine(BSTR* pbstrMachine) mut => VT.[Friend]get_Machine(&this, pbstrMachine);

	public HRESULT get_MessageCount(int32* plMessageCount) mut => VT.[Friend]get_MessageCount(&this, plMessageCount);

	public HRESULT get_ForeignStatus(int32* plForeignStatus) mut => VT.[Friend]get_ForeignStatus(&this, plForeignStatus);

	public HRESULT get_QueueType(int32* plQueueType) mut => VT.[Friend]get_QueueType(&this, plQueueType);

	public HRESULT get_IsLocal(int16* pfIsLocal) mut => VT.[Friend]get_IsLocal(&this, pfIsLocal);

	public HRESULT get_TransactionalStatus(int32* plTransactionalStatus) mut => VT.[Friend]get_TransactionalStatus(&this, plTransactionalStatus);

	public HRESULT get_BytesInQueue(VARIANT* pvBytesInQueue) mut => VT.[Friend]get_BytesInQueue(&this, pvBytesInQueue);
}

[CRepr]struct IMSMQOutgoingQueueManagement : IMSMQManagement
{
	public new const Guid IID = .(0x64c478fb, 0xf9b0, 0x4695, 0x8a, 0x7f, 0x43, 0x9a, 0xc9, 0x43, 0x26, 0xd3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMSMQManagement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvNextHops) get_NextHops;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMSMQCollection** ppCollection) EodGetSendInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EodResend;
	}


	public HRESULT get_State(int32* plState) mut => VT.[Friend]get_State(&this, plState);

	public HRESULT get_NextHops(VARIANT* pvNextHops) mut => VT.[Friend]get_NextHops(&this, pvNextHops);

	public HRESULT EodGetSendInfo(IMSMQCollection** ppCollection) mut => VT.[Friend]EodGetSendInfo(&this, ppCollection);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT EodResend() mut => VT.[Friend]EodResend(&this);
}

[CRepr]struct IMSMQQueueManagement : IMSMQManagement
{
	public new const Guid IID = .(0x7fbe7759, 0x5760, 0x444d, 0xb8, 0xa5, 0x5e, 0x7a, 0xb9, 0xa8, 0x4c, 0xce);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMSMQManagement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plJournalMessageCount) get_JournalMessageCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvBytesInJournal) get_BytesInJournal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvCollection) EodGetReceiveInfo;
	}


	public HRESULT get_JournalMessageCount(int32* plJournalMessageCount) mut => VT.[Friend]get_JournalMessageCount(&this, plJournalMessageCount);

	public HRESULT get_BytesInJournal(VARIANT* pvBytesInJournal) mut => VT.[Friend]get_BytesInJournal(&this, pvBytesInJournal);

	public HRESULT EodGetReceiveInfo(VARIANT* pvCollection) mut => VT.[Friend]EodGetReceiveInfo(&this, pvCollection);
}

#endregion
