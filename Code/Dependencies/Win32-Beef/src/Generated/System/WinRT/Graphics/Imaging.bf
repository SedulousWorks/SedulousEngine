using Win32.System.WinRT;
using Win32.Foundation;
using Win32.Graphics.Imaging;
using Win32.Media.MediaFoundation;
using System;

namespace Win32.System.WinRT.Graphics.Imaging;

#region Constants
public static
{
	public const Guid CLSID_SoftwareBitmapNativeFactory = .(0x84e65691, 0x8602, 0x4a84, 0xbe, 0x46, 0x70, 0x8b, 0xe9, 0xcd, 0x4b, 0x74);
}
#endregion

#region COM Types
[CRepr]struct ISoftwareBitmapNative : IInspectable
{
	public new const Guid IID = .(0x94bc8415, 0x04ea, 0x4b2e, 0xaf, 0x13, 0x4d, 0xe9, 0x5a, 0xa8, 0x98, 0xeb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetData;
	}


	public HRESULT GetData(in Guid riid, void** ppv) mut => VT.[Friend]GetData(&this, riid, ppv);
}

[CRepr]struct ISoftwareBitmapNativeFactory : IInspectable
{
	public new const Guid IID = .(0xc3c181ec, 0x2914, 0x4791, 0xaf, 0x02, 0x02, 0xd2, 0x24, 0xa1, 0x0b, 0x43);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmap* data, BOOL forceReadOnly, in Guid riid, void** ppv) CreateFromWICBitmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMF2DBuffer2* data, in Guid subtype, uint32 width, uint32 height, BOOL forceReadOnly, MFVideoArea* minDisplayAperture, in Guid riid, void** ppv) CreateFromMF2DBuffer2;
	}


	public HRESULT CreateFromWICBitmap(IWICBitmap* data, BOOL forceReadOnly, in Guid riid, void** ppv) mut => VT.[Friend]CreateFromWICBitmap(&this, data, forceReadOnly, riid, ppv);

	public HRESULT CreateFromMF2DBuffer2(IMF2DBuffer2* data, in Guid subtype, uint32 width, uint32 height, BOOL forceReadOnly, MFVideoArea* minDisplayAperture, in Guid riid, void** ppv) mut => VT.[Friend]CreateFromMF2DBuffer2(&this, data, subtype, width, height, forceReadOnly, minDisplayAperture, riid, ppv);
}

#endregion
