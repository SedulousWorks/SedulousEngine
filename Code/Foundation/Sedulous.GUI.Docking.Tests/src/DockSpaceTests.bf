using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Docking.Tests.DockingFixtures;

namespace Sedulous.GUI.Docking.Tests;

/// A DockSpace 800 by 600 in a root, showing its controller's main surface, five panels registered
/// (none docked), each made a Panel by its factory, counted.
class SpaceBed
{
	public SceneRoot Root;
	public DockController Controller = new .();
	public DockSpace Space = new .();
	/// Contents the factories made.
	public int Made = 0;

	public this()
	{
		Root = NewRoot(800.0f, 600.0f);
		Space.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(800.0f);
				s.Height = LayoutLength.Px(600.0f);
			});
		Root.AddChild(Space);
		String[5] ids = .("scene", "hierarchy", "inspector", "console", "log");
		String[5] titles = .("Scene", "Hierarchy", "Inspector", "Console", "Log");
		for (int i < 5)
			Register(ids[i], titles[i], .Hide);
		Space.Show(Controller, Controller.Layout.MainSurface);
	}

	public ~this()
	{
		// The root (and the space with it, leaving the controller's views) before the controller.
		Space.ReleaseRef();
		Root.ReleaseRef();
		delete Controller;
	}

	public void Register(StringView id, StringView title, DockClosePolicy policy)
	{
		let description = new DockPanelDescription();
		description.Id.Set(id);
		description.Title.Set(title);
		description.Close = policy;
		description.Factory = new () =>
			{
				++Made;
				return new Panel();
			};
		Test.Assert(Controller.Register(description));
	}

	public DockNodeId Central => Controller.Layout.CentralStack;
	public DockNodeId StackOf(StringView panel) => Controller.Layout.StackOf(panel);
	public void Lay() { Root.UpdateLayout(); }
}

/// The DockSpace and its controller (D3 of Specs/gui-lab-evolution-3.md): splits as Splitters and
/// stacks as TabViews, kept by node id as the layout changes; a panel's content made when its tab
/// is first shown and kept by the controller; closing by the panel's policy; a placeholder for a
/// panel not registered, filled when it is; a maximized stack alone; and what the user does in the
/// widgets (a separator dragged, a tab chosen, dragged or closed, by its close part or a middle
/// click) noted back; a panel wider than its stack moves no separator, the stack clipping it.
class DockSpaceTests
{
	[Test]
	public static void SplitsAreSplittersAndStacksTabViewsKeptByNodeIdAsTheLayoutChanges()
	{
		let bed = scope SpaceBed();
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("scene", bed.Central)).Ok);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("hierarchy", bed.Central, .Start, 0.25f)).Ok);
		bed.Lay();
		Test.Assert(bed.Space.ChildCount == 1);
		let splitter = bed.Space.GetChildAt(0) as Splitter;
		Test.Assert(splitter != null);
		Test.Assert(splitter.PaneCount == 2);
		let central = bed.Space.WidgetOf(bed.Central) as TabView;
		Test.Assert(central != null);
		Test.Assert(splitter.GetPane(1) == central);
		Test.Assert(central.HasClass("dock-central"));
		Test.Assert(central.Group == "dock");
		let weights = scope List<float>();
		splitter.GetWeights(weights);
		Test.Assert(Near(weights[0], 0.25f));
		Test.Assert(bed.Space.PageOf("hierarchy").Title == "Hierarchy");
		// A tab more: the same widgets, a page more.
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("inspector", bed.Central)).Ok);
		Test.Assert(bed.Space.GetChildAt(0) == splitter);
		Test.Assert(bed.Space.WidgetOf(bed.Central) == central);
		Test.Assert(central.PageCount == 2);
		Test.Assert(central.SelectedIndex == 1); // the one tabbed in last
	}

	[Test]
	public static void APanelsContentIsMadeWhenItsTabIsFirstShownAndKeptByTheController()
	{
		let bed = scope SpaceBed();
		// Both tabbed in at once: the console, tabbed in last, is the one shown.
		Test.Assert(bed.Controller.Edit(scope (l) =>
			{
				let first = l.InsertTab("scene", bed.Central);
				return first.Ok ? l.InsertTab("console", bed.Central) : first;
			}).Ok);
		bed.Lay();
		Test.Assert(bed.Controller.HasContent("console")); // selected: shown
		Test.Assert(!bed.Controller.HasContent("scene")); // not shown yet
		Test.Assert(bed.Made == 1);
		let central = bed.Space.WidgetOf(bed.Central) as TabView;
		central.Bar.SelectByUser(0); // the user chose the scene's tab
		bed.Lay();
		Test.Assert(bed.Controller.HasContent("scene"));
		Test.Assert(bed.Controller.Layout.FindNode(bed.Central).Active == 0); // noted
		// Moved to a stack of its own: the same content.
		let scene = bed.Controller.Content("scene");
		scene.AddRef(); // held, so its address is not reused if it went
		defer scene.ReleaseRef();
		Test.Assert(bed.Controller.Edit(scope (l) => l.MoveBeside("scene", bed.Central, .End)).Ok);
		bed.Lay();
		Test.Assert(bed.Controller.Content("scene") == scene);
		Test.Assert(scene.Parent == bed.Space.PageOf("scene"));
		Test.Assert(bed.Made == 2);
	}

	[Test]
	public static void ClosingByThePanelsPolicyHideKeepsItsContentRebuildMakesItAgainDestroyForgetsIt()
	{
		let bed = scope SpaceBed();
		bed.Register("preview", "Preview", .Rebuild);
		bed.Register("search", "Search", .Destroy);
		String[3] placed = .("scene", "preview", "search");
		for (let panel in placed)
		{
			Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside(panel, bed.Central, .End)).Ok);
			bed.Lay();
		}
		let scene = bed.Controller.Content("scene");
		scene.AddRef(); // held, so its address is not reused if it went
		defer scene.ReleaseRef();
		let preview = bed.Controller.Content("preview");
		preview.AddRef();
		defer preview.ReleaseRef();
		// Through the tab's close, as the user would.
		let sceneStack = bed.Space.WidgetOf(bed.StackOf("scene")) as TabView;
		sceneStack.Bar.RequestClose(0);
		Test.Assert(bed.StackOf("scene") == cNoDock);
		Test.Assert(bed.Controller.HasContent("scene")); // hidden, kept
		Test.Assert(bed.Controller.Show("scene").Ok);
		bed.Lay();
		Test.Assert(bed.Controller.Content("scene") == scene);

		Test.Assert(bed.Controller.Close("preview").Ok);
		Test.Assert(!bed.Controller.HasContent("preview")); // let go
		Test.Assert(bed.Controller.Layout.FindHidden("preview") != null); // its place kept
		Test.Assert(bed.Controller.Show("preview").Ok);
		bed.Lay();
		Test.Assert(bed.Controller.Content("preview") != preview); // made again

		Test.Assert(bed.Controller.Close("search").Ok);
		Test.Assert(!bed.Controller.HasContent("search"));
		Test.Assert(bed.Controller.Layout.FindHidden("search") == null); // forgotten
		// Shown again, it goes to its default place (the main surface's end).
		Test.Assert(bed.Controller.Show("search").Ok);
		Test.Assert(bed.StackOf("search") != cNoDock);

		let @fixed = new DockPanelDescription();
		@fixed.Id.Set("toolbar");
		@fixed.Closable = false;
		Test.Assert(bed.Controller.Register(@fixed));
		Test.Assert(bed.Controller.Show("toolbar").Ok);
		Test.Assert(!bed.Controller.Close("toolbar").Ok);
	}

	[Test]
	public static void APanelNotRegisteredShowsAPlaceholderFilledWhenItRegisters()
	{
		let bed = scope SpaceBed();
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("profiler", bed.Central)).Ok);
		bed.Lay();
		var page = bed.Space.PageOf("profiler");
		Test.Assert(page != null);
		Test.Assert(page.ChildCount == 1);
		Test.Assert((page.GetChildAt(0) as Label) != null);
		Test.Assert((page.GetChildAt(0) as Label).HasClass("dock-placeholder"));
		bed.Register("profiler", "Profiler", .Hide);
		bed.Lay();
		page = bed.Space.PageOf("profiler");
		Test.Assert(page != null);
		Test.Assert(page.Title == "Profiler");
		Test.Assert(page.ChildCount == 1);
		Test.Assert((page.GetChildAt(0) as Label) == null);
		Test.Assert(bed.Controller.HasContent("profiler"));
	}

	[Test]
	public static void ASeparatorDraggedAndATabDraggedAreNotedAMaximizedStackIsShownAloneTheRestKept()
	{
		let bed = scope SpaceBed();
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("hierarchy", bed.Central, .Start, 0.5f)).Ok);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("log", bed.Central)).Ok);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("console", bed.Central)).Ok);
		bed.Lay();
		let splitter = bed.Space.GetChildAt(0) as Splitter;
		Test.Assert(splitter != null);
		splitter.MoveHandleTo(0, 200.0f);
		bed.Lay();
		let layout = bed.Controller.Layout;
		let root = layout.FindNode(layout.FindSurface(layout.MainSurface).Root);
		Test.Assert(Near(root.Weights[0], 200.0f / 794.0f, 0.01)); // 800 less the handle
		Test.Assert(bed.Space.GetChildAt(0) == splitter); // kept, not made again

		let central = bed.Space.WidgetOf(bed.Central) as TabView;
		central.Bar.MoveTab(1, 0); // console before log
		Test.Assert(bed.Controller.Layout.FindNode(bed.Central).Panels[0] == "console");
		Test.Assert(bed.Space.WidgetOf(bed.Central) == central);

		splitter.AddRef(); // held, so its address is not reused if it went
		defer splitter.ReleaseRef();
		Test.Assert(bed.Controller.Edit(scope (l) => l.Maximize(bed.Central)).Ok);
		Test.Assert(bed.Space.GetChildAt(0) == central); // alone
		Test.Assert(bed.Controller.Edit(scope (l) => l.Restore(l.MainSurface)).Ok);
		Test.Assert(bed.Space.GetChildAt(0) == splitter); // kept while out of sight
		Test.Assert(splitter.GetPane(1) == central);
		let weights = scope List<float>();
		splitter.GetWeights(weights);
		Test.Assert(Near(weights[0], 200.0f / 794.0f, 0.01));
	}

	[Test]
	public static void ATabShownWithContentWiderThanItsStackMovesNoSeparatorTheStackClipsIt()
	{
		let bed = scope SpaceBed();
		let description = new DockPanelDescription();
		description.Id.Set("wide");
		description.Factory = new () =>
			{
				let wide = new Panel();
				wide.EditLayoutStyle(scope (s) => { s.MinWidth = LayoutLength.Px(700.0f); });
				return wide;
			};
		Test.Assert(bed.Controller.Register(description));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("hierarchy", bed.Central, .Start, 0.25f)).Ok);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("wide", l.StackOf("hierarchy"))).Ok);
		let stack = bed.Space.WidgetOf(bed.StackOf("hierarchy")) as TabView;
		Test.Assert(stack != null);
		stack.SelectedIndex = 0;
		bed.Lay();
		let splitter = bed.Space.GetChildAt(0) as Splitter;
		Test.Assert(splitter != null);
		let before = splitter.PaneSizes[0];
		stack.SelectedIndex = 1; // the wide one
		bed.Lay();
		Test.Assert(Near(splitter.PaneSizes[0], before));
		Test.Assert(Near(stack.Size.X, before, 0.01)); // snapped to the pixel
		Test.Assert(stack.LayoutStyle.OverflowX == .Hidden);
		Test.Assert(stack.LayoutStyle.OverflowY == .Hidden);
	}

	[Test]
	public static void AClosablePanelsTabShowsItsClosePartChosenOrHoveredItOrAMiddleClickClosesThePanel()
	{
		let bed = scope SpaceBed();
		Test.Assert(bed.Controller.Register(PanelNamed("fixed", default, false)));
		String[3] tabbed = .("fixed", "hierarchy", "inspector");
		for (let id in tabbed)
			Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab(id, bed.Central)).Ok);
		bed.Lay();
		let bar = (bed.Space.WidgetOf(bed.Central) as TabView).Bar;
		Test.Assert(bar.TabCount == 3);
		bar.SelectByUser(2); // the inspector
		bed.Lay();
		Test.Assert(bar.CloseDisplay == .Hover);
		Test.Assert(!bar.GetTab(0).ClosePart.Displayed); // it cannot be closed
		Test.Assert(bar.GetTab(1).ClosePart.Displayed); // its room kept, shown when hovered
		Test.Assert(!bar.GetTab(1).ClosePart.Visible);
		Test.Assert(bar.GetTab(2).ClosePart.Visible); // the chosen tab's

		let d = bed.Root.EventDispatcher;
		let close = bar.GetTab(2).ClosePart.ScreenBounds;
		let at = Float2(close.X + close.Width * 0.5f, close.Y + close.Height * 0.5f);
		d.InjectMouseMove(at);
		d.InjectMouseDown(at, .Left);
		d.InjectMouseUp(at, .Left);
		Test.Assert(bed.StackOf("inspector") == cNoDock);
		bed.Lay();

		Test.Assert(bar.TabCount == 2);
		void MiddleClick(int32 index)
		{
			let tab = bar.GetTab(index).ScreenBounds;
			let on = Float2(tab.X + tab.Width * 0.5f, tab.Y + tab.Height * 0.5f);
			d.InjectMouseMove(on);
			d.InjectMouseDown(on, .Middle);
			d.InjectMouseUp(on, .Middle);
			bed.Lay();
		}
		MiddleClick(0); // the fixed panel: nothing
		Test.Assert(bed.StackOf("fixed") != cNoDock);
		MiddleClick(1);
		Test.Assert(bed.StackOf("hierarchy") == cNoDock);
		Test.Assert(bed.StackOf("fixed") != cNoDock);
	}

	/// A panel whose description gives no title is titled by its id, on its tab and in the stack's
	/// name (the Move to menu's).
	[Test]
	public static void APanelWithNoTitleIsTitledByItsId()
	{
		let bed = scope SpaceBed();
		Test.Assert(bed.Controller.Register(PanelNamed("untitled")));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("untitled", bed.Central, .End)).Ok);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("scene", bed.Central)).Ok);
		bed.Lay();
		let page = bed.Space.PageOf("untitled");
		Test.Assert(page != null);
		Test.Assert(page.Title == "untitled");
		let view = bed.Space.WidgetOf(bed.StackOf("untitled")) as TabView;
		Test.Assert(view.Bar.GetTab(0).Text == "untitled");
		// The scene's tab names it in the menu of where the scene may go.
		let scene = (bed.Space.WidgetOf(bed.Central) as TabView).Bar.GetTab(0);
		let menu = bed.Space.OpenMoveTo("scene", scene, .(0.0f, 0.0f));
		Test.Assert(menu != null);
		Menu into = null;
		for (int i < menu.ChildCount)
		{
			let sub = menu.GetChildAt(i) as MenuSubItem;
			if ((sub != null) && (sub.Text == "Into"))
				into = sub.SubMenu;
		}
		Test.Assert(into != null);
		bool named = false;
		for (int i < into.ChildCount)
		{
			let item = into.GetChildAt(i) as MenuItem;
			named = named || ((item != null) && (item.Text == "untitled"));
		}
		Test.Assert(named);
		menu.Close();
	}
}
