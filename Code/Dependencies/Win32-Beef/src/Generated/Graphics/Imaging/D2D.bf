using Win32.System.Com;
using Win32.Foundation;
using Win32.Graphics.Direct2D;
using Win32.Graphics.Imaging;
using System;

namespace Win32.Graphics.Imaging.D2D;

#region COM Types
[CRepr]struct IWICImageEncoder : IUnknown
{
	public new const Guid IID = .(0x04c75bf8, 0x3ce1, 0x473b, 0xac, 0xc5, 0x3c, 0xc4, 0xf5, 0xe9, 0x49, 0x99);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID2D1Image* pImage, IWICBitmapFrameEncode* pFrameEncode, WICImageParameters* pImageParameters) WriteFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID2D1Image* pImage, IWICBitmapFrameEncode* pFrameEncode, WICImageParameters* pImageParameters) WriteFrameThumbnail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID2D1Image* pImage, IWICBitmapEncoder* pEncoder, WICImageParameters* pImageParameters) WriteThumbnail;
	}


	public HRESULT WriteFrame(ID2D1Image* pImage, IWICBitmapFrameEncode* pFrameEncode, WICImageParameters* pImageParameters) mut => VT.[Friend]WriteFrame(&this, pImage, pFrameEncode, pImageParameters);

	public HRESULT WriteFrameThumbnail(ID2D1Image* pImage, IWICBitmapFrameEncode* pFrameEncode, WICImageParameters* pImageParameters) mut => VT.[Friend]WriteFrameThumbnail(&this, pImage, pFrameEncode, pImageParameters);

	public HRESULT WriteThumbnail(ID2D1Image* pImage, IWICBitmapEncoder* pEncoder, WICImageParameters* pImageParameters) mut => VT.[Friend]WriteThumbnail(&this, pImage, pEncoder, pImageParameters);
}

[CRepr]struct IWICImagingFactory2 : IWICImagingFactory
{
	public new const Guid IID = .(0x7b816b45, 0x1996, 0x4476, 0xb1, 0x32, 0xde, 0x9e, 0x24, 0x7c, 0x8a, 0xf0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICImagingFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID2D1Device* pD2DDevice, IWICImageEncoder** ppWICImageEncoder) CreateImageEncoder;
	}


	public HRESULT CreateImageEncoder(ID2D1Device* pD2DDevice, IWICImageEncoder** ppWICImageEncoder) mut => VT.[Friend]CreateImageEncoder(&this, pD2DDevice, ppWICImageEncoder);
}

#endregion
