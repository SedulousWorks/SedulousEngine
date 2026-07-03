using System;
namespace Dxc_Beef
{
	public struct IDxcCompiler : IUnknown
	{
		public static new Guid IID = .(0x8c210bf3, 0x011f, 0x4422, 0x8d, 0x70, 0x6f, 0x9a, 0xcb, 0x8d, 0xb6, 0x17);
		public static new Guid sCLSID = CLSID_DxcCompiler;

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcCompiler* self,
				IDxcBlob* pSource, // Source text to compile
				char16* pSourceName, // Optional file name for pSource. Used in errors and include handlers.
				char16* pEntryPoint, // entry point name
				char16* pTargetProfile, // shader profile to compile
				char16** pArguments, // Array of pointers to arguments
				uint32 argCount, // Number of arguments
				DxcDefine *pDefines, // Array of defines
				uint32 defineCount, // Number of defines
				IDxcIncludeHandler *pIncludeHandler, // user-provided interface to handle #include directives (optional)
				out IDxcOperationResult* ppResult // Compiler output status, buffer, and errors
				) Compile;

			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcCompiler* self,
			  	IDxcBlob *pSource,                       // Source text to preprocess
			  	char16* pSourceName,               // Optional file name for pSource. Used in errors and include handlers.
			  	char16** pArguments, // Array of pointers to arguments
			  	uint32 argCount,                         // Number of arguments
			 	DxcDefine *pDefines,                  // Array of defines
			  	uint32 defineCount,                      // Number of defines
			  	IDxcIncludeHandler *pIncludeHandler, // user-provided interface to handle #include directives (optional)
			  	out IDxcOperationResult *ppResult   // Preprocessor output status, buffer, and errors
			) Preprocess;

			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcCompiler* self,
				IDxcBlob *pSource,                         // Program to disassemble.
				out IDxcBlobEncoding *ppDisassembly   // Disassembly text.
			)Disassemble;
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