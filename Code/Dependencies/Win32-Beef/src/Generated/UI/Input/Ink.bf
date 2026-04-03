using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.UI.Input.Ink;

#region Enums

[AllowDuplicates]
public enum INK_HIGH_CONTRAST_ADJUSTMENT : int32
{
	USE_SYSTEM_COLORS_WHEN_NECESSARY = 0,
	USE_SYSTEM_COLORS = 1,
	USE_ORIGINAL_COLORS = 2,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_InkDesktopHost = .(0x062584a6, 0xf830, 0x4bdc, 0xa4, 0xd2, 0x0a, 0x10, 0xab, 0x06, 0x2b, 0x1d);


	public const Guid CLSID_InkD2DRenderer = .(0x4044e60c, 0x7b01, 0x4671, 0xa9, 0x7c, 0x04, 0xe0, 0x21, 0x0a, 0x07, 0xa5);


}
#endregion

#region COM Types
[CRepr]struct IInkCommitRequestHandler : IUnknown
{
	public new const Guid IID = .(0xfabea3fc, 0xb108, 0x45b6, 0xa9, 0xfc, 0x8d, 0x08, 0xfa, 0x9f, 0x85, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnCommitRequested;
	}


	public HRESULT OnCommitRequested() mut => VT.[Friend]OnCommitRequested(&this);
}

[CRepr]struct IInkPresenterDesktop : IUnknown
{
	public new const Guid IID = .(0x73f3c0d9, 0x2e8b, 0x48f3, 0x89, 0x5e, 0x20, 0xcb, 0xd2, 0x7b, 0x72, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* rootVisual, IUnknown* device) SetRootVisual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkCommitRequestHandler* handler) SetCommitRequestHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* width, float* height) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float width, float height) SetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnHighContrastChanged;
	}


	public HRESULT SetRootVisual(IUnknown* rootVisual, IUnknown* device) mut => VT.[Friend]SetRootVisual(&this, rootVisual, device);

	public HRESULT SetCommitRequestHandler(IInkCommitRequestHandler* handler) mut => VT.[Friend]SetCommitRequestHandler(&this, handler);

	public HRESULT GetSize(float* width, float* height) mut => VT.[Friend]GetSize(&this, width, height);

	public HRESULT SetSize(float width, float height) mut => VT.[Friend]SetSize(&this, width, height);

	public HRESULT OnHighContrastChanged() mut => VT.[Friend]OnHighContrastChanged(&this);
}

[CRepr]struct IInkHostWorkItem : IUnknown
{
	public new const Guid IID = .(0xccda0a9a, 0x1b78, 0x4632, 0xbb, 0x96, 0x97, 0x80, 0x06, 0x62, 0xe2, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Invoke;
	}


	public HRESULT Invoke() mut => VT.[Friend]Invoke(&this);
}

[CRepr]struct IInkDesktopHost : IUnknown
{
	public new const Guid IID = .(0x4ce7d875, 0xa981, 0x4140, 0xa1, 0xff, 0xad, 0x93, 0x25, 0x8e, 0x8d, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInkHostWorkItem* workItem) QueueWorkItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) CreateInkPresenter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* rootVisual, float width, float height, in Guid riid, void** ppv) CreateAndInitializeInkPresenter;
	}


	public HRESULT QueueWorkItem(IInkHostWorkItem* workItem) mut => VT.[Friend]QueueWorkItem(&this, workItem);

	public HRESULT CreateInkPresenter(in Guid riid, void** ppv) mut => VT.[Friend]CreateInkPresenter(&this, riid, ppv);

	public HRESULT CreateAndInitializeInkPresenter(IUnknown* rootVisual, float width, float height, in Guid riid, void** ppv) mut => VT.[Friend]CreateAndInitializeInkPresenter(&this, rootVisual, width, height, riid, ppv);
}

[CRepr]struct IInkD2DRenderer : IUnknown
{
	public new const Guid IID = .(0x407fb1de, 0xf85a, 0x4150, 0x97, 0xcf, 0xb7, 0xfb, 0x27, 0x4f, 0xb4, 0xf8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pD2D1DeviceContext, IUnknown* pInkStrokeIterable, BOOL fHighContrast) Draw;
	}


	public HRESULT Draw(IUnknown* pD2D1DeviceContext, IUnknown* pInkStrokeIterable, BOOL fHighContrast) mut => VT.[Friend]Draw(&this, pD2D1DeviceContext, pInkStrokeIterable, fHighContrast);
}

[CRepr]struct IInkD2DRenderer2 : IUnknown
{
	public new const Guid IID = .(0x0a95dcd9, 0x4578, 0x4b71, 0xb2, 0x0b, 0xbf, 0x66, 0x4d, 0x4b, 0xfe, 0xee);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pD2D1DeviceContext, IUnknown* pInkStrokeIterable, INK_HIGH_CONTRAST_ADJUSTMENT highContrastAdjustment) Draw;
	}


	public HRESULT Draw(IUnknown* pD2D1DeviceContext, IUnknown* pInkStrokeIterable, INK_HIGH_CONTRAST_ADJUSTMENT highContrastAdjustment) mut => VT.[Friend]Draw(&this, pD2D1DeviceContext, pInkStrokeIterable, highContrastAdjustment);
}

#endregion
