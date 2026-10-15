using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
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
	/// The tab previews a phone held upright: its screen is a portrait phone's, and a game held
	/// to the other orientation is presented turned.
	[Appended]
	public bool PhonePreview = false;
}

/// The resolution the Game tab draws at (GameResolution.Collect says the choices). A fixed
/// choice is fitted into the panel by the project's render fit, as the player fits it into its
/// window, and turned when the game is held to the other orientation. The Phone toggle makes the
/// tab's screen a phone held upright, letterboxed in the panel.
extension GameEditorPage
{
	/// Seconds between looks at whether the choices changed (a preset, the project's
	/// resolution): cheap, and a reopened dropdown is fresh within one.
	private const float cResolutionRefreshSeconds = 1.0f;

	private ComboBox mResolutionCombo;
	private List<GameResolutionChoice> mResolutionChoices = new .() ~ DeleteContainerAndItems!(_);
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
	/// How the game is held (the chosen preset's, else the project's), and whether the tab
	/// previews a phone held upright.
	private ScreenOrientation mOrientation = .Any;
	private bool mPhonePreview = false;
	private ToolbarToggle mPhoneToggle;

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
		// A phone held upright: the game as a phone would show it, turned when it is held the
		// other way (mouse and touch map through the same turn).
		mPhoneToggle = mToolbar.AddToggle("Phone");
		mPhoneToggle.OnCheckedChanged.Add(new [=this](toggle, on) =>
		{
			if (mResolutionRebuilding)
				return;
			SetPhonePreview(on);
			SaveResolutionKey();
		});
		LoadResolutionKey();
		mResolutionRebuilding = true;
		mPhoneToggle.IsChecked = mPhonePreview;
		mResolutionRebuilding = false;
		RefreshResolutionChoices(true);
	}

	public List<GameResolutionChoice> ResolutionChoices()
	{
		RefreshResolutionChoices(false);
		return mResolutionChoices;
	}

	public StringView ResolutionKey => mResolutionKey;

	public bool SelectResolution(StringView key)
	{
		RefreshResolutionChoices(false);
		for (int32 i < (int32)mResolutionChoices.Count)
		{
			if (mResolutionChoices[i].Key != key)
				continue;
			mResolutionRebuilding = true; // the dropdown shows it; its handler stays out
			mResolutionCombo.SetSelectedIndex(i);
			mResolutionRebuilding = false;
			mResolutionKey.Set(mResolutionChoices[i].Key);
			SaveResolutionKey();
			ApplyResolution();
			return true;
		}
		return false;
	}

	public bool PhonePreview => mPhonePreview;

	public void SelectPhonePreview(bool on)
	{
		mResolutionRebuilding = true; // the toggle shows it; its handler stays out
		mPhoneToggle.IsChecked = on;
		mResolutionRebuilding = false;
		SetPhonePreview(on);
		SaveResolutionKey();
	}

	/// The phone preview: the tab's screen becomes a portrait phone's, or the panel again.
	private void SetPhonePreview(bool on)
	{
		mPhonePreview = on;
		ApplyResolution();
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
		let fresh = scope List<GameResolutionChoice>();
		defer ClearAndDeleteItems(fresh);
		CollectResolutionChoices(fresh);

		let signature = scope String();
		GameResolution.Signature(fresh, ProjectSettings(), signature);
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

	private void CollectResolutionChoices(List<GameResolutionChoice> outChoices)
	{
		ExportPresetSet presets = null;
		let loaded = scope ExportPresetSet();
		if (let project = mContext.Project)
		{
			let root = scope NativeFileSystem(project.Directory);
			if (ExportPresetsFile.Load(root, loaded) case .Ok)
				presets = loaded;
		}
		GameResolution.Collect(ProjectSettings(), presets, GamePreviewSettings.From(mContext.UserEditorSettings), outChoices);
	}

	/// The chosen size, fitted into the tab's screen by the project's render fit and turned to
	/// how the game is held, as the player fits it into its window: the scene draws at it into
	/// the fitted rectangle of the target, the screen UI lays out at it and draws crisp, and the
	/// pointer maps into it.
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
		mOrientation = choice.OverridesOrientation ? choice.Orientation : ((settings != null) ? settings.Orientation : .Any);
		// The previewed phone's screen is the target, letterboxed in the panel; else the panel is.
		mViewport.SetFixedResolution(mPhonePreview ? GameResolution.cPhonePreviewWidth : 0,
			mPhonePreview ? GameResolution.cPhonePreviewHeight : 0);
		mViewport.FitMode = mPhonePreview ? .Letterbox : .Stretch;
		SyncGameFit();
	}

	/// The input surface's content follows the game's fit on the tab's current target, which may
	/// change shape (and so the turn, and the pointer's map) as the panel resizes.
	private void SyncGameFit()
	{
		let w = mViewport.RenderWidth;
		let h = mViewport.RenderHeight;
		if ((w == 0) || (h == 0))
		{
			mViewport.SetContentResolution(mRenderWidth, mRenderHeight, mRenderFit);
			return;
		}
		let fit = GameFitIn(w, h);
		if (GameFitted(fit))
			mViewport.SetContentResolution((uint32)fit.ContentSize.X, (uint32)fit.ContentSize.Y, fit.Mode, fit.Rotation);
		else
			mViewport.SetContentResolution(0, 0, mRenderFit);
	}

	/// The game on a `width` x `height` target (the panel, or the previewed phone's screen), as
	/// the player puts it in its window.
	private ContentFit GameFitIn(uint32 width, uint32 height) =>
		GameResolution.GameFitOn(width, height, mRenderWidth, mRenderHeight, mRenderFit, mOrientation);

	/// Whether the game draws fitted (at a resolution of its own, or turned) rather than straight
	/// at the target.
	private bool GameFitted(ContentFit fit) => ((mRenderWidth > 0) && (mRenderHeight > 0)) || (fit.Rotation != .None);

	private Sedulous.Engine.Project.ProjectSettings ProjectSettings()
	{
		let project = mContext.Project;
		return (project != null) ? project.Settings : null;
	}

	private void LoadResolutionKey()
	{
		mResolutionKey.Set(GameResolution.cProjectKey);
		if (let store = mContext.ProjectEditorSettings)
		{
			if (let section = store.Find<GamePageSettings>())
			{
				if (!section.ResolutionKey.IsEmpty)
					mResolutionKey.Set(section.ResolutionKey);
				mPhonePreview = section.PhonePreview;
			}
		}
	}

	private void SaveResolutionKey()
	{
		let store = mContext.ProjectEditorSettings;
		if (store == null)
			return;
		store.Section<GamePageSettings>().ResolutionKey.Set(mResolutionKey);
		store.Section<GamePageSettings>().PhonePreview = mPhonePreview;
		store.MarkChanged<GamePageSettings>();
		mContext.RequestProjectEditorSettingsSave();
	}
}
