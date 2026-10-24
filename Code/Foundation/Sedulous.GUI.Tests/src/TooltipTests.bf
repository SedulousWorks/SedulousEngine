using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Tooltips: the GUI shows the nearest tooltip text up the parent chain from the hovered node after
/// a delay on its own clock, by the pointer, as a hint popup (a Tooltip, Node's default content);
/// just after one hid the next shows at once; a press or a key hides it until the pointer moves on;
/// the keys moving the focus show the focused control's; an interactive one holds while the pointer
/// crosses into it. A right release, Shift+F10 or a long press asks for a context menu (a
/// `contextmenu` event); a long press nobody takes shows the tooltip. A text field's offers cut,
/// copy, paste and select all.
class TooltipTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A panel with a tooltip holding a child with none, and another widget with one beside it. The
	/// root (and the tree) go with the bed.
	private class Bed
	{
		public SceneRoot Root = SceneFixtures.NewScene(300.0f, 300.0f) ~ _.ReleaseRef();
		public UIWidget Panel = new .() ~ _.ReleaseRef();
		public UIWidget Child = new .() ~ _.ReleaseRef();
		public UIWidget Other = new .() ~ _.ReleaseRef();

		public this()
		{
			Panel.Size = .(100.0f, 100.0f);
			Panel.Tooltip = "The panel";
			Root.AddChild(Panel);
			Child.Size = .(40.0f, 40.0f);
			Panel.AddChild(Child); // no text of its own: the panel's shows
			Other.Position = .(150.0f, 0.0f);
			Other.Size = .(100.0f, 100.0f);
			Other.Tooltip = "Another";
			Root.AddChild(Other);
		}

		public EventDispatcher D => Root.EventDispatcher;

		public void Frames(int n, double seconds = 0.1)
		{
			for (int i = 0; i < n; ++i)
				Root.Context.Update(SceneFixtures.Seconds(seconds));
		}

		public StringView Shown
		{
			get
			{
				let tip = D.ShownTooltip as Tooltip;
				return (tip != null) ? tip.Text : default;
			}
		}
	}

	[Test]
	public static void TheNearestTextUpTheParentChainShowsAfterTheDelayByThePointer()
	{
		let bed = scope Bed();
		bed.D.InjectMouseMove(.(20.0f, 20.0f)); // over the child
		bed.Frames(4); // 0.4 s
		Test.Assert(bed.D.ShownTooltip == null);
		bed.Frames(2);
		Test.Assert(bed.D.ShownTooltip != null);
		Test.Assert(bed.Shown == "The panel");
		let tip = bed.D.ShownTooltip;
		Test.Assert(Near(tip.Position.X, 32.0f)); // 12 right of the pointer
		Test.Assert(Near(tip.Position.Y, 38.0f)); // 18 below it
	}

	[Test]
	public static void MovingToAnotherHidesItAndTheNextShowsAtOnceWhileWarm()
	{
		let bed = scope Bed();
		bed.D.InjectMouseMove(.(20.0f, 20.0f));
		bed.Frames(6);
		Test.Assert(bed.D.ShownTooltip != null);
		bed.D.InjectMouseMove(.(160.0f, 20.0f)); // onto the other
		bed.Frames(1);
		Test.Assert(bed.Shown == "Another"); // no second wait
		bed.D.InjectMouseMove(.(280.0f, 280.0f)); // nothing with a tooltip
		bed.Frames(1);
		Test.Assert(bed.D.ShownTooltip == null);
		bed.Frames(10); // cold again
		bed.D.InjectMouseMove(.(20.0f, 20.0f));
		bed.Frames(1);
		Test.Assert(bed.D.ShownTooltip == null); // the full delay again
	}

	[Test]
	public static void ItsProvidersTextChangingUnderThePointerShowsTheNewTextAtOnce()
	{
		let bed = scope Bed();
		bed.D.InjectMouseMove(.(20.0f, 20.0f));
		bed.Frames(6);
		Test.Assert(bed.Shown == "The panel");
		bed.Panel.Tooltip = "The panel, elsewhere"; // as a code editor's word under the pointer
		bed.D.InjectMouseMove(.(30.0f, 22.0f));
		bed.Frames(1);
		Test.Assert(bed.Shown == "The panel, elsewhere");
		Test.Assert(Near(bed.D.ShownTooltip.Position.X, 42.0f)); // by the pointer now
		bed.Frames(3);
		Test.Assert(bed.Shown == "The panel, elsewhere"); // the same text stays
	}

	[Test]
	public static void APressHidesItUntilThePointerMovesToAnotherNode()
	{
		let bed = scope Bed();
		bed.D.InjectMouseMove(.(20.0f, 20.0f));
		bed.Frames(6);
		Test.Assert(bed.D.ShownTooltip != null);
		bed.D.InjectMouseDown(.(20.0f, 20.0f), .Left);
		bed.D.InjectMouseUp(.(20.0f, 20.0f), .Left);
		Test.Assert(bed.D.ShownTooltip == null);
		bed.Frames(10);
		Test.Assert(bed.D.ShownTooltip == null); // not again under the same pointer
	}

	[Test]
	public static void AKeyHidesItUntilThePointerMovesToAnotherNode()
	{
		let bed = scope Bed();
		bed.D.InjectMouseMove(.(20.0f, 20.0f));
		bed.Frames(6);
		Test.Assert(bed.D.ShownTooltip != null);
		bed.D.InjectKeyDown((uint32)KeyCode.A);
		Test.Assert(bed.D.ShownTooltip == null);
		bed.Frames(10);
		Test.Assert(bed.D.ShownTooltip == null); // not reopened at the next tick
	}

	[Test]
	public static void SitsByThePointerAtADisplayScale()
	{
		let bed = scope Bed();
		bed.Root.DisplayScale = 2.0f;
		bed.Root.Size = .(300.0f, 300.0f);
		bed.D.InjectMouseMove(.(40.0f, 40.0f)); // device pixels: (20, 20) in the root's units
		bed.Frames(6);
		Test.Assert(bed.D.ShownTooltip != null);
		Test.Assert(Near(bed.D.ShownTooltip.Position.X, 32.0f));
		Test.Assert(Near(bed.D.ShownTooltip.Position.Y, 38.0f));
	}

	[Test]
	public static void TheKeysMovingTheFocusShowTheFocusedControlsBelowIt()
	{
		let bed = scope Bed();
		bed.Panel.TabFocusable = true;
		bed.Other.TabFocusable = true;
		bed.Panel.RequestFocus(); // focused from code at the start: no tooltip of its own accord
		bed.Frames(10);
		Test.Assert(bed.D.ShownTooltip == null);

		bed.D.InjectKeyDown((uint32)KeyCode.Tab); // to the other
		bed.Frames(4);
		Test.Assert(bed.D.ShownTooltip == null); // the delay
		bed.Frames(2);
		Test.Assert(bed.D.ShownTooltip != null);
		Test.Assert(bed.Shown == "Another");
		let tip = bed.D.ShownTooltip;
		Test.Assert(Near(tip.Position.X, 150.0f)); // below the control, at its start
		Test.Assert(Near(tip.Position.Y, 104.0f));

		bed.D.InjectKeyDown((uint32)KeyCode.Tab); // on to the panel: its own, after the delay
		bed.Frames(1);
		Test.Assert(bed.Shown == "The panel"); // warm: at once

		// The pointer in use: the focus's tooltip waits for the keys again.
		bed.D.InjectMouseDown(.(280.0f, 280.0f), .Left);
		bed.D.InjectMouseUp(.(280.0f, 280.0f), .Left);
		bed.Frames(10);
		Test.Assert(bed.D.ShownTooltip == null);
		bed.D.KeyboardTooltips = false;
		bed.D.InjectKeyDown((uint32)KeyCode.Tab);
		bed.Frames(10);
		Test.Assert(bed.D.ShownTooltip == null); // turned off
	}

	[Test]
	public static void AnInteractiveOneHoldsWhileThePointerCrossesIntoItAndTakesAPress()
	{
		let bed = scope Bed();
		bed.Other.TooltipInteractive = true;
		bed.D.InjectMouseMove(.(160.0f, 20.0f));
		bed.Frames(6);
		let tip = bed.D.ShownTooltip;
		Test.Assert(tip != null);
		bed.Root.UpdateLayout();
		let inside = tip.ConvertToWorldSpace(.(tip.Size.X * 0.5f, tip.Size.Y * 0.5f));

		// Off the control, toward the tooltip: it holds a moment.
		bed.D.InjectMouseMove(.(160.0f, 120.0f)); // below the control, before the tooltip
		bed.Frames(1);
		Test.Assert(bed.D.ShownTooltip == tip);
		bed.D.InjectMouseMove(inside); // in it: it holds
		bed.Frames(10);
		Test.Assert(bed.D.ShownTooltip == tip);
		bed.D.InjectMouseDown(inside, .Left); // a press inside does not close it
		bed.D.InjectMouseUp(inside, .Left);
		Test.Assert(bed.D.ShownTooltip == tip);

		// Off both: gone after the grace.
		bed.D.InjectMouseMove(.(20.0f, 280.0f));
		bed.Frames(2); // 0.2 s
		Test.Assert(bed.D.ShownTooltip == tip);
		bed.Frames(2);
		Test.Assert(bed.D.ShownTooltip == null);
	}

	[Test]
	public static void ARightReleaseAsksTheNodeThereAndUpShiftF10AsksTheFocusedOne()
	{
		let bed = scope Bed();
		let button = new Button();
		defer button.ReleaseRef();
		button.Size = .(30.0f, 20.0f);
		bed.Child.AddChild(button);
		int asked = 0;
		Float2 at = .(0.0f, 0.0f);
		bed.Panel.AddEventListener(.ContextMenu, new [&] (e) =>
			{
				++asked;
				at = ((MouseEvent)e).Position;
				e.Handled = true;
			});
		bed.D.InjectMouseDown(.(10.0f, 10.0f), .Right);
		Test.Assert(asked == 0);
		bed.D.InjectMouseUp(.(10.0f, 10.0f), .Right);
		Test.Assert(asked == 1);
		Test.Assert(Near(at.X, 10.0f));
		button.RequestFocus();
		bed.D.InjectKeyDown((uint32)KeyCode.F10, KeyModShift);
		Test.Assert(asked == 2);
		Test.Assert(Near(at.Y, 20.0f)); // the focused node's bottom-left
	}

	[Test]
	public static void ALongPressAsksForOneUntakenItShowsTheTooltipAndNoClickFollows()
	{
		let bed = scope Bed();
		let button = new Button();
		defer button.ReleaseRef();
		button.Size = .(30.0f, 20.0f);
		bed.Child.AddChild(button);
		int clicks = 0;
		button.SetOnClick(new [&] () => { ++clicks; });
		bed.D.InjectTouchDown(1, .(10.0f, 10.0f));
		bed.Frames(3); // 0.3 s
		Test.Assert(bed.D.ShownTooltip == null);
		bed.Frames(3);
		Test.Assert(bed.D.ShownTooltip != null); // nobody opened a menu: the tooltip
		Test.Assert(bed.Shown == "The panel");
		bed.D.InjectTouchUp(1, .(10.0f, 10.0f));
		Test.Assert(clicks == 0);

		// A finger that moves is a drag, not a long press.
		bed.D.InjectTouchDown(1, .(10.0f, 10.0f));
		bed.D.InjectTouchMove(1, .(60.0f, 60.0f));
		bed.Frames(8);
		Test.Assert(bed.D.ShownTooltip == null);
		bed.D.InjectTouchUp(1, .(60.0f, 60.0f));
	}

	[Test]
	public static void ATextFieldsContextMenuOffersCutCopyPasteAndSelectAllLitWhereTheyDoSomething()
	{
		let bed = scope Bed();
		let field = new TextField();
		defer field.ReleaseRef();
		field.Position = .(0.0f, 150.0f);
		field.Size = .(200.0f, 24.0f);
		bed.Root.AddChild(field);
		field.Text = "hello";
		bed.D.InjectMouseDown(.(20.0f, 160.0f), .Right);
		bed.D.InjectMouseUp(.(20.0f, 160.0f), .Right);
		let menu = field.ContextMenu;
		Test.Assert(menu != null);
		Test.Assert(menu.IsOpen);
		Test.Assert(menu.Parent == field);
		Test.Assert(menu.ItemCount == 4);
		// Nothing selected, no clipboard: only select all is lit.
		menu.Close();
		field.SelectAll();
		bed.D.InjectMouseDown(.(20.0f, 160.0f), .Right);
		bed.D.InjectMouseUp(.(20.0f, 160.0f), .Right);
		Test.Assert(menu.IsOpen);
		// Its Cut runs the field's command, and the menu closes, focus back on the field.
		let cut = menu.GetChildAt(0) as MenuItem;
		Test.Assert(cut != null);
		Test.Assert(cut.Text == "Cut");
		Test.Assert(cut.Enabled);
		cut.HandleActivate();
		Test.Assert(field.Text.Length == 0);
		Test.Assert(!menu.IsOpen);
		Test.Assert(field.IsFocused);
	}
}
