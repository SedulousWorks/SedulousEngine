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
/// the dock refuses leaves it as it was; the old dock's tree (section version 1) reads and is set
/// aside, read through to its end, the open pages kept, and saves again as version 2.
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
	/// its dock tree, a split of the welcome page beside a split of the assets over the console.
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

	[Test]
	public static void TheOldDocksTreeReadsAndIsSetAside()
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
		Test.Assert(!section.Captured);
		// The open pages still reopen.
		let pages = scope List<Guid>();
		let reopened = ProjectEditorSettings.ApplyOpenPages(loaded, pages, let active);
		Test.Assert(reopened case .Ok);
		Test.Assert(pages.Count == 1);
		Test.Assert(active != .Empty);
		Test.Assert(active == pages[0]);

		// Set aside: the default stands.
		let dock = scope DockController();
		Register(dock, "assets");
		Arrange(dock);
		let before = LayoutText(dock.Layout, .. scope .());
		Test.Assert(ProjectEditorSettings.ApplyDockLayout(dock, loaded) case .Err(.NotFound));
		Test.Assert(LayoutText(dock.Layout, .. scope .()) == before);

		// Saved again, the section is the new one, the pages with it.
		ProjectEditorSettings.CaptureDockLayout(dock, loaded);
		Test.Assert(ProjectEditorSettings.Save(loaded, dir) case .Ok);
		let saved = ReadText(path, .. scope .());
		Test.Assert(saved.Contains("<bool name=\"captured\">true</bool>"));
		Test.Assert(saved.Contains("<u32 name=\"version\">2</u32>"));
		Test.Assert(!saved.Contains("hasRoot"));
		Test.Assert(saved.Contains("7914f166-d579-454d-95d8-aba44565f196"));
		let again = scope Settings();
		Test.Assert(ProjectEditorSettings.Load(again, dir) case .Ok);
		Test.Assert(again.Find<EditorDockLayoutSettings>().Captured);
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
		section.Captured = true; // a reused section: version 1 leaves none captured
		section.Serialize(reader);
		uint32 after = 0;
		Serialize(reader, ref after);
		Test.Assert(reader.IsOk);
		Test.Assert(!section.Captured);
		Test.Assert(after == cAfter);
	}
}
