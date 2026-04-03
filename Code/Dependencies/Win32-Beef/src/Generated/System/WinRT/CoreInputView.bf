using Win32.System.WinRT;
using Win32.Foundation;
using System;

namespace Win32.System.WinRT.CoreInputView;

#region COM Types
[CRepr]struct ICoreFrameworkInputViewInterop : IInspectable
{
	public new const Guid IID = .(0x0e3da342, 0xb11c, 0x484b, 0x9c, 0x1c, 0xbe, 0x0d, 0x61, 0xc2, 0xf6, 0xc5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** coreFrameworkInputView) GetForWindow;
	}


	public HRESULT GetForWindow(HWND appWindow, in Guid riid, void** coreFrameworkInputView) mut => VT.[Friend]GetForWindow(&this, appWindow, riid, coreFrameworkInputView);
}

#endregion
