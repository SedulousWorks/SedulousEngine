using System;
using System.Collections;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.GUI; // the dock's layout
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// EditorApplication's lifecycle, headless. With no window OnStartup starts nothing and
/// OnShutdown has nothing to stop, however often. The parts that need no window start in order
/// (export, the MCP host, the editor-wide actions), once however often asked: the actions
/// registered are the ones this lifecycle can run, Exit reaching the host, Reset Layout the dock
/// and the cooks, the Game tab and Save off with no project; they stop in the order shutdown needs, leaving no project and no MCP host.
/// Close Project is offered only when the project manager launched the editor, and with no window
/// the manager never shows.
///
/// Not here: a project opened through the application, since the session then saves the user's
/// editor.settings.xml (EditorSessionTests drive the session over services of their own); the
/// MCP host started, which mints and saves the user's token; and everything with a window or a
/// device: the GUI, the embedded runtime, the frames, the captures, About's message box.
static class EditorApplicationTests
{
	/// No shell, no graphics, no windows; it counts the exits asked of it.
	private class HeadlessHost : IApplicationHost
	{
		public Context Context { get; } = new .() ~ delete _;
		public int Exits = 0;

		public IShell Shell => null;
		public GraphicsDevice Graphics => null;
		public RenderWindow MainRenderWindow => null;

		public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) => null;
		public void CloseWindow(RenderWindow window) {}
		public void RequestExit(int code = 0) { Exits++; }
	}

	/// The editor-wide actions the lifecycle gives a hook to.
	private static StringView[17] sRegistered = .("file.save", "file.saveAs", "file.exit", "edit.undo", "edit.redo", "page.discardChanges",
		"edit.preferences", "project.settings", "project.reportResourceMemory", "build.cookAll", "build.rebuildAll", "game.play",
		"game.playNewInstance", "view.resetLayout", "view.screenshot", "view.commandPalette", "help.about");
	/// The ones a later layer brings: no hook yet, so not registered. Close Project is here because
	/// a project given on the command line keeps its one project.
	private static StringView[6] sLeftOut = .("file.saveLayout", "file.closeProject",
		"edit.exportTemplates", "project.export", "view.profiler", "profiler.record");

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

		// Exit asks the host at once with no page unsaved; the cooks, Project Settings and the Game
		// tab need a project, Save and Save As a page; About, the screenshot, the palette and Preferences do
		// nothing with no interface and no window.
		Test.Assert(actions.Execute("file.exit") case .Ok);
		Test.Assert(host.Exits == 1);
		Test.Assert(Refused(actions, "file.saveAs"));
		Test.Assert(Refused(actions, "build.cookAll"));
		Test.Assert(Refused(actions, "build.rebuildAll"));
		Test.Assert(Refused(actions, "project.settings"));
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

	[Test]
	public static void CloseProjectIsOfferedOnlyWhenTheManagerLaunchedTheEditor()
	{
		let host = scope HeadlessHost();
		let config = new EditorAppConfig();
		config.StartInProjectManager = true;
		let app = scope EditorApplication(config);
		app.OnStartup(host); // no window: the manager never shows
		app.StartParts();
		Test.Assert(app.ManagerMode != null);
		Test.Assert(app.ManagerMode.View == null);
		let actions = app.Context.Actions;
		Test.Assert(actions.Find("file.closeProject") != null);
		// With no project it closes nothing and asks nothing.
		Test.Assert(actions.Execute("file.closeProject") case .Ok);
		Test.Assert(app.Project == null);
		Test.Assert(app.ManagerMode.View == null);
		app.OnShutdown(host);
		Test.Assert(app.ManagerMode == null, "it goes with the window");
		Test.Assert(actions.Execute("file.closeProject") case .Ok, "shut down: nothing to reach");
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
}
