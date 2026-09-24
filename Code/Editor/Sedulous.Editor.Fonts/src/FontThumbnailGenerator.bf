using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.VFS;
using Sedulous.Fonts;
using Sedulous.Fonts.Coverage.Baker;
using Sedulous.Fonts.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Fonts;

/// A font's thumbnail: "Ag" at 72px from the source bytes, centred on the tile ground.
class FontThumbnailGenerator : IThumbnailGenerator
{
	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("FontAsset");

	public Result<void, ErrorCode> Prepare(Instance instance, IFileSystem sources,
		ThumbnailPrepared outPrepared)
	{
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as FontAsset;
		if ((asset == null) || asset.FileName.IsEmpty)
			return .Err(.InvalidArgument);
		let stream = sources.Open(asset.FileName.Value, .Read);
		if ((stream == null) || !stream.IsValid)
		{
			delete stream;
			return .Err(.NotFound);
		}
		if (stream.Size() <= 0)
		{
			delete stream;
			return .Err(.NotFound);
		}
		// Handed over UNREAD: the file is drained on the worker.
		outPrepared.TakeStream(stream);
		return .Ok;
	}

	public Result<void, ErrorCode> Generate(Span<uint8> payload, Image outImage)
	{
		var options = FontLoadOptions();
		options.PixelHeight = 72.0f;
		options.FirstCodepoint = (int32)'A';
		options.LastCodepoint = (int32)'g';
		options.AtlasWidth = 512;
		options.AtlasHeight = 512;
		options.OversampleX = 1;
		options.OversampleY = 1;
		if (!(FontBaker.Bake(payload, options) case .Ok(let data)))
			return .Err(.InvalidArgument);
		defer delete data;

		int32[2] sample = .((int32)'A', (int32)'g');
		AtlasRegion[2] regions = .(.(), .());
		for (int i < 2)
		{
			if (!data.Atlas.TryGetRegion(sample[i], out regions[i]))
				return .Err(.NotFound);
		}
		var pen = 0.0f;
		float minX = 0.0f, minY = 0.0f, maxX = 0.0f, maxY = 0.0f;
		for (int i < 2)
		{
			let r = regions[i];
			let x0 = pen + r.OffsetX;
			let y0 = r.OffsetY; // y down, negative above the baseline
			minX = (i == 0) ? x0 : Math.Min(minX, x0);
			minY = (i == 0) ? y0 : Math.Min(minY, y0);
			maxX = Math.Max(maxX, x0 + r.Width);
			maxY = Math.Max(maxY, y0 + r.Height);
			pen += r.AdvanceX;
		}
		let tile = ThumbnailService.cThumbnailSize;
		uint8[3] ground = .(26, 28, 33); // the GPU stage's tile ground
		uint8[3] ink = .(225, 227, 232);
		let dst = scope uint8[(int)tile * (int)tile * 4];
		for (int i = 0; i < dst.Count; i += 4)
		{
			dst[i] = ground[0];
			dst[i + 1] = ground[1];
			dst[i + 2] = ground[2];
			dst[i + 3] = 255;
		}
		let shiftX = (int32)((tile - (maxX - minX)) * 0.5f - minX);
		let shiftY = (int32)((tile - (maxY - minY)) * 0.5f - minY);
		let coverage = data.Atlas.PixelData;
		let atlasW = (int)data.Atlas.Width;
		pen = 0.0f;
		for (int i < 2)
		{
			let r = regions[i];
			let destX = (int32)(pen + r.OffsetX) + shiftX;
			let destY = (int32)r.OffsetY + shiftY;
			for (int32 sy < (int32)r.Height)
			{
				let y = destY + sy;
				if ((y < 0) || (y >= (int32)tile))
					continue;
				for (int32 sx < (int32)r.Width)
				{
					let x = destX + sx;
					if ((x < 0) || (x >= (int32)tile))
						continue;
					let alpha = (uint32)coverage[((int)r.Y + sy) * atlasW + ((int)r.X + sx)];
					if (alpha == 0)
						continue;
					let texel = ((int)y * (int)tile + (int)x) * 4;
					for (int c < 3)
						dst[texel + c] = (uint8)((ink[c] * alpha + dst[texel + c] * (255 - alpha)) / 255);
				}
			}
			pen += r.AdvanceX;
		}
		outImage.ReplaceData(tile, tile, .RGBA8, dst);
		return .Ok;
	}
}
