using System;
using Sedulous.Images;

namespace Sedulous.Fonts;

/// Utility for turning a font atlas (single-channel alpha pixels) into a
/// renderer-friendly RGBA8 image. Font atlases are stored R8 (the byte is
/// glyph coverage / alpha); rendering wants RGBA8 with white RGB and alpha
/// carrying coverage. Both `TrueTypeFontService` and `BakedFontService`
/// produce textures this way, so the conversion lives here once.
public static class FontAtlasTexture
{
	/// Expand the atlas's R8 alpha buffer into a freshly-allocated RGBA8
	/// `OwnedImageData`. Caller owns the returned image. Returns null if the
	/// atlas has no pixel data (e.g., 0x0 atlas dims).
	public static OwnedImageData ExpandR8ToRGBA8(IFontAtlas atlas)
	{
		if (atlas == null) return null;
		let w = atlas.Width;
		let h = atlas.Height;
		if (w == 0 || h == 0) return null;

		let r8 = atlas.PixelData;
		let pixelCount = (int)w * (int)h;
		if (r8.Length < pixelCount) return null;

		let rgba = new uint8[pixelCount * 4];
		for (int i = 0; i < pixelCount; i++)
		{
			rgba[i * 4 + 0] = 255;     // R
			rgba[i * 4 + 1] = 255;     // G
			rgba[i * 4 + 2] = 255;     // B
			rgba[i * 4 + 3] = r8[i];   // A = glyph coverage
		}
		return new OwnedImageData(w, h, .RGBA8, rgba);
	}
}
