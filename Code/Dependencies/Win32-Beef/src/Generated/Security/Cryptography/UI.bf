using Win32.Foundation;
using Win32.Security.Cryptography;
using Win32.UI.Controls;
using Win32.Security.WinTrust;
using System;

namespace Win32.Security.Cryptography.UI;

#region Constants
public static
{
	public const uint32 CRYTPDLG_FLAGS_MASK = 4278190080;
	public const uint32 CRYPTDLG_REVOCATION_DEFAULT = 0;
	public const uint32 CRYPTDLG_REVOCATION_ONLINE = 2147483648;
	public const uint32 CRYPTDLG_REVOCATION_CACHE = 1073741824;
	public const uint32 CRYPTDLG_REVOCATION_NONE = 536870912;
	public const uint32 CRYPTDLG_CACHE_ONLY_URL_RETRIEVAL = 268435456;
	public const uint32 CRYPTDLG_DISABLE_AIA = 134217728;
	public const uint32 CRYPTDLG_POLICY_MASK = 65535;
	public const uint32 POLICY_IGNORE_NON_CRITICAL_BC = 1;
	public const uint32 CRYPTDLG_ACTION_MASK = 4294901760;
	public const uint32 ACTION_REVOCATION_DEFAULT_ONLINE = 65536;
	public const uint32 ACTION_REVOCATION_DEFAULT_CACHE = 131072;
	public const uint32 CERT_DISPWELL_SELECT = 1;
	public const uint32 CERT_DISPWELL_TRUST_CA_CERT = 2;
	public const uint32 CERT_DISPWELL_TRUST_LEAF_CERT = 3;
	public const uint32 CERT_DISPWELL_TRUST_ADD_CA_CERT = 4;
	public const uint32 CERT_DISPWELL_TRUST_ADD_LEAF_CERT = 5;
	public const uint32 CERT_DISPWELL_DISTRUST_CA_CERT = 6;
	public const uint32 CERT_DISPWELL_DISTRUST_LEAF_CERT = 7;
	public const uint32 CERT_DISPWELL_DISTRUST_ADD_CA_CERT = 8;
	public const uint32 CERT_DISPWELL_DISTRUST_ADD_LEAF_CERT = 9;
	public const uint32 CSS_SELECTCERT_MASK = 16777215;
	public const uint32 SELCERT_PROPERTIES = 100;
	public const uint32 SELCERT_FINEPRINT = 101;
	public const uint32 SELCERT_CERTLIST = 102;
	public const uint32 SELCERT_ISSUED_TO = 103;
	public const uint32 SELCERT_VALIDITY = 104;
	public const uint32 SELCERT_ALGORITHM = 105;
	public const uint32 SELCERT_SERIAL_NUM = 106;
	public const uint32 SELCERT_THUMBPRINT = 107;
	public const uint32 CM_VIEWFLAGS_MASK = 16777215;
	public const uint32 CERTVIEW_CRYPTUI_LPARAM = 8388608;
	public const uint32 CERT_FILTER_OP_EXISTS = 1;
	public const uint32 CERT_FILTER_OP_NOT_EXISTS = 2;
	public const uint32 CERT_FILTER_OP_EQUALITY = 3;
	public const uint32 CERT_FILTER_INCLUDE_V1_CERTS = 1;
	public const uint32 CERT_FILTER_VALID_TIME_RANGE = 2;
	public const uint32 CERT_FILTER_VALID_SIGNATURE = 4;
	public const uint32 CERT_FILTER_LEAF_CERTS_ONLY = 8;
	public const uint32 CERT_FILTER_ISSUER_CERTS_ONLY = 16;
	public const uint32 CERT_FILTER_KEY_EXISTS = 32;
	public const String szCERT_CERTIFICATE_ACTION_VERIFY = "{7801ebd0-cf4b-11d0-851f-0060979387ea}";
	public const uint32 CERT_VALIDITY_BEFORE_START = 1;
	public const uint32 CERT_VALIDITY_AFTER_END = 2;
	public const uint32 CERT_VALIDITY_SIGNATURE_FAILS = 4;
	public const uint32 CERT_VALIDITY_CERTIFICATE_REVOKED = 8;
	public const uint32 CERT_VALIDITY_KEY_USAGE_EXT_FAILURE = 16;
	public const uint32 CERT_VALIDITY_EXTENDED_USAGE_FAILURE = 32;
	public const uint32 CERT_VALIDITY_NAME_CONSTRAINTS_FAILURE = 64;
	public const uint32 CERT_VALIDITY_UNKNOWN_CRITICAL_EXTENSION = 128;
	public const uint32 CERT_VALIDITY_ISSUER_INVALID = 256;
	public const uint32 CERT_VALIDITY_OTHER_EXTENSION_FAILURE = 512;
	public const uint32 CERT_VALIDITY_PERIOD_NESTING_FAILURE = 1024;
	public const uint32 CERT_VALIDITY_OTHER_ERROR = 2048;
	public const uint32 CERT_VALIDITY_ISSUER_DISTRUST = 33554432;
	public const uint32 CERT_VALIDITY_EXPLICITLY_DISTRUSTED = 16777216;
	public const uint32 CERT_VALIDITY_NO_ISSUER_CERT_FOUND = 268435456;
	public const uint32 CERT_VALIDITY_NO_CRL_FOUND = 536870912;
	public const uint32 CERT_VALIDITY_CRL_OUT_OF_DATE = 1073741824;
	public const uint32 CERT_VALIDITY_NO_TRUST_DATA = 2147483648;
	public const uint32 CERT_VALIDITY_MASK_TRUST = 4294901760;
	public const uint32 CERT_VALIDITY_MASK_VALIDITY = 65535;
	public const uint32 CERT_TRUST_MASK = 16777215;
	public const uint32 CERT_TRUST_DO_FULL_SEARCH = 1;
	public const uint32 CERT_TRUST_PERMIT_MISSING_CRLS = 2;
	public const uint32 CERT_TRUST_DO_FULL_TRUST = 5;
	public const int32 CERT_CREDENTIAL_PROVIDER_ID = -509;
	public const uint64 CRYPTUI_SELECT_ISSUEDTO_COLUMN = 1;
	public const uint64 CRYPTUI_SELECT_ISSUEDBY_COLUMN = 2;
	public const uint64 CRYPTUI_SELECT_INTENDEDUSE_COLUMN = 4;
	public const uint64 CRYPTUI_SELECT_FRIENDLYNAME_COLUMN = 8;
	public const uint64 CRYPTUI_SELECT_LOCATION_COLUMN = 16;
	public const uint64 CRYPTUI_SELECT_EXPIRATION_COLUMN = 32;
	public const uint32 CRYPTUI_CERT_MGR_TAB_MASK = 15;
	public const uint32 CRYPTUI_CERT_MGR_PUBLISHER_TAB = 4;
	public const uint32 CRYPTUI_CERT_MGR_SINGLE_TAB_FLAG = 32768;
	public const uint32 CRYPTUI_WIZ_DIGITAL_SIGN_EXCLUDE_PAGE_HASHES = 2;
	public const uint32 CRYPTUI_WIZ_DIGITAL_SIGN_INCLUDE_PAGE_HASHES = 4;
	public const uint32 CRYPTUI_WIZ_EXPORT_FORMAT_SERIALIZED_CERT_STORE = 5;
}
#endregion

#region Enums

[AllowDuplicates]
public enum CRYPTUI_WIZ_FLAGS : uint32
{
	CRYPTUI_WIZ_NO_UI = 1,
	CRYPTUI_WIZ_IGNORE_NO_UI_FLAG_FOR_CSPS = 2,
	CRYPTUI_WIZ_NO_UI_EXCEPT_CSP = 3,
	CRYPTUI_WIZ_IMPORT_ALLOW_CERT = 131072,
	CRYPTUI_WIZ_IMPORT_ALLOW_CRL = 262144,
	CRYPTUI_WIZ_IMPORT_ALLOW_CTL = 524288,
	CRYPTUI_WIZ_IMPORT_NO_CHANGE_DEST_STORE = 65536,
	CRYPTUI_WIZ_IMPORT_TO_LOCALMACHINE = 1048576,
	CRYPTUI_WIZ_IMPORT_TO_CURRENTUSER = 2097152,
	CRYPTUI_WIZ_IMPORT_REMOTE_DEST_STORE = 4194304,
	CRYPTUI_WIZ_EXPORT_PRIVATE_KEY = 256,
	CRYPTUI_WIZ_EXPORT_NO_DELETE_PRIVATE_KEY = 512,
}


[AllowDuplicates]
public enum CRYPTUI_VIEWCERTIFICATE_FLAGS : uint32
{
	CRYPTUI_HIDE_HIERARCHYPAGE = 1,
	CRYPTUI_HIDE_DETAILPAGE = 2,
	CRYPTUI_DISABLE_EDITPROPERTIES = 4,
	CRYPTUI_ENABLE_EDITPROPERTIES = 8,
	CRYPTUI_DISABLE_ADDTOSTORE = 16,
	CRYPTUI_ENABLE_ADDTOSTORE = 32,
	CRYPTUI_ACCEPT_DECLINE_STYLE = 64,
	CRYPTUI_IGNORE_UNTRUSTED_ROOT = 128,
	CRYPTUI_DONT_OPEN_STORES = 256,
	CRYPTUI_ONLY_OPEN_ROOT_STORE = 512,
	CRYPTUI_WARN_UNTRUSTED_ROOT = 1024,
	CRYPTUI_ENABLE_REVOCATION_CHECKING = 2048,
	CRYPTUI_WARN_REMOTE_TRUST = 4096,
	CRYPTUI_DISABLE_EXPORT = 8192,
	CRYPTUI_ENABLE_REVOCATION_CHECK_END_CERT = 16384,
	CRYPTUI_ENABLE_REVOCATION_CHECK_CHAIN = 32768,
	CRYPTUI_ENABLE_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT = 2048,
	CRYPTUI_DISABLE_HTMLLINK = 65536,
	CRYPTUI_DISABLE_ISSUERSTATEMENT = 131072,
	CRYPTUI_CACHE_ONLY_URL_RETRIEVAL = 262144,
}


[AllowDuplicates]
public enum CERT_SELECT_STRUCT_FLAGS : uint32
{
	CSS_HIDE_PROPERTIES = 1,
	CSS_ENABLEHOOK = 2,
	CSS_ALLOWMULTISELECT = 4,
	CSS_SHOW_HELP = 16,
	CSS_ENABLETEMPLATE = 32,
	CSS_ENABLETEMPLATEHANDLE = 64,
}


[AllowDuplicates]
public enum CRYPTUI_WIZ_IMPORT_SUBJECT_OPTION : uint32
{
	CRYPTUI_WIZ_IMPORT_SUBJECT_FILE = 1,
	CRYPTUI_WIZ_IMPORT_SUBJECT_CERT_CONTEXT = 2,
	CRYPTUI_WIZ_IMPORT_SUBJECT_CTL_CONTEXT = 3,
	CRYPTUI_WIZ_IMPORT_SUBJECT_CRL_CONTEXT = 4,
	CRYPTUI_WIZ_IMPORT_SUBJECT_CERT_STORE = 5,
}


[AllowDuplicates]
public enum CRYPTUI_WIZ_DIGITAL_SIGN_SUBJECT : uint32
{
	CRYPTUI_WIZ_DIGITAL_SIGN_SUBJECT_BLOB = 2,
	CRYPTUI_WIZ_DIGITAL_SIGN_SUBJECT_FILE = 1,
	CRYPTUI_WIZ_DIGITAL_SIGN_SUBJECT_NONE = 0,
}


[AllowDuplicates]
public enum CRYPTUI_WIZ_DIGITAL_SIGN : uint32
{
	CRYPTUI_WIZ_DIGITAL_SIGN_CERT = 1,
	CRYPTUI_WIZ_DIGITAL_SIGN_STORE = 2,
	CRYPTUI_WIZ_DIGITAL_SIGN_PVK = 3,
	CRYPTUI_WIZ_DIGITAL_SIGN_NONE = 0,
}


[AllowDuplicates]
public enum CRYPTUI_WIZ_EXPORT_SUBJECT : uint32
{
	CRYPTUI_WIZ_EXPORT_CERT_CONTEXT = 1,
	CRYPTUI_WIZ_EXPORT_CTL_CONTEXT = 2,
	CRYPTUI_WIZ_EXPORT_CRL_CONTEXT = 3,
	CRYPTUI_WIZ_EXPORT_CERT_STORE = 4,
	CRYPTUI_WIZ_EXPORT_CERT_STORE_CERTIFICATES_ONLY = 5,
}


[AllowDuplicates]
public enum CRYPTUI_WIZ_DIGITAL_SIGN_SIG_TYPE : uint32
{
	CRYPTUI_WIZ_DIGITAL_SIGN_COMMERCIAL = 1,
	CRYPTUI_WIZ_DIGITAL_SIGN_INDIVIDUAL = 2,
}


[AllowDuplicates]
public enum CRYPTUI_WIZ_DIGITAL_SIGN_PVK_OPTION : uint32
{
	CRYPTUI_WIZ_DIGITAL_SIGN_PVK_FILE = 1,
	CRYPTUI_WIZ_DIGITAL_SIGN_PVK_PROV = 2,
}


[AllowDuplicates]
public enum CERT_VIEWPROPERTIES_STRUCT_FLAGS : uint32
{
	CM_ENABLEHOOK = 1,
	CM_SHOW_HELP = 2,
	CM_SHOW_HELPICON = 4,
	CM_ENABLETEMPLATE = 8,
	CM_HIDE_ADVANCEPAGE = 16,
	CM_HIDE_TRUSTPAGE = 32,
	CM_NO_NAMECHANGE = 64,
	CM_NO_EDITTRUST = 128,
	CM_HIDE_DETAILPAGE = 256,
	CM_ADD_CERT_STORES = 512,
}


[AllowDuplicates]
public enum CRYPTUI_WIZ_EXPORT_FORMAT : uint32
{
	CRYPTUI_WIZ_EXPORT_FORMAT_DER = 1,
	CRYPTUI_WIZ_EXPORT_FORMAT_PFX = 2,
	CRYPTUI_WIZ_EXPORT_FORMAT_PKCS7 = 3,
	CRYPTUI_WIZ_EXPORT_FORMAT_BASE64 = 4,
	CRYPTUI_WIZ_EXPORT_FORMAT_CRL = 6,
	CRYPTUI_WIZ_EXPORT_FORMAT_CTL = 7,
}


[AllowDuplicates]
public enum CRYPTUI_WIZ_DIGITAL_ADDITIONAL_CERT_CHOICE : uint32
{
	CRYPTUI_WIZ_DIGITAL_SIGN_ADD_CHAIN = 1,
	CRYPTUI_WIZ_DIGITAL_SIGN_ADD_CHAIN_NO_ROOT = 2,
	CRYPTUI_WIZ_DIGITAL_SIGN_ADD_NONE = 0,
}


[AllowDuplicates]
public enum CTL_MODIFY_REQUEST_OPERATION : uint32
{
	CTL_MODIFY_REQUEST_ADD_TRUSTED = 3,
	CTL_MODIFY_REQUEST_ADD_NOT_TRUSTED = 1,
	CTL_MODIFY_REQUEST_REMOVE = 2,
}

#endregion

#region Function Pointers
public function BOOL PFNCMFILTERPROC(CERT_CONTEXT* pCertContext, LPARAM param1, uint32 param2, uint32 param3);

public function uint32 PFNCMHOOKPROC(HWND hwndDialog, uint32 message, WPARAM wParam, LPARAM lParam);

public function HRESULT PFNTRUSTHELPER(CERT_CONTEXT* pCertContext, LPARAM lCustData, BOOL fLeafCertificate, uint8* pbTrustBlob);

public function BOOL PFNCFILTERPROC(CERT_CONTEXT* pCertContext, BOOL* pfInitialSelectedCert, void* pvCallbackData);

#endregion

#region Structs
[CRepr]
public struct CERT_SELECT_STRUCT_A
{
	public uint32 dwSize;
	public HWND hwndParent;
	public HINSTANCE hInstance;
	public PSTR pTemplateName;
	public CERT_SELECT_STRUCT_FLAGS dwFlags;
	public PSTR szTitle;
	public uint32 cCertStore;
	public HCERTSTORE* arrayCertStore;
	public PSTR szPurposeOid;
	public uint32 cCertContext;
	public CERT_CONTEXT** arrayCertContext;
	public LPARAM lCustData;
	public PFNCMHOOKPROC pfnHook;
	public PFNCMFILTERPROC pfnFilter;
	public PSTR szHelpFileName;
	public uint32 dwHelpId;
	public uint hprov;
}

[CRepr]
public struct CERT_SELECT_STRUCT_W
{
	public uint32 dwSize;
	public HWND hwndParent;
	public HINSTANCE hInstance;
	public PWSTR pTemplateName;
	public CERT_SELECT_STRUCT_FLAGS dwFlags;
	public PWSTR szTitle;
	public uint32 cCertStore;
	public HCERTSTORE* arrayCertStore;
	public PSTR szPurposeOid;
	public uint32 cCertContext;
	public CERT_CONTEXT** arrayCertContext;
	public LPARAM lCustData;
	public PFNCMHOOKPROC pfnHook;
	public PFNCMFILTERPROC pfnFilter;
	public PWSTR szHelpFileName;
	public uint32 dwHelpId;
	public uint hprov;
}

[CRepr]
public struct CERT_VIEWPROPERTIES_STRUCT_A
{
	public uint32 dwSize;
	public HWND hwndParent;
	public HINSTANCE hInstance;
	public CERT_VIEWPROPERTIES_STRUCT_FLAGS dwFlags;
	public PSTR szTitle;
	public CERT_CONTEXT* pCertContext;
	public PSTR* arrayPurposes;
	public uint32 cArrayPurposes;
	public uint32 cRootStores;
	public HCERTSTORE* rghstoreRoots;
	public uint32 cStores;
	public HCERTSTORE* rghstoreCAs;
	public uint32 cTrustStores;
	public HCERTSTORE* rghstoreTrust;
	public uint hprov;
	public LPARAM lCustData;
	public uint32 dwPad;
	public PSTR szHelpFileName;
	public uint32 dwHelpId;
	public uint32 nStartPage;
	public uint32 cArrayPropSheetPages;
	public PROPSHEETPAGEA* arrayPropSheetPages;
}

[CRepr]
public struct CERT_VIEWPROPERTIES_STRUCT_W
{
	public uint32 dwSize;
	public HWND hwndParent;
	public HINSTANCE hInstance;
	public CERT_VIEWPROPERTIES_STRUCT_FLAGS dwFlags;
	public PWSTR szTitle;
	public CERT_CONTEXT* pCertContext;
	public PSTR* arrayPurposes;
	public uint32 cArrayPurposes;
	public uint32 cRootStores;
	public HCERTSTORE* rghstoreRoots;
	public uint32 cStores;
	public HCERTSTORE* rghstoreCAs;
	public uint32 cTrustStores;
	public HCERTSTORE* rghstoreTrust;
	public uint hprov;
	public LPARAM lCustData;
	public uint32 dwPad;
	public PWSTR szHelpFileName;
	public uint32 dwHelpId;
	public uint32 nStartPage;
	public uint32 cArrayPropSheetPages;
	public PROPSHEETPAGEA* arrayPropSheetPages;
}

[CRepr]
public struct CERT_FILTER_EXTENSION_MATCH
{
	public PSTR szExtensionOID;
	public uint32 dwTestOperation;
	public uint8* pbTestData;
	public uint32 cbTestData;
}

[CRepr]
public struct CERT_FILTER_DATA
{
	public uint32 dwSize;
	public uint32 cExtensionChecks;
	public CERT_FILTER_EXTENSION_MATCH* arrayExtensionChecks;
	public uint32 dwCheckingFlags;
}

[CRepr]
public struct CERT_VERIFY_CERTIFICATE_TRUST
{
	public uint32 cbSize;
	public CERT_CONTEXT* pccert;
	public uint32 dwFlags;
	public uint32 dwIgnoreErr;
	public uint32* pdwErrors;
	public PSTR pszUsageOid;
	public uint hprov;
	public uint32 cRootStores;
	public HCERTSTORE* rghstoreRoots;
	public uint32 cStores;
	public HCERTSTORE* rghstoreCAs;
	public uint32 cTrustStores;
	public HCERTSTORE* rghstoreTrust;
	public LPARAM lCustData;
	public PFNTRUSTHELPER pfnTrustHelper;
	public uint32* pcChain;
	public CERT_CONTEXT*** prgChain;
	public uint32** prgdwErrors;
	public CRYPTOAPI_BLOB** prgpbTrustInfo;
}

[CRepr]
public struct CTL_MODIFY_REQUEST
{
	public CERT_CONTEXT* pccert;
	public CTL_MODIFY_REQUEST_OPERATION dwOperation;
	public uint32 dwError;
}

[CRepr]
public struct CERT_SELECTUI_INPUT
{
	public HCERTSTORE hStore;
	public CERT_CHAIN_CONTEXT** prgpChain;
	public uint32 cChain;
}

[CRepr]
public struct CRYPTUI_CERT_MGR_STRUCT
{
	public uint32 dwSize;
	public HWND hwndParent;
	public uint32 dwFlags;
	public PWSTR pwszTitle;
	public PSTR pszInitUsageOID;
}

[CRepr]
public struct CRYPTUI_WIZ_DIGITAL_SIGN_BLOB_INFO
{
	public uint32 dwSize;
	public Guid* pGuidSubject;
	public uint32 cbBlob;
	public uint8* pbBlob;
	public PWSTR pwszDisplayName;
}

[CRepr]
public struct CRYPTUI_WIZ_DIGITAL_SIGN_STORE_INFO
{
	public uint32 dwSize;
	public uint32 cCertStore;
	public HCERTSTORE* rghCertStore;
	public PFNCFILTERPROC pFilterCallback;
	public void* pvCallbackData;
}

[CRepr]
public struct CRYPTUI_WIZ_DIGITAL_SIGN_PVK_FILE_INFO
{
	public uint32 dwSize;
	public PWSTR pwszPvkFileName;
	public PWSTR pwszProvName;
	public uint32 dwProvType;
}

[CRepr]
public struct CRYPTUI_WIZ_DIGITAL_SIGN_CERT_PVK_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CRYPTUI_WIZ_DIGITAL_SIGN_PVK_FILE_INFO* pPvkFileInfo;
		public CRYPT_KEY_PROV_INFO* pPvkProvInfo;
	}
	public uint32 dwSize;
	public PWSTR pwszSigningCertFileName;
	public CRYPTUI_WIZ_DIGITAL_SIGN_PVK_OPTION dwPvkChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CRYPTUI_WIZ_DIGITAL_SIGN_EXTENDED_INFO
{
	public uint32 dwSize;
	public CRYPTUI_WIZ_DIGITAL_SIGN_SIG_TYPE dwAttrFlags;
	public PWSTR pwszDescription;
	public PWSTR pwszMoreInfoLocation;
	public PSTR pszHashAlg;
	public PWSTR pwszSigningCertDisplayString;
	public HCERTSTORE hAdditionalCertStore;
	public CRYPT_ATTRIBUTES* psAuthenticated;
	public CRYPT_ATTRIBUTES* psUnauthenticated;
}

[CRepr]
public struct CRYPTUI_WIZ_DIGITAL_SIGN_INFO
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public CERT_CONTEXT* pSigningCertContext;
		public CRYPTUI_WIZ_DIGITAL_SIGN_STORE_INFO* pSigningCertStore;
		public CRYPTUI_WIZ_DIGITAL_SIGN_CERT_PVK_INFO* pSigningCertPvkInfo;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PWSTR pwszFileName;
		public CRYPTUI_WIZ_DIGITAL_SIGN_BLOB_INFO* pSignBlobInfo;
	}
	public uint32 dwSize;
	public CRYPTUI_WIZ_DIGITAL_SIGN_SUBJECT dwSubjectChoice;
	public using _Anonymous1_e__Union Anonymous1;
	public CRYPTUI_WIZ_DIGITAL_SIGN dwSigningCertChoice;
	public using _Anonymous2_e__Union Anonymous2;
	public PWSTR pwszTimestampURL;
	public CRYPTUI_WIZ_DIGITAL_ADDITIONAL_CERT_CHOICE dwAdditionalCertChoice;
	public CRYPTUI_WIZ_DIGITAL_SIGN_EXTENDED_INFO* pSignExtInfo;
}

[CRepr]
public struct CRYPTUI_WIZ_DIGITAL_SIGN_CONTEXT
{
	public uint32 dwSize;
	public uint32 cbBlob;
	public uint8* pbBlob;
}

[CRepr]
public struct CRYPTUI_INITDIALOG_STRUCT
{
	public LPARAM lParam;
	public CERT_CONTEXT* pCertContext;
}

[CRepr]
public struct CRYPTUI_VIEWCERTIFICATE_STRUCTW
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CRYPT_PROVIDER_DATA* pCryptProviderData;
		public HANDLE hWVTStateData;
	}
	public uint32 dwSize;
	public HWND hwndParent;
	public CRYPTUI_VIEWCERTIFICATE_FLAGS dwFlags;
	public PWSTR szTitle;
	public CERT_CONTEXT* pCertContext;
	public PSTR* rgszPurposes;
	public uint32 cPurposes;
	public using _Anonymous_e__Union Anonymous;
	public BOOL fpCryptProviderDataTrustedUsage;
	public uint32 idxSigner;
	public uint32 idxCert;
	public BOOL fCounterSigner;
	public uint32 idxCounterSigner;
	public uint32 cStores;
	public HCERTSTORE* rghStores;
	public uint32 cPropSheetPages;
	public PROPSHEETPAGEW* rgPropSheetPages;
	public uint32 nStartPage;
}

[CRepr]
public struct CRYPTUI_VIEWCERTIFICATE_STRUCTA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CRYPT_PROVIDER_DATA* pCryptProviderData;
		public HANDLE hWVTStateData;
	}
	public uint32 dwSize;
	public HWND hwndParent;
	public CRYPTUI_VIEWCERTIFICATE_FLAGS dwFlags;
	public PSTR szTitle;
	public CERT_CONTEXT* pCertContext;
	public PSTR* rgszPurposes;
	public uint32 cPurposes;
	public using _Anonymous_e__Union Anonymous;
	public BOOL fpCryptProviderDataTrustedUsage;
	public uint32 idxSigner;
	public uint32 idxCert;
	public BOOL fCounterSigner;
	public uint32 idxCounterSigner;
	public uint32 cStores;
	public HCERTSTORE* rghStores;
	public uint32 cPropSheetPages;
	public PROPSHEETPAGEA* rgPropSheetPages;
	public uint32 nStartPage;
}

[CRepr]
public struct CRYPTUI_WIZ_EXPORT_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CERT_CONTEXT* pCertContext;
		public CTL_CONTEXT* pCTLContext;
		public CRL_CONTEXT* pCRLContext;
		public HCERTSTORE hCertStore;
	}
	public uint32 dwSize;
	public PWSTR pwszExportFileName;
	public CRYPTUI_WIZ_EXPORT_SUBJECT dwSubjectChoice;
	public using _Anonymous_e__Union Anonymous;
	public uint32 cStores;
	public HCERTSTORE* rghStores;
}

[CRepr]
public struct CRYPTUI_WIZ_EXPORT_CERTCONTEXT_INFO
{
	public uint32 dwSize;
	public CRYPTUI_WIZ_EXPORT_FORMAT dwExportFormat;
	public BOOL fExportChain;
	public BOOL fExportPrivateKeys;
	public PWSTR pwszPassword;
	public BOOL fStrongEncryption;
}

[CRepr]
public struct CRYPTUI_WIZ_IMPORT_SRC_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PWSTR pwszFileName;
		public CERT_CONTEXT* pCertContext;
		public CTL_CONTEXT* pCTLContext;
		public CRL_CONTEXT* pCRLContext;
		public HCERTSTORE hCertStore;
	}
	public uint32 dwSize;
	public CRYPTUI_WIZ_IMPORT_SUBJECT_OPTION dwSubjectChoice;
	public using _Anonymous_e__Union Anonymous;
	public CRYPT_KEY_FLAGS dwFlags;
	public PWSTR pwszPassword;
}

#endregion

#region Functions
public static
{
	[Import("CRYPTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUIDlgViewContext(uint32 dwContextType, void* pvContext, HWND hwnd, PWSTR pwszTitle, uint32 dwFlags, void* pvReserved);

	[Import("CRYPTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CERT_CONTEXT* CryptUIDlgSelectCertificateFromStore(HCERTSTORE hCertStore, HWND hwnd, PWSTR pwszTitle, PWSTR pwszDisplayString, uint32 dwDontUseColumn, uint32 dwFlags, void* pvReserved);

	[Import("CRYPTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSelectionGetSerializedBlob(CERT_SELECTUI_INPUT* pcsi, void** ppOutBuffer, uint32* pulOutBufferSize);

	[Import("CRYPTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUIDlgCertMgr(CRYPTUI_CERT_MGR_STRUCT* pCryptUICertMgr);

	[Import("CRYPTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUIWizDigitalSign(uint32 dwFlags, HWND hwndParent, PWSTR pwszWizardTitle, CRYPTUI_WIZ_DIGITAL_SIGN_INFO* pDigitalSignInfo, CRYPTUI_WIZ_DIGITAL_SIGN_CONTEXT** ppSignContext);

	[Import("CRYPTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUIWizFreeDigitalSignContext(CRYPTUI_WIZ_DIGITAL_SIGN_CONTEXT* pSignContext);

	[Import("CRYPTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUIDlgViewCertificateW(CRYPTUI_VIEWCERTIFICATE_STRUCTW* pCertViewInfo, BOOL* pfPropertiesChanged);

	[Import("CRYPTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUIDlgViewCertificateA(CRYPTUI_VIEWCERTIFICATE_STRUCTA* pCertViewInfo, BOOL* pfPropertiesChanged);
	public static BOOL CryptUIDlgViewCertificate(CRYPTUI_VIEWCERTIFICATE_STRUCTA* pCertViewInfo, BOOL* pfPropertiesChanged) => CryptUIDlgViewCertificateA(pCertViewInfo, pfPropertiesChanged);

	[Import("CRYPTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUIWizExport(CRYPTUI_WIZ_FLAGS dwFlags, HWND hwndParent, PWSTR pwszWizardTitle, CRYPTUI_WIZ_EXPORT_INFO* pExportInfo, void* pvoid);

	[Import("CRYPTUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptUIWizImport(CRYPTUI_WIZ_FLAGS dwFlags, HWND hwndParent, PWSTR pwszWizardTitle, CRYPTUI_WIZ_IMPORT_SRC_INFO* pImportSrc, HCERTSTORE hDestCertStore);

}
#endregion
