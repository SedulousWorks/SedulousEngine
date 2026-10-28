using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The Console over its markup (Data/Editor/Console.gml): lines with their category, the levels'
/// chips (Info holding trace and debug, Error holding critical) with their counts showing and
/// hiding their lines, the search, the cap trimming the oldest, Clear, the empty line, a selection
/// kept by entry through a trim and copied oldest first, each line's time, and every line one
/// fixed height under the editor's sheet. Then what Sedulous
/// adds so each behaviour has a test: the search typed into its field and its x, a selection kept
/// through a filter for the lines still shown, rows picked out of order and ranges grown with
/// Shift, a copy announced with its count, each row's time and level colour, the newest line
/// followed until the user scrolls up, and the list's menu.
class LogViewTests
{
	/// The Console in a GUI of its own, 800 by 400, with a clipboard the test reads.
	private class ConsoleBed
	{
		public SceneRoot Root;
		public LauncherClipboard Clipboard = new .() ~ delete _;
		public LogView View;

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(800.0f, 400.0f);
			Root.EventDispatcher.Clipboard = Clipboard;
			View = new LogView(PagesBed.LoadMarkup(LogView.cMarkupPath));
			Test.Assert(View.Content != null);
			View.Content.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(800.0f);
					s.Height = LayoutLength.Px(400.0f);
				});
			Root.AddChild(View.Content);
		}

		public ~this()
		{
			DeleteAndNullify!(View); // the list let go while the tree holds it
			Root.EventDispatcher.Clipboard = null;
			Root.ReleaseRef();
		}

		public ListView List => View.List;

		public Sedulous.GUI.Button Chip(StringView id) => View.Content.FindElement(id) as Sedulous.GUI.Button;

		public Sedulous.GUI.Label Empty => View.Content.FindElement("console-empty") as Sedulous.GUI.Label;

		public bool Press(KeyCode key, uint32 modifiers = 0) => Root.EventDispatcher.InjectKeyDown((uint32)key, modifiers);

		/// The list a fixed 800 by `height`, so it scrolls and realises its rows; laid out.
		public void SizeList(float height)
		{
			List.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(800.0f);
					s.Height = LayoutLength.Px(height);
				});
			Layout();
		}

		public void Layout()
		{
			Root.UpdateLayout();
			Root.UpdateLayout();
		}
	}

	[Test]
	public static void LinesWithTheirCategoryTheLevelsFoldedIntoThreeChipsWithTheirCounts()
	{
		let bed = scope ConsoleBed();
		Test.Assert(bed.Empty.Displayed, "nothing yet");
		Test.Assert(bed.Empty.Text == "No messages yet.");
		bed.View.AddEntry(.Information, "Editor", "opened project");
		bed.View.AddEntry(.Trace, "RHI", "trace detail");
		bed.View.AddEntry(.Critical, "RHI", "device lost");
		bed.View.AddEntry(.Warning, "", "no category");
		Test.Assert(bed.View.EntryCount == 4);
		Test.Assert(bed.View.ShownCount == 4);
		Test.Assert(bed.View.ShownText(0) == "[Editor] opened project");
		Test.Assert(bed.View.ShownText(3) == "no category");
		Test.Assert(!bed.Empty.Displayed);

		Test.Assert(LogBucket.Of(.Trace) == .Info);
		Test.Assert(LogBucket.Of(.Debug) == .Info);
		Test.Assert(LogBucket.Of(.Information) == .Info);
		Test.Assert(LogBucket.Of(.Warning) == .Warning);
		Test.Assert(LogBucket.Of(.Error) == .Error);
		Test.Assert(LogBucket.Of(.Critical) == .Error);
		Test.Assert(bed.View.CountOf(.Info) == 2);
		Test.Assert(bed.View.CountOf(.Warning) == 1);
		Test.Assert(bed.Chip("console-info").Text == "Info 2");
		Test.Assert(bed.Chip("console-warnings").Text == "Warnings 1");
		Test.Assert(bed.Chip("console-errors").Text == "Errors 1");
	}

	[Test]
	public static void AChipHidesAndShowsItsLinesInTheirOrderTheSearchNarrowsThem()
	{
		let bed = scope ConsoleBed();
		bed.View.AddEntry(.Information, "A", "info");
		bed.View.AddEntry(.Warning, "A", "warn");
		bed.View.AddEntry(.Error, "A", "error");

		let warnings = bed.Chip("console-warnings");
		Test.Assert(warnings.HasClass("checked"));
		Test.Assert(warnings.HandleActivate()); // off
		Test.Assert(!bed.View.IsBucketVisible(.Warning));
		Test.Assert(!warnings.HasClass("checked"));
		Test.Assert(bed.View.ShownCount == 2);
		Test.Assert(bed.View.ShownText(1) == "[A] error");
		bed.View.AddEntry(.Warning, "A", "warn2"); // hidden while its chip is off
		Test.Assert(bed.View.ShownCount == 2);
		Test.Assert(bed.View.CountOf(.Warning) == 2, "counted though hidden");
		Test.Assert(warnings.HandleActivate()); // on again: in order
		Test.Assert(warnings.HasClass("checked"));
		Test.Assert(bed.View.ShownCount == 4);
		Test.Assert(bed.View.ShownText(1) == "[A] warn");
		Test.Assert(bed.View.ShownText(3) == "[A] warn2");
		// A call moves the chip too.
		bed.View.SetBucketVisible(.Error, false);
		Test.Assert(!bed.Chip("console-errors").HasClass("checked"));
		bed.View.SetBucketVisible(.Error, true);

		bed.View.SetSearch("WARN");
		Test.Assert(bed.View.ShownCount == 2);
		bed.View.SetSearch("[a]"); // the category is part of a line
		Test.Assert(bed.View.ShownCount == 4);
		bed.View.SetSearch("nowhere");
		Test.Assert(bed.View.ShownCount == 0);
		Test.Assert(bed.Empty.Displayed && (bed.Empty.Text == "No line matches."));
		Test.Assert((bed.View.Content.FindElement("console-clear-search") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(bed.View.ShownCount == 4);
	}

	[Test]
	public static void TheCapTrimsTheOldestASelectionKeptByEntryClearEmptiesIt()
	{
		let bed = scope ConsoleBed();
		for (int i < LogView.cMaxEntries)
			bed.View.AddEntry(.Information, "N", scope $"line {i}");
		let list = bed.List;
		list.SelectedItem = 10; // "line 10"
		bed.View.AddEntry(.Information, "N", "one more");
		Test.Assert(bed.View.EntryCount == LogView.cMaxEntries);
		Test.Assert(bed.View.ShownText(0) == "[N] line 1");
		Test.Assert(list.IsItemSelected(9), "the same line, one up");
		Test.Assert(bed.View.SelectedText(.. scope .()) == "[N] line 10");

		Test.Assert((bed.View.Content.FindElement("console-clear") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(bed.View.EntryCount == 0);
		Test.Assert(bed.View.ShownCount == 0);
		Test.Assert(bed.View.CountOf(.Info) == 0);
		Test.Assert(bed.Chip("console-info").Text == "Info");
		Test.Assert(bed.Empty.Displayed && (bed.Empty.Text == "No messages yet."));
	}

	/// A line rolling off the cap leaves its level's count.
	[Test]
	public static void ALineTrimmedLeavesItsLevelsCount()
	{
		let bed = scope ConsoleBed();
		bed.View.AddEntry(.Error, "A", "e1");
		for (int i < LogView.cMaxEntries - 1)
			bed.View.AddEntry(.Information, "N", "line");
		Test.Assert(bed.View.CountOf(.Error) == 1);
		bed.View.AddEntry(.Information, "N", "line");
		Test.Assert(bed.View.CountOf(.Error) == 0);
		Test.Assert(bed.Chip("console-errors").Text == "Errors");
		Test.Assert(bed.View.CountOf(.Info) == LogView.cMaxEntries);
		Test.Assert(bed.Chip("console-info").Text == "Info 1000");
	}

	[Test]
	public static void TheSelectedLinesCopiedOldestFirstOnePerLineCtrlCOnTheList()
	{
		let bed = scope ConsoleBed();
		bed.View.AddEntry(.Information, "A", "first");
		bed.View.AddEntry(.Warning, "B", "second");
		bed.View.AddEntry(.Error, "C", "third");
		int copied = 0;
		bed.View.SetOnCopied(new [&](lines) => { copied = lines; });
		let list = bed.List;
		list.SelectAll();
		bed.View.CopySelection();
		Test.Assert(bed.Clipboard.Held == "[A] first\n[B] second\n[C] third");
		Test.Assert(copied == 3);

		list.ClearSelection();
		list.SelectedItem = 2;
		Test.Assert(list.FocusElement());
		Test.Assert(bed.Press(.C, KeyModCtrl));
		Test.Assert(bed.Clipboard.Held == "[C] third");

		// Rows picked out of order copy oldest first: Ctrl moves the keyboard, Ctrl+Space picks.
		Test.Assert(bed.Press(.Up, KeyModCtrl));
		Test.Assert(bed.Press(.Up, KeyModCtrl));
		Test.Assert(bed.Press(.Space, KeyModCtrl));
		Test.Assert(bed.Press(.C, KeyModCtrl));
		Test.Assert(bed.Clipboard.Held == "[A] first\n[C] third");
		Test.Assert(copied == 2);

		// Nothing selected copies nothing, and says nothing.
		list.ClearSelection();
		bed.Clipboard.Held.Set("kept");
		copied = 0;
		bed.View.CopySelection();
		Test.Assert((bed.Clipboard.Held == "kept") && (copied == 0));
	}

	/// A filter keeps the selection of the lines it still shows; a hidden line's goes.
	[Test]
	public static void AFilterKeepsTheSelectionOfTheLinesStillShown()
	{
		let bed = scope ConsoleBed();
		bed.View.AddEntry(.Information, "A", "info");
		bed.View.AddEntry(.Warning, "A", "warn");
		bed.View.AddEntry(.Error, "A", "error");
		bed.List.SelectAll();
		bed.View.SetBucketVisible(.Warning, false);
		Test.Assert(bed.List.IsItemSelected(0) && bed.List.IsItemSelected(1));
		Test.Assert(bed.View.SelectedText(.. scope .()) == "[A] info\n[A] error");
		bed.View.SetBucketVisible(.Warning, true);
		Test.Assert(!bed.List.IsItemSelected(1), "hidden, it left the selection");
		Test.Assert(bed.View.SelectedText(.. scope .()) == "[A] info\n[A] error");
	}

	/// Shift and the arrows extend ONE range from where it started, as far as the user goes:
	/// three presses down select four rows, one back up leaves three.
	[Test]
	public static void ShiftArrowsGrowAndShrinkOneRange()
	{
		let bed = scope ConsoleBed();
		for (int i < 6)
			bed.View.AddEntry(.Information, "A", scope $"line{i}");
		let list = bed.List;
		list.SelectedItem = 1;
		Test.Assert(list.FocusElement());
		bed.Press(.Down, KeyModShift);
		bed.Press(.Down, KeyModShift);
		bed.Press(.Down, KeyModShift);
		Test.Assert(list.SelectionCount == 4);
		Test.Assert(bed.View.SelectedText(.. scope .()) == "[A] line1\n[A] line2\n[A] line3\n[A] line4");
		bed.Press(.Up, KeyModShift);
		Test.Assert(bed.View.SelectedText(.. scope .()) == "[A] line1\n[A] line2\n[A] line3");

		// Past the anchor the range flips to the other side of it.
		bed.Press(.Up, KeyModShift);
		bed.Press(.Up, KeyModShift);
		bed.Press(.Up, KeyModShift);
		Test.Assert(bed.View.SelectedText(.. scope .()) == "[A] line0\n[A] line1");

		// A plain arrow moves outright from where the range ended.
		bed.Press(.Down);
		Test.Assert((list.SelectionCount == 1) && (bed.View.SelectedText(.. scope .()) == "[A] line1"));
	}

	/// A copy the user asks for says so: the console's lines, and every other copy through
	/// the context, which warns instead when there is no clipboard to reach.
	[Test]
	public static void ACopyAnnouncesItself()
	{
		let context = scope EditorContext();
		let notices = scope List<String>();
		defer { ClearAndDeleteItems!(notices); }
		context.OnNotice = new [&](kind, message) => { notices.Add(new $"{kind}: {message}"); };
		let clipboard = scope LauncherClipboard();

		Test.Assert(context.CopyText(clipboard, "1234", "GUID"));
		Test.Assert((clipboard.Held == "1234") && (notices.Back == "Success: Copied GUID"));
		Test.Assert(!context.CopyText(null, "x", "path"));
		Test.Assert(notices.Back == "Warning: Could not copy path to the clipboard");
		context.CopyToEditorClipboard("component", scope uint8[](1, 2), "component 'Mesh'");
		Test.Assert((context.ClipboardKind == "component") && (notices.Back == "Success: Copied component 'Mesh'"));

		// The console reports how many lines it copied.
		let bed = scope ConsoleBed();
		int copied = 0;
		bed.View.SetOnCopied(new [&](lines) => { copied = lines; });
		bed.View.AddEntry(.Information, "A", "one");
		bed.View.AddEntry(.Information, "A", "two");
		Test.Assert(bed.List.FocusElement());
		bed.Press(.A, KeyModCtrl);
		bed.Press(.C, KeyModCtrl);
		Test.Assert(copied == 2);
		Test.Assert(bed.Clipboard.Held == "[A] one\n[A] two");
	}

	/// The search field narrows the lines as the user types, together with the chips, and
	/// applies to lines that arrive while it is set; its x shows with text and clears it.
	[Test]
	public static void TheSearchFieldNarrowsAsTheUserTypesItsXClearsIt()
	{
		let bed = scope ConsoleBed();
		bed.View.AddEntry(.Information, "Editor", "opened scene 'Main'");
		bed.View.AddEntry(.Warning, "Resource", "bind failed for 6c26");
		bed.View.AddEntry(.Error, "Editor", "Cook FAILED");
		let field = bed.View.Content.FindElement("console-search") as TextField;
		let clear = bed.View.Content.FindElement("console-clear-search") as Sedulous.GUI.Button;
		Test.Assert((field != null) && (clear != null));
		Test.Assert(!clear.Visible);

		Test.Assert(field.FocusElement());
		bed.Root.EventDispatcher.InjectText("failed");
		Test.Assert(bed.View.Search == "failed");
		Test.Assert(bed.View.ShownCount == 2, "either case");
		Test.Assert(bed.View.ShownText(0) == "[Resource] bind failed for 6c26");
		Test.Assert(clear.Visible);

		// Together with the chips.
		bed.View.SetBucketVisible(.Warning, false);
		Test.Assert((bed.View.ShownCount == 1) && (bed.View.ShownText(0) == "[Editor] Cook FAILED"));
		bed.View.SetBucketVisible(.Warning, true);

		// A new line shows only when it matches.
		bed.View.AddEntry(.Information, "Editor", "saved");
		Test.Assert(bed.View.ShownCount == 2);
		bed.View.AddEntry(.Information, "Editor", "retry failed");
		Test.Assert(bed.View.ShownCount == 3);

		// The x empties the field and shows every line again, and hides.
		Test.Assert(clear.HandleActivate());
		Test.Assert(field.Text.IsEmpty && bed.View.Search.IsEmpty);
		Test.Assert(bed.View.ShownCount == 5);
		Test.Assert(!clear.Visible);
	}

	/// Each row shows its line's time since the editor started and its text, in its level's
	/// colour (the sheet's, by the row's class).
	[Test]
	public static void EachRowShowsItsTimeAndItsLevelsColour()
	{
		let bed = scope ConsoleBed();
		bed.SizeList(200.0f);
		bed.View.AddEntry(.Debug, "A", "debug", TimeSpan(0, 1, 5));
		bed.View.AddEntry(.Information, "A", "info", TimeSpan(1, 2, 3));
		bed.View.AddEntry(.Warning, "A", "warn");
		bed.View.AddEntry(.Critical, "A", "critical");
		bed.Layout();
		StringView[4] times = .("00:01:05", "01:02:03", "00:00:00", "00:00:00");
		StringView[4] levels = .("debug", "", "warning", "error");
		StringView[3] classes = .("debug", "warning", "error");
		for (int32 i < 4)
		{
			let row = bed.List.RowForItem(i);
			Test.Assert(row != null);
			let content = row.Content as UIWidget;
			Test.Assert((content != null) && content.HasClass("log-row"));
			Test.Assert((content.GetChildAt(0) as Sedulous.GUI.Label).Text == times[i]);
			Test.Assert((content.GetChildAt(1) as Sedulous.GUI.Label).Text == bed.View.ShownText(i));
			for (let level in classes)
				Test.Assert(content.HasClass(level) == (level == levels[i]));
		}
	}

	/// The newest line is followed until the user scrolls up, and again once they are back at
	/// the bottom.
	[Test]
	public static void TheNewestLineIsFollowedUntilTheUserScrollsUp()
	{
		let bed = scope ConsoleBed();
		bed.SizeList(100.0f);
		for (int i < 50)
			bed.View.AddEntry(.Information, "N", scope $"line {i}");
		bed.Layout();
		let list = bed.List;
		Test.Assert(list.ScrollRange.Y > 0.0f);
		Test.Assert(list.ScrollOffset.Y >= list.ScrollRange.Y - 0.5f, "followed to the newest");

		list.ScrollOffset = .(0.0f, 0.0f); // the user scrolls up
		bed.View.AddEntry(.Information, "N", "while reading");
		bed.Layout();
		Test.Assert(list.ScrollOffset.Y == 0.0f, "not pulled down while reading");

		list.ScrollOffset = .(0.0f, list.ScrollRange.Y); // back at the bottom
		let bottom = list.ScrollOffset.Y;
		bed.View.AddEntry(.Information, "N", "followed again");
		bed.Layout();
		Test.Assert(list.ScrollOffset.Y > bottom);
		Test.Assert(list.ScrollOffset.Y >= list.ScrollRange.Y - 0.5f);
	}

	/// The list's menu: Copy (Ctrl+C, only with a selection), Select All, Clear.
	[Test]
	public static void TheListsMenuCopiesSelectsAllAndClears()
	{
		let bed = scope ConsoleBed();
		bed.SizeList(200.0f);
		bed.View.AddEntry(.Information, "A", "one");
		bed.View.AddEntry(.Warning, "A", "two");
		Test.Assert(bed.List.FocusElement());
		bed.Root.EventDispatcher.InjectContextMenu();
		var menu = bed.View.OpenMenu;
		Test.Assert(menu != null);
		Test.Assert(MenuRows.Is(menu, "Copy|Select All|-|Clear"));
		var copy = MenuRows.ItemNamed(menu, "Copy");
		Test.Assert((copy.Shortcut == "Ctrl+C") && !copy.Enabled, "nothing selected");
		Test.Assert(MenuRows.ItemNamed(menu, "Select All").HandleActivate());
		Test.Assert(bed.List.SelectionCount == 2);

		Test.Assert(bed.List.FocusElement());
		bed.Root.EventDispatcher.InjectContextMenu();
		menu = bed.View.OpenMenu;
		Test.Assert(menu != null);
		copy = MenuRows.ItemNamed(menu, "Copy");
		Test.Assert(copy.Enabled);
		Test.Assert(copy.HandleActivate());
		Test.Assert(bed.Clipboard.Held == "[A] one\n[A] two");

		Test.Assert(bed.List.FocusElement());
		bed.Root.EventDispatcher.InjectContextMenu();
		menu = bed.View.OpenMenu;
		Test.Assert(menu != null);
		Test.Assert(MenuRows.ItemNamed(menu, "Clear").HandleActivate());
		Test.Assert(bed.View.EntryCount == 0);
	}

	/// Under the editor's sheet every line is one fixed height (the sheet's `.log`), so scrolling
	/// moves the bar rather than resizing it.
	[Test]
	public static void UnderTheEditorsSheetEveryLineIsOneFixedHeight()
	{
		let bed = scope ConsoleBed();
		let sheet = scope EditorSheet(); // goes first, while the tree it styled is there
		for (int i < 200)
			bed.View.AddEntry(.Information, "N", scope $"line {i}");
		sheet.Apply(bed.Root);
		let list = bed.List;
		Test.Assert(list.RowHeight == 22.0f);
		let range = list.ScrollRange.Y;
		Test.Assert(range > 0.0f, "the lines overflow the list");
		list.ScrollToItem(0);
		bed.Layout();
		Test.Assert(list.ScrollOffset.Y == 0.0f);
		Test.Assert(Math.Abs(list.ScrollRange.Y - range) < 0.5f, "the content's height holds at the top");
	}
}
