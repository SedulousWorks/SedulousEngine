using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Docking.Tests.DockingFixtures;

namespace Sedulous.GUI.Docking.Tests;

/// The docking bed with docking's commands defined.
class KeyBed : DockBed
{
	public this()
	{
		DefineDockingCommands(Root.Context);
	}

	public bool Run(StringView command) => Root.RunCommand(command);
	public DockNodeId Focused => Space.FocusedStack;
}

/// Docking from the keyboard (D4 of Specs/gui-lab-evolution-3.md): a docked panel's tab picked up
/// (`drag.pick`) and dropped on another stack's tab; `dock.focus-*` and `dock.move-*` by direction
/// (into the stack that way, else along the surface's edge, the focus going with the panel);
/// `dock.maximize` and back; `dock.close`; none bound to a key, the keyboard's way in a tab's
/// context menu (Move to, Float, Close).
class DockKeyboardTests
{
	private static MenuItem Row(Menu menu, StringView text)
	{
		for (int i < menu.ChildCount)
		{
			let item = menu.GetChildAt(i) as MenuItem;
			if ((item != null) && (item.Text == text))
				return item;
		}
		return null;
	}

	private static Menu Sub(Menu menu, StringView text)
	{
		let row = Row(menu, text);
		let sub = (row != null) ? row as MenuSubItem : null;
		return (sub != null) ? sub.SubMenu : null;
	}

	[Test]
	public static void ATabPickedUpFromTheKeyboardIsDroppedOnAnotherStacksTab()
	{
		let bed = scope KeyBed();
		bed.TabOf("inspector").RequestFocus();
		Test.Assert(bed.D.PickDrag());
		bed.TabOf("hierarchy").RequestFocus();
		Test.Assert(bed.D.DropTarget == bed.ViewOf("hierarchy").Bar);
		Rect preview = .();
		Test.Assert(bed.Preview(out preview));
		bed.D.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(bed.StackOf("inspector") == bed.StackOf("hierarchy"));
	}

	[Test]
	public static void FocusAndMoveByDirectionIntoTheStackThatWayElseAlongTheEdge()
	{
		let bed = scope KeyBed();
		let central = bed.Controller.Layout.CentralStack;
		let hierarchy = bed.StackOf("hierarchy");
		let console = bed.StackOf("console");
		bed.TabOf("inspector").RequestFocus();
		Test.Assert(bed.Focused == central);
		Test.Assert(bed.Run("dock.focus-down"));
		Test.Assert(bed.Focused == console);
		Test.Assert(bed.Run("dock.focus-left")); // the hierarchy spans the whole height
		Test.Assert(bed.Focused == hierarchy);
		bed.Run("dock.focus-left"); // nothing that way: it stays
		Test.Assert(bed.Focused == hierarchy);

		bed.TabOf("inspector").RequestFocus();
		Test.Assert(bed.Run("dock.move-left")); // into the hierarchy's stack, the focus with it
		Test.Assert(bed.StackOf("inspector") == hierarchy);
		Test.Assert(bed.Focused == hierarchy);
		bed.Lay();
		Test.Assert(bed.Run("dock.move-up")); // nothing above: along the surface's top
		let layout = bed.Controller.Layout;
		let root = layout.FindNode(layout.FindSurface(layout.MainSurface).Root);
		Test.Assert(root.Axis == .Vertical);
		Test.Assert(root.Children[0] == bed.StackOf("inspector"));
		Test.Assert(bed.Focused == bed.StackOf("inspector"));
	}

	[Test]
	public static void MaximizeAndBackCloseNoKeyBoundToThem()
	{
		let bed = scope KeyBed();
		let central = bed.Controller.Layout.CentralStack;
		bed.TabOf("inspector").RequestFocus();
		Test.Assert(bed.Run("dock.maximize"));
		Test.Assert(bed.Controller.Layout.FindSurface(bed.Controller.Layout.MainSurface).Maximized == central);
		Test.Assert(bed.Focused == central);
		Test.Assert(bed.Run("dock.maximize"));
		Test.Assert(bed.Controller.Layout.FindSurface(bed.Controller.Layout.MainSurface).Maximized == cNoDock);

		Test.Assert(bed.Run("dock.close"));
		Test.Assert(bed.StackOf("inspector") == cNoDock);

		// No key is bound to them: docking is the pointer's, and the keys a desktop leaves free differ.
		String[8] commands = .("dock.focus-left", "dock.move-down", "dock.maximize", "dock.close",
			"dock.move-to", "dock.float", "dock.next-surface", "dock.previous-surface");
		for (let command in commands)
		{
			Test.Assert(bed.Root.Context.Commands.Find(command) != null);
			let shortcut = scope String();
			bed.Root.Context.Keymap.ShortcutText(command, shortcut);
			Test.Assert(shortcut.IsEmpty);
		}
	}

	[Test]
	public static void TheKeyboardsWayInIsAFocusedTabsContextMenuShiftF10MoveTo()
	{
		let bed = scope KeyBed();
		bed.TabOf("inspector").RequestFocus();
		bed.D.InjectKeyDown((uint32)KeyCode.F10, KeyModShift);
		bed.Root.Context.Update(Seconds(0.016)); // the binding runs in the frame
		let menu = bed.Space.MoveMenu;
		Test.Assert(menu != null);
		Test.Assert(menu.IsOpen);
	}

	[Test]
	public static void TheMoveToMenuFromATabsContextMenuOrDockMoveToEachPlaceThoseRefusedDisabled()
	{
		let bed = scope KeyBed();
		Test.Assert(bed.Controller.Edit(scope (l) => l.SetStackFlags(bed.StackOf("console"), DockStackNoTabs)).Ok);
		bed.Lay();
		let at = Centre(Bounds(bed.TabOf("inspector")));
		bed.D.InjectMouseDown(at, .Right);
		bed.D.InjectMouseUp(at, .Right);
		var menu = bed.Space.MoveMenu;
		Test.Assert(menu != null);
		Test.Assert(menu.IsOpen);
		let into = Sub(menu, "Into");
		Test.Assert(into != null);
		Test.Assert(Row(into, "scene, inspector") == null); // not its own stack
		Test.Assert(Row(into, "console") != null);
		Test.Assert(!Row(into, "console").Enabled); // the console's stack takes no tabs
		Test.Assert(Row(into, "hierarchy") != null);
		Test.Assert(Row(into, "hierarchy").Enabled);
		let beside = Sub(menu, "Beside");
		Test.Assert(beside != null);
		let besideConsole = Sub(beside, "console");
		Test.Assert(besideConsole != null);
		Test.Assert(Row(besideConsole, "Right") != null);
		Row(besideConsole, "Right").HandleActivate(); // as Return on it
		Test.Assert(!menu.IsOpen);
		let inspector = bed.StackOf("inspector");
		let split = bed.Controller.Layout.FindNode(bed.Controller.Layout.FindNode(inspector).Parent);
		Test.Assert(split != null);
		Test.Assert(split.Children[1] == inspector);
		Test.Assert(split.Children[0] == bed.StackOf("console"));
		Test.Assert(bed.Focused == inspector); // the focus went with it

		bed.Lay();
		Test.Assert(bed.Run("dock.move-to"));
		menu = bed.Space.MoveMenu;
		Test.Assert(menu != null);
		Test.Assert(menu.IsOpen);
		let edge = Sub(menu, "Along the Edge");
		Test.Assert(edge != null);
		Row(edge, "Top").HandleActivate();
		let layout = bed.Controller.Layout;
		let root = layout.FindNode(layout.FindSurface(layout.MainSurface).Root);
		Test.Assert(root.Axis == .Vertical);
		Test.Assert(root.Children[0] == bed.StackOf("inspector"));
	}

	[Test]
	public static void ATabsContextMenuEndsWithCloseDisabledForAPanelThatCannotBeClosed()
	{
		let bed = scope KeyBed();
		Test.Assert(bed.Controller.Register(PanelNamed("fixed", default, false)));
		Test.Assert(bed.Controller.Edit(scope (l) => l.InsertTab("fixed", bed.StackOf("hierarchy"))).Ok);
		bed.Lay();

		bed.TabOf("inspector").RequestFocus();
		Test.Assert(bed.Run("dock.move-to"));
		var menu = bed.Space.MoveMenu;
		Test.Assert(menu != null);
		let close = Row(menu, "Close");
		Test.Assert(close != null);
		Test.Assert(close.Enabled);
		close.HandleActivate();
		Test.Assert(!menu.IsOpen);
		Test.Assert(bed.StackOf("inspector") == cNoDock);

		bed.Lay();
		bed.TabOf("fixed").RequestFocus();
		Test.Assert(bed.Run("dock.move-to"));
		menu = bed.Space.MoveMenu;
		Test.Assert(menu != null);
		Test.Assert(Row(menu, "Close") != null);
		Test.Assert(!Row(menu, "Close").Enabled);
	}

	/// `dock.float` with no area about the space: the focused stack's panel floats into a surface
	/// of its own with no bounds (an area would cascade it), and leaves the space.
	[Test]
	public static void DockFloatWithNoAreaFloatsTheFocusedPanelIntoASurfaceOfItsOwn()
	{
		let bed = scope KeyBed();
		bed.TabOf("console").RequestFocus();
		Test.Assert(bed.Focused == bed.StackOf("console"));
		Test.Assert(bed.Run("dock.float"));
		let layout = bed.Controller.Layout;
		Test.Assert(layout.Surfaces.Count == 2);
		let surface = layout.FindSurface(layout.SurfaceOf(bed.StackOf("console")));
		Test.Assert(surface != null);
		Test.Assert(surface.Kind == .Floating);
		Test.Assert(surface.Bounds.Width == 0.0f);
		Test.Assert(surface.Bounds.Height == 0.0f);
		bed.Lay();
		Test.Assert(bed.Space.PageOf("console") == null); // the main surface's space shows it no more
		let why = scope String();
		Test.Assert(layout.CheckInvariants(why), why);
	}
}
