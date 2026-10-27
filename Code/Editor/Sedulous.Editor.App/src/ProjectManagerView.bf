using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.Image.IO;
using Sedulous.GUI;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

// ProjectManagerView: the project manager (Raptor's editor-gui spec, 5.1, layer 13), the window's
// whole screen at startup with no project given, and after File > Close Project. Its frame is
// markup (Data/Editor/ProjectManager.gml): New Project and Open Folder first, then every recent
// project as a row (its picture, name, folder and engine, Open, a menu) or a tile of its picture.
// There is no selection: an action is one click on the project it is for. Each project is probed as
// it is shown: one whose folder no longer holds it is dimmed with no Open; one saved by a newer
// engine is named in the warning colour. The status line under the head says what went wrong.
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
}

class ProjectManagerView
{
	/// Its frames, under the data root.
	public const String cMarkupPath = "Editor/ProjectManager.gml";
	public const String cNewProjectPath = "Editor/NewProject.gml";
	private const float cDialogWidth = 480.0f;
	private const float cDialogHeight = 220.0f;

	/// One recent project as it was probed when shown.
	private class Card
	{
		public String Path = new .() ~ delete _;
		public String Name = new .() ~ delete _;
		public String EngineVersion = new .() ~ delete _;
		public bool Missing = false;
		public bool Newer = false;
	}

	private ProjectManagerServices mServices ~ delete _;
	/// What the pictures show: declared before the content, so they outlive it.
	private List<Sedulous.Image.Image> mPictures = new .() ~ DeleteContainerAndItems!(_);
	/// A reference of ours; the window showing it takes its own.
	private Node mContent ~ _?.ReleaseRef();
	/// New Project, a reference of ours while it is the last one made.
	private Sedulous.GUI.Window mDialog = null ~ _?.ReleaseRef();
	/// A project's menu, a reference of ours while it is the last one made.
	private Sedulous.GUI.Menu mMenu = null ~ _?.ReleaseRef();
	private List<Card> mShown = new .() ~ DeleteContainerAndItems!(_);

	/// The manager over `services`, its frame `content` (the markup's: its parts by id). TAKES
	/// OWNERSHIP of the services and of a reference to `content`; null shows nothing.
	public this(ProjectManagerServices services, Node content)
	{
		mServices = services;
		mContent = content;
		if (mContent == null)
			return;
		if (let create = Find<Sedulous.GUI.Button>("manager-new"))
			create.SetOnClick(new () => { ShowCreateDialog(); });
		if (let open = Find<Sedulous.GUI.Button>("manager-open"))
			open.SetOnClick(new () => { BrowseAndOpen(); });
		if (let asList = Find<Sedulous.GUI.Button>("manager-list"))
			asList.SetOnClick(new () => { SetGridView(false); });
		if (let asGrid = Find<Sedulous.GUI.Button>("manager-grid"))
			asGrid.SetOnClick(new () => { SetGridView(true); });
		if (let engine = Find<Sedulous.GUI.Label>("manager-engine"))
			engine.Text = scope $"engine {EngineVersion.String}";
		Rebuild();
	}

	public ~this()
	{
		// Open as it goes, New Project would make into nothing and the menu run on nothing.
		if ((mDialog != null) && mDialog.IsOpen)
			mDialog.Close();
		if ((mMenu != null) && mMenu.IsOpen)
			mMenu.Close();
	}

	/// Its frame. Ours: a caller that keeps it takes a reference.
	public Node Content => mContent;

	/// The status line (empty hides it).
	public void SetStatus(StringView text)
	{
		if (let status = Find<Sedulous.GUI.Label>("manager-status"))
		{
			status.Text = text;
			status.Displayed = !text.IsEmpty;
		}
	}

	public StringView Status
	{
		get
		{
			let status = Find<Sedulous.GUI.Label>("manager-status");
			return (status != null) ? status.Text : default;
		}
	}

	/// The projects again, each probed now.
	public void Rebuild()
	{
		let list = Find<Node>("manager-projects");
		if ((list == null) || (mServices.Controller == null))
			return;
		list.RemoveAllChildren(); // the pictures it showed go before their images
		ClearAndDeleteItems(mPictures);
		ClearAndDeleteItems(mShown);
		let grid = mServices.Controller.GridView;
		if (let asList = Find<Sedulous.GUI.Button>("manager-list"))
			asList.Checked = !grid;
		if (let asGrid = Find<Sedulous.GUI.Button>("manager-grid"))
			asGrid.Checked = grid;
		if (let view = list as UIWidget)
		{
			if (grid)
				view.AddClass("grid");
			else
				view.RemoveClass("grid");
		}
		let recent = mServices.Controller.Entries;
		if (recent.Entries.IsEmpty)
		{
			Adopt(list, Text("No projects yet. Make a new project, or open a project's folder.", "manager-empty"));
			return;
		}
		for (let entry in recent.Entries)
		{
			let card = new Card();
			card.Path.Set(entry.Path);
			card.Name.Set(entry.Name);
			card.EngineVersion.Set(entry.EngineVersion);
			let probed = scope ProjectSettings();
			if (ProjectRegistry.ProbeProject(entry.Path, probed) case .Ok)
			{
				card.Name.Set(probed.Name);
				card.EngineVersion.Set(probed.EngineVersion);
				card.Newer = ProjectRegistry.CompareProjectEngineVersion(probed.EngineVersion) == .ProjectNewer;
			}
			else
				card.Missing = true;
			mShown.Add(card);
			Adopt(list, grid ? Tile(card) : Row(card));
		}
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
		RebuildLater();
	}

	/// The projects shown, and how many show their thumbnail (a test's).
	public int ShownCount => mShown.Count;
	public int ThumbnailCount => mPictures.Count;
	/// A project's menu while it is open (a test's); null with none.
	public Sedulous.GUI.Menu OpenMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

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
				SetStatus("Copied the project's path.");
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
			RebuildLater();
		}
		else if (item == "Remove from List")
		{
			if ((mServices.Controller == null) || !mServices.Controller.Remove(path))
				return;
			if (mServices.StoreChanged != null)
				mServices.StoreChanged();
			RebuildLater();
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
		RebuildLater();
		return true;
	}

	/// New Project: a name and the folder it is made in; Create waits for both. Nothing with no
	/// GUI, no markup, or with it open already.
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
		dialog.Content.AddChild(body);
		// Create waits for both fields; the line under them says where the project goes.
		name.SetOnTextChanging(new [=name, =parent, =target, =create] (text) => { RefreshCreate(name, parent, target, create); });
		parent.SetOnTextChanging(new [=name, =parent, =target, =create] (text) => { RefreshCreate(name, parent, target, create); });
		create.SetOnClick(new [=this, =dialog, =name, =parent] () =>
			{
				let projectName = scope String(name.Text);
				let folder = scope String(parent.Text);
				if (projectName.IsEmpty || folder.IsEmpty)
					return;
				let directory = PathJoin(folder, projectName, .. scope .());
				dialog.Close();
				if (mServices.Create != null)
					mServices.Create(directory, projectName);
			});
		if (browse != null)
		{
			browse.SetOnClick(new [=this, =name, =parent, =target, =create] () =>
				{
					if (mServices.Dialogs == null)
						return;
					mServices.Dialogs.ShowOpenFolder(new [=name, =parent, =target, =create] (paths) =>
						{
							if (paths.Length == 0)
								return; // cancelled
							parent.Text = paths[0]; // set from code: no edit reported, so refreshed here
							RefreshCreate(name, parent, target, create);
						}, "", false, 0);
				});
		}
		if (cancel != null)
			cancel.SetOnClick(new [=dialog] () => { dialog.Close(); });
		RefreshCreate(name, parent, target, create);
		dialog.OpenModal(root);
		name.FocusElement();
	}

	/// New Project's window while it is open (a test's); null with none.
	public Sedulous.GUI.Window CreateDialog => ((mDialog != null) && mDialog.IsOpen) ? mDialog : null;

	/// Create enabled once both fields hold something; the line under them says where then.
	private static void RefreshCreate(Sedulous.GUI.TextField name, Sedulous.GUI.TextField parent, Sedulous.GUI.Label target,
		Sedulous.GUI.Button create)
	{
		let ready = !name.Text.IsEmpty && !parent.Text.IsEmpty;
		create.Enabled = ready;
		if (target == null)
			return;
		let path = scope String();
		if (ready)
			PathJoin(parent.Text, name.Text, path);
		target.Text = path;
	}

	/// The frame's part with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
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

	/// Rebuilds at the GUI's next drain (the clicked button is in what a rebuild takes away); at
	/// once in no GUI.
	private void RebuildLater()
	{
		let queue = (mContent != null) ? mContent.MutationQueue : null;
		if (queue == null)
		{
			Rebuild();
			return;
		}
		queue.Enqueue(new () => { Rebuild(); });
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

	/// A click on `button` opens the project at `path`.
	private void OnClickOpens(Sedulous.GUI.Button button, StringView path)
	{
		let projectPath = new String(path);
		button.SetOnClick(new [=this, =projectPath] () => { Open(projectPath); } ~ delete projectPath);
	}

	private static StringView NameOf(Card card) => card.Name.IsEmpty ? "(unnamed)" : StringView(card.Name);

	/// A row's name: what is wrong with the project, if anything, after it.
	private static void Title(Card card, String outText)
	{
		outText.Append(NameOf(card));
		if (card.Missing)
			outText.Append(" (missing)");
		else if (card.Newer)
			outText.Append(" (newer engine)");
	}

	private static void Classes(Sedulous.GUI.Panel panel, Card card)
	{
		if (card.Missing)
			panel.AddClass("missing");
		if (card.Newer)
			panel.AddClass("newer");
	}

	/// A row: the picture, the name over the folder, the engine, Open (none when missing), the
	/// menu. A node with one reference, the caller's.
	private Node Row(Card card)
	{
		let row = new Sedulous.GUI.Panel();
		row.AddClass("manager-row");
		Classes(row, card);
		Adopt(row, ProjectPicture.Make(card.Missing ? "" : StringView(card.Path), card.Name, "manager-row-picture", mPictures));
		let text = new Sedulous.GUI.Panel();
		text.AddClass("manager-text");
		Adopt(text, Text(Title(card, .. scope .()), "manager-name"));
		let path = Text(card.Path, "manager-path");
		path.Tooltip = card.Path;
		Adopt(text, path);
		Adopt(row, text);
		Adopt(row, Text(card.EngineVersion, "manager-version"));
		if (!card.Missing)
		{
			let open = new Sedulous.GUI.Button();
			open.Text = "Open";
			OnClickOpens(open, card.Path);
			Adopt(row, open);
		}
		Adopt(row, MoreButton(card.Path));
		return row;
	}

	/// A tile: the picture (a click opens it), then the name and the engine with the menu. A node
	/// with one reference, the caller's.
	private Node Tile(Card card)
	{
		let tile = new Sedulous.GUI.Panel();
		tile.AddClass("manager-tile");
		Classes(tile, card);
		// The picture opens it: a flat button holding it.
		let picture = new Sedulous.GUI.Button();
		picture.AddClass("link");
		Adopt(picture, ProjectPicture.Make(card.Missing ? "" : StringView(card.Path), card.Name, "manager-tile-picture", mPictures));
		picture.Tooltip = card.Path;
		picture.Enabled = !card.Missing;
		OnClickOpens(picture, card.Path);
		Adopt(tile, picture);
		let foot = new Sedulous.GUI.Panel();
		foot.AddClass("manager-tile-foot");
		let text = new Sedulous.GUI.Panel();
		text.AddClass("manager-text");
		Adopt(text, Text(NameOf(card), "manager-name"));
		let subtitle = scope String(card.EngineVersion);
		if (card.Missing)
			subtitle.Append(", missing");
		else if (card.Newer)
			subtitle.Append(", newer engine");
		Adopt(text, Text(subtitle, "manager-path"));
		Adopt(foot, text);
		Adopt(foot, MoreButton(card.Path));
		Adopt(tile, foot);
		return tile;
	}
}
