using System;
using System.Collections;
using Sedulous.Image;

namespace Sedulous.Fonts;

/// Turns an atlas's coverage buffer into an image a renderer can upload.
static class FontAtlasTexture
{
	/// Expands single channel coverage into RGBA8: white everywhere, with the coverage as
	/// alpha.
	///
	/// White rather than the text colour, because the colour is a per draw thing and the
	/// texture is uploaded once. Tinting at draw time is what lets one atlas serve every
	/// colour of text on screen.
	///
	/// Null when there is nothing usable to expand, including an atlas whose buffer is
	/// SHORTER than its own dimensions claim, which is a half constructed atlas rather
	/// than an empty one.
	public static Image ExpandR8ToRGBA8(IFontAtlas atlas)
	{
		if (atlas == null)
			return null;

		let width = atlas.Width;
		let height = atlas.Height;
		if ((width == 0) || (height == 0))
			return null;

		let coverage = atlas.PixelData;
		let pixelCount = (int)width * (int)height;
		if (coverage.Length < pixelCount)
			return null;

		let rgba = scope List<uint8>();
		rgba.Resize(pixelCount * 4);
		for (int i < pixelCount)
		{
			rgba[i * 4 + 0] = 255;
			rgba[i * 4 + 1] = 255;
			rgba[i * 4 + 2] = 255;
			rgba[i * 4 + 3] = coverage[i];
		}
		return new Image(width, height, .RGBA8, .(rgba.Ptr, rgba.Count));
	}
}
