namespace Sedulous.Engine.Navigation;

using System;
using recastnavigation_Beef;

/// Passthrough compressor implemented in Beef (no actual compression).
/// Can be extended to use real compression algorithms.
class TileCacheCompressor
{
	private dtTileCacheCompressorHandle mHandle;

	public this()
	{
		// Create compressor using Beef callbacks
		mHandle = dtCreateTileCacheCompressor(
			=> MaxCompressedSize,
			=> Compress,
			=> Decompress);
	}

	public ~this()
	{
		if (mHandle != null)
		{
			dtDestroyTileCacheCompressor(mHandle);
			mHandle = null;
		}
	}

	/// Gets the underlying handle.
	public dtTileCacheCompressorHandle Handle => mHandle;

	/// Callback: returns maximum compressed size for a buffer.
	private static int32 MaxCompressedSize(int32 bufferSize)
	{
		// Passthrough: compressed size equals original size
		return bufferSize;
	}

	/// Callback: compress data (passthrough - just copy).
	private static dtStatus Compress(uint8* buffer, int32 bufferSize,
		uint8* compressed, int32 maxCompressedSize, int32* compressedSize)
	{
		if (bufferSize > maxCompressedSize)
			return DT_FAILURE;

		Internal.MemCpy(compressed, buffer, bufferSize);
		*compressedSize = bufferSize;
		return DT_SUCCESS;
	}

	/// Callback: decompress data (passthrough - just copy).
	private static dtStatus Decompress(uint8* compressed, int32 compressedSize,
		uint8* buffer, int32 maxBufferSize, int32* bufferSize)
	{
		if (compressedSize > maxBufferSize)
			return DT_FAILURE;

		Internal.MemCpy(buffer, compressed, compressedSize);
		*bufferSize = compressedSize;
		return DT_SUCCESS;
	}
}
