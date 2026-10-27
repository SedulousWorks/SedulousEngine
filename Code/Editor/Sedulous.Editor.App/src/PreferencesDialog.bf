using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Settings;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// EditorPreferencesDialog: the user's own editor settings (the settings store at
// <user-data>/editor.settings.xml), distinct from Project Settings, which edits the project
// (Raptor's editor-gui spec, 5.1, layer 12). A modal window of the editor's markup
// (Data/Editor/Preferences.gml), a tab per category. Appearance holds the look's inputs: the
// scheme, the accent (one of the editor's or any #rrggbb), the density, less motion and the UI
// scale; each change shows at once. Save writes them into the store and persists it; Cancel, its
// close button or Escape put the look back as it was. The other tabs (Shortcuts, Export, Agent
// access, Game preview, the domains' categories) come in the layer's later parts; until then they
// are in the parked Sedulous.UI dialog (EditorPreferencesDialog.bf).

/// What an EditorPreferencesDialog works over. The store is borrowed; the delegates are its own.
class EditorPreferencesServices
{
	/// The user's store; null: the defaults show and Save keeps nothing.
	public Settings User = null;
	/// Shows a look (the window's SetLook); unset: shown nowhere. Owned.
	public delegate void(EditorLook look) ShowLook ~ delete _;
	/// Persists the user's store, false when it could not be written; unset: nothing to write.
	/// Owned.
	public delegate bool() Persist ~ delete _;
}

class EditorPreferencesDialog
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/Preferences.gml";
	private const float cWidth = 560.0f;
	private const float cHeight = 440.0f;

	private EditorPreferencesServices mServices ~ delete _;
	/// A reference of ours (the window holds its own).
	private Node mBody = null ~ _?.ReleaseRef();
	/// A reference of ours: closed, it leaves the tree, and this keeps it for the next open.
	private Sedulous.GUI.Window mWindow = null ~ _?.ReleaseRef();
	/// The accents' segments' group, a reference of ours (each segment holds its own).
	private ButtonGroup mAccentGroup = null ~ _?.ReleaseRef();
	/// A segment per accent, in EditorLook.Accents' order, each a reference of ours.
	private List<Sedulous.GUI.Button> mAccents = new .() ~ { for (let segment in _) segment.ReleaseRef(); delete _; };
	/// As it was when it opened.
	private EditorLook mOriginal = new .() ~ delete _;
	/// As the controls have it.
	private EditorLook mLook = new .() ~ delete _;
	private bool mSaved = false;

	/// The dialog over `services`, its body `body` (the markup's controls by id). TAKES OWNERSHIP
	/// of the services and of a reference to `body`; null makes a dialog that never opens.
	public this(EditorPreferencesServices services, Node body)
	{
		mServices = services;
		mBody = body;
		if (mBody == null)
			return;
		mWindow = new Sedulous.GUI.Window();
		mWindow.Title = "Preferences";
		mWindow.AddClass("preferences-window");
		mWindow.Size = .(cWidth, cHeight);
		mWindow.Content.AddChild(mBody);
		Bind();
	}

	public ~this()
	{
		// Open as it goes, it closes as Cancel does: the look goes back.
		if ((mWindow != null) && mWindow.IsOpen)
			mWindow.Close();
		// The window may outlive this (its exit playing): its close reaches this no more.
		if (mWindow != null)
			mWindow.SetOnClose(null);
	}

	/// Opens it over `root` as a modal window, its controls as the store has the look; false with
	/// no markup, or when it is open already.
	public bool Open(Node root)
	{
		if ((mWindow == null) || mWindow.IsOpen)
			return false;
		mOriginal.ReadFrom((mServices.User != null) ? mServices.User.Find<EditorUiSettings>() : null);
		mLook.Set(mOriginal);
		mSaved = false;
		ShowControls();
		mWindow.OpenModal(root);
		return mWindow.IsOpen;
	}

	public bool IsOpen => (mWindow != null) && mWindow.IsOpen;

	/// Keeps the look: into the store, persisted, the window closed. False when the store could
	/// not be written (the look is kept all the same).
	public bool Save()
	{
		if (mServices.User != null)
		{
			mLook.StoreInto(mServices.User.Section<EditorUiSettings>());
			mServices.User.MarkChanged<EditorUiSettings>();
		}
		let persisted = (mServices.Persist == null) || mServices.Persist();
		mSaved = true;
		if (IsOpen)
			mWindow.Close();
		return persisted;
	}

	/// Puts the look back as it was and closes (its close puts it back).
	public void Cancel()
	{
		if (IsOpen)
			mWindow.Close();
	}

	/// The look as the controls have it now. The dialog's.
	public EditorLook Look => mLook;
	/// The window (its controls by id, for a test); null with no markup. The dialog's.
	public Sedulous.GUI.Window Window => mWindow;

	private T Find<T>(StringView id) where T : Node => (mBody != null) ? mBody.FindElement(id) as T : null;

	// The controls, once: each change of the user's shows the look at once. A state set from code
	// reports nothing, so ShowControls sets them without coming back here.
	private void Bind()
	{
		if (let dark = Find<Sedulous.GUI.Button>("pref-dark"))
			dark.SetOnToggled(new (on) => { if (on) { mLook.Dark = true; Changed(); } });
		if (let light = Find<Sedulous.GUI.Button>("pref-light"))
			light.SetOnToggled(new (on) => { if (on) { mLook.Dark = false; Changed(); } });
		if (let accents = mBody.FindElement("pref-accents"))
		{
			mAccentGroup = new ButtonGroup();
			for (int i < EditorLook.Accents.Count)
			{
				let accent = EditorLook.Accents[i];
				let segment = new Sedulous.GUI.Button();
				segment.AddClass("segment");
				segment.Text = accent.Name;
				segment.IsToggle = true;
				segment.Group = mAccentGroup;
				let fill = accent.Fill; // a literal's: it lives as long as the program
				segment.SetOnToggled(new [=fill, =this] (on) => { if (on) { mLook.Accent.Set(fill); Changed(); } });
				accents.AddChild(segment);
				mAccents.Add(segment);
			}
		}
		// Any #rrggbb typed takes; what is not one yet changes nothing.
		if (let field = Find<Sedulous.GUI.TextField>("pref-accent"))
		{
			field.SetOnTextChanging(new (text) =>
				{
					if (EditorLook.IsHexColor(text))
					{
						mLook.Accent.Set(text);
						Changed();
					}
				});
		}
		for (int i < EditorLook.Densities.Count)
		{
			let density = EditorLook.Densities[i];
			if (let segment = Find<Sedulous.GUI.Button>(scope $"pref-density-{density}"))
				segment.SetOnToggled(new [=density, =this] (on) => { if (on) { mLook.Density.Set(density); Changed(); } });
		}
		if (let motion = Find<Sedulous.GUI.CheckBox>("pref-motion"))
			motion.SetOnToggled(new (on) => { mLook.ReduceMotion = on; Changed(); });
		// A committed change (a drag let go, a key): the whole editor relayouts at a new scale, so
		// not under every step of a drag.
		if (let scale = Find<Sedulous.GUI.Slider>("pref-scale"))
			scale.SetOnValueChanged(new (chosen) => { mLook.UiScale = (float)chosen; Changed(); });
		if (let save = Find<Sedulous.GUI.Button>("pref-save"))
			save.SetOnClick(new () => { Save(); });
		if (let cancel = Find<Sedulous.GUI.Button>("pref-cancel"))
			cancel.SetOnClick(new () => { Cancel(); });
		// However it closes (Cancel, its close button, Escape), unsaved, the look goes back.
		mWindow.SetOnClose(new () =>
			{
				if (!mSaved && (mServices.ShowLook != null))
					mServices.ShowLook(mOriginal);
			});
	}

	private void Changed()
	{
		mLook.UiScale = Math.Clamp(mLook.UiScale, EditorUiSettings.MinUiScale, EditorUiSettings.MaxUiScale);
		ShowControls();
		if (mServices.ShowLook != null)
			mServices.ShowLook(mLook);
	}

	// The controls as mLook has it.
	private void ShowControls()
	{
		if (let dark = Find<Sedulous.GUI.Button>("pref-dark"))
			dark.Checked = mLook.Dark;
		if (let light = Find<Sedulous.GUI.Button>("pref-light"))
			light.Checked = !mLook.Dark;
		for (int i < mAccents.Count)
			mAccents[i].Checked = (StringView)mLook.Accent == EditorLook.Accents[i].Fill;
		if (let field = Find<Sedulous.GUI.TextField>("pref-accent"))
			field.Text = mLook.Accent; // the same text keeps the caret where it is
		for (int i < EditorLook.Densities.Count)
		{
			let density = EditorLook.Densities[i];
			if (let segment = Find<Sedulous.GUI.Button>(scope $"pref-density-{density}"))
				segment.Checked = density == (StringView)mLook.Density;
		}
		if (let motion = Find<Sedulous.GUI.CheckBox>("pref-motion"))
			motion.Checked = mLook.ReduceMotion;
		if (let scale = Find<Sedulous.GUI.Slider>("pref-scale"))
			scale.Value = mLook.UiScale;
		if (let shown = Find<Sedulous.GUI.Label>("pref-scale-value"))
			shown.Text = scope $"{(int32)(mLook.UiScale * 100.0f + 0.5f)}%";
	}
}
