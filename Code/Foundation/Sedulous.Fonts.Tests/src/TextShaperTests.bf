using System;
using System.IO;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;

namespace Sedulous.Fonts.Tests;

class TextShaperTests
{
	private static StringView[?] sSystemFontPaths = .(
		"C:/Windows/Fonts/arial.ttf",
		"C:/Windows/Fonts/segoeui.ttf"
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
	static void TestShapeText()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			let shaper = scope TrueTypeTextShaper();
			let positions = scope List<GlyphPosition>();

			if (shaper.ShapeText(font, "ABC", positions) case .Ok(let totalWidth))
			{
				Test.Assert(positions.Count == 3);
				Test.Assert(totalWidth > 0);

				// Positions should be in order
				Test.Assert(positions[0].X < positions[1].X);
				Test.Assert(positions[1].X < positions[2].X);

				// Each should have valid codepoint
				Test.Assert(positions[0].Codepoint == (int32)'A');
				Test.Assert(positions[1].Codepoint == (int32)'B');
				Test.Assert(positions[2].Codepoint == (int32)'C');
			}
			else
			{
				Test.FatalError("ShapeText failed");
			}
		}
	}

	[Test]
	static void TestShapeTextWithStartPosition()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			let shaper = scope TrueTypeTextShaper();
			let positions = scope List<GlyphPosition>();

			if (shaper.ShapeText(font, "AB", 100, 50, positions) case .Ok)
			{
				Test.Assert(positions.Count == 2);

				// First glyph should be at start position
				Test.Assert(positions[0].X == 100);
				Test.Assert(positions[0].Y == 50);
			}
		}
	}

	[Test]
	static void TestShapeTextWrapped()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			let shaper = scope TrueTypeTextShaper();
			let positions = scope List<GlyphPosition>();
			float totalHeight = 0;

			// Use a narrow max width to force wrapping
			let text = "Hello World";
			let wordWidth = font.MeasureString("Hello");
			let maxWidth = wordWidth + 10; // Just enough for "Hello "

			if (shaper.ShapeTextWrapped(font, text, maxWidth, positions, out totalHeight) case .Ok)
			{
				// Should have wrapped to multiple lines
				Test.Assert(totalHeight > font.Metrics.LineHeight);

				// Find if any glyph wrapped to Y > 0
				bool hasSecondLine = false;
				for (let pos in positions)
				{
					if (pos.Y > 0)
					{
						hasSecondLine = true;
						break;
					}
				}
				Test.Assert(hasSecondLine);
			}
		}
	}

	[Test]
	static void TestShapeTextNewlines()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			let shaper = scope TrueTypeTextShaper();
			let positions = scope List<GlyphPosition>();
			float totalHeight = 0;

			// Text with explicit newline
			if (shaper.ShapeTextWrapped(font, "A\nB", 1000, positions, out totalHeight) case .Ok)
			{
				// Should have characters on different lines
				// Note: newline itself is not in positions
				bool foundSecondLine = false;
				for (let pos in positions)
				{
					if (pos.Y > 0)
					{
						foundSecondLine = true;
						break;
					}
				}
				Test.Assert(foundSecondLine);
			}
		}
	}
}
