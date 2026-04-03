using Win32.System.WinRT;
using Win32.Foundation;
using Win32.System.Com;
using Win32.Storage.Packaging.Appx;
using System;

namespace Win32.Security.EnterpriseData;

#region Enums

[AllowDuplicates]
public enum ENTERPRISE_DATA_POLICIES : uint32
{
	ENTERPRISE_POLICY_NONE = 0,
	ENTERPRISE_POLICY_ALLOWED = 1,
	ENTERPRISE_POLICY_ENLIGHTENED = 2,
	ENTERPRISE_POLICY_EXEMPT = 4,
}


[AllowDuplicates]
public enum SRPHOSTING_TYPE : int32
{
	SRPHOSTING_TYPE_NONE = 0,
	SRPHOSTING_TYPE_WINHTTP = 1,
	SRPHOSTING_TYPE_WININET = 2,
}


[AllowDuplicates]
public enum SRPHOSTING_VERSION : int32
{
	SRPHOSTING_VERSION1 = 1,
}

#endregion


#region Structs
[CRepr]
public struct HTHREAD_NETWORK_CONTEXT
{
	public uint32 ThreadId;
	public HANDLE ThreadContext;
}

[CRepr]
public struct FILE_UNPROTECT_OPTIONS
{
	public uint8 audit;
}

#endregion

#region COM Types
[CRepr]struct IProtectionPolicyManagerInterop : IInspectable
{
	public new const Guid IID = .(0x4652651d, 0xc1fe, 0x4ba1, 0x9f, 0x0a, 0xc0, 0xf5, 0x65, 0x96, 0xf7, 0x21);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, HSTRING sourceIdentity, HSTRING targetIdentity, in Guid riid, void** asyncOperation) RequestAccessForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** result) GetForWindow;
	}


	public HRESULT RequestAccessForWindowAsync(HWND appWindow, HSTRING sourceIdentity, HSTRING targetIdentity, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessForWindowAsync(&this, appWindow, sourceIdentity, targetIdentity, riid, asyncOperation);

	public HRESULT GetForWindow(HWND appWindow, in Guid riid, void** result) mut => VT.[Friend]GetForWindow(&this, appWindow, riid, result);
}

[CRepr]struct IProtectionPolicyManagerInterop2 : IInspectable
{
	public new const Guid IID = .(0x157cfbe4, 0xa78d, 0x4156, 0xb3, 0x84, 0x61, 0xfd, 0xac, 0x41, 0xe6, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, HSTRING sourceIdentity, HSTRING appPackageFamilyName, in Guid riid, void** asyncOperation) RequestAccessForAppWithWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, HSTRING sourceIdentity, HSTRING targetIdentity, IUnknown* auditInfoUnk, in Guid riid, void** asyncOperation) RequestAccessWithAuditingInfoForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, HSTRING sourceIdentity, HSTRING targetIdentity, IUnknown* auditInfoUnk, HSTRING messageFromApp, in Guid riid, void** asyncOperation) RequestAccessWithMessageForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, HSTRING sourceIdentity, HSTRING appPackageFamilyName, IUnknown* auditInfoUnk, in Guid riid, void** asyncOperation) RequestAccessForAppWithAuditingInfoForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, HSTRING sourceIdentity, HSTRING appPackageFamilyName, IUnknown* auditInfoUnk, HSTRING messageFromApp, in Guid riid, void** asyncOperation) RequestAccessForAppWithMessageForWindowAsync;
	}


	public HRESULT RequestAccessForAppWithWindowAsync(HWND appWindow, HSTRING sourceIdentity, HSTRING appPackageFamilyName, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessForAppWithWindowAsync(&this, appWindow, sourceIdentity, appPackageFamilyName, riid, asyncOperation);

	public HRESULT RequestAccessWithAuditingInfoForWindowAsync(HWND appWindow, HSTRING sourceIdentity, HSTRING targetIdentity, IUnknown* auditInfoUnk, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessWithAuditingInfoForWindowAsync(&this, appWindow, sourceIdentity, targetIdentity, auditInfoUnk, riid, asyncOperation);

	public HRESULT RequestAccessWithMessageForWindowAsync(HWND appWindow, HSTRING sourceIdentity, HSTRING targetIdentity, IUnknown* auditInfoUnk, HSTRING messageFromApp, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessWithMessageForWindowAsync(&this, appWindow, sourceIdentity, targetIdentity, auditInfoUnk, messageFromApp, riid, asyncOperation);

	public HRESULT RequestAccessForAppWithAuditingInfoForWindowAsync(HWND appWindow, HSTRING sourceIdentity, HSTRING appPackageFamilyName, IUnknown* auditInfoUnk, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessForAppWithAuditingInfoForWindowAsync(&this, appWindow, sourceIdentity, appPackageFamilyName, auditInfoUnk, riid, asyncOperation);

	public HRESULT RequestAccessForAppWithMessageForWindowAsync(HWND appWindow, HSTRING sourceIdentity, HSTRING appPackageFamilyName, IUnknown* auditInfoUnk, HSTRING messageFromApp, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessForAppWithMessageForWindowAsync(&this, appWindow, sourceIdentity, appPackageFamilyName, auditInfoUnk, messageFromApp, riid, asyncOperation);
}

[CRepr]struct IProtectionPolicyManagerInterop3 : IInspectable
{
	public new const Guid IID = .(0xc1c03933, 0xb398, 0x4d93, 0xb0, 0xfd, 0x29, 0x72, 0xad, 0xf8, 0x02, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, HSTRING sourceIdentity, HSTRING targetIdentity, IUnknown* auditInfoUnk, HSTRING messageFromApp, uint32 behavior, in Guid riid, void** asyncOperation) RequestAccessWithBehaviorForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, HSTRING sourceIdentity, HSTRING appPackageFamilyName, IUnknown* auditInfoUnk, HSTRING messageFromApp, uint32 behavior, in Guid riid, void** asyncOperation) RequestAccessForAppWithBehaviorForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, IUnknown* sourceItemListUnk, HSTRING appPackageFamilyName, IUnknown* auditInfoUnk, in Guid riid, void** asyncOperation) RequestAccessToFilesForAppForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, IUnknown* sourceItemListUnk, HSTRING appPackageFamilyName, IUnknown* auditInfoUnk, HSTRING messageFromApp, uint32 behavior, in Guid riid, void** asyncOperation) RequestAccessToFilesForAppWithMessageAndBehaviorForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, IUnknown* sourceItemListUnk, uint32 processId, IUnknown* auditInfoUnk, in Guid riid, void** asyncOperation) RequestAccessToFilesForProcessForWindowAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, IUnknown* sourceItemListUnk, uint32 processId, IUnknown* auditInfoUnk, HSTRING messageFromApp, uint32 behavior, in Guid riid, void** asyncOperation) RequestAccessToFilesForProcessWithMessageAndBehaviorForWindowAsync;
	}


	public HRESULT RequestAccessWithBehaviorForWindowAsync(HWND appWindow, HSTRING sourceIdentity, HSTRING targetIdentity, IUnknown* auditInfoUnk, HSTRING messageFromApp, uint32 behavior, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessWithBehaviorForWindowAsync(&this, appWindow, sourceIdentity, targetIdentity, auditInfoUnk, messageFromApp, behavior, riid, asyncOperation);

	public HRESULT RequestAccessForAppWithBehaviorForWindowAsync(HWND appWindow, HSTRING sourceIdentity, HSTRING appPackageFamilyName, IUnknown* auditInfoUnk, HSTRING messageFromApp, uint32 behavior, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessForAppWithBehaviorForWindowAsync(&this, appWindow, sourceIdentity, appPackageFamilyName, auditInfoUnk, messageFromApp, behavior, riid, asyncOperation);

	public HRESULT RequestAccessToFilesForAppForWindowAsync(HWND appWindow, IUnknown* sourceItemListUnk, HSTRING appPackageFamilyName, IUnknown* auditInfoUnk, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessToFilesForAppForWindowAsync(&this, appWindow, sourceItemListUnk, appPackageFamilyName, auditInfoUnk, riid, asyncOperation);

	public HRESULT RequestAccessToFilesForAppWithMessageAndBehaviorForWindowAsync(HWND appWindow, IUnknown* sourceItemListUnk, HSTRING appPackageFamilyName, IUnknown* auditInfoUnk, HSTRING messageFromApp, uint32 behavior, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessToFilesForAppWithMessageAndBehaviorForWindowAsync(&this, appWindow, sourceItemListUnk, appPackageFamilyName, auditInfoUnk, messageFromApp, behavior, riid, asyncOperation);

	public HRESULT RequestAccessToFilesForProcessForWindowAsync(HWND appWindow, IUnknown* sourceItemListUnk, uint32 processId, IUnknown* auditInfoUnk, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessToFilesForProcessForWindowAsync(&this, appWindow, sourceItemListUnk, processId, auditInfoUnk, riid, asyncOperation);

	public HRESULT RequestAccessToFilesForProcessWithMessageAndBehaviorForWindowAsync(HWND appWindow, IUnknown* sourceItemListUnk, uint32 processId, IUnknown* auditInfoUnk, HSTRING messageFromApp, uint32 behavior, in Guid riid, void** asyncOperation) mut => VT.[Friend]RequestAccessToFilesForProcessWithMessageAndBehaviorForWindowAsync(&this, appWindow, sourceItemListUnk, processId, auditInfoUnk, messageFromApp, behavior, riid, asyncOperation);
}

#endregion

#region Functions
public static
{
	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SrpCreateThreadNetworkContext(PWSTR enterpriseId, HTHREAD_NETWORK_CONTEXT* threadNetworkContext);

	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SrpCloseThreadNetworkContext(HTHREAD_NETWORK_CONTEXT* threadNetworkContext);

	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SrpSetTokenEnterpriseId(HANDLE tokenHandle, PWSTR enterpriseId);

	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SrpGetEnterpriseIds(HANDLE tokenHandle, uint32* numberOfBytes, PWSTR* enterpriseIds, uint32* enterpriseIdCount);

	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SrpEnablePermissiveModeFileEncryption(PWSTR enterpriseId);

	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SrpDisablePermissiveModeFileEncryption();

	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SrpGetEnterprisePolicy(HANDLE tokenHandle, ENTERPRISE_DATA_POLICIES* policyFlags);

	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS SrpIsTokenService(HANDLE TokenHandle, uint8* IsTokenService);

	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SrpDoesPolicyAllowAppExecution(PACKAGE_ID* packageId, BOOL* isAllowed);

	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SrpHostingInitialize(SRPHOSTING_VERSION Version, SRPHOSTING_TYPE Type, void* pvData, uint32 cbData);

	[Import("srpapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SrpHostingTerminate(SRPHOSTING_TYPE Type);

	[Import("efswrt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ProtectFileToEnterpriseIdentity(PWSTR fileOrFolderPath, PWSTR identity);

	[Import("efswrt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UnprotectFile(PWSTR fileOrFolderPath, FILE_UNPROTECT_OPTIONS* options);

}
#endregion
