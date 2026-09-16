using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.DistanceField;
using Sedulous.Fonts.DistanceField.Baker;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.DistanceField.Baker.Tests;

/// Baking a real typeface through msdfgen.
///
/// These are ORIENTATION and WINDING tests above all. Both mistakes produce an atlas that
/// is full of plausible looking data and renders as garbage, and neither shows up in a
/// dimension or region check.
class DistanceFieldBakerTests
{
	private static int32 Cp(char8 c) => (int32)c;

	private static FontLoadOptions BakeOptions()
	{
		var options = FontLoadOptions.DistanceField();
		options.PixelHeight = 48.0f;
		options.AtlasWidth = 1024;
		options.AtlasHeight = 1024;
		return options;
	}

	[Test]
	public static void TheBakerClaimsTrueTypeAndOnlyInDistanceFieldMode()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.SupportsExtension(".ttf"));
		Test.Assert(baker.SupportsExtension(".OTF"));
		Test.Assert(!baker.SupportsExtension(".png"));

		Test.Assert(baker.CanBake(font, BakeOptions()));

		// A coverage request belongs to the raster baker, not this one.
		var coverage = FontLoadOptions.Default();
		coverage.AtlasMode = .Coverage;
		Test.Assert(!baker.CanBake(font, coverage));

		// And without the options there is no mode to check, so it claims nothing: saying
		// yes here would take every coverage bake as well.
		Test.Assert(!baker.CanBake(font));
		Test.Assert(!baker.CanBake(null, BakeOptions()));
	}

	/// The orientation test. 'F' is strongly TOP heavy, so a vertical flip inverts which
	/// half its ink sits in; and a reversed winding makes msdfgen fill the exterior, which
	/// floods nearly the whole cell.
	[Test]
	public static void GlyphsAreUprightAndNotInsideOut()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, BakeOptions()) case .Ok(let atlas));
		defer delete atlas;

		let f = InkStats.Analyze(atlas, Cp('F'));
		Test.Assert(f.Total > 0, "'F' baked something");

		// 'F' is thin strokes: it fills a fraction of its cell. A reversed winding fills
		// nearly all of it, which this catches without needing to know the exact fraction.
		Test.Assert(f.Total < (f.CellWidth * f.CellHeight) / 2,
			scope $"'F' filled {f.Total} of {f.CellWidth * f.CellHeight} texels, so it is inside out");

		// Top bar plus middle bar plus the stem: the top half carries more ink than the
		// bottom. Flipped, this reverses.
		Test.Assert(f.TopHalf > f.BottomHalf,
			scope $"'F' has {f.TopHalf} above and {f.BottomHalf} below, so it is upside down");
	}

	/// A descender must keep its tail. If the projection mis-registers the glyph in its
	/// cell, the bottom comes out empty and 'g' renders like 'a'.
	[Test]
	public static void DescendersKeepTheirTail()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, BakeOptions()) case .Ok(let atlas));
		defer delete atlas;

		let g = InkStats.Analyze(atlas, Cp('g'));
		let o = InkStats.Analyze(atlas, Cp('o'));
		Test.Assert(g.Total > 0);
		Test.Assert(o.Total > 0);

		Test.Assert(g.CellHeight > o.CellHeight, "'g' hangs below the baseline and 'o' does not");
		Test.Assert(g.MaxRow > (g.CellHeight * 2) / 3,
			scope $"'g' has no ink below row {g.MaxRow} of {g.CellHeight}, so the tail was lost");
	}

	/// A space has no outline, so no cell is generated for it, but it MUST still carry its
	/// advance. The raster baker gets this free from stb's packer; here it is done by hand,
	/// which is exactly why it needs a test.
	[Test]
	public static void BlankGlyphsGetAnAdvanceOnlyRegion()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		var options = BakeOptions();
		options.FirstCodepoint = 32;
		options.LastCodepoint = 126;

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, options) case .Ok(let atlas));
		defer delete atlas;

		Test.Assert(atlas.TryGetRegion(Cp(' '), let space));
		Test.Assert(space.IsEmpty, "nothing to draw");
		Test.Assert(space.AdvanceX > 0, "but the cursor steps");

		float cursorX = 10.0f;
		Test.Assert(!atlas.GetGlyphQuad(Cp(' '), ref cursorX, 20.0f, let quad));
		Test.Assert(Abs(cursorX - (10.0f + space.AdvanceX)) < 0.001f);

		// The advance is the font's own, rescaled from the size it was parsed at to the size
		// it was baked at.
		let toBakeScale = options.PixelHeight / font.PixelHeight;
		let expected = font.GetGlyphInfo(Cp(' ')).AdvanceWidth * toBakeScale;
		Test.Assert(Abs(space.AdvanceX - expected) < (expected * 0.02f),
			scope $"space advance {space.AdvanceX}, expected about {expected}");
	}

	/// The generation fans out across workers, so the pack order and every baked byte have
	/// to be scheduling independent. Two bakes of the same font must agree exactly.
	[Test]
	public static void BakingIsDeterministic()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, BakeOptions()) case .Ok(let first));
		defer delete first;
		Test.Assert(baker.Bake(font, BakeOptions()) case .Ok(let second));
		defer delete second;

		Test.Assert(first.Width == second.Width);
		Test.Assert(first.Height == second.Height);

		// Every region in the same place.
		for (int32 codepoint = 32; codepoint <= 126; codepoint++)
		{
			let hasFirst = first.TryGetRegion(codepoint, let a);
			let hasSecond = second.TryGetRegion(codepoint, let b);
			Test.Assert(hasFirst == hasSecond, scope $"codepoint {codepoint} baked in only one run");
			if (!hasFirst)
				continue;
			Test.Assert((a.X == b.X) && (a.Y == b.Y), scope $"codepoint {codepoint} packed elsewhere");
			Test.Assert((a.Width == b.Width) && (a.Height == b.Height));
			Test.Assert(a.AdvanceX == b.AdvanceX);
		}

		// And every byte the same.
		let firstPixels = first.PixelData;
		let secondPixels = second.PixelData;
		Test.Assert(firstPixels.Length == secondPixels.Length);
		Test.Assert(RawMemory.Equal(firstPixels.Ptr, secondPixels.Ptr, firstPixels.Length),
			"the two bakes differ byte for byte");
	}

	[Test]
	public static void TheAtlasCarriesItsRangeAndAWhiteTexel()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, BakeOptions()) case .Ok(let atlas));
		defer delete atlas;

		// The shader divides by the range to recover a screen-space edge, so it has to
		// travel with the pixels rather than being assumed.
		Test.Assert(atlas.DistanceFieldRange > 0);
		Test.Assert(atlas.Mode == .DistanceField);
		Test.Assert(atlas.PixelData.Length == (int)atlas.Width * (int)atlas.Height * 4,
			"RGBA8, four bytes per texel");

		let uv = atlas.WhitePixelUV;
		Test.Assert((uv.X > 0) && (uv.X < 1));
		Test.Assert((uv.Y > 0) && (uv.Y < 1));

		let x = (int)(uv.X * atlas.Width);
		let y = (int)(uv.Y * atlas.Height);
		let index = (y * (int)atlas.Width + x) * 4;
		let pixels = atlas.PixelData;
		Test.Assert(pixels[index + 0] == 255, "and it is solid on every channel");
		Test.Assert(pixels[index + 1] == 255);
		Test.Assert(pixels[index + 2] == 255);
		Test.Assert(pixels[index + 3] == 255);
	}

	/// An atlas too small for a single cell has nowhere to pack, and must say so rather than
	/// returning an empty atlas that every later lookup misses on.
	[Test]
	public static void AnAtlasWithNoRoomIsRefused()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		var options = BakeOptions();
		options.AtlasWidth = 8;
		options.AtlasHeight = 8;

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, options) case .Err(let error));
		Test.Assert(error == .NoGlyphsFound);
	}

	/// The range is in SHAPE units, not pixels. It is the pixel spread divided by the scale
	/// that takes font units to pixels, and getting that wrong leaves the interior correct
	/// while collapsing the soft edge the shader antialiases with, so only the width of the
	/// transition band shows it.
	[Test]
	public static void TheFieldHasASoftEdgeOfAboutTheRequestedRange()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, BakeOptions()) case .Ok(let atlas));
		defer delete atlas;

		let ink = InkStats.Analyze(atlas, Cp('F'));
		let band = InkStats.CountTransitionTexels(atlas, Cp('F'));
		Test.Assert(ink.Total > 0);

		// The band traces the glyph's outline a few texels thick, so it is a substantial
		// share of the ink. A range in the wrong units makes the field step from outside to
		// inside almost at once and the band all but disappears.
		Test.Assert(band > (ink.Total / 4),
			scope $"only {band} transition texels against {ink.Total} inside, so the edge is too hard");

		// And it does not swallow the cell either, which is what too WIDE a range would do.
		Test.Assert(band < (ink.CellWidth * ink.CellHeight),
			scope $"{band} transition texels fills the whole {ink.CellWidth}x{ink.CellHeight} cell");
	}

	/// Every glyph sits CENTRED in its cell, inset by the padding plus the one texel of
	/// safety. The projection is what puts it there, and a projection that is off by even a
	/// few texels leaves the glyph legible but mis-registered against its own region.
	[Test]
	public static void EachGlyphIsRegisteredInsideItsCell()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		var options = BakeOptions();
		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, options) case .Ok(let atlas));
		defer delete atlas;

		// The cell is the glyph plus `padding` on each side plus one texel of safety, so the
		// ink starts about that far in and ends about that far from the far edge.
		let margin = (int32)options.Padding + 1;

		for (let codepoint in int32[](Cp('F'), Cp('o'), Cp('g'), Cp('M'), Cp('1')))
		{
			let ink = InkStats.Analyze(atlas, codepoint);
			Test.Assert(ink.Total > 0, scope $"'{(char8)codepoint}' baked nothing");

			// One texel of slack each way: the field's own falloff can light a texel just
			// outside the outline.
			Test.Assert(ink.MinRow >= (margin - 1),
				scope $"'{(char8)codepoint}' ink starts at row {ink.MinRow}, expected about {margin}");
			Test.Assert(ink.MaxRow <= (ink.CellHeight - margin),
				scope $"'{(char8)codepoint}' ink ends at row {ink.MaxRow} of {ink.CellHeight}");

			// Horizontally too. The two translates are computed separately, so a mistake in
			// one of them is invisible to a check on the other axis alone.
			Test.Assert(ink.MinColumn >= (margin - 1),
				scope $"'{(char8)codepoint}' ink starts at column {ink.MinColumn}, expected about {margin}");
			Test.Assert(ink.MaxColumn <= (ink.CellWidth - margin),
				scope $"'{(char8)codepoint}' ink ends at column {ink.MaxColumn} of {ink.CellWidth}");
		}
	}

	/// The region's offsets place the cell against the baseline, and they have to account for
	/// the margin the cell added around the glyph. Dropping it draws every glyph a few pixels
	/// off, consistently, which looks like a font that simply sits wrong.
	[Test]
	public static void TheRegionOffsetsAccountForTheCellMargin()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		var options = BakeOptions();
		options.PixelHeight = font.PixelHeight; // so the font's own metrics are comparable
		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, options) case .Ok(let atlas));
		defer delete atlas;

		let margin = (float)options.Padding + 1.0f;

		for (let codepoint in int32[](Cp('F'), Cp('o'), Cp('g')))
		{
			Test.Assert(atlas.TryGetRegion(codepoint, let region));
			let bounds = font.GetGlyphInfo(codepoint).BoundingBox;

			// The cell's top left is the glyph's own bounding box pushed out by the margin.
			Test.Assert(Abs(region.OffsetX - (bounds.X - margin)) < 1.0f,
				scope $"'{(char8)codepoint}' offsetX {region.OffsetX}, expected about {bounds.X - margin}");
			Test.Assert(Abs(region.OffsetY - (bounds.Y - margin)) < 1.0f,
				scope $"'{(char8)codepoint}' offsetY {region.OffsetY}, expected about {bounds.Y - margin}");

			// And the cell is the glyph plus a margin on each side.
			Test.Assert(Abs((float)region.Width - (bounds.Width + margin * 2)) < 1.5f);
			Test.Assert(Abs((float)region.Height - (bounds.Height + margin * 2)) < 1.5f);
		}
	}

	/// Cells are packed with a gutter between them. The atlas starts zeroed, which reads as
	/// outside, so the gutter is what stops bilinear sampling at a cell's edge from pulling
	/// in the neighbour and showing as flickering seams under magnification.
	[Test]
	public static void PackedCellsNeverTouch()
	{
		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		var options = BakeOptions();
		options.FirstCodepoint = 32;
		options.LastCodepoint = 126;

		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, options) case .Ok(let atlas));
		defer delete atlas;

		// The separation is stated HERE rather than read from RowPacker.CellGutter: a test
		// that took its expectation from the constant it is checking would follow that
		// constant to zero and still pass.
		const int32 cRequiredGap = 2;

		let regions = scope List<AtlasRegion>();
		for (int32 codepoint = options.FirstCodepoint; codepoint <= options.LastCodepoint; codepoint++)
		{
			if (atlas.TryGetRegion(codepoint, let region) && !region.IsEmpty)
				regions.Add(region);
		}
		Test.Assert(regions.Count > 50, scope $"only {regions.Count} cells to compare");

		for (int i < regions.Count)
		{
			for (int j = i + 1; j < regions.Count; j++)
			{
				let a = regions[i];
				let b = regions[j];

				// Grown by the gutter, the two must still not overlap. That is the same as
				// saying there is at least a gutter's worth of space between them.
				let separated =
					((int32)a.X + (int32)a.Width + cRequiredGap <= (int32)b.X)
					|| ((int32)b.X + (int32)b.Width + cRequiredGap <= (int32)a.X)
					|| ((int32)a.Y + (int32)a.Height + cRequiredGap <= (int32)b.Y)
					|| ((int32)b.Y + (int32)b.Height + cRequiredGap <= (int32)a.Y);

				Test.Assert(separated,
					scope $"cells ({a.X},{a.Y},{a.Width}x{a.Height}) and ({b.X},{b.Y},{b.Width}x{b.Height}) crowd each other");
			}
		}
	}
}
