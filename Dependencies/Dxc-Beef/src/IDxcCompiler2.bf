using System;
namespace Dxc_Beef
{
	public struct IDxcCompiler2 : IDxcCompiler
	{
		public static new Guid IID = .(0xA005A9D9, 0xB8BB, 0x4594, 0xB5, 0xC9, 0x0E, 0x63, 0x3B, 0xEC, 0x4D, 0x37);
		public static new Guid sCLSID = CLSID_DxcCompiler;

		public struct VTable : IDxcCompiler.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcCompiler2* self,
				IDxcBlob* pSource, // Source text to compile
				char16* pSourceName, // Optional file name for pSource. Used in errors and include handlers.
				char16* pEntryPoint, // Entry point name
				char16* pTargetProfile, // Shader profile to compile
				char16** pArguments, // Array of pointers to arguments
				uint32 argCount, // Number of arguments
				DxcDefine* pDefines, // Array of defines
				uint32 defineCount, // Number of defines
				IDxcIncludeHandler* pIncludeHandler, // user-provided interface to handle #include directives (optional)
				out IDxcOperationResult* ppResult, // Compiler output status, buffer, and errors
				out char16* ppDebugBlobName, // Suggested file name for debug blob. (Must be CoTaskMemFree()'d!)
				out IDxcBlob* ppDebugBlob // Debug blob
				) CompileWithDebug;
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