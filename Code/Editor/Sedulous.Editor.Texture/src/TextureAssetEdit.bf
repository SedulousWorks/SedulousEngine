using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.Texture.Compression;
using Sedulous.Texture.Pipeline;

namespace Sedulous.Editor.Texture;

/// The texture page's headless halves: what a usage implies, the lint on a mismatch, the
/// cooked format read out, and the whole asset's binary snapshot the undo step carries.
static class TextureAssetEdit
{
	/// A colour texture is sRGB; every data usage is linear.
	public static ImageColorSpace ColorSpaceFor(SourceUsage usage) => (usage == .Color) ? .Srgb : .Linear;

	/// Data as sRGB warps the values, the warning that matters; colour as linear is unusual
	/// but legitimate. Empty when the pair is fine.
	public static StringView Lint(SourceUsage usage, ImageColorSpace colorSpace)
	{
		if ((usage != .Color) && (colorSpace == .Srgb))
			return "Normal/Mask/HDR maps are data - sRGB will warp the values. Set Linear.";
		if ((usage == .Color) && (colorSpace == .Linear))
			return "Color as Linear is unusual (fine for LUT-style data).";
		return "";
	}

	public static StringView CookedFormatName(TextureFormat format)
	{
		switch (format)
		{
		case .BC1RGBAUnorm: return "BC1 (opaque)";
		case .BC1RGBAUnormSrgb: return "BC1 sRGB (opaque)";
		case .BC4RUnorm: return "BC4 (single channel)";
		case .BC5RGUnorm: return "BC5 (normal RG)";
		case .BC7RGBAUnorm: return "BC7";
		case .BC7RGBAUnormSrgb: return "BC7 sRGB";
		case .ASTC4x4Unorm: return "ASTC 4x4";
		case .ASTC4x4UnormSrgb: return "ASTC 4x4 sRGB";
		case .RGBA32Float: return "RGBA32F (uncompressed)";
		default: return "uncompressed";
		}
	}

	/// The mip chain length for a full pyramid down to one texel.
	public static uint32 MipLevels(uint32 width, uint32 height)
	{
		uint32 levels = 1;
		var w = width;
		var h = height;
		while ((w > 1) || (h > 1))
		{
			w = (w > 1) ? w / 2 : 1;
			h = (h > 1) ? h / 2 : 1;
			levels++;
		}
		return levels;
	}

	/// What the cook will produce for the asset on the preview's pixels, one name, or two
	/// when desktop and mobile differ.
	public static void ResolvedFormatText(TextureAsset asset, ImageData preview, PixelFormat sourceFormat, String outText)
	{
		if (asset == null)
		{
			outText.Set("-");
			return;
		}
		let srgb = asset.ColorSpace == .Srgb;
		let width = (preview != null) ? preview.Width : 0;
		let height = (preview != null) ? preview.Height : 0;
		var hasAlpha = false;
		var multiChannel = false;
		if (preview != null)
		{
			let px = preview.PixelData;
			for (int i = 0; i + 3 < px.Length; i += 4)
			{
				if (px[i + 3] != 255)
				{
					hasAlpha = true;
					break;
				}
			}
			multiChannel = TextureCompression.HasDistinctChannels(px.Ptr, width, height);
		}
		let uncompressed = (sourceFormat == .RGBA32F) ? TextureFormat.RGBA32Float : TextureFormat.RGBA8Unorm;
		let desktop = TextureCompression.ResolveCompressedFormat(asset.Usage, srgb, hasAlpha, multiChannel, asset.Compression, width, height, .Desktop, uncompressed);
		let mobile = TextureCompression.ResolveCompressedFormat(asset.Usage, srgb, hasAlpha, multiChannel, asset.Compression, width, height, .Mobile, uncompressed);
		if (desktop == mobile)
			outText.Set(CookedFormatName(desktop));
		else
			outText.AppendF("{}  |  mobile: {}", CookedFormatName(desktop), CookedFormatName(mobile));
	}

	public static void Snapshot(TextureAsset asset, List<uint8> outBlob)
	{
		outBlob.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		outBlob.AddRange(stream.Bytes);
	}

	/// Restores a snapshot over `asset`; false when it already matched, nothing read.
	public static bool Apply(TextureAsset asset, Span<uint8> blob)
	{
		let current = scope List<uint8>();
		Snapshot(asset, current);
		if ((current.Count == blob.Length) && (Internal.MemCmp(current.Ptr, blob.Ptr, blob.Length) == 0))
			return false;
		let stream = scope MemoryStream();
		stream.Write(blob);
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		return true;
	}
}
