using System;
namespace Dxc_Beef
{
	public struct IDxcBlob : IUnknown
	{
		public static Guid sIID = .(0x8BA5FB08, 0x5195, 0x40e2, 0xAC, 0x58, 0x0D, 0x98, 0x9C, 0x3A, 0x01, 0x02);

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] void*(IDxcBlob* self) GetBufferPointer;
			public function [CallingConvention(.Stdcall)] uint(IDxcBlob* self) GetBufferSize;
		}

		private new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}

		public void* GetBufferPointer() mut
		{
			return VT.GetBufferPointer(&this);
		}

		public uint GetBufferSize() mut
		{
			return VT.GetBufferSize(&this);
		}
	}
}