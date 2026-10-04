using System;
using Sedulous.Core;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.Engine.UI.Tests;

/// The scene less screen tier: global overlays that outlive a scene swap, and the hit testing
/// contract that keeps an empty or a passive layer from shielding the interface beneath it.
class UIScreenTierTests
{
	[Test]
	public static void TheScreenTierSurvivesSceneSwapsAndStaysTopmost()
	{
		let fixture = scope UITestFixture();

		let scene = fixture.Scenes.CreateScene("level");
		let canvases = scene.GetSystem<UICanvasComponentManager>();
		let e = scene.CreateEntity("hud");
		let canvas = canvases.Add(e);
		let hudDoc = UITestFixture.MakeDocument("<Label id=\"hud\" text=\"HUD\"/>");
		defer delete hudDoc;
		canvas.Document.SetDirect(hudDoc);

		let loading = UITestFixture.MakeDocument(
			"<Panel><Label id=\"loading\" text=\"Loading...\"/></Panel>");
		defer delete loading;
		// BORROWED: the overlay layer took the reference the loader handed back.
		let overlay = fixture.UI.PushScreenOverlay(loading);
		Test.Assert(overlay != null);
		Test.Assert(fixture.UI.ScreenOverlayCount == 1);

		fixture.Frame();

		// The tier split keeps the screen root scene free: the canvas lives in ITS scene's
		// root, and the overlay rides the screen root, drawn per window target above every
		// scene.
		Test.Assert(fixture.UI.ScreenRoot.FindByName("loading") != null);
		Test.Assert(fixture.UI.ScreenRoot.FindByName("hud") == null);
		Test.Assert(fixture.UI.SceneRoot(scene).FindByName("hud") != null);

		// Destroying the scene takes its root and its canvas. The GLOBAL overlay survives.
		fixture.Scenes.DestroyScene(scene);
		fixture.Frame();
		Test.Assert(fixture.UI.ScreenOverlayCount == 1);
		Test.Assert(fixture.UI.ScreenRoot.FindByName("loading") != null);

		fixture.UI.RemoveScreenOverlay(overlay);
		Test.Assert(fixture.UI.ScreenOverlayCount == 0);
	}

	[Test]
	public static void AnEmptyOverlayLayerNeverBlocksCanvasHitTesting()
	{
		let fixture = scope UITestFixture();

		let scene = fixture.Scenes.CreateScene("level");
		let e = scene.CreateEntity("hud");
		let canvas = scene.GetSystem<UICanvasComponentManager>().Add(e);
		let document = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical"><Button id="btn" text="hit me" width="200" height="40"/></Flex>
			""");
		defer delete document;
		canvas.Document.SetDirect(document);

		fixture.Frame();
		Test.Assert(canvas.Root != null);

		// Lay both tiers out at a known size: the scene root holds the button, and the EMPTY
		// screen tier above it must not intercept anything.
		let sceneRoot = fixture.UI.SceneRoot(scene);
		let screenRoot = fixture.UI.ScreenRoot;
		Test.Assert(sceneRoot != null);
		sceneRoot.ViewportSize = .(800.0f, 600.0f);
		screenRoot.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(sceneRoot);
		fixture.UI.UiContext.UpdateRootView(screenRoot);

		let screenHit = screenRoot.HitTest(.(20.0f, 20.0f));
		Test.Assert((screenHit == null) || (screenHit == screenRoot), "an empty tier is transparent");

		let hit = sceneRoot.HitTest(.(20.0f, 20.0f));
		Test.Assert(hit != null);
		Test.Assert(hit.Name == "btn");

		// With an overlay pushed the screen tier DOES block, which a modal loading screen
		// has to.
		let loading = UITestFixture.MakeDocument(
			"""
			<Panel width="800" height="600"><Label text="Loading"/></Panel>
			""");
		defer delete loading;
		let overlay = fixture.UI.PushScreenOverlay(loading);
		Test.Assert(overlay != null);

		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(screenRoot);
		let blocked = screenRoot.HitTest(.(20.0f, 20.0f));
		Test.Assert(blocked != null);
		Test.Assert(blocked != screenRoot, "the occupied overlay layer eats the point");
	}

	[Test]
	public static void APassiveScreenOverlayNeverTurnsTheLayerModal()
	{
		let fixture = scope UITestFixture();

		// A watermark or a badge pushed with hit testing off must not flip the full window
		// overlay layer into a click shield, which is the heads up display regression; only
		// a hit testable overlay, a modal menu, claims input.
		let badgeDoc = UITestFixture.MakeDocument(
			"""
			<Panel width="80" height="24"><Label text="badge"/></Panel>
			""");
		defer delete badgeDoc;
		let badge = fixture.UI.PushScreenOverlay(badgeDoc);
		Test.Assert(badge != null);
		badge.IsHitTestVisible = false;
		Test.Assert(!fixture.UI.OverlayLayerWantsInput);

		fixture.Frame(); // the input pump applies the gate to the layer

		let screenRoot = fixture.UI.ScreenRoot;
		screenRoot.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(screenRoot);

		// Probe OUTSIDE the 80x24 badge: the layer itself must not answer. Hit test
		// visibility is self only by contract, since the toast host and the floating tool
		// layers rely on children staying hittable, so the badge's own content does still
		// answer inside its box.
		let hit = screenRoot.HitTest(.(400.0f, 300.0f));
		Test.Assert((hit == null) || (hit == screenRoot), "transparent despite the badge");

		// A modal overlay alongside it flips the layer back to input claiming.
		let menuDoc = UITestFixture.MakeDocument(
			"""
			<Panel width="800" height="600"><Label text="menu"/></Panel>
			""");
		defer delete menuDoc;
		let menu = fixture.UI.PushScreenOverlay(menuDoc);
		Test.Assert(menu != null);
		Test.Assert(fixture.UI.OverlayLayerWantsInput);
	}

	/// A menu screen of two buttons named for its run, as a game's title screen. The caller's
	/// reference is the one Push consumes.
	private static UIScreen MenuFor(UITestFixture fixture, StringView prefix)
	{
		let document = UITestFixture.MakeDocument(scope $"""
			<Flex direction="vertical" spacing="4">
			<Button id="{prefix}-top" text="Top" width="200" height="36"/>
			<Button id="{prefix}-bottom" text="Bottom" width="200" height="36"/>
			</Flex>
			""");
		defer delete document;
		let screen = new UIScreen();
		screen.AddView(fixture.UI.InstantiateScreenOverlay(document));
		return screen;
	}

	/// Two Game tabs in one editor run two games: with run screens on, each run's menus sit on
	/// its own screen tier, and navigation reaches the menu of the run whose scene the input is
	/// bound to, not the other's. Off (the player), every run shares the one tier.
	[Test]
	public static void WithRunScreensOnEachRunHasItsOwnScreensAndInputReachesTheBoundRuns()
	{
		let fixture = scope UITestFixture(true);
		let runA = scope Object();
		let runB = scope Object();

		Test.Assert(fixture.UI.ScreensFor(runA) === fixture.UI.Screens, "off: the shared tier");
		Test.Assert(fixture.UI.RunScreenCount == 0);

		fixture.UI.RunScreens = true;
		let stackA = fixture.UI.ScreensFor(runA);
		let stackB = fixture.UI.ScreensFor(runB);
		Test.Assert((stackA !== stackB) && (stackA !== fixture.UI.Screens));
		Test.Assert(fixture.UI.ScreensFor(runA) === stackA, "the same run, the same tier");
		Test.Assert(fixture.UI.ScreensFor(null) === fixture.UI.Screens);
		Test.Assert(fixture.UI.RunScreenCount == 2);
		Test.Assert(fixture.UI.ScreenRootFor(runA) !== fixture.UI.ScreenRootFor(runB));

		let sceneA = fixture.Scenes.CreateScene("a");
		let sceneB = fixture.Scenes.CreateScene("b");
		sceneA.SetRun(runA);
		sceneB.SetRun(runB);
		stackA.Push(MenuFor(fixture, "a"));
		stackB.Push(MenuFor(fixture, "b"));
		fixture.Frame();
		for (let root in RootView[2](fixture.UI.ScreenRootFor(runA), fixture.UI.ScreenRootFor(runB)))
		{
			root.ViewportSize = .(800.0f, 600.0f);
			fixture.UI.UiContext.UpdateRootView(root);
		}
		Test.Assert(fixture.UI.ScreenRootFor(runA).FindByName("a-top") != null);
		Test.Assert(fixture.UI.ScreenRootFor(runA).FindByName("b-top") == null);

		// Input bound to run B's scene (its Game tab has the keyboard): Down lands on B's menu.
		let devices = scope NavFakeDevices();
		fixture.Input.SetSourceProvider(devices, Internal.UnsafeCastToPtr(sceneB));
		let focus = fixture.UI.UiContext.GetFocusManager();
		focus.ClearFocus(); // a push focuses its screen; start from nothing focused
		devices.Pad.SetDown(.DPadDown);
		fixture.Frame();
		Test.Assert((focus.FocusedView != null) && (focus.FocusedView.Name == "b-top"));
		devices.Pad.SetDown(.DPadDown, false);
		fixture.Frame();

		// Bound to run A's: navigation moves to A's menu.
		focus.ClearFocus();
		fixture.Input.SetSourceProvider(devices, Internal.UnsafeCastToPtr(sceneA));
		devices.Pad.SetDown(.DPadDown);
		fixture.Frame();
		Test.Assert((focus.FocusedView != null) && (focus.FocusedView.Name == "a-top"));
		devices.Pad.SetDown(.DPadDown, false);

		// A run's end takes its tier and its screens; the other run's stay.
		focus.ClearFocus();
		fixture.UI.EndRunScreens(runA);
		Test.Assert(fixture.UI.RunScreenCount == 1);
		Test.Assert(fixture.UI.ScreensFor(runB) === stackB);
		Test.Assert(stackB.Count == 1);

		fixture.Input.SetSourceProvider(null);
		fixture.Scenes.DestroyScene(sceneA);
		fixture.Scenes.DestroyScene(sceneB);
	}
}
