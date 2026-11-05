using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// A package of the project's (an entry with a path: its game code, a project-local plugin) and
/// the parts its manifest lists, as the project's build links them.
class ProjectPackage
{
	public String Id = new .() ~ delete _;
	/// The package's folder, absolute: Plugins/<Name> under the project.
	public String Directory = new .() ~ delete _;
	/// The folder's name, the prefix of each part's project ("NativeSample.Engine").
	public String Name = new .() ~ delete _;
	public List<PluginPartKind> Parts = new .() ~ delete _;
}

/// A project's own build: the editor and the player linked with the project's packages.
///
/// A Beef library cannot be loaded beside the engine (each carries a runtime of its own), so a
/// package's parts are compiled in. The stock editor and player link the engine's plugins; a
/// project with packages of its own builds <Game>Editor and <Game>Player, each a one-line Main
/// over the stock startup (EditorMain, DesktopPlayerMain) with the parts its role loads as
/// dependencies (named without a dot, so no part's project, always <Package>.<Kind>, can take
/// the name, a package named for the game included), in a workspace generated under <project>/.cache/build that names the engine's
/// projects by absolute path into the checkout. So it needs an engine checkout: an editor run
/// from a distribution has no sources to build against, and the build is refused there.
static class ProjectBuild
{
	/// The generated workspace, under the project.
	public const String cBuildDir = ".cache/build";
	public const String cEditorSuffix = "Editor";
	public const String cPlayerSuffix = "Player";
	/// The library each executable's Main calls, and its call.
	public const String cEditorStartup = "Sedulous.Editor.Main";
	public const String cPlayerStartup = "Sedulous.Engine.Player.DesktopMain";
	/// The stock editor's project, whose post-build steps (naga and tint beside the executable)
	/// the project's editor takes over.
	public const String cStockEditorProject = "Tools/Sedulous.Tools.Editor/BeefProj.toml";

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

	/// The engine checkout an editor's data root is in (<checkout>/Data, beside <checkout>/Code
	/// with the startup libraries in it). False for a data root that is in no checkout.
	public static bool FindCheckout(StringView dataRoot, String outCheckout)
	{
		outCheckout.Clear();
		let trimmed = scope String(dataRoot);
		while (trimmed.EndsWith("/") || trimmed.EndsWith("\\"))
			trimmed.RemoveFromEnd(1);
		if (trimmed.IsEmpty)
			return false;
		let checkout = PathParent(trimmed, .. scope .());
		let code = PathJoin(checkout, "Code", .. scope .());
		if (!FileExists(PathJoin(code, "BeefSpace.toml", .. scope .()))
			|| !FileExists(PathJoin(code, "Editor/Sedulous.Editor.Main/BeefProj.toml", .. scope .()))
			|| !FileExists(PathJoin(code, "Engine/Sedulous.Engine.Player.DesktopMain/BeefProj.toml", .. scope .())))
			return false;
		outCheckout.Set(checkout);
		return true;
	}

	/// The generated workspace's directory.
	public static void Directory(StringView projectDir, String outDir) => PathJoin(projectDir, cBuildDir, outDir);

	/// Where BeefBuild puts the project's editor (or its player) for `config` on this host:
	/// <workspace>/build/<Config>_<Platform>/<Game>Editor/<Game>Editor.
	public static void ExecutablePath(StringView projectDir, StringView gameName, bool editor, StringView config, String outPath)
	{
		let project = scope $"{gameName}{editor ? cEditorSuffix : cPlayerSuffix}";
		let workspace = Directory(projectDir, .. scope .());
		let build = scope $"build/{config}_{BuildLayout.HostPlatformName}/{project}";
		let file = BuildLayout.ExecutableName(project, .. scope .());
		PathJoin(PathJoin(workspace, build, .. scope .()), file, outPath);
	}

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
				let partProject = PathJoin(dir, scope $"{package.Name}.{part.Kind}/BeefProj.toml", .. scope .());
				if (!FileExists(partProject))
				{
					outProblems.Add(new $"plugin '{entry.Id}': its {part.Kind} part has no project ({package.Name}.{part.Kind}/BeefProj.toml)");
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

	/// Writes the project's build workspace under `projectDir`: its BeefSpace.toml (the engine's
	/// projects by absolute path into `checkout`, the packages' parts, the two executables, the
	/// engine's configs) and <Game>Editor and <Game>Player. A file whose content is unchanged is
	/// left alone, so a build after a generate that changed nothing rebuilds nothing. Refused,
	/// with why in `outError`, for a problem with a package or a checkout it cannot read.
	public static Result<void, ErrorCode> Generate(StringView projectDir, ProjectSettings settings, StringView checkout, String outError)
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

		let engineSpace = scope String();
		if (ReadText(PathJoin(checkout, "Code/BeefSpace.toml", .. scope .()), engineSpace) case .Err)
		{
			outError.Set(scope $"no engine workspace in '{checkout}/Code'");
			return .Err(.NotFound);
		}
		let stockEditor = scope String();
		if (ReadText(PathJoin(PathJoin(checkout, "Code", .. scope .()), cStockEditorProject, .. scope .()), stockEditor) case .Err)
		{
			outError.Set(scope $"no stock editor project in '{checkout}/Code'");
			return .Err(.NotFound);
		}

		let game = GameName(settings.Name, .. scope .());
		let workspace = Directory(projectDir, .. scope .());
		let space = scope String();
		if (WorkspaceText(engineSpace, checkout, game, packages, space) case .Err)
		{
			outError.Set("the engine workspace's [Projects] is not one `Name = {Path = \"...\"}` a line");
			return .Err(.InvalidArgument);
		}
		let editor = scope String();
		ExecutableProject(game, true, packages, StockEditorConfigs(stockEditor, checkout, .. scope .()), editor);
		let player = scope String();
		ExecutableProject(game, false, packages, "", player);

		let editorDir = PathJoin(workspace, scope $"{game}{cEditorSuffix}", .. scope .());
		let playerDir = PathJoin(workspace, scope $"{game}{cPlayerSuffix}", .. scope .());
		if ((WriteIfChanged(PathJoin(workspace, "BeefSpace.toml", .. scope .()), space) case .Err)
			|| (WriteIfChanged(PathJoin(editorDir, "BeefProj.toml", .. scope .()), editor) case .Err)
			|| (WriteIfChanged(PathJoin(editorDir, "src/Program.bf", .. scope .()), ProgramText(game, true, .. scope .())) case .Err)
			|| (WriteIfChanged(PathJoin(playerDir, "BeefProj.toml", .. scope .()), player) case .Err)
			|| (WriteIfChanged(PathJoin(playerDir, "src/Program.bf", .. scope .()), ProgramText(game, false, .. scope .())) case .Err))
		{
			outError.Set(scope $"could not write the build workspace in '{workspace}'");
			return .Err(.Internal);
		}
		return .Ok;
	}

	/// The workspace: the engine's [Projects], each path made absolute (less any that is one of the
	/// packages' parts), then the packages' parts and the two executables, then every [Configs.*]
	/// section of the engine's (its macros, SHIPPING among them, and its project selections, less
	/// any leaving a package's part out). The engine's [Workspace] and [WorkspaceFolders] are its
	/// IDE's and stay out.
	public static Result<void> WorkspaceText(StringView engineSpace, StringView checkout, StringView game, List<ProjectPackage> packages, String outText)
	{
		let code = Slashed(PathJoin(checkout, "Code", .. scope .()), .. scope .());
		outText.Append("FileVersion = 1\n\n[Workspace]\n");
		outText.AppendF("StartupProject = \"{}{}\"\n\n[Projects]\n", game, cEditorSuffix);
		let configs = scope String();
		let section = scope String();
		for (let rawLine in engineSpace.Split('\n'))
		{
			var line = rawLine;
			line.TrimEnd('\r');
			if (line.StartsWith("["))
			{
				section.Set(line);
				if (section.StartsWith("[Configs."))
					configs.AppendF("\n{}\n", line);
				continue;
			}
			if (section == "[Projects]")
			{
				if (line.IsWhiteSpace)
					continue;
				let marker = line.IndexOf("{Path = \"");
				if ((marker < 0) || !line.EndsWith("\"}"))
					return .Err;
				// A sample's package can be in the engine's workspace too (NativeSample's parts are):
				// the project's own copy of it wins.
				var name = line.Substring(0, marker);
				name.Trim();
				name.TrimEnd('=');
				name.Trim();
				name.Trim('"');
				if (IsPart(packages, name))
					continue;
				let start = marker + 9;
				let path = line.Substring(start, line.Length - 2 - start);
				outText.AppendF("{}{{Path = \"{}/{}\"}}\n", line.Substring(0, marker), code, path);
			}
			else if (section.StartsWith("[Configs.") && !line.IsWhiteSpace)
			{
				// A config leaving a sample's package out of the engine's builds (NativeSample's
				// parts are out of every ShippingRelease) must not leave the project's own out.
				let kept = scope String(line);
				for (let package in packages)
				{
					for (let kind in package.Parts)
					{
						kept.Replace(scope $"\"{package.Name}.{kind}\" = {{Enabled = false}}, ", "");
						kept.Replace(scope $", \"{package.Name}.{kind}\" = {{Enabled = false}}", "");
						kept.Replace(scope $"\"{package.Name}.{kind}\" = {{Enabled = false}}", "");
					}
				}
				configs.AppendF("{}\n", kept);
			}
		}
		for (let package in packages)
		{
			for (let kind in package.Parts)
			{
				let partDir = Slashed(PathJoin(package.Directory, scope $"{package.Name}.{kind}", .. scope .()), .. scope .());
				outText.AppendF("\"{}.{}\" = {{Path = \"{}\"}}\n", package.Name, kind, partDir);
			}
		}
		outText.AppendF("\"{0}{1}\" = {{Path = \"{0}{1}\"}}\n", game, cEditorSuffix);
		outText.AppendF("\"{0}{1}\" = {{Path = \"{0}{1}\"}}\n", game, cPlayerSuffix);
		outText.Append(configs);
		return .Ok;
	}

	/// Whether `name` is the project of one of the packages' parts.
	private static bool IsPart(List<ProjectPackage> packages, StringView name)
	{
		for (let package in packages)
		{
			for (let kind in package.Parts)
			{
				if (name == scope $"{package.Name}.{kind}")
					return true;
			}
		}
		return false;
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
					outText.AppendF("\"{}.{}\" = \"*\"\n", package.Name, kind);
			}
		}
		if (!configs.IsEmpty)
			outText.AppendF("\n{}", configs);
	}

	/// The stock editor's [Configs.*] sections, its post-build steps among them, with the
	/// workspace-relative paths into the checkout made absolute.
	public static void StockEditorConfigs(StringView stockEditor, StringView checkout, String outText)
	{
		let index = stockEditor.IndexOf("\n[Configs.");
		if (index < 0)
			return;
		outText.Append(stockEditor.Substring(index + 1));
		outText.Replace("$(WorkspaceDir)/..", Slashed(checkout, .. scope .()));
	}

	/// The executable's Main: one call into the stock startup.
	public static void ProgramText(StringView game, bool editor, String outText)
	{
		let call = editor ? "Sedulous.Editor.Main.EditorMain.Run" : "Sedulous.Engine.Player.DesktopMain.DesktopPlayerMain.Run";
		outText.AppendF("namespace {}{};\n\nclass Program\n{{\n\tpublic static int Main(System.String[] args) => {}(args);\n}}\n",
			game, editor ? cEditorSuffix : cPlayerSuffix, call);
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
