using System;
using System.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;

namespace Sedulous.Fonts.Tests;

class TrueTypeFontTests
{
	// Common system font paths on Windows
	private static StringView[?] sSystemFontPaths = .(
		"C:/Windows/Fonts/arial.ttf",
		"C:/Windows/Fonts/segoeui.ttf",
		"C:/Windows/Fonts/tahoma.ttf",
		"C:/Windows/Fonts/verdana.ttf"
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
	static void TestLoadSystemFont()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
		{
			// Skip test if no system font available
			return;
		}

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			Test.Assert(font.PixelHeight == FontLoadOptions.Default.PixelHeight);
			Test.Assert(font.Metrics.Ascent > 0);
			Test.Assert(font.Metrics.Descent < 0); // Descent is typically negative
			Test.Assert(font.Metrics.LineHeight > 0);
		}
		else
		{
			Test.FatalError("Failed to load system font");
		}
	}

	[Test]
	static void TestFontGlyphInfo()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			// Test 'A' character
			let infoA = font.GetGlyphInfo((int32)'A');
			Test.Assert(infoA.Codepoint == (int32)'A');
			Test.Assert(infoA.GlyphIndex > 0); // Should have a valid glyph
			Test.Assert(infoA.AdvanceWidth > 0);
			Test.Assert(infoA.HasBitmap);

			// Test space character
			let spaceInfo = font.GetGlyphInfo((int32)' ');
			Test.Assert(spaceInfo.AdvanceWidth > 0); // Space should advance
			Test.Assert(!spaceInfo.HasBitmap); // Space typically has no visible pixels
		}
	}

	[Test]
	static void TestFontHasGlyph()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			// All printable ASCII should be present in standard fonts
			Test.Assert(font.HasGlyph((int32)'A'));
			Test.Assert(font.HasGlyph((int32)'z'));
			Test.Assert(font.HasGlyph((int32)'0'));
			Test.Assert(font.HasGlyph((int32)'!'));
		}
	}

	[Test]
	static void TestFontMeasureString()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			let width = font.MeasureString("Hello World");
			Test.Assert(width > 0);

			// Longer string should be wider
			let longerWidth = font.MeasureString("Hello World, this is longer!");
			Test.Assert(longerWidth > width);

			// Empty string should have zero width
			let emptyWidth = font.MeasureString("");
			Test.Assert(emptyWidth == 0);

			// 'W' is typically wider than 'i'
			let widthW = font.MeasureString("W");
			let widthI = font.MeasureString("i");
			Test.Assert(widthW > widthI);
		}
	}
}
