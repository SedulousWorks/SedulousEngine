using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// ListBox tests: add and clear items, click and keyboard selection, the selection callback, and
/// scroll-into-view for an off-screen selection.
class ListBoxTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A new list `w` by `h` with 24-high rows, the last child of `root`, held by the caller.
	private static ListBox MakeList(Node root, float w, float h)
	{
		let lb = new ListBox();
		lb.Size = .(w, h);
		lb.ItemHeight = 24.0f;
		root.AddChild(lb);
		return lb;
	}

	[Test]
	public static void AddCountGetClearItems()
	{
		let lb = new ListBox();
		defer lb.ReleaseRef();
		lb.Size = .(200.0f, 100.0f);
		lb.AddItem("Alpha");
		lb.AddItem("Beta");
		lb.AddItem("Gamma");

		Test.Assert(lb.ItemCount == 3);
		Test.Assert(lb.GetItem(1) == "Beta");
		Test.Assert(lb.SelectedIndex == -1);

		lb.Clear();
		Test.Assert(lb.ItemCount == 0);
		Test.Assert(lb.SelectedIndex == -1);
	}

	[Test]
	public static void SetSelectedIndexHighlightsAndFiresTheCallbackOnlyOnChange()
	{
		let lb = new ListBox();
		defer lb.ReleaseRef();
		lb.Size = .(200.0f, 100.0f);
		for (int i = 0; i < 5; ++i)
			lb.AddItem("item");

		int changes = 0;
		int last = -99;
		lb.SetOnSelectionChanged(new [&] (index) =>
			{
				++changes;
				last = index;
			});

		lb.SelectedIndex = 2;
		Test.Assert(lb.SelectedIndex == 2);
		Test.Assert(changes == 1);
		Test.Assert(last == 2);
		lb.SelectedIndex = 2; // no change
		Test.Assert(changes == 1);
		lb.SelectedIndex = 4;
		Test.Assert(changes == 2);
		Test.Assert(last == 4);

		lb.SelectedIndex = 99; // out of range -> ignored
		Test.Assert(lb.SelectedIndex == 4);
	}

	[Test]
	public static void ClickingARowSelectsIt()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let lb = MakeList(root, 200.0f, 100.0f);
		defer lb.ReleaseRef();
		for (int i = 0; i < 10; ++i)
			lb.AddItem("row");
		let d = root.EventDispatcher;

		// Row 2 spans y in [48, 72); click it.
		d.InjectMouseDown(.(10.0f, 60.0f), .Left);
		d.InjectMouseUp(.(10.0f, 60.0f), .Left);
		Test.Assert(lb.SelectedIndex == 2);
	}

	[Test]
	public static void KeyboardNavigationMovesTheSelection()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let lb = MakeList(root, 200.0f, 100.0f);
		defer lb.ReleaseRef();
		for (int i = 0; i < 6; ++i)
			lb.AddItem("row");
		let d = root.EventDispatcher;
		lb.RequestFocus();

		d.InjectKeyDown((uint32)KeyCode.Down); // -1 -> 0
		Test.Assert(lb.SelectedIndex == 0);
		d.InjectKeyDown((uint32)KeyCode.Down); // -> 1
		Test.Assert(lb.SelectedIndex == 1);
		d.InjectKeyDown((uint32)KeyCode.End); // -> last (5)
		Test.Assert(lb.SelectedIndex == 5);
		d.InjectKeyDown((uint32)KeyCode.Down); // clamps at last
		Test.Assert(lb.SelectedIndex == 5);
		d.InjectKeyDown((uint32)KeyCode.Home); // -> 0
		Test.Assert(lb.SelectedIndex == 0);
		d.InjectKeyDown((uint32)KeyCode.Up); // clamps at 0
		Test.Assert(lb.SelectedIndex == 0);
	}

	[Test]
	public static void SelectingAnOffScreenRowScrollsItIntoView()
	{
		let lb = new ListBox();
		defer lb.ReleaseRef();
		lb.Size = .(200.0f, 100.0f); // viewport 100 tall
		for (int i = 0; i < 10; ++i)
			lb.AddItem("row"); // content 240 tall, range 140

		Test.Assert(Near(lb.ScrollOffset.Y, 0.0f));
		lb.SelectedIndex = 9; // row 9 -> [216, 240]; scroll so bottom hits viewport bottom: 240-100 = 140
		Test.Assert(Near(lb.ScrollOffset.Y, 140.0f));

		lb.SelectedIndex = 0; // back to top
		Test.Assert(Near(lb.ScrollOffset.Y, 0.0f));
	}
}
