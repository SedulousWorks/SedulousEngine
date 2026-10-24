using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A root 400 by 300 holding a panel at (20, 20), 300 by 200, with three tab stops in a row. The
/// root (and its tree) goes with it.
class OverlayBed
{
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 300.0f) ~ _.ReleaseRef();
	public UIWidget Panel = new .() ~ _.ReleaseRef();
	public List<UIWidget> Stops = new .() ~ { for (let s in _) s.ReleaseRef(); delete _; };

	public this()
	{
		Panel.Tag = "panel";
		Panel.Position = .(20.0f, 20.0f);
		Panel.Size = .(300.0f, 200.0f);
		Root.AddChild(Panel);
		for (int i = 0; i < 3; i++)
		{
			let w = new UIWidget();
			w.Tag = "stop";
			w.TabFocusable = true;
			w.Position = .(10.0f + 60.0f * (float)i, 10.0f);
			w.Size = .(50.0f, 20.0f);
			Panel.AddChild(w);
			Stops.Add(w);
		}
		Root.UpdateLayout();
	}

	/// The vertices a draw makes with `overlay` on.
	public int Draw(DebugOverlay overlay)
	{
		Root.DebugOverlay = overlay;
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		Root.DrawFrame(dc);
		let batch = canvas.GetBatch();
		return batch.Vertices.Count + batch.BoxVertices.Count;
	}

	public EventDispatcher D => Root.EventDispatcher;
}

/// The debug overlay: what the input half reads (the tab stops in Tab's order, the focus, the node
/// under the pointer) and that it draws each part only when asked.
class DebugOverlayTests
{
	[Test]
	public static void TheTabStopsComeInTabsOrderAndTheOverlayNumbersAndJoinsThem()
	{
		let bed = scope OverlayBed();
		let d = bed.D;
		let stops = scope List<Node>();
		d.TabStops(stops);
		Test.Assert(stops.Count == 3);
		for (int i = 0; i < 3; i++)
			Test.Assert(stops[i] == bed.Stops[i]);
		bed.Stops[1].TabFocusable = false; // a stop no longer: not numbered
		stops.Clear();
		d.TabStops(stops);
		Test.Assert(stops.Count == 2);
		bed.Stops[1].TabFocusable = true;

		let none = bed.Draw(.());
		var tabs = DebugOverlay();
		tabs.TabOrder = true;
		Test.Assert(bed.Draw(tabs) > none);
	}

	[Test]
	public static void TheFocusPathAndThePointerDrawOnlyWithSomethingFocusedAndSomethingUnderThePointer()
	{
		let bed = scope OverlayBed();
		let d = bed.D;
		var focus = DebugOverlay();
		focus.FocusPath = true;
		let none = bed.Draw(.());
		Test.Assert(bed.Draw(focus) == none); // nothing focused
		d.FocusNode = bed.Stops[2];
		Test.Assert(bed.Draw(focus) > none);

		var pointer = DebugOverlay();
		pointer.Pointer = true;
		Test.Assert(bed.Draw(pointer) == none);
		d.InjectMouseMove(.(45.0f, 35.0f)); // over the first stop
		Test.Assert(d.OverNode == bed.Stops[0]);
		Test.Assert(bed.Draw(pointer) > none);
	}

	[Test]
	public static void TheLayoutHalfAndTheInputHalfAreSeparate()
	{
		let layout = DebugOverlay.Layout;
		Test.Assert(layout.AnyLayout);
		Test.Assert(!layout.AnyInput);
		let input = DebugOverlay.Input;
		Test.Assert(input.AnyInput);
		Test.Assert(!input.AnyLayout);
		Test.Assert(!DebugOverlay().Any);
	}

	[Test]
	public static void AWidgetUnderANodeOutOfTheLayoutIsNoTabStopAndTakesNoArrowMove()
	{
		let bed = scope OverlayBed();
		let d = bed.D;
		bed.Stops[1].Displayed = false; // a page switched away
		let stops = scope List<Node>();
		d.TabStops(stops);
		Test.Assert(stops.Count == 2);
		Test.Assert(stops[0] == bed.Stops[0]);
		Test.Assert(stops[1] == bed.Stops[2]);
		d.FocusNode = bed.Stops[0];
		Test.Assert(d.MoveFocus(.Right));
		Test.Assert(d.FocusNode == bed.Stops[2]); // past the one out of the layout
		bed.Panel.Displayed = false;
		stops.Clear();
		d.TabStops(stops);
		Test.Assert(stops.IsEmpty);
	}

	[Test]
	public static void AnArrowMoveKeepsWhatItWeighedTheOneChosenThoseBeatenThoseBehind()
	{
		let bed = scope OverlayBed();
		let d = bed.D;
		Test.Assert(!d.LastNavigation.Any);
		d.FocusNode = bed.Stops[0];
		Test.Assert(d.MoveFocus(.Right));
		let trace = d.LastNavigation;
		Test.Assert(trace.Any);
		Test.Assert(trace.Direction == .Right);
		Test.Assert(NodeFixtures.Near(trace.From.X, 30.0f)); // the first stop, in the world
		Test.Assert(trace.Candidates.Count == 2); // the other two
		int chosen = 0;
		int beaten = 0;
		for (let c in trace.Candidates)
		{
			chosen += (c.Verdict == .Chosen) ? 1 : 0;
			beaten += (c.Verdict == .Beaten) ? 1 : 0;
			if (c.Verdict == .Chosen)
				Test.Assert(NodeFixtures.Near(c.Bounds.X, 90.0f)); // the nearest, the second stop
		}
		Test.Assert(chosen == 1);
		Test.Assert(beaten == 1);

		// Back left from the second: the first chosen, the third behind.
		Test.Assert(d.MoveFocus(.Left));
		int behind = 0;
		for (let c in d.LastNavigation.Candidates)
			behind += (c.Verdict == .Behind) ? 1 : 0;
		Test.Assert(behind == 1);

		let none = bed.Draw(.());
		var nav = DebugOverlay();
		nav.Navigation = true;
		Test.Assert(bed.Draw(nav) > none);
	}

	[Test]
	public static void ANodeThatInvalidatedItselfFlashesOnceAndTheFlashesKeepFramesComingWhileTheyFade()
	{
		let bed = scope OverlayBed();
		var flash = DebugOverlay();
		flash.RedrawFlash = true;
		bed.Draw(.()); // drawn once: nothing new since
		Test.Assert(bed.Root.RedrawFlashCount == 0);

		bed.Draw(flash); // turning it on invalidates the root, which never flashes
		Test.Assert(bed.Root.RedrawFlashCount == 0);
		bed.Stops[1].Alpha = 0.5f; // it alone, not the panel holding it
		bed.Draw(flash);
		Test.Assert(bed.Root.RedrawFlashCount == 1);
		Test.Assert(bed.Root.NeedsFrame());
		Test.Assert(bed.Root.LastFrameStats.Reasons.Overlay);
		bed.Draw(flash); // nothing changed: no new flash (the old one still fades)
		Test.Assert(bed.Root.RedrawFlashCount == 1);

		bed.Stops[0].Alpha = 0.5f;
		bed.Draw(.()); // off: nothing recorded
		Test.Assert(bed.Root.RedrawFlashCount == 1);
	}
}
