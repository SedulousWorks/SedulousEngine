using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.Editor.Texture;

/// A decoded source as displayable RGBA8: an RGBA8 image copied, an HDR one tone clamped to
/// eight bits. Null for anything else, or an empty image. The caller owns the result.
static class TexturePreview
{
	public static OwnedImageData From(Image source)
	{
		let w = source.Width;
		let h = source.Height;
		if ((w == 0) || (h == 0))
			return null;
		if (source.Format == .RGBA8)
			return new OwnedImageData(w, h, .RGBA8, source.PixelData, source.ColorSpace);
		if (source.Format == .RGBA32F)
		{
			let raw = source.PixelData;
			let texels = (int)w * (int)h * 4;
			if (raw.Length < texels * sizeof(float))
				return null;
			let input = (float*)raw.Ptr;
			let output = new List<uint8>(); // handed to the image
			output.Resize(texels);
			for (int i < texels)
			{
				let c = Math.Clamp(input[i], 0.0f, 1.0f);
				output[i] = (uint8)Math.Min((int)(c * 255.0f + 0.5f), 255);
			}
			return new OwnedImageData(w, h, .RGBA8, output, .Srgb);
		}
		return null;
	}
}
