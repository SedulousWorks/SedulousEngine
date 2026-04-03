using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.System.TransactionServer;

#region Enums

[AllowDuplicates]
public enum MTSPackageInstallOptions : int32
{
	mtsInstallUsers = 1,
}


[AllowDuplicates]
public enum MTSPackageExportOptions : int32
{
	mtsExportUsers = 1,
}


[AllowDuplicates]
public enum MTSAdminErrorCodes : int32
{
	mtsErrObjectErrors = -2146368511,
	mtsErrObjectInvalid = -2146368510,
	mtsErrKeyMissing = -2146368509,
	mtsErrAlreadyInstalled = -2146368508,
	mtsErrDownloadFailed = -2146368507,
	mtsErrPDFWriteFail = -2146368505,
	mtsErrPDFReadFail = -2146368504,
	mtsErrPDFVersion = -2146368503,
	mtsErrCoReqCompInstalled = -2146368496,
	mtsErrBadPath = -2146368502,
	mtsErrPackageExists = -2146368501,
	mtsErrRoleExists = -2146368500,
	mtsErrCantCopyFile = -2146368499,
	mtsErrNoTypeLib = -2146368498,
	mtsErrNoUser = -2146368497,
	mtsErrInvalidUserids = -2146368496,
	mtsErrNoRegistryCLSID = -2146368495,
	mtsErrBadRegistryProgID = -2146368494,
	mtsErrAuthenticationLevel = -2146368493,
	mtsErrUserPasswdNotValid = -2146368492,
	mtsErrNoRegistryRead = -2146368491,
	mtsErrNoRegistryWrite = -2146368490,
	mtsErrNoRegistryRepair = -2146368489,
	mtsErrCLSIDOrIIDMismatch = -2146368488,
	mtsErrRemoteInterface = -2146368487,
	mtsErrDllRegisterServer = -2146368486,
	mtsErrNoServerShare = -2146368485,
	mtsErrNoAccessToUNC = -2146368484,
	mtsErrDllLoadFailed = -2146368483,
	mtsErrBadRegistryLibID = -2146368482,
	mtsErrPackDirNotFound = -2146368481,
	mtsErrTreatAs = -2146368480,
	mtsErrBadForward = -2146368479,
	mtsErrBadIID = -2146368478,
	mtsErrRegistrarFailed = -2146368477,
	mtsErrCompFileDoesNotExist = -2146368476,
	mtsErrCompFileLoadDLLFail = -2146368475,
	mtsErrCompFileGetClassObj = -2146368474,
	mtsErrCompFileClassNotAvail = -2146368473,
	mtsErrCompFileBadTLB = -2146368472,
	mtsErrCompFileNotInstallable = -2146368471,
	mtsErrNotChangeable = -2146368470,
	mtsErrNotDeletable = -2146368469,
	mtsErrSession = -2146368468,
	mtsErrCompFileNoRegistrar = -2146368460,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_Catalog = .(0x6eb22881, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);


	public const Guid CLSID_CatalogObject = .(0x6eb22882, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);


	public const Guid CLSID_CatalogCollection = .(0x6eb22883, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);


	public const Guid CLSID_ComponentUtil = .(0x6eb22884, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);


	public const Guid CLSID_PackageUtil = .(0x6eb22885, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);


	public const Guid CLSID_RemoteComponentUtil = .(0x6eb22886, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);


	public const Guid CLSID_RoleAssociationUtil = .(0x6eb22887, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);


}
#endregion

#region COM Types
[CRepr]struct ICatalog : IDispatch
{
	public new const Guid IID = .(0x6eb22870, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCollName, IDispatch** ppCatalogCollection) GetCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrConnectString, IDispatch** ppCatalogCollection) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MajorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* retval) get_MinorVersion;
	}


	public HRESULT GetCollection(BSTR bstrCollName, IDispatch** ppCatalogCollection) mut => VT.[Friend]GetCollection(&this, bstrCollName, ppCatalogCollection);

	public HRESULT Connect(BSTR bstrConnectString, IDispatch** ppCatalogCollection) mut => VT.[Friend]Connect(&this, bstrConnectString, ppCatalogCollection);

	public HRESULT get_MajorVersion(int32* retval) mut => VT.[Friend]get_MajorVersion(&this, retval);

	public HRESULT get_MinorVersion(int32* retval) mut => VT.[Friend]get_MinorVersion(&this, retval);
}

[CRepr]struct IComponentUtil : IDispatch
{
	public new const Guid IID = .(0x6eb22873, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDLLFile, BSTR bstrTypelibFile, BSTR bstrProxyStubDLLFile) InstallComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCLSID) ImportComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProgID) ImportComponentByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDLLFile, BSTR bstrTypelibFile, SAFEARRAY** aCLSIDs) GetCLSIDs;
	}


	public HRESULT InstallComponent(BSTR bstrDLLFile, BSTR bstrTypelibFile, BSTR bstrProxyStubDLLFile) mut => VT.[Friend]InstallComponent(&this, bstrDLLFile, bstrTypelibFile, bstrProxyStubDLLFile);

	public HRESULT ImportComponent(BSTR bstrCLSID) mut => VT.[Friend]ImportComponent(&this, bstrCLSID);

	public HRESULT ImportComponentByName(BSTR bstrProgID) mut => VT.[Friend]ImportComponentByName(&this, bstrProgID);

	public HRESULT GetCLSIDs(BSTR bstrDLLFile, BSTR bstrTypelibFile, SAFEARRAY** aCLSIDs) mut => VT.[Friend]GetCLSIDs(&this, bstrDLLFile, bstrTypelibFile, aCLSIDs);
}

[CRepr]struct IPackageUtil : IDispatch
{
	public new const Guid IID = .(0x6eb22874, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPackageFile, BSTR bstrInstallPath, int32 lOptions) InstallPackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPackageID, BSTR bstrPackageFile, int32 lOptions) ExportPackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPackageID) ShutdownPackage;
	}


	public HRESULT InstallPackage(BSTR bstrPackageFile, BSTR bstrInstallPath, int32 lOptions) mut => VT.[Friend]InstallPackage(&this, bstrPackageFile, bstrInstallPath, lOptions);

	public HRESULT ExportPackage(BSTR bstrPackageID, BSTR bstrPackageFile, int32 lOptions) mut => VT.[Friend]ExportPackage(&this, bstrPackageID, bstrPackageFile, lOptions);

	public HRESULT ShutdownPackage(BSTR bstrPackageID) mut => VT.[Friend]ShutdownPackage(&this, bstrPackageID);
}

[CRepr]struct IRemoteComponentUtil : IDispatch
{
	public new const Guid IID = .(0x6eb22875, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServer, BSTR bstrPackageID, BSTR bstrCLSID) InstallRemoteComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServer, BSTR bstrPackageName, BSTR bstrProgID) InstallRemoteComponentByName;
	}


	public HRESULT InstallRemoteComponent(BSTR bstrServer, BSTR bstrPackageID, BSTR bstrCLSID) mut => VT.[Friend]InstallRemoteComponent(&this, bstrServer, bstrPackageID, bstrCLSID);

	public HRESULT InstallRemoteComponentByName(BSTR bstrServer, BSTR bstrPackageName, BSTR bstrProgID) mut => VT.[Friend]InstallRemoteComponentByName(&this, bstrServer, bstrPackageName, bstrProgID);
}

[CRepr]struct IRoleAssociationUtil : IDispatch
{
	public new const Guid IID = .(0x6eb22876, 0x8a19, 0x11d0, 0x81, 0xb6, 0x00, 0xa0, 0xc9, 0x23, 0x1c, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleID) AssociateRole;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRoleName) AssociateRoleByName;
	}


	public HRESULT AssociateRole(BSTR bstrRoleID) mut => VT.[Friend]AssociateRole(&this, bstrRoleID);

	public HRESULT AssociateRoleByName(BSTR bstrRoleName) mut => VT.[Friend]AssociateRoleByName(&this, bstrRoleName);
}

#endregion
