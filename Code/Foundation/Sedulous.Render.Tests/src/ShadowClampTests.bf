using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// Clamping a caster's depth onto the near plane suits a cascade: a tall caster toward the sun past
/// it still shadows. A spot's shadow clamped too, and a lamp's own housing around its light landed
/// on the near plane and shadowed the whole cone: a square under each post lamp.
class ShadowClampTests
{
	/// Notes each shadow pass it is asked to draw: whether the pass clamps its casters' depth, and
	/// whether it is a cascade's (which follows its view's level selection, so it carries the view)
	/// or a local light's tile (which carries none).
	private class ClampRecordingRenderer : Renderer
	{
		private static uint16[1] sCategories = .(RenderCategories.Opaque);

		public List<(bool Cascade, bool Clamp)> Passes = new .() ~ delete _;

		public override Span<uint16> SupportedCategories => .(&sCategories[0], 1);

		public override void Resolve(RenderRecordContext context, Span<DrawItem> items, List<ResolvedDraw> outDraws)
		{
		}

		public override void ResolveDepthOnly(RenderRecordContext context, Span<DrawItem> items, List<ResolvedDraw> outDraws)
		{
			if (!context.DepthPrepass)
				Passes.Add(((context.View != null), context.ClampShadowCasters));
		}
	}

	[Test]
	public static void TheSunsCascadesClampTheirCastersAndASpotsShadowDoesNot()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let recorder = scope ClampRecordingRenderer();
		let registry = scope RendererRegistry();
		registry.Register(recorder);
		let shadows = scope ShadowSystem(fixture.Device, 2);
		Test.Assert(shadows.Initialize() case .Ok);
		let frame = scope RenderFrame(fixture.Device, registry, 2, null, null, shadows);

		let scene = scope ExtractedScene();
		let caster = scene.Add<JunkRenderData>();
		caster.Category = RenderCategories.Opaque;
		caster.RendererId = recorder.RendererId;
		caster.WorldCenter = .(0, 0, 0);
		caster.WorldRadius = 1.0f;
		var sun = DirectionalShadow();
		sun.Direction = .(0, -1, 0);
		sun.Valid = true;
		scene.SetDirectionalShadow(sun);
		var lamp = LocalShadowCaster();
		lamp.Type = 2;
		lamp.PositionWS = .(0, 3, 0);
		lamp.DirectionWS = .(0, -1, 0);
		lamp.Range = 8.0f;
		lamp.OuterAngle = 0.6f;
		scene.AddLocalShadowCaster(lamp);

		let camera = RenderFrameFixture.LookingAtTheOrigin();
		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();

		int cascades = 0;
		int locals = 0;
		for (let pass in recorder.Passes)
		{
			Test.Assert(pass.Clamp == pass.Cascade, pass.Cascade ? "a cascade clamps" : "a spot's tile does not");
			if (pass.Cascade)
				cascades++;
			else
				locals++;
		}
		Test.Assert(cascades >= 1, "the sun's cascades drew");
		Test.Assert(locals == 1, "the spot's tile drew");
	}
}
