using System;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.UI;
using Sedulous.RHI.Null;
using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// World panels end to end: instantiated, rendered to their own target, driving the sprite
/// that shows them, and taking a ray routed click through whatever is drawn over them.
class UIWorldPanelTests
{
	private static bool Near(float actual, float expected) =>
		Math.Abs(actual - expected) < 0.01f;

	[Test]
	public static void AWorldPanelRendersDrivesItsSpriteAndTakesARayRoutedClick()
	{
		// Freed LAST, the fixture's teardown releasing GPU objects through it.
		let device = scope NullDevice();
		let encoder = scope NullCommandEncoder();
		let fixture = scope UITestFixture(true);
		fixture.UI.EnsureRenderReady(device, 2);

		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices);

		let scene = fixture.Scenes.CreateScene("world");
		scene.AddSystem<CameraComponentManager>();
		scene.AddSystem<SpriteComponentManager>();
		let cam = scene.CreateEntity("cam");
		scene.SetLocalPosition(cam, .(0.0f, 2.0f, 10.0f));
		scene.GetSystem<CameraComponentManager>().Add(cam);

		let e = scene.CreateEntity("kiosk");
		scene.SetLocalPosition(e, .(0.0f, 2.0f, 0.0f));
		let panels = scene.GetSystem<UIWorldPanelComponentManager>();
		Test.Assert(panels != null);

		let document = UITestFixture.MakeDocument(
			"""
			<FrameLayout><Button id="kiosk-btn" text="Press" width="200" height="100"/></FrameLayout>
			""");
		defer delete document;
		let panel = panels.Add(e);
		panel.Document.SetDirect(document);
		panel.SizeMeters = .(2.0f, 1.0f);
		panel.PixelsPerMeter = 100.0f; // a 200x100 target
		scene.UpdateTransforms();

		fixture.Frame(); // instantiate
		Test.Assert(panel.RenderRoot != null);
		fixture.UI.RenderCanvasTextures(encoder, 0);
		Test.Assert(panel.RenderTexture != null);
		Test.Assert(panel.RenderTextureView != null);
		Test.Assert(Near(panel.RenderRoot.ViewportSize.X, 200.0f));
		// The target carries a two pixel transparent border on each side for silhouette
		// antialiasing, so 200x100 of content sits in a 204x104 texture.
		Test.Assert(panel.RenderTexture.Desc.Width == 204);
		Test.Assert(panel.RenderTexture.Desc.Height == 104);

		// The sprite is DRIVEN: auto added, entity oriented, texture bound, and inflated by
		// the border ratio so the CONTENT keeps the authored world size.
		let sprite = scene.GetSystem<SpriteComponentManager>().Get(e);
		Test.Assert(sprite != null);
		Test.Assert(sprite.Orientation == .EntityOriented);
		Test.Assert(Near(sprite.Size.X, 2.0f * 204.0f / 200.0f));
		Test.Assert(Near(sprite.Size.Y, 1.0f * 104.0f / 100.0f));
		Test.Assert(sprite.Texture == panel.RenderTextureView);

		// Route a click: lay the scene root out, that being the surface size the ray math
		// reads, then point at the view centre where the camera looks straight at the panel.
		let sceneRoot = fixture.UI.SceneRoot(scene);
		Test.Assert(sceneRoot != null);
		sceneRoot.ViewportSize = .(800.0f, 600.0f);

		bool clicked = false;
		panel.RenderRoot.FindByName<Button>("kiosk-btn").OnClick.Add(
			new [&clicked](b) => { clicked = true; });

		devices.MoveTo(400.0f, 300.0f);
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == panel.RenderRoot);
		Test.Assert(fixture.UI.PointerOverUI);

		devices.PressLeft();
		fixture.Frame();
		devices.ReleaseLeft();
		fixture.Frame();
		Test.Assert(clicked);

		// Non interactive: the ray ignores it and the pointer stops routing to the panel.
		panel.Interactive = false;
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot != panel.RenderRoot);
	}

	/// The kiosk regression: CanvasHostView stretches every document to the viewport, so the
	/// document's root has to stay hit TRANSPARENT. Otherwise one heads up display eats the
	/// pointer everywhere, consumption reads true over empty space and gameplay clicks die,
	/// and the scene root outbids every world panel.
	[Test]
	public static void AStretchedFullScreenCanvasDoesNotSwallowThePointer()
	{
		// Freed LAST, the fixture's teardown releasing GPU objects through it.
		let device = scope NullDevice();
		let encoder = scope NullCommandEncoder();
		let fixture = scope UITestFixture(true);
		fixture.UI.EnsureRenderReady(device, 2);
		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices);

		let scene = fixture.Scenes.CreateScene("world");
		scene.AddSystem<CameraComponentManager>();
		scene.AddSystem<SpriteComponentManager>();
		let cam = scene.CreateEntity("cam");
		scene.SetLocalPosition(cam, .(0.0f, 2.0f, 10.0f));
		scene.GetSystem<CameraComponentManager>().Add(cam);

		// A stretched root Flex with its content in one corner.
		let hudDoc = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical" align="start" padding="12">
			<Button id="hud-btn" text="HUD" width="180" height="36"/></Flex>
			""");
		defer delete hudDoc;
		let hud = scene.CreateEntity("hud");
		scene.GetSystem<UICanvasComponentManager>().Add(hud).Document.SetDirect(hudDoc);

		// And a world panel mid view.
		let panelDoc = UITestFixture.MakeDocument(
			"""
			<FrameLayout><Button id="kiosk-btn" text="Tap" width="200" height="100"/></FrameLayout>
			""");
		defer delete panelDoc;
		let kiosk = scene.CreateEntity("kiosk");
		scene.SetLocalPosition(kiosk, .(0.0f, 2.0f, 0.0f));
		let panel = scene.GetSystem<UIWorldPanelComponentManager>().Add(kiosk);
		panel.Document.SetDirect(panelDoc);
		panel.SizeMeters = .(2.0f, 1.0f);
		panel.PixelsPerMeter = 100.0f;
		scene.UpdateTransforms();

		fixture.Frame();
		fixture.UI.RenderCanvasTextures(encoder, 0);
		let sceneRoot = fixture.UI.SceneRoot(scene);
		sceneRoot.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(sceneRoot);

		// Over the heads up display's button: the scene root wins and consumption is true.
		devices.MoveTo(30.0f, 30.0f);
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == sceneRoot);
		Test.Assert(fixture.UI.PointerOverUI);

		// At the view CENTRE, which is empty display space with the kiosk dead ahead: the
		// panel is reachable THROUGH the stretched display, and the hit consumes.
		devices.MoveTo(400.0f, 300.0f);
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == panel.RenderRoot);
		Test.Assert(fixture.UI.PointerOverUI);

		// Over truly empty space, with no panel behind it: NOT consumed, so a gameplay
		// click passes through.
		panel.Visible = false;
		fixture.Frame();
		Test.Assert(!fixture.UI.PointerOverUI);
	}

	/// The crosshair shove regression: a press parks on the RootView so the release still
	/// routes, but a root press is NOT interaction. Before the fix ANY held click published
	/// a consumed mask for the press's whole duration, which gated the gameplay poll that
	/// runs on exactly the press frame.
	[Test]
	public static void APressOverEmptySpaceNeverConsumesThePointer()
	{
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices);

		let document = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical" align="start" padding="12">
			<Button id="hud-btn" text="HUD" width="180" height="36"/></Flex>
			""");
		defer delete document;
		let scene = fixture.Scenes.CreateScene("world");
		let hud = scene.CreateEntity("hud");
		scene.GetSystem<UICanvasComponentManager>().Add(hud).Document.SetDirect(document);

		fixture.Frame();
		let sceneRoot = fixture.UI.SceneRoot(scene);
		Test.Assert(sceneRoot != null);
		sceneRoot.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(sceneRoot);

		// Press and hold over empty space: never consumed, on the press frame or held.
		devices.MoveTo(400.0f, 300.0f);
		fixture.Frame();
		Test.Assert(!fixture.UI.PointerOverUI);
		devices.PressLeft();
		fixture.Frame(); // the press frame, where the gameplay poll runs
		Test.Assert(!fixture.UI.PointerOverUI);
		fixture.Frame(); // still held
		Test.Assert(!fixture.UI.PointerOverUI);
		devices.ReleaseLeft();
		fixture.Frame();
		Test.Assert(!fixture.UI.PointerOverUI);

		// Pressed ON the button: consumed while held, which is the intended consumption.
		devices.MoveTo(30.0f, 30.0f);
		fixture.Frame();
		Test.Assert(fixture.UI.PointerOverUI);
		devices.PressLeft();
		fixture.Frame();
		Test.Assert(fixture.UI.PointerOverUI);
		devices.ReleaseLeft();
		fixture.Frame();
	}
}
