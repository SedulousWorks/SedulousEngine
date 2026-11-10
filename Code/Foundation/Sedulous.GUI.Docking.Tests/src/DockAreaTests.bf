using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Docking.Tests.DockingFixtures;

namespace Sedulous.GUI.Docking.Tests;

/// A DockArea 800 by 600 in a root, four panels registered (the console may not close), the scene
/// tabbed in the central stack.
class AreaBed
{
	public SceneRoot Root;
	public DockController Controller = new .();
	public DockArea Area = new .();

	public this()
	{
		Root = NewRoot(800.0f, 600.0f);
		Area.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(800.0f);
				s.Height = LayoutLength.Px(600.0f);
			});
		Root.AddChild(Area);
		String[4] ids = .("scene", "profiler", "memory", "console");
		String[4] titles = .("Scene", "Profiler", "Memory", "Console");
		for (int i < 4)
			Test.Assert(Controller.Register(PanelNamed(ids[i], titles[i], i != 3))); // the console may not close
		Area.Show(Controller);
		Test.Assert(Controller.Edit(scope (l) => l.InsertTab("scene", l.CentralStack)).Ok);
		Lay();
	}

	public ~this()
	{
		// The root (and the area with it, leaving the controller's views) before the controller.
		Area.ReleaseRef();
		Root.ReleaseRef();
		delete Controller;
	}

	public void Lay()
	{
		Root.UpdateLayout();
		// The tabs a size of their own: with no font their text measures nothing.
		String[4] ids = .("scene", "profiler", "memory", "console");
		for (let id in ids)
		{
			let tab = TabOf(id);
			if (tab == null)
				continue;
			tab.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(80.0f);
					s.Height = LayoutLength.Px(24.0f);
				});
		}
		Root.UpdateLayout();
	}

	// The dock space showing a panel: the main one or a float's.
	public DockSpace SpaceOf(StringView panel)
	{
		if (Area.MainSpace.PageOf(panel) != null)
			return Area.MainSpace;
		for (int i < Area.FloatCount)
		{
			if (Area.GetFloat(i).Space.PageOf(panel) != null)
				return Area.GetFloat(i).Space;
		}
		return null;
	}

	public Tab TabOf(StringView panel)
	{
		let space = SpaceOf(panel);
		if (space == null)
			return null;
		let view = space.WidgetOf(Controller.Layout.StackOf(panel)) as TabView;
		let page = space.PageOf(panel);
		if (view == null)
			return null;
		for (int32 i = 0; i < view.PageCount; ++i)
		{
			if (view.GetPage(i) == page)
				return view.Bar.GetTab(i);
		}
		return null;
	}

	public EventDispatcher D => Root.EventDispatcher;

	public DockSurfaceId Float(StringView panel, Rectangle bounds)
	{
		DockSurfaceId made = cNoDock;
		Test.Assert(Controller.Edit(scope [&] (l) => l.Float(panel, bounds, &made)).Ok);
		Lay();
		return made;
	}
}

/// Windows of their own for the floats, each a root of the bed's GUI at a place on a screen, the
/// area's root at 1000,500 on it; the GUI's root places as a host that places windows tells them.
class FakeWindows : IDockWindows, IRootPlaces
{
	public class FakeWindow
	{
		public DockSurfaceId Surface = cNoDock;
		public SceneRoot Root = null ~ _?.ReleaseRef();
		public Rectangle Bounds = .();
		public String Title = new .() ~ delete _;
		public int Raises = 0;
	}

	private AreaBed mBed;
	public List<FakeWindow> Shown = new .() ~ DeleteContainerAndItems!(_);
	public Float2 Origin = .(1000.0f, 500.0f);
	public int Opens = 0;
	public int Closes = 0;
	public int Places = 0;
	public bool Refuse = false;

	public this(AreaBed bed)
	{
		mBed = bed;
	}

	public FakeWindow Find(DockSurfaceId surface)
	{
		for (let each in Shown)
		{
			if (each.Surface == surface)
				return each;
		}
		return null;
	}

	public bool Open(DockSurfaceId surface, Node content, Rectangle bounds, StringView title)
	{
		if (Refuse)
			return false;
		let made = new FakeWindow();
		made.Surface = surface;
		made.Root = new SceneRoot(mBed.Root.Context);
		made.Root.Size = .(bounds.Width, bounds.Height);
		made.Root.AddChild(content);
		made.Bounds = bounds;
		made.Title.Set(title);
		made.Root.UpdateLayout();
		Shown.Add(made);
		++Opens;
		return true;
	}

	public void Close(DockSurfaceId surface)
	{
		for (int i < Shown.Count)
		{
			if (Shown[i].Surface != surface)
				continue;
			let gone = Shown[i];
			gone.Root.RemoveAllChildren();
			Shown.RemoveAt(i);
			delete gone;
			++Closes;
			return;
		}
	}

	public void Place(DockSurfaceId surface, Rectangle bounds)
	{
		let each = Find(surface);
		if (each != null)
			each.Bounds = bounds;
		++Places;
	}

	public void SetTitle(DockSurfaceId surface, StringView title)
	{
		let each = Find(surface);
		if (each != null)
			each.Title.Set(title);
	}

	public void Raise(DockSurfaceId surface)
	{
		let each = Find(surface);
		if (each != null)
			++each.Raises;
	}

	public bool ToScreen(Node node, Float2 local, out Float2 screen)
	{
		screen = .();
		let world = node.ConvertToWorldSpace(local);
		let top = node.RootNode;
		if (top == mBed.Root)
		{
			screen = .(Origin.X + world.X, Origin.Y + world.Y);
			return true;
		}
		for (let each in Shown)
		{
			if (top == each.Root)
			{
				screen = .(each.Bounds.X + world.X, each.Bounds.Y + world.Y);
				return true;
			}
		}
		return false;
	}

	// IRootPlaces: the area's root and each window's.
	public EventDispatcher DispatcherAt(Float2 screen, out Float2 local)
	{
		local = .();
		for (let each in Shown)
		{
			if ((screen.X >= each.Bounds.X) && (screen.Y >= each.Bounds.Y) && (screen.X < each.Bounds.X + each.Bounds.Width) &&
				(screen.Y < each.Bounds.Y + each.Bounds.Height))
			{
				local = .(screen.X - each.Bounds.X, screen.Y - each.Bounds.Y);
				return each.Root.EventDispatcher;
			}
		}
		if ((screen.X >= Origin.X) && (screen.Y >= Origin.Y) && (screen.X < Origin.X + 800.0f) && (screen.Y < Origin.Y + 600.0f))
		{
			local = .(screen.X - Origin.X, screen.Y - Origin.Y);
			return mBed.Root.EventDispatcher;
		}
		return null;
	}

	public bool ToScreen(EventDispatcher d, Float2 local, out Float2 screen)
	{
		screen = .();
		if (d == mBed.Root.EventDispatcher)
		{
			screen = .(Origin.X + local.X, Origin.Y + local.Y);
			return true;
		}
		for (let each in Shown)
		{
			if (d == each.Root.EventDispatcher)
			{
				screen = .(each.Bounds.X + local.X, each.Bounds.Y + local.Y);
				return true;
			}
		}
		return false;
	}
}

/// Floating surfaces in one window: a DockArea shows the main
/// surface and each floating one as a window over it, holding a dock space of its own; the windows
/// follow the layout (made, placed, titled, ended) and the layout follows what the user does to them
/// (moved or resized, closed); a float is docked into like the main surface; a tab dragged with
/// Shift, Move to's Float and dock.float float a panel; a float dragged by its title docks whole
/// over a target, is only moved with Shift, and goes back on Escape; the dock keys reach across the
/// surfaces (past a float's edge, the surface cycle) and so does the Move to menu; a stack's grip
/// dragged with Shift floats the whole stack. Floats as windows of their own: each floating
/// surface a dock space in its window, titled and placed on the screen, its moves and close heard
/// back; a tab let go outside every window floats there; a window that cannot open takes the area
/// back to floats in it.
class DockAreaTests
{
	// A float's title bar pressed and dragged to `to` (in steps), the window following.
	private static void DragTitle(AreaBed bed, DockFloat window, Float2 to, uint32 modifiers = 0)
	{
		let at = window.ScreenBounds;
		let press = Float2(at.X + 60.0f, at.Y + 10.0f);
		bed.D.InjectMouseDown(press, .Left);
		bed.D.InjectMouseMove(.(press.X + 10.0f, press.Y), modifiers);
		bed.D.InjectMouseMove(to, modifiers);
	}

	// The dock space whose stack the focus is in; null when none.
	private static DockSpace FocusedSpace(AreaBed bed)
	{
		if (bed.Area.MainSpace.FocusedStack != cNoDock)
			return bed.Area.MainSpace;
		for (int i < bed.Area.FloatCount)
		{
			if (bed.Area.GetFloat(i).Space.FocusedStack != cNoDock)
				return bed.Area.GetFloat(i).Space;
		}
		return null;
	}

	private static DockNodeId FocusedStackOf(AreaBed bed)
	{
		let space = FocusedSpace(bed);
		return (space != null) ? space.FocusedStack : cNoDock;
	}

	[Test]
	public static void AFloatingSurfaceIsAWindowOverTheMainOneAtItsBoundsItsPanelsInADockSpaceOfItsOwn()
	{
		let bed = scope AreaBed();
		Test.Assert(bed.Area.FloatCount == 0);
		let floating = bed.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f));
		Test.Assert(bed.Area.FloatCount == 1);
		let window = bed.Area.FloatOf(floating);
		Test.Assert(window != null);
		Test.Assert(window.HasClass("dock-float"));
		Test.Assert(Near(window.Position.X, 100.0f));
		Test.Assert(Near(window.Size.X, 300.0f));
		Test.Assert(window.Title == "Profiler");
		Test.Assert(window.Space != null);
		Test.Assert(window.Space.Surface == floating);
		Test.Assert(window.Space.PageOf("profiler") != null);
		Test.Assert(bed.Area.MainSpace.PageOf("profiler") == null);
		Test.Assert(Near(bed.Area.MainSpace.Size.X, 800.0f)); // the main surface fills the area

		// Docked into like the main one: a tab, then the title counts it.
		let stack = bed.Controller.Layout.StackOf("profiler");
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", stack)).Ok);
		bed.Lay();
		Test.Assert(window.Space.PageOf("memory") != null);
		Test.Assert(window.Title == "Memory +1"); // the shown one first

		// Docked away whole: the window ends, its panels' contents kept and shown in the main surface.
		let content = bed.Controller.Content("profiler");
		content.AddRef(); // held, so its address is not reused if it went
		defer content.ReleaseRef();
		Test.Assert(bed.Controller.Edit(scope (l) => l.DockSurfaceInto(floating, l.CentralStack)).Ok);
		bed.Lay();
		Test.Assert(bed.Area.FloatCount == 0);
		Test.Assert(bed.Area.MainSpace.PageOf("profiler") != null);
		Test.Assert(bed.Controller.Content("profiler") == content);
	}

	[Test]
	public static void AFloatMovedShiftOnItsTitleOrResizedByTheUserWritesItsBoundsBackKeptWhereItsTitleCanBeReached()
	{
		let bed = scope AreaBed();
		let floating = bed.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f));
		let window = bed.Area.FloatOf(floating);
		Test.Assert(window != null);
		let at = Float2(window.ScreenBounds.X + 150.0f, window.ScreenBounds.Y + 10.0f);
		bed.D.InjectMouseDown(at, .Left);
		bed.D.InjectMouseMove(.(at.X + 20.0f, at.Y + 15.0f), KeyModShift);
		bed.D.InjectMouseMove(.(at.X + 40.0f, at.Y + 30.0f), KeyModShift);
		bed.D.InjectMouseUp(.(at.X + 40.0f, at.Y + 30.0f), .Left, KeyModShift);
		bed.Lay();
		let moved = bed.Controller.Layout.FindSurface(floating).Bounds;
		Test.Assert(Near(moved.X, 140.0f));
		Test.Assert(Near(moved.Y, 110.0f));
		Test.Assert(Near(moved.Width, 300.0f));

		// Far off the area: its title bar kept in reach, and that is what is noted.
		// Its grip: the size noted too.
		let @box = window.ScreenBounds;
		let grip = Float2(@box.X + @box.Width - 7.0f, @box.Y + @box.Height - 7.0f);
		bed.D.InjectMouseDown(grip, .Left);
		bed.D.InjectMouseMove(.(grip.X + 50.0f, grip.Y + 20.0f));
		bed.D.InjectMouseUp(.(grip.X + 50.0f, grip.Y + 20.0f), .Left);
		bed.Lay();
		Test.Assert(Near(bed.Controller.Layout.FindSurface(floating).Bounds.Width, 350.0f));
		Test.Assert(Near(bed.Controller.Layout.FindSurface(floating).Bounds.Height, 220.0f));

		let from = Float2(window.ScreenBounds.X + 150.0f, window.ScreenBounds.Y + 10.0f);
		bed.D.InjectMouseDown(from, .Left);
		bed.D.InjectMouseMove(.(from.X + 20.0f, from.Y), KeyModShift);
		bed.D.InjectMouseMove(.(from.X + 2000.0f, from.Y - 500.0f), KeyModShift);
		bed.D.InjectMouseUp(.(from.X + 2000.0f, from.Y - 500.0f), .Left, KeyModShift);
		bed.Lay();
		let kept = bed.Controller.Layout.FindSurface(floating).Bounds;
		Test.Assert(Near(kept.X, 800.0f - DockArea.cKeepInView));
		Test.Assert(Near(kept.Y, 0.0f));
		Test.Assert(Near(window.Position.X, kept.X));
	}

	[Test]
	public static void ClosingAFloatClosesItsPanelsAsTheirPoliciesSayOneThatMayNotCloseKeepsIt()
	{
		let bed = scope AreaBed();
		let floating = bed.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", l.StackOf("profiler"))).Ok);
		bed.Lay();
		let window = bed.Area.FloatOf(floating);
		Test.Assert(window != null);
		window.RequestClose(); // what its close button does
		bed.Lay();
		Test.Assert(bed.Area.FloatCount == 0);
		Test.Assert(bed.Controller.Layout.FindHidden("profiler") != null); // hidden, its place kept
		Test.Assert(bed.Controller.Layout.FindHidden("memory") != null);

		let other = bed.Float("console", .(50.0f, 50.0f, 300.0f, 200.0f));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", l.StackOf("console"))).Ok);
		bed.Lay();
		bed.Area.FloatOf(other).RequestClose();
		bed.Lay();
		Test.Assert(bed.Area.FloatOf(other) != null); // the console stays, and its window
		Test.Assert(bed.Controller.Layout.StackOf("console") != cNoDock);
		Test.Assert(bed.Controller.Layout.StackOf("memory") == cNoDock);
	}

	[Test]
	public static void FloatsWithNoBoundsOfTheirOwnCascadeAndARestoredLayoutsFloatsComeBackAsWindows()
	{
		let bed = scope AreaBed();
		bed.Float("profiler", .(0.0f, 0.0f, 0.0f, 0.0f));
		bed.Float("memory", .(0.0f, 0.0f, 0.0f, 0.0f));
		Test.Assert(bed.Area.FloatCount == 2);
		let first = bed.Area.GetFloat(0).Position;
		let second = bed.Area.GetFloat(1).Position;
		Test.Assert(second.X > first.X);
		Test.Assert(Near(bed.Area.GetFloat(0).Size.X, DockArea.cFloatSize.X));
		Test.Assert(Near(bed.Controller.Layout.FindSurface(bed.Area.GetFloat(0).Surface).Bounds.Width, DockArea.cFloatSize.X));

		// The same layout adopted again (a restore): the windows stay one per float.
		let saved = scope DockLayout();
		saved.Set(bed.Controller.Layout);
		Test.Assert(bed.Controller.Adopt(saved).Ok);
		bed.Lay();
		Test.Assert(bed.Area.FloatCount == 2);
	}

	[Test]
	public static void ATabDraggedWithShiftHeldFloatsAtThePointerTheDockTargetsPassItOnThePreviewIsTheWindow()
	{
		let bed = scope AreaBed();
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("profiler", l.CentralStack)).Ok);
		bed.Lay();
		let tab = bed.TabOf("profiler");
		Test.Assert(tab != null);
		let from = tab.ScreenBounds;
		let press = Float2(from.X + 10.0f, from.Y + 10.0f);
		bed.D.InjectMouseDown(press, .Left);
		let over = Float2(400.0f, 300.0f); // the central stack's middle
		bed.D.InjectMouseMove(.(press.X + 10.0f, press.Y));
		bed.D.InjectMouseMove(over);
		Test.Assert(bed.D.IsDragging);
		Test.Assert(bed.D.DropTarget != bed.Area); // docking: into the stack
		Rectangle preview = .();
		Test.Assert(!bed.Area.GetFloatPreview(out preview));

		bed.D.InjectMouseMove(over, KeyModShift); // Shift: a float
		Test.Assert(bed.D.DropTarget == bed.Area);
		Test.Assert(bed.Area.GetFloatPreview(out preview));
		Test.Assert(preview.X < over.X);
		Test.Assert(preview.X + preview.Width > over.X);
		Test.Assert(Near(preview.Y, over.Y - 14.0f)); // its title bar under the pointer
		Rect docked = .();
		Test.Assert(!bed.Area.MainSpace.GetPreviewBounds(out docked)); // the dock's preview gone

		bed.D.InjectMouseUp(over, .Left, KeyModShift); // let go with Shift still held
		bed.Lay();
		Test.Assert(bed.Area.FloatCount == 1);
		let window = bed.Area.GetFloat(0);
		Test.Assert(window.Space.PageOf("profiler") != null);
		Test.Assert(Near(window.Position.X, preview.X));
		Test.Assert(Near(window.Position.Y, preview.Y));
		Test.Assert(!bed.Area.GetFloatPreview(out preview));
	}

	[Test]
	public static void AtADisplayScaleMoveToOpensBelowItsTabNotAtThatPointScaledAgain()
	{
		let bed = scope AreaBed();
		bed.Root.DisplayScale = 1.25f; // world space is device pixels, the root's units times 1.25
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("profiler", l.CentralStack, .End, 0.4f)).Ok);
		bed.Lay();
		let tab = bed.TabOf("profiler");
		Test.Assert(tab != null);
		tab.RequestFocus();
		let menu = bed.Area.MainSpace.OpenMoveToFocused();
		Test.Assert(menu != null);
		bed.Lay();
		let below = tab.ConvertToWorldSpace(.(0.0f, tab.Size.Y));
		let bounds = menu.ScreenBounds;
		Test.Assert(Near(bounds.X, below.X, 0.01));
		Test.Assert(Near(bounds.Y, below.Y, 0.01));
	}

	[Test]
	public static void MoveTosFloatAndDockFloatFloatAPanelOverItsStack()
	{
		let bed = scope AreaBed();
		DefineDockingCommands(bed.Root.Context);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("profiler", l.CentralStack, .End, 0.4f)).Ok);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", l.StackOf("profiler"))).Ok);
		bed.Lay();
		let main = bed.Area.MainSpace;
		let tab = bed.TabOf("memory");
		Test.Assert(tab != null);
		let menu = main.OpenMoveTo("memory", tab, .(0.0f, 0.0f));
		Test.Assert(menu != null);
		MenuItem floatItem = null;
		for (int i < menu.ChildCount)
		{
			let item = menu.GetChildAt(i) as MenuItem;
			if ((item != null) && (item.Text == "Float"))
				floatItem = item;
		}
		Test.Assert(floatItem != null);
		Test.Assert(floatItem.Enabled);
		let stack = main.WidgetOf(bed.Controller.Layout.StackOf("memory")).ScreenBounds;
		floatItem.HandleActivate();
		bed.Lay();
		Test.Assert(bed.Area.FloatCount == 1);
		let window = bed.Area.GetFloat(0);
		Test.Assert(window.Space.PageOf("memory") != null);
		Test.Assert(Near(window.Position.X, stack.X + 24.0f, 0.01)); // over its stack, a little in
		Test.Assert(Near(window.Position.Y, stack.Y + 24.0f, 0.01));

		// From the keys: the focused stack's panel.
		bed.TabOf("profiler").RequestFocus();
		Test.Assert(bed.Root.RunCommand("dock.float"));
		bed.Lay();
		Test.Assert(bed.Area.FloatCount == 2);
		Test.Assert(bed.SpaceOf("profiler") != main);
	}

	[Test]
	public static void AFloatDraggedByItsTitleFollowsThePointerAndDocksWholeWhereItIsLetGoOverATarget()
	{
		let bed = scope AreaBed();
		let floating = bed.Float("profiler", .(420.0f, 300.0f, 300.0f, 200.0f));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("memory", l.StackOf("profiler"), .End)).Ok);
		bed.Lay();
		let window = bed.Area.FloatOf(floating);
		Test.Assert(window != null);
		let middle = Float2(300.0f, 250.0f); // the central stack's middle
		DragTitle(bed, window, middle);
		Test.Assert(bed.D.IsDragging);
		Test.Assert(bed.D.DragPreview == null); // the window is what follows
		Test.Assert(window.IsBeingDragged);
		Test.Assert(window.HasClass("dock-dragging"));
		Test.Assert(Near(window.Position.X, middle.X - 60.0f)); // held where it was taken
		Test.Assert(Near(window.Position.Y, middle.Y - 10.0f));
		Rect preview = .();
		Test.Assert(bed.Area.MainSpace.GetPreviewBounds(out preview)); // the target under it answered
		Test.Assert(Near(preview.Width, 800.0f, 0.02)); // into the central stack: all of it
		bed.D.InjectMouseUp(middle, .Left);
		bed.Lay();
		Test.Assert(bed.Area.FloatCount == 0);
		let central = bed.Controller.Layout.FindNode(bed.Controller.Layout.CentralStack);
		Test.Assert(central.Panels.Count == 3); // scene, then the float's two
		Test.Assert(bed.Area.MainSpace.PageOf("memory") != null);
	}

	[Test]
	public static void AFloatLetGoInAStacksEdgeBandDocksBesideItItsOwnSplitKept()
	{
		let bed = scope AreaBed();
		let floating = bed.Float("profiler", .(420.0f, 300.0f, 300.0f, 200.0f));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("memory", l.StackOf("profiler"), .Bottom)).Ok);
		bed.Lay();
		let right = Float2(770.0f, 250.0f); // in the central stack's right band (64), not the surface's (20)
		DragTitle(bed, bed.Area.FloatOf(floating), right);
		Rect preview = .();
		Test.Assert(bed.Area.MainSpace.GetPreviewBounds(out preview));
		Test.Assert(Near(preview.X, 400.0f, 0.03)); // its half
		bed.D.InjectMouseUp(right, .Left);
		bed.Lay();
		let layout = bed.Controller.Layout;
		let root = layout.FindNode(layout.FindSurface(layout.MainSurface).Root);
		Test.Assert(root.Axis == .Horizontal);
		Test.Assert(root.Children.Count == 2);
		let moved = layout.FindNode(root.Children[1]);
		Test.Assert(moved.Axis == .Vertical); // the float's split, kept
		Test.Assert(layout.SurfaceOf(layout.StackOf("memory")) == layout.MainSurface);
	}

	[Test]
	public static void AFloatDraggedWithShiftIsOnlyMovedEscapePutsItBack()
	{
		let bed = scope AreaBed();
		let floating = bed.Float("profiler", .(100.0f, 100.0f, 300.0f, 200.0f));
		let window = bed.Area.FloatOf(floating);
		let to = Float2(400.0f, 300.0f);
		DragTitle(bed, window, to, KeyModShift);
		Test.Assert(bed.D.DropTarget == bed.Area);
		Rect preview = .();
		Test.Assert(!bed.Area.MainSpace.GetPreviewBounds(out preview));
		bed.D.InjectMouseUp(to, .Left, KeyModShift);
		bed.Lay();
		Test.Assert(bed.Area.FloatOf(floating) == window);
		let bounds = bed.Controller.Layout.FindSurface(floating).Bounds;
		Test.Assert(Near(bounds.X, to.X - 60.0f));
		Test.Assert(Near(bounds.Y, to.Y - 10.0f));
		Test.Assert(!window.IsBeingDragged);

		DragTitle(bed, window, .(600.0f, 500.0f));
		Test.Assert(!Near(window.Position.X, bounds.X));
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		bed.D.InjectMouseUp(.(600.0f, 500.0f), .Left);
		bed.Lay();
		Test.Assert(Near(window.Position.X, bounds.X));
		Test.Assert(Near(window.Position.Y, bounds.Y));
		Test.Assert(bed.Controller.Layout.FindSurface(floating) != null); // nothing docked
	}

	[Test]
	public static void AFloatLaidOutBeforeTheAreaHasItsSizeStandsAtItsBoundsOnceItHas()
	{
		let bed = scope AreaBed();
		bed.Area.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(0.0f);
				s.Height = LayoutLength.Px(0.0f);
			});
		let floating = bed.Float("profiler", .(350.0f, 70.0f, 220.0f, 160.0f)); // kept in an area of none
		bed.Area.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(800.0f);
				s.Height = LayoutLength.Px(600.0f);
			});
		bed.Lay();
		let window = bed.Area.FloatOf(floating);
		Test.Assert(window != null);
		Test.Assert(Near(window.Position.X, 350.0f));
		Test.Assert(Near(window.Position.Y, 70.0f));
	}

	[Test]
	public static void AnArrowPastAFloatsEdgeFocusesWhatLiesBeyondItTheTopmostOtherFloatElseTheMainSurface()
	{
		let bed = scope AreaBed();
		DefineDockingCommands(bed.Root.Context);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("console", l.CentralStack, .End, 0.3f)).Ok);
		bed.Lay();
		bed.Float("profiler", .(100.0f, 80.0f, 200.0f, 160.0f));
		bed.Float("memory", .(280.0f, 100.0f, 300.0f, 120.0f)); // over the first's right edge
		let layout = bed.Controller.Layout;

		// Left of the first float: the main surface's stack there (the scene's).
		bed.TabOf("profiler").RequestFocus();
		Test.Assert(bed.Root.RunCommand("dock.focus-left"));
		Test.Assert(FocusedStackOf(bed) == layout.StackOf("scene"));

		// Right of the first float: the second, over the main surface there.
		bed.TabOf("profiler").RequestFocus();
		Test.Assert(bed.Root.RunCommand("dock.focus-right"));
		Test.Assert(FocusedStackOf(bed) == layout.StackOf("memory"));
		Test.Assert((bed.Area.GetChildAt(bed.Area.ChildCount - 1) as DockFloat) == null); // the preview stays on top

		// Right of the second: the main surface's stack there (the console's, along the right).
		Test.Assert(bed.Root.RunCommand("dock.focus-right"));
		Test.Assert(FocusedStackOf(bed) == layout.StackOf("console"));

		// Past the main surface's own edge is outside the area: nothing.
		bed.Root.RunCommand("dock.focus-right");
		Test.Assert(FocusedStackOf(bed) == layout.StackOf("console"));
	}

	[Test]
	public static void APanelMovedPastAFloatsEdgeGoesIntoTheStackBeyondAFloatItEmptiesEndsTheFocusWithThePanel()
	{
		let bed = scope AreaBed();
		DefineDockingCommands(bed.Root.Context);
		bed.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", l.StackOf("profiler"))).Ok);
		bed.Lay();
		let scene = bed.Controller.Layout.StackOf("scene");

		bed.TabOf("memory").RequestFocus();
		Test.Assert(bed.Root.RunCommand("dock.move-left"));
		bed.Lay();
		Test.Assert(bed.Controller.Layout.StackOf("memory") == scene);
		Test.Assert(FocusedSpace(bed) == bed.Area.MainSpace);
		Test.Assert(FocusedStackOf(bed) == scene);
		Test.Assert(bed.Area.FloatCount == 1);

		// The float's last panel: the float ends with the move (its dock space with it), the focus
		// following the panel into the main surface.
		bed.TabOf("profiler").RequestFocus();
		Test.Assert(bed.Root.RunCommand("dock.move-up"));
		bed.Lay();
		Test.Assert(bed.Area.FloatCount == 0);
		Test.Assert(bed.Controller.Layout.StackOf("profiler") == scene);
		Test.Assert(FocusedStackOf(bed) == scene);
	}

	[Test]
	public static void DockNextSurfaceAndDockPreviousSurfaceGoAroundTheSurfacesBackToTheStackLastFocusedInEach()
	{
		let bed = scope AreaBed();
		DefineDockingCommands(bed.Root.Context);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("console", l.CentralStack, .End, 0.3f)).Ok);
		bed.Lay();
		bed.TabOf("scene").RequestFocus();
		bed.Root.RunCommand("dock.next-surface"); // no other surface to go to
		Test.Assert(FocusedStackOf(bed) == bed.Controller.Layout.StackOf("scene"));
		bed.Float("profiler", .(100.0f, 80.0f, 200.0f, 160.0f));
		bed.Float("memory", .(350.0f, 100.0f, 150.0f, 120.0f));
		let layout = bed.Controller.Layout;

		bed.TabOf("console").RequestFocus(); // the main surface's second stack
		Test.Assert(bed.Root.RunCommand("dock.next-surface"));
		Test.Assert(FocusedStackOf(bed) == layout.StackOf("profiler"));
		Test.Assert(bed.Area.GetChildAt(bed.Area.ChildCount - 2) == bed.Area.GetFloat(0)); // brought to the front
		Test.Assert(bed.Root.RunCommand("dock.next-surface"));
		Test.Assert(FocusedStackOf(bed) == layout.StackOf("memory"));
		Test.Assert(bed.Root.RunCommand("dock.next-surface"));
		Test.Assert(FocusedStackOf(bed) == layout.StackOf("console")); // around, to where it was
		Test.Assert(bed.Root.RunCommand("dock.previous-surface"));
		Test.Assert(FocusedStackOf(bed) == layout.StackOf("memory"));
	}

	[Test]
	public static void AFloatsMoveToMenuListsTheOtherSurfacesStacksNamedForWhereTheyAre()
	{
		let bed = scope AreaBed();
		bed.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f));
		bed.Float("memory", .(420.0f, 100.0f, 200.0f, 160.0f));
		let space = bed.SpaceOf("profiler");
		Test.Assert(space != null);
		let menu = space.OpenMoveTo("profiler", bed.TabOf("profiler"), .(0.0f, 0.0f));
		Test.Assert(menu != null);
		Menu into = null;
		for (int i < menu.ChildCount)
		{
			let sub = menu.GetChildAt(i) as MenuSubItem;
			if ((sub != null) && (sub.Text == "Into"))
				into = sub.SubMenu;
		}
		Test.Assert(into != null);
		MenuItem scene = null;
		bool memory = false;
		for (int i < into.ChildCount)
		{
			let item = into.GetChildAt(i) as MenuItem;
			if (item == null)
				continue;
			if (item.Text == "Scene (main)")
				scene = item;
			memory = memory || (item.Text == "Memory (floating)");
		}
		Test.Assert(memory);
		Test.Assert(scene != null);
		scene.HandleActivate(); // the float's only panel: the float ends with it
		bed.Lay();
		Test.Assert(bed.Controller.Layout.StackOf("profiler") == bed.Controller.Layout.StackOf("scene"));
		Test.Assert(bed.Area.FloatCount == 1);
		Test.Assert(FocusedStackOf(bed) == bed.Controller.Layout.StackOf("scene"));
	}

	[Test]
	public static void AStacksGripDraggedWithShiftFloatsTheWholeStackAtThePointerAFloatClosedWholeByItsCross()
	{
		let bed = scope AreaBed();
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("profiler", l.CentralStack, .End, 0.4f)).Ok);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", l.StackOf("profiler"))).Ok);
		bed.Lay();
		let stack = bed.Controller.Layout.StackOf("profiler");
		let view = bed.Area.MainSpace.WidgetOf(stack) as TabView;
		Test.Assert(view != null);
		let grip = Centre(view.Bar.ListButton.ScreenBounds);
		let over = Float2(300.0f, 300.0f);
		bed.D.InjectMouseDown(grip, .Left);
		bed.D.InjectMouseMove(.(grip.X - 20.0f, grip.Y + 10.0f), KeyModShift);
		bed.D.InjectMouseMove(over, KeyModShift);
		Test.Assert(bed.D.IsDragging);
		Test.Assert(bed.D.DropTarget == bed.Area);
		Rectangle preview = .();
		Test.Assert(bed.Area.GetFloatPreview(out preview));
		bed.D.InjectMouseUp(over, .Left, KeyModShift);
		bed.Lay();
		Test.Assert(bed.Area.FloatCount == 1);
		let window = bed.Area.GetFloat(0);
		let layout = bed.Controller.Layout;
		Test.Assert(layout.FindSurface(window.Surface).Root == stack); // the stack itself, floated
		Test.Assert(layout.FindNode(stack).Panels.Count == 2);
		Test.Assert(Near(window.Position.X, preview.X));

		// Its strip's cross closes both, and the float with them.
		let floated = window.Space.WidgetOf(stack) as TabView;
		Test.Assert(floated != null);
		floated.Bar.CloseAll();
		Test.Assert(bed.Controller.Layout.StackOf("profiler") == cNoDock);
		Test.Assert(bed.Controller.Layout.StackOf("memory") == cNoDock);
		bed.Lay();
		Test.Assert(bed.Area.FloatCount == 0);
	}

	[Test]
	public static void GivenWindowsOfTheirOwnAFloatOpensInOneTitledAndPlacedOnTheScreenItsMovesAndCloseAreHeardBackAgain()
	{
		let bed = scope AreaBed();
		let floating = bed.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f));
		Test.Assert(bed.Area.FloatCount == 1);
		let windows = scope FakeWindows(bed);
		// The area and the GUI let go of the windows however the test ends (before the windows go).
		defer
		{
			bed.Root.Context.RootPlaces = null;
			bed.Area.SetWindows(null);
		}
		bed.Area.SetWindows(windows);
		Test.Assert(bed.Area.FloatCount == 0); // no float in the area
		Test.Assert(windows.Opens == 1);
		Test.Assert(windows.Shown.Count == 1);
		Test.Assert(windows.Shown[0].Surface == floating);
		Test.Assert(windows.Shown[0].Title == "Profiler");
		Test.Assert(Near(windows.Shown[0].Bounds.X, 1100.0f)); // the area's 100, on the screen
		Test.Assert(Near(windows.Shown[0].Bounds.Y, 580.0f));
		Test.Assert(Near(bed.Controller.Layout.FindSurface(floating).Bounds.X, 1100.0f));
		let space = bed.Area.WindowSpaceOf(floating);
		Test.Assert(space != null);
		Test.Assert(space.PageOf("profiler") != null);
		Test.Assert(space.RootNode == windows.Shown[0].Root);

		// Moved by the user: the layout follows, and the window is not placed again.
		bed.Area.NoteWindowBounds(floating, .(1200.0f, 600.0f, 320.0f, 210.0f));
		Test.Assert(Near(bed.Controller.Layout.FindSurface(floating).Bounds.X, 1200.0f));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", l.StackOf("profiler"))).Ok);
		Test.Assert(windows.Shown[0].Title == "Memory +1"); // the chosen panel's, and how many more
		Test.Assert(windows.Places == 0);
		// A layout that places it, the window placed there.
		bed.Controller.NoteSurfaceBounds(floating, .(1300.0f, 650.0f, 320.0f, 210.0f));
		bed.Area.ShowLayout();
		Test.Assert(windows.Places == 1);
		Test.Assert(Near(windows.Shown[0].Bounds.X, 1300.0f));

		// Floats in the area again: the window closes, the float comes back at the area's 300,150.
		bed.Area.SetWindows(null);
		Test.Assert(windows.Closes == 1);
		Test.Assert(bed.Area.FloatCount == 1);
		Test.Assert(Near(bed.Area.GetFloat(0).Position.X, 300.0f));
		Test.Assert(Near(bed.Area.GetFloat(0).Position.Y, 150.0f));

		// In its own window again, closed by its window's close: its panels close, and the window.
		bed.Area.SetWindows(windows);
		Test.Assert(windows.Shown.Count == 1);
		bed.Area.CloseFloat(floating);
		Test.Assert(bed.Controller.Layout.FindSurface(floating) == null);
		Test.Assert(windows.Shown.Count == 0);
		bed.Area.SetWindows(null);
	}

	[Test]
	public static void InWindowsOfTheirOwnATabLetGoOutsideEveryWindowFloatsThereWithShiftAtThePointerOnTheScreen()
	{
		let bed = scope AreaBed();
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("profiler", l.CentralStack)).Ok);
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", l.CentralStack)).Ok);
		bed.Lay();
		let windows = scope FakeWindows(bed);
		defer
		{
			bed.Root.Context.RootPlaces = null;
			bed.Area.SetWindows(null);
		}
		bed.Area.SetWindows(windows);
		bed.Root.Context.RootPlaces = windows;

		// Past the area's left edge: outside every window, at the screen's 970,600.
		var tab = bed.TabOf("profiler");
		Test.Assert(tab != null);
		let from = tab.ScreenBounds;
		let press = Float2(from.X + 10.0f, from.Y + 10.0f);
		bed.D.InjectMouseDown(press, .Left);
		bed.D.InjectMouseMove(.(press.X, press.Y + 40.0f));
		bed.D.InjectMouseMove(.(-30.0f, 100.0f));
		Test.Assert(bed.D.IsDragging);
		Test.Assert(bed.D.DragOver == null);
		bed.D.InjectMouseUp(.(-30.0f, 100.0f), .Left);
		Test.Assert(windows.Shown.Count == 1);
		let @out = windows.Shown[0].Surface;
		Test.Assert(bed.Controller.Layout.SurfaceOf(bed.Controller.Layout.StackOf("profiler")) == @out);
		Test.Assert(Near(windows.Shown[0].Bounds.Y, 586.0f)); // its title bar under the pointer
		Test.Assert(windows.Shown[0].Bounds.X < 970.0f);
		Test.Assert(windows.Shown[0].Bounds.X + windows.Shown[0].Bounds.Width > 970.0f);

		// Its window moved off the area by the user (the system moves it), out of the way.
		windows.Shown[0].Bounds.X = 3000.0f;
		windows.Shown[0].Bounds.Y = 3000.0f;
		bed.Area.NoteWindowBounds(@out, windows.Shown[0].Bounds);

		// With Shift over the area: the preview in the area, the window where it was, on the screen.
		bed.Lay();
		tab = bed.TabOf("memory");
		Test.Assert(tab != null);
		let at = tab.ScreenBounds;
		let p = Float2(at.X + 10.0f, at.Y + 10.0f);
		let over = Float2(400.0f, 300.0f);
		bed.D.InjectMouseDown(p, .Left);
		bed.D.InjectMouseMove(.(p.X + 10.0f, p.Y), KeyModShift);
		bed.D.InjectMouseMove(over, KeyModShift);
		Rectangle preview = .();
		Test.Assert(bed.Area.GetFloatPreview(out preview));
		bed.D.InjectMouseUp(over, .Left, KeyModShift);
		Test.Assert(windows.Shown.Count == 2);
		Test.Assert(Near(windows.Shown[1].Bounds.X, preview.X + 1000.0f));
		Test.Assert(Near(windows.Shown[1].Bounds.Y, preview.Y + 500.0f));

		// The surface cycle raises the window it goes to.
		bed.Lay();
		bed.TabOf("scene").RequestFocus();
		Test.Assert(bed.Area.FocusNextSurface(false));
		Test.Assert(windows.Shown[0].Raises == 1);

		bed.Root.Context.RootPlaces = null;
		bed.Area.SetWindows(null);
	}

	[Test]
	public static void AWindowThatCannotBeOpenedTakesTheAreaBackToFloatsInIt()
	{
		let bed = scope AreaBed();
		bed.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f));
		let windows = scope FakeWindows(bed);
		defer
		{
			bed.Root.Context.RootPlaces = null;
			bed.Area.SetWindows(null);
		}
		windows.Refuse = true;
		bed.Area.SetWindows(windows);
		Test.Assert(bed.Area.Windows == null);
		Test.Assert(bed.Area.FloatCount == 1);
		Test.Assert(Near(bed.Area.GetFloat(0).Position.X, 100.0f)); // its place back in the area's units
	}

	/// A float's title is its first stack's chosen panel's, then how many more it holds; choosing
	/// another tab there retitles it once the layout is shown again.
	[Test]
	public static void AFloatsTitleFollowsTheTabChosenInItsFirstStack()
	{
		let bed = scope AreaBed();
		let floating = bed.Float("profiler", .(100.0f, 80.0f, 300.0f, 200.0f));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("memory", l.StackOf("profiler"))).Ok);
		bed.Lay();
		let window = bed.Area.FloatOf(floating);
		Test.Assert(window != null);
		Test.Assert(window.Title == "Memory +1");
		// The user chooses the profiler's tab: noted quietly, the title as it was until a show.
		let view = window.Space.WidgetOf(bed.Controller.Layout.StackOf("profiler")) as TabView;
		Test.Assert(view != null);
		view.Bar.SelectByUser(0);
		Test.Assert(bed.Controller.Layout.FindNode(bed.Controller.Layout.StackOf("profiler")).Active == 0);
		bed.Area.ShowLayout();
		Test.Assert(window.Title == "Profiler +1");
		// One panel left: no count.
		Test.Assert(bed.Controller.Edit(scope (l) => l.MoveToTab("memory", l.CentralStack)).Ok);
		Test.Assert(window.Title == "Profiler");
	}

	/// A panel floated from its stack is no larger than most of the area and no smaller than a
	/// window can be used at, whatever its stack's size.
	[Test]
	public static void AFloatsSizeKeepsWithinMostOfTheAreaAndAUsableLeast()
	{
		let bed = scope AreaBed();
		var bounds = bed.Area.FloatBoundsFor("scene"); // alone: its stack is the whole area
		Test.Assert(Near(bounds.Width, 800.0f * 0.7f));
		Test.Assert(Near(bounds.Height, 600.0f * 0.7f));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertBeside("console", l.CentralStack, .Bottom, 0.05f)).Ok);
		bed.Lay();
		bounds = bed.Area.FloatBoundsFor("console"); // a thin strip along the bottom
		Test.Assert(Near(bounds.Width, 800.0f * 0.7f));
		Test.Assert(Near(bounds.Height, 140.0f));
	}
}
