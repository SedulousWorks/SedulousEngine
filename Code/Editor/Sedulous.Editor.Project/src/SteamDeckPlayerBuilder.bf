using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// Builds a preset's Linux64 player in the Steam Deck container (the SDK's
/// Code/Tools/SteamDeck/build-steamdeck.sh): an Ubuntu 22.04 image whose glibc (2.35) is below
/// SteamOS's, so the player runs there and on older Linux systems, where one built on this
/// machine asks for this machine's glibc. The project's packages are copied under the SDK's
/// build/steamdeck/projects/<Game>, its workspace generated there against the SDK as the
/// container mounts it (cContainerSdk), and the script builds <Game>Player over it and stages
/// the bundle: the player stripped, its shared libraries less the shader compiler's, SDL3 by
/// its soname and the notices, each checked against the Deck's glibc. The bundle folder is the
/// build.
///
/// The script runs through the project build service as one job, its output streamed into it
/// and its cancel honoured as BeefBuild's are, so build_status follows the container's first
/// build of Beef and the native dependencies, which takes long.
class SteamDeckPlayerBuilder : IPlayerBuilder
{
	/// The script that builds in the container, in the SDK.
	public const String cScript = "Code/Tools/SteamDeck/build-steamdeck.sh";
	/// Where the script keeps its state, in the SDK: its Beef clone, its copy of the SDK, the
	/// projects' copies (cProjectsDir) and the bundles (cOutDir).
	public const String cStateDir = "build/steamdeck";
	public const String cProjectsDir = "projects";
	public const String cOutDir = "out";
	/// The SDK's copy as the container mounts it: a project's copy is generated against this
	/// path, and the script mounts the copy itself at the same path it has here.
	public const String cContainerSdk = "/work";
	/// The only platform a Steam Deck player is built for.
	public const String cPlatform = "Linux64";
	/// What the container runs on, either one.
	public const String[2] cRuntimes = .("podman", "docker");

	/// BORROWED: the editor's (or the tool's) one service.
	private ProjectBuildService mService;
	private String mDataRoot = new .() ~ delete _;
	/// One reference of ours, or null for nothing to cancel.
	private CancelToken mCancel ~ _?.ReleaseRef();
	/// Ships the last bundle rather than building.
	private bool mReuseLastBuild;

	/// Over `service` (borrowed), whose runner runs the script, the engine data root `dataRoot`
	/// the SDK is found from, and `cancel` (null: nothing cancels; a reference is taken). With
	/// `reuseLastBuild` it never builds: it ships the bundle the last build left.
	public this(ProjectBuildService service, StringView dataRoot, CancelToken cancel = null, bool reuseLastBuild = false)
	{
		mService = service;
		mDataRoot.Set(dataRoot);
		mCancel = cancel;
		if (mCancel != null)
			mCancel.AddRef();
		mReuseLastBuild = reuseLastBuild;
	}

	public Result<void, ErrorCode> Build(EditorProject project, ExportPreset preset, PlayerBuild outBuild, ExportProgress onProgress,
		String outRefusal)
	{
		outBuild.Clear();
		let config = scope String();
		if (Target(preset, config, outRefusal) case .Err(let refused))
			return .Err(refused);
		let sdk = scope String();
		if (!ProjectBuild.FindSdk(mDataRoot, project.Directory, sdk))
		{
			outRefusal.Set(scope $"a Steam Deck build needs the engine SDK: set {ProjectBuild.cSdkVariable}, or run from an engine checkout");
			return .Err(.NotSupported);
		}
		let game = ProjectBuild.GameName(project.Name, .. scope .());
		let name = ProjectBuild.EntryName(game, .Player, .. scope .());
		let bundle = BundleDirectory(sdk, name, config, .. scope .());
		let made = PathJoin(bundle, name, .. scope .());
		if (mReuseLastBuild)
		{
			if (!FileExists(made))
			{
				outRefusal.Set(scope $"{name} has not been built for the Steam Deck in {config} ('{made}' is not there): export with the build on first");
				return .Err(.NotFound);
			}
			CollectBundle(bundle, name, outBuild);
			outBuild.Description.Set(scope $"{name}, {config}, {cPlatform}, Steam Deck (the last build)");
			if (onProgress != null)
				onProgress(scope $"Reused {name} ({config}, Steam Deck)", PlayerBuild.cProgressEnd);
			return .Ok;
		}
		let script = PathJoin(sdk, cScript, .. scope .());
		if (!FileExists(script))
		{
			outRefusal.Set(scope $"the engine SDK at '{sdk}' has no Steam Deck build ({cScript})");
			return .Err(.NotFound);
		}

		// The job's own copy: the project's settings may change on the main thread meanwhile.
		let settings = new ProjectSettings();
		if (ProjectManifest.Copy(project.Settings, settings) case .Err)
		{
			delete settings;
			outRefusal.Set("the project's settings did not copy");
			return .Err(.Internal);
		}
		let copyDir = ProjectCopyDirectory(sdk, game, .. scope .());
		let job = new BuildJob(.Player, copyDir, mDataRoot, settings, config, cPlatform);
		defer job.ReleaseRef();
		if (onProgress != null)
			onProgress(scope $"Building {name} ({config}) in the Steam Deck container", PlayerBuild.cProgressStart);

		// The project's code where the container reaches it, and its workspace generated for the
		// SDK as the container sees it; what is read of the SDK is read here.
		if (!CopyPackages(project.Directory, settings, copyDir, outRefusal))
			return .Err(.Internal);
		if (ProjectBuild.Generate(copyDir, settings, sdk, outRefusal, cContainerSdk) case .Err(let generateErr))
			return .Err(generateErr);
		let workspace = ProjectBuild.Directory(copyDir, .. scope .());
		let arguments = scope StringView[]("--workspace", workspace, "--project", name, "--config", config, "--out", bundle);
		if (mService.RunExternal(job, script, arguments, name, config, made, mCancel) case .Err(let err))
		{
			if (err == .Cancelled)
			{
				outRefusal.Set("the player's Steam Deck build was cancelled");
				return .Err(.Cancelled);
			}
			ProjectPlayerBuilder.Refusal(job, outRefusal);
			return .Err(err);
		}

		CollectBundle(bundle, name, outBuild);
		outBuild.Description.Set(scope $"{name}, {config}, {cPlatform}, Steam Deck");
		outBuild.SetJob(job);
		if (onProgress != null)
			onProgress(scope $"Built {name} ({config}, Steam Deck)", PlayerBuild.cProgressEnd);
		return .Ok;
	}

	/// The build config a Steam Deck player for `preset` is built in, as for this host
	/// (ProjectPlayerBuilder.Target: Release ships ShippingRelease). Refused, with why in
	/// `outRefusal`, for a platform other than Linux64, and for what Target refuses (a config no
	/// player is built in; on Windows, a Linux64 player, which the script, a bash one, does not
	/// build).
	public static Result<void, ErrorCode> Target(ExportPreset preset, String outConfig, String outRefusal)
	{
		if (preset.Platform != cPlatform)
		{
			outRefusal.Set(scope $"a Steam Deck player is a {cPlatform} one, and the preset's platform is '{preset.Platform}'");
			return .Err(.InvalidArgument);
		}
		BuildEntry entry;
		return ProjectPlayerBuilder.Target(preset, out entry, outConfig, outRefusal);
	}

	/// Whether a Steam Deck player for `preset` can be built here: what Target allows, with podman
	/// or docker on PATH. False, with why in `outWhy`, otherwise.
	public static bool CanBuild(ExportPreset preset, String outWhy)
	{
		if (Target(preset, scope .(), outWhy) case .Err)
			return false;
		let searchPath = scope String();
		if (Environment.GetEnvironmentVariable("PATH", searchPath) case .Err)
			searchPath.Clear();
		for (int i < cRuntimes.Count)
		{
			if (ProjectBuild.FindOnPath(searchPath, cRuntimes[i], scope .()))
				return true;
		}
		outWhy.Set("a Steam Deck build runs in a container: it needs podman or docker");
		return false;
	}

	/// Where the project of the game named `game` is copied for the container: the SDK's
	/// build/steamdeck/projects/<Game>.
	public static void ProjectCopyDirectory(StringView sdk, StringView game, String outDir)
	{
		let state = PathJoin(sdk, cStateDir, .. scope .());
		let projects = PathJoin(state, cProjectsDir, .. scope .());
		PathJoin(projects, game, outDir);
	}

	/// Where the bundle of the player `name` built in `config` lands: the SDK's
	/// build/steamdeck/out/<Config>_Linux64/<Game>Player.
	public static void BundleDirectory(StringView sdk, StringView name, StringView config, String outDir)
	{
		let state = PathJoin(sdk, cStateDir, .. scope .());
		let outRoot = PathJoin(state, cOutDir, .. scope .());
		let configDir = PathJoin(outRoot, scope $"{config}_{cPlatform}", .. scope .());
		PathJoin(configDir, name, outDir);
	}

	/// The bundle the script staged in `bundle` as a build, into `outBuild`: the player `binary`,
	/// and beside it every other file the script put there (the shared libraries, SDL3 by its
	/// soname, the notices), in name order; the shader compiler's, which the script leaves out,
	/// never ship.
	public static void CollectBundle(StringView bundle, StringView binary, PlayerBuild outBuild)
	{
		outBuild.Directory.Set(bundle);
		outBuild.Binary.Set(binary);
		ListDirectory(bundle, scope [&](name, isDirectory) =>
			{
				if (!isDirectory && (name != binary) && !ExportStaging.IsDxcRuntimeLib(name))
					outBuild.Files.Add(new .(name));
			});
		outBuild.Files.Sort(scope (a, b) => a.CompareTo(b));
	}

	/// The project's packages (each enabled plugin with a path: the game's in Code/, any in
	/// Plugins/) copied into `copyDir` at their paths. What builds write at the top of the game's
	/// package is neither copied nor removed, so the copy's own build stays incremental; anything
	/// else the copy had of a package goes first, so a file deleted from the project does not
	/// linger there. False, with why in `outRefusal`, when a package could not be copied.
	public static bool CopyPackages(StringView projectDir, ProjectSettings settings, StringView copyDir, String outRefusal)
	{
		for (let entry in settings.Plugins)
		{
			if (entry.Path.IsEmpty)
				continue;
			let game = ProjectBuild.IsGamePath(entry.Path);
			let source = PathJoin(projectDir, entry.Path, .. scope .());
			let destination = PathJoin(copyDir, entry.Path, .. scope .());
			if (!MakeDirectories(destination) || !Clear(destination, game) || !CopyEntries(source, destination, game))
			{
				outRefusal.Set(scope $"the project's package '{entry.Path}' could not be copied to '{destination}'");
				return false;
			}
		}
		return true;
	}

	/// What `dir` holds removed, less what builds write at its top when `game`.
	private static bool Clear(StringView dir, bool game)
	{
		let names = scope List<(String name, bool isDirectory)>();
		defer { for (let item in names) delete item.name; }
		ListDirectory(dir, scope [&](name, isDirectory) => { names.Add((new String(name), isDirectory)); });
		bool ok = true;
		for (let item in names)
		{
			if (game && IsWritten(item.name, item.isDirectory))
				continue;
			let path = PathJoin(dir, item.name, .. scope .());
			ok = (item.isDirectory ? RemoveDirectoryRecursive(path) : DeleteFile(path)) && ok;
		}
		return ok;
	}

	/// What `source` holds copied into `destination`, less what builds write at its top when
	/// `game`.
	private static bool CopyEntries(StringView source, StringView destination, bool game)
	{
		let names = scope List<(String name, bool isDirectory)>();
		defer { for (let item in names) delete item.name; }
		if (!ListDirectory(source, scope [&](name, isDirectory) => { names.Add((new String(name), isDirectory)); }))
			return false;
		bool ok = true;
		for (let item in names)
		{
			if (game && IsWritten(item.name, item.isDirectory))
				continue;
			if (item.isDirectory)
				ok = FileCopy.CopyTree(PathJoin(source, item.name, .. scope .()), PathJoin(destination, item.name, .. scope .())) && ok;
			else
				ok = FileCopy.CopyFile(source, item.name, destination, item.name) && ok;
		}
		return ok;
	}

	/// Whether `name`, at the top of the game's package, is something builds write
	/// (ProjectBuild.cWrittenDirs, cWrittenFiles).
	private static bool IsWritten(StringView name, bool isDirectory)
	{
		if (isDirectory)
		{
			for (int i < ProjectBuild.cWrittenDirs.Count)
			{
				if (name == ProjectBuild.cWrittenDirs[i])
					return true;
			}
			return false;
		}
		for (int i < ProjectBuild.cWrittenFiles.Count)
		{
			if (name == ProjectBuild.cWrittenFiles[i])
				return true;
		}
		return false;
	}

	/// `dir` and the folders above it made, as needed; false when it is not there after.
	private static bool MakeDirectories(StringView dir)
	{
		if (DirectoryExists(dir))
			return true;
		let parent = PathParent(dir, .. scope .());
		if (!parent.IsEmpty && (parent != dir))
			MakeDirectories(parent);
		CreateDirectory(dir);
		return DirectoryExists(dir);
	}
}
