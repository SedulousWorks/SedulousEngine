using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// Scene pass multisampling, accepted on a real device.
///
/// Two properties, both STRUCTURAL: that four samples fill a silhouette with partial coverage
/// pixels a single sample cannot produce, and that the resolve still composes with the post
/// stack, each of which reads the RESOLVED single sampled buffers under multisampling.
class MsaaProbeTests
{
	private const uint32 cSize = 128;

	private struct MsaaConfig
	{
		public uint32 Samples = 1;
		public bool Taa = false;
		public bool Fxaa = false;
		public bool Ssr = false;
		/// Nought is off, one GTAO, two SSAO.
		public uint32 AoMode = 0;
		/// A large thin slab tilted so its top face crosses the whole view at a grazing
		/// angle, a floor seen from just above it, in place of the small rotated cube: the
		/// flat surface AO probe. Thin, so the camera at z=6 is never inside it.
		public bool ObliquePlane = false;

		public this() {}
	}

	private struct EffectRun
	{
		public String Name;
		public MsaaConfig Config;

		public this(String name, MsaaConfig config)
		{
			Name = name;
			Config = config;
		}
	}

	/// A flat lit rotated cube on black through the whole chain, read back.
	private static CapturedImage RenderMsaa(BackendProbeFixture fixture, MsaaConfig config)
	{
		let device = fixture.Device;
		let shaders = fixture.Shaders;

		let psoCache = scope PipelineStateCache(shaders, device);
		let materials = scope MaterialSystem();
		if (materials.Initialize(device) case .Err)
			return null;

		let meshRenderer = scope MeshRenderer(device, shaders, psoCache, materials, 2);
		if (meshRenderer.Initialize() case .Err)
			return null;

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let tonemap = scope TonemapPass(device, shaders, 2);
		if (tonemap.Initialize() case .Err)
			return null;

		let msaaResolve = scope MsaaResolvePass(device, shaders);
		if (msaaResolve.Initialize() case .Err)
			return null;

		let taa = scope TaaPass(device, shaders);
		if (taa.Initialize() case .Err)
			return null;

		let fxaa = scope FxaaPass(device, shaders, 2);
		if (fxaa.Initialize() case .Err)
			return null;

		let ao = scope AoPass(device, shaders);
		if (ao.Initialize() case .Err)
			return null;

		let ssr = scope SsrPass(device, shaders);
		if (ssr.Initialize() case .Err)
			return null;

		let frame = scope RenderFrame(device, registry, 2, null, tonemap, null, null, null, null,
			config.Taa ? taa : null, (config.AoMode != 0) ? ao : null, config.Fxaa ? fxaa : null);
		frame.SetMsaaResolve(msaaResolve);
		if (config.Ssr)
		{
			frame.SetSsr(ssr);
			frame.SetSsrParams(true, .());
		}

		// A bright white cube, ROTATED so its silhouette runs diagonally: long edges are a
		// clear coverage signal. Flat bright ambient, so no light has to be placed.
		let cubeMesh = Primitives.Cube(2.2f);
		defer delete cubeMesh;

		let cubeMaterial = MaterialPresets.CreatePbr("msaa.cube", .(1, 1, 1, 1), 0.0f, 0.6f);
		defer delete cubeMaterial;

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));

		let cube = scene.Add<MeshRenderData>();
		// The slab is 40 by 0.2 by 40, tilted 0.35 radians about X and pushed back to z = -8,
		// so its top face spans the view with its normal about seventy degrees off the view
		// direction.
		cube.World = config.ObliquePlane
			? Float4x4.Scale(.(40.0f, 0.2f, 40.0f)) * Float4x4.RotationX(0.35f) * Float4x4.Translation(.(0, 0, -8))
			: Float4x4.RotationY(0.6f) * Float4x4.RotationX(0.5f);
		cube.WorldCenter = config.ObliquePlane ? Float3(0.0f, 0.0f, -8.0f) : Float3(0.0f, 0.0f, 0.0f);
		cube.WorldRadius = config.ObliquePlane ? 30.0f : 2.0f;
		cube.Mesh = cubeMesh;
		cube.Material = cubeMaterial;
		cube.Category = RenderCategories.Opaque;

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 6), .(0, 0, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 0, 6);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "msaa.probe.target";
		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return null;
		defer device.DestroyTexture(ref target);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return null;
		defer device.DestroyTextureView(ref targetView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return null;
		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return null;
		defer device.DestroyFence(ref fence);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return null;

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.BloomEnabled = false;
		settings.Post.TaaEnabled = config.Taa;
		settings.Post.FxaaEnabled = config.Fxaa;
		settings.Post.SsrEnabled = config.Ssr;
		settings.Post.AoMode = config.AoMode;
		// The temporal resolve and a temporal reflection both read motion vectors.
		settings.Post.NeedsMotion = config.Taa || config.Ssr;
		settings.Post.MsaaSamples = (uint8)config.Samples;

		// The temporal resolve warms its history over a few frames even on a still camera.
		let frames = config.Taa ? 8 : 2;
		for (uint32 i = 0; i < (uint32)frames; i++)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return null;

			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;

			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();

			let commandBuffer = encoder.Finish();
			if (commandBuffer == null)
			{
				pool.DestroyEncoder(ref encoder);
				return null;
			}

			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}

		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		device.WaitIdle();
		return image;
	}

	private static uint32 MaxLuma(CapturedImage image)
	{
		var max = (uint32)0;
		for (uint32 y = 0; y < image.Height; y++)
		{
			for (uint32 x = 0; x < image.Width; x++)
				max = Math.Max(max, image.Luma(x, y));
		}
		return max;
	}

	/// The partial coverage pixels: brightness strictly BETWEEN the background and the solid
	/// cube.
	///
	/// The band is relative to the image's OWN maximum, so it isolates the silhouette's fringe
	/// whatever the tone map decided white should be: the solid cube sits near the top of the
	/// range and the background near the bottom, and both are excluded.
	private static uint32 CountEdgeFringe(CapturedImage image, uint32 maxLuma)
	{
		let low = maxLuma * 15 / 100;
		let high = maxLuma * 85 / 100;

		return image.CountWhere(scope (rgba) =>
			{
				let luma = (uint32)rgba[0] + rgba[1] + rgba[2];
				return (luma > low) && (luma < high);
			});
	}

	private static bool Has4xMsaa(IDevice device)
	{
		return (device.MaxColorDepthSampleCount >= 4) && device.SupportsSampleCount(4);
	}

	[Test]
	public static void FourSamplesProduceEdgeCoverageThatOneDoesNot()
	{
		// EVERY backend, because the resolve is a backend feature: Vulkan resolves in the pass
		// and WebGPU through a resolveTarget, and only running both holds them to one property.
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			EdgeCoverageOn(kind);
	}

	private static void EdgeCoverageOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready || !Has4xMsaa(fixture.Device))
			return;

		let at1x = RenderMsaa(fixture, .() { Samples = 1 });
		defer delete at1x;
		let at4x = RenderMsaa(fixture, .() { Samples = 4 });
		defer delete at4x;

		Test.Assert((at1x != null) && at1x.Valid);
		Test.Assert((at4x != null) && at4x.Valid);

		let max1x = MaxLuma(at1x);
		let max4x = MaxLuma(at4x);
		let fringe1x = CountEdgeFringe(at1x, max1x);
		let fringe4x = CountEdgeFringe(at4x, max4x);

		// The cube has to actually render, as a clearly lit solid, at both counts.
		Test.Assert(max1x > 300, scope $"{kind}: the cube renders at one sample");
		Test.Assert(max4x > 300, scope $"{kind}: the cube renders at four");

		// The property being accepted: four samples fill the silhouette with partial coverage
		// pixels that the hard edged single sampled image, every pixel wholly cube or wholly
		// background, simply does not have.
		Test.Assert(fringe4x > fringe1x * 3, scope $"{kind}: four samples soften the silhouette");
		Test.Assert(fringe4x > 40, scope $"{kind}: and over a real span of it");
	}

	[Test]
	public static void TheResolveComposesWithThePostStack()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			PostStackOn(kind);
	}

	private static void PostStackOn(ProbeBackend kind)
	{
		// Each of these reads the RESOLVED single sampled buffers under multisampling, so this
		// guards the rebinding that makes that work: each still has to render a sane lit image.
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready || !Has4xMsaa(fixture.Device))
			return;

		let runs = scope EffectRun[4](
			.("fxaa", .() { Samples = 4, Fxaa = true }),
			.("ao", .() { Samples = 4, AoMode = 1 }),
			.("taa", .() { Samples = 4, Taa = true }),
			.("ssr", .() { Samples = 4, Ssr = true }));

		for (let run in runs)
		{
			let image = RenderMsaa(fixture, run.Config);
			defer delete image;
			Test.Assert((image != null) && image.Valid, scope $"{kind} {run.Name}: rendered");

			let max = MaxLuma(image);
			let lit = image.CountWhere(scope (rgba) =>
				{
					return ((uint32)rgba[0] + rgba[1] + rgba[2]) > 100;
				});

			// The effect composed with the resolve without breaking it: the cube is still a
			// clearly lit solid over a real area, and the values are sane rather than
			// overflowed.
			Test.Assert(max > 300, scope $"{kind} {run.Name}: lit");
			Test.Assert(max <= 765, scope $"{kind} {run.Name}: not overflowed");
			Test.Assert(lit > 200, scope $"{kind} {run.Name}: covers an area");
		}
	}

	/// The mean luminance over a rectangle, which is what a flat surface's brightness is
	/// measured by: a maximum would miss a uniform darkening.
	private static uint32 MeanLuma(CapturedImage image, uint32 x0, uint32 y0, uint32 x1, uint32 y1)
	{
		uint64 sum = 0;
		for (uint32 y = y0; y < y1; y++)
		{
			for (uint32 x = x0; x < x1; x++)
				sum += image.Luma(x, y);
		}
		return (uint32)(sum / (uint64)((x1 - x0) * (y1 - y0)));
	}

	/// A flat surface has NO ambient occlusion: a floor seen at a grazing angle comes out as
	/// bright with SSAO, and with GTAO, as with AO off.
	///
	/// SSAO compared each sample's scene depth against the CENTRE pixel and drew its kernel
	/// from a sphere, so an oblique floor's own depth gradient read as occlusion and the
	/// darkening moved with the camera.
	[Test]
	public static void AFlatSurfaceIsNotSelfOccluded()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			FlatSurfaceAoOn(kind);
	}

	private static void FlatSurfaceAoOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let off = RenderMsaa(fixture, .() { ObliquePlane = true });
		defer delete off;
		Test.Assert((off != null) && off.Valid, scope $"{kind}: the plane rendered");
		let unoccluded = MeanLuma(off, 32, 32, 96, 96);
		Test.Assert(unoccluded > 100, scope $"{kind}: the plane fills the probe region and is lit");

		for (let run in scope EffectRun[2](
			.("gtao", .() { AoMode = 1, ObliquePlane = true }),
			.("ssao", .() { AoMode = 2, ObliquePlane = true })))
		{
			let image = RenderMsaa(fixture, run.Config);
			defer delete image;
			Test.Assert((image != null) && image.Valid, scope $"{kind} {run.Name}: rendered");
			let lit = MeanLuma(image, 32, 32, 96, 96);
			// Within two percent of the unoccluded surface: a plane never occludes itself.
			// Measured here at 521 against 524 fixed, and 506 with the kernel left as a full
			// sphere, so the band separates those with room on both sides. Raptor's own five
			// percent band does not, this scene darkening less than theirs did. The per
			// sample comparison moves it by one unit, which no band could separate: the
			// hemisphere half is what this probe guards. GTAO sits at 523 throughout.
			Test.Assert(lit * 100 >= unoccluded * 98,
				scope $"{kind} {run.Name}: flat surface mean luma {lit} against {unoccluded} with AO off");
		}
	}
}
