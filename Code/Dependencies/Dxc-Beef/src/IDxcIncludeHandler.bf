using System;
using System.IO;
namespace Dxc_Beef
{
	public struct IDxcIncludeHandler : IUnknown
	{
		public static Guid sIID = .(0x7f61fc7d, 0x950d, 0x467f, 0xb3, 0xe3, 0x3c, 0x02, 0xfb, 0x49, 0x18, 0x7c);

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcIncludeHandler* self, char16* pFilename, out IDxcBlob* ppIncludeSource) LoadSource;
		}

		protected new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}

		public HRESULT LoadSource(in StringView pFilename, out IDxcBlob* ppIncludeSource) mut
		{
			return VT.LoadSource(&this, pFilename.ToScopedNativeWChar!(), out ppIncludeSource);
		}
	}
}