using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.UI;
using Sedulous.Engine.Render;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// A modal editor for the project manifest: a row per field ProjectSettings marks [Setting], in
/// its declaration order and built from its reflection, so a setting added there is edited
/// here. A text is an edit box, an asset a slot picking by guid through the AssetPickerDialog
/// (filtered to the type the setting names; the path kept as the readable mirror), an asset
/// list a list of slots, a count a number within its range, a choice its enum's cases, a flag a
/// box. MSAA is the one with a rule of its own: the render subsystem's levels. The engine
/// version is shown read-only; every save re-stamps it. Save writes the rows back into
/// EditorProject.Settings and persists the manifest; Cancel discards.
class ProjectSettingsDialog : Dialog
{
	/// An asset setting: the id the dialog applies on Save, and the slot row showing it.
	private class AssetRow
	{
		public FieldInfo Field;
		public Guid Id = .Empty;
		/// OWNED; its view sits in the dialog's row.
		public ResourceRefEditor Editor ~ delete _;
	}

	/// An asset list setting: the ids as edited (nil entries are slots not yet picked), and
	/// the list editor, rebuilt on every change.
	private class AssetListRow
	{
		public FieldInfo Field;
		public String Label = new .() ~ delete _;
		public String AssetType = new .() ~ delete _;
		public List<Guid> Ids = new .() ~ delete _;
		/// Borrowed: the row's cell the list sits in.
		public FlexLayout Host;
		/// OWNED: its view sits in Host.
		public ContainerListEditor List ~ delete _;
	}

	/// A text, count, choice or flag setting and the view editing it (borrowed: the content
	/// owns it).
	private class ValueRow
	{
		public FieldInfo Field;
		public SettingKind Kind;
		public EditText Text;
		public NumericField Number;
		public ComboBox Choice;
		/// A choice's case values, in the combo's order.
		public List<int64> ChoiceValues = new .() ~ delete _;
		public CheckBox Flag;
	}

	/// Borrowed.
	private EditorContext mContext;
	private ComboBox mMsaaCombo = null;
	private List<AssetRow> mAssets = new .() ~ DeleteContainerAndItems!(_);
	private List<AssetListRow> mAssetLists = new .() ~ DeleteContainerAndItems!(_);
	private List<ValueRow> mValues = new .() ~ DeleteContainerAndItems!(_);

	public this(EditorContext context) : base("Project Settings")
	{
		mContext = context;
		MinWidth.Value = 460.0f;
		MinHeight.Value = 240.0f;
		MaxWidth.Value = 560.0f;
		MaxHeight.Value = 560.0f; // taller so the rows fit; the ScrollView handles overflow

		let project = context.Project;
		let settings = (project != null) ? project.Settings : scope:: ProjectSettings();

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 8;

		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		for (let field in fields)
		{
			let setting = SettingFields.Setting(field).Value;
			SettingFields.KindOf(field, let kind);
			switch (kind)
			{
			case .Asset:
				let asset = new AssetRow();
				asset.Field = field;
				mAssets.Add(asset);
				AddPickRow(column, setting.Label, asset, setting.AssetType, setting.EmptyText,
					*(Guid*)SettingFields.Address(settings, field));
			case .AssetList:
				let list = new AssetListRow();
				list.Field = field;
				list.Label.Set(setting.Label);
				list.AssetType.Set(setting.AssetType);
				list.Ids.AddRange(*(List<Guid>*)SettingFields.Address(settings, field));
				mAssetLists.Add(list);
				AddAssetListRow(column, list);
			case .TextList:
				// No settings field is one yet; the MCP tools set it whole.
			default:
				if (field.Name == "RenderMsaaSamples")
					AddMsaaRow(column, setting.Label, settings.RenderMsaaSamples);
				else
					AddValueRow(column, setting.Label, field, kind, settings);
			}
		}

		// The engine stamp, informational; re-stamped by every save.
		{
			let row = AddRow(column, "Engine version");
			var centre = LayoutStyle();
			centre.AlignSelf = .Center;
			row.AddView(new Label(EngineVersion.String), centre);
		}

		// Scrolled, so a tall column cannot spill over the modal button row.
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

	/// The scene-pass MSAA: Off, 2x, 4x map to 1, 2, 4 samples. The player and play-in-editor
	/// apply it; the render subsystem capability-clamps at runtime.
	private void AddMsaaRow(FlexLayout column, StringView label, uint32 samples)
	{
		let row = AddRow(column, label);
		mMsaaCombo = new ComboBox();
		for (let level in MsaaLevels.All)
			mMsaaCombo.AddItem(level.Label);
		mMsaaCombo.SetSelectedIndex(MsaaLevels.IndexForSamples(samples));
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		row.AddView(mMsaaCombo, grow);
	}

	/// A text, count, choice or flag setting's row, seeded from the manifest.
	private void AddValueRow(FlexLayout column, StringView label, FieldInfo field, SettingKind kind, ProjectSettings settings)
	{
		let value = new ValueRow();
		value.Field = field;
		value.Kind = kind;
		mValues.Add(value);
		let address = SettingFields.Address(settings, field);
		switch (kind)
		{
		case .Text:
			value.Text = AddTextRow(column, label, *(String*)address);
		case .Count:
			let row = AddRow(column, label);
			SettingFields.CountRange(field, let least, let most);
			value.Number = new NumericField();
			value.Number.SetDecimalPlaces(0);
			value.Number.SetMin(least);
			value.Number.SetMax(most);
			value.Number.SetStep(1);
			value.Number.SetValue(*(uint32*)address);
			var style = LayoutStyle();
			style.Width = SizeSpec.Fixed(Unit.Dp(80));
			style.AlignSelf = .Center;
			row.AddView(value.Number, style);
		case .Choice:
			let row = AddRow(column, label);
			value.Choice = new ComboBox();
			let current = SettingFields.ReadChoice(settings, field);
			int32 selected = 0;
			for (var (name, data) in Enum.GetEnumerator(field.FieldType))
			{
				if (data == current)
					selected = (int32)value.ChoiceValues.Count;
				value.ChoiceValues.Add(data);
				value.Choice.AddItem(name);
			}
			value.Choice.SetSelectedIndex(selected);
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			row.AddView(value.Choice, grow);
		case .Flag:
			let row = AddRow(column, label);
			value.Flag = new CheckBox("", *(bool*)address);
			var centre = LayoutStyle();
			centre.AlignSelf = .Center;
			row.AddView(value.Flag, centre);
		default:
		}
	}

	/// A labelled horizontal row, fixed-width label; callers append the field views.
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

	/// An asset setting's row: a slot that picks, takes a dropped asset of its type and clears,
	/// seeded from the manifest. Edit and reveal are left off: this is a modal dialog.
	private void AddPickRow(FlexLayout column, StringView label, AssetRow asset, StringView typeName,
		StringView emptyText, Guid current)
	{
		let row = AddRow(column, label);
		asset.Id = current;
		asset.Editor = new ResourceRefEditor(label, emptyText, "", scope StringView[](typeName));
		asset.Editor.EmptyText.Set(emptyText);
		asset.Editor.BindAsset(mContext, new [=asset]() => asset.Id, new [=asset](id) => { asset.Id = id; });
		delete asset.Editor.OnEdit;
		asset.Editor.OnEdit = null;
		delete asset.Editor.OnReveal;
		asset.Editor.OnReveal = null;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.AlignSelf = .Center;
		// The editor keeps its own reference to its view; the layout gets one of its own.
		asset.Editor.EditorView.AddRef();
		row.AddView(asset.Editor.EditorView, grow);
	}

	/// An asset list setting's row: a list of slots of the setting's type.
	private void AddAssetListRow(FlexLayout column, AssetListRow list)
	{
		let row = AddRow(column, list.Label);
		list.Host = new FlexLayout();
		list.Host.Direction = .Vertical;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		row.AddView(list.Host, grow);
		RebuildAssetList(list);
	}

	/// After the gesture that changed the list: its editor is running the callback, so it is
	/// replaced once the dispatch is over.
	private void AssetListChanged(AssetListRow list)
	{
		if (Context != null)
			Context.MutationQueue.QueueAction(new [=this, =list]() => { RebuildAssetList(list); });
	}

	private void RebuildAssetList(AssetListRow row)
	{
		if (row.List != null)
		{
			row.Host.RemoveView(row.List.EditorView);
			DeleteAndNullify!(row.List);
		}
		let list = new ContainerListEditor(row.Label, "Project");
		for (let id in row.Ids)
		{
			let name = new String();
			if (id.IsSet)
				mContext.AssetNameFor(id, name);
			else
				name.Set("(pick one)");
			list.SlotNames.Add(name);
		}
		list.SetAcceptedTypes(scope StringView[](row.AssetType));
		list.OnAdd = new [=this, =row]() => { row.Ids.Add(.Empty); AssetListChanged(row); };
		list.OnRemoveSlot = new [=this, =row](i) => { row.Ids.RemoveAt(i); AssetListChanged(row); };
		list.OnMoveSlot = new [=this, =row](i, up) =>
			{
				let other = up ? i - 1 : i + 1;
				if ((other < 0) || (other >= row.Ids.Count))
					return;
				Swap!(row.Ids[i], row.Ids[other]);
				AssetListChanged(row);
			};
		list.OnAssignSlot = new [=this, =row](i, id) => { row.Ids[i] = id; AssetListChanged(row); };
		list.OnAppendDropped = new [=this, =row](id) => { row.Ids.Add(id); AssetListChanged(row); };
		list.OnPickSlot = new [=this, =row](i) =>
			{
				if (Context == null)
					return;
				let dialog = new AssetPickerDialog(mContext, scope StringView[](row.AssetType));
				dialog.OnPicked = new [=this, =row, =i](picked) =>
					{
						if (i < row.Ids.Count)
						{
							row.Ids[i] = picked;
							AssetListChanged(row);
						}
					};
				dialog.Show(Context);
			};
		row.List = list;
		// The editor keeps its own reference to its view; the layout gets one of its own.
		list.EditorView.AddRef();
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		row.Host.AddView(list.EditorView, match);
	}

	private void Apply()
	{
		let project = mContext.Project;
		if (project == null)
		{
			Close(.Cancel);
			return;
		}
		let settings = project.Settings;
		for (let asset in mAssets)
			*(Guid*)SettingFields.Address(settings, asset.Field) = asset.Id;
		for (let list in mAssetLists)
		{
			let ids = (List<Guid>*)SettingFields.Address(settings, list.Field);
			(*ids).Clear();
			for (let id in list.Ids)
			{
				// An unpicked slot is dropped, and an asset listed twice is listed once.
				if (id.IsSet && !(*ids).Contains(id))
					(*ids).Add(id);
			}
		}
		for (let value in mValues)
		{
			let address = SettingFields.Address(settings, value.Field);
			switch (value.Kind)
			{
			case .Text:
				(*(String*)address).Set(value.Text.Text);
			case .Count:
				*(uint32*)address = (uint32)value.Number.Value;
			case .Choice:
				let index = value.Choice.SelectedIndex;
				if ((index >= 0) && (index < value.ChoiceValues.Count))
					SettingFields.WriteChoice(settings, value.Field, value.ChoiceValues[index]);
			case .Flag:
				*(bool*)address = value.Flag.IsChecked.Value;
			default:
			}
		}
		if (mMsaaCombo != null)
			settings.RenderMsaaSamples = MsaaLevels.SamplesForIndex(mMsaaCombo.SelectedIndex);
		// The source-database path mirrors, for display and the older manifest fallback.
		settings.RefreshPathMirrors(scope (id, outPath) =>
			{
				if (let instance = project.SourceDb.GetInstance(id))
					instance.GetPath(outPath);
			});
		if (project.SaveSettings() case .Ok)
		{
			mContext.SetStatus("Project settings saved.");
			// Settings-derived session state (the default UI font and theme binds) re-applies
			// now; without this a changed default font kept the old bind until reopen.
			mContext.NotifyProjectSettingsChanged();
			GlobalLog(.Information, "Project: settings saved (default scene: {})",
				settings.DefaultScene.IsEmpty ? "(none)" : StringView(settings.DefaultScene));
		}
		else
		{
			mContext.Notify(.Error, "Project settings save FAILED (see console).");
		}
		Close(.OK);
	}
}
