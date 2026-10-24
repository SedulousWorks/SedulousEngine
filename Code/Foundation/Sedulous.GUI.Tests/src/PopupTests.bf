using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Popups, the top layer: a popup stays in its owner's subtree yet draws and takes the pointer
/// above everything, unclipped; nesting comes from the tree; placement flips, shrinks and clamps;
/// a hint takes no pointer; input in another root closes this one's light popups.
class PopupTests
{
	private static PopupPlacement Placement(PopupSide side, PopupAlign align, float gap, bool shrink)
	{
		var placement = PopupPlacement();
		placement.Side = side;
		placement.Align = align;
		placement.Gap = gap;
		placement.Shrink = shrink;
		return placement;
	}

	[Test]
	public static void AnOpenPopupDrawsAfterTheWholeTreeAndTakesThePointerFirstUnclippedByItsOwner()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let owner = new UIWidget();
		defer owner.ReleaseRef();
		owner.Size = .(50.0f, 50.0f);
		owner.ClipChildren = true; // a clipping owner (a scroller)
		root.AddChild(owner);
		let later = SceneFixtures.NewProbe(root, "later", .(0.0f, 0.0f), .(400.0f, 300.0f)); // over everything
		defer later.ReleaseRef();
		let popup = SceneFixtures.NewProbe(null, "popup", .(0.0f, 0.0f), .(100.0f, 80.0f));
		defer popup.ReleaseRef();
		d.OpenPopup(owner, popup, SceneFixtures.At(.(40.0f, 40.0f)));
		Test.Assert(popup.Parent == owner);
		Test.Assert(NodeFixtures.Near(popup.Position.X, 40.0f)); // in the root's space
		SceneFixtures.DrawRoot(root);
		Test.Assert(SceneFixtures.DrawLog.Count == 2);
		Test.Assert(SceneFixtures.DrawLog[0] == "later");
		Test.Assert(SceneFixtures.DrawLog[1] == "popup"); // last, over the later sibling
		// Outside its clipping owner, over the later sibling: the pointer finds it.
		int pressed = 0;
		popup.AddEventListener(.MouseDown, new [&](e) => { pressed++; });
		d.InjectMouseDown(.(120.0f, 100.0f), .Left);
		Test.Assert(pressed == 1);
		// Its events reach its owner on their way up.
		int bubbled = 0;
		owner.AddEventListener(.MouseDown, new [&](e) => { bubbled++; });
		d.InjectMouseUp(.(120.0f, 100.0f), .Left);
		d.InjectMouseDown(.(120.0f, 100.0f), .Left);
		Test.Assert(bubbled == 1);
	}

	[Test]
	public static void NestingComesFromTheTreeOpeningAnotherClosesWhatDoesNotHoldItClosingTakesItsChildren()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let a = SceneFixtures.NewProbe(null, "a", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer a.ReleaseRef();
		let item = SceneFixtures.NewProbe(a, "item", .(0.0f, 0.0f), .(100.0f, 20.0f));
		defer item.ReleaseRef();
		let b = SceneFixtures.NewProbe(null, "b", .(0.0f, 0.0f), .(80.0f, 80.0f));
		defer b.ReleaseRef();
		let c = SceneFixtures.NewProbe(null, "c", .(0.0f, 0.0f), .(80.0f, 80.0f));
		defer c.ReleaseRef();
		let closed = scope List<String>();
		defer { ClearAndDeleteItems!(closed); }
		PopupOptions Watch(PopupOptions o, StringView name)
		{
			let named = new String(name);
			o.OnClosed = new (reason) => // by value: the list's reference, and the name it owns
				{
					let entry = new String(named);
					entry.Append(":");
					entry.Append(PopupCloseReasonName(reason));
					closed.Add(entry);
				}
				~
				{
					delete named;
				};
			return o;
		}
		d.OpenPopup(root, a, Watch(SceneFixtures.At(.(10.0f, 10.0f)), "a"));
		d.OpenPopup(item, b, Watch(SceneFixtures.At(.(110.0f, 10.0f)), "b")); // inside a: a stays
		Test.Assert(d.PopupCount == 2);
		d.OpenPopup(root, c, Watch(SceneFixtures.At(.(200.0f, 150.0f)), "c")); // holds neither: both go
		Test.Assert(closed.Count == 2);
		Test.Assert(closed[0] == "b:replaced"); // the inner first
		Test.Assert(closed[1] == "a:replaced");
		Test.Assert(d.PopupCount == 1);

		ClearAndDeleteItems!(closed);
		d.ClosePopup(c);
		d.OpenPopup(root, a, Watch(SceneFixtures.At(.(10.0f, 10.0f)), "a"));
		d.OpenPopup(item, b, Watch(SceneFixtures.At(.(110.0f, 10.0f)), "b"));
		ClearAndDeleteItems!(closed);
		Test.Assert(d.ClosePopup(a));
		Test.Assert(closed.Count == 2);
		Test.Assert(closed[0] == "b:code");
		Test.Assert(closed[1] == "a:code");
		Test.Assert(a.Parent == null); // a closed popup leaves the tree
	}

	[Test]
	public static void PlacementFlipsShrinksAndClampsAtEveryEdge()
	{
		let bounds = Rect(0.0f, 0.0f, 400.0f, 300.0f);
		// Below fits.
		var p = PlacePopup(.(10.0f, 10.0f, 50.0f, 20.0f), .(100.0f, 80.0f), bounds, .(), false);
		Test.Assert(p.Side == .Below);
		Test.Assert(NodeFixtures.Near(p.Position.Y, 30.0f));
		// Near the bottom: flipped above.
		p = PlacePopup(.(10.0f, 260.0f, 50.0f, 20.0f), .(100.0f, 80.0f), bounds, .(), false);
		Test.Assert(p.Side == .Above);
		Test.Assert(NodeFixtures.Near(p.Position.Y, 180.0f));
		// Too tall for either side: the larger side, shrunk to it.
		p = PlacePopup(.(10.0f, 100.0f, 50.0f, 20.0f), .(100.0f, 400.0f), bounds, .(), false);
		Test.Assert(p.Side == .Below);
		Test.Assert(NodeFixtures.Near(p.Size.Y, 180.0f));
		Test.Assert(p.Position.Y + p.Size.Y <= 300.0f + 0.01f);
		// Past the right edge: slid back in.
		p = PlacePopup(.(380.0f, 10.0f, 20.0f, 20.0f), .(100.0f, 50.0f), bounds, .(), false);
		Test.Assert(NodeFixtures.Near(p.Position.X, 300.0f));
		// A submenu at the right edge flips to its item's inline start; at the bottom it slides up.
		p = PlacePopup(.(300.0f, 250.0f, 80.0f, 20.0f), .(120.0f, 100.0f), bounds, Placement(.InlineEnd, .Start, 0.0f, true), false);
		Test.Assert(p.Side == .InlineStart);
		Test.Assert(NodeFixtures.Near(p.Position.X, 180.0f));
		Test.Assert(NodeFixtures.Near(p.Position.Y, 200.0f));
		// Centred under its anchor, past the left edge: clamped to it.
		p = PlacePopup(.(0.0f, 10.0f, 20.0f, 20.0f), .(100.0f, 50.0f), bounds, Placement(.Below, .Center, 4.0f, true), false);
		Test.Assert(NodeFixtures.Near(p.Position.X, 0.0f));
		Test.Assert(NodeFixtures.Near(p.Position.Y, 34.0f));
	}

	[Test]
	public static void InRightToLeftTheInlineSidesAndTheStartAlignmentMirror()
	{
		let bounds = Rect(0.0f, 0.0f, 400.0f, 300.0f);
		// A dropdown's start is the right: the right edges line up.
		var p = PlacePopup(.(200.0f, 10.0f, 150.0f, 20.0f), .(100.0f, 80.0f), bounds, .(), true);
		Test.Assert(p.Side == .Below);
		Test.Assert(NodeFixtures.Near(p.Position.X, 250.0f));
		// End lines up the left edges; centred is the same either way.
		p = PlacePopup(.(200.0f, 10.0f, 150.0f, 20.0f), .(100.0f, 80.0f), bounds, Placement(.Below, .End, 0.0f, true), true);
		Test.Assert(NodeFixtures.Near(p.Position.X, 200.0f));
		p = PlacePopup(.(200.0f, 10.0f, 150.0f, 20.0f), .(100.0f, 80.0f), bounds, Placement(.Below, .Center, 0.0f, true), true);
		Test.Assert(NodeFixtures.Near(p.Position.X, 225.0f));
		// A submenu goes to its item's inline end, the left, its top with the item's.
		p = PlacePopup(.(200.0f, 40.0f, 80.0f, 20.0f), .(120.0f, 100.0f), bounds, Placement(.InlineEnd, .Start, 0.0f, true), true);
		Test.Assert(p.Side == .InlineEnd);
		Test.Assert(NodeFixtures.Near(p.Position.X, 80.0f));
		Test.Assert(NodeFixtures.Near(p.Position.Y, 40.0f));
		// At the left edge it flips to the inline start, the right.
		p = PlacePopup(.(20.0f, 40.0f, 80.0f, 20.0f), .(120.0f, 100.0f), bounds, Placement(.InlineEnd, .Start, 0.0f, true), true);
		Test.Assert(p.Side == .InlineStart);
		Test.Assert(NodeFixtures.Near(p.Position.X, 100.0f));
		// A context menu at a point opens toward the left of it.
		p = PlaceAtPoint(.(300.0f, 50.0f), .(100.0f, 80.0f), bounds, true);
		Test.Assert(NodeFixtures.Near(p.Position.X, 200.0f));
		Test.Assert(NodeFixtures.Near(p.Position.Y, 50.0f));
	}

	[Test]
	public static void AHintNeverTakesThePointerAndClosesOnAnyPressOrKeyLeavingTheOthers()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let menu = SceneFixtures.NewProbe(null, "menu", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer menu.ReleaseRef();
		d.OpenPopup(root, menu, SceneFixtures.At(.(0.0f, 0.0f)));
		let tip = SceneFixtures.NewProbe(null, "tip", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer tip.ReleaseRef();
		d.OpenPopup(root, tip, SceneFixtures.At(.(0.0f, 0.0f), .Hint));
		Test.Assert(d.IsPopupOpen(menu)); // a hint closes no one
		int menuPresses = 0;
		menu.AddEventListener(.MouseDown, new [&](e) => { menuPresses++; });
		d.InjectMouseDown(.(50.0f, 50.0f), .Left); // through the hint
		Test.Assert(menuPresses == 1);
		Test.Assert(!d.IsPopupOpen(tip));
		Test.Assert(d.IsPopupOpen(menu));
	}

	[Test]
	public static void InputInAnotherRootOfTheGUIClosesThisRootsLightPopupsNotItsDialogs()
	{
		let gui = new GUIContext();
		defer gui.ReleaseRef();
		let a = new SceneRoot(gui);
		defer a.ReleaseRef();
		let b = new SceneRoot(gui);
		defer b.ReleaseRef();
		a.Size = .(200.0f, 200.0f);
		b.Size = .(200.0f, 200.0f);
		let menu = SceneFixtures.NewProbe(null, "menu", .(0.0f, 0.0f), .(50.0f, 50.0f));
		defer menu.ReleaseRef();
		a.EventDispatcher.OpenPopup(a, menu, SceneFixtures.At(.(10.0f, 10.0f)));
		let dialog = SceneFixtures.NewProbe(null, "dialog", .(0.0f, 0.0f), .(50.0f, 50.0f));
		defer dialog.ReleaseRef();
		a.EventDispatcher.OpenPopup(a, dialog, SceneFixtures.At(.(100.0f, 100.0f), .Manual));
		let menu2 = SceneFixtures.NewProbe(null, "menu2", .(0.0f, 0.0f), .(50.0f, 50.0f));
		defer menu2.ReleaseRef();
		a.EventDispatcher.OpenPopup(a, menu2, SceneFixtures.At(.(60.0f, 10.0f)));
		b.EventDispatcher.InjectMouseDown(.(5.0f, 5.0f), .Left);
		Test.Assert(!a.EventDispatcher.IsPopupOpen(menu2)); // above the dialog: closed
		Test.Assert(a.EventDispatcher.IsPopupOpen(dialog));
		Test.Assert(a.EventDispatcher.IsPopupOpen(menu)); // below the dialog: kept
	}
}
