using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Markup coverage: every control is a markup element. A scroll bar is a range like the slider,
/// and a message box waits in its page until a script shows it.
class MarkupCoverageTests
{
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1e-5;

	[Test]
	public static void EveryControlIsAnElement()
	{
		String[?] controls = .(
			"<Label/>", "<Button/>", "<CheckBox/>", "<RadioButton/>", "<ToggleSwitch/>", "<Slider/>",
			"<ScrollBar/>", "<ProgressBar/>", "<NumberField/>", "<TextField/>", "<TextArea/>",
			"<EditableLabel/>", "<RichText/>", "<Image/>", "<Separator/>", "<Spacer/>", "<Panel/>",
			"<ScrollView/>", "<Expander/>", "<ComboBox/>", "<ListBox/>",
			"<TabBar/>", "<TabView/>", "<Menu/>", "<MenuBar/>", "<Window/>",
			"<MessageBox/>");
		for (let markup in controls)
		{
			let made = MarkupFixtures.Load(markup);
			Test.Assert(made != null, markup);
			made?.ReleaseRef();
		}
	}

	[Test]
	public static void AScrollBarIsARangeWithAnOrientationAndAPage()
	{
		let tree = MarkupFixtures.Load("<ScrollBar orientation=\"vertical\" min=\"0\" max=\"100\" page=\"25\" value=\"40\"/>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let bar = tree as ScrollBar;
		Test.Assert(bar != null);
		Test.Assert(bar.Orientation == .Vertical);
		Test.Assert(Near(bar.Page, 25.0));
		Test.Assert(Near(bar.Value, 40.0));
	}

	[Test]
	public static void AMessageBoxWaitsUnseenInItsPageIsShownModalAndGoesBackAnswered()
	{
		let root = SceneFixtures.NewScene(800.0f, 600.0f);
		defer root.ReleaseRef();
		let page = MarkupFixtures.Load(
			"<Panel><Label text=\"before\"/><MessageBox id=\"ask\" title=\"Delete?\" text=\"It cannot be undone.\" buttons=\"ok-cancel\"/><Label text=\"after\"/></Panel>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		root.AddChild(page);
		root.UpdateLayout();
		let @box = page.GetChildAt(1) as MessageBox;
		Test.Assert(@box != null);
		Test.Assert(!@box.Displayed);
		Test.Assert(@box.Message == "It cannot be undone.");
		Test.Assert(@box.ButtonCount == 2);

		int changes = 0;
		@box.AddEventListener(.Changed, new [&] (e) => { ++changes; });
		@box.Show();
		Test.Assert(@box.IsOpen);
		Test.Assert(@box.IsModal);
		Test.Assert(@box.Displayed);
		Test.Assert(@box.Parent != page);

		// Escape answers with the leftmost button (Cancel).
		root.EventDispatcher.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!@box.IsOpen);
		Test.Assert(@box.ResultName == "cancel");
		Test.Assert(changes == 1);
		// Back in its place, unseen, ready to be shown again.
		Test.Assert(@box.Parent == page);
		Test.Assert(page.GetChildIndex(@box) == 1);
		Test.Assert(!@box.Displayed);
		@box.Show();
		Test.Assert(@box.IsOpen);
	}
}
