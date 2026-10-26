using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// EventDispatcher: hover enter/leave, click, focus (click and programmatic), key and text routing
/// to the focus node, and interaction-ref cleanup. Input is injected as abstract events (the shell
/// bridge's job), hit-tested via the tree's OverFind.
class EventDispatcherTests
{
	[Test]
	public static void HoverEnterLeaveTracksTheNodeUnderTheCursor()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = SceneFixtures.NewNode(10.0f, 10.0f, 50.0f, 50.0f, root);
		defer child.ReleaseRef();
		let d = root.EventDispatcher;

		int enter = 0;
		int leave = 0;
		child.AddEventListener(.MouseEnter, new [&](e) => { enter++; });
		child.AddEventListener(.MouseLeave, new [&](e) => { leave++; });

		d.InjectMouseMove(.(20.0f, 20.0f)); // over child
		Test.Assert(d.OverNode == child);
		Test.Assert(enter == 1);
		Test.Assert(leave == 0);

		d.InjectMouseMove(.(120.0f, 120.0f)); // off child, over root
		Test.Assert(d.OverNode == root);
		Test.Assert(leave == 1);
	}

	[Test]
	public static void PressAndReleaseOnTheSameNodeIsAClickAndFocusesIt()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = SceneFixtures.NewNode(10.0f, 10.0f, 50.0f, 50.0f);
		defer child.ReleaseRef();
		child.TabFocusable = true; // a widget that takes focus
		root.AddChild(child);
		let d = root.EventDispatcher;

		int clicks = 0;
		child.AddEventListener(.MouseClick, new [&](e) => { clicks++; });

		d.InjectMouseDown(.(20.0f, 20.0f), .Left);
		d.InjectMouseUp(.(20.0f, 20.0f), .Left);
		Test.Assert(clicks == 1);
		Test.Assert(d.FocusNode == child);
		Test.Assert(child.IsFocused);

		// A click on what does not take focus (a backdrop) clears it, still delivering the click;
		// one on a child of a focusable widget focuses that widget.
		let backdrop = SceneFixtures.NewNode(100.0f, 100.0f, 50.0f, 50.0f, root);
		defer backdrop.ReleaseRef();
		int backdropClicks = 0;
		backdrop.AddEventListener(.MouseClick, new [&](e) => { backdropClicks++; });
		d.InjectMouseDown(.(120.0f, 120.0f), .Left);
		d.InjectMouseUp(.(120.0f, 120.0f), .Left);
		Test.Assert(backdropClicks == 1);
		Test.Assert(d.FocusNode == null);
		let inner = SceneFixtures.NewNode(5.0f, 5.0f, 10.0f, 10.0f, child);
		defer inner.ReleaseRef();
		d.InjectMouseDown(.(20.0f, 20.0f), .Left);
		Test.Assert(d.FocusNode == child);
	}

	[Test]
	public static void APressInANodeThatKeepsTheFocusLeavesItWhereItIs()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let field = SceneFixtures.NewNode(10.0f, 10.0f, 50.0f, 50.0f);
		defer field.ReleaseRef();
		field.TabFocusable = true;
		root.AddChild(field);
		let list = SceneFixtures.NewNode(100.0f, 100.0f, 80.0f, 80.0f);
		defer list.ReleaseRef();
		list.KeepsFocus = true; // a completion list
		root.AddChild(list);
		let row = SceneFixtures.NewNode(0.0f, 0.0f, 80.0f, 20.0f, list);
		defer row.ReleaseRef();
		let d = root.EventDispatcher;
		field.RequestFocus();
		Test.Assert(d.FocusNode == field);
		int clicks = 0;
		row.AddEventListener(.MouseClick, new [&](e) => { clicks++; });
		d.InjectMouseDown(.(110.0f, 105.0f), .Left);
		d.InjectMouseUp(.(110.0f, 105.0f), .Left);
		Test.Assert(clicks == 1);
		Test.Assert(d.FocusNode == field); // kept
		// A focusable widget inside it still takes the focus.
		let button = SceneFixtures.NewNode(0.0f, 40.0f, 80.0f, 20.0f);
		defer button.ReleaseRef();
		button.TabFocusable = true;
		list.AddChild(button);
		d.InjectMouseDown(.(110.0f, 145.0f), .Left);
		Test.Assert(d.FocusNode == button);
	}

	[Test]
	public static void MouseEventPayloadIsAccessibleByACast()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;

		Float2 seen = .(-1.0f, -1.0f);
		root.AddEventListener(.MouseMove, new [&](e) => { seen = ((MouseEvent)e).Position; });

		d.InjectMouseMove(.(33.0f, 44.0f));
		Test.Assert(NodeFixtures.Near(seen.X, 33.0f));
		Test.Assert(NodeFixtures.Near(seen.Y, 44.0f));
	}

	[Test]
	public static void KeyAndTextRouteToTheFocusNode()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = SceneFixtures.NewNode(0.0f, 0.0f, 50.0f, 50.0f, root);
		defer child.ReleaseRef();
		let d = root.EventDispatcher;

		int keys = 0;
		int texts = 0;
		let lastText = scope String();
		child.AddEventListener(.KeyDown, new [&](e) => { keys++; });
		child.AddEventListener(.TextInput, new [&](e) =>
			{
				texts++;
				lastText.Set(((TextInputEvent)e).Text);
			});

		d.InjectKeyDown(65); // no focus yet: dropped
		Test.Assert(keys == 0);

		d.FocusNode = child;
		d.InjectKeyDown(65);
		d.InjectText("hi");
		Test.Assert(keys == 1);
		Test.Assert(texts == 1);
		Test.Assert(lastText == "hi");
	}

	[Test]
	public static void ProgrammaticFocusGainsAndReleases()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let a = SceneFixtures.NewNode(0.0f, 0.0f, 50.0f, 50.0f, root);
		defer a.ReleaseRef();
		let b = SceneFixtures.NewNode(60.0f, 0.0f, 50.0f, 50.0f, root);
		defer b.ReleaseRef();
		let d = root.EventDispatcher;

		a.RequestFocus();
		Test.Assert(d.FocusNode == a);
		Test.Assert(a.IsFocused);

		b.RequestFocus(); // moves focus: a loses, b gains
		Test.Assert(d.FocusNode == b);
		Test.Assert(!a.IsFocused);
		Test.Assert(b.IsFocused);

		b.ReleaseFocus();
		Test.Assert(d.FocusNode == null);
		Test.Assert(!b.IsFocused);
	}

	[Test]
	public static void ASubtreeLeavingTheTreeTakesTheHoverPressAndFocusRefsIntoIt()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let panel = SceneFixtures.NewNode(0.0f, 0.0f, 100.0f, 100.0f);
		defer panel.ReleaseRef();
		let child = SceneFixtures.NewNode(0.0f, 0.0f, 50.0f, 50.0f, panel);
		defer child.ReleaseRef();
		let other = SceneFixtures.NewNode(100.0f, 100.0f, 50.0f, 50.0f);
		defer other.ReleaseRef();
		root.AddChild(panel);
		root.AddChild(other);
		let d = root.EventDispatcher;

		d.InjectMouseMove(.(10.0f, 10.0f));
		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		d.FocusNode = child;
		Test.Assert(d.OverNode == child);
		Test.Assert(d.FocusNode == child);

		root.RemoveChild(panel); // the child goes with its parent
		Test.Assert(d.OverNode == root); // what is still under the pointer
		Test.Assert(!child.Hovered);
		Test.Assert(d.FocusNode == null);
		Test.Assert(!child.IsFocused); // told it lost focus while it still lived
		d.InjectMouseUp(.(10.0f, 10.0f), .Left); // no press to finish
		d.InjectMouseMove(.(120.0f, 120.0f));
		Test.Assert(d.OverNode == other);

		// A node leaving elsewhere leaves the refs alone.
		d.FocusNode = other;
		root.AddChild(panel);
		root.RemoveChild(panel);
		Test.Assert(d.OverNode == other);
		Test.Assert(d.FocusNode == other);
	}

	[Test]
	public static void APopupLeavingTheTreeOrWithItsOwnerIsDroppedAndToldWhy()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let opener = SceneFixtures.NewNode(0.0f, 0.0f, 50.0f, 20.0f, root);
		defer opener.ReleaseRef();
		let popup = SceneFixtures.NewNode(0.0f, 20.0f, 50.0f, 80.0f);
		defer popup.ReleaseRef();
		let d = root.EventDispatcher;
		PopupCloseReason why = .Code;
		int closes = 0;
		let first = new PopupOptions();
		first.OnClosed = new [&](reason) =>
			{
				closes++;
				why = reason;
			};
		d.OpenPopup(opener, popup, first);
		Test.Assert(popup.Parent == opener); // the opener's child while open
		Test.Assert(popup.InTopLayer);
		popup.RemoveFromParent();
		Test.Assert(d.PopupCount == 0);
		Test.Assert(closes == 1);
		Test.Assert(why == .OwnerRemoved);
		Test.Assert(!popup.InTopLayer);

		let second = new PopupOptions();
		second.OnClosed = new [&](reason) =>
			{
				closes++;
				why = reason;
			};
		d.OpenPopup(opener, popup, second);
		root.RemoveChild(opener);
		Test.Assert(d.PopupCount == 0);
		Test.Assert(closes == 2);
		Test.Assert(why == .OwnerRemoved);
	}

	[Test]
	public static void TabNavigationCyclesThroughTabFocusableNodesInOrder()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let a = SceneFixtures.NewNode(0.0f, 0.0f, 50.0f, 20.0f);
		defer a.ReleaseRef();
		let skip = SceneFixtures.NewNode(0.0f, 20.0f, 50.0f, 20.0f); // NOT focusable
		defer skip.ReleaseRef();
		let b = SceneFixtures.NewNode(0.0f, 40.0f, 50.0f, 20.0f);
		defer b.ReleaseRef();
		let c = SceneFixtures.NewNode(0.0f, 60.0f, 50.0f, 20.0f);
		defer c.ReleaseRef();
		a.TabFocusable = true;
		b.TabFocusable = true;
		c.TabFocusable = true;
		root.AddChild(a);
		root.AddChild(skip);
		root.AddChild(b);
		root.AddChild(c);
		let d = root.EventDispatcher;

		// Nothing focused: Tab lands on the first stop.
		Test.Assert(d.FocusNext());
		Test.Assert(d.FocusNode == a);
		// Tab skips the non-focusable node.
		Test.Assert(d.FocusNext());
		Test.Assert(d.FocusNode == b);
		Test.Assert(d.FocusNext());
		Test.Assert(d.FocusNode == c);
		// Wraps back to the first.
		Test.Assert(d.FocusNext());
		Test.Assert(d.FocusNode == a);
		// Shift+Tab goes backwards (wraps to the last).
		Test.Assert(d.FocusPrevious());
		Test.Assert(d.FocusNode == c);
	}

	[Test]
	public static void TheTabKeyDrivesFocusTraversalShiftTabReverses()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let a = SceneFixtures.NewNode(0.0f, 0.0f, 50.0f, 20.0f);
		defer a.ReleaseRef();
		let b = SceneFixtures.NewNode(0.0f, 40.0f, 50.0f, 20.0f);
		defer b.ReleaseRef();
		a.TabFocusable = true;
		b.TabFocusable = true;
		root.AddChild(a);
		root.AddChild(b);
		let d = root.EventDispatcher;

		d.InjectKeyDown((uint32)KeyCode.Tab);
		Test.Assert(d.FocusNode == a);
		d.InjectKeyDown((uint32)KeyCode.Tab);
		Test.Assert(d.FocusNode == b);
		d.InjectKeyDown((uint32)KeyCode.Tab, KeyModShift);
		Test.Assert(d.FocusNode == a);
	}

	[Test]
	public static void TabIsConsumedNotRoutedButOtherKeysStillReachTheFocusNode()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let a = SceneFixtures.NewNode(0.0f, 0.0f, 50.0f, 20.0f);
		defer a.ReleaseRef();
		a.TabFocusable = true;
		root.AddChild(a);
		let d = root.EventDispatcher;

		int tabKeys = 0;
		int otherKeys = 0;
		a.AddEventListener(.KeyDown, new [&](e) =>
			{
				if (((KeyEvent)e).KeyCode == (uint32)KeyCode.Tab)
					tabKeys++;
				else
					otherKeys++;
			});

		d.InjectKeyDown((uint32)KeyCode.Tab); // focuses a, consumed
		Test.Assert(d.FocusNode == a);
		Test.Assert(tabKeys == 0); // the widget never saw the Tab
		d.InjectKeyDown((uint32)KeyCode.Home); // a real key routes through
		Test.Assert(otherKeys == 1);
	}

	[Test]
	public static void OnlyTheLeftButtonSynthesizesAClick()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = SceneFixtures.NewNode(0.0f, 0.0f, 100.0f, 100.0f, root);
		defer child.ReleaseRef();
		let d = root.EventDispatcher;

		int clicks = 0;
		int downs = 0;
		child.AddEventListener(.MouseClick, new [&](e) => { clicks++; });
		child.AddEventListener(.MouseDown, new [&](e) => { downs++; });

		// Right-click: down and up are delivered, but no click (no activation).
		d.InjectMouseDown(.(10.0f, 10.0f), .Right);
		d.InjectMouseUp(.(10.0f, 10.0f), .Right);
		Test.Assert(downs == 1);
		Test.Assert(clicks == 0);

		// Left-click activates.
		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		d.InjectMouseUp(.(10.0f, 10.0f), .Left);
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void AMoveCarriesTheModifiersHeldDuringIt()
	{
		let root = SceneFixtures.NewScene(100.0f, 100.0f);
		defer root.ReleaseRef();
		uint32 seen = 0;
		root.AddEventListener(.MouseMove, new [&](e) => { seen = ((MouseEvent)e).Modifiers; });
		let d = root.EventDispatcher;
		d.InjectMouseMove(.(10.0f, 10.0f), KeyModShift);
		Test.Assert(seen == KeyModShift);
		d.InjectMouseMove(.(12.0f, 10.0f));
		Test.Assert(seen == 0);
	}

	[Test]
	public static void ADisabledWidgetOrOneInsideADisabledPanelTakesNoPointerInput()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let backdrop = SceneFixtures.NewNode(0.0f, 0.0f, 200.0f, 200.0f);
		defer backdrop.ReleaseRef();
		let panel = SceneFixtures.NewNode(100.0f, 0.0f, 100.0f, 100.0f);
		defer panel.ReleaseRef();
		let button = new Button();
		defer button.ReleaseRef();
		let inner = new Button();
		defer inner.ReleaseRef();
		button.Size = .(50.0f, 20.0f);
		inner.Size = .(50.0f, 20.0f);
		root.AddChild(backdrop);
		root.AddChild(button);
		root.AddChild(panel);
		panel.AddChild(inner);
		int clicks = 0;
		int innerClicks = 0;
		int behind = 0;
		int enters = 0;
		button.SetOnClick(new [&] () => { clicks++; });
		inner.SetOnClick(new [&] () => { innerClicks++; });
		backdrop.AddEventListener(.MouseDown, new [&] (e) => { behind++; });
		button.AddEventListener(.MouseEnter, new [&] (e) => { enters++; });
		let d = root.EventDispatcher;
		void Click(Float2 at)
		{
			d.InjectMouseMove(at);
			d.InjectMouseDown(at, .Left);
			d.InjectMouseUp(at, .Left);
		}

		button.Enabled = false;
		Click(.(10.0f, 10.0f));
		Test.Assert(clicks == 0);
		Test.Assert(behind == 0); // it still covers what lies behind it
		Test.Assert(enters == 1); // and is still hovered (a tooltip says why it is disabled)
		Test.Assert(d.FocusNode == null);
		button.Enabled = true;
		Click(.(10.0f, 10.0f));
		Test.Assert(clicks == 1);

		panel.Enabled = false;
		Test.Assert(!inner.IsTreeEnabled);
		Click(.(110.0f, 10.0f));
		Test.Assert(innerClicks == 0);
		d.FocusNode = inner;
		Test.Assert(!d.Activate()); // nor by the keyboard
		Test.Assert(innerClicks == 0);
	}

	[Test]
	public static void ACentredPopupSitsInTheRootsMiddleByItsSizeAgainAsTheRootResizes()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let opener = new Panel(); // at the root's edge
		defer opener.ReleaseRef();
		opener.Position = .(350.0f, 10.0f);
		opener.Size = .(40.0f, 20.0f);
		let popup = new Panel();
		defer popup.ReleaseRef();
		popup.Size = .(100.0f, 60.0f);
		root.AddChild(opener);
		let d = root.EventDispatcher;
		let options = new PopupOptions();
		options.Centered = true;
		options.Anchor = opener; // not asked: centred
		d.OpenPopup(opener, popup, options);
		root.UpdateLayout();
		Test.Assert(NodeFixtures.Near(popup.ConvertToRootSpace(.(0.0f, 0.0f)).X, 150.0f));
		Test.Assert(NodeFixtures.Near(popup.ConvertToRootSpace(.(0.0f, 0.0f)).Y, 120.0f));
		root.Size = .(600.0f, 500.0f);
		root.UpdateLayout();
		Test.Assert(NodeFixtures.Near(popup.ConvertToRootSpace(.(0.0f, 0.0f)).X, 250.0f));
		Test.Assert(NodeFixtures.Near(popup.ConvertToRootSpace(.(0.0f, 0.0f)).Y, 220.0f));
		d.ClosePopup(popup);
	}
}
