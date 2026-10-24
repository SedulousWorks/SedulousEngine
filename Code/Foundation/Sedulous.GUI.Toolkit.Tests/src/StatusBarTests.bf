using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// A status bar 600 by 24 in a root 800 by 600. The root goes with it.
class StatusBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public StatusBar Bar = new .() ~ _.ReleaseRef();
	private List<StatusItem> mItems = new .() ~ { for (let item in _) item.ReleaseRef(); delete _; };

	public this()
	{
		Root = NewRoot(800.0f, 600.0f);
		Bar.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(600.0f);
				s.Height = LayoutLength.Px(24.0f);
			});
		Root.AddChild(Bar);
	}

	/// An item of a width of its own, held by the bed.
	public StatusItem Item(StringView id, StatusZone zone, int32 order = 0, StringView title = "")
	{
		let item = new StatusItem();
		item.Id = id;
		item.Zone = zone;
		item.Order = order;
		item.Title = title;
		item.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(60.0f);
				s.Height = LayoutLength.Px(16.0f);
			});
		Bar.AddItem(item);
		mItems.Add(item);
		return item;
	}

	public void Frame(float seconds = 0.016f) => ToolkitFixtures.Frame(Root, seconds);
}

/// The status bar: items by id in a start and an end zone, in their order; a message held until
/// replaced or for its seconds on the GUI's clock; items with a title hidden and shown from the bar's
/// menu, the application told; markup.
class StatusBarTests
{
	[Test]
	public static void ItemsByIdInAStartAndAnEndZoneInTheirOrderTheEndZoneAtTheEnd()
	{
		let bed = scope StatusBed();
		let mode = bed.Item("mode", .Start, 1);
		let branch = bed.Item("branch", .Start, 0);
		let cursor = bed.Item("cursor", .End);
		bed.Frame();

		let start = scope List<StatusItem>();
		bed.Bar.GetItems(.Start, start);
		Test.Assert(start.Count == 2);
		Test.Assert(start[0] == branch); // order 0 before order 1
		Test.Assert(start[1] == mode);
		Test.Assert(branch.ConvertToWorldSpace(.(0.0f, 0.0f)).X < mode.ConvertToWorldSpace(.(0.0f, 0.0f)).X);
		CheckNear(cursor.ConvertToWorldSpace(.(60.0f, 0.0f)).X, 592.0f); // inside the end padding
		Test.Assert(bed.Bar.FindItem("cursor") == cursor);

		Test.Assert(bed.Bar.RemoveItem("mode"));
		Test.Assert(bed.Bar.FindItem("mode") == null);
		Test.Assert(!bed.Bar.RemoveItem("mode"));

		// Moved to the other zone, it goes there.
		branch.Zone = .End;
		let end = scope List<StatusItem>();
		bed.Bar.GetItems(.End, end);
		Test.Assert(end.Count == 2);
		start.Clear();
		bed.Bar.GetItems(.Start, start);
		Test.Assert(start.IsEmpty);

		// Right to left, the end zone is at the left.
		bed.Root.SetLayoutDirection(.RightToLeft);
		bed.Frame();
		Test.Assert(cursor.ConvertToWorldSpace(.(0.0f, 0.0f)).X < 300.0f);
	}

	[Test]
	public static void AMessageHoldsUntilReplacedOrForItsSecondsOnTheGuisClock()
	{
		let bed = scope StatusBed();
		bed.Item("branch", .Start);
		bed.Bar.ShowMessage("Saved", 2.0f);
		bed.Frame();
		Test.Assert(bed.Bar.Message == "Saved");
		Test.Assert(bed.Bar.MessagePart.Displayed);
		bed.Frame(1.0f);
		Test.Assert(bed.Bar.Message == "Saved");
		bed.Frame(1.5f);
		Test.Assert(bed.Bar.Message.Length == 0);
		Test.Assert(!bed.Bar.MessagePart.Displayed);

		// A timed message replaced by one that holds: the first's time ends nothing.
		bed.Bar.ShowMessage("Building", 1.0f);
		bed.Frame();
		bed.Bar.ShowMessage("Ready");
		bed.Frame(2.0f);
		bed.Frame(2.0f);
		Test.Assert(bed.Bar.Message == "Ready");
		bed.Bar.ClearMessage();
		Test.Assert(bed.Bar.Message.Length == 0);
	}

	[Test]
	public static void ItsMenuListsTheItemsWithATitlePickingOneHidesOrShowsItAndTheApplicationHearsIt()
	{
		let bed = scope StatusBed();
		bed.Item("branch", .Start, 0, "Branch");
		bed.Item("fps", .End, 0, "Frame rate");
		bed.Item("fixed", .End); // no title: not in the menu
		let heard = scope List<String>();
		defer { ClearAndDeleteItems!(heard); }
		bed.Bar.SetOnItemShownChanged(new [&] (id, shown) => { heard.Add(new String()..AppendF("{}={}", id, shown ? "shown" : "hidden")); });
		bed.Frame();

		Test.Assert(bed.Bar.OpenItemsMenu(.(100.0f, 20.0f)));
		bed.Frame();
		let menu = bed.Bar.ItemsMenu;
		Test.Assert(menu != null);
		let rows = scope List<MenuItem>();
		Collect(menu, rows);
		Test.Assert(rows.Count == 2);
		Test.Assert(rows[0].Text == "Branch");
		Test.Assert(rows[1].Text == "Frame rate");
		Test.Assert(rows[1].Checked);

		Test.Assert(rows[1].HandleActivate());
		Test.Assert(!bed.Bar.IsItemShown("fps"));
		Test.Assert(heard.Count == 1);
		Test.Assert(heard[0] == "fps=hidden");

		Test.Assert(bed.Bar.SetItemShown("fps", true));
		Test.Assert(bed.Bar.IsItemShown("fps"));
		Test.Assert(heard.Count == 2);
		Test.Assert(bed.Bar.SetItemShown("fps", true)); // as it is: nothing heard
		Test.Assert(heard.Count == 2);
		Test.Assert(!bed.Bar.SetItemShown("none", false));
	}

	[Test]
	public static void MarkupsChildrenAreItsItemsEachInItsZone()
	{
		let made = Load(
			"<StatusBar>\n" +
			"    <StatusItem id=\"cursor\" zone=\"end\" title=\"Cursor\"><Label text=\"Ln 1, Col 1\"/></StatusItem>\n" +
			"    <StatusItem id=\"branch\" title=\"Branch\"><Label text=\"main\"/></StatusItem>\n" +
			"</StatusBar>");
		Test.Assert(made != null);
		defer made.ReleaseRef();
		let bar = made as StatusBar;
		Test.Assert(bar != null);
		Test.Assert(bar.FindItem("cursor") != null);
		Test.Assert(bar.FindItem("cursor").Zone == .End);
		Test.Assert(bar.FindItem("cursor").Title == "Cursor");
		let start = scope List<StatusItem>();
		bar.GetItems(.Start, start);
		Test.Assert(start.Count == 1);
	}

	// What no Raptor test covers: the zone and the order read back, a message cleared by an empty one.
	[Test]
	public static void AnItemsZoneNameAndOrderReadBackAndAnEmptyMessageHidesThePart()
	{
		let bed = scope StatusBed();
		let item = bed.Item("x", .Start, 3);
		Test.Assert(item.ZoneName == "start");
		item.ZoneName = " end ";
		Test.Assert(item.Zone == .End);
		Test.Assert(item.ZoneName == "end");
		Test.Assert(item.Order == 3);
		bed.Bar.ShowMessage("Hi");
		Test.Assert(bed.Bar.MessagePart.Displayed);
		bed.Bar.ShowMessage("");
		Test.Assert(!bed.Bar.MessagePart.Displayed);
		Test.Assert(bed.Bar.Message.Length == 0);
	}
}
