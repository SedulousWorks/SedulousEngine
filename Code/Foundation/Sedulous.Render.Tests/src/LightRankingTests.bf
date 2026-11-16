using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The lights a view shades past its budget: the forward and the cluster build shade the first
/// RenderLimits.MaxLightsPerView, so a scene with more ranks them by what each brings to the view.
class LightRankingTests
{
	/// With one light past the budget, a bright light beside the camera extracted last was the one
	/// cut.
	[Test]
	public static void PastThePerViewBudgetTheLightsThatMatterToTheViewAreKept()
	{
		let scene = scope ExtractedScene();
		scene.SetViewOrigin(.(0, 0, 0));
		for (uint32 i < RenderLimits.MaxLightsPerView)
		{
			var dim = GpuLight();
			dim.Type = 1.0f; // point
			dim.PositionWS = .(500.0f + (float)i, 0, 0);
			dim.Range = 5.0f;
			dim.Intensity = 0.5f;
			scene.AddLight(dim);
		}
		var sun = GpuLight();
		sun.Type = 0.0f;
		sun.Intensity = 0.1f;
		scene.AddLight(sun);
		var lamp = GpuLight();
		lamp.Type = 2.0f; // spot, beside the view
		lamp.PositionWS = .(1, 2, 0);
		lamp.Range = 10.0f;
		lamp.Intensity = 20.0f;
		lamp.ShadowIndex = 3.0f;
		scene.AddLight(lamp);
		Test.Assert(scene.Lights.Length == RenderLimits.MaxLightsPerView + 2);

		scene.RankLights();
		let lights = scene.Lights;
		Test.Assert(lights.Length == RenderLimits.MaxLightsPerView + 2, "ranked, not cut: the views cut");
		Test.Assert(lights[0].Type == 0.0f, "the sun first");
		Test.Assert(lights[1].Type == 2.0f, "then the lamp");
		Test.Assert(lights[1].ShadowIndex == 3.0f, "with its own shadow index");
		// The dim ones keep their extraction order among themselves (the ranking is stable).
		Test.Assert(lights[2].PositionWS.X == 500.0f);
		Test.Assert(lights[RenderLimits.MaxLightsPerView + 1].PositionWS.X == 500.0f + (float)(RenderLimits.MaxLightsPerView - 1));
	}

	/// Within the budget every light is shaded, so the order stays the extraction order.
	[Test]
	public static void WithinTheBudgetLightsKeepExtractionOrder()
	{
		let scene = scope ExtractedScene();
		scene.SetViewOrigin(.(0, 0, 0));
		var far = GpuLight();
		far.Type = 1.0f;
		far.PositionWS = .(100, 0, 0);
		var near = far;
		near.PositionWS = .(1, 0, 0);
		scene.AddLight(far);
		scene.AddLight(near);
		scene.RankLights();
		Test.Assert(scene.Lights[0].PositionWS.X == 100.0f);
	}
}
