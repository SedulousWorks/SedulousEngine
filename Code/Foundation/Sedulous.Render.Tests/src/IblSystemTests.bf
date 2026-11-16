using System;
using Sedulous.Core;
using Sedulous.RenderGraph;
using Sedulous.RHI;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The environment system's PER SCENE contexts, and when a context rebuilds.
class IblSystemTests
{
	/// Two scenes with different skies get their own contexts and their own products, and the
	/// generations never collide, coming from ONE counter across every context.
	[Test]
	public static void TwoScenesGetTheirOwnProducts()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let ibl = scope IBLSystem(fixture.Device, fixture.Shaders);
		Test.Assert(ibl.Initialize() case .Ok);

		// A view standing in for a cooked image product.
		let texture = fixture.Device.CreateTexture(
			TextureDesc.RenderTarget(.RGBA8Unorm, 8, 8, 1, "sky")).Value;
		defer { var t = texture; fixture.Device.DestroyTexture(ref t); }
		var viewDesc = TextureViewDesc();
		viewDesc.Label = "IblSystemTests.TwoScenesGetTheirOwnProducts";
		viewDesc.Format = .RGBA8Unorm;
		let view = fixture.Device.CreateTextureView(texture, viewDesc).Value;
		defer { var v = view; fixture.Device.DestroyTextureView(ref v); }

		let sceneA = scope ExtractedScene();
		let sceneB = scope ExtractedScene();
		let sun = Float3(0.0f, -1.0f, 0.0f);

		var procedural = SkySnapshot();
		var image = SkySnapshot();
		image.Mode = .HDREquirect;
		image.Texture = view;
		image.TextureUid = 101;
		image.TextureIsCube = false;

		IblContext contextA = null;
		IblContext contextB = null;
		{
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			contextA = ibl.Prepare(sceneA, procedural, sun, graph);
			contextB = ibl.Prepare(sceneB, image, sun, graph);
		}

		Test.Assert(contextA != null);
		Test.Assert(contextB != null);
		Test.Assert(contextA != contextB);
		Test.Assert(ibl.ContextCount == 2);

		Test.Assert(contextA.ShBuffer != contextB.ShBuffer);
		Test.Assert(contextA.PrefilterView != contextB.PrefilterView);
		Test.Assert(contextA.Generation != contextB.Generation);

		// The untextured sky draws a crisp disc; a textured environment carries its own sun,
		// so drawing one over it would double it.
		Test.Assert(contextA.HasSunDisc);
		Test.Assert(!contextB.HasSunDisc);
	}

	/// In the steady state a scene re-prepares into the SAME context and rebuilds nothing: the
	/// generation is what a downstream cache keys on, so it must not move without cause.
	[Test]
	public static void ASteadySceneRebuildsNothing()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let ibl = scope IBLSystem(fixture.Device, fixture.Shaders);
		Test.Assert(ibl.Initialize() case .Ok);

		let scene = scope ExtractedScene();
		let sun = Float3(0.0f, -1.0f, 0.0f);
		var sky = SkySnapshot();

		IblContext context = null;
		{
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			context = ibl.Prepare(scene, sky, sun, graph);
		}
		Test.Assert(context != null);
		let generation = context.Generation;

		// The bake warms up over the first frames, so run past that window before pinning it.
		for (int i < 32)
		{
			let graph = scope:: RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			Test.Assert(ibl.Prepare(scene, sky, sun, graph) == context);
		}
		Test.Assert(context.Generation == generation);
	}

	/// A scene's sky texture changing rebuilds THAT scene's environment and no other. The
	/// change is detected by the product's identity, never by its address: a reload frees the
	/// old one and the allocator hands the replacement the same address.
	[Test]
	public static void OnlyTheSceneWhoseSkyChangedRebuilds()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let ibl = scope IBLSystem(fixture.Device, fixture.Shaders);
		Test.Assert(ibl.Initialize() case .Ok);

		let texture = fixture.Device.CreateTexture(
			TextureDesc.RenderTarget(.RGBA8Unorm, 8, 8, 1, "sky")).Value;
		defer { var t = texture; fixture.Device.DestroyTexture(ref t); }
		var viewDesc = TextureViewDesc();
		viewDesc.Label = "IblSystemTests.OnlyTheSceneWhoseSkyChangedRebuilds";
		viewDesc.Format = .RGBA8Unorm;
		let view = fixture.Device.CreateTextureView(texture, viewDesc).Value;
		defer { var v = view; fixture.Device.DestroyTextureView(ref v); }

		let sceneA = scope ExtractedScene();
		let sceneB = scope ExtractedScene();
		let sun = Float3(0.0f, -1.0f, 0.0f);

		var procedural = SkySnapshot();
		var image = SkySnapshot();
		image.Mode = .HDREquirect;
		image.Texture = view;
		image.TextureUid = 101;

		// A context that bakes in a frame declares one prefilter pass per mip and face.
		let bake = IBLSystem.cPrefilterMips * 6;

		IblContext contextA = null;
		IblContext contextB = null;
		{
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			contextA = ibl.Prepare(sceneA, procedural, sun, graph);
			contextB = ibl.Prepare(sceneB, image, sun, graph);
			Test.Assert(PrefilterPasses(graph) == 2 * bake);
		}

		// The products bake once: the next frame bakes nothing (a rebake in each startup frame
		// made every game's first seconds crawl on a phone).
		{
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			ibl.Prepare(sceneA, procedural, sun, graph);
			ibl.Prepare(sceneB, image, sun, graph);
			Test.Assert(PrefilterPasses(graph) == 0);
		}

		let generationB = contextB.Generation;

		// The sun moves. The image sky carries its own sun and never bakes for it; the procedural
		// one bakes once the sun has turned past the threshold, not for a sliver of a degree.
		{
			let nudged = Normalized(Float3(0.001f, -1.0f, 0.0f)); // about 0.06 degrees
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			ibl.Prepare(sceneA, procedural, nudged, graph);
			ibl.Prepare(sceneB, image, nudged, graph);
			Test.Assert(PrefilterPasses(graph) == 0);
			Test.Assert(contextA.SunDir.X == nudged.X, "the live direction follows regardless");
		}
		{
			let turned = Normalized(Float3(0.5f, -1.0f, 0.0f));
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			ibl.Prepare(sceneA, procedural, turned, graph);
			ibl.Prepare(sceneB, image, turned, graph);
			Test.Assert(PrefilterPasses(graph) == bake, "the procedural sky alone");
		}
		{
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			ibl.Prepare(sceneA, procedural, sun, graph);
			ibl.Prepare(sceneB, image, sun, graph);
			Test.Assert(PrefilterPasses(graph) == bake, "back again: the procedural sky bakes once more");
		}
		Test.Assert(contextB.Generation == generationB);
		let generationA = contextA.Generation;

		// The SAME view, but a different product behind it.
		image.TextureUid = 102;
		{
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			ibl.Prepare(sceneA, procedural, sun, graph);
			ibl.Prepare(sceneB, image, sun, graph);
			Test.Assert(PrefilterPasses(graph) == bake);
		}

		Test.Assert(contextA.Generation == generationA);
		Test.Assert(contextB.Generation > generationB);

		// Another environment resolution (a quality level's): each context remakes its
		// prefiltered cube at it, the old one retired rather than freed in flight, and bakes once
		// more; then rests.
		let retire = scope GpuRetireQueue();
		retire.Initialize(fixture.Device, 2);
		ibl.SetRetireQueue(retire);
		defer { retire.Flush(); ibl.SetRetireQueue(null); }
		Test.Assert(contextA.PrefilterView.Texture.Desc.Width == 256);
		ibl.SetPrefilterResolution(128);
		{
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			Test.Assert(ibl.Prepare(sceneA, procedural, sun, graph) === contextA);
			Test.Assert(ibl.Prepare(sceneB, image, sun, graph) === contextB);
			Test.Assert(PrefilterPasses(graph) == 2 * bake);
		}
		Test.Assert(contextA.PrefilterView.Texture.Desc.Width == 128);
		Test.Assert(contextB.PrefilterView.Texture.Desc.Width == 128);
		Test.Assert(retire.PendingCount == 4, "each context's old cube and its view");
		{
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			ibl.Prepare(sceneA, procedural, sun, graph);
			ibl.Prepare(sceneB, image, sun, graph);
			Test.Assert(PrefilterPasses(graph) == 0);
		}
	}

	/// The prefilter passes a frame's graph declares.
	private static int PrefilterPasses(RenderGraph graph)
	{
		var count = 0;
		for (let pass in graph.Passes)
		{
			if (pass.Name == "ibl.prefilter")
				count++;
		}
		return count;
	}
}
