using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// A tool bar `width` across and 28 tall in a root 800 by 600. The root goes with it, and the
/// buttons and lines it made.
class ToolBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public ToolBar Bar = new .() ~ _.ReleaseRef();
	private List<Node> mMade = new .() ~ { for (let node in _) node.ReleaseRef(); delete _; };

	public this(float width = 200.0f)
	{
		Root = NewRoot(800.0f, 600.0f);
		Root.AddChild(Bar);
		Width(width);
	}

	public void Width(float width)
	{
		Bar.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(width);
				s.Height = LayoutLength.Px(28.0f);
			});
		Lay();
	}

	public void Lay()
	{
		Root.UpdateLayout();
	}

	public void Frame() => ToolkitFixtures.Frame(Root);

	/// A button of a size of its own (no sheet, no font).
	public ToolButton Button(float width = 40.0f)
	{
		let b = new ToolButton();
		b.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(width);
				s.Height = LayoutLength.Px(24.0f);
			});
		Bar.AddChild(b);
		mMade.Add(b);
		return b;
	}

	public Separator Line()
	{
		let s = new Separator();
		Bar.AddChild(s);
		mMade.Add(s);
		return s;
	}

	/// Holds `node` for the bed (it releases it).
	public T Hold<T>(T node) where T : Node
	{
		mMade.Add(node);
		return node;
	}

	public EventDispatcher D => Root.EventDispatcher;
}

/// The tool bar: its buttons name commands and show what the command says (label, keys, checked,
/// why it is disabled) in their tooltips; what does not fit goes into an overflow menu, the lowest
/// priority then the last first, separators only between shown items, a widget no menu row can stand
/// for never going; drop-down and split menu buttons; a column, right to left, and markup.
class ToolBarTests
{
	[Test]
	public static void AButtonBoundToACommandShowsItsIconAloneItsTooltipTheLabelTheKeysAndWhyItIsDisabled()
	{
		let bed = scope ToolBed();
		let save = bed.Button();
		save.Icon = "save.svg";
		bed.Root.OnCommand("file.save", new (command) => { });
		let command = bed.Root.Context.DefineCommand("file.save");
		command.Label = "Save";
		command.DisabledReason = "Nothing to save";
		Test.Assert(bed.Root.Context.Keymap.Bind("ctrl-s", "file.save"));
		save.Command = "file.save";
		bed.Frame();

		Test.Assert(save.Label == "Save");
		Test.Assert(save.TextPart != null);
		Test.Assert(!save.TextPart.Displayed); // an icon: its text does not show
		Test.Assert(save.TooltipText == "Save (Ctrl+S)");

		command.Enabled = false;
		bed.Frame();
		Test.Assert(!save.Enabled);
		Test.Assert(save.TooltipText == "Save (Ctrl+S)\nNothing to save");

		save.ShowsText = true; // asked: its text beside its icon
		Test.Assert(save.TextPart.Displayed);
		save.Tooltip = "Write the scene"; // its own tooltip wins
		Test.Assert(save.TooltipText == "Write the scene");

		// With no icon its text shows.
		let plain = bed.Button();
		plain.Text = "Build";
		Test.Assert(plain.TextPart.Displayed);
		Test.Assert(plain.TooltipText == "Build");
	}

	[Test]
	public static void WhatDoesNotFitOverflowsTheLowestPriorityFirstThenTheLastTheOverflowButtonAtTheEnd()
	{
		let bed = scope ToolBed(200.0f); // 192 inside its padding
		let b = scope List<ToolButton>();
		for (int32 i = 0; i < 6; ++i)
			b.Add(bed.Button());
		b[1].OverflowPriority = -1;
		bed.Lay();

		// Six of 40 with gaps of 2 ask 250; four fit with the overflow button (12) after them.
		Test.Assert(!b[1].Visible); // the lowest priority went first
		Test.Assert(!b[5].Visible); // then the last
		Test.Assert(b[0].Visible);
		Test.Assert(b[2].Visible);
		Test.Assert(b[4].Visible);
		Test.Assert(bed.Bar.Overflowed.Length == 2);
		Test.Assert(bed.Bar.Overflowed[0] == b[1]); // in bar order
		Test.Assert(bed.Bar.Overflowed[1] == b[5]);
		let overflow = bed.Bar.OverflowButton;
		Test.Assert(overflow.Visible);
		CheckNear(b[0].Position.X, 4.0f);
		CheckNear(b[2].Position.X, 46.0f); // the hidden one leaves no gap
		CheckNear(overflow.Position.X + overflow.Size.X, 196.0f); // at the end

		// Room again: everything shows, and no overflow button.
		bed.Width(400.0f);
		for (let button in b)
			Test.Assert(button.Visible);
		Test.Assert(bed.Bar.Overflowed.IsEmpty);
		Test.Assert(!overflow.Visible);
	}

	[Test]
	public static void ASeparatorShowsOnlyBetweenShownItemsAWidgetNoMenuRowStandsForNeverOverflows()
	{
		let bed = scope ToolBed(400.0f);
		let lead = bed.Line(); // nothing before it
		bed.Button();
		let between = bed.Line();
		let twice = bed.Line(); // right after another
		bed.Button();
		let trailing = bed.Line(); // nothing after it
		bed.Lay();
		Test.Assert(!lead.Visible);
		Test.Assert(between.Visible);
		Test.Assert(!twice.Visible);
		Test.Assert(!trailing.Visible);
		Test.Assert(bed.Bar.Overflowed.Length == 3); // the separators left out
		Test.Assert(!bed.Bar.OverflowButton.Visible); // but no item: nothing overflows

		// A field wider than the bar: the buttons go, the field stays.
		let narrow = scope ToolBed(100.0f);
		let button = narrow.Button();
		let field = narrow.Hold(new Panel());
		field.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(150.0f);
				s.Height = LayoutLength.Px(20.0f);
			});
		narrow.Bar.AddChild(field);
		narrow.Lay();
		Test.Assert(!button.Visible);
		Test.Assert(field.Visible);
	}

	[Test]
	public static void TheOverflowMenuStandsForEachButtonACommandsRowWithItsCheckedStateAClicksRow()
	{
		let bed = scope ToolBed(110.0f); // two fit with the overflow button
		let first = bed.Button();
		bed.Button();
		let grid = bed.Button();
		let snap = bed.Button();
		int grids = 0;
		int snaps = 0;
		bed.Root.OnCommand("view.grid", new [&] (command) => { ++grids; });
		let command = bed.Root.Context.DefineCommand("view.grid");
		command.Label = "Grid";
		command.Checked = true;
		grid.IsToggle = true;
		grid.Command = "view.grid";
		snap.Text = "Snap";
		snap.SetOnClick(new [&] () => { ++snaps; });
		bed.Frame();
		Test.Assert(!grid.Visible);
		Test.Assert(!snap.Visible);

		let barSize = bed.Bar.Size;
		let firstAt = first.Position;
		Click(bed.D, Middle(bed.Bar.OverflowButton));
		bed.Frame();
		let menu = bed.Bar.OverflowMenu;
		Test.Assert(menu != null);
		// The open menu is the bar's child (in the top layer), not one of its items.
		Test.Assert(menu.Parent == bed.Bar);
		CheckNear(bed.Bar.Size.Y, barSize.Y);
		CheckNear(first.Position.X, firstAt.X);
		Test.Assert(first.Visible);
		Test.Assert(bed.Bar.Overflowed.Length == 2);
		let rows = scope List<MenuItem>();
		Collect(menu, rows);
		Test.Assert(rows.Count == 2);
		Test.Assert(rows[0].Text == "Grid"); // the command's label
		Test.Assert(rows[0].Checkable);
		Test.Assert(rows[0].Checked);
		Test.Assert(rows[1].Text == "Snap");

		Click(bed.D, Middle(rows[0]));
		bed.Frame();
		Test.Assert(grids == 1);
		Test.Assert(bed.Bar.OverflowMenu == null); // picked: it closed

		Click(bed.D, Middle(bed.Bar.OverflowButton));
		bed.Frame();
		rows.Clear();
		Collect(bed.Bar.OverflowMenu, rows);
		Test.Assert(rows.Count == 2);
		Click(bed.D, Middle(rows[1]));
		Test.Assert(snaps == 1);
	}

	[Test]
	public static void ADropDownOpensItsMenuOnAClickASplitButtonRunsItsCommandItsArrowOpensTheMenu()
	{
		let bed = scope ToolBed(400.0f);
		let drop = bed.Hold(new ToolMenuButton());
		drop.Text = "Add";
		drop.Menu.AddItem("Cube", new () => { });
		bed.Bar.AddChild(drop);
		let split = bed.Hold(new ToolMenuButton());
		split.Text = "Play";
		split.IsSplit = true;
		int plays = 0;
		split.SetOnClick(new [&] () => { ++plays; });
		split.Menu.AddItem("Play from here", new () => { });
		bed.Bar.AddChild(split);
		ToolMenuButton[2] both = .(drop, split);
		for (let b in both)
		{
			b.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(80.0f);
					s.Height = LayoutLength.Px(24.0f);
				});
		}
		bed.Frame();

		Click(bed.D, Middle(drop));
		bed.Frame();
		Test.Assert(drop.GetOpenMenu() != null);
		drop.Menu.Close();
		bed.Frame();

		// The body runs it; the arrow opens the menu.
		Click(bed.D, split.ConvertToWorldSpace(.(10.0f, 12.0f)));
		bed.Frame();
		Test.Assert(plays == 1);
		Test.Assert(split.GetOpenMenu() == null);
		Click(bed.D, Middle(split.ArrowPart));
		bed.Frame();
		Test.Assert(plays == 1);
		Test.Assert(split.GetOpenMenu() != null);
	}

	[Test]
	public static void InAColumnItsItemsRunDownAndOverflowAtTheBottomRightToLeftTheyStartAtTheRight()
	{
		let bed = scope ToolBed(36.0f);
		bed.Bar.IsVertical = true;
		bed.Bar.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(100.0f); });
		let a = bed.Button(28.0f);
		let b = bed.Button(28.0f);
		bed.Button(28.0f);
		let d = bed.Button(28.0f);
		bed.Lay();
		CheckNear(a.Position.Y, 2.0f);
		CheckNear(b.Position.Y, 28.0f); // 24 tall and a gap of 2
		Test.Assert(!d.Visible);
		Test.Assert(bed.Bar.OverflowButton.Visible);

		let rtl = scope ToolBed(400.0f);
		rtl.Root.SetLayoutDirection(.RightToLeft);
		let first = rtl.Button();
		let second = rtl.Button();
		rtl.Lay();
		CheckNear(first.Position.X + first.Size.X, 396.0f);
		CheckNear(second.Position.X + second.Size.X, 354.0f);
	}

	[Test]
	public static void MarkupMakesABarOfToolButtonsASeparatorAndAMenuButtonWhoseChildrenAreItsMenus()
	{
		let made = Load(
			"<ToolBar orientation=\"horizontal\">\n" +
			"    <ToolButton command=\"file.save\" icon=\"save.svg\" overflow-priority=\"2\"/>\n" +
			"    <Separator/>\n" +
			"    <ToolMenuButton text=\"Add\" split=\"true\">\n" +
			"        <MenuItem text=\"Cube\"/>\n" +
			"        <MenuItem text=\"Sphere\"/>\n" +
			"    </ToolMenuButton>\n" +
			"</ToolBar>");
		Test.Assert(made != null);
		defer made.ReleaseRef();
		let bar = made as ToolBar;
		Test.Assert(bar != null);
		let buttons = scope List<ToolButton>();
		Collect(bar, buttons);
		Test.Assert(buttons.Count == 2);
		Test.Assert(buttons[0].Command == "file.save");
		Test.Assert(buttons[0].OverflowPriority == 2);
		let add = buttons[1] as ToolMenuButton;
		Test.Assert(add != null);
		Test.Assert(add.IsSplit);
		let rows = scope List<MenuItem>();
		Collect(add.Menu, rows);
		Test.Assert(rows.Count == 2);
	}

	[Test]
	public static void MarkupsVerticalBarStaysAColumnThroughARestyleItsSeparatorsLyingAcross()
	{
		let made = Load(
			"<ToolBar orientation=\"vertical\" height=\"200\">\n" +
			"    <ToolButton text=\"A\"/>\n" +
			"    <Separator/>\n" +
			"    <ToolButton text=\"B\"/>\n" +
			"</ToolBar>");
		let bar = made as ToolBar;
		Test.Assert(bar != null);
		let root = NewRoot(400.0f, 400.0f);
		defer root.ReleaseRef();
		root.AddChild(bar);
		made.ReleaseRef(); // the root's keeps it
		let styles = scope StyleManager();
		let sheet = scope StyleSheet();
		CSSParser.Parse(ToolkitSheetCSS(), sheet);
		styles.UserAgentSheet = sheet;
		styles.ApplyTree(root);
		styles.ApplyTree(root); // and again: a restyle keeps it
		root.UpdateLayout();
		Test.Assert(bar.IsVertical);
		Test.Assert(bar.OrientationName == "vertical");
		let buttons = scope List<ToolButton>();
		Collect(bar, buttons);
		Test.Assert(buttons.Count == 2);
		Test.Assert(buttons[1].Position.Y > buttons[0].Position.Y); // one below the other
		CheckNear(buttons[1].Position.X, buttons[0].Position.X);
		let lines = scope List<Separator>();
		Collect(bar, lines);
		Test.Assert(lines.Count == 1);
		Test.Assert(!lines[0].IsVertical); // it lies across a column
	}

	[Test]
	public static void AnItemsBoxSitsInsideItsMarginsASeparatorASheetMakesShorterIsCentredNotStretched()
	{
		let bed = scope ToolBed(400.0f);
		let a = bed.Button();
		let line = bed.Line();
		let b = bed.Button();
		line.EditLayoutStyle(scope (s) =>
			{
				s.Margin = Thickness(4.0f, 0.0f, 4.0f, 0.0f);
				s.Width = LayoutLength.Px(1.0f);
				s.Height = LayoutLength.Px(12.0f);
			});
		bed.Lay();
		Test.Assert(line.Visible);
		let aEnd = a.Position.X + a.Size.X;
		CheckNear(line.Size.X, 1.0f); // its own width, not its slot with its margins
		CheckNear(line.Position.X, aEnd + 2.0f + 4.0f); // past the gap and its margin
		CheckNear(b.Position.X, aEnd + 2.0f + 9.0f + 2.0f); // its slot: 4 + 1 + 4
		CheckNear(line.Size.Y, 12.0f); // its height, not the bar's
		let content = 28.0f - bed.Bar.Padding.TotalVertical;
		CheckNear(line.Position.Y, bed.Bar.Padding.Top + (content - 12.0f) * 0.5f);

		// With no height of its own it stands across the whole bar, inside its margins.
		line.EditLayoutStyle(scope (s) => { s.Height = LayoutLength(); });
		bed.Lay();
		CheckNear(line.Size.Y, content);
	}

	// What no Raptor test covers: the orientation's name either way, and a disabled reason's line with
	// no keys.
	[Test]
	public static void TheOrientationReadsBackAndATooltipWithNoKeysHasOnlyTheReason()
	{
		let bed = scope ToolBed(400.0f);
		Test.Assert(bed.Bar.OrientationName == "horizontal");
		bed.Bar.OrientationName = "vertical";
		Test.Assert(bed.Bar.IsVertical);
		Test.Assert(bed.Bar.LayoutStyle.Direction == .Column);
		bed.Bar.OrientationName = "sideways";
		Test.Assert(!bed.Bar.IsVertical);

		let button = bed.Button();
		bed.Root.OnCommand("edit.cut", new (command) => { });
		let command = bed.Root.Context.DefineCommand("edit.cut");
		command.Label = "Cut";
		command.DisabledReason = "Nothing selected";
		command.Enabled = false;
		button.Command = "edit.cut";
		bed.Frame();
		Test.Assert(button.TooltipText == "Cut\nNothing selected");
	}
}
