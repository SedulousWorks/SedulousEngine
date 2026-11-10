using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.GUI;
using Sedulous.Http.Client;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.ProjectManager;

namespace Sedulous.Editor.App;

/// What a ProjectManagerMode works over. The registry, the session and the pages are borrowed;
/// the delegates are its own.
class ProjectManagerModeServices
{
	/// The user's recent projects: what the manager lists, and the open gate.
	public ProjectManagerController Projects = null;
	/// The project the editor has open: opened, made and closed here.
	public EditorSession Session = null;
	/// The pages, asked about their unsaved changes before the project closes.
	public EditorPages Pages = null;
	/// The window's GUI root (dialogs over it, the deferred work through its queue); null with no
	/// interface, and the manager then never shows. Owned.
	public delegate SceneRoot() Root ~ delete _;
	/// The shell's dialogs; null: none. Owned.
	public delegate IDialogService() Dialogs ~ delete _;
	/// Shows a screen over the window in place of the frame; null puts the frame back. Owned.
	public delegate void(Node screen) ShowScreen ~ delete _;
	/// A frame's markup by its path: a node with one reference, the caller's. Owned.
	public delegate Node(StringView path) LoadMarkup ~ delete _;
	/// The recent list or its layout changed: the user's settings are saved. Owned.
	public delegate void() StoreChanged ~ delete _;
	/// The Samples tab's client, made on first use and outliving the manager; null: none. Owned.
	public delegate IHttpClient() Http ~ delete _;
	/// Where a file of this editor's release is fetched from; null: the release's own URL. Owned.
	public delegate void(StringView file, String outUrl) ReleaseFile ~ delete _;
	/// The manager opens on its Samples tab (a run pointed at release files is there to try it).
	public bool OpenOnSamples = false;
	/// Told each time the manager shows (the editor's MCP host serves it then). Owned.
	public delegate void() Shown ~ delete _;
}

/// The project manager's part of the application, over the manager's own behaviour
/// (ProjectManagerApp): the manager over the window while no project is open, its Open opening the
/// project in this editor's session and its New Project making the project there with the starter
/// content. Close Project asks about the unsaved pages, then closes the project and shows the
/// manager again.
class ProjectManagerMode
{
	private ProjectManagerModeServices mServices ~ delete _;
	private ProjectManagerApp mApp = null;

	/// TAKES OWNERSHIP of the services.
	public this(ProjectManagerModeServices services)
	{
		mServices = services;
		let app = new ProjectManagerAppServices();
		app.Projects = services.Projects;
		app.Root = new () => Root;
		app.Dialogs = new () => (mServices.Dialogs != null) ? mServices.Dialogs() : null;
		app.ShowScreen = new (screen) =>
			{
				if (mServices.ShowScreen != null)
					mServices.ShowScreen(screen);
			};
		app.LoadMarkup = new (path) => (mServices.LoadMarkup != null) ? mServices.LoadMarkup(path) : null;
		app.StoreChanged = new () =>
			{
				if (mServices.StoreChanged != null)
					mServices.StoreChanged();
			};
		if (services.Http != null)
			app.Http = new () => mServices.Http();
		if (services.ReleaseFile != null)
			app.ReleaseFile = new (file, outUrl) => { mServices.ReleaseFile(file, outUrl); };
		app.OpenOnSamples = services.OpenOnSamples;
		app.Shown = new () =>
			{
				if (mServices.Shown != null)
					mServices.Shown();
			};
		app.OpenProject = new (directory, restamp, outWhy) => OpenInSession(directory, restamp);
		app.CreateProject = new (directory, name, outWhy) => CreateInSession(directory, name);
		mApp = new ProjectManagerApp(app);
	}

	public ~this()
	{
		// The manager first: it reaches the services.
		DeleteAndNullify!(mApp);
	}

	/// The manager; null until it first shows.
	public ProjectManagerView View => mApp.View;

	/// The manager over the whole window: made the first time, its projects probed again after,
	/// its status line cleared. Nothing with no interface.
	public void Enter() => mApp.Enter();

	/// Once a frame: the Samples tab's fetches and downloads, which go on while a project is open.
	public void Tick() => mApp.Tick();

	/// Opens the project in `directory` from the manager: one saved by another engine version asks
	/// first.
	public void OpenFrom(StringView directory) => mApp.OpenFrom(directory);

	/// New Project from the manager: a folder that holds a project already is refused; else the
	/// project is made there with the starter content and opened.
	public void CreateFrom(StringView directory, StringView name) => mApp.CreateFrom(directory, name);

	/// The frame back and the project open; on failure the manager again, saying so.
	public bool OpenProject(StringView directory) => mApp.OpenProject(directory);

	/// File > Close Project: the unsaved pages asked about, then the project closed and the
	/// manager shown. Nothing with no project open.
	public void CloseProject()
	{
		if (mServices.Session.Project == null)
			return;
		mServices.Pages.ConfirmUnsavedThen("Save All and Close", "Close Without Saving", new () =>
			{
				mApp.Later(new () =>
					{
						mServices.Session.Close();
						Enter();
					});
			});
	}

	private SceneRoot Root => (mServices.Root != null) ? mServices.Root() : null;

	/// The session opens the project; an older engine's, opened with this one, is stamped with it
	/// at once.
	private bool OpenInSession(StringView directory, bool restamp)
	{
		var options = EditorSessionOpenOptions();
		options.Restamp = restamp;
		return mServices.Session.Open(directory, options);
	}

	/// The session scaffolds the project in `directory` with the starter content and opens it.
	private bool CreateInSession(StringView directory, StringView name)
	{
		var options = EditorSessionOpenOptions();
		options.Scaffold = true;
		options.ScaffoldName = name;
		options.Seed = true;
		return mServices.Session.Open(directory, options);
	}
}
