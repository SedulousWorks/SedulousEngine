using System;
namespace Dxc_Beef
{
	public struct IDxcVersionInfo3 : IUnknown
	{
		public static Guid sIID = .(0x5e13e843, 0x9d25, 0x473c, 0x9a, 0xd2, 0x03, 0xb2, 0xd0, 0xb4, 0x4b, 0x1e);

		public struct VTable : IUnknown.VTable
		{
			// Assemble dxil in ll or llvm bitcode to DXIL container.
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcVersionInfo3 * self,
				out char8 **pVersionString // Custom version string for compiler. (Must be CoTaskMemFree()'d!)
				) GetCustomVersionString;
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