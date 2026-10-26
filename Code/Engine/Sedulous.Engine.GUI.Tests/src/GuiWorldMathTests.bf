using System;
using Sedulous.Core;
using Sedulous.Engine.GUI;
using Sedulous.Render;

namespace Sedulous.Engine.GUI.Tests;

/// The GUI's arithmetic in the world on its own, with no context, no scene and no device: where
/// a billboard shows, where a ray crosses a panel, a pointer's ray and a panel's texture size.
class GuiWorldMathTests
{
	private static bool Near(float actual, float expected, float tolerance = 0.001f) =>
		Math.Abs(actual - expected) < tolerance;

	/// A projection a test reads at a glance: clip = (x, y, z, z), so a point's place on screen
	/// is (x / z, y / z) and it is behind the camera when z <= 0.
	private static Float4x4 SimpleProjection()
	{
		var m = Float4x4.Identity();
		m.M[2][3] = 1.0f;
		m.M[3][3] = 0.0f;
		return m;
	}

	private static Float4x4 At(Float3 position)
	{
		var m = Float4x4.Identity();
		m.M[3][0] = position.X;
		m.M[3][1] = position.Y;
		m.M[3][2] = position.Z;
		return m;
	}

	[Test]
	public static void ABillboardHangsFromItsEntitysProjectedPointLiftedHiddenBehindAndScaledWithDistance()
	{
		var billboard = GuiBillboardComponent();
		let projection = SimpleProjection();
		let viewport = Float2(200.0f, 100.0f);
		let eye = Float3(0.0f, 0.0f, 0.0f);

		var placed = GuiWorldMath.PlaceBillboard(billboard, At(.(0.0f, 0.0f, 1.0f)), projection, eye, viewport);
		Test.Assert(placed.Shown);
		Test.Assert(Near(placed.Anchor.X, 100.0f), "the view's centre");
		Test.Assert(Near(placed.Anchor.Y, 50.0f));
		Test.Assert(Near(placed.Scale, 1.0f));

		// Lifted half the view's height at that distance.
		billboard.Offset = .(0.0f, 0.5f, 0.0f);
		placed = GuiWorldMath.PlaceBillboard(billboard, At(.(0.0f, 0.0f, 1.0f)), projection, eye, viewport);
		Test.Assert(Near(placed.Anchor.Y, 25.0f));

		// Screen orientation: the offset turns with the entity (a half turn about z flips the lift).
		billboard.Orientation = .Screen;
		var turned = At(.(0.0f, 0.0f, 1.0f));
		turned.M[0][0] = -1.0f;
		turned.M[1][1] = -1.0f;
		placed = GuiWorldMath.PlaceBillboard(billboard, turned, projection, eye, viewport);
		Test.Assert(Near(placed.Anchor.Y, 75.0f));

		Test.Assert(!GuiWorldMath.PlaceBillboard(billboard, At(.(0.0f, 0.0f, -1.0f)), projection, eye, viewport).Shown);

		billboard.Offset = .(0.0f, 0.0f, 0.0f);
		billboard.ScaleMode = .Distance;
		billboard.ReferenceDistance = 10.0f;
		Test.Assert(Near(GuiWorldMath.PlaceBillboard(billboard, At(.(0.0f, 0.0f, 20.0f)), projection, eye, viewport).Scale, 0.5f));
		Test.Assert(Near(GuiWorldMath.PlaceBillboard(billboard, At(.(0.0f, 0.0f, 1.0f)), projection, eye, viewport).Scale, 2.0f), "at most MaxScale");
		Test.Assert(Near(GuiWorldMath.PlaceBillboard(billboard, At(.(0.0f, 0.0f, 100.0f)), projection, eye, viewport).Scale, 0.3f), "at least MinScale");
	}

	[Test]
	public static void ARayCrossesAWorldPanelWhereItShouldFromEitherFaceAndMissesPastItsEdges()
	{
		// In the xy plane, 2 by 1.
		let panel = At(.(0.0f, 0.0f, 0.0f));
		let size = Float2(2.0f, 1.0f);
		var hit = GuiWorldMath.RayHitGuiPanel(.(0.0f, 0.0f, 5.0f), .(0.0f, 0.0f, -1.0f), panel, size);
		Test.Assert(hit.Hit);
		Test.Assert(Near(hit.Distance, 5.0f));
		Test.Assert(Near(hit.Uv.X, 0.5f));
		Test.Assert(Near(hit.Uv.Y, 0.5f));

		// From behind.
		hit = GuiWorldMath.RayHitGuiPanel(.(0.5f, 0.25f, -5.0f), .(0.0f, 0.0f, 1.0f), panel, size);
		Test.Assert(hit.Hit);
		Test.Assert(Near(hit.Uv.X, 0.75f));
		Test.Assert(Near(hit.Uv.Y, 0.25f), "v down");

		Test.Assert(!GuiWorldMath.RayHitGuiPanel(.(1.5f, 0.0f, 5.0f), .(0.0f, 0.0f, -1.0f), panel, size).Hit, "past the edge");
		Test.Assert(!GuiWorldMath.RayHitGuiPanel(.(0.0f, 0.0f, 5.0f), .(1.0f, 0.0f, 0.0f), panel, size).Hit, "along the plane");
		Test.Assert(!GuiWorldMath.RayHitGuiPanel(.(0.0f, 0.0f, 5.0f), .(0.0f, 0.0f, 1.0f), panel, size).Hit, "away from it");
	}

	[Test]
	public static void APointersRayLeavesTheNearPlaneAndAPanelsTextureIsItsSizeAtItsDensityWithinLimits()
	{
		// The view's centre looks straight down an identity view's axis.
		var camera = ViewCamera();
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 16.0f / 9.0f, 0.1f, 100.0f);
		GuiWorldMath.GuiPointerRay(camera, .(640.0f, 360.0f), .(1280.0f, 720.0f), let origin, let direction);
		Test.Assert(direction.Z < -0.99f, "an identity view looks down -Z");
		Test.Assert(Math.Abs(direction.X) < 0.01f);
		Test.Assert(Math.Abs(direction.Y) < 0.01f);
		Test.Assert(Near(origin.Z, -0.1f), "from the near plane");

		var panel = GuiWorldPanelComponent();
		Test.Assert(GuiWorldMath.WorldPanelPixels(panel) == Float2(320.0f, 180.0f), "1.6 by 0.9 at 200");
		panel.SizeMeters = .(0.01f, 100.0f);
		Test.Assert(GuiWorldMath.WorldPanelPixels(panel) == Float2(16.0f, 2044.0f), "within 16 and 2044");
		panel.SizeMeters = .(1.0f, 1.0f);
		panel.PixelsPerMeter = 0.0f;
		Test.Assert(GuiWorldMath.WorldPanelPixels(panel) == Float2(16.0f, 16.0f), "a density of at least one");
	}
}
