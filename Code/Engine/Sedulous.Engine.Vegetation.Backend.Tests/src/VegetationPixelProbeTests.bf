using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Heightfield;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.Scene;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;
using Sedulous.Vegetation;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.Vegetation;

namespace Sedulous.Engine.Vegetation.Backend.Tests;

/// Splat driven grass, accepted at the texel on a real device: it draws on the painted half
/// only, thins with distance through the fade prefix, and disappears beyond the fade.
///
/// This is also what catches a region offset a backend refuses: the instanced sets go through
/// the mesh renderer's persistent buffer, whose per region slices have to meet every
/// backend's storage buffer alignment.
class VegetationPixelProbeTests
{
	private const uint32 cSize = 256;
	/// Two by two chunks.
	private const int32 cGrid = 129;
	/// Centred on the origin.
	private const float cWorld = 128.0f;

	private static Heightfield MakeFlat()
	{
		let grid = new Heightfield(cGrid, .(cWorld, cWorld), 0.0f, 10.0f);
		let sample = grid.WorldYToSample(0.0f);
		for (int32 z = 0; z < cGrid; z++)
			for (int32 x = 0; x < cGrid; x++)
				grid.SetSample(x, z, sample);
		return grid;
	}

	/// Palette layer nought one hot on one half, base on the other.
	private static SplatWeights MakeHalfSplat()
	{
		const int32 n = 64;
		let sw = new SplatWeights(n, n);
		let idx = sw.Indices;
		let wts = sw.Weights;
		for (int32 y = 0; y < n; y++)
		{
			for (int32 x = 0; x < n / 2; x++)
			{
				let at = sw.TexelOffset(x, y);
				idx[at + 0] = 0;
				wts[at + 0] = 255;
			}
		}
		sw.BumpVersion();
		return sw;
	}

	private static ViewCamera TopDown()
	{
		var camera = ViewCamera();
		camera.Position = .(0.0f, 90.0f, 0.0f);
		camera.View = Float4x4.LookAtRH(camera.Position, .(0.0f, 0.0f, 0.0f), .(0.0f, 0.0f, 1.0f));
		camera.Projection = Float4x4.PerspectiveFovRH(1.2f, 1.0f, 1.0f, 1000.0f);
		camera.FarZ = 1000.0f;
		return camera;
	}

	/// The view pixel, y down, a world point lands on.
	private static void PixelOf(ViewCamera camera, Float3 world, out uint32 px, out uint32 py)
	{
		let clip = Float4(world.X, world.Y, world.Z, 1.0f) * camera.ViewProjection;
		let ndcX = clip.X / clip.W;
		let ndcY = clip.Y / clip.W;
		px = (uint32)Clamp((ndcX * 0.5f + 0.5f) * (float)cSize, 0.0f, (float)(cSize - 1));
		py = (uint32)Clamp((0.5f - ndcY * 0.5f) * (float)cSize, 0.0f, (float)(cSize - 1));
	}

	private class Probe
	{
		public bool Valid = false;
		/// Green texels in a window around the painted half's centre.
		public uint32 PaintedGreen = 0;
		/// The same around the unpainted half's centre.
		public uint32 UnpaintedGreen = 0;
		public uint32 TotalGreen = 0;
		public int SetsEmitted = 0;
	}

	/// Renders the grass layer with the manager's fade evaluated from a view origin.
	private static void RenderGrass(VegetationProbeFixture fixture, Float3 viewOrigin,
		float fadeStart, float fadeEnd, Probe outProbe)
	{
		let device = fixture.Device;
		let psoCache = scope PipelineStateCache(fixture.Shaders, device);
		let materials = scope MaterialSystem();
		if (materials.Initialize(device) case .Err)
			return;

		let meshRenderer = scope MeshRenderer(device, fixture.Shaders, psoCache, materials, 2);
		if (meshRenderer.Initialize() case .Err)
			return;

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(device, registry, 2);

		// The scene: a flat terrain with the half splat, and one grass layer under it.
		let world = scope Scene();
		TerrainScene.AddTerrainSceneManagers(world);
		VegetationScene.AddVegetationSceneManagers(world);
		let manager = world.GetSystem<TerrainVegetationComponentManager>();
		Test.Assert(manager != null);
		manager.SetBuildBudget(100);

		let grid = MakeFlat();
		defer delete grid;
		let splat = MakeHalfSplat();
		defer delete splat;
		let resource = scope TerrainResource();
		resource.Heightfield.SetDirect(grid);
		resource.Weights.SetDirect(splat);

		let terrain = world.CreateEntity("terrain");
		world.GetSystem<TerrainComponentManager>().Add(terrain).Terrain.SetDirect(resource);

		let tuft = Primitives.Cube(1.0f);
		defer delete tuft;
		let green = MaterialPresets.CreatePbr("grass", .(0.1f, 0.9f, 0.1f, 1.0f), 0.0f, 0.9f);
		defer delete green;

		let component = manager.Add(terrain);
		let layer = new ProceduralVegetationLayer();
		layer.Name.Set("Grass");
		layer.Mesh.SetDirect(tuft);
		layer.Material.SetDirect(green);
		layer.Placement = .Splat;
		layer.SplatLayer = 0;
		layer.Density = 0.5f;
		layer.MaxSlopeDegrees = 90.0f;
		layer.FadeStart = fadeStart;
		layer.FadeEnd = fadeEnd;
		component.ProceduralLayers.Add(layer);
		world.Start();

		let snapshot = scope ExtractedScene();
		snapshot.SetAmbient(.(1.0f, 1.0f, 1.0f));
		snapshot.SetViewOrigin(viewOrigin);
		manager.ExtractRenderData(snapshot);
		outProbe.SetsEmitted = snapshot.Size;

		let camera = TopDown();

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "vegetation.probe.target";
		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return;
		defer device.DestroyTexture(ref target);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return;
		defer device.DestroyTextureView(ref targetView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return;
		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return;
		defer device.DestroyFence(ref fence);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return;

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;

		for (uint32 i = 0; i < 2; i++)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return;

			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.Begin(encoder, i % 2);
			frame.AddView(snapshot, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();

			let commandBuffer = encoder.Finish();
			if (commandBuffer == null)
			{
				pool.DestroyEncoder(ref encoder);
				return;
			}

			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}

		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		defer delete image;
		Test.Assert((image != null) && image.Valid);

		PixelOf(camera, .(-32.0f, 0.5f, 0.0f), let paintedX, let paintedY);
		PixelOf(camera, .(32.0f, 0.5f, 0.0f), let unpaintedX, let unpaintedY);
		const uint32 cHalfWindow = 24;

		bool InWindow(uint32 x, uint32 y, uint32 cx, uint32 cy)
		{
			return ((x + cHalfWindow) >= cx) && (x < (cx + cHalfWindow))
				&& ((y + cHalfWindow) >= cy) && (y < (cy + cHalfWindow));
		}

		for (uint32 y = 0; y < cSize; y++)
		{
			for (uint32 x = 0; x < cSize; x++)
			{
				let p = image.At(x, y);
				let isGreen = (p[1] > 60) && ((uint32)p[1] > (uint32)p[0] + (uint32)p[2]);
				if (!isGreen)
					continue;

				outProbe.TotalGreen++;
				if (InWindow(x, y, paintedX, paintedY))
					outProbe.PaintedGreen++;
				if (InWindow(x, y, unpaintedX, unpaintedY))
					outProbe.UnpaintedGreen++;
			}
		}
		outProbe.Valid = true;
		device.WaitIdle();
	}

	[Test]
	public static void GrassDrawsOnThePaintedHalfOnlyAndThinsWithDistance()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			ProbeOn(kind);
	}

	private static void ProbeOn(ProbeBackend kind)
	{
		let fixture = scope VegetationProbeFixture(kind);
		if (!fixture.Ready)
			return;

		// Near: the view origin sits over the terrain, so every chunk is inside the fade's
		// start and draws in full.
		let near = scope Probe();
		RenderGrass(fixture, .(0.0f, 20.0f, 0.0f), 100.0f, 200.0f, near);
		Test.Assert(near.Valid, scope $"{kind}: rendered");
		// The two painted chunks; the other two scatter to nothing.
		Test.Assert(near.SetsEmitted == 2, scope $"{kind}: two sets");
		Test.Assert(near.PaintedGreen > 200, scope $"{kind}: dense grass on the painted half");
		Test.Assert(near.UnpaintedGreen == 0, scope $"{kind}: none on the other half");
		Test.Assert(near.TotalGreen > 2000, scope $"{kind}: grass over a real area");

		// Far: the origin is inside the fade, so the prefix thins the sets and fewer texels
		// come back green, but not none.
		let far = scope Probe();
		RenderGrass(fixture, .(0.0f, 300.0f, 0.0f), 100.0f, 400.0f, far);
		Test.Assert(far.Valid, scope $"{kind}: far rendered");
		Test.Assert(far.SetsEmitted == 2, scope $"{kind}: far still emits");
		Test.Assert(far.TotalGreen > 0, scope $"{kind}: far still draws");
		Test.Assert(far.TotalGreen < near.TotalGreen * 3 / 4, scope $"{kind}: the fade thinned it");
		Test.Assert(far.UnpaintedGreen == 0, scope $"{kind}: far keeps to the painted half");

		// Beyond the fade's end nothing is emitted and nothing draws.
		let gone = scope Probe();
		RenderGrass(fixture, .(0.0f, 300.0f, 0.0f), 40.0f, 80.0f, gone);
		Test.Assert(gone.Valid, scope $"{kind}: gone rendered");
		Test.Assert(gone.SetsEmitted == 0, scope $"{kind}: nothing emitted beyond the fade");
		Test.Assert(gone.TotalGreen == 0, scope $"{kind}: nothing drawn beyond the fade");
	}
}
