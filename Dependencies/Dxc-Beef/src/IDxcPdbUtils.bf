using System;
namespace Dxc_Beef
{
	public struct IDxcPdbUtils : IUnknown
	{
		public static new Guid IID = .(0xE6C9647E, 0x9D6A, 0x4C3B, 0xB9, 0x4C, 0x52, 0x4B, 0x5A, 0x6C, 0x34, 0x3D);
		public static new Guid sCLSID = CLSID_DxcPdbUtils;

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, IDxcBlob *pPdbOrDxil) Load;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out uint32 pCount) GetSourceCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self,  uint32 uIndex, out IDxcBlobEncoding *ppResult) GetSource;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self,  uint32 uIndex, out BSTR *pResult) GetSourceName;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out uint32 pCount) GetFlagCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self,  uint32 uIndex, out BSTR *pResult) GetFlag;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out uint32 pCount) GetArgCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self,  uint32 uIndex, out BSTR *pResult) GetArg;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out uint32 pCount) GetArgPairCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self,  uint32 uIndex, out BSTR *pName, out BSTR *pValue) GetArgPair;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out uint32 pCount) GetDefineCount;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self,  uint32 uIndex, out BSTR *pResult) GetDefine;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out BSTR *pResult) GetTargetProfile;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out BSTR *pResult) GetEntryPoint;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out BSTR *pResult) GetMainFileName;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out IDxcBlob *ppResult) GetHash;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out BSTR *pResult) GetName;

			public function [CallingConvention(.Stdcall)] bool(IDxcPdbUtils * self) IsFullPDB;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out IDxcBlob *ppFullPDB) GetFullPDB;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out IDxcVersionInfo* ppVersionInfo) GetVersionInfo;

			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self,  IDxcCompiler3 *pCompiler) SetCompiler;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self, out IDxcResult *ppResult) CompileForFullPDB;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self,  DxcArgPair *pArgPairs, uint32 uNumArgPairs) OverrideArgs;
			public function [CallingConvention(.Stdcall)] HRESULT(IDxcPdbUtils * self,  char16 *pRootSignature) OverrideRootSignature;
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