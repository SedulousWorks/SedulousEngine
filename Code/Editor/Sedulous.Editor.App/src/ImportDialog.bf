using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// The import window (Raptor's editor-gui spec, 5.2, layer 7), over its markup
// (Data/Editor/Import.gml): one window for one file or many, where the old editor had a single-file
// and a batch dialog. Where they go, a field that opens the group picker; the files, when there are
// several, each kept or not, with its state (reading, ready, failed), one chosen; the chosen file's
// importer (a choice when several take it), its options (a check box per toggle), and what it
// would create by kind, each kept or not and named, a kind's box keeping or leaving all of it. A
// file still being read says so and shows when it is ready. The line under it says what Import
// does, or why it waits, Import waiting with it. A name another asset holds is said on the file
// (AssetImport.ClashOf): one of another type waits for a rename; another file's of its type offers
// Replace or Keep both, Import waiting for the choice. It is the view of an AssetImport session,
// which does the work. Run is the editor's one import (a drop, Import...): at once when nothing needs
// review, else here.

class ImportWindow
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/Import.gml";
	private const float cWidth = 640.0f;
	private const float cHeight = 520.0f;
	/// The kinds a plan shows, in the order they show; a kind with nothing planned is left out.
	private static readonly ImportResourceKind[7] cKinds = .(.Mesh, .Material, .Texture, .Skeleton, .AnimationClip, .Collision, .Asset);

	/// BORROWED: the application's, which outlives the window.
	private AssetImport mImport;
	/// BORROWED: the editor's one picker, which outlives the window; null: the group field picks
	/// nothing.
	private Picker mPicker;
	/// A reference of ours (the window holds its own).
	private Node mBody = null ~ _?.ReleaseRef();
	/// A reference of ours: closed, it leaves the tree, and this keeps it for the next open.
	private Sedulous.GUI.Window mWindow = null ~ _?.ReleaseRef();
	/// BORROWED: what it opened over (the group picker opens there too).
	private SceneRoot mRoot = null;
	/// The import it shows: a reference of ours while it is open, null closed.
	private AssetImport.Session mSession = null;
	/// The file whose detail shows.
	private int mSelected = 0;
	/// Whether the picker is open for this: it answers here, so it closes when this goes.
	private bool mPicking = false;
	// The body's: the tree holds them.
	private Sedulous.GUI.Button mGroupField = null;
	private Node mFilesScroll = null;
	private Node mFiles = null;
	private Node mDetail = null;
	private Sedulous.GUI.Label mWhy = null;
	private Sedulous.GUI.Button mRun = null;

	/// The window over `body` (the markup's controls by id), showing sessions of `import`, its group
	/// field opening `picker` (both borrowed: they outlive it; a null picker picks nothing). TAKES
	/// OWNERSHIP of a reference to `body`; null makes a window that never opens.
	public this(AssetImport import, Picker picker, Node body)
	{
		mImport = import;
		mPicker = picker;
		mBody = body;
		if (mBody == null)
			return;
		mWindow = new Sedulous.GUI.Window();
		mWindow.Title = "Import";
		mWindow.AddClass("import-window");
		mWindow.Size = .(cWidth, cHeight);
		mWindow.Content.AddChild(mBody);
		mGroupField = Find<Sedulous.GUI.Button>("import-group");
		mFilesScroll = Find<Node>("import-files-scroll");
		mFiles = Find<Node>("import-files");
		mDetail = Find<Node>("import-detail");
		mWhy = Find<Sedulous.GUI.Label>("import-why");
		mRun = Find<Sedulous.GUI.Button>("import-run");
		if (mGroupField != null)
			mGroupField.SetOnClick(new () => { PickGroup(); });
		if (mRun != null)
			mRun.SetOnClick(new () => { Import(); });
		if (let cancel = Find<Sedulous.GUI.Button>("import-cancel"))
			cancel.SetOnClick(new () => { Close(); });
		// However it closes, the session lets go of it: a read that arrives after is dropped.
		mWindow.SetOnClose(new () => { Release(); });
	}

	/// Open as it goes, the group picker would answer into nothing: it closes, and so does this,
	/// letting go of its session. The body may outlive this: what of it calls back here goes.
	public ~this()
	{
		if (mPicking && (mPicker != null) && mPicker.IsOpen)
			mPicker.Close();
		Close();
		Release();
		if (mWindow != null)
			mWindow.SetOnClose(null);
	}

	/// One import of `paths` into `group`, as the editor runs one (files dropped, Import...): at
	/// once when nothing needs review; else in the window `window` gives (made only when one is
	/// needed) over `root`, `context` told when one is open already. Nothing to review in with no
	/// root.
	public static void Run(AssetImport import, EditorContext context, Span<StringView> paths, Group group, SceneRoot root,
		delegate ImportWindow() window)
	{
		let session = import.Begin(paths, group);
		if (session == null)
			return;
		defer session.ReleaseRef(); // the window takes its own
		if (AssetImport.NeedsNoReview(session))
		{
			import.Commit(session);
			return;
		}
		if (root == null)
			return;
		let shown = window();
		if ((shown == null) || !shown.Open(root, session))
			context.Notify(.Info, "An import is open already: finish it first.");
	}

	/// Where files dropped on the editor go: the group the Assets panel shows (`assets`, null: no
	/// panel), else the top of `sources`.
	public static Group DropGroup(AssetsView assets, ContentDatabase sources)
	{
		if ((assets != null) && (assets.CurrentGroup != null))
			return assets.CurrentGroup;
		return sources.RootGroup;
	}

	/// Opens it over `root` for `session` (it takes a reference of its own), its first file chosen;
	/// false with no markup, no session or one open.
	public bool Open(SceneRoot root, AssetImport.Session session)
	{
		if ((mWindow == null) || (session == null) || mWindow.IsOpen)
			return false;
		Release(); // a session left by a modal open refused
		session.AddRef();
		mSession = session;
		mRoot = root;
		mSelected = 0;
		delete mSession.OnChanged;
		mSession.OnChanged = new (file) =>
			{
				ShowFiles();
				if (file == mSelected)
					ShowDetail();
				ShowWhy();
			};
		ShowAll();
		mWindow.OpenModal(root);
		return true;
	}

	public bool IsOpen => (mWindow != null) && mWindow.IsOpen;

	public void Close()
	{
		if (IsOpen)
			mWindow.Close();
	}

	/// Imports what is kept and closes; false (it stays, saying why) when it cannot yet.
	public bool Import()
	{
		if ((mSession == null) || !mImport.Commit(mSession))
			return false;
		Close();
		return true;
	}

	/// Shows file `index`'s detail.
	public void Select(int index)
	{
		if ((mSession == null) || (index < 0) || (index >= mSession.Files.Count))
			return;
		mSelected = index;
		ShowFiles();
		ShowDetail();
	}

	// For tests: the session, the window, the chosen file, the line, its parts.
	public AssetImport.Session Session => mSession;
	/// Its window. Ours: a caller that keeps it takes a reference.
	public Sedulous.GUI.Window Window => mWindow;
	public int Selected => mSelected;
	public StringView Why => (mWhy != null) ? mWhy.Text : default;
	public Sedulous.GUI.Label WhyLine => mWhy;
	public Sedulous.GUI.Button ImportButton => mRun;
	public Sedulous.GUI.Button GroupField => mGroupField;
	/// The files' list, and what holds it (shown only when there are several).
	public Node Files => mFiles;
	public Node FilesScroll => mFilesScroll;
	/// The chosen file's detail.
	public Node Detail => mDetail;

	// The session lets go of it: told no more, a read that arrives after dropped.
	private void Release()
	{
		if (mSession == null)
			return;
		DeleteAndNullify!(mSession.OnChanged);
		mSession.Closed = true;
		mSession.ReleaseRef();
		mSession = null;
	}

	private void ShowAll()
	{
		if ((mGroupField != null) && (mSession != null))
			mGroupField.Text = AssetImport.ShownGroup(mSession, .. scope .());
		ShowFiles();
		ShowDetail();
		ShowWhy();
	}

	// The group picker below the group field, the import's group checked.
	private void PickGroup()
	{
		let sources = mImport.Sources;
		if ((mSession == null) || (mPicker == null) || (mRoot == null) || (sources == null))
			return;
		let request = GroupPicker.Request(sources, mImport.GroupOf(mSession));
		request.OnPicked = new (key) => { PickedGroup(key); };
		mPicking = mPicker.Open(mRoot, request);
	}

	private void PickedGroup(StringView key)
	{
		mPicking = false;
		let sources = mImport.Sources;
		if ((mSession == null) || (sources == null))
			return;
		if (let picked = GroupPicker.Find(sources, key))
		{
			mImport.SetGroup(mSession, picked);
			ShowAll();
		}
	}

	// The files, when there are several: each kept or not (a failed one's box off), its state, the
	// chosen one marked.
	private void ShowFiles()
	{
		if ((mFilesScroll == null) || (mFiles == null) || (mSession == null))
			return;
		let several = mSession.Files.Count > 1;
		mFilesScroll.Displayed = several;
		mFiles.RemoveAllChildren();
		if (!several)
			return;
		for (int i < mSession.Files.Count)
		{
			let file = mSession.Files[i];
			let row = new Sedulous.GUI.Panel();
			row.AddClass("import-file");
			if (i == mSelected)
				row.AddClass("selected");
			let kept = new Sedulous.GUI.CheckBox();
			kept.Checked = file.Kept;
			kept.Enabled = file.State != .Failed;
			kept.Tooltip = "Import this file";
			kept.SetOnToggled(new [=this, =i] (keep) =>
				{
					if ((mSession != null) && (i < mSession.Files.Count))
						mSession.Files[i].Kept = keep;
					ShowWhy();
				});
			let name = new Sedulous.GUI.Button();
			name.AddClass("import-file-name");
			name.Text = file.Name;
			name.Tooltip = file.Path;
			// The rows are made again: not under the click.
			name.SetOnClick(new [=this, =i] () => { Later(new [=this, =i] () => { Select(i); }); });
			let state = new Sedulous.GUI.Label();
			state.AddClass("badge");
			switch (file.State)
			{
			case .Ready:
				state.AddClass("success");
				state.Text = "Ready";
			case .Failed:
				state.AddClass("danger");
				state.Text = "Failed";
			case .Reading:
				state.AddClass("warning");
				state.Text = "Reading";
			}
			Add(row, kept);
			Add(row, name);
			Add(row, state);
			Add(mFiles, row);
		}
	}

	// The chosen file: its importer, its options, what it would create by kind.
	private void ShowDetail()
	{
		if ((mDetail == null) || (mSession == null) || (mSelected >= mSession.Files.Count))
			return;
		mDetail.RemoveAllChildren();
		let file = mSession.Files[mSelected];
		let index = mSelected;
		Add(mDetail, Text(file.Name, "import-title"));
		if (file.Importers.Count > 1)
		{
			let line = Row("import-importer");
			Add(line, Text("Import as", "form-label"));
			let choice = new Sedulous.GUI.ComboBox();
			for (let importer in file.Importers)
				choice.AddItem(importer.Label);
			choice.SelectedIndex = (int32)file.ImporterIndex; // before its callback: no change told
			choice.SetOnSelectionChanged(new [=this, =index] (picked) =>
				{
					if ((mSession == null) || (picked < 0))
						return;
					mImport.SetImporter(mSession, index, picked);
					Later(new [=this] () => { ShowAll(); }); // not under the combo's own event
				});
			Add(line, choice);
			Add(mDetail, line);
		}
		if (file.State == .Reading)
		{
			Add(mDetail, Text(scope $"Reading {file.Name}...", "form-help"));
			let bar = new Sedulous.GUI.ProgressBar();
			bar.Indeterminate = true;
			Add(mDetail, bar);
			return;
		}
		if (file.State == .Failed)
		{
			Add(mDetail, Text("It could not be read; the Console says why.", "form-help refused"));
			return;
		}
		// Its options: a box per toggle, writing straight through to the field it points at (one
		// pointing at none shows nothing).
		if (file.Options != null)
		{
			let toggles = scope List<ImportToggle>();
			file.Options.GetToggles(toggles);
			for (let toggle in toggles)
			{
				if (toggle.Value == null)
					continue;
				let toggleBox = new Sedulous.GUI.CheckBox();
				toggleBox.Text = toggle.Label;
				if (!toggle.Description.IsEmpty)
					toggleBox.Tooltip = toggle.Description;
				toggleBox.Checked = *toggle.Value;
				let value = toggle.Value;
				toggleBox.SetOnToggled(new [=value] (on) => { *value = on; });
				Add(mDetail, toggleBox);
			}
		}
		ShowClash(file, index);
		if (file.Plan.IsEmpty)
		{
			Add(mDetail, Text("It makes one asset, named after the file.", "form-help"));
			return;
		}
		// What it would create, by kind: a kind's box keeps or leaves all of it.
		for (let kind in cKinds)
		{
			int count = 0;
			int kept = 0;
			for (let entry in file.Plan.Entries)
			{
				if (entry.Kind != kind)
					continue;
				count++;
				if (entry.Enabled)
					kept++;
			}
			if (count == 0)
				continue;
			let all = new Sedulous.GUI.CheckBox();
			all.AddClass("import-kind");
			all.Text = scope $"{kind.Label} ({count})";
			all.Checked = kept == count;
			all.Indeterminate = (kept > 0) && (kept < count); // after Checked, which settles it
			all.SetOnToggled(new [=this, =index, =kind] (on) =>
				{
					if ((mSession == null) || (index >= mSession.Files.Count))
						return;
					for (let entry in mSession.Files[index].Plan.Entries)
					{
						if (entry.Kind == kind)
							entry.Enabled = on;
					}
					Later(new [=this] () => { ShowDetail(); });
				});
			Add(mDetail, all);
			for (int e < file.Plan.Entries.Count)
			{
				let entry = file.Plan.Entries[e];
				if (entry.Kind != kind)
					continue;
				let line = Row("import-entry");
				let keep = new Sedulous.GUI.CheckBox();
				keep.Checked = entry.Enabled;
				keep.SetOnToggled(new [=this, =index, =e] (on) =>
					{
						if (let planned = Planned(index, e))
							planned.Enabled = on;
						Later(new [=this] () => { ShowDetail(); }); // its kind's box follows
					});
				let name = new Sedulous.GUI.TextField();
				name.Text = entry.TargetName;
				name.Placeholder = entry.SourceName; // emptied, it keeps the importer's name
				name.SetOnTextChanging(new [=this, =index, =e] (text) =>
					{
						if (let planned = Planned(index, e))
							planned.TargetName.Set(text);
						ShowWhy(); // a rename may free the name, or take one
					});
				// Committed (Enter, or leaving it): the clash line says what the name meets now.
				name.SetOnTextChanged(new [=this] (text) => { Later(new [=this] () => { ShowDetail(); }); });
				Add(line, keep);
				Add(line, name);
				Add(mDetail, line);
			}
		}
	}

	// What the file's name meets (AssetImport.ClashOf): nothing said when it is free or the file's
	// own earlier import; another type's asset said, to rename; another file's of its type said,
	// with Replace and Keep both.
	private void ShowClash(AssetImport.File file, int index)
	{
		let clash = AssetImport.ClashOf(mSession, file, .. scope .());
		if ((clash.Kind == .None) || (clash.Kind == .Reimport))
			return;
		let chosen = ImportPaths.ImportClashAllows(clash, file.OnConflict);
		Add(mDetail, Text(ImportPaths.DescribeImportClash(clash, .. scope .()), chosen ? "form-help" : "form-help refused"));
		if (clash.Kind != .SameType)
			return;
		let choices = Row("segmented");
		AddChoice(choices, file, index, "Replace", "The asset there takes this file; what refers to it keeps working", .Replace);
		AddChoice(choices, file, index, "Keep both", "This one under the next free name", .KeepBoth);
		Add(mDetail, choices);
	}

	private void AddChoice(Node into, AssetImport.File file, int index, StringView text, StringView tip, ImportConflictChoice choice)
	{
		let segment = new Sedulous.GUI.Button();
		segment.AddClass("segment");
		segment.Text = text;
		segment.Tooltip = tip;
		segment.IsToggle = true;
		segment.Checked = file.OnConflict == choice;
		segment.SetOnClick(new [=this, =index, =choice] () =>
			{
				if ((mSession != null) && (index < mSession.Files.Count))
					mSession.Files[index].OnConflict = choice;
				Later(new [=this] () =>
					{
						ShowDetail();
						ShowWhy();
					});
			});
		Add(into, segment);
	}

	// File `index`'s plan entry `entry`, while the session still has it.
	private ImportPlanEntry Planned(int index, int entry)
	{
		if ((mSession == null) || (index >= mSession.Files.Count))
			return null;
		let entries = mSession.Files[index].Plan.Entries;
		return (entry < entries.Count) ? entries[entry] : null;
	}

	// What Import does, or why it waits; Import with it.
	private void ShowWhy()
	{
		if (mSession == null)
			return;
		let why = scope String();
		let can = AssetImport.CanImport(mSession, why);
		if (mWhy != null)
		{
			mWhy.Text = why;
			if (can)
				mWhy.RemoveClass("refused");
			else
				mWhy.AddClass("refused");
		}
		if (mRun != null)
			mRun.Enabled = can;
	}

	/// `work` after the event that asked (a control's own callback rebuilding the controls), at
	/// the GUI's next drain; at once out of one. TAKES OWNERSHIP of `work`.
	private void Later(delegate void() work)
	{
		let queue = (mBody != null) ? mBody.MutationQueue : null;
		if (queue == null)
		{
			defer delete work;
			work();
			return;
		}
		queue.Enqueue(work);
	}

	/// `child` into `into`, whose reference keeps it: the caller's one goes.
	private static void Add(Node into, Node child)
	{
		into.AddChild(child);
		child.ReleaseRef();
	}

	/// A label of `text` with the sheet's `classes`: a node with one reference, the caller's.
	private static Node Text(StringView text, StringView classes)
	{
		let label = new Sedulous.GUI.Label();
		label.AddClasses(classes);
		label.Text = text;
		return label;
	}

	/// A row of the sheet's class `cls`: a node with one reference, the caller's.
	private static Node Row(StringView cls)
	{
		let row = new Sedulous.GUI.Panel();
		row.AddClass(cls);
		return row;
	}

	private T Find<T>(StringView id) where T : Node => (mBody != null) ? mBody.FindElement(id) as T : null;
}
