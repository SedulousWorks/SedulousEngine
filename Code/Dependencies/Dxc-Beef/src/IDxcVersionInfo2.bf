using System;
namespace Dxc_Beef
{
	public struct IDxcVersionInfo2 : IDxcVersionInfo
	{
		public static new Guid IID = .(0xfb6904c4, 0x42f0, 0x4b62, 0x9c, 0x46, 0x98, 0x3a, 0xf7, 0xda, 0x7c, 0x83);

		public struct VTable : IDxcVersionInfo.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcVersionInfo2 * self,
				out uint32 pCommitCount,           // The total number commits.
				out char8 **pCommitHash  // The SHA of the latest commit. (Must be CoTaskMemFree()'d!)
				) GetCommitInfo;
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