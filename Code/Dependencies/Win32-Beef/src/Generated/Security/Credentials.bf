using Win32.Foundation;
using Win32.Graphics.Gdi;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.Security.Credentials;

#region Constants
public static
{
	public const uint32 CRED_MAX_CREDENTIAL_BLOB_SIZE = 2560;
	public const uint32 CRED_MAX_USERNAME_LENGTH = 513;
	public const uint32 CRED_MAX_DOMAIN_TARGET_NAME_LENGTH = 337;
	public const uint32 FILE_DEVICE_SMARTCARD = 49;
	public const Guid GUID_DEVINTERFACE_SMARTCARD_READER = .(0x50dd5230, 0xba8a, 0x11d1, 0xbf, 0x5d, 0x00, 0x00, 0xf8, 0x05, 0xf5, 0x30);
	public const uint32 SCARD_ATR_LENGTH = 33;
	public const uint32 SCARD_PROTOCOL_UNDEFINED = 0;
	public const uint32 SCARD_PROTOCOL_T0 = 1;
	public const uint32 SCARD_PROTOCOL_T1 = 2;
	public const uint32 SCARD_PROTOCOL_RAW = 65536;
	public const uint32 SCARD_PROTOCOL_DEFAULT = 2147483648;
	public const uint32 SCARD_PROTOCOL_OPTIMAL = 0;
	public const uint32 SCARD_POWER_DOWN = 0;
	public const uint32 SCARD_COLD_RESET = 1;
	public const uint32 SCARD_WARM_RESET = 2;
	public const uint32 MAXIMUM_ATTR_STRING_LENGTH = 32;
	public const uint32 MAXIMUM_SMARTCARD_READERS = 10;
	public const uint32 SCARD_CLASS_VENDOR_INFO = 1;
	public const uint32 SCARD_CLASS_COMMUNICATIONS = 2;
	public const uint32 SCARD_CLASS_PROTOCOL = 3;
	public const uint32 SCARD_CLASS_POWER_MGMT = 4;
	public const uint32 SCARD_CLASS_SECURITY = 5;
	public const uint32 SCARD_CLASS_MECHANICAL = 6;
	public const uint32 SCARD_CLASS_VENDOR_DEFINED = 7;
	public const uint32 SCARD_CLASS_IFD_PROTOCOL = 8;
	public const uint32 SCARD_CLASS_ICC_STATE = 9;
	public const uint32 SCARD_CLASS_PERF = 32766;
	public const uint32 SCARD_CLASS_SYSTEM = 32767;
	public const uint32 SCARD_T0_HEADER_LENGTH = 7;
	public const uint32 SCARD_T0_CMD_LENGTH = 5;
	public const uint32 SCARD_T1_PROLOGUE_LENGTH = 3;
	public const uint32 SCARD_T1_EPILOGUE_LENGTH = 2;
	public const uint32 SCARD_T1_EPILOGUE_LENGTH_LRC = 1;
	public const uint32 SCARD_T1_MAX_IFS = 254;
	public const uint32 SCARD_UNKNOWN = 0;
	public const uint32 SCARD_ABSENT = 1;
	public const uint32 SCARD_PRESENT = 2;
	public const uint32 SCARD_SWALLOWED = 3;
	public const uint32 SCARD_POWERED = 4;
	public const uint32 SCARD_NEGOTIABLE = 5;
	public const uint32 SCARD_SPECIFIC = 6;
	public const uint32 SCARD_READER_SWALLOWS = 1;
	public const uint32 SCARD_READER_EJECTS = 2;
	public const uint32 SCARD_READER_CONFISCATES = 4;
	public const uint32 SCARD_READER_CONTACTLESS = 8;
	public const uint32 SCARD_READER_TYPE_SERIAL = 1;
	public const uint32 SCARD_READER_TYPE_PARALELL = 2;
	public const uint32 SCARD_READER_TYPE_KEYBOARD = 4;
	public const uint32 SCARD_READER_TYPE_SCSI = 8;
	public const uint32 SCARD_READER_TYPE_IDE = 16;
	public const uint32 SCARD_READER_TYPE_USB = 32;
	public const uint32 SCARD_READER_TYPE_PCMCIA = 64;
	public const uint32 SCARD_READER_TYPE_TPM = 128;
	public const uint32 SCARD_READER_TYPE_NFC = 256;
	public const uint32 SCARD_READER_TYPE_UICC = 512;
	public const uint32 SCARD_READER_TYPE_NGC = 1024;
	public const uint32 SCARD_READER_TYPE_EMBEDDEDSE = 2048;
	public const uint32 SCARD_READER_TYPE_VENDOR = 240;
	public const NTSTATUS STATUS_LOGON_FAILURE = -1073741715;
	public const NTSTATUS STATUS_WRONG_PASSWORD = -1073741718;
	public const NTSTATUS STATUS_PASSWORD_EXPIRED = -1073741711;
	public const NTSTATUS STATUS_PASSWORD_MUST_CHANGE = -1073741276;
	public const NTSTATUS STATUS_DOWNGRADE_DETECTED = -1073740920;
	public const NTSTATUS STATUS_AUTHENTICATION_FIREWALL_FAILED = -1073740781;
	public const NTSTATUS STATUS_ACCOUNT_DISABLED = -1073741710;
	public const NTSTATUS STATUS_ACCOUNT_RESTRICTION = -1073741714;
	public const NTSTATUS STATUS_ACCOUNT_LOCKED_OUT = -1073741260;
	public const NTSTATUS STATUS_ACCOUNT_EXPIRED = -1073741421;
	public const NTSTATUS STATUS_LOGON_TYPE_NOT_GRANTED = -1073741477;
	public const NTSTATUS STATUS_NO_SUCH_LOGON_SESSION = -1073741729;
	public const NTSTATUS STATUS_NO_SUCH_USER = -1073741724;
	public const uint32 CRED_MAX_STRING_LENGTH = 256;
	public const uint32 CRED_MAX_GENERIC_TARGET_NAME_LENGTH = 32767;
	public const uint32 CRED_MAX_TARGETNAME_NAMESPACE_LENGTH = 256;
	public const uint32 CRED_MAX_TARGETNAME_ATTRIBUTE_LENGTH = 256;
	public const uint32 CRED_MAX_VALUE_SIZE = 256;
	public const uint32 CRED_MAX_ATTRIBUTES = 64;
	public const String CRED_SESSION_WILDCARD_NAME_W = "*Session";
	public const String CRED_SESSION_WILDCARD_NAME_A = "*Session";
	public const String CRED_TARGETNAME_DOMAIN_NAMESPACE_W = "Domain";
	public const String CRED_TARGETNAME_DOMAIN_NAMESPACE_A = "Domain";
	public const String CRED_TARGETNAME_LEGACYGENERIC_NAMESPACE_W = "LegacyGeneric";
	public const String CRED_TARGETNAME_LEGACYGENERIC_NAMESPACE_A = "LegacyGeneric";
	public const String CRED_TARGETNAME_ATTRIBUTE_TARGET_W = "target";
	public const String CRED_TARGETNAME_ATTRIBUTE_TARGET_A = "target";
	public const String CRED_TARGETNAME_ATTRIBUTE_NAME_W = "name";
	public const String CRED_TARGETNAME_ATTRIBUTE_NAME_A = "name";
	public const String CRED_TARGETNAME_ATTRIBUTE_BATCH_W = "batch";
	public const String CRED_TARGETNAME_ATTRIBUTE_BATCH_A = "batch";
	public const String CRED_TARGETNAME_ATTRIBUTE_INTERACTIVE_W = "interactive";
	public const String CRED_TARGETNAME_ATTRIBUTE_INTERACTIVE_A = "interactive";
	public const String CRED_TARGETNAME_ATTRIBUTE_SERVICE_W = "service";
	public const String CRED_TARGETNAME_ATTRIBUTE_SERVICE_A = "service";
	public const String CRED_TARGETNAME_ATTRIBUTE_NETWORK_W = "network";
	public const String CRED_TARGETNAME_ATTRIBUTE_NETWORK_A = "network";
	public const String CRED_TARGETNAME_ATTRIBUTE_NETWORKCLEARTEXT_W = "networkcleartext";
	public const String CRED_TARGETNAME_ATTRIBUTE_NETWORKCLEARTEXT_A = "networkcleartext";
	public const String CRED_TARGETNAME_ATTRIBUTE_REMOTEINTERACTIVE_W = "remoteinteractive";
	public const String CRED_TARGETNAME_ATTRIBUTE_REMOTEINTERACTIVE_A = "remoteinteractive";
	public const String CRED_TARGETNAME_ATTRIBUTE_CACHEDINTERACTIVE_W = "cachedinteractive";
	public const String CRED_TARGETNAME_ATTRIBUTE_CACHEDINTERACTIVE_A = "cachedinteractive";
	public const String CRED_SESSION_WILDCARD_NAME = "*Session";
	public const String CRED_TARGETNAME_DOMAIN_NAMESPACE = "Domain";
	public const String CRED_TARGETNAME_ATTRIBUTE_NAME = "name";
	public const String CRED_TARGETNAME_ATTRIBUTE_TARGET = "target";
	public const String CRED_TARGETNAME_ATTRIBUTE_BATCH = "batch";
	public const String CRED_TARGETNAME_ATTRIBUTE_INTERACTIVE = "interactive";
	public const String CRED_TARGETNAME_ATTRIBUTE_SERVICE = "service";
	public const String CRED_TARGETNAME_ATTRIBUTE_NETWORK = "network";
	public const String CRED_TARGETNAME_ATTRIBUTE_NETWORKCLEARTEXT = "networkcleartext";
	public const String CRED_TARGETNAME_ATTRIBUTE_REMOTEINTERACTIVE = "remoteinteractive";
	public const String CRED_TARGETNAME_ATTRIBUTE_CACHEDINTERACTIVE = "cachedinteractive";
	public const uint32 CRED_LOGON_TYPES_MASK = 61440;
	public const uint32 CRED_TI_SERVER_FORMAT_UNKNOWN = 1;
	public const uint32 CRED_TI_DOMAIN_FORMAT_UNKNOWN = 2;
	public const uint32 CRED_TI_ONLY_PASSWORD_REQUIRED = 4;
	public const uint32 CRED_TI_USERNAME_TARGET = 8;
	public const uint32 CRED_TI_CREATE_EXPLICIT_CRED = 16;
	public const uint32 CRED_TI_WORKGROUP_MEMBER = 32;
	public const uint32 CRED_TI_DNSTREE_IS_DFS_SERVER = 64;
	public const uint32 CRED_TI_VALID_FLAGS = 61567;
	public const uint32 CERT_HASH_LENGTH = 20;
	public const uint32 CREDUI_MAX_MESSAGE_LENGTH = 1024;
	public const uint32 CREDUI_MAX_CAPTION_LENGTH = 128;
	public const uint32 CREDUI_MAX_GENERIC_TARGET_LENGTH = 32767;
	public const uint32 CREDUI_MAX_DOMAIN_TARGET_LENGTH = 337;
	public const uint32 CREDUI_MAX_USERNAME_LENGTH = 513;
	public const uint32 CREDUIWIN_IGNORE_CLOUDAUTHORITY_NAME = 262144;
	public const uint32 CREDUIWIN_DOWNLEVEL_HELLO_AS_SMART_CARD = 2147483648;
	public const uint32 CRED_PRESERVE_CREDENTIAL_BLOB = 1;
	public const uint32 CRED_CACHE_TARGET_INFORMATION = 1;
	public const uint32 CRED_ALLOW_NAME_RESOLUTION = 1;
	public const uint32 CRED_PROTECT_AS_SELF = 1;
	public const uint32 CRED_PROTECT_TO_SYSTEM = 2;
	public const uint32 CRED_UNPROTECT_AS_SELF = 1;
	public const uint32 CRED_UNPROTECT_ALLOW_TO_SYSTEM = 2;
	public const uint32 SCARD_SCOPE_TERMINAL = 1;
	public const String SCARD_ALL_READERS = "SCard$AllReaders\u{0000}00";
	public const String SCARD_DEFAULT_READERS = "SCard$DefaultReaders\u{0000}00";
	public const String SCARD_LOCAL_READERS = "SCard$LocalReaders\u{0000}00";
	public const String SCARD_SYSTEM_READERS = "SCard$SystemReaders\u{0000}00";
	public const uint32 SCARD_PROVIDER_PRIMARY = 1;
	public const uint32 SCARD_PROVIDER_CSP = 2;
	public const uint32 SCARD_PROVIDER_KSP = 3;
	public const uint32 SCARD_STATE_UNPOWERED = 1024;
	public const uint32 SCARD_SHARE_EXCLUSIVE = 1;
	public const uint32 SCARD_SHARE_SHARED = 2;
	public const uint32 SCARD_SHARE_DIRECT = 3;
	public const uint32 SCARD_LEAVE_CARD = 0;
	public const uint32 SCARD_RESET_CARD = 1;
	public const uint32 SCARD_UNPOWER_CARD = 2;
	public const uint32 SCARD_EJECT_CARD = 3;
	public const uint32 SC_DLG_MINIMAL_UI = 1;
	public const uint32 SC_DLG_NO_UI = 2;
	public const uint32 SC_DLG_FORCE_UI = 4;
	public const uint32 SCERR_NOCARDNAME = 16384;
	public const uint32 SCERR_NOGUIDS = 32768;
	public const uint32 SCARD_AUDIT_CHV_FAILURE = 0;
	public const uint32 SCARD_AUDIT_CHV_SUCCESS = 1;
	public const String CREDSSP_NAME = "CREDSSP";
	public const String TS_SSP_NAME_A = "TSSSP";
	public const String TS_SSP_NAME = "TSSSP";
	public const String szOID_TS_KP_TS_SERVER_AUTH = "1.3.6.1.4.1.311.54.1.2";
	public const uint32 CREDSSP_SERVER_AUTH_NEGOTIATE = 1;
	public const uint32 CREDSSP_SERVER_AUTH_CERTIFICATE = 2;
	public const uint32 CREDSSP_SERVER_AUTH_LOOPBACK = 4;
	public const uint32 SECPKG_ALT_ATTR = 2147483648;
	public const uint32 SECPKG_ATTR_C_FULL_IDENT_TOKEN = 2147483781;
	public const uint32 CREDSSP_CRED_EX_VERSION = 0;
	public const uint32 CREDSSP_FLAG_REDIRECT = 1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum CRED_FLAGS : uint32
{
	CRED_FLAGS_PASSWORD_FOR_CERT = 1,
	CRED_FLAGS_PROMPT_NOW = 2,
	CRED_FLAGS_USERNAME_TARGET = 4,
	CRED_FLAGS_OWF_CRED_BLOB = 8,
	CRED_FLAGS_REQUIRE_CONFIRMATION = 16,
	CRED_FLAGS_WILDCARD_MATCH = 32,
	CRED_FLAGS_VSM_PROTECTED = 64,
	CRED_FLAGS_NGC_CERT = 128,
	CRED_FLAGS_VALID_FLAGS = 61695,
	CRED_FLAGS_VALID_INPUT_FLAGS = 61599,
}


[AllowDuplicates]
public enum CRED_TYPE : uint32
{
	CRED_TYPE_GENERIC = 1,
	CRED_TYPE_DOMAIN_PASSWORD = 2,
	CRED_TYPE_DOMAIN_CERTIFICATE = 3,
	CRED_TYPE_DOMAIN_VISIBLE_PASSWORD = 4,
	CRED_TYPE_GENERIC_CERTIFICATE = 5,
	CRED_TYPE_DOMAIN_EXTENDED = 6,
	CRED_TYPE_MAXIMUM = 7,
	CRED_TYPE_MAXIMUM_EX = 1007,
}


[AllowDuplicates]
public enum CRED_PERSIST : uint32
{
	CRED_PERSIST_NONE = 0,
	CRED_PERSIST_SESSION = 1,
	CRED_PERSIST_LOCAL_MACHINE = 2,
	CRED_PERSIST_ENTERPRISE = 3,
}


[AllowDuplicates]
public enum CREDUI_FLAGS : uint32
{
	CREDUI_FLAGS_ALWAYS_SHOW_UI = 128,
	CREDUI_FLAGS_COMPLETE_USERNAME = 2048,
	CREDUI_FLAGS_DO_NOT_PERSIST = 2,
	CREDUI_FLAGS_EXCLUDE_CERTIFICATES = 8,
	CREDUI_FLAGS_EXPECT_CONFIRMATION = 131072,
	CREDUI_FLAGS_GENERIC_CREDENTIALS = 262144,
	CREDUI_FLAGS_INCORRECT_PASSWORD = 1,
	CREDUI_FLAGS_KEEP_USERNAME = 1048576,
	CREDUI_FLAGS_PASSWORD_ONLY_OK = 512,
	CREDUI_FLAGS_PERSIST = 4096,
	CREDUI_FLAGS_REQUEST_ADMINISTRATOR = 4,
	CREDUI_FLAGS_REQUIRE_CERTIFICATE = 16,
	CREDUI_FLAGS_REQUIRE_SMARTCARD = 256,
	CREDUI_FLAGS_SERVER_CREDENTIAL = 16384,
	CREDUI_FLAGS_SHOW_SAVE_CHECK_BOX = 64,
	CREDUI_FLAGS_USERNAME_TARGET_CREDENTIALS = 524288,
	CREDUI_FLAGS_VALIDATE_USERNAME = 1024,
}


[AllowDuplicates]
public enum SCARD_SCOPE : uint32
{
	SCARD_SCOPE_USER = 0,
	SCARD_SCOPE_SYSTEM = 2,
}


[AllowDuplicates]
public enum CRED_ENUMERATE_FLAGS : uint32
{
	CRED_ENUMERATE_ALL_CREDENTIALS = 1,
}


[AllowDuplicates]
public enum CREDUIWIN_FLAGS : uint32
{
	CREDUIWIN_GENERIC = 1,
	CREDUIWIN_CHECKBOX = 2,
	CREDUIWIN_AUTHPACKAGE_ONLY = 16,
	CREDUIWIN_IN_CRED_ONLY = 32,
	CREDUIWIN_ENUMERATE_ADMINS = 256,
	CREDUIWIN_ENUMERATE_CURRENT_USER = 512,
	CREDUIWIN_SECURE_PROMPT = 4096,
	CREDUIWIN_PREPROMPTING = 8192,
	CREDUIWIN_PACK_32_WOW = 268435456,
}


[AllowDuplicates]
public enum SCARD_STATE : uint32
{
	SCARD_STATE_UNAWARE = 0,
	SCARD_STATE_IGNORE = 1,
	SCARD_STATE_UNAVAILABLE = 8,
	SCARD_STATE_EMPTY = 16,
	SCARD_STATE_PRESENT = 32,
	SCARD_STATE_ATRMATCH = 64,
	SCARD_STATE_EXCLUSIVE = 128,
	SCARD_STATE_INUSE = 256,
	SCARD_STATE_MUTE = 512,
	SCARD_STATE_CHANGED = 2,
	SCARD_STATE_UNKNOWN = 4,
}


[AllowDuplicates]
public enum CRED_PACK_FLAGS : uint32
{
	CRED_PACK_PROTECTED_CREDENTIALS = 1,
	CRED_PACK_WOW_BUFFER = 2,
	CRED_PACK_GENERIC_CREDENTIALS = 4,
	CRED_PACK_ID_PROVIDER_CREDENTIALS = 8,
}


[AllowDuplicates]
public enum KeyCredentialManagerOperationErrorStates : uint32
{
	KeyCredentialManagerOperationErrorStateNone = 0,
	KeyCredentialManagerOperationErrorStateDeviceJoinFailure = 1,
	KeyCredentialManagerOperationErrorStateTokenFailure = 2,
	KeyCredentialManagerOperationErrorStateCertificateFailure = 4,
	KeyCredentialManagerOperationErrorStateRemoteSessionFailure = 8,
	KeyCredentialManagerOperationErrorStatePolicyFailure = 16,
	KeyCredentialManagerOperationErrorStateHardwareFailure = 32,
	KeyCredentialManagerOperationErrorStatePinExistsFailure = 64,
}


[AllowDuplicates]
public enum KeyCredentialManagerOperationType : int32
{
	KeyCredentialManagerProvisioning = 0,
	KeyCredentialManagerPinChange = 1,
	KeyCredentialManagerPinReset = 2,
}


[AllowDuplicates]
public enum CRED_MARSHAL_TYPE : int32
{
	CertCredential = 1,
	UsernameTargetCredential = 2,
	BinaryBlobCredential = 3,
	UsernameForPackedCredentials = 4,
	BinaryBlobForSystem = 5,
}


[AllowDuplicates]
public enum CRED_PROTECTION_TYPE : int32
{
	CredUnprotected = 0,
	CredUserProtection = 1,
	CredTrustedProtection = 2,
	CredForSystemProtection = 3,
}


[AllowDuplicates]
public enum READER_SEL_REQUEST_MATCH_TYPE : int32
{
	RSR_MATCH_TYPE_READER_AND_CONTAINER = 1,
	RSR_MATCH_TYPE_SERIAL_NUMBER = 2,
	RSR_MATCH_TYPE_ALL_CARDS = 3,
}


[AllowDuplicates]
public enum CREDSPP_SUBMIT_TYPE : int32
{
	CredsspPasswordCreds = 2,
	CredsspSchannelCreds = 4,
	CredsspCertificateCreds = 13,
	CredsspSubmitBufferBoth = 50,
	CredsspSubmitBufferBothOld = 51,
	CredsspCredEx = 100,
}

#endregion

#region Function Pointers
public function uint LPOCNCONNPROCA(uint param0, PSTR param1, PSTR param2, void* param3);

public function uint LPOCNCONNPROCW(uint param0, PWSTR param1, PWSTR param2, void* param3);

public function BOOL LPOCNCHKPROC(uint param0, uint param1, void* param2);

public function void LPOCNDSCPROC(uint param0, uint param1, void* param2);

#endregion

#region Structs
[CRepr]
public struct KeyCredentialManagerInfo
{
	public Guid containerId;
}

[CRepr]
public struct SecHandle
{
	public uint dwLower;
	public uint dwUpper;
}

[CRepr]
public struct CREDENTIAL_ATTRIBUTEA
{
	public PSTR Keyword;
	public uint32 Flags;
	public uint32 ValueSize;
	public uint8* Value;
}

[CRepr]
public struct CREDENTIAL_ATTRIBUTEW
{
	public PWSTR Keyword;
	public uint32 Flags;
	public uint32 ValueSize;
	public uint8* Value;
}

[CRepr]
public struct CREDENTIALA
{
	public CRED_FLAGS Flags;
	public CRED_TYPE Type;
	public PSTR TargetName;
	public PSTR Comment;
	public FILETIME LastWritten;
	public uint32 CredentialBlobSize;
	public uint8* CredentialBlob;
	public CRED_PERSIST Persist;
	public uint32 AttributeCount;
	public CREDENTIAL_ATTRIBUTEA* Attributes;
	public PSTR TargetAlias;
	public PSTR UserName;
}

[CRepr]
public struct CREDENTIALW
{
	public CRED_FLAGS Flags;
	public CRED_TYPE Type;
	public PWSTR TargetName;
	public PWSTR Comment;
	public FILETIME LastWritten;
	public uint32 CredentialBlobSize;
	public uint8* CredentialBlob;
	public CRED_PERSIST Persist;
	public uint32 AttributeCount;
	public CREDENTIAL_ATTRIBUTEW* Attributes;
	public PWSTR TargetAlias;
	public PWSTR UserName;
}

[CRepr]
public struct CREDENTIAL_TARGET_INFORMATIONA
{
	public PSTR TargetName;
	public PSTR NetbiosServerName;
	public PSTR DnsServerName;
	public PSTR NetbiosDomainName;
	public PSTR DnsDomainName;
	public PSTR DnsTreeName;
	public PSTR PackageName;
	public uint32 Flags;
	public uint32 CredTypeCount;
	public uint32* CredTypes;
}

[CRepr]
public struct CREDENTIAL_TARGET_INFORMATIONW
{
	public PWSTR TargetName;
	public PWSTR NetbiosServerName;
	public PWSTR DnsServerName;
	public PWSTR NetbiosDomainName;
	public PWSTR DnsDomainName;
	public PWSTR DnsTreeName;
	public PWSTR PackageName;
	public uint32 Flags;
	public uint32 CredTypeCount;
	public uint32* CredTypes;
}

[CRepr]
public struct CERT_CREDENTIAL_INFO
{
	public uint32 cbSize;
	public uint8[20] rgbHashOfCert;
}

[CRepr]
public struct USERNAME_TARGET_CREDENTIAL_INFO
{
	public PWSTR UserName;
}

[CRepr]
public struct BINARY_BLOB_CREDENTIAL_INFO
{
	public uint32 cbBlob;
	public uint8* pbBlob;
}

[CRepr]
public struct CREDUI_INFOA
{
	public uint32 cbSize;
	public HWND hwndParent;
	public PSTR pszMessageText;
	public PSTR pszCaptionText;
	public HBITMAP hbmBanner;
}

[CRepr]
public struct CREDUI_INFOW
{
	public uint32 cbSize;
	public HWND hwndParent;
	public PWSTR pszMessageText;
	public PWSTR pszCaptionText;
	public HBITMAP hbmBanner;
}

[CRepr]
public struct SCARD_IO_REQUEST
{
	public uint32 dwProtocol;
	public uint32 cbPciLength;
}

[CRepr]
public struct SCARD_T0_COMMAND
{
	public uint8 bCla;
	public uint8 bIns;
	public uint8 bP1;
	public uint8 bP2;
	public uint8 bP3;
}

[CRepr]
public struct SCARD_T0_REQUEST
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public SCARD_T0_COMMAND CmdBytes;
		public uint8[5] rgbHeader;
	}
	public SCARD_IO_REQUEST ioRequest;
	public uint8 bSw1;
	public uint8 bSw2;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct SCARD_T1_REQUEST
{
	public SCARD_IO_REQUEST ioRequest;
}

[CRepr]
public struct SCARD_READERSTATEA
{
	public PSTR szReader;
	public void* pvUserData;
	public SCARD_STATE dwCurrentState;
	public SCARD_STATE dwEventState;
	public uint32 cbAtr;
	public uint8[36] rgbAtr;
}

[CRepr]
public struct SCARD_READERSTATEW
{
	public PWSTR szReader;
	public void* pvUserData;
	public SCARD_STATE dwCurrentState;
	public SCARD_STATE dwEventState;
	public uint32 cbAtr;
	public uint8[36] rgbAtr;
}

[CRepr]
public struct SCARD_ATRMASK
{
	public uint32 cbAtr;
	public uint8[36] rgbAtr;
	public uint8[36] rgbMask;
}

[CRepr]
public struct OPENCARD_SEARCH_CRITERIAA
{
	public uint32 dwStructSize;
	public PSTR lpstrGroupNames;
	public uint32 nMaxGroupNames;
	public Guid* rgguidInterfaces;
	public uint32 cguidInterfaces;
	public PSTR lpstrCardNames;
	public uint32 nMaxCardNames;
	public LPOCNCHKPROC lpfnCheck;
	public LPOCNCONNPROCA lpfnConnect;
	public LPOCNDSCPROC lpfnDisconnect;
	public void* pvUserData;
	public uint32 dwShareMode;
	public uint32 dwPreferredProtocols;
}

[CRepr]
public struct OPENCARD_SEARCH_CRITERIAW
{
	public uint32 dwStructSize;
	public PWSTR lpstrGroupNames;
	public uint32 nMaxGroupNames;
	public Guid* rgguidInterfaces;
	public uint32 cguidInterfaces;
	public PWSTR lpstrCardNames;
	public uint32 nMaxCardNames;
	public LPOCNCHKPROC lpfnCheck;
	public LPOCNCONNPROCW lpfnConnect;
	public LPOCNDSCPROC lpfnDisconnect;
	public void* pvUserData;
	public uint32 dwShareMode;
	public uint32 dwPreferredProtocols;
}

[CRepr]
public struct OPENCARDNAME_EXA
{
	public uint32 dwStructSize;
	public uint hSCardContext;
	public HWND hwndOwner;
	public uint32 dwFlags;
	public PSTR lpstrTitle;
	public PSTR lpstrSearchDesc;
	public HICON hIcon;
	public OPENCARD_SEARCH_CRITERIAA* pOpenCardSearchCriteria;
	public LPOCNCONNPROCA lpfnConnect;
	public void* pvUserData;
	public uint32 dwShareMode;
	public uint32 dwPreferredProtocols;
	public PSTR lpstrRdr;
	public uint32 nMaxRdr;
	public PSTR lpstrCard;
	public uint32 nMaxCard;
	public uint32 dwActiveProtocol;
	public uint hCardHandle;
}

[CRepr]
public struct OPENCARDNAME_EXW
{
	public uint32 dwStructSize;
	public uint hSCardContext;
	public HWND hwndOwner;
	public uint32 dwFlags;
	public PWSTR lpstrTitle;
	public PWSTR lpstrSearchDesc;
	public HICON hIcon;
	public OPENCARD_SEARCH_CRITERIAW* pOpenCardSearchCriteria;
	public LPOCNCONNPROCW lpfnConnect;
	public void* pvUserData;
	public uint32 dwShareMode;
	public uint32 dwPreferredProtocols;
	public PWSTR lpstrRdr;
	public uint32 nMaxRdr;
	public PWSTR lpstrCard;
	public uint32 nMaxCard;
	public uint32 dwActiveProtocol;
	public uint hCardHandle;
}

[CRepr]
public struct READER_SEL_REQUEST
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _SerialNumberParameter_e__Struct
		{
			public uint32 cbSerialNumberOffset;
			public uint32 cbSerialNumberLength;
			public uint32 dwDesiredCardModuleVersion;
		}
		[CRepr]
		public struct _ReaderAndContainerParameter_e__Struct
		{
			public uint32 cbReaderNameOffset;
			public uint32 cchReaderNameLength;
			public uint32 cbContainerNameOffset;
			public uint32 cchContainerNameLength;
			public uint32 dwDesiredCardModuleVersion;
			public uint32 dwCspFlags;
		}
		public _ReaderAndContainerParameter_e__Struct ReaderAndContainerParameter;
		public _SerialNumberParameter_e__Struct SerialNumberParameter;
	}
	public uint32 dwShareMode;
	public uint32 dwPreferredProtocols;
	public READER_SEL_REQUEST_MATCH_TYPE MatchType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct READER_SEL_RESPONSE
{
	public uint32 cbReaderNameOffset;
	public uint32 cchReaderNameLength;
	public uint32 cbCardNameOffset;
	public uint32 cchCardNameLength;
}

[CRepr]
public struct OPENCARDNAMEA
{
	public uint32 dwStructSize;
	public HWND hwndOwner;
	public uint hSCardContext;
	public PSTR lpstrGroupNames;
	public uint32 nMaxGroupNames;
	public PSTR lpstrCardNames;
	public uint32 nMaxCardNames;
	public Guid* rgguidInterfaces;
	public uint32 cguidInterfaces;
	public PSTR lpstrRdr;
	public uint32 nMaxRdr;
	public PSTR lpstrCard;
	public uint32 nMaxCard;
	public PSTR lpstrTitle;
	public uint32 dwFlags;
	public void* pvUserData;
	public uint32 dwShareMode;
	public uint32 dwPreferredProtocols;
	public uint32 dwActiveProtocol;
	public LPOCNCONNPROCA lpfnConnect;
	public LPOCNCHKPROC lpfnCheck;
	public LPOCNDSCPROC lpfnDisconnect;
	public uint hCardHandle;
}

[CRepr]
public struct OPENCARDNAMEW
{
	public uint32 dwStructSize;
	public HWND hwndOwner;
	public uint hSCardContext;
	public PWSTR lpstrGroupNames;
	public uint32 nMaxGroupNames;
	public PWSTR lpstrCardNames;
	public uint32 nMaxCardNames;
	public Guid* rgguidInterfaces;
	public uint32 cguidInterfaces;
	public PWSTR lpstrRdr;
	public uint32 nMaxRdr;
	public PWSTR lpstrCard;
	public uint32 nMaxCard;
	public PWSTR lpstrTitle;
	public uint32 dwFlags;
	public void* pvUserData;
	public uint32 dwShareMode;
	public uint32 dwPreferredProtocols;
	public uint32 dwActiveProtocol;
	public LPOCNCONNPROCW lpfnConnect;
	public LPOCNCHKPROC lpfnCheck;
	public LPOCNDSCPROC lpfnDisconnect;
	public uint hCardHandle;
}

[CRepr]
public struct SecPkgContext_ClientCreds
{
	public uint32 AuthBufferLen;
	public uint8* AuthBuffer;
}

[CRepr]
public struct CREDSSP_CRED
{
	public CREDSPP_SUBMIT_TYPE Type;
	public void* pSchannelCred;
	public void* pSpnegoCred;
}

[CRepr]
public struct CREDSSP_CRED_EX
{
	public CREDSPP_SUBMIT_TYPE Type;
	public uint32 Version;
	public uint32 Flags;
	public uint32 Reserved;
	public CREDSSP_CRED Cred;
}

#endregion

#region Functions
public static
{
	[Import("KeyCredMgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT KeyCredentialManagerGetOperationErrorStates(KeyCredentialManagerOperationType keyCredentialManagerOperationType, BOOL* isReady, KeyCredentialManagerOperationErrorStates* keyCredentialManagerOperationErrorStates);

	[Import("KeyCredMgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT KeyCredentialManagerShowUIOperation(HWND hWndOwner, KeyCredentialManagerOperationType keyCredentialManagerOperationType);

	[Import("KeyCredMgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT KeyCredentialManagerGetInformation(KeyCredentialManagerInfo** keyCredentialManagerInfo);

	[Import("KeyCredMgr.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void KeyCredentialManagerFreeInformation(KeyCredentialManagerInfo* keyCredentialManagerInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredWriteW(CREDENTIALW* Credential, uint32 Flags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredWriteA(CREDENTIALA* Credential, uint32 Flags);
	public static BOOL CredWrite(CREDENTIALA* Credential, uint32 Flags) => CredWriteA(Credential, Flags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredReadW(PWSTR TargetName, uint32 Type, uint32 Flags, CREDENTIALW** Credential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredReadA(PSTR TargetName, uint32 Type, uint32 Flags, CREDENTIALA** Credential);
	public static BOOL CredRead(PSTR TargetName, uint32 Type, uint32 Flags, CREDENTIALA** Credential) => CredReadA(TargetName, Type, Flags, Credential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredEnumerateW(PWSTR Filter, CRED_ENUMERATE_FLAGS Flags, uint32* Count, CREDENTIALW*** Credential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredEnumerateA(PSTR Filter, CRED_ENUMERATE_FLAGS Flags, uint32* Count, CREDENTIALA*** Credential);
	public static BOOL CredEnumerate(PSTR Filter, CRED_ENUMERATE_FLAGS Flags, uint32* Count, CREDENTIALA*** Credential) => CredEnumerateA(Filter, Flags, Count, Credential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredWriteDomainCredentialsW(CREDENTIAL_TARGET_INFORMATIONW* TargetInfo, CREDENTIALW* Credential, uint32 Flags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredWriteDomainCredentialsA(CREDENTIAL_TARGET_INFORMATIONA* TargetInfo, CREDENTIALA* Credential, uint32 Flags);
	public static BOOL CredWriteDomainCredentials(CREDENTIAL_TARGET_INFORMATIONA* TargetInfo, CREDENTIALA* Credential, uint32 Flags) => CredWriteDomainCredentialsA(TargetInfo, Credential, Flags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredReadDomainCredentialsW(CREDENTIAL_TARGET_INFORMATIONW* TargetInfo, uint32 Flags, uint32* Count, CREDENTIALW*** Credential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredReadDomainCredentialsA(CREDENTIAL_TARGET_INFORMATIONA* TargetInfo, uint32 Flags, uint32* Count, CREDENTIALA*** Credential);
	public static BOOL CredReadDomainCredentials(CREDENTIAL_TARGET_INFORMATIONA* TargetInfo, uint32 Flags, uint32* Count, CREDENTIALA*** Credential) => CredReadDomainCredentialsA(TargetInfo, Flags, Count, Credential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredDeleteW(PWSTR TargetName, uint32 Type, uint32 Flags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredDeleteA(PSTR TargetName, uint32 Type, uint32 Flags);
	public static BOOL CredDelete(PSTR TargetName, uint32 Type, uint32 Flags) => CredDeleteA(TargetName, Type, Flags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredRenameW(PWSTR OldTargetName, PWSTR NewTargetName, uint32 Type, uint32 Flags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredRenameA(PSTR OldTargetName, PSTR NewTargetName, uint32 Type, uint32 Flags);
	public static BOOL CredRename(PSTR OldTargetName, PSTR NewTargetName, uint32 Type, uint32 Flags) => CredRenameA(OldTargetName, NewTargetName, Type, Flags);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredGetTargetInfoW(PWSTR TargetName, uint32 Flags, CREDENTIAL_TARGET_INFORMATIONW** TargetInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredGetTargetInfoA(PSTR TargetName, uint32 Flags, CREDENTIAL_TARGET_INFORMATIONA** TargetInfo);
	public static BOOL CredGetTargetInfo(PSTR TargetName, uint32 Flags, CREDENTIAL_TARGET_INFORMATIONA** TargetInfo) => CredGetTargetInfoA(TargetName, Flags, TargetInfo);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredMarshalCredentialW(CRED_MARSHAL_TYPE CredType, void* Credential, PWSTR* MarshaledCredential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredMarshalCredentialA(CRED_MARSHAL_TYPE CredType, void* Credential, PSTR* MarshaledCredential);
	public static BOOL CredMarshalCredential(CRED_MARSHAL_TYPE CredType, void* Credential, PSTR* MarshaledCredential) => CredMarshalCredentialA(CredType, Credential, MarshaledCredential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredUnmarshalCredentialW(PWSTR MarshaledCredential, CRED_MARSHAL_TYPE* CredType, void** Credential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredUnmarshalCredentialA(PSTR MarshaledCredential, CRED_MARSHAL_TYPE* CredType, void** Credential);
	public static BOOL CredUnmarshalCredential(PSTR MarshaledCredential, CRED_MARSHAL_TYPE* CredType, void** Credential) => CredUnmarshalCredentialA(MarshaledCredential, CredType, Credential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredIsMarshaledCredentialW(PWSTR MarshaledCredential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredIsMarshaledCredentialA(PSTR MarshaledCredential);
	public static BOOL CredIsMarshaledCredential(PSTR MarshaledCredential) => CredIsMarshaledCredentialA(MarshaledCredential);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredUnPackAuthenticationBufferW(CRED_PACK_FLAGS dwFlags, void* pAuthBuffer, uint32 cbAuthBuffer, char16* pszUserName, uint32* pcchMaxUserName, char16* pszDomainName, uint32* pcchMaxDomainName, char16* pszPassword, uint32* pcchMaxPassword);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredUnPackAuthenticationBufferA(CRED_PACK_FLAGS dwFlags, void* pAuthBuffer, uint32 cbAuthBuffer, uint8* pszUserName, uint32* pcchlMaxUserName, uint8* pszDomainName, uint32* pcchMaxDomainName, uint8* pszPassword, uint32* pcchMaxPassword);
	public static BOOL CredUnPackAuthenticationBuffer(CRED_PACK_FLAGS dwFlags, void* pAuthBuffer, uint32 cbAuthBuffer, uint8* pszUserName, uint32* pcchlMaxUserName, uint8* pszDomainName, uint32* pcchMaxDomainName, uint8* pszPassword, uint32* pcchMaxPassword) => CredUnPackAuthenticationBufferA(dwFlags, pAuthBuffer, cbAuthBuffer, pszUserName, pcchlMaxUserName, pszDomainName, pcchMaxDomainName, pszPassword, pcchMaxPassword);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredPackAuthenticationBufferW(CRED_PACK_FLAGS dwFlags, PWSTR pszUserName, PWSTR pszPassword, uint8* pPackedCredentials, uint32* pcbPackedCredentials);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredPackAuthenticationBufferA(CRED_PACK_FLAGS dwFlags, PSTR pszUserName, PSTR pszPassword, uint8* pPackedCredentials, uint32* pcbPackedCredentials);
	public static BOOL CredPackAuthenticationBuffer(CRED_PACK_FLAGS dwFlags, PSTR pszUserName, PSTR pszPassword, uint8* pPackedCredentials, uint32* pcbPackedCredentials) => CredPackAuthenticationBufferA(dwFlags, pszUserName, pszPassword, pPackedCredentials, pcbPackedCredentials);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredProtectW(BOOL fAsSelf, char16* pszCredentials, uint32 cchCredentials, char16* pszProtectedCredentials, uint32* pcchMaxChars, CRED_PROTECTION_TYPE* ProtectionType);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredProtectA(BOOL fAsSelf, uint8* pszCredentials, uint32 cchCredentials, uint8* pszProtectedCredentials, uint32* pcchMaxChars, CRED_PROTECTION_TYPE* ProtectionType);
	public static BOOL CredProtect(BOOL fAsSelf, uint8* pszCredentials, uint32 cchCredentials, uint8* pszProtectedCredentials, uint32* pcchMaxChars, CRED_PROTECTION_TYPE* ProtectionType) => CredProtectA(fAsSelf, pszCredentials, cchCredentials, pszProtectedCredentials, pcchMaxChars, ProtectionType);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredUnprotectW(BOOL fAsSelf, char16* pszProtectedCredentials, uint32 cchProtectedCredentials, char16* pszCredentials, uint32* pcchMaxChars);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredUnprotectA(BOOL fAsSelf, uint8* pszProtectedCredentials, uint32 cchProtectedCredentials, uint8* pszCredentials, uint32* pcchMaxChars);
	public static BOOL CredUnprotect(BOOL fAsSelf, uint8* pszProtectedCredentials, uint32 cchProtectedCredentials, uint8* pszCredentials, uint32* pcchMaxChars) => CredUnprotectA(fAsSelf, pszProtectedCredentials, cchProtectedCredentials, pszCredentials, pcchMaxChars);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredIsProtectedW(PWSTR pszProtectedCredentials, CRED_PROTECTION_TYPE* pProtectionType);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredIsProtectedA(PSTR pszProtectedCredentials, CRED_PROTECTION_TYPE* pProtectionType);
	public static BOOL CredIsProtected(PSTR pszProtectedCredentials, CRED_PROTECTION_TYPE* pProtectionType) => CredIsProtectedA(pszProtectedCredentials, pProtectionType);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredFindBestCredentialW(PWSTR TargetName, uint32 Type, uint32 Flags, CREDENTIALW** Credential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredFindBestCredentialA(PSTR TargetName, uint32 Type, uint32 Flags, CREDENTIALA** Credential);
	public static BOOL CredFindBestCredential(PSTR TargetName, uint32 Type, uint32 Flags, CREDENTIALA** Credential) => CredFindBestCredentialA(TargetName, Type, Flags, Credential);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CredGetSessionTypes(uint32 MaximumPersistCount, uint32* MaximumPersist);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CredFree(void* Buffer);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUIPromptForCredentialsW(CREDUI_INFOW* pUiInfo, PWSTR pszTargetName, SecHandle* pContext, uint32 dwAuthError, char16* pszUserName, uint32 ulUserNameBufferSize, char16* pszPassword, uint32 ulPasswordBufferSize, BOOL* save, CREDUI_FLAGS dwFlags);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUIPromptForCredentialsA(CREDUI_INFOA* pUiInfo, PSTR pszTargetName, SecHandle* pContext, uint32 dwAuthError, uint8* pszUserName, uint32 ulUserNameBufferSize, uint8* pszPassword, uint32 ulPasswordBufferSize, BOOL* save, CREDUI_FLAGS dwFlags);
	public static uint32 CredUIPromptForCredentials(CREDUI_INFOA* pUiInfo, PSTR pszTargetName, SecHandle* pContext, uint32 dwAuthError, uint8* pszUserName, uint32 ulUserNameBufferSize, uint8* pszPassword, uint32 ulPasswordBufferSize, BOOL* save, CREDUI_FLAGS dwFlags) => CredUIPromptForCredentialsA(pUiInfo, pszTargetName, pContext, dwAuthError, pszUserName, ulUserNameBufferSize, pszPassword, ulPasswordBufferSize, save, dwFlags);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUIPromptForWindowsCredentialsW(CREDUI_INFOW* pUiInfo, uint32 dwAuthError, uint32* pulAuthPackage, void* pvInAuthBuffer, uint32 ulInAuthBufferSize, void** ppvOutAuthBuffer, uint32* pulOutAuthBufferSize, BOOL* pfSave, CREDUIWIN_FLAGS dwFlags);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUIPromptForWindowsCredentialsA(CREDUI_INFOA* pUiInfo, uint32 dwAuthError, uint32* pulAuthPackage, void* pvInAuthBuffer, uint32 ulInAuthBufferSize, void** ppvOutAuthBuffer, uint32* pulOutAuthBufferSize, BOOL* pfSave, CREDUIWIN_FLAGS dwFlags);
	public static uint32 CredUIPromptForWindowsCredentials(CREDUI_INFOA* pUiInfo, uint32 dwAuthError, uint32* pulAuthPackage, void* pvInAuthBuffer, uint32 ulInAuthBufferSize, void** ppvOutAuthBuffer, uint32* pulOutAuthBufferSize, BOOL* pfSave, CREDUIWIN_FLAGS dwFlags) => CredUIPromptForWindowsCredentialsA(pUiInfo, dwAuthError, pulAuthPackage, pvInAuthBuffer, ulInAuthBufferSize, ppvOutAuthBuffer, pulOutAuthBufferSize, pfSave, dwFlags);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUIParseUserNameW(PWSTR UserName, char16* user, uint32 userBufferSize, char16* domain, uint32 domainBufferSize);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUIParseUserNameA(PSTR userName, uint8* user, uint32 userBufferSize, uint8* domain, uint32 domainBufferSize);
	public static uint32 CredUIParseUserName(PSTR userName, uint8* user, uint32 userBufferSize, uint8* domain, uint32 domainBufferSize) => CredUIParseUserNameA(userName, user, userBufferSize, domain, domainBufferSize);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUICmdLinePromptForCredentialsW(PWSTR pszTargetName, SecHandle* pContext, uint32 dwAuthError, char16* UserName, uint32 ulUserBufferSize, char16* pszPassword, uint32 ulPasswordBufferSize, BOOL* pfSave, CREDUI_FLAGS dwFlags);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUICmdLinePromptForCredentialsA(PSTR pszTargetName, SecHandle* pContext, uint32 dwAuthError, uint8* UserName, uint32 ulUserBufferSize, uint8* pszPassword, uint32 ulPasswordBufferSize, BOOL* pfSave, CREDUI_FLAGS dwFlags);
	public static uint32 CredUICmdLinePromptForCredentials(PSTR pszTargetName, SecHandle* pContext, uint32 dwAuthError, uint8* UserName, uint32 ulUserBufferSize, uint8* pszPassword, uint32 ulPasswordBufferSize, BOOL* pfSave, CREDUI_FLAGS dwFlags) => CredUICmdLinePromptForCredentialsA(pszTargetName, pContext, dwAuthError, UserName, ulUserBufferSize, pszPassword, ulPasswordBufferSize, pfSave, dwFlags);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUIConfirmCredentialsW(PWSTR pszTargetName, BOOL bConfirm);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUIConfirmCredentialsA(PSTR pszTargetName, BOOL bConfirm);
	public static uint32 CredUIConfirmCredentials(PSTR pszTargetName, BOOL bConfirm) => CredUIConfirmCredentialsA(pszTargetName, bConfirm);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUIStoreSSOCredW(PWSTR pszRealm, PWSTR pszUsername, PWSTR pszPassword, BOOL bPersist);

	[Import("credui.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CredUIReadSSOCredW(PWSTR pszRealm, PWSTR* ppszUsername);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardEstablishContext(SCARD_SCOPE dwScope, void* pvReserved1, void* pvReserved2, uint* phContext);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardReleaseContext(uint hContext);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardIsValidContext(uint hContext);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardListReaderGroupsA(uint hContext, uint8* mszGroups, uint32* pcchGroups);
	public static int32 SCardListReaderGroups(uint hContext, uint8* mszGroups, uint32* pcchGroups) => SCardListReaderGroupsA(hContext, mszGroups, pcchGroups);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardListReaderGroupsW(uint hContext, char16* mszGroups, uint32* pcchGroups);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardListReadersA(uint hContext, PSTR mszGroups, uint8* mszReaders, uint32* pcchReaders);
	public static int32 SCardListReaders(uint hContext, PSTR mszGroups, uint8* mszReaders, uint32* pcchReaders) => SCardListReadersA(hContext, mszGroups, mszReaders, pcchReaders);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardListReadersW(uint hContext, PWSTR mszGroups, char16* mszReaders, uint32* pcchReaders);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardListCardsA(uint hContext, uint8* pbAtr, Guid* rgquidInterfaces, uint32 cguidInterfaceCount, uint8* mszCards, uint32* pcchCards);
	public static int32 SCardListCards(uint hContext, uint8* pbAtr, Guid* rgquidInterfaces, uint32 cguidInterfaceCount, uint8* mszCards, uint32* pcchCards) => SCardListCardsA(hContext, pbAtr, rgquidInterfaces, cguidInterfaceCount, mszCards, pcchCards);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardListCardsW(uint hContext, uint8* pbAtr, Guid* rgquidInterfaces, uint32 cguidInterfaceCount, char16* mszCards, uint32* pcchCards);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardListInterfacesA(uint hContext, PSTR szCard, Guid* pguidInterfaces, uint32* pcguidInterfaces);
	public static int32 SCardListInterfaces(uint hContext, PSTR szCard, Guid* pguidInterfaces, uint32* pcguidInterfaces) => SCardListInterfacesA(hContext, szCard, pguidInterfaces, pcguidInterfaces);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardListInterfacesW(uint hContext, PWSTR szCard, Guid* pguidInterfaces, uint32* pcguidInterfaces);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetProviderIdA(uint hContext, PSTR szCard, Guid* pguidProviderId);
	public static int32 SCardGetProviderId(uint hContext, PSTR szCard, Guid* pguidProviderId) => SCardGetProviderIdA(hContext, szCard, pguidProviderId);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetProviderIdW(uint hContext, PWSTR szCard, Guid* pguidProviderId);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetCardTypeProviderNameA(uint hContext, PSTR szCardName, uint32 dwProviderId, uint8* szProvider, uint32* pcchProvider);
	public static int32 SCardGetCardTypeProviderName(uint hContext, PSTR szCardName, uint32 dwProviderId, uint8* szProvider, uint32* pcchProvider) => SCardGetCardTypeProviderNameA(hContext, szCardName, dwProviderId, szProvider, pcchProvider);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetCardTypeProviderNameW(uint hContext, PWSTR szCardName, uint32 dwProviderId, char16* szProvider, uint32* pcchProvider);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardIntroduceReaderGroupA(uint hContext, PSTR szGroupName);
	public static int32 SCardIntroduceReaderGroup(uint hContext, PSTR szGroupName) => SCardIntroduceReaderGroupA(hContext, szGroupName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardIntroduceReaderGroupW(uint hContext, PWSTR szGroupName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardForgetReaderGroupA(uint hContext, PSTR szGroupName);
	public static int32 SCardForgetReaderGroup(uint hContext, PSTR szGroupName) => SCardForgetReaderGroupA(hContext, szGroupName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardForgetReaderGroupW(uint hContext, PWSTR szGroupName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardIntroduceReaderA(uint hContext, PSTR szReaderName, PSTR szDeviceName);
	public static int32 SCardIntroduceReader(uint hContext, PSTR szReaderName, PSTR szDeviceName) => SCardIntroduceReaderA(hContext, szReaderName, szDeviceName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardIntroduceReaderW(uint hContext, PWSTR szReaderName, PWSTR szDeviceName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardForgetReaderA(uint hContext, PSTR szReaderName);
	public static int32 SCardForgetReader(uint hContext, PSTR szReaderName) => SCardForgetReaderA(hContext, szReaderName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardForgetReaderW(uint hContext, PWSTR szReaderName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardAddReaderToGroupA(uint hContext, PSTR szReaderName, PSTR szGroupName);
	public static int32 SCardAddReaderToGroup(uint hContext, PSTR szReaderName, PSTR szGroupName) => SCardAddReaderToGroupA(hContext, szReaderName, szGroupName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardAddReaderToGroupW(uint hContext, PWSTR szReaderName, PWSTR szGroupName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardRemoveReaderFromGroupA(uint hContext, PSTR szReaderName, PSTR szGroupName);
	public static int32 SCardRemoveReaderFromGroup(uint hContext, PSTR szReaderName, PSTR szGroupName) => SCardRemoveReaderFromGroupA(hContext, szReaderName, szGroupName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardRemoveReaderFromGroupW(uint hContext, PWSTR szReaderName, PWSTR szGroupName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardIntroduceCardTypeA(uint hContext, PSTR szCardName, Guid* pguidPrimaryProvider, Guid* rgguidInterfaces, uint32 dwInterfaceCount, uint8* pbAtr, uint8* pbAtrMask, uint32 cbAtrLen);
	public static int32 SCardIntroduceCardType(uint hContext, PSTR szCardName, Guid* pguidPrimaryProvider, Guid* rgguidInterfaces, uint32 dwInterfaceCount, uint8* pbAtr, uint8* pbAtrMask, uint32 cbAtrLen) => SCardIntroduceCardTypeA(hContext, szCardName, pguidPrimaryProvider, rgguidInterfaces, dwInterfaceCount, pbAtr, pbAtrMask, cbAtrLen);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardIntroduceCardTypeW(uint hContext, PWSTR szCardName, Guid* pguidPrimaryProvider, Guid* rgguidInterfaces, uint32 dwInterfaceCount, uint8* pbAtr, uint8* pbAtrMask, uint32 cbAtrLen);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardSetCardTypeProviderNameA(uint hContext, PSTR szCardName, uint32 dwProviderId, PSTR szProvider);
	public static int32 SCardSetCardTypeProviderName(uint hContext, PSTR szCardName, uint32 dwProviderId, PSTR szProvider) => SCardSetCardTypeProviderNameA(hContext, szCardName, dwProviderId, szProvider);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardSetCardTypeProviderNameW(uint hContext, PWSTR szCardName, uint32 dwProviderId, PWSTR szProvider);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardForgetCardTypeA(uint hContext, PSTR szCardName);
	public static int32 SCardForgetCardType(uint hContext, PSTR szCardName) => SCardForgetCardTypeA(hContext, szCardName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardForgetCardTypeW(uint hContext, PWSTR szCardName);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardFreeMemory(uint hContext, void* pvMem);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE SCardAccessStartedEvent();

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SCardReleaseStartedEvent();

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardLocateCardsA(uint hContext, PSTR mszCards, SCARD_READERSTATEA* rgReaderStates, uint32 cReaders);
	public static int32 SCardLocateCards(uint hContext, PSTR mszCards, SCARD_READERSTATEA* rgReaderStates, uint32 cReaders) => SCardLocateCardsA(hContext, mszCards, rgReaderStates, cReaders);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardLocateCardsW(uint hContext, PWSTR mszCards, SCARD_READERSTATEW* rgReaderStates, uint32 cReaders);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardLocateCardsByATRA(uint hContext, SCARD_ATRMASK* rgAtrMasks, uint32 cAtrs, SCARD_READERSTATEA* rgReaderStates, uint32 cReaders);
	public static int32 SCardLocateCardsByATR(uint hContext, SCARD_ATRMASK* rgAtrMasks, uint32 cAtrs, SCARD_READERSTATEA* rgReaderStates, uint32 cReaders) => SCardLocateCardsByATRA(hContext, rgAtrMasks, cAtrs, rgReaderStates, cReaders);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardLocateCardsByATRW(uint hContext, SCARD_ATRMASK* rgAtrMasks, uint32 cAtrs, SCARD_READERSTATEW* rgReaderStates, uint32 cReaders);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetStatusChangeA(uint hContext, uint32 dwTimeout, SCARD_READERSTATEA* rgReaderStates, uint32 cReaders);
	public static int32 SCardGetStatusChange(uint hContext, uint32 dwTimeout, SCARD_READERSTATEA* rgReaderStates, uint32 cReaders) => SCardGetStatusChangeA(hContext, dwTimeout, rgReaderStates, cReaders);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetStatusChangeW(uint hContext, uint32 dwTimeout, SCARD_READERSTATEW* rgReaderStates, uint32 cReaders);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardCancel(uint hContext);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardConnectA(uint hContext, PSTR szReader, uint32 dwShareMode, uint32 dwPreferredProtocols, uint* phCard, uint32* pdwActiveProtocol);
	public static int32 SCardConnect(uint hContext, PSTR szReader, uint32 dwShareMode, uint32 dwPreferredProtocols, uint* phCard, uint32* pdwActiveProtocol) => SCardConnectA(hContext, szReader, dwShareMode, dwPreferredProtocols, phCard, pdwActiveProtocol);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardConnectW(uint hContext, PWSTR szReader, uint32 dwShareMode, uint32 dwPreferredProtocols, uint* phCard, uint32* pdwActiveProtocol);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardReconnect(uint hCard, uint32 dwShareMode, uint32 dwPreferredProtocols, uint32 dwInitialization, uint32* pdwActiveProtocol);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardDisconnect(uint hCard, uint32 dwDisposition);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardBeginTransaction(uint hCard);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardEndTransaction(uint hCard, uint32 dwDisposition);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardState(uint hCard, uint32* pdwState, uint32* pdwProtocol, uint8* pbAtr, uint32* pcbAtrLen);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardStatusA(uint hCard, uint8* mszReaderNames, uint32* pcchReaderLen, uint32* pdwState, uint32* pdwProtocol, uint8* pbAtr, uint32* pcbAtrLen);
	public static int32 SCardStatus(uint hCard, uint8* mszReaderNames, uint32* pcchReaderLen, uint32* pdwState, uint32* pdwProtocol, uint8* pbAtr, uint32* pcbAtrLen) => SCardStatusA(hCard, mszReaderNames, pcchReaderLen, pdwState, pdwProtocol, pbAtr, pcbAtrLen);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardStatusW(uint hCard, char16* mszReaderNames, uint32* pcchReaderLen, uint32* pdwState, uint32* pdwProtocol, uint8* pbAtr, uint32* pcbAtrLen);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardTransmit(uint hCard, SCARD_IO_REQUEST* pioSendPci, uint8* pbSendBuffer, uint32 cbSendLength, SCARD_IO_REQUEST* pioRecvPci, uint8* pbRecvBuffer, uint32* pcbRecvLength);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetTransmitCount(uint hCard, uint32* pcTransmitCount);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardControl(uint hCard, uint32 dwControlCode, void* lpInBuffer, uint32 cbInBufferSize, void* lpOutBuffer, uint32 cbOutBufferSize, uint32* lpBytesReturned);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetAttrib(uint hCard, uint32 dwAttrId, uint8* pbAttr, uint32* pcbAttrLen);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardSetAttrib(uint hCard, uint32 dwAttrId, uint8* pbAttr, uint32 cbAttrLen);

	[Import("SCARDDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardUIDlgSelectCardA(OPENCARDNAME_EXA* param0);
	public static int32 SCardUIDlgSelectCard(OPENCARDNAME_EXA* param0) => SCardUIDlgSelectCardA(param0);

	[Import("SCARDDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardUIDlgSelectCardW(OPENCARDNAME_EXW* param0);

	[Import("SCARDDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetOpenCardNameA(OPENCARDNAMEA* param0);
	public static int32 GetOpenCardName(OPENCARDNAMEA* param0) => GetOpenCardNameA(param0);

	[Import("SCARDDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetOpenCardNameW(OPENCARDNAMEW* param0);

	[Import("SCARDDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardDlgExtendedError();

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardReadCacheA(uint hContext, Guid* CardIdentifier, uint32 FreshnessCounter, PSTR LookupName, uint8* Data, uint32* DataLen);
	public static int32 SCardReadCache(uint hContext, Guid* CardIdentifier, uint32 FreshnessCounter, PSTR LookupName, uint8* Data, uint32* DataLen) => SCardReadCacheA(hContext, CardIdentifier, FreshnessCounter, LookupName, Data, DataLen);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardReadCacheW(uint hContext, Guid* CardIdentifier, uint32 FreshnessCounter, PWSTR LookupName, uint8* Data, uint32* DataLen);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardWriteCacheA(uint hContext, Guid* CardIdentifier, uint32 FreshnessCounter, PSTR LookupName, uint8* Data, uint32 DataLen);
	public static int32 SCardWriteCache(uint hContext, Guid* CardIdentifier, uint32 FreshnessCounter, PSTR LookupName, uint8* Data, uint32 DataLen) => SCardWriteCacheA(hContext, CardIdentifier, FreshnessCounter, LookupName, Data, DataLen);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardWriteCacheW(uint hContext, Guid* CardIdentifier, uint32 FreshnessCounter, PWSTR LookupName, uint8* Data, uint32 DataLen);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetReaderIconA(uint hContext, PSTR szReaderName, uint8* pbIcon, uint32* pcbIcon);
	public static int32 SCardGetReaderIcon(uint hContext, PSTR szReaderName, uint8* pbIcon, uint32* pcbIcon) => SCardGetReaderIconA(hContext, szReaderName, pbIcon, pcbIcon);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetReaderIconW(uint hContext, PWSTR szReaderName, uint8* pbIcon, uint32* pcbIcon);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetDeviceTypeIdA(uint hContext, PSTR szReaderName, uint32* pdwDeviceTypeId);
	public static int32 SCardGetDeviceTypeId(uint hContext, PSTR szReaderName, uint32* pdwDeviceTypeId) => SCardGetDeviceTypeIdA(hContext, szReaderName, pdwDeviceTypeId);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetDeviceTypeIdW(uint hContext, PWSTR szReaderName, uint32* pdwDeviceTypeId);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetReaderDeviceInstanceIdA(uint hContext, PSTR szReaderName, uint8* szDeviceInstanceId, uint32* pcchDeviceInstanceId);
	public static int32 SCardGetReaderDeviceInstanceId(uint hContext, PSTR szReaderName, uint8* szDeviceInstanceId, uint32* pcchDeviceInstanceId) => SCardGetReaderDeviceInstanceIdA(hContext, szReaderName, szDeviceInstanceId, pcchDeviceInstanceId);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardGetReaderDeviceInstanceIdW(uint hContext, PWSTR szReaderName, char16* szDeviceInstanceId, uint32* pcchDeviceInstanceId);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardListReadersWithDeviceInstanceIdA(uint hContext, PSTR szDeviceInstanceId, uint8* mszReaders, uint32* pcchReaders);
	public static int32 SCardListReadersWithDeviceInstanceId(uint hContext, PSTR szDeviceInstanceId, uint8* mszReaders, uint32* pcchReaders) => SCardListReadersWithDeviceInstanceIdA(hContext, szDeviceInstanceId, mszReaders, pcchReaders);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardListReadersWithDeviceInstanceIdW(uint hContext, PWSTR szDeviceInstanceId, char16* mszReaders, uint32* pcchReaders);

	[Import("WinSCard.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SCardAudit(uint hContext, uint32 dwEvent);

}
#endregion
