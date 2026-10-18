using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.TrueType.Tests;

/// Baking a real typeface into a coverage atlas.
class TrueTypeAtlasTests
{
	private static int32 Cp(char8 c) => (int32)c;

	private static TrueTypeFontAtlas Bake(TrueTypeFont font, FontLoadOptions options)
	{
		let baker = scope TrueTypeFontAtlasBaker();
		if (baker.Bake(font, options) case .Ok(let atlas))
			return (TrueTypeFontAtlas)atlas;
		return null;
	}

	[Test]
	public static void BakingFillsTheAtlas()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let atlas = Bake(font, .Default());
		Test.Assert(atlas != null);
		defer delete atlas;

		let options = FontLoadOptions.Default();
		Test.Assert(atlas.Width == options.AtlasWidth);
		Test.Assert(atlas.Height == options.AtlasHeight);
		Test.Assert(atlas.PixelData.Length == (int)options.AtlasWidth * (int)options.AtlasHeight);

		// Something was actually rasterised: an atlas of zeroes is a bake that silently
		// did nothing, which looks identical to a working one from the outside.
		int inked = 0;
		for (let coverage in atlas.PixelData)
		{
			if (coverage > 0)
				inked++;
		}
		Test.Assert(inked > 0, "the atlas is entirely blank");
	}

	/// The atlas holds the RANGE it was baked for and nothing else, whatever the font has.
	[Test]
	public static void ContainsRespectsTheBakedRange()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		var options = FontLoadOptions.Default();
		options.FirstCodepoint = Cp('A');
		options.LastCodepoint = Cp('Z');

		let atlas = Bake(font, options);
		Test.Assert(atlas != null);
		defer delete atlas;

		// The range's codepoints map to their glyphs, by glyph index; the rest to none.
		Test.Assert(atlas.Contains(atlas.GlyphFor(Cp('A'))));
		Test.Assert(atlas.Contains(atlas.GlyphFor(Cp('Z'))));
		Test.Assert(atlas.GlyphFor(Cp('A')) == font.GetGlyphInfo(Cp('A')).GlyphIndex);
		Test.Assert(atlas.GlyphFor(Cp('A')) != Cp('A'), "a glyph index, not the codepoint");
		Test.Assert(atlas.GlyphFor(Cp('a')) == -1, "outside the range, though the font has it");
		Test.Assert(font.HasGlyph(Cp('a')), "which is the point: the font has it, the bake did not");
		Test.Assert(atlas.GlyphFor(Cp('@')) == -1, "below the range");
		Test.Assert(!atlas.Contains(0));
	}

	[Test]
	public static void AQuadStepsTheCursorAndNamesTexels()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let atlas = Bake(font, .Default());
		Test.Assert(atlas != null);
		defer delete atlas;

		float cursorX = 100.0f;
		Test.Assert(atlas.GetGlyphQuad(atlas.GlyphFor(Cp('A')), ref cursorX, 50.0f, let quad));

		Test.Assert(cursorX > 100.0f, "the cursor moved past the glyph");
		Test.Assert(quad.Width > 0 && quad.Height > 0);

		// The UVs are normalised into the atlas, so they stay inside it.
		Test.Assert((quad.U0 >= 0.0f) && (quad.U1 <= 1.0f));
		Test.Assert((quad.V0 >= 0.0f) && (quad.V1 <= 1.0f));
		Test.Assert(quad.U1 > quad.U0);

		// The placed form draws the same shape without touching a cursor.
		float untouched = 100.0f;
		Test.Assert(atlas.GetGlyphQuadAt(atlas.GlyphFor(Cp('A')), 10.0f, 20.0f, let placed));
		Test.Assert(Abs(placed.Width - quad.Width) < 0.001f);
		Test.Assert(untouched == 100.0f);
	}

	/// A space packs as an advance-only record: mapped to its glyph, with no region and no quad,
	/// but a cursor stepped by its advance, as a baked atlas's advance-only region is.
	[Test]
	public static void ASpaceAdvancesWithNothingToDraw()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let atlas = Bake(font, .Default());
		Test.Assert(atlas != null);
		defer delete atlas;

		let space = atlas.GlyphFor(Cp(' '));
		Test.Assert(space > 0, "a space keeps its glyph");
		Test.Assert(!atlas.Contains(space), "with no pixels");
		Test.Assert(!atlas.TryGetRegion(space, ?));

		float cursorX = 100.0f;
		Test.Assert(!atlas.GetGlyphQuad(space, ref cursorX, 0.0f, ?));
		Test.Assert(Abs(cursorX - (100.0f + font.GetGlyphInfo(Cp(' ')).AdvanceWidth)) < 0.01f,
			scope $"the cursor stepped by the advance ({cursorX})");
	}

	/// A glyph no codepoint reaches, such as Roboto's fi ligature (glyph 868, what HarfBuzz shapes
	/// "fi" to), packs when asked for, drawn by its glyph index.
	[Test]
	public static void AGlyphNoCodepointReachesPacksWhenAskedFor()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		var options = FontLoadOptions.Default();
		options.FirstCodepoint = Cp('A');
		options.LastCodepoint = Cp('Z');
		let plain = scope TrueTypeFontAtlas();
		Test.Assert(plain.Create(font, options) == .Success);
		Test.Assert(!plain.Contains(868));

		let atlas = scope TrueTypeFontAtlas();
		int32[2] extras = .(868, 1000000);
		Test.Assert(atlas.Create(font, options, extras) == .Success);
		Test.Assert(atlas.Contains(868));
		Test.Assert(!atlas.Contains(1000000), "past the font's glyphs, so not packed");
		Test.Assert(atlas.Glyphs.Length == plain.Glyphs.Length + 1);
		float cursorX = 0.0f;
		Test.Assert(atlas.GetGlyphQuad(868, ref cursorX, 20.0f, let quad));
		Test.Assert((quad.Width > 0) && (cursorX > 0.0f));
	}

	[Test]
	public static void AnUnbakedGlyphIsRefusedWithoutMovingTheCursor()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		var options = FontLoadOptions.Default();
		options.FirstCodepoint = Cp('A');
		options.LastCodepoint = Cp('Z');
		let atlas = Bake(font, options);
		Test.Assert(atlas != null);
		defer delete atlas;

		float cursorX = 100.0f;
		Test.Assert(atlas.GlyphFor(Cp('a')) == -1);
		Test.Assert(!atlas.GetGlyphQuad(atlas.GlyphFor(Cp('a')), ref cursorX, 0.0f, let quad));
		Test.Assert(cursorX == 100.0f);
		Test.Assert(!atlas.TryGetRegion(atlas.GlyphFor(Cp('a')), let region));
	}

	/// The white texel is what lets a caret or an underline come from the SAME texture, and
	/// so the same draw call, as the text. It has to be inside the atlas and actually white.
	[Test]
	public static void TheWhiteTexelIsSolidAndInside()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let atlas = Bake(font, .Default());
		Test.Assert(atlas != null);
		defer delete atlas;

		let uv = atlas.WhitePixelUV;
		Test.Assert((uv.X > 0.0f) && (uv.X < 1.0f));
		Test.Assert((uv.Y > 0.0f) && (uv.Y < 1.0f));

		let x = (int)(uv.X * (float)atlas.Width);
		let y = (int)(uv.Y * (float)atlas.Height);
		Test.Assert(atlas.PixelData[y * (int)atlas.Width + x] == 255, "and it is fully opaque");
	}

	/// An atlas far too small for the range asked for fails rather than dropping the glyphs
	/// that did not fit: a page of missing boxes is much harder to diagnose than a refusal.
	[Test]
	public static void ARangeThatDoesNotFitIsRefused()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		var options = FontLoadOptions.Default();
		options.AtlasWidth = 8;
		options.AtlasHeight = 8;

		let baker = scope TrueTypeFontAtlasBaker();
		Test.Assert(baker.Bake(font, options) case .Err(.AtlasPackingFailed));
	}

	/// The baker takes coverage requests only. A distance field over the same font belongs
	/// to the MSDF baker, and the two are told apart by the mode alone.
	[Test]
	public static void TheBakerRefusesADistanceFieldRequest()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let baker = scope TrueTypeFontAtlasBaker();
		Test.Assert(baker.CanBake(font), "it can bake this font");
		Test.Assert(baker.CanBake(font, .Default()), "for a coverage request");
		Test.Assert(!baker.CanBake(font, .DistanceField()), "but not a distance field one");
	}
}
