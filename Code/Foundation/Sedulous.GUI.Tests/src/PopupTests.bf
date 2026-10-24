using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A root that says when it goes.
class WatchedScene : SceneRoot
{
	public bool* Gone = null;

	public this(Sedulous.GUI.GUIContext gui) : base(gui)
	{
	}

	public ~this()
	{
		if (Gone != null)
			*Gone = true;
	}
}

/// Popups, the top layer: a popup stays in its owner's subtree yet draws and takes the pointer
/// above everything, unclipped; nesting comes from the tree; a press that closes an auto popup is
/// consumed; Escape reaches the focused widget first; a modal popup makes what is below it inert,
/// bindings included, while popups opened inside it work; focus comes back to what it was taken
/// from, or the nearest holder still there; placement flips, shrinks and clamps, and follows a
/// scrolled anchor; every close says why; a hint takes no pointer; input in another root closes
/// this one's light popups.
class PopupTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A new button at `at`, `size`, the last child of `parent`, held by the caller.
	private static Button NewButton(Node parent, Float2 at, Float2 size)
	{
		let b = new Button();
		b.Position = at;
		b.Size = size;
		parent.AddChild(b);
		return b;
	}

	/// A new button at `at`, 40 by 20.
	private static Button NewButton(Node parent, Float2 at) => NewButton(parent, at, .(40.0f, 20.0f));

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

	[Test]
	public static void APopupWhoseOldParentHeldTheOnlyReferenceToItSurvivesTheMoveToItsOwner()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let page = new Panel();
		defer page.ReleaseRef();
		root.AddChild(page);
		Node popup = null;
		{
			let made = new Panel();
			made.Size = .(80.0f, 40.0f);
			page.AddChild(made);
			popup = made;
			made.ReleaseRef(); // the page holds the only reference now
		}
		let owner = new Panel();
		defer owner.ReleaseRef();
		root.AddChild(owner);
		let d = root.EventDispatcher;
		d.OpenPopup(owner, popup, new PopupOptions());
		Test.Assert(d.IsPopupOpen(popup));
		Test.Assert(popup.Parent == owner);
		Test.Assert(page.ChildCount == 0);
	}

	[Test]
	public static void OneSizedByItsContentGrowsWhenItsContentDoesATooltipWhoseFontArrivesLate()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let popup = new Panel();
		defer popup.ReleaseRef();
		let content = new Panel();
		defer content.ReleaseRef();
		content.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(20.0f);
				s.Height = LayoutLength.Px(10.0f);
			});
		popup.AddChild(content);
		let d = root.EventDispatcher;
		let options = new PopupOptions();
		options.Kind = .Hint;
		options.AnchorRect = .(50.0f, 50.0f, 0.0f, 0.0f);
		options.HasAnchorRect = true;
		options.FitContent = true;
		d.OpenPopup(root, popup, options);
		root.UpdateLayout();
		Test.Assert(NodeFixtures.Near(popup.Size.X, 20.0f));
		content.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(150.0f); }); // what it shows grew
		root.UpdateLayout();
		Test.Assert(NodeFixtures.Near(popup.Size.X, 150.0f));
	}

	[Test]
	public static void OneOpenThatGoesBackHomeOnCloseDoesNotKeepItsRootAlive()
	{
		// Its home is the root itself, which owns the dispatcher holding the entry: a strong
		// reference there would make a cycle, and a GUI closed with the popup open would never be
		// freed.
		bool gone = false;
		let context = new GUIContext();
		let root = new WatchedScene(context);
		context.ReleaseRef(); // the root's keeps it
		root.Gone = &gone;
		let screen = new Panel();
		defer screen.ReleaseRef();
		root.AddChild(screen);
		let options = new PopupOptions();
		options.Kind = .Manual;
		options.Modal = true;
		options.ReturnHome = true;
		root.EventDispatcher.OpenPopup(root, screen, options);
		Test.Assert(root.EventDispatcher.IsPopupOpen(screen));
		root.ReleaseRef();
		Test.Assert(gone);
	}

	[Test]
	public static void AnOpenPopupInheritsItsOwnersStylesWhereItIsInTheTree()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let owner = new UIWidget();
		defer owner.ReleaseRef();
		owner.AddClass("warm");
		root.AddChild(owner);
		let popup = new Label();
		defer popup.ReleaseRef();
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, ".warm { color: #ff8000; } .warm > label { padding: 4px; }");
		root.EventDispatcher.OpenPopup(owner, popup, SceneFixtures.At(.(10.0f, 10.0f)));
		styles.ApplyTree(root);
		Test.Assert(Near(popup.TextColor.R, 1.0f));
		Test.Assert(Near(popup.TextColor.G, (float)0x80 / 255.0f));
		Test.Assert(Near(popup.Padding.Left, 4.0f)); // `.warm > label` matches it in place
	}

	[Test]
	public static void APressOutsideClosesThoseAboveTheOneItIsInAndIsConsumedWithItsRelease()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let opener = NewButton(root, .(300.0f, 250.0f));
		defer opener.ReleaseRef();
		int clicks = 0;
		opener.SetOnClick(new [&] () => { clicks++; });
		let a = SceneFixtures.NewProbe(null, "a", .(0.0f, 0.0f), .(100.0f, 100.0f));
		defer a.ReleaseRef();
		let inner = SceneFixtures.NewProbe(a, "inner", .(0.0f, 0.0f), .(100.0f, 20.0f));
		defer inner.ReleaseRef();
		let b = SceneFixtures.NewProbe(null, "b", .(0.0f, 0.0f), .(50.0f, 50.0f));
		defer b.ReleaseRef();
		d.OpenPopup(opener, a, SceneFixtures.At(.(10.0f, 10.0f)));
		d.OpenPopup(inner, b, SceneFixtures.At(.(150.0f, 10.0f)));
		// A press in a closes b only, and goes on to a.
		int pressedA = 0;
		a.AddEventListener(.MouseDown, new [&] (e) => { pressedA++; });
		d.InjectMouseDown(.(50.0f, 80.0f), .Left);
		Test.Assert(pressedA == 1);
		Test.Assert(!d.IsPopupOpen(b));
		Test.Assert(d.IsPopupOpen(a));
		d.InjectMouseUp(.(50.0f, 80.0f), .Left);
		// The opener pressed again: a closes, and the press does nothing more (no reopening click).
		Test.Assert(clicks == 0); // the click in a, bubbling to its opener, is not a click on the opener
		SceneFixtures.Click(d, .(310.0f, 260.0f));
		Test.Assert(!d.IsPopupOpen(a));
		Test.Assert(clicks == 0);
		SceneFixtures.Click(d, .(310.0f, 260.0f)); // nothing open: an ordinary click
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void EscapeGoesToTheFocusedWidgetFirstUntakenItClosesTheTopmostAutoPopup()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let taker = NewButton(root, .(0.0f, 0.0f));
		defer taker.ReleaseRef();
		bool take = true;
		taker.AddEventListener(.KeyDown, new [&] (e) =>
			{
				if (take)
					e.Handled = true;
			});
		d.FocusNode = taker;
		let popup = SceneFixtures.NewProbe(null, "popup", .(0.0f, 0.0f), .(50.0f, 50.0f));
		defer popup.ReleaseRef();
		PopupCloseReason why = .Code;
		let o = SceneFixtures.At(.(100.0f, 100.0f));
		o.OnClosed = new [&] (reason) => { why = reason; };
		d.OpenPopup(root, popup, o);
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(d.IsPopupOpen(popup)); // the focused widget took it
		take = false;
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!d.IsPopupOpen(popup));
		Test.Assert(why == .Escape);
	}

	[Test]
	public static void AModalMakesWhatIsBelowItInertBindingsTooWhilePopupsOpenedInItWork()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let behind = NewButton(root, .(0.0f, 0.0f));
		defer behind.ReleaseRef();
		int behindClicks = 0;
		behind.SetOnClick(new [&] () => { behindClicks++; });
		int rootCommands = 0;
		root.OnCommand("save", new [&] (command) => { rootCommands++; });
		Test.Assert(root.Context.Keymap.Bind("ctrl-s", "save"));
		d.FocusNode = behind;

		let dialog = new UIWidget();
		defer dialog.ReleaseRef();
		dialog.Size = .(200.0f, 150.0f);
		dialog.Position = .(100.0f, 100.0f);
		let inside = NewButton(dialog, .(10.0f, 10.0f));
		defer inside.ReleaseRef();
		let modal = new PopupOptions();
		modal.Kind = .Manual;
		modal.Modal = true;
		d.OpenPopup(root, dialog, modal);
		Test.Assert(inside.IsFocused); // focus moved in

		SceneFixtures.Click(d, .(10.0f, 10.0f));
		Test.Assert(behindClicks == 0); // inert
		Test.Assert(d.IsPopupOpen(dialog)); // and a dialog is not light-dismissed
		d.InjectKeyDown((uint32)KeyCode.S, KeyModCtrl);
		Test.Assert(rootCommands == 0); // the root's binding does not reach past the modal
		Test.Assert(!root.IsCommandAvailable("save"));

		// A list opened from inside the dialog stacks above it and takes presses; a press elsewhere
		// in the dialog closes it.
		let list = SceneFixtures.NewProbe(null, "list", .(0.0f, 0.0f), .(60.0f, 60.0f));
		defer list.ReleaseRef();
		let drop = new PopupOptions();
		drop.Anchor = inside;
		d.OpenPopup(inside, list, drop);
		int listPresses = 0;
		list.AddEventListener(.MouseDown, new [&] (e) => { listPresses++; });
		SceneFixtures.Click(d, .(130.0f, 140.0f)); // in the list, below the button
		Test.Assert(listPresses == 1);
		SceneFixtures.Click(d, .(250.0f, 200.0f)); // in the dialog, outside the list
		Test.Assert(!d.IsPopupOpen(list));
		Test.Assert(d.IsPopupOpen(dialog));

		d.ClosePopup(dialog);
		Test.Assert(behind.IsFocused); // focus back
		d.InjectKeyDown((uint32)KeyCode.S, KeyModCtrl);
		Test.Assert(rootCommands == 1);
	}

	[Test]
	public static void FocusComesBackToWhatItWasTakenFromElseTheNearestHolderStillThereAndEnabled()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let holder = NewButton(root, .(0.0f, 0.0f), .(200.0f, 100.0f));
		defer holder.ReleaseRef();
		let start = NewButton(holder, .(10.0f, 10.0f));
		defer start.ReleaseRef();
		void OpenFocusing(Node popup)
		{
			let o = SceneFixtures.At(.(250.0f, 150.0f));
			o.TakesFocus = true;
			d.OpenPopup(root, popup, o);
		}
		let popup = new UIWidget();
		defer popup.ReleaseRef();
		popup.Size = .(100.0f, 60.0f);
		let field = NewButton(popup, .(5.0f, 5.0f));
		defer field.ReleaseRef();

		d.FocusNode = start;
		OpenFocusing(popup);
		Test.Assert(field.IsFocused);
		d.ClosePopup(popup);
		Test.Assert(start.IsFocused);

		OpenFocusing(popup);
		start.Enabled = false; // what it came from is disabled meanwhile
		d.ClosePopup(popup);
		Test.Assert(holder.IsFocused); // the nearest holder that can take it
		start.Enabled = true;

		d.FocusNode = start;
		OpenFocusing(popup);
		holder.RemoveChild(start); // gone meanwhile
		d.ClosePopup(popup);
		Test.Assert(holder.IsFocused);

		// Focus that moved out of the popup meanwhile is left where it went.
		d.FocusNode = holder;
		OpenFocusing(popup);
		let elsewhere = NewButton(root, .(300.0f, 0.0f));
		defer elsewhere.ReleaseRef();
		d.FocusNode = elsewhere;
		d.ClosePopup(popup);
		Test.Assert(elsewhere.IsFocused);
	}

	[Test]
	public static void OneOpenedInARightToLeftPartOfAPagePlacesItselfInThatDirection()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f); // the page runs left to right; a part of it right to left
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let part = new UIWidget();
		defer part.ReleaseRef();
		part.Size = .(400.0f, 300.0f);
		part.SetLayoutDirection(.RightToLeft);
		root.AddChild(part);
		let field = NewButton(part, .(200.0f, 10.0f), .(150.0f, 20.0f));
		defer field.ReleaseRef();
		root.UpdateLayout();
		let fieldAt = field.ConvertToRootSpace(.(0.0f, 0.0f));

		// Below its anchor, the right edges lined up (a combo box's list).
		let list = SceneFixtures.NewProbe(null, "list", .(0.0f, 0.0f), .(100.0f, 80.0f));
		defer list.ReleaseRef();
		let below = new PopupOptions();
		below.Anchor = field;
		d.OpenPopup(field, list, below);
		root.UpdateLayout();
		let listAt = list.ConvertToRootSpace(.(0.0f, 0.0f));
		Test.Assert(Near(listAt.X + 100.0f, fieldAt.X + 150.0f));
		Test.Assert(Near(listAt.Y, fieldAt.Y + 20.0f));
		d.ClosePopup(list);

		// At a point, owned there: toward the left of it (a context menu).
		let menu = SceneFixtures.NewProbe(null, "menu", .(0.0f, 0.0f), .(100.0f, 80.0f));
		defer menu.ReleaseRef();
		d.OpenPopup(part, menu, SceneFixtures.At(.(300.0f, 50.0f)));
		root.UpdateLayout();
		Test.Assert(Near(menu.ConvertToRootSpace(.(0.0f, 0.0f)).X, 200.0f));
	}

	[Test]
	public static void AnAnchoredPopupFollowsItsAnchorWhenWhatHoldsItScrolls()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let scroller = new UIWidget();
		defer scroller.ReleaseRef();
		scroller.Size = .(200.0f, 200.0f);
		scroller.EditLayoutStyle(scope (s) =>
			{
				s.OverflowY = .Scroll;
				s.Direction = .Column;
			});
		root.AddChild(scroller);
		let filler = new UIWidget();
		defer filler.ReleaseRef();
		filler.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(100.0f); });
		scroller.AddChild(filler);
		let anchor = new Button();
		defer anchor.ReleaseRef();
		anchor.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(20.0f); });
		scroller.AddChild(anchor);
		let rest = new UIWidget();
		defer rest.ReleaseRef();
		rest.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(400.0f); });
		scroller.AddChild(rest);
		root.UpdateLayout();
		let popup = SceneFixtures.NewProbe(null, "popup", .(0.0f, 0.0f), .(80.0f, 40.0f));
		defer popup.ReleaseRef();
		let o = new PopupOptions();
		o.Anchor = anchor;
		root.EventDispatcher.OpenPopup(anchor, popup, o);
		Test.Assert(Near(popup.Position.Y, 120.0f));
		scroller.ScrollOffset = .(0.0f, 50.0f);
		root.UpdateLayout();
		Test.Assert(Near(popup.Position.Y, 70.0f));
	}

	[Test]
	public static void OpeningAndClosingAreToggleEventsAtThePopupWhichReachItsOwner()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let owner = NewButton(root, .(0.0f, 0.0f));
		defer owner.ReleaseRef();
		let popup = SceneFixtures.NewProbe(null, "popup", .(0.0f, 0.0f), .(50.0f, 50.0f));
		defer popup.ReleaseRef();
		let heard = scope List<String>();
		defer { ClearAndDeleteItems!(heard); }
		owner.AddEventListener(.Toggle, new [&] (e) =>
			{
				let t = (ToggleEvent)e;
				heard.Add(new String(t.Open ? "open" : PopupCloseReasonName(t.Reason)));
			});
		d.OpenPopup(owner, popup, SceneFixtures.At(.(100.0f, 100.0f)));
		d.InjectMouseDown(.(350.0f, 250.0f), .Left);
		Test.Assert(heard.Count == 2);
		Test.Assert(heard[0] == "open");
		Test.Assert(heard[1] == "outside-press");
	}

	[Test]
	public static void OnePlacedAgainstARectangleFollowsItWhenItsOwnerMovesIt()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let popup = new Panel();
		defer popup.ReleaseRef();
		popup.Size = .(60.0f, 40.0f);
		d.OpenPopup(root, popup, SceneFixtures.At(.(50.0f, 50.0f), .Manual));
		Test.Assert(Near(popup.Position.X, 50.0f));
		// A code editor's caret, scrolled: its list goes with it.
		Test.Assert(d.SetPopupAnchorRect(popup, .(120.0f, 80.0f, 0.0f, 16.0f)));
		Test.Assert(Near(popup.Position.X, 120.0f));
		Test.Assert(Near(popup.Position.Y, 96.0f)); // below it
		d.ClosePopup(popup);
		Test.Assert(!d.SetPopupAnchorRect(popup, .(0.0f, 0.0f, 0.0f, 0.0f))); // not open
	}
}
