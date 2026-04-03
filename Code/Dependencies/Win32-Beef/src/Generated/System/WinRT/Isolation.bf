using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.System.WinRT.Isolation;

#region COM Types
[CRepr]struct IIsolatedEnvironmentInterop : IUnknown
{
	public new const Guid IID = .(0x85713c2e, 0x8e62, 0x46c5, 0x8d, 0xe2, 0xc6, 0x47, 0xe1, 0xd5, 0x46, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND containerHwnd, HWND* hostHwnd) GetHostHwndInterop;
	}


	public HRESULT GetHostHwndInterop(HWND containerHwnd, HWND* hostHwnd) mut => VT.[Friend]GetHostHwndInterop(&this, containerHwnd, hostHwnd);
}

#endregion
