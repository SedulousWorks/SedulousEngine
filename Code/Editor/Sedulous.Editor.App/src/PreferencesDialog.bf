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
// scale, and whether axis views are orthographic; each change of the look shows at once. Export
// holds the templates' folder, Agent access the MCP host (on, its port, its token), Game preview
// the sizes the Game tab offers. Shortcuts lists every action with its chord: a click captures the
// next keys, Reset goes back to the declaration's. Then a tab per category other parts of the
// editor contribute, its checks applied as they change. Save writes everything into the store (a
// chord another action holds refused, a port out of range kept as it was, each said in a warning)
// and persists it; Cancel, its close button or Escape put the look back as it was and forget the
// rest.

/// What an EditorPreferencesDialog works over. The store is borrowed; the delegates are its own.
class EditorPreferencesServices
{
	/// The user's store; null: the defaults show and Save keeps nothing.
	public Settings User = null;
	/// The actions the Shortcuts tab lists and Save rebinds; null: the tab is empty. Borrowed.
	public EditorActionRegistry Actions = null;
	/// Says a warning to the user (a chord another action holds, a port out of range); unset: said
	/// nowhere. Owned.
	public delegate void(StringView text) Warn ~ delete _;
	/// The settings other parts of the editor contribute, a tab per category; null: none. Borrowed
	/// (the context's): registered at boot, before the dialog is made, and kept until the editor
	/// goes.
	public List<EditorSettingsContribution> Contributions = null;
	/// The MCP section was saved: the host follows it over the open project; unset: nothing
	/// follows. Owned.
	public delegate void() McpChanged ~ delete _;
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
	/// The Shortcuts tab's edits, staged; applied and persisted on Save, forgotten at the next open.
	private ShortcutEdits mShortcutEdits = new .() ~ delete _;
	/// A row per preview resolution, in the list's order, made again at each open.
	private List<PreviewRow> mPreviews = new .() ~ DeleteContainerAndItems!(_);
	/// A check per contributed field, made once (the contributions come before the dialog).
	private List<Contributed> mContributed = new .() ~ delete _;
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
		delete mShortcutEdits;
		mShortcutEdits = new .();
		ShowControls();
		ShowSettings();
		ShowShortcuts();
		mWindow.OpenModal(root);
		return mWindow.IsOpen;
	}

	public bool IsOpen => (mWindow != null) && mWindow.IsOpen;

	/// Keeps the look, the other tabs and the shortcuts' edits: into the store, persisted, the
	/// window closed. A chord another action holds is refused, that action keeping it, and named in
	/// a warning; a port out of range is kept as it was, and said. False when the store could not
	/// be written (the rest is kept all the same).
	public bool Save()
	{
		if (mServices.User != null)
		{
			let ui = mServices.User.Section<EditorUiSettings>();
			mLook.StoreInto(ui);
			// The section marked once, the axis views' check with the look.
			if (let ortho = Find<Sedulous.GUI.CheckBox>("pref-auto-ortho"))
				ui.AutoOrthographic = ortho.Checked;
			mServices.User.MarkChanged<EditorUiSettings>();
			SaveSettings();
			if (!mShortcutEdits.IsEmpty && (mServices.Actions != null))
			{
				let collisions = scope List<String>();
				defer { ClearAndDeleteItems!(collisions); }
				mShortcutEdits.Apply(mServices.Actions, mServices.User.Section<EditorShortcutSettings>(), collisions);
				mServices.User.MarkChanged<EditorShortcutSettings>();
				if (mServices.Warn != null)
				{
					for (let collision in collisions)
						mServices.Warn(scope $"Shortcut kept: {collision}");
				}
			}
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
		if (let add = Find<Sedulous.GUI.Button>("pref-preview-add"))
			add.SetOnClick(new () => { AddPreview("Custom", 1920, 1080); });
		AddContributions();
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

	// The tabs beside the look and the keys, as the store has them.
	private void ShowSettings()
	{
		let user = mServices.User;
		if (let ortho = Find<Sedulous.GUI.CheckBox>("pref-auto-ortho"))
			ortho.Checked = EditorUiSettings.AutoOrthographicViews(user);
		if (let root = Find<Sedulous.GUI.TextField>("pref-templates-root"))
		{
			let exportSettings = (user != null) ? user.Find<EditorExportSettings>() : null;
			root.Text = (exportSettings != null) ? exportSettings.TemplatesRoot : "";
			// Empty, the default is what it takes, so the default is what it shows.
			root.Placeholder = Sedulous.Editor.Project.ExportTemplates.DefaultRoot(.. scope .());
		}
		let mcp = (user != null) ? user.Find<EditorMcpSettings>() : null;
		if (let enabled = Find<Sedulous.GUI.CheckBox>("pref-mcp-enabled"))
			enabled.Checked = (mcp != null) && mcp.Enabled;
		if (let port = Find<Sedulous.GUI.TextField>("pref-mcp-port"))
		{
			let shown = (mcp != null) ? mcp.Port : EditorMcpSettings.DefaultPort;
			port.Text = scope $"{shown}";
		}
		if (let token = Find<Sedulous.GUI.TextField>("pref-mcp-token"))
			token.Text = (mcp != null) ? mcp.Token : "";
		ShowPreviews();
		for (let check in mContributed)
			check.Box.Checked = (check.Field.Get != null) && check.Field.Get();
	}

	// Into the store: the templates' folder, the MCP host (the host then follows it), the preview
	// resolutions. The axis views' check goes with the look.
	private void SaveSettings()
	{
		let user = mServices.User;
		if (let root = Find<Sedulous.GUI.TextField>("pref-templates-root"))
		{
			user.Section<EditorExportSettings>().TemplatesRoot.Set(root.Text);
			user.MarkChanged<EditorExportSettings>();
		}
		let enabled = Find<Sedulous.GUI.CheckBox>("pref-mcp-enabled");
		let port = Find<Sedulous.GUI.TextField>("pref-mcp-port");
		let token = Find<Sedulous.GUI.TextField>("pref-mcp-token");
		if ((enabled != null) && (port != null) && (token != null))
		{
			if (!user.Section<EditorMcpSettings>().ApplyFromPreferences(enabled.Checked, port.Text, token.Text) && (mServices.Warn != null))
				mServices.Warn("The MCP port must be a number from 1024 to 65535; the old one is kept.");
			user.MarkChanged<EditorMcpSettings>();
			if (mServices.McpChanged != null)
				mServices.McpChanged();
		}
		if (let previews = GamePreviewSettings.From(user))
		{
			ClearAndDeleteItems!(previews.Presets);
			for (let row in mPreviews)
			{
				if (row.Removed || row.Name.Text.IsEmpty)
					continue;
				previews.Presets.Add(new .(row.Name.Text, (uint32)row.Width.Value, (uint32)row.Height.Value));
			}
			user.MarkChanged<GamePreviewSettings>();
		}
	}

	// Game preview: a row per resolution (its name, width and height, Remove), Add after them.
	private void ShowPreviews()
	{
		let list = Find<Node>("pref-previews");
		if (list == null)
			return;
		list.RemoveAllChildren();
		ClearAndDeleteItems!(mPreviews);
		if (let previews = GamePreviewSettings.From(mServices.User))
		{
			for (let preview in previews.Presets)
				AddPreview(preview.Name, preview.Width, preview.Height);
		}
	}

	private void AddPreview(StringView name, uint32 width, uint32 height)
	{
		let list = Find<Node>("pref-previews");
		if (list == null)
			return;
		let entry = new PreviewRow();
		entry.Row = new Sedulous.GUI.Panel();
		entry.Row.AddClass("pref-preview");
		entry.Name = new Sedulous.GUI.TextField();
		entry.Name.Text = name;
		entry.Width = SizeField(width);
		entry.Height = SizeField(height);
		let by = new Sedulous.GUI.Label();
		by.Text = "x";
		let remove = new Sedulous.GUI.Button();
		remove.AddClass("ghost");
		remove.Text = "Remove";
		let index = mPreviews.Count;
		// Hidden and skipped on Save rather than taken out from under its own click. The rows are
		// made again only at an open, when this one has left the tree.
		remove.SetOnClick(new [=this, =index] () =>
			{
				let removed = mPreviews[index];
				removed.Removed = true;
				removed.Row.Displayed = false;
			});
		entry.Row.AddChild(entry.Name);
		entry.Row.AddChild(entry.Width);
		entry.Row.AddChild(by);
		entry.Row.AddChild(entry.Height);
		entry.Row.AddChild(remove);
		list.AddChild(entry.Row);
		// The tree's references keep them.
		entry.Name.ReleaseRef();
		entry.Width.ReleaseRef();
		by.ReleaseRef();
		entry.Height.ReleaseRef();
		remove.ReleaseRef();
		entry.Row.ReleaseRef();
		mPreviews.Add(entry);
	}

	/// A whole number of pixels, 1 to 16384; its one reference is the caller's.
	private static Sedulous.GUI.NumberField SizeField(uint32 value)
	{
		let field = new Sedulous.GUI.NumberField();
		field.IsInteger = true;
		field.Min = 1.0;
		field.Max = 16384.0;
		field.Step = 1.0;
		field.Value = (double)value; // after the range, which would clamp it
		return field;
	}

	// A tab per category other parts of the editor contribute (contributions naming one category
	// share it), its checks applied as they change, not on Save.
	private void AddContributions()
	{
		let tabs = Find<Sedulous.GUI.TabView>("pref-tabs");
		if ((tabs == null) || (mServices.Contributions == null))
			return;
		let categories = scope List<StringView>();
		let columns = scope List<Node>();
		for (let contribution in mServices.Contributions)
		{
			Node column = null;
			for (int i < categories.Count)
			{
				if (categories[i] == contribution.Category)
					column = columns[i];
			}
			if (column == null)
			{
				let page = tabs.AddPage(contribution.Category);
				let body = new Sedulous.GUI.Panel();
				body.AddClass("dialog-body");
				body.AddClass("pref-contributed");
				page.AddChild(body);
				body.ReleaseRef(); // the page's reference keeps it
				column = body;
				categories.Add(contribution.Category);
				columns.Add(column);
			}
			for (let field in contribution.Bools)
			{
				let checkBox = new Sedulous.GUI.CheckBox();
				checkBox.Text = field.Label;
				if (!field.Description.IsEmpty)
					checkBox.Tooltip = field.Description;
				// The field is the context's, kept from boot: registrations come before the dialog.
				checkBox.SetOnToggled(new [=field] (on) =>
					{
						if (field.Set != null)
							field.Set(on);
					});
				column.AddChild(checkBox);
				checkBox.ReleaseRef(); // the tree's reference keeps it
				mContributed.Add(.(field, checkBox));
			}
		}
	}

	// The Shortcuts tab: a row per action (its name, where it is in the menus, its chord as a capture
	// button, Reset), the chord as the registry has it now. A chosen chord or a reset is staged.
	private void ShowShortcuts()
	{
		let list = Find<Node>("pref-shortcuts");
		if ((list == null) || (mServices.Actions == null))
			return;
		list.RemoveAllChildren();
		let actions = mServices.Actions;
		for (let action in actions.Actions)
		{
			let row = new Sedulous.GUI.Panel();
			row.AddClass("pref-shortcut");
			let name = new Sedulous.GUI.Label();
			name.AddClass("row-name");
			name.Text = action.Label;
			let @where = new Sedulous.GUI.Label();
			@where.AddClass("pref-where");
			@where.Text = action.MenuPath;
			let capture = new ShortcutCaptureButton();
			capture.SetChord(actions.Shortcut(action.Id));
			let reset = new Sedulous.GUI.Button();
			reset.AddClass("ghost");
			reset.Text = "Reset";
			reset.Enabled = actions.HasOverride(action.Id);
			// The row's: its own buttons reach each other, and the declaration outlives the dialog's
			// rows (the registry keeps it until the editor goes).
			capture.SetOnChordChosen(new [=this, =action, =reset] (chord) =>
				{
					mShortcutEdits.Set(action.Id, chord);
					reset.Enabled = true;
				});
			reset.SetOnClick(new [=this, =action, =capture, =reset] () =>
				{
					mShortcutEdits.Reset(action.Id);
					capture.SetChord(action.Shortcut); // the default, shown at once
					reset.Enabled = false;
				});
			row.AddChild(name);
			row.AddChild(@where);
			row.AddChild(capture);
			row.AddChild(reset);
			list.AddChild(row);
			// The tree's references keep them.
			name.ReleaseRef();
			@where.ReleaseRef();
			capture.ReleaseRef();
			reset.ReleaseRef();
			row.ReleaseRef();
		}
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

	/// One preview resolution's row; its views are the tree's.
	private class PreviewRow
	{
		public Sedulous.GUI.Panel Row;
		public Sedulous.GUI.TextField Name;
		public Sedulous.GUI.NumberField Width;
		public Sedulous.GUI.NumberField Height;
		public bool Removed = false;
	}

	/// A contributed field and its check, the tree's.
	private struct Contributed : this(EditorSettingsBoolField Field, Sedulous.GUI.CheckBox Box);
}
