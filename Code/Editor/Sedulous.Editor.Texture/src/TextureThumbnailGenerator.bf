using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.VFS;
using Sedulous.Texture.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Texture;

/// A texture's thumbnail: the source image, or the embedded pixels, box filtered into the
/// tile, letterboxed transparent, alpha shown over a checker.
///
/// The payload is either the encoded source image as stored, or, for embedded pixels,
/// "RAW8" then the width and height as little endian u32s then the RGBA8 texels.
class TextureThumbnailGenerator : IThumbnailGenerator
{
	private const int cRawHeader = 12;

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("TextureAsset");

	public Result<void, ErrorCode> Prepare(Instance instance, IFileSystem sources,
		ThumbnailPrepared outPrepared)
	{
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as TextureAsset;
		if (asset == null)
			return .Err(.InvalidArgument);
		if (!asset.FileName.IsEmpty)
		{
			let stream = sources.Open(asset.FileName.Value, .Read);
			if ((stream != null) && stream.IsValid)
			{
				// Handed over UNREAD: the encoded file is drained on the worker.
				outPrepared.TakeStream(stream);
				return .Ok;
			}
			delete stream;
		}
		if ((asset.EmbeddedWidth > 0) && (asset.EmbeddedHeight > 0))
		{
			let stream = instance.ReadData("pixels");
			if (stream == null)
				return .Err(.NotFound);
			// The header says how to read the raw texels; the texels themselves follow from
			// the stream, on the worker.
			WriteRawHeader(outPrepared.Header, asset.EmbeddedWidth, asset.EmbeddedHeight);
			outPrepared.TakeStream(stream);
			return .Ok;
		}
		return .Err(.NotFound);
	}

	/// The raw payload header for `width` by `height` RGBA8 texels.
	public static void WriteRawHeader(List<uint8> outPayload, uint32 width, uint32 height)
	{
		outPayload.Add((uint8)'R');
		outPayload.Add((uint8)'A');
		outPayload.Add((uint8)'W');
		outPayload.Add((uint8)'8');
		AppendU32(outPayload, width);
		AppendU32(outPayload, height);
	}

	public Result<void, ErrorCode> Generate(Span<uint8> payload, Image outImage)
	{
		let source = scope Image();
		if ((payload.Length > cRawHeader) && (payload[0] == (uint8)'R') && (payload[1] == (uint8)'A') && (payload[2] == (uint8)'W') && (payload[3] == (uint8)'8'))
		{
			let width = ReadU32(payload, 4);
			let height = ReadU32(payload, 8);
			let expected = (int)width * (int)height * 4;
			if ((width == 0) || (height == 0) || (payload.Length - cRawHeader < expected))
				return .Err(.InvalidArgument);
			source.ReplaceData(width, height, .RGBA8, .(payload.Ptr + cRawHeader, expected));
		}
		else
		{
			if (ImageIO.LoadImageFromMemory(payload, source) case .Err(let error))
				return .Err(error);
		}
		return DownscaleIntoTile(source, outImage);
	}

	private static void AppendU32(List<uint8> payload, uint32 value)
	{
		for (int shift = 0; shift < 32; shift += 8)
			payload.Add((uint8)((value >> shift) & 0xff));
	}

	private static uint32 ReadU32(Span<uint8> payload, int at)
		=> (uint32)payload[at] | ((uint32)payload[at + 1] << 8) | ((uint32)payload[at + 2] << 16) | ((uint32)payload[at + 3] << 24);

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

	/// The source fit into the tile, centred; the letterbox stays transparent and any
	/// translucent texel composites over a checker so alpha reads at a glance.
	public static Result<void, ErrorCode> DownscaleIntoTile(Image source, Image outImage)
	{
		if (source.Format != .RGBA8)
			return .Err(.InvalidArgument); // the loaders yield RGBA8
		let tile = ThumbnailService.cThumbnailSize;
		let sourceW = source.Width;
		let sourceH = source.Height;
		if ((sourceW == 0) || (sourceH == 0))
			return .Err(.InvalidArgument);
		let scale = Math.Min((float)tile / sourceW, (float)tile / sourceH);
		let fitW = Math.Max((uint32)1, (uint32)(sourceW * scale));
		let fitH = Math.Max((uint32)1, (uint32)(sourceH * scale));
		let offsetX = (tile - fitW) / 2;
		let offsetY = (tile - fitH) / 2;
		let dst = scope uint8[(int)tile * (int)tile * 4]; // zero: a transparent letterbox
		let src = source.PixelData;
		for (uint32 y < fitH)
		{
			let y0 = y * sourceH / fitH;
			let y1 = Math.Max(y0 + 1, (y + 1) * sourceH / fitH);
			for (uint32 x < fitW)
			{
				let x0 = x * sourceW / fitW;
				let x1 = Math.Max(x0 + 1, (x + 1) * sourceW / fitW);
				uint32 r = 0, g = 0, b = 0, a = 0, n = 0;
				for (uint32 sy = y0; sy < y1; sy++)
				{
					for (uint32 sx = x0; sx < x1; sx++)
					{
						let p = ((int)sy * (int)sourceW + (int)sx) * 4;
						r += src[p];
						g += src[p + 1];
						b += src[p + 2];
						a += src[p + 3];
						n++;
					}
				}
				r /= n;
				g /= n;
				b /= n;
				a /= n;
				if (a < 255)
				{
					let check = (uint32)((((x / 8) + (y / 8)) % 2 == 0) ? 200 : 128);
					r = (r * a + check * (255 - a)) / 255;
					g = (g * a + check * (255 - a)) / 255;
					b = (b * a + check * (255 - a)) / 255;
					a = 255;
				}
				let q = ((int)(y + offsetY) * (int)tile + (int)(x + offsetX)) * 4;
				dst[q] = (uint8)r;
				dst[q + 1] = (uint8)g;
				dst[q + 2] = (uint8)b;
				dst[q + 3] = (uint8)a;
			}
		}
		outImage.ReplaceData(tile, tile, .RGBA8, dst);
		return .Ok;
	}
}
