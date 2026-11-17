using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// The clustered light lists proven at the pixel: a ground seen from above, lit only by a grid of
/// small point lights, through the full RenderFrame chain with the ClusterSystem on real devices.
/// Each light's patch is lit and the ground between them is dark, so every cluster found its own
/// lights and no others. The grid has more lights than the shared index list's average per cluster
/// (it is sized by that past 16), so the compact list is what is read.
class ClusterProbeTests
{
	private const uint32 cSize = 128;
	private const float cSpacing = 2.0f; // between lights
	private const float cRange = 0.9f; // short of the gap between them
	private const float cHeight = 0.4f; // over the ground

	private static ViewCamera TopDown()
	{
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 12.0f, 0.001f), .(0, 0, 0), .(0, 0, -1));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		return camera;
	}

	/// The pixel column a world point lands on (x only: the y convention is the backend's).
	private static uint32 PixelX(ViewCamera camera, Float3 world)
	{
		let clip = Float4(world.X, world.Y, world.Z, 1.0f) * (camera.View * camera.Projection);
		let ndcX = clip.X / clip.W;
		return (uint32)Clamp((ndcX * 0.5f + 0.5f) * (float)cSize, 0.0f, (float)(cSize - 1));
	}

	/// The grid of lights over a grey ground, with no ambient, read back raw.
	private static CapturedImage RenderLights(BackendProbeFixture fixture, ViewCamera camera)
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
		let clusters = scope ClusterSystem(device, shaders, 2);
		if (clusters.Initialize() case .Err)
			return null;
		let frame = scope RenderFrame(device, registry, 2, clusters);

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(0.0f, 0.0f, 0.0f)); // only the point lights light anything
		let plane = Primitives.Plane(30.0f, 30.0f);
		defer delete plane;
		let grey = MaterialPresets.CreatePbr("cluster.ground", .(0.8f, 0.8f, 0.8f, 1), 0.0f, 0.9f);
		defer delete grey;
		let ground = scene.Add<MeshRenderData>();
		ground.World = .Identity();
		ground.WorldCenter = .(0, 0, 0);
		ground.WorldRadius = 30.0f;
		ground.Mesh = plane;
		ground.Material = grey;
		ground.Category = RenderCategories.Opaque;
		// A 9 by 5 grid: 45 lights, past the list's average per cluster.
		for (int32 gz = -2; gz <= 2; gz++)
		{
			for (int32 gx = -4; gx <= 4; gx++)
			{
				var light = GpuLight();
				light.Type = 1.0f; // point
				light.PositionWS = .((float)gx * cSpacing, cHeight, (float)gz * cSpacing);
				light.Range = cRange;
				light.Color = .(1, 1, 1);
				light.Intensity = 6.0f;
				light.ShadowIndex = -1.0f;
				scene.AddLight(light);
			}
		}

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "cluster.target";
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
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;
		for (uint32 i = 0; i < 2; i++)
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

	[Test]
	public static void AGridOfSmallPointLightsEachLightsItsOwnPatch()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			ProbeOn(kind);
	}

	private static void ProbeOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let camera = TopDown();
		let image = RenderLights(fixture, camera);
		defer delete image;
		Test.Assert((image != null) && image.Valid, scope $"{kind}: the lights rendered");
		let row = cSize / 2; // world z = 0: the middle row of lights
		for (int32 gx = -2; gx <= 2; gx++) // in view: the ground shows about 6.9 either side
		{
			let x = (float)gx * cSpacing;
			let lit = image.Luma(PixelX(camera, .(x, 0, 0)), row);
			let between = image.Luma(PixelX(camera, .(x + cSpacing * 0.5f, 0, 0)), row);
			Test.Assert(lit > 120, scope $"{kind} light {gx}: its own light found its cluster, under it {lit}");
			Test.Assert(between < 30, scope $"{kind} light {gx}: no light past its range did, between {between}");
		}
	}
}
