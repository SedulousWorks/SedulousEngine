using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// Views that present a font and its atlas at a size other than the one it was baked at.
/// This is what lets a single distance field bake serve a whole UI.
class ScaledViewTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	[Test]
	public static void AFontViewScalesEverythingInScreenSpace()
	{
		let baseFont = scope StubFont();
		let view = scope ScaledFontView(baseFont, 16.0f); // Half of the 32 it was baked at.

		Test.Assert(Near(view.Scale, 0.5f));
		Test.Assert(Near(view.PixelHeight, 16.0f));
		Test.Assert(view.HasGlyph((int32)'A'));

		let name = scope String();
		view.GetFamilyName(name);
		Test.Assert(name == "Stub", "identity is not a screen space fact and passes through");

		let metrics = view.Metrics;
		Test.Assert(Near(metrics.Ascent, 12.0f));
		Test.Assert(Near(metrics.Descent, -4.0f));
		Test.Assert(Near(metrics.LineGap, 2.0f));
		Test.Assert(Near(metrics.LineHeight, 18.0f), "still derived, now from scaled parts");
		Test.Assert(Near(metrics.PixelHeight, 16.0f));

		let info = view.GetGlyphInfo((int32)'A');
		Test.Assert(Near(info.AdvanceWidth, 10.0f));
		Test.Assert(Near(info.LeftSideBearing, 1.0f));
		Test.Assert(Near(info.BoundingBox.Width, 1.5f));
		Test.Assert(Near(info.BoundingBox.Height, 2.0f));

		Test.Assert(Near(view.GetKerning((int32)'A', (int32)'A'), -0.75f), "kerning is screen space too");
		Test.Assert(Near(view.MeasureString("AA"), 20.0f));
	}

	/// Laid out in the view's own space, so the kerning that separates two glyphs is the
	/// scaled kerning and not the base one.
	[Test]
	public static void AFontViewLaysOutInItsOwnSpace()
	{
		let baseFont = scope StubFont();
		let view = scope ScaledFontView(baseFont, 16.0f);

		let positions = scope List<GlyphPosition>();
		let width = view.MeasureString("AA", positions);

		Test.Assert(positions.Count == 2);
		Test.Assert(Near(positions[0].X, 0.0f));
		Test.Assert(Near(positions[1].X, 9.25f), "advance 10 plus kerning -0.75");
		Test.Assert(Near(width, 19.25f));
	}

	/// A base with no size of its own cannot be divided by, and passes through at one to
	/// one rather than producing infinities.
	[Test]
	public static void AZeroSizedBaseIsNotDividedBy()
	{
		let baseFont = scope ZeroSizeFont();
		let view = scope ScaledFontView(baseFont, 16.0f);

		Test.Assert(Near(view.Scale, 1.0f));
		Test.Assert(Near(view.GetGlyphInfo((int32)'A').AdvanceWidth, 20.0f));
	}

	[Test]
	public static void AnAtlasViewScalesGeometryAndLeavesTheTextureAlone()
	{
		let baseAtlas = scope StubAtlas();
		let view = scope ScaledFontAtlasView(baseAtlas, 0.5f);

		Test.Assert(view.Width == 128 && view.Height == 128);
		Test.Assert(view.Mode == .DistanceField);
		Test.Assert(Near(view.DistanceFieldRange, 4.0f));
		Test.Assert(view.Contains((int32)'A'));
		Test.Assert(Near(view.WhitePixelUV.X, 0.5f));

		Test.Assert(view.TryGetRegion((int32)'A', let region));
		Test.Assert(region.X == 10, "the texel rectangle indexes the real atlas and must not move");
		Test.Assert(region.Width == 30);
		Test.Assert(Near(region.OffsetX, 1.5f));
		Test.Assert(Near(region.OffsetY, -12.0f));
		Test.Assert(Near(region.AdvanceX, 10.0f));
	}

	[Test]
	public static void AnAtlasViewBuildsScaledQuadsWithUnscaledUVs()
	{
		let baseAtlas = scope StubAtlas();
		let view = scope ScaledFontAtlasView(baseAtlas, 0.5f);

		float cursorX = 100.0f;
		Test.Assert(view.GetGlyphQuad((int32)'A', ref cursorX, 50.0f, let quad));
		Test.Assert(Near(quad.X0, 101.5f), "100 plus offset 3 halved");
		Test.Assert(Near(quad.Y0, 38.0f), "50 minus 24 halved");
		Test.Assert(Near(quad.Width, 15.0f));
		Test.Assert(Near(quad.Height, 20.0f));
		Test.Assert(Near(cursorX, 110.0f), "advanced by the scaled advance");

		// The UVs index the base atlas, because the texture IS the base atlas.
		Test.Assert(Near(quad.U0, 10.0f / 128.0f));
		Test.Assert(Near(quad.V1, 60.0f / 128.0f));

		Test.Assert(view.GetGlyphQuadAt((int32)'A', 10.0f, 10.0f, let placed));
		Test.Assert(Near(placed.X0, 11.5f));
		Test.Assert(Near(placed.Y0, -2.0f));
	}

	/// Whitespace steps the cursor and reports nothing to draw, which is not the same as a
	/// glyph the atlas does not have.
	[Test]
	public static void WhitespaceAdvancesWithoutAQuad()
	{
		let baseAtlas = scope StubAtlas();
		let view = scope ScaledFontAtlasView(baseAtlas, 0.5f);

		float cursorX = 100.0f;
		Test.Assert(!view.GetGlyphQuad((int32)' ', ref cursorX, 50.0f, let quad));
		Test.Assert(Near(cursorX, 106.0f), "12 halved");
		Test.Assert(!view.GetGlyphQuadAt((int32)' ', 10.0f, 10.0f, let placed));
	}
}
