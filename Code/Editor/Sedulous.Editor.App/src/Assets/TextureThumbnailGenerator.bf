namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Images;
using Sedulous.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Editor.Core;

/// Generates thumbnails for `.texture` assets by loading the TextureResource,
/// nearest-neighbor scaling its pixel data down to the requested dimensions,
/// and returning the result as `OwnedImageData`. CPU-only - no GPU work.
class TextureThumbnailGenerator : IAssetThumbnailGenerator
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

		// Load (or look up cached) the texture resource. The handle gets
		// released when this method returns - the thumbnail keeps a copy
		// of the scaled pixel data.
		ResourceHandle<TextureResource> handle;
		if (mResourceSystem.LoadResource<TextureResource>(assetPath) case .Ok(let h))
			handle = h;
		else
			return .Err;
		defer handle.Release();

		let res = handle.Resource;
		if (res == null || res.Image == null)
			return .Err;

		let src = res.Image;
		if (src.Width == 0 || src.Height == 0 || src.Data.Length == 0)
			return .Err;

		let bpp = Image.GetBytesPerPixel(src.Format);
		if (bpp == 0)
			return .Err;

		// HDR / float formats - tonemap into RGBA8 so the asset browser
		// can display them like any other thumbnail.
		switch (src.Format)
		{
		case .R16F, .RG16F, .RGB16F, .RGBA16F,
		     .R32F, .RG32F, .RGB32F, .RGBA32F:
			return ScaleFloatToRGBA8(src, width, height);
		default: break;
		}

		// 8-bit formats: nearest-neighbor downscale into a freshly-
		// allocated buffer in the source's own format. Cheap; box-
		// filter or mip-aware sampling is a follow-up.
		if (src.Format != .RGBA8 && src.Format != .RGB8 &&
			src.Format != .BGRA8 && src.Format != .BGR8 &&
			src.Format != .R8 && src.Format != .RG8)
			return .Err;

		let dstPixels = new uint8[width * height * bpp];
		let srcStride = (int32)src.Width * bpp;
		let dstStride = width * bpp;

		for (int32 dy = 0; dy < height; dy++)
		{
			let sy = (int32)((int64)dy * src.Height / (int64)height);
			let srcRowOff = (int)sy * srcStride;
			let dstRowOff = (int)dy * dstStride;
			for (int32 dx = 0; dx < width; dx++)
			{
				let sx = (int32)((int64)dx * src.Width / (int64)width);
				let srcOff = srcRowOff + (int)sx * bpp;
				let dstOff = dstRowOff + (int)dx * bpp;
				for (int b = 0; b < bpp; b++)
					dstPixels[dstOff + b] = src.Data[srcOff + b];
			}
		}

		return .Ok(new OwnedImageData((uint32)width, (uint32)height, src.Format, dstPixels));
	}

	/// Downsamples an HDR float image (16F or 32F, 1-4 channels) into
	/// a square 8-bit RGBA thumbnail. Sky textures and other HDR
	/// content land here. Tonemap is Reinhard (x / (1 + x)) - cheap,
	/// no-knobs, gives recognizable thumbnails for values that
	/// overshoot [0,1] without going pure-white from a hard clamp.
	private Result<OwnedImageData> ScaleFloatToRGBA8(Image src, int32 width, int32 height)
	{
		let channels = Image.GetChannelCount(src.Format);
		let isHalf = (src.Format == .R16F || src.Format == .RG16F ||
		              src.Format == .RGB16F || src.Format == .RGBA16F);
		let bytesPerChannel = isHalf ? 2 : 4;
		let srcBpp = (int32)channels * bytesPerChannel;
		let srcStride = (int32)src.Width * srcBpp;
		let dstPixels = new uint8[width * height * 4];

		for (int32 dy = 0; dy < height; dy++)
		{
			let sy = (int32)((int64)dy * src.Height / (int64)height);
			let srcRowOff = (int)sy * srcStride;
			let dstRowOff = (int)dy * (width * 4);
			for (int32 dx = 0; dx < width; dx++)
			{
				let sx = (int32)((int64)dx * src.Width / (int64)width);
				let srcOff = srcRowOff + (int)sx * srcBpp;
				let dstOff = dstRowOff + (int)dx * 4;

				float r = 0, g = 0, b = 0;
				float a = 1.0f;
				if (isHalf)
				{
					if (channels >= 1) r = MathUtil.HalfToFloat(*(uint16*)&src.Data[srcOff + 0]);
					if (channels >= 2) g = MathUtil.HalfToFloat(*(uint16*)&src.Data[srcOff + 2]);
					if (channels >= 3) b = MathUtil.HalfToFloat(*(uint16*)&src.Data[srcOff + 4]);
					if (channels >= 4) a = MathUtil.HalfToFloat(*(uint16*)&src.Data[srcOff + 6]);
				}
				else
				{
					if (channels >= 1) r = *(float*)&src.Data[srcOff + 0];
					if (channels >= 2) g = *(float*)&src.Data[srcOff + 4];
					if (channels >= 3) b = *(float*)&src.Data[srcOff + 8];
					if (channels >= 4) a = *(float*)&src.Data[srcOff + 12];
				}

				// Single-channel images (R-only) broadcast into greyscale.
				if (channels == 1) { g = r; b = r; }

				// Reinhard tonemap on color. Alpha is opacity, not radiance,
				// so it's clamped without tonemapping.
				r = r / (1.0f + Math.Max(0.0f, r));
				g = g / (1.0f + Math.Max(0.0f, g));
				b = b / (1.0f + Math.Max(0.0f, b));

				dstPixels[dstOff + 0] = (uint8)(Math.Clamp(r, 0.0f, 1.0f) * 255.0f + 0.5f);
				dstPixels[dstOff + 1] = (uint8)(Math.Clamp(g, 0.0f, 1.0f) * 255.0f + 0.5f);
				dstPixels[dstOff + 2] = (uint8)(Math.Clamp(b, 0.0f, 1.0f) * 255.0f + 0.5f);
				dstPixels[dstOff + 3] = (uint8)(Math.Clamp(a, 0.0f, 1.0f) * 255.0f + 0.5f);
			}
		}

		return .Ok(new OwnedImageData((uint32)width, (uint32)height, .RGBA8, dstPixels));
	}

}
