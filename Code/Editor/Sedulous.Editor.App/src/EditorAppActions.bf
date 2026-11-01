using System;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// What File's actions run. The registration TAKES OWNERSHIP of these hooks; one left null
/// keeps its action out.
class FileActions
{
	/// Where Save Layout says it is done. Borrowed; null says nothing.
	public EditorContext Context = null;
	/// Saves the subject page (never null: the action is off without one). Owned.
	public delegate void(EditorPage page) Save ~ delete _;
	/// Saves the subject page as a new source asset. Owned.
	public delegate void(EditorPage page) SaveAs ~ delete _;
	/// Captures the panel layout and the open pages and writes them. Owned.
	public delegate void() SaveLayout ~ delete _;
	/// Only when the manager launched the editor: one opened from the command line keeps its
	/// single-project lifecycle, Exit being the way out. Owned.
	public delegate void() CloseProject ~ delete _;
	/// Asks the user about unsaved pages, then exits. Owned.
	public delegate void() Exit ~ delete _;
}

/// What Edit's actions run (undo, redo and discard work on the subject page itself). Owned
/// hooks, as FileActions'.
class EditActions
{
	/// Opens the per-user preferences dialog. Owned.
	public delegate void() Preferences ~ delete _;
	/// Opens the export templates manager. Owned.
	public delegate void() ExportTemplates ~ delete _;
}

/// What Project's actions run; most need a project open in Context. Owned hooks, as
/// FileActions'.
class ProjectActions
{
	/// Whether a project is open, and the resources Report Resource Memory reports. Borrowed;
	/// null is never a project, and the report then says no resource manager.
	public EditorContext Context = null;
	/// Opens the project settings dialog. Owned.
	public delegate void() Settings ~ delete _;
	/// Opens the export presets panel. Owned.
	public delegate void() ExportPresets ~ delete _;
	// Raptor's native module actions (Add Native Code, Build and Reload Native Module) are not
	// here: Sedulous's editor does not handle a project's native code (RaptorSync.md, "Standing
	// differences").
}

/// What Game's actions run; they need a project open in Context. Owned hooks, as FileActions'.
class GameActions
{
	/// Borrowed; null is never a project.
	public EditorContext Context = null;
	/// Plays in the primary Game page. Owned.
	public delegate void() Play ~ delete _;
	/// Plays in a fresh Game page. Owned.
	public delegate void() PlayNewInstance ~ delete _;
}

/// What View's actions run. Owned hooks, as FileActions'.
class ViewActions
{
	/// Where Reset Layout says it is done. Borrowed; null says nothing.
	public EditorContext Context = null;
	/// Puts the panels back in the default layout. Owned.
	public delegate void() ResetLayout ~ delete _;
	/// Brings the Assets panel back, or to the front. Owned.
	public delegate void() Assets ~ delete _;
	/// Brings the Console panel back, or to the front. Owned.
	public delegate void() Console ~ delete _;
	/// Shows the Profiler page. Owned.
	public delegate void() Profiler ~ delete _;
	/// Whether the profiler is recording: Profiler Record's checked state; null is never.
	/// Owned, and dropped with ProfilerRecord when that is not given.
	public delegate bool() ProfilerRecording ~ delete _;
	/// Shows the Profiler page and starts or stops its recording. Owned.
	public delegate void() ProfilerRecord ~ delete _;
	/// Writes the main window to a PNG under <user-data>/screenshots. Owned.
	public delegate void() Screenshot ~ delete _;
	/// Opens the command palette over the registry. Owned.
	public delegate void() CommandPalette ~ delete _;
}

/// What Help's actions run. Owned hooks, as FileActions'.
class HelpActions
{
	/// Shows the editor's version. Owned.
	public delegate void() About ~ delete _;
}

/// The editor-wide actions (File, Edit, Project, Build, Game, View, Help), out of the
/// application (Raptor's editor-gui spec, 5.1, layer 3): one registration per menu, each
/// declaration as the menu bar, the shortcuts, the palette and the MCP bridge read it. Called in
/// menu order, before the domains register theirs: the bar lists menus in the order their names
/// first appear. An action runs what the application gives it; one it gives nothing for (a
/// dialog not on the GUI yet) is left out until it is, so a surface never offers what cannot
/// run. What the context itself reaches (the cook, the resources) the actions call directly.
static class EditorAppActions
{
	typealias Hook = delegate void();
	typealias PageHook = delegate void(EditorPage page);

	/// Registers `d` running `run`, taking the hook (the field is left null so its holder does
	/// not delete it too); with no hook, `d` is dropped.
	private static void Add(EditorActionRegistry actions, EditorActionDeclaration d, ref Hook run)
	{
		if (run == null)
		{
			delete d;
			return;
		}
		let hook = run;
		run = null;
		d.Execute = new [=hook] (page) => { hook(); } ~ delete hook;
		actions.Register(d);
	}

	/// Enabled while `context` has a project open.
	private static EditorActionDeclaration NeedsProject(EditorContext context, EditorActionDeclaration d)
	{
		d.Enabled = new [=context] (page) => (context != null) && (context.Project != null);
		return d;
	}

	/// File's actions. TAKES OWNERSHIP of `run`.
	public static void RegisterFileActions(EditorActionRegistry actions, FileActions run)
	{
		defer delete run;
		let context = run.Context;
		if (run.Save != null)
		{
			let d = new EditorActionDeclaration("file.save", "Save", "Save the active page to its source asset", "File/Save", 100);
			d.Enabled = new (page) => (page != null) && page.IsDirty;
			d.Shortcut = EditorShortcut.Of("ctrl-s");
			let save = run.Save;
			run.Save = null;
			d.Execute = new [=save] (page) => { save(page); } ~ delete save;
			actions.Register(d);
		}
		if (run.SaveAs != null)
		{
			let d = new EditorActionDeclaration("file.saveAs", "Save As...", "Save the active page as a new source asset", "File/Save As...", 101);
			d.Enabled = new (page) => page != null;
			let saveAs = run.SaveAs;
			run.SaveAs = null;
			d.Execute = new [=saveAs] (page) => { saveAs(page); } ~ delete saveAs;
			actions.Register(d);
		}
		if (run.SaveLayout != null)
		{
			let d = new EditorActionDeclaration("file.saveLayout", "Save Layout", "Save the panel layout as the default for this editor", "File/Save Layout", 200);
			let saveLayout = run.SaveLayout;
			run.SaveLayout = null;
			d.Execute = new [=saveLayout, =context] (page) =>
				{
					saveLayout();
					if (context != null)
						context.SetStatus("Layout saved.");
				} ~ delete saveLayout;
			actions.Register(d);
		}
		Add(actions, new EditorActionDeclaration("file.closeProject", "Close Project", "Close the project and return to the project manager", "File/Close Project", 300), ref run.CloseProject);
		Add(actions, new EditorActionDeclaration("file.exit", "Exit", "Exit the editor", "File/Exit", 301), ref run.Exit);
	}

	/// Edit's actions, the playback actions among them (the pages' transports, kept off the
	/// bar). TAKES OWNERSHIP of `run`.
	public static void RegisterEditActions(EditorActionRegistry actions, EditActions run)
	{
		defer delete run;
		{
			let d = new EditorActionDeclaration("edit.undo", "Undo", "Undo the active page's last edit", "Edit/Undo", 100);
			d.Enabled = new (page) => (page != null) && page.Commands.CanUndo;
			d.Shortcut = EditorShortcut.Of("ctrl-z");
			d.Execute = new (page) => { page.Commands.Undo(); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("edit.redo", "Redo", "Redo the active page's last undone edit", "Edit/Redo", 101);
			d.Enabled = new (page) => (page != null) && page.Commands.CanRedo;
			d.Shortcut = EditorShortcut.Of("ctrl-shift-z");
			d.AlternateShortcut = EditorShortcut.Of("ctrl-y");
			d.Execute = new (page) => { page.Commands.Redo(); };
			actions.Register(d);
		}
		{
			let d = new EditorActionDeclaration("page.discardChanges", "Discard Changes", "Revert the page's unsaved edits");
			d.Enabled = new (page) => (page != null) && page.IsDirty;
			d.Execute = new (page) => { page.DiscardChanges(); };
			actions.Register(d);
		}
		PlaybackActions.Register(actions);
		// Per-user, not per-document: the conventional Edit home.
		Add(actions, new EditorActionDeclaration("edit.preferences", "Preferences...", "Open the per-user editor preferences", "Edit/Preferences...", 200), ref run.Preferences);
		// The templates are the editor's, shared by every project: beside Preferences.
		Add(actions, new EditorActionDeclaration("edit.exportTemplates", "Export Templates...", "Manage the export templates this editor exports with", "Edit/Export Templates...", 201), ref run.ExportTemplates);
	}

	/// Project's actions. Report Resource Memory is always there: it reads the context's
	/// resources, which the session sets while a project is open. TAKES OWNERSHIP of `run`.
	public static void RegisterProjectActions(EditorActionRegistry actions, ProjectActions run)
	{
		defer delete run;
		let context = run.Context;
		Add(actions, NeedsProject(context, new EditorActionDeclaration("project.settings", "Project Settings...", "Open the project settings", "Project/Project Settings...", 100)), ref run.Settings);
		Add(actions, NeedsProject(context, new EditorActionDeclaration("project.export", "Export...", "Open the export presets panel", "Project/Export...", 300)), ref run.ExportPresets);
		{
			// What is resident, from the log: counts by product type, unreferenced being the
			// cache-only purge candidates.
			let d = new EditorActionDeclaration("project.reportResourceMemory", "Report Resource Memory", "Log the resident resources by type (unreferenced = purge candidates)", "Project/Report Resource Memory", 400);
			d.ReadOnly = true;
			d.Execute = new [=context] (page) => { EditorExport.ReportResourceMemory((context != null) ? context.Resources : null); };
			actions.Register(d);
		}
	}

	/// Build's actions, cooks through the context's cook request (the session wires it to the
	/// cook service while a project is open); they need a project open. Left out with no
	/// context. `cookPage` and `rebuildPage` cook the page's asset and what it needs (rebuild:
	/// again, whether changed or not), its unsaved changes saved first so the cook reads them;
	/// each is left out when null. TAKES OWNERSHIP of both.
	public static void RegisterBuildActions(EditorActionRegistry actions, EditorContext context, delegate void(EditorPage page) cookPage = null, delegate void(EditorPage page) rebuildPage = null)
	{
		if (context == null)
		{
			delete cookPage;
			delete rebuildPage;
			return;
		}
		{
			let d = NeedsProject(context, new EditorActionDeclaration("build.cookAll", "Cook All", "Cook the dirty assets into the cooked database", "Build/Cook All", 100));
			d.Execute = new [=context] (page) => { context.RequestCook(false); };
			actions.Register(d);
		}
		{
			let d = NeedsProject(context, new EditorActionDeclaration("build.rebuildAll", "Rebuild All", "Cook every asset again", "Build/Rebuild All", 101));
			d.Execute = new [=context] (page) => { context.RequestCook(true); };
			actions.Register(d);
		}
		// An asset page's: on its bar, and in Build's menu over the active page. Where the old
		// collision page had its own Cook now, every asset page has these.
		AddPageCook(actions, context, new .("build.cookPage", "Cook This Asset", "Save the page's changes, then cook its asset and what it needs", "Build/Cook This Asset", 200), cookPage);
		AddPageCook(actions, context, new .("build.rebuildPage", "Rebuild This Asset", "Save the page's changes, then cook its asset and what it needs again, changed or not", "Build/Rebuild This Asset", 201), rebuildPage);
	}

	/// Registers `d` running `cook` over the page, on while a project is open and the page shows
	/// an asset (a Game tab shows none). TAKES OWNERSHIP of both; with no hook, `d` is dropped.
	private static void AddPageCook(EditorActionRegistry actions, EditorContext context, EditorActionDeclaration d, PageHook cook)
	{
		if (cook == null)
		{
			delete d;
			return;
		}
		d.Enabled = new [=context] (page) => (context.Project != null) && (page != null) && !page.InstanceId.IsNil;
		d.DisabledReason = new [=context] (page, outReason) =>
			{
				if (context.Project == null)
					outReason.Append("Open a project first");
				else
					outReason.Append((page == null) ? "No page is active" : "This page shows no asset");
			};
		d.Execute = new [=cook] (page) =>
			{
				if (page != null)
					cook(page);
			} ~ delete cook;
		actions.Register(d);
	}

	/// Game's actions. TAKES OWNERSHIP of `run`.
	public static void RegisterGameActions(EditorActionRegistry actions, GameActions run)
	{
		defer delete run;
		let context = run.Context;
		Add(actions, NeedsProject(context, new EditorActionDeclaration("game.play", "Play", "Play the project in the Game page", "Game/Play", 100)), ref run.Play);
		Add(actions, NeedsProject(context, new EditorActionDeclaration("game.playNewInstance", "Play New Instance", "Play the project in a fresh Game page", "Game/Play New Instance", 101)), ref run.PlayNewInstance);
	}

	/// View's actions. TAKES OWNERSHIP of `run`.
	public static void RegisterViewActions(EditorActionRegistry actions, ViewActions run)
	{
		defer delete run;
		let context = run.Context;
		if (run.ResetLayout != null)
		{
			let d = new EditorActionDeclaration("view.resetLayout", "Reset Layout", "Reset the panel layout to the default", "View/Reset Layout", 100);
			let resetLayout = run.ResetLayout;
			run.ResetLayout = null;
			d.Execute = new [=resetLayout, =context] (page) =>
				{
					resetLayout();
					if (context != null)
						context.SetStatus("Layout reset to default.");
				} ~ delete resetLayout;
			actions.Register(d);
		}
		// The closable panels, each shown again where it belongs (or brought to the front) without
		// undoing the rest of the layout, as Reset Layout would. The Project panel cannot be closed.
		{
			let d = new EditorActionDeclaration("view.assets", "Assets", "Show the Assets panel", "View/Assets", 150);
			d.ReadOnly = true; // shows a panel; nothing in the project changes
			Add(actions, d, ref run.Assets);
		}
		{
			let d = new EditorActionDeclaration("view.console", "Console", "Show the Console panel", "View/Console", 160);
			d.ReadOnly = true;
			Add(actions, d, ref run.Console);
		}
		{
			let d = new EditorActionDeclaration("view.profiler", "Profiler", "Show the Profiler page: record the editor process, open a player's capture", "View/Profiler", 210);
			d.ReadOnly = true; // shows a panel; nothing in the project changes
			Add(actions, d, ref run.Profiler);
		}
		if (run.ProfilerRecord != null)
		{
			let d = new EditorActionDeclaration("profiler.record", "Profiler Record", "Record the editor process in the Profiler page (every page, preview and Play-in-editor run), or stop", "View/Profiler Record", 211);
			d.Kind = .Toggle;
			d.ReadOnly = true; // the profiler's state, not the project's
			let recording = run.ProfilerRecording;
			run.ProfilerRecording = null;
			d.Checked = new [=recording] (page) => { return (recording != null) && recording(); } ~ delete recording;
			Add(actions, d, ref run.ProfilerRecord);
		}
		{
			let d = new EditorActionDeclaration("view.screenshot", "Screenshot Editor", "Write the editor's main window, as it looks now, to a PNG under <user-data>/screenshots", "View/Screenshot Editor", 300);
			d.Shortcut = EditorShortcut.Of("f12");
			d.ReadOnly = true; // a file outside the project; nothing in it changes
			Add(actions, d, ref run.Screenshot);
		}
		{
			let d = new EditorActionDeclaration("view.commandPalette", "Command Palette...", "Every action by name: type to filter, Enter runs it", "View/Command Palette...", 200);
			d.Shortcut = EditorShortcut.Of("ctrl-shift-p");
			d.ReadOnly = true; // the palette changes nothing itself
			Add(actions, d, ref run.CommandPalette);
		}
	}

	/// Help's actions. TAKES OWNERSHIP of `run`.
	public static void RegisterHelpActions(EditorActionRegistry actions, HelpActions run)
	{
		defer delete run;
		let d = new EditorActionDeclaration("help.about", "About", "The editor's version", "Help/About", 100);
		d.ReadOnly = true;
		Add(actions, d, ref run.About);
	}
}
