using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.Media.LibrarySharingServices;

#region Enums

[AllowDuplicates]
public enum WindowsMediaLibrarySharingDeviceAuthorizationStatus : int32
{
	DEVICE_AUTHORIZATION_UNKNOWN = 0,
	DEVICE_AUTHORIZATION_ALLOWED = 1,
	DEVICE_AUTHORIZATION_DENIED = 2,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_WindowsMediaLibrarySharingServices = .(0xad581b00, 0x7b64, 0x4e59, 0xa3, 0x8d, 0xd2, 0xc5, 0xbf, 0x51, 0xdd, 0xb3);


}
#endregion

#region COM Types
[CRepr]struct IWindowsMediaLibrarySharingDeviceProperty : IDispatch
{
	public new const Guid IID = .(0x81e26927, 0x7a7d, 0x40a7, 0x81, 0xd4, 0xbd, 0xdc, 0x02, 0x96, 0x0e, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* value) get_Value;
	}


	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT get_Value(VARIANT* value) mut => VT.[Friend]get_Value(&this, value);
}

[CRepr]struct IWindowsMediaLibrarySharingDeviceProperties : IDispatch
{
	public new const Guid IID = .(0xc4623214, 0x6b06, 0x40c5, 0xa6, 0x23, 0xb2, 0xff, 0x4c, 0x07, 0x6b, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, IWindowsMediaLibrarySharingDeviceProperty** property) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, IWindowsMediaLibrarySharingDeviceProperty** property) GetProperty;
	}


	public HRESULT get_Item(int32 index, IWindowsMediaLibrarySharingDeviceProperty** property) mut => VT.[Friend]get_Item(&this, index, property);

	public HRESULT get_Count(int32* count) mut => VT.[Friend]get_Count(&this, count);

	public HRESULT GetProperty(BSTR name, IWindowsMediaLibrarySharingDeviceProperty** property) mut => VT.[Friend]GetProperty(&this, name, property);
}

[CRepr]struct IWindowsMediaLibrarySharingDevice : IDispatch
{
	public new const Guid IID = .(0x3dccc293, 0x4fd9, 0x4191, 0xa2, 0x5b, 0x8e, 0x57, 0xc5, 0xd2, 0x7b, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* deviceID) get_DeviceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WindowsMediaLibrarySharingDeviceAuthorizationStatus* authorization) get_Authorization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WindowsMediaLibrarySharingDeviceAuthorizationStatus authorization) put_Authorization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWindowsMediaLibrarySharingDeviceProperties** deviceProperties) get_Properties;
	}


	public HRESULT get_DeviceID(BSTR* deviceID) mut => VT.[Friend]get_DeviceID(&this, deviceID);

	public HRESULT get_Authorization(WindowsMediaLibrarySharingDeviceAuthorizationStatus* authorization) mut => VT.[Friend]get_Authorization(&this, authorization);

	public HRESULT put_Authorization(WindowsMediaLibrarySharingDeviceAuthorizationStatus authorization) mut => VT.[Friend]put_Authorization(&this, authorization);

	public HRESULT get_Properties(IWindowsMediaLibrarySharingDeviceProperties** deviceProperties) mut => VT.[Friend]get_Properties(&this, deviceProperties);
}

[CRepr]struct IWindowsMediaLibrarySharingDevices : IDispatch
{
	public new const Guid IID = .(0x1803f9d6, 0xfe6d, 0x4546, 0xbf, 0x5b, 0x99, 0x2f, 0xe8, 0xec, 0x12, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, IWindowsMediaLibrarySharingDevice** device) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR deviceID, IWindowsMediaLibrarySharingDevice** device) GetDevice;
	}


	public HRESULT get_Item(int32 index, IWindowsMediaLibrarySharingDevice** device) mut => VT.[Friend]get_Item(&this, index, device);

	public HRESULT get_Count(int32* count) mut => VT.[Friend]get_Count(&this, count);

	public HRESULT GetDevice(BSTR deviceID, IWindowsMediaLibrarySharingDevice** device) mut => VT.[Friend]GetDevice(&this, deviceID, device);
}

[CRepr]struct IWindowsMediaLibrarySharingServices : IDispatch
{
	public new const Guid IID = .(0x01f5f85e, 0x0a81, 0x40da, 0xa7, 0xc8, 0x21, 0xef, 0x3a, 0xf8, 0x44, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR device) showShareMediaCPL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* sharingEnabled) get_userHomeMediaSharingState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 sharingEnabled) put_userHomeMediaSharingState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* libraryName) get_userHomeMediaSharingLibraryName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR libraryName) put_userHomeMediaSharingLibraryName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* sharingAllowed) get_computerHomeMediaSharingAllowedState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 sharingAllowed) put_computerHomeMediaSharingAllowedState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* sharingEnabled) get_userInternetMediaSharingState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 sharingEnabled) put_userInternetMediaSharingState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* sharingAllowed) get_computerInternetMediaSharingAllowedState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 sharingAllowed) put_computerInternetMediaSharingAllowedState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* securityGroup) get_internetMediaSharingSecurityGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR securityGroup) put_internetMediaSharingSecurityGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* sharingEnabled) get_allowSharingToAllDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 sharingEnabled) put_allowSharingToAllDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR MACAddresses, BSTR friendlyName, int16 authorization) setDefaultAuthorization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR MACAddress, int16 authorizationState) setAuthorizationState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWindowsMediaLibrarySharingDevices** devices) getAllDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* customSettingsApplied) get_customSettingsApplied;
	}


	public HRESULT showShareMediaCPL(BSTR device) mut => VT.[Friend]showShareMediaCPL(&this, device);

	public HRESULT get_userHomeMediaSharingState(int16* sharingEnabled) mut => VT.[Friend]get_userHomeMediaSharingState(&this, sharingEnabled);

	public HRESULT put_userHomeMediaSharingState(int16 sharingEnabled) mut => VT.[Friend]put_userHomeMediaSharingState(&this, sharingEnabled);

	public HRESULT get_userHomeMediaSharingLibraryName(BSTR* libraryName) mut => VT.[Friend]get_userHomeMediaSharingLibraryName(&this, libraryName);

	public HRESULT put_userHomeMediaSharingLibraryName(BSTR libraryName) mut => VT.[Friend]put_userHomeMediaSharingLibraryName(&this, libraryName);

	public HRESULT get_computerHomeMediaSharingAllowedState(int16* sharingAllowed) mut => VT.[Friend]get_computerHomeMediaSharingAllowedState(&this, sharingAllowed);

	public HRESULT put_computerHomeMediaSharingAllowedState(int16 sharingAllowed) mut => VT.[Friend]put_computerHomeMediaSharingAllowedState(&this, sharingAllowed);

	public HRESULT get_userInternetMediaSharingState(int16* sharingEnabled) mut => VT.[Friend]get_userInternetMediaSharingState(&this, sharingEnabled);

	public HRESULT put_userInternetMediaSharingState(int16 sharingEnabled) mut => VT.[Friend]put_userInternetMediaSharingState(&this, sharingEnabled);

	public HRESULT get_computerInternetMediaSharingAllowedState(int16* sharingAllowed) mut => VT.[Friend]get_computerInternetMediaSharingAllowedState(&this, sharingAllowed);

	public HRESULT put_computerInternetMediaSharingAllowedState(int16 sharingAllowed) mut => VT.[Friend]put_computerInternetMediaSharingAllowedState(&this, sharingAllowed);

	public HRESULT get_internetMediaSharingSecurityGroup(BSTR* securityGroup) mut => VT.[Friend]get_internetMediaSharingSecurityGroup(&this, securityGroup);

	public HRESULT put_internetMediaSharingSecurityGroup(BSTR securityGroup) mut => VT.[Friend]put_internetMediaSharingSecurityGroup(&this, securityGroup);

	public HRESULT get_allowSharingToAllDevices(int16* sharingEnabled) mut => VT.[Friend]get_allowSharingToAllDevices(&this, sharingEnabled);

	public HRESULT put_allowSharingToAllDevices(int16 sharingEnabled) mut => VT.[Friend]put_allowSharingToAllDevices(&this, sharingEnabled);

	public HRESULT setDefaultAuthorization(BSTR MACAddresses, BSTR friendlyName, int16 authorization) mut => VT.[Friend]setDefaultAuthorization(&this, MACAddresses, friendlyName, authorization);

	public HRESULT setAuthorizationState(BSTR MACAddress, int16 authorizationState) mut => VT.[Friend]setAuthorizationState(&this, MACAddress, authorizationState);

	public HRESULT getAllDevices(IWindowsMediaLibrarySharingDevices** devices) mut => VT.[Friend]getAllDevices(&this, devices);

	public HRESULT get_customSettingsApplied(int16* customSettingsApplied) mut => VT.[Friend]get_customSettingsApplied(&this, customSettingsApplied);
}

#endregion
