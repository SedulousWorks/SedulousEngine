using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.UI;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The project manager screen, built into the single editor executable: shown at startup
/// when no project was given on the command line, and returned to by File > Close Project.
/// No selection state: New Project and Open Folder sit at the top, always available; below,
/// every recent project is a card carrying its own Open and Remove, and an empty list shows
/// a friendly empty state. Rows are live-probed on every Rebuild, so a missing manifest
/// renders dim without Open and a newer-engine stamp renders amber. Everything with
/// project consequences goes through callbacks the application binds and defers through the
/// UI mutation queue, since opening detaches this view mid dispatch.
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

		// The header: the product name and the engine version, since the manager is the
		// version disambiguator.
		{
			let header = new FlexLayout();
			header.Direction = .Horizontal;
			header.Spacing = 12;
			let title = new Label("Editor");
			title.FontSize.Value = 24.0f;
			header.AddView(title);
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

		{
			let caption = new Label("Recent projects");
			caption.FontSize.Value = 13.0f;
			caption.TextColor.Value = Color(0.72f, 0.72f, 0.72f, 1.0f);
			column.AddView(caption);
		}

		// The card list: a vertical column inside a scroll view; rows are rebuilt whole.
		mListColumn = new FlexLayout();
		mListColumn.Direction = .Vertical;
		mListColumn.Spacing = 6;
		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		scroll.HScrollBarPolicy.Value = .Never;
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

	/// Re-reads the registry, live-probes every entry, and rebuilds the card list. On every
	/// return to the manager; registry mutations queue a rebuild themselves.
	public void Rebuild()
	{
		mListColumn.RemoveAllViews();

		let reg = mController.Entries;
		if (reg.Entries.IsEmpty)
		{
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
			let name = scope String(entry.Name);
			let engineVersion = scope String(entry.EngineVersion);
			bool missing = false;
			EngineVersionRelation relation = .Same;
			let probed = scope ProjectSettings();
			if (ProjectRegistry.ProbeProject(entry.Path, probed) case .Ok)
			{
				name.Set(probed.Name);
				engineVersion.Set(probed.EngineVersion);
				relation = ProjectRegistry.CompareProjectEngineVersion(probed.EngineVersion);
			}
			else
			{
				missing = true;
			}
			AddRow(entry.Path, name, engineVersion, relation, missing);
		}
	}

	private void AddRow(StringView path, StringView name, StringView engineVersion, EngineVersionRelation relation, bool missing)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 10;
		row.Padding = .(10, 8);

		// The left block: the name line with its state suffix over the dim path line.
		let text = new FlexLayout();
		text.Direction = .Vertical;
		text.Spacing = 2;
		{
			let title = scope String(name.IsEmpty ? "(unnamed)" : name);
			if (!engineVersion.IsEmpty)
			{
				title.Append("   ");
				title.Append(engineVersion);
			}
			if (missing)
				title.Append("   (missing)");
			else if (relation == .ProjectNewer)
				title.Append("   (newer engine)");
			let nameLabel = new Label(title);
			nameLabel.FontSize.Value = 14.0f;
			nameLabel.TextColor.Value = missing ? Color(0.5f, 0.5f, 0.5f, 1.0f)
				: (relation == .ProjectNewer) ? Color(0.95f, 0.75f, 0.3f, 1.0f)
				: Color(0.9f, 0.9f, 0.9f, 1.0f);
			text.AddView(nameLabel);

			let pathLabel = new Label(path);
			pathLabel.FontSize.Value = 11.0f;
			pathLabel.TextColor.Value = Color(0.5f, 0.5f, 0.5f, 1.0f);
			text.AddView(pathLabel);
		}
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		row.AddView(text, grow);

		if (!missing)
		{
			let open = new Button("Open");
			let openPath = new String(path);
			open.OnClick.Add(new [=openPath, =this](b) => { if (OnOpenProject != null) OnOpenProject(openPath); } ~ delete openPath);
			row.AddView(open);
		}
		let remove = new Button("Remove");
		let removePath = new String(path);
		remove.OnClick.Add(new [=removePath, =this](b) => { RemoveEntry(removePath); } ~ delete removePath);
		row.AddView(remove);

		// The card surface: a themed Panel, the stylesheet's "panel" class, so rows read as
		// cards against the window background.
		let card = new Panel();
		card.StyleClasses.Add(new String("panel"));
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		card.AddView(row, match);
		mListColumn.AddView(card, match);
	}

	private void RemoveEntry(StringView path)
	{
		if (!mController.Remove(path))
			return;
		if (OnStoreChanged != null)
			OnStoreChanged();
		// The Remove button lives in the row the rebuild destroys: deferred, never a tree
		// mutation mid dispatch.
		mUiContext.MutationQueue.QueueAction(new () => { Rebuild(); });
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
