using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// overflow-wrap: a word wider than its whole line breaks where the line ends, between graphemes,
/// instead of running out of its box; a word that fits a line of its own goes to the next line
/// first, as before. Over DejaVu Sans Mono, every character as wide as the next.
class OverflowWrapTests
{
	private static TrueTypeFontService DejaVu(TrueTypeFontService service)
	{
		TextFixtures.Load(service, "DejaVu", TextFixtures.cDejaVuMono);
		return service;
	}

	private static float Advance(TrueTypeFontService font) => font.GetFont("DejaVu", 16.0f).Font.MeasureString("a");

	private static TextLayout Lay(TrueTypeFontService font, StringView text, float maxWidth, bool breakWords, TextLayout outLayout)
	{
		let style = scope TextLayoutStyle();
		style.Font = font.GetFont("DejaVu", 16.0f);
		style.Family.Set("DejaVu");
		style.Size = 16.0f;
		style.MaxWidth = maxWidth;
		style.BreakWords = breakWords;
		return LayOutText(TextFixtures.OneRun(text, scope .()), style, outLayout);
	}

	// Every line within `width`, and together they cover the text, each starting where the last ended.
	private static void CheckCovers(TextLayout layout, int size, float width)
	{
		Test.Assert(!layout.Lines.IsEmpty);
		Test.Assert(layout.Lines[0].Start == 0);
		for (int i = 0; i < layout.Lines.Count; i++)
		{
			Test.Assert(layout.Lines[i].Width <= width + 0.01f);
			if (i + 1 < layout.Lines.Count)
				Test.Assert(layout.Lines[i + 1].Start == layout.Lines[i].End);
		}
		Test.Assert(layout.Lines.Back.End == size);
	}

	[Test]
	public static void WithoutItALongWordRunsOutOfItsLine()
	{
		let font = DejaVu(scope .());
		let width = Advance(font) * 5.5f;
		let layout = Lay(font, "abcdefghijklmnop", width, false, scope .());
		Test.Assert(layout.Lines.Count == 1);
		Test.Assert(layout.Lines[0].Width > width);
	}

	[Test]
	public static void BreakWordBreaksAWordWiderThanItsLineWhereTheLineEnds()
	{
		let font = DejaVu(scope .());
		let width = Advance(font) * 5.5f; // five characters to a line
		let layout = Lay(font, "abcdefghijklmnop", width, true, scope .());
		Test.Assert(layout.Lines.Count == 4);
		Test.Assert(layout.Lines[0].End == 5);
		CheckCovers(layout, 16, width);
	}

	[Test]
	public static void ALongWordAfterAShortOneStartsItsOwnLineThenBreaks()
	{
		let font = DejaVu(scope .());
		let width = Advance(font) * 5.5f;
		let layout = Lay(font, "hi abcdefghij", width, true, scope .());
		Test.Assert(layout.Lines.Count == 3);
		Test.Assert(layout.Lines[0].End == 3); // "hi " alone
		Test.Assert(layout.Lines[1].End == 8);
		CheckCovers(layout, 13, width);
	}

	[Test]
	public static void ALineNarrowerThanACharacterStillHoldsOneAndAGraphemeIsNotSplit()
	{
		let font = DejaVu(scope .());
		let narrow = Lay(font, "abc", Advance(font) * 0.5f, true, scope .());
		Test.Assert(narrow.Lines.Count == 3);
		// e and a combining acute: one grapheme, two characters.
		let marks = Lay(font, "ae\u{0301}b", Advance(font) * 0.5f, true, scope .());
		Test.Assert(marks.Lines.Count == 3);
		Test.Assert(marks.Lines[1].Start == 1);
		Test.Assert(marks.Lines[1].End == 4);
	}

	[Test]
	public static void ItInheritsFromASheetAndNormalTurnsItOff()
	{
		let font = DejaVu(scope .());
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let panel = new Panel();
		defer panel.ReleaseRef();
		let label = new Label();
		defer label.ReleaseRef();
		root.AddChild(panel);
		panel.AddChild(label);
		panel.AddClass("page");
		label.Font = font.GetFont("DejaVu", 16.0f);
		label.AddClass("text");
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, ".page { overflow-wrap: break-word; }");
		styles.ApplyTree(root);
		Test.Assert(label.GetTextStyle().BreakWords);
		Test.Assert(label.GetTextLayout().BreakWords);
		WidgetFixtures.UseSheet(styles, ".page { overflow-wrap: anywhere; } .text { overflow-wrap: normal; }");
		styles.ApplyTree(root);
		Test.Assert(!label.GetTextStyle().BreakWords);
	}

	/// A font every character of which is 10 wide, CJK included: no font in the repository has CJK
	/// glyphs, and one without them measures them 0, so nothing would ever wrap.
	private class EvenFont : IFont
	{
		public override void GetFamilyName(String outName) { outName.Append("Even"); }
		public override Span<uint8> SourceData => default;
		public override FontMetrics Metrics => .(12.0f, -4.0f, 0.0f, 16.0f, 1.0f);
		public override float PixelHeight => 16.0f;

		public override GlyphInfo GetGlyphInfo(int32 codepoint)
		{
			var info = GlyphInfo();
			info.Codepoint = codepoint;
			info.AdvanceWidth = 10.0f;
			return info;
		}

		public override float GetKerning(int32 firstCodepoint, int32 secondCodepoint) => 0.0f;
		public override bool HasGlyph(int32 codepoint) => true;
		public override float MeasureString(StringView text) => MeasureString(text, scope .());

		public override float MeasureString(StringView text, List<GlyphPosition> outPositions)
		{
			float x = 0.0f;
			int at = 0;
			while (at < text.Length)
			{
				let start = at;
				let c = DecodeCodepoint(text, ref at);
				var position = GlyphPosition();
				position.Cluster = (int32)start;
				position.ClusterLength = (int32)(at - start);
				position.X = x;
				position.Advance = 10.0f;
				position.GlyphInfo = GetGlyphInfo((int32)c);
				outPositions.Add(position);
				x += 10.0f;
			}
			return x;
		}
	}

	private static TextLayout LayEven(CachedFont font, StringView text, float maxWidth, TextLayout outLayout)
	{
		let style = scope TextLayoutStyle();
		style.Font = font;
		style.Family.Set("Even");
		style.Size = 16.0f;
		style.MaxWidth = maxWidth;
		return LayOutText(TextFixtures.OneRun(text, scope .()), style, outLayout);
	}

	/// Pieces ended only at spaces, so 150 characters of Chinese or Japanese were one word that
	/// never wrapped and ran out of its box.
	[Test]
	public static void CjkTextWrapsBetweenItsCharactersAndKeepsItsPunctuationOffALinesStart()
	{
		let font = scope CachedFont(new EvenFont(), null); // owns and deletes the font
		let text = scope String();
		for (int i < 50)
			text.Append("漢字か");
		let layout = LayEven(font, text, 105.0f, scope .()); // ten characters to a line
		Test.Assert(layout.Lines.Count == 15, scope $"{layout.Lines.Count} lines");
		CheckCovers(layout, text.Length, 105.0f);

		// "。" may not start a line: the break before it moves back one character.
		let punctuated = scope String();
		for (int i < 10)
			punctuated.Append("漢");
		punctuated.Append("。字字");
		let kept = LayEven(font, punctuated, 105.0f, scope .());
		Test.Assert(kept.Lines.Count == 2, scope $"{kept.Lines.Count} lines");
		Test.Assert(punctuated.Substring(kept.Lines[1].Start, 3) == "漢");

		// Latin text still breaks only at its spaces.
		Test.Assert(LayEven(font, "abcdefghijklmnopqrstuvwxyz", 105.0f, scope .()).Lines.Count == 1);
		Test.Assert(!IsLineBreakBetween((uint32)'a', (uint32)'b'));
		Test.Assert(IsLineBreakBetween(0x6F22, 0x5B57));
		Test.Assert(!IsLineBreakBetween(0x300C, 0x6F22)); // nothing after an opening bracket
	}
}
