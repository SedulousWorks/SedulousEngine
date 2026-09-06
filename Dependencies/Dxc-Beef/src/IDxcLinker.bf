using System;
namespace Dxc_Beef
{
	public struct IDxcLinker : IUnknown
	{
		public static new Guid IID = .(0xF1B5BE2A, 0x62DD, 0x4327, 0xA1, 0xC2, 0x42, 0xAC, 0x1E, 0x1E, 0x78, 0xE6);
		public static new Guid sCLSID = CLSID_DxcLinker;

		public struct VTable : IUnknown.VTable
		{
			public function [CallingConvention(.Stdcall)] HRESULT (
				IDxcLinker* self,
				char16* pLibName,          // Name of the library.
				IDxcBlob *pLib                 // Library blob.
				) RegisterLibrary;
			
			public function [CallingConvention(.Stdcall)] HRESULT (
				IDxcLinker* self,
				char16* pEntryName,        // Entry point name
				char16* pTargetProfile,        // shader profile to link
				char16** pLibNames,       // Array of library names to link
				uint32 libCount,               // Number of libraries to link
				char16** pArguments, // Array of pointers to arguments
				uint32 argCount,               // Number of arguments
				out IDxcOperationResult *ppResult  // Linker output status, buffer, and errors
				) Link;
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