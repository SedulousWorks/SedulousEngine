using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The docking system: the pieces on their own, then the manager that arranges them.
class DockingTests
{
	/// A context, a root and a laid out dock manager, which is what every manager case needs.
	private class DockBed
	{
		public UIContext Context = new .();
		public RootView Root = new .();
		public DockManager Manager = new .();

		public this()
		{
			Root.ViewportSize = .(800, 600);
			Context.AddRootView(Root);
			Root.AddView(Manager);
			Layout();
		}

		public ~this()
		{
			Root.ReleaseRef();
			delete Context;
		}

		public void Layout()
		{
			Context.BeginFrame(0.016f);
			Root.Measure(BoxConstraints.Tight(800, 600));
			Root.Layout(0, 0, 800, 600);
		}

		/// TWICE: the dock re-selects its tab groups on the first pass, and the sizes that
		/// follow from that only apply on the second.
		public void SettleLayout()
		{
			Context.BeginFrame(0.016f);
			Context.UpdateRootView(Root);
			Context.BeginFrame(0.016f);
			Context.UpdateRootView(Root);
		}
	}

	/// Records what it was asked to make, and keeps the close callback so a test can press the
	/// system's own close button.
	private class FakeWindowHost : IDockableWindowHost
	{
		public bool Chrome = false;
		/// Every view ever handed over, in order: entries stay after the window is destroyed.
		public List<View> Created = new .() ~ delete _;
		/// CreateDockableWindow CONSUMES the reference, so every window handed over is this
		/// host's to release once the test is done with it.
		private List<View> mLive = new .() ~ delete _;
		public delegate void(View) LastOnClose = null ~ delete _;
		public int32 Destroyed = 0;

		public ~this()
		{
			for (let view in mLive)
				view.ReleaseRef();
		}

		public bool SupportsOSWindows() => true;

		public bool UsesOSChrome() => Chrome;

		public void CreateDockableWindow(View view, float width, float height, float x, float y,
			delegate void(View) onCloseRequested)
		{
			Created.Add(view);
			mLive.Add(view);
			delete LastOnClose;
			LastOnClose = onCloseRequested;
		}

		// A BLOCK body: Beef will not take an increment as an expression body.
		public void DestroyDockableWindow(View view)
		{
			// NOT released here: the real host tears its window down asynchronously, and the
			// manager still queues a node deletion on this view straight after the call.
			Destroyed++;
		}

		public void MoveDockableWindow(View view, float x, float y) {}

		public void ResizeDockableWindow(View view, float x, float y, float width, float height) {}

		public bool TryGetDockableWindowBounds(View view, out float x, out float y,
			out float width, out float height)
		{
			x = 0;
			y = 0;
			width = 300;
			height = 250;
			return true;
		}

		public void GetGlobalMousePosition(out float globalX, out float globalY)
		{
			globalX = 0;
			globalY = 0;
		}
	}

	// ---- The pieces -----------------------------------------------------------------------------

	[Test]
	public static void APanelsTitleRoundTrips()
	{
		let panel = new DockablePanel("My Panel");
		defer panel.ReleaseRef();

		Test.Assert(panel.Title == "My Panel");
		panel.SetTitle("Renamed");
		Test.Assert(panel.Title == "Renamed");
	}

	[Test]
	public static void APanelsContentIsReadBack()
	{
		let panel = new DockablePanel("Test");
		defer panel.ReleaseRef();

		let content = new Label();
		content.AddRef();
		defer content.ReleaseRef();

		panel.SetContent(content);
		Test.Assert(panel.ContentView == content);
	}

	/// The ratio is held AWAY from both ends, so a divider dragged to an edge still leaves a
	/// sliver of the other pane to drag back by.
	[Test]
	public static void ASplitsRatioIsClampedAwayFromTheEdges()
	{
		let split = new DockSplit();
		defer split.ReleaseRef();

		split.SplitRatio = -1.0f;
		Test.Assert(split.SplitRatio >= 0.05f);

		split.SplitRatio = 2.0f;
		Test.Assert(split.SplitRatio <= 0.95f);
	}

	[Test]
	public static void ASplitAdoptsBothChildren()
	{
		let split = new DockSplit();
		defer split.ReleaseRef();

		let first = new Label("A");
		let second = new Label("B");
		first.AddRef();
		second.AddRef();
		defer { first.ReleaseRef(); second.ReleaseRef(); }

		split.SetChildren(first, second);
		Test.Assert(split.First == first);
		Test.Assert(split.Second == second);
		Test.Assert(split.ChildCount == 2);
	}

	[Test]
	public static void TheZoneIndicatorTracksItsTargets()
	{
		let indicator = new DockZoneIndicator();
		defer indicator.ReleaseRef();

		Test.Assert(indicator.TargetCount == 0);
		indicator.AddTarget(.Left, .(0, 0, 100, 400), null);
		indicator.AddTarget(.Right, .(300, 0, 100, 400), null);
		Test.Assert(indicator.TargetCount == 2);

		indicator.ClearTargets();
		Test.Assert(indicator.TargetCount == 0);
		Test.Assert(indicator.HoveredIndex == -1);
	}

	[Test]
	public static void TheZoneIndicatorResolvesHover()
	{
		let indicator = new DockZoneIndicator();
		defer indicator.ReleaseRef();

		indicator.AddTarget(.Left, .(0, 0, 100, 400), null);
		indicator.AddTarget(.Right, .(300, 0, 100, 400), null);

		indicator.UpdateHover(50, 200);
		Test.Assert(indicator.HoveredIndex == 0);
		Test.Assert(indicator.HoveredTarget != null);
		Test.Assert(indicator.HoveredTarget.Value.Position == .Left);

		indicator.UpdateHover(350, 200);
		Test.Assert(indicator.HoveredIndex == 1);

		indicator.UpdateHover(200, 200);
		Test.Assert(indicator.HoveredIndex == -1, "between the zones is no zone");
		Test.Assert(indicator.HoveredTarget == null);
	}

	/// A zone carries the region a drop would FILL, which is what the hover wash draws. A zone
	/// added without one shows no wash rather than a zero sized one.
	[Test]
	public static void AZoneCarriesItsDropPreview()
	{
		let indicator = new DockZoneIndicator();
		defer indicator.ReleaseRef();

		indicator.AddTarget(.Left, .(8, 180, 40, 40), null, .(0, 0, 400, 600));
		indicator.AddTarget(.Right, .(752, 180, 40, 40), null);

		indicator.UpdateHover(20, 200);
		Test.Assert(indicator.HoveredTarget != null);
		Test.Assert(indicator.HoveredTarget.Value.PreviewRect.Width == 400);
		Test.Assert(indicator.HoveredTarget.Value.PreviewRect.Height == 600);

		indicator.UpdateHover(760, 200);
		Test.Assert(indicator.HoveredTarget != null);
		Test.Assert(indicator.HoveredTarget.Value.PreviewRect.Width == 0);
	}

	[Test]
	public static void ATabGroupAddsAndRemovesPanels()
	{
		let group = new DockTabGroup();
		defer group.ReleaseRef();

		let first = new DockablePanel("P1");
		let second = new DockablePanel("P2");
		group.AddPanel(first);
		group.AddPanel(second);

		Test.Assert(group.PanelCount == 2);
		Test.Assert(group.GetPanel(0) == first);
		Test.Assert(group.SelectedIndex == 0, "the first panel selects itself");
		Test.Assert(!first.ShowHeader, "a tabbed panel loses its own header");

		let removed = group.RemovePanel(first);
		defer removed.ReleaseRef();
		Test.Assert(removed == first);
		Test.Assert(group.PanelCount == 1);
		Test.Assert(removed.ShowHeader, "and gets it back on the way out");
	}

	[Test]
	public static void ATabGroupsSelectionFollowsItsPanels()
	{
		let group = new DockTabGroup();
		defer group.ReleaseRef();

		group.AddPanel(new DockablePanel("P1"));
		group.AddPanel(new DockablePanel("P2"));
		group.AddPanel(new DockablePanel("P3"));

		var selected = 0;
		group.OnTabSelected.Add(new [&selected](panel) => { selected++; });

		group.SetSelectedIndex(2);
		Test.Assert(group.SelectedIndex == 2);
		Test.Assert(group.SelectedPanel == group.GetPanel(2));
		Test.Assert(selected == 1);

		group.SetSelectedIndex(2);
		Test.Assert(selected == 1, "selecting the same tab reports nothing");

		group.SetSelectedIndex(99);
		Test.Assert(group.SelectedIndex == 2, "out of range changes nothing");
	}

	[Test]
	public static void AWindowHandsBackItsPanel()
	{
		let panel = new DockablePanel("Floating");
		let window = new DockableWindow(panel);
		defer window.ReleaseRef();

		Test.Assert(window.Panel == panel);

		let detached = window.DetachPanel();
		defer detached.ReleaseRef();
		Test.Assert(detached == panel);
		Test.Assert(window.Panel == null);
		Test.Assert(window.DetachPanel() == null, "and only once");
	}

	// ---- The manager ----------------------------------------------------------------------------

	[Test]
	public static void AddPanelRegistersWithoutDocking()
	{
		let bed = scope DockBed();

		let panel = bed.Manager.AddPanel("Test", new Label("Content"));
		Test.Assert(panel != null);
		Test.Assert(panel.Title == "Test");
		Test.Assert(panel.DockHost == bed.Manager);
		Test.Assert(bed.Manager.RootNode == null, "registering is not docking");

		bed.Manager.DockPanel(panel, .Center);
		Test.Assert(bed.Manager.RootNode != null);
	}

	[Test]
	public static void DockingTwoPanelsSideBySideMakesASplit()
	{
		let bed = scope DockBed();

		let first = bed.Manager.AddPanel("P1", new Label("Content 1"));
		let second = bed.Manager.AddPanel("P2", new Label("Content 2"));

		bed.Manager.DockPanel(first, .Center);
		Test.Assert(bed.Manager.RootNode is DockTabGroup);

		bed.Manager.DockPanel(second, .Right);
		Test.Assert(bed.Manager.RootNode is DockSplit);
	}

	/// A DELIBERATE DEVIATION from the original, which kept the existing selection and left an
	/// editor to activate by hand. Activating on dock is what every mainstream tool of this
	/// shape does, and every path into docking comes through the same place.
	[Test]
	public static void DockingIntoTabsActivatesTheNewTab()
	{
		let bed = scope DockBed();

		let first = bed.Manager.AddPanel("P1", new Label("Content 1"));
		let second = bed.Manager.AddPanel("P2", new Label("Content 2"));
		let third = bed.Manager.AddPanel("P3", new Label("Content 3"));

		bed.Manager.DockPanel(first, .Center);
		bed.Manager.DockPanel(second, .Center);

		let group = second.Parent as DockTabGroup;
		Test.Assert(group != null);
		Test.Assert(group.PanelCount == 2);
		Test.Assert(group.SelectedPanel == second);

		bed.Manager.DockPanelRelativeTo(third, .Center, first.Parent);
		Test.Assert(group.SelectedPanel == third);

		// And activating a background tab by hand still works.
		bed.Manager.ActivatePanel(first);
		Test.Assert(group.SelectedPanel == first);
	}

	/// A press ANYWHERE inside a panel makes it active, not just on its tab. With two groups
	/// side by side a panel can already be its own group's selected tab while a different one
	/// is the application's active panel, so a tab click alone can never re-announce it.
	[Test]
	public static void APressInsideAPanelActivatesIt()
	{
		let bed = scope DockBed();

		let a = bed.Manager.AddPanel("A", new Label("A"));
		let b = bed.Manager.AddPanel("B", new Label("B"));
		bed.Manager.DockPanel(a, .Center);
		bed.Manager.DockPanelRelativeTo(b, .Right, a.Parent);
		bed.SettleLayout();

		DockablePanel activated = null;
		bed.Manager.OnPanelActivated.Add(new [&activated](panel) => { activated = panel; });

		PressInside(bed, a);
		Test.Assert(activated == a);
		PressInside(bed, b);
		Test.Assert(activated == b);
		PressInside(bed, a);
		Test.Assert(activated == a, "and again, which a tab click could not do");
	}

	/// Seven tenths down, which is inside the CONTENT rather than on the tab strip.
	private static void PressInside(DockBed bed, DockablePanel panel)
	{
		let screen = panel.LocalToScreen(.(panel.Width * 0.5f, panel.Height * 0.7f));
		bed.Context.GetInputManager().ProcessMouseDown(.Left, screen.X, screen.Y, 0.0f);
		bed.Context.GetInputManager().ProcessMouseUp(.Left, screen.X, screen.Y);
	}

	/// The veto applies to the USER's close gesture and not to a programmatic one, which is what
	/// lets a dirty page prompt and then close itself from the prompt's own buttons.
	[Test]
	public static void TheCloseInterceptorVetoesGesturesButNotDirectCloses()
	{
		let panel = new DockablePanel("Doc");
		defer panel.ReleaseRef();

		var closed = 0;
		panel.OnCloseRequested.Add(new [&closed](p) => { closed++; });

		var allow = false;
		var asked = 0;
		panel.OnCloseInterceptor = new [&allow, &asked](p) =>
			{
				asked++;
				return allow;
			};

		panel.RequestClose();
		Test.Assert(asked == 1);
		Test.Assert(closed == 0, "vetoed");

		allow = true;
		panel.RequestClose();
		Test.Assert(asked == 2);
		Test.Assert(closed == 1);

		allow = false;
		panel.OnCloseRequested(panel);
		Test.Assert(asked == 2, "a direct close never asks");
		Test.Assert(closed == 2);
	}

	/// The host's chrome policy reaches the window and flips three things at once: whether the
	/// panel draws its own close cross, whether a re-dock drag shows a chip, and whether the
	/// inner resize edges exist.
	[Test]
	public static void AFloatedWindowInheritsTheHostsChromePolicy()
	{
		for (let chrome in bool[](true, false))
		{
			let bed = scope DockBed();
			let host = scope FakeWindowHost();
			host.Chrome = chrome;
			bed.Manager.DockableWindowHost = host;

			let panel = bed.Manager.AddPanel("Scene", new Label("C"));
			bed.Manager.FloatPanel(panel, 10, 10);

			Test.Assert(host.Created.Count == 1);
			let window = host.Created[0] as DockableWindow;
			Test.Assert(window != null);
			Test.Assert(window.IsOSWindow);
			Test.Assert(window.HasOSChrome == chrome);
			Test.Assert(panel.InChromedOSWindow() == chrome);

			// Chromed, the window stays put and the chip is what flies; borderless, the window
			// itself follows and a chip as well would be two things in flight.
			let visual = panel.CreateDragVisual(null);
			Test.Assert((visual != null) == chrome);
			if (visual != null)
				visual.ReleaseRef();

			window.Measure(BoxConstraints.Tight(300, 250));
			window.Layout(0, 0, 300, 250);
			let edgeHit = window.HitTest(.(2, 125));
			if (chrome)
				Test.Assert(edgeHit != window, "the system's border resizes, not an inner band");
			else
				Test.Assert(edgeHit == window);
		}
	}

	/// The system's own close button routes through the panel's RequestClose, so the veto
	/// applies there exactly as it does to the drawn cross.
	[Test]
	public static void AnOSCloseRequestRespectsTheInterceptor()
	{
		let bed = scope DockBed();
		let host = scope FakeWindowHost();
		host.Chrome = true;
		bed.Manager.DockableWindowHost = host;

		let panel = bed.Manager.AddPanel("Doc", new Label("C"));
		panel.SetPersistenceId("doc");

		var allow = false;
		var asked = 0;
		panel.OnCloseInterceptor = new [&allow, &asked](p) =>
			{
				asked++;
				return allow;
			};

		bed.Manager.FloatPanel(panel, 10, 10);
		Test.Assert(host.LastOnClose != null);

		host.LastOnClose(host.Created[0]);
		Test.Assert(asked == 1);
		Test.Assert(host.Destroyed == 0, "vetoed, so the window survives");
		Test.Assert(bed.Manager.FindPanelById("doc") == panel);

		allow = true;
		host.LastOnClose(host.Created[0]);
		Test.Assert(asked == 2);
		Test.Assert(host.Destroyed == 1);
		Test.Assert(bed.Manager.FindPanelById("doc") == null);
	}
}
