using System;
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
}
