using System;
using Sedulous.Core;
using Sedulous.Settings;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// A modal editor for the per-user editor preferences, the settings store persisted at
/// <user-data>/editor.settings.xml; distinct from ProjectSettingsDialog, which edits the
/// project manifest. Fields: the export templates root (blank means $SEDULOUS_TEMPLATES_DIR,
/// else <user-data>/templates, shown as the placeholder), the editor font paths (blank is
/// the built-in chain), the UI scale, and every domain-contributed category. Save writes
/// the sections back and persists them; font changes apply on the next start. Cancel
/// discards.
class EditorPreferencesDialog : Dialog
{
	/// Fired on Apply with the new UI scale so the app can apply it live (the host's scale
	/// plus an icon re-bake); the saved setting covers the next launch. Owned.
	public delegate void(float scale) OnUiScaleApplied ~ delete _;

	private EditorContext mContext;
	private Settings mSettings;
	// Borrowed: the content owns them.
	private EditText mRootEdit = null;
	private EditText mFontEdit = null;
	private EditText mMonoFontEdit = null;
	private Slider mUiScaleSlider = null;
	private Label mUiScaleLabel = null;

	public this(EditorContext context, Settings store) : base("Preferences")
	{
		mContext = context;
		mSettings = store;
		MinWidth.Value = 480.0f;
		MinHeight.Value = 220.0f;
		MaxWidth.Value = 640.0f;
		MaxHeight.Value = 300.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 8;

		StringView current = "";
		if (let s = store.Find<EditorExportSettings>())
			current = s.TemplatesRoot;
		mRootEdit = AddTextRow(column, "Templates root", current);
		mRootEdit.Placeholder.Value.Set(ExportTemplates.DefaultRoot(.. scope .()));

		StringView fontPath = "";
		StringView monoPath = "";
		if (let f = store.Find<EditorFontSettings>())
		{
			fontPath = f.FontPath;
			monoPath = f.MonoFontPath;
		}
		mFontEdit = AddTextRow(column, "UI font (.ttf)", fontPath);
		mFontEdit.Placeholder.Value.Set("built-in (embedded fallback)");
		mMonoFontEdit = AddTextRow(column, "Mono font (.ttf)", monoPath);
		mMonoFontEdit.Placeholder.Value.Set("built-in");

		float uiScale = 1.0f;
		if (let u = store.Find<EditorUiSettings>())
			uiScale = Math.Clamp(u.UiScale, 1.0f, 2.0f);
		{
			let row = AddRow(column, "UI scale");
			let slider = new Slider();
			slider.Min.Value = 1.0f;
			slider.Max.Value = 2.0f;
			slider.Step.Value = 0.05f;
			slider.Value.Value = uiScale;
			mUiScaleSlider = slider;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			row.AddView(slider, grow);
			let valueLabel = new Label("1.00x");
			valueLabel.FontSize.Value = 11.0f;
			mUiScaleLabel = valueLabel;
			var narrow = LayoutStyle();
			narrow.Width = SizeSpec.Fixed(Unit.Dp(44));
			narrow.AlignSelf = .Center;
			row.AddView(valueLabel, narrow);
			UpdateScaleLabel(uiScale);
			slider.OnValueChanged.Add(new (s, v) => { UpdateScaleLabel(v); });
		}
		{
			let note = new Label("Font changes apply on restart.");
			note.FontSize.Value = 11.0f;
			note.TextColor.Value = Color(0.55f, 0.55f, 0.55f, 1.0f);
			column.AddView(note);
		}

		// The domain-contributed categories: the app hardcodes nothing, each domain's fields
		// render generically here and write through their own closures.
		for (let contribution in context.EditorSettingsContributions)
		{
			let header = new Label(contribution.Category);
			header.FontSize.Value = 13.0f;
			column.AddView(header);
			for (let field in contribution.Bools)
			{
				let on = (field.Get != null) ? field.Get() : false;
				let check = new CheckBox(field.Label, on);
				check.FontSize.Value = 12.0f;
				if (!field.Description.IsEmpty)
					check.TooltipText.Set(field.Description);
				// The field is context-owned and stable: registrations happen at boot.
				check.OnCheckedChanged.Add(new [=field](c, value) => { if (field.Set != null) field.Set(value); });
				var style = LayoutStyle();
				style.Width = SizeSpec.Match();
				style.Height = SizeSpec.Fixed(Unit.Dp(22.0f));
				column.AddView(check, style);
			}
		}

		// Scrolled, so the column can grow without spilling over the modal button row.
		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		scroll.HScrollBarPolicy.Value = .Never;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		scroll.AddView(column, match);
		SetContent(scroll);

		let save = AddButton("Save", .None);
		save.OnClick.Add(new (b) => { Apply(); });
		AddButton("Cancel", .Cancel);
	}

	private void UpdateScaleLabel(float value)
	{
		if (mUiScaleLabel != null)
		{
			let percent = (int32)(value * 100.0f + 0.5f);
			mUiScaleLabel.SetText(scope $"{percent}%");
		}
	}

	/// A labelled horizontal row, narrow-width label; callers append the field views.
	private FlexLayout AddRow(FlexLayout column, StringView label)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 8;
		let text = new Label(label);
		var narrow = LayoutStyle();
		narrow.Width = SizeSpec.Fixed(Unit.Dp(110));
		narrow.AlignSelf = .Center;
		row.AddView(text, narrow);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(row, match);
		return row;
	}

	private EditText AddTextRow(FlexLayout column, StringView label, StringView value)
	{
		let row = AddRow(column, label);
		let edit = new EditText();
		edit.SetText(value);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		row.AddView(edit, grow);
		return edit;
	}

	private void Apply()
	{
		mSettings.Section<EditorExportSettings>().TemplatesRoot.Set(mRootEdit.Text);
		mSettings.MarkChanged<EditorExportSettings>();
		let fontPrefs = mSettings.Section<EditorFontSettings>();
		fontPrefs.FontPath.Set(mFontEdit.Text);
		fontPrefs.MonoFontPath.Set(mMonoFontEdit.Text);
		mSettings.MarkChanged<EditorFontSettings>();
		let uiScale = Math.Clamp(mUiScaleSlider.Value.Value, 1.0f, 2.0f);
		mSettings.Section<EditorUiSettings>().UiScale = uiScale;
		mSettings.MarkChanged<EditorUiSettings>();
		if (OnUiScaleApplied != null)
			OnUiScaleApplied(uiScale); // live: the host scale and the icon re-bake
		if (EditorSettingsStore.SaveToUserData(mSettings) case .Ok)
			mContext.SetStatus("Preferences saved.");
		else
			mContext.Notify(.Error, "Preferences save FAILED (see console).");
		Close(.OK);
	}
}
