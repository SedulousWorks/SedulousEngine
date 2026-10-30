using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.GUI;
using Sedulous.Fonts;
using Sedulous.Fonts.Resource;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;

namespace Sedulous.Engine.GUI.Tests;

/// The subsystem's core: the screen tier (the screen stack under the overlay layer) and the scene
/// tier (a root per scene); the game's sheets in order over the theme, restyled when one is cooked
/// again; the fonts; both tiers drawn into the engine's overlay passes (the Null device, the
/// shaders from the data root), the screen's placed at the game's resolution and orientation (its
/// pointer taken to the tier's pixels), a tier per run; the overlay layer, modal while it shows;
/// an editor's preview.
class GuiSubsystemTests
{
	private static bool Near(float actual, float expected, float tolerance = 0.001f) =>
		Math.Abs(actual - expected) < tolerance;

	[Test]
	public static void TheScreenTierHoldsTheScreenStackUnderTheOverlayLayerAndEachSceneARootOfItsOwn()
	{
		let engine = scope GuiTestEngine();
		let screen = engine.Gui.ScreenRoot;
		Test.Assert(screen != null);
		Test.Assert(screen.ChildCount == 2);
		Test.Assert(screen.GetChildAt(0) === engine.Gui.Screens);
		Test.Assert(screen.GetChildAt(1) === engine.Gui.OverlayLayer);
		Test.Assert(engine.Gui.GuiContext.ResourceProvider === engine.Gui.Resources);
		Test.Assert(engine.Gui.Fonts != null);

		let level = engine.Scenes.CreateScene("level");
		let root = engine.Gui.SceneRootFor(level);
		Test.Assert(root != null);
		Test.Assert(root !== screen);
		engine.Scenes.DestroyScene(level);
		Test.Assert(engine.Gui.SceneRootFor(level) == null); // compared, never followed
		Test.Assert(engine.Gui.ScreenRoot === screen, "the screen tier outlives a scene");
	}

	[Test]
	public static void TheGamesSheetsApplyInOrderOverTheThemeRestyleWhenOneIsCookedAgainAndADocumentPushesByItsGuid()
	{
		// DECLARED FIRST so it is freed LAST: the provider lets go of its bindings through it.
		let project = scope GuiTestProject("scratch_engine_gui_sheets");
		let shared = project.Sheet("base", "#box { width: 120px; height: 10px; }");
		let game = project.Sheet("game", "#box { width: 200px; }");
		let menu = project.Document("menu", "<Screen><Panel id=\"box\"/></Screen>");
		let engine = scope GuiTestEngine();
		engine.Gui.SetResourceManager(project.Resources);
		defer engine.Gui.SetResourceManager(null); // before the project goes
		engine.Gui.SetStyleSheets(scope Guid[](shared, game));
		Test.Assert(engine.Gui.StyleSheets.Length == 2);

		let pushed = engine.Gui.Screens.PushDocument(GuiTestProject.Braced(menu, .. scope .()));
		Test.Assert(pushed != null);
		engine.Gui.ScreenRoot.ViewportSize = .(800.0f, 600.0f);
		engine.Frame();
		let @box = engine.Gui.ScreenRoot.FindElement("box");
		Test.Assert(@box != null);
		Test.Assert(Near(@box.Size.X, 200.0f), "the game's over the shared one");
		Test.Assert(Near(@box.Size.Y, 10.0f), "what it leaves is the shared one's");

		let generation = engine.Gui.SheetGeneration;
		engine.Frame();
		Test.Assert(engine.Gui.SheetGeneration == generation, "nothing changed: nothing re-applied");
		project.RewriteSheet(game, "#box { width: 150px; }");
		engine.Frame();
		Test.Assert(engine.Gui.SheetGeneration == generation + 1);
		Test.Assert(Near(@box.Size.X, 150.0f));
	}

	/// Raptor's case draws both tiers: this is its screen half, the scene half the case after.
	[Test]
	public static void TheScreenTierDrawsIntoTheEnginesOverlayPassItsLayersBeforeItsPass()
	{
		// DECLARED FIRST so it is freed LAST: the GUI's shutdown releases its renderers through it.
		let device = scope NullDevice();
		let engine = scope GuiTestEngine();
		engine.Gui.EnsureRenderReady(device, 2);
		Test.Assert(engine.Gui.IsRenderReady);
		Test.Assert(engine.Gui.GuiContext.PictureBaker != null);

		// A faded group on a screen: its layer is drawn before the screen's pass.
		let group = new Panel();
		group.Size = .(60.0f, 40.0f);
		let look = scope NodeBox();
		look.BackgroundColor = .(1.0f, 0.0f, 0.0f, 1.0f);
		group.SetBox(look);
		group.Alpha = 0.5f;
		let inner = new Panel();
		inner.Size = .(20.0f, 20.0f);
		let innerLook = scope NodeBox();
		innerLook.BackgroundColor = .(0.0f, 0.0f, 1.0f, 1.0f);
		inner.SetBox(innerLook);
		group.AddChild(inner);
		inner.ReleaseRef(); // the group holds it
		Test.Assert(engine.Gui.Screens.Push(group) != null);
		group.ReleaseRef(); // its screen holds it
		engine.Frame();

		var view = ScreenOverlayView();
		view.Width = 320;
		view.Height = 180;
		view.TargetFormat = .RGBA8UnormSrgb;
		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);

		let passesBefore = device.Counters().RenderPasses;
		engine.Gui.PrepareOverlay(encoder, view);
		let layerPasses = device.Counters().RenderPasses - passesBefore;
		Test.Assert(layerPasses == 1, "the faded group's layer, before the overlay pass opens");
		Test.Assert(Near(engine.Gui.ScreenRoot.ViewportSize.X, 320.0f));
		let pass = encoder.BeginRenderPass(.());
		Test.Assert(pass != null);
		let drawsBefore = device.Counters().Draws;
		engine.Gui.Render(pass, view);
		Test.Assert(device.Counters().Draws > drawsBefore);
		Test.Assert(device.Counters().RenderPasses - passesBefore == layerPasses + 1, "Render opened none");
		// Unprepared (another view): drawn in the pass all the same.
		let drawsUnprepared = device.Counters().Draws;
		engine.Gui.Render(pass, view);
		Test.Assert(device.Counters().Draws > drawsUnprepared);
		pass.End();
	}

	/// Raptor's case's scene half: the view's scene root, laid out at its viewport, drawn while a
	/// canvas shows something; another scene's view draws nothing of it.
	[Test]
	public static void TheSceneTierDrawsIntoTheEnginesOverlayPassForItsOwnScenesViewAlone()
	{
		let device = scope NullDevice();
		let engine = scope GuiTestEngine();
		engine.Gui.EnsureRenderReady(device, 2);
		Test.Assert(engine.Gui.IsRenderReady);

		let level = engine.Scenes.CreateScene("level");
		let root = engine.Gui.SceneRootFor(level);
		Test.Assert(root != null);
		let badge = new Panel();
		badge.Size = .(30.0f, 30.0f);
		let badgeLook = scope NodeBox();
		badgeLook.BackgroundColor = .(0.0f, 1.0f, 0.0f, 1.0f);
		badge.SetBox(badgeLook);
		// A canvas holds it: a scene's GUI draws while it shows something.
		let canvases = level.GetSystem<GuiCanvasComponentManager>();
		let hudEntity = level.CreateEntity("hud");
		let document = GuiTestEngine.MakeDocument("<Panel/>");
		defer delete document;
		canvases.Add(hudEntity).Document.SetDirect(document);
		engine.Frame();
		Test.Assert(canvases.Get(hudEntity).Root != null);
		canvases.Get(hudEntity).Root.AddChild(badge);
		badge.ReleaseRef(); // the canvas's tree holds it

		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);
		let pass = encoder.BeginRenderPass(.());
		Test.Assert(pass != null);
		var sceneView = SceneOverlayView();
		sceneView.SceneKey = Internal.UnsafeCastToPtr(level);
		sceneView.ViewportX = 160;
		sceneView.ViewportWidth = 160;
		sceneView.ViewportHeight = 180;
		sceneView.TargetWidth = 320;
		sceneView.TargetHeight = 180;
		sceneView.TargetFormat = .RGBA8Unorm;
		let drawsScene = device.Counters().Draws;
		engine.Gui.Render(pass, sceneView);
		Test.Assert(device.Counters().Draws > drawsScene);
		Test.Assert(Near(root.ViewportSize.X, 160.0f));
		// Another scene's view draws nothing of this one.
		sceneView.SceneKey = Internal.UnsafeCastToPtr(engine);
		let drawsOther = device.Counters().Draws;
		engine.Gui.Render(pass, sceneView);
		Test.Assert(device.Counters().Draws == drawsOther);
		// A scene showing nothing is not even laid out for the view.
		let empty = engine.Scenes.CreateScene("empty");
		let emptyRoot = engine.Gui.SceneRootFor(empty);
		Test.Assert(emptyRoot != null);
		let before = emptyRoot.ViewportSize;
		sceneView.SceneKey = Internal.UnsafeCastToPtr(empty);
		engine.Gui.Render(pass, sceneView);
		Test.Assert(emptyRoot.ViewportSize == before, "no canvas, no billboard: nothing done");
		pass.End();
		engine.Scenes.DestroyScene(empty);
		engine.Scenes.DestroyScene(level);
	}

	/// A font product of `family` baked at 24 pixels, with no tables: a family to resolve by name.
	private static void MakeFontProduct(Font font, StringView family)
	{
		font.SetFamily(family);
		let entry = new FontEntry();
		entry.PixelHeight = 24.0f;
		font.AddEntry(entry);
	}

	[Test]
	public static void TheProjectsFontsADefaultAndOthersEachAFamilyElseTheBuiltInFont()
	{
		// BORROWED by the GUI's service, so declared first: freed after the engine.
		let body = scope Font();
		MakeFontProduct(body, "Body");
		let title = scope Font();
		MakeFontProduct(title, "Title");
		let engine = scope GuiTestEngine();
		let builtIn = engine.Gui.Fonts;
		Test.Assert(builtIn != null);
		let others = scope Font[](title);

		engine.Gui.SetFonts(null, others);
		Test.Assert(engine.Gui.Fonts === builtIn, "others wait for a default");

		engine.Gui.SetFonts(body, others);
		let project = engine.Gui.Fonts;
		Test.Assert(project !== builtIn);
		Test.Assert(engine.Gui.GuiContext.FontService === project, "what text measures and draws with");
		Test.Assert(project.GetDefaultFontFamily(.. scope String()) == "Body");
		let bodyFont = project.GetFont("Body", 24.0f);
		let titleFont = project.GetFont("Title", 24.0f);
		Test.Assert(bodyFont != null);
		Test.Assert(titleFont != null);
		Test.Assert(titleFont !== bodyFont, "a label naming the title family gets the title face");

		engine.Gui.SetFonts(null, .());
		Test.Assert(engine.Gui.Fonts === builtIn);
		Test.Assert(engine.Gui.GuiContext.FontService === builtIn);
	}

	[Test]
	public static void TheScreenIsPlacedAsTheGamesImageIsFittedAtItsResolutionTurnedForItsOrientation()
	{
		// No resolution, any orientation: the plain draw.
		Test.Assert(!GuiSubsystem.PlaceScreen(.Zero, .Letterbox, .Any, .(1280.0f, 720.0f)).Fitted);

		// 320 by 180 fitted into 1280 by 800: letterboxed, laid out at 320 by 180 four times over.
		var place = GuiSubsystem.PlaceScreen(.(320.0f, 180.0f), .Letterbox, .Any, .(1280.0f, 800.0f));
		Test.Assert(place.Fitted);
		Test.Assert(Near(place.Rect.X, 0.0f));
		Test.Assert(Near(place.Rect.Y, 40.0f));
		Test.Assert(Near(place.Rect.Width, 1280.0f));
		Test.Assert(Near(place.Rect.Height, 720.0f));
		Test.Assert(Near(place.DrawSize.X, 1280.0f));
		Test.Assert(Near(place.DpiScale, 4.0f), "1280 / 4 = 320 laid out");

		// A landscape game on a portrait target: turned a quarter, laid out at its own shape.
		place = GuiSubsystem.PlaceScreen(.Zero, .Letterbox, .Landscape, .(720.0f, 1280.0f));
		Test.Assert(place.Fitted);
		Test.Assert(place.Turn != .None);
		Test.Assert(Near(place.DrawSize.X, 1280.0f), "the target's sides swapped");
		Test.Assert(Near(place.DrawSize.Y, 720.0f));
		Test.Assert(Near(place.Transform.M[0][0], 0.0f), "x runs down the target");
	}

	[Test]
	public static void AtARenderResolutionTheScreenTierLaysOutAtItDrawsFittedAndTakesThePointerInRenderSpace()
	{
		let device = scope NullDevice();
		let engine = scope GuiTestEngine();
		engine.Gui.EnsureRenderReady(device, 2);
		Test.Assert(engine.Gui.IsRenderReady);
		engine.Gui.SetScreenResolution(400, 300, .Letterbox);
		Test.Assert(engine.Gui.HasScreenResolution);
		let menu = GuiTestEngine.MakeMenu("play");
		Test.Assert(engine.Gui.Screens.Push(menu) != null);
		menu.ReleaseRef(); // its screen holds it

		var view = ScreenOverlayView();
		view.Width = 800;
		view.Height = 600;
		view.TargetFormat = .RGBA8UnormSrgb;
		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);
		engine.Gui.PrepareOverlay(encoder, view);
		let root = engine.Gui.ScreenRoot;
		Test.Assert(Near(root.Size.X, 400.0f), "laid out at the game's resolution");
		Test.Assert(Near(root.Size.Y, 300.0f));
		Test.Assert(Near(root.DisplayScale, 2.0f), "drawn crisp at the target's");
		let pass = encoder.BeginRenderPass(.());
		Test.Assert(pass != null);
		let draws = device.Counters().Draws;
		engine.Gui.Render(pass, view);
		Test.Assert(device.Counters().Draws > draws);
		pass.End();

		// The pointer arrives in render space (the game's fitted source): the tier takes it to its
		// pixels, against the target it last drew into.
		engine.Devices.FakeMouse.X = 50.0f;
		engine.Devices.FakeMouse.Y = 30.0f;
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === root);
		Test.Assert(Near(root.EventDispatcher.MousePosition.X, 100.0f));
		Test.Assert(Near(root.EventDispatcher.MousePosition.Y, 60.0f));

		engine.Gui.SetScreenResolution(0, 0, .Letterbox); // back to the target's own size
		Test.Assert(!engine.Gui.HasScreenResolution);
		engine.Gui.PrepareOverlay(encoder, view);
		Test.Assert(Near(root.Size.X, 800.0f));
		Test.Assert(Near(root.DisplayScale, 1.0f));
	}

	[Test]
	public static void WithRunScreensOnEachRunHasItsOwnScreenTierDrawnForItsTabAndGoneWithItsRun()
	{
		let device = scope NullDevice();
		let engine = scope GuiTestEngine();
		engine.Gui.EnsureRenderReady(device, 2);
		Test.Assert(engine.Gui.IsRenderReady);
		let runA = scope Object();
		let runB = scope Object();
		Test.Assert(engine.Gui.ScreensFor(runA) === engine.Gui.Screens, "off: one tier for every run");
		engine.Gui.RunScreens = true;
		let a = engine.Gui.ScreensFor(runA);
		let b = engine.Gui.ScreensFor(runB);
		Test.Assert(a != null);
		Test.Assert(a !== b);
		Test.Assert(a !== engine.Gui.Screens);
		Test.Assert(engine.Gui.ScreensFor(runA) === a, "made once");
		Test.Assert(engine.Gui.ScreensFor(null) === engine.Gui.Screens);
		Test.Assert(engine.Gui.RunScreenCount == 2);
		Test.Assert(a.Id == "screens", "what its scripts find under their root");

		// A's tab draws A's screens under the shared tier; a run's resolution is its own.
		let menu = GuiTestEngine.MakeMenu("play");
		Test.Assert(a.Push(menu) != null);
		menu.ReleaseRef(); // its screen holds it
		engine.Gui.SetScreenResolution(runA, 320, 180, .Letterbox);
		Test.Assert(!engine.Gui.HasScreenResolution, "the shared tier's untouched");
		var view = ScreenOverlayView();
		view.Width = 640;
		view.Height = 360;
		view.TargetFormat = .RGBA8UnormSrgb;
		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);
		engine.Gui.SetRenderRun(runA);
		engine.Gui.PrepareOverlay(encoder, view);
		Test.Assert(Near(engine.Gui.ScreenRootFor(runA).Size.X, 320.0f));
		let pass = encoder.BeginRenderPass(.());
		Test.Assert(pass != null);
		let draws = device.Counters().Draws;
		engine.Gui.Render(pass, view);
		Test.Assert(device.Counters().Draws > draws);
		pass.End();
		engine.Gui.SetRenderRun(null);

		engine.Gui.EndRunScreens(runA);
		Test.Assert(engine.Gui.RunScreenCount == 1);
		engine.Gui.EndRunScreens(runB);
		Test.Assert(engine.Gui.RunScreenCount == 0);
	}

	[Test]
	public static void ADocumentOnTheOverlayLayerShowsAboveEveryScreenModalUntilItIsTakenOff()
	{
		let engine = scope GuiTestEngine();
		engine.Gui.ScreenRoot.ViewportSize = .(800.0f, 600.0f);
		let level = engine.Scenes.CreateScene("level");
		let hud = engine.Gui.SceneRootFor(level);
		Test.Assert(hud != null);
		hud.ViewportSize = .(800.0f, 600.0f);
		let fire = GuiTestEngine.MakeButton("fire", .(20.0f, 20.0f));
		hud.AddChild(fire);
		fire.ReleaseRef(); // the scene's GUI holds it
		engine.Devices.FakeMouse.X = 50.0f;
		engine.Devices.FakeMouse.Y = 30.0f;
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === hud);

		let loading = GuiTestEngine.MakeDocument("<Panel id=\"loading\"/>");
		defer delete loading;
		let splash = engine.Gui.PushOverlay(loading);
		Test.Assert(splash != null);
		defer { if (splash != null) splash.ReleaseRef(); }
		Test.Assert(engine.Gui.OverlayCount == 1);
		Test.Assert(engine.Gui.OverlayLayer.FindElement("loading") != null);
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === engine.Gui.ScreenRoot, "modal while it shows");

		engine.Gui.RemoveOverlay(splash);
		Test.Assert(engine.Gui.OverlayCount == 0);
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === hud);

		// A passive overlay (a watermark: pointer-events none on its root) takes nothing.
		let badgeDocument = GuiTestEngine.MakeDocument("<Panel pointer-events=\"none\"><Label text=\"badge\"/></Panel>");
		defer delete badgeDocument;
		let badge = engine.Gui.PushOverlay(badgeDocument);
		Test.Assert(badge != null);
		defer { if (badge != null) badge.ReleaseRef(); }
		Test.Assert(!badge.HitTestVisible);
		engine.Frame();
		Test.Assert(engine.Gui.ActiveInputRoot === hud);
		engine.Gui.RemoveOverlay(badge);

		let empty = GuiTestEngine.MakeDocument("");
		defer delete empty;
		Test.Assert(engine.Gui.PushOverlay(empty) == null, "nothing to build");
		engine.Scenes.DestroyScene(level);
	}

	[Test]
	public static void AnEditorsPreviewBuildsInTheGuisContextASheetOverItAloneAndDrawsIntoTheEditorsTarget()
	{
		let device = scope NullDevice();
		let engine = scope GuiTestEngine();
		engine.Gui.EnsureRenderReady(device, 2);
		Test.Assert(engine.Gui.IsRenderReady);
		let found = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(found); }
		Test.Assert(engine.Gui.CreatePreview("<NoSuchElement/>", "", found) == null, "nothing builds");
		Test.Assert(!found.IsEmpty);

		let preview = engine.Gui.CreatePreview("<Panel><Panel class=\"title\" id=\"t\"/></Panel>",
			".title { width: 66px; height: 4px; }");
		Test.Assert(preview != null);
		defer { if (preview != null) preview.ReleaseRef(); }
		Test.Assert(engine.Gui.ScreenRoot.ChildCount == 2, "not in a tier: the screen's stack and overlays alone");

		var texture = device.CreateTexture(TextureDesc.RenderTarget(.RGBA8UnormSrgb, 320, 200)).Value;
		defer device.DestroyTexture(ref texture);
		var target = device.CreateTextureView(texture, .()).Value;
		defer device.DestroyTextureView(ref target);
		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);
		let passes = device.Counters().RenderPasses;
		engine.Gui.RenderPreview(preview, encoder, target, .RGBA8UnormSrgb, 320, 200, 0);
		Test.Assert(device.Counters().RenderPasses == passes + 1, "its own pass");
		Test.Assert(Near(preview.ViewportSize.X, 320.0f));
		let title = preview.FindElement("t");
		Test.Assert(title != null);
		Test.Assert(Near(title.Size.X, 66.0f), "the sheet styled it");
	}

	[Test]
	public static void AGamesTextDrawsInTheDefaultFamilyWithNoSheetNamingOneAndASheetStillChoosesItsOwn()
	{
		// The style applier gives text a font only where a family is declared: the GUI's own sheet
		// declares the default family on every tree's top elements (the editor showed text missing
		// from a document's preview before it did).
		let engine = scope GuiTestEngine();
		Test.Assert(engine.Gui.Fonts != null);
		let family = engine.Gui.Fonts.GetDefaultFontFamily(.. scope String());
		Test.Assert(!family.IsEmpty, "the built-in font loaded");
		let preview = engine.Gui.CreatePreview(
			"<Panel flex-direction=\"column\" align-items=\"center\" padding=\"24\"><Label id=\"title\" text=\"New document\"/><Button id=\"ok\" text=\"OK\"/></Panel>");
		Test.Assert(preview != null);
		defer { if (preview != null) preview.ReleaseRef(); }
		preview.ViewportSize = .(800.0f, 500.0f);
		engine.Gui.Styles.MediaContext = preview.MediaContext;
		engine.Gui.Styles.ApplyTree(preview);
		preview.UpdateLayout();
		let title = preview.FindElement("title");
		let ok = preview.FindElement("ok");
		Test.Assert(title != null);
		Test.Assert(ok != null);
		Test.Assert(title.Size.X > 0.0f, "its text measured");
		Test.Assert(title.Size.Y > 0.0f);
		Test.Assert(ok.Size.Y > 0.0f);
		Test.Assert((title as UINode).GetTextStyle().FontFamily == family);
	}

	/// A map with one action, Deliver, on `key`. The caller owns it.
	private static Sedulous.Input.InputMap MapWith(Sedulous.Shell.KeyCode key)
	{
		let map = new Sedulous.Input.InputMap();
		let set = new Sedulous.Input.ActionSet();
		set.Name.Set("Gameplay");
		let deliver = new Sedulous.Input.InputAction();
		deliver.Name.Set("Deliver");
		Sedulous.Input.Binding binding = .();
		binding.Source = .Key;
		binding.Code = (uint32)key;
		deliver.Bindings.Add(binding);
		set.Actions.Add(deliver);
		map.Sets.Add(set);
		return map;
	}

	[Test]
	public static void APromptNamesTheGamesBindingWithNoHostWiringAndFollowsARebindingAndTheRuntimeNamed()
	{
		let engine = scope GuiTestEngine();
		// The input subsystem's runtime by default.
		let e = MapWith(.E);
		defer delete e;
		engine.Input.SetMap(e);
		let prompt = new Sedulous.GUI.Prompt();
		defer prompt.ReleaseRef();
		prompt.ActionName = "Deliver";
		engine.Gui.ScreenRoot.AddChild(prompt);
		engine.Frame();
		engine.Gui.ScreenRoot.UpdateLayout();
		Test.Assert(engine.Gui.PromptRuntime === engine.Input.Runtime);
		Test.Assert(prompt.Text == "E", scope $"{prompt.Text}");

		// A rebinding (a map installed again) shows at the next frame.
		let f = MapWith(.F);
		defer delete f;
		engine.Input.SetMap(f);
		engine.Frame();
		engine.Gui.ScreenRoot.UpdateLayout();
		Test.Assert(prompt.Text == "F", scope $"{prompt.Text}");

		// The runtime the host names (a game instance's) instead.
		let game = scope Sedulous.Input.ActionRuntime();
		let g = MapWith(.G);
		defer delete g;
		game.SetMap(g);
		engine.Gui.SetPromptRuntime(game);
		engine.Frame();
		engine.Gui.ScreenRoot.UpdateLayout();
		Test.Assert(prompt.Text == "G", scope $"{prompt.Text}");
		engine.Gui.SetPromptRuntime(null);
		engine.Frame();
	}
}
