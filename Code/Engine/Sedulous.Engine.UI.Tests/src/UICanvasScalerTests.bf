using System;
using Sedulous.Core;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// The canvas scaler: authored against one resolution and fitted to whatever viewport it
/// lands in, with hit testing following the same transform.
class UICanvasScalerTests
{
	private static bool Near(float actual, float expected) =>
		Math.Abs(actual - expected) < 0.01f;

	[Test]
	public static void TheReferenceResolutionScalerLaysOutAtTheReferenceSizeAndScalesToFit()
	{
		let fixture = scope UITestFixture();

		let scene = fixture.Scenes.CreateScene("menu");
		let canvases = scene.GetSystem<UICanvasComponentManager>();
		let e = scene.CreateEntity("hud");

		let document = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical"><Button id="btn" text="go" width="200" height="40"/></Flex>
			""");
		defer delete document;
		{
			let component = canvases.Add(e);
			component.Document.SetDirect(document);
			component.ScalerMode = .ReferenceResolution;
			component.ReferenceResolution = .(1600.0f, 900.0f);
		}

		fixture.Frame();
		var canvas = canvases.Get(e);
		Test.Assert(canvas != null);
		Test.Assert(canvas.Root != null);

		// Lay the scene root out at a smaller, differently proportioned viewport.
		let root = fixture.UI.SceneRoot(scene);
		Test.Assert(root != null);
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(root);

		// The document laid out at the REFERENCE size, scaled uniformly by
		// min(800/1600, 600/900) = 0.5 and centred, which letterboxes 75 pixels top and
		// bottom.
		Test.Assert(Near(canvas.Root.Width, 1600.0f));
		Test.Assert(Near(canvas.Root.Height, 900.0f));
		Test.Assert(Near(canvas.Root.Transform.Scale.X, 0.5f));
		Test.Assert(Near(canvas.Root.Transform.Scale.Y, 0.5f));
		Test.Assert(Near(canvas.Root.Bounds.X, 0.0f));
		Test.Assert(Near(canvas.Root.Bounds.Y, 75.0f));

		// Hit testing follows the transform: reference space (100, 20) draws at
		// (50, 75 + 10), so the button answers there and the letterbox bar is empty.
		let hit = root.HitTest(.(50.0f, 85.0f));
		Test.Assert(hit != null);
		Test.Assert(hit.Name == "btn");
		let bar = root.HitTest(.(50.0f, 30.0f));
		Test.Assert((bar == null) || (bar == root));

		// Switching back to ConstantPixel restores a one to one layout on the next sync.
		canvas.ScalerMode = .ConstantPixel;
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		canvas = canvases.Get(e);
		Test.Assert(Near(canvas.Root.Width, 800.0f));
		Test.Assert(Near(canvas.Root.Transform.Scale.X, 1.0f));
		let direct = root.HitTest(.(100.0f, 20.0f));
		Test.Assert(direct != null);
		Test.Assert(direct.Name == "btn");
	}
}
