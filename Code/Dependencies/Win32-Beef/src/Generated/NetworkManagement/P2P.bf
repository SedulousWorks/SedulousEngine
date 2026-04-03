using Win32.Foundation;
using Win32.Networking.WinSock;
using Win32.System.Com;
using Win32.Security.Cryptography;
using Win32.System.IO;
using System;

namespace Win32.NetworkManagement.P2P;

#region Constants
public static
{
	public const uint32 NS_PNRPNAME = 38;
	public const uint32 NS_PNRPCLOUD = 39;
	public const uint32 PNRPINFO_HINT = 1;
	public const Guid NS_PROVIDER_PNRPNAME = .(0x03fe89cd, 0x766d, 0x4976, 0xb9, 0xc1, 0xbb, 0x9b, 0xc4, 0x2c, 0x7b, 0x4d);
	public const Guid NS_PROVIDER_PNRPCLOUD = .(0x03fe89ce, 0x766d, 0x4976, 0xb9, 0xc1, 0xbb, 0x9b, 0xc4, 0x2c, 0x7b, 0x4d);
	public const Guid SVCID_PNRPCLOUD = .(0xc2239ce6, 0x00c0, 0x4fbf, 0xba, 0xd6, 0x18, 0x13, 0x93, 0x85, 0xa4, 0x9a);
	public const Guid SVCID_PNRPNAME_V1 = .(0xc2239ce5, 0x00c0, 0x4fbf, 0xba, 0xd6, 0x18, 0x13, 0x93, 0x85, 0xa4, 0x9a);
	public const Guid SVCID_PNRPNAME_V2 = .(0xc2239ce7, 0x00c0, 0x4fbf, 0xba, 0xd6, 0x18, 0x13, 0x93, 0x85, 0xa4, 0x9a);
	public const uint32 PNRP_MAX_ENDPOINT_ADDRESSES = 10;
	public const String WSZ_SCOPE_GLOBAL = "GLOBAL";
	public const String WSZ_SCOPE_SITELOCAL = "SITELOCAL";
	public const String WSZ_SCOPE_LINKLOCAL = "LINKLOCAL";
	public const uint32 PNRP_MAX_EXTENDED_PAYLOAD_BYTES = 4096;
	public const String PEER_PNRP_ALL_LINK_CLOUDS = "PEER_PNRP_ALL_LINKS";
	public const uint32 WSA_PNRP_ERROR_BASE = 11500;
	public const uint32 WSA_PNRP_CLOUD_NOT_FOUND = 11501;
	public const uint32 WSA_PNRP_CLOUD_DISABLED = 11502;
	public const uint32 WSA_PNRP_INVALID_IDENTITY = 11503;
	public const uint32 WSA_PNRP_TOO_MUCH_LOAD = 11504;
	public const uint32 WSA_PNRP_CLOUD_IS_SEARCH_ONLY = 11505;
	public const uint32 WSA_PNRP_CLIENT_INVALID_COMPARTMENT_ID = 11506;
	public const uint32 WSA_PNRP_DUPLICATE_PEER_NAME = 11508;
	public const uint32 WSA_PNRP_CLOUD_IS_DEAD = 11509;
	public const HRESULT PEER_E_CLOUD_NOT_FOUND = -2147013395;
	public const HRESULT PEER_E_CLOUD_DISABLED = -2147013394;
	public const HRESULT PEER_E_INVALID_IDENTITY = -2147013393;
	public const HRESULT PEER_E_TOO_MUCH_LOAD = -2147013392;
	public const HRESULT PEER_E_CLOUD_IS_SEARCH_ONLY = -2147013391;
	public const HRESULT PEER_E_CLIENT_INVALID_COMPARTMENT_ID = -2147013390;
	public const HRESULT PEER_E_DUPLICATE_PEER_NAME = -2147013388;
	public const HRESULT PEER_E_CLOUD_IS_DEAD = -2147013387;
	public const HRESULT PEER_E_NOT_FOUND = -2147023728;
	public const HRESULT PEER_E_DISK_FULL = -2147024784;
	public const HRESULT PEER_E_ALREADY_EXISTS = -2147024713;
	public const Guid PEER_GROUP_ROLE_ADMIN = .(0x04387127, 0xaa56, 0x450a, 0x8c, 0xe5, 0x4f, 0x56, 0x5c, 0x67, 0x90, 0xf4);
	public const Guid PEER_GROUP_ROLE_MEMBER = .(0xf12dc4c7, 0x0857, 0x4ca0, 0x93, 0xfc, 0xb1, 0xbb, 0x19, 0xa3, 0xd8, 0xc2);
	public const Guid PEER_GROUP_ROLE_INVITING_MEMBER = .(0x4370fd89, 0xdc18, 0x4cfb, 0x8d, 0xbf, 0x98, 0x53, 0xa8, 0xa9, 0xf9, 0x05);
	public const Guid PEER_COLLAB_OBJECTID_USER_PICTURE = .(0xdd15f41f, 0xfc4e, 0x4922, 0xb0, 0x35, 0x4c, 0x06, 0xa7, 0x54, 0xd0, 0x1d);
	public const uint32 FACILITY_DRT = 98;
	public const HRESULT DRT_E_TIMEOUT = -2141057023;
	public const HRESULT DRT_E_INVALID_KEY_SIZE = -2141057022;
	public const HRESULT DRT_E_INVALID_CERT_CHAIN = -2141057020;
	public const HRESULT DRT_E_INVALID_MESSAGE = -2141057019;
	public const HRESULT DRT_E_NO_MORE = -2141057018;
	public const HRESULT DRT_E_INVALID_MAX_ADDRESSES = -2141057017;
	public const HRESULT DRT_E_SEARCH_IN_PROGRESS = -2141057016;
	public const HRESULT DRT_E_INVALID_KEY = -2141057015;
	public const HRESULT DRT_S_RETRY = 6426640;
	public const HRESULT DRT_E_INVALID_MAX_ENDPOINTS = -2141057007;
	public const HRESULT DRT_E_INVALID_SEARCH_RANGE = -2141057006;
	public const HRESULT DRT_E_INVALID_PORT = -2141052928;
	public const HRESULT DRT_E_INVALID_TRANSPORT_PROVIDER = -2141052927;
	public const HRESULT DRT_E_INVALID_SECURITY_PROVIDER = -2141052926;
	public const HRESULT DRT_E_STILL_IN_USE = -2141052925;
	public const HRESULT DRT_E_INVALID_BOOTSTRAP_PROVIDER = -2141052924;
	public const HRESULT DRT_E_INVALID_ADDRESS = -2141052923;
	public const HRESULT DRT_E_INVALID_SCOPE = -2141052922;
	public const HRESULT DRT_E_TRANSPORT_SHUTTING_DOWN = -2141052921;
	public const HRESULT DRT_E_NO_ADDRESSES_AVAILABLE = -2141052920;
	public const HRESULT DRT_E_DUPLICATE_KEY = -2141052919;
	public const HRESULT DRT_E_TRANSPORTPROVIDER_IN_USE = -2141052918;
	public const HRESULT DRT_E_TRANSPORTPROVIDER_NOT_ATTACHED = -2141052917;
	public const HRESULT DRT_E_SECURITYPROVIDER_IN_USE = -2141052916;
	public const HRESULT DRT_E_SECURITYPROVIDER_NOT_ATTACHED = -2141052915;
	public const HRESULT DRT_E_BOOTSTRAPPROVIDER_IN_USE = -2141052914;
	public const HRESULT DRT_E_BOOTSTRAPPROVIDER_NOT_ATTACHED = -2141052913;
	public const HRESULT DRT_E_TRANSPORT_ALREADY_BOUND = -2141052671;
	public const HRESULT DRT_E_TRANSPORT_NOT_BOUND = -2141052670;
	public const HRESULT DRT_E_TRANSPORT_UNEXPECTED = -2141052669;
	public const HRESULT DRT_E_TRANSPORT_INVALID_ARGUMENT = -2141052668;
	public const HRESULT DRT_E_TRANSPORT_NO_DEST_ADDRESSES = -2141052667;
	public const HRESULT DRT_E_TRANSPORT_EXECUTING_CALLBACK = -2141052666;
	public const HRESULT DRT_E_TRANSPORT_ALREADY_EXISTS_FOR_SCOPE = -2141052665;
	public const HRESULT DRT_E_INVALID_SETTINGS = -2141052664;
	public const HRESULT DRT_E_INVALID_SEARCH_INFO = -2141052663;
	public const HRESULT DRT_E_FAULTED = -2141052662;
	public const HRESULT DRT_E_TRANSPORT_STILL_BOUND = -2141052661;
	public const HRESULT DRT_E_INSUFFICIENT_BUFFER = -2141052660;
	public const HRESULT DRT_E_INVALID_INSTANCE_PREFIX = -2141052659;
	public const HRESULT DRT_E_INVALID_SECURITY_MODE = -2141052658;
	public const HRESULT DRT_E_CAPABILITY_MISMATCH = -2141052657;
	public const uint32 DRT_PAYLOAD_REVOKED = 1;
	public const uint32 DRT_MIN_ROUTING_ADDRESSES = 1;
	public const uint32 DRT_MAX_ROUTING_ADDRESSES = 20;
	public const uint32 DRT_MAX_PAYLOAD_SIZE = 5120;
	public const uint32 DRT_MAX_INSTANCE_PREFIX_LEN = 128;
	public const uint32 DRT_LINK_LOCAL_ISATAP_SCOPEID = 4294967295;
	public const int32 PEERDIST_PUBLICATION_OPTIONS_VERSION_1 = 1;
	public const int32 PEERDIST_PUBLICATION_OPTIONS_VERSION = 2;
	public const int32 PEERDIST_PUBLICATION_OPTIONS_VERSION_2 = 2;
	public const uint32 PEERDIST_READ_TIMEOUT_LOCAL_CACHE_ONLY = 0;
	public const uint32 PEERDIST_READ_TIMEOUT_DEFAULT = 4294967294;
}
#endregion

#region Enums

[AllowDuplicates]
public enum PEERDIST_RETRIEVAL_OPTIONS_CONTENTINFO_VERSION_VALUE : uint32
{
	PEERDIST_RETRIEVAL_OPTIONS_CONTENTINFO_VERSION_1 = 1,
	PEERDIST_RETRIEVAL_OPTIONS_CONTENTINFO_VERSION_2 = 2,
	PEERDIST_RETRIEVAL_OPTIONS_CONTENTINFO_VERSION = 2,
}


[AllowDuplicates]
public enum PNRP_SCOPE : int32
{
	PNRP_SCOPE_ANY = 0,
	PNRP_GLOBAL_SCOPE = 1,
	PNRP_SITE_LOCAL_SCOPE = 2,
	PNRP_LINK_LOCAL_SCOPE = 3,
}


[AllowDuplicates]
public enum PNRP_CLOUD_STATE : int32
{
	PNRP_CLOUD_STATE_VIRTUAL = 0,
	PNRP_CLOUD_STATE_SYNCHRONISING = 1,
	PNRP_CLOUD_STATE_ACTIVE = 2,
	PNRP_CLOUD_STATE_DEAD = 3,
	PNRP_CLOUD_STATE_DISABLED = 4,
	PNRP_CLOUD_STATE_NO_NET = 5,
	PNRP_CLOUD_STATE_ALONE = 6,
}


[AllowDuplicates]
public enum PNRP_CLOUD_FLAGS : int32
{
	PNRP_CLOUD_NO_FLAGS = 0,
	PNRP_CLOUD_NAME_LOCAL = 1,
	PNRP_CLOUD_RESOLVE_ONLY = 2,
	PNRP_CLOUD_FULL_PARTICIPANT = 4,
}


[AllowDuplicates]
public enum PNRP_REGISTERED_ID_STATE : int32
{
	PNRP_REGISTERED_ID_STATE_OK = 1,
	PNRP_REGISTERED_ID_STATE_PROBLEM = 2,
}


[AllowDuplicates]
public enum PNRP_RESOLVE_CRITERIA : int32
{
	PNRP_RESOLVE_CRITERIA_DEFAULT = 0,
	PNRP_RESOLVE_CRITERIA_REMOTE_PEER_NAME = 1,
	PNRP_RESOLVE_CRITERIA_NEAREST_REMOTE_PEER_NAME = 2,
	PNRP_RESOLVE_CRITERIA_NON_CURRENT_PROCESS_PEER_NAME = 3,
	PNRP_RESOLVE_CRITERIA_NEAREST_NON_CURRENT_PROCESS_PEER_NAME = 4,
	PNRP_RESOLVE_CRITERIA_ANY_PEER_NAME = 5,
	PNRP_RESOLVE_CRITERIA_NEAREST_PEER_NAME = 6,
}


[AllowDuplicates]
public enum PNRP_EXTENDED_PAYLOAD_TYPE : int32
{
	PNRP_EXTENDED_PAYLOAD_TYPE_NONE = 0,
	PNRP_EXTENDED_PAYLOAD_TYPE_BINARY = 1,
	PNRP_EXTENDED_PAYLOAD_TYPE_STRING = 2,
}


[AllowDuplicates]
public enum PEER_RECORD_CHANGE_TYPE : int32
{
	PEER_RECORD_ADDED = 1,
	PEER_RECORD_UPDATED = 2,
	PEER_RECORD_DELETED = 3,
	PEER_RECORD_EXPIRED = 4,
}


[AllowDuplicates]
public enum PEER_CONNECTION_STATUS : int32
{
	PEER_CONNECTED = 1,
	PEER_DISCONNECTED = 2,
	PEER_CONNECTION_FAILED = 3,
}


[AllowDuplicates]
public enum PEER_CONNECTION_FLAGS : int32
{
	PEER_CONNECTION_NEIGHBOR = 1,
	PEER_CONNECTION_DIRECT = 2,
}


[AllowDuplicates]
public enum PEER_RECORD_FLAGS : int32
{
	PEER_RECORD_FLAG_AUTOREFRESH = 1,
	PEER_RECORD_FLAG_DELETED = 2,
}


[AllowDuplicates]
public enum PEER_GRAPH_EVENT_TYPE : int32
{
	PEER_GRAPH_EVENT_STATUS_CHANGED = 1,
	PEER_GRAPH_EVENT_PROPERTY_CHANGED = 2,
	PEER_GRAPH_EVENT_RECORD_CHANGED = 3,
	PEER_GRAPH_EVENT_DIRECT_CONNECTION = 4,
	PEER_GRAPH_EVENT_NEIGHBOR_CONNECTION = 5,
	PEER_GRAPH_EVENT_INCOMING_DATA = 6,
	PEER_GRAPH_EVENT_CONNECTION_REQUIRED = 7,
	PEER_GRAPH_EVENT_NODE_CHANGED = 8,
	PEER_GRAPH_EVENT_SYNCHRONIZED = 9,
}


[AllowDuplicates]
public enum PEER_NODE_CHANGE_TYPE : int32
{
	PEER_NODE_CHANGE_CONNECTED = 1,
	PEER_NODE_CHANGE_DISCONNECTED = 2,
	PEER_NODE_CHANGE_UPDATED = 3,
}


[AllowDuplicates]
public enum PEER_GRAPH_STATUS_FLAGS : int32
{
	PEER_GRAPH_STATUS_LISTENING = 1,
	PEER_GRAPH_STATUS_HAS_CONNECTIONS = 2,
	PEER_GRAPH_STATUS_SYNCHRONIZED = 4,
}


[AllowDuplicates]
public enum PEER_GRAPH_PROPERTY_FLAGS : int32
{
	PEER_GRAPH_PROPERTY_HEARTBEATS = 1,
	PEER_GRAPH_PROPERTY_DEFER_EXPIRATION = 2,
}


[AllowDuplicates]
public enum PEER_GRAPH_SCOPE : int32
{
	PEER_GRAPH_SCOPE_ANY = 0,
	PEER_GRAPH_SCOPE_GLOBAL = 1,
	PEER_GRAPH_SCOPE_SITELOCAL = 2,
	PEER_GRAPH_SCOPE_LINKLOCAL = 3,
	PEER_GRAPH_SCOPE_LOOPBACK = 4,
}


[AllowDuplicates]
public enum PEER_GROUP_EVENT_TYPE : int32
{
	PEER_GROUP_EVENT_STATUS_CHANGED = 1,
	PEER_GROUP_EVENT_PROPERTY_CHANGED = 2,
	PEER_GROUP_EVENT_RECORD_CHANGED = 3,
	PEER_GROUP_EVENT_DIRECT_CONNECTION = 4,
	PEER_GROUP_EVENT_NEIGHBOR_CONNECTION = 5,
	PEER_GROUP_EVENT_INCOMING_DATA = 6,
	PEER_GROUP_EVENT_MEMBER_CHANGED = 8,
	PEER_GROUP_EVENT_CONNECTION_FAILED = 10,
	PEER_GROUP_EVENT_AUTHENTICATION_FAILED = 11,
}


[AllowDuplicates]
public enum PEER_GROUP_STATUS : int32
{
	PEER_GROUP_STATUS_LISTENING = 1,
	PEER_GROUP_STATUS_HAS_CONNECTIONS = 2,
}


[AllowDuplicates]
public enum PEER_GROUP_PROPERTY_FLAGS : int32
{
	PEER_MEMBER_DATA_OPTIONAL = 1,
	PEER_DISABLE_PRESENCE = 2,
	PEER_DEFER_EXPIRATION = 4,
}


[AllowDuplicates]
public enum PEER_GROUP_AUTHENTICATION_SCHEME : int32
{
	PEER_GROUP_GMC_AUTHENTICATION = 1,
	PEER_GROUP_PASSWORD_AUTHENTICATION = 2,
}


[AllowDuplicates]
public enum PEER_MEMBER_FLAGS : int32
{
	PEER_MEMBER_PRESENT = 1,
}


[AllowDuplicates]
public enum PEER_MEMBER_CHANGE_TYPE : int32
{
	PEER_MEMBER_CONNECTED = 1,
	PEER_MEMBER_DISCONNECTED = 2,
	PEER_MEMBER_UPDATED = 3,
	PEER_MEMBER_JOINED = 4,
	PEER_MEMBER_LEFT = 5,
}


[AllowDuplicates]
public enum PEER_GROUP_ISSUE_CREDENTIAL_FLAGS : int32
{
	PEER_GROUP_STORE_CREDENTIALS = 1,
}


[AllowDuplicates]
public enum PEER_SIGNIN_FLAGS : int32
{
	PEER_SIGNIN_NONE = 0,
	PEER_SIGNIN_NEAR_ME = 1,
	PEER_SIGNIN_INTERNET = 2,
	PEER_SIGNIN_ALL = 3,
}


[AllowDuplicates]
public enum PEER_WATCH_PERMISSION : int32
{
	PEER_WATCH_BLOCKED = 0,
	PEER_WATCH_ALLOWED = 1,
}


[AllowDuplicates]
public enum PEER_PUBLICATION_SCOPE : int32
{
	PEER_PUBLICATION_SCOPE_NONE = 0,
	PEER_PUBLICATION_SCOPE_NEAR_ME = 1,
	PEER_PUBLICATION_SCOPE_INTERNET = 2,
	PEER_PUBLICATION_SCOPE_ALL = 3,
}


[AllowDuplicates]
public enum PEER_INVITATION_RESPONSE_TYPE : int32
{
	PEER_INVITATION_RESPONSE_DECLINED = 0,
	PEER_INVITATION_RESPONSE_ACCEPTED = 1,
	PEER_INVITATION_RESPONSE_EXPIRED = 2,
	PEER_INVITATION_RESPONSE_ERROR = 3,
}


[AllowDuplicates]
public enum PEER_APPLICATION_REGISTRATION_TYPE : int32
{
	PEER_APPLICATION_CURRENT_USER = 0,
	PEER_APPLICATION_ALL_USERS = 1,
}


[AllowDuplicates]
public enum PEER_PRESENCE_STATUS : int32
{
	PEER_PRESENCE_OFFLINE = 0,
	PEER_PRESENCE_OUT_TO_LUNCH = 1,
	PEER_PRESENCE_AWAY = 2,
	PEER_PRESENCE_BE_RIGHT_BACK = 3,
	PEER_PRESENCE_IDLE = 4,
	PEER_PRESENCE_BUSY = 5,
	PEER_PRESENCE_ON_THE_PHONE = 6,
	PEER_PRESENCE_ONLINE = 7,
}


[AllowDuplicates]
public enum PEER_CHANGE_TYPE : int32
{
	PEER_CHANGE_ADDED = 0,
	PEER_CHANGE_DELETED = 1,
	PEER_CHANGE_UPDATED = 2,
}


[AllowDuplicates]
public enum PEER_COLLAB_EVENT_TYPE : int32
{
	PEER_EVENT_WATCHLIST_CHANGED = 1,
	PEER_EVENT_ENDPOINT_CHANGED = 2,
	PEER_EVENT_ENDPOINT_PRESENCE_CHANGED = 3,
	PEER_EVENT_ENDPOINT_APPLICATION_CHANGED = 4,
	PEER_EVENT_ENDPOINT_OBJECT_CHANGED = 5,
	PEER_EVENT_MY_ENDPOINT_CHANGED = 6,
	PEER_EVENT_MY_PRESENCE_CHANGED = 7,
	PEER_EVENT_MY_APPLICATION_CHANGED = 8,
	PEER_EVENT_MY_OBJECT_CHANGED = 9,
	PEER_EVENT_PEOPLE_NEAR_ME_CHANGED = 10,
	PEER_EVENT_REQUEST_STATUS_CHANGED = 11,
}


[AllowDuplicates]
public enum DRT_SCOPE : int32
{
	DRT_GLOBAL_SCOPE = 1,
	DRT_SITE_LOCAL_SCOPE = 2,
	DRT_LINK_LOCAL_SCOPE = 3,
}


[AllowDuplicates]
public enum DRT_STATUS : int32
{
	DRT_ACTIVE = 0,
	DRT_ALONE = 1,
	DRT_NO_NETWORK = 10,
	DRT_FAULTED = 20,
}


[AllowDuplicates]
public enum DRT_MATCH_TYPE : int32
{
	DRT_MATCH_EXACT = 0,
	DRT_MATCH_NEAR = 1,
	DRT_MATCH_INTERMEDIATE = 2,
}


[AllowDuplicates]
public enum DRT_LEAFSET_KEY_CHANGE_TYPE : int32
{
	DRT_LEAFSET_KEY_ADDED = 0,
	DRT_LEAFSET_KEY_DELETED = 1,
}


[AllowDuplicates]
public enum DRT_EVENT_TYPE : int32
{
	DRT_EVENT_STATUS_CHANGED = 0,
	DRT_EVENT_LEAFSET_KEY_CHANGED = 1,
	DRT_EVENT_REGISTRATION_STATE_CHANGED = 2,
}


[AllowDuplicates]
public enum DRT_SECURITY_MODE : int32
{
	DRT_SECURE_RESOLVE = 0,
	DRT_SECURE_MEMBERSHIP = 1,
	DRT_SECURE_CONFIDENTIALPAYLOAD = 2,
}


[AllowDuplicates]
public enum DRT_REGISTRATION_STATE : int32
{
	DRT_REGISTRATION_STATE_UNRESOLVEABLE = 1,
}


[AllowDuplicates]
public enum DRT_ADDRESS_FLAGS : int32
{
	DRT_ADDRESS_FLAG_ACCEPTED = 1,
	DRT_ADDRESS_FLAG_REJECTED = 2,
	DRT_ADDRESS_FLAG_UNREACHABLE = 4,
	DRT_ADDRESS_FLAG_LOOP = 8,
	DRT_ADDRESS_FLAG_TOO_BUSY = 16,
	DRT_ADDRESS_FLAG_BAD_VALIDATE_ID = 32,
	DRT_ADDRESS_FLAG_SUSPECT_UNREGISTERED_ID = 64,
	DRT_ADDRESS_FLAG_INQUIRE = 128,
}


[AllowDuplicates]
public enum PEERDIST_STATUS : int32
{
	PEERDIST_STATUS_DISABLED = 0,
	PEERDIST_STATUS_UNAVAILABLE = 1,
	PEERDIST_STATUS_AVAILABLE = 2,
}


[AllowDuplicates]
public enum PEERDIST_CLIENT_INFO_BY_HANDLE_CLASS : int32
{
	PeerDistClientBasicInfo = 0,
	MaximumPeerDistClientInfoByHandlesClass = 1,
}

#endregion

#region Function Pointers
public function HRESULT PFNPEER_VALIDATE_RECORD(void* hGraph, void* pvContext, PEER_RECORD* pRecord, PEER_RECORD_CHANGE_TYPE changeType);

public function HRESULT PFNPEER_SECURE_RECORD(void* hGraph, void* pvContext, PEER_RECORD* pRecord, PEER_RECORD_CHANGE_TYPE changeType, PEER_DATA** ppSecurityData);

public function HRESULT PFNPEER_FREE_SECURITY_DATA(void* hGraph, void* pvContext, PEER_DATA* pSecurityData);

public function HRESULT PFNPEER_ON_PASSWORD_AUTH_FAILED(void* hGraph, void* pvContext);

public function void DRT_BOOTSTRAP_RESOLVE_CALLBACK(HRESULT hr, void* pvContext, SOCKET_ADDRESS_LIST* pAddresses, BOOL fFatalError);

#endregion

#region Structs
[CRepr]
public struct PNRP_CLOUD_ID
{
	public int32 AddressFamily;
	public PNRP_SCOPE Scope;
	public uint32 ScopeId;
}

[CRepr]
public struct PNRPINFO_V1
{
	public uint32 dwSize;
	public PWSTR lpwszIdentity;
	public uint32 nMaxResolve;
	public uint32 dwTimeout;
	public uint32 dwLifetime;
	public PNRP_RESOLVE_CRITERIA enResolveCriteria;
	public uint32 dwFlags;
	public SOCKET_ADDRESS saHint;
	public PNRP_REGISTERED_ID_STATE enNameState;
}

[CRepr]
public struct PNRPINFO_V2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public BLOB blobPayload;
		public PWSTR pwszPayload;
	}
	public uint32 dwSize;
	public PWSTR lpwszIdentity;
	public uint32 nMaxResolve;
	public uint32 dwTimeout;
	public uint32 dwLifetime;
	public PNRP_RESOLVE_CRITERIA enResolveCriteria;
	public uint32 dwFlags;
	public SOCKET_ADDRESS saHint;
	public PNRP_REGISTERED_ID_STATE enNameState;
	public PNRP_EXTENDED_PAYLOAD_TYPE enExtendedPayloadType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PNRPCLOUDINFO
{
	public uint32 dwSize;
	public PNRP_CLOUD_ID Cloud;
	public PNRP_CLOUD_STATE enCloudState;
	public PNRP_CLOUD_FLAGS enCloudFlags;
}

[CRepr]
public struct PEER_VERSION_DATA
{
	public uint16 wVersion;
	public uint16 wHighestVersion;
}

[CRepr]
public struct PEER_DATA
{
	public uint32 cbData;
	public uint8* pbData;
}

[CRepr]
public struct PEER_RECORD
{
	public uint32 dwSize;
	public Guid type;
	public Guid id;
	public uint32 dwVersion;
	public uint32 dwFlags;
	public PWSTR pwzCreatorId;
	public PWSTR pwzModifiedById;
	public PWSTR pwzAttributes;
	public FILETIME ftCreation;
	public FILETIME ftExpiration;
	public FILETIME ftLastModified;
	public PEER_DATA securityData;
	public PEER_DATA data;
}

[CRepr]
public struct PEER_ADDRESS
{
	public uint32 dwSize;
	public SOCKADDR_IN6 sin6;
}

[CRepr]
public struct PEER_CONNECTION_INFO
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint64 ullConnectionId;
	public uint64 ullNodeId;
	public PWSTR pwzPeerId;
	public PEER_ADDRESS address;
}

[CRepr]
public struct PEER_EVENT_INCOMING_DATA
{
	public uint32 dwSize;
	public uint64 ullConnectionId;
	public Guid type;
	public PEER_DATA data;
}

[CRepr]
public struct PEER_EVENT_RECORD_CHANGE_DATA
{
	public uint32 dwSize;
	public PEER_RECORD_CHANGE_TYPE changeType;
	public Guid recordId;
	public Guid recordType;
}

[CRepr]
public struct PEER_EVENT_CONNECTION_CHANGE_DATA
{
	public uint32 dwSize;
	public PEER_CONNECTION_STATUS status;
	public uint64 ullConnectionId;
	public uint64 ullNodeId;
	public uint64 ullNextConnectionId;
	public HRESULT hrConnectionFailedReason;
}

[CRepr]
public struct PEER_EVENT_SYNCHRONIZED_DATA
{
	public uint32 dwSize;
	public Guid recordType;
}

[CRepr]
public struct PEER_GRAPH_PROPERTIES
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwScope;
	public uint32 dwMaxRecordSize;
	public PWSTR pwzGraphId;
	public PWSTR pwzCreatorId;
	public PWSTR pwzFriendlyName;
	public PWSTR pwzComment;
	public uint32 ulPresenceLifetime;
	public uint32 cPresenceMax;
}

[CRepr]
public struct PEER_NODE_INFO
{
	public uint32 dwSize;
	public uint64 ullNodeId;
	public PWSTR pwzPeerId;
	public uint32 cAddresses;
	public PEER_ADDRESS* pAddresses;
	public PWSTR pwzAttributes;
}

[CRepr]
public struct PEER_EVENT_NODE_CHANGE_DATA
{
	public uint32 dwSize;
	public PEER_NODE_CHANGE_TYPE changeType;
	public uint64 ullNodeId;
	public PWSTR pwzPeerId;
}

[CRepr]
public struct PEER_GRAPH_EVENT_REGISTRATION
{
	public PEER_GRAPH_EVENT_TYPE eventType;
	public Guid* pType;
}

[CRepr]
public struct PEER_GRAPH_EVENT_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PEER_GRAPH_STATUS_FLAGS dwStatus;
		public PEER_EVENT_INCOMING_DATA incomingData;
		public PEER_EVENT_RECORD_CHANGE_DATA recordChangeData;
		public PEER_EVENT_CONNECTION_CHANGE_DATA connectionChangeData;
		public PEER_EVENT_NODE_CHANGE_DATA nodeChangeData;
		public PEER_EVENT_SYNCHRONIZED_DATA synchronizedData;
	}
	public PEER_GRAPH_EVENT_TYPE eventType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PEER_SECURITY_INTERFACE
{
	public uint32 dwSize;
	public PWSTR pwzSspFilename;
	public PWSTR pwzPackageName;
	public uint32 cbSecurityInfo;
	public uint8* pbSecurityInfo;
	public void* pvContext;
	public PFNPEER_VALIDATE_RECORD pfnValidateRecord;
	public PFNPEER_SECURE_RECORD pfnSecureRecord;
	public PFNPEER_FREE_SECURITY_DATA pfnFreeSecurityData;
	public PFNPEER_ON_PASSWORD_AUTH_FAILED pfnAuthFailed;
}

[CRepr]
public struct PEER_CREDENTIAL_INFO
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PWSTR pwzFriendlyName;
	public CERT_PUBLIC_KEY_INFO* pPublicKey;
	public PWSTR pwzIssuerPeerName;
	public PWSTR pwzIssuerFriendlyName;
	public FILETIME ftValidityStart;
	public FILETIME ftValidityEnd;
	public uint32 cRoles;
	public Guid* pRoles;
}

[CRepr]
public struct PEER_MEMBER
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PWSTR pwzIdentity;
	public PWSTR pwzAttributes;
	public uint64 ullNodeId;
	public uint32 cAddresses;
	public PEER_ADDRESS* pAddresses;
	public PEER_CREDENTIAL_INFO* pCredentialInfo;
}

[CRepr]
public struct PEER_INVITATION_INFO
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PWSTR pwzCloudName;
	public uint32 dwScope;
	public uint32 dwCloudFlags;
	public PWSTR pwzGroupPeerName;
	public PWSTR pwzIssuerPeerName;
	public PWSTR pwzSubjectPeerName;
	public PWSTR pwzGroupFriendlyName;
	public PWSTR pwzIssuerFriendlyName;
	public PWSTR pwzSubjectFriendlyName;
	public FILETIME ftValidityStart;
	public FILETIME ftValidityEnd;
	public uint32 cRoles;
	public Guid* pRoles;
	public uint32 cClassifiers;
	public PWSTR* ppwzClassifiers;
	public CERT_PUBLIC_KEY_INFO* pSubjectPublicKey;
	public PEER_GROUP_AUTHENTICATION_SCHEME authScheme;
}

[CRepr]
public struct PEER_GROUP_PROPERTIES
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PWSTR pwzCloud;
	public PWSTR pwzClassifier;
	public PWSTR pwzGroupPeerName;
	public PWSTR pwzCreatorPeerName;
	public PWSTR pwzFriendlyName;
	public PWSTR pwzComment;
	public uint32 ulMemberDataLifetime;
	public uint32 ulPresenceLifetime;
	public uint32 dwAuthenticationSchemes;
	public PWSTR pwzGroupPassword;
	public Guid groupPasswordRole;
}

[CRepr]
public struct PEER_EVENT_MEMBER_CHANGE_DATA
{
	public uint32 dwSize;
	public PEER_MEMBER_CHANGE_TYPE changeType;
	public PWSTR pwzIdentity;
}

[CRepr]
public struct PEER_GROUP_EVENT_REGISTRATION
{
	public PEER_GROUP_EVENT_TYPE eventType;
	public Guid* pType;
}

[CRepr]
public struct PEER_GROUP_EVENT_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PEER_GROUP_STATUS dwStatus;
		public PEER_EVENT_INCOMING_DATA incomingData;
		public PEER_EVENT_RECORD_CHANGE_DATA recordChangeData;
		public PEER_EVENT_CONNECTION_CHANGE_DATA connectionChangeData;
		public PEER_EVENT_MEMBER_CHANGE_DATA memberChangeData;
		public HRESULT hrConnectionFailedReason;
	}
	public PEER_GROUP_EVENT_TYPE eventType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PEER_NAME_PAIR
{
	public uint32 dwSize;
	public PWSTR pwzPeerName;
	public PWSTR pwzFriendlyName;
}

[CRepr]
public struct PEER_APPLICATION
{
	public Guid id;
	public PEER_DATA data;
	public PWSTR pwzDescription;
}

[CRepr]
public struct PEER_OBJECT
{
	public Guid id;
	public PEER_DATA data;
	public uint32 dwPublicationScope;
}

[CRepr]
public struct PEER_CONTACT
{
	public PWSTR pwzPeerName;
	public PWSTR pwzNickName;
	public PWSTR pwzDisplayName;
	public PWSTR pwzEmailAddress;
	public BOOL fWatch;
	public PEER_WATCH_PERMISSION WatcherPermissions;
	public PEER_DATA credentials;
}

[CRepr]
public struct PEER_ENDPOINT
{
	public PEER_ADDRESS address;
	public PWSTR pwzEndpointName;
}

[CRepr]
public struct PEER_PEOPLE_NEAR_ME
{
	public PWSTR pwzNickName;
	public PEER_ENDPOINT endpoint;
	public Guid id;
}

[CRepr]
public struct PEER_INVITATION
{
	public Guid applicationId;
	public PEER_DATA applicationData;
	public PWSTR pwzMessage;
}

[CRepr]
public struct PEER_INVITATION_RESPONSE
{
	public PEER_INVITATION_RESPONSE_TYPE action;
	public PWSTR pwzMessage;
	public HRESULT hrExtendedInfo;
}

[CRepr]
public struct PEER_APP_LAUNCH_INFO
{
	public PEER_CONTACT* pContact;
	public PEER_ENDPOINT* pEndpoint;
	public PEER_INVITATION* pInvitation;
}

[CRepr]
public struct PEER_APPLICATION_REGISTRATION_INFO
{
	public PEER_APPLICATION application;
	public PWSTR pwzApplicationToLaunch;
	public PWSTR pwzApplicationArguments;
	public uint32 dwPublicationScope;
}

[CRepr]
public struct PEER_PRESENCE_INFO
{
	public PEER_PRESENCE_STATUS status;
	public PWSTR pwzDescriptiveText;
}

[CRepr]
public struct PEER_COLLAB_EVENT_REGISTRATION
{
	public PEER_COLLAB_EVENT_TYPE eventType;
	public Guid* pInstance;
}

[CRepr]
public struct PEER_EVENT_WATCHLIST_CHANGED_DATA
{
	public PEER_CONTACT* pContact;
	public PEER_CHANGE_TYPE changeType;
}

[CRepr]
public struct PEER_EVENT_PRESENCE_CHANGED_DATA
{
	public PEER_CONTACT* pContact;
	public PEER_ENDPOINT* pEndpoint;
	public PEER_CHANGE_TYPE changeType;
	public PEER_PRESENCE_INFO* pPresenceInfo;
}

[CRepr]
public struct PEER_EVENT_APPLICATION_CHANGED_DATA
{
	public PEER_CONTACT* pContact;
	public PEER_ENDPOINT* pEndpoint;
	public PEER_CHANGE_TYPE changeType;
	public PEER_APPLICATION* pApplication;
}

[CRepr]
public struct PEER_EVENT_OBJECT_CHANGED_DATA
{
	public PEER_CONTACT* pContact;
	public PEER_ENDPOINT* pEndpoint;
	public PEER_CHANGE_TYPE changeType;
	public PEER_OBJECT* pObject;
}

[CRepr]
public struct PEER_EVENT_ENDPOINT_CHANGED_DATA
{
	public PEER_CONTACT* pContact;
	public PEER_ENDPOINT* pEndpoint;
}

[CRepr]
public struct PEER_EVENT_PEOPLE_NEAR_ME_CHANGED_DATA
{
	public PEER_CHANGE_TYPE changeType;
	public PEER_PEOPLE_NEAR_ME* pPeopleNearMe;
}

[CRepr]
public struct PEER_EVENT_REQUEST_STATUS_CHANGED_DATA
{
	public PEER_ENDPOINT* pEndpoint;
	public HRESULT hrChange;
}

[CRepr]
public struct PEER_COLLAB_EVENT_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PEER_EVENT_WATCHLIST_CHANGED_DATA watchListChangedData;
		public PEER_EVENT_PRESENCE_CHANGED_DATA presenceChangedData;
		public PEER_EVENT_APPLICATION_CHANGED_DATA applicationChangedData;
		public PEER_EVENT_OBJECT_CHANGED_DATA objectChangedData;
		public PEER_EVENT_ENDPOINT_CHANGED_DATA endpointChangedData;
		public PEER_EVENT_PEOPLE_NEAR_ME_CHANGED_DATA peopleNearMeChangedData;
		public PEER_EVENT_REQUEST_STATUS_CHANGED_DATA requestStatusChangedData;
	}
	public PEER_COLLAB_EVENT_TYPE eventType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PEER_PNRP_ENDPOINT_INFO
{
	public PWSTR pwzPeerName;
	public uint32 cAddresses;
	public SOCKADDR** ppAddresses;
	public PWSTR pwzComment;
	public PEER_DATA payload;
}

[CRepr]
public struct PEER_PNRP_CLOUD_INFO
{
	public PWSTR pwzCloudName;
	public PNRP_SCOPE dwScope;
	public uint32 dwScopeId;
}

[CRepr]
public struct PEER_PNRP_REGISTRATION_INFO
{
	public PWSTR pwzCloudName;
	public PWSTR pwzPublishingIdentity;
	public uint32 cAddresses;
	public SOCKADDR** ppAddresses;
	public uint16 wPort;
	public PWSTR pwzComment;
	public PEER_DATA payload;
}

[CRepr]
public struct DRT_DATA
{
	public uint32 cb;
	public uint8* pb;
}

[CRepr]
public struct DRT_REGISTRATION
{
	public DRT_DATA key;
	public DRT_DATA appData;
}

[CRepr]
public struct DRT_SECURITY_PROVIDER
{
	public void* pvContext;
	public int Attach;
	public int Detach;
	public int RegisterKey;
	public int UnregisterKey;
	public int ValidateAndUnpackPayload;
	public int SecureAndPackPayload;
	public int FreeData;
	public int EncryptData;
	public int DecryptData;
	public int GetSerializedCredential;
	public int ValidateRemoteCredential;
	public int SignData;
	public int VerifyData;
}

[CRepr]
public struct DRT_BOOTSTRAP_PROVIDER
{
	public void* pvContext;
	public int Attach;
	public int Detach;
	public int InitResolve;
	public int IssueResolve;
	public int EndResolve;
	public int Register;
	public int Unregister;
}

[CRepr]
public struct DRT_SETTINGS
{
	public uint32 dwSize;
	public uint32 cbKey;
	public uint8 bProtocolMajorVersion;
	public uint8 bProtocolMinorVersion;
	public uint32 ulMaxRoutingAddresses;
	public PWSTR pwzDrtInstancePrefix;
	public void* hTransport;
	public DRT_SECURITY_PROVIDER* pSecurityProvider;
	public DRT_BOOTSTRAP_PROVIDER* pBootstrapProvider;
	public DRT_SECURITY_MODE eSecurityMode;
}

[CRepr]
public struct DRT_SEARCH_INFO
{
	public uint32 dwSize;
	public BOOL fIterative;
	public BOOL fAllowCurrentInstanceMatch;
	public BOOL fAnyMatchInRange;
	public uint32 cMaxEndpoints;
	public DRT_DATA* pMaximumKey;
	public DRT_DATA* pMinimumKey;
}

[CRepr]
public struct DRT_ADDRESS
{
	public SOCKADDR_STORAGE socketAddress;
	public uint32 flags;
	public int32 nearness;
	public uint32 latency;
}

[CRepr]
public struct DRT_ADDRESS_LIST
{
	public uint32 AddressCount;
	public DRT_ADDRESS* AddressList mut => &AddressList_impl;
	private DRT_ADDRESS[ANYSIZE_ARRAY] AddressList_impl;
}

[CRepr]
public struct DRT_SEARCH_RESULT
{
	public uint32 dwSize;
	public DRT_MATCH_TYPE type;
	public void* pvContext;
	public DRT_REGISTRATION registration;
}

[CRepr]
public struct DRT_EVENT_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _statusChange_e__Struct
		{
			[CRepr]
			public struct _bootstrapAddresses_e__Struct
			{
				public uint32 cntAddress;
				public SOCKADDR_STORAGE* pAddresses;
			}
			public DRT_STATUS status;
			public _bootstrapAddresses_e__Struct bootstrapAddresses;
		}
		[CRepr]
		public struct _leafsetKeyChange_e__Struct
		{
			public DRT_LEAFSET_KEY_CHANGE_TYPE change;
			public DRT_DATA localKey;
			public DRT_DATA remoteKey;
		}
		[CRepr]
		public struct _registrationStateChange_e__Struct
		{
			public DRT_REGISTRATION_STATE state;
			public DRT_DATA localKey;
		}
		public _leafsetKeyChange_e__Struct leafsetKeyChange;
		public _registrationStateChange_e__Struct registrationStateChange;
		public _statusChange_e__Struct statusChange;
	}
	public DRT_EVENT_TYPE type;
	public HRESULT hr;
	public void* pvContext;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PEERDIST_PUBLICATION_OPTIONS
{
	public uint32 dwVersion;
	public uint32 dwFlags;
}

[CRepr]
public struct PEERDIST_CONTENT_TAG
{
	public uint8[16] Data;
}

[CRepr]
public struct PEERDIST_RETRIEVAL_OPTIONS
{
	public uint32 cbSize;
	public uint32 dwContentInfoMinVersion;
	public uint32 dwContentInfoMaxVersion;
	public uint32 dwReserved;
}

[CRepr]
public struct PEERDIST_STATUS_INFO
{
	public uint32 cbSize;
	public PEERDIST_STATUS status;
	public PEERDIST_RETRIEVAL_OPTIONS_CONTENTINFO_VERSION_VALUE dwMinVer;
	public PEERDIST_RETRIEVAL_OPTIONS_CONTENTINFO_VERSION_VALUE dwMaxVer;
}

[CRepr]
public struct PEERDIST_CLIENT_BASIC_INFO
{
	public BOOL fFlashCrowd;
}

#endregion

#region Functions
public static
{
	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphStartup(uint16 wVersionRequested, PEER_VERSION_DATA* pVersionData);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphShutdown();

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PeerGraphFreeData(void* pvData);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphGetItemCount(void* hPeerEnum, uint32* pCount);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphGetNextItem(void* hPeerEnum, uint32* pCount, void*** pppvItems);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphEndEnumeration(void* hPeerEnum);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphCreate(PEER_GRAPH_PROPERTIES* pGraphProperties, PWSTR pwzDatabaseName, PEER_SECURITY_INTERFACE* pSecurityInterface, void** phGraph);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphOpen(PWSTR pwzGraphId, PWSTR pwzPeerId, PWSTR pwzDatabaseName, PEER_SECURITY_INTERFACE* pSecurityInterface, uint32 cRecordTypeSyncPrecedence, Guid* pRecordTypeSyncPrecedence, void** phGraph);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphListen(void* hGraph, uint32 dwScope, uint32 dwScopeId, uint16 wPort);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphConnect(void* hGraph, PWSTR pwzPeerId, PEER_ADDRESS* pAddress, uint64* pullConnectionId);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphClose(void* hGraph);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphDelete(PWSTR pwzGraphId, PWSTR pwzPeerId, PWSTR pwzDatabaseName);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphGetStatus(void* hGraph, uint32* pdwStatus);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphGetProperties(void* hGraph, PEER_GRAPH_PROPERTIES** ppGraphProperties);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphSetProperties(void* hGraph, PEER_GRAPH_PROPERTIES* pGraphProperties);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphRegisterEvent(void* hGraph, HANDLE hEvent, uint32 cEventRegistrations, PEER_GRAPH_EVENT_REGISTRATION* pEventRegistrations, void** phPeerEvent);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphUnregisterEvent(void* hPeerEvent);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphGetEventData(void* hPeerEvent, PEER_GRAPH_EVENT_DATA** ppEventData);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphGetRecord(void* hGraph, in Guid pRecordId, PEER_RECORD** ppRecord);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphAddRecord(void* hGraph, PEER_RECORD* pRecord, Guid* pRecordId);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphUpdateRecord(void* hGraph, PEER_RECORD* pRecord);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphDeleteRecord(void* hGraph, in Guid pRecordId, BOOL fLocal);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphEnumRecords(void* hGraph, Guid* pRecordType, PWSTR pwzPeerId, void** phPeerEnum);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphSearchRecords(void* hGraph, PWSTR pwzCriteria, void** phPeerEnum);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphExportDatabase(void* hGraph, PWSTR pwzFilePath);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphImportDatabase(void* hGraph, PWSTR pwzFilePath);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphValidateDeferredRecords(void* hGraph, uint32 cRecordIds, Guid* pRecordIds);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphOpenDirectConnection(void* hGraph, PWSTR pwzPeerId, PEER_ADDRESS* pAddress, uint64* pullConnectionId);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphSendData(void* hGraph, uint64 ullConnectionId, in Guid pType, uint32 cbData, void* pvData);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphCloseDirectConnection(void* hGraph, uint64 ullConnectionId);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphEnumConnections(void* hGraph, uint32 dwFlags, void** phPeerEnum);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphEnumNodes(void* hGraph, PWSTR pwzPeerId, void** phPeerEnum);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphSetPresence(void* hGraph, BOOL fPresent);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphGetNodeInfo(void* hGraph, uint64 ullNodeId, PEER_NODE_INFO** ppNodeInfo);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphSetNodeAttributes(void* hGraph, PWSTR pwzAttributes);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphPeerTimeToUniversalTime(void* hGraph, FILETIME* pftPeerTime, FILETIME* pftUniversalTime);

	[Import("P2PGRAPH.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGraphUniversalTimeToPeerTime(void* hGraph, FILETIME* pftUniversalTime, FILETIME* pftPeerTime);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PeerFreeData(void* pvData);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGetItemCount(void* hPeerEnum, uint32* pCount);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGetNextItem(void* hPeerEnum, uint32* pCount, void*** pppvItems);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerEndEnumeration(void* hPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupStartup(uint16 wVersionRequested, PEER_VERSION_DATA* pVersionData);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupShutdown();

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupCreate(PEER_GROUP_PROPERTIES* pProperties, void** phGroup);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupOpen(PWSTR pwzIdentity, PWSTR pwzGroupPeerName, PWSTR pwzCloud, void** phGroup);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupJoin(PWSTR pwzIdentity, PWSTR pwzInvitation, PWSTR pwzCloud, void** phGroup);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupPasswordJoin(PWSTR pwzIdentity, PWSTR pwzInvitation, PWSTR pwzPassword, PWSTR pwzCloud, void** phGroup);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupConnect(void* hGroup);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupConnectByAddress(void* hGroup, uint32 cAddresses, PEER_ADDRESS* pAddresses);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupClose(void* hGroup);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupDelete(PWSTR pwzIdentity, PWSTR pwzGroupPeerName);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupCreateInvitation(void* hGroup, PWSTR pwzIdentityInfo, FILETIME* pftExpiration, uint32 cRoles, Guid* pRoles, PWSTR* ppwzInvitation);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupCreatePasswordInvitation(void* hGroup, PWSTR* ppwzInvitation);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupParseInvitation(PWSTR pwzInvitation, PEER_INVITATION_INFO** ppInvitationInfo);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupGetStatus(void* hGroup, uint32* pdwStatus);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupGetProperties(void* hGroup, PEER_GROUP_PROPERTIES** ppProperties);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupSetProperties(void* hGroup, PEER_GROUP_PROPERTIES* pProperties);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupEnumMembers(void* hGroup, uint32 dwFlags, PWSTR pwzIdentity, void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupOpenDirectConnection(void* hGroup, PWSTR pwzIdentity, PEER_ADDRESS* pAddress, uint64* pullConnectionId);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupCloseDirectConnection(void* hGroup, uint64 ullConnectionId);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupEnumConnections(void* hGroup, uint32 dwFlags, void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupSendData(void* hGroup, uint64 ullConnectionId, in Guid pType, uint32 cbData, void* pvData);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupRegisterEvent(void* hGroup, HANDLE hEvent, uint32 cEventRegistration, PEER_GROUP_EVENT_REGISTRATION* pEventRegistrations, void** phPeerEvent);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupUnregisterEvent(void* hPeerEvent);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupGetEventData(void* hPeerEvent, PEER_GROUP_EVENT_DATA** ppEventData);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupGetRecord(void* hGroup, in Guid pRecordId, PEER_RECORD** ppRecord);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupAddRecord(void* hGroup, PEER_RECORD* pRecord, Guid* pRecordId);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupUpdateRecord(void* hGroup, PEER_RECORD* pRecord);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupDeleteRecord(void* hGroup, in Guid pRecordId);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupEnumRecords(void* hGroup, Guid* pRecordType, void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupSearchRecords(void* hGroup, PWSTR pwzCriteria, void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupExportDatabase(void* hGroup, PWSTR pwzFilePath);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupImportDatabase(void* hGroup, PWSTR pwzFilePath);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupIssueCredentials(void* hGroup, PWSTR pwzSubjectIdentity, PEER_CREDENTIAL_INFO* pCredentialInfo, uint32 dwFlags, PWSTR* ppwzInvitation);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupExportConfig(void* hGroup, PWSTR pwzPassword, PWSTR* ppwzXML);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupImportConfig(PWSTR pwzXML, PWSTR pwzPassword, BOOL fOverwrite, PWSTR* ppwzIdentity, PWSTR* ppwzGroup);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupPeerTimeToUniversalTime(void* hGroup, FILETIME* pftPeerTime, FILETIME* pftUniversalTime);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupUniversalTimeToPeerTime(void* hGroup, FILETIME* pftUniversalTime, FILETIME* pftPeerTime);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerGroupResumePasswordAuthentication(void* hGroup, void* hPeerEventHandle);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerIdentityCreate(PWSTR pwzClassifier, PWSTR pwzFriendlyName, uint hCryptProv, PWSTR* ppwzIdentity);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerIdentityGetFriendlyName(PWSTR pwzIdentity, PWSTR* ppwzFriendlyName);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerIdentitySetFriendlyName(PWSTR pwzIdentity, PWSTR pwzFriendlyName);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerIdentityGetCryptKey(PWSTR pwzIdentity, uint* phCryptProv);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerIdentityDelete(PWSTR pwzIdentity);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerEnumIdentities(void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerEnumGroups(PWSTR pwzIdentity, void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCreatePeerName(PWSTR pwzIdentity, PWSTR pwzClassifier, PWSTR* ppwzPeerName);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerIdentityGetXML(PWSTR pwzIdentity, PWSTR* ppwzIdentityXML);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerIdentityExport(PWSTR pwzIdentity, PWSTR pwzPassword, PWSTR* ppwzExportXML);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerIdentityImport(PWSTR pwzImportXML, PWSTR pwzPassword, PWSTR* ppwzIdentity);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerIdentityGetDefault(PWSTR* ppwzPeerName);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabStartup(uint16 wVersionRequested);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabShutdown();

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabSignin(HWND hwndParent, uint32 dwSigninOptions);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabSignout(uint32 dwSigninOptions);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabGetSigninOptions(uint32* pdwSigninOptions);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabAsyncInviteContact(PEER_CONTACT* pcContact, PEER_ENDPOINT* pcEndpoint, PEER_INVITATION* pcInvitation, HANDLE hEvent, HANDLE* phInvitation);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabGetInvitationResponse(HANDLE hInvitation, PEER_INVITATION_RESPONSE** ppInvitationResponse);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabCancelInvitation(HANDLE hInvitation);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabCloseHandle(HANDLE hInvitation);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabInviteContact(PEER_CONTACT* pcContact, PEER_ENDPOINT* pcEndpoint, PEER_INVITATION* pcInvitation, PEER_INVITATION_RESPONSE** ppResponse);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabAsyncInviteEndpoint(PEER_ENDPOINT* pcEndpoint, PEER_INVITATION* pcInvitation, HANDLE hEvent, HANDLE* phInvitation);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabInviteEndpoint(PEER_ENDPOINT* pcEndpoint, PEER_INVITATION* pcInvitation, PEER_INVITATION_RESPONSE** ppResponse);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabGetAppLaunchInfo(PEER_APP_LAUNCH_INFO** ppLaunchInfo);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabRegisterApplication(PEER_APPLICATION_REGISTRATION_INFO* pcApplication, PEER_APPLICATION_REGISTRATION_TYPE registrationType);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabUnregisterApplication(in Guid pApplicationId, PEER_APPLICATION_REGISTRATION_TYPE registrationType);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabGetApplicationRegistrationInfo(in Guid pApplicationId, PEER_APPLICATION_REGISTRATION_TYPE registrationType, PEER_APPLICATION_REGISTRATION_INFO** ppApplication);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabEnumApplicationRegistrationInfo(PEER_APPLICATION_REGISTRATION_TYPE registrationType, void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabGetPresenceInfo(PEER_ENDPOINT* pcEndpoint, PEER_PRESENCE_INFO** ppPresenceInfo);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabEnumApplications(PEER_ENDPOINT* pcEndpoint, Guid* pApplicationId, void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabEnumObjects(PEER_ENDPOINT* pcEndpoint, Guid* pObjectId, void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabEnumEndpoints(PEER_CONTACT* pcContact, void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabRefreshEndpointData(PEER_ENDPOINT* pcEndpoint);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabDeleteEndpointData(PEER_ENDPOINT* pcEndpoint);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabQueryContactData(PEER_ENDPOINT* pcEndpoint, PWSTR* ppwzContactData);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabSubscribeEndpointData(PEER_ENDPOINT* pcEndpoint);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabUnsubscribeEndpointData(PEER_ENDPOINT* pcEndpoint);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabSetPresenceInfo(PEER_PRESENCE_INFO* pcPresenceInfo);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabGetEndpointName(PWSTR* ppwzEndpointName);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabSetEndpointName(PWSTR pwzEndpointName);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabSetObject(PEER_OBJECT* pcObject);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabDeleteObject(in Guid pObjectId);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabRegisterEvent(HANDLE hEvent, uint32 cEventRegistration, PEER_COLLAB_EVENT_REGISTRATION* pEventRegistrations, void** phPeerEvent);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabGetEventData(void* hPeerEvent, PEER_COLLAB_EVENT_DATA** ppEventData);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabUnregisterEvent(void* hPeerEvent);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabEnumPeopleNearMe(void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabAddContact(PWSTR pwzContactData, PEER_CONTACT** ppContact);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabDeleteContact(PWSTR pwzPeerName);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabGetContact(PWSTR pwzPeerName, PEER_CONTACT** ppContact);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabUpdateContact(PEER_CONTACT* pContact);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabEnumContacts(void** phPeerEnum);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabExportContact(PWSTR pwzPeerName, PWSTR* ppwzContactData);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerCollabParseContact(PWSTR pwzContactData, PEER_CONTACT** ppContact);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerNameToPeerHostName(PWSTR pwzPeerName, PWSTR* ppwzHostName);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerHostNameToPeerName(PWSTR pwzHostName, PWSTR* ppwzPeerName);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerPnrpStartup(uint16 wVersionRequested);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerPnrpShutdown();

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerPnrpRegister(PWSTR pcwzPeerName, PEER_PNRP_REGISTRATION_INFO* pRegistrationInfo, void** phRegistration);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerPnrpUpdateRegistration(void* hRegistration, PEER_PNRP_REGISTRATION_INFO* pRegistrationInfo);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerPnrpUnregister(void* hRegistration);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerPnrpResolve(PWSTR pcwzPeerName, PWSTR pcwzCloudName, uint32* pcEndpoints, PEER_PNRP_ENDPOINT_INFO** ppEndpoints);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerPnrpStartResolve(PWSTR pcwzPeerName, PWSTR pcwzCloudName, uint32 cMaxEndpoints, HANDLE hEvent, void** phResolve);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerPnrpGetCloudInfo(uint32* pcNumClouds, PEER_PNRP_CLOUD_INFO** ppCloudInfo);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerPnrpGetEndpoint(void* hResolve, PEER_PNRP_ENDPOINT_INFO** ppEndpoint);

	[Import("P2P.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PeerPnrpEndResolve(void* hResolve);

	[Import("drtprov.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtCreatePnrpBootstrapResolver(BOOL fPublish, PWSTR pwzPeerName, PWSTR pwzCloudName, PWSTR pwzPublishingIdentity, DRT_BOOTSTRAP_PROVIDER** ppResolver);

	[Import("drtprov.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DrtDeletePnrpBootstrapResolver(DRT_BOOTSTRAP_PROVIDER* pResolver);

	[Import("drtprov.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtCreateDnsBootstrapResolver(uint16 port, PWSTR pwszAddress, DRT_BOOTSTRAP_PROVIDER** ppModule);

	[Import("drtprov.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DrtDeleteDnsBootstrapResolver(DRT_BOOTSTRAP_PROVIDER* pResolver);

	[Import("drttransport.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtCreateIpv6UdpTransport(DRT_SCOPE @scope, uint32 dwScopeId, uint32 dwLocalityThreshold, uint16* pwPort, void** phTransport);

	[Import("drttransport.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtDeleteIpv6UdpTransport(void* hTransport);

	[Import("drtprov.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtCreateDerivedKeySecurityProvider(CERT_CONTEXT* pRootCert, CERT_CONTEXT* pLocalCert, DRT_SECURITY_PROVIDER** ppSecurityProvider);

	[Import("drtprov.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtCreateDerivedKey(CERT_CONTEXT* pLocalCert, DRT_DATA* pKey);

	[Import("drtprov.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DrtDeleteDerivedKeySecurityProvider(DRT_SECURITY_PROVIDER* pSecurityProvider);

	[Import("drtprov.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtCreateNullSecurityProvider(DRT_SECURITY_PROVIDER** ppSecurityProvider);

	[Import("drtprov.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DrtDeleteNullSecurityProvider(DRT_SECURITY_PROVIDER* pSecurityProvider);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtOpen(DRT_SETTINGS* pSettings, HANDLE hEvent, void* pvContext, void** phDrt);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DrtClose(void* hDrt);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtGetEventDataSize(void* hDrt, uint32* pulEventDataLen);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtGetEventData(void* hDrt, uint32 ulEventDataLen, DRT_EVENT_DATA* pEventData);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtRegisterKey(void* hDrt, DRT_REGISTRATION* pRegistration, void* pvKeyContext, void** phKeyRegistration);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtUpdateKey(void* hKeyRegistration, DRT_DATA* pAppData);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DrtUnregisterKey(void* hKeyRegistration);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtStartSearch(void* hDrt, DRT_DATA* pKey, DRT_SEARCH_INFO* pInfo, uint32 timeout, HANDLE hEvent, void* pvContext, void** hSearchContext);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtContinueSearch(void* hSearchContext);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtGetSearchResultSize(void* hSearchContext, uint32* pulSearchResultSize);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtGetSearchResult(void* hSearchContext, uint32 ulSearchResultSize, DRT_SEARCH_RESULT* pSearchResult);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtGetSearchPathSize(void* hSearchContext, uint32* pulSearchPathSize);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtGetSearchPath(void* hSearchContext, uint32 ulSearchPathSize, DRT_ADDRESS_LIST* pSearchPath);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtEndSearch(void* hSearchContext);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtGetInstanceName(void* hDrt, uint32 ulcbInstanceNameSize, PWSTR pwzDrtInstanceName);

	[Import("drt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DrtGetInstanceNameSize(void* hDrt, uint32* pulcbInstanceNameSize);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistStartup(uint32 dwVersionRequested, int* phPeerDist, uint32* pdwSupportedVersion);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistShutdown(int hPeerDist);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistGetStatus(int hPeerDist, PEERDIST_STATUS* pPeerDistStatus);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistRegisterForStatusChangeNotification(int hPeerDist, HANDLE hCompletionPort, uint ulCompletionKey, OVERLAPPED* lpOverlapped, PEERDIST_STATUS* pPeerDistStatus);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistUnregisterForStatusChangeNotification(int hPeerDist);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistServerPublishStream(int hPeerDist, uint32 cbContentIdentifier, uint8* pContentIdentifier, uint64 cbContentLength, PEERDIST_PUBLICATION_OPTIONS* pPublishOptions, HANDLE hCompletionPort, uint ulCompletionKey, int* phStream);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistServerPublishAddToStream(int hPeerDist, int hStream, uint32 cbNumberOfBytes, uint8* pBuffer, OVERLAPPED* lpOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistServerPublishCompleteStream(int hPeerDist, int hStream, OVERLAPPED* lpOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistServerCloseStreamHandle(int hPeerDist, int hStream);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistServerUnpublish(int hPeerDist, uint32 cbContentIdentifier, uint8* pContentIdentifier);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistServerOpenContentInformation(int hPeerDist, uint32 cbContentIdentifier, uint8* pContentIdentifier, uint64 ullContentOffset, uint64 cbContentLength, HANDLE hCompletionPort, uint ulCompletionKey, int* phContentInfo);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistServerRetrieveContentInformation(int hPeerDist, int hContentInfo, uint32 cbMaxNumberOfBytes, uint8* pBuffer, OVERLAPPED* lpOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistServerCloseContentInformation(int hPeerDist, int hContentInfo);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistServerCancelAsyncOperation(int hPeerDist, uint32 cbContentIdentifier, uint8* pContentIdentifier, OVERLAPPED* pOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistClientOpenContent(int hPeerDist, PEERDIST_CONTENT_TAG* pContentTag, HANDLE hCompletionPort, uint ulCompletionKey, int* phContentHandle);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistClientCloseContent(int hPeerDist, int hContentHandle);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistClientAddContentInformation(int hPeerDist, int hContentHandle, uint32 cbNumberOfBytes, uint8* pBuffer, OVERLAPPED* lpOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistClientCompleteContentInformation(int hPeerDist, int hContentHandle, OVERLAPPED* lpOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistClientAddData(int hPeerDist, int hContentHandle, uint32 cbNumberOfBytes, uint8* pBuffer, OVERLAPPED* lpOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistClientBlockRead(int hPeerDist, int hContentHandle, uint32 cbMaxNumberOfBytes, uint8* pBuffer, uint32 dwTimeoutInMilliseconds, OVERLAPPED* lpOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistClientStreamRead(int hPeerDist, int hContentHandle, uint32 cbMaxNumberOfBytes, uint8* pBuffer, uint32 dwTimeoutInMilliseconds, OVERLAPPED* lpOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistClientFlushContent(int hPeerDist, PEERDIST_CONTENT_TAG* pContentTag, HANDLE hCompletionPort, uint ulCompletionKey, OVERLAPPED* lpOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistClientCancelAsyncOperation(int hPeerDist, int hContentHandle, OVERLAPPED* pOverlapped);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistGetStatusEx(int hPeerDist, PEERDIST_STATUS_INFO* pPeerDistStatus);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistRegisterForStatusChangeNotificationEx(int hPeerDist, HANDLE hCompletionPort, uint ulCompletionKey, OVERLAPPED* lpOverlapped, PEERDIST_STATUS_INFO* pPeerDistStatus);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PeerDistGetOverlappedResult(OVERLAPPED* lpOverlapped, uint32* lpNumberOfBytesTransferred, BOOL bWait);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistServerOpenContentInformationEx(int hPeerDist, uint32 cbContentIdentifier, uint8* pContentIdentifier, uint64 ullContentOffset, uint64 cbContentLength, PEERDIST_RETRIEVAL_OPTIONS* pRetrievalOptions, HANDLE hCompletionPort, uint ulCompletionKey, int* phContentInfo);

	[Import("PeerDist.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PeerDistClientGetInformationByHandle(int hPeerDist, int hContentHandle, PEERDIST_CLIENT_INFO_BY_HANDLE_CLASS PeerDistClientInfoClass, uint32 dwBufferSize, void* lpInformation);

}
#endregion
