using System;
using Sedulous.Core;
using Sedulous.Engine.UI;
using Sedulous.Input;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.Engine.UI.Tests;

/// A phone has no mouse: the first finger is the UI's pointer, its press and release its own,
/// the game's touch controls show once a finger is seen, and only controls take the pointer
/// from the game.
class UITouchPointerTests
{
	/// A stick on the left half, and a Jump zone on the right half when `withJump`.
	private static InputMap TouchMap(bool withJump)
	{
		let map = new InputMap();
		let set = new ActionSet();
		set.Name.Set("Gameplay");
		map.Sets.Add(set);

		let move = new InputAction();
		move.Name.Set("Move");
		move.Kind = .Axis2D;
		var stick = Binding();
		stick.Source = .TouchStick;
		stick.RegionW = 0.5f;
		move.Bindings.Add(stick);
		set.Actions.Add(move);

		if (withJump)
		{
			let jump = new InputAction();
			jump.Name.Set("Jump");
			jump.Kind = .Button;
			var zone = Binding();
			zone.Source = .TouchButton;
			zone.RegionX = 0.5f;
			zone.RegionW = 0.5f;
			jump.Bindings.Add(zone);
			set.Actions.Add(jump);
		}
		return map;
	}

	private static bool Has(ControlState state, ControlState bit) => (state & bit) == bit;

	private static bool Near(float a, float b) => Math.Abs(a - b) <= 0.01f;

	[Test]
	public static void AFingerIsThePointerATapPressesADragScrolls()
	{
		// The web shell takes the touches, and the UI must take them as its pointer or no menu
		// can be pressed.
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices);

		let scene = fixture.Scenes.CreateScene("menu");
		let e = scene.CreateEntity("hud");
		let canvas = scene.GetSystem<UICanvasComponentManager>().Add(e);
		let document = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical">
			<Button id="play" text="Play" width="200" height="40"/>
			<ScrollView id="list" width="200" height="100"><Flex direction="vertical">
			<Label text="1" height="60"/><Label text="2" height="60"/>
			<Label text="3" height="60"/><Label text="4" height="60"/>
			</Flex></ScrollView></Flex>
			""");
		defer delete document;
		canvas.Document.SetDirect(document);
		fixture.Frame();
		let root = fixture.UI.SceneRoot(scene);
		Test.Assert(root != null);
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(root);
		var clicks = 0;
		root.FindByName<Button>("play").OnClick.Add(new [&clicks] (b) => { clicks++; });
		let list = root.FindByName<ScrollView>("list");
		Test.Assert(list != null);

		// The mouse rests far away; a tap on the button clicks it, the release where the finger was.
		devices.FakeMouse.X = 700.0f;
		devices.FakeMouse.Y = 500.0f;
		devices.FakeTouch.Put(1, 50.0f, 20.0f);
		fixture.Frame();
		Test.Assert(fixture.Input.Runtime.GetConsumptionMask().Pointer, "a finger on the UI is the UI's");
		devices.FakeTouch.Points.Clear();
		fixture.Frame();
		Test.Assert(clicks == 1);
		// Lifted: no cursor left behind, and the idle mouse does not take over.
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.GetInputManager().HoveredId == .Invalid);

		// A drag up the list scrolls it.
		fixture.UI.UiContext.UpdateRootView(root);
		devices.FakeTouch.Put(2, 100.0f, 120.0f);
		fixture.Frame();
		devices.FakeTouch.Put(2, 100.0f, 90.0f);
		fixture.Frame();
		devices.FakeTouch.Put(2, 100.0f, 60.0f);
		fixture.Frame();
		Test.Assert(list.ScrollY > 0.0f);
		devices.FakeTouch.Points.Clear();
		fixture.Frame();
		Test.Assert(clicks == 1, "the drag clicked nothing");
	}

	[Test]
	public static void TheTouchGuideShowsTheGamesTouchControlsOnceAFingerTouches()
	{
		let map = TouchMap(true);
		defer delete map;
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices);
		fixture.Input.Runtime.SetMap(map);

		let guide = fixture.UI.TouchGuide;
		Test.Assert(guide != null);
		// No finger yet (a desktop player): nothing shown.
		fixture.Frame();
		Test.Assert(guide.ControlCount == 0);
		Test.Assert(guide.Visibility == .Gone);
		// A finger: both controls, and they stay after it lifts.
		devices.FakeTouch.Put(1, 600.0f, 300.0f);
		fixture.Frame();
		Test.Assert(guide.ControlCount == 2);
		Test.Assert(guide.Visibility == .Visible);
		devices.FakeTouch.Points.Clear();
		fixture.Frame();
		Test.Assert(guide.ControlCount == 2);
		// It covers the screen, and stays through the game's screens coming and going (Snowline
		// clears its screens whenever it changes them).
		let screenRoot = fixture.UI.ScreenRoot;
		screenRoot.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(screenRoot);
		Test.Assert(Near(guide.Width, 800.0f) && Near(guide.Height, 600.0f));
		fixture.UI.Screens.Push(UIScreenTierTests.MenuFor(fixture, "g"));
		fixture.UI.Screens.Clear();
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(screenRoot);
		Test.Assert(guide.Parent === screenRoot);
		Test.Assert(Near(guide.Width, 800.0f));
		// Each name is sized by its button, so it reads on a phone's many pixels as on a desktop:
		// a larger screen, a larger name, never below the least.
		float JumpFont()
		{
			for (int i < guide.ChildCount)
			{
				if (let label = guide.GetChildAt(i) as Label)
				{
					if ((label.Text.Value == "Jump") && label.FontSize.Value.HasValue)
						return label.FontSize.Value.Value;
				}
			}
			return 0.0f;
		}
		devices.FakeTouch.Put(1, 600.0f, 300.0f);
		fixture.Frame();
		let small = JumpFont();
		Test.Assert(small >= 15.0f, scope $"{small}");
		screenRoot.ViewportSize = .(2340.0f, 1080.0f); // a phone's pixels, the game turned on it
		fixture.UI.UiContext.UpdateRootView(screenRoot);
		fixture.Frame();
		let large = JumpFont();
		Test.Assert((large > small * 1.5f) && (large > 40.0f), scope $"{small} then {large}");
		screenRoot.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(screenRoot);
		devices.FakeTouch.Points.Clear();

		// A set out of effect shows nothing.
		fixture.Input.Runtime.DisableSet("Gameplay");
		fixture.Frame();
		Test.Assert(guide.ControlCount == 0);
	}

	[Test]
	public static void ATapPressesAButtonOnAPushedScreenWithTheTouchGuideShowing()
	{
		// Snowline's title on a phone: the course cards on a screen pushed onto the screen tier,
		// the game binding touch controls (so the guide shows from the first touch). The finger
		// is id 0, as a phone's browser numbers its first finger.
		let map = TouchMap(false);
		defer delete map;
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices);
		fixture.Input.Runtime.SetMap(map);

		let screen = UIScreenTierTests.MenuFor(fixture, "t");
		fixture.UI.Screens.Push(screen);
		let root = fixture.UI.ScreenRoot;
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		var clicks = 0;
		let top = root.FindByName<Button>("t-top");
		Test.Assert(top != null);
		top.OnClick.Add(new [&clicks] (b) => { clicks++; });
		let at = top.LocalToScreen(.(20.0f, 10.0f));
		// A phone's browser may report the mouse's button down and leave it so (a synthesized
		// or unpaired press): it must neither swallow the finger's press nor click on its own.
		devices.FakeMouse.X = 700.0f;
		devices.FakeMouse.Y = 500.0f;
		devices.PressLeft();
		fixture.Frame(); // the stuck press lands away from the button, before the tap

		devices.FakeTouch.Put(0, at.X, at.Y);
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		devices.FakeTouch.Put(0, at.X + 0.5f, at.Y); // a finger never rests quite still
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		devices.FakeTouch.Points.Clear();
		fixture.Frame();
		Test.Assert(clicks == 1);
		// The stuck mouse, unmoved over the button, does nothing afterwards; released, still nothing.
		fixture.Frame();
		devices.ReleaseLeft();
		fixture.Frame();
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void AHeldFingerLeavesAButtonAsAHeldMouseDoesPressedThenClicked()
	{
		// What the player sees while a finger rests on a card: the button pressed (and hovered),
		// as under a held mouse; and after either, focus on it without the ring (a pointer's
		// focus).
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices);
		fixture.UI.Screens.Push(UIScreenTierTests.MenuFor(fixture, "h"));
		let root = fixture.UI.ScreenRoot;
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		let button = root.FindByName<Button>("h-top");
		Test.Assert(button != null);
		var clicks = 0;
		button.OnClick.Add(new [&clicks] (b) => { clicks++; });
		let at = button.LocalToScreen(.(20.0f, 10.0f));
		let focus = fixture.UI.UiContext.GetFocusManager();

		// A held mouse.
		devices.FakeMouse.X = at.X;
		devices.FakeMouse.Y = at.Y;
		devices.PressLeft();
		fixture.Frame();
		fixture.Frame();
		let mouseHeld = button.GetControlState();
		Test.Assert(Has(mouseHeld, .Pressed));
		Test.Assert(Has(mouseHeld, .Hover));
		devices.ReleaseLeft();
		fixture.Frame();
		Test.Assert(clicks == 1);
		Test.Assert(focus.FocusedView === button);
		Test.Assert(!Has(button.GetControlState(), .Focused), "no ring for a pointer's focus");

		// A held finger (id 0, as a phone): the same state while it rests, the same click and focus.
		focus.ClearFocus();
		devices.FakeTouch.Put(0, at.X, at.Y);
		fixture.Frame();
		devices.FakeTouch.Put(0, at.X + 0.5f, at.Y);
		fixture.Frame();
		Test.Assert(button.GetControlState() == mouseHeld);
		devices.FakeTouch.Points.Clear();
		fixture.Frame();
		Test.Assert(clicks == 2);
		Test.Assert(focus.FocusedView === button);
		Test.Assert(!Has(button.GetControlState(), .Focused));
	}

	[Test]
	public static void AGamesOwnActionRuntimeGetsTheTouchGuideAndTheUIsConsumption()
	{
		// The player: each game instance reads its actions in its own runtime, not the input
		// subsystem's. The guide shows that runtime's touch controls, and what the UI takes is
		// marked there too (else a tap on a menu also reached the game's actions).
		let game = scope ActionRuntime(); // the game instance's runtime
		{
			let map = TouchMap(true);
			defer delete map;
			// The Jump zone alone.
			let stick = map.Sets[0].Actions[0];
			map.Sets[0].Actions.RemoveAt(0);
			delete stick;
			game.SetMap(map);
		}
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices);
		fixture.Input.SetActionRuntimeProvider(new [=game] (visit) => { visit(game); });

		fixture.UI.Screens.Push(UIScreenTierTests.MenuFor(fixture, "p"));
		let root = fixture.UI.ScreenRoot;
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		let button = root.FindByName<Button>("p-top");
		Test.Assert(button != null);
		let at = button.LocalToScreen(.(20.0f, 10.0f));

		// A finger on the menu: the game's runtime hears the pointer is the UI's, and the guide
		// shows the game's Jump zone.
		devices.FakeTouch.Put(0, at.X, at.Y);
		fixture.Frame();
		Test.Assert(game.GetConsumptionMask().Pointer);
		Test.Assert(fixture.UI.TouchGuide.ControlCount == 1);
		devices.FakeTouch.Points.Clear();
		fixture.Frame();
		fixture.Frame();
		Test.Assert(!game.GetConsumptionMask().Pointer, "off the UI, the game has it back");
	}

	[Test]
	public static void APassThroughHudFillingTheScreenTakesThePointerOnlyAtItsControls()
	{
		// Snowline's HUD is an overlay screen whose layout fills the screen. Its layout boxes are
		// not the UI's to take: a touch on the open screen (a touch control's zone) reaches the
		// game, one on a control is the UI's, and a modal screen takes it wherever it lands.
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices);

		let hud = UIScreenTierTests.MenuFor(fixture, "hud");
		hud.Mode = .Overlay;
		{
			// Its layout stretched over the whole screen, as Snowline's HUD is.
			var fill = LayoutStyle();
			fill.Width = SizeSpec.Match();
			fill.Height = SizeSpec.Match();
			hud.SetLayout(fill);
			hud.GetChildAt(0).SetLayout(fill);
		}
		fixture.UI.Screens.Push(hud);
		let root = fixture.UI.ScreenRoot;
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		let button = root.FindByName<Button>("hud-top");
		Test.Assert(button != null);
		let onButton = button.LocalToScreen(.(20.0f, 10.0f));
		let openHit = root.HitTest(.(600.0f, 500.0f));
		Test.Assert((openHit != null) && (openHit !== root), "the HUD's layout box is what the open screen hits");

		// Open screen, inside the HUD's layout but on no control: the game's.
		devices.FakeTouch.Put(0, 600.0f, 500.0f);
		fixture.Frame();
		Test.Assert(!fixture.Input.Runtime.GetConsumptionMask().Pointer);
		devices.FakeTouch.Points.Clear();
		fixture.Frame();
		// On the HUD's button: the UI's.
		devices.FakeTouch.Put(0, onButton.X, onButton.Y);
		fixture.Frame();
		Test.Assert(fixture.Input.Runtime.GetConsumptionMask().Pointer);
		devices.FakeTouch.Points.Clear();
		fixture.Frame();

		// A modal screen shields what is below: the open screen is the UI's too.
		let pause = UIScreenTierTests.MenuFor(fixture, "pause");
		pause.Mode = .Modal;
		fixture.UI.Screens.Push(pause);
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		devices.FakeTouch.Put(0, 600.0f, 500.0f);
		fixture.Frame();
		Test.Assert(fixture.Input.Runtime.GetConsumptionMask().Pointer);
		devices.FakeTouch.Points.Clear();
		fixture.Frame();
	}
}
