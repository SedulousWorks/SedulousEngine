using Win32.Foundation;
using System;

namespace Win32.Security;

#region Constants
public static
{
	public const String wszCERTENROLLSHAREPATH = "CertSrv\\CertEnroll";
	public const uint32 cwcHRESULTSTRING = 40;
	public const String szLBRACE = "{";
	public const String szRBRACE = "}";
	public const String wszLBRACE = "{";
	public const String wszRBRACE = "}";
	public const String szLPAREN = "(";
	public const String szRPAREN = ")";
	public const String wszLPAREN = "(";
	public const String wszRPAREN = ")";
	public const uint32 CVT_SECONDS = 1;
	public const uint32 cwcFILENAMESUFFIXMAX = 20;
	public const String wszFCSAPARM_SERVERDNSNAME = "%1";
	public const String wszFCSAPARM_SERVERSHORTNAME = "%2";
	public const String wszFCSAPARM_SANITIZEDCANAME = "%3";
	public const String wszFCSAPARM_CERTFILENAMESUFFIX = "%4";
	public const String wszFCSAPARM_DOMAINDN = "%5";
	public const String wszFCSAPARM_CONFIGDN = "%6";
	public const String wszFCSAPARM_SANITIZEDCANAMEHASH = "%7";
	public const String wszFCSAPARM_CRLFILENAMESUFFIX = "%8";
	public const String wszFCSAPARM_CRLDELTAFILENAMESUFFIX = "%9";
	public const String wszFCSAPARM_DSCRLATTRIBUTE = "%10";
	public const String wszFCSAPARM_DSCACERTATTRIBUTE = "%11";
	public const String wszFCSAPARM_DSUSERCERTATTRIBUTE = "%12";
	public const String wszFCSAPARM_DSKRACERTATTRIBUTE = "%13";
	public const String wszFCSAPARM_DSCROSSCERTPAIRATTRIBUTE = "%14";
}
#endregion

#region TypeDefs
typealias HDIAGNOSTIC_DATA_QUERY_SESSION = int;

typealias HDIAGNOSTIC_REPORT = int;

typealias HDIAGNOSTIC_EVENT_TAG_DESCRIPTION = int;

typealias HDIAGNOSTIC_EVENT_PRODUCER_DESCRIPTION = int;

typealias HDIAGNOSTIC_EVENT_CATEGORY_DESCRIPTION = int;

typealias HDIAGNOSTIC_RECORD = int;

typealias NCRYPT_DESCRIPTOR_HANDLE = int;

typealias NCRYPT_STREAM_HANDLE = int;

typealias SAFER_LEVEL_HANDLE = int;

typealias SC_HANDLE = int;

typealias PSECURITY_DESCRIPTOR = void*;

#endregion


#region Enums

[AllowDuplicates]
public enum TOKEN_PRIVILEGES_ATTRIBUTES : uint32
{
	SE_PRIVILEGE_ENABLED = 2,
	SE_PRIVILEGE_ENABLED_BY_DEFAULT = 1,
	SE_PRIVILEGE_REMOVED = 4,
	SE_PRIVILEGE_USED_FOR_ACCESS = 2147483648,
}


[AllowDuplicates]
public enum LOGON32_PROVIDER : uint32
{
	LOGON32_PROVIDER_DEFAULT = 0,
	LOGON32_PROVIDER_WINNT50 = 3,
	LOGON32_PROVIDER_WINNT40 = 2,
}


[AllowDuplicates]
public enum CREATE_RESTRICTED_TOKEN_FLAGS : uint32
{
	DISABLE_MAX_PRIVILEGE = 1,
	SANDBOX_INERT = 2,
	LUA_TOKEN = 4,
	WRITE_RESTRICTED = 8,
}


[AllowDuplicates]
public enum LOGON32_LOGON : uint32
{
	LOGON32_LOGON_BATCH = 4,
	LOGON32_LOGON_INTERACTIVE = 2,
	LOGON32_LOGON_NETWORK = 3,
	LOGON32_LOGON_NETWORK_CLEARTEXT = 8,
	LOGON32_LOGON_NEW_CREDENTIALS = 9,
	LOGON32_LOGON_SERVICE = 5,
	LOGON32_LOGON_UNLOCK = 7,
}


[AllowDuplicates]
public enum ACE_FLAGS : uint32
{
	CONTAINER_INHERIT_ACE = 2,
	FAILED_ACCESS_ACE_FLAG = 128,
	INHERIT_ONLY_ACE = 8,
	INHERITED_ACE = 16,
	NO_PROPAGATE_INHERIT_ACE = 4,
	OBJECT_INHERIT_ACE = 1,
	SUCCESSFUL_ACCESS_ACE_FLAG = 64,
	SUB_CONTAINERS_AND_OBJECTS_INHERIT = 3,
	SUB_CONTAINERS_ONLY_INHERIT = 2,
	SUB_OBJECTS_ONLY_INHERIT = 1,
	INHERIT_NO_PROPAGATE = 4,
	INHERIT_ONLY = 8,
	NO_INHERITANCE = 0,
}


[AllowDuplicates]
public enum OBJECT_SECURITY_INFORMATION : uint32
{
	ATTRIBUTE_SECURITY_INFORMATION = 32,
	BACKUP_SECURITY_INFORMATION = 65536,
	DACL_SECURITY_INFORMATION = 4,
	GROUP_SECURITY_INFORMATION = 2,
	LABEL_SECURITY_INFORMATION = 16,
	OWNER_SECURITY_INFORMATION = 1,
	PROTECTED_DACL_SECURITY_INFORMATION = 2147483648,
	PROTECTED_SACL_SECURITY_INFORMATION = 1073741824,
	SACL_SECURITY_INFORMATION = 8,
	SCOPE_SECURITY_INFORMATION = 64,
	UNPROTECTED_DACL_SECURITY_INFORMATION = 536870912,
	UNPROTECTED_SACL_SECURITY_INFORMATION = 268435456,
}


[AllowDuplicates]
public enum SECURITY_AUTO_INHERIT_FLAGS : uint32
{
	SEF_AVOID_OWNER_CHECK = 16,
	SEF_AVOID_OWNER_RESTRICTION = 4096,
	SEF_AVOID_PRIVILEGE_CHECK = 8,
	SEF_DACL_AUTO_INHERIT = 1,
	SEF_DEFAULT_DESCRIPTOR_FOR_OBJECT = 4,
	SEF_DEFAULT_GROUP_FROM_PARENT = 64,
	SEF_DEFAULT_OWNER_FROM_PARENT = 32,
	SEF_MACL_NO_EXECUTE_UP = 1024,
	SEF_MACL_NO_READ_UP = 512,
	SEF_MACL_NO_WRITE_UP = 256,
	SEF_SACL_AUTO_INHERIT = 2,
}


[AllowDuplicates]
public enum ACE_REVISION : uint32
{
	ACL_REVISION = 2,
	ACL_REVISION_DS = 4,
}


[AllowDuplicates]
public enum TOKEN_MANDATORY_POLICY_ID : uint32
{
	TOKEN_MANDATORY_POLICY_OFF = 0,
	TOKEN_MANDATORY_POLICY_NO_WRITE_UP = 1,
	TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN = 2,
	TOKEN_MANDATORY_POLICY_VALID_MASK = 3,
}


[AllowDuplicates]
public enum SYSTEM_AUDIT_OBJECT_ACE_FLAGS : uint32
{
	ACE_OBJECT_TYPE_PRESENT = 1,
	ACE_INHERITED_OBJECT_TYPE_PRESENT = 2,
}


[AllowDuplicates]
public enum CLAIM_SECURITY_ATTRIBUTE_FLAGS : uint32
{
	CLAIM_SECURITY_ATTRIBUTE_NON_INHERITABLE = 1,
	CLAIM_SECURITY_ATTRIBUTE_VALUE_CASE_SENSITIVE = 2,
	CLAIM_SECURITY_ATTRIBUTE_USE_FOR_DENY_ONLY = 4,
	CLAIM_SECURITY_ATTRIBUTE_DISABLED_BY_DEFAULT = 8,
	CLAIM_SECURITY_ATTRIBUTE_DISABLED = 16,
	CLAIM_SECURITY_ATTRIBUTE_MANDATORY = 32,
}


[AllowDuplicates]
public enum CLAIM_SECURITY_ATTRIBUTE_VALUE_TYPE : uint16
{
	CLAIM_SECURITY_ATTRIBUTE_TYPE_INT64 = 1,
	CLAIM_SECURITY_ATTRIBUTE_TYPE_UINT64 = 2,
	CLAIM_SECURITY_ATTRIBUTE_TYPE_STRING = 3,
	CLAIM_SECURITY_ATTRIBUTE_TYPE_OCTET_STRING = 16,
	CLAIM_SECURITY_ATTRIBUTE_TYPE_FQBN = 4,
	CLAIM_SECURITY_ATTRIBUTE_TYPE_SID = 5,
	CLAIM_SECURITY_ATTRIBUTE_TYPE_BOOLEAN = 6,
}


[AllowDuplicates]
public enum TOKEN_ACCESS_MASK : uint32
{
	TOKEN_DELETE = 65536,
	TOKEN_READ_CONTROL = 131072,
	TOKEN_WRITE_DAC = 262144,
	TOKEN_WRITE_OWNER = 524288,
	TOKEN_ACCESS_SYSTEM_SECURITY = 16777216,
	TOKEN_ASSIGN_PRIMARY = 1,
	TOKEN_DUPLICATE = 2,
	TOKEN_IMPERSONATE = 4,
	TOKEN_QUERY = 8,
	TOKEN_QUERY_SOURCE = 16,
	TOKEN_ADJUST_PRIVILEGES = 32,
	TOKEN_ADJUST_GROUPS = 64,
	TOKEN_ADJUST_DEFAULT = 128,
	TOKEN_ADJUST_SESSIONID = 256,
	TOKEN_READ = 131080,
	TOKEN_WRITE = 131296,
	TOKEN_EXECUTE = 131072,
	TOKEN_TRUST_CONSTRAINT_MASK = 131096,
	TOKEN_ACCESS_PSEUDO_HANDLE_WIN8 = 24,
	TOKEN_ACCESS_PSEUDO_HANDLE = 24,
	TOKEN_ALL_ACCESS = 983295,
}


[AllowDuplicates]
public enum ENUM_PERIOD : int32
{
	ENUM_PERIOD_INVALID = -1,
	ENUM_PERIOD_SECONDS = 0,
	ENUM_PERIOD_MINUTES = 1,
	ENUM_PERIOD_HOURS = 2,
	ENUM_PERIOD_DAYS = 3,
	ENUM_PERIOD_WEEKS = 4,
	ENUM_PERIOD_MONTHS = 5,
	ENUM_PERIOD_YEARS = 6,
}


[AllowDuplicates]
public enum SID_NAME_USE : int32
{
	SidTypeUser = 1,
	SidTypeGroup = 2,
	SidTypeDomain = 3,
	SidTypeAlias = 4,
	SidTypeWellKnownGroup = 5,
	SidTypeDeletedAccount = 6,
	SidTypeInvalid = 7,
	SidTypeUnknown = 8,
	SidTypeComputer = 9,
	SidTypeLabel = 10,
	SidTypeLogonSession = 11,
}


[AllowDuplicates]
public enum WELL_KNOWN_SID_TYPE : int32
{
	WinNullSid = 0,
	WinWorldSid = 1,
	WinLocalSid = 2,
	WinCreatorOwnerSid = 3,
	WinCreatorGroupSid = 4,
	WinCreatorOwnerServerSid = 5,
	WinCreatorGroupServerSid = 6,
	WinNtAuthoritySid = 7,
	WinDialupSid = 8,
	WinNetworkSid = 9,
	WinBatchSid = 10,
	WinInteractiveSid = 11,
	WinServiceSid = 12,
	WinAnonymousSid = 13,
	WinProxySid = 14,
	WinEnterpriseControllersSid = 15,
	WinSelfSid = 16,
	WinAuthenticatedUserSid = 17,
	WinRestrictedCodeSid = 18,
	WinTerminalServerSid = 19,
	WinRemoteLogonIdSid = 20,
	WinLogonIdsSid = 21,
	WinLocalSystemSid = 22,
	WinLocalServiceSid = 23,
	WinNetworkServiceSid = 24,
	WinBuiltinDomainSid = 25,
	WinBuiltinAdministratorsSid = 26,
	WinBuiltinUsersSid = 27,
	WinBuiltinGuestsSid = 28,
	WinBuiltinPowerUsersSid = 29,
	WinBuiltinAccountOperatorsSid = 30,
	WinBuiltinSystemOperatorsSid = 31,
	WinBuiltinPrintOperatorsSid = 32,
	WinBuiltinBackupOperatorsSid = 33,
	WinBuiltinReplicatorSid = 34,
	WinBuiltinPreWindows2000CompatibleAccessSid = 35,
	WinBuiltinRemoteDesktopUsersSid = 36,
	WinBuiltinNetworkConfigurationOperatorsSid = 37,
	WinAccountAdministratorSid = 38,
	WinAccountGuestSid = 39,
	WinAccountKrbtgtSid = 40,
	WinAccountDomainAdminsSid = 41,
	WinAccountDomainUsersSid = 42,
	WinAccountDomainGuestsSid = 43,
	WinAccountComputersSid = 44,
	WinAccountControllersSid = 45,
	WinAccountCertAdminsSid = 46,
	WinAccountSchemaAdminsSid = 47,
	WinAccountEnterpriseAdminsSid = 48,
	WinAccountPolicyAdminsSid = 49,
	WinAccountRasAndIasServersSid = 50,
	WinNTLMAuthenticationSid = 51,
	WinDigestAuthenticationSid = 52,
	WinSChannelAuthenticationSid = 53,
	WinThisOrganizationSid = 54,
	WinOtherOrganizationSid = 55,
	WinBuiltinIncomingForestTrustBuildersSid = 56,
	WinBuiltinPerfMonitoringUsersSid = 57,
	WinBuiltinPerfLoggingUsersSid = 58,
	WinBuiltinAuthorizationAccessSid = 59,
	WinBuiltinTerminalServerLicenseServersSid = 60,
	WinBuiltinDCOMUsersSid = 61,
	WinBuiltinIUsersSid = 62,
	WinIUserSid = 63,
	WinBuiltinCryptoOperatorsSid = 64,
	WinUntrustedLabelSid = 65,
	WinLowLabelSid = 66,
	WinMediumLabelSid = 67,
	WinHighLabelSid = 68,
	WinSystemLabelSid = 69,
	WinWriteRestrictedCodeSid = 70,
	WinCreatorOwnerRightsSid = 71,
	WinCacheablePrincipalsGroupSid = 72,
	WinNonCacheablePrincipalsGroupSid = 73,
	WinEnterpriseReadonlyControllersSid = 74,
	WinAccountReadonlyControllersSid = 75,
	WinBuiltinEventLogReadersGroup = 76,
	WinNewEnterpriseReadonlyControllersSid = 77,
	WinBuiltinCertSvcDComAccessGroup = 78,
	WinMediumPlusLabelSid = 79,
	WinLocalLogonSid = 80,
	WinConsoleLogonSid = 81,
	WinThisOrganizationCertificateSid = 82,
	WinApplicationPackageAuthoritySid = 83,
	WinBuiltinAnyPackageSid = 84,
	WinCapabilityInternetClientSid = 85,
	WinCapabilityInternetClientServerSid = 86,
	WinCapabilityPrivateNetworkClientServerSid = 87,
	WinCapabilityPicturesLibrarySid = 88,
	WinCapabilityVideosLibrarySid = 89,
	WinCapabilityMusicLibrarySid = 90,
	WinCapabilityDocumentsLibrarySid = 91,
	WinCapabilitySharedUserCertificatesSid = 92,
	WinCapabilityEnterpriseAuthenticationSid = 93,
	WinCapabilityRemovableStorageSid = 94,
	WinBuiltinRDSRemoteAccessServersSid = 95,
	WinBuiltinRDSEndpointServersSid = 96,
	WinBuiltinRDSManagementServersSid = 97,
	WinUserModeDriversSid = 98,
	WinBuiltinHyperVAdminsSid = 99,
	WinAccountCloneableControllersSid = 100,
	WinBuiltinAccessControlAssistanceOperatorsSid = 101,
	WinBuiltinRemoteManagementUsersSid = 102,
	WinAuthenticationAuthorityAssertedSid = 103,
	WinAuthenticationServiceAssertedSid = 104,
	WinLocalAccountSid = 105,
	WinLocalAccountAndAdministratorSid = 106,
	WinAccountProtectedUsersSid = 107,
	WinCapabilityAppointmentsSid = 108,
	WinCapabilityContactsSid = 109,
	WinAccountDefaultSystemManagedSid = 110,
	WinBuiltinDefaultSystemManagedGroupSid = 111,
	WinBuiltinStorageReplicaAdminsSid = 112,
	WinAccountKeyAdminsSid = 113,
	WinAccountEnterpriseKeyAdminsSid = 114,
	WinAuthenticationKeyTrustSid = 115,
	WinAuthenticationKeyPropertyMFASid = 116,
	WinAuthenticationKeyPropertyAttestationSid = 117,
	WinAuthenticationFreshKeyAuthSid = 118,
	WinBuiltinDeviceOwnersSid = 119,
}


[AllowDuplicates]
public enum ACL_INFORMATION_CLASS : int32
{
	AclRevisionInformation = 1,
	AclSizeInformation = 2,
}


[AllowDuplicates]
public enum AUDIT_EVENT_TYPE : int32
{
	AuditEventObjectAccess = 0,
	AuditEventDirectoryServiceAccess = 1,
}


[AllowDuplicates]
public enum SECURITY_IMPERSONATION_LEVEL : int32
{
	SecurityAnonymous = 0,
	SecurityIdentification = 1,
	SecurityImpersonation = 2,
	SecurityDelegation = 3,
}


[AllowDuplicates]
public enum TOKEN_TYPE : int32
{
	TokenPrimary = 1,
	TokenImpersonation = 2,
}


[AllowDuplicates]
public enum TOKEN_ELEVATION_TYPE : int32
{
	TokenElevationTypeDefault = 1,
	TokenElevationTypeFull = 2,
	TokenElevationTypeLimited = 3,
}


[AllowDuplicates]
public enum TOKEN_INFORMATION_CLASS : int32
{
	TokenUser = 1,
	TokenGroups = 2,
	TokenPrivileges = 3,
	TokenOwner = 4,
	TokenPrimaryGroup = 5,
	TokenDefaultDacl = 6,
	TokenSource = 7,
	TokenType = 8,
	TokenImpersonationLevel = 9,
	TokenStatistics = 10,
	TokenRestrictedSids = 11,
	TokenSessionId = 12,
	TokenGroupsAndPrivileges = 13,
	TokenSessionReference = 14,
	TokenSandBoxInert = 15,
	TokenAuditPolicy = 16,
	TokenOrigin = 17,
	TokenElevationType = 18,
	TokenLinkedToken = 19,
	TokenElevation = 20,
	TokenHasRestrictions = 21,
	TokenAccessInformation = 22,
	TokenVirtualizationAllowed = 23,
	TokenVirtualizationEnabled = 24,
	TokenIntegrityLevel = 25,
	TokenUIAccess = 26,
	TokenMandatoryPolicy = 27,
	TokenLogonSid = 28,
	TokenIsAppContainer = 29,
	TokenCapabilities = 30,
	TokenAppContainerSid = 31,
	TokenAppContainerNumber = 32,
	TokenUserClaimAttributes = 33,
	TokenDeviceClaimAttributes = 34,
	TokenRestrictedUserClaimAttributes = 35,
	TokenRestrictedDeviceClaimAttributes = 36,
	TokenDeviceGroups = 37,
	TokenRestrictedDeviceGroups = 38,
	TokenSecurityAttributes = 39,
	TokenIsRestricted = 40,
	TokenProcessTrustLevel = 41,
	TokenPrivateNameSpace = 42,
	TokenSingletonAttributes = 43,
	TokenBnoIsolation = 44,
	TokenChildProcessFlags = 45,
	TokenIsLessPrivilegedAppContainer = 46,
	TokenIsSandboxed = 47,
	MaxTokenInfoClass = 48,
}


[AllowDuplicates]
public enum MANDATORY_LEVEL : int32
{
	MandatoryLevelUntrusted = 0,
	MandatoryLevelLow = 1,
	MandatoryLevelMedium = 2,
	MandatoryLevelHigh = 3,
	MandatoryLevelSystem = 4,
	MandatoryLevelSecureProcess = 5,
	MandatoryLevelCount = 6,
}

#endregion

#region Function Pointers
public function NTSTATUS PLSA_AP_CALL_PACKAGE_UNTRUSTED(void** ClientRequest, void* ProtocolSubmitBuffer, void* ClientBufferBase, uint32 SubmitBufferLength, void** ProtocolReturnBuffer, uint32* ReturnBufferLength, int32* ProtocolStatus);

public function uint32 SEC_THREAD_START(void* lpThreadParameter);

#endregion

#region Structs
[CRepr]
public struct SECURITY_ATTRIBUTES
{
	public uint32 nLength;
	public void* lpSecurityDescriptor;
	public BOOL bInheritHandle;
}

[CRepr]
public struct LLFILETIME
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public int64 ll;
		public FILETIME ft;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct GENERIC_MAPPING
{
	public uint32 GenericRead;
	public uint32 GenericWrite;
	public uint32 GenericExecute;
	public uint32 GenericAll;
}

[CRepr]
public struct LUID_AND_ATTRIBUTES
{
	public LUID Luid;
	public TOKEN_PRIVILEGES_ATTRIBUTES Attributes;
}

[CRepr]
public struct SID_IDENTIFIER_AUTHORITY
{
	public uint8[6] Value;
}

[CRepr]
public struct SID
{
	public uint8 Revision;
	public uint8 SubAuthorityCount;
	public SID_IDENTIFIER_AUTHORITY IdentifierAuthority;
	public uint32* SubAuthority mut => &SubAuthority_impl;
	private uint32[ANYSIZE_ARRAY] SubAuthority_impl;
}

[CRepr, Union]
public struct SE_SID
{
	public SID Sid;
	public uint8[68] Buffer;
}

[CRepr]
public struct SID_AND_ATTRIBUTES
{
	public PSID Sid;
	public uint32 Attributes;
}

[CRepr]
public struct SID_AND_ATTRIBUTES_HASH
{
	public uint32 SidCount;
	public SID_AND_ATTRIBUTES* SidAttr;
	public uint[32] Hash;
}

[CRepr]
public struct ACL
{
	public uint8 AclRevision;
	public uint8 Sbz1;
	public uint16 AclSize;
	public uint16 AceCount;
	public uint16 Sbz2;
}

[CRepr]
public struct ACE_HEADER
{
	public uint8 AceType;
	public uint8 AceFlags;
	public uint16 AceSize;
}

[CRepr]
public struct ACCESS_ALLOWED_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct ACCESS_DENIED_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_AUDIT_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_ALARM_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_RESOURCE_ATTRIBUTE_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_SCOPED_POLICY_ID_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_MANDATORY_LABEL_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_PROCESS_TRUST_LABEL_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_ACCESS_FILTER_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct ACCESS_ALLOWED_OBJECT_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public SYSTEM_AUDIT_OBJECT_ACE_FLAGS Flags;
	public Guid ObjectType;
	public Guid InheritedObjectType;
	public uint32 SidStart;
}

[CRepr]
public struct ACCESS_DENIED_OBJECT_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public SYSTEM_AUDIT_OBJECT_ACE_FLAGS Flags;
	public Guid ObjectType;
	public Guid InheritedObjectType;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_AUDIT_OBJECT_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public SYSTEM_AUDIT_OBJECT_ACE_FLAGS Flags;
	public Guid ObjectType;
	public Guid InheritedObjectType;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_ALARM_OBJECT_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 Flags;
	public Guid ObjectType;
	public Guid InheritedObjectType;
	public uint32 SidStart;
}

[CRepr]
public struct ACCESS_ALLOWED_CALLBACK_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct ACCESS_DENIED_CALLBACK_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_AUDIT_CALLBACK_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_ALARM_CALLBACK_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public uint32 SidStart;
}

[CRepr]
public struct ACCESS_ALLOWED_CALLBACK_OBJECT_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public SYSTEM_AUDIT_OBJECT_ACE_FLAGS Flags;
	public Guid ObjectType;
	public Guid InheritedObjectType;
	public uint32 SidStart;
}

[CRepr]
public struct ACCESS_DENIED_CALLBACK_OBJECT_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public SYSTEM_AUDIT_OBJECT_ACE_FLAGS Flags;
	public Guid ObjectType;
	public Guid InheritedObjectType;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_AUDIT_CALLBACK_OBJECT_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public SYSTEM_AUDIT_OBJECT_ACE_FLAGS Flags;
	public Guid ObjectType;
	public Guid InheritedObjectType;
	public uint32 SidStart;
}

[CRepr]
public struct SYSTEM_ALARM_CALLBACK_OBJECT_ACE
{
	public ACE_HEADER Header;
	public uint32 Mask;
	public SYSTEM_AUDIT_OBJECT_ACE_FLAGS Flags;
	public Guid ObjectType;
	public Guid InheritedObjectType;
	public uint32 SidStart;
}

[CRepr]
public struct ACL_REVISION_INFORMATION
{
	public uint32 AclRevision;
}

[CRepr]
public struct ACL_SIZE_INFORMATION
{
	public uint32 AceCount;
	public uint32 AclBytesInUse;
	public uint32 AclBytesFree;
}

[CRepr]
public struct SECURITY_DESCRIPTOR
{
	public uint8 Revision;
	public uint8 Sbz1;
	public uint16 Control;
	public PSID Owner;
	public PSID Group;
	public ACL* Sacl;
	public ACL* Dacl;
}

[CRepr]
public struct OBJECT_TYPE_LIST
{
	public uint16 Level;
	public uint16 Sbz;
	public Guid* ObjectType;
}

[CRepr]
public struct PRIVILEGE_SET
{
	public uint32 PrivilegeCount;
	public uint32 Control;
	public LUID_AND_ATTRIBUTES* Privilege mut => &Privilege_impl;
	private LUID_AND_ATTRIBUTES[ANYSIZE_ARRAY] Privilege_impl;
}

[CRepr]
public struct ACCESS_REASONS
{
	public uint32[32] Data;
}

[CRepr]
public struct SE_SECURITY_DESCRIPTOR
{
	public uint32 Size;
	public uint32 Flags;
	public PSECURITY_DESCRIPTOR SecurityDescriptor;
}

[CRepr]
public struct SE_ACCESS_REQUEST
{
	public uint32 Size;
	public SE_SECURITY_DESCRIPTOR* SeSecurityDescriptor;
	public uint32 DesiredAccess;
	public uint32 PreviouslyGrantedAccess;
	public PSID PrincipalSelfSid;
	public GENERIC_MAPPING* GenericMapping;
	public uint32 ObjectTypeListCount;
	public OBJECT_TYPE_LIST* ObjectTypeList;
}

[CRepr]
public struct SE_ACCESS_REPLY
{
	public uint32 Size;
	public uint32 ResultListCount;
	public uint32* GrantedAccess;
	public uint32* AccessStatus;
	public ACCESS_REASONS* AccessReason;
	public PRIVILEGE_SET** Privileges;
}

[CRepr]
public struct TOKEN_USER
{
	public SID_AND_ATTRIBUTES User;
}

[CRepr]
public struct TOKEN_GROUPS
{
	public uint32 GroupCount;
	public SID_AND_ATTRIBUTES* Groups mut => &Groups_impl;
	private SID_AND_ATTRIBUTES[ANYSIZE_ARRAY] Groups_impl;
}

[CRepr]
public struct TOKEN_PRIVILEGES
{
	public uint32 PrivilegeCount;
	public LUID_AND_ATTRIBUTES* Privileges mut => &Privileges_impl;
	private LUID_AND_ATTRIBUTES[ANYSIZE_ARRAY] Privileges_impl;
}

[CRepr]
public struct TOKEN_OWNER
{
	public PSID Owner;
}

[CRepr]
public struct TOKEN_PRIMARY_GROUP
{
	public PSID PrimaryGroup;
}

[CRepr]
public struct TOKEN_DEFAULT_DACL
{
	public ACL* DefaultDacl;
}

[CRepr]
public struct TOKEN_USER_CLAIMS
{
	public void* UserClaims;
}

[CRepr]
public struct TOKEN_DEVICE_CLAIMS
{
	public void* DeviceClaims;
}

[CRepr]
public struct TOKEN_GROUPS_AND_PRIVILEGES
{
	public uint32 SidCount;
	public uint32 SidLength;
	public SID_AND_ATTRIBUTES* Sids;
	public uint32 RestrictedSidCount;
	public uint32 RestrictedSidLength;
	public SID_AND_ATTRIBUTES* RestrictedSids;
	public uint32 PrivilegeCount;
	public uint32 PrivilegeLength;
	public LUID_AND_ATTRIBUTES* Privileges;
	public LUID AuthenticationId;
}

[CRepr]
public struct TOKEN_LINKED_TOKEN
{
	public HANDLE LinkedToken;
}

[CRepr]
public struct TOKEN_ELEVATION
{
	public uint32 TokenIsElevated;
}

[CRepr]
public struct TOKEN_MANDATORY_LABEL
{
	public SID_AND_ATTRIBUTES Label;
}

[CRepr]
public struct TOKEN_MANDATORY_POLICY
{
	public TOKEN_MANDATORY_POLICY_ID Policy;
}

[CRepr]
public struct TOKEN_ACCESS_INFORMATION
{
	public SID_AND_ATTRIBUTES_HASH* SidHash;
	public SID_AND_ATTRIBUTES_HASH* RestrictedSidHash;
	public TOKEN_PRIVILEGES* Privileges;
	public LUID AuthenticationId;
	public TOKEN_TYPE TokenType;
	public SECURITY_IMPERSONATION_LEVEL ImpersonationLevel;
	public TOKEN_MANDATORY_POLICY MandatoryPolicy;
	public uint32 Flags;
	public uint32 AppContainerNumber;
	public PSID PackageSid;
	public SID_AND_ATTRIBUTES_HASH* CapabilitiesHash;
	public PSID TrustLevelSid;
	public void* SecurityAttributes;
}

[CRepr]
public struct TOKEN_AUDIT_POLICY
{
	public uint8[30] PerUserPolicy;
}

[CRepr]
public struct TOKEN_SOURCE
{
	public CHAR[8] SourceName;
	public LUID SourceIdentifier;
}

[CRepr]
public struct TOKEN_STATISTICS
{
	public LUID TokenId;
	public LUID AuthenticationId;
	public LARGE_INTEGER ExpirationTime;
	public TOKEN_TYPE TokenType;
	public SECURITY_IMPERSONATION_LEVEL ImpersonationLevel;
	public uint32 DynamicCharged;
	public uint32 DynamicAvailable;
	public uint32 GroupCount;
	public uint32 PrivilegeCount;
	public LUID ModifiedId;
}

[CRepr]
public struct TOKEN_CONTROL
{
	public LUID TokenId;
	public LUID AuthenticationId;
	public LUID ModifiedId;
	public TOKEN_SOURCE TokenSource;
}

[CRepr]
public struct TOKEN_ORIGIN
{
	public LUID OriginatingLogonSession;
}

[CRepr]
public struct TOKEN_APPCONTAINER_INFORMATION
{
	public PSID TokenAppContainer;
}

[CRepr]
public struct CLAIM_SECURITY_ATTRIBUTE_FQBN_VALUE
{
	public uint64 Version;
	public PWSTR Name;
}

[CRepr]
public struct CLAIM_SECURITY_ATTRIBUTE_OCTET_STRING_VALUE
{
	public void* pValue;
	public uint32 ValueLength;
}

[CRepr]
public struct CLAIM_SECURITY_ATTRIBUTE_V1
{
	[CRepr, Union]
	public struct _Values_e__Union
	{
		public int64* pInt64;
		public uint64* pUint64;
		public PWSTR* ppString;
		public CLAIM_SECURITY_ATTRIBUTE_FQBN_VALUE* pFqbn;
		public CLAIM_SECURITY_ATTRIBUTE_OCTET_STRING_VALUE* pOctetString;
	}
	public PWSTR Name;
	public CLAIM_SECURITY_ATTRIBUTE_VALUE_TYPE ValueType;
	public uint16 Reserved;
	public uint32 Flags;
	public uint32 ValueCount;
	public _Values_e__Union Values;
}

[CRepr]
public struct CLAIM_SECURITY_ATTRIBUTE_RELATIVE_V1
{
	[CRepr, Union]
	public struct _Values_e__Union
	{
		public uint32* pInt64 mut => &pInt64_impl;
		private uint32[ANYSIZE_ARRAY] pInt64_impl;
		public uint32* pUint64 mut => &pUint64_impl;
		private uint32[ANYSIZE_ARRAY] pUint64_impl;
		public uint32* ppString mut => &ppString_impl;
		private uint32[ANYSIZE_ARRAY] ppString_impl;
		public uint32* pFqbn mut => &pFqbn_impl;
		private uint32[ANYSIZE_ARRAY] pFqbn_impl;
		public uint32* pOctetString mut => &pOctetString_impl;
		private uint32[ANYSIZE_ARRAY] pOctetString_impl;
	}
	public uint32 Name;
	public CLAIM_SECURITY_ATTRIBUTE_VALUE_TYPE ValueType;
	public uint16 Reserved;
	public CLAIM_SECURITY_ATTRIBUTE_FLAGS Flags;
	public uint32 ValueCount;
	public _Values_e__Union Values;
}

[CRepr]
public struct CLAIM_SECURITY_ATTRIBUTES_INFORMATION
{
	[CRepr, Union]
	public struct _Attribute_e__Union
	{
		public CLAIM_SECURITY_ATTRIBUTE_V1* pAttributeV1;
	}
	public uint16 Version;
	public uint16 Reserved;
	public uint32 AttributeCount;
	public _Attribute_e__Union Attribute;
}

[CRepr]
public struct SECURITY_QUALITY_OF_SERVICE
{
	public uint32 Length;
	public SECURITY_IMPERSONATION_LEVEL ImpersonationLevel;
	public uint8 ContextTrackingMode;
	public BOOLEAN EffectiveOnly;
}

[CRepr]
public struct SE_IMPERSONATION_STATE
{
	public void* Token;
	public BOOLEAN CopyOnOpen;
	public BOOLEAN EffectiveOnly;
	public SECURITY_IMPERSONATION_LEVEL Level;
}

[CRepr]
public struct SECURITY_CAPABILITIES
{
	public PSID AppContainerSid;
	public SID_AND_ATTRIBUTES* Capabilities;
	public uint32 CapabilityCount;
	public uint32 Reserved;
}

[CRepr]
public struct QUOTA_LIMITS
{
	public uint PagedPoolLimit;
	public uint NonPagedPoolLimit;
	public uint MinimumWorkingSetSize;
	public uint MaximumWorkingSetSize;
	public uint PagefileLimit;
	public LARGE_INTEGER TimeLimit;
}

#endregion

#region Functions
public static
{
	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheck(PSECURITY_DESCRIPTOR pSecurityDescriptor, HANDLE ClientToken, uint32 DesiredAccess, GENERIC_MAPPING* GenericMapping, PRIVILEGE_SET* PrivilegeSet, uint32* PrivilegeSetLength, uint32* GrantedAccess, int32* AccessStatus);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheckAndAuditAlarmW(PWSTR SubsystemName, void* HandleId, PWSTR ObjectTypeName, PWSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, uint32 DesiredAccess, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccess, int32* AccessStatus, int32* pfGenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheckByType(PSECURITY_DESCRIPTOR pSecurityDescriptor, PSID PrincipalSelfSid, HANDLE ClientToken, uint32 DesiredAccess, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, PRIVILEGE_SET* PrivilegeSet, uint32* PrivilegeSetLength, uint32* GrantedAccess, int32* AccessStatus);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheckByTypeResultList(PSECURITY_DESCRIPTOR pSecurityDescriptor, PSID PrincipalSelfSid, HANDLE ClientToken, uint32 DesiredAccess, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, PRIVILEGE_SET* PrivilegeSet, uint32* PrivilegeSetLength, uint32* GrantedAccessList, uint32* AccessStatusList);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheckByTypeAndAuditAlarmW(PWSTR SubsystemName, void* HandleId, PWSTR ObjectTypeName, PWSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid, uint32 DesiredAccess, AUDIT_EVENT_TYPE AuditType, uint32 Flags, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccess, int32* AccessStatus, int32* pfGenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheckByTypeResultListAndAuditAlarmW(PWSTR SubsystemName, void* HandleId, PWSTR ObjectTypeName, PWSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid, uint32 DesiredAccess, AUDIT_EVENT_TYPE AuditType, uint32 Flags, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccessList, uint32* AccessStatusList, int32* pfGenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheckByTypeResultListAndAuditAlarmByHandleW(PWSTR SubsystemName, void* HandleId, HANDLE ClientToken, PWSTR ObjectTypeName, PWSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid, uint32 DesiredAccess, AUDIT_EVENT_TYPE AuditType, uint32 Flags, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccessList, uint32* AccessStatusList, int32* pfGenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddAccessAllowedAce(ACL* pAcl, uint32 dwAceRevision, uint32 AccessMask, PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddAccessAllowedAceEx(ACL* pAcl, uint32 dwAceRevision, ACE_FLAGS AceFlags, uint32 AccessMask, PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddAccessAllowedObjectAce(ACL* pAcl, uint32 dwAceRevision, ACE_FLAGS AceFlags, uint32 AccessMask, Guid* ObjectTypeGuid, Guid* InheritedObjectTypeGuid, PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddAccessDeniedAce(ACL* pAcl, uint32 dwAceRevision, uint32 AccessMask, PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddAccessDeniedAceEx(ACL* pAcl, uint32 dwAceRevision, ACE_FLAGS AceFlags, uint32 AccessMask, PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddAccessDeniedObjectAce(ACL* pAcl, uint32 dwAceRevision, ACE_FLAGS AceFlags, uint32 AccessMask, Guid* ObjectTypeGuid, Guid* InheritedObjectTypeGuid, PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddAce(ACL* pAcl, uint32 dwAceRevision, uint32 dwStartingAceIndex, void* pAceList, uint32 nAceListLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddAuditAccessAce(ACL* pAcl, uint32 dwAceRevision, uint32 dwAccessMask, PSID pSid, BOOL bAuditSuccess, BOOL bAuditFailure);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddAuditAccessAceEx(ACL* pAcl, uint32 dwAceRevision, ACE_FLAGS AceFlags, uint32 dwAccessMask, PSID pSid, BOOL bAuditSuccess, BOOL bAuditFailure);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddAuditAccessObjectAce(ACL* pAcl, uint32 dwAceRevision, ACE_FLAGS AceFlags, uint32 AccessMask, Guid* ObjectTypeGuid, Guid* InheritedObjectTypeGuid, PSID pSid, BOOL bAuditSuccess, BOOL bAuditFailure);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddMandatoryAce(ACL* pAcl, ACE_REVISION dwAceRevision, ACE_FLAGS AceFlags, uint32 MandatoryPolicy, PSID pLabelSid);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddResourceAttributeAce(ACL* pAcl, uint32 dwAceRevision, ACE_FLAGS AceFlags, uint32 AccessMask, PSID pSid, CLAIM_SECURITY_ATTRIBUTES_INFORMATION* pAttributeInfo, uint32* pReturnLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddScopedPolicyIDAce(ACL* pAcl, uint32 dwAceRevision, ACE_FLAGS AceFlags, uint32 AccessMask, PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AdjustTokenGroups(HANDLE TokenHandle, BOOL ResetToDefault, TOKEN_GROUPS* NewState, uint32 BufferLength, TOKEN_GROUPS* PreviousState, uint32* ReturnLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AdjustTokenPrivileges(HANDLE TokenHandle, BOOL DisableAllPrivileges, TOKEN_PRIVILEGES* NewState, uint32 BufferLength, TOKEN_PRIVILEGES* PreviousState, uint32* ReturnLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllocateAndInitializeSid(SID_IDENTIFIER_AUTHORITY* pIdentifierAuthority, uint8 nSubAuthorityCount, uint32 nSubAuthority0, uint32 nSubAuthority1, uint32 nSubAuthority2, uint32 nSubAuthority3, uint32 nSubAuthority4, uint32 nSubAuthority5, uint32 nSubAuthority6, uint32 nSubAuthority7, PSID* pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllocateLocallyUniqueId(LUID* Luid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AreAllAccessesGranted(uint32 GrantedAccess, uint32 DesiredAccess);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AreAnyAccessesGranted(uint32 GrantedAccess, uint32 DesiredAccess);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CheckTokenMembership(HANDLE TokenHandle, PSID SidToCheck, BOOL* IsMember);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CheckTokenCapability(HANDLE TokenHandle, PSID CapabilitySidToCheck, BOOL* HasCapability);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetAppContainerAce(ACL* Acl, uint32 StartingAceIndex, void** AppContainerAce, uint32* AppContainerAceIndex);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CheckTokenMembershipEx(HANDLE TokenHandle, PSID SidToCheck, uint32 Flags, BOOL* IsMember);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertToAutoInheritPrivateObjectSecurity(PSECURITY_DESCRIPTOR ParentDescriptor, PSECURITY_DESCRIPTOR CurrentSecurityDescriptor, PSECURITY_DESCRIPTOR* NewSecurityDescriptor, Guid* ObjectType, BOOLEAN IsDirectoryObject, GENERIC_MAPPING* GenericMapping);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CopySid(uint32 nDestinationSidLength, PSID pDestinationSid, PSID pSourceSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreatePrivateObjectSecurity(PSECURITY_DESCRIPTOR ParentDescriptor, PSECURITY_DESCRIPTOR CreatorDescriptor, PSECURITY_DESCRIPTOR* NewDescriptor, BOOL IsDirectoryObject, HANDLE Token, GENERIC_MAPPING* GenericMapping);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreatePrivateObjectSecurityEx(PSECURITY_DESCRIPTOR ParentDescriptor, PSECURITY_DESCRIPTOR CreatorDescriptor, PSECURITY_DESCRIPTOR* NewDescriptor, Guid* ObjectType, BOOL IsContainerObject, SECURITY_AUTO_INHERIT_FLAGS AutoInheritFlags, HANDLE Token, GENERIC_MAPPING* GenericMapping);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreatePrivateObjectSecurityWithMultipleInheritance(PSECURITY_DESCRIPTOR ParentDescriptor, PSECURITY_DESCRIPTOR CreatorDescriptor, PSECURITY_DESCRIPTOR* NewDescriptor, Guid** ObjectTypes, uint32 GuidCount, BOOL IsContainerObject, SECURITY_AUTO_INHERIT_FLAGS AutoInheritFlags, HANDLE Token, GENERIC_MAPPING* GenericMapping);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateRestrictedToken(HANDLE ExistingTokenHandle, CREATE_RESTRICTED_TOKEN_FLAGS Flags, uint32 DisableSidCount, SID_AND_ATTRIBUTES* SidsToDisable, uint32 DeletePrivilegeCount, LUID_AND_ATTRIBUTES* PrivilegesToDelete, uint32 RestrictedSidCount, SID_AND_ATTRIBUTES* SidsToRestrict, HANDLE* NewTokenHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateWellKnownSid(WELL_KNOWN_SID_TYPE WellKnownSidType, PSID DomainSid, PSID pSid, uint32* cbSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EqualDomainSid(PSID pSid1, PSID pSid2, BOOL* pfEqual);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteAce(ACL* pAcl, uint32 dwAceIndex);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DestroyPrivateObjectSecurity(PSECURITY_DESCRIPTOR* ObjectDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DuplicateToken(HANDLE ExistingTokenHandle, SECURITY_IMPERSONATION_LEVEL ImpersonationLevel, HANDLE* DuplicateTokenHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DuplicateTokenEx(HANDLE hExistingToken, TOKEN_ACCESS_MASK dwDesiredAccess, SECURITY_ATTRIBUTES* lpTokenAttributes, SECURITY_IMPERSONATION_LEVEL ImpersonationLevel, TOKEN_TYPE TokenType, HANDLE* phNewToken);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EqualPrefixSid(PSID pSid1, PSID pSid2);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EqualSid(PSID pSid1, PSID pSid2);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FindFirstFreeAce(ACL* pAcl, void** pAce);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* FreeSid(PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetAce(ACL* pAcl, uint32 dwAceIndex, void** pAce);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetAclInformation(ACL* pAcl, void* pAclInformation, uint32 nAclInformationLength, ACL_INFORMATION_CLASS dwAclInformationClass);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileSecurityW(PWSTR lpFileName, uint32 RequestedInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32 nLength, uint32* lpnLengthNeeded);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetKernelObjectSecurity(HANDLE Handle, uint32 RequestedInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32 nLength, uint32* lpnLengthNeeded);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetLengthSid(PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPrivateObjectSecurity(PSECURITY_DESCRIPTOR ObjectDescriptor, uint32 SecurityInformation, PSECURITY_DESCRIPTOR ResultantDescriptor, uint32 DescriptorLength, uint32* ReturnLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSecurityDescriptorControl(PSECURITY_DESCRIPTOR pSecurityDescriptor, uint16* pControl, uint32* lpdwRevision);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSecurityDescriptorDacl(PSECURITY_DESCRIPTOR pSecurityDescriptor, int32* lpbDaclPresent, ACL** pDacl, int32* lpbDaclDefaulted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSecurityDescriptorGroup(PSECURITY_DESCRIPTOR pSecurityDescriptor, PSID* pGroup, int32* lpbGroupDefaulted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSecurityDescriptorLength(PSECURITY_DESCRIPTOR pSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSecurityDescriptorOwner(PSECURITY_DESCRIPTOR pSecurityDescriptor, PSID* pOwner, int32* lpbOwnerDefaulted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSecurityDescriptorRMControl(PSECURITY_DESCRIPTOR SecurityDescriptor, uint8* RMControl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSecurityDescriptorSacl(PSECURITY_DESCRIPTOR pSecurityDescriptor, int32* lpbSaclPresent, ACL** pSacl, int32* lpbSaclDefaulted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SID_IDENTIFIER_AUTHORITY* GetSidIdentifierAuthority(PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSidLengthRequired(uint8 nSubAuthorityCount);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32* GetSidSubAuthority(PSID pSid, uint32 nSubAuthority);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* GetSidSubAuthorityCount(PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetTokenInformation(HANDLE TokenHandle, TOKEN_INFORMATION_CLASS TokenInformationClass, void* TokenInformation, uint32 TokenInformationLength, uint32* ReturnLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetWindowsAccountDomainSid(PSID pSid, PSID pDomainSid, uint32* cbDomainSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImpersonateAnonymousToken(HANDLE ThreadHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImpersonateLoggedOnUser(HANDLE hToken);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImpersonateSelf(SECURITY_IMPERSONATION_LEVEL ImpersonationLevel);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitializeAcl(ACL* pAcl, uint32 nAclLength, uint32 dwAclRevision);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitializeSecurityDescriptor(PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32 dwRevision);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitializeSid(PSID Sid, SID_IDENTIFIER_AUTHORITY* pIdentifierAuthority, uint8 nSubAuthorityCount);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsTokenRestricted(HANDLE TokenHandle);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsValidAcl(ACL* pAcl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsValidSecurityDescriptor(PSECURITY_DESCRIPTOR pSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsValidSid(PSID pSid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsWellKnownSid(PSID pSid, WELL_KNOWN_SID_TYPE WellKnownSidType);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MakeAbsoluteSD(PSECURITY_DESCRIPTOR pSelfRelativeSecurityDescriptor, PSECURITY_DESCRIPTOR pAbsoluteSecurityDescriptor, uint32* lpdwAbsoluteSecurityDescriptorSize, ACL* pDacl, uint32* lpdwDaclSize, ACL* pSacl, uint32* lpdwSaclSize, PSID pOwner, uint32* lpdwOwnerSize, PSID pPrimaryGroup, uint32* lpdwPrimaryGroupSize);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MakeSelfRelativeSD(PSECURITY_DESCRIPTOR pAbsoluteSecurityDescriptor, PSECURITY_DESCRIPTOR pSelfRelativeSecurityDescriptor, uint32* lpdwBufferLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void MapGenericMask(uint32* AccessMask, GENERIC_MAPPING* GenericMapping);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ObjectCloseAuditAlarmW(PWSTR SubsystemName, void* HandleId, BOOL GenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ObjectDeleteAuditAlarmW(PWSTR SubsystemName, void* HandleId, BOOL GenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ObjectOpenAuditAlarmW(PWSTR SubsystemName, void* HandleId, PWSTR ObjectTypeName, PWSTR ObjectName, PSECURITY_DESCRIPTOR pSecurityDescriptor, HANDLE ClientToken, uint32 DesiredAccess, uint32 GrantedAccess, PRIVILEGE_SET* Privileges, BOOL ObjectCreation, BOOL AccessGranted, int32* GenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ObjectPrivilegeAuditAlarmW(PWSTR SubsystemName, void* HandleId, HANDLE ClientToken, uint32 DesiredAccess, PRIVILEGE_SET* Privileges, BOOL AccessGranted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrivilegeCheck(HANDLE ClientToken, PRIVILEGE_SET* RequiredPrivileges, int32* pfResult);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrivilegedServiceAuditAlarmW(PWSTR SubsystemName, PWSTR ServiceName, HANDLE ClientToken, PRIVILEGE_SET* Privileges, BOOL AccessGranted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void QuerySecurityAccessMask(uint32 SecurityInformation, uint32* DesiredAccess);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RevertToSelf();

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetAclInformation(ACL* pAcl, void* pAclInformation, uint32 nAclInformationLength, ACL_INFORMATION_CLASS dwAclInformationClass);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileSecurityW(PWSTR lpFileName, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetKernelObjectSecurity(HANDLE Handle, uint32 SecurityInformation, PSECURITY_DESCRIPTOR SecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetPrivateObjectSecurity(uint32 SecurityInformation, PSECURITY_DESCRIPTOR ModificationDescriptor, PSECURITY_DESCRIPTOR* ObjectsSecurityDescriptor, GENERIC_MAPPING* GenericMapping, HANDLE Token);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetPrivateObjectSecurityEx(uint32 SecurityInformation, PSECURITY_DESCRIPTOR ModificationDescriptor, PSECURITY_DESCRIPTOR* ObjectsSecurityDescriptor, SECURITY_AUTO_INHERIT_FLAGS AutoInheritFlags, GENERIC_MAPPING* GenericMapping, HANDLE Token);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetSecurityAccessMask(uint32 SecurityInformation, uint32* DesiredAccess);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSecurityDescriptorControl(PSECURITY_DESCRIPTOR pSecurityDescriptor, uint16 ControlBitsOfInterest, uint16 ControlBitsToSet);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSecurityDescriptorDacl(PSECURITY_DESCRIPTOR pSecurityDescriptor, BOOL bDaclPresent, ACL* pDacl, BOOL bDaclDefaulted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSecurityDescriptorGroup(PSECURITY_DESCRIPTOR pSecurityDescriptor, PSID pGroup, BOOL bGroupDefaulted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSecurityDescriptorOwner(PSECURITY_DESCRIPTOR pSecurityDescriptor, PSID pOwner, BOOL bOwnerDefaulted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetSecurityDescriptorRMControl(PSECURITY_DESCRIPTOR SecurityDescriptor, uint8* RMControl);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetSecurityDescriptorSacl(PSECURITY_DESCRIPTOR pSecurityDescriptor, BOOL bSaclPresent, ACL* pSacl, BOOL bSaclDefaulted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetTokenInformation(HANDLE TokenHandle, TOKEN_INFORMATION_CLASS TokenInformationClass, void* TokenInformation, uint32 TokenInformationLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCachedSigningLevel(HANDLE* SourceFiles, uint32 SourceFileCount, uint32 Flags, HANDLE TargetFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCachedSigningLevel(HANDLE File, uint32* Flags, uint32* SigningLevel, uint8* Thumbprint, uint32* ThumbprintSize, uint32* ThumbprintAlgorithm);

	[Import("api-ms-win-security-base-l1-2-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeriveCapabilitySidsFromName(PWSTR CapName, PSID** CapabilityGroupSids, uint32* CapabilityGroupSidCount, PSID** CapabilitySids, uint32* CapabilitySidCount);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOLEAN RtlNormalizeSecurityDescriptor(PSECURITY_DESCRIPTOR* SecurityDescriptor, uint32 SecurityDescriptorLength, PSECURITY_DESCRIPTOR* NewSecurityDescriptor, uint32* NewSecurityDescriptorLength, BOOLEAN CheckOnly);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetUserObjectSecurity(HANDLE hObj, OBJECT_SECURITY_INFORMATION* pSIRequested, PSECURITY_DESCRIPTOR pSID);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUserObjectSecurity(HANDLE hObj, uint32* pSIRequested, PSECURITY_DESCRIPTOR pSID, uint32 nLength, uint32* lpnLengthNeeded);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheckAndAuditAlarmA(PSTR SubsystemName, void* HandleId, PSTR ObjectTypeName, PSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, uint32 DesiredAccess, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccess, int32* AccessStatus, int32* pfGenerateOnClose);
	public static BOOL AccessCheckAndAuditAlarm(PSTR SubsystemName, void* HandleId, PSTR ObjectTypeName, PSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, uint32 DesiredAccess, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccess, int32* AccessStatus, int32* pfGenerateOnClose) => AccessCheckAndAuditAlarmA(SubsystemName, HandleId, ObjectTypeName, ObjectName, SecurityDescriptor, DesiredAccess, GenericMapping, ObjectCreation, GrantedAccess, AccessStatus, pfGenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheckByTypeAndAuditAlarmA(PSTR SubsystemName, void* HandleId, PSTR ObjectTypeName, PSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid, uint32 DesiredAccess, AUDIT_EVENT_TYPE AuditType, uint32 Flags, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccess, int32* AccessStatus, int32* pfGenerateOnClose);
	public static BOOL AccessCheckByTypeAndAuditAlarm(PSTR SubsystemName, void* HandleId, PSTR ObjectTypeName, PSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid, uint32 DesiredAccess, AUDIT_EVENT_TYPE AuditType, uint32 Flags, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccess, int32* AccessStatus, int32* pfGenerateOnClose) => AccessCheckByTypeAndAuditAlarmA(SubsystemName, HandleId, ObjectTypeName, ObjectName, SecurityDescriptor, PrincipalSelfSid, DesiredAccess, AuditType, Flags, ObjectTypeList, ObjectTypeListLength, GenericMapping, ObjectCreation, GrantedAccess, AccessStatus, pfGenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheckByTypeResultListAndAuditAlarmA(PSTR SubsystemName, void* HandleId, PSTR ObjectTypeName, PSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid, uint32 DesiredAccess, AUDIT_EVENT_TYPE AuditType, uint32 Flags, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccess, uint32* AccessStatusList, int32* pfGenerateOnClose);
	public static BOOL AccessCheckByTypeResultListAndAuditAlarm(PSTR SubsystemName, void* HandleId, PSTR ObjectTypeName, PSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid, uint32 DesiredAccess, AUDIT_EVENT_TYPE AuditType, uint32 Flags, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccess, uint32* AccessStatusList, int32* pfGenerateOnClose) => AccessCheckByTypeResultListAndAuditAlarmA(SubsystemName, HandleId, ObjectTypeName, ObjectName, SecurityDescriptor, PrincipalSelfSid, DesiredAccess, AuditType, Flags, ObjectTypeList, ObjectTypeListLength, GenericMapping, ObjectCreation, GrantedAccess, AccessStatusList, pfGenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AccessCheckByTypeResultListAndAuditAlarmByHandleA(PSTR SubsystemName, void* HandleId, HANDLE ClientToken, PSTR ObjectTypeName, PSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid, uint32 DesiredAccess, AUDIT_EVENT_TYPE AuditType, uint32 Flags, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccess, uint32* AccessStatusList, int32* pfGenerateOnClose);
	public static BOOL AccessCheckByTypeResultListAndAuditAlarmByHandle(PSTR SubsystemName, void* HandleId, HANDLE ClientToken, PSTR ObjectTypeName, PSTR ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid, uint32 DesiredAccess, AUDIT_EVENT_TYPE AuditType, uint32 Flags, OBJECT_TYPE_LIST* ObjectTypeList, uint32 ObjectTypeListLength, GENERIC_MAPPING* GenericMapping, BOOL ObjectCreation, uint32* GrantedAccess, uint32* AccessStatusList, int32* pfGenerateOnClose) => AccessCheckByTypeResultListAndAuditAlarmByHandleA(SubsystemName, HandleId, ClientToken, ObjectTypeName, ObjectName, SecurityDescriptor, PrincipalSelfSid, DesiredAccess, AuditType, Flags, ObjectTypeList, ObjectTypeListLength, GenericMapping, ObjectCreation, GrantedAccess, AccessStatusList, pfGenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ObjectOpenAuditAlarmA(PSTR SubsystemName, void* HandleId, PSTR ObjectTypeName, PSTR ObjectName, PSECURITY_DESCRIPTOR pSecurityDescriptor, HANDLE ClientToken, uint32 DesiredAccess, uint32 GrantedAccess, PRIVILEGE_SET* Privileges, BOOL ObjectCreation, BOOL AccessGranted, int32* GenerateOnClose);
	public static BOOL ObjectOpenAuditAlarm(PSTR SubsystemName, void* HandleId, PSTR ObjectTypeName, PSTR ObjectName, PSECURITY_DESCRIPTOR pSecurityDescriptor, HANDLE ClientToken, uint32 DesiredAccess, uint32 GrantedAccess, PRIVILEGE_SET* Privileges, BOOL ObjectCreation, BOOL AccessGranted, int32* GenerateOnClose) => ObjectOpenAuditAlarmA(SubsystemName, HandleId, ObjectTypeName, ObjectName, pSecurityDescriptor, ClientToken, DesiredAccess, GrantedAccess, Privileges, ObjectCreation, AccessGranted, GenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ObjectPrivilegeAuditAlarmA(PSTR SubsystemName, void* HandleId, HANDLE ClientToken, uint32 DesiredAccess, PRIVILEGE_SET* Privileges, BOOL AccessGranted);
	public static BOOL ObjectPrivilegeAuditAlarm(PSTR SubsystemName, void* HandleId, HANDLE ClientToken, uint32 DesiredAccess, PRIVILEGE_SET* Privileges, BOOL AccessGranted) => ObjectPrivilegeAuditAlarmA(SubsystemName, HandleId, ClientToken, DesiredAccess, Privileges, AccessGranted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ObjectCloseAuditAlarmA(PSTR SubsystemName, void* HandleId, BOOL GenerateOnClose);
	public static BOOL ObjectCloseAuditAlarm(PSTR SubsystemName, void* HandleId, BOOL GenerateOnClose) => ObjectCloseAuditAlarmA(SubsystemName, HandleId, GenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ObjectDeleteAuditAlarmA(PSTR SubsystemName, void* HandleId, BOOL GenerateOnClose);
	public static BOOL ObjectDeleteAuditAlarm(PSTR SubsystemName, void* HandleId, BOOL GenerateOnClose) => ObjectDeleteAuditAlarmA(SubsystemName, HandleId, GenerateOnClose);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrivilegedServiceAuditAlarmA(PSTR SubsystemName, PSTR ServiceName, HANDLE ClientToken, PRIVILEGE_SET* Privileges, BOOL AccessGranted);
	public static BOOL PrivilegedServiceAuditAlarm(PSTR SubsystemName, PSTR ServiceName, HANDLE ClientToken, PRIVILEGE_SET* Privileges, BOOL AccessGranted) => PrivilegedServiceAuditAlarmA(SubsystemName, ServiceName, ClientToken, Privileges, AccessGranted);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddConditionalAce(ACL* pAcl, uint32 dwAceRevision, ACE_FLAGS AceFlags, uint8 AceType, uint32 AccessMask, PSID pSid, PWSTR ConditionStr, uint32* ReturnLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetFileSecurityA(PSTR lpFileName, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor);
	public static BOOL SetFileSecurity(PSTR lpFileName, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor) => SetFileSecurityA(lpFileName, SecurityInformation, pSecurityDescriptor);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileSecurityA(PSTR lpFileName, uint32 RequestedInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32 nLength, uint32* lpnLengthNeeded);
	public static BOOL GetFileSecurity(PSTR lpFileName, uint32 RequestedInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32 nLength, uint32* lpnLengthNeeded) => GetFileSecurityA(lpFileName, RequestedInformation, pSecurityDescriptor, nLength, lpnLengthNeeded);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LookupAccountSidA(PSTR lpSystemName, PSID Sid, uint8* Name, uint32* cchName, uint8* ReferencedDomainName, uint32* cchReferencedDomainName, SID_NAME_USE* peUse);
	public static BOOL LookupAccountSid(PSTR lpSystemName, PSID Sid, uint8* Name, uint32* cchName, uint8* ReferencedDomainName, uint32* cchReferencedDomainName, SID_NAME_USE* peUse) => LookupAccountSidA(lpSystemName, Sid, Name, cchName, ReferencedDomainName, cchReferencedDomainName, peUse);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LookupAccountSidW(PWSTR lpSystemName, PSID Sid, char16* Name, uint32* cchName, char16* ReferencedDomainName, uint32* cchReferencedDomainName, SID_NAME_USE* peUse);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LookupAccountNameA(PSTR lpSystemName, PSTR lpAccountName, PSID Sid, uint32* cbSid, uint8* ReferencedDomainName, uint32* cchReferencedDomainName, SID_NAME_USE* peUse);
	public static BOOL LookupAccountName(PSTR lpSystemName, PSTR lpAccountName, PSID Sid, uint32* cbSid, uint8* ReferencedDomainName, uint32* cchReferencedDomainName, SID_NAME_USE* peUse) => LookupAccountNameA(lpSystemName, lpAccountName, Sid, cbSid, ReferencedDomainName, cchReferencedDomainName, peUse);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LookupAccountNameW(PWSTR lpSystemName, PWSTR lpAccountName, PSID Sid, uint32* cbSid, char16* ReferencedDomainName, uint32* cchReferencedDomainName, SID_NAME_USE* peUse);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LookupPrivilegeValueA(PSTR lpSystemName, PSTR lpName, LUID* lpLuid);
	public static BOOL LookupPrivilegeValue(PSTR lpSystemName, PSTR lpName, LUID* lpLuid) => LookupPrivilegeValueA(lpSystemName, lpName, lpLuid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LookupPrivilegeValueW(PWSTR lpSystemName, PWSTR lpName, LUID* lpLuid);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LookupPrivilegeNameA(PSTR lpSystemName, LUID* lpLuid, uint8* lpName, uint32* cchName);
	public static BOOL LookupPrivilegeName(PSTR lpSystemName, LUID* lpLuid, uint8* lpName, uint32* cchName) => LookupPrivilegeNameA(lpSystemName, lpLuid, lpName, cchName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LookupPrivilegeNameW(PWSTR lpSystemName, LUID* lpLuid, char16* lpName, uint32* cchName);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LookupPrivilegeDisplayNameA(PSTR lpSystemName, PSTR lpName, uint8* lpDisplayName, uint32* cchDisplayName, uint32* lpLanguageId);
	public static BOOL LookupPrivilegeDisplayName(PSTR lpSystemName, PSTR lpName, uint8* lpDisplayName, uint32* cchDisplayName, uint32* lpLanguageId) => LookupPrivilegeDisplayNameA(lpSystemName, lpName, lpDisplayName, cchDisplayName, lpLanguageId);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LookupPrivilegeDisplayNameW(PWSTR lpSystemName, PWSTR lpName, char16* lpDisplayName, uint32* cchDisplayName, uint32* lpLanguageId);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LogonUserA(PSTR lpszUsername, PSTR lpszDomain, PSTR lpszPassword, LOGON32_LOGON dwLogonType, LOGON32_PROVIDER dwLogonProvider, HANDLE* phToken);
	public static BOOL LogonUser(PSTR lpszUsername, PSTR lpszDomain, PSTR lpszPassword, LOGON32_LOGON dwLogonType, LOGON32_PROVIDER dwLogonProvider, HANDLE* phToken) => LogonUserA(lpszUsername, lpszDomain, lpszPassword, dwLogonType, dwLogonProvider, phToken);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LogonUserW(PWSTR lpszUsername, PWSTR lpszDomain, PWSTR lpszPassword, LOGON32_LOGON dwLogonType, LOGON32_PROVIDER dwLogonProvider, HANDLE* phToken);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LogonUserExA(PSTR lpszUsername, PSTR lpszDomain, PSTR lpszPassword, LOGON32_LOGON dwLogonType, LOGON32_PROVIDER dwLogonProvider, HANDLE* phToken, PSID* ppLogonSid, void** ppProfileBuffer, uint32* pdwProfileLength, QUOTA_LIMITS* pQuotaLimits);
	public static BOOL LogonUserEx(PSTR lpszUsername, PSTR lpszDomain, PSTR lpszPassword, LOGON32_LOGON dwLogonType, LOGON32_PROVIDER dwLogonProvider, HANDLE* phToken, PSID* ppLogonSid, void** ppProfileBuffer, uint32* pdwProfileLength, QUOTA_LIMITS* pQuotaLimits) => LogonUserExA(lpszUsername, lpszDomain, lpszPassword, dwLogonType, dwLogonProvider, phToken, ppLogonSid, ppProfileBuffer, pdwProfileLength, pQuotaLimits);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LogonUserExW(PWSTR lpszUsername, PWSTR lpszDomain, PWSTR lpszPassword, LOGON32_LOGON dwLogonType, LOGON32_PROVIDER dwLogonProvider, HANDLE* phToken, PSID* ppLogonSid, void** ppProfileBuffer, uint32* pdwProfileLength, QUOTA_LIMITS* pQuotaLimits);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS RtlConvertSidToUnicodeString(UNICODE_STRING* UnicodeString, PSID Sid, BOOLEAN AllocateDestinationString);

}
#endregion
