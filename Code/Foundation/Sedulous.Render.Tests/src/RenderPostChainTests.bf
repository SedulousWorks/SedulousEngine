using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.RHI;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The post chain: which passes a view's own settings put into the graph.
///
/// These read the declared pass list rather than any pixel, which is exactly what a null
/// device can answer, and it is the part that goes wrong: a pass silently not declared looks
/// identical to one that ran and did nothing.
class RenderPostChainTests
{
	private static bool Declared(RenderFrame frame, StringView name)
	{
		for (let pass in frame.Graph.Passes)
		{
			if (pass.Name == name)
				return true;
		}
		return false;
	}

	private static int DeclaredCount(RenderFrame frame, StringView name)
	{
		var count = 0;
		for (let pass in frame.Graph.Passes)
		{
			if (pass.Name == name)
				count++;
		}
		return count;
	}

	private static Material MakeLitMaterial()
	{
		let builder = scope MaterialBuilder("lit");
		return builder..Shader("forward")..VertexLayout(.Mesh).Build();
	}

	private static void AddCube(ExtractedScene scene, StaticMesh mesh, Material material)
	{
		let data = scene.Add<MeshRenderData>();
		data.World = Float4x4.Identity();
		data.Mesh = mesh;
		data.Material = material;
		data.Category = RenderCategories.Opaque;
		data.WorldRadius = 1.0f;
	}

	/// Without a tone map the forward writes the target directly, so there is no separate
	/// resolve at all: the chain is the forward, the sky and the blended pass.
	[Test]
	public static void WithoutAToneMapTheForwardWritesTheTarget()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;
		let scene = scope ExtractedScene();
		AddCube(scene, cube, material);

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, RenderFrameFixture.LookingAtTheOrigin(), .(), fixture.ColorView,
			.BGRA8Unorm, 128, 128);
		frame.End();

		Test.Assert(Declared(frame, "depth.prepass"));
		Test.Assert(Declared(frame, "forward"));
		Test.Assert(Declared(frame, "transparent"));
		Test.Assert(!Declared(frame, "tonemap"));
	}

	/// With one, the forward renders high range into a transient and the tone map resolves it,
	/// so both are declared and in that order.
	[Test]
	public static void AToneMapAddsItsOwnResolve()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let tonemap = scope TonemapPass(fixture.Device, fixture.Shaders, 2);
		Test.Assert(tonemap.Initialize() case .Ok);

		let frame = scope RenderFrame(fixture.Device, registry, 2, null, tonemap);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;
		let scene = scope ExtractedScene();
		AddCube(scene, cube, material);

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, RenderFrameFixture.LookingAtTheOrigin(), .(), fixture.ColorView,
			.BGRA8Unorm, 128, 128);
		frame.End();

		Test.Assert(Declared(frame, "forward"));
		Test.Assert(Declared(frame, "tonemap"));
	}

	/// The bounce is OFF by default and declares nothing; turning the view's own flag on
	/// declares its whole chain, the prefilter, the trace, the blur and the resolve.
	[Test]
	public static void TheBounceIsDeclaredOnlyWhenTheViewAsksForIt()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let tonemap = scope TonemapPass(fixture.Device, fixture.Shaders, 2);
		Test.Assert(tonemap.Initialize() case .Ok);
		let ssgi = scope SsgiPass(fixture.Device, fixture.Shaders);
		Test.Assert(ssgi.Initialize() case .Ok);

		let frame = scope RenderFrame(fixture.Device, registry, 2, null, tonemap);
		frame.SetSsgi(ssgi);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;
		let scene = scope ExtractedScene();
		AddCube(scene, cube, material);

		let camera = RenderFrameFixture.LookingAtTheOrigin();

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();
		Test.Assert(!Declared(frame, "ssgi.trace"));

		var settings = ViewSettings();
		settings.Post.SsgiEnabled = true;

		frame.Begin(fixture.Encoder, 1);
		frame.AddView(scene, camera, settings, fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();

		Test.Assert(Declared(frame, "ssgi.down"));
		Test.Assert(Declared(frame, "ssgi.trace"));
		Test.Assert(Declared(frame, "ssgi.blur"));
		Test.Assert(Declared(frame, "ssgi.resolve"));
	}

	/// The eye adaptation's measurement is a pass of its own, one per view, and it survives
	/// consecutive frames: its groups are keyed per view AND frame because the adapted value
	/// ping pongs, and a slot keyed on the view alone would free a set the previous frame is
	/// still reading.
	[Test]
	public static void TheEyeAdaptationMeasuresOncePerViewEveryFrame()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let tonemap = scope TonemapPass(fixture.Device, fixture.Shaders, 2);
		Test.Assert(tonemap.Initialize() case .Ok);
		let exposure = scope ExposurePass(fixture.Device, fixture.Shaders, 2);
		Test.Assert(exposure.Initialize() case .Ok);

		let frame = scope RenderFrame(fixture.Device, registry, 2, null, tonemap, null, null, null,
			null, null, null, null, exposure);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;
		let scene = scope ExtractedScene();
		AddCube(scene, cube, material);

		var settings = ViewSettings();
		settings.Post.AutoExposure = true;

		let camera = RenderFrameFixture.LookingAtTheOrigin();

		// Four consecutive frames over two views, which cycles the frame slots twice.
		for (uint32 f = 0; f < 4; f++)
		{
			frame.Begin(fixture.Encoder, f % 2);
			frame.AddView(scene, camera, settings, fixture.ColorView, .BGRA8Unorm, 128, 128);
			frame.AddView(scene, camera, settings, fixture.ColorView, .BGRA8Unorm, 128, 128);
			frame.End();

			Test.Assert(DeclaredCount(frame, "exposure.measure") == 2);
		}
	}

	/// A named graph texture appends a blit over the view's own rectangle, and the read is a
	/// REAL edge, so the aliasing keeps that transient alive as far as the blit.
	[Test]
	public static void ANamedResourceAppendsTheDebugBlit()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let tonemap = scope TonemapPass(fixture.Device, fixture.Shaders, 2);
		Test.Assert(tonemap.Initialize() case .Ok);
		let debugBlit = scope DebugBlitPass(fixture.Device, fixture.Shaders, 2);
		Test.Assert(debugBlit.Initialize() case .Ok);

		let frame = scope RenderFrame(fixture.Device, registry, 2, null, tonemap, null, null, null,
			null, null, null, null, null, debugBlit);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;
		let scene = scope ExtractedScene();
		AddCube(scene, cube, material);

		let camera = RenderFrameFixture.LookingAtTheOrigin();

		// Nothing asked for, so nothing is blitted.
		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();
		Test.Assert(!Declared(frame, "debug.blit"));

		// A resource the frame really declares.
		let debug = scope ViewDebugView();
		debug.Resource.Set("forward.normal");
		var settings = ViewSettings();
		settings.Debug = debug;

		frame.Begin(fixture.Encoder, 1);
		frame.AddView(scene, camera, settings, fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();
		Test.Assert(Declared(frame, "debug.blit"));

		// A name nothing declares blits nothing, rather than blitting whatever was nearest.
		let missing = scope ViewDebugView();
		missing.Resource.Set("nothing.at.all");
		settings.Debug = missing;

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, settings, fixture.ColorView, .BGRA8Unorm, 128, 128);
		frame.End();
		Test.Assert(!Declared(frame, "debug.blit"));
	}

	/// A SEMANTIC debug view shows the term the shading encoded into the scene, so it blits
	/// the raw high range image, and only where there IS one: without a tone map the forward
	/// wrote the final target and there is nothing to blit from.
	[Test]
	public static void ASemanticViewBlitsOnlyOnTheToneMappedPath()
	{
		let fixture = scope RenderFrameFixture(128, 128);
		if (!fixture.Ready)
			return;

		let meshRenderer = scope MeshRenderer(fixture.Device, fixture.Shaders, fixture.PsoCache,
			fixture.Materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let debugBlit = scope DebugBlitPass(fixture.Device, fixture.Shaders, 2);
		Test.Assert(debugBlit.Initialize() case .Ok);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let material = MakeLitMaterial();
		defer delete material;
		let scene = scope ExtractedScene();
		AddCube(scene, cube, material);

		let camera = RenderFrameFixture.LookingAtTheOrigin();
		let debug = scope ViewDebugView();
		debug.Semantic = .Normal;
		var settings = ViewSettings();
		settings.Debug = debug;

		// No tone map: nothing to blit from.
		{
			let frame = scope RenderFrame(fixture.Device, registry, 2, null, null, null, null, null,
				null, null, null, null, null, debugBlit);
			frame.Begin(fixture.Encoder, 0);
			frame.AddView(scene, camera, settings, fixture.ColorView, .BGRA8Unorm, 128, 128);
			frame.End();
			Test.Assert(!Declared(frame, "debug.blit"));
		}

		// With one, the scene image exists and the term is shown from it.
		{
			let tonemap = scope TonemapPass(fixture.Device, fixture.Shaders, 2);
			Test.Assert(tonemap.Initialize() case .Ok);
			let frame = scope RenderFrame(fixture.Device, registry, 2, null, tonemap, null, null,
				null, null, null, null, null, null, debugBlit);
			frame.Begin(fixture.Encoder, 0);
			frame.AddView(scene, camera, settings, fixture.ColorView, .BGRA8Unorm, 128, 128);
			frame.End();
			Test.Assert(Declared(frame, "debug.blit"));
		}
	}
}
