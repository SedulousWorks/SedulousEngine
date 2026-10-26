using System;
using Sedulous.Core;
using Sedulous.Engine.GUI;
using Sedulous.Engine.Render;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;

namespace Sedulous.Engine.GUI.Tests;

/// The components as the subsystem runs them: a canvas's tree in its scene's root (ordered,
/// shown, inert, rebuilt, swept, scaled, its own sheet), billboards placed as each view draws, a
/// render-texture canvas's texture shown on its entity's sprite, and a world panel's sprite.
class GuiComponentSyncTests
{
	private static bool Near(float actual, float expected, float tolerance = 0.001f) =>
		Math.Abs(actual - expected) < tolerance;

	/// The scene's GUI styled and laid out at `size`, as a frame's draw does.
	private static void LayOut(GuiSubsystem gui, SceneRoot root, Float2 size)
	{
		root.ViewportSize = size;
		gui.Styles.MediaContext = root.MediaContext;
		gui.Styles.ApplyTree(root);
		root.UpdateLayout();
	}

	/// A projection a test reads at a glance: clip = (x, y, z, z), so a point's place on screen
	/// is (x / z, y / z) and it is behind the camera when z <= 0.
	private static Float4x4 SimpleProjection()
	{
		var m = Float4x4.Identity();
		m.M[2][3] = 1.0f;
		m.M[3][3] = 0.0f;
		return m;
	}

	/// Raptor's case names input too: what a canvas takes is its tree's inertness, checked here;
	/// the pointer reaching it is the input pump's (E4), with its own cases.
	[Test]
	public static void ACanvasShowsItsDocumentInItsScenesGuiOrderedShownAndTakingInputAsItSaysRebuiltWhenItsDocumentChangesGoneWhenDespawned()
	{
		let engine = scope GuiTestEngine();
		let level = engine.Scenes.CreateScene("level");
		let canvases = level.GetSystem<GuiCanvasComponentManager>();
		Test.Assert(canvases != null, "installed by the scene composition");
		let hud = level.CreateEntity("hud");
		let pause = level.CreateEntity("pause");
		// BORROWED by the components, which compare them and never free them.
		let pauseMenu = GuiTestEngine.MakeDocument("<Panel id=\"pause-menu\"/>");
		defer delete pauseMenu;
		let score = GuiTestEngine.MakeDocument("<Panel id=\"score\"/>");
		defer delete score;
		let lives = GuiTestEngine.MakeDocument("<Panel id=\"lives\"/>");
		defer delete lives;
		{
			let c = canvases.Add(pause);
			c.Document.SetDirect(pauseMenu);
			c.Order = 5;
		}
		{
			let c = canvases.Add(hud);
			c.Document.SetDirect(score);
			c.Order = 1;
		}
		engine.Frame();
		let root = engine.Gui.SceneRootFor(level);
		Test.Assert(root != null);
		Test.Assert(root.ChildCount == 3, "the billboards' layer, then the canvases");
		Test.Assert((root.GetChildAt(0) as UIWidget).Tag == "billboards");
		Test.Assert(root.GetChildAt(1).FindElement("score") != null, "order 1 under order 5");
		Test.Assert(root.GetChildAt(2).FindElement("pause-menu") != null);
		Test.Assert((root.GetChildAt(1) as UIWidget).Tag == "canvas");

		// Reordered.
		canvases.Get(hud).Order = 9;
		engine.Frame();
		Test.Assert(root.GetChildAt(2).FindElement("score") != null);

		// Hidden, then its entity inactive; not interactive.
		let tree = canvases.Get(hud).Root;
		Test.Assert(tree != null);
		canvases.Get(hud).Visible = false;
		engine.Frame();
		Test.Assert(!tree.Displayed);
		canvases.Get(hud).Visible = true;
		level.SetActive(hud, false);
		engine.Frame();
		Test.Assert(!tree.Displayed);
		level.SetActive(hud, true);
		canvases.Get(hud).Interactive = false;
		engine.Frame();
		Test.Assert(tree.Displayed);
		Test.Assert(tree.IsTreeInert);

		// A new document product rebuilds the tree.
		canvases.Get(hud).Document.SetDirect(lives);
		engine.Frame();
		Test.Assert(root.FindElement("lives") != null);
		Test.Assert(root.FindElement("score") == null);

		// Despawned: its host goes.
		level.DestroyEntity(hud);
		engine.Frame();
		Test.Assert(root.ChildCount == 2);
		Test.Assert(root.FindElement("lives") == null);
		engine.Scenes.DestroyScene(level);
	}

	[Test]
	public static void ACanvasScaledFromAReferenceResolutionFitsTheViewCentredAtConstantPixelsItFillsIt()
	{
		let engine = scope GuiTestEngine();
		let level = engine.Scenes.CreateScene("level");
		let canvases = level.GetSystem<GuiCanvasComponentManager>();
		let hud = level.CreateEntity("hud");
		let frame = GuiTestEngine.MakeDocument("<Panel id=\"frame\"/>");
		defer delete frame;
		{
			let added = canvases.Add(hud);
			added.Document.SetDirect(frame);
			added.ScalerMode = .ReferenceResolution;
			added.ReferenceResolution = .(400.0f, 300.0f);
		}
		engine.Frame();
		let root = engine.Gui.SceneRootFor(level);
		let tree = canvases.Get(hud).Root;
		Test.Assert(tree != null);

		LayOut(engine.Gui, root, .(1000.0f, 600.0f));
		Test.Assert(Near(tree.Size.X, 400.0f), "laid out at the reference");
		Test.Assert(Near(tree.Size.Y, 300.0f));
		Test.Assert(Near(tree.Scale.X, 2.0f), "scaled to fit the height");
		Test.Assert(Near(tree.Position.X, 100.0f), "centred across");
		Test.Assert(Near(tree.Position.Y, 0.0f));

		canvases.Get(hud).ScalerMode = .ConstantPixel;
		engine.Frame();
		LayOut(engine.Gui, root, .(1000.0f, 600.0f));
		Test.Assert(Near(tree.Size.X, 1000.0f));
		Test.Assert(Near(tree.Scale.X, 1.0f));
		engine.Scenes.DestroyScene(level);
	}

	[Test]
	public static void ACanvasesOwnSheetStylesItsDocumentAloneOverTheGames()
	{
		let engine = scope GuiTestEngine();
		let level = engine.Scenes.CreateScene("level");
		let canvases = level.GetSystem<GuiCanvasComponentManager>();
		let styled = level.CreateEntity("styled");
		let plain = level.CreateEntity("plain");
		let sheet = scope GuiStyleSheet();
		sheet.Css.Set(".title { width: 77px; height: 5px; }");
		// The root is the canvas's area: the titles inside it are what the sheet sizes.
		let styledDocument = GuiTestEngine.MakeDocument("<Panel><Panel class=\"title\" id=\"a\"/></Panel>");
		defer delete styledDocument;
		let plainDocument = GuiTestEngine.MakeDocument("<Panel><Panel class=\"title\" id=\"b\"/></Panel>");
		defer delete plainDocument;
		{
			let c = canvases.Add(styled);
			c.Document.SetDirect(styledDocument);
			c.Sheet.SetDirect(sheet);
		}
		canvases.Add(plain).Document.SetDirect(plainDocument);
		engine.Frame();
		let root = engine.Gui.SceneRootFor(level);
		LayOut(engine.Gui, root, .(800.0f, 600.0f));
		let a = root.FindElement("a");
		let b = root.FindElement("b");
		Test.Assert(a != null);
		Test.Assert(b != null);
		Test.Assert(Near(a.Size.X, 77.0f));
		Test.Assert(!Near(b.Size.X, 77.0f));
		engine.Scenes.DestroyScene(level);
	}

	[Test]
	public static void BillboardsLiveInALayerUnderTheCanvasesPlacedAsEachViewDrawsAndGoWhenDespawned()
	{
		// DECLARED FIRST so it is freed LAST: the GUI's shutdown releases its renderers through it.
		let device = scope NullDevice();
		let engine = scope GuiTestEngine();
		engine.Gui.EnsureRenderReady(device, 2);
		Test.Assert(engine.Gui.IsRenderReady);
		let level = engine.Scenes.CreateScene("level");
		let billboards = level.GetSystem<GuiBillboardComponentManager>();
		Test.Assert(billboards != null);
		let guard = level.CreateEntity("guard");
		level.SetLocalPosition(guard, .(0.0f, 0.0f, 1.0f));
		level.UpdateTransforms();
		let plateDocument = GuiTestEngine.MakeDocument("<Panel width=\"40\" height=\"20\" id=\"plate\"/>");
		defer delete plateDocument;
		billboards.Add(guard).Document.SetDirect(plateDocument);
		engine.Frame();
		let root = engine.Gui.SceneRootFor(level);
		let layer = root.GetChildAt(0);
		Test.Assert(layer.ChildCount == 1);
		let plate = billboards.Get(guard).Root;
		Test.Assert(plate === layer.GetChildAt(0));

		var view = SceneOverlayView();
		view.SceneKey = Internal.UnsafeCastToPtr(level);
		view.ViewProjection = SimpleProjection();
		view.ViewportWidth = 200;
		view.ViewportHeight = 100;
		view.TargetWidth = 200;
		view.TargetHeight = 100;
		view.TargetFormat = .RGBA8Unorm;
		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);
		let pass = encoder.BeginRenderPass(.());
		Test.Assert(pass != null);
		engine.Gui.Render(pass, view); // its size is known after this layout
		engine.Gui.Render(pass, view);
		Test.Assert(Near(plate.Size.X, 40.0f));
		Test.Assert(Near(plate.Position.X, 80.0f), "centred on 100");
		Test.Assert(Near(plate.Position.Y, 30.0f), "its bottom on 50");
		Test.Assert(plate.Visible);

		level.SetLocalPosition(guard, .(0.0f, 0.0f, -1.0f)); // behind the camera
		level.UpdateTransforms();
		engine.Gui.Render(pass, view);
		Test.Assert(!plate.Visible);
		pass.End();

		level.DestroyEntity(guard);
		engine.Frame();
		Test.Assert(layer.ChildCount == 0);
		engine.Scenes.DestroyScene(level);
	}

	[Test]
	public static void ARenderTextureCanvasDrawsIntoATextureOfItsOwnItsEntitysSpriteShowsItAndItGoesWithTheCanvas()
	{
		let device = scope NullDevice();
		let engine = scope GuiTestEngine();
		engine.Gui.EnsureRenderReady(device, 2);
		Test.Assert(engine.Gui.IsRenderReady);
		let level = engine.Scenes.CreateScene("level");
		// The render managers come from the render subsystem normally; added by hand here.
		level.AddSystem<SpriteComponentManager>();
		let sprites = level.GetSystem<SpriteComponentManager>();
		let canvases = level.GetSystem<GuiCanvasComponentManager>();
		let screen = level.CreateEntity("screen");
		sprites.Add(screen);
		let monitor = GuiTestEngine.MakeDocument("<Panel id=\"monitor\"/>");
		defer delete monitor;
		{
			let added = canvases.Add(screen);
			added.Document.SetDirect(monitor);
			added.RenderMode = .RenderTexture;
			added.RenderTextureWidth = 128;
			added.RenderTextureHeight = 64;
		}
		engine.Frame();
		Test.Assert(canvases.Get(screen).RenderRoot != null);
		let root = engine.Gui.SceneRootFor(level);
		Test.Assert(root.ChildCount == 1, "the billboards' layer alone: not in the scene's GUI");
		Test.Assert(canvases.Get(screen).RenderRoot.FindElement("monitor") != null);

		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);
		let passesBefore = device.Counters().RenderPasses;
		engine.Gui.RenderTextures(encoder, 0);
		Test.Assert(engine.Gui.TextureCount == 1);
		let c = canvases.Get(screen);
		Test.Assert(c.RenderTextureView != null);
		Test.Assert(sprites.Get(screen).Texture === c.RenderTextureView);
		Test.Assert(Near(c.RenderRoot.ViewportSize.X, 128.0f));
		let passes = device.Counters().RenderPasses;
		Test.Assert(passes > passesBefore, "its own pass");
		engine.Gui.RenderTextures(encoder, 0); // once a frame
		Test.Assert(device.Counters().RenderPasses == passes);

		// Back over the view: in the scene's GUI again, the texture let go next time.
		canvases.Get(screen).RenderMode = .ScreenOverlay;
		engine.Frame();
		Test.Assert(root.FindElement("monitor") != null);
		engine.Gui.RenderTextures(encoder, 1);
		Test.Assert(engine.Gui.TextureCount == 0);
		Test.Assert(sprites.Get(screen).Texture == null);

		// Into a texture again, then despawned: the texture goes.
		canvases.Get(screen).RenderMode = .RenderTexture;
		engine.Frame();
		engine.Gui.RenderTextures(encoder, 0);
		Test.Assert(engine.Gui.TextureCount == 1);
		level.DestroyEntity(screen);
		engine.Frame();
		engine.Gui.RenderTextures(encoder, 1);
		Test.Assert(engine.Gui.TextureCount == 0);
		engine.Scenes.DestroyScene(level);
	}

	/// Raptor's case goes on to the pointer reaching the panel by a ray through the scene's
	/// camera (hovered, clicked, the action layer told); that part waits for the input pump (E4).
	[Test]
	public static void AWorldPanelDrivesItsSprite()
	{
		let device = scope NullDevice();
		let engine = scope GuiTestEngine();
		engine.Gui.EnsureRenderReady(device, 2);
		Test.Assert(engine.Gui.IsRenderReady);
		let level = engine.Scenes.CreateScene("level");
		level.AddSystem<SpriteComponentManager>();
		let sprites = level.GetSystem<SpriteComponentManager>();
		let kiosk = level.CreateEntity("kiosk");
		level.SetLocalPosition(kiosk, .(0.0f, 2.0f, 0.0f));
		level.UpdateTransforms();
		let panels = level.GetSystem<GuiWorldPanelComponentManager>();
		let tap = GuiTestEngine.MakeDocument("<Button id=\"tap\" text=\"Tap\"/>");
		defer delete tap;
		{
			let added = panels.Add(kiosk);
			added.Document.SetDirect(tap);
			added.SizeMeters = .(2.0f, 1.0f);
			added.PixelsPerMeter = 100.0f;
		}
		engine.Frame();
		Test.Assert(panels.Get(kiosk).RenderRoot != null);
		Test.Assert(sprites.Get(kiosk) == null);

		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);
		engine.Gui.RenderTextures(encoder, 0);
		let c = panels.Get(kiosk);
		let sprite = sprites.Get(kiosk);
		Test.Assert(sprite != null, "added for it");
		Test.Assert(c.RenderTextureView != null);
		Test.Assert(sprite.Texture === c.RenderTextureView);
		Test.Assert(sprite.Orientation == .EntityOriented);
		Test.Assert(sprite.PostTonemap);
		Test.Assert(sprite.Visible);
		Test.Assert(Near(sprite.Size.X, 2.0f * 204.0f / 200.0f), "the transparent edge's share");
		Test.Assert(Near(c.RenderRoot.ViewportSize.X, 200.0f));
		engine.Scenes.DestroyScene(level);
	}
}
