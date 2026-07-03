using System;
namespace Dxc_Beef
{
	public struct IDxcVersionInfo : IUnknown
	{
		public static Guid sIID = .(0xb04f5b50, 0x2059, 0x4f12, 0xa8, 0xff, 0xa1, 0xe0, 0xcd, 0xe1, 0xcc, 0x7e);

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcVersionInfo * self, out uint32 pMajor, out uint32 pMinor) GetVersion;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcVersionInfo * self, out uint32 pFlags) GetFlags;
		}

		public new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}
	}
}