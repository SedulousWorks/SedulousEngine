using Win32.System.Com;
using Win32.Foundation;
using Win32.System.Threading;
using System;

namespace Win32.System.SecurityCenter;

#region Enums

[AllowDuplicates]
public enum WSC_SECURITY_PRODUCT_SUBSTATUS : int32
{
	WSC_SECURITY_PRODUCT_SUBSTATUS_NOT_SET = 0,
	WSC_SECURITY_PRODUCT_SUBSTATUS_NO_ACTION = 1,
	WSC_SECURITY_PRODUCT_SUBSTATUS_ACTION_RECOMMENDED = 2,
	WSC_SECURITY_PRODUCT_SUBSTATUS_ACTION_NEEDED = 3,
}


[AllowDuplicates]
public enum WSC_SECURITY_PRODUCT_STATE : int32
{
	WSC_SECURITY_PRODUCT_STATE_ON = 0,
	WSC_SECURITY_PRODUCT_STATE_OFF = 1,
	WSC_SECURITY_PRODUCT_STATE_SNOOZED = 2,
	WSC_SECURITY_PRODUCT_STATE_EXPIRED = 3,
}


[AllowDuplicates]
public enum SECURITY_PRODUCT_TYPE : int32
{
	SECURITY_PRODUCT_TYPE_ANTIVIRUS = 0,
	SECURITY_PRODUCT_TYPE_FIREWALL = 1,
	SECURITY_PRODUCT_TYPE_ANTISPYWARE = 2,
}


[AllowDuplicates]
public enum WSC_SECURITY_SIGNATURE_STATUS : int32
{
	WSC_SECURITY_PRODUCT_OUT_OF_DATE = 0,
	WSC_SECURITY_PRODUCT_UP_TO_DATE = 1,
}


[AllowDuplicates]
public enum WSC_SECURITY_PROVIDER : int32
{
	WSC_SECURITY_PROVIDER_FIREWALL = 1,
	WSC_SECURITY_PROVIDER_AUTOUPDATE_SETTINGS = 2,
	WSC_SECURITY_PROVIDER_ANTIVIRUS = 4,
	WSC_SECURITY_PROVIDER_ANTISPYWARE = 8,
	WSC_SECURITY_PROVIDER_INTERNET_SETTINGS = 16,
	WSC_SECURITY_PROVIDER_USER_ACCOUNT_CONTROL = 32,
	WSC_SECURITY_PROVIDER_SERVICE = 64,
	WSC_SECURITY_PROVIDER_NONE = 0,
	WSC_SECURITY_PROVIDER_ALL = 127,
}


[AllowDuplicates]
public enum WSC_SECURITY_PROVIDER_HEALTH : int32
{
	WSC_SECURITY_PROVIDER_HEALTH_GOOD = 0,
	WSC_SECURITY_PROVIDER_HEALTH_NOTMONITORED = 1,
	WSC_SECURITY_PROVIDER_HEALTH_POOR = 2,
	WSC_SECURITY_PROVIDER_HEALTH_SNOOZE = 3,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_WSCProductList = .(0x17072f7b, 0x9abe, 0x4a74, 0xa2, 0x61, 0x1e, 0xb7, 0x6b, 0x55, 0x10, 0x7a);


	public const Guid CLSID_WSCDefaultProduct = .(0x2981a36e, 0xf22d, 0x11e5, 0x9c, 0xe9, 0x5e, 0x55, 0x17, 0x50, 0x7c, 0x66);


}
#endregion

#region COM Types
[CRepr]struct IWscProduct : IDispatch
{
	public new const Guid IID = .(0x8c38232e, 0x3a45, 0x4a27, 0x92, 0xb0, 0x1a, 0x16, 0xa9, 0x75, 0xf6, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ProductName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSC_SECURITY_PRODUCT_STATE* pVal) get_ProductState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSC_SECURITY_SIGNATURE_STATUS* pVal) get_SignatureStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_RemediationPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ProductStateTimestamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ProductGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pVal) get_ProductIsDefault;
	}


	public HRESULT get_ProductName(BSTR* pVal) mut => VT.[Friend]get_ProductName(&this, pVal);

	public HRESULT get_ProductState(WSC_SECURITY_PRODUCT_STATE* pVal) mut => VT.[Friend]get_ProductState(&this, pVal);

	public HRESULT get_SignatureStatus(WSC_SECURITY_SIGNATURE_STATUS* pVal) mut => VT.[Friend]get_SignatureStatus(&this, pVal);

	public HRESULT get_RemediationPath(BSTR* pVal) mut => VT.[Friend]get_RemediationPath(&this, pVal);

	public HRESULT get_ProductStateTimestamp(BSTR* pVal) mut => VT.[Friend]get_ProductStateTimestamp(&this, pVal);

	public HRESULT get_ProductGuid(BSTR* pVal) mut => VT.[Friend]get_ProductGuid(&this, pVal);

	public HRESULT get_ProductIsDefault(BOOL* pVal) mut => VT.[Friend]get_ProductIsDefault(&this, pVal);
}

[CRepr]struct IWscProduct2 : IWscProduct
{
	public new const Guid IID = .(0xf896ca54, 0xfe09, 0x4403, 0x86, 0xd4, 0x23, 0xcb, 0x48, 0x8d, 0x81, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWscProduct.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) get_AntivirusScanSubstatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) get_AntivirusSettingsSubstatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) get_AntivirusProtectionUpdateSubstatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) get_FirewallDomainProfileSubstatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) get_FirewallPrivateProfileSubstatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) get_FirewallPublicProfileSubstatus;
	}


	public HRESULT get_AntivirusScanSubstatus(WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) mut => VT.[Friend]get_AntivirusScanSubstatus(&this, peStatus);

	public HRESULT get_AntivirusSettingsSubstatus(WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) mut => VT.[Friend]get_AntivirusSettingsSubstatus(&this, peStatus);

	public HRESULT get_AntivirusProtectionUpdateSubstatus(WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) mut => VT.[Friend]get_AntivirusProtectionUpdateSubstatus(&this, peStatus);

	public HRESULT get_FirewallDomainProfileSubstatus(WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) mut => VT.[Friend]get_FirewallDomainProfileSubstatus(&this, peStatus);

	public HRESULT get_FirewallPrivateProfileSubstatus(WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) mut => VT.[Friend]get_FirewallPrivateProfileSubstatus(&this, peStatus);

	public HRESULT get_FirewallPublicProfileSubstatus(WSC_SECURITY_PRODUCT_SUBSTATUS* peStatus) mut => VT.[Friend]get_FirewallPublicProfileSubstatus(&this, peStatus);
}

[CRepr]struct IWscProduct3 : IWscProduct2
{
	public new const Guid IID = .(0x55536524, 0xd1d1, 0x4726, 0x8c, 0x7c, 0x04, 0x99, 0x6a, 0x19, 0x04, 0xe7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWscProduct2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwDays) get_AntivirusDaysUntilExpired;
	}


	public HRESULT get_AntivirusDaysUntilExpired(uint32* pdwDays) mut => VT.[Friend]get_AntivirusDaysUntilExpired(&this, pdwDays);
}

[CRepr]struct IWSCProductList : IDispatch
{
	public new const Guid IID = .(0x722a338c, 0x6e8e, 0x4e72, 0xac, 0x27, 0x14, 0x17, 0xfb, 0x0c, 0x81, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WSC_SECURITY_PROVIDER provider) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IWscProduct** pVal) get_Item;
	}


	public HRESULT Initialize(WSC_SECURITY_PROVIDER provider) mut => VT.[Friend]Initialize(&this, provider);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_Item(uint32 index, IWscProduct** pVal) mut => VT.[Friend]get_Item(&this, index, pVal);
}

[CRepr]struct IWSCDefaultProduct : IDispatch
{
	public new const Guid IID = .(0x0476d69c, 0xf21a, 0x11e5, 0x9c, 0xe9, 0x5e, 0x55, 0x17, 0x50, 0x7c, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SECURITY_PRODUCT_TYPE eType, BSTR pGuid) SetDefaultProduct;
	}


	public HRESULT SetDefaultProduct(SECURITY_PRODUCT_TYPE eType, BSTR pGuid) mut => VT.[Friend]SetDefaultProduct(&this, eType, pGuid);
}

#endregion

#region Functions
public static
{
	[Import("WSCAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WscRegisterForChanges(void* Reserved, HANDLE* phCallbackRegistration, LPTHREAD_START_ROUTINE lpCallbackAddress, void* pContext);

	[Import("WSCAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WscUnRegisterChanges(HANDLE hRegistrationHandle);

	[Import("WSCAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WscRegisterForUserNotifications();

	[Import("WSCAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WscGetSecurityProviderHealth(uint32 Providers, WSC_SECURITY_PROVIDER_HEALTH* pHealth);

	[Import("WSCAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WscQueryAntiMalwareUri();

	[Import("WSCAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WscGetAntiMalwareUri(PWSTR* ppszUri);

}
#endregion
