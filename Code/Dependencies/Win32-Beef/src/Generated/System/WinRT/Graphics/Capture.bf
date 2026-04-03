using Win32.System.Com;
using Win32.Foundation;
using Win32.Graphics.Gdi;
using System;

namespace Win32.System.WinRT.Graphics.Capture;

#region COM Types
[CRepr]struct IGraphicsCaptureItemInterop : IUnknown
{
	public new const Guid IID = .(0x3628e81b, 0x3cac, 0x4c60, 0xb7, 0xf4, 0x23, 0xce, 0x0e, 0x0c, 0x33, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND window, in Guid riid, void** result) CreateForWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMONITOR monitor, in Guid riid, void** result) CreateForMonitor;
	}


	public HRESULT CreateForWindow(HWND window, in Guid riid, void** result) mut => VT.[Friend]CreateForWindow(&this, window, riid, result);

	public HRESULT CreateForMonitor(HMONITOR monitor, in Guid riid, void** result) mut => VT.[Friend]CreateForMonitor(&this, monitor, riid, result);
}

#endregion
