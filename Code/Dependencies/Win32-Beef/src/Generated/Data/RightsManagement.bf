using Win32.Foundation;
using System;

namespace Win32.Data.RightsManagement;

#region Constants
public static
{
	public const uint32 DRMHANDLE_INVALID = 0;
	public const uint32 DRMENVHANDLE_INVALID = 0;
	public const uint32 DRMQUERYHANDLE_INVALID = 0;
	public const uint32 DRMHSESSION_INVALID = 0;
	public const uint32 DRMPUBHANDLE_INVALID = 0;
	public const uint32 DRM_AL_NONSILENT = 1;
	public const uint32 DRM_AL_NOPERSIST = 2;
	public const uint32 DRM_AL_CANCEL = 4;
	public const uint32 DRM_AL_FETCHNOADVISORY = 8;
	public const uint32 DRM_AL_NOUI = 16;
	public const uint32 DRM_ACTIVATE_MACHINE = 1;
	public const uint32 DRM_ACTIVATE_GROUPIDENTITY = 2;
	public const uint32 DRM_ACTIVATE_TEMPORARY = 4;
	public const uint32 DRM_ACTIVATE_CANCEL = 8;
	public const uint32 DRM_ACTIVATE_SILENT = 16;
	public const uint32 DRM_ACTIVATE_SHARED_GROUPIDENTITY = 32;
	public const uint32 DRM_ACTIVATE_DELAYED = 64;
	public const uint32 DRM_EL_MACHINE = 1;
	public const uint32 DRM_EL_GROUPIDENTITY = 2;
	public const uint32 DRM_EL_GROUPIDENTITY_NAME = 4;
	public const uint32 DRM_EL_GROUPIDENTITY_LID = 8;
	public const uint32 DRM_EL_SPECIFIED_GROUPIDENTITY = 16;
	public const uint32 DRM_EL_EUL = 32;
	public const uint32 DRM_EL_EUL_LID = 64;
	public const uint32 DRM_EL_CLIENTLICENSOR = 128;
	public const uint32 DRM_EL_CLIENTLICENSOR_LID = 256;
	public const uint32 DRM_EL_SPECIFIED_CLIENTLICENSOR = 512;
	public const uint32 DRM_EL_REVOCATIONLIST = 1024;
	public const uint32 DRM_EL_REVOCATIONLIST_LID = 2048;
	public const uint32 DRM_EL_EXPIRED = 4096;
	public const uint32 DRM_EL_ISSUERNAME = 8192;
	public const uint32 DRM_EL_ISSUANCELICENSE_TEMPLATE = 16384;
	public const uint32 DRM_EL_ISSUANCELICENSE_TEMPLATE_LID = 32768;
	public const uint32 DRM_ADD_LICENSE_NOPERSIST = 0;
	public const uint32 DRM_ADD_LICENSE_PERSIST = 1;
	public const uint32 DRM_SERVICE_TYPE_ACTIVATION = 1;
	public const uint32 DRM_SERVICE_TYPE_CERTIFICATION = 2;
	public const uint32 DRM_SERVICE_TYPE_PUBLISHING = 4;
	public const uint32 DRM_SERVICE_TYPE_CLIENTLICENSOR = 8;
	public const uint32 DRM_SERVICE_TYPE_SILENT = 16;
	public const uint32 DRM_SERVICE_LOCATION_INTERNET = 1;
	public const uint32 DRM_SERVICE_LOCATION_ENTERPRISE = 2;
	public const String DRM_DEFAULTGROUPIDTYPE_WINDOWSAUTH = "WindowsAuthProvider";
	public const String DRM_DEFAULTGROUPIDTYPE_PASSPORT = "PassportAuthProvider";
	public const uint32 DRM_SIGN_ONLINE = 1;
	public const uint32 DRM_SIGN_OFFLINE = 2;
	public const uint32 DRM_SIGN_CANCEL = 4;
	public const uint32 DRM_SERVER_ISSUANCELICENSE = 8;
	public const uint32 DRM_AUTO_GENERATE_KEY = 16;
	public const uint32 DRM_OWNER_LICENSE_NOPERSIST = 32;
	public const uint32 DRM_REUSE_KEY = 64;
	public const uint32 DRM_LOCKBOXTYPE_NONE = 0;
	public const uint32 DRM_LOCKBOXTYPE_WHITEBOX = 1;
	public const uint32 DRM_LOCKBOXTYPE_BLACKBOX = 2;
	public const uint32 DRM_LOCKBOXTYPE_DEFAULT = 2;
	public const uint32 DRM_AILT_NONSILENT = 1;
	public const uint32 DRM_AILT_OBTAIN_ALL = 2;
	public const uint32 DRM_AILT_CANCEL = 4;
	public const uint32 MSDRM_CLIENT_ZONE = 52992;
	public const uint32 MSDRM_POLICY_ZONE = 37632;
	public const uint32 DRMIDVERSION = 0;
	public const uint32 DRMBOUNDLICENSEPARAMSVERSION = 1;
	public const uint32 DRMBINDINGFLAGS_IGNORE_VALIDITY_INTERVALS = 1;
	public const uint32 DRMLICENSEACQDATAVERSION = 0;
	public const uint32 DRMACTSERVINFOVERSION = 0;
	public const uint32 DRMCLIENTSTRUCTVERSION = 1;
	public const uint32 DRMCALLBACKVERSION = 1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum DRMTIMETYPE : int32
{
	DRMTIMETYPE_SYSTEMUTC = 0,
	DRMTIMETYPE_SYSTEMLOCAL = 1,
}


[AllowDuplicates]
public enum DRMENCODINGTYPE : int32
{
	DRMENCODINGTYPE_BASE64 = 0,
	DRMENCODINGTYPE_STRING = 1,
	DRMENCODINGTYPE_LONG = 2,
	DRMENCODINGTYPE_TIME = 3,
	DRMENCODINGTYPE_UINT = 4,
	DRMENCODINGTYPE_RAW = 5,
}


[AllowDuplicates]
public enum DRMATTESTTYPE : int32
{
	DRMATTESTTYPE_FULLENVIRONMENT = 0,
	DRMATTESTTYPE_HASHONLY = 1,
}


[AllowDuplicates]
public enum DRMSPECTYPE : int32
{
	DRMSPECTYPE_UNKNOWN = 0,
	DRMSPECTYPE_FILENAME = 1,
}


[AllowDuplicates]
public enum DRMSECURITYPROVIDERTYPE : int32
{
	DRMSECURITYPROVIDERTYPE_SOFTWARESECREP = 0,
}


[AllowDuplicates]
public enum DRMGLOBALOPTIONS : int32
{
	DRMGLOBALOPTIONS_USE_WINHTTP = 0,
	DRMGLOBALOPTIONS_USE_SERVERSECURITYPROCESSOR = 1,
}


[AllowDuplicates]
public enum DRM_STATUS_MSG : int32
{
	DRM_MSG_ACTIVATE_MACHINE = 0,
	DRM_MSG_ACTIVATE_GROUPIDENTITY = 1,
	DRM_MSG_ACQUIRE_LICENSE = 2,
	DRM_MSG_ACQUIRE_ADVISORY = 3,
	DRM_MSG_SIGN_ISSUANCE_LICENSE = 4,
	DRM_MSG_ACQUIRE_CLIENTLICENSOR = 5,
	DRM_MSG_ACQUIRE_ISSUANCE_LICENSE_TEMPLATE = 6,
}


[AllowDuplicates]
public enum DRM_USAGEPOLICY_TYPE : int32
{
	DRM_USAGEPOLICY_TYPE_BYNAME = 0,
	DRM_USAGEPOLICY_TYPE_BYPUBLICKEY = 1,
	DRM_USAGEPOLICY_TYPE_BYDIGEST = 2,
	DRM_USAGEPOLICY_TYPE_OSEXCLUSION = 3,
}


[AllowDuplicates]
public enum DRM_DISTRIBUTION_POINT_INFO : int32
{
	DRM_DISTRIBUTION_POINT_LICENSE_ACQUISITION = 0,
	DRM_DISTRIBUTION_POINT_PUBLISHING = 1,
	DRM_DISTRIBUTION_POINT_REFERRAL_INFO = 2,
}

#endregion

#region Function Pointers
public function HRESULT DRMCALLBACK(DRM_STATUS_MSG param0, HRESULT param1, void* param2, void* param3);

#endregion

#region Structs
[CRepr]
public struct DRMID
{
	public uint32 uVersion;
	public PWSTR wszIDType;
	public PWSTR wszID;
}

[CRepr]
public struct DRMBOUNDLICENSEPARAMS
{
	public uint32 uVersion;
	public uint32 hEnablingPrincipal;
	public uint32 hSecureStore;
	public PWSTR wszRightsRequested;
	public PWSTR wszRightsGroup;
	public DRMID idResource;
	public uint32 cAuthenticatorCount;
	public uint32* rghAuthenticators;
	public PWSTR wszDefaultEnablingPrincipalCredentials;
	public uint32 dwFlags;
}

[CRepr]
public struct DRM_LICENSE_ACQ_DATA
{
	public uint32 uVersion;
	public PWSTR wszURL;
	public PWSTR wszLocalFilename;
	public uint8* pbPostData;
	public uint32 dwPostDataSize;
	public PWSTR wszFriendlyName;
}

[CRepr]
public struct DRM_ACTSERV_INFO
{
	public uint32 uVersion;
	public PWSTR wszPubKey;
	public PWSTR wszURL;
}

[CRepr]
public struct DRM_CLIENT_VERSION_INFO
{
	public uint32 uStructVersion;
	public uint32[4] dwVersion;
	public char16[256] wszHierarchy;
	public char16[256] wszProductId;
	public char16[256] wszProductDescription;
}

#endregion

#region Functions
public static
{
	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMSetGlobalOptions(DRMGLOBALOPTIONS eGlobalOptions, void* pvdata, uint32 dwlen);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetClientVersion(DRM_CLIENT_VERSION_INFO* pDRMClientVersionInfo);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMInitEnvironment(DRMSECURITYPROVIDERTYPE eSecurityProviderType, DRMSPECTYPE eSpecification, PWSTR wszSecurityProvider, PWSTR wszManifestCredentials, PWSTR wszMachineCredentials, uint32* phEnv, uint32* phDefaultLibrary);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMLoadLibrary(uint32 hEnv, DRMSPECTYPE eSpecification, PWSTR wszLibraryProvider, PWSTR wszCredentials, uint32* phLibrary);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCreateEnablingPrincipal(uint32 hEnv, uint32 hLibrary, PWSTR wszObject, DRMID* pidPrincipal, PWSTR wszCredentials, uint32* phEnablingPrincipal);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCloseHandle(uint32 handle);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCloseEnvironmentHandle(uint32 hEnv);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMDuplicateHandle(uint32 hToCopy, uint32* phCopy);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMDuplicateEnvironmentHandle(uint32 hToCopy, uint32* phCopy);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMRegisterRevocationList(uint32 hEnv, PWSTR wszRevocationList);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCheckSecurity(uint32 hEnv, uint32 cLevel);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMRegisterContent(BOOL fRegister);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMEncrypt(uint32 hCryptoProvider, uint32 iPosition, uint32 cNumInBytes, uint8* pbInData, uint32* pcNumOutBytes, uint8* pbOutData);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMDecrypt(uint32 hCryptoProvider, uint32 iPosition, uint32 cNumInBytes, uint8* pbInData, uint32* pcNumOutBytes, uint8* pbOutData);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCreateBoundLicense(uint32 hEnv, DRMBOUNDLICENSEPARAMS* pParams, PWSTR wszLicenseChain, uint32* phBoundLicense, uint32* phErrorLog);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCreateEnablingBitsDecryptor(uint32 hBoundLicense, PWSTR wszRight, uint32 hAuxLib, PWSTR wszAuxPlug, uint32* phDecryptor);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCreateEnablingBitsEncryptor(uint32 hBoundLicense, PWSTR wszRight, uint32 hAuxLib, PWSTR wszAuxPlug, uint32* phEncryptor);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMAttest(uint32 hEnablingPrincipal, PWSTR wszData, DRMATTESTTYPE eType, uint32* pcAttestedBlob, char16* wszAttestedBlob);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetTime(uint32 hEnv, DRMTIMETYPE eTimerIdType, SYSTEMTIME* poTimeObject);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetInfo(uint32 handle, PWSTR wszAttribute, DRMENCODINGTYPE* peEncoding, uint32* pcBuffer, uint8* pbBuffer);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetEnvironmentInfo(uint32 handle, PWSTR wszAttribute, DRMENCODINGTYPE* peEncoding, uint32* pcBuffer, uint8* pbBuffer);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetProcAddress(uint32 hLibrary, PWSTR wszProcName, FARPROC* ppfnProcAddress);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetBoundLicenseObjectCount(uint32 hQueryRoot, PWSTR wszSubObjectType, uint32* pcSubObjects);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetBoundLicenseObject(uint32 hQueryRoot, PWSTR wszSubObjectType, uint32 iWhich, uint32* phSubObject);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetBoundLicenseAttributeCount(uint32 hQueryRoot, PWSTR wszAttribute, uint32* pcAttributes);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetBoundLicenseAttribute(uint32 hQueryRoot, PWSTR wszAttribute, uint32 iWhich, DRMENCODINGTYPE* peEncoding, uint32* pcBuffer, uint8* pbBuffer);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCreateClientSession(DRMCALLBACK pfnCallback, uint32 uCallbackVersion, PWSTR wszGroupIDProviderType, PWSTR wszGroupID, uint32* phClient);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMIsActivated(uint32 hClient, uint32 uFlags, DRM_ACTSERV_INFO* pActServInfo);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMActivate(uint32 hClient, uint32 uFlags, uint32 uLangID, DRM_ACTSERV_INFO* pActServInfo, void* pvContext, HWND hParentWnd);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetServiceLocation(uint32 hClient, uint32 uServiceType, uint32 uServiceLocation, PWSTR wszIssuanceLicense, uint32* puServiceURLLength, char16* wszServiceURL);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCreateLicenseStorageSession(uint32 hEnv, uint32 hDefaultLibrary, uint32 hClient, uint32 uFlags, PWSTR wszIssuanceLicense, uint32* phLicenseStorage);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMAddLicense(uint32 hLicenseStorage, uint32 uFlags, PWSTR wszLicense);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMAcquireAdvisories(uint32 hLicenseStorage, PWSTR wszLicense, PWSTR wszURL, void* pvContext);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMEnumerateLicense(uint32 hSession, uint32 uFlags, uint32 uIndex, BOOL* pfSharedFlag, uint32* puCertificateDataLen, char16* wszCertificateData);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMAcquireLicense(uint32 hSession, uint32 uFlags, PWSTR wszGroupIdentityCredential, PWSTR wszRequestedRights, PWSTR wszCustomData, PWSTR wszURL, void* pvContext);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMDeleteLicense(uint32 hSession, PWSTR wszLicenseId);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCloseSession(uint32 hSession);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMDuplicateSession(uint32 hSessionIn, uint32* phSessionOut);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetSecurityProvider(uint32 uFlags, uint32* puTypeLen, char16* wszType, uint32* puPathLen, char16* wszPath);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMEncode(PWSTR wszAlgID, uint32 uDataLen, uint8* pbDecodedData, uint32* puEncodedStringLen, char16* wszEncodedString);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMDecode(PWSTR wszAlgID, PWSTR wszEncodedString, uint32* puDecodedDataLen, uint8* pbDecodedData);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMConstructCertificateChain(uint32 cCertificates, PWSTR* rgwszCertificates, uint32* pcChain, char16* wszChain);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMParseUnboundLicense(PWSTR wszCertificate, uint32* phQueryRoot);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCloseQueryHandle(uint32 hQuery);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetUnboundLicenseObjectCount(uint32 hQueryRoot, PWSTR wszSubObjectType, uint32* pcSubObjects);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetUnboundLicenseObject(uint32 hQueryRoot, PWSTR wszSubObjectType, uint32 iIndex, uint32* phSubQuery);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetUnboundLicenseAttributeCount(uint32 hQueryRoot, PWSTR wszAttributeType, uint32* pcAttributes);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetUnboundLicenseAttribute(uint32 hQueryRoot, PWSTR wszAttributeType, uint32 iWhich, DRMENCODINGTYPE* peEncoding, uint32* pcBuffer, uint8* pbBuffer);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetCertificateChainCount(PWSTR wszChain, uint32* pcCertCount);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMDeconstructCertificateChain(PWSTR wszChain, uint32 iWhich, uint32* pcCert, char16* wszCert);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMVerify(PWSTR wszData, uint32* pcAttestedData, char16* wszAttestedData, DRMATTESTTYPE* peType, uint32* pcPrincipal, char16* wszPrincipal, uint32* pcManifest, char16* wszManifest);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCreateUser(PWSTR wszUserName, PWSTR wszUserId, PWSTR wszUserIdType, uint32* phUser);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCreateRight(PWSTR wszRightName, SYSTEMTIME* pstFrom, SYSTEMTIME* pstUntil, uint32 cExtendedInfo, PWSTR* pwszExtendedInfoName, PWSTR* pwszExtendedInfoValue, uint32* phRight);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMCreateIssuanceLicense(SYSTEMTIME* pstTimeFrom, SYSTEMTIME* pstTimeUntil, PWSTR wszReferralInfoName, PWSTR wszReferralInfoURL, uint32 hOwner, PWSTR wszIssuanceLicense, uint32 hBoundLicense, uint32* phIssuanceLicense);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMAddRightWithUser(uint32 hIssuanceLicense, uint32 hRight, uint32 hUser);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMClearAllRights(uint32 hIssuanceLicense);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMSetMetaData(uint32 hIssuanceLicense, PWSTR wszContentId, PWSTR wszContentIdType, PWSTR wszSKUId, PWSTR wszSKUIdType, PWSTR wszContentType, PWSTR wszContentName);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMSetUsagePolicy(uint32 hIssuanceLicense, DRM_USAGEPOLICY_TYPE eUsagePolicyType, BOOL fDelete, BOOL fExclusion, PWSTR wszName, PWSTR wszMinVersion, PWSTR wszMaxVersion, PWSTR wszPublicKey, PWSTR wszDigestAlgorithm, uint8* pbDigest, uint32 cbDigest);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMSetRevocationPoint(uint32 hIssuanceLicense, BOOL fDelete, PWSTR wszId, PWSTR wszIdType, PWSTR wszURL, SYSTEMTIME* pstFrequency, PWSTR wszName, PWSTR wszPublicKey);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMSetApplicationSpecificData(uint32 hIssuanceLicense, BOOL fDelete, PWSTR wszName, PWSTR wszValue);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMSetNameAndDescription(uint32 hIssuanceLicense, BOOL fDelete, uint32 lcid, PWSTR wszName, PWSTR wszDescription);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMSetIntervalTime(uint32 hIssuanceLicense, uint32 cDays);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetIssuanceLicenseTemplate(uint32 hIssuanceLicense, uint32* puIssuanceLicenseTemplateLength, char16* wszIssuanceLicenseTemplate);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetSignedIssuanceLicense(uint32 hEnv, uint32 hIssuanceLicense, uint32 uFlags, uint8* pbSymKey, uint32 cbSymKey, PWSTR wszSymKeyType, PWSTR wszClientLicensorCertificate, DRMCALLBACK pfnCallback, PWSTR wszURL, void* pvContext);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetSignedIssuanceLicenseEx(uint32 hEnv, uint32 hIssuanceLicense, uint32 uFlags, uint8* pbSymKey, uint32 cbSymKey, PWSTR wszSymKeyType, void* pvReserved, uint32 hEnablingPrincipal, uint32 hBoundLicenseCLC, DRMCALLBACK pfnCallback, void* pvContext);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMClosePubHandle(uint32 hPub);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMDuplicatePubHandle(uint32 hPubIn, uint32* phPubOut);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetUserInfo(uint32 hUser, uint32* puUserNameLength, char16* wszUserName, uint32* puUserIdLength, char16* wszUserId, uint32* puUserIdTypeLength, char16* wszUserIdType);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetRightInfo(uint32 hRight, uint32* puRightNameLength, char16* wszRightName, SYSTEMTIME* pstFrom, SYSTEMTIME* pstUntil);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetRightExtendedInfo(uint32 hRight, uint32 uIndex, uint32* puExtendedInfoNameLength, char16* wszExtendedInfoName, uint32* puExtendedInfoValueLength, char16* wszExtendedInfoValue);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetUsers(uint32 hIssuanceLicense, uint32 uIndex, uint32* phUser);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetUserRights(uint32 hIssuanceLicense, uint32 hUser, uint32 uIndex, uint32* phRight);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetMetaData(uint32 hIssuanceLicense, uint32* puContentIdLength, char16* wszContentId, uint32* puContentIdTypeLength, char16* wszContentIdType, uint32* puSKUIdLength, char16* wszSKUId, uint32* puSKUIdTypeLength, char16* wszSKUIdType, uint32* puContentTypeLength, char16* wszContentType, uint32* puContentNameLength, char16* wszContentName);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetApplicationSpecificData(uint32 hIssuanceLicense, uint32 uIndex, uint32* puNameLength, char16* wszName, uint32* puValueLength, char16* wszValue);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetIssuanceLicenseInfo(uint32 hIssuanceLicense, SYSTEMTIME* pstTimeFrom, SYSTEMTIME* pstTimeUntil, uint32 uFlags, uint32* puDistributionPointNameLength, char16* wszDistributionPointName, uint32* puDistributionPointURLLength, char16* wszDistributionPointURL, uint32* phOwner, BOOL* pfOfficial);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetRevocationPoint(uint32 hIssuanceLicense, uint32* puIdLength, char16* wszId, uint32* puIdTypeLength, char16* wszIdType, uint32* puURLLength, char16* wszRL, SYSTEMTIME* pstFrequency, uint32* puNameLength, char16* wszName, uint32* puPublicKeyLength, char16* wszPublicKey);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetUsagePolicy(uint32 hIssuanceLicense, uint32 uIndex, DRM_USAGEPOLICY_TYPE* peUsagePolicyType, BOOL* pfExclusion, uint32* puNameLength, char16* wszName, uint32* puMinVersionLength, char16* wszMinVersion, uint32* puMaxVersionLength, char16* wszMaxVersion, uint32* puPublicKeyLength, char16* wszPublicKey, uint32* puDigestAlgorithmLength, char16* wszDigestAlgorithm, uint32* pcbDigest, uint8* pbDigest);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetNameAndDescription(uint32 hIssuanceLicense, uint32 uIndex, uint32* pulcid, uint32* puNameLength, char16* wszName, uint32* puDescriptionLength, char16* wszDescription);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetOwnerLicense(uint32 hIssuanceLicense, uint32* puOwnerLicenseLength, char16* wszOwnerLicense);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMGetIntervalTime(uint32 hIssuanceLicense, uint32* pcDays);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMRepair();

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMRegisterProtectedWindow(uint32 hEnv, HWND hwnd);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMIsWindowProtected(HWND hwnd, BOOL* pfProtected);

	[Import("msdrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DRMAcquireIssuanceLicenseTemplate(uint32 hClient, uint32 uFlags, void* pvReserved, uint32 cTemplates, PWSTR* pwszTemplateIds, PWSTR wszUrl, void* pvContext);

}
#endregion
