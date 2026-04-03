using System;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

class GlyphInfoTests
{
	[Test]
	static void TestGlyphInfoDefaultConstructor()
	{
		let info = GlyphInfo();

		Test.Assert(info.Codepoint == 0);
		Test.Assert(info.GlyphIndex == 0);
		Test.Assert(info.AdvanceWidth == 0);
		Test.Assert(info.LeftSideBearing == 0);
		Test.Assert(info.HasBitmap == false);
	}

	[Test]
	static void TestGlyphQuadDimensions()
	{
		GlyphQuad quad = .(10, 20, 30, 50, 0, 0, 1, 1);

		Test.Assert(quad.Width == 20);
		Test.Assert(quad.Height == 30);
	}

	[Test]
	static void TestGlyphQuadDefaultConstructor()
	{
		let quad = GlyphQuad();

		Test.Assert(quad.X0 == 0);
		Test.Assert(quad.Y0 == 0);
		Test.Assert(quad.X1 == 0);
		Test.Assert(quad.Y1 == 0);
		Test.Assert(quad.Width == 0);
		Test.Assert(quad.Height == 0);
	}
}
