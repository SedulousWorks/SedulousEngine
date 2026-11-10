using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.GUI;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.ProjectManager;

/// The project manager's Engines page, over its parts in the manager's markup
/// (Data/Editor/ProjectManager.xml): the engines listed, each with its version, how it was listed
/// (installed, a folder, a checkout), its folder and the projects that open with it, with Show in
/// Folder and Remove..., which asks first and names those projects; Add Folder... lists a checkout
/// or an engine unpacked by hand. Under them, the engines the releases offer for this platform,
/// each with Install (or Installed), and while it installs, its bar and Cancel. The first visit asks
/// the releases; Check for Engines asks again.
class EnginesPage
{
	/// An install's bar and words on its row, while the row shows: the tree's.
	private class InstallBar
	{
		public String Display = new .() ~ delete _;
		public Sedulous.GUI.ProgressBar Bar;
		public Sedulous.GUI.Label Words;
	}

	/// BORROWED, all: the manager's frame, the engines, the view whose status line it speaks on, and
	/// the shell's dialogs (null: none).
	private Node mContent;
	private EngineManager mEngines;
	private ProjectManagerView mView;
	private IDialogService mDialogs;
	/// Remove's question, a reference of ours while it is the last one asked.
	private Sedulous.GUI.MessageBox mAsking = null ~ _?.ReleaseRef();
	private List<InstallBar> mBars = new .() ~ DeleteContainerAndItems!(_);
	private String mHome = new .() ~ delete _;
	private bool mVisited = false;
	private int mChangeSeen = 0;

	public this(Node content, EngineManager engines, ProjectManagerView view, IDialogService dialogs)
	{
		mContent = content;
		mEngines = engines;
		mView = view;
		mDialogs = dialogs;
		mChangeSeen = engines.ChangeSerial;
		GetHomeDirectory(mHome);
		if (let add = Find<Sedulous.GUI.Button>("manager-engines-add"))
			add.SetOnClick(new () => { BrowseAndAdd(); });
		if (let refresh = Find<Sedulous.GUI.Button>("manager-engines-refresh"))
			refresh.SetOnClick(new () =>
				{
					mEngines.FetchAvailable();
					Later();
				});
	}

	/// The rows call back here: they go first, and a question still open goes unanswered.
	public ~this()
	{
		if ((mAsking != null) && mAsking.IsOpen)
			mAsking.Close();
		Clear(Find<Node>("manager-engines-installed"));
		Clear(Find<Node>("manager-engines-available"));
	}

	/// The page comes into view: the listed engines read again, and the first time, the releases
	/// asked what they offer.
	public void Shown()
	{
		mEngines.ReadInstalled();
		if (!mVisited)
		{
			mVisited = true;
			if (mEngines.AvailableState == .NotFetched)
				mEngines.FetchAvailable();
		}
		mChangeSeen = mEngines.ChangeSerial;
		Populate();
	}

	/// Once a frame while the page shows: a change of the engines laid out at the next drain, else
	/// the bars of the installs under way.
	public void Tick()
	{
		if (mEngines.ChangeSerial != mChangeSeen)
		{
			mChangeSeen = mEngines.ChangeSerial;
			Later();
			return;
		}
		ShowProgress();
	}

	/// The lists laid out from what the engines last read and fetched.
	public void Populate()
	{
		let installed = Find<Node>("manager-engines-installed");
		let available = Find<Node>("manager-engines-available");
		Clear(installed);
		Clear(available);
		ClearAndDeleteItems!(mBars);
		if (installed != null)
		{
			for (let engine in mEngines.Installed)
				Adopt(installed, InstalledRow(engine));
		}
		if (let count = Find<Sedulous.GUI.Label>("manager-engines-count"))
		{
			let listed = mEngines.Installed.Count;
			count.Text = scope $"{listed} engine{(listed == 1) ? "" : "s"}";
		}
		if (let none = Find<Node>("manager-engines-none"))
			none.Displayed = mEngines.Installed.IsEmpty;
		if (available != null)
		{
			for (let engine in mEngines.Available)
				Adopt(available, AvailableRow(engine));
		}
		if (let state = Find<Sedulous.GUI.Label>("manager-engines-available-state"))
			AvailableState(state);
		ShowProgress();
	}

	/// Remove's question for the engine at `root`: what happens to it and the projects that open
	/// with it; Remove removes it. Nothing with no window, or with one open already.
	public void AskRemove(StringView root)
	{
		let title = scope String();
		let body = scope String();
		let scene = (mContent != null) ? (mContent.RootNode as SceneRoot) : null;
		if ((scene == null) || ((mAsking != null) && mAsking.IsOpen) || !mEngines.RemovalQuestion(root, title, body))
			return;
		if (mAsking != null)
			mAsking.ReleaseRef();
		let question = new Sedulous.GUI.MessageBox();
		mAsking = question;
		question.Configure(title, body, .Ok);
		question.ClearButtons();
		question.AddButton("Cancel", "cancel", .Cancel);
		question.AddButton("Remove", "remove", .Primary);
		let path = new String(root);
		question.AddEventListener(.Changed, new [=question, =path, =this] (e) =>
			{
				if (question.ResultName == "remove")
					Remove(path);
			} ~ delete path);
		question.OpenModal(scene);
	}

	/// Removes the engine at `root` (Remove's second half), at the next drain, saying how it went.
	public void Remove(StringView root)
	{
		let path = new String(root);
		LaterDo(new [=this, =path] () =>
			{
				let why = scope String();
				if (!mEngines.Remove(path, why))
					mView.SetStatus(why); // a removal says what it did through the engines' message
				Populate();
			} ~ delete path);
	}

	/// Add Folder...: asks for the folder, then lists the engine in it.
	private void BrowseAndAdd()
	{
		if (mDialogs == null)
			return;
		mDialogs.ShowOpenFolder(new (paths) =>
			{
				if (paths.Length == 0)
					return; // cancelled
				let why = scope String();
				if (!mEngines.AddFolder(paths[0], why))
					mView.SetStatus(why);
				Later();
			}, "", false, 0);
	}

	/// Installs the offered engine `display` (the row's Install), saying why when it cannot start.
	private void Install(StringView display)
	{
		for (let engine in mEngines.Available)
		{
			if (engine.Display != display)
				continue;
			let why = scope String();
			if (!mEngines.Install(engine, why))
				mView.SetStatus(why);
			Later();
			return;
		}
	}

	/// Where the list of what the releases offer stands, in words.
	private void AvailableState(Sedulous.GUI.Label state)
	{
		let platform = BuildLayout.HostPlatformName;
		switch (mEngines.AvailableState)
		{
		case .NotFetched:
			state.Text = "Check for Engines asks the releases.";
		case .Fetching:
			state.Text = "Asking the releases...";
		case .Failed:
			state.Text = scope $"The releases were not reached: {mEngines.AvailableError}.";
		case .Loaded:
			if (mEngines.Available.IsEmpty)
				state.Text = scope $"No release offers an engine for {platform} yet.";
			else
				state.Text = scope $"for {platform}";
		}
	}

	/// A listed engine's row: its name with how it was listed (and missing, or this manager's own),
	/// its folder and the projects that open with it, then Show in Folder and Remove.... A node with
	/// one reference, the caller's.
	private Node InstalledRow(InstalledEngine engine)
	{
		let row = new Sedulous.GUI.Panel();
		row.AddClass("manager-row");
		row.AddClass("manager-engine");
		if (engine.Missing)
			row.AddClass("missing");
		let text = new Sedulous.GUI.Panel();
		text.AddClass("manager-text");
		let title = new Sedulous.GUI.Panel();
		title.AddClass("manager-title");
		Adopt(title, Text(engine.Name(.. scope .()), "manager-name"));
		Adopt(title, Text(InstalledEngine.KindName(engine.Kind), "badge info"));
		if (engine.Own)
			Adopt(title, Text("this manager's", "badge accent"));
		if (engine.Missing)
			Adopt(title, Text("missing", "badge warning"));
		Adopt(text, title);
		let path = Text(RecentProjects.ShortenHomePath(engine.Root, mHome, .. scope .()), "manager-path");
		path.Tooltip = engine.Root;
		Adopt(text, path);
		Adopt(text, Text(UsedBy(engine, .. scope .()), "manager-path"));
		Adopt(row, text);
		if (!engine.Missing && (mDialogs != null))
		{
			let show = new Sedulous.GUI.Button();
			show.Text = "Show in Folder";
			let folder = new String(engine.Root);
			show.SetOnClick(new [=this, =folder] () => { mDialogs.OpenPath(folder); } ~ delete folder);
			Adopt(row, show);
		}
		let remove = new Sedulous.GUI.Button();
		remove.AddClass("ghost");
		remove.Text = "Remove...";
		remove.Enabled = !engine.Own;
		remove.Tooltip = (engine.Kind == .Installed) ? "Delete this engine's folder" : "Take it off the list; its files stay";
		let root = new String(engine.Root);
		remove.SetOnClick(new [=this, =root] () => { AskRemove(root); } ~ delete root);
		Adopt(row, remove);
		return row;
	}

	/// The projects that open with `engine`, in words.
	private static void UsedBy(InstalledEngine engine, String outText)
	{
		if (engine.Projects.IsEmpty)
		{
			outText.Append("No project you have listed opens with it");
			return;
		}
		outText.Append("Opens ");
		for (let project in engine.Projects)
			outText.AppendF("{}{}", (@project.Index == 0) ? "" : ", ", project);
	}

	/// An offered engine's row: its name and label, its platform and sizes, then Install, Installed,
	/// or while it installs its bar, its words and Cancel. A node with one reference, the caller's.
	private Node AvailableRow(AvailableEngine engine)
	{
		let row = new Sedulous.GUI.Panel();
		row.AddClass("manager-row");
		row.AddClass("manager-engine");
		let text = new Sedulous.GUI.Panel();
		text.AddClass("manager-text");
		let title = new Sedulous.GUI.Panel();
		title.AddClass("manager-title");
		Adopt(title, Text(scope $"Engine {engine.Display}", "manager-name"));
		if (!engine.Label.IsEmpty)
			Adopt(title, Text((engine.Label == SdkInfo.cDevLabel) ? "dev build" : "pre-release", "badge info"));
		Adopt(text, title);
		let sizes = scope String();
		sizes.AppendF("{} · {} download", engine.Platform, ByteSizeText(engine.Size, .. scope .()));
		if (engine.UnpackedSize > 0)
			sizes.AppendF(" · {} installed", ByteSizeText(engine.UnpackedSize, .. scope .()));
		Adopt(text, Text(sizes, "manager-path"));
		Adopt(row, text);
		let display = engine.Display;
		if (mEngines.InstallOf(display) != null)
		{
			let progress = new Sedulous.GUI.Panel();
			progress.AddClass("manager-engine-progress");
			let bar = new Sedulous.GUI.ProgressBar();
			bar.Min = 0.0;
			bar.Max = 1.0;
			Adopt(progress, bar);
			let words = Text("Downloading", "manager-meta");
			Adopt(progress, words);
			Adopt(row, progress);
			let cancel = new Sedulous.GUI.Button();
			cancel.AddClass("ghost");
			cancel.Text = "Cancel";
			let which = new String(display);
			cancel.SetOnClick(new [=this, =which] () => { mEngines.CancelInstall(which); } ~ delete which);
			Adopt(row, cancel);
			let shown = new InstallBar();
			shown.Display.Set(display);
			shown.Bar = bar;
			shown.Words = words;
			mBars.Add(shown);
		}
		else if (mEngines.IsInstalled(engine))
			Adopt(row, Text("Installed", "manager-sample-have"));
		else
		{
			let install = new Sedulous.GUI.Button();
			install.AddClass("primary");
			install.Text = "Install";
			let which = new String(display);
			install.SetOnClick(new [=this, =which] () => { Install(which); } ~ delete which);
			Adopt(row, install);
		}
		return row;
	}

	/// The bars and words of the installs under way, without laying the page out again.
	private void ShowProgress()
	{
		for (let shown in mBars)
		{
			let download = mEngines.InstallOf(shown.Display);
			if (download == null)
				continue;
			shown.Bar.Value = download.Progress;
			shown.Words.Text = scope $"{ByteSizeText(download.Received, .. scope .())} of {ByteSizeText(download.Total, .. scope .())}";
		}
	}

	/// Laid out again at the GUI's next drain (the clicked button is in what goes); at once in no GUI.
	private void Later()
	{
		LaterDo(new [=this] () => { Populate(); });
	}

	/// `work` at the GUI's next drain; at once with no GUI. TAKES OWNERSHIP of `work`.
	private void LaterDo(delegate void() work)
	{
		let queue = (mContent != null) ? mContent.MutationQueue : null;
		if (queue == null)
		{
			defer delete work;
			work();
			return;
		}
		queue.Enqueue(work);
	}

	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

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
}
