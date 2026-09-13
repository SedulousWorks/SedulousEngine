using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Terrain;
using Sedulous.Heightfield;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Terrain;

namespace Sedulous.Engine.Terrain.Tests;

/// The terrain draw path end to end on a null device and the real compiler: a heightfield
/// becomes a chunk model and a height texture, then ONE render data item, and a frame is
/// driven over it with the renderer registered on the opaque category.
///
/// A green run also proves the terrain shaders BUILD, since resolving emits nothing at all
/// without a pipeline.
class TerrainRendererTests
{
	/// The levels the manager ships, descending by coverage.
	private static float[7] sThresholds = .(1.0f, 0.25f, 0.08f, 0.03f, 0.012f, 0.005f, 0.002f);

	/// A foreign opaque item from ANOTHER renderer: the base fields sane, the payload floats,
	/// which is what a terrain item's pointers would misread as spans.
	private class ForeignRenderData : RenderData
	{
		public float[32] Payload = .();
	}

	/// A 129 grid, so two chunks a side, over a 128 by 128 world, rising along positive X.
	private static Heightfield MakeRampX()
	{
		let grid = new Heightfield(129, .(128.0f, 128.0f), 0.0f, 10.0f);
		for (int32 z = 0; z < 129; z++)
		{
			for (int32 x = 0; x < 129; x++)
				grid.SetSample(x, z, (uint16)((float)x / 128.0f * 65535.0f));
		}
		return grid;
	}

	/// Fills one whole terrain item, which is what the manager's extract does.
	private static void FillTerrainRenderData(TerrainRenderData data, Heightfield grid,
		Span<TerrainChunk> chunks, TerrainQuadtree tree, ITextureView heightView,
		uint16 rendererId)
	{
		data.Category = RenderCategories.Opaque;
		data.RendererId = rendererId;
		data.Chunks = chunks.Ptr;
		data.ChunkCount = (uint32)chunks.Length;
		data.Nodes = tree.Nodes.Ptr;
		data.NodeCount = (uint32)tree.Nodes.Length;
		data.HeightView = heightView;
		data.ChunkToWorld = Float4x4.Identity();
		data.GridSize = grid.Size;
		data.WorldSizeXZ = grid.WorldSize;
		data.MinY = grid.MinY;
		data.MaxY = grid.MaxY;

		for (int i < 7)
			data.Thresholds[i] = sThresholds[i];
		data.ThresholdCount = 7;

		data.WorldCenter = .(0.0f, 5.0f, 0.0f);
		data.WorldRadius = 100.0f;
	}

	[Test]
	public static void VisibleChunksDraw()
	{
		let fixture = scope TerrainRenderFixture(256, 256);
		if (!fixture.Ready)
			return;

		let renderer = scope TerrainRenderer(fixture.Device, fixture.Shaders, 2);
		Test.Assert(renderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(renderer);

		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let grid = MakeRampX();
		defer delete grid;

		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(grid, chunks);
		Test.Assert(chunks.Count == 4);

		let tree = scope TerrainQuadtree();
		tree.Build(chunks, TerrainChunks.ChunksPerSide(grid.Size));

		let heightCache = scope TerrainHeightTextureCache();
		let heightView = heightCache.GetOrCreate(fixture.Device, grid, 1);
		Test.Assert(heightView != null);

		let scene = scope ExtractedScene();
		let data = scene.Add<TerrainRenderData>();
		Test.Assert(data != null);
		FillTerrainRenderData(data, grid, chunks, tree, heightView, renderer.RendererId);

		// Straight down at the terrain, so all four chunks sit inside the frustum.
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0.0f, 300.0f, 0.1f), .(0.0f, 0.0f, 0.0f),
			.(0.0f, 0.0f, 1.0f));
		camera.Projection = Float4x4.PerspectiveFovRH(1.2f, 1.0f, 1.0f, 2000.0f);
		camera.Position = .(0.0f, 300.0f, 0.1f);

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 256, 256);
		Test.Assert(frame.ViewCount == 1);
		frame.End();

		// Draws only appear once the pipeline, and with it the shaders, built AND the resolve
		// picked a level per chunk.
		Test.Assert(renderer.MaxChunksDrawn == 4);

		// The GPU objects go back to the device before it dies.
		heightCache.Clear(fixture.Device);
	}

	[Test]
	public static void NothingDrawsWhenTheTerrainIsOffScreen()
	{
		let fixture = scope TerrainRenderFixture(256, 256);
		if (!fixture.Ready)
			return;

		let renderer = scope TerrainRenderer(fixture.Device, fixture.Shaders, 2);
		Test.Assert(renderer.Initialize() case .Ok);

		let registry = scope RendererRegistry();
		registry.Register(renderer);

		let frame = scope RenderFrame(fixture.Device, registry, 2);

		let grid = MakeRampX();
		defer delete grid;

		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(grid, chunks);

		let tree = scope TerrainQuadtree();
		tree.Build(chunks, TerrainChunks.ChunksPerSide(grid.Size));

		let heightCache = scope TerrainHeightTextureCache();
		let heightView = heightCache.GetOrCreate(fixture.Device, grid, 1);
		Test.Assert(heightView != null);

		let scene = scope ExtractedScene();
		let data = scene.Add<TerrainRenderData>();
		FillTerrainRenderData(data, grid, chunks, tree, heightView, renderer.RendererId);

		// Far away and looking further away, so the whole terrain is outside the frustum.
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(5000.0f, 100.0f, 0.0f), .(6000.0f, 100.0f, 0.0f),
			.(0.0f, 1.0f, 0.0f));
		camera.Projection = Float4x4.PerspectiveFovRH(1.2f, 1.0f, 1.0f, 2000.0f);
		camera.Position = .(5000.0f, 100.0f, 0.0f);

		frame.Begin(fixture.Encoder, 0);
		frame.AddView(scene, camera, .(), fixture.ColorView, .BGRA8Unorm, 256, 256);
		frame.End();

		Test.Assert(renderer.MaxChunksDrawn == 0);
		heightCache.Clear(fixture.Device);
	}

	[Test]
	public static void ACameraIndependentDepthPassCastsAtTheCoarsestLevel()
	{
		// A local shadow tile has no camera, and must never cast finer than any view shows. A
		// close up camera resolve picks fine levels, which is more indices per draw; the
		// camera independent one has to emit every chunk at the coarsest grid.
		let fixture = scope TerrainRenderFixture(256, 256);
		if (!fixture.Ready)
			return;

		let renderer = scope TerrainRenderer(fixture.Device, fixture.Shaders, 2);
		Test.Assert(renderer.Initialize() case .Ok);

		let grid = MakeRampX();
		defer delete grid;

		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(grid, chunks);

		let tree = scope TerrainQuadtree();
		tree.Build(chunks, TerrainChunks.ChunksPerSide(grid.Size));

		let heightCache = scope TerrainHeightTextureCache();
		let heightView = heightCache.GetOrCreate(fixture.Device, grid, 1);
		Test.Assert(heightView != null);

		let data = scope TerrainRenderData();
		FillTerrainRenderData(data, grid, chunks, tree, heightView, renderer.RendererId);

		let item = DrawItem(0, data);
		// The rings sized, which the frame would otherwise have done.
		renderer.PrepareFrame(64, 0);

		// A light style orthographic projection from above, covering the whole terrain.
		var context = RenderRecordContext();
		context.ViewProj = Float4x4.LookAtRH(.(0, 200, 0), .(0, 0, 0), .(0, 0, -1))
			* Float4x4.OrthographicRH(300.0f, 300.0f, 1.0f, 400.0f);
		context.DepthFormat = .Depth32Float;
		context.View = null;

		let coarse = scope List<ResolvedDraw>();
		var items = DrawItem[1](item);
		renderer.ResolveDepthOnly(context, .(&items[0], 1), coarse);
		// Two chunks a side, all visible from above.
		Test.Assert(coarse.Count == 4);

		// Every draw takes the SAME, coarsest, index count.
		for (int i = 1; i < coarse.Count; i++)
			Test.Assert(coarse[i].IndexCount == coarse[0].IndexCount);

		// The same terrain through a CLOSE UP camera resolves finer geometry: at least one
		// draw carries more indices than the camera independent ones.
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(-40.0f, 12.0f, 0.0f), .(0.0f, 5.0f, 0.0f), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 1000.0f);
		camera.Position = .(-40.0f, 12.0f, 0.0f);

		let empty = scope ExtractedScene();
		let view = scope RenderView();
		view.Bind(empty, camera, .(), fixture.ColorView, .BGRA8Unorm, 256, 256);

		var cameraContext = RenderRecordContext();
		cameraContext.View = view;
		cameraContext.ViewMatrix = camera.View;
		cameraContext.ViewProj = camera.ViewProjection;
		cameraContext.DepthFormat = .Depth32Float;
		cameraContext.DepthPrepass = true;

		let fine = scope List<ResolvedDraw>();
		renderer.ResolveDepthOnly(cameraContext, .(&items[0], 1), fine);
		Test.Assert(!fine.IsEmpty);

		var anyFiner = false;
		for (let draw in fine)
		{
			if (draw.IndexCount > coarse[0].IndexCount)
				anyFiner = true;
		}
		Test.Assert(anyFiner);

		heightCache.Clear(fixture.Device);
	}

	[Test]
	public static void ForeignItemsInTheSpanAreSkipped()
	{
		// An opaque run can interleave RENDERERS, meshes and terrain sharing one scene. The
		// dispatch groups runs by renderer, but the resolve gates on the id as well: a foreign
		// item that slipped through must be skipped rather than read as a terrain.
		let fixture = scope TerrainRenderFixture(256, 256);
		if (!fixture.Ready)
			return;

		let renderer = scope TerrainRenderer(fixture.Device, fixture.Shaders, 2);
		Test.Assert(renderer.Initialize() case .Ok);

		let grid = MakeRampX();
		defer delete grid;

		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(grid, chunks);

		let tree = scope TerrainQuadtree();
		tree.Build(chunks, TerrainChunks.ChunksPerSide(grid.Size));

		let heightCache = scope TerrainHeightTextureCache();
		let heightView = heightCache.GetOrCreate(fixture.Device, grid, 1);
		Test.Assert(heightView != null);

		let data = scope TerrainRenderData();
		FillTerrainRenderData(data, grid, chunks, tree, heightView, renderer.RendererId);

		let foreign = scope ForeignRenderData();
		foreign.Category = RenderCategories.Opaque;
		foreign.RendererId = renderer.RendererId + 1;
		for (int i < 32)
			foreign.Payload[i] = 1.0f;

		var items = DrawItem[3](.(0, foreign), .(0, data), .(0, foreign));
		renderer.PrepareFrame(64, 0);

		var context = RenderRecordContext();
		context.ViewProj = Float4x4.LookAtRH(.(0, 200, 0), .(0, 0, 0), .(0, 0, -1))
			* Float4x4.OrthographicRH(300.0f, 300.0f, 1.0f, 400.0f);
		context.DepthFormat = .Depth32Float;
		context.View = null;

		let depthDraws = scope List<ResolvedDraw>();
		renderer.ResolveDepthOnly(context, .(&items[0], 3), depthDraws);
		// The terrain's four chunks alone; both impostors skipped.
		Test.Assert(depthDraws.Count == 4);

		// The same gate on the colour path.
		var colorContext = context;
		colorContext.ColorFormat = .RGBA8Unorm;

		let colorDraws = scope List<ResolvedDraw>();
		renderer.Resolve(colorContext, .(&items[0], 3), colorDraws);
		Test.Assert(colorDraws.Count == 4);

		heightCache.Clear(fixture.Device);
	}
}
