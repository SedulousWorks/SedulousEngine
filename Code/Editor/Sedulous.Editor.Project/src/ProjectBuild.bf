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
	/// name for any other ("NativeSample" gives NativeSample.Engine).
	public String Name = new .() ~ delete _;
	/// The game's own package (Code/), whose Engine part is the project <Game>, not <Game>.Engine.
	public bool IsGame;
	public List<PluginPartKind> Parts = new .() ~ delete _;

	/// The project name of the part of `kind`, which is its folder's name too.
	public void PartName(PluginPartKind kind, String outName) => ProjectBuild.PartName(Name, IsGame, kind, outName);
}

/// A project's own build: the editor and the player linked with the project's packages.
///
/// A Beef library cannot be loaded beside the engine (each carries a runtime of its own), so a
/// package's parts are compiled in. The stock editor and player link the engine's plugins; a
/// project with packages of its own builds <Game>Editor and <Game>Player in its own workspace,
/// Code/. Each is a one-line Main over the stock startup (EditorMain, DesktopPlayerMain) with the
/// parts its role loads as dependencies, generated under Code/.generated. They are named without a
/// dot, so no part (<Game> or <Name>.<Kind>) can take the name.
///
/// The workspace lists only the project's own projects. Everything else (the engine's libraries
/// and their dependencies) Beef finds through its library registry: Code/BeefConfig.toml, written
/// per machine, points it at the folders of the engine SDK. So a build needs an SDK: a source
/// tree of the engine, found through SEDULOUS_SDK or as the checkout an editor runs from.
static class ProjectBuild
{
	/// Under Code/: the generated entries, and BeefBuild's output.
	public const String cGeneratedDir = ".generated";
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
	/// The library each executable's Main calls, and its call.
	public const String cEditorStartup = "Sedulous.Editor.Main";
	public const String cPlayerStartup = "Sedulous.Engine.Player.DesktopMain";
	/// The stock editor's project, whose post-build steps (naga and tint beside the executable)
	/// the project's editor takes over.
	public const String cStockEditorProject = "Code/Tools/Sedulous.Tools.Editor/BeefProj.toml";

	/// Names an SDK root ahead of any other.
	public const String cSdkVariable = "SEDULOUS_SDK";
	/// The SDK's folders Beef's registry walks for projects, relative to the SDK root. Not the
	/// whole of Code/: the registry walks every directory under each, and Code/build is huge; and
	/// not Code/Tools, Integration, Samples or Deprecated, which no game links.
	public const String[6] cSdkLibraryDirs = .("Code/Foundation", "Code/Engine", "Code/Pipeline", "Code/Editor", "Code/Plugins", "Dependencies");

	/// The engine workspace's workspace-level settings per config and platform (Code/BeefSpace.toml
	/// less every ConfigSelections line, which name the engine's own projects): the wasm32 heap and
	/// debug checks, the debug info a release drops, and SHIPPING. A project's new workspace starts
	/// with them; ProjectBuildTests checks they match the engine's.
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

	/// Whether `root` is an engine SDK: Code/ with the two startup libraries the entries call
	/// (and Dependencies/ beside it). A checkout is one; so is a source package of the engine,
	/// which needs no workspace of its own.
	public static bool IsSdk(StringView root)
	{
		if (root.IsEmpty)
			return false;
		return FileExists(PathJoin(root, "Code/Editor/Sedulous.Editor.Main/BeefProj.toml", .. scope .()))
			&& FileExists(PathJoin(root, "Code/Engine/Sedulous.Engine.Player.DesktopMain/BeefProj.toml", .. scope .()));
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
		let project = scope $"{gameName}{editor ? cEditorSuffix : cPlayerSuffix}";
		let workspace = Directory(projectDir, .. scope .());
		let build = scope $"{cBuildDir}/{config}_{BuildLayout.HostPlatformName}/{project}";
		let file = BuildLayout.ExecutableName(project, .. scope .());
		PathJoin(PathJoin(workspace, build, .. scope .()), file, outPath);
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
	/// at `sdk`), BeefSpace.toml (merged, WorkspaceText), a .gitignore when there is none, and the
	/// entries <Game>Editor and <Game>Player under .generated. A file whose content is unchanged
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

		let stockEditor = scope String();
		if (ReadText(PathJoin(sdk, cStockEditorProject, .. scope .()), stockEditor) case .Err)
		{
			outError.Set(scope $"the engine SDK at '{sdk}' has no stock editor project ({cStockEditorProject})");
			return .Err(.NotFound);
		}

		let game = GameName(settings.Name, .. scope .());
		let workspace = Directory(projectDir, .. scope .());
		let editor = scope String();
		ExecutableProject(game, true, packages, StockEditorConfigs(stockEditor, sdk, .. scope .()), editor);
		let player = scope String();
		ExecutableProject(game, false, packages, "", player);

		let generated = PathJoin(workspace, cGeneratedDir, .. scope .());
		let editorDir = PathJoin(generated, scope $"{game}{cEditorSuffix}", .. scope .());
		let playerDir = PathJoin(generated, scope $"{game}{cPlayerSuffix}", .. scope .());
		if ((WriteWorkspace(projectDir, game, packages) case .Err)
			|| (WriteIfChanged(PathJoin(workspace, cConfigFile, .. scope .()), ConfigText(sdk, .. scope .())) case .Err)
			|| (WriteIgnore(workspace) case .Err)
			|| (WriteIfChanged(PathJoin(editorDir, "BeefProj.toml", .. scope .()), editor) case .Err)
			|| (WriteIfChanged(PathJoin(editorDir, "src/Program.bf", .. scope .()), ProgramText(game, true, .. scope .())) case .Err)
			|| (WriteIfChanged(PathJoin(playerDir, "BeefProj.toml", .. scope .()), player) case .Err)
			|| (WriteIfChanged(PathJoin(playerDir, "src/Program.bf", .. scope .()), ProgramText(game, false, .. scope .())) case .Err))
		{
			outError.Set(scope $"could not write the project's workspace in '{workspace}'");
			return .Err(.Internal);
		}
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
	/// of every package, then the two entries.
	public static void WorkspaceProjects(StringView game, List<ProjectPackage> packages, List<String> outNames, List<String> outPaths)
	{
		for (let package in packages)
		{
			for (let kind in package.Parts)
			{
				let part = package.PartName(kind, .. new .());
				outNames.Add(part);
				let path = new String();
				if (package.IsGame)
					path.Set(part);
				else if (PathIsAbsolute(package.Path))
					PathJoin(package.Directory, part, path);
				else
				{
					path.AppendF("../{}/{}", TrimSlashes(package.Path), part);
				}
				path.Replace('\\', '/');
				outPaths.Add(path);
			}
		}
		for (let suffix in StringView[2](cEditorSuffix, cPlayerSuffix))
		{
			outNames.Add(new $"{game}{suffix}");
			outPaths.Add(new $"{cGeneratedDir}/{game}{suffix}");
		}
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

	/// An executable's project: the stock startup and every part its role loads.
	public static void ExecutableProject(StringView game, bool editor, List<ProjectPackage> packages, StringView configs, String outText)
	{
		let name = scope $"{game}{editor ? cEditorSuffix : cPlayerSuffix}";
		outText.AppendF("FileVersion = 1\n\n[Project]\nName = \"{}\"\nTargetType = \"BeefGUIApplication\"\n", name);
		outText.AppendF("StartupObject = \"{}.Program\"\n\n[Dependencies]\ncorlib = \"*\"\n", name);
		outText.AppendF("\"{}\" = \"*\"\n", editor ? cEditorStartup : cPlayerStartup);
		let role = editor ? HostRole.Editor : HostRole.Player;
		for (let package in packages)
		{
			for (let kind in package.Parts)
			{
				if (role.Loads(kind))
					outText.AppendF("\"{}\" = \"*\"\n", package.PartName(kind, .. scope .()));
			}
		}
		if (!configs.IsEmpty)
			outText.AppendF("\n{}", configs);
	}

	/// The stock editor's [Configs.*] sections, its post-build steps among them, with the
	/// workspace-relative paths into the engine made the SDK's absolute path (the entry is
	/// generated per machine).
	public static void StockEditorConfigs(StringView stockEditor, StringView sdk, String outText)
	{
		let index = stockEditor.IndexOf("\n[Configs.");
		if (index < 0)
			return;
		outText.Append(stockEditor.Substring(index + 1));
		outText.Replace("$(WorkspaceDir)/..", Slashed(sdk, .. scope .()));
	}

	/// The executable's Main: one call into the stock startup.
	public static void ProgramText(StringView game, bool editor, String outText)
	{
		let call = editor ? "Sedulous.Editor.Main.EditorMain.Run" : "Sedulous.Engine.Player.DesktopMain.DesktopPlayerMain.Run";
		outText.AppendF("namespace {}{};\n\nclass Program\n{{\n\tpublic static int Main(System.String[] args) => {}(args);\n}}\n",
			game, editor ? cEditorSuffix : cPlayerSuffix, call);
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
			{
				outPath.Set(candidate);
				return true;
			}
		}
		return false;
	}

	/// BeefBuild, found on PATH only.
	public static bool FindBeefBuild(String outPath)
	{
		let searchPath = scope String();
		if (Environment.GetEnvironmentVariable("PATH", searchPath) case .Err)
			return false;
		return FindOnPath(searchPath, "BeefBuild", outPath);
	}

	/// The project's player for `config`, when it is built and newer than every file of the
	/// project's packages: what an export of a project with packages ships. In the game's package
	/// (Code/) what builds write is not counted, or the player would never be fresh. NotFound for
	/// a player never built, InvalidArgument for one older than a file of a package.
	public static Result<void, ErrorCode> FreshPlayer(StringView projectDir, ProjectSettings settings, StringView config, String outPath)
	{
		let game = GameName(settings.Name, .. scope .());
		ExecutablePath(projectDir, game, false, config, outPath);
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

	/// Build Project: generates the workspace, then runs BeefBuild over Code/ once per executable
	/// and config (the editor in Debug, the player in PlayerConfigs), one at a time, each run's
	/// output to the log. Refused, with why in `outError`, without an engine SDK (FindSdk), for a
	/// project with no package of its own, without BeefBuild on PATH, at the first run that fails,
	/// or when a run said it built and an executable is not there. Blocking: run it on the build
	/// lane.
	///
	/// Each step is logged, and the end is the line "Build Project: built": it runs for minutes
	/// (the first one compiles the engine beside the packages), and someone reading the log, or
	/// a caller driving the editor over MCP, has nothing else to tell a running build from a
	/// finished one.
	public static Result<void, ErrorCode> Build(StringView projectDir, ProjectSettings settings, ExportPresetSet presets, StringView dataRoot, String outError)
	{
		let sdk = scope String();
		if (!FindSdk(dataRoot, sdk))
		{
			outError.Set(scope $"a project's build needs the engine SDK: set {cSdkVariable}, or run from an engine checkout");
			return .Err(.NotSupported);
		}
		if (!HasPackages(settings))
		{
			outError.Set("the project has no package of its own (Add Native Code makes one)");
			return .Err(.NotFound);
		}
		let beefBuild = scope String();
		if (!FindBeefBuild(beefBuild))
		{
			outError.Set("BeefBuild is not on PATH");
			return .Err(.NotFound);
		}
		if (Generate(projectDir, settings, sdk, outError) case .Err(let err))
			return .Err(err);

		let game = GameName(settings.Name, .. scope .());
		let configs = scope List<String>();
		defer { ClearAndDeleteItems!(configs); }
		PlayerConfigs(presets, configs);
		let workspace = Directory(projectDir, .. scope .());
		GlobalLog(.Information, "Build Project: generated the workspace in '{}' over the SDK at '{}' (the first build compiles the engine too)", workspace, sdk);
		if (RunBeefBuild(beefBuild, workspace, scope $"{game}{cEditorSuffix}", "Debug", outError) case .Err(let editorErr))
			return .Err(editorErr);
		for (let config in configs)
		{
			if (RunBeefBuild(beefBuild, workspace, scope $"{game}{cPlayerSuffix}", config, outError) case .Err(let playerErr))
				return .Err(playerErr);
		}
		// BeefBuild's exit alone is not the word on it: a run can end well with nothing built
		// (a project it did not find), so the executables themselves are checked.
		let unbuilt = scope String();
		if (FindUnbuilt(projectDir, game, configs, unbuilt))
		{
			outError.Set(scope $"BeefBuild ended without building '{unbuilt}'");
			return .Err(.NotFound);
		}
		GlobalLog(.Information, "Build Project: built - Project > Open With This Build runs it");
		return .Ok;
	}

	/// One BeefBuild run over the workspace, its output to the log line by line.
	private static Result<void, ErrorCode> RunBeefBuild(StringView beefBuild, StringView workspace, StringView project, StringView config, String outError)
	{
		GlobalLog(.Information, "Build Project: {} ({})", project, config);
		let workspaceArg = scope $"-workspace={workspace}";
		let configArg = scope $"-config={config}";
		let platformArg = scope $"-platform={BuildLayout.HostPlatformName}";
		let projectArg = scope $"-project={project}";
		let result = scope ProcessResult();
		Process.Run(beefBuild, scope StringView[](workspaceArg, configArg, platformArg, projectArg), result);
		for (let line in result.Output.Split('\n'))
		{
			if (!line.IsWhiteSpace)
				GlobalLog(.Information, "Build Project: {}", line);
		}
		if (result.ExitCode != 0)
		{
			outError.Set(scope $"BeefBuild failed building {project} ({config}), exit {result.ExitCode}");
			return .Err(.Internal);
		}
		return .Ok;
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
