using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Script;
using Sedulous.Script.Resource;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// The scene editor's services, registered without a page: the export's seams set (a scene's text
/// source transcoded to the binary wire, its references scanned), and an import that is not a
/// model passing the model-prefab listener by.
class SceneServicesTests
{
	/// A headless host: the import listener only keeps it.
	class StubHost : IApplicationHost
	{
		public SubsystemManager Subsystems { get; } = new .() ~ delete _;

		public IShell Shell => null;
		public GraphicsDevice Graphics => null;
		public RenderWindow MainRenderWindow => null;

		public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) => null;
		public void CloseWindow(RenderWindow window) {}
		public void RequestExit(int code = 0) {}
	}

	[Test]
	public static void TheExportsSeamsSetASceneTextSourceStagedAsTheBinaryWireItsReferencesScanned()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_scene_services_project", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		let context = scope EditorContext();
		let host = scope StubHost();
		Test.Assert(context.SceneStreamStager == null);
		Test.Assert(context.SceneRefScanner == null);
		SceneServices.Register(context, host);
		Test.Assert(context.SceneStreamStager != null);
		Test.Assert(context.SceneRefScanner != null);

		let level = project.SourceDb.RootGroup.CreateInstance("Level", typeof(SceneDocument).GetFullName(.. scope .()));
		Test.Assert(level != null);
		{
			let authored = scope Sedulous.Scene.Scene("authored");
			EngineSceneComposition.AddAllSceneManagers(authored);
			authored.CreateEntity("Crate");
			Test.Assert(SceneStorage.SaveScene(authored, level) case .Ok);
		}
		let text = scope List<uint8>();
		{
			let stream = level.ReadData(SceneExportSupport.cSceneStream);
			Test.Assert(stream != null);
			defer delete stream;
			text.Resize((int)stream.Size());
			stream.Read(Span<uint8>(text.Ptr, text.Count));
		}
		let wire = scope List<uint8>();
		Test.Assert(context.SceneStreamStager(level, wire));
		Test.Assert(!wire.IsEmpty);
		var verbatim = wire.Count == text.Count;
		for (int i = 0; verbatim && (i < wire.Count); i++)
			verbatim = wire[i] == text[i];
		Test.Assert(!verbatim, "transcoded, not the source as it is");

		let resources = scope List<Guid>();
		let prefabs = scope List<Guid>();
		Test.Assert(context.SceneRefScanner(level, project.SourceDb, resources, prefabs));
		Test.Assert(prefabs.IsEmpty);

		// Not a model's import: the prefab listener lets it by, saying nothing.
		int notices = 0;
		context.OnNotice = new [&notices](kind, message) => { notices++; };
		context.NotifyImported(level, null);
		Test.Assert(notices == 0, "nothing said");
		Test.Assert(project.SourceDb.RootGroup.GetInstance("Level") == level);
	}

	/// A script property holding an asset is a reference a pruned export follows, though the
	/// scene never binds it: a behaviour's override and the Level's. An entity override's guid
	/// is the scene's, not an asset, and an asset nothing names stays out.
	[Test]
	public static void APrunedExportReachesTheAssetsAScriptsPropertiesName()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_scene_services_script_refs", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		let context = scope EditorContext();
		let host = scope StubHost();
		SceneServices.Register(context, host);

		let root = project.SourceDb.RootGroup;
		let dropper = root.CreateInstance("Dropper", "Sedulous.Script.Pipeline.ScriptClassAsset");
		let pickup = root.CreateInstance("Pickup", typeof(PrefabDocument).GetFullName(.. scope .()));
		let theme = root.CreateInstance("Theme", "Sedulous.Audio.Resource.AudioClipData");
		let unused = root.CreateInstance("Unused", "Sedulous.Audio.Resource.AudioClipData");
		let level = root.CreateInstance("Level", typeof(SceneDocument).GetFullName(.. scope .()));
		Test.Assert((dropper != null) && (pickup != null) && (theme != null) && (unused != null) && (level != null));
		{
			let authored = scope Sedulous.Scene.Scene("authored");
			EngineSceneComposition.AddAllSceneManagers(authored);
			let spawner = authored.CreateEntity("Spawner");
			let scripts = authored.GetSystem<ScriptComponentManager>();
			Test.Assert(scripts.AddBehavior(spawner, dropper.Id));
			let behavior = scripts.Get(spawner).Behaviors[0];
			behavior.SetOverride(ScriptPropertyNames.HashOf("drop"), .Asset(pickup.Id));
			behavior.SetOverride(ScriptPropertyNames.HashOf("target"), .Entity(unused.Id));
			authored.GetSystem<ScriptSceneSystem>().Settings.SetOverride(ScriptPropertyNames.HashOf("music"), .Asset(theme.Id));
			Test.Assert(SceneStorage.SaveScene(authored, level) case .Ok);
		}

		SceneReferenceScanner adapter = scope (instance, db, refs) => { context.SceneRefScanner(instance, db, refs.Resources, refs.Prefabs); };
		let seeds = scope List<ExportRoot>();
		defer { ClearAndDeleteItems(seeds); }
		let seed = new ExportRoot();
		seed.Id = level.Id;
		seeds.Add(seed);
		let reachable = scope List<Guid>();
		ExportDriver.ExpandReachableRoots(project, seeds, adapter, reachable);
		Test.Assert(reachable.Contains(level.Id) && reachable.Contains(dropper.Id), "the scene and the script it binds");
		Test.Assert(reachable.Contains(pickup.Id), "the prefab a behaviour's override names");
		Test.Assert(reachable.Contains(theme.Id), "the asset the Level's override names");
		Test.Assert(!reachable.Contains(unused.Id), "an entity override names no asset, and nothing else names it");
	}

	/// A placed prefab instance's own override is the scene's reference: the scan spawns the
	/// instances with their overrides before it collects, so an asset one placement names (here
	/// a script property set on it alone) is reached, and the prefab's own content still is.
	[Test]
	public static void APrunedExportReachesTheAssetsAPlacedPrefabsOverridesName()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_scene_services_instance_refs", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		let context = scope EditorContext();
		let host = scope StubHost();
		SceneServices.Register(context, host);

		let root = project.SourceDb.RootGroup;
		let dropper = root.CreateInstance("Dropper", "Sedulous.Script.Pipeline.ScriptClassAsset");
		let crate = root.CreateInstance("Crate", typeof(PrefabDocument).GetFullName(.. scope .()));
		let inPrefab = root.CreateInstance("InPrefab", "Sedulous.Audio.Resource.AudioClipData");
		let onPlacement = root.CreateInstance("OnPlacement", "Sedulous.Audio.Resource.AudioClipData");
		let unused = root.CreateInstance("Unused", "Sedulous.Audio.Resource.AudioClipData");
		let level = root.CreateInstance("Level", typeof(SceneDocument).GetFullName(.. scope .()));
		Test.Assert((dropper != null) && (crate != null) && (inPrefab != null) && (onPlacement != null) && (unused != null) && (level != null));
		let drop = ScriptPropertyNames.HashOf("drop");
		{
			// The prefab: a body whose behaviour's own override names one asset.
			let doc = scope PrefabDocument();
			doc.Name.Set("Crate");
			Test.Assert(crate.WriteObject(doc) case .Ok);
			let author = scope Sedulous.Scene.Scene("Crate");
			EngineSceneComposition.AddAllSceneManagers(author);
			let body = author.CreateEntity("Body");
			let scripts = author.GetSystem<ScriptComponentManager>();
			Test.Assert(scripts.AddBehavior(body, dropper.Id));
			scripts.Get(body).Behaviors[0].SetOverride(drop, .Asset(inPrefab.Id));
			let payload = scope MemoryStream();
			Test.Assert(PrefabCapture.Capture(author, body, payload) case .Ok);
			Test.Assert(crate.WriteData(SceneExportSupport.cSceneStream, payload.Bytes, .Text) case .Ok);
		}
		{
			// The scene: one placement of it, its override naming another asset.
			let authored = scope Sedulous.Scene.Scene("authored");
			EngineSceneComposition.AddAllSceneManagers(authored);
			let payload = crate.ReadData(SceneExportSupport.cSceneStream);
			Test.Assert(payload != null);
			defer delete payload;
			let placed = PrefabSpawn.Spawn(authored, payload, crate.Id);
			Test.Assert(placed.IsAssigned && (authored.PrefabInstanceCount == 1));
			let behavior = authored.GetSystem<ScriptComponentManager>().Get(placed).Behaviors[0];
			let inherited = behavior.FindOverride(drop);
			Test.Assert((inherited != null) && (inherited.Value.Id == inPrefab.Id), "the placement starts as the prefab");
			behavior.SetOverride(drop, .Asset(onPlacement.Id));
			Test.Assert(SceneStorage.SaveScene(authored, level) case .Ok);
		}

		// The scene's scan alone: the placement's asset, and the prefab it places.
		let resources = scope List<Guid>();
		let prefabs = scope List<Guid>();
		Test.Assert(context.SceneRefScanner(level, project.SourceDb, resources, prefabs));
		Test.Assert((prefabs.Count == 1) && (prefabs[0] == crate.Id), "the placed prefab's id, as before");
		Test.Assert(resources.Contains(onPlacement.Id), "the asset the placement's override names");

		SceneReferenceScanner adapter = scope (instance, db, refs) => { context.SceneRefScanner(instance, db, refs.Resources, refs.Prefabs); };
		let seeds = scope List<ExportRoot>();
		defer { ClearAndDeleteItems(seeds); }
		let seed = new ExportRoot();
		seed.Id = level.Id;
		seeds.Add(seed);
		let reachable = scope List<Guid>();
		ExportDriver.ExpandReachableRoots(project, seeds, adapter, reachable);
		Test.Assert(reachable.Contains(level.Id) && reachable.Contains(crate.Id) && reachable.Contains(dropper.Id));
		Test.Assert(reachable.Contains(onPlacement.Id), "the placement's asset");
		Test.Assert(reachable.Contains(inPrefab.Id), "the prefab's own asset, through the prefab");
		Test.Assert(!reachable.Contains(unused.Id), "an asset nothing names stays out");
	}
}
