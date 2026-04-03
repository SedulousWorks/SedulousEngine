using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.Networking.BackgroundIntelligentTransferService;

#region Constants
public static
{
	public const uint32 BG_NOTIFY_JOB_TRANSFERRED = 1;
	public const uint32 BG_NOTIFY_JOB_ERROR = 2;
	public const uint32 BG_NOTIFY_DISABLE = 4;
	public const uint32 BG_NOTIFY_JOB_MODIFICATION = 8;
	public const uint32 BG_NOTIFY_FILE_TRANSFERRED = 16;
	public const uint32 BG_NOTIFY_FILE_RANGES_TRANSFERRED = 32;
	public const uint32 BG_JOB_ENUM_ALL_USERS = 1;
	public const uint32 BG_COPY_FILE_OWNER = 1;
	public const uint32 BG_COPY_FILE_GROUP = 2;
	public const uint32 BG_COPY_FILE_DACL = 4;
	public const uint32 BG_COPY_FILE_SACL = 8;
	public const uint32 BG_COPY_FILE_ALL = 15;
	public const uint32 BG_SSL_ENABLE_CRL_CHECK = 1;
	public const uint32 BG_SSL_IGNORE_CERT_CN_INVALID = 2;
	public const uint32 BG_SSL_IGNORE_CERT_DATE_INVALID = 4;
	public const uint32 BG_SSL_IGNORE_UNKNOWN_CA = 8;
	public const uint32 BG_SSL_IGNORE_CERT_WRONG_USAGE = 16;
	public const uint32 BG_HTTP_REDIRECT_POLICY_MASK = 1792;
	public const uint32 BG_HTTP_REDIRECT_POLICY_ALLOW_SILENT = 0;
	public const uint32 BG_HTTP_REDIRECT_POLICY_ALLOW_REPORT = 256;
	public const uint32 BG_HTTP_REDIRECT_POLICY_DISALLOW = 512;
	public const uint32 BG_HTTP_REDIRECT_POLICY_ALLOW_HTTPS_TO_HTTP = 2048;
	public const uint32 BG_ENABLE_PEERCACHING_CLIENT = 1;
	public const uint32 BG_ENABLE_PEERCACHING_SERVER = 2;
	public const uint32 BG_DISABLE_BRANCH_CACHE = 4;
	public const uint32 BG_JOB_ENABLE_PEERCACHING_CLIENT = 1;
	public const uint32 BG_JOB_ENABLE_PEERCACHING_SERVER = 2;
	public const uint32 BG_JOB_DISABLE_BRANCH_CACHE = 4;
	public const uint32 BITS_COST_STATE_UNRESTRICTED = 1;
	public const uint32 BITS_COST_STATE_CAPPED_USAGE_UNKNOWN = 2;
	public const uint32 BITS_COST_STATE_BELOW_CAP = 4;
	public const uint32 BITS_COST_STATE_NEAR_CAP = 8;
	public const uint32 BITS_COST_STATE_OVERCAP_CHARGED = 16;
	public const uint32 BITS_COST_STATE_OVERCAP_THROTTLED = 32;
	public const uint32 BITS_COST_STATE_USAGE_BASED = 64;
	public const uint32 BITS_COST_STATE_ROAMING = 128;
	public const uint32 BITS_COST_OPTION_IGNORE_CONGESTION = 2147483648;
	public const uint32 BITS_COST_STATE_RESERVED = 1073741824;
	public const uint32 QM_NOTIFY_FILE_DONE = 1;
	public const uint32 QM_NOTIFY_JOB_DONE = 2;
	public const uint32 QM_NOTIFY_GROUP_DONE = 4;
	public const uint32 QM_NOTIFY_DISABLE_NOTIFY = 64;
	public const uint32 QM_NOTIFY_USE_PROGRESSEX = 128;
	public const uint32 QM_STATUS_FILE_COMPLETE = 1;
	public const uint32 QM_STATUS_FILE_INCOMPLETE = 2;
	public const uint32 QM_STATUS_JOB_COMPLETE = 4;
	public const uint32 QM_STATUS_JOB_INCOMPLETE = 8;
	public const uint32 QM_STATUS_JOB_ERROR = 16;
	public const uint32 QM_STATUS_JOB_FOREGROUND = 32;
	public const uint32 QM_STATUS_GROUP_COMPLETE = 64;
	public const uint32 QM_STATUS_GROUP_INCOMPLETE = 128;
	public const uint32 QM_STATUS_GROUP_SUSPENDED = 256;
	public const uint32 QM_STATUS_GROUP_ERROR = 512;
	public const uint32 QM_STATUS_GROUP_FOREGROUND = 1024;
	public const uint32 QM_PROTOCOL_HTTP = 1;
	public const uint32 QM_PROTOCOL_FTP = 2;
	public const uint32 QM_PROTOCOL_SMB = 3;
	public const uint32 QM_PROTOCOL_CUSTOM = 4;
	public const uint32 QM_PROGRESS_PERCENT_DONE = 1;
	public const uint32 QM_PROGRESS_TIME_DONE = 2;
	public const uint32 QM_PROGRESS_SIZE_DONE = 3;
	public const uint32 QM_E_INVALID_STATE = 2164264961;
	public const uint32 QM_E_SERVICE_UNAVAILABLE = 2164264962;
	public const uint32 QM_E_DOWNLOADER_UNAVAILABLE = 2164264963;
	public const uint32 QM_E_ITEM_NOT_FOUND = 2164264964;
	public const int32 BG_E_NOT_FOUND = -2145386495;
	public const int32 BG_E_INVALID_STATE = -2145386494;
	public const int32 BG_E_EMPTY = -2145386493;
	public const int32 BG_E_FILE_NOT_AVAILABLE = -2145386492;
	public const int32 BG_E_PROTOCOL_NOT_AVAILABLE = -2145386491;
	public const int32 BG_S_ERROR_CONTEXT_NONE = 2097158;
	public const int32 BG_E_ERROR_CONTEXT_UNKNOWN = -2145386489;
	public const int32 BG_E_ERROR_CONTEXT_GENERAL_QUEUE_MANAGER = -2145386488;
	public const int32 BG_E_ERROR_CONTEXT_LOCAL_FILE = -2145386487;
	public const int32 BG_E_ERROR_CONTEXT_REMOTE_FILE = -2145386486;
	public const int32 BG_E_ERROR_CONTEXT_GENERAL_TRANSPORT = -2145386485;
	public const int32 BG_E_ERROR_CONTEXT_QUEUE_MANAGER_NOTIFICATION = -2145386484;
	public const int32 BG_E_DESTINATION_LOCKED = -2145386483;
	public const int32 BG_E_VOLUME_CHANGED = -2145386482;
	public const int32 BG_E_ERROR_INFORMATION_UNAVAILABLE = -2145386481;
	public const int32 BG_E_NETWORK_DISCONNECTED = -2145386480;
	public const int32 BG_E_MISSING_FILE_SIZE = -2145386479;
	public const int32 BG_E_INSUFFICIENT_HTTP_SUPPORT = -2145386478;
	public const int32 BG_E_INSUFFICIENT_RANGE_SUPPORT = -2145386477;
	public const int32 BG_E_REMOTE_NOT_SUPPORTED = -2145386476;
	public const int32 BG_E_NEW_OWNER_DIFF_MAPPING = -2145386475;
	public const int32 BG_E_NEW_OWNER_NO_FILE_ACCESS = -2145386474;
	public const int32 BG_S_PARTIAL_COMPLETE = 2097175;
	public const int32 BG_E_PROXY_LIST_TOO_LARGE = -2145386472;
	public const int32 BG_E_PROXY_BYPASS_LIST_TOO_LARGE = -2145386471;
	public const int32 BG_S_UNABLE_TO_DELETE_FILES = 2097178;
	public const int32 BG_E_INVALID_SERVER_RESPONSE = -2145386469;
	public const int32 BG_E_TOO_MANY_FILES = -2145386468;
	public const int32 BG_E_LOCAL_FILE_CHANGED = -2145386467;
	public const int32 BG_E_ERROR_CONTEXT_REMOTE_APPLICATION = -2145386466;
	public const int32 BG_E_SESSION_NOT_FOUND = -2145386465;
	public const int32 BG_E_TOO_LARGE = -2145386464;
	public const int32 BG_E_STRING_TOO_LONG = -2145386463;
	public const int32 BG_E_CLIENT_SERVER_PROTOCOL_MISMATCH = -2145386462;
	public const int32 BG_E_SERVER_EXECUTE_ENABLE = -2145386461;
	public const int32 BG_E_NO_PROGRESS = -2145386460;
	public const int32 BG_E_USERNAME_TOO_LARGE = -2145386459;
	public const int32 BG_E_PASSWORD_TOO_LARGE = -2145386458;
	public const int32 BG_E_INVALID_AUTH_TARGET = -2145386457;
	public const int32 BG_E_INVALID_AUTH_SCHEME = -2145386456;
	public const int32 BG_E_FILE_NOT_FOUND = -2145386455;
	public const int32 BG_S_PROXY_CHANGED = 2097194;
	public const int32 BG_E_INVALID_RANGE = -2145386453;
	public const int32 BG_E_OVERLAPPING_RANGES = -2145386452;
	public const int32 BG_E_CONNECT_FAILURE = -2145386451;
	public const int32 BG_E_CONNECTION_CLOSED = -2145386450;
	public const int32 BG_E_BLOCKED_BY_POLICY = -2145386434;
	public const int32 BG_E_INVALID_PROXY_INFO = -2145386433;
	public const int32 BG_E_INVALID_CREDENTIALS = -2145386432;
	public const int32 BG_E_INVALID_HASH_ALGORITHM = -2145386431;
	public const int32 BG_E_RECORD_DELETED = -2145386430;
	public const int32 BG_E_COMMIT_IN_PROGRESS = -2145386429;
	public const int32 BG_E_DISCOVERY_IN_PROGRESS = -2145386428;
	public const int32 BG_E_UPNP_ERROR = -2145386427;
	public const int32 BG_E_TEST_OPTION_BLOCKED_DOWNLOAD = -2145386426;
	public const int32 BG_E_PEERCACHING_DISABLED = -2145386425;
	public const int32 BG_E_BUSYCACHERECORD = -2145386424;
	public const int32 BG_E_TOO_MANY_JOBS_PER_USER = -2145386423;
	public const int32 BG_E_TOO_MANY_JOBS_PER_MACHINE = -2145386416;
	public const int32 BG_E_TOO_MANY_FILES_IN_JOB = -2145386415;
	public const int32 BG_E_TOO_MANY_RANGES_IN_FILE = -2145386414;
	public const int32 BG_E_VALIDATION_FAILED = -2145386413;
	public const int32 BG_E_MAXDOWNLOAD_TIMEOUT = -2145386412;
	public const int32 BG_S_OVERRIDDEN_BY_POLICY = 2097237;
	public const int32 BG_E_TOKEN_REQUIRED = -2145386410;
	public const int32 BG_E_UNKNOWN_PROPERTY_ID = -2145386409;
	public const int32 BG_E_READ_ONLY_PROPERTY = -2145386408;
	public const int32 BG_E_BLOCKED_BY_COST_TRANSFER_POLICY = -2145386407;
	public const int32 BG_E_PROPERTY_SUPPORTED_FOR_DOWNLOAD_JOBS_ONLY = -2145386400;
	public const int32 BG_E_READ_ONLY_PROPERTY_AFTER_ADDFILE = -2145386399;
	public const int32 BG_E_READ_ONLY_PROPERTY_AFTER_RESUME = -2145386398;
	public const int32 BG_E_MAX_DOWNLOAD_SIZE_INVALID_VALUE = -2145386397;
	public const int32 BG_E_MAX_DOWNLOAD_SIZE_LIMIT_REACHED = -2145386396;
	public const int32 BG_E_STANDBY_MODE = -2145386395;
	public const int32 BG_E_USE_STORED_CREDENTIALS_NOT_SUPPORTED = -2145386394;
	public const int32 BG_E_BLOCKED_BY_BATTERY_POLICY = -2145386393;
	public const int32 BG_E_BLOCKED_BY_BATTERY_SAVER = -2145386392;
	public const int32 BG_E_WATCHDOG_TIMEOUT = -2145386391;
	public const int32 BG_E_APP_PACKAGE_NOT_FOUND = -2145386390;
	public const int32 BG_E_APP_PACKAGE_SCENARIO_NOT_SUPPORTED = -2145386389;
	public const int32 BG_E_DATABASE_CORRUPT = -2145386388;
	public const int32 BG_E_RANDOM_ACCESS_NOT_SUPPORTED = -2145386387;
	public const int32 BG_E_BLOCKED_BY_BACKGROUND_ACCESS_POLICY = -2145386386;
	public const int32 BG_E_BLOCKED_BY_GAME_MODE = -2145386385;
	public const int32 BG_E_BLOCKED_BY_SYSTEM_POLICY = -2145386384;
	public const int32 BG_E_NOT_SUPPORTED_WITH_CUSTOM_HTTP_METHOD = -2145386383;
	public const int32 BG_E_UNSUPPORTED_JOB_CONFIGURATION = -2145386382;
	public const int32 BG_E_REMOTE_FILE_CHANGED = -2145386381;
	public const int32 BG_E_SERVER_CERT_VALIDATION_INTERFACE_REQUIRED = -2145386380;
	public const int32 BG_E_READ_ONLY_WHEN_JOB_ACTIVE = -2145386379;
	public const int32 BG_E_ERROR_CONTEXT_SERVER_CERTIFICATE_CALLBACK = -2145386378;
	public const int32 BG_E_HTTP_ERROR_100 = -2145845148;
	public const int32 BG_E_HTTP_ERROR_101 = -2145845147;
	public const int32 BG_E_HTTP_ERROR_200 = -2145845048;
	public const int32 BG_E_HTTP_ERROR_201 = -2145845047;
	public const int32 BG_E_HTTP_ERROR_202 = -2145845046;
	public const int32 BG_E_HTTP_ERROR_203 = -2145845045;
	public const int32 BG_E_HTTP_ERROR_204 = -2145845044;
	public const int32 BG_E_HTTP_ERROR_205 = -2145845043;
	public const int32 BG_E_HTTP_ERROR_206 = -2145845042;
	public const int32 BG_E_HTTP_ERROR_300 = -2145844948;
	public const int32 BG_E_HTTP_ERROR_301 = -2145844947;
	public const int32 BG_E_HTTP_ERROR_302 = -2145844946;
	public const int32 BG_E_HTTP_ERROR_303 = -2145844945;
	public const int32 BG_E_HTTP_ERROR_304 = -2145844944;
	public const int32 BG_E_HTTP_ERROR_305 = -2145844943;
	public const int32 BG_E_HTTP_ERROR_307 = -2145844941;
	public const int32 BG_E_HTTP_ERROR_400 = -2145844848;
	public const int32 BG_E_HTTP_ERROR_401 = -2145844847;
	public const int32 BG_E_HTTP_ERROR_402 = -2145844846;
	public const int32 BG_E_HTTP_ERROR_403 = -2145844845;
	public const int32 BG_E_HTTP_ERROR_404 = -2145844844;
	public const int32 BG_E_HTTP_ERROR_405 = -2145844843;
	public const int32 BG_E_HTTP_ERROR_406 = -2145844842;
	public const int32 BG_E_HTTP_ERROR_407 = -2145844841;
	public const int32 BG_E_HTTP_ERROR_408 = -2145844840;
	public const int32 BG_E_HTTP_ERROR_409 = -2145844839;
	public const int32 BG_E_HTTP_ERROR_410 = -2145844838;
	public const int32 BG_E_HTTP_ERROR_411 = -2145844837;
	public const int32 BG_E_HTTP_ERROR_412 = -2145844836;
	public const int32 BG_E_HTTP_ERROR_413 = -2145844835;
	public const int32 BG_E_HTTP_ERROR_414 = -2145844834;
	public const int32 BG_E_HTTP_ERROR_415 = -2145844833;
	public const int32 BG_E_HTTP_ERROR_416 = -2145844832;
	public const int32 BG_E_HTTP_ERROR_417 = -2145844831;
	public const int32 BG_E_HTTP_ERROR_449 = -2145844799;
	public const int32 BG_E_HTTP_ERROR_500 = -2145844748;
	public const int32 BG_E_HTTP_ERROR_501 = -2145844747;
	public const int32 BG_E_HTTP_ERROR_502 = -2145844746;
	public const int32 BG_E_HTTP_ERROR_503 = -2145844745;
	public const int32 BG_E_HTTP_ERROR_504 = -2145844744;
	public const int32 BG_E_HTTP_ERROR_505 = -2145844743;
	public const int32 BITS_MC_JOB_CANCELLED = -2145828864;
	public const int32 BITS_MC_FILE_DELETION_FAILED = -2145828863;
	public const int32 BITS_MC_FILE_DELETION_FAILED_MORE = -2145828862;
	public const int32 BITS_MC_JOB_PROPERTY_CHANGE = -2145828861;
	public const int32 BITS_MC_JOB_TAKE_OWNERSHIP = -2145828860;
	public const int32 BITS_MC_JOB_SCAVENGED = -2145828859;
	public const int32 BITS_MC_JOB_NOTIFICATION_FAILURE = -2145828858;
	public const int32 BITS_MC_STATE_FILE_CORRUPT = -2145828857;
	public const int32 BITS_MC_FAILED_TO_START = -2145828856;
	public const int32 BITS_MC_FATAL_IGD_ERROR = -2145828855;
	public const int32 BITS_MC_PEERCACHING_PORT = -2145828854;
	public const int32 BITS_MC_WSD_PORT = -2145828853;
}
#endregion

#region Enums

[AllowDuplicates]
public enum BG_TOKEN : uint32
{
	BG_TOKEN_LOCAL_FILE = 1,
	BG_TOKEN_NETWORK = 2,
}


[AllowDuplicates]
public enum BG_ERROR_CONTEXT : int32
{
	BG_ERROR_CONTEXT_NONE = 0,
	BG_ERROR_CONTEXT_UNKNOWN = 1,
	BG_ERROR_CONTEXT_GENERAL_QUEUE_MANAGER = 2,
	BG_ERROR_CONTEXT_QUEUE_MANAGER_NOTIFICATION = 3,
	BG_ERROR_CONTEXT_LOCAL_FILE = 4,
	BG_ERROR_CONTEXT_REMOTE_FILE = 5,
	BG_ERROR_CONTEXT_GENERAL_TRANSPORT = 6,
	BG_ERROR_CONTEXT_REMOTE_APPLICATION = 7,
	BG_ERROR_CONTEXT_SERVER_CERTIFICATE_CALLBACK = 8,
}


[AllowDuplicates]
public enum BG_JOB_PRIORITY : int32
{
	BG_JOB_PRIORITY_FOREGROUND = 0,
	BG_JOB_PRIORITY_HIGH = 1,
	BG_JOB_PRIORITY_NORMAL = 2,
	BG_JOB_PRIORITY_LOW = 3,
}


[AllowDuplicates]
public enum BG_JOB_STATE : int32
{
	BG_JOB_STATE_QUEUED = 0,
	BG_JOB_STATE_CONNECTING = 1,
	BG_JOB_STATE_TRANSFERRING = 2,
	BG_JOB_STATE_SUSPENDED = 3,
	BG_JOB_STATE_ERROR = 4,
	BG_JOB_STATE_TRANSIENT_ERROR = 5,
	BG_JOB_STATE_TRANSFERRED = 6,
	BG_JOB_STATE_ACKNOWLEDGED = 7,
	BG_JOB_STATE_CANCELLED = 8,
}


[AllowDuplicates]
public enum BG_JOB_TYPE : int32
{
	BG_JOB_TYPE_DOWNLOAD = 0,
	BG_JOB_TYPE_UPLOAD = 1,
	BG_JOB_TYPE_UPLOAD_REPLY = 2,
}


[AllowDuplicates]
public enum BG_JOB_PROXY_USAGE : int32
{
	BG_JOB_PROXY_USAGE_PRECONFIG = 0,
	BG_JOB_PROXY_USAGE_NO_PROXY = 1,
	BG_JOB_PROXY_USAGE_OVERRIDE = 2,
	BG_JOB_PROXY_USAGE_AUTODETECT = 3,
}


[AllowDuplicates]
public enum BG_AUTH_TARGET : int32
{
	BG_AUTH_TARGET_SERVER = 1,
	BG_AUTH_TARGET_PROXY = 2,
}


[AllowDuplicates]
public enum BG_AUTH_SCHEME : int32
{
	BG_AUTH_SCHEME_BASIC = 1,
	BG_AUTH_SCHEME_DIGEST = 2,
	BG_AUTH_SCHEME_NTLM = 3,
	BG_AUTH_SCHEME_NEGOTIATE = 4,
	BG_AUTH_SCHEME_PASSPORT = 5,
}


[AllowDuplicates]
public enum BG_CERT_STORE_LOCATION : int32
{
	BG_CERT_STORE_LOCATION_CURRENT_USER = 0,
	BG_CERT_STORE_LOCATION_LOCAL_MACHINE = 1,
	BG_CERT_STORE_LOCATION_CURRENT_SERVICE = 2,
	BG_CERT_STORE_LOCATION_SERVICES = 3,
	BG_CERT_STORE_LOCATION_USERS = 4,
	BG_CERT_STORE_LOCATION_CURRENT_USER_GROUP_POLICY = 5,
	BG_CERT_STORE_LOCATION_LOCAL_MACHINE_GROUP_POLICY = 6,
	BG_CERT_STORE_LOCATION_LOCAL_MACHINE_ENTERPRISE = 7,
}


[AllowDuplicates]
public enum BITS_JOB_TRANSFER_POLICY : int32
{
	BITS_JOB_TRANSFER_POLICY_ALWAYS = -2147483393,
	BITS_JOB_TRANSFER_POLICY_NOT_ROAMING = -2147483521,
	BITS_JOB_TRANSFER_POLICY_NO_SURCHARGE = -2147483537,
	BITS_JOB_TRANSFER_POLICY_STANDARD = -2147483545,
	BITS_JOB_TRANSFER_POLICY_UNRESTRICTED = -2147483615,
}


[AllowDuplicates]
public enum BITS_JOB_PROPERTY_ID : int32
{
	BITS_JOB_PROPERTY_ID_COST_FLAGS = 1,
	BITS_JOB_PROPERTY_NOTIFICATION_CLSID = 2,
	BITS_JOB_PROPERTY_DYNAMIC_CONTENT = 3,
	BITS_JOB_PROPERTY_HIGH_PERFORMANCE = 4,
	BITS_JOB_PROPERTY_MAX_DOWNLOAD_SIZE = 5,
	BITS_JOB_PROPERTY_USE_STORED_CREDENTIALS = 7,
	BITS_JOB_PROPERTY_MINIMUM_NOTIFICATION_INTERVAL_MS = 9,
	BITS_JOB_PROPERTY_ON_DEMAND_MODE = 10,
}


[AllowDuplicates]
public enum BITS_FILE_PROPERTY_ID : int32
{
	BITS_FILE_PROPERTY_ID_HTTP_RESPONSE_HEADERS = 1,
}


[AllowDuplicates]
public enum GROUPPROP : int32
{
	GROUPPROP_PRIORITY = 0,
	GROUPPROP_REMOTEUSERID = 1,
	GROUPPROP_REMOTEUSERPWD = 2,
	GROUPPROP_LOCALUSERID = 3,
	GROUPPROP_LOCALUSERPWD = 4,
	GROUPPROP_PROTOCOLFLAGS = 5,
	GROUPPROP_NOTIFYFLAGS = 6,
	GROUPPROP_NOTIFYCLSID = 7,
	GROUPPROP_PROGRESSSIZE = 8,
	GROUPPROP_PROGRESSPERCENT = 9,
	GROUPPROP_PROGRESSTIME = 10,
	GROUPPROP_DISPLAYNAME = 11,
	GROUPPROP_DESCRIPTION = 12,
}

#endregion


#region Structs
[CRepr]
public struct BG_FILE_PROGRESS
{
	public uint64 BytesTotal;
	public uint64 BytesTransferred;
	public BOOL Completed;
}

[CRepr]
public struct BG_FILE_INFO
{
	public PWSTR RemoteName;
	public PWSTR LocalName;
}

[CRepr]
public struct BG_JOB_PROGRESS
{
	public uint64 BytesTotal;
	public uint64 BytesTransferred;
	public uint32 FilesTotal;
	public uint32 FilesTransferred;
}

[CRepr]
public struct BG_JOB_TIMES
{
	public FILETIME CreationTime;
	public FILETIME ModificationTime;
	public FILETIME TransferCompletionTime;
}

[CRepr]
public struct BG_JOB_REPLY_PROGRESS
{
	public uint64 BytesTotal;
	public uint64 BytesTransferred;
}

[CRepr]
public struct BG_BASIC_CREDENTIALS
{
	public PWSTR UserName;
	public PWSTR Password;
}

[CRepr, Union]
public struct BG_AUTH_CREDENTIALS_UNION
{
	public BG_BASIC_CREDENTIALS Basic;
}

[CRepr]
public struct BG_AUTH_CREDENTIALS
{
	public BG_AUTH_TARGET Target;
	public BG_AUTH_SCHEME Scheme;
	public BG_AUTH_CREDENTIALS_UNION Credentials;
}

[CRepr]
public struct BG_FILE_RANGE
{
	public uint64 InitialOffset;
	public uint64 Length;
}

[CRepr, Union]
public struct BITS_JOB_PROPERTY_VALUE
{
	public uint32 Dword;
	public Guid ClsID;
	public BOOL Enable;
	public uint64 Uint64;
	public BG_AUTH_TARGET Target;
}

[CRepr, Union]
public struct BITS_FILE_PROPERTY_VALUE
{
	public PWSTR String;
}

[CRepr]
public struct FILESETINFO
{
	public BSTR bstrRemoteFile;
	public BSTR bstrLocalFile;
	public uint32 dwSizeHint;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_BackgroundCopyManager = .(0x4991d34b, 0x80a1, 0x4291, 0x83, 0xb6, 0x33, 0x28, 0x36, 0x6b, 0x90, 0x97);


	public const Guid CLSID_BackgroundCopyManager1_5 = .(0xf087771f, 0xd74f, 0x4c1a, 0xbb, 0x8a, 0xe1, 0x6a, 0xca, 0x91, 0x24, 0xea);


	public const Guid CLSID_BackgroundCopyManager2_0 = .(0x6d18ad12, 0xbde3, 0x4393, 0xb3, 0x11, 0x09, 0x9c, 0x34, 0x6e, 0x6d, 0xf9);


	public const Guid CLSID_BackgroundCopyManager2_5 = .(0x03ca98d6, 0xff5d, 0x49b8, 0xab, 0xc6, 0x03, 0xdd, 0x84, 0x12, 0x70, 0x20);


	public const Guid CLSID_BackgroundCopyManager3_0 = .(0x659cdea7, 0x489e, 0x11d9, 0xa9, 0xcd, 0x00, 0x0d, 0x56, 0x96, 0x52, 0x51);


	public const Guid CLSID_BackgroundCopyManager4_0 = .(0xbb6df56b, 0xcace, 0x11dc, 0x99, 0x92, 0x00, 0x19, 0xb9, 0x3a, 0x3a, 0x84);


	public const Guid CLSID_BackgroundCopyManager5_0 = .(0x1ecca34c, 0xe88a, 0x44e3, 0x8d, 0x6a, 0x89, 0x21, 0xbd, 0xe9, 0xe4, 0x52);


	public const Guid CLSID_BackgroundCopyManager10_1 = .(0x4bd3e4e1, 0x7bd4, 0x4a2b, 0x99, 0x64, 0x49, 0x64, 0x00, 0xde, 0x51, 0x93);


	public const Guid CLSID_BackgroundCopyManager10_2 = .(0x4575438f, 0xa6c8, 0x4976, 0xb0, 0xfe, 0x2f, 0x26, 0xb8, 0x0d, 0x95, 0x9e);


	public const Guid CLSID_BackgroundCopyManager10_3 = .(0x5fd42ad5, 0xc04e, 0x4d36, 0xad, 0xc7, 0xe0, 0x8f, 0xf1, 0x57, 0x37, 0xad);


	public const Guid CLSID_BITSExtensionSetupFactory = .(0xefbbab68, 0x7286, 0x4783, 0x94, 0xbf, 0x94, 0x61, 0xd8, 0xb7, 0xe7, 0xe9);


	public const Guid CLSID_BackgroundCopyQMgr = .(0x69ad4aee, 0x51be, 0x439b, 0xa9, 0x2c, 0x86, 0xae, 0x49, 0x0e, 0x8b, 0x30);


}
#endregion

#region COM Types
[CRepr]struct IBackgroundCopyFile : IUnknown
{
	public new const Guid IID = .(0x01b7bd23, 0xfb88, 0x4a77, 0x84, 0x90, 0x58, 0x91, 0xd3, 0xe4, 0x65, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pVal) GetRemoteName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pVal) GetLocalName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_FILE_PROGRESS* pVal) GetProgress;
	}


	public HRESULT GetRemoteName(PWSTR* pVal) mut => VT.[Friend]GetRemoteName(&this, pVal);

	public HRESULT GetLocalName(PWSTR* pVal) mut => VT.[Friend]GetLocalName(&this, pVal);

	public HRESULT GetProgress(BG_FILE_PROGRESS* pVal) mut => VT.[Friend]GetProgress(&this, pVal);
}

[CRepr]struct IEnumBackgroundCopyFiles : IUnknown
{
	public new const Guid IID = .(0xca51e165, 0xc365, 0x424c, 0x8d, 0x41, 0x24, 0xaa, 0xa4, 0xff, 0x3c, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IBackgroundCopyFile** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumBackgroundCopyFiles** ppenum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puCount) GetCount;
	}


	public HRESULT Next(uint32 celt, IBackgroundCopyFile** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumBackgroundCopyFiles** ppenum) mut => VT.[Friend]Clone(&this, ppenum);

	public HRESULT GetCount(uint32* puCount) mut => VT.[Friend]GetCount(&this, puCount);
}

[CRepr]struct IBackgroundCopyError : IUnknown
{
	public new const Guid IID = .(0x19c613a0, 0xfcb8, 0x4f28, 0x81, 0xae, 0x89, 0x7c, 0x3d, 0x07, 0x8f, 0x81);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_ERROR_CONTEXT* pContext, HRESULT* pCode) GetError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyFile** pVal) GetFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 LanguageId, PWSTR* pErrorDescription) GetErrorDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 LanguageId, PWSTR* pContextDescription) GetErrorContextDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pProtocol) GetProtocol;
	}


	public HRESULT GetError(BG_ERROR_CONTEXT* pContext, HRESULT* pCode) mut => VT.[Friend]GetError(&this, pContext, pCode);

	public HRESULT GetFile(IBackgroundCopyFile** pVal) mut => VT.[Friend]GetFile(&this, pVal);

	public HRESULT GetErrorDescription(uint32 LanguageId, PWSTR* pErrorDescription) mut => VT.[Friend]GetErrorDescription(&this, LanguageId, pErrorDescription);

	public HRESULT GetErrorContextDescription(uint32 LanguageId, PWSTR* pContextDescription) mut => VT.[Friend]GetErrorContextDescription(&this, LanguageId, pContextDescription);

	public HRESULT GetProtocol(PWSTR* pProtocol) mut => VT.[Friend]GetProtocol(&this, pProtocol);
}

[CRepr]struct IBackgroundCopyJob : IUnknown
{
	public new const Guid IID = .(0x37668d37, 0x507e, 0x4160, 0x93, 0x16, 0x26, 0x30, 0x6d, 0x15, 0x0b, 0x12);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cFileCount, BG_FILE_INFO* pFileSet) AddFileSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR RemoteUrl, PWSTR LocalName) AddFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumBackgroundCopyFiles** pEnum) EnumFiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Suspend;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Complete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pVal) GetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_JOB_TYPE* pVal) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_JOB_PROGRESS* pVal) GetProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_JOB_TIMES* pVal) GetTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_JOB_STATE* pVal) GetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyError** ppError) GetError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pVal) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Val) SetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pVal) GetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Val) SetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pVal) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_JOB_PRIORITY Val) SetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_JOB_PRIORITY* pVal) GetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Val) SetNotifyFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pVal) GetNotifyFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* Val) SetNotifyInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) GetNotifyInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Seconds) SetMinimumRetryDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* Seconds) GetMinimumRetryDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Seconds) SetNoProgressTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* Seconds) GetNoProgressTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* Errors) GetErrorCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_JOB_PROXY_USAGE ProxyUsage, PWSTR ProxyList, PWSTR ProxyBypassList) SetProxySettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_JOB_PROXY_USAGE* pProxyUsage, PWSTR* pProxyList, PWSTR* pProxyBypassList) GetProxySettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TakeOwnership;
	}


	public HRESULT AddFileSet(uint32 cFileCount, BG_FILE_INFO* pFileSet) mut => VT.[Friend]AddFileSet(&this, cFileCount, pFileSet);

	public HRESULT AddFile(PWSTR RemoteUrl, PWSTR LocalName) mut => VT.[Friend]AddFile(&this, RemoteUrl, LocalName);

	public HRESULT EnumFiles(IEnumBackgroundCopyFiles** pEnum) mut => VT.[Friend]EnumFiles(&this, pEnum);

	public HRESULT Suspend() mut => VT.[Friend]Suspend(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT Complete() mut => VT.[Friend]Complete(&this);

	public HRESULT GetId(Guid* pVal) mut => VT.[Friend]GetId(&this, pVal);

	public HRESULT GetType(BG_JOB_TYPE* pVal) mut => VT.[Friend]COM_GetType(&this, pVal);

	public HRESULT GetProgress(BG_JOB_PROGRESS* pVal) mut => VT.[Friend]GetProgress(&this, pVal);

	public HRESULT GetTimes(BG_JOB_TIMES* pVal) mut => VT.[Friend]GetTimes(&this, pVal);

	public HRESULT GetState(BG_JOB_STATE* pVal) mut => VT.[Friend]GetState(&this, pVal);

	public HRESULT GetError(IBackgroundCopyError** ppError) mut => VT.[Friend]GetError(&this, ppError);

	public HRESULT GetOwner(PWSTR* pVal) mut => VT.[Friend]GetOwner(&this, pVal);

	public HRESULT SetDisplayName(PWSTR Val) mut => VT.[Friend]SetDisplayName(&this, Val);

	public HRESULT GetDisplayName(PWSTR* pVal) mut => VT.[Friend]GetDisplayName(&this, pVal);

	public HRESULT SetDescription(PWSTR Val) mut => VT.[Friend]SetDescription(&this, Val);

	public HRESULT GetDescription(PWSTR* pVal) mut => VT.[Friend]GetDescription(&this, pVal);

	public HRESULT SetPriority(BG_JOB_PRIORITY Val) mut => VT.[Friend]SetPriority(&this, Val);

	public HRESULT GetPriority(BG_JOB_PRIORITY* pVal) mut => VT.[Friend]GetPriority(&this, pVal);

	public HRESULT SetNotifyFlags(uint32 Val) mut => VT.[Friend]SetNotifyFlags(&this, Val);

	public HRESULT GetNotifyFlags(uint32* pVal) mut => VT.[Friend]GetNotifyFlags(&this, pVal);

	public HRESULT SetNotifyInterface(IUnknown* Val) mut => VT.[Friend]SetNotifyInterface(&this, Val);

	public HRESULT GetNotifyInterface(IUnknown** pVal) mut => VT.[Friend]GetNotifyInterface(&this, pVal);

	public HRESULT SetMinimumRetryDelay(uint32 Seconds) mut => VT.[Friend]SetMinimumRetryDelay(&this, Seconds);

	public HRESULT GetMinimumRetryDelay(uint32* Seconds) mut => VT.[Friend]GetMinimumRetryDelay(&this, Seconds);

	public HRESULT SetNoProgressTimeout(uint32 Seconds) mut => VT.[Friend]SetNoProgressTimeout(&this, Seconds);

	public HRESULT GetNoProgressTimeout(uint32* Seconds) mut => VT.[Friend]GetNoProgressTimeout(&this, Seconds);

	public HRESULT GetErrorCount(uint32* Errors) mut => VT.[Friend]GetErrorCount(&this, Errors);

	public HRESULT SetProxySettings(BG_JOB_PROXY_USAGE ProxyUsage, PWSTR ProxyList, PWSTR ProxyBypassList) mut => VT.[Friend]SetProxySettings(&this, ProxyUsage, ProxyList, ProxyBypassList);

	public HRESULT GetProxySettings(BG_JOB_PROXY_USAGE* pProxyUsage, PWSTR* pProxyList, PWSTR* pProxyBypassList) mut => VT.[Friend]GetProxySettings(&this, pProxyUsage, pProxyList, pProxyBypassList);

	public HRESULT TakeOwnership() mut => VT.[Friend]TakeOwnership(&this);
}

[CRepr]struct IEnumBackgroundCopyJobs : IUnknown
{
	public new const Guid IID = .(0x1af4f612, 0x3b71, 0x466f, 0x8f, 0x58, 0x7b, 0x6f, 0x73, 0xac, 0x57, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IBackgroundCopyJob** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumBackgroundCopyJobs** ppenum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puCount) GetCount;
	}


	public HRESULT Next(uint32 celt, IBackgroundCopyJob** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumBackgroundCopyJobs** ppenum) mut => VT.[Friend]Clone(&this, ppenum);

	public HRESULT GetCount(uint32* puCount) mut => VT.[Friend]GetCount(&this, puCount);
}

[CRepr]struct IBackgroundCopyCallback : IUnknown
{
	public new const Guid IID = .(0x97ea99c7, 0x0186, 0x4ad4, 0x8d, 0xf9, 0xc5, 0xb4, 0xe0, 0xed, 0x6b, 0x22);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyJob* pJob) JobTransferred;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyJob* pJob, IBackgroundCopyError* pError) JobError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyJob* pJob, uint32 dwReserved) JobModification;
	}


	public HRESULT JobTransferred(IBackgroundCopyJob* pJob) mut => VT.[Friend]JobTransferred(&this, pJob);

	public HRESULT JobError(IBackgroundCopyJob* pJob, IBackgroundCopyError* pError) mut => VT.[Friend]JobError(&this, pJob, pError);

	public HRESULT JobModification(IBackgroundCopyJob* pJob, uint32 dwReserved) mut => VT.[Friend]JobModification(&this, pJob, dwReserved);
}

[CRepr]struct AsyncIBackgroundCopyCallback : IUnknown
{
	public new const Guid IID = .(0xca29d251, 0xb4bb, 0x4679, 0xa3, 0xd9, 0xae, 0x80, 0x06, 0x11, 0x9d, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyJob* pJob) Begin_JobTransferred;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_JobTransferred;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyJob* pJob, IBackgroundCopyError* pError) Begin_JobError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_JobError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyJob* pJob, uint32 dwReserved) Begin_JobModification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_JobModification;
	}


	public HRESULT Begin_JobTransferred(IBackgroundCopyJob* pJob) mut => VT.[Friend]Begin_JobTransferred(&this, pJob);

	public HRESULT Finish_JobTransferred() mut => VT.[Friend]Finish_JobTransferred(&this);

	public HRESULT Begin_JobError(IBackgroundCopyJob* pJob, IBackgroundCopyError* pError) mut => VT.[Friend]Begin_JobError(&this, pJob, pError);

	public HRESULT Finish_JobError() mut => VT.[Friend]Finish_JobError(&this);

	public HRESULT Begin_JobModification(IBackgroundCopyJob* pJob, uint32 dwReserved) mut => VT.[Friend]Begin_JobModification(&this, pJob, dwReserved);

	public HRESULT Finish_JobModification() mut => VT.[Friend]Finish_JobModification(&this);
}

[CRepr]struct IBackgroundCopyManager : IUnknown
{
	public new const Guid IID = .(0x5ce34c0d, 0x0dc9, 0x4c1f, 0x89, 0x7c, 0xda, 0xa1, 0xb7, 0x8c, 0xee, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR DisplayName, BG_JOB_TYPE Type, Guid* pJobId, IBackgroundCopyJob** ppJob) CreateJob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid jobID, IBackgroundCopyJob** ppJob) GetJob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IEnumBackgroundCopyJobs** ppEnum) EnumJobs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hResult, uint32 LanguageId, PWSTR* pErrorDescription) GetErrorDescription;
	}


	public HRESULT CreateJob(PWSTR DisplayName, BG_JOB_TYPE Type, Guid* pJobId, IBackgroundCopyJob** ppJob) mut => VT.[Friend]CreateJob(&this, DisplayName, Type, pJobId, ppJob);

	public HRESULT GetJob(in Guid jobID, IBackgroundCopyJob** ppJob) mut => VT.[Friend]GetJob(&this, jobID, ppJob);

	public HRESULT EnumJobs(uint32 dwFlags, IEnumBackgroundCopyJobs** ppEnum) mut => VT.[Friend]EnumJobs(&this, dwFlags, ppEnum);

	public HRESULT GetErrorDescription(HRESULT hResult, uint32 LanguageId, PWSTR* pErrorDescription) mut => VT.[Friend]GetErrorDescription(&this, hResult, LanguageId, pErrorDescription);
}

[CRepr]struct IBackgroundCopyJob2 : IBackgroundCopyJob
{
	public new const Guid IID = .(0x54b50739, 0x686f, 0x45eb, 0x9d, 0xff, 0xd6, 0xa9, 0xa0, 0xfa, 0xa9, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyJob.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Program, PWSTR Parameters) SetNotifyCmdLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pProgram, PWSTR* pParameters) GetNotifyCmdLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_JOB_REPLY_PROGRESS* pProgress) GetReplyProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppBuffer, uint64* pLength) GetReplyData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR ReplyFileName) SetReplyFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pReplyFileName) GetReplyFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_AUTH_CREDENTIALS* credentials) SetCredentials;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_AUTH_TARGET Target, BG_AUTH_SCHEME Scheme) RemoveCredentials;
	}


	public HRESULT SetNotifyCmdLine(PWSTR Program, PWSTR Parameters) mut => VT.[Friend]SetNotifyCmdLine(&this, Program, Parameters);

	public HRESULT GetNotifyCmdLine(PWSTR* pProgram, PWSTR* pParameters) mut => VT.[Friend]GetNotifyCmdLine(&this, pProgram, pParameters);

	public HRESULT GetReplyProgress(BG_JOB_REPLY_PROGRESS* pProgress) mut => VT.[Friend]GetReplyProgress(&this, pProgress);

	public HRESULT GetReplyData(uint8** ppBuffer, uint64* pLength) mut => VT.[Friend]GetReplyData(&this, ppBuffer, pLength);

	public HRESULT SetReplyFileName(PWSTR ReplyFileName) mut => VT.[Friend]SetReplyFileName(&this, ReplyFileName);

	public HRESULT GetReplyFileName(PWSTR* pReplyFileName) mut => VT.[Friend]GetReplyFileName(&this, pReplyFileName);

	public HRESULT SetCredentials(BG_AUTH_CREDENTIALS* credentials) mut => VT.[Friend]SetCredentials(&this, credentials);

	public HRESULT RemoveCredentials(BG_AUTH_TARGET Target, BG_AUTH_SCHEME Scheme) mut => VT.[Friend]RemoveCredentials(&this, Target, Scheme);
}

[CRepr]struct IBackgroundCopyJob3 : IBackgroundCopyJob2
{
	public new const Guid IID = .(0x443c8934, 0x90ff, 0x48ed, 0xbc, 0xde, 0x26, 0xf5, 0xc7, 0x45, 0x00, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyJob2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR OldPrefix, PWSTR NewPrefix) ReplaceRemotePrefix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR RemoteUrl, PWSTR LocalName, uint32 RangeCount, BG_FILE_RANGE* Ranges) AddFileWithRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Flags) SetFileACLFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* Flags) GetFileACLFlags;
	}


	public HRESULT ReplaceRemotePrefix(PWSTR OldPrefix, PWSTR NewPrefix) mut => VT.[Friend]ReplaceRemotePrefix(&this, OldPrefix, NewPrefix);

	public HRESULT AddFileWithRanges(PWSTR RemoteUrl, PWSTR LocalName, uint32 RangeCount, BG_FILE_RANGE* Ranges) mut => VT.[Friend]AddFileWithRanges(&this, RemoteUrl, LocalName, RangeCount, Ranges);

	public HRESULT SetFileACLFlags(uint32 Flags) mut => VT.[Friend]SetFileACLFlags(&this, Flags);

	public HRESULT GetFileACLFlags(uint32* Flags) mut => VT.[Friend]GetFileACLFlags(&this, Flags);
}

[CRepr]struct IBackgroundCopyFile2 : IBackgroundCopyFile
{
	public new const Guid IID = .(0x83e81b93, 0x0873, 0x474d, 0x8a, 0x8c, 0xf2, 0x01, 0x8b, 0x1a, 0x93, 0x9c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyFile.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* RangeCount, BG_FILE_RANGE** Ranges) GetFileRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Val) SetRemoteName;
	}


	public HRESULT GetFileRanges(uint32* RangeCount, BG_FILE_RANGE** Ranges) mut => VT.[Friend]GetFileRanges(&this, RangeCount, Ranges);

	public HRESULT SetRemoteName(PWSTR Val) mut => VT.[Friend]SetRemoteName(&this, Val);
}

[CRepr]struct IBackgroundCopyJobHttpOptions : IUnknown
{
	public new const Guid IID = .(0xf1bd1079, 0x9f01, 0x4bdc, 0x80, 0x36, 0xf0, 0x9b, 0x70, 0x09, 0x50, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_CERT_STORE_LOCATION StoreLocation, PWSTR StoreName, uint8* pCertHashBlob) SetClientCertificateByID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_CERT_STORE_LOCATION StoreLocation, PWSTR StoreName, PWSTR SubjectName) SetClientCertificateByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveClientCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_CERT_STORE_LOCATION* pStoreLocation, PWSTR* pStoreName, uint8** ppCertHashBlob, PWSTR* pSubjectName) GetClientCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR RequestHeaders) SetCustomHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pRequestHeaders) GetCustomHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Flags) SetSecurityFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFlags) GetSecurityFlags;
	}


	public HRESULT SetClientCertificateByID(BG_CERT_STORE_LOCATION StoreLocation, PWSTR StoreName, uint8* pCertHashBlob) mut => VT.[Friend]SetClientCertificateByID(&this, StoreLocation, StoreName, pCertHashBlob);

	public HRESULT SetClientCertificateByName(BG_CERT_STORE_LOCATION StoreLocation, PWSTR StoreName, PWSTR SubjectName) mut => VT.[Friend]SetClientCertificateByName(&this, StoreLocation, StoreName, SubjectName);

	public HRESULT RemoveClientCertificate() mut => VT.[Friend]RemoveClientCertificate(&this);

	public HRESULT GetClientCertificate(BG_CERT_STORE_LOCATION* pStoreLocation, PWSTR* pStoreName, uint8** ppCertHashBlob, PWSTR* pSubjectName) mut => VT.[Friend]GetClientCertificate(&this, pStoreLocation, pStoreName, ppCertHashBlob, pSubjectName);

	public HRESULT SetCustomHeaders(PWSTR RequestHeaders) mut => VT.[Friend]SetCustomHeaders(&this, RequestHeaders);

	public HRESULT GetCustomHeaders(PWSTR* pRequestHeaders) mut => VT.[Friend]GetCustomHeaders(&this, pRequestHeaders);

	public HRESULT SetSecurityFlags(uint32 Flags) mut => VT.[Friend]SetSecurityFlags(&this, Flags);

	public HRESULT GetSecurityFlags(uint32* pFlags) mut => VT.[Friend]GetSecurityFlags(&this, pFlags);
}

[CRepr]struct IBitsPeerCacheRecord : IUnknown
{
	public new const Guid IID = .(0x659cdeaf, 0x489e, 0x11d9, 0xa9, 0xcd, 0x00, 0x0d, 0x56, 0x96, 0x52, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pVal) GetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pVal) GetOriginUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pVal) GetFileSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pVal) GetFileModificationTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pVal) GetLastAccessTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsFileValidated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pRangeCount, BG_FILE_RANGE** ppRanges) GetFileRanges;
	}


	public HRESULT GetId(Guid* pVal) mut => VT.[Friend]GetId(&this, pVal);

	public HRESULT GetOriginUrl(PWSTR* pVal) mut => VT.[Friend]GetOriginUrl(&this, pVal);

	public HRESULT GetFileSize(uint64* pVal) mut => VT.[Friend]GetFileSize(&this, pVal);

	public HRESULT GetFileModificationTime(FILETIME* pVal) mut => VT.[Friend]GetFileModificationTime(&this, pVal);

	public HRESULT GetLastAccessTime(FILETIME* pVal) mut => VT.[Friend]GetLastAccessTime(&this, pVal);

	public HRESULT IsFileValidated() mut => VT.[Friend]IsFileValidated(&this);

	public HRESULT GetFileRanges(uint32* pRangeCount, BG_FILE_RANGE** ppRanges) mut => VT.[Friend]GetFileRanges(&this, pRangeCount, ppRanges);
}

[CRepr]struct IEnumBitsPeerCacheRecords : IUnknown
{
	public new const Guid IID = .(0x659cdea4, 0x489e, 0x11d9, 0xa9, 0xcd, 0x00, 0x0d, 0x56, 0x96, 0x52, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IBitsPeerCacheRecord** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumBitsPeerCacheRecords** ppenum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puCount) GetCount;
	}


	public HRESULT Next(uint32 celt, IBitsPeerCacheRecord** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumBitsPeerCacheRecords** ppenum) mut => VT.[Friend]Clone(&this, ppenum);

	public HRESULT GetCount(uint32* puCount) mut => VT.[Friend]GetCount(&this, puCount);
}

[CRepr]struct IBitsPeer : IUnknown
{
	public new const Guid IID = .(0x659cdea2, 0x489e, 0x11d9, 0xa9, 0xcd, 0x00, 0x0d, 0x56, 0x96, 0x52, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pName) GetPeerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pAuth) IsAuthenticated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pOnline) IsAvailable;
	}


	public HRESULT GetPeerName(PWSTR* pName) mut => VT.[Friend]GetPeerName(&this, pName);

	public HRESULT IsAuthenticated(BOOL* pAuth) mut => VT.[Friend]IsAuthenticated(&this, pAuth);

	public HRESULT IsAvailable(BOOL* pOnline) mut => VT.[Friend]IsAvailable(&this, pOnline);
}

[CRepr]struct IEnumBitsPeers : IUnknown
{
	public new const Guid IID = .(0x659cdea5, 0x489e, 0x11d9, 0xa9, 0xcd, 0x00, 0x0d, 0x56, 0x96, 0x52, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IBitsPeer** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumBitsPeers** ppenum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puCount) GetCount;
	}


	public HRESULT Next(uint32 celt, IBitsPeer** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumBitsPeers** ppenum) mut => VT.[Friend]Clone(&this, ppenum);

	public HRESULT GetCount(uint32* puCount) mut => VT.[Friend]GetCount(&this, puCount);
}

[CRepr]struct IBitsPeerCacheAdministration : IUnknown
{
	public new const Guid IID = .(0x659cdead, 0x489e, 0x11d9, 0xa9, 0xcd, 0x00, 0x0d, 0x56, 0x96, 0x52, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pBytes) GetMaximumCacheSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Bytes) SetMaximumCacheSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pSeconds) GetMaximumContentAge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Seconds) SetMaximumContentAge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFlags) GetConfigurationFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Flags) SetConfigurationFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumBitsPeerCacheRecords** ppEnum) EnumRecords;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid id, IBitsPeerCacheRecord** ppRecord) GetRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearRecords;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid id) DeleteRecord;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR url) DeleteUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumBitsPeers** ppEnum) EnumPeers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearPeers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DiscoverPeers;
	}


	public HRESULT GetMaximumCacheSize(uint32* pBytes) mut => VT.[Friend]GetMaximumCacheSize(&this, pBytes);

	public HRESULT SetMaximumCacheSize(uint32 Bytes) mut => VT.[Friend]SetMaximumCacheSize(&this, Bytes);

	public HRESULT GetMaximumContentAge(uint32* pSeconds) mut => VT.[Friend]GetMaximumContentAge(&this, pSeconds);

	public HRESULT SetMaximumContentAge(uint32 Seconds) mut => VT.[Friend]SetMaximumContentAge(&this, Seconds);

	public HRESULT GetConfigurationFlags(uint32* pFlags) mut => VT.[Friend]GetConfigurationFlags(&this, pFlags);

	public HRESULT SetConfigurationFlags(uint32 Flags) mut => VT.[Friend]SetConfigurationFlags(&this, Flags);

	public HRESULT EnumRecords(IEnumBitsPeerCacheRecords** ppEnum) mut => VT.[Friend]EnumRecords(&this, ppEnum);

	public HRESULT GetRecord(in Guid id, IBitsPeerCacheRecord** ppRecord) mut => VT.[Friend]GetRecord(&this, id, ppRecord);

	public HRESULT ClearRecords() mut => VT.[Friend]ClearRecords(&this);

	public HRESULT DeleteRecord(in Guid id) mut => VT.[Friend]DeleteRecord(&this, id);

	public HRESULT DeleteUrl(PWSTR url) mut => VT.[Friend]DeleteUrl(&this, url);

	public HRESULT EnumPeers(IEnumBitsPeers** ppEnum) mut => VT.[Friend]EnumPeers(&this, ppEnum);

	public HRESULT ClearPeers() mut => VT.[Friend]ClearPeers(&this);

	public HRESULT DiscoverPeers() mut => VT.[Friend]DiscoverPeers(&this);
}

[CRepr]struct IBackgroundCopyJob4 : IBackgroundCopyJob3
{
	public new const Guid IID = .(0x659cdeae, 0x489e, 0x11d9, 0xa9, 0xcd, 0x00, 0x0d, 0x56, 0x96, 0x52, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyJob3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Flags) SetPeerCachingFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFlags) GetPeerCachingFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pLevel) GetOwnerIntegrityLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pElevated) GetOwnerElevationState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Timeout) SetMaximumDownloadTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pTimeout) GetMaximumDownloadTime;
	}


	public HRESULT SetPeerCachingFlags(uint32 Flags) mut => VT.[Friend]SetPeerCachingFlags(&this, Flags);

	public HRESULT GetPeerCachingFlags(uint32* pFlags) mut => VT.[Friend]GetPeerCachingFlags(&this, pFlags);

	public HRESULT GetOwnerIntegrityLevel(uint32* pLevel) mut => VT.[Friend]GetOwnerIntegrityLevel(&this, pLevel);

	public HRESULT GetOwnerElevationState(BOOL* pElevated) mut => VT.[Friend]GetOwnerElevationState(&this, pElevated);

	public HRESULT SetMaximumDownloadTime(uint32 Timeout) mut => VT.[Friend]SetMaximumDownloadTime(&this, Timeout);

	public HRESULT GetMaximumDownloadTime(uint32* pTimeout) mut => VT.[Friend]GetMaximumDownloadTime(&this, pTimeout);
}

[CRepr]struct IBackgroundCopyFile3 : IBackgroundCopyFile2
{
	public new const Guid IID = .(0x659cdeaa, 0x489e, 0x11d9, 0xa9, 0xcd, 0x00, 0x0d, 0x56, 0x96, 0x52, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyFile2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pFilename) GetTemporaryName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL state) SetValidationState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pState) GetValidationState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pVal) IsDownloadedFromPeer;
	}


	public HRESULT GetTemporaryName(PWSTR* pFilename) mut => VT.[Friend]GetTemporaryName(&this, pFilename);

	public HRESULT SetValidationState(BOOL state) mut => VT.[Friend]SetValidationState(&this, state);

	public HRESULT GetValidationState(BOOL* pState) mut => VT.[Friend]GetValidationState(&this, pState);

	public HRESULT IsDownloadedFromPeer(BOOL* pVal) mut => VT.[Friend]IsDownloadedFromPeer(&this, pVal);
}

[CRepr]struct IBackgroundCopyCallback2 : IBackgroundCopyCallback
{
	public new const Guid IID = .(0x659cdeac, 0x489e, 0x11d9, 0xa9, 0xcd, 0x00, 0x0d, 0x56, 0x96, 0x52, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyCallback.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyJob* pJob, IBackgroundCopyFile* pFile) FileTransferred;
	}


	public HRESULT FileTransferred(IBackgroundCopyJob* pJob, IBackgroundCopyFile* pFile) mut => VT.[Friend]FileTransferred(&this, pJob, pFile);
}

[CRepr]struct IBitsTokenOptions : IUnknown
{
	public new const Guid IID = .(0x9a2584c3, 0xf7d2, 0x457a, 0x9a, 0x5e, 0x22, 0xb6, 0x7b, 0xff, 0xc7, 0xd2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_TOKEN UsageFlags) SetHelperTokenFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BG_TOKEN* pFlags) GetHelperTokenFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetHelperToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearHelperToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pSid) GetHelperTokenSid;
	}


	public HRESULT SetHelperTokenFlags(BG_TOKEN UsageFlags) mut => VT.[Friend]SetHelperTokenFlags(&this, UsageFlags);

	public HRESULT GetHelperTokenFlags(BG_TOKEN* pFlags) mut => VT.[Friend]GetHelperTokenFlags(&this, pFlags);

	public HRESULT SetHelperToken() mut => VT.[Friend]SetHelperToken(&this);

	public HRESULT ClearHelperToken() mut => VT.[Friend]ClearHelperToken(&this);

	public HRESULT GetHelperTokenSid(PWSTR* pSid) mut => VT.[Friend]GetHelperTokenSid(&this, pSid);
}

[CRepr]struct IBackgroundCopyFile4 : IBackgroundCopyFile3
{
	public new const Guid IID = .(0xef7e0655, 0x7888, 0x4960, 0xb0, 0xe5, 0x73, 0x08, 0x46, 0xe0, 0x34, 0x92);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyFile3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pFromOrigin, uint64* pFromPeers) GetPeerDownloadStats;
	}


	public HRESULT GetPeerDownloadStats(uint64* pFromOrigin, uint64* pFromPeers) mut => VT.[Friend]GetPeerDownloadStats(&this, pFromOrigin, pFromPeers);
}

[CRepr]struct IBackgroundCopyJob5 : IBackgroundCopyJob4
{
	public new const Guid IID = .(0xe847030c, 0xbbba, 0x4657, 0xaf, 0x6d, 0x48, 0x4a, 0xa4, 0x2b, 0xf1, 0xfe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyJob4.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BITS_JOB_PROPERTY_ID PropertyId, BITS_JOB_PROPERTY_VALUE PropertyValue) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BITS_JOB_PROPERTY_ID PropertyId, BITS_JOB_PROPERTY_VALUE* PropertyValue) GetProperty;
	}


	public HRESULT SetProperty(BITS_JOB_PROPERTY_ID PropertyId, BITS_JOB_PROPERTY_VALUE PropertyValue) mut => VT.[Friend]SetProperty(&this, PropertyId, PropertyValue);

	public HRESULT GetProperty(BITS_JOB_PROPERTY_ID PropertyId, BITS_JOB_PROPERTY_VALUE* PropertyValue) mut => VT.[Friend]GetProperty(&this, PropertyId, PropertyValue);
}

[CRepr]struct IBackgroundCopyFile5 : IBackgroundCopyFile4
{
	public new const Guid IID = .(0x85c1657f, 0xdafc, 0x40e8, 0x88, 0x34, 0xdf, 0x18, 0xea, 0x25, 0x71, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyFile4.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BITS_FILE_PROPERTY_ID PropertyId, BITS_FILE_PROPERTY_VALUE PropertyValue) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BITS_FILE_PROPERTY_ID PropertyId, BITS_FILE_PROPERTY_VALUE* PropertyValue) GetProperty;
	}


	public HRESULT SetProperty(BITS_FILE_PROPERTY_ID PropertyId, BITS_FILE_PROPERTY_VALUE PropertyValue) mut => VT.[Friend]SetProperty(&this, PropertyId, PropertyValue);

	public HRESULT GetProperty(BITS_FILE_PROPERTY_ID PropertyId, BITS_FILE_PROPERTY_VALUE* PropertyValue) mut => VT.[Friend]GetProperty(&this, PropertyId, PropertyValue);
}

[CRepr]struct IBackgroundCopyCallback3 : IBackgroundCopyCallback2
{
	public new const Guid IID = .(0x98c97bd2, 0xe32b, 0x4ad8, 0xa5, 0x28, 0x95, 0xfd, 0x8b, 0x16, 0xbd, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyCallback2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyJob* job, IBackgroundCopyFile* file, uint32 rangeCount, BG_FILE_RANGE* ranges) FileRangesTransferred;
	}


	public HRESULT FileRangesTransferred(IBackgroundCopyJob* job, IBackgroundCopyFile* file, uint32 rangeCount, BG_FILE_RANGE* ranges) mut => VT.[Friend]FileRangesTransferred(&this, job, file, rangeCount, ranges);
}

[CRepr]struct IBackgroundCopyFile6 : IBackgroundCopyFile5
{
	public new const Guid IID = .(0xcf6784f7, 0xd677, 0x49fd, 0x93, 0x68, 0xcb, 0x47, 0xae, 0xe9, 0xd1, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyFile5.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 offset) UpdateDownloadPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 rangeCount, BG_FILE_RANGE* ranges) RequestFileRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* rangeCount, BG_FILE_RANGE** ranges) GetFilledFileRanges;
	}


	public HRESULT UpdateDownloadPosition(uint64 offset) mut => VT.[Friend]UpdateDownloadPosition(&this, offset);

	public HRESULT RequestFileRanges(uint32 rangeCount, BG_FILE_RANGE* ranges) mut => VT.[Friend]RequestFileRanges(&this, rangeCount, ranges);

	public HRESULT GetFilledFileRanges(uint32* rangeCount, BG_FILE_RANGE** ranges) mut => VT.[Friend]GetFilledFileRanges(&this, rangeCount, ranges);
}

[CRepr]struct IBackgroundCopyJobHttpOptions2 : IBackgroundCopyJobHttpOptions
{
	public new const Guid IID = .(0xb591a192, 0xa405, 0x4fc3, 0x83, 0x23, 0x4c, 0x5c, 0x54, 0x25, 0x78, 0xfc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyJobHttpOptions.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR method) SetHttpMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* method) GetHttpMethod;
	}


	public HRESULT SetHttpMethod(PWSTR method) mut => VT.[Friend]SetHttpMethod(&this, method);

	public HRESULT GetHttpMethod(PWSTR* method) mut => VT.[Friend]GetHttpMethod(&this, method);
}

[CRepr]struct IBackgroundCopyServerCertificateValidationCallback : IUnknown
{
	public new const Guid IID = .(0x4cec0d02, 0xdef7, 0x4158, 0x81, 0x3a, 0xc3, 0x2a, 0x46, 0x94, 0x5f, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyJob* job, IBackgroundCopyFile* file, uint32 certLength, uint8* certData, uint32 certEncodingType, uint32 certStoreLength, uint8* certStoreData) ValidateServerCertificate;
	}


	public HRESULT ValidateServerCertificate(IBackgroundCopyJob* job, IBackgroundCopyFile* file, uint32 certLength, uint8* certData, uint32 certEncodingType, uint32 certStoreLength, uint8* certStoreData) mut => VT.[Friend]ValidateServerCertificate(&this, job, file, certLength, certData, certEncodingType, certStoreLength, certStoreData);
}

[CRepr]struct IBackgroundCopyJobHttpOptions3 : IBackgroundCopyJobHttpOptions2
{
	public new const Guid IID = .(0x8a9263d3, 0xfd4c, 0x4eda, 0x9b, 0x28, 0x30, 0x13, 0x2a, 0x4d, 0x4e, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBackgroundCopyJobHttpOptions2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* certValidationCallback) SetServerCertificateValidationInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MakeCustomHeadersWriteOnly;
	}


	public HRESULT SetServerCertificateValidationInterface(IUnknown* certValidationCallback) mut => VT.[Friend]SetServerCertificateValidationInterface(&this, certValidationCallback);

	public HRESULT MakeCustomHeadersWriteOnly() mut => VT.[Friend]MakeCustomHeadersWriteOnly(&this);
}

[CRepr]struct IBITSExtensionSetup : IDispatch
{
	public new const Guid IID = .(0x29cfbbf7, 0x09e4, 0x4b97, 0xb0, 0xbc, 0xf2, 0x28, 0x7e, 0x3d, 0x8e, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableBITSUploads;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableBITSUploads;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pTaskName) GetCleanupTaskName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppUnk) GetCleanupTask;
	}


	public HRESULT EnableBITSUploads() mut => VT.[Friend]EnableBITSUploads(&this);

	public HRESULT DisableBITSUploads() mut => VT.[Friend]DisableBITSUploads(&this);

	public HRESULT GetCleanupTaskName(BSTR* pTaskName) mut => VT.[Friend]GetCleanupTaskName(&this, pTaskName);

	public HRESULT GetCleanupTask(in Guid riid, IUnknown** ppUnk) mut => VT.[Friend]GetCleanupTask(&this, riid, ppUnk);
}

[CRepr]struct IBITSExtensionSetupFactory : IDispatch
{
	public new const Guid IID = .(0xd5d2d542, 0x5503, 0x4e64, 0x8b, 0x48, 0x72, 0xef, 0x91, 0xa3, 0x2e, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Path, IBITSExtensionSetup** ppExtensionSetup) GetObject;
	}


	public HRESULT GetObject(BSTR Path, IBITSExtensionSetup** ppExtensionSetup) mut => VT.[Friend]GetObject(&this, Path, ppExtensionSetup);
}

[CRepr]struct IBackgroundCopyJob1 : IUnknown
{
	public new const Guid IID = .(0x59f5553c, 0x2031, 0x4629, 0xbb, 0x18, 0x26, 0x45, 0xa6, 0x97, 0x09, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelJob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32* pdwProgress) GetProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus, uint32* pdwWin32Result, uint32* pdwTransportResult, uint32* pdwNumOfRetries) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cFileCount, FILESETINFO** ppFileSet) AddFiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cFileIndex, FILESETINFO* pFileInfo) GetFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFileCount) GetFileCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SwitchToForeground;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidJobID) get_JobID;
	}


	public HRESULT CancelJob() mut => VT.[Friend]CancelJob(&this);

	public HRESULT GetProgress(uint32 dwFlags, uint32* pdwProgress) mut => VT.[Friend]GetProgress(&this, dwFlags, pdwProgress);

	public HRESULT GetStatus(uint32* pdwStatus, uint32* pdwWin32Result, uint32* pdwTransportResult, uint32* pdwNumOfRetries) mut => VT.[Friend]GetStatus(&this, pdwStatus, pdwWin32Result, pdwTransportResult, pdwNumOfRetries);

	public HRESULT AddFiles(uint32 cFileCount, FILESETINFO** ppFileSet) mut => VT.[Friend]AddFiles(&this, cFileCount, ppFileSet);

	public HRESULT GetFile(uint32 cFileIndex, FILESETINFO* pFileInfo) mut => VT.[Friend]GetFile(&this, cFileIndex, pFileInfo);

	public HRESULT GetFileCount(uint32* pdwFileCount) mut => VT.[Friend]GetFileCount(&this, pdwFileCount);

	public HRESULT SwitchToForeground() mut => VT.[Friend]SwitchToForeground(&this);

	public HRESULT get_JobID(Guid* pguidJobID) mut => VT.[Friend]get_JobID(&this, pguidJobID);
}

[CRepr]struct IEnumBackgroundCopyJobs1 : IUnknown
{
	public new const Guid IID = .(0x8baeba9d, 0x8f1c, 0x42c4, 0xb8, 0x2c, 0x09, 0xae, 0x79, 0x98, 0x0d, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, Guid* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumBackgroundCopyJobs1** ppenum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puCount) GetCount;
	}


	public HRESULT Next(uint32 celt, Guid* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumBackgroundCopyJobs1** ppenum) mut => VT.[Friend]Clone(&this, ppenum);

	public HRESULT GetCount(uint32* puCount) mut => VT.[Friend]GetCount(&this, puCount);
}

[CRepr]struct IBackgroundCopyGroup : IUnknown
{
	public new const Guid IID = .(0x1ded80a7, 0x53ea, 0x424f, 0x8a, 0x04, 0x17, 0xfe, 0xa9, 0xad, 0xc4, 0xf5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GROUPPROP propID, VARIANT* pvarVal) GetProp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GROUPPROP propID, VARIANT* pvarVal) SetProp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32* pdwProgress) GetProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus, uint32* pdwJobIndex) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid jobID, IBackgroundCopyJob1** ppJob) GetJob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SuspendGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResumeGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwSize) get_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidGroupID) get_GroupID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guidJobID, IBackgroundCopyJob1** ppJob) CreateJob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IEnumBackgroundCopyJobs1** ppEnumJobs) EnumJobs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SwitchToForeground;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid iid, IUnknown** pUnk) QueryNewJobInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid iid, IUnknown* pUnk) SetNotificationPointer;
	}


	public HRESULT GetProp(GROUPPROP propID, VARIANT* pvarVal) mut => VT.[Friend]GetProp(&this, propID, pvarVal);

	public HRESULT SetProp(GROUPPROP propID, VARIANT* pvarVal) mut => VT.[Friend]SetProp(&this, propID, pvarVal);

	public HRESULT GetProgress(uint32 dwFlags, uint32* pdwProgress) mut => VT.[Friend]GetProgress(&this, dwFlags, pdwProgress);

	public HRESULT GetStatus(uint32* pdwStatus, uint32* pdwJobIndex) mut => VT.[Friend]GetStatus(&this, pdwStatus, pdwJobIndex);

	public HRESULT GetJob(Guid jobID, IBackgroundCopyJob1** ppJob) mut => VT.[Friend]GetJob(&this, jobID, ppJob);

	public HRESULT SuspendGroup() mut => VT.[Friend]SuspendGroup(&this);

	public HRESULT ResumeGroup() mut => VT.[Friend]ResumeGroup(&this);

	public HRESULT CancelGroup() mut => VT.[Friend]CancelGroup(&this);

	public HRESULT get_Size(uint32* pdwSize) mut => VT.[Friend]get_Size(&this, pdwSize);

	public HRESULT get_GroupID(Guid* pguidGroupID) mut => VT.[Friend]get_GroupID(&this, pguidGroupID);

	public HRESULT CreateJob(Guid guidJobID, IBackgroundCopyJob1** ppJob) mut => VT.[Friend]CreateJob(&this, guidJobID, ppJob);

	public HRESULT EnumJobs(uint32 dwFlags, IEnumBackgroundCopyJobs1** ppEnumJobs) mut => VT.[Friend]EnumJobs(&this, dwFlags, ppEnumJobs);

	public HRESULT SwitchToForeground() mut => VT.[Friend]SwitchToForeground(&this);

	public HRESULT QueryNewJobInterface(in Guid iid, IUnknown** pUnk) mut => VT.[Friend]QueryNewJobInterface(&this, iid, pUnk);

	public HRESULT SetNotificationPointer(in Guid iid, IUnknown* pUnk) mut => VT.[Friend]SetNotificationPointer(&this, iid, pUnk);
}

[CRepr]struct IEnumBackgroundCopyGroups : IUnknown
{
	public new const Guid IID = .(0xd993e603, 0x4aa4, 0x47c5, 0x86, 0x65, 0xc2, 0x0d, 0x39, 0xc2, 0xba, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, Guid* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumBackgroundCopyGroups** ppenum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puCount) GetCount;
	}


	public HRESULT Next(uint32 celt, Guid* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumBackgroundCopyGroups** ppenum) mut => VT.[Friend]Clone(&this, ppenum);

	public HRESULT GetCount(uint32* puCount) mut => VT.[Friend]GetCount(&this, puCount);
}

[CRepr]struct IBackgroundCopyCallback1 : IUnknown
{
	public new const Guid IID = .(0x084f6593, 0x3800, 0x4e08, 0x9b, 0x59, 0x99, 0xfa, 0x59, 0xad, 0xdf, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBackgroundCopyGroup* pGroup, IBackgroundCopyJob1* pJob, uint32 dwFileIndex, uint32 dwStatus, uint32 dwNumOfRetries, uint32 dwWin32Result, uint32 dwTransportResult) OnStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ProgressType, IBackgroundCopyGroup* pGroup, IBackgroundCopyJob1* pJob, uint32 dwFileIndex, uint32 dwProgressValue) OnProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ProgressType, IBackgroundCopyGroup* pGroup, IBackgroundCopyJob1* pJob, uint32 dwFileIndex, uint32 dwProgressValue, uint32 dwByteArraySize, uint8* pByte) OnProgressEx;
	}


	public HRESULT OnStatus(IBackgroundCopyGroup* pGroup, IBackgroundCopyJob1* pJob, uint32 dwFileIndex, uint32 dwStatus, uint32 dwNumOfRetries, uint32 dwWin32Result, uint32 dwTransportResult) mut => VT.[Friend]OnStatus(&this, pGroup, pJob, dwFileIndex, dwStatus, dwNumOfRetries, dwWin32Result, dwTransportResult);

	public HRESULT OnProgress(uint32 ProgressType, IBackgroundCopyGroup* pGroup, IBackgroundCopyJob1* pJob, uint32 dwFileIndex, uint32 dwProgressValue) mut => VT.[Friend]OnProgress(&this, ProgressType, pGroup, pJob, dwFileIndex, dwProgressValue);

	public HRESULT OnProgressEx(uint32 ProgressType, IBackgroundCopyGroup* pGroup, IBackgroundCopyJob1* pJob, uint32 dwFileIndex, uint32 dwProgressValue, uint32 dwByteArraySize, uint8* pByte) mut => VT.[Friend]OnProgressEx(&this, ProgressType, pGroup, pJob, dwFileIndex, dwProgressValue, dwByteArraySize, pByte);
}

[CRepr]struct IBackgroundCopyQMgr : IUnknown
{
	public new const Guid IID = .(0x16f41c69, 0x09f5, 0x41d2, 0x8c, 0xd8, 0x3c, 0x08, 0xc4, 0x7b, 0xc8, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guidGroupID, IBackgroundCopyGroup** ppGroup) CreateGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid groupID, IBackgroundCopyGroup** ppGroup) GetGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IEnumBackgroundCopyGroups** ppEnumGroups) EnumGroups;
	}


	public HRESULT CreateGroup(Guid guidGroupID, IBackgroundCopyGroup** ppGroup) mut => VT.[Friend]CreateGroup(&this, guidGroupID, ppGroup);

	public HRESULT GetGroup(Guid groupID, IBackgroundCopyGroup** ppGroup) mut => VT.[Friend]GetGroup(&this, groupID, ppGroup);

	public HRESULT EnumGroups(uint32 dwFlags, IEnumBackgroundCopyGroups** ppEnumGroups) mut => VT.[Friend]EnumGroups(&this, dwFlags, ppEnumGroups);
}

#endregion
