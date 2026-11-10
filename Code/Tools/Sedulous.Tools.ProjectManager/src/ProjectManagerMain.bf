using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.VFS;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.Runtime.SDL3;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;
using Sedulous.Engine.Project;
using Sedulous.Editor.ProjectManager;

namespace Sedulous.Tools.ProjectManager;

/// The project manager's whole startup: the OS shell, the graphics device and the manager's
/// program (ProjectManagerProgram) run over them. Beside Main rather than in the manager's
/// library, which the editor links: the platform's shell and device stay out of the editor's
/// libraries and their tests.
///
/// Usage: <manager> [--data-root <dir>] [--release-files <url or folder>] (where the Samples tab
///   reads this version's release files instead of GitHub: a base URL, or a folder
///   Code/Tools/pack-samples.py wrote) [--screenshot <png> [--screenshot-exit]] (the window as a
///   PNG once it has drawn; --screenshot-exit quits once it is written) [--exit-after <s>]
///   [--open <project folder>] (opened as though picked, once the window is up) [--version]
///   GPU: [--vulkan|--dx12|--webgpu|--null-gpu] [--gpu-validation|--no-gpu-validation].
///   The data root is found beside the executable or above it (an SDK's Data, the manager sitting
///   in its ProjectManager/), unless given.
static class ProjectManagerMain
{
	public static int Run(String[] args)
	{
		// Before any startup work, so --version answers on a machine with no window.
		for (let arg in args)
		{
			if (arg == "--version")
			{
				Console.WriteLine(scope $"Project Manager {EngineVersion.BuildIdentity(.. scope .())}");
				return 0;
			}
		}

		let logger = new ConsoleLogger(.Information, "Projects");
		InitGlobalLogger(logger, true);
		defer ShutdownGlobalLogger();
		GlobalLog(.Information, "Project Manager {}", EngineVersion.BuildIdentity(.. scope .()));

		let config = new ProjectManagerConfig(); // the program takes it
		ResolveDataRoot(args, config.DataRoot);
		if (config.DataRoot.IsEmpty)
		{
			Console.Error.WriteLine("Project Manager: no data root (put Data/ with its .dataroot marker beside or above the manager, or pass --data-root <dir>)");
			delete config;
			return 1;
		}
		ReadCommandLine(args, config);
		System.Environment.GetExecutableFilePath(config.ExecutablePath);

		WindowSettings windowSettings = .();
		windowSettings.Title = "Sedulous Project Manager";
		windowSettings.Width = 1280;
		windowSettings.Height = 800;
		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("Project Manager: failed to create the OS shell window");
			delete config;
			return 1;
		}
		if (!(GpuGraphics.CreateDevice(GraphicsDeviceDesc.FromArguments(args)) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("Project Manager: the graphics device could not be created");
			delete config;
			return 1;
		}
		defer delete graphics;

		let program = scope ProjectManagerProgram(config);
		return DesktopRunner.RunApplication(program, shell, graphics);
	}

	/// The flags into `config`.
	public static void ReadCommandLine(Span<String> args, ProjectManagerConfig config)
	{
		for (int i = 0; i < args.Length - 1; i++)
		{
			if (args[i] == "--release-files")
				config.ReleaseFiles.Set(args[i + 1]);
			else if (args[i] == "--screenshot")
				config.ScreenshotPath.Set(args[i + 1]);
			else if (args[i] == "--open")
				config.OpenPath.Set(args[i + 1]);
			else if (args[i] == "--exit-after")
				config.ExitAfterSeconds = float.Parse(args[i + 1]).GetValueOrDefault();
		}
		for (let arg in args)
		{
			if (arg == "--screenshot-exit")
				config.ScreenshotExit = true;
		}
	}
}
