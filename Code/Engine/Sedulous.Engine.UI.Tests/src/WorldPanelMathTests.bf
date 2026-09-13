using System;
using Sedulous.Core;
using Sedulous.Engine.UI;
using Sedulous.Render;

namespace Sedulous.Engine.UI.Tests;

/// The world panel's pointer arithmetic on its own, with no context, no scene and no device:
/// a ray from a pointer, and where that ray crosses a panel.
class WorldPanelMathTests
{
	private static bool Near(float actual, float expected, float tolerance = 0.001f) =>
		Math.Abs(actual - expected) < tolerance;

	[Test]
	public static void RayAndUvMathHitsFrontAndBackAndMissesTheEdges()
	{
		// An identity oriented panel at the origin: right is +X, up is +Y, normal is +Z.
		let panel = Float4x4.Identity();
		let size = Float2(2.0f, 1.0f);

		// Straight on from +Z at the exact centre.
		var hit = WorldPanelMath.RayHitWorldPanel(.(0, 0, 5), .(0, 0, -1), panel, size);
		Test.Assert(hit.Hit);
		Test.Assert(Near(hit.Distance, 5.0f));
		Test.Assert(Near(hit.Uv.X, 0.5f));
		Test.Assert(Near(hit.Uv.Y, 0.5f));

		// Off centre: half a unit right and a quarter up gives u 0.75 and v 0.25, since v
		// runs DOWN the way UI pixels do.
		hit = WorldPanelMath.RayHitWorldPanel(.(0.5f, 0.25f, 5), .(0, 0, -1), panel, size);
		Test.Assert(hit.Hit);
		Test.Assert(Near(hit.Uv.X, 0.75f));
		Test.Assert(Near(hit.Uv.Y, 0.25f));

		// The BACK face hits too, panels being double sided.
		hit = WorldPanelMath.RayHitWorldPanel(.(0, 0, -5), .(0, 0, 1), panel, size);
		Test.Assert(hit.Hit);

		// Past the half extent, parallel to the plane, and behind the pointer: all misses.
		Test.Assert(!WorldPanelMath.RayHitWorldPanel(.(1.5f, 0, 5), .(0, 0, -1), panel, size).Hit);
		Test.Assert(!WorldPanelMath.RayHitWorldPanel(.(0, 0, 5), .(1, 0, 0), panel, size).Hit);
		Test.Assert(!WorldPanelMath.RayHitWorldPanel(.(0, 0, 5), .(0, 0, 1), panel, size).Hit);

		// Unprojecting a pointer: the view centre looks straight down the camera axis.
		ViewCamera camera = .();
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 16.0f / 9.0f, 0.1f, 100.0f);
		WorldPanelMath.PointerRayFromCamera(camera, .(640.0f, 360.0f), .(1280.0f, 720.0f),
			let origin, let direction);
		Test.Assert(direction.Z < -0.99f, "an identity view looks down -Z");
		Test.Assert(Math.Abs(direction.X) < 0.01f);
		Test.Assert(Math.Abs(direction.Y) < 0.01f);
	}

	/// The playground pose, which is where the oblique case first went wrong: a fly camera
	/// off to one side and above, and a kiosk it is not squarely facing.
	[Test]
	public static void TheRayHitsUnderAnObliqueCamera()
	{
		ViewCamera camera = .();
		let rotation = FromYawPitchRoll(0.5f, -0.3f, 0.0f);
		var world = RotationMatrix(rotation);
		world.M[3][0] = 8.0f;
		world.M[3][1] = 6.0f;
		world.M[3][2] = 14.0f;
		camera.View = Inverse(world);
		camera.Projection = Float4x4.PerspectiveFovRH(1.04719755f, 1280.0f / 720.0f, 0.1f, 1000.0f);
		camera.Position = .(8.0f, 6.0f, 14.0f);

		var panel = Float4x4.Identity();
		panel.M[3][0] = 4.0f;
		panel.M[3][1] = 1.6f;
		panel.M[3][2] = -6.0f;
		let sizeMeters = Float2(1.6f, 1.0f);

		// Project the panel's centre to screen pixels, then aim at exactly that.
		let clip = Float4(4.0f, 1.6f, -6.0f, 1.0f) * camera.ViewProjection;
		Test.Assert(clip.W > 0.0f, "in front of the camera");
		let viewSize = Float2(1280.0f, 720.0f);
		let pointer = Float2((clip.X / clip.W * 0.5f + 0.5f) * viewSize.X,
			(1.0f - (clip.Y / clip.W * 0.5f + 0.5f)) * viewSize.Y);

		WorldPanelMath.PointerRayFromCamera(camera, pointer, viewSize, let origin,
			let direction);
		let hit = WorldPanelMath.RayHitWorldPanel(origin, direction, panel, sizeMeters);
		Test.Assert(hit.Hit);
		Test.Assert(Near(hit.Uv.X, 0.5f, 0.01f), "the ray comes back to the centre");
		Test.Assert(Near(hit.Uv.Y, 0.5f, 0.01f));
	}
}
