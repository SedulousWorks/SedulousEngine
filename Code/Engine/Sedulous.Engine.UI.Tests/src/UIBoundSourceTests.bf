using System;
using Sedulous.Engine.Input;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// Which scene a source speaks for: routing, consumption and keyboard all confined to the
/// bound one, and the editor policy that keeps un-bound input out of scene interfaces.
class UIBoundSourceTests
{
	[Test]
	public static void ABoundSourceConfinesRoutingAndConsumptionToItsScene()
	{
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices); // un-bound, so the AllScenes default holds

		// Two scenes, each with an interactive button at the SAME coordinates, which is the
		// historical edge: probing in creation order can answer for the wrong scene.
		let docA = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical"><Button id="btn-a" text="A" width="200" height="40"/></Flex>
			""");
		defer delete docA;
		let sceneA = fixture.Scenes.CreateScene("a");
		let ea = sceneA.CreateEntity("hud-a");
		sceneA.GetSystem<UICanvasComponentManager>().Add(ea).Document.SetDirect(docA);

		let docB = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical">
			<Button id="btn-b" text="B" width="200" height="40"/>
			<EditText id="field-b" width="200" height="30"/>
			</Flex>
			""");
		defer delete docB;
		let sceneB = fixture.Scenes.CreateScene("b");
		let eb = sceneB.CreateEntity("hud-b");
		sceneB.GetSystem<UICanvasComponentManager>().Add(eb).Document.SetDirect(docB);

		fixture.Frame(); // instantiate both trees
		let rootA = fixture.UI.SceneRoot(sceneA);
		let rootB = fixture.UI.SceneRoot(sceneB);
		Test.Assert(rootA != null);
		Test.Assert(rootB != null);
		rootA.ViewportSize = .(800.0f, 600.0f);
		rootB.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(rootA);
		fixture.UI.UiContext.UpdateRootView(rootB);

		bool clickedA = false;
		bool clickedB = false;
		rootA.FindByName<Button>("btn-a").OnClick.Add(new [&clickedA](b) => { clickedA = true; });
		rootB.FindByName<Button>("btn-b").OnClick.Add(new [&clickedB](b) => { clickedB = true; });

		// UN-BOUND, the AllScenes default: the pointer probe walks the scene roots in
		// creation order, so scene A wins the overlapping point.
		devices.MoveTo(50.0f, 20.0f);
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == rootA);
		Test.Assert(fixture.Input.Runtime.GetConsumptionMask().Pointer);

		// BOUND to scene B: the same coordinates route to B, and ONLY B. The click fires
		// B's button, and A's identical button at the identical point never hears it.
		fixture.Input.SetSourceProvider(devices, Internal.UnsafeCastToPtr(sceneB));
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == rootB);
		Test.Assert(fixture.Input.Runtime.GetConsumptionMask().Pointer);
		devices.PressLeft();
		fixture.Frame();
		devices.ReleaseLeft();
		fixture.Frame();
		Test.Assert(clickedB);
		Test.Assert(!clickedA);

		// Pointer less frames, the pad or keyboard only path: the fallback root is the
		// BOUND scene rather than the first scene holding content.
		devices.MousePresent = false;
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == rootB);

		// Keyboard and text follow the binding too.
		let field = rootB.FindByName<EditText>("field-b");
		Test.Assert(field != null);
		fixture.UI.UiContext.GetFocusManager().SetFocus(field);
		devices.PushText("go");
		fixture.Frame();
		devices.Queue.Clear();
		Test.Assert(field.Text == "go");
		Test.Assert(fixture.Input.Runtime.GetConsumptionMask().Keyboard);
		fixture.UI.UiContext.GetFocusManager().ClearFocus();

		// Un-binding, the provider kept, returns to the un-bound default: creation order.
		devices.MousePresent = true;
		fixture.Input.SetSourceProvider(devices, null);
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == rootA);
	}

	[Test]
	public static void ScreenTierOnlyKeepsUnboundInputOutOfSceneUi()
	{
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		fixture.Input.SetSourceProvider(devices); // un-bound...
		fixture.Input.UnboundScenePolicy = .ScreenTierOnly;

		let document = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical"><Button id="btn" text="hud" width="200" height="40"/></Flex>
			""");
		defer delete document;
		let scene = fixture.Scenes.CreateScene("editing");
		let e = scene.CreateEntity("hud");
		scene.GetSystem<UICanvasComponentManager>().Add(e).Document.SetDirect(document);

		fixture.Frame();
		let root = fixture.UI.SceneRoot(scene);
		Test.Assert(root != null);
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.ScreenRoot.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(root);
		fixture.UI.UiContext.UpdateRootView(fixture.UI.ScreenRoot);

		bool clicked = false;
		root.FindByName<Button>("btn").OnClick.Add(new [&clicked](b) => { clicked = true; });

		// The heads up display renders, its tree existing and visible, but is NOT
		// interactive: a pointer over its button neither routes to the scene root nor
		// publishes consumption, so an editor pane click at these coordinates stays an
		// editor click.
		devices.MoveTo(50.0f, 20.0f);
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == fixture.UI.ScreenRoot);
		Test.Assert(!fixture.Input.Runtime.GetConsumptionMask().Pointer);
		Test.Assert(!fixture.UI.PointerOverUI);
		devices.PressLeft();
		fixture.Frame();
		devices.ReleaseLeft();
		fixture.Frame();
		Test.Assert(!clicked);

		// The scene less screen tier is NOT confined: an occupied overlay is modal and
		// fully interactive under the same policy, which loading screens and system menus
		// depend on.
		let modal = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical"><Button id="ok" text="OK" width="200" height="40"/></Flex>
			""");
		defer delete modal;
		let overlay = fixture.UI.PushScreenOverlay(modal);
		Test.Assert(overlay != null);
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(fixture.UI.ScreenRoot);

		bool okClicked = false;
		fixture.UI.ScreenRoot.FindByName<Button>("ok").OnClick.Add(
			new [&okClicked](b) => { okClicked = true; });

		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == fixture.UI.ScreenRoot);
		Test.Assert(fixture.Input.Runtime.GetConsumptionMask().Pointer);
		devices.PressLeft();
		fixture.Frame();
		devices.ReleaseLeft();
		fixture.Frame();
		Test.Assert(okClicked);
		Test.Assert(!clicked, "the scene button under the overlay still never fires");

		fixture.UI.RemoveScreenOverlay(overlay);
	}
}
