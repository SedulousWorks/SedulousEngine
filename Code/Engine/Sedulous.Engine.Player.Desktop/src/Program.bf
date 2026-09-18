using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Engine.Player;
using Sedulous.Engine.Project;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.Runtime.SDL3;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;

namespace Sedulous.Engine.Player.Desktop;

/// The DESKTOP entry for the player.
///
/// A SEPARATE PROJECT from the browser entry rather than one project with a platform switch,
/// because what differs is not code. The dependencies differ (Shell.SDL3 and Runtime.SDL3
/// against Shell.Web and Runtime.Web) and a compile time branch cannot drop a dependency, so
/// one project would link SDL3 into the wasm build. The link flags and the target name differ
/// too, and both live in BeefProj.toml where no #if reaches. Raptor splits it the same way:
/// PlayerMain.cpp imports shell.desktop outright, and WebMain.cpp is its own boot beside it.
///
/// The APPLICATION is Sedulous.Engine.Player and is shared. This file is only the boot: read
/// the command line, find the project, bring up a shell and a device, and run.
class Program
{
	private const String cDevProjectFallback = "EditorProject";

	public static int Main(String[] args)
	{
		// Before ANY startup work, so --version answers on a machine that cannot bring up a
		// window at all.
		for (let arg in args)
		{
			if (arg == "--version")
			{
				Console.WriteLine(scope $"Player {EngineVersion.String}");
				return 0;
			}
		}

		InitGlobalLogger(new ConsoleLogger(.Information, "Player"), true);
		defer ShutdownGlobalLogger();
		GlobalLog(.Information, "Player {}", EngineVersion.String);

		let options = scope PlayerOptions();
		ReadCommandLine(args, options);

		WindowSettings windowSettings = .();
		windowSettings.Title = "Player";
		windowSettings.Width = 1280;
		windowSettings.Height = 720;

		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("Player: failed to create the OS shell window");
			return 1;
		}

		GraphicsDeviceDesc deviceDesc = .();
		// From the command line, so ONE binary runs against whichever backend a machine has.
		// --webgpu is what lets the desktop player drive the same backend the browser does,
		// with the runtime shader compiler and hot reload the web build lacks: a web render
		// bug becomes reproducible without the wasm export loop.
		deviceDesc.Backend = BackendSelection.FromArguments(args);

		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("Player: the graphics device could not be created");
			return 1;
		}
		defer delete graphics;

		let app = scope PlayerApplication(options);
		return DesktopRunner.RunApplication(app, shell, graphics);
	}

	/// The positional project directory, then the flags.
	private static void ReadCommandLine(String[] args, PlayerOptions options)
	{
		if ((args.Count > 0) && !args[0].StartsWith("-"))
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
