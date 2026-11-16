using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.App;

// Export: Project > Export, a window over its markup
// (Data/Editor/Export.xml). The project's export presets on the left (add, duplicate, remove after
// asking), each by the icon of the template it resolves to here, warned of when none does; the
// selected one on the right under a card naming the template it exports with, or saying why there
// is none, its settings on the property grid as Project Settings' are: a section per
// category (General: its name, template, platform, config, player and output folder; Content: the
// extra files as a list, symbols, pruning, shader source; Display: its own render size, window and
// orientation, each shown only when the preset overrides it). A template picked by name decides
// the platform and config. Edits apply as they are made and are saved when the selection moves, an
// export starts or it closes. Export runs the selected preset, Export All every one; Export
// Templates opens that window over this one, and the card follows what it changed. What it needs
// from outside comes through ExportDialogSeams, so a test drives it without a window system.

/// A preset field that names a file: its path, typed or picked with Browse. The dialog decides how
/// Browse picks (the editor's picker for a file of the project's, the system's dialog for one kept
/// outside it), given the row's path.
class ExportPathEditor : PropertyEditor
{
	public const String cHint = "exportPath";

	private delegate void(StringView row) mBrowse ~ delete _;
	private TextField mField ~ _.ReleaseRef();
	private Sedulous.GUI.Button mButton ~ _.ReleaseRef();

	/// Takes `browse`, told the row's path when Browse is pressed.
	public this(delegate void(StringView row) browse)
	{
		mBrowse = browse;
		AddClass("export-path");
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Center;
				s.ColumnGap = 6.0f;
			});
		mField = new TextField();
		mField.EditLayoutStyle(scope (s) =>
			{
				s.Grow = 1.0f;
				s.Shrink = 1.0f;
				s.MinWidth = .Px(0.0f);
			});
		mField.SetOnTextChanged(new [=this] (text) => { ApplyEdit(PropertyWrite(Sedulous.GUI.Variant(text))); });
		AddChild(mField);
		mButton = new Sedulous.GUI.Button();
		mButton.Text = "Browse...";
		mButton.SetOnClick(new [=this] () =>
			{
				if (mBrowse != null)
					mBrowse(Path);
			});
		AddChild(mButton);
	}

	public override bool IsTyping => mField.IsFocused;
	public TextField Field => mField;
	public Sedulous.GUI.Button BrowseButton => mButton;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mField.Text = value.Value.AsString;
		mField.IsReadOnly = IsReadOnly;
		mButton.Enabled = !IsReadOnly;
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mField);
		ShareTextStyle(mButton);
	}
}

/// What the export dialog asks of the application. Every delegate is owned.
class ExportDialogSeams
{
	/// Appends the project's quality levels, in its order: the ones a preset may start at. The
	/// dialog owns what it appends.
	public delegate void(List<ProjectQualityLevel> outLevels) QualityLevels ~ delete _;
	/// Fills the registry with the templates this host sees.
	public delegate void(TemplateRegistry registry) Refresh ~ delete _;
	/// Persists the presets (the controller the dialog edits) to the project.
	public delegate void() Save ~ delete _;
	/// Runs the export of one preset by name, or of every preset (`all`).
	public delegate void(StringView preset, bool all) RunExport ~ delete _;
	/// Opens Export Templates over this one. TAKES OWNERSHIP of `closed`, told when it closes.
	public delegate void(delegate void() closed) OpenTemplates ~ delete _;
	/// Asks for files anywhere on the machine (the system's dialog). TAKES OWNERSHIP of `chosen`
	/// and calls it exactly once: with the files, or none when the user cancels.
	public delegate void(delegate void(Span<String> files) chosen) PickFiles ~ delete _;
	/// Opens the editor's picker for `request` (a project file, through PathPicker). OWNERSHIP of
	/// `request` transfers.
	public delegate void(PickerRequest request) Pick ~ delete _;
	/// Tells the user something the dialog refused ("is outside the project").
	public delegate void(StringView message) Notify ~ delete _;
	/// The project's folder, absolute: the files a preset ships are under it, named relative to it.
	public String ProjectRoot = new .() ~ delete _;
	/// The host's platform, a new preset's.
	public String HostPlatform = new .() ~ delete _;
	/// Where exports are written, said under the presets.
	public String OutputRoot = new .() ~ delete _;
}

class ExportDialog
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/Export.xml";
	private const float cWidth = 820.0f;
	private const float cHeight = 540.0f;
	private const String cDot = " · ";
	private const String cGeneral = "General";
	private const String cContent = "Content";
	private const String cDisplay = "Display";
	private const String cAndroid = "Android";

	/// The presets as the list's model.
	private class Model : IModel
	{
		private ExportDialog mDialog;

		public this(ExportDialog dialog) { mDialog = dialog; }

		public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mDialog.mPresets.Count;
		public override int ColumnCount() => 1;

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			if ((role != .Display) || (index.Row < 0) || (index.Row >= mDialog.mPresets.Count))
				return .();
			return .(mDialog.mPresets.At(index.Row).Name);
		}

		public void Reset() => NotifyReset();
		public void Changed(int32 row) => NotifyRowsChanged(.(), row, 1);
	}

	/// Borrowed: the application's (EditorExport's), which outlives the dialog.
	private ExportPresetsController mPresets;
	private ExportDialogSeams mSeams ~ delete _;
	/// A reference of ours (the window holds its own). Declared first: it goes last, after the
	/// model the list it holds borrows.
	private Node mBody = null ~ _?.ReleaseRef();
	/// A reference of ours: closed, it leaves the tree, and this keeps it for the next open.
	private Sedulous.GUI.Window mWindow = null ~ _?.ReleaseRef();
	/// BORROWED: what it opened over (its confirms open there too).
	private Node mRoot = null;
	private TemplateRegistry mRegistry = new .() ~ delete _;
	/// One reference each, by template id and folder.
	private Dictionary<String, Sedulous.GUI.Drawable> mIcons = new .() ~ { ClearIcons(_); delete _; };
	/// The selected preset's rows, the grid's source; null with none.
	private Sedulous.GUI.PropertyBag mBag = null ~ delete _;
	/// The platform row's choices, by index, and the config row's.
	private List<String> mPlatforms = new .() ~ DeleteContainerAndItems!(_);
	/// The quality row's levels, by its index less one.
	private List<ProjectQualityLevel> mQualityLevels = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mConfigs = new .() ~ DeleteContainerAndItems!(_);
	/// The question Remove asks, while it is asked (a reference of ours).
	private MessageBox mAsking = null ~ _?.ReleaseRef();
	// The body's: the tree holds them.
	private ListView mList = null;
	private PropertyGrid mGrid = null;
	private Sedulous.GUI.Button mExport = null;
	private Sedulous.GUI.Button mDuplicate = null;
	private Sedulous.GUI.Button mRemove = null;
	/// Edited since the last save.
	private bool mDirty = false;
	private Model mModel ~ delete _;

	/// The dialog over `body` (the markup's controls by id), editing `presets` (borrowed: it
	/// outlives the dialog). TAKES OWNERSHIP of the seams and of a reference to `body`; null makes a
	/// dialog that never opens.
	public this(ExportPresetsController presets, ExportDialogSeams seams, Node body)
	{
		mPresets = presets;
		mSeams = seams;
		mBody = body;
		mModel = new Model(this);
		if (mBody == null)
			return;
		mWindow = new Sedulous.GUI.Window();
		mWindow.Title = "Export";
		mWindow.AddClass("export-window");
		mWindow.Size = .(cWidth, cHeight);
		mWindow.Content.AddChild(mBody);
		mList = Find<ListView>("export-list");
		if (mList != null)
		{
			let rows = new RowFactory();
			rows.Create = new (type) => new TemplateRow();
			rows.Bind = new (row, index) => { BindRow(row, index.Row); };
			mList.SetRowFactory(rows);
			mList.Model = mModel;
			mList.SetOnSelectionChanged(new (index) =>
				{
					Save(); // the one left is kept
					Load();
				});
		}
		mGrid = Find<PropertyGrid>("export-grid");
		// A file a preset names (the Android app's icon and keystore): typed, or picked with Browse.
		if (mGrid != null)
			mGrid.Editors.RegisterHint(ExportPathEditor.cHint, new [=this] () => new ExportPathEditor(new [=this] (row) => { Browse(row); }));
		mExport = Find<Sedulous.GUI.Button>("export-run");
		mDuplicate = Find<Sedulous.GUI.Button>("export-duplicate");
		mRemove = Find<Sedulous.GUI.Button>("export-remove");
		OnClick("export-add", new () => { AddPreset(); });
		OnClick("export-duplicate", new () => { DuplicateSelected(); });
		OnClick("export-remove", new () => { RemoveSelected(); });
		OnClick("export-run", new () => { ExportSelected(); });
		OnClick("export-all", new () => { ExportAll(); });
		OnClick("export-close", new () => { Close(); });
		OnClick("export-add-files", new () => { AddFiles(); });
		OnClick("export-add-disk", new () => { AddFilesFromDisk(); });
		OnClick("export-templates", new () =>
			{
				if (mSeams.OpenTemplates != null)
					mSeams.OpenTemplates(new () => { RefreshTemplates(); });
			});
		if (let outputNote = Find<Sedulous.GUI.Label>("export-where"))
			outputNote.Text = scope $"Exports go to {mSeams.OutputRoot}";
		// However it closes, what was edited is kept.
		mWindow.SetOnClose(new () => { Save(); });
	}

	/// The body may outlive this: what of it calls back here goes first.
	public ~this()
	{
		if ((mAsking != null) && mAsking.IsOpen)
			mAsking.Close();
		Close();
		// The grid may outlive this (the window's exit playing): it lets go of the bag first.
		if (mGrid != null)
			mGrid.Source = null;
		if (mList != null)
		{
			mList.Model = null;
			mList.SetRowFactory(null);
		}
	}

	/// Opens it over `root`, the templates read again and the first preset selected; false with no
	/// markup or one open.
	public bool Open(Node root)
	{
		if ((mWindow == null) || mWindow.IsOpen)
			return false;
		mRoot = root;
		if (mSeams.Refresh != null)
			mSeams.Refresh(mRegistry);
		ClearIcons(mIcons);
		mModel.Reset();
		Select(0);
		mWindow.OpenModal(root);
		return true;
	}

	public bool IsOpen => (mWindow != null) && mWindow.IsOpen;

	public void Close()
	{
		if (IsOpen)
			mWindow.Close();
	}

	/// The presets' count and the selected one's index (-1 when there are none).
	public int PresetCount => mPresets.Count;

	public int SelectedIndex
	{
		get
		{
			let index = (mList != null) ? mList.SelectedItem : -1;
			return ((index >= 0) && (index < mPresets.Count)) ? index : -1;
		}
	}

	public void Select(int index)
	{
		Save(); // the one left is kept
		if (mList != null)
		{
			if ((index >= 0) && (index < mPresets.Count))
				mList.SelectedItem = (int32)index;
			else
				mList.ClearSelection();
		}
		Load();
	}

	/// The template the selected preset resolves to here, or null. Borrowed.
	public ExportTemplate Resolved
	{
		get
		{
			let index = SelectedIndex;
			return (index >= 0) ? mRegistry.Resolve(mPresets.At(index)) : null;
		}
	}

	/// The card's title: the template it exports with, or why there is none.
	public StringView ResolveText
	{
		get
		{
			let title = Find<Sedulous.GUI.Label>("export-card-title");
			return (title != null) ? title.Text : default;
		}
	}

	/// The card's detail line under it.
	public StringView ResolveDetail
	{
		get
		{
			let detail = Find<Sedulous.GUI.Label>("export-card-detail");
			return (detail != null) ? detail.Text : default;
		}
	}

	/// Adds a preset for the host's platform and selects it.
	public void AddPreset()
	{
		let fresh = scope ExportPreset();
		fresh.Name.Set("New Preset");
		fresh.Platform.Set(mSeams.HostPlatform);
		let index = mPresets.Add(fresh);
		mDirty = true;
		Save();
		mModel.Reset();
		Select(index);
	}

	public void DuplicateSelected()
	{
		let index = SelectedIndex;
		if (index < 0)
			return;
		let copy = mPresets.Duplicate(index);
		mDirty = true;
		Save();
		mModel.Reset();
		Select(copy);
	}

	/// Removes the selected preset once the user confirms (`confirmed` skips the question).
	public void RemoveSelected(bool confirmed = false)
	{
		let index = SelectedIndex;
		if (index < 0)
			return;
		if (!confirmed)
		{
			if ((mRoot == null) || ((mAsking != null) && mAsking.IsOpen))
				return; // nothing to ask over, or asking already
			if (mAsking != null)
				mAsking.ReleaseRef();
			let question = new MessageBox();
			mAsking = question;
			let name = new String(mPresets.At(index).Name);
			question.Configure("Remove Preset", scope $"Remove the preset '{name}'? Its settings go; what it exported stays.", .Ok);
			question.ClearButtons();
			question.AddButton("Cancel", "cancel", .Cancel);
			question.AddButton("Remove", "remove", .Destructive);
			question.AddEventListener(.Changed, new [=question, =index, =name, =this] (e) =>
				{
					// The one asked about, still the selected one.
					if ((question.ResultName == "remove") && (SelectedIndex == index) && (mPresets.At(index).Name == name))
						RemoveSelected(true);
				} ~ delete name);
			question.OpenModal(mRoot);
			return;
		}
		mPresets.Remove(index);
		mDirty = true;
		Save();
		mModel.Reset();
		Select((mPresets.Count > 0) ? Math.Min(index, mPresets.Count - 1) : mPresets.Count);
	}

	/// Saves what is pending, closes and runs the selected preset's export; nothing when it
	/// resolves to no template here.
	public void ExportSelected()
	{
		let index = SelectedIndex;
		if ((index < 0) || (mSeams.RunExport == null) || (Resolved == null))
			return;
		Save();
		let name = scope String(mPresets.At(index).Name);
		Close();
		mSeams.RunExport(name, false);
	}

	public void ExportAll()
	{
		if ((mSeams.RunExport == null) || (mPresets.Count == 0))
			return;
		Save();
		Close();
		mSeams.RunExport(default, true);
	}

	/// Re-reads the templates (after Export Templates changed them).
	public void RefreshTemplates()
	{
		if (mSeams.Refresh != null)
			mSeams.Refresh(mRegistry);
		ClearIcons(mIcons);
		mModel.Reset();
		Load();
	}

	/// Add Files: the editor's picker over the project's own files (not the folders the editor, a
	/// cook or an export writes); the one picked joins the extra files, named relative to the
	/// project, so the preset travels with it.
	public void AddFiles()
	{
		let index = SelectedIndex;
		if ((mSeams.Pick == null) || mSeams.ProjectRoot.IsEmpty || (index < 0))
			return;
		let request = PathPicker.Request(mSeams.ProjectRoot, .(), default, scope (folder) => ProjectLayout.IsOutputFolder(folder));
		request.Placeholder.Set("Search the project's files");
		request.OnPicked = new [=index, =this] (path) =>
			{
				var picked = scope String(path);
				AddExtraFiles(index, Span<String>(&picked, 1));
			};
		mSeams.Pick(request);
	}

	/// From Disk: the system's dialog, for a file the editor's picker does not list. One inside the
	/// project joins as Add Files' do; one outside it is refused, since a preset names what travels
	/// with the project.
	public void AddFilesFromDisk()
	{
		let index = SelectedIndex;
		if ((mSeams.PickFiles == null) || (index < 0))
			return;
		mSeams.PickFiles(new [=index, =this] (paths) =>
			{
				let inside = scope List<String>();
				defer { ClearAndDeleteItems!(inside); }
				for (let path in paths)
				{
					let relative = ProjectRelative(path, .. new String());
					if (!relative.IsEmpty)
						inside.Add(relative);
					else
					{
						delete relative;
						if (mSeams.Notify != null)
							mSeams.Notify(scope $"{path} is outside the project: put it in the project to ship it with the game.");
					}
				}
				AddExtraFiles(index, inside);
			});
	}

	/// Browse for the file a path row names: the app icon from the project's PNGs with the editor's
	/// picker (not those of the folders the editor, a cook or an export writes), since the icon
	/// ships from the project; the keystore with the system's dialog, since a release keystore is
	/// kept outside the project as a rule, named relative to the project when it is inside it.
	public void Browse(StringView row)
	{
		let index = SelectedIndex;
		if (index < 0)
			return;
		let path = new String(row);
		if (row == "androidIcon")
		{
			if ((mSeams.Pick == null) || mSeams.ProjectRoot.IsEmpty)
			{
				delete path;
				return;
			}
			let request = PathPicker.Request(mSeams.ProjectRoot, scope StringView[](".png"), mPresets.At(index).AndroidIcon,
				scope (folder) => ProjectLayout.IsOutputFolder(folder));
			request.Placeholder.Set("Search the project's PNGs");
			request.OnPicked = new [=index, =this, =path] (picked) => { SetPath(index, path, picked); } ~ delete path;
			mSeams.Pick(request);
			return;
		}
		if (mSeams.PickFiles == null)
		{
			delete path;
			return;
		}
		mSeams.PickFiles(new [=index, =this, =path] (paths) =>
			{
				if (paths.IsEmpty)
					return;
				let relative = ProjectRelative(paths[0], .. scope .());
				SetPath(index, path, relative.IsEmpty ? StringView(paths[0]) : StringView(relative));
			} ~ delete path);
	}

	/// Sets preset `index`'s path row `row` to `value`, if it is still the one selected.
	private void SetPath(int index, StringView row, StringView value)
	{
		if ((SelectedIndex != index) || (mBag == null))
			return; // another preset by now
		mBag.SetValue(row, 0, Sedulous.GUI.Variant(value));
		Store();
		mBag.PropertiesChanged();
	}

	/// `path` relative to the project's folder, appended to `outRelative`; nothing when it is not
	/// under it.
	public void ProjectRelative(StringView path, String outRelative)
	{
		let root = StringView(mSeams.ProjectRoot);
		if (root.IsEmpty || (path.Length <= root.Length + 1) || !path.StartsWith(root) || (path[root.Length] != '/'))
			return;
		outRelative.Append(path.Substring(root.Length + 1));
	}

	/// Adds `files` the selected preset's extra files do not list yet, if it is still preset `index`.
	private void AddExtraFiles(int index, Span<String> files)
	{
		if ((SelectedIndex != index) || files.IsEmpty)
			return; // cancelled, or another preset by now
		let preset = scope ExportPreset();
		mPresets.At(index).CopyTo(preset);
		for (let file in files)
		{
			bool listed = false;
			for (let known in preset.AdditionalFiles)
				listed |= known == file;
			if (!listed)
				preset.AdditionalFiles.Add(new String(file));
		}
		mPresets.Update(index, preset);
		mDirty = true;
		Load();
	}

	/// The rows (the selected preset's, the grid's source; null with none), the grid, the window,
	/// the list and the Export button, for tests. The dialog's and the body's.
	public Sedulous.GUI.PropertyBag Rows => mBag;
	public PropertyGrid Grid => mGrid;
	public Sedulous.GUI.Window Window => mWindow;
	public ListView List => mList;
	public Sedulous.GUI.Button ExportButton => mExport;

	private T Find<T>(StringView id) where T : Node => (mBody != null) ? mBody.FindElement(id) as T : null;

	/// CONSUMES `run`, given to the button `id` (dropped when the markup has none).
	private void OnClick(StringView id, delegate void() run)
	{
		if (let button = Find<Sedulous.GUI.Button>(id))
			button.SetOnClick(run);
		else
			delete run;
	}

	private static void ClearIcons(Dictionary<String, Sedulous.GUI.Drawable> icons)
	{
		for (let entry in icons)
		{
			delete entry.key;
			entry.value?.ReleaseRef();
		}
		icons.Clear();
	}

	/// The icon a template is shown by, made once per template and folder. Borrowed: the cache
	/// holds its reference.
	private Sedulous.GUI.Drawable IconFor(ExportTemplate template)
	{
		let key = scope String();
		key.AppendF("{}|{}", template.Id, template.Directory);
		if (mIcons.TryGetValue(key, let known))
			return known;
		let svg = TemplateIcons.SvgFor(template, .. scope .());
		Sedulous.GUI.Drawable icon = SvgDrawable.FromText(svg);
		mIcons[new String(key)] = icon;
		return icon;
	}

	private void BindRow(Node node, int32 row)
	{
		let shown = node as TemplateRow;
		if ((shown == null) || (row < 0) || (row >= mPresets.Count))
			return;
		let preset = mPresets.At(row);
		let template = mRegistry.Resolve(preset);
		let summary = scope String();
		summary.Append(preset.Platform.IsEmpty ? "?" : StringView(preset.Platform));
		summary.Append(cDot);
		summary.Append(preset.EffectiveConfig);
		shown.Show((template != null) ? IconFor(template) : null, preset.Name, summary,
			(template != null) ? StringView() : "No template for it here");
	}

	// The values a choice offers: the preset's own, the fallback (the host's platform, Release),
	// then the templates' here and, for the platform, every one a game exports to; a platform with
	// no template stays choosable.
	private void FillChoices(PropertyInfo row, List<String> values, StringView current, StringView fallback, bool platforms)
	{
		ClearAndDeleteItems!(values);
		void Add(StringView value)
		{
			if (value.IsEmpty)
				return;
			for (let known in values)
			{
				if (known == value)
					return;
			}
			values.Add(new String(value));
		}
		Add(current);
		Add(fallback);
		for (int i < mRegistry.Count)
			Add(platforms ? StringView(mRegistry.At(i).Platform) : mRegistry.At(i).EffectiveConfig);
		if (platforms)
		{
			for (let known in ExportPlatform.All)
				Add(known.Tag);
		}
		for (int i < values.Count)
			row.AddChoice(values[i], i);
	}

	private static int64 IndexOf(List<String> values, StringView value)
	{
		for (int i < values.Count)
		{
			if (values[i] == value)
				return i;
		}
		return 0;
	}

	private PropertyInfo Row(StringView path, PropertyKind kind, Sedulous.GUI.Variant value, StringView label, StringView category,
		StringView description = default)
	{
		let row = mBag.Add(path, kind, value);
		row.DisplayName.Set(label);
		row.Category.Set(category);
		row.Description.Set(description);
		return row;
	}

	/// An enum's row, its choices the cases by name.
	private PropertyInfo EnumRow(StringView path, Type type, int64 value, StringView label, StringView category)
	{
		let row = Row(path, .Enum, Sedulous.GUI.Variant(value), label, category);
		for (var (caseName, data) in Enum.GetEnumerator(type))
			row.AddChoice(caseName, data);
		return row;
	}

	private PropertyInfo SizeRow(StringView path, uint32 value, StringView label, double least)
	{
		let row = Row(path, .Integer, Sedulous.GUI.Variant((int64)value), label, cDisplay);
		row.HasRange = true;
		row.Min = least;
		row.Max = 16384.0;
		row.Step = 1.0;
		return row;
	}

	// The selected preset's rows, the card and the buttons.
	private void Load()
	{
		if (mGrid != null)
			mGrid.Source = null;
		DeleteAndNullify!(mBag);
		let index = SelectedIndex;
		if (mExport != null)
			mExport.Enabled = (index >= 0) && (Resolved != null);
		if (mDuplicate != null)
			mDuplicate.Enabled = index >= 0;
		if (mRemove != null)
			mRemove.Enabled = index >= 0;
		ShowCard();
		if (index < 0)
			return;
		let preset = mPresets.At(index);
		mBag = new .();
		Row("name", .String, Sedulous.GUI.Variant(preset.Name), "Name", cGeneral);
		int64 chosen = 0;
		for (int i < mRegistry.Count)
		{
			if (!preset.TemplateId.IsEmpty && (mRegistry.At(i).Id == preset.TemplateId))
				chosen = i + 1;
		}
		let template = Row("template", .Enum, Sedulous.GUI.Variant(chosen), "Template", cGeneral,
			"A template picked by name decides the platform and config; Any takes the best installed for them.");
		template.AddChoice("Any for its platform and config", 0);
		let choiceName = scope String();
		for (int i < mRegistry.Count)
		{
			let t = mRegistry.At(i);
			choiceName.Set(t.Name);
			if (t.IsHost)
				choiceName.Append(" (this editor's own)");
			template.AddChoice(choiceName, i + 1);
		}
		Row("platform", .Enum, Sedulous.GUI.Variant((int64)0), "Platform", cGeneral);
		Row("config", .Enum, Sedulous.GUI.Variant((int64)0), "Config", cGeneral);
		ShowChoices(preset, chosen != 0);
		Row("playerName", .String, Sedulous.GUI.Variant(preset.PlayerName), "Player name", cGeneral,
			"Empty: the template's (Sedulous.Engine.Player.Desktop).");
		Row("outputSubdir", .String, Sedulous.GUI.Variant(preset.OutputSubdir), "Output folder", cGeneral,
			"Empty: the preset's name.");

		let files = mBag.AddList("additionalFiles", .String, Sedulous.GUI.Variant(StringView()), preset.AdditionalFiles.Count);
		files.DisplayName.Set("Extra files");
		files.Category.Set(cContent);
		files.Description.Set("Files of the project's, copied beside the player as they are (a licence, a readme).");
		let path = scope String();
		for (int i < preset.AdditionalFiles.Count)
			mBag.SetValue(path..Clear()..AppendF("additionalFiles.{}", i), 0, Sedulous.GUI.Variant(preset.AdditionalFiles[i]));
		Row("stageSymbols", .Bool, Sedulous.GUI.Variant(preset.StageSymbols), "Ship debug symbols", cContent,
			"Stage the template's debug symbols into the export.");
		Row("pruneToReachable", .Bool, Sedulous.GUI.Variant(preset.PruneToReachable), "Only what is reached", cContent,
			"Pack the closure of the default scene, the startup script and the other settings' assets, not every cooked asset.");
		Row("includeShaderSource", .Bool, Sedulous.GUI.Variant(preset.IncludeShaderSource), "Shader source", cContent,
			"Ship the project's shaders as HLSL too, beside the cooked bytecode (for modders to read).");

		Row("overridesRender", .Bool, Sedulous.GUI.Variant(preset.OverridesRender), "Own render size", cDisplay,
			"This platform draws at its own resolution rather than the project's.");
		SizeRow("renderWidth", preset.RenderWidth, "Render width", 0.0);
		SizeRow("renderHeight", preset.RenderHeight, "Render height", 0.0);
		EnumRow("renderFit", typeof(FitMode), (int64)preset.RenderFit, "Render fit", cDisplay);
		Row("overridesWindow", .Bool, Sedulous.GUI.Variant(preset.OverridesWindow), "Own window", cDisplay,
			"This platform's window differs from the project's (fullscreen on a device).");
		SizeRow("windowWidth", preset.WindowWidth, "Window width", 1.0);
		SizeRow("windowHeight", preset.WindowHeight, "Window height", 1.0);
		EnumRow("windowMode", typeof(WindowMode), (int64)preset.WindowMode, "Window mode", cDisplay);
		Row("windowResizable", .Bool, Sedulous.GUI.Variant(preset.WindowResizable), "Resizable", cDisplay);
		Row("overridesOrientation", .Bool, Sedulous.GUI.Variant(preset.OverridesOrientation), "Own orientation", cDisplay,
			"This platform is held its own way.");
		EnumRow("orientation", typeof(ScreenOrientation), (int64)preset.Orientation, "Orientation", cDisplay);
		// The quality level the platform starts at: the project's default, or one of its levels
		// (a preset may start at those alone).
		ClearAndDeleteItems(mQualityLevels);
		if (mSeams.QualityLevels != null)
			mSeams.QualityLevels(mQualityLevels);
		int64 level = 0;
		for (int i < mQualityLevels.Count)
		{
			if (mQualityLevels[i].Id == preset.QualityLevelId)
				level = i + 1;
		}
		let quality = Row("qualityLevel", .Enum, Sedulous.GUI.Variant(level), "Quality level", cDisplay,
			"The quality level this platform starts at; one of the project's (Project Settings, Quality).");
		quality.AddChoice("The project's default", 0);
		for (int i < mQualityLevels.Count)
			quality.AddChoice(mQualityLevels[i].Name, i + 1);
		Row("androidApplicationId", .String, Sedulous.GUI.Variant(preset.AndroidApplicationId), "Application id", cAndroid,
			"The app's own name on the phone and in a store, as com.studio.game.");
		let code = Row("androidVersionCode", .Integer, Sedulous.GUI.Variant((int64)preset.AndroidVersionCode), "Version code", cAndroid,
			"The version a phone and a store compare: raise it for each release.");
		code.HasRange = true;
		code.Min = 1.0;
		code.Max = 2100000000.0;
		code.Step = 1.0;
		Row("androidVersionName", .String, Sedulous.GUI.Variant(preset.AndroidVersionName), "Version name", cAndroid,
			"The version a person reads.");
		Row("androidLabel", .String, Sedulous.GUI.Variant(preset.AndroidLabel), "App name", cAndroid,
			"The name under its icon. Empty: the project's.");
		Row("androidIcon", .String, Sedulous.GUI.Variant(preset.AndroidIcon), "App icon", cAndroid,
			"A square PNG in the project, 512 pixels or more. Empty: the platform's.").Hint.Set(ExportPathEditor.cHint);
		EnumRow("androidPackage", typeof(AndroidPackage), (int64)preset.AndroidPackage, "Package", cAndroid);
		Row("androidKeystore", .String, Sedulous.GUI.Variant(preset.AndroidKeystore), "Keystore", cAndroid,
			"The release keystore, relative to the project. Empty: the debug key, for testing. Its password is asked for at export, or read from ANDROID_KEYSTORE_PASSWORD.").Hint.Set(ExportPathEditor.cHint);
		Row("androidKeyAlias", .String, Sedulous.GUI.Variant(preset.AndroidKeyAlias), "Key alias", cAndroid,
			"The key in the keystore that signs.");
		ShowOverrides(preset);
		mBag.SetOnCommit(new (commit) => { Store(); });
		// An extra file added or removed on the grid is a list edit, not a commit: it applies as
		// made too.
		mBag.SetOnListEdited(new (listPath, edit) => { Store(); });
		if (mGrid != null)
			mGrid.Source = mBag;
	}

	// The platform and config rows as the preset has them: their choices, the preset's, and read
	// only while a template picked by name decides them. In place: this runs inside the rows' own
	// commit.
	private void ShowChoices(ExportPreset preset, bool byTemplate)
	{
		let platform = mBag.FindInfo("platform");
		let config = mBag.FindInfo("config");
		if ((platform == null) || (config == null))
			return;
		ClearAndDeleteItems!(platform.Choices);
		ClearAndDeleteItems!(config.Choices);
		FillChoices(platform, mPlatforms, preset.Platform, mSeams.HostPlatform, true);
		FillChoices(config, mConfigs, preset.Config, "Release", false);
		platform.ReadOnly = byTemplate;
		config.ReadOnly = byTemplate;
		mBag.SetValue("platform", 0, Sedulous.GUI.Variant(IndexOf(mPlatforms, preset.Platform.IsEmpty ? StringView(mSeams.HostPlatform) : StringView(preset.Platform))));
		mBag.SetValue("config", 0, Sedulous.GUI.Variant(IndexOf(mConfigs, preset.EffectiveConfig)));
		mBag.PropertiesChanged();
	}

	// A display override's rows show only while the preset overrides it.
	private void ShowOverrides(ExportPreset preset)
	{
		void Show(StringView path, bool shown)
		{
			if (let info = mBag.FindInfo(path))
				info.Visible = shown;
		}
		Show("renderWidth", preset.OverridesRender);
		Show("renderHeight", preset.OverridesRender);
		Show("renderFit", preset.OverridesRender);
		Show("windowWidth", preset.OverridesWindow);
		Show("windowHeight", preset.OverridesWindow);
		Show("windowMode", preset.OverridesWindow);
		Show("windowResizable", preset.OverridesWindow);
		Show("orientation", preset.OverridesOrientation);
		// A field of one platform's (the Android app's) shows for a preset of that platform.
		let fields = scope List<System.Reflection.FieldInfo>();
		SettingFields.Of(typeof(ExportPreset), fields);
		let key = scope String();
		for (let field in fields)
		{
			if (field.GetCustomAttribute<PresetPlatformAttribute>() case .Ok(let only))
				Show(SettingFields.Key(field, .. key..Clear()), only.Platform == preset.Platform);
		}
		mBag.PropertiesChanged();
	}

	private void TextAt(StringView path, String outText)
	{
		var value = mBag.GetValue(path, 0);
		defer value.Dispose();
		outText.Set(value.AsString);
	}

	private bool FlagAt(StringView path)
	{
		var value = mBag.GetValue(path, 0);
		defer value.Dispose();
		return value.AsBool;
	}

	private int64 ChoiceAt(StringView path)
	{
		var value = mBag.GetValue(path, 0);
		defer value.Dispose();
		return value.AsInt;
	}

	/// A size row's value, never below none.
	private uint32 NumberAt(StringView path) => (uint32)Math.Max((int64)0, ChoiceAt(path));

	// The rows into the selected preset, then what shows it.
	private void Store()
	{
		let index = SelectedIndex;
		if ((index < 0) || (mBag == null))
			return;
		let preset = scope ExportPreset();
		mPresets.At(index).CopyTo(preset);
		TextAt("name", preset.Name);
		let chosen = ChoiceAt("template");
		let template = ((chosen > 0) && (chosen <= mRegistry.Count)) ? mRegistry.At((int)chosen - 1) : null;
		if (template != null)
		{
			// A template by name: its platform and config.
			preset.TemplateId.Set(template.Id);
			preset.Platform.Set(template.Platform);
			preset.Config.Set(template.EffectiveConfig);
		}
		else
		{
			preset.TemplateId.Clear();
			let platform = ChoiceAt("platform");
			let config = ChoiceAt("config");
			preset.Platform.Set(((platform >= 0) && (platform < mPlatforms.Count)) ? StringView(mPlatforms[(int)platform]) : default);
			preset.Config.Set(((config >= 0) && (config < mConfigs.Count)) ? StringView(mConfigs[(int)config]) : default);
		}
		TextAt("playerName", preset.PlayerName);
		TextAt("outputSubdir", preset.OutputSubdir);
		ClearAndDeleteItems(preset.AdditionalFiles);
		let path = scope String();
		for (int i < mBag.ElementCount("additionalFiles", 0))
		{
			let file = new String();
			TextAt(path..Clear()..AppendF("additionalFiles.{}", i), file);
			var trimmed = StringView(file);
			trimmed.Trim();
			// A row added and never filled is dropped.
			if (trimmed.IsEmpty)
				delete file;
			else
				preset.AdditionalFiles.Add(file);
		}
		preset.StageSymbols = FlagAt("stageSymbols");
		preset.PruneToReachable = FlagAt("pruneToReachable");
		preset.IncludeShaderSource = FlagAt("includeShaderSource");
		preset.OverridesRender = FlagAt("overridesRender");
		preset.RenderWidth = NumberAt("renderWidth");
		preset.RenderHeight = NumberAt("renderHeight");
		preset.RenderFit = (FitMode)ChoiceAt("renderFit");
		preset.OverridesWindow = FlagAt("overridesWindow");
		preset.WindowWidth = NumberAt("windowWidth");
		preset.WindowHeight = NumberAt("windowHeight");
		preset.WindowMode = (WindowMode)ChoiceAt("windowMode");
		preset.WindowResizable = FlagAt("windowResizable");
		preset.OverridesOrientation = FlagAt("overridesOrientation");
		preset.Orientation = (ScreenOrientation)ChoiceAt("orientation");
		TextAt("androidApplicationId", preset.AndroidApplicationId);
		preset.AndroidVersionCode = Math.Max((uint32)1, NumberAt("androidVersionCode"));
		TextAt("androidVersionName", preset.AndroidVersionName);
		TextAt("androidLabel", preset.AndroidLabel);
		TextAt("androidIcon", preset.AndroidIcon);
		preset.AndroidPackage = (AndroidPackage)ChoiceAt("androidPackage");
		TextAt("androidKeystore", preset.AndroidKeystore);
		TextAt("androidKeyAlias", preset.AndroidKeyAlias);
		let level = ChoiceAt("qualityLevel");
		preset.QualityLevelId = ((level > 0) && (level <= mQualityLevels.Count)) ? mQualityLevels[(int)level - 1].Id : Guid();
		mPresets.Update(index, preset);
		mDirty = true;
		mModel.Changed((int32)index);
		let stored = mPresets.At(index);
		ShowChoices(stored, template != null); // the platform and config follow a template picked by name
		ShowOverrides(stored);
		ShowCard();
		if (mExport != null)
			mExport.Enabled = Resolved != null;
	}

	private void ShowCard()
	{
		let icon = Find<Sedulous.GUI.Image>("export-card-icon");
		let title = Find<Sedulous.GUI.Label>("export-card-title");
		let detail = Find<Sedulous.GUI.Label>("export-card-detail");
		if ((icon == null) || (title == null) || (detail == null))
			return;
		let index = SelectedIndex;
		detail.RemoveClass("warning");
		if (index < 0)
		{
			icon.SetDrawable(null);
			title.Text = "No presets yet";
			detail.Text = "Add one with + for this platform.";
			return;
		}
		let preset = mPresets.At(index);
		let template = mRegistry.Resolve(preset);
		if (template == null)
		{
			icon.SetDrawable(null);
			icon.Source = "Editor/Icons/warning.svg";
			if (!preset.TemplateId.IsEmpty && (mRegistry.FindById(preset.TemplateId) == null))
				title.Text = scope $"Template '{preset.TemplateId}' is not installed here";
			else
				title.Text = scope $"No template for {preset.Platform.IsEmpty ? "?" : StringView(preset.Platform)} {preset.EffectiveConfig} here";
			detail.Text = "Install or create one in Export Templates, or pick another platform.";
			detail.AddClass("warning");
			return;
		}
		icon.SetDrawable(IconFor(template));
		title.Text = scope $"Exports with {template.Name}";
		let text = scope String();
		text.Append(template.Platform);
		text.Append(cDot);
		text.Append(template.EffectiveConfig);
		if (!template.EngineVersion.IsEmpty)
		{
			text.Append(cDot);
			text.Append(template.EngineVersion);
		}
		text.Append(cDot);
		text.Append(template.IsHost ? "this editor's own player" : "installed");
		if (!ExportTemplates.EngineMatches(template))
		{
			text.Append(". Built for another engine version; the export still runs.");
			detail.AddClass("warning");
		}
		detail.Text = text;
	}

	private void Save()
	{
		if (mDirty && (mSeams.Save != null))
			mSeams.Save();
		mDirty = false;
	}
}
