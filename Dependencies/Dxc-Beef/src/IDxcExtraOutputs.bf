using System;
namespace Dxc_Beef
{
	public struct IDxcExtraOutputs : IUnknown
	{
		public static Guid sIID = .(0x319b37a2,0xa5c2,0x494a,0xa5,0xde,0x48,0x01,0xb2,0xfa,0xf9,0x89);

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] uint32(IDxcExtraOutputs * self) GetOutputCount;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcExtraOutputs * self,
				uint32 uIndex,
				ref Guid iid, out void **ppvObject,
				out IDxcBlobWide *ppOutputType,
				out IDxcBlobWide *ppOutputName) GetOutput;
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