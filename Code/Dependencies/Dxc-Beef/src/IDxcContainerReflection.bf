using System;
namespace Dxc_Beef
{
	public struct IDxcContainerReflection : IUnknown
	{
		public static new Guid IID = .(0xd2c21b26, 0x8350, 0x4bdc, 0x97, 0x6a, 0x33, 0x1c, 0xe6, 0xf4, 0xc5, 0x4c);
		public static new Guid sCLSID = CLSID_DxcContainerReflection;

		public struct VTable : IUnknown.VTable
		{
			// Container to load.
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcContainerReflection * self, IDxcBlob *pContainer) Load;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcContainerReflection * self, out uint32 pResult) GetPartCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcContainerReflection * self, uint32 idx, out uint32 pResult) GetPartKind;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcContainerReflection * self, uint32 idx, out IDxcBlob ppResult) GetPartContent;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcContainerReflection * self, uint32 kind, out uint32 pResult) FindFirstPartKind;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcContainerReflection * self, uint32 idx, ref Guid iid, void *ppvObject) GetPartReflection;
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