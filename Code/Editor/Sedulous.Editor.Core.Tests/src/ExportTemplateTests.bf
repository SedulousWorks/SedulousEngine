using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// The export presets, templates and roots: the files round trip and refuse another data
/// version, the host synthesizes from a player directory, the registry resolves by id, by
/// platform and config with the host as the fallback, bundles create, import and remove,
/// and the roots set toggles idempotently.
static class ExportTemplateTests
{
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
		CreateDirectory(outPath);
	}

	private static void SaveText(StringView dir, StringView name, StringView text)
	{
		let path = PathJoin(dir, name, .. scope .());
		CreateDirectory(PathParent(path, .. scope .()));
		WriteFile(path, .((uint8*)text.Ptr, text.Length)).IgnoreError();
	}

	private static void ForeignPlatform(String outName) => outName.Set((BuildLayout.HostPlatformName == "Win64") ? "Linux64" : "Win64");

	[Test]
	public static void ThePresetSetRoundTripsThroughExportPresetsXml()
	{
		let dir = Scratch("scratch_presets", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let root = scope NativeFileSystem(dir);
		let absent = scope ExportPresetSet();
		Test.Assert(ExportPresetsFile.Load(root, absent) case .Err(.NotFound));

		let defaults = scope ExportPresetSet();
		ExportPresetsFile.Defaults(defaults);
		Test.Assert((defaults.Presets.Count == 1) && (defaults.Presets[0].Platform == BuildLayout.HostPlatformName) && defaults.Presets[0].TemplateId.IsEmpty);

		let written = scope ExportPresetSet();
		let a = new ExportPreset();
		a.Name.Set("Linux Desktop");
		a.Platform.Set("Linux64");
		a.OutputSubdir.Set("Linux64");
		let b = new ExportPreset();
		b.Name.Set("Windows Desktop");
		b.Platform.Set("Win64");
		b.Config.Set("Debug");
		b.StageSymbols = true;
		b.PruneToReachable = true;
		b.TemplateId.Set("sedulous-win64-0.1.0");
		b.PlayerName.Set("MyGame.exe");
		b.OutputSubdir.Set("Win64");
		b.AdditionalFiles.Add(new String("icon.ico"));
		b.AdditionalFiles.Add(new String("config.xml"));
		written.Presets.Add(a);
		written.Presets.Add(b);
		Test.Assert(ExportPresetsFile.Save(root, written) case .Ok);

		let loaded = scope ExportPresetSet();
		Test.Assert(ExportPresetsFile.Load(root, loaded) case .Ok);
		Test.Assert(loaded.Presets.Count == 2);
		Test.Assert((loaded.Presets[0].Name == "Linux Desktop") && loaded.Presets[0].TemplateId.IsEmpty && loaded.Presets[0].PlayerName.IsEmpty && !loaded.Presets[0].PruneToReachable);
		let win = loaded.Find("Windows Desktop");
		Test.Assert(win != null);
		Test.Assert((win.Platform == "Win64") && (win.Config == "Debug") && win.StageSymbols && win.PruneToReachable);
		Test.Assert((win.TemplateId == "sedulous-win64-0.1.0") && (win.PlayerName == "MyGame.exe"));
		Test.Assert((win.AdditionalFiles.Count == 2) && (win.AdditionalFiles[0] == "icon.ico") && (win.AdditionalFiles[1] == "config.xml"));
		Test.Assert(loaded.Find("nope") == null);
	}

	[Test]
	public static void AnotherDataVersionIsRefusedNotDefaulted()
	{
		let dir = Scratch("scratch_presets_v1", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let root = scope NativeFileSystem(dir);
		// A file saved at the current version, its version rewritten: the envelope refuses.
		let written = scope ExportPresetSet();
		let preset = new ExportPreset();
		preset.Name.Set("Legacy");
		written.Presets.Add(preset);
		Test.Assert(ExportPresetsFile.Save(root, written) case .Ok);
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(dir, ExportPresetsFile.cFileName, .. scope .()), bytes) case .Ok);
		let text = scope String(StringView((char8*)bytes.Ptr, bytes.Count));
		let marker = "<u32 name=\"version\">";
		let at = text.IndexOf(marker);
		Test.Assert(at >= 0);
		let close = text.IndexOf('<', at + marker.Length);
		text.Remove(at + marker.Length, close - (at + marker.Length));
		text.Insert(at + marker.Length, "1");
		SaveText(dir, ExportPresetsFile.cFileName, text);
		let loaded = scope ExportPresetSet();
		Test.Assert(ExportPresetsFile.Load(root, loaded) case .Err);
		// The same for a template manifest.
		let template = scope ExportTemplate();
		template.Id.Set("sample-legacy");
		Test.Assert(ExportTemplates.SaveManifest(root, template) case .Ok);
		bytes.Clear();
		Test.Assert(ReadFile(PathJoin(dir, ExportTemplates.cManifestFile, .. scope .()), bytes) case .Ok);
		text.Set(StringView((char8*)bytes.Ptr, bytes.Count));
		let at2 = text.IndexOf(marker);
		let close2 = text.IndexOf('<', at2 + marker.Length);
		text.Remove(at2 + marker.Length, close2 - (at2 + marker.Length));
		text.Insert(at2 + marker.Length, "1");
		SaveText(dir, ExportTemplates.cManifestFile, text);
		Test.Assert(ExportTemplates.LoadManifest(root, scope ExportTemplate()) case .Err);
	}

	[Test]
	public static void TemplateXmlRoundTripsAndTheHostSynthesizesFromThePlayerDirectory()
	{
		let dir = Scratch("scratch_template", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let root = scope NativeFileSystem(dir);
		let t = scope ExportTemplate();
		t.Id.Set("sedulous-win64-release-0.1.0");
		t.Name.Set("Windows Desktop Release 0.1.0");
		t.Platform.Set("Win64");
		t.Config.Set("Release");
		t.Compiler.Set("Beef");
		t.EngineVersion.Set("0.1.0");
		t.PlayerBinary.Set("Sedulous.Engine.Player.Desktop.exe");
		t.Sidecars.Add(new String("SDL3.dll"));
		t.Sidecars.Add(new String("dxcompiler.dll"));
		t.Symbols.Add(new String("Sedulous.Engine.Player.Desktop.pdb"));
		Test.Assert(ExportTemplates.SaveManifest(root, t) case .Ok);
		let loaded = scope ExportTemplate();
		Test.Assert(ExportTemplates.LoadManifest(root, loaded) case .Ok);
		Test.Assert((loaded.Id == "sedulous-win64-release-0.1.0") && (loaded.Platform == "Win64") && (loaded.Config == "Release") && (loaded.Compiler == "Beef"));
		Test.Assert(loaded.PlayerBinary == "Sedulous.Engine.Player.Desktop.exe");
		Test.Assert((loaded.Sidecars.Count == 2) && (loaded.Sidecars[0] == "SDL3.dll") && (loaded.Sidecars[1] == "dxcompiler.dll"));
		Test.Assert((loaded.Symbols.Count == 1) && (loaded.Symbols[0] == "Sedulous.Engine.Player.Desktop.pdb"));
		Test.Assert(loaded.Directory.IsEmpty && !loaded.IsHost, "the runtime fields are not serialized");

		// The host: the shared libraries beside the player are its sidecars; nothing else is.
		SaveText(dir, "libjoltc.so", "so\n");
		SaveText(dir, "libdxcompiler.so", "so\n");
		SaveText(dir, "libBeefRT.a", "a\n");
		SaveText(dir, "build.dat", "x\n");
		let host = scope ExportTemplate();
		ExportTemplates.SynthesizeHost(dir, host);
		Test.Assert(host.IsHost && (host.Platform == BuildLayout.HostPlatformName) && (host.Config == BuildLayout.BuildConfigName));
		Test.Assert(host.Id == scope $"host-{BuildLayout.HostPlatformName}-{BuildLayout.BuildConfigName}");
		Test.Assert(host.PlayerBinary == BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, .. scope .()));
		Test.Assert(host.Directory == dir);
		Test.Assert((host.Sidecars.Count == 2) && (host.Sidecars[0] == "libdxcompiler.so") && (host.Sidecars[1] == "libjoltc.so"), scope $"{host.Sidecars.Count} sidecars");
	}

	[Test]
	public static void TheRegistryResolvesByIdByPlatformAndFallsBackToTheHost()
	{
		let rootDir = Scratch("scratch_templates_root", .. scope .());
		let hostDir = Scratch("scratch_host_playerdir", .. scope .());
		defer { RemoveDirectoryRecursive(rootDir); RemoveDirectoryRecursive(hostDir); }
		let foreignPlatform = ForeignPlatform(.. scope .());
		let rootFs = scope NativeFileSystem(rootDir);
		let foreign = scope ExportTemplate();
		foreign.Id.Set("sedulous-foreign-0.1.0");
		foreign.Platform.Set(foreignPlatform);
		foreign.PlayerBinary.Set("Sedulous.Engine.Player.Desktop");
		CreateDirectory(PathJoin(rootDir, "foreign-template", .. scope .()));
		Test.Assert(ExportTemplates.SaveManifest(rootFs, foreign, "foreign-template/template.xml") case .Ok);

		let registry = scope TemplateRegistry();
		registry.Refresh(rootDir, hostDir);
		Test.Assert(registry.Count == 2, "the imported foreign plus the synthesized host");
		let byId = registry.FindById("sedulous-foreign-0.1.0");
		Test.Assert((byId != null) && (byId.Directory == PathJoin(rootDir, "foreign-template", .. scope .())));
		Test.Assert(registry.FindBy(foreignPlatform, "Release") == byId);
		Test.Assert(registry.FindBy(foreignPlatform, "") == byId, "an empty config is Release");
		let host = registry.FindBy(BuildLayout.HostPlatformName, BuildLayout.BuildConfigName);
		Test.Assert((host != null) && host.IsHost);
		let preset = scope ExportPreset();
		preset.Platform.Set(foreignPlatform);
		Test.Assert(registry.Resolve(preset) == byId, "a blank template id resolves by platform and config");
		preset.TemplateId.Set("sedulous-foreign-0.1.0");
		Test.Assert(registry.Resolve(preset) == byId);
		let none = scope ExportPreset();
		none.Platform.Set("Nonexistent64");
		Test.Assert(registry.Resolve(none) == null);
	}

	[Test]
	public static void AnImportedTemplateOutRanksTheHostForTheHostPlatform()
	{
		let rootDir = Scratch("scratch_templates_hostwin", .. scope .());
		let hostDir = Scratch("scratch_host_playerdir2", .. scope .());
		defer { RemoveDirectoryRecursive(rootDir); RemoveDirectoryRecursive(hostDir); }
		let rootFs = scope NativeFileSystem(rootDir);
		let imported = scope ExportTemplate();
		imported.Id.Set("sedulous-host-import");
		imported.Platform.Set(BuildLayout.HostPlatformName);
		imported.Config.Set(BuildLayout.BuildConfigName);
		imported.PlayerBinary.Set("Sedulous.Engine.Player.Desktop");
		CreateDirectory(PathJoin(rootDir, "host-template", .. scope .()));
		Test.Assert(ExportTemplates.SaveManifest(rootFs, imported, "host-template/template.xml") case .Ok);
		let registry = scope TemplateRegistry();
		registry.Refresh(rootDir, hostDir);
		Test.Assert(registry.Count == 2);
		let byPlatform = registry.FindBy(BuildLayout.HostPlatformName, BuildLayout.BuildConfigName);
		Test.Assert((byPlatform != null) && !byPlatform.IsHost && (byPlatform.Id == "sedulous-host-import"));
		let host = registry.FindById(scope $"host-{BuildLayout.HostPlatformName}-{BuildLayout.BuildConfigName}");
		Test.Assert((host != null) && host.IsHost);
	}

	[Test]
	public static void ImportInstallsABundleTheRegistryThenResolvesAndRemoveDropsIt()
	{
		let src = Scratch("scratch_tmpl_src", .. scope .());
		let root = Scratch("scratch_tmpl_root2", .. scope .());
		defer { RemoveDirectoryRecursive(src); RemoveDirectoryRecursive(root); }
		let srcFs = scope NativeFileSystem(src);
		let t = scope ExportTemplate();
		t.Id.Set("sedulous-win64-import");
		t.Platform.Set("Win64");
		t.PlayerBinary.Set("Sedulous.Engine.Player.Desktop.exe");
		t.Sidecars.Add(new String("SDL3.dll"));
		Test.Assert(ExportTemplates.SaveManifest(srcFs, t) case .Ok);
		SaveText(src, "Sedulous.Engine.Player.Desktop.exe", "exe\n");
		SaveText(src, "SDL3.dll", "dll\n");
		let importedId = scope String();
		Test.Assert(ExportTemplates.Import(src, root, importedId) case .Ok);
		Test.Assert(importedId == "sedulous-win64-import");
		let registry = scope TemplateRegistry();
		registry.Refresh(root, src);
		let found = registry.FindById("sedulous-win64-import");
		Test.Assert((found != null) && (found.Platform == "Win64") && (found.Sidecars.Count == 1) && (found.Sidecars[0] == "SDL3.dll"));
		Test.Assert(found.Directory == PathJoin(root, "sedulous-win64-import", .. scope .()));
		Test.Assert(FileExists(PathJoin(found.Directory, "SDL3.dll", .. scope .())), "the bundle's files came along");
		let empty = Scratch("scratch_tmpl_empty", .. scope .());
		defer RemoveDirectoryRecursive(empty);
		Test.Assert(ExportTemplates.Import(empty, root) case .Err);

		// Remove deletes the bundle; the registry then drops it.
		Test.Assert(ExportTemplates.Remove(root, "sedulous-win64-import") case .Ok);
		Test.Assert(ExportTemplates.Remove(root, "sedulous-win64-import") case .Err(.NotFound));
		Test.Assert(ExportTemplates.Remove(root, "") case .Err(.InvalidArgument));
		registry.Refresh(root, src);
		Test.Assert(registry.FindById("sedulous-win64-import") == null);
	}

	[Test]
	public static void CreatePackagesABuildDirectoryAndTheRegistryThenResolvesIt()
	{
		let basePath = Scratch("scratch_createtmpl", .. scope .());
		let root = Scratch("scratch_createtmpl_root", .. scope .());
		defer { RemoveDirectoryRecursive(basePath); RemoveDirectoryRecursive(root); }
		// A Beef build directory: <build>/Release_<Platform>/<Player>/.
		let buildDir = PathJoin(PathJoin(basePath, scope $"Release_{BuildLayout.HostPlatformName}", .. scope .()), BuildLayout.cPlayerBaseName, .. scope .());
		CreateDirectory(buildDir);
		let playerName = BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, .. scope .());
		SaveText(buildDir, playerName, "#!player\n");
		SaveText(buildDir, "libfoo.so", "foo\n");
		SaveText(buildDir, "libBeefRT.a", "not a sidecar\n");
		let createdId = scope String();
		let createdDir = scope String();
		Test.Assert(ExportTemplates.Create(buildDir, root, .Install, createdId, createdDir) case .Ok);
		let expectedId = scope $"sedulous-{scope String(BuildLayout.HostPlatformName)..ToLower()}-release-{EngineVersion.String}";
		Test.Assert(createdId == expectedId, scope $"{createdId}");
		Test.Assert(createdDir == PathJoin(root, createdId, .. scope .()));
		Test.Assert(FileExists(PathJoin(createdDir, "template.xml", .. scope .())) && FileExists(PathJoin(createdDir, playerName, .. scope .())) && FileExists(PathJoin(createdDir, "libfoo.so", .. scope .())));
		Test.Assert(!FileExists(PathJoin(createdDir, "libBeefRT.a", .. scope .())), "the static archive is not a sidecar");
		let manifest = scope ExportTemplate();
		Test.Assert(ExportTemplates.LoadManifest(scope NativeFileSystem(createdDir), manifest) case .Ok);
		Test.Assert((manifest.Config == "Release") && (manifest.Compiler == "Beef") && (manifest.Platform == BuildLayout.HostPlatformName));
		Test.Assert((manifest.Sidecars.Count == 1) && (manifest.Sidecars[0] == "libfoo.so"));
		let registry = scope TemplateRegistry();
		registry.Refresh(root, basePath);
		let found = registry.FindById(createdId);
		Test.Assert((found != null) && !found.IsHost && (found.Config == "Release"));
		Test.Assert(registry.FindBy(BuildLayout.HostPlatformName, "Release") == found);
	}

	[Test]
	public static void CreateExportFolderModeWritesASelfContainedBundle()
	{
		let basePath = Scratch("scratch_createtmpl_out", .. scope .());
		let outFolder = Scratch("scratch_createtmpl_bundle", .. scope .());
		defer { RemoveDirectoryRecursive(basePath); RemoveDirectoryRecursive(outFolder); }
		let buildDir = PathJoin(PathJoin(basePath, scope $"Debug_{BuildLayout.HostPlatformName}", .. scope .()), BuildLayout.cPlayerBaseName, .. scope .());
		CreateDirectory(buildDir);
		let playerName = BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, .. scope .());
		SaveText(buildDir, playerName, "#!player\n");
		let createdId = scope String();
		let createdDir = scope String();
		Test.Assert(ExportTemplates.Create(buildDir, outFolder, .ExportFolder, createdId, createdDir) case .Ok);
		Test.Assert(createdDir == outFolder);
		Test.Assert(FileExists(PathJoin(outFolder, "template.xml", .. scope .())) && FileExists(PathJoin(outFolder, playerName, .. scope .())));
		let manifest = scope ExportTemplate();
		Test.Assert(ExportTemplates.LoadManifest(scope NativeFileSystem(outFolder), manifest) case .Ok);
		Test.Assert(manifest.Config == "Debug", "from the build directory's name");
		let emptyBuild = PathJoin(basePath, "empty", .. scope .());
		CreateDirectory(emptyBuild);
		Test.Assert(ExportTemplates.Create(emptyBuild, outFolder, .ExportFolder) case .Err(.NotFound), "no player, no template");
	}

	[Test]
	public static void CreateRecognisesAWebBuildDirectory()
	{
		let basePath = Scratch("scratch_createtmpl_web", .. scope .());
		let root = Scratch("scratch_createtmpl_web_root", .. scope .());
		defer { RemoveDirectoryRecursive(basePath); RemoveDirectoryRecursive(root); }
		// The web player lands in its project's dist/: the page, the script and the module.
		let distDir = PathJoin(basePath, "dist", .. scope .());
		CreateDirectory(distDir);
		let page = scope $"{BuildLayout.cWebPlayerBaseName}.html";
		SaveText(distDir, page, "<html></html>\n");
		SaveText(distDir, scope $"{BuildLayout.cWebPlayerBaseName}.js", "js\n");
		SaveText(distDir, scope $"{BuildLayout.cWebPlayerBaseName}.wasm", "wasm\n");
		let createdId = scope String();
		let createdDir = scope String();
		Test.Assert(ExportTemplates.Create(distDir, root, .Install, createdId, createdDir) case .Ok);
		Test.Assert(createdId == scope $"sedulous-web-release-{EngineVersion.String}", scope $"{createdId}");
		let manifest = scope ExportTemplate();
		Test.Assert(ExportTemplates.LoadManifest(scope NativeFileSystem(createdDir), manifest) case .Ok);
		Test.Assert((manifest.Platform == "Web") && (manifest.PlayerBinary == page) && (manifest.Compiler == "Emscripten"));
		Test.Assert(manifest.Sidecars.Count == 2, scope $"{manifest.Sidecars.Count} web parts");
		Test.Assert(FileExists(PathJoin(createdDir, scope $"{BuildLayout.cWebPlayerBaseName}.wasm", .. scope .())));
	}

	[Test]
	public static void FindByResolvesExactAndFallsBackPreferringRelease()
	{
		let rootDir = Scratch("scratch_findby_root", .. scope .());
		let hostDir = Scratch("scratch_findby_host", .. scope .());
		defer { RemoveDirectoryRecursive(rootDir); RemoveDirectoryRecursive(hostDir); }
		let platform = ForeignPlatform(.. scope .());
		let rootFs = scope NativeFileSystem(rootDir);
		for (let (id, config, subdir) in scope (StringView, StringView, StringView)[](("sedulous-dbg", "Debug", "dbg"), ("sedulous-rel", "Release", "rel")))
		{
			let t = scope ExportTemplate();
			t.Id.Set(id);
			t.Platform.Set(platform);
			t.Config.Set(config);
			t.PlayerBinary.Set("Sedulous.Engine.Player.Desktop");
			CreateDirectory(PathJoin(rootDir, subdir, .. scope .()));
			Test.Assert(ExportTemplates.SaveManifest(rootFs, t, PathJoin(subdir, "template.xml", .. scope .())) case .Ok);
		}
		let registry = scope TemplateRegistry();
		registry.Refresh(rootDir, hostDir);
		let dbg = registry.FindById("sedulous-dbg");
		let rel = registry.FindById("sedulous-rel");
		Test.Assert((dbg != null) && (rel != null));
		Test.Assert(registry.FindBy(platform, "Debug") == dbg);
		Test.Assert(registry.FindBy(platform, "Release") == rel);
		Test.Assert(registry.FindBy(platform, "Test") == rel, "no exact match: Release preferred");
		Test.Assert(registry.FindBy(platform, "") == rel);
		let preset = scope ExportPreset();
		preset.Platform.Set(platform);
		preset.Config.Set("Debug");
		Test.Assert(registry.Resolve(preset) == dbg);
	}

	[Test]
	public static void ResolveRootPrefersAnExplicitOverride()
	{
		Test.Assert(ExportTemplates.ResolveRoot("/explicit/templates", .. scope .()) == "/explicit/templates");
		let resolved = ExportTemplates.ResolveRoot("", .. scope .());
		Test.Assert(!resolved.IsEmpty, "the environment or the user data default");
	}

	[Test]
	public static void EngineMatchesFlagsAMismatchAndPassesHostAndUnstamped()
	{
		let host = scope ExportTemplate();
		ExportTemplates.SynthesizeHost(Directory.GetCurrentDirectory(.. scope .()), host);
		Test.Assert(ExportTemplates.EngineMatches(host));
		let unstamped = scope ExportTemplate();
		Test.Assert(ExportTemplates.EngineMatches(unstamped));
		let foreign = scope ExportTemplate();
		foreign.EngineVersion.Set("9.9.9");
		Test.Assert(!ExportTemplates.EngineMatches(foreign));
	}

	[Test]
	public static void EditorExportSettingsRoundTripsThroughTheStore()
	{
		EditorSerializables.RegisterAll();
		let dir = Scratch("scratch_export_settings", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let fs = scope NativeFileSystem(dir);
		let store = scope Sedulous.Settings.Settings();
		store.Section<EditorExportSettings>().TemplatesRoot.Set("/shared/templates");
		Test.Assert(EditorSettingsStore.Save(fs, store) case .Ok);
		let loaded = scope Sedulous.Settings.Settings();
		Test.Assert(EditorSettingsStore.Load(fs, loaded) case .Ok);
		Test.Assert(loaded.Find<EditorExportSettings>().TemplatesRoot == "/shared/templates");
	}

	[Test]
	public static void ThePresetsControllerLoadsDefaultsEditsWithUniqueNamesAndSaves()
	{
		let dir = Scratch("scratch_presets_controller", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let fs = scope NativeFileSystem(dir);
		let controller = scope ExportPresetsController();
		controller.Load(fs);
		Test.Assert(controller.Count == 1, "no file: the host default");
		let preset = scope ExportPreset();
		preset.Name.Set("Steam");
		preset.Platform.Set("Win64");
		let index = controller.Add(preset);
		Test.Assert((index == 1) && (controller.At(1).Name == "Steam"));
		Test.Assert(controller.Add(preset) == 2);
		Test.Assert(controller.At(2).Name == "Steam Copy");
		Test.Assert(controller.Duplicate(1) == 3);
		Test.Assert(controller.At(3).Name == "Steam Copy 2");
		preset.Name.Set("Steam");
		controller.Update(1, preset);
		Test.Assert(controller.At(1).Name == "Steam", "its own name is not taken by itself");
		controller.Update(2, preset);
		Test.Assert(controller.At(2).Name == "Steam Copy", "taken by index 1");
		controller.Remove(3);
		Test.Assert(controller.Count == 3);
		Test.Assert(controller.Save(fs) case .Ok);
		let reloaded = scope ExportPresetsController();
		reloaded.Load(fs);
		Test.Assert((reloaded.Count == 3) && (reloaded.At(2).Name == "Steam Copy"));
	}

	[Test]
	public static void RootsMembershipTogglesIdempotentlyAndRoundTripsThroughXml()
	{
		let dir = Scratch("scratch_export_roots", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let roots = scope ExportRootsSet();
		Test.Assert(roots.IsEmpty);
		let a = Guid.Parse("00000000-0000-0000-0000-00000000000a").Get();
		Test.Assert(roots.SetInstance(a, true) && roots.HasInstance(a));
		Test.Assert(roots.SetInstance(a, true) && (roots.Instances.Count == 1), "idempotent");
		Test.Assert(!roots.ToggleInstance(a) && !roots.HasInstance(a));
		Test.Assert(roots.ToggleInstance(a));
		Test.Assert(roots.SetGroup("levels/hub", true) && roots.HasGroup("levels/hub"));
		Test.Assert(roots.SetGroup("levels/hub", true) && (roots.Groups.Count == 1));
		Test.Assert(!roots.ToggleGroup("levels/hub") && !roots.HasGroup("levels/hub"));
		roots.SetGroup("levels/hub", true);
		let fs = scope NativeFileSystem(dir);
		Test.Assert(ExportRootsFile.Save(fs, roots) case .Ok);
		let loaded = scope ExportRootsSet();
		Test.Assert(ExportRootsFile.Load(fs, loaded) case .Ok);
		Test.Assert(loaded.HasInstance(a) && loaded.HasGroup("levels/hub") && (loaded.Instances.Count == 1));
		Test.Assert(ExportRootsFile.Load(fs, scope ExportRootsSet(), "missing.xml") case .Err(.NotFound));
	}
}
