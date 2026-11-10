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
using Sedulous.Editor.Project;
using Sedulous.Editor.App;
using Sedulous.Editor.Navigation;

namespace Sedulous.Editor.Main;

/// The editor's whole startup: creates the OS shell and the graphics device and runs
/// EditorApplication, with every per subsystem editor module assembled through
/// EditorRegistration. A library rather than the executable's own, so the stock editor
/// (Sedulous.Tools.Editor) and a project's own build (<Game>Editor, which links the project's
/// packages) run the same editor: each executable's Main is one call to Run.
///
/// Usage: see cUsage. With a project (positional or --project) it opens it, scaffolding the
/// manifest and the content tree on first run: an editor has one project, and Close Project hands
/// the user to the project manager. With no project it starts the project manager instead
/// (ManagerLauncher.Find: --manager, the one that ran last, the SDK's own) with its data root and
/// exits 0; with none found it writes the usage and exits 2.
static class EditorMain
{
	/// What the editor takes, written when it is started with no project and no manager is found.
	private const String cUsage = """
		Usage: <editor> [projectDirectory] [--project <dir>] [--data-root <dir>]
		  [--exit-after <s>] [--rebuild-after <s>] [--screenshot <png> [--screenshot-after <s>]
		  [--screenshot-exit]] (the main window as a PNG; --screenshot-exit quits once it is written)
		  [--mcp] [--mcp-port <n>] (the MCP host for this run: agent access to the open project
		  over 127.0.0.1; the persisted preference is in Preferences)
		  [--seed] [--seed-primitives] [--version]
		  [--restamp] (the project's manifest saved once as it opens, stamping it with this engine)
		  [--manager <path>] (the project manager that launched it, which Close Project starts again)
		  GPU: [--vulkan|--dx12|--webgpu|--null-gpu] [--gpu-validation|--no-gpu-validation]
		  (validation defaults on for a dev build, off for an optimized one).
		An editor opens one project. Projects are listed, made and opened by the project manager
		(Sedulous.Tools.ProjectManager, in the engine's ProjectManager folder), which this editor
		starts when it is given no project.
		""";

	/// The splash's last resort face, baked into the executable, so a relocated editor's splash
	/// never comes up textless (the editor's own faces are its sheet's, through its resources).
	private const uint8[?] cEmbeddedFont = Compiler.ReadBinary("../../../Data/Engine/Fonts/roboto/Roboto-Regular.ttf");

	public static int Run(String[] args)
	{
		// Before ANY startup work, so --version answers on a machine that cannot bring up a
		// window at all.
		for (let arg in args)
		{
			if (arg == "--version")
			{
				Console.WriteLine(scope $"Editor {EngineVersion.BuildIdentity(.. scope .())}");
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
		GlobalLog(.Information, "Editor {}", EngineVersion.BuildIdentity(.. scope .()));

		let dataRoot = scope String();
		ResolveDataRoot(args, dataRoot);
		if (dataRoot.IsEmpty)
		{
			Console.Error.WriteLine("Editor: no data root (put Data/ with its .dataroot marker beside the editor, or pass --data-root <dir>)");
			return 1;
		}
		EditorSeed.DataRoot.Set(dataRoot);

		let config = new EditorAppConfig(); // the app takes it
		config.DataRoot.Set(dataRoot);
		config.ReadCommandLine(args);
		if (config.ProjectDirectory.IsEmpty)
		{
			// No project: the project manager lists, makes and opens them.
			defer delete config;
			let manager = scope String();
			if (ManagerLauncher.Find(config.ManagerPath, "", dataRoot, manager))
			{
				if (ManagerLauncher.Start(manager, dataRoot, null))
				{
					GlobalLog(.Information, "Editor: no project given: the project manager {} started", manager);
					return 0;
				}
				Console.Error.WriteLine(scope $"Editor: no project given, and the project manager {manager} did not start");
			}
			else
				Console.Error.WriteLine("Editor: no project given, and no project manager was found to start");
			Console.Error.WriteLine(cUsage);
			return 2;
		}
		EditorSeed.SeedAllPrimitives = config.SeedAllPrimitives;
		// The splash's face, from the data root, with the embedded twin as the last resort.
		let splashFontPath = DataPath(dataRoot, "Engine/Fonts/roboto/Roboto-Regular.ttf", .. scope .());
		config.LogBuffer = logBuffer;
		config.SeedNewProject = new (ctx, project) => EditorSeed.SeedNewProject(ctx, project);
		config.RegisterEditors = new (app, host) => EditorRegistration.RegisterEditors(app, host);

		// The domain contributed settings sections exist before the app loads the per user
		// store, which happens before the editor modules register.
		NavigationEditorSerializables.RegisterAll();

		GlobalLog(.Information, "Editor: starting (project: {})", config.ProjectDirectory);

		WindowSettings windowSettings = .();
		windowSettings.Title = "SedulousEngine";
		windowSettings.Width = 1600;
		windowSettings.Height = 900;
		// Hidden until the editor is ready: the splash shows until then (StartupFinished).
		windowSettings.Hidden = true;
		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("Editor: failed to create the OS shell window");
			delete config;
			return 1;
		}
		let mainWindow = shell.MainWindow;
		EditorSplash.ApplyWindowIcon(mainWindow, dataRoot);

		// The splash, from now until the editor is ready: startup holds the main thread with
		// nothing drawn (the device, the shader compiles, the fonts, the project). Declared
		// before the app, so it outlives the app's calls into it.
		let splash = EditorSplash.Open(shell, dataRoot, splashFontPath, cEmbeddedFont, scope $"Version {EngineVersion.Display}");
		defer delete splash;
		if (splash != null)
			splash.Step("Starting the graphics device", 0.05f);
		else
			mainWindow.Show(); // no splash: show the window now
		config.StartupProgress = new [=splash](status, progress) =>
			{
				if (splash != null)
					splash.Step(status, progress);
			};
		config.StartupFinished = new [=splash, =mainWindow]() =>
			{
				mainWindow.Show();
				if (splash != null)
					splash.Close();
			};

		// Validation follows the build config unless the command line says otherwise: an
		// optimized editor is for measuring, not for carrying the layer's cost.
		let deviceDesc = GraphicsDeviceDesc.FromArguments(args);
		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("Editor: the graphics device could not be created");
			delete config;
			return 1;
		}
		defer delete graphics;

		let app = scope EditorApplication(config);
		return DesktopRunner.RunApplication(app, shell, graphics);
	}
}
