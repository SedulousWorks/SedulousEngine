using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Terrain;
using Sedulous.Heightfield;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.Terrain;

namespace Sedulous.Engine.Terrain.Backend.Tests;

/// Renders one terrain scene through the whole frame chain on a real device and measures the
/// pixels that came out.
static class TerrainProbeRenderer
{
	public const uint32 Size = 256;

	/// The levels the manager ships, descending by coverage.
	private static float[7] sDefaultThresholds = .(1.0f, 0.25f, 0.08f, 0.03f, 0.012f, 0.005f,
		0.002f);

	public static TerrainProbe Render(TerrainProbeFixture fixture, TerrainProbeConfig config)
	{
		let probe = new TerrainProbe();

		let device = fixture.Device;
		let renderer = scope TerrainRenderer(device, fixture.Shaders, 2);
		if (renderer.Initialize() case .Err)
			return probe;

		renderer.SetSkirtsEnabled(config.Skirts);

		let registry = scope RendererRegistry();
		registry.Register(renderer);

		let frame = scope RenderFrame(device, registry, 2);

		let terrain = config.Terrain;
		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(terrain, chunks);

		let tree = scope TerrainQuadtree();
		tree.Build(chunks, TerrainChunks.ChunksPerSide(terrain.Size));

		let heightCache = scope TerrainHeightTextureCache();
		let heightView = heightCache.GetOrCreate(device, terrain, 1);
		if (heightView == null)
			return probe;

		// The cache owns the height texture, so it must let go before the device does.
		defer heightCache.Clear(device);

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));

		if (config.ToLight != null)
		{
			var sun = GpuLight();
			sun.Type = 0.0f;
			sun.DirectionWS = config.ToLight.Value * -1.0f;
			sun.Color = .(1.0f, 1.0f, 1.0f);
			sun.Intensity = 1.0f;
			scene.AddLight(sun);
		}

		let data = scene.Add<TerrainRenderData>();
		if (data == null)
			return probe;

		data.Category = RenderCategories.Opaque;
		data.RendererId = renderer.RendererId;
		data.Chunks = chunks.Ptr;
		data.ChunkCount = (uint32)chunks.Count;
		data.Nodes = tree.Nodes.Ptr;
		data.NodeCount = (uint32)tree.Nodes.Length;
		data.HeightView = heightView;
		data.ChunkToWorld = config.ChunkToWorld;
		data.GridSize = terrain.Size;
		data.WorldSizeXZ = terrain.WorldSize;
		data.MinY = terrain.MinY;
		data.MaxY = terrain.MaxY;

		if ((config.Thresholds != null) && !config.Thresholds.IsEmpty)
		{
			let count = Math.Min(config.Thresholds.Count, TerrainRenderData.cMaxLodThresholds);
			for (int i < count)
				data.Thresholds[i] = config.Thresholds[i];
			data.ThresholdCount = (uint32)count;
		}
		else
		{
			for (int i < sDefaultThresholds.Count)
				data.Thresholds[i] = sDefaultThresholds[i];
			data.ThresholdCount = (uint32)sDefaultThresholds.Count;
		}

		data.WeightView = config.WeightView;
		data.IndexView = config.IndexView;
		data.BaseAlbedoView = config.BaseAlbedoView;
		data.BaseNormalView = config.BaseNormalView;
		data.BaseOrmView = config.BaseOrmView;
		data.BaseTileScale = config.BaseTileScale;
		data.PaletteArrayView = config.PaletteArrayView;
		data.NormalArrayView = config.NormalArrayView;
		data.OrmArrayView = config.OrmArrayView;
		data.HeightArrayView = config.HeightArrayView;
		data.MaskArrayView = config.MaskArrayView;
		data.HeightBlendContrast = config.HeightBlendContrast;
		data.TileScaleBuffer = config.TileScaleBuffer;
		data.TileScaleGeneration = config.TileScaleGeneration;
		data.PaletteCount = config.PaletteCount;

		data.WorldCenter = .(0.0f, 0.5f * (terrain.MaxY + terrain.MinY), 0.0f);
		data.WorldRadius = Length(terrain.WorldSize) + (terrain.MaxY - terrain.MinY);

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(config.Eye, config.Target, config.Up);
		camera.Projection = Float4x4.PerspectiveFovRH(config.Fov, 1.0f, 1.0f, 4000.0f);
		camera.Position = config.Eye;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = Size;
		textureDesc.Height = Size;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "terrain.probe.target";
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
		settings.Clear = config.Clear;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.BloomEnabled = false;

		for (uint32 i = 0; i < 2; i++)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return probe;

			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;

			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, Size, Size);
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

		let image = RhiTestSupport.Readback(device, target, Size, Size);
		defer delete image;
		if (!image.Valid)
			return probe;

		Measure(image, probe);
		device.WaitIdle();
		return probe;
	}

	private static void Measure(CapturedImage image, TerrainProbe probe)
	{
		const uint32 cBandWidth = Size / (uint32)TerrainProbe.Bands;

		for (uint32 y = 0; y < Size; y++)
		{
			for (uint32 x = 0; x < Size; x++)
			{
				let p = image.At(x, y);
				let luma = (double)p[0] + p[1] + p[2];
				probe.Total += luma;
				if (luma > 30.0)
					probe.Filled++;

				if (x < Size / 2)
				{
					probe.LeftLuma += luma;
					probe.LeftR += p[0];
					probe.LeftG += p[1];
					probe.LeftB += p[2];
				}
				else
				{
					probe.RightLuma += luma;
					probe.RightR += p[0];
					probe.RightG += p[1];
					probe.RightB += p[2];
				}

				if (y < Size / 2)
					probe.TopLuma += luma;
				else
					probe.BottomLuma += luma;

				// The band centres, clear of the boundaries where bands blend and of the rim.
				if ((y >= Size / 4) && (y < Size * 3 / 4))
				{
					let band = Math.Min(x / cBandWidth, (uint32)TerrainProbe.Bands - 1);
					let within = x - band * cBandWidth;
					if ((within >= cBandWidth / 4) && (within < cBandWidth * 3 / 4))
					{
						probe.BandR[band] += p[0];
						probe.BandG[band] += p[1];
						probe.BandB[band] += p[2];
					}
				}
			}
		}

		probe.Valid = true;
	}
}
