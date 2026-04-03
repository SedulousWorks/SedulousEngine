using System;
namespace Dxc_Beef
{
	public struct IDxcBlobUtf8 : IDxcBlobEncoding
	{
		public static new Guid IID = .(0x3DA636C9, 0xBA71, 0x4024, 0xA3, 0x01, 0x30, 0xCB, 0xF1, 0x25, 0x30, 0x5B);

		public struct VTable : IDxcBlobEncoding.VTable
		{
			public function [CallingConvention(.Stdcall)] char8*(IDxcBlobUtf8* self) GetStringPointer;
			public function [CallingConvention(.Stdcall)] int(IDxcBlobUtf8* self) GetStringLength;
		}

		private new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}

		public char8* GetStringPointer() mut
		{
			return VT.GetStringPointer(&this);
		}

		public int GetStringLength() mut
		{
			return VT.GetStringLength(&this);
		}
	}
}