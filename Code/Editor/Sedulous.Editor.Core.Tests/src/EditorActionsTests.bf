using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// The action registry on a real EditorContext: declarations bound through the subject page
/// and the interface it publishes, the pulled enabled and checked states, Execute as the one
/// funnel with its refusals, the shortcut table (defaults, overrides, collisions, reset) and
/// the change notification; the refusals of a bad or duplicate registration; a context menu's
/// items from the declarations; a chord as the surfaces spell it.
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

	private static EditorShortcut CtrlS => .(.S, .Ctrl);
	private static EditorShortcut F5 => .(.F5);

	private static EditorActionDeclaration Declare(StringView id, StringView label)
	{
		let d = new EditorActionDeclaration(id, label);
		d.Execute = new (page) => {};
		return d;
	}

	[Test]
	public static void DeclarationsBindThroughTheSubjectPageAndExecuteIsTheFunnel()
	{
		let context = scope EditorContext();
		let actions = context.Actions;
		int changes = 0;
		delegate void() onChanged = new [&changes]() => { changes++; };
		actions.OnActionsChanged.Add(onChanged);
		defer actions.OnActionsChanged.Remove(onChanged, true);

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
		run.AlternateShortcut = .(.F6);
		Test.Assert(actions.Register(run));
		Test.Assert(actions.Register(Declare("view.reset", "Reset Layout")), "no chord");
		int changes = 0;
		delegate void() onChanged = new [&changes]() => { changes++; };
		actions.OnActionsChanged.Add(onChanged);
		defer actions.OnActionsChanged.Remove(onChanged, true);

		Test.Assert(actions.Shortcut("page.save") == CtrlS);
		Test.Assert(!actions.Shortcut("view.reset").IsSet);
		Test.Assert(!actions.Shortcut("nobody.home").IsSet);
		Test.Assert(actions.HolderOf(CtrlS) == actions.Find("page.save"));
		Test.Assert(actions.HolderOf(.()) == null, "the unset chord is nobody's");
		Test.Assert(actions.HolderOf(.(.F6)) == actions.Find("sim.run"), "an alternate is taken");
		Test.Assert(actions.AlternateShortcut("sim.run") == EditorShortcut(.F6));
		Test.Assert(!actions.HasOverride("page.save"));

		// A free chord binds; the declaration's default no longer applies.
		let ctrlShiftS = EditorShortcut(.S, .Ctrl | .Shift);
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
		Test.Assert(actions.Rebind("view.reset", .(.F6)) case .Err(.AlreadyExists), "an alternate cannot be taken");
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
	public static void AContextMenusItemsComeFromTheDeclarationsOverASubject()
	{
		let actions = scope EditorActionRegistry();
		int runs = 0;
		let run = new EditorActionDeclaration("sim.run", "Simulate");
		run.Enabled = new (page) => page != null;
		run.Execute = new [&runs](page) => { runs++; };
		Test.Assert(actions.Register(run));
		Test.Assert(actions.Register(Declare("file.exit", "Exit")));

		let page = scope SimPage();
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		Test.Assert(actions.AppendActionItems(menu, page, "sim.run", "nobody.home", "file.exit") == 2);
		Test.Assert(menu.ItemCount == 2);
		Test.Assert(menu.ItemAt(0).Label == "Simulate");
		Test.Assert(menu.ItemAt(0).Enabled);
		Test.Assert(menu.ItemAt(1).Label == "Exit");
		menu.ItemAt(0).Action();
		Test.Assert(runs == 1);
		// Over no subject the page-bound item is disabled; its click is refused by the registry.
		let bare = new ContextMenu();
		defer bare.ReleaseRef();
		Test.Assert(actions.AppendActionItems(bare, null, "sim.run") == 1);
		Test.Assert(!bare.ItemAt(0).Enabled);
		bare.ItemAt(0).Action();
		Test.Assert(runs == 1);
	}

	[Test]
	public static void AChordIsSpelledAsAShortcutColumnShowsIt()
	{
		Test.Assert(EditorShortcut().ToString(.. scope .()).IsEmpty);
		Test.Assert(CtrlS.ToString(.. scope .()) == "Ctrl+S");
		Test.Assert(F5.ToString(.. scope .()) == "F5");
		Test.Assert(EditorShortcut(.Z, .Ctrl | .Shift).ToString(.. scope .()) == "Ctrl+Shift+Z");
		Test.Assert(EditorShortcut(.PageUp, .Alt).ToString(.. scope .()) == "Alt+Page Up");
		Test.Assert(EditorShortcut(.Delete).ToString(.. scope .()) == "Delete");
	}
}
