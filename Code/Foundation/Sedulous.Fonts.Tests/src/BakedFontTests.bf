using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.Baked;

namespace Sedulous.Fonts.Tests;

/// Pure-data tests for BakedFont + BakedFontAtlas. No rasterizer / no TTF -
/// the type's whole point is that it can be exercised with hand-rolled data.
class BakedFontTests
{
	[Test]
	static void TestBakedFontMetricsRoundTrip()
	{
		let font = scope BakedFont();
		font.SetFamilyName("Hand Rolled");
		font.SetPixelHeight(24);
		font.SetMetrics(.(20f, -5f, 2f, 24f, 0.0625f));

		Test.Assert(font.FamilyName == "Hand Rolled");
		Test.Assert(font.PixelHeight == 24);
		Test.Assert(font.Metrics.Ascent == 20f);
		Test.Assert(font.Metrics.Descent == -5f);
		Test.Assert(font.Metrics.LineGap == 2f);
		Test.Assert(font.Metrics.LineHeight == 27f); // ascent - descent + lineGap
		Test.Assert(font.Metrics.PixelHeight == 24);
		Test.Assert(font.Metrics.Scale == 0.0625f);
	}

	[Test]
	static void TestBakedFontGlyphTable()
	{
		let font = scope BakedFont();

		var infoA = GlyphInfo();
		infoA.Codepoint = (int32)'A';
		infoA.GlyphIndex = 17;
		infoA.AdvanceWidth = 12.5f;
		infoA.LeftSideBearing = 0.5f;
		infoA.BoundingBox = .(0, -10, 12, 10);
		infoA.HasBitmap = true;
		font.SetGlyph((int32)'A', infoA);

		Test.Assert(font.HasGlyph((int32)'A'));
		Test.Assert(!font.HasGlyph((int32)'Z'));

		let readback = font.GetGlyphInfo((int32)'A');
		Test.Assert(readback.AdvanceWidth == 12.5f);
		Test.Assert(readback.GlyphIndex == 17);
		Test.Assert(readback.HasBitmap);

		// Missing glyph returns a default-constructed GlyphInfo.
		let missing = font.GetGlyphInfo((int32)'Z');
		Test.Assert(missing.AdvanceWidth == 0);
		Test.Assert(!missing.HasBitmap);
	}

	[Test]
	static void TestBakedFontKerning()
	{
		let font = scope BakedFont();
		font.SetKerning((int32)'A', (int32)'V', -2.5f);
		font.SetKerning((int32)'T', (int32)'o', -1.0f);

		Test.Assert(font.GetKerning((int32)'A', (int32)'V') == -2.5f);
		Test.Assert(font.GetKerning((int32)'T', (int32)'o') == -1.0f);
		// Reversed pair was never set - returns 0.
		Test.Assert(font.GetKerning((int32)'V', (int32)'A') == 0);
		// Unknown pair returns 0.
		Test.Assert(font.GetKerning((int32)'X', (int32)'Y') == 0);
	}

	[Test]
	static void TestBakedFontMeasureStringUsesKerning()
	{
		let font = scope BakedFont();
		// Two single-codepoint glyphs with 10 advance each.
		var a = GlyphInfo();
		a.AdvanceWidth = 10f;
		var b = GlyphInfo();
		b.AdvanceWidth = 10f;
		font.SetGlyph((int32)'A', a);
		font.SetGlyph((int32)'B', b);
		font.SetKerning((int32)'A', (int32)'B', -3f);

		// "AB": advance(A) + kerning(A,B) + advance(B) = 10 + (-3) + 10 = 17.
		Test.Assert(font.MeasureString("AB") == 17f);
		// "BA" has no kerning entry -> 20.
		Test.Assert(font.MeasureString("BA") == 20f);
	}

	[Test]
	static void TestBakedFontMeasureStringWithGlyphPositions()
	{
		let font = scope BakedFont();
		var a = GlyphInfo();
		a.AdvanceWidth = 10f;
		var b = GlyphInfo();
		b.AdvanceWidth = 10f;
		font.SetGlyph((int32)'A', a);
		font.SetGlyph((int32)'B', b);
		font.SetKerning((int32)'A', (int32)'B', -3f);

		let positions = scope List<GlyphPosition>();
		let total = font.MeasureString("AB", positions);

		Test.Assert(total == 17f);
		Test.Assert(positions.Count == 2);
		Test.Assert(positions[0].X == 0);
		Test.Assert(positions[0].Codepoint == (int32)'A');
		// Second glyph is positioned after first advance + kerning adjustment.
		Test.Assert(positions[1].X == 7f);
		Test.Assert(positions[1].Codepoint == (int32)'B');
	}

	[Test]
	static void TestBakedFontAtlasSetPixelsTakesOwnership()
	{
		let atlas = scope BakedFontAtlas();
		let pixels = new uint8[64 * 64];
		for (int i = 0; i < pixels.Count; i++)
			pixels[i] = (uint8)(i & 0xFF);

		atlas.SetPixels(64, 64, pixels); // ownership transferred to atlas

		Test.Assert(atlas.Width == 64);
		Test.Assert(atlas.Height == 64);
		Test.Assert(atlas.PixelData.Length == 64 * 64);
		Test.Assert(atlas.PixelData[0] == 0);
		Test.Assert(atlas.PixelData[255] == 255);
	}

	[Test]
	static void TestBakedFontAtlasRegionTable()
	{
		let atlas = scope BakedFontAtlas();
		atlas.SetPixels(128, 128, new uint8[128 * 128]);
		atlas.SetWhitePixelUV(0.99f, 0.99f);

		var region = AtlasRegion(16, 32, 12, 14, 1.0f, -10.0f, 13.5f);
		atlas.SetRegion((int32)'A', region);

		Test.Assert(atlas.Contains((int32)'A'));
		Test.Assert(!atlas.Contains((int32)'Z'));

		AtlasRegion got;
		Test.Assert(atlas.TryGetRegion((int32)'A', out got));
		Test.Assert(got.X == 16);
		Test.Assert(got.Y == 32);
		Test.Assert(got.Width == 12);
		Test.Assert(got.Height == 14);
		Test.Assert(got.AdvanceX == 13.5f);

		let (u, v) = atlas.WhitePixelUV;
		Test.Assert(u == 0.99f);
		Test.Assert(v == 0.99f);
	}

	[Test]
	static void TestBakedFontAtlasGetGlyphQuadAdvances()
	{
		let atlas = scope BakedFontAtlas();
		atlas.SetPixels(128, 128, new uint8[128 * 128]);
		var region = AtlasRegion(16, 32, 12, 14, 1.0f, -10.0f, 13.5f);
		atlas.SetRegion((int32)'A', region);

		float cursorX = 100f;
		GlyphQuad quad;
		Test.Assert(atlas.GetGlyphQuad((int32)'A', ref cursorX, 50f, out quad));

		// Screen quad: cursor + offset + width/height.
		Test.Assert(quad.X0 == 101f);   // 100 + 1
		Test.Assert(quad.Y0 == 40f);    // 50 + -10
		Test.Assert(quad.X1 == 113f);   // 101 + 12
		Test.Assert(quad.Y1 == 54f);    // 40 + 14
		// Cursor advances by region.AdvanceX from the original cursor position.
		Test.Assert(cursorX == 113.5f); // 100 + 13.5
	}

	[Test]
	static void TestBakedFontAtlasGetGlyphQuadAtNoAdvance()
	{
		let atlas = scope BakedFontAtlas();
		atlas.SetPixels(64, 64, new uint8[64 * 64]);
		atlas.SetRegion((int32)'A', .(0, 0, 16, 16, 0, -16, 18));

		GlyphQuad quad;
		Test.Assert(atlas.GetGlyphQuadAt((int32)'A', 100f, 50f, out quad));
		Test.Assert(quad.X0 == 100f);
		Test.Assert(quad.Y0 == 34f); // 50 + -16
		// The non-advancing variant doesn't mutate any cursor.
		// (Verified by the absence of a ref parameter on GetGlyphQuadAt.)
	}

	[Test]
	static void TestBakedFontAtlasMissingGlyphReturnsFalse()
	{
		let atlas = scope BakedFontAtlas();
		atlas.SetPixels(64, 64, new uint8[64 * 64]);

		float cursorX = 0;
		GlyphQuad quad;
		Test.Assert(!atlas.GetGlyphQuad((int32)'?', ref cursorX, 0, out quad));
		Test.Assert(cursorX == 0); // unchanged on miss
	}
}
