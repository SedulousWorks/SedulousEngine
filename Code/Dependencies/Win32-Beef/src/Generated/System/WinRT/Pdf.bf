using Win32.Foundation;
using Win32.Graphics.Dxgi;
using Win32.Graphics.Direct2D.Common;
using Win32.System.Com;
using Win32.Graphics.Direct2D;
using System;

namespace Win32.System.WinRT.Pdf;
#region Function Pointers
public function HRESULT PFN_PDF_CREATE_RENDERER(IDXGIDevice* param0, IPdfRendererNative** param1);

#endregion

#region Structs
[CRepr]
public struct PDF_RENDER_PARAMS
{
	public D2D_RECT_F SourceRect;
	public uint32 DestinationWidth;
	public uint32 DestinationHeight;
	public D2D_COLOR_F BackgroundColor;
	public BOOLEAN IgnoreHighContrast;
}

#endregion

#region COM Types
[CRepr]struct IPdfRendererNative : IUnknown
{
	public new const Guid IID = .(0x7d9dcd91, 0xd277, 0x4947, 0x85, 0x27, 0x07, 0xa0, 0xda, 0xed, 0xa9, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pdfPage, IDXGISurface* pSurface, POINT offset, PDF_RENDER_PARAMS* pRenderParams) RenderPageToSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pdfPage, ID2D1DeviceContext* pD2DDeviceContext, PDF_RENDER_PARAMS* pRenderParams) RenderPageToDeviceContext;
	}


	public HRESULT RenderPageToSurface(IUnknown* pdfPage, IDXGISurface* pSurface, POINT offset, PDF_RENDER_PARAMS* pRenderParams) mut => VT.[Friend]RenderPageToSurface(&this, pdfPage, pSurface, offset, pRenderParams);

	public HRESULT RenderPageToDeviceContext(IUnknown* pdfPage, ID2D1DeviceContext* pD2DDeviceContext, PDF_RENDER_PARAMS* pRenderParams) mut => VT.[Friend]RenderPageToDeviceContext(&this, pdfPage, pD2DDeviceContext, pRenderParams);
}

#endregion

#region Functions
public static
{
	[Import("Windows.Data.Pdf.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PdfCreateRenderer(IDXGIDevice* pDevice, IPdfRendererNative** ppRenderer);

}
#endregion
