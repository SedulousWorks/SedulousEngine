using Win32.System.WinRT;
using Win32.Foundation;
using System;

namespace Win32.System.WinRT.AllJoyn;

#region COM Types
[CRepr]struct IWindowsDevicesAllJoynBusAttachmentInterop : IInspectable
{
	public new const Guid IID = .(0xfd89c65b, 0xb50e, 0x4a19, 0x9d, 0x0c, 0xb4, 0x2b, 0x78, 0x32, 0x81, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* value) get_Win32Handle;
	}


	public HRESULT get_Win32Handle(uint64* value) mut => VT.[Friend]get_Win32Handle(&this, value);
}

[CRepr]struct IWindowsDevicesAllJoynBusAttachmentFactoryInterop : IInspectable
{
	public new const Guid IID = .(0x4b8f7505, 0xb239, 0x4e7b, 0x88, 0xaf, 0xf6, 0x68, 0x25, 0x75, 0xd8, 0x61);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 win32handle, uint8 enableAboutData, in Guid riid, void** ppv) CreateFromWin32Handle;
	}


	public HRESULT CreateFromWin32Handle(uint64 win32handle, uint8 enableAboutData, in Guid riid, void** ppv) mut => VT.[Friend]CreateFromWin32Handle(&this, win32handle, enableAboutData, riid, ppv);
}

[CRepr]struct IWindowsDevicesAllJoynBusObjectInterop : IInspectable
{
	public new const Guid IID = .(0xd78aa3d5, 0x5054, 0x428f, 0x99, 0xf2, 0xec, 0x3a, 0x5d, 0xe3, 0xc3, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* context, HSTRING interfaceName, int callback) AddPropertyGetHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* context, HSTRING interfaceName, int callback) AddPropertySetHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* value) get_Win32Handle;
	}


	public HRESULT AddPropertyGetHandler(void* context, HSTRING interfaceName, int callback) mut => VT.[Friend]AddPropertyGetHandler(&this, context, interfaceName, callback);

	public HRESULT AddPropertySetHandler(void* context, HSTRING interfaceName, int callback) mut => VT.[Friend]AddPropertySetHandler(&this, context, interfaceName, callback);

	public HRESULT get_Win32Handle(uint64* value) mut => VT.[Friend]get_Win32Handle(&this, value);
}

[CRepr]struct IWindowsDevicesAllJoynBusObjectFactoryInterop : IInspectable
{
	public new const Guid IID = .(0x6174e506, 0x8b95, 0x4e36, 0x95, 0xc0, 0xb8, 0x8f, 0xed, 0x34, 0x93, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 win32handle, in Guid riid, void** ppv) CreateFromWin32Handle;
	}


	public HRESULT CreateFromWin32Handle(uint64 win32handle, in Guid riid, void** ppv) mut => VT.[Friend]CreateFromWin32Handle(&this, win32handle, riid, ppv);
}

#endregion
