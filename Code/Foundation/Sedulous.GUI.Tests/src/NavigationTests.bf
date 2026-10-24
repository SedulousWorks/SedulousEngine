using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Directional navigation: the geometric picker over grids and irregular layouts, focus scopes
// (pass, wrap, contain, focus memory, default focus), widgets that use the arrows and give them
// back at their ends, and activation by Return.

/// A GUI 400 by 400. The root and the tree go with it.
class NavBed
{
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 400.0f) ~ _.ReleaseRef();

	public EventDispatcher D => Root.EventDispatcher;

	/// The focused widget's id (empty: none, or not a widget).
	public StringView Focused
	{
		get
		{
			let w = D.FocusNode as UIWidget;
			return (w != null) ? w.Id : "";
		}
	}

	public void Key(KeyCode key)
	{
		D.InjectKeyDown((uint32)key);
	}

	/// A focusable button `id` at (x, y), `w` by `h`, the last child of `parent`, which holds it: it
	/// comes back borrowed.
	public static Button Cell(Node parent, StringView id, float x, float y, float w, float h)
	{
		let b = new Button();
		b.Id = id;
		b.Position = .(x, y);
		b.Size = .(w, h);
		parent.AddChild(b);
		b.ReleaseRef(); // the tree's reference keeps it
		return b;
	}

	/// A cell 40 by 20.
	public static Button Cell(Node parent, StringView id, float x, float y) => Cell(parent, id, x, y, 40.0f, 20.0f);
}

/// Navigation: the picker, scopes, widgets keeping or giving back their arrows, Return.
class NavigationTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1.2e-5 * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));

	[Test]
	public static void AGridMovesByRowsAndColumnsAndStopsAtItsEdges()
	{
		let bed = scope NavBed();
		// a b c
		// d e f
		String[6] ids = .("a", "b", "c", "d", "e", "f");
		for (int i = 0; i < 6; ++i)
			NavBed.Cell(bed.Root, ids[i], 10.0f + 60.0f * (float)(i % 3), 10.0f + 40.0f * (float)(i / 3));

		bed.Key(.Down); // nothing focused: the first
		Test.Assert(bed.Focused == "a");
		bed.Key(.Right);
		Test.Assert(bed.Focused == "b");
		bed.Key(.Down);
		Test.Assert(bed.Focused == "e");
		bed.Key(.Right);
		Test.Assert(bed.Focused == "f");
		bed.Key(.Right); // the edge
		Test.Assert(bed.Focused == "f");
		bed.Key(.Up);
		Test.Assert(bed.Focused == "c");
	}

	[Test]
	public static void AnOverlappingNeighbourBeatsADiagonallyNearerOne()
	{
		let bed = scope NavBed();
		let from = NavBed.Cell(bed.Root, "from", 100.0f, 100.0f);
		NavBed.Cell(bed.Root, "diagonal", 150.0f, 130.0f); // nearer, but off the row
		let row = NavBed.Cell(bed.Root, "row", 260.0f, 100.0f); // farther, on the row
		bed.D.FocusNode = from;
		bed.Key(.Right);
		Test.Assert(bed.Focused == "row");

		// Irregular: with nothing on the row, the nearest beyond wins.
		row.Visible = false;
		bed.D.FocusNode = from;
		bed.Key(.Right);
		Test.Assert(bed.Focused == "diagonal");
	}

	[Test]
	public static void HiddenDisabledAndClippedAwayWidgetsAreSkipped()
	{
		let bed = scope NavBed();
		let from = NavBed.Cell(bed.Root, "from", 10.0f, 10.0f);
		let hidden = NavBed.Cell(bed.Root, "hidden", 10.0f, 40.0f);
		let disabled = NavBed.Cell(bed.Root, "disabled", 10.0f, 70.0f);
		let area = new UIWidget();
		defer area.ReleaseRef();
		area.Position = .(0.0f, 100.0f);
		area.Size = .(60.0f, 30.0f);
		area.ClipChildren = true;
		bed.Root.AddChild(area);
		NavBed.Cell(area, "clipped", 10.0f, 200.0f); // outside its parent's clip
		NavBed.Cell(bed.Root, "target", 10.0f, 160.0f);
		hidden.Visible = false;
		disabled.Enabled = false;
		bed.D.FocusNode = from;
		bed.Key(.Down);
		Test.Assert(bed.Focused == "target");
	}

	[Test]
	public static void ScopesPassWrapAndContainComingBackReturnsToTheRememberedWidget()
	{
		let bed = scope NavBed();
		let menu = new UIWidget(); // a column on the left
		defer menu.ReleaseRef();
		menu.Size = .(100.0f, 200.0f);
		bed.Root.AddChild(menu);
		menu.NavScope = .Wrap;
		NavBed.Cell(menu, "one", 10.0f, 10.0f);
		let two = NavBed.Cell(menu, "two", 10.0f, 40.0f);
		let three = NavBed.Cell(menu, "three", 10.0f, 70.0f);
		NavBed.Cell(bed.Root, "side", 200.0f, 40.0f); // outside the menu, to its right

		bed.D.FocusNode = three;
		bed.Key(.Down); // wraps to the top
		Test.Assert(bed.Focused == "one");
		bed.Key(.Up); // and back round
		Test.Assert(bed.Focused == "three");

		// A pass scope hands an edge on: Right finds nothing inside the menu, so the widget beside it.
		menu.NavScope = .Pass;
		bed.D.FocusNode = two;
		bed.Key(.Right);
		Test.Assert(bed.Focused == "side");
		bed.Key(.Left); // back into the menu: the remembered widget, not the nearest
		Test.Assert(bed.Focused == "two");

		menu.NavScope = .Contain;
		bed.Key(.Right); // a dialog's edge
		Test.Assert(bed.Focused == "two");
	}

	[Test]
	public static void EnteringAScopeWithNoMemoryTakesItsDefaultFocus()
	{
		let bed = scope NavBed();
		let start = NavBed.Cell(bed.Root, "start", 10.0f, 10.0f);
		let panel = new UIWidget();
		defer panel.ReleaseRef();
		panel.Position = .(0.0f, 100.0f);
		panel.Size = .(300.0f, 100.0f);
		panel.NavScope = .Pass;
		panel.DefaultFocusId = "ok";
		bed.Root.AddChild(panel);
		NavBed.Cell(panel, "cancel", 10.0f, 10.0f); // nearest from above
		NavBed.Cell(panel, "ok", 200.0f, 10.0f);
		bed.D.FocusNode = start;
		bed.Key(.Down);
		Test.Assert(bed.Focused == "ok");
	}

	[Test]
	public static void AModalConfinesIt()
	{
		let bed = scope NavBed();
		NavBed.Cell(bed.Root, "behind", 10.0f, 10.0f);
		let dialog = new UIWidget();
		defer dialog.ReleaseRef();
		dialog.Position = .(100.0f, 100.0f);
		dialog.Size = .(200.0f, 100.0f);
		NavBed.Cell(dialog, "yes", 10.0f, 10.0f);
		NavBed.Cell(dialog, "no", 100.0f, 10.0f);
		let modal = new PopupOptions();
		modal.Kind = .Manual;
		modal.Modal = true;
		bed.D.OpenPopup(bed.Root, dialog, modal);
		Test.Assert(bed.Focused == "yes"); // focus moves in: the modal's first
		bed.Key(.Right);
		Test.Assert(bed.Focused == "no");
		bed.Key(.Up); // the widget behind is out of reach
		Test.Assert(bed.Focused == "no");
	}

	[Test]
	public static void ASliderKeepsItsArrowsAtItsEndsAListGivesThemBack()
	{
		let bed = scope NavBed();
		let slider = new Slider();
		defer slider.ReleaseRef();
		slider.Position = .(10.0f, 10.0f);
		slider.Size = .(100.0f, 20.0f);
		bed.Root.AddChild(slider);
		NavBed.Cell(bed.Root, "after", 200.0f, 10.0f);
		bed.D.FocusNode = slider;
		slider.Value = 0.9f;
		bed.Key(.Right);
		Test.Assert(Near(slider.Value, 0.95));
		bed.Key(.Right);
		bed.Key(.Right); // at 1: still the slider's (holding to the end must not leave it)
		Test.Assert(Near(slider.Value, 1.0));
		Test.Assert(bed.D.FocusNode == slider);

		let list = new ListBox();
		defer list.ReleaseRef();
		list.Position = .(10.0f, 100.0f);
		list.Size = .(100.0f, 80.0f);
		list.AddItem("x");
		list.AddItem("y");
		bed.Root.AddChild(list);
		NavBed.Cell(bed.Root, "below", 10.0f, 250.0f);
		bed.D.FocusNode = list;
		list.SelectedIndex = 0;
		bed.Key(.Down);
		Test.Assert(list.SelectedIndex == 1);
		Test.Assert(bed.D.FocusNode == list);
		bed.Key(.Down); // at the end: given back
		Test.Assert(bed.Focused == "below");
	}

	[Test]
	public static void ReturnActivatesTheFocusedButtonAsAClickDoes()
	{
		let bed = scope NavBed();
		let go = NavBed.Cell(bed.Root, "go", 10.0f, 10.0f);
		int clicks = 0;
		go.AddEventListener(.MouseClick, new [&] (e) => { clicks++; });
		let check = new CheckBox();
		defer check.ReleaseRef();
		check.Position = .(10.0f, 60.0f);
		check.Size = .(20.0f, 20.0f);
		bed.Root.AddChild(check);

		bed.D.FocusNode = go;
		bed.Key(.Return);
		Test.Assert(clicks == 1);
		bed.D.FocusNode = check;
		bed.Key(.Space);
		Test.Assert(check.Checked);
	}

	[Test]
	public static void OverridesFromASheetAndNativeCodeComeFirst()
	{
		let bed = scope NavBed();
		let a = NavBed.Cell(bed.Root, "a", 10.0f, 10.0f);
		let b = NavBed.Cell(bed.Root, "b", 10.0f, 40.0f);
		NavBed.Cell(bed.Root, "c", 300.0f, 300.0f);
		// A sheet: down from a goes to c (geometry would say b); right from b stops.
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "#a { nav-down: c; } #b { nav-right: none; nav-next: a; }");
		styles.ApplyTree(bed.Root);
		Test.Assert(a.NavDown == "c");
		bed.D.FocusNode = a;
		bed.Key(.Down);
		Test.Assert(bed.Focused == "c");
		bed.D.FocusNode = b;
		bed.Key(.Right);
		Test.Assert(bed.Focused == "b");
		bed.Key(.Tab); // nav-next
		Test.Assert(bed.Focused == "a");

		// An id that is not there, or auto: the picker as usual.
		a.NavDown = "nowhere";
		bed.D.FocusNode = a;
		bed.Key(.Down);
		Test.Assert(bed.Focused == "b");

		// A scope's kind and default focus from a sheet.
		let panel = new UIWidget();
		defer panel.ReleaseRef();
		panel.Id = "panel";
		bed.Root.AddChild(panel);
		let scopes = scope StyleManager();
		WidgetFixtures.UseSheet(scopes, "#panel { nav-scope: contain; nav-default: c; }");
		scopes.ApplyTree(bed.Root);
		Test.Assert(panel.NavScope == .Contain);
		Test.Assert(panel.DefaultFocusId == "c");
	}

	[Test]
	public static void AHeldDirectionRepeatsAfterADelayFasterTheLongerItIsHeld()
	{
		let bed = scope NavBed();
		Button[40] cells = default;
		for (int i = 0; i < 40; ++i)
		{
			let id = scope String();
			id.AppendF("c{}{}", i / 10, i % 10);
			cells[i] = NavBed.Cell(bed.Root, id, 10.0f, 10.0f + 25.0f * (float)i, 40.0f, 20.0f);
		}
		bed.D.FocusNode = cells[0];
		int Index()
		{
			for (int i = 0; i < 40; ++i)
			{
				if (bed.D.FocusNode == cells[i])
					return i;
			}
			return -1;
		}
		bed.D.PressDirection(.Down); // at once
		Test.Assert(Index() == 1);
		Test.Assert(bed.Root.NeedsFrame()); // held: frames keep coming
		bed.Root.Context.Update(SceneFixtures.Seconds(0.39)); // not yet the delay
		Test.Assert(Index() == 1);
		bed.Root.Context.Update(SceneFixtures.Seconds(0.02)); // past it: the first repeat
		Test.Assert(Index() == 2);
		// Over the first half second of repeats, slower; over a later half second, faster.
		bed.Root.Context.Update(SceneFixtures.Seconds(0.5));
		let early = Index() - 2;
		for (int i = 0; i < 20; ++i)
			bed.Root.Context.Update(SceneFixtures.Seconds(0.05)); // a second more
		let before = Index();
		bed.Root.Context.Update(SceneFixtures.Seconds(0.5));
		let late = Index() - before;
		Test.Assert(late > early);
		bed.D.ReleaseDirection(.Down);
		let released = Index();
		bed.Root.Context.Update(SceneFixtures.Seconds(1.0));
		Test.Assert(Index() == released);
	}

	[Test]
	public static void TheFocusRingShowsForTheKeyboardAndAGamepadNotAfterAClick()
	{
		let bed = scope NavBed();
		let a = NavBed.Cell(bed.Root, "a", 10.0f, 10.0f);
		let b = NavBed.Cell(bed.Root, "b", 10.0f, 40.0f);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "button:focus-visible { opacity: 0.5; }");

		bed.D.InjectMouseDown(.(20.0f, 15.0f), .Left); // click-to-focus
		bed.D.InjectMouseUp(.(20.0f, 15.0f), .Left);
		Test.Assert(a.IsFocused);
		Test.Assert(!a.FocusVisible);
		styles.ApplyTree(bed.Root);
		Test.Assert(Near(a.Alpha, 1.0f));

		bed.Key(.Down);
		Test.Assert(b.FocusVisible);
		styles.ApplyTree(bed.Root);
		Test.Assert(Near(b.Alpha, 0.5f));

		bed.D.InjectMouseDown(.(300.0f, 300.0f), .Left); // the pointer again
		Test.Assert(!b.FocusVisible);
	}

	[Test]
	public static void FocusMovedIntoAScrollersHiddenPartScrollsItIntoView()
	{
		let bed = scope NavBed();
		let scroll = new ScrollView();
		defer scroll.ReleaseRef();
		scroll.Size = .(200.0f, 100.0f);
		bed.Root.AddChild(scroll);
		let top = new Button();
		defer top.ReleaseRef();
		top.Id = "top";
		top.Position = .(0.0f, 0.0f);
		top.Size = .(60.0f, 30.0f);
		let far = new Button();
		defer far.ReleaseRef();
		far.Id = "far";
		far.Position = .(0.0f, 300.0f);
		far.Size = .(60.0f, 30.0f);
		scroll.AddChild(top);
		scroll.AddChild(far);
		bed.Root.UpdateLayout();
		bed.D.FocusNode = top;
		bed.Key(.Down);
		Test.Assert(bed.D.FocusNode == far);
		let shown = far.ScreenBounds;
		Test.Assert(shown.Y >= 0.0f);
		Test.Assert(shown.Y + shown.Height <= 100.0f + 0.5f); // inside the 100-high viewport
	}

	[Test]
	public static void AHeldDPadDirectionReachesTheFocusedWidgetBeforeNavigation()
	{
		// The showcase's slider: the d-pad must change its value, not move focus away from it.
		let bed = scope NavBed();
		let slider = new Slider();
		defer slider.ReleaseRef();
		slider.Position = .(10.0f, 10.0f);
		slider.Size = .(100.0f, 20.0f);
		bed.Root.AddChild(slider);
		NavBed.Cell(bed.Root, "after", 200.0f, 10.0f);
		bed.D.FocusNode = slider;
		slider.Value = 0.5f;
		bed.D.PressDirection(.Right);
		Test.Assert(Near(slider.Value, 0.55));
		Test.Assert(bed.D.FocusNode == slider);
		bed.Root.Context.Update(SceneFixtures.Seconds(0.45)); // a repeat steps it again
		Test.Assert(Near(slider.Value, 0.6));
		bed.D.ReleaseDirection(.Right);
		// Down is not the slider's: focus moves.
		bed.D.PressDirection(.Down);
		bed.D.ReleaseDirection(.Down);
		Test.Assert(bed.D.FocusNode == slider); // nothing below it: stays
		slider.Value = 1.0f;
		bed.D.PressDirection(.Right); // at its end: still the slider's
		Test.Assert(bed.D.FocusNode == slider);
		bed.D.ReleaseDirection(.Right);
	}

	[Test]
	public static void AfterAClickOnTheBackdropAnArrowStartsFromTheGUIsEntry()
	{
		// The showcase at launch: Play focused, a click on the backdrop, then Down. Down from the
		// full-window backdrop found nothing below it (and Up found Quit); it must enter again.
		let bed = scope NavBed();
		let backdrop = new UIWidget();
		defer backdrop.ReleaseRef();
		backdrop.Size = .(400.0f, 400.0f);
		bed.Root.AddChild(backdrop);
		let play = NavBed.Cell(bed.Root, "play", 100.0f, 100.0f);
		NavBed.Cell(bed.Root, "quit", 100.0f, 160.0f);
		bed.D.FocusNode = play;
		Test.Assert(play.FocusVisible); // before any pointer use, focus shows
		bed.D.InjectMouseDown(.(300.0f, 350.0f), .Left);
		bed.D.InjectMouseUp(.(300.0f, 350.0f), .Left);
		Test.Assert(bed.D.FocusNode == null);
		bed.Key(.Down);
		Test.Assert(bed.Focused == "play");

		// Focus left on something that does not take focus (a program's doing) also enters.
		bed.D.FocusNode = backdrop;
		bed.Key(.Down);
		Test.Assert(bed.Focused == "play");
	}

	[Test]
	public static void AWideWidgetAcrossTheRowAboveIsNotToTheRight()
	{
		// The showcase's settings: a text field (120..380) above a centred Back (200..300). Right
		// from Back has nothing to its right, so focus stays.
		let bed = scope NavBed();
		NavBed.Cell(bed.Root, "field", 120.0f, 100.0f, 260.0f, 30.0f);
		let back = NavBed.Cell(bed.Root, "back", 200.0f, 160.0f, 100.0f, 40.0f);
		bed.D.FocusNode = back;
		bed.Key(.Right);
		Test.Assert(bed.Focused == "back");
		bed.Key(.Up); // up is where the field is
		Test.Assert(bed.Focused == "field");
		// Neighbours overlapping a little still count.
		NavBed.Cell(bed.Root, "beside", 290.0f, 160.0f, 60.0f, 40.0f); // overlaps back by 10
		bed.D.FocusNode = back;
		bed.Key(.Right);
		Test.Assert(bed.Focused == "beside");
	}
}
