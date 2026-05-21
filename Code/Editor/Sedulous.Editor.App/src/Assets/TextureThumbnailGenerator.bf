namespace Sedulous.Editor.App;

using System;
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

		// Only handle the common byte-per-channel formats for now. HDR /
		// half-float formats would need clamping + sRGB encoding to display
		// usefully at thumbnail size; deferring that to a follow-up.
		let bpp = Image.GetBytesPerPixel(src.Format);
		if (bpp == 0)
			return .Err;
		if (src.Format != .RGBA8 && src.Format != .RGB8 &&
			src.Format != .BGRA8 && src.Format != .BGR8 &&
			src.Format != .R8 && src.Format != .RG8)
			return .Err;

		// Nearest-neighbor downscale into a freshly-allocated buffer. Cheap;
		// good enough for thumbnails at small sizes. Box-filter or mip-aware
		// sampling is a follow-up.
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
}
