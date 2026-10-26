using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Docking.Tests.DockingFixtures;

namespace Sedulous.GUI.Docking.Tests;

/// Drag to dock within one window (D4 of Specs/gui-lab-evolution-3.md): a tab torn from a stack's
/// strip carries its panel; over a strip it goes in at a tab's place, over a stack's middle into it,
/// over its edge band beside it, over the surface's band along the whole edge. Each drop is the
/// layout's move, tried on a copy first: the preview is where the panel would be, and a move the
/// layout refuses shows its reason and does nothing. Meanwhile the torn tab dims (or its strip
/// closes up, as the theme says), shown again as the layout has it when the drag ends. A stack's
/// grip (its strip's list button) carries the whole stack the same ways, and lists its tabs when
/// clicked; the cross past it closes every closable panel of the stack.
class DockDropTests
{
	// A drag of `panel`'s stack by its strip's grip, past the threshold.
	private static void GrabStack(DockBed bed, StringView panel)
	{
		let grip = bed.ViewOf(panel).Bar.ListButton;
		Test.Assert(grip.Displayed);
		let at = Centre(Bounds(grip));
		bed.D.InjectMouseDown(at, .Left);
		bed.D.InjectMouseMove(.(at.X - 20.0f, at.Y + 20.0f));
		bed.D.InjectMouseMove(.(at.X - 30.0f, at.Y + 30.0f));
		Test.Assert(bed.D.IsDragging);
	}

	[Test]
	public static void OverAStacksMiddleThePanelTabsIntoItThePreviewIsTheStack()
	{
		let bed = scope DockBed();
		let hierarchy = bed.StackOf("hierarchy");
		bed.Tear("inspector");
		let stack = Bounds(bed.Space.WidgetOf(hierarchy));
		let middle = Centre(stack);
		bed.Over(middle);
		Test.Assert(bed.D.DropTarget == bed.Space.WidgetOf(hierarchy));
		Rect preview = .();
		Test.Assert(bed.Preview(out preview));
		Test.Assert(Near(preview.X, stack.X, 0.02));
		Test.Assert(Near(preview.Width, stack.Width, 0.05));
		Test.Assert(bed.Controller.Layout.StackOf("inspector") != hierarchy); // nothing moved yet
		bed.Release(middle);
		Test.Assert(bed.StackOf("inspector") == hierarchy);
		Test.Assert(!bed.Preview(out preview));
		Test.Assert(bed.Space.PageOf("inspector") != null);
	}

	[Test]
	public static void OverAStacksEdgeBandThePanelGoesBesideItThePreviewItsHalf()
	{
		let bed = scope DockBed();
		let console = bed.StackOf("console");
		bed.Tear("inspector");
		let stack = Bounds(bed.Space.WidgetOf(console));
		let right = Float2(stack.X + stack.Width - 30.0f, stack.Y + stack.Height * 0.5f); // in its band (64)
		bed.Over(right);
		Rect preview = .();
		Test.Assert(bed.Preview(out preview));
		Test.Assert(Near(preview.X, stack.X + stack.Width * 0.5f, 0.03));
		Test.Assert(Near(preview.Width, stack.Width * 0.5f, 0.05));
		bed.Release(right);
		let inspector = bed.StackOf("inspector");
		Test.Assert(inspector != cNoDock);
		Test.Assert(inspector != console);
		let layout = bed.Controller.Layout;
		let split = layout.FindNode(layout.FindNode(inspector).Parent);
		Test.Assert(split != null);
		Test.Assert(split.Axis == .Horizontal);
		Test.Assert(split.Children[0] == console);
		Test.Assert(split.Children[1] == inspector);
	}

	[Test]
	public static void OverTheSurfacesBandThePanelGoesAlongTheWholeEdge()
	{
		let bed = scope DockBed();
		bed.Tear("inspector");
		let top = Float2(400.0f, 4.0f); // over the central strip, in the band's outer third (20 / 3)
		// Down the left side, over the hierarchy's body: the surface's band too.
		bed.Over(.(6.0f, 300.0f));
		Test.Assert(bed.D.DropTarget == bed.Space);
		bed.Over(top);
		Test.Assert(bed.D.DropTarget != null); // the strip under it, which leaves the band its due
		Rect preview = .();
		Test.Assert(bed.Preview(out preview));
		Test.Assert(Near(preview.Y, 0.0f));
		Test.Assert(Near(preview.Width, 800.0f));
		Test.Assert(Near(preview.Height, 150.0f, 0.05)); // a quarter
		bed.Release(top);
		let layout = bed.Controller.Layout;
		let root = layout.FindNode(layout.FindSurface(layout.MainSurface).Root);
		Test.Assert(root != null);
		Test.Assert(root.Axis == .Vertical);
		Test.Assert(root.Children[0] == bed.StackOf("inspector"));
	}

	[Test]
	public static void OverAStripThePanelGoesInAtATabsPlaceCountedAsTheTabsAre()
	{
		let bed = scope DockBed();
		// Into the console's strip, before the console.
		bed.Tear("scene");
		let consoleTab = Bounds(bed.TabOf("console"));
		let before = Float2(consoleTab.X + 10.0f, consoleTab.Y + 10.0f);
		bed.Over(before);
		Test.Assert(bed.D.DropTarget == bed.ViewOf("console").Bar);
		bed.Release(before);
		var stack = bed.Controller.Layout.FindNode(bed.StackOf("console"));
		Test.Assert(stack.Panels.Count == 2);
		Test.Assert(stack.Panels[0] == "scene");
		Test.Assert(stack.Panels[1] == "console");
		bed.Lay();
		// Within its own strip, torn and dropped after the console: last.
		bed.Tear("scene");
		let after = Bounds(bed.TabOf("console"));
		let end = Float2(after.X + after.Width - 5.0f, after.Y + 10.0f);
		bed.Over(end);
		bed.Release(end);
		stack = bed.Controller.Layout.FindNode(bed.StackOf("console"));
		Test.Assert(stack.Panels[0] == "console");
		Test.Assert(stack.Panels[1] == "scene");
	}

	[Test]
	public static void AMoveTheLayoutRefusesShowsItsReasonNoPreviewAndDoesNothingEscapeLeavesItAsItWas()
	{
		let bed = scope DockBed();
		let hierarchy = bed.StackOf("hierarchy");
		Test.Assert(bed.Controller.Edit(scope (l) => l.SetStackFlags(hierarchy, DockStackNoTabs)).Ok);
		bed.Lay();
		bed.Tear("inspector");
		let middle = Centre(Bounds(bed.Space.WidgetOf(hierarchy)));
		bed.Over(middle);
		Test.Assert(bed.D.DropTarget == null);
		Test.Assert(!bed.D.DropReason.IsEmpty);
		Rect preview = .();
		Test.Assert(!bed.Preview(out preview));
		bed.Release(middle);
		Test.Assert(bed.StackOf("inspector") == bed.Controller.Layout.CentralStack);

		bed.Tear("inspector");
		let console = Centre(Bounds(bed.Space.WidgetOf(bed.StackOf("console"))));
		bed.Over(console);
		Test.Assert(bed.Preview(out preview));
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!bed.D.IsDragging);
		Test.Assert(!bed.Preview(out preview));
		Test.Assert(bed.StackOf("inspector") == bed.Controller.Layout.CentralStack);
	}

	[Test]
	public static void TheBandsAreTheSheetsThroughTheThemesTokens()
	{
		let bed = scope DockBed();
		let styles = scope StyleManager();
		let css = scope String();
		css.Append(DockingSheetCSS());
		css.Append(" :root { --dock-edge: 40px; --dock-surface-edge: 12px; }");
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		styles.StyleSheet = sheet;
		styles.ApplyTree(bed.Root);
		Test.Assert(Near(bed.Space.EdgeBand, 40.0f));
		Test.Assert(Near(bed.Space.SurfaceBand, 12.0f));
	}

	[Test]
	public static void ATornTabClosesUpItsStripANeighbourShownAndEscapeShowsTheStackAsItWas()
	{
		let bed = scope DockBed();
		bed.Space.TornTab = .Close;
		let central = bed.ViewOf("inspector");
		Test.Assert(central != null);
		let inspector = bed.TabOf("inspector");
		central.SelectedIndex = central.Bar.IndexOf(inspector);
		bed.Lay();
		bed.Tear("inspector");
		Test.Assert(!inspector.Displayed);
		Test.Assert(central.SelectedPage == bed.Space.PageOf("scene")); // the view's, not the layout's
		let stack = bed.Controller.Layout.FindNode(bed.StackOf("inspector"));
		Test.Assert(stack.Panels[(int)stack.Active] == "inspector");
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(inspector.Displayed);
		Test.Assert(central.SelectedPage == bed.Space.PageOf("inspector"));

		// Dropped into another stack: it is there, shown, and its old stack shows what the layout has.
		bed.Tear("inspector");
		let middle = Centre(Bounds(bed.Space.WidgetOf(bed.StackOf("console"))));
		bed.Over(middle);
		bed.Release(middle);
		Test.Assert(bed.TabOf("inspector") != null);
		Test.Assert(bed.TabOf("inspector").Displayed);
		Test.Assert(central.SelectedPage == bed.Space.PageOf("scene"));
	}

	[Test]
	public static void ATornTabDimsByDefaultTheThemesTornTabClosesItUpAStacksOnlyTabDimsItsStack()
	{
		let bed = scope DockBed();
		{
			let styles = scope StyleManager();
			let sheet = scope StyleSheet();
			CSSParser.Parse(DockingSheetCSS(), sheet);
			styles.StyleSheet = sheet;
			styles.ApplyTree(bed.Root);
			Test.Assert(bed.Space.TornTab == .Dim);
			let css = scope String();
			css.Append(DockingSheetCSS());
			css.Append(" :root { --dock-torn-tab: close; }");
			let closing = scope StyleSheet();
			CSSParser.Parse(css, closing);
			styles.StyleSheet = closing;
			styles.ApplyTree(bed.Root);
			Test.Assert(bed.Space.TornTab == .Close);
		}
		bed.Space.TornTab = .Dim;
		bed.Tear("inspector");
		let inspector = bed.TabOf("inspector");
		Test.Assert(inspector.Displayed);
		Test.Assert(inspector.HasClass("dock-torn"));
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!inspector.HasClass("dock-torn"));

		bed.Space.TornTab = .Close;
		bed.Tear("hierarchy"); // alone in its stack: the stack dims, the tab stays
		Test.Assert(bed.TabOf("hierarchy").Displayed);
		Test.Assert(bed.ViewOf("hierarchy").HasClass("dock-torn"));
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!bed.ViewOf("hierarchy").HasClass("dock-torn"));
	}

	[Test]
	public static void ATabMovedAFewPixelsAlongItsStripIsADragAtOnceDroppedFurtherAlongTheLayoutReordersIt()
	{
		let bed = scope DockBed();
		let central = bed.Controller.Layout.CentralStack;
		Test.Assert(bed.Controller.Layout.FindNode(central).Panels[0] == "scene");
		bed.Space.TornTab = .Close;
		let scene = bed.TabOf("scene");
		let start = Centre(Bounds(scene));
		bed.D.InjectMouseDown(start, .Left);
		bed.Over(.(start.X + 8.0f, start.Y));
		Test.Assert(bed.D.IsDragging);
		Test.Assert(!scene.Displayed); // its strip closed up from the first move
		bed.Lay();
		let inspector = Bounds(bed.TabOf("inspector"));
		let end = Float2(inspector.X + inspector.Width - 5.0f, start.Y);
		bed.Over(end);
		bed.Release(end);
		let stack = bed.Controller.Layout.FindNode(central);
		Test.Assert(stack.Panels[0] == "inspector");
		Test.Assert(stack.Panels[1] == "scene");
		Test.Assert(bed.TabOf("scene").Displayed);
	}

	[Test]
	public static void AStacksGripDraggedCarriesTheWholeStackIntoAStackOverItsStripBesideOneByItsEdge()
	{
		{
			let bed = scope DockBed();
			let central = bed.ViewOf("scene");
			GrabStack(bed, "scene"); // scene and inspector
			Test.Assert(central.HasClass("dock-torn")); // the stack dims while it is carried
			Test.Assert(bed.ViewOf("hierarchy").Bar.TabListMenu == null);
			let strip = Centre(Bounds(bed.TabOf("hierarchy")));
			bed.Over(strip);
			Test.Assert(bed.D.DropTarget == bed.ViewOf("hierarchy").Bar);
			Rect preview = .();
			Test.Assert(bed.Preview(out preview));
			bed.Release(strip);
			let into = bed.Controller.Layout.FindNode(bed.StackOf("hierarchy"));
			Test.Assert(into.Panels.Count == 3);
			Test.Assert(into.Panels[1] == "scene");
			Test.Assert(into.Panels[2] == "inspector");
			// The central stack stays, emptied; the drag opened no list.
			Test.Assert(bed.Controller.Layout.FindNode(bed.Controller.Layout.CentralStack).Panels.IsEmpty);
			Test.Assert(!central.HasClass("dock-torn"));
			Test.Assert(central.Bar.TabListMenu == null);
		}
		{
			let bed = scope DockBed();
			let console = bed.StackOf("console");
			GrabStack(bed, "console");
			// Into the hierarchy's bottom edge band: the stack beside it, below.
			let h = Bounds(bed.Space.WidgetOf(bed.StackOf("hierarchy")));
			let low = Float2(h.X + h.Width * 0.5f, h.Y + h.Height - 40.0f); // past the surface's own band
			bed.Over(low);
			bed.Release(low);
			Test.Assert(bed.StackOf("console") == console); // the same stack, moved
			let layout = bed.Controller.Layout;
			let split = layout.FindNode(layout.FindNode(console).Parent);
			Test.Assert(split.Axis == .Vertical);
			Test.Assert(split.Children[0] == bed.StackOf("hierarchy"));
			Test.Assert(split.Children[1] == console);
			Test.Assert(!bed.Space.WidgetOf(console).HasClass("dock-torn")); // shown again, not dimmed
		}
		{
			// Along the whole area's bottom edge (the surface's own band): moved there, not dimmed.
			let bed = scope DockBed();
			let console = bed.StackOf("console");
			GrabStack(bed, "console");
			let area = Bounds(bed.Space);
			let bottom = Float2(area.X + area.Width * 0.5f, area.Y + area.Height - 4.0f);
			bed.Over(bottom);
			bed.Release(bottom);
			Test.Assert(bed.Space.WidgetOf(bed.StackOf("console")) != null);
			DockNodeId[2] stacks = .(bed.StackOf("console"), console);
			for (let stack in stacks)
			{
				let widget = bed.Space.WidgetOf(stack);
				if (widget != null)
					Test.Assert(!widget.HasClass("dock-torn"));
			}
		}
	}

	[Test]
	public static void AStacksGripClickedListsItsTabsTheCrossPastItClosesEveryClosablePanelOfTheStack()
	{
		let bed = scope DockBed();
		Test.Assert(bed.Controller.Register(PanelNamed("fixed", default, false)));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("fixed", bed.StackOf("scene"), 0)).Ok);
		bed.Lay();
		let bar = bed.ViewOf("scene").Bar;
		let grip = Centre(Bounds(bar.ListButton));
		bed.D.InjectMouseDown(grip, .Left);
		bed.D.InjectMouseUp(grip, .Left);
		let list = bar.TabListMenu;
		Test.Assert(list != null);
		Test.Assert(list.ItemCount == 3);
		list.Close();

		Test.Assert(bar.CloseAllPart.Displayed);
		let cross = Centre(Bounds(bar.CloseAllPart));
		bed.D.InjectMouseDown(cross, .Left);
		bed.D.InjectMouseUp(cross, .Left);
		Test.Assert(bed.StackOf("scene") == cNoDock);
		Test.Assert(bed.StackOf("inspector") == cNoDock);
		Test.Assert(bed.StackOf("fixed") == bed.Controller.Layout.CentralStack); // it cannot be closed
		bed.Lay();
		Test.Assert(!bed.ViewOf("fixed").Bar.CloseAllPart.Displayed); // nothing left to close
	}

	/// The drop a point means, asked directly: the surface's band first (its outer part only where
	/// a share of it is asked), then the stack's edge band, then its middle; nowhere over no stack.
	[Test]
	public static void ThePointsDropTheSurfacesBandThenTheStacksEdgeBandThenItsMiddle()
	{
		let bed = scope DockBed();
		let console = bed.StackOf("console");
		let c = Bounds(bed.Space.WidgetOf(console));
		DockDrop drop = .();
		// The surface's bottom edge, under the console: along the whole edge.
		Test.Assert(bed.Space.DropAt(.(c.X + c.Width * 0.5f, 598.0f), console, out drop));
		Test.Assert(drop.Kind == .Edge);
		Test.Assert(drop.Side == .Bottom);
		Test.Assert(drop.Surface == bed.Controller.Layout.MainSurface);
		// The same point with a third of the band asked (a strip's): 2 is still in its outer third.
		Test.Assert(bed.Space.DropAt(.(c.X + c.Width * 0.5f, 598.0f), console, out drop, 1.0f / 3.0f));
		Test.Assert(drop.Kind == .Edge);
		// 15 from the edge is in the band, but not in its outer third: the console's own band.
		Test.Assert(bed.Space.DropAt(.(c.X + c.Width * 0.5f, 585.0f), console, out drop, 1.0f / 3.0f));
		Test.Assert(drop.Kind == .Beside);
		Test.Assert(drop.Stack == console);
		Test.Assert(drop.Side == .Bottom);
		// Its left band, well inside the surface: beside it, at its start.
		Test.Assert(bed.Space.DropAt(.(c.X + 30.0f, c.Y + c.Height * 0.5f), console, out drop));
		Test.Assert(drop.Kind == .Beside);
		Test.Assert(drop.Side == .Start);
		// Its middle: into it.
		Test.Assert(bed.Space.DropAt(Centre(c), console, out drop));
		Test.Assert(drop.Kind == .Middle);
		Test.Assert(drop.Stack == console);
		// Over no stack and in no band: nothing.
		Test.Assert(!bed.Space.DropAt(.(400.0f, 300.0f), cNoDock, out drop));
	}

	/// The bands are at most what they are set to and at most a third of what they edge: a
	/// point past the stack's band is its middle however wide the stack, and a surface's band
	/// set past a third of the surface takes only that third.
	[Test]
	public static void EachBandIsAtMostItsSettingAndAThirdOfWhatItEdges()
	{
		let bed = scope DockBed();
		let central = bed.Controller.Layout.CentralStack;
		let c = Bounds(bed.Space.WidgetOf(central));
		Test.Assert(c.Width > 150.0f); // its third wider than the band below
		bed.Space.EdgeBand = 40.0f;
		DockDrop drop = .();
		Test.Assert(bed.Space.DropAt(.(c.X + 45.0f, c.Y + c.Height * 0.5f), central, out drop));
		Test.Assert(drop.Kind == .Middle);
		Test.Assert(bed.Space.DropAt(.(c.X + 35.0f, c.Y + c.Height * 0.5f), central, out drop));
		Test.Assert(drop.Kind == .Beside);

		let s = bed.Space.ScreenBounds;
		bed.Space.SurfaceBand = 10000.0f;
		let third = Math.Min(s.Width, s.Height) / 3.0f;
		Test.Assert(!bed.Space.DropAt(.(third + 5.0f, s.Height * 0.5f), cNoDock, out drop));
		Test.Assert(bed.Space.DropAt(.(third - 5.0f, s.Height * 0.5f), cNoDock, out drop));
		Test.Assert(drop.Kind == .Edge);
	}
}
