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
using Sedulous.Runtime;
using Sedulous.VFS;
using Sedulous.VFS.Pak;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Pipeline.Core;

namespace Sedulous.Editor.Core.Tests;

/// A Tooling part that adds an export hook through the service its host offers.
class HookingPart : PluginPart
{
	public override StringView PluginId => "hooked";
	public override PluginPartKind Kind => .Tooling;

	public override void Load(PluginContext context)
	{
		if (let hooks = context.Find<ExportPluginServices>())
			hooks.AddHook("hooked", new (hookContext, outWhy) => true);
	}
}

/// A player builder over the staged one whose build leaves a symbol file beside its player, as a
/// Windows build leaves its .pdb.
class SymbolsPlayerBuilder : IPlayerBuilder
{
	public const String cSymbols = "Export.dbg";

	/// Borrowed.
	private StagedPlayerBuilder mInner;

	public this(StagedPlayerBuilder inner)
	{
		mInner = inner;
	}

	public Result<void, ErrorCode> Build(EditorProject project, ExportPreset preset, PlayerBuild outBuild, ExportProgress onProgress,
		String outRefusal)
	{
		if (mInner.Build(project, preset, outBuild, onProgress, outRefusal) case .Err(let err))
			return .Err(err);
		let text = "symbols\n";
		Test.Assert(WriteFile(PathJoin(outBuild.Directory, cSymbols, .. scope .()), .((uint8*)text.Ptr, text.Length)) case .Ok);
		outBuild.Symbols.Add(new .(cSymbols));
		return .Ok;
	}
}

/// The export driver: a project into a dist the player loads back, the closure pruned and
/// reported or not, the roots seeded, the variants per platform, the player built for the preset
/// (a stand in: StagedPlayerBuilder) and staged with the files its build left beside it and the
/// shader pack, symbols when opted in, another host's platform refused or skipped, the plugins
/// refused without templates, each player built once by Export All, and the names.
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
		let titleFontId = Guid.Create();
		fx.Project.Settings.RenderMsaaSamples = 4;
		fx.Project.Settings.UiFontIds.Add(titleFontId);
		let sheetId = Guid.Create();
		let guiSplashId = Guid.Create();
		fx.Project.Settings.GuiStyleSheetIds.Add(sheetId);
		fx.Project.Settings.GuiLoadingDocumentId = guiSplashId;
		fx.Project.Settings.RenderWidth = 640;
		fx.Project.Settings.RenderHeight = 360;
		fx.Project.Settings.RenderFit = .IntegerScale;
		fx.Project.Settings.WindowWidth = 1920;
		fx.Project.Settings.WindowHeight = 1080;
		fx.Project.Settings.WindowMode = .Borderless;
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
		// And everything else the player reads: the MSAA, the other fonts, the GUI's sheets and loading
		// screen.
		Test.Assert(manifest.RenderMsaaSamples == 4, "the MSAA");
		Test.Assert((manifest.UiFontIds.Count == 1) && (manifest.UiFontIds[0] == titleFontId), "the other UI fonts");
		Test.Assert((manifest.GuiStyleSheetIds.Count == 1) && (manifest.GuiStyleSheetIds[0] == sheetId), "the GUI's sheets");
		Test.Assert(manifest.GuiLoadingDocumentId == guiSplashId, "the GUI's loading screen");
		Test.Assert((manifest.RenderWidth == 640) && (manifest.RenderHeight == 360) && (manifest.RenderFit == .IntegerScale), "the render resolution");
		Test.Assert((manifest.WindowWidth == 1920) && (manifest.WindowHeight == 1080) && (manifest.WindowMode == .Borderless), "the window");

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

	/// The export builds the game's player first, then cooks: the player staged under the game's
	/// name, the files its build left beside it (the shader compiler's left out), the shader pack,
	/// the preset's extra file and the content, the build's band of the progress before the cook's.
	[Test]
	public static void ExportOneBuildsThePlayerAndStagesItsFilesAndShaderPackBesideTheContent()
	{
		let fx = scope ExportProjectFixture("scratch_export_one");
		let preset = ExportProjectFixture.HostPreset("Host", "host");
		defer delete preset;
		preset.AdditionalFiles.Add(new String("Project.xml"));
		let result = scope ExportResult();
		let steps = scope List<String>();
		defer { ClearAndDeleteItems(steps); }
		let fractions = scope List<float>();
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result,
			scope [&](step, fraction) => { steps.Add(new String(step)); fractions.Add(fraction); }) case .Ok, result.Refusal);
		Test.Assert(fx.Players.Builds == 1, "the player built");
		Test.Assert(result.OutputDir == PathJoin(fx.OutRoot, "host", .. scope .()));
		let dist = scope NativeFileSystem(result.OutputDir);
		Test.Assert(dist.Exists(ExportStaging.PlayerOutputName(BuildLayout.HostPlatformName, "Export", "", .. scope .())), "the player, named by the game");
		Test.Assert(!dist.Exists(BuildLayout.ExecutableName("ExportPlayer", .. scope .())), "not by its build");
		Test.Assert(dist.Exists(StagedPlayerBuilder.cLibrary), "the library its build left beside it");
		Test.Assert(!dist.Exists(StagedPlayerBuilder.cDxcLibrary), "but not the shader compiler's");
		Test.Assert(dist.Exists(BuildLayout.cThirdPartyNotices), "the notices the build carries");
		Test.Assert(dist.Exists(ProjectLayout.DistContentPak) && dist.Exists(ProjectLayout.DistManifestFile));
		Test.Assert(dist.Exists("Project.xml"), "the additional file staged by its base name");
		Test.Assert(dist.Exists("Data/Engine/Shaders/shaders.dpak") && dist.Exists("Data/.dataroot"), "the shader pack and the data root marker");
		Test.Assert(!dist.Exists(".stage-scenes"), "the staging directory removed");
		// The player, the shader pack and its marker, the library, the notices and Project.xml.
		Test.Assert(result.FilesStaged == 6, scope $"{result.FilesStaged} staged");
		Test.Assert(result.PlayerReason.StartsWith(scope $"ExportPlayer, ShippingRelease, {BuildLayout.HostPlatformName}"), result.PlayerReason);
		Test.Assert(result.Content.Cooked == 2);
		Test.Assert(!result.Pruning.Pruned);
		Test.Assert(steps[0].StartsWith("Building ExportPlayer"), steps[0]);
		Test.Assert(fractions[0] == PlayerBuild.cProgressStart);
		int cooking = -1;
		for (int i < steps.Count)
		{
			if (steps[i].StartsWith("Cooking") && (cooking < 0))
				cooking = i;
		}
		Test.Assert(cooking > 0, "the cook after the build");
		Test.Assert(fractions[cooking] >= PlayerBuild.cProgressEnd, "and its progress after the build's band");
		Test.Assert(steps[steps.Count - 1] == "Done");
	}

	[Test]
	public static void ExportOneWithContentOnlyStagesTheContentAndTheShaderPackBuildingNoPlayer()
	{
		let fx = scope ExportProjectFixture("scratch_export_content_only");
		let preset = ExportProjectFixture.HostPreset("Android", "android");
		defer delete preset;
		preset.Platform.Set("Android64");
		let result = scope ExportResult();
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result,
			null, true, null, null, null, null, null, true) case .Ok);
		Test.Assert(fx.Players.Builds == 0, "no player built");

		// What the game reads, and no player: the platform's one pak, the settings and the shader pack.
		let dist = scope NativeFileSystem(result.OutputDir);
		Test.Assert(dist.Exists(ProjectLayout.DistContentPak) && dist.Exists(ProjectLayout.DistManifestFile));
		Test.Assert(dist.Exists("Data/Engine/Shaders/shaders.dpak"));
		Test.Assert(!dist.Exists(BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, .. scope .())), "no player");
		Test.Assert(result.PlayerReason.IsEmpty);
		// Its content is cooked for the platform's target, beside the host's Cooked/.
		Test.Assert(DirectoryExists(PathJoin(fx.ProjectDir, "Cooked-android", .. scope .())));

		// Without contentOnly the same preset needs a player for Android, which is not built here.
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false) case .Err);
		Test.Assert(fx.Players.Builds == 0);
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
		Test.Assert(ExportDriver.ExportOne(fx.Project, pruned, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result, null, true, null, fx.Scanner) case .Ok);
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
		Test.Assert(ExportDriver.ExportOne(fx.Project, full, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, fullResult, null, true, null, fx.Scanner) case .Ok);
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
		Test.Assert(ExportDriver.ExportOne(fx.Project, blind, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, blindResult) case .Ok);
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

	/// The engine GUI's sheets and its loading screen are the manifest's too: an export carries
	/// what they name, as it does the UI's fonts and loading screen.
	[Test]
	public static void CollectExportRootsSeedsTheGuisSheetsAndItsLoadingScreen()
	{
		let fx = scope ExportProjectFixture("scratch_export_gui_roots");
		fx.Project.Settings.GuiStyleSheetIds.Add(fx.UnreferencedMeshId);
		fx.Project.Settings.GuiLoadingDocumentId = fx.ReferencedMeshId;
		let roots = scope List<ExportRoot>();
		defer { ClearAndDeleteItems(roots); }
		ExportDriver.CollectExportRoots(fx.Project, roots);
		Test.Assert(roots.Count == 3, scope $"{roots.Count} roots");
		Test.Assert((roots[1].Id == fx.UnreferencedMeshId) && (roots[1].Reason == .ManifestDefault), "a sheet");
		Test.Assert((roots[2].Id == fx.ReferencedMeshId) && (roots[2].Reason == .ManifestDefault), "the GUI's loading screen");
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
		Test.Assert((web[0].TargetId == "web-bc") && (web[1].TargetId == "web-astc"));
		// Android: one Content.pak, cooked for the "android" target (ASTC) into a sibling Cooked-android/.
		let android = scope List<ContentVariant>();
		defer { ClearAndDeleteItems(android); }
		ExportDriver.VariantsForPlatform(fx.Project, "Android64", android);
		Test.Assert(android.Count == 1);
		Test.Assert((android[0].Key == "android") && (android[0].PakName == "Content.pak") && android[0].CookedDir.EndsWith("Cooked-android"));
		Test.Assert(android[0].TargetId == "android");
		Test.Assert(CookTarget.For("android").Astc && !CookTarget.For("android").Bc);
	}

	/// A desktop platform this host does not build for: Win64 on Linux, Linux64 on Windows.
	private static StringView OtherHost => (BuildLayout.HostPlatformName == "Win64") ? "Linux64" : "Win64";

	/// The player is named by the preset when it names one, else by the game; its symbols ship
	/// only when the preset asks for them.
	[Test]
	public static void ThePresetNamesThePlayerAndItsSymbolsStageOnlyWhenOptedIn()
	{
		let fx = scope ExportProjectFixture("scratch_export_symbols");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		let players = scope SymbolsPlayerBuilder(fx.Players);

		let named = ExportProjectFixture.HostPreset("Named", "named");
		defer delete named;
		named.PlayerName.Set("MyGame");
		let result = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, named, players, fx.Builders, fx.OutRoot, dataRoot, false, result) case .Ok, result.Refusal);
		let dist = scope NativeFileSystem(result.OutputDir);
		Test.Assert(dist.Exists(ExportStaging.PlayerOutputName(BuildLayout.HostPlatformName, "MyGame", "", .. scope .())), "the preset's player name");
		Test.Assert(!dist.Exists(ExportStaging.PlayerOutputName(BuildLayout.HostPlatformName, "Export", "", .. scope .())), "not the game's");
		Test.Assert(!dist.Exists(SymbolsPlayerBuilder.cSymbols), "no symbols unless asked");

		let withSymbols = ExportProjectFixture.HostPreset("Symbols", "symbols");
		defer delete withSymbols;
		withSymbols.StageSymbols = true;
		let symbolResult = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, withSymbols, players, fx.Builders, fx.OutRoot, dataRoot, false, symbolResult) case .Ok, symbolResult.Refusal);
		Test.Assert(FileExists(PathJoin(symbolResult.OutputDir, SymbolsPlayerBuilder.cSymbols, .. scope .())), "the symbols, asked for");
		Test.Assert(FileExists(PathJoin(symbolResult.OutputDir, ExportStaging.PlayerOutputName(BuildLayout.HostPlatformName, "Export", "", .. scope .()), .. scope .())), "the game's name");
	}

	/// A desktop platform's player builds on its own host: another host's preset is refused before
	/// anything builds or is written, saying where to export it. So is a config no player is built
	/// in.
	[Test]
	public static void AnotherHostsPlatformIsRefusedBeforeAnythingBuilds()
	{
		let fx = scope ExportProjectFixture("scratch_export_elsewhere");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		let elsewhere = ExportProjectFixture.HostPreset("Elsewhere", "elsewhere");
		defer delete elsewhere;
		elsewhere.Platform.Set(OtherHost);
		let result = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, elsewhere, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result) case .Err(.NotSupported));
		Test.Assert(result.Refusal.Contains(scope $"a {OtherHost} player builds on") && result.Refusal.Contains("export this preset there"), result.Refusal);
		Test.Assert(fx.Players.Builds == 0, "nothing built");
		Test.Assert(!DirectoryExists(PathJoin(fx.OutRoot, "elsewhere", .. scope .())), "nothing written");
		Test.Assert(ExportDriver.BuildsOnAnotherHost(OtherHost) && !ExportDriver.BuildsOnAnotherHost(BuildLayout.HostPlatformName)
			&& !ExportDriver.BuildsOnAnotherHost("Web"));

		let testConfig = ExportProjectFixture.HostPreset("Tests", "tests");
		defer delete testConfig;
		testConfig.Config.Set("Test");
		let refused = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, testConfig, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, refused) case .Err(.InvalidArgument));
		Test.Assert(refused.Refusal.Contains("test runner"), refused.Refusal);
		Test.Assert((fx.Players.Builds == 0) && !DirectoryExists(PathJoin(fx.OutRoot, "tests", .. scope .())));
	}

	/// A plugin package's manifest, plugin `id` supporting `platform`, into `dir` (made), with the
	/// deploy file `deploy` listed and written beside it (none for empty).
	private static void WritePackage(StringView dir, StringView id, StringView platform, StringView deploy)
	{
		CreateDirectory(dir);
		let manifest = scope PluginManifest();
		manifest.Id.Set(id);
		manifest.Version.Set("1.0.0");
		manifest.EngineVersion.Set("0.1");
		let target = new PluginPlatform();
		target.Platform.Set(platform);
		if (!deploy.IsEmpty)
			target.Deploy.Add(new .(deploy));
		manifest.Platforms.Add(target);
		let xml = manifest.Write(.. scope .());
		Test.Assert(WriteFile(PathJoin(dir, "Plugin.xml", .. scope .()), .((uint8*)xml.Ptr, xml.Length)) case .Ok);
		if (!deploy.IsEmpty)
		{
			let lib = "so\n";
			Test.Assert(WriteFile(PathJoin(dir, deploy, .. scope .()), .((uint8*)lib.Ptr, lib.Length)) case .Ok);
		}
	}

	/// The project's plugins, with no template to carry them: a package of the project's own
	/// ships, its deploy file beside the player; a package with no manifest, a plugin enabled on a
	/// platform it does not support and an engine plugin in no package of the SDK are refused
	/// before anything builds or is written, each named. A plugin not enabled on the platform asks
	/// nothing.
	[Test]
	public static void ThePluginsShipFromTheirPackagesOrRefuseBeforeTheBuild()
	{
		let fx = scope ExportProjectFixture("scratch_export_plugins");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		let preset = ExportProjectFixture.HostPreset("Host", "host");
		defer delete preset;
		let entry = new EnabledPlugin();
		entry.Id.Set("meter");
		entry.Path.Set("Plugins/Meter");
		fx.Project.Settings.Plugins.Add(entry);
		let package = PathJoin(fx.ProjectDir, "Plugins/Meter", .. scope .());
		CreateDirectory(PathJoin(fx.ProjectDir, "Plugins", .. scope .()));

		// Its package has no manifest.
		let missing = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, missing) case .Err(.InvalidArgument));
		Test.Assert(missing.Refusal.Contains("plugin 'meter'"), missing.Refusal);
		Test.Assert((fx.Players.Builds == 0) && !DirectoryExists(PathJoin(fx.OutRoot, "host", .. scope .())), "refused before anything builds or is written");

		WritePackage(package, "meter", BuildLayout.HostPlatformName, "libmeter.so");
		let result = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result) case .Ok, result.Refusal);
		Test.Assert(FileExists(PathJoin(result.OutputDir, "libmeter.so", .. scope .())), "its deploy file beside the player");

		// Enabled here, which the plugin does not support.
		WritePackage(package, "meter", "Web", "");
		entry.Platforms.Add(new .(BuildLayout.HostPlatformName));
		let unsupported = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, unsupported) case .Err(.InvalidArgument));
		Test.Assert(unsupported.Refusal.Contains("which it does not support"), unsupported.Refusal);
		Test.Assert(fx.Players.Builds == 1, "refused before the build");
		// Not enabled on this platform: nothing asked, nothing deployed.
		ClearAndDeleteItems!(entry.Platforms);
		entry.Platforms.Add(new .("Web"));
		let elsewhere = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, elsewhere) case .Ok, elsewhere.Refusal);

		// An engine plugin (no path) that no package of the SDK's Code/Plugins is.
		ClearAndDeleteItems!(entry.Platforms);
		entry.Path.Clear();
		entry.Id.Set("no-such-plugin");
		let lacking = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, lacking) case .Err(.InvalidArgument));
		Test.Assert(lacking.Refusal.Contains("plugin 'no-such-plugin'") && lacking.Refusal.Contains(ProjectBuild.cSdkPluginsDir), lacking.Refusal);
		Test.Assert(fx.Players.Builds == 2, "refused before the build");
	}

	/// A plugin's export hooks run over the staged dist, in order, the dist there to read; one that
	/// fails fails the export with its name and reason.
	[Test]
	public static void ThePluginsExportHooksRunOverTheStagedDistAndAFailureFailsTheExport()
	{
		let fx = scope ExportProjectFixture("scratch_export_hooks");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		let preset = ExportProjectFixture.HostPreset("Host", "host");
		defer delete preset;
		let hooks = scope ExportPluginServices();
		let seen = scope String();
		Test.Assert(hooks.AddHook("probe", new [&] (context, outWhy) =>
			{
				seen.Set(context.OutputDir);
				return FileExists(PathJoin(context.OutputDir, ProjectLayout.DistContentPak, .. scope .()));
			}));
		let result = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result,
			null, true, null, null, null, hooks) case .Ok, result.Refusal);
		Test.Assert(seen == result.OutputDir, "run over the staged dist");
		Test.Assert(!hooks.AddHook("none", null));
		Test.Assert(hooks.AddHook("refuser", new (context, outWhy) => { outWhy.Set("no signing key"); return false; }));
		let failed = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, failed,
			null, true, null, null, null, hooks) case .Err(.Internal));
		Test.Assert(failed.Refusal == "export hook refuser: no signing key", failed.Refusal);
	}

	/// A Tooling part's hooks leave with its plugin: the service records them against the part's
	/// load, and the host's unload reverses them.
	[Test]
	public static void APluginsExportHooksLeaveWithIt()
	{
		let hooks = scope ExportPluginServices();
		let subsystems = scope Sedulous.Runtime.SubsystemManager();
		let host = scope PluginHost(subsystems, .Export, EngineVersion.String);
		Test.Assert(hooks.Attach(host));
		let manifest = scope PluginManifest();
		manifest.Id.Set("hooked");
		manifest.Version.Set("1.0.0");
		manifest.EngineVersion.Set(EngineVersion.String);
		let part = new PluginManifestPart();
		part.Kind.Set("Tooling");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		let hooking = scope HookingPart();
		Test.Assert(host.AddLinked(manifest.Write(.. scope .()), scope PluginPart[](hooking)) case .Ok);
		host.Load(scope StringView[]("hooked"), scope .());
		Test.Assert(hooks.Count == 1);
		host.Unload();
		Test.Assert(hooks.Count == 0);
	}

	/// Every preset in turn, the progress scoped to each; the presets sharing a (platform, config)
	/// build their player once; another host's preset is skipped and counted, and fails nothing;
	/// one that fails fails the whole.
	[Test]
	public static void ExportAllBuildsEachPlayerOnceSkipsAnotherHostsAndFailsWhenOneFails()
	{
		let fx = scope ExportProjectFixture("scratch_export_all");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		let presets = scope List<ExportPreset>();
		defer { ClearAndDeleteItems(presets); }
		presets.Add(ExportProjectFixture.HostPreset("A", "a"));
		presets.Add(ExportProjectFixture.HostPreset("B", "b"));
		let steps = scope List<String>();
		defer { ClearAndDeleteItems(steps); }
		let summary = scope ExportAllSummary();
		Test.Assert(ExportDriver.ExportAll(fx.Project, presets, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false,
			scope [&](step, fraction) => { steps.Add(new String(step)); }, true, null, null, null, null, null, summary) case .Ok);
		Test.Assert(fx.Players.Builds == 1, "one build for the two presets that share it");
		let player = ExportStaging.PlayerOutputName(BuildLayout.HostPlatformName, "Export", "", .. scope .());
		Test.Assert(FileExists(PathJoin(PathJoin(fx.OutRoot, "a", .. scope .()), player, .. scope .()))
			&& FileExists(PathJoin(PathJoin(fx.OutRoot, "b", .. scope .()), player, .. scope .())), "each dist has it");
		Test.Assert(steps[0].StartsWith("A: "), "the progress scoped to the preset");
		Test.Assert((summary.Exported == 2) && (summary.Failed == 0) && summary.Skipped.IsEmpty);

		// Another config builds its own; another host's preset is skipped, counted, written nowhere.
		let debug = ExportProjectFixture.HostPreset("D", "d");
		debug.Config.Set("Debug");
		presets.Add(debug);
		let elsewhere = ExportProjectFixture.HostPreset("E", "e");
		elsewhere.Platform.Set(OtherHost);
		presets.Add(elsewhere);
		let again = scope ExportAllSummary();
		Test.Assert(ExportDriver.ExportAll(fx.Project, presets, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false,
			null, true, null, null, null, null, null, again) case .Ok);
		Test.Assert(fx.Players.Builds == 3, scope $"{fx.Players.Builds} builds: Release again for this run, and Debug");
		Test.Assert((again.Exported == 3) && (again.Failed == 0), scope $"{again.Exported} exported, {again.Failed} failed");
		Test.Assert((again.Skipped.Count == 1) && (again.Skipped[0] == "E"));
		Test.Assert(!DirectoryExists(PathJoin(fx.OutRoot, "e", .. scope .())));

		// One that fails fails the whole, the rest exported.
		let broken = ExportProjectFixture.HostPreset("C", "c");
		broken.Config.Set("Test");
		presets.Add(broken);
		let failed = scope ExportAllSummary();
		Test.Assert(ExportDriver.ExportAll(fx.Project, presets, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false,
			null, true, null, null, null, null, null, failed) case .Err);
		Test.Assert((failed.Failed == 1) && (failed.Exported == 3) && (failed.Skipped.Count == 1));
	}

	[Test]
	public static void TheNamesAreTargetPlatformAwareAndFilesystemSafe()
	{
		Test.Assert(ExportStaging.PlayerOutputName("Win64", "", "Sedulous.Engine.Player.Desktop.exe", .. scope .()) == "Sedulous.Engine.Player.Desktop.exe");
		Test.Assert(ExportStaging.PlayerOutputName("Win64", "MyGame", "Player.exe", .. scope .()) == "MyGame.exe", "a Windows target gets .exe");
		Test.Assert(ExportStaging.PlayerOutputName("Linux64", "MyGame", "Player", .. scope .()) == "MyGame");
		// The web player is its page: a renamed one keeps .html, or the browser downloads it.
		Test.Assert(ExportStaging.PlayerOutputName("Web", "SkyHopper", "Sedulous.Engine.Player.Web.html", .. scope .()) == "SkyHopper.html");
		Test.Assert(ExportStaging.PlayerOutputName("Web", "SkyHopper.html", "Sedulous.Engine.Player.Web.html", .. scope .()) == "SkyHopper.html");
		Test.Assert(ExportStaging.PlayerOutputName("Web", "", "Sedulous.Engine.Player.Web.html", .. scope .()) == "Sedulous.Engine.Player.Web.html");
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
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result, null, true, null, null, reachable) case .Ok);
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
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result, null, true, null, fx.Scanner) case .Ok);
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

	/// A preset's own render resolution replaces the project's in its dist, and leaves the
	/// window it does not override as the project had it.
	[Test]
	public static void APresetsDisplayOverridesTheProjectsInItsDist()
	{
		let dir = "scratch_export_display";
		RemoveDirectoryRecursive(dir);
		Test.Assert(CreateDirectory(dir));
		defer RemoveDirectoryRecursive(dir);
		{
			let project = scope ProjectSettings();
			project.RenderWidth = 1280;
			project.RenderHeight = 720;
			project.WindowWidth = 1600;
			project.WindowHeight = 900;
			Test.Assert(ProjectManifest.Save(scope NativeFileSystem(dir), project, ProjectLayout.DistManifestFile) case .Ok);
		}

		let preset = scope ExportPreset();
		Test.Assert(ExportDriver.ApplyPresetDisplay(dir, preset) case .Ok, "overriding nothing changes nothing");
		preset.OverridesRender = true;
		preset.RenderWidth = 1280;
		preset.RenderHeight = 800;
		preset.RenderFit = .Crop;
		preset.WindowMode = .Fullscreen; // not overridden, so not applied
		Test.Assert(ExportDriver.ApplyPresetDisplay(dir, preset) case .Ok);

		let dist = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(scope NativeFileSystem(dir), dist, ProjectLayout.DistManifestFile) case .Ok);
		Test.Assert((dist.RenderWidth == 1280) && (dist.RenderHeight == 800) && (dist.RenderFit == .Crop), "the preset's render resolution");
		Test.Assert((dist.WindowWidth == 1600) && (dist.WindowHeight == 900) && (dist.WindowMode == .Windowed), "the project's window");
		Test.Assert(dist.Orientation == .Any, "not overridden: the project's");

		// And the orientation: a phone-facing preset holds the game landscape.
		preset.OverridesRender = false;
		preset.OverridesOrientation = true;
		preset.Orientation = .Landscape;
		Test.Assert(ExportDriver.ApplyPresetDisplay(dir, preset) case .Ok);
		let turned = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(scope NativeFileSystem(dir), turned, ProjectLayout.DistManifestFile) case .Ok);
		Test.Assert(turned.Orientation == .Landscape, "the preset's orientation");
		Test.Assert(turned.RenderHeight == 800, "the render size applied before stays");
	}

	[Test]
	public static void AWebPresetStagesTheBrowserPlayerAndAWgslShaderPack()
	{
		// The whole web path: a Web preset, its player's page built (a stand in), the BC and ASTC
		// variant cooks, the two paks, and a WGSL only shader pack under Data.
		let fx = scope ExportProjectFixture("scratch_export_web");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());

		let preset = scope ExportPreset();
		preset.Name.Set("Web Build");
		preset.Platform.Set("Web");
		preset.OutputSubdir.Set("web");
		let result = scope ExportResult();
		let exported = ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result);
		Test.Assert(exported case .Ok, scope $"the web export: {exported} ({result.Refusal}); the WGSL cook needs naga and tint beside the test executable");
		if (exported case .Err)
			return; // nothing below exists to read
		Test.Assert(result.PlayerReason.StartsWith("ExportPlayerWeb, ShippingRelease, wasm32"), result.PlayerReason);
		let dist = scope NativeFileSystem(result.OutputDir);
		// The page renamed for the game; the .js and .wasm it refers to keep their names.
		Test.Assert(dist.Exists("Export.html") && dist.Exists("ExportPlayerWeb.js") && dist.Exists("ExportPlayerWeb.wasm"), "the browser player trio");
		Test.Assert(dist.Exists("serve.py") && dist.Exists(BuildLayout.cThirdPartyNotices), "and what its build left beside the page");
		Test.Assert(dist.Exists("Content-bc.pak") && dist.Exists("Content-astc.pak") && !dist.Exists("Content.pak"), "the two web paks, no desktop one");
		Test.Assert(dist.Exists(ProjectLayout.DistManifestFile) && dist.Exists("Data/.dataroot") && dist.Exists("Data/Engine/Shaders/shaders.dpak"));
		let packStream = dist.Open("Data/Engine/Shaders/shaders.dpak", .Read);
		Test.Assert(packStream != null);
		defer delete packStream;
		let pack = scope Sedulous.Shaders.CookedShaderPack();
		Test.Assert(pack.Read(packStream) case .Ok);
		Test.Assert(pack.Find("tonemap", .Fragment, .None, .Wgsl) case .Ok, "WGSL for the browser");
		Test.Assert(pack.Find("tonemap", .Fragment, .None, .SpirV) case .Err, "and nothing the browser cannot use");
	}

	/// A surface shader is three programs: the dist's pack holds the depth and pick programs'
	/// variants beside the forward one's, and the dist's product keeps none of their HLSL.
	[Test]
	public static void ASurfaceShaderShipsItsDepthAndPickProgramsInTheDistPack()
	{
		{
			let probe = scope Sedulous.Shaders.ShaderCompiler();
			if (probe.Initialize() case .Err) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		}
		let fx = scope ExportProjectFixture("scratch_export_surface");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		Sedulous.Shaders.Pipeline.ShadersPipeline.RegisterAll();
		Sedulous.Shaders.Resource.ShaderResources.RegisterAll();
		{
			let sources = scope NativeFileSystem(fx.Project.SourcesRoot(.. scope .()));
			let text = """
				// surface: lit
				properties
				{
				    float Height = 0.2;
				}
				void Surface(SurfaceInput input, inout SurfaceOutput surface) {
				    surface.albedo = float3(0.1, 0.4, 0.8);
				}
				void Vertex(inout VertexInput v) {
				    v.position.y += sin(v.position.x + Time()) * Height;
				}
				""";
			Test.Assert(sources.Save("waves.hlsl", .((uint8*)text.Ptr, text.Length)) case .Ok);
			let asset = scope Sedulous.Shaders.Pipeline.ShaderAsset();
			Sedulous.Shaders.Pipeline.ShaderImporter.Import("waves", "waves.hlsl", asset);
			let instance = fx.Project.SourceDb.RootGroup.CreateInstance("waves", typeof(Sedulous.Shaders.Pipeline.ShaderAsset).GetFullName(.. scope .()));
			Test.Assert((instance != null) && (instance.WriteObject(asset) case .Ok));
		}
		fx.Builders.Register(new Sedulous.Shaders.Pipeline.ShaderAssetBuilder(dataRoot));

		let preset = ExportProjectFixture.HostPreset("dist", "dist");
		defer delete preset;
		let result = scope ExportResult();
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result) case .Ok);
		Test.Assert(result.Content.CookFailed == 0);

		let packStream = scope NativeFileSystem(result.OutputDir).Open("Data/Engine/Shaders/shaders.dpak", .Read);
		Test.Assert(packStream != null);
		defer delete packStream;
		let pack = scope Sedulous.Shaders.CookedShaderPack();
		Test.Assert(pack.Read(packStream) case .Ok);
		Test.Assert(pack.Find("waves", .Fragment, .GBuffer, .SpirV) case .Ok);
		Test.Assert(pack.Find("waves.depth", .Vertex, .Instanced, .SpirV) case .Ok);
		Test.Assert(pack.Find("waves.depth", .Fragment, .AlphaTest, .SpirV) case .Ok);
		Test.Assert(pack.Find("waves.pick", .Vertex, .Skinned, .SpirV) case .Ok);

		SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let pak = scope PakFileSystem(PathJoin(result.OutputDir, ProjectLayout.DistContentPak, .. scope .()));
		let db = OpenDistPak(result.OutputDir, pak, binary);
		defer delete db;
		let product = db.GetInstanceByPath("waves");
		Test.Assert(product != null);
		let object = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(product.ReadObject()));
		defer delete object;
		let source = object as Sedulous.Shaders.Resource.ShaderSource;
		Test.Assert(source != null);
		Test.Assert(source.DepthProgramsAlways, "it moves its vertices");
		let programs = scope List<Sedulous.Shaders.Resource.ShaderProgram>();
		defer { ClearAndDeleteItems!(programs); }
		source.GetPrograms(programs);
		Test.Assert(programs.Count == 3);
		for (let program in programs)
			Test.Assert(program.VertexSource.IsEmpty && program.FragmentSource.IsEmpty, "no HLSL in the dist");
	}

	/// A project's custom shader ships as bytecode: the export cooks both its stages, every
	/// declared variant under its entry point, into the dist's shader pack beside the engine's,
	/// so a compiler free player draws it; the dist's product carries no HLSL unless the preset
	/// keeps it.
	[Test]
	public static void ACustomShaderShipsAsBytecodeInTheDistPackItsSourceLeftOut()
	{
		{
			let probe = scope Sedulous.Shaders.ShaderCompiler();
			if (probe.Initialize() case .Err) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		}
		let fx = scope ExportProjectFixture("scratch_export_shader");
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		Sedulous.Shaders.Pipeline.ShadersPipeline.RegisterAll();
		Sedulous.Shaders.Resource.ShaderResources.RegisterAll();
		{
			let sources = scope NativeFileSystem(fx.Project.SourcesRoot(.. scope .()));
			let text = """
				// variants(fragment): GBUFFER
				properties
				{
				    Color Tint = (1, 0.5, 0);
				}
				float4 VSMain(uint id : SV_VertexID) : SV_Position {
				    return float4(0, 0, 0, 1);
				}
				float4 PSMain() : SV_Target0 { return Tint; }
				""";
			Test.Assert(sources.Save("glow.hlsl", .((uint8*)text.Ptr, text.Length)) case .Ok);
			let asset = scope Sedulous.Shaders.Pipeline.ShaderAsset();
			Sedulous.Shaders.Pipeline.ShaderImporter.Import("glow", "glow.hlsl", asset);
			let instance = fx.Project.SourceDb.RootGroup.CreateInstance("glow", typeof(Sedulous.Shaders.Pipeline.ShaderAsset).GetFullName(.. scope .()));
			Test.Assert((instance != null) && (instance.WriteObject(asset) case .Ok));
		}
		fx.Builders.Register(new Sedulous.Shaders.Pipeline.ShaderAssetBuilder(dataRoot));

		String ExportWith(bool includeSource, StringView subdir)
		{
			let preset = ExportProjectFixture.HostPreset(subdir, subdir);
			defer delete preset;
			preset.IncludeShaderSource = includeSource;
			let result = scope ExportResult();
			Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Players, fx.Builders, fx.OutRoot, dataRoot, false, result) case .Ok);
			Test.Assert(result.Content.CookFailed == 0);
			Test.Assert(result.Content.Shaders.Count == 1);
			return new String(result.OutputDir);
		}

		SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		// Whether the dist's pak holds the shader's HLSL anywhere, in any entry: a reader finds
		// the stripped copy, but the original product must not ship beside it either.
		bool PakHasSource(StringView distDir)
		{
			let bytes = scope List<uint8>();
			Test.Assert(ReadFile(PathJoin(distDir, ProjectLayout.DistContentPak, .. scope .()), bytes) case .Ok);
			let needle = "return Tint;";
			for (int i = 0; i + needle.Length <= bytes.Count; i++)
				if (Internal.MemCmp(&bytes[i], needle.Ptr, needle.Length) == 0)
					return true;
			return false;
		}
		Sedulous.Shaders.Resource.ShaderSource ReadGlow(StringView distDir)
		{
			let pak = scope PakFileSystem(PathJoin(distDir, ProjectLayout.DistContentPak, .. scope .()));
			let db = OpenDistPak(distDir, pak, binary);
			defer delete db;
			let product = db.GetInstanceByPath("glow");
			Test.Assert(product != null);
			let object = product.ReadObject();
			return Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Sedulous.Shaders.Resource.ShaderSource;
		}

		// The default: bytecode only.
		let stripped = ExportWith(false, "stripped");
		defer delete stripped;
		{
			let packStream = scope NativeFileSystem(stripped).Open("Data/Engine/Shaders/shaders.dpak", .Read);
			Test.Assert(packStream != null);
			defer delete packStream;
			let pack = scope Sedulous.Shaders.CookedShaderPack();
			Test.Assert(pack.Read(packStream) case .Ok);
			Test.Assert(pack.EntryPoint("glow", .Vertex) == "VSMain");
			Test.Assert(pack.EntryPoint("glow", .Fragment) == "PSMain");
			Test.Assert(pack.Find("glow", .Fragment, .GBuffer, .SpirV) case .Ok);
			Test.Assert(pack.Find("glow", .Fragment, .None, .SpirV) case .Ok);
			Test.Assert(pack.Find("forward", .Fragment, .None, .SpirV) case .Ok, "the engine's");

			let source = ReadGlow(stripped);
			Test.Assert(source != null);
			defer delete source;
			Test.Assert(source.VertexSource.IsEmpty && source.FragmentSource.IsEmpty, "no HLSL in the dist");
			Test.Assert(source.FragmentEntryPoint == "PSMain", "the rest of the product stays");
			Test.Assert(source.FragmentVariantMask == (uint32)Sedulous.Shaders.ShaderFlags.GBuffer);
			Test.Assert(source.PropertyNames.Count == 1);
			Test.Assert(!PakHasSource(stripped), "the original product does not ship beside the stripped one");
		}
		// The project's own product keeps its source: the editor compiles from it.
		{
			let object = fx.Project.CookedDb.GetInstanceByPath("glow").ReadObject();
			let source = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Sedulous.Shaders.Resource.ShaderSource;
			Test.Assert(source != null);
			defer delete source;
			Test.Assert(!source.FragmentSource.IsEmpty);
		}

		// The preset keeps the source.
		let kept = ExportWith(true, "kept");
		defer delete kept;
		{
			let source = ReadGlow(kept);
			Test.Assert(source != null);
			defer delete source;
			Test.Assert(!source.FragmentSource.IsEmpty);
			Test.Assert(PakHasSource(kept));
		}
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
