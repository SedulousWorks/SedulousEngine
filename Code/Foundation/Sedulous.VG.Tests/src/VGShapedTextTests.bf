using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Single-line text in a font with a shaper is shaped, so its ligatures draw, and shaped once.
class VGShapedTextTests
{
	/// Glyph 70 is 'f' alone, 73 'i' alone.
	class LigatureFont : IFont
	{
		public override void GetFamilyName(String outName) => outName.Append("Lig");
		public override Span<uint8> SourceData => .();
		public override FontMetrics Metrics => .(10.0f, -3.0f, 0.0f, 13.0f, 1.0f);
		public override float PixelHeight => 13.0f;

		public override GlyphInfo GetGlyphInfo(int32 codepoint)
		{
			var info = GlyphInfo();
			info.Codepoint = codepoint;
			info.GlyphIndex = (codepoint == (int32)'f') ? 70 : 73;
			info.AdvanceWidth = 8.0f;
			return info;
		}

		public override float GetKerning(int32 first, int32 second) => 0.0f;
		public override bool HasGlyph(int32 codepoint) => true;
		public override float MeasureString(StringView text) => 8.0f * (float)text.Length;

		public override float MeasureString(StringView text, List<GlyphPosition> outPositions)
		{
			outPositions.Clear();
			return MeasureString(text);
		}
	}

	/// Turns "fi" into one glyph (77), as a real shaper's ligature does, and counts its calls.
	class LigatureShaper : ClusterTextShaper
	{
		public int Calls;

		public override Result<float, FontLoadResult> ShapeText(IFont font, StringView text,
			List<GlyphPosition> outPositions)
			=> ShapeText(font, text, 0, 0, outPositions);

		public override Result<float, FontLoadResult> ShapeText(IFont font, StringView text,
			float startX, float startY, List<GlyphPosition> outPositions)
		{
			Calls++;
			outPositions.Clear();
			var glyph = GlyphPosition();
			glyph.X = startX;
			glyph.Y = startY;
			glyph.Advance = 12.0f;
			glyph.GlyphId = (text == "fi") ? 77 : 70;
			glyph.ClusterLength = (int32)text.Length;
			outPositions.Add(glyph);
			return .Ok(12.0f);
		}

		public override Result<void, FontLoadResult> ShapeTextWrapped(IFont font, StringView text,
			float maxWidth, List<GlyphPosition> outPositions, out float outTotalHeight)
		{
			outTotalHeight = 13.0f;
			if (ShapeText(font, text, outPositions) case .Err(let error))
				return .Err(error);
			return .Ok;
		}

		protected override Result<float, FontLoadResult> ShapeRun(ShapeRequest request, List<uint32> codepoints,
			List<int> byteOffsets, int start, int end, RunDirection direction, float x, float y,
			List<GlyphPosition> outPositions)
			=> ShapeText(request.Fonts[0], request.Text, x, y, outPositions);

		public override void CollectReachableGlyphs(IFont font, Span<int32> codepoints, List<int32> outGlyphs)
		{
			outGlyphs.Clear();
		}
	}

	/// Holds glyphs 70, 73 and 77.
	class LigatureAtlas : IFontAtlas
	{
		public override uint32 Width => 64;
		public override uint32 Height => 64;
		public override Span<uint8> PixelData => .();
		public override Float2 WhitePixelUV => .(0.5f, 0.5f);
		public override int32 GlyphFor(int32 codepoint) => (codepoint == (int32)'f') ? 70 : 73;
		public override bool Contains(int32 glyph) => (glyph == 70) || (glyph == 73) || (glyph == 77);

		public override bool TryGetRegion(int32 glyph, out AtlasRegion region)
		{
			region = Contains(glyph) ? .(0, 0, 8, 8, 0.0f, -8.0f, 8.0f) : .();
			return Contains(glyph);
		}

		public override bool GetGlyphQuad(int32 glyph, ref float cursorX, float cursorY, out GlyphQuad quad)
		{
			quad = .();
			if (!Contains(glyph))
				return false;
			quad = .(cursorX, cursorY - 8.0f, cursorX + 8.0f, cursorY, 0, 0, 0.125f, 0.125f);
			cursorX += 8.0f;
			return true;
		}

		public override bool GetGlyphQuadAt(int32 glyph, float x, float y, out GlyphQuad quad)
		{
			var cursor = x;
			return GetGlyphQuad(glyph, ref cursor, y, out quad);
		}
	}

	class OneFontService : IFontService
	{
		public CachedFont Font;
		public OwnedImageData Texture = new .(64, 64, .RGBA8, .(), .Linear) ~ delete _;

		public override CachedFont GetFont(float pixelHeight) => Font;
		public override CachedFont GetFont(StringView familyName, float pixelHeight) => Font;
		public override ImageData GetAtlasTexture(CachedFont font) => Texture;
		public override ImageData GetAtlasTexture(StringView familyName, float pixelHeight) => Texture;
		public override void ReleaseFont(CachedFont font) {}
		public override void GetDefaultFontFamily(String outFamily) => outFamily.Append("Lig");
		public override bool HasFamily(StringView familyName) => true;
	}

	private static int Quads(VGContext context)
	{
		int quads = 0;
		for (let command in context.GetBatch().Commands)
			quads += command.IndexCount / 6;
		return quads;
	}

	[Test]
	public static void TextInAFontWithAShaperIsShapedOnceSoLigaturesDraw()
	{
		let shaper = new LigatureShaper();
		let font = scope CachedFont(new LigatureFont(), new LigatureAtlas(), shaper); // owns all three
		let service = scope OneFontService();
		service.Font = font;
		let context = scope VGContext();
		context.SetFontService(service);

		context.DrawText("fi", font, .(0.0f, 20.0f), .White);
		Test.Assert(Quads(context) == 1, "one ligature glyph, not f and i");
		context.DrawText("fi", font, .(0, 0, 100, 20), .Center, .Middle, .White);
		Test.Assert(Quads(context) == 2);
		Test.Assert(shaper.Calls == 1, "shaped once, then drawn from the cache");
		Test.Assert(context.ShapedTextCount == 1);

		context.Clear();
		context.DrawText("fi", font, .(0.0f, 20.0f), .White);
		Test.Assert(shaper.Calls == 1, "across frames too");
	}

	/// Centred by the shaped width, as the unshaped path centres by the measured one.
	[Test]
	public static void ShapedTextIsAlignedByItsShapedWidth()
	{
		let font = scope CachedFont(new LigatureFont(), new LigatureAtlas(), new LigatureShaper());
		let service = scope OneFontService();
		service.Font = font;
		let context = scope VGContext();
		context.SetFontService(service);

		// The ligature is 12 wide in a 100 wide box: its pen starts at 44.
		context.DrawText("fi", font, .(0, 0, 100, 20), .Center, .Middle, .White);
		let batch = context.GetBatch();
		Test.Assert(batch.Vertices.Count >= 4);
		var minX = float.MaxValue;
		for (let vertex in batch.Vertices)
			minX = Math.Min(minX, vertex.Position.X);
		Test.Assert(Math.Abs(minX - 44.0f) < 0.01f, scope $"left edge {minX}");
	}
}
