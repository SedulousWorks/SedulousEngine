using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Profiler;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;

namespace Sedulous.Engine.Terrain;

/// The pool of terrains, which is also a render data provider.
///
/// It owns the GPU side: the height, splat and palette caches, and the chunk model built per
/// heightfield.
class TerrainComponentManager : ResourceBindingComponentManager<TerrainComponent>,
	IRenderDataProvider
{
	/// DESCENDING coverage thresholds over the chunk levels. The first is one, which is the
	/// level nought fallback.
	private static float[7] cDefaultThresholds = .(1.0f, 0.25f, 0.08f, 0.03f, 0.012f, 0.005f,
		0.002f);

	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	/// BORROWED, wired by the subsystem once the render systems exist.
	private IDevice mDevice = null;
	private uint16 mRendererId = 0;

	private TerrainHeightTextureCache mHeightTextures = new .() ~ delete _;
	private TerrainSplatTextureCache mSplatTextures = new .() ~ delete _;
	private TerrainPaletteTextureCache mPaletteTextures = new .() ~ delete _;

	/// The chunk model per heightfield, shared by every terrain referencing it. Keyed by the
	/// heightfield's UID for the same reason the texture caches are.
	private Dictionary<uint64, TerrainChunkCache> mChunkCache
		= new .() ~ DeleteDictionaryAndValues!(_);

	private List<float> mScaleScratch = new .() ~ delete _;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// Terrain draws in an editor as well as in a player, so this is NOT simulation gated.
	public override bool IsSimulationOnly => false;

	/// Wired by the subsystem after it creates and registers the renderer: the device the
	/// uploads go through, the dispatch id stamped on each item, and the frame aged queue so
	/// a rebuild never destroys a texture a frame in flight still samples.
	public void SetRenderContext(IDevice device, uint16 rendererId, GpuRetireQueue retire = null)
	{
		mDevice = device;
		mRendererId = rendererId;
		mHeightTextures.SetRetireQueue(retire);
		mSplatTextures.SetRetireQueue(retire);
		mPaletteTextures.SetRetireQueue(retire);
	}

	/// Tears down the GPU state THROUGH the wired device.
	///
	/// The destructor cannot do this: a scene's teardown can outlive the render device, and
	/// destroying a texture through a dead device is how the device itself leaks. The
	/// subsystem calls this at both points where the device is still alive. Safe to repeat,
	/// since a later extract finds no device and does nothing.
	public void ClearGpu()
	{
		if (mDevice == null)
			return;

		mHeightTextures.Clear(mDevice);
		mSplatTextures.Clear(mDevice);
		mPaletteTextures.Clear(mDevice);
		mDevice = null;
	}

	public int HeightTextureCount => mHeightTextures.Size;
	public int SplatTextureCount => mSplatTextures.Size;
	public int PaletteTextureCount => mPaletteTextures.Size;

	/// One item per visible terrain: the WHOLE terrain is a single draw list entry, and the
	/// renderer culls and picks levels for its chunks per view.
	public void ExtractRenderData(ExtractedScene snapshot)
	{
		// No device means a headless consumer, which has nothing to draw.
		if (mDevice == null)
			return;

		using (ProfileScope("Terrain.Extract"))
		{
			ForEach(scope [&] (component, owner) =>
				{
					ExtractTerrain(component, owner, snapshot);
				});
		}
	}

	private void ExtractTerrain(TerrainComponent* component, EntityHandle owner,
		ExtractedScene snapshot)
	{
		if (!component.Visible
			|| ((mScene != null) && !mScene.IsEffectivelyActive(owner)))
			return;

		let resource = component.Terrain.Get;
		if (resource == null)
			return;

		let heightfield = resource.Heightfield.Get;
		if ((heightfield == null) || heightfield.IsEmpty)
			return;

		let cache = GetOrBuildChunks(heightfield);
		if (cache.Chunks.IsEmpty)
			return;

		let heightView = mHeightTextures.GetOrCreate(mDevice, heightfield, heightfield.Version);
		if (heightView == null)
			return;

		// COPY the grid and the tree into the frame's arena. The snapshot is read at record
		// time, after arbitrary mid frame mutation, so a borrowed pointer into the cache
		// would be reading storage a rebuild had already freed.
		let chunkCopy = snapshot.AddArray<TerrainChunk>(cache.Chunks);
		let nodeCopy = snapshot.AddArray<TerrainQuadtreeNode>(cache.Quadtree.Nodes);
		// The arena is exhausted: skip rather than snapshot something dangling.
		if (chunkCopy.IsEmpty || nodeCopy.IsEmpty)
			return;

		let data = snapshot.Add<TerrainRenderData>();
		if (data == null)
			return;

		data.Category = RenderCategories.Opaque;
		data.RendererId = mRendererId;
		data.Chunks = chunkCopy.Ptr;
		data.Nodes = nodeCopy.Ptr;
		data.ChunkCount = (uint32)chunkCopy.Length;
		data.NodeCount = (uint32)nodeCopy.Length;
		data.HeightView = heightView;

		data.ChunkToWorld = (mScene != null) ? mScene.GetWorldMatrix(owner) : Float4x4.Identity();
		data.EntityId = EntityTag.Pack(owner.Index, owner.Generation); // the GPU pick's tag
		data.GridSize = heightfield.Size;
		data.WorldSizeXZ = heightfield.WorldSize;
		data.MinY = heightfield.MinY;
		data.MaxY = heightfield.MaxY;

		let thresholdCount = Math.Min(cDefaultThresholds.Count, TerrainRenderData.cMaxLodThresholds);
		for (int i < thresholdCount)
			data.Thresholds[i] = cDefaultThresholds[i];
		data.ThresholdCount = (uint32)thresholdCount;
		data.LodBias = component.LodBias;

		ExtractMaterial(resource, data);

		// The WHOLE terrain's bounds, so the framework does not cull it while any chunk of it
		// is still visible.
		data.WorldCenter = TransformPoint(cache.LocalBounds.Center(), data.ChunkToWorld);
		data.WorldRadius = Length(cache.LocalBounds.Extents());
	}

	private void ExtractMaterial(TerrainResource resource, TerrainRenderData data)
	{
		// The painted weights are the source of truth, and the texture pair derives from them.
		// A paint bumps the version, which re-uploads and rebuilds the renderer's cached
		// binding on the new view identities.
		if (let weights = resource.Weights.Get)
		{
			let views = mSplatTextures.GetOrCreate(mDevice, weights, weights.Version);
			data.WeightView = views.WeightView;
			data.IndexView = views.IndexView;
		}

		if (let albedo = resource.Base.Albedo.Get)
			data.BaseAlbedoView = albedo.View;
		if (let normal = resource.Base.Normal.Get)
			data.BaseNormalView = normal.View;
		if (let orm = resource.Base.Orm.Get)
			data.BaseOrmView = orm.View;
		if (let height = resource.Base.Height.Get)
			data.BaseHeightView = height.View;

		data.BaseTileScale = resource.Base.TileScale;
		data.HeightBlendContrast = resource.HeightBlendContrast;

		let palette = resource.PaletteData;
		if ((palette == null) || !palette.IsValid)
		{
			// No cooked palette, so the base layer alone covers it.
			data.PaletteCount = 0;
			return;
		}

		mScaleScratch.Clear();
		for (let layer in resource.Palette)
			mScaleScratch.Add(layer.TileScale);

		let gpu = mPaletteTextures.GetOrCreate(mDevice, palette, mScaleScratch);
		data.PaletteArrayView = gpu.ArrayView;
		data.NormalArrayView = gpu.NormalArrayView;
		data.OrmArrayView = gpu.OrmArrayView;
		data.HeightArrayView = gpu.HeightArrayView;
		data.MaskArrayView = gpu.MaskArrayView;
		data.TileScaleBuffer = gpu.TileScaleBuffer;
		data.TileScaleGeneration = gpu.Generation;
		data.PaletteCount = palette.SliceCount;
	}

	/// The chunk model for a heightfield, built on first sight.
	///
	/// Keyed by the heightfield's UID rather than its address, for the same reason the texture
	/// caches are. A hot reload swaps the object, which is a new identity, and a sculpt bumps
	/// the version; either rebuilds, because the chunk bounds move with the heights and both
	/// culling and level selection read them.
	private TerrainChunkCache GetOrBuildChunks(Heightfield heightfield)
	{
		if (mChunkCache.TryGetValue(heightfield.Uid, let found))
		{
			if (found.Version == heightfield.Version)
				return found;

			delete found;
			mChunkCache.Remove(heightfield.Uid);
		}

		let cache = new TerrainChunkCache();
		cache.Version = heightfield.Version;

		TerrainChunks.BuildChunks(heightfield, cache.Chunks);
		cache.Quadtree.Build(cache.Chunks, TerrainChunks.ChunksPerSide(heightfield.Size));

		for (let chunk in cache.Chunks)
			cache.LocalBounds = Sedulous.Core.Merge(cache.LocalBounds, chunk.Bounds);

		mChunkCache[heightfield.Uid] = cache;
		return cache;
	}
}
