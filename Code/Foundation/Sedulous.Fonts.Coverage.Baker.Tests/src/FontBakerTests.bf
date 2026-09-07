using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.Coverage;
using Sedulous.Fonts.Coverage.Baker;

namespace Sedulous.Fonts.Coverage.Baker.Tests;

/// Baking a real typeface into the pair a packaged game ships.
class FontBakerTests
{
	private static int32 Cp(char8 c) => (int32)c;

	[Test]
	public static void BakingProducesGlyphsMetricsAndRegions()
	{
		let bytes = scope List<uint8>();
		Test.Assert(TestFontBytes.Read(bytes), "the Roboto fixture is present");

		Test.Assert(FontBaker.Bake(bytes, FontLoadOptions.Default()) case .Ok(let baked));
		defer delete baked;

		let family = scope String();
		baked.Font.GetFamilyName(family);
		Test.Assert(!family.IsEmpty, "the name table came across");

		Test.Assert(baked.Font.Metrics.Ascent > 0);
		Test.Assert(baked.Font.Metrics.Descent < 0, "descent is below the baseline");
		Test.Assert(baked.Font.Metrics.LineHeight > 0);
		Test.Assert(baked.Font.PixelHeight == FontLoadOptions.Default().PixelHeight);

		for (let codepoint in int32[](Cp('A'), Cp('z'), Cp('0')))
		{
			Test.Assert(baked.Font.HasGlyph(codepoint), scope $"font has {codepoint}");
			Test.Assert(baked.Atlas.Contains(codepoint), scope $"atlas has {codepoint}");
		}

		Test.Assert(baked.Font.GetGlyphInfo(Cp('A')).AdvanceWidth > 0);
	}

	/// The atlas comes out at the size that was ASKED for, not at whatever the packer chose,
	/// because the texture it will become is allocated against that number.
	[Test]
	public static void TheAtlasMatchesTheRequestedDimensions()
	{
		let bytes = scope List<uint8>();
		Test.Assert(TestFontBytes.Read(bytes));

		var options = FontLoadOptions.Default();
		options.AtlasWidth = 256;
		options.AtlasHeight = 256;
		options.FirstCodepoint = Cp('A');
		options.LastCodepoint = Cp('Z');

		Test.Assert(FontBaker.Bake(bytes, options) case .Ok(let baked));
		defer delete baked;

		Test.Assert(baked.Atlas.Width == 256);
		Test.Assert(baked.Atlas.Height == 256);
		Test.Assert(baked.Atlas.PixelData.Length == 256 * 256, "one byte of coverage per texel");

		// And only the requested range was baked.
		Test.Assert(baked.Atlas.Contains(Cp('A')));
		Test.Assert(baked.Atlas.Contains(Cp('Z')));
		Test.Assert(!baked.Atlas.Contains(Cp('a')), "outside the range, so not baked");
		Test.Assert(!baked.Font.HasGlyph(Cp('a')), "and not in the glyph table either");
	}

	[Test]
	public static void GarbageBytesAreRefusedWithoutLeaking()
	{
		let junk = scope List<uint8>();
		junk.Resize(256);
		for (int i < junk.Count)
			junk[i] = 0xAB;

		Test.Assert(FontBaker.Bake(junk, FontLoadOptions.Default()) case .Err);
		Test.Assert(FontBaker.Bake(.(), FontLoadOptions.Default()) case .Err, "and nothing at all");
	}

	/// Detach moves both out, and deleting the holder afterwards must not touch them: this
	/// is how a bake gets handed to a FontResource that outlives it.
	[Test]
	public static void DetachMovesBothOutAndTheHolderStopsOwningThem()
	{
		let bytes = scope List<uint8>();
		Test.Assert(TestFontBytes.Read(bytes));

		Test.Assert(FontBaker.Bake(bytes, FontLoadOptions.Default()) case .Ok(let baked));

		baked.Detach(let font, let atlas);
		Test.Assert(font != null);
		Test.Assert(atlas != null);
		Test.Assert(baked.Font == null, "the holder let go");
		Test.Assert(baked.Atlas == null);

		delete baked; // must not free what was taken

		// Still usable, which is the point: reading through them after the holder is gone.
		Test.Assert(font.HasGlyph(Cp('A')));
		Test.Assert(atlas.Contains(Cp('A')));

		delete font;
		delete atlas;
	}

	/// The baked pair reproduces what the rasterizer measured. A bake that dropped the
	/// kerning or the oversampling would still pass every check above, and lay text out
	/// differently from the font it came from.
	[Test]
	public static void TheBakedPairMeasuresTheSameAsWhatItWasBakedFrom()
	{
		let bytes = scope List<uint8>();
		Test.Assert(TestFontBytes.Read(bytes));

		var options = FontLoadOptions.Default();
		options.OversampleX = 3;
		options.OversampleY = 1;

		Test.Assert(FontBaker.Bake(bytes, options) case .Ok(let baked));
		defer delete baked;

		let source = scope Sedulous.Fonts.TrueType.TrueTypeFont();
		let sourceBytes = new List<uint8>();
		sourceBytes.AddRange(bytes);
		Test.Assert(source.Initialize(sourceBytes, options.PixelHeight) == .Success);

		Test.Assert(Abs(baked.Font.MeasureString("AVATAR Waltz")
			- source.MeasureString("AVATAR Waltz")) < 0.001f,
			"same advances and same kerning");

		// Kerning specifically: this pair kerns in Roboto, and a bake that skipped the
		// kerning table would measure the two glyphs as simply adjacent.
		Test.Assert(baked.Font.GetKerning(Cp('A'), Cp('V')) == source.GetKerning(Cp('A'), Cp('V')));

		Test.Assert(baked.Atlas.OversampleX == 3.0f, "the oversampling travelled with it");
		Test.Assert(baked.Atlas.OversampleY == 1.0f);
	}

	/// The white texel survives the bake, because the vector renderer draws solid fills by
	/// sampling it out of the font atlas rather than binding a second texture.
	[Test]
	public static void TheWhiteTexelSurvivesTheBake()
	{
		let bytes = scope List<uint8>();
		Test.Assert(TestFontBytes.Read(bytes));

		Test.Assert(FontBaker.Bake(bytes, FontLoadOptions.Default()) case .Ok(let baked));
		defer delete baked;

		let uv = baked.Atlas.WhitePixelUV;
		Test.Assert((uv.X > 0) && (uv.X < 1));
		Test.Assert((uv.Y > 0) && (uv.Y < 1));

		let x = (uint32)(uv.X * baked.Atlas.Width);
		let y = (uint32)(uv.Y * baked.Atlas.Height);
		let pixels = baked.Atlas.PixelData;
		Test.Assert(pixels[(int)(y * baked.Atlas.Width + x)] == 255, "and it is solid");
	}
}
