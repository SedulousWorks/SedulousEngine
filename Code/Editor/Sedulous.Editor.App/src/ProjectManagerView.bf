using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.Image.IO;
using Sedulous.GUI;
using Sedulous.Http.Client;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

// ProjectManagerView: the project manager (Raptor's project-manager spec), the window's whole screen
// at startup with no project given, and after File > Close Project. Its frame is markup
// (Data/Editor/ProjectManager.xml): a header with the Projects and Samples tabs; on Projects a
// toolbar (New Project, Open Folder, a search, the sort, list or grid) over the projects as rows or
// as tiles, and under them the missing ones, each with Locate... and Remove from list; on Samples
// the sample games of this editor's release, each with its Download...; a footer with the status
// and the keys. With no projects at all, a welcome stands in for the lists.
//
// There is no selection: an action is one click on the project it is for. A focus ring that Up and
// Down move marks the project Enter opens and Del takes off the list. Each project is probed when the
// list is rebuilt; a search or a sort only arranges what was probed.
//
// Everything with consequences for the project goes through the services the application binds:
// opening (the application runs the version check), creating, and saving the list after a change.
// A change to the list it shows is made again at the GUI's next drain, never inside the click that
// asked (the clicked button is in what goes).

/// What a ProjectManagerView works over. The controller and the dialogs are borrowed; the
/// delegates are its own.
class ProjectManagerServices
{
	/// The user's recent projects and the list's layout; null: nothing to show.
	public ProjectManagerController Controller = null;
	/// The shell's dialogs; null: no folder or file dialogs, and Show in Folder does nothing.
	public IDialogService Dialogs = null;
	/// Opens the project in this folder (the application checks its engine first). Owned.
	public delegate void(StringView directory) Open ~ delete _;
	/// Makes a project named `name` in `directory`, then opens it. Owned.
	public delegate void(StringView directory, StringView name) Create ~ delete _;
	/// The recent list or its layout changed: the store is saved. Owned.
	public delegate void() StoreChanged ~ delete _;
	/// A dialog's markup by its path (New Project's): a node with one reference, the caller's.
	/// Owned.
	public delegate Node(StringView path) LoadMarkup ~ delete _;
	/// The Samples tab's client, BORROWED (null: the tab says the samples could not be fetched). It must
	/// outlive the view, which pumps it in Tick.
	public IHttpClient Http = null;
	/// Where a file of this editor's release is fetched from (null: the release's own URL,
	/// EngineVersion.ReleaseDownloadUrl); tests point it at a loopback server. Owned.
	public delegate void(StringView file, String outUrl) ReleaseFile ~ delete _;
}

class ProjectManagerView
{
	/// Its frames, under the data root.
	public const String cMarkupPath = "Editor/ProjectManager.xml";
	public const String cNewProjectPath = "Editor/NewProject.xml";
	public const String cDownloadSamplePath = "Editor/DownloadSample.xml";
	private const float cDialogWidth = 600.0f;
	/// The heights the dialogs open at; their content's height replaces them at the first layout.
	private const float cDialogHeight = 250.0f;
	private const float cDownloadDialogHeight = 200.0f;
	/// The buttons that make a project and open a folder: the toolbar's and the welcome's.
	private static StringView[2] cNewButtons = .("manager-new", "manager-welcome-new");
	private static StringView[2] cOpenButtons = .("manager-open", "manager-welcome-open");

	/// A listed project as the last probe found it.
	private class Probe
	{
		public String Path = new .() ~ delete _;
		/// From its manifest, when found.
		public String Name = new .() ~ delete _;
		public String EngineVersion = new .() ~ delete _;
		public bool Found = false;
	}

	/// A project on the page, in the order the focus ring walks: the projects, then the missing.
	private class Listed
	{
		public String Path = new .() ~ delete _;
		public bool Missing = false;
	}

	/// What a row or a tile shows.
	private class Card
	{
		public String Path = new .() ~ delete _;
		public String Name = new .() ~ delete _;
		public String EngineVersion = new .() ~ delete _;
		/// "2 hours ago".
		public String Opened = new .() ~ delete _;
		/// Its exact time, for the tooltip.
		public String OpenedAt = new .() ~ delete _;
		public EngineVersionRelation Relation = .Same;
		public bool Favourite = false;
	}

	/// Where the Samples tab's list of samples stands.
	public enum CatalogState : uint8
	{
		NotFetched,
		Fetching,
		Loaded,
		/// The release has no samples.json (a build between releases).
		NotPublished,
		/// The release was not reached, or answered with nothing readable.
		Failed,
	}

	/// A sample's card on the Samples tab, while it shows.
	private class SampleCard
	{
		public String Folder = new .() ~ delete _;
		/// While it downloads; the tree's.
		public Sedulous.GUI.ProgressBar Bar = null;
		public Sedulous.GUI.Label Stage = null;
	}

	private ProjectManagerServices mServices ~ delete _;
	/// What the pictures show: declared before the content, so they outlive it.
	private List<Sedulous.Image.Image> mPictures = new .() ~ DeleteContainerAndItems!(_);
	/// Each sample's picture, by the catalog's order; null until it arrives. Before the content too.
	private List<Sedulous.Image.Image> mSamplePictures = new .() ~ DeleteContainerAndItems!(_);
	/// A reference of ours; the window showing it takes its own.
	private Node mContent ~ _?.ReleaseRef();
	/// New Project, a reference of ours while it is the last one made.
	private Sedulous.GUI.Window mDialog = null ~ _?.ReleaseRef();
	/// A project's menu, a reference of ours while it is the last one made.
	private Sedulous.GUI.Menu mMenu = null ~ _?.ReleaseRef();
	/// Every listed project, as the last rebuild found it.
	private List<Probe> mProbes = new .() ~ DeleteContainerAndItems!(_);
	/// The projects on the page, in the ring's order.
	private List<Listed> mShown = new .() ~ DeleteContainerAndItems!(_);
	/// Their rows or tiles, in the same order: the tree's.
	private List<Node> mRows = new .() ~ delete _;
	/// Shown as ~ in a folder.
	private String mHome = new .() ~ delete _;
	private String mQuery = new .() ~ delete _;
	private String mStatus = new .() ~ delete _;
	private String mFocusPath = new .() ~ delete _;
	private int mFocus = 0;
	private bool mProblem = false;
	private bool mSamples = false;
	/// The page's keys, on the content.
	private uint32 mKeyListener = 0;
	// The Samples tab.
	private CatalogState mCatalogState = .NotFetched;
	private SampleCatalog mCatalog = new .() ~ delete _;
	private String mCatalogError = new .() ~ delete _;
	private uint64 mCatalogRequest = 0;
	private List<uint64> mPictureRequests = new .() ~ delete _;
	/// Under way, OWNED; each holds its callbacks, so it goes before the client.
	private List<SampleDownload> mDownloads = new .() ~ DeleteContainerAndItems!(_);
	private List<SampleCard> mSampleCards = new .() ~ DeleteContainerAndItems!(_);
	/// The sample the download dialog is for, while it is open.
	private SampleInfo mDialogSample = new .() ~ delete _;
	/// Where it goes, once Download is pressed.
	private String mDialogTarget = new .() ~ delete _;

	/// Where the download dialog is: choosing where, downloading, or how it ended.
	private enum DialogStage : uint8
	{
		Choosing,
		Downloading,
		Done,
		Failed,
		Cancelled,
	}

	/// The manager over `services`, its frame `content` (the markup's: its parts by id). TAKES
	/// OWNERSHIP of the services and of a reference to `content`; null shows nothing.
	public this(ProjectManagerServices services, Node content)
	{
		mServices = services;
		mContent = content;
		GetHomeDirectory(mHome);
		if (mContent == null)
			return;
		for (let id in cNewButtons)
			if (let create = Find<Sedulous.GUI.Button>(id))
				create.SetOnClick(new () => { ShowCreateDialog(); });
		for (let id in cOpenButtons)
			if (let open = Find<Sedulous.GUI.Button>(id))
				open.SetOnClick(new () => { BrowseAndOpen(); });
		if (let asList = Find<Sedulous.GUI.Button>("manager-list"))
			asList.SetOnClick(new () => { SetGridView(false); });
		if (let asGrid = Find<Sedulous.GUI.Button>("manager-grid"))
			asGrid.SetOnClick(new () => { SetGridView(true); });
		if (let projects = Find<Sedulous.GUI.Button>("manager-tab-projects"))
			projects.SetOnClick(new () => { ShowSamples(false); });
		if (let samples = Find<Sedulous.GUI.Button>("manager-tab-samples"))
			samples.SetOnClick(new () => { ShowSamples(true); });
		if (let removeMissing = Find<Sedulous.GUI.Button>("manager-remove-missing"))
			removeMissing.SetOnClick(new () => { RemoveMissing(); });
		if (let retry = Find<Sedulous.GUI.Button>("manager-samples-retry"))
			retry.SetOnClick(new () => { FetchCatalog(); });
		if (let intro = Find<Sedulous.GUI.Label>("manager-samples-intro"))
			intro.Text = scope $"Sample games made with this engine, for engine {EngineVersion.Display}. A sample you download becomes one of your projects.";
		if (let search = Find<Sedulous.GUI.TextField>("manager-search"))
			search.SetOnTextChanging(new (text) => { SetQuery(text); });
		if (let sort = Find<Sedulous.GUI.ComboBox>("manager-sort"))
		{
			if (mServices.Controller != null)
				sort.SelectedIndex = mServices.Controller.SortByName ? 1 : 0;
			sort.SetOnSelectionChanged(new (index) => { SetSortByName(index == 1); });
		}
		if (let engine = Find<Sedulous.GUI.Label>("manager-engine"))
			engine.Text = scope $"Editor {EngineVersion.Display}";
		// The scroller takes the focus when the page is clicked, so the keys reach the page.
		if (let scroll = Find<Node>("manager-scroll"))
			scroll.TabFocusable = true;
		// Capture: the page's keys come before the search field's (Up, Down and Enter move and
		// open, as in a palette).
		mKeyListener = mContent.AddEventListener(.KeyDown, new (e) =>
			{
				let key = (KeyEvent)e;
				if (HandleKey(key.KeyCode, key.Modifiers))
					e.Handled = true;
			}, true);
		Rebuild();
	}

	/// The content may outlive this: what of it calls back here goes first.
	public ~this()
	{
		// Open as it goes, New Project would make into nothing and the menu run on nothing.
		if ((mDialog != null) && mDialog.IsOpen)
			mDialog.Close();
		if ((mMenu != null) && mMenu.IsOpen)
			mMenu.Close();
		if (mContent != null)
		{
			mContent.RemoveEventListener(mKeyListener);
			Clear(Find<Node>("manager-projects"));
			Clear(Find<Node>("manager-missing-list"));
			Clear(Find<Node>("manager-samples")); // the cards before their pictures
		}
		if (mServices.Http != null)
		{
			if (mCatalogRequest != 0)
				mServices.Http.Cancel(mCatalogRequest);
			for (let id in mPictureRequests)
				mServices.Http.Cancel(id);
		}
		ClearAndDeleteItems(mDownloads); // each cancels itself and deletes what it wrote
	}

	/// Its frame. Ours: a caller that keeps it takes a reference.
	public Node Content => mContent;

	/// Called once the page is on screen: the list takes the keys.
	public void Shown()
	{
		let scroll = Find<Node>("manager-scroll");
		if ((scroll != null) && scroll.IsTreeVisible)
			scroll.RequestFocus();
	}

	/// The status line to a problem, in the warning colour (empty shows the idle hint).
	public void SetStatus(StringView text) => ShowStatus(text, true);

	/// The status line to what just happened, in the text colour.
	public void SetNote(StringView text) => ShowStatus(text, false);

	public StringView Status => mStatus;

	/// Probes every listed project, then lays the list out again.
	public void Rebuild()
	{
		ClearAndDeleteItems(mProbes);
		if (mServices.Controller != null)
		{
			for (let entry in mServices.Controller.Entries.Entries)
			{
				let probe = new Probe();
				probe.Path.Set(entry.Path);
				let probed = scope ProjectSettings();
				if (ProjectRegistry.ProbeProject(entry.Path, probed) case .Ok)
				{
					probe.Found = true;
					probe.Name.Set(probed.Name);
					probe.EngineVersion.Set(probed.EngineVersion);
				}
				mProbes.Add(probe);
			}
		}
		Populate();
	}

	/// The list's layout: a grid of the pictures, else rows (kept in the store).
	public bool IsGridView => (mServices.Controller != null) && mServices.Controller.GridView;

	public void SetGridView(bool grid)
	{
		if ((mServices.Controller == null) || (grid == mServices.Controller.GridView))
			return;
		mServices.Controller.SetGridView(grid);
		if (mServices.StoreChanged != null)
			mServices.StoreChanged();
		Later(false);
	}

	/// The order: by name, else by when each was last opened (kept in the store).
	public void SetSortByName(bool byName)
	{
		if ((mServices.Controller == null) || (byName == mServices.Controller.SortByName))
			return;
		mServices.Controller.SetSortByName(byName);
		if (mServices.StoreChanged != null)
			mServices.StoreChanged();
		Later(false);
	}

	/// Shows only the projects whose name or folder holds `query` (any case).
	public void SetQuery(StringView query)
	{
		mQuery.Set(query);
		Populate();
	}

	/// Pins a project to the top, or unpins it.
	public void SetFavourite(StringView path, bool favourite)
	{
		if ((mServices.Controller == null) || !mServices.Controller.SetFavourite(path, favourite))
			return;
		if (mServices.StoreChanged != null)
			mServices.StoreChanged();
		mFocusPath.Set(path); // the ring follows the project to its new place
		Later(false);
	}

	/// The Samples tab, else the Projects tab. The first visit fetches the release's samples.
	public void ShowSamples(bool samples)
	{
		mSamples = samples;
		if (samples && (mCatalogState == .NotFetched))
			FetchCatalog();
		Populate();
	}

	/// Once a frame: the HTTP client's answers, then the downloads under way (their bars, and what
	/// each that ended leaves: a project in the list, or a word in the status line).
	public void Tick()
	{
		if (mServices.Http != null)
			mServices.Http.Pump();
		bool ended = false;
		for (int i = mDownloads.Count - 1; i >= 0; i--)
		{
			let d = mDownloads[i];
			if (d.State == .Downloading)
				continue;
			Finished(d);
			mDownloads.RemoveAt(i);
			delete d;
			ended = true;
		}
		if (ended)
			Later(true);
		else
			ShowProgress();
	}

	public CatalogState SampleCatalogState => mCatalogState;
	public SampleCatalog Samples => mCatalog;

	/// The download of the sample in `folder`, while one is under way (null else).
	public SampleDownload DownloadOf(StringView folder)
	{
		for (let d in mDownloads)
		{
			if (d.Sample.Folder == folder)
				return d;
		}
		return null;
	}

	/// Whether a sample is already one of the user's projects (a listed project of its name).
	public bool InProjects(SampleInfo sample)
	{
		for (let probe in mProbes)
		{
			if (probe.Found && (probe.Name == sample.Name))
				return true;
		}
		return false;
	}

	/// Fetches the release's samples.json, then each sample's picture.
	public void FetchCatalog()
	{
		if (mServices.Http == null)
		{
			mCatalogState = .Failed;
			mCatalogError.Set("this editor has no network client");
			Populate();
			return;
		}
		if (mCatalogRequest != 0)
			mServices.Http.Cancel(mCatalogRequest);
		mCatalogState = .Fetching;
		let request = HttpClientRequest.Get(ReleaseFile("samples.json", .. scope .()));
		request.MaxResponseBytes = 1024 * 1024;
		mCatalogRequest = mServices.Http.Send(request, new (response) => { OnCatalog(response); });
		Populate();
	}

	/// A sample's download, in one window from start to end: where it goes (starting where the last
	/// project went, and whether it gets a folder of its name there; Download waits while the check
	/// line is red), its progress with Cancel, and how it ended, with Open for the new project or Try
	/// again. Closing it mid-way leaves the download going, its card showing it.
	public void ShowDownloadDialog(SampleInfo sample)
	{
		let root = (mContent != null) ? (mContent.RootNode as SceneRoot) : null;
		if ((root == null) || ((mDialog != null) && mDialog.IsOpen))
			return;
		let body = (mServices.LoadMarkup != null) ? mServices.LoadMarkup(cDownloadSamplePath) : null;
		if (body == null)
			return;
		defer body.ReleaseRef(); // the window holds its own
		let parent = body.FindElement("download-sample-parent") as Sedulous.GUI.TextField;
		let ownFolder = body.FindElement("download-sample-own-folder") as Sedulous.GUI.CheckBox;
		let line = body.FindElement("download-sample-check") as UIWidget;
		let icon = body.FindElement("download-sample-check-icon") as Sedulous.GUI.Image;
		let checkText = body.FindElement("download-sample-where") as Sedulous.GUI.Label;
		let size = body.FindElement("download-sample-size") as Sedulous.GUI.Label;
		let go = body.FindElement("download-sample-go") as Sedulous.GUI.Button;
		let browse = body.FindElement("download-sample-browse") as Sedulous.GUI.Button;
		let cancel = body.FindElement("download-sample-cancel") as Sedulous.GUI.Button;
		let close = body.FindElement("download-sample-close") as Sedulous.GUI.Button;
		let retry = body.FindElement("download-sample-retry") as Sedulous.GUI.Button;
		let open = body.FindElement("download-sample-open") as Sedulous.GUI.Button;
		if ((parent == null) || (go == null))
			return;

		if (sample != mDialogSample)
			mDialogSample.CopyFrom(sample);
		mDialogTarget.Clear();
		if (mDialog != null)
			mDialog.ReleaseRef();
		let dialog = new Sedulous.GUI.Window();
		mDialog = dialog;
		dialog.Title = scope $"Download {sample.Name}";
		dialog.Size = .(cDialogWidth, cDownloadDialogHeight);
		dialog.FitsHeightToContent = true; // each stage, and a check line that wraps
		dialog.Content.AddChild(body);
		if (ownFolder != null)
		{
			ownFolder.Text = scope $"Create a folder named {sample.Folder} in it";
			ownFolder.Checked = true;
		}
		if (size != null)
			size.Text = scope $"{ByteSizeText(sample.Size, .. scope .())} download";
		StringView last = (mServices.Controller != null) ? mServices.Controller.LastLocation : default;
		parent.Text = last.IsEmpty ? StringView(mHome) : last;
		parent.SetOnTextChanging(new [=this, =parent, =ownFolder, =line, =icon, =checkText, =go] (text) =>
			{
				RefreshDownload(parent, ownFolder, line, icon, checkText, go);
			});
		if (ownFolder != null)
		{
			ownFolder.SetOnToggled(new [=this, =parent, =ownFolder, =line, =icon, =checkText, =go] (on) =>
				{
					RefreshDownload(parent, ownFolder, line, icon, checkText, go);
				});
		}
		go.SetOnClick(new [=this, =parent, =ownFolder] () =>
			{
				let result = scope NewProjectCheck();
				CheckDownload(parent, ownFolder, result);
				if (result.Level == .Error)
					return;
				if (mServices.Controller != null)
				{
					mServices.Controller.SetLastLocation(parent.Text);
					if (mServices.StoreChanged != null)
						mServices.StoreChanged();
				}
				mDialogTarget.Set(result.Target);
				StartDownload(mDialogSample, result.Target);
				ShowDialogStage(.Downloading);
			});
		if (browse != null)
		{
			browse.SetOnClick(new [=this, =parent, =ownFolder, =line, =icon, =checkText, =go] () =>
				{
					if (mServices.Dialogs == null)
						return;
					mServices.Dialogs.ShowOpenFolder(new [=this, =parent, =ownFolder, =line, =icon, =checkText, =go] (paths) =>
						{
							if (paths.Length == 0)
								return; // cancelled
							parent.Text = paths[0]; // set from code: no edit reported, so refreshed here
							RefreshDownload(parent, ownFolder, line, icon, checkText, go);
						}, parent.Text, false, 0);
				});
		}
		if (cancel != null)
		{
			cancel.SetOnClick(new [=this, =dialog] () =>
				{
					// Choosing: the dialog goes. Downloading: the download stops, and the dialog
					// says so when Tick hears it.
					if (let d = DownloadOf(mDialogSample.Folder))
						d.Cancel();
					else
						dialog.Close();
				});
		}
		if (close != null)
			close.SetOnClick(new [=dialog] () => { dialog.Close(); });
		if (retry != null)
		{
			retry.SetOnClick(new [=this, =parent, =ownFolder, =line, =icon, =checkText, =go] () =>
				{
					ShowDialogStage(.Choosing);
					RefreshDownload(parent, ownFolder, line, icon, checkText, go);
				});
		}
		if (open != null)
		{
			open.SetOnClick(new [=this, =dialog] () =>
				{
					let target = scope String(mDialogTarget);
					dialog.Close();
					Open(target);
				});
		}
		RefreshDownload(parent, ownFolder, line, icon, checkText, go);
		dialog.OpenModal(root);
		ShowDialogStage(.Choosing); // once open: a closed window's stages are left alone
	}

	/// The download dialog's window while it is open (a test's); null with none.
	public Sedulous.GUI.Window DownloadDialog => CreateDialog;

	/// Starts `sample`'s download into `target` (the dialog's second half).
	public void StartDownload(SampleInfo sample, StringView target)
	{
		if ((mServices.Http == null) || (DownloadOf(sample.Folder) != null))
			return;
		let download = new SampleDownload(mServices.Http, sample, ReleaseFile(sample.Archive, .. scope .()), target);
		mDownloads.Add(download);
		download.Start();
		SetNote(scope $"Downloading {sample.Name}...");
		Later(false);
	}

	public bool IsShowingSamples => mSamples;

	/// Whether the first run's welcome stands in for the lists (no projects at all).
	public bool IsWelcome => !mSamples && mProbes.IsEmpty;

	/// The projects shown (missing ones too), and how many show their thumbnail (a test's).
	public int ShownCount => mShown.Count;
	public int ThumbnailCount => mPictures.Count;
	/// A project's menu while it is open (a test's); null with none.
	public Sedulous.GUI.Menu OpenMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	/// The folder of the project the focus ring is on (empty with none).
	public StringView FocusedPath => (mFocus < mShown.Count) ? StringView(mShown[mFocus].Path) : default;

	/// The page's keys: Ctrl+F searches, Ctrl+N is New Project, Ctrl+O is Open Folder; Up and Down
	/// move the focus ring, Enter opens its project (Locate... for a missing one), Del takes it off
	/// the list. A key the focused widget needs for itself (Enter on a button, Del in the search, the
	/// arrows in an open list) stays with it. True when it took the key.
	public bool HandleKey(uint32 keyCode, uint32 modifiers)
	{
		let code = (Sedulous.GUI.KeyCode)keyCode;
		if (modifiers == KeyModCtrl)
		{
			if ((code == .F) && !mSamples)
			{
				let search = Find<Sedulous.GUI.TextField>("manager-search");
				if ((search != null) && search.IsTreeVisible)
					search.RequestFocus();
				return true;
			}
			if (code == .N)
			{
				ShowCreateDialog();
				return true;
			}
			if (code == .O)
			{
				BrowseAndOpen();
				return true;
			}
			return false;
		}
		if ((modifiers != 0) || mSamples || mShown.IsEmpty)
			return false;
		let dispatcher = (mContent != null) ? mContent.EventDispatcher : null;
		let focus = (dispatcher != null) ? dispatcher.FocusNode : null;
		if ((code == .Down) || (code == .Up))
		{
			if (focus is Sedulous.GUI.ComboBox)
				return false;
			MoveFocus((code == .Down) ? 1 : -1);
			return true;
		}
		if ((code == .Return) || (code == .KeypadEnter))
		{
			if ((focus is ButtonBase) || (focus is Sedulous.GUI.ComboBox))
				return false;
			let shown = mShown[Math.Min(mFocus, mShown.Count - 1)];
			if (shown.Missing)
				BrowseAndLocate(shown.Path);
			else
				Open(shown.Path);
			return true;
		}
		if (code == .Delete)
		{
			if (focus is Sedulous.GUI.TextField)
				return false;
			Run(scope String(mShown[Math.Min(mFocus, mShown.Count - 1)].Path), "Remove from List");
			return true;
		}
		return false;
	}

	/// Moves the focus ring by `step` projects, stopping at the ends.
	public void MoveFocus(int step)
	{
		if (mShown.IsEmpty)
			return;
		SetFocusIndex(Math.Clamp(Math.Min(mFocus, mShown.Count - 1) + step, 0, mShown.Count - 1));
	}

	/// A folder dropped on the window: opens the project in it, or says it holds none. False when
	/// nothing was dropped.
	public bool OpenDropped(Span<StringView> paths)
	{
		if (paths.Length == 0)
			return false;
		let probed = scope ProjectSettings();
		if (ProjectRegistry.ProbeProject(paths[0], probed) case .Err)
		{
			let folder = PathFilename(paths[0], .. scope .());
			SetStatus(scope $"{folder} holds no Project.xml, so it is not a project. New Project makes one.");
			return true;
		}
		Open(paths[0]);
		return true;
	}

	/// Points a missing project at the folder it is in now (Locate...'s second half), and says so;
	/// a folder that holds no project is refused.
	public bool Locate(StringView from, StringView to)
	{
		if (mServices.Controller == null)
			return false;
		if (!mServices.Controller.Relocate(from, to))
		{
			SetStatus("That folder holds no Project.xml, or is listed already.");
			return false;
		}
		if (mServices.StoreChanged != null)
			mServices.StoreChanged();
		mFocusPath.Set(to);
		let shown = RecentProjects.ShortenHomePath(to, mHome, .. scope .());
		SetNote(scope $"Found it: the project is listed at {shown} now.");
		Later(true);
		return true;
	}

	/// Takes every missing project off the list. No files are touched.
	public void RemoveMissing()
	{
		if (mServices.Controller == null)
			return;
		let removed = mServices.Controller.RemoveMissing();
		if (removed == 0)
			return;
		if (mServices.StoreChanged != null)
			mServices.StoreChanged();
		if (removed == 1)
			SetNote("The missing project was taken off the list; no files were touched.");
		else
			SetNote(scope $"{removed} missing projects were taken off the list; no files were touched.");
		Later(true);
	}

	/// What a project's menu offers, appended.
	public static void MenuItemsFor(StringView path, List<StringView> outItems)
	{
		let missing = !FileExists(PathJoin(path, ProjectLayout.ManifestFile, .. scope .()));
		if (!missing)
			outItems.Add("Open");
		outItems.Add("Show in Folder");
		outItems.Add("Copy Path");
		if (!missing)
		{
			outItems.Add("Choose Thumbnail Image...");
			if (FileExists(EditorProject.ThumbnailPath(path, .. scope .())))
				outItems.Add("Clear Thumbnail");
		}
		outItems.Add("Remove from List");
	}

	/// Runs one of a project's menu items.
	public void Run(StringView path, StringView item)
	{
		if (item == "Open")
			Open(path);
		else if (item == "Show in Folder")
		{
			if (mServices.Dialogs != null)
				mServices.Dialogs.OpenPath(path);
		}
		else if (item == "Copy Path")
		{
			let dispatcher = (mContent != null) ? mContent.EventDispatcher : null;
			if ((dispatcher != null) && (dispatcher.Clipboard != null))
			{
				dispatcher.Clipboard.SetText(path);
				SetNote("Copied the project's path.");
			}
		}
		else if (item == "Choose Thumbnail Image...")
		{
			if (mServices.Dialogs == null)
				return;
			var images = FileFilter("Images", "png;jpg;jpeg;bmp;tga");
			let projectPath = new String(path);
			// The service consumes the callback once it answers.
			mServices.Dialogs.ShowOpenFile(new [=this, =projectPath] (paths) =>
				{
					if (paths.Length > 0) // none: cancelled
						SetThumbnailFromImage(projectPath, paths[0]);
				} ~ delete projectPath, .(&images, 1), "", false, 0);
		}
		else if (item == "Clear Thumbnail")
		{
			DeleteFile(EditorProject.ThumbnailPath(path, .. scope .()));
			Later(false);
		}
		else if (item == "Remove from List")
		{
			let name = NameOf(path, .. scope .());
			if ((mServices.Controller == null) || !mServices.Controller.Remove(path))
				return;
			if (mServices.StoreChanged != null)
				mServices.StoreChanged();
			SetNote(scope $"{name} was taken off the list; its files are untouched.");
			Later(true);
		}
	}

	/// `image` (any picture the editor reads) as the project's thumbnail, saved as a PNG in its
	/// editor folder. False, said in the status line, when it does not read or save.
	public bool SetThumbnailFromImage(StringView projectPath, StringView image)
	{
		let picture = scope Sedulous.Image.Image();
		if (ImageIO.LoadImage(image, picture) case .Err)
		{
			SetStatus("That image could not be read.");
			return false;
		}
		let target = EditorProject.ThumbnailPath(projectPath, .. scope .());
		CreateDirectory(PathParent(target, .. scope .()));
		if (ImageIO.SaveImage(picture, target, .PNG) case .Err)
		{
			SetStatus("The thumbnail could not be saved (an 8-bit image is needed).");
			return false;
		}
		Later(false);
		return true;
	}

	/// New Project: a name, the folder it is made in (starting where the last project went), and
	/// whether it gets a folder of its name there. The check line under them says what Create would
	/// do, and Create waits while it is red. Nothing with no GUI, no markup, or with it open already.
	public void ShowCreateDialog()
	{
		let root = (mContent != null) ? (mContent.RootNode as SceneRoot) : null;
		if ((root == null) || ((mDialog != null) && mDialog.IsOpen))
			return;
		let body = (mServices.LoadMarkup != null) ? mServices.LoadMarkup(cNewProjectPath) : null;
		if (body == null)
			return;
		defer body.ReleaseRef(); // the window holds its own
		let name = body.FindElement("new-project-name") as Sedulous.GUI.TextField;
		let parent = body.FindElement("new-project-parent") as Sedulous.GUI.TextField;
		let ownFolder = body.FindElement("new-project-own-folder") as Sedulous.GUI.CheckBox;
		let line = body.FindElement("new-project-check") as UIWidget;
		let icon = body.FindElement("new-project-check-icon") as Sedulous.GUI.Image;
		let target = body.FindElement("new-project-where") as Sedulous.GUI.Label;
		let create = body.FindElement("new-project-create") as Sedulous.GUI.Button;
		let browse = body.FindElement("new-project-browse") as Sedulous.GUI.Button;
		let cancel = body.FindElement("new-project-cancel") as Sedulous.GUI.Button;
		if ((name == null) || (parent == null) || (create == null))
			return;

		if (mDialog != null)
			mDialog.ReleaseRef();
		let dialog = new Sedulous.GUI.Window();
		mDialog = dialog;
		dialog.Title = "New Project";
		dialog.Size = .(cDialogWidth, cDialogHeight);
		dialog.FitsHeightToContent = true; // a check line that wraps grows it
		dialog.Content.AddChild(body);
		if (ownFolder != null)
			ownFolder.Checked = true;
		StringView last = (mServices.Controller != null) ? mServices.Controller.LastLocation : default;
		parent.Text = last.IsEmpty ? StringView(mHome) : last;
		// The check line, kept current: what Create would make, coloured by what it says.
		name.SetOnTextChanging(new [=this, =name, =parent, =ownFolder, =line, =icon, =target, =create] (text) =>
			{
				RefreshCreate(name, parent, ownFolder, line, icon, target, create);
			});
		parent.SetOnTextChanging(new [=this, =name, =parent, =ownFolder, =line, =icon, =target, =create] (text) =>
			{
				RefreshCreate(name, parent, ownFolder, line, icon, target, create);
			});
		if (ownFolder != null)
		{
			ownFolder.SetOnToggled(new [=this, =name, =parent, =ownFolder, =line, =icon, =target, =create] (on) =>
				{
					RefreshCreate(name, parent, ownFolder, line, icon, target, create);
				});
		}
		create.SetOnClick(new [=this, =dialog, =name, =parent, =ownFolder] () =>
			{
				let result = scope NewProjectCheck();
				CheckCreate(name, parent, ownFolder, result);
				if (result.Level == .Error)
					return;
				if (mServices.Controller != null)
				{
					mServices.Controller.SetLastLocation(parent.Text);
					if (mServices.StoreChanged != null)
						mServices.StoreChanged();
				}
				dialog.Close();
				if (mServices.Create != null)
					mServices.Create(result.Target, result.Name);
			});
		if (browse != null)
		{
			browse.SetOnClick(new [=this, =name, =parent, =ownFolder, =line, =icon, =target, =create] () =>
				{
					if (mServices.Dialogs == null)
						return;
					mServices.Dialogs.ShowOpenFolder(new [=this, =name, =parent, =ownFolder, =line, =icon, =target, =create] (paths) =>
						{
							if (paths.Length == 0)
								return; // cancelled
							parent.Text = paths[0]; // set from code: no edit reported, so refreshed here
							RefreshCreate(name, parent, ownFolder, line, icon, target, create);
						}, parent.Text, false, 0);
				});
		}
		if (cancel != null)
			cancel.SetOnClick(new [=dialog] () => { dialog.Close(); });
		RefreshCreate(name, parent, ownFolder, line, icon, target, create);
		dialog.OpenModal(root);
		name.FocusElement();
	}

	/// New Project's window while it is open (a test's); null with none.
	public Sedulous.GUI.Window CreateDialog => ((mDialog != null) && mDialog.IsOpen) ? mDialog : null;

	/// What Create would make of the fields as they stand (ProjectManagerController.CheckNewProject).
	private void CheckCreate(Sedulous.GUI.TextField name, Sedulous.GUI.TextField parent, Sedulous.GUI.CheckBox ownFolder,
		NewProjectCheck outCheck)
	{
		ProjectManagerController.CheckNewProject(name.Text, parent.Text, (ownFolder == null) || ownFolder.Checked, mHome, outCheck);
	}

	/// The check line again: its words, its colour and icon, and Create waiting while it is red.
	private void RefreshCreate(Sedulous.GUI.TextField name, Sedulous.GUI.TextField parent, Sedulous.GUI.CheckBox ownFolder,
		UIWidget line, Sedulous.GUI.Image icon, Sedulous.GUI.Label target, Sedulous.GUI.Button create)
	{
		let result = scope NewProjectCheck();
		CheckCreate(name, parent, ownFolder, result);
		ShowCheck(result, line, icon, target, create);
	}

	/// What Download would do with the fields as they stand: New Project's check, worded as a
	/// download.
	private void CheckDownload(Sedulous.GUI.TextField parent, Sedulous.GUI.CheckBox ownFolder, NewProjectCheck outCheck)
	{
		ProjectManagerController.CheckNewProject(mDialogSample.Folder, parent.Text, (ownFolder == null) || ownFolder.Checked, mHome, outCheck,
			.Download);
	}

	/// The download dialog's check line again.
	private void RefreshDownload(Sedulous.GUI.TextField parent, Sedulous.GUI.CheckBox ownFolder, UIWidget line, Sedulous.GUI.Image icon,
		Sedulous.GUI.Label checkText, Sedulous.GUI.Button go)
	{
		let result = scope NewProjectCheck();
		CheckDownload(parent, ownFolder, result);
		ShowCheck(result, line, icon, checkText, go);
	}

	/// Shows one stage of the download dialog: its panel and the buttons it offers. Nothing unless
	/// the download dialog is the one open.
	private void ShowDialogStage(DialogStage stage, StringView words = default)
	{
		if ((mDialog == null) || !mDialog.IsOpen)
			return;
		let body = mDialog.Content;
		if (body.FindElement("download-sample-choose") == null)
			return; // New Project's
		let ended = (stage == .Done) || (stage == .Failed) || (stage == .Cancelled);
		ShowPart(body, "download-sample-choose", stage == .Choosing);
		ShowPart(body, "download-sample-progress", stage == .Downloading);
		ShowPart(body, "download-sample-result", ended);
		ShowPart(body, "download-sample-go", stage == .Choosing);
		ShowPart(body, "download-sample-cancel", (stage == .Choosing) || (stage == .Downloading));
		ShowPart(body, "download-sample-close", ended);
		ShowPart(body, "download-sample-retry", stage == .Failed);
		ShowPart(body, "download-sample-open", stage == .Done);
		if (ended)
		{
			let line = body.FindElement("download-sample-result");
			SetClass(line, "error", stage == .Failed);
			SetClass(line, "warning", stage == .Cancelled);
			if (let text = body.FindElement("download-sample-result-text") as Sedulous.GUI.Label)
				text.Text = words;
			if (let icon = body.FindElement("download-sample-result-icon") as Sedulous.GUI.Image)
				icon.Source = (stage == .Done) ? "Editor/Icons/check.svg" : ((stage == .Failed) ? "Editor/Icons/error.svg" : "Editor/Icons/warning.svg");
		}
		if (stage == .Downloading)
			ShowProgress();
	}

	private static void ShowPart(Node body, StringView id, bool shown)
	{
		if (let part = body.FindElement(id))
			part.Displayed = shown;
	}

	/// A check line (New Project's, a download's): its words, its colour, its icon, and whether the
	/// dialog's button may go ahead.
	private static void ShowCheck(NewProjectCheck result, UIWidget line, Sedulous.GUI.Image icon, Sedulous.GUI.Label checkText,
		Sedulous.GUI.Button go)
	{
		go.Enabled = result.Level != .Error;
		if (checkText != null)
			checkText.Text = result.Message;
		SetClass(line, "warning", result.Level == .Warning);
		SetClass(line, "error", result.Level == .Error);
		if (icon != null)
			icon.Source = (result.Level == .Ok) ? "Editor/Icons/check.svg" : ((result.Level == .Warning) ? "Editor/Icons/warning.svg" : "Editor/Icons/error.svg");
	}

	/// Where `file` of this editor's release is fetched from.
	private void ReleaseFile(StringView file, String outUrl)
	{
		if (mServices.ReleaseFile != null)
			mServices.ReleaseFile(file, outUrl);
		else
			EngineVersion.ReleaseDownloadUrl(file, outUrl);
	}

	private void OnCatalog(HttpClientResponse response)
	{
		mCatalogRequest = 0;
		if (response.Ok && (response.Status == 404))
			mCatalogState = .NotPublished;
		else if (!response.Ok || (response.Status != 200))
		{
			mCatalogState = .Failed;
			mCatalogError.Clear();
			if (response.Ok)
				mCatalogError.AppendF("the release answered {}", response.Status);
			else
				mCatalogError.Append(response.Error);
		}
		else if (!SampleCatalog.Parse(response.BodyText, mCatalog, mCatalogError))
			mCatalogState = .Failed;
		else
		{
			mCatalogState = .Loaded;
			FetchPictures();
		}
		Later(false);
	}

	/// Each sample's picture, shown on its card as it arrives.
	private void FetchPictures()
	{
		Clear(Find<Node>("manager-samples")); // the cards before the pictures they show
		ClearAndDeleteItems(mSampleCards);
		for (let picture in mSamplePictures)
			delete picture;
		mSamplePictures.Clear();
		mPictureRequests.Clear();
		for (int i < mCatalog.Samples.Count)
		{
			mSamplePictures.Add(null);
			if (mCatalog.Samples[i].Picture.IsEmpty)
				continue;
			let request = HttpClientRequest.Get(ReleaseFile(mCatalog.Samples[i].Picture, .. scope .()));
			let index = i;
			mPictureRequests.Add(mServices.Http.Send(request, new [=this, =index] (response) =>
				{
					if (!response.Ok || (response.Status != 200) || (index >= mSamplePictures.Count))
						return;
					let image = new Sedulous.Image.Image();
					if (ImageIO.LoadImageFromMemory(response.Body, image) case .Err)
					{
						delete image;
						return;
					}
					delete mSamplePictures[index];
					mSamplePictures[index] = image;
					Later(false);
				}));
		}
	}

	/// What a finished download leaves: a project in the list, or why it did not.
	private void Finished(SampleDownload d)
	{
		let name = scope String(d.Sample.Name);
		// The dialog that started it, if it is still open, says how it ended too.
		let told = (mDialog != null) && mDialog.IsOpen && (mDialogSample.Folder == d.Sample.Folder);
		let words = scope String();
		DialogStage stage = .Failed;
		if (d.State == .Done)
		{
			let probed = scope ProjectSettings();
			if ((mServices.Controller != null) && (ProjectRegistry.ProbeProject(d.Target, probed) case .Ok))
			{
				mServices.Controller.NoteOpened(d.Target, probed.Name, probed.EngineVersion);
				if (mServices.StoreChanged != null)
					mServices.StoreChanged();
				words.AppendF("{} is in your projects, in {}.", name, RecentProjects.ShortenHomePath(d.Target, mHome, .. scope .()));
				stage = .Done;
				SetNote(words);
			}
			else
			{
				words.AppendF("{} downloaded, but holds no Project.xml.", name);
				SetStatus(words);
			}
		}
		else if (d.State == .Failed)
		{
			words.AppendF("{} did not download: {}.", name, d.Error);
			SetStatus(words);
		}
		else
		{
			words.AppendF("{}'s download was cancelled; nothing was kept.", name);
			stage = .Cancelled;
			SetNote(words);
		}
		if (told)
			ShowDialogStage(stage, words);
	}

	/// The bars and words of the downloads under way, without laying the page out again.
	private void ShowProgress()
	{
		if ((mDialog != null) && mDialog.IsOpen)
		{
			if (let d = DownloadOf(mDialogSample.Folder))
			{
				if (let bar = mDialog.Content.FindElement("download-sample-bar") as Sedulous.GUI.ProgressBar)
				{
					bar.Min = 0.0;
					bar.Max = 1.0;
					bar.Value = d.Progress;
				}
				if (let words = mDialog.Content.FindElement("download-sample-stage") as Sedulous.GUI.Label)
					words.Text = scope $"Downloading {ByteSizeText(d.Received, .. scope .())} of {ByteSizeText(d.Total, .. scope .())}";
			}
		}
		for (let card in mSampleCards)
		{
			let d = DownloadOf(card.Folder);
			if ((d == null) || (card.Bar == null))
				continue;
			card.Bar.Value = d.Progress;
			if (card.Stage != null)
				card.Stage.Text = scope $"Downloading {ByteSizeText(d.Received, .. scope .())} of {ByteSizeText(d.Total, .. scope .())}";
		}
	}

	/// The Samples tab: the cards, or where the list stands.
	private void PopulateSamples()
	{
		let grid = Find<Node>("manager-samples");
		Clear(grid);
		ClearAndDeleteItems(mSampleCards);
		let loaded = (mCatalogState == .Loaded) && !mCatalog.Samples.IsEmpty;
		if (let scroll = Find<Node>("manager-samples-scroll"))
			scroll.Displayed = loaded;
		if (let state = Find<Node>("manager-samples-state"))
			state.Displayed = !loaded;
		if (!loaded)
		{
			StringView title = "Fetching the samples...";
			let text = scope String();
			if (mCatalogState == .Failed)
			{
				title = "The samples could not be fetched";
				text.AppendF("The release was not reached: {}.", mCatalogError);
			}
			else if ((mCatalogState == .NotPublished) || (mCatalogState == .Loaded))
			{
				title = "No samples for this version yet";
				text.AppendF("Release {} has no samples published: they come with each release of the editor.", EngineVersion.Display);
			}
			if (let label = Find<Sedulous.GUI.Label>("manager-samples-state-title"))
				label.Text = title;
			if (let label = Find<Sedulous.GUI.Label>("manager-samples-state-text"))
				label.Text = text;
			if (let retry = Find<Node>("manager-samples-retry"))
				retry.Displayed = mCatalogState == .Failed;
			return;
		}
		if (grid != null)
		{
			for (int i < mCatalog.Samples.Count)
				Adopt(grid, SampleCardFor(i));
		}
		ShowProgress();
	}

	/// A sample's card: its picture, its name and size, its line, then Download... (with "In your
	/// projects" once it is one) or, while it downloads, the bar and Cancel. A node with one
	/// reference, the caller's.
	private Node SampleCardFor(int index)
	{
		let sample = mCatalog.Samples[index];
		let card = new Sedulous.GUI.Panel();
		card.AddClass("manager-sample");
		let image = (index < mSamplePictures.Count) ? mSamplePictures[index] : null;
		if (image != null)
		{
			let picture = new Sedulous.GUI.Image();
			picture.AddClass("manager-sample-picture");
			picture.Fit = .Cover;
			let drawable = new ImageDrawable(image);
			defer drawable.ReleaseRef(); // the picture takes its own
			picture.SetDrawable(drawable);
			Adopt(card, picture);
		}
		else
		{
			let blank = new Sedulous.GUI.Panel();
			blank.AddClass("manager-sample-picture");
			Adopt(card, blank);
		}
		let body = new Sedulous.GUI.Panel();
		body.AddClass("manager-sample-body");
		let title = new Sedulous.GUI.Panel();
		title.AddClass("manager-sample-title");
		Adopt(title, Text(sample.Name, "manager-sample-name"));
		Adopt(title, Text(ByteSizeText(sample.Size, .. scope .()), "manager-count"));
		Adopt(body, title);
		Adopt(body, Text(sample.Description, "manager-sample-text"));
		let entry = new SampleCard();
		entry.Folder.Set(sample.Folder);
		if (DownloadOf(sample.Folder) != null)
		{
			let progress = new Sedulous.GUI.Panel();
			progress.AddClass("manager-sample-progress");
			let bar = new Sedulous.GUI.ProgressBar();
			bar.Min = 0.0;
			bar.Max = 1.0;
			Adopt(progress, bar);
			let stage = new Sedulous.GUI.Panel();
			stage.AddClass("manager-sample-stage");
			let words = Text("Downloading", "");
			Adopt(stage, words);
			let cancel = new Sedulous.GUI.Button();
			cancel.AddClass("ghost");
			cancel.Text = "Cancel";
			let folder = new String(sample.Folder);
			cancel.SetOnClick(new [=this, =folder] () =>
				{
					if (let d = DownloadOf(folder))
						d.Cancel(); // Tick takes it off and says so
				} ~ delete folder);
			Adopt(stage, cancel);
			Adopt(progress, stage);
			Adopt(body, progress);
			entry.Bar = bar;
			entry.Stage = words;
		}
		else
		{
			let actions = new Sedulous.GUI.Panel();
			actions.AddClass("manager-sample-actions");
			let download = new Sedulous.GUI.Button();
			download.AddClasses("primary");
			download.Text = "Download...";
			download.Enabled = mServices.Http != null;
			download.SetOnClick(new [=this, =index] () =>
				{
					if (index < mCatalog.Samples.Count)
						ShowDownloadDialog(mCatalog.Samples[index]);
				});
			Adopt(actions, download);
			if (InProjects(sample))
				Adopt(actions, Text("In your projects", "manager-sample-have"));
			Adopt(body, actions);
		}
		Adopt(card, body);
		mSampleCards.Add(entry);
		return card;
	}

	/// The frame's part with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	private static void SetClass(Node node, StringView name, bool on)
	{
		if (let widget = node as UIWidget)
		{
			if (on)
				widget.AddClass(name);
			else
				widget.RemoveClass(name);
		}
	}

	/// Its children gone (the pictures they showed go after, with mPictures).
	private static void Clear(Node node)
	{
		if (node != null)
			node.RemoveAllChildren();
	}

	/// Adds `child` to `into`, the tree's reference taking the place of the one it was made with.
	private static void Adopt(Node into, Node child)
	{
		into.AddChild(child);
		child.ReleaseRef();
	}

	/// A label of `text` with the sheet's `classes`: a node with one reference, the caller's.
	private static Sedulous.GUI.Label Text(StringView text, StringView classes)
	{
		let label = new Sedulous.GUI.Label();
		label.AddClasses(classes);
		label.Text = text;
		return label;
	}

	/// At the GUI's next drain (the clicked button is in what a rebuild takes away), the projects
	/// probed again (`probe`) or only laid out again; at once in no GUI.
	private void Later(bool probe)
	{
		let queue = (mContent != null) ? mContent.MutationQueue : null;
		if (queue == null)
		{
			if (probe)
				Rebuild();
			else
				Populate();
			return;
		}
		queue.Enqueue(new [=this, =probe] () =>
			{
				if (probe)
					Rebuild();
				else
					Populate();
			});
	}

	private void ShowStatus(StringView text, bool problem)
	{
		mStatus.Set(text);
		mProblem = problem;
		let status = Find<Sedulous.GUI.Label>("manager-status");
		if (status == null)
			return;
		// Nothing to say: how to open a project, while there are some; the Samples tab says nothing
		// until something happens (its intro already names the engine the samples are for).
		let idle = text.IsEmpty;
		if (!idle)
			status.Text = text;
		else if (!mSamples && !mShown.IsEmpty)
			status.Text = "Double-click a project or press Enter to open it.";
		else
			status.Text = "";
		SetClass(status, "warning", problem && !idle);
	}

	private Probe ProbeOf(StringView path)
	{
		for (let probe in mProbes)
			if (probe.Path == path)
				return probe;
		return null;
	}

	/// The listed name of the project at `path`, else its folder's name.
	private void NameOf(StringView path, String outName)
	{
		if (mServices.Controller != null)
		{
			if (let entry = mServices.Controller.Entries.Find(path))
			{
				outName.Append(entry.Name);
				return;
			}
		}
		PathFilename(path, outName);
	}

	/// Lays the page out from the last probe: the tab, the welcome or the lists in their order, the
	/// counts, the focus ring.
	private void Populate()
	{
		if ((mContent == null) || (mServices.Controller == null))
			return;
		if (let projects = Find<Sedulous.GUI.Button>("manager-tab-projects"))
			projects.Checked = !mSamples;
		if (let samples = Find<Sedulous.GUI.Button>("manager-tab-samples"))
			samples.Checked = mSamples;
		let welcome = IsWelcome;
		if (let page = Find<Node>("manager-projects-page"))
			page.Displayed = !mSamples && !welcome;
		if (let page = Find<Node>("manager-samples-page"))
			page.Displayed = mSamples;
		if (mSamples)
			PopulateSamples();
		if (let page = Find<Node>("manager-welcome"))
			page.Displayed = welcome;
		if (let logo = Find<Node>("manager-logo"))
			logo.Displayed = !welcome; // the welcome shows it large
		let grid = mServices.Controller.GridView;
		if (let asList = Find<Sedulous.GUI.Button>("manager-list"))
			asList.Checked = !grid;
		if (let asGrid = Find<Sedulous.GUI.Button>("manager-grid"))
			asGrid.Checked = grid;

		let list = Find<Node>("manager-projects");
		let missingList = Find<Node>("manager-missing-list");
		Clear(list); // the pictures they showed go before their images
		Clear(missingList);
		ClearAndDeleteItems(mPictures);
		ClearAndDeleteItems(mShown);
		mRows.Clear();
		SetClass(list, "grid", grid);

		let now = GetUnixTime();
		let offset = GetLocalTimeOffset(now);
		let arranged = scope List<RecentProjectEntry>();
		RecentProjects.Arrange(mServices.Controller.Entries, mQuery, mServices.Controller.SortByName, arranged);
		int present = 0;
		for (let probe in mProbes)
			if (probe.Found)
				present++;
		let missing = scope List<RecentProjectEntry>();
		for (let entry in arranged)
		{
			let probe = ProbeOf(entry.Path);
			if ((probe == null) || !probe.Found)
			{
				missing.Add(entry);
				continue;
			}
			let card = scope Card();
			card.Path.Set(entry.Path);
			card.Name.Set(probe.Name.IsEmpty ? StringView(entry.Name) : StringView(probe.Name));
			card.EngineVersion.Set(probe.EngineVersion);
			card.Relation = ProjectRegistry.CompareProjectEngineVersion(probe.EngineVersion);
			RecentProjects.DescribeLastOpened(entry.LastOpened, now, offset, card.Opened);
			RecentProjects.DescribeTime(entry.LastOpened, offset, card.OpenedAt);
			card.Favourite = entry.Favourite;
			if (list != null)
				Adopt(list, grid ? Tile(card) : Row(card));
			AddShown(card.Path, false);
		}
		let matched = mShown.Count;
		for (let entry in missing)
		{
			if (missingList != null)
				Adopt(missingList, MissingRow(entry));
			AddShown(entry.Path, true);
		}

		if (let count = Find<Sedulous.GUI.Label>("manager-count"))
		{
			if (matched == present)
				count.Text = scope $"{present} project{(present == 1) ? "" : "s"}";
			else
				count.Text = scope $"{matched} of {present}";
		}
		if (let noMatch = Find<Sedulous.GUI.Label>("manager-no-match"))
		{
			noMatch.Displayed = !mQuery.IsEmpty && (matched == 0);
			noMatch.Text = scope $"No project matches \"{mQuery}\". Search looks at names and folders.";
		}
		if (let section = Find<Node>("manager-missing"))
			section.Displayed = !missing.IsEmpty;
		if (let missingCount = Find<Sedulous.GUI.Label>("manager-missing-count"))
			missingCount.Text = scope $"{missing.Count} · not found at the last known location"; // right for any count
		if (let keys = Find<Node>("manager-keys"))
			keys.Displayed = !mSamples && !welcome;

		// The ring stays on its project when that is still shown, else on the same place.
		var focus = Math.Min(mFocus, mShown.IsEmpty ? 0 : (mShown.Count - 1));
		for (int i < mShown.Count)
			if (mShown[i].Path == mFocusPath)
				focus = i;
		SetFocusIndex(focus);
		ShowStatus(scope String(mStatus), mProblem);
		// A rebuild removed the focused button: the list takes the keys again.
		let dispatcher = mContent.EventDispatcher;
		if ((dispatcher != null) && (dispatcher.FocusNode == null))
			Shown();
	}

	private void AddShown(StringView path, bool missing)
	{
		let shown = new Listed();
		shown.Path.Set(path);
		shown.Missing = missing;
		mShown.Add(shown);
	}

	private void SetFocusIndex(int index)
	{
		mFocus = index;
		if (index < mShown.Count)
			mFocusPath.Set(mShown[index].Path);
		else
			mFocusPath.Clear();
		for (int i < mRows.Count)
			SetClass(mRows[i], "focused", i == index);
		if (index < mRows.Count)
		{
			let scroll = Find<Node>("manager-scroll");
			if ((scroll != null) && IsInTree(mRows[index], scroll))
				scroll.ScrollIntoView(mRows[index]);
		}
	}

	private static bool IsInTree(Node node, Node ancestor)
	{
		for (var n = node; n != null; n = n.Parent)
			if (n == ancestor)
				return true;
		return false;
	}

	private void Open(StringView path)
	{
		if (mServices.Open != null)
			mServices.Open(path);
	}

	private void BrowseAndOpen()
	{
		if (mServices.Dialogs == null)
			return;
		mServices.Dialogs.ShowOpenFolder(new (paths) =>
			{
				if (paths.Length == 0)
					return; // cancelled
				let probed = scope ProjectSettings();
				if (ProjectRegistry.ProbeProject(paths[0], probed) case .Err)
				{
					SetStatus("Not a project (no Project.xml there). New Project makes one.");
					return;
				}
				Open(paths[0]);
			}, "", false, 0);
	}

	/// Locate...: asks for the folder a missing project is in now.
	private void BrowseAndLocate(StringView from)
	{
		if (mServices.Dialogs == null)
			return;
		let path = new String(from);
		// The service consumes the callback once it answers.
		mServices.Dialogs.ShowOpenFolder(new [=this, =path] (paths) =>
			{
				if (paths.Length > 0) // none: cancelled
					Locate(path, paths[0]);
			} ~ delete path, "", false, 0);
	}

	/// The menu of the project at `path`, under `anchor`.
	private void ShowMenu(StringView path, Node anchor)
	{
		if (mMenu != null)
		{
			if (mMenu.IsOpen)
				mMenu.Close();
			mMenu.ReleaseRef();
		}
		mMenu = new Sedulous.GUI.Menu();
		let items = scope List<StringView>();
		MenuItemsFor(path, items);
		for (let item in items)
		{
			if (item == "Remove from List")
				mMenu.AddSeparator();
			let projectPath = new String(path);
			let which = new String(item);
			mMenu.AddItem(item, new [=this, =projectPath, =which] () => { Run(projectPath, which); } ~ { delete projectPath; delete which; });
		}
		mMenu.OpenBelow(anchor, anchor);
	}

	/// The "more" button: the project's menu. A node with one reference, the caller's.
	private Sedulous.GUI.Button MoreButton(StringView path)
	{
		let more = new Sedulous.GUI.Button();
		more.AddClass("slot-button");
		more.Icon = "Editor/Icons/more.svg";
		more.Tooltip = "More";
		let projectPath = new String(path);
		more.SetOnClick(new [=this, =projectPath, =more] () => { ShowMenu(projectPath, more); } ~ delete projectPath);
		return more;
	}

	/// The pin: on, it unpins; off, it pins to the top. A node with one reference, the caller's.
	private Sedulous.GUI.Button StarButton(Card card)
	{
		let star = new Sedulous.GUI.Button();
		star.AddClass("manager-star");
		if (card.Favourite)
			star.AddClass("on");
		star.Icon = card.Favourite ? "Editor/Icons/star-filled.svg" : "Editor/Icons/star.svg";
		star.Tooltip = card.Favourite ? "Unpin" : "Pin to the top";
		let projectPath = new String(card.Path);
		let pin = !card.Favourite;
		star.SetOnClick(new [=this, =projectPath, =pin] () => { SetFavourite(projectPath, pin); } ~ delete projectPath);
		return star;
	}

	/// A click on `button` opens the project at `path`.
	private void OnClickOpens(Sedulous.GUI.Button button, StringView path)
	{
		let projectPath = new String(path);
		button.SetOnClick(new [=this, =projectPath] () => { Open(projectPath); } ~ delete projectPath);
	}

	/// The version's class: none when it is this editor's, else newer or older.
	private static StringView VersionClass(EngineVersionRelation relation)
	{
		switch (relation)
		{
		case .ProjectNewer:
			return "newer";
		case .ProjectOlder, .Unstamped:
			return "older";
		default:
			return "";
		}
	}

	private static StringView VersionText(Card card) => card.EngineVersion.IsEmpty ? "unknown" : StringView(card.EngineVersion);

	/// A project's row or tile: a press puts the ring on it, a double-click opens it, its context
	/// menu is the project's.
	private void Listen(Node node, int index, StringView path)
	{
		let projectPath = new String(path);
		node.AddEventListener(.MouseClick, new [=this, =index, =projectPath] (e) =>
			{
				let click = (MouseEvent)e;
				if (index < mRows.Count)
					SetFocusIndex(index);
				if ((click.ClickCount == 2) && !e.Handled)
					Open(projectPath);
			} ~ delete projectPath);
		let menuPath = new String(path);
		node.AddEventListener(.ContextMenu, new [=this, =menuPath, =node] (e) =>
			{
				ShowMenu(menuPath, node);
				e.Handled = true;
			} ~ delete menuPath);
	}

	/// A row: the picture, the name (with a badge when its engine is not this one's) over the
	/// folder, when it was opened, the engine, the pin, Open, the menu. A node with one reference,
	/// the caller's.
	private Node Row(Card card)
	{
		let row = new Sedulous.GUI.Panel();
		row.AddClass("manager-row");
		let version = VersionClass(card.Relation);
		if (!version.IsEmpty)
			row.AddClass(version);
		Adopt(row, ProjectPicture.Make(card.Path, card.Name, "manager-row-picture", mPictures));
		let text = new Sedulous.GUI.Panel();
		text.AddClass("manager-text");
		let title = new Sedulous.GUI.Panel();
		title.AddClass("manager-title");
		Adopt(title, Text(card.Name, "manager-name"));
		if (card.Relation == .ProjectNewer)
			Adopt(title, Text("Made with a newer engine", "badge warning"));
		else if (!version.IsEmpty)
			Adopt(title, Text("Upgrades when opened", "badge info"));
		Adopt(text, title);
		let path = Text(RecentProjects.ShortenHomePath(card.Path, mHome, .. scope .()), "manager-path");
		path.Tooltip = card.Path;
		Adopt(text, path);
		Adopt(row, text);
		let opened = Text(card.Opened, "manager-opened");
		opened.Tooltip = card.OpenedAt;
		Adopt(row, opened);
		let stamp = Text(VersionText(card), "manager-version");
		if (!version.IsEmpty)
			stamp.AddClass(version);
		Adopt(row, stamp);
		Adopt(row, StarButton(card));
		let open = new Sedulous.GUI.Button();
		open.Text = "Open";
		OnClickOpens(open, card.Path);
		Adopt(row, open);
		Adopt(row, MoreButton(card.Path));
		Listen(row, mRows.Count, card.Path);
		mRows.Add(row);
		return row;
	}

	/// A tile: the picture (a click opens it), then the name over when it was opened and the engine,
	/// with the pin and the menu. A node with one reference, the caller's.
	private Node Tile(Card card)
	{
		let tile = new Sedulous.GUI.Panel();
		tile.AddClass("manager-tile");
		let version = VersionClass(card.Relation);
		// The picture opens it: a flat button holding it.
		let picture = new Sedulous.GUI.Button();
		picture.AddClass("manager-tile-open");
		Adopt(picture, ProjectPicture.Make(card.Path, card.Name, "manager-tile-picture", mPictures));
		picture.Tooltip = card.Path;
		OnClickOpens(picture, card.Path);
		Adopt(tile, picture);
		let foot = new Sedulous.GUI.Panel();
		foot.AddClass("manager-tile-foot");
		let text = new Sedulous.GUI.Panel();
		text.AddClass("manager-text");
		Adopt(text, Text(card.Name, "manager-name"));
		let meta = new Sedulous.GUI.Panel();
		meta.AddClass("manager-tile-meta");
		if (!card.Opened.IsEmpty)
		{
			let opened = Text(card.Opened, "manager-tile-opened");
			opened.Tooltip = card.OpenedAt;
			Adopt(meta, opened);
			Adopt(meta, Text("·", "manager-tile-dot"));
		}
		let stamp = Text(VersionText(card), "manager-tile-version");
		if (!version.IsEmpty)
		{
			stamp.AddClass(version);
			stamp.Tooltip = (card.Relation == .ProjectNewer) ? "Made with a newer engine" : "Upgrades when opened";
		}
		Adopt(meta, stamp);
		Adopt(text, meta);
		Adopt(foot, text);
		Adopt(foot, StarButton(card));
		Adopt(foot, MoreButton(card.Path));
		Adopt(tile, foot);
		Listen(tile, mRows.Count, card.Path);
		mRows.Add(tile);
		return tile;
	}

	/// A missing project: its folder marked broken, its name and old folder, Locate... and Remove
	/// from list. A node with one reference, the caller's.
	private Node MissingRow(RecentProjectEntry entry)
	{
		let row = new Sedulous.GUI.Panel();
		row.AddClass("manager-row");
		row.AddClass("missing");
		let icon = new Sedulous.GUI.Panel();
		icon.AddClass("manager-missing-icon");
		let broken = new Sedulous.GUI.Image();
		broken.Source = "Editor/Icons/folder-missing.svg";
		Adopt(icon, broken);
		Adopt(row, icon);
		let text = new Sedulous.GUI.Panel();
		text.AddClass("manager-text");
		Adopt(text, Text(entry.Name, "manager-name"));
		let path = Text(RecentProjects.ShortenHomePath(entry.Path, mHome, .. scope .()), "manager-path");
		path.Tooltip = entry.Path;
		Adopt(text, path);
		Adopt(row, text);
		let locate = new Sedulous.GUI.Button();
		locate.Text = "Locate...";
		locate.Tooltip = "Choose the folder the project is in now";
		let locatePath = new String(entry.Path);
		locate.SetOnClick(new [=this, =locatePath] () => { BrowseAndLocate(locatePath); } ~ delete locatePath);
		Adopt(row, locate);
		let remove = new Sedulous.GUI.Button();
		remove.AddClass("ghost");
		remove.Text = "Remove from list";
		let removePath = new String(entry.Path);
		remove.SetOnClick(new [=this, =removePath] () => { Run(removePath, "Remove from List"); } ~ delete removePath);
		Adopt(row, remove);
		let index = mShown.Count; // its place in the ring's walk
		row.AddEventListener(.MouseClick, new [=this, =index] (e) => { SetFocusIndex(index); });
		mRows.Add(row);
		return row;
	}
}
