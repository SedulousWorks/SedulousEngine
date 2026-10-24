using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A focused area 54 wide (nine characters a line) and 36 tall (three lines) in the mock font (6px
/// a byte, 12px a line). The font, the root and the area go with it.
class AreaBed
{
	// Declared first, so it goes last: the area borrows it.
	public CachedFont Font = new .(new MockFont(), null) ~ delete _;
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 300.0f) ~ _.ReleaseRef();
	public TextArea Area = new .() ~ _.ReleaseRef();

	public this(StringView text)
	{
		Area.Size = .(54.0f, 36.0f);
		Area.Font = Font;
		Root.AddChild(Area);
		Area.Text = text;
		Area.RequestFocus();
	}

	public EventDispatcher D => Root.EventDispatcher;
}

/// TextArea: Return breaks a line, `rows` sizes it, up and down move by the lines it shows, it
/// scrolls to keep the caret in view, and a scroller round it does as it grows.
class TextAreaTests
{
	private static bool Near(float a, float b) => TextFixtures.Near(a, b);
	private static uint32 Key(KeyCode k) => (uint32)k;

	[Test]
	public static void ReturnBreaksALineItIsRowsLinesTallWhenNothingSizesIt()
	{
		let bed = scope AreaBed("ab");
		bed.D.InjectKeyDown(Key(.Return));
		bed.D.InjectText("cd");
		Test.Assert(bed.Area.Text == "ab\ncd");
		int submits = 0;
		bed.Area.SetOnSubmit(new [&] (text) => { ++submits; });
		bed.D.InjectKeyDown(Key(.Return));
		Test.Assert(submits == 0); // a text area's Return is a line break
		bed.Area.Rows = 5;
		Test.Assert(Near(bed.Area.MeasureContent(.(cUnbounded, cUnbounded)).Y, 60.0f));
	}

	[Test]
	public static void UpAndDownMoveByShownLinesAndKeepTheirColumnHomeAndEndStopAtAWrap()
	{
		// "alpha beta gamma" wraps at nine characters: "alpha " | "beta " | "gamma".
		let bed = scope AreaBed("alpha beta gamma");
		bed.Area.Caret = 2; // al|pha
		bed.D.InjectKeyDown(Key(.Down));
		Test.Assert(bed.Area.Caret == 8); // be|ta
		bed.D.InjectKeyDown(Key(.Down));
		Test.Assert(bed.Area.Caret == 13); // ga|mma
		bed.D.InjectKeyDown(Key(.Up));
		bed.D.InjectKeyDown(Key(.Up));
		Test.Assert(bed.Area.Caret == 2);
		bed.D.InjectKeyDown(Key(.End));
		Test.Assert(bed.Area.Caret == 5); // before the space the line broke at
		bed.D.InjectKeyDown(Key(.Down), KeyModShift);
		Test.Assert(bed.Area.SelectedText == " beta");
		bed.D.InjectKeyDown(Key(.Home));
		Test.Assert(bed.Area.Caret == 6); // the start of "beta", the line it shows on
	}

	[Test]
	public static void ItScrollsDownToKeepTheCaretInViewPageKeysMoveAPage()
	{
		let bed = scope AreaBed("1\n2\n3\n4\n5\n6\n7\n8");
		// The caret at the end, on the eighth line of three shown: scrolled to show it.
		Test.Assert(Near(bed.Area.ScrollY, 8.0f * 12.0f - 36.0f));
		bed.D.InjectKeyDown(Key(.Home), KeyModCtrl);
		Test.Assert(Near(bed.Area.ScrollY, 0.0f));
		bed.D.InjectKeyDown(Key(.PageDown));
		Test.Assert(bed.Area.Caret == 6); // three lines down: the start of "4"
		// A click maps through the scroll.
		bed.D.InjectKeyDown(Key(.End), KeyModCtrl);
		bed.D.InjectMouseDown(.(1.0f, 1.0f), .Left);
		Test.Assert(bed.Area.Caret == 10); // the top shown line is "6"
	}

	[Test]
	public static void AsTallAsItsTextInAScrollerTheScrollerKeepsTheCaretInViewAsItIsTypedIn()
	{
		let font = scope CachedFont(new MockFont(), null);
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let @box = new UIWidget();
		defer @box.ReleaseRef();
		let area = new TextArea();
		defer area.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		@box.EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Column;
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(36.0f);
				s.OverflowY = .Auto;
			});
		area.Font = font;
		area.Rows = 10; // 120 tall, in a box 36 tall
		@box.AddChild(area);
		root.AddChild(@box);
		root.UpdateLayout();
		area.RequestFocus();
		Test.Assert(Near(@box.ScrollOffset.Y, 0.0f));
		for (int i = 0; i < 6; ++i)
			root.EventDispatcher.InjectKeyDown(Key(.Return));
		// The caret on the seventh line (72 to 84): the box scrolled by the least that shows it.
		Test.Assert(Near(area.ScrollY, 0.0f));
		Test.Assert(Near(@box.ScrollOffset.Y, 84.0f - 36.0f));
		root.EventDispatcher.InjectKeyDown(Key(.Home), KeyModCtrl);
		Test.Assert(Near(@box.ScrollOffset.Y, 0.0f));
		area.Font = null;
	}

	[Test]
	public static void MarkupAndScriptsMakeOneByItsElementName()
	{
		RegisterGuiElements();
		Test.Assert(ElementTypes.Find("TextArea") == TextArea.StaticGuiType);
		Test.Assert(ElementTypes.Find("RichText") == RichText.StaticGuiType);
	}
}
