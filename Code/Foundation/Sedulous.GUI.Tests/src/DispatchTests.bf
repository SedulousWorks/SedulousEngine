using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A widget with a tooltip whose content is a probe (Node's own default makes none).
class TipWidget : UIWidget
{
	public override Node CreateTooltipContent(StringView text)
	{
		let tip = new Probe("tip");
		tip.Size = .(60.0f, 20.0f);
		return tip;
	}
}

/// What the dispatcher, the scene root and the GUI cluster do beyond the ported tests: bubbling
/// stopped by a handler, tab-index order, a popup's light dismiss, a tooltip's delay, a drag's
/// enter, over, drop and cancel, a bound command following its handlers and the focus, a subtree
/// leaving while pressed and captured, the frame's reasons, the bindings' one flush a frame,
/// commands and keystrokes along the focus path, leaving, entering and inert.
class DispatchTests
{
	[Test]
	public static void AHandledEventBubblesNoFurtherThanItsNode()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let card = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "card");
		defer card.ReleaseRef();
		let inner = SceneFixtures.NewWidget(card, 10, 10, 100, 100, "inner");
		defer inner.ReleaseRef();
		let trace = scope RouteTrace();
		trace.Watch(card, .MouseDown);
		inner.AddEventListener(.MouseDown, new (e) => { e.Handled = true; }); // its bubble listener takes it
		let used = root.EventDispatcher.InjectMouseDown(.(20.0f, 20.0f), .Left);
		Test.Assert(used); // handled: the GUI used it
		Test.Assert(trace.Is("card capture")); // down through the card, never back up to it
	}

	[Test]
	public static void TabIndexOrdersTabPositiveFirstLowestFirstNegativeSkipped()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let a = SceneFixtures.NewWidget(root, 0, 0, 40, 20, "a");
		defer a.ReleaseRef();
		let b = SceneFixtures.NewWidget(root, 0, 30, 40, 20, "b");
		defer b.ReleaseRef();
		let c = SceneFixtures.NewWidget(root, 0, 60, 40, 20, "c");
		defer c.ReleaseRef();
		let skipped = SceneFixtures.NewWidget(root, 0, 90, 40, 20, "skipped");
		defer skipped.ReleaseRef();
		a.TabFocusable = true;
		b.TabFocusable = true;
		c.TabFocusable = true;
		skipped.TabFocusable = true;
		b.TabIndex = 2;
		c.TabIndex = 1;
		skipped.TabIndex = -1;
		let d = root.EventDispatcher;
		let stops = scope List<Node>();
		d.TabStops(stops);
		Test.Assert(stops.Count == 3);
		Test.Assert((stops[0] == c) && (stops[1] == b) && (stops[2] == a));
		Test.Assert(d.FocusNext());
		Test.Assert(d.FocusNode == c);
		Test.Assert(d.FocusPrevious()); // from the first, round to the last
		Test.Assert(d.FocusNode == a);
		skipped.RequestFocus(); // never by Tab, though code still focuses it
		Test.Assert(d.FocusNode == skipped);
	}

	[Test]
	public static void APressOutsideAnAutoPopupClosesItAndIsConsumedAManualOneStays()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		int rootPresses = 0;
		int rootReleases = 0;
		root.AddEventListener(.MouseDown, new [&](e) => { rootPresses++; });
		root.AddEventListener(.MouseUp, new [&](e) => { rootReleases++; });
		let popup = SceneFixtures.NewProbe(null, "popup", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer popup.ReleaseRef();
		PopupCloseReason why = .Code;
		let options = SceneFixtures.At(.(10.0f, 10.0f));
		options.OnClosed = new [&](reason) => { why = reason; };
		d.OpenPopup(root, popup, options);
		int popupPresses = 0;
		popup.AddEventListener(.MouseDown, new [&](e) => { popupPresses++; });
		SceneFixtures.Click(d, .(50.0f, 50.0f)); // inside: it stays, and hears the press
		Test.Assert(d.IsPopupOpen(popup));
		Test.Assert(popupPresses == 1);
		let before = rootPresses; // the press inside bubbled to the root
		SceneFixtures.Click(d, .(300.0f, 250.0f)); // outside
		Test.Assert(!d.IsPopupOpen(popup));
		Test.Assert(why == .OutsidePress);
		Test.Assert(rootPresses == before); // the press that closed it went no further
		Test.Assert(rootReleases == 1); // nor its release (the inside click's was the one)
		Test.Assert(popup.Parent == null); // a closed popup leaves the tree

		let dialog = SceneFixtures.NewProbe(null, "dialog", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer dialog.ReleaseRef();
		d.OpenPopup(root, dialog, SceneFixtures.At(.(10.0f, 10.0f), .Manual));
		SceneFixtures.Click(d, .(300.0f, 250.0f));
		Test.Assert(d.IsPopupOpen(dialog)); // closed from code only
		Test.Assert(d.ClosePopup(dialog));
		Test.Assert(!d.ClosePopup(dialog)); // not open now
	}

	[Test]
	public static void ATooltipShowsAfterItsDelayAPressHidesItAndTheNextShowsAtOnceWhileWarm()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let a = new TipWidget();
		defer a.ReleaseRef();
		a.Position = .(0.0f, 0.0f);
		a.Size = .(100.0f, 40.0f);
		a.Tooltip = "first";
		root.AddChild(a);
		let b = new TipWidget();
		defer b.ReleaseRef();
		b.Position = .(200.0f, 0.0f);
		b.Size = .(100.0f, 40.0f);
		b.Tooltip = "second";
		root.AddChild(b);
		let d = root.EventDispatcher;
		Test.Assert(NodeFixtures.Near(d.TooltipDelay, 0.5f));

		d.InjectMouseMove(.(10.0f, 10.0f));
		d.Tick(0.3f);
		Test.Assert(d.ShownTooltip == null); // not yet: 0.3 of 0.5 seconds
		d.Tick(0.3f);
		Test.Assert(d.ShownTooltip != null);
		Test.Assert(d.ShownTooltip is Probe);
		Test.Assert(d.PopupOptionsAt(0).Kind == .Hint);

		// Over the other while warm: it shows at the next tick.
		d.InjectMouseMove(.(210.0f, 10.0f));
		d.Tick(0.01f);
		Test.Assert(d.ShownTooltip != null);
		Test.Assert(d.PopupCount == 1); // the first one's went

		// A press hides it, and it stays hidden over the same node.
		d.InjectMouseDown(.(210.0f, 10.0f), .Left);
		d.InjectMouseUp(.(210.0f, 10.0f), .Left);
		Test.Assert(d.ShownTooltip == null);
		d.Tick(1.0f);
		Test.Assert(d.ShownTooltip == null);
	}

	[Test]
	public static void ADragEntersGoesOverAndDropsOnItsTargetAndEscapeCancelsOne()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let source = SceneFixtures.NewWidget(root, 0, 0, 100, 40, "source");
		defer source.ReleaseRef();
		source.DragType = "text";
		source.DragValue = "hello";
		let target = SceneFixtures.NewWidget(root, 140, 0, 100, 40, "target");
		defer target.ReleaseRef();
		target.DropTypes = "text";
		let seen = scope List<String>();
		defer { ClearAndDeleteItems!(seen); }
		EventType[4] types = .(.DragEnter, .DragOver, .DragLeave, .Drop);
		for (let type in types)
			target.AddEventListener(type, new [&](e) => { seen.Add(new String(EventTypeName(e.Type))); });
		DropEffect ended = .Copy;
		bool cancelled = false;
		int ends = 0;
		source.SetOnDragEnd(new [&](result) =>
			{
				ended = result.Effect;
				cancelled = result.Cancelled;
				ends++;
			});
		int clicks = 0;
		source.AddEventListener(.MouseClick, new [&](e) => { clicks++; });
		let d = root.EventDispatcher;

		d.InjectMouseDown(.(20.0f, 20.0f), .Left);
		d.InjectMouseMove(.(24.0f, 20.0f)); // within the threshold: still a press
		Test.Assert(!d.IsDragging);
		d.InjectMouseMove(.(30.0f, 20.0f)); // past it: the source gives a drag
		Test.Assert(d.IsDragging);
		Test.Assert(d.DragSource == source);
		Test.Assert(d.DragPayload.Type == "text");
		Test.Assert(d.DragPayload.Label == "hello"); // no drag-label: its value
		Test.Assert(source.IsDragSource);
		Test.Assert(d.DropTarget == null);
		Test.Assert(d.PopupCount == 1); // the drag's layer
		d.InjectMouseMove(.(150.0f, 20.0f));
		Test.Assert(d.DropTarget == target);
		Test.Assert(target.IsDropTarget);
		Test.Assert(d.DropEffect == .Move); // the first the source allows
		Test.Assert(d.Cursor == .Move);
		d.InjectMouseMove(.(155.0f, 20.0f));
		d.InjectMouseUp(.(155.0f, 20.0f), .Left);
		Test.Assert(!d.IsDragging);
		Test.Assert(seen.Count == 5);
		Test.Assert((seen[0] == "dragenter") && (seen[1] == "dragover") && (seen[2] == "dragover") && (seen[3] == "dragover") && (seen[4] == "drop"));
		Test.Assert(ends == 1);
		Test.Assert(ended == .Move);
		Test.Assert(!cancelled);
		Test.Assert(clicks == 0); // the press became the drag's
		Test.Assert(!source.IsDragSource);
		Test.Assert(!target.IsDropTarget);
		Test.Assert(d.PopupCount == 0);

		ClearAndDeleteItems!(seen);
		d.InjectMouseDown(.(20.0f, 20.0f), .Left);
		d.InjectMouseMove(.(30.0f, 20.0f));
		d.InjectMouseMove(.(150.0f, 20.0f));
		Test.Assert(d.DropTarget == target);
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!d.IsDragging);
		Test.Assert(ends == 2);
		Test.Assert(cancelled);
		Test.Assert(ended == .None);
		Test.Assert(seen.Back == "dragleave"); // the target told the drag left it
		Test.Assert(!target.IsDropTarget);
	}

	[Test]
	public static void ABoundCommandFollowsItsHandlersAndTheFocus()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let editor = SceneFixtures.NewWidget(root, 0, 0, 200, 100, "editor");
		defer editor.ReleaseRef();
		let inside = SceneFixtures.NewWidget(editor, 10, 10, 40, 20, "inside");
		defer inside.ReleaseRef();
		inside.TabFocusable = true;
		let probe = new StateProbe();
		defer probe.ReleaseRef();
		root.AddChild(probe);
		probe.Command = "cut";
		Test.Assert(probe.HasCommand);
		Test.Assert(probe.Command == "cut");
		let d = root.EventDispatcher;
		d.FocusNode = inside;
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!probe.Available); // no handler on the focus path

		int cuts = 0;
		let token = editor.OnCommand("cut", new [&](command) => { cuts++; }); // a handler added: told
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(probe.Available);
		Test.Assert(probe.RunBoundCommand());
		Test.Assert(cuts == 1);

		d.FocusNode = null; // the focus left the editor
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!probe.Available);
		d.FocusNode = inside;
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(probe.Available);

		Test.Assert(editor.RemoveCommandHandler(token)); // removed: told too
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!probe.Available);
		Test.Assert(!probe.RunBoundCommand());
	}

	[Test]
	public static void ASubtreeLeavingTheTreeTakesThePressAndTheCaptureIntoIt()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let panel = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "panel");
		defer panel.ReleaseRef();
		let child = SceneFixtures.NewWidget(panel, 10, 10, 50, 50, "child");
		defer child.ReleaseRef();
		int lost = 0;
		child.AddEventListener(.PointerCaptureLost, new [&](e) => { lost++; });
		int clicks = 0;
		root.AddEventListener(.MouseClick, new [&](e) => { clicks++; });
		let d = root.EventDispatcher;
		d.InjectMouseMove(.(20.0f, 20.0f));
		d.InjectMouseDown(.(20.0f, 20.0f), .Left);
		d.CapturePointer(child);
		Test.Assert(child.Pressed && panel.Pressed && child.Hovered);
		root.RemoveChild(panel);
		Test.Assert(!child.Pressed);
		Test.Assert(!panel.Pressed);
		Test.Assert(!child.Hovered);
		Test.Assert(lost == 1); // told while it still lived
		Test.Assert(d.PointerCapture == null);
		Test.Assert(!root.Pressed); // the press path went with the node it started at
		d.InjectMouseUp(.(20.0f, 20.0f), .Left);
		Test.Assert(clicks == 0); // no press left to finish
	}

	[Test]
	public static void NeedsFrameSaysWhatAsksForOne()
	{
		let root = SceneFixtures.NewScene(100.0f, 100.0f);
		defer root.ReleaseRef();
		let child = SceneFixtures.NewNode(10.0f, 10.0f, 20.0f, 20.0f, root);
		defer child.ReleaseRef();
		Test.Assert(root.NeedsFrame()); // nothing drawn yet
		Test.Assert(root.LastFrameStats.Reasons.Redraw);
		Test.Assert(root.LastFrameStats.Reasons.Layout);
		root.UpdateLayout();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		root.DrawFrame(dc);
		Test.Assert(!root.NeedsFrame()); // idle: it costs nothing
		Test.Assert(!root.LastFrameStats.Reasons.Any);

		let value = scope Property<int>(0);
		int seen = -1;
		child.Bind(new [&]() => { seen = value.Get(); });
		Test.Assert(seen == 0); // a binding runs at once
		value.Set(1);
		Test.Assert(seen == 0); // then on the GUI's frame
		Test.Assert(root.NeedsFrame());
		Test.Assert(root.LastFrameStats.Reasons.Pending);
		Test.Assert(!root.LastFrameStats.Reasons.Layout);
		root.Context.Update(TimeSpan(0));
		Test.Assert(seen == 1);
		Test.Assert(!root.NeedsFrame());

		child.Size = .(30.0f, 30.0f);
		Test.Assert(root.NeedsFrame());
		Test.Assert(root.LastFrameStats.Reasons.Layout);
		root.UpdateLayout();
		root.DrawFrame(dc);

		let d = root.EventDispatcher;
		d.PressDirection(.Down);
		Test.Assert(root.NeedsFrame());
		Test.Assert(root.LastFrameStats.Reasons.HeldDirection);
		d.ReleaseDirection(.Down);
		root.NeedsFrame();
		Test.Assert(!root.LastFrameStats.Reasons.HeldDirection);
	}

	[Test]
	public static void TheBindingsRunOnceAFrameHoweverManyChangesReachThem()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let node = new Node();
		defer node.ReleaseRef();
		root.AddChild(node);
		let value = scope Property<int>(0);
		int runs = 0;
		node.Bind(new [&]() =>
			{
				value.Get();
				runs++;
			});
		Test.Assert(runs == 1);
		value.Set(1);
		value.Set(2);
		value.Set(3);
		Test.Assert(runs == 1); // queued once, not run
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(runs == 2);
		Test.Assert(root.Context.LastBindingCount == 1);
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(runs == 2);
		Test.Assert(root.Context.LastBindingCount == 0);
	}

	[Test]
	public static void ACommandRunsCaptureDownThenBubbleUpAndABoundKeystrokeRunsItAlongTheFocusPath()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let panel = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "panel");
		defer panel.ReleaseRef();
		let field = SceneFixtures.NewWidget(panel, 10, 10, 50, 20, "field");
		defer field.ReleaseRef();
		field.TabFocusable = true;
		let order = scope List<String>();
		defer { ClearAndDeleteItems!(order); }
		root.OnCommand("save", new [&](command) => { order.Add(new String("root-capture")); }, .Capture);
		panel.OnCommand("save", new [&](command) => { order.Add(new String("panel-capture")); }, .Capture);
		field.OnCommand("save", new [&](command) => { order.Add(new String("field")); });
		panel.OnCommand("save", new [&](command) => { order.Add(new String("panel")); });
		root.OnCommand("save", new [&](command) => { order.Add(new String("root")); });
		let d = root.EventDispatcher;
		d.FocusNode = field;

		Test.Assert(root.RunCommand("save"));
		Test.Assert(order.Count == 3); // the field's bubble handler stopped it
		Test.Assert((order[0] == "root-capture") && (order[1] == "panel-capture") && (order[2] == "field"));
		Test.Assert(root.IsCommandAvailable("save"));

		// A keystroke no widget takes goes to the keymap, which runs the command it binds.
		ClearAndDeleteItems!(order);
		Test.Assert(root.Context.Keymap.Bind("ctrl-s", "save"));
		Test.Assert(d.InjectKeyDown((uint32)KeyCode.S, KeyModCtrl));
		Test.Assert(order.Count == 3);
		// One nothing on the focus path handles lets the key go on.
		Test.Assert(root.Context.Keymap.Bind("ctrl-o", "open"));
		Test.Assert(!d.InjectKeyDown((uint32)KeyCode.O, KeyModCtrl));

		// Disabled, it does not run.
		ClearAndDeleteItems!(order);
		root.Context.DefineCommand("save").Enabled = false;
		Test.Assert(!root.RunCommand("save"));
		Test.Assert(order.IsEmpty);
		Test.Assert(!root.IsCommandAvailable("save"));
	}

	[Test]
	public static void ALeavingNodeIsOutOfInputAtOnceAnEntranceWithNoStylePassEndsAtOnceAndInertLetsGo()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let leaving = SceneFixtures.NewWidget(root, 0, 0, 100, 40, "leaving");
		defer leaving.ReleaseRef();
		leaving.TabFocusable = true;
		d.InjectMouseMove(.(10.0f, 10.0f));
		leaving.RequestFocus();
		Test.Assert(leaving.Hovered && leaving.IsFocused);
		leaving.Leave();
		Test.Assert(leaving.IsLeaving);
		Test.Assert(leaving.Parent == root); // it goes at the next update
		Test.Assert(!leaving.Hovered);
		Test.Assert(d.FocusNode == null);
		leaving.RequestFocus(); // what leaves takes no focus
		Test.Assert(d.FocusNode == null);
		root.Context.Update(TimeSpan(0));
		Test.Assert(leaving.Parent == null);

		let arriving = SceneFixtures.NewWidget(root, 0, 0, 100, 40, "arriving");
		defer arriving.ReleaseRef();
		int entered = 0;
		arriving.AddEventListener(.Entered, new [&](e) => { entered++; });
		arriving.Enter();
		Test.Assert(entered == 1); // no style pass: nothing plays an entrance
		Test.Assert(!arriving.IsArriving);

		let screen = SceneFixtures.NewWidget(root, 0, 100, 200, 100, "screen");
		defer screen.ReleaseRef();
		let button = SceneFixtures.NewWidget(screen, 10, 10, 50, 20, "button");
		defer button.ReleaseRef();
		button.TabFocusable = true;
		int presses = 0;
		button.AddEventListener(.MouseDown, new [&](e) => { presses++; });
		button.RequestFocus();
		Test.Assert(d.FocusNode == button);
		screen.SetInert(true);
		Test.Assert(screen.IsInert);
		Test.Assert(d.FocusNode == null); // it let the focus go
		button.RequestFocus();
		Test.Assert(d.FocusNode == null);
		d.InjectMouseDown(.(20.0f, 120.0f), .Left);
		Test.Assert(presses == 0);
		d.InjectMouseUp(.(20.0f, 120.0f), .Left);
		screen.SetInert(false);
		d.InjectMouseDown(.(20.0f, 120.0f), .Left);
		Test.Assert(presses == 1);
	}
}
