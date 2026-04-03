using System;
namespace Dxc_Beef
{
	public struct IDxcPdbUtils2 : IUnknown
	{
		public static new Guid IID = .(0x4315D938, 0xF369, 0x4F93, 0x95, 0xA2, 0x25, 0x20, 0x17, 0xCC, 0x38, 0x07);
		public static new Guid sCLSID = CLSID_DxcPdbUtils;

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, IDxcBlob* pPdbOrDxil) Load;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out uint32 pCount) GetSourceCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, uint32 uIndex, out IDxcBlobEncoding* ppResult) GetSource;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, uint32 uIndex, out IDxcBlobWide* ppResult) GetSourceName;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out uint32 pCount) GetLibraryPDBCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, uint32 uIndex, out IDxcPdbUtils2* ppOutPdbUtils, out IDxcBlobWide* ppLibraryName) GetLibraryPDB;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out uint32 pCount) GetFlagCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, uint32 uIndex, out IDxcBlobWide* ppResult) GetFlag;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out uint32 pCount) GetArgCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, uint32 uIndex, out IDxcBlobWide* ppResult) GetArg;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out uint32 pCount) GetArgPairCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, uint32 uIndex, out IDxcBlobWide* ppName, out IDxcBlobWide* ppValue) GetArgPair;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out uint32 pCount) GetDefineCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, uint32 uIndex, out IDxcBlobWide* ppResult) GetDefine;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out IDxcBlobWide* ppResult) GetTargetProfile;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out IDxcBlobWide* ppResult) GetEntryPoint;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out IDxcBlobWide* ppResult) GetMainFileName;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out IDxcBlob* ppResult) GetHash;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out IDxcBlobWide* ppResult) GetName;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out IDxcVersionInfo* ppVersionInfo) GetVersionInfo;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out uint32 pID) GetCustomToolchainID;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out IDxcBlob* ppBlob) GetCustomToolchainData;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils2* self, out IDxcBlob* ppResult) GetWholeDxil;

			public function [CallingConvention(.Stdcall)] bool(IDxcPdbUtils2* self) IsFullPDB;
			public function [CallingConvention(.Stdcall)] bool(IDxcPdbUtils2* self) IsPDBRef;
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
