using System;
using Sedulous.Core;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.UI;

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
}
