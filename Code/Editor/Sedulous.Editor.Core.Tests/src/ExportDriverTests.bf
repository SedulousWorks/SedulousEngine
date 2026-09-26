using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Geometry;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Render;
using Sedulous.Engine.Project;
using Sedulous.VFS;
using Sedulous.VFS.Pak;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// The export driver: a project into a dist the player loads back, the closure pruned and
/// reported or not, the roots seeded, the variants per platform, the player and sidecars
/// staged from the resolved template with the shader pack, symbols when opted in, a foreign
/// engine version warning but exporting, and the names.
static class ExportDriverTests
{
	private static ContentDatabase OpenDistPak(StringView outputDir, PakFileSystem pak, SerializerFactory factory)
	{
		Test.Assert(pak.IsValid, "the dist pak opens");
		return new ContentDatabase(pak, factory, ProjectLayout.CookedAssetExtension);
	}

	[Test]
	public static void AProjectExportsToADistPakThePlayerLoadsBack()
	{
		let fx = scope ExportProjectFixture("scratch_export_e2e");
		let distDir = PathJoin(fx.OutRoot, "dist", .. scope .());
		let scriptId = Guid.Parse("abcd1234-0000-0000-0000-5678ef900000").Get();
		fx.Project.Settings.StartupScriptId = scriptId;
		Test.Assert(fx.Project.SaveSettings() case .Ok);

		// The scene pre-transcoded to the binary wire, as the editor's stager does.
		let sceneStreams = scope Dictionary<Guid, List<uint8>>();
		defer { for (let entry in sceneStreams) delete entry.value; }
		{
			let sceneInstance = fx.Project.SourceDb.GetInstance(fx.SceneId);
			let source = sceneInstance.ReadData("scene");
			Test.Assert(source != null);
			defer delete source;
			let scratch = scope Scene("scratch");
			scratch.AddSystem<MeshComponentManager>();
			let bytes = new List<uint8>();
			Test.Assert(SceneTranscode.ToBinary(source, scratch, bytes, true) case .Ok);
			Test.Assert((bytes.Count > 0) && (bytes[0] != (uint8)'<'), "binary, not the XML source");
			sceneStreams[fx.SceneId] = bytes;
		}
		let stats = scope ExportStats();
		Test.Assert(ExportDriver.ExportProject(fx.Project, distDir, fx.Builders, false, stats, null, sceneStreams) case .Ok);
		Test.Assert(stats.Cooked == 2, scope $"{stats.Cooked} cooked");
		Test.Assert(stats.ScenesStaged == 1);
		Test.Assert(stats.FilesPacked >= 3, "products plus the scene envelope and stream");

		// The dist manifest carries the defaults by guid.
		let distRoot = scope NativeFileSystem(distDir);
		let manifest = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(distRoot, manifest, ProjectLayout.DistManifestFile) case .Ok);
		Test.Assert((manifest.DefaultScene == "Scenes/Main") && (manifest.DefaultSceneId == fx.SceneId) && (manifest.StartupScriptId == scriptId));

		// The pak, read as the player reads it: the scene by guid and by path, its stream
		// binary, its mesh resolving through the factory to the 2.0 cube.
		let pak = scope PakFileSystem(PathJoin(distDir, ProjectLayout.DistContentPak, .. scope .()));
		SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let db = OpenDistPak(distDir, pak, binary);
		defer delete db;
		let packedScene = db.GetInstance(manifest.DefaultSceneId);
		Test.Assert((packedScene != null) && (packedScene.Id == fx.SceneId));
		Test.Assert(db.GetInstanceByPath(manifest.DefaultScene) == packedScene);
		{
			let packed = packedScene.ReadData("scene");
			Test.Assert(packed != null);
			defer delete packed;
			uint8[1] first = .(0);
			Test.Assert(packed.Read(first) == 1);
			Test.Assert(first[0] != (uint8)'<');
		}
		let scene = scope Scene();
		let meshes = scene.AddSystem<MeshComponentManager>();
		Test.Assert(SceneStorage.LoadScene(packedScene, scene) case .Ok);
		let resources = scope ResourceManager(db);
		let staticMeshes = scope StaticMeshFactory();
		let skinnedMeshes = scope SkinnedMeshFactory();
		GeometryResources.AddFactories(resources, staticMeshes, skinnedMeshes);
		SceneResolve.ResolveSceneResources(scene, resources);
		MeshComponent* component = null;
		meshes.ForEach(scope [&](c, owner) => { component = c; });
		Test.Assert(component != null);
		Test.Assert(component.Mesh.Id == fx.ReferencedMeshId);
		let mesh = component.Mesh.Get;
		Test.Assert(mesh != null, "the mesh resolved from the pak");
		Test.Assert(Math.Abs(mesh.Bounds.Max.X - 1.0f) < 1e-4f, "the 2.0 cube");
	}

	[Test]
	public static void ExportOneStagesThePlayerSidecarsAndShaderPackBesideTheContent()
	{
		let fx = scope ExportProjectFixture("scratch_export_one");
		let preset = ExportProjectFixture.HostPreset("Host", "host");
		defer delete preset;
		preset.AdditionalFiles.Add(new String("Project.xml"));
		let result = scope ExportResult();
		let steps = scope List<String>();
		defer { ClearAndDeleteItems(steps); }
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, result,
			scope [&](step, fraction) => { steps.Add(new String(step)); }) case .Ok);
		Test.Assert(result.OutputDir == PathJoin(fx.OutRoot, "host", .. scope .()));
		let dist = scope NativeFileSystem(result.OutputDir);
		Test.Assert(dist.Exists(BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, .. scope .())), "the player staged");
		Test.Assert(dist.Exists("libfoo.so"), "the sidecar staged");
		Test.Assert(dist.Exists(ProjectLayout.DistContentPak) && dist.Exists(ProjectLayout.DistManifestFile));
		Test.Assert(dist.Exists("Project.xml"), "the additional file staged by its base name");
		Test.Assert(dist.Exists("Data/Shaders/shaders.dpak") && dist.Exists("Data/.dataroot"), "the shader pack and the data root marker");
		Test.Assert(!dist.Exists(".stage-scenes"), "the staging directory removed");
		Test.Assert(result.FilesStaged == 5, scope $"{result.FilesStaged} staged");
		Test.Assert(result.Content.Cooked == 2);
		Test.Assert(result.EngineVersionWarning.IsEmpty);
		Test.Assert(!result.Pruning.Pruned);
		Test.Assert((steps.Count > 0) && (steps[steps.Count - 1] == "Done"));
	}

	[Test]
	public static void APrunedDistKeepsTheClosureDropsTheRestAndReportsBoth()
	{
		let fx = scope ExportProjectFixture("scratch_export_prune");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		let pruned = ExportProjectFixture.HostPreset("Pruned", "pruned");
		defer delete pruned;
		pruned.PruneToReachable = true;
		let result = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, pruned, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, result, null, true, null, fx.Scanner) case .Ok);
		SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		{
			let pak = scope PakFileSystem(PathJoin(result.OutputDir, ProjectLayout.DistContentPak, .. scope .()));
			let db = OpenDistPak(result.OutputDir, pak, binary);
			defer delete db;
			Test.Assert(db.GetInstance(fx.SceneId) != null, "the scene staged");
			Test.Assert(db.GetInstance(fx.ReferencedMeshId) != null, "the referenced mesh kept");
			Test.Assert(db.GetInstance(fx.UnreferencedMeshId) == null, "the unreferenced mesh pruned");
		}
		Test.Assert(result.Pruning.Pruned);
		Test.Assert((result.Pruning.Roots.Count == 1) && (result.Pruning.Roots[0].Reason == .DefaultScene) && (result.Pruning.Roots[0].Id == fx.SceneId));
		bool droppedDead = false;
		for (let dropped in result.Pruning.Dropped)
			if (dropped == "Meshes/Unreferenced")
				droppedDead = true;
		Test.Assert(droppedDead);
		Test.Assert(FileExists(PathJoin(result.OutputDir, "export-report.txt", .. scope .())), "the report beside the dist");

		// Not pruning ships the unreferenced mesh too, and writes no report.
		let full = ExportProjectFixture.HostPreset("Full", "full");
		defer delete full;
		let fullResult = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, full, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, fullResult, null, true, null, fx.Scanner) case .Ok);
		{
			let pak = scope PakFileSystem(PathJoin(fullResult.OutputDir, ProjectLayout.DistContentPak, .. scope .()));
			let db = OpenDistPak(fullResult.OutputDir, pak, binary);
			defer delete db;
			Test.Assert((db.GetInstance(fx.ReferencedMeshId) != null) && (db.GetInstance(fx.UnreferencedMeshId) != null));
		}
		Test.Assert(!fullResult.Pruning.Pruned);
		Test.Assert(!FileExists(PathJoin(fullResult.OutputDir, "export-report.txt", .. scope .())));

		// Pruning requested with no scanner and no precomputed set exports everything, with
		// a warning.
		let blind = ExportProjectFixture.HostPreset("Blind", "blind");
		defer delete blind;
		blind.PruneToReachable = true;
		let blindResult = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, blind, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, blindResult) case .Ok);
		Test.Assert(!blindResult.Pruning.Pruned);
	}

	[Test]
	public static void CollectExportRootsSeedsTheManifestFlagsAndGroupMembersDeduped()
	{
		let fx = scope ExportProjectFixture("scratch_export_roots");
		fx.Project.ExportRoots.SetInstance(fx.UnreferencedMeshId, true);
		fx.Project.ExportRoots.SetInstance(fx.SceneId, true); // also the default scene: deduped
		fx.Project.ExportRoots.SetGroup("Meshes", true);
		let roots = scope List<ExportRoot>();
		defer { ClearAndDeleteItems(roots); }
		ExportDriver.CollectExportRoots(fx.Project, roots);
		Test.Assert(roots.Count == 3, scope $"{roots.Count} roots");
		Test.Assert((roots[0].Id == fx.SceneId) && (roots[0].Reason == .DefaultScene) && (roots[0].Name == "Scenes/Main"), "the default scene first, its flag deduped");
		Test.Assert((roots[1].Id == fx.UnreferencedMeshId) && (roots[1].Reason == .Flag));
		Test.Assert((roots[2].Id == fx.ReferencedMeshId) && (roots[2].Reason == .Group), "the group member the flag did not already name");

		// The closure from the seeds through the scanner.
		let seeds = scope List<ExportRoot>();
		defer { ClearAndDeleteItems(seeds); }
		let sceneRoot = new ExportRoot();
		sceneRoot.Id = fx.SceneId;
		seeds.Add(sceneRoot);
		let reachable = scope List<Guid>();
		ExportDriver.ExpandReachableRoots(fx.Project, seeds, fx.Scanner, reachable);
		Test.Assert((reachable.Count == 2) && (reachable[0] == fx.SceneId) && (reachable[1] == fx.ReferencedMeshId));

		// A group subtree enumerates, not its siblings.
		let members = scope List<Guid>();
		ExportRootsFile.CollectGroupInstances(fx.Project.SourceDb, "Meshes", members);
		Test.Assert((members.Count == 2) && !members.Contains(fx.SceneId));
		members.Clear();
		ExportRootsFile.CollectGroupInstances(fx.Project.SourceDb, "NoSuchGroup", members);
		Test.Assert(members.IsEmpty);
	}

	[Test]
	public static void VariantsForPlatformDesktopSinglePakWebBcAndAstcSiblings()
	{
		let fx = scope ExportProjectFixture("scratch_export_variants");
		let desktop = scope List<ContentVariant>();
		defer { ClearAndDeleteItems(desktop); }
		ExportDriver.VariantsForPlatform(fx.Project, "Linux64", desktop);
		Test.Assert((desktop.Count == 1) && desktop[0].Key.IsEmpty && (desktop[0].PakName == "Content.pak"));
		Test.Assert(desktop[0].CookedDir == PathJoin(fx.ProjectDir, ProjectLayout.CookedDir, .. scope .()));
		let web = scope List<ContentVariant>();
		defer { ClearAndDeleteItems(web); }
		ExportDriver.VariantsForPlatform(fx.Project, "Web", web);
		Test.Assert(web.Count == 2);
		Test.Assert((web[0].Key == "bc") && (web[0].PakName == "Content-bc.pak") && web[0].CookedDir.EndsWith("Cooked-web-bc"));
		Test.Assert((web[1].Key == "astc") && (web[1].PakName == "Content-astc.pak") && web[1].CookedDir.EndsWith("Cooked-web-astc"));
	}

	[Test]
	public static void AForeignEngineVersionWarnsButExportsAndSymbolsStageOnlyWhenOptedIn()
	{
		let fx = scope ExportProjectFixture("scratch_export_foreign");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		// An imported template for the host platform, another engine, with a symbol file.
		let templatesRoot = PathJoin(fx.OutRoot, "templates", .. scope .());
		let bundle = PathJoin(templatesRoot, "sedulous-old", .. scope .());
		CreateDirectory(bundle);
		let template = scope ExportTemplate();
		template.Id.Set("sedulous-old");
		template.Platform.Set(BuildLayout.HostPlatformName);
		template.Config.Set(BuildLayout.BuildConfigName);
		template.EngineVersion.Set("0.0.1");
		template.PlayerBinary.Set("OldPlayer");
		template.Sidecars.Add(new String("libold.so"));
		template.Symbols.Add(new String("OldPlayer.dbg"));
		Test.Assert(ExportTemplates.SaveManifest(scope NativeFileSystem(bundle), template) case .Ok);
		for (let name in scope String[]("OldPlayer", "libold.so", "OldPlayer.dbg"))
		{
			let text = "x\n";
			WriteFile(PathJoin(bundle, name, .. scope .()), .((uint8*)text.Ptr, text.Length)).IgnoreError();
		}
		fx.Templates.Refresh(templatesRoot, fx.ToolDir);

		let stripped = ExportProjectFixture.HostPreset("Stripped", "stripped");
		defer delete stripped;
		stripped.TemplateId.Set("sedulous-old");
		stripped.PlayerName.Set("MyGame");
		let result = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, stripped, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, result) case .Ok);
		Test.Assert(result.EngineVersionWarning.Contains("0.0.1") && result.EngineVersionWarning.Contains(EngineVersion.String));
		let dist = scope NativeFileSystem(result.OutputDir);
		Test.Assert(dist.Exists("MyGame"), "the preset's player name");
		Test.Assert(dist.Exists("libold.so") && !dist.Exists("OldPlayer.dbg"), "sidecars yes, symbols no");

		let withSymbols = ExportProjectFixture.HostPreset("Symbols", "symbols");
		defer delete withSymbols;
		withSymbols.TemplateId.Set("sedulous-old");
		withSymbols.StageSymbols = true;
		let symbolResult = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, withSymbols, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, symbolResult) case .Ok);
		Test.Assert(FileExists(PathJoin(symbolResult.OutputDir, "OldPlayer.dbg", .. scope .())));

		// No template for the platform: refused before anything is written.
		let nowhere = ExportProjectFixture.HostPreset("Nowhere", "nowhere");
		defer delete nowhere;
		nowhere.Platform.Set("Nonexistent64");
		Test.Assert(ExportDriver.ExportOne(fx.Project, nowhere, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false) case .Err(.NotFound));
		// A native module is not supported yet.
		fx.Project.Settings.NativeModule.Set("Native/libGame.so");
		let native = ExportProjectFixture.HostPreset("Native", "native");
		defer delete native;
		Test.Assert(ExportDriver.ExportOne(fx.Project, native, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false) case .Err(.NotSupported));
	}

	[Test]
	public static void ExportAllRunsEveryPresetAndFailsWhenOneDoes()
	{
		let fx = scope ExportProjectFixture("scratch_export_all");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		let presets = scope List<ExportPreset>();
		defer { ClearAndDeleteItems(presets); }
		presets.Add(ExportProjectFixture.HostPreset("A", "a"));
		presets.Add(ExportProjectFixture.HostPreset("B", "b"));
		let steps = scope List<String>();
		defer { ClearAndDeleteItems(steps); }
		Test.Assert(ExportDriver.ExportAll(fx.Project, presets, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false,
			scope [&](step, fraction) => { steps.Add(new String(step)); }) case .Ok);
		Test.Assert(DirectoryExists(PathJoin(fx.OutRoot, "a", .. scope .())) && DirectoryExists(PathJoin(fx.OutRoot, "b", .. scope .())));
		Test.Assert(steps[0].StartsWith("A: "), "the progress scoped to the preset");
		let broken = ExportProjectFixture.HostPreset("C", "c");
		broken.Platform.Set("Nonexistent64");
		presets.Add(broken);
		Test.Assert(ExportDriver.ExportAll(fx.Project, presets, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false) case .Err);
	}

	[Test]
	public static void TheNamesAreTargetPlatformAwareAndFilesystemSafe()
	{
		Test.Assert(ExportStaging.PlayerOutputName("Win64", "", "Sedulous.Engine.Player.Desktop.exe", .. scope .()) == "Sedulous.Engine.Player.Desktop.exe");
		Test.Assert(ExportStaging.PlayerOutputName("Win64", "MyGame", "Player.exe", .. scope .()) == "MyGame.exe", "a Windows target gets .exe");
		Test.Assert(ExportStaging.PlayerOutputName("Linux64", "MyGame", "Player", .. scope .()) == "MyGame");
		Test.Assert(ExportStaging.SanitizeName("My Game: v2!", .. scope .()) == "My-Game--v2-");
		Test.Assert(ExportStaging.SanitizeName("", .. scope .()) == "export");
		Test.Assert(ExportStaging.IsDxcRuntimeLib("libdxcompiler.so") && ExportStaging.IsDxcRuntimeLib("dxil.dll") && !ExportStaging.IsDxcRuntimeLib("SDL3.dll"));
		let formats = scope List<Sedulous.Shaders.CookedShaderFormat>();
		ExportStaging.FormatsForPlatform("Web", formats);
		Test.Assert((formats.Count == 1) && (formats[0] == .Wgsl));
		formats.Clear();
		ExportStaging.FormatsForPlatform("Win64", formats);
		Test.Assert((formats.Count == 2) && (formats[0] == .SpirV) && (formats[1] == .Dxil));
		formats.Clear();
		ExportStaging.FormatsForPlatform("Linux64", formats);
		Test.Assert((formats.Count == 1) && (formats[0] == .SpirV));
	}

	[Test]
	public static void PrecomputedReachableRootsPruneLikeAnInlineScanner()
	{
		// The editor's main thread path: the scan happens up front and the background export
		// job takes the set, no live scanner.
		let fx = scope ExportProjectFixture("scratch_export_precomputed");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		let seeds = scope List<ExportRoot>();
		defer { ClearAndDeleteItems(seeds); }
		ExportDriver.CollectExportRoots(fx.Project, seeds);
		let reachable = scope List<Guid>();
		ExportDriver.ExpandReachableRoots(fx.Project, seeds, fx.Scanner, reachable);
		Test.Assert(reachable.Count >= 2, "the scene and its mesh at least");
		let preset = ExportProjectFixture.HostPreset("Pruned", "pruned");
		defer delete preset;
		preset.PruneToReachable = true;
		let result = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, result, null, true, null, null, reachable) case .Ok);
		SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let pak = scope PakFileSystem(PathJoin(result.OutputDir, ProjectLayout.DistContentPak, .. scope .()));
		let db = OpenDistPak(result.OutputDir, pak, binary);
		defer delete db;
		Test.Assert((db.GetInstance(fx.SceneId) != null) && (db.GetInstance(fx.ReferencedMeshId) != null));
		Test.Assert(db.GetInstance(fx.UnreferencedMeshId) == null, "pruned through the precomputed set");
		Test.Assert(result.Pruning.Pruned);
	}

	[Test]
	public static void PruningKeepsASceneToPrefabToAssetChain()
	{
		let fx = scope ExportProjectFixture("scratch_export_prefab_chain");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		// A prefab whose body carries a mesh of its own, spawned into the scene.
		let meshInPrefab = ExportProjectFixture.AuthorMesh(fx.Project.SourceDb.RootGroup.GetGroup("Meshes"), "InPrefab");
		let prefabs = fx.Project.SourceDb.RootGroup.CreateGroup("Prefabs");
		let prefabInstance = prefabs.CreateInstance("Barrel", McpDocumentNames.cPrefabDocument);
		{
			let doc = scope PrefabDocument();
			doc.Name.Set("Barrel");
			Test.Assert(prefabInstance.WriteObject(doc) case .Ok);
			let author = scope Scene("Barrel");
			author.AddSystem<MeshComponentManager>();
			let e = author.CreateEntity("Body");
			author.GetSystem<MeshComponentManager>().Add(e).Mesh.SetId(meshInPrefab);
			let payload = scope Sedulous.Core.IO.MemoryStream();
			Test.Assert(PrefabCapture.Capture(author, e, payload) case .Ok);
			Test.Assert(prefabInstance.WriteData("scene", payload.Bytes, .Text) case .Ok);
		}
		{
			let sceneInstance = fx.Project.SourceDb.GetInstance(fx.SceneId);
			let scene = scope Scene("Main");
			scene.AddSystem<MeshComponentManager>();
			let payload = prefabInstance.ReadData("scene");
			Test.Assert(payload != null);
			defer delete payload;
			let spawned = PrefabSpawn.Spawn(scene, payload, prefabInstance.Id);
			Test.Assert(spawned.IsAssigned && (scene.PrefabInstanceCount == 1));
			Test.Assert(SceneStorage.SaveScene(scene, sceneInstance) case .Ok);
		}
		let preset = ExportProjectFixture.HostPreset("Pruned", "pruned");
		defer delete preset;
		preset.PruneToReachable = true;
		let result = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, result, null, true, null, fx.Scanner) case .Ok);
		SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let pak = scope PakFileSystem(PathJoin(result.OutputDir, ProjectLayout.DistContentPak, .. scope .()));
		let db = OpenDistPak(result.OutputDir, pak, binary);
		defer delete db;
		Test.Assert(db.GetInstance(fx.SceneId) != null);
		Test.Assert(db.GetInstance(prefabInstance.Id) != null, "the prefab the scene instantiates");
		Test.Assert(db.GetInstance(meshInPrefab) != null, "the mesh the prefab's body references");
		Test.Assert(db.GetInstance(fx.UnreferencedMeshId) == null);
	}

	[Test]
	public static void TheDesktopPakIsByteIdenticalWithASiblingTargetDatabasePresent()
	{
		// A materialised per target database, Cooked-web-astc/, is a SIBLING of Cooked/: the
		// desktop pack must never walk into it.
		let fx = scope ExportProjectFixture("scratch_export_byteident");
		let distA = PathJoin(fx.OutRoot, "a", .. scope .());
		let distB = PathJoin(fx.OutRoot, "b", .. scope .());
		Test.Assert(ExportDriver.ExportProject(fx.Project, distA, fx.Builders, false) case .Ok);
		let sibling = PathJoin(fx.ProjectDir, "Cooked-web-astc", .. scope .());
		CreateDirectory(sibling);
		let junk = "NOT DESKTOP CONTENT";
		Test.Assert(WriteFile(PathJoin(sibling, "junk.rasset", .. scope .()), .((uint8*)junk.Ptr, junk.Length)) case .Ok);
		Test.Assert(ExportDriver.ExportProject(fx.Project, distB, fx.Builders, false) case .Ok);
		let a = scope List<uint8>();
		let b = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(distA, ProjectLayout.DistContentPak, .. scope .()), a) case .Ok);
		Test.Assert(ReadFile(PathJoin(distB, ProjectLayout.DistContentPak, .. scope .()), b) case .Ok);
		Test.Assert((a.Count == b.Count) && (a.Count > 0));
		Test.Assert(Internal.MemCmp(a.Ptr, b.Ptr, a.Count) == 0, "byte identical");
	}

	[Test]
	public static void AStartupScriptAssetCooksIntoTheDistPakAndBindsLikeThePlayer()
	{
		let fx = scope ExportProjectFixture("scratch_export_script");
		Sedulous.Pipeline.Registration.PipelineRegistration.RegisterPipelineTypes();
		defer Sedulous.Pipeline.Registration.PipelineRegistration.Teardown();
		let source = "class Game\n{\n\tvoid launch() {}\n\tvoid update(float dt) {}\n}\n";
		Test.Assert(WriteFile(PathJoin(fx.Project.SourcesRoot(.. scope .()), "Game.as", .. scope .()), .((uint8*)source.Ptr, source.Length)) case .Ok);
		let scriptInstance = fx.Project.SourceDb.RootGroup.CreateInstance("Game", typeof(Sedulous.Script.Pipeline.ScriptClassAsset).GetFullName(.. scope .()));
		let asset = scope Sedulous.Script.Pipeline.ScriptClassAsset();
		asset.FileName.Set("Game.as");
		asset.Language.Set("angelscript");
		Test.Assert(scriptInstance.WriteObject(asset) case .Ok);
		fx.Project.Settings.StartupScriptId = scriptInstance.Id;
		Test.Assert(fx.Project.SaveSettings() case .Ok);
		fx.Builders.Register(new Sedulous.Script.Pipeline.ScriptClassAssetBuilder());

		let distDir = PathJoin(fx.OutRoot, "dist", .. scope .());
		let stats = scope ExportStats();
		Test.Assert(ExportDriver.ExportProject(fx.Project, distDir, fx.Builders, false, stats) case .Ok);
		Test.Assert((stats.Cooked == 3) && (stats.CookFailed == 0), scope $"{stats.Cooked} cooked, {stats.CookFailed} failed");
		// The player's path: the manifest names the script by guid, the pak holds its class.
		let distRoot = scope NativeFileSystem(distDir);
		let manifest = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(distRoot, manifest, ProjectLayout.DistManifestFile) case .Ok);
		Test.Assert(manifest.StartupScriptId == scriptInstance.Id);
		SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let pak = scope PakFileSystem(PathJoin(distDir, ProjectLayout.DistContentPak, .. scope .()));
		let db = OpenDistPak(distDir, pak, binary);
		defer delete db;
		let product = db.ReadObject(manifest.StartupScriptId);
		Test.Assert(product != null, "the script class is in the pak by the source's guid");
		defer delete product;
		let record = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(product)) as Sedulous.Script.Resource.ScriptClassSource;
		Test.Assert((record != null) && (record.ClassName == "Game") && (record.Language == "angelscript"));
	}

	[Test]
	public static void AWebPresetStagesTheBrowserPlayerAndAWgslShaderPack()
	{
		// The whole web path: a Web preset, the imported Web template, the BC and ASTC
		// variant cooks, the two paks, and a WGSL only shader pack under Data.
		let fx = scope ExportProjectFixture("scratch_export_web");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		let distSrc = PathJoin(fx.OutRoot, "webdist", .. scope .());
		CreateDirectory(distSrc);
		let page = scope $"{BuildLayout.cWebPlayerBaseName}.html";
		for (let name in scope String[](page, scope $"{BuildLayout.cWebPlayerBaseName}.js", scope $"{BuildLayout.cWebPlayerBaseName}.wasm"))
		{
			let text = "web\n";
			WriteFile(PathJoin(distSrc, name, .. scope .()), .((uint8*)text.Ptr, text.Length)).IgnoreError();
		}
		let templatesRoot = PathJoin(fx.OutRoot, "templates", .. scope .());
		Test.Assert(ExportTemplates.Create(distSrc, templatesRoot, .Install) case .Ok);
		fx.Templates.Refresh(templatesRoot, fx.ToolDir);

		let preset = scope ExportPreset();
		preset.Name.Set("Web Build");
		preset.Platform.Set("Web");
		preset.OutputSubdir.Set("web");
		let result = scope ExportResult();
		let exported = ExportDriver.ExportOne(fx.Project, preset, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, result);
		Test.Assert(exported case .Ok, scope $"the web export: {exported}; the WGSL cook needs naga and tint beside the test executable");
		if (exported case .Err)
			return; // nothing below exists to read
		let dist = scope NativeFileSystem(result.OutputDir);
		Test.Assert(dist.Exists(page) && dist.Exists(scope $"{BuildLayout.cWebPlayerBaseName}.js") && dist.Exists(scope $"{BuildLayout.cWebPlayerBaseName}.wasm"), "the browser player trio");
		Test.Assert(dist.Exists("Content-bc.pak") && dist.Exists("Content-astc.pak") && !dist.Exists("Content.pak"), "the two web paks, no desktop one");
		Test.Assert(dist.Exists(ProjectLayout.DistManifestFile) && dist.Exists("Data/.dataroot") && dist.Exists("Data/Shaders/shaders.dpak"));
		let packStream = dist.Open("Data/Shaders/shaders.dpak", .Read);
		Test.Assert(packStream != null);
		defer delete packStream;
		let pack = scope Sedulous.Shaders.CookedShaderPack();
		Test.Assert(pack.Read(packStream) case .Ok);
		Test.Assert(pack.Find("tonemap", .Fragment, .None, .Wgsl) case .Ok, "WGSL for the browser");
		Test.Assert(pack.Find("tonemap", .Fragment, .None, .SpirV) case .Err, "and nothing the browser cannot use");
	}

	[Test]
	public static void CollectSceneStreamsKeysWhatTheStagerAcceptsWalkingNestedGroups()
	{
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_scene_streams", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Streams") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let root = project.SourceDb.RootGroup;
		let top = root.CreateInstance("Top", McpDocumentNames.cSceneDocument);
		let nested = root.CreateGroup("nested");
		let deep = nested.CreateInstance("Deep", McpDocumentNames.cSceneDocument);
		nested.CreateInstance("NotAScene", McpDocumentNames.cSceneDocument);

		// The stager decides: anything named "NotAScene" is declined and stays out of the map.
		let streams = scope Dictionary<Guid, List<uint8>>();
		defer { for (let entry in streams) delete entry.value; }
		ExportDriver.CollectSceneStreams(root, scope (instance, outBytes) =>
			{
				if (instance.Name == "NotAScene")
					return false;
				outBytes.Add((uint8)instance.Name.Length);
				return true;
			}, streams);
		Test.Assert(streams.Count == 2);
		Test.Assert(streams.ContainsKey(top.Id));
		Test.Assert(streams.ContainsKey(deep.Id));
		Test.Assert(streams[deep.Id].Count == 1);
	}
}
