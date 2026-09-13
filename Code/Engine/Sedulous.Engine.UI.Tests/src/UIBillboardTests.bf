using System;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.UI;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// The billboards, headless: a world anchor through a synthetic camera and into the view's
/// pixels, and the scene confinement that keeps one scene's tree out of another's.
class UIBillboardTests
{
	/// Approximately, in pixels. Nothing here is close enough to a boundary for the
	/// tolerance to matter.
	private static bool Near(float actual, float expected) =>
		Math.Abs(actual - expected) < 0.01f;

	[Test]
	public static void BillboardsProjectThroughTheSceneCameraAndParkBehindIt()
	{
		let fixture = scope UITestFixture();

		let scene = fixture.Scenes.CreateScene("world");
		// The camera manager comes from the render subsystem normally; added by hand here.
		scene.AddSystem<CameraComponentManager>();

		let cameras = scene.GetSystem<CameraComponentManager>();
		let cam = scene.CreateEntity("cam");
		cameras.Add(cam);

		// A camera at the origin looking down -Z, and two anchors either side of it.
		let front = scene.CreateEntity("front");
		scene.SetLocalPosition(front, .(0.0f, 0.0f, -10.0f));
		let behind = scene.CreateEntity("behind");
		scene.SetLocalPosition(behind, .(0.0f, 0.0f, 10.0f));
		scene.UpdateTransforms();

		let billboards = scene.GetSystem<UIBillboardComponentManager>();
		Test.Assert(billboards != null);

		let a = billboards.Add(front);
		let docA = UITestFixture.MakeDocument("<Label id=\"name-a\" text=\"A\"/>");
		defer delete docA;
		a.Document.SetDirect(docA);

		let b = billboards.Add(behind);
		let docB = UITestFixture.MakeDocument("<Label id=\"name-b\" text=\"B\"/>");
		defer delete docB;
		b.Document.SetDirect(docB);

		fixture.Frame();
		Test.Assert(a.Root != null);
		Test.Assert(b.Root != null);

		// The overlay role split made the per view sync directly testable: drive it with a
		// synthetic view whose clip.w is -z_view, which is the shape every real perspective
		// produces for a camera at the origin looking down -Z. front (z = -10) is on axis
		// and centres; behind (z = +10) gets clip.w < 0 and parks off screen.
		SceneOverlayView view = .();
		view.SceneKey = Internal.UnsafeCastToPtr(scene);
		view.ViewProjection = .Identity();
		view.ViewProjection[2, 3] = -1.0f; // clip.w = -z, row vector convention
		view.ViewProjection[3, 3] = 0.0f;
		view.TargetWidth = 800;
		view.TargetHeight = 600;
		view.ViewportWidth = 800;
		view.ViewportHeight = 600;
		fixture.UI.UpdateSceneView(scene, view);

		Test.Assert(Near(a.Root.Layout.Left.Value, 400.0f), "on axis lands at the centre");
		Test.Assert(Near(a.Root.Layout.Top.Value, 300.0f));
		Test.Assert(Near(b.Root.Layout.Left.Value, -10000.0f), "behind the camera parks");
		Test.Assert(Near(b.Root.Layout.Top.Value, -10000.0f));

		// A sub rect view, the split screen half: billboards land in VIEWPORT pixels, since
		// the vector renderer places the whole root at the view's rectangle, so the on axis
		// anchor centres within the HALF rather than within the whole target.
		view.ViewportX = 400;
		view.ViewportWidth = 400;
		view.ViewportHeight = 300;
		fixture.UI.UpdateSceneView(scene, view);
		Test.Assert(Near(a.Root.Layout.Left.Value, 200.0f), "the centre of the 400x300 half");
		Test.Assert(Near(a.Root.Layout.Top.Value, 150.0f));

		// Scene isolation is structural: another scene's canvas parents into ITS root.
		let other = fixture.Scenes.CreateScene("other");
		let otherCanvases = other.GetSystem<UICanvasComponentManager>();
		let e = other.CreateEntity("hud");
		let canvas = otherCanvases.Add(e);
		let docX = UITestFixture.MakeDocument("<Label id=\"x\" text=\"other\"/>");
		defer delete docX;
		canvas.Document.SetDirect(docX);

		fixture.Frame();
		Test.Assert(canvas.Root != null);
		Test.Assert(fixture.UI.SceneRoot(other).FindByName("x") != null);
		Test.Assert(fixture.UI.SceneRoot(scene).FindByName("x") == null);
	}
}
