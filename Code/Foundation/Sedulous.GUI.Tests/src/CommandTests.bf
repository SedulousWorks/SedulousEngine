using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A control that keeps the state its command's binding last told it.
class StateProbe : UIWidget
{
	public bool Available = false;
	public String Reason = new .() ~ delete _;

	public override void OnBoundCommandState(BoundCommandState state)
	{
		base.OnBoundCommandState(state);
		Available = state.Available;
		Reason.Set(state.Reason);
	}
}

/// Commands: one model controls bind to by id; running walks the focus path (capture down, bubble
/// up, a bubble handler stopping it unless it propagates); a command is available when enabled with
/// a handler on the focus path, and its state reaches a bound button or menu item with no
/// bookkeeping; a handler may end the nodes on its path.
class CommandTests
{
	[Test]
	public static void RunningWalksTheFocusPathCaptureDownThenBubbleUp()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let panel = new UIWidget();
		defer panel.ReleaseRef();
		let field = new Button();
		defer field.ReleaseRef();
		field.TabFocusable = true;
		root.AddChild(panel);
		panel.AddChild(field);
		let order = scope List<String>();
		defer { ClearAndDeleteItems!(order); }
		root.OnCommand("save", new [&] (command) => { order.Add(new String("root-capture")); }, .Capture);
		panel.OnCommand("save", new [&] (command) => { order.Add(new String("panel-capture")); }, .Capture);
		field.OnCommand("save", new [&] (command) => { order.Add(new String("field")); });
		panel.OnCommand("save", new [&] (command) => { order.Add(new String("panel")); });
		root.OnCommand("save", new [&] (command) => { order.Add(new String("root")); });
		root.EventDispatcher.FocusNode = field;

		Test.Assert(root.RunCommand("save"));
		Test.Assert(order.Count == 3); // the field's bubble handler stopped it
		Test.Assert(order[0] == "root-capture");
		Test.Assert(order[1] == "panel-capture");
		Test.Assert(order[2] == "field");

		// A bubble handler that propagates lets it go on up.
		field.OnCommand("open", new (command) => { command.Propagate = true; });
		bool reachedRoot = false;
		root.OnCommand("open", new [&] (command) => { reachedRoot = true; });
		Test.Assert(root.RunCommand("open"));
		Test.Assert(reachedRoot);

		// When every handler passes it on (each says: not mine), nothing took it.
		field.OnCommand("undo", new (command) => { command.Propagate = true; });
		root.OnCommand("undo", new (command) => { command.Propagate = true; });
		Test.Assert(!root.RunCommand("undo"));

		// Disabled, it does not run; unhandled, it reports so.
		root.Context.DefineCommand("save").Enabled = false;
		ClearAndDeleteItems!(order);
		Test.Assert(!root.RunCommand("save"));
		Test.Assert(order.IsEmpty);
		Test.Assert(!root.RunCommand("nobody"));
	}

	[Test]
	public static void AHandlerThatEndsTheNodesOnItsPathTheLastHoldOnThemFinishesTheWalkSafely()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		var panel = new UIWidget();
		let field = new Button();
		defer field.ReleaseRef();
		field.TabFocusable = true;
		root.AddChild(panel);
		panel.AddChild(field);
		root.EventDispatcher.FocusNode = field;
		// The panel's handler takes it out of the tree and lets go of it: the walk still has it.
		bool reachedRoot = false;
		panel.OnCommand("close", new [&] (command) =>
			{
				command.Propagate = true;
				let gone = panel;
				panel = null;
				gone.RemoveFromParent();
				gone.ReleaseRef();
			});
		root.OnCommand("close", new [&] (command) => { reachedRoot = true; });
		Test.Assert(root.RunCommand("close"));
		Test.Assert(panel == null);
		Test.Assert(reachedRoot);
	}

	[Test]
	public static void AvailabilityFollowsFocusAndABoundButtonGreysAndLightsWithIt()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let editor = new UIWidget(); // handles "cut" while focus is inside it
		defer editor.ReleaseRef();
		let inside = new Button();
		defer inside.ReleaseRef();
		let outside = new Button();
		defer outside.ReleaseRef();
		let cut = new Button(); // a toolbar button bound to "cut"
		defer cut.ReleaseRef();
		inside.TabFocusable = true;
		outside.TabFocusable = true;
		root.AddChild(editor);
		editor.AddChild(inside);
		root.AddChild(outside);
		root.AddChild(cut);
		int cuts = 0;
		editor.OnCommand("cut", new [&] (command) => { cuts++; });
		cut.Command = "cut";
		let d = root.EventDispatcher;

		d.FocusNode = outside;
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!cut.Enabled); // no handler on the focus path

		d.FocusNode = inside;
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(cut.Enabled);
		cut.Position = .(0.0f, 0.0f);
		cut.Size = .(40.0f, 20.0f);
		Test.Assert(cut.HandleActivate()); // a click (Return) on it runs the command along the focus path
		Test.Assert(cuts == 1);

		root.Context.DefineCommand("cut").Enabled = false; // one switch greys every control bound to it
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!cut.Enabled);
	}

	[Test]
	public static void ACaptureHandlerThatStopsItTakesItNothingBelowRunsNorAnyBubbleHandler()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let panel = new UIWidget();
		defer panel.ReleaseRef();
		let field = new Button();
		defer field.ReleaseRef();
		field.TabFocusable = true;
		root.AddChild(panel);
		panel.AddChild(field);
		let order = scope List<String>();
		defer { ClearAndDeleteItems!(order); }
		panel.OnCommand("save", new [&] (command) =>
			{
				order.Add(new String("panel-capture"));
				command.Stop = true;
			}, .Capture);
		field.OnCommand("save", new [&] (command) => { order.Add(new String("field")); });
		root.OnCommand("save", new [&] (command) => { order.Add(new String("root")); });
		root.EventDispatcher.FocusNode = field;
		Test.Assert(root.RunCommand("save"));
		Test.Assert(order.Count == 1);
		Test.Assert(order[0] == "panel-capture");
	}

	[Test]
	public static void ABoundControlHearsWhyItsCommandIsDisabledAndOnlyWhileItIs()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let probe = new StateProbe();
		defer probe.ReleaseRef();
		root.AddChild(probe);
		root.OnCommand("save", new (command) => { });
		let save = root.Context.DefineCommand("save");
		save.DisabledReason = "Nothing to save";
		probe.Command = "save";
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(probe.Available);
		Test.Assert(probe.Reason.Length == 0); // enabled: the reason is not said

		save.Enabled = false;
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!probe.Available);
		Test.Assert(probe.Reason == "Nothing to save");

		save.DisabledReason = "Read only"; // followed as it changes
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(probe.Reason == "Read only");

		// Unavailable for want of a handler where the focus is: no reason.
		save.Enabled = true;
		probe.Command = "unhandled";
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!probe.Available);
		Test.Assert(probe.Reason.Length == 0);
	}

	[Test]
	public static void ACheckBoxAndAMenuItemShowTheCommandsCheckedStateAndRunIt()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let music = root.Context.DefineCommand("music");
		root.OnCommand("music", new (command) => { music.Checked = !music.Checked; });
		let check = new CheckBox();
		defer check.ReleaseRef();
		check.Size = .(20.0f, 20.0f);
		let item = new MenuItem();
		defer item.ReleaseRef();
		item.Checkable = true;
		root.AddChild(check);
		root.AddChild(item);
		check.Command = "music";
		item.Command = "music";
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(check.Enabled);
		Test.Assert(!check.Checked);

		Test.Assert(check.HandleActivate()); // the box asks the command; the handler toggles it
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(music.Checked);
		Test.Assert(check.Checked);
		Test.Assert(item.Checked); // the menu item follows the same command
	}

	[Test]
	public static void MarkupBindsAControlToACommandByIdBeforeItIsAttached()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.OnCommand("play", new (command) => { });
		root.Context.DefineCommand("play").Enabled = false;
		let tree = MarkupFixtures.Load("<Button command=\"play\" text=\"Play\"/>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let play = tree as Button;
		Test.Assert(play != null);
		Test.Assert(play.Command == "play");
		root.AddChild(tree); // joining the GUI reaches its binding
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!play.Enabled);
		root.Context.DefineCommand("play").Enabled = true;
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(play.Enabled);
	}
}
