using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Runtime;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// A package of the project's (an entry with a path: the game's own in Code/, a project-local
/// plugin in Plugins/) and the parts its manifest lists, as the project's build links them.
class ProjectPackage
{
	public String Id = new .() ~ delete _;
	/// The package's folder, absolute: Code or Plugins/<Name> under the project.
	public String Directory = new .() ~ delete _;
	/// The folder as the project's entry names it, relative to the project.
	public String Path = new .() ~ delete _;
	/// The prefix of each part's project: the game's name for the game's package, the folder's
	/// name for any other (a package in Plugins/Weather gives Weather.Engine).
	public String Name = new .() ~ delete _;
	/// The game's own package (Code/), whose Engine part is the project <Game>, not <Game>.Engine.
	public bool IsGame;
	public List<PluginPartKind> Parts = new .() ~ delete _;

	/// The project name of the part of `kind`, which is its folder's name too.
	public void PartName(PluginPartKind kind, String outName) => ProjectBuild.PartName(Name, IsGame, kind, outName);
}

/// The executables a project's build generates under Code/.generated, each named <Game><Suffix>.
enum BuildEntry
{
	case Editor;
	/// The desktop player.
	case Player;
	/// The browser player, built for wasm32.
	case PlayerWeb;
	/// The project's tooling: the MCP host, the cook and the export, one subcommand each.
	case Tools;

	public const int Count = 4;
}

/// A project's own build: the editor, the players and the tools linked with the project's
/// packages.
///
/// A Beef library cannot be loaded beside the engine (each carries a runtime of its own), so a
/// package's parts are compiled in. The stock executables link the engine's plugins; a project
/// with packages of its own builds its entries (BuildEntry: <Game>Editor, <Game>Player,
/// <Game>PlayerWeb and <Game>Tools) in its own workspace, Code/ (the web player in one of its
/// own, Code/.generated/Web, which nothing desktop-only reaches). Each is a one-line Main over the
/// stock startup (EditorMain, DesktopPlayerMain, WebPlayerMain; the tools dispatch to McpMain,
/// CookMain and ExportMain) with the parts its roles load as dependencies, generated under
/// Code/.generated. They are named without a dot, so no part (<Game> or <Name>.<Kind>) can take
/// the name.
///
/// The workspace lists only the project's own projects. Everything else (the engine's libraries
/// and their dependencies) Beef finds through its library registry: Code/BeefConfig.toml, written
/// per machine, points it at the folders of the engine SDK. So a build needs an SDK: a source
/// tree of the engine, found through SEDULOUS_SDK or as the checkout an editor runs from.
static class ProjectBuild
{
	/// Under Code/: the generated entries, and BeefBuild's output.
	public const String cGeneratedDir = ".generated";
	/// Under .generated: the web player's own workspace (WebWorkspaceText).
	public const String cWebWorkspaceDir = "Web";
	public const String cBuildDir = "build";
	public const String cSpaceFile = "BeefSpace.toml";
	/// The per-machine registry file that points Beef at the SDK.
	public const String cConfigFile = "BeefConfig.toml";
	public const String cIgnoreFile = ".gitignore";
	/// What builds and the Beef IDE write in Code/, so neither version control nor a player's
	/// freshness counts it: BeefBuild's output, the generated entries and registry file, and the
	/// IDE's recovery folder and per-user workspace state.
	public const String[3] cWrittenDirs = .(cBuildDir, cGeneratedDir, "recovery");
	public const String[2] cWrittenFiles = .(cConfigFile, "BeefSpace_User.toml");

	public const String cEditorSuffix = "Editor";
	public const String cPlayerSuffix = "Player";
	public const String cPlayerWebSuffix = "PlayerWeb";
	public const String cToolsSuffix = "Tools";
	/// The library each executable's Main calls.
	public const String cEditorStartup = "Sedulous.Editor.Main";
	public const String cPlayerStartup = "Sedulous.Engine.Player.DesktopMain";
	public const String cPlayerWebStartup = "Sedulous.Engine.Player.WebMain";
	/// The tools' libraries, one per subcommand of cToolCommands, in its order.
	public const String[3] cToolStartups = .("Sedulous.Editor.McpMain", "Sedulous.Editor.CookMain", "Sedulous.Editor.ExportMain");
	/// The first argument <Game>Tools takes, naming what it runs; and each one's call.
	public const String[3] cToolCommands = .("mcp", "cook", "export");
	public const String[3] cToolCalls = .("Sedulous.Editor.McpMain.McpMain.Run", "Sedulous.Editor.CookMain.CookMain.Run", "Sedulous.Editor.ExportMain.ExportMain.Run");
	/// The exit code of <Game>Tools given no subcommand it knows.
	public const int cToolsUsageExit = 2;
	/// The stock editor's project, whose post-build steps (naga and tint beside the executable)
	/// the project's editor takes over.
	public const String cStockEditorProject = "Code/Tools/Sedulous.Tools.Editor/BeefProj.toml";
	/// The stock web player's folder and project, whose wasm link (emcc's flags, the shell page,
	/// and serve.py, the logo and the notices staged beside the page) the project's web player
	/// takes over.
	public const String cStockWebDir = "Code/Engine/Sedulous.Engine.Player.Web";
	public const String cStockWebProject = "Code/Engine/Sedulous.Engine.Player.Web/BeefProj.toml";
	/// The stock MCP host's project, whose post-build steps (naga and tint, which the export's
	/// WGSL cook runs from beside the executable) the project's tools take over.
	public const String cStockToolsProject = "Code/Tools/Sedulous.Tools.Mcp/BeefProj.toml";
	/// The stock web player's setting each config keeps as the generated project's own: its
	/// output stays beside the generated project, not in the SDK.
	public const String cWebOwnKey = "TargetDirectory";

	/// Names an SDK root ahead of any other.
	public const String cSdkVariable = "SEDULOUS_SDK";
	/// Names the BeefBuild executable ahead of any other (FindBeefBuild).
	public const String cBeefBuildVariable = "BEEFBUILD";
	/// The SDK's folders Beef's registry walks for projects, relative to the SDK root. Not the
	/// whole of Code/: the registry walks every directory under each, and Code/build is huge; and
	/// not Code/Tools, Integration, Samples or Deprecated, which no game links.
	public const String[6] cSdkLibraryDirs = .("Code/Foundation", "Code/Engine", "Code/Pipeline", "Code/Editor", "Code/Plugins", "Dependencies");

	/// The engine workspace's workspace-level settings per config and platform (Code/BeefSpace.toml
	/// less every ConfigSelections line, which name the engine's own projects): the wasm32 heap and
	/// debug checks, the debug info a release drops, and SHIPPING. A project's new workspace starts
	/// with them, and so does the web player's (WebWorkspaceText); ProjectBuildTests checks they
	/// match the engine's.
	public const String cWorkspaceConfigs = """
		[Configs.Debug.wasm32]
		AllocType = "CRT"
		EnableObjectDebugFlags = false
		EmitObjectAccessCheck = false

		[Configs.Debug.Linux64]

		[Configs.Debug.Win64]

		[Configs.Release.wasm32]
		EmitDebugInfo = "No"

		[Configs.Release.Linux64]

		[Configs.Release.Win64]

		[Configs.Test.Linux64]

		[Configs.Test.Win64]

		[Configs.ShippingRelease.wasm32]
		PreprocessorMacros = ["SHIPPING"]
		EmitDebugInfo = "No"

		[Configs.ShippingRelease.Linux64]
		PreprocessorMacros = ["SHIPPING"]

		[Configs.ShippingRelease.Win64]
		PreprocessorMacros = ["SHIPPING"]

		""";

	/// The name the project's build gives its executables and their namespace: the project's
	/// name with only its letters and digits ("Sky Hopper" gives SkyHopper), "Game" in front of
	/// one that would not start with a letter.
	public static void GameName(StringView projectName, String outName)
	{
		outName.Clear();
		for (let c in projectName.RawChars)
		{
			if (c.IsLetterOrDigit && ((uint8)c < 0x80))
				outName.Append(c);
		}
		if (outName.IsEmpty || !outName[0].IsLetter)
			outName.Insert(0, "Game");
	}

	/// A part's project name: <Name>.<Kind>, except the game's Engine part, which is the game
	/// itself (<Game>).
	public static void PartName(StringView packageName, bool game, PluginPartKind kind, String outName)
	{
		outName.Set(packageName);
		if (!game || (kind != .Engine))
			outName.AppendF(".{}", kind);
	}

	/// Whether a project entry's path is the game's own package, Code/.
	public static bool IsGamePath(StringView path)
	{
		return TrimSlashes(path) == ProjectLayout.CodeDir;
	}

	// ---- the SDK ---------------------------------------------------------------------------

	/// Whether `root` is an engine SDK: Code/ with the startup libraries the entries call (and
	/// Dependencies/ beside it). A checkout is one; so is a source package of the engine, which
	/// needs no workspace of its own.
	public static bool IsSdk(StringView root)
	{
		if (root.IsEmpty)
			return false;
		if (!HasProject(root, "Code/Editor", cEditorStartup) || !HasProject(root, "Code/Engine", cPlayerStartup)
			|| !HasProject(root, "Code/Engine", cPlayerWebStartup))
			return false;
		for (int i < cToolStartups.Count)
		{
			if (!HasProject(root, "Code/Editor", cToolStartups[i]))
				return false;
		}
		return true;
	}

	/// Whether the project `name` is in `folder` (relative) under `root`.
	private static bool HasProject(StringView root, StringView folder, StringView name)
	{
		return FileExists(PathJoin(root, scope $"{folder}/{name}/BeefProj.toml", .. scope .()));
	}

	/// The engine SDK a project's build compiles against, absolute: the one SEDULOUS_SDK names,
	/// else the checkout an editor's data root is in (<sdk>/Data). False when neither is one.
	public static bool FindSdk(StringView dataRoot, String outSdk)
	{
		let variable = scope String();
		if (Environment.GetEnvironmentVariable(cSdkVariable, variable) case .Err)
			variable.Clear();
		return FindSdkFrom(variable, dataRoot, outSdk);
	}

	/// FindSdk over a given value of SEDULOUS_SDK (empty for unset): the variable when it names an
	/// SDK, else the data root's parent when that is one.
	public static bool FindSdkFrom(StringView variable, StringView dataRoot, String outSdk)
	{
		outSdk.Clear();
		if (SdkAt(variable, outSdk))
			return true;
		// The project manager's registry of installed SDKs is asked here, between the variable and
		// the checkout, once there is one.
		let data = Absolute(dataRoot, .. scope .());
		if (data.IsEmpty)
			return false;
		return SdkAt(PathParent(data, .. scope .()), outSdk);
	}

	/// `candidate` made absolute into `outSdk` when it is an SDK.
	private static bool SdkAt(StringView candidate, String outSdk)
	{
		let root = Absolute(candidate, .. scope .());
		if (!IsSdk(root))
			return false;
		outSdk.Set(root);
		return true;
	}

	/// `path` less its trailing slashes, against the current directory when relative; empty stays
	/// empty.
	private static void Absolute(StringView path, String outPath)
	{
		var trimmed = path;
		trimmed.Trim();
		trimmed = TrimSlashes(trimmed);
		if (trimmed.IsEmpty)
		{
			outPath.Clear();
			return;
		}
		if (PathIsAbsolute(trimmed))
			outPath.Set(trimmed);
		else
			PathJoin(GetCurrentDirectory(.. scope .()), trimmed, outPath);
	}

	/// Code/BeefConfig.toml: Beef's registry pointed at the SDK's library folders, by absolute
	/// path (a registry path takes no macro, and the file is per machine).
	public static void ConfigText(StringView sdk, String outText)
	{
		let root = Slashed(sdk, .. scope .());
		outText.Append("Version = 1\nUnversionedLibDirs = [");
		for (int i < cSdkLibraryDirs.Count)
			outText.AppendF("{}\"{}/{}\"", (i == 0) ? "" : ", ", root, cSdkLibraryDirs[i]);
		outText.Append("]\n");
	}

	// ---- paths -----------------------------------------------------------------------------

	/// The project's workspace: <project>/Code.
	public static void Directory(StringView projectDir, String outDir) => PathJoin(projectDir, ProjectLayout.CodeDir, outDir);

	/// Where BeefBuild puts the project's editor (or its player) for `config` on this host:
	/// Code/build/<Config>_<Platform>/<Game>Editor/<Game>Editor.
	public static void ExecutablePath(StringView projectDir, StringView gameName, bool editor, StringView config, String outPath)
	{
		let project = EntryName(gameName, editor ? BuildEntry.Editor : BuildEntry.Player, .. scope .());
		let workspace = Directory(projectDir, .. scope .());
		let build = scope $"{cBuildDir}/{config}_{BuildLayout.HostPlatformName}/{project}";
		let file = BuildLayout.ExecutableName(project, .. scope .());
		PathJoin(PathJoin(workspace, build, .. scope .()), file, outPath);
	}

	/// The web player's workspace: <project>/Code/.generated/Web, with its own BeefSpace.toml and
	/// BeefConfig.toml.
	public static void WebWorkspaceDirectory(StringView projectDir, String outDir)
	{
		PathJoin(Directory(projectDir, .. scope .()), scope $"{cGeneratedDir}/{cWebWorkspaceDir}", outDir);
	}

	/// Where BeefBuild puts the project's web player page for `config`: the stock web player's
	/// TargetDirectory, which the entry keeps as its own (Code/.generated/<Game>PlayerWeb/dist,
	/// dist-profile for Release), and its TargetName, <Game>PlayerWeb.html.
	public static void WebPagePath(StringView projectDir, StringView gameName, StringView config, String outPath)
	{
		let project = EntryName(gameName, .PlayerWeb, .. scope .());
		StringView output = (config == "Release") ? "dist-profile" : "dist";
		let dir = scope $"{cGeneratedDir}/{project}/{output}";
		PathJoin(PathJoin(Directory(projectDir, .. scope .()), dir, .. scope .()), scope $"{project}.html", outPath);
	}

	/// The suffix of an entry's name.
	public static StringView EntrySuffix(BuildEntry entry)
	{
		if (entry == .Editor)
			return cEditorSuffix;
		if (entry == .Player)
			return cPlayerSuffix;
		if (entry == .PlayerWeb)
			return cPlayerWebSuffix;
		return cToolsSuffix;
	}

	/// An entry's project name, its folder's and its executable's: <Game><Suffix>.
	public static void EntryName(StringView gameName, BuildEntry entry, String outName)
	{
		outName.Set(gameName);
		outName.Append(EntrySuffix(entry));
	}

	/// Whether an entry links parts of `kind`: those its host's role loads, and for the tools those
	/// of any of the three roles it runs (MCP, cook, export).
	public static bool Loads(BuildEntry entry, PluginPartKind kind)
	{
		if (entry == .Editor)
			return HostRole.Editor.Loads(kind);
		if ((entry == .Player) || (entry == .PlayerWeb))
			return HostRole.Player.Loads(kind);
		return HostRole.Mcp.Loads(kind) || HostRole.Cook.Loads(kind) || HostRole.Export.Loads(kind);
	}

	// ---- packages --------------------------------------------------------------------------

	/// The project's packages: each entry with a path, its manifest read from the folder. A
	/// folder without a manifest of the entry's id, or a part the manifest lists without its
	/// project, is a problem in `outProblems`, and the package is left out.
	public static void Packages(StringView projectDir, ProjectSettings settings, List<ProjectPackage> outPackages, List<String> outProblems)
	{
		for (let entry in settings.Plugins)
		{
			if (entry.Path.IsEmpty)
				continue;
			let dir = PathJoin(projectDir, entry.Path, .. scope .());
			let manifest = scope PluginManifest();
			if ((PluginManifest.Load(dir, manifest) case .Err) || (manifest.Id != entry.Id))
			{
				outProblems.Add(new $"plugin '{entry.Id}': '{entry.Path}' holds no Plugin.xml of that id");
				continue;
			}
			let package = new ProjectPackage();
			package.Id.Set(entry.Id);
			package.Directory.Set(dir);
			package.Path.Set(entry.Path);
			package.IsGame = IsGamePath(entry.Path);
			if (package.IsGame)
				GameName(settings.Name, package.Name);
			else
				PathFilename(dir, package.Name);
			bool complete = true;
			for (let part in manifest.Parts)
			{
				if (!(PluginPartKind.Parse(part.Kind) case .Ok(let kind)))
				{
					outProblems.Add(new $"plugin '{entry.Id}': its manifest lists a part of no kind '{part.Kind}'");
					complete = false;
					continue;
				}
				let partName = package.PartName(kind, .. scope .());
				if (!FileExists(PathJoin(dir, scope $"{partName}/BeefProj.toml", .. scope .())))
				{
					outProblems.Add(new $"plugin '{entry.Id}': its {part.Kind} part has no project ({partName}/BeefProj.toml)");
					complete = false;
					continue;
				}
				package.Parts.Add(kind);
			}
			if (complete)
				outPackages.Add(package);
			else
				delete package;
		}
	}

	// ---- generation ------------------------------------------------------------------------

	/// Writes what a build of the project needs in Code/: BeefConfig.toml (the registry pointed
	/// at `sdk`), BeefSpace.toml (merged, WorkspaceText), a .gitignore when there is none, and
	/// every entry (BuildEntry) under .generated, with the web player's own workspace
	/// (.generated/Web: WebWorkspaceText and its registry file). A file whose content is unchanged
	/// is left alone, so a build after a generate that changed nothing rebuilds nothing. Refused,
	/// with why in `outError`, for a problem with a package or an SDK it cannot read.
	public static Result<void, ErrorCode> Generate(StringView projectDir, ProjectSettings settings, StringView sdk, String outError)
	{
		let packages = scope List<ProjectPackage>();
		defer { ClearAndDeleteItems!(packages); }
		let problems = scope List<String>();
		defer { ClearAndDeleteItems!(problems); }
		Packages(projectDir, settings, packages, problems);
		if (!problems.IsEmpty)
		{
			outError.Set(problems[0]);
			return .Err(.InvalidArgument);
		}

		// The configs the entries take over from the stock executables, made to reach the SDK: the
		// editor's and the tools' post-build steps, the web player's link and what it stages (all
		// but its output folder). The desktop player has none.
		let editorConfigs = scope String();
		let webConfigs = scope String();
		let toolsConfigs = scope String();
		let webDir = PathJoin(sdk, cStockWebDir, .. scope .());
		if ((ReadStockConfigs(sdk, cStockEditorProject, "$(WorkspaceDir)/..", sdk, "", editorConfigs, outError) case .Err)
			|| (ReadStockConfigs(sdk, cStockWebProject, "$(ProjectDir)", webDir, cWebOwnKey, webConfigs, outError) case .Err)
			|| (ReadStockConfigs(sdk, cStockToolsProject, "$(WorkspaceDir)/..", sdk, "", toolsConfigs, outError) case .Err))
			return .Err(.NotFound);

		let game = GameName(settings.Name, .. scope .());
		let workspace = Directory(projectDir, .. scope .());
		let generated = PathJoin(workspace, cGeneratedDir, .. scope .());
		if ((WriteWorkspace(projectDir, game, packages) case .Err)
			|| (WriteIfChanged(PathJoin(workspace, cConfigFile, .. scope .()), ConfigText(sdk, .. scope .())) case .Err)
			|| (WriteIgnore(workspace) case .Err)
			|| (WriteEntry(generated, game, .Editor, packages, editorConfigs) case .Err)
			|| (WriteEntry(generated, game, .Player, packages, "") case .Err)
			|| (WriteEntry(generated, game, .PlayerWeb, packages, webConfigs) case .Err)
			|| (WriteEntry(generated, game, .Tools, packages, toolsConfigs) case .Err)
			|| (WriteWebWorkspace(projectDir, game, packages, sdk) case .Err))
		{
			outError.Set(scope $"could not write the project's workspace in '{workspace}'");
			return .Err(.Internal);
		}
		return .Ok;
	}

	/// The stock project at `relative` in the SDK, its configs made to reach the SDK (StockConfigs)
	/// into `outText`. Refused, with why in `outError`, when the SDK has no such project.
	private static Result<void> ReadStockConfigs(StringView sdk, StringView relative, StringView macro, StringView path, StringView ownKey,
		String outText, String outError)
	{
		let stock = scope String();
		if (ReadText(PathJoin(sdk, relative, .. scope .()), stock) case .Err)
		{
			outError.Set(scope $"the engine SDK at '{sdk}' has no stock project {relative}");
			return .Err;
		}
		StockConfigs(stock, macro, path, ownKey, outText);
		return .Ok;
	}

	/// The web player's workspace and the registry file beside it (Beef reads the BeefConfig.toml
	/// in a workspace's folder), each written when it changed.
	private static Result<void> WriteWebWorkspace(StringView projectDir, StringView game, List<ProjectPackage> packages, StringView sdk)
	{
		let dir = WebWorkspaceDirectory(projectDir, .. scope .());
		if ((WriteIfChanged(PathJoin(dir, cSpaceFile, .. scope .()), WebWorkspaceText(game, packages, .. scope .())) case .Err)
			|| (WriteIfChanged(PathJoin(dir, cConfigFile, .. scope .()), ConfigText(sdk, .. scope .())) case .Err))
			return .Err;
		return .Ok;
	}

	/// An entry's project and Main in .generated/<Game><Suffix>, each written when it changed.
	private static Result<void> WriteEntry(StringView generated, StringView game, BuildEntry entry, List<ProjectPackage> packages, StringView configs)
	{
		let dir = PathJoin(generated, EntryName(game, entry, .. scope .()), .. scope .());
		if ((WriteIfChanged(PathJoin(dir, "BeefProj.toml", .. scope .()), ExecutableProject(game, entry, packages, configs, .. scope .())) case .Err)
			|| (WriteIfChanged(PathJoin(dir, "src/Program.bf", .. scope .()), ProgramText(game, entry, .. scope .())) case .Err))
			return .Err;
		return .Ok;
	}

	/// Code/BeefSpace.toml brought up to date with the project's packages as they read (one with
	/// a problem left out), and Code/.gitignore when there is none: what Add Native Code writes,
	/// without the SDK a build needs.
	public static Result<void> UpdateWorkspace(StringView projectDir, ProjectSettings settings)
	{
		let packages = scope List<ProjectPackage>();
		defer { ClearAndDeleteItems!(packages); }
		let problems = scope List<String>();
		defer { ClearAndDeleteItems!(problems); }
		Packages(projectDir, settings, packages, problems);
		let game = GameName(settings.Name, .. scope .());
		if ((WriteWorkspace(projectDir, game, packages) case .Err) || (WriteIgnore(Directory(projectDir, .. scope .())) case .Err))
			return .Err;
		return .Ok;
	}

	/// The workspace merged over the one in Code/ (none is an empty one), written when it changed.
	private static Result<void> WriteWorkspace(StringView projectDir, StringView game, List<ProjectPackage> packages)
	{
		let path = PathJoin(Directory(projectDir, .. scope .()), cSpaceFile, .. scope .());
		let existing = scope String();
		if (ReadText(path, existing) case .Err)
			existing.Clear();
		return WriteIfChanged(path, WorkspaceText(existing, game, packages, .. scope .()));
	}

	/// Code/.gitignore, what builds write (cWrittenDirs, cWrittenFiles), when Code/ has none: one
	/// that is there is the user's.
	private static Result<void> WriteIgnore(StringView workspace)
	{
		let path = PathJoin(workspace, cIgnoreFile, .. scope .());
		if (FileExists(path))
			return .Ok;
		let text = scope String();
		IgnoreText(text);
		return WriteIfChanged(path, text);
	}

	/// The .gitignore a new Code/ gets.
	public static void IgnoreText(String outText)
	{
		outText.Append("# Written by builds and the Beef IDE.\n");
		for (int i < cWrittenDirs.Count)
			outText.AppendF("/{}/\n", cWrittenDirs[i]);
		for (int i < cWrittenFiles.Count)
			outText.AppendF("/{}\n", cWrittenFiles[i]);
	}

	/// The projects the workspace must list, and each one's path relative to Code/: every part
	/// of every package, then the desktop entries (the editor, the player and the tools). The web
	/// player is not among them: it has a workspace of its own (WebWorkspaceText).
	public static void WorkspaceProjects(StringView game, List<ProjectPackage> packages, List<String> outNames, List<String> outPaths)
	{
		for (let package in packages)
		{
			for (let kind in package.Parts)
			{
				let part = package.PartName(kind, .. new .());
				outNames.Add(part);
				outPaths.Add(PartPath(package, part, 0, .. new .()));
			}
		}
		for (let entry in BuildEntry[3](.Editor, .Player, .Tools))
		{
			let name = EntryName(game, entry, .. new .());
			outNames.Add(name);
			outPaths.Add(new $"{cGeneratedDir}/{name}");
		}
	}

	/// A part's project folder relative to a workspace `depth` folders below Code/ (0 for Code/
	/// itself), or absolute for a package the project names by absolute path.
	private static void PartPath(ProjectPackage package, StringView part, int depth, String outPath)
	{
		let up = scope String();
		for (int i < depth)
			up.Append("../");
		if (package.IsGame)
			outPath.AppendF("{}{}", up, part);
		else if (PathIsAbsolute(package.Path))
			PathJoin(package.Directory, part, outPath);
		else
			outPath.AppendF("{}../{}/{}", up, TrimSlashes(package.Path), part);
		outPath.Replace('\\', '/');
	}

	/// The web player's own workspace, Code/.generated/Web/BeefSpace.toml: the parts a player
	/// loads and <Game>PlayerWeb, with the engine's configs. A workspace of its own because
	/// BeefBuild compiles every enabled project of a workspace, and the editor's and the tools'
	/// dependencies, which the registry brings into the project's workspace, do not compile for
	/// wasm32; disabling the entries there would not disable what they bring in. Generated whole:
	/// it is not the user's.
	public static void WebWorkspaceText(StringView game, List<ProjectPackage> packages, String outText)
	{
		let entry = EntryName(game, .PlayerWeb, .. scope .());
		outText.AppendF("FileVersion = 1\n\n[Workspace]\nStartupProject = \"{}\"\n\n[Projects]\n", entry);
		for (let package in packages)
		{
			for (let kind in package.Parts)
			{
				if (!Loads(.PlayerWeb, kind))
					continue;
				let part = package.PartName(kind, .. scope .());
				ProjectLine(part, PartPath(package, part, 2, .. scope .()), outText);
			}
		}
		ProjectLine(entry, scope $"../{entry}", outText);
		outText.AppendF("\n{}", cWorkspaceConfigs);
	}

	/// Code/BeefSpace.toml from `existing` (the file as it is; empty for none). The file is the
	/// user's: every line of it stays, and what the build needs is added. A [Workspace] starting
	/// the editor when there is none; a [Projects] line for each part and entry it does not list
	/// (by name; a user's line naming one wins, its path too); and the engine's configs
	/// (cWorkspaceConfigs) when it has no [Configs.*]. A line added for a part that has since gone
	/// stays, as a user's would: only the user removes lines.
	public static void WorkspaceText(StringView existing, StringView game, List<ProjectPackage> packages, String outText)
	{
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		let paths = scope List<String>();
		defer { ClearAndDeleteItems!(paths); }
		WorkspaceProjects(game, packages, names, paths);
		let startup = scope $"[Workspace]\nStartupProject = \"{game}{cEditorSuffix}\"\n";

		if (existing.IsWhiteSpace)
		{
			outText.AppendF("FileVersion = 1\n\n{}\n[Projects]\n", startup);
			for (int i < names.Count)
				ProjectLine(names[i], paths[i], outText);
			outText.AppendF("\n{}", cWorkspaceConfigs);
			return;
		}

		let text = scope String(existing);
		if (!text.EndsWith("\n"))
			text.Append('\n');
		// The last is the empty one after the final newline.
		let lines = scope List<StringView>();
		for (let line in text.Split('\n'))
			lines.Add(line);
		let end = lines.Count - 1;

		int firstHeader = -1;
		int projectsHeader = -1;
		int projectsAt = -1;
		bool hasWorkspace = false;
		bool hasConfigs = false;
		bool inProjects = false;
		let listed = scope List<String>();
		defer { ClearAndDeleteItems!(listed); }
		for (int i < end)
		{
			var line = lines[i];
			line.Trim();
			if (line.StartsWith("["))
			{
				if (firstHeader < 0)
					firstHeader = i;
				hasWorkspace |= line == "[Workspace]";
				hasConfigs |= line.StartsWith("[Configs.");
				inProjects = (line == "[Projects]") && (projectsHeader < 0);
				if (inProjects)
				{
					projectsHeader = i;
					projectsAt = i + 1;
				}
				continue;
			}
			if (!inProjects || line.IsEmpty || line.StartsWith("#"))
				continue;
			// New lines go after the section's last, before the blank lines that end it.
			projectsAt = i + 1;
			let equals = line.IndexOf('=');
			if (equals <= 0)
				continue;
			var name = line.Substring(0, equals);
			name.Trim();
			name.Trim('"');
			listed.Add(new .(name));
		}

		let missing = scope String();
		for (int i < names.Count)
		{
			bool there = false;
			for (let name in listed)
				there |= name == names[i];
			if (!there)
				ProjectLine(names[i], paths[i], missing);
		}
		let workspace = scope String();
		if (!hasWorkspace)
			workspace.AppendF("{}\n", startup);
		// Before the first table: a top-level key (FileVersion) must come before any.
		let workspaceAt = (firstHeader < 0) ? end : firstHeader;

		for (int i < end)
		{
			if (i == workspaceAt)
				outText.Append(workspace);
			if (i == projectsAt)
				outText.Append(missing);
			outText.Append(lines[i]);
			outText.Append('\n');
		}
		if (workspaceAt == end)
			outText.Append(workspace);
		if (projectsAt == end)
			outText.Append(missing);
		if (projectsHeader < 0)
		{
			BlankLine(outText);
			outText.AppendF("[Projects]\n{}", missing);
		}
		if (!hasConfigs)
		{
			BlankLine(outText);
			outText.Append(cWorkspaceConfigs);
		}
	}

	/// One blank line at the end of `outText` before a new table, not a second.
	private static void BlankLine(String outText)
	{
		if (!outText.EndsWith("\n\n"))
			outText.Append('\n');
	}

	private static void ProjectLine(StringView name, StringView path, String outText)
	{
		outText.AppendF("\"{}\" = {{Path = \"{}\"}}\n", name, path);
	}

	/// An executable's project: the stock startup (the tools' three) and every part its roles load.
	/// The tools are a console application, as the stock ones are.
	public static void ExecutableProject(StringView game, BuildEntry entry, List<ProjectPackage> packages, StringView configs, String outText)
	{
		let name = EntryName(game, entry, .. scope .());
		let targetType = (entry == .Tools) ? "BeefConsoleApplication" : "BeefGUIApplication";
		outText.AppendF("FileVersion = 1\n\n[Project]\nName = \"{}\"\nTargetType = \"{}\"\n", name, targetType);
		outText.AppendF("StartupObject = \"{}.Program\"\n\n[Dependencies]\ncorlib = \"*\"\n", name);
		if (entry == .Tools)
		{
			for (int i < cToolStartups.Count)
				outText.AppendF("\"{}\" = \"*\"\n", cToolStartups[i]);
		}
		else
			outText.AppendF("\"{}\" = \"*\"\n", StartupLibrary(entry));
		for (let package in packages)
		{
			for (let kind in package.Parts)
			{
				if (Loads(entry, kind))
					outText.AppendF("\"{}\" = \"*\"\n", package.PartName(kind, .. scope .()));
			}
		}
		if (!configs.IsEmpty)
			outText.AppendF("\n{}", configs);
	}

	/// The startup library of an entry other than the tools.
	private static StringView StartupLibrary(BuildEntry entry)
	{
		if (entry == .Editor)
			return cEditorStartup;
		if (entry == .PlayerWeb)
			return cPlayerWebStartup;
		return cPlayerStartup;
	}

	/// The call the Main of an entry other than the tools makes (cToolCalls holds the tools').
	private static StringView StartupCall(BuildEntry entry)
	{
		if (entry == .Editor)
			return "Sedulous.Editor.Main.EditorMain.Run";
		if (entry == .PlayerWeb)
			return "Sedulous.Engine.Player.WebMain.WebPlayerMain.Run";
		return "Sedulous.Engine.Player.DesktopMain.DesktopPlayerMain.Run";
	}

	/// A stock project's [Configs.*] sections, its post-build steps and link settings among them,
	/// with `macro` made `path`, absolute (the entry is generated per machine), so what the stock
	/// reaches relative to itself the entry reaches in the SDK. A line setting `ownKey` keeps the
	/// macro: that setting stays the generated project's own.
	public static void StockConfigs(StringView stockProject, StringView macro, StringView path, StringView ownKey, String outText)
	{
		let index = stockProject.IndexOf("\n[Configs.");
		if (index < 0)
			return;
		let slashed = Slashed(path, .. scope .());
		bool first = true;
		for (let line in stockProject.Substring(index + 1).Split('\n'))
		{
			if (!first)
				outText.Append('\n');
			first = false;
			if (!ownKey.IsEmpty && SetsKey(line, ownKey))
			{
				outText.Append(line);
				continue;
			}
			let made = scope String(line);
			made.Replace(macro, slashed);
			outText.Append(made);
		}
	}

	/// Whether a TOML line sets `key` (`key = ...`).
	private static bool SetsKey(StringView line, StringView key)
	{
		var trimmed = line;
		trimmed.Trim();
		if (!trimmed.StartsWith(key))
			return false;
		var rest = trimmed.Substring(key.Length);
		rest.TrimStart();
		return rest.StartsWith('=');
	}

	/// The executable's Main: one call into the stock startup. The tools' dispatches on its first
	/// argument (cToolCommands) and hands the rest to that subcommand's startup; anything else is
	/// a usage line and cToolsUsageExit.
	public static void ProgramText(StringView game, BuildEntry entry, String outText)
	{
		let name = EntryName(game, entry, .. scope .());
		if (entry != .Tools)
		{
			outText.AppendF("namespace {};\n\nclass Program\n{{\n\tpublic static int Main(System.String[] args) => {}(args);\n}}\n",
				name, StartupCall(entry));
			return;
		}
		outText.AppendF("namespace {};\n\nclass Program\n{{\n\tpublic static int Main(System.String[] args)\n\t{{\n", name);
		outText.Append("\t\tif (args.Count > 0)\n\t\t{\n");
		outText.Append("\t\t\tlet rest = scope System.String[args.Count - 1];\n");
		outText.Append("\t\t\tfor (int i < rest.Count)\n\t\t\t\trest[i] = args[i + 1];\n");
		let commands = scope String();
		for (int i < cToolCommands.Count)
		{
			outText.AppendF("\t\t\tif (args[0] == \"{}\")\n\t\t\t\treturn {}(rest);\n", cToolCommands[i], cToolCalls[i]);
			commands.AppendF("{}{}", (i == 0) ? "" : "|", cToolCommands[i]);
		}
		outText.Append("\t\t}\n");
		outText.AppendF("\t\tSystem.Console.Error.WriteLine(\"usage: {} {} [arguments]\");\n", name, commands);
		outText.AppendF("\t\treturn {};\n\t}}\n}}\n", cToolsUsageExit);
	}

	// ---- builds ----------------------------------------------------------------------------

	/// The build config a preset's template config names: a Release template is a ShippingRelease
	/// build and a Profile one a Release build (BuildLayout.TemplateConfigFor, inverted); Debug and
	/// Test are themselves.
	public static void BuildConfigFor(StringView presetConfig, String outConfig)
	{
		if (presetConfig.IsEmpty || (presetConfig == "Release"))
			outConfig.Set("ShippingRelease");
		else if (presetConfig == "Profile")
			outConfig.Set("Release");
		else
			outConfig.Set(presetConfig);
	}

	/// The configs Build Project makes the player in: Debug, then each one a preset for this host
	/// exports with, once each in the order the presets name them. The editor is built in Debug.
	public static void PlayerConfigs(ExportPresetSet presets, List<String> outConfigs)
	{
		outConfigs.Add(new .("Debug"));
		for (let preset in presets.Presets)
		{
			if (preset.Platform != BuildLayout.HostPlatformName)
				continue;
			let config = BuildConfigFor(preset.Config, .. scope .());
			bool listed = false;
			for (let existing in outConfigs)
				listed |= existing == config;
			if (!listed)
				outConfigs.Add(new .(config));
		}
	}

	/// Whether the project enables a package of its own (an entry with a path).
	public static bool HasPackages(ProjectSettings settings)
	{
		for (let entry in settings.Plugins)
		{
			if (!entry.Path.IsEmpty)
				return true;
		}
		return false;
	}

	/// The first `name` (with the host's executable suffix) in the directories of `searchPath`,
	/// a PATH value. False when none holds it.
	public static bool FindOnPath(StringView searchPath, StringView name, String outPath)
	{
		let found = scope List<String>();
		defer { ClearAndDeleteItems!(found); }
		AllOnPath(searchPath, name, found);
		if (found.IsEmpty)
			return false;
		outPath.Set(found[0]);
		return true;
	}

	/// Every `name` (with the host's executable suffix) in the directories of `searchPath`, in
	/// its order, into `outPaths` (the caller's).
	public static void AllOnPath(StringView searchPath, StringView name, List<String> outPaths)
	{
		let file = BuildLayout.ExecutableName(name, .. scope .());
#if BF_PLATFORM_WINDOWS
		let separator = ';';
#else
		let separator = ':';
#endif
		for (let dir in searchPath.Split(separator))
		{
			if (dir.IsEmpty)
				continue;
			let candidate = PathJoin(dir, file, .. scope .());
			if (FileExists(candidate))
				outPaths.Add(new .(candidate));
		}
	}

	/// BeefBuild: the one BEEFBUILD names, else the first on PATH whose install has corlib, else
	/// the managed install (ManagedBeefBuild). Refused, with every candidate tried and why each
	/// was passed over in `outError`, when none will build.
	public static bool FindBeefBuild(String outPath, String outError)
	{
		let variable = scope String();
		if (Environment.GetEnvironmentVariable(cBeefBuildVariable, variable) case .Err)
			variable.Clear();
		let searchPath = scope String();
		if (Environment.GetEnvironmentVariable("PATH", searchPath) case .Err)
			searchPath.Clear();
		return FindBeefBuildFrom(variable, searchPath, outPath, outError);
	}

	/// FindBeefBuild over given values of BEEFBUILD and PATH (empty for unset).
	public static bool FindBeefBuildFrom(StringView variable, StringView searchPath, String outPath, String outError)
	{
		let tried = scope String();
		if (!variable.IsEmpty && AcceptBeefBuild(variable, cBeefBuildVariable, tried, outPath))
			return true;

		let onPath = scope List<String>();
		defer { ClearAndDeleteItems!(onPath); }
		AllOnPath(searchPath, "BeefBuild", onPath);
		for (let candidate in onPath)
		{
			if (AcceptBeefBuild(candidate, "PATH", tried, outPath))
				return true;
		}
		if (onPath.IsEmpty)
			AppendTried(tried, "PATH: no BeefBuild there");

		let managed = scope String();
		if (ManagedBeefBuild(managed) && AcceptBeefBuild(managed, "the managed install", tried, outPath))
			return true;

		outError.Set(scope $"BeefBuild not found: set {cBeefBuildVariable}, or put BeefBuild on PATH (tried: {tried})");
		return false;
	}

	/// The BeefBuild of a toolchain the editor installs and keeps up to date itself. None yet:
	/// that install is to come, and until it does this finds nothing, so BEEFBUILD and PATH are
	/// the only places looked.
	public static bool ManagedBeefBuild(String outPath)
	{
		outPath.Clear();
		return false;
	}

	/// `candidate` into `outPath` when it is a file and its install has corlib (HasCorlib); else
	/// why not, after `source` (where it came from), appended to `tried`.
	private static bool AcceptBeefBuild(StringView candidate, StringView source, String tried, String outPath)
	{
		if (!FileExists(candidate))
		{
			AppendTried(tried, scope $"{source} '{candidate}': no such file");
			return false;
		}
		let why = scope String();
		if (!HasCorlib(candidate, why))
		{
			AppendTried(tried, scope $"{source} '{candidate}': {why}");
			return false;
		}
		outPath.Set(candidate);
		return true;
	}

	private static void AppendTried(String tried, StringView entry)
	{
		if (!tried.IsEmpty)
			tried.Append("; ");
		tried.Append(entry);
	}

	/// Whether the Beef install of the BeefBuild at `executable` has corlib, which every build
	/// needs, found the way BeefBuild finds it: the BeefConfig.toml in the executable's folder
	/// (links followed first, as BeefBuild reads its own path) lists library folders
	/// (UnversionedLibDirs, relative to that folder), and corlib is a folder named corlib with a
	/// BeefProj.toml somewhere under one of them. A source build's IDE/dist lists ../../BeefLibs,
	/// an installed one's bin ../BeefLibs. When not, why not in `outWhy`.
	public static bool HasCorlib(StringView executable, String outWhy)
	{
		let real = ResolveLinks(executable, .. scope .());
		let install = PathParent(real, .. scope .());
		let configPath = PathJoin(install, cConfigFile, .. scope .());
		let config = scope String();
		if (ReadText(configPath, config) case .Err)
		{
			outWhy.Set(scope $"no {cConfigFile} beside it, where BeefBuild looks for its libraries");
			return false;
		}
		let libraries = scope List<String>();
		defer { ClearAndDeleteItems!(libraries); }
		LibraryDirs(config, libraries);
		for (let library in libraries)
		{
			if (FindLibrary(PathJoin(install, library, .. scope .()), "corlib", cLibrarySearchDepth))
				return true;
		}
		outWhy.Set(scope $"no corlib under the library folders its {cConfigFile} names");
		return false;
	}

	/// The UnversionedLibDirs of a BeefConfig.toml, each string of the array as written (one
	/// line or several, "basic" or 'literal' strings).
	public static void LibraryDirs(StringView config, List<String> outDirs)
	{
		let key = config.IndexOf("UnversionedLibDirs");
		if (key < 0)
			return;
		let open = config.IndexOf('[', key);
		if (open < 0)
			return;
		int i = open + 1;
		while (i < config.Length)
		{
			let c = config[i];
			if (c == ']')
				break;
			if ((c == '"') || (c == '\''))
			{
				let value = new String();
				i++;
				while ((i < config.Length) && (config[i] != c))
				{
					// A basic string's escape: the next character as it is (a path's backslash).
					if ((c == '"') && (config[i] == '\\') && (i + 1 < config.Length))
						i++;
					value.Append(config[i]);
					i++;
				}
				outDirs.Add(value);
			}
			i++;
		}
	}

	/// How deep FindLibrary looks under a library folder. BeefBuild's registry walks every
	/// folder; corlib sits at the top of BeefLibs, and the bound keeps a folder linked into
	/// itself from walking forever.
	private const int cLibrarySearchDepth = 8;

	/// Whether a folder `name` holding a BeefProj.toml is under `dir`, `depth` levels down at most.
	private static bool FindLibrary(StringView dir, StringView name, int depth)
	{
		if (depth <= 0)
			return false;
		let subs = scope List<String>();
		defer { ClearAndDeleteItems!(subs); }
		ListDirectory(dir, scope [&](entry, isDirectory) =>
			{
				if (isDirectory)
					subs.Add(new .(entry));
			});
		for (let sub in subs)
		{
			let path = PathJoin(dir, sub, .. scope .());
			if ((sub == name) && FileExists(PathJoin(path, "BeefProj.toml", .. scope .())))
				return true;
		}
		for (let sub in subs)
		{
			if (FindLibrary(PathJoin(dir, sub, .. scope .()), name, depth - 1))
				return true;
		}
		return false;
	}

#if BF_PLATFORM_LINUX || BF_PLATFORM_MACOS
	[CLink]
	private static extern char8* realpath(char8* path, char8* resolved);
#endif

	/// `path` with its links followed, as the system resolves an executable's own path; `path`
	/// as it is where that cannot be done (Windows, which BeefBuild does not resolve either).
	private static void ResolveLinks(StringView path, String outPath)
	{
		outPath.Set(path);
#if BF_PLATFORM_LINUX || BF_PLATFORM_MACOS
		// PATH_MAX on both.
		let resolved = scope char8[4096];
		if (realpath(scope String(path).CStr(), resolved.Ptr) != null)
			outPath.Set(StringView(resolved.Ptr));
#endif
	}

	/// Whether the project's editor for `config` is missing or older than a file of the project's
	/// packages: a change to the game's code the editor running it has not been built with.
	public static bool IsStale(StringView projectDir, ProjectSettings settings, StringView config)
	{
		return FreshExecutable(projectDir, settings, true, config, scope .()) case .Err;
	}

	/// The project's player for `config`, when it is built and newer than every file of the
	/// project's packages: what an export of a project with packages ships. In the game's package
	/// (Code/) what builds write is not counted, or the player would never be fresh. NotFound for
	/// a player never built, InvalidArgument for one older than a file of a package.
	public static Result<void, ErrorCode> FreshPlayer(StringView projectDir, ProjectSettings settings, StringView config, String outPath)
		=> FreshExecutable(projectDir, settings, false, config, outPath);

	/// FreshPlayer for the editor or the player.
	private static Result<void, ErrorCode> FreshExecutable(StringView projectDir, ProjectSettings settings, bool editor, StringView config, String outPath)
	{
		let game = GameName(settings.Name, .. scope .());
		ExecutablePath(projectDir, game, editor, config, outPath);
		if (!FileStat(outPath, let size, let built))
			return .Err(.NotFound);
		for (let entry in settings.Plugins)
		{
			if (entry.Path.IsEmpty)
				continue;
			if (NewestFile(PathJoin(projectDir, entry.Path, .. scope .()), IsGamePath(entry.Path)) > built)
				return .Err(.InvalidArgument);
		}
		return .Ok;
	}

	/// The newest modification time of any file under `dir`, nought for none; with `skipWritten`,
	/// less what builds write at its top (cWrittenDirs, cWrittenFiles).
	private static int64 NewestFile(StringView dir, bool skipWritten = false)
	{
		int64 newest = 0;
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		let directories = scope List<String>();
		defer { ClearAndDeleteItems!(directories); }
		ListDirectory(dir, scope [&](name, isDirectory) =>
			{
				if (skipWritten && IsWritten(name, isDirectory))
					return;
				if (isDirectory)
					directories.Add(new .(name));
				else
					names.Add(new .(name));
			});
		for (let name in names)
		{
			if (FileStat(PathJoin(dir, name, .. scope .()), let size, let ticks) && (ticks > newest))
				newest = ticks;
		}
		for (let sub in directories)
			newest = Math.Max(newest, NewestFile(PathJoin(dir, sub, .. scope .())));
		return newest;
	}

	/// The first executable a build of `game` should have made and has not, in `outPath`: the
	/// editor in Debug, then the player in each of `playerConfigs`. False when all are there.
	public static bool FindUnbuilt(StringView projectDir, StringView game, List<String> playerConfigs, String outPath)
	{
		ExecutablePath(projectDir, game, true, "Debug", outPath..Clear());
		if (!FileExists(outPath))
			return true;
		for (let config in playerConfigs)
		{
			ExecutablePath(projectDir, game, false, config, outPath..Clear());
			if (!FileExists(outPath))
				return true;
		}
		outPath.Clear();
		return false;
	}

	/// Whether `name`, at the top of the game's package, is something builds write.
	private static bool IsWritten(StringView name, bool isDirectory)
	{
		if (isDirectory)
		{
			for (int i < cWrittenDirs.Count)
			{
				if (name == cWrittenDirs[i])
					return true;
			}
			return false;
		}
		for (int i < cWrittenFiles.Count)
		{
			if (name == cWrittenFiles[i])
				return true;
		}
		return false;
	}

	/// `path` less its trailing slashes.
	private static StringView TrimSlashes(StringView path)
	{
		var trimmed = path;
		while (trimmed.EndsWith('/') || trimmed.EndsWith('\\'))
			trimmed = trimmed.Substring(0, trimmed.Length - 1);
		return trimmed;
	}

	/// A path with forward slashes, as the workspace and project files take one on every host.
	private static void Slashed(StringView path, String outPath)
	{
		outPath.Set(path);
		outPath.Replace('\\', '/');
	}

	private static Result<void> ReadText(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		if (ReadFile(path, bytes) case .Err)
			return .Err;
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
		return .Ok;
	}

	/// Writes `text` unless the file holds it already, making the folders on the way.
	private static Result<void> WriteIfChanged(StringView path, StringView text)
	{
		let existing = scope String();
		if ((ReadText(path, existing) case .Ok) && (existing == text))
			return .Ok;
		if (!MakeDirectories(PathParent(path, .. scope .())))
			return .Err;
		if (WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Err)
			return .Err;
		return .Ok;
	}

	private static bool MakeDirectories(StringView dir)
	{
		if (dir.IsEmpty || DirectoryExists(dir))
			return true;
		if (!MakeDirectories(PathParent(dir, .. scope .())))
			return false;
		return CreateDirectory(dir) || DirectoryExists(dir);
	}
}
