using System;
namespace Dxc_Beef
{
	public struct IDxcOptimizerPass : IUnknown
	{
		public static Guid sIID = .(0xAE2CD79F, 0xCC22, 0x453F, 0x9B, 0x6B, 0xB1, 0x24, 0xE7, 0xA5, 0x20, 0x4C);

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcOptimizerPass * self, out char16 *ppResult) GetOptionName;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcOptimizerPass * self, out char16 *ppResult) GetDescription;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcOptimizerPass * self, out uint32 pCount) GetOptionArgCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcOptimizerPass * self, uint32 argIndex, out char16 *ppResult) GetOptionArgName;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcOptimizerPass * self, uint32 argIndex, out char16 *ppResult) GetOptionArgDescription;
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