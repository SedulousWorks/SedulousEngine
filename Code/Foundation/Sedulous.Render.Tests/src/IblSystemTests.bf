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

		IblContext contextA = null;
		IblContext contextB = null;
		{
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			contextA = ibl.Prepare(sceneA, procedural, sun, graph);
			contextB = ibl.Prepare(sceneB, image, sun, graph);
		}

		// Past the warmup, so what follows is a real change rather than a rebake.
		for (int i < 32)
		{
			let graph = scope:: RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			ibl.Prepare(sceneA, procedural, sun, graph);
			ibl.Prepare(sceneB, image, sun, graph);
		}

		let generationA = contextA.Generation;
		let generationB = contextB.Generation;

		// The SAME view, but a different product behind it.
		image.TextureUid = 102;
		{
			let graph = scope RenderGraph(fixture.Device);
			ibl.BeginFrame(graph);
			ibl.Prepare(sceneA, procedural, sun, graph);
			ibl.Prepare(sceneB, image, sun, graph);
		}

		Test.Assert(contextA.Generation == generationA);
		Test.Assert(contextB.Generation > generationB);
	}
}
