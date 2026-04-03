using Win32.System.WinRT;
using Win32.Foundation;
using System;

namespace Win32.UI.Input.Radial;

#region COM Types
[CRepr]struct IRadialControllerInterop : IInspectable
{
	public new const Guid IID = .(0x1b0535c9, 0x57ad, 0x45c1, 0x9d, 0x79, 0xad, 0x5c, 0x34, 0x36, 0x05, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, in Guid riid, void** ppv) CreateForWindow;
	}


	public HRESULT CreateForWindow(HWND hwnd, in Guid riid, void** ppv) mut => VT.[Friend]CreateForWindow(&this, hwnd, riid, ppv);
}

[CRepr]struct IRadialControllerConfigurationInterop : IInspectable
{
	public new const Guid IID = .(0x787cdaac, 0x3186, 0x476d, 0x87, 0xe4, 0xb9, 0x37, 0x4a, 0x7b, 0x99, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, in Guid riid, void** ppv) GetForWindow;
	}


	public HRESULT GetForWindow(HWND hwnd, in Guid riid, void** ppv) mut => VT.[Friend]GetForWindow(&this, hwnd, riid, ppv);
}

[CRepr]struct IRadialControllerIndependentInputSourceInterop : IInspectable
{
	public new const Guid IID = .(0x3d577eff, 0x4cee, 0x11e6, 0xb5, 0x35, 0x00, 0x1b, 0xdc, 0x06, 0xab, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, in Guid riid, void** ppv) CreateForWindow;
	}


	public HRESULT CreateForWindow(HWND hwnd, in Guid riid, void** ppv) mut => VT.[Friend]CreateForWindow(&this, hwnd, riid, ppv);
}

#endregion
