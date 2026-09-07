using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.DistanceField;

namespace Sedulous.Fonts.DistanceField.Tests;

/// The runtime half: reading a distance field atlas back, with no baker in sight.
class DistanceFieldFontAtlasTests
{
	private static int32 Cp(char8 c) => (int32)c;

	/// An atlas of `size` square with nothing in it, ready to have regions set on it.
	private static DistanceFieldFontAtlas MakeAtlas(uint32 size = 64)
	{
		let atlas = new DistanceFieldFontAtlas();
		let pixels = new List<uint8>();
		pixels.Resize((int)size * (int)size * 4);
		atlas.SetPixels(size, size, pixels);
		return atlas;
	}

	/// The mode is what the draw path branches on to pick the distance-field shader rather
	/// than sampling coverage directly.
	[Test]
	public static void TheModeIsDistanceField()
	{
		let atlas = scope DistanceFieldFontAtlas();
		Test.Assert(atlas.Mode == .DistanceField);
	}

	/// The default range is not zero: a shader divides by it, and a fresh atlas that
	/// reported zero would produce a division by zero rather than an obvious mistake.
	[Test]
	public static void ThePixelRangeDefaultsToFourAndIsSettable()
	{
		let atlas = scope DistanceFieldFontAtlas();
		Test.Assert(atlas.DistanceFieldRange == 4.0f);

		atlas.SetPixelRange(8.0f);
		Test.Assert(atlas.DistanceFieldRange == 8.0f);
	}

	[Test]
	public static void RegionsGoInAndComeBackOut()
	{
		let atlas = MakeAtlas(16);
		defer delete atlas;

		atlas.SetRegion(Cp('A'), .(2, 3, 8, 10, 1.0f, -2.0f, 9.0f));

		Test.Assert(atlas.Contains(Cp('A')));
		Test.Assert(!atlas.Contains(Cp('B')), "and nothing that was not set");

		Test.Assert(atlas.TryGetRegion(Cp('A'), let region));
		Test.Assert(region.X == 2);
		Test.Assert(region.Y == 3);
		Test.Assert(region.Width == 8);
		Test.Assert(region.Height == 10);
		Test.Assert(region.AdvanceX == 9.0f);

		Test.Assert(!atlas.TryGetRegion(Cp('B'), let missing));
		Test.Assert(missing.Width == 0, "and a miss leaves nothing behind");
	}

	/// The quad is placed at the cursor plus the glyph's offsets, and its texture
	/// coordinates come from the region over the atlas size.
	[Test]
	public static void AQuadStepsTheCursorAndNamesTexels()
	{
		let atlas = MakeAtlas(64);
		defer delete atlas;

		atlas.SetRegion(Cp('X'), .(4, 4, 10, 12, 1.0f, -10.0f, 11.0f));

		float cursorX = 10.0f;
		Test.Assert(atlas.GetGlyphQuad(Cp('X'), ref cursorX, 20.0f, let quad));

		Test.Assert(cursorX == 21.0f, "the cursor stepped by the advance");
		Test.Assert(quad.X0 == 11.0f, "cursor plus the horizontal offset");
		Test.Assert(quad.Y0 == 10.0f, "the baseline plus the vertical offset, which is negative");
		Test.Assert(quad.X1 == 21.0f, "and the far corner is the width away");
		Test.Assert(quad.Y1 == 22.0f);

		// No oversampling division here, unlike a coverage atlas: a field is one texel per
		// pixel of the cell, so the texture coordinates are the region straight over the size.
		Test.Assert(quad.U0 == 4.0f / 64.0f);
		Test.Assert(quad.V0 == 4.0f / 64.0f);
		Test.Assert(quad.U1 == 14.0f / 64.0f);
		Test.Assert(quad.V1 == 16.0f / 64.0f);
	}

	/// Placing at a point rather than walking a cursor gives the same quad and moves nothing.
	[Test]
	public static void PlacingAtAPointLeavesTheCursorAlone()
	{
		let atlas = MakeAtlas(64);
		defer delete atlas;

		atlas.SetRegion(Cp('X'), .(4, 4, 10, 12, 1.0f, -10.0f, 11.0f));

		float cursorX = 10.0f;
		Test.Assert(atlas.GetGlyphQuad(Cp('X'), ref cursorX, 20.0f, let walked));
		Test.Assert(atlas.GetGlyphQuadAt(Cp('X'), 10.0f, 20.0f, let placed));

		Test.Assert(placed.X0 == walked.X0);
		Test.Assert(placed.Y0 == walked.Y0);
		Test.Assert(placed.U0 == walked.U0);
		Test.Assert(placed.V1 == walked.V1);
	}

	/// Whitespace advances and draws nothing. Without the advance, cursor-walking draw paths
	/// render "hello world" as "helloworld".
	[Test]
	public static void AnAdvanceOnlyRegionStepsTheCursorWithoutAQuad()
	{
		let atlas = MakeAtlas(64);
		defer delete atlas;

		atlas.SetRegion(Cp(' '), .(0, 0, 0, 0, 0, 0, 13.0f));

		float cursorX = 10.0f;
		Test.Assert(!atlas.GetGlyphQuad(Cp(' '), ref cursorX, 20.0f, let quad));
		Test.Assert(cursorX == 23.0f, "advanced despite drawing nothing");

		Test.Assert(!atlas.GetGlyphQuadAt(Cp(' '), 10.0f, 20.0f, let placed));
	}

	/// A codepoint that was never baked refuses without moving the cursor, so a missing
	/// glyph leaves a gap rather than silently shifting the rest of the line.
	[Test]
	public static void AnUnbakedGlyphIsRefusedWithoutMovingTheCursor()
	{
		let atlas = MakeAtlas(64);
		defer delete atlas;

		float cursorX = 10.0f;
		Test.Assert(!atlas.GetGlyphQuad(Cp('Z'), ref cursorX, 20.0f, let quad));
		Test.Assert(cursorX == 10.0f, "nothing moved");
	}

	/// The pixels are RGBA8, so four bytes per texel, and replacing them frees the old set
	/// rather than leaking it.
	[Test]
	public static void PixelsAreFourBytesPerTexelAndReplaceable()
	{
		let atlas = scope DistanceFieldFontAtlas();
		Test.Assert(atlas.PixelData.IsEmpty, "nothing until it is given some");

		let first = new List<uint8>();
		first.Resize(8 * 8 * 4);
		atlas.SetPixels(8, 8, first);
		Test.Assert(atlas.Width == 8);
		Test.Assert(atlas.PixelData.Length == 8 * 8 * 4);

		let second = new List<uint8>();
		second.Resize(16 * 16 * 4);
		atlas.SetPixels(16, 16, second);
		Test.Assert(atlas.Width == 16);
		Test.Assert(atlas.PixelData.Length == 16 * 16 * 4);
	}

	[Test]
	public static void TheWhitePixelIsWhereItWasPut()
	{
		let atlas = scope DistanceFieldFontAtlas();
		atlas.SetWhitePixelUV(0.25f, 0.75f);
		Test.Assert(atlas.WhitePixelUV.X == 0.25f);
		Test.Assert(atlas.WhitePixelUV.Y == 0.75f);
	}
}
