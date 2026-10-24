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

	[Test]
	public static void ASheetsDirectionAutoSetsALabelsParagraphsByItsTextItsBoxesByItsParent()
	{
		let font = DejaVu(scope .());
		BidiAlgorithm.Install();
		defer BidiAlgorithm.Uninstall();
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let panel = new Panel();
		defer panel.ReleaseRef();
		let label = new Label();
		defer label.ReleaseRef();
		root.AddChild(panel);
		panel.AddChild(label);
		panel.AddClass("page");
		label.AddClass("field");
		label.Font = font.GetFont("DejaVu", 16.0f);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, ".page { direction: rtl; } .field { direction: auto; }");
		styles.ApplyTree(root);

		Test.Assert(label.GetLayoutDirection() == .Auto);
		Test.Assert(label.IsRightToLeft); // its boxes: as the page's
		Test.Assert(label.GetTextLayout().Direction.Direction == .Auto);
		Test.Assert(label.GetTextLayout().Direction.AutoRightToLeft);
		label.Text = cLatinFirst;
		Test.Assert(!label.GetTextLayout().LayoutFor(Rect(0.0f, 0.0f, 400.0f, 40.0f)).Lines[0].RightToLeft);
		label.Text = cArabicFirst;
		Test.Assert(label.GetTextLayout().LayoutFor(Rect(0.0f, 0.0f, 400.0f, 40.0f)).Lines[0].RightToLeft);
		Test.Assert(label.Direction == "auto");
	}
}
