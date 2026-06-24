namespace Sedulous.Editor;

using System;
using Sedulous.Fonts;
using Sedulous.Fonts.Resources;
using Sedulous.Images;
using Sedulous.Resources;
using Sedulous.Editor.Core;

/// Generates thumbnails for `.font` assets by sampling the font's pre-rasterized
/// atlas. Renders the glyphs 'A' and 'a' side-by-side, expanded from single-
/// channel alpha to RGBA8 (white-on-transparent) so the preview composes over
/// any cell background. Scales down to fit the requested thumbnail size while
/// preserving aspect ratio; small glyphs are letterboxed rather than enlarged.
/// CPU-only - reuses the atlas that was already rasterized at load time.
class FontThumbnailGenerator : IAssetThumbnailGenerator
{
	private ResourceSystem mResourceSystem;

	public this(ResourceSystem resourceSystem)
	{
		mResourceSystem = resourceSystem;
	}

	public Result<OwnedImageData> GenerateThumbnail(StringView assetPath, int32 width, int32 height)
	{
		if (mResourceSystem == null || width <= 0 || height <= 0)
			return .Err;

		ResourceHandle<FontResource> handle;
		if (mResourceSystem.LoadResource<FontResource>(assetPath) case .Ok(let h))
			handle = h;
		else
			return .Err;
		defer handle.Release();

		let res = handle.Resource;
		if (res == null || res.Atlas == null)
			return .Err;

		let atlas = res.Atlas;
		AtlasRegion upper;
		AtlasRegion lower;
		if (!atlas.TryGetRegion((int32)'A', out upper))
			return .Err;
		if (!atlas.TryGetRegion((int32)'a', out lower))
			return .Err;

		// Lay out the two glyphs side-by-side respecting their natural
		// horizontal advances; align them to a shared baseline derived from
		// the maximum descent across both.
		let gap = (int32)2;
		let pairW = (int32)upper.Width + gap + (int32)lower.Width;
		let pairH = (int32)Math.Max((int32)upper.Height, (int32)lower.Height);
		if (pairW <= 0 || pairH <= 0)
			return .Err;

		// Compute uniform scale to fit the thumbnail with a small margin.
		// Letterbox (no enlargement) for fonts whose atlas glyphs are already
		// smaller than the thumbnail - scaling up alpha glyphs would just
		// blur them.
		let marginPx = (int32)Math.Max(2, width / 10);
		let availW = width - marginPx * 2;
		let availH = height - marginPx * 2;
		let scaleW = (float)availW / (float)pairW;
		let scaleH = (float)availH / (float)pairH;
		var scale = Math.Min(scaleW, scaleH);
		if (scale > 1.0f) scale = 1.0f;
		if (scale <= 0) return .Err;

		let drawW = (int32)((float)pairW * scale);
		let drawH = (int32)((float)pairH * scale);
		let offsetX = (width - drawW) / 2;
		let offsetY = (height - drawH) / 2;

		// RGBA8 output buffer, zero-initialized (transparent).
		let dst = new uint8[width * height * 4];

		// Blit one glyph from the atlas into the output. The atlas is single-
		// channel 8-bit alpha; we expand to RGBA8 with white RGB and the
		// alpha sample.
		void BlitGlyph(AtlasRegion region, int32 outX, int32 outY, int32 outW, int32 outH)
		{
			let atlasW = (int32)atlas.Width;
			let pixels = atlas.PixelData;
			for (int32 dy = 0; dy < outH; dy++)
			{
				let sy = (int32)((int64)dy * region.Height / (int64)outH);
				let pxY = outY + dy;
				if (pxY < 0 || pxY >= height) continue;
				for (int32 dx = 0; dx < outW; dx++)
				{
					let sx = (int32)((int64)dx * region.Width / (int64)outW);
					let pxX = outX + dx;
					if (pxX < 0 || pxX >= width) continue;

					let srcIdx = (int32)((int)(region.Y + sy) * atlasW + (region.X + sx));
					if (srcIdx < 0 || srcIdx >= pixels.Length) continue;

					let alpha = pixels[srcIdx];
					let di = (pxY * width + pxX) * 4;
					dst[di + 0] = 255; // R
					dst[di + 1] = 255; // G
					dst[di + 2] = 255; // B
					dst[di + 3] = alpha;
				}
			}
		}

		let upperW = (int32)((float)upper.Width * scale);
		let upperH = (int32)((float)upper.Height * scale);
		let lowerW = (int32)((float)lower.Width * scale);
		let lowerH = (int32)((float)lower.Height * scale);
		let gapPx = (int32)((float)gap * scale);

		// Place 'A' on the left, 'a' on the right, both vertically centered
		// within the drawing band. Proper baseline alignment using
		// region OffsetY would be nicer but isn't necessary at thumbnail size.
		BlitGlyph(upper, offsetX, offsetY + (drawH - upperH) / 2, upperW, upperH);
		BlitGlyph(lower, offsetX + upperW + gapPx, offsetY + (drawH - lowerH) / 2, lowerW, lowerH);

		return .Ok(new OwnedImageData((uint32)width, (uint32)height, .RGBA8, dst));
	}
}
