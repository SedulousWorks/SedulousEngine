using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// Saving a dock layout and getting it back.
///
/// A layout names panels by their PERSISTENCE ID, not by pointer, which is the whole reason it
/// can outlive the session that wrote it. These check both directions and the round trip, and
/// what happens when a saved layout no longer matches the panels that exist.
class DockPersistenceTests
{
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
		}

		public ~this()
		{
			Root.ReleaseRef();
			delete Context;
		}

		/// Registers a panel and gives it an id, which is the pair everything here needs.
		public DockablePanel Panel(StringView title, StringView persistenceId)
		{
			let panel = Manager.AddPanel(title, new Label(title));
			panel.SetPersistenceId(persistenceId);
			return panel;
		}
	}

	/// How many panels a saved layout mentions, wherever they sit in it.
	private static int CountPanels(DockLayoutNode node)
	{
		if (node == null)
			return 0;

		if (node.Type == .TabGroup)
			return node.PanelIds.Count;

		return CountPanels(node.First) + CountPanels(node.Second);
	}

	// ---- The id ---------------------------------------------------------------------------------

	[Test]
	public static void APersistenceIdStartsEmptyAndRoundTrips()
	{
		let panel = new DockablePanel("Assets");
		defer panel.ReleaseRef();

		Test.Assert(panel.PersistenceId.IsEmpty);
		panel.SetPersistenceId("assets");
		Test.Assert(panel.PersistenceId == "assets");
	}

	[Test]
	public static void PanelsAreFoundByTheirId()
	{
		let bed = scope DockBed();

		let assets = bed.Panel("Assets", "assets");
		let console = bed.Panel("Console", "console");

		Test.Assert(bed.Manager.FindPanelById("assets") == assets);
		Test.Assert(bed.Manager.FindPanelById("console") == console);
		Test.Assert(bed.Manager.FindPanelById("nope") == null);
	}

	// ---- Exporting ------------------------------------------------------------------------------

	[Test]
	public static void AnEmptyTreeExportsNothing()
	{
		let bed = scope DockBed();
		Test.Assert(bed.Manager.ExportLayout() == null);
	}

	[Test]
	public static void OnePanelExportsAsAOneTabGroup()
	{
		let bed = scope DockBed();

		let panel = bed.Panel("Assets", "assets");
		bed.Manager.DockPanel(panel, .Center);

		let layout = bed.Manager.ExportLayout();
		defer delete layout;

		Test.Assert(layout != null);
		Test.Assert(layout.Type == .TabGroup);
		Test.Assert(layout.PanelIds.Count == 1);
		Test.Assert(layout.PanelIds[0] == "assets");
		Test.Assert(layout.ActiveTabIndex == 0);
	}

	[Test]
	public static void TabsExportInTabOrder()
	{
		let bed = scope DockBed();

		let assets = bed.Panel("Assets", "assets");
		let console = bed.Panel("Console", "console");
		bed.Manager.DockPanel(assets, .Center);
		bed.Manager.DockPanelRelativeTo(console, .Center, assets.Parent);

		let layout = bed.Manager.ExportLayout();
		defer delete layout;

		Test.Assert(layout.Type == .TabGroup);
		Test.Assert(layout.PanelIds.Count == 2);
		Test.Assert(layout.PanelIds[0] == "assets");
		Test.Assert(layout.PanelIds[1] == "console");
	}

	[Test]
	public static void ASplitExportsItsDirectionAndRatio()
	{
		let bed = scope DockBed();

		let left = bed.Panel("Left", "left");
		let right = bed.Panel("Right", "right");
		bed.Manager.DockPanel(left, .Center);
		bed.Manager.DockPanel(right, .Right);

		if (let split = bed.Manager.RootNode as DockSplit)
			split.SplitRatio = 0.35f;

		let layout = bed.Manager.ExportLayout();
		defer delete layout;

		Test.Assert(layout.Type == .Split);
		Test.Assert(layout.Direction == .Horizontal);
		Test.Assert(Abs(layout.SplitRatio - 0.35f) < 0.01f);
		Test.Assert(CountPanels(layout) == 2);
	}

	[Test]
	public static void ANestedSplitExportsEveryPanel()
	{
		let bed = scope DockBed();

		let editor = bed.Panel("Editor", "editor");
		let assets = bed.Panel("Assets", "assets");
		let inspector = bed.Panel("Inspector", "inspector");

		bed.Manager.DockPanel(editor, .Center);
		bed.Manager.DockPanel(assets, .Bottom);
		bed.Manager.DockPanel(inspector, .Right);

		let layout = bed.Manager.ExportLayout();
		defer delete layout;

		Test.Assert(layout.Type == .Split);
		Test.Assert(CountPanels(layout) == 3);
	}

	/// A panel with NO id cannot be restored, so recording it would produce a layout that
	/// silently loses a tab on load.
	[Test]
	public static void APanelWithNoIdIsLeftOutOfTheLayout()
	{
		let bed = scope DockBed();

		let named = bed.Panel("Assets", "assets");
		let unnamed = bed.Manager.AddPanel("Scratch", new Label("S"));

		bed.Manager.DockPanel(named, .Center);
		bed.Manager.DockPanelRelativeTo(unnamed, .Center, named.Parent);

		let layout = bed.Manager.ExportLayout();
		defer delete layout;

		Test.Assert(layout.PanelIds.Count == 1);
		Test.Assert(layout.PanelIds[0] == "assets");
	}

	// ---- Applying -------------------------------------------------------------------------------

	[Test]
	public static void ApplyingALayoutDocksTheNamedPanel()
	{
		let bed = scope DockBed();
		bed.Panel("Assets", "assets");

		let layout = scope DockLayoutNode();
		layout.Type = .TabGroup;
		layout.PanelIds.Add(new String("assets"));

		bed.Manager.ApplyLayout(layout);

		let group = bed.Manager.RootNode as DockTabGroup;
		Test.Assert(group != null);
		Test.Assert(group.PanelCount == 1);
	}

	[Test]
	public static void ApplyingASplitBuildsOne()
	{
		let bed = scope DockBed();
		bed.Panel("Left", "left");
		bed.Panel("Right", "right");

		let layout = scope DockLayoutNode();
		layout.Type = .Split;
		layout.Direction = .Horizontal;
		layout.SplitRatio = 0.4f;

		layout.First = new DockLayoutNode();
		layout.First.Type = .TabGroup;
		layout.First.PanelIds.Add(new String("left"));

		layout.Second = new DockLayoutNode();
		layout.Second.Type = .TabGroup;
		layout.Second.PanelIds.Add(new String("right"));

		bed.Manager.ApplyLayout(layout);

		let split = bed.Manager.RootNode as DockSplit;
		Test.Assert(split != null);
		Test.Assert(Abs(split.SplitRatio - 0.4f) < 0.01f);
	}

	/// An id the session does not have is SKIPPED rather than fatal, which is what lets a saved
	/// layout survive a panel being renamed or removed between versions.
	[Test]
	public static void AnUnknownIdIsSkipped()
	{
		let bed = scope DockBed();
		bed.Panel("Assets", "assets");

		let layout = scope DockLayoutNode();
		layout.Type = .TabGroup;
		layout.PanelIds.Add(new String("nonexistent"));
		layout.PanelIds.Add(new String("assets"));

		bed.Manager.ApplyLayout(layout);

		let group = bed.Manager.RootNode as DockTabGroup;
		Test.Assert(group != null);
		Test.Assert(group.PanelCount == 1);
	}

	/// A split whose other side ends up empty COLLAPSES to the side that survived, rather than
	/// leaving half the window blank.
	[Test]
	public static void ASplitWithAnEmptyBranchCollapses()
	{
		let bed = scope DockBed();
		bed.Panel("Only", "only");

		let layout = scope DockLayoutNode();
		layout.Type = .Split;
		layout.Direction = .Horizontal;
		layout.SplitRatio = 0.5f;

		layout.First = new DockLayoutNode();
		layout.First.Type = .TabGroup;
		layout.First.PanelIds.Add(new String("only"));

		layout.Second = new DockLayoutNode();
		layout.Second.Type = .TabGroup;
		layout.Second.PanelIds.Add(new String("gone"));

		bed.Manager.ApplyLayout(layout);

		Test.Assert(bed.Manager.RootNode is DockTabGroup);
	}

	// ---- The round trip -------------------------------------------------------------------------

	[Test]
	public static void OnePanelSurvivesTheRoundTrip()
	{
		let bed = scope DockBed();

		let panel = bed.Panel("Assets", "assets");
		bed.Manager.DockPanel(panel, .Center);

		let layout = bed.Manager.ExportLayout();
		defer delete layout;
		bed.Manager.ApplyLayout(layout);

		let again = bed.Manager.ExportLayout();
		defer delete again;

		Test.Assert(again != null);
		Test.Assert(again.Type == .TabGroup);
		Test.Assert(again.PanelIds.Count == 1);
		Test.Assert(again.PanelIds[0] == "assets");
	}

	[Test]
	public static void AComplexLayoutKeepsEveryPanel()
	{
		let bed = scope DockBed();

		let editor = bed.Panel("Editor", "editor");
		let assets = bed.Panel("Assets", "assets");
		let console = bed.Panel("Console", "console");
		let inspector = bed.Panel("Inspector", "inspector");

		bed.Manager.DockPanel(editor, .Center);
		bed.Manager.DockPanel(assets, .Bottom);
		bed.Manager.DockPanelRelativeTo(console, .Center, assets.Parent);
		bed.Manager.DockPanel(inspector, .Right);

		let layout = bed.Manager.ExportLayout();
		defer delete layout;
		let originalCount = CountPanels(layout);
		Test.Assert(originalCount == 4);

		bed.Manager.ApplyLayout(layout);

		let again = bed.Manager.ExportLayout();
		defer delete again;
		Test.Assert(again != null);
		Test.Assert(CountPanels(again) == originalCount);
	}

	[Test]
	public static void TheSplitRatioSurvivesTheRoundTrip()
	{
		let bed = scope DockBed();

		let left = bed.Panel("Left", "left");
		let right = bed.Panel("Right", "right");
		bed.Manager.DockPanel(left, .Center);
		bed.Manager.DockPanel(right, .Right);

		if (let split = bed.Manager.RootNode as DockSplit)
			split.SplitRatio = 0.35f;

		let layout = bed.Manager.ExportLayout();
		defer delete layout;
		bed.Manager.ApplyLayout(layout);

		let again = bed.Manager.ExportLayout();
		defer delete again;

		Test.Assert(again.Type == .Split);
		Test.Assert(Abs(again.SplitRatio - 0.35f) < 0.01f);
	}

	/// Which tab was in FRONT is part of the layout: restoring a workspace onto a different tab
	/// than the one left open is a small thing that reads as the tool losing its place.
	[Test]
	public static void TheActiveTabSurvivesTheRoundTrip()
	{
		let bed = scope DockBed();

		let assets = bed.Panel("Assets", "assets");
		let console = bed.Panel("Console", "console");
		bed.Manager.DockPanel(assets, .Center);
		bed.Manager.DockPanelRelativeTo(console, .Center, assets.Parent);

		if (let group = bed.Manager.RootNode as DockTabGroup)
			group.SetSelectedIndex(1);

		let layout = bed.Manager.ExportLayout();
		defer delete layout;
		Test.Assert(layout.ActiveTabIndex == 1);

		bed.Manager.ApplyLayout(layout);

		let group = bed.Manager.RootNode as DockTabGroup;
		Test.Assert(group != null);
		Test.Assert(group.SelectedIndex == 1);
	}
}
