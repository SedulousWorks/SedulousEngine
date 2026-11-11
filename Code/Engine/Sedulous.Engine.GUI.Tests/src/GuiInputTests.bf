using System;
using Sedulous.Core;
using Sedulous.Engine.GUI;
using Sedulous.GUI;

namespace Sedulous.Engine.GUI.Tests;

/// The input: where it goes (the root whose GUI is under the pointer, else the screens a game
/// pushed), a press kept by its root, what the action layer hears beside an earlier claim, the
/// keys and Back, and a source bound to another scene. A fitted tier's pointer, the overlay layer
/// modal and a world panel's pointer are with the cases they extend (GuiSubsystemTests.bf,
/// GuiComponentSyncTests.bf).
class GuiInputTests
{
	[Test]
	public static void InputGoesToTheRootWhoseGuiIsUnderThePointerAClickLandsAndTheActionLayerHearsWhatTheGuiTook()
	{
		let engine = scope GuiTestEngine();
		let mouse = engine.Devices.FakeMouse;
		let level = engine.Scenes.CreateScene("level");
		let hud = engine.Gui.SceneRootFor(level);
		Test.Assert(hud != null);
		hud.ViewportSize = .(800.0f, 600.0f);
		let button = GuiTestEngine.MakeButton("fire", .(20.0f, 20.0f));
		hud.AddChild(button);
		int clicks = 0;
		button.AddEventListener(.MouseClick, new [&] (e) => { clicks++; });
		button.ReleaseRef(); // the scene's GUI holds it
		engine.Gui.ScreenRoot.ViewportSize = .(800.0f, 600.0f);
		engine.Frame();

		// Over the button: the scene's root takes the input, and the pointer is the GUI's.
		mouse.X = 50.0f;
		mouse.Y = 30.0f;
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === hud);
		Test.Assert(engine.Gui.PointerOverGui);
		Test.Assert(engine.PointerClaimed);
		mouse.Down = true;
		engine.Frame();
		mouse.Down = false;
		engine.Frame();
		Test.Assert(clicks == 1);

		// Over empty space: the game's pointer; and the frame's end clears the claim.
		mouse.X = 500.0f;
		engine.Frame();
		Test.Assert(!engine.Gui.PointerOverGui);
		Test.Assert(!engine.PointerClaimed);
		mouse.X = 50.0f;
		engine.Frame();
		Test.Assert(engine.PointerClaimed);
		engine.Context.EndFrame();
		Test.Assert(!engine.PointerClaimed);

		// The earlier claim (made first in the lane) stands though the GUI takes nothing.
		engine.Claiming.Claims = true;
		mouse.X = 500.0f;
		engine.Frame();
		Test.Assert(!engine.Gui.PointerOverGui);
		Test.Assert(engine.PointerClaimed);
		engine.Claiming.Claims = false;
		engine.Context.EndFrame();

		// A press stays with the root it began in until it is let go.
		mouse.X = 50.0f;
		mouse.Down = true;
		engine.Frame();
		let menu = new UIWidget();
		let menuButton = GuiTestEngine.MakeButton("menu", .(400.0f, 20.0f));
		menu.AddChild(menuButton);
		menuButton.ReleaseRef(); // the menu holds it
		Test.Assert(engine.Gui.Screens.Push(menu) != null);
		menu.ReleaseRef(); // its screen holds it
		mouse.X = 450.0f; // over the screen's button now, still held
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === hud);
		Test.Assert(engine.PointerClaimed, "it began over the GUI");
		mouse.Down = false;
		engine.Frame();
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === engine.Gui.ScreenRoot);
		engine.Scenes.DestroyScene(level);
		Test.Assert(engine.Gui.ActiveInputRoot !== hud); // compared, never followed
	}

	[Test]
	public static void WithNoGuiUnderThePointerTheKeysGoToTheScreensAGamePushedAndBackPopsOne()
	{
		let engine = scope GuiTestEngine();
		engine.Gui.ScreenRoot.ViewportSize = .(800.0f, 600.0f);
		let title = GuiTestEngine.MakeMenu("play");
		Test.Assert(engine.Gui.Screens.Push(title) != null);
		title.ReleaseRef(); // its screen holds it
		let settings = GuiTestEngine.MakeMenu("back");
		Test.Assert(engine.Gui.Screens.Push(settings) != null);
		settings.ReleaseRef();
		engine.Frame();
		engine.Frame();
		Test.Assert(engine.Gui.Screens.Count == 2);
		engine.Devices.Key(.Escape);
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === engine.Gui.ScreenRoot);
		Test.Assert(engine.Gui.Screens.Count == 1);
	}

	/// A back press nothing handles is unhandled; a screen that pops or a binding handles it.
	[Test]
	public static void ABackPressNothingHandlesIsUnhandledAScreenThatPopsOrABindingHandlesIt()
	{
		let engine = scope GuiTestEngine();
		engine.Gui.ScreenRoot.ViewportSize = .(800.0f, 600.0f);
		engine.Frame();
		Test.Assert(!engine.Gui.BackUnhandled);

		// No screen, no binding: nothing handles it (a phone's platform takes it).
		engine.Devices.Key(.Back);
		engine.Frame();
		Test.Assert(engine.Gui.BackUnhandled);
		engine.Frame();
		Test.Assert(!engine.Gui.BackUnhandled, "only the frame it was pressed in");

		// A screen over another backs out with it, as with Escape.
		let title = GuiTestEngine.MakeMenu("play");
		Test.Assert(engine.Gui.Screens.Push(title) != null);
		title.ReleaseRef(); // its screen holds it
		let settings = GuiTestEngine.MakeMenu("back");
		Test.Assert(engine.Gui.Screens.Push(settings) != null);
		settings.ReleaseRef();
		engine.Frame();
		engine.Devices.Key(.Back);
		engine.Frame();
		Test.Assert(engine.Gui.Screens.Count == 1);
		Test.Assert(!engine.Gui.BackUnhandled);
		engine.Gui.Screens.Pop();
		engine.Frame();

		// An action the game binds to it handles it.
		let map = scope Sedulous.Input.InputMap();
		let set = new Sedulous.Input.ActionSet();
		set.Name.Set("Gameplay");
		let pause = new Sedulous.Input.InputAction();
		pause.Name.Set("Pause");
		var back = Sedulous.Input.Binding();
		back.Source = .Key;
		back.Code = (uint32)Sedulous.Shell.KeyCode.Back;
		pause.Bindings.Add(back);
		set.Actions.Add(pause);
		map.Sets.Add(set);
		engine.Input.SetMap(map);
		engine.Devices.Key(.Back);
		engine.Frame();
		Test.Assert(!engine.Gui.BackUnhandled);
	}

	[Test]
	public static void ASourceBoundToAnotherSceneNeverReachesThisScenesGui()
	{
		let engine = scope GuiTestEngine();
		let mouse = engine.Devices.FakeMouse;
		let level = engine.Scenes.CreateScene("level");
		let other = engine.Scenes.CreateScene("other");
		let hud = engine.Gui.SceneRootFor(level);
		Test.Assert(hud != null);
		hud.ViewportSize = .(800.0f, 600.0f);
		let button = GuiTestEngine.MakeButton("fire", .(20.0f, 20.0f));
		hud.AddChild(button);
		button.ReleaseRef(); // the scene's GUI holds it
		mouse.X = 50.0f;
		mouse.Y = 30.0f;
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === hud);
		// An editor Game tab on the other scene.
		engine.Input.SetSourceProvider(engine.Devices, Internal.UnsafeCastToPtr(other));
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot !== hud);
		Test.Assert(!engine.Gui.PointerOverGui);
		engine.Input.SetSourceProvider(engine.Devices, Internal.UnsafeCastToPtr(level));
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === hud);
		engine.Scenes.DestroyScene(other);
		engine.Scenes.DestroyScene(level);
	}
}
