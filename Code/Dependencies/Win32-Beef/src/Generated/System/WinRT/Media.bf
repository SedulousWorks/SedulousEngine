using Win32.System.WinRT;
using Win32.Foundation;
using Win32.Media.MediaFoundation;
using System;

namespace Win32.System.WinRT.Media;

#region Constants
public static
{
	public const Guid CLSID_AudioFrameNativeFactory = .(0x16a0a3b9, 0x9f65, 0x4102, 0x93, 0x67, 0x2c, 0xda, 0x3a, 0x4f, 0x37, 0x2a);
	public const Guid CLSID_VideoFrameNativeFactory = .(0xd194386a, 0x04e3, 0x4814, 0x81, 0x00, 0xb2, 0xb0, 0xae, 0x6d, 0x78, 0xc7);
}
#endregion

#region COM Types
[CRepr]struct IAudioFrameNative : IInspectable
{
	public new const Guid IID = .(0x20be1e2e, 0x930f, 0x4746, 0x93, 0x35, 0x3c, 0x33, 0x2f, 0x25, 0x50, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetData;
	}


	public HRESULT GetData(in Guid riid, void** ppv) mut => VT.[Friend]GetData(&this, riid, ppv);
}

[CRepr]struct IVideoFrameNative : IInspectable
{
	public new const Guid IID = .(0x26ba702b, 0x314a, 0x4620, 0xaa, 0xf6, 0x7a, 0x51, 0xaa, 0x58, 0xfa, 0x18);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetDevice;
	}


	public HRESULT GetData(in Guid riid, void** ppv) mut => VT.[Friend]GetData(&this, riid, ppv);

	public HRESULT GetDevice(in Guid riid, void** ppv) mut => VT.[Friend]GetDevice(&this, riid, ppv);
}

[CRepr]struct IAudioFrameNativeFactory : IInspectable
{
	public new const Guid IID = .(0x7bd67cf8, 0xbf7d, 0x43e6, 0xaf, 0x8d, 0xb1, 0x70, 0xee, 0x0c, 0x01, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMFSample* data, BOOL forceReadOnly, in Guid riid, void** ppv) CreateFromMFSample;
	}


	public HRESULT CreateFromMFSample(IMFSample* data, BOOL forceReadOnly, in Guid riid, void** ppv) mut => VT.[Friend]CreateFromMFSample(&this, data, forceReadOnly, riid, ppv);
}

[CRepr]struct IVideoFrameNativeFactory : IInspectable
{
	public new const Guid IID = .(0x69e3693e, 0x8e1e, 0x4e63, 0xac, 0x4c, 0x7f, 0xdc, 0x21, 0xd9, 0x73, 0x1d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMFSample* data, in Guid subtype, uint32 width, uint32 height, BOOL forceReadOnly, MFVideoArea* minDisplayAperture, IMFDXGIDeviceManager* device, in Guid riid, void** ppv) CreateFromMFSample;
	}


	public HRESULT CreateFromMFSample(IMFSample* data, in Guid subtype, uint32 width, uint32 height, BOOL forceReadOnly, MFVideoArea* minDisplayAperture, IMFDXGIDeviceManager* device, in Guid riid, void** ppv) mut => VT.[Friend]CreateFromMFSample(&this, data, subtype, width, height, forceReadOnly, minDisplayAperture, device, riid, ppv);
}

#endregion
