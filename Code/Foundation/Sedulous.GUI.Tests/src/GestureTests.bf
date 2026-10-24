using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// What a gesture event said, kept past its dispatch.
struct GestureSeen
{
	public float Scale = 1.0f;
	public float Rotation = 0.0f;
	public Float2 Translation = .(0.0f, 0.0f);
	public float ScaleDelta = 1.0f;

	public this() { }

	public this(GestureEvent e)
	{
		Scale = e.Scale;
		Rotation = e.Rotation;
		Translation = e.Translation;
		ScaleDelta = e.ScaleDelta;
	}
}

/// A root 400 by 400 with a pad at (50, 50), 300 by 300, of the touch actions given, and what the
/// pad heard. The root (and its tree) goes with it.
class GestureBed
{
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 400.0f) ~ _.ReleaseRef();
	public UIWidget Pad = new .() ~ _.ReleaseRef();
	public List<String> Seen = new .() ~ DeleteContainerAndItems!(_);
	public List<GestureSeen> Changes = new .() ~ delete _;
	public GestureSeen Last = .();

	public this(uint8 touchActions)
	{
		Pad.Position = .(50.0f, 50.0f);
		Pad.Size = .(300.0f, 300.0f);
		Pad.TouchActions = touchActions;
		Root.AddChild(Pad);
		EventType[6] types = .(.GestureStart, .GestureChange, .GestureEnd, .GestureCancel, .PointerCancel, .MouseClick);
		for (let type in types)
		{
			Pad.AddEventListener(type, new (e) =>
				{
					Seen.Add(new String(EventTypeName(e.Type)));
					if (e.Type == .GestureChange)
						Changes.Add(.((GestureEvent)e));
					if ((e.Type == .GestureEnd) || (e.Type == .GestureCancel) || (e.Type == .GestureChange))
						Last = .((GestureEvent)e);
				});
		}
		Root.UpdateLayout();
	}

	public EventDispatcher D => Root.EventDispatcher;

	public bool Saw(StringView name)
	{
		for (let s in Seen)
		{
			if (s == name)
				return true;
		}
		return false;
	}
}

/// Gestures: two fingers over a node whose touch-action leaves pinch-zoom out pinch, turn and pan
/// it as one; over a node that leaves it to the GUI, a second finger does nothing.
class GestureTests
{
	private static bool Near(float a, float b, float epsilon) => Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	[Test]
	public static void TwoFingersOverANodeThatKeepsPinchZoomPinchTurnAndPanItAsOne()
	{
		let bed = scope GestureBed(cTouchPanX | cTouchPanY); // pinch-zoom left out: two fingers are the node's
		let d = bed.D;
		d.InjectTouchDown(1, .(150.0f, 200.0f));
		Test.Assert(d.InjectTouchDown(2, .(250.0f, 200.0f)));
		Test.Assert(d.IsGesturing);
		Test.Assert(bed.Seen.Count >= 2);
		Test.Assert(bed.Saw("pointercancel")); // the first finger's press: a gesture, not a tap
		Test.Assert(bed.Seen.Back == "gesturestart");

		// Spread from 100 apart to 200: twice the scale, about the same middle.
		d.InjectTouchMove(1, .(100.0f, 200.0f));
		d.InjectTouchMove(2, .(300.0f, 200.0f));
		Test.Assert(NodeFixtures.Near(bed.Last.Scale, 2.0f));
		Test.Assert(NodeFixtures.Near(bed.Last.Translation.X, 0.0f));
		// The deltas multiply up to the total.
		float product = 1.0f;
		for (let e in bed.Changes)
			product *= e.ScaleDelta;
		Test.Assert(NodeFixtures.Near(product, 2.0f));

		// Turned a quarter, clockwise (y runs down): the second finger below the middle.
		d.InjectTouchMove(1, .(200.0f, 100.0f));
		d.InjectTouchMove(2, .(200.0f, 300.0f));
		Test.Assert(Near(bed.Last.Rotation, Pi * 0.5f, 0.01f));
		Test.Assert(NodeFixtures.Near(bed.Last.Scale, 2.0f));

		d.InjectTouchUp(2, .(200.0f, 300.0f));
		Test.Assert(!d.IsGesturing);
		Test.Assert(bed.Seen.Back == "gestureend");
		Test.Assert(Near(bed.Last.Rotation, Pi * 0.5f, 0.01f));
		d.InjectTouchUp(1, .(200.0f, 100.0f));
		Test.Assert(!bed.Saw("click"));
	}

	[Test]
	public static void ATwoFingerPansTranslationIsInTheGUIsUnitsAtAnyScaleAndAnyTurnOfTheNode()
	{
		let bed = scope GestureBed(0);
		bed.Root.DisplayScale = 2.0f; // device pixels twice the root's units
		bed.Root.UpdateLayout();
		let d = bed.D;
		d.InjectTouchDown(1, .(300.0f, 300.0f));
		d.InjectTouchDown(2, .(400.0f, 300.0f));
		d.InjectTouchMove(1, .(340.0f, 260.0f));
		d.InjectTouchMove(2, .(440.0f, 260.0f));
		Test.Assert(NodeFixtures.Near(bed.Last.Translation.X, 20.0f)); // 40 device pixels: 20 units
		Test.Assert(NodeFixtures.Near(bed.Last.Translation.Y, -20.0f));
		Test.Assert(NodeFixtures.Near(bed.Last.Scale, 1.0f));
		d.InjectTouchUp(2, .(440.0f, 260.0f));
		d.InjectTouchUp(1, .(340.0f, 260.0f));

		// Turned a quarter by its last gesture, as a viewer turns its picture: a move across is still across.
		bed.Pad.RotationOrigin = .(150.0f, 150.0f); // about its middle: still under the fingers
		bed.Pad.Rotation = Pi * 0.5f;
		bed.Root.UpdateLayout();
		d.InjectTouchDown(1, .(300.0f, 300.0f));
		d.InjectTouchDown(2, .(400.0f, 300.0f));
		Test.Assert(d.IsGesturing);
		d.InjectTouchMove(1, .(340.0f, 300.0f));
		d.InjectTouchMove(2, .(440.0f, 300.0f));
		Test.Assert(NodeFixtures.Near(bed.Last.Translation.X, 20.0f));
		Test.Assert(Near(bed.Last.Translation.Y, 0.0f, 0.001f));
	}

	[Test]
	public static void OverANodeThatLeavesPinchZoomToTheGUIASecondFingerDoesNothing()
	{
		let bed = scope GestureBed(cTouchAuto);
		let d = bed.D;
		d.InjectTouchDown(1, .(150.0f, 200.0f));
		Test.Assert(!d.InjectTouchDown(2, .(250.0f, 200.0f)));
		Test.Assert(!d.IsGesturing);
		d.InjectTouchUp(2, .(250.0f, 200.0f));
		d.InjectTouchUp(1, .(150.0f, 200.0f));
		Test.Assert(bed.Saw("click")); // the first finger still taps
		Test.Assert(!bed.Saw("gesturestart"));
	}

	[Test]
	public static void OneCancelledOrWhoseNodeLeavesTheTreeEndsAsCancelled()
	{
		{
			let bed = scope GestureBed(0);
			let d = bed.D;
			d.InjectTouchDown(1, .(150.0f, 200.0f));
			d.InjectTouchDown(2, .(250.0f, 200.0f));
			d.CancelGesture(); // the platform took a finger back
			Test.Assert(!d.IsGesturing);
			Test.Assert(bed.Seen.Back == "gesturecancel");
		}
		{
			let bed = scope GestureBed(0);
			let d = bed.D;
			d.InjectTouchDown(1, .(150.0f, 200.0f));
			d.InjectTouchDown(2, .(250.0f, 200.0f));
			bed.Pad.RemoveFromParent();
			let before = bed.Seen.Count;
			d.InjectTouchMove(1, .(140.0f, 200.0f));
			Test.Assert(!d.IsGesturing);
			Test.Assert(bed.Seen.Count == before); // gone: it hears nothing more
		}
	}
}
