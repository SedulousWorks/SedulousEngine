using System;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// Removing the COMPONENT while the entity lives on, which is what an editor does and what a
/// component manager has no destroy hook for.
class UIComponentRemovalTests
{
	[Test]
	public static void RemovingACanvasOrBillboardComponentSweepsItsTree()
	{
		let fixture = scope UITestFixture();
		let scene = fixture.Scenes.CreateScene("level");
		let e = scene.CreateEntity("hud");

		let hudDoc = UITestFixture.MakeDocument("<Label id=\"hud-label\" text=\"HUD\"/>");
		defer delete hudDoc;
		let plateDoc = UITestFixture.MakeDocument("<Label id=\"plate\" text=\"name\"/>");
		defer delete plateDoc;

		let canvases = scene.GetSystem<UICanvasComponentManager>();
		canvases.Add(e).Document.SetDirect(hudDoc);
		let billboards = scene.GetSystem<UIBillboardComponentManager>();
		billboards.Add(e).Document.SetDirect(plateDoc);

		fixture.Frame();
		let root = fixture.UI.SceneRoot(scene);
		Test.Assert(root != null);
		Test.Assert(root.FindByName("hud-label") != null);
		Test.Assert(root.FindByName("plate") != null);

		// Only the COMPONENTS go; the entity survives.
		canvases.Remove(e);
		billboards.Remove(e);
		fixture.Frame();
		Test.Assert(root.FindByName("hud-label") == null);
		Test.Assert(root.FindByName("plate") == null);
	}
}
