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
	/// The engine's own stock web player and MCP host projects, whose configs the web player and
	/// the tools take over: a change to them shows here.
	private const String cStockWeb = Compiler.ReadText("../../Engine/Sedulous.Engine.Player.Web/BeefProj.toml");
	private const String cStockTools = Compiler.ReadText("../../Tools/Sedulous.Tools.Mcp/BeefProj.toml");

	/// An SDK with the files the build reads (the startup libraries, the stock editor's, web
	/// player's and MCP host's projects) and a data root, a second SDK, and a project with the
	/// game's package in Code/ (an Engine and an Editor part) and a project-local package in
	/// Plugins/Lantern (an Engine, a Pipeline and a Tooling part). The build service's tests
	/// (ProjectBuildServiceTests) build over it too.
	public class Bed
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
				Write(sdk, ProjectBuild.cStockWebProject, cStockWeb);
				Write(sdk, ProjectBuild.cStockToolsProject, cStockTools);
				for (let library in StringView[6]("Code/Editor/Sedulous.Editor.Main", "Code/Engine/Sedulous.Engine.Player.DesktopMain",
					"Code/Engine/Sedulous.Engine.Player.WebMain", "Code/Editor/Sedulous.Editor.McpMain", "Code/Editor/Sedulous.Editor.CookMain",
					"Code/Editor/Sedulous.Editor.ExportMain"))
					Write(sdk, scope $"{library}/BeefProj.toml", "");
				Test.Assert(CreateDirectory(PathJoin(sdk, "Data", .. scope .())));
			}

			Settings.Name.Set("Native Game");
			AddPackage("nativegame", "Code", scope StringView[]("Engine", "Editor"));
			Write(ProjectDir, "Code/NativeGame/BeefProj.toml", "");
			Write(ProjectDir, "Code/NativeGame.Editor/BeefProj.toml", "");
			AddPackage("lantern", "Plugins/Lantern", scope StringView[]("Engine", "Pipeline", "Tooling"));
			Write(ProjectDir, "Plugins/Lantern/Lantern.Engine/BeefProj.toml", "");
			Write(ProjectDir, "Plugins/Lantern/Lantern.Pipeline/BeefProj.toml", "");
			Write(ProjectDir, "Plugins/Lantern/Lantern.Tooling/BeefProj.toml", "");
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
		// Every startup library an entry calls is part of an SDK: one without the tools' is not.
		DeleteFile(PathJoin(bed.OtherSdk, "Code/Editor/Sedulous.Editor.CookMain/BeefProj.toml", .. scope .()));
		Test.Assert(!ProjectBuild.IsSdk(bed.OtherSdk));
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
	/// the game), the Plugins/ package's parts by path relative to Code/, and the three desktop
	/// entries (not the web player),
	/// and carries the engine's configs. Beside it go the registry file and a .gitignore.
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
		Test.Assert(space.Contains("\"NativeGameTools\" = {Path = \".generated/NativeGameTools\"}\n"), space);
		Test.Assert(!space.Contains("PlayerWeb"), "the web player has a workspace of its own");
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
		Test.Assert(!player.Contains("\"Lantern.Pipeline\"") && !player.Contains("\"Lantern.Tooling\""), "a player loads no Pipeline or Tooling part");
	}

	/// The web player boots through WebPlayerMain with the parts a player loads, and takes the stock
	/// web player's wasm link: every path the stock reaches from its own folder (serve.py, the
	/// shell, the logo, the notices) is the stock folder in the SDK, absolute, while the output
	/// folder is the generated project's own, one per config in the web workspace's build folder.
	[Test]
	public static void TheWebPlayerTakesTheStockLinkWithItsOwnOutputFolder()
	{
		let bed = scope Bed();
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);

		let web = bed.Read(".generated/NativeGamePlayerWeb/BeefProj.toml", .. scope .());
		Test.Assert(web.Contains("Name = \"NativeGamePlayerWeb\"\nTargetType = \"BeefGUIApplication\"\nStartupObject = \"NativeGamePlayerWeb.Program\""), web);
		Test.Assert(web.Contains("\"Sedulous.Engine.Player.WebMain\" = \"*\""), web);
		Test.Assert(web.Contains("\"NativeGame\" = \"*\"") && web.Contains("\"Lantern.Engine\" = \"*\""), web);
		Test.Assert(!web.Contains("\"NativeGame.Editor\"") && !web.Contains("\"Lantern.Pipeline\"") && !web.Contains("\"Lantern.Tooling\""), web);

		let stockDir = PathJoin(bed.Sdk, ProjectBuild.cStockWebDir, .. scope .());
		Test.Assert(web.Contains("[Configs.Debug.wasm32]\n") && web.Contains("[Configs.ShippingRelease.wasm32]\n"), web);
		Test.Assert(web.Contains(scope $"CopyToTarget(\\\"{stockDir}/serve.py\\\")"), web);
		Test.Assert(web.Contains(scope $"--js-library {stockDir}/player.js --shell-file {stockDir}/shell.html"), web);
		// Each config's output folder is its own, in the build folder of the web workspace, not the
		// stock's in the SDK (whose Debug and ShippingRelease share dist/).
		for (let config in StringView[3]("Debug", "Release", "ShippingRelease"))
		{
			let section = scope $"[Configs.{config}.wasm32]\nTargetName = \"$(ProjectName).html\"\nTargetDirectory = \"$(WorkspaceDir)/build/{config}_wasm32/NativeGamePlayerWeb\"\n";
			Test.Assert(web.Contains(section), section);
			Test.Assert(ProjectBuild.WebTargetDirectory("NativeGame", config, .. scope .()) == scope $"$(WorkspaceDir)/build/{config}_wasm32/NativeGamePlayerWeb");
		}
		int targetLines = 0;
		for (let line in web.Split('\n'))
		{
			if (line.StartsWith("TargetDirectory = "))
				targetLines++;
		}
		Test.Assert(targetLines == 3, "one output folder per wasm32 config");
		Test.Assert(!web.Contains("$(ProjectDir)"), web);

		let program = bed.Read(".generated/NativeGamePlayerWeb/src/Program.bf", .. scope .());
		Test.Assert(program.Contains("namespace NativeGamePlayerWeb;"), program);
		Test.Assert(program.Contains("=> Sedulous.Engine.Player.WebMain.WebPlayerMain.Run(args);"), program);
	}

	/// A plugin manifest of `id` in `dir`, listing parts of `kinds` and supporting `platforms`.
	private static void WriteManifest(StringView dir, StringView id, Span<StringView> kinds, Span<StringView> platforms)
	{
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
		for (let platform in platforms)
		{
			let entry = new PluginPlatform();
			entry.Platform.Set(platform);
			manifest.Platforms.Add(entry);
		}
		let xml = scope String();
		Test.Assert(manifest.Write(xml) case .Ok);
		Bed.Write(dir, "Plugin.xml", xml);
	}

	/// The project's entry enabling engine plugin `id` (no path) on `platforms` (none: every one
	/// its manifest supports).
	private static void EnableEnginePlugin(Bed bed, StringView id, Span<StringView> platforms)
	{
		let entry = new EnabledPlugin();
		entry.Id.Set(id);
		for (let platform in platforms)
			entry.Platforms.Add(new .(platform));
		bed.Settings.Plugins.Add(entry);
	}

	/// The players link the Engine part of each engine plugin the project enables on their
	/// platform, found in the SDK's Code/Plugins by its id. One its entry leaves off a platform,
	/// or whose manifest does not support it, is not linked there; one not enabled, one with no
	/// Engine part and one in no package of the SDK are linked nowhere. The editor and the tools
	/// link none of them.
	[Test]
	public static void ThePlayersLinkTheEnginePluginsEnabledOnTheirPlatform()
	{
		let bed = scope Bed();
		let host = BuildLayout.HostPlatformName;
		let plugins = PathJoin(bed.Sdk, ProjectBuild.cSdkPluginsDir, .. scope .());
		WriteManifest(PathJoin(plugins, "Imgui", .. scope .()), "imgui", scope StringView[]("Engine"), scope StringView[](host, "Web"));
		WriteManifest(PathJoin(plugins, "Weather", .. scope .()), "weather", scope StringView[]("Engine"), scope StringView[](host));
		WriteManifest(PathJoin(plugins, "Fog", .. scope .()), "fog", scope StringView[]("Engine"), scope StringView[](host, "Web"));
		WriteManifest(PathJoin(plugins, "Haze", .. scope .()), "haze", scope StringView[]("Engine"), scope StringView[](host, "Web"));
		WriteManifest(PathJoin(plugins, "Atlas", .. scope .()), "atlas", scope StringView[]("Pipeline"), scope StringView[](host, "Web"));
		EnableEnginePlugin(bed, "imgui", default);
		// Web is not Weather's, so it links on the host alone.
		EnableEnginePlugin(bed, "weather", default);
		EnableEnginePlugin(bed, "fog", scope StringView[]("Web"));
		EnableEnginePlugin(bed, "atlas", default);
		EnableEnginePlugin(bed, "ghost", default);

		let hostParts = scope List<String>();
		defer { ClearAndDeleteItems!(hostParts); }
		ProjectBuild.EnginePluginParts(bed.Settings, bed.Sdk, host, hostParts);
		Test.Assert((hostParts.Count == 2) && (hostParts[0] == "Imgui.Engine") && (hostParts[1] == "Weather.Engine"), "imgui and weather on the host");
		let webParts = scope List<String>();
		defer { ClearAndDeleteItems!(webParts); }
		ProjectBuild.EnginePluginParts(bed.Settings, bed.Sdk, "Web", webParts);
		Test.Assert((webParts.Count == 2) && (webParts[0] == "Imgui.Engine") && (webParts[1] == "Fog.Engine"), "imgui and fog on the web");

		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);
		let player = bed.Read(".generated/NativeGamePlayer/BeefProj.toml", .. scope .());
		Test.Assert(player.Contains("\"Lantern.Engine\" = \"*\"\n\"Imgui.Engine\" = \"*\"\n\"Weather.Engine\" = \"*\"\n"), player);
		let web = bed.Read(".generated/NativeGamePlayerWeb/BeefProj.toml", .. scope .());
		Test.Assert(web.Contains("\"Lantern.Engine\" = \"*\"\n\"Imgui.Engine\" = \"*\"\n\"Fog.Engine\" = \"*\"\n"), web);
		Test.Assert(!player.Contains("\"Fog.Engine\"") && !web.Contains("\"Weather.Engine\""), "each player links what is enabled on its platform");
		for (let text in StringView[2](player, web))
			Test.Assert(!text.Contains("\"Haze.") && !text.Contains("\"Atlas.") && !text.Contains("\"Ghost."), scope String(text));
		for (let entry in StringView[2]("NativeGameEditor", "NativeGameTools"))
		{
			let project = bed.Read(scope $".generated/{entry}/BeefProj.toml", .. scope .());
			Test.Assert(!project.Contains("\"Imgui.Engine\"") && !project.Contains("\"Weather.Engine\"") && !project.Contains("\"Fog.Engine\""), project);
		}
	}

	/// The tools are one console executable over the MCP host's, the cook's and the export's
	/// startup, linking the parts any of those roles loads (no Editor part); its Main runs the
	/// subcommand its first argument names with the rest, and anything else is a usage line and
	/// exit 2. It takes the stock MCP host's post-build steps, reaching the SDK's Bin.
	[Test]
	public static void TheToolsDispatchTheirSubcommandsAndLinkTheToolRolesParts()
	{
		let bed = scope Bed();
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);

		let tools = bed.Read(".generated/NativeGameTools/BeefProj.toml", .. scope .());
		Test.Assert(tools.Contains("Name = \"NativeGameTools\"\nTargetType = \"BeefConsoleApplication\"\nStartupObject = \"NativeGameTools.Program\""), tools);
		for (let library in StringView[3]("Sedulous.Editor.McpMain", "Sedulous.Editor.CookMain", "Sedulous.Editor.ExportMain"))
			Test.Assert(tools.Contains(scope $"\"{library}\" = \"*\""), tools);
		for (let part in StringView[4]("NativeGame", "Lantern.Engine", "Lantern.Pipeline", "Lantern.Tooling"))
			Test.Assert(tools.Contains(scope $"\"{part}\" = \"*\""), tools);
		Test.Assert(!tools.Contains("\"NativeGame.Editor\""), "the tools load no Editor part");
		Test.Assert(tools.Contains(scope $"CopyToTarget(\\\"{bed.Sdk}/Bin/Naga/bin/linux-x86_64/naga\\\")"), tools);
		Test.Assert(tools.Contains(scope $"CopyToTarget(\\\"{bed.Sdk}/Bin/Tint/bin/win-x64/tint.exe\\\")"), tools);
		Test.Assert(tools.Contains("ExecuteRaw(\\\"chmod +x \\\\\\\"$(TargetDir)/naga\\\\\\\" \\\\\\\"$(TargetDir)/tint\\\\\\\"\\\")"), tools);
		Test.Assert(!tools.Contains("$(WorkspaceDir)"), tools);

		let program = bed.Read(".generated/NativeGameTools/src/Program.bf", .. scope .());
		Test.Assert(program.Contains("namespace NativeGameTools;"), program);
		Test.Assert(program.Contains("if (args[0] == \"mcp\")\n\t\t\t\treturn Sedulous.Editor.McpMain.McpMain.Run(rest);"), program);
		Test.Assert(program.Contains("if (args[0] == \"cook\")\n\t\t\t\treturn Sedulous.Editor.CookMain.CookMain.Run(rest);"), program);
		Test.Assert(program.Contains("if (args[0] == \"export\")\n\t\t\t\treturn Sedulous.Editor.ExportMain.ExportMain.Run(rest);"), program);
		Test.Assert(program.Contains("rest[i] = args[i + 1];"), program);
		Test.Assert(program.Contains("usage: NativeGameTools mcp|cook|export [arguments]") && program.Contains("return 2;"), program);
	}

	/// A project with no package of its own and no Code/ gets one: the workspace listing the three
	/// desktop entries and no part, the registry file, a .gitignore, and every entry linking its
	/// startup and nothing of the project's, the web player in its own workspace as ever.
	[Test]
	public static void AProjectWithoutAPackageGetsEntriesLinkingNoPart()
	{
		let bed = scope Bed();
		let projectDir = PathJoin(bed.Root, "Pure Data", .. scope .());
		Test.Assert(CreateDirectory(projectDir));
		let settings = scope ProjectSettings();
		settings.Name.Set("Pure Data");
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(projectDir, settings, bed.Sdk, error) case .Ok, error);

		let workspace = ProjectBuild.Directory(projectDir, .. scope .());
		let space = ReadText(PathJoin(workspace, "BeefSpace.toml", .. scope .()), .. scope .());
		Test.Assert(space.StartsWith("FileVersion = 1\n\n[Workspace]\nStartupProject = \"PureDataEditor\"\n\n[Projects]\n\"PureDataEditor\" = {Path = \".generated/PureDataEditor\"}\n"), space);
		Test.Assert(space.Contains("\"PureDataPlayer\" = {Path = \".generated/PureDataPlayer\"}\n\"PureDataTools\" = {Path = \".generated/PureDataTools\"}\n\n"), space);
		Test.Assert(space.EndsWith(ProjectBuild.cWorkspaceConfigs), space);
		for (let file in StringView[3](".gitignore", "BeefConfig.toml", ".generated/Web/BeefSpace.toml"))
			Test.Assert(FileExists(PathJoin(workspace, file, .. scope .())), scope String(file));

		for (let entry in StringView[4]("PureDataEditor", "PureDataPlayer", "PureDataPlayerWeb", "PureDataTools"))
		{
			let project = ReadText(PathJoin(workspace, scope $".generated/{entry}/BeefProj.toml", .. scope .()), .. scope .());
			// Every dependency is corlib or a startup library of the engine's.
			let dependencies = project.Substring(project.IndexOf("[Dependencies]\n"));
			int linked = 0;
			for (let line in dependencies.Split('\n'))
			{
				if (!line.EndsWith(" = \"*\""))
					continue;
				Test.Assert(line.StartsWith("corlib") || line.StartsWith("\"Sedulous.Editor.") || line.StartsWith("\"Sedulous.Engine.Player."), project);
				linked++;
			}
			Test.Assert(linked >= 2, project);
			Test.Assert(FileExists(PathJoin(workspace, scope $".generated/{entry}/src/Program.bf", .. scope .())), scope String(entry));
		}
	}

	/// A file's text.
	private static void ReadText(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(path, bytes) case .Ok, scope String(path));
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	/// An SDK without a stock project an entry takes its configs from refuses the generate,
	/// naming it.
	[Test]
	public static void AnSdkWithoutAStockProjectRefusesTheGenerate()
	{
		let bed = scope Bed();
		DeleteFile(PathJoin(bed.Sdk, ProjectBuild.cStockWebProject, .. scope .()));
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Err(.NotFound));
		Test.Assert(error.Contains(ProjectBuild.cStockWebProject), error);
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
		Test.Assert(restored.Contains(scope $"\"NativeGameTools\" = {{Path = \".generated/NativeGameTools\"}}\n{lantern}\n[Configs."), restored);

		// Every file a generate writes, each entry's project and Main among them.
		let written = scope List<String>();
		defer { ClearAndDeleteItems!(written); }
		let workspace = ProjectBuild.Directory(bed.ProjectDir, .. scope .());
		written.Add(PathJoin(workspace, "BeefSpace.toml", .. new .()));
		written.Add(PathJoin(workspace, "BeefConfig.toml", .. new .()));
		written.Add(PathJoin(workspace, ".generated/Web/BeefSpace.toml", .. new .()));
		written.Add(PathJoin(workspace, ".generated/Web/BeefConfig.toml", .. new .()));
		for (let entry in StringView[4]("NativeGameEditor", "NativeGamePlayer", "NativeGamePlayerWeb", "NativeGameTools"))
		{
			written.Add(PathJoin(workspace, scope $".generated/{entry}/BeefProj.toml", .. new .()));
			written.Add(PathJoin(workspace, scope $".generated/{entry}/src/Program.bf", .. new .()));
		}
		let ticks = scope List<int64>();
		for (let path in written)
		{
			Test.Assert(FileStat(path, let size, let fileTicks), path);
			ticks.Add(fileTicks);
		}
		// Past the file system's timestamp step, so a write would show.
		System.Threading.Thread.Sleep(50);
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);
		for (int i < written.Count)
			Test.Assert(FileStat(written[i], let sizeAgain, let ticksAgain) && (ticksAgain == ticks[i]), written[i]);
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
		Test.Assert(text.EndsWith(scope $"\"NativeGameTools\" = {{Path = \".generated/NativeGameTools\"}}\n\n{ProjectBuild.cWorkspaceConfigs}"), text);

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

	/// The web player builds in a workspace of its own, Code/.generated/Web, which lists the parts
	/// a player loads (by path from there) and the web entry alone, with the engine's configs and
	/// a registry file of its own: nothing the editor or the tools bring in is compiled for wasm32.
	[Test]
	public static void TheWebPlayerHasAWorkspaceOfItsOwn()
	{
		let bed = scope Bed();
		let error = scope String();
		Test.Assert(ProjectBuild.Generate(bed.ProjectDir, bed.Settings, bed.Sdk, error) case .Ok, error);

		let webDir = ProjectBuild.WebWorkspaceDirectory(bed.ProjectDir, .. scope .());
		Test.Assert(webDir == scope $"{bed.ProjectDir}/Code/.generated/Web", webDir);
		let space = bed.Read(".generated/Web/BeefSpace.toml", .. scope .());
		Test.Assert(space.StartsWith("FileVersion = 1\n\n[Workspace]\nStartupProject = \"NativeGamePlayerWeb\"\n\n[Projects]\n"), space);
		Test.Assert(space.Contains("\n\"NativeGame\" = {Path = \"../../NativeGame\"}\n"), space);
		Test.Assert(space.Contains("\"Lantern.Engine\" = {Path = \"../../../Plugins/Lantern/Lantern.Engine\"}\n"), space);
		Test.Assert(space.Contains("\"NativeGamePlayerWeb\" = {Path = \"../NativeGamePlayerWeb\"}\n\n"), space);
		for (let absent in StringView[6]("NativeGame.Editor", "Lantern.Pipeline", "Lantern.Tooling", "NativeGameEditor", "NativeGamePlayer\"", "NativeGameTools"))
			Test.Assert(!space.Contains(absent), scope String(absent));
		Test.Assert(space.EndsWith(ProjectBuild.cWorkspaceConfigs) && !space.Contains("ConfigSelections"), space);
		Test.Assert(bed.Read(".generated/Web/BeefConfig.toml", .. scope .()) == ProjectBuild.ConfigText(bed.Sdk, .. scope .()));

		// Its page lands in the entry's own output folder for the config, under the web workspace,
		// in the layout of every other build; it is what a web build makes, built there for wasm32.
		let page = ProjectBuild.WebPagePath(bed.ProjectDir, "NativeGame", "Debug", .. scope .());
		Test.Assert(page == scope $"{bed.ProjectDir}/Code/.generated/Web/build/Debug_wasm32/NativeGamePlayerWeb/NativeGamePlayerWeb.html", page);
		let shipping = ProjectBuild.WebPagePath(bed.ProjectDir, "NativeGame", "ShippingRelease", .. scope .());
		Test.Assert(shipping.EndsWith("/Code/.generated/Web/build/ShippingRelease_wasm32/NativeGamePlayerWeb/NativeGamePlayerWeb.html"), shipping);
		Test.Assert(ProjectBuild.EntryPath(bed.ProjectDir, "NativeGame", .PlayerWeb, "Debug", .. scope .()) == page);
		Test.Assert(ProjectBuild.EntryWorkspace(bed.ProjectDir, .PlayerWeb, .. scope .()) == webDir);
		Test.Assert(ProjectBuild.EntryWorkspace(bed.ProjectDir, .Player, .. scope .()) == ProjectBuild.Directory(bed.ProjectDir, .. scope .()));
		Test.Assert((ProjectBuild.EntryPlatform(.PlayerWeb) == "wasm32") && (ProjectBuild.EntryPlatform(.Player) == BuildLayout.HostPlatformName));
		let config = scope String();
		let platform = scope String();
		BuildLayout.ParseBuildDirectory(PathParent(page, .. scope .()), config, platform);
		Test.Assert((config == "Debug") && (platform == BuildLayout.cWebPlatform), "its folder reads as a build folder");
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

	/// A preset's config names the build its player is made in: Release (or none) a
	/// ShippingRelease build, Profile a Release one, Debug itself.
	[Test]
	public static void APresetsConfigNamesItsBuildConfig()
	{
		Test.Assert(ProjectBuild.BuildConfigFor("", .. scope String()) == "ShippingRelease");
		Test.Assert(ProjectBuild.BuildConfigFor("Release", .. scope String()) == "ShippingRelease");
		Test.Assert(ProjectBuild.BuildConfigFor("Profile", .. scope String()) == "Release");
		Test.Assert(ProjectBuild.BuildConfigFor("Debug", .. scope String()) == "Debug");
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

	/// A fake Beef install under the bed: BeefBuild at `exe` (relative to the bed's root), the
	/// BeefConfig.toml beside it naming `libraries` (none: no config), and corlib at `corlib`
	/// (relative to the root; empty: none). Its BeefBuild's path.
	public static void FakeInstall(Bed bed, StringView exe, StringView libraries, StringView corlib, String outBeefBuild)
	{
		let file = BuildLayout.ExecutableName(exe, .. scope .());
		Bed.Write(bed.Root, file, "#!beefbuild\n");
		if (!libraries.IsEmpty)
		{
			let dir = PathParent(file, .. scope .());
			Bed.Write(bed.Root, scope $"{dir}/BeefConfig.toml", scope $"Version = 1\nUnversionedLibDirs = [{libraries}]\n");
		}
		if (!corlib.IsEmpty)
			Bed.Write(bed.Root, scope $"{corlib}/BeefProj.toml", "FileVersion = 1\n");
		PathJoin(bed.Root, file, outBeefBuild);
	}

	/// BeefBuild is taken where its install has corlib, laid out as BeefBuild finds it: a source
	/// build's IDE/dist reaching ../../BeefLibs, an installed one's bin reaching ../BeefLibs.
	/// BEEFBUILD wins over PATH.
	[Test]
	public static void BeefBuildIsTakenWhereItsInstallHasCorlib()
	{
		let bed = scope Bed();
		let source = FakeInstall(bed, "beef/IDE/dist/BeefBuild", "\"../../BeefLibs\"", "beef/BeefLibs/corlib", .. scope .());
		let installed = FakeInstall(bed, "installed/bin/BeefBuild", "'../BeefLibs'", "installed/BeefLibs/corlib", .. scope .());
		Test.Assert(ProjectBuild.HasCorlib(source, scope .()));
		Test.Assert(ProjectBuild.HasCorlib(installed, scope .()));

		let found = scope String();
		let error = scope String();
		let sourceDir = PathParent(source, .. scope .());
		Test.Assert(ProjectBuild.FindBeefBuildFrom("", sourceDir, found, error) && (found == source), error);
		Test.Assert(ProjectBuild.FindBeefBuildFrom(installed, sourceDir, found, error) && (found == installed), found);
	}

	/// A BeefBuild whose install has no corlib, or no BeefConfig.toml, is passed over for the next
	/// on PATH; with none left, the refusal names each one tried and why.
	[Test]
	public static void ABeefBuildWithoutCorlibIsPassedOver()
	{
		let bed = scope Bed();
		let bare = FakeInstall(bed, "bare/bin/BeefBuild", "\"../BeefLibs\"", "bare/BeefLibs/minlib", .. scope .());
		let unconfigured = FakeInstall(bed, "unconfigured/BeefBuild", "", "", .. scope .());
		let good = FakeInstall(bed, "good/bin/BeefBuild", "\"../Libraries/Extra\", \"../BeefLibs\"", "good/BeefLibs/Core/corlib", .. scope .());
		let why = scope String();
		Test.Assert(!ProjectBuild.HasCorlib(bare, why) && why.Contains("no corlib"), why);
		Test.Assert(!ProjectBuild.HasCorlib(unconfigured, why..Clear()) && why.Contains("no BeefConfig.toml"), why);
		Test.Assert(ProjectBuild.HasCorlib(good, why..Clear()), "corlib a level down in the second library folder");

#if BF_PLATFORM_WINDOWS
		let separator = ";";
#else
		let separator = ":";
#endif
		let bareDir = PathParent(bare, .. scope .());
		let unconfiguredDir = PathParent(unconfigured, .. scope .());
		let goodDir = PathParent(good, .. scope .());
		let found = scope String();
		let error = scope String();
		Test.Assert(ProjectBuild.FindBeefBuildFrom("", scope $"{bareDir}{separator}{unconfiguredDir}{separator}{goodDir}", found, error) && (found == good), error);

		let missing = PathJoin(bed.Root, "nowhere/BeefBuild", .. scope .());
		Test.Assert(!ProjectBuild.FindBeefBuildFrom(missing, scope $"{bareDir}{separator}{unconfiguredDir}", found, error));
		Test.Assert(error.StartsWith("BeefBuild not found: set BEEFBUILD, or put BeefBuild on PATH (tried: "), error);
		Test.Assert(error.Contains(scope $"BEEFBUILD '{missing}': no such file"), error);
		Test.Assert(error.Contains(scope $"PATH '{bare}': no corlib"), error);
		Test.Assert(error.Contains(scope $"PATH '{unconfigured}': no BeefConfig.toml"), error);
		Test.Assert(!ProjectBuild.FindBeefBuildFrom("", "", found, error) && error.Contains("PATH: no BeefBuild there"), error);
	}

	/// A BeefConfig.toml's library folders: each string of the array, on one line or several,
	/// either kind of quote, a basic string's escaped backslash read as one.
	[Test]
	public static void TheLibraryFoldersAreReadFromBeefConfig()
	{
		let dirs = scope List<String>();
		defer { ClearAndDeleteItems!(dirs); }
		ProjectBuild.LibraryDirs("Version = 1\nUnversionedLibDirs = [\n\t\"../../BeefLibs\",\n\t'C:\\Beef\\Libs', \"D:\\\\Libs\"\n]\n", dirs);
		Test.Assert(dirs.Count == 3, scope String()..AppendF("{} folders", dirs.Count));
		Test.Assert((dirs[0] == "../../BeefLibs") && (dirs[1] == "C:\\Beef\\Libs") && (dirs[2] == "D:\\Libs"), dirs[2]);
		ProjectBuild.LibraryDirs("Version = 1\n", dirs);
		Test.Assert(dirs.Count == 3, "none without the key");
	}

	/// An Emscripten folder with emcc in it, for the fake installs; its path.
	public static void FakeEmscripten(Bed bed, StringView name, String outPath)
	{
		PathJoin(bed.Root, name, outPath);
		Bed.Write(outPath, BuildLayout.ExecutableName(ProjectBuild.cEmccPath, .. scope .()), "#!emcc\n");
	}

	/// Emscripten is the folder the [Wasm] table's EmscriptenPath names in the BeefSettings.toml
	/// beside BeefBuild, once it holds emcc. No settings file, a file without the key in that
	/// table, and a folder without emcc are each refused, saying what to set.
	[Test]
	public static void EmscriptenIsTheFolderBeefBuildsSettingsName()
	{
		let bed = scope Bed();
		let beefBuild = FakeInstall(bed, "beef/IDE/dist/BeefBuild", "\"../../BeefLibs\"", "beef/BeefLibs/corlib", .. scope .());
		let home = PathJoin(bed.Root, "home", .. scope .());
		let emsdk = PathJoin(bed.Root, "emsdk", .. scope .());
		let found = scope String();
		let error = scope String();
		Test.Assert(!ProjectBuild.FindEmscriptenFrom(beefBuild, home, found, error) && found.IsEmpty);
		Test.Assert(error.Contains("has no BeefSettings.toml") && error.Contains("EmscriptenPath = \"<emsdk folder>\" under [Wasm]"), error);

		// The key in another table is not Emscripten's.
		Bed.Write(bed.Root, "beef/IDE/dist/BeefSettings.toml", scope $"FileVersion = 1\n\n[Wasm]\n\n[Options]\nEmscriptenPath = '{emsdk}'\n");
		Test.Assert(!ProjectBuild.FindEmscriptenFrom(beefBuild, home, found, error..Clear()), "the key under [Options]");
		Test.Assert(error.Contains("BeefSettings.toml' names none: set EmscriptenPath"), error);
		Bed.Write(bed.Root, "beef/IDE/dist/BeefSettings.toml", "FileVersion = 1\n\n[Wasm]\nEmscriptenPath = \"\"\n");
		Test.Assert(!ProjectBuild.FindEmscriptenFrom(beefBuild, home, found, error..Clear()) && error.Contains("names none"), "an empty path");

		Bed.Write(bed.Root, "beef/IDE/dist/BeefSettings.toml", scope $"FileVersion = 1\n\n[Console]\nDebugConsole = \"Native\"\n\n[Wasm]\nEmscriptenPath = '{emsdk}'\n\n[RecentFiles]\n");
		Test.Assert(!ProjectBuild.FindEmscriptenFrom(beefBuild, home, found, error..Clear()) && found.IsEmpty);
		Test.Assert(error.Contains(scope $"Emscripten at '{emsdk}'") && error.Contains("has no upstream/emscripten/emcc"), error);

		FakeEmscripten(bed, "emsdk", .. scope .());
		Test.Assert(ProjectBuild.FindEmscriptenFrom(beefBuild, home, found, error..Clear()) && (found == emsdk), error);
	}

	/// A TOML table's string value: a basic string's escapes read as the character escaped, a
	/// literal string as written, the same key in another table not it.
	[Test]
	public static void ATomlValueIsReadFromItsTable()
	{
		let value = scope String();
		Test.Assert(ProjectBuild.TomlValue("[Wasm]\r\nEmscriptenPath = \"C:\\\\Tools\\\\emsdk\"\r\n", "Wasm", "EmscriptenPath", value) && (value == "C:\\Tools\\emsdk"), value);
		Test.Assert(ProjectBuild.TomlValue("[Wasm]\n  EmscriptenPath='/opt/emsdk'\n", "Wasm", "EmscriptenPath", value) && (value == "/opt/emsdk"), value);
		Test.Assert(!ProjectBuild.TomlValue("[Options]\nEmscriptenPath = \"/opt\"\n", "Wasm", "EmscriptenPath", value) && value.IsEmpty);
		Test.Assert(!ProjectBuild.TomlValue("[Wasm]\nEmscriptenPathX = \"/opt\"\n", "Wasm", "EmscriptenPath", value), "another key");
		Test.Assert(!ProjectBuild.TomlValue("[Wasm]\nEmscriptenPath = \"/opt\n", "Wasm", "EmscriptenPath", value) && value.IsEmpty, "unterminated");
	}

#if BF_PLATFORM_LINUX
	/// A BeefBuild with no settings beside it is one packaged for Linux, which reads them from
	/// ~/.config/beeflang; a file beside it is the one it reads, whatever HOME holds.
	[Test]
	public static void APackagedBeefBuildsSettingsAreUnderHome()
	{
		let bed = scope Bed();
		let beefBuild = FakeInstall(bed, "installed/bin/BeefBuild", "'../BeefLibs'", "installed/BeefLibs/corlib", .. scope .());
		let home = PathJoin(bed.Root, "home", .. scope .());
		let packaged = FakeEmscripten(bed, "packaged emsdk", .. scope .());
		Bed.Write(home, ".config/beeflang/BeefSettings.toml", scope $"[Wasm]\nEmscriptenPath = \"{packaged}\"\n");
		let found = scope String();
		let error = scope String();
		Test.Assert(ProjectBuild.FindEmscriptenFrom(beefBuild, home, found, error) && (found == packaged), error);
		Test.Assert(!ProjectBuild.FindEmscriptenFrom(beefBuild, "", found, error) && error.Contains("has no BeefSettings.toml"), "no HOME, no packaged settings");

		let beside = FakeEmscripten(bed, "beside emsdk", .. scope .());
		Bed.Write(bed.Root, "installed/bin/BeefSettings.toml", scope $"[Wasm]\nEmscriptenPath = \"{beside}\"\n");
		Test.Assert(ProjectBuild.FindEmscriptenFrom(beefBuild, home, found, error) && (found == beside), found);
	}
#endif

	/// The executables are BeefBuild's output in Code/build: <Game>Editor and <Game>Player, each
	/// in its config's folder.
	[Test]
	public static void TheExecutablesAreBeefBuildsOutputInCodeBuild()
	{
		let bed = scope Bed();
		let editor = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", true, "Debug", .. scope .());
		let player = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", false, "ShippingRelease", .. scope .());
		Test.Assert(editor.StartsWith(scope $"{bed.ProjectDir}/Code/build/Debug_{BuildLayout.HostPlatformName}/NativeGameEditor/NativeGameEditor"), editor);
		Test.Assert(player.StartsWith(scope $"{bed.ProjectDir}/Code/build/ShippingRelease_{BuildLayout.HostPlatformName}/NativeGamePlayer/NativeGamePlayer"), player);
	}

	/// The project's editor is fresh when built and newer than every file of its packages. What
	/// builds write in Code/ (their output, the entries, the registry file) does not count; a
	/// change to the game's source, or to a Plugins/ package's, does.
	[Test]
	public static void TheEditorIsFreshWhenNewerThanEveryPackageFile()
	{
		let bed = scope Bed();
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"), "not built");
		System.Threading.Thread.Sleep(50);
		let editor = ProjectBuild.ExecutablePath(bed.ProjectDir, "NativeGame", true, "Debug", .. scope .());
		Bed.Write(bed.ProjectDir, editor.Substring(bed.ProjectDir.Length + 1), "#!editor\n");
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"));
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Release"), "another config's is not built");

		System.Threading.Thread.Sleep(50);
		bed.WriteCode("build/Debug_Linux64/NativeGame/NativeGame.o", "object\n");
		bed.WriteCode(".generated/NativeGameEditor/src/Program.bf", "// generated\n");
		bed.WriteCode("BeefConfig.toml", "Version = 1\n");
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"), "what builds write is not the game's");

		bed.WriteCode("NativeGame/src/Part.bf", "// changed\n");
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"));
		DeleteFile(PathJoin(bed.ProjectDir, "Code/NativeGame/src/Part.bf", .. scope .()));
		Test.Assert(!ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"));
		Bed.Write(bed.ProjectDir, "Plugins/Lantern/Lantern.Engine/src/Part.bf", "// changed\n");
		Test.Assert(ProjectBuild.IsStale(bed.ProjectDir, bed.Settings, "Debug"));
	}
}
