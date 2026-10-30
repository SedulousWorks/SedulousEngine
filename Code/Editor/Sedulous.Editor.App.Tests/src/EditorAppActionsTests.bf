using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Resource;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The editor-wide actions: each menu registers what the application can run, with its id,
/// label, menu path, order and keys; one it gives nothing for is left out; one that needs a
/// project is off without one. Each action runs its hook (or the context's cook request, or the
/// resource report), over the subject page where it takes one, and its enabled and checked
/// states follow what they read.
class EditorAppActionsTests
{
	public typealias Hook = delegate void();
	public typealias PageHook = delegate void(EditorPage page);

	/// A page with a title the hooks record; its edits are AddOne commands on Value.
	class TestPage : EditorPage
	{
		public int Value = 0;
		private String mTitle = new .() ~ delete _;

		public this(StringView title)
		{
			mTitle.Set(title);
		}

		public override StringView Title => mTitle;
		public override Result<void, ErrorCode> Save() => .Ok;
	}

	/// One reversible edit: Value up by one.
	class AddOne : EditorCommand
	{
		private TestPage mPage;

		public this(TestPage page)
		{
			mPage = page;
		}

		public override bool Execute()
		{
			mPage.Value++;
			return true;
		}

		public override void Undo()
		{
			mPage.Value--;
		}

		public override StringView TypeId => "add_one";
	}

	/// A registry, a context whose status lines land in Events beside the hooks' runs, and a
	/// scratch project to open in it.
	class Bench
	{
		public EditorActionRegistry Actions = new .() ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public List<String> Events = new .() ~ DeleteContainerAndItems!(_);
		/// The rebuild flag of each cook the context was asked for.
		public List<bool> Cooks = new .() ~ delete _;
		public EditorProject Project = null ~ delete _;
		public String Dir = new .() ~ delete _;

		public this()
		{
			let events = Events;
			Context.OnStatus = new [=events](text) =>
				{
					let line = new String("status:");
					line.Append(text);
					events.Add(line);
				};
			let cooks = Cooks;
			Context.OnCookRequested = new [=cooks](rebuild) => { cooks.Add(rebuild); };
		}

		public ~this()
		{
			if (Project != null)
			{
				Context.SetProject(null);
				DeleteAndNullify!(Project);
				RemoveDirectoryRecursive(Dir);
			}
		}

		/// A scratch project, open in the context.
		public void OpenProject(StringView leaf)
		{
			PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), scope $"scratch_{leaf}_project", Dir);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Actions") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
		}

		/// A hook that records `name` when it runs.
		public Hook Record(StringView name)
		{
			let events = Events;
			let tag = new String(name);
			return new [=events, =tag] () => { events.Add(new String(tag)); } ~ delete tag;
		}

		/// A page hook that records `name:<the page's title>` when it runs.
		public PageHook RecordPage(StringView name)
		{
			let events = Events;
			let tag = new String(name);
			return new [=events, =tag] (page) =>
				{
					let line = new String(tag);
					line.Append(':');
					line.Append(page.Title);
					events.Add(line);
				} ~ delete tag;
		}

		/// The events so far, joined by ',', then forgotten.
		public void Take(String outEvents)
		{
			for (let e in Events)
			{
				if (!outEvents.IsEmpty)
					outEvents.Append(',');
				outEvents.Append(e);
			}
			ClearAndDeleteItems(Events);
		}

		public bool Said(StringView expected)
		{
			let events = Take(.. scope .());
			return events == expected;
		}
	}

	/// The global log, kept in Log while it lives.
	class LogCapture
	{
		public EditorLogBuffer Log = new .() ~ delete _;
		private ILogger mPrevious;
		private bool mPreviousOwned = false;

		public this()
		{
			mPrevious = DetachGlobalLogger(out mPreviousOwned);
			InitGlobalLogger(Log);
		}

		public ~this()
		{
			bool owned = false;
			DetachGlobalLogger(out owned);
			InitGlobalLogger(mPrevious, mPreviousOwned);
		}

		/// Whether a line logged since the last call contains `text`.
		public bool Logged(StringView text, ref uint64 since)
		{
			let entries = scope List<EditorLogEntry>();
			since = Log.CollectSince(since, entries);
			bool found = false;
			for (let entry in entries)
			{
				if (entry.Message.Contains(text))
					found = true;
			}
			ClearAndDeleteItems(entries);
			return found;
		}
	}

	/// Each menu with every hook given, in menu order.
	static void RegisterAll(Bench bench)
	{
		let file = new FileActions();
		file.Context = bench.Context;
		file.Save = bench.RecordPage("save");
		file.SaveAs = bench.RecordPage("saveAs");
		file.SaveLayout = bench.Record("saveLayout");
		file.CloseProject = bench.Record("closeProject");
		file.Exit = bench.Record("exit");
		EditorAppActions.RegisterFileActions(bench.Actions, file);

		let edit = new EditActions();
		edit.Preferences = bench.Record("preferences");
		edit.ExportTemplates = bench.Record("exportTemplates");
		EditorAppActions.RegisterEditActions(bench.Actions, edit);

		let project = new ProjectActions();
		project.Context = bench.Context;
		project.Settings = bench.Record("settings");
		project.ExportPresets = bench.Record("export");
		EditorAppActions.RegisterProjectActions(bench.Actions, project);

		EditorAppActions.RegisterBuildActions(bench.Actions, bench.Context);

		let game = new GameActions();
		game.Context = bench.Context;
		game.Play = bench.Record("play");
		game.PlayNewInstance = bench.Record("playNewInstance");
		EditorAppActions.RegisterGameActions(bench.Actions, game);

		let view = new ViewActions();
		view.Context = bench.Context;
		view.ResetLayout = bench.Record("resetLayout");
		view.Profiler = bench.Record("profiler");
		view.ProfilerRecord = bench.Record("profilerRecord");
		view.Screenshot = bench.Record("screenshot");
		view.CommandPalette = bench.Record("commandPalette");
		EditorAppActions.RegisterViewActions(bench.Actions, view);

		let help = new HelpActions();
		help.About = bench.Record("about");
		EditorAppActions.RegisterHelpActions(bench.Actions, help);
	}

	[Test]
	public static void AMenuRegistersWhatCanRunWithItsKeysAndWhatNeedsAProjectIsOffWithoutOne()
	{
		let bench = scope Bench();
		let actions = bench.Actions;
		let file = new FileActions();
		file.Exit = bench.Record("exit");
		EditorAppActions.RegisterFileActions(actions, file);
		Test.Assert(actions.Find("file.exit") != null);
		Test.Assert(actions.Find("file.save") == null, "no save given: left out");
		Test.Assert(actions.Find("file.saveLayout") == null);
		Test.Assert(actions.Execute("file.exit", null) case .Ok);
		Test.Assert(bench.Said("exit"));

		EditorAppActions.RegisterEditActions(actions, new EditActions());
		Test.Assert(actions.Shortcut("edit.undo") == EditorShortcut.Of("ctrl-z"));
		Test.Assert(actions.AlternateShortcut("edit.redo") == EditorShortcut.Of("ctrl-y"));
		Test.Assert(actions.Find("edit.preferences") == null);
		Test.Assert(!actions.IsEnabled("edit.undo", null), "no page");

		// Raptor checks this with Reload Native Module, which Sedulous's editor does not have.
		let project = new ProjectActions();
		project.Context = bench.Context;
		project.Settings = bench.Record("settings");
		EditorAppActions.RegisterProjectActions(actions, project);
		Test.Assert(!actions.IsEnabled("project.settings", null), "no project open");
		Test.Assert(actions.Execute("project.settings", null) case .Err(.NotSupported));
		Test.Assert(bench.Events.IsEmpty);
		Test.Assert(actions.Find("project.reportResourceMemory").ReadOnly);

		let view = new ViewActions();
		view.Screenshot = bench.Record("screenshot");
		EditorAppActions.RegisterViewActions(actions, view);
		Test.Assert(actions.Shortcut("view.screenshot") == EditorShortcut.Of("f12"));
		Test.Assert(actions.Find("view.commandPalette") == null);
	}

	/// One registered action as the surfaces read it.
	struct Row
	{
		public StringView Id;
		public StringView Label;
		public StringView MenuPath;
		public int32 MenuOrder;
		public StringView Keys;
		public StringView AlternateKeys;
		public bool ReadOnly;
		public bool Toggle;

		public this(StringView id, StringView label, StringView menuPath, int32 menuOrder, StringView keys = "", StringView alternateKeys = "", bool readOnly = false, bool toggle = false)
		{
			Id = id;
			Label = label;
			MenuPath = menuPath;
			MenuOrder = menuOrder;
			Keys = keys;
			AlternateKeys = alternateKeys;
			ReadOnly = readOnly;
			Toggle = toggle;
		}
	}

	[Test]
	public static void EveryHookGivenRegistersTheWholeSetInMenuOrderWithItsPathsAndKeys()
	{
		let bench = scope Bench();
		RegisterAll(bench);
		Row[26] expected = .(
			.("file.save", "Save", "File/Save", 100, "ctrl-s"),
			.("file.saveAs", "Save As...", "File/Save As...", 101),
			.("file.saveLayout", "Save Layout", "File/Save Layout", 200),
			.("file.closeProject", "Close Project", "File/Close Project", 300),
			.("file.exit", "Exit", "File/Exit", 301),
			.("edit.undo", "Undo", "Edit/Undo", 100, "ctrl-z"),
			.("edit.redo", "Redo", "Edit/Redo", 101, "ctrl-shift-z", "ctrl-y"),
			.("page.discardChanges", "Discard Changes", "", 0),
			.("playback.play", "Play", "", 0, "", "", false, true),
			.("playback.stop", "Stop", "", 0),
			.("playback.restart", "Restart", "", 0),
			.("edit.preferences", "Preferences...", "Edit/Preferences...", 200),
			.("edit.exportTemplates", "Export Templates...", "Edit/Export Templates...", 201),
			.("project.settings", "Project Settings...", "Project/Project Settings...", 100),
			.("project.export", "Export...", "Project/Export...", 300),
			.("project.reportResourceMemory", "Report Resource Memory", "Project/Report Resource Memory", 400, "", "", true),
			.("build.cookAll", "Cook All", "Build/Cook All", 100),
			.("build.rebuildAll", "Rebuild All", "Build/Rebuild All", 101),
			.("game.play", "Play", "Game/Play", 100),
			.("game.playNewInstance", "Play New Instance", "Game/Play New Instance", 101),
			.("view.resetLayout", "Reset Layout", "View/Reset Layout", 100),
			.("view.profiler", "Profiler", "View/Profiler", 210, "", "", true),
			.("profiler.record", "Profiler Record", "View/Profiler Record", 211, "", "", true, true),
			.("view.screenshot", "Screenshot Editor", "View/Screenshot Editor", 300, "f12", "", true),
			.("view.commandPalette", "Command Palette...", "View/Command Palette...", 200, "ctrl-shift-p", "", true),
			.("help.about", "About", "Help/About", 100, "", "", true));
		let registered = bench.Actions.Actions;
		Test.Assert(registered.Count == expected.Count);
		for (int i < expected.Count)
		{
			let row = expected[i];
			let action = registered[i];
			Test.Assert(action.Id == row.Id, scope $"action {i} is '{action.Id}', not '{row.Id}'");
			Test.Assert(action.Label == row.Label, scope $"'{row.Id}' label");
			Test.Assert(action.MenuPath == row.MenuPath, scope $"'{row.Id}' menu path");
			Test.Assert(action.MenuOrder == row.MenuOrder, scope $"'{row.Id}' menu order");
			Test.Assert(bench.Actions.Shortcut(row.Id).Keys(.. scope .()) == row.Keys, scope $"'{row.Id}' shortcut");
			Test.Assert(bench.Actions.AlternateShortcut(row.Id).Keys(.. scope .()) == row.AlternateKeys, scope $"'{row.Id}' alternate");
			Test.Assert(action.ReadOnly == row.ReadOnly, scope $"'{row.Id}' read only");
			Test.Assert((action.Kind == .Toggle) == row.Toggle, scope $"'{row.Id}' kind");
			Test.Assert(!action.Description.IsEmpty, scope $"'{row.Id}' description");
		}
	}

	[Test]
	public static void FileSavesTheSubjectPageWhileItCanAndSaysWhenTheLayoutIsSaved()
	{
		let bench = scope Bench();
		RegisterAll(bench);
		let actions = bench.Actions;
		let page = scope TestPage("Level");

		// Save: off with no page and with a clean one, on once the page is dirty.
		Test.Assert(!actions.IsEnabled("file.save", null));
		Test.Assert(!actions.IsEnabled("file.save", page));
		Test.Assert(actions.Execute("file.save", page) case .Err(.NotSupported));
		Test.Assert(bench.Events.IsEmpty);
		page.MarkDirty();
		Test.Assert(actions.IsEnabled("file.save", page));
		Test.Assert(actions.Execute("file.save", page) case .Ok);
		Test.Assert(bench.Said("save:Level"));

		// Save As: any page, clean or not.
		page.ClearDirty();
		Test.Assert(!actions.IsEnabled("file.saveAs", null));
		Test.Assert(actions.IsEnabled("file.saveAs", page));
		Test.Assert(actions.Execute("file.saveAs", page) case .Ok);
		Test.Assert(bench.Said("saveAs:Level"));

		// Save Layout runs, then says so.
		Test.Assert(actions.IsEnabled("file.saveLayout", null));
		Test.Assert(actions.Execute("file.saveLayout", null) case .Ok);
		Test.Assert(bench.Said("saveLayout,status:Layout saved."));

		Test.Assert(actions.Execute("file.closeProject", null) case .Ok);
		Test.Assert(bench.Said("closeProject"));
		Test.Assert(actions.Execute("file.exit", null) case .Ok);
		Test.Assert(bench.Said("exit"));
	}

	[Test]
	public static void FileLeavesOutWhatItIsNotGivenAndTheLayoutSavesQuietlyWithNoContext()
	{
		let bench = scope Bench();
		let actions = bench.Actions;
		EditorAppActions.RegisterFileActions(actions, new FileActions());
		Test.Assert(actions.Count == 0);

		let file = new FileActions();
		file.SaveLayout = bench.Record("saveLayout");
		EditorAppActions.RegisterFileActions(actions, file);
		Test.Assert(actions.Count == 1);
		Test.Assert(actions.Find("file.closeProject") == null, "the manager did not launch it: no Close Project");
		Test.Assert(actions.Execute("file.saveLayout", null) case .Ok);
		Test.Assert(bench.Said("saveLayout"));
	}

	[Test]
	public static void EditUndoesRedoesAndDiscardsOnTheSubjectPageAsItsStackAllows()
	{
		let bench = scope Bench();
		RegisterAll(bench);
		let actions = bench.Actions;
		let page = scope TestPage("Level");

		Test.Assert(!actions.IsEnabled("edit.undo", page), "nothing to undo");
		Test.Assert(!actions.IsEnabled("edit.redo", page), "nothing to redo");
		Test.Assert(!actions.IsEnabled("page.discardChanges", page), "nothing unsaved");
		Test.Assert(!actions.IsEnabled("edit.redo", null));
		Test.Assert(!actions.IsEnabled("page.discardChanges", null));

		Test.Assert(page.Commands.Execute(new AddOne(page)));
		Test.Assert(page.Value == 1);
		Test.Assert(actions.IsEnabled("edit.undo", page));
		Test.Assert(!actions.IsEnabled("edit.redo", page));
		Test.Assert(actions.Execute("edit.undo", page) case .Ok);
		Test.Assert(page.Value == 0);
		Test.Assert(!actions.IsEnabled("edit.undo", page));
		Test.Assert(actions.IsEnabled("edit.redo", page));
		Test.Assert(actions.Execute("edit.redo", page) case .Ok);
		Test.Assert(page.Value == 1);

		Test.Assert(page.IsDirty);
		Test.Assert(actions.IsEnabled("page.discardChanges", page));
		Test.Assert(actions.Execute("page.discardChanges", page) case .Ok);
		Test.Assert(page.Value == 0, "the edit reverted");
		Test.Assert(!page.IsDirty);
		Test.Assert(!actions.IsEnabled("edit.undo", page), "the stack cleared");

		// The playback actions come with Edit.
		Test.Assert(actions.Find("playback.play") != null);
		Test.Assert(actions.Find("playback.stop") != null);
		Test.Assert(actions.Find("playback.restart") != null);

		Test.Assert(actions.Execute("edit.preferences", null) case .Ok);
		Test.Assert(bench.Said("preferences"));
		Test.Assert(actions.Execute("edit.exportTemplates", null) case .Ok);
		Test.Assert(bench.Said("exportTemplates"));
		Test.Assert(bench.Events.IsEmpty, "undo, redo and discard run no hook");
	}

	[Test]
	public static void ProjectBuildAndGameNeedAProjectAndRunWhatTheyAreGivenOnceOneIsOpen()
	{
		let bench = scope Bench();
		RegisterAll(bench);
		let actions = bench.Actions;
		let gated = scope StringView[]("project.settings", "project.export", "build.cookAll", "build.rebuildAll", "game.play", "game.playNewInstance");
		for (let id in gated)
		{
			Test.Assert(!actions.IsEnabled(id, null), scope $"'{id}' is off with no project");
			Test.Assert(actions.Execute(id, null) case .Err(.NotSupported));
		}
		Test.Assert(bench.Events.IsEmpty);
		Test.Assert(bench.Cooks.IsEmpty);

		bench.OpenProject("appactions_gated");
		for (let id in gated)
			Test.Assert(actions.IsEnabled(id, null), scope $"'{id}' is on with a project");
		Test.Assert(actions.Execute("project.settings", null) case .Ok);
		Test.Assert(bench.Said("settings"));
		Test.Assert(actions.Execute("project.export", null) case .Ok);
		Test.Assert(bench.Said("export"));
		Test.Assert(actions.Execute("game.play", null) case .Ok);
		Test.Assert(bench.Said("play"));
		Test.Assert(actions.Execute("game.playNewInstance", null) case .Ok);
		Test.Assert(bench.Said("playNewInstance"));

		// Build asks the context for its cooks: incremental, then everything again.
		Test.Assert(actions.Execute("build.cookAll", null) case .Ok);
		Test.Assert(actions.Execute("build.rebuildAll", null) case .Ok);
		Test.Assert(bench.Cooks.Count == 2);
		Test.Assert(!bench.Cooks[0], "Cook All is incremental");
		Test.Assert(bench.Cooks[1], "Rebuild All rebuilds");
		Test.Assert(bench.Events.IsEmpty, "a cook runs no hook");
	}

	[Test]
	public static void ProjectBuildAndGameLeaveOutWhatTheyAreNotGivenAndAreOffWithNoContext()
	{
		let bench = scope Bench();
		let actions = bench.Actions;
		EditorAppActions.RegisterProjectActions(actions, new ProjectActions());
		EditorAppActions.RegisterBuildActions(actions, null);
		EditorAppActions.RegisterGameActions(actions, new GameActions());
		Test.Assert(actions.Count == 1, "only the resource report, which needs no hook");
		Test.Assert(actions.Find("project.reportResourceMemory") != null);

		// Given hooks but no context: never a project, though one is open.
		let other = scope EditorActionRegistry();
		let project = new ProjectActions();
		project.Settings = bench.Record("settings");
		EditorAppActions.RegisterProjectActions(other, project);
		let game = new GameActions();
		game.Play = bench.Record("play");
		EditorAppActions.RegisterGameActions(other, game);
		bench.OpenProject("appactions_nocontext");
		Test.Assert(!other.IsEnabled("project.settings", null));
		Test.Assert(!other.IsEnabled("game.play", null));
		Test.Assert(other.Execute("game.play", null) case .Err(.NotSupported));
		Test.Assert(bench.Events.IsEmpty);
	}

	[Test]
	public static void ReportResourceMemoryLogsTheContextsResourcesOrSaysThereAreNone()
	{
		let capture = scope LogCapture();
		uint64 since = 0;
		let bench = scope Bench();
		RegisterAll(bench);
		let actions = bench.Actions;
		Test.Assert(actions.IsEnabled("project.reportResourceMemory", null), "it needs no project");
		Test.Assert(actions.Execute("project.reportResourceMemory", null) case .Ok);
		Test.Assert(capture.Logged("no resource manager", ref since));

		bench.OpenProject("appactions_report");
		let resources = new ResourceManager(bench.Project.CookedDb);
		defer delete resources;
		bench.Context.Resources = resources;
		Test.Assert(actions.Execute("project.reportResourceMemory", null) case .Ok);
		bench.Context.Resources = null;
		Test.Assert(capture.Logged("0 live products total", ref since), "the report over the context's resources");

		// With no context to read, the same line as no project.
		let other = scope EditorActionRegistry();
		EditorAppActions.RegisterProjectActions(other, new ProjectActions());
		Test.Assert(other.Execute("project.reportResourceMemory", null) case .Ok);
		Test.Assert(capture.Logged("no resource manager", ref since));
	}

	[Test]
	public static void ViewRunsItsHooksAndProfilerRecordIsCheckedWhileRecording()
	{
		let bench = scope Bench();
		let actions = bench.Actions;
		bool recording = false;
		let view = new ViewActions();
		view.Context = bench.Context;
		view.ResetLayout = bench.Record("resetLayout");
		view.Profiler = bench.Record("profiler");
		view.ProfilerRecord = bench.Record("profilerRecord");
		view.ProfilerRecording = new [&recording] () => recording;
		view.Screenshot = bench.Record("screenshot");
		view.CommandPalette = bench.Record("commandPalette");
		EditorAppActions.RegisterViewActions(actions, view);

		Test.Assert(actions.Execute("view.resetLayout", null) case .Ok);
		Test.Assert(bench.Said("resetLayout,status:Layout reset to default."));
		Test.Assert(actions.Execute("view.profiler", null) case .Ok);
		Test.Assert(bench.Said("profiler"));
		Test.Assert(actions.Execute("view.screenshot", null) case .Ok);
		Test.Assert(bench.Said("screenshot"));
		Test.Assert(actions.Execute("view.commandPalette", null) case .Ok);
		Test.Assert(bench.Said("commandPalette"));

		Test.Assert(!actions.IsChecked("profiler.record", null));
		recording = true;
		Test.Assert(actions.IsChecked("profiler.record", null));
		Test.Assert(actions.Execute("profiler.record", null) case .Ok);
		Test.Assert(bench.Said("profilerRecord"));
		recording = false;
		Test.Assert(!actions.IsChecked("profiler.record", null));
		Test.Assert(!actions.IsChecked("view.profiler", null), "the panel action has no checked state");
	}

	[Test]
	public static void ViewAndHelpLeaveOutWhatTheyAreNotGiven()
	{
		let bench = scope Bench();
		let actions = bench.Actions;
		// A recording state with nothing to record is dropped with its holder.
		let view = new ViewActions();
		view.ProfilerRecording = new () => true;
		EditorAppActions.RegisterViewActions(actions, view);
		EditorAppActions.RegisterHelpActions(actions, new HelpActions());
		Test.Assert(actions.Count == 0);

		// Record given without its state: never checked; Reset Layout with no context says
		// nothing.
		let more = new ViewActions();
		more.ResetLayout = bench.Record("resetLayout");
		more.ProfilerRecord = bench.Record("profilerRecord");
		EditorAppActions.RegisterViewActions(actions, more);
		Test.Assert(actions.Count == 2);
		Test.Assert(!actions.IsChecked("profiler.record", null));
		Test.Assert(actions.Execute("view.resetLayout", null) case .Ok);
		Test.Assert(bench.Said("resetLayout"));

		let help = new HelpActions();
		help.About = bench.Record("about");
		EditorAppActions.RegisterHelpActions(actions, help);
		Test.Assert(actions.Execute("help.about", null) case .Ok);
		Test.Assert(bench.Said("about"));
	}

	/// An asset page's Cook and Rebuild: off with no project, or over a page with no asset (a Game
	/// tab), saying why; each runs over the page it is given.
	[Test]
	public static void AnAssetPagesCookAndRebuildAreOffWithNoProjectOrNoAssetAndRunOverTheirPage()
	{
		let bench = scope Bench();
		let actions = bench.Actions;
		let ran = scope List<String>();
		defer { ClearAndDeleteItems!(ran); }
		EditorAppActions.RegisterBuildActions(actions, bench.Context,
			new [=ran] (page) => { ran.Add(new $"cook {page.Title}"); },
			new [=ran] (page) => { ran.Add(new $"rebuild {page.Title}"); });
		Test.Assert(actions.Find("build.cookPage") != null);
		Test.Assert(actions.Find("build.rebuildPage") != null);
		Test.Assert(actions.Find("build.cookPage").MenuPath == "Build/Cook This Asset");

		let page = scope TestPage("Crate");
		Test.Assert(!actions.IsEnabled("build.cookPage", page));
		Test.Assert(actions.DisabledReason("build.cookPage", page, .. scope .()) == "Open a project first");

		bench.OpenProject("app_actions_cook");
		Test.Assert(!actions.IsEnabled("build.cookPage", page), "a page with no asset (a Game tab)");
		Test.Assert(actions.DisabledReason("build.cookPage", page, .. scope .()) == "This page shows no asset");
		Test.Assert(actions.DisabledReason("build.cookPage", null, .. scope .()) == "No page is active");
		page.InstanceId = Guid.Create();
		Test.Assert(actions.IsEnabled("build.cookPage", page));
		Test.Assert(actions.Execute("build.cookPage", page) case .Ok);
		Test.Assert(actions.Execute("build.rebuildPage", page) case .Ok);
		Test.Assert(ran.Count == 2);
		Test.Assert(ran[0] == "cook Crate");
		Test.Assert(ran[1] == "rebuild Crate");
		Test.Assert(bench.Cooks.IsEmpty, "the page's own cook, not the whole project's");
	}

	/// No context: the page cooks are left out, their hooks let go.
	[Test]
	public static void ThePageCooksAreLeftOutWithNoContext()
	{
		let actions = scope EditorActionRegistry();
		EditorAppActions.RegisterBuildActions(actions, null, new (page) => {}, new (page) => {});
		Test.Assert(actions.Count == 0);
	}
}
