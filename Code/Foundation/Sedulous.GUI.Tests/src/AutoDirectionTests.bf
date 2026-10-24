using System;
using Sedulous.Fonts;
using Sedulous.Fonts.Bidi;
using Sedulous.Fonts.TrueType;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// direction: auto: each paragraph of a node's text runs as its first strong character reads, typed
/// or translated; one with none runs as the node's boxes do. With the resolver installed and
/// without. Over DejaVu Sans Mono, which draws Arabic.
class AutoDirectionTests
{
	/// Salaam, then a Latin word.
	private const String cArabicFirst = "\u{0633}\u{0644}\u{0627}\u{0645} ok";
	private const String cLatinFirst = "ok \u{0633}\u{0644}\u{0627}\u{0645}";

	private static TrueTypeFontService DejaVu(TrueTypeFontService service)
	{
		TextFixtures.Load(service, "DejaVu", TextFixtures.cDejaVuMono);
		return service;
	}

	private static TextLayout Lay(TrueTypeFontService font, StringView text, bool autoRightToLeft, TextLayout outLayout)
	{
		let style = scope TextLayoutStyle();
		style.Font = font.GetFont("DejaVu", 16.0f);
		style.Family.Set("DejaVu");
		style.Size = 16.0f;
		style.Direction = .Auto;
		style.AutoRightToLeft = autoRightToLeft;
		return LayOutText(TextFixtures.OneRun(text, scope .()), style, outLayout);
	}

	[Test]
	public static void AParagraphRunsAsItsFirstStrongCharacterReadsEachParagraphItsOwn()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		Test.Assert(Lay(font, cArabicFirst, false, scope .()).Lines[0].RightToLeft);
		Test.Assert(!Lay(font, cLatinFirst, true, scope .()).Lines[0].RightToLeft);
		let two = scope String(cArabicFirst);
		two.Append("\n");
		two.Append(cLatinFirst);
		let layout = Lay(font, two, false, scope .());
		Test.Assert(layout.Lines.Count == 2);
		Test.Assert(layout.Lines[0].RightToLeft);
		Test.Assert(!layout.Lines[1].RightToLeft);
	}

	[Test]
	public static void DigitsAndPunctuationAloneRunAsTheNodeDoes()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		Test.Assert(Lay(font, "42 - 7", true, scope .()).Lines[0].RightToLeft);
		Test.Assert(!Lay(font, "42 - 7", false, scope .()).Lines[0].RightToLeft);
		Test.Assert(Lay(font, "", true, scope .()).Lines[0].RightToLeft); // an empty field's caret on its node's start
	}

	[Test]
	public static void WithoutAResolverTheFirstStrongCharacterStillDecides()
	{
		let font = DejaVu(scope .());
		Test.Assert(Lay(font, cArabicFirst, false, scope .()).Lines[0].RightToLeft);
		Test.Assert(!Lay(font, cLatinFirst, true, scope .()).Lines[0].RightToLeft);
	}
}
