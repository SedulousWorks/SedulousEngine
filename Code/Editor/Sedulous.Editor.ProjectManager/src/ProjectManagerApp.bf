using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.GUI;
using Sedulous.Http.Client;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.ProjectManager;

/// What a ProjectManagerApp works over. The registry is borrowed; the delegates are its own.
class ProjectManagerAppServices
{
	/// The user's recent projects: what the manager lists, and the open gate.
	public ProjectManagerController Projects = null;
	/// The window's GUI root (dialogs over it, the deferred work through its queue); null with no
	/// interface, and the manager then never shows. Owned.
	public delegate SceneRoot() Root ~ delete _;
	/// The shell's dialogs; null: none. Owned.
	public delegate IDialogService() Dialogs ~ delete _;
	/// Shows the manager's screen over the window; null takes it away. Owned.
	public delegate void(Node screen) ShowScreen ~ delete _;
	/// A frame's markup by its path: a node with one reference, the caller's. Owned.
	public delegate Node(StringView path) LoadMarkup ~ delete _;
	/// The recent list or its layout changed: the store is saved. Owned.
	public delegate void() StoreChanged ~ delete _;
	/// The Samples tab's client, made on first use and outliving the manager; null: none. Owned.
	public delegate IHttpClient() Http ~ delete _;
	/// Where a file of the release is fetched from; null: the release's own URL. Owned.
	public delegate void(StringView file, String outUrl) ReleaseFile ~ delete _;
	/// The manager opens on its Samples tab (a run pointed at release files is there to try it).
	public bool OpenOnSamples = false;
	/// Told each time the manager shows. Owned.
	public delegate void() Shown ~ delete _;
	/// The engine version the project in the folder is to open with (the SDK picked for it) into
	/// `outVersion`, which the gate compares its stamp with; false, with why for the status line in
	/// `outWhy`, when there is none to open it with. Null: this engine's own. Owned.
	public delegate bool(StringView directory, String outVersion, String outWhy) EngineFor ~ delete _;
	/// Opens the project in the folder, the gate passed: true when it opened, or its opening has
	/// started; else why for the status line in `outWhy` (empty: the log says). `restamp`: the user
	/// chose to open an older engine's project with this one, which stamps it. Owned.
	public delegate bool(StringView directory, bool restamp, String outWhy) OpenProject ~ delete _;
	/// Makes the project named `name` in the folder (its parent made, the folder not a project)
	/// and opens it: true when it did; else why in `outWhy` (empty: the folder could not be made
	/// into a project). Owned.
	public delegate bool(StringView directory, StringView name, String outWhy) CreateProject ~ delete _;
	/// The manager stays shown while a project opens, and its status line says how an open that
	/// failed failed: the manager's program, which builds the project's editor under it. False: it
	/// goes before the open, as the editor's frame takes the window, and comes back when the open
	/// fails.
	public bool StaysWhileOpening = false;
}

/// The project manager's behaviour over a window: the manager shown (made the first time, its
/// list probed again after), and what its actions start. Opening a project saved by an engine
/// other than the one it is to open with (EngineFor; this engine when the host names none) asks
/// first: a newer engine's Open Anyway; an older engine's Back Up and Open, or Open Without
/// Backup, either stamping the project with the engine that opens it. New Project refuses a folder
/// that holds a project already, then has the project made and opened. What opening and making
/// are is the host's (OpenProject, CreateProject): the editor opens a session in its own window,
/// the manager's program builds the project's own editor and launches it.
///
/// A headless test drives it over a GUI of its own. What a click asks for runs at the GUI's next
/// drain, never inside the click (the screen it swaps takes away the button that was clicked); at
/// once with no GUI.
class ProjectManagerApp
{
	private ProjectManagerAppServices mServices ~ delete _;
	private ProjectManagerView mView = null ~ delete _;
	/// The other engine's question, a reference of ours while it is the last one asked.
	private Sedulous.GUI.MessageBox mAsking = null ~ _?.ReleaseRef();

	/// TAKES OWNERSHIP of the services.
	public this(ProjectManagerAppServices services)
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

	/// The registry the manager lists.
	public ProjectManagerController Projects => mServices.Projects;

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
			if (mServices.ReleaseFile != null)
				services.ReleaseFile = new (file, outUrl) => { mServices.ReleaseFile(file, outUrl); };
			mView = new ProjectManagerView(services, LoadMarkup(ProjectManagerView.cMarkupPath));
			if (mServices.OpenOnSamples)
				mView.ShowSamples(true);
		}
		else
			mView.Rebuild(); // back from a project: probed again
		mView.SetStatus("");
		ShowScreen(mView.Content);
		mView.Shown();
		if (mServices.Shown != null)
			mServices.Shown();
	}

	/// Once a frame: the Samples tab's fetches and downloads.
	public void Tick()
	{
		if (mView != null)
			mView.Tick();
	}

	/// Opens the project in `directory` from the manager: the engine it opens with picked
	/// (EngineFor), then one saved by another engine version asks first (the controller decides and
	/// words it against that engine; a backup of its manifest is offered for an older one).
	public void OpenFrom(StringView directory)
	{
		let decision = scope ProjectOpenDecision();
		let engine = scope String(EngineVersion.String);
		if ((mServices.EngineFor != null) && (ProjectHeader.Read(directory, decision.Header) case .Ok))
		{
			let why = scope String();
			engine.Clear();
			if (!mServices.EngineFor(directory, engine, why))
			{
				SetStatus(why);
				return;
			}
		}
		mServices.Projects.DecideOpen(directory, engine, decision);
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
	/// project is made there (its location too, when that is new) and opened.
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
		if (!mServices.StaysWhileOpening)
			ShowScreen(null);
		let why = scope String();
		if ((mServices.CreateProject != null) && mServices.CreateProject(directory, name, why))
			return;
		if (!mServices.StaysWhileOpening)
			Enter();
		SetStatus(why.IsEmpty ? "The project could not be made there (is the folder writable?)." : why);
	}

	/// The project opened, the manager's screen away first unless it stays (StaysWhileOpening); on
	/// failure the manager again, saying why.
	public bool OpenProject(StringView directory, bool restamp = false)
	{
		if (!mServices.StaysWhileOpening)
			ShowScreen(null);
		let why = scope String();
		if ((mServices.OpenProject != null) && mServices.OpenProject(directory, restamp, why))
			return true;
		if (!mServices.StaysWhileOpening)
			Enter();
		if (why.IsEmpty)
			why.AppendF("The project in {} did not open (see the log).", directory);
		SetStatus(why);
		return false;
	}

	/// The status line under the manager.
	public void SetStatus(StringView text)
	{
		if (mView != null)
			mView.SetStatus(text);
	}

	/// `work` at the GUI's next drain; at once with no GUI. TAKES OWNERSHIP of `work`.
	public void Later(delegate void() work)
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

	private SceneRoot Root => (mServices.Root != null) ? mServices.Root() : null;

	private Node LoadMarkup(StringView path) => (mServices.LoadMarkup != null) ? mServices.LoadMarkup(path) : null;

	private void ShowScreen(Node screen)
	{
		if (mServices.ShowScreen != null)
			mServices.ShowScreen(screen);
	}

	/// The other engine's question answered: Cancel (or a close) stays; the others open at the next
	/// drain, Back Up and Open backing the manifest up first (not opening when that fails). An
	/// older engine's project is stamped by what opens it; a newer engine's keeps its stamp.
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
				OpenProject(path, restamp);
			} ~ delete path);
	}
}
