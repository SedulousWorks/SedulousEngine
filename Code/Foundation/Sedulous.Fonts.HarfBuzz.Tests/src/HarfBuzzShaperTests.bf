using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.Fonts.HarfBuzz;
using Sedulous.Fonts.Bidi;
using Sedulous.Fonts.DistanceField.Baker;

namespace Sedulous.Fonts.HarfBuzz.Tests;

/// The HarfBuzz shaper through ITextShaper: an fi ligature is one glyph over a shared cluster
/// of two characters and hit tests to the right offsets; Arabic joins into fewer glyphs than
/// characters; wrapping keeps a ligature whole; a font with no file falls back to the basic
/// shaper; and installing it changes what a font service hands out.
class HarfBuzzShaperTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Math.Abs(a - b) <= epsilon;

	[Test]
	public static void FiIsOneGlyphOverTwoCharactersAndHitsAndCaretsGoByItsCluster()
	{
		let font = TestFonts.Load(TestFonts.cRoboto);
		Test.Assert(font != null);
		defer delete font;
		let shaper = scope HarfBuzzTextShaper();
		let glyphs = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeText(font, "office", glyphs) case .Ok);

		// o, f, the fi ligature, c, e: five glyphs for six characters.
		Test.Assert(glyphs.Count == 5, scope $"{glyphs.Count} glyphs");
		Test.Assert(glyphs[2].Cluster == 2);
		Test.Assert(glyphs[2].ClusterLength == 2);
		Test.Assert(glyphs[3].Cluster == 4);
		Test.Assert(glyphs[2].GlyphId != font.GetGlyphInfo((int32)'f').GlyphIndex);
		Test.Assert(glyphs[2].GlyphId != font.GetGlyphInfo((int32)'i').GlyphIndex);
		// Glyph ids are the font's; the ones a codepoint maps to match the basic shaper's.
		Test.Assert(glyphs[0].GlyphId == font.GetGlyphInfo((int32)'o').GlyphIndex);
		Test.Assert(Near(glyphs[3].X, glyphs[2].X + glyphs[2].Advance));

		// The trailing half of the ligature puts the caret after both its characters.
		let fi = glyphs[2];
		Span<GlyphPosition> span = glyphs;
		Test.Assert(shaper.HitTest(font, span, fi.X + fi.Advance * 0.9f, 0.0f).InsertionIndex == 4);
		Test.Assert(shaper.HitTest(font, span, fi.X + fi.Advance * 0.1f, 0.0f).InsertionIndex == 2);
		Test.Assert(Near(shaper.GetCursorPosition(font, span, 3), fi.X), "inside it");
	}

	[Test]
	public static void ArabicJoinsIntoFewerGlyphsAndReadsRightToLeft()
	{
		let font = TestFonts.Load(TestFonts.cDejaVuMono);
		Test.Assert(font != null);
		defer delete font;
		let shaper = scope HarfBuzzTextShaper();
		let glyphs = scope List<GlyphPosition>();
		// salaam: seen, lam, alef, meem; lam and alef join into one glyph.
		Test.Assert(shaper.ShapeText(font, "\u{0633}\u{0644}\u{0627}\u{0645}", glyphs) case .Ok);
		Test.Assert(glyphs.Count == 3, scope $"{glyphs.Count} glyphs");
		// Right to left: the first glyph drawn (leftmost) is the last character's.
		Test.Assert(glyphs[0].Cluster == 3);
		Test.Assert(glyphs.Back.Cluster == 0);
		// The joined forms are not the isolated forms a codepoint maps to.
		Test.Assert(glyphs.Back.GlyphId != font.GetGlyphInfo(0x0633).GlyphIndex);
		for (let glyph in glyphs)
			Test.Assert(glyph.Advance > 0.0f);
	}

	[Test]
	public static void WrappingBreaksAfterSpacesKeepsTheLigatureWholeAndStartsLinesAtZero()
	{
		let font = TestFonts.Load(TestFonts.cRoboto, 20.0f);
		Test.Assert(font != null);
		defer delete font;
		let shaper = scope HarfBuzzTextShaper();
		let one = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeText(font, "office office", one) case .Ok);
		let word = one[4].X + one[4].Advance; // "office"

		let glyphs = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeTextWrapped(font, "office office\noffice", word * 1.5f, glyphs, let height) case .Ok);
		// Three lines: the first word (and its space), the second, then the paragraph after the break.
		let lineHeight = font.Metrics.LineHeight;
		Test.Assert(Near(height, lineHeight * 3.0f), scope $"height {height}");
		int ligatures = 0;
		for (let glyph in glyphs)
		{
			if (glyph.ClusterLength == 2)
				ligatures++;
			Test.Assert(glyph.X + glyph.Advance <= word * 1.5f + 0.5f);
		}
		Test.Assert(ligatures == 3);
		Test.Assert(Near(glyphs[0].X, 0.0f));

		// The second "office" starts its own line at x 0, its clusters still counting from the text.
		bool sawSecond = false;
		for (let glyph in glyphs)
		{
			if (glyph.Cluster == 7)
			{
				sawSecond = true;
				Test.Assert(Near(glyph.X, 0.0f));
				Test.Assert(Near(glyph.Y, lineHeight));
			}
			if (glyph.Cluster == 14) // after the break
				Test.Assert(Near(glyph.Y, lineHeight * 2.0f));
		}
		Test.Assert(sawSecond);
	}

	/// A hand-built font: no source data, one glyph per character, glyph id from its table.
	class TableFont : IFont
	{
		public override void GetFamilyName(String outName) => outName.Append("Table");
		public override Span<uint8> SourceData => .();
		public override FontMetrics Metrics => .(10.0f, -3.0f, 0.0f, 13.0f, 1.0f);
		public override float PixelHeight => 13.0f;

		public override GlyphInfo GetGlyphInfo(int32 codepoint)
		{
			var info = GlyphInfo();
			info.Codepoint = codepoint;
			info.GlyphIndex = codepoint + 1000;
			info.AdvanceWidth = 7.0f;
			return info;
		}

		public override float GetKerning(int32 first, int32 second) => 0.0f;
		public override bool HasGlyph(int32 codepoint) => true;
		public override float MeasureString(StringView text) => 7.0f * (float)text.Length;

		public override float MeasureString(StringView text, List<GlyphPosition> outPositions)
		{
			outPositions.Clear();
			return MeasureString(text);
		}
	}

	[Test]
	public static void AFontWithNoFileIsShapedByTheBasicShaper()
	{
		let font = scope TableFont();
		let shaper = scope HarfBuzzTextShaper();
		let glyphs = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeText(font, "fi", glyphs) case .Ok);
		Test.Assert(glyphs.Count == 2, "no ligature without the font's tables");
		Test.Assert(glyphs[0].GlyphId == (int32)'f' + 1000);
		Test.Assert(Near(glyphs[1].X, 7.0f));
	}

	[Test]
	public static void InstalledItIsTheShaperAFontServiceHandsOut()
	{
		let path = scope String();
		Test.Assert(TestFonts.FindPath(TestFonts.cRoboto, path));
		var options = FontLoadOptions.Default();
		options.PixelHeight = 24.0f;

		HarfBuzzShaping.Install();
		Test.Assert(HarfBuzzShaping.IsInstalled);
		{
			let service = scope TrueTypeFontService();
			Test.Assert(service.LoadFont("Roboto", path, options) == .Success);
			let font = service.GetFont("Roboto", 24.0f);
			Test.Assert((font != null) && (font.Shaper != null));
			let glyphs = scope List<GlyphPosition>();
			Test.Assert(font.Shaper.ShapeText(font.Font, "fi", glyphs) case .Ok);
			Test.Assert(glyphs.Count == 1, "the ligature: HarfBuzz shaped it");
		}
		HarfBuzzShaping.Uninstall();
		Test.Assert(!HarfBuzzShaping.IsInstalled);
		{
			let service = scope TrueTypeFontService();
			Test.Assert(service.LoadFont("Roboto", path, options) == .Success);
			let font = service.GetFont("Roboto", 24.0f);
			let glyphs = scope List<GlyphPosition>();
			Test.Assert(font.Shaper.ShapeText(font.Font, "fi", glyphs) case .Ok);
			Test.Assert(glyphs.Count == 2, "the basic shaper again");
		}
	}

	[Test]
	public static void TheGlyphsSubstitutionsReachAreNamedAndBakersBakeThem()
	{
		let font = TestFonts.Load(TestFonts.cRoboto);
		Test.Assert(font != null);
		defer delete font;
		let shaper = scope HarfBuzzTextShaper();
		let shaped = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeText(font, "fi", shaped) case .Ok);
		Test.Assert(shaped.Count == 1);
		let ligature = shaped[0].GlyphId;

		// Reachable from f and i: the ligature, which no codepoint maps to.
		int32[2] range = .((int32)'f', (int32)'i');
		let reachable = scope List<int32>();
		shaper.CollectReachableGlyphs(font, range, reachable);
		Test.Assert(reachable.Contains(ligature));
		Test.Assert(!reachable.Contains(font.GetGlyphInfo((int32)'f').GlyphIndex), "the codepoints' own glyphs are not repeated");

		// With HarfBuzz installed, a coverage atlas and a distance-field atlas both hold it.
		TrueTypeFonts.Initialize();
		DistanceFieldFonts.Initialize();
		HarfBuzzShaping.Install();
		var options = FontLoadOptions.Default();
		options.PixelHeight = 32.0f;
		{
			Test.Assert(FontAtlasBakerFactory.Bake(font, options) case .Ok(let coverage));
			defer delete coverage;
			Test.Assert(coverage.Contains(ligature));
			Test.Assert(coverage.GlyphFor((int32)'f') != ligature);
		}
		{
			var distanceField = FontLoadOptions.DistanceField();
			distanceField.FirstCodepoint = (int32)'a';
			distanceField.LastCodepoint = (int32)'z';
			Test.Assert(FontAtlasBakerFactory.Bake(font, distanceField) case .Ok(let field));
			defer delete field;
			Test.Assert(field.Contains(ligature));
		}
		HarfBuzzShaping.Uninstall();

		// Without it, the basic shaper reaches nothing more, and the atlas holds only the range.
		Test.Assert(FontAtlasBakerFactory.Bake(font, options) case .Ok(let plain));
		defer delete plain;
		Test.Assert(!plain.Contains(ligature));
	}

	[Test]
	public static void ThroughAFontServiceEveryGlyphOfShapedTextHasItsPlaceInTheAtlas()
	{
		let path = scope String();
		Test.Assert(TestFonts.FindPath(TestFonts.cRoboto, path));
		var options = FontLoadOptions.Default();
		options.PixelHeight = 24.0f;

		HarfBuzzShaping.Install();
		defer HarfBuzzShaping.Uninstall();
		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("Roboto", path, options) == .Success);
		let font = service.GetFont("Roboto", 24.0f);
		Test.Assert(font != null);
		let glyphs = scope List<GlyphPosition>();
		Test.Assert(font.Shaper.ShapeText(font.Font, "office fluff", glyphs) case .Ok);
		Test.Assert(glyphs.Count < 12, "the ligatures shaped");
		for (let glyph in glyphs)
		{
			float cursor = 0.0f;
			let drawn = font.Atlas.GetGlyphQuad(glyph.GlyphId, ref cursor, 0.0f, ?);
			// A space draws nothing but advances; everything else, the ligatures too, draws.
			Test.Assert(drawn || (glyph.GlyphInfo.Codepoint == (int32)' '), scope $"glyph {glyph.GlyphId} drawable");
			Test.Assert(cursor > 0.0f, "and it advances");
		}
	}

	// ---- the widened request: a font list with fallback, a direction, a script, a language ----

	[Test]
	public static void ACharacterNoFontBeforeHasTakesTheNextFontInTheList()
	{
		let roboto = TestFonts.Load(TestFonts.cRoboto);
		let dejavu = TestFonts.Load(TestFonts.cDejaVuMono);
		Test.Assert((roboto != null) && (dejavu != null));
		defer delete roboto;
		defer delete dejavu;
		IFont[2] fonts = .(roboto, dejavu);
		let shaper = scope HarfBuzzTextShaper();
		let request = ShapeRequest("a \u{0633}\u{0644}\u{0627}\u{0645} b", fonts); // Roboto has no Arabic
		let glyphs = scope List<GlyphPosition>();
		Test.Assert(shaper.Shape(request, glyphs) case .Ok);

		// a and the space after it in Roboto; the Arabic in DejaVu, with the space after it (a
		// character keeps the run's font when that font has it); b in Roboto again.
		int arabic = 0;
		for (let glyph in glyphs)
		{
			let inDejaVu = (glyph.Cluster >= 2) && (glyph.Cluster <= 6);
			Test.Assert(glyph.Font == (inDejaVu ? 1 : 0), scope $"cluster {glyph.Cluster} in font {glyph.Font}");
			if ((glyph.Cluster >= 2) && (glyph.Cluster <= 5))
				arabic++;
		}
		Test.Assert(arabic == 3, "joined in DejaVu: three glyphs for four characters");
		// Runs follow on, left to right; the Arabic run reads right to left inside itself.
		for (int i = 1; i < glyphs.Count; i++)
			Test.Assert(glyphs[i].X >= glyphs[i - 1].X);
		Test.Assert(glyphs.Back.Cluster == 7, "b, last");
	}

	[Test]
	public static void ARightToLeftRequestReadsRightToLeftAndALanguagePicksItsForms()
	{
		let roboto = TestFonts.Load(TestFonts.cRoboto);
		let dejavu = TestFonts.Load(TestFonts.cDejaVuMono);
		Test.Assert((roboto != null) && (dejavu != null));
		defer delete roboto;
		defer delete dejavu;
		let shaper = scope HarfBuzzTextShaper();
		{
			IFont[1] fonts = .(roboto);
			var request = ShapeRequest("abc", fonts);
			request.Direction = .RightToLeft;
			let glyphs = scope List<GlyphPosition>();
			Test.Assert(shaper.Shape(request, glyphs) case .Ok);
			Test.Assert(glyphs.Count == 3);
			Test.Assert(glyphs[0].Cluster == 2, "c drawn first, leftmost");
			Test.Assert(glyphs[2].Cluster == 0);
		}
		{
			// DejaVu draws a Serbian be differently from the Russian one.
			IFont[1] fonts = .(dejavu);
			var request = ShapeRequest("\u{0431}", fonts);
			let plain = scope List<GlyphPosition>();
			Test.Assert(shaper.Shape(request, plain) case .Ok);
			request.Language = "sr";
			let serbian = scope List<GlyphPosition>();
			Test.Assert(shaper.Shape(request, serbian) case .Ok);
			Test.Assert((plain.Count == 1) && (serbian.Count == 1));
			Test.Assert(serbian[0].GlyphId != plain[0].GlyphId);
			Test.Assert(plain[0].GlyphId == dejavu.GetGlyphInfo(0x0431).GlyphIndex);
			// A script given outright is used for the whole text.
			request.Language = default;
			request.Script = ShapeRequest.ScriptTag("Cyrl");
			let cyrillic = scope List<GlyphPosition>();
			Test.Assert(shaper.Shape(request, cyrillic) case .Ok);
			Test.Assert(cyrillic.Count == 1);
		}
	}

	[Test]
	public static void TheBasicShaperTakesTheSameRequestFallingBackByFontAndMirroring()
	{
		let roboto = TestFonts.Load(TestFonts.cRoboto);
		let dejavu = TestFonts.Load(TestFonts.cDejaVuMono);
		Test.Assert((roboto != null) && (dejavu != null));
		defer delete roboto;
		defer delete dejavu;
		IFont[2] fonts = .(roboto, dejavu);
		let basic = scope TrueTypeTextShaper();
		var request = ShapeRequest("a\u{0633}b", fonts);
		let glyphs = scope List<GlyphPosition>();
		Test.Assert(basic.Shape(request, glyphs) case .Ok);
		Test.Assert(glyphs.Count == 3);
		Test.Assert(glyphs[0].Font == 0);
		Test.Assert(glyphs[1].Font == 1);
		Test.Assert(glyphs[1].Cluster == 1);
		Test.Assert(glyphs[2].Font == 0);

		request.Direction = .RightToLeft;
		let mirrored = scope List<GlyphPosition>();
		Test.Assert(basic.Shape(request, mirrored) case .Ok);
		Test.Assert(mirrored.Count == 3);
		Test.Assert(mirrored[0].Cluster == 2, "b leftmost");
		Test.Assert(Near(mirrored[0].X, 0.0f));
		Test.Assert(Near(mirrored[2].X + mirrored[2].Advance, glyphs[2].X + glyphs[2].Advance));
	}

	/// In a right-to-left run a cluster starts at its right edge: the caret before the first
	/// character is at the right end, the caret at the end at the left, and a hit on a
	/// glyph's right half lands before its cluster.
	[Test]
	public static void CaretsAndHitsReadARightToLeftRunFromTheRight()
	{
		let dejavu = TestFonts.Load(TestFonts.cDejaVuMono);
		Test.Assert(dejavu != null);
		defer delete dejavu;
		IFont[1] fonts = .(dejavu);
		var request = ShapeRequest("\u{0633}\u{0644}\u{0627}\u{0645}", fonts);
		request.Direction = .RightToLeft;
		let shaper = scope HarfBuzzTextShaper();
		let glyphs = scope List<GlyphPosition>();
		Test.Assert(shaper.Shape(request, glyphs) case .Ok);
		Test.Assert(glyphs.Count == 3);
		for (let glyph in glyphs)
			Test.Assert(glyph.RightToLeft);

		Span<GlyphPosition> span = glyphs;
		let seen = glyphs.Back; // the first character, drawn rightmost
		Test.Assert(seen.Cluster == 0);
		Test.Assert(Near(shaper.GetCursorPosition(dejavu, span, 0), seen.X + seen.Advance), "the start, at the right");
		Test.Assert(Near(shaper.GetCursorPosition(dejavu, span, 4), glyphs[0].X), "the end, at the left");
		Test.Assert(shaper.HitTest(dejavu, span, seen.X + seen.Advance * 0.9f, 0.0f).InsertionIndex == 0);
		Test.Assert(shaper.HitTest(dejavu, span, seen.X + seen.Advance * 0.1f, 0.0f).InsertionIndex == 1);
	}

	// ---- bidi: a right-to-left paragraph with Latin inside lays out, hit tests and wraps in
	// visual order ----

	[Test]
	public static void TheResolverGivesArabicOddLevelsAndFindsAParagraphsDirection()
	{
		let resolver = BidiAlgorithm.Resolver;
		let levels = scope BidiLevels();
		uint32[7] leftToRight = .((.)'a', (.)'b', (.)' ', 0x0633, 0x0644, (.)' ', (.)'c');
		resolver.Resolve(leftToRight, .Auto, levels);
		Test.Assert(levels.Levels.Count == 7);
		Test.Assert(levels.ParagraphLevel == 0);
		Test.Assert(levels.Levels[0] == 0);
		Test.Assert(levels.Levels[3] == 1);
		Test.Assert(levels.Levels[4] == 1);
		Test.Assert(levels.Levels[6] == 0);
		uint32[5] rightToLeft = .(0x0633, (.)' ', (.)'a', (.)'b', 0x0644);
		resolver.Resolve(rightToLeft, .Auto, levels);
		Test.Assert(levels.ParagraphLevel == 1, "its first strong character is Arabic");
		Test.Assert(levels.Levels[2] == 2, "the Latin inside, one level up");
	}

	[Test]
	public static void ARightToLeftParagraphWithLatinInsideReadsRightToLeftAndHitTests()
	{
		let font = TestFonts.Load(TestFonts.cDejaVuMono);
		Test.Assert(font != null);
		defer delete font;
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let shaper = scope HarfBuzzTextShaper();
		let glyphs = scope List<GlyphPosition>();
		// salaam, a space, then "world": an Arabic paragraph.
		Test.Assert(shaper.ShapeText(font, "\u{0633}\u{0644}\u{0627}\u{0645} world", glyphs) case .Ok);

		float arabicLeft = 1e9f, latinRight = -1e9f, right = 0;
		int seen = -1;
		float wx = 0, dx = 0;
		for (int i < glyphs.Count)
		{
			let glyph = glyphs[i];
			if (glyph.Cluster <= 3)
			{
				arabicLeft = Math.Min(arabicLeft, glyph.X);
				Test.Assert(glyph.RightToLeft);
			}
			if (glyph.Cluster >= 5)
				latinRight = Math.Max(latinRight, glyph.X + glyph.Advance);
			if (glyph.Cluster == 0)
				seen = i;
			if (glyph.Cluster == 5)
				wx = glyph.X;
			if (glyph.Cluster == 9)
				dx = glyph.X;
			right = Math.Max(right, glyph.X + glyph.Advance);
		}
		Test.Assert(latinRight <= arabicLeft + 0.01f, "the Latin on the left, the Arabic on the right");
		Test.Assert(seen >= 0);
		let first = glyphs[seen];
		Test.Assert(Near(first.X + first.Advance, right), "the first character rightmost");
		Test.Assert(wx < dx, "world reads left to right inside");

		// The caret before the paragraph is at its right edge; a hit on the right half of its
		// first character puts the caret before it, on the left half after it.
		Span<GlyphPosition> span = glyphs;
		Test.Assert(Near(shaper.GetCursorPosition(font, span, 0), right));
		Test.Assert(shaper.HitTest(font, span, first.X + first.Advance * 0.9f, 0.0f).InsertionIndex == 0);
		Test.Assert(shaper.HitTest(font, span, first.X + first.Advance * 0.1f, 0.0f).InsertionIndex == 1);
	}

	[Test]
	public static void AWrappedRightToLeftParagraphReordersEachLine()
	{
		let font = TestFonts.Load(TestFonts.cDejaVuMono, 20.0f);
		Test.Assert(font != null);
		defer delete font;
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let shaper = scope HarfBuzzTextShaper();

		// Three Arabic words; a width that holds two.
		let one = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeText(font, "\u{0633}\u{0644}\u{0627}\u{0645} ", one) case .Ok);
		float word = 0;
		for (let glyph in one)
			word += glyph.Advance;
		let glyphs = scope List<GlyphPosition>();
		Test.Assert(shaper.ShapeTextWrapped(font,
			"\u{0633}\u{0644}\u{0627}\u{0645} \u{0633}\u{0644}\u{0627}\u{0645} \u{0633}\u{0644}\u{0627}\u{0645}",
			word * 2.2f, glyphs, let height) case .Ok);
		let lineHeight = font.Metrics.LineHeight;
		Test.Assert(Near(height, lineHeight * 2.0f), scope $"height {height}");

		// The first word (clusters 0 to 3) is on the first line, to the right of the second.
		float firstLeft = 1e9f, secondRight = -1e9f;
		for (let glyph in glyphs)
		{
			if (glyph.Cluster <= 3)
			{
				Test.Assert(Near(glyph.Y, 0.0f));
				firstLeft = Math.Min(firstLeft, glyph.X);
			}
			if ((glyph.Cluster >= 5) && (glyph.Cluster <= 8))
			{
				Test.Assert(Near(glyph.Y, 0.0f));
				secondRight = Math.Max(secondRight, glyph.X + glyph.Advance);
			}
			if (glyph.Cluster >= 10)
				Test.Assert(Near(glyph.Y, lineHeight));
		}
		Test.Assert(secondRight <= firstLeft + 0.01f);
	}
}
