using System;
using Sedulous.Slug;

namespace Sedulous.Slug.Tests;

class SlugTextureBuilderTests
{
	[Test]
	public static void BuildEmptyFont_ReturnsErr()
	{
		let font = scope SlugFont();
		let result = SlugTextureBuilder.Build(font);
		Test.Assert(result case .Err, "Building textures for empty font should fail");
	}

	[Test]
	public static void BuildSingleGlyph_Succeeds()
	{
		let font = scope SlugFont();

		// Create a simple square glyph (4 line segments = 4 quadratic curves)
		let glyph = new SlugGlyphData();
		glyph.Codepoint = (uint32)'A';
		glyph.GlyphIndex = 1;
		glyph.AdvanceWidth = 0.6f;
		glyph.BoundingBox = .(0.05f, 0.0f, 0.55f, 0.7f);
		glyph.Curves = new QuadraticBezier2D[](
			// Bottom edge (left to right)
			.(.(0.05f, 0.0f), .(0.3f, 0.0f), .(0.55f, 0.0f)),
			// Right edge (bottom to top)
			.(.(0.55f, 0.0f), .(0.55f, 0.35f), .(0.55f, 0.7f)),
			// Top edge (right to left)
			.(.(0.55f, 0.7f), .(0.3f, 0.7f), .(0.05f, 0.7f)),
			// Left edge (top to bottom)
			.(.(0.05f, 0.7f), .(0.05f, 0.35f), .(0.05f, 0.0f))
		);

		font.AddGlyph(glyph);

		let result = SlugTextureBuilder.Build(font);
		Test.Assert(result case .Ok, "Building textures should succeed");

		if (result case .Ok(let br))
		{
			Test.Assert(br.CurveTextureData != null, "Curve texture data should not be null");
			Test.Assert(br.BandTextureData != null, "Band texture data should not be null");
			Test.Assert(br.CurveTextureSize.x == SlugConstants.kBandTextureWidth);
			Test.Assert(br.CurveTextureSize.y > 0);
			Test.Assert(font.TexturesBuilt);

			let g = font.GetGlyph((uint32)'A');
			Test.Assert(g.BandCount[0] > 0, "Should have horizontal bands");
			Test.Assert(g.BandCount[1] > 0, "Should have vertical bands");

			delete br.CurveTextureData;
			delete br.BandTextureData;
		}
	}

	[Test]
	public static void GeometryBuilder_MeasureString()
	{
		let font = scope SlugFont();

		let glyphA = new SlugGlyphData();
		glyphA.Codepoint = (uint32)'A';
		glyphA.GlyphIndex = 1;
		glyphA.AdvanceWidth = 0.6f;
		glyphA.BoundingBox = .(0.05f, 0.0f, 0.55f, 0.7f);
		font.AddGlyph(glyphA);

		let glyphB = new SlugGlyphData();
		glyphB.Codepoint = (uint32)'B';
		glyphB.GlyphIndex = 2;
		glyphB.AdvanceWidth = 0.55f;
		glyphB.BoundingBox = .(0.05f, 0.0f, 0.5f, 0.7f);
		font.AddGlyph(glyphB);

		let width = SlugGeometryBuilder.MeasureString(font, "AB", 16.0f);
		let expected = (0.6f + 0.55f) * 16.0f;
		Test.Assert(Math.Abs(width - expected) < 0.01f, scope $"Expected {expected}, got {width}");
	}
}
