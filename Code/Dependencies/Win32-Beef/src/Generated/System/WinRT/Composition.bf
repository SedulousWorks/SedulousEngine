using Win32.System.Com;
using Win32.Foundation;
using Win32.UI.Input.Pointer;
using Win32.System.WinRT;
using System;

namespace Win32.System.WinRT.Composition;

#region COM Types
[CRepr]struct ICompositionDrawingSurfaceInterop : IUnknown
{
	public new const Guid IID = .(0xfd04e6e3, 0xfe0c, 0x4c3c, 0xab, 0x19, 0xa0, 0x76, 0x01, 0xa5, 0x76, 0xee);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* updateRect, in Guid iid, void** updateObject, POINT* updateOffset) BeginDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE sizePixels) Resize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* scrollRect, RECT* clipRect, int32 offsetX, int32 offsetY) Scroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResumeDraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SuspendDraw;
	}


	public HRESULT BeginDraw(RECT* updateRect, in Guid iid, void** updateObject, POINT* updateOffset) mut => VT.[Friend]BeginDraw(&this, updateRect, iid, updateObject, updateOffset);

	public HRESULT EndDraw() mut => VT.[Friend]EndDraw(&this);

	public HRESULT Resize(SIZE sizePixels) mut => VT.[Friend]Resize(&this, sizePixels);

	public HRESULT Scroll(RECT* scrollRect, RECT* clipRect, int32 offsetX, int32 offsetY) mut => VT.[Friend]Scroll(&this, scrollRect, clipRect, offsetX, offsetY);

	public HRESULT ResumeDraw() mut => VT.[Friend]ResumeDraw(&this);

	public HRESULT SuspendDraw() mut => VT.[Friend]SuspendDraw(&this);
}

[CRepr]struct ICompositionDrawingSurfaceInterop2 : ICompositionDrawingSurfaceInterop
{
	public new const Guid IID = .(0x41e64aae, 0x98c0, 0x4239, 0x8e, 0x95, 0xa3, 0x30, 0xdd, 0x6a, 0xa1, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICompositionDrawingSurfaceInterop.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* destinationResource, int32 destinationOffsetX, int32 destinationOffsetY, RECT* sourceRectangle) CopySurface;
	}


	public HRESULT CopySurface(IUnknown* destinationResource, int32 destinationOffsetX, int32 destinationOffsetY, RECT* sourceRectangle) mut => VT.[Friend]CopySurface(&this, destinationResource, destinationOffsetX, destinationOffsetY, sourceRectangle);
}

[CRepr]struct ICompositionGraphicsDeviceInterop : IUnknown
{
	public new const Guid IID = .(0xa116ff71, 0xf8bf, 0x4c8a, 0x9c, 0x98, 0x70, 0x77, 0x9a, 0x32, 0xa9, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** value) GetRenderingDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* value) SetRenderingDevice;
	}


	public HRESULT GetRenderingDevice(IUnknown** value) mut => VT.[Friend]GetRenderingDevice(&this, value);

	public HRESULT SetRenderingDevice(IUnknown* value) mut => VT.[Friend]SetRenderingDevice(&this, value);
}

[CRepr]struct ICompositorInterop : IUnknown
{
	public new const Guid IID = .(0x25297d5c, 0x3ad4, 0x4c9c, 0xb5, 0xcf, 0xe3, 0x6a, 0x38, 0x51, 0x23, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE swapChain, void** result) CreateCompositionSurfaceForHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* swapChain, void** result) CreateCompositionSurfaceForSwapChain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* renderingDevice, void** result) CreateGraphicsDevice;
	}


	public HRESULT CreateCompositionSurfaceForHandle(HANDLE swapChain, void** result) mut => VT.[Friend]CreateCompositionSurfaceForHandle(&this, swapChain, result);

	public HRESULT CreateCompositionSurfaceForSwapChain(IUnknown* swapChain, void** result) mut => VT.[Friend]CreateCompositionSurfaceForSwapChain(&this, swapChain, result);

	public HRESULT CreateGraphicsDevice(IUnknown* renderingDevice, void** result) mut => VT.[Friend]CreateGraphicsDevice(&this, renderingDevice, result);
}

[CRepr]struct ISwapChainInterop : IUnknown
{
	public new const Guid IID = .(0x26f496a0, 0x7f38, 0x45fb, 0x88, 0xf7, 0xfa, 0xaa, 0xbe, 0x67, 0xdd, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* swapChain) SetSwapChain;
	}


	public HRESULT SetSwapChain(IUnknown* swapChain) mut => VT.[Friend]SetSwapChain(&this, swapChain);
}

[CRepr]struct IVisualInteractionSourceInterop : IUnknown
{
	public new const Guid IID = .(0x11f62cd1, 0x2f9d, 0x42d3, 0xb0, 0x5f, 0xd6, 0x79, 0x0d, 0x9e, 0x9f, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINTER_INFO* pointerInfo) TryRedirectForManipulation;
	}


	public HRESULT TryRedirectForManipulation(POINTER_INFO* pointerInfo) mut => VT.[Friend]TryRedirectForManipulation(&this, pointerInfo);
}

[CRepr]struct ICompositionCapabilitiesInteropFactory : IInspectable
{
	public new const Guid IID = .(0x2c9db356, 0xe70d, 0x4642, 0x82, 0x98, 0xbc, 0x4a, 0xa5, 0xb4, 0x86, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, void** result) GetForWindow;
	}


	public HRESULT GetForWindow(HWND hwnd, void** result) mut => VT.[Friend]GetForWindow(&this, hwnd, result);
}

[CRepr]struct ICompositorDesktopInterop : IUnknown
{
	public new const Guid IID = .(0x29e691fa, 0x4567, 0x4dca, 0xb3, 0x19, 0xd0, 0xf2, 0x07, 0xeb, 0x68, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndTarget, BOOL isTopmost, void** result) CreateDesktopWindowTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 threadId) EnsureOnThread;
	}


	public HRESULT CreateDesktopWindowTarget(HWND hwndTarget, BOOL isTopmost, void** result) mut => VT.[Friend]CreateDesktopWindowTarget(&this, hwndTarget, isTopmost, result);

	public HRESULT EnsureOnThread(uint32 threadId) mut => VT.[Friend]EnsureOnThread(&this, threadId);
}

[CRepr]struct IDesktopWindowTargetInterop : IUnknown
{
	public new const Guid IID = .(0x35dbf59e, 0xe3f9, 0x45b0, 0x81, 0xe7, 0xfe, 0x75, 0xf4, 0x14, 0x5d, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* value) get_Hwnd;
	}


	public HRESULT get_Hwnd(HWND* value) mut => VT.[Friend]get_Hwnd(&this, value);
}

#endregion
