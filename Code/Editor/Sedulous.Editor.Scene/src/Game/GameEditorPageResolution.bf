using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.UI;
using Sedulous.VFS;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Scene;

/// The Game tab's resolution choice, per project: a section of the project's editor store.
[Serializable(1)]
class GamePageSettings
{
	/// The chosen entry's key: "project", "export:<preset>", "preset:<name>" or "panel".
	public String ResolutionKey = new .() ~ delete _;
}

/// The resolution the Game tab draws at. The project's own render resolution comes first and
/// is the default; then each export preset that draws at its own size; then the user's
/// preview presets (editor preferences); then the panel's own size. A fixed choice is fitted
/// into the panel by the project's render fit, as the player fits it into its window.
extension GameEditorPage
{
	private class ResolutionChoice
	{
		public String Key = new .() ~ delete _;
		public String Label = new .() ~ delete _;
		/// Nought for the panel's own size.
		public uint32 Width;
		public uint32 Height;
	}

	private const String cProjectKey = "project";
	private const String cPanelKey = "panel";
	/// Seconds between looks at whether the choices changed (a preset, the project's
	/// resolution): cheap, and a reopened dropdown is fresh within one.
	private const float cResolutionRefreshSeconds = 1.0f;

	private ComboBox mResolutionCombo;
	private List<ResolutionChoice> mResolutionChoices = new .() ~ DeleteContainerAndItems!(_);
	/// What the choices were built from; rebuilt only when it changes.
	private String mResolutionSignature = new .() ~ delete _;
	/// The chosen entry's key, kept across rebuilds and saved per project.
	private String mResolutionKey = new .() ~ delete _;
	private float mResolutionRefresh = 0.0f;
	/// Set while the items are replaced, so the rebuild's own selection is not a user's.
	private bool mResolutionRebuilding = false;
	/// What the game draws at, fitted into the panel by mRenderFit; nought draws at the
	/// panel's size.
	private uint32 mRenderWidth = 0;
	private uint32 mRenderHeight = 0;
	private FitMode mRenderFit = .Letterbox;

	private void CreateResolutionCombo()
	{
		mResolutionCombo = new ComboBox();
		var style = LayoutStyle();
		style.Width = SizeSpec.Fixed(Unit.Dp(220));
		mToolbar.AddItem(mResolutionCombo, style);
		mResolutionCombo.OnSelectionChanged.Add(new [=this](combo, index) =>
		{
			if (mResolutionRebuilding || (index < 0) || (index >= mResolutionChoices.Count))
				return;
			mResolutionKey.Set(mResolutionChoices[index].Key);
			SaveResolutionKey();
			ApplyResolution();
		});
		LoadResolutionKey();
		RefreshResolutionChoices(true);
	}

	/// Once a frame: rebuilds the choices when what they come from changed.
	private void TickResolution(float dt)
	{
		mResolutionRefresh -= dt;
		if (mResolutionRefresh > 0.0f)
			return;
		mResolutionRefresh = cResolutionRefreshSeconds;
		RefreshResolutionChoices(false);
	}

	private void RefreshResolutionChoices(bool force)
	{
		let fresh = scope List<ResolutionChoice>();
		defer ClearAndDeleteItems(fresh);
		CollectResolutionChoices(fresh);

		let signature = scope String();
		for (let choice in fresh)
			signature.AppendF("{}={}x{};", choice.Key, choice.Width, choice.Height);
		if (let settings = ProjectSettings())
			signature.AppendF("fit={}", (int)settings.RenderFit);
		if (!force && (signature == mResolutionSignature))
			return;
		mResolutionSignature.Set(signature);

		ClearAndDeleteItems(mResolutionChoices);
		for (let choice in fresh)
			mResolutionChoices.Add(choice);
		fresh.Clear();

		// The chosen entry survives a rebuild by its key; gone, the project's comes back.
		int32 selected = 0;
		for (int32 i < (int32)mResolutionChoices.Count)
		{
			if (mResolutionChoices[i].Key == mResolutionKey)
				selected = i;
		}
		mResolutionRebuilding = true;
		mResolutionCombo.ClearItems();
		for (let choice in mResolutionChoices)
			mResolutionCombo.AddItem(choice.Label);
		mResolutionCombo.SetSelectedIndex(selected);
		mResolutionRebuilding = false;
		mResolutionKey.Set(mResolutionChoices[selected].Key);
		ApplyResolution();
	}

	private void CollectResolutionChoices(List<ResolutionChoice> outChoices)
	{
		let settings = ProjectSettings();
		{
			let project = new ResolutionChoice();
			project.Key.Set(cProjectKey);
			if ((settings != null) && settings.HasRenderResolution)
			{
				project.Width = settings.RenderWidth;
				project.Height = settings.RenderHeight;
				project.Label.AppendF("Project {}x{}", project.Width, project.Height);
			}
			else
			{
				project.Label.Set("Project (panel size)");
			}
			outChoices.Add(project);
		}

		// The export presets that draw at their own size, as that platform would.
		if (let project = mContext.Project)
		{
			let root = scope NativeFileSystem(project.Directory);
			let presets = scope ExportPresetSet();
			if (ExportPresetsFile.Load(root, presets) case .Ok)
			{
				for (let preset in presets.Presets)
				{
					if (!preset.OverridesRender || (preset.RenderWidth == 0) || (preset.RenderHeight == 0))
						continue;
					let choice = new ResolutionChoice();
					choice.Key.AppendF("export:{}", preset.Name);
					choice.Label.AppendF("{} {}x{}", preset.Name, preset.RenderWidth, preset.RenderHeight);
					choice.Width = preset.RenderWidth;
					choice.Height = preset.RenderHeight;
					outChoices.Add(choice);
				}
			}
		}

		if (let previews = GamePreviewSettings.From(mContext.UserEditorSettings))
		{
			for (let preset in previews.Presets)
			{
				if ((preset.Width == 0) || (preset.Height == 0))
					continue;
				let choice = new ResolutionChoice();
				choice.Key.AppendF("preset:{}", preset.Name);
				choice.Label.AppendF("{} {}x{}", preset.Name, preset.Width, preset.Height);
				choice.Width = preset.Width;
				choice.Height = preset.Height;
				outChoices.Add(choice);
			}
		}

		let panel = new ResolutionChoice();
		panel.Key.Set(cPanelKey);
		panel.Label.Set("Fit to panel");
		outChoices.Add(panel);
	}

	/// The chosen size, fitted into the panel by the project's render fit, as the player fits
	/// it into its window: the scene draws at it into the fitted rectangle of a panel sized
	/// target, the screen UI lays out at it and draws crisp, and the pointer maps into it.
	private void ApplyResolution()
	{
		let index = mResolutionCombo.SelectedIndex;
		if ((index < 0) || (index >= mResolutionChoices.Count))
			return;
		let choice = mResolutionChoices[index];
		let settings = ProjectSettings();
		mRenderWidth = choice.Width;
		mRenderHeight = choice.Height;
		mRenderFit = (settings != null) ? settings.RenderFit : .Letterbox;
		mViewport.SetFixedResolution(0, 0);
		mViewport.FitMode = .Stretch;
		mViewport.SetContentResolution(mRenderWidth, mRenderHeight, mRenderFit);
	}

	/// The render resolution fitted into a panel sized target.
	private ContentFit RenderFitIn(uint32 width, uint32 height) =>
		ContentFit(.(0, 0, width, height), .(mRenderWidth, mRenderHeight), mRenderFit);

	private bool HasRenderResolution => (mRenderWidth > 0) && (mRenderHeight > 0);

	private Sedulous.Engine.Project.ProjectSettings ProjectSettings()
	{
		let project = mContext.Project;
		return (project != null) ? project.Settings : null;
	}

	private void LoadResolutionKey()
	{
		mResolutionKey.Set(cProjectKey);
		if (let store = mContext.ProjectEditorSettings)
		{
			if (let section = store.Find<GamePageSettings>())
			{
				if (!section.ResolutionKey.IsEmpty)
					mResolutionKey.Set(section.ResolutionKey);
			}
		}
	}

	private void SaveResolutionKey()
	{
		let store = mContext.ProjectEditorSettings;
		if (store == null)
			return;
		store.Section<GamePageSettings>().ResolutionKey.Set(mResolutionKey);
		store.MarkChanged<GamePageSettings>();
		mContext.RequestProjectEditorSettingsSave();
	}
}
