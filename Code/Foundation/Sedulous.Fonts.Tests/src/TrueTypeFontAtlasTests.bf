using System;
using System.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;

namespace Sedulous.Fonts.Tests;

class TrueTypeFontAtlasTests
{
	private static StringView[?] sSystemFontPaths = .(
		"C:/Windows/Fonts/arial.ttf",
		"C:/Windows/Fonts/segoeui.ttf",
		"C:/Windows/Fonts/tahoma.ttf"
	);

	private static StringView GetAvailableSystemFont()
	{
		for (let path in sSystemFontPaths)
		{
			if (File.Exists(path))
				return path;
		}
		return .();
	}

	[Test]
	static void TestAtlasCreation()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			if (FontLoaderFactory.CreateAtlas(font, .Default) case .Ok(let atlas))
			{
				defer delete (Object)atlas;

				Test.Assert(atlas.Width == FontLoadOptions.Default.AtlasWidth);
				Test.Assert(atlas.Height == FontLoadOptions.Default.AtlasHeight);
				Test.Assert(atlas.PixelData.Length == (int)(atlas.Width * atlas.Height));
			}
			else
			{
				Test.FatalError("Failed to create atlas");
			}
		}
	}

	[Test]
	static void TestAtlasContains()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			if (FontLoaderFactory.CreateAtlas(font, .Default) case .Ok(let atlas))
			{
				defer delete (Object)atlas;

				// Printable ASCII should be in the atlas (default is 32-126)
				Test.Assert(atlas.Contains((int32)'A'));
				Test.Assert(atlas.Contains((int32)'z'));
				Test.Assert(atlas.Contains((int32)'0'));

				// Characters outside range should not be present
				Test.Assert(!atlas.Contains(0));
				Test.Assert(!atlas.Contains(31));
				Test.Assert(!atlas.Contains(127));
				Test.Assert(!atlas.Contains(200)); // Extended Latin not in default
			}
		}
	}

	[Test]
	static void TestAtlasGetGlyphQuad()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			if (FontLoaderFactory.CreateAtlas(font, .Default) case .Ok(let atlas))
			{
				defer delete (Object)atlas;

				float cursorX = 0;
				GlyphQuad quad = .();

				let result = atlas.GetGlyphQuad((int32)'A', ref cursorX, 0, out quad);
				Test.Assert(result);

				// Quad should have positive dimensions
				Test.Assert(quad.Width > 0);
				Test.Assert(quad.Height > 0);

				// UVs should be in [0, 1] range
				Test.Assert(quad.U0 >= 0 && quad.U0 <= 1);
				Test.Assert(quad.V0 >= 0 && quad.V0 <= 1);
				Test.Assert(quad.U1 >= 0 && quad.U1 <= 1);
				Test.Assert(quad.V1 >= 0 && quad.V1 <= 1);

				// Cursor should have advanced
				Test.Assert(cursorX > 0);
			}
		}
	}
}
