using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Texture;

namespace Sedulous.Texture.Resource;

/// Working out what a cooked payload contains, and where each piece goes.
///
/// Separated from the factory because it is ARITHMETIC over a record and a byte count, and
/// arithmetic that decides how far into a buffer to read deserves to be checkable without
/// standing up a device.
static class TextureUpload
{
	/// The writes a payload of `payloadBytes` supports, in order.
	///
	/// A TRUNCATED payload yields the levels it can satisfy and stops. Uploading what
	/// exists beats both alternatives: refusing gives a black texture with no clue why, and
	/// reading past the end is a crash somewhere else entirely.
	public static void EnumerateWrites(TextureResource record, int payloadBytes,
		List<TextureUploadWrite> outWrites)
	{
		if ((payloadBytes <= 0) || (record.Width == 0) || (record.Height == 0))
			return;

		if (record.Shape == .Cubemap)
		{
			EnumerateCubeFaces(record, payloadBytes, outWrites);
			return;
		}
		EnumerateMipChain(record, payloadBytes, outWrites);
	}

	/// Six faces at mip zero, in +X, -X, +Y, -Y, +Z, -Z order: the cook concatenates them
	/// in that order and each is one layer write.
	private static void EnumerateCubeFaces(TextureResource record, int payloadBytes,
		List<TextureUploadWrite> outWrites)
	{
		let compressed = TextureFormats.IsCompressed(record.Format);
		let faceBytes = compressed
			? (int)TextureFormats.CompressedLevelBytes(record.Format, record.Width, record.Height)
			: (int)record.Width * (int)record.Height
				* (int)TextureData.GetBytesPerPixel(record.Format);

		if (faceBytes <= 0)
			return;

		for (uint32 face = 0; face < 6; face++)
		{
			let offset = (int)face * faceBytes;
			if ((offset + faceBytes) > payloadBytes)
				break;

			var write = TextureUploadWrite();
			write.Offset = offset;
			write.ByteCount = faceBytes;
			write.Layout.BytesPerRow = compressed
				? TextureFormats.CompressedRowPitch(record.Format, record.Width)
				: record.Width * TextureData.GetBytesPerPixel(record.Format);
			write.Layout.RowsPerImage = compressed
				? RowsOfBlocks(record.Format, record.Height) : record.Height;
			write.Extent = .(record.Width, record.Height, 1);
			write.MipLevel = 0;
			write.ArrayLayer = face;
			outWrites.Add(write);
		}
	}

	/// The concatenated chain, largest level first. A payload holding only level zero
	/// uploads only that.
	private static void EnumerateMipChain(TextureResource record, int payloadBytes,
		List<TextureUploadWrite> outWrites)
	{
		let compressed = TextureFormats.IsCompressed(record.Format);
		let bytesPerPixel = TextureData.GetBytesPerPixel(record.Format);

		var offset = 0;
		var levelWidth = record.Width;
		var levelHeight = record.Height;

		for (uint32 level = 0; level < record.MipLevels; level++)
		{
			// A compressed level is measured by its BLOCK footprint, never per texel: an
			// 8x8 BC7 level is four blocks, and a 1x1 one still costs a whole block.
			let levelBytes = compressed
				? (int)TextureFormats.CompressedLevelBytes(record.Format, levelWidth, levelHeight)
				: (int)levelWidth * (int)levelHeight * (int)bytesPerPixel;

			if ((levelBytes <= 0) || ((offset + levelBytes) > payloadBytes))
				break;

			var write = TextureUploadWrite();
			write.Offset = offset;
			write.ByteCount = levelBytes;
			write.Layout.BytesPerRow = compressed
				? TextureFormats.CompressedRowPitch(record.Format, levelWidth)
				: levelWidth * bytesPerPixel;
			write.Layout.RowsPerImage = compressed
				? RowsOfBlocks(record.Format, levelHeight) : levelHeight;
			write.Extent = .(levelWidth, levelHeight, 1);
			write.MipLevel = level;
			write.ArrayLayer = 0;
			outWrites.Add(write);

			offset += levelBytes;
			levelWidth = Max((uint32)1, levelWidth >> 1);
			levelHeight = Max((uint32)1, levelHeight >> 1);
		}
	}

	/// Block rows, which is the RowsPerImage a compressed upload wants: the height rounded
	/// up to whole blocks, because a partial block still occupies one.
	private static uint32 RowsOfBlocks(TextureFormat format, uint32 height)
	{
		let blockHeight = TextureFormats.BlockHeight(format);
		return (height + blockHeight - 1) / blockHeight;
	}
}
