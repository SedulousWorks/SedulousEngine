namespace Sedulous.Engine.Navigation;

using System;
using recastnavigation_Beef;

/// Build result from NavMeshBuilder.
class NavMeshBuildResult
{
	public bool Success;
	public NavMesh NavMesh ~ delete _;
	public TileCache TileCache ~ delete _;
	public String ErrorMessage ~ delete _;
	public NavMeshBuildStats Stats;
}

/// Statistics from navmesh building.
struct NavMeshBuildStats
{
	public int32 VertexCount;
	public int32 PolyCount;
	public int32 TileCount;
}

/// Static class for building navigation meshes.
static class NavMeshBuilder
{
	/// Builds a single-tile navigation mesh from geometry.
	public static NavMeshBuildResult BuildSingle(IInputGeometryProvider geometry, in NavMeshBuildConfig config)
	{
		let result = new NavMeshBuildResult();
		result.Success = false;

		if (geometry == null || geometry.VertexCount == 0 || geometry.TriangleCount == 0)
		{
			result.ErrorMessage = new String("Invalid input geometry");
			return result;
		}

		// Get bounds
		let bounds = geometry.Bounds;
		float[3] bmin = .(bounds.Min.X, bounds.Min.Y, bounds.Min.Z);
		float[3] bmax = .(bounds.Max.X, bounds.Max.Y, bounds.Max.Z);

		// Create context
		let ctx = rcCreateContext(1, 1);
		defer { rcDestroyContext(ctx); }

		// Calculate grid size
		int32 gw = 0, gh = 0;
		rcCalcGridSize(&bmin[0], &bmax[0], config.CellSize, &gw, &gh);

		// Create heightfield
		let hf = rcAllocHeightfield();
		defer { rcFreeHeightField(hf); }

		if (rcCreateHeightfield(ctx, hf, gw, gh, &bmin[0], &bmax[0], config.CellSize, config.CellHeight) == 0)
		{
			result.ErrorMessage = new String("Could not create heightfield");
			return result;
		}

		// Mark walkable triangles
		int32 ntris = geometry.TriangleCount;
		uint8* triareas = new uint8[ntris]*;
		defer { delete triareas; }

		Internal.MemSet(triareas, 0, ntris);
		rcMarkWalkableTriangles(ctx, config.AgentMaxSlope, geometry.Vertices, geometry.VertexCount,
			geometry.Triangles, ntris, triareas);

		// Rasterize triangles
		if (rcRasterizeTriangles(ctx, geometry.Vertices, geometry.VertexCount,
			geometry.Triangles, triareas, ntris, hf, (int32)(config.AgentMaxClimb / config.CellHeight)) == 0)
		{
			result.ErrorMessage = new String("Could not rasterize triangles");
			return result;
		}

		// Filter walkables
		int32 walkableHeight = (int32)Math.Ceiling(config.AgentHeight / config.CellHeight);
		int32 walkableClimb = (int32)Math.Floor(config.AgentMaxClimb / config.CellHeight);

		rcFilterLowHangingWalkableObstacles(ctx, walkableClimb, hf);
		rcFilterLedgeSpans(ctx, walkableHeight, walkableClimb, hf);
		rcFilterWalkableLowHeightSpans(ctx, walkableHeight, hf);

		// Create compact heightfield
		let chf = rcAllocCompactHeightfield();
		defer { rcFreeCompactHeightfield(chf); }

		if (rcBuildCompactHeightfield(ctx, walkableHeight, walkableClimb, hf, chf) == 0)
		{
			result.ErrorMessage = new String("Could not build compact heightfield");
			return result;
		}

		// Erode walkable area
		int32 walkableRadius = (int32)Math.Ceiling(config.AgentRadius / config.CellSize);
		if (rcErodeWalkableArea(ctx, walkableRadius, chf) == 0)
		{
			result.ErrorMessage = new String("Could not erode walkable area");
			return result;
		}

		// Build distance field and regions
		if (rcBuildDistanceField(ctx, chf) == 0)
		{
			result.ErrorMessage = new String("Could not build distance field");
			return result;
		}

		if (rcBuildRegions(ctx, chf, 0, config.RegionMinSize * config.RegionMinSize,
			config.RegionMergeSize * config.RegionMergeSize) == 0)
		{
			result.ErrorMessage = new String("Could not build regions");
			return result;
		}

		// Build contours
		let cset = rcAllocContourSet();
		defer { rcFreeContourSet(cset); }

		int32 maxEdgeLen = (int32)(config.EdgeMaxLen / config.CellSize);
		if (rcBuildContours(ctx, chf, config.EdgeMaxError, maxEdgeLen, cset, (.)rcBuildContoursFlags.RC_CONTOUR_TESS_WALL_EDGES) == 0)
		{
			result.ErrorMessage = new String("Could not build contours");
			return result;
		}

		// Build poly mesh
		let pmesh = rcAllocPolyMesh();
		defer { rcFreePolyMesh(pmesh); }

		if (rcBuildPolyMesh(ctx, cset, config.VertsPerPoly, pmesh) == 0)
		{
			result.ErrorMessage = new String("Could not build poly mesh");
			return result;
		}

		// Build detail mesh
		let dmesh = rcAllocPolyMeshDetail();
		defer { rcFreePolyMeshDetail(dmesh); }

		if (rcBuildPolyMeshDetail(ctx, pmesh, chf, config.DetailSampleDist, config.DetailSampleMaxError, dmesh) == 0)
		{
			result.ErrorMessage = new String("Could not build detail mesh");
			return result;
		}

		// Get poly mesh data
		int32 nverts = rcPolyMeshGetNVerts(pmesh);
		int32 npolys = rcPolyMeshGetNPolys(pmesh);
		int32 nvp = rcPolyMeshGetNvp(pmesh);

		if (npolys == 0)
		{
			result.ErrorMessage = new String("No polygons generated");
			return result;
		}

		// Build navmesh create params
		dtNavMeshCreateParams navParams = .();
		navParams.verts = rcPolyMeshGetVerts(pmesh);
		navParams.vertCount = nverts;
		navParams.polys = rcPolyMeshGetPolys(pmesh);
		navParams.polyFlags = rcPolyMeshGetFlags(pmesh);
		navParams.polyAreas = rcPolyMeshGetAreas(pmesh);
		navParams.polyCount = npolys;
		navParams.nvp = nvp;

		navParams.detailMeshes = rcPolyMeshDetailGetMeshes(dmesh);
		navParams.detailVerts = rcPolyMeshDetailGetVerts(dmesh);
		navParams.detailVertsCount = rcPolyMeshDetailGetNVerts(dmesh);
		navParams.detailTris = rcPolyMeshDetailGetTris(dmesh);
		navParams.detailTriCount = rcPolyMeshDetailGetNTris(dmesh);

		rcPolyMeshGetBMin(pmesh, &navParams.bmin[0]);
		rcPolyMeshGetBMax(pmesh, &navParams.bmax[0]);

		navParams.walkableHeight = config.AgentHeight;
		navParams.walkableRadius = config.AgentRadius;
		navParams.walkableClimb = config.AgentMaxClimb;
		navParams.cs = config.CellSize;
		navParams.ch = config.CellHeight;
		navParams.buildBvTree = 1;

		// Set all poly flags to 1 (walkable)
		for (int32 i = 0; i < npolys; i++)
			navParams.polyFlags[i] = 1;

		// Create navmesh data
		uint8* navData = null;
		int32 navDataSize = 0;
		if (dtCreateNavMeshData(&navParams, &navData, &navDataSize) == 0)
		{
			result.ErrorMessage = new String("Could not create navmesh data");
			return result;
		}

		// Create navmesh
		let navMesh = new NavMesh();
		let initStatus = navMesh.InitSingle(navData, navDataSize, (.)dtTileFlags.DT_TILE_FREE_DATA);
		if (initStatus != .Success)
		{
			dtFree(navData);
			delete navMesh;
			result.ErrorMessage = new String("Could not initialize navmesh");
			return result;
		}

		result.Success = true;
		result.NavMesh = navMesh;
		result.Stats = .() {
			VertexCount = nverts,
			PolyCount = npolys,
			TileCount = 1
		};

		return result;
	}

	/// Builds a tiled navigation mesh with TileCache support for dynamic obstacles.
	public static NavMeshBuildResult BuildTiled(IInputGeometryProvider geometry, in NavMeshBuildConfig config)
	{
		let result = new NavMeshBuildResult();
		result.Success = false;

		if (geometry == null || geometry.VertexCount == 0 || geometry.TriangleCount == 0)
		{
			result.ErrorMessage = new String("Invalid input geometry");
			return result;
		}

		// Get bounds
		let bounds = geometry.Bounds;
		float[3] bmin = .(bounds.Min.X, bounds.Min.Y, bounds.Min.Z);
		float[3] bmax = .(bounds.Max.X, bounds.Max.Y, bounds.Max.Z);

		// Tile size (use config or default)
		int32 tileSize = config.TileSize > 0 ? config.TileSize : 48;
		float tileWorldSize = tileSize * config.CellSize;

		// Calculate tile grid dimensions
		int32 gw = (int32)Math.Ceiling((bmax[0] - bmin[0]) / tileWorldSize);
		int32 gh = (int32)Math.Ceiling((bmax[2] - bmin[2]) / tileWorldSize);

		if (gw <= 0) gw = 1;
		if (gh <= 0) gh = 1;

		// Calculate walkable parameters
		int32 walkableHeight = (int32)Math.Ceiling(config.AgentHeight / config.CellHeight);
		int32 walkableClimb = (int32)Math.Floor(config.AgentMaxClimb / config.CellHeight);
		int32 walkableRadius = (int32)Math.Ceiling(config.AgentRadius / config.CellSize);
		int32 borderSize = walkableRadius + 3; // Extra padding for tile borders

		// Create TileCache
		let tileCache = new TileCache();

		// Initialize TileCache params
		dtTileCacheParams tcParams = .();
		tcParams.orig = bmin;
		tcParams.cs = config.CellSize;
		tcParams.ch = config.CellHeight;
		tcParams.width = tileSize;
		tcParams.height = tileSize;
		tcParams.walkableHeight = config.AgentHeight;
		tcParams.walkableRadius = config.AgentRadius;
		tcParams.walkableClimb = config.AgentMaxClimb;
		tcParams.maxSimplificationError = config.EdgeMaxError;
		tcParams.maxTiles = gw * gh * 4; // Allow for layers
		tcParams.maxObstacles = 128;

		if (tileCache.Init(&tcParams) != .Success)
		{
			delete tileCache;
			result.ErrorMessage = new String("Could not initialize TileCache");
			return result;
		}

		// Create NavMesh for tiled mesh
		let navMesh = new NavMesh();

		// Initialize navmesh params
		dtNavMeshParams navParams = .();
		navParams.orig = bmin;
		navParams.tileWidth = tileWorldSize;
		navParams.tileHeight = tileWorldSize;
		navParams.maxTiles = gw * gh * 4;
		navParams.maxPolys = 1 << 14; // 16384 polys per tile max

		if (navMesh.Init(&navParams) != .Success)
		{
			delete tileCache;
			delete navMesh;
			result.ErrorMessage = new String("Could not initialize NavMesh");
			return result;
		}

		tileCache.SetNavMesh(navMesh);

		// Create context
		let ctx = rcCreateContext(1, 1);
		defer { rcDestroyContext(ctx); }

		int32 totalTiles = 0;
		int32 totalPolys = 0;

		// Build each tile
		for (int32 ty = 0; ty < gh; ty++)
		{
			for (int32 tx = 0; tx < gw; tx++)
			{
				int32 tilesBuilt = 0;
				if (!BuildTileCacheTile(ctx, geometry, config, tileCache, navMesh,
					tx, ty, tileSize, borderSize, walkableHeight, walkableClimb, walkableRadius,
					bmin, bmax, out tilesBuilt))
				{
					// Tile may have no geometry - that's okay
					continue;
				}
				totalTiles += tilesBuilt;
			}
		}

		if (totalTiles == 0)
		{
			delete tileCache;
			delete navMesh;
			result.ErrorMessage = new String("No tiles were built");
			return result;
		}

		// Count total polys
		for (int32 i = 0; i < navMesh.MaxTiles; i++)
		{
			let tile = navMesh.GetTile(i);
			if (tile != null && tile.header != null)
				totalPolys += tile.header.polyCount;
		}

		result.Success = true;
		result.NavMesh = navMesh;
		result.TileCache = tileCache;
		result.Stats = .() {
			VertexCount = 0, // Not tracked for tiled
			PolyCount = totalPolys,
			TileCount = totalTiles
		};

		return result;
	}

	/// Builds a single tile for TileCache.
	private static bool BuildTileCacheTile(
		rcContextHandle ctx,
		IInputGeometryProvider geometry,
		in NavMeshBuildConfig config,
		TileCache tileCache,
		NavMesh navMesh,
		int32 tx, int32 ty,
		int32 tileSize,
		int32 borderSize,
		int32 walkableHeight,
		int32 walkableClimb,
		int32 walkableRadius,
		float[3] worldBMin,
		float[3] worldBMax,
		out int32 tilesBuilt)
	{
		tilesBuilt = 0;

		float tcs = tileSize * config.CellSize;

		// Calculate tile bounds with border
		float[3] tileBMin;
		float[3] tileBMax;

		tileBMin[0] = worldBMin[0] + tx * tcs;
		tileBMin[1] = worldBMin[1];
		tileBMin[2] = worldBMin[2] + ty * tcs;

		tileBMax[0] = worldBMin[0] + (tx + 1) * tcs;
		tileBMax[1] = worldBMax[1];
		tileBMax[2] = worldBMin[2] + (ty + 1) * tcs;

		// Expand by border
		tileBMin[0] -= borderSize * config.CellSize;
		tileBMin[2] -= borderSize * config.CellSize;
		tileBMax[0] += borderSize * config.CellSize;
		tileBMax[2] += borderSize * config.CellSize;

		// Calculate grid size for this tile
		int32 tileSizeWithBorder = tileSize + borderSize * 2;

		// Create heightfield
		let hf = rcAllocHeightfield();
		defer { rcFreeHeightField(hf); }

		if (rcCreateHeightfield(ctx, hf, tileSizeWithBorder, tileSizeWithBorder,
			&tileBMin[0], &tileBMax[0], config.CellSize, config.CellHeight) == 0)
		{
			return false;
		}

		// Rasterize triangles
		int32 ntris = geometry.TriangleCount;
		uint8* triareas = new uint8[ntris]*;
		defer { delete triareas; }

		Internal.MemSet(triareas, 0, ntris);
		rcMarkWalkableTriangles(ctx, config.AgentMaxSlope, geometry.Vertices, geometry.VertexCount,
			geometry.Triangles, ntris, triareas);

		if (rcRasterizeTriangles(ctx, geometry.Vertices, geometry.VertexCount,
			geometry.Triangles, triareas, ntris, hf, walkableClimb) == 0)
		{
			return false;
		}

		// Filter walkables
		rcFilterLowHangingWalkableObstacles(ctx, walkableClimb, hf);
		rcFilterLedgeSpans(ctx, walkableHeight, walkableClimb, hf);
		rcFilterWalkableLowHeightSpans(ctx, walkableHeight, hf);

		// Build compact heightfield
		let chf = rcAllocCompactHeightfield();
		defer { rcFreeCompactHeightfield(chf); }

		if (rcBuildCompactHeightfield(ctx, walkableHeight, walkableClimb, hf, chf) == 0)
		{
			return false;
		}

		// Erode walkable area
		if (rcErodeWalkableArea(ctx, walkableRadius, chf) == 0)
		{
			return false;
		}

		// Build heightfield layers
		let lset = rcAllocHeightfieldLayerSet();
		defer { rcFreeHeightfieldLayerSet(lset); }

		if (rcBuildHeightfieldLayers(ctx, chf, borderSize, walkableHeight, lset) == 0)
		{
			return false;
		}

		int32 nlayers = rcHeightfieldLayerSetGetNLayers(lset);
		if (nlayers == 0)
			return false;

		let layers = rcHeightfieldLayerSetGetLayers(lset);

		// Build TileCache layers for each heightfield layer
		for (int32 i = 0; i < nlayers; i++)
		{
			let layer = &layers[i];

			// Create TileCache layer header
			dtTileCacheLayerHeader header = .();
			header.magic = DT_TILECACHE_MAGIC;
			header.version = DT_TILECACHE_VERSION;
			header.tx = tx;
			header.ty = ty;
			header.tlayer = i;

			header.bmin[0] = layer.bmin[0];
			header.bmin[1] = layer.bmin[1];
			header.bmin[2] = layer.bmin[2];
			header.bmax[0] = layer.bmax[0];
			header.bmax[1] = layer.bmax[1];
			header.bmax[2] = layer.bmax[2];

			header.width = (uint8)layer.width;
			header.height = (uint8)layer.height;
			header.minx = (uint8)layer.minx;
			header.maxx = (uint8)layer.maxx;
			header.miny = (uint8)layer.miny;
			header.maxy = (uint8)layer.maxy;
			header.hmin = (uint16)layer.hmin;
			header.hmax = (uint16)layer.hmax;

			// Build compressed tile data
			uint8* tileData = null;
			int32 tileDataSize = 0;

			let compHandle = tileCache.CompressorHandle;
			if (compHandle == null)
				continue;

			let status = dtBuildTileCacheLayer(compHandle, &header,
				layer.heights, layer.areas, layer.cons,
				&tileData, &tileDataSize);

			if (!StatusHelper.IsSuccess(status) || tileData == null)
				continue;

			// Add tile to cache
			dtCompressedTileRef tileRef = 0;
			if (tileCache.AddTile(tileData, tileDataSize, (uint8)dtCompressedTileFlags.DT_COMPRESSEDTILE_FREE_DATA, out tileRef) == .Success)
			{
				// Build navmesh tile from cache
				tileCache.BuildNavMeshTile(tileRef, navMesh);
				tilesBuilt++;
			}
			else
			{
				dtFree(tileData);
			}
		}

		return tilesBuilt > 0;
	}
}
