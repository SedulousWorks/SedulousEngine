using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.UI;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// The project manager screen, built into the single editor executable: shown at startup
/// when no project was given on the command line, and returned to by File > Close Project.
/// No selection state: New Project and Open Folder sit at the top, always available; below,
/// the recent projects as a list or a grid (remembered), each by its picture: the thumbnail
/// the editor captures of its default scene, or an image chosen for it, else its initial. A
/// row carries Open and a "more" menu (Show in Folder, Copy Path, the thumbnail, Remove); a
/// grid tile opens on a click and shows its name, engine and path with those actions in an
/// interactive tooltip. An empty list shows a friendly empty state. Projects are live-probed
/// on every Rebuild, so a missing manifest renders dim without Open and a newer-engine stamp
/// renders amber. Everything with project consequences goes through callbacks the
/// application binds and defers through the UI mutation queue, since opening detaches this
/// view mid dispatch.
class ProjectManagerView
{
	/// Open an existing project; the app runs the version gate. Owned.
	public delegate void(StringView directory) OnOpenProject ~ delete _;
	/// Scaffold and open a new project at the directory. Owned.
	public delegate void(StringView directory, StringView name) OnCreateProject ~ delete _;
	/// The registry changed; persist the settings store. Owned.
	public delegate void() OnStoreChanged ~ delete _;

	private ProjectManagerController mController = null;
	private IDialogService mDialogs = null;
	private UIContext mUiContext = null;
	private RootView mRoot = null ~ { if (_ != null) _.ReleaseRef(); };
	// Borrowed: the tree owns them.
	private FlexLayout mListColumn = null;
	private Label mStatus = null;
	private ViewModeToggles mViewToggles = null;
	/// The logo heading the screen (EditorSplash.LoadLogo), borrowed; null shows the name.
	private Drawable mLogo = null;
	/// The pictures the shown projects' views borrow; cleared with the views.
	private List<Image> mThumbnails = new .() ~ DeleteContainerAndItems!(_);
	/// The projects shown, as last probed.
	private List<Card> mShownCards = new .() ~ DeleteContainerAndItems!(_);

	/// One recent project as the launcher shows it.
	private class Card
	{
		public String Path = new .() ~ delete _;
		public String Name = new .() ~ delete _;
		public String EngineVersion = new .() ~ delete _;
		public EngineVersionRelation Relation = .Same;
		public bool Missing = false;
	}

	/// A tile's picture: a click opens the project, a hover shows TileTooltipFor.
	private class TileButton : Button, ITooltipProvider
	{
		/// Borrowed: the view outlives its tiles.
		private ProjectManagerView mOwner;
		private String mPath = new .() ~ delete _;

		public this(ProjectManagerView owner, StringView path) : base("")
		{
			mOwner = owner;
			mPath.Set(path);
			IsTooltipInteractive = true;
		}

		public override ITooltipProvider AsTooltipProvider() => this;
		public View CreateTooltipContent() => mOwner.TileTooltipFor(mPath);
	}

	/// `logo` (EditorSplash.LoadLogo) heads the screen, borrowed; null shows the name as text.
	public this(Drawable logo = null)
	{
		mLogo = logo;
	}

	public void Build(ProjectManagerController controller, IDialogService dialogs, UIContext uiContext,
		uint32 width, uint32 height)
	{
		mController = controller;
		mDialogs = dialogs;
		mUiContext = uiContext;
		mRoot = new RootView();
		mRoot.ViewportSize = .((float)width, (float)height);
		mRoot.DpiScale = 1.0f;

		// A centred fixed-width column: spacer, column 720, spacer.
		let outer = new FlexLayout();
		outer.Direction = .Horizontal;
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 12;
		column.Padding = .(0, 28);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		outer.AddView(new FlexLayout(), grow);
		var middle = LayoutStyle();
		middle.Width = SizeSpec.Fixed(Unit.Dp(720.0f));
		middle.Height = SizeSpec.Match();
		outer.AddView(column, middle);
		outer.AddView(new FlexLayout(), grow);

		// The header: the logo (else the name) and the engine version, since the manager is
		// the version disambiguator.
		{
			let header = new FlexLayout();
			header.Direction = .Horizontal;
			header.Spacing = 12;
			header.AlignItems = .Center;
			if (mLogo != null)
			{
				const float cLogoHeight = 44.0f;
				mLogo.AddRef(); // the view's reference
				header.AddView(new DrawableView(mLogo, cLogoHeight * EditorSplash.cEditorLogoAspect, cLogoHeight));
			}
			else
			{
				let title = new Label("SedulousEngine");
				title.FontSize.Value = 24.0f;
				header.AddView(title);
			}
			let version = new Label(scope $"engine {EngineVersion.String}");
			version.FontSize.Value = 12.0f;
			version.TextColor.Value = Color(0.55f, 0.55f, 0.55f, 1.0f);
			header.AddView(version);
			column.AddView(header);
		}

		// The standalone entry points, independent of the list below.
		{
			let actions = new FlexLayout();
			actions.Direction = .Horizontal;
			actions.Spacing = 8;
			let create = new Button("New Project...");
			create.OnClick.Add(new (b) => { ShowCreateDialog(); });
			actions.AddView(create);
			let browse = new Button("Open Folder...");
			browse.OnClick.Add(new (b) => { BrowseAndOpen(); });
			actions.AddView(browse);
			column.AddView(actions);
		}

		// "Recent projects", and the List and Grid toggle (remembered with the projects).
		{
			let bar = new FlexLayout();
			bar.Direction = .Horizontal;
			bar.AlignItems = .Center;
			let caption = new Label("Recent projects");
			caption.FontSize.Value = 13.0f;
			caption.TextColor.Value = Color(0.72f, 0.72f, 0.72f, 1.0f);
			var captionGrow = LayoutStyle();
			captionGrow.FlexGrow = 1.0f;
			bar.AddView(caption, captionGrow);
			mViewToggles = new ViewModeToggles();
			mViewToggles.SetGridMode(mController.GridView);
			mViewToggles.OnModeChanged = new (grid) => { SetGridView(grid); };
			bar.AddView(mViewToggles);
			var barWidth = LayoutStyle();
			barWidth.Width = SizeSpec.Match();
			column.AddView(bar, barWidth);
		}

		// The projects: rows, or tiles that wrap; rebuilt whole.
		mListColumn = new FlexLayout();
		mListColumn.Direction = .Vertical;
		mListColumn.Spacing = 6;
		mListColumn.Padding = .(0, 0, 8, 0); // a gap before the scroll bar
		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		scroll.HScrollBarPolicy.Value = .Never;
		// The bar takes its own room beside the projects rather than lying over them.
		scroll.ScrollBarMode.Value = .Reserved;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		scroll.AddView(mListColumn, match);
		var fill = LayoutStyle();
		fill.Width = SizeSpec.Match();
		fill.FlexGrow = 1.0f;
		column.AddView(scroll, fill);

		mStatus = new Label();
		mStatus.FontSize.Value = 12.0f;
		mStatus.TextColor.Value = Color(0.7f, 0.7f, 0.7f, 1.0f);
		column.AddView(mStatus);

		mRoot.AddView(outer);
		Rebuild();
	}

	public RootView Root => mRoot;

	public void SetStatus(StringView text) => mStatus.SetText(text);

	/// Re-reads the registry, live-probes every entry, and rebuilds the projects as rows or
	/// tiles. On every return to the manager; registry mutations queue a rebuild themselves.
	public void Rebuild()
	{
		mListColumn.RemoveAllViews();
		ClearAndDeleteItems(mThumbnails); // the views showing them went with the rows
		ClearAndDeleteItems(mShownCards);
		let grid = mController.GridView;
		mListColumn.Direction = grid ? .Horizontal : .Vertical;
		mListColumn.Wrap = grid;
		mListColumn.Spacing = grid ? 14 : 6;
		mListColumn.LineSpacing = grid ? 14 : 0; // between the grid's rows

		let reg = mController.Entries;
		if (reg.Entries.IsEmpty)
		{
			mListColumn.Direction = .Vertical;
			let empty = new Label("No projects yet. Create a new project, or open an existing project folder.");
			empty.FontSize.Value = 13.0f;
			empty.TextColor.Value = Color(0.5f, 0.5f, 0.5f, 1.0f);
			empty.WordWrap.Value = true;
			let pad = new FlexLayout();
			pad.Padding = .(4, 16);
			pad.AddView(empty);
			mListColumn.AddView(pad);
			return;
		}

		for (let entry in reg.Entries)
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
				card.Relation = ProjectRegistry.CompareProjectEngineVersion(probed.EngineVersion);
			}
			else
				card.Missing = true;
			mShownCards.Add(card);
			if (grid)
				AddTile(card);
			else
				AddRow(card);
		}
	}

	/// For tests: the layout shown, the projects shown, and how many show their picture.
	public bool IsGridView => mController.GridView;
	public int CardCount => mShownCards.Count;
	public int ThumbnailCount => mThumbnails.Count;

	/// Shows the projects as a grid (else a list), remembered with them.
	public void SetGridView(bool grid)
	{
		if (grid == mController.GridView)
			return;
		mController.SetGridView(grid);
		if (mViewToggles != null)
			mViewToggles.SetGridMode(grid);
		if (OnStoreChanged != null)
			OnStoreChanged();
		QueueRebuild();
	}

	/// The menu's items for a project, as its "more" button shows them, appended.
	public void MenuItemsFor(StringView path, List<StringView> outItems)
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

	/// Uses `image` (any picture the editor reads) as the project's thumbnail, saved as a PNG
	/// in its editor folder. False when it does not read.
	public bool SetThumbnailFromImage(StringView projectPath, StringView image)
	{
		let picture = scope Image();
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
		QueueRebuild();
		return true;
	}

	/// What a grid tile shows on hover for the project at `path`: the whole name, the engine it
	/// was made with (or why it will not open) and the path the tile has no room for, with the
	/// actions worth a click from there. Interactive, so the pointer can reach its buttons. The
	/// caller's view; null when no card shows the project.
	public View TileTooltipFor(StringView path)
	{
		Card card = null;
		for (let shown in mShownCards)
		{
			if (shown.Path == path)
				card = shown;
		}
		if (card == null)
			return null;
		let tip = new FlexLayout();
		tip.Direction = .Vertical;
		tip.Spacing = 3;
		tip.Padding = .(2, 2);
		let name = new Label(card.Name.IsEmpty ? "(unnamed)" : StringView(card.Name));
		name.FontSize.Value = 14.0f;
		name.TextColor.Value = TitleColor(card);
		tip.AddView(name);
		let detail = scope String();
		if (card.Missing)
			detail.Set("Missing: there is no project in this folder now");
		else
		{
			if (card.EngineVersion.IsEmpty)
				detail.Set("Engine version unknown");
			else
				detail.AppendF("Engine {}", card.EngineVersion);
			if (card.Relation == .ProjectNewer)
				detail.Append(", newer than this editor");
		}
		let detailLabel = new Label(detail);
		detailLabel.FontSize.Value = 11.5f;
		detailLabel.TextColor.Value = Color(0.6f, 0.6f, 0.6f, 1.0f);
		tip.AddView(detailLabel);
		let pathLabel = new Label(card.Path);
		pathLabel.FontSize.Value = 11.5f;
		pathLabel.TextColor.Value = Color(0.75f, 0.75f, 0.75f, 1.0f);
		tip.AddView(pathLabel);

		let actions = new FlexLayout();
		actions.Direction = .Horizontal;
		actions.Spacing = 6;
		actions.Padding = .(0, 6, 0, 0);
		StringView[3] items = .("Open", "Show in Folder", "Copy Path");
		for (let item in items)
		{
			if ((item == "Open") && card.Missing)
				continue;
			let button = new Button(item);
			let projectPath = new String(card.Path);
			let which = new String(item);
			button.OnClick.Add(new [=this, =projectPath, =which](b) => { RunCardMenuItem(projectPath, which); } ~ { delete projectPath; delete which; });
			var height = LayoutStyle();
			height.Height = SizeSpec.Fixed(Unit.Dp(26.0f));
			actions.AddView(button, height);
		}
		tip.AddView(actions);
		return tip;
	}

	/// The card's title colour: missing dims, a newer engine warns.
	private static Color TitleColor(Card card)
	{
		return card.Missing ? Color(0.5f, 0.5f, 0.5f, 1.0f)
			: (card.Relation == .ProjectNewer) ? Color(0.95f, 0.75f, 0.3f, 1.0f)
			: Color(0.9f, 0.9f, 0.9f, 1.0f);
	}

	/// The tile's line under the name: the engine, and what is wrong, if anything.
	private static void Subtitle(Card card, String outText)
	{
		outText.Append(card.EngineVersion);
		if (card.Missing)
			outText.Append(outText.IsEmpty ? "missing" : " \u{00b7} missing");
		else if (card.Relation == .ProjectNewer)
			outText.Append(" \u{00b7} newer engine");
	}

	/// The project's picture (its thumbnail, else a tile with its initial), `w` x `h`.
	private View Picture(Card card, float w, float h, float radius) =>
		ProjectPicture.Make(card.Missing ? "" : StringView(card.Path), card.Name, w, h, radius, mThumbnails);

	/// The "more" button: the project's menu.
	private IconButton MoreButton(Card card)
	{
		let more = new IconButton(EditorIcons.More, 16.0f);
		more.TooltipText.Set("More for this project");
		// A button's surface, so it reads as one beside Open: a quiet rounded fill.
		let look = new StateListDrawable();
		look.Set(.Normal, new RoundedRectDrawable(Color(1.0f, 1.0f, 1.0f, 0.045f), 4.0f));
		look.Set(.Hover, new RoundedRectDrawable(Color(1.0f, 1.0f, 1.0f, 0.09f), 4.0f));
		look.Set(.Pressed, new RoundedRectDrawable(Color(1.0f, 1.0f, 1.0f, 0.13f), 4.0f));
		more.SetStyle(.Background, look);
		let path = new String(card.Path);
		more.OnClick.Add(new [=this, =path, =more](b) => { ShowCardMenu(path, more); } ~ delete path);
		return more;
	}

	private void OpenCard(StringView path)
	{
		if (OnOpenProject != null)
			OnOpenProject(path);
	}

	private void AddRow(Card card)
	{
		const float cButtonHeight = 28.0f;
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.AlignItems = .Center;
		row.Spacing = 12;
		row.Padding = .(10, 8);
		row.AddView(Picture(card, 76.0f, 43.0f, 4.0f));

		// The name (and what is wrong with the project, if anything) over the dim path; both
		// take only the room left and end in an ellipsis rather than run under the buttons.
		let text = new FlexLayout();
		text.Direction = .Vertical;
		text.Spacing = 2;
		{
			var line = LayoutStyle();
			line.Width = SizeSpec.Match();
			let title = scope String(card.Name.IsEmpty ? "(unnamed)" : StringView(card.Name));
			if (card.Missing)
				title.Append("   (missing)");
			else if (card.Relation == .ProjectNewer)
				title.Append("   (newer engine)");
			let nameLabel = new Label(title);
			nameLabel.FontSize.Value = 14.0f;
			nameLabel.Ellipsis.Value = true;
			nameLabel.TextColor.Value = TitleColor(card);
			text.AddView(nameLabel, line);

			let pathLabel = new Label(card.Path);
			pathLabel.FontSize.Value = 11.0f;
			pathLabel.Ellipsis.Value = true;
			pathLabel.TooltipText.Set(card.Path);
			pathLabel.TextColor.Value = Color(0.5f, 0.5f, 0.5f, 1.0f);
			text.AddView(pathLabel, line);
		}
		var rest = LayoutStyle(); // no width of its own (basis 0): the room the others leave
		rest.FlexBasis = Unit.Dp(0.0f);
		rest.FlexGrow = 1.0f;
		row.AddView(text, rest);

		// The engine version in its own column, so the rows' versions line up.
		{
			let version = new Label(card.EngineVersion);
			version.FontSize.Value = 11.5f;
			version.HAlign.Value = .Right;
			version.TextColor.Value = Color(0.55f, 0.55f, 0.55f, 1.0f);
			var fixedWidth = LayoutStyle();
			fixedWidth.Width = SizeSpec.Fixed(Unit.Dp(56.0f));
			row.AddView(version, fixedWidth);
		}

		var button = LayoutStyle();
		button.Height = SizeSpec.Fixed(Unit.Dp(cButtonHeight));
		if (!card.Missing)
		{
			let open = new Button("Open");
			let path = new String(card.Path);
			open.OnClick.Add(new [=this, =path](b) => { OpenCard(path); } ~ delete path);
			var wide = button;
			wide.Width = SizeSpec.Fixed(Unit.Dp(64.0f));
			row.AddView(open, wide);
		}
		var square = button; // as tall as Open
		square.Width = SizeSpec.Fixed(Unit.Dp(cButtonHeight));
		row.AddView(MoreButton(card), square);

		// The card surface: a themed Panel, the stylesheet's "panel" class, so rows read as
		// cards against the window background.
		let surface = new Panel();
		surface.AddClass("panel");
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		surface.AddView(row, match);
		mListColumn.AddView(surface, match);
	}

	/// A tile: the project's picture, then its name and engine with the "more" button; a click
	/// on the picture opens it.
	private void AddTile(Card card)
	{
		// Three to a row in the launcher's 720 px column, less the scroll bar and its gap.
		const float cTileWidth = 220.0f;
		const float cPictureHeight = 115.0f; // the picture 204 wide: about 16:9
		let tile = new FlexLayout();
		tile.Direction = .Vertical;
		tile.Spacing = 6;
		tile.Padding = .(8, 8);

		let picture = new TileButton(this, card.Path);
		picture.SetStyle(.Padding, Thickness(0.0f, 0.0f));
		picture.SetStyle(.Background, new RoundedRectDrawable(Color(0, 0, 0, 0), 6.0f));
		// The tile shows no path, so its tooltip does (two projects of one name tell apart). A
		// missing project's picture stays enabled for that tooltip (Show in Folder and Copy
		// Path still apply), and a click on it does nothing.
		if (!card.Missing)
		{
			let path = new String(card.Path);
			picture.OnClick.Add(new [=this, =path](b) => { OpenCard(path); } ~ delete path);
		}
		let pictureStack = new Panel();
		pictureStack.AddView(Picture(card, cTileWidth - 16.0f, cPictureHeight, 6.0f));
		pictureStack.AddView(picture); // the click target over the picture
		tile.AddView(pictureStack);

		let line = new FlexLayout();
		line.Direction = .Horizontal;
		line.AlignItems = .Center;
		line.Spacing = 6;
		let text = new FlexLayout();
		text.Direction = .Vertical;
		text.Spacing = 1;
		let nameLabel = new Label(card.Name.IsEmpty ? "(unnamed)" : StringView(card.Name));
		nameLabel.FontSize.Value = 13.5f;
		nameLabel.Ellipsis.Value = true;
		nameLabel.TooltipText.Set(card.Path);
		nameLabel.TextColor.Value = TitleColor(card);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		text.AddView(nameLabel, match);
		let sub = new Label(Subtitle(card, .. scope .()));
		sub.FontSize.Value = 11.0f;
		sub.TextColor.Value = Color(0.55f, 0.55f, 0.55f, 1.0f);
		text.AddView(sub);
		var grow = LayoutStyle(); // the room the "more" button leaves (basis 0), names cut short
		grow.FlexBasis = Unit.Dp(0.0f);
		grow.FlexGrow = 1.0f;
		line.AddView(text, grow);
		line.AddView(MoreButton(card));
		tile.AddView(line, match);

		let surface = new Panel();
		surface.AddClass("panel");
		surface.AddView(tile);
		var fixedWidth = LayoutStyle();
		fixedWidth.Width = SizeSpec.Fixed(Unit.Dp(cTileWidth));
		mListColumn.AddView(surface, fixedWidth);
	}

	private void ShowCardMenu(StringView path, View anchor)
	{
		if (mUiContext == null)
			return;
		let menu = new ContextMenu();
		let items = scope List<StringView>();
		MenuItemsFor(path, items);
		for (let item in items)
		{
			if (item == "Remove from List")
				menu.AddSeparator();
			let projectPath = new String(path);
			let which = new String(item);
			menu.AddItem(item, new [=this, =projectPath, =which]() => { RunCardMenuItem(projectPath, which); } ~ { delete projectPath; delete which; });
		}
		let at = anchor.LocalToScreen(.(0.0f, anchor.Height));
		menu.Show(mUiContext, at.X, at.Y);
		menu.ReleaseRef();
	}

	private void RunCardMenuItem(StringView path, StringView item)
	{
		if (item == "Open")
			OpenCard(path);
		else if (item == "Show in Folder")
		{
			if (mDialogs != null)
				mDialogs.OpenPath(path);
		}
		else if (item == "Copy Path")
		{
			if ((mUiContext != null) && (mUiContext.Clipboard != null))
			{
				mUiContext.Clipboard.SetText(path);
				SetStatus("Copied the project's path.");
			}
		}
		else if (item == "Choose Thumbnail Image...")
		{
			if (mDialogs == null)
				return;
			FileFilter[1] images = .(.("Images", "png;jpg;jpeg;bmp;tga"));
			let projectPath = new String(path);
			mDialogs.ShowOpenFile(new [=this, =projectPath](paths) =>
				{
					if (paths.Length > 0) // none: cancelled
						SetThumbnailFromImage(projectPath, paths[0]);
				} ~ delete projectPath, images, "", false, 0);
		}
		else if (item == "Clear Thumbnail")
		{
			DeleteFile(EditorProject.ThumbnailPath(path, .. scope .()));
			QueueRebuild();
		}
		else if (item == "Remove from List")
			RemoveEntry(path);
	}

	/// Rebuilds after the click that asked for it is over (the clicked view is in what the
	/// rebuild destroys); at once when not in an interface yet (tests).
	private void QueueRebuild()
	{
		if (mUiContext == null)
		{
			Rebuild();
			return;
		}
		mUiContext.MutationQueue.QueueAction(new [=this]() => { Rebuild(); });
	}

	private void RemoveEntry(StringView path)
	{
		if (!mController.Remove(path))
			return;
		if (OnStoreChanged != null)
			OnStoreChanged();
		// The menu that asked lives in the row the rebuild destroys: deferred, never a tree
		// mutation mid dispatch.
		QueueRebuild();
	}

	private void BrowseAndOpen()
	{
		if (mDialogs == null)
			return;
		mDialogs.ShowOpenFolder(new (paths) =>
			{
				if (paths.Length == 0)
					return; // cancelled
				let probed = scope ProjectSettings();
				if (ProjectRegistry.ProbeProject(paths[0], probed) case .Err)
				{
					SetStatus("Not a project (no Project.xml there). Use New Project to start one.");
					return;
				}
				if (OnOpenProject != null)
					OnOpenProject(paths[0]);
			}, "", false, 0);
	}

	private void ShowCreateDialog()
	{
		let dialog = new Dialog("New Project");
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;

		let nameEdit = new EditText();
		nameEdit.Placeholder.Value.Set("Project name");
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(nameEdit, match);

		let dirRow = new FlexLayout();
		dirRow.Direction = .Horizontal;
		dirRow.Spacing = 6;
		let dirEdit = new EditText();
		dirEdit.Placeholder.Value.Set("Parent directory (the project is created inside it)");
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		dirRow.AddView(dirEdit, grow);
		let browse = new Button("Browse...");
		browse.OnClick.Add(new [=dirEdit, =this](b) =>
			{
				if (mDialogs == null)
					return;
				mDialogs.ShowOpenFolder(new [=dirEdit](paths) =>
					{
						if (paths.Length > 0)
							dirEdit.SetText(paths[0]);
					}, "", false, 0);
			});
		dirRow.AddView(browse);
		column.AddView(dirRow, match);
		dialog.SetContent(column);
		dialog.MinWidth.Value = 460.0f;

		let create = dialog.AddButton("Create", .None);
		create.OnClick.Add(new [=dialog, =nameEdit, =dirEdit, =this](b) =>
			{
				let name = nameEdit.Text;
				let parent = dirEdit.Text;
				if (name.IsEmpty || parent.IsEmpty)
					return; // both required; the dialog stays up
				dialog.Close(.OK);
				if (OnCreateProject != null)
					OnCreateProject(PathJoin(parent, name, .. scope .()), name);
			});
		dialog.AddButton("Cancel", .Cancel);
		dialog.Show(mUiContext);
	}
}
