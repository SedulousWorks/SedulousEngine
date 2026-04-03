using System;
namespace Dxc_Beef;

[CRepr]struct IUnknown
{
	public new const Guid IID = .(0x00000000, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvObject) QueryInterface;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) AddRef;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) Release;
	}


	public HRESULT QueryInterface(in Guid riid, void** ppvObject) mut => VT.[Friend]QueryInterface(&this, riid, ppvObject);

	public uint32 AddRef() mut => VT.[Friend]AddRef(&this);

	public uint32 Release() mut => VT.[Friend]Release(&this);
}