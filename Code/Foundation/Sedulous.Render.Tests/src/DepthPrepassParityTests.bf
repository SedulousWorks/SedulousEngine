using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// What the driver hands a renderer for the depth prepass, which has to agree with what it
/// hands the same renderer for the colour pass.
class DepthPrepassParityTests
{
	private static bool SameMatrix(Float4x4 a, Float4x4 b)
	{
		for (int row < 4)
			for (int col < 4)
			{
				if (Abs(a.M[row][col] - b.M[row][col]) > 0.0001f)
					return false;
			}
		return true;
	}

	/// BOTH passes see the REAL camera view, and the same one.
	///
	/// That is the invariant behind the level of detail agreeing between them: the selection
	/// reads the view matrix, so a prepass given the identity would place the camera at the
	/// origin, select the finest level everywhere, and write a depth the colour pass then
	/// fights with, dropping far fragments in bands.
	[Test]
	public static void BothPassesSeeTheSameCameraView()
	{
		let fixture = scope RenderFrameFixture(256, 256);
		if (!fixture.Ready)
			return;

		let capture = scope CapturingRenderer();
		let registry = scope RendererRegistry();
		registry.Register(capture);

		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let scene = scope ExtractedScene();
		let data = scene.Add<MeshRenderData>();
		data.World = Float4x4.Identity();
		data.Category = RenderCategories.Opaque;
		data.RendererId = capture.RendererId;
		data.WorldRadius = 1.0f;

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(10, 20, 30), .(0, 0, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0f, 1.0f, 0.1f, 1000.0f);
		camera.Position = .(10, 20, 30);
		camera.FarZ = 1000.0f;

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 256, 256);
		frame.End();

		Test.Assert(capture.SawColorPass);
		Test.Assert(capture.SawDepthPass);

		Test.Assert(!SameMatrix(capture.DepthViewMatrix, Float4x4.Identity()));
		Test.Assert(SameMatrix(capture.DepthViewMatrix, camera.View));
		Test.Assert(SameMatrix(capture.ColorViewMatrix, camera.View));
	}

	/// The prepass FILLS the instance cache and the colour pass reuses it, which is what
	/// builds each group's instance data once rather than twice.
	[Test]
	public static void ThePrepassFillsTheCacheTheForwardReuses()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let capture = scope CapturingRenderer();
		let registry = scope RendererRegistry();
		registry.Register(capture);

		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let scene = scope ExtractedScene();
		let data = scene.Add<MeshRenderData>();
		data.World = Float4x4.Identity();
		data.Category = RenderCategories.Opaque;
		data.RendererId = capture.RendererId;
		data.WorldRadius = 1.0f;

		let camera = RenderFrameFixture.LookingAtTheOrigin();

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();
		Test.Assert(capture.DepthFilledInstanceCache);

		// Turned off, the forward fills its own instead, which is the comparison path.
		frame.SetInstanceSharing(false);
		capture.DepthFilledInstanceCache = false;

		frame.Begin(fixture.Encoder, 1);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();
		Test.Assert(!capture.DepthFilledInstanceCache);
	}

	/// The opaque pass records at the VIEW'S OWN sample count, so its pipelines and its bundle
	/// match the attachments it is recorded into.
	[Test]
	public static void TheOpaquePassRecordsAtTheViewsSampleCount()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let capture = scope CapturingRenderer();
		let registry = scope RendererRegistry();
		registry.Register(capture);

		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let scene = scope ExtractedScene();
		let data = scene.Add<MeshRenderData>();
		data.World = Float4x4.Identity();
		data.Category = RenderCategories.Opaque;
		data.RendererId = capture.RendererId;
		data.WorldRadius = 1.0f;

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, RenderFrameFixture.LookingAtTheOrigin(), .(), fixture.ColorView,
			.BGRA8Unorm, 128, 128);
		frame.End();

		// Multisampling engages only on the tone mapped path, and there is none here, so the
		// whole chain stays single sampled.
		Test.Assert(capture.ColorSampleCount == 1);
	}
}
