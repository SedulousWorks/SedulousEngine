using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.GUI; // Effect (what changes), Menu (action items)
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// The action registry on a real EditorContext: declarations bound through the subject page
/// and the interface it publishes, the pulled enabled and checked states, Execute as the one
/// funnel with its refusals, the shortcut table (defaults, overrides, collisions, reset) and
/// the change notice an Effect follows; the refusals of a bad or duplicate registration; a
/// menu's items from the declarations; a chord as the surfaces spell it; an override kept by
/// the editor before chords were text.
static class EditorActionsTests
{
	/// A page kind an action can address: it publishes ISimulating (start and stop a run).
	interface ISimulating
	{
		void Start();
		void Stop();
		bool Running { get; }
	}

	private class SimPage : EditorPage, ISimulating
	{
		public int Saves = 0;
		public bool IsRunning = false;
		public override StringView Title => "sim";
		public override Result<void, ErrorCode> Save()
		{
			Saves++;
			ClearDirty();
			return .Ok;
		}
		public void Start() { IsRunning = true; }
		public void Stop() { IsRunning = false; }
		public bool Running => IsRunning;
	}

	private class PlainPage : EditorPage
	{
		public int Saves = 0;
		public override StringView Title => "plain";
		public override Result<void, ErrorCode> Save()
		{
			Saves++;
			ClearDirty();
			return .Ok;
		}
	}

	private static EditorShortcut CtrlS => .Of("ctrl-s");
	private static EditorShortcut F5 => .Of("f5");

	/// A menu's items, in order (the rows AppendActionItems added).
	private static void ItemsOf(Node node, List<MenuItem> outItems)
	{
		if (let item = node as MenuItem)
			outItems.Add(item);
		for (int i < node.ChildCount)
			ItemsOf(node.GetChildAt(i), outItems);
	}

	/// An override as the editor kept it before chords were text: ShortcutOverrideEntry's
	/// version 1 layout (Sedulous.UI's key code and modifier bits) under its identity.
	private class LegacyOverrideEntry : ISerializable
	{
		public String Id = new .() ~ delete _;
		public uint32 Key = 0;
		public uint32 Modifiers = 0;

		public this() {}

		public this(StringView id, uint32 key, uint32 modifiers)
		{
			Id.Set(id);
			Key = key;
			Modifiers = modifiers;
		}

		public void Serialize(ISerializer ar)
		{
			BeginVersionedPayload(ar, ShortcutOverrideEntry.TypeId, 1);
			ar.BeginObject();
			Sedulous.Core.Serialization.Serialize(ar, "id", Id);
			SerializeValue(ar, "key", ref Key);
			SerializeValue(ar, "modifiers", ref Modifiers);
			ar.EndObject();
			EndVersionedPayload(ar);
		}
	}

	/// The shortcut section holding those, as its generated body writes it.
	private class LegacyShortcutSection : ISerializable
	{
		public List<LegacyOverrideEntry> Overrides = new .() ~ DeleteContainerAndItems!(_);

		public void Serialize(ISerializer ar)
		{
			BeginVersionedPayload(ar, EditorShortcutSettings.TypeId, EditorShortcutSettings.DataVersion);
			ar.BeginObject();
			ar.Key("overrides");
			SerializeList(ar, Overrides);
			ar.EndObject();
			EndVersionedPayload(ar);
		}
	}

	private static EditorActionDeclaration Declare(StringView id, StringView label)
	{
		let d = new EditorActionDeclaration(id, label);
		d.Execute = new (page) => {};
		return d;
	}

	/// A plugin's action leaves the registry as its plugin unloads: the others keep their places and
	/// their lookups, and a shortcut the user bound to it holds again when it comes back.
	[Test]
	public static void AnUnregisteredActionIsGoneTheRestStillFoundItsUserShortcutKept()
	{
		let context = scope EditorContext();
		let actions = context.Actions;
		Test.Assert(actions.Register(Declare("a.one", "Label")));
		Test.Assert(actions.Register(Declare("b.two", "Label")));
		Test.Assert(actions.Register(Declare("c.three", "Label")));
		Test.Assert(actions.Rebind("b.two", EditorShortcut.Of("ctrl-k")) case .Ok);
		Test.Assert(actions.Unregister("b.two"));
		Test.Assert(!actions.Unregister("b.two"), "gone already");
		Test.Assert(actions.Count == 2);
		Test.Assert(actions.Find("b.two") == null);
		Test.Assert((actions.Find("c.three") != null) && (actions.Find("c.three").Id == "c.three"));
		Test.Assert((actions.Actions[0].Id == "a.one") && (actions.Actions[1].Id == "c.three"));
		Test.Assert(actions.Register(Declare("b.two", "Back")));
		Test.Assert(actions.Shortcut("b.two") == EditorShortcut.Of("ctrl-k"));
	}

	[Test]
	public static void DeclarationsBindThroughTheSubjectPageAndExecuteIsTheFunnel()
	{
		let context = scope EditorContext();
		let actions = context.Actions;
		int changes = 0;
		let watch = scope Effect(new [&]() => { actions.TrackChanges(); changes++; }); // a surface following the actions
		Test.Assert(watch.RunCount == 1);
		changes = 0; // its first run reads them; the changes are what follow

		// Editor-wide, always enabled.
		int exits = 0;
		let exit = new EditorActionDeclaration("file.exit", "Exit", "", "File/Exit");
		exit.Execute = new [&exits](page) => { exits++; };
		Test.Assert(actions.Register(exit));

		// Over the subject page: enabled while it is dirty, executes its Save.
		let save = new EditorActionDeclaration("page.save", "Save");
		save.Shortcut = CtrlS;
		save.Enabled = new (page) => (page != null) && page.IsDirty;
		save.Execute = new (page) => { page.Save().IgnoreError(); };
		Test.Assert(actions.Register(save));

		// Over the interface the subject publishes: a Toggle whose checked state is the run.
		let simulate = new EditorActionDeclaration("sim.run", "Simulate");
		simulate.Kind = .Toggle;
		simulate.Shortcut = F5;
		simulate.Enabled = new (page) => (page as ISimulating) != null;
		simulate.Checked = new (page) =>
			{
				let sim = page as ISimulating;
				return (sim != null) && sim.Running;
			};
		simulate.Execute = new (page) =>
			{
				let sim = page as ISimulating;
				if (sim.Running)
					sim.Stop();
				else
					sim.Start();
			};
		Test.Assert(actions.Register(simulate));
		Test.Assert(changes == 3);
		Test.Assert(actions.Count == 3);
		Test.Assert(actions.Actions[0].Id == "file.exit", "registration order");
		Test.Assert(actions.Actions[2].Id == "sim.run");
		Test.Assert(actions.Find("page.save").Label == "Save");
		Test.Assert(actions.Find("nobody.home") == null);

		// No page: the editor-wide action runs, the page-bound ones are disabled and refused.
		Test.Assert(actions.IsEnabled("file.exit"));
		Test.Assert(!actions.IsEnabled("page.save"));
		Test.Assert(!actions.IsEnabled("sim.run"));
		Test.Assert(!actions.IsEnabled("nobody.home"));
		Test.Assert(actions.Execute("file.exit") case .Ok);
		Test.Assert(exits == 1);
		Test.Assert(actions.Execute("page.save") case .Err(.NotSupported));
		Test.Assert(actions.Execute("nobody.home") case .Err(.NotFound));

		// A plain page, dirty: save is enabled and saves IT; simulate stays disabled.
		let plain = (PlainPage)context.AdoptPage(new PlainPage());
		Test.Assert(!actions.IsEnabled("page.save"), "clean");
		plain.MarkDirty();
		Test.Assert(actions.IsEnabled("page.save"));
		Test.Assert(!actions.IsEnabled("sim.run"));
		Test.Assert(actions.Execute("page.save") case .Ok);
		Test.Assert(plain.Saves == 1);
		Test.Assert(!actions.IsEnabled("page.save"), "clean again, pulled");
		Test.Assert(actions.Execute("sim.run") case .Err(.NotSupported));

		// A sim page active: the toggle is enabled, its checked state follows the run.
		let sim = (SimPage)context.AdoptPage(new SimPage());
		Test.Assert(context.ActivePage == sim);
		Test.Assert(actions.IsEnabled("sim.run"));
		Test.Assert(!actions.IsChecked("sim.run"));
		Test.Assert(actions.Execute("sim.run") case .Ok);
		Test.Assert(sim.IsRunning);
		Test.Assert(actions.IsChecked("sim.run"));
		Test.Assert(actions.Execute("sim.run") case .Ok);
		Test.Assert(!sim.IsRunning);
		Test.Assert(!actions.IsChecked("file.exit"), "a Command is never checked");

		// Back on the plain page the toggle is out of reach through the active subject; a
		// surface that names the sim page still reaches it (a page's own toolbar in a split
		// layout), and a named subject answers about ITSELF.
		context.SetActivePage(plain);
		Test.Assert(!actions.IsEnabled("sim.run"));
		Test.Assert(actions.IsEnabled("sim.run", sim));
		Test.Assert(actions.Execute("sim.run", sim) case .Ok);
		Test.Assert(sim.IsRunning);
		Test.Assert(actions.IsChecked("sim.run", sim));
		Test.Assert(!actions.IsChecked("sim.run"), "the active subject is the plain page");
		Test.Assert(actions.Execute("page.save", plain) case .Err(.NotSupported), "clean");
		plain.MarkDirty();
		context.SetActivePage(sim);
		Test.Assert(!actions.IsEnabled("page.save"), "the active sim page is clean");
		Test.Assert(actions.IsEnabled("page.save", plain), "the named plain page is dirty");
		Test.Assert(actions.Execute("page.save", plain) case .Ok);
		Test.Assert(plain.Saves == 2);

		// A bare registry has no subject: page-bound actions see null.
		let bare = scope EditorActionRegistry();
		let needsPage = Declare("needs.page", "Needs a page");
		needsPage.Enabled = new (page) => page != null;
		Test.Assert(bare.Register(needsPage));
		Test.Assert(bare.Subject == null);
		Test.Assert(!bare.IsEnabled("needs.page"));
		Test.Assert(bare.IsEnabled("needs.page", plain));
	}

	[Test]
	public static void TheShortcutTableDefaultsOverridesCollisionsAndReset()
	{
		let context = scope EditorContext();
		let actions = context.Actions;
		let save = Declare("page.save", "Save");
		save.Shortcut = CtrlS;
		Test.Assert(actions.Register(save));
		let run = Declare("sim.run", "Simulate");
		run.Shortcut = F5;
		run.AlternateShortcut = .Of("f6");
		Test.Assert(actions.Register(run));
		Test.Assert(actions.Register(Declare("view.reset", "Reset Layout")), "no chord");
		int changes = 0;
		let watch = scope Effect(new [&]() => { actions.TrackChanges(); changes++; }); // a surface following the actions
		Test.Assert(watch.RunCount == 1);
		changes = 0; // its first run reads them; the changes are what follow

		Test.Assert(actions.Shortcut("page.save") == CtrlS);
		Test.Assert(!actions.Shortcut("view.reset").IsSet);
		Test.Assert(!actions.Shortcut("nobody.home").IsSet);
		Test.Assert(actions.HolderOf(CtrlS) == actions.Find("page.save"));
		Test.Assert(actions.HolderOf(.()) == null, "the unset chord is nobody's");
		Test.Assert(actions.HolderOf(.Of("f6")) == actions.Find("sim.run"), "an alternate is taken");
		Test.Assert(actions.AlternateShortcut("sim.run") == EditorShortcut.Of("f6"));
		Test.Assert(!actions.HasOverride("page.save"));

		// A free chord binds; the declaration's default no longer applies.
		let ctrlShiftS = EditorShortcut.Of("ctrl-shift-s");
		Test.Assert(actions.Rebind("page.save", ctrlShiftS) case .Ok);
		Test.Assert(changes == 1);
		Test.Assert(actions.Shortcut("page.save") == ctrlShiftS);
		Test.Assert(actions.HasOverride("page.save"));
		Test.Assert(actions.HolderOf(CtrlS) == null);
		Test.Assert(actions.HolderOf(ctrlShiftS) == actions.Find("page.save"));

		// Another action's chord is refused, naming the holder; nothing changes.
		EditorActionDeclaration holder;
		Test.Assert(actions.Rebind("view.reset", F5, out holder) case .Err(.AlreadyExists));
		Test.Assert((holder != null) && (holder.Id == "sim.run"));
		Test.Assert(changes == 1);
		Test.Assert(!actions.Shortcut("view.reset").IsSet);
		Test.Assert(actions.Rebind("view.reset", .Of("f6")) case .Err(.AlreadyExists), "an alternate cannot be taken");
		// An action may keep its own chord through Rebind (the settings page re-applies).
		Test.Assert(actions.Rebind("sim.run", F5) case .Ok);
		Test.Assert(actions.Shortcut("sim.run") == F5);
		// The chord an override freed is available to another action.
		Test.Assert(actions.Rebind("view.reset", CtrlS) case .Ok);
		Test.Assert(actions.HolderOf(CtrlS) == actions.Find("view.reset"));

		// Clearing is an override that is unset: "no shortcut", on purpose, distinct from the
		// default.
		Test.Assert(actions.Rebind("sim.run", .()) case .Ok);
		Test.Assert(!actions.Shortcut("sim.run").IsSet);
		Test.Assert(actions.HasOverride("sim.run"));
		Test.Assert(actions.HolderOf(F5) == null);
		// Resetting forgets the override: the default is back.
		actions.ResetShortcut("sim.run");
		Test.Assert(actions.Shortcut("sim.run") == F5);
		Test.Assert(!actions.HasOverride("sim.run"));
		let before = changes;
		actions.ResetShortcut("sim.run");
		Test.Assert(changes == before, "nothing to forget: no change");
		Test.Assert(actions.Rebind("nobody.home", F5) case .Err(.NotFound));
	}

	[Test]
	public static void ABadOrDuplicateRegistrationIsRefusedAndTheFirstStands()
	{
		let actions = scope EditorActionRegistry();
		Test.Assert(!actions.Register(Declare("", "Nameless")));
		Test.Assert(!actions.Register(Declare("x.y", "")));
		Test.Assert(!actions.Register(new EditorActionDeclaration("x.y", "No body")), "Execute unset");
		Test.Assert(actions.Count == 0);

		int first = 0;
		int second = 0;
		let a = new EditorActionDeclaration("x.y", "First");
		a.Execute = new [&first](page) => { first++; };
		let b = new EditorActionDeclaration("x.y", "Second");
		b.Execute = new [&second](page) => { second++; };
		Test.Assert(actions.Register(a));
		Test.Assert(!actions.Register(b));
		Test.Assert(actions.Count == 1);
		Test.Assert(actions.Find("x.y").Label == "First");
		Test.Assert(actions.Execute("x.y") case .Ok);
		Test.Assert((first == 1) && (second == 0));
	}

	[Test]
	public static void AMenusItemsComeFromTheDeclarationsOverASubjectWithTheirChords()
	{
		let actions = scope EditorActionRegistry();
		int runs = 0;
		let run = new EditorActionDeclaration("sim.run", "Simulate");
		run.Shortcut = F5;
		run.Enabled = new (page) => page != null;
		run.Execute = new [&runs](page) => { runs++; };
		Test.Assert(actions.Register(run));
		Test.Assert(actions.Register(Declare("file.exit", "Exit")));

		let page = scope SimPage();
		let menu = new Menu();
		defer menu.ReleaseRef();
		Test.Assert(actions.AppendActionItems(menu, page, "sim.run", "nobody.home", "file.exit") == 2);
		let items = scope List<MenuItem>();
		ItemsOf(menu, items);
		Test.Assert(items.Count == 2);
		Test.Assert(items[0].Text == "Simulate");
		Test.Assert(items[0].Shortcut == "F5", "its chord, as the menu shows it");
		Test.Assert(items[0].Enabled);
		Test.Assert(items[1].Text == "Exit");
		Test.Assert(items[1].Shortcut.IsEmpty, "no chord, no shortcut column");
		items[0].HandleActivate();
		Test.Assert(runs == 1);
		// Over no subject the page-bound item is disabled; its click is refused by the registry.
		let bare = new Menu();
		defer bare.ReleaseRef();
		Test.Assert(actions.AppendActionItems(bare, null, "sim.run") == 1);
		let bareItems = scope List<MenuItem>();
		ItemsOf(bare, bareItems);
		Test.Assert(bareItems.Count == 1);
		Test.Assert(!bareItems[0].Enabled);
		bareItems[0].HandleActivate();
		Test.Assert(runs == 1);
	}

	[Test]
	public static void AChordIsSpelledAsAShortcutColumnShowsIt()
	{
		Test.Assert(EditorShortcut().ToString(.. scope .()).IsEmpty);
		Test.Assert(CtrlS.ToString(.. scope .()) == "Ctrl+S");
		Test.Assert(F5.ToString(.. scope .()) == "F5");
		Test.Assert(EditorShortcut.Of("ctrl-shift-z").ToString(.. scope .()) == "Ctrl+Shift+Z");
		Test.Assert(EditorShortcut.Of("alt-pageup").ToString(.. scope .()) == "Alt+PgUp");
		Test.Assert(EditorShortcut.Of("delete").ToString(.. scope .()) == "Del");
		// As a binding writes it, which Of reads back; a name the keymap does not know is unset.
		Test.Assert(EditorShortcut.Of("ctrl-shift-z").Keys(.. scope .()) == "ctrl-shift-z");
		Test.Assert(EditorShortcut().Keys(.. scope .()).IsEmpty);
		Test.Assert(!EditorShortcut.Of("ctrl-nokey").IsSet);
		Test.Assert(EditorShortcut.Of("shift-ctrl-s") == EditorShortcut.Of("ctrl-shift-s"), "a binding may name its modifiers in any order");
	}

	[Test]
	public static void ShortcutOverridesPersistThroughTheSectionWithUnknownIdsKeptAndCollisionsSkipped()
	{
		EditorSerializables.RegisterAll();
		let context = scope EditorContext();
		let actions = context.Actions;
		let save = Declare("page.save", "Save");
		save.Shortcut = CtrlS;
		Test.Assert(actions.Register(save));
		let run = Declare("sim.run", "Simulate");
		run.Shortcut = F5;
		Test.Assert(actions.Register(run));
		Test.Assert(actions.Register(Declare("view.reset", "Reset Layout")));
		let ctrlShiftS = EditorShortcut.Of("ctrl-shift-s");
		Test.Assert(actions.Rebind("page.save", ctrlShiftS) case .Ok);
		Test.Assert(actions.Rebind("sim.run", .()) case .Ok); // cleared on purpose

		// Capture: only the overridden ones; an entry for an id this build never registered stays.
		let store = scope Settings();
		let section = store.Section<EditorShortcutSettings>();
		let foreign = new ShortcutOverrideEntry();
		foreign.Id.Set("terrain.sculpt"); // a domain not loaded here
		foreign.Keys.Set("t");
		section.Overrides.Add(foreign);
		Test.Assert(section.Capture(actions) == 3);
		Test.Assert(section.Find("page.save").Chord == ctrlShiftS);
		Test.Assert(!section.Find("sim.run").Chord.IsSet);
		Test.Assert(section.Find("view.reset") == null);
		Test.Assert(section.Find("terrain.sculpt") != null);
		// A reset override leaves the section on the next capture.
		actions.ResetShortcut("sim.run");
		Test.Assert(section.Capture(actions) == 2);
		Test.Assert(section.Find("sim.run") == null);

		// Through the store and back.
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		let back = loaded.Find<EditorShortcutSettings>();
		Test.Assert(back != null);
		Test.Assert(back.Overrides.Count == 2);
		Test.Assert(back.Find("page.save").Chord == ctrlShiftS);
		Test.Assert(back.Find("terrain.sculpt").Chord == EditorShortcut.Of("t"));
		Test.Assert(back.Find("page.save").Keys == "ctrl-shift-s", "kept as a binding writes it");

		// Apply to a fresh registry: the known override binds, the unknown id is skipped, and a
		// chord another action holds is refused and skipped (the holder keeps it).
		let other = scope EditorContext();
		let fresh = other.Actions;
		let freshSave = Declare("page.save", "Save");
		freshSave.Shortcut = CtrlS;
		Test.Assert(fresh.Register(freshSave));
		let taken = Declare("edit.other", "Other");
		taken.Shortcut = ctrlShiftS;
		Test.Assert(fresh.Register(taken));
		Test.Assert(back.ApplyTo(fresh) == 0);
		Test.Assert(fresh.Shortcut("page.save") == CtrlS);
		Test.Assert(!fresh.HasOverride("page.save"));
		// Free the chord: the override applies on the next apply; the unknown id still counts nothing.
		Test.Assert(fresh.Rebind("edit.other", .()) case .Ok);
		Test.Assert(back.ApplyTo(fresh) == 1);
		Test.Assert(fresh.Shortcut("page.save") == ctrlShiftS);
		Test.Assert(fresh.Find("terrain.sculpt") == null);
	}

	[Test]
	public static void StagedShortcutEditsApplyTogetherWithSwapsResetsAndNamedCollisions()
	{
		let context = scope EditorContext();
		let actions = context.Actions;
		let ctrlZ = EditorShortcut.Of("ctrl-z");
		let ctrlY = EditorShortcut.Of("ctrl-y");
		for (let (id, chord) in scope (StringView, EditorShortcut)[](("page.save", CtrlS), ("edit.undo", ctrlZ),
			("edit.redo", ctrlY), ("sim.run", F5), ("view.reset", .())))
		{
			let d = Declare(id, id);
			d.Shortcut = chord;
			Test.Assert(actions.Register(d));
		}
		let section = scope EditorShortcutSettings();

		let edits = scope ShortcutEdits();
		Test.Assert(edits.IsEmpty);
		// A chord for a bare action; a swap of undo and redo; a reset of one with an override.
		Test.Assert(actions.Rebind("sim.run", .Of("f7")) case .Ok);
		edits.Set("view.reset", .Of("f6"));
		edits.Set("edit.undo", ctrlY);
		edits.Set("edit.redo", ctrlZ);
		edits.Reset("sim.run");
		edits.Set("view.reset", .Of("f6")); // re-staged: still one entry
		Test.Assert(edits.Count == 4);
		Test.Assert(edits.Pending("sim.run").Reset);
		edits.Set("page.save", CtrlS);
		edits.Discard("page.save");
		// sim.run's DEFAULT comes back through the reset, so F5 collides with it.
		edits.Set("page.save", F5);
		Test.Assert(edits.Count == 5);

		let collisions = scope List<String>();
		defer { ClearAndDeleteItems!(collisions); }
		let applied = edits.Apply(actions, section, collisions);
		Test.Assert(edits.IsEmpty);
		Test.Assert(actions.Shortcut("view.reset") == EditorShortcut.Of("f6"));
		Test.Assert(actions.Shortcut("edit.undo") == ctrlY);
		Test.Assert(actions.Shortcut("edit.redo") == ctrlZ);
		Test.Assert(actions.Shortcut("sim.run") == F5);
		Test.Assert(!actions.HasOverride("sim.run"));
		// The collision: page.save wanted F5, sim.run's default holds it; page.save is back to its own.
		Test.Assert(actions.Shortcut("page.save") == CtrlS);
		Test.Assert(!actions.HasOverride("page.save"));
		Test.Assert(collisions.Count == 1);
		Test.Assert(collisions[0].StartsWith("F5: 'sim.run' holds it"));
		Test.Assert(applied == 4);
		// The section holds the overrides that stand: three.
		Test.Assert(section.Overrides.Count == 3);
		Test.Assert(section.Find("edit.undo").Chord == ctrlY);
		Test.Assert(section.Find("page.save") == null);
		Test.Assert(section.Find("sim.run") == null);
		// An id nobody registered is dropped quietly.
		edits.Set("nobody.home", F5);
		Test.Assert(edits.Apply(actions, section, collisions) == 0);
		Test.Assert(collisions.Count == 1);
	}

	[Test]
	public static void AnOverrideKeptAsAKeyCodeBeforeChordsWereTextReadsAsItsKeys()
	{
		// Sedulous.UI's codes were SDL's scancodes (the USB HID usages) with SDL's modifier bits:
		// T is 23, F5 62, Delete 76, Z 29, Page Up 75; LeftCtrl 0x0040, LeftShift 0x0001,
		// RightShift 0x0002, LeftAlt 0x0100.
		Test.Assert(ShortcutOverrideEntry.LegacyChordKeys(23, 0x0040, .. scope .()) == "ctrl-t");
		Test.Assert(ShortcutOverrideEntry.LegacyChordKeys(62, 0, .. scope .()) == "f5");
		Test.Assert(ShortcutOverrideEntry.LegacyChordKeys(76, 0x0001, .. scope .()) == "shift-delete");
		Test.Assert(ShortcutOverrideEntry.LegacyChordKeys(29, 0x0042, .. scope .()) == "ctrl-shift-z");
		Test.Assert(ShortcutOverrideEntry.LegacyChordKeys(75, 0x0101, .. scope .()) == "shift-alt-pageup", "in the order a binding writes them");
		Test.Assert(ShortcutOverrideEntry.LegacyChordKeys(39, 0, .. scope .()) == "0", "SDL runs the digits 1 to 9, then 0");
		Test.Assert(ShortcutOverrideEntry.LegacyChordKeys(104, 0, .. scope .()) == "f13");
		Test.Assert(ShortcutOverrideEntry.LegacyChordKeys(93, 0, .. scope .()) == "numpad5");
		Test.Assert(ShortcutOverrideEntry.LegacyChordKeys(0, 0, .. scope .()).IsEmpty);
		Test.Assert(ShortcutOverrideEntry.LegacyChordKeys(224, 0x0040, .. scope .()).IsEmpty, "a modifier key alone is no chord");
		Test.Assert(EditorShortcut.Of(ShortcutOverrideEntry.LegacyChordKeys(29, 0x0042, .. scope .())) == EditorShortcut.Of("ctrl-shift-z"));

		// A settings file the editor saved then: the store reads it, each override as its keys,
		// "no shortcut" (key 0) still none; saved again, it is text.
		EditorSerializables.RegisterAll();
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		{
			let legacy = scope LegacyShortcutSection();
			legacy.Overrides.Add(new LegacyOverrideEntry("page.save", 22, 0x0041)); // Ctrl+Shift+S
			legacy.Overrides.Add(new LegacyOverrideEntry("sim.run", 0, 0)); // cleared on purpose
			legacy.Overrides.Add(new LegacyOverrideEntry("terrain.sculpt", 23, 0)); // T
			let writing = factory(buffer, .Write);
			defer delete writing;
			let archive = writing.Serializer;
			Test.Assert(archive.IsSelfDescribing, "a self describing file has no format version to write");
			uint32 count = 1;
			archive.Key("sections");
			archive.BeginArray(ref count);
			archive.BeginObject();
			archive.Key("typeName");
			archive.Text(typeof(EditorShortcutSettings).GetFullName(.. scope .()));
			archive.BeginFramedRegion();
			archive.Key("payload");
			archive.BeginObject();
			legacy.Serialize(archive);
			archive.EndObject();
			archive.EndFramedRegion();
			archive.EndObject();
			archive.EndArray();
			Test.Assert(archive.IsOk);
			writing.Flush(buffer);
		}
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		let section = loaded.Find<EditorShortcutSettings>();
		Test.Assert((section != null) && (section.Overrides.Count == 3));
		Test.Assert(section.Find("page.save").Keys == "ctrl-shift-s");
		Test.Assert(section.Find("page.save").Chord == EditorShortcut.Of("ctrl-shift-s"));
		Test.Assert(section.Find("sim.run").Keys.IsEmpty && !section.Find("sim.run").Chord.IsSet);
		Test.Assert(section.Find("terrain.sculpt").Keys == "t");

		// It applies as any override does.
		let context = scope EditorContext();
		let save = Declare("page.save", "Save");
		save.Shortcut = CtrlS;
		Test.Assert(context.Actions.Register(save));
		Test.Assert(section.ApplyTo(context.Actions) == 1);
		Test.Assert(context.Actions.Shortcut("page.save") == EditorShortcut.Of("ctrl-shift-s"));

		// Saved again it is version 2, the chord as text, and reads back the same.
		let again = scope Sedulous.Core.IO.MemoryStream();
		Test.Assert(loaded.Save(again, factory) case .Ok);
		let text = scope String((char8*)again.Bytes.Ptr, again.Bytes.Length);
		Test.Assert(text.Contains("ctrl-shift-s"));
		again.Seek(0, .Begin);
		let reloaded = scope Settings();
		Test.Assert(reloaded.Load(again, factory) case .Ok);
		let back = reloaded.Find<EditorShortcutSettings>();
		Test.Assert((back != null) && (back.Overrides.Count == 3));
		Test.Assert(back.Find("page.save").Keys == "ctrl-shift-s");
		Test.Assert(back.Find("terrain.sculpt").Chord == EditorShortcut.Of("t"));
	}
}
