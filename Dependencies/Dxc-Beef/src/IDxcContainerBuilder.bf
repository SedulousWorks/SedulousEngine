using System;
namespace Dxc_Beef
{
	public struct IDxcContainerBuilder : IUnknown
	{
		public static new Guid IID = .(0x334b1f50, 0x2292, 0x4b35, 0x99, 0xa1, 0x25, 0x58, 0x8d, 0x8c, 0x17, 0xfe);
		public static new Guid sCLSID = CLSID_DxcContainerBuilder;

		public struct VTable : IUnknown.VTable
		{
			// Loads DxilContainer to the builder
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcContainerBuilder * self,IDxcBlob *pDxilContainerHeader) Load;

			// Part to add to the container
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcContainerBuilder * self, uint32 fourCC, IDxcBlob *pSource) AddPart;

			// Remove the part with fourCC
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcContainerBuilder * self, uint32 fourCC) RemovePart;

			// Builds a container of the given container builder state
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcContainerBuilder * self, out IDxcOperationResult *ppResult) SerializeContainer;
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