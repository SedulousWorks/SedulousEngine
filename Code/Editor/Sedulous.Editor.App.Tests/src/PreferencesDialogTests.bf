using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// Preferences over its own markup (Data/Editor/Preferences.gml): its controls as the user's store
/// has the look (what the store names wrongly, the defaults); each change of each input shown at
/// once; Save into the store, marked changed and persisted; Cancel, Escape, its close button, or
/// the dialog going while open, putting the look back as it was with the store unchanged.
static class PreferencesDialogTests
{
	/// A GUI scene for the dialog to open over, the user's store (violet), the looks it showed and
	/// the persists it asked for.
	private class Bed
	{
		public SceneRoot Root;
		public Settings Store = new .() ~ delete _;
		public List<EditorLook> Shown = new .() ~ DeleteContainerAndItems!(_);
		public int Persisted = 0;
		/// What a persist answers.
		public bool PersistHolds = true;
		public EditorPreferencesDialog Dialog = null ~ delete _;

		public this(StringView accent = "#6d5bd8", StringView density = "compact")
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(1000.0f, 700.0f);
			Store.Section<EditorUiSettings>().Accent.Set(accent);
			Store.Section<EditorUiSettings>().Density.Set(density);
			let services = new EditorPreferencesServices();
			services.User = Store;
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

		public Sedulous.GUI.EventDispatcher Dispatcher => Root.EventDispatcher;
		public Sedulous.GUI.Window Window => Dialog.Window;
		public EditorLook Last => Shown.Back;
		public EditorUiSettings Ui => Store.Find<EditorUiSettings>();

		public bool Press(KeyCode key) => Root.EventDispatcher.InjectKeyDown((uint32)key, 0);
	}

	/// The dialog's body, read from the repository's Data with the GUI's elements; its one
	/// reference is the caller's.
	private static Node LoadPreferences()
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

		// Save: into the store, marked changed, persisted, closed; nothing put back.
		int changes = 0;
		bed.Store.OnChanged.Add(new [&] (name) => { changes++; });
		let shownAtSave = bed.Shown.Count;
		Test.Assert(bed.Dialog.Save());
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(bed.Persisted == 1);
		Test.Assert(changes == 1);
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
}
