using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// Builds the project's own player for a preset with BeefBuild, through the project build
/// service: <Game>Player for this host, or <Game>PlayerWeb for wasm32, in the build config the
/// preset's config names, as one Player job. The job is the service's latest while it runs, so a
/// build's status and cancel reach an export's compile as they reach Build Project's. It runs on
/// the caller's thread: the editor's build lane, or inline in a tool with none.
class ProjectPlayerBuilder : IPlayerBuilder
{
	/// How many of a failed build's errors its refusal quotes; the rest stay on the job.
	public const int cRefusalErrors = 3;

	/// BORROWED: the editor's (or the tool's) one service.
	private ProjectBuildService mService;
	private String mDataRoot = new .() ~ delete _;
	/// One reference of ours, or null for nothing to cancel.
	private CancelToken mCancel ~ _?.ReleaseRef();

	/// Over `service` (borrowed), the engine data root `dataRoot` the SDK is found from, and
	/// `cancel` (null: nothing cancels; a reference is taken), which stops BeefBuild when it is.
	public this(ProjectBuildService service, StringView dataRoot, CancelToken cancel = null)
	{
		mService = service;
		mDataRoot.Set(dataRoot);
		mCancel = cancel;
		if (mCancel != null)
			mCancel.AddRef();
	}

	public Result<void, ErrorCode> Build(EditorProject project, ExportPreset preset, PlayerBuild outBuild, ExportProgress onProgress,
		String outRefusal)
	{
		outBuild.Clear();
		let config = scope String();
		BuildEntry entry;
		if (Target(preset, out entry, config, outRefusal) case .Err(let refused))
			return .Err(refused);

		// The job's own copy: the project's settings may change on the main thread meanwhile.
		let settings = new ProjectSettings();
		if (ProjectManifest.Copy(project.Settings, settings) case .Err)
		{
			delete settings;
			outRefusal.Set("the project's settings did not copy");
			return .Err(.Internal);
		}
		let platform = ProjectBuild.EntryPlatform(entry);
		let job = new BuildJob(.Player, project.Directory, mDataRoot, settings, null, config, platform);
		defer job.ReleaseRef();

		let game = ProjectBuild.GameName(project.Name, .. scope .());
		let name = ProjectBuild.EntryName(game, entry, .. scope .());
		if (onProgress != null)
			onProgress(scope $"Building {name} ({config})", PlayerBuild.cProgressStart);
		if (mService.Run(job, mCancel) case .Err(let err))
		{
			if (err == .Cancelled)
			{
				outRefusal.Set("the player's build was cancelled");
				return .Err(.Cancelled);
			}
			Refusal(job, outRefusal);
			return .Err(err);
		}

		let made = ProjectBuild.EntryPath(project.Directory, game, entry, config, .. scope .());
		let directory = PathParent(made, .. scope .());
		let binary = PathFilename(made, .. scope .());
		if (entry == .PlayerWeb)
			CollectWeb(directory, binary, outBuild);
		else
			CollectDesktop(directory, binary, outBuild);
		outBuild.Description.Set(scope $"{name}, {config}, {platform}");
		if (onProgress != null)
			onProgress(scope $"Built {name} ({config})", PlayerBuild.cProgressEnd);
		return .Ok;
	}

	/// The job's error, and the first of its errors (cRefusalErrors) each as
	/// "file:line:column: message", into `outRefusal`.
	private static void Refusal(BuildJob job, String outRefusal)
	{
		outRefusal.Set(job.GetError(.. scope .()));
		let diagnostics = scope List<BuildDiagnostic>();
		defer { ClearAndDeleteItems!(diagnostics); }
		job.GetDiagnostics(diagnostics);
		int quoted = 0;
		for (let diagnostic in diagnostics)
		{
			if (diagnostic.Severity != .Error)
				continue;
			if (quoted == cRefusalErrors)
			{
				outRefusal.Append("\n...");
				break;
			}
			outRefusal.Append('\n');
			diagnostic.Describe(outRefusal);
			quoted++;
		}
	}

	/// What a player for `preset` is built as: the entry (<Game>PlayerWeb for the web,
	/// <Game>Player for this host) and the build config its config names
	/// (ProjectBuild.BuildConfigFor: Release ships ShippingRelease, Profile is Release, Debug is
	/// Debug). Refused, with why in `outRefusal`, for another host's platform (BeefBuild builds
	/// for its own host alone; the web builds on any) and for any other config: Test links the
	/// test runner, and is no player.
	public static Result<void, ErrorCode> Target(ExportPreset preset, out BuildEntry outEntry, String outConfig, String outRefusal)
	{
		outEntry = .Player;
		let presetConfig = preset.EffectiveConfig;
		if ((presetConfig != "Release") && (presetConfig != "Profile") && (presetConfig != "Debug"))
		{
			if (presetConfig == "Test")
				outRefusal.Set("a Test build links the test runner and is no player: a preset exports Release, Profile or Debug");
			else
				outRefusal.Set(scope $"'{presetConfig}' is no preset config: a preset exports Release, Profile or Debug");
			return .Err(.InvalidArgument);
		}
		if (ExportStaging.IsWebPlatform(preset.Platform))
			outEntry = .PlayerWeb;
		else if (preset.Platform.IsEmpty)
		{
			outRefusal.Set("the preset names no platform");
			return .Err(.InvalidArgument);
		}
		else if (preset.Platform != BuildLayout.HostPlatformName)
		{
			outRefusal.Set(scope $"a {preset.Platform} player builds on {HostName(preset.Platform)}: export this preset there");
			return .Err(.NotSupported);
		}
		ProjectBuild.BuildConfigFor(presetConfig, outConfig);
		return .Ok;
	}

	/// The system a desktop platform's player builds on, by its name for people.
	private static StringView HostName(StringView platform)
	{
		if (platform.StartsWith("Win"))
			return "Windows";
		if (platform.StartsWith("Linux"))
			return "Linux";
		return platform;
	}

	/// A desktop player built as `binary` in `directory` into `outBuild`: the shared libraries
	/// beside it less the shader compiler's (the player renders from the cooked shader pack, and
	/// the compiler's glibc floor would keep a dist off an older system), the third-party notices
	/// every build carries, and on Windows its .pdb as a symbol.
	public static void CollectDesktop(StringView directory, StringView binary, PlayerBuild outBuild)
	{
		outBuild.Directory.Set(directory);
		outBuild.Binary.Set(binary);
		let libraries = scope List<String>();
		defer { ClearAndDeleteItems!(libraries); }
		BuildLayout.CollectSharedLibraries(directory, libraries);
		for (let library in libraries)
		{
			if (!ExportStaging.IsDxcRuntimeLib(library))
				outBuild.Files.Add(new .(library));
		}
		if (FileExists(PathJoin(directory, BuildLayout.cThirdPartyNotices, .. scope .())))
			outBuild.Files.Add(new .(BuildLayout.cThirdPartyNotices));
#if BF_PLATFORM_WINDOWS
		let symbols = scope String(binary);
		if (symbols.EndsWith(".exe"))
			symbols.RemoveFromEnd(4);
		symbols.Append(".pdb");
		if (FileExists(PathJoin(directory, symbols, .. scope .())))
			outBuild.Symbols.Add(new .(symbols));
#endif
	}

	/// A web player built as its page `page` in `directory` into `outBuild`: the page's parts
	/// beside it (BuildLayout.CollectWebParts: its .js and .wasm, serve.py, the logo, the notices).
	public static void CollectWeb(StringView directory, StringView page, PlayerBuild outBuild)
	{
		outBuild.Directory.Set(directory);
		outBuild.Binary.Set(page);
		BuildLayout.CollectWebParts(directory, page, outBuild.Files);
	}
}
