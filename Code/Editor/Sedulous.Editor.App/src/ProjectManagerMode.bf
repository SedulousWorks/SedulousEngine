using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.GUI;
using Sedulous.Http.Client;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

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
}

/// The project manager's part of the application (Raptor's editor-gui spec, 5.1, layer 13): the
/// manager over the window while no project is open (made the first time, its list probed again
/// after), and what its actions start. Opening a project another engine saved asks first, as
/// before: a newer engine's Open Anyway; an older engine's Back Up and Open, or Open Without Backup,
/// either stamping the project with this engine at once. New Project makes the project in the
/// folder chosen with the starter content, then opens it. Close Project asks about the unsaved
/// pages, then closes the project and shows the manager again.
///
/// Raptor keeps this in the application; here it is a part of its own, as the session and the
/// pages are, so a headless test drives it over a GUI of its own. What a click asks for runs at
/// the GUI's next drain, never inside the click (the screen it swaps takes away the button that was
/// clicked); at once with no GUI.
class ProjectManagerMode
{
	private ProjectManagerModeServices mServices ~ delete _;
	private ProjectManagerView mView = null ~ delete _;
	/// The other engine's question, a reference of ours while it is the last one asked.
	private Sedulous.GUI.MessageBox mAsking = null ~ _?.ReleaseRef();

	/// TAKES OWNERSHIP of the services.
	public this(ProjectManagerModeServices services)
	{
		mServices = services;
	}

	public ~this()
	{
		// An open question would answer into a gone part: it goes unanswered.
		if ((mAsking != null) && mAsking.IsOpen)
			mAsking.Close();
	}

	/// The manager; null until it first shows.
	public ProjectManagerView View => mView;

	/// The manager over the whole window: made the first time, its projects probed again after,
	/// its status line cleared. Nothing with no interface.
	public void Enter()
	{
		if (Root == null)
			return;
		if (mView == null)
		{
			let services = new ProjectManagerServices();
			services.Controller = mServices.Projects;
			services.Dialogs = (mServices.Dialogs != null) ? mServices.Dialogs() : null;
			services.Open = new (directory) =>
				{
					let path = new String(directory);
					Later(new [=this, =path] () => { OpenFrom(path); } ~ delete path);
				};
			services.Create = new (directory, name) =>
				{
					let path = new String(directory);
					let projectName = new String(name);
					Later(new [=this, =path, =projectName] () => { CreateFrom(path, projectName); } ~ { delete path; delete projectName; });
				};
			services.StoreChanged = new () =>
				{
					if (mServices.StoreChanged != null)
						mServices.StoreChanged();
				};
			services.LoadMarkup = new (path) => LoadMarkup(path);
			services.Http = (mServices.Http != null) ? mServices.Http() : null;
			mView = new ProjectManagerView(services, LoadMarkup(ProjectManagerView.cMarkupPath));
		}
		else
			mView.Rebuild(); // back from a project: probed again
		mView.SetStatus("");
		ShowScreen(mView.Content);
		mView.Shown();
	}

	/// Once a frame: the Samples tab's fetches and downloads, which go on while a project is open.
	public void Tick()
	{
		if (mView != null)
			mView.Tick();
	}

	/// Opens the project in `directory` from the manager: one saved by another engine version asks
	/// first (the controller decides and words it; a backup of its manifest is offered for an older
	/// one).
	public void OpenFrom(StringView directory)
	{
		let decision = scope ProjectOpenDecision();
		mServices.Projects.DecideOpen(directory, decision);
		if (decision.Gate == .NotAProject)
		{
			SetStatus("Not a project (no Project.xml there).");
			return;
		}
		if (decision.Gate == .OpenDirectly)
		{
			OpenProject(directory);
			return;
		}
		let root = Root;
		if ((root == null) || ((mAsking != null) && mAsking.IsOpen))
			return;
		if (mAsking != null)
			mAsking.ReleaseRef();
		let question = new Sedulous.GUI.MessageBox();
		mAsking = question;
		question.Configure(decision.PromptTitle, decision.PromptBody, .Ok);
		question.ClearButtons();
		question.AddButton("Cancel", "cancel", .Cancel);
		if (decision.Gate == .PromptNewerEngine)
			question.AddButton("Open Anyway", "open", .Normal);
		else // an older engine's: its manifest backed up first, or not
		{
			question.AddButton("Open Without Backup", "open", .Normal);
			// "and", not "&": a button's & marks its access key.
			question.AddButton("Back Up and Open", "backup", .Primary);
		}
		let path = new String(directory);
		let gate = decision.Gate;
		question.AddEventListener(.Changed, new [=question, =path, =gate, =this] (e) => { Answered(gate, question.ResultName, path); } ~ delete path);
		question.OpenModal(root);
	}

	/// New Project from the manager: a folder that holds a project already is refused; else the
	/// project is made there (its location too, when that is new) with the starter content and
	/// opened.
	public void CreateFrom(StringView directory, StringView name)
	{
		let probed = scope ProjectSettings();
		if (ProjectRegistry.ProbeProject(directory, probed) case .Ok)
		{
			SetStatus("That folder is a project already: Open Folder opens it.");
			return;
		}
		// New Project's check said a location that does not exist yet is made: the project's own
		// folder's parent first (CreateDirectory makes the folders on the way).
		CreateDirectory(PathParent(directory, .. scope .()));
		var options = EditorSessionOpenOptions();
		options.Scaffold = true;
		options.ScaffoldName = name;
		options.Seed = true;
		ShowScreen(null);
		if (!mServices.Session.Open(directory, options))
		{
			Enter();
			SetStatus("The project could not be made there (is the folder writable?).");
		}
	}

	/// The frame back and the project open; on failure the manager again, saying so.
	public bool OpenProject(StringView directory)
	{
		ShowScreen(null);
		if (mServices.Session.Open(directory))
			return true;
		Enter();
		SetStatus(scope $"The project in {directory} did not open (see the log).");
		return false;
	}

	/// File > Close Project: the unsaved pages asked about, then the project closed and the
	/// manager shown. Nothing with no project open.
	public void CloseProject()
	{
		if (mServices.Session.Project == null)
			return;
		mServices.Pages.ConfirmUnsavedThen("Save All and Close", "Close Without Saving", new () =>
			{
				Later(new () =>
					{
						mServices.Session.Close();
						Enter();
					});
			});
	}

	private SceneRoot Root => (mServices.Root != null) ? mServices.Root() : null;

	private Node LoadMarkup(StringView path) => (mServices.LoadMarkup != null) ? mServices.LoadMarkup(path) : null;

	private void ShowScreen(Node screen)
	{
		if (mServices.ShowScreen != null)
			mServices.ShowScreen(screen);
	}

	private void SetStatus(StringView text)
	{
		if (mView != null)
			mView.SetStatus(text);
	}

	/// `work` at the GUI's next drain; at once with no GUI. TAKES OWNERSHIP of `work`.
	private void Later(delegate void() work)
	{
		let root = Root;
		let queue = (root != null) ? root.MutationQueue : null;
		if (queue == null)
		{
			defer delete work;
			work();
			return;
		}
		queue.Enqueue(work);
	}

	/// The other engine's question answered: Cancel (or a close) stays; the others open at the next
	/// drain, Back Up and Open backing the manifest up first (not opening when that fails). An
	/// older engine's project is stamped with this engine at once; a newer engine's keeps its stamp.
	private void Answered(ProjectOpenGate gate, StringView answer, StringView directory)
	{
		if ((answer != "open") && (answer != "backup"))
			return;
		let path = new String(directory);
		let backup = answer == "backup";
		let restamp = ProjectManagerController.RestampsOnOpen(gate);
		Later(new [=this, =path, =backup, =restamp] () =>
			{
				if (backup && (mServices.Projects.BackupManifest(path, scope .()) case .Err))
				{
					SetStatus("The backup FAILED: not opening.");
					return;
				}
				if (OpenProject(path) && restamp && (mServices.Session.Project != null))
					mServices.Session.Project.SaveSettings().IgnoreError(); // stamped with this engine at once
			} ~ delete path);
	}
}
