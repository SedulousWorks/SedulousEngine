using System;
namespace Dxc_Beef
{
	public struct IDxcBlobEncoding : IDxcBlob
	{
		public static new Guid IID = .(0x7241d424, 0x2646, 0x4191, 0x97, 0xc0, 0x98, 0xe9, 0x6e, 0x42, 0xfc, 0x68);

		public struct VTable : IDxcBlob.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcBlobEncoding* self, out bool* pKnown, out uint32 pCodePage) GetEncoding;
		}

		private new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}

		public HRESULT GetEncoding(out bool* pKnown, out uint32 pCodePage) mut {
			return VT.GetEncoding(&this, out pKnown, out pCodePage);
		}
	}
}