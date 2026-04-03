using Win32.Security.Cryptography;
using Win32.Foundation;
using Win32.System.Com;
using Win32.Data.Xml.MsXml;
using System;

namespace Win32.Security.ExtensibleAuthenticationProtocol;

#region Constants
public static
{
	public const uint32 FACILITY_EAP_MESSAGE = 2114;
	public const int32 EAP_GROUP_MASK = 65280;
	public const int32 EAP_E_EAPHOST_FIRST = -2143158272;
	public const int32 EAP_E_EAPHOST_LAST = -2143158017;
	public const int32 EAP_I_EAPHOST_FIRST = -2143158272;
	public const int32 EAP_I_EAPHOST_LAST = -2143158017;
	public const uint32 EAP_E_CERT_STORE_INACCESSIBLE = 2151809040;
	public const uint32 EAP_E_EAPHOST_METHOD_NOT_INSTALLED = 2151809041;
	public const uint32 EAP_E_EAPHOST_THIRDPARTY_METHOD_HOST_RESET = 2151809042;
	public const uint32 EAP_E_EAPHOST_EAPQEC_INACCESSIBLE = 2151809043;
	public const uint32 EAP_E_EAPHOST_IDENTITY_UNKNOWN = 2151809044;
	public const uint32 EAP_E_AUTHENTICATION_FAILED = 2151809045;
	public const uint32 EAP_I_EAPHOST_EAP_NEGOTIATION_FAILED = 1078067222;
	public const uint32 EAP_E_EAPHOST_METHOD_INVALID_PACKET = 2151809047;
	public const uint32 EAP_E_EAPHOST_REMOTE_INVALID_PACKET = 2151809048;
	public const uint32 EAP_E_EAPHOST_XML_MALFORMED = 2151809049;
	public const uint32 EAP_E_METHOD_CONFIG_DOES_NOT_SUPPORT_SSO = 2151809050;
	public const uint32 EAP_E_EAPHOST_METHOD_OPERATION_NOT_SUPPORTED = 2151809056;
	public const int32 EAP_E_USER_FIRST = -2143158016;
	public const int32 EAP_E_USER_LAST = -2143157761;
	public const int32 EAP_I_USER_FIRST = 1078067456;
	public const int32 EAP_I_USER_LAST = 1078067711;
	public const uint32 EAP_E_USER_CERT_NOT_FOUND = 2151809280;
	public const uint32 EAP_E_USER_CERT_INVALID = 2151809281;
	public const uint32 EAP_E_USER_CERT_EXPIRED = 2151809282;
	public const uint32 EAP_E_USER_CERT_REVOKED = 2151809283;
	public const uint32 EAP_E_USER_CERT_OTHER_ERROR = 2151809284;
	public const uint32 EAP_E_USER_CERT_REJECTED = 2151809285;
	public const uint32 EAP_I_USER_ACCOUNT_OTHER_ERROR = 1078067472;
	public const uint32 EAP_E_USER_CREDENTIALS_REJECTED = 2151809297;
	public const uint32 EAP_E_USER_NAME_PASSWORD_REJECTED = 2151809298;
	public const uint32 EAP_E_NO_SMART_CARD_READER = 2151809299;
	public const int32 EAP_E_SERVER_FIRST = -2143157760;
	public const int32 EAP_E_SERVER_LAST = -2143157505;
	public const uint32 EAP_E_SERVER_CERT_NOT_FOUND = 2151809536;
	public const uint32 EAP_E_SERVER_CERT_INVALID = 2151809537;
	public const uint32 EAP_E_SERVER_CERT_EXPIRED = 2151809538;
	public const uint32 EAP_E_SERVER_CERT_REVOKED = 2151809539;
	public const uint32 EAP_E_SERVER_CERT_OTHER_ERROR = 2151809540;
	public const int32 EAP_E_USER_ROOT_CERT_FIRST = -2143157504;
	public const int32 EAP_E_USER_ROOT_CERT_LAST = -2143157249;
	public const uint32 EAP_E_USER_ROOT_CERT_NOT_FOUND = 2151809792;
	public const uint32 EAP_E_USER_ROOT_CERT_INVALID = 2151809793;
	public const uint32 EAP_E_USER_ROOT_CERT_EXPIRED = 2151809794;
	public const int32 EAP_E_SERVER_ROOT_CERT_FIRST = -2143157248;
	public const int32 EAP_E_SERVER_ROOT_CERT_LAST = -2143156993;
	public const uint32 EAP_E_SERVER_ROOT_CERT_NOT_FOUND = 2151810048;
	public const uint32 EAP_E_SERVER_ROOT_CERT_INVALID = 2151810049;
	public const uint32 EAP_E_SERVER_ROOT_CERT_NAME_REQUIRED = 2151810054;
	public const uint32 EAP_E_SIM_NOT_VALID = 2151810304;
	public const uint32 EAP_METHOD_INVALID_PACKET = 2151809047;
	public const uint32 EAP_INVALID_PACKET = 2151809048;
	public const uint32 EAP_PEER_FLAG_GUEST_ACCESS = 64;
	public const uint32 eapPropCipherSuiteNegotiation = 1;
	public const uint32 eapPropMutualAuth = 2;
	public const uint32 eapPropIntegrity = 4;
	public const uint32 eapPropReplayProtection = 8;
	public const uint32 eapPropConfidentiality = 16;
	public const uint32 eapPropKeyDerivation = 32;
	public const uint32 eapPropKeyStrength64 = 64;
	public const uint32 eapPropKeyStrength128 = 128;
	public const uint32 eapPropKeyStrength256 = 256;
	public const uint32 eapPropKeyStrength512 = 512;
	public const uint32 eapPropKeyStrength1024 = 1024;
	public const uint32 eapPropDictionaryAttackResistance = 2048;
	public const uint32 eapPropFastReconnect = 4096;
	public const uint32 eapPropCryptoBinding = 8192;
	public const uint32 eapPropSessionIndependence = 16384;
	public const uint32 eapPropFragmentation = 32768;
	public const uint32 eapPropChannelBinding = 65536;
	public const uint32 eapPropNap = 131072;
	public const uint32 eapPropStandalone = 262144;
	public const uint32 eapPropMppeEncryption = 524288;
	public const uint32 eapPropTunnelMethod = 1048576;
	public const uint32 eapPropSupportsConfig = 2097152;
	public const uint32 eapPropCertifiedMethod = 4194304;
	public const uint32 eapPropHiddenMethod = 8388608;
	public const uint32 eapPropMachineAuth = 16777216;
	public const uint32 eapPropUserAuth = 33554432;
	public const uint32 eapPropIdentityPrivacy = 67108864;
	public const uint32 eapPropMethodChaining = 134217728;
	public const uint32 eapPropSharedStateEquivalence = 268435456;
	public const uint32 eapPropReserved = 2147483648;
	public const String EAP_VALUENAME_PROPERTIES = "Properties";
	public const uint32 EAP_FLAG_Reserved1 = 1;
	public const uint32 EAP_FLAG_NON_INTERACTIVE = 2;
	public const uint32 EAP_FLAG_LOGON = 4;
	public const uint32 EAP_FLAG_PREVIEW = 8;
	public const uint32 EAP_FLAG_Reserved2 = 16;
	public const uint32 EAP_FLAG_MACHINE_AUTH = 32;
	public const uint32 EAP_FLAG_GUEST_ACCESS = 64;
	public const uint32 EAP_FLAG_Reserved3 = 128;
	public const uint32 EAP_FLAG_Reserved4 = 256;
	public const uint32 EAP_FLAG_RESUME_FROM_HIBERNATE = 512;
	public const uint32 EAP_FLAG_Reserved5 = 1024;
	public const uint32 EAP_FLAG_Reserved6 = 2048;
	public const uint32 EAP_FLAG_FULL_AUTH = 4096;
	public const uint32 EAP_FLAG_PREFER_ALT_CREDENTIALS = 8192;
	public const uint32 EAP_FLAG_Reserved7 = 16384;
	public const uint32 EAP_PEER_FLAG_HEALTH_STATE_CHANGE = 32768;
	public const uint32 EAP_FLAG_SUPRESS_UI = 65536;
	public const uint32 EAP_FLAG_PRE_LOGON = 131072;
	public const uint32 EAP_FLAG_USER_AUTH = 262144;
	public const uint32 EAP_FLAG_CONFG_READONLY = 524288;
	public const uint32 EAP_FLAG_Reserved8 = 1048576;
	public const uint32 EAP_FLAG_Reserved9 = 4194304;
	public const uint32 EAP_FLAG_VPN = 8388608;
	public const uint32 EAP_FLAG_ONLY_EAP_TLS = 16777216;
	public const uint32 EAP_FLAG_SERVER_VALIDATION_REQUIRED = 33554432;
	public const uint32 EAP_CONFIG_INPUT_FIELD_PROPS_DEFAULT = 0;
	public const uint32 EAP_CONFIG_INPUT_FIELD_PROPS_NON_DISPLAYABLE = 1;
	public const uint32 EAP_CONFIG_INPUT_FIELD_PROPS_NON_PERSIST = 2;
	public const uint32 EAP_UI_INPUT_FIELD_PROPS_DEFAULT = 0;
	public const uint32 EAP_UI_INPUT_FIELD_PROPS_NON_DISPLAYABLE = 1;
	public const uint32 EAP_UI_INPUT_FIELD_PROPS_NON_PERSIST = 2;
	public const uint32 EAP_UI_INPUT_FIELD_PROPS_READ_ONLY = 4;
	public const uint32 EAP_CREDENTIAL_VERSION = 1;
	public const uint32 EAP_INTERACTIVE_UI_DATA_VERSION = 1;
	public const uint32 EAPHOST_PEER_API_VERSION = 1;
	public const uint32 EAPHOST_METHOD_API_VERSION = 1;
	public const uint32 MAX_EAP_CONFIG_INPUT_FIELD_LENGTH = 256;
	public const uint32 MAX_EAP_CONFIG_INPUT_FIELD_VALUE_LENGTH = 1024;
	public const uint32 CERTIFICATE_HASH_LENGTH = 20;
	public const uint32 NCRYPT_PIN_CACHE_PIN_BYTE_LENGTH = 90;
	public const String EAP_REGISTRY_LOCATION = "System\\CurrentControlSet\\Services\\EapHost\\Methods";
	public const String EAP_PEER_VALUENAME_DLL_PATH = "PeerDllPath";
	public const String EAP_PEER_VALUENAME_FRIENDLY_NAME = "PeerFriendlyName";
	public const String EAP_PEER_VALUENAME_CONFIGUI = "PeerConfigUIPath";
	public const String EAP_PEER_VALUENAME_REQUIRE_CONFIGUI = "PeerRequireConfigUI";
	public const String EAP_PEER_VALUENAME_IDENTITY = "PeerIdentityPath";
	public const String EAP_PEER_VALUENAME_INTERACTIVEUI = "PeerInteractiveUIPath";
	public const String EAP_PEER_VALUENAME_INVOKE_NAMEDLG = "PeerInvokeUsernameDialog";
	public const String EAP_PEER_VALUENAME_INVOKE_PWDDLG = "PeerInvokePasswordDialog";
	public const String EAP_PEER_VALUENAME_PROPERTIES = "Properties";
	public const String EAP_AUTHENTICATOR_VALUENAME_DLL_PATH = "AuthenticatorDllPath";
	public const String EAP_AUTHENTICATOR_VALUENAME_FRIENDLY_NAME = "AuthenticatorFriendlyName";
	public const String EAP_AUTHENTICATOR_VALUENAME_PROPERTIES = "Properties";
	public const String EAP_AUTHENTICATOR_VALUENAME_CONFIGUI = "AuthenticatorConfigUIPath";
	public const uint32 EAP_METHOD_AUTHENTICATOR_CONFIG_IS_IDENTITY_PRIVACY = 1;
	public const String RAS_EAP_REGISTRY_LOCATION = "System\\CurrentControlSet\\Services\\Rasman\\PPP\\EAP";
	public const String RAS_EAP_VALUENAME_PATH = "Path";
	public const String RAS_EAP_VALUENAME_CONFIGUI = "ConfigUIPath";
	public const String RAS_EAP_VALUENAME_INTERACTIVEUI = "InteractiveUIPath";
	public const String RAS_EAP_VALUENAME_IDENTITY = "IdentityPath";
	public const String RAS_EAP_VALUENAME_FRIENDLY_NAME = "FriendlyName";
	public const String RAS_EAP_VALUENAME_DEFAULT_DATA = "ConfigData";
	public const String RAS_EAP_VALUENAME_REQUIRE_CONFIGUI = "RequireConfigUI";
	public const String RAS_EAP_VALUENAME_ENCRYPTION = "MPPEEncryptionSupported";
	public const String RAS_EAP_VALUENAME_INVOKE_NAMEDLG = "InvokeUsernameDialog";
	public const String RAS_EAP_VALUENAME_INVOKE_PWDDLG = "InvokePasswordDialog";
	public const String RAS_EAP_VALUENAME_CONFIG_CLSID = "ConfigCLSID";
	public const String RAS_EAP_VALUENAME_STANDALONE_SUPPORTED = "StandaloneSupported";
	public const String RAS_EAP_VALUENAME_ROLES_SUPPORTED = "RolesSupported";
	public const String RAS_EAP_VALUENAME_PER_POLICY_CONFIG = "PerPolicyConfig";
	public const String RAS_EAP_VALUENAME_ISTUNNEL_METHOD = "IsTunnelMethod";
	public const String RAS_EAP_VALUENAME_FILTER_INNERMETHODS = "FilterInnerMethods";
	public const uint32 RAS_EAP_ROLE_AUTHENTICATOR = 1;
	public const uint32 RAS_EAP_ROLE_AUTHENTICATEE = 2;
	public const uint32 RAS_EAP_ROLE_EXCLUDE_IN_EAP = 4;
	public const uint32 RAS_EAP_ROLE_EXCLUDE_IN_PEAP = 8;
	public const uint32 RAS_EAP_ROLE_EXCLUDE_IN_VPN = 16;
	public const uint32 raatARAPChallenge = 33;
	public const uint32 raatARAPOldPassword = 19;
	public const uint32 raatARAPNewPassword = 20;
	public const uint32 raatARAPPasswordChangeReason = 21;
	public const uint32 EAPCODE_Request = 1;
	public const uint32 EAPCODE_Response = 2;
	public const uint32 EAPCODE_Success = 3;
	public const uint32 EAPCODE_Failure = 4;
	public const uint32 MAXEAPCODE = 4;
	public const uint32 RAS_EAP_FLAG_ROUTER = 1;
	public const uint32 RAS_EAP_FLAG_NON_INTERACTIVE = 2;
	public const uint32 RAS_EAP_FLAG_LOGON = 4;
	public const uint32 RAS_EAP_FLAG_PREVIEW = 8;
	public const uint32 RAS_EAP_FLAG_FIRST_LINK = 16;
	public const uint32 RAS_EAP_FLAG_MACHINE_AUTH = 32;
	public const uint32 RAS_EAP_FLAG_GUEST_ACCESS = 64;
	public const uint32 RAS_EAP_FLAG_8021X_AUTH = 128;
	public const uint32 RAS_EAP_FLAG_HOSTED_IN_PEAP = 256;
	public const uint32 RAS_EAP_FLAG_RESUME_FROM_HIBERNATE = 512;
	public const uint32 RAS_EAP_FLAG_PEAP_UPFRONT = 1024;
	public const uint32 RAS_EAP_FLAG_ALTERNATIVE_USER_DB = 2048;
	public const uint32 RAS_EAP_FLAG_PEAP_FORCE_FULL_AUTH = 4096;
	public const uint32 RAS_EAP_FLAG_PRE_LOGON = 131072;
	public const uint32 RAS_EAP_FLAG_CONFG_READONLY = 524288;
	public const uint32 RAS_EAP_FLAG_RESERVED = 1048576;
	public const uint32 RAS_EAP_FLAG_SAVE_CREDMAN = 2097152;
	public const uint32 RAS_EAP_FLAG_SERVER_VALIDATION_REQUIRED = 33554432;
	public const Guid GUID_EapHost_Default = .(0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
	public const Guid GUID_EapHost_Cause_MethodDLLNotFound = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x01);
	public const Guid GUID_EapHost_Repair_ContactSysadmin = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x02);
	public const Guid GUID_EapHost_Cause_CertStoreInaccessible = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x04);
	public const Guid GUID_EapHost_Cause_Generic_AuthFailure = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x01, 0x04);
	public const Guid GUID_EapHost_Cause_IdentityUnknown = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x02, 0x04);
	public const Guid GUID_EapHost_Cause_SimNotValid = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x03, 0x04);
	public const Guid GUID_EapHost_Cause_Server_CertExpired = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x05);
	public const Guid GUID_EapHost_Cause_Server_CertInvalid = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x06);
	public const Guid GUID_EapHost_Cause_Server_CertNotFound = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x07);
	public const Guid GUID_EapHost_Cause_Server_CertRevoked = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x08);
	public const Guid GUID_EapHost_Cause_Server_CertOtherError = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x01, 0x08);
	public const Guid GUID_EapHost_Cause_User_CertExpired = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x09);
	public const Guid GUID_EapHost_Cause_User_CertInvalid = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x0a);
	public const Guid GUID_EapHost_Cause_User_CertNotFound = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x0b);
	public const Guid GUID_EapHost_Cause_User_CertOtherError = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x0c);
	public const Guid GUID_EapHost_Cause_User_CertRejected = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x0d);
	public const Guid GUID_EapHost_Cause_User_CertRevoked = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x0e);
	public const Guid GUID_EapHost_Cause_User_Account_OtherProblem = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x01, 0x0e);
	public const Guid GUID_EapHost_Cause_User_CredsRejected = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x02, 0x0e);
	public const Guid GUID_EapHost_Cause_User_Root_CertExpired = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x0f);
	public const Guid GUID_EapHost_Cause_User_Root_CertInvalid = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x10);
	public const Guid GUID_EapHost_Cause_User_Root_CertNotFound = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x11);
	public const Guid GUID_EapHost_Cause_Server_Root_CertNameRequired = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x12);
	public const Guid GUID_EapHost_Cause_Server_Root_CertNotFound = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x01, 0x12);
	public const Guid GUID_EapHost_Cause_ThirdPartyMethod_Host_Reset = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x02, 0x12);
	public const Guid GUID_EapHost_Cause_EapQecInaccessible = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x03, 0x12);
	public const Guid GUID_EapHost_Repair_Server_ClientSelectServerCert = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x18);
	public const Guid GUID_EapHost_Repair_User_AuthFailure = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x19);
	public const Guid GUID_EapHost_Repair_User_GetNewCert = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x1a);
	public const Guid GUID_EapHost_Repair_User_SelectValidCert = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x1b);
	public const Guid GUID_EapHost_Repair_Retry_Authentication = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x01, 0x1b);
	public const Guid GUID_EapHost_Cause_EapNegotiationFailed = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x1c);
	public const Guid GUID_EapHost_Cause_XmlMalformed = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x1d);
	public const Guid GUID_EapHost_Cause_MethodDoesNotSupportOperation = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x1e);
	public const Guid GUID_EapHost_Repair_ContactAdmin_AuthFailure = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x1f);
	public const Guid GUID_EapHost_Repair_ContactAdmin_IdentityUnknown = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x20);
	public const Guid GUID_EapHost_Repair_ContactAdmin_NegotiationFailed = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x21);
	public const Guid GUID_EapHost_Repair_ContactAdmin_MethodNotFound = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x22);
	public const Guid GUID_EapHost_Repair_RestartNap = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x23);
	public const Guid GUID_EapHost_Repair_ContactAdmin_CertStoreInaccessible = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x24);
	public const Guid GUID_EapHost_Repair_ContactAdmin_InvalidUserAccount = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x25);
	public const Guid GUID_EapHost_Repair_ContactAdmin_RootCertInvalid = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x26);
	public const Guid GUID_EapHost_Repair_ContactAdmin_RootCertNotFound = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x27);
	public const Guid GUID_EapHost_Repair_ContactAdmin_RootExpired = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x28);
	public const Guid GUID_EapHost_Repair_ContactAdmin_CertNameAbsent = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x29);
	public const Guid GUID_EapHost_Repair_ContactAdmin_NoSmartCardReader = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x2a);
	public const Guid GUID_EapHost_Cause_No_SmartCardReader_Found = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x2b);
	public const Guid GUID_EapHost_Repair_ContactAdmin_InvalidUserCert = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x2c);
	public const Guid GUID_EapHost_Repair_Method_Not_Support_Sso = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x2d);
	public const Guid GUID_EapHost_Repair_No_ValidSim_Found = .(0x9612fc67, 0x6150, 0x4209, 0xa8, 0x5e, 0xa8, 0xd8, 0x00, 0x00, 0x00, 0x2e);
	public const Guid GUID_EapHost_Help_ObtainingCerts = .(0xf535eea3, 0x1bdd, 0x46ca, 0xa2, 0xfc, 0xa6, 0x65, 0x59, 0x39, 0xb7, 0xe8);
	public const Guid GUID_EapHost_Help_Troubleshooting = .(0x33307acf, 0x0698, 0x41ba, 0xb0, 0x14, 0xea, 0x0a, 0x2e, 0xb8, 0xd0, 0xa8);
	public const Guid GUID_EapHost_Cause_Method_Config_Does_Not_Support_Sso = .(0xda18bd32, 0x004f, 0x41fa, 0xae, 0x08, 0x0b, 0xc8, 0x5e, 0x58, 0x45, 0xac);
}
#endregion

#region Enums

[AllowDuplicates]
public enum RAS_AUTH_ATTRIBUTE_TYPE : int32
{
	raatMinimum = 0,
	raatUserName = 1,
	raatUserPassword = 2,
	raatMD5CHAPPassword = 3,
	raatNASIPAddress = 4,
	raatNASPort = 5,
	raatServiceType = 6,
	raatFramedProtocol = 7,
	raatFramedIPAddress = 8,
	raatFramedIPNetmask = 9,
	raatFramedRouting = 10,
	raatFilterId = 11,
	raatFramedMTU = 12,
	raatFramedCompression = 13,
	raatLoginIPHost = 14,
	raatLoginService = 15,
	raatLoginTCPPort = 16,
	raatUnassigned17 = 17,
	raatReplyMessage = 18,
	raatCallbackNumber = 19,
	raatCallbackId = 20,
	raatUnassigned21 = 21,
	raatFramedRoute = 22,
	raatFramedIPXNetwork = 23,
	raatState = 24,
	raatClass = 25,
	raatVendorSpecific = 26,
	raatSessionTimeout = 27,
	raatIdleTimeout = 28,
	raatTerminationAction = 29,
	raatCalledStationId = 30,
	raatCallingStationId = 31,
	raatNASIdentifier = 32,
	raatProxyState = 33,
	raatLoginLATService = 34,
	raatLoginLATNode = 35,
	raatLoginLATGroup = 36,
	raatFramedAppleTalkLink = 37,
	raatFramedAppleTalkNetwork = 38,
	raatFramedAppleTalkZone = 39,
	raatAcctStatusType = 40,
	raatAcctDelayTime = 41,
	raatAcctInputOctets = 42,
	raatAcctOutputOctets = 43,
	raatAcctSessionId = 44,
	raatAcctAuthentic = 45,
	raatAcctSessionTime = 46,
	raatAcctInputPackets = 47,
	raatAcctOutputPackets = 48,
	raatAcctTerminateCause = 49,
	raatAcctMultiSessionId = 50,
	raatAcctLinkCount = 51,
	raatAcctEventTimeStamp = 55,
	raatMD5CHAPChallenge = 60,
	raatNASPortType = 61,
	raatPortLimit = 62,
	raatLoginLATPort = 63,
	raatTunnelType = 64,
	raatTunnelMediumType = 65,
	raatTunnelClientEndpoint = 66,
	raatTunnelServerEndpoint = 67,
	raatARAPPassword = 70,
	raatARAPFeatures = 71,
	raatARAPZoneAccess = 72,
	raatARAPSecurity = 73,
	raatARAPSecurityData = 74,
	raatPasswordRetry = 75,
	raatPrompt = 76,
	raatConnectInfo = 77,
	raatConfigurationToken = 78,
	raatEAPMessage = 79,
	raatSignature = 80,
	raatARAPChallengeResponse = 84,
	raatAcctInterimInterval = 85,
	raatNASIPv6Address = 95,
	raatFramedInterfaceId = 96,
	raatFramedIPv6Prefix = 97,
	raatLoginIPv6Host = 98,
	raatFramedIPv6Route = 99,
	raatFramedIPv6Pool = 100,
	raatARAPGuestLogon = 8096,
	raatCertificateOID = 8097,
	raatEAPConfiguration = 8098,
	raatPEAPEmbeddedEAPTypeId = 8099,
	raatInnerEAPTypeId = 8099,
	raatPEAPFastRoamedSession = 8100,
	raatFastRoamedSession = 8100,
	raatEAPTLV = 8102,
	raatCredentialsChanged = 8103,
	raatCertificateThumbprint = 8250,
	raatPeerId = 9000,
	raatServerId = 9001,
	raatMethodId = 9002,
	raatEMSK = 9003,
	raatSessionId = 9004,
	raatReserved = -1,
}


[AllowDuplicates]
public enum PPP_EAP_ACTION : int32
{
	EAPACTION_NoAction = 0,
	EAPACTION_Authenticate = 1,
	EAPACTION_Done = 2,
	EAPACTION_SendAndDone = 3,
	EAPACTION_Send = 4,
	EAPACTION_SendWithTimeout = 5,
	EAPACTION_SendWithTimeoutInteractive = 6,
	EAPACTION_IndicateTLV = 7,
	EAPACTION_IndicateIdentity = 8,
}


[AllowDuplicates]
public enum EAP_ATTRIBUTE_TYPE : int32
{
	eatMinimum = 0,
	eatUserName = 1,
	eatUserPassword = 2,
	eatMD5CHAPPassword = 3,
	eatNASIPAddress = 4,
	eatNASPort = 5,
	eatServiceType = 6,
	eatFramedProtocol = 7,
	eatFramedIPAddress = 8,
	eatFramedIPNetmask = 9,
	eatFramedRouting = 10,
	eatFilterId = 11,
	eatFramedMTU = 12,
	eatFramedCompression = 13,
	eatLoginIPHost = 14,
	eatLoginService = 15,
	eatLoginTCPPort = 16,
	eatUnassigned17 = 17,
	eatReplyMessage = 18,
	eatCallbackNumber = 19,
	eatCallbackId = 20,
	eatUnassigned21 = 21,
	eatFramedRoute = 22,
	eatFramedIPXNetwork = 23,
	eatState = 24,
	eatClass = 25,
	eatVendorSpecific = 26,
	eatSessionTimeout = 27,
	eatIdleTimeout = 28,
	eatTerminationAction = 29,
	eatCalledStationId = 30,
	eatCallingStationId = 31,
	eatNASIdentifier = 32,
	eatProxyState = 33,
	eatLoginLATService = 34,
	eatLoginLATNode = 35,
	eatLoginLATGroup = 36,
	eatFramedAppleTalkLink = 37,
	eatFramedAppleTalkNetwork = 38,
	eatFramedAppleTalkZone = 39,
	eatAcctStatusType = 40,
	eatAcctDelayTime = 41,
	eatAcctInputOctets = 42,
	eatAcctOutputOctets = 43,
	eatAcctSessionId = 44,
	eatAcctAuthentic = 45,
	eatAcctSessionTime = 46,
	eatAcctInputPackets = 47,
	eatAcctOutputPackets = 48,
	eatAcctTerminateCause = 49,
	eatAcctMultiSessionId = 50,
	eatAcctLinkCount = 51,
	eatAcctEventTimeStamp = 55,
	eatMD5CHAPChallenge = 60,
	eatNASPortType = 61,
	eatPortLimit = 62,
	eatLoginLATPort = 63,
	eatTunnelType = 64,
	eatTunnelMediumType = 65,
	eatTunnelClientEndpoint = 66,
	eatTunnelServerEndpoint = 67,
	eatARAPPassword = 70,
	eatARAPFeatures = 71,
	eatARAPZoneAccess = 72,
	eatARAPSecurity = 73,
	eatARAPSecurityData = 74,
	eatPasswordRetry = 75,
	eatPrompt = 76,
	eatConnectInfo = 77,
	eatConfigurationToken = 78,
	eatEAPMessage = 79,
	eatSignature = 80,
	eatARAPChallengeResponse = 84,
	eatAcctInterimInterval = 85,
	eatNASIPv6Address = 95,
	eatFramedInterfaceId = 96,
	eatFramedIPv6Prefix = 97,
	eatLoginIPv6Host = 98,
	eatFramedIPv6Route = 99,
	eatFramedIPv6Pool = 100,
	eatARAPGuestLogon = 8096,
	eatCertificateOID = 8097,
	eatEAPConfiguration = 8098,
	eatPEAPEmbeddedEAPTypeId = 8099,
	eatPEAPFastRoamedSession = 8100,
	eatFastRoamedSession = 8100,
	eatEAPTLV = 8102,
	eatCredentialsChanged = 8103,
	eatInnerEapMethodType = 8104,
	eatClearTextPassword = 8107,
	eatQuarantineSoH = 8150,
	eatCertificateThumbprint = 8250,
	eatPeerId = 9000,
	eatServerId = 9001,
	eatMethodId = 9002,
	eatEMSK = 9003,
	eatSessionId = 9004,
	eatReserved = -1,
}


[AllowDuplicates]
public enum EAP_CONFIG_INPUT_FIELD_TYPE : int32
{
	EapConfigInputUsername = 0,
	EapConfigInputPassword = 1,
	EapConfigInputNetworkUsername = 2,
	EapConfigInputNetworkPassword = 3,
	EapConfigInputPin = 4,
	EapConfigInputPSK = 5,
	EapConfigInputEdit = 6,
	EapConfigSmartCardUsername = 7,
	EapConfigSmartCardError = 8,
}


[AllowDuplicates]
public enum EAP_INTERACTIVE_UI_DATA_TYPE : int32
{
	EapCredReq = 0,
	EapCredResp = 1,
	EapCredExpiryReq = 2,
	EapCredExpiryResp = 3,
	EapCredLogonReq = 4,
	EapCredLogonResp = 5,
}


[AllowDuplicates]
public enum EAP_METHOD_PROPERTY_TYPE : int32
{
	emptPropCipherSuiteNegotiation = 0,
	emptPropMutualAuth = 1,
	emptPropIntegrity = 2,
	emptPropReplayProtection = 3,
	emptPropConfidentiality = 4,
	emptPropKeyDerivation = 5,
	emptPropKeyStrength64 = 6,
	emptPropKeyStrength128 = 7,
	emptPropKeyStrength256 = 8,
	emptPropKeyStrength512 = 9,
	emptPropKeyStrength1024 = 10,
	emptPropDictionaryAttackResistance = 11,
	emptPropFastReconnect = 12,
	emptPropCryptoBinding = 13,
	emptPropSessionIndependence = 14,
	emptPropFragmentation = 15,
	emptPropChannelBinding = 16,
	emptPropNap = 17,
	emptPropStandalone = 18,
	emptPropMppeEncryption = 19,
	emptPropTunnelMethod = 20,
	emptPropSupportsConfig = 21,
	emptPropCertifiedMethod = 22,
	emptPropHiddenMethod = 23,
	emptPropMachineAuth = 24,
	emptPropUserAuth = 25,
	emptPropIdentityPrivacy = 26,
	emptPropMethodChaining = 27,
	emptPropSharedStateEquivalence = 28,
	emptLegacyMethodPropertyFlag = 31,
	emptPropVendorSpecific = 255,
}


[AllowDuplicates]
public enum EAP_METHOD_PROPERTY_VALUE_TYPE : int32
{
	empvtBool = 0,
	empvtDword = 1,
	empvtString = 2,
}


[AllowDuplicates]
public enum EapCredentialType : int32
{
	EAP_EMPTY_CREDENTIAL = 0,
	EAP_USERNAME_PASSWORD_CREDENTIAL = 1,
	EAP_WINLOGON_CREDENTIAL = 2,
	EAP_CERTIFICATE_CREDENTIAL = 3,
	EAP_SIM_CREDENTIAL = 4,
}


[AllowDuplicates]
public enum EapHostPeerMethodResultReason : int32
{
	EapHostPeerMethodResultAltSuccessReceived = 1,
	EapHostPeerMethodResultTimeout = 2,
	EapHostPeerMethodResultFromMethod = 3,
}


[AllowDuplicates]
public enum EapHostPeerResponseAction : int32
{
	EapHostPeerResponseDiscard = 0,
	EapHostPeerResponseSend = 1,
	EapHostPeerResponseResult = 2,
	EapHostPeerResponseInvokeUi = 3,
	EapHostPeerResponseRespond = 4,
	EapHostPeerResponseStartAuthentication = 5,
	EapHostPeerResponseNone = 6,
}


[AllowDuplicates]
public enum EapHostPeerAuthParams : int32
{
	EapHostPeerAuthStatus = 1,
	EapHostPeerIdentity = 2,
	EapHostPeerIdentityExtendedInfo = 3,
	EapHostNapInfo = 4,
}


[AllowDuplicates]
public enum EAPHOST_AUTH_STATUS : int32
{
	EapHostInvalidSession = 0,
	EapHostAuthNotStarted = 1,
	EapHostAuthIdentityExchange = 2,
	EapHostAuthNegotiatingType = 3,
	EapHostAuthInProgress = 4,
	EapHostAuthSucceeded = 5,
	EapHostAuthFailed = 6,
}


[AllowDuplicates]
public enum ISOLATION_STATE : int32
{
	ISOLATION_STATE_UNKNOWN = 0,
	ISOLATION_STATE_NOT_RESTRICTED = 1,
	ISOLATION_STATE_IN_PROBATION = 2,
	ISOLATION_STATE_RESTRICTED_ACCESS = 3,
}


[AllowDuplicates]
public enum EapCode : int32
{
	EapCodeMinimum = 1,
	EapCodeRequest = 1,
	EapCodeResponse = 2,
	EapCodeSuccess = 3,
	EapCodeFailure = 4,
	EapCodeMaximum = 4,
}


[AllowDuplicates]
public enum EAP_METHOD_AUTHENTICATOR_RESPONSE_ACTION : int32
{
	EAP_METHOD_AUTHENTICATOR_RESPONSE_DISCARD = 0,
	EAP_METHOD_AUTHENTICATOR_RESPONSE_SEND = 1,
	EAP_METHOD_AUTHENTICATOR_RESPONSE_RESULT = 2,
	EAP_METHOD_AUTHENTICATOR_RESPONSE_RESPOND = 3,
	EAP_METHOD_AUTHENTICATOR_RESPONSE_AUTHENTICATE = 4,
	EAP_METHOD_AUTHENTICATOR_RESPONSE_HANDLE_IDENTITY = 5,
}


[AllowDuplicates]
public enum EapPeerMethodResponseAction : int32
{
	EapPeerMethodResponseActionDiscard = 0,
	EapPeerMethodResponseActionSend = 1,
	EapPeerMethodResponseActionResult = 2,
	EapPeerMethodResponseActionInvokeUI = 3,
	EapPeerMethodResponseActionRespond = 4,
	EapPeerMethodResponseActionNone = 5,
}


[AllowDuplicates]
public enum EapPeerMethodResultReason : int32
{
	EapPeerMethodResultUnknown = 1,
	EapPeerMethodResultSuccess = 2,
	EapPeerMethodResultFailure = 3,
}


[AllowDuplicates]
public enum EAP_AUTHENTICATOR_SEND_TIMEOUT : int32
{
	EAP_AUTHENTICATOR_SEND_TIMEOUT_NONE = 0,
	EAP_AUTHENTICATOR_SEND_TIMEOUT_BASIC = 1,
	EAP_AUTHENTICATOR_SEND_TIMEOUT_INTERACTIVE = 2,
}

#endregion

#region Function Pointers
public function void NotificationHandler(Guid connectionId, void* pContextData);

#endregion

#region Structs
[CRepr]
public struct NgcTicketContext
{
	public char16[45] wszTicket;
	public NCRYPT_KEY_HANDLE hKey;
	public HANDLE hImpersonateToken;
}

[CRepr]
public struct RAS_AUTH_ATTRIBUTE
{
	public RAS_AUTH_ATTRIBUTE_TYPE raaType;
	public uint32 dwLength;
	public void* Value;
}

[CRepr]
public struct PPP_EAP_PACKET
{
	public uint8 Code;
	public uint8 Id;
	public uint8[2] Length;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct PPP_EAP_INPUT
{
	public uint32 dwSizeInBytes;
	public uint32 fFlags;
	public BOOL fAuthenticator;
	public PWSTR pwszIdentity;
	public PWSTR pwszPassword;
	public uint8 bInitialId;
	public RAS_AUTH_ATTRIBUTE* pUserAttributes;
	public BOOL fAuthenticationComplete;
	public uint32 dwAuthResultCode;
	public HANDLE hTokenImpersonateUser;
	public BOOL fSuccessPacketReceived;
	public BOOL fDataReceivedFromInteractiveUI;
	public uint8* pDataFromInteractiveUI;
	public uint32 dwSizeOfDataFromInteractiveUI;
	public uint8* pConnectionData;
	public uint32 dwSizeOfConnectionData;
	public uint8* pUserData;
	public uint32 dwSizeOfUserData;
	public HANDLE hReserved;
	public Guid guidConnectionId;
	public BOOL isVpn;
}

[CRepr]
public struct PPP_EAP_OUTPUT
{
	public uint32 dwSizeInBytes;
	public PPP_EAP_ACTION Action;
	public uint32 dwAuthResultCode;
	public RAS_AUTH_ATTRIBUTE* pUserAttributes;
	public BOOL fInvokeInteractiveUI;
	public uint8* pUIContextData;
	public uint32 dwSizeOfUIContextData;
	public BOOL fSaveConnectionData;
	public uint8* pConnectionData;
	public uint32 dwSizeOfConnectionData;
	public BOOL fSaveUserData;
	public uint8* pUserData;
	public uint32 dwSizeOfUserData;
	public NgcTicketContext* pNgcKerbTicket;
	public BOOL fSaveToCredMan;
}

[CRepr]
public struct PPP_EAP_INFO
{
	public uint32 dwSizeInBytes;
	public uint32 dwEapTypeId;
	public int RasEapInitialize;
	public int RasEapBegin;
	public int RasEapEnd;
	public int RasEapMakeMessage;
}

[CRepr]
public struct LEGACY_IDENTITY_UI_PARAMS
{
	public uint32 eapType;
	public uint32 dwFlags;
	public uint32 dwSizeofConnectionData;
	public uint8* pConnectionData;
	public uint32 dwSizeofUserData;
	public uint8* pUserData;
	public uint32 dwSizeofUserDataOut;
	public uint8* pUserDataOut;
	public PWSTR pwszIdentity;
	public uint32 dwError;
}

[CRepr]
public struct LEGACY_INTERACTIVE_UI_PARAMS
{
	public uint32 eapType;
	public uint32 dwSizeofContextData;
	public uint8* pContextData;
	public uint32 dwSizeofInteractiveUIData;
	public uint8* pInteractiveUIData;
	public uint32 dwError;
}

[CRepr]
public struct EAP_TYPE
{
	public uint8 type;
	public uint32 dwVendorId;
	public uint32 dwVendorType;
}

[CRepr]
public struct EAP_METHOD_TYPE
{
	public EAP_TYPE eapType;
	public uint32 dwAuthorId;
}

[CRepr]
public struct EAP_METHOD_INFO
{
	public EAP_METHOD_TYPE eaptype;
	public PWSTR pwszAuthorName;
	public PWSTR pwszFriendlyName;
	public uint32 eapProperties;
	public EAP_METHOD_INFO* pInnerMethodInfo;
}

[CRepr]
public struct EAP_METHOD_INFO_EX
{
	public EAP_METHOD_TYPE eaptype;
	public PWSTR pwszAuthorName;
	public PWSTR pwszFriendlyName;
	public uint32 eapProperties;
	public EAP_METHOD_INFO_ARRAY_EX* pInnerMethodInfoArray;
}

[CRepr]
public struct EAP_METHOD_INFO_ARRAY
{
	public uint32 dwNumberOfMethods;
	public EAP_METHOD_INFO* pEapMethods;
}

[CRepr]
public struct EAP_METHOD_INFO_ARRAY_EX
{
	public uint32 dwNumberOfMethods;
	public EAP_METHOD_INFO_EX* pEapMethods;
}

[CRepr]
public struct EAP_ERROR
{
	public uint32 dwWinError;
	public EAP_METHOD_TYPE type;
	public uint32 dwReasonCode;
	public Guid rootCauseGuid;
	public Guid repairGuid;
	public Guid helpLinkGuid;
	public PWSTR pRootCauseString;
	public PWSTR pRepairString;
}

[CRepr]
public struct EAP_ATTRIBUTE
{
	public EAP_ATTRIBUTE_TYPE eaType;
	public uint32 dwLength;
	public uint8* pValue;
}

[CRepr]
public struct EAP_ATTRIBUTES
{
	public uint32 dwNumberOfAttributes;
	public EAP_ATTRIBUTE* pAttribs;
}

[CRepr]
public struct EAP_CONFIG_INPUT_FIELD_DATA
{
	public uint32 dwSize;
	public EAP_CONFIG_INPUT_FIELD_TYPE Type;
	public uint32 dwFlagProps;
	public PWSTR pwszLabel;
	public PWSTR pwszData;
	public uint32 dwMinDataLength;
	public uint32 dwMaxDataLength;
}

[CRepr]
public struct EAP_CONFIG_INPUT_FIELD_ARRAY
{
	public uint32 dwVersion;
	public uint32 dwNumberOfFields;
	public EAP_CONFIG_INPUT_FIELD_DATA* pFields;
}

[CRepr]
public struct EAP_CRED_EXPIRY_REQ
{
	public EAP_CONFIG_INPUT_FIELD_ARRAY curCreds;
	public EAP_CONFIG_INPUT_FIELD_ARRAY newCreds;
}

[CRepr, Union]
public struct EAP_UI_DATA_FORMAT
{
	public EAP_CONFIG_INPUT_FIELD_ARRAY* credData;
	public EAP_CRED_EXPIRY_REQ* credExpiryData;
	public EAP_CONFIG_INPUT_FIELD_ARRAY* credLogonData;
}

[CRepr]
public struct EAP_INTERACTIVE_UI_DATA
{
	public uint32 dwVersion;
	public uint32 dwSize;
	public EAP_INTERACTIVE_UI_DATA_TYPE dwDataType;
	public uint32 cbUiData;
	public EAP_UI_DATA_FORMAT pbUiData;
}

[CRepr]
public struct EAP_METHOD_PROPERTY_VALUE_BOOL
{
	public uint32 length;
	public BOOL value;
}

[CRepr]
public struct EAP_METHOD_PROPERTY_VALUE_DWORD
{
	public uint32 length;
	public uint32 value;
}

[CRepr]
public struct EAP_METHOD_PROPERTY_VALUE_STRING
{
	public uint32 length;
	public uint8* value;
}

[CRepr, Union]
public struct EAP_METHOD_PROPERTY_VALUE
{
	public EAP_METHOD_PROPERTY_VALUE_BOOL empvBool;
	public EAP_METHOD_PROPERTY_VALUE_DWORD empvDword;
	public EAP_METHOD_PROPERTY_VALUE_STRING empvString;
}

[CRepr]
public struct EAP_METHOD_PROPERTY
{
	public EAP_METHOD_PROPERTY_TYPE eapMethodPropertyType;
	public EAP_METHOD_PROPERTY_VALUE_TYPE eapMethodPropertyValueType;
	public EAP_METHOD_PROPERTY_VALUE eapMethodPropertyValue;
}

[CRepr]
public struct EAP_METHOD_PROPERTY_ARRAY
{
	public uint32 dwNumberOfProperties;
	public EAP_METHOD_PROPERTY* pMethodProperty;
}

[CRepr]
public struct EAPHOST_IDENTITY_UI_PARAMS
{
	public EAP_METHOD_TYPE eapMethodType;
	public uint32 dwFlags;
	public uint32 dwSizeofConnectionData;
	public uint8* pConnectionData;
	public uint32 dwSizeofUserData;
	public uint8* pUserData;
	public uint32 dwSizeofUserDataOut;
	public uint8* pUserDataOut;
	public PWSTR pwszIdentity;
	public uint32 dwError;
	public EAP_ERROR* pEapError;
}

[CRepr]
public struct EAPHOST_INTERACTIVE_UI_PARAMS
{
	public uint32 dwSizeofContextData;
	public uint8* pContextData;
	public uint32 dwSizeofInteractiveUIData;
	public uint8* pInteractiveUIData;
	public uint32 dwError;
	public EAP_ERROR* pEapError;
}

[CRepr]
public struct EapUsernamePasswordCredential
{
	public PWSTR username;
	public PWSTR password;
}

[CRepr]
public struct EapCertificateCredential
{
	public uint8[20] certHash;
	public PWSTR password;
}

[CRepr]
public struct EapSimCredential
{
	public PWSTR iccID;
}

[CRepr, Union]
public struct EapCredentialTypeData
{
	public EapUsernamePasswordCredential username_password;
	public EapCertificateCredential certificate;
	public EapSimCredential sim;
}

[CRepr]
public struct EapCredential
{
	public EapCredentialType credType;
	public EapCredentialTypeData credData;
}

[CRepr]
public struct EAPHOST_AUTH_INFO
{
	public EAPHOST_AUTH_STATUS status;
	public uint32 dwErrorCode;
	public uint32 dwReasonCode;
}

[CRepr]
public struct EapHostPeerMethodResult
{
	public BOOL fIsSuccess;
	public uint32 dwFailureReasonCode;
	public BOOL fSaveConnectionData;
	public uint32 dwSizeofConnectionData;
	public uint8* pConnectionData;
	public BOOL fSaveUserData;
	public uint32 dwSizeofUserData;
	public uint8* pUserData;
	public EAP_ATTRIBUTES* pAttribArray;
	public ISOLATION_STATE isolationState;
	public EAP_METHOD_INFO* pEapMethodInfo;
	public EAP_ERROR* pEapError;
}

[CRepr]
public struct EapPacket
{
	public uint8 Code;
	public uint8 Id;
	public uint8[2] Length;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct EAP_METHOD_AUTHENTICATOR_RESULT
{
	public BOOL fIsSuccess;
	public uint32 dwFailureReason;
	public EAP_ATTRIBUTES* pAuthAttribs;
}

[CRepr]
public struct EapPeerMethodOutput
{
	public EapPeerMethodResponseAction action;
	public BOOL fAllowNotifications;
}

[CRepr]
public struct EapPeerMethodResult
{
	public BOOL fIsSuccess;
	public uint32 dwFailureReasonCode;
	public BOOL fSaveConnectionData;
	public uint32 dwSizeofConnectionData;
	public uint8* pConnectionData;
	public BOOL fSaveUserData;
	public uint32 dwSizeofUserData;
	public uint8* pUserData;
	public EAP_ATTRIBUTES* pAttribArray;
	public EAP_ERROR* pEapError;
	public NgcTicketContext* pNgcKerbTicket;
	public BOOL fSaveToCredMan;
}

[CRepr]
public struct EAP_PEER_METHOD_ROUTINES
{
	public uint32 dwVersion;
	public EAP_TYPE* pEapType;
	public int EapPeerInitialize;
	public int EapPeerGetIdentity;
	public int EapPeerBeginSession;
	public int EapPeerSetCredentials;
	public int EapPeerProcessRequestPacket;
	public int EapPeerGetResponsePacket;
	public int EapPeerGetResult;
	public int EapPeerGetUIContext;
	public int EapPeerSetUIContext;
	public int EapPeerGetResponseAttributes;
	public int EapPeerSetResponseAttributes;
	public int EapPeerEndSession;
	public int EapPeerShutdown;
}

[CRepr]
public struct EAP_AUTHENTICATOR_METHOD_ROUTINES
{
	public uint32 dwSizeInBytes;
	public EAP_METHOD_TYPE* pEapType;
	public int EapMethodAuthenticatorInitialize;
	public int EapMethodAuthenticatorBeginSession;
	public int EapMethodAuthenticatorUpdateInnerMethodParams;
	public int EapMethodAuthenticatorReceivePacket;
	public int EapMethodAuthenticatorSendPacket;
	public int EapMethodAuthenticatorGetAttributes;
	public int EapMethodAuthenticatorSetAttributes;
	public int EapMethodAuthenticatorGetResult;
	public int EapMethodAuthenticatorEndSession;
	public int EapMethodAuthenticatorShutdown;
}

#endregion

#region COM Types
[CRepr]struct IRouterProtocolConfig : IUnknown
{
	public new const Guid IID = .(0x66a2db16, 0xd706, 0x11d0, 0xa3, 0x7b, 0x00, 0xc0, 0x4f, 0xc9, 0xda, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMachineName, uint32 dwTransportId, uint32 dwProtocolId, HWND hWnd, uint32 dwFlags, IUnknown* pRouter, uint uReserved1) AddProtocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMachineName, uint32 dwTransportId, uint32 dwProtocolId, HWND hWnd, uint32 dwFlags, IUnknown* pRouter, uint uReserved1) RemoveProtocol;
	}


	public HRESULT AddProtocol(PWSTR pszMachineName, uint32 dwTransportId, uint32 dwProtocolId, HWND hWnd, uint32 dwFlags, IUnknown* pRouter, uint uReserved1) mut => VT.[Friend]AddProtocol(&this, pszMachineName, dwTransportId, dwProtocolId, hWnd, dwFlags, pRouter, uReserved1);

	public HRESULT RemoveProtocol(PWSTR pszMachineName, uint32 dwTransportId, uint32 dwProtocolId, HWND hWnd, uint32 dwFlags, IUnknown* pRouter, uint uReserved1) mut => VT.[Friend]RemoveProtocol(&this, pszMachineName, dwTransportId, dwProtocolId, hWnd, dwFlags, pRouter, uReserved1);
}

[CRepr]struct IAuthenticationProviderConfig : IUnknown
{
	public new const Guid IID = .(0x66a2db17, 0xd706, 0x11d0, 0xa3, 0x7b, 0x00, 0xc0, 0x4f, 0xc9, 0xda, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMachineName, uint* puConnectionParam) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint uConnectionParam) Uninitialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint uConnectionParam, HWND hWnd, uint32 dwFlags, uint uReserved1, uint uReserved2) Configure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint uConnectionParam, uint uReserved1, uint uReserved2) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint uConnectionParam, uint uReserved1, uint uReserved2) Deactivate;
	}


	public HRESULT Initialize(PWSTR pszMachineName, uint* puConnectionParam) mut => VT.[Friend]Initialize(&this, pszMachineName, puConnectionParam);

	public HRESULT Uninitialize(uint uConnectionParam) mut => VT.[Friend]Uninitialize(&this, uConnectionParam);

	public HRESULT Configure(uint uConnectionParam, HWND hWnd, uint32 dwFlags, uint uReserved1, uint uReserved2) mut => VT.[Friend]Configure(&this, uConnectionParam, hWnd, dwFlags, uReserved1, uReserved2);

	public HRESULT Activate(uint uConnectionParam, uint uReserved1, uint uReserved2) mut => VT.[Friend]Activate(&this, uConnectionParam, uReserved1, uReserved2);

	public HRESULT Deactivate(uint uConnectionParam, uint uReserved1, uint uReserved2) mut => VT.[Friend]Deactivate(&this, uConnectionParam, uReserved1, uReserved2);
}

[CRepr]struct IAccountingProviderConfig : IUnknown
{
	public new const Guid IID = .(0x66a2db18, 0xd706, 0x11d0, 0xa3, 0x7b, 0x00, 0xc0, 0x4f, 0xc9, 0xda, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMachineName, uint* puConnectionParam) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint uConnectionParam) Uninitialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint uConnectionParam, HWND hWnd, uint32 dwFlags, uint uReserved1, uint uReserved2) Configure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint uConnectionParam, uint uReserved1, uint uReserved2) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint uConnectionParam, uint uReserved1, uint uReserved2) Deactivate;
	}


	public HRESULT Initialize(PWSTR pszMachineName, uint* puConnectionParam) mut => VT.[Friend]Initialize(&this, pszMachineName, puConnectionParam);

	public HRESULT Uninitialize(uint uConnectionParam) mut => VT.[Friend]Uninitialize(&this, uConnectionParam);

	public HRESULT Configure(uint uConnectionParam, HWND hWnd, uint32 dwFlags, uint uReserved1, uint uReserved2) mut => VT.[Friend]Configure(&this, uConnectionParam, hWnd, dwFlags, uReserved1, uReserved2);

	public HRESULT Activate(uint uConnectionParam, uint uReserved1, uint uReserved2) mut => VT.[Friend]Activate(&this, uConnectionParam, uReserved1, uReserved2);

	public HRESULT Deactivate(uint uConnectionParam, uint uReserved1, uint uReserved2) mut => VT.[Friend]Deactivate(&this, uConnectionParam, uReserved1, uReserved2);
}

[CRepr]struct IEAPProviderConfig : IUnknown
{
	public new const Guid IID = .(0x66a2db19, 0xd706, 0x11d0, 0xa3, 0x7b, 0x00, 0xc0, 0x4f, 0xc9, 0xda, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMachineName, uint32 dwEapTypeId, uint* puConnectionParam) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEapTypeId, uint uConnectionParam) Uninitialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEapTypeId, uint uConnectionParam, HWND hWnd, uint uReserved1, uint uReserved2) ServerInvokeConfigUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEapTypeId, uint uConnectionParam, HWND hwndParent, uint32 dwFlags, uint8* pConnectionDataIn, uint32 dwSizeOfConnectionDataIn, uint8** ppConnectionDataOut, uint32* pdwSizeOfConnectionDataOut) RouterInvokeConfigUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEapTypeId, uint uConnectionParam, HWND hwndParent, uint32 dwFlags, uint8* pConnectionDataIn, uint32 dwSizeOfConnectionDataIn, uint8* pUserDataIn, uint32 dwSizeOfUserDataIn, uint8** ppUserDataOut, uint32* pdwSizeOfUserDataOut) RouterInvokeCredentialsUI;
	}


	public HRESULT Initialize(PWSTR pszMachineName, uint32 dwEapTypeId, uint* puConnectionParam) mut => VT.[Friend]Initialize(&this, pszMachineName, dwEapTypeId, puConnectionParam);

	public HRESULT Uninitialize(uint32 dwEapTypeId, uint uConnectionParam) mut => VT.[Friend]Uninitialize(&this, dwEapTypeId, uConnectionParam);

	public HRESULT ServerInvokeConfigUI(uint32 dwEapTypeId, uint uConnectionParam, HWND hWnd, uint uReserved1, uint uReserved2) mut => VT.[Friend]ServerInvokeConfigUI(&this, dwEapTypeId, uConnectionParam, hWnd, uReserved1, uReserved2);

	public HRESULT RouterInvokeConfigUI(uint32 dwEapTypeId, uint uConnectionParam, HWND hwndParent, uint32 dwFlags, uint8* pConnectionDataIn, uint32 dwSizeOfConnectionDataIn, uint8** ppConnectionDataOut, uint32* pdwSizeOfConnectionDataOut) mut => VT.[Friend]RouterInvokeConfigUI(&this, dwEapTypeId, uConnectionParam, hwndParent, dwFlags, pConnectionDataIn, dwSizeOfConnectionDataIn, ppConnectionDataOut, pdwSizeOfConnectionDataOut);

	public HRESULT RouterInvokeCredentialsUI(uint32 dwEapTypeId, uint uConnectionParam, HWND hwndParent, uint32 dwFlags, uint8* pConnectionDataIn, uint32 dwSizeOfConnectionDataIn, uint8* pUserDataIn, uint32 dwSizeOfUserDataIn, uint8** ppUserDataOut, uint32* pdwSizeOfUserDataOut) mut => VT.[Friend]RouterInvokeCredentialsUI(&this, dwEapTypeId, uConnectionParam, hwndParent, dwFlags, pConnectionDataIn, dwSizeOfConnectionDataIn, pUserDataIn, dwSizeOfUserDataIn, ppUserDataOut, pdwSizeOfUserDataOut);
}

[CRepr]struct IEAPProviderConfig2 : IEAPProviderConfig
{
	public new const Guid IID = .(0xd565917a, 0x85c4, 0x4466, 0x85, 0x6e, 0x67, 0x1c, 0x37, 0x42, 0xea, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IEAPProviderConfig.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEapTypeId, uint uConnectionParam, HWND hWnd, uint8* pConfigDataIn, uint32 dwSizeOfConfigDataIn, uint8** ppConfigDataOut, uint32* pdwSizeOfConfigDataOut) ServerInvokeConfigUI2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEapTypeId, uint8** ppConfigDataOut, uint32* pdwSizeOfConfigDataOut) GetGlobalConfig;
	}


	public HRESULT ServerInvokeConfigUI2(uint32 dwEapTypeId, uint uConnectionParam, HWND hWnd, uint8* pConfigDataIn, uint32 dwSizeOfConfigDataIn, uint8** ppConfigDataOut, uint32* pdwSizeOfConfigDataOut) mut => VT.[Friend]ServerInvokeConfigUI2(&this, dwEapTypeId, uConnectionParam, hWnd, pConfigDataIn, dwSizeOfConfigDataIn, ppConfigDataOut, pdwSizeOfConfigDataOut);

	public HRESULT GetGlobalConfig(uint32 dwEapTypeId, uint8** ppConfigDataOut, uint32* pdwSizeOfConfigDataOut) mut => VT.[Friend]GetGlobalConfig(&this, dwEapTypeId, ppConfigDataOut, pdwSizeOfConfigDataOut);
}

[CRepr]struct IEAPProviderConfig3 : IEAPProviderConfig2
{
	public new const Guid IID = .(0xb78ecd12, 0x68bb, 0x4f86, 0x9b, 0xf0, 0x84, 0x38, 0xdd, 0x3b, 0xe9, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IEAPProviderConfig2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEapTypeId, uint uConnectionParam, HWND hWnd, uint8* pConfigDataIn, uint32 dwSizeOfConfigDataIn, uint8** ppConfigDataOut, uint32* pdwSizeOfConfigDataOut, uint uReserved) ServerInvokeCertificateConfigUI;
	}


	public HRESULT ServerInvokeCertificateConfigUI(uint32 dwEapTypeId, uint uConnectionParam, HWND hWnd, uint8* pConfigDataIn, uint32 dwSizeOfConfigDataIn, uint8** ppConfigDataOut, uint32* pdwSizeOfConfigDataOut, uint uReserved) mut => VT.[Friend]ServerInvokeCertificateConfigUI(&this, dwEapTypeId, uConnectionParam, hWnd, pConfigDataIn, dwSizeOfConfigDataIn, ppConfigDataOut, pdwSizeOfConfigDataOut, uReserved);
}

#endregion

#region Functions
public static
{
	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerGetMethods(EAP_METHOD_INFO_ARRAY* pEapMethodInfoArray, EAP_ERROR** ppEapError);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerGetMethodProperties(uint32 dwVersion, uint32 dwFlags, EAP_METHOD_TYPE eapMethodType, HANDLE hUserImpersonationToken, uint32 dwEapConnDataSize, uint8* pbEapConnData, uint32 dwUserDataSize, uint8* pbUserData, EAP_METHOD_PROPERTY_ARRAY* pMethodPropertyArray, EAP_ERROR** ppEapError);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerInvokeConfigUI(HWND hwndParent, uint32 dwFlags, EAP_METHOD_TYPE eapMethodType, uint32 dwSizeOfConfigIn, uint8* pConfigIn, uint32* pdwSizeOfConfigOut, uint8** ppConfigOut, EAP_ERROR** ppEapError);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerQueryCredentialInputFields(HANDLE hUserImpersonationToken, EAP_METHOD_TYPE eapMethodType, uint32 dwFlags, uint32 dwEapConnDataSize, uint8* pbEapConnData, EAP_CONFIG_INPUT_FIELD_ARRAY* pEapConfigInputFieldArray, EAP_ERROR** ppEapError);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerQueryUserBlobFromCredentialInputFields(HANDLE hUserImpersonationToken, EAP_METHOD_TYPE eapMethodType, uint32 dwFlags, uint32 dwEapConnDataSize, uint8* pbEapConnData, EAP_CONFIG_INPUT_FIELD_ARRAY* pEapConfigInputFieldArray, uint32* pdwUserBlobSize, uint8** ppbUserBlob, EAP_ERROR** ppEapError);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerInvokeIdentityUI(uint32 dwVersion, EAP_METHOD_TYPE eapMethodType, uint32 dwFlags, HWND hwndParent, uint32 dwSizeofConnectionData, uint8* pConnectionData, uint32 dwSizeofUserData, uint8* pUserData, uint32* pdwSizeOfUserDataOut, uint8** ppUserDataOut, PWSTR* ppwszIdentity, EAP_ERROR** ppEapError, void** ppvReserved);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerInvokeInteractiveUI(HWND hwndParent, uint32 dwSizeofUIContextData, uint8* pUIContextData, uint32* pdwSizeOfDataFromInteractiveUI, uint8** ppDataFromInteractiveUI, EAP_ERROR** ppEapError);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerQueryInteractiveUIInputFields(uint32 dwVersion, uint32 dwFlags, uint32 dwSizeofUIContextData, uint8* pUIContextData, EAP_INTERACTIVE_UI_DATA* pEapInteractiveUIData, EAP_ERROR** ppEapError, void** ppvReserved);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerQueryUIBlobFromInteractiveUIInputFields(uint32 dwVersion, uint32 dwFlags, uint32 dwSizeofUIContextData, uint8* pUIContextData, EAP_INTERACTIVE_UI_DATA* pEapInteractiveUIData, uint32* pdwSizeOfDataFromInteractiveUI, uint8** ppDataFromInteractiveUI, EAP_ERROR** ppEapError, void** ppvReserved);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerConfigXml2Blob(uint32 dwFlags, IXMLDOMNode* pConfigDoc, uint32* pdwSizeOfConfigOut, uint8** ppConfigOut, EAP_METHOD_TYPE* pEapMethodType, EAP_ERROR** ppEapError);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerCredentialsXml2Blob(uint32 dwFlags, IXMLDOMNode* pCredentialsDoc, uint32 dwSizeOfConfigIn, uint8* pConfigIn, uint32* pdwSizeOfCredentialsOut, uint8** ppCredentialsOut, EAP_METHOD_TYPE* pEapMethodType, EAP_ERROR** ppEapError);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerConfigBlob2Xml(uint32 dwFlags, EAP_METHOD_TYPE eapMethodType, uint32 dwSizeOfConfigIn, uint8* pConfigIn, IXMLDOMDocument2** ppConfigDoc, EAP_ERROR** ppEapError);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EapHostPeerFreeMemory(uint8* pData);

	[Import("eappcfg.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EapHostPeerFreeErrorMemory(EAP_ERROR* pEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerInitialize();

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EapHostPeerUninitialize();

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerBeginSession(uint32 dwFlags, EAP_METHOD_TYPE eapType, EAP_ATTRIBUTES* pAttributeArray, HANDLE hTokenImpersonateUser, uint32 dwSizeofConnectionData, uint8* pConnectionData, uint32 dwSizeofUserData, uint8* pUserData, uint32 dwMaxSendPacketSize, in Guid pConnectionId, NotificationHandler func, void* pContextData, uint32* pSessionId, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerProcessReceivedPacket(uint32 sessionHandle, uint32 cbReceivePacket, uint8* pReceivePacket, EapHostPeerResponseAction* pEapOutput, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerGetSendPacket(uint32 sessionHandle, uint32* pcbSendPacket, uint8** ppSendPacket, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerGetResult(uint32 sessionHandle, EapHostPeerMethodResultReason reason, EapHostPeerMethodResult* ppResult, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerGetUIContext(uint32 sessionHandle, uint32* pdwSizeOfUIContextData, uint8** ppUIContextData, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerSetUIContext(uint32 sessionHandle, uint32 dwSizeOfUIContextData, uint8* pUIContextData, EapHostPeerResponseAction* pEapOutput, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerGetResponseAttributes(uint32 sessionHandle, EAP_ATTRIBUTES* pAttribs, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerSetResponseAttributes(uint32 sessionHandle, EAP_ATTRIBUTES* pAttribs, EapHostPeerResponseAction* pEapOutput, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerGetAuthStatus(uint32 sessionHandle, EapHostPeerAuthParams authParam, uint32* pcbAuthData, uint8** ppAuthData, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerEndSession(uint32 sessionHandle, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerGetDataToUnplumbCredentials(Guid* pConnectionIdThatLastSavedCreds, int* phCredentialImpersonationToken, uint32 sessionHandle, EAP_ERROR** ppEapError, BOOL* fSaveToCredMan);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerClearConnection(Guid* pConnectionId, EAP_ERROR** ppEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EapHostPeerFreeEapError(EAP_ERROR* pEapError);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerGetIdentity(uint32 dwVersion, uint32 dwFlags, EAP_METHOD_TYPE eapMethodType, uint32 dwSizeofConnectionData, uint8* pConnectionData, uint32 dwSizeofUserData, uint8* pUserData, HANDLE hTokenImpersonateUser, BOOL* pfInvokeUI, uint32* pdwSizeOfUserDataOut, uint8** ppUserDataOut, PWSTR* ppwszIdentity, EAP_ERROR** ppEapError, uint8** ppvReserved);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EapHostPeerGetEncryptedPassword(uint32 dwSizeofPassword, PWSTR szPassword, PWSTR* ppszEncPassword);

	[Import("eappprxy.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EapHostPeerFreeRuntimeMemory(uint8* pData);

}
#endregion
