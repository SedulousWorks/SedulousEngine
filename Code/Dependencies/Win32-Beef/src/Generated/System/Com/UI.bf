using Win32.System.Com;
using Win32.Foundation;
using Win32.System.Com.StructuredStorage;
using Win32.Graphics.Gdi;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.System.Com.UI;

#region COM Types
[CRepr]struct IThumbnailExtractor : IUnknown
{
	public new const Guid IID = .(0x969dc708, 0x5c76, 0x11d1, 0x8d, 0x86, 0x00, 0x00, 0xf8, 0x04, 0xb0, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStorage* pStg, uint32 ulLength, uint32 ulHeight, uint32* pulOutputLength, uint32* pulOutputHeight, HBITMAP* phOutputBitmap) ExtractThumbnail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStorage* pStg) OnFileUpdated;
	}


	public HRESULT ExtractThumbnail(IStorage* pStg, uint32 ulLength, uint32 ulHeight, uint32* pulOutputLength, uint32* pulOutputHeight, HBITMAP* phOutputBitmap) mut => VT.[Friend]ExtractThumbnail(&this, pStg, ulLength, ulHeight, pulOutputLength, pulOutputHeight, phOutputBitmap);

	public HRESULT OnFileUpdated(IStorage* pStg) mut => VT.[Friend]OnFileUpdated(&this, pStg);
}

[CRepr]struct IDummyHICONIncluder : IUnknown
{
	public new const Guid IID = .(0x947990de, 0xcc28, 0x11d2, 0xa0, 0xf7, 0x00, 0x80, 0x5f, 0x85, 0x8f, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HICON h1, HDC h2) Dummy;
	}


	public HRESULT Dummy(HICON h1, HDC h2) mut => VT.[Friend]Dummy(&this, h1, h2);
}

#endregion
