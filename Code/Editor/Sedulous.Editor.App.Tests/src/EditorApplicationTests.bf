using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.GUI; // the dock's layout
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// EditorApplication's lifecycle, headless. With no window OnStartup starts nothing and
/// OnShutdown has nothing to stop, however often. The parts that need no window start in order
/// (export, the MCP host, the editor-wide actions), once however often asked: the actions
/// registered are the ones this lifecycle can run, Exit reaching the host, Reset Layout the dock
/// and the cooks, the Game tab and Save off with no project; they stop in the order shutdown needs, leaving no project and no MCP host.
/// Close Project is always offered: it starts the project manager (the one given, else the one
/// that ran last, else the SDK's own) and the editor exits, or, with none found or one that does
/// not start, says so and stays. A thumbnail the thumbnail service says is ready is told to the
/// context's thumbnail listeners (the assets browser's).
///
/// Not here: a project opened through the application, since the session then saves the user's
/// editor.settings.xml (EditorSessionTests drive the session over services of their own); the
/// MCP host started, which mints and saves the user's token; and everything with a window or a
/// device: the GUI, the embedded runtime, the frames, the captures, About's message box. Close
/// Project reads a scratch SDK registry, never the user's, and starts no process.
static class EditorApplicationTests
{
	/// No shell, no graphics, no windows; it counts the exits asked of it.
	private class HeadlessHost : IApplicationHost
	{
		public SubsystemManager Subsystems { get; } = new .() ~ delete _;
		public int Exits = 0;

		public IShell Shell => null;
		public GraphicsDevice Graphics => null;
		public RenderWindow MainRenderWindow => null;

		public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) => null;
		public void CloseWindow(RenderWindow window) {}
		public void RequestExit(int code = 0) { Exits++; }
	}

	/// The editor-wide actions the lifecycle gives a hook to.
	private static StringView[24] sRegistered = .("file.save", "file.saveAs", "file.closeProject", "file.exit", "edit.undo", "edit.redo", "page.discardChanges",
		"edit.preferences", "project.settings", "project.export", "project.reportResourceMemory", "build.cookAll",
		"build.rebuildAll", "build.cookPage", "build.rebuildPage", "build.reimportPage", "game.play", "game.playNewInstance", "view.resetLayout",
		"view.profiler", "profiler.record", "view.screenshot", "view.commandPalette", "help.about");
	/// The ones a later layer brings: no hook yet, so not registered.
	private static StringView[1] sLeftOut = .("file.saveLayout");

	/// A scratch folder `name` beside the tests, emptied.
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
		Test.Assert(CreateDirectory(outPath));
	}

	/// A file at `path`, its folders made: a project manager to find.
	private static void Touch(StringView path)
	{
		Test.Assert(CreateDirectory(PathParent(path, .. scope .())));
		Test.Assert(System.IO.File.WriteAllText(path, "manager") case .Ok);
	}

	/// The registry refused `id` as not enabled (over no subject).
	private static bool Refused(EditorActionRegistry actions, StringView id)
	{
		if (actions.Execute(id) case .Err(let error))
			return error == .NotSupported;
		return false;
	}

	[Test]
	public static void WithNoWindowStartupStartsNothingAndShutdownHasNothingToStop()
	{
		let host = scope HeadlessHost();
		bool registered = false;
		bool finished = false;
		let config = new EditorAppConfig();
		config.RegisterEditors = new [&] (application, embeddedHost) => { registered = true; };
		config.StartupFinished = new [&] () => { finished = true; };
		let app = scope EditorApplication(config);
		app.OnStartup(host);
		Test.Assert(!app.Window.IsOpen);
		Test.Assert((app.Export == null) && (app.McpService == null));
		Test.Assert(app.Context.Actions.Count == 0);
		Test.Assert(!registered && !finished, "no editors registered, no splash closed: nothing started");
		app.OnShutdown(host);
		app.OnShutdown(host); // again: nothing left to stop
		Test.Assert(app.Project == null);
		Test.Assert(host.Exits == 0);
	}

	[Test]
	public static void ThePartsStartOnceWithTheActionsTheLifecycleCanRun()
	{
		let host = scope HeadlessHost();
		let app = scope EditorApplication(new EditorAppConfig());
		app.OnStartup(host); // the host kept; no window, so nothing more
		app.StartParts();
		Test.Assert(app.Export != null);
		Test.Assert(app.McpService != null);
		Test.Assert(!app.McpService.IsRunning, "not enabled, and no project");
		let actions = app.Context.Actions;
		for (let id in sRegistered)
			Test.Assert(actions.Find(id) != null, scope $"{id} registered");
		for (let id in sLeftOut)
			Test.Assert(actions.Find(id) == null, scope $"{id} left out until its layer");

		// Again: the same parts, no action twice.
		let exportBefore = app.Export;
		let mcpBefore = app.McpService;
		let count = actions.Count;
		app.StartParts();
		Test.Assert((app.Export === exportBefore) && (app.McpService === mcpBefore));
		Test.Assert(actions.Count == count);

		// Exit asks the host at once with no page unsaved; the cooks, Project Settings, Export and the
		// Game tab need a project, Save and Save As a page; About, the screenshot, the palette,
		// and Preferences do nothing with no interface and no window.
		Test.Assert(actions.Execute("file.exit") case .Ok);
		Test.Assert(host.Exits == 1);
		Test.Assert(Refused(actions, "file.saveAs"));
		Test.Assert(Refused(actions, "build.cookAll"));
		Test.Assert(Refused(actions, "build.rebuildAll"));
		Test.Assert(Refused(actions, "build.cookPage"));
		Test.Assert(Refused(actions, "build.rebuildPage"));
		Test.Assert(Refused(actions, "build.reimportPage"));
		Test.Assert(Refused(actions, "project.settings"));
		Test.Assert(Refused(actions, "project.export"));
		Test.Assert(Refused(actions, "game.play"));
		Test.Assert(Refused(actions, "game.playNewInstance"));
		Test.Assert(Refused(actions, "file.save"));
		Test.Assert(app.Pages.Count == 0);
		Test.Assert(actions.Execute("help.about") case .Ok);
		Test.Assert(actions.Execute("view.screenshot") case .Ok);
		Test.Assert(actions.Execute("view.commandPalette") case .Ok);
		Test.Assert(actions.Execute("edit.preferences") case .Ok);
		// Reset Layout reaches the dock: unopened, its controller takes the default layout all the
		// same (a panel the layout names unregistered keeps its place).
		let layout = app.Dock.Controller.Layout;
		Test.Assert(layout.StackOf(EditorDock.cPanelProject) == cNoDock);
		Test.Assert(actions.Execute("view.resetLayout") case .Ok);
		Test.Assert(layout.StackOf(EditorDock.cPanelProject) == layout.CentralStack);
		Test.Assert(layout.StackOf(EditorDock.cPanelConsole) != cNoDock);
		app.OnShutdown(host);
	}

	/// Close Project, always offered, starts the project manager given on the command line
	/// (--manager) with this editor's data root, and the editor exits: nothing unsaved to ask about.
	[Test]
	public static void CloseProjectStartsTheGivenManagerThenTheEditorExits()
	{
		let scratch = Scratch("scratch_app_close_project", .. scope .());
		defer RemoveDirectoryRecursive(scratch);
		let manager = PathJoin(scratch, "sdk/ProjectManager/manager", .. scope .());
		Touch(manager);
		let data = PathJoin(scratch, "sdk/Data", .. scope .());
		let launched = scope List<String>();
		defer ClearAndDeleteItems(launched);
		let host = scope HeadlessHost();
		let config = new EditorAppConfig();
		config.ManagerPath.Set(manager);
		config.SdksPath.Set(PathJoin(scratch, "sdks.xml", .. scope .()));
		config.DataRoot.Set(data);
		config.LaunchManager = new [=launched] (executable, arguments) =>
			{
				launched.Add(new String(executable));
				for (let argument in arguments)
					launched.Add(new String(argument));
				return true;
			};
		let app = scope EditorApplication(config);
		app.OnStartup(host); // no window: the host kept, nothing more
		app.StartParts();
		let actions = app.Context.Actions;
		Test.Assert(actions.Find("file.closeProject") != null, "always offered");
		Test.Assert(actions.Execute("file.closeProject") case .Ok);
		Test.Assert(launched.Count == 3, "the manager started once, with the data root");
		Test.Assert(launched[0] == manager, launched[0]);
		Test.Assert((launched[1] == "--data-root") && (launched[2] == data), launched[2]);
		Test.Assert(host.Exits == 1, "the editor exits for the manager");
		app.OnShutdown(host);
	}

	/// With no project manager to be found (the one given gone, none recorded in the registry,
	/// none in the SDK), Close Project says so and the editor stays; one found that does not start
	/// is said too, and the editor stays.
	[Test]
	public static void WithNoManagerToStartCloseProjectSaysSoAndTheEditorStays()
	{
		let scratch = Scratch("scratch_app_close_no_manager", .. scope .());
		defer RemoveDirectoryRecursive(scratch);
		let given = PathJoin(scratch, "gone/manager", .. scope .());
		let notices = scope List<String>();
		defer ClearAndDeleteItems(notices);
		int launches = 0;
		let host = scope HeadlessHost();
		let config = new EditorAppConfig();
		config.ManagerPath.Set(given);
		config.SdksPath.Set(PathJoin(scratch, "sdks.xml", .. scope .()));
		config.DataRoot.Set(PathJoin(scratch, "sdk/Data", .. scope .()));
		config.LaunchManager = new [&launches] (executable, arguments) =>
			{
				launches++;
				return false; // as a manager that cannot run
			};
		let app = scope EditorApplication(config);
		app.Context.OnNotice = new [=notices] (kind, message) => { notices.Add(new String(message)); };
		app.OnStartup(host);
		app.StartParts();

		Test.Assert(!app.CloseProject());
		Test.Assert((launches == 0) && (host.Exits == 0), "nothing started; the editor stays");
		Test.Assert(notices.Count == 1);
		Test.Assert(notices[0].StartsWith("No project manager was found"), notices[0]);

		Touch(given);
		Test.Assert(app.Context.Actions.Execute("file.closeProject") case .Ok);
		Test.Assert((launches == 1) && (host.Exits == 0), "it did not start: the editor stays");
		Test.Assert(notices.Count == 2);
		Test.Assert(notices[1].StartsWith("The project manager ") && notices[1].Contains("did not start"), notices[1]);
		app.OnShutdown(host);
	}

	/// The project manager Close Project starts: the one given (--manager), else the one the SDK
	/// registry recorded as the last to run, else ProjectManager/ in the SDK whose Data the editor
	/// runs on; each only when its file is there.
	[Test]
	public static void TheManagerIsTheGivenOneElseTheOneThatRanLastElseTheSdksOwn()
	{
		let scratch = Scratch("scratch_app_find_manager", .. scope .());
		defer RemoveDirectoryRecursive(scratch);
		let sdks = PathJoin(scratch, "sdks.xml", .. scope .());
		let data = PathJoin(scratch, "sdk/Data", .. scope .());
		let folder = PathJoin(PathJoin(scratch, "sdk", .. scope .()), ManagerLauncher.cManagerFolder, .. scope .());
		let own = PathJoin(folder, BuildLayout.ExecutableName(ManagerLauncher.cManagerName, .. scope .()), .. scope .());
		let recorded = PathJoin(scratch, "other sdk/ProjectManager/manager", .. scope .());
		let given = PathJoin(scratch, "given/manager", .. scope .());
		let found = scope String();

		Test.Assert(!ManagerLauncher.Find(given, sdks, data, found) && found.IsEmpty, "none there");
		Touch(own);
		Test.Assert(ManagerLauncher.Find(given, sdks, data, found) && (found == own), found);
		Touch(recorded);
		let registry = scope SdkRegistry(sdks);
		Test.Assert(registry.RecordManager(recorded) case .Ok);
		Test.Assert(ManagerLauncher.Find(given, sdks, data, found) && (found == recorded), "the one that ran last before the SDK's own");
		Touch(given);
		Test.Assert(ManagerLauncher.Find(given, sdks, data, found) && (found == given), "the one given first");
		Test.Assert(ManagerLauncher.Find("", sdks, "", found) && (found == recorded), "none given: the one that ran last");
	}

	[Test]
	public static void ThePartsStopLeavingNoProjectAndNoMcpHost()
	{
		// Declared before the application, whose context's hook adds to them.
		let notices = scope List<String>();
		defer ClearAndDeleteItems(notices);
		let host = scope HeadlessHost();
		let app = scope EditorApplication(new EditorAppConfig());
		app.Context.OnNotice = new [=notices] (kind, message) => { notices.Add(new String(message)); };
		app.OnStartup(host);
		app.StartParts();
		// Export is wired to the context, and with no project it says so.
		app.Export.Run("Default", false);
		Test.Assert((notices.Count == 1) && (notices[0] == "Open a project first."));
		Test.Assert(!app.Export.IsPending);

		app.StopParts();
		Test.Assert(app.Project == null);
		Test.Assert(app.Context.Project == null);
		Test.Assert(app.McpService == null, "released with the parts");
		Test.Assert(app.Export != null, "the export stays until the application goes");
		app.StopParts(); // again: nothing left to stop
		app.OnShutdown(host);
		Test.Assert(app.McpService == null);
	}

	/// The thumbnail service's ready signal reaches the context's thumbnail listeners, the
	/// assets browser's among them: nothing else tells them.
	[Test]
	public static void AThumbnailReadyIsToldToTheContextsListeners()
	{
		let app = scope EditorApplication(new EditorAppConfig());
		let thumbnails = app.Context.Thumbnails;
		Test.Assert((thumbnails != null) && (thumbnails.OnThumbnailReady != null));
		let heard = scope List<Guid>();
		let listener = app.Context.AddThumbnailListener(new [=heard] (id) => { heard.Add(id); });
		let id = Guid(7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		thumbnails.OnThumbnailReady(id); // as the service fires it when a thumbnail lands
		Test.Assert((heard.Count == 1) && (heard[0] == id));
		app.Context.RemoveThumbnailListener(listener);
	}
}
