using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.Coverage;

namespace Sedulous.Fonts.Coverage.Tests;

/// The pre-rasterised atlas: a coverage buffer and a region per glyph.
class BakedFontAtlasTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;
	private static int32 Cp(char8 c) => (int32)c;

	/// A 128 by 128 atlas with one glyph at texels (16,32) sized 12 by 14, offset (1,-10)
	/// and advancing 13.5, so the arithmetic below can be checked by hand.
	/// Returns an OWNED atlas; `scope` cannot be applied to a call, so the caller defers a
	/// delete.
	private static BakedFontAtlas MakeAtlas(uint32 size = 128)
	{
		let atlas = new BakedFontAtlas();
		let pixels = new List<uint8>();
		pixels.Resize((int)size * (int)size);
		atlas.SetPixels(size, size, pixels);
		atlas.SetRegion(Cp('A'), .(16, 32, 12, 14, 1.0f, -10.0f, 13.5f));
		return atlas;
	}

	/// The buffer is TAKEN, not copied: an atlas is a megabyte or two and one copy per bake
	/// is worth avoiding.
	[Test]
	public static void SetPixelsTakesTheBuffer()
	{
		let atlas = scope BakedFontAtlas();
		let pixels = new List<uint8>();
		pixels.Resize(64 * 64);
		for (int i < pixels.Count)
			pixels[i] = (uint8)(i & 0xFF);

		let originalPointer = pixels.Ptr;
		atlas.SetPixels(64, 64, pixels);

		Test.Assert(atlas.Width == 64 && atlas.Height == 64);
		Test.Assert(atlas.PixelData.Length == 64 * 64);
		Test.Assert(atlas.PixelData[0] == 0);
		Test.Assert(atlas.PixelData[255] == 255);
		Test.Assert(atlas.PixelData.Ptr == originalPointer, "taken, not copied");
	}

	/// Setting a second buffer frees the first: an atlas rebaked at a new size must not
	/// leak the old one.
	[Test]
	public static void SetPixelsReplacesWhatWasHeld()
	{
		let atlas = scope BakedFontAtlas();

		let first = new List<uint8>();
		first.Resize(16);
		atlas.SetPixels(4, 4, first);

		let second = new List<uint8>();
		second.Resize(64);
		second[0] = 7;
		atlas.SetPixels(8, 8, second);

		Test.Assert(atlas.Width == 8 && atlas.Height == 8);
		Test.Assert(atlas.PixelData.Length == 64);
		Test.Assert(atlas.PixelData[0] == 7);
	}

	[Test]
	public static void TheRegionTableAnswersForWhatWasPacked()
	{
		let atlas = MakeAtlas();
		defer delete atlas;
		atlas.SetWhitePixelUV(0.99f, 0.99f);

		Test.Assert(atlas.Contains(Cp('A')));
		Test.Assert(!atlas.Contains(Cp('Z')));

		Test.Assert(atlas.TryGetRegion(Cp('A'), let region));
		Test.Assert(region.X == 16 && region.Y == 32);
		Test.Assert(region.Width == 12 && region.Height == 14);
		Test.Assert(Near(region.OffsetY, -10.0f));
		Test.Assert(Near(region.AdvanceX, 13.5f));

		Test.Assert(!atlas.TryGetRegion(Cp('Z'), let missing));
		Test.Assert(missing.IsEmpty, "and the out value is cleared, not left as it was");

		// The white texel is what lets a caret or an underline be drawn from the SAME
		// texture, and so the same draw call, as the text.
		Test.Assert(Near(atlas.WhitePixelUV.X, 0.99f));
		Test.Assert(Near(atlas.WhitePixelUV.Y, 0.99f));

		Test.Assert(atlas.Regions.Count == 1, "the table is readable for tooling");
	}

	[Test]
	public static void AQuadStepsTheCursorPastTheGlyph()
	{
		let atlas = MakeAtlas();
		defer delete atlas;

		float cursorX = 100.0f;
		Test.Assert(atlas.GetGlyphQuad(Cp('A'), ref cursorX, 50.0f, let quad));

		Test.Assert(Near(quad.X0, 101.0f), "100 plus the offset");
		Test.Assert(Near(quad.Y0, 40.0f), "50 minus 10");
		Test.Assert(Near(quad.X1, 113.0f), "101 plus the width");
		Test.Assert(Near(quad.Y1, 54.0f), "40 plus the height");
		Test.Assert(Near(cursorX, 113.5f), "and the cursor stepped by the ADVANCE, not the width");

		// The UVs are the region normalised into the atlas.
		Test.Assert(Near(quad.U0, 16.0f / 128.0f));
		Test.Assert(Near(quad.V0, 32.0f / 128.0f));
		Test.Assert(Near(quad.U1, 28.0f / 128.0f));
		Test.Assert(Near(quad.V1, 46.0f / 128.0f));
	}

	/// The absolute placement must not move the caller's cursor: it is for drawing a glyph
	/// somewhere chosen, not for walking a run of text.
	[Test]
	public static void APlacedQuadLeavesTheCursorAlone()
	{
		let atlas = MakeAtlas();
		defer delete atlas;

		float cursorX = 100.0f;
		Test.Assert(atlas.GetGlyphQuadAt(Cp('A'), 10.0f, 20.0f, let quad));
		Test.Assert(Near(quad.X0, 11.0f));
		Test.Assert(Near(quad.Y0, 10.0f));
		Test.Assert(Near(cursorX, 100.0f), "untouched");
	}

	/// A glyph the atlas does not have is reported, rather than drawn as whatever happened
	/// to be at those texels.
	[Test]
	public static void AMissingGlyphIsRefused()
	{
		let atlas = MakeAtlas();
		defer delete atlas;

		float cursorX = 100.0f;
		Test.Assert(!atlas.GetGlyphQuad(Cp('Z'), ref cursorX, 50.0f, let quad));
		Test.Assert(Near(cursorX, 100.0f), "and the cursor does not move for it");
		Test.Assert(Near(quad.Width, 0.0f), "the quad is cleared");

		Test.Assert(!atlas.GetGlyphQuadAt(Cp('Z'), 0.0f, 0.0f, let placed));
	}

	/// Whitespace has an advance and no pixels. False means nothing to draw, which is NOT
	/// the same as the glyph being missing: the cursor still moves.
	[Test]
	public static void WhitespaceAdvancesWithoutAQuad()
	{
		let atlas = MakeAtlas();
		defer delete atlas;
		atlas.SetRegion(Cp(' '), .(0, 0, 0, 0, 0, 0, 6.0f));

		float cursorX = 100.0f;
		Test.Assert(!atlas.GetGlyphQuad(Cp(' '), ref cursorX, 50.0f, let quad));
		Test.Assert(Near(cursorX, 106.0f), "stepped by the advance even though nothing was drawn");
	}

	/// A packer rasterises glyph bitmaps at oversample times the logical size while the
	/// offsets and advances it records stay logical. The screen span therefore divides back
	/// down; not doing so draws every glyph at twice its size, overlapping its neighbours,
	/// while the cursor still steps by the logical advance.
	[Test]
	public static void OversamplingShrinksTheSpanAndNothingElse()
	{
		let atlas = MakeAtlas();
		defer delete atlas;
		atlas.SetOversample(2.0f, 2.0f);
		Test.Assert(Near(atlas.OversampleX, 2.0f));

		float cursorX = 100.0f;
		Test.Assert(atlas.GetGlyphQuad(Cp('A'), ref cursorX, 50.0f, let quad));

		Test.Assert(Near(quad.X0, 101.0f), "the offset is logical and does not scale");
		Test.Assert(Near(quad.Width, 6.0f), "twelve raw texels are six logical pixels");
		Test.Assert(Near(quad.Height, 7.0f));
		Test.Assert(Near(cursorX, 113.5f), "the advance is logical too");

		// The UVs still name the RAW texels: the texture did not change.
		Test.Assert(Near(quad.U1, 28.0f / 128.0f));
	}

	/// A zero or negative factor would divide the span to infinity, so it is refused in
	/// favour of one.
	[Test]
	public static void ANonsenseOversampleFallsBackToOne()
	{
		let atlas = scope BakedFontAtlas();
		atlas.SetOversample(0.0f, -3.0f);
		Test.Assert(Near(atlas.OversampleX, 1.0f));
		Test.Assert(Near(atlas.OversampleY, 1.0f));
	}

	[Test]
	public static void ClearForReloadEmptiesInPlace()
	{
		let atlas = MakeAtlas();
		defer delete atlas;
		atlas.SetWhitePixelUV(0.5f, 0.5f);

		atlas.ClearForReload();

		Test.Assert(atlas.Width == 0 && atlas.Height == 0);
		Test.Assert(atlas.PixelData.Length == 0);
		Test.Assert(!atlas.Contains(Cp('A')));
		Test.Assert(Near(atlas.WhitePixelUV.X, 0.0f));

		// And it takes a fresh bake.
		let pixels = new List<uint8>();
		pixels.Resize(4);
		atlas.SetPixels(2, 2, pixels);
		atlas.SetRegion(Cp('B'), .(0, 0, 1, 1, 0, 0, 1.0f));
		Test.Assert(atlas.Contains(Cp('B')));
		Test.Assert(atlas.Width == 2);
	}

	/// An empty atlas answers an empty span rather than a pointer into nothing.
	[Test]
	public static void AnEmptyAtlasHasNoPixels()
	{
		let atlas = scope BakedFontAtlas();
		Test.Assert(atlas.PixelData.Length == 0);
		Test.Assert(atlas.PixelData.Ptr == null);
		Test.Assert(atlas.Mode == .Coverage, "a baked atlas is coverage unless it says otherwise");
		Test.Assert(Near(atlas.DistanceFieldRange, 0.0f));
	}
}
