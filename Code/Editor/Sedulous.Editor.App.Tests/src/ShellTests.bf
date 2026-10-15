using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App.Tests;

/// EditorShell and dock-layout persistence, headless: views build and lay out without a
/// window. Chrome construction (bars, dock, the persistence-id'd panels), status routing,
/// and the save, restore, same-layout round trip through the XML file in a project's
/// Editor directory.
static class ShellTests
{
	private static void ScratchDir(StringView name, String outDir)
	{
		GetCurrentDirectory(outDir);
		PathJoin(outDir, name, outDir);
		RemoveDirectoryRecursive(outDir);
		CreateDirectory(outDir);
	}

	[Test]
	public static void BuildsTheChromeWithTheGlobalPanelsOnly()
	{
		let ctx = scope EditorContext();
		let shell = scope EditorShell();
		shell.Build(ctx, null, 1280, 720);

		Test.Assert(shell.Root != null);
		Test.Assert(shell.Menus != null);
		Test.Assert(shell.StatusBar != null);
		Test.Assert(shell.Docks != null);

		// The global panels are Assets and Console plus the Project panel holding the centre;
		// scene-scoped views live inside pages, never in the shell. The Project panel keeps the
		// id it had as the Welcome panel, so saved layouts still place it.
		Test.Assert(shell.ProjectPanel != null);
		Test.Assert(shell.ProjectPanel.Title == "Project");
		Test.Assert(shell.ProjectPanel.PersistenceId == "welcome");
		Test.Assert(shell.ConsolePanel.PersistenceId == "console");
		Test.Assert(shell.AssetsPanel.PersistenceId == "assets");
		Test.Assert(shell.ProfilerTab != null);
		Test.Assert(shell.ProfilerTab.PersistenceId == "profiler");
		Test.Assert(shell.ProfilerTab.Title == "Profiler");
		Test.Assert(shell.Profiler != null);
		Test.Assert(!shell.Profiler.IsRecording, "off until Record");
		Test.Assert(shell.Docks.FindPanelById("assets") === shell.AssetsPanel);
		Test.Assert(shell.Docks.FindPanelById("viewport") == null, "no global viewport panel");

		// Status text routes through the context to the status bar.
		ctx.SetStatus("hello");
	}

	/// What a first user sees: most of the window is the document, and the pane below shows
	/// the asset browser and the log at once rather than one behind the other.
	[Test]
	public static void TheDefaultLayoutPutsAssetsBesideTheConsoleUnderTheDocument()
	{
		let ctx = scope EditorContext();
		let shell = scope EditorShell();
		shell.Build(ctx, null, 1280, 720);

		let root = shell.Docks.RootNode as DockSplit;
		Test.Assert(root != null);
		Test.Assert(root.Orientation == .Vertical);
		Test.Assert(Math.Abs(root.SplitRatio - 0.7f) < 0.0001f); // the first, top child's share

		// Assets and the Console sit in their OWN tab groups, side by side in one split.
		let assetsGroup = shell.AssetsPanel.Parent as DockTabGroup;
		let consoleGroup = shell.ConsolePanel.Parent as DockTabGroup;
		Test.Assert((assetsGroup != null) && (consoleGroup != null));
		Test.Assert(assetsGroup !== consoleGroup);
		Test.Assert(assetsGroup.PanelCount == 1);
		// The Console's group holds the Profiler tab too, the Console in front.
		Test.Assert(consoleGroup.PanelCount == 2);
		Test.Assert(consoleGroup.GetPanel(0) === shell.ConsolePanel);
		Test.Assert(consoleGroup.GetPanel(1) === shell.ProfilerTab);
		Test.Assert(consoleGroup.SelectedIndex == 0);

		let pane = assetsGroup.Parent as DockSplit;
		Test.Assert(pane != null);
		Test.Assert(pane === consoleGroup.Parent);
		Test.Assert(pane.Orientation == .Horizontal);
		Test.Assert(pane.First === assetsGroup); // Assets left
		Test.Assert(pane.Second === consoleGroup); // the Console right
		Test.Assert(Math.Abs(pane.SplitRatio - 0.65f) < 0.0001f);
		Test.Assert(root.Second === pane); // the pane is the root split's bottom child
	}

	[Test]
	public static void PagePanelsDockIntoTheCentreDocumentAreaAsClosableTabs()
	{
		let ctx = scope EditorContext();
		let shell = scope EditorShell();
		shell.Build(ctx, null, 1280, 720);

		let page = shell.AddPagePanel("Scene 1", new Label("scene content"));
		Test.Assert(page != null);
		Test.Assert(page.Closable);

		// The page tabs with the Project panel in the centre group.
		Test.Assert(page.Parent === shell.ProjectPanel.Parent);
	}

	private static bool SameNodes(DockLayoutNode a, DockLayoutNode b)
	{
		if ((a == null) != (b == null))
			return false;
		if (a == null)
			return true;
		if (a.Type != b.Type)
			return false;
		if (a.Type == .TabGroup)
		{
			if (a.PanelIds.Count != b.PanelIds.Count)
				return false;
			for (int i < a.PanelIds.Count)
			{
				if (a.PanelIds[i] != b.PanelIds[i])
					return false;
			}
			return true;
		}
		return (a.Direction == b.Direction) && SameNodes(a.First, b.First) && SameNodes(a.Second, b.Second);
	}

	[Test]
	public static void DockLayoutSurvivesASaveRestoreRoundTrip()
	{
		let dir = ScratchDir("scratch_editor_test_layout", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		let ctx = scope EditorContext();
		let shell = scope EditorShell();
		shell.Build(ctx, null, 1280, 720);

		// Capture the default arrangement into the per-project store, persist it, and load
		// it back through the same file the app writes.
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();
		let before = shell.Docks.ExportLayout();
		defer delete before;
		Test.Assert(before != null);
		let store = scope Settings();
		Test.Assert(shell.SaveLayout(store) case .Ok);
		Test.Assert(ProjectEditorSettings.Save(store, dir) case .Ok);
		Test.Assert(FileExists(PathJoin(dir, ProjectEditorSettings.cFileName, .. scope .())));

		// Rearrange by undocking a panel, then restore from a freshly loaded store: the
		// exported tree matches the saved one again.
		shell.Docks.UndockPanel(shell.AssetsPanel);
		Test.Assert(shell.Docks.FindPanelById("assets") != null, "still registered while undocked");
		let loaded = scope Settings();
		Test.Assert(ProjectEditorSettings.Load(loaded, dir) case .Ok);
		Test.Assert(shell.RestoreLayout(loaded) case .Ok);
		let after = shell.Docks.ExportLayout();
		defer delete after;
		Test.Assert(after != null);

		// Structural comparison: same node types, same panel ids in the same tab order.
		Test.Assert(SameNodes(before, after));
	}

	[Test]
	public static void RestoreFromAMissingFileReportsNotFound()
	{
		let dir = ScratchDir("scratch_editor_test_layout_missing", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		let ctx = scope EditorContext();
		let shell = scope EditorShell();
		shell.Build(ctx, null, 640, 480);
		// A store with no captured snapshot and a directory with no store file: both NotFound.
		let store = scope Settings();
		Test.Assert(shell.RestoreLayout(store) case .Err(.NotFound));
		Test.Assert(ProjectEditorSettings.Load(store, dir) case .Err(.NotFound));
	}

	[Test]
	public static void TheAssetBrowserViewModeRoundTripsThroughTheStore()
	{
		let dir = ScratchDir("scratch_editor_test_assetview", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();

		// The default is list; a fresh store reads the default.
		{
			let store = scope Settings();
			Test.Assert(!store.Section<EditorAssetBrowserSettings>().GridMode);
		}

		// Toggle to grid, persist, and load back through the same file the app writes.
		{
			let store = scope Settings();
			store.Section<EditorAssetBrowserSettings>().GridMode = true;
			store.MarkChanged<EditorAssetBrowserSettings>();
			Test.Assert(ProjectEditorSettings.Save(store, dir) case .Ok);
		}
		{
			let loaded = scope Settings();
			Test.Assert(ProjectEditorSettings.Load(loaded, dir) case .Ok);
			let section = loaded.Find<EditorAssetBrowserSettings>();
			Test.Assert(section != null);
			Test.Assert(section.GridMode, "the grid choice survived save and reload");
		}
	}

	[Test]
	public static void LayoutNodeRoundTripsNestedSplitsThroughXml()
	{
		// A hand-built split tree, [A | (B tabbed C)] over D: nesting, ratios, tab order.
		let root = scope DockLayoutNode();
		root.Type = .Split;
		root.Direction = .Vertical;
		root.SplitRatio = 0.75f;
		root.First = new DockLayoutNode();
		root.First.Type = .Split;
		root.First.Direction = .Horizontal;
		root.First.SplitRatio = 0.25f;
		root.First.First = new DockLayoutNode();
		root.First.First.PanelIds.Add(new String("a"));
		root.First.Second = new DockLayoutNode();
		root.First.Second.PanelIds.Add(new String("b"));
		root.First.Second.PanelIds.Add(new String("c"));
		root.First.Second.ActiveTabIndex = 1;
		root.Second = new DockLayoutNode();
		root.Second.PanelIds.Add(new String("d"));

		// Written to XML text, read back.
		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		{
			let ctx = factory(buffer, .Write);
			defer delete ctx;
			Test.Assert(ctx.Serializer != null);
			DockLayoutNodeSerialization.SerializeLayoutNode(ctx.Serializer, root);
			Test.Assert(ctx.Serializer.IsOk);
			ctx.Flush(buffer);
		}

		let loaded = scope DockLayoutNode();
		{
			buffer.Seek(0, .Begin);
			let ctx = factory(buffer, .Read);
			defer delete ctx;
			Test.Assert(ctx.Serializer != null);
			DockLayoutNodeSerialization.SerializeLayoutNode(ctx.Serializer, loaded);
			Test.Assert(ctx.Serializer.IsOk);
		}

		Test.Assert(loaded.Type == .Split);
		Test.Assert(loaded.Direction == .Vertical);
		Test.Assert(Math.Abs(loaded.SplitRatio - 0.75f) < 1e-5f);
		Test.Assert(loaded.First != null);
		Test.Assert(loaded.Second != null);
		Test.Assert(Math.Abs(loaded.First.SplitRatio - 0.25f) < 1e-5f);
		Test.Assert(loaded.First.Second != null);
		Test.Assert(loaded.First.Second.PanelIds.Count == 2);
		Test.Assert(loaded.First.Second.PanelIds[0] == "b");
		Test.Assert(loaded.First.Second.PanelIds[1] == "c");
		Test.Assert(loaded.First.Second.ActiveTabIndex == 1);
		Test.Assert(loaded.Second.PanelIds.Count == 1);
		Test.Assert(loaded.Second.PanelIds[0] == "d");
	}

	private static bool Places(DockLayoutNode node, StringView id)
	{
		if (node == null)
			return false;
		for (let panel in node.PanelIds)
		{
			if (panel == id)
				return true;
		}
		return Places(node.First, id) || Places(node.Second, id);
	}

	/// A layout saved before the Profiler tab existed puts it with the Console rather than
	/// floating it; View > Profiler brings it forward, and docks it again once closed.
	[Test]
	public static void ALayoutSavedBeforeTheProfilerTabPutsItWithTheConsole()
	{
		let ctx = scope EditorContext();
		let shell = scope EditorShell();
		shell.Build(ctx, null, 1280, 720);
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();

		// A saved layout that does not name the Profiler: take it out of the tree, then save.
		shell.Docks.UndockPanel(shell.ProfilerTab);
		let store = scope Settings();
		Test.Assert(shell.SaveLayout(store) case .Ok);
		Test.Assert(!Places(store.Find<EditorDockLayoutSettings>().Root, "profiler"));

		Test.Assert(shell.RestoreLayout(store) case .Ok);
		Test.Assert(shell.ProfilerTab.Parent === shell.ConsolePanel.Parent, "docked with it");
		let group = shell.ConsolePanel.Parent as DockTabGroup;
		Test.Assert(group != null);
		Test.Assert(group.GetPanel(group.SelectedIndex) === shell.ConsolePanel);

		// View > Profiler brings it forward.
		shell.ShowProfiler();
		Test.Assert(group.GetPanel(group.SelectedIndex) === shell.ProfilerTab);

		// Closed (its close button), a tool panel hides, it is not destroyed, and the recording
		// stops; View > Profiler docks it with the Console again.
		shell.Profiler.Start();
		Test.Assert(shell.Profiler.IsRecording);
		shell.ProfilerTab.RequestClose();
		Test.Assert(!shell.Profiler.IsRecording);
		Test.Assert(shell.Docks.FindPanelById("profiler") === shell.ProfilerTab);
		Test.Assert(shell.ProfilerTab.Parent == null);
		shell.ShowProfiler();
		Test.Assert(shell.ProfilerTab.Parent === shell.ConsolePanel.Parent);
		let again = shell.ProfilerTab.Parent as DockTabGroup;
		Test.Assert(again != null);
		Test.Assert(again.GetPanel(again.SelectedIndex) === shell.ProfilerTab);
	}
}
