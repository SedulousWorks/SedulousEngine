using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// The value types text layout is built out of.
class FontTypesTests
{
	private static bool Near(float a, float b, float tolerance = 0.0001f) => Abs(a - b) <= tolerance;

	[Test]
	public static void ARectKnowsItsBoundsAndWhatIsInsideThem()
	{
		let empty = FontRect();
		Test.Assert(empty.X == 0 && empty.Y == 0 && empty.Width == 0 && empty.Height == 0);
		Test.Assert(empty.IsEmpty);

		let rect = FontRect(10, 20, 100, 50);
		Test.Assert(!rect.IsEmpty);
		Test.Assert(rect.Left == 10 && rect.Top == 20);
		Test.Assert(rect.Right == 110 && rect.Bottom == 70);

		Test.Assert(rect.Contains(50, 40));
		Test.Assert(rect.Contains(10, 20), "the top left corner is in");
		Test.Assert(!rect.Contains(110, 70), "the bottom right corner is NOT");
		Test.Assert(!rect.Contains(5, 40));
		Test.Assert(!rect.Contains(50, 100));

		let bounds = FontRect.FromBounds(10, 20, 110, 70);
		Test.Assert(bounds.X == 10 && bounds.Y == 20);
		Test.Assert(bounds.Width == 100 && bounds.Height == 50);
	}

	/// The half open right edge is what keeps adjacent glyph boxes from both claiming a
	/// point on the boundary between them, so a click there resolves to exactly one
	/// character.
	[Test]
	public static void AdjacentRectsShareNoPoint()
	{
		let left = FontRect(0, 0, 10, 20);
		let right = FontRect(10, 0, 10, 20);

		Test.Assert(!left.Contains(10, 5), "the shared edge belongs to the right one");
		Test.Assert(right.Contains(10, 5));
	}

	[Test]
	public static void AnAtlasRegionMapsItselfOntoATexture()
	{
		let empty = AtlasRegion();
		Test.Assert(empty.Width == 0 && empty.AdvanceX == 0);
		Test.Assert(empty.IsEmpty);

		let region = AtlasRegion(10, 20, 32, 48, 2.0f, -5.0f, 30.0f);
		Test.Assert(region.X == 10 && region.Height == 48);
		Test.Assert(region.OffsetY == -5.0f && region.AdvanceX == 30.0f);
		Test.Assert(!region.IsEmpty);

		let placed = AtlasRegion(64, 128, 32, 48, 0, 0, 0);
		placed.GetUVs(512, 512, let u0, let v0, let u1, let v1);
		Test.Assert(Near(u0, 0.125f));
		Test.Assert(Near(v0, 0.25f));
		Test.Assert(Near(u1, 0.1875f));
		Test.Assert(Near(v1, 0.34375f));
	}

	/// A region with an advance and no pixels is whitespace, not a broken region: the
	/// cursor has to move past it even though there is nothing to draw.
	[Test]
	public static void AnAdvanceOnlyRegionIsEmptyButNotUseless()
	{
		let space = AtlasRegion(0, 0, 0, 0, 0, 0, 12.0f);
		Test.Assert(space.IsEmpty);
		Test.Assert(space.AdvanceX == 12.0f);
	}

	[Test]
	public static void GlyphDefaultsAndQuadDimensions()
	{
		let info = GlyphInfo();
		Test.Assert(info.Codepoint == 0 && info.GlyphIndex == 0);
		Test.Assert(info.AdvanceWidth == 0 && info.LeftSideBearing == 0);
		Test.Assert(!info.HasBitmap);

		let quad = GlyphQuad(10, 20, 30, 50, 0, 0, 1, 1);
		Test.Assert(quad.Width == 20);
		Test.Assert(quad.Height == 30);

		let blank = GlyphQuad();
		Test.Assert(blank.X0 == 0 && blank.Width == 0 && blank.Height == 0);
	}

	/// Line height is DERIVED, and subtracting the descent is what makes it work: the
	/// descent is negative, so a line box is ascent plus the depth below plus the gap.
	[Test]
	public static void MetricsDeriveTheirLineHeight()
	{
		let metrics = FontMetrics(20.0f, -5.0f, 2.0f, 24.0f, 0.5f);
		Test.Assert(metrics.Ascent == 20.0f);
		Test.Assert(metrics.Descent == -5.0f);
		Test.Assert(metrics.LineGap == 2.0f);
		Test.Assert(metrics.PixelHeight == 24.0f);
		Test.Assert(metrics.Scale == 0.5f);
		Test.Assert(metrics.LineHeight == 27.0f, "20 - (-5) + 2");

		let fallback = FontMetrics.Default();
		Test.Assert(fallback.Ascent == 0 && fallback.LineHeight == 0);
		Test.Assert(fallback.Scale == 1.0f, "a scale of zero would collapse every glyph");
	}

	/// Derived decorations sit on opposite sides of the baseline, which is the whole point:
	/// an underline below the text and a strikethrough through it.
	[Test]
	public static void DecorationsStraddleTheBaseline()
	{
		let byDefault = TextDecorationMetrics();
		Test.Assert(byDefault.UnderlineThickness == 1);
		Test.Assert(byDefault.StrikethroughThickness == 1);

		let derived = TextDecorationMetrics.FromFontMetrics(24, 32);
		Test.Assert(derived.UnderlinePosition > 0, "below the baseline");
		Test.Assert(derived.StrikethroughPosition < 0, "above it");
		Test.Assert(derived.UnderlineThickness >= 1);
		Test.Assert(derived.StrikethroughThickness >= 1);

		// At a tiny size the proportional thickness rounds away, and the floor is what
		// keeps the decoration visible at all.
		let tiny = TextDecorationMetrics.FromFontMetrics(6, 8);
		Test.Assert(tiny.UnderlineThickness == 1.0f);
	}

	[Test]
	public static void ASelectionNormalisesAndExcludesItsEnd()
	{
		let forwards = SelectionRange(2, 5);
		Test.Assert(forwards.Start == 2 && forwards.End == 5);
		Test.Assert(forwards.Length == 3);

		let backwards = SelectionRange(5, 2);
		Test.Assert(backwards.Start == 2 && backwards.End == 5, "dragged backwards, same range");

		Test.Assert(SelectionRange(3, 3).IsEmpty);
		Test.Assert(SelectionRange(3, 3).Length == 0);
		Test.Assert(!SelectionRange(2, 5).IsEmpty);

		Test.Assert(!forwards.Contains(1));
		Test.Assert(forwards.Contains(2), "the start is in");
		Test.Assert(forwards.Contains(4));
		Test.Assert(!forwards.Contains(5), "the end is not");

		let fromDrag = SelectionRange.FromAnchorActive(9, 4);
		Test.Assert(fromDrag.Start == 4 && fromDrag.End == 9);
	}

	/// Clicking the right half of a character puts the caret AFTER it, which is what makes
	/// click to place feel like it went where you pointed.
	[Test]
	public static void ATrailingHitInsertsAfterTheCharacter()
	{
		Test.Assert(HitTestResult(5, false, true).InsertionIndex == 5);
		Test.Assert(HitTestResult(5, true, true).InsertionIndex == 6);
	}

	[Test]
	public static void TheLoadOptionPresetsAreCoherent()
	{
		let standard = FontLoadOptions.Default();
		Test.Assert(standard.PixelHeight > 0);
		Test.Assert(standard.FirstCodepoint >= 32);
		Test.Assert(standard.LastCodepoint >= standard.FirstCodepoint);
		Test.Assert(IsPowerOfTwo(standard.AtlasWidth) && IsPowerOfTwo(standard.AtlasHeight));
		Test.Assert(standard.OversampleX >= 1);
		Test.Assert(standard.CharacterCount == 95, "32 to 126 inclusive");
		Test.Assert(standard.AtlasMode == .Coverage);

		let extended = FontLoadOptions.ExtendedLatin();
		Test.Assert(extended.LastCodepoint >= 255);
		Test.Assert(extended.AtlasWidth >= 512, "a wider range needs a bigger atlas");

		let small = FontLoadOptions.Small();
		Test.Assert(small.PixelHeight == 16.0f);
		Test.Assert(small.AtlasWidth == 256);

		let large = FontLoadOptions.Large();
		Test.Assert(large.PixelHeight == 64.0f);
		Test.Assert(large.AtlasWidth >= 1024);

		// A distance field is analytic, so oversampling it buys nothing and the padding has
		// to hold the spread instead.
		let df = FontLoadOptions.DistanceField();
		Test.Assert(df.AtlasMode == .DistanceField);
		Test.Assert(df.OversampleX == 1 && df.OversampleY == 1);
		Test.Assert(df.Padding > FontLoadOptions.Default().Padding);
	}

	private static bool IsPowerOfTwo(uint32 v) => (v > 0) && ((v & (v - 1)) == 0);

	/// Sizes arrive from layout arithmetic, so the same size reached two ways can differ in
	/// the last bit. Comparing exactly would bake the same font twice.
	[Test]
	public static void CacheKeysCompareSizesWithTolerance()
	{
		let path = scope String("fonts/Roboto.ttf");
		let other = scope String("fonts/Roboto.ttf");
		let elsewhere = scope String("fonts/Other.ttf");

		Test.Assert(FontCacheKey(path, 16.0f) == FontCacheKey(other, 16.0f));
		Test.Assert(FontCacheKey(path, 16.0f) == FontCacheKey(other, 16.0002f));
		Test.Assert(FontCacheKey(path, 16.0f) != FontCacheKey(other, 16.5f));
		Test.Assert(FontCacheKey(path, 16.0f) != FontCacheKey(elsewhere, 16.0f));

		// Equal keys must hash together or a dictionary never finds them.
		Test.Assert(FontCacheKey(path, 16.0f).GetHashCode() == FontCacheKey(other, 16.0f).GetHashCode());
	}
}
