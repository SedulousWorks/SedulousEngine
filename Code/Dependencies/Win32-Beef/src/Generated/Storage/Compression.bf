using Win32.Foundation;
using System;

namespace Win32.Storage.Compression;

#region Constants
public static
{
	public const uint32 COMPRESS_ALGORITHM_INVALID = 0;
	public const uint32 COMPRESS_ALGORITHM_NULL = 1;
	public const uint32 COMPRESS_ALGORITHM_MAX = 6;
	public const uint32 COMPRESS_RAW = 536870912;
}
#endregion

#region TypeDefs
typealias COMPRESSOR_HANDLE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum COMPRESS_ALGORITHM : uint32
{
	COMPRESS_ALGORITHM_MSZIP = 2,
	COMPRESS_ALGORITHM_XPRESS = 3,
	COMPRESS_ALGORITHM_XPRESS_HUFF = 4,
	COMPRESS_ALGORITHM_LZMS = 5,
}


[AllowDuplicates]
public enum COMPRESS_INFORMATION_CLASS : int32
{
	COMPRESS_INFORMATION_CLASS_INVALID = 0,
	COMPRESS_INFORMATION_CLASS_BLOCK_SIZE = 1,
	COMPRESS_INFORMATION_CLASS_LEVEL = 2,
}

#endregion

#region Function Pointers
public function void* PFN_COMPRESS_ALLOCATE(void* UserContext, uint Size);

public function void PFN_COMPRESS_FREE(void* UserContext, void* Memory);

#endregion

#region Structs
[CRepr]
public struct COMPRESS_ALLOCATION_ROUTINES
{
	public PFN_COMPRESS_ALLOCATE Allocate;
	public PFN_COMPRESS_FREE Free;
	public void* UserContext;
}

#endregion

#region Functions
public static
{
	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateCompressor(COMPRESS_ALGORITHM Algorithm, COMPRESS_ALLOCATION_ROUTINES* AllocationRoutines, int* CompressorHandle);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCompressorInformation(COMPRESSOR_HANDLE CompressorHandle, COMPRESS_INFORMATION_CLASS CompressInformationClass, void* CompressInformation, uint CompressInformationSize);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryCompressorInformation(COMPRESSOR_HANDLE CompressorHandle, COMPRESS_INFORMATION_CLASS CompressInformationClass, void* CompressInformation, uint CompressInformationSize);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Compress(COMPRESSOR_HANDLE CompressorHandle, void* UncompressedData, uint UncompressedDataSize, void* CompressedBuffer, uint CompressedBufferSize, uint* CompressedDataSize);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResetCompressor(COMPRESSOR_HANDLE CompressorHandle);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseCompressor(COMPRESSOR_HANDLE CompressorHandle);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateDecompressor(COMPRESS_ALGORITHM Algorithm, COMPRESS_ALLOCATION_ROUTINES* AllocationRoutines, int* DecompressorHandle);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDecompressorInformation(int DecompressorHandle, COMPRESS_INFORMATION_CLASS CompressInformationClass, void* CompressInformation, uint CompressInformationSize);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL QueryDecompressorInformation(int DecompressorHandle, COMPRESS_INFORMATION_CLASS CompressInformationClass, void* CompressInformation, uint CompressInformationSize);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Decompress(int DecompressorHandle, void* CompressedData, uint CompressedDataSize, void* UncompressedBuffer, uint UncompressedBufferSize, uint* UncompressedDataSize);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResetDecompressor(int DecompressorHandle);

	[Import("Cabinet.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseDecompressor(int DecompressorHandle);

}
#endregion
