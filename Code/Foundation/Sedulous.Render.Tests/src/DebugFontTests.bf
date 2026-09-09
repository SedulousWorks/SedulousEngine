using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The embedded bitmap font.
class DebugFontTests
{
	[Test]
	public static void TheAtlasIsExactlyItsDeclaredSize()
	{
		let pixels = scope List<uint8>();
		DebugFont.GenerateTextureData(pixels);
		Test.Assert(pixels.Count == DebugFont.cTextureWidth * DebugFont.cTextureHeight);
	}

	[Test]
	public static void SpaceIsBlankAndACapitalIsNot()
	{
		let pixels = scope List<uint8>();
		DebugFont.GenerateTextureData(pixels);

		// Space is the first glyph, at the atlas's own origin.
		for (int row < DebugFont.cCharHeight)
			for (int col < DebugFont.cCharWidth)
				Test.Assert(pixels[row * DebugFont.cTextureWidth + col] == 0);

		var lit = 0;
		let index = (int)'A' - DebugFont.cFirstChar;
		let baseX = (index % DebugFont.cCharsPerRow) * DebugFont.cCharWidth;
		let baseY = (index / DebugFont.cCharsPerRow) * DebugFont.cCharHeight;
		for (int row < DebugFont.cCharHeight)
			for (int col < DebugFont.cCharWidth)
				if (pixels[(baseY + row) * DebugFont.cTextureWidth + (baseX + col)] != 0)
					lit++;
		Test.Assert(lit > 0);
	}

	[Test]
	public static void EveryPixelIsFullyOnOrFullyOff()
	{
		let pixels = scope List<uint8>();
		DebugFont.GenerateTextureData(pixels);
		for (let pixel in pixels)
			Test.Assert((pixel == 0) || (pixel == 255));
	}

	/// The block after the last glyph is what a filled rectangle samples, so it has to be
	/// solid rather than whatever the initial clear left.
	[Test]
	public static void TheSolidBlockIsSolid()
	{
		let pixels = scope List<uint8>();
		DebugFont.GenerateTextureData(pixels);

		let uv = DebugFont.SolidBlockUV;
		let x = (int)(uv.X * DebugFont.cTextureWidth);
		let y = (int)(uv.Y * DebugFont.cTextureHeight);

		for (int row < DebugFont.cCharHeight)
			for (int col < DebugFont.cCharWidth)
				Test.Assert(pixels[(y + row) * DebugFont.cTextureWidth + (x + col)] == 255);
	}

	[Test]
	public static void ThePrintableRangeMapsAndTheRestDoesNot()
	{
		Test.Assert(DebugFont.TryGetCharUV(' ', let space));
		Test.Assert(space.X == 0.0f);
		Test.Assert(space.Y == 0.0f);

		Test.Assert(DebugFont.TryGetCharUV('~', let tilde));
		Test.Assert(tilde.Z <= 1.0f);
		Test.Assert(tilde.W <= 1.0f);

		Test.Assert(!DebugFont.TryGetCharUV('\n', let control));
		Test.Assert(control == Float4(0, 0, 0, 0));
	}

	/// One cell wide and one tall, so a glyph never bleeds into its neighbour.
	[Test]
	public static void ACellIsExactlyOneGlyphAcross()
	{
		Test.Assert(DebugFont.TryGetCharUV('A', let uv));
		let width = (uv.Z - uv.X) * DebugFont.cTextureWidth;
		let height = (uv.W - uv.Y) * DebugFont.cTextureHeight;
		Test.Assert(Abs(width - DebugFont.cCharWidth) < 0.001f);
		Test.Assert(Abs(height - DebugFont.cCharHeight) < 0.001f);
	}

	/// The sixteenth character wraps onto the next row, which is what the atlas's height
	/// depends on.
	[Test]
	public static void TheSeventeenthGlyphStartsTheSecondRow()
	{
		Test.Assert(DebugFont.TryGetCharUV((char32)(DebugFont.cFirstChar + 15), let last));
		Test.Assert(DebugFont.TryGetCharUV((char32)(DebugFont.cFirstChar + 16), let wrapped));
		Test.Assert(last.Y == 0.0f);
		Test.Assert(wrapped.X == 0.0f);
		Test.Assert(wrapped.Y > 0.0f);
	}
}
