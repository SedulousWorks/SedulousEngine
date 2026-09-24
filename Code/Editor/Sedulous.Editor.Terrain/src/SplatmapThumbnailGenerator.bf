using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.VFS;
using Sedulous.Terrain.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain;

/// A splatmap's thumbnail: each texel's four slot weights blended between four fixed slot
/// colours, box filtered to the tile, so a painted region reads as a distinct hue per
/// dominant slot.
///
/// The payload is either the encoded source image as stored, or, for an embedded raster,
/// "SPLT" then the width and height as little endian u32 then the raw four byte texels of
/// the weight stream.
class SplatmapThumbnailGenerator : IThumbnailGenerator
{
	private const int cRawHeader = 12;

	private static readonly uint8[4][3] cSlotColor = .(
		.(96, 128, 72),   // moss
		.(168, 138, 92),  // sand
		.(110, 116, 128), // rock
		.(196, 186, 74)   // gold
		);

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("SplatmapAsset");

	public Result<void, ErrorCode> Prepare(Instance instance, IFileSystem sources,
		ThumbnailPrepared outPrepared)
	{
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as SplatmapAsset;
		if (asset == null)
			return .Err(.InvalidArgument);
		if (!asset.FileName.IsEmpty)
		{
			let stream = sources.Open(asset.FileName.Value, .Read);
			if ((stream != null) && stream.IsValid)
			{
				// Handed over UNREAD: the encoded image is drained on the worker, no header.
				outPrepared.TakeStream(stream);
				return .Ok;
			}
			delete stream;
		}
		let weights = instance.ReadData("pixels");
		if (weights == null)
			return .Err(.NotFound);
		// The header says how large the raster is; the weights follow from the stream, on the
		// worker.
		WriteRawHeader(outPrepared.Header, (uint32)Math.Max(asset.Width, 1),
			(uint32)Math.Max(asset.Height, 1));
		outPrepared.TakeStream(weights);
		return .Ok;
	}

	/// The raw payload header for a `width` by `height` raster.
	public static void WriteRawHeader(List<uint8> outPayload, uint32 width, uint32 height)
	{
		outPayload.Add((uint8)'S');
		outPayload.Add((uint8)'P');
		outPayload.Add((uint8)'L');
		outPayload.Add((uint8)'T');
		AppendU32(outPayload, width);
		AppendU32(outPayload, height);
	}

	private static void AppendU32(List<uint8> outPayload, uint32 value)
	{
		for (int shift = 0; shift < 32; shift += 8)
			outPayload.Add((uint8)((value >> shift) & 0xff));
	}

	private static uint32 ReadU32(Span<uint8> payload, int at)
	{
		return (uint32)payload[at] | ((uint32)payload[at + 1] << 8) | ((uint32)payload[at + 2] << 16) | ((uint32)payload[at + 3] << 24);
	}

	public Result<void, ErrorCode> Generate(Span<uint8> payload, Image outImage)
	{
		uint8* weights = null;
		uint32 width = 0;
		uint32 height = 0;
		let decoded = scope Image();
		if ((payload.Length > cRawHeader) && (payload[0] == (uint8)'S') && (payload[1] == (uint8)'P') && (payload[2] == (uint8)'L') && (payload[3] == (uint8)'T'))
		{
			width = ReadU32(payload, 4);
			height = ReadU32(payload, 8);
			let expected = (int)width * (int)height * 4;
			if ((width == 0) || (height == 0) || (payload.Length - cRawHeader < expected))
				return .Err(.InvalidArgument);
			weights = payload.Ptr + cRawHeader;
		}
		else
		{
			if (ImageIO.LoadImageFromMemory(payload, decoded) case .Err(let error))
				return .Err(error);
			if (decoded.Format != .RGBA8)
				return .Err(.InvalidArgument);
			weights = decoded.PixelData.Ptr;
			width = decoded.Width;
			height = decoded.Height;
		}
		if ((width == 0) || (height == 0))
			return .Err(.InvalidArgument);

		let tile = ThumbnailService.cThumbnailSize;
		let dst = scope uint8[(int)tile * (int)tile * 4];
		for (uint32 y < tile)
		{
			let y0 = y * height / tile;
			let y1 = Math.Max(y0 + 1, (y + 1) * height / tile);
			for (uint32 x < tile)
			{
				let x0 = x * width / tile;
				let x1 = Math.Max(x0 + 1, (x + 1) * width / tile);
				uint32[4] slot = .(0, 0, 0, 0);
				uint32 n = 0;
				for (uint32 sy = y0; sy < y1; sy++)
				{
					for (uint32 sx = x0; sx < x1; sx++)
					{
						let p = ((int)sy * (int)width + (int)sx) * 4;
						for (int k < 4)
							slot[k] += weights[p + k];
						n++;
					}
				}
				uint32 total = 0;
				uint32[3] color = .(0, 0, 0);
				for (int k < 4)
				{
					let w = slot[k] / n;
					total += w;
					for (int c < 3)
						color[c] += (uint32)cSlotColor[k][c] * w;
				}
				let texel = ((int)y * (int)tile + (int)x) * 4;
				for (int c < 3)
					dst[texel + c] = (uint8)((total > 0) ? Math.Min(color[c] / total, 255u) : 30u);
				dst[texel + 3] = 255;
			}
		}
		outImage.ReplaceData(tile, tile, .RGBA8, dst);
		return .Ok;
	}

	private static Result<void, ErrorCode> ReadAll(IStream stream, List<uint8> outBytes)
	{
		let size = (int)stream.Size();
		if (size <= 0)
			return .Err(.NotFound);
		outBytes.Resize(size);
		stream.Seek(0, .Begin);
		let read = stream.Read(Span<uint8>(outBytes.Ptr, size));
		return (read == size) ? .Ok : .Err(.Internal);
	}
}
