using System;
using System.Collections;
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
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Navigation;

namespace Sedulous.Tools.Editor;

/// The editor executable: creates the OS shell and the graphics device and runs
/// EditorApplication, with every per subsystem editor module assembled through
/// EditorRegistration.
///
/// Usage: Sedulous.Tools.Editor [projectDirectory] [--project <dir>] [--data-root <dir>]
///   [--exit-after <s>] [--rebuild-after <s>] [--screenshot <png> [--screenshot-after <s>]]
///   [--seed] [--seed-primitives] [--version]
///   With a project (positional or --project): opens it directly, scaffolding the manifest
///   and the content tree on first run; the single project lifecycle.
///   With NO project: starts on the built in PROJECT MANAGER (recent projects from the per
///   user registry, open, create, remove); File > Close Project returns to it.
class Program
{
	/// The last resort face, baked into the executable, so a relocated editor never comes
	/// up textless.
	private const uint8[?] cEmbeddedFont = Compiler.ReadBinary("../../../Data/Assets/fonts/roboto/Roboto-Regular.ttf");

	public static int Main(String[] args)
	{
		// Before ANY startup work, so --version answers on a machine that cannot bring up a
		// window at all.
		for (let arg in args)
		{
			if (arg == "--version")
			{
				Console.WriteLine(scope $"Editor {EngineVersion.String}");
				return 0;
			}
		}

		// The log capture FIRST, before anything logs, so early startup reaches the Console
		// panel; the console mirror second. Debug, because the panel has a Debug filter.
		let logBuffer = new EditorLogBuffer();
		let logger = new CompositeLogger(.Debug);
		logger.Add(logBuffer, true);
		logger.Add(new ConsoleLogger(.Debug, "Editor"), true);
		InitGlobalLogger(logger, true);
		defer ShutdownGlobalLogger();
		GlobalLog(.Information, "Editor {}", EngineVersion.String);

		let dataRoot = scope String();
		ResolveDataRoot(args, dataRoot);
		if (dataRoot.IsEmpty)
		{
			Console.Error.WriteLine("Sedulous.Tools.Editor: no data root (put Data/ with its .dataroot marker beside the editor, or pass --data-root <dir>)");
			return 1;
		}
		EditorSeed.DataRoot.Set(dataRoot);

		let config = new EditorAppConfig(); // the app takes it
		config.DataRoot.Set(dataRoot);
		ReadCommandLine(args, config);
		config.StartInProjectManager = config.ProjectDirectory.IsEmpty;
		DataPath(dataRoot, "Assets/fonts/roboto/Roboto-Regular.ttf", config.FontPath);
		DataPath(dataRoot, "Assets/fonts/dejavu/DejaVuSansMono.ttf", config.MonoFontPath);
		config.EmbeddedFont = cEmbeddedFont;
		config.LogBuffer = logBuffer;
		config.SeedNewProject = new (ctx, project) => EditorSeed.SeedNewProject(ctx, project);
		config.RegisterEditors = new (app, host, uiHost) => EditorRegistration.RegisterEditors(app, host, uiHost);

		// The domain contributed settings sections exist before the app loads the per user
		// store, which happens before the editor modules register.
		NavigationEditorSerializables.RegisterAll();

		GlobalLog(.Information, "Editor: starting (project: {})", config.ProjectDirectory);

		WindowSettings windowSettings = .();
		windowSettings.Title = "Editor";
		windowSettings.Width = 1600;
		windowSettings.Height = 900;
		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("Sedulous.Tools.Editor: failed to create the OS shell window");
			delete config;
			return 1;
		}

		GraphicsDeviceDesc deviceDesc = .();
		deviceDesc.Backend = BackendSelection.FromArguments(args);
		deviceDesc.EnableValidation = true;
		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("Sedulous.Tools.Editor: the graphics device could not be created");
			delete config;
			return 1;
		}
		defer delete graphics;
		// After the app, whose pages borrow the cooks, and before the device it drew with.
		defer PipelineRegistration.Teardown();

		let app = scope EditorApplication(config);
		return DesktopRunner.RunApplication(app, shell, graphics);
	}

	/// The positional project directory, then the flags.
	private static void ReadCommandLine(String[] args, EditorAppConfig config)
	{
		if ((args.Count > 0) && !args[0].StartsWith("-"))
			config.ProjectDirectory.Set(args[0]);
		for (int i = 0; i < args.Count - 1; i++)
		{
			if (args[i] == "--project")
				config.ProjectDirectory.Set(args[i + 1]);
			else if (args[i] == "--exit-after")
				config.AutoExitSeconds = float.Parse(args[i + 1]).GetValueOrDefault();
			else if (args[i] == "--rebuild-after")
				config.AutoRebuildSeconds = float.Parse(args[i + 1]).GetValueOrDefault();
			else if (args[i] == "--screenshot")
				config.ScreenshotPath.Set(args[i + 1]);
			else if (args[i] == "--screenshot-after")
				config.ScreenshotAfterSeconds = float.Parse(args[i + 1]).GetValueOrDefault();
		}
		for (let arg in args)
		{
			if (arg == "--seed")
				config.SeedOnScaffold = true; // a scaffolded project also gets the starter content
			else if (arg == "--seed-primitives")
			{
				config.SeedOnScaffold = true;
				EditorSeed.SeedAllPrimitives = true; // plus every primitive, not just the three
			}
		}
	}
}
