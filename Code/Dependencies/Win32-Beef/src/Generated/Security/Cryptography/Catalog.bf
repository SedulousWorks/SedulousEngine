using Win32.Foundation;
using Win32.Security.Cryptography.Sip;
using Win32.Security.Cryptography;
using System;

namespace Win32.Security.Cryptography.Catalog;

#region Constants
public static
{
	public const String szOID_CATALOG_LIST = "1.3.6.1.4.1.311.12.1.1";
	public const String szOID_CATALOG_LIST_MEMBER = "1.3.6.1.4.1.311.12.1.2";
	public const String szOID_CATALOG_LIST_MEMBER2 = "1.3.6.1.4.1.311.12.1.3";
	public const String CRYPTCAT_FILEEXT = "CAT";
	public const uint32 CRYPTCAT_MAX_MEMBERTAG = 64;
	public const uint32 CRYPTCAT_MEMBER_SORTED = 1073741824;
	public const uint32 CRYPTCAT_ATTR_AUTHENTICATED = 268435456;
	public const uint32 CRYPTCAT_ATTR_UNAUTHENTICATED = 536870912;
	public const uint32 CRYPTCAT_ATTR_NAMEASCII = 1;
	public const uint32 CRYPTCAT_ATTR_NAMEOBJID = 2;
	public const uint32 CRYPTCAT_ATTR_DATAASCII = 65536;
	public const uint32 CRYPTCAT_ATTR_DATABASE64 = 131072;
	public const uint32 CRYPTCAT_ATTR_DATAREPLACE = 262144;
	public const uint32 CRYPTCAT_ATTR_NO_AUTO_COMPAT_ENTRY = 16777216;
	public const uint32 CRYPTCAT_E_AREA_HEADER = 0;
	public const uint32 CRYPTCAT_E_AREA_MEMBER = 65536;
	public const uint32 CRYPTCAT_E_AREA_ATTRIBUTE = 131072;
	public const uint32 CRYPTCAT_E_CDF_UNSUPPORTED = 1;
	public const uint32 CRYPTCAT_E_CDF_DUPLICATE = 2;
	public const uint32 CRYPTCAT_E_CDF_TAGNOTFOUND = 4;
	public const uint32 CRYPTCAT_E_CDF_MEMBER_FILE_PATH = 65537;
	public const uint32 CRYPTCAT_E_CDF_MEMBER_INDIRECTDATA = 65538;
	public const uint32 CRYPTCAT_E_CDF_MEMBER_FILENOTFOUND = 65540;
	public const uint32 CRYPTCAT_E_CDF_BAD_GUID_CONV = 131073;
	public const uint32 CRYPTCAT_E_CDF_ATTR_TOOFEWVALUES = 131074;
	public const uint32 CRYPTCAT_E_CDF_ATTR_TYPECOMBO = 131076;
	public const uint32 CRYPTCAT_ADDCATALOG_NONE = 0;
	public const uint32 CRYPTCAT_ADDCATALOG_HARDLINK = 1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum CRYPTCAT_VERSION : uint32
{
	CRYPTCAT_VERSION_1 = 256,
	CRYPTCAT_VERSION_2 = 512,
}


[AllowDuplicates]
public enum CRYPTCAT_OPEN_FLAGS : uint32
{
	CRYPTCAT_OPEN_ALWAYS = 2,
	CRYPTCAT_OPEN_CREATENEW = 1,
	CRYPTCAT_OPEN_EXISTING = 4,
	CRYPTCAT_OPEN_EXCLUDE_PAGE_HASHES = 65536,
	CRYPTCAT_OPEN_INCLUDE_PAGE_HASHES = 131072,
	CRYPTCAT_OPEN_VERIFYSIGHASH = 268435456,
	CRYPTCAT_OPEN_NO_CONTENT_HCRYPTMSG = 536870912,
	CRYPTCAT_OPEN_SORTED = 1073741824,
	CRYPTCAT_OPEN_FLAGS_MASK = 4294901760,
}

#endregion

#region Function Pointers
public function void PFN_CDF_PARSE_ERROR_CALLBACK(uint32 dwErrorArea, uint32 dwLocalError, PWSTR pwszLine);

#endregion

#region Structs
[CRepr]
public struct CRYPTCATSTORE
{
	public uint32 cbStruct;
	public uint32 dwPublicVersion;
	public PWSTR pwszP7File;
	public uint hProv;
	public uint32 dwEncodingType;
	public CRYPTCAT_OPEN_FLAGS fdwStoreFlags;
	public HANDLE hReserved;
	public HANDLE hAttrs;
	public void* hCryptMsg;
	public HANDLE hSorted;
}

[CRepr]
public struct CRYPTCATMEMBER
{
	public uint32 cbStruct;
	public PWSTR pwszReferenceTag;
	public PWSTR pwszFileName;
	public Guid gSubjectType;
	public uint32 fdwMemberFlags;
	public SIP_INDIRECT_DATA* pIndirectData;
	public uint32 dwCertVersion;
	public uint32 dwReserved;
	public HANDLE hReserved;
	public CRYPTOAPI_BLOB sEncodedIndirectData;
	public CRYPTOAPI_BLOB sEncodedMemberInfo;
}

[CRepr]
public struct CRYPTCATATTRIBUTE
{
	public uint32 cbStruct;
	public PWSTR pwszReferenceTag;
	public uint32 dwAttrTypeAndAction;
	public uint32 cbValue;
	public uint8* pbValue;
	public uint32 dwReserved;
}

[CRepr]
public struct CRYPTCATCDF
{
	public uint32 cbStruct;
	public HANDLE hFile;
	public uint32 dwCurFilePos;
	public uint32 dwLastMemberOffset;
	public BOOL fEOF;
	public PWSTR pwszResultDir;
	public HANDLE hCATStore;
}

[CRepr]
public struct CATALOG_INFO
{
	public uint32 cbStruct;
	public char16[260] wszCatalogFile;
}

[CRepr]
public struct MS_ADDINFO_CATALOGMEMBER
{
	public uint32 cbStruct;
	public CRYPTCATSTORE* pStore;
	public CRYPTCATMEMBER* pMember;
}

#endregion

#region Functions
public static
{
	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CryptCATOpen(PWSTR pwszFileName, CRYPTCAT_OPEN_FLAGS fdwOpenFlags, uint hProv, CRYPTCAT_VERSION dwPublicVersion, uint32 dwEncodingType);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATClose(HANDLE hCatalog);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATSTORE* CryptCATStoreFromHandle(HANDLE hCatalog);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CryptCATHandleFromStore(CRYPTCATSTORE* pCatStore);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATPersistStore(HANDLE hCatalog);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATATTRIBUTE* CryptCATGetCatAttrInfo(HANDLE hCatalog, PWSTR pwszReferenceTag);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATATTRIBUTE* CryptCATPutCatAttrInfo(HANDLE hCatalog, PWSTR pwszReferenceTag, uint32 dwAttrTypeAndAction, uint32 cbData, uint8* pbData);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATATTRIBUTE* CryptCATEnumerateCatAttr(HANDLE hCatalog, CRYPTCATATTRIBUTE* pPrevAttr);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATMEMBER* CryptCATGetMemberInfo(HANDLE hCatalog, PWSTR pwszReferenceTag);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATMEMBER* CryptCATAllocSortedMemberInfo(HANDLE hCatalog, PWSTR pwszReferenceTag);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CryptCATFreeSortedMemberInfo(HANDLE hCatalog, CRYPTCATMEMBER* pCatMember);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATATTRIBUTE* CryptCATGetAttrInfo(HANDLE hCatalog, CRYPTCATMEMBER* pCatMember, PWSTR pwszReferenceTag);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATMEMBER* CryptCATPutMemberInfo(HANDLE hCatalog, PWSTR pwszFileName, PWSTR pwszReferenceTag, Guid* pgSubjectType, uint32 dwCertVersion, uint32 cbSIPIndirectData, uint8* pbSIPIndirectData);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATATTRIBUTE* CryptCATPutAttrInfo(HANDLE hCatalog, CRYPTCATMEMBER* pCatMember, PWSTR pwszReferenceTag, uint32 dwAttrTypeAndAction, uint32 cbData, uint8* pbData);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATMEMBER* CryptCATEnumerateMember(HANDLE hCatalog, CRYPTCATMEMBER* pPrevMember);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATATTRIBUTE* CryptCATEnumerateAttr(HANDLE hCatalog, CRYPTCATMEMBER* pCatMember, CRYPTCATATTRIBUTE* pPrevAttr);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATCDF* CryptCATCDFOpen(PWSTR pwszFilePath, PFN_CDF_PARSE_ERROR_CALLBACK pfnParseError);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATCDFClose(CRYPTCATCDF* pCDF);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATATTRIBUTE* CryptCATCDFEnumCatAttributes(CRYPTCATCDF* pCDF, CRYPTCATATTRIBUTE* pPrevAttr, PFN_CDF_PARSE_ERROR_CALLBACK pfnParseError);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATMEMBER* CryptCATCDFEnumMembers(CRYPTCATCDF* pCDF, CRYPTCATMEMBER* pPrevMember, PFN_CDF_PARSE_ERROR_CALLBACK pfnParseError);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CRYPTCATATTRIBUTE* CryptCATCDFEnumAttributes(CRYPTCATCDF* pCDF, CRYPTCATMEMBER* pMember, CRYPTCATATTRIBUTE* pPrevAttr, PFN_CDF_PARSE_ERROR_CALLBACK pfnParseError);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsCatalogFile(HANDLE hFile, PWSTR pwszFileName);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATAdminAcquireContext(int* phCatAdmin, Guid* pgSubsystem, uint32 dwFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATAdminAcquireContext2(int* phCatAdmin, Guid* pgSubsystem, PWSTR pwszHashAlgorithm, CERT_STRONG_SIGN_PARA* pStrongHashPolicy, uint32 dwFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATAdminReleaseContext(int hCatAdmin, uint32 dwFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATAdminReleaseCatalogContext(int hCatAdmin, int hCatInfo, uint32 dwFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CryptCATAdminEnumCatalogFromHash(int hCatAdmin, uint8* pbHash, uint32 cbHash, uint32 dwFlags, int* phPrevCatInfo);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATAdminCalcHashFromFileHandle(HANDLE hFile, uint32* pcbHash, uint8* pbHash, uint32 dwFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATAdminCalcHashFromFileHandle2(int hCatAdmin, HANDLE hFile, uint32* pcbHash, uint8* pbHash, uint32 dwFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CryptCATAdminAddCatalog(int hCatAdmin, PWSTR pwszCatalogFile, PWSTR pwszSelectBaseName, uint32 dwFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATAdminRemoveCatalog(int hCatAdmin, PWSTR pwszCatalogFile, uint32 dwFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATCatalogInfoFromContext(int hCatInfo, CATALOG_INFO* psCatInfo, uint32 dwFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATAdminResolveCatalogPath(int hCatAdmin, PWSTR pwszCatalogFile, CATALOG_INFO* psCatInfo, uint32 dwFlags);

	[Import("WINTRUST.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CryptCATAdminPauseServiceForBackup(uint32 dwFlags, BOOL fResume);

}
#endregion
