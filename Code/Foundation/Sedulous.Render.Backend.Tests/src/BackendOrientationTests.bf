using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// The orientation probe: ONE asymmetric scene, a bright cube in the TOP half over a dim
/// ground plane in the bottom, rendered through the WHOLE frame chain on a real device, read
/// back, and checked that each object lights its own half.
///
/// This is the pixel level ground truth for the vertical flip class of bug. EVERY regression
/// in that class swaps the halves or culls the plane, so it fails here, loudly and
/// specifically, rather than in somebody's eyes a week later.
///
/// Raptor runs the same probe on Vulkan AND WebGPU and then checks the two agree. The WebGPU
/// backend is not ported yet, so the cross backend half is absent rather than failing: what
/// is here still catches the whole class WITHIN Vulkan.
class BackendOrientationTests
{
	private const uint32 cSize = 128;

	/// What one run of the chain is configured with.
	private struct ProbeConfig
	{
		public bool TaaEnabled = false;
		/// False sends the raw forward pass straight into the target.
		public bool UseTonemap = true;
		public bool IncludeCube = true;
		public bool IncludePlane = true;

		public this() {}
	}

	/// One named run of the chain.
	private struct ProbeRun
	{
		public String Name;
		public ProbeConfig Config;

		public this(String name, ProbeConfig config)
		{
			Name = name;
			Config = config;
		}
	}

	/// What came back: the brightness summed over each half's rows.
	private struct Probe
	{
		public bool Valid = false;
		public double TopLuma = 0.0;
		public double BottomLuma = 0.0;

		public this() {}
	}

	private static Probe RenderProbe(BackendProbeFixture fixture, ProbeConfig config)
	{
		var probe = Probe();

		let device = fixture.Device;
		let shaders = fixture.Shaders;

		let psoCache = scope PipelineStateCache(shaders, device);
		let materials = scope MaterialSystem();
		if (materials.Initialize(device) case .Err)
			return probe;

		let meshRenderer = scope MeshRenderer(device, shaders, psoCache, materials, 2);
		if (meshRenderer.Initialize() case .Err)
			return probe;

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let tonemap = scope TonemapPass(device, shaders, 2);
		if (tonemap.Initialize() case .Err)
			return probe;

		let taa = scope TaaPass(device, shaders);
		if (taa.Initialize() case .Err)
			return probe;

		let frame = scope RenderFrame(device, registry, 2, null,
			config.UseTonemap ? tonemap : null, null, null, null, null,
			config.TaaEnabled ? taa : null, null, null);
		// The per view flag turns the RESOLVE on; this is what tells the frame that motion
		// vectors are needed at all. Without it the forward pass skips them, the resolve
		// finds no velocity to read, and the target it was going to write stays at its clear.
		frame.SetTaa(config.TaaEnabled, 0.97f, 1.25f, 32.0f);

		// The asymmetric scene: a bright white cube ABOVE eye level, which projects into the
		// top half, over a wide dim ground plane below it. Flat bright ambient, so no light
		// has to be placed and nothing depends on one.
		let cubeMesh = Primitives.Cube(1.6f);
		defer delete cubeMesh;
		let planeMesh = Primitives.Plane(24.0f, 24.0f);
		defer delete planeMesh;

		let cubeMaterial = MaterialPresets.CreatePbr("probe.cube", .(1, 1, 1, 1), 0.0f, 0.6f);
		defer delete cubeMaterial;
		let planeMaterial = MaterialPresets.CreatePbr("probe.plane", .(0.18f, 0.18f, 0.18f, 1),
			0.0f, 0.8f);
		defer delete planeMaterial;

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));

		if (config.IncludeCube)
		{
			let cube = scene.Add<MeshRenderData>();
			cube.World = Float4x4.Translation(.(0.0f, 2.2f, 0.0f));
			cube.WorldCenter = .(0.0f, 2.2f, 0.0f);
			cube.Mesh = cubeMesh;
			cube.Material = cubeMaterial;
			cube.Category = RenderCategories.Opaque;
		}
		if (config.IncludePlane)
		{
			let plane = scene.Add<MeshRenderData>();
			plane.World = Float4x4.Translation(.(0.0f, -1.0f, 0.0f));
			plane.WorldCenter = .(0.0f, -1.0f, 0.0f);
			plane.Mesh = planeMesh;
			plane.Material = planeMaterial;
			plane.Category = RenderCategories.Opaque;
		}

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0.5f, 7), .(0, 0.5f, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 0.5f, 7);

		// The offscreen target the chain resolves into, left in the copy source state for the
		// readback.
		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "probe.target";
		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return probe;
		defer device.DestroyTexture(ref target);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return probe;
		defer device.DestroyTextureView(ref targetView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return probe;
		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return probe;
		defer device.DestroyFence(ref fence);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return probe;

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		// The temporal resolve is gated on the per view CONFIG as well as the pass existing.
		settings.Post.TaaEnabled = config.TaaEnabled;
		settings.Post.BloomEnabled = false;
		// The resolve READS motion vectors, and this is the per view flag that asks for them.
		settings.Post.NeedsMotion = config.TaaEnabled;

		// A few frames, since the temporal resolve warms its history even on a still camera.
		let frames = config.TaaEnabled ? 8 : 2;
		for (uint32 i = 0; i < (uint32)frames; i++)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return probe;

			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;

			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();

			let commandBuffer = encoder.Finish();
			if (commandBuffer == null)
			{
				pool.DestroyEncoder(ref encoder);
				return probe;
			}

			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}

		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		defer delete image;
		if (!image.Valid)
			return probe;

		for (uint32 y = 0; y < cSize; y++)
		{
			var row = 0.0;
			for (uint32 x = 0; x < cSize; x++)
			{
				let p = image.At(x, y);
				row += (double)p[0] + p[1] + p[2];
			}

			if (y < cSize / 2)
				probe.TopLuma += row;
			else
				probe.BottomLuma += row;
		}

		probe.Valid = true;
		device.WaitIdle();
		return probe;
	}

	[Test]
	public static void EachObjectLightsItsOwnHalfAtEveryStage()
	{
		let fixture = scope BackendProbeFixture();
		if (!fixture.Ready)
			return;

		// Raw forward, then with the tonemap, then with the temporal resolve as well; then
		// each object on its own. Each historical flip shows up as a different one of these
		// failing: a mirrored scene drops the cube on raw forward, a wrongly firing tonemap
		// side compensation drops it on one of the tonemap runs and not the other, and a
		// front face winding hack turns the plane only run black.
		let runs = scope ProbeRun[5](
			.("raw-forward", .() { TaaEnabled = false, UseTonemap = false }),
			.("tonemap", .() { TaaEnabled = false, UseTonemap = true }),
			.("taa", .() { TaaEnabled = true, UseTonemap = true }),
			.("plane-only-raw", .() { TaaEnabled = false, UseTonemap = false, IncludeCube = false }),
			.("cube-only-raw", .() { TaaEnabled = false, UseTonemap = false, IncludePlane = false }));

		for (let run in runs)
		{
			let probe = RenderProbe(fixture, run.Config);
			Test.Assert(probe.Valid, scope $"{run.Name}: the probe rendered");

			if (run.Config.IncludeCube && run.Config.IncludePlane)
			{
				// Both: the small bright cube lights the top half, and the huge dim plane
				// sums to MORE in the bottom, area beating brightness. A flip swaps the two
				// and the dominance inverts.
				Test.Assert(probe.TopLuma > 100000.0, scope $"{run.Name}: top lit");
				Test.Assert(probe.BottomLuma > probe.TopLuma * 1.3,
					scope $"{run.Name}: the plane dominates below");
			}
			else if (run.Config.IncludeCube)
			{
				// The cube alone, above eye level: ALL of its light is in the top half.
				Test.Assert(probe.TopLuma > 100000.0, scope $"{run.Name}: top lit");
				Test.Assert(probe.BottomLuma < probe.TopLuma * 0.05,
					scope $"{run.Name}: nothing below");
			}
			else
			{
				// The plane alone: it must RENDER, a winding hack culling it to black, and it
				// must land entirely below, a flip mirroring it up.
				Test.Assert(probe.BottomLuma > 100000.0, scope $"{run.Name}: bottom lit");
				Test.Assert(probe.TopLuma < probe.BottomLuma * 0.05,
					scope $"{run.Name}: nothing above");
			}
		}
	}
}
