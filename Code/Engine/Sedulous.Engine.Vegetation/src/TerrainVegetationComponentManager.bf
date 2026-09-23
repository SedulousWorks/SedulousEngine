using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Geometry;
using Sedulous.Heightfield;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;
using Sedulous.Vegetation;
using Sedulous.Vegetation.Resource;
using Sedulous.Engine.Render;
using Sedulous.Engine.Terrain;

namespace Sedulous.Engine.Vegetation;

/// The scene's render data provider for vegetation.
///
/// Per layer and chunk it scatters on demand, through Sedulous.Vegetation's pure function of
/// the seed, keeps the set's terrain local instances composed into world space, and emits ONE
/// MultiMeshRenderData per set in range with the fade prefix as its count. Sets out of range
/// are absent from the snapshot, and the renderer evicts their GPU buffers after its eviction
/// window.
///
/// Invalidation: the heightfield uid and version, the splat uid and version, the entity world
/// matrix and the layer's scatter hash. A region notice, which the editor brushes send,
/// regrows only the touched chunks.
class TerrainVegetationComponentManager : ResourceBindingComponentManager<TerrainVegetationComponent>,
	IRenderDataProvider
{
	/// The chunks scattered per extraction, per layer: a cold start spreads over frames.
	public const uint32 cDefaultBuildBudget = 4;

	/// One chunk's instances.
	private class ChunkSet
	{
		/// The ChunkSeed, which is the renderer's persistent buffer key.
		public uint64 Key = 0;
		/// Bumps per rebuild, so the renderer re-uploads on a change.
		public uint32 Version = 0;
		public bool Built = false;
		/// Needs a rescatter before it can draw.
		public bool Dirty = true;
		/// The composed instances: terrain local through the entity world.
		public List<Float4x4> World = new .() ~ delete _;
		/// The scatter itself, kept so a moved entity recomposes without rescattering.
		public List<Float4x4> Local = new .() ~ delete _;
		public AABB LocalBounds = AABB.Empty();
		public Float3 WorldCenter = .(0, 0, 0);
		public float WorldRadius = 0.0f;
	}

	/// One layer entity's cache.
	private class LayerCache
	{
		public Guid OwnerId = .();
		public uint32 LayerIndex = 0;
		public uint64 HeightfieldUid = 0;
		public uint64 HeightfieldVersion = 0;
		public uint64 SplatUid = 0;
		public uint64 SplatVersion = 0;
		public uint64 MaskUid = 0;
		public uint64 MaskVersion = 0;
		/// Scattered: a content hash of the authored instances.
		public uint64 InstancesHash = 0;
		public uint64 LayerHash = 0;
		public uint64 MeshUid = 0;
		public Float4x4 EntityWorld = .Identity();
		public bool Composed = false;
		public int32 ChunksPerSide = 0;
		public List<TerrainChunk> Chunks = new .() ~ delete _;
		/// One per chunk, row major.
		public List<ChunkSet> Sets = new .() ~ DeleteContainerAndItems!(_);
		public bool SeenThisFrame = false;
		/// The over budget warning fires once per layer.
		public bool WarnedClamp = false;
		/// And the unresolved mesh warning, likewise once per layer.
		public bool WarnedNoMesh = false;
	}

	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	private uint32 mBuildBudget = cDefaultBuildBudget;
	private uint64 mBuilds = 0;
	/// Keyed by the layer entity's tag.
	private Dictionary<uint64, LayerCache> mCaches = new .() ~ DeleteDictionaryAndValues!(_);
	private List<HeightfieldRegion> mPendingRegions = new .() ~ delete _;
	private ScatterResult mScatterScratch = new .() ~ delete _;
	private List<uint32> mTouchedScratch = new .() ~ delete _;
	private List<uint64> mStaleScratch = new .() ~ delete _;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// The component is a struct, so it cannot carry a field destructor: the manager owns the
	/// layer list's lifetime.
	protected override void OnComponentCreated(TerrainVegetationComponent* component,
		EntityHandle entity)
	{
		component.Layers = new List<VegetationLayer>();
	}

	protected override void OnComponentDestroyed(TerrainVegetationComponent* component,
		EntityHandle entity)
	{
		DeleteContainerAndItems!(component.Layers);
		component.Layers = null;
	}

	/// Vegetation draws in an editor as well as in a player, so this is NOT simulation gated.
	public override bool IsSimulationOnly => false;

	public void SetBuildBudget(uint32 chunksPerFrame) => mBuildBudget = chunksPerFrame;
	public uint32 BuildBudget => mBuildBudget;

	/// A sculpt or a paint over a region, in the sample grid coordinates of the heightfield
	/// the layers grow on: only the chunks it touches regrow on the next extraction. Without a
	/// notice, a heightfield or splat version bump regrows every chunk, the conservative
	/// fallback.
	public void InvalidateRegion(HeightfieldRegion region)
	{
		if (!region.IsEmpty)
			mPendingRegions.Add(region);
	}

	/// The region notices waiting for the next extraction, which is what a brush test reads
	/// to see that a stamp scoped its regrow.
	public int PendingRegionCount => mPendingRegions.Count;

	/// The same notice from a nought to one FOOTPRINT rect, which is a mask or splat texel
	/// rect over the terrain footprint, mapped onto the heightfield's sample grid.
	public void InvalidateFootprint(float u0, float v0, float u1, float v1, int32 gridSize)
	{
		if ((gridSize <= 1) || (u1 < u0) || (v1 < v0))
			return;

		let span = (float)(gridSize - 1);
		var region = HeightfieldRegion();
		region.MinX = Clamp((int32)Math.Floor(Clamp(u0, 0.0f, 1.0f) * span), 0, gridSize - 1);
		region.MaxX = Clamp((int32)Math.Ceiling(Clamp(u1, 0.0f, 1.0f) * span), 0, gridSize - 1);
		region.MinZ = Clamp((int32)Math.Floor(Clamp(v0, 0.0f, 1.0f) * span), 0, gridSize - 1);
		region.MaxZ = Clamp((int32)Math.Ceiling(Clamp(v1, 0.0f, 1.0f) * span), 0, gridSize - 1);
		InvalidateRegion(region);
	}

	/// The sets holding instances, for the tests and the heads up display.
	public int BuiltSetCount
	{
		get
		{
			var n = 0;
			for (let entry in mCaches)
				for (let set in entry.value.Sets)
					n += (set.Built && !set.World.IsEmpty) ? 1 : 0;
			return n;
		}
	}

	/// The instances across the built sets.
	public int InstanceCount
	{
		get
		{
			var n = 0;
			for (let entry in mCaches)
				for (let set in entry.value.Sets)
					n += set.Built ? set.World.Count : 0;
			return n;
		}
	}

	/// The scatters run, ever.
	public uint64 BuildCount => mBuilds;

	/// The terrain a layer entity grows on: its own TerrainComponent, else the nearest
	/// ancestor's. Null when there is none, and the terrain entity is left unassigned.
	private TerrainComponent* FindTerrainFor(EntityHandle layerEntity, out EntityHandle terrainEntity)
	{
		terrainEntity = .();
		let terrains = mScene.GetSystem<TerrainComponentManager>();
		if (terrains == null)
			return null;

		var e = layerEntity;
		for (uint32 depth = 0; (depth < 64) && e.IsAssigned; depth++)
		{
			let tc = terrains.Get(e);
			if (tc != null)
			{
				terrainEntity = e;
				return tc;
			}
			e = mScene.GetParent(e);
		}
		return null;
	}

	/// The largest axis scale a matrix applies: a bounds radius scales by at most this.
	private static float MaxAxisScale(Float4x4 m)
	{
		let sx = Length(Float3(m.M[0][0], m.M[0][1], m.M[0][2]));
		let sy = Length(Float3(m.M[1][0], m.M[1][1], m.M[1][2]));
		let sz = Length(Float3(m.M[2][0], m.M[2][1], m.M[2][2]));
		return Max(sx, Max(sy, sz));
	}

	/// One cache per layer SLOT of an entity: the entity tag hashed with the slot index, so
	/// removing a slot drops exactly its cache.
	private static uint64 CacheKey(EntityHandle owner, uint32 layerIndex)
	{
		var layerIndex;
		let entity = RenderExtract.PackEntity(owner);
		return HashBytes(&layerIndex, sizeof(uint32), entity);
	}

	private LayerCache CacheFor(EntityHandle owner, uint32 layerIndex)
	{
		let key = CacheKey(owner, layerIndex);
		if (mCaches.TryGetValue(key, let found))
			return found;

		let created = new LayerCache();
		created.LayerIndex = layerIndex;
		mCaches[key] = created;
		return created;
	}

	private void ResetCache(LayerCache cache, Heightfield hf, Guid ownerId, uint32 layerIndex)
	{
		cache.OwnerId = ownerId;
		cache.LayerIndex = layerIndex;
		cache.HeightfieldUid = hf.Uid;
		cache.HeightfieldVersion = hf.Version;
		cache.SplatUid = 0;
		cache.SplatVersion = 0;
		cache.Composed = false;
		cache.Chunks.Clear();
		TerrainChunks.BuildChunks(hf, cache.Chunks);
		cache.ChunksPerSide = TerrainChunks.ChunksPerSide(hf.Size);
		ClearAndDeleteItems!(cache.Sets);
		for (let chunk in cache.Chunks)
		{
			let set = new ChunkSet();
			set.Key = Scatter.ChunkSeed(ownerId, layerIndex, chunk.ChunkX, chunk.ChunkZ);
			cache.Sets.Add(set);
		}
	}

	private static void DirtyAll(LayerCache cache)
	{
		for (let set in cache.Sets)
			set.Dirty = true;
	}

	private static void Compose(LayerCache cache, ChunkSet set)
	{
		set.World.Clear();
		for (let local in set.Local)
			set.World.Add(local * cache.EntityWorld);

		// The world bounds are the local box's corners through the entity matrix.
		var world = AABB.Empty();
		let lo = set.LocalBounds.Min;
		let hi = set.LocalBounds.Max;
		for (uint32 corner = 0; corner < 8; corner++)
		{
			let p = Float3(
				((corner & 1) != 0) ? hi.X : lo.X,
				((corner & 2) != 0) ? hi.Y : lo.Y,
				((corner & 4) != 0) ? hi.Z : lo.Z);
			world.Expand(TransformPoint(p, cache.EntityWorld));
		}
		set.WorldCenter = world.Center();
		set.WorldRadius = Length(world.Extents());
		set.Version++; // the renderer re-uploads the set's buffer on a version change
	}

	/// The chunk an authored instance belongs to, by its terrain local XZ: exactly one, so a
	/// prop is never drawn twice.
	private static void ChunkOfInstance(LayerCache cache, Float4x4 instance, out int32 outX,
		out int32 outZ)
	{
		let origin = cache.Chunks[0];
		let width = Max(origin.Bounds.Max.X - origin.Bounds.Min.X, 1.0e-6f);
		let depth = Max(origin.Bounds.Max.Z - origin.Bounds.Min.Z, 1.0e-6f);
		let last = cache.ChunksPerSide - 1;
		outX = Clamp((int32)Floor((instance.M[3][0] - origin.Bounds.Min.X) / width), 0, last);
		outZ = Clamp((int32)Floor((instance.M[3][2] - origin.Bounds.Min.Z) / depth), 0, last);
	}

	/// The authored instances this chunk holds, with the bounds grown as the scatter's are.
	private void BucketAuthored(LayerCache cache, int chunkIndex, ScatterLayer layer,
		AABB meshBounds, Span<Float4x4> authored, Heightfield hf)
	{
		let chunk = cache.Chunks[chunkIndex];
		let holes = (hf != null) && hf.HasHoles;
		mScatterScratch.Clear();
		mScatterScratch.LocalBounds = chunk.Bounds;
		for (let instance in authored)
		{
			ChunkOfInstance(cache, instance, let cx, let cz);
			if ((cx != chunk.ChunkX) || (cz != chunk.ChunkZ))
				continue;

			// A prop standing over a CUT cell has no surface under it. It stays in the
			// authored list, so a fill brings it back and the eraser can still reach it, but
			// it does not draw: the one rule everywhere, props included.
			if (holes)
			{
				hf.CellOfLocal(instance.M[3][0], instance.M[3][2], let hx, let hz);
				if (hf.CellHasHole(hx, hz))
					continue;
			}
			mScatterScratch.Transforms.Add(instance);
		}
		if (!mScatterScratch.Transforms.IsEmpty && (meshBounds.Max.X >= meshBounds.Min.X))
		{
			let reach = Length(meshBounds.Extents()) + Length(meshBounds.Center());
			let grow = reach * Max(layer.ScaleRange.X, layer.ScaleRange.Y);
			mScatterScratch.LocalBounds.Min = mScatterScratch.LocalBounds.Min - Float3(grow, grow, grow);
			mScatterScratch.LocalBounds.Max = mScatterScratch.LocalBounds.Max + Float3(grow, grow, grow);
		}
	}

	private void BuildSet(LayerCache cache, int chunkIndex, Heightfield hf, SplatWeights splat,
		VegetationMask mask, ScatterLayer layer, AABB meshBounds, Span<Float4x4> authored)
	{
		let set = cache.Sets[chunkIndex];
		// A Scattered layer is authored rather than grown: its instances are bucketed by
		// their own position, and the procedural scatter is not run at all.
		if (layer.Placement == .Scattered)
			BucketAuthored(cache, chunkIndex, layer, meshBounds, authored, hf);
		else
			Scatter.ScatterChunk(set.Key, cache.Chunks[chunkIndex], hf, splat, mask, layer,
				meshBounds, mScatterScratch);
		if (mScatterScratch.DensityClamped && !cache.WarnedClamp)
		{
			cache.WarnedClamp = true;
			GlobalLog(.Warning,
				"Vegetation: a layer is over budget, {} instances per square metre wanted and {} used, the cap being {}",
				layer.Density, mScatterScratch.EffectiveDensity, layer.MaxInstancesPerChunk);
		}

		// The previous list may be BORROWED by a snapshot still being recorded, so the
		// contents are replaced rather than the list: the pointer a recorded snapshot holds
		// stays live for the frame it was taken in.
		set.Local.Clear();
		set.Local.AddRange(mScatterScratch.Transforms);
		set.LocalBounds = mScatterScratch.LocalBounds;
		set.Built = true;
		set.Dirty = false;
		Compose(cache, set);
		mBuilds++;
	}

	/// One layer slot's sets: the cache, its invalidation, and the emit of every chunk in
	/// range with the fade prefix as its count.
	private void ExtractLayer(ExtractedScene snapshot, EntityHandle owner, Guid ownerId,
		uint32 layerIndex, VegetationLayer authored, Heightfield hf, SplatWeights splat,
		VegetationMask mask, Float4x4 entityWorld, ref uint32 budget)
	{
		let cache = CacheFor(owner, layerIndex);
		cache.SeenThisFrame = true; // a hidden layer keeps its sets, so unhiding regrows nothing
		if (!authored.Visible)
			return;

		let mesh = authored.Mesh.Get;
		if (mesh == null)
		{
			// A reference that NAMES an asset but resolves to nothing, one deleted, uncooked
			// or left behind by a stale database, draws nothing: say so once, because a
			// silently empty layer reads as a broken brush. A nil reference is just an
			// unfinished layer, so it stays quiet.
			if ((authored.Mesh.Id != Guid()) && !cache.WarnedNoMesh)
			{
				cache.WarnedNoMesh = true;
				GlobalLog(.Warning,
					"Vegetation: layer {} '{}' has a mesh reference that does not resolve, one deleted, uncooked or stale, so nothing will draw",
					layerIndex, authored.Name);
			}
			return;
		}
		cache.WarnedNoMesh = false;

		let layer = authored.ToScatterLayer();
		let layerHash = VegetationLayers.LayerScatterHash(layer);

		// An identity change rebuilds the whole cache: another heightfield or its size, the
		// owner's persistent id, the mesh, or any scatter parameter.
		if (cache.Chunks.IsEmpty || (cache.HeightfieldUid != hf.Uid) || (cache.OwnerId != ownerId)
			|| (cache.MeshUid != mesh.Uid) || (cache.LayerHash != layerHash))
		{
			ResetCache(cache, hf, ownerId, layerIndex);
			cache.LayerHash = layerHash;
			cache.MeshUid = mesh.Uid;
			cache.WarnedClamp = false;
		}

		// The authored instances ARE the content of a Scattered layer, so a stroke, or an
		// undo of one, is a hash change and the whole layer re-buckets. Props are few, and a
		// sculpt regrows everything anyway.
		var instancesHash = (uint64)0;
		if (layer.Placement == .Scattered)
		{
			var count = (uint64)authored.Instances.Count;
			instancesHash = HashBytes(&count, sizeof(uint64), 0x9E3779B97F4A7C15UL);
			if (count > 0)
			{
				instancesHash = HashBytes(authored.Instances.Ptr,
					authored.Instances.Count * strideof(Float4x4), instancesHash);
			}
		}
		if (cache.InstancesHash != instancesHash)
		{
			DirtyAll(cache);
			cache.InstancesHash = instancesHash;
		}

		// A content change, a sculpt or a paint, regrows the touched chunks when the editor
		// said which, else every chunk.
		let splatUid = (splat != null) ? splat.Uid : 0;
		let splatVersion = (splat != null) ? splat.Version : 0;
		let maskUid = (mask != null) ? mask.Uid : 0;
		let maskVersion = (mask != null) ? mask.Version : 0;
		if ((cache.HeightfieldVersion != hf.Version) || (cache.SplatUid != splatUid)
			|| (cache.SplatVersion != splatVersion) || (cache.MaskUid != maskUid)
			|| (cache.MaskVersion != maskVersion))
		{
			if (mPendingRegions.IsEmpty)
			{
				DirtyAll(cache);
			}
			else
			{
				mTouchedScratch.Clear();
				for (let region in mPendingRegions)
					Scatter.ChunksTouchedBy(region, cache.ChunksPerSide, mTouchedScratch);
				for (let index in mTouchedScratch)
				{
					if (index < (uint32)cache.Sets.Count)
						cache.Sets[(int)index].Dirty = true;
				}
			}
			cache.HeightfieldVersion = hf.Version;
			cache.SplatUid = splatUid;
			cache.SplatVersion = splatVersion;
			cache.MaskUid = maskUid;
			cache.MaskVersion = maskVersion;
		}

		// The terrain entity's world matrix places the terrain local instances; a move
		// recomposes the built sets without rescattering them.
		if (!cache.Composed || (cache.EntityWorld != entityWorld))
		{
			cache.EntityWorld = entityWorld;
			cache.Composed = true;
			for (let set in cache.Sets)
			{
				if (set.Built)
					Compose(cache, set);
			}
		}

		let hasOrigin = snapshot.HasViewOrigin;
		let origin = snapshot.ViewOrigin;
		let entityScale = MaxAxisScale(entityWorld);
		let material = authored.Material.Get;
		for (int i < cache.Sets.Count)
		{
			let set = cache.Sets[i];
			// The distance from the view to the chunk: its built bounds, else the terrain's.
			var distance = 0.0f;
			if (hasOrigin)
			{
				var center = set.WorldCenter;
				var radius = set.WorldRadius;
				if (!set.Built)
				{
					let chunk = cache.Chunks[i];
					center = TransformPoint(chunk.Bounds.Center(), entityWorld);
					radius = Length(chunk.Bounds.Extents()) * entityScale;
				}
				distance = Max(0.0f, Length(origin - center) - radius);
				// Out of range: absent from the snapshot, and the renderer evicts it.
				if (distance >= layer.FadeEnd)
					continue;
			}

			if (set.Dirty)
			{
				// Authored props re-bucket in one copy, outside the budget, which exists for
				// the procedural scatter, so a stroke lands whole. A procedural set past the
				// budget waits for a later frame, but one that was ALREADY built keeps drawing
				// what it had meanwhile: a dropped frame under a brush is a flicker.
				let scattered = layer.Placement == .Scattered;
				if (scattered || (budget > 0))
				{
					BuildSet(cache, i, hf, splat, mask, layer, mesh.Bounds, authored.Instances);
					if (!scattered)
						budget--;
				}
				else if (!set.Built)
				{
					continue; // never built: nothing stale to show until its turn
				}
			}
			if (set.World.IsEmpty)
				continue;

			let density = hasOrigin
				? Scatter.DensityAtDistance(distance, layer.FadeStart, layer.FadeEnd)
				: 1.0f;
			let count = Scatter.FadePrefix((uint32)set.World.Count, density);
			if (count == 0)
				continue;

			let rd = snapshot.Add<MultiMeshRenderData>();
			if (rd == null)
				return;

			// The renderer dispatches on this flag, not on the type.
			rd.MultiMesh = true;
			rd.Key = set.Key;
			rd.Transforms = set.World.Ptr; // borrowed for the frame, the snapshot being immutable
			rd.InstanceCount = count; // the fade prefix, per frame
			// The WHOLE set, uploaded once: the prefix then moves with the camera without a
			// re-upload, and no region ever draws a tail it was not written with.
			rd.UploadCount = (uint32)set.World.Count;
			// The layer's own window, which is what the vertex shaders dissolve against per
			// instance: the prefix above stays the coarse bound and this removes the seam
			// between neighbouring chunks.
			rd.FadeStart = layer.FadeStart;
			rd.FadeEnd = layer.FadeEnd;
			rd.Version = set.Version; // the scatter, so a re-upload only on a change
			rd.Mesh = mesh;
			rd.Material = material;
			rd.WorldCenter = set.WorldCenter;
			rd.WorldRadius = set.WorldRadius;
			rd.EntityId = RenderExtract.PackEntity(owner);
			rd.Category = RenderExtract.CategoryForMaterial(material);
			rd.SortBatchKey = SortKeys.BatchKey(Internal.UnsafeCastToPtr(mesh),
				(material != null) ? Internal.UnsafeCastToPtr(material) : null);
			rd.CastShadows = layer.CastShadows;
		}
	}

	/// One MultiMeshRenderData per layer slot and chunk in range of the snapshot's view
	/// origin, or every chunk when the snapshot has none, which is a headless extraction.
	public void ExtractRenderData(ExtractedScene snapshot)
	{
		if (mScene == null)
			return;

		for (let entry in mCaches)
			entry.value.SeenThisFrame = false;

		var budget = mBuildBudget;

		ForEach(scope [&] (component, owner) =>
			{
				// Hidden or inactive: the layers keep their caches, marked seen, and draw
				// nothing.
				let active = component.Visible && mScene.IsEffectivelyActive(owner);
				EntityHandle terrainEntity = .();
				let tc = active ? FindTerrainFor(owner, out terrainEntity) : null;
				let res = (tc != null) ? tc.Terrain.Get : null;
				let hf = (res != null) ? res.Heightfield.Get : null;
				if ((hf == null) || hf.IsEmpty)
				{
					for (int li < component.Layers.Count)
						CacheFor(owner, (uint32)li).SeenThisFrame = true;
					return;
				}

				let splat = res.Weights.Get;
				let mask = component.Mask.Get;
				let ownerId = mScene.GetEntityId(owner);
				let entityWorld = mScene.GetWorldMatrix(terrainEntity);
				for (int li < component.Layers.Count)
				{
					ExtractLayer(snapshot, owner, ownerId, (uint32)li, component.Layers[li], hf,
						splat, mask, entityWorld, ref budget);
				}
			});

		// A layer slot that no longer exists, a removed slot, a removed component or a
		// destroyed entity, drops its cache, and the renderer evicts its buffers.
		mStaleScratch.Clear();
		for (let entry in mCaches)
		{
			if (!entry.value.SeenThisFrame)
				mStaleScratch.Add(entry.key);
		}
		for (let key in mStaleScratch)
		{
			if (mCaches.GetAndRemove(key) case .Ok(let pair))
				delete pair.value;
		}
		mPendingRegions.Clear();
	}
}
