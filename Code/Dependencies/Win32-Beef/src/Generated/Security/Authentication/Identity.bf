using Win32.Foundation;
using Win32.Security;
using Win32.System.Kernel;
using Win32.Security.Credentials;
using Win32.System.Rpc;
using Win32.System.Threading;
using Win32.Security.Cryptography;
using Win32.System.PasswordManagement;
using Win32.System.Com;
using Win32.System.WindowsProgramming;
using System;

namespace Win32.Security.Authentication.Identity;

#region Constants
public static
{
	public const String NTLMSP_NAME_A = "NTLM";
	public const String NTLMSP_NAME = "NTLM";
	public const String MICROSOFT_KERBEROS_NAME_A = "Kerberos";
	public const String MICROSOFT_KERBEROS_NAME_W = "Kerberos";
	public const String MICROSOFT_KERBEROS_NAME = "Kerberos";
	public const String NEGOSSP_NAME_W = "Negotiate";
	public const String NEGOSSP_NAME_A = "Negotiate";
	public const String NEGOSSP_NAME = "Negotiate";
	public const String CLOUDAP_NAME_W = "CloudAP";
	public const String ClOUDAP_NAME_A = "CloudAP";
	public const String CLOUDAP_NAME = "CloudAP";
	public const uint32 ISSP_LEVEL = 32;
	public const uint32 ISSP_MODE = 1;
	public const uint32 SECPKG_FLAG_INTEGRITY = 1;
	public const uint32 SECPKG_FLAG_PRIVACY = 2;
	public const uint32 SECPKG_FLAG_TOKEN_ONLY = 4;
	public const uint32 SECPKG_FLAG_DATAGRAM = 8;
	public const uint32 SECPKG_FLAG_CONNECTION = 16;
	public const uint32 SECPKG_FLAG_MULTI_REQUIRED = 32;
	public const uint32 SECPKG_FLAG_CLIENT_ONLY = 64;
	public const uint32 SECPKG_FLAG_EXTENDED_ERROR = 128;
	public const uint32 SECPKG_FLAG_IMPERSONATION = 256;
	public const uint32 SECPKG_FLAG_ACCEPT_WIN32_NAME = 512;
	public const uint32 SECPKG_FLAG_STREAM = 1024;
	public const uint32 SECPKG_FLAG_NEGOTIABLE = 2048;
	public const uint32 SECPKG_FLAG_GSS_COMPATIBLE = 4096;
	public const uint32 SECPKG_FLAG_LOGON = 8192;
	public const uint32 SECPKG_FLAG_ASCII_BUFFERS = 16384;
	public const uint32 SECPKG_FLAG_FRAGMENT = 32768;
	public const uint32 SECPKG_FLAG_MUTUAL_AUTH = 65536;
	public const uint32 SECPKG_FLAG_DELEGATION = 131072;
	public const uint32 SECPKG_FLAG_READONLY_WITH_CHECKSUM = 262144;
	public const uint32 SECPKG_FLAG_RESTRICTED_TOKENS = 524288;
	public const uint32 SECPKG_FLAG_NEGO_EXTENDER = 1048576;
	public const uint32 SECPKG_FLAG_NEGOTIABLE2 = 2097152;
	public const uint32 SECPKG_FLAG_APPCONTAINER_PASSTHROUGH = 4194304;
	public const uint32 SECPKG_FLAG_APPCONTAINER_CHECKS = 8388608;
	public const uint32 SECPKG_FLAG_CREDENTIAL_ISOLATION_ENABLED = 16777216;
	public const uint32 SECPKG_FLAG_APPLY_LOOPBACK = 33554432;
	public const uint32 SECPKG_ID_NONE = 65535;
	public const uint32 SECPKG_CALLFLAGS_APPCONTAINER = 1;
	public const uint32 SECPKG_CALLFLAGS_APPCONTAINER_AUTHCAPABLE = 2;
	public const uint32 SECPKG_CALLFLAGS_FORCE_SUPPLIED = 4;
	public const uint32 SECPKG_CALLFLAGS_APPCONTAINER_UPNCAPABLE = 8;
	public const uint32 SECBUFFER_VERSION = 0;
	public const uint32 SECBUFFER_EMPTY = 0;
	public const uint32 SECBUFFER_DATA = 1;
	public const uint32 SECBUFFER_TOKEN = 2;
	public const uint32 SECBUFFER_PKG_PARAMS = 3;
	public const uint32 SECBUFFER_MISSING = 4;
	public const uint32 SECBUFFER_EXTRA = 5;
	public const uint32 SECBUFFER_STREAM_TRAILER = 6;
	public const uint32 SECBUFFER_STREAM_HEADER = 7;
	public const uint32 SECBUFFER_NEGOTIATION_INFO = 8;
	public const uint32 SECBUFFER_PADDING = 9;
	public const uint32 SECBUFFER_STREAM = 10;
	public const uint32 SECBUFFER_MECHLIST = 11;
	public const uint32 SECBUFFER_MECHLIST_SIGNATURE = 12;
	public const uint32 SECBUFFER_TARGET = 13;
	public const uint32 SECBUFFER_CHANNEL_BINDINGS = 14;
	public const uint32 SECBUFFER_CHANGE_PASS_RESPONSE = 15;
	public const uint32 SECBUFFER_TARGET_HOST = 16;
	public const uint32 SECBUFFER_ALERT = 17;
	public const uint32 SECBUFFER_APPLICATION_PROTOCOLS = 18;
	public const uint32 SECBUFFER_SRTP_PROTECTION_PROFILES = 19;
	public const uint32 SECBUFFER_SRTP_MASTER_KEY_IDENTIFIER = 20;
	public const uint32 SECBUFFER_TOKEN_BINDING = 21;
	public const uint32 SECBUFFER_PRESHARED_KEY = 22;
	public const uint32 SECBUFFER_PRESHARED_KEY_IDENTITY = 23;
	public const uint32 SECBUFFER_DTLS_MTU = 24;
	public const uint32 SECBUFFER_SEND_GENERIC_TLS_EXTENSION = 25;
	public const uint32 SECBUFFER_SUBSCRIBE_GENERIC_TLS_EXTENSION = 26;
	public const uint32 SECBUFFER_FLAGS = 27;
	public const uint32 SECBUFFER_TRAFFIC_SECRETS = 28;
	public const uint32 SECBUFFER_ATTRMASK = 4026531840;
	public const uint32 SECBUFFER_READONLY = 2147483648;
	public const uint32 SECBUFFER_READONLY_WITH_CHECKSUM = 268435456;
	public const uint32 SECBUFFER_RESERVED = 1610612736;
	public const uint32 SZ_ALG_MAX_SIZE = 64;
	public const uint32 SECURITY_NATIVE_DREP = 16;
	public const uint32 SECURITY_NETWORK_DREP = 0;
	public const uint32 SECPKG_CRED_BOTH = 3;
	public const uint32 SECPKG_CRED_DEFAULT = 4;
	public const uint32 SECPKG_CRED_RESERVED = 4026531840;
	public const uint32 SECPKG_CRED_AUTOLOGON_RESTRICTED = 16;
	public const uint32 SECPKG_CRED_PROCESS_POLICY_ONLY = 32;
	public const uint32 ISC_RET_DELEGATE = 1;
	public const uint32 ISC_RET_MUTUAL_AUTH = 2;
	public const uint32 ISC_RET_REPLAY_DETECT = 4;
	public const uint32 ISC_RET_SEQUENCE_DETECT = 8;
	public const uint32 ISC_RET_CONFIDENTIALITY = 16;
	public const uint32 ISC_RET_USE_SESSION_KEY = 32;
	public const uint32 ISC_RET_USED_COLLECTED_CREDS = 64;
	public const uint32 ISC_RET_USED_SUPPLIED_CREDS = 128;
	public const uint32 ISC_RET_ALLOCATED_MEMORY = 256;
	public const uint32 ISC_RET_USED_DCE_STYLE = 512;
	public const uint32 ISC_RET_DATAGRAM = 1024;
	public const uint32 ISC_RET_CONNECTION = 2048;
	public const uint32 ISC_RET_INTERMEDIATE_RETURN = 4096;
	public const uint32 ISC_RET_CALL_LEVEL = 8192;
	public const uint32 ISC_RET_EXTENDED_ERROR = 16384;
	public const uint32 ISC_RET_STREAM = 32768;
	public const uint32 ISC_RET_INTEGRITY = 65536;
	public const uint32 ISC_RET_IDENTIFY = 131072;
	public const uint32 ISC_RET_NULL_SESSION = 262144;
	public const uint32 ISC_RET_MANUAL_CRED_VALIDATION = 524288;
	public const uint32 ISC_RET_RESERVED1 = 1048576;
	public const uint32 ISC_RET_FRAGMENT_ONLY = 2097152;
	public const uint32 ISC_RET_FORWARD_CREDENTIALS = 4194304;
	public const uint32 ISC_RET_USED_HTTP_STYLE = 16777216;
	public const uint32 ISC_RET_NO_ADDITIONAL_TOKEN = 33554432;
	public const uint32 ISC_RET_REAUTHENTICATION = 134217728;
	public const uint32 ISC_RET_CONFIDENTIALITY_ONLY = 1073741824;
	public const uint64 ISC_RET_MESSAGES = 4294967296;
	public const uint64 ISC_RET_DEFERRED_CRED_VALIDATION = 8589934592;
	public const uint32 ASC_RET_DELEGATE = 1;
	public const uint32 ASC_RET_MUTUAL_AUTH = 2;
	public const uint32 ASC_RET_REPLAY_DETECT = 4;
	public const uint32 ASC_RET_SEQUENCE_DETECT = 8;
	public const uint32 ASC_RET_CONFIDENTIALITY = 16;
	public const uint32 ASC_RET_USE_SESSION_KEY = 32;
	public const uint32 ASC_RET_SESSION_TICKET = 64;
	public const uint32 ASC_RET_ALLOCATED_MEMORY = 256;
	public const uint32 ASC_RET_USED_DCE_STYLE = 512;
	public const uint32 ASC_RET_DATAGRAM = 1024;
	public const uint32 ASC_RET_CONNECTION = 2048;
	public const uint32 ASC_RET_CALL_LEVEL = 8192;
	public const uint32 ASC_RET_THIRD_LEG_FAILED = 16384;
	public const uint32 ASC_RET_EXTENDED_ERROR = 32768;
	public const uint32 ASC_RET_STREAM = 65536;
	public const uint32 ASC_RET_INTEGRITY = 131072;
	public const uint32 ASC_RET_LICENSING = 262144;
	public const uint32 ASC_RET_IDENTIFY = 524288;
	public const uint32 ASC_RET_NULL_SESSION = 1048576;
	public const uint32 ASC_RET_ALLOW_NON_USER_LOGONS = 2097152;
	public const uint32 ASC_RET_ALLOW_CONTEXT_REPLAY = 4194304;
	public const uint32 ASC_RET_FRAGMENT_ONLY = 8388608;
	public const uint32 ASC_RET_NO_TOKEN = 16777216;
	public const uint32 ASC_RET_NO_ADDITIONAL_TOKEN = 33554432;
	public const uint64 ASC_RET_MESSAGES = 4294967296;
	public const uint32 SECPKG_CRED_ATTR_NAMES = 1;
	public const uint32 SECPKG_CRED_ATTR_SSI_PROVIDER = 2;
	public const uint32 SECPKG_CRED_ATTR_KDC_PROXY_SETTINGS = 3;
	public const uint32 SECPKG_CRED_ATTR_CERT = 4;
	public const uint32 SECPKG_CRED_ATTR_PAC_BYPASS = 5;
	public const uint32 KDC_PROXY_SETTINGS_V1 = 1;
	public const uint32 KDC_PROXY_SETTINGS_FLAGS_FORCEPROXY = 1;
	public const uint32 SECPKG_ATTR_PROTO_INFO = 7;
	public const uint32 SECPKG_ATTR_USER_FLAGS = 11;
	public const uint32 SECPKG_ATTR_USE_VALIDATED = 15;
	public const uint32 SECPKG_ATTR_CREDENTIAL_NAME = 16;
	public const uint32 SECPKG_ATTR_TARGET = 19;
	public const uint32 SECPKG_ATTR_AUTHENTICATION_ID = 20;
	public const uint32 SECPKG_ATTR_LOGOFF_TIME = 21;
	public const uint32 SECPKG_ATTR_NEGO_KEYS = 22;
	public const uint32 SECPKG_ATTR_PROMPTING_NEEDED = 24;
	public const uint32 SECPKG_ATTR_NEGO_PKG_INFO = 31;
	public const uint32 SECPKG_ATTR_NEGO_STATUS = 32;
	public const uint32 SECPKG_ATTR_CONTEXT_DELETED = 33;
	public const uint32 SECPKG_ATTR_APPLICATION_PROTOCOL = 35;
	public const uint32 SECPKG_ATTR_NEGOTIATED_TLS_EXTENSIONS = 36;
	public const uint32 SECPKG_ATTR_IS_LOOPBACK = 37;
	public const uint32 SECPKG_ATTR_NEGO_INFO_FLAG_NO_KERBEROS = 1;
	public const uint32 SECPKG_ATTR_NEGO_INFO_FLAG_NO_NTLM = 2;
	public const uint32 SECPKG_NEGOTIATION_COMPLETE = 0;
	public const uint32 SECPKG_NEGOTIATION_OPTIMISTIC = 1;
	public const uint32 SECPKG_NEGOTIATION_IN_PROGRESS = 2;
	public const uint32 SECPKG_NEGOTIATION_DIRECT = 3;
	public const uint32 SECPKG_NEGOTIATION_TRY_MULTICRED = 4;
	public const uint32 MAX_PROTOCOL_ID_SIZE = 255;
	public const uint32 SECQOP_WRAP_NO_ENCRYPT = 2147483649;
	public const uint32 SECQOP_WRAP_OOB_DATA = 1073741824;
	public const String SECURITY_ENTRYPOINT_ANSIW = "InitSecurityInterfaceW";
	public const String SECURITY_ENTRYPOINT_ANSIA = "InitSecurityInterfaceA";
	public const String SECURITY_ENTRYPOINT16 = "INITSECURITYINTERFACEA";
	public const String SECURITY_ENTRYPOINT_ANSI = "InitSecurityInterfaceW";
	public const String SECURITY_ENTRYPOINT = "INITSECURITYINTERFACEA";
	public const uint32 SECURITY_SUPPORT_PROVIDER_INTERFACE_VERSION = 1;
	public const uint32 SECURITY_SUPPORT_PROVIDER_INTERFACE_VERSION_2 = 2;
	public const uint32 SECURITY_SUPPORT_PROVIDER_INTERFACE_VERSION_3 = 3;
	public const uint32 SECURITY_SUPPORT_PROVIDER_INTERFACE_VERSION_4 = 4;
	public const uint32 SECURITY_SUPPORT_PROVIDER_INTERFACE_VERSION_5 = 5;
	public const uint32 SASL_OPTION_SEND_SIZE = 1;
	public const uint32 SASL_OPTION_RECV_SIZE = 2;
	public const uint32 SASL_OPTION_AUTHZ_STRING = 3;
	public const uint32 SASL_OPTION_AUTHZ_PROCESSING = 4;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_VERSION_2 = 513;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_VERSION = 512;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_PROCESS_ENCRYPTED = 16;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_SYSTEM_PROTECTED = 32;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_USER_PROTECTED = 64;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_SYSTEM_ENCRYPTED = 128;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_RESERVED = 65536;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_NULL_USER = 131072;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_NULL_DOMAIN = 262144;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_ID_PROVIDER = 524288;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_SSPIPFC_USE_MASK = 4278190080;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_SSPIPFC_CREDPROV_DO_NOT_SAVE = 2147483648;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_SSPIPFC_SAVE_CRED_BY_CALLER = 2147483648;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_SSPIPFC_SAVE_CRED_CHECKED = 1073741824;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_SSPIPFC_NO_CHECKBOX = 536870912;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_FLAGS_SSPIPFC_CREDPROV_DO_NOT_LOAD = 268435456;
	public const uint32 SSPIPFC_CREDPROV_DO_NOT_SAVE = 1;
	public const uint32 SSPIPFC_SAVE_CRED_BY_CALLER = 1;
	public const uint32 SSPIPFC_NO_CHECKBOX = 2;
	public const uint32 SSPIPFC_CREDPROV_DO_NOT_LOAD = 4;
	public const uint32 SSPIPFC_USE_CREDUIBROKER = 8;
	public const uint32 NGC_DATA_FLAG_KERB_CERTIFICATE_LOGON_FLAG_CHECK_DUPLICATES = 1;
	public const uint32 NGC_DATA_FLAG_KERB_CERTIFICATE_LOGON_FLAG_USE_CERTIFICATE_INFO = 2;
	public const uint32 NGC_DATA_FLAG_IS_SMARTCARD_DATA = 4;
	public const uint32 NGC_DATA_FLAG_IS_CLOUD_TRUST_CRED = 8;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_ENCRYPT_SAME_LOGON = 1;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_ENCRYPT_SAME_PROCESS = 2;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_ENCRYPT_FOR_SYSTEM = 4;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_MARSHALLED = 4;
	public const uint32 SEC_WINNT_AUTH_IDENTITY_ONLY = 8;
	public const uint32 SECPKG_OPTIONS_PERMANENT = 1;
	public const uint32 LOOKUP_VIEW_LOCAL_INFORMATION = 1;
	public const uint32 LOOKUP_TRANSLATE_NAMES = 2048;
	public const uint32 SECPKG_ATTR_ISSUER_LIST = 80;
	public const uint32 SECPKG_ATTR_REMOTE_CRED = 81;
	public const uint32 SECPKG_ATTR_SUPPORTED_ALGS = 86;
	public const uint32 SECPKG_ATTR_CIPHER_STRENGTHS = 87;
	public const uint32 SECPKG_ATTR_SUPPORTED_PROTOCOLS = 88;
	public const uint32 SECPKG_ATTR_MAPPED_CRED_ATTR = 92;
	public const uint32 SECPKG_ATTR_REMOTE_CERTIFICATES = 95;
	public const uint32 SECPKG_ATTR_CLIENT_CERT_POLICY = 96;
	public const uint32 SECPKG_ATTR_CC_POLICY_RESULT = 97;
	public const uint32 SECPKG_ATTR_USE_NCRYPT = 98;
	public const uint32 SECPKG_ATTR_LOCAL_CERT_INFO = 99;
	public const uint32 SECPKG_ATTR_CIPHER_INFO = 100;
	public const uint32 SECPKG_ATTR_REMOTE_CERT_CHAIN = 103;
	public const uint32 SECPKG_ATTR_UI_INFO = 104;
	public const uint32 SECPKG_ATTR_KEYING_MATERIAL = 107;
	public const uint32 SECPKG_ATTR_SRTP_PARAMETERS = 108;
	public const uint32 SECPKG_ATTR_TOKEN_BINDING = 109;
	public const uint32 SECPKG_ATTR_CONNECTION_INFO_EX = 110;
	public const uint32 SECPKG_ATTR_KEYING_MATERIAL_TOKEN_BINDING = 111;
	public const uint32 SECPKG_ATTR_KEYING_MATERIAL_INPROC = 112;
	public const uint32 SECPKG_ATTR_CERT_CHECK_RESULT = 113;
	public const uint32 SECPKG_ATTR_CERT_CHECK_RESULT_INPROC = 114;
	public const uint32 SECPKG_ATTR_SESSION_TICKET_KEYS = 115;
	public const uint32 SESSION_TICKET_INFO_V0 = 0;
	public const uint32 SESSION_TICKET_INFO_VERSION = 0;
	public const int32 LSA_MODE_PASSWORD_PROTECTED = 1;
	public const int32 LSA_MODE_INDIVIDUAL_ACCOUNTS = 2;
	public const int32 LSA_MODE_MANDATORY_ACCESS = 4;
	public const int32 LSA_MODE_LOG_FULL = 8;
	public const int32 LSA_MAXIMUM_SID_COUNT = 256;
	public const uint32 LSA_MAXIMUM_ENUMERATION_LENGTH = 32000;
	public const uint32 LSA_CALL_LICENSE_SERVER = 2147483648;
	public const uint32 SE_ADT_OBJECT_ONLY = 1;
	public const uint32 SE_MAX_AUDIT_PARAMETERS = 32;
	public const uint32 SE_MAX_GENERIC_AUDIT_PARAMETERS = 28;
	public const uint32 SE_ADT_PARAMETERS_SELF_RELATIVE = 1;
	public const uint32 SE_ADT_PARAMETERS_SEND_TO_LSA = 2;
	public const uint32 SE_ADT_PARAMETER_EXTENSIBLE_AUDIT = 4;
	public const uint32 SE_ADT_PARAMETER_GENERIC_AUDIT = 8;
	public const uint32 SE_ADT_PARAMETER_WRITE_SYNCHRONOUS = 16;
	public const String LSA_ADT_SECURITY_SOURCE_NAME = "Microsoft-Windows-Security-Auditing";
	public const String LSA_ADT_LEGACY_SECURITY_SOURCE_NAME = "Security";
	public const uint32 SE_ADT_POLICY_AUDIT_EVENT_TYPE_EX_BEGIN = 100;
	public const int32 POLICY_AUDIT_EVENT_UNCHANGED = 0;
	public const int32 POLICY_AUDIT_EVENT_SUCCESS = 1;
	public const int32 POLICY_AUDIT_EVENT_FAILURE = 2;
	public const int32 POLICY_AUDIT_EVENT_NONE = 4;
	public const String LSA_AP_NAME_INITIALIZE_PACKAGE = "LsaApInitializePackage\u{0000}";
	public const String LSA_AP_NAME_LOGON_USER = "LsaApLogonUser\u{0000}";
	public const String LSA_AP_NAME_LOGON_USER_EX = "LsaApLogonUserEx\u{0000}";
	public const String LSA_AP_NAME_CALL_PACKAGE = "LsaApCallPackage\u{0000}";
	public const String LSA_AP_NAME_LOGON_TERMINATED = "LsaApLogonTerminated\u{0000}";
	public const String LSA_AP_NAME_CALL_PACKAGE_UNTRUSTED = "LsaApCallPackageUntrusted\u{0000}";
	public const String LSA_AP_NAME_CALL_PACKAGE_PASSTHROUGH = "LsaApCallPackagePassthrough\u{0000}";
	public const int32 POLICY_VIEW_LOCAL_INFORMATION = 1;
	public const int32 POLICY_VIEW_AUDIT_INFORMATION = 2;
	public const int32 POLICY_GET_PRIVATE_INFORMATION = 4;
	public const int32 POLICY_TRUST_ADMIN = 8;
	public const int32 POLICY_CREATE_ACCOUNT = 16;
	public const int32 POLICY_CREATE_SECRET = 32;
	public const int32 POLICY_CREATE_PRIVILEGE = 64;
	public const int32 POLICY_SET_DEFAULT_QUOTA_LIMITS = 128;
	public const int32 POLICY_SET_AUDIT_REQUIREMENTS = 256;
	public const int32 POLICY_AUDIT_LOG_ADMIN = 512;
	public const int32 POLICY_SERVER_ADMIN = 1024;
	public const int32 POLICY_LOOKUP_NAMES = 2048;
	public const int32 POLICY_NOTIFICATION = 4096;
	public const uint32 LSA_LOOKUP_ISOLATED_AS_LOCAL = 2147483648;
	public const uint32 LSA_LOOKUP_DISALLOW_CONNECTED_ACCOUNT_INTERNET_SID = 2147483648;
	public const uint32 LSA_LOOKUP_PREFER_INTERNET_NAMES = 1073741824;
	public const uint32 PER_USER_POLICY_UNCHANGED = 0;
	public const uint32 PER_USER_AUDIT_SUCCESS_INCLUDE = 1;
	public const uint32 PER_USER_AUDIT_SUCCESS_EXCLUDE = 2;
	public const uint32 PER_USER_AUDIT_FAILURE_INCLUDE = 4;
	public const uint32 PER_USER_AUDIT_FAILURE_EXCLUDE = 8;
	public const uint32 PER_USER_AUDIT_NONE = 16;
	public const uint32 POLICY_QOS_SCHANNEL_REQUIRED = 1;
	public const uint32 POLICY_QOS_OUTBOUND_INTEGRITY = 2;
	public const uint32 POLICY_QOS_OUTBOUND_CONFIDENTIALITY = 4;
	public const uint32 POLICY_QOS_INBOUND_INTEGRITY = 8;
	public const uint32 POLICY_QOS_INBOUND_CONFIDENTIALITY = 16;
	public const uint32 POLICY_QOS_ALLOW_LOCAL_ROOT_CERT_STORE = 32;
	public const uint32 POLICY_QOS_RAS_SERVER_ALLOWED = 64;
	public const uint32 POLICY_QOS_DHCP_SERVER_ALLOWED = 128;
	public const uint32 POLICY_KERBEROS_VALIDATE_CLIENT = 128;
	public const int32 ACCOUNT_VIEW = 1;
	public const int32 ACCOUNT_ADJUST_PRIVILEGES = 2;
	public const int32 ACCOUNT_ADJUST_QUOTAS = 4;
	public const int32 ACCOUNT_ADJUST_SYSTEM_ACCESS = 8;
	public const int32 TRUSTED_QUERY_DOMAIN_NAME = 1;
	public const int32 TRUSTED_QUERY_CONTROLLERS = 2;
	public const int32 TRUSTED_SET_CONTROLLERS = 4;
	public const int32 TRUSTED_QUERY_POSIX = 8;
	public const int32 TRUSTED_SET_POSIX = 16;
	public const int32 TRUSTED_SET_AUTH = 32;
	public const int32 TRUSTED_QUERY_AUTH = 64;
	public const uint32 TRUST_ATTRIBUTE_TREE_PARENT = 4194304;
	public const uint32 TRUST_ATTRIBUTE_TREE_ROOT = 8388608;
	public const uint32 TRUST_ATTRIBUTES_VALID = 4278386687;
	public const uint32 TRUST_ATTRIBUTE_QUARANTINED_DOMAIN = 4;
	public const uint32 TRUST_ATTRIBUTE_TRUST_USES_RC4_ENCRYPTION = 128;
	public const uint32 TRUST_ATTRIBUTE_TRUST_USES_AES_KEYS = 256;
	public const uint32 TRUST_ATTRIBUTE_CROSS_ORGANIZATION_NO_TGT_DELEGATION = 512;
	public const uint32 TRUST_ATTRIBUTE_PIM_TRUST = 1024;
	public const uint32 TRUST_ATTRIBUTE_CROSS_ORGANIZATION_ENABLE_TGT_DELEGATION = 2048;
	public const uint32 TRUST_ATTRIBUTES_USER = 4278190080;
	public const uint32 LSA_FOREST_TRUST_RECORD_TYPE_UNRECOGNIZED = 2147483648;
	public const int32 LSA_FTRECORD_DISABLED_REASONS = 65535;
	public const int32 LSA_TLN_DISABLED_NEW = 1;
	public const int32 LSA_TLN_DISABLED_ADMIN = 2;
	public const int32 LSA_TLN_DISABLED_CONFLICT = 4;
	public const int32 LSA_SID_DISABLED_ADMIN = 1;
	public const int32 LSA_SID_DISABLED_CONFLICT = 2;
	public const int32 LSA_NB_DISABLED_ADMIN = 4;
	public const int32 LSA_NB_DISABLED_CONFLICT = 8;
	public const uint32 MAX_RECORDS_IN_FOREST_TRUST_INFO = 4000;
	public const int32 SECRET_SET_VALUE = 1;
	public const int32 SECRET_QUERY_VALUE = 2;
	public const String LSA_GLOBAL_SECRET_PREFIX = "G$";
	public const uint32 LSA_GLOBAL_SECRET_PREFIX_LENGTH = 2;
	public const String LSA_LOCAL_SECRET_PREFIX = "L$";
	public const uint32 LSA_LOCAL_SECRET_PREFIX_LENGTH = 2;
	public const String LSA_MACHINE_SECRET_PREFIX = "M$";
	public const int32 LSA_SECRET_MAXIMUM_COUNT = 4096;
	public const int32 LSA_SECRET_MAXIMUM_LENGTH = 512;
	public const uint32 MAXIMUM_CAPES_PER_CAP = 127;
	public const uint32 CENTRAL_ACCESS_POLICY_OWNER_RIGHTS_PRESENT_FLAG = 1;
	public const uint32 CENTRAL_ACCESS_POLICY_STAGED_OWNER_RIGHTS_PRESENT_FLAG = 256;
	public const uint32 CENTRAL_ACCESS_POLICY_STAGED_FLAG = 65536;
	public const uint32 LSASETCAPS_RELOAD_FLAG = 1;
	public const uint32 LSASETCAPS_VALID_FLAG_MASK = 1;
	public const String SE_INTERACTIVE_LOGON_NAME = "SeInteractiveLogonRight";
	public const String SE_NETWORK_LOGON_NAME = "SeNetworkLogonRight";
	public const String SE_BATCH_LOGON_NAME = "SeBatchLogonRight";
	public const String SE_SERVICE_LOGON_NAME = "SeServiceLogonRight";
	public const String SE_DENY_INTERACTIVE_LOGON_NAME = "SeDenyInteractiveLogonRight";
	public const String SE_DENY_NETWORK_LOGON_NAME = "SeDenyNetworkLogonRight";
	public const String SE_DENY_BATCH_LOGON_NAME = "SeDenyBatchLogonRight";
	public const String SE_DENY_SERVICE_LOGON_NAME = "SeDenyServiceLogonRight";
	public const String SE_REMOTE_INTERACTIVE_LOGON_NAME = "SeRemoteInteractiveLogonRight";
	public const String SE_DENY_REMOTE_INTERACTIVE_LOGON_NAME = "SeDenyRemoteInteractiveLogonRight";
	public const uint32 NEGOTIATE_MAX_PREFIX = 32;
	public const uint32 NEGOTIATE_ALLOW_NTLM = 268435456;
	public const uint32 NEGOTIATE_NEG_NTLM = 536870912;
	public const uint32 MAX_USER_RECORDS = 1000;
	public const Guid Audit_System_SecurityStateChange = .(0x0cce9210, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_System_SecuritySubsystemExtension = .(0x0cce9211, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_System_Integrity = .(0x0cce9212, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_System_IPSecDriverEvents = .(0x0cce9213, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_System_Others = .(0x0cce9214, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_Logon = .(0x0cce9215, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_Logoff = .(0x0cce9216, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_AccountLockout = .(0x0cce9217, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_IPSecMainMode = .(0x0cce9218, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_IPSecQuickMode = .(0x0cce9219, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_IPSecUserMode = .(0x0cce921a, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_SpecialLogon = .(0x0cce921b, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_Others = .(0x0cce921c, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_FileSystem = .(0x0cce921d, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_Registry = .(0x0cce921e, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_Kernel = .(0x0cce921f, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_Sam = .(0x0cce9220, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_CertificationServices = .(0x0cce9221, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_ApplicationGenerated = .(0x0cce9222, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_Handle = .(0x0cce9223, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_Share = .(0x0cce9224, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_FirewallPacketDrops = .(0x0cce9225, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_FirewallConnection = .(0x0cce9226, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_Other = .(0x0cce9227, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PrivilegeUse_Sensitive = .(0x0cce9228, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PrivilegeUse_NonSensitive = .(0x0cce9229, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PrivilegeUse_Others = .(0x0cce922a, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_DetailedTracking_ProcessCreation = .(0x0cce922b, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_DetailedTracking_ProcessTermination = .(0x0cce922c, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_DetailedTracking_DpapiActivity = .(0x0cce922d, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_DetailedTracking_RpcCall = .(0x0cce922e, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PolicyChange_AuditPolicy = .(0x0cce922f, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PolicyChange_AuthenticationPolicy = .(0x0cce9230, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PolicyChange_AuthorizationPolicy = .(0x0cce9231, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PolicyChange_MpsscvRulePolicy = .(0x0cce9232, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PolicyChange_WfpIPSecPolicy = .(0x0cce9233, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PolicyChange_Others = .(0x0cce9234, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountManagement_UserAccount = .(0x0cce9235, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountManagement_ComputerAccount = .(0x0cce9236, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountManagement_SecurityGroup = .(0x0cce9237, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountManagement_DistributionGroup = .(0x0cce9238, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountManagement_ApplicationGroup = .(0x0cce9239, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountManagement_Others = .(0x0cce923a, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_DSAccess_DSAccess = .(0x0cce923b, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_DsAccess_AdAuditChanges = .(0x0cce923c, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Ds_Replication = .(0x0cce923d, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Ds_DetailedReplication = .(0x0cce923e, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountLogon_CredentialValidation = .(0x0cce923f, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountLogon_Kerberos = .(0x0cce9240, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountLogon_Others = .(0x0cce9241, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountLogon_KerbCredentialValidation = .(0x0cce9242, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_NPS = .(0x0cce9243, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_DetailedFileShare = .(0x0cce9244, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_RemovableStorage = .(0x0cce9245, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess_CbacStaging = .(0x0cce9246, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_Claims = .(0x0cce9247, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_DetailedTracking_PnpActivity = .(0x0cce9248, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon_Groups = .(0x0cce9249, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_DetailedTracking_TokenRightAdjusted = .(0x0cce924a, 0x69ae, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_System = .(0x69979848, 0x797a, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_Logon = .(0x69979849, 0x797a, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_ObjectAccess = .(0x6997984a, 0x797a, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PrivilegeUse = .(0x6997984b, 0x797a, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_DetailedTracking = .(0x6997984c, 0x797a, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_PolicyChange = .(0x6997984d, 0x797a, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountManagement = .(0x6997984e, 0x797a, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_DirectoryServiceAccess = .(0x6997984f, 0x797a, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const Guid Audit_AccountLogon = .(0x69979850, 0x797a, 0x11d9, 0xbe, 0xd3, 0x50, 0x50, 0x54, 0x50, 0x30, 0x30);
	public const int32 DOMAIN_NO_LM_OWF_CHANGE = 64;
	public const String SAM_PASSWORD_CHANGE_NOTIFY_ROUTINE = "PasswordChangeNotify";
	public const String SAM_INIT_NOTIFICATION_ROUTINE = "InitializeChangeNotify";
	public const String SAM_PASSWORD_FILTER_ROUTINE = "PasswordFilter";
	public const String MSV1_0_PACKAGE_NAME = "MICROSOFT_AUTHENTICATION_PACKAGE_V1_0";
	public const String MSV1_0_PACKAGE_NAMEW = "MICROSOFT_AUTHENTICATION_PACKAGE_V1_0";
	public const String MSV1_0_SUBAUTHENTICATION_KEY = "SYSTEM\\CurrentControlSet\\Control\\Lsa\\MSV1_0";
	public const String MSV1_0_SUBAUTHENTICATION_VALUE = "Auth";
	public const uint32 MSV1_0_CHALLENGE_LENGTH = 8;
	public const uint32 MSV1_0_USER_SESSION_KEY_LENGTH = 16;
	public const uint32 MSV1_0_LANMAN_SESSION_KEY_LENGTH = 8;
	public const uint32 MSV1_0_USE_CLIENT_CHALLENGE = 128;
	public const uint32 MSV1_0_DISABLE_PERSONAL_FALLBACK = 4096;
	public const uint32 MSV1_0_ALLOW_FORCE_GUEST = 8192;
	public const uint32 MSV1_0_CLEARTEXT_PASSWORD_SUPPLIED = 16384;
	public const uint32 MSV1_0_USE_DOMAIN_FOR_ROUTING_ONLY = 32768;
	public const uint32 MSV1_0_SUBAUTHENTICATION_DLL_EX = 1048576;
	public const uint32 MSV1_0_ALLOW_MSVCHAPV2 = 65536;
	public const uint32 MSV1_0_S4U2SELF = 131072;
	public const uint32 MSV1_0_CHECK_LOGONHOURS_FOR_S4U = 262144;
	public const uint32 MSV1_0_INTERNET_DOMAIN = 524288;
	public const uint32 MSV1_0_SUBAUTHENTICATION_DLL = 4278190080;
	public const uint32 MSV1_0_SUBAUTHENTICATION_DLL_SHIFT = 24;
	public const uint32 MSV1_0_MNS_LOGON = 16777216;
	public const uint32 MSV1_0_SUBAUTHENTICATION_DLL_RAS = 2;
	public const uint32 MSV1_0_SUBAUTHENTICATION_DLL_IIS = 132;
	public const uint32 MSV1_0_S4U_LOGON_FLAG_CHECK_LOGONHOURS = 2;
	public const uint32 LOGON_NTLMV2_ENABLED = 256;
	public const uint32 LOGON_NT_V2 = 2048;
	public const uint32 LOGON_LM_V2 = 4096;
	public const uint32 LOGON_NTLM_V2 = 8192;
	public const uint32 LOGON_OPTIMIZED = 16384;
	public const uint32 LOGON_WINLOGON = 32768;
	public const uint32 LOGON_PKINIT = 65536;
	public const uint32 LOGON_NO_OPTIMIZED = 131072;
	public const uint32 LOGON_NO_ELEVATION = 262144;
	public const uint32 LOGON_MANAGED_SERVICE = 524288;
	public const uint32 MSV1_0_SUBAUTHENTICATION_FLAGS = 4278190080;
	public const uint32 LOGON_GRACE_LOGON = 16777216;
	public const uint32 MSV1_0_OWF_PASSWORD_LENGTH = 16;
	public const uint32 MSV1_0_SHA_PASSWORD_LENGTH = 20;
	public const uint32 MSV1_0_CREDENTIAL_KEY_LENGTH = 20;
	public const uint32 MSV1_0_CRED_REMOVED = 4;
	public const uint32 MSV1_0_CRED_CREDKEY_PRESENT = 8;
	public const uint32 MSV1_0_CRED_SHA_PRESENT = 16;
	public const uint32 MSV1_0_CRED_VERSION_V2 = 2;
	public const uint32 MSV1_0_CRED_VERSION_V3 = 4;
	public const uint32 MSV1_0_CRED_VERSION_IUM = 4294901761;
	public const uint32 MSV1_0_CRED_VERSION_REMOTE = 4294901762;
	public const uint32 MSV1_0_CRED_VERSION_ARSO = 4294901763;
	public const uint32 MSV1_0_CRED_VERSION_RESERVED_1 = 4294967294;
	public const uint32 MSV1_0_CRED_VERSION_INVALID = 4294967295;
	public const uint32 MSV1_0_NTLM3_RESPONSE_LENGTH = 16;
	public const uint32 MSV1_0_NTLM3_OWF_LENGTH = 16;
	public const uint32 MSV1_0_MAX_NTLM3_LIFE = 1800;
	public const uint32 MSV1_0_MAX_AVL_SIZE = 64000;
	public const uint32 MSV1_0_AV_FLAG_FORCE_GUEST = 1;
	public const uint32 MSV1_0_AV_FLAG_MIC_HANDSHAKE_MESSAGES = 2;
	public const uint32 MSV1_0_AV_FLAG_UNVERIFIED_TARGET = 4;
	public const uint32 RTL_ENCRYPT_MEMORY_SIZE = 8;
	public const uint32 RTL_ENCRYPT_OPTION_CROSS_PROCESS = 1;
	public const uint32 RTL_ENCRYPT_OPTION_SAME_LOGON = 2;
	public const uint32 RTL_ENCRYPT_OPTION_FOR_SYSTEM = 4;
	public const uint32 KERBEROS_VERSION = 5;
	public const uint32 KERBEROS_REVISION = 6;
	public const uint32 KERB_ETYPE_AES128_CTS_HMAC_SHA1_96 = 17;
	public const uint32 KERB_ETYPE_AES256_CTS_HMAC_SHA1_96 = 18;
	public const int32 KERB_ETYPE_RC4_PLAIN2 = -129;
	public const int32 KERB_ETYPE_RC4_LM = -130;
	public const int32 KERB_ETYPE_RC4_SHA = -131;
	public const int32 KERB_ETYPE_DES_PLAIN = -132;
	public const int32 KERB_ETYPE_RC4_HMAC_OLD = -133;
	public const int32 KERB_ETYPE_RC4_PLAIN_OLD = -134;
	public const int32 KERB_ETYPE_RC4_HMAC_OLD_EXP = -135;
	public const int32 KERB_ETYPE_RC4_PLAIN_OLD_EXP = -136;
	public const int32 KERB_ETYPE_RC4_PLAIN = -140;
	public const int32 KERB_ETYPE_RC4_PLAIN_EXP = -141;
	public const int32 KERB_ETYPE_AES128_CTS_HMAC_SHA1_96_PLAIN = -148;
	public const int32 KERB_ETYPE_AES256_CTS_HMAC_SHA1_96_PLAIN = -149;
	public const uint32 KERB_ETYPE_DSA_SHA1_CMS = 9;
	public const uint32 KERB_ETYPE_RSA_MD5_CMS = 10;
	public const uint32 KERB_ETYPE_RSA_SHA1_CMS = 11;
	public const uint32 KERB_ETYPE_RC2_CBC_ENV = 12;
	public const uint32 KERB_ETYPE_RSA_ENV = 13;
	public const uint32 KERB_ETYPE_RSA_ES_OEAP_ENV = 14;
	public const uint32 KERB_ETYPE_DES_EDE3_CBC_ENV = 15;
	public const uint32 KERB_ETYPE_DSA_SIGN = 8;
	public const uint32 KERB_ETYPE_RSA_PRIV = 9;
	public const uint32 KERB_ETYPE_RSA_PUB = 10;
	public const uint32 KERB_ETYPE_RSA_PUB_MD5 = 11;
	public const uint32 KERB_ETYPE_RSA_PUB_SHA1 = 12;
	public const uint32 KERB_ETYPE_PKCS7_PUB = 13;
	public const uint32 KERB_ETYPE_DES3_CBC_MD5 = 5;
	public const uint32 KERB_ETYPE_DES3_CBC_SHA1 = 7;
	public const uint32 KERB_ETYPE_DES3_CBC_SHA1_KD = 16;
	public const uint32 KERB_ETYPE_DES_CBC_MD5_NT = 20;
	public const uint32 KERB_ETYPE_RC4_HMAC_NT_EXP = 24;
	public const uint32 KERB_CHECKSUM_NONE = 0;
	public const uint32 KERB_CHECKSUM_CRC32 = 1;
	public const uint32 KERB_CHECKSUM_MD4 = 2;
	public const uint32 KERB_CHECKSUM_KRB_DES_MAC = 4;
	public const uint32 KERB_CHECKSUM_KRB_DES_MAC_K = 5;
	public const uint32 KERB_CHECKSUM_MD5 = 7;
	public const uint32 KERB_CHECKSUM_MD5_DES = 8;
	public const uint32 KERB_CHECKSUM_SHA1_NEW = 14;
	public const uint32 KERB_CHECKSUM_HMAC_SHA1_96_AES128 = 15;
	public const uint32 KERB_CHECKSUM_HMAC_SHA1_96_AES256 = 16;
	public const int32 KERB_CHECKSUM_LM = -130;
	public const int32 KERB_CHECKSUM_SHA1 = -131;
	public const int32 KERB_CHECKSUM_REAL_CRC32 = -132;
	public const int32 KERB_CHECKSUM_DES_MAC = -133;
	public const int32 KERB_CHECKSUM_DES_MAC_MD5 = -134;
	public const int32 KERB_CHECKSUM_MD25 = -135;
	public const int32 KERB_CHECKSUM_RC4_MD5 = -136;
	public const int32 KERB_CHECKSUM_MD5_HMAC = -137;
	public const int32 KERB_CHECKSUM_HMAC_MD5 = -138;
	public const int32 KERB_CHECKSUM_HMAC_SHA1_96_AES128_Ki = -150;
	public const int32 KERB_CHECKSUM_HMAC_SHA1_96_AES256_Ki = -151;
	public const uint32 AUTH_REQ_ALLOW_FORWARDABLE = 1;
	public const uint32 AUTH_REQ_ALLOW_PROXIABLE = 2;
	public const uint32 AUTH_REQ_ALLOW_POSTDATE = 4;
	public const uint32 AUTH_REQ_ALLOW_RENEWABLE = 8;
	public const uint32 AUTH_REQ_ALLOW_NOADDRESS = 16;
	public const uint32 AUTH_REQ_ALLOW_ENC_TKT_IN_SKEY = 32;
	public const uint32 AUTH_REQ_ALLOW_VALIDATE = 64;
	public const uint32 AUTH_REQ_VALIDATE_CLIENT = 128;
	public const uint32 AUTH_REQ_OK_AS_DELEGATE = 256;
	public const uint32 AUTH_REQ_PREAUTH_REQUIRED = 512;
	public const uint32 AUTH_REQ_TRANSITIVE_TRUST = 1024;
	public const uint32 AUTH_REQ_ALLOW_S4U_DELEGATE = 2048;
	public const uint32 KERB_TICKET_FLAGS_name_canonicalize = 65536;
	public const uint32 KERB_TICKET_FLAGS_cname_in_pa_data = 262144;
	public const uint32 KERB_TICKET_FLAGS_enc_pa_rep = 65536;
	public const uint32 KRB_NT_UNKNOWN = 0;
	public const uint32 KRB_NT_PRINCIPAL = 1;
	public const int32 KRB_NT_PRINCIPAL_AND_ID = -131;
	public const uint32 KRB_NT_SRV_INST = 2;
	public const int32 KRB_NT_SRV_INST_AND_ID = -132;
	public const uint32 KRB_NT_SRV_HST = 3;
	public const uint32 KRB_NT_SRV_XHST = 4;
	public const uint32 KRB_NT_UID = 5;
	public const uint32 KRB_NT_ENTERPRISE_PRINCIPAL = 10;
	public const uint32 KRB_NT_WELLKNOWN = 11;
	public const int32 KRB_NT_ENT_PRINCIPAL_AND_ID = -130;
	public const int32 KRB_NT_MS_PRINCIPAL = -128;
	public const int32 KRB_NT_MS_PRINCIPAL_AND_ID = -129;
	public const int32 KRB_NT_MS_BRANCH_ID = -133;
	public const uint32 KRB_NT_X500_PRINCIPAL = 6;
	public const String KRB_WELLKNOWN_STRING = "WELLKNOWN";
	public const String KRB_ANONYMOUS_STRING = "ANONYMOUS";
	public const uint32 KERB_WRAP_NO_ENCRYPT = 2147483649;
	public const uint32 KERB_CERTIFICATE_LOGON_FLAG_CHECK_DUPLICATES = 1;
	public const uint32 KERB_CERTIFICATE_LOGON_FLAG_USE_CERTIFICATE_INFO = 2;
	public const uint32 KERB_CERTIFICATE_S4U_LOGON_FLAG_CHECK_DUPLICATES = 1;
	public const uint32 KERB_CERTIFICATE_S4U_LOGON_FLAG_CHECK_LOGONHOURS = 2;
	public const uint32 KERB_CERTIFICATE_S4U_LOGON_FLAG_FAIL_IF_NT_AUTH_POLICY_REQUIRED = 4;
	public const uint32 KERB_CERTIFICATE_S4U_LOGON_FLAG_IDENTIFY = 8;
	public const uint32 KERB_LOGON_FLAG_ALLOW_EXPIRED_TICKET = 1;
	public const uint32 KERB_LOGON_FLAG_REDIRECTED = 2;
	public const uint32 KERB_S4U_LOGON_FLAG_CHECK_LOGONHOURS = 2;
	public const uint32 KERB_S4U_LOGON_FLAG_IDENTIFY = 8;
	public const uint32 KERB_USE_DEFAULT_TICKET_FLAGS = 0;
	public const uint32 KERB_RETRIEVE_TICKET_DEFAULT = 0;
	public const uint32 KERB_RETRIEVE_TICKET_DONT_USE_CACHE = 1;
	public const uint32 KERB_RETRIEVE_TICKET_USE_CACHE_ONLY = 2;
	public const uint32 KERB_RETRIEVE_TICKET_USE_CREDHANDLE = 4;
	public const uint32 KERB_RETRIEVE_TICKET_AS_KERB_CRED = 8;
	public const uint32 KERB_RETRIEVE_TICKET_WITH_SEC_CRED = 16;
	public const uint32 KERB_RETRIEVE_TICKET_CACHE_TICKET = 32;
	public const uint32 KERB_RETRIEVE_TICKET_MAX_LIFETIME = 64;
	public const uint32 KERB_ETYPE_DEFAULT = 0;
	public const uint32 KERB_PURGE_ALL_TICKETS = 1;
	public const uint32 KERB_S4U2PROXY_CACHE_ENTRY_INFO_FLAG_NEGATIVE = 1;
	public const uint32 KERB_S4U2PROXY_CRED_FLAG_NEGATIVE = 1;
	public const uint32 KERB_REFRESH_POLICY_KERBEROS = 1;
	public const uint32 KERB_REFRESH_POLICY_KDC = 2;
	public const uint32 KERB_CLOUD_KERBEROS_DEBUG_DATA_VERSION = 0;
	public const uint32 DS_UNKNOWN_ADDRESS_TYPE = 0;
	public const uint32 KERB_SETPASS_USE_LOGONID = 1;
	public const uint32 KERB_SETPASS_USE_CREDHANDLE = 2;
	public const uint32 KERB_DECRYPT_FLAG_DEFAULT_KEY = 1;
	public const uint32 KERB_REFRESH_SCCRED_RELEASE = 0;
	public const uint32 KERB_REFRESH_SCCRED_GETTGT = 1;
	public const uint32 KERB_TRANSFER_CRED_WITH_TICKETS = 1;
	public const uint32 KERB_TRANSFER_CRED_CLEANUP_CREDENTIALS = 2;
	public const uint32 KERB_QUERY_DOMAIN_EXTENDED_POLICIES_RESPONSE_FLAG_DAC_DISABLED = 1;
	public const uint32 AUDIT_SET_SYSTEM_POLICY = 1;
	public const uint32 AUDIT_QUERY_SYSTEM_POLICY = 2;
	public const uint32 AUDIT_SET_USER_POLICY = 4;
	public const uint32 AUDIT_QUERY_USER_POLICY = 8;
	public const uint32 AUDIT_ENUMERATE_USERS = 16;
	public const uint32 AUDIT_SET_MISC_POLICY = 32;
	public const uint32 AUDIT_QUERY_MISC_POLICY = 64;
	public const String PKU2U_PACKAGE_NAME_A = "pku2u";
	public const String PKU2U_PACKAGE_NAME = "pku2u";
	public const String PKU2U_PACKAGE_NAME_W = "pku2u";
	public const String SAM_CREDENTIAL_UPDATE_NOTIFY_ROUTINE = "CredentialUpdateNotify";
	public const String SAM_CREDENTIAL_UPDATE_REGISTER_ROUTINE = "CredentialUpdateRegister";
	public const String SAM_CREDENTIAL_UPDATE_FREE_ROUTINE = "CredentialUpdateFree";
	public const String SAM_CREDENTIAL_UPDATE_REGISTER_MAPPED_ENTRYPOINTS_ROUTINE = "RegisterMappedEntrypoints";
	public const uint32 SECPKG_CLIENT_PROCESS_TERMINATED = 1;
	public const uint32 SECPKG_CLIENT_THREAD_TERMINATED = 2;
	public const uint32 SECPKG_CALL_KERNEL_MODE = 1;
	public const uint32 SECPKG_CALL_ANSI = 2;
	public const uint32 SECPKG_CALL_URGENT = 4;
	public const uint32 SECPKG_CALL_RECURSIVE = 8;
	public const uint32 SECPKG_CALL_IN_PROC = 16;
	public const uint32 SECPKG_CALL_CLEANUP = 32;
	public const uint32 SECPKG_CALL_WOWCLIENT = 64;
	public const uint32 SECPKG_CALL_THREAD_TERM = 128;
	public const uint32 SECPKG_CALL_PROCESS_TERM = 256;
	public const uint32 SECPKG_CALL_IS_TCB = 512;
	public const uint32 SECPKG_CALL_NETWORK_ONLY = 1024;
	public const uint32 SECPKG_CALL_WINLOGON = 2048;
	public const uint32 SECPKG_CALL_ASYNC_UPDATE = 4096;
	public const uint32 SECPKG_CALL_SYSTEM_PROC = 8192;
	public const uint32 SECPKG_CALL_NEGO = 16384;
	public const uint32 SECPKG_CALL_NEGO_EXTENDER = 32768;
	public const uint32 SECPKG_CALL_BUFFER_MARSHAL = 65536;
	public const uint32 SECPKG_CALL_UNLOCK = 131072;
	public const uint32 SECPKG_CALL_CLOUDAP_CONNECT = 262144;
	public const uint32 SECPKG_CALL_WOWX86 = 64;
	public const uint32 SECPKG_CALL_WOWA32 = 262144;
	public const uint32 SECPKG_CREDENTIAL_VERSION = 201;
	public const uint32 SECPKG_CREDENTIAL_FLAGS_CALLER_HAS_TCB = 1;
	public const uint32 SECPKG_CREDENTIAL_FLAGS_CREDMAN_CRED = 2;
	public const uint32 SECPKG_SURROGATE_LOGON_VERSION_1 = 1;
	public const uint32 SECBUFFER_UNMAPPED = 1073741824;
	public const uint32 SECBUFFER_KERNEL_MAP = 536870912;
	public const uint32 PRIMARY_CRED_CLEAR_PASSWORD = 1;
	public const uint32 PRIMARY_CRED_OWF_PASSWORD = 2;
	public const uint32 PRIMARY_CRED_UPDATE = 4;
	public const uint32 PRIMARY_CRED_CACHED_LOGON = 8;
	public const uint32 PRIMARY_CRED_LOGON_NO_TCB = 16;
	public const uint32 PRIMARY_CRED_LOGON_LUA = 32;
	public const uint32 PRIMARY_CRED_INTERACTIVE_SMARTCARD_LOGON = 64;
	public const uint32 PRIMARY_CRED_REFRESH_NEEDED = 128;
	public const uint32 PRIMARY_CRED_INTERNET_USER = 256;
	public const uint32 PRIMARY_CRED_AUTH_ID = 512;
	public const uint32 PRIMARY_CRED_DO_NOT_SPLIT = 1024;
	public const uint32 PRIMARY_CRED_PROTECTED_USER = 2048;
	public const uint32 PRIMARY_CRED_EX = 4096;
	public const uint32 PRIMARY_CRED_TRANSFER = 8192;
	public const uint32 PRIMARY_CRED_RESTRICTED_TS = 16384;
	public const uint32 PRIMARY_CRED_PACKED_CREDS = 32768;
	public const uint32 PRIMARY_CRED_ENTERPRISE_INTERNET_USER = 65536;
	public const uint32 PRIMARY_CRED_ENCRYPTED_CREDGUARD_PASSWORD = 131072;
	public const uint32 PRIMARY_CRED_CACHED_INTERACTIVE_LOGON = 262144;
	public const uint32 PRIMARY_CRED_INTERACTIVE_NGC_LOGON = 524288;
	public const uint32 PRIMARY_CRED_INTERACTIVE_FIDO_LOGON = 1048576;
	public const uint32 PRIMARY_CRED_ARSO_LOGON = 2097152;
	public const uint32 PRIMARY_CRED_SUPPLEMENTAL = 4194304;
	public const uint32 PRIMARY_CRED_LOGON_PACKAGE_SHIFT = 24;
	public const uint32 PRIMARY_CRED_PACKAGE_MASK = 4278190080;
	public const uint32 SECPKG_PRIMARY_CRED_EX_FLAGS_EX_DELEGATION_TOKEN = 1;
	public const uint32 MAX_CRED_SIZE = 1024;
	public const uint32 SECPKG_STATE_ENCRYPTION_PERMITTED = 1;
	public const uint32 SECPKG_STATE_STRONG_ENCRYPTION_PERMITTED = 2;
	public const uint32 SECPKG_STATE_DOMAIN_CONTROLLER = 4;
	public const uint32 SECPKG_STATE_WORKSTATION = 8;
	public const uint32 SECPKG_STATE_STANDALONE = 16;
	public const uint32 SECPKG_STATE_CRED_ISOLATION_ENABLED = 32;
	public const uint32 SECPKG_STATE_RESERVED_1 = 2147483648;
	public const uint32 SECPKG_MAX_OID_LENGTH = 32;
	public const uint32 SECPKG_ATTR_SASL_CONTEXT = 65536;
	public const uint32 SECPKG_ATTR_THUNK_ALL = 65536;
	public const uint32 UNDERSTANDS_LONG_NAMES = 1;
	public const uint32 NO_LONG_NAMES = 2;
	public const uint32 SECPKG_CALL_PACKAGE_TRANSFER_CRED_REQUEST_FLAG_OPTIMISTIC_LOGON = 1;
	public const uint32 SECPKG_CALL_PACKAGE_TRANSFER_CRED_REQUEST_FLAG_CLEANUP_CREDENTIALS = 2;
	public const uint32 SECPKG_CALL_PACKAGE_TRANSFER_CRED_REQUEST_FLAG_TO_SSO_SESSION = 4;
	public const uint32 NOTIFIER_FLAG_NEW_THREAD = 1;
	public const uint32 NOTIFIER_FLAG_ONE_SHOT = 2;
	public const uint32 NOTIFIER_FLAG_SECONDS = 2147483648;
	public const uint32 NOTIFIER_TYPE_INTERVAL = 1;
	public const uint32 NOTIFIER_TYPE_HANDLE_WAIT = 2;
	public const uint32 NOTIFIER_TYPE_STATE_CHANGE = 3;
	public const uint32 NOTIFIER_TYPE_NOTIFY_EVENT = 4;
	public const uint32 NOTIFIER_TYPE_IMMEDIATE = 16;
	public const uint32 NOTIFY_CLASS_PACKAGE_CHANGE = 1;
	public const uint32 NOTIFY_CLASS_ROLE_CHANGE = 2;
	public const uint32 NOTIFY_CLASS_DOMAIN_CHANGE = 3;
	public const uint32 NOTIFY_CLASS_REGISTRY_CHANGE = 4;
	public const uint32 LSA_QUERY_CLIENT_PRELOGON_SESSION_ID = 1;
	public const uint32 CREDP_FLAGS_IN_PROCESS = 1;
	public const uint32 CREDP_FLAGS_USE_MIDL_HEAP = 2;
	public const uint32 CREDP_FLAGS_DONT_CACHE_TI = 4;
	public const uint32 CREDP_FLAGS_CLEAR_PASSWORD = 8;
	public const uint32 CREDP_FLAGS_USER_ENCRYPTED_PASSWORD = 16;
	public const uint32 CREDP_FLAGS_TRUSTED_CALLER = 32;
	public const uint32 CREDP_FLAGS_VALIDATE_PROXY_TARGET = 64;
	public const uint32 CRED_MARSHALED_TI_SIZE_SIZE = 12;
	public const String LSA_AP_NAME_LOGON_USER_EX2 = "LsaApLogonUserEx2\u{0000}";
	public const String SP_ACCEPT_CREDENTIALS_NAME = "SpAcceptCredentials\u{0000}";
	public const uint32 SECPKG_UNICODE_ATTRIBUTE = 2147483648;
	public const uint32 SECPKG_ANSI_ATTRIBUTE = 0;
	public const uint32 SECPKG_CREDENTIAL_ATTRIBUTE = 0;
	public const String SECPKG_LSAMODEINIT_NAME = "SpLsaModeInitialize";
	public const String SECPKG_USERMODEINIT_NAME = "SpUserModeInitialize";
	public const uint32 SECPKG_INTERFACE_VERSION = 65536;
	public const uint32 SECPKG_INTERFACE_VERSION_2 = 131072;
	public const uint32 SECPKG_INTERFACE_VERSION_3 = 262144;
	public const uint32 SECPKG_INTERFACE_VERSION_4 = 524288;
	public const uint32 SECPKG_INTERFACE_VERSION_5 = 1048576;
	public const uint32 SECPKG_INTERFACE_VERSION_6 = 2097152;
	public const uint32 SECPKG_INTERFACE_VERSION_7 = 4194304;
	public const uint32 SECPKG_INTERFACE_VERSION_8 = 8388608;
	public const uint32 SECPKG_INTERFACE_VERSION_9 = 16777216;
	public const uint32 SECPKG_INTERFACE_VERSION_10 = 33554432;
	public const String UNISP_NAME_A = "Microsoft Unified Security Protocol Provider";
	public const String UNISP_NAME_W = "Microsoft Unified Security Protocol Provider";
	public const String SSL2SP_NAME_A = "Microsoft SSL 2.0";
	public const String SSL2SP_NAME_W = "Microsoft SSL 2.0";
	public const String SSL3SP_NAME_A = "Microsoft SSL 3.0";
	public const String SSL3SP_NAME_W = "Microsoft SSL 3.0";
	public const String TLS1SP_NAME_A = "Microsoft TLS 1.0";
	public const String TLS1SP_NAME_W = "Microsoft TLS 1.0";
	public const String PCT1SP_NAME_A = "Microsoft PCT 1.0";
	public const String PCT1SP_NAME_W = "Microsoft PCT 1.0";
	public const String SCHANNEL_NAME_A = "Schannel";
	public const String SCHANNEL_NAME_W = "Schannel";
	public const String DEFAULT_TLS_SSP_NAME_A = "Default TLS SSP";
	public const String DEFAULT_TLS_SSP_NAME_W = "Default TLS SSP";
	public const String UNISP_NAME = "Microsoft Unified Security Protocol Provider";
	public const String PCT1SP_NAME = "Microsoft PCT 1.0";
	public const String SSL2SP_NAME = "Microsoft SSL 2.0";
	public const String SSL3SP_NAME = "Microsoft SSL 3.0";
	public const String TLS1SP_NAME = "Microsoft TLS 1.0";
	public const String SCHANNEL_NAME = "Schannel";
	public const String DEFAULT_TLS_SSP_NAME = "Default TLS SSP";
	public const uint32 UNISP_RPC_ID = 14;
	public const uint32 RCRED_STATUS_NOCRED = 0;
	public const uint32 RCRED_CRED_EXISTS = 1;
	public const uint32 RCRED_STATUS_UNKNOWN_ISSUER = 2;
	public const uint32 LCRED_STATUS_NOCRED = 0;
	public const uint32 LCRED_CRED_EXISTS = 1;
	public const uint32 LCRED_STATUS_UNKNOWN_ISSUER = 2;
	public const uint32 SECPKGCONTEXT_CONNECTION_INFO_EX_V1 = 1;
	public const uint32 SECPKGCONTEXT_CIPHERINFO_V1 = 1;
	public const uint32 SSL_SESSION_RECONNECT = 1;
	public const uint32 KERN_CONTEXT_CERT_INFO_V1 = 0;
	public const uint32 ENABLE_TLS_CLIENT_EARLY_START = 1;
	public const uint32 SCH_CRED_V1 = 1;
	public const uint32 SCH_CRED_V2 = 2;
	public const uint32 SCH_CRED_VERSION = 2;
	public const uint32 SCH_CRED_V3 = 3;
	public const uint32 SCHANNEL_CRED_VERSION = 4;
	public const uint32 SCH_CREDENTIALS_VERSION = 5;
	public const uint32 TLS_PARAMS_OPTIONAL = 1;
	public const uint32 SCH_CRED_MAX_SUPPORTED_PARAMETERS = 16;
	public const uint32 SCH_CRED_MAX_SUPPORTED_ALPN_IDS = 16;
	public const uint32 SCH_CRED_MAX_SUPPORTED_CRYPTO_SETTINGS = 16;
	public const uint32 SCH_CRED_MAX_SUPPORTED_CHAINING_MODES = 16;
	public const uint32 SCH_MAX_EXT_SUBSCRIPTIONS = 2;
	public const uint32 SCH_CRED_FORMAT_CERT_CONTEXT = 0;
	public const uint32 SCH_CRED_FORMAT_CERT_HASH = 1;
	public const uint32 SCH_CRED_FORMAT_CERT_HASH_STORE = 2;
	public const uint32 SCH_CRED_MAX_STORE_NAME_SIZE = 128;
	public const uint32 SCH_CRED_MAX_SUPPORTED_ALGS = 256;
	public const uint32 SCH_CRED_MAX_SUPPORTED_CERTS = 100;
	public const uint32 SCH_MACHINE_CERT_HASH = 1;
	public const uint32 SCH_CRED_DISABLE_RECONNECTS = 128;
	public const uint32 SCH_CRED_RESTRICTED_ROOTS = 8192;
	public const uint32 SCH_CRED_REVOCATION_CHECK_CACHE_ONLY = 16384;
	public const uint32 SCH_CRED_CACHE_ONLY_URL_RETRIEVAL = 32768;
	public const uint32 SCH_CRED_MEMORY_STORE_CERT = 65536;
	public const uint32 SCH_CRED_SNI_CREDENTIAL = 524288;
	public const uint32 SCH_CRED_SNI_ENABLE_OCSP = 1048576;
	public const uint32 SCH_USE_DTLS_ONLY = 16777216;
	public const uint32 SCH_ALLOW_NULL_ENCRYPTION = 33554432;
	public const uint32 SCH_CRED_DEFERRED_CRED_VALIDATION = 67108864;
	public const uint32 SCHANNEL_RENEGOTIATE = 0;
	public const uint32 SCHANNEL_SHUTDOWN = 1;
	public const uint32 SCHANNEL_ALERT = 2;
	public const uint32 SCHANNEL_SESSION = 3;
	public const uint32 TLS1_ALERT_CLOSE_NOTIFY = 0;
	public const uint32 TLS1_ALERT_UNEXPECTED_MESSAGE = 10;
	public const uint32 TLS1_ALERT_BAD_RECORD_MAC = 20;
	public const uint32 TLS1_ALERT_DECRYPTION_FAILED = 21;
	public const uint32 TLS1_ALERT_RECORD_OVERFLOW = 22;
	public const uint32 TLS1_ALERT_DECOMPRESSION_FAIL = 30;
	public const uint32 TLS1_ALERT_HANDSHAKE_FAILURE = 40;
	public const uint32 TLS1_ALERT_BAD_CERTIFICATE = 42;
	public const uint32 TLS1_ALERT_UNSUPPORTED_CERT = 43;
	public const uint32 TLS1_ALERT_CERTIFICATE_REVOKED = 44;
	public const uint32 TLS1_ALERT_CERTIFICATE_EXPIRED = 45;
	public const uint32 TLS1_ALERT_CERTIFICATE_UNKNOWN = 46;
	public const uint32 TLS1_ALERT_ILLEGAL_PARAMETER = 47;
	public const uint32 TLS1_ALERT_UNKNOWN_CA = 48;
	public const uint32 TLS1_ALERT_ACCESS_DENIED = 49;
	public const uint32 TLS1_ALERT_DECODE_ERROR = 50;
	public const uint32 TLS1_ALERT_DECRYPT_ERROR = 51;
	public const uint32 TLS1_ALERT_EXPORT_RESTRICTION = 60;
	public const uint32 TLS1_ALERT_PROTOCOL_VERSION = 70;
	public const uint32 TLS1_ALERT_INSUFFIENT_SECURITY = 71;
	public const uint32 TLS1_ALERT_INTERNAL_ERROR = 80;
	public const uint32 TLS1_ALERT_USER_CANCELED = 90;
	public const uint32 TLS1_ALERT_NO_RENEGOTIATION = 100;
	public const uint32 TLS1_ALERT_UNSUPPORTED_EXT = 110;
	public const uint32 TLS1_ALERT_UNKNOWN_PSK_IDENTITY = 115;
	public const uint32 TLS1_ALERT_NO_APP_PROTOCOL = 120;
	public const uint32 SP_PROT_PCT1_SERVER = 1;
	public const uint32 SP_PROT_PCT1_CLIENT = 2;
	public const uint32 SP_PROT_SSL2_SERVER = 4;
	public const uint32 SP_PROT_SSL2_CLIENT = 8;
	public const uint32 SP_PROT_SSL3_SERVER = 16;
	public const uint32 SP_PROT_SSL3_CLIENT = 32;
	public const uint32 SP_PROT_TLS1_SERVER = 64;
	public const uint32 SP_PROT_TLS1_CLIENT = 128;
	public const uint32 SP_PROT_UNI_SERVER = 1073741824;
	public const uint32 SP_PROT_UNI_CLIENT = 2147483648;
	public const uint32 SP_PROT_ALL = 4294967295;
	public const uint32 SP_PROT_NONE = 0;
	public const uint32 SP_PROT_TLS1_0_SERVER = 64;
	public const uint32 SP_PROT_TLS1_0_CLIENT = 128;
	public const uint32 SP_PROT_TLS1_1_SERVER = 256;
	public const uint32 SP_PROT_TLS1_1_CLIENT = 512;
	public const uint32 SP_PROT_TLS1_2_SERVER = 1024;
	public const uint32 SP_PROT_TLS1_2_CLIENT = 2048;
	public const uint32 SP_PROT_TLS1_3_SERVER = 4096;
	public const uint32 SP_PROT_TLS1_3_CLIENT = 8192;
	public const uint32 SP_PROT_DTLS_SERVER = 65536;
	public const uint32 SP_PROT_DTLS_CLIENT = 131072;
	public const uint32 SP_PROT_DTLS1_0_SERVER = 65536;
	public const uint32 SP_PROT_DTLS1_0_CLIENT = 131072;
	public const uint32 SP_PROT_DTLS1_2_SERVER = 262144;
	public const uint32 SP_PROT_DTLS1_2_CLIENT = 524288;
	public const uint32 SP_PROT_TLS1_3PLUS_SERVER = 4096;
	public const uint32 SP_PROT_TLS1_3PLUS_CLIENT = 8192;
	public const uint32 SCHANNEL_SECRET_TYPE_CAPI = 1;
	public const uint32 SCHANNEL_SECRET_PRIVKEY = 2;
	public const uint32 SCH_CRED_X509_CERTCHAIN = 1;
	public const uint32 SCH_CRED_X509_CAPI = 2;
	public const uint32 SCH_CRED_CERT_CONTEXT = 3;
	public const String SSL_CRACK_CERTIFICATE_NAME = "SslCrackCertificate";
	public const String SSL_FREE_CERTIFICATE_NAME = "SslFreeCertificate";
	public const String SL_INFO_KEY_CHANNEL = "Channel";
	public const String SL_INFO_KEY_NAME = "Name";
	public const String SL_INFO_KEY_AUTHOR = "Author";
	public const String SL_INFO_KEY_DESCRIPTION = "Description";
	public const String SL_INFO_KEY_LICENSOR_URL = "LicensorUrl";
	public const String SL_INFO_KEY_DIGITAL_PID = "DigitalPID";
	public const String SL_INFO_KEY_DIGITAL_PID2 = "DigitalPID2";
	public const String SL_INFO_KEY_PARTIAL_PRODUCT_KEY = "PartialProductKey";
	public const String SL_INFO_KEY_PRODUCT_SKU_ID = "ProductSkuId";
	public const String SL_INFO_KEY_LICENSE_TYPE = "LicenseType";
	public const String SL_INFO_KEY_VERSION = "Version";
	public const String SL_INFO_KEY_SYSTEM_STATE = "SystemState";
	public const String SL_INFO_KEY_ACTIVE_PLUGINS = "ActivePlugins";
	public const String SL_INFO_KEY_SECURE_STORE_ID = "SecureStoreId";
	public const String SL_INFO_KEY_BIOS_PKEY = "BiosProductKey";
	public const String SL_INFO_KEY_BIOS_SLIC_STATE = "BiosSlicState";
	public const String SL_INFO_KEY_BIOS_OA2_MINOR_VERSION = "BiosOA2MinorVersion";
	public const String SL_INFO_KEY_BIOS_PKEY_DESCRIPTION = "BiosProductKeyDescription";
	public const String SL_INFO_KEY_BIOS_PKEY_PKPN = "BiosProductKeyPkPn";
	public const String SL_INFO_KEY_SECURE_PROCESSOR_ACTIVATION_URL = "SPCURL";
	public const String SL_INFO_KEY_RIGHT_ACCOUNT_ACTIVATION_URL = "RACURL";
	public const String SL_INFO_KEY_PRODUCT_KEY_ACTIVATION_URL = "PKCURL";
	public const String SL_INFO_KEY_USE_LICENSE_ACTIVATION_URL = "EULURL";
	public const String SL_INFO_KEY_IS_KMS = "IsKeyManagementService";
	public const String SL_INFO_KEY_KMS_CURRENT_COUNT = "KeyManagementServiceCurrentCount";
	public const String SL_INFO_KEY_KMS_REQUIRED_CLIENT_COUNT = "KeyManagementServiceRequiredClientCount";
	public const String SL_INFO_KEY_KMS_UNLICENSED_REQUESTS = "KeyManagementServiceUnlicensedRequests";
	public const String SL_INFO_KEY_KMS_LICENSED_REQUESTS = "KeyManagementServiceLicensedRequests";
	public const String SL_INFO_KEY_KMS_OOB_GRACE_REQUESTS = "KeyManagementServiceOOBGraceRequests";
	public const String SL_INFO_KEY_KMS_OOT_GRACE_REQUESTS = "KeyManagementServiceOOTGraceRequests";
	public const String SL_INFO_KEY_KMS_NON_GENUINE_GRACE_REQUESTS = "KeyManagementServiceNonGenuineGraceRequests";
	public const String SL_INFO_KEY_KMS_NOTIFICATION_REQUESTS = "KeyManagementServiceNotificationRequests";
	public const String SL_INFO_KEY_KMS_TOTAL_REQUESTS = "KeyManagementServiceTotalRequests";
	public const String SL_INFO_KEY_KMS_FAILED_REQUESTS = "KeyManagementServiceFailedRequests";
	public const String SL_INFO_KEY_IS_PRS = "IsPRS";
	public const String SL_PKEY_MS2005 = "msft:rm/algorithm/pkey/2005";
	public const String SL_PKEY_MS2009 = "msft:rm/algorithm/pkey/2009";
	public const String SL_PKEY_DETECT = "msft:rm/algorithm/pkey/detect";
	public const String SL_EVENT_LICENSING_STATE_CHANGED = "msft:rm/event/licensingstatechanged";
	public const String SL_EVENT_POLICY_CHANGED = "msft:rm/event/policychanged";
	public const String SL_EVENT_USER_NOTIFICATION = "msft:rm/event/usernotification";
	public const uint32 SL_SYSTEM_STATE_REBOOT_POLICY_FOUND = 1;
	public const uint32 SL_SYSTEM_STATE_TAMPERED = 2;
	public const uint32 SL_REARM_REBOOT_REQUIRED = 1;
	public const uint32 SPP_MIGRATION_GATHER_MIGRATABLE_APPS = 1;
	public const uint32 SPP_MIGRATION_GATHER_ACTIVATED_WINDOWS_STATE = 2;
	public const uint32 SPP_MIGRATION_GATHER_ALL = 4294967295;
	public const String SL_PROP_BRT_DATA = "SL_BRT_DATA";
	public const String SL_PROP_BRT_COMMIT = "SL_BRT_COMMIT";
	public const String SL_PROP_GENUINE_RESULT = "SL_GENUINE_RESULT";
	public const String SL_PROP_NONGENUINE_GRACE_FLAG = "SL_NONGENUINE_GRACE_FLAG";
	public const String SL_PROP_GET_GENUINE_AUTHZ = "SL_GET_GENUINE_AUTHZ";
	public const String SL_PROP_GET_GENUINE_SERVER_AUTHZ = "SL_GET_GENUINE_SERVER_AUTHZ";
	public const String SL_PROP_LAST_ACT_ATTEMPT_HRESULT = "SL_LAST_ACT_ATTEMPT_HRESULT";
	public const String SL_PROP_LAST_ACT_ATTEMPT_TIME = "SL_LAST_ACT_ATTEMPT_TIME";
	public const String SL_PROP_LAST_ACT_ATTEMPT_SERVER_FLAGS = "SL_LAST_ACT_ATTEMPT_SERVER_FLAGS";
	public const String SL_PROP_ACTIVATION_VALIDATION_IN_PROGRESS = "SL_ACTIVATION_VALIDATION_IN_PROGRESS";
	public const String SL_POLICY_EVALUATION_MODE_ENABLED = "Security-SPP-EvaluationModeEnabled";
	public const String SL_DEFAULT_MIGRATION_ENCRYPTOR_URI = "msft:spp/migrationencryptor/tokenact/1.0";
	public const String ID_CAP_SLAPI = "slapiQueryLicenseValue";
	public const uint32 USER_ACCOUNT_DISABLED = 1;
	public const uint32 USER_HOME_DIRECTORY_REQUIRED = 2;
	public const uint32 USER_PASSWORD_NOT_REQUIRED = 4;
	public const uint32 USER_TEMP_DUPLICATE_ACCOUNT = 8;
	public const uint32 USER_NORMAL_ACCOUNT = 16;
	public const uint32 USER_MNS_LOGON_ACCOUNT = 32;
	public const uint32 USER_INTERDOMAIN_TRUST_ACCOUNT = 64;
	public const uint32 USER_WORKSTATION_TRUST_ACCOUNT = 128;
	public const uint32 USER_SERVER_TRUST_ACCOUNT = 256;
	public const uint32 USER_DONT_EXPIRE_PASSWORD = 512;
	public const uint32 USER_ACCOUNT_AUTO_LOCKED = 1024;
	public const uint32 USER_ENCRYPTED_TEXT_PASSWORD_ALLOWED = 2048;
	public const uint32 USER_SMARTCARD_REQUIRED = 4096;
	public const uint32 USER_TRUSTED_FOR_DELEGATION = 8192;
	public const uint32 USER_NOT_DELEGATED = 16384;
	public const uint32 USER_USE_DES_KEY_ONLY = 32768;
	public const uint32 USER_DONT_REQUIRE_PREAUTH = 65536;
	public const uint32 USER_PASSWORD_EXPIRED = 131072;
	public const uint32 USER_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION = 262144;
	public const uint32 USER_NO_AUTH_DATA_REQUIRED = 524288;
	public const uint32 USER_PARTIAL_SECRETS_ACCOUNT = 1048576;
	public const uint32 USER_USE_AES_KEYS = 2097152;
	public const uint32 SAM_DAYS_PER_WEEK = 7;
	public const uint32 USER_ALL_PARAMETERS = 2097152;
	public const uint32 CLEAR_BLOCK_LENGTH = 8;
	public const uint32 CYPHER_BLOCK_LENGTH = 8;
	public const uint32 MSV1_0_VALIDATION_LOGOFF_TIME = 1;
	public const uint32 MSV1_0_VALIDATION_KICKOFF_TIME = 2;
	public const uint32 MSV1_0_VALIDATION_LOGON_SERVER = 4;
	public const uint32 MSV1_0_VALIDATION_LOGON_DOMAIN = 8;
	public const uint32 MSV1_0_VALIDATION_SESSION_KEY = 16;
	public const uint32 MSV1_0_VALIDATION_USER_FLAGS = 32;
	public const uint32 MSV1_0_VALIDATION_USER_ID = 64;
	public const uint32 MSV1_0_SUBAUTH_ACCOUNT_DISABLED = 1;
	public const uint32 MSV1_0_SUBAUTH_PASSWORD = 2;
	public const uint32 MSV1_0_SUBAUTH_WORKSTATIONS = 4;
	public const uint32 MSV1_0_SUBAUTH_LOGON_HOURS = 8;
	public const uint32 MSV1_0_SUBAUTH_ACCOUNT_EXPIRY = 16;
	public const uint32 MSV1_0_SUBAUTH_PASSWORD_EXPIRY = 32;
	public const uint32 MSV1_0_SUBAUTH_ACCOUNT_TYPE = 64;
	public const uint32 MSV1_0_SUBAUTH_LOCKOUT = 128;
	public const uint32 SL_MDOLLAR_ZONE = 40960;
	public const uint32 SL_SERVER_ZONE = 45056;
	public const uint32 SL_MSCH_ZONE = 49152;
	public const uint32 SL_INTERNAL_ZONE = 57344;
	public const uint32 SL_CLIENTAPI_ZONE = 61440;
	public const uint32 FACILITY_SL_ITF = 4;
	public const uint32 _FACILITY_WINDOWS_STORE = 63;
	public const HRESULT SL_E_SRV_INVALID_PUBLISH_LICENSE = -1073434623;
	public const HRESULT SL_E_SRV_INVALID_PRODUCT_KEY_LICENSE = -1073434622;
	public const HRESULT SL_E_SRV_INVALID_RIGHTS_ACCOUNT_LICENSE = -1073434621;
	public const HRESULT SL_E_SRV_INVALID_LICENSE_STRUCTURE = -1073434620;
	public const HRESULT SL_E_SRV_AUTHORIZATION_FAILED = -1073434619;
	public const HRESULT SL_E_SRV_INVALID_BINDING = -1073434618;
	public const HRESULT SL_E_SRV_SERVER_PONG = -1073434617;
	public const HRESULT SL_E_SRV_INVALID_PAYLOAD = -1073434616;
	public const HRESULT SL_E_SRV_INVALID_SECURITY_PROCESSOR_LICENSE = -1073434615;
	public const HRESULT SL_E_SRV_BUSINESS_TOKEN_ENTRY_NOT_FOUND = -1073434608;
	public const HRESULT SL_E_SRV_CLIENT_CLOCK_OUT_OF_SYNC = -1073434607;
	public const HRESULT SL_E_SRV_GENERAL_ERROR = -1073434368;
	public const HRESULT SL_E_CHPA_PRODUCT_KEY_OUT_OF_RANGE = -1073430527;
	public const HRESULT SL_E_CHPA_INVALID_BINDING = -1073430526;
	public const HRESULT SL_E_CHPA_PRODUCT_KEY_BLOCKED = -1073430525;
	public const HRESULT SL_E_CHPA_INVALID_PRODUCT_KEY = -1073430524;
	public const HRESULT SL_E_CHPA_BINDING_NOT_FOUND = -1073430523;
	public const HRESULT SL_E_CHPA_BINDING_MAPPING_NOT_FOUND = -1073430522;
	public const HRESULT SL_E_CHPA_UNSUPPORTED_PRODUCT_KEY = -1073430521;
	public const HRESULT SL_E_CHPA_MAXIMUM_UNLOCK_EXCEEDED = -1073430520;
	public const HRESULT SL_E_CHPA_ACTCONFIG_ID_NOT_FOUND = -1073430519;
	public const HRESULT SL_E_CHPA_INVALID_PRODUCT_DATA_ID = -1073430518;
	public const HRESULT SL_E_CHPA_INVALID_PRODUCT_DATA = -1073430517;
	public const HRESULT SL_E_CHPA_SYSTEM_ERROR = -1073430516;
	public const HRESULT SL_E_CHPA_INVALID_ACTCONFIG_ID = -1073430515;
	public const HRESULT SL_E_CHPA_INVALID_PRODUCT_KEY_LENGTH = -1073430514;
	public const HRESULT SL_E_CHPA_INVALID_PRODUCT_KEY_FORMAT = -1073430513;
	public const HRESULT SL_E_CHPA_INVALID_PRODUCT_KEY_CHAR = -1073430512;
	public const HRESULT SL_E_CHPA_INVALID_BINDING_URI = -1073430511;
	public const HRESULT SL_E_CHPA_NETWORK_ERROR = -1073430510;
	public const HRESULT SL_E_CHPA_DATABASE_ERROR = -1073430509;
	public const HRESULT SL_E_CHPA_INVALID_ARGUMENT = -1073430508;
	public const HRESULT SL_E_CHPA_DMAK_LIMIT_EXCEEDED = -1073430496;
	public const HRESULT SL_E_CHPA_DMAK_EXTENSION_LIMIT_EXCEEDED = -1073430495;
	public const HRESULT SL_E_CHPA_REISSUANCE_LIMIT_NOT_FOUND = -1073430494;
	public const HRESULT SL_E_CHPA_OVERRIDE_REQUEST_NOT_FOUND = -1073430493;
	public const HRESULT SL_E_CHPA_OEM_SLP_COA0 = -1073430506;
	public const HRESULT SL_E_CHPA_PRODUCT_KEY_BLOCKED_IPLOCATION = -1073430505;
	public const HRESULT SL_E_CHPA_RESPONSE_NOT_AVAILABLE = -1073430507;
	public const HRESULT SL_E_CHPA_GENERAL_ERROR = -1073430448;
	public const HRESULT SL_E_CHPA_TIMEBASED_ACTIVATION_BEFORE_START_DATE = -1073430480;
	public const HRESULT SL_E_CHPA_TIMEBASED_ACTIVATION_AFTER_END_DATE = -1073430479;
	public const HRESULT SL_E_CHPA_TIMEBASED_ACTIVATION_NOT_AVAILABLE = -1073430478;
	public const HRESULT SL_E_CHPA_TIMEBASED_PRODUCT_KEY_NOT_CONFIGURED = -1073430477;
	public const HRESULT SL_E_CHPA_NO_RULES_TO_ACTIVATE = -1073430449;
	public const HRESULT SL_E_CHPA_DIGITALMARKER_INVALID_BINDING = -1073430447;
	public const HRESULT SL_E_CHPA_DIGITALMARKER_BINDING_NOT_CONFIGURED = -1073430446;
	public const HRESULT SL_E_CHPA_DYNAMICALLY_BLOCKED_PRODUCT_KEY = -1073430432;
	public const HRESULT SL_E_CHPA_MSCH_RESPONSE_NOT_AVAILABLE_VGA = -1073429505;
	public const HRESULT SL_E_CHPA_BUSINESS_RULE_INPUT_NOT_FOUND = -1073428736;
	public const HRESULT SL_E_CHPA_NULL_VALUE_FOR_PROPERTY_NAME_OR_ID = -1073428656;
	public const HRESULT SL_E_CHPA_UNKNOWN_PROPERTY_NAME = -1073428655;
	public const HRESULT SL_E_CHPA_UNKNOWN_PROPERTY_ID = -1073428654;
	public const HRESULT SL_E_CHPA_FAILED_TO_UPDATE_PRODUCTKEY_BINDING = -1073428651;
	public const HRESULT SL_E_CHPA_FAILED_TO_INSERT_PRODUCTKEY_BINDING = -1073428650;
	public const HRESULT SL_E_CHPA_FAILED_TO_DELETE_PRODUCTKEY_BINDING = -1073428649;
	public const HRESULT SL_E_CHPA_FAILED_TO_PROCESS_PRODUCT_KEY_BINDINGS_XML = -1073428648;
	public const HRESULT SL_E_CHPA_FAILED_TO_INSERT_PRODUCT_KEY_PROPERTY = -1073428646;
	public const HRESULT SL_E_CHPA_FAILED_TO_UPDATE_PRODUCT_KEY_PROPERTY = -1073428645;
	public const HRESULT SL_E_CHPA_FAILED_TO_DELETE_PRODUCT_KEY_PROPERTY = -1073428644;
	public const HRESULT SL_E_CHPA_UNKNOWN_PRODUCT_KEY_TYPE = -1073428636;
	public const HRESULT SL_E_CHPA_PRODUCT_KEY_BEING_USED = -1073428624;
	public const HRESULT SL_E_CHPA_FAILED_TO_INSERT_PRODUCT_KEY_RECORD = -1073428608;
	public const HRESULT SL_E_CHPA_FAILED_TO_UPDATE_PRODUCT_KEY_RECORD = -1073428607;
	public const HRESULT SL_E_INVALID_LICENSE_STATE_BREACH_GRACE = -1073429871;
	public const HRESULT SL_E_INVALID_LICENSE_STATE_BREACH_GRACE_EXPIRED = -1073429870;
	public const HRESULT SL_E_INVALID_TEMPLATE_ID = -1073429770;
	public const HRESULT SL_E_INVALID_XML_BLOB = -1073429766;
	public const HRESULT SL_E_VALIDATION_BLOB_PARAM_NOT_FOUND = -1073429721;
	public const HRESULT SL_E_INVALID_CLIENT_TOKEN = -1073429720;
	public const HRESULT SL_E_INVALID_OFFLINE_BLOB = -1073429719;
	public const HRESULT SL_E_OFFLINE_VALIDATION_BLOB_PARAM_NOT_FOUND = -1073429718;
	public const HRESULT SL_E_INVALID_OSVERSION_TEMPLATEID = -1073429717;
	public const HRESULT SL_E_OFFLINE_GENUINE_BLOB_REVOKED = -1073429716;
	public const HRESULT SL_E_OFFLINE_GENUINE_BLOB_NOT_FOUND = -1073429715;
	public const HRESULT SL_E_INVALID_OS_FOR_PRODUCT_KEY = -1073429503;
	public const HRESULT SL_E_INVALID_FILE_HASH = -1073429343;
	public const HRESULT SL_E_VALIDATION_BLOCKED_PRODUCT_KEY = -1073429342;
	public const HRESULT SL_E_MISMATCHED_KEY_TYPES = -1073429340;
	public const HRESULT SL_E_VALIDATION_INVALID_PRODUCT_KEY = -1073429339;
	public const HRESULT SL_E_INVALID_OEM_OR_VOLUME_BINDING_DATA = -1073429337;
	public const HRESULT SL_E_INVALID_LICENSE_STATE = -1073429336;
	public const HRESULT SL_E_IP_LOCATION_FALIED = -1073429335;
	public const HRESULT SL_E_SOFTMOD_EXPLOIT_DETECTED = -1073429333;
	public const HRESULT SL_E_INVALID_TOKEN_DATA = -1073429332;
	public const HRESULT SL_E_HEALTH_CHECK_FAILED_NEUTRAL_FILES = -1073429331;
	public const HRESULT SL_E_HEALTH_CHECK_FAILED_MUI_FILES = -1073429330;
	public const HRESULT SL_E_INVALID_AD_DATA = -1073429329;
	public const HRESULT SL_E_INVALID_RSDP_COUNT = -1073429328;
	public const HRESULT SL_E_ENGINE_DETECTED_EXPLOIT = -1073429327;
	public const HRESULT SL_E_NON_GENUINE_STATUS_LAST = -1073428992;
	public const HRESULT SL_E_NOTIFICATION_BREACH_DETECTED = -1073429199;
	public const HRESULT SL_E_NOTIFICATION_GRACE_EXPIRED = -1073429198;
	public const HRESULT SL_E_NOTIFICATION_OTHER_REASONS = -1073429197;
	public const HRESULT SL_E_INVALID_CONTEXT = -1073422335;
	public const HRESULT SL_E_TOKEN_STORE_INVALID_STATE = -1073422334;
	public const HRESULT SL_E_EVALUATION_FAILED = -1073422333;
	public const HRESULT SL_E_NOT_EVALUATED = -1073422332;
	public const HRESULT SL_E_NOT_ACTIVATED = -1073422331;
	public const HRESULT SL_E_INVALID_GUID = -1073422330;
	public const HRESULT SL_E_TOKSTO_TOKEN_NOT_FOUND = -1073422329;
	public const HRESULT SL_E_TOKSTO_NO_PROPERTIES = -1073422328;
	public const HRESULT SL_E_TOKSTO_NOT_INITIALIZED = -1073422327;
	public const HRESULT SL_E_TOKSTO_ALREADY_INITIALIZED = -1073422326;
	public const HRESULT SL_E_TOKSTO_NO_ID_SET = -1073422325;
	public const HRESULT SL_E_TOKSTO_CANT_CREATE_FILE = -1073422324;
	public const HRESULT SL_E_TOKSTO_CANT_WRITE_TO_FILE = -1073422323;
	public const HRESULT SL_E_TOKSTO_CANT_READ_FILE = -1073422322;
	public const HRESULT SL_E_TOKSTO_CANT_PARSE_PROPERTIES = -1073422321;
	public const HRESULT SL_E_TOKSTO_PROPERTY_NOT_FOUND = -1073422320;
	public const HRESULT SL_E_TOKSTO_INVALID_FILE = -1073422319;
	public const HRESULT SL_E_TOKSTO_CANT_CREATE_MUTEX = -1073422318;
	public const HRESULT SL_E_TOKSTO_CANT_ACQUIRE_MUTEX = -1073422317;
	public const HRESULT SL_E_TOKSTO_NO_TOKEN_DATA = -1073422316;
	public const HRESULT SL_E_EUL_CONSUMPTION_FAILED = -1073422315;
	public const HRESULT SL_E_PKEY_INVALID_CONFIG = -1073422314;
	public const HRESULT SL_E_PKEY_INVALID_UNIQUEID = -1073422313;
	public const HRESULT SL_E_PKEY_INVALID_ALGORITHM = -1073422312;
	public const HRESULT SL_E_PKEY_INTERNAL_ERROR = -1073422311;
	public const HRESULT SL_E_LICENSE_INVALID_ADDON_INFO = -1073422310;
	public const HRESULT SL_E_HWID_ERROR = -1073422309;
	public const HRESULT SL_E_PKEY_INVALID_KEYCHANGE1 = -1073422308;
	public const HRESULT SL_E_PKEY_INVALID_KEYCHANGE2 = -1073422307;
	public const HRESULT SL_E_PKEY_INVALID_KEYCHANGE3 = -1073422306;
	public const HRESULT SL_E_POLICY_OTHERINFO_MISMATCH = -1073422304;
	public const HRESULT SL_E_PRODUCT_UNIQUENESS_GROUP_ID_INVALID = -1073422303;
	public const HRESULT SL_E_SECURE_STORE_ID_MISMATCH = -1073422302;
	public const HRESULT SL_E_INVALID_RULESET_RULE = -1073422301;
	public const HRESULT SL_E_INVALID_CONTEXT_DATA = -1073422300;
	public const HRESULT SL_E_INVALID_HASH = -1073422299;
	public const HRESULT SL_E_INVALID_USE_OF_ADD_ON_PKEY = -2147164122;
	public const HRESULT SL_E_WINDOWS_VERSION_MISMATCH = -1073422297;
	public const HRESULT SL_E_ACTIVATION_IN_PROGRESS = -1073422296;
	public const HRESULT SL_E_STORE_UPGRADE_TOKEN_REQUIRED = -1073422295;
	public const HRESULT SL_E_STORE_UPGRADE_TOKEN_WRONG_EDITION = -1073422294;
	public const HRESULT SL_E_STORE_UPGRADE_TOKEN_WRONG_PID = -1073422293;
	public const HRESULT SL_E_STORE_UPGRADE_TOKEN_NOT_PRS_SIGNED = -1073422292;
	public const HRESULT SL_E_STORE_UPGRADE_TOKEN_WRONG_VERSION = -1073422291;
	public const HRESULT SL_E_STORE_UPGRADE_TOKEN_NOT_AUTHORIZED = -1073422290;
	public const HRESULT SL_E_SFS_INVALID_FS_VERSION = -2147163903;
	public const HRESULT SL_E_SFS_INVALID_FD_TABLE = -2147163902;
	public const HRESULT SL_E_SFS_INVALID_SYNC = -2147163901;
	public const HRESULT SL_E_SFS_BAD_TOKEN_NAME = -2147163900;
	public const HRESULT SL_E_SFS_BAD_TOKEN_EXT = -2147163899;
	public const HRESULT SL_E_SFS_DUPLICATE_TOKEN_NAME = -2147163898;
	public const HRESULT SL_E_SFS_TOKEN_SIZE_MISMATCH = -2147163897;
	public const HRESULT SL_E_SFS_INVALID_TOKEN_DATA_HASH = -2147163896;
	public const HRESULT SL_E_SFS_FILE_READ_ERROR = -2147163895;
	public const HRESULT SL_E_SFS_FILE_WRITE_ERROR = -2147163894;
	public const HRESULT SL_E_SFS_INVALID_FILE_POSITION = -2147163893;
	public const HRESULT SL_E_SFS_NO_ACTIVE_TRANSACTION = -2147163892;
	public const HRESULT SL_E_SFS_INVALID_FS_HEADER = -2147163891;
	public const HRESULT SL_E_SFS_INVALID_TOKEN_DESCRIPTOR = -2147163890;
	public const HRESULT SL_E_INTERNAL_ERROR = -1073418239;
	public const HRESULT SL_E_RIGHT_NOT_CONSUMED = -1073418238;
	public const HRESULT SL_E_USE_LICENSE_NOT_INSTALLED = -1073418237;
	public const HRESULT SL_E_MISMATCHED_PKEY_RANGE = -1073418236;
	public const HRESULT SL_E_MISMATCHED_PID = -1073418235;
	public const HRESULT SL_E_EXTERNAL_SIGNATURE_NOT_FOUND = -1073418234;
	public const HRESULT SL_E_RAC_NOT_AVAILABLE = -1073418233;
	public const HRESULT SL_E_SPC_NOT_AVAILABLE = -1073418232;
	public const HRESULT SL_E_GRACE_TIME_EXPIRED = -1073418231;
	public const HRESULT SL_E_MISMATCHED_APPID = -1073418230;
	public const HRESULT SL_E_NO_PID_CONFIG_DATA = -1073418229;
	public const HRESULT SL_I_OOB_GRACE_PERIOD = 1074065420;
	public const HRESULT SL_I_OOT_GRACE_PERIOD = 1074065421;
	public const HRESULT SL_E_MISMATCHED_SECURITY_PROCESSOR = -1073418226;
	public const HRESULT SL_E_OUT_OF_TOLERANCE = -1073418225;
	public const HRESULT SL_E_INVALID_PKEY = -1073418224;
	public const HRESULT SL_E_LICENSE_FILE_NOT_INSTALLED = -1073418223;
	public const HRESULT SL_E_VALUE_NOT_FOUND = -1073418222;
	public const HRESULT SL_E_RIGHT_NOT_GRANTED = -1073418221;
	public const HRESULT SL_E_PKEY_NOT_INSTALLED = -1073418220;
	public const HRESULT SL_E_PRODUCT_SKU_NOT_INSTALLED = -1073418219;
	public const HRESULT SL_E_NOT_SUPPORTED = -1073418218;
	public const HRESULT SL_E_PUBLISHING_LICENSE_NOT_INSTALLED = -1073418217;
	public const HRESULT SL_E_LICENSE_SERVER_URL_NOT_FOUND = -1073418216;
	public const HRESULT SL_E_INVALID_EVENT_ID = -1073418215;
	public const HRESULT SL_E_EVENT_NOT_REGISTERED = -1073418214;
	public const HRESULT SL_E_EVENT_ALREADY_REGISTERED = -1073418213;
	public const HRESULT SL_E_DECRYPTION_LICENSES_NOT_AVAILABLE = -1073418212;
	public const HRESULT SL_E_LICENSE_SIGNATURE_VERIFICATION_FAILED = -1073418211;
	public const HRESULT SL_E_DATATYPE_MISMATCHED = -1073418210;
	public const HRESULT SL_E_INVALID_LICENSE = -1073418209;
	public const HRESULT SL_E_INVALID_PACKAGE = -1073418208;
	public const HRESULT SL_E_VALIDITY_TIME_EXPIRED = -1073418207;
	public const HRESULT SL_E_LICENSE_AUTHORIZATION_FAILED = -1073418206;
	public const HRESULT SL_E_LICENSE_DECRYPTION_FAILED = -1073418205;
	public const HRESULT SL_E_WINDOWS_INVALID_LICENSE_STATE = -1073418204;
	public const HRESULT SL_E_LUA_ACCESSDENIED = -1073418203;
	public const HRESULT SL_E_PROXY_KEY_NOT_FOUND = -1073418202;
	public const HRESULT SL_E_TAMPER_DETECTED = -1073418201;
	public const HRESULT SL_E_POLICY_CACHE_INVALID = -1073418200;
	public const HRESULT SL_E_INVALID_RUNNING_MODE = -1073418199;
	public const HRESULT SL_E_SLP_NOT_SIGNED = -1073418198;
	public const HRESULT SL_E_CIDIID_INVALID_DATA = -1073418196;
	public const HRESULT SL_E_CIDIID_INVALID_VERSION = -1073418195;
	public const HRESULT SL_E_CIDIID_VERSION_NOT_SUPPORTED = -1073418194;
	public const HRESULT SL_E_CIDIID_INVALID_DATA_LENGTH = -1073418193;
	public const HRESULT SL_E_CIDIID_NOT_DEPOSITED = -1073418192;
	public const HRESULT SL_E_CIDIID_MISMATCHED = -1073418191;
	public const HRESULT SL_E_INVALID_BINDING_BLOB = -1073418190;
	public const HRESULT SL_E_PRODUCT_KEY_INSTALLATION_NOT_ALLOWED = -1073418189;
	public const HRESULT SL_E_EUL_NOT_AVAILABLE = -1073418188;
	public const HRESULT SL_E_VL_NOT_WINDOWS_SLP = -1073418187;
	public const HRESULT SL_E_VL_NOT_ENOUGH_COUNT = -1073418184;
	public const HRESULT SL_E_VL_BINDING_SERVICE_NOT_ENABLED = -1073418183;
	public const HRESULT SL_E_VL_INFO_PRODUCT_USER_RIGHT = 1074065472;
	public const HRESULT SL_E_VL_KEY_MANAGEMENT_SERVICE_NOT_ACTIVATED = -1073418175;
	public const HRESULT SL_E_VL_KEY_MANAGEMENT_SERVICE_ID_MISMATCH = -1073418174;
	public const HRESULT SL_E_PROXY_POLICY_NOT_UPDATED = -1073418169;
	public const HRESULT SL_E_CIDIID_INVALID_CHECK_DIGITS = -1073418163;
	public const HRESULT SL_E_LICENSE_MANAGEMENT_DATA_NOT_FOUND = -1073418161;
	public const HRESULT SL_E_INVALID_PRODUCT_KEY = -1073418160;
	public const HRESULT SL_E_BLOCKED_PRODUCT_KEY = -1073418159;
	public const HRESULT SL_E_DUPLICATE_POLICY = -1073418158;
	public const HRESULT SL_E_MISSING_OVERRIDE_ONLY_ATTRIBUTE = -1073418157;
	public const HRESULT SL_E_LICENSE_MANAGEMENT_DATA_DUPLICATED = -1073418156;
	public const HRESULT SL_E_BASE_SKU_NOT_AVAILABLE = -1073418155;
	public const HRESULT SL_E_VL_MACHINE_NOT_BOUND = -1073418154;
	public const HRESULT SL_E_SLP_MISSING_ACPI_SLIC = -1073418153;
	public const HRESULT SL_E_SLP_MISSING_SLP_MARKER = -1073418152;
	public const HRESULT SL_E_SLP_BAD_FORMAT = -1073418151;
	public const HRESULT SL_E_INVALID_PACKAGE_VERSION = -1073418144;
	public const HRESULT SL_E_PKEY_INVALID_UPGRADE = -1073418143;
	public const HRESULT SL_E_ISSUANCE_LICENSE_NOT_INSTALLED = -1073418142;
	public const HRESULT SL_E_SLP_OEM_CERT_MISSING = -1073418141;
	public const HRESULT SL_E_NONGENUINE_GRACE_TIME_EXPIRED = -1073418140;
	public const HRESULT SL_I_NONGENUINE_GRACE_PERIOD = 1074065509;
	public const HRESULT SL_E_DEPENDENT_PROPERTY_NOT_SET = -1073418138;
	public const HRESULT SL_E_NONGENUINE_GRACE_TIME_EXPIRED_2 = -1073418137;
	public const HRESULT SL_I_NONGENUINE_GRACE_PERIOD_2 = 1074065512;
	public const HRESULT SL_E_MISMATCHED_PRODUCT_SKU = -1073418135;
	public const HRESULT SL_E_OPERATION_NOT_ALLOWED = -1073418134;
	public const HRESULT SL_E_VL_KEY_MANAGEMENT_SERVICE_VM_NOT_SUPPORTED = -1073418133;
	public const HRESULT SL_E_VL_INVALID_TIMESTAMP = -1073418132;
	public const HRESULT SL_E_PLUGIN_INVALID_MANIFEST = -1073418127;
	public const HRESULT SL_E_APPLICATION_POLICIES_MISSING = -1073418126;
	public const HRESULT SL_E_APPLICATION_POLICIES_NOT_LOADED = -1073418125;
	public const HRESULT SL_E_VL_BINDING_SERVICE_UNAVAILABLE = -1073418124;
	public const HRESULT SL_E_SERVICE_STOPPING = -1073418123;
	public const HRESULT SL_E_PLUGIN_NOT_REGISTERED = -1073418122;
	public const HRESULT SL_E_AUTHN_WRONG_VERSION = -1073418121;
	public const HRESULT SL_E_AUTHN_MISMATCHED_KEY = -1073418120;
	public const HRESULT SL_E_AUTHN_CHALLENGE_NOT_SET = -1073418119;
	public const HRESULT SL_E_AUTHN_CANT_VERIFY = -1073418118;
	public const HRESULT SL_E_SERVICE_RUNNING = -1073418117;
	public const HRESULT SL_E_SLP_INVALID_MARKER_VERSION = -1073418116;
	public const HRESULT SL_E_INVALID_PRODUCT_KEY_TYPE = -1073418115;
	public const HRESULT SL_E_CIDIID_MISMATCHED_PKEY = -1073418114;
	public const HRESULT SL_E_CIDIID_NOT_BOUND = -1073418113;
	public const HRESULT SL_E_LICENSE_NOT_BOUND = -1073418112;
	public const HRESULT SL_E_VL_AD_AO_NOT_FOUND = -1073418111;
	public const HRESULT SL_E_VL_AD_AO_NAME_TOO_LONG = -1073418110;
	public const HRESULT SL_E_VL_AD_SCHEMA_VERSION_NOT_SUPPORTED = -1073418109;
	public const HRESULT SL_E_NOT_GENUINE = -1073417728;
	public const HRESULT SL_E_EDITION_MISMATCHED = -1073417712;
	public const HRESULT SL_E_HWID_CHANGED = -1073417711;
	public const HRESULT SL_E_OEM_KEY_EDITION_MISMATCH = -1073417710;
	public const HRESULT SL_E_NO_PRODUCT_KEY_FOUND = -1073417709;
	public const HRESULT SL_E_DOWNLEVEL_SETUP_KEY = -1073417708;
	public const HRESULT SL_E_BIOS_KEY = -1073417707;
	public const HRESULT SL_E_TKA_CHALLENGE_EXPIRED = -1073417471;
	public const HRESULT SL_E_TKA_SILENT_ACTIVATION_FAILURE = -1073417470;
	public const HRESULT SL_E_TKA_INVALID_CERT_CHAIN = -1073417469;
	public const HRESULT SL_E_TKA_GRANT_NOT_FOUND = -1073417468;
	public const HRESULT SL_E_TKA_CERT_NOT_FOUND = -1073417467;
	public const HRESULT SL_E_TKA_INVALID_SKU_ID = -1073417466;
	public const HRESULT SL_E_TKA_INVALID_BLOB = -1073417465;
	public const HRESULT SL_E_TKA_TAMPERED_CERT_CHAIN = -1073417464;
	public const HRESULT SL_E_TKA_CHALLENGE_MISMATCH = -1073417463;
	public const HRESULT SL_E_TKA_INVALID_CERTIFICATE = -1073417462;
	public const HRESULT SL_E_TKA_INVALID_SMARTCARD = -1073417461;
	public const HRESULT SL_E_TKA_FAILED_GRANT_PARSING = -1073417460;
	public const HRESULT SL_E_TKA_INVALID_THUMBPRINT = -1073417459;
	public const HRESULT SL_E_TKA_THUMBPRINT_CERT_NOT_FOUND = -1073417458;
	public const HRESULT SL_E_TKA_CRITERIA_MISMATCH = -1073417457;
	public const HRESULT SL_E_TKA_TPID_MISMATCH = -1073417456;
	public const HRESULT SL_E_TKA_SOFT_CERT_DISALLOWED = -1073417455;
	public const HRESULT SL_E_TKA_SOFT_CERT_INVALID = -1073417454;
	public const HRESULT SL_E_TKA_CERT_CNG_NOT_AVAILABLE = -1073417453;
	public const HRESULT SL_I_STORE_BASED_ACTIVATION = 1074066433;
	public const HRESULT E_RM_UNKNOWN_ERROR = -1073415165;
	public const HRESULT SL_I_TIMEBASED_VALIDITY_PERIOD = 1074068484;
	public const HRESULT SL_I_PERPETUAL_OOB_GRACE_PERIOD = 1074068485;
	public const HRESULT SL_I_TIMEBASED_EXTENDED_GRACE_PERIOD = 1074068486;
	public const HRESULT SL_E_VALIDITY_PERIOD_EXPIRED = -1073415161;
	public const HRESULT SL_E_IA_THROTTLE_LIMIT_EXCEEDED = -1073414912;
	public const HRESULT SL_E_IA_INVALID_VIRTUALIZATION_PLATFORM = -1073414911;
	public const HRESULT SL_E_IA_PARENT_PARTITION_NOT_ACTIVATED = -1073414910;
	public const HRESULT SL_E_IA_ID_MISMATCH = -1073414909;
	public const HRESULT SL_E_IA_MACHINE_NOT_BOUND = -1073414908;
	public const HRESULT SL_E_TAMPER_RECOVERY_REQUIRES_ACTIVATION = -1073414656;
	public const HRESULT SL_REMAPPING_SP_PUB_GENERAL_NOT_INITIALIZED = -1073426175;
	public const HRESULT SL_REMAPPING_SP_STATUS_SYSTEM_TIME_SKEWED = -2147167998;
	public const HRESULT SL_REMAPPING_SP_STATUS_GENERIC_FAILURE = -1073426173;
	public const HRESULT SL_REMAPPING_SP_STATUS_INVALIDARG = -1073426172;
	public const HRESULT SL_REMAPPING_SP_STATUS_ALREADY_EXISTS = -1073426171;
	public const HRESULT SL_REMAPPING_SP_STATUS_INSUFFICIENT_BUFFER = -1073426169;
	public const HRESULT SL_REMAPPING_SP_STATUS_INVALIDDATA = -1073426168;
	public const HRESULT SL_REMAPPING_SP_STATUS_INVALID_SPAPI_CALL = -1073426167;
	public const HRESULT SL_REMAPPING_SP_STATUS_INVALID_SPAPI_VERSION = -1073426166;
	public const HRESULT SL_REMAPPING_SP_STATUS_DEBUGGER_DETECTED = -2147167989;
	public const HRESULT SL_REMAPPING_SP_STATUS_NO_MORE_DATA = -1073426164;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_INVALID_KEYLENGTH = -1073425919;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_INVALID_BLOCKLENGTH = -1073425918;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_INVALID_CIPHER = -1073425917;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_INVALID_CIPHERMODE = -1073425916;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_UNKNOWN_PROVIDERID = -1073425915;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_UNKNOWN_KEYID = -1073425914;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_UNKNOWN_HASHID = -1073425913;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_UNKNOWN_ATTRIBUTEID = -1073425912;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_HASH_FINALIZED = -1073425911;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_KEY_NOT_AVAILABLE = -1073425910;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_KEY_NOT_FOUND = -1073425909;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_NOT_BLOCK_ALIGNED = -1073425908;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_INVALID_SIGNATURELENGTH = -1073425907;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_INVALID_SIGNATURE = -1073425906;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_INVALID_BLOCK = -1073425905;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_INVALID_FORMAT = -1073425904;
	public const HRESULT SL_REMAPPING_SP_PUB_CRYPTO_INVALID_PADDING = -1073425903;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_TAMPERED = -1073425663;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_REARMED = -1073425662;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_RECREATED = -1073425661;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_ENTRY_KEY_NOT_FOUND = -1073425660;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_ENTRY_KEY_ALREADY_EXISTS = -1073425659;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_ENTRY_KEY_SIZE_TOO_BIG = -1073425658;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_MAX_REARM_REACHED = -1073425657;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_DATA_SIZE_TOO_BIG = -1073425656;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_INVALID_HW_BINDING = -1073425655;
	public const HRESULT SL_REMAPPING_SP_PUB_TIMER_ALREADY_EXISTS = -1073425654;
	public const HRESULT SL_REMAPPING_SP_PUB_TIMER_NOT_FOUND = -1073425653;
	public const HRESULT SL_REMAPPING_SP_PUB_TIMER_EXPIRED = -1073425652;
	public const HRESULT SL_REMAPPING_SP_PUB_TIMER_NAME_SIZE_TOO_BIG = -1073425651;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_FULL = -1073425650;
	public const HRESULT SL_REMAPPING_SP_PUB_TRUSTED_TIME_OK = 1074057999;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_ENTRY_READ_ONLY = -1073425648;
	public const HRESULT SL_REMAPPING_SP_PUB_TIMER_READ_ONLY = -1073425647;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_ATTRIBUTE_READ_ONLY = -1073425646;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_ATTRIBUTE_NOT_FOUND = -1073425645;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_ACCESS_DENIED = -1073425644;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_NAMESPACE_NOT_FOUND = -1073425643;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_NAMESPACE_IN_USE = -1073425642;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_TAMPERED_BREADCRUMB_LOAD_INVALID = -1073425641;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_TAMPERED_BREADCRUMB_GENERATION = -1073425640;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_TAMPERED_INVALID_DATA = -1073425639;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_TAMPERED_NO_DATA = -1073425638;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_TAMPERED_DATA_BREADCRUMB_MISMATCH = -1073425637;
	public const HRESULT SL_REMAPPING_SP_PUB_TS_TAMPERED_DATA_VERSION_MISMATCH = -1073425636;
	public const HRESULT SL_REMAPPING_SP_PUB_TAMPER_MODULE_AUTHENTICATION = -1073425407;
	public const HRESULT SL_REMAPPING_SP_PUB_TAMPER_SECURITY_PROCESSOR_PATCHED = -1073425406;
	public const HRESULT SL_REMAPPING_SP_PUB_KM_CACHE_TAMPER = -1073425151;
	public const HRESULT SL_REMAPPING_SP_PUB_KM_CACHE_TAMPER_RESTORE_FAILED = -1073425150;
	public const HRESULT SL_REMAPPING_SP_PUB_KM_CACHE_IDENTICAL = 1074058753;
	public const HRESULT SL_REMAPPING_SP_PUB_KM_CACHE_POLICY_CHANGED = 1074058754;
	public const HRESULT SL_REMAPPING_SP_STATUS_PUSHKEY_CONFLICT = -1073424639;
	public const HRESULT SL_REMAPPING_SP_PUB_PROXY_SOFT_TAMPER = -1073424638;
	public const HRESULT SL_REMAPPING_SP_PUB_API_INVALID_LICENSE = -1073426432;
	public const HRESULT SL_REMAPPING_SP_PUB_API_INVALID_ALGORITHM_TYPE = -1073426423;
	public const HRESULT SL_REMAPPING_SP_PUB_API_TOO_MANY_LOADED_ENVIRONMENTS = -1073426420;
	public const HRESULT SL_REMAPPING_SP_PUB_API_BAD_GET_INFO_QUERY = -1073426414;
	public const HRESULT SL_REMAPPING_SP_PUB_API_INVALID_HANDLE = -1073426388;
	public const HRESULT SL_REMAPPING_SP_PUB_API_INVALID_KEY_LENGTH = -1073426347;
	public const HRESULT SL_REMAPPING_SP_PUB_API_NO_AES_PROVIDER = -1073426317;
	public const HRESULT SL_REMAPPING_SP_PUB_API_HANDLE_NOT_COMMITED = -1073426303;
	public const HRESULT SL_REMAPPING_MDOLLAR_PRODUCT_KEY_OUT_OF_RANGE = -2143313819;
	public const HRESULT SL_REMAPPING_MDOLLAR_INVALID_BINDING = -2143313818;
	public const HRESULT SL_REMAPPING_MDOLLAR_PRODUCT_KEY_BLOCKED = -2143313817;
	public const HRESULT SL_REMAPPING_MDOLLAR_INVALID_PRODUCT_KEY = -2143313816;
	public const HRESULT SL_REMAPPING_MDOLLAR_UNSUPPORTED_PRODUCT_KEY = -2143313812;
	public const HRESULT SL_REMAPPING_MDOLLAR_MAXIMUM_UNLOCK_EXCEEDED = -2143313807;
	public const HRESULT SL_REMAPPING_MDOLLAR_INVALID_PRODUCT_DATA_ID = -2143313805;
	public const HRESULT SL_REMAPPING_MDOLLAR_INVALID_PRODUCT_DATA = -2143313804;
	public const HRESULT SL_REMAPPING_MDOLLAR_INVALID_ACTCONFIG_ID = -2143313802;
	public const HRESULT SL_REMAPPING_MDOLLAR_INVALID_PRODUCT_KEY_LENGTH = -2143313801;
	public const HRESULT SL_REMAPPING_MDOLLAR_INVALID_PRODUCT_KEY_FORMAT = -2143313800;
	public const HRESULT SL_REMAPPING_MDOLLAR_INVALID_BINDING_URI = -2143313798;
	public const HRESULT SL_REMAPPING_MDOLLAR_INVALID_ARGUMENT = -2143313795;
	public const HRESULT SL_REMAPPING_MDOLLAR_DMAK_LIMIT_EXCEEDED = -2143313793;
	public const HRESULT SL_REMAPPING_MDOLLAR_DMAK_EXTENSION_LIMIT_EXCEEDED = -2143313792;
	public const HRESULT SL_REMAPPING_MDOLLAR_OEM_SLP_COA0 = -2143313789;
	public const HRESULT SL_REMAPPING_MDOLLAR_CIDIID_INVALID_VERSION = -2143313779;
	public const HRESULT SL_REMAPPING_MDOLLAR_CIDIID_INVALID_DATA = -2143313778;
	public const HRESULT SL_REMAPPING_MDOLLAR_CIDIID_INVALID_DATA_LENGTH = -2143313777;
	public const HRESULT SL_REMAPPING_MDOLLAR_CIDIID_INVALID_CHECK_DIGITS = -2143313776;
	public const HRESULT SL_REMAPPING_MDOLLAR_TIMEBASED_ACTIVATION_BEFORE_START_DATE = -2143313769;
	public const HRESULT SL_REMAPPING_MDOLLAR_TIMEBASED_ACTIVATION_AFTER_END_DATE = -2143313768;
	public const HRESULT SL_REMAPPING_MDOLLAR_TIMEBASED_ACTIVATION_NOT_AVAILABLE = -2143313767;
	public const HRESULT SL_REMAPPING_MDOLLAR_TIMEBASED_PRODUCT_KEY_NOT_CONFIGURED = -2143313766;
	public const HRESULT SL_REMAPPING_MDOLLAR_NO_RULES_TO_ACTIVATE = -2143313720;
	public const HRESULT SL_REMAPPING_MDOLLAR_PRODUCT_KEY_BLOCKED_IPLOCATION = -2143313717;
	public const HRESULT SL_REMAPPING_MDOLLAR_DIGITALMARKER_INVALID_BINDING = -2143313709;
	public const HRESULT SL_REMAPPING_MDOLLAR_DIGITALMARKER_BINDING_NOT_CONFIGURED = -2143313708;
	public const HRESULT SL_REMAPPING_MDOLLAR_ROT_OVERRIDE_LIMIT_REACHED = -2143313707;
	public const HRESULT SL_REMAPPING_MDOLLAR_DMAK_OVERRIDE_LIMIT_REACHED = -2143313706;
	public const HRESULT SL_REMAPPING_MDOLLAR_FREE_OFFER_EXPIRED = -2143312896;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_DONOR_HWID_NO_ENTITLEMENT = -2143310920;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_GENERIC_ERROR = -2143310919;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_NO_ASSOCIATION = -2143310918;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_NOT_ADMIN = -2143310917;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_USER_THROTTLED = -2143310916;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_LICENSE_THROTTLED = -2143310915;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_DEVICE_THROTTLED = -2143310914;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_GP_DISABLED = -2143310913;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_HARDWARE_BLOCKED = -2143310912;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_USER_BLOCKED = -2143310911;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_LICENSE_BLOCKED = -2143310910;
	public const HRESULT SL_REMAPPING_MDOLLAR_OSR_DEVICE_BLOCKED = -2143310909;
	public const Guid WINDOWS_SLID = .(0x55c92734, 0xd682, 0x4d71, 0x98, 0x3e, 0xd6, 0xec, 0x3f, 0x16, 0x05, 0x9f);
	public const String WDIGEST_SP_NAME_A = "WDigest";
	public const String WDIGEST_SP_NAME_W = "WDigest";
	public const String WDIGEST_SP_NAME = "WDigest";
}
#endregion

#region TypeDefs
typealias LsaHandle = int;

#endregion


#region Enums

[AllowDuplicates]
public enum SECPKG_ATTR : uint32
{
	SECPKG_ATTR_C_ACCESS_TOKEN = 2147483666,
	SECPKG_ATTR_C_FULL_ACCESS_TOKEN = 2147483778,
	SECPKG_ATTR_CERT_TRUST_STATUS = 2147483780,
	SECPKG_ATTR_CREDS = 2147483776,
	SECPKG_ATTR_CREDS_2 = 2147483782,
	SECPKG_ATTR_NEGOTIATION_PACKAGE = 2147483777,
	SECPKG_ATTR_PACKAGE_INFO = 10,
	SECPKG_ATTR_SERVER_AUTH_FLAGS = 2147483779,
	SECPKG_ATTR_SIZES = 0,
	SECPKG_ATTR_SUBJECT_SECURITY_ATTRIBUTES = 124,
	SECPKG_ATTR_APP_DATA = 94,
	SECPKG_ATTR_EAP_PRF_INFO = 101,
	SECPKG_ATTR_EARLY_START = 105,
	SECPKG_ATTR_DTLS_MTU = 34,
	SECPKG_ATTR_KEYING_MATERIAL_INFO = 106,
	SECPKG_ATTR_ACCESS_TOKEN = 18,
	SECPKG_ATTR_AUTHORITY = 6,
	SECPKG_ATTR_CLIENT_SPECIFIED_TARGET = 27,
	SECPKG_ATTR_CONNECTION_INFO = 90,
	SECPKG_ATTR_DCE_INFO = 3,
	SECPKG_ATTR_ENDPOINT_BINDINGS = 26,
	SECPKG_ATTR_EAP_KEY_BLOCK = 91,
	SECPKG_ATTR_FLAGS = 14,
	SECPKG_ATTR_ISSUER_LIST_EX = 89,
	SECPKG_ATTR_KEY_INFO = 5,
	SECPKG_ATTR_LAST_CLIENT_TOKEN_STATUS = 30,
	SECPKG_ATTR_LIFESPAN = 2,
	SECPKG_ATTR_LOCAL_CERT_CONTEXT = 84,
	SECPKG_ATTR_LOCAL_CRED = 82,
	SECPKG_ATTR_NAMES = 1,
	SECPKG_ATTR_NATIVE_NAMES = 13,
	SECPKG_ATTR_NEGOTIATION_INFO = 12,
	SECPKG_ATTR_PASSWORD_EXPIRY = 8,
	SECPKG_ATTR_REMOTE_CERT_CONTEXT = 83,
	SECPKG_ATTR_ROOT_STORE = 85,
	SECPKG_ATTR_SESSION_KEY = 9,
	SECPKG_ATTR_SESSION_INFO = 93,
	SECPKG_ATTR_STREAM_SIZES = 4,
	SECPKG_ATTR_SUPPORTED_SIGNATURES = 102,
	SECPKG_ATTR_TARGET_INFORMATION = 17,
	SECPKG_ATTR_UNIQUE_BINDINGS = 25,
}


[AllowDuplicates]
public enum MSV1_0 : uint32
{
	MSV1_0_PASSTHRU = 1,
	MSV1_0_GUEST_LOGON = 2,
}


[AllowDuplicates]
public enum SECPKG_CRED : uint32
{
	SECPKG_CRED_INBOUND = 1,
	SECPKG_CRED_OUTBOUND = 2,
}


[AllowDuplicates]
public enum MSV_SUB_AUTHENTICATION_FILTER : uint32
{
	LOGON_GUEST = 1,
	LOGON_NOENCRYPTION = 2,
	LOGON_CACHED_ACCOUNT = 4,
	LOGON_USED_LM_PASSWORD = 8,
	LOGON_EXTRA_SIDS = 32,
	LOGON_SUBAUTH_SESSION_KEY = 64,
	LOGON_SERVER_TRUST_ACCOUNT = 128,
	LOGON_PROFILE_PATH_RETURNED = 1024,
	LOGON_RESOURCE_GROUPS = 512,
}


[AllowDuplicates]
public enum EXPORT_SECURITY_CONTEXT_FLAGS : uint32
{
	SECPKG_CONTEXT_EXPORT_RESET_NEW = 1,
	SECPKG_CONTEXT_EXPORT_DELETE_OLD = 2,
	SECPKG_CONTEXT_EXPORT_TO_KERNEL = 4,
}


[AllowDuplicates]
public enum KERB_TICKET_FLAGS : uint32
{
	KERB_TICKET_FLAGS_forwardable = 1073741824,
	KERB_TICKET_FLAGS_forwarded = 536870912,
	KERB_TICKET_FLAGS_hw_authent = 1048576,
	KERB_TICKET_FLAGS_initial = 4194304,
	KERB_TICKET_FLAGS_invalid = 16777216,
	KERB_TICKET_FLAGS_may_postdate = 67108864,
	KERB_TICKET_FLAGS_ok_as_delegate = 262144,
	KERB_TICKET_FLAGS_postdated = 33554432,
	KERB_TICKET_FLAGS_pre_authent = 2097152,
	KERB_TICKET_FLAGS_proxiable = 268435456,
	KERB_TICKET_FLAGS_proxy = 134217728,
	KERB_TICKET_FLAGS_renewable = 8388608,
	KERB_TICKET_FLAGS_reserved = 2147483648,
	KERB_TICKET_FLAGS_reserved1 = 1,
}


[AllowDuplicates]
public enum KERB_ADDRESS_TYPE : uint32
{
	DS_INET_ADDRESS = 1,
	DS_NETBIOS_ADDRESS = 2,
}


[AllowDuplicates]
public enum SCHANNEL_CRED_FLAGS : uint32
{
	SCH_CRED_AUTO_CRED_VALIDATION = 32,
	SCH_CRED_CACHE_ONLY_URL_RETRIEVAL_ON_CREATE = 131072,
	SCH_DISABLE_RECONNECTS = 128,
	SCH_CRED_IGNORE_NO_REVOCATION_CHECK = 2048,
	SCH_CRED_IGNORE_REVOCATION_OFFLINE = 4096,
	SCH_CRED_MANUAL_CRED_VALIDATION = 8,
	SCH_CRED_NO_DEFAULT_CREDS = 16,
	SCH_CRED_NO_SERVERNAME_CHECK = 4,
	SCH_CRED_NO_SYSTEM_MAPPER = 2,
	SCH_CRED_REVOCATION_CHECK_CHAIN = 512,
	SCH_CRED_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT = 1024,
	SCH_CRED_REVOCATION_CHECK_END_CERT = 256,
	SCH_CRED_USE_DEFAULT_CREDS = 64,
	SCH_SEND_AUX_RECORD = 2097152,
	SCH_SEND_ROOT_CERT = 262144,
	SCH_USE_STRONG_CRYPTO = 4194304,
	SCH_USE_PRESHAREDKEY_ONLY = 8388608,
}


[AllowDuplicates]
public enum DOMAIN_PASSWORD_PROPERTIES : uint32
{
	DOMAIN_PASSWORD_COMPLEX = 1,
	DOMAIN_PASSWORD_NO_ANON_CHANGE = 2,
	DOMAIN_PASSWORD_NO_CLEAR_CHANGE = 4,
	DOMAIN_LOCKOUT_ADMINS = 8,
	DOMAIN_PASSWORD_STORE_CLEARTEXT = 16,
	DOMAIN_REFUSE_PASSWORD_CHANGE = 32,
}


[AllowDuplicates]
public enum SCHANNEL_ALERT_TOKEN_ALERT_TYPE : uint32
{
	TLS1_ALERT_WARNING = 1,
	TLS1_ALERT_FATAL = 2,
}


[AllowDuplicates]
public enum TRUSTED_DOMAIN_TRUST_TYPE : uint32
{
	TRUST_TYPE_DOWNLEVEL = 1,
	TRUST_TYPE_UPLEVEL = 2,
	TRUST_TYPE_MIT = 3,
	TRUST_TYPE_DCE = 4,
}


[AllowDuplicates]
public enum MSV_SUBAUTH_LOGON_PARAMETER_CONTROL : uint32
{
	MSV1_0_CLEARTEXT_PASSWORD_ALLOWED = 2,
	MSV1_0_UPDATE_LOGON_STATISTICS = 4,
	MSV1_0_RETURN_USER_PARAMETERS = 8,
	MSV1_0_DONT_TRY_GUEST_ACCOUNT = 16,
	MSV1_0_ALLOW_SERVER_TRUST_ACCOUNT = 32,
	MSV1_0_RETURN_PASSWORD_EXPIRY = 64,
	MSV1_0_ALLOW_WORKSTATION_TRUST_ACCOUNT = 2048,
	MSV1_0_TRY_GUEST_ACCOUNT_ONLY = 256,
	MSV1_0_RETURN_PROFILE_PATH = 512,
	MSV1_0_TRY_SPECIFIED_DOMAIN_ONLY = 1024,
}


[AllowDuplicates]
public enum KERB_REQUEST_FLAGS : uint32
{
	KERB_REQUEST_ADD_CREDENTIAL = 1,
	KERB_REQUEST_REPLACE_CREDENTIAL = 2,
	KERB_REQUEST_REMOVE_CREDENTIAL = 4,
}


[AllowDuplicates]
public enum TRUSTED_DOMAIN_TRUST_DIRECTION : uint32
{
	TRUST_DIRECTION_DISABLED = 0,
	TRUST_DIRECTION_INBOUND = 1,
	TRUST_DIRECTION_OUTBOUND = 2,
	TRUST_DIRECTION_BIDIRECTIONAL = 3,
}


[AllowDuplicates]
public enum MSV_SUPPLEMENTAL_CREDENTIAL_FLAGS : uint32
{
	MSV1_0_CRED_LM_PRESENT = 1,
	MSV1_0_CRED_NT_PRESENT = 2,
	MSV1_0_CRED_VERSION = 0,
}


[AllowDuplicates]
public enum SECURITY_PACKAGE_OPTIONS_TYPE : uint32
{
	SECPKG_OPTIONS_TYPE_UNKNOWN = 0,
	SECPKG_OPTIONS_TYPE_LSA = 1,
	SECPKG_OPTIONS_TYPE_SSPI = 2,
}


[AllowDuplicates]
public enum SCHANNEL_SESSION_TOKEN_FLAGS : uint32
{
	SSL_SESSION_ENABLE_RECONNECTS = 1,
	SSL_SESSION_DISABLE_RECONNECTS = 2,
}


[AllowDuplicates]
public enum KERB_CRYPTO_KEY_TYPE : int32
{
	KERB_ETYPE_DES_CBC_CRC = 1,
	KERB_ETYPE_DES_CBC_MD4 = 2,
	KERB_ETYPE_DES_CBC_MD5 = 3,
	KERB_ETYPE_NULL = 0,
	KERB_ETYPE_RC4_HMAC_NT = 23,
	KERB_ETYPE_RC4_MD4 = -128,
}


[AllowDuplicates]
public enum LSA_AUTH_INFORMATION_AUTH_TYPE : uint32
{
	TRUST_AUTH_TYPE_NONE = 0,
	TRUST_AUTH_TYPE_NT4OWF = 1,
	TRUST_AUTH_TYPE_CLEAR = 2,
	TRUST_AUTH_TYPE_VERSION = 3,
}


[AllowDuplicates]
public enum SECPKG_PACKAGE_CHANGE_TYPE : uint32
{
	SECPKG_PACKAGE_CHANGE_LOAD = 0,
	SECPKG_PACKAGE_CHANGE_UNLOAD = 1,
	SECPKG_PACKAGE_CHANGE_SELECT = 2,
}


[AllowDuplicates]
public enum TRUSTED_DOMAIN_TRUST_ATTRIBUTES : uint32
{
	TRUST_ATTRIBUTE_NON_TRANSITIVE = 1,
	TRUST_ATTRIBUTE_UPLEVEL_ONLY = 2,
	TRUST_ATTRIBUTE_FILTER_SIDS = 4,
	TRUST_ATTRIBUTE_FOREST_TRANSITIVE = 8,
	TRUST_ATTRIBUTE_CROSS_ORGANIZATION = 16,
	TRUST_ATTRIBUTE_TREAT_AS_EXTERNAL = 64,
	TRUST_ATTRIBUTE_WITHIN_FOREST = 32,
}


[AllowDuplicates]
public enum ISC_REQ_HIGH_FLAGS : uint64
{
	ISC_REQ_MESSAGES = 4294967296,
	ISC_REQ_DEFERRED_CRED_VALIDATION = 8589934592,
}


[AllowDuplicates]
public enum ISC_REQ_FLAGS : uint32
{
	ISC_REQ_DELEGATE = 1,
	ISC_REQ_MUTUAL_AUTH = 2,
	ISC_REQ_REPLAY_DETECT = 4,
	ISC_REQ_SEQUENCE_DETECT = 8,
	ISC_REQ_CONFIDENTIALITY = 16,
	ISC_REQ_USE_SESSION_KEY = 32,
	ISC_REQ_PROMPT_FOR_CREDS = 64,
	ISC_REQ_USE_SUPPLIED_CREDS = 128,
	ISC_REQ_ALLOCATE_MEMORY = 256,
	ISC_REQ_USE_DCE_STYLE = 512,
	ISC_REQ_DATAGRAM = 1024,
	ISC_REQ_CONNECTION = 2048,
	ISC_REQ_CALL_LEVEL = 4096,
	ISC_REQ_FRAGMENT_SUPPLIED = 8192,
	ISC_REQ_EXTENDED_ERROR = 16384,
	ISC_REQ_STREAM = 32768,
	ISC_REQ_INTEGRITY = 65536,
	ISC_REQ_IDENTIFY = 131072,
	ISC_REQ_NULL_SESSION = 262144,
	ISC_REQ_MANUAL_CRED_VALIDATION = 524288,
	ISC_REQ_RESERVED1 = 1048576,
	ISC_REQ_FRAGMENT_TO_FIT = 2097152,
	ISC_REQ_FORWARD_CREDENTIALS = 4194304,
	ISC_REQ_NO_INTEGRITY = 8388608,
	ISC_REQ_USE_HTTP_STYLE = 16777216,
	ISC_REQ_UNVERIFIED_TARGET_NAME = 536870912,
	ISC_REQ_CONFIDENTIALITY_ONLY = 1073741824,
}


[AllowDuplicates]
public enum ASC_REQ_HIGH_FLAGS : uint64
{
	ASC_REQ_MESSAGES = 4294967296,
}


[AllowDuplicates]
public enum ASC_REQ_FLAGS : uint32
{
	ASC_REQ_DELEGATE = 1,
	ASC_REQ_MUTUAL_AUTH = 2,
	ASC_REQ_REPLAY_DETECT = 4,
	ASC_REQ_SEQUENCE_DETECT = 8,
	ASC_REQ_CONFIDENTIALITY = 16,
	ASC_REQ_USE_SESSION_KEY = 32,
	ASC_REQ_SESSION_TICKET = 64,
	ASC_REQ_ALLOCATE_MEMORY = 256,
	ASC_REQ_USE_DCE_STYLE = 512,
	ASC_REQ_DATAGRAM = 1024,
	ASC_REQ_CONNECTION = 2048,
	ASC_REQ_CALL_LEVEL = 4096,
	ASC_REQ_FRAGMENT_SUPPLIED = 8192,
	ASC_REQ_EXTENDED_ERROR = 32768,
	ASC_REQ_STREAM = 65536,
	ASC_REQ_INTEGRITY = 131072,
	ASC_REQ_LICENSING = 262144,
	ASC_REQ_IDENTIFY = 524288,
	ASC_REQ_ALLOW_NULL_SESSION = 1048576,
	ASC_REQ_ALLOW_NON_USER_LOGONS = 2097152,
	ASC_REQ_ALLOW_CONTEXT_REPLAY = 4194304,
	ASC_REQ_FRAGMENT_TO_FIT = 8388608,
	ASC_REQ_NO_TOKEN = 16777216,
	ASC_REQ_PROXY_BINDINGS = 67108864,
	ASC_REQ_ALLOW_MISSING_BINDINGS = 268435456,
}


[AllowDuplicates]
public enum LSA_LOOKUP_DOMAIN_INFO_CLASS : int32
{
	AccountDomainInformation = 5,
	DnsDomainInformation = 12,
}


[AllowDuplicates]
public enum SECURITY_LOGON_TYPE : int32
{
	UndefinedLogonType = 0,
	Interactive = 2,
	Network = 3,
	Batch = 4,
	Service = 5,
	Proxy = 6,
	Unlock = 7,
	NetworkCleartext = 8,
	NewCredentials = 9,
	RemoteInteractive = 10,
	CachedInteractive = 11,
	CachedRemoteInteractive = 12,
	CachedUnlock = 13,
}


[AllowDuplicates]
public enum SE_ADT_PARAMETER_TYPE : int32
{
	SeAdtParmTypeNone = 0,
	SeAdtParmTypeString = 1,
	SeAdtParmTypeFileSpec = 2,
	SeAdtParmTypeUlong = 3,
	SeAdtParmTypeSid = 4,
	SeAdtParmTypeLogonId = 5,
	SeAdtParmTypeNoLogonId = 6,
	SeAdtParmTypeAccessMask = 7,
	SeAdtParmTypePrivs = 8,
	SeAdtParmTypeObjectTypes = 9,
	SeAdtParmTypeHexUlong = 10,
	SeAdtParmTypePtr = 11,
	SeAdtParmTypeTime = 12,
	SeAdtParmTypeGuid = 13,
	SeAdtParmTypeLuid = 14,
	SeAdtParmTypeHexInt64 = 15,
	SeAdtParmTypeStringList = 16,
	SeAdtParmTypeSidList = 17,
	SeAdtParmTypeDuration = 18,
	SeAdtParmTypeUserAccountControl = 19,
	SeAdtParmTypeNoUac = 20,
	SeAdtParmTypeMessage = 21,
	SeAdtParmTypeDateTime = 22,
	SeAdtParmTypeSockAddr = 23,
	SeAdtParmTypeSD = 24,
	SeAdtParmTypeLogonHours = 25,
	SeAdtParmTypeLogonIdNoSid = 26,
	SeAdtParmTypeUlongNoConv = 27,
	SeAdtParmTypeSockAddrNoPort = 28,
	SeAdtParmTypeAccessReason = 29,
	SeAdtParmTypeStagingReason = 30,
	SeAdtParmTypeResourceAttribute = 31,
	SeAdtParmTypeClaims = 32,
	SeAdtParmTypeLogonIdAsSid = 33,
	SeAdtParmTypeMultiSzString = 34,
	SeAdtParmTypeLogonIdEx = 35,
}


[AllowDuplicates]
public enum POLICY_AUDIT_EVENT_TYPE : int32
{
	AuditCategorySystem = 0,
	AuditCategoryLogon = 1,
	AuditCategoryObjectAccess = 2,
	AuditCategoryPrivilegeUse = 3,
	AuditCategoryDetailedTracking = 4,
	AuditCategoryPolicyChange = 5,
	AuditCategoryAccountManagement = 6,
	AuditCategoryDirectoryServiceAccess = 7,
	AuditCategoryAccountLogon = 8,
}


[AllowDuplicates]
public enum POLICY_LSA_SERVER_ROLE : int32
{
	PolicyServerRoleBackup = 2,
	PolicyServerRolePrimary = 3,
}


[AllowDuplicates]
public enum POLICY_INFORMATION_CLASS : int32
{
	PolicyAuditLogInformation = 1,
	PolicyAuditEventsInformation = 2,
	PolicyPrimaryDomainInformation = 3,
	PolicyPdAccountInformation = 4,
	PolicyAccountDomainInformation = 5,
	PolicyLsaServerRoleInformation = 6,
	PolicyReplicaSourceInformation = 7,
	PolicyDefaultQuotaInformation = 8,
	PolicyModificationInformation = 9,
	PolicyAuditFullSetInformation = 10,
	PolicyAuditFullQueryInformation = 11,
	PolicyDnsDomainInformation = 12,
	PolicyDnsDomainInformationInt = 13,
	PolicyLocalAccountDomainInformation = 14,
	PolicyMachineAccountInformation = 15,
	PolicyLastEntry = 16,
}


[AllowDuplicates]
public enum POLICY_DOMAIN_INFORMATION_CLASS : int32
{
	PolicyDomainEfsInformation = 2,
	PolicyDomainKerberosTicketInformation = 3,
}


[AllowDuplicates]
public enum POLICY_NOTIFICATION_INFORMATION_CLASS : int32
{
	PolicyNotifyAuditEventsInformation = 1,
	PolicyNotifyAccountDomainInformation = 2,
	PolicyNotifyServerRoleInformation = 3,
	PolicyNotifyDnsDomainInformation = 4,
	PolicyNotifyDomainEfsInformation = 5,
	PolicyNotifyDomainKerberosTicketInformation = 6,
	PolicyNotifyMachineAccountPasswordInformation = 7,
	PolicyNotifyGlobalSaclInformation = 8,
	PolicyNotifyMax = 9,
}


[AllowDuplicates]
public enum TRUSTED_INFORMATION_CLASS : int32
{
	TrustedDomainNameInformation = 1,
	TrustedControllersInformation = 2,
	TrustedPosixOffsetInformation = 3,
	TrustedPasswordInformation = 4,
	TrustedDomainInformationBasic = 5,
	TrustedDomainInformationEx = 6,
	TrustedDomainAuthInformation = 7,
	TrustedDomainFullInformation = 8,
	TrustedDomainAuthInformationInternal = 9,
	TrustedDomainFullInformationInternal = 10,
	TrustedDomainInformationEx2Internal = 11,
	TrustedDomainFullInformation2Internal = 12,
	TrustedDomainSupportedEncryptionTypes = 13,
}


[AllowDuplicates]
public enum LSA_FOREST_TRUST_RECORD_TYPE : int32
{
	ForestTrustTopLevelName = 0,
	ForestTrustTopLevelNameEx = 1,
	ForestTrustDomainInfo = 2,
	ForestTrustRecordTypeLast = 2,
}


[AllowDuplicates]
public enum LSA_FOREST_TRUST_COLLISION_RECORD_TYPE : int32
{
	CollisionTdo = 0,
	CollisionXref = 1,
	CollisionOther = 2,
}


[AllowDuplicates]
public enum NEGOTIATE_MESSAGES : int32
{
	NegEnumPackagePrefixes = 0,
	NegGetCallerName = 1,
	NegTransferCredentials = 2,
	NegMsgReserved1 = 3,
	NegCallPackageMax = 4,
}


[AllowDuplicates]
public enum MSV1_0_LOGON_SUBMIT_TYPE : int32
{
	MsV1_0InteractiveLogon = 2,
	MsV1_0Lm20Logon = 3,
	MsV1_0NetworkLogon = 4,
	MsV1_0SubAuthLogon = 5,
	MsV1_0WorkstationUnlockLogon = 7,
	MsV1_0S4ULogon = 12,
	MsV1_0VirtualLogon = 82,
	MsV1_0NoElevationLogon = 83,
	MsV1_0LuidLogon = 84,
}


[AllowDuplicates]
public enum MSV1_0_PROFILE_BUFFER_TYPE : int32
{
	MsV1_0InteractiveProfile = 2,
	MsV1_0Lm20LogonProfile = 3,
	MsV1_0SmartCardProfile = 4,
}


[AllowDuplicates]
public enum MSV1_0_CREDENTIAL_KEY_TYPE : int32
{
	InvalidCredKey = 0,
	DeprecatedIUMCredKey = 1,
	DomainUserCredKey = 2,
	LocalUserCredKey = 3,
	ExternallySuppliedCredKey = 4,
}


[AllowDuplicates]
public enum MSV1_0_AVID : int32
{
	MsvAvEOL = 0,
	MsvAvNbComputerName = 1,
	MsvAvNbDomainName = 2,
	MsvAvDnsComputerName = 3,
	MsvAvDnsDomainName = 4,
	MsvAvDnsTreeName = 5,
	MsvAvFlags = 6,
	MsvAvTimestamp = 7,
	MsvAvRestrictions = 8,
	MsvAvTargetName = 9,
	MsvAvChannelBindings = 10,
}


[AllowDuplicates]
public enum MSV1_0_PROTOCOL_MESSAGE_TYPE : int32
{
	MsV1_0Lm20ChallengeRequest = 0,
	MsV1_0Lm20GetChallengeResponse = 1,
	MsV1_0EnumerateUsers = 2,
	MsV1_0GetUserInfo = 3,
	MsV1_0ReLogonUsers = 4,
	MsV1_0ChangePassword = 5,
	MsV1_0ChangeCachedPassword = 6,
	MsV1_0GenericPassthrough = 7,
	MsV1_0CacheLogon = 8,
	MsV1_0SubAuth = 9,
	MsV1_0DeriveCredential = 10,
	MsV1_0CacheLookup = 11,
	MsV1_0SetProcessOption = 12,
	MsV1_0ConfigLocalAliases = 13,
	MsV1_0ClearCachedCredentials = 14,
	MsV1_0LookupToken = 15,
	MsV1_0ValidateAuth = 16,
	MsV1_0CacheLookupEx = 17,
	MsV1_0GetCredentialKey = 18,
	MsV1_0SetThreadOption = 19,
	MsV1_0DecryptDpapiMasterKey = 20,
	MsV1_0GetStrongCredentialKey = 21,
	MsV1_0TransferCred = 22,
	MsV1_0ProvisionTbal = 23,
	MsV1_0DeleteTbalSecrets = 24,
}


[AllowDuplicates]
public enum KERB_LOGON_SUBMIT_TYPE : int32
{
	KerbInteractiveLogon = 2,
	KerbSmartCardLogon = 6,
	KerbWorkstationUnlockLogon = 7,
	KerbSmartCardUnlockLogon = 8,
	KerbProxyLogon = 9,
	KerbTicketLogon = 10,
	KerbTicketUnlockLogon = 11,
	KerbS4ULogon = 12,
	KerbCertificateLogon = 13,
	KerbCertificateS4ULogon = 14,
	KerbCertificateUnlockLogon = 15,
	KerbNoElevationLogon = 83,
	KerbLuidLogon = 84,
}


[AllowDuplicates]
public enum KERB_PROFILE_BUFFER_TYPE : int32
{
	KerbInteractiveProfile = 2,
	KerbSmartCardProfile = 4,
	KerbTicketProfile = 6,
}


[AllowDuplicates]
public enum KERB_PROTOCOL_MESSAGE_TYPE : int32
{
	KerbDebugRequestMessage = 0,
	KerbQueryTicketCacheMessage = 1,
	KerbChangeMachinePasswordMessage = 2,
	KerbVerifyPacMessage = 3,
	KerbRetrieveTicketMessage = 4,
	KerbUpdateAddressesMessage = 5,
	KerbPurgeTicketCacheMessage = 6,
	KerbChangePasswordMessage = 7,
	KerbRetrieveEncodedTicketMessage = 8,
	KerbDecryptDataMessage = 9,
	KerbAddBindingCacheEntryMessage = 10,
	KerbSetPasswordMessage = 11,
	KerbSetPasswordExMessage = 12,
	KerbVerifyCredentialsMessage = 13,
	KerbQueryTicketCacheExMessage = 14,
	KerbPurgeTicketCacheExMessage = 15,
	KerbRefreshSmartcardCredentialsMessage = 16,
	KerbAddExtraCredentialsMessage = 17,
	KerbQuerySupplementalCredentialsMessage = 18,
	KerbTransferCredentialsMessage = 19,
	KerbQueryTicketCacheEx2Message = 20,
	KerbSubmitTicketMessage = 21,
	KerbAddExtraCredentialsExMessage = 22,
	KerbQueryKdcProxyCacheMessage = 23,
	KerbPurgeKdcProxyCacheMessage = 24,
	KerbQueryTicketCacheEx3Message = 25,
	KerbCleanupMachinePkinitCredsMessage = 26,
	KerbAddBindingCacheEntryExMessage = 27,
	KerbQueryBindingCacheMessage = 28,
	KerbPurgeBindingCacheMessage = 29,
	KerbPinKdcMessage = 30,
	KerbUnpinAllKdcsMessage = 31,
	KerbQueryDomainExtendedPoliciesMessage = 32,
	KerbQueryS4U2ProxyCacheMessage = 33,
	KerbRetrieveKeyTabMessage = 34,
	KerbRefreshPolicyMessage = 35,
	KerbPrintCloudKerberosDebugMessage = 36,
}


[AllowDuplicates]
public enum KERB_CERTIFICATE_INFO_TYPE : int32
{
	CertHashInfo = 1,
}


[AllowDuplicates]
public enum PKU2U_LOGON_SUBMIT_TYPE : int32
{
	Pku2uCertificateS4ULogon = 14,
}


[AllowDuplicates]
public enum SEC_APPLICATION_PROTOCOL_NEGOTIATION_EXT : int32
{
	SecApplicationProtocolNegotiationExt_None = 0,
	SecApplicationProtocolNegotiationExt_NPN = 1,
	SecApplicationProtocolNegotiationExt_ALPN = 2,
}


[AllowDuplicates]
public enum SEC_TRAFFIC_SECRET_TYPE : int32
{
	SecTrafficSecret_None = 0,
	SecTrafficSecret_Client = 1,
	SecTrafficSecret_Server = 2,
}


[AllowDuplicates]
public enum SECPKG_CRED_CLASS : int32
{
	SecPkgCredClass_None = 0,
	SecPkgCredClass_Ephemeral = 10,
	SecPkgCredClass_PersistedGeneric = 20,
	SecPkgCredClass_PersistedSpecific = 30,
	SecPkgCredClass_Explicit = 40,
}


[AllowDuplicates]
public enum SECPKG_ATTR_LCT_STATUS : int32
{
	SecPkgAttrLastClientTokenYes = 0,
	SecPkgAttrLastClientTokenNo = 1,
	SecPkgAttrLastClientTokenMaybe = 2,
}


[AllowDuplicates]
public enum SEC_APPLICATION_PROTOCOL_NEGOTIATION_STATUS : int32
{
	SecApplicationProtocolNegotiationStatus_None = 0,
	SecApplicationProtocolNegotiationStatus_Success = 1,
	SecApplicationProtocolNegotiationStatus_SelectedClientOnly = 2,
}


[AllowDuplicates]
public enum SecDelegationType : int32
{
	SecFull = 0,
	SecService = 1,
	SecTree = 2,
	SecDirectory = 3,
	SecObject = 4,
}


[AllowDuplicates]
public enum SASL_AUTHZID_STATE : int32
{
	Sasl_AuthZIDForbidden = 0,
	Sasl_AuthZIDProcessed = 1,
}


[AllowDuplicates]
public enum LSA_TOKEN_INFORMATION_TYPE : int32
{
	LsaTokenInformationNull = 0,
	LsaTokenInformationV1 = 1,
	LsaTokenInformationV2 = 2,
	LsaTokenInformationV3 = 3,
}


[AllowDuplicates]
public enum SECPKG_EXTENDED_INFORMATION_CLASS : int32
{
	SecpkgGssInfo = 1,
	SecpkgContextThunks = 2,
	SecpkgMutualAuthLevel = 3,
	SecpkgWowClientDll = 4,
	SecpkgExtraOids = 5,
	SecpkgMaxInfo = 6,
	SecpkgNego2Info = 7,
}


[AllowDuplicates]
public enum SECPKG_CALL_PACKAGE_MESSAGE_TYPE : int32
{
	SecPkgCallPackageMinMessage = 1024,
	SecPkgCallPackagePinDcMessage = 1024,
	SecPkgCallPackageUnpinAllDcsMessage = 1025,
	SecPkgCallPackageTransferCredMessage = 1026,
	SecPkgCallPackageMaxMessage = 1026,
}


[AllowDuplicates]
public enum SECPKG_SESSIONINFO_TYPE : int32
{
	SecSessionPrimaryCred = 0,
}


[AllowDuplicates]
public enum SECPKG_NAME_TYPE : int32
{
	SecNameSamCompatible = 0,
	SecNameAlternateId = 1,
	SecNameFlat = 2,
	SecNameDN = 3,
	SecNameSPN = 4,
}


[AllowDuplicates]
public enum CRED_FETCH : int32
{
	CredFetchDefault = 0,
	CredFetchDPAPI = 1,
	CredFetchForced = 2,
}


[AllowDuplicates]
public enum KSEC_CONTEXT_TYPE : int32
{
	KSecPaged = 0,
	KSecNonPaged = 1,
}


[AllowDuplicates]
public enum eTlsSignatureAlgorithm : int32
{
	TlsSignatureAlgorithm_Anonymous = 0,
	TlsSignatureAlgorithm_Rsa = 1,
	TlsSignatureAlgorithm_Dsa = 2,
	TlsSignatureAlgorithm_Ecdsa = 3,
}


[AllowDuplicates]
public enum eTlsHashAlgorithm : int32
{
	TlsHashAlgorithm_None = 0,
	TlsHashAlgorithm_Md5 = 1,
	TlsHashAlgorithm_Sha1 = 2,
	TlsHashAlgorithm_Sha224 = 3,
	TlsHashAlgorithm_Sha256 = 4,
	TlsHashAlgorithm_Sha384 = 5,
	TlsHashAlgorithm_Sha512 = 6,
}


[AllowDuplicates]
public enum SchGetExtensionsOptions : uint32
{
	SCH_EXTENSIONS_OPTIONS_NONE = 0,
	SCH_NO_RECORD_HEADER = 1,
}


[AllowDuplicates]
public enum NETLOGON_LOGON_INFO_CLASS : int32
{
	NetlogonInteractiveInformation = 1,
	NetlogonNetworkInformation = 2,
	NetlogonServiceInformation = 3,
	NetlogonGenericInformation = 4,
	NetlogonInteractiveTransitiveInformation = 5,
	NetlogonNetworkTransitiveInformation = 6,
	NetlogonServiceTransitiveInformation = 7,
}


[AllowDuplicates]
public enum TOKENBINDING_TYPE : int32
{
	TOKENBINDING_TYPE_PROVIDED = 0,
	TOKENBINDING_TYPE_REFERRED = 1,
}


[AllowDuplicates]
public enum TOKENBINDING_EXTENSION_FORMAT : int32
{
	TOKENBINDING_EXTENSION_FORMAT_UNDEFINED = 0,
}


[AllowDuplicates]
public enum TOKENBINDING_KEY_PARAMETERS_TYPE : int32
{
	TOKENBINDING_KEY_PARAMETERS_TYPE_RSA2048_PKCS = 0,
	TOKENBINDING_KEY_PARAMETERS_TYPE_RSA2048_PSS = 1,
	TOKENBINDING_KEY_PARAMETERS_TYPE_ECDSAP256 = 2,
	TOKENBINDING_KEY_PARAMETERS_TYPE_ANYEXISTING = 255,
}


[AllowDuplicates]
public enum EXTENDED_NAME_FORMAT : int32
{
	NameUnknown = 0,
	NameFullyQualifiedDN = 1,
	NameSamCompatible = 2,
	NameDisplay = 3,
	NameUniqueId = 6,
	NameCanonical = 7,
	NameUserPrincipal = 8,
	NameCanonicalEx = 9,
	NameServicePrincipal = 10,
	NameDnsDomain = 12,
	NameGivenName = 13,
	NameSurname = 14,
}


[AllowDuplicates]
public enum SLDATATYPE : uint32
{
	SL_DATA_NONE = 0,
	SL_DATA_SZ = 1,
	SL_DATA_DWORD = 4,
	SL_DATA_BINARY = 3,
	SL_DATA_MULTI_SZ = 7,
	SL_DATA_SUM = 100,
}


[AllowDuplicates]
public enum SLIDTYPE : int32
{
	SL_ID_APPLICATION = 0,
	SL_ID_PRODUCT_SKU = 1,
	SL_ID_LICENSE_FILE = 2,
	SL_ID_LICENSE = 3,
	SL_ID_PKEY = 4,
	SL_ID_ALL_LICENSES = 5,
	SL_ID_ALL_LICENSE_FILES = 6,
	SL_ID_STORE_TOKEN = 7,
	SL_ID_LAST = 8,
}


[AllowDuplicates]
public enum SLLICENSINGSTATUS : int32
{
	SL_LICENSING_STATUS_UNLICENSED = 0,
	SL_LICENSING_STATUS_LICENSED = 1,
	SL_LICENSING_STATUS_IN_GRACE_PERIOD = 2,
	SL_LICENSING_STATUS_NOTIFICATION = 3,
	SL_LICENSING_STATUS_LAST = 4,
}


[AllowDuplicates]
public enum SL_ACTIVATION_TYPE : int32
{
	SL_ACTIVATION_TYPE_DEFAULT = 0,
	SL_ACTIVATION_TYPE_ACTIVE_DIRECTORY = 1,
}


[AllowDuplicates]
public enum SLREFERRALTYPE : int32
{
	SL_REFERRALTYPE_SKUID = 0,
	SL_REFERRALTYPE_APPID = 1,
	SL_REFERRALTYPE_OVERRIDE_SKUID = 2,
	SL_REFERRALTYPE_OVERRIDE_APPID = 3,
	SL_REFERRALTYPE_BEST_MATCH = 4,
}


[AllowDuplicates]
public enum SL_GENUINE_STATE : int32
{
	SL_GEN_STATE_IS_GENUINE = 0,
	SL_GEN_STATE_INVALID_LICENSE = 1,
	SL_GEN_STATE_TAMPERED = 2,
	SL_GEN_STATE_OFFLINE = 3,
	SL_GEN_STATE_LAST = 4,
}

#endregion

#region Function Pointers
public function NTSTATUS PSAM_PASSWORD_NOTIFICATION_ROUTINE(UNICODE_STRING* UserName, uint32 RelativeId, UNICODE_STRING* NewPassword);

public function BOOLEAN PSAM_INIT_NOTIFICATION_ROUTINE();

public function BOOLEAN PSAM_PASSWORD_FILTER_ROUTINE(UNICODE_STRING* AccountName, UNICODE_STRING* FullName, UNICODE_STRING* Password, BOOLEAN SetOperation);

public function void SEC_GET_KEY_FN(void* Arg, void* Principal, uint32 KeyVer, void** Key, HRESULT* Status);

public function HRESULT ACQUIRE_CREDENTIALS_HANDLE_FN_W(uint16* param0, uint16* param1, uint32 param2, void* param3, void* param4, SEC_GET_KEY_FN param5, void* param6, SecHandle* param7, LARGE_INTEGER* param8);

public function HRESULT ACQUIRE_CREDENTIALS_HANDLE_FN_A(int8* param0, int8* param1, uint32 param2, void* param3, void* param4, SEC_GET_KEY_FN param5, void* param6, SecHandle* param7, LARGE_INTEGER* param8);

public function HRESULT FREE_CREDENTIALS_HANDLE_FN(SecHandle* param0);

public function HRESULT ADD_CREDENTIALS_FN_W(SecHandle* param0, uint16* param1, uint16* param2, uint32 param3, void* param4, SEC_GET_KEY_FN param5, void* param6, LARGE_INTEGER* param7);

public function HRESULT ADD_CREDENTIALS_FN_A(SecHandle* param0, int8* param1, int8* param2, uint32 param3, void* param4, SEC_GET_KEY_FN param5, void* param6, LARGE_INTEGER* param7);

public function HRESULT CHANGE_PASSWORD_FN_W(uint16* param0, uint16* param1, uint16* param2, uint16* param3, uint16* param4, BOOLEAN param5, uint32 param6, SecBufferDesc* param7);

public function HRESULT CHANGE_PASSWORD_FN_A(int8* param0, int8* param1, int8* param2, int8* param3, int8* param4, BOOLEAN param5, uint32 param6, SecBufferDesc* param7);

public function HRESULT INITIALIZE_SECURITY_CONTEXT_FN_W(SecHandle* param0, SecHandle* param1, uint16* param2, uint32 param3, uint32 param4, uint32 param5, SecBufferDesc* param6, uint32 param7, SecHandle* param8, SecBufferDesc* param9, uint32* param10, LARGE_INTEGER* param11);

public function HRESULT INITIALIZE_SECURITY_CONTEXT_FN_A(SecHandle* param0, SecHandle* param1, int8* param2, uint32 param3, uint32 param4, uint32 param5, SecBufferDesc* param6, uint32 param7, SecHandle* param8, SecBufferDesc* param9, uint32* param10, LARGE_INTEGER* param11);

public function HRESULT ACCEPT_SECURITY_CONTEXT_FN(SecHandle* param0, SecHandle* param1, SecBufferDesc* param2, uint32 param3, uint32 param4, SecHandle* param5, SecBufferDesc* param6, uint32* param7, LARGE_INTEGER* param8);

public function HRESULT COMPLETE_AUTH_TOKEN_FN(SecHandle* param0, SecBufferDesc* param1);

public function HRESULT IMPERSONATE_SECURITY_CONTEXT_FN(SecHandle* param0);

public function HRESULT REVERT_SECURITY_CONTEXT_FN(SecHandle* param0);

public function HRESULT QUERY_SECURITY_CONTEXT_TOKEN_FN(SecHandle* param0, void** param1);

public function HRESULT DELETE_SECURITY_CONTEXT_FN(SecHandle* param0);

public function HRESULT APPLY_CONTROL_TOKEN_FN(SecHandle* param0, SecBufferDesc* param1);

public function HRESULT QUERY_CONTEXT_ATTRIBUTES_FN_W(SecHandle* param0, uint32 param1, void* param2);

public function HRESULT QUERY_CONTEXT_ATTRIBUTES_EX_FN_W(SecHandle* param0, uint32 param1, void* param2, uint32 param3);

public function HRESULT QUERY_CONTEXT_ATTRIBUTES_FN_A(SecHandle* param0, uint32 param1, void* param2);

public function HRESULT QUERY_CONTEXT_ATTRIBUTES_EX_FN_A(SecHandle* param0, uint32 param1, void* param2, uint32 param3);

public function HRESULT SET_CONTEXT_ATTRIBUTES_FN_W(SecHandle* param0, uint32 param1, void* param2, uint32 param3);

public function HRESULT SET_CONTEXT_ATTRIBUTES_FN_A(SecHandle* param0, uint32 param1, void* param2, uint32 param3);

public function HRESULT QUERY_CREDENTIALS_ATTRIBUTES_FN_W(SecHandle* param0, uint32 param1, void* param2);

public function HRESULT QUERY_CREDENTIALS_ATTRIBUTES_EX_FN_W(SecHandle* param0, uint32 param1, void* param2, uint32 param3);

public function HRESULT QUERY_CREDENTIALS_ATTRIBUTES_FN_A(SecHandle* param0, uint32 param1, void* param2);

public function HRESULT QUERY_CREDENTIALS_ATTRIBUTES_EX_FN_A(SecHandle* param0, uint32 param1, void* param2, uint32 param3);

public function HRESULT SET_CREDENTIALS_ATTRIBUTES_FN_W(SecHandle* param0, uint32 param1, void* param2, uint32 param3);

public function HRESULT SET_CREDENTIALS_ATTRIBUTES_FN_A(SecHandle* param0, uint32 param1, void* param2, uint32 param3);

public function HRESULT FREE_CONTEXT_BUFFER_FN(void* param0);

public function HRESULT MAKE_SIGNATURE_FN(SecHandle* param0, uint32 param1, SecBufferDesc* param2, uint32 param3);

public function HRESULT VERIFY_SIGNATURE_FN(SecHandle* param0, SecBufferDesc* param1, uint32 param2, uint32* param3);

public function HRESULT ENCRYPT_MESSAGE_FN(SecHandle* param0, uint32 param1, SecBufferDesc* param2, uint32 param3);

public function HRESULT DECRYPT_MESSAGE_FN(SecHandle* param0, SecBufferDesc* param1, uint32 param2, uint32* param3);

public function HRESULT ENUMERATE_SECURITY_PACKAGES_FN_W(uint32* param0, SecPkgInfoW** param1);

public function HRESULT ENUMERATE_SECURITY_PACKAGES_FN_A(uint32* param0, SecPkgInfoA** param1);

public function HRESULT QUERY_SECURITY_PACKAGE_INFO_FN_W(uint16* param0, SecPkgInfoW** param1);

public function HRESULT QUERY_SECURITY_PACKAGE_INFO_FN_A(int8* param0, SecPkgInfoA** param1);

public function HRESULT EXPORT_SECURITY_CONTEXT_FN(SecHandle* param0, uint32 param1, SecBuffer* param2, void** param3);

public function HRESULT IMPORT_SECURITY_CONTEXT_FN_W(uint16* param0, SecBuffer* param1, void* param2, SecHandle* param3);

public function HRESULT IMPORT_SECURITY_CONTEXT_FN_A(int8* param0, SecBuffer* param1, void* param2, SecHandle* param3);

public function SecurityFunctionTableA* INIT_SECURITY_INTERFACE_A();

public function SecurityFunctionTableW* INIT_SECURITY_INTERFACE_W();

public function NTSTATUS PLSA_CREATE_LOGON_SESSION(LUID* LogonId);

public function NTSTATUS PLSA_DELETE_LOGON_SESSION(LUID* LogonId);

public function NTSTATUS PLSA_ADD_CREDENTIAL(LUID* LogonId, uint32 AuthenticationPackage, STRING* PrimaryKeyValue, STRING* Credentials);

public function NTSTATUS PLSA_GET_CREDENTIALS(LUID* LogonId, uint32 AuthenticationPackage, uint32* QueryContext, BOOLEAN RetrieveAllCredentials, STRING* PrimaryKeyValue, uint32* PrimaryKeyLength, STRING* Credentials);

public function NTSTATUS PLSA_DELETE_CREDENTIAL(LUID* LogonId, uint32 AuthenticationPackage, STRING* PrimaryKeyValue);

public function void* PLSA_ALLOCATE_LSA_HEAP(uint32 Length);

public function void PLSA_FREE_LSA_HEAP(void* Base);

public function void* PLSA_ALLOCATE_PRIVATE_HEAP(uint Length);

public function void PLSA_FREE_PRIVATE_HEAP(void* Base);

public function NTSTATUS PLSA_ALLOCATE_CLIENT_BUFFER(void** ClientRequest, uint32 LengthRequired, void** ClientBaseAddress);

public function NTSTATUS PLSA_FREE_CLIENT_BUFFER(void** ClientRequest, void* ClientBaseAddress);

public function NTSTATUS PLSA_COPY_TO_CLIENT_BUFFER(void** ClientRequest, uint32 Length, void* ClientBaseAddress, void* BufferToCopy);

public function NTSTATUS PLSA_COPY_FROM_CLIENT_BUFFER(void** ClientRequest, uint32 Length, void* BufferToCopy, void* ClientBaseAddress);

public function NTSTATUS PLSA_AP_INITIALIZE_PACKAGE(uint32 AuthenticationPackageId, LSA_DISPATCH_TABLE* LsaDispatchTable, STRING* Database, STRING* Confidentiality, STRING** AuthenticationPackageName);

public function NTSTATUS PLSA_AP_LOGON_USER(void** ClientRequest, SECURITY_LOGON_TYPE LogonType, void* AuthenticationInformation, void* ClientAuthenticationBase, uint32 AuthenticationInformationLength, void** ProfileBuffer, uint32* ProfileBufferLength, LUID* LogonId, int32* SubStatus, LSA_TOKEN_INFORMATION_TYPE* TokenInformationType, void** TokenInformation, UNICODE_STRING** AccountName, UNICODE_STRING** AuthenticatingAuthority);

public function NTSTATUS PLSA_AP_LOGON_USER_EX(void** ClientRequest, SECURITY_LOGON_TYPE LogonType, void* AuthenticationInformation, void* ClientAuthenticationBase, uint32 AuthenticationInformationLength, void** ProfileBuffer, uint32* ProfileBufferLength, LUID* LogonId, int32* SubStatus, LSA_TOKEN_INFORMATION_TYPE* TokenInformationType, void** TokenInformation, UNICODE_STRING** AccountName, UNICODE_STRING** AuthenticatingAuthority, UNICODE_STRING** MachineName);

public function NTSTATUS PLSA_AP_CALL_PACKAGE(void** ClientRequest, void* ProtocolSubmitBuffer, void* ClientBufferBase, uint32 SubmitBufferLength, void** ProtocolReturnBuffer, uint32* ReturnBufferLength, int32* ProtocolStatus);

public function NTSTATUS PLSA_AP_CALL_PACKAGE_PASSTHROUGH(void** ClientRequest, void* ProtocolSubmitBuffer, void* ClientBufferBase, uint32 SubmitBufferLength, void** ProtocolReturnBuffer, uint32* ReturnBufferLength, int32* ProtocolStatus);

public function void PLSA_AP_LOGON_TERMINATED(LUID* LogonId);

public function NTSTATUS PSAM_CREDENTIAL_UPDATE_NOTIFY_ROUTINE(UNICODE_STRING* ClearPassword, void* OldCredentials, uint32 OldCredentialSize, uint32 UserAccountControl, UNICODE_STRING* UPN, UNICODE_STRING* UserName, UNICODE_STRING* NetbiosDomainName, UNICODE_STRING* DnsDomainName, void** NewCredentials, uint32* NewCredentialSize);

public function BOOLEAN PSAM_CREDENTIAL_UPDATE_REGISTER_ROUTINE(UNICODE_STRING* CredentialName);

public function void PSAM_CREDENTIAL_UPDATE_FREE_ROUTINE(void* p);

public function NTSTATUS PSAM_CREDENTIAL_UPDATE_REGISTER_MAPPED_ENTRYPOINTS_ROUTINE(SAM_REGISTER_MAPPING_TABLE* Table);

public function NTSTATUS PLSA_CALLBACK_FUNCTION(uint Argument1, uint Argument2, SecBuffer* InputBuffer, SecBuffer* OutputBuffer);

public function NTSTATUS PLSA_REDIRECTED_LOGON_INIT(HANDLE RedirectedLogonHandle, UNICODE_STRING* PackageName, uint32 SessionId, LUID* LogonId);

public function NTSTATUS PLSA_REDIRECTED_LOGON_CALLBACK(HANDLE RedirectedLogonHandle, void* Buffer, uint32 BufferLength, void** ReturnBuffer, uint32* ReturnBufferLength);

public function void PLSA_REDIRECTED_LOGON_CLEANUP_CALLBACK(HANDLE RedirectedLogonHandle);

public function NTSTATUS PLSA_REDIRECTED_LOGON_GET_LOGON_CREDS(HANDLE RedirectedLogonHandle, uint8** LogonBuffer, uint32* LogonBufferLength);

public function NTSTATUS PLSA_REDIRECTED_LOGON_GET_SUPP_CREDS(HANDLE RedirectedLogonHandle, SECPKG_SUPPLEMENTAL_CRED_ARRAY** SupplementalCredentials);

public function NTSTATUS PLSA_IMPERSONATE_CLIENT();

public function NTSTATUS PLSA_UNLOAD_PACKAGE();

public function NTSTATUS PLSA_DUPLICATE_HANDLE(HANDLE SourceHandle, HANDLE* DestionationHandle);

public function NTSTATUS PLSA_SAVE_SUPPLEMENTAL_CREDENTIALS(LUID* LogonId, uint32 SupplementalCredSize, void* SupplementalCreds, BOOLEAN Synchronous);

public function HANDLE PLSA_CREATE_THREAD(SECURITY_ATTRIBUTES* SecurityAttributes, uint32 StackSize, LPTHREAD_START_ROUTINE StartFunction, void* ThreadParameter, uint32 CreationFlags, uint32* ThreadId);

public function NTSTATUS PLSA_GET_CLIENT_INFO(SECPKG_CLIENT_INFO* ClientInfo);

public function HANDLE PLSA_REGISTER_NOTIFICATION(LPTHREAD_START_ROUTINE StartFunction, void* Parameter, uint32 NotificationType, uint32 NotificationClass, uint32 NotificationFlags, uint32 IntervalMinutes, HANDLE WaitEvent);

public function NTSTATUS PLSA_CANCEL_NOTIFICATION(HANDLE NotifyHandle);

public function NTSTATUS PLSA_MAP_BUFFER(SecBuffer* InputBuffer, SecBuffer* OutputBuffer);

public function NTSTATUS PLSA_CREATE_TOKEN(LUID* LogonId, TOKEN_SOURCE* TokenSource, SECURITY_LOGON_TYPE LogonType, SECURITY_IMPERSONATION_LEVEL ImpersonationLevel, LSA_TOKEN_INFORMATION_TYPE TokenInformationType, void* TokenInformation, TOKEN_GROUPS* TokenGroups, UNICODE_STRING* AccountName, UNICODE_STRING* AuthorityName, UNICODE_STRING* Workstation, UNICODE_STRING* ProfilePath, HANDLE* Token, int32* SubStatus);

public function NTSTATUS PLSA_CREATE_TOKEN_EX(LUID* LogonId, TOKEN_SOURCE* TokenSource, SECURITY_LOGON_TYPE LogonType, SECURITY_IMPERSONATION_LEVEL ImpersonationLevel, LSA_TOKEN_INFORMATION_TYPE TokenInformationType, void* TokenInformation, TOKEN_GROUPS* TokenGroups, UNICODE_STRING* Workstation, UNICODE_STRING* ProfilePath, void* SessionInformation, SECPKG_SESSIONINFO_TYPE SessionInformationType, HANDLE* Token, int32* SubStatus);

public function void PLSA_AUDIT_LOGON(NTSTATUS Status, NTSTATUS SubStatus, UNICODE_STRING* AccountName, UNICODE_STRING* AuthenticatingAuthority, UNICODE_STRING* WorkstationName, PSID UserSid, SECURITY_LOGON_TYPE LogonType, TOKEN_SOURCE* TokenSource, LUID* LogonId);

public function NTSTATUS PLSA_CALL_PACKAGE(UNICODE_STRING* AuthenticationPackage, void* ProtocolSubmitBuffer, uint32 SubmitBufferLength, void** ProtocolReturnBuffer, uint32* ReturnBufferLength, int32* ProtocolStatus);

public function NTSTATUS PLSA_CALL_PACKAGEEX(UNICODE_STRING* AuthenticationPackage, void* ClientBufferBase, void* ProtocolSubmitBuffer, uint32 SubmitBufferLength, void** ProtocolReturnBuffer, uint32* ReturnBufferLength, int32* ProtocolStatus);

public function NTSTATUS PLSA_CALL_PACKAGE_PASSTHROUGH(UNICODE_STRING* AuthenticationPackage, void* ClientBufferBase, void* ProtocolSubmitBuffer, uint32 SubmitBufferLength, void** ProtocolReturnBuffer, uint32* ReturnBufferLength, int32* ProtocolStatus);

public function BOOLEAN PLSA_GET_CALL_INFO(SECPKG_CALL_INFO* Info);

public function void* PLSA_CREATE_SHARED_MEMORY(uint32 MaxSize, uint32 InitialSize);

public function void* PLSA_ALLOCATE_SHARED_MEMORY(void* SharedMem, uint32 Size);

public function void PLSA_FREE_SHARED_MEMORY(void* SharedMem, void* Memory);

public function BOOLEAN PLSA_DELETE_SHARED_MEMORY(void* SharedMem);

public function NTSTATUS PLSA_GET_APP_MODE_INFO(uint32* UserFunction, uint* Argument1, uint* Argument2, SecBuffer* UserData, BOOLEAN* ReturnToLsa);

public function NTSTATUS PLSA_SET_APP_MODE_INFO(uint32 UserFunction, uint Argument1, uint Argument2, SecBuffer* UserData, BOOLEAN ReturnToLsa);

public function NTSTATUS PLSA_OPEN_SAM_USER(UNICODE_STRING* Name, SECPKG_NAME_TYPE NameType, UNICODE_STRING* Prefix, BOOLEAN AllowGuest, uint32 Reserved, void** UserHandle);

public function NTSTATUS PLSA_GET_USER_CREDENTIALS(void* UserHandle, void** PrimaryCreds, uint32* PrimaryCredsSize, void** SupplementalCreds, uint32* SupplementalCredsSize);

public function NTSTATUS PLSA_GET_USER_AUTH_DATA(void* UserHandle, uint8** UserAuthData, uint32* UserAuthDataSize);

public function NTSTATUS PLSA_CLOSE_SAM_USER(void* UserHandle);

public function NTSTATUS PLSA_GET_AUTH_DATA_FOR_USER(UNICODE_STRING* Name, SECPKG_NAME_TYPE NameType, UNICODE_STRING* Prefix, uint8** UserAuthData, uint32* UserAuthDataSize, UNICODE_STRING* UserFlatName);

public function NTSTATUS PLSA_CONVERT_AUTH_DATA_TO_TOKEN(void* UserAuthData, uint32 UserAuthDataSize, SECURITY_IMPERSONATION_LEVEL ImpersonationLevel, TOKEN_SOURCE* TokenSource, SECURITY_LOGON_TYPE LogonType, UNICODE_STRING* AuthorityName, HANDLE* Token, LUID* LogonId, UNICODE_STRING* AccountName, int32* SubStatus);

public function NTSTATUS PLSA_CRACK_SINGLE_NAME(uint32 FormatOffered, BOOLEAN PerformAtGC, UNICODE_STRING* NameInput, UNICODE_STRING* Prefix, uint32 RequestedFormat, UNICODE_STRING* CrackedName, UNICODE_STRING* DnsDomainName, uint32* SubStatus);

public function NTSTATUS PLSA_AUDIT_ACCOUNT_LOGON(uint32 AuditId, BOOLEAN Success, UNICODE_STRING* Source, UNICODE_STRING* ClientName, UNICODE_STRING* MappedName, NTSTATUS Status);

public function NTSTATUS PLSA_CLIENT_CALLBACK(PSTR Callback, uint Argument1, uint Argument2, SecBuffer* Input, SecBuffer* Output);

public function NTSTATUS PLSA_REGISTER_CALLBACK(uint32 CallbackId, PLSA_CALLBACK_FUNCTION Callback);

public function NTSTATUS PLSA_GET_EXTENDED_CALL_FLAGS(uint32* Flags);

public function NTSTATUS PLSA_UPDATE_PRIMARY_CREDENTIALS(SECPKG_PRIMARY_CRED* PrimaryCredentials, SECPKG_SUPPLEMENTAL_CRED_ARRAY* Credentials);

public function void PLSA_PROTECT_MEMORY(void* Buffer, uint32 BufferSize);

public function NTSTATUS PLSA_OPEN_TOKEN_BY_LOGON_ID(LUID* LogonId, HANDLE* RetTokenHandle);

public function NTSTATUS PLSA_EXPAND_AUTH_DATA_FOR_DOMAIN(uint8* UserAuthData, uint32 UserAuthDataSize, void* Reserved, uint8** ExpandedAuthData, uint32* ExpandedAuthDataSize);

public function NTSTATUS PLSA_GET_SERVICE_ACCOUNT_PASSWORD(UNICODE_STRING* AccountName, UNICODE_STRING* DomainName, CRED_FETCH CredFetch, FILETIME* FileTimeExpiry, UNICODE_STRING* CurrentPassword, UNICODE_STRING* PreviousPassword, FILETIME* FileTimeCurrPwdValidForOutbound);

public function void PLSA_AUDIT_LOGON_EX(NTSTATUS Status, NTSTATUS SubStatus, UNICODE_STRING* AccountName, UNICODE_STRING* AuthenticatingAuthority, UNICODE_STRING* WorkstationName, PSID UserSid, SECURITY_LOGON_TYPE LogonType, SECURITY_IMPERSONATION_LEVEL ImpersonationLevel, TOKEN_SOURCE* TokenSource, LUID* LogonId);

public function NTSTATUS PLSA_CHECK_PROTECTED_USER_BY_TOKEN(HANDLE UserToken, BOOLEAN* ProtectedUser);

public function NTSTATUS PLSA_QUERY_CLIENT_REQUEST(void** ClientRequest, uint32 QueryType, void** ReplyBuffer);

public function NTSTATUS CredReadFn(LUID* LogonId, uint32 CredFlags, PWSTR TargetName, uint32 Type, uint32 Flags, ENCRYPTED_CREDENTIALW** Credential);

public function NTSTATUS CredReadDomainCredentialsFn(LUID* LogonId, uint32 CredFlags, CREDENTIAL_TARGET_INFORMATIONW* TargetInfo, uint32 Flags, uint32* Count, ENCRYPTED_CREDENTIALW*** Credential);

public function void CredFreeCredentialsFn(uint32 Count, ENCRYPTED_CREDENTIALW** Credentials);

public function NTSTATUS CredWriteFn(LUID* LogonId, uint32 CredFlags, ENCRYPTED_CREDENTIALW* Credential, uint32 Flags);

public function NTSTATUS CrediUnmarshalandDecodeStringFn(PWSTR MarshaledString, uint8** Blob, uint32* BlobSize, uint8* IsFailureFatal);

public function void* PLSA_LOCATE_PKG_BY_ID(uint32 PackgeId);

public function NTSTATUS SpInitializeFn(uint PackageId, SECPKG_PARAMETERS* Parameters, LSA_SECPKG_FUNCTION_TABLE* FunctionTable);

public function NTSTATUS SpShutdownFn();

public function NTSTATUS SpGetInfoFn(SecPkgInfoA* PackageInfo);

public function NTSTATUS SpGetExtendedInformationFn(SECPKG_EXTENDED_INFORMATION_CLASS Class, SECPKG_EXTENDED_INFORMATION** ppInformation);

public function NTSTATUS SpSetExtendedInformationFn(SECPKG_EXTENDED_INFORMATION_CLASS Class, SECPKG_EXTENDED_INFORMATION* Info);

public function NTSTATUS PLSA_AP_LOGON_USER_EX2(void** ClientRequest, SECURITY_LOGON_TYPE LogonType, void* ProtocolSubmitBuffer, void* ClientBufferBase, uint32 SubmitBufferSize, void** ProfileBuffer, uint32* ProfileBufferSize, LUID* LogonId, int32* SubStatus, LSA_TOKEN_INFORMATION_TYPE* TokenInformationType, void** TokenInformation, UNICODE_STRING** AccountName, UNICODE_STRING** AuthenticatingAuthority, UNICODE_STRING** MachineName, SECPKG_PRIMARY_CRED* PrimaryCredentials, SECPKG_SUPPLEMENTAL_CRED_ARRAY** SupplementalCredentials);

public function NTSTATUS PLSA_AP_LOGON_USER_EX3(void** ClientRequest, SECURITY_LOGON_TYPE LogonType, void* ProtocolSubmitBuffer, void* ClientBufferBase, uint32 SubmitBufferSize, SECPKG_SURROGATE_LOGON* SurrogateLogon, void** ProfileBuffer, uint32* ProfileBufferSize, LUID* LogonId, int32* SubStatus, LSA_TOKEN_INFORMATION_TYPE* TokenInformationType, void** TokenInformation, UNICODE_STRING** AccountName, UNICODE_STRING** AuthenticatingAuthority, UNICODE_STRING** MachineName, SECPKG_PRIMARY_CRED* PrimaryCredentials, SECPKG_SUPPLEMENTAL_CRED_ARRAY** SupplementalCredentials);

public function NTSTATUS PLSA_AP_PRE_LOGON_USER_SURROGATE(void** ClientRequest, SECURITY_LOGON_TYPE LogonType, void* ProtocolSubmitBuffer, void* ClientBufferBase, uint32 SubmitBufferSize, SECPKG_SURROGATE_LOGON* SurrogateLogon, int32* SubStatus);

public function NTSTATUS PLSA_AP_POST_LOGON_USER_SURROGATE(void** ClientRequest, SECURITY_LOGON_TYPE LogonType, void* ProtocolSubmitBuffer, void* ClientBufferBase, uint32 SubmitBufferSize, SECPKG_SURROGATE_LOGON* SurrogateLogon, void* ProfileBuffer, uint32 ProfileBufferSize, LUID* LogonId, NTSTATUS Status, NTSTATUS SubStatus, LSA_TOKEN_INFORMATION_TYPE TokenInformationType, void* TokenInformation, UNICODE_STRING* AccountName, UNICODE_STRING* AuthenticatingAuthority, UNICODE_STRING* MachineName, SECPKG_PRIMARY_CRED* PrimaryCredentials, SECPKG_SUPPLEMENTAL_CRED_ARRAY* SupplementalCredentials);

public function NTSTATUS SpAcceptCredentialsFn(SECURITY_LOGON_TYPE LogonType, UNICODE_STRING* AccountName, SECPKG_PRIMARY_CRED* PrimaryCredentials, SECPKG_SUPPLEMENTAL_CRED* SupplementalCredentials);

public function NTSTATUS SpAcquireCredentialsHandleFn(UNICODE_STRING* PrincipalName, uint32 CredentialUseFlags, LUID* LogonId, void* AuthorizationData, void* GetKeyFunciton, void* GetKeyArgument, uint* CredentialHandle, LARGE_INTEGER* ExpirationTime);

public function NTSTATUS SpFreeCredentialsHandleFn(uint CredentialHandle);

public function NTSTATUS SpQueryCredentialsAttributesFn(uint CredentialHandle, uint32 CredentialAttribute, void* Buffer);

public function NTSTATUS SpSetCredentialsAttributesFn(uint CredentialHandle, uint32 CredentialAttribute, void* Buffer, uint32 BufferSize);

public function NTSTATUS SpAddCredentialsFn(uint CredentialHandle, UNICODE_STRING* PrincipalName, UNICODE_STRING* Package, uint32 CredentialUseFlags, void* AuthorizationData, void* GetKeyFunciton, void* GetKeyArgument, LARGE_INTEGER* ExpirationTime);

public function NTSTATUS SpSaveCredentialsFn(uint CredentialHandle, SecBuffer* Credentials);

public function NTSTATUS SpGetCredentialsFn(uint CredentialHandle, SecBuffer* Credentials);

public function NTSTATUS SpDeleteCredentialsFn(uint CredentialHandle, SecBuffer* Key);

public function NTSTATUS SpInitLsaModeContextFn(uint CredentialHandle, uint ContextHandle, UNICODE_STRING* TargetName, uint32 ContextRequirements, uint32 TargetDataRep, SecBufferDesc* InputBuffers, uint* NewContextHandle, SecBufferDesc* OutputBuffers, uint32* ContextAttributes, LARGE_INTEGER* ExpirationTime, BOOLEAN* MappedContext, SecBuffer* ContextData);

public function NTSTATUS SpDeleteContextFn(uint ContextHandle);

public function NTSTATUS SpApplyControlTokenFn(uint ContextHandle, SecBufferDesc* ControlToken);

public function NTSTATUS SpAcceptLsaModeContextFn(uint CredentialHandle, uint ContextHandle, SecBufferDesc* InputBuffer, uint32 ContextRequirements, uint32 TargetDataRep, uint* NewContextHandle, SecBufferDesc* OutputBuffer, uint32* ContextAttributes, LARGE_INTEGER* ExpirationTime, BOOLEAN* MappedContext, SecBuffer* ContextData);

public function NTSTATUS SpGetUserInfoFn(LUID* LogonId, uint32 Flags, SECURITY_USER_DATA** UserData);

public function NTSTATUS SpQueryContextAttributesFn(uint ContextHandle, uint32 ContextAttribute, void* Buffer);

public function NTSTATUS SpSetContextAttributesFn(uint ContextHandle, uint32 ContextAttribute, void* Buffer, uint32 BufferSize);

public function NTSTATUS SpChangeAccountPasswordFn(UNICODE_STRING* pDomainName, UNICODE_STRING* pAccountName, UNICODE_STRING* pOldPassword, UNICODE_STRING* pNewPassword, BOOLEAN Impersonating, SecBufferDesc* pOutput);

public function NTSTATUS SpQueryMetaDataFn(uint CredentialHandle, UNICODE_STRING* TargetName, uint32 ContextRequirements, uint32* MetaDataLength, uint8** MetaData, uint* ContextHandle);

public function NTSTATUS SpExchangeMetaDataFn(uint CredentialHandle, UNICODE_STRING* TargetName, uint32 ContextRequirements, uint32 MetaDataLength, uint8* MetaData, uint* ContextHandle);

public function NTSTATUS SpGetCredUIContextFn(uint ContextHandle, Guid* CredType, uint32* FlatCredUIContextLength, uint8** FlatCredUIContext);

public function NTSTATUS SpUpdateCredentialsFn(uint ContextHandle, Guid* CredType, uint32 FlatCredUIContextLength, uint8* FlatCredUIContext);

public function NTSTATUS SpValidateTargetInfoFn(void** ClientRequest, void* ProtocolSubmitBuffer, void* ClientBufferBase, uint32 SubmitBufferLength, SECPKG_TARGETINFO* TargetInfo);

public function NTSTATUS LSA_AP_POST_LOGON_USER(SECPKG_POST_LOGON_USER_INFO* PostLogonUserInfo);

public function NTSTATUS SpGetRemoteCredGuardLogonBufferFn(uint CredHandle, uint ContextHandle, UNICODE_STRING* TargetName, HANDLE* RedirectedLogonHandle, PLSA_REDIRECTED_LOGON_CALLBACK* Callback, PLSA_REDIRECTED_LOGON_CLEANUP_CALLBACK* CleanupCallback, uint32* LogonBufferSize, void** LogonBuffer);

public function NTSTATUS SpGetRemoteCredGuardSupplementalCredsFn(uint CredHandle, UNICODE_STRING* TargetName, HANDLE* RedirectedLogonHandle, PLSA_REDIRECTED_LOGON_CALLBACK* Callback, PLSA_REDIRECTED_LOGON_CLEANUP_CALLBACK* CleanupCallback, uint32* SupplementalCredsSize, void** SupplementalCreds);

public function NTSTATUS SpGetTbalSupplementalCredsFn(LUID LogonId, uint32* SupplementalCredsSize, void** SupplementalCreds);

public function NTSTATUS SpInstanceInitFn(uint32 Version, SECPKG_DLL_FUNCTIONS* FunctionTable, void** UserFunctions);

public function NTSTATUS SpInitUserModeContextFn(uint ContextHandle, SecBuffer* PackedContext);

public function NTSTATUS SpMakeSignatureFn(uint ContextHandle, uint32 QualityOfProtection, SecBufferDesc* MessageBuffers, uint32 MessageSequenceNumber);

public function NTSTATUS SpVerifySignatureFn(uint ContextHandle, SecBufferDesc* MessageBuffers, uint32 MessageSequenceNumber, uint32* QualityOfProtection);

public function NTSTATUS SpSealMessageFn(uint ContextHandle, uint32 QualityOfProtection, SecBufferDesc* MessageBuffers, uint32 MessageSequenceNumber);

public function NTSTATUS SpUnsealMessageFn(uint ContextHandle, SecBufferDesc* MessageBuffers, uint32 MessageSequenceNumber, uint32* QualityOfProtection);

public function NTSTATUS SpGetContextTokenFn(uint ContextHandle, HANDLE* ImpersonationToken);

public function NTSTATUS SpExportSecurityContextFn(uint phContext, uint32 fFlags, SecBuffer* pPackedContext, HANDLE* pToken);

public function NTSTATUS SpImportSecurityContextFn(SecBuffer* pPackedContext, HANDLE Token, uint* phContext);

public function NTSTATUS SpCompleteAuthTokenFn(uint ContextHandle, SecBufferDesc* InputBuffer);

public function NTSTATUS SpFormatCredentialsFn(SecBuffer* Credentials, SecBuffer* FormattedCredentials);

public function NTSTATUS SpMarshallSupplementalCredsFn(uint32 CredentialSize, uint8* Credentials, uint32* MarshalledCredSize, void** MarshalledCreds);

public function NTSTATUS SpMarshalAttributeDataFn(uint32 AttributeInfo, uint32 Attribute, uint32 AttributeDataSize, uint8* AttributeData, uint32* MarshaledAttributeDataSize, uint8** MarshaledAttributeData);

public function NTSTATUS SpLsaModeInitializeFn(uint32 LsaVersion, uint32* PackageVersion, SECPKG_FUNCTION_TABLE** ppTables, uint32* pcTables);

public function NTSTATUS SpUserModeInitializeFn(uint32 LsaVersion, uint32* PackageVersion, SECPKG_USER_FUNCTION_TABLE** ppTables, uint32* pcTables);

public function void* PKSEC_CREATE_CONTEXT_LIST(KSEC_CONTEXT_TYPE Type);

public function void PKSEC_INSERT_LIST_ENTRY(void* List, KSEC_LIST_ENTRY* Entry);

public function NTSTATUS PKSEC_REFERENCE_LIST_ENTRY(KSEC_LIST_ENTRY* Entry, uint32 Signature, BOOLEAN RemoveNoRef);

public function void PKSEC_DEREFERENCE_LIST_ENTRY(KSEC_LIST_ENTRY* Entry, uint8* Delete);

public function NTSTATUS PKSEC_SERIALIZE_WINNT_AUTH_DATA(void* pvAuthData, uint32* Size, void** SerializedData);

public function NTSTATUS PKSEC_SERIALIZE_SCHANNEL_AUTH_DATA(void* pvAuthData, uint32* Size, void** SerializedData);

public function void* PKSEC_LOCATE_PKG_BY_ID(uint32 PackageId);

public function NTSTATUS KspInitPackageFn(SECPKG_KERNEL_FUNCTIONS* FunctionTable);

public function NTSTATUS KspDeleteContextFn(uint ContextId, uint* LsaContextId);

public function NTSTATUS KspInitContextFn(uint ContextId, SecBuffer* ContextData, uint* NewContextId);

public function NTSTATUS KspMakeSignatureFn(uint ContextId, uint32 fQOP, SecBufferDesc* Message, uint32 MessageSeqNo);

public function NTSTATUS KspVerifySignatureFn(uint ContextId, SecBufferDesc* Message, uint32 MessageSeqNo, uint32* pfQOP);

public function NTSTATUS KspSealMessageFn(uint ContextId, uint32 fQOP, SecBufferDesc* Message, uint32 MessageSeqNo);

public function NTSTATUS KspUnsealMessageFn(uint ContextId, SecBufferDesc* Message, uint32 MessageSeqNo, uint32* pfQOP);

public function NTSTATUS KspGetTokenFn(uint ContextId, HANDLE* ImpersonationToken, void** RawToken);

public function NTSTATUS KspQueryAttributesFn(uint ContextId, uint32 Attribute, void* Buffer);

public function NTSTATUS KspCompleteTokenFn(uint ContextId, SecBufferDesc* Token);

public function NTSTATUS KspMapHandleFn(uint ContextId, uint* LsaContextId);

public function NTSTATUS KspSetPagingModeFn(BOOLEAN PagingMode);

public function NTSTATUS KspSerializeAuthDataFn(void* pvAuthData, uint32* Size, void** SerializedData);

public function BOOL SSL_EMPTY_CACHE_FN_A(PSTR pszTargetName, uint32 dwFlags);

public function BOOL SSL_EMPTY_CACHE_FN_W(PWSTR pszTargetName, uint32 dwFlags);

public function BOOL SSL_CRACK_CERTIFICATE_FN(uint8* pbCertificate, uint32 cbCertificate, BOOL VerifySignature, X509Certificate** ppCertificate);

public function void SSL_FREE_CERTIFICATE_FN(X509Certificate* pCertificate);

public function HRESULT SslGetServerIdentityFn(uint8* ClientHello, uint32 ClientHelloSize, uint8** ServerIdentity, uint32* ServerIdentitySize, uint32 Flags);

public function HRESULT SslGetExtensionsFn(uint8* clientHello, uint32 clientHelloByteSize, SCH_EXTENSION_DATA* genericExtensions, uint8 genericExtensionsCount, uint32* bytesToRead, SchGetExtensionsOptions flags);

#endregion

#region Structs
[CRepr]
public struct LSA_TRUST_INFORMATION
{
	public UNICODE_STRING Name;
	public PSID Sid;
}

[CRepr]
public struct LSA_REFERENCED_DOMAIN_LIST
{
	public uint32 Entries;
	public LSA_TRUST_INFORMATION* Domains;
}

[CRepr]
public struct LSA_TRANSLATED_SID2
{
	public SID_NAME_USE Use;
	public PSID Sid;
	public int32 DomainIndex;
	public uint32 Flags;
}

[CRepr]
public struct LSA_TRANSLATED_NAME
{
	public SID_NAME_USE Use;
	public UNICODE_STRING Name;
	public int32 DomainIndex;
}

[CRepr]
public struct POLICY_ACCOUNT_DOMAIN_INFO
{
	public UNICODE_STRING DomainName;
	public PSID DomainSid;
}

[CRepr]
public struct POLICY_DNS_DOMAIN_INFO
{
	public UNICODE_STRING Name;
	public UNICODE_STRING DnsDomainName;
	public UNICODE_STRING DnsForestName;
	public Guid DomainGuid;
	public PSID Sid;
}

[CRepr]
public struct SE_ADT_OBJECT_TYPE
{
	public Guid ObjectType;
	public uint16 Flags;
	public uint16 Level;
	public uint32 AccessMask;
}

[CRepr]
public struct SE_ADT_PARAMETER_ARRAY_ENTRY
{
	public SE_ADT_PARAMETER_TYPE Type;
	public uint32 Length;
	public uint[2] Data;
	public void* Address;
}

[CRepr]
public struct SE_ADT_ACCESS_REASON
{
	public uint32 AccessMask;
	public uint32[32] AccessReasons;
	public uint32 ObjectTypeIndex;
	public uint32 AccessGranted;
	public PSECURITY_DESCRIPTOR SecurityDescriptor;
}

[CRepr]
public struct SE_ADT_CLAIMS
{
	public uint32 Length;
	public void* Claims;
}

[CRepr]
public struct SE_ADT_PARAMETER_ARRAY
{
	public uint32 CategoryId;
	public uint32 AuditId;
	public uint32 ParameterCount;
	public uint32 Length;
	public uint16 FlatSubCategoryId;
	public uint16 Type;
	public uint32 Flags;
	public SE_ADT_PARAMETER_ARRAY_ENTRY[32] Parameters;
}

[CRepr]
public struct SE_ADT_PARAMETER_ARRAY_EX
{
	public uint32 CategoryId;
	public uint32 AuditId;
	public uint32 Version;
	public uint32 ParameterCount;
	public uint32 Length;
	public uint16 FlatSubCategoryId;
	public uint16 Type;
	public uint32 Flags;
	public SE_ADT_PARAMETER_ARRAY_ENTRY[32] Parameters;
}

[CRepr]
public struct LSA_TRANSLATED_SID
{
	public SID_NAME_USE Use;
	public uint32 RelativeId;
	public int32 DomainIndex;
}

[CRepr]
public struct POLICY_AUDIT_LOG_INFO
{
	public uint32 AuditLogPercentFull;
	public uint32 MaximumLogSize;
	public LARGE_INTEGER AuditRetentionPeriod;
	public BOOLEAN AuditLogFullShutdownInProgress;
	public LARGE_INTEGER TimeToShutdown;
	public uint32 NextAuditRecordId;
}

[CRepr]
public struct POLICY_AUDIT_EVENTS_INFO
{
	public BOOLEAN AuditingMode;
	public uint32* EventAuditingOptions;
	public uint32 MaximumAuditEventCount;
}

[CRepr]
public struct POLICY_AUDIT_SUBCATEGORIES_INFO
{
	public uint32 MaximumSubCategoryCount;
	public uint32* EventAuditingOptions;
}

[CRepr]
public struct POLICY_AUDIT_CATEGORIES_INFO
{
	public uint32 MaximumCategoryCount;
	public POLICY_AUDIT_SUBCATEGORIES_INFO* SubCategoriesInfo;
}

[CRepr]
public struct POLICY_PRIMARY_DOMAIN_INFO
{
	public UNICODE_STRING Name;
	public PSID Sid;
}

[CRepr]
public struct POLICY_PD_ACCOUNT_INFO
{
	public UNICODE_STRING Name;
}

[CRepr]
public struct POLICY_LSA_SERVER_ROLE_INFO
{
	public POLICY_LSA_SERVER_ROLE LsaServerRole;
}

[CRepr]
public struct POLICY_REPLICA_SOURCE_INFO
{
	public UNICODE_STRING ReplicaSource;
	public UNICODE_STRING ReplicaAccountName;
}

[CRepr]
public struct POLICY_DEFAULT_QUOTA_INFO
{
	public QUOTA_LIMITS QuotaLimits;
}

[CRepr]
public struct POLICY_MODIFICATION_INFO
{
	public LARGE_INTEGER ModifiedId;
	public LARGE_INTEGER DatabaseCreationTime;
}

[CRepr]
public struct POLICY_AUDIT_FULL_SET_INFO
{
	public BOOLEAN ShutDownOnFull;
}

[CRepr]
public struct POLICY_AUDIT_FULL_QUERY_INFO
{
	public BOOLEAN ShutDownOnFull;
	public BOOLEAN LogIsFull;
}

[CRepr]
public struct POLICY_DOMAIN_EFS_INFO
{
	public uint32 InfoLength;
	public uint8* EfsBlob;
}

[CRepr]
public struct POLICY_DOMAIN_KERBEROS_TICKET_INFO
{
	public uint32 AuthenticationOptions;
	public LARGE_INTEGER MaxServiceTicketAge;
	public LARGE_INTEGER MaxTicketAge;
	public LARGE_INTEGER MaxRenewAge;
	public LARGE_INTEGER MaxClockSkew;
	public LARGE_INTEGER Reserved;
}

[CRepr]
public struct POLICY_MACHINE_ACCT_INFO
{
	public uint32 Rid;
	public PSID Sid;
}

[CRepr]
public struct TRUSTED_DOMAIN_NAME_INFO
{
	public UNICODE_STRING Name;
}

[CRepr]
public struct TRUSTED_CONTROLLERS_INFO
{
	public uint32 Entries;
	public UNICODE_STRING* Names;
}

[CRepr]
public struct TRUSTED_POSIX_OFFSET_INFO
{
	public uint32 Offset;
}

[CRepr]
public struct TRUSTED_PASSWORD_INFO
{
	public UNICODE_STRING Password;
	public UNICODE_STRING OldPassword;
}

[CRepr]
public struct TRUSTED_DOMAIN_INFORMATION_EX
{
	public UNICODE_STRING Name;
	public UNICODE_STRING FlatName;
	public PSID Sid;
	public TRUSTED_DOMAIN_TRUST_DIRECTION TrustDirection;
	public TRUSTED_DOMAIN_TRUST_TYPE TrustType;
	public TRUSTED_DOMAIN_TRUST_ATTRIBUTES TrustAttributes;
}

[CRepr]
public struct TRUSTED_DOMAIN_INFORMATION_EX2
{
	public UNICODE_STRING Name;
	public UNICODE_STRING FlatName;
	public PSID Sid;
	public uint32 TrustDirection;
	public uint32 TrustType;
	public uint32 TrustAttributes;
	public uint32 ForestTrustLength;
	public uint8* ForestTrustInfo;
}

[CRepr]
public struct LSA_AUTH_INFORMATION
{
	public LARGE_INTEGER LastUpdateTime;
	public LSA_AUTH_INFORMATION_AUTH_TYPE AuthType;
	public uint32 AuthInfoLength;
	public uint8* AuthInfo;
}

[CRepr]
public struct TRUSTED_DOMAIN_AUTH_INFORMATION
{
	public uint32 IncomingAuthInfos;
	public LSA_AUTH_INFORMATION* IncomingAuthenticationInformation;
	public LSA_AUTH_INFORMATION* IncomingPreviousAuthenticationInformation;
	public uint32 OutgoingAuthInfos;
	public LSA_AUTH_INFORMATION* OutgoingAuthenticationInformation;
	public LSA_AUTH_INFORMATION* OutgoingPreviousAuthenticationInformation;
}

[CRepr]
public struct TRUSTED_DOMAIN_FULL_INFORMATION
{
	public TRUSTED_DOMAIN_INFORMATION_EX Information;
	public TRUSTED_POSIX_OFFSET_INFO PosixOffset;
	public TRUSTED_DOMAIN_AUTH_INFORMATION AuthInformation;
}

[CRepr]
public struct TRUSTED_DOMAIN_FULL_INFORMATION2
{
	public TRUSTED_DOMAIN_INFORMATION_EX2 Information;
	public TRUSTED_POSIX_OFFSET_INFO PosixOffset;
	public TRUSTED_DOMAIN_AUTH_INFORMATION AuthInformation;
}

[CRepr]
public struct TRUSTED_DOMAIN_SUPPORTED_ENCRYPTION_TYPES
{
	public uint32 SupportedEncryptionTypes;
}

[CRepr]
public struct LSA_FOREST_TRUST_DOMAIN_INFO
{
	public PSID Sid;
	public UNICODE_STRING DnsName;
	public UNICODE_STRING NetbiosName;
}

[CRepr]
public struct LSA_FOREST_TRUST_BINARY_DATA
{
	public uint32 Length;
	public uint8* Buffer;
}

[CRepr]
public struct LSA_FOREST_TRUST_RECORD
{
	[CRepr, Union]
	public struct _ForestTrustData_e__Union
	{
		public UNICODE_STRING TopLevelName;
		public LSA_FOREST_TRUST_DOMAIN_INFO DomainInfo;
		public LSA_FOREST_TRUST_BINARY_DATA Data;
	}
	public uint32 Flags;
	public LSA_FOREST_TRUST_RECORD_TYPE ForestTrustType;
	public LARGE_INTEGER Time;
	public _ForestTrustData_e__Union ForestTrustData;
}

[CRepr]
public struct LSA_FOREST_TRUST_INFORMATION
{
	public uint32 RecordCount;
	public LSA_FOREST_TRUST_RECORD** Entries;
}

[CRepr]
public struct LSA_FOREST_TRUST_COLLISION_RECORD
{
	public uint32 Index;
	public LSA_FOREST_TRUST_COLLISION_RECORD_TYPE Type;
	public uint32 Flags;
	public UNICODE_STRING Name;
}

[CRepr]
public struct LSA_FOREST_TRUST_COLLISION_INFORMATION
{
	public uint32 RecordCount;
	public LSA_FOREST_TRUST_COLLISION_RECORD** Entries;
}

[CRepr]
public struct LSA_ENUMERATION_INFORMATION
{
	public PSID Sid;
}

[CRepr]
public struct LSA_LAST_INTER_LOGON_INFO
{
	public LARGE_INTEGER LastSuccessfulLogon;
	public LARGE_INTEGER LastFailedLogon;
	public uint32 FailedAttemptCountSinceLastSuccessfulLogon;
}

[CRepr]
public struct SECURITY_LOGON_SESSION_DATA
{
	public uint32 Size;
	public LUID LogonId;
	public UNICODE_STRING UserName;
	public UNICODE_STRING LogonDomain;
	public UNICODE_STRING AuthenticationPackage;
	public uint32 LogonType;
	public uint32 Session;
	public PSID Sid;
	public LARGE_INTEGER LogonTime;
	public UNICODE_STRING LogonServer;
	public UNICODE_STRING DnsDomainName;
	public UNICODE_STRING Upn;
	public uint32 UserFlags;
	public LSA_LAST_INTER_LOGON_INFO LastLogonInfo;
	public UNICODE_STRING LogonScript;
	public UNICODE_STRING ProfilePath;
	public UNICODE_STRING HomeDirectory;
	public UNICODE_STRING HomeDirectoryDrive;
	public LARGE_INTEGER LogoffTime;
	public LARGE_INTEGER KickOffTime;
	public LARGE_INTEGER PasswordLastSet;
	public LARGE_INTEGER PasswordCanChange;
	public LARGE_INTEGER PasswordMustChange;
}

[CRepr]
public struct CENTRAL_ACCESS_POLICY_ENTRY
{
	public UNICODE_STRING Name;
	public UNICODE_STRING Description;
	public UNICODE_STRING ChangeId;
	public uint32 LengthAppliesTo;
	public uint8* AppliesTo;
	public uint32 LengthSD;
	public PSECURITY_DESCRIPTOR SD;
	public uint32 LengthStagedSD;
	public PSECURITY_DESCRIPTOR StagedSD;
	public uint32 Flags;
}

[CRepr]
public struct CENTRAL_ACCESS_POLICY
{
	public PSID CAPID;
	public UNICODE_STRING Name;
	public UNICODE_STRING Description;
	public UNICODE_STRING ChangeId;
	public uint32 Flags;
	public uint32 CAPECount;
	public CENTRAL_ACCESS_POLICY_ENTRY** CAPEs;
}

[CRepr]
public struct NEGOTIATE_PACKAGE_PREFIX
{
	public uint PackageId;
	public void* PackageDataA;
	public void* PackageDataW;
	public uint PrefixLen;
	public uint8[32] Prefix;
}

[CRepr]
public struct NEGOTIATE_PACKAGE_PREFIXES
{
	public uint32 MessageType;
	public uint32 PrefixCount;
	public uint32 Offset;
	public uint32 Pad;
}

[CRepr]
public struct NEGOTIATE_CALLER_NAME_REQUEST
{
	public uint32 MessageType;
	public LUID LogonId;
}

[CRepr]
public struct NEGOTIATE_CALLER_NAME_RESPONSE
{
	public uint32 MessageType;
	public PWSTR CallerName;
}

[CRepr]
public struct DOMAIN_PASSWORD_INFORMATION
{
	public uint16 MinPasswordLength;
	public uint16 PasswordHistoryLength;
	public DOMAIN_PASSWORD_PROPERTIES PasswordProperties;
	public LARGE_INTEGER MaxPasswordAge;
	public LARGE_INTEGER MinPasswordAge;
}

[CRepr]
public struct MSV1_0_INTERACTIVE_LOGON
{
	public MSV1_0_LOGON_SUBMIT_TYPE MessageType;
	public UNICODE_STRING LogonDomainName;
	public UNICODE_STRING UserName;
	public UNICODE_STRING Password;
}

[CRepr]
public struct MSV1_0_INTERACTIVE_PROFILE
{
	public MSV1_0_PROFILE_BUFFER_TYPE MessageType;
	public uint16 LogonCount;
	public uint16 BadPasswordCount;
	public LARGE_INTEGER LogonTime;
	public LARGE_INTEGER LogoffTime;
	public LARGE_INTEGER KickOffTime;
	public LARGE_INTEGER PasswordLastSet;
	public LARGE_INTEGER PasswordCanChange;
	public LARGE_INTEGER PasswordMustChange;
	public UNICODE_STRING LogonScript;
	public UNICODE_STRING HomeDirectory;
	public UNICODE_STRING FullName;
	public UNICODE_STRING ProfilePath;
	public UNICODE_STRING HomeDirectoryDrive;
	public UNICODE_STRING LogonServer;
	public uint32 UserFlags;
}

[CRepr]
public struct MSV1_0_LM20_LOGON
{
	public MSV1_0_LOGON_SUBMIT_TYPE MessageType;
	public UNICODE_STRING LogonDomainName;
	public UNICODE_STRING UserName;
	public UNICODE_STRING Workstation;
	public uint8[8] ChallengeToClient;
	public STRING CaseSensitiveChallengeResponse;
	public STRING CaseInsensitiveChallengeResponse;
	public uint32 ParameterControl;
}

[CRepr]
public struct MSV1_0_SUBAUTH_LOGON
{
	public MSV1_0_LOGON_SUBMIT_TYPE MessageType;
	public UNICODE_STRING LogonDomainName;
	public UNICODE_STRING UserName;
	public UNICODE_STRING Workstation;
	public uint8[8] ChallengeToClient;
	public STRING AuthenticationInfo1;
	public STRING AuthenticationInfo2;
	public MSV_SUBAUTH_LOGON_PARAMETER_CONTROL ParameterControl;
	public uint32 SubAuthPackageId;
}

[CRepr]
public struct MSV1_0_S4U_LOGON
{
	public MSV1_0_LOGON_SUBMIT_TYPE MessageType;
	public uint32 Flags;
	public UNICODE_STRING UserPrincipalName;
	public UNICODE_STRING DomainName;
}

[CRepr]
public struct MSV1_0_LM20_LOGON_PROFILE
{
	public MSV1_0_PROFILE_BUFFER_TYPE MessageType;
	public LARGE_INTEGER KickOffTime;
	public LARGE_INTEGER LogoffTime;
	public MSV_SUB_AUTHENTICATION_FILTER UserFlags;
	public uint8[16] UserSessionKey;
	public UNICODE_STRING LogonDomainName;
	public uint8[8] LanmanSessionKey;
	public UNICODE_STRING LogonServer;
	public UNICODE_STRING UserParameters;
}

[CRepr]
public struct MSV1_0_CREDENTIAL_KEY
{
	public uint8[20] Data;
}

[CRepr]
public struct MSV1_0_SUPPLEMENTAL_CREDENTIAL
{
	public uint32 Version;
	public MSV_SUPPLEMENTAL_CREDENTIAL_FLAGS Flags;
	public uint8[16] LmPassword;
	public uint8[16] NtPassword;
}

[CRepr]
public struct MSV1_0_SUPPLEMENTAL_CREDENTIAL_V2
{
	public uint32 Version;
	public uint32 Flags;
	public uint8[16] NtPassword;
	public MSV1_0_CREDENTIAL_KEY CredentialKey;
}

[CRepr]
public struct MSV1_0_SUPPLEMENTAL_CREDENTIAL_V3
{
	public uint32 Version;
	public uint32 Flags;
	public MSV1_0_CREDENTIAL_KEY_TYPE CredentialKeyType;
	public uint8[16] NtPassword;
	public MSV1_0_CREDENTIAL_KEY CredentialKey;
	public uint8[20] ShaPassword;
}

[CRepr]
public struct MSV1_0_IUM_SUPPLEMENTAL_CREDENTIAL
{
	public uint32 Version;
	public uint32 EncryptedCredsSize;
	public uint8* EncryptedCreds mut => &EncryptedCreds_impl;
	private uint8[ANYSIZE_ARRAY] EncryptedCreds_impl;
}

[CRepr, Packed(1)]
public struct MSV1_0_REMOTE_SUPPLEMENTAL_CREDENTIAL
{
	public uint32 Version;
	public uint32 Flags;
	public MSV1_0_CREDENTIAL_KEY CredentialKey;
	public MSV1_0_CREDENTIAL_KEY_TYPE CredentialKeyType;
	public uint32 EncryptedCredsSize;
	public uint8* EncryptedCreds mut => &EncryptedCreds_impl;
	private uint8[ANYSIZE_ARRAY] EncryptedCreds_impl;
}

[CRepr]
public struct MSV1_0_NTLM3_RESPONSE
{
	public uint8[16] Response;
	public uint8 RespType;
	public uint8 HiRespType;
	public uint16 Flags;
	public uint32 MsgWord;
	public uint64 TimeStamp;
	public uint8[8] ChallengeFromClient;
	public uint32 AvPairsOff;
	public uint8* Buffer mut => &Buffer_impl;
	private uint8[ANYSIZE_ARRAY] Buffer_impl;
}

[CRepr]
public struct MSV1_0_AV_PAIR
{
	public uint16 AvId;
	public uint16 AvLen;
}

[CRepr]
public struct MSV1_0_CHANGEPASSWORD_REQUEST
{
	public MSV1_0_PROTOCOL_MESSAGE_TYPE MessageType;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING AccountName;
	public UNICODE_STRING OldPassword;
	public UNICODE_STRING NewPassword;
	public BOOLEAN Impersonating;
}

[CRepr]
public struct MSV1_0_CHANGEPASSWORD_RESPONSE
{
	public MSV1_0_PROTOCOL_MESSAGE_TYPE MessageType;
	public BOOLEAN PasswordInfoValid;
	public DOMAIN_PASSWORD_INFORMATION DomainPasswordInfo;
}

[CRepr]
public struct MSV1_0_PASSTHROUGH_REQUEST
{
	public MSV1_0_PROTOCOL_MESSAGE_TYPE MessageType;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING PackageName;
	public uint32 DataLength;
	public uint8* LogonData;
	public uint32 Pad;
}

[CRepr]
public struct MSV1_0_PASSTHROUGH_RESPONSE
{
	public MSV1_0_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 Pad;
	public uint32 DataLength;
	public uint8* ValidationData;
}

[CRepr]
public struct MSV1_0_SUBAUTH_REQUEST
{
	public MSV1_0_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 SubAuthPackageId;
	public uint32 SubAuthInfoLength;
	public uint8* SubAuthSubmitBuffer;
}

[CRepr]
public struct MSV1_0_SUBAUTH_RESPONSE
{
	public MSV1_0_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 SubAuthInfoLength;
	public uint8* SubAuthReturnBuffer;
}

[CRepr]
public struct KERB_INTERACTIVE_LOGON
{
	public KERB_LOGON_SUBMIT_TYPE MessageType;
	public UNICODE_STRING LogonDomainName;
	public UNICODE_STRING UserName;
	public UNICODE_STRING Password;
}

[CRepr]
public struct KERB_INTERACTIVE_UNLOCK_LOGON
{
	public KERB_INTERACTIVE_LOGON Logon;
	public LUID LogonId;
}

[CRepr]
public struct KERB_SMART_CARD_LOGON
{
	public KERB_LOGON_SUBMIT_TYPE MessageType;
	public UNICODE_STRING Pin;
	public uint32 CspDataLength;
	public uint8* CspData;
}

[CRepr]
public struct KERB_SMART_CARD_UNLOCK_LOGON
{
	public KERB_SMART_CARD_LOGON Logon;
	public LUID LogonId;
}

[CRepr]
public struct KERB_CERTIFICATE_LOGON
{
	public KERB_LOGON_SUBMIT_TYPE MessageType;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING UserName;
	public UNICODE_STRING Pin;
	public uint32 Flags;
	public uint32 CspDataLength;
	public uint8* CspData;
}

[CRepr]
public struct KERB_CERTIFICATE_UNLOCK_LOGON
{
	public KERB_CERTIFICATE_LOGON Logon;
	public LUID LogonId;
}

[CRepr]
public struct KERB_CERTIFICATE_S4U_LOGON
{
	public KERB_LOGON_SUBMIT_TYPE MessageType;
	public uint32 Flags;
	public UNICODE_STRING UserPrincipalName;
	public UNICODE_STRING DomainName;
	public uint32 CertificateLength;
	public uint8* Certificate;
}

[CRepr]
public struct KERB_TICKET_LOGON
{
	public KERB_LOGON_SUBMIT_TYPE MessageType;
	public uint32 Flags;
	public uint32 ServiceTicketLength;
	public uint32 TicketGrantingTicketLength;
	public uint8* ServiceTicket;
	public uint8* TicketGrantingTicket;
}

[CRepr]
public struct KERB_TICKET_UNLOCK_LOGON
{
	public KERB_TICKET_LOGON Logon;
	public LUID LogonId;
}

[CRepr]
public struct KERB_S4U_LOGON
{
	public KERB_LOGON_SUBMIT_TYPE MessageType;
	public uint32 Flags;
	public UNICODE_STRING ClientUpn;
	public UNICODE_STRING ClientRealm;
}

[CRepr]
public struct KERB_INTERACTIVE_PROFILE
{
	public KERB_PROFILE_BUFFER_TYPE MessageType;
	public uint16 LogonCount;
	public uint16 BadPasswordCount;
	public LARGE_INTEGER LogonTime;
	public LARGE_INTEGER LogoffTime;
	public LARGE_INTEGER KickOffTime;
	public LARGE_INTEGER PasswordLastSet;
	public LARGE_INTEGER PasswordCanChange;
	public LARGE_INTEGER PasswordMustChange;
	public UNICODE_STRING LogonScript;
	public UNICODE_STRING HomeDirectory;
	public UNICODE_STRING FullName;
	public UNICODE_STRING ProfilePath;
	public UNICODE_STRING HomeDirectoryDrive;
	public UNICODE_STRING LogonServer;
	public uint32 UserFlags;
}

[CRepr]
public struct KERB_SMART_CARD_PROFILE
{
	public KERB_INTERACTIVE_PROFILE Profile;
	public uint32 CertificateSize;
	public uint8* CertificateData;
}

[CRepr]
public struct KERB_CRYPTO_KEY
{
	public KERB_CRYPTO_KEY_TYPE KeyType;
	public uint32 Length;
	public uint8* Value;
}

[CRepr]
public struct KERB_CRYPTO_KEY32
{
	public int32 KeyType;
	public uint32 Length;
	public uint32 Offset;
}

[CRepr]
public struct KERB_TICKET_PROFILE
{
	public KERB_INTERACTIVE_PROFILE Profile;
	public KERB_CRYPTO_KEY SessionKey;
}

[CRepr]
public struct KERB_QUERY_TKT_CACHE_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID LogonId;
}

[CRepr]
public struct KERB_TICKET_CACHE_INFO
{
	public UNICODE_STRING ServerName;
	public UNICODE_STRING RealmName;
	public LARGE_INTEGER StartTime;
	public LARGE_INTEGER EndTime;
	public LARGE_INTEGER RenewTime;
	public int32 EncryptionType;
	public KERB_TICKET_FLAGS TicketFlags;
}

[CRepr]
public struct KERB_TICKET_CACHE_INFO_EX
{
	public UNICODE_STRING ClientName;
	public UNICODE_STRING ClientRealm;
	public UNICODE_STRING ServerName;
	public UNICODE_STRING ServerRealm;
	public LARGE_INTEGER StartTime;
	public LARGE_INTEGER EndTime;
	public LARGE_INTEGER RenewTime;
	public int32 EncryptionType;
	public uint32 TicketFlags;
}

[CRepr]
public struct KERB_TICKET_CACHE_INFO_EX2
{
	public UNICODE_STRING ClientName;
	public UNICODE_STRING ClientRealm;
	public UNICODE_STRING ServerName;
	public UNICODE_STRING ServerRealm;
	public LARGE_INTEGER StartTime;
	public LARGE_INTEGER EndTime;
	public LARGE_INTEGER RenewTime;
	public int32 EncryptionType;
	public uint32 TicketFlags;
	public uint32 SessionKeyType;
	public uint32 BranchId;
}

[CRepr]
public struct KERB_TICKET_CACHE_INFO_EX3
{
	public UNICODE_STRING ClientName;
	public UNICODE_STRING ClientRealm;
	public UNICODE_STRING ServerName;
	public UNICODE_STRING ServerRealm;
	public LARGE_INTEGER StartTime;
	public LARGE_INTEGER EndTime;
	public LARGE_INTEGER RenewTime;
	public int32 EncryptionType;
	public uint32 TicketFlags;
	public uint32 SessionKeyType;
	public uint32 BranchId;
	public uint32 CacheFlags;
	public UNICODE_STRING KdcCalled;
}

[CRepr]
public struct KERB_QUERY_TKT_CACHE_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 CountOfTickets;
	public KERB_TICKET_CACHE_INFO* Tickets mut => &Tickets_impl;
	private KERB_TICKET_CACHE_INFO[ANYSIZE_ARRAY] Tickets_impl;
}

[CRepr]
public struct KERB_QUERY_TKT_CACHE_EX_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 CountOfTickets;
	public KERB_TICKET_CACHE_INFO_EX* Tickets mut => &Tickets_impl;
	private KERB_TICKET_CACHE_INFO_EX[ANYSIZE_ARRAY] Tickets_impl;
}

[CRepr]
public struct KERB_QUERY_TKT_CACHE_EX2_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 CountOfTickets;
	public KERB_TICKET_CACHE_INFO_EX2* Tickets mut => &Tickets_impl;
	private KERB_TICKET_CACHE_INFO_EX2[ANYSIZE_ARRAY] Tickets_impl;
}

[CRepr]
public struct KERB_QUERY_TKT_CACHE_EX3_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 CountOfTickets;
	public KERB_TICKET_CACHE_INFO_EX3* Tickets mut => &Tickets_impl;
	private KERB_TICKET_CACHE_INFO_EX3[ANYSIZE_ARRAY] Tickets_impl;
}

[CRepr]
public struct KERB_AUTH_DATA
{
	public uint32 Type;
	public uint32 Length;
	public uint8* Data;
}

[CRepr]
public struct KERB_NET_ADDRESS
{
	public uint32 Family;
	public uint32 Length;
	public PSTR Address;
}

[CRepr]
public struct KERB_NET_ADDRESSES
{
	public uint32 Number;
	public KERB_NET_ADDRESS* Addresses mut => &Addresses_impl;
	private KERB_NET_ADDRESS[ANYSIZE_ARRAY] Addresses_impl;
}

[CRepr]
public struct KERB_EXTERNAL_NAME
{
	public int16 NameType;
	public uint16 NameCount;
	public UNICODE_STRING* Names mut => &Names_impl;
	private UNICODE_STRING[ANYSIZE_ARRAY] Names_impl;
}

[CRepr]
public struct KERB_EXTERNAL_TICKET
{
	public KERB_EXTERNAL_NAME* ServiceName;
	public KERB_EXTERNAL_NAME* TargetName;
	public KERB_EXTERNAL_NAME* ClientName;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING TargetDomainName;
	public UNICODE_STRING AltTargetDomainName;
	public KERB_CRYPTO_KEY SessionKey;
	public KERB_TICKET_FLAGS TicketFlags;
	public uint32 Flags;
	public LARGE_INTEGER KeyExpirationTime;
	public LARGE_INTEGER StartTime;
	public LARGE_INTEGER EndTime;
	public LARGE_INTEGER RenewUntil;
	public LARGE_INTEGER TimeSkew;
	public uint32 EncodedTicketSize;
	public uint8* EncodedTicket;
}

[CRepr]
public struct KERB_RETRIEVE_TKT_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID LogonId;
	public UNICODE_STRING TargetName;
	public uint32 TicketFlags;
	public uint32 CacheOptions;
	public KERB_CRYPTO_KEY_TYPE EncryptionType;
	public SecHandle CredentialsHandle;
}

[CRepr]
public struct KERB_RETRIEVE_TKT_RESPONSE
{
	public KERB_EXTERNAL_TICKET Ticket;
}

[CRepr]
public struct KERB_PURGE_TKT_CACHE_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID LogonId;
	public UNICODE_STRING ServerName;
	public UNICODE_STRING RealmName;
}

[CRepr]
public struct KERB_PURGE_TKT_CACHE_EX_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID LogonId;
	public uint32 Flags;
	public KERB_TICKET_CACHE_INFO_EX TicketTemplate;
}

[CRepr]
public struct KERB_SUBMIT_TKT_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID LogonId;
	public uint32 Flags;
	public KERB_CRYPTO_KEY32 Key;
	public uint32 KerbCredSize;
	public uint32 KerbCredOffset;
}

[CRepr]
public struct KERB_QUERY_KDC_PROXY_CACHE_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 Flags;
	public LUID LogonId;
}

[CRepr]
public struct KDC_PROXY_CACHE_ENTRY_DATA
{
	public uint64 SinceLastUsed;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING ProxyServerName;
	public UNICODE_STRING ProxyServerVdir;
	public uint16 ProxyServerPort;
	public LUID LogonId;
	public UNICODE_STRING CredUserName;
	public UNICODE_STRING CredDomainName;
	public BOOLEAN GlobalCache;
}

[CRepr]
public struct KERB_QUERY_KDC_PROXY_CACHE_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 CountOfEntries;
	public KDC_PROXY_CACHE_ENTRY_DATA* Entries;
}

[CRepr]
public struct KERB_PURGE_KDC_PROXY_CACHE_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 Flags;
	public LUID LogonId;
}

[CRepr]
public struct KERB_PURGE_KDC_PROXY_CACHE_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 CountOfPurged;
}

[CRepr]
public struct KERB_S4U2PROXY_CACHE_ENTRY_INFO
{
	public UNICODE_STRING ServerName;
	public uint32 Flags;
	public NTSTATUS LastStatus;
	public LARGE_INTEGER Expiry;
}

[CRepr]
public struct KERB_S4U2PROXY_CRED
{
	public UNICODE_STRING UserName;
	public UNICODE_STRING DomainName;
	public uint32 Flags;
	public NTSTATUS LastStatus;
	public LARGE_INTEGER Expiry;
	public uint32 CountOfEntries;
	public KERB_S4U2PROXY_CACHE_ENTRY_INFO* Entries;
}

[CRepr]
public struct KERB_QUERY_S4U2PROXY_CACHE_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 Flags;
	public LUID LogonId;
}

[CRepr]
public struct KERB_QUERY_S4U2PROXY_CACHE_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 CountOfCreds;
	public KERB_S4U2PROXY_CRED* Creds;
}

[CRepr]
public struct KERB_RETRIEVE_KEY_TAB_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 Flags;
	public UNICODE_STRING UserName;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING Password;
}

[CRepr]
public struct KERB_RETRIEVE_KEY_TAB_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 KeyTabLength;
	public uint8* KeyTab;
}

[CRepr]
public struct KERB_REFRESH_POLICY_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 Flags;
}

[CRepr]
public struct KERB_REFRESH_POLICY_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 Flags;
}

[CRepr]
public struct KERB_CLOUD_KERBEROS_DEBUG_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID LogonId;
}

[CRepr]
public struct KERB_CLOUD_KERBEROS_DEBUG_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 Version;
	public uint32 Length;
	public uint32* Data mut => &Data_impl;
	private uint32[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct KERB_CLOUD_KERBEROS_DEBUG_DATA_V0
{
	public int32 _bitfield;
}

[CRepr]
public struct KERB_CHANGEPASSWORD_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING AccountName;
	public UNICODE_STRING OldPassword;
	public UNICODE_STRING NewPassword;
	public BOOLEAN Impersonating;
}

[CRepr]
public struct KERB_SETPASSWORD_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID LogonId;
	public SecHandle CredentialsHandle;
	public uint32 Flags;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING AccountName;
	public UNICODE_STRING Password;
}

[CRepr]
public struct KERB_SETPASSWORD_EX_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID LogonId;
	public SecHandle CredentialsHandle;
	public uint32 Flags;
	public UNICODE_STRING AccountRealm;
	public UNICODE_STRING AccountName;
	public UNICODE_STRING Password;
	public UNICODE_STRING ClientRealm;
	public UNICODE_STRING ClientName;
	public BOOLEAN Impersonating;
	public UNICODE_STRING KdcAddress;
	public uint32 KdcAddressType;
}

[CRepr]
public struct KERB_DECRYPT_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID LogonId;
	public uint32 Flags;
	public int32 CryptoType;
	public int32 KeyUsage;
	public KERB_CRYPTO_KEY Key;
	public uint32 EncryptedDataSize;
	public uint32 InitialVectorSize;
	public uint8* InitialVector;
	public uint8* EncryptedData;
}

[CRepr]
public struct KERB_DECRYPT_RESPONSE
{
	public uint8* DecryptedData mut => &DecryptedData_impl;
	private uint8[ANYSIZE_ARRAY] DecryptedData_impl;
}

[CRepr]
public struct KERB_ADD_BINDING_CACHE_ENTRY_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public UNICODE_STRING RealmName;
	public UNICODE_STRING KdcAddress;
	public KERB_ADDRESS_TYPE AddressType;
}

[CRepr]
public struct KERB_REFRESH_SCCRED_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public UNICODE_STRING CredentialBlob;
	public LUID LogonId;
	public uint32 Flags;
}

[CRepr]
public struct KERB_ADD_CREDENTIALS_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public UNICODE_STRING UserName;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING Password;
	public LUID LogonId;
	public KERB_REQUEST_FLAGS Flags;
}

[CRepr]
public struct KERB_ADD_CREDENTIALS_REQUEST_EX
{
	public KERB_ADD_CREDENTIALS_REQUEST Credentials;
	public uint32 PrincipalNameCount;
	public UNICODE_STRING* PrincipalNames mut => &PrincipalNames_impl;
	private UNICODE_STRING[ANYSIZE_ARRAY] PrincipalNames_impl;
}

[CRepr]
public struct KERB_TRANSFER_CRED_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID OriginLogonId;
	public LUID DestinationLogonId;
	public uint32 Flags;
}

[CRepr]
public struct KERB_CLEANUP_MACHINE_PKINIT_CREDS_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public LUID LogonId;
}

[CRepr]
public struct KERB_BINDING_CACHE_ENTRY_DATA
{
	public uint64 DiscoveryTime;
	public UNICODE_STRING RealmName;
	public UNICODE_STRING KdcAddress;
	public KERB_ADDRESS_TYPE AddressType;
	public uint32 Flags;
	public uint32 DcFlags;
	public uint32 CacheFlags;
	public UNICODE_STRING KdcName;
}

[CRepr]
public struct KERB_QUERY_BINDING_CACHE_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 CountOfEntries;
	public KERB_BINDING_CACHE_ENTRY_DATA* Entries;
}

[CRepr]
public struct KERB_ADD_BINDING_CACHE_ENTRY_EX_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public UNICODE_STRING RealmName;
	public UNICODE_STRING KdcAddress;
	public KERB_ADDRESS_TYPE AddressType;
	public uint32 DcFlags;
}

[CRepr]
public struct KERB_QUERY_BINDING_CACHE_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
}

[CRepr]
public struct KERB_PURGE_BINDING_CACHE_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
}

[CRepr]
public struct KERB_QUERY_DOMAIN_EXTENDED_POLICIES_REQUEST
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 Flags;
	public UNICODE_STRING DomainName;
}

[CRepr]
public struct KERB_QUERY_DOMAIN_EXTENDED_POLICIES_RESPONSE
{
	public KERB_PROTOCOL_MESSAGE_TYPE MessageType;
	public uint32 Flags;
	public uint32 ExtendedPolicies;
	public uint32 DsFlags;
}

[CRepr]
public struct KERB_CERTIFICATE_HASHINFO
{
	public uint16 StoreNameLength;
	public uint16 HashLength;
}

[CRepr]
public struct KERB_CERTIFICATE_INFO
{
	public uint32 CertInfoSize;
	public uint32 InfoType;
}

[CRepr]
public struct POLICY_AUDIT_SID_ARRAY
{
	public uint32 UsersCount;
	public PSID* UserSidArray;
}

[CRepr]
public struct AUDIT_POLICY_INFORMATION
{
	public Guid AuditSubCategoryGuid;
	public uint32 AuditingInformation;
	public Guid AuditCategoryGuid;
}

[CRepr]
public struct PKU2U_CERT_BLOB
{
	public uint32 CertOffset;
	public uint16 CertLength;
}

[CRepr]
public struct PKU2U_CREDUI_CONTEXT
{
	public uint64 Version;
	public uint16 cbHeaderLength;
	public uint32 cbStructureLength;
	public uint16 CertArrayCount;
	public uint32 CertArrayOffset;
}

[CRepr]
public struct PKU2U_CERTIFICATE_S4U_LOGON
{
	public PKU2U_LOGON_SUBMIT_TYPE MessageType;
	public uint32 Flags;
	public UNICODE_STRING UserPrincipalName;
	public UNICODE_STRING DomainName;
	public uint32 CertificateLength;
	public uint8* Certificate;
}

[CRepr]
public struct SecPkgInfoW
{
	public uint32 fCapabilities;
	public uint16 wVersion;
	public uint16 wRPCID;
	public uint32 cbMaxToken;
	public uint16* Name;
	public uint16* Comment;
}

[CRepr]
public struct SecPkgInfoA
{
	public uint32 fCapabilities;
	public uint16 wVersion;
	public uint16 wRPCID;
	public uint32 cbMaxToken;
	public int8* Name;
	public int8* Comment;
}

[CRepr]
public struct SecBuffer
{
	public uint32 cbBuffer;
	public uint32 BufferType;
	public void* pvBuffer;
}

[CRepr]
public struct SecBufferDesc
{
	public uint32 ulVersion;
	public uint32 cBuffers;
	public SecBuffer* pBuffers;
}

[CRepr]
public struct SEC_NEGOTIATION_INFO
{
	public uint32 Size;
	public uint32 NameLength;
	public uint16* Name;
	public void* Reserved;
}

[CRepr]
public struct SEC_CHANNEL_BINDINGS
{
	public uint32 dwInitiatorAddrType;
	public uint32 cbInitiatorLength;
	public uint32 dwInitiatorOffset;
	public uint32 dwAcceptorAddrType;
	public uint32 cbAcceptorLength;
	public uint32 dwAcceptorOffset;
	public uint32 cbApplicationDataLength;
	public uint32 dwApplicationDataOffset;
}

[CRepr]
public struct SEC_APPLICATION_PROTOCOL_LIST
{
	public SEC_APPLICATION_PROTOCOL_NEGOTIATION_EXT ProtoNegoExt;
	public uint16 ProtocolListSize;
	public uint8* ProtocolList mut => &ProtocolList_impl;
	private uint8[ANYSIZE_ARRAY] ProtocolList_impl;
}

[CRepr]
public struct SEC_APPLICATION_PROTOCOLS
{
	public uint32 ProtocolListsSize;
	public SEC_APPLICATION_PROTOCOL_LIST* ProtocolLists mut => &ProtocolLists_impl;
	private SEC_APPLICATION_PROTOCOL_LIST[ANYSIZE_ARRAY] ProtocolLists_impl;
}

[CRepr]
public struct SEC_SRTP_PROTECTION_PROFILES
{
	public uint16 ProfilesSize;
	public uint16* ProfilesList mut => &ProfilesList_impl;
	private uint16[ANYSIZE_ARRAY] ProfilesList_impl;
}

[CRepr]
public struct SEC_SRTP_MASTER_KEY_IDENTIFIER
{
	public uint8 MasterKeyIdentifierSize;
	public uint8* MasterKeyIdentifier mut => &MasterKeyIdentifier_impl;
	private uint8[ANYSIZE_ARRAY] MasterKeyIdentifier_impl;
}

[CRepr]
public struct SEC_TOKEN_BINDING
{
	public uint8 MajorVersion;
	public uint8 MinorVersion;
	public uint16 KeyParametersSize;
	public uint8* KeyParameters mut => &KeyParameters_impl;
	private uint8[ANYSIZE_ARRAY] KeyParameters_impl;
}

[CRepr]
public struct SEC_PRESHAREDKEY
{
	public uint16 KeySize;
	public uint8* Key mut => &Key_impl;
	private uint8[ANYSIZE_ARRAY] Key_impl;
}

[CRepr]
public struct SEC_PRESHAREDKEY_IDENTITY
{
	public uint16 KeyIdentitySize;
	public uint8* KeyIdentity mut => &KeyIdentity_impl;
	private uint8[ANYSIZE_ARRAY] KeyIdentity_impl;
}

[CRepr]
public struct SEC_DTLS_MTU
{
	public uint16 PathMTU;
}

[CRepr]
public struct SEC_FLAGS
{
	public uint64 Flags;
}

[CRepr]
public struct SEC_TRAFFIC_SECRETS
{
	public char16[64] SymmetricAlgId;
	public char16[64] ChainingMode;
	public char16[64] HashAlgId;
	public uint16 KeySize;
	public uint16 IvSize;
	public uint16 MsgSequenceStart;
	public uint16 MsgSequenceEnd;
	public SEC_TRAFFIC_SECRET_TYPE TrafficSecretType;
	public uint16 TrafficSecretSize;
	public uint8* TrafficSecret mut => &TrafficSecret_impl;
	private uint8[ANYSIZE_ARRAY] TrafficSecret_impl;
}

[CRepr]
public struct SecPkgCredentials_NamesW
{
	public uint16* sUserName;
}

[CRepr]
public struct SecPkgCredentials_NamesA
{
	public int8* sUserName;
}

[CRepr]
public struct SecPkgCredentials_SSIProviderW
{
	public uint16* sProviderName;
	public uint32 ProviderInfoLength;
	public PSTR ProviderInfo;
}

[CRepr]
public struct SecPkgCredentials_SSIProviderA
{
	public int8* sProviderName;
	public uint32 ProviderInfoLength;
	public PSTR ProviderInfo;
}

[CRepr]
public struct SecPkgCredentials_KdcProxySettingsW
{
	public uint32 Version;
	public uint32 Flags;
	public uint16 ProxyServerOffset;
	public uint16 ProxyServerLength;
	public uint16 ClientTlsCredOffset;
	public uint16 ClientTlsCredLength;
}

[CRepr]
public struct SecPkgCredentials_Cert
{
	public uint32 EncodedCertSize;
	public uint8* EncodedCert;
}

[CRepr]
public struct SecPkgContext_SubjectAttributes
{
	public void* AttributeInfo;
}

[CRepr]
public struct SecPkgContext_CredInfo
{
	public SECPKG_CRED_CLASS CredClass;
	public uint32 IsPromptingNeeded;
}

[CRepr]
public struct SecPkgContext_NegoPackageInfo
{
	public uint32 PackageMask;
}

[CRepr]
public struct SecPkgContext_NegoStatus
{
	public uint32 LastStatus;
}

[CRepr]
public struct SecPkgContext_Sizes
{
	public uint32 cbMaxToken;
	public uint32 cbMaxSignature;
	public uint32 cbBlockSize;
	public uint32 cbSecurityTrailer;
}

[CRepr]
public struct SecPkgContext_StreamSizes
{
	public uint32 cbHeader;
	public uint32 cbTrailer;
	public uint32 cbMaximumMessage;
	public uint32 cBuffers;
	public uint32 cbBlockSize;
}

[CRepr]
public struct SecPkgContext_NamesW
{
	public uint16* sUserName;
}

[CRepr]
public struct SecPkgContext_LastClientTokenStatus
{
	public SECPKG_ATTR_LCT_STATUS LastClientTokenStatus;
}

[CRepr]
public struct SecPkgContext_NamesA
{
	public int8* sUserName;
}

[CRepr]
public struct SecPkgContext_Lifespan
{
	public LARGE_INTEGER tsStart;
	public LARGE_INTEGER tsExpiry;
}

[CRepr]
public struct SecPkgContext_DceInfo
{
	public uint32 AuthzSvc;
	public void* pPac;
}

[CRepr]
public struct SecPkgContext_KeyInfoA
{
	public int8* sSignatureAlgorithmName;
	public int8* sEncryptAlgorithmName;
	public uint32 KeySize;
	public uint32 SignatureAlgorithm;
	public uint32 EncryptAlgorithm;
}

[CRepr]
public struct SecPkgContext_KeyInfoW
{
	public uint16* sSignatureAlgorithmName;
	public uint16* sEncryptAlgorithmName;
	public uint32 KeySize;
	public uint32 SignatureAlgorithm;
	public uint32 EncryptAlgorithm;
}

[CRepr]
public struct SecPkgContext_AuthorityA
{
	public int8* sAuthorityName;
}

[CRepr]
public struct SecPkgContext_AuthorityW
{
	public uint16* sAuthorityName;
}

[CRepr]
public struct SecPkgContext_ProtoInfoA
{
	public int8* sProtocolName;
	public uint32 majorVersion;
	public uint32 minorVersion;
}

[CRepr]
public struct SecPkgContext_ProtoInfoW
{
	public uint16* sProtocolName;
	public uint32 majorVersion;
	public uint32 minorVersion;
}

[CRepr]
public struct SecPkgContext_PasswordExpiry
{
	public LARGE_INTEGER tsPasswordExpires;
}

[CRepr]
public struct SecPkgContext_LogoffTime
{
	public LARGE_INTEGER tsLogoffTime;
}

[CRepr]
public struct SecPkgContext_SessionKey
{
	public uint32 SessionKeyLength;
	public uint8* SessionKey;
}

[CRepr]
public struct SecPkgContext_NegoKeys
{
	public uint32 KeyType;
	public uint16 KeyLength;
	public uint8* KeyValue;
	public uint32 VerifyKeyType;
	public uint16 VerifyKeyLength;
	public uint8* VerifyKeyValue;
}

[CRepr]
public struct SecPkgContext_PackageInfoW
{
	public SecPkgInfoW* PackageInfo;
}

[CRepr]
public struct SecPkgContext_PackageInfoA
{
	public SecPkgInfoA* PackageInfo;
}

[CRepr]
public struct SecPkgContext_UserFlags
{
	public uint32 UserFlags;
}

[CRepr]
public struct SecPkgContext_Flags
{
	public uint32 Flags;
}

[CRepr]
public struct SecPkgContext_NegotiationInfoA
{
	public SecPkgInfoA* PackageInfo;
	public uint32 NegotiationState;
}

[CRepr]
public struct SecPkgContext_NegotiationInfoW
{
	public SecPkgInfoW* PackageInfo;
	public uint32 NegotiationState;
}

[CRepr]
public struct SecPkgContext_NativeNamesW
{
	public uint16* sClientName;
	public uint16* sServerName;
}

[CRepr]
public struct SecPkgContext_NativeNamesA
{
	public int8* sClientName;
	public int8* sServerName;
}

[CRepr]
public struct SecPkgContext_CredentialNameW
{
	public uint32 CredentialType;
	public uint16* sCredentialName;
}

[CRepr]
public struct SecPkgContext_CredentialNameA
{
	public uint32 CredentialType;
	public int8* sCredentialName;
}

[CRepr]
public struct SecPkgContext_AccessToken
{
	public void* AccessToken;
}

[CRepr]
public struct SecPkgContext_TargetInformation
{
	public uint32 MarshalledTargetInfoLength;
	public uint8* MarshalledTargetInfo;
}

[CRepr]
public struct SecPkgContext_AuthzID
{
	public uint32 AuthzIDLength;
	public PSTR AuthzID;
}

[CRepr]
public struct SecPkgContext_Target
{
	public uint32 TargetLength;
	public PSTR Target;
}

[CRepr]
public struct SecPkgContext_ClientSpecifiedTarget
{
	public uint16* sTargetName;
}

[CRepr]
public struct SecPkgContext_Bindings
{
	public uint32 BindingsLength;
	public SEC_CHANNEL_BINDINGS* Bindings;
}

[CRepr]
public struct SecPkgContext_ApplicationProtocol
{
	public SEC_APPLICATION_PROTOCOL_NEGOTIATION_STATUS ProtoNegoStatus;
	public SEC_APPLICATION_PROTOCOL_NEGOTIATION_EXT ProtoNegoExt;
	public uint8 ProtocolIdSize;
	public uint8[255] ProtocolId;
}

[CRepr]
public struct SecPkgContext_NegotiatedTlsExtensions
{
	public uint32 ExtensionsCount;
	public uint16* Extensions;
}

[CRepr]
public struct SECPKG_APP_MODE_INFO
{
	public uint32 UserFunction;
	public uint Argument1;
	public uint Argument2;
	public SecBuffer UserData;
	public BOOLEAN ReturnToLsa;
}

[CRepr]
public struct SecurityFunctionTableW
{
	public uint32 dwVersion;
	public ENUMERATE_SECURITY_PACKAGES_FN_W EnumerateSecurityPackagesW;
	public QUERY_CREDENTIALS_ATTRIBUTES_FN_W QueryCredentialsAttributesW;
	public ACQUIRE_CREDENTIALS_HANDLE_FN_W AcquireCredentialsHandleW;
	public FREE_CREDENTIALS_HANDLE_FN FreeCredentialsHandle;
	public void* Reserved2;
	public INITIALIZE_SECURITY_CONTEXT_FN_W InitializeSecurityContextW;
	public ACCEPT_SECURITY_CONTEXT_FN AcceptSecurityContext;
	public COMPLETE_AUTH_TOKEN_FN CompleteAuthToken;
	public DELETE_SECURITY_CONTEXT_FN DeleteSecurityContext;
	public APPLY_CONTROL_TOKEN_FN ApplyControlToken;
	public QUERY_CONTEXT_ATTRIBUTES_FN_W QueryContextAttributesW;
	public IMPERSONATE_SECURITY_CONTEXT_FN ImpersonateSecurityContext;
	public REVERT_SECURITY_CONTEXT_FN RevertSecurityContext;
	public MAKE_SIGNATURE_FN MakeSignature;
	public VERIFY_SIGNATURE_FN VerifySignature;
	public FREE_CONTEXT_BUFFER_FN FreeContextBuffer;
	public QUERY_SECURITY_PACKAGE_INFO_FN_W QuerySecurityPackageInfoW;
	public void* Reserved3;
	public void* Reserved4;
	public EXPORT_SECURITY_CONTEXT_FN ExportSecurityContext;
	public IMPORT_SECURITY_CONTEXT_FN_W ImportSecurityContextW;
	public ADD_CREDENTIALS_FN_W AddCredentialsW;
	public void* Reserved8;
	public QUERY_SECURITY_CONTEXT_TOKEN_FN QuerySecurityContextToken;
	public ENCRYPT_MESSAGE_FN EncryptMessage;
	public DECRYPT_MESSAGE_FN DecryptMessage;
	public SET_CONTEXT_ATTRIBUTES_FN_W SetContextAttributesW;
	public SET_CREDENTIALS_ATTRIBUTES_FN_W SetCredentialsAttributesW;
	public CHANGE_PASSWORD_FN_W ChangeAccountPasswordW;
	public QUERY_CONTEXT_ATTRIBUTES_EX_FN_W QueryContextAttributesExW;
	public QUERY_CREDENTIALS_ATTRIBUTES_EX_FN_W QueryCredentialsAttributesExW;
}

[CRepr]
public struct SecurityFunctionTableA
{
	public uint32 dwVersion;
	public ENUMERATE_SECURITY_PACKAGES_FN_A EnumerateSecurityPackagesA;
	public QUERY_CREDENTIALS_ATTRIBUTES_FN_A QueryCredentialsAttributesA;
	public ACQUIRE_CREDENTIALS_HANDLE_FN_A AcquireCredentialsHandleA;
	public FREE_CREDENTIALS_HANDLE_FN FreeCredentialsHandle;
	public void* Reserved2;
	public INITIALIZE_SECURITY_CONTEXT_FN_A InitializeSecurityContextA;
	public ACCEPT_SECURITY_CONTEXT_FN AcceptSecurityContext;
	public COMPLETE_AUTH_TOKEN_FN CompleteAuthToken;
	public DELETE_SECURITY_CONTEXT_FN DeleteSecurityContext;
	public APPLY_CONTROL_TOKEN_FN ApplyControlToken;
	public QUERY_CONTEXT_ATTRIBUTES_FN_A QueryContextAttributesA;
	public IMPERSONATE_SECURITY_CONTEXT_FN ImpersonateSecurityContext;
	public REVERT_SECURITY_CONTEXT_FN RevertSecurityContext;
	public MAKE_SIGNATURE_FN MakeSignature;
	public VERIFY_SIGNATURE_FN VerifySignature;
	public FREE_CONTEXT_BUFFER_FN FreeContextBuffer;
	public QUERY_SECURITY_PACKAGE_INFO_FN_A QuerySecurityPackageInfoA;
	public void* Reserved3;
	public void* Reserved4;
	public EXPORT_SECURITY_CONTEXT_FN ExportSecurityContext;
	public IMPORT_SECURITY_CONTEXT_FN_A ImportSecurityContextA;
	public ADD_CREDENTIALS_FN_A AddCredentialsA;
	public void* Reserved8;
	public QUERY_SECURITY_CONTEXT_TOKEN_FN QuerySecurityContextToken;
	public ENCRYPT_MESSAGE_FN EncryptMessage;
	public DECRYPT_MESSAGE_FN DecryptMessage;
	public SET_CONTEXT_ATTRIBUTES_FN_A SetContextAttributesA;
	public SET_CREDENTIALS_ATTRIBUTES_FN_A SetCredentialsAttributesA;
	public CHANGE_PASSWORD_FN_A ChangeAccountPasswordA;
	public QUERY_CONTEXT_ATTRIBUTES_EX_FN_A QueryContextAttributesExA;
	public QUERY_CREDENTIALS_ATTRIBUTES_EX_FN_A QueryCredentialsAttributesExA;
}

[CRepr]
public struct SEC_WINNT_AUTH_IDENTITY_EX2
{
	public uint32 Version;
	public uint16 cbHeaderLength;
	public uint32 cbStructureLength;
	public uint32 UserOffset;
	public uint16 UserLength;
	public uint32 DomainOffset;
	public uint16 DomainLength;
	public uint32 PackedCredentialsOffset;
	public uint16 PackedCredentialsLength;
	public uint32 Flags;
	public uint32 PackageListOffset;
	public uint16 PackageListLength;
}

[CRepr]
public struct SEC_WINNT_AUTH_IDENTITY_EXW
{
	public uint32 Version;
	public uint32 Length;
	public uint16* User;
	public uint32 UserLength;
	public uint16* Domain;
	public uint32 DomainLength;
	public uint16* Password;
	public uint32 PasswordLength;
	public uint32 Flags;
	public uint16* PackageList;
	public uint32 PackageListLength;
}

[CRepr]
public struct SEC_WINNT_AUTH_IDENTITY_EXA
{
	public uint32 Version;
	public uint32 Length;
	public uint8* User;
	public uint32 UserLength;
	public uint8* Domain;
	public uint32 DomainLength;
	public uint8* Password;
	public uint32 PasswordLength;
	public uint32 Flags;
	public uint8* PackageList;
	public uint32 PackageListLength;
}

[CRepr, Union]
public struct SEC_WINNT_AUTH_IDENTITY_INFO
{
	public SEC_WINNT_AUTH_IDENTITY_EXW AuthIdExw;
	public SEC_WINNT_AUTH_IDENTITY_EXA AuthIdExa;
	public SEC_WINNT_AUTH_IDENTITY_A AuthId_a;
	public SEC_WINNT_AUTH_IDENTITY_W AuthId_w;
	public SEC_WINNT_AUTH_IDENTITY_EX2 AuthIdEx2;
}

[CRepr]
public struct SECURITY_PACKAGE_OPTIONS
{
	public uint32 Size;
	public SECURITY_PACKAGE_OPTIONS_TYPE Type;
	public uint32 Flags;
	public uint32 SignatureSize;
	public void* Signature;
}

[CRepr]
public struct LSA_TOKEN_INFORMATION_NULL
{
	public LARGE_INTEGER ExpirationTime;
	public TOKEN_GROUPS* Groups;
}

[CRepr]
public struct LSA_TOKEN_INFORMATION_V1
{
	public LARGE_INTEGER ExpirationTime;
	public TOKEN_USER User;
	public TOKEN_GROUPS* Groups;
	public TOKEN_PRIMARY_GROUP PrimaryGroup;
	public TOKEN_PRIVILEGES* Privileges;
	public TOKEN_OWNER Owner;
	public TOKEN_DEFAULT_DACL DefaultDacl;
}

[CRepr]
public struct LSA_TOKEN_INFORMATION_V3
{
	public LARGE_INTEGER ExpirationTime;
	public TOKEN_USER User;
	public TOKEN_GROUPS* Groups;
	public TOKEN_PRIMARY_GROUP PrimaryGroup;
	public TOKEN_PRIVILEGES* Privileges;
	public TOKEN_OWNER Owner;
	public TOKEN_DEFAULT_DACL DefaultDacl;
	public TOKEN_USER_CLAIMS UserClaims;
	public TOKEN_DEVICE_CLAIMS DeviceClaims;
	public TOKEN_GROUPS* DeviceGroups;
}

[CRepr]
public struct LSA_DISPATCH_TABLE
{
	public PLSA_CREATE_LOGON_SESSION CreateLogonSession;
	public PLSA_DELETE_LOGON_SESSION DeleteLogonSession;
	public PLSA_ADD_CREDENTIAL AddCredential;
	public PLSA_GET_CREDENTIALS GetCredentials;
	public PLSA_DELETE_CREDENTIAL DeleteCredential;
	public PLSA_ALLOCATE_LSA_HEAP AllocateLsaHeap;
	public PLSA_FREE_LSA_HEAP FreeLsaHeap;
	public PLSA_ALLOCATE_CLIENT_BUFFER AllocateClientBuffer;
	public PLSA_FREE_CLIENT_BUFFER FreeClientBuffer;
	public PLSA_COPY_TO_CLIENT_BUFFER CopyToClientBuffer;
	public PLSA_COPY_FROM_CLIENT_BUFFER CopyFromClientBuffer;
}

[CRepr]
public struct SAM_REGISTER_MAPPING_ELEMENT
{
	public PSTR Original;
	public PSTR Mapped;
	public BOOLEAN Continuable;
}

[CRepr]
public struct SAM_REGISTER_MAPPING_LIST
{
	public uint32 Count;
	public SAM_REGISTER_MAPPING_ELEMENT* Elements;
}

[CRepr]
public struct SAM_REGISTER_MAPPING_TABLE
{
	public uint32 Count;
	public SAM_REGISTER_MAPPING_LIST* Lists;
}

[CRepr]
public struct SECPKG_CLIENT_INFO
{
	public LUID LogonId;
	public uint32 ProcessID;
	public uint32 ThreadID;
	public BOOLEAN HasTcbPrivilege;
	public BOOLEAN Impersonating;
	public BOOLEAN Restricted;
	public uint8 ClientFlags;
	public SECURITY_IMPERSONATION_LEVEL ImpersonationLevel;
	public HANDLE ClientToken;
}

[CRepr]
public struct SECPKG_CALL_INFO
{
	public uint32 ProcessId;
	public uint32 ThreadId;
	public uint32 Attributes;
	public uint32 CallCount;
	public void* MechOid;
}

[CRepr]
public struct SECPKG_SUPPLEMENTAL_CRED
{
	public UNICODE_STRING PackageName;
	public uint32 CredentialSize;
	public uint8* Credentials;
}

[CRepr]
public struct SECPKG_BYTE_VECTOR
{
	public uint32 ByteArrayOffset;
	public uint16 ByteArrayLength;
}

[CRepr]
public struct SECPKG_SHORT_VECTOR
{
	public uint32 ShortArrayOffset;
	public uint16 ShortArrayCount;
}

[CRepr]
public struct SECPKG_SUPPLIED_CREDENTIAL
{
	public uint16 cbHeaderLength;
	public uint16 cbStructureLength;
	public SECPKG_SHORT_VECTOR UserName;
	public SECPKG_SHORT_VECTOR DomainName;
	public SECPKG_BYTE_VECTOR PackedCredentials;
	public uint32 CredFlags;
}

[CRepr]
public struct SECPKG_CREDENTIAL
{
	public uint64 Version;
	public uint16 cbHeaderLength;
	public uint32 cbStructureLength;
	public uint32 ClientProcess;
	public uint32 ClientThread;
	public LUID LogonId;
	public HANDLE ClientToken;
	public uint32 SessionId;
	public LUID ModifiedId;
	public uint32 fCredentials;
	public uint32 Flags;
	public SECPKG_BYTE_VECTOR PrincipalName;
	public SECPKG_BYTE_VECTOR PackageList;
	public SECPKG_BYTE_VECTOR MarshaledSuppliedCreds;
}

[CRepr]
public struct SECPKG_SUPPLEMENTAL_CRED_ARRAY
{
	public uint32 CredentialCount;
	public SECPKG_SUPPLEMENTAL_CRED* Credentials mut => &Credentials_impl;
	private SECPKG_SUPPLEMENTAL_CRED[ANYSIZE_ARRAY] Credentials_impl;
}

[CRepr]
public struct SECPKG_SURROGATE_LOGON_ENTRY
{
	public Guid Type;
	public void* Data;
}

[CRepr]
public struct SECPKG_SURROGATE_LOGON
{
	public uint32 Version;
	public LUID SurrogateLogonID;
	public uint32 EntryCount;
	public SECPKG_SURROGATE_LOGON_ENTRY* Entries;
}

[CRepr]
public struct SECPKG_PRIMARY_CRED
{
	public LUID LogonId;
	public UNICODE_STRING DownlevelName;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING Password;
	public UNICODE_STRING OldPassword;
	public PSID UserSid;
	public uint32 Flags;
	public UNICODE_STRING DnsDomainName;
	public UNICODE_STRING Upn;
	public UNICODE_STRING LogonServer;
	public UNICODE_STRING Spare1;
	public UNICODE_STRING Spare2;
	public UNICODE_STRING Spare3;
	public UNICODE_STRING Spare4;
}

[CRepr]
public struct SECPKG_PRIMARY_CRED_EX
{
	public LUID LogonId;
	public UNICODE_STRING DownlevelName;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING Password;
	public UNICODE_STRING OldPassword;
	public PSID UserSid;
	public uint32 Flags;
	public UNICODE_STRING DnsDomainName;
	public UNICODE_STRING Upn;
	public UNICODE_STRING LogonServer;
	public UNICODE_STRING Spare1;
	public UNICODE_STRING Spare2;
	public UNICODE_STRING Spare3;
	public UNICODE_STRING Spare4;
	public uint PackageId;
	public LUID PrevLogonId;
	public uint32 FlagsEx;
}

[CRepr]
public struct SECPKG_PARAMETERS
{
	public uint32 Version;
	public uint32 MachineState;
	public uint32 SetupMode;
	public PSID DomainSid;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING DnsDomainName;
	public Guid DomainGuid;
}

[CRepr]
public struct SECPKG_GSS_INFO
{
	public uint32 EncodedIdLength;
	public uint8[4] EncodedId;
}

[CRepr]
public struct SECPKG_CONTEXT_THUNKS
{
	public uint32 InfoLevelCount;
	public uint32* Levels mut => &Levels_impl;
	private uint32[ANYSIZE_ARRAY] Levels_impl;
}

[CRepr]
public struct SECPKG_MUTUAL_AUTH_LEVEL
{
	public uint32 MutualAuthLevel;
}

[CRepr]
public struct SECPKG_WOW_CLIENT_DLL
{
	public UNICODE_STRING WowClientDllPath;
}

[CRepr]
public struct SECPKG_SERIALIZED_OID
{
	public uint32 OidLength;
	public uint32 OidAttributes;
	public uint8[32] OidValue;
}

[CRepr]
public struct SECPKG_EXTRA_OIDS
{
	public uint32 OidCount;
	public SECPKG_SERIALIZED_OID* Oids mut => &Oids_impl;
	private SECPKG_SERIALIZED_OID[ANYSIZE_ARRAY] Oids_impl;
}

[CRepr]
public struct SECPKG_NEGO2_INFO
{
	public uint8[16] AuthScheme;
	public uint32 PackageFlags;
}

[CRepr]
public struct SECPKG_EXTENDED_INFORMATION
{
	[CRepr, Union]
	public struct _Info_e__Union
	{
		public SECPKG_GSS_INFO GssInfo;
		public SECPKG_CONTEXT_THUNKS ContextThunks;
		public SECPKG_MUTUAL_AUTH_LEVEL MutualAuthLevel;
		public SECPKG_WOW_CLIENT_DLL WowClientDll;
		public SECPKG_EXTRA_OIDS ExtraOids;
		public SECPKG_NEGO2_INFO Nego2Info;
	}
	public SECPKG_EXTENDED_INFORMATION_CLASS Class;
	public _Info_e__Union Info;
}

[CRepr]
public struct SECPKG_TARGETINFO
{
	public PSID DomainSid;
	public PWSTR ComputerName;
}

[CRepr]
public struct SecPkgContext_SaslContext
{
	public void* SaslContext;
}

[CRepr]
public struct SECURITY_USER_DATA
{
	public UNICODE_STRING UserName;
	public UNICODE_STRING LogonDomainName;
	public UNICODE_STRING LogonServer;
	public PSID pSid;
}

[CRepr]
public struct SECPKG_CALL_PACKAGE_PIN_DC_REQUEST
{
	public uint32 MessageType;
	public uint32 Flags;
	public UNICODE_STRING DomainName;
	public UNICODE_STRING DcName;
	public uint32 DcFlags;
}

[CRepr]
public struct SECPKG_CALL_PACKAGE_UNPIN_ALL_DCS_REQUEST
{
	public uint32 MessageType;
	public uint32 Flags;
}

[CRepr]
public struct SECPKG_CALL_PACKAGE_TRANSFER_CRED_REQUEST
{
	public uint32 MessageType;
	public LUID OriginLogonId;
	public LUID DestinationLogonId;
	public uint32 Flags;
}

[CRepr]
public struct SECPKG_REDIRECTED_LOGON_BUFFER
{
	public Guid RedirectedLogonGuid;
	public HANDLE RedirectedLogonHandle;
	public PLSA_REDIRECTED_LOGON_INIT Init;
	public PLSA_REDIRECTED_LOGON_CALLBACK Callback;
	public PLSA_REDIRECTED_LOGON_CLEANUP_CALLBACK CleanupCallback;
	public PLSA_REDIRECTED_LOGON_GET_LOGON_CREDS GetLogonCreds;
	public PLSA_REDIRECTED_LOGON_GET_SUPP_CREDS GetSupplementalCreds;
}

[CRepr]
public struct SECPKG_POST_LOGON_USER_INFO
{
	public uint32 Flags;
	public LUID LogonId;
	public LUID LinkedLogonId;
}

[CRepr]
public struct SECPKG_EVENT_PACKAGE_CHANGE
{
	public SECPKG_PACKAGE_CHANGE_TYPE ChangeType;
	public uint PackageId;
	public UNICODE_STRING PackageName;
}

[CRepr]
public struct SECPKG_EVENT_ROLE_CHANGE
{
	public uint32 PreviousRole;
	public uint32 NewRole;
}

[CRepr]
public struct SECPKG_EVENT_NOTIFY
{
	public uint32 EventClass;
	public uint32 Reserved;
	public uint32 EventDataSize;
	public void* EventData;
	public void* PackageParameter;
}

[CRepr]
public struct ENCRYPTED_CREDENTIALW
{
	public CREDENTIALW Cred;
	public uint32 ClearCredentialBlobSize;
}

[CRepr]
public struct SEC_WINNT_AUTH_IDENTITY32
{
	public uint32 User;
	public uint32 UserLength;
	public uint32 Domain;
	public uint32 DomainLength;
	public uint32 Password;
	public uint32 PasswordLength;
	public uint32 Flags;
}

[CRepr]
public struct SEC_WINNT_AUTH_IDENTITY_EX32
{
	public uint32 Version;
	public uint32 Length;
	public uint32 User;
	public uint32 UserLength;
	public uint32 Domain;
	public uint32 DomainLength;
	public uint32 Password;
	public uint32 PasswordLength;
	public uint32 Flags;
	public uint32 PackageList;
	public uint32 PackageListLength;
}

[CRepr]
public struct LSA_SECPKG_FUNCTION_TABLE
{
	public PLSA_CREATE_LOGON_SESSION CreateLogonSession;
	public PLSA_DELETE_LOGON_SESSION DeleteLogonSession;
	public PLSA_ADD_CREDENTIAL AddCredential;
	public PLSA_GET_CREDENTIALS GetCredentials;
	public PLSA_DELETE_CREDENTIAL DeleteCredential;
	public PLSA_ALLOCATE_LSA_HEAP AllocateLsaHeap;
	public PLSA_FREE_LSA_HEAP FreeLsaHeap;
	public PLSA_ALLOCATE_CLIENT_BUFFER AllocateClientBuffer;
	public PLSA_FREE_CLIENT_BUFFER FreeClientBuffer;
	public PLSA_COPY_TO_CLIENT_BUFFER CopyToClientBuffer;
	public PLSA_COPY_FROM_CLIENT_BUFFER CopyFromClientBuffer;
	public PLSA_IMPERSONATE_CLIENT ImpersonateClient;
	public PLSA_UNLOAD_PACKAGE UnloadPackage;
	public PLSA_DUPLICATE_HANDLE DuplicateHandle;
	public PLSA_SAVE_SUPPLEMENTAL_CREDENTIALS SaveSupplementalCredentials;
	public PLSA_CREATE_THREAD CreateThread;
	public PLSA_GET_CLIENT_INFO GetClientInfo;
	public PLSA_REGISTER_NOTIFICATION RegisterNotification;
	public PLSA_CANCEL_NOTIFICATION CancelNotification;
	public PLSA_MAP_BUFFER MapBuffer;
	public PLSA_CREATE_TOKEN CreateToken;
	public PLSA_AUDIT_LOGON AuditLogon;
	public PLSA_CALL_PACKAGE CallPackage;
	public PLSA_FREE_LSA_HEAP FreeReturnBuffer;
	public PLSA_GET_CALL_INFO GetCallInfo;
	public PLSA_CALL_PACKAGEEX CallPackageEx;
	public PLSA_CREATE_SHARED_MEMORY CreateSharedMemory;
	public PLSA_ALLOCATE_SHARED_MEMORY AllocateSharedMemory;
	public PLSA_FREE_SHARED_MEMORY FreeSharedMemory;
	public PLSA_DELETE_SHARED_MEMORY DeleteSharedMemory;
	public PLSA_OPEN_SAM_USER OpenSamUser;
	public PLSA_GET_USER_CREDENTIALS GetUserCredentials;
	public PLSA_GET_USER_AUTH_DATA GetUserAuthData;
	public PLSA_CLOSE_SAM_USER CloseSamUser;
	public PLSA_CONVERT_AUTH_DATA_TO_TOKEN ConvertAuthDataToToken;
	public PLSA_CLIENT_CALLBACK ClientCallback;
	public PLSA_UPDATE_PRIMARY_CREDENTIALS UpdateCredentials;
	public PLSA_GET_AUTH_DATA_FOR_USER GetAuthDataForUser;
	public PLSA_CRACK_SINGLE_NAME CrackSingleName;
	public PLSA_AUDIT_ACCOUNT_LOGON AuditAccountLogon;
	public PLSA_CALL_PACKAGE_PASSTHROUGH CallPackagePassthrough;
	public CredReadFn CrediRead;
	public CredReadDomainCredentialsFn CrediReadDomainCredentials;
	public CredFreeCredentialsFn CrediFreeCredentials;
	public PLSA_PROTECT_MEMORY LsaProtectMemory;
	public PLSA_PROTECT_MEMORY LsaUnprotectMemory;
	public PLSA_OPEN_TOKEN_BY_LOGON_ID OpenTokenByLogonId;
	public PLSA_EXPAND_AUTH_DATA_FOR_DOMAIN ExpandAuthDataForDomain;
	public PLSA_ALLOCATE_PRIVATE_HEAP AllocatePrivateHeap;
	public PLSA_FREE_PRIVATE_HEAP FreePrivateHeap;
	public PLSA_CREATE_TOKEN_EX CreateTokenEx;
	public CredWriteFn CrediWrite;
	public CrediUnmarshalandDecodeStringFn CrediUnmarshalandDecodeString;
	public PLSA_PROTECT_MEMORY DummyFunction6;
	public PLSA_GET_EXTENDED_CALL_FLAGS GetExtendedCallFlags;
	public PLSA_DUPLICATE_HANDLE DuplicateTokenHandle;
	public PLSA_GET_SERVICE_ACCOUNT_PASSWORD GetServiceAccountPassword;
	public PLSA_PROTECT_MEMORY DummyFunction7;
	public PLSA_AUDIT_LOGON_EX AuditLogonEx;
	public PLSA_CHECK_PROTECTED_USER_BY_TOKEN CheckProtectedUserByToken;
	public PLSA_QUERY_CLIENT_REQUEST QueryClientRequest;
	public PLSA_GET_APP_MODE_INFO GetAppModeInfo;
	public PLSA_SET_APP_MODE_INFO SetAppModeInfo;
}

[CRepr]
public struct SECPKG_DLL_FUNCTIONS
{
	public PLSA_ALLOCATE_LSA_HEAP AllocateHeap;
	public PLSA_FREE_LSA_HEAP FreeHeap;
	public PLSA_REGISTER_CALLBACK RegisterCallback;
	public PLSA_LOCATE_PKG_BY_ID LocatePackageById;
}

[CRepr]
public struct SECPKG_FUNCTION_TABLE
{
	public PLSA_AP_INITIALIZE_PACKAGE InitializePackage;
	public PLSA_AP_LOGON_USER LogonUserA;
	public PLSA_AP_CALL_PACKAGE CallPackage;
	public PLSA_AP_LOGON_TERMINATED LogonTerminated;
	public PLSA_AP_CALL_PACKAGE CallPackageUntrusted;
	public PLSA_AP_CALL_PACKAGE_PASSTHROUGH CallPackagePassthrough;
	public PLSA_AP_LOGON_USER_EX LogonUserExA;
	public PLSA_AP_LOGON_USER_EX2 LogonUserEx2;
	public SpInitializeFn Initialize;
	public SpShutdownFn Shutdown;
	public SpGetInfoFn GetInfo;
	public SpAcceptCredentialsFn AcceptCredentials;
	public SpAcquireCredentialsHandleFn AcquireCredentialsHandleA;
	public SpQueryCredentialsAttributesFn QueryCredentialsAttributesA;
	public SpFreeCredentialsHandleFn FreeCredentialsHandle;
	public SpSaveCredentialsFn SaveCredentials;
	public SpGetCredentialsFn GetCredentials;
	public SpDeleteCredentialsFn DeleteCredentials;
	public SpInitLsaModeContextFn InitLsaModeContext;
	public SpAcceptLsaModeContextFn AcceptLsaModeContext;
	public SpDeleteContextFn DeleteContext;
	public SpApplyControlTokenFn ApplyControlToken;
	public SpGetUserInfoFn GetUserInfo;
	public SpGetExtendedInformationFn GetExtendedInformation;
	public SpQueryContextAttributesFn QueryContextAttributesA;
	public SpAddCredentialsFn AddCredentialsA;
	public SpSetExtendedInformationFn SetExtendedInformation;
	public SpSetContextAttributesFn SetContextAttributesA;
	public SpSetCredentialsAttributesFn SetCredentialsAttributesA;
	public SpChangeAccountPasswordFn ChangeAccountPasswordA;
	public SpQueryMetaDataFn QueryMetaData;
	public SpExchangeMetaDataFn ExchangeMetaData;
	public SpGetCredUIContextFn GetCredUIContext;
	public SpUpdateCredentialsFn UpdateCredentials;
	public SpValidateTargetInfoFn ValidateTargetInfo;
	public LSA_AP_POST_LOGON_USER PostLogonUser;
	public SpGetRemoteCredGuardLogonBufferFn GetRemoteCredGuardLogonBuffer;
	public SpGetRemoteCredGuardSupplementalCredsFn GetRemoteCredGuardSupplementalCreds;
	public SpGetTbalSupplementalCredsFn GetTbalSupplementalCreds;
	public PLSA_AP_LOGON_USER_EX3 LogonUserEx3;
	public PLSA_AP_PRE_LOGON_USER_SURROGATE PreLogonUserSurrogate;
	public PLSA_AP_POST_LOGON_USER_SURROGATE PostLogonUserSurrogate;
}

[CRepr]
public struct SECPKG_USER_FUNCTION_TABLE
{
	public SpInstanceInitFn InstanceInit;
	public SpInitUserModeContextFn InitUserModeContext;
	public SpMakeSignatureFn MakeSignature;
	public SpVerifySignatureFn VerifySignature;
	public SpSealMessageFn SealMessage;
	public SpUnsealMessageFn UnsealMessage;
	public SpGetContextTokenFn GetContextToken;
	public SpQueryContextAttributesFn QueryContextAttributesA;
	public SpCompleteAuthTokenFn CompleteAuthToken;
	public SpDeleteContextFn DeleteUserModeContext;
	public SpFormatCredentialsFn FormatCredentials;
	public SpMarshallSupplementalCredsFn MarshallSupplementalCreds;
	public SpExportSecurityContextFn ExportContext;
	public SpImportSecurityContextFn ImportContext;
	public SpMarshalAttributeDataFn MarshalAttributeData;
}

[CRepr]
public struct KSEC_LIST_ENTRY
{
	public LIST_ENTRY List;
	public int32 RefCount;
	public uint32 Signature;
	public void* OwningList;
	public void* Reserved;
}

[CRepr]
public struct SECPKG_KERNEL_FUNCTIONS
{
	public PLSA_ALLOCATE_LSA_HEAP AllocateHeap;
	public PLSA_FREE_LSA_HEAP FreeHeap;
	public PKSEC_CREATE_CONTEXT_LIST CreateContextList;
	public PKSEC_INSERT_LIST_ENTRY InsertListEntry;
	public PKSEC_REFERENCE_LIST_ENTRY ReferenceListEntry;
	public PKSEC_DEREFERENCE_LIST_ENTRY DereferenceListEntry;
	public PKSEC_SERIALIZE_WINNT_AUTH_DATA SerializeWinntAuthData;
	public PKSEC_SERIALIZE_SCHANNEL_AUTH_DATA SerializeSchannelAuthData;
	public PKSEC_LOCATE_PKG_BY_ID LocatePackageById;
}

[CRepr]
public struct SECPKG_KERNEL_FUNCTION_TABLE
{
	public KspInitPackageFn Initialize;
	public KspDeleteContextFn DeleteContext;
	public KspInitContextFn InitContext;
	public KspMapHandleFn MapHandle;
	public KspMakeSignatureFn Sign;
	public KspVerifySignatureFn Verify;
	public KspSealMessageFn Seal;
	public KspUnsealMessageFn Unseal;
	public KspGetTokenFn GetToken;
	public KspQueryAttributesFn QueryAttributes;
	public KspCompleteTokenFn CompleteToken;
	public SpExportSecurityContextFn ExportContext;
	public SpImportSecurityContextFn ImportContext;
	public KspSetPagingModeFn SetPackagePagingMode;
	public KspSerializeAuthDataFn SerializeAuthData;
}

[CRepr]
public struct SecPkgCred_SupportedAlgs
{
	public uint32 cSupportedAlgs;
	public uint32* palgSupportedAlgs;
}

[CRepr]
public struct SecPkgCred_CipherStrengths
{
	public uint32 dwMinimumCipherStrength;
	public uint32 dwMaximumCipherStrength;
}

[CRepr]
public struct SecPkgCred_SupportedProtocols
{
	public uint32 grbitProtocol;
}

[CRepr]
public struct SecPkgCred_ClientCertPolicy
{
	public uint32 dwFlags;
	public Guid guidPolicyId;
	public uint32 dwCertFlags;
	public uint32 dwUrlRetrievalTimeout;
	public BOOL fCheckRevocationFreshnessTime;
	public uint32 dwRevocationFreshnessTime;
	public BOOL fOmitUsageCheck;
	public PWSTR pwszSslCtlStoreName;
	public PWSTR pwszSslCtlIdentifier;
}

[CRepr]
public struct SecPkgCred_SessionTicketKey
{
	public uint32 TicketInfoVersion;
	public uint8[16] KeyId;
	public uint8[64] KeyingMaterial;
	public uint8 KeyingMaterialSize;
}

[CRepr]
public struct SecPkgCred_SessionTicketKeys
{
	public uint32 cSessionTicketKeys;
	public SecPkgCred_SessionTicketKey* pSessionTicketKeys;
}

[CRepr]
public struct SecPkgContext_RemoteCredentialInfo
{
	public uint32 cbCertificateChain;
	public uint8* pbCertificateChain;
	public uint32 cCertificates;
	public uint32 fFlags;
	public uint32 dwBits;
}

[CRepr]
public struct SecPkgContext_LocalCredentialInfo
{
	public uint32 cbCertificateChain;
	public uint8* pbCertificateChain;
	public uint32 cCertificates;
	public uint32 fFlags;
	public uint32 dwBits;
}

[CRepr]
public struct SecPkgContext_ClientCertPolicyResult
{
	public HRESULT dwPolicyResult;
	public Guid guidPolicyId;
}

[CRepr]
public struct SecPkgContext_IssuerListInfoEx
{
	public CRYPTOAPI_BLOB* aIssuers;
	public uint32 cIssuers;
}

[CRepr]
public struct SecPkgContext_ConnectionInfo
{
	public uint32 dwProtocol;
	public uint32 aiCipher;
	public uint32 dwCipherStrength;
	public uint32 aiHash;
	public uint32 dwHashStrength;
	public uint32 aiExch;
	public uint32 dwExchStrength;
}

[CRepr]
public struct SecPkgContext_ConnectionInfoEx
{
	public uint32 dwVersion;
	public uint32 dwProtocol;
	public char16[64] szCipher;
	public uint32 dwCipherStrength;
	public char16[64] szHash;
	public uint32 dwHashStrength;
	public char16[64] szExchange;
	public uint32 dwExchStrength;
}

[CRepr]
public struct SecPkgContext_CipherInfo
{
	public uint32 dwVersion;
	public uint32 dwProtocol;
	public uint32 dwCipherSuite;
	public uint32 dwBaseCipherSuite;
	public char16[64] szCipherSuite;
	public char16[64] szCipher;
	public uint32 dwCipherLen;
	public uint32 dwCipherBlockLen;
	public char16[64] szHash;
	public uint32 dwHashLen;
	public char16[64] szExchange;
	public uint32 dwMinExchangeLen;
	public uint32 dwMaxExchangeLen;
	public char16[64] szCertificate;
	public uint32 dwKeyType;
}

[CRepr]
public struct SecPkgContext_EapKeyBlock
{
	public uint8[128] rgbKeys;
	public uint8[64] rgbIVs;
}

[CRepr]
public struct SecPkgContext_MappedCredAttr
{
	public uint32 dwAttribute;
	public void* pvBuffer;
}

[CRepr]
public struct SecPkgContext_SessionInfo
{
	public uint32 dwFlags;
	public uint32 cbSessionId;
	public uint8[32] rgbSessionId;
}

[CRepr]
public struct SecPkgContext_SessionAppData
{
	public uint32 dwFlags;
	public uint32 cbAppData;
	public uint8* pbAppData;
}

[CRepr]
public struct SecPkgContext_EapPrfInfo
{
	public uint32 dwVersion;
	public uint32 cbPrfData;
	public uint8* pbPrfData;
}

[CRepr]
public struct SecPkgContext_SupportedSignatures
{
	public uint16 cSignatureAndHashAlgorithms;
	public uint16* pSignatureAndHashAlgorithms;
}

[CRepr]
public struct SecPkgContext_Certificates
{
	public uint32 cCertificates;
	public uint32 cbCertificateChain;
	public uint8* pbCertificateChain;
}

[CRepr]
public struct SecPkgContext_CertInfo
{
	public uint32 dwVersion;
	public uint32 cbSubjectName;
	public PWSTR pwszSubjectName;
	public uint32 cbIssuerName;
	public PWSTR pwszIssuerName;
	public uint32 dwKeySize;
}

[CRepr]
public struct SecPkgContext_UiInfo
{
	public HWND hParentWindow;
}

[CRepr]
public struct SecPkgContext_EarlyStart
{
	public uint32 dwEarlyStartFlags;
}

[CRepr]
public struct SecPkgContext_KeyingMaterialInfo
{
	public uint16 cbLabel;
	public PSTR pszLabel;
	public uint16 cbContextValue;
	public uint8* pbContextValue;
	public uint32 cbKeyingMaterial;
}

[CRepr]
public struct SecPkgContext_KeyingMaterial
{
	public uint32 cbKeyingMaterial;
	public uint8* pbKeyingMaterial;
}

[CRepr]
public struct SecPkgContext_KeyingMaterial_Inproc
{
	public uint16 cbLabel;
	public PSTR pszLabel;
	public uint16 cbContextValue;
	public uint8* pbContextValue;
	public uint32 cbKeyingMaterial;
	public uint8* pbKeyingMaterial;
}

[CRepr]
public struct SecPkgContext_SrtpParameters
{
	public uint16 ProtectionProfile;
	public uint8 MasterKeyIdentifierSize;
	public uint8* MasterKeyIdentifier;
}

[CRepr]
public struct SecPkgContext_TokenBinding
{
	public uint8 MajorVersion;
	public uint8 MinorVersion;
	public uint16 KeyParametersSize;
	public uint8* KeyParameters;
}

[CRepr]
public struct SecPkgContext_CertificateValidationResult
{
	public uint32 dwChainErrorStatus;
	public HRESULT hrVerifyChainStatus;
}

[CRepr]
public struct _HMAPPER
{
}

[CRepr]
public struct SCHANNEL_CRED
{
	public uint32 dwVersion;
	public uint32 cCreds;
	public CERT_CONTEXT** paCred;
	public HCERTSTORE hRootStore;
	public uint32 cMappers;
	public _HMAPPER** aphMappers;
	public uint32 cSupportedAlgs;
	public uint32* palgSupportedAlgs;
	public uint32 grbitEnabledProtocols;
	public uint32 dwMinimumCipherStrength;
	public uint32 dwMaximumCipherStrength;
	public uint32 dwSessionLifespan;
	public SCHANNEL_CRED_FLAGS dwFlags;
	public uint32 dwCredFormat;
}

[CRepr]
public struct SEND_GENERIC_TLS_EXTENSION
{
	public uint16 ExtensionType;
	public uint16 HandshakeType;
	public uint32 Flags;
	public uint16 BufferSize;
	public uint8* Buffer mut => &Buffer_impl;
	private uint8[ANYSIZE_ARRAY] Buffer_impl;
}

[CRepr]
public struct TLS_EXTENSION_SUBSCRIPTION
{
	public uint16 ExtensionType;
	public uint16 HandshakeType;
}

[CRepr]
public struct SUBSCRIBE_GENERIC_TLS_EXTENSION
{
	public uint32 Flags;
	public uint32 SubscriptionsCount;
	public TLS_EXTENSION_SUBSCRIPTION* Subscriptions mut => &Subscriptions_impl;
	private TLS_EXTENSION_SUBSCRIPTION[ANYSIZE_ARRAY] Subscriptions_impl;
}

[CRepr]
public struct SCHANNEL_CERT_HASH
{
	public uint32 dwLength;
	public uint32 dwFlags;
	public uint hProv;
	public uint8[20] ShaHash;
}

[CRepr]
public struct SCHANNEL_CERT_HASH_STORE
{
	public uint32 dwLength;
	public uint32 dwFlags;
	public uint hProv;
	public uint8[20] ShaHash;
	public char16[128] pwszStoreName;
}

[CRepr]
public struct SCHANNEL_ALERT_TOKEN
{
	public uint32 dwTokenType;
	public SCHANNEL_ALERT_TOKEN_ALERT_TYPE dwAlertType;
	public uint32 dwAlertNumber;
}

[CRepr]
public struct SCHANNEL_SESSION_TOKEN
{
	public uint32 dwTokenType;
	public SCHANNEL_SESSION_TOKEN_FLAGS dwFlags;
}

[CRepr]
public struct SCHANNEL_CLIENT_SIGNATURE
{
	public uint32 cbLength;
	public uint32 aiHash;
	public uint32 cbHash;
	public uint8[36] HashValue;
	public uint8[20] CertThumbprint;
}

[CRepr]
public struct SSL_CREDENTIAL_CERTIFICATE
{
	public uint32 cbPrivateKey;
	public uint8* pPrivateKey;
	public uint32 cbCertificate;
	public uint8* pCertificate;
	public PSTR pszPassword;
}

[CRepr]
public struct SCH_CRED
{
	public uint32 dwVersion;
	public uint32 cCreds;
	public void** paSecret;
	public void** paPublic;
	public uint32 cMappers;
	public _HMAPPER** aphMappers;
}

[CRepr]
public struct SCH_CRED_SECRET_CAPI
{
	public uint32 dwType;
	public uint hProv;
}

[CRepr]
public struct SCH_CRED_SECRET_PRIVKEY
{
	public uint32 dwType;
	public uint8* pPrivateKey;
	public uint32 cbPrivateKey;
	public PSTR pszPassword;
}

[CRepr]
public struct SCH_CRED_PUBLIC_CERTCHAIN
{
	public uint32 dwType;
	public uint32 cbCertChain;
	public uint8* pCertChain;
}

[CRepr]
public struct PctPublicKey
{
	public uint32 Type;
	public uint32 cbKey;
	public uint8* pKey mut => &pKey_impl;
	private uint8[ANYSIZE_ARRAY] pKey_impl;
}

[CRepr]
public struct X509Certificate
{
	public uint32 Version;
	public uint32[4] SerialNumber;
	public uint32 SignatureAlgorithm;
	public FILETIME ValidFrom;
	public FILETIME ValidUntil;
	public PSTR pszIssuer;
	public PSTR pszSubject;
	public PctPublicKey* pPublicKey;
}

[CRepr]
public struct SCH_EXTENSION_DATA
{
	public uint16 ExtensionType;
	public uint8* pExtData;
	public uint32 cbExtData;
}

[CRepr]
public struct LOGON_HOURS
{
	public uint16 UnitsPerWeek;
	public uint8* LogonHours;
}

[CRepr]
public struct SR_SECURITY_DESCRIPTOR
{
	public uint32 Length;
	public uint8* SecurityDescriptor;
}

[CRepr, Packed(4)]
public struct USER_ALL_INFORMATION
{
	public LARGE_INTEGER LastLogon;
	public LARGE_INTEGER LastLogoff;
	public LARGE_INTEGER PasswordLastSet;
	public LARGE_INTEGER AccountExpires;
	public LARGE_INTEGER PasswordCanChange;
	public LARGE_INTEGER PasswordMustChange;
	public UNICODE_STRING UserName;
	public UNICODE_STRING FullName;
	public UNICODE_STRING HomeDirectory;
	public UNICODE_STRING HomeDirectoryDrive;
	public UNICODE_STRING ScriptPath;
	public UNICODE_STRING ProfilePath;
	public UNICODE_STRING AdminComment;
	public UNICODE_STRING WorkStations;
	public UNICODE_STRING UserComment;
	public UNICODE_STRING Parameters;
	public UNICODE_STRING LmPassword;
	public UNICODE_STRING NtPassword;
	public UNICODE_STRING PrivateData;
	public SR_SECURITY_DESCRIPTOR SecurityDescriptor;
	public uint32 UserId;
	public uint32 PrimaryGroupId;
	public uint32 UserAccountControl;
	public uint32 WhichFields;
	public LOGON_HOURS LogonHours;
	public uint16 BadPasswordCount;
	public uint16 LogonCount;
	public uint16 CountryCode;
	public uint16 CodePage;
	public BOOLEAN LmPasswordPresent;
	public BOOLEAN NtPasswordPresent;
	public BOOLEAN PasswordExpired;
	public BOOLEAN PrivateDataSensitive;
}

[CRepr]
public struct CLEAR_BLOCK
{
	public CHAR[8] data;
}

[CRepr]
public struct USER_SESSION_KEY
{
	public CYPHER_BLOCK[2] data;
}

[CRepr]
public struct NETLOGON_LOGON_IDENTITY_INFO
{
	public UNICODE_STRING LogonDomainName;
	public uint32 ParameterControl;
	public LARGE_INTEGER LogonId;
	public UNICODE_STRING UserName;
	public UNICODE_STRING Workstation;
}

[CRepr]
public struct NETLOGON_INTERACTIVE_INFO
{
	public NETLOGON_LOGON_IDENTITY_INFO Identity;
	public LM_OWF_PASSWORD LmOwfPassword;
	public LM_OWF_PASSWORD NtOwfPassword;
}

[CRepr]
public struct NETLOGON_SERVICE_INFO
{
	public NETLOGON_LOGON_IDENTITY_INFO Identity;
	public LM_OWF_PASSWORD LmOwfPassword;
	public LM_OWF_PASSWORD NtOwfPassword;
}

[CRepr]
public struct NETLOGON_NETWORK_INFO
{
	public NETLOGON_LOGON_IDENTITY_INFO Identity;
	public CLEAR_BLOCK LmChallenge;
	public STRING NtChallengeResponse;
	public STRING LmChallengeResponse;
}

[CRepr]
public struct NETLOGON_GENERIC_INFO
{
	public NETLOGON_LOGON_IDENTITY_INFO Identity;
	public UNICODE_STRING PackageName;
	public uint32 DataLength;
	public uint8* LogonData;
}

[CRepr]
public struct MSV1_0_VALIDATION_INFO
{
	public LARGE_INTEGER LogoffTime;
	public LARGE_INTEGER KickoffTime;
	public UNICODE_STRING LogonServer;
	public UNICODE_STRING LogonDomainName;
	public USER_SESSION_KEY SessionKey;
	public BOOLEAN Authoritative;
	public uint32 UserFlags;
	public uint32 WhichFields;
	public uint32 UserId;
}

[CRepr]
public struct TOKENBINDING_IDENTIFIER
{
	public uint8 keyType;
}

[CRepr]
public struct TOKENBINDING_RESULT_DATA
{
	public TOKENBINDING_TYPE bindingType;
	public uint32 identifierSize;
	public TOKENBINDING_IDENTIFIER* identifierData;
	public TOKENBINDING_EXTENSION_FORMAT extensionFormat;
	public uint32 extensionSize;
	public void* extensionData;
}

[CRepr]
public struct TOKENBINDING_RESULT_LIST
{
	public uint32 resultCount;
	public TOKENBINDING_RESULT_DATA* resultData;
}

[CRepr]
public struct TOKENBINDING_KEY_TYPES
{
	public uint32 keyCount;
	public TOKENBINDING_KEY_PARAMETERS_TYPE* keyType;
}

[CRepr]
public struct SL_LICENSING_STATUS
{
	public Guid SkuId;
	public SLLICENSINGSTATUS eStatus;
	public uint32 dwGraceTime;
	public uint32 dwTotalGraceDays;
	public HRESULT hrReason;
	public uint64 qwValidityExpiration;
}

[CRepr]
public struct SL_ACTIVATION_INFO_HEADER
{
	public uint32 cbSize;
	public SL_ACTIVATION_TYPE type;
}

[CRepr]
public struct SL_AD_ACTIVATION_INFO
{
	public SL_ACTIVATION_INFO_HEADER header;
	public PWSTR pwszProductKey;
	public PWSTR pwszActivationObjectName;
}

[CRepr]
public struct SL_NONGENUINE_UI_OPTIONS
{
	public uint32 cbSize;
	public Guid* pComponentId;
	public HRESULT hResultUI;
}

[CRepr]
public struct SL_SYSTEM_POLICY_INFORMATION
{
	public void*[2] Reserved1;
	public uint32[3] Reserved2;
}

#endregion

#region COM Types
[CRepr]struct ICcgDomainAuthCredentials : IUnknown
{
	public new const Guid IID = .(0x6ecda518, 0x2010, 0x4437, 0x8b, 0xc3, 0x46, 0xe7, 0x52, 0xb7, 0xb1, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pluginInput, PWSTR* domainName, PWSTR* username, PWSTR* password) GetPasswordCredentials;
	}


	public HRESULT GetPasswordCredentials(PWSTR pluginInput, PWSTR* domainName, PWSTR* username, PWSTR* password) mut => VT.[Friend]GetPasswordCredentials(&this, pluginInput, domainName, username, password);
}

#endregion

#region Functions
public static
{
	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaRegisterLogonProcess(STRING* LogonProcessName, LsaHandle* LsaHandle, uint32* SecurityMode);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaLogonUser(HANDLE LsaHandle, STRING* OriginName, SECURITY_LOGON_TYPE LogonType, uint32 AuthenticationPackage, void* AuthenticationInformation, uint32 AuthenticationInformationLength, TOKEN_GROUPS* LocalGroups, TOKEN_SOURCE* SourceContext, void** ProfileBuffer, uint32* ProfileBufferLength, LUID* LogonId, HANDLE* Token, QUOTA_LIMITS* Quotas, int32* SubStatus);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaLookupAuthenticationPackage(HANDLE LsaHandle, STRING* PackageName, uint32* AuthenticationPackage);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaFreeReturnBuffer(void* Buffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaCallAuthenticationPackage(HANDLE LsaHandle, uint32 AuthenticationPackage, void* ProtocolSubmitBuffer, uint32 SubmitBufferLength, void** ProtocolReturnBuffer, uint32* ReturnBufferLength, int32* ProtocolStatus);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaDeregisterLogonProcess(LsaHandle LsaHandle);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaConnectUntrusted(HANDLE* LsaHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaFreeMemory(void* Buffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaClose(void* ObjectHandle);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaEnumerateLogonSessions(uint32* LogonSessionCount, LUID** LogonSessionList);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaGetLogonSessionData(LUID* LogonId, SECURITY_LOGON_SESSION_DATA** ppLogonSessionData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaOpenPolicy(UNICODE_STRING* SystemName, OBJECT_ATTRIBUTES* ObjectAttributes, uint32 DesiredAccess, void** PolicyHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaSetCAPs(UNICODE_STRING* CAPDNs, uint32 CAPDNCount, uint32 Flags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaGetAppliedCAPIDs(UNICODE_STRING* SystemName, PSID** CAPIDs, uint32* CAPIDCount);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaQueryCAPs(PSID* CAPIDs, uint32 CAPIDCount, CENTRAL_ACCESS_POLICY** CAPs, uint32* CAPCount);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaQueryInformationPolicy(void* PolicyHandle, POLICY_INFORMATION_CLASS InformationClass, void** Buffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaSetInformationPolicy(void* PolicyHandle, POLICY_INFORMATION_CLASS InformationClass, void* Buffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaQueryDomainInformationPolicy(void* PolicyHandle, POLICY_DOMAIN_INFORMATION_CLASS InformationClass, void** Buffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaSetDomainInformationPolicy(void* PolicyHandle, POLICY_DOMAIN_INFORMATION_CLASS InformationClass, void* Buffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaRegisterPolicyChangeNotification(POLICY_NOTIFICATION_INFORMATION_CLASS InformationClass, HANDLE NotificationEventHandle);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaUnregisterPolicyChangeNotification(POLICY_NOTIFICATION_INFORMATION_CLASS InformationClass, HANDLE NotificationEventHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaEnumerateTrustedDomains(void* PolicyHandle, uint32* EnumerationContext, void** Buffer, uint32 PreferedMaximumLength, uint32* CountReturned);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaLookupNames(void* PolicyHandle, uint32 Count, UNICODE_STRING* Names, LSA_REFERENCED_DOMAIN_LIST** ReferencedDomains, LSA_TRANSLATED_SID** Sids);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaLookupNames2(void* PolicyHandle, uint32 Flags, uint32 Count, UNICODE_STRING* Names, LSA_REFERENCED_DOMAIN_LIST** ReferencedDomains, LSA_TRANSLATED_SID2** Sids);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaLookupSids(void* PolicyHandle, uint32 Count, PSID* Sids, LSA_REFERENCED_DOMAIN_LIST** ReferencedDomains, LSA_TRANSLATED_NAME** Names);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaLookupSids2(void* PolicyHandle, uint32 LookupOptions, uint32 Count, PSID* Sids, LSA_REFERENCED_DOMAIN_LIST** ReferencedDomains, LSA_TRANSLATED_NAME** Names);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaEnumerateAccountsWithUserRight(void* PolicyHandle, UNICODE_STRING* UserRight, void** Buffer, uint32* CountReturned);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaEnumerateAccountRights(void* PolicyHandle, PSID AccountSid, UNICODE_STRING** UserRights, uint32* CountOfRights);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaAddAccountRights(void* PolicyHandle, PSID AccountSid, UNICODE_STRING* UserRights, uint32 CountOfRights);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaRemoveAccountRights(void* PolicyHandle, PSID AccountSid, BOOLEAN AllRights, UNICODE_STRING* UserRights, uint32 CountOfRights);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaOpenTrustedDomainByName(void* PolicyHandle, UNICODE_STRING* TrustedDomainName, uint32 DesiredAccess, void** TrustedDomainHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaQueryTrustedDomainInfo(void* PolicyHandle, PSID TrustedDomainSid, TRUSTED_INFORMATION_CLASS InformationClass, void** Buffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaSetTrustedDomainInformation(void* PolicyHandle, PSID TrustedDomainSid, TRUSTED_INFORMATION_CLASS InformationClass, void* Buffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaDeleteTrustedDomain(void* PolicyHandle, PSID TrustedDomainSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaQueryTrustedDomainInfoByName(void* PolicyHandle, UNICODE_STRING* TrustedDomainName, TRUSTED_INFORMATION_CLASS InformationClass, void** Buffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaSetTrustedDomainInfoByName(void* PolicyHandle, UNICODE_STRING* TrustedDomainName, TRUSTED_INFORMATION_CLASS InformationClass, void* Buffer);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaEnumerateTrustedDomainsEx(void* PolicyHandle, uint32* EnumerationContext, void** Buffer, uint32 PreferedMaximumLength, uint32* CountReturned);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaCreateTrustedDomainEx(void* PolicyHandle, TRUSTED_DOMAIN_INFORMATION_EX* TrustedDomainInformation, TRUSTED_DOMAIN_AUTH_INFORMATION* AuthenticationInformation, uint32 DesiredAccess, void** TrustedDomainHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaQueryForestTrustInformation(void* PolicyHandle, UNICODE_STRING* TrustedDomainName, LSA_FOREST_TRUST_INFORMATION** ForestTrustInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaSetForestTrustInformation(void* PolicyHandle, UNICODE_STRING* TrustedDomainName, LSA_FOREST_TRUST_INFORMATION* ForestTrustInfo, BOOLEAN CheckOnly, LSA_FOREST_TRUST_COLLISION_INFORMATION** CollisionInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaStorePrivateData(void* PolicyHandle, UNICODE_STRING* KeyName, UNICODE_STRING* PrivateData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS LsaRetrievePrivateData(void* PolicyHandle, UNICODE_STRING* KeyName, UNICODE_STRING** PrivateData);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LsaNtStatusToWinError(NTSTATUS Status);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN SystemFunction036(void* RandomBuffer, uint32 RandomBufferLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS SystemFunction040(void* Memory, uint32 MemorySize, uint32 OptionFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS SystemFunction041(void* Memory, uint32 MemorySize, uint32 OptionFlags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditSetSystemPolicy(AUDIT_POLICY_INFORMATION* pAuditPolicy, uint32 dwPolicyCount);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditSetPerUserPolicy(PSID pSid, AUDIT_POLICY_INFORMATION* pAuditPolicy, uint32 dwPolicyCount);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditQuerySystemPolicy(Guid* pSubCategoryGuids, uint32 dwPolicyCount, AUDIT_POLICY_INFORMATION** ppAuditPolicy);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditQueryPerUserPolicy(PSID pSid, Guid* pSubCategoryGuids, uint32 dwPolicyCount, AUDIT_POLICY_INFORMATION** ppAuditPolicy);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditEnumeratePerUserPolicy(POLICY_AUDIT_SID_ARRAY** ppAuditSidArray);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditComputeEffectivePolicyBySid(PSID pSid, Guid* pSubCategoryGuids, uint32 dwPolicyCount, AUDIT_POLICY_INFORMATION** ppAuditPolicy);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditComputeEffectivePolicyByToken(HANDLE hTokenHandle, Guid* pSubCategoryGuids, uint32 dwPolicyCount, AUDIT_POLICY_INFORMATION** ppAuditPolicy);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditEnumerateCategories(Guid** ppAuditCategoriesArray, uint32* pdwCountReturned);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditEnumerateSubCategories(Guid* pAuditCategoryGuid, BOOLEAN bRetrieveAllSubCategories, Guid** ppAuditSubCategoriesArray, uint32* pdwCountReturned);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditLookupCategoryNameW(in Guid pAuditCategoryGuid, PWSTR* ppszCategoryName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditLookupCategoryNameA(in Guid pAuditCategoryGuid, PSTR* ppszCategoryName);
	public static BOOLEAN AuditLookupCategoryName(in Guid pAuditCategoryGuid, PSTR* ppszCategoryName) => AuditLookupCategoryNameA(pAuditCategoryGuid, ppszCategoryName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditLookupSubCategoryNameW(in Guid pAuditSubCategoryGuid, PWSTR* ppszSubCategoryName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditLookupSubCategoryNameA(in Guid pAuditSubCategoryGuid, PSTR* ppszSubCategoryName);
	public static BOOLEAN AuditLookupSubCategoryName(in Guid pAuditSubCategoryGuid, PSTR* ppszSubCategoryName) => AuditLookupSubCategoryNameA(pAuditSubCategoryGuid, ppszSubCategoryName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditLookupCategoryIdFromCategoryGuid(in Guid pAuditCategoryGuid, POLICY_AUDIT_EVENT_TYPE* pAuditCategoryId);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditLookupCategoryGuidFromCategoryId(POLICY_AUDIT_EVENT_TYPE AuditCategoryId, Guid* pAuditCategoryGuid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditSetSecurity(uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditQuerySecurity(uint32 SecurityInformation, PSECURITY_DESCRIPTOR* ppSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditSetGlobalSaclW(PWSTR ObjectTypeName, ACL* Acl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditSetGlobalSaclA(PSTR ObjectTypeName, ACL* Acl);
	public static BOOLEAN AuditSetGlobalSacl(PSTR ObjectTypeName, ACL* Acl) => AuditSetGlobalSaclA(ObjectTypeName, Acl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditQueryGlobalSaclW(PWSTR ObjectTypeName, ACL** Acl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN AuditQueryGlobalSaclA(PSTR ObjectTypeName, ACL** Acl);
	public static BOOLEAN AuditQueryGlobalSacl(PSTR ObjectTypeName, ACL** Acl) => AuditQueryGlobalSaclA(ObjectTypeName, Acl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void AuditFree(void* Buffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AcquireCredentialsHandleW(PWSTR pszPrincipal, PWSTR pszPackage, SECPKG_CRED fCredentialUse, void* pvLogonId, void* pAuthData, SEC_GET_KEY_FN pGetKeyFn, void* pvGetKeyArgument, SecHandle* phCredential, LARGE_INTEGER* ptsExpiry);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AcquireCredentialsHandleA(PSTR pszPrincipal, PSTR pszPackage, SECPKG_CRED fCredentialUse, void* pvLogonId, void* pAuthData, SEC_GET_KEY_FN pGetKeyFn, void* pvGetKeyArgument, SecHandle* phCredential, LARGE_INTEGER* ptsExpiry);
	public static HRESULT AcquireCredentialsHandle(PSTR pszPrincipal, PSTR pszPackage, SECPKG_CRED fCredentialUse, void* pvLogonId, void* pAuthData, SEC_GET_KEY_FN pGetKeyFn, void* pvGetKeyArgument, SecHandle* phCredential, LARGE_INTEGER* ptsExpiry) => AcquireCredentialsHandleA(pszPrincipal, pszPackage, fCredentialUse, pvLogonId, pAuthData, pGetKeyFn, pvGetKeyArgument, phCredential, ptsExpiry);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FreeCredentialsHandle(SecHandle* phCredential);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddCredentialsW(SecHandle* hCredentials, PWSTR pszPrincipal, PWSTR pszPackage, uint32 fCredentialUse, void* pAuthData, SEC_GET_KEY_FN pGetKeyFn, void* pvGetKeyArgument, LARGE_INTEGER* ptsExpiry);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddCredentialsA(SecHandle* hCredentials, PSTR pszPrincipal, PSTR pszPackage, uint32 fCredentialUse, void* pAuthData, SEC_GET_KEY_FN pGetKeyFn, void* pvGetKeyArgument, LARGE_INTEGER* ptsExpiry);
	public static HRESULT AddCredentials(SecHandle* hCredentials, PSTR pszPrincipal, PSTR pszPackage, uint32 fCredentialUse, void* pAuthData, SEC_GET_KEY_FN pGetKeyFn, void* pvGetKeyArgument, LARGE_INTEGER* ptsExpiry) => AddCredentialsA(hCredentials, pszPrincipal, pszPackage, fCredentialUse, pAuthData, pGetKeyFn, pvGetKeyArgument, ptsExpiry);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ChangeAccountPasswordW(uint16* pszPackageName, uint16* pszDomainName, uint16* pszAccountName, uint16* pszOldPassword, uint16* pszNewPassword, BOOLEAN bImpersonating, uint32 dwReserved, SecBufferDesc* pOutput);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ChangeAccountPasswordA(int8* pszPackageName, int8* pszDomainName, int8* pszAccountName, int8* pszOldPassword, int8* pszNewPassword, BOOLEAN bImpersonating, uint32 dwReserved, SecBufferDesc* pOutput);
	public static HRESULT ChangeAccountPassword(int8* pszPackageName, int8* pszDomainName, int8* pszAccountName, int8* pszOldPassword, int8* pszNewPassword, BOOLEAN bImpersonating, uint32 dwReserved, SecBufferDesc* pOutput) => ChangeAccountPasswordA(pszPackageName, pszDomainName, pszAccountName, pszOldPassword, pszNewPassword, bImpersonating, dwReserved, pOutput);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitializeSecurityContextW(SecHandle* phCredential, SecHandle* phContext, uint16* pszTargetName, ISC_REQ_FLAGS fContextReq, uint32 Reserved1, uint32 TargetDataRep, SecBufferDesc* pInput, uint32 Reserved2, SecHandle* phNewContext, SecBufferDesc* pOutput, uint32* pfContextAttr, LARGE_INTEGER* ptsExpiry);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitializeSecurityContextA(SecHandle* phCredential, SecHandle* phContext, int8* pszTargetName, ISC_REQ_FLAGS fContextReq, uint32 Reserved1, uint32 TargetDataRep, SecBufferDesc* pInput, uint32 Reserved2, SecHandle* phNewContext, SecBufferDesc* pOutput, uint32* pfContextAttr, LARGE_INTEGER* ptsExpiry);
	public static HRESULT InitializeSecurityContext(SecHandle* phCredential, SecHandle* phContext, int8* pszTargetName, ISC_REQ_FLAGS fContextReq, uint32 Reserved1, uint32 TargetDataRep, SecBufferDesc* pInput, uint32 Reserved2, SecHandle* phNewContext, SecBufferDesc* pOutput, uint32* pfContextAttr, LARGE_INTEGER* ptsExpiry) => InitializeSecurityContextA(phCredential, phContext, pszTargetName, fContextReq, Reserved1, TargetDataRep, pInput, Reserved2, phNewContext, pOutput, pfContextAttr, ptsExpiry);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AcceptSecurityContext(SecHandle* phCredential, SecHandle* phContext, SecBufferDesc* pInput, ASC_REQ_FLAGS fContextReq, uint32 TargetDataRep, SecHandle* phNewContext, SecBufferDesc* pOutput, uint32* pfContextAttr, LARGE_INTEGER* ptsExpiry);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CompleteAuthToken(SecHandle* phContext, SecBufferDesc* pToken);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ImpersonateSecurityContext(SecHandle* phContext);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RevertSecurityContext(SecHandle* phContext);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QuerySecurityContextToken(SecHandle* phContext, void** Token);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeleteSecurityContext(SecHandle* phContext);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ApplyControlToken(SecHandle* phContext, SecBufferDesc* pInput);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryContextAttributesW(SecHandle* phContext, SECPKG_ATTR ulAttribute, void* pBuffer);

	[Import("SspiCli.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryContextAttributesExW(SecHandle* phContext, SECPKG_ATTR ulAttribute, void* pBuffer, uint32 cbBuffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryContextAttributesA(SecHandle* phContext, SECPKG_ATTR ulAttribute, void* pBuffer);
	public static HRESULT QueryContextAttributes(SecHandle* phContext, SECPKG_ATTR ulAttribute, void* pBuffer) => QueryContextAttributesA(phContext, ulAttribute, pBuffer);

	[Import("SspiCli.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryContextAttributesExA(SecHandle* phContext, SECPKG_ATTR ulAttribute, void* pBuffer, uint32 cbBuffer);
	public static HRESULT QueryContextAttributesEx(SecHandle* phContext, SECPKG_ATTR ulAttribute, void* pBuffer, uint32 cbBuffer) => QueryContextAttributesExA(phContext, ulAttribute, pBuffer, cbBuffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetContextAttributesW(SecHandle* phContext, SECPKG_ATTR ulAttribute, void* pBuffer, uint32 cbBuffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetContextAttributesA(SecHandle* phContext, SECPKG_ATTR ulAttribute, void* pBuffer, uint32 cbBuffer);
	public static HRESULT SetContextAttributes(SecHandle* phContext, SECPKG_ATTR ulAttribute, void* pBuffer, uint32 cbBuffer) => SetContextAttributesA(phContext, ulAttribute, pBuffer, cbBuffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryCredentialsAttributesW(SecHandle* phCredential, uint32 ulAttribute, void* pBuffer);

	[Import("SspiCli.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryCredentialsAttributesExW(SecHandle* phCredential, uint32 ulAttribute, void* pBuffer, uint32 cbBuffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryCredentialsAttributesA(SecHandle* phCredential, uint32 ulAttribute, void* pBuffer);
	public static HRESULT QueryCredentialsAttributes(SecHandle* phCredential, uint32 ulAttribute, void* pBuffer) => QueryCredentialsAttributesA(phCredential, ulAttribute, pBuffer);

	[Import("SspiCli.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QueryCredentialsAttributesExA(SecHandle* phCredential, uint32 ulAttribute, void* pBuffer, uint32 cbBuffer);
	public static HRESULT QueryCredentialsAttributesEx(SecHandle* phCredential, uint32 ulAttribute, void* pBuffer, uint32 cbBuffer) => QueryCredentialsAttributesExA(phCredential, ulAttribute, pBuffer, cbBuffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetCredentialsAttributesW(SecHandle* phCredential, uint32 ulAttribute, void* pBuffer, uint32 cbBuffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetCredentialsAttributesA(SecHandle* phCredential, uint32 ulAttribute, void* pBuffer, uint32 cbBuffer);
	public static HRESULT SetCredentialsAttributes(SecHandle* phCredential, uint32 ulAttribute, void* pBuffer, uint32 cbBuffer) => SetCredentialsAttributesA(phCredential, ulAttribute, pBuffer, cbBuffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FreeContextBuffer(void* pvContextBuffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MakeSignature(SecHandle* phContext, uint32 fQOP, SecBufferDesc* pMessage, uint32 MessageSeqNo);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT VerifySignature(SecHandle* phContext, SecBufferDesc* pMessage, uint32 MessageSeqNo, uint32* pfQOP);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EncryptMessage(SecHandle* phContext, uint32 fQOP, SecBufferDesc* pMessage, uint32 MessageSeqNo);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DecryptMessage(SecHandle* phContext, SecBufferDesc* pMessage, uint32 MessageSeqNo, uint32* pfQOP);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EnumerateSecurityPackagesW(uint32* pcPackages, SecPkgInfoW** ppPackageInfo);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT EnumerateSecurityPackagesA(uint32* pcPackages, SecPkgInfoA** ppPackageInfo);
	public static HRESULT EnumerateSecurityPackages(uint32* pcPackages, SecPkgInfoA** ppPackageInfo) => EnumerateSecurityPackagesA(pcPackages, ppPackageInfo);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QuerySecurityPackageInfoW(PWSTR pszPackageName, SecPkgInfoW** ppPackageInfo);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QuerySecurityPackageInfoA(PSTR pszPackageName, SecPkgInfoA** ppPackageInfo);
	public static HRESULT QuerySecurityPackageInfo(PSTR pszPackageName, SecPkgInfoA** ppPackageInfo) => QuerySecurityPackageInfoA(pszPackageName, ppPackageInfo);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ExportSecurityContext(SecHandle* phContext, EXPORT_SECURITY_CONTEXT_FLAGS fFlags, SecBuffer* pPackedContext, void** pToken);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ImportSecurityContextW(PWSTR pszPackage, SecBuffer* pPackedContext, void* Token, SecHandle* phContext);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ImportSecurityContextA(PSTR pszPackage, SecBuffer* pPackedContext, void* Token, SecHandle* phContext);
	public static HRESULT ImportSecurityContext(PSTR pszPackage, SecBuffer* pPackedContext, void* Token, SecHandle* phContext) => ImportSecurityContextA(pszPackage, pPackedContext, Token, phContext);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SecurityFunctionTableA* InitSecurityInterfaceA();
	public static SecurityFunctionTableA* InitSecurityInterface() => InitSecurityInterfaceA();

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SecurityFunctionTableW* InitSecurityInterfaceW();

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslEnumerateProfilesA(PSTR* ProfileList, uint32* ProfileCount);
	public static HRESULT SaslEnumerateProfiles(PSTR* ProfileList, uint32* ProfileCount) => SaslEnumerateProfilesA(ProfileList, ProfileCount);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslEnumerateProfilesW(PWSTR* ProfileList, uint32* ProfileCount);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslGetProfilePackageA(PSTR ProfileName, SecPkgInfoA** PackageInfo);
	public static HRESULT SaslGetProfilePackage(PSTR ProfileName, SecPkgInfoA** PackageInfo) => SaslGetProfilePackageA(ProfileName, PackageInfo);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslGetProfilePackageW(PWSTR ProfileName, SecPkgInfoW** PackageInfo);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslIdentifyPackageA(SecBufferDesc* pInput, SecPkgInfoA** PackageInfo);
	public static HRESULT SaslIdentifyPackage(SecBufferDesc* pInput, SecPkgInfoA** PackageInfo) => SaslIdentifyPackageA(pInput, PackageInfo);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslIdentifyPackageW(SecBufferDesc* pInput, SecPkgInfoW** PackageInfo);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslInitializeSecurityContextW(SecHandle* phCredential, SecHandle* phContext, PWSTR pszTargetName, ISC_REQ_FLAGS fContextReq, uint32 Reserved1, uint32 TargetDataRep, SecBufferDesc* pInput, uint32 Reserved2, SecHandle* phNewContext, SecBufferDesc* pOutput, uint32* pfContextAttr, LARGE_INTEGER* ptsExpiry);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslInitializeSecurityContextA(SecHandle* phCredential, SecHandle* phContext, PSTR pszTargetName, ISC_REQ_FLAGS fContextReq, uint32 Reserved1, uint32 TargetDataRep, SecBufferDesc* pInput, uint32 Reserved2, SecHandle* phNewContext, SecBufferDesc* pOutput, uint32* pfContextAttr, LARGE_INTEGER* ptsExpiry);
	public static HRESULT SaslInitializeSecurityContext(SecHandle* phCredential, SecHandle* phContext, PSTR pszTargetName, ISC_REQ_FLAGS fContextReq, uint32 Reserved1, uint32 TargetDataRep, SecBufferDesc* pInput, uint32 Reserved2, SecHandle* phNewContext, SecBufferDesc* pOutput, uint32* pfContextAttr, LARGE_INTEGER* ptsExpiry) => SaslInitializeSecurityContextA(phCredential, phContext, pszTargetName, fContextReq, Reserved1, TargetDataRep, pInput, Reserved2, phNewContext, pOutput, pfContextAttr, ptsExpiry);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslAcceptSecurityContext(SecHandle* phCredential, SecHandle* phContext, SecBufferDesc* pInput, ASC_REQ_FLAGS fContextReq, uint32 TargetDataRep, SecHandle* phNewContext, SecBufferDesc* pOutput, uint32* pfContextAttr, LARGE_INTEGER* ptsExpiry);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslSetContextOption(SecHandle* ContextHandle, uint32 Option, void* Value, uint32 Size);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SaslGetContextOption(SecHandle* ContextHandle, uint32 Option, void* Value, uint32 Size, uint32* Needed);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SspiPromptForCredentialsW(PWSTR pszTargetName, void* pUiInfo, uint32 dwAuthError, PWSTR pszPackage, void* pInputAuthIdentity, void** ppAuthIdentity, int32* pfSave, uint32 dwFlags);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SspiPromptForCredentialsA(PSTR pszTargetName, void* pUiInfo, uint32 dwAuthError, PSTR pszPackage, void* pInputAuthIdentity, void** ppAuthIdentity, int32* pfSave, uint32 dwFlags);
	public static uint32 SspiPromptForCredentials(PSTR pszTargetName, void* pUiInfo, uint32 dwAuthError, PSTR pszPackage, void* pInputAuthIdentity, void** ppAuthIdentity, int32* pfSave, uint32 dwFlags) => SspiPromptForCredentialsA(pszTargetName, pUiInfo, dwAuthError, pszPackage, pInputAuthIdentity, ppAuthIdentity, pfSave, dwFlags);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiPrepareForCredRead(void* AuthIdentity, PWSTR pszTargetName, uint32* pCredmanCredentialType, PWSTR* ppszCredmanTargetName);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiPrepareForCredWrite(void* AuthIdentity, PWSTR pszTargetName, uint32* pCredmanCredentialType, PWSTR* ppszCredmanTargetName, PWSTR* ppszCredmanUserName, uint8** ppCredentialBlob, uint32* pCredentialBlobSize);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiEncryptAuthIdentity(void* AuthData);

	[Import("SspiCli.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiEncryptAuthIdentityEx(uint32 Options, void* AuthData);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiDecryptAuthIdentity(void* EncryptedAuthData);

	[Import("SspiCli.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiDecryptAuthIdentityEx(uint32 Options, void* EncryptedAuthData);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN SspiIsAuthIdentityEncrypted(void* EncryptedAuthData);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiEncodeAuthIdentityAsStrings(void* pAuthIdentity, PWSTR* ppszUserName, PWSTR* ppszDomainName, PWSTR* ppszPackedCredentialsString);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiValidateAuthIdentity(void* AuthData);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiCopyAuthIdentity(void* AuthData, void** AuthDataCopy);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SspiFreeAuthIdentity(void* AuthData);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SspiZeroAuthIdentity(void* AuthData);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SspiLocalFree(void* DataBuffer);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiEncodeStringsAsAuthIdentity(PWSTR pszUserName, PWSTR pszDomainName, PWSTR pszPackedCredentialsString, void** ppAuthIdentity);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiCompareAuthIdentities(void* AuthIdentity1, void* AuthIdentity2, BOOLEAN* SameSuppliedUser, BOOLEAN* SameSuppliedIdentity);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiMarshalAuthIdentity(void* AuthIdentity, uint32* AuthIdentityLength, int8** AuthIdentityByteArray);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiUnmarshalAuthIdentity(uint32 AuthIdentityLength, PSTR AuthIdentityByteArray, void** ppAuthIdentity);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN SspiIsPromptingNeeded(uint32 ErrorOrNtStatus);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiGetTargetHostName(PWSTR pszTargetName, PWSTR* pszHostName);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SspiExcludePackage(void* AuthIdentity, PWSTR pszPackageName, void** ppNewAuthIdentity);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddSecurityPackageA(PSTR pszPackageName, SECURITY_PACKAGE_OPTIONS* pOptions);
	public static HRESULT AddSecurityPackage(PSTR pszPackageName, SECURITY_PACKAGE_OPTIONS* pOptions) => AddSecurityPackageA(pszPackageName, pOptions);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddSecurityPackageW(PWSTR pszPackageName, SECURITY_PACKAGE_OPTIONS* pOptions);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeleteSecurityPackageA(PSTR pszPackageName);
	public static HRESULT DeleteSecurityPackage(PSTR pszPackageName) => DeleteSecurityPackageA(pszPackageName);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeleteSecurityPackageW(PWSTR pszPackageName);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS CredMarshalTargetInfo(CREDENTIAL_TARGET_INFORMATIONW* InTargetInfo, uint16** Buffer, uint32* BufferSize);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS CredUnmarshalTargetInfo(uint16* Buffer, uint32 BufferSize, CREDENTIAL_TARGET_INFORMATIONW** RetTargetInfo, uint32* RetActualSize);

	[Import("SCHANNEL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SslEmptyCacheA(PSTR pszTargetName, uint32 dwFlags);
	public static BOOL SslEmptyCache(PSTR pszTargetName, uint32 dwFlags) => SslEmptyCacheA(pszTargetName, dwFlags);

	[Import("SCHANNEL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SslEmptyCacheW(PWSTR pszTargetName, uint32 dwFlags);

	[Import("SCHANNEL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SslGenerateRandomBits(uint8* pRandomData, int32 cRandomData);

	[Import("SCHANNEL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SslCrackCertificate(uint8* pbCertificate, uint32 cbCertificate, uint32 dwFlags, X509Certificate** ppCertificate);

	[Import("SCHANNEL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SslFreeCertificate(X509Certificate* pCertificate);

	[Import("SCHANNEL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SslGetMaximumKeySize(uint32 Reserved);

	[Import("SCHANNEL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SslGetServerIdentity(uint8* ClientHello, uint32 ClientHelloSize, uint8** ServerIdentity, uint32* ServerIdentitySize, uint32 Flags);

	[Import("SCHANNEL.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SslGetExtensions(uint8* clientHello, uint32 clientHelloByteSize, SCH_EXTENSION_DATA* genericExtensions, uint8 genericExtensionsCount, uint32* bytesToRead, SchGetExtensionsOptions flags);

	[Import("TOKENBINDING.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TokenBindingGenerateBinding(TOKENBINDING_KEY_PARAMETERS_TYPE keyType, PWSTR targetURL, TOKENBINDING_TYPE bindingType, void* tlsEKM, uint32 tlsEKMSize, TOKENBINDING_EXTENSION_FORMAT extensionFormat, void* extensionData, void** tokenBinding, uint32* tokenBindingSize, TOKENBINDING_RESULT_DATA** resultData);

	[Import("TOKENBINDING.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TokenBindingGenerateMessage(void** tokenBindings, uint32* tokenBindingsSize, uint32 tokenBindingsCount, void** tokenBindingMessage, uint32* tokenBindingMessageSize);

	[Import("TOKENBINDING.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TokenBindingVerifyMessage(void* tokenBindingMessage, uint32 tokenBindingMessageSize, TOKENBINDING_KEY_PARAMETERS_TYPE keyType, void* tlsEKM, uint32 tlsEKMSize, TOKENBINDING_RESULT_LIST** resultList);

	[Import("TOKENBINDING.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TokenBindingGetKeyTypesClient(TOKENBINDING_KEY_TYPES** keyTypes);

	[Import("TOKENBINDING.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TokenBindingGetKeyTypesServer(TOKENBINDING_KEY_TYPES** keyTypes);

	[Import("TOKENBINDING.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TokenBindingDeleteBinding(PWSTR targetURL);

	[Import("TOKENBINDING.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TokenBindingDeleteAllBindings();

	[Import("TOKENBINDING.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TokenBindingGenerateID(TOKENBINDING_KEY_PARAMETERS_TYPE keyType, void* publicKey, uint32 publicKeySize, TOKENBINDING_RESULT_DATA** resultData);

	[Import("TOKENBINDING.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TokenBindingGenerateIDForUri(TOKENBINDING_KEY_PARAMETERS_TYPE keyType, PWSTR targetUri, TOKENBINDING_RESULT_DATA** resultData);

	[Import("TOKENBINDING.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TokenBindingGetHighestSupportedVersion(uint8* majorVersion, uint8* minorVersion);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN GetUserNameExA(EXTENDED_NAME_FORMAT NameFormat, uint8* lpNameBuffer, uint32* nSize);
	public static BOOLEAN GetUserNameEx(EXTENDED_NAME_FORMAT NameFormat, uint8* lpNameBuffer, uint32* nSize) => GetUserNameExA(NameFormat, lpNameBuffer, nSize);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN GetUserNameExW(EXTENDED_NAME_FORMAT NameFormat, char16* lpNameBuffer, uint32* nSize);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN GetComputerObjectNameA(EXTENDED_NAME_FORMAT NameFormat, uint8* lpNameBuffer, uint32* nSize);
	public static BOOLEAN GetComputerObjectName(EXTENDED_NAME_FORMAT NameFormat, uint8* lpNameBuffer, uint32* nSize) => GetComputerObjectNameA(NameFormat, lpNameBuffer, nSize);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN GetComputerObjectNameW(EXTENDED_NAME_FORMAT NameFormat, char16* lpNameBuffer, uint32* nSize);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN TranslateNameA(PSTR lpAccountName, EXTENDED_NAME_FORMAT AccountNameFormat, EXTENDED_NAME_FORMAT DesiredNameFormat, uint8* lpTranslatedName, uint32* nSize);
	public static BOOLEAN TranslateName(PSTR lpAccountName, EXTENDED_NAME_FORMAT AccountNameFormat, EXTENDED_NAME_FORMAT DesiredNameFormat, uint8* lpTranslatedName, uint32* nSize) => TranslateNameA(lpAccountName, AccountNameFormat, DesiredNameFormat, lpTranslatedName, nSize);

	[Import("SECUR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN TranslateNameW(PWSTR lpAccountName, EXTENDED_NAME_FORMAT AccountNameFormat, EXTENDED_NAME_FORMAT DesiredNameFormat, char16* lpTranslatedName, uint32* nSize);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLOpen(void** phSLC);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLClose(void* hSLC);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLInstallProofOfPurchase(void* hSLC, PWSTR pwszPKeyAlgorithm, PWSTR pwszPKeyString, uint32 cbPKeySpecificData, uint8* pbPKeySpecificData, Guid* pPkeyId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLUninstallProofOfPurchase(void* hSLC, in Guid pPKeyId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLInstallLicense(void* hSLC, uint32 cbLicenseBlob, uint8* pbLicenseBlob, Guid* pLicenseFileId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLUninstallLicense(void* hSLC, in Guid pLicenseFileId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLConsumeRight(void* hSLC, in Guid pAppId, Guid* pProductSkuId, PWSTR pwszRightName, void* pvReserved);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetProductSkuInformation(void* hSLC, in Guid pProductSkuId, PWSTR pwszValueName, SLDATATYPE* peDataType, uint32* pcbValue, uint8** ppbValue);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetPKeyInformation(void* hSLC, in Guid pPKeyId, PWSTR pwszValueName, SLDATATYPE* peDataType, uint32* pcbValue, uint8** ppbValue);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetLicenseInformation(void* hSLC, in Guid pSLLicenseId, PWSTR pwszValueName, SLDATATYPE* peDataType, uint32* pcbValue, uint8** ppbValue);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetLicensingStatusInformation(void* hSLC, Guid* pAppID, Guid* pProductSkuId, PWSTR pwszRightName, uint32* pnStatusCount, SL_LICENSING_STATUS** ppLicensingStatus);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetPolicyInformation(void* hSLC, PWSTR pwszValueName, SLDATATYPE* peDataType, uint32* pcbValue, uint8** ppbValue);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetPolicyInformationDWORD(void* hSLC, PWSTR pwszValueName, uint32* pdwValue);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetServiceInformation(void* hSLC, PWSTR pwszValueName, SLDATATYPE* peDataType, uint32* pcbValue, uint8** ppbValue);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetApplicationInformation(void* hSLC, in Guid pApplicationId, PWSTR pwszValueName, SLDATATYPE* peDataType, uint32* pcbValue, uint8** ppbValue);

	[Import("slcext.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLActivateProduct(void* hSLC, in Guid pProductSkuId, uint32 cbAppSpecificData, void* pvAppSpecificData, SL_ACTIVATION_INFO_HEADER* pActivationInfo, PWSTR pwszProxyServer, uint16 wProxyPort);

	[Import("slcext.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetServerStatus(PWSTR pwszServerURL, PWSTR pwszAcquisitionType, PWSTR pwszProxyServer, uint16 wProxyPort, HRESULT* phrStatus);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGenerateOfflineInstallationId(void* hSLC, in Guid pProductSkuId, PWSTR* ppwszInstallationId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGenerateOfflineInstallationIdEx(void* hSLC, Guid* pProductSkuId, SL_ACTIVATION_INFO_HEADER* pActivationInfo, PWSTR* ppwszInstallationId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLDepositOfflineConfirmationId(void* hSLC, in Guid pProductSkuId, PWSTR pwszInstallationId, PWSTR pwszConfirmationId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLDepositOfflineConfirmationIdEx(void* hSLC, Guid* pProductSkuId, SL_ACTIVATION_INFO_HEADER* pActivationInfo, PWSTR pwszInstallationId, PWSTR pwszConfirmationId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetPKeyId(void* hSLC, PWSTR pwszPKeyAlgorithm, PWSTR pwszPKeyString, uint32 cbPKeySpecificData, uint8* pbPKeySpecificData, Guid* pPKeyId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetInstalledProductKeyIds(void* hSLC, in Guid pProductSkuId, uint32* pnProductKeyIds, Guid** ppProductKeyIds);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLSetCurrentProductKey(void* hSLC, in Guid pProductSkuId, in Guid pProductKeyId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetSLIDList(void* hSLC, SLIDTYPE eQueryIdType, Guid* pQueryId, SLIDTYPE eReturnIdType, uint32* pnReturnIds, Guid** ppReturnIds);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetLicenseFileId(void* hSLC, uint32 cbLicenseBlob, uint8* pbLicenseBlob, Guid* pLicenseFileId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetLicense(void* hSLC, in Guid pLicenseFileId, uint32* pcbLicenseFile, uint8** ppbLicenseFile);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLFireEvent(void* hSLC, PWSTR pwszEventId, in Guid pApplicationId);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLRegisterEvent(void* hSLC, PWSTR pwszEventId, in Guid pApplicationId, HANDLE hEvent);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLUnregisterEvent(void* hSLC, PWSTR pwszEventId, in Guid pApplicationId, HANDLE hEvent);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetWindowsInformation(PWSTR pwszValueName, SLDATATYPE* peDataType, uint32* pcbValue, uint8** ppbValue);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetWindowsInformationDWORD(PWSTR pwszValueName, uint32* pdwValue);

	[Import("SLWGA.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLIsGenuineLocal(in Guid pAppId, SL_GENUINE_STATE* pGenuineState, SL_NONGENUINE_UI_OPTIONS* pUIOptions);

	[Import("slcext.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLAcquireGenuineTicket(void** ppTicketBlob, uint32* pcbTicketBlob, PWSTR pwszTemplateId, PWSTR pwszServerUrl, PWSTR pwszClientToken);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLSetGenuineInformation(in Guid pQueryId, PWSTR pwszValueName, SLDATATYPE eDataType, uint32 cbValue, uint8* pbValue);

	[Import("slcext.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetReferralInformation(void* hSLC, SLREFERRALTYPE eReferralType, in Guid pSkuOrAppId, PWSTR pwszValueName, PWSTR* ppwszValue);

	[Import("SLC.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLGetGenuineInformation(in Guid pQueryId, PWSTR pwszValueName, SLDATATYPE* peDataType, uint32* pcbValue, uint8** ppbValue);

	[Import("api-ms-win-core-slapi-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SLQueryLicenseValueFromApp(PWSTR valueName, uint32* valueType, void* dataBuffer, uint32 dataSize, uint32* resultDataSize);

}
#endregion
