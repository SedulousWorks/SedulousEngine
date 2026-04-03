using System;
namespace Dxc_Beef
{
	public struct IDxcBlobWide : IDxcBlobEncoding
	{
		public static new Guid IID = .(0xA3F84EAB, 0x0FAA, 0x497E, 0xA3, 0x9C, 0xEE, 0x6E, 0xD6, 0x0B, 0x2D, 0x84);

		public struct VTable : IDxcBlobEncoding.VTable
		{
			public function [CallingConvention(.Stdcall)] char16*(IDxcBlobWide* self) GetStringPointer;
			public function [CallingConvention(.Stdcall)] int(IDxcBlobWide* self) GetStringLength;
		}

		private new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}

		public char16* GetStringPointer() mut
		{
			return VT.GetStringPointer(&this);
		}

		public int GetStringLength() mut
		{
			return VT.GetStringLength(&this);
		}
	}

#if BF_PLATFORM_WINDOWS
	typealias IDxcBlobUtf16 = IDxcBlobWide;
#endif
}