using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Player;
using Sedulous.Engine.Project;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.Profiler.Capture;
using Sedulous.Runtime.SDL3;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;
using Sedulous.VFS;
using Sedulous.RHI.Capture;

namespace Sedulous.Engine.Player.DesktopMain;

/// The DESKTOP entry for the player.
///
/// A SEPARATE PROJECT from the browser entry rather than one project with a platform switch,
/// because what differs is not code. The dependencies differ (Shell.SDL3 and Runtime.SDL3
/// against Shell.Web and Runtime.Web) and a compile time branch cannot drop a dependency, so
/// one project would link SDL3 into the wasm build. The link flags and the target name differ
/// too, and both live in BeefProj.toml where no #if reaches.
///
/// The APPLICATION is Sedulous.Engine.Player and is shared. This is only the boot: read the
/// command line, find the project, bring up a shell and a device, and run. A library rather than
/// the executable's own, so the stock player (Sedulous.Engine.Player.Desktop) and a project's own
/// build (<Game>Player, which links the project's packages) boot the same way: each
/// executable's Main is one call to Run.
static class DesktopPlayerMain
{
	private const String cDevProjectFallback = "EditorProject";

	public static int Run(String[] args) => Run(args, scope PlayerMounts());

	/// Runs the player over the mounts the host made (BORROWED: the run takes the ones it uses,
	/// and leaves the rest to the caller). Each one given replaces finding it by path.
	public static int Run(String[] args, PlayerMounts mounts)
	{
		// Before ANY startup work, so --version answers on a machine that cannot bring up a
		// window at all.
		for (let arg in args)
		{
			if (arg == "--version")
			{
				Console.WriteLine(scope $"Player {EngineVersion.BuildIdentity(.. scope .())}");
				return 0;
			}
			// The plugins this player links, one `id|version` line each: what an export template
			// made from it records it carries.
			if (arg == "--plugins")
			{
				Console.Write(Sedulous.Runtime.PluginRegistry.Linked(.. scope .()));
				return 0;
			}
		}

		InitGlobalLogger(new ConsoleLogger(.Information, "Player"), true);
		defer ShutdownGlobalLogger();
		GlobalLog(.Information, "Player {}", EngineVersion.BuildIdentity(.. scope .()));

		let options = scope PlayerOptions();
		ReadCommandLine(args, mounts.Game != null, options);

		// The window the game asked for, read before the window exists: the dist's player.xml,
		// or a dev tree's Project.xml. Neither, and the defaults stand.
		let manifest = scope ProjectSettings();
		{
			let projectRoot = scope NativeFileSystem(options.ProjectDir);
			IFileSystem root = projectRoot;
			if (mounts.Game != null)
				root = mounts.Game;
			if ((ProjectManifest.Load(root, manifest, ProjectLayout.DistManifestFile) case .Err)
				&& (ProjectManifest.Load(root, manifest, ProjectLayout.ManifestFile) case .Err))
				GlobalLog(.Warning, "Player: no manifest in '{}', the default window", options.ProjectDir);
		}
		// The application takes the game's mounts from the options at startup.
		options.GameRoot = mounts.Game;
		mounts.Game = null;
		options.ContentPak = mounts.Content;
		mounts.Content = null;
		WindowSettings windowSettings = .();
		windowSettings.Title = manifest.Name.IsEmpty ? "Player" : StringView(manifest.Name);
		windowSettings.Width = Math.Max(manifest.WindowWidth, 1);
		windowSettings.Height = Math.Max(manifest.WindowHeight, 1);
		windowSettings.Resizable = manifest.WindowResizable;
		switch (manifest.WindowMode)
		{
		case .Windowed: windowSettings.Fullscreen = .None;
		case .Fullscreen: windowSettings.Fullscreen = .Exclusive;
		case .Borderless: windowSettings.Fullscreen = .Desktop;
		}

		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("Player: failed to create the OS shell window");
			return 1;
		}

		// From the command line, so ONE binary runs against whichever backend a machine has, and
		// --no-gpu-validation measures a debug player as the editor's flag measures the editor.
		// --webgpu is what lets the desktop player drive the same backend the browser does,
		// with the runtime shader compiler and hot reload the web build lacks: a web render
		// bug becomes reproducible without the wasm export loop.
		let deviceDesc = GraphicsDeviceDesc.FromArguments(args);

		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("Player: the graphics device could not be created");
			return 1;
		}
		defer delete graphics;

		let app = scope PlayerApplication(options);
		// Captures are named after the game.
		CaptureRecorder.Process.SetApplication(manifest.Name.IsEmpty ? "Player" : StringView(manifest.Name));
		// --profile-capture <seconds>: a capture from the start, to <user-data>/profiles.
		app.SetProfileCaptureSeconds(ProfileCaptureSeconds(args));
		// --profile-overlay: the profiler overlay from the start (F3 toggles it either way).
		app.SetProfilerOverlayAtStart(HasFlag(args, "--profile-overlay"));
		// --screenshot <png> [--screenshot-frame N | --screenshot-after S] [--screenshot-count N]
		// [--screenshot-exit]: a capture with no hand on F11, which is how a run proves what it
		// drew; with a count, that many consecutive frames as <png stem>-<i>.png.
		app.SetScreenshotOptions(ScreenshotOptions.FromArguments(args));
		// The engine data: the host's mount when it gave one, else --data-root when given, else
		// the discovery walk.
		if (mounts.Data != null)
		{
			app.SetDataFileSystem(mounts.Data);
			mounts.Data = null;
		}
		else
		{
			app.SetDataRoot(DataRootFromArguments(args, .. scope .()));
		}
		return DesktopRunner.RunApplication(app, shell, graphics);
	}

	private static bool HasFlag(String[] args, StringView flag)
	{
		for (let arg in args)
		{
			if (arg == flag)
				return true;
		}
		return false;
	}

	/// --profile-capture's seconds, nought without it.
	private static double ProfileCaptureSeconds(String[] args)
	{
		for (int i = 0; i < args.Count - 1; i++)
		{
			if (args[i] == "--profile-capture")
				return double.Parse(args[i + 1]).GetValueOrDefault();
		}
		return 0.0;
	}

	/// The positional project directory, then the flags. With a game mount from the host there
	/// is no directory to find, and the one named is for the log alone.
	private static void ReadCommandLine(String[] args, bool hostGame, PlayerOptions options)
	{
		if (hostGame)
			options.ProjectDir.Set("(the host's mount)");
		else if ((args.Count > 0) && !args[0].StartsWith("-"))
			options.ProjectDir.Set(args[0]);
		else
			ResolveProjectDir(options.ProjectDir);

		for (int i = 0; i < args.Count - 1; i++)
		{
			if (args[i] == "--scene")
				options.SceneOverride.Set(args[i + 1]);
			else if (args[i] == "--exit-after")
				options.ExitAfterSeconds = float.Parse(args[i + 1]).GetValueOrDefault();
		}
	}

	/// Where the game is when nobody said.
	///
	/// A DISTRIBUTED binary is sitting in its own game's directory, so the working directory
	/// comes first and the executable's own directory second, which is what makes a double
	/// click or a run from anywhere behave the same. The dev fallback is last and is the only
	/// baked name here.
	private static void ResolveProjectDir(String outDir)
	{
		let working = scope String();
		GetCurrentDirectory(working);
		if (HasGame(working))
		{
			outDir.Set(working);
			return;
		}

		let exeDir = scope String();
		GetExecutableDirectory(exeDir);
		if (HasGame(exeDir))
		{
			outDir.Set(exeDir);
			return;
		}

		outDir.Set(cDevProjectFallback);
	}

	/// A directory holds a game if it carries either half of one: the cooked pak a shipped
	/// build has, or the manifest a dev tree has.
	private static bool HasGame(StringView dir)
	{
		if (FileExists(PathJoin(dir, ProjectLayout.DistContentPak, .. scope String())))
			return true;
		return FileExists(PathJoin(dir, ProjectLayout.ManifestFile, .. scope String()));
	}
}
