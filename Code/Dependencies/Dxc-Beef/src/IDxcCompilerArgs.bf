using System;
namespace Dxc_Beef
{
	public struct IDxcCompilerArgs : IUnknown
	{
		public static new Guid IID = .(0x73EFFE2A, 0x70DC, 0x45F8, 0x96, 0x90, 0xEF, 0xF6, 0x4C, 0x02, 0x42, 0x9D);
		public static new Guid sCLSID = CLSID_DxcCompilerArgs;

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] char16**(IDxcCompilerArgs * self) GetArguments;
			public function [CallingConvention(.Stdcall)] uint32(IDxcCompilerArgs * self) GetCount;

			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcCompilerArgs * self,
				char16** pArguments,       // Array of pointers to arguments to add
				uint32 argCount                                // Number of arguments to add
				) AddArguments;

			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcCompilerArgs * self,
				char8** pArguments,         // Array of pointers to UTF-8 arguments to add
				uint32 argCount                                // Number of arguments to add
				) AddArgumentsUTF8;

			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcCompilerArgs * self,
				DxcDefine *pDefines, // Array of defines
				uint32 defineCount   // Number of defines
				) AddDefines;
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