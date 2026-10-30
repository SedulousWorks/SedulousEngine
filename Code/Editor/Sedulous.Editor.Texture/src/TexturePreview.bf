using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.Editor.Texture;

/// A decoded source as the picture shows it, RGBA8: an RGBA8 image copied, an HDR one clamped to
/// eight bits (a faithful preview would need an exposure, which the page does not have), another
/// format converted. Null for an empty image. The caller owns the result.
static class TexturePreview
{
	public static Sedulous.Image.Image From(Sedulous.Image.Image source)
	{
		let w = source.Width;
		let h = source.Height;
		if ((w == 0) || (h == 0))
			return null;
		if (source.Format == .RGBA8)
			return new Sedulous.Image.Image(w, h, .RGBA8, source.PixelData);
		if (source.Format == .RGBA32F)
		{
			let raw = source.PixelData;
			let texels = (int)w * (int)h * 4;
			if (raw.Length < texels * sizeof(float))
				return null;
			let input = (float*)raw.Ptr;
			let output = new Sedulous.Image.Image(w, h, .RGBA8);
			let bytes = output.PixelData;
			for (int i < texels)
			{
				let c = Math.Clamp(input[i], 0.0f, 1.0f);
				bytes[i] = (uint8)Math.Min((int)(c * 255.0f + 0.5f), 255);
			}
			return output;
		}
		return source.ConvertFormat(.RGBA8);
	}
}
