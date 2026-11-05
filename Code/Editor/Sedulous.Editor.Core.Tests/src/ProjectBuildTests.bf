using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// A project's own build: the workspace it generates over an engine checkout, its executables'
/// projects, and its refusals.
class ProjectBuildTests
{
	private const String cRoot = "scratch_project_build";

	/// A checkout with the files the build reads (its workspace, the stock editor's project, the
	/// startup libraries), and a project with one package of an Engine and an Editor part.
	private class Bed
	{
		public String Root = new .() ~ delete _;
		public String Checkout = new .() ~ delete _;
		public String ProjectDir = new .() ~ delete _;
		public ProjectSettings Settings = new .() ~ delete _;

		public this()
		{
			RemoveDirectoryRecursive(cRoot);
			let cwd = GetCurrentDirectory(.. scope .());
			PathJoin(cwd, cRoot, Root);
			PathJoin(Root, "checkout", Checkout);
			PathJoin(Root, "Native Game", ProjectDir);
			Write(Checkout, "Code/BeefSpace.toml", """
				FileVersion = 1

				[Workspace]
				StartupProject = "Samples.GUISandbox"

				[Projects]
				Bulkan = {Path = "../Dependencies/Bulkan"}
				"Sedulous.Core" = {Path = "Foundation/Sedulous.Core"}
				"NativeGame.Engine" = {Path = "../Data/SampleProjects/NativeGame/Plugins/NativeGame/NativeGame.Engine"}

				[WorkspaceFolders]
				"Sedulous/Foundation" = ["Sedulous.Core"]

				[Configs.ShippingRelease.Linux64]
				PreprocessorMacros = ["SHIPPING"]
				ConfigSelections = {"NativeGame.Engine" = {Enabled = false}, "Samples.Web" = {Enabled = false}}
				""");
			Write(Checkout, "Code/Tools/Sedulous.Tools.Editor/BeefProj.toml",
				"FileVersion = 1\n\n[Project]\nName = \"Sedulous.Tools.Editor\"\n\n[Configs.Debug.Linux64]\nPostBuildCmds = [\"CopyToTarget(\\\"$(WorkspaceDir)/../Bin/Naga/bin/linux-x86_64/naga\\\")\"]\n");
			Write(Checkout, "Code/Editor/Sedulous.Editor.Main/BeefProj.toml", "");
			Write(Checkout, "Code/Engine/Sedulous.Engine.Player.DesktopMain/BeefProj.toml", "");
			Test.Assert(CreateDirectory(PathJoin(Checkout, "Data", .. scope .())));

			Settings.Name.Set("Native Game");
			let entry = new EnabledPlugin();
			entry.Id.Set("nativegame");
			entry.Path.Set("Plugins/NativeGame");
			Settings.Plugins.Add(entry);
			let manifest = scope PluginManifest();
			manifest.Id.Set("nativegame");
			manifest.Name.Set("Native Game");
			manifest.Version.Set("0.1.0");
			manifest.EngineVersion.Set("0.1");
			for (let kind in StringView[2]("Engine", "Editor"))
			{
				let part = new PluginManifestPart();
				part.Kind.Set(kind);
				manifest.Parts.Add(part);
			}
			let xml = scope String();
			Test.Assert(manifest.Write(xml) case .Ok);
			Write(ProjectDir, "Plugins/NativeGame/Plugin.xml", xml);
			Write(ProjectDir, "Plugins/NativeGame/NativeGame.Engine/BeefProj.toml", "");
			Write(ProjectDir, "Plugins/NativeGame/NativeGame.Editor/BeefProj.toml", "");
		}

		public ~this()
		{
			RemoveDirectoryRecursive(cRoot);
		}

		public static void Write(StringView dir, StringView relative, StringView text)
		{
			let path = PathJoin(dir, relative, .. scope .());
			MakeDirectories(PathParent(path, .. scope .()));
			Test.Assert(WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Ok);
		}

		public static void MakeDirectories(StringView dir)
		{
			if (DirectoryExists(dir))
				return;
			MakeDirectories(PathParent(dir, .. scope .()));
			CreateDirectory(dir);
		}

		public void Read(StringView relative, String outText)
		{
			let bytes = scope List<uint8>();
			let path = PathJoin(ProjectBuild.Directory(ProjectDir, .. scope .()), relative, .. scope .());
			Test.Assert(ReadFile(path, bytes) case .Ok, path);
			outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
		}
	}

	/// A project's name gives the executables' name: only its letters and digits, and a name that
	/// would not start with a letter gets "Game" in front.
	[Test]
	public static void TheGameNameIsTheProjectsLettersAndDigits()
	{
		Test.Assert(ProjectBuild.GameName("Sky Hopper", .. scope String()) == "SkyHopper");
		Test.Assert(ProjectBuild.GameName("2 Fast!", .. scope String()) == "Game2Fast");
		Test.Assert(ProjectBuild.GameName("", .. scope String()) == "Game");
	}

	/// The build needs an engine checkout: a data root beside a Code folder with the startup
	/// libraries in it. Anywhere else (a distribution's data root) is no checkout.
	[Test]
	public static void ACheckoutIsADataRootBesideTheEnginesCode()
	{
		let bed = scope Bed();
		let found = scope String();
		Test.Assert(ProjectBuild.FindCheckout(PathJoin(bed.Checkout, "Data", .. scope .()), found));
		Test.Assert(found == bed.Checkout);
		Test.Assert(ProjectBuild.FindCheckout(scope $"{bed.Checkout}/Data/", found), "a trailing slash too");
		Test.Assert(!ProjectBuild.FindCheckout(PathJoin(bed.ProjectDir, "Data", .. scope .()), found));
		Test.Assert(found.IsEmpty);
		Test.Assert(!ProjectBuild.FindCheckout("", found));
	}

	/// The workspace names the engine's projects by absolute path into the checkout, then the
	/// package's parts and the two executables, and keeps the engine's configs but not its IDE
	/// sections; the editor links every part, the player the Engine part alone, and each Main is
	/// one call into the stock startup.
	[Test]
	public static void TheWorkspaceNamesTheEngineByAbsolutePathAndEachExecutableItsRolesParts()
	{
		let bed = scope Bed();
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Checkout, error) case .Ok, error);

		let space = bed.Read("BeefSpace.toml", .. scope .());
		Test.Assert(space.Contains("StartupProject = \"NativeGameEditor\""), space);
		Test.Assert(space.Contains(scope $"Bulkan = {{Path = \"{bed.Checkout}/Code/../Dependencies/Bulkan\"}}"), space);
		Test.Assert(space.Contains(scope $"\"Sedulous.Core\" = {{Path = \"{bed.Checkout}/Code/Foundation/Sedulous.Core\"}}"), space);
		Test.Assert(space.Contains(scope $"\"NativeGame.Engine\" = {{Path = \"{bed.ProjectDir}/Plugins/NativeGame/NativeGame.Engine\"}}"), space);
		Test.Assert(!space.Contains("SampleProjects"), "the engine's copy of the package is the project's");
		Test.Assert(space.Contains(scope $"\"NativeGame.Editor\" = {{Path = \"{bed.ProjectDir}/Plugins/NativeGame/NativeGame.Editor\"}}"), space);
		Test.Assert(space.Contains("\"NativeGamePlayer\" = {Path = \"NativeGamePlayer\"}"), space);
		Test.Assert(space.Contains("\"NativeGameEditor\" = {Path = \"NativeGameEditor\"}"), "beside the package's Editor part, not over it");
		Test.Assert(space.Contains("[Configs.ShippingRelease.Linux64]\nPreprocessorMacros = [\"SHIPPING\"]"), space);
		Test.Assert(space.Contains("ConfigSelections = {\"Samples.Web\" = {Enabled = false}}"), "the engine's selection kept, the package's part's dropped");
		Test.Assert(!space.Contains("WorkspaceFolders") && !space.Contains("Samples.GUISandbox"), space);

		let editor = bed.Read("NativeGameEditor/BeefProj.toml", .. scope .());
		Test.Assert(editor.Contains("StartupObject = \"NativeGameEditor.Program\""), editor);
		Test.Assert(editor.Contains("\"Sedulous.Editor.Main\" = \"*\""), editor);
		Test.Assert(editor.Contains("\"NativeGame.Engine\" = \"*\"") && editor.Contains("\"NativeGame.Editor\" = \"*\""), editor);
		Test.Assert(editor.Contains(scope $"CopyToTarget(\\\"{bed.Checkout}/Bin/Naga/bin/linux-x86_64/naga\\\")"), editor);
		let player = bed.Read("NativeGamePlayer/BeefProj.toml", .. scope .());
		Test.Assert(player.Contains("\"Sedulous.Engine.Player.DesktopMain\" = \"*\""), player);
		Test.Assert(player.Contains("\"NativeGame.Engine\" = \"*\"") && !player.Contains("\"NativeGame.Editor\""), "a player loads no Editor part");
		Test.Assert(!player.Contains("[Configs."), "the editor's post-build steps are the editor's");
		let program = bed.Read("NativeGameEditor/src/Program.bf", .. scope .());
		Test.Assert(program.Contains("namespace NativeGameEditor;"), program);
		Test.Assert(program.Contains("=> Sedulous.Editor.Main.EditorMain.Run(args);"), program);
		Test.Assert(bed.Read("NativeGamePlayer/src/Program.bf", .. scope .()).Contains("DesktopPlayerMain.Run(args)"));

		let exe = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", false, "Debug", .. scope .());
		Test.Assert(exe.StartsWith(scope $"{bed.ProjectDir}/.cache/build/build/Debug_{BuildLayout.HostPlatformName}/NativeGamePlayer/NativeGamePlayer"), exe);
	}

	/// A generate that changes nothing writes nothing, so the build after it has nothing to do;
	/// a change rewrites only what it changes.
	[Test]
	public static void AGenerateThatChangesNothingWritesNothing()
	{
		let bed = scope Bed();
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Checkout, error) case .Ok, error);
		let space = PathJoin(ProjectBuild.Directory(bed.ProjectDir, .. scope .()), "BeefSpace.toml", .. scope .());
		let marked = "// changed by hand\n";
		Test.Assert(FileStat(space, let size, let ticks));
		let program = PathJoin(ProjectBuild.Directory(bed.ProjectDir, .. scope .()), "NativeGamePlayer/src/Program.bf", .. scope .());
		let text = bed.Read("NativeGamePlayer/src/Program.bf", .. scope .());
		// Past the file system's timestamp step, so a write would show.
		System.Threading.Thread.Sleep(50);
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Checkout, error) case .Ok, error);
		Test.Assert(FileStat(space, let sizeAgain, let ticksAgain) && (sizeAgain == size) && (ticksAgain == ticks));
		Test.Assert(WriteFile(program, .((uint8*)marked.Ptr, marked.Length)) case .Ok);
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Checkout, error) case .Ok, error);
		Test.Assert(bed.Read("NativeGamePlayer/src/Program.bf", .. scope .()) == text, "rewritten when it differs");
	}

	/// A package whose folder lacks a manifest of its id, or a part's project, refuses the build,
	/// saying which; an entry with no path (an engine plugin) is not a package.
	[Test]
	public static void APackageMissingItsManifestOrAPartsProjectRefusesTheBuild()
	{
		let bed = scope Bed();
		let engine = new EnabledPlugin();
		engine.Id.Set("imgui");
		bed.Settings.Plugins.Add(engine);
		let packages = scope List<ProjectPackage>();
		defer { ClearAndDeleteItems!(packages); }
		let problems = scope List<String>();
		defer { ClearAndDeleteItems!(problems); }
		ProjectBuild.Packages(bed.ProjectDir, bed.Settings, packages, problems);
		Test.Assert((packages.Count == 1) && problems.IsEmpty, "the engine plugin is not a package");
		Test.Assert((packages[0].Name == "NativeGame") && (packages[0].Parts.Count == 2));

		DeleteFile(PathJoin(bed.ProjectDir, "Plugins/NativeGame/NativeGame.Editor/BeefProj.toml", .. scope .()));
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Checkout, error) case .Err(.InvalidArgument));
		Test.Assert(error.Contains("its Editor part has no project (NativeGame.Editor/BeefProj.toml)"), error);

		bed.Settings.Plugins[0].Id.Set("other");
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Checkout, error) case .Err(.InvalidArgument));
		Test.Assert(error.Contains("holds no Plugin.xml of that id"), error);
		Test.Assert(!DirectoryExists(ProjectBuild.Directory(bed.ProjectDir, .. scope .())), "nothing written");
	}

	/// A preset's template config names the build it is made from: Release a ShippingRelease build,
	/// Profile a Release one; the player is built in Debug and in each config a preset for this
	/// host exports with, once each; a preset for another platform takes a template, not this
	/// build.
	[Test]
	public static void ThePlayerIsBuiltInDebugAndEachHostPresetsConfig()
	{
		Test.Assert(ProjectBuild.BuildConfigFor("", .. scope String()) == "ShippingRelease");
		Test.Assert(ProjectBuild.BuildConfigFor("Release", .. scope String()) == "ShippingRelease");
		Test.Assert(ProjectBuild.BuildConfigFor("Profile", .. scope String()) == "Release");
		Test.Assert(ProjectBuild.BuildConfigFor("Debug", .. scope String()) == "Debug");

		let presets = scope ExportPresetSet();
		for (let config in StringView[4]("", "Profile", "Release", "Debug"))
		{
			let preset = new ExportPreset();
			preset.Platform.Set(BuildLayout.HostPlatformName);
			preset.Config.Set(config);
			presets.Presets.Add(preset);
		}
		let web = new ExportPreset();
		web.Platform.Set("Web");
		web.Config.Set("Test");
		presets.Presets.Add(web);
		let configs = scope List<String>();
		defer { ClearAndDeleteItems!(configs); }
		ProjectBuild.PlayerConfigs(presets, configs);
		Test.Assert((configs.Count == 3) && (configs[0] == "Debug") && (configs[1] == "ShippingRelease") && (configs[2] == "Release"));
	}

	/// BeefBuild is looked for on PATH alone: the first directory holding it, none for a path
	/// without it.
	[Test]
	public static void BeefBuildIsTheFirstOnThePath()
	{
		let bed = scope Bed();
		let first = PathJoin(bed.Root, "first", .. scope .());
		let second = PathJoin(bed.Root, "second", .. scope .());
		let file = BuildLayout.ExecutableName("BeefBuild", .. scope .());
		Bed.Write(second, file, "");
		Test.Assert(CreateDirectory(first));
#if BF_PLATFORM_WINDOWS
		let searchPath = scope $"{first};;{second}";
#else
		let searchPath = scope $"{first}::{second}";
#endif
		let found = scope String();
		Test.Assert(ProjectBuild.FindOnPath(searchPath, "BeefBuild", found));
		Test.Assert(found == PathJoin(second, file, .. scope .()), found);
		Bed.Write(first, file, "");
		Test.Assert(ProjectBuild.FindOnPath(searchPath, "BeefBuild", found) && (found == PathJoin(first, file, .. scope .())), found);
		Test.Assert(!ProjectBuild.FindOnPath(first, "Nothing", found));
	}

	/// Build Project is refused outside an engine checkout and for a project with no package of
	/// its own, before anything runs.
	[Test]
	public static void BuildProjectNeedsACheckoutAndAPackage()
	{
		let bed = scope Bed();
		let presets = scope ExportPresetSet();
		let error = scope String();
		Test.Assert(ProjectBuild.Build(bed.ProjectDir, bed.Settings, presets, bed.ProjectDir, error) case .Err(.NotSupported));
		Test.Assert(error.Contains("needs an engine checkout"), error);
		let dataRoot = PathJoin(bed.Checkout, "Data", .. scope .());
		ClearAndDeleteItems!(bed.Settings.Plugins);
		Test.Assert(!ProjectBuild.HasPackages(bed.Settings));
		Test.Assert(ProjectBuild.Build(bed.ProjectDir, bed.Settings, presets, dataRoot, error) case .Err(.NotFound));
		Test.Assert(error.Contains("no package of its own"), error);
		Test.Assert(!DirectoryExists(ProjectBuild.Directory(bed.ProjectDir, .. scope .())), "nothing generated");
	}

	/// A build is finished when its executables are there: the editor in Debug first, then the
	/// player in each config, the first missing one named.
	[Test]
	public static void ABuildIsFinishedWhenItsExecutablesAreThere()
	{
		let bed = scope Bed();
		let configs = scope List<String>() { "Debug", "Release" };
		let unbuilt = scope String();
		let editor = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", true, "Debug", .. scope .());
		let debugPlayer = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", false, "Debug", .. scope .());
		let releasePlayer = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", false, "Release", .. scope .());
		Test.Assert(ProjectBuild.FindUnbuilt(bed.ProjectDir, "NativeGame", configs, unbuilt) && (unbuilt == editor), unbuilt);
		Bed.Write(bed.ProjectDir, editor.Substring(bed.ProjectDir.Length + 1), "#!editor\n");
		Test.Assert(ProjectBuild.FindUnbuilt(bed.ProjectDir, "NativeGame", configs, unbuilt) && (unbuilt == debugPlayer), unbuilt);
		Bed.Write(bed.ProjectDir, debugPlayer.Substring(bed.ProjectDir.Length + 1), "#!player\n");
		Test.Assert(ProjectBuild.FindUnbuilt(bed.ProjectDir, "NativeGame", configs, unbuilt) && (unbuilt == releasePlayer), unbuilt);
		Bed.Write(bed.ProjectDir, releasePlayer.Substring(bed.ProjectDir.Length + 1), "#!player\n");
		Test.Assert(!ProjectBuild.FindUnbuilt(bed.ProjectDir, "NativeGame", configs, unbuilt) && unbuilt.IsEmpty, unbuilt);
	}

	/// The project's player is fresh when built and newer than every file of its packages, a
	/// file in a part's folder included.
	[Test]
	public static void ThePlayerIsFreshWhenNewerThanEveryPackageFile()
	{
		let bed = scope Bed();
		let player = scope String();
		Test.Assert(ProjectBuild.FreshPlayer(bed.ProjectDir, bed.Settings, "Debug", player) case .Err(.NotFound));
		System.Threading.Thread.Sleep(50);
		let relative = player.Substring(bed.ProjectDir.Length + 1);
		Bed.Write(bed.ProjectDir, relative, "#!player\n");
		Test.Assert(ProjectBuild.FreshPlayer(bed.ProjectDir, bed.Settings, "Debug", player) case .Ok);
		Test.Assert(ProjectBuild.FreshPlayer(bed.ProjectDir, bed.Settings, "Release", player) case .Err(.NotFound), "another config's is not built");
		System.Threading.Thread.Sleep(50);
		Bed.Write(bed.ProjectDir, "Plugins/NativeGame/NativeGame.Engine/src/Part.bf", "// changed\n");
		Test.Assert(ProjectBuild.FreshPlayer(bed.ProjectDir, bed.Settings, "Debug", player) case .Err(.InvalidArgument));
	}
}
