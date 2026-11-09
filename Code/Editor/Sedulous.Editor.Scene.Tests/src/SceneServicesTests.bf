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
}
