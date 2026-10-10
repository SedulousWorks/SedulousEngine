using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.App;

/// What the export dialog asks of the application. Every delegate is owned.
class ExportDialogSeams
{
	/// Fills the registry with the templates this host sees.
	public delegate void(TemplateRegistry registry) Refresh ~ delete _;
	/// Persists the presets (the controller the dialog edits) to the project.
	public delegate void() Save ~ delete _;
	/// Runs the export of one preset by name, or of every preset (`all`).
	public delegate void(StringView preset, bool all) RunExport ~ delete _;
	/// Opens the templates dialog over this one; null when it cannot.
	public delegate Dialog() OpenTemplates ~ delete _;
	/// Asks for files. TAKES OWNERSHIP of `chosen` and calls it exactly once: with the files,
	/// or none when the user cancels.
	public delegate void(delegate void(Span<String> files) chosen) PickFiles ~ delete _;
	/// The host's platform, a new preset's.
	public String HostPlatform = new .() ~ delete _;
	/// Where exports are written, said under the presets.
	public String OutputRoot = new .() ~ delete _;
}

/// Project > Export. The project's export presets on the left (add, duplicate, remove), each
/// by the icon of the template it resolves to here, with a warning when none does; the selected
/// one's settings on the right, a tab per category (General: its name, template, platform,
/// config, player and output folder; Content: extra files, symbols, pruning; Display: its own
/// render size and window), under a card naming the template it exports with, or saying none
/// is installed. Edits apply as they are made and are saved when the selection moves, an
/// export starts or the dialog closes. Export runs the selected preset, Export All every one;
/// Export Templates opens the templates dialog over this one, and the cards follow what it
/// changed. What it needs from outside comes through ExportDialogSeams, so a test drives it
/// without a window.
class ExportDialog : Dialog
{
	private static readonly Color cDimText = .(0.62f, 0.62f, 0.62f, 1.0f);
	private static readonly Color cWarningText = .(0.91f, 0.69f, 0.29f, 1.0f);
	private const String cDot = " · ";

	/// A preset's row: the icon of the template it resolves to (a warning when none does), its
	/// name over its platform and config.
	private class Adapter : ListAdapterBase
	{
		private ExportDialog mOwner;

		public this(ExportDialog owner)
		{
			mOwner = owner;
		}

		public override int32 ItemCount => (int32)mOwner.mPresets.Count;

		public override View CreateView(int32 viewType)
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 8;
			row.Padding = .(6, 4);
			var centred = LayoutStyle();
			centred.AlignSelf = .Center;
			row.AddView(new DrawableView(null, 24.0f, 24.0f) { KeepAspect = true }, centred);
			let text = new FlexLayout();
			text.Direction = .Vertical;
			text.Spacing = 1;
			let name = new Label();
			name.FontSize.Value = 12.5f;
			text.AddView(name);
			let summary = new Label();
			summary.FontSize.Value = 11.0f;
			text.AddView(summary);
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			row.AddView(text, grow);
			return row;
		}

		public override void BindView(View view, int32 position)
		{
			let row = view as FlexLayout;
			if ((row == null) || (row.ChildCount < 2) || (position < 0) || (position >= mOwner.mPresets.Count))
				return;
			let preset = mOwner.mPresets.At(position);
			let template = mOwner.mRegistry.Resolve(preset);
			(row.GetChildAt(0) as DrawableView).SetDrawable((template != null) ? mOwner.IconFor(template) : Retained(EditorIcons.Warning));
			let text = row.GetChildAt(1) as FlexLayout;
			(text.GetChildAt(0) as Label).SetText(preset.Name);
			let summary = scope String();
			summary.Append(preset.Platform.IsEmpty ? "?" : StringView(preset.Platform));
			summary.Append(cDot);
			summary.Append(preset.EffectiveConfig);
			if (template == null)
				summary.AppendF("{}no template here", cDot);
			let line = text.GetChildAt(1) as Label;
			line.SetText(summary);
			line.TextColor.Value = (template != null) ? cDimText : cWarningText;
		}
	}

	private EditorContext mContext;
	/// Borrowed: the application's, which outlives the dialog.
	private ExportPresetsController mPresets;
	private ExportDialogSeams mSeams ~ delete _;
	private TemplateRegistry mRegistry = new .() ~ delete _;
	private Adapter mAdapter ~ delete _;
	private CategoryTabs mTabs = new .() ~ delete _;
	/// One reference each, by template id and directory.
	private Dictionary<String, Drawable> mIcons = new .() ~ ClearIcons(_);
	/// The fields are being filled, not edited.
	private bool mLoading = false;
	/// Edited since the last save.
	private bool mDirty = false;

	// Borrowed from the content, as are the fields below.
	private ListView mList;
	// The resolve card.
	private DrawableView mResolveIcon;
	private Label mResolveTitle;
	private Label mResolveDetail;
	// General.
	private EditText mName;
	private ComboBox mTemplate;
	/// The template combo's items after "Any": template ids.
	private List<String> mTemplateIds = new .() ~ DeleteContainerAndItems!(_);
	private ComboBox mPlatform;
	private ComboBox mConfig;
	private EditText mPlayer;
	private EditText mSubdir;
	// Content.
	private EditText mFiles;
	private CheckBox mSymbols;
	private CheckBox mPrune;
	// Display.
	private CheckBox mOverridesRender;
	private NumericField mRenderWidth;
	private NumericField mRenderHeight;
	private ComboBox mRenderFit;
	private List<int64> mRenderFitValues = new .() ~ delete _;
	private CheckBox mOverridesWindow;
	private NumericField mWindowWidth;
	private NumericField mWindowHeight;
	private ComboBox mWindowMode;
	private List<int64> mWindowModeValues = new .() ~ delete _;
	private CheckBox mWindowResizable;
	// The presets' and the dialog's buttons.
	private View mDuplicate;
	private View mRemove;
	private Button mExport;

	/// Borrows the presets controller; TAKES OWNERSHIP of the seams.
	public this(EditorContext context, ExportPresetsController presets, ExportDialogSeams seams) : base("Export")
	{
		mContext = context;
		mPresets = presets;
		mSeams = seams;
		// A fixed size: the tabs measure only the page they show.
		MinWidth.Value = 820.0f;
		MaxWidth.Value = 820.0f;
		MinHeight.Value = 520.0f;
		MaxHeight.Value = 520.0f;
		if (mSeams.Refresh != null)
			mSeams.Refresh(mRegistry);

		let body = new FlexLayout();
		body.Direction = .Horizontal;

		// The presets.
		let side = new FlexLayout();
		side.Direction = .Vertical;
		side.Spacing = 4;
		side.Padding = .(6, 6);
		{
			let bar = new FlexLayout();
			bar.Direction = .Horizontal;
			bar.Spacing = 2;
			let heading = new Label("Presets");
			heading.FontSize.Value = 12.0f;
			heading.TextColor.Value = cDimText;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			bar.AddView(heading, grow);
			IconButton AddIconButton(SVGDrawable icon, StringView tip)
			{
				let button = new IconButton(icon, 14.0f);
				button.TooltipText.Set(tip);
				var centred = LayoutStyle();
				centred.AlignSelf = .Center;
				bar.AddView(button, centred);
				return button;
			}
			AddIconButton(EditorIcons.Add, "Add a preset for this platform").OnClick.Add(new [=this](b) => { AddPreset(); });
			let duplicate = AddIconButton(EditorIcons.Copy, "Duplicate the preset");
			duplicate.OnClick.Add(new [=this](b) => { DuplicateSelected(); });
			mDuplicate = duplicate;
			let remove = AddIconButton(EditorIcons.Remove, "Remove the preset");
			remove.OnClick.Add(new [=this](b) => { RemoveSelected(); });
			mRemove = remove;
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			side.AddView(bar, match);
		}
		mAdapter = new Adapter(this);
		mList = new ListView();
		mList.ItemHeight.Value = 40.0f;
		mList.SetAdapter(mAdapter);
		mList.Selection.OnSelectionChanged.Add(new [=this]() =>
			{
				Save(); // what was edited stays edited
				LoadFields();
			});
		{
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.Width = SizeSpec.Match();
			side.AddView(mList, grow);
		}
		if (!mSeams.OutputRoot.IsEmpty)
		{
			let outputNote = new Label(scope $"Exports go to {mSeams.OutputRoot}");
			outputNote.FontSize.Value = 10.5f;
			outputNote.WordWrap.Value = true;
			outputNote.TextColor.Value = cDimText;
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			side.AddView(outputNote, match);
		}
		{
			var sideWidth = LayoutStyle();
			sideWidth.Width = SizeSpec.Fixed(Unit.Dp(250.0f));
			sideWidth.Height = SizeSpec.Match();
			body.AddView(side, sideWidth);
		}
		{
			var line = LayoutStyle();
			line.Width = SizeSpec.Fixed(Unit.Dp(1.0f));
			line.Height = SizeSpec.Match();
			body.AddView(new Separator(.Vertical), line);
		}

		// The selected preset: its template card over its settings' tabs.
		let detail = new FlexLayout();
		detail.Direction = .Vertical;
		detail.Spacing = 6;
		detail.Padding = .(10, 8);
		BuildResolveCard(detail);
		BuildGeneral(mTabs.Column("General"));
		BuildContent(mTabs.Column("Content"));
		BuildDisplay(mTabs.Column("Display"));
		{
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.Width = SizeSpec.Match();
			detail.AddView(mTabs.View, grow);
		}
		{
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.Height = SizeSpec.Match();
			body.AddView(detail, grow);
		}
		SetContent(body);

		let templates = AddButton("Export Templates...", .None);
		templates.OnClick.Add(new [=this](b) =>
			{
				if (mSeams.OpenTemplates == null)
					return;
				// What it installed or removed shows here once it closes.
				if (let opened = mSeams.OpenTemplates())
					opened.OnClosed.Add(new [=this](d, result) => { RefreshTemplates(); });
			});
		let all = AddButton("Export All", .None);
		all.OnClick.Add(new [=this](b) => { ExportAll(); });
		mExport = AddButton("Export", .None);
		mExport.OnClick.Add(new [=this](b) => { ExportSelected(); });
		AddButton("Close", .Cancel);
		OnClosed.Add(new [=this](d, result) => { Save(); });

		if (mPresets.Count > 0)
			Select(0);
		LoadFields();
	}

	public ~this()
	{
		// The list outlives this body (the content holds it); it must not ask a deleted adapter.
		mList.SetAdapter(null);
	}

	private static void ClearIcons(Dictionary<String, Drawable> icons)
	{
		for (let entry in icons)
		{
			delete entry.key;
			entry.value?.ReleaseRef();
		}
		delete icons;
	}

	/// A shared icon with a reference taken for the view it goes to; null passes through.
	private static Drawable Retained(Drawable icon)
	{
		icon?.AddRef();
		return icon;
	}

	/// The extra files as the field shows them, "; "-separated: an EditText holds no list.
	private static void JoinFiles(List<String> files, String outText)
	{
		for (let file in files)
		{
			if (!outText.IsEmpty)
				outText.Append("; ");
			outText.Append(file);
		}
	}

	private static void SplitFiles(StringView text, List<String> outFiles)
	{
		ClearAndDeleteItems(outFiles);
		for (var part in text.Split(';'))
		{
			part.Trim();
			if (!part.IsEmpty)
				outFiles.Add(new String(part));
		}
	}

	/// A combo of an enum's cases by name, their values in `outValues` in the combo's order.
	private static ComboBox EnumCombo(Type type, List<int64> outValues)
	{
		let combo = new ComboBox();
		for (var (name, data) in Enum.GetEnumerator(type))
		{
			combo.AddItem(name);
			outValues.Add(data);
		}
		return combo;
	}

	private static void SelectEnum(ComboBox combo, List<int64> values, int64 value)
	{
		let index = values.IndexOf(value);
		if (index >= 0)
			combo.SetSelectedIndex((int32)index);
	}

	private static int64 ChosenEnum(ComboBox combo, List<int64> values)
	{
		let index = combo.SelectedIndex;
		return ((index >= 0) && (index < values.Count)) ? values[index] : 0;
	}

	private static NumericField SizeField(double least)
	{
		let field = new NumericField();
		field.SetDecimalPlaces(0);
		field.SetStep(1);
		field.SetMin(least);
		field.SetMax(16384);
		return field;
	}

	/// The presets' count and the selected one's index (-1 when there are none).
	public int PresetCount => mPresets.Count;

	public int SelectedIndex
	{
		get
		{
			let index = mList.Selection.FirstSelected();
			return ((index >= 0) && (index < mPresets.Count)) ? index : -1;
		}
	}

	public void Select(int index)
	{
		if ((index < 0) || (index >= mPresets.Count))
			return;
		mList.Selection.Select((int32)index);
		mList.ScrollToPosition((int32)index);
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

	/// The resolve card's title: the template's name, or why there is none.
	public StringView ResolveText => mResolveTitle.Text.Value;

	/// The tabs, and the General tab's fields, for tests. Borrowed.
	public TabView Tabs => mTabs.View;
	public int32 TabIndexOf(StringView category) => mTabs.IndexOf(category);
	public EditText NameField => mName;
	public ComboBox TemplateField => mTemplate;
	public CheckBox PruneField => mPrune;

	private FlexLayout AddRow(FlexLayout column, StringView label, View field)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 8;
		let text = new Label(label);
		text.FontSize.Value = 12.0f;
		var labelWidth = LayoutStyle();
		labelWidth.Width = SizeSpec.Fixed(Unit.Dp(110.0f));
		labelWidth.AlignSelf = .Center;
		row.AddView(text, labelWidth);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.AlignSelf = .Center;
		row.AddView(field, grow);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(row, match);
		return row;
	}

	private void BuildResolveCard(FlexLayout column)
	{
		let card = new FlexLayout();
		card.Direction = .Horizontal;
		card.Spacing = 10;
		card.Padding = .(10, 8);
		mResolveIcon = new DrawableView(null, 34.0f, 34.0f) { KeepAspect = true };
		var centred = LayoutStyle();
		centred.AlignSelf = .Center;
		card.AddView(mResolveIcon, centred);
		let text = new FlexLayout();
		text.Direction = .Vertical;
		text.Spacing = 2;
		mResolveTitle = new Label();
		mResolveTitle.FontSize.Value = 13.0f;
		text.AddView(mResolveTitle);
		mResolveDetail = new Label();
		mResolveDetail.FontSize.Value = 11.0f;
		mResolveDetail.WordWrap.Value = true;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		text.AddView(mResolveDetail, match);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.AlignSelf = .Center;
		card.AddView(text, grow);
		// A quiet rounded panel behind it (a FlexLayout draws no background of its own).
		let panel = new Panel();
		panel.SetStyle(.Background, new RoundedRectDrawable(.(1.0f, 1.0f, 1.0f, 0.04f), 6.0f, .(1.0f, 1.0f, 1.0f, 0.10f), 1.0f));
		panel.AddView(card);
		column.AddView(panel, match);
	}

	private void BuildGeneral(FlexLayout column)
	{
		mName = new EditText();
		mName.OnTextChanged.Add(new [=this](e) => { StoreFields(); });
		AddRow(column, "Name", mName);

		mTemplate = new ComboBox();
		mTemplate.OnSelectionChanged.Add(new [=this](c, i) => { StoreFields(); });
		AddRow(column, "Template", mTemplate);

		mPlatform = new ComboBox();
		mPlatform.OnSelectionChanged.Add(new [=this](c, i) => { StoreFields(); });
		AddRow(column, "Platform", mPlatform);

		mConfig = new ComboBox();
		mConfig.OnSelectionChanged.Add(new [=this](c, i) => { StoreFields(); });
		AddRow(column, "Config", mConfig);
		CategoryTabs.AddNote(column, "A template picked by name decides the platform and config; \"Any\" takes the best installed for the platform and config.");

		mPlayer = new EditText();
		mPlayer.Placeholder.Value.Set("the template's (Sedulous.Engine.Player.Desktop)");
		mPlayer.OnTextChanged.Add(new [=this](e) => { StoreFields(); });
		AddRow(column, "Player name", mPlayer);

		mSubdir = new EditText();
		mSubdir.Placeholder.Value.Set("the preset's name");
		mSubdir.OnTextChanged.Add(new [=this](e) => { StoreFields(); });
		AddRow(column, "Output folder", mSubdir);
	}

	private void BuildContent(FlexLayout column)
	{
		mFiles = new EditText();
		mFiles.Placeholder.Value.Set("none (separate files with ;)");
		mFiles.OnTextChanged.Add(new [=this](e) => { StoreFields(); });
		let row = AddRow(column, "Extra files", mFiles);
		let browse = new Button("Add Files...");
		browse.OnClick.Add(new [=this](b) => { PickFiles(); });
		var centred = LayoutStyle();
		centred.AlignSelf = .Center;
		row.AddView(browse, centred);
		CategoryTabs.AddNote(column, "Copied beside the player, as they are (a licence, a readme).");

		mSymbols = new CheckBox("Ship the template's debug symbols", false);
		mSymbols.OnCheckedChanged.Add(new [=this](c, v) => { StoreFields(); });
		column.AddView(mSymbols);
		mPrune = new CheckBox("Ship only the content the game reaches", false);
		mPrune.TooltipText.Set("Pack the closure of the default scene, the startup script and the other settings' assets, not every cooked asset");
		mPrune.OnCheckedChanged.Add(new [=this](c, v) => { StoreFields(); });
		column.AddView(mPrune);
	}

	/// Asks for files and appends them to the extra files. The dialog holds a reference across
	/// the pick, which the OS may answer after it has closed.
	private void PickFiles()
	{
		if (mSeams.PickFiles == null)
			return;
		AddRef();
		mSeams.PickFiles(new [=this](paths) =>
			{
				defer ReleaseRef();
				if (paths.IsEmpty)
					return;
				let files = scope List<String>();
				defer ClearAndDeleteItems(files);
				SplitFiles(mFiles.Text, files);
				for (let path in paths)
					files.Add(new String(path));
				mFiles.SetText(JoinFiles(files, .. scope .()));
				StoreFields();
			});
	}

	private void BuildDisplay(FlexLayout column)
	{
		FlexLayout Pair(View a, View b)
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 6;
			var sizeWidth = LayoutStyle();
			sizeWidth.Width = SizeSpec.Fixed(Unit.Dp(90));
			row.AddView(a, sizeWidth);
			row.AddView(new Label("x"));
			row.AddView(b, sizeWidth);
			return row;
		}
		CategoryTabs.AddNote(column, "This platform's own display, over the project's (a handheld's panel, fullscreen on a device).");

		mOverridesRender = new CheckBox("Draw at its own render size", false);
		mOverridesRender.OnCheckedChanged.Add(new [=this](c, v) => { StoreFields(); });
		column.AddView(mOverridesRender);
		mRenderWidth = SizeField(0);
		mRenderHeight = SizeField(0);
		mRenderWidth.OnValueChanged.Add(new [=this](f, v) => { StoreFields(); });
		mRenderHeight.OnValueChanged.Add(new [=this](f, v) => { StoreFields(); });
		AddRow(column, "Render size", Pair(mRenderWidth, mRenderHeight));
		mRenderFit = EnumCombo(typeof(FitMode), mRenderFitValues);
		mRenderFit.OnSelectionChanged.Add(new [=this](c, i) => { StoreFields(); });
		AddRow(column, "Render fit", mRenderFit);

		mOverridesWindow = new CheckBox("Open its own window", false);
		mOverridesWindow.OnCheckedChanged.Add(new [=this](c, v) => { StoreFields(); });
		column.AddView(mOverridesWindow);
		mWindowWidth = SizeField(1);
		mWindowHeight = SizeField(1);
		mWindowWidth.OnValueChanged.Add(new [=this](f, v) => { StoreFields(); });
		mWindowHeight.OnValueChanged.Add(new [=this](f, v) => { StoreFields(); });
		AddRow(column, "Window size", Pair(mWindowWidth, mWindowHeight));
		mWindowMode = EnumCombo(typeof(WindowMode), mWindowModeValues);
		mWindowMode.OnSelectionChanged.Add(new [=this](c, i) => { StoreFields(); });
		AddRow(column, "Window mode", mWindowMode);
		mWindowResizable = new CheckBox("Resizable", false);
		mWindowResizable.OnCheckedChanged.Add(new [=this](c, v) => { StoreFields(); });
		column.AddView(mWindowResizable);
	}

	private void ClearIconCache()
	{
		for (let entry in mIcons)
		{
			delete entry.key;
			entry.value?.ReleaseRef();
		}
		mIcons.Clear();
	}

	/// The icon a template is shown by, made once per template, with a reference taken for the
	/// view it goes to.
	private Drawable IconFor(ExportTemplate template)
	{
		let key = scope String();
		key.AppendF("{}|{}", template.Id, template.Directory);
		if (mIcons.TryGetValue(key, let known))
			return Retained(known);
		let svg = TemplateIcons.SvgFor(template, .. scope .());
		Drawable icon = SVGDrawable.FromString(svg);
		mIcons[new String(key)] = icon;
		return Retained(icon);
	}

	/// The values the templates here offer, the preset's own, and the fallback (the host's
	/// platform, Release): a platform with no template stays choosable, the card says so.
	private void FillChoices(ComboBox combo, StringView current, StringView fallback, bool platforms)
	{
		let values = scope List<StringView>();
		void Add(StringView value)
		{
			if (!value.IsEmpty && !values.Contains(value))
				values.Add(value);
		}
		Add(current);
		Add(fallback);
		for (int i < mRegistry.Count)
			Add(platforms ? StringView(mRegistry.At(i).Platform) : mRegistry.At(i).EffectiveConfig);
		let shown = current.IsEmpty ? fallback : current;
		// The views point into the presets and the registry, which the combo's rebuild keeps.
		combo.ClearItems();
		int32 selected = 0;
		for (let value in values)
		{
			let index = combo.AddItem(value);
			if (value == shown)
				selected = index;
		}
		combo.SetSelectedIndex(selected);
	}

	private void FillTemplateChoices()
	{
		mTemplate.ClearItems();
		ClearAndDeleteItems(mTemplateIds);
		mTemplate.AddItem("Any for its platform and config");
		for (int i < mRegistry.Count)
		{
			let template = mRegistry.At(i);
			mTemplate.AddItem(template.IsHost ? scope $"{template.Name} (this editor's own)" : StringView(template.Name));
			mTemplateIds.Add(new String(template.Id));
		}
	}

	/// Shows the selected preset in the fields, without writing it back.
	private void LoadFields()
	{
		let index = SelectedIndex;
		mLoading = true;
		let any = index >= 0;
		mTabs.View.IsEnabled = any;
		mExport.IsEnabled = any;
		mDuplicate.IsEnabled = any;
		mRemove.IsEnabled = any;
		FillTemplateChoices();
		if (any)
		{
			let preset = mPresets.At(index);
			mName.SetText(preset.Name);
			int32 chosen = 0;
			for (int i < mTemplateIds.Count)
			{
				if (mTemplateIds[i] == preset.TemplateId)
					chosen = (int32)i + 1;
			}
			mTemplate.SetSelectedIndex(chosen);
			FillChoices(mPlatform, preset.Platform, mSeams.HostPlatform, true);
			FillChoices(mConfig, preset.Config, "Release", false);
			// A template picked by name decides both.
			mPlatform.IsEnabled = chosen == 0;
			mConfig.IsEnabled = chosen == 0;
			mPlayer.SetText(preset.PlayerName);
			mSubdir.SetText(preset.OutputSubdir);
			mFiles.SetText(JoinFiles(preset.AdditionalFiles, .. scope .()));
			mSymbols.IsChecked.Value = preset.StageSymbols;
			mPrune.IsChecked.Value = preset.PruneToReachable;
			mOverridesRender.IsChecked.Value = preset.OverridesRender;
			mRenderWidth.SetValue(preset.RenderWidth);
			mRenderHeight.SetValue(preset.RenderHeight);
			SelectEnum(mRenderFit, mRenderFitValues, (int64)preset.RenderFit);
			mOverridesWindow.IsChecked.Value = preset.OverridesWindow;
			mWindowWidth.SetValue(preset.WindowWidth);
			mWindowHeight.SetValue(preset.WindowHeight);
			SelectEnum(mWindowMode, mWindowModeValues, (int64)preset.WindowMode);
			mWindowResizable.IsChecked.Value = preset.WindowResizable;
		}
		mLoading = false;
		UpdateResolve();
	}

	/// Writes the fields into the selected preset, then refreshes what shows it.
	private void StoreFields()
	{
		let index = SelectedIndex;
		if (mLoading || (index < 0))
			return;
		let preset = scope ExportPreset();
		mPresets.At(index).CopyTo(preset);
		preset.Name.Set(mName.Text);
		let chosen = mTemplate.SelectedIndex;
		if ((chosen > 0) && (chosen <= mTemplateIds.Count))
		{
			// A template by name: its platform and config, shown in their (now fixed) fields.
			let id = mTemplateIds[chosen - 1];
			preset.TemplateId.Set(id);
			if (let template = mRegistry.FindById(id))
			{
				preset.Platform.Set(template.Platform);
				preset.Config.Set(template.EffectiveConfig);
			}
		}
		else
		{
			preset.TemplateId.Clear();
			preset.Platform.Set(mPlatform.SelectedText);
			preset.Config.Set(mConfig.SelectedText);
		}
		preset.PlayerName.Set(mPlayer.Text);
		preset.OutputSubdir.Set(mSubdir.Text);
		SplitFiles(mFiles.Text, preset.AdditionalFiles);
		preset.StageSymbols = mSymbols.IsChecked.Value;
		preset.PruneToReachable = mPrune.IsChecked.Value;
		preset.OverridesRender = mOverridesRender.IsChecked.Value;
		preset.RenderWidth = (uint32)mRenderWidth.Value;
		preset.RenderHeight = (uint32)mRenderHeight.Value;
		preset.RenderFit = (FitMode)ChosenEnum(mRenderFit, mRenderFitValues);
		preset.OverridesWindow = mOverridesWindow.IsChecked.Value;
		preset.WindowWidth = (uint32)mWindowWidth.Value;
		preset.WindowHeight = (uint32)mWindowHeight.Value;
		preset.WindowMode = (WindowMode)ChosenEnum(mWindowMode, mWindowModeValues);
		preset.WindowResizable = mWindowResizable.IsChecked.Value;
		mPresets.Update(index, preset);
		mDirty = true;

		// The platform and config follow a template picked by name.
		mLoading = true;
		let stored = mPresets.At(index);
		FillChoices(mPlatform, stored.Platform, mSeams.HostPlatform, true);
		FillChoices(mConfig, stored.Config, "Release", false);
		mPlatform.IsEnabled = chosen <= 0;
		mConfig.IsEnabled = chosen <= 0;
		mLoading = false;
		mList.OnItemRangeChanged((int32)index, 1);
		UpdateResolve();
	}

	private void UpdateResolve()
	{
		let index = SelectedIndex;
		if (index < 0)
		{
			mResolveIcon.SetDrawable(null);
			mResolveTitle.SetText("No presets yet");
			mResolveDetail.SetText("Add one with + for this platform.");
			mResolveDetail.TextColor.Value = cDimText;
			return;
		}
		let preset = mPresets.At(index);
		let template = mRegistry.Resolve(preset);
		if (template == null)
		{
			mResolveIcon.SetDrawable(Retained(EditorIcons.Warning));
			if (!preset.TemplateId.IsEmpty && (mRegistry.FindById(preset.TemplateId) == null))
				mResolveTitle.SetText(scope $"Template '{preset.TemplateId}' is not installed here");
			else
				mResolveTitle.SetText(scope $"No template for {preset.Platform.IsEmpty ? "?" : StringView(preset.Platform)} {preset.EffectiveConfig} here");
			mResolveDetail.SetText("Install or create one in Export Templates, or pick another platform.");
			mResolveDetail.TextColor.Value = cWarningText;
			mExport.IsEnabled = false;
			return;
		}
		mResolveIcon.SetDrawable(IconFor(template));
		mResolveTitle.SetText(scope $"Exports with {template.Name}");
		let detail = scope String();
		detail.Append(template.Platform);
		detail.Append(cDot);
		detail.Append(template.EffectiveConfig);
		if (!template.EngineVersion.IsEmpty)
			detail.AppendF("{}{}", cDot, template.EngineVersion);
		detail.Append(cDot);
		detail.Append(template.IsHost ? "this editor's own player" : "installed");
		let matches = ExportTemplates.EngineMatches(template);
		if (!matches)
			detail.Append(". Built for another engine version; the export still runs.");
		mResolveDetail.SetText(detail);
		mResolveDetail.TextColor.Value = matches ? cDimText : cWarningText;
		mExport.IsEnabled = true;
	}

	private void Save()
	{
		if (mDirty && (mSeams.Save != null))
			mSeams.Save();
		mDirty = false;
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
		mList.NotifyDataChanged();
		Select(index);
		LoadFields();
	}

	public void DuplicateSelected()
	{
		let index = SelectedIndex;
		if (index < 0)
			return;
		let copy = mPresets.Duplicate(index);
		mDirty = true;
		Save();
		mList.NotifyDataChanged();
		Select(copy);
		LoadFields();
	}

	public void RemoveSelected()
	{
		let index = SelectedIndex;
		if (index < 0)
			return;
		mPresets.Remove(index);
		mDirty = true;
		Save();
		mList.Selection.ClearSelection();
		mList.NotifyDataChanged();
		if (mPresets.Count > 0)
			Select(Math.Min(index, mPresets.Count - 1));
		LoadFields();
	}

	/// Saves what is pending, runs the selected preset's export and closes.
	public void ExportSelected()
	{
		let index = SelectedIndex;
		if ((index < 0) || (mSeams.RunExport == null))
			return;
		Save();
		let name = scope String(mPresets.At(index).Name);
		mSeams.RunExport(name, false);
		Close(.OK);
	}

	public void ExportAll()
	{
		if ((mSeams.RunExport == null) || (mPresets.Count == 0))
			return;
		Save();
		mSeams.RunExport(default, true);
		Close(.OK);
	}

	/// Re-reads the templates (after the templates dialog changed them).
	public void RefreshTemplates()
	{
		if (mSeams.Refresh != null)
			mSeams.Refresh(mRegistry);
		ClearIconCache();
		mList.NotifyDataChanged();
		LoadFields();
	}
}
