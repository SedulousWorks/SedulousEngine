using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The per-project store: the dock's layout through the file and back into a dock with the same
/// panels in the same places; with none captured the dock keeps its default; a capture is a copy,
/// adopted into a dock with a panel the layout names unregistered, which keeps its place; a layout
/// the dock refuses leaves it as it was; the old dock's tree (section version 1) reads into the new
/// layout (its splits each splitting their own region at their shares, its groups' tabs in order
/// with their chosen ones, a panel named twice placed once), read through to its end, the
/// open pages kept, and saves again as version 2.
class LayoutStoreTests
{
	private const String cSectionName = "Sedulous.Editor.App.EditorDockLayoutSettings";

	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
		CreateDirectory(outPath);
	}

	private static void Register(DockController dock, StringView id)
	{
		let description = new DockPanelDescription();
		description.Id.Set(id);
		description.Title.Set(id);
		Test.Assert(dock.Register(description));
	}

	/// The assets in the central stack, the console in a stack of its own below it: an
	/// arrangement no panel's default makes (a default goes along the main surface's end).
	private static void Arrange(DockController dock)
	{
		let layout = scope DockLayout();
		Test.Assert(layout.InsertTab("assets", layout.CentralStack).Ok);
		Test.Assert(layout.InsertBeside("console", layout.StackOf("assets"), .Bottom, 0.3f).Ok);
		Test.Assert(dock.Adopt(layout).Ok);
	}

	/// A layout as its document writes it, to compare two whole.
	private static void LayoutText(DockLayout layout, String outText)
	{
		let document = scope DockLayoutDocument();
		document.Layout.Set(layout);
		let writer = scope XmlSerializer();
		document.Serialize(writer);
		Test.Assert(writer.IsOk);
		writer.GetOutput(outText);
	}

	private static void ReadText(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(path, bytes) case .Ok);
		outText.Append((char8*)bytes.Ptr, bytes.Count);
	}

	[Test]
	public static void TheDocksLayoutThroughTheFileAndBack()
	{
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();
		let dir = Scratch("scratch_layout_store", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		let dock = scope DockController();
		Register(dock, "assets");
		Register(dock, "console");
		Arrange(dock);

		let store = scope Settings();
		Test.Assert(ProjectEditorSettings.ApplyDockLayout(dock, store) case .Err(.NotFound)); // none captured: the default stands
		ProjectEditorSettings.CaptureDockLayout(dock, store);
		Test.Assert(ProjectEditorSettings.Save(store, dir) case .Ok);

		let loaded = scope Settings();
		Test.Assert(ProjectEditorSettings.Load(loaded, dir) case .Ok);
		let section = loaded.Find<EditorDockLayoutSettings>();
		Test.Assert(section != null);
		Test.Assert(section.Captured);

		let restored = scope DockController();
		Register(restored, "assets");
		Register(restored, "console");
		Test.Assert(ProjectEditorSettings.ApplyDockLayout(restored, loaded) case .Ok);
		let l = restored.Layout;
		Test.Assert(l.StackOf("assets") == l.CentralStack);
		Test.Assert(l.StackOf("console") != cNoDock);
		Test.Assert(l.StackOf("console") != l.StackOf("assets"));
		// The same panels in the same places, nothing lost on the way.
		let saved = LayoutText(dock.Layout, .. scope .());
		Test.Assert(LayoutText(l, .. scope .()) == saved);
	}

	[Test]
	public static void ACaptureIsACopyAdoptedIntoAnotherDock()
	{
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();
		let dock = scope DockController();
		Register(dock, "assets");
		Register(dock, "console");
		Arrange(dock);
		let captured = LayoutText(dock.Layout, .. scope .());

		let store = scope Settings();
		var changed = 0;
		let seen = scope String();
		store.OnChanged.Add(new [&changed, &seen] (name) => { seen.Set(name); changed++; });
		defer store.OnChanged.Dispose();
		ProjectEditorSettings.CaptureDockLayout(dock, store);
		Test.Assert(changed == 1); // the store told, so the session saves it
		Test.Assert(seen == cSectionName);

		// The dock changes on; the store keeps what it was given.
		Test.Assert(dock.Close("console").Ok);
		Test.Assert(dock.Layout.StackOf("console") == cNoDock);
		Test.Assert(LayoutText(store.Find<EditorDockLayoutSettings>().Document.Layout, .. scope .()) == captured);

		// Adopted back: the console where it was.
		Test.Assert(ProjectEditorSettings.ApplyDockLayout(dock, store) case .Ok);
		Test.Assert(LayoutText(dock.Layout, .. scope .()) == captured);

		// Into a dock that has only the assets: the console, not registered, keeps its place.
		let other = scope DockController();
		Register(other, "assets");
		Test.Assert(ProjectEditorSettings.ApplyDockLayout(other, store) case .Ok);
		Test.Assert(other.Layout.StackOf("assets") == other.Layout.CentralStack);
		Test.Assert(other.Layout.StackOf("console") != cNoDock);
		Test.Assert(LayoutText(other.Layout, .. scope .()) == captured);
	}

	[Test]
	public static void ALayoutTheDockRefusesLeavesItAsItWas()
	{
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();
		let dock = scope DockController();
		Register(dock, "assets");
		Register(dock, "console");
		Arrange(dock);
		let store = scope Settings();
		ProjectEditorSettings.CaptureDockLayout(dock, store);

		// The console docked twice, as a file edited by hand might have it.
		let read = store.Find<EditorDockLayoutSettings>().Document.Layout;
		read.FindNode(read.CentralStack).Panels.Add(new String("console"));
		Test.Assert(dock.Close("console").Ok);
		let before = LayoutText(dock.Layout, .. scope .());

		Test.Assert(ProjectEditorSettings.ApplyDockLayout(dock, store) case .Err(.InvalidArgument));
		Test.Assert(LayoutText(dock.Layout, .. scope .()) == before); // unchanged
	}

	/// The store as the old dock wrote it (a sample project's, cut down): its open pages, then
	/// its dock tree, a split (type 0) one over the other (direction 1, Sedulous.UI's
	/// Orientation.Vertical) of the welcome page (70%) and a split side by side (0, Horizontal) of
	/// the assets (65%) and the console, each a tab group (type 1).
	private const String cVersionOneStore = """
		<root>
			<array name="sections" count="2">
				<object>
					<string name="typeName">Sedulous.Editor.App.EditorOpenPagesSettings</string>
					<object name="payload">
						<array name="dataVersions" count="1">
							<u64 name="type">1402274261608347619</u64>
							<u32 name="version">1</u32>
						</array>
						<object>
							<array name="pages" count="1">
								<string>7914f166-d579-454d-95d8-aba44565f196</string>
							</array>
							<string name="active">7914f166-d579-454d-95d8-aba44565f196</string>
						</object>
					</object>
				</object>
				<object>
					<string name="typeName">Sedulous.Editor.App.EditorDockLayoutSettings</string>
					<object name="payload">
						<array name="dataVersions" count="1">
							<u64 name="type">3264330293309156222</u64>
							<u32 name="version">1</u32>
						</array>
						<object>
							<bool name="hasRoot">true</bool>
							<object name="root">
								<u8 name="type">0</u8>
								<u8 name="direction">1</u8>
								<f32 name="ratio">0.7</f32>
								<i32 name="activeTab">0</i32>
								<array name="panels" count="0"/>
								<bool name="hasFirst">true</bool>
								<bool name="hasSecond">true</bool>
								<object name="first">
									<u8 name="type">1</u8>
									<u8 name="direction">0</u8>
									<f32 name="ratio">0.5</f32>
									<i32 name="activeTab">0</i32>
									<array name="panels" count="1">
										<string>welcome</string>
									</array>
									<bool name="hasFirst">false</bool>
									<bool name="hasSecond">false</bool>
								</object>
								<object name="second">
									<u8 name="type">0</u8>
									<u8 name="direction">0</u8>
									<f32 name="ratio">0.65</f32>
									<i32 name="activeTab">0</i32>
									<array name="panels" count="0"/>
									<bool name="hasFirst">true</bool>
									<bool name="hasSecond">true</bool>
									<object name="first">
										<u8 name="type">1</u8>
										<u8 name="direction">0</u8>
										<f32 name="ratio">0.5</f32>
										<i32 name="activeTab">0</i32>
										<array name="panels" count="1">
											<string>assets</string>
										</array>
										<bool name="hasFirst">false</bool>
										<bool name="hasSecond">false</bool>
									</object>
									<object name="second">
										<u8 name="type">1</u8>
										<u8 name="direction">0</u8>
										<f32 name="ratio">0.5</f32>
										<i32 name="activeTab">0</i32>
										<array name="panels" count="1">
											<string>console</string>
										</array>
										<bool name="hasFirst">false</bool>
										<bool name="hasSecond">false</bool>
									</object>
								</object>
							</object>
						</object>
					</object>
				</object>
			</array>
		</root>
		""";

	/// The split holding `node` in `layout`; null for a surface's root.
	private static DockNode ParentOf(DockLayout layout, DockNodeId node)
	{
		let found = layout.FindNode(node);
		return (found != null) ? layout.FindNode(found.Parent) : null;
	}

	/// The first child's share of a split of two.
	private static float FirstShare(DockNode split)
	{
		Test.Assert(split.Weights.Count == 2);
		return split.Weights[0] / (split.Weights[0] + split.Weights[1]);
	}

	private static bool Near(float a, float b) => Math.Abs(a - b) < 0.01f;

	/// The panels of `stack` are `expected`, in tab order.
	private static bool TabsAre(DockLayout layout, DockNodeId stack, params StringView[] expected)
	{
		let node = layout.FindNode(stack);
		if ((node == null) || (node.Panels.Count != expected.Count))
			return false;
		for (int i < expected.Count)
		{
			if (node.Panels[i] != expected[i])
				return false;
		}
		return true;
	}

	[Test]
	public static void TheOldDocksTreeReadsIntoTheNewLayout()
	{
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();
		let dir = Scratch("scratch_layout_store_v1", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let path = PathJoin(dir, ProjectEditorSettings.cFileName, .. scope .());
		Test.Assert(WriteFile(path, .((uint8*)cVersionOneStore.Ptr, cVersionOneStore.Length)) case .Ok);

		let loaded = scope Settings();
		Test.Assert(ProjectEditorSettings.Load(loaded, dir) case .Ok); // the store reads whole
		let section = loaded.Find<EditorDockLayoutSettings>();
		Test.Assert(section != null);
		Test.Assert(section.Captured);
		// The open pages still reopen.
		let pages = scope List<Guid>();
		let reopened = ProjectEditorSettings.ApplyOpenPages(loaded, pages, let active);
		Test.Assert(reopened case .Ok);
		Test.Assert(pages.Count == 1);
		Test.Assert(active != .Empty);
		Test.Assert(active == pages[0]);

		// Into a dock arranged otherwise: the old tree's places.
		let dock = scope DockController();
		Register(dock, "welcome");
		Register(dock, "assets");
		Register(dock, "console");
		Arrange(dock);
		Test.Assert(ProjectEditorSettings.ApplyDockLayout(dock, loaded) case .Ok);
		let l = dock.Layout;
		Test.Assert(l.CheckInvariants());
		let documents = l.CentralStack;
		Test.Assert(TabsAre(l, documents, "welcome")); // the first group, top
		let assets = l.StackOf("assets");
		let console = l.StackOf("console");
		Test.Assert(TabsAre(l, assets, "assets"));
		Test.Assert(TabsAre(l, console, "console"));
		Test.Assert((assets != documents) && (console != documents) && (assets != console));
		// The welcome over the pane (70% of the height), the pane's two side by side (the assets
		// 65% of it, first).
		let down = ParentOf(l, documents);
		Test.Assert(down != null);
		Test.Assert(down.Axis == .Vertical);
		Test.Assert(down.Children[0] == documents);
		Test.Assert(Near(FirstShare(down), 0.7f));
		let across = ParentOf(l, assets);
		Test.Assert(across != null);
		Test.Assert(ParentOf(l, console) == across);
		Test.Assert(across.Id == down.Children[1]);
		Test.Assert(across.Axis == .Horizontal);
		Test.Assert((across.Children[0] == assets) && (across.Children[1] == console));
		Test.Assert(Near(FirstShare(across), 0.65f));

		// Saved again, the section is the new one, the pages with it.
		let before = LayoutText(l, .. scope .());
		ProjectEditorSettings.CaptureDockLayout(dock, loaded);
		Test.Assert(ProjectEditorSettings.Save(loaded, dir) case .Ok);
		let saved = ReadText(path, .. scope .());
		Test.Assert(saved.Contains("<bool name=\"captured\">true</bool>"));
		Test.Assert(saved.Contains("<u32 name=\"version\">2</u32>"));
		Test.Assert(!saved.Contains("hasRoot"));
		Test.Assert(saved.Contains("7914f166-d579-454d-95d8-aba44565f196"));
		let again = scope Settings();
		Test.Assert(ProjectEditorSettings.Load(again, dir) case .Ok);
		let read = again.Find<EditorDockLayoutSettings>();
		Test.Assert(read.Captured);
		Test.Assert(LayoutText(read.Document.Layout, .. scope .()) == before);
	}

	/// A tab group of the old tree, its chosen tab `active`. The caller owns it.
	private static LegacyDockNode Group(int32 active, params StringView[] panels)
	{
		let node = new LegacyDockNode();
		node.ActiveTab = active;
		for (let panel in panels)
			node.Panels.Add(new String(panel));
		return node;
	}

	/// A split of the old tree, `ratio` the first's share, side by side (`direction` 0) or one
	/// over the other (1). TAKES OWNERSHIP of the halves; the caller owns it.
	private static LegacyDockNode Split(uint8 direction, float ratio, LegacyDockNode first, LegacyDockNode second)
	{
		let node = new LegacyDockNode();
		node.Direction = direction;
		node.Ratio = ratio;
		node.First = first;
		node.Second = second;
		return node;
	}

	/// A split as the second half: the documents (70%) over a pane of the assets (65%) beside the
	/// console's group. Each stack keeps its tabs in order, the chosen one where the old group
	/// had it (not the last placed).
	[Test]
	public static void AnOldTreesNestedSplitsEachSplitTheirOwnRegionWithTheirShares()
	{
		let root = Split(1, 0.7f, Group(0, "welcome", "page-a"),
			Split(0, 0.65f, Group(0, "assets"), Group(1, "console", "profiler", "log")));
		defer delete root;
		let layout = scope DockLayout();
		Test.Assert(layout.InsertTab("stale", layout.CentralStack).Ok);
		EditorDockLayoutSettings.LayoutFromLegacy(root, layout);
		Test.Assert(layout.CheckInvariants());
		Test.Assert(layout.StackOf("stale") == cNoDock, "what the layout held before goes");
		Test.Assert(layout.FindHidden("stale") == null);

		let documents = layout.CentralStack;
		Test.Assert(TabsAre(layout, documents, "welcome", "page-a"));
		Test.Assert(layout.FindNode(documents).Active == 0);
		let assets = layout.StackOf("assets");
		let console = layout.StackOf("console");
		Test.Assert(TabsAre(layout, assets, "assets"));
		Test.Assert(TabsAre(layout, console, "console", "profiler", "log"));
		Test.Assert(layout.FindNode(console).Active == 1);

		let down = ParentOf(layout, documents);
		Test.Assert(down != null);
		Test.Assert(down.Axis == .Vertical);
		Test.Assert(down.Children.Count == 2);
		Test.Assert(down.Children[0] == documents);
		Test.Assert(Near(FirstShare(down), 0.7f));
		let across = ParentOf(layout, assets);
		Test.Assert(across != null);
		Test.Assert(across.Id == down.Children[1]);
		Test.Assert(ParentOf(layout, console) == across);
		Test.Assert(across.Axis == .Horizontal);
		Test.Assert((across.Children[0] == assets) && (across.Children[1] == console));
		Test.Assert(Near(FirstShare(across), 0.65f));
	}

	/// A split as the first half: the assets and console (one over the other, the assets 60%)
	/// beside the welcome, the pair a quarter of the width. The second half is placed first, so
	/// the first half splits only the stack left to it, not the whole.
	[Test]
	public static void AnOldSplitsFirstHalfSplitsOnlyItsOwnRegion()
	{
		let root = Split(0, 0.25f, Split(1, 0.6f, Group(0, "assets"), Group(0, "console")), Group(0, "welcome"));
		defer delete root;
		let layout = scope DockLayout();
		EditorDockLayoutSettings.LayoutFromLegacy(root, layout);
		Test.Assert(layout.CheckInvariants());

		let assets = layout.StackOf("assets");
		let console = layout.StackOf("console");
		let welcome = layout.StackOf("welcome");
		Test.Assert(assets == layout.CentralStack, "the first panel's group is the central stack");
		Test.Assert((console != cNoDock) && (welcome != cNoDock));
		Test.Assert((assets != console) && (assets != welcome) && (console != welcome));
		let across = ParentOf(layout, welcome);
		Test.Assert(across != null);
		Test.Assert(across.Axis == .Horizontal);
		Test.Assert(across.Children.Count == 2);
		Test.Assert(across.Children[1] == welcome);
		Test.Assert(Near(FirstShare(across), 0.25f));
		let down = ParentOf(layout, assets);
		Test.Assert(down != null);
		Test.Assert(down.Id == across.Children[0]);
		Test.Assert(ParentOf(layout, console) == down);
		Test.Assert(down.Axis == .Vertical);
		Test.Assert((down.Children[0] == assets) && (down.Children[1] == console));
		Test.Assert(Near(FirstShare(down), 0.6f));
	}

	/// A panel the old tree names twice (a file edited by hand) is placed once, the layout
	/// holding together: chosen only in the stack it went to, so another group naming it leaves
	/// that stack's choice as it was; a split whose second half begins with a panel placed
	/// already is its first half alone; a half with no panels gives way to the other.
	[Test]
	public static void APanelNamedTwiceIsPlacedOnce()
	{
		{
			// The console in both halves, the second half's chosen tab: the first's choice stands.
			let root = Split(0, 0.5f, Group(0, "assets", "console"), Group(1, "log", "console"));
			defer delete root;
			let layout = scope DockLayout();
			EditorDockLayoutSettings.LayoutFromLegacy(root, layout);
			Test.Assert(layout.CheckInvariants());
			let central = layout.CentralStack;
			Test.Assert(TabsAre(layout, central, "assets", "console"));
			Test.Assert(layout.FindNode(central).Active == 0);
			let log = layout.StackOf("log");
			Test.Assert((log != cNoDock) && (log != central));
			Test.Assert(TabsAre(layout, log, "log"));
		}
		{
			// The outer split puts the log beside the assets first; the inner split, whose second
			// half begins with it, is then the assets alone.
			let root = Split(0, 0.5f, Split(1, 0.5f, Group(0, "assets"), Group(0, "log")), Group(0, "log", "console"));
			defer delete root;
			let layout = scope DockLayout();
			EditorDockLayoutSettings.LayoutFromLegacy(root, layout);
			Test.Assert(layout.CheckInvariants());
			let central = layout.CentralStack;
			Test.Assert(TabsAre(layout, central, "assets"));
			let log = layout.StackOf("log");
			Test.Assert(TabsAre(layout, log, "log", "console"));
			let across = ParentOf(layout, central);
			Test.Assert(across != null);
			Test.Assert(across.Axis == .Horizontal);
			Test.Assert(ParentOf(layout, log) == across);
			Test.Assert(layout.Nodes.Count == 3, "one split of two stacks: nothing split down");
		}
		{
			// A half with nothing in it: the other is the whole.
			let root = Split(0, 0.3f, Group(0), Group(0, "assets"));
			defer delete root;
			let layout = scope DockLayout();
			EditorDockLayoutSettings.LayoutFromLegacy(root, layout);
			Test.Assert(TabsAre(layout, layout.CentralStack, "assets"));
			Test.Assert(layout.Nodes.Count == 1, "the central stack alone");
		}
	}

	/// A version 1 node as the old dock wrote it, up to its children: `type` 0 a split, 1 a tab
	/// group; the caller writes the children and ends it.
	private static void BeginLegacyNode(ISerializer ar, uint8 type, StringView panel, bool split)
	{
		ar.BeginObject();
		var nodeType = type;
		uint8 direction = 1;
		float ratio = 0.7f;
		int32 activeTab = 0;
		let panels = scope List<String>();
		defer { ClearAndDeleteItems!(panels); }
		if (!panel.IsEmpty)
			panels.Add(new String(panel));
		ar.Key("type");
		Serialize(ar, ref nodeType);
		ar.Key("direction");
		Serialize(ar, ref direction);
		ar.Key("ratio");
		Serialize(ar, ref ratio);
		ar.Key("activeTab");
		Serialize(ar, ref activeTab);
		ar.Key("panels");
		SerializeList(ar, panels);
		var hasFirst = split;
		var hasSecond = split;
		ar.Key("hasFirst");
		Serialize(ar, ref hasFirst);
		ar.Key("hasSecond");
		Serialize(ar, ref hasSecond);
	}

	/// Through a positional backend, where nothing marks a field's end, a version 1 payload is
	/// read to its last byte: what follows it reads as written.
	[Test]
	public static void AVersionOnePayloadIsReadThroughToItsEnd()
	{
		const uint32 cAfter = 0xC0FFEE;
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			BeginVersionedPayload(writer, EditorDockLayoutSettings.TypeId, 1);
			writer.BeginObject();
			var hasRoot = true;
			writer.Key("hasRoot");
			Serialize(writer, ref hasRoot);
			writer.Key("root");
			BeginLegacyNode(writer, 0, "", true);
			writer.Key("first");
			BeginLegacyNode(writer, 1, "welcome", false);
			writer.EndObject();
			writer.Key("second");
			BeginLegacyNode(writer, 0, "", true);
			writer.Key("first");
			BeginLegacyNode(writer, 1, "assets", false);
			writer.EndObject();
			writer.Key("second");
			BeginLegacyNode(writer, 1, "console", false);
			writer.EndObject();
			writer.EndObject();
			writer.EndObject();
			writer.EndObject();
			EndVersionedPayload(writer);
			var after = cAfter;
			Serialize(writer, ref after);
			Test.Assert(writer.IsOk);
		}

		buffer.Seek(0, .Begin);
		let reader = scope BinarySerializer(buffer, .Read);
		let section = scope EditorDockLayoutSettings();
		// A reused section: version 1 replaces what it held.
		Test.Assert(section.Document.Layout.InsertTab("stale", section.Document.Layout.CentralStack).Ok);
		section.Serialize(reader);
		uint32 after = 0;
		Serialize(reader, ref after);
		Test.Assert(reader.IsOk);
		Test.Assert(after == cAfter);
		Test.Assert(section.Captured);
		let layout = section.Document.Layout;
		Test.Assert(layout.StackOf("stale") == cNoDock);
		Test.Assert(layout.StackOf("welcome") == layout.CentralStack);
		Test.Assert(TabsAre(layout, layout.StackOf("assets"), "assets"));
		Test.Assert(TabsAre(layout, layout.StackOf("console"), "console"));
		Test.Assert(layout.StackOf("assets") != layout.StackOf("console"));
	}

	/// A version 1 tree that names no panel places none: the section reads as none captured (so
	/// ApplyDockLayout says NotFound and the dock keeps its default).
	[Test]
	public static void AnOldTreeNamingNoPanelLeavesNoneCaptured()
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			BeginVersionedPayload(writer, EditorDockLayoutSettings.TypeId, 1);
			writer.BeginObject();
			var hasRoot = true;
			writer.Key("hasRoot");
			Serialize(writer, ref hasRoot);
			writer.Key("root");
			BeginLegacyNode(writer, 1, "", false);
			writer.EndObject();
			writer.EndObject();
			EndVersionedPayload(writer);
			Test.Assert(writer.IsOk);
		}

		buffer.Seek(0, .Begin);
		let reader = scope BinarySerializer(buffer, .Read);
		let section = scope EditorDockLayoutSettings();
		section.Captured = true; // a reused section
		section.Serialize(reader);
		Test.Assert(reader.IsOk);
		Test.Assert(!section.Captured);
	}

	/// What a restored layout names and nothing provides (a Game tab) is let go, docked or closed.
	[Test]
	public static void WhatARestoredLayoutNamesAndNothingProvidesIsLetGoDockedOrClosed()
	{
		let dock = scope DockController();
		Register(dock, "assets");
		Register(dock, "game-page");
		Register(dock, "game-page-1");
		let layout = scope DockLayout();
		Test.Assert(layout.InsertTab("assets", layout.CentralStack).Ok);
		Test.Assert(layout.InsertBeside("game-page", layout.StackOf("assets"), .End, 0.5f).Ok);
		Test.Assert(layout.InsertTab("game-page-1", layout.StackOf("game-page")).Ok);
		Test.Assert(layout.Close("game-page-1").Ok, "a closed one is remembered as hidden");

		// The next session: the shared panels registered, no Game tab reopened.
		let restored = scope DockController();
		Register(restored, "assets");
		Test.Assert(restored.Adopt(layout).Ok);
		Test.Assert(restored.Layout.StackOf("game-page") != cNoDock, "a placeholder until let go");
		ProjectEditorSettings.ForgetUnprovidedPanels(restored);
		let kept = restored.Layout;
		Test.Assert(kept.StackOf("assets") != cNoDock);
		Test.Assert(kept.StackOf("game-page") == cNoDock);
		Test.Assert(kept.FindHidden("game-page") == null);
		Test.Assert(kept.FindHidden("game-page-1") == null);
		Test.Assert(kept.CheckInvariants());
	}
}
