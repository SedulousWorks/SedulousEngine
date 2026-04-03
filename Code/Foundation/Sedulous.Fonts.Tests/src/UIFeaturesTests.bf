using System;
using System.IO;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;

namespace Sedulous.Fonts.Tests;

class UIFeaturesTests
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

	// === HitTestResult Tests ===

	[Test]
	static void TestHitTestResultInsertionIndex()
	{
		// Leading edge: insertion at same index
		var result = HitTestResult(5, false, true);
		Test.Assert(result.InsertionIndex == 5);

		// Trailing edge: insertion after character
		result = HitTestResult(5, true, true);
		Test.Assert(result.InsertionIndex == 6);
	}

	// === SelectionRange Tests ===

	[Test]
	static void TestSelectionRangeNormalization()
	{
		// Normal order
		var range = SelectionRange(2, 5);
		Test.Assert(range.Start == 2);
		Test.Assert(range.End == 5);
		Test.Assert(range.Length == 3);

		// Reversed order should normalize
		range = SelectionRange(5, 2);
		Test.Assert(range.Start == 2);
		Test.Assert(range.End == 5);
	}

	[Test]
	static void TestSelectionRangeEmpty()
	{
		var range = SelectionRange(3, 3);
		Test.Assert(range.IsEmpty);
		Test.Assert(range.Length == 0);

		range = SelectionRange(2, 5);
		Test.Assert(!range.IsEmpty);
	}

	[Test]
	static void TestSelectionRangeContains()
	{
		var range = SelectionRange(2, 5);
		Test.Assert(!range.Contains(1));
		Test.Assert(range.Contains(2));
		Test.Assert(range.Contains(3));
		Test.Assert(range.Contains(4));
		Test.Assert(!range.Contains(5)); // End is exclusive
	}

	// === TextDecorationMetrics Tests ===

	[Test]
	static void TestTextDecorationMetricsDefaults()
	{
		let metrics = TextDecorationMetrics();
		Test.Assert(metrics.UnderlineThickness == 1);
		Test.Assert(metrics.StrikethroughThickness == 1);
	}

	[Test]
	static void TestTextDecorationMetricsFromFont()
	{
		let metrics = TextDecorationMetrics.FromFontMetrics(24, 32);

		// Underline should be below baseline (positive)
		Test.Assert(metrics.UnderlinePosition > 0);

		// Strikethrough should be above baseline (negative)
		Test.Assert(metrics.StrikethroughPosition < 0);

		// Thickness should be reasonable
		Test.Assert(metrics.UnderlineThickness >= 1);
		Test.Assert(metrics.StrikethroughThickness >= 1);
	}

	// === HitTest Tests ===

	[Test]
	static void TestHitTestEmpty()
	{
		let shaper = scope TrueTypeTextShaper();
		let positions = scope List<GlyphPosition>();

		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			// Empty positions
			let result = shaper.HitTest(font, positions, 50, 0);
			Test.Assert(result.CharacterIndex == 0);
			Test.Assert(!result.IsInside);
		}
	}

	[Test]
	static void TestHitTestBeforeText()
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

			shaper.ShapeText(font, "Hello", 100, 0, positions);

			// Click before text
			let result = shaper.HitTest(font, positions, 50, 0);
			Test.Assert(result.CharacterIndex == 0);
			Test.Assert(!result.IsTrailingHit);
		}
	}

	[Test]
	static void TestHitTestMiddleOfText()
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

			shaper.ShapeText(font, "ABCDE", positions);

			if (positions.Count >= 3)
			{
				// Click in middle of 3rd character
				let pos = positions[2];
				let midX = pos.X + pos.Advance * 0.5f;

				let result = shaper.HitTest(font, positions, midX, 0);
				Test.Assert(result.CharacterIndex == 2);
				Test.Assert(result.IsInside);
			}
		}
	}

	[Test]
	static void TestHitTestTrailingEdge()
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

			shaper.ShapeText(font, "AB", positions);

			if (positions.Count >= 1)
			{
				// Click on trailing edge of first character
				let pos = positions[0];
				let trailingX = pos.X + pos.Advance * 0.75f;

				let result = shaper.HitTest(font, positions, trailingX, 0);
				Test.Assert(result.CharacterIndex == 0);
				Test.Assert(result.IsTrailingHit);
				Test.Assert(result.InsertionIndex == 1);
			}
		}
	}

	// === GetCursorPosition Tests ===

	[Test]
	static void TestGetCursorPositionStart()
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

			shaper.ShapeText(font, "Hello", 100, 0, positions);

			// Cursor at start
			let cursorX = shaper.GetCursorPosition(font, positions, 0);
			Test.Assert(cursorX == 100);
		}
	}

	[Test]
	static void TestGetCursorPositionEnd()
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

			shaper.ShapeText(font, "Hi", 0, 0, positions);

			if (positions.Count >= 2)
			{
				// Cursor at end
				let cursorX = shaper.GetCursorPosition(font, positions, (int32)positions.Count);
				let lastPos = positions[positions.Count - 1];
				let expectedX = lastPos.X + lastPos.Advance;
				Test.Assert(Math.Abs(cursorX - expectedX) < 0.01f);
			}
		}
	}

	[Test]
	static void TestGetCursorPositionMiddle()
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

			shaper.ShapeText(font, "ABC", positions);

			if (positions.Count >= 3)
			{
				// Cursor before character 1 (between A and B)
				let cursorX = shaper.GetCursorPosition(font, positions, 1);
				Test.Assert(cursorX == positions[1].X);
			}
		}
	}

	// === GetSelectionRects Tests ===

	[Test]
	static void TestGetSelectionRectsEmpty()
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
			let rects = scope List<Rect>();

			shaper.ShapeText(font, "Hello", positions);

			// Empty selection
			shaper.GetSelectionRects(font, positions, SelectionRange(2, 2), font.Metrics.LineHeight, rects);
			Test.Assert(rects.Count == 0);
		}
	}

	[Test]
	static void TestGetSelectionRectsSingleLine()
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
			let rects = scope List<Rect>();

			shaper.ShapeText(font, "Hello", positions);

			// Select "ell" (indices 1-4)
			shaper.GetSelectionRects(font, positions, SelectionRange(1, 4), font.Metrics.LineHeight, rects);

			// Should have exactly one rectangle for single line
			Test.Assert(rects.Count == 1);

			// Rectangle should have positive dimensions
			Test.Assert(rects[0].Width > 0);
			Test.Assert(rects[0].Height > 0);
		}
	}

	// === FontMetrics Decorations Tests ===

	[Test]
	static void TestFontMetricsHasDecorations()
	{
		let fontPath = GetAvailableSystemFont();
		if (fontPath.IsEmpty)
			return;

		TrueTypeFonts.Initialize();
		defer TrueTypeFonts.Shutdown();

		if (FontLoaderFactory.LoadFont(fontPath, .Default) case .Ok(let font))
		{
			defer delete (Object)font;

			let decorations = font.Metrics.Decorations;

			// Should have valid decoration metrics
			Test.Assert(decorations.UnderlineThickness >= 1);
			Test.Assert(decorations.StrikethroughThickness >= 1);
			Test.Assert(decorations.UnderlinePosition > 0); // Below baseline
			Test.Assert(decorations.StrikethroughPosition < 0); // Above baseline
		}
	}
}
