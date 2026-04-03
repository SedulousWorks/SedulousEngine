using Win32.Foundation;
using Win32.Security.Cryptography;
using Win32.Security.Cryptography.Sip;
using System;

namespace Win32.Security.WinTrust;

#region Constants
public static
{
	public const String WINTRUST_CONFIG_REGPATH = "Software\\Microsoft\\Cryptography\\Wintrust\\Config";
	public const String WINTRUST_MAX_HEADER_BYTES_TO_MAP_VALUE_NAME = "MaxHeaderBytesToMap";
	public const uint32 WINTRUST_MAX_HEADER_BYTES_TO_MAP_DEFAULT = 10485760;
	public const String WINTRUST_MAX_HASH_BYTES_TO_MAP_VALUE_NAME = "MaxHashBytesToMap";
	public const uint32 WINTRUST_MAX_HASH_BYTES_TO_MAP_DEFAULT = 1048576;
	public const uint32 WTD_PROV_FLAGS_MASK = 65535;
	public const uint32 WTD_CODE_INTEGRITY_DRIVER_MODE = 32768;
	public const uint32 WSS_VERIFY_SEALING = 4;
	public const uint32 WSS_INPUT_FLAG_MASK = 7;
	public const uint32 WSS_OUT_SEALING_STATUS_VERIFIED = 2147483648;
	public const uint32 WSS_OUT_HAS_SEALING_INTENT = 1073741824;
	public const uint32 WSS_OUT_FILE_SUPPORTS_SEAL = 536870912;
	public const uint32 WSS_OUTPUT_FLAG_MASK = 3758096384;
	public const uint32 WTCI_DONT_OPEN_STORES = 1;
	public const uint32 WTCI_OPEN_ONLY_ROOT = 2;
	public const uint32 WTCI_USE_LOCAL_MACHINE = 4;
	public const uint32 TRUSTERROR_STEP_WVTPARAMS = 0;
	public const uint32 TRUSTERROR_STEP_FILEIO = 2;
	public const uint32 TRUSTERROR_STEP_SIP = 3;
	public const uint32 TRUSTERROR_STEP_SIPSUBJINFO = 5;
	public const uint32 TRUSTERROR_STEP_CATALOGFILE = 6;
	public const uint32 TRUSTERROR_STEP_CERTSTORE = 7;
	public const uint32 TRUSTERROR_STEP_MESSAGE = 8;
	public const uint32 TRUSTERROR_STEP_MSG_SIGNERCOUNT = 9;
	public const uint32 TRUSTERROR_STEP_MSG_INNERCNTTYPE = 10;
	public const uint32 TRUSTERROR_STEP_MSG_INNERCNT = 11;
	public const uint32 TRUSTERROR_STEP_MSG_STORE = 12;
	public const uint32 TRUSTERROR_STEP_MSG_SIGNERINFO = 13;
	public const uint32 TRUSTERROR_STEP_MSG_SIGNERCERT = 14;
	public const uint32 TRUSTERROR_STEP_MSG_CERTCHAIN = 15;
	public const uint32 TRUSTERROR_STEP_MSG_COUNTERSIGINFO = 16;
	public const uint32 TRUSTERROR_STEP_MSG_COUNTERSIGCERT = 17;
	public const uint32 TRUSTERROR_STEP_VERIFY_MSGHASH = 18;
	public const uint32 TRUSTERROR_STEP_VERIFY_MSGINDIRECTDATA = 19;
	public const uint32 TRUSTERROR_STEP_FINAL_WVTINIT = 30;
	public const uint32 TRUSTERROR_STEP_FINAL_INITPROV = 31;
	public const uint32 TRUSTERROR_STEP_FINAL_OBJPROV = 32;
	public const uint32 TRUSTERROR_STEP_FINAL_SIGPROV = 33;
	public const uint32 TRUSTERROR_STEP_FINAL_CERTPROV = 34;
	public const uint32 TRUSTERROR_STEP_FINAL_CERTCHKPROV = 35;
	public const uint32 TRUSTERROR_STEP_FINAL_POLICYPROV = 36;
	public const uint32 TRUSTERROR_STEP_FINAL_UIPROV = 37;
	public const uint32 TRUSTERROR_MAX_STEPS = 38;
	public const uint32 CPD_CHOICE_SIP = 1;
	public const uint32 CPD_USE_NT5_CHAIN_FLAG = 2147483648;
	public const uint32 CPD_REVOCATION_CHECK_NONE = 65536;
	public const uint32 CPD_REVOCATION_CHECK_END_CERT = 131072;
	public const uint32 CPD_REVOCATION_CHECK_CHAIN = 262144;
	public const uint32 CPD_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT = 524288;
	public const uint32 CPD_RETURN_LOWER_QUALITY_CHAINS = 1048576;
	public const uint32 CPD_UISTATE_MODE_PROMPT = 0;
	public const uint32 CPD_UISTATE_MODE_BLOCK = 1;
	public const uint32 CPD_UISTATE_MODE_ALLOW = 2;
	public const uint32 CPD_UISTATE_MODE_MASK = 3;
	public const uint32 WSS_OBJTRUST_SUPPORT = 1;
	public const uint32 WSS_SIGTRUST_SUPPORT = 2;
	public const uint32 WSS_CERTTRUST_SUPPORT = 4;
	public const uint32 SGNR_TYPE_TIMESTAMP = 16;
	public const uint32 CERT_CONFIDENCE_SIG = 268435456;
	public const uint32 CERT_CONFIDENCE_TIME = 16777216;
	public const uint32 CERT_CONFIDENCE_TIMENEST = 1048576;
	public const uint32 CERT_CONFIDENCE_AUTHIDEXT = 65536;
	public const uint32 CERT_CONFIDENCE_HYGIENE = 4096;
	public const uint32 CERT_CONFIDENCE_HIGHEST = 286330880;
	public const uint32 WT_CURRENT_VERSION = 512;
	public const String WT_PROVIDER_DLL_NAME = "WINTRUST.DLL";
	public const String WT_PROVIDER_CERTTRUST_FUNCTION = "WintrustCertificateTrust";
	public const uint32 WT_ADD_ACTION_ID_RET_RESULT_FLAG = 1;
	public const String szOID_TRUSTED_CODESIGNING_CA_LIST = "1.3.6.1.4.1.311.2.2.1";
	public const String szOID_TRUSTED_CLIENT_AUTH_CA_LIST = "1.3.6.1.4.1.311.2.2.2";
	public const String szOID_TRUSTED_SERVER_AUTH_CA_LIST = "1.3.6.1.4.1.311.2.2.3";
	public const String SPC_COMMON_NAME_OBJID = "2.5.4.3";
	public const String SPC_TIME_STAMP_REQUEST_OBJID = "1.3.6.1.4.1.311.3.2.1";
	public const String SPC_INDIRECT_DATA_OBJID = "1.3.6.1.4.1.311.2.1.4";
	public const String SPC_SP_AGENCY_INFO_OBJID = "1.3.6.1.4.1.311.2.1.10";
	public const String SPC_STATEMENT_TYPE_OBJID = "1.3.6.1.4.1.311.2.1.11";
	public const String SPC_SP_OPUS_INFO_OBJID = "1.3.6.1.4.1.311.2.1.12";
	public const String SPC_CERT_EXTENSIONS_OBJID = "1.3.6.1.4.1.311.2.1.14";
	public const String SPC_PE_IMAGE_DATA_OBJID = "1.3.6.1.4.1.311.2.1.15";
	public const String SPC_RAW_FILE_DATA_OBJID = "1.3.6.1.4.1.311.2.1.18";
	public const String SPC_STRUCTURED_STORAGE_DATA_OBJID = "1.3.6.1.4.1.311.2.1.19";
	public const String SPC_JAVA_CLASS_DATA_OBJID = "1.3.6.1.4.1.311.2.1.20";
	public const String SPC_INDIVIDUAL_SP_KEY_PURPOSE_OBJID = "1.3.6.1.4.1.311.2.1.21";
	public const String SPC_COMMERCIAL_SP_KEY_PURPOSE_OBJID = "1.3.6.1.4.1.311.2.1.22";
	public const String SPC_CAB_DATA_OBJID = "1.3.6.1.4.1.311.2.1.25";
	public const String SPC_GLUE_RDN_OBJID = "1.3.6.1.4.1.311.2.1.25";
	public const String SPC_MINIMAL_CRITERIA_OBJID = "1.3.6.1.4.1.311.2.1.26";
	public const String SPC_FINANCIAL_CRITERIA_OBJID = "1.3.6.1.4.1.311.2.1.27";
	public const String SPC_LINK_OBJID = "1.3.6.1.4.1.311.2.1.28";
	public const String SPC_SIGINFO_OBJID = "1.3.6.1.4.1.311.2.1.30";
	public const String SPC_PE_IMAGE_PAGE_HASHES_V1_OBJID = "1.3.6.1.4.1.311.2.3.1";
	public const String SPC_PE_IMAGE_PAGE_HASHES_V2_OBJID = "1.3.6.1.4.1.311.2.3.2";
	public const String szOID_NESTED_SIGNATURE = "1.3.6.1.4.1.311.2.4.1";
	public const String szOID_INTENT_TO_SEAL = "1.3.6.1.4.1.311.2.4.2";
	public const String szOID_SEALING_SIGNATURE = "1.3.6.1.4.1.311.2.4.3";
	public const String szOID_SEALING_TIMESTAMP = "1.3.6.1.4.1.311.2.4.4";
	public const String szOID_ENHANCED_HASH = "1.3.6.1.4.1.311.2.5.1";
	public const String SPC_RELAXED_PE_MARKER_CHECK_OBJID = "1.3.6.1.4.1.311.2.6.1";
	public const String SPC_ENCRYPTED_DIGEST_RETRY_COUNT_OBJID = "1.3.6.1.4.1.311.2.6.2";
	public const String szOID_PKCS_9_SEQUENCE_NUMBER = "1.2.840.113549.1.9.25.4";
	public const String CAT_NAMEVALUE_OBJID = "1.3.6.1.4.1.311.12.2.1";
	public const String CAT_MEMBERINFO_OBJID = "1.3.6.1.4.1.311.12.2.2";
	public const String CAT_MEMBERINFO2_OBJID = "1.3.6.1.4.1.311.12.2.3";
	public const String SPC_WINDOWS_HELLO_COMPATIBILITY_OBJID = "1.3.6.1.4.1.311.10.41.1";
	public const String SPC_NATURAL_AUTH_PLUGIN_OBJID = "1.3.6.1.4.1.311.96.1.1";
	public const PSTR SPC_SP_AGENCY_INFO_STRUCT = (PSTR)(void*)2000;
	public const PSTR SPC_MINIMAL_CRITERIA_STRUCT = (PSTR)(void*)2001;
	public const PSTR SPC_FINANCIAL_CRITERIA_STRUCT = (PSTR)(void*)2002;
	public const PSTR SPC_INDIRECT_DATA_CONTENT_STRUCT = (PSTR)(void*)2003;
	public const PSTR SPC_PE_IMAGE_DATA_STRUCT = (PSTR)(void*)2004;
	public const PSTR SPC_LINK_STRUCT = (PSTR)(void*)2005;
	public const PSTR SPC_STATEMENT_TYPE_STRUCT = (PSTR)(void*)2006;
	public const PSTR SPC_SP_OPUS_INFO_STRUCT = (PSTR)(void*)2007;
	public const PSTR SPC_CAB_DATA_STRUCT = (PSTR)(void*)2008;
	public const PSTR SPC_JAVA_CLASS_DATA_STRUCT = (PSTR)(void*)2009;
	public const PSTR INTENT_TO_SEAL_ATTRIBUTE_STRUCT = (PSTR)(void*)2010;
	public const PSTR SEALING_SIGNATURE_ATTRIBUTE_STRUCT = (PSTR)(void*)2011;
	public const PSTR SEALING_TIMESTAMP_ATTRIBUTE_STRUCT = (PSTR)(void*)2012;
	public const PSTR SPC_SIGINFO_STRUCT = (PSTR)(void*)2130;
	public const PSTR CAT_NAMEVALUE_STRUCT = (PSTR)(void*)2221;
	public const PSTR CAT_MEMBERINFO_STRUCT = (PSTR)(void*)2222;
	public const PSTR CAT_MEMBERINFO2_STRUCT = (PSTR)(void*)2223;
	public const uint32 SPC_UUID_LENGTH = 16;
	public const uint32 SPC_URL_LINK_CHOICE = 1;
	public const uint32 SPC_MONIKER_LINK_CHOICE = 2;
	public const uint32 SPC_FILE_LINK_CHOICE = 3;
	public const uint32 WIN_CERT_REVISION_1_0 = 256;
	public const uint32 WIN_CERT_REVISION_2_0 = 512;
	public const uint32 WIN_CERT_TYPE_X509 = 1;
	public const uint32 WIN_CERT_TYPE_PKCS_SIGNED_DATA = 2;
	public const uint32 WIN_CERT_TYPE_RESERVED_1 = 3;
	public const uint32 WIN_CERT_TYPE_TS_STACK_SIGNED = 4;
	public const uint32 WT_TRUSTDBDIALOG_NO_UI_FLAG = 1;
	public const uint32 WT_TRUSTDBDIALOG_ONLY_PUB_TAB_FLAG = 2;
	public const uint32 WT_TRUSTDBDIALOG_WRITE_LEGACY_REG_FLAG = 256;
	public const uint32 WT_TRUSTDBDIALOG_WRITE_IEAK_STORE_FLAG = 512;
	public const String SP_POLICY_PROVIDER_DLL_NAME = "WINTRUST.DLL";
	public const String SP_INIT_FUNCTION = "SoftpubInitialize";
	public const String SP_OBJTRUST_FUNCTION = "SoftpubLoadMessage";
	public const String SP_SIGTRUST_FUNCTION = "SoftpubLoadSignature";
	public const String SP_CHKCERT_FUNCTION = "SoftpubCheckCert";
	public const String SP_FINALPOLICY_FUNCTION = "SoftpubAuthenticode";
	public const String SP_CLEANUPPOLICY_FUNCTION = "SoftpubCleanup";
	public const String SP_TESTDUMPPOLICY_FUNCTION_TEST = "SoftpubDumpStructure";
	public const String SP_GENERIC_CERT_INIT_FUNCTION = "SoftpubDefCertInit";
	public const String GENERIC_CHAIN_FINALPOLICY_FUNCTION = "GenericChainFinalProv";
	public const String GENERIC_CHAIN_CERTTRUST_FUNCTION = "GenericChainCertificateTrust";
	public const String HTTPS_FINALPOLICY_FUNCTION = "HTTPSFinalProv";
	public const String HTTPS_CHKCERT_FUNCTION = "HTTPSCheckCertProv";
	public const String HTTPS_CERTTRUST_FUNCTION = "HTTPSCertificateTrust";
	public const String OFFICE_POLICY_PROVIDER_DLL_NAME = "WINTRUST.DLL";
	public const String OFFICE_INITPROV_FUNCTION = "OfficeInitializePolicy";
	public const String OFFICE_CLEANUPPOLICY_FUNCTION = "OfficeCleanupPolicy";
	public const String DRIVER_INITPROV_FUNCTION = "DriverInitializePolicy";
	public const String DRIVER_FINALPOLPROV_FUNCTION = "DriverFinalPolicy";
	public const String DRIVER_CLEANUPPOLICY_FUNCTION = "DriverCleanupPolicy";
	public const uint32 CCPI_RESULT_ALLOW = 1;
	public const uint32 CCPI_RESULT_DENY = 2;
	public const uint32 CCPI_RESULT_AUDIT = 3;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WINTRUST_GET_DEFAULT_FOR_USAGE_ACTION : uint32
{
	DWACTION_ALLOCANDFILL = 1,
	DWACTION_FREE = 2,
}


[AllowDuplicates]
public enum WINTRUST_POLICY_FLAGS : uint32
{
	WTPF_TRUSTTEST = 32,
	WTPF_TESTCANBEVALID = 128,
	WTPF_IGNOREEXPIRATION = 256,
	WTPF_IGNOREREVOKATION = 512,
	WTPF_OFFLINEOK_IND = 1024,
	WTPF_OFFLINEOK_COM = 2048,
	WTPF_OFFLINEOKNBU_IND = 4096,
	WTPF_OFFLINEOKNBU_COM = 8192,
	WTPF_VERIFY_V1_OFF = 65536,
	WTPF_IGNOREREVOCATIONONTS = 131072,
	WTPF_ALLOWONLYPERTRUST = 262144,
}


[AllowDuplicates]
public enum WINTRUST_DATA_PROVIDER_FLAGS : uint32
{
	WTD_USE_IE4_TRUST_FLAG = 1,
	WTD_NO_IE4_CHAIN_FLAG = 2,
	WTD_NO_POLICY_USAGE_FLAG = 4,
	WTD_REVOCATION_CHECK_NONE = 16,
	WTD_REVOCATION_CHECK_END_CERT = 32,
	WTD_REVOCATION_CHECK_CHAIN = 64,
	WTD_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT = 128,
	WTD_SAFER_FLAG = 256,
	WTD_HASH_ONLY_FLAG = 512,
	WTD_USE_DEFAULT_OSVER_CHECK = 1024,
	WTD_LIFETIME_SIGNING_FLAG = 2048,
	WTD_CACHE_ONLY_URL_RETRIEVAL = 4096,
	WTD_DISABLE_MD2_MD4 = 8192,
	WTD_MOTW = 16384,
}


[AllowDuplicates]
public enum WINTRUST_DATA_UICHOICE : uint32
{
	WTD_UI_ALL = 1,
	WTD_UI_NONE = 2,
	WTD_UI_NOBAD = 3,
	WTD_UI_NOGOOD = 4,
}


[AllowDuplicates]
public enum WINTRUST_SIGNATURE_SETTINGS_FLAGS : uint32
{
	WSS_VERIFY_SPECIFIC = 1,
	WSS_GET_SECONDARY_SIG_COUNT = 2,
}


[AllowDuplicates]
public enum WINTRUST_DATA_STATE_ACTION : uint32
{
	WTD_STATEACTION_IGNORE = 0,
	WTD_STATEACTION_VERIFY = 1,
	WTD_STATEACTION_CLOSE = 2,
	WTD_STATEACTION_AUTO_CACHE = 3,
	WTD_STATEACTION_AUTO_CACHE_FLUSH = 4,
}


[AllowDuplicates]
public enum WINTRUST_DATA_UNION_CHOICE : uint32
{
	WTD_CHOICE_FILE = 1,
	WTD_CHOICE_CATALOG = 2,
	WTD_CHOICE_BLOB = 3,
	WTD_CHOICE_SIGNER = 4,
	WTD_CHOICE_CERT = 5,
}


[AllowDuplicates]
public enum WINTRUST_DATA_REVOCATION_CHECKS : uint32
{
	WTD_REVOKE_NONE = 0,
	WTD_REVOKE_WHOLECHAIN = 1,
}


[AllowDuplicates]
public enum WINTRUST_DATA_UICONTEXT : uint32
{
	WTD_UICONTEXT_EXECUTE = 0,
	WTD_UICONTEXT_INSTALL = 1,
}

#endregion

#region Function Pointers
public function void* PFN_CPD_MEM_ALLOC(uint32 cbSize);

public function void PFN_CPD_MEM_FREE(void* pvMem2Free);

public function BOOL PFN_CPD_ADD_STORE(CRYPT_PROVIDER_DATA* pProvData, HCERTSTORE hStore2Add);

public function BOOL PFN_CPD_ADD_SGNR(CRYPT_PROVIDER_DATA* pProvData, BOOL fCounterSigner, uint32 idxSigner, CRYPT_PROVIDER_SGNR* pSgnr2Add);

public function BOOL PFN_CPD_ADD_CERT(CRYPT_PROVIDER_DATA* pProvData, uint32 idxSigner, BOOL fCounterSigner, uint32 idxCounterSigner, CERT_CONTEXT* pCert2Add);

public function BOOL PFN_CPD_ADD_PRIVDATA(CRYPT_PROVIDER_DATA* pProvData, CRYPT_PROVIDER_PRIVDATA* pPrivData2Add);

public function HRESULT PFN_PROVIDER_INIT_CALL(CRYPT_PROVIDER_DATA* pProvData);

public function HRESULT PFN_PROVIDER_OBJTRUST_CALL(CRYPT_PROVIDER_DATA* pProvData);

public function HRESULT PFN_PROVIDER_SIGTRUST_CALL(CRYPT_PROVIDER_DATA* pProvData);

public function HRESULT PFN_PROVIDER_CERTTRUST_CALL(CRYPT_PROVIDER_DATA* pProvData);

public function HRESULT PFN_PROVIDER_FINALPOLICY_CALL(CRYPT_PROVIDER_DATA* pProvData);

public function HRESULT PFN_PROVIDER_TESTFINALPOLICY_CALL(CRYPT_PROVIDER_DATA* pProvData);

public function HRESULT PFN_PROVIDER_CLEANUP_CALL(CRYPT_PROVIDER_DATA* pProvData);

public function BOOL PFN_PROVIDER_CERTCHKPOLICY_CALL(CRYPT_PROVIDER_DATA* pProvData, uint32 idxSigner, BOOL fCounterSignerChain, uint32 idxCounterSigner);

public function BOOL PFN_PROVUI_CALL(HWND hWndSecurityDialog, CRYPT_PROVIDER_DATA* pProvData);

public function BOOL PFN_ALLOCANDFILLDEFUSAGE(PSTR pszUsageOID, CRYPT_PROVIDER_DEFUSAGE* psDefUsage);

public function BOOL PFN_FREEDEFUSAGE(PSTR pszUsageOID, CRYPT_PROVIDER_DEFUSAGE* psDefUsage);

public function HRESULT PFN_WTD_GENERIC_CHAIN_POLICY_CALLBACK(CRYPT_PROVIDER_DATA* pProvData, uint32 dwStepError, uint32 dwRegPolicySettings, uint32 cSigner, WTD_GENERIC_CHAIN_POLICY_SIGNER_INFO** rgpSigner, void* pvPolicyArg);

#endregion

#region Structs
[CRepr]
public struct WINTRUST_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public WINTRUST_FILE_INFO* pFile;
		public WINTRUST_CATALOG_INFO* pCatalog;
		public WINTRUST_BLOB_INFO* pBlob;
		public WINTRUST_SGNR_INFO* pSgnr;
		public WINTRUST_CERT_INFO* pCert;
	}
	public uint32 cbStruct;
	public void* pPolicyCallbackData;
	public void* pSIPClientData;
	public WINTRUST_DATA_UICHOICE dwUIChoice;
	public WINTRUST_DATA_REVOCATION_CHECKS fdwRevocationChecks;
	public WINTRUST_DATA_UNION_CHOICE dwUnionChoice;
	public using _Anonymous_e__Union Anonymous;
	public WINTRUST_DATA_STATE_ACTION dwStateAction;
	public HANDLE hWVTStateData;
	public PWSTR pwszURLReference;
	public WINTRUST_DATA_PROVIDER_FLAGS dwProvFlags;
	public WINTRUST_DATA_UICONTEXT dwUIContext;
	public WINTRUST_SIGNATURE_SETTINGS* pSignatureSettings;
}

[CRepr]
public struct WINTRUST_SIGNATURE_SETTINGS
{
	public uint32 cbStruct;
	public uint32 dwIndex;
	public WINTRUST_SIGNATURE_SETTINGS_FLAGS dwFlags;
	public uint32 cSecondarySigs;
	public uint32 dwVerifiedSigIndex;
	public CERT_STRONG_SIGN_PARA* pCryptoPolicy;
}

[CRepr]
public struct WINTRUST_FILE_INFO
{
	public uint32 cbStruct;
	public PWSTR pcwszFilePath;
	public HANDLE hFile;
	public Guid* pgKnownSubject;
}

[CRepr]
public struct WINTRUST_CATALOG_INFO
{
	public uint32 cbStruct;
	public uint32 dwCatalogVersion;
	public PWSTR pcwszCatalogFilePath;
	public PWSTR pcwszMemberTag;
	public PWSTR pcwszMemberFilePath;
	public HANDLE hMemberFile;
	public uint8* pbCalculatedFileHash;
	public uint32 cbCalculatedFileHash;
	public CTL_CONTEXT* pcCatalogContext;
	public int hCatAdmin;
}

[CRepr]
public struct WINTRUST_BLOB_INFO
{
	public uint32 cbStruct;
	public Guid gSubject;
	public PWSTR pcwszDisplayName;
	public uint32 cbMemObject;
	public uint8* pbMemObject;
	public uint32 cbMemSignedMsg;
	public uint8* pbMemSignedMsg;
}

[CRepr]
public struct WINTRUST_SGNR_INFO
{
	public uint32 cbStruct;
	public PWSTR pcwszDisplayName;
	public CMSG_SIGNER_INFO* psSignerInfo;
	public uint32 chStores;
	public HCERTSTORE* pahStores;
}

[CRepr]
public struct WINTRUST_CERT_INFO
{
	public uint32 cbStruct;
	public PWSTR pcwszDisplayName;
	public CERT_CONTEXT* psCertContext;
	public uint32 chStores;
	public HCERTSTORE* pahStores;
	public uint32 dwFlags;
	public FILETIME* psftVerifyAsOf;
}

[CRepr]
public struct CRYPT_PROVIDER_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PROVDATA_SIP* pPDSip;
	}
	public uint32 cbStruct;
	public WINTRUST_DATA* pWintrustData;
	public BOOL fOpenedFile;
	public HWND hWndParent;
	public Guid* pgActionID;
	public uint hProv;
	public uint32 dwError;
	public uint32 dwRegSecuritySettings;
	public uint32 dwRegPolicySettings;
	public CRYPT_PROVIDER_FUNCTIONS* psPfns;
	public uint32 cdwTrustStepErrors;
	public uint32* padwTrustStepErrors;
	public uint32 chStores;
	public HCERTSTORE* pahStores;
	public uint32 dwEncoding;
	public void* hMsg;
	public uint32 csSigners;
	public CRYPT_PROVIDER_SGNR* pasSigners;
	public uint32 csProvPrivData;
	public CRYPT_PROVIDER_PRIVDATA* pasProvPrivData;
	public uint32 dwSubjectChoice;
	public using _Anonymous_e__Union Anonymous;
	public PSTR pszUsageOID;
	public BOOL fRecallWithState;
	public FILETIME sftSystemTime;
	public PSTR pszCTLSignerUsageOID;
	public uint32 dwProvFlags;
	public uint32 dwFinalError;
	public CERT_USAGE_MATCH* pRequestUsage;
	public uint32 dwTrustPubSettings;
	public uint32 dwUIStateFlags;
	public CRYPT_PROVIDER_SIGSTATE* pSigState;
	public WINTRUST_SIGNATURE_SETTINGS* pSigSettings;
}

[CRepr]
public struct CRYPT_PROVIDER_SIGSTATE
{
	public uint32 cbStruct;
	public void** rhSecondarySigs;
	public void* hPrimarySig;
	public BOOL fFirstAttemptMade;
	public BOOL fNoMoreSigs;
	public uint32 cSecondarySigs;
	public uint32 dwCurrentIndex;
	public BOOL fSupportMultiSig;
	public uint32 dwCryptoPolicySupport;
	public uint32 iAttemptCount;
	public BOOL fCheckedSealing;
	public SEALING_SIGNATURE_ATTRIBUTE* pSealingSignature;
}

[CRepr]
public struct CRYPT_PROVIDER_FUNCTIONS
{
	public uint32 cbStruct;
	public PFN_CPD_MEM_ALLOC pfnAlloc;
	public PFN_CPD_MEM_FREE pfnFree;
	public PFN_CPD_ADD_STORE pfnAddStore2Chain;
	public PFN_CPD_ADD_SGNR pfnAddSgnr2Chain;
	public PFN_CPD_ADD_CERT pfnAddCert2Chain;
	public PFN_CPD_ADD_PRIVDATA pfnAddPrivData2Chain;
	public PFN_PROVIDER_INIT_CALL pfnInitialize;
	public PFN_PROVIDER_OBJTRUST_CALL pfnObjectTrust;
	public PFN_PROVIDER_SIGTRUST_CALL pfnSignatureTrust;
	public PFN_PROVIDER_CERTTRUST_CALL pfnCertificateTrust;
	public PFN_PROVIDER_FINALPOLICY_CALL pfnFinalPolicy;
	public PFN_PROVIDER_CERTCHKPOLICY_CALL pfnCertCheckPolicy;
	public PFN_PROVIDER_TESTFINALPOLICY_CALL pfnTestFinalPolicy;
	public CRYPT_PROVUI_FUNCS* psUIpfns;
	public PFN_PROVIDER_CLEANUP_CALL pfnCleanupPolicy;
}

[CRepr]
public struct CRYPT_PROVUI_FUNCS
{
	public uint32 cbStruct;
	public CRYPT_PROVUI_DATA* psUIData;
	public PFN_PROVUI_CALL pfnOnMoreInfoClick;
	public PFN_PROVUI_CALL pfnOnMoreInfoClickDefault;
	public PFN_PROVUI_CALL pfnOnAdvancedClick;
	public PFN_PROVUI_CALL pfnOnAdvancedClickDefault;
}

[CRepr]
public struct CRYPT_PROVUI_DATA
{
	public uint32 cbStruct;
	public uint32 dwFinalError;
	public PWSTR pYesButtonText;
	public PWSTR pNoButtonText;
	public PWSTR pMoreInfoButtonText;
	public PWSTR pAdvancedLinkText;
	public PWSTR pCopyActionText;
	public PWSTR pCopyActionTextNoTS;
	public PWSTR pCopyActionTextNotSigned;
}

[CRepr]
public struct CRYPT_PROVIDER_SGNR
{
	public uint32 cbStruct;
	public FILETIME sftVerifyAsOf;
	public uint32 csCertChain;
	public CRYPT_PROVIDER_CERT* pasCertChain;
	public uint32 dwSignerType;
	public CMSG_SIGNER_INFO* psSigner;
	public uint32 dwError;
	public uint32 csCounterSigners;
	public CRYPT_PROVIDER_SGNR* pasCounterSigners;
	public CERT_CHAIN_CONTEXT* pChainContext;
}

[CRepr]
public struct CRYPT_PROVIDER_CERT
{
	public uint32 cbStruct;
	public CERT_CONTEXT* pCert;
	public BOOL fCommercial;
	public BOOL fTrustedRoot;
	public BOOL fSelfSigned;
	public BOOL fTestCert;
	public uint32 dwRevokedReason;
	public uint32 dwConfidence;
	public uint32 dwError;
	public CTL_CONTEXT* pTrustListContext;
	public BOOL fTrustListSignerCert;
	public CTL_CONTEXT* pCtlContext;
	public uint32 dwCtlError;
	public BOOL fIsCyclic;
	public CERT_CHAIN_ELEMENT* pChainElement;
}

[CRepr]
public struct CRYPT_PROVIDER_PRIVDATA
{
	public uint32 cbStruct;
	public Guid gProviderID;
	public uint32 cbProvData;
	public void* pvProvData;
}

[CRepr]
public struct PROVDATA_SIP
{
	public uint32 cbStruct;
	public Guid gSubject;
	public SIP_DISPATCH_INFO* pSip;
	public SIP_DISPATCH_INFO* pCATSip;
	public SIP_SUBJECTINFO* psSipSubjectInfo;
	public SIP_SUBJECTINFO* psSipCATSubjectInfo;
	public SIP_INDIRECT_DATA* psIndirectData;
}

[CRepr]
public struct CRYPT_TRUST_REG_ENTRY
{
	public uint32 cbStruct;
	public PWSTR pwszDLLName;
	public PWSTR pwszFunctionName;
}

[CRepr]
public struct CRYPT_REGISTER_ACTIONID
{
	public uint32 cbStruct;
	public CRYPT_TRUST_REG_ENTRY sInitProvider;
	public CRYPT_TRUST_REG_ENTRY sObjectProvider;
	public CRYPT_TRUST_REG_ENTRY sSignatureProvider;
	public CRYPT_TRUST_REG_ENTRY sCertificateProvider;
	public CRYPT_TRUST_REG_ENTRY sCertificatePolicyProvider;
	public CRYPT_TRUST_REG_ENTRY sFinalPolicyProvider;
	public CRYPT_TRUST_REG_ENTRY sTestPolicyProvider;
	public CRYPT_TRUST_REG_ENTRY sCleanupProvider;
}

[CRepr]
public struct CRYPT_PROVIDER_REGDEFUSAGE
{
	public uint32 cbStruct;
	public Guid* pgActionID;
	public PWSTR pwszDllName;
	public PSTR pwszLoadCallbackDataFunctionName;
	public PSTR pwszFreeCallbackDataFunctionName;
}

[CRepr]
public struct CRYPT_PROVIDER_DEFUSAGE
{
	public uint32 cbStruct;
	public Guid gActionID;
	public void* pDefPolicyCallbackData;
	public void* pDefSIPClientData;
}

[CRepr]
public struct SPC_SERIALIZED_OBJECT
{
	public uint8[16] ClassId;
	public CRYPTOAPI_BLOB SerializedData;
}

[CRepr]
public struct SPC_SIGINFO
{
	public uint32 dwSipVersion;
	public Guid gSIPGuid;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwReserved3;
	public uint32 dwReserved4;
	public uint32 dwReserved5;
}

[CRepr]
public struct SPC_LINK
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PWSTR pwszUrl;
		public SPC_SERIALIZED_OBJECT Moniker;
		public PWSTR pwszFile;
	}
	public uint32 dwLinkChoice;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct SPC_PE_IMAGE_DATA
{
	public CRYPT_BIT_BLOB Flags;
	public SPC_LINK* pFile;
}

[CRepr]
public struct SPC_INDIRECT_DATA_CONTENT
{
	public CRYPT_ATTRIBUTE_TYPE_VALUE Data;
	public CRYPT_ALGORITHM_IDENTIFIER DigestAlgorithm;
	public CRYPTOAPI_BLOB Digest;
}

[CRepr]
public struct SPC_FINANCIAL_CRITERIA
{
	public BOOL fFinancialInfoAvailable;
	public BOOL fMeetsCriteria;
}

[CRepr]
public struct SPC_IMAGE
{
	public SPC_LINK* pImageLink;
	public CRYPTOAPI_BLOB Bitmap;
	public CRYPTOAPI_BLOB Metafile;
	public CRYPTOAPI_BLOB EnhancedMetafile;
	public CRYPTOAPI_BLOB GifFile;
}

[CRepr]
public struct SPC_SP_AGENCY_INFO
{
	public SPC_LINK* pPolicyInformation;
	public PWSTR pwszPolicyDisplayText;
	public SPC_IMAGE* pLogoImage;
	public SPC_LINK* pLogoLink;
}

[CRepr]
public struct SPC_STATEMENT_TYPE
{
	public uint32 cKeyPurposeId;
	public PSTR* rgpszKeyPurposeId;
}

[CRepr]
public struct SPC_SP_OPUS_INFO
{
	public PWSTR pwszProgramName;
	public SPC_LINK* pMoreInfo;
	public SPC_LINK* pPublisherInfo;
}

[CRepr]
public struct CAT_NAMEVALUE
{
	public PWSTR pwszTag;
	public uint32 fdwFlags;
	public CRYPTOAPI_BLOB Value;
}

[CRepr]
public struct CAT_MEMBERINFO
{
	public PWSTR pwszSubjGuid;
	public uint32 dwCertVersion;
}

[CRepr]
public struct CAT_MEMBERINFO2
{
	public Guid SubjectGuid;
	public uint32 dwCertVersion;
}

[CRepr]
public struct INTENT_TO_SEAL_ATTRIBUTE
{
	public uint32 version;
	public BOOLEAN seal;
}

[CRepr]
public struct SEALING_SIGNATURE_ATTRIBUTE
{
	public uint32 version;
	public uint32 signerIndex;
	public CRYPT_ALGORITHM_IDENTIFIER signatureAlgorithm;
	public CRYPTOAPI_BLOB encryptedDigest;
}

[CRepr]
public struct SEALING_TIMESTAMP_ATTRIBUTE
{
	public uint32 version;
	public uint32 signerIndex;
	public CRYPTOAPI_BLOB sealTimeStampToken;
}

[CRepr]
public struct WIN_CERTIFICATE
{
	public uint32 dwLength;
	public uint16 wRevision;
	public uint16 wCertificateType;
	public uint8* bCertificate mut => &bCertificate_impl;
	private uint8[ANYSIZE_ARRAY] bCertificate_impl;
}

[CRepr]
public struct WIN_TRUST_ACTDATA_CONTEXT_WITH_SUBJECT
{
	public HANDLE hClientToken;
	public Guid* SubjectType;
	public void* Subject;
}

[CRepr]
public struct WIN_TRUST_ACTDATA_SUBJECT_ONLY
{
	public Guid* SubjectType;
	public void* Subject;
}

[CRepr]
public struct WIN_TRUST_SUBJECT_FILE
{
	public HANDLE hFile;
	public PWSTR lpPath;
}

[CRepr]
public struct WIN_TRUST_SUBJECT_FILE_AND_DISPLAY
{
	public HANDLE hFile;
	public PWSTR lpPath;
	public PWSTR lpDisplayName;
}

[CRepr]
public struct WIN_SPUB_TRUSTED_PUBLISHER_DATA
{
	public HANDLE hClientToken;
	public WIN_CERTIFICATE* lpCertificate;
}

[CRepr]
public struct WTD_GENERIC_CHAIN_POLICY_SIGNER_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 cbStruct;
		public uint32 cbSize;
	}
	public using _Anonymous_e__Union Anonymous;
	public CERT_CHAIN_CONTEXT* pChainContext;
	public uint32 dwSignerType;
	public CMSG_SIGNER_INFO* pMsgSignerInfo;
	public uint32 dwError;
	public uint32 cCounterSigner;
	public WTD_GENERIC_CHAIN_POLICY_SIGNER_INFO** rgpCounterSigner;
}

[CRepr]
public struct WTD_GENERIC_CHAIN_POLICY_CREATE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 cbStruct;
		public uint32 cbSize;
	}
	public using _Anonymous_e__Union Anonymous;
	public HCERTCHAINENGINE hChainEngine;
	public CERT_CHAIN_PARA* pChainPara;
	public uint32 dwFlags;
	public void* pvReserved;
}

[CRepr]
public struct WTD_GENERIC_CHAIN_POLICY_DATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 cbStruct;
		public uint32 cbSize;
	}
	public using _Anonymous_e__Union Anonymous;
	public WTD_GENERIC_CHAIN_POLICY_CREATE_INFO* pSignerChainInfo;
	public WTD_GENERIC_CHAIN_POLICY_CREATE_INFO* pCounterSignerChainInfo;
	public PFN_WTD_GENERIC_CHAIN_POLICY_CALLBACK pfnPolicyCallback;
	public void* pvPolicyArg;
}

[CRepr]
public struct DRIVER_VER_MAJORMINOR
{
	public uint32 dwMajor;
	public uint32 dwMinor;
}

[CRepr]
public struct DRIVER_VER_INFO
{
	public uint32 cbStruct;
	public uint dwReserved1;
	public uint dwReserved2;
	public uint32 dwPlatform;
	public uint32 dwVersion;
	public char16[260] wszVersion;
	public char16[260] wszSignedBy;
	public CERT_CONTEXT* pcSignerCertContext;
	public DRIVER_VER_MAJORMINOR sOSVersionLow;
	public DRIVER_VER_MAJORMINOR sOSVersionHigh;
	public uint32 dwBuildNumberLow;
	public uint32 dwBuildNumberHigh;
}

[CRepr]
public struct CONFIG_CI_PROV_INFO_RESULT
{
	public HRESULT hr;
	public uint32 dwResult;
	public uint32 dwPolicyIndex;
	public BOOLEAN fIsExplicitDeny;
}

[CRepr]
public struct CONFIG_CI_PROV_INFO
{
	public uint32 cbSize;
	public uint32 dwPolicies;
	public CRYPTOAPI_BLOB* pPolicies;
	public CONFIG_CI_PROV_INFO_RESULT result;
	public uint32 dwScenario;
}

#endregion

#region Functions
public static
{
	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WinVerifyTrust(HWND hwnd, Guid* pgActionID, void* pWVTData);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WinVerifyTrustEx(HWND hwnd, Guid* pgActionID, WINTRUST_DATA* pWinTrustData);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WintrustGetRegPolicyFlags(WINTRUST_POLICY_FLAGS* pdwPolicyFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WintrustSetRegPolicyFlags(WINTRUST_POLICY_FLAGS dwPolicyFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WintrustAddActionID(Guid* pgActionID, uint32 fdwFlags, CRYPT_REGISTER_ACTIONID* psProvInfo);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WintrustRemoveActionID(Guid* pgActionID);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WintrustLoadFunctionPointers(Guid* pgActionID, CRYPT_PROVIDER_FUNCTIONS* pPfns);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WintrustAddDefaultForUsage(PSTR pszUsageOID, CRYPT_PROVIDER_REGDEFUSAGE* psDefUsage);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WintrustGetDefaultForUsage(WINTRUST_GET_DEFAULT_FOR_USAGE_ACTION dwAction, PSTR pszUsageOID, CRYPT_PROVIDER_DEFUSAGE* psUsage);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPT_PROVIDER_SGNR* WTHelperGetProvSignerFromChain(CRYPT_PROVIDER_DATA* pProvData, uint32 idxSigner, BOOL fCounterSigner, uint32 idxCounterSigner);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPT_PROVIDER_CERT* WTHelperGetProvCertFromChain(CRYPT_PROVIDER_SGNR* pSgnr, uint32 idxCert);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPT_PROVIDER_DATA* WTHelperProvDataFromStateData(HANDLE hStateData);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPT_PROVIDER_PRIVDATA* WTHelperGetProvPrivateDataFromChain(CRYPT_PROVIDER_DATA* pProvData, Guid* pgProviderID);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WTHelperCertIsSelfSigned(uint32 dwEncoding, CERT_INFO* pCert);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WTHelperCertCheckValidSignature(CRYPT_PROVIDER_DATA* pProvData);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OpenPersonalTrustDBDialogEx(HWND hwndParent, uint32 dwFlags, void** pvReserved);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OpenPersonalTrustDBDialog(HWND hwndParent);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WintrustSetDefaultIncludePEPageHashes(BOOL fIncludePEPageHashes);

}
#endregion
