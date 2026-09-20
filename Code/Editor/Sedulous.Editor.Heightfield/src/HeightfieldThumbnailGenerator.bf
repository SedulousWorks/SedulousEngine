using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.VFS;
using Sedulous.Heightfield.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Heightfield;

/// A heightfield's thumbnail: the source image, or the embedded "heights" stream, box
/// filtered to the tile and normalised so a low relief field still fills the ramp.
///
/// The payload is either the encoded source image as stored, or, for an embedded field,
/// "R16 " then the side as a little endian u32 then the raw 16 bit samples.
class HeightfieldThumbnailGenerator : IThumbnailGenerator
{
	private const int cRawHeader = 8;

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("HeightfieldAsset");

	public Result<void, ErrorCode> Prepare(Instance instance, IFileSystem sources, List<uint8> outPayload)
	{
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as HeightfieldAsset;
		if (asset == null)
			return .Err(.InvalidArgument);
		if (!asset.FileName.IsEmpty)
		{
			let stream = sources.Open(asset.FileName.Value, .Read);
			if ((stream != null) && stream.IsValid)
			{
				defer delete stream;
				return ReadAll(stream, outPayload); // the encoded image bytes, no header
			}
			delete stream;
		}
		let heights = instance.ReadData("heights");
		if (heights == null)
			return .Err(.NotFound);
		defer delete heights;
		let samples = scope List<uint8>();
		if (ReadAll(heights, samples) case .Err(let error))
			return .Err(error);
		outPayload.Clear();
		WriteRawHeader(outPayload, (uint32)Math.Max(asset.Size, 1));
		outPayload.AddRange(samples);
		return .Ok;
	}

	/// The raw payload header for `side` samples a side.
	public static void WriteRawHeader(List<uint8> outPayload, uint32 side)
	{
		outPayload.Add((uint8)'R');
		outPayload.Add((uint8)'1');
		outPayload.Add((uint8)'6');
		outPayload.Add((uint8)' ');
		for (int shift = 0; shift < 32; shift += 8)
			outPayload.Add((uint8)((side >> shift) & 0xff));
	}

	public Result<void, ErrorCode> Generate(Span<uint8> payload, Image outImage)
	{
		uint16* samples = null;
		uint32 width = 0;
		uint32 height = 0;
		let decoded = scope Image();
		if ((payload.Length > cRawHeader) && (payload[0] == (uint8)'R') && (payload[1] == (uint8)'1') && (payload[2] == (uint8)'6') && (payload[3] == (uint8)' '))
		{
			let side = (uint32)payload[4] | ((uint32)payload[5] << 8) | ((uint32)payload[6] << 16) | ((uint32)payload[7] << 24);
			let expected = (int)side * (int)side * 2;
			if ((side == 0) || (payload.Length - cRawHeader < expected))
				return .Err(.InvalidArgument);
			samples = (uint16*)(payload.Ptr + cRawHeader);
			width = side;
			height = side;
		}
		else
		{
			if (ImageIO.LoadImage16FromMemory(payload, decoded) case .Err(let error))
				return .Err(error);
			samples = (uint16*)decoded.PixelData.Ptr;
			width = decoded.Width;
			height = decoded.Height;
		}
		if ((width == 0) || (height == 0))
			return .Err(.InvalidArgument);

		uint16 minSample = 65535;
		uint16 maxSample = 0;
		let count = (int)width * (int)height;
		for (int i < count)
		{
			minSample = Math.Min(minSample, samples[i]);
			maxSample = Math.Max(maxSample, samples[i]);
		}
		let range = Math.Max((uint32)1, (uint32)((uint32)maxSample - (uint32)minSample));
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
				uint64 sum = 0;
				uint32 n = 0;
				for (uint32 sy = y0; sy < y1; sy++)
				{
					for (uint32 sx = x0; sx < x1; sx++)
					{
						sum += samples[(int)sy * (int)width + (int)sx];
						n++;
					}
				}
				let normalized = ((uint32)(sum / n) - (uint32)minSample) * 255u / range;
				let g = (uint8)Math.Min(normalized, 255u);
				let texel = ((int)y * (int)tile + (int)x) * 4;
				dst[texel] = g;
				dst[texel + 1] = g;
				dst[texel + 2] = g;
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
