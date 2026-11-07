using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// Preferences over its own markup (Data/Editor/Preferences.xml): its controls as the user's store
/// has the look (what the store names wrongly, the defaults); each change of each input shown at
/// once; Save into the store, marked changed and persisted; Cancel, Escape, its close button, or
/// the dialog going while open, putting the look back as it was with the store unchanged; the
/// Shortcuts tab's edits staged, applied on Save (a chord another action holds refused, named),
/// forgotten on Cancel, Reset going back to the declaration's; the orthographic check, the
/// templates' folder (empty: the default shown), the MCP host's fields (a port out of range kept,
/// said; the host told on Save), the preview resolutions (added, removed) and the contributed
/// categories' tabs (shared by a category, their checks applied as they change).
static class PreferencesDialogTests
{
	/// A GUI scene for the dialog to open over, the user's store (violet), two actions (Save on
	/// Ctrl+S, Open on Ctrl+O), a contributed Navigation category (one check, Snapping), the looks
	/// it showed, the warnings it said, the persists it asked for and the times it told the MCP
	/// host.
	private class Bed
	{
		public SceneRoot Root;
		public Settings Store = new .() ~ delete _;
		public EditorActionRegistry Actions = new .() ~ delete _;
		/// Outlives the dialog (the context's would): ~this deletes the dialog first.
		public List<EditorSettingsContribution> Contributions = new .() ~ DeleteContainerAndItems!(_);
		/// A contributed setting, Navigation's "Snap agents to the mesh".
		public bool Snapping = true;
		/// Two more fields: Audio's "Mute in the background" and Navigation's "Show the bake bounds".
		public bool Muted = false;
		public bool BakeBounds = false;
		public int McpChanged = 0;
		public List<String> Warnings = new .() ~ DeleteContainerAndItems!(_);
		public List<EditorLook> Shown = new .() ~ DeleteContainerAndItems!(_);
		public int Persisted = 0;
		/// What a persist answers.
		public bool PersistHolds = true;
		public EditorPreferencesDialog Dialog = null ~ delete _;

		/// `moreCategories`: Audio, then a second Navigation contribution, after the first.
		public this(StringView accent = "#6d5bd8", StringView density = "compact", bool moreCategories = false)
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(1000.0f, 700.0f);
			Store.Section<EditorUiSettings>().Accent.Set(accent);
			Store.Section<EditorUiSettings>().Density.Set(density);
			Declare("file.save", "Save", "ctrl-s");
			Declare("file.open", "Open", "ctrl-o");
			let services = new EditorPreferencesServices();
			services.User = Store;
			services.Actions = Actions;
			services.Warn = new (text) => { Warnings.Add(new String(text)); };
			Contribute("Navigation", "Snap agents to the mesh", new () => Snapping, new (on) => { Snapping = on; });
			if (moreCategories)
			{
				Contribute("Audio", "Mute in the background", new () => Muted, new (on) => { Muted = on; });
				Contribute("Navigation", "Show the bake bounds", new () => BakeBounds, new (on) => { BakeBounds = on; });
			}
			services.Contributions = Contributions;
			services.McpChanged = new () => { McpChanged++; };
			services.ShowLook = new (look) => { Shown.Add(new EditorLook()..Set(look)); };
			services.Persist = new () =>
				{
					Persisted++;
					return PersistHolds;
				};
			Dialog = new EditorPreferencesDialog(services, LoadPreferences());
		}

		public ~this()
		{
			DeleteAndNullify!(Dialog); // closed while the root is there
			Root.ReleaseRef();
		}

		private void Contribute(StringView category, StringView label, delegate bool() get, delegate void(bool) set)
		{
			let contribution = new EditorSettingsContribution(category);
			contribution.Bools.Add(new EditorSettingsBoolField(label, "", get, set));
			Contributions.Add(contribution);
		}

		private void Declare(StringView id, StringView label, StringView keys)
		{
			let d = new EditorActionDeclaration(id, label, "", scope $"File/{label}");
			d.Shortcut = EditorShortcut.Of(keys);
			d.Execute = new (page) => {};
			Test.Assert(Actions.Register(d));
		}

		public Sedulous.GUI.EventDispatcher Dispatcher => Root.EventDispatcher;
		public Sedulous.GUI.Window Window => Dialog.Window;
		public EditorLook Last => Shown.Back;
		public EditorUiSettings Ui => Store.Find<EditorUiSettings>();

		public bool Press(KeyCode key, uint32 modifiers = 0) => Root.EventDispatcher.InjectKeyDown((uint32)key, modifiers);
	}

	/// The dialog's body, read from the repository's Data with the GUI's elements; its one
	/// reference is the caller's. EditorMcpServiceTests' dialog over a real host reads it too.
	public static Node LoadPreferences()
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		let path = PathJoin(data, EditorPreferencesDialog.cMarkupPath, .. scope .());
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(path, text) case .Ok);
		RegisterGuiElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	private static T Find<T>(Node node, StringView id) where T : Node => node.FindElement(id) as T;

	/// The button showing `text` under `node` (an accent's segment, made by code, has no id).
	private static Sedulous.GUI.Button ButtonText(Node node, StringView text)
	{
		if (let button = node as Sedulous.GUI.Button)
		{
			if (button.Text == text)
				return button;
		}
		for (int i < node.ChildCount)
		{
			if (let found = ButtonText(node.GetChildAt(i), text))
				return found;
		}
		return null;
	}

	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	/// The chord capture buttons under `node`, in the tree's order (a row per action).
	private static void Captures(Node node, List<ShortcutCaptureButton> outCaptures)
	{
		if (let capture = node as ShortcutCaptureButton)
			outCaptures.Add(capture);
		for (int i < node.ChildCount)
			Captures(node.GetChildAt(i), outCaptures);
	}

	/// The index of the page titled `title`, or -1.
	private static int32 PageTitled(TabView tabs, StringView title)
	{
		for (int32 i < tabs.PageCount)
		{
			if (let page = tabs.GetPage(i) as TabPage)
			{
				if (page.Title == title)
					return i;
			}
		}
		return -1;
	}

	/// The check boxes under `node`, in the tree's order.
	private static void Checks(Node node, List<Sedulous.GUI.CheckBox> outBoxes)
	{
		if (let checkBox = node as Sedulous.GUI.CheckBox)
			outBoxes.Add(checkBox);
		for (int i < node.ChildCount)
			Checks(node.GetChildAt(i), outBoxes);
	}

	/// The one check checkBox showing `text` under `node`; null when none does, or more than one.
	private static Sedulous.GUI.CheckBox CheckTexted(Node node, StringView text)
	{
		let boxes = scope List<Sedulous.GUI.CheckBox>();
		Checks(node, boxes);
		Sedulous.GUI.CheckBox found = null;
		for (let checkBox in boxes)
		{
			if (checkBox.Text == text)
			{
				if (found != null)
					return null;
				found = checkBox;
			}
		}
		return found;
	}

	/// The Shortcuts tab shown, its capture buttons in `outCaptures`.
	private static void ShowShortcutsTab(Bed bed, List<ShortcutCaptureButton> outCaptures)
	{
		let tabs = Find<TabView>(bed.Window, "pref-tabs");
		Test.Assert(tabs != null);
		let shortcuts = PageTitled(tabs, "Shortcuts");
		Test.Assert(shortcuts >= 0);
		tabs.SelectedIndex = shortcuts;
		bed.Root.UpdateLayout();
		outCaptures.Clear();
		Captures(bed.Window, outCaptures);
	}

	[Test]
	public static void ItsControlsAreTheStoresLookEachChangeShowsAtOnceAndSaveKeepsItPersisted()
	{
		let bed = scope Bed();
		Test.Assert(bed.Window != null, "its markup loaded");
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(bed.Dialog.IsOpen);
		Test.Assert(!bed.Dialog.Open(bed.Root), "open already");
		let window = bed.Window;
		let dark = Find<Sedulous.GUI.Button>(window, "pref-dark");
		let light = Find<Sedulous.GUI.Button>(window, "pref-light");
		let compact = Find<Sedulous.GUI.Button>(window, "pref-density-compact");
		let comfortable = Find<Sedulous.GUI.Button>(window, "pref-density-comfortable");
		let motion = Find<Sedulous.GUI.CheckBox>(window, "pref-motion");
		let accent = Find<Sedulous.GUI.TextField>(window, "pref-accent");
		let scale = Find<Sedulous.GUI.Slider>(window, "pref-scale");
		let scaleShown = Find<Sedulous.GUI.Label>(window, "pref-scale-value");
		Test.Assert((dark != null) && (light != null) && (compact != null) && (comfortable != null));
		Test.Assert((motion != null) && (accent != null) && (scale != null) && (scaleShown != null));
		let azure = ButtonText(window, "Azure");
		let violet = ButtonText(window, "Violet");
		let teal = ButtonText(window, "Teal");
		Test.Assert((azure != null) && (violet != null) && (teal != null) && (ButtonText(window, "Magenta") != null), "a segment per accent");

		// As the store has it.
		Test.Assert(dark.Checked && !light.Checked);
		Test.Assert(compact.Checked && !comfortable.Checked);
		Test.Assert(violet.Checked && !azure.Checked);
		Test.Assert(accent.Text == "#6d5bd8");
		Test.Assert(!motion.Checked);
		Test.Assert(scale.Value == 1.0);
		Test.Assert(scaleShown.Text == "100%");
		Test.Assert(bed.Shown.IsEmpty, "nothing changed yet");

		// The scheme, either way.
		Test.Assert(light.HandleActivate());
		Test.Assert(bed.Shown.Count == 1);
		Test.Assert(!bed.Last.Dark);
		Test.Assert(!dark.Checked, "one of the two");
		Test.Assert(dark.HandleActivate());
		Test.Assert((bed.Shown.Count == 2) && bed.Last.Dark);
		Test.Assert(light.HandleActivate());
		Test.Assert((bed.Shown.Count == 3) && !bed.Last.Dark);

		// An accent's segment: its fill, in the field too.
		Test.Assert(teal.HandleActivate());
		Test.Assert(bed.Shown.Count == 4);
		Test.Assert(bed.Last.Accent == "#0f8a7e");
		Test.Assert(accent.Text == "#0f8a7e");
		Test.Assert(teal.Checked && !violet.Checked);

		// Any #rrggbb typed: no segment is it.
		let d = bed.Dispatcher;
		d.FocusNode = accent;
		accent.SelectAll();
		d.InjectText("#123abc");
		Test.Assert(accent.Text == "#123abc");
		Test.Assert(bed.Last.Accent == "#123abc");
		Test.Assert(!teal.Checked && !violet.Checked && !azure.Checked);
		// Not a colour (yet): nothing shown, the look keeps the last one.
		let shownBefore = bed.Shown.Count;
		accent.SelectAll();
		d.InjectText("#12");
		Test.Assert(bed.Shown.Count == shownBefore);
		Test.Assert(bed.Dialog.Look.Accent == "#123abc");
		Test.Assert(teal.HandleActivate());
		Test.Assert((bed.Last.Accent == "#0f8a7e") && (accent.Text == "#0f8a7e"));

		// The density.
		Test.Assert(comfortable.HandleActivate());
		Test.Assert(bed.Last.Density == "comfortable");
		Test.Assert(!compact.Checked);

		// Less motion.
		Test.Assert(motion.HandleActivate());
		Test.Assert(bed.Last.ReduceMotion);

		// The UI scale, by its keys: to its end, then a step back.
		d.FocusNode = scale;
		Test.Assert(bed.Press(.End));
		Test.Assert(Near(bed.Last.UiScale, 2.0f));
		Test.Assert(scaleShown.Text == "200%");
		Test.Assert(bed.Press(.Left));
		Test.Assert(Near(bed.Last.UiScale, 1.95f));
		Test.Assert(scaleShown.Text == "195%");
		// Each look shown is the whole look, not the one input.
		Test.Assert(!bed.Last.Dark && (bed.Last.Accent == "#0f8a7e") && (bed.Last.Density == "comfortable") && bed.Last.ReduceMotion);

		// Save: into the store, marked changed (the look's section, then the templates', the MCP
		// host's and the preview sizes'), persisted, closed; nothing put back.
		int changes = 0;
		bed.Store.OnChanged.Add(new [&] (name) => { changes++; });
		let shownAtSave = bed.Shown.Count;
		Test.Assert(bed.Dialog.Save());
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(bed.Persisted == 1);
		Test.Assert(changes == 4);
		let ui = bed.Ui;
		Test.Assert(ui.Scheme == "light");
		Test.Assert(ui.Accent == "#0f8a7e");
		Test.Assert(ui.Density == "comfortable");
		Test.Assert(ui.ReduceMotion);
		Test.Assert(Near(ui.UiScale, 1.95f));
		Test.Assert(bed.Shown.Count == shownAtSave, "saved: nothing put back");

		// Opened again: as the store has it now. Its Save button saves as Save does; a store that
		// could not be written answers false, the look kept all the same.
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(light.Checked && comfortable.Checked && teal.Checked && motion.Checked);
		Test.Assert(scaleShown.Text == "195%");
		Test.Assert(Find<Sedulous.GUI.Button>(window, "pref-save").HandleActivate());
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(bed.Persisted == 2);
		bed.PersistHolds = false;
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(dark.HandleActivate());
		Test.Assert(!bed.Dialog.Save());
		Test.Assert(bed.Persisted == 3);
		Test.Assert(bed.Ui.Scheme == "dark");
		Test.Assert(bed.Last.Dark, "kept: not put back");
	}

	/// The UI scale's percentage follows a drag as it goes; the scale applies on release.
	[Test]
	public static void TheUIScalesPercentageFollowsADragTheScaleAppliesOnRelease()
	{
		let bed = scope Bed();
		Test.Assert(bed.Dialog.Open(bed.Root));
		bed.Root.UpdateLayout();
		let window = bed.Window;
		let scale = Find<Sedulous.GUI.Slider>(window, "pref-scale");
		let shown = Find<Sedulous.GUI.Label>(window, "pref-scale-value");
		Test.Assert((scale != null) && (shown != null));
		Test.Assert(shown.Text == "100%");

		// Mid-drag the slider reports input: the label shows where it is, nothing is applied.
		let y = scale.Size.Y * 0.5f;
		let d = bed.Dispatcher;
		d.InjectMouseDown(scale.ConvertToWorldSpace(.(scale.Size.X * 0.25f, y)), .Left);
		d.InjectMouseMove(scale.ConvertToWorldSpace(.(scale.Size.X * 0.75f, y)));
		let dragged = (float)scale.Value;
		Test.Assert(dragged > 1.0f, "dragged up from 100%");
		Test.Assert(shown.Text == scope $"{(int32)(dragged * 100.0f + 0.5f)}%", "the label follows the drag");
		Test.Assert(bed.Shown.IsEmpty, "not applied mid-drag");

		// The release commits it, which applies it.
		d.InjectMouseUp(scale.ConvertToWorldSpace(.(scale.Size.X * 0.75f, y)), .Left);
		Test.Assert(bed.Shown.Count == 1);
		Test.Assert(Near(bed.Last.UiScale, dragged));
		Test.Assert(shown.Text == scope $"{(int32)(dragged * 100.0f + 0.5f)}%");
	}

	[Test]
	public static void CancelEscapeItsCloseButtonOrGoingWhileOpenPutTheLookBackTheStoreUnchanged()
	{
		let bed = scope Bed();
		let window = bed.Window;
		Test.Assert(window != null);
		let dark = Find<Sedulous.GUI.Button>(window, "pref-dark");
		let light = Find<Sedulous.GUI.Button>(window, "pref-light");
		let comfortable = Find<Sedulous.GUI.Button>(window, "pref-density-comfortable");
		let motion = Find<Sedulous.GUI.CheckBox>(window, "pref-motion");
		let scale = Find<Sedulous.GUI.Slider>(window, "pref-scale");
		Test.Assert((dark != null) && (light != null) && (comfortable != null) && (motion != null) && (scale != null));

		// Cancel.
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(light.HandleActivate());
		Test.Assert(!bed.Last.Dark);
		Test.Assert(Find<Sedulous.GUI.Button>(window, "pref-cancel").HandleActivate());
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(bed.Shown.Count == 2);
		Test.Assert(bed.Last.Dark, "back");
		Test.Assert(bed.Last.Accent == "#6d5bd8", "as the store had it");
		Test.Assert(bed.Ui.Scheme == "dark");

		// Escape.
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(dark.Checked, "as the store has it, not as it was left");
		Test.Assert(comfortable.HandleActivate());
		Test.Assert(bed.Last.Density == "comfortable");
		bed.Dispatcher.FocusNode = dark;
		bed.Press(.Escape);
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(bed.Last.Density == "compact");
		Test.Assert(bed.Ui.Density == "compact");

		// Its close button (what a click on it runs).
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(motion.HandleActivate());
		Test.Assert(bed.Last.ReduceMotion);
		window.RequestClose();
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(!bed.Last.ReduceMotion);
		Test.Assert(!bed.Ui.ReduceMotion);

		// Cancel from code, the scale changed.
		Test.Assert(bed.Dialog.Open(bed.Root));
		bed.Dispatcher.FocusNode = scale;
		Test.Assert(bed.Press(.End));
		Test.Assert(Near(bed.Last.UiScale, 2.0f));
		bed.Dialog.Cancel();
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(Near(bed.Last.UiScale, 1.0f));
		Test.Assert(Near(bed.Ui.UiScale, 1.0f));
		Test.Assert(bed.Persisted == 0, "nothing written");

		// The dialog going while open (the editor's shutdown): as Cancel.
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(light.HandleActivate());
		let shown = bed.Shown.Count;
		DeleteAndNullify!(bed.Dialog);
		Test.Assert(bed.Shown.Count == shown + 1);
		Test.Assert(bed.Last.Dark);
		Test.Assert(bed.Persisted == 0);
	}

	[Test]
	public static void WhatTheStoreNamesWronglyShowsAsTheDefaultAndNoMarkupNeverOpens()
	{
		let bed = scope Bed("red", "roomy");
		Test.Assert(bed.Dialog.Open(bed.Root));
		let window = bed.Window;
		Test.Assert(ButtonText(window, "Azure").Checked);
		Test.Assert(Find<Sedulous.GUI.TextField>(window, "pref-accent").Text == "#2f6fdf");
		Test.Assert(Find<Sedulous.GUI.Button>(window, "pref-density-compact").Checked);
		Test.Assert((bed.Dialog.Look.Accent == "#2f6fdf") && (bed.Dialog.Look.Density == "compact"));
		// Saved, the store has the look as shown.
		Test.Assert(bed.Dialog.Save());
		Test.Assert((bed.Ui.Accent == "#2f6fdf") && (bed.Ui.Density == "compact"));

		// No markup: no window, nothing opens.
		let services = new EditorPreferencesServices();
		services.User = bed.Store;
		let none = scope EditorPreferencesDialog(services, null);
		Test.Assert(none.Window == null);
		Test.Assert(!none.Open(bed.Root));
		Test.Assert(!none.IsOpen);
	}

	[Test]
	public static void ShortcutsListsEveryActionAnEditIsStagedAndAppliedOnSaveOneAnotherHoldsRefusedResetGoesBack()
	{
		let bed = scope Bed();
		Test.Assert(bed.Dialog.Open(bed.Root));
		let captures = scope List<ShortcutCaptureButton>();
		ShowShortcutsTab(bed, captures);
		Test.Assert(captures.Count == 2, "Save, Open");
		Test.Assert(captures[0].Chord == EditorShortcut.Of("ctrl-s"));
		Test.Assert(captures[1].Chord == EditorShortcut.Of("ctrl-o"));
		// Each row names its action and where it is in the menus.
		let row = captures[0].Parent;
		Test.Assert((row != null) && (row.ChildCount == 4));
		Test.Assert((row.GetChildAt(0) as Sedulous.GUI.Label).Text == "Save");
		Test.Assert((row.GetChildAt(1) as Sedulous.GUI.Label).Text == "File/Save");
		let resetSave = row.GetChildAt(3) as Sedulous.GUI.Button;
		Test.Assert((resetSave != null) && (resetSave.Text == "Reset"));
		Test.Assert(!resetSave.Enabled, "no override yet");

		Test.Assert(captures[0].HandleActivate());
		Test.Assert(bed.Press(.F2));
		Test.Assert(captures[0].Chord == EditorShortcut.Of("f2"));
		Test.Assert(resetSave.Enabled, "chosen: there is something to reset");
		Test.Assert(captures[1].HandleActivate());
		Test.Assert(bed.Press(.F2)); // the one Save now holds
		Test.Assert(captures[1].Chord == EditorShortcut.Of("f2"), "shown as chosen; refused on Save");
		Test.Assert(bed.Actions.Shortcut("file.save") == EditorShortcut.Of("ctrl-s"), "staged, not yet");
		Test.Assert(bed.Actions.Shortcut("file.open") == EditorShortcut.Of("ctrl-o"));
		Test.Assert(bed.Store.Find<EditorShortcutSettings>() == null);

		Test.Assert(bed.Dialog.Save());
		Test.Assert(bed.Persisted == 1);
		Test.Assert(bed.Actions.Shortcut("file.save") == EditorShortcut.Of("f2"));
		Test.Assert(bed.Actions.Shortcut("file.open") == EditorShortcut.Of("ctrl-o"), "refused");
		Test.Assert(!bed.Actions.HasOverride("file.open"));
		Test.Assert(bed.Warnings.Count == 1);
		Test.Assert(bed.Warnings[0].StartsWith("Shortcut kept: ") && bed.Warnings[0].Contains("'Save'"), "the holder named");
		let section = bed.Store.Find<EditorShortcutSettings>();
		Test.Assert(section != null);
		Test.Assert((section.Overrides.Count == 1) && (section.Find("file.save").Keys == "f2"));

		// Opened again: as the registry has it now; Reset puts Save back to its declared chord, shown
		// at once, kept on Save.
		Test.Assert(bed.Dialog.Open(bed.Root));
		ShowShortcutsTab(bed, captures);
		Test.Assert(captures.Count == 2, "the rows made again, not added to");
		Test.Assert(captures[0].Chord == EditorShortcut.Of("f2"));
		Test.Assert(captures[1].Chord == EditorShortcut.Of("ctrl-o"));
		let reset = ButtonText(bed.Window, "Reset");
		Test.Assert(reset != null);
		Test.Assert(reset.Enabled, "Save has an override");
		Test.Assert(reset.HandleActivate());
		Test.Assert(captures[0].Chord == EditorShortcut.Of("ctrl-s"));
		Test.Assert(!reset.Enabled);
		Test.Assert(bed.Actions.Shortcut("file.save") == EditorShortcut.Of("f2"), "staged, not yet");
		Test.Assert(bed.Dialog.Save());
		Test.Assert(bed.Actions.Shortcut("file.save") == EditorShortcut.Of("ctrl-s"));
		Test.Assert(!bed.Actions.HasOverride("file.save"));
		Test.Assert(bed.Store.Find<EditorShortcutSettings>().Overrides.IsEmpty);
		Test.Assert(bed.Warnings.Count == 1, "nothing refused");
	}

	[Test]
	public static void AShortcutsEditIsForgottenOnCancelAndACaptureTakesEscapeBeforeTheDialog()
	{
		let bed = scope Bed();
		Test.Assert(bed.Dialog.Open(bed.Root));
		let captures = scope List<ShortcutCaptureButton>();
		ShowShortcutsTab(bed, captures);
		Test.Assert(captures.Count == 2);

		// Escape while a capture waits is the capture's: it cancels, the dialog stays.
		Test.Assert(captures[1].HandleActivate());
		Test.Assert(captures[1].IsCapturing);
		bed.Press(.Escape);
		Test.Assert(!captures[1].IsCapturing);
		Test.Assert(bed.Dialog.IsOpen);
		Test.Assert(captures[1].Chord == EditorShortcut.Of("ctrl-o"));

		// Chosen, then Cancel: the registry and the store as they were.
		Test.Assert(captures[1].HandleActivate());
		Test.Assert(bed.Press(.O, KeyModCtrl | KeyModShift));
		Test.Assert(captures[1].Chord == EditorShortcut.Of("ctrl-shift-o"));
		bed.Dialog.Cancel();
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(bed.Actions.Shortcut("file.open") == EditorShortcut.Of("ctrl-o"));
		Test.Assert(bed.Store.Find<EditorShortcutSettings>() == null);
		Test.Assert(bed.Persisted == 0);

		// Opened again and saved: the cancelled edit is gone, not applied late.
		Test.Assert(bed.Dialog.Open(bed.Root));
		ShowShortcutsTab(bed, captures);
		Test.Assert(captures[1].Chord == EditorShortcut.Of("ctrl-o"));
		Test.Assert(bed.Dialog.Save());
		Test.Assert(bed.Actions.Shortcut("file.open") == EditorShortcut.Of("ctrl-o"));
		Test.Assert(!bed.Actions.HasOverride("file.open"));
		Test.Assert(bed.Warnings.IsEmpty);

		// Delete chooses none: kept on Save as "no shortcut", not as the default.
		Test.Assert(bed.Dialog.Open(bed.Root));
		ShowShortcutsTab(bed, captures);
		Test.Assert(captures[1].HandleActivate());
		Test.Assert(bed.Press(.Delete));
		Test.Assert(bed.Dialog.Save());
		Test.Assert(bed.Actions.HasOverride("file.open"));
		Test.Assert(!bed.Actions.Shortcut("file.open").IsSet);
		Test.Assert(bed.Store.Find<EditorShortcutSettings>().Find("file.open").Keys.IsEmpty);
	}

	[Test]
	public static void TheOtherTabsAxisViewsTemplatesTheMcpHostABadPortKeptPreviewSizesAContributedCategory()
	{
		let bed = scope Bed();
		bed.Store.Section<EditorMcpSettings>().Port = 7500;
		Test.Assert(bed.Dialog.Open(bed.Root));
		let window = bed.Window;
		let tabs = Find<TabView>(window, "pref-tabs");
		Test.Assert(tabs != null);
		Test.Assert(tabs.PageCount == 6); // Appearance, Export, Agent access, Game preview, Shortcuts, Navigation
		let ortho = Find<Sedulous.GUI.CheckBox>(window, "pref-auto-ortho");
		let root = Find<Sedulous.GUI.TextField>(window, "pref-templates-root");
		let enabled = Find<Sedulous.GUI.CheckBox>(window, "pref-mcp-enabled");
		let port = Find<Sedulous.GUI.TextField>(window, "pref-mcp-port");
		Test.Assert((ortho != null) && (root != null) && (enabled != null) && (port != null));
		Test.Assert(ortho.Checked);
		Test.Assert(port.Text == "7500");
		Test.Assert(!enabled.Checked);

		// Six preview sizes seeded; one removed, one added.
		let previews = Find<Node>(window, "pref-previews");
		Test.Assert(previews != null);
		Test.Assert(previews.ChildCount == 6);
		let remove = ButtonText(previews.GetChildAt(0), "Remove");
		Test.Assert(remove != null);
		Test.Assert(remove.HandleActivate());
		Test.Assert(Find<Sedulous.GUI.Button>(window, "pref-preview-add").HandleActivate());
		Test.Assert(previews.ChildCount == 7);

		// The contributed check applies as it changes.
		let snap = CheckTexted(window, "Snap agents to the mesh");
		Test.Assert(snap != null);
		Test.Assert(snap.Checked);
		Test.Assert(snap.HandleActivate());
		Test.Assert(!bed.Snapping);

		Test.Assert(ortho.HandleActivate());
		root.Text = "/opt/templates";
		Test.Assert(enabled.HandleActivate());
		port.Text = "80"; // below the range
		Test.Assert(bed.Dialog.Save());
		Test.Assert(!bed.Store.Find<EditorUiSettings>().AutoOrthographic);
		Test.Assert(bed.Store.Find<EditorExportSettings>().TemplatesRoot == "/opt/templates");
		let mcp = bed.Store.Find<EditorMcpSettings>();
		Test.Assert(mcp.Enabled);
		Test.Assert(mcp.Port == 7500, "kept");
		Test.Assert(bed.Warnings.Count == 1);
		Test.Assert(bed.McpChanged == 1);
		let sizes = bed.Store.Find<GamePreviewSettings>();
		Test.Assert(sizes != null);
		Test.Assert(sizes.Presets.Count == 6, "six, less one, plus the new one");
		Test.Assert(sizes.Presets[0].Name != "HD");
		Test.Assert(sizes.Presets.Back.Name == "Custom");
	}

	/// Off in the store, the check shows off; turned on, Save keeps it on. Cancel keeps nothing.
	[Test]
	public static void TheAxisViewsCheckShowsTheStoresAndSaveStoresItEitherWay()
	{
		let bed = scope Bed();
		bed.Store.Section<EditorUiSettings>().AutoOrthographic = false;
		Test.Assert(bed.Dialog.Open(bed.Root));
		let ortho = Find<Sedulous.GUI.CheckBox>(bed.Window, "pref-auto-ortho");
		Test.Assert(ortho != null);
		Test.Assert(!ortho.Checked);
		Test.Assert(ortho.HandleActivate());
		bed.Dialog.Cancel();
		Test.Assert(!bed.Ui.AutoOrthographic, "cancelled: not stored");

		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(!ortho.Checked, "as the store has it, not as it was left");
		Test.Assert(ortho.HandleActivate());
		Test.Assert(bed.Dialog.Save());
		Test.Assert(bed.Ui.AutoOrthographic);
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(ortho.Checked);
	}

	/// The templates' folder: what the store has; empty, the default shown in its place, and an
	/// emptied field stored empty (the default then taken, not written down).
	[Test]
	public static void AnEmptyTemplatesFieldShowsTheDefaultAndIsStoredEmpty()
	{
		let bed = scope Bed();
		let defaultRoot = Sedulous.Editor.Project.ExportTemplates.DefaultRoot(.. scope .());
		Test.Assert(!defaultRoot.IsEmpty);
		Test.Assert(bed.Dialog.Open(bed.Root));
		let root = Find<Sedulous.GUI.TextField>(bed.Window, "pref-templates-root");
		Test.Assert(root != null);
		Test.Assert(root.Text.IsEmpty, "no section: empty");
		Test.Assert(root.Placeholder == defaultRoot);
		bed.Dialog.Cancel();

		bed.Store.Section<EditorExportSettings>().TemplatesRoot.Set("/srv/templates");
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(root.Text == "/srv/templates");
		Test.Assert(root.Placeholder == defaultRoot);
		root.Text = "";
		Test.Assert(bed.Dialog.Save());
		Test.Assert(bed.Store.Find<EditorExportSettings>().TemplatesRoot.IsEmpty);
	}

	/// The MCP host's fields: what the store has (the default port with no section); a port in
	/// range and the token stored, the host told; a port out of range, or not a number, kept as it
	/// was and said; Cancel tells the host nothing.
	[Test]
	public static void TheMcpFieldsAreStoredAPortOutOfRangeIsKeptAndSaidAndTheHostIsToldOnSave()
	{
		let bed = scope Bed();
		Test.Assert(bed.Dialog.Open(bed.Root));
		let window = bed.Window;
		let enabled = Find<Sedulous.GUI.CheckBox>(window, "pref-mcp-enabled");
		let port = Find<Sedulous.GUI.TextField>(window, "pref-mcp-port");
		let token = Find<Sedulous.GUI.TextField>(window, "pref-mcp-token");
		Test.Assert((enabled != null) && (port != null) && (token != null));
		Test.Assert(!enabled.Checked);
		Test.Assert(port.Text == scope $"{EditorMcpSettings.DefaultPort}");
		Test.Assert(token.Text.IsEmpty);
		Test.Assert(token.Placeholder == "made on first enable");

		// Cancel: nothing stored, the host not told.
		Test.Assert(enabled.HandleActivate());
		bed.Dialog.Cancel();
		Test.Assert(bed.McpChanged == 0);
		Test.Assert(bed.Store.Find<EditorMcpSettings>() == null);

		// In range: stored, nothing said, the host told.
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(!enabled.Checked);
		Test.Assert(enabled.HandleActivate());
		port.Text = "7600";
		token.Text = "sekrit";
		Test.Assert(bed.Dialog.Save());
		let mcp = bed.Store.Find<EditorMcpSettings>();
		Test.Assert(mcp != null);
		Test.Assert(mcp.Enabled && (mcp.Port == 7600) && (mcp.Token == "sekrit"));
		Test.Assert(bed.Warnings.IsEmpty);
		Test.Assert(bed.McpChanged == 1);

		// Shown as stored; above the range: kept, said; turned off, stored, the host told.
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(enabled.Checked && (port.Text == "7600") && (token.Text == "sekrit"));
		Test.Assert(enabled.HandleActivate());
		port.Text = "70000";
		Test.Assert(bed.Dialog.Save());
		Test.Assert(!mcp.Enabled);
		Test.Assert(mcp.Port == 7600, "kept");
		Test.Assert(bed.Warnings.Count == 1);
		Test.Assert(bed.Warnings[0].Contains("MCP port") && bed.Warnings[0].Contains("kept"));
		Test.Assert(bed.McpChanged == 2);

		// Not a number: kept, said. An emptied token is stored empty (made again on the next enable).
		Test.Assert(bed.Dialog.Open(bed.Root));
		port.Text = "port";
		token.Text = "";
		Test.Assert(bed.Dialog.Save());
		Test.Assert(mcp.Port == 7600);
		Test.Assert(mcp.Token.IsEmpty);
		Test.Assert(bed.Warnings.Count == 2);
		Test.Assert(bed.McpChanged == 3);
	}

	/// The preview resolutions: a row per stored size; a removed row hidden and left out on Save,
	/// an added one (Custom, 1920 by 1080) and an edited size kept, a nameless row left out;
	/// Cancel keeps none of it; opened again, the rows as stored, made again rather than added to.
	[Test]
	public static void APreviewSizeIsAddedRemovedAndEditedOnSaveAndForgottenOnCancel()
	{
		let bed = scope Bed();
		let stored = bed.Store.Section<GamePreviewSettings>();
		stored.Seeded = true; // the user's own list, not the seeded one
		stored.Presets.Add(new .("Deck", 1280, 800));
		stored.Presets.Add(new .("Phone", 1080, 2400));
		Test.Assert(bed.Dialog.Open(bed.Root));
		let window = bed.Window;
		let previews = Find<Node>(window, "pref-previews");
		let add = Find<Sedulous.GUI.Button>(window, "pref-preview-add");
		Test.Assert((previews != null) && (add != null));
		Test.Assert(previews.ChildCount == 2);
		// A row: its name, width, "x", height and Remove.
		let deck = previews.GetChildAt(0);
		Test.Assert(deck.ChildCount == 5);
		Test.Assert((deck.GetChildAt(0) as Sedulous.GUI.TextField).Text == "Deck");
		Test.Assert((deck.GetChildAt(1) as Sedulous.GUI.NumberField).Value == 1280.0);
		Test.Assert((deck.GetChildAt(3) as Sedulous.GUI.NumberField).Value == 800.0);

		// Cancel: nothing kept.
		Test.Assert(add.HandleActivate());
		Test.Assert(ButtonText(previews.GetChildAt(0), "Remove").HandleActivate());
		bed.Dialog.Cancel();
		Test.Assert(stored.Presets.Count == 2);
		Test.Assert(stored.Presets[0].Name == "Deck");

		// Opened again: two rows, made again.
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(previews.ChildCount == 2);
		Test.Assert(previews.GetChildAt(0).Displayed);
		// Deck removed, Phone's width edited, one added, one added and its name emptied.
		Test.Assert(ButtonText(previews.GetChildAt(0), "Remove").HandleActivate());
		Test.Assert(!previews.GetChildAt(0).Displayed, "hidden");
		(previews.GetChildAt(1).GetChildAt(1) as Sedulous.GUI.NumberField).Value = 1440.0;
		Test.Assert(add.HandleActivate());
		Test.Assert(add.HandleActivate());
		Test.Assert(previews.ChildCount == 4);
		(previews.GetChildAt(3).GetChildAt(0) as Sedulous.GUI.TextField).Text = "";
		Test.Assert(bed.Dialog.Save());
		Test.Assert(stored.Presets.Count == 2, "Phone and the one added");
		Test.Assert((stored.Presets[0].Name == "Phone") && (stored.Presets[0].Width == 1440) && (stored.Presets[0].Height == 2400));
		Test.Assert((stored.Presets[1].Name == "Custom") && (stored.Presets[1].Width == 1920) && (stored.Presets[1].Height == 1080));

		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(previews.ChildCount == 2);
		Test.Assert((previews.GetChildAt(0).GetChildAt(0) as Sedulous.GUI.TextField).Text == "Phone");
	}

	/// A tab per contributed category, after the editor's own, contributions naming one category
	/// sharing it; each check shows its field's value at each open and writes it as it changes,
	/// before Save and kept on Cancel, as before.
	[Test]
	public static void ContributionsNamingOneCategoryShareItsTabAndTheirChecksApplyAsTheyChange()
	{
		let bed = scope Bed("#6d5bd8", "compact", true);
		Test.Assert(bed.Dialog.Open(bed.Root));
		let tabs = Find<TabView>(bed.Window, "pref-tabs");
		Test.Assert(tabs != null);
		Test.Assert(tabs.PageCount == 7);
		Test.Assert(PageTitled(tabs, "Appearance") == 0);
		Test.Assert(PageTitled(tabs, "Export") == 1);
		Test.Assert(PageTitled(tabs, "Agent access") == 2);
		Test.Assert(PageTitled(tabs, "Game preview") == 3);
		Test.Assert(PageTitled(tabs, "Shortcuts") == 4);
		Test.Assert(PageTitled(tabs, "Navigation") == 5);
		Test.Assert(PageTitled(tabs, "Audio") == 6);

		// Both Navigation fields on its tab, in their order; Audio's on its own.
		let navigation = scope List<Sedulous.GUI.CheckBox>();
		Checks(tabs.GetPage(5), navigation);
		Test.Assert(navigation.Count == 2);
		Test.Assert(navigation[0].Text == "Snap agents to the mesh");
		Test.Assert(navigation[1].Text == "Show the bake bounds");
		let audio = scope List<Sedulous.GUI.CheckBox>();
		Checks(tabs.GetPage(6), audio);
		Test.Assert((audio.Count == 1) && (audio[0].Text == "Mute in the background"));

		// As the fields have them.
		Test.Assert(navigation[0].Checked && !navigation[1].Checked && !audio[0].Checked);

		// Applied as it changes, and kept on Cancel.
		Test.Assert(navigation[1].HandleActivate());
		Test.Assert(bed.BakeBounds);
		Test.Assert(audio[0].HandleActivate());
		Test.Assert(bed.Muted);
		Test.Assert(bed.Snapping, "the others untouched");
		bed.Dialog.Cancel();
		Test.Assert(bed.BakeBounds && bed.Muted);

		// Changed elsewhere: opened again, shown as the field has it; the tabs made once.
		bed.Muted = false;
		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(tabs.PageCount == 7);
		Test.Assert(!audio[0].Checked);
		Test.Assert(navigation[1].Checked);
	}
}
