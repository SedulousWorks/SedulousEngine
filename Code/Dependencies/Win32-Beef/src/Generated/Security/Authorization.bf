using Win32.Foundation;
using Win32.Security;
using Win32.System.Com;
using Win32.System.Threading;
using System;

namespace Win32.Security.Authorization;

#region Constants
public static
{
	public const uint32 SDDL_REVISION_1 = 1;
	public const uint32 SDDL_REVISION = 1;
	public const String SDDL_OWNER = "O";
	public const String SDDL_GROUP = "G";
	public const String SDDL_DACL = "D";
	public const String SDDL_SACL = "S";
	public const String SDDL_PROTECTED = "P";
	public const String SDDL_AUTO_INHERIT_REQ = "AR";
	public const String SDDL_AUTO_INHERITED = "AI";
	public const String SDDL_NULL_ACL = "NO_ACCESS_CONTROL";
	public const String SDDL_ACCESS_ALLOWED = "A";
	public const String SDDL_ACCESS_DENIED = "D";
	public const String SDDL_OBJECT_ACCESS_ALLOWED = "OA";
	public const String SDDL_OBJECT_ACCESS_DENIED = "OD";
	public const String SDDL_AUDIT = "AU";
	public const String SDDL_ALARM = "AL";
	public const String SDDL_OBJECT_AUDIT = "OU";
	public const String SDDL_OBJECT_ALARM = "OL";
	public const String SDDL_MANDATORY_LABEL = "ML";
	public const String SDDL_PROCESS_TRUST_LABEL = "TL";
	public const String SDDL_CALLBACK_ACCESS_ALLOWED = "XA";
	public const String SDDL_CALLBACK_ACCESS_DENIED = "XD";
	public const String SDDL_RESOURCE_ATTRIBUTE = "RA";
	public const String SDDL_SCOPED_POLICY_ID = "SP";
	public const String SDDL_CALLBACK_AUDIT = "XU";
	public const String SDDL_CALLBACK_OBJECT_ACCESS_ALLOWED = "ZA";
	public const String SDDL_ACCESS_FILTER = "FL";
	public const String SDDL_INT = "TI";
	public const String SDDL_UINT = "TU";
	public const String SDDL_WSTRING = "TS";
	public const String SDDL_SID = "TD";
	public const String SDDL_BLOB = "TX";
	public const String SDDL_BOOLEAN = "TB";
	public const String SDDL_CONTAINER_INHERIT = "CI";
	public const String SDDL_OBJECT_INHERIT = "OI";
	public const String SDDL_NO_PROPAGATE = "NP";
	public const String SDDL_INHERIT_ONLY = "IO";
	public const String SDDL_INHERITED = "ID";
	public const String SDDL_CRITICAL = "CR";
	public const String SDDL_TRUST_PROTECTED_FILTER = "TP";
	public const String SDDL_AUDIT_SUCCESS = "SA";
	public const String SDDL_AUDIT_FAILURE = "FA";
	public const String SDDL_READ_PROPERTY = "RP";
	public const String SDDL_WRITE_PROPERTY = "WP";
	public const String SDDL_CREATE_CHILD = "CC";
	public const String SDDL_DELETE_CHILD = "DC";
	public const String SDDL_LIST_CHILDREN = "LC";
	public const String SDDL_SELF_WRITE = "SW";
	public const String SDDL_LIST_OBJECT = "LO";
	public const String SDDL_DELETE_TREE = "DT";
	public const String SDDL_CONTROL_ACCESS = "CR";
	public const String SDDL_READ_CONTROL = "RC";
	public const String SDDL_WRITE_DAC = "WD";
	public const String SDDL_WRITE_OWNER = "WO";
	public const String SDDL_STANDARD_DELETE = "SD";
	public const String SDDL_GENERIC_ALL = "GA";
	public const String SDDL_GENERIC_READ = "GR";
	public const String SDDL_GENERIC_WRITE = "GW";
	public const String SDDL_GENERIC_EXECUTE = "GX";
	public const String SDDL_FILE_ALL = "FA";
	public const String SDDL_FILE_READ = "FR";
	public const String SDDL_FILE_WRITE = "FW";
	public const String SDDL_FILE_EXECUTE = "FX";
	public const String SDDL_KEY_ALL = "KA";
	public const String SDDL_KEY_READ = "KR";
	public const String SDDL_KEY_WRITE = "KW";
	public const String SDDL_KEY_EXECUTE = "KX";
	public const String SDDL_NO_WRITE_UP = "NW";
	public const String SDDL_NO_READ_UP = "NR";
	public const String SDDL_NO_EXECUTE_UP = "NX";
	public const uint32 SDDL_ALIAS_SIZE = 2;
	public const String SDDL_DOMAIN_ADMINISTRATORS = "DA";
	public const String SDDL_DOMAIN_GUESTS = "DG";
	public const String SDDL_DOMAIN_USERS = "DU";
	public const String SDDL_ENTERPRISE_DOMAIN_CONTROLLERS = "ED";
	public const String SDDL_DOMAIN_DOMAIN_CONTROLLERS = "DD";
	public const String SDDL_DOMAIN_COMPUTERS = "DC";
	public const String SDDL_BUILTIN_ADMINISTRATORS = "BA";
	public const String SDDL_BUILTIN_GUESTS = "BG";
	public const String SDDL_BUILTIN_USERS = "BU";
	public const String SDDL_LOCAL_ADMIN = "LA";
	public const String SDDL_LOCAL_GUEST = "LG";
	public const String SDDL_ACCOUNT_OPERATORS = "AO";
	public const String SDDL_BACKUP_OPERATORS = "BO";
	public const String SDDL_PRINTER_OPERATORS = "PO";
	public const String SDDL_SERVER_OPERATORS = "SO";
	public const String SDDL_AUTHENTICATED_USERS = "AU";
	public const String SDDL_PERSONAL_SELF = "PS";
	public const String SDDL_CREATOR_OWNER = "CO";
	public const String SDDL_CREATOR_GROUP = "CG";
	public const String SDDL_LOCAL_SYSTEM = "SY";
	public const String SDDL_POWER_USERS = "PU";
	public const String SDDL_EVERYONE = "WD";
	public const String SDDL_REPLICATOR = "RE";
	public const String SDDL_INTERACTIVE = "IU";
	public const String SDDL_NETWORK = "NU";
	public const String SDDL_SERVICE = "SU";
	public const String SDDL_RESTRICTED_CODE = "RC";
	public const String SDDL_WRITE_RESTRICTED_CODE = "WR";
	public const String SDDL_ANONYMOUS = "AN";
	public const String SDDL_SCHEMA_ADMINISTRATORS = "SA";
	public const String SDDL_CERT_SERV_ADMINISTRATORS = "CA";
	public const String SDDL_RAS_SERVERS = "RS";
	public const String SDDL_ENTERPRISE_ADMINS = "EA";
	public const String SDDL_GROUP_POLICY_ADMINS = "PA";
	public const String SDDL_ALIAS_PREW2KCOMPACC = "RU";
	public const String SDDL_LOCAL_SERVICE = "LS";
	public const String SDDL_NETWORK_SERVICE = "NS";
	public const String SDDL_REMOTE_DESKTOP = "RD";
	public const String SDDL_NETWORK_CONFIGURATION_OPS = "NO";
	public const String SDDL_PERFMON_USERS = "MU";
	public const String SDDL_PERFLOG_USERS = "LU";
	public const String SDDL_IIS_USERS = "IS";
	public const String SDDL_CRYPTO_OPERATORS = "CY";
	public const String SDDL_OWNER_RIGHTS = "OW";
	public const String SDDL_EVENT_LOG_READERS = "ER";
	public const String SDDL_ENTERPRISE_RO_DCs = "RO";
	public const String SDDL_CERTSVC_DCOM_ACCESS = "CD";
	public const String SDDL_ALL_APP_PACKAGES = "AC";
	public const String SDDL_RDS_REMOTE_ACCESS_SERVERS = "RA";
	public const String SDDL_RDS_ENDPOINT_SERVERS = "ES";
	public const String SDDL_RDS_MANAGEMENT_SERVERS = "MS";
	public const String SDDL_USER_MODE_DRIVERS = "UD";
	public const String SDDL_HYPER_V_ADMINS = "HA";
	public const String SDDL_CLONEABLE_CONTROLLERS = "CN";
	public const String SDDL_ACCESS_CONTROL_ASSISTANCE_OPS = "AA";
	public const String SDDL_REMOTE_MANAGEMENT_USERS = "RM";
	public const String SDDL_AUTHORITY_ASSERTED = "AS";
	public const String SDDL_SERVICE_ASSERTED = "SS";
	public const String SDDL_PROTECTED_USERS = "AP";
	public const String SDDL_KEY_ADMINS = "KA";
	public const String SDDL_ENTERPRISE_KEY_ADMINS = "EK";
	public const String SDDL_ML_LOW = "LW";
	public const String SDDL_ML_MEDIUM = "ME";
	public const String SDDL_ML_MEDIUM_PLUS = "MP";
	public const String SDDL_ML_HIGH = "HI";
	public const String SDDL_ML_SYSTEM = "SI";
	public const String SDDL_SEPERATOR = ";";
	public const String SDDL_DELIMINATOR = ":";
	public const String SDDL_ACE_BEGIN = "(";
	public const String SDDL_ACE_END = ")";
	public const String SDDL_ACE_COND_BEGIN = "(";
	public const String SDDL_ACE_COND_END = ")";
	public const String SDDL_SPACE = " ";
	public const String SDDL_ACE_COND_BLOB_PREFIX = "#";
	public const String SDDL_ACE_COND_SID_PREFIX = "SID";
	public const String SDDL_ACE_COND_ATTRIBUTE_PREFIX = "@";
	public const String SDDL_ACE_COND_USER_ATTRIBUTE_PREFIX = "@USER.";
	public const String SDDL_ACE_COND_RESOURCE_ATTRIBUTE_PREFIX = "@RESOURCE.";
	public const String SDDL_ACE_COND_DEVICE_ATTRIBUTE_PREFIX = "@DEVICE.";
	public const String SDDL_ACE_COND_TOKEN_ATTRIBUTE_PREFIX = "@TOKEN.";
	public const uint32 INHERITED_ACCESS_ENTRY = 16;
	public const uint32 INHERITED_PARENT = 268435456;
	public const uint32 INHERITED_GRANDPARENT = 536870912;
	public const String ACCCTRL_DEFAULT_PROVIDERA = "Windows NT Access Provider";
	public const String ACCCTRL_DEFAULT_PROVIDERW = "Windows NT Access Provider";
	public const String ACCCTRL_DEFAULT_PROVIDER = "Windows NT Access Provider";
	public const int32 TRUSTEE_ACCESS_ALLOWED = 1;
	public const int32 TRUSTEE_ACCESS_READ = 2;
	public const int32 TRUSTEE_ACCESS_WRITE = 4;
	public const int32 TRUSTEE_ACCESS_EXPLICIT = 1;
	public const int32 TRUSTEE_ACCESS_ALL = -1;
	public const uint32 ACTRL_RESERVED = 0;
	public const uint32 ACTRL_PERM_1 = 1;
	public const uint32 ACTRL_PERM_2 = 2;
	public const uint32 ACTRL_PERM_3 = 4;
	public const uint32 ACTRL_PERM_4 = 8;
	public const uint32 ACTRL_PERM_5 = 16;
	public const uint32 ACTRL_PERM_6 = 32;
	public const uint32 ACTRL_PERM_7 = 64;
	public const uint32 ACTRL_PERM_8 = 128;
	public const uint32 ACTRL_PERM_9 = 256;
	public const uint32 ACTRL_PERM_10 = 512;
	public const uint32 ACTRL_PERM_11 = 1024;
	public const uint32 ACTRL_PERM_12 = 2048;
	public const uint32 ACTRL_PERM_13 = 4096;
	public const uint32 ACTRL_PERM_14 = 8192;
	public const uint32 ACTRL_PERM_15 = 16384;
	public const uint32 ACTRL_PERM_16 = 32768;
	public const uint32 ACTRL_PERM_17 = 65536;
	public const uint32 ACTRL_PERM_18 = 131072;
	public const uint32 ACTRL_PERM_19 = 262144;
	public const uint32 ACTRL_PERM_20 = 524288;
	public const uint32 ACTRL_ACCESS_PROTECTED = 1;
	public const uint32 ACTRL_SYSTEM_ACCESS = 67108864;
	public const uint32 ACTRL_DELETE = 134217728;
	public const uint32 ACTRL_READ_CONTROL = 268435456;
	public const uint32 ACTRL_CHANGE_ACCESS = 536870912;
	public const uint32 ACTRL_CHANGE_OWNER = 1073741824;
	public const uint32 ACTRL_SYNCHRONIZE = 2147483648;
	public const uint32 ACTRL_STD_RIGHTS_ALL = 4160749568;
	public const uint32 ACTRL_FILE_READ = 1;
	public const uint32 ACTRL_FILE_WRITE = 2;
	public const uint32 ACTRL_FILE_APPEND = 4;
	public const uint32 ACTRL_FILE_READ_PROP = 8;
	public const uint32 ACTRL_FILE_WRITE_PROP = 16;
	public const uint32 ACTRL_FILE_EXECUTE = 32;
	public const uint32 ACTRL_FILE_READ_ATTRIB = 128;
	public const uint32 ACTRL_FILE_WRITE_ATTRIB = 256;
	public const uint32 ACTRL_FILE_CREATE_PIPE = 512;
	public const uint32 ACTRL_DIR_LIST = 1;
	public const uint32 ACTRL_DIR_CREATE_OBJECT = 2;
	public const uint32 ACTRL_DIR_CREATE_CHILD = 4;
	public const uint32 ACTRL_DIR_DELETE_CHILD = 64;
	public const uint32 ACTRL_DIR_TRAVERSE = 32;
	public const uint32 ACTRL_KERNEL_TERMINATE = 1;
	public const uint32 ACTRL_KERNEL_THREAD = 2;
	public const uint32 ACTRL_KERNEL_VM = 4;
	public const uint32 ACTRL_KERNEL_VM_READ = 8;
	public const uint32 ACTRL_KERNEL_VM_WRITE = 16;
	public const uint32 ACTRL_KERNEL_DUP_HANDLE = 32;
	public const uint32 ACTRL_KERNEL_PROCESS = 64;
	public const uint32 ACTRL_KERNEL_SET_INFO = 128;
	public const uint32 ACTRL_KERNEL_GET_INFO = 256;
	public const uint32 ACTRL_KERNEL_CONTROL = 512;
	public const uint32 ACTRL_KERNEL_ALERT = 1024;
	public const uint32 ACTRL_KERNEL_GET_CONTEXT = 2048;
	public const uint32 ACTRL_KERNEL_SET_CONTEXT = 4096;
	public const uint32 ACTRL_KERNEL_TOKEN = 8192;
	public const uint32 ACTRL_KERNEL_IMPERSONATE = 16384;
	public const uint32 ACTRL_KERNEL_DIMPERSONATE = 32768;
	public const uint32 ACTRL_PRINT_SADMIN = 1;
	public const uint32 ACTRL_PRINT_SLIST = 2;
	public const uint32 ACTRL_PRINT_PADMIN = 4;
	public const uint32 ACTRL_PRINT_PUSE = 8;
	public const uint32 ACTRL_PRINT_JADMIN = 16;
	public const uint32 ACTRL_SVC_GET_INFO = 1;
	public const uint32 ACTRL_SVC_SET_INFO = 2;
	public const uint32 ACTRL_SVC_STATUS = 4;
	public const uint32 ACTRL_SVC_LIST = 8;
	public const uint32 ACTRL_SVC_START = 16;
	public const uint32 ACTRL_SVC_STOP = 32;
	public const uint32 ACTRL_SVC_PAUSE = 64;
	public const uint32 ACTRL_SVC_INTERROGATE = 128;
	public const uint32 ACTRL_SVC_UCONTROL = 256;
	public const uint32 ACTRL_REG_QUERY = 1;
	public const uint32 ACTRL_REG_SET = 2;
	public const uint32 ACTRL_REG_CREATE_CHILD = 4;
	public const uint32 ACTRL_REG_LIST = 8;
	public const uint32 ACTRL_REG_NOTIFY = 16;
	public const uint32 ACTRL_REG_LINK = 32;
	public const uint32 ACTRL_WIN_CLIPBRD = 1;
	public const uint32 ACTRL_WIN_GLOBAL_ATOMS = 2;
	public const uint32 ACTRL_WIN_CREATE = 4;
	public const uint32 ACTRL_WIN_LIST_DESK = 8;
	public const uint32 ACTRL_WIN_LIST = 16;
	public const uint32 ACTRL_WIN_READ_ATTRIBS = 32;
	public const uint32 ACTRL_WIN_WRITE_ATTRIBS = 64;
	public const uint32 ACTRL_WIN_SCREEN = 128;
	public const uint32 ACTRL_WIN_EXIT = 256;
	public const uint32 ACTRL_ACCESS_NO_OPTIONS = 0;
	public const uint32 ACTRL_ACCESS_SUPPORTS_OBJECT_ENTRIES = 1;
	public const uint32 AUDIT_TYPE_LEGACY = 1;
	public const uint32 AUDIT_TYPE_WMI = 2;
	public const uint32 AP_ParamTypeBits = 8;
	public const int32 AP_ParamTypeMask = 255;
	public const uint32 _AUTHZ_SS_MAXSIZE = 128;
	public const uint32 APF_AuditFailure = 0;
	public const uint32 APF_AuditSuccess = 1;
	public const uint32 APF_ValidFlags = 1;
	public const uint32 AUTHZP_WPD_EVENT = 16;
	public const uint32 AUTHZ_ALLOW_MULTIPLE_SOURCE_INSTANCES = 1;
	public const uint32 AUTHZ_MIGRATED_LEGACY_PUBLISHER = 2;
	public const uint32 AUTHZ_AUDIT_INSTANCE_INFORMATION = 2;
	public const uint32 AUTHZ_SKIP_TOKEN_GROUPS = 2;
	public const uint32 AUTHZ_REQUIRE_S4U_LOGON = 4;
	public const uint32 AUTHZ_COMPUTE_PRIVILEGES = 8;
	public const uint32 AUTHZ_SECURITY_ATTRIBUTE_TYPE_INVALID = 0;
	public const uint32 AUTHZ_SECURITY_ATTRIBUTE_TYPE_INT64 = 1;
	public const uint32 AUTHZ_SECURITY_ATTRIBUTE_TYPE_UINT64 = 2;
	public const uint32 AUTHZ_SECURITY_ATTRIBUTE_TYPE_STRING = 3;
	public const uint32 AUTHZ_SECURITY_ATTRIBUTE_TYPE_FQBN = 4;
	public const uint32 AUTHZ_SECURITY_ATTRIBUTE_TYPE_SID = 5;
	public const uint32 AUTHZ_SECURITY_ATTRIBUTE_TYPE_BOOLEAN = 6;
	public const uint32 AUTHZ_SECURITY_ATTRIBUTE_TYPE_OCTET_STRING = 16;
	public const uint32 AUTHZ_SECURITY_ATTRIBUTES_INFORMATION_VERSION_V1 = 1;
	public const uint32 AUTHZ_SECURITY_ATTRIBUTES_INFORMATION_VERSION = 1;
	public const uint32 AUTHZ_RPC_INIT_INFO_CLIENT_VERSION_V1 = 1;
	public const uint32 AUTHZ_INIT_INFO_VERSION_V1 = 1;
	public const uint32 AUTHZ_WPD_CATEGORY_FLAG = 16;
	public const uint32 AUTHZ_FLAG_ALLOW_MULTIPLE_SOURCE_INSTANCES = 1;
	public const HRESULT OLESCRIPT_E_SYNTAX = -2147352319;
}
#endregion

#region TypeDefs
typealias AUTHZ_ACCESS_CHECK_RESULTS_HANDLE = int;

typealias AUTHZ_CLIENT_CONTEXT_HANDLE = int;

typealias AUTHZ_RESOURCE_MANAGER_HANDLE = int;

typealias AUTHZ_AUDIT_EVENT_HANDLE = int;

typealias AUTHZ_AUDIT_EVENT_TYPE_HANDLE = int;

typealias AUTHZ_SECURITY_EVENT_PROVIDER_HANDLE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum AUTHZ_RESOURCE_MANAGER_FLAGS : uint32
{
	AUTHZ_RM_FLAG_NO_AUDIT = 1,
	AUTHZ_RM_FLAG_INITIALIZE_UNDER_IMPERSONATION = 2,
	AUTHZ_RM_FLAG_NO_CENTRAL_ACCESS_POLICIES = 4,
}


[AllowDuplicates]
public enum AUTHZ_ACCESS_CHECK_FLAGS : uint32
{
	AUTHZ_ACCESS_CHECK_NO_DEEP_COPY_SD = 1,
}


[AllowDuplicates]
public enum AUTHZ_INITIALIZE_OBJECT_ACCESS_AUDIT_EVENT_FLAGS : uint32
{
	AUTHZ_NO_SUCCESS_AUDIT = 1,
	AUTHZ_NO_FAILURE_AUDIT = 2,
	AUTHZ_NO_ALLOC_STRINGS = 4,
}


[AllowDuplicates]
public enum TREE_SEC_INFO : uint32
{
	TREE_SEC_INFO_SET = 1,
	TREE_SEC_INFO_RESET = 2,
	TREE_SEC_INFO_RESET_KEEP_EXPLICIT = 3,
}


[AllowDuplicates]
public enum AUTHZ_GENERATE_RESULTS : uint32
{
	AUTHZ_GENERATE_SUCCESS_AUDIT = 1,
	AUTHZ_GENERATE_FAILURE_AUDIT = 2,
}


[AllowDuplicates]
public enum ACTRL_ACCESS_ENTRY_ACCESS_FLAGS : uint32
{
	ACTRL_ACCESS_ALLOWED = 1,
	ACTRL_ACCESS_DENIED = 2,
	ACTRL_AUDIT_SUCCESS = 4,
	ACTRL_AUDIT_FAILURE = 8,
}


[AllowDuplicates]
public enum AUTHZ_SECURITY_ATTRIBUTE_FLAGS : uint32
{
	AUTHZ_SECURITY_ATTRIBUTE_NON_INHERITABLE = 1,
	AUTHZ_SECURITY_ATTRIBUTE_VALUE_CASE_SENSITIVE = 2,
}


[AllowDuplicates]
public enum SE_OBJECT_TYPE : int32
{
	SE_UNKNOWN_OBJECT_TYPE = 0,
	SE_FILE_OBJECT = 1,
	SE_SERVICE = 2,
	SE_PRINTER = 3,
	SE_REGISTRY_KEY = 4,
	SE_LMSHARE = 5,
	SE_KERNEL_OBJECT = 6,
	SE_WINDOW_OBJECT = 7,
	SE_DS_OBJECT = 8,
	SE_DS_OBJECT_ALL = 9,
	SE_PROVIDER_DEFINED_OBJECT = 10,
	SE_WMIGUID_OBJECT = 11,
	SE_REGISTRY_WOW64_32KEY = 12,
	SE_REGISTRY_WOW64_64KEY = 13,
}


[AllowDuplicates]
public enum TRUSTEE_TYPE : int32
{
	TRUSTEE_IS_UNKNOWN = 0,
	TRUSTEE_IS_USER = 1,
	TRUSTEE_IS_GROUP = 2,
	TRUSTEE_IS_DOMAIN = 3,
	TRUSTEE_IS_ALIAS = 4,
	TRUSTEE_IS_WELL_KNOWN_GROUP = 5,
	TRUSTEE_IS_DELETED = 6,
	TRUSTEE_IS_INVALID = 7,
	TRUSTEE_IS_COMPUTER = 8,
}


[AllowDuplicates]
public enum TRUSTEE_FORM : int32
{
	TRUSTEE_IS_SID = 0,
	TRUSTEE_IS_NAME = 1,
	TRUSTEE_BAD_FORM = 2,
	TRUSTEE_IS_OBJECTS_AND_SID = 3,
	TRUSTEE_IS_OBJECTS_AND_NAME = 4,
}


[AllowDuplicates]
public enum MULTIPLE_TRUSTEE_OPERATION : int32
{
	NO_MULTIPLE_TRUSTEE = 0,
	TRUSTEE_IS_IMPERSONATE = 1,
}


[AllowDuplicates]
public enum ACCESS_MODE : int32
{
	NOT_USED_ACCESS = 0,
	GRANT_ACCESS = 1,
	SET_ACCESS = 2,
	DENY_ACCESS = 3,
	REVOKE_ACCESS = 4,
	SET_AUDIT_SUCCESS = 5,
	SET_AUDIT_FAILURE = 6,
}


[AllowDuplicates]
public enum PROG_INVOKE_SETTING : int32
{
	ProgressInvokeNever = 1,
	ProgressInvokeEveryObject = 2,
	ProgressInvokeOnError = 3,
	ProgressCancelOperation = 4,
	ProgressRetryOperation = 5,
	ProgressInvokePrePostError = 6,
}


[AllowDuplicates]
public enum AUDIT_PARAM_TYPE : int32
{
	APT_None = 1,
	APT_String = 2,
	APT_Ulong = 3,
	APT_Pointer = 4,
	APT_Sid = 5,
	APT_LogonId = 6,
	APT_ObjectTypeList = 7,
	APT_Luid = 8,
	APT_Guid = 9,
	APT_Time = 10,
	APT_Int64 = 11,
	APT_IpAddress = 12,
	APT_LogonIdWithSid = 13,
}


[AllowDuplicates]
public enum AUTHZ_SECURITY_ATTRIBUTE_OPERATION : int32
{
	AUTHZ_SECURITY_ATTRIBUTE_OPERATION_NONE = 0,
	AUTHZ_SECURITY_ATTRIBUTE_OPERATION_REPLACE_ALL = 1,
	AUTHZ_SECURITY_ATTRIBUTE_OPERATION_ADD = 2,
	AUTHZ_SECURITY_ATTRIBUTE_OPERATION_DELETE = 3,
	AUTHZ_SECURITY_ATTRIBUTE_OPERATION_REPLACE = 4,
}


[AllowDuplicates]
public enum AUTHZ_SID_OPERATION : int32
{
	AUTHZ_SID_OPERATION_NONE = 0,
	AUTHZ_SID_OPERATION_REPLACE_ALL = 1,
	AUTHZ_SID_OPERATION_ADD = 2,
	AUTHZ_SID_OPERATION_DELETE = 3,
	AUTHZ_SID_OPERATION_REPLACE = 4,
}


[AllowDuplicates]
public enum AUTHZ_CONTEXT_INFORMATION_CLASS : int32
{
	AuthzContextInfoUserSid = 1,
	AuthzContextInfoGroupsSids = 2,
	AuthzContextInfoRestrictedSids = 3,
	AuthzContextInfoPrivileges = 4,
	AuthzContextInfoExpirationTime = 5,
	AuthzContextInfoServerContext = 6,
	AuthzContextInfoIdentifier = 7,
	AuthzContextInfoSource = 8,
	AuthzContextInfoAll = 9,
	AuthzContextInfoAuthenticationId = 10,
	AuthzContextInfoSecurityAttributes = 11,
	AuthzContextInfoDeviceSids = 12,
	AuthzContextInfoUserClaims = 13,
	AuthzContextInfoDeviceClaims = 14,
	AuthzContextInfoAppContainerSid = 15,
	AuthzContextInfoCapabilitySids = 16,
}


[AllowDuplicates]
public enum AUTHZ_AUDIT_EVENT_INFORMATION_CLASS : int32
{
	AuthzAuditEventInfoFlags = 1,
	AuthzAuditEventInfoOperationType = 2,
	AuthzAuditEventInfoObjectType = 3,
	AuthzAuditEventInfoObjectName = 4,
	AuthzAuditEventInfoAdditionalInfo = 5,
}


[AllowDuplicates]
public enum AZ_PROP_CONSTANTS : int32
{
	AZ_PROP_NAME = 1,
	AZ_PROP_DESCRIPTION = 2,
	AZ_PROP_WRITABLE = 3,
	AZ_PROP_APPLICATION_DATA = 4,
	AZ_PROP_CHILD_CREATE = 5,
	AZ_MAX_APPLICATION_NAME_LENGTH = 512,
	AZ_MAX_OPERATION_NAME_LENGTH = 64,
	AZ_MAX_TASK_NAME_LENGTH = 64,
	AZ_MAX_SCOPE_NAME_LENGTH = 65536,
	AZ_MAX_GROUP_NAME_LENGTH = 64,
	AZ_MAX_ROLE_NAME_LENGTH = 64,
	AZ_MAX_NAME_LENGTH = 65536,
	AZ_MAX_DESCRIPTION_LENGTH = 1024,
	AZ_MAX_APPLICATION_DATA_LENGTH = 4096,
	AZ_SUBMIT_FLAG_ABORT = 1,
	AZ_SUBMIT_FLAG_FLUSH = 2,
	AZ_MAX_POLICY_URL_LENGTH = 65536,
	AZ_AZSTORE_FLAG_CREATE = 1,
	AZ_AZSTORE_FLAG_MANAGE_STORE_ONLY = 2,
	AZ_AZSTORE_FLAG_BATCH_UPDATE = 4,
	AZ_AZSTORE_FLAG_AUDIT_IS_CRITICAL = 8,
	AZ_AZSTORE_FORCE_APPLICATION_CLOSE = 16,
	AZ_AZSTORE_NT6_FUNCTION_LEVEL = 32,
	AZ_AZSTORE_FLAG_MANAGE_ONLY_PASSIVE_SUBMIT = 32768,
	AZ_PROP_AZSTORE_DOMAIN_TIMEOUT = 100,
	AZ_AZSTORE_DEFAULT_DOMAIN_TIMEOUT = 15000,
	AZ_PROP_AZSTORE_SCRIPT_ENGINE_TIMEOUT = 101,
	AZ_AZSTORE_MIN_DOMAIN_TIMEOUT = 500,
	AZ_AZSTORE_MIN_SCRIPT_ENGINE_TIMEOUT = 5000,
	AZ_AZSTORE_DEFAULT_SCRIPT_ENGINE_TIMEOUT = 45000,
	AZ_PROP_AZSTORE_MAX_SCRIPT_ENGINES = 102,
	AZ_AZSTORE_DEFAULT_MAX_SCRIPT_ENGINES = 120,
	AZ_PROP_AZSTORE_MAJOR_VERSION = 103,
	AZ_PROP_AZSTORE_MINOR_VERSION = 104,
	AZ_PROP_AZSTORE_TARGET_MACHINE = 105,
	AZ_PROP_AZTORE_IS_ADAM_INSTANCE = 106,
	AZ_PROP_OPERATION_ID = 200,
	AZ_PROP_TASK_OPERATIONS = 300,
	AZ_PROP_TASK_BIZRULE = 301,
	AZ_PROP_TASK_BIZRULE_LANGUAGE = 302,
	AZ_PROP_TASK_TASKS = 303,
	AZ_PROP_TASK_BIZRULE_IMPORTED_PATH = 304,
	AZ_PROP_TASK_IS_ROLE_DEFINITION = 305,
	AZ_MAX_TASK_BIZRULE_LENGTH = 65536,
	AZ_MAX_TASK_BIZRULE_LANGUAGE_LENGTH = 64,
	AZ_MAX_TASK_BIZRULE_IMPORTED_PATH_LENGTH = 512,
	AZ_MAX_BIZRULE_STRING = 65536,
	AZ_PROP_GROUP_TYPE = 400,
	AZ_GROUPTYPE_LDAP_QUERY = 1,
	AZ_GROUPTYPE_BASIC = 2,
	AZ_GROUPTYPE_BIZRULE = 3,
	AZ_PROP_GROUP_APP_MEMBERS = 401,
	AZ_PROP_GROUP_APP_NON_MEMBERS = 402,
	AZ_PROP_GROUP_LDAP_QUERY = 403,
	AZ_MAX_GROUP_LDAP_QUERY_LENGTH = 4096,
	AZ_PROP_GROUP_MEMBERS = 404,
	AZ_PROP_GROUP_NON_MEMBERS = 405,
	AZ_PROP_GROUP_MEMBERS_NAME = 406,
	AZ_PROP_GROUP_NON_MEMBERS_NAME = 407,
	AZ_PROP_GROUP_BIZRULE = 408,
	AZ_PROP_GROUP_BIZRULE_LANGUAGE = 409,
	AZ_PROP_GROUP_BIZRULE_IMPORTED_PATH = 410,
	AZ_MAX_GROUP_BIZRULE_LENGTH = 65536,
	AZ_MAX_GROUP_BIZRULE_LANGUAGE_LENGTH = 64,
	AZ_MAX_GROUP_BIZRULE_IMPORTED_PATH_LENGTH = 512,
	AZ_PROP_ROLE_APP_MEMBERS = 500,
	AZ_PROP_ROLE_MEMBERS = 501,
	AZ_PROP_ROLE_OPERATIONS = 502,
	AZ_PROP_ROLE_TASKS = 504,
	AZ_PROP_ROLE_MEMBERS_NAME = 505,
	AZ_PROP_SCOPE_BIZRULES_WRITABLE = 600,
	AZ_PROP_SCOPE_CAN_BE_DELEGATED = 601,
	AZ_PROP_CLIENT_CONTEXT_USER_DN = 700,
	AZ_PROP_CLIENT_CONTEXT_USER_SAM_COMPAT = 701,
	AZ_PROP_CLIENT_CONTEXT_USER_DISPLAY = 702,
	AZ_PROP_CLIENT_CONTEXT_USER_GUID = 703,
	AZ_PROP_CLIENT_CONTEXT_USER_CANONICAL = 704,
	AZ_PROP_CLIENT_CONTEXT_USER_UPN = 705,
	AZ_PROP_CLIENT_CONTEXT_USER_DNS_SAM_COMPAT = 707,
	AZ_PROP_CLIENT_CONTEXT_ROLE_FOR_ACCESS_CHECK = 708,
	AZ_PROP_CLIENT_CONTEXT_LDAP_QUERY_DN = 709,
	AZ_PROP_APPLICATION_AUTHZ_INTERFACE_CLSID = 800,
	AZ_PROP_APPLICATION_VERSION = 801,
	AZ_MAX_APPLICATION_VERSION_LENGTH = 512,
	AZ_PROP_APPLICATION_NAME = 802,
	AZ_PROP_APPLICATION_BIZRULE_ENABLED = 803,
	AZ_PROP_APPLY_STORE_SACL = 900,
	AZ_PROP_GENERATE_AUDITS = 901,
	AZ_PROP_POLICY_ADMINS = 902,
	AZ_PROP_POLICY_READERS = 903,
	AZ_PROP_DELEGATED_POLICY_USERS = 904,
	AZ_PROP_POLICY_ADMINS_NAME = 905,
	AZ_PROP_POLICY_READERS_NAME = 906,
	AZ_PROP_DELEGATED_POLICY_USERS_NAME = 907,
	AZ_CLIENT_CONTEXT_SKIP_GROUP = 1,
	AZ_CLIENT_CONTEXT_SKIP_LDAP_QUERY = 1,
	AZ_CLIENT_CONTEXT_GET_GROUP_RECURSIVE = 2,
	AZ_CLIENT_CONTEXT_GET_GROUPS_STORE_LEVEL_ONLY = 2,
}

#endregion

#region Function Pointers
public function BOOL PFN_AUTHZ_DYNAMIC_ACCESS_CHECK(AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, ACE_HEADER* pAce, void* pArgs, BOOL* pbAceApplicable);

public function BOOL PFN_AUTHZ_COMPUTE_DYNAMIC_GROUPS(AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, void* Args, SID_AND_ATTRIBUTES** pSidAttrArray, uint32* pSidCount, SID_AND_ATTRIBUTES** pRestrictedSidAttrArray, uint32* pRestrictedSidCount);

public function void PFN_AUTHZ_FREE_DYNAMIC_GROUPS(SID_AND_ATTRIBUTES* pSidAttrArray);

public function BOOL PFN_AUTHZ_GET_CENTRAL_ACCESS_POLICY(AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, PSID capid, void* pArgs, BOOL* pCentralAccessPolicyApplicable, void** ppCentralAccessPolicy);

public function void PFN_AUTHZ_FREE_CENTRAL_ACCESS_POLICY(void* pCentralAccessPolicy);

public function void FN_PROGRESS(PWSTR pObjectName, uint32 Status, PROG_INVOKE_SETTING* pInvokeSetting, void* Args, BOOL SecuritySet);

#endregion

#region Structs
[CRepr]
public struct OBJECTS_AND_SID
{
	public SYSTEM_AUDIT_OBJECT_ACE_FLAGS ObjectsPresent;
	public Guid ObjectTypeGuid;
	public Guid InheritedObjectTypeGuid;
	public SID* pSid;
}

[CRepr]
public struct OBJECTS_AND_NAME_A
{
	public SYSTEM_AUDIT_OBJECT_ACE_FLAGS ObjectsPresent;
	public SE_OBJECT_TYPE ObjectType;
	public PSTR ObjectTypeName;
	public PSTR InheritedObjectTypeName;
	public PSTR ptstrName;
}

[CRepr]
public struct OBJECTS_AND_NAME_W
{
	public SYSTEM_AUDIT_OBJECT_ACE_FLAGS ObjectsPresent;
	public SE_OBJECT_TYPE ObjectType;
	public PWSTR ObjectTypeName;
	public PWSTR InheritedObjectTypeName;
	public PWSTR ptstrName;
}

[CRepr]
public struct TRUSTEE_A
{
	public TRUSTEE_A* pMultipleTrustee;
	public MULTIPLE_TRUSTEE_OPERATION MultipleTrusteeOperation;
	public TRUSTEE_FORM TrusteeForm;
	public TRUSTEE_TYPE TrusteeType;
	public PSTR ptstrName;
}

[CRepr]
public struct TRUSTEE_W
{
	public TRUSTEE_W* pMultipleTrustee;
	public MULTIPLE_TRUSTEE_OPERATION MultipleTrusteeOperation;
	public TRUSTEE_FORM TrusteeForm;
	public TRUSTEE_TYPE TrusteeType;
	public PWSTR ptstrName;
}

[CRepr]
public struct EXPLICIT_ACCESS_A
{
	public uint32 grfAccessPermissions;
	public ACCESS_MODE grfAccessMode;
	public ACE_FLAGS grfInheritance;
	public TRUSTEE_A Trustee;
}

[CRepr]
public struct EXPLICIT_ACCESS_W
{
	public uint32 grfAccessPermissions;
	public ACCESS_MODE grfAccessMode;
	public ACE_FLAGS grfInheritance;
	public TRUSTEE_W Trustee;
}

[CRepr]
public struct ACTRL_ACCESS_ENTRYA
{
	public TRUSTEE_A Trustee;
	public ACTRL_ACCESS_ENTRY_ACCESS_FLAGS fAccessFlags;
	public uint32 Access;
	public uint32 ProvSpecificAccess;
	public ACE_FLAGS Inheritance;
	public PSTR lpInheritProperty;
}

[CRepr]
public struct ACTRL_ACCESS_ENTRYW
{
	public TRUSTEE_W Trustee;
	public ACTRL_ACCESS_ENTRY_ACCESS_FLAGS fAccessFlags;
	public uint32 Access;
	public uint32 ProvSpecificAccess;
	public ACE_FLAGS Inheritance;
	public PWSTR lpInheritProperty;
}

[CRepr]
public struct ACTRL_ACCESS_ENTRY_LISTA
{
	public uint32 cEntries;
	public ACTRL_ACCESS_ENTRYA* pAccessList;
}

[CRepr]
public struct ACTRL_ACCESS_ENTRY_LISTW
{
	public uint32 cEntries;
	public ACTRL_ACCESS_ENTRYW* pAccessList;
}

[CRepr]
public struct ACTRL_PROPERTY_ENTRYA
{
	public PSTR lpProperty;
	public ACTRL_ACCESS_ENTRY_LISTA* pAccessEntryList;
	public uint32 fListFlags;
}

[CRepr]
public struct ACTRL_PROPERTY_ENTRYW
{
	public PWSTR lpProperty;
	public ACTRL_ACCESS_ENTRY_LISTW* pAccessEntryList;
	public uint32 fListFlags;
}

[CRepr]
public struct ACTRL_ACCESSA
{
	public uint32 cEntries;
	public ACTRL_PROPERTY_ENTRYA* pPropertyAccessList;
}

[CRepr]
public struct ACTRL_ACCESSW
{
	public uint32 cEntries;
	public ACTRL_PROPERTY_ENTRYW* pPropertyAccessList;
}

[CRepr]
public struct TRUSTEE_ACCESSA
{
	public PSTR lpProperty;
	public uint32 Access;
	public uint32 fAccessFlags;
	public uint32 fReturnedAccess;
}

[CRepr]
public struct TRUSTEE_ACCESSW
{
	public PWSTR lpProperty;
	public uint32 Access;
	public uint32 fAccessFlags;
	public uint32 fReturnedAccess;
}

[CRepr]
public struct ACTRL_OVERLAPPED
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public void* Provider;
		public uint32 Reserved1;
	}
	public using _Anonymous_e__Union Anonymous;
	public uint32 Reserved2;
	public HANDLE hEvent;
}

[CRepr]
public struct ACTRL_ACCESS_INFOA
{
	public uint32 fAccessPermission;
	public PSTR lpAccessPermissionName;
}

[CRepr]
public struct ACTRL_ACCESS_INFOW
{
	public uint32 fAccessPermission;
	public PWSTR lpAccessPermissionName;
}

[CRepr]
public struct ACTRL_CONTROL_INFOA
{
	public PSTR lpControlId;
	public PSTR lpControlName;
}

[CRepr]
public struct ACTRL_CONTROL_INFOW
{
	public PWSTR lpControlId;
	public PWSTR lpControlName;
}

[CRepr]
public struct FN_OBJECT_MGR_FUNCTS
{
	public uint32 Placeholder;
}

[CRepr]
public struct INHERITED_FROMA
{
	public int32 GenerationGap;
	public PSTR AncestorName;
}

[CRepr]
public struct INHERITED_FROMW
{
	public int32 GenerationGap;
	public PWSTR AncestorName;
}

[CRepr]
public struct AUDIT_OBJECT_TYPE
{
	public Guid ObjectType;
	public uint16 Flags;
	public uint16 Level;
	public uint32 AccessMask;
}

[CRepr]
public struct AUDIT_OBJECT_TYPES
{
	public uint16 Count;
	public uint16 Flags;
	public AUDIT_OBJECT_TYPE* pObjectTypes;
}

[CRepr]
public struct AUDIT_IP_ADDRESS
{
	public uint8[128] pIpAddress;
}

[CRepr]
public struct AUDIT_PARAM
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint Data0;
		public PWSTR String;
		public uint u;
		public SID* psid;
		public Guid* pguid;
		public uint32 LogonId_LowPart;
		public AUDIT_OBJECT_TYPES* pObjectTypes;
		public AUDIT_IP_ADDRESS* pIpAddress;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint Data1;
		public int32 LogonId_HighPart;
	}
	public AUDIT_PARAM_TYPE Type;
	public uint32 Length;
	public uint32 Flags;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct AUDIT_PARAMS
{
	public uint32 Length;
	public uint32 Flags;
	public uint16 Count;
	public AUDIT_PARAM* Parameters;
}

[CRepr]
public struct AUTHZ_AUDIT_EVENT_TYPE_LEGACY
{
	public uint16 CategoryId;
	public uint16 AuditId;
	public uint16 ParameterCount;
}

[CRepr, Union]
public struct AUTHZ_AUDIT_EVENT_TYPE_UNION
{
	public AUTHZ_AUDIT_EVENT_TYPE_LEGACY Legacy;
}

[CRepr]
public struct AUTHZ_AUDIT_EVENT_TYPE_OLD
{
	public uint32 Version;
	public uint32 dwFlags;
	public int32 RefCount;
	public uint hAudit;
	public LUID LinkId;
	public AUTHZ_AUDIT_EVENT_TYPE_UNION u;
}

[CRepr]
public struct AUTHZ_CAP_CHANGE_SUBSCRIPTION_HANDLE__
{
	public int32 unused;
}

[CRepr]
public struct AUTHZ_ACCESS_REQUEST
{
	public uint32 DesiredAccess;
	public PSID PrincipalSelfSid;
	public OBJECT_TYPE_LIST* ObjectTypeList;
	public uint32 ObjectTypeListLength;
	public void* OptionalArguments;
}

[CRepr]
public struct AUTHZ_ACCESS_REPLY
{
	public uint32 ResultListLength;
	public uint32* GrantedAccessMask;
	public AUTHZ_GENERATE_RESULTS* SaclEvaluationResults;
	public uint32* Error;
}

[CRepr]
public struct AUTHZ_SECURITY_ATTRIBUTE_FQBN_VALUE
{
	public uint64 Version;
	public PWSTR pName;
}

[CRepr]
public struct AUTHZ_SECURITY_ATTRIBUTE_OCTET_STRING_VALUE
{
	public void* pValue;
	public uint32 ValueLength;
}

[CRepr]
public struct AUTHZ_SECURITY_ATTRIBUTE_V1
{
	[CRepr, Union]
	public struct _Values_e__Union
	{
		public int64* pInt64;
		public uint64* pUint64;
		public PWSTR* ppString;
		public AUTHZ_SECURITY_ATTRIBUTE_FQBN_VALUE* pFqbn;
		public AUTHZ_SECURITY_ATTRIBUTE_OCTET_STRING_VALUE* pOctetString;
	}
	public PWSTR pName;
	public uint16 ValueType;
	public uint16 Reserved;
	public AUTHZ_SECURITY_ATTRIBUTE_FLAGS Flags;
	public uint32 ValueCount;
	public _Values_e__Union Values;
}

[CRepr]
public struct AUTHZ_SECURITY_ATTRIBUTES_INFORMATION
{
	[CRepr, Union]
	public struct _Attribute_e__Union
	{
		public AUTHZ_SECURITY_ATTRIBUTE_V1* pAttributeV1;
	}
	public uint16 Version;
	public uint16 Reserved;
	public uint32 AttributeCount;
	public _Attribute_e__Union Attribute;
}

[CRepr]
public struct AUTHZ_RPC_INIT_INFO_CLIENT
{
	public uint16 version;
	public PWSTR ObjectUuid;
	public PWSTR ProtSeq;
	public PWSTR NetworkAddr;
	public PWSTR Endpoint;
	public PWSTR Options;
	public PWSTR ServerSpn;
}

[CRepr]
public struct AUTHZ_INIT_INFO
{
	public uint16 version;
	public PWSTR szResourceManagerName;
	public PFN_AUTHZ_DYNAMIC_ACCESS_CHECK pfnDynamicAccessCheck;
	public PFN_AUTHZ_COMPUTE_DYNAMIC_GROUPS pfnComputeDynamicGroups;
	public PFN_AUTHZ_FREE_DYNAMIC_GROUPS pfnFreeDynamicGroups;
	public PFN_AUTHZ_GET_CENTRAL_ACCESS_POLICY pfnGetCentralAccessPolicy;
	public PFN_AUTHZ_FREE_CENTRAL_ACCESS_POLICY pfnFreeCentralAccessPolicy;
}

[CRepr]
public struct AUTHZ_REGISTRATION_OBJECT_TYPE_NAME_OFFSET
{
	public PWSTR szObjectTypeName;
	public uint32 dwOffset;
}

[CRepr]
public struct AUTHZ_SOURCE_SCHEMA_REGISTRATION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public void* pReserved;
		public Guid* pProviderGuid;
	}
	public uint32 dwFlags;
	public PWSTR szEventSourceName;
	public PWSTR szEventMessageFile;
	public PWSTR szEventSourceXmlSchemaFile;
	public PWSTR szEventAccessStringsFile;
	public PWSTR szExecutableImagePath;
	public using _Anonymous_e__Union Anonymous;
	public uint32 dwObjectTypeNameCount;
	public AUTHZ_REGISTRATION_OBJECT_TYPE_NAME_OFFSET* ObjectTypeNames mut => &ObjectTypeNames_impl;
	private AUTHZ_REGISTRATION_OBJECT_TYPE_NAME_OFFSET[ANYSIZE_ARRAY] ObjectTypeNames_impl;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_AzAuthorizationStore = .(0xb2bcff59, 0xa757, 0x4b0b, 0xa1, 0xbc, 0xea, 0x69, 0x98, 0x1d, 0xa6, 0x9e);


	public const Guid CLSID_AzBizRuleContext = .(0x5c2dc96f, 0x8d51, 0x434b, 0xb3, 0x3c, 0x37, 0x9b, 0xcc, 0xae, 0x77, 0xc3);


	public const Guid CLSID_AzPrincipalLocator = .(0x483afb5d, 0x70df, 0x4e16, 0xab, 0xdc, 0xa1, 0xde, 0x4d, 0x01, 0x5a, 0x3e);


}
#endregion

#region COM Types
[CRepr]struct IAzAuthorizationStore : IDispatch
{
	public new const Guid IID = .(0xedbd9ca9, 0x9b82, 0x4f6a, 0x9e, 0x8b, 0x98, 0x30, 0x1e, 0x45, 0x0f, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrApplicationData) get_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationData) put_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProp) get_DomainTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lProp) put_DomainTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProp) get_ScriptEngineTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lProp) put_ScriptEngineTimeout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProp) get_MaxScriptEngines;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lProp) put_MaxScriptEngines;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbProp) get_GenerateAudits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bProp) put_GenerateAudits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProp) get_Writable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AZ_PROP_CONSTANTS lPropId, VARIANT varProp, VARIANT varReserved) AddPropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) DeletePropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarAdmins) get_PolicyAdministrators;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarReaders) get_PolicyReaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) AddPolicyAdministrator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) DeletePolicyAdministrator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) AddPolicyReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) DeletePolicyReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AZ_PROP_CONSTANTS lFlags, BSTR bstrPolicyURL, VARIANT varReserved) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varReserved) UpdateCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varReserved) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzApplications** ppAppCollection) get_Applications;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationName, VARIANT varReserved, IAzApplication** ppApplication) OpenApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationName, VARIANT varReserved, IAzApplication** ppApplication) CreateApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationName, VARIANT varReserved) DeleteApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzApplicationGroups** ppGroupCollection) get_ApplicationGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) CreateApplicationGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) OpenApplicationGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName, VARIANT varReserved) DeleteApplicationGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, VARIANT varReserved) Submit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarDelegatedPolicyUsers) get_DelegatedPolicyUsers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDelegatedPolicyUser, VARIANT varReserved) AddDelegatedPolicyUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDelegatedPolicyUser, VARIANT varReserved) DeleteDelegatedPolicyUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTargetMachine) get_TargetMachine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbApplyStoreSacl) get_ApplyStoreSacl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bApplyStoreSacl) put_ApplyStoreSacl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarAdmins) get_PolicyAdministratorsName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarReaders) get_PolicyReadersName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) AddPolicyAdministratorName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) DeletePolicyAdministratorName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) AddPolicyReaderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) DeletePolicyReaderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarDelegatedPolicyUsers) get_DelegatedPolicyUsersName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDelegatedPolicyUser, VARIANT varReserved) AddDelegatedPolicyUserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDelegatedPolicyUser, VARIANT varReserved) DeleteDelegatedPolicyUserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationName, int32 lFlag) CloseApplication;
	}


	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_ApplicationData(BSTR* pbstrApplicationData) mut => VT.[Friend]get_ApplicationData(&this, pbstrApplicationData);

	public HRESULT put_ApplicationData(BSTR bstrApplicationData) mut => VT.[Friend]put_ApplicationData(&this, bstrApplicationData);

	public HRESULT get_DomainTimeout(int32* plProp) mut => VT.[Friend]get_DomainTimeout(&this, plProp);

	public HRESULT put_DomainTimeout(int32 lProp) mut => VT.[Friend]put_DomainTimeout(&this, lProp);

	public HRESULT get_ScriptEngineTimeout(int32* plProp) mut => VT.[Friend]get_ScriptEngineTimeout(&this, plProp);

	public HRESULT put_ScriptEngineTimeout(int32 lProp) mut => VT.[Friend]put_ScriptEngineTimeout(&this, lProp);

	public HRESULT get_MaxScriptEngines(int32* plProp) mut => VT.[Friend]get_MaxScriptEngines(&this, plProp);

	public HRESULT put_MaxScriptEngines(int32 lProp) mut => VT.[Friend]put_MaxScriptEngines(&this, lProp);

	public HRESULT get_GenerateAudits(BOOL* pbProp) mut => VT.[Friend]get_GenerateAudits(&this, pbProp);

	public HRESULT put_GenerateAudits(BOOL bProp) mut => VT.[Friend]put_GenerateAudits(&this, bProp);

	public HRESULT get_Writable(BOOL* pfProp) mut => VT.[Friend]get_Writable(&this, pfProp);

	public HRESULT GetProperty(int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) mut => VT.[Friend]GetProperty(&this, lPropId, varReserved, pvarProp);

	public HRESULT SetProperty(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]SetProperty(&this, lPropId, varProp, varReserved);

	public HRESULT AddPropertyItem(AZ_PROP_CONSTANTS lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]AddPropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT DeletePropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]DeletePropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT get_PolicyAdministrators(VARIANT* pvarAdmins) mut => VT.[Friend]get_PolicyAdministrators(&this, pvarAdmins);

	public HRESULT get_PolicyReaders(VARIANT* pvarReaders) mut => VT.[Friend]get_PolicyReaders(&this, pvarReaders);

	public HRESULT AddPolicyAdministrator(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]AddPolicyAdministrator(&this, bstrAdmin, varReserved);

	public HRESULT DeletePolicyAdministrator(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]DeletePolicyAdministrator(&this, bstrAdmin, varReserved);

	public HRESULT AddPolicyReader(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]AddPolicyReader(&this, bstrReader, varReserved);

	public HRESULT DeletePolicyReader(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]DeletePolicyReader(&this, bstrReader, varReserved);

	public HRESULT Initialize(AZ_PROP_CONSTANTS lFlags, BSTR bstrPolicyURL, VARIANT varReserved) mut => VT.[Friend]Initialize(&this, lFlags, bstrPolicyURL, varReserved);

	public HRESULT UpdateCache(VARIANT varReserved) mut => VT.[Friend]UpdateCache(&this, varReserved);

	public HRESULT Delete(VARIANT varReserved) mut => VT.[Friend]Delete(&this, varReserved);

	public HRESULT get_Applications(IAzApplications** ppAppCollection) mut => VT.[Friend]get_Applications(&this, ppAppCollection);

	public HRESULT OpenApplication(BSTR bstrApplicationName, VARIANT varReserved, IAzApplication** ppApplication) mut => VT.[Friend]OpenApplication(&this, bstrApplicationName, varReserved, ppApplication);

	public HRESULT CreateApplication(BSTR bstrApplicationName, VARIANT varReserved, IAzApplication** ppApplication) mut => VT.[Friend]CreateApplication(&this, bstrApplicationName, varReserved, ppApplication);

	public HRESULT DeleteApplication(BSTR bstrApplicationName, VARIANT varReserved) mut => VT.[Friend]DeleteApplication(&this, bstrApplicationName, varReserved);

	public HRESULT get_ApplicationGroups(IAzApplicationGroups** ppGroupCollection) mut => VT.[Friend]get_ApplicationGroups(&this, ppGroupCollection);

	public HRESULT CreateApplicationGroup(BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) mut => VT.[Friend]CreateApplicationGroup(&this, bstrGroupName, varReserved, ppGroup);

	public HRESULT OpenApplicationGroup(BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) mut => VT.[Friend]OpenApplicationGroup(&this, bstrGroupName, varReserved, ppGroup);

	public HRESULT DeleteApplicationGroup(BSTR bstrGroupName, VARIANT varReserved) mut => VT.[Friend]DeleteApplicationGroup(&this, bstrGroupName, varReserved);

	public HRESULT Submit(int32 lFlags, VARIANT varReserved) mut => VT.[Friend]Submit(&this, lFlags, varReserved);

	public HRESULT get_DelegatedPolicyUsers(VARIANT* pvarDelegatedPolicyUsers) mut => VT.[Friend]get_DelegatedPolicyUsers(&this, pvarDelegatedPolicyUsers);

	public HRESULT AddDelegatedPolicyUser(BSTR bstrDelegatedPolicyUser, VARIANT varReserved) mut => VT.[Friend]AddDelegatedPolicyUser(&this, bstrDelegatedPolicyUser, varReserved);

	public HRESULT DeleteDelegatedPolicyUser(BSTR bstrDelegatedPolicyUser, VARIANT varReserved) mut => VT.[Friend]DeleteDelegatedPolicyUser(&this, bstrDelegatedPolicyUser, varReserved);

	public HRESULT get_TargetMachine(BSTR* pbstrTargetMachine) mut => VT.[Friend]get_TargetMachine(&this, pbstrTargetMachine);

	public HRESULT get_ApplyStoreSacl(BOOL* pbApplyStoreSacl) mut => VT.[Friend]get_ApplyStoreSacl(&this, pbApplyStoreSacl);

	public HRESULT put_ApplyStoreSacl(BOOL bApplyStoreSacl) mut => VT.[Friend]put_ApplyStoreSacl(&this, bApplyStoreSacl);

	public HRESULT get_PolicyAdministratorsName(VARIANT* pvarAdmins) mut => VT.[Friend]get_PolicyAdministratorsName(&this, pvarAdmins);

	public HRESULT get_PolicyReadersName(VARIANT* pvarReaders) mut => VT.[Friend]get_PolicyReadersName(&this, pvarReaders);

	public HRESULT AddPolicyAdministratorName(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]AddPolicyAdministratorName(&this, bstrAdmin, varReserved);

	public HRESULT DeletePolicyAdministratorName(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]DeletePolicyAdministratorName(&this, bstrAdmin, varReserved);

	public HRESULT AddPolicyReaderName(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]AddPolicyReaderName(&this, bstrReader, varReserved);

	public HRESULT DeletePolicyReaderName(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]DeletePolicyReaderName(&this, bstrReader, varReserved);

	public HRESULT get_DelegatedPolicyUsersName(VARIANT* pvarDelegatedPolicyUsers) mut => VT.[Friend]get_DelegatedPolicyUsersName(&this, pvarDelegatedPolicyUsers);

	public HRESULT AddDelegatedPolicyUserName(BSTR bstrDelegatedPolicyUser, VARIANT varReserved) mut => VT.[Friend]AddDelegatedPolicyUserName(&this, bstrDelegatedPolicyUser, varReserved);

	public HRESULT DeleteDelegatedPolicyUserName(BSTR bstrDelegatedPolicyUser, VARIANT varReserved) mut => VT.[Friend]DeleteDelegatedPolicyUserName(&this, bstrDelegatedPolicyUser, varReserved);

	public HRESULT CloseApplication(BSTR bstrApplicationName, int32 lFlag) mut => VT.[Friend]CloseApplication(&this, bstrApplicationName, lFlag);
}

[CRepr]struct IAzAuthorizationStore2 : IAzAuthorizationStore
{
	public new const Guid IID = .(0xb11e5584, 0xd577, 0x4273, 0xb6, 0xc5, 0x09, 0x73, 0xe0, 0xf8, 0xe8, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzAuthorizationStore.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationName, VARIANT varReserved, IAzApplication2** ppApplication) OpenApplication2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationName, VARIANT varReserved, IAzApplication2** ppApplication) CreateApplication2;
	}


	public HRESULT OpenApplication2(BSTR bstrApplicationName, VARIANT varReserved, IAzApplication2** ppApplication) mut => VT.[Friend]OpenApplication2(&this, bstrApplicationName, varReserved, ppApplication);

	public HRESULT CreateApplication2(BSTR bstrApplicationName, VARIANT varReserved, IAzApplication2** ppApplication) mut => VT.[Friend]CreateApplication2(&this, bstrApplicationName, varReserved, ppApplication);
}

[CRepr]struct IAzAuthorizationStore3 : IAzAuthorizationStore2
{
	public new const Guid IID = .(0xabc08425, 0x0c86, 0x4fa0, 0x9b, 0xe3, 0x71, 0x89, 0x95, 0x6c, 0x92, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzAuthorizationStore2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbIsUpdateNeeded) IsUpdateNeeded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbSupported) BizruleGroupSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFunctionalLevel) UpgradeStoresFunctionalLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFunctionalLevel, int16* pbSupported) IsFunctionalLevelUpgradeSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMajorVersion, int32* plMinorVersion) GetSchemaVersion;
	}


	public HRESULT IsUpdateNeeded(int16* pbIsUpdateNeeded) mut => VT.[Friend]IsUpdateNeeded(&this, pbIsUpdateNeeded);

	public HRESULT BizruleGroupSupported(int16* pbSupported) mut => VT.[Friend]BizruleGroupSupported(&this, pbSupported);

	public HRESULT UpgradeStoresFunctionalLevel(int32 lFunctionalLevel) mut => VT.[Friend]UpgradeStoresFunctionalLevel(&this, lFunctionalLevel);

	public HRESULT IsFunctionalLevelUpgradeSupported(int32 lFunctionalLevel, int16* pbSupported) mut => VT.[Friend]IsFunctionalLevelUpgradeSupported(&this, lFunctionalLevel, pbSupported);

	public HRESULT GetSchemaVersion(int32* plMajorVersion, int32* plMinorVersion) mut => VT.[Friend]GetSchemaVersion(&this, plMajorVersion, plMinorVersion);
}

[CRepr]struct IAzApplication : IDispatch
{
	public new const Guid IID = .(0x987bc7c7, 0xb813, 0x4d27, 0xbe, 0xde, 0x6b, 0xa5, 0xae, 0x86, 0x7e, 0x95);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrApplicationData) get_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationData) put_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_AuthzInterfaceClsid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp) put_AuthzInterfaceClsid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp) put_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbProp) get_GenerateAudits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bProp) put_GenerateAudits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbProp) get_ApplyStoreSacl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bProp) put_ApplyStoreSacl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProp) get_Writable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarAdmins) get_PolicyAdministrators;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarReaders) get_PolicyReaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) AddPolicyAdministrator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) DeletePolicyAdministrator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) AddPolicyReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) DeletePolicyReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzScopes** ppScopeCollection) get_Scopes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, VARIANT varReserved, IAzScope** ppScope) OpenScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, VARIANT varReserved, IAzScope** ppScope) CreateScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, VARIANT varReserved) DeleteScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzOperations** ppOperationCollection) get_Operations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOperationName, VARIANT varReserved, IAzOperation** ppOperation) OpenOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOperationName, VARIANT varReserved, IAzOperation** ppOperation) CreateOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOperationName, VARIANT varReserved) DeleteOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzTasks** ppTaskCollection) get_Tasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTaskName, VARIANT varReserved, IAzTask** ppTask) OpenTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTaskName, VARIANT varReserved, IAzTask** ppTask) CreateTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTaskName, VARIANT varReserved) DeleteTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzApplicationGroups** ppGroupCollection) get_ApplicationGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) OpenApplicationGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) CreateApplicationGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName, VARIANT varReserved) DeleteApplicationGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzRoles** ppRoleCollection) get_Roles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleName, VARIANT varReserved, IAzRole** ppRole) OpenRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleName, VARIANT varReserved, IAzRole** ppRole) CreateRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleName, VARIANT varReserved) DeleteRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullTokenHandle, VARIANT varReserved, IAzClientContext** ppClientContext) InitializeClientContextFromToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) AddPropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) DeletePropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, VARIANT varReserved) Submit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ClientName, BSTR DomainName, VARIANT varReserved, IAzClientContext** ppClientContext) InitializeClientContextFromName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarDelegatedPolicyUsers) get_DelegatedPolicyUsers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDelegatedPolicyUser, VARIANT varReserved) AddDelegatedPolicyUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDelegatedPolicyUser, VARIANT varReserved) DeleteDelegatedPolicyUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR SidString, int32 lOptions, VARIANT varReserved, IAzClientContext** ppClientContext) InitializeClientContextFromStringSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarAdmins) get_PolicyAdministratorsName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarReaders) get_PolicyReadersName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) AddPolicyAdministratorName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) DeletePolicyAdministratorName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) AddPolicyReaderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) DeletePolicyReaderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarDelegatedPolicyUsers) get_DelegatedPolicyUsersName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDelegatedPolicyUser, VARIANT varReserved) AddDelegatedPolicyUserName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDelegatedPolicyUser, VARIANT varReserved) DeleteDelegatedPolicyUserName;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrName) mut => VT.[Friend]put_Name(&this, bstrName);

	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_ApplicationData(BSTR* pbstrApplicationData) mut => VT.[Friend]get_ApplicationData(&this, pbstrApplicationData);

	public HRESULT put_ApplicationData(BSTR bstrApplicationData) mut => VT.[Friend]put_ApplicationData(&this, bstrApplicationData);

	public HRESULT get_AuthzInterfaceClsid(BSTR* pbstrProp) mut => VT.[Friend]get_AuthzInterfaceClsid(&this, pbstrProp);

	public HRESULT put_AuthzInterfaceClsid(BSTR bstrProp) mut => VT.[Friend]put_AuthzInterfaceClsid(&this, bstrProp);

	public HRESULT get_Version(BSTR* pbstrProp) mut => VT.[Friend]get_Version(&this, pbstrProp);

	public HRESULT put_Version(BSTR bstrProp) mut => VT.[Friend]put_Version(&this, bstrProp);

	public HRESULT get_GenerateAudits(BOOL* pbProp) mut => VT.[Friend]get_GenerateAudits(&this, pbProp);

	public HRESULT put_GenerateAudits(BOOL bProp) mut => VT.[Friend]put_GenerateAudits(&this, bProp);

	public HRESULT get_ApplyStoreSacl(BOOL* pbProp) mut => VT.[Friend]get_ApplyStoreSacl(&this, pbProp);

	public HRESULT put_ApplyStoreSacl(BOOL bProp) mut => VT.[Friend]put_ApplyStoreSacl(&this, bProp);

	public HRESULT get_Writable(BOOL* pfProp) mut => VT.[Friend]get_Writable(&this, pfProp);

	public HRESULT GetProperty(int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) mut => VT.[Friend]GetProperty(&this, lPropId, varReserved, pvarProp);

	public HRESULT SetProperty(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]SetProperty(&this, lPropId, varProp, varReserved);

	public HRESULT get_PolicyAdministrators(VARIANT* pvarAdmins) mut => VT.[Friend]get_PolicyAdministrators(&this, pvarAdmins);

	public HRESULT get_PolicyReaders(VARIANT* pvarReaders) mut => VT.[Friend]get_PolicyReaders(&this, pvarReaders);

	public HRESULT AddPolicyAdministrator(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]AddPolicyAdministrator(&this, bstrAdmin, varReserved);

	public HRESULT DeletePolicyAdministrator(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]DeletePolicyAdministrator(&this, bstrAdmin, varReserved);

	public HRESULT AddPolicyReader(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]AddPolicyReader(&this, bstrReader, varReserved);

	public HRESULT DeletePolicyReader(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]DeletePolicyReader(&this, bstrReader, varReserved);

	public HRESULT get_Scopes(IAzScopes** ppScopeCollection) mut => VT.[Friend]get_Scopes(&this, ppScopeCollection);

	public HRESULT OpenScope(BSTR bstrScopeName, VARIANT varReserved, IAzScope** ppScope) mut => VT.[Friend]OpenScope(&this, bstrScopeName, varReserved, ppScope);

	public HRESULT CreateScope(BSTR bstrScopeName, VARIANT varReserved, IAzScope** ppScope) mut => VT.[Friend]CreateScope(&this, bstrScopeName, varReserved, ppScope);

	public HRESULT DeleteScope(BSTR bstrScopeName, VARIANT varReserved) mut => VT.[Friend]DeleteScope(&this, bstrScopeName, varReserved);

	public HRESULT get_Operations(IAzOperations** ppOperationCollection) mut => VT.[Friend]get_Operations(&this, ppOperationCollection);

	public HRESULT OpenOperation(BSTR bstrOperationName, VARIANT varReserved, IAzOperation** ppOperation) mut => VT.[Friend]OpenOperation(&this, bstrOperationName, varReserved, ppOperation);

	public HRESULT CreateOperation(BSTR bstrOperationName, VARIANT varReserved, IAzOperation** ppOperation) mut => VT.[Friend]CreateOperation(&this, bstrOperationName, varReserved, ppOperation);

	public HRESULT DeleteOperation(BSTR bstrOperationName, VARIANT varReserved) mut => VT.[Friend]DeleteOperation(&this, bstrOperationName, varReserved);

	public HRESULT get_Tasks(IAzTasks** ppTaskCollection) mut => VT.[Friend]get_Tasks(&this, ppTaskCollection);

	public HRESULT OpenTask(BSTR bstrTaskName, VARIANT varReserved, IAzTask** ppTask) mut => VT.[Friend]OpenTask(&this, bstrTaskName, varReserved, ppTask);

	public HRESULT CreateTask(BSTR bstrTaskName, VARIANT varReserved, IAzTask** ppTask) mut => VT.[Friend]CreateTask(&this, bstrTaskName, varReserved, ppTask);

	public HRESULT DeleteTask(BSTR bstrTaskName, VARIANT varReserved) mut => VT.[Friend]DeleteTask(&this, bstrTaskName, varReserved);

	public HRESULT get_ApplicationGroups(IAzApplicationGroups** ppGroupCollection) mut => VT.[Friend]get_ApplicationGroups(&this, ppGroupCollection);

	public HRESULT OpenApplicationGroup(BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) mut => VT.[Friend]OpenApplicationGroup(&this, bstrGroupName, varReserved, ppGroup);

	public HRESULT CreateApplicationGroup(BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) mut => VT.[Friend]CreateApplicationGroup(&this, bstrGroupName, varReserved, ppGroup);

	public HRESULT DeleteApplicationGroup(BSTR bstrGroupName, VARIANT varReserved) mut => VT.[Friend]DeleteApplicationGroup(&this, bstrGroupName, varReserved);

	public HRESULT get_Roles(IAzRoles** ppRoleCollection) mut => VT.[Friend]get_Roles(&this, ppRoleCollection);

	public HRESULT OpenRole(BSTR bstrRoleName, VARIANT varReserved, IAzRole** ppRole) mut => VT.[Friend]OpenRole(&this, bstrRoleName, varReserved, ppRole);

	public HRESULT CreateRole(BSTR bstrRoleName, VARIANT varReserved, IAzRole** ppRole) mut => VT.[Friend]CreateRole(&this, bstrRoleName, varReserved, ppRole);

	public HRESULT DeleteRole(BSTR bstrRoleName, VARIANT varReserved) mut => VT.[Friend]DeleteRole(&this, bstrRoleName, varReserved);

	public HRESULT InitializeClientContextFromToken(uint64 ullTokenHandle, VARIANT varReserved, IAzClientContext** ppClientContext) mut => VT.[Friend]InitializeClientContextFromToken(&this, ullTokenHandle, varReserved, ppClientContext);

	public HRESULT AddPropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]AddPropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT DeletePropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]DeletePropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT Submit(int32 lFlags, VARIANT varReserved) mut => VT.[Friend]Submit(&this, lFlags, varReserved);

	public HRESULT InitializeClientContextFromName(BSTR ClientName, BSTR DomainName, VARIANT varReserved, IAzClientContext** ppClientContext) mut => VT.[Friend]InitializeClientContextFromName(&this, ClientName, DomainName, varReserved, ppClientContext);

	public HRESULT get_DelegatedPolicyUsers(VARIANT* pvarDelegatedPolicyUsers) mut => VT.[Friend]get_DelegatedPolicyUsers(&this, pvarDelegatedPolicyUsers);

	public HRESULT AddDelegatedPolicyUser(BSTR bstrDelegatedPolicyUser, VARIANT varReserved) mut => VT.[Friend]AddDelegatedPolicyUser(&this, bstrDelegatedPolicyUser, varReserved);

	public HRESULT DeleteDelegatedPolicyUser(BSTR bstrDelegatedPolicyUser, VARIANT varReserved) mut => VT.[Friend]DeleteDelegatedPolicyUser(&this, bstrDelegatedPolicyUser, varReserved);

	public HRESULT InitializeClientContextFromStringSid(BSTR SidString, int32 lOptions, VARIANT varReserved, IAzClientContext** ppClientContext) mut => VT.[Friend]InitializeClientContextFromStringSid(&this, SidString, lOptions, varReserved, ppClientContext);

	public HRESULT get_PolicyAdministratorsName(VARIANT* pvarAdmins) mut => VT.[Friend]get_PolicyAdministratorsName(&this, pvarAdmins);

	public HRESULT get_PolicyReadersName(VARIANT* pvarReaders) mut => VT.[Friend]get_PolicyReadersName(&this, pvarReaders);

	public HRESULT AddPolicyAdministratorName(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]AddPolicyAdministratorName(&this, bstrAdmin, varReserved);

	public HRESULT DeletePolicyAdministratorName(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]DeletePolicyAdministratorName(&this, bstrAdmin, varReserved);

	public HRESULT AddPolicyReaderName(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]AddPolicyReaderName(&this, bstrReader, varReserved);

	public HRESULT DeletePolicyReaderName(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]DeletePolicyReaderName(&this, bstrReader, varReserved);

	public HRESULT get_DelegatedPolicyUsersName(VARIANT* pvarDelegatedPolicyUsers) mut => VT.[Friend]get_DelegatedPolicyUsersName(&this, pvarDelegatedPolicyUsers);

	public HRESULT AddDelegatedPolicyUserName(BSTR bstrDelegatedPolicyUser, VARIANT varReserved) mut => VT.[Friend]AddDelegatedPolicyUserName(&this, bstrDelegatedPolicyUser, varReserved);

	public HRESULT DeleteDelegatedPolicyUserName(BSTR bstrDelegatedPolicyUser, VARIANT varReserved) mut => VT.[Friend]DeleteDelegatedPolicyUserName(&this, bstrDelegatedPolicyUser, varReserved);
}

[CRepr]struct IAzApplication2 : IAzApplication
{
	public new const Guid IID = .(0x086a68af, 0xa249, 0x437c, 0xb1, 0x8d, 0xd4, 0xd8, 0x6d, 0x6a, 0x96, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzApplication.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulTokenHandleLowPart, uint32 ulTokenHandleHighPart, VARIANT varReserved, IAzClientContext2** ppClientContext) InitializeClientContextFromToken2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR IdentifyingString, VARIANT varReserved, IAzClientContext2** ppClientContext) InitializeClientContext2;
	}


	public HRESULT InitializeClientContextFromToken2(uint32 ulTokenHandleLowPart, uint32 ulTokenHandleHighPart, VARIANT varReserved, IAzClientContext2** ppClientContext) mut => VT.[Friend]InitializeClientContextFromToken2(&this, ulTokenHandleLowPart, ulTokenHandleHighPart, varReserved, ppClientContext);

	public HRESULT InitializeClientContext2(BSTR IdentifyingString, VARIANT varReserved, IAzClientContext2** ppClientContext) mut => VT.[Friend]InitializeClientContext2(&this, IdentifyingString, varReserved, ppClientContext);
}

[CRepr]struct IAzApplications : IDispatch
{
	public new const Guid IID = .(0x929b11a9, 0x95c5, 0x4a84, 0xa2, 0x9a, 0x20, 0xad, 0x42, 0xc2, 0xf1, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pvarObtPtr) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumPtr) get__NewEnum;
	}


	public HRESULT get_Item(int32 Index, VARIANT* pvarObtPtr) mut => VT.[Friend]get_Item(&this, Index, pvarObtPtr);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppEnumPtr) mut => VT.[Friend]get__NewEnum(&this, ppEnumPtr);
}

[CRepr]struct IAzOperation : IDispatch
{
	public new const Guid IID = .(0x5e56b24f, 0xea01, 0x4d61, 0xbe, 0x44, 0xc4, 0x9b, 0x5e, 0x4e, 0xaf, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrApplicationData) get_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationData) put_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProp) get_OperationID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lProp) put_OperationID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProp) get_Writable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, VARIANT varReserved) Submit;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrName) mut => VT.[Friend]put_Name(&this, bstrName);

	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_ApplicationData(BSTR* pbstrApplicationData) mut => VT.[Friend]get_ApplicationData(&this, pbstrApplicationData);

	public HRESULT put_ApplicationData(BSTR bstrApplicationData) mut => VT.[Friend]put_ApplicationData(&this, bstrApplicationData);

	public HRESULT get_OperationID(int32* plProp) mut => VT.[Friend]get_OperationID(&this, plProp);

	public HRESULT put_OperationID(int32 lProp) mut => VT.[Friend]put_OperationID(&this, lProp);

	public HRESULT get_Writable(BOOL* pfProp) mut => VT.[Friend]get_Writable(&this, pfProp);

	public HRESULT GetProperty(int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) mut => VT.[Friend]GetProperty(&this, lPropId, varReserved, pvarProp);

	public HRESULT SetProperty(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]SetProperty(&this, lPropId, varProp, varReserved);

	public HRESULT Submit(int32 lFlags, VARIANT varReserved) mut => VT.[Friend]Submit(&this, lFlags, varReserved);
}

[CRepr]struct IAzOperations : IDispatch
{
	public new const Guid IID = .(0x90ef9c07, 0x9706, 0x49d9, 0xaf, 0x80, 0x04, 0x38, 0xa5, 0xf3, 0xec, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pvarObtPtr) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumPtr) get__NewEnum;
	}


	public HRESULT get_Item(int32 Index, VARIANT* pvarObtPtr) mut => VT.[Friend]get_Item(&this, Index, pvarObtPtr);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppEnumPtr) mut => VT.[Friend]get__NewEnum(&this, ppEnumPtr);
}

[CRepr]struct IAzTask : IDispatch
{
	public new const Guid IID = .(0xcb94e592, 0x2e0e, 0x4a6c, 0xa3, 0x36, 0xb8, 0x9a, 0x6d, 0xc1, 0xe3, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrApplicationData) get_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationData) put_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_BizRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp) put_BizRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_BizRuleLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp) put_BizRuleLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_BizRuleImportedPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp) put_BizRuleImportedPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProp) get_IsRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fProp) put_IsRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_Operations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_Tasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOp, VARIANT varReserved) AddOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOp, VARIANT varReserved) DeleteOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTask, VARIANT varReserved) AddTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTask, VARIANT varReserved) DeleteTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProp) get_Writable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) AddPropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) DeletePropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, VARIANT varReserved) Submit;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrName) mut => VT.[Friend]put_Name(&this, bstrName);

	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_ApplicationData(BSTR* pbstrApplicationData) mut => VT.[Friend]get_ApplicationData(&this, pbstrApplicationData);

	public HRESULT put_ApplicationData(BSTR bstrApplicationData) mut => VT.[Friend]put_ApplicationData(&this, bstrApplicationData);

	public HRESULT get_BizRule(BSTR* pbstrProp) mut => VT.[Friend]get_BizRule(&this, pbstrProp);

	public HRESULT put_BizRule(BSTR bstrProp) mut => VT.[Friend]put_BizRule(&this, bstrProp);

	public HRESULT get_BizRuleLanguage(BSTR* pbstrProp) mut => VT.[Friend]get_BizRuleLanguage(&this, pbstrProp);

	public HRESULT put_BizRuleLanguage(BSTR bstrProp) mut => VT.[Friend]put_BizRuleLanguage(&this, bstrProp);

	public HRESULT get_BizRuleImportedPath(BSTR* pbstrProp) mut => VT.[Friend]get_BizRuleImportedPath(&this, pbstrProp);

	public HRESULT put_BizRuleImportedPath(BSTR bstrProp) mut => VT.[Friend]put_BizRuleImportedPath(&this, bstrProp);

	public HRESULT get_IsRoleDefinition(BOOL* pfProp) mut => VT.[Friend]get_IsRoleDefinition(&this, pfProp);

	public HRESULT put_IsRoleDefinition(BOOL fProp) mut => VT.[Friend]put_IsRoleDefinition(&this, fProp);

	public HRESULT get_Operations(VARIANT* pvarProp) mut => VT.[Friend]get_Operations(&this, pvarProp);

	public HRESULT get_Tasks(VARIANT* pvarProp) mut => VT.[Friend]get_Tasks(&this, pvarProp);

	public HRESULT AddOperation(BSTR bstrOp, VARIANT varReserved) mut => VT.[Friend]AddOperation(&this, bstrOp, varReserved);

	public HRESULT DeleteOperation(BSTR bstrOp, VARIANT varReserved) mut => VT.[Friend]DeleteOperation(&this, bstrOp, varReserved);

	public HRESULT AddTask(BSTR bstrTask, VARIANT varReserved) mut => VT.[Friend]AddTask(&this, bstrTask, varReserved);

	public HRESULT DeleteTask(BSTR bstrTask, VARIANT varReserved) mut => VT.[Friend]DeleteTask(&this, bstrTask, varReserved);

	public HRESULT get_Writable(BOOL* pfProp) mut => VT.[Friend]get_Writable(&this, pfProp);

	public HRESULT GetProperty(int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) mut => VT.[Friend]GetProperty(&this, lPropId, varReserved, pvarProp);

	public HRESULT SetProperty(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]SetProperty(&this, lPropId, varProp, varReserved);

	public HRESULT AddPropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]AddPropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT DeletePropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]DeletePropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT Submit(int32 lFlags, VARIANT varReserved) mut => VT.[Friend]Submit(&this, lFlags, varReserved);
}

[CRepr]struct IAzTasks : IDispatch
{
	public new const Guid IID = .(0xb338ccab, 0x4c85, 0x4388, 0x8c, 0x0a, 0xc5, 0x85, 0x92, 0xba, 0xd3, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pvarObtPtr) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumPtr) get__NewEnum;
	}


	public HRESULT get_Item(int32 Index, VARIANT* pvarObtPtr) mut => VT.[Friend]get_Item(&this, Index, pvarObtPtr);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppEnumPtr) mut => VT.[Friend]get__NewEnum(&this, ppEnumPtr);
}

[CRepr]struct IAzScope : IDispatch
{
	public new const Guid IID = .(0x00e52487, 0xe08d, 0x4514, 0xb6, 0x2e, 0x87, 0x7d, 0x56, 0x45, 0xf5, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrApplicationData) get_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationData) put_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProp) get_Writable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) AddPropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) DeletePropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarAdmins) get_PolicyAdministrators;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarReaders) get_PolicyReaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) AddPolicyAdministrator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) DeletePolicyAdministrator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) AddPolicyReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) DeletePolicyReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzApplicationGroups** ppGroupCollection) get_ApplicationGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) OpenApplicationGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) CreateApplicationGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName, VARIANT varReserved) DeleteApplicationGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzRoles** ppRoleCollection) get_Roles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleName, VARIANT varReserved, IAzRole** ppRole) OpenRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleName, VARIANT varReserved, IAzRole** ppRole) CreateRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleName, VARIANT varReserved) DeleteRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzTasks** ppTaskCollection) get_Tasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTaskName, VARIANT varReserved, IAzTask** ppTask) OpenTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTaskName, VARIANT varReserved, IAzTask** ppTask) CreateTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTaskName, VARIANT varReserved) DeleteTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, VARIANT varReserved) Submit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProp) get_CanBeDelegated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProp) get_BizrulesWritable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarAdmins) get_PolicyAdministratorsName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarReaders) get_PolicyReadersName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) AddPolicyAdministratorName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAdmin, VARIANT varReserved) DeletePolicyAdministratorName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) AddPolicyReaderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrReader, VARIANT varReserved) DeletePolicyReaderName;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrName) mut => VT.[Friend]put_Name(&this, bstrName);

	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_ApplicationData(BSTR* pbstrApplicationData) mut => VT.[Friend]get_ApplicationData(&this, pbstrApplicationData);

	public HRESULT put_ApplicationData(BSTR bstrApplicationData) mut => VT.[Friend]put_ApplicationData(&this, bstrApplicationData);

	public HRESULT get_Writable(BOOL* pfProp) mut => VT.[Friend]get_Writable(&this, pfProp);

	public HRESULT GetProperty(int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) mut => VT.[Friend]GetProperty(&this, lPropId, varReserved, pvarProp);

	public HRESULT SetProperty(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]SetProperty(&this, lPropId, varProp, varReserved);

	public HRESULT AddPropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]AddPropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT DeletePropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]DeletePropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT get_PolicyAdministrators(VARIANT* pvarAdmins) mut => VT.[Friend]get_PolicyAdministrators(&this, pvarAdmins);

	public HRESULT get_PolicyReaders(VARIANT* pvarReaders) mut => VT.[Friend]get_PolicyReaders(&this, pvarReaders);

	public HRESULT AddPolicyAdministrator(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]AddPolicyAdministrator(&this, bstrAdmin, varReserved);

	public HRESULT DeletePolicyAdministrator(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]DeletePolicyAdministrator(&this, bstrAdmin, varReserved);

	public HRESULT AddPolicyReader(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]AddPolicyReader(&this, bstrReader, varReserved);

	public HRESULT DeletePolicyReader(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]DeletePolicyReader(&this, bstrReader, varReserved);

	public HRESULT get_ApplicationGroups(IAzApplicationGroups** ppGroupCollection) mut => VT.[Friend]get_ApplicationGroups(&this, ppGroupCollection);

	public HRESULT OpenApplicationGroup(BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) mut => VT.[Friend]OpenApplicationGroup(&this, bstrGroupName, varReserved, ppGroup);

	public HRESULT CreateApplicationGroup(BSTR bstrGroupName, VARIANT varReserved, IAzApplicationGroup** ppGroup) mut => VT.[Friend]CreateApplicationGroup(&this, bstrGroupName, varReserved, ppGroup);

	public HRESULT DeleteApplicationGroup(BSTR bstrGroupName, VARIANT varReserved) mut => VT.[Friend]DeleteApplicationGroup(&this, bstrGroupName, varReserved);

	public HRESULT get_Roles(IAzRoles** ppRoleCollection) mut => VT.[Friend]get_Roles(&this, ppRoleCollection);

	public HRESULT OpenRole(BSTR bstrRoleName, VARIANT varReserved, IAzRole** ppRole) mut => VT.[Friend]OpenRole(&this, bstrRoleName, varReserved, ppRole);

	public HRESULT CreateRole(BSTR bstrRoleName, VARIANT varReserved, IAzRole** ppRole) mut => VT.[Friend]CreateRole(&this, bstrRoleName, varReserved, ppRole);

	public HRESULT DeleteRole(BSTR bstrRoleName, VARIANT varReserved) mut => VT.[Friend]DeleteRole(&this, bstrRoleName, varReserved);

	public HRESULT get_Tasks(IAzTasks** ppTaskCollection) mut => VT.[Friend]get_Tasks(&this, ppTaskCollection);

	public HRESULT OpenTask(BSTR bstrTaskName, VARIANT varReserved, IAzTask** ppTask) mut => VT.[Friend]OpenTask(&this, bstrTaskName, varReserved, ppTask);

	public HRESULT CreateTask(BSTR bstrTaskName, VARIANT varReserved, IAzTask** ppTask) mut => VT.[Friend]CreateTask(&this, bstrTaskName, varReserved, ppTask);

	public HRESULT DeleteTask(BSTR bstrTaskName, VARIANT varReserved) mut => VT.[Friend]DeleteTask(&this, bstrTaskName, varReserved);

	public HRESULT Submit(int32 lFlags, VARIANT varReserved) mut => VT.[Friend]Submit(&this, lFlags, varReserved);

	public HRESULT get_CanBeDelegated(BOOL* pfProp) mut => VT.[Friend]get_CanBeDelegated(&this, pfProp);

	public HRESULT get_BizrulesWritable(BOOL* pfProp) mut => VT.[Friend]get_BizrulesWritable(&this, pfProp);

	public HRESULT get_PolicyAdministratorsName(VARIANT* pvarAdmins) mut => VT.[Friend]get_PolicyAdministratorsName(&this, pvarAdmins);

	public HRESULT get_PolicyReadersName(VARIANT* pvarReaders) mut => VT.[Friend]get_PolicyReadersName(&this, pvarReaders);

	public HRESULT AddPolicyAdministratorName(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]AddPolicyAdministratorName(&this, bstrAdmin, varReserved);

	public HRESULT DeletePolicyAdministratorName(BSTR bstrAdmin, VARIANT varReserved) mut => VT.[Friend]DeletePolicyAdministratorName(&this, bstrAdmin, varReserved);

	public HRESULT AddPolicyReaderName(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]AddPolicyReaderName(&this, bstrReader, varReserved);

	public HRESULT DeletePolicyReaderName(BSTR bstrReader, VARIANT varReserved) mut => VT.[Friend]DeletePolicyReaderName(&this, bstrReader, varReserved);
}

[CRepr]struct IAzScopes : IDispatch
{
	public new const Guid IID = .(0x78e14853, 0x9f5e, 0x406d, 0x9b, 0x91, 0x6b, 0xdb, 0xa6, 0x97, 0x35, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pvarObtPtr) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumPtr) get__NewEnum;
	}


	public HRESULT get_Item(int32 Index, VARIANT* pvarObtPtr) mut => VT.[Friend]get_Item(&this, Index, pvarObtPtr);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppEnumPtr) mut => VT.[Friend]get__NewEnum(&this, ppEnumPtr);
}

[CRepr]struct IAzApplicationGroup : IDispatch
{
	public new const Guid IID = .(0xf1b744cd, 0x58a6, 0x4e06, 0x9f, 0xbf, 0x36, 0xf6, 0xd7, 0x79, 0xe2, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProp) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lProp) put_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_LdapQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp) put_LdapQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_AppMembers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_AppNonMembers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_Members;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_NonMembers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddAppMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteAppMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddAppNonMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteAppNonMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddNonMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteNonMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProp) get_Writable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) AddPropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) DeletePropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, VARIANT varReserved) Submit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddMemberName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteMemberName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddNonMemberName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteNonMemberName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_MembersName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_NonMembersName;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrName) mut => VT.[Friend]put_Name(&this, bstrName);

	public HRESULT get_Type(int32* plProp) mut => VT.[Friend]get_Type(&this, plProp);

	public HRESULT put_Type(int32 lProp) mut => VT.[Friend]put_Type(&this, lProp);

	public HRESULT get_LdapQuery(BSTR* pbstrProp) mut => VT.[Friend]get_LdapQuery(&this, pbstrProp);

	public HRESULT put_LdapQuery(BSTR bstrProp) mut => VT.[Friend]put_LdapQuery(&this, bstrProp);

	public HRESULT get_AppMembers(VARIANT* pvarProp) mut => VT.[Friend]get_AppMembers(&this, pvarProp);

	public HRESULT get_AppNonMembers(VARIANT* pvarProp) mut => VT.[Friend]get_AppNonMembers(&this, pvarProp);

	public HRESULT get_Members(VARIANT* pvarProp) mut => VT.[Friend]get_Members(&this, pvarProp);

	public HRESULT get_NonMembers(VARIANT* pvarProp) mut => VT.[Friend]get_NonMembers(&this, pvarProp);

	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT AddAppMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddAppMember(&this, bstrProp, varReserved);

	public HRESULT DeleteAppMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteAppMember(&this, bstrProp, varReserved);

	public HRESULT AddAppNonMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddAppNonMember(&this, bstrProp, varReserved);

	public HRESULT DeleteAppNonMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteAppNonMember(&this, bstrProp, varReserved);

	public HRESULT AddMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddMember(&this, bstrProp, varReserved);

	public HRESULT DeleteMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteMember(&this, bstrProp, varReserved);

	public HRESULT AddNonMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddNonMember(&this, bstrProp, varReserved);

	public HRESULT DeleteNonMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteNonMember(&this, bstrProp, varReserved);

	public HRESULT get_Writable(BOOL* pfProp) mut => VT.[Friend]get_Writable(&this, pfProp);

	public HRESULT GetProperty(int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) mut => VT.[Friend]GetProperty(&this, lPropId, varReserved, pvarProp);

	public HRESULT SetProperty(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]SetProperty(&this, lPropId, varProp, varReserved);

	public HRESULT AddPropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]AddPropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT DeletePropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]DeletePropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT Submit(int32 lFlags, VARIANT varReserved) mut => VT.[Friend]Submit(&this, lFlags, varReserved);

	public HRESULT AddMemberName(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddMemberName(&this, bstrProp, varReserved);

	public HRESULT DeleteMemberName(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteMemberName(&this, bstrProp, varReserved);

	public HRESULT AddNonMemberName(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddNonMemberName(&this, bstrProp, varReserved);

	public HRESULT DeleteNonMemberName(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteNonMemberName(&this, bstrProp, varReserved);

	public HRESULT get_MembersName(VARIANT* pvarProp) mut => VT.[Friend]get_MembersName(&this, pvarProp);

	public HRESULT get_NonMembersName(VARIANT* pvarProp) mut => VT.[Friend]get_NonMembersName(&this, pvarProp);
}

[CRepr]struct IAzApplicationGroups : IDispatch
{
	public new const Guid IID = .(0x4ce66ad5, 0x9f3c, 0x469d, 0xa9, 0x11, 0xb9, 0x98, 0x87, 0xa7, 0xe6, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pvarObtPtr) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumPtr) get__NewEnum;
	}


	public HRESULT get_Item(int32 Index, VARIANT* pvarObtPtr) mut => VT.[Friend]get_Item(&this, Index, pvarObtPtr);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppEnumPtr) mut => VT.[Friend]get__NewEnum(&this, ppEnumPtr);
}

[CRepr]struct IAzRole : IDispatch
{
	public new const Guid IID = .(0x859e0d8d, 0x62d7, 0x41d8, 0xa0, 0x34, 0xc0, 0xcd, 0x5d, 0x43, 0xfd, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrApplicationData) get_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrApplicationData) put_ApplicationData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddAppMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteAppMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfProp) get_Writable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_AppMembers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_Members;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_Operations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_Tasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) AddPropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varProp, VARIANT varReserved) DeletePropertyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, VARIANT varReserved) Submit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) AddMemberName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp, VARIANT varReserved) DeleteMemberName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarProp) get_MembersName;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrName) mut => VT.[Friend]put_Name(&this, bstrName);

	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_ApplicationData(BSTR* pbstrApplicationData) mut => VT.[Friend]get_ApplicationData(&this, pbstrApplicationData);

	public HRESULT put_ApplicationData(BSTR bstrApplicationData) mut => VT.[Friend]put_ApplicationData(&this, bstrApplicationData);

	public HRESULT AddAppMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddAppMember(&this, bstrProp, varReserved);

	public HRESULT DeleteAppMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteAppMember(&this, bstrProp, varReserved);

	public HRESULT AddTask(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddTask(&this, bstrProp, varReserved);

	public HRESULT DeleteTask(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteTask(&this, bstrProp, varReserved);

	public HRESULT AddOperation(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddOperation(&this, bstrProp, varReserved);

	public HRESULT DeleteOperation(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteOperation(&this, bstrProp, varReserved);

	public HRESULT AddMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddMember(&this, bstrProp, varReserved);

	public HRESULT DeleteMember(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteMember(&this, bstrProp, varReserved);

	public HRESULT get_Writable(BOOL* pfProp) mut => VT.[Friend]get_Writable(&this, pfProp);

	public HRESULT GetProperty(int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) mut => VT.[Friend]GetProperty(&this, lPropId, varReserved, pvarProp);

	public HRESULT SetProperty(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]SetProperty(&this, lPropId, varProp, varReserved);

	public HRESULT get_AppMembers(VARIANT* pvarProp) mut => VT.[Friend]get_AppMembers(&this, pvarProp);

	public HRESULT get_Members(VARIANT* pvarProp) mut => VT.[Friend]get_Members(&this, pvarProp);

	public HRESULT get_Operations(VARIANT* pvarProp) mut => VT.[Friend]get_Operations(&this, pvarProp);

	public HRESULT get_Tasks(VARIANT* pvarProp) mut => VT.[Friend]get_Tasks(&this, pvarProp);

	public HRESULT AddPropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]AddPropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT DeletePropertyItem(int32 lPropId, VARIANT varProp, VARIANT varReserved) mut => VT.[Friend]DeletePropertyItem(&this, lPropId, varProp, varReserved);

	public HRESULT Submit(int32 lFlags, VARIANT varReserved) mut => VT.[Friend]Submit(&this, lFlags, varReserved);

	public HRESULT AddMemberName(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]AddMemberName(&this, bstrProp, varReserved);

	public HRESULT DeleteMemberName(BSTR bstrProp, VARIANT varReserved) mut => VT.[Friend]DeleteMemberName(&this, bstrProp, varReserved);

	public HRESULT get_MembersName(VARIANT* pvarProp) mut => VT.[Friend]get_MembersName(&this, pvarProp);
}

[CRepr]struct IAzRoles : IDispatch
{
	public new const Guid IID = .(0x95e0f119, 0x13b4, 0x4dae, 0xb6, 0x5f, 0x2f, 0x7d, 0x60, 0xd8, 0x22, 0xe4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pvarObtPtr) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumPtr) get__NewEnum;
	}


	public HRESULT get_Item(int32 Index, VARIANT* pvarObtPtr) mut => VT.[Friend]get_Item(&this, Index, pvarObtPtr);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppEnumPtr) mut => VT.[Friend]get__NewEnum(&this, ppEnumPtr);
}

[CRepr]struct IAzClientContext : IDispatch
{
	public new const Guid IID = .(0xeff1f00b, 0x488a, 0x466d, 0xaf, 0xd9, 0xa4, 0x01, 0xc5, 0xf9, 0xee, 0xf5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrObjectName, VARIANT varScopeNames, VARIANT varOperations, VARIANT varParameterNames, VARIANT varParameterValues, VARIANT varInterfaceNames, VARIANT varInterfaceFlags, VARIANT varInterfaces, VARIANT* pvarResults) AccessCheck;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBusinessRuleString) GetBusinessRuleString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_UserDn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_UserSamCompat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_UserDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_UserGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_UserCanonical;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_UserUpn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_UserDnsSamCompat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, VARIANT* pvarRoleNames) GetRoles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_RoleForAccessCheck;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp) put_RoleForAccessCheck;
	}


	public HRESULT AccessCheck(BSTR bstrObjectName, VARIANT varScopeNames, VARIANT varOperations, VARIANT varParameterNames, VARIANT varParameterValues, VARIANT varInterfaceNames, VARIANT varInterfaceFlags, VARIANT varInterfaces, VARIANT* pvarResults) mut => VT.[Friend]AccessCheck(&this, bstrObjectName, varScopeNames, varOperations, varParameterNames, varParameterValues, varInterfaceNames, varInterfaceFlags, varInterfaces, pvarResults);

	public HRESULT GetBusinessRuleString(BSTR* pbstrBusinessRuleString) mut => VT.[Friend]GetBusinessRuleString(&this, pbstrBusinessRuleString);

	public HRESULT get_UserDn(BSTR* pbstrProp) mut => VT.[Friend]get_UserDn(&this, pbstrProp);

	public HRESULT get_UserSamCompat(BSTR* pbstrProp) mut => VT.[Friend]get_UserSamCompat(&this, pbstrProp);

	public HRESULT get_UserDisplay(BSTR* pbstrProp) mut => VT.[Friend]get_UserDisplay(&this, pbstrProp);

	public HRESULT get_UserGuid(BSTR* pbstrProp) mut => VT.[Friend]get_UserGuid(&this, pbstrProp);

	public HRESULT get_UserCanonical(BSTR* pbstrProp) mut => VT.[Friend]get_UserCanonical(&this, pbstrProp);

	public HRESULT get_UserUpn(BSTR* pbstrProp) mut => VT.[Friend]get_UserUpn(&this, pbstrProp);

	public HRESULT get_UserDnsSamCompat(BSTR* pbstrProp) mut => VT.[Friend]get_UserDnsSamCompat(&this, pbstrProp);

	public HRESULT GetProperty(int32 lPropId, VARIANT varReserved, VARIANT* pvarProp) mut => VT.[Friend]GetProperty(&this, lPropId, varReserved, pvarProp);

	public HRESULT GetRoles(BSTR bstrScopeName, VARIANT* pvarRoleNames) mut => VT.[Friend]GetRoles(&this, bstrScopeName, pvarRoleNames);

	public HRESULT get_RoleForAccessCheck(BSTR* pbstrProp) mut => VT.[Friend]get_RoleForAccessCheck(&this, pbstrProp);

	public HRESULT put_RoleForAccessCheck(BSTR bstrProp) mut => VT.[Friend]put_RoleForAccessCheck(&this, bstrProp);
}

[CRepr]struct IAzClientContext2 : IAzClientContext
{
	public new const Guid IID = .(0x2b0c92b8, 0x208a, 0x488a, 0x8f, 0x81, 0xe4, 0xed, 0xb2, 0x21, 0x11, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzClientContext.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lOptions, int32 PageSize, VARIANT* pvarCursor, VARIANT* pvarScopeNames) GetAssignedScopesPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varRoles, BSTR bstrScopeName) AddRoles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varApplicationGroups) AddApplicationGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varStringSids) AddStringSids;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLDAPQueryDN) put_LDAPQueryDN;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLDAPQueryDN) get_LDAPQueryDN;
	}


	public HRESULT GetAssignedScopesPage(int32 lOptions, int32 PageSize, VARIANT* pvarCursor, VARIANT* pvarScopeNames) mut => VT.[Friend]GetAssignedScopesPage(&this, lOptions, PageSize, pvarCursor, pvarScopeNames);

	public HRESULT AddRoles(VARIANT varRoles, BSTR bstrScopeName) mut => VT.[Friend]AddRoles(&this, varRoles, bstrScopeName);

	public HRESULT AddApplicationGroups(VARIANT varApplicationGroups) mut => VT.[Friend]AddApplicationGroups(&this, varApplicationGroups);

	public HRESULT AddStringSids(VARIANT varStringSids) mut => VT.[Friend]AddStringSids(&this, varStringSids);

	public HRESULT put_LDAPQueryDN(BSTR bstrLDAPQueryDN) mut => VT.[Friend]put_LDAPQueryDN(&this, bstrLDAPQueryDN);

	public HRESULT get_LDAPQueryDN(BSTR* pbstrLDAPQueryDN) mut => VT.[Friend]get_LDAPQueryDN(&this, pbstrLDAPQueryDN);
}

[CRepr]struct IAzBizRuleContext : IDispatch
{
	public new const Guid IID = .(0xe192f17d, 0xd59f, 0x455e, 0xa1, 0x52, 0x94, 0x03, 0x16, 0xcd, 0x77, 0xb2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bResult) put_BusinessRuleResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBusinessRuleString) put_BusinessRuleString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBusinessRuleString) get_BusinessRuleString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrParameterName, VARIANT* pvarParameterValue) GetParameter;
	}


	public HRESULT put_BusinessRuleResult(BOOL bResult) mut => VT.[Friend]put_BusinessRuleResult(&this, bResult);

	public HRESULT put_BusinessRuleString(BSTR bstrBusinessRuleString) mut => VT.[Friend]put_BusinessRuleString(&this, bstrBusinessRuleString);

	public HRESULT get_BusinessRuleString(BSTR* pbstrBusinessRuleString) mut => VT.[Friend]get_BusinessRuleString(&this, pbstrBusinessRuleString);

	public HRESULT GetParameter(BSTR bstrParameterName, VARIANT* pvarParameterValue) mut => VT.[Friend]GetParameter(&this, bstrParameterName, pvarParameterValue);
}

[CRepr]struct IAzBizRuleParameters : IDispatch
{
	public new const Guid IID = .(0xfc17685f, 0xe25d, 0x4dcd, 0xba, 0xe1, 0x27, 0x6e, 0xc9, 0x53, 0x3c, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrParameterName, VARIANT varParameterValue) AddParameter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varParameterNames, VARIANT varParameterValues) AddParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrParameterName, VARIANT* pvarParameterValue) GetParameterValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR varParameterName) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* plCount) get_Count;
	}


	public HRESULT AddParameter(BSTR bstrParameterName, VARIANT varParameterValue) mut => VT.[Friend]AddParameter(&this, bstrParameterName, varParameterValue);

	public HRESULT AddParameters(VARIANT varParameterNames, VARIANT varParameterValues) mut => VT.[Friend]AddParameters(&this, varParameterNames, varParameterValues);

	public HRESULT GetParameterValue(BSTR bstrParameterName, VARIANT* pvarParameterValue) mut => VT.[Friend]GetParameterValue(&this, bstrParameterName, pvarParameterValue);

	public HRESULT Remove(BSTR varParameterName) mut => VT.[Friend]Remove(&this, varParameterName);

	public HRESULT RemoveAll() mut => VT.[Friend]RemoveAll(&this);

	public HRESULT get_Count(uint32* plCount) mut => VT.[Friend]get_Count(&this, plCount);
}

[CRepr]struct IAzBizRuleInterfaces : IDispatch
{
	public new const Guid IID = .(0xe94128c7, 0xe9da, 0x44cc, 0xb0, 0xbd, 0x53, 0x03, 0x6f, 0x3a, 0xab, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInterfaceName, int32 lInterfaceFlag, VARIANT varInterface) AddInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varInterfaceNames, VARIANT varInterfaceFlags, VARIANT varInterfaces) AddInterfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInterfaceName, int32* lInterfaceFlag, VARIANT* varInterface) GetInterfaceValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInterfaceName) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* plCount) get_Count;
	}


	public HRESULT AddInterface(BSTR bstrInterfaceName, int32 lInterfaceFlag, VARIANT varInterface) mut => VT.[Friend]AddInterface(&this, bstrInterfaceName, lInterfaceFlag, varInterface);

	public HRESULT AddInterfaces(VARIANT varInterfaceNames, VARIANT varInterfaceFlags, VARIANT varInterfaces) mut => VT.[Friend]AddInterfaces(&this, varInterfaceNames, varInterfaceFlags, varInterfaces);

	public HRESULT GetInterfaceValue(BSTR bstrInterfaceName, int32* lInterfaceFlag, VARIANT* varInterface) mut => VT.[Friend]GetInterfaceValue(&this, bstrInterfaceName, lInterfaceFlag, varInterface);

	public HRESULT Remove(BSTR bstrInterfaceName) mut => VT.[Friend]Remove(&this, bstrInterfaceName);

	public HRESULT RemoveAll() mut => VT.[Friend]RemoveAll(&this);

	public HRESULT get_Count(uint32* plCount) mut => VT.[Friend]get_Count(&this, plCount);
}

[CRepr]struct IAzClientContext3 : IAzClientContext2
{
	public new const Guid IID = .(0x11894fde, 0x1deb, 0x4b4b, 0x89, 0x07, 0x6d, 0x1c, 0xda, 0x1f, 0x5d, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzClientContext2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrObjectName, BSTR bstrScopeName, int32 lOperation, uint32* plResult) AccessCheck2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, BSTR bstrRoleName, int16* pbIsInRole) IsInRoleAssignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, IAzOperations** ppOperationCollection) GetOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, IAzTasks** ppTaskCollection) GetTasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzBizRuleParameters** ppBizRuleParam) get_BizRuleParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzBizRuleInterfaces** ppBizRuleInterfaces) get_BizRuleInterfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, AZ_PROP_CONSTANTS ulOptions, VARIANT* pGroupArray) GetGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pStringSidArray) get_Sids;
	}


	public HRESULT AccessCheck2(BSTR bstrObjectName, BSTR bstrScopeName, int32 lOperation, uint32* plResult) mut => VT.[Friend]AccessCheck2(&this, bstrObjectName, bstrScopeName, lOperation, plResult);

	public HRESULT IsInRoleAssignment(BSTR bstrScopeName, BSTR bstrRoleName, int16* pbIsInRole) mut => VT.[Friend]IsInRoleAssignment(&this, bstrScopeName, bstrRoleName, pbIsInRole);

	public HRESULT GetOperations(BSTR bstrScopeName, IAzOperations** ppOperationCollection) mut => VT.[Friend]GetOperations(&this, bstrScopeName, ppOperationCollection);

	public HRESULT GetTasks(BSTR bstrScopeName, IAzTasks** ppTaskCollection) mut => VT.[Friend]GetTasks(&this, bstrScopeName, ppTaskCollection);

	public HRESULT get_BizRuleParameters(IAzBizRuleParameters** ppBizRuleParam) mut => VT.[Friend]get_BizRuleParameters(&this, ppBizRuleParam);

	public HRESULT get_BizRuleInterfaces(IAzBizRuleInterfaces** ppBizRuleInterfaces) mut => VT.[Friend]get_BizRuleInterfaces(&this, ppBizRuleInterfaces);

	public HRESULT GetGroups(BSTR bstrScopeName, AZ_PROP_CONSTANTS ulOptions, VARIANT* pGroupArray) mut => VT.[Friend]GetGroups(&this, bstrScopeName, ulOptions, pGroupArray);

	public HRESULT get_Sids(VARIANT* pStringSidArray) mut => VT.[Friend]get_Sids(&this, pStringSidArray);
}

[CRepr]struct IAzScope2 : IAzScope
{
	public new const Guid IID = .(0xee9fe8c9, 0xc9f3, 0x40e2, 0xaa, 0x12, 0xd1, 0xd8, 0x59, 0x97, 0x27, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzScope.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzRoleDefinitions** ppRoleDefinitions) get_RoleDefinitions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleDefinitionName, IAzRoleDefinition** ppRoleDefinitions) CreateRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleDefinitionName, IAzRoleDefinition** ppRoleDefinitions) OpenRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleDefinitionName) DeleteRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzRoleAssignments** ppRoleAssignments) get_RoleAssignments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleAssignmentName, IAzRoleAssignment** ppRoleAssignment) CreateRoleAssignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleAssignmentName, IAzRoleAssignment** ppRoleAssignment) OpenRoleAssignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleAssignmentName) DeleteRoleAssignment;
	}


	public HRESULT get_RoleDefinitions(IAzRoleDefinitions** ppRoleDefinitions) mut => VT.[Friend]get_RoleDefinitions(&this, ppRoleDefinitions);

	public HRESULT CreateRoleDefinition(BSTR bstrRoleDefinitionName, IAzRoleDefinition** ppRoleDefinitions) mut => VT.[Friend]CreateRoleDefinition(&this, bstrRoleDefinitionName, ppRoleDefinitions);

	public HRESULT OpenRoleDefinition(BSTR bstrRoleDefinitionName, IAzRoleDefinition** ppRoleDefinitions) mut => VT.[Friend]OpenRoleDefinition(&this, bstrRoleDefinitionName, ppRoleDefinitions);

	public HRESULT DeleteRoleDefinition(BSTR bstrRoleDefinitionName) mut => VT.[Friend]DeleteRoleDefinition(&this, bstrRoleDefinitionName);

	public HRESULT get_RoleAssignments(IAzRoleAssignments** ppRoleAssignments) mut => VT.[Friend]get_RoleAssignments(&this, ppRoleAssignments);

	public HRESULT CreateRoleAssignment(BSTR bstrRoleAssignmentName, IAzRoleAssignment** ppRoleAssignment) mut => VT.[Friend]CreateRoleAssignment(&this, bstrRoleAssignmentName, ppRoleAssignment);

	public HRESULT OpenRoleAssignment(BSTR bstrRoleAssignmentName, IAzRoleAssignment** ppRoleAssignment) mut => VT.[Friend]OpenRoleAssignment(&this, bstrRoleAssignmentName, ppRoleAssignment);

	public HRESULT DeleteRoleAssignment(BSTR bstrRoleAssignmentName) mut => VT.[Friend]DeleteRoleAssignment(&this, bstrRoleAssignmentName);
}

[CRepr]struct IAzApplication3 : IAzApplication2
{
	public new const Guid IID = .(0x181c845e, 0x7196, 0x4a7d, 0xac, 0x2e, 0x02, 0x0c, 0x0b, 0xb7, 0xa3, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzApplication2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, int16* pbExist) ScopeExists;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, IAzScope2** ppScope2) OpenScope2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, IAzScope2** ppScope2) CreateScope2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName) DeleteScope2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzRoleDefinitions** ppRoleDefinitions) get_RoleDefinitions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleDefinitionName, IAzRoleDefinition** ppRoleDefinitions) CreateRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleDefinitionName, IAzRoleDefinition** ppRoleDefinitions) OpenRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleDefinitionName) DeleteRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzRoleAssignments** ppRoleAssignments) get_RoleAssignments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleAssignmentName, IAzRoleAssignment** ppRoleAssignment) CreateRoleAssignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleAssignmentName, IAzRoleAssignment** ppRoleAssignment) OpenRoleAssignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleAssignmentName) DeleteRoleAssignment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_BizRulesEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_BizRulesEnabled;
	}


	public HRESULT ScopeExists(BSTR bstrScopeName, int16* pbExist) mut => VT.[Friend]ScopeExists(&this, bstrScopeName, pbExist);

	public HRESULT OpenScope2(BSTR bstrScopeName, IAzScope2** ppScope2) mut => VT.[Friend]OpenScope2(&this, bstrScopeName, ppScope2);

	public HRESULT CreateScope2(BSTR bstrScopeName, IAzScope2** ppScope2) mut => VT.[Friend]CreateScope2(&this, bstrScopeName, ppScope2);

	public HRESULT DeleteScope2(BSTR bstrScopeName) mut => VT.[Friend]DeleteScope2(&this, bstrScopeName);

	public HRESULT get_RoleDefinitions(IAzRoleDefinitions** ppRoleDefinitions) mut => VT.[Friend]get_RoleDefinitions(&this, ppRoleDefinitions);

	public HRESULT CreateRoleDefinition(BSTR bstrRoleDefinitionName, IAzRoleDefinition** ppRoleDefinitions) mut => VT.[Friend]CreateRoleDefinition(&this, bstrRoleDefinitionName, ppRoleDefinitions);

	public HRESULT OpenRoleDefinition(BSTR bstrRoleDefinitionName, IAzRoleDefinition** ppRoleDefinitions) mut => VT.[Friend]OpenRoleDefinition(&this, bstrRoleDefinitionName, ppRoleDefinitions);

	public HRESULT DeleteRoleDefinition(BSTR bstrRoleDefinitionName) mut => VT.[Friend]DeleteRoleDefinition(&this, bstrRoleDefinitionName);

	public HRESULT get_RoleAssignments(IAzRoleAssignments** ppRoleAssignments) mut => VT.[Friend]get_RoleAssignments(&this, ppRoleAssignments);

	public HRESULT CreateRoleAssignment(BSTR bstrRoleAssignmentName, IAzRoleAssignment** ppRoleAssignment) mut => VT.[Friend]CreateRoleAssignment(&this, bstrRoleAssignmentName, ppRoleAssignment);

	public HRESULT OpenRoleAssignment(BSTR bstrRoleAssignmentName, IAzRoleAssignment** ppRoleAssignment) mut => VT.[Friend]OpenRoleAssignment(&this, bstrRoleAssignmentName, ppRoleAssignment);

	public HRESULT DeleteRoleAssignment(BSTR bstrRoleAssignmentName) mut => VT.[Friend]DeleteRoleAssignment(&this, bstrRoleAssignmentName);

	public HRESULT get_BizRulesEnabled(int16* pbEnabled) mut => VT.[Friend]get_BizRulesEnabled(&this, pbEnabled);

	public HRESULT put_BizRulesEnabled(int16 bEnabled) mut => VT.[Friend]put_BizRulesEnabled(&this, bEnabled);
}

[CRepr]struct IAzOperation2 : IAzOperation
{
	public new const Guid IID = .(0x1f5ea01f, 0x44a2, 0x4184, 0x9c, 0x48, 0xa7, 0x5b, 0x4d, 0xcc, 0x8c, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzOperation.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, int16 bRecursive, IAzRoleAssignments** ppRoleAssignments) RoleAssignments;
	}


	public HRESULT RoleAssignments(BSTR bstrScopeName, int16 bRecursive, IAzRoleAssignments** ppRoleAssignments) mut => VT.[Friend]RoleAssignments(&this, bstrScopeName, bRecursive, ppRoleAssignments);
}

[CRepr]struct IAzRoleDefinitions : IDispatch
{
	public new const Guid IID = .(0x881f25a5, 0xd755, 0x4550, 0x95, 0x7a, 0xd5, 0x03, 0xa3, 0xb3, 0x40, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pvarObtPtr) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumPtr) get__NewEnum;
	}


	public HRESULT get_Item(int32 Index, VARIANT* pvarObtPtr) mut => VT.[Friend]get_Item(&this, Index, pvarObtPtr);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppEnumPtr) mut => VT.[Friend]get__NewEnum(&this, ppEnumPtr);
}

[CRepr]struct IAzRoleDefinition : IAzTask
{
	public new const Guid IID = .(0xd97fcea1, 0x2599, 0x44f1, 0x9f, 0xc3, 0x58, 0xe9, 0xfb, 0xe0, 0x94, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzTask.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, int16 bRecursive, IAzRoleAssignments** ppRoleAssignments) RoleAssignments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleDefinition) AddRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleDefinition) DeleteRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzRoleDefinitions** ppRoleDefinitions) get_RoleDefinitions;
	}


	public HRESULT RoleAssignments(BSTR bstrScopeName, int16 bRecursive, IAzRoleAssignments** ppRoleAssignments) mut => VT.[Friend]RoleAssignments(&this, bstrScopeName, bRecursive, ppRoleAssignments);

	public HRESULT AddRoleDefinition(BSTR bstrRoleDefinition) mut => VT.[Friend]AddRoleDefinition(&this, bstrRoleDefinition);

	public HRESULT DeleteRoleDefinition(BSTR bstrRoleDefinition) mut => VT.[Friend]DeleteRoleDefinition(&this, bstrRoleDefinition);

	public HRESULT get_RoleDefinitions(IAzRoleDefinitions** ppRoleDefinitions) mut => VT.[Friend]get_RoleDefinitions(&this, ppRoleDefinitions);
}

[CRepr]struct IAzRoleAssignment : IAzRole
{
	public new const Guid IID = .(0x55647d31, 0x0d5a, 0x4fa3, 0xb4, 0xac, 0x2b, 0x5f, 0x9a, 0xd5, 0xab, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzRole.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleDefinition) AddRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleDefinition) DeleteRoleDefinition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzRoleDefinitions** ppRoleDefinitions) get_RoleDefinitions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzScope** ppScope) get_Scope;
	}


	public HRESULT AddRoleDefinition(BSTR bstrRoleDefinition) mut => VT.[Friend]AddRoleDefinition(&this, bstrRoleDefinition);

	public HRESULT DeleteRoleDefinition(BSTR bstrRoleDefinition) mut => VT.[Friend]DeleteRoleDefinition(&this, bstrRoleDefinition);

	public HRESULT get_RoleDefinitions(IAzRoleDefinitions** ppRoleDefinitions) mut => VT.[Friend]get_RoleDefinitions(&this, ppRoleDefinitions);

	public HRESULT get_Scope(IAzScope** ppScope) mut => VT.[Friend]get_Scope(&this, ppScope);
}

[CRepr]struct IAzRoleAssignments : IDispatch
{
	public new const Guid IID = .(0x9c80b900, 0xfceb, 0x4d73, 0xa0, 0xf4, 0xc8, 0x3b, 0x0b, 0xbf, 0x24, 0x81);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pvarObtPtr) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppEnumPtr) get__NewEnum;
	}


	public HRESULT get_Item(int32 Index, VARIANT* pvarObtPtr) mut => VT.[Friend]get_Item(&this, Index, pvarObtPtr);

	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** ppEnumPtr) mut => VT.[Friend]get__NewEnum(&this, ppEnumPtr);
}

[CRepr]struct IAzPrincipalLocator : IDispatch
{
	public new const Guid IID = .(0xe5c3507d, 0xad6a, 0x4992, 0x9c, 0x7f, 0x74, 0xab, 0x48, 0x0b, 0x44, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzNameResolver** ppNameResolver) get_NameResolver;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAzObjectPicker** ppObjectPicker) get_ObjectPicker;
	}


	public HRESULT get_NameResolver(IAzNameResolver** ppNameResolver) mut => VT.[Friend]get_NameResolver(&this, ppNameResolver);

	public HRESULT get_ObjectPicker(IAzObjectPicker** ppObjectPicker) mut => VT.[Friend]get_ObjectPicker(&this, ppObjectPicker);
}

[CRepr]struct IAzNameResolver : IDispatch
{
	public new const Guid IID = .(0x504d0f15, 0x73e2, 0x43df, 0xa8, 0x70, 0xa6, 0x4f, 0x40, 0x71, 0x4f, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSid, int32* pSidType, BSTR* pbstrName) NameFromSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vSids, VARIANT* pvSidTypes, VARIANT* pvNames) NamesFromSids;
	}


	public HRESULT NameFromSid(BSTR bstrSid, int32* pSidType, BSTR* pbstrName) mut => VT.[Friend]NameFromSid(&this, bstrSid, pSidType, pbstrName);

	public HRESULT NamesFromSids(VARIANT vSids, VARIANT* pvSidTypes, VARIANT* pvNames) mut => VT.[Friend]NamesFromSids(&this, vSids, pvSidTypes, pvNames);
}

[CRepr]struct IAzObjectPicker : IDispatch
{
	public new const Guid IID = .(0x63130a48, 0x699a, 0x42d8, 0xbf, 0x01, 0xc6, 0x2a, 0xc3, 0xfb, 0x79, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hParentWnd, BSTR bstrTitle, VARIANT* pvSidTypes, VARIANT* pvNames, VARIANT* pvSids) GetPrincipals;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
	}


	public HRESULT GetPrincipals(HWND hParentWnd, BSTR bstrTitle, VARIANT* pvSidTypes, VARIANT* pvNames, VARIANT* pvSids) mut => VT.[Friend]GetPrincipals(&this, hParentWnd, bstrTitle, pvSidTypes, pvNames, pvSids);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);
}

[CRepr]struct IAzApplicationGroup2 : IAzApplicationGroup
{
	public new const Guid IID = .(0x3f0613fc, 0xb71a, 0x464e, 0xa1, 0x1d, 0x5b, 0x88, 0x1a, 0x56, 0xce, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzApplicationGroup.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_BizRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp) put_BizRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_BizRuleLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp) put_BizRuleLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProp) get_BizRuleImportedPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProp) put_BizRuleImportedPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, int16 bRecursive, IAzRoleAssignments** ppRoleAssignments) RoleAssignments;
	}


	public HRESULT get_BizRule(BSTR* pbstrProp) mut => VT.[Friend]get_BizRule(&this, pbstrProp);

	public HRESULT put_BizRule(BSTR bstrProp) mut => VT.[Friend]put_BizRule(&this, bstrProp);

	public HRESULT get_BizRuleLanguage(BSTR* pbstrProp) mut => VT.[Friend]get_BizRuleLanguage(&this, pbstrProp);

	public HRESULT put_BizRuleLanguage(BSTR bstrProp) mut => VT.[Friend]put_BizRuleLanguage(&this, bstrProp);

	public HRESULT get_BizRuleImportedPath(BSTR* pbstrProp) mut => VT.[Friend]get_BizRuleImportedPath(&this, pbstrProp);

	public HRESULT put_BizRuleImportedPath(BSTR bstrProp) mut => VT.[Friend]put_BizRuleImportedPath(&this, bstrProp);

	public HRESULT RoleAssignments(BSTR bstrScopeName, int16 bRecursive, IAzRoleAssignments** ppRoleAssignments) mut => VT.[Friend]RoleAssignments(&this, bstrScopeName, bRecursive, ppRoleAssignments);
}

[CRepr]struct IAzTask2 : IAzTask
{
	public new const Guid IID = .(0x03a9a5ee, 0x48c8, 0x4832, 0x90, 0x25, 0xaa, 0xd5, 0x03, 0xc4, 0x65, 0x26);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAzTask.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrScopeName, int16 bRecursive, IAzRoleAssignments** ppRoleAssignments) RoleAssignments;
	}


	public HRESULT RoleAssignments(BSTR bstrScopeName, int16 bRecursive, IAzRoleAssignments** ppRoleAssignments) mut => VT.[Friend]RoleAssignments(&this, bstrScopeName, bRecursive, ppRoleAssignments);
}

#endregion

#region Functions
public static
{
	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzAccessCheck(AUTHZ_ACCESS_CHECK_FLAGS Flags, AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, AUTHZ_ACCESS_REQUEST* pRequest, AUTHZ_AUDIT_EVENT_HANDLE hAuditEvent, PSECURITY_DESCRIPTOR pSecurityDescriptor, PSECURITY_DESCRIPTOR* OptionalSecurityDescriptorArray, uint32 OptionalSecurityDescriptorCount, AUTHZ_ACCESS_REPLY* pReply, int* phAccessCheckResults);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzCachedAccessCheck(uint32 Flags, AUTHZ_ACCESS_CHECK_RESULTS_HANDLE hAccessCheckResults, AUTHZ_ACCESS_REQUEST* pRequest, AUTHZ_AUDIT_EVENT_HANDLE hAuditEvent, AUTHZ_ACCESS_REPLY* pReply);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzOpenObjectAudit(uint32 Flags, AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, AUTHZ_ACCESS_REQUEST* pRequest, AUTHZ_AUDIT_EVENT_HANDLE hAuditEvent, PSECURITY_DESCRIPTOR pSecurityDescriptor, PSECURITY_DESCRIPTOR* OptionalSecurityDescriptorArray, uint32 OptionalSecurityDescriptorCount, AUTHZ_ACCESS_REPLY* pReply);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzFreeHandle(AUTHZ_ACCESS_CHECK_RESULTS_HANDLE hAccessCheckResults);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzInitializeResourceManager(uint32 Flags, PFN_AUTHZ_DYNAMIC_ACCESS_CHECK pfnDynamicAccessCheck, PFN_AUTHZ_COMPUTE_DYNAMIC_GROUPS pfnComputeDynamicGroups, PFN_AUTHZ_FREE_DYNAMIC_GROUPS pfnFreeDynamicGroups, PWSTR szResourceManagerName, AUTHZ_RESOURCE_MANAGER_HANDLE* phAuthzResourceManager);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzInitializeResourceManagerEx(AUTHZ_RESOURCE_MANAGER_FLAGS Flags, AUTHZ_INIT_INFO* pAuthzInitInfo, AUTHZ_RESOURCE_MANAGER_HANDLE* phAuthzResourceManager);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzInitializeRemoteResourceManager(AUTHZ_RPC_INIT_INFO_CLIENT* pRpcInitInfo, AUTHZ_RESOURCE_MANAGER_HANDLE* phAuthzResourceManager);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzFreeResourceManager(AUTHZ_RESOURCE_MANAGER_HANDLE hAuthzResourceManager);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzInitializeContextFromToken(uint32 Flags, HANDLE TokenHandle, AUTHZ_RESOURCE_MANAGER_HANDLE hAuthzResourceManager, LARGE_INTEGER* pExpirationTime, LUID Identifier, void* DynamicGroupArgs, AUTHZ_CLIENT_CONTEXT_HANDLE* phAuthzClientContext);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzInitializeContextFromSid(uint32 Flags, PSID UserSid, AUTHZ_RESOURCE_MANAGER_HANDLE hAuthzResourceManager, LARGE_INTEGER* pExpirationTime, LUID Identifier, void* DynamicGroupArgs, AUTHZ_CLIENT_CONTEXT_HANDLE* phAuthzClientContext);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzInitializeContextFromAuthzContext(uint32 Flags, AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, LARGE_INTEGER* pExpirationTime, LUID Identifier, void* DynamicGroupArgs, AUTHZ_CLIENT_CONTEXT_HANDLE* phNewAuthzClientContext);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzInitializeCompoundContext(AUTHZ_CLIENT_CONTEXT_HANDLE UserContext, AUTHZ_CLIENT_CONTEXT_HANDLE DeviceContext, AUTHZ_CLIENT_CONTEXT_HANDLE* phCompoundContext);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzAddSidsToContext(AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, SID_AND_ATTRIBUTES* Sids, uint32 SidCount, SID_AND_ATTRIBUTES* RestrictedSids, uint32 RestrictedSidCount, AUTHZ_CLIENT_CONTEXT_HANDLE* phNewAuthzClientContext);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzModifySecurityAttributes(AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, AUTHZ_SECURITY_ATTRIBUTE_OPERATION* pOperations, AUTHZ_SECURITY_ATTRIBUTES_INFORMATION* pAttributes);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzModifyClaims(AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, AUTHZ_CONTEXT_INFORMATION_CLASS ClaimClass, AUTHZ_SECURITY_ATTRIBUTE_OPERATION* pClaimOperations, AUTHZ_SECURITY_ATTRIBUTES_INFORMATION* pClaims);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzModifySids(AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, AUTHZ_CONTEXT_INFORMATION_CLASS SidClass, AUTHZ_SID_OPERATION* pSidOperations, TOKEN_GROUPS* pSids);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzSetAppContainerInformation(AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, PSID pAppContainerSid, uint32 CapabilityCount, SID_AND_ATTRIBUTES* pCapabilitySids);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzGetInformationFromContext(AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext, AUTHZ_CONTEXT_INFORMATION_CLASS InfoClass, uint32 BufferSize, uint32* pSizeRequired, void* Buffer);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzFreeContext(AUTHZ_CLIENT_CONTEXT_HANDLE hAuthzClientContext);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzInitializeObjectAccessAuditEvent(AUTHZ_INITIALIZE_OBJECT_ACCESS_AUDIT_EVENT_FLAGS Flags, AUTHZ_AUDIT_EVENT_TYPE_HANDLE hAuditEventType, PWSTR szOperationType, PWSTR szObjectType, PWSTR szObjectName, PWSTR szAdditionalInfo, int* phAuditEvent, uint32 dwAdditionalParameterCount);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzInitializeObjectAccessAuditEvent2(uint32 Flags, AUTHZ_AUDIT_EVENT_TYPE_HANDLE hAuditEventType, PWSTR szOperationType, PWSTR szObjectType, PWSTR szObjectName, PWSTR szAdditionalInfo, PWSTR szAdditionalInfo2, int* phAuditEvent, uint32 dwAdditionalParameterCount);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzFreeAuditEvent(AUTHZ_AUDIT_EVENT_HANDLE hAuditEvent);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzEvaluateSacl(AUTHZ_CLIENT_CONTEXT_HANDLE AuthzClientContext, AUTHZ_ACCESS_REQUEST* pRequest, ACL* Sacl, uint32 GrantedAccess, BOOL AccessGranted, BOOL* pbGenerateAudit);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzInstallSecurityEventSource(uint32 dwFlags, AUTHZ_SOURCE_SCHEMA_REGISTRATION* pRegistration);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzUninstallSecurityEventSource(uint32 dwFlags, PWSTR szEventSourceName);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzEnumerateSecurityEventSources(uint32 dwFlags, AUTHZ_SOURCE_SCHEMA_REGISTRATION* Buffer, uint32* pdwCount, uint32* pdwLength);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzRegisterSecurityEventSource(uint32 dwFlags, PWSTR szEventSourceName, int* phEventProvider);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzUnregisterSecurityEventSource(uint32 dwFlags, int* phEventProvider);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzReportSecurityEvent(uint32 dwFlags, AUTHZ_SECURITY_EVENT_PROVIDER_HANDLE hEventProvider, uint32 dwAuditId, PSID pUserSid, uint32 dwCount);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzReportSecurityEventFromParams(uint32 dwFlags, AUTHZ_SECURITY_EVENT_PROVIDER_HANDLE hEventProvider, uint32 dwAuditId, PSID pUserSid, AUDIT_PARAMS* pParams);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzRegisterCapChangeNotification(AUTHZ_CAP_CHANGE_SUBSCRIPTION_HANDLE__** phCapChangeSubscription, LPTHREAD_START_ROUTINE pfnCapChangeCallback, void* pCallbackContext);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzUnregisterCapChangeNotification(AUTHZ_CAP_CHANGE_SUBSCRIPTION_HANDLE__* hCapChangeSubscription);

	[Import("AUTHZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AuthzFreeCentralAccessPolicyCache();

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetEntriesInAclA(uint32 cCountOfExplicitEntries, EXPLICIT_ACCESS_A* pListOfExplicitEntries, ACL* OldAcl, ACL** NewAcl);
	public static uint32 SetEntriesInAcl(uint32 cCountOfExplicitEntries, EXPLICIT_ACCESS_A* pListOfExplicitEntries, ACL* OldAcl, ACL** NewAcl) => SetEntriesInAclA(cCountOfExplicitEntries, pListOfExplicitEntries, OldAcl, NewAcl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetEntriesInAclW(uint32 cCountOfExplicitEntries, EXPLICIT_ACCESS_W* pListOfExplicitEntries, ACL* OldAcl, ACL** NewAcl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetExplicitEntriesFromAclA(ACL* pacl, uint32* pcCountOfExplicitEntries, EXPLICIT_ACCESS_A** pListOfExplicitEntries);
	public static uint32 GetExplicitEntriesFromAcl(ACL* pacl, uint32* pcCountOfExplicitEntries, EXPLICIT_ACCESS_A** pListOfExplicitEntries) => GetExplicitEntriesFromAclA(pacl, pcCountOfExplicitEntries, pListOfExplicitEntries);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetExplicitEntriesFromAclW(ACL* pacl, uint32* pcCountOfExplicitEntries, EXPLICIT_ACCESS_W** pListOfExplicitEntries);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEffectiveRightsFromAclA(ACL* pacl, TRUSTEE_A* pTrustee, uint32* pAccessRights);
	public static uint32 GetEffectiveRightsFromAcl(ACL* pacl, TRUSTEE_A* pTrustee, uint32* pAccessRights) => GetEffectiveRightsFromAclA(pacl, pTrustee, pAccessRights);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEffectiveRightsFromAclW(ACL* pacl, TRUSTEE_W* pTrustee, uint32* pAccessRights);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetAuditedPermissionsFromAclA(ACL* pacl, TRUSTEE_A* pTrustee, uint32* pSuccessfulAuditedRights, uint32* pFailedAuditRights);
	public static uint32 GetAuditedPermissionsFromAcl(ACL* pacl, TRUSTEE_A* pTrustee, uint32* pSuccessfulAuditedRights, uint32* pFailedAuditRights) => GetAuditedPermissionsFromAclA(pacl, pTrustee, pSuccessfulAuditedRights, pFailedAuditRights);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetAuditedPermissionsFromAclW(ACL* pacl, TRUSTEE_W* pTrustee, uint32* pSuccessfulAuditedRights, uint32* pFailedAuditRights);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetNamedSecurityInfoA(PSTR pObjectName, SE_OBJECT_TYPE ObjectType, OBJECT_SECURITY_INFORMATION SecurityInfo, PSID* ppsidOwner, PSID* ppsidGroup, ACL** ppDacl, ACL** ppSacl, PSECURITY_DESCRIPTOR* ppSecurityDescriptor);
	public static WIN32_ERROR GetNamedSecurityInfo(PSTR pObjectName, SE_OBJECT_TYPE ObjectType, OBJECT_SECURITY_INFORMATION SecurityInfo, PSID* ppsidOwner, PSID* ppsidGroup, ACL** ppDacl, ACL** ppSacl, PSECURITY_DESCRIPTOR* ppSecurityDescriptor) => GetNamedSecurityInfoA(pObjectName, ObjectType, SecurityInfo, ppsidOwner, ppsidGroup, ppDacl, ppSacl, ppSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetNamedSecurityInfoW(PWSTR pObjectName, SE_OBJECT_TYPE ObjectType, OBJECT_SECURITY_INFORMATION SecurityInfo, PSID* ppsidOwner, PSID* ppsidGroup, ACL** ppDacl, ACL** ppSacl, PSECURITY_DESCRIPTOR* ppSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetSecurityInfo(HANDLE handle, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, PSID* ppsidOwner, PSID* ppsidGroup, ACL** ppDacl, ACL** ppSacl, PSECURITY_DESCRIPTOR* ppSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetNamedSecurityInfoA(PSTR pObjectName, SE_OBJECT_TYPE ObjectType, OBJECT_SECURITY_INFORMATION SecurityInfo, PSID psidOwner, PSID psidGroup, ACL* pDacl, ACL* pSacl);
	public static uint32 SetNamedSecurityInfo(PSTR pObjectName, SE_OBJECT_TYPE ObjectType, OBJECT_SECURITY_INFORMATION SecurityInfo, PSID psidOwner, PSID psidGroup, ACL* pDacl, ACL* pSacl) => SetNamedSecurityInfoA(pObjectName, ObjectType, SecurityInfo, psidOwner, psidGroup, pDacl, pSacl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetNamedSecurityInfoW(PWSTR pObjectName, SE_OBJECT_TYPE ObjectType, OBJECT_SECURITY_INFORMATION SecurityInfo, PSID psidOwner, PSID psidGroup, ACL* pDacl, ACL* pSacl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetSecurityInfo(HANDLE handle, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, PSID psidOwner, PSID psidGroup, ACL* pDacl, ACL* pSacl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetInheritanceSourceA(PSTR pObjectName, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, BOOL Container, Guid** pObjectClassGuids, uint32 GuidCount, ACL* pAcl, FN_OBJECT_MGR_FUNCTS* pfnArray, GENERIC_MAPPING* pGenericMapping, INHERITED_FROMA* pInheritArray);
	public static uint32 GetInheritanceSource(PSTR pObjectName, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, BOOL Container, Guid** pObjectClassGuids, uint32 GuidCount, ACL* pAcl, FN_OBJECT_MGR_FUNCTS* pfnArray, GENERIC_MAPPING* pGenericMapping, INHERITED_FROMA* pInheritArray) => GetInheritanceSourceA(pObjectName, ObjectType, SecurityInfo, Container, pObjectClassGuids, GuidCount, pAcl, pfnArray, pGenericMapping, pInheritArray);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetInheritanceSourceW(PWSTR pObjectName, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, BOOL Container, Guid** pObjectClassGuids, uint32 GuidCount, ACL* pAcl, FN_OBJECT_MGR_FUNCTS* pfnArray, GENERIC_MAPPING* pGenericMapping, INHERITED_FROMW* pInheritArray);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FreeInheritedFromArray(INHERITED_FROMW* pInheritArray, uint16 AceCnt, FN_OBJECT_MGR_FUNCTS* pfnArray);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TreeResetNamedSecurityInfoA(PSTR pObjectName, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, PSID pOwner, PSID pGroup, ACL* pDacl, ACL* pSacl, BOOL KeepExplicit, FN_PROGRESS fnProgress, PROG_INVOKE_SETTING ProgressInvokeSetting, void* Args);
	public static uint32 TreeResetNamedSecurityInfo(PSTR pObjectName, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, PSID pOwner, PSID pGroup, ACL* pDacl, ACL* pSacl, BOOL KeepExplicit, FN_PROGRESS fnProgress, PROG_INVOKE_SETTING ProgressInvokeSetting, void* Args) => TreeResetNamedSecurityInfoA(pObjectName, ObjectType, SecurityInfo, pOwner, pGroup, pDacl, pSacl, KeepExplicit, fnProgress, ProgressInvokeSetting, Args);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TreeResetNamedSecurityInfoW(PWSTR pObjectName, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, PSID pOwner, PSID pGroup, ACL* pDacl, ACL* pSacl, BOOL KeepExplicit, FN_PROGRESS fnProgress, PROG_INVOKE_SETTING ProgressInvokeSetting, void* Args);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TreeSetNamedSecurityInfoA(PSTR pObjectName, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, PSID pOwner, PSID pGroup, ACL* pDacl, ACL* pSacl, TREE_SEC_INFO dwAction, FN_PROGRESS fnProgress, PROG_INVOKE_SETTING ProgressInvokeSetting, void* Args);
	public static uint32 TreeSetNamedSecurityInfo(PSTR pObjectName, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, PSID pOwner, PSID pGroup, ACL* pDacl, ACL* pSacl, TREE_SEC_INFO dwAction, FN_PROGRESS fnProgress, PROG_INVOKE_SETTING ProgressInvokeSetting, void* Args) => TreeSetNamedSecurityInfoA(pObjectName, ObjectType, SecurityInfo, pOwner, pGroup, pDacl, pSacl, dwAction, fnProgress, ProgressInvokeSetting, Args);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TreeSetNamedSecurityInfoW(PWSTR pObjectName, SE_OBJECT_TYPE ObjectType, uint32 SecurityInfo, PSID pOwner, PSID pGroup, ACL* pDacl, ACL* pSacl, TREE_SEC_INFO dwAction, FN_PROGRESS fnProgress, PROG_INVOKE_SETTING ProgressInvokeSetting, void* Args);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BuildSecurityDescriptorA(TRUSTEE_A* pOwner, TRUSTEE_A* pGroup, uint32 cCountOfAccessEntries, EXPLICIT_ACCESS_A* pListOfAccessEntries, uint32 cCountOfAuditEntries, EXPLICIT_ACCESS_A* pListOfAuditEntries, PSECURITY_DESCRIPTOR pOldSD, uint32* pSizeNewSD, PSECURITY_DESCRIPTOR* pNewSD);
	public static uint32 BuildSecurityDescriptor(TRUSTEE_A* pOwner, TRUSTEE_A* pGroup, uint32 cCountOfAccessEntries, EXPLICIT_ACCESS_A* pListOfAccessEntries, uint32 cCountOfAuditEntries, EXPLICIT_ACCESS_A* pListOfAuditEntries, PSECURITY_DESCRIPTOR pOldSD, uint32* pSizeNewSD, PSECURITY_DESCRIPTOR* pNewSD) => BuildSecurityDescriptorA(pOwner, pGroup, cCountOfAccessEntries, pListOfAccessEntries, cCountOfAuditEntries, pListOfAuditEntries, pOldSD, pSizeNewSD, pNewSD);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BuildSecurityDescriptorW(TRUSTEE_W* pOwner, TRUSTEE_W* pGroup, uint32 cCountOfAccessEntries, EXPLICIT_ACCESS_W* pListOfAccessEntries, uint32 cCountOfAuditEntries, EXPLICIT_ACCESS_W* pListOfAuditEntries, PSECURITY_DESCRIPTOR pOldSD, uint32* pSizeNewSD, PSECURITY_DESCRIPTOR* pNewSD);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LookupSecurityDescriptorPartsA(TRUSTEE_A** ppOwner, TRUSTEE_A** ppGroup, uint32* pcCountOfAccessEntries, EXPLICIT_ACCESS_A** ppListOfAccessEntries, uint32* pcCountOfAuditEntries, EXPLICIT_ACCESS_A** ppListOfAuditEntries, PSECURITY_DESCRIPTOR pSD);
	public static uint32 LookupSecurityDescriptorParts(TRUSTEE_A** ppOwner, TRUSTEE_A** ppGroup, uint32* pcCountOfAccessEntries, EXPLICIT_ACCESS_A** ppListOfAccessEntries, uint32* pcCountOfAuditEntries, EXPLICIT_ACCESS_A** ppListOfAuditEntries, PSECURITY_DESCRIPTOR pSD) => LookupSecurityDescriptorPartsA(ppOwner, ppGroup, pcCountOfAccessEntries, ppListOfAccessEntries, pcCountOfAuditEntries, ppListOfAuditEntries, pSD);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LookupSecurityDescriptorPartsW(TRUSTEE_W** ppOwner, TRUSTEE_W** ppGroup, uint32* pcCountOfAccessEntries, EXPLICIT_ACCESS_W** ppListOfAccessEntries, uint32* pcCountOfAuditEntries, EXPLICIT_ACCESS_W** ppListOfAuditEntries, PSECURITY_DESCRIPTOR pSD);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildExplicitAccessWithNameA(EXPLICIT_ACCESS_A* pExplicitAccess, PSTR pTrusteeName, uint32 AccessPermissions, ACCESS_MODE AccessMode, ACE_FLAGS Inheritance);
	public static void BuildExplicitAccessWithName(EXPLICIT_ACCESS_A* pExplicitAccess, PSTR pTrusteeName, uint32 AccessPermissions, ACCESS_MODE AccessMode, ACE_FLAGS Inheritance) => BuildExplicitAccessWithNameA(pExplicitAccess, pTrusteeName, AccessPermissions, AccessMode, Inheritance);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildExplicitAccessWithNameW(EXPLICIT_ACCESS_W* pExplicitAccess, PWSTR pTrusteeName, uint32 AccessPermissions, ACCESS_MODE AccessMode, ACE_FLAGS Inheritance);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildImpersonateExplicitAccessWithNameA(EXPLICIT_ACCESS_A* pExplicitAccess, PSTR pTrusteeName, TRUSTEE_A* pTrustee, uint32 AccessPermissions, ACCESS_MODE AccessMode, uint32 Inheritance);
	public static void BuildImpersonateExplicitAccessWithName(EXPLICIT_ACCESS_A* pExplicitAccess, PSTR pTrusteeName, TRUSTEE_A* pTrustee, uint32 AccessPermissions, ACCESS_MODE AccessMode, uint32 Inheritance) => BuildImpersonateExplicitAccessWithNameA(pExplicitAccess, pTrusteeName, pTrustee, AccessPermissions, AccessMode, Inheritance);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildImpersonateExplicitAccessWithNameW(EXPLICIT_ACCESS_W* pExplicitAccess, PWSTR pTrusteeName, TRUSTEE_W* pTrustee, uint32 AccessPermissions, ACCESS_MODE AccessMode, uint32 Inheritance);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildTrusteeWithNameA(TRUSTEE_A* pTrustee, PSTR pName);
	public static void BuildTrusteeWithName(TRUSTEE_A* pTrustee, PSTR pName) => BuildTrusteeWithNameA(pTrustee, pName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildTrusteeWithNameW(TRUSTEE_W* pTrustee, PWSTR pName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildImpersonateTrusteeA(TRUSTEE_A* pTrustee, TRUSTEE_A* pImpersonateTrustee);
	public static void BuildImpersonateTrustee(TRUSTEE_A* pTrustee, TRUSTEE_A* pImpersonateTrustee) => BuildImpersonateTrusteeA(pTrustee, pImpersonateTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildImpersonateTrusteeW(TRUSTEE_W* pTrustee, TRUSTEE_W* pImpersonateTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildTrusteeWithSidA(TRUSTEE_A* pTrustee, PSID pSid);
	public static void BuildTrusteeWithSid(TRUSTEE_A* pTrustee, PSID pSid) => BuildTrusteeWithSidA(pTrustee, pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildTrusteeWithSidW(TRUSTEE_W* pTrustee, PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildTrusteeWithObjectsAndSidA(TRUSTEE_A* pTrustee, OBJECTS_AND_SID* pObjSid, Guid* pObjectGuid, Guid* pInheritedObjectGuid, PSID pSid);
	public static void BuildTrusteeWithObjectsAndSid(TRUSTEE_A* pTrustee, OBJECTS_AND_SID* pObjSid, Guid* pObjectGuid, Guid* pInheritedObjectGuid, PSID pSid) => BuildTrusteeWithObjectsAndSidA(pTrustee, pObjSid, pObjectGuid, pInheritedObjectGuid, pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildTrusteeWithObjectsAndSidW(TRUSTEE_W* pTrustee, OBJECTS_AND_SID* pObjSid, Guid* pObjectGuid, Guid* pInheritedObjectGuid, PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildTrusteeWithObjectsAndNameA(TRUSTEE_A* pTrustee, OBJECTS_AND_NAME_A* pObjName, SE_OBJECT_TYPE ObjectType, PSTR ObjectTypeName, PSTR InheritedObjectTypeName, PSTR Name);
	public static void BuildTrusteeWithObjectsAndName(TRUSTEE_A* pTrustee, OBJECTS_AND_NAME_A* pObjName, SE_OBJECT_TYPE ObjectType, PSTR ObjectTypeName, PSTR InheritedObjectTypeName, PSTR Name) => BuildTrusteeWithObjectsAndNameA(pTrustee, pObjName, ObjectType, ObjectTypeName, InheritedObjectTypeName, Name);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void BuildTrusteeWithObjectsAndNameW(TRUSTEE_W* pTrustee, OBJECTS_AND_NAME_W* pObjName, SE_OBJECT_TYPE ObjectType, PWSTR ObjectTypeName, PWSTR InheritedObjectTypeName, PWSTR Name);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR GetTrusteeNameA(TRUSTEE_A* pTrustee);
	public static PSTR GetTrusteeName(TRUSTEE_A* pTrustee) => GetTrusteeNameA(pTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR GetTrusteeNameW(TRUSTEE_W* pTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TRUSTEE_TYPE GetTrusteeTypeA(TRUSTEE_A* pTrustee);
	public static TRUSTEE_TYPE GetTrusteeType(TRUSTEE_A* pTrustee) => GetTrusteeTypeA(pTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TRUSTEE_TYPE GetTrusteeTypeW(TRUSTEE_W* pTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TRUSTEE_FORM GetTrusteeFormA(TRUSTEE_A* pTrustee);
	public static TRUSTEE_FORM GetTrusteeForm(TRUSTEE_A* pTrustee) => GetTrusteeFormA(pTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TRUSTEE_FORM GetTrusteeFormW(TRUSTEE_W* pTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern MULTIPLE_TRUSTEE_OPERATION GetMultipleTrusteeOperationA(TRUSTEE_A* pTrustee);
	public static MULTIPLE_TRUSTEE_OPERATION GetMultipleTrusteeOperation(TRUSTEE_A* pTrustee) => GetMultipleTrusteeOperationA(pTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern MULTIPLE_TRUSTEE_OPERATION GetMultipleTrusteeOperationW(TRUSTEE_W* pTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TRUSTEE_A* GetMultipleTrusteeA(TRUSTEE_A* pTrustee);
	public static TRUSTEE_A* GetMultipleTrustee(TRUSTEE_A* pTrustee) => GetMultipleTrusteeA(pTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern TRUSTEE_W* GetMultipleTrusteeW(TRUSTEE_W* pTrustee);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertSidToStringSidA(PSID Sid, PSTR* StringSid);
	public static BOOL ConvertSidToStringSid(PSID Sid, PSTR* StringSid) => ConvertSidToStringSidA(Sid, StringSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertSidToStringSidW(PSID Sid, PWSTR* StringSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertStringSidToSidA(PSTR StringSid, PSID* Sid);
	public static BOOL ConvertStringSidToSid(PSTR StringSid, PSID* Sid) => ConvertStringSidToSidA(StringSid, Sid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertStringSidToSidW(PWSTR StringSid, PSID* Sid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertStringSecurityDescriptorToSecurityDescriptorA(PSTR StringSecurityDescriptor, uint32 StringSDRevision, PSECURITY_DESCRIPTOR* SecurityDescriptor, uint32* SecurityDescriptorSize);
	public static BOOL ConvertStringSecurityDescriptorToSecurityDescriptor(PSTR StringSecurityDescriptor, uint32 StringSDRevision, PSECURITY_DESCRIPTOR* SecurityDescriptor, uint32* SecurityDescriptorSize) => ConvertStringSecurityDescriptorToSecurityDescriptorA(StringSecurityDescriptor, StringSDRevision, SecurityDescriptor, SecurityDescriptorSize);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertStringSecurityDescriptorToSecurityDescriptorW(PWSTR StringSecurityDescriptor, uint32 StringSDRevision, PSECURITY_DESCRIPTOR* SecurityDescriptor, uint32* SecurityDescriptorSize);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertSecurityDescriptorToStringSecurityDescriptorA(PSECURITY_DESCRIPTOR SecurityDescriptor, uint32 RequestedStringSDRevision, uint32 SecurityInformation, PSTR* StringSecurityDescriptor, uint32* StringSecurityDescriptorLen);
	public static BOOL ConvertSecurityDescriptorToStringSecurityDescriptor(PSECURITY_DESCRIPTOR SecurityDescriptor, uint32 RequestedStringSDRevision, uint32 SecurityInformation, PSTR* StringSecurityDescriptor, uint32* StringSecurityDescriptorLen) => ConvertSecurityDescriptorToStringSecurityDescriptorA(SecurityDescriptor, RequestedStringSDRevision, SecurityInformation, StringSecurityDescriptor, StringSecurityDescriptorLen);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertSecurityDescriptorToStringSecurityDescriptorW(PSECURITY_DESCRIPTOR SecurityDescriptor, uint32 RequestedStringSDRevision, uint32 SecurityInformation, PWSTR* StringSecurityDescriptor, uint32* StringSecurityDescriptorLen);

}
#endregion
