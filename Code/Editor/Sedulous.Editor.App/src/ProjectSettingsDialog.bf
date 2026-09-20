using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.UI;
using Sedulous.Engine.Render;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// A modal editor for the project manifest, the fields a user meaningfully changes from
/// inside the editor: the name, the native module path, the default scene, startup script,
/// input map, bus layout, UI theme, loading screen and UI font (each picked by guid through
/// the AssetPickerDialog, the path kept as the human-readable mirror), and the scene-pass
/// MSAA. The engine version is shown read-only; every save re-stamps it. Save writes the
/// fields back into EditorProject.Settings and persists the manifest; Cancel discards.
class ProjectSettingsDialog : Dialog
{
	/// One guid-backed asset reference row: the label showing the path, Pick and Clear.
	private class AssetRow
	{
		public Guid Id = .Empty;
		public Label Label = null;
		public String TypeName = new .() ~ delete _;
		public String EmptyText = new .() ~ delete _;
	}

	/// Borrowed.
	private EditorContext mContext;
	// Borrowed: the content owns them.
	private EditText mNameEdit = null;
	/// A project-relative path; empty is none.
	private EditText mNativeModuleEdit = null;
	private ComboBox mMsaaCombo = null;
	private AssetRow mScene = new .() ~ delete _;
	private AssetRow mScript = new .() ~ delete _;
	private AssetRow mInputMap = new .() ~ delete _;
	private AssetRow mBusLayout = new .() ~ delete _;
	private AssetRow mUiTheme = new .() ~ delete _;
	private AssetRow mLoadingDoc = new .() ~ delete _;
	private AssetRow mUiFont = new .() ~ delete _;

	public this(EditorContext context) : base("Project Settings")
	{
		mContext = context;
		MinWidth.Value = 460.0f;
		MinHeight.Value = 240.0f;
		MaxWidth.Value = 560.0f;
		MaxHeight.Value = 560.0f; // taller so the rows fit; the ScrollView handles overflow

		let project = context.Project;
		let settings = (project != null) ? project.Settings : null;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 8;

		mNameEdit = AddTextRow(column, "Name", (settings != null) ? settings.Name : "");
		// The native game module: a project-relative path to the built module; free text,
		// since the module is built outside the editor and there is nothing to pick from.
		mNativeModuleEdit = AddTextRow(column, "Native module", (settings != null) ? settings.NativeModule : "");

		// The default scene: a read-only path plus Pick; the picker owns clearing too.
		{
			let row = AddRow(column, "Default scene");
			mScene.TypeName.Set("SceneDocument");
			mScene.EmptyText.Set("(none)");
			mScene.Label = AddAssetLabel(row, mScene);
			let pick = new Button("Pick...");
			pick.OnClick.Add(new (b) => { PickAsset(mScene); });
			row.AddView(pick);
			if (settings != null)
			{
				mScene.Id = settings.DefaultSceneId;
				// The live instance's path over the stored mirror, which can lie.
				if (!ShowPath(mScene) && !settings.DefaultScene.IsEmpty)
					mScene.Label.SetText(settings.DefaultScene);
			}
		}

		AddPickRow(column, "Startup script", mScript, "ScriptClassAsset", "(none)",
			(settings != null) ? settings.StartupScriptId : .Empty);
		AddPickRow(column, "Default input map", mInputMap, "InputMapAsset", "(none)",
			(settings != null) ? settings.DefaultInputMapId : .Empty);
		AddPickRow(column, "Default bus layout", mBusLayout, "AudioBusLayoutAsset", "(built-in)",
			(settings != null) ? settings.DefaultBusLayoutId : .Empty);
		AddPickRow(column, "Default UI theme", mUiTheme, "UIThemeAsset", "(built-in)",
			(settings != null) ? settings.DefaultUiThemeId : .Empty);
		AddPickRow(column, "Loading screen", mLoadingDoc, "UIDocumentAsset", "(built-in)",
			(settings != null) ? settings.LoadingDocumentId : .Empty);
		AddPickRow(column, "Default UI font", mUiFont, "FontAsset", "(built-in)",
			(settings != null) ? settings.DefaultUiFontId : .Empty);

		// The scene-pass MSAA: Off, 2x, 4x map to 1, 2, 4 samples. The player and play-in-editor
		// apply it; the render subsystem capability-clamps at runtime.
		{
			let row = AddRow(column, "MSAA");
			mMsaaCombo = new ComboBox();
			for (let level in MsaaLevels.All)
				mMsaaCombo.AddItem(level.Label);
			let samples = (settings != null) ? settings.RenderMsaaSamples : 1;
			mMsaaCombo.SetSelectedIndex(MsaaLevels.IndexForSamples(samples));
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			row.AddView(mMsaaCombo, grow);
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

	private Label AddAssetLabel(FlexLayout row, AssetRow asset)
	{
		let label = new Label(asset.EmptyText);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.AlignSelf = .Center;
		row.AddView(label, grow);
		return label;
	}

	/// A guid-picked reference row: the path label, Pick and Clear, seeded from the manifest.
	private void AddPickRow(FlexLayout column, StringView label, AssetRow asset, StringView typeName,
		StringView emptyText, Guid current)
	{
		let row = AddRow(column, label);
		asset.TypeName.Set(typeName);
		asset.EmptyText.Set(emptyText);
		asset.Label = AddAssetLabel(row, asset);
		let pick = new Button("Pick...");
		pick.OnClick.Add(new [=asset, =this](b) => { PickAsset(asset); });
		row.AddView(pick);
		let clear = new Button("Clear");
		clear.OnClick.Add(new [=asset](b) =>
			{
				asset.Id = .Empty;
				asset.Label.SetText(asset.EmptyText);
			});
		row.AddView(clear);
		asset.Id = current;
		ShowPath(asset);
	}

	/// Shows the live instance's path for the row's id; false, with the empty text shown,
	/// when it resolves to nothing.
	private bool ShowPath(AssetRow asset)
	{
		let project = mContext.Project;
		let instance = (asset.Id.IsSet && (project != null)) ? project.SourceDb.GetInstance(asset.Id) : null;
		if (instance != null)
		{
			asset.Label.SetText(instance.GetPath(.. scope .()));
			return true;
		}
		asset.Label.SetText(asset.EmptyText);
		return false;
	}

	/// The picker stacks above this dialog on the popup layer.
	private void PickAsset(AssetRow asset)
	{
		if (Context == null)
			return;
		let picker = new AssetPickerDialog(mContext, scope StringView[](asset.TypeName));
		picker.OnPicked = new [=asset, =this](id) =>
			{
				asset.Id = id;
				ShowPath(asset);
			};
		picker.Show(Context);
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
		settings.Name.Set(mNameEdit.Text);
		settings.NativeModule.Set(mNativeModuleEdit.Text);
		settings.StartupScriptId = mScript.Id;
		// The source-database path mirror, for display and the older manifest fallback.
		settings.StartupScript.Clear();
		if (let script = mScript.Id.IsSet ? project.SourceDb.GetInstance(mScript.Id) : null)
			script.GetPath(settings.StartupScript);
		settings.DefaultSceneId = mScene.Id;
		settings.DefaultInputMapId = mInputMap.Id;
		settings.DefaultBusLayoutId = mBusLayout.Id;
		settings.DefaultUiThemeId = mUiTheme.Id;
		settings.LoadingDocumentId = mLoadingDoc.Id;
		settings.DefaultUiFontId = mUiFont.Id;
		settings.RenderMsaaSamples = MsaaLevels.SamplesForIndex((mMsaaCombo != null) ? mMsaaCombo.SelectedIndex : 0);
		settings.DefaultScene.Clear();
		if (let scene = mScene.Id.IsSet ? project.SourceDb.GetInstance(mScene.Id) : null)
			scene.GetPath(settings.DefaultScene);
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
