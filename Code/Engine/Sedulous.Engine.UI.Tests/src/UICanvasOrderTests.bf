using System;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// The draw order inside one scene's root: canvases sorted by their authored order, the
/// billboard layer pinned beneath them, and a despawn sweeping its host away.
class UICanvasOrderTests
{
	[Test]
	public static void CanvasesStackByOrderAndADespawnSweeps()
	{
		let fixture = scope UITestFixture();

		let scene = fixture.Scenes.CreateScene("hud");
		let canvases = scene.GetSystem<UICanvasComponentManager>();

		let docA = UITestFixture.MakeDocument("<Label id=\"canvas-a\" text=\"a\"/>");
		defer delete docA;
		let docB = UITestFixture.MakeDocument("<Label id=\"canvas-b\" text=\"b\"/>");
		defer delete docB;
		let docC = UITestFixture.MakeDocument("<Label id=\"canvas-c\" text=\"c\"/>");
		defer delete docC;

		// Added as a (order 5), b (order 0), c (order 5, a TIE with a). A component
		// reference is transient because the pool compacts, so the fields are set right
		// after each Add and the component is re-resolved through Get later.
		let ea = scene.CreateEntity("a");
		{
			let a = canvases.Add(ea);
			a.Document.SetDirect(docA);
			a.Order = 5;
		}
		let eb = scene.CreateEntity("b");
		{
			let b = canvases.Add(eb);
			b.Document.SetDirect(docB);
			b.Order = 0;
		}
		let ec = scene.CreateEntity("c");
		{
			let c = canvases.Add(ec);
			c.Document.SetDirect(docC);
			c.Order = 5;
		}

		fixture.Frame();
		let root = fixture.UI.SceneRoot(scene);
		Test.Assert(root != null);
		Test.Assert(root.ChildCount == 4, "the billboard layer and three canvas hosts");

		// Child order IS draw order, later being on top. The billboard layer is child 0,
		// beneath every canvas, and holds no canvas of its own.
		Test.Assert(CanvasAt(root, 0) == "");
		// Sorted by order, and STABLE across the a/c tie, so: b(0), a(5), c(5).
		Test.Assert(CanvasAt(root, 1) == "b");
		Test.Assert(CanvasAt(root, 2) == "a");
		Test.Assert(CanvasAt(root, 3) == "c");

		// An order change re-sorts on the next sync: b goes on top.
		canvases.Get(eb).Order = 10;
		fixture.Frame();
		Test.Assert(CanvasAt(root, 1) == "a");
		Test.Assert(CanvasAt(root, 2) == "c");
		Test.Assert(CanvasAt(root, 3) == "b");

		// Despawning the entity sweeps its host out of the scene root, so a menu closes on
		// a despawn even though a component manager has no destroy hook.
		scene.DestroyEntity(ec);
		fixture.Frame();
		Test.Assert(root.ChildCount == 3);
		Test.Assert(root.FindByName("canvas-c") == null);
		Test.Assert(CanvasAt(root, 1) == "a");
		Test.Assert(CanvasAt(root, 2) == "b");
	}

	/// Which canvas sits at this child index, by the identifier its document carries.
	private static StringView CanvasAt(RootView root, int index)
	{
		let group = root.GetChildAt(index) as ViewGroup;
		if (group == null)
			return "";
		if (group.FindByName("canvas-a") != null)
			return "a";
		if (group.FindByName("canvas-b") != null)
			return "b";
		if (group.FindByName("canvas-c") != null)
			return "c";
		return "";
	}
}
