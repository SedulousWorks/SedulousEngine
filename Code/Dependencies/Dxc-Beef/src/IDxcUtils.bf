using System;
namespace Dxc_Beef
{
	public struct IDxcUtils : IUnknown
	{
		public static new Guid IID = .(0x4605C4CB, 0x2019, 0x492A, 0xAD, 0xA4, 0x65, 0xF2, 0x0B, 0xB7, 0xD6, 0x7F);
		public static new Guid sCLSID = CLSID_DxcUtils;

		public struct VTable : IUnknown.VTable
		{
			// Create a sub-blob that holds a reference to the outer blob and points to its memory.
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				IDxcBlob *pBlob, uint32 offset, uint32 length, out IDxcBlob *ppResult
			) CreateBlobFromBlob;

			// For codePage, use 0 (or DXC_CP_ACP) for raw binary or ANSI code page

			// Creates a blob referencing existing memory, with no copy.
			// User must manage the memory lifetime separately.
			// (was: CreateBlobWithEncodingFromPinned)
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				void* pData, uint32 size, uint32 codePage,
				out IDxcBlobEncoding *pBlobEncoding
			) CreateBlobFromPinned;

			// Create blob, taking ownership of memory allocated with supplied allocator.
			// (was: CreateBlobWithEncodingOnMalloc)
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				void* pData, IMalloc *pIMalloc, uint32 size, uint32 codePage,
				out IDxcBlobEncoding *pBlobEncoding
			) MoveToBlob;

			////
			// New blobs and copied contents are allocated with the current allocator

			// Copy blob contents to memory owned by the new blob.
			// (was: CreateBlobWithEncodingOnHeapCopy)
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				void* pData, uint32 size, uint32 codePage,
				out IDxcBlobEncoding *pBlobEncoding
			) CreateBlob;

			// (was: CreateBlobFromFile)
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				char16* pFileName, uint32* pCodePage,
				out IDxcBlobEncoding *pBlobEncoding
			) LoadFile;

			// Create default file-based include handler
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				IDxcBlob *pBlob, out IStream *ppStream
			) CreateReadOnlyStreamFromBlob;

			// Create default file-based include handler
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				out IDxcIncludeHandler *ppResult
			) CreateDefaultIncludeHandler;

			// Convert or return matching encoded text blobs
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				IDxcBlob *pBlob, out IDxcBlobUtf8 *pBlobEncoding
			) GetBlobAsUtf8;


			// Renamed from GetBlobAsUtf16 to GetBlobAsWide
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				 IDxcBlob *pBlob, out IDxcBlobWide *pBlobEncoding
			) GetBlobAsWide;

			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				DxcBuffer *pShader,
				uint32 DxcPart,
				out void *ppPartData,
				out uint32 pPartSizeInBytes
			) GetDxilContainerPart;

			// Create reflection interface from serialized Dxil container, or DXC_PART_REFLECTION_DATA.
			// TBD: Require part header for RDAT?  (leaning towards yes)
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				DxcBuffer *pData, ref Guid iid, void *ppvReflection
			) CreateReflection;
			
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				char16* pSourceName,               // Optional file name for pSource. Used in errors and include handlers.
				char16* pEntryPoint,               // Entry point name. (-E)
				char16* pTargetProfile,                // Shader profile to compile. (-T)
				char16* *pArguments, // Array of pointers to arguments
				uint32 argCount,                         // Number of arguments
				DxcDefine *pDefines,                  // Array of defines
				uint32 defineCount,                      // Number of defines
				out IDxcCompilerArgs *ppArgs        // Arguments you can use with Compile() method
			) BuildArguments;

			// Takes the shader PDB and returns the hash and the container inside it
			public function [CallingConvention(.Stdcall)] HRESULT(
				IDxcUtils* self,
				IDxcBlob *pPDBBlob, out IDxcBlob *ppHash, out IDxcBlob *ppContainer
			) GetPDBContents;
		}

		public new VTable* VT
		{
			get
			{
				return (.)mVT;
			}
		}

		public HRESULT CreateDefaultIncludeHandler(out IDxcIncludeHandler *ppResult) mut => VT.CreateDefaultIncludeHandler(&this, out ppResult);
	}

}