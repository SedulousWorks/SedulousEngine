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
/// is hovered, every node holding the pressed one is pressed); pointer capture and its loss; click
/// counts; and the fingers.
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
}
