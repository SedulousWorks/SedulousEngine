using System;
using Sedulous.Core;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// The scene grid's pure parts: each plane's axes, the spacing for the camera's distance, and
/// how far the grid reaches.
class SceneGridTests
{
	private static bool Near(float a, float b, float tolerance = 1e-4f) => Math.Abs(a - b) <= tolerance;

	/// Each plane's axes are unit, at right angles, and turn into its normal.
	[Test]
	public static void EachPlanesAxesAreUnitAtRightAnglesAndTurnIntoItsNormal()
	{
		GridPlane[3] planes = .(.XZ, .XY, .YZ);
		Float3[3] normals = .(.(0, 1, 0), .(0, 0, 1), .(1, 0, 0));
		for (int i < 3)
		{
			let axes = SceneGrid.AxesOf(planes[i]);
			Test.Assert(Near(Length(axes.U), 1.0f) && Near(Length(axes.V), 1.0f));
			Test.Assert(Near(Dot(axes.U, axes.V), 0.0f));
			let n = Cross(axes.U, axes.V);
			Test.Assert(Near(n.X, normals[i].X) && Near(n.Y, normals[i].Y) && Near(n.Z, normals[i].Z), scope $"plane {i}");
			Test.Assert(Near(axes.Normal.X, normals[i].X) && Near(axes.Normal.Y, normals[i].Y) && Near(axes.Normal.Z, normals[i].Z));
		}
	}

	/// The spacing steps a decade at a time, blending across each step.
	[Test]
	public static void TheSpacingStepsADecadeAtATimeBlendingAcrossEachStep()
	{
		// 10 m up: metre cells, at the start of their decade.
		var s = SceneGrid.SpacingFor(10.0f);
		Test.Assert(Near(s.Spacing, 1.0f) && Near(s.Blend, 0.0f));
		// Half way (in decades) to 100 m: still metres, half blended toward ten.
		s = SceneGrid.SpacingFor(31.6228f);
		Test.Assert(Near(s.Spacing, 1.0f) && Near(s.Blend, 0.5f, 1e-3f));
		// 100 m up: ten metre cells; 1 m up: ten centimetre cells.
		Test.Assert(Near(SceneGrid.SpacingFor(100.0f).Spacing, 10.0f, 1e-3f));
		Test.Assert(Near(SceneGrid.SpacingFor(1.0f).Spacing, 0.1f));
		// On the plane, or below it: never finer than a centimetre.
		Test.Assert(Near(SceneGrid.SpacingFor(0.0f).Spacing, 0.01f));
		Test.Assert(Near(SceneGrid.SpacingFor(-5.0f).Spacing, 0.01f));

		// The spacing never shrinks as the camera climbs, and the blend stays within 0..1.
		var last = 0.0f;
		for (var d = 0.05f; d < 5000.0f; d *= 1.3f)
		{
			let step = SceneGrid.SpacingFor(d);
			Test.Assert((step.Spacing >= last) && (step.Blend >= 0.0f) && (step.Blend <= 1.0f), scope $"at {d} m");
			last = step.Spacing;
		}
	}

	/// It reaches further as the camera climbs, within the far plane.
	[Test]
	public static void ItReachesFurtherAsTheCameraClimbsWithinTheFarPlane()
	{
		Test.Assert(Near(SceneGrid.FadeDistance(0.0f), 60.0f));
		Test.Assert(SceneGrid.FadeDistance(10.0f) > SceneGrid.FadeDistance(1.0f));
		Test.Assert(SceneGrid.FadeDistance(1.0e6f) <= 900.0f);
	}
}
