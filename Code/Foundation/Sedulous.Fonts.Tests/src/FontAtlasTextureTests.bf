using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// Turning an atlas's coverage into an uploadable image.
class FontAtlasTextureTests
{
	[Test]
	public static void CoverageBecomesWhiteWithAlpha()
	{
		let atlas = scope CoverageAtlas(2, 2, scope uint8[](0, 64, 128, 255));

		let image = FontAtlasTexture.ExpandR8ToRGBA8(atlas);
		Test.Assert(image != null);
		defer delete image;

		Test.Assert(image.Width == 2 && image.Height == 2);
		Test.Assert(image.Format == .RGBA8);

		let pixels = image.PixelData;
		Test.Assert(pixels.Length == 16);
		for (int i < 4)
		{
			Test.Assert(pixels[i * 4 + 0] == 255, "white, so a draw can tint it any colour");
			Test.Assert(pixels[i * 4 + 1] == 255);
			Test.Assert(pixels[i * 4 + 2] == 255);
		}
		Test.Assert(pixels[3] == 0);
		Test.Assert(pixels[7] == 64);
		Test.Assert(pixels[11] == 128);
		Test.Assert(pixels[15] == 255);
	}

	/// Nothing to expand answers null rather than an empty image, so a caller cannot upload
	/// a texture that has no glyphs in it and wonder why the text is invisible.
	[Test]
	public static void AnAtlasWithNoPixelsExpandsToNothing()
	{
		Test.Assert(FontAtlasTexture.ExpandR8ToRGBA8(null) == null);

		let zeroSized = scope CoverageAtlas(0, 0, scope uint8[](0));
		Test.Assert(FontAtlasTexture.ExpandR8ToRGBA8(zeroSized) == null);
	}

	/// A buffer SHORTER than the dimensions claim is a half built atlas, and reading past
	/// its end would be the kind of corruption that shows up somewhere else entirely.
	[Test]
	public static void AShortBufferIsRefusedRatherThanOverrun()
	{
		let truncated = scope CoverageAtlas(4, 4, scope uint8[](1, 2, 3));
		Test.Assert(FontAtlasTexture.ExpandR8ToRGBA8(truncated) == null);
	}
}
