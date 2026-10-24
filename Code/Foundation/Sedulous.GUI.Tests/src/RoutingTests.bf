using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Records "<node> <phase>" for every listener call on the nodes it watches, capture and bubble.
class RouteTrace
{
	public List<String> Calls = new .() ~ DeleteContainerAndItems!(_);

	public void Watch(Node node, EventType type)
	{
		for (int pass = 0; pass < 2; pass++)
		{
			node.AddEventListener(type, new (e) =>
				{
					let line = new String();
					RoutingTests.Name(node, line);
					line.Append(" ");
					line.Append((e.Phase == .Capture) ? "capture" : (e.Phase == .Target) ? "target" : "bubble");
					Calls.Add(line);
				}, pass == 0); // capture, then bubble
		}
	}

	public bool Is(params Span<StringView> expected)
	{
		if (Calls.Count != expected.Length)
			return false;
		for (int i = 0; i < expected.Length; i++)
		{
			if (Calls[i] != expected[i])
				return false;
		}
		return true;
	}
}

/// Routing: an input event goes down from the root through the capture listeners, reaches its
/// target, and comes back up, each node's own handler running in the bubble phase and a handled
/// event ending the route after its node; the hover and press paths (every node under the pointer
/// is hovered, every node holding the pressed one is pressed); pointer capture and its loss; a
/// click on the nearest node holding the press and the release; click counts; the fingers; and what
/// the Inject calls tell a host.
class RoutingTests
{
	public static void Name(Node node, String outText)
	{
		let widget = node as UIWidget;
		outText.Append((widget != null) ? widget.Id : "root");
	}

	[Test]
	public static void APressGoesDownThroughCaptureReachesItsTargetAndComesBackUp()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let card = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "card");
		defer card.ReleaseRef();
		let inner = SceneFixtures.NewWidget(card, 10, 10, 100, 100, "inner");
		defer inner.ReleaseRef();
		let trace = scope RouteTrace();
		trace.Watch(card, .MouseDown);
		trace.Watch(inner, .MouseDown);
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(20.0f, 20.0f), .Left);
		Test.Assert(trace.Is("card capture", "inner target", "inner target", "card bubble"));
		d.InjectMouseUp(.(20.0f, 20.0f), .Left);

		// A parent handling the press in capture keeps it from its child (a list taking a drag).
		ClearAndDeleteItems!(trace.Calls);
		card.AddEventListener(.MouseDown, new (e) => { e.Handled = true; }, true);
		d.InjectMouseDown(.(20.0f, 20.0f), .Left);
		Test.Assert(trace.Is("card capture"));
	}

	[Test]
	public static void AHandlerRemovingTheNodesAboveItDoesNotBreakTheWalk()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let card = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "card");
		defer card.ReleaseRef();
		let inner = SceneFixtures.NewWidget(card, 10, 10, 100, 100, "inner");
		defer inner.ReleaseRef();
		int cardSaw = 0;
		card.AddEventListener(.MouseDown, new [&](e) => { cardSaw++; });
		inner.AddEventListener(.MouseDown, new [&](e) => { root.RemoveChild(card); });
		root.EventDispatcher.InjectMouseDown(.(20.0f, 20.0f), .Left);
		Test.Assert(card.Parent == null);
		Test.Assert(cardSaw == 0); // it left the tree before the press came back up
	}

	[Test]
	public static void EveryNodeUnderThePointerIsHoveredAndToldAsItJoinsOrLeaves()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let card = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "card");
		defer card.ReleaseRef();
		let a = SceneFixtures.NewWidget(card, 10, 10, 50, 50, "a");
		defer a.ReleaseRef();
		let b = SceneFixtures.NewWidget(card, 100, 10, 50, 50, "b");
		defer b.ReleaseRef();
		int cardEnters = 0;
		int cardLeaves = 0;
		int aLeaves = 0;
		int bEnters = 0;
		card.AddEventListener(.MouseEnter, new [&](e) => { cardEnters++; });
		card.AddEventListener(.MouseLeave, new [&](e) => { cardLeaves++; });
		a.AddEventListener(.MouseLeave, new [&](e) => { aLeaves++; });
		b.AddEventListener(.MouseEnter, new [&](e) => { bEnters++; });
		let d = root.EventDispatcher;
		d.InjectMouseMove(.(20.0f, 20.0f));
		Test.Assert(a.Hovered);
		Test.Assert(card.Hovered); // :hover holds for the card while a is under the pointer
		Test.Assert(cardEnters == 1);
		d.InjectMouseMove(.(110.0f, 20.0f)); // a to b, inside the card
		Test.Assert(!a.Hovered);
		Test.Assert(b.Hovered);
		Test.Assert(aLeaves == 1);
		Test.Assert(bEnters == 1);
		Test.Assert(cardEnters == 1); // never left
		Test.Assert(cardLeaves == 0);
		d.InjectMouseMove(.(300.0f, 300.0f));
		Test.Assert(!card.Hovered);
		Test.Assert(cardLeaves == 1);
		Test.Assert(d.OverNode == root);
	}

	[Test]
	public static void ThePressedNodeAndTheNodesHoldingItArePressedUntilTheRelease()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let card = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "card");
		defer card.ReleaseRef();
		let a = SceneFixtures.NewWidget(card, 10, 10, 50, 50, "a");
		defer a.ReleaseRef();
		let other = SceneFixtures.NewWidget(root, 250, 0, 50, 50, "other");
		defer other.ReleaseRef();
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(20.0f, 20.0f), .Left);
		Test.Assert(a.Pressed);
		Test.Assert(card.Pressed);
		Test.Assert(!other.Pressed);
		d.InjectMouseUp(.(20.0f, 20.0f), .Left);
		Test.Assert(!a.Pressed);
		Test.Assert(!card.Pressed);
	}

	[Test]
	public static void PointerCaptureHoldsTheMovesAndTheReleaseAndIsLostWhenItEnds()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let knob = SceneFixtures.NewWidget(root, 0, 0, 50, 50, "knob");
		defer knob.ReleaseRef();
		let other = SceneFixtures.NewWidget(root, 200, 0, 50, 50, "other");
		defer other.ReleaseRef();
		int knobMoves = 0;
		int otherMoves = 0;
		int lost = 0;
		knob.AddEventListener(.MouseMove, new [&](e) => { knobMoves++; });
		other.AddEventListener(.MouseMove, new [&](e) => { otherMoves++; });
		knob.AddEventListener(.PointerCaptureLost, new [&](e) => { lost++; });
		let d = root.EventDispatcher;
		d.CapturePointer(knob);
		d.InjectMouseMove(.(210.0f, 10.0f)); // over the other node
		Test.Assert(knobMoves == 1);
		Test.Assert(otherMoves == 0);
		Test.Assert(other.Hovered); // hover still follows the pointer
		d.InjectMouseUp(.(210.0f, 10.0f), .Left);
		Test.Assert(lost == 1); // the press ended it
		Test.Assert(d.PointerCapture == null);

		d.CapturePointer(knob);
		d.CapturePointer(other); // taken by another
		Test.Assert(lost == 2);
		int otherLost = 0;
		other.AddEventListener(.PointerCaptureLost, new [&](e) => { otherLost++; });
		d.CapturePointer(knob); // taken back
		Test.Assert(otherLost == 1);
		root.RemoveChild(knob); // leaving the tree
		Test.Assert(lost == 3);
		Test.Assert(d.PointerCapture == null);
	}

	[Test]
	public static void PressesNearInTimeAndPlaceCountUpAPauseOrAMoveStartsAgain()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let target = SceneFixtures.NewWidget(root, 0, 0, 100, 100, "box");
		defer target.ReleaseRef();
		let counts = scope List<uint32>();
		target.AddEventListener(.MouseDown, new [&](e) => { counts.Add(((MouseEvent)e).ClickCount); });
		let d = root.EventDispatcher;
		void Press(float x)
		{
			d.InjectMouseDown(.(x, 10.0f), .Left);
			d.InjectMouseUp(.(x, 10.0f), .Left);
		}
		Press(10.0f);
		Press(12.0f);
		Press(11.0f);
		d.Tick(1.0f); // a pause
		Press(11.0f);
		Press(60.0f); // far away
		Test.Assert(counts.Count == 5);
		Test.Assert(counts[0] == 1);
		Test.Assert(counts[1] == 2);
		Test.Assert(counts[2] == 3);
		Test.Assert(counts[3] == 1);
		Test.Assert(counts[4] == 1);
	}

	[Test]
	public static void TheFirstFingerDrivesThePointerMovesFollowItAndASecondFingerIsIgnored()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let a = SceneFixtures.NewWidget(root, 0, 0, 50, 50, "a");
		defer a.ReleaseRef();
		let b = SceneFixtures.NewWidget(root, 100, 0, 50, 50, "b");
		defer b.ReleaseRef();
		int downs = 0;
		int moves = 0;
		root.AddEventListener(.MouseDown, new [&](e) => { downs++; });
		a.AddEventListener(.MouseMove, new [&](e) => { moves++; });
		let d = root.EventDispatcher;
		d.InjectTouchDown(1, .(10.0f, 10.0f));
		Test.Assert(!d.InjectTouchDown(2, .(110.0f, 10.0f))); // a second finger
		Test.Assert(!d.InjectTouchMove(2, .(120.0f, 10.0f)));
		Test.Assert(downs == 1);
		d.InjectTouchMove(1, .(110.0f, 10.0f)); // the press holds the moves for a
		Test.Assert(moves == 1);
		Test.Assert(b.Hovered); // and hover follows the finger
		Test.Assert(!d.InjectTouchUp(2, .(120.0f, 10.0f)));
		Test.Assert(d.IsTouchActive);
		d.InjectTouchUp(1, .(110.0f, 10.0f));
		Test.Assert(!d.IsTouchActive);
	}

	[Test]
	public static void EveryFingerDownIsFollowedWhereItWentDownAndWhereItIsUntilItLifts()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		Test.Assert(d.Fingers.Length == 0);
		d.InjectTouchDown(1, .(10.0f, 10.0f));
		d.InjectTouchDown(2, .(110.0f, 10.0f));
		d.InjectTouchMove(2, .(120.0f, 30.0f));
		Test.Assert(d.Fingers.Length == 2);
		Test.Assert(d.Fingers[1].Id == 2);
		Test.Assert(NodeFixtures.Near(d.Fingers[1].Start.X, 110.0f));
		Test.Assert(NodeFixtures.Near(d.Fingers[1].Now.X, 120.0f));
		Test.Assert(NodeFixtures.Near(d.Fingers[1].Now.Y, 30.0f));
		// The first lifting leaves the second followed, and the pointer free.
		d.InjectTouchUp(1, .(10.0f, 10.0f));
		Test.Assert(d.Fingers.Length == 1);
		Test.Assert(d.Fingers[0].Id == 2);
		Test.Assert(!d.IsTouchActive);
		d.InjectTouchUp(2, .(120.0f, 30.0f));
		Test.Assert(d.Fingers.Length == 0);
	}

	[Test]
	public static void TapsCountAsADoubleTapOverAWiderDistanceThanClicks()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let target = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "box");
		defer target.ReleaseRef();
		let counts = scope List<uint32>();
		target.AddEventListener(.MouseDown, new [&](e) => { counts.Add(((MouseEvent)e).ClickCount); });
		let d = root.EventDispatcher;
		d.InjectTouchDown(1, .(50.0f, 50.0f));
		d.InjectTouchUp(1, .(50.0f, 50.0f));
		d.InjectTouchDown(2, .(68.0f, 50.0f)); // 18 apart: a finger's wobble
		d.InjectTouchUp(2, .(68.0f, 50.0f));
		d.Tick(1.0f);
		d.InjectMouseDown(.(50.0f, 50.0f), .Left);
		d.InjectMouseUp(.(50.0f, 50.0f), .Left);
		d.InjectMouseDown(.(68.0f, 50.0f), .Left); // too far for a mouse
		Test.Assert(counts.Count == 4);
		Test.Assert(counts[1] == 2);
		Test.Assert(counts[3] == 1);
	}

	[Test]
	public static void PointerEventsAndCursorComeFromASheetTheCursorIsTheNearestSetOne()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let card = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "card");
		defer card.ReleaseRef();
		card.AddClass("card");
		let glass = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "glass"); // over the card
		defer glass.ReleaseRef();
		glass.AddClass("glass");
		let inner = SceneFixtures.NewWidget(card, 10, 10, 50, 50, "inner");
		defer inner.ReleaseRef();
		let sheet = scope StyleSheet();
		CSSParser.Parse(".glass { pointer-events: none; } .card { cursor: pointer; }", sheet);
		let styles = scope StyleManager(sheet);
		styles.ApplyTree(root);
		let d = root.EventDispatcher;
		d.InjectMouseMove(.(20.0f, 20.0f));
		Test.Assert(d.OverNode == inner); // through the glass
		Test.Assert(d.Cursor == .Pointer); // the card's, inherited by the inner box
		inner.Cursor = .Text;
		Test.Assert(d.Cursor == .Text);
		d.InjectMouseMove(.(300.0f, 300.0f));
		Test.Assert(d.Cursor == .Default);

		// While a press holds the pointer, the pressed node's look stays (a drag keeps its cursor).
		d.InjectMouseDown(.(20.0f, 20.0f), .Left);
		d.InjectMouseMove(.(300.0f, 300.0f));
		Test.Assert(d.Cursor == .Text);
		d.InjectMouseUp(.(300.0f, 300.0f), .Left);
		Test.Assert(d.Cursor == .Default);
	}

	[Test]
	public static void KeysBubbleFromTheFocusAScrollerScrollsOnlyWhenItIsFocused()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let page = SceneFixtures.NewWidget(root, 0, 0, 300, 300, "page");
		defer page.ReleaseRef();
		let field = SceneFixtures.NewWidget(page, 10, 10, 100, 30, "field");
		defer field.ReleaseRef();
		field.TabFocusable = true;
		int pageKeys = 0;
		page.AddEventListener(.KeyDown, new [&] (e) => { pageKeys++; });
		let d = root.EventDispatcher;
		d.FocusNode = field;
		Test.Assert(!d.InjectKeyDown((uint32)KeyCode.F5)); // nobody used it
		Test.Assert(pageKeys == 1);

		let scroller = new ScrollView();
		defer scroller.ReleaseRef();
		scroller.Size = .(100.0f, 100.0f);
		root.AddChild(scroller);
		let tall = SceneFixtures.NewWidget(scroller, 0, 0, 10, 400, "tall"); // what it scrolls over
		defer tall.ReleaseRef();
		let inside = SceneFixtures.NewWidget(scroller, 0, 0, 50, 20, "inside");
		defer inside.ReleaseRef();
		root.UpdateLayout();
		inside.TabFocusable = true;
		d.FocusNode = inside;
		d.InjectKeyDown((uint32)KeyCode.PageDown);
		Test.Assert(NodeFixtures.Near(scroller.ScrollOffset.Y, 0.0f)); // the key was the widget's to leave
		d.FocusNode = scroller;
		Test.Assert(d.InjectKeyDown((uint32)KeyCode.PageDown));
		Test.Assert(scroller.ScrollOffset.Y > 0.0f);
	}

	[Test]
	public static void TheWheelGoesUpFromThePointerAScrollerAtItsEndLeavesItToTheOneAroundIt()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let outer = new ScrollView();
		defer outer.ReleaseRef();
		outer.Size = .(200.0f, 200.0f);
		root.AddChild(outer);
		let outerTall = SceneFixtures.NewWidget(outer, 150, 0, 10, 800, "outer-tall");
		defer outerTall.ReleaseRef();
		let inner = new ScrollView();
		defer inner.ReleaseRef();
		inner.Size = .(100.0f, 100.0f);
		outer.AddChild(inner);
		let innerTall = SceneFixtures.NewWidget(inner, 0, 0, 10, 150, "inner-tall");
		defer innerTall.ReleaseRef();
		root.UpdateLayout();
		let d = root.EventDispatcher;
		Test.Assert(d.InjectMouseWheel(.(50.0f, 50.0f), .(0.0f, -10.0f)));
		Test.Assert(inner.ScrollOffset.Y > 0.0f);
		Test.Assert(NodeFixtures.Near(outer.ScrollOffset.Y, 0.0f));
		for (int i = 0; i < 20; ++i) // to the inner one's end, and on
			d.InjectMouseWheel(.(50.0f, 50.0f), .(0.0f, -10.0f));
		Test.Assert(NodeFixtures.Near(inner.ScrollOffset.Y, inner.ScrollRange.Y));
		Test.Assert(outer.ScrollOffset.Y > 0.0f);
	}

	[Test]
	public static void AHandledEventEndsAfterItsNodeTheNodesOwnListenersStillRun()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let card = SceneFixtures.NewWidget(root, 0, 0, 200, 200, "card");
		defer card.ReleaseRef();
		let button = new Button();
		defer button.ReleaseRef();
		button.Size = .(80.0f, 30.0f);
		card.AddChild(button);
		int buttonClicks = 0;
		int cardClicks = 0;
		button.SetOnClick(new [&] () => { buttonClicks++; });
		button.AddEventListener(.MouseClick, new [&] (e) => { buttonClicks++; });
		card.AddEventListener(.MouseClick, new [&] (e) => { cardClicks++; });
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		d.InjectMouseUp(.(10.0f, 10.0f), .Left);
		Test.Assert(buttonClicks == 2); // its handler and its listener
		Test.Assert(cardClicks == 0); // the button took the click
		d.InjectMouseDown(.(150.0f, 150.0f), .Left);
		d.InjectMouseUp(.(150.0f, 150.0f), .Left);
		Test.Assert(cardClicks == 1);
	}

	[Test]
	public static void AClickGoesToTheNearestNodeHoldingBothThePressAndTheRelease()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let row = SceneFixtures.NewWidget(root, 0, 0, 300, 50, "row");
		defer row.ReleaseRef();
		let a = SceneFixtures.NewWidget(row, 0, 0, 50, 50, "a");
		defer a.ReleaseRef();
		let b = SceneFixtures.NewWidget(row, 100, 0, 50, 50, "b");
		defer b.ReleaseRef();
		let clicked = scope List<String>();
		defer { ClearAndDeleteItems!(clicked); }
		Node[3] watched = .(row, a, b);
		for (let node in watched)
		{
			node.AddEventListener(.MouseClick, new (e) =>
				{
					if (e.Phase == .Target)
					{
						let name = new String();
						Name(node, name);
						clicked.Add(name);
					}
				});
		}
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(10.0f, 10.0f), .Left); // on a
		d.InjectMouseUp(.(110.0f, 10.0f), .Left); // released on b
		Test.Assert(clicked.Count == 1);
		Test.Assert(clicked[0] == "row");

		// A button holding a label: a click on the label is the button's.
		let button = new Button();
		defer button.ReleaseRef();
		button.Position = .(0.0f, 100.0f);
		button.Size = .(100.0f, 40.0f);
		root.AddChild(button);
		let caption = new Label();
		defer caption.ReleaseRef();
		caption.Size = .(60.0f, 20.0f);
		button.AddChild(caption);
		int presses = 0;
		button.SetOnClick(new [&] () => { presses++; });
		d.InjectMouseDown(.(10.0f, 105.0f), .Left);
		d.InjectMouseUp(.(10.0f, 105.0f), .Left);
		Test.Assert(presses == 1);
	}

	[Test]
	public static void TheInjectCallsTellAHostWhetherTheGUIUsedTheInput()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let layer = SceneFixtures.NewWidget(root, 0, 0, 400, 400, "layer"); // a full-window layout container
		defer layer.ReleaseRef();
		let button = new Button();
		defer button.ReleaseRef();
		button.Position = .(10.0f, 10.0f);
		button.Size = .(80.0f, 30.0f);
		button.TabFocusable = true;
		layer.AddChild(button);
		let d = root.EventDispatcher;
		Test.Assert(d.InjectMouseDown(.(20.0f, 20.0f), .Left));
		Test.Assert(d.InjectMouseUp(.(20.0f, 20.0f), .Left));
		Test.Assert(!d.InjectMouseDown(.(300.0f, 300.0f), .Left)); // the game's
		Test.Assert(!d.InjectMouseUp(.(300.0f, 300.0f), .Left));
		Test.Assert(d.IsPointerOver(.(20.0f, 20.0f)));
		Test.Assert(!d.IsPointerOver(.(300.0f, 300.0f)));
		let backdrop = scope NodeBox();
		backdrop.BackgroundColor = .(0.0f, 0.0f, 0.0f, 0.5f);
		layer.SetBox(backdrop, false); // a backdrop that paints
		Test.Assert(d.IsPointerOver(.(300.0f, 300.0f)));

		d.FocusNode = button;
		Test.Assert(d.InjectKeyDown((uint32)KeyCode.Return)); // activated
		Test.Assert(!d.InjectKeyDown((uint32)KeyCode.F7));
	}

	[Test]
	public static void ATapIsAPressAReleaseAndAClickMarkedAsTouchWithNoHoverLeftBehind()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let button = new Button();
		defer button.ReleaseRef();
		button.Position = .(10.0f, 10.0f);
		button.Size = .(80.0f, 30.0f);
		root.AddChild(button);
		let seen = scope List<String>();
		defer { ClearAndDeleteItems!(seen); }
		EventType[3] kinds = .(.MouseDown, .MouseUp, .MouseClick);
		for (let type in kinds)
		{
			button.AddEventListener(type, new (e) =>
				{
					let m = (MouseEvent)e;
					if ((m.Pointer == .Touch) && (m.PointerId == 7))
						seen.Add(new String((e.Type == .MouseDown) ? "down" : (e.Type == .MouseUp) ? "up" : "click"));
				});
		}
		let d = root.EventDispatcher;
		Test.Assert(d.InjectTouchDown(7, .(20.0f, 20.0f)));
		Test.Assert(button.Hovered); // while the finger is down
		Test.Assert(button.Pressed);
		Test.Assert(d.InjectTouchUp(7, .(20.0f, 20.0f)));
		Test.Assert(seen.Count == 3);
		Test.Assert(seen[0] == "down");
		Test.Assert(seen[1] == "up");
		Test.Assert(seen[2] == "click");
		Test.Assert(!button.Hovered); // the finger lifted: nothing under it
		Test.Assert(d.OverNode == null);
	}

	[Test]
	public static void CancelPointerEndsAPressWithNoClickAndASliderDropsItsDrag()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let button = new Button();
		defer button.ReleaseRef();
		button.Size = .(80.0f, 30.0f);
		root.AddChild(button);
		int clicks = 0;
		int cancels = 0;
		button.SetOnClick(new [&] () => { clicks++; });
		button.AddEventListener(.PointerCancel, new [&] (e) => { cancels++; });
		let d = root.EventDispatcher;
		d.InjectTouchDown(1, .(10.0f, 10.0f));
		d.CancelPointer(); // a scroller began panning under the finger
		Test.Assert(cancels == 1);
		Test.Assert(!button.Pressed);
		d.InjectTouchUp(1, .(10.0f, 10.0f));
		Test.Assert(clicks == 0);

		let slider = new Slider();
		defer slider.ReleaseRef();
		slider.Position = .(0.0f, 100.0f);
		slider.Size = .(200.0f, 20.0f);
		root.AddChild(slider);
		d.InjectMouseDown(.(100.0f, 110.0f), .Left);
		let before = (float)slider.Value;
		d.CancelPointer();
		d.InjectMouseMove(.(190.0f, 110.0f));
		Test.Assert(NodeFixtures.Near((float)slider.Value, before)); // the drag ended with the press
		d.InjectMouseUp(.(190.0f, 110.0f), .Left);
	}
}
