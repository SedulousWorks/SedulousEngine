using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// A project's own build: the SDK it finds, the workspace it keeps in Code/, the entries it
/// generates, and its refusals.
class ProjectBuildTests
{
	private const String cRoot = "scratch_project_build";

	/// An SDK with the files the build reads (the startup libraries, the stock editor's project)
	/// and a data root, a second SDK, and a project with the game's package in Code/ (an Engine
	/// and an Editor part) and a project-local package in Plugins/Lantern (an Engine part).
	private class Bed
	{
		public String Root = new .() ~ delete _;
		public String Sdk = new .() ~ delete _;
		public String OtherSdk = new .() ~ delete _;
		public String ProjectDir = new .() ~ delete _;
		public ProjectSettings Settings = new .() ~ delete _;

		public this()
		{
			RemoveDirectoryRecursive(cRoot);
			let cwd = GetCurrentDirectory(.. scope .());
			PathJoin(cwd, cRoot, Root);
			PathJoin(Root, "sdk", Sdk);
			PathJoin(Root, "other sdk", OtherSdk);
			PathJoin(Root, "Native Game", ProjectDir);
			for (let sdk in StringView[2](Sdk, OtherSdk))
			{
				Write(sdk, "Code/Tools/Sedulous.Tools.Editor/BeefProj.toml",
					"FileVersion = 1\n\n[Project]\nName = \"Sedulous.Tools.Editor\"\n\n[Configs.Debug.Linux64]\nPostBuildCmds = [\"CopyToTarget(\\\"$(WorkspaceDir)/../Bin/Naga/bin/linux-x86_64/naga\\\")\"]\n");
				Write(sdk, "Code/Editor/Sedulous.Editor.Main/BeefProj.toml", "");
				Write(sdk, "Code/Engine/Sedulous.Engine.Player.DesktopMain/BeefProj.toml", "");
				Test.Assert(CreateDirectory(PathJoin(sdk, "Data", .. scope .())));
			}

			Settings.Name.Set("Native Game");
			AddPackage("nativegame", "Code", scope StringView[]("Engine", "Editor"));
			Write(ProjectDir, "Code/NativeGame/BeefProj.toml", "");
			Write(ProjectDir, "Code/NativeGame.Editor/BeefProj.toml", "");
			AddPackage("lantern", "Plugins/Lantern", scope StringView[]("Engine"));
			Write(ProjectDir, "Plugins/Lantern/Lantern.Engine/BeefProj.toml", "");
		}

		public ~this()
		{
			RemoveDirectoryRecursive(cRoot);
		}

		/// A package's manifest of `kinds` at `path` in the project, and the project's entry for it.
		private void AddPackage(StringView id, StringView path, Span<StringView> kinds)
		{
			let entry = new EnabledPlugin();
			entry.Id.Set(id);
			entry.Path.Set(path);
			Settings.Plugins.Add(entry);
			let manifest = scope PluginManifest();
			manifest.Id.Set(id);
			manifest.Name.Set(id);
			manifest.Version.Set("0.1.0");
			manifest.EngineVersion.Set("0.1");
			for (let kind in kinds)
			{
				let part = new PluginManifestPart();
				part.Kind.Set(kind);
				manifest.Parts.Add(part);
			}
			let xml = scope String();
			Test.Assert(manifest.Write(xml) case .Ok);
			Write(ProjectDir, scope $"{path}/Plugin.xml", xml);
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

		/// A file of the project's workspace (Code/).
		public void Read(StringView relative, String outText)
		{
			let bytes = scope List<uint8>();
			let path = PathJoin(ProjectBuild.Directory(ProjectDir, .. scope .()), relative, .. scope .());
			Test.Assert(ReadFile(path, bytes) case .Ok, path);
			outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
		}

		/// Writes a file of the project's workspace (Code/).
		public void WriteCode(StringView relative, StringView text)
		{
			Write(ProjectBuild.Directory(ProjectDir, .. scope .()), relative, text);
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

	/// The game's Engine part is the game itself; every other part, and every part of another
	/// package, is <Name>.<Kind>. Only Code is the game's package.
	[Test]
	public static void TheGamesEnginePartIsTheGameItself()
	{
		Test.Assert(ProjectBuild.PartName("NativeGame", true, .Engine, .. scope String()) == "NativeGame");
		Test.Assert(ProjectBuild.PartName("NativeGame", true, .Editor, .. scope String()) == "NativeGame.Editor");
		Test.Assert(ProjectBuild.PartName("Lantern", false, .Engine, .. scope String()) == "Lantern.Engine");
		Test.Assert(ProjectBuild.IsGamePath("Code") && ProjectBuild.IsGamePath("Code/"));
		Test.Assert(!ProjectBuild.IsGamePath("Plugins/Code") && !ProjectBuild.IsGamePath(""));
	}

	/// SEDULOUS_SDK names the SDK when it names one; one that does not falls back to the checkout
	/// the data root is in; a data root in no SDK, with no variable, finds none.
	[Test]
	public static void TheSdkIsTheVariablesElseTheDataRootsCheckout()
	{
		let bed = scope Bed();
		let dataRoot = PathJoin(bed.Sdk, "Data", .. scope .());
		let found = scope String();
		Test.Assert(ProjectBuild.FindSdkFrom("", dataRoot, found) && (found == bed.Sdk), found);
		Test.Assert(ProjectBuild.FindSdkFrom("", scope $"{dataRoot}/", found) && (found == bed.Sdk), "a trailing slash too");
		Test.Assert(ProjectBuild.FindSdkFrom(bed.OtherSdk, dataRoot, found) && (found == bed.OtherSdk), "the variable wins");
		Test.Assert(ProjectBuild.FindSdkFrom(scope $"{bed.OtherSdk}/", "", found) && (found == bed.OtherSdk), "with no data root");
		Test.Assert(ProjectBuild.FindSdkFrom(bed.ProjectDir, dataRoot, found) && (found == bed.Sdk), "a variable naming no SDK falls back");
		Test.Assert(!ProjectBuild.FindSdkFrom("", PathJoin(bed.ProjectDir, "Data", .. scope .()), found) && found.IsEmpty);
		Test.Assert(!ProjectBuild.FindSdkFrom("", "", found));
		Test.Assert(ProjectBuild.IsSdk(bed.Sdk) && !ProjectBuild.IsSdk(bed.ProjectDir));
	}

	/// BeefConfig.toml points Beef's registry at the SDK's six library folders, by absolute path.
	[Test]
	public static void TheConfigListsTheSdksLibraryFoldersAbsolute()
	{
		let bed = scope Bed();
		let text = ProjectBuild.ConfigText(bed.Sdk, .. scope .());
		Test.Assert(text.StartsWith("Version = 1\nUnversionedLibDirs = [\""), text);
		Test.Assert(PathIsAbsolute(bed.Sdk));
		for (let dir in StringView[6]("Code/Foundation", "Code/Engine", "Code/Pipeline", "Code/Editor", "Code/Plugins", "Dependencies"))
			Test.Assert(text.Contains(scope $"\"{bed.Sdk}/{dir}\""), text);
		Test.Assert(!text.Contains(scope $"\"{bed.Sdk}/Code\"") && !text.Contains("Code/Tools") && !text.Contains("Code/Samples"), text);
	}

	/// A new workspace starts the project's editor, lists the game's parts (the Engine part as
	/// the game), the Plugins/ package's parts by path relative to Code/, and the two entries, and
	/// carries the engine's configs. Beside it go the registry file and a .gitignore.
	[Test]
	public static void ANewWorkspaceListsTheGamesPartsThePackagesAndTheEntries()
	{
		let bed = scope Bed();
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);

		let space = bed.Read("BeefSpace.toml", .. scope .());
		Test.Assert(space.StartsWith("FileVersion = 1\n\n[Workspace]\nStartupProject = \"NativeGameEditor\"\n"), space);
		Test.Assert(space.Contains("\n[Projects]\n\"NativeGame\" = {Path = \"NativeGame\"}\n"), space);
		Test.Assert(space.Contains("\"NativeGame.Editor\" = {Path = \"NativeGame.Editor\"}\n"), space);
		Test.Assert(space.Contains("\"Lantern.Engine\" = {Path = \"../Plugins/Lantern/Lantern.Engine\"}\n"), space);
		Test.Assert(space.Contains("\"NativeGameEditor\" = {Path = \".generated/NativeGameEditor\"}\n"), space);
		Test.Assert(space.Contains("\"NativeGamePlayer\" = {Path = \".generated/NativeGamePlayer\"}\n"), space);
		Test.Assert(space.EndsWith(ProjectBuild.cWorkspaceConfigs), space);
		Test.Assert(!space.Contains("Sedulous."), "the engine's projects come from the registry");

		Test.Assert(bed.Read("BeefConfig.toml", .. scope .()) == ProjectBuild.ConfigText(bed.Sdk, .. scope .()));
		let ignore = bed.Read(".gitignore", .. scope .());
		Test.Assert(ignore.Contains("/build/\n") && ignore.Contains("/.generated/\n") && ignore.Contains("/BeefConfig.toml\n"), ignore);
	}

	/// Each entry links the stock startup and the parts its role loads (a player no Editor part),
	/// its Main is one call into the startup, and the editor's post-build steps reach the SDK by
	/// absolute path.
	[Test]
	public static void TheEntriesLinkTheirRolesPartsAndTheEditorsStepsReachTheSdk()
	{
		let bed = scope Bed();
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);

		let editor = bed.Read(".generated/NativeGameEditor/BeefProj.toml", .. scope .());
		Test.Assert(editor.Contains("Name = \"NativeGameEditor\"") && editor.Contains("StartupObject = \"NativeGameEditor.Program\""), editor);
		Test.Assert(editor.Contains("\"Sedulous.Editor.Main\" = \"*\""), editor);
		Test.Assert(editor.Contains("\"NativeGame\" = \"*\"") && editor.Contains("\"NativeGame.Editor\" = \"*\"") && editor.Contains("\"Lantern.Engine\" = \"*\""), editor);
		Test.Assert(editor.Contains(scope $"CopyToTarget(\\\"{bed.Sdk}/Bin/Naga/bin/linux-x86_64/naga\\\")"), editor);
		Test.Assert(!editor.Contains("$(WorkspaceDir)"), editor);
		let player = bed.Read(".generated/NativeGamePlayer/BeefProj.toml", .. scope .());
		Test.Assert(player.Contains("\"Sedulous.Engine.Player.DesktopMain\" = \"*\""), player);
		Test.Assert(player.Contains("\"NativeGame\" = \"*\"") && player.Contains("\"Lantern.Engine\" = \"*\""), player);
		Test.Assert(!player.Contains("\"NativeGame.Editor\""), "a player loads no Editor part");
		Test.Assert(!player.Contains("[Configs."), "the editor's post-build steps are the editor's");
		let program = bed.Read(".generated/NativeGameEditor/src/Program.bf", .. scope .());
		Test.Assert(program.Contains("namespace NativeGameEditor;"), program);
		Test.Assert(program.Contains("=> Sedulous.Editor.Main.EditorMain.Run(args);"), program);
		Test.Assert(bed.Read(".generated/NativeGamePlayer/src/Program.bf", .. scope .()).Contains("DesktopPlayerMain.Run(args)"));
	}

	/// The workspace is the user's: a second generate keeps a project line they added and an edit
	/// elsewhere, adds back a line the build needs, and writes nothing when nothing changed.
	[Test]
	public static void AGenerateKeepsTheUsersWorkspaceAndWritesNothingUnchanged()
	{
		let bed = scope Bed();
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);
		let edited = bed.Read("BeefSpace.toml", .. scope .());
		edited.Replace("StartupProject = \"NativeGameEditor\"", "StartupProject = \"MyTool\"");
		edited.Replace("[Configs.Debug.Linux64]\n", "[Configs.Debug.Linux64]\nOptimizationLevel = \"O1\"\n");
		edited.Replace("\"NativeGame\" = {Path = \"NativeGame\"}\n", "\"NativeGame\" = {Path = \"NativeGame\"}\n\"MyTool\" = {Path = \"../Tools/MyTool\"}\n");
		bed.WriteCode("BeefSpace.toml", edited);
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);
		Test.Assert(bed.Read("BeefSpace.toml", .. scope .()) == edited, "every line kept, nothing added");

		// A line the build needs, gone, comes back at the end of [Projects].
		let lantern = "\"Lantern.Engine\" = {Path = \"../Plugins/Lantern/Lantern.Engine\"}\n";
		let removed = scope String(edited)..Replace(lantern, "");
		bed.WriteCode("BeefSpace.toml", removed);
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);
		let restored = bed.Read("BeefSpace.toml", .. scope .());
		Test.Assert(restored.Contains("\"MyTool\" = {Path = \"../Tools/MyTool\"}") && restored.Contains("OptimizationLevel = \"O1\""), restored);
		Test.Assert(restored.Contains(scope $"\"NativeGamePlayer\" = {{Path = \".generated/NativeGamePlayer\"}}\n{lantern}\n[Configs."), restored);

		let space = PathJoin(ProjectBuild.Directory(bed.ProjectDir, .. scope .()), "BeefSpace.toml", .. scope .());
		let program = PathJoin(ProjectBuild.Directory(bed.ProjectDir, .. scope .()), ".generated/NativeGamePlayer/src/Program.bf", .. scope .());
		Test.Assert(FileStat(space, let size, let ticks));
		Test.Assert(FileStat(program, let programSize, let programTicks));
		// Past the file system's timestamp step, so a write would show.
		System.Threading.Thread.Sleep(50);
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);
		Test.Assert(FileStat(space, let sizeAgain, let ticksAgain) && (sizeAgain == size) && (ticksAgain == ticks));
		Test.Assert(FileStat(program, let programSizeAgain, let programTicksAgain) && (programTicksAgain == programTicks));
	}

	/// A workspace of the user's without [Workspace] or configs gains them, the [Workspace] before
	/// the first table, and keeps its own lines; one with everything is left as it is.
	[Test]
	public static void AUsersWorkspaceGainsWhatItLacks()
	{
		let bed = scope Bed();
		let packages = scope List<ProjectPackage>();
		defer { ClearAndDeleteItems!(packages); }
		let problems = scope List<String>();
		defer { ClearAndDeleteItems!(problems); }
		ProjectBuild.Packages(bed.ProjectDir, bed.Settings, packages, problems);
		let existing = "FileVersion = 1\n\n[Projects]\n\"Mine\" = {Path = \"Mine\"}\n";
		let text = ProjectBuild.WorkspaceText(existing, "NativeGame", packages, .. scope .());
		Test.Assert(text.StartsWith("FileVersion = 1\n\n[Workspace]\nStartupProject = \"NativeGameEditor\"\n\n[Projects]\n\"Mine\" = {Path = \"Mine\"}\n\"NativeGame\" = {Path = \"NativeGame\"}\n"), text);
		Test.Assert(text.EndsWith(scope $"\"NativeGamePlayer\" = {{Path = \".generated/NativeGamePlayer\"}}\n\n{ProjectBuild.cWorkspaceConfigs}"), text);

		let noProjects = ProjectBuild.WorkspaceText("FileVersion = 1\n", "NativeGame", packages, .. scope .());
		Test.Assert(noProjects.Contains("[Workspace]\nStartupProject = \"NativeGameEditor\"\n\n[Projects]\n\"NativeGame\""), noProjects);
		let again = ProjectBuild.WorkspaceText(noProjects, "NativeGame", packages, .. scope .());
		Test.Assert(again == noProjects, again);
	}

	/// The configs a new workspace carries are the engine workspace's, less the project
	/// selections, which name the engine's own projects: a change to the engine's shows here.
	[Test]
	public static void TheWorkspaceConfigsAreTheEnginesLessItsSelections()
	{
		const String cEngineSpace = Compiler.ReadText("../../BeefSpace.toml");
		let start = StringView(cEngineSpace).IndexOf("\n[Configs.");
		Test.Assert(start >= 0);
		let stripped = scope String();
		for (let rawLine in StringView(cEngineSpace, start + 1).Split('\n'))
		{
			var line = rawLine;
			line.TrimEnd('\r');
			if (line.StartsWith("ConfigSelections"))
				continue;
			stripped.AppendF("{}\n", line);
		}
		stripped.TrimEnd();
		let expected = scope String(ProjectBuild.cWorkspaceConfigs)..TrimEnd();
		Test.Assert(stripped == expected, stripped);
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
		Test.Assert((packages.Count == 2) && problems.IsEmpty, "the engine plugin is not a package");
		Test.Assert((packages[0].Name == "NativeGame") && packages[0].IsGame && (packages[0].Parts.Count == 2));
		Test.Assert((packages[1].Name == "Lantern") && !packages[1].IsGame && (packages[1].Path == "Plugins/Lantern"));

		DeleteFile(PathJoin(bed.ProjectDir, "Code/NativeGame/BeefProj.toml", .. scope .()));
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Err(.InvalidArgument));
		Test.Assert(error.Contains("its Engine part has no project (NativeGame/BeefProj.toml)"), error);

		bed.Settings.Plugins[0].Id.Set("other");
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Err(.InvalidArgument));
		Test.Assert(error.Contains("holds no Plugin.xml of that id"), error);
		Test.Assert(!FileExists(PathJoin(bed.ProjectDir, "Code/BeefSpace.toml", .. scope .())), "nothing written");
		Test.Assert(!DirectoryExists(PathJoin(bed.ProjectDir, "Code/.generated", .. scope .())), "nothing written");
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

	/// Build Project is refused without an SDK and for a project with no package of its own,
	/// before anything runs.
	[Test]
	public static void BuildProjectNeedsAnSdkAndAPackage()
	{
		let bed = scope Bed();
		let presets = scope ExportPresetSet();
		let error = scope String();
		// SEDULOUS_SDK set where the tests run would find that SDK: the refusal is checked without.
		let variable = scope String();
		if ((Environment.GetEnvironmentVariable(ProjectBuild.cSdkVariable, variable) case .Err) || !ProjectBuild.IsSdk(variable))
		{
			Test.Assert(ProjectBuild.Build(bed.ProjectDir, bed.Settings, presets, bed.ProjectDir, error) case .Err(.NotSupported));
			Test.Assert(error.Contains("needs the engine SDK: set SEDULOUS_SDK, or run from an engine checkout"), error);
		}
		let dataRoot = PathJoin(bed.Sdk, "Data", .. scope .());
		ClearAndDeleteItems!(bed.Settings.Plugins);
		Test.Assert(!ProjectBuild.HasPackages(bed.Settings));
		Test.Assert(ProjectBuild.Build(bed.ProjectDir, bed.Settings, presets, dataRoot, error) case .Err(.NotFound));
		Test.Assert(error.Contains("no package of its own"), error);
		Test.Assert(!FileExists(PathJoin(bed.ProjectDir, "Code/BeefSpace.toml", .. scope .())), "nothing generated");
	}

	/// The executables are BeefBuild's output in Code/build. A build is finished when they are
	/// there: the editor in Debug first, then the player in each config, the first missing one
	/// named.
	[Test]
	public static void ABuildIsFinishedWhenItsExecutablesAreThere()
	{
		let bed = scope Bed();
		let configs = scope List<String>() { "Debug", "Release" };
		let unbuilt = scope String();
		let editor = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", true, "Debug", .. scope .());
		let debugPlayer = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", false, "Debug", .. scope .());
		let releasePlayer = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", false, "Release", .. scope .());
		Test.Assert(editor.StartsWith(scope $"{bed.ProjectDir}/Code/build/Debug_{BuildLayout.HostPlatformName}/NativeGameEditor/NativeGameEditor"), editor);
		Test.Assert(debugPlayer.StartsWith(scope $"{bed.ProjectDir}/Code/build/Debug_{BuildLayout.HostPlatformName}/NativeGamePlayer/NativeGamePlayer"), debugPlayer);
		Test.Assert(ProjectBuild.FindUnbuilt(bed.ProjectDir, "NativeGame", configs, unbuilt) && (unbuilt == editor), unbuilt);
		Bed.Write(bed.ProjectDir, editor.Substring(bed.ProjectDir.Length + 1), "#!editor\n");
		Test.Assert(ProjectBuild.FindUnbuilt(bed.ProjectDir, "NativeGame", configs, unbuilt) && (unbuilt == debugPlayer), unbuilt);
		Bed.Write(bed.ProjectDir, debugPlayer.Substring(bed.ProjectDir.Length + 1), "#!player\n");
		Test.Assert(ProjectBuild.FindUnbuilt(bed.ProjectDir, "NativeGame", configs, unbuilt) && (unbuilt == releasePlayer), unbuilt);
		Bed.Write(bed.ProjectDir, releasePlayer.Substring(bed.ProjectDir.Length + 1), "#!player\n");
		Test.Assert(!ProjectBuild.FindUnbuilt(bed.ProjectDir, "NativeGame", configs, unbuilt) && unbuilt.IsEmpty, unbuilt);
	}

	/// The project's player is fresh when built and newer than every file of its packages. What
	/// builds write in Code/ (their output, the entries, the registry file) does not count; a
	/// change to the game's source, or to a Plugins/ package's, does.
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
		bed.WriteCode("build/Debug_Linux64/NativeGame/NativeGame.o", "object\n");
		bed.WriteCode(".generated/NativeGamePlayer/src/Program.bf", "// generated\n");
		bed.WriteCode("BeefConfig.toml", "Version = 1\n");
		Test.Assert(ProjectBuild.FreshPlayer(bed.ProjectDir, bed.Settings, "Debug", player) case .Ok, "what builds write is not the game's");

		bed.WriteCode("NativeGame/src/Part.bf", "// changed\n");
		Test.Assert(ProjectBuild.FreshPlayer(bed.ProjectDir, bed.Settings, "Debug", player) case .Err(.InvalidArgument));
		DeleteFile(PathJoin(bed.ProjectDir, "Code/NativeGame/src/Part.bf", .. scope .()));
		Test.Assert(ProjectBuild.FreshPlayer(bed.ProjectDir, bed.Settings, "Debug", player) case .Ok);
		Bed.Write(bed.ProjectDir, "Plugins/Lantern/Lantern.Engine/src/Part.bf", "// changed\n");
		Test.Assert(ProjectBuild.FreshPlayer(bed.ProjectDir, bed.Settings, "Debug", player) case .Err(.InvalidArgument));
	}
}
