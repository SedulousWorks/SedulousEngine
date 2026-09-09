using System;
using System.Collections;
using Sedulous.Core;
using recastnavigation_Beef;

namespace Sedulous.Navigation;

/// The bake.
///
/// A triangle soup and an agent profile go in; a serialized tiled navmesh blob comes out.
/// PURE and DETERMINISTIC: the same input and parameters produce byte identical output, since
/// nothing in this path threads or randomises.
static class NavigationMeshBuilder
{
	/// The flag every walkable polygon is baked with. NON ZERO, so the default query filter,
	/// which includes everything, accepts it.
	private const uint16 cPolyFlagWalk = 0x01;

	/// The most stage samples kept, and how many cells are skipped between them. A diagnostic
	/// overlay rather than an export: a large zone would otherwise produce millions.
	private const int cMaxStageSamples = 60000;
	private const int cStageStride = 2;

	/// The grid the tiles sit on, derived from the geometry's own bounds.
	private struct TileGrid
	{
		public float[3] BMin;
		public float[3] BMax;
		public float TileWorldSize;
		public int32 CountX;
		public int32 CountY;
	}

	private static bool ComputeTileGrid(Span<Float3> vertices, NavigationBakeParams parameters,
		out TileGrid outGrid)
	{
		outGrid = .();
		if (vertices.IsEmpty || (parameters.TileCells == 0))
			return false;

		for (int c < 3)
		{
			outGrid.BMin[c] = vertices[0][c];
			outGrid.BMax[c] = vertices[0][c];
		}
		for (int i = 1; i < vertices.Length; i++)
		{
			for (int c < 3)
			{
				outGrid.BMin[c] = Min(outGrid.BMin[c], vertices[i][c]);
				outGrid.BMax[c] = Max(outGrid.BMax[c], vertices[i][c]);
			}
		}

		outGrid.TileWorldSize = (float)parameters.TileCells * parameters.CellSize;
		outGrid.CountX = (int32)Ceil((outGrid.BMax[0] - outGrid.BMin[0])
			/ outGrid.TileWorldSize);
		outGrid.CountY = (int32)Ceil((outGrid.BMax[2] - outGrid.BMin[2])
			/ outGrid.TileWorldSize);
		// Geometry thinner than one tile still gets one.
		outGrid.CountX = Max(outGrid.CountX, 1);
		outGrid.CountY = Max(outGrid.CountY, 1);
		return true;
	}

	/// Bakes into a blob. The status says what happened:
	///
	/// Ok, and the blob is filled; InvalidArgument for empty or malformed input; Internal when
	/// a stage of the bake failed; NotFound when the bake produced no walkable polygon at all,
	/// which is degenerate geometry or an agent that fits nowhere, and leaves the blob empty.
	public static Result<void, ErrorCode> Build(Span<Float3> vertices, Span<uint32> indices,
		NavigationBakeParams parameters, List<uint8> outData)
	{
		return BuildTiled(vertices, indices, parameters, outData, null);
	}

	/// The tiled bake: the geometry's bounds split into tiles, each baked independently and
	/// assembled ROW MAJOR into one blob. An empty tile is simply absent.
	public static Result<void, ErrorCode> BuildTiled(Span<Float3> vertices, Span<uint32> indices,
		NavigationBakeParams parameters, List<uint8> outData,
		NavigationBakeStages outStages = null)
	{
		outData.Clear();
		if (vertices.IsEmpty || indices.IsEmpty || ((indices.Length % 3) != 0))
			return .Err(.InvalidArgument);
		if (!ComputeTileGrid(vertices, parameters, let grid))
			return .Err(.InvalidArgument);

		let tileTotal = (int)grid.CountX * (int)grid.CountY;

		let records = scope List<NavigationBlob.TileRecord>();
		let tiles = scope List<List<uint8>>();
		defer { ClearAndDeleteItems!(tiles); }
		var payloadBytes = 0;

		// Row major, which is what makes the blob deterministic. Raptor bakes the tiles across
		// workers and assembles in this same order; here they bake in it, and the bytes are
		// the same either way.
		for (int index = 0; index < tileTotal; index++)
		{
			let tileX = (int32)(index % (int)grid.CountX);
			let tileY = (int32)(index / (int)grid.CountX);

			let tileData = new List<uint8>();
			let status = BuildOneTile(vertices, indices, parameters, grid, tileX, tileY, tileData,
				outStages);

			if (status case .Err(let error))
			{
				if (error != .NotFound)
				{
					delete tileData;
					return .Err(error);
				}
				// An empty tile is NORMAL: most of a grid sits off the geometry.
				delete tileData;
				continue;
			}

			records.Add(.() { TileX = tileX, TileY = tileY, DataSize = (uint32)tileData.Count });
			payloadBytes += NavigationBlob.TileRecordSize + tileData.Count;
			tiles.Add(tileData);
		}

		if (records.IsEmpty)
			return .Err(.NotFound);

		var info = NavigationBlob.TiledInfo();
		info.Origin[0] = grid.BMin[0];
		info.Origin[1] = grid.BMin[1];
		info.Origin[2] = grid.BMin[2];
		info.TileWorldSize = grid.TileWorldSize;
		info.TileCountX = grid.CountX;
		info.TileCountY = grid.CountY;
		info.TileCount = (uint32)records.Count;

		let header = NavigationBlob.Header()
			{
				Magic = NavigationBlob.Magic,
				Version = NavigationBlob.VersionTiled,
				AgentRadius = parameters.AgentRadius,
				AgentHeight = parameters.AgentHeight,
				NavDataSize = (uint32)(NavigationBlob.TiledInfoSize + payloadBytes)
			};

		NavigationBlob.Append(outData, header);
		NavigationBlob.Append(outData, info);
		for (int i = 0; i < records.Count; i++)
		{
			NavigationBlob.Append(outData, records[i]);
			NavigationBlob.Append(outData, Span<uint8>(tiles[i].Ptr, tiles[i].Count));
		}
		return .Ok;
	}

	/// Bakes ONE tile of the grid the full bake would derive from these bounds, to raw tile
	/// data. The tiled bake is exactly this in a loop, so a regenerated tile is byte identical
	/// to the one the full bake produced.
	public static Result<void, ErrorCode> BuildTileAt(Span<Float3> vertices, Span<uint32> indices,
		NavigationBakeParams parameters, int32 tileX, int32 tileY, List<uint8> outTileData)
	{
		outTileData.Clear();
		if (vertices.IsEmpty || indices.IsEmpty || ((indices.Length % 3) != 0))
			return .Err(.InvalidArgument);
		if (!ComputeTileGrid(vertices, parameters, let grid))
			return .Err(.InvalidArgument);

		return BuildOneTile(vertices, indices, parameters, grid, tileX, tileY, outTileData, null);
	}

	/// Rebuilds one tile against an EXPLICIT grid, which is the one a previous bake recorded.
	///
	/// Edited geometry may shift the bounds, and a patched tile has to stay on the original
	/// grid or it lands somewhere else entirely. The horizontal anchoring comes from the
	/// recorded grid; the VERTICAL range from the geometry as it is now, since a rebake may
	/// add taller or lower content without invalidating the grid.
	public static Result<void, ErrorCode> BuildTileInGrid(Span<Float3> vertices,
		Span<uint32> indices, NavigationBakeParams parameters, NavigationTileGridDesc gridDesc,
		int32 tileX, int32 tileY, List<uint8> outTileData)
	{
		outTileData.Clear();
		if (vertices.IsEmpty || indices.IsEmpty || ((indices.Length % 3) != 0)
			|| (gridDesc.TileWorldSize <= 0.0f) || (gridDesc.CountX <= 0)
			|| (gridDesc.CountY <= 0))
			return .Err(.InvalidArgument);

		var grid = TileGrid();
		grid.BMin[0] = gridDesc.Origin.X;
		grid.BMin[2] = gridDesc.Origin.Z;
		grid.TileWorldSize = gridDesc.TileWorldSize;
		grid.CountX = gridDesc.CountX;
		grid.CountY = gridDesc.CountY;

		grid.BMin[1] = vertices[0].Y;
		grid.BMax[1] = vertices[0].Y;
		for (int i = 1; i < vertices.Length; i++)
		{
			grid.BMin[1] = Min(grid.BMin[1], vertices[i].Y);
			grid.BMax[1] = Max(grid.BMax[1], vertices[i].Y);
		}
		grid.BMax[0] = grid.BMin[0] + (float)grid.CountX * grid.TileWorldSize;
		grid.BMax[2] = grid.BMin[2] + (float)grid.CountY * grid.TileWorldSize;

		return BuildOneTile(vertices, indices, parameters, grid, tileX, tileY, outTileData, null);
	}

	/// The Recast pipeline for ONE tile.
	///
	/// The tile's bounds are expanded by a BORDER so neighbours overlap and their edge
	/// polygons stitch; the border region itself never emits a polygon. NotFound, with empty
	/// data, is a tile with no walkable surface, which is the normal answer for most of a grid.
	private static Result<void, ErrorCode> BuildOneTile(Span<Float3> vertices,
		Span<uint32> indices, NavigationBakeParams parameters, TileGrid grid, int32 tileX,
		int32 tileY, List<uint8> outNavData, NavigationBakeStages outStages)
	{
		outNavData.Clear();
		if ((tileX < 0) || (tileY < 0) || (tileX >= grid.CountX) || (tileY >= grid.CountY))
			return .Err(.InvalidArgument);

		let vertexCount = (int32)vertices.Length;
		let triangleCount = (int32)(indices.Length / 3);

		// Recast takes signed indices, and an index past the end would read off the vertices.
		let tris = scope int32[indices.Length];
		for (int i = 0; i < indices.Length; i++)
		{
			if (indices[i] >= (uint32)vertices.Length)
				return .Err(.InvalidArgument);
			tris[i] = (int32)indices[i];
		}
		let verts = (float*)vertices.Ptr;

		let cellSize = parameters.CellSize;
		let cellHeight = parameters.CellHeight;
		let walkableHeight = (int32)Ceil(parameters.AgentHeight / cellHeight);
		let walkableClimb = (int32)Floor(parameters.AgentMaxClimb / cellHeight);
		let walkableRadius = (int32)Ceil(parameters.AgentRadius / cellSize);
		let maxEdgeLen = (int32)(12.0f / cellSize);
		const float cMaxSimplificationError = 1.3f;
		const int32 cMinRegionArea = 8 * 8;
		const int32 cMergeRegionArea = 20 * 20;
		let detailSampleDist = cellSize * 6.0f;
		let detailSampleMaxError = cellHeight * 1.0f;
		let tileSize = (int32)parameters.TileCells;
		// Recast's own tile sample expansion.
		let borderSize = walkableRadius + 3;
		let width = tileSize + borderSize * 2;
		let height = tileSize + borderSize * 2;

		float[3] bmin = .(
			grid.BMin[0] + (float)tileX * grid.TileWorldSize,
			grid.BMin[1],
			grid.BMin[2] + (float)tileY * grid.TileWorldSize);
		float[3] bmax = .(
			bmin[0] + grid.TileWorldSize,
			grid.BMax[1],
			bmin[2] + grid.TileWorldSize);
		bmin[0] -= (float)borderSize * cellSize;
		bmin[2] -= (float)borderSize * cellSize;
		bmax[0] += (float)borderSize * cellSize;
		bmax[2] += (float)borderSize * cellSize;

		let ctx = C_rcCreateContext(0, 0);
		if (ctx == null)
			return .Err(.Internal);
		defer C_rcDestroyContext(ctx);

		let solid = C_rcAllocHeightfield();
		let chf = C_rcAllocCompactHeightfield();
		let cset = C_rcAllocContourSet();
		let pmesh = C_rcAllocPolyMesh();
		let dmesh = C_rcAllocPolyMeshDetail();
		// Freed in reverse, whatever happens: every stage after a failure is skipped, and the
		// ones already built still have to go.
		defer
		{
			C_rcFreePolyMeshDetail(dmesh);
			C_rcFreePolyMesh(pmesh);
			C_rcFreeContourSet(cset);
			C_rcFreeCompactHeightfield(chf);
			C_rcFreeHeightField(solid);
		}

		if ((solid == null) || (chf == null) || (cset == null) || (pmesh == null)
			|| (dmesh == null))
			return .Err(.Internal);

		if (C_rcCreateHeightfield(ctx, solid, width, height, &bmin[0], &bmax[0], cellSize,
			cellHeight) == 0)
			return .Err(.Internal);

		let triAreas = scope uint8[Max(triangleCount, 1)];
		C_rcMarkWalkableTriangles(ctx, parameters.AgentMaxSlopeDegrees, verts, vertexCount,
			&tris[0], triangleCount, &triAreas[0]);
		if (C_rcRasterizeTriangles(ctx, verts, vertexCount, &tris[0], &triAreas[0], triangleCount,
			solid, walkableClimb) == 0)
			return .Err(.Internal);

		C_rcFilterLowHangingWalkableObstacles(ctx, walkableClimb, solid);
		C_rcFilterLedgeSpans(ctx, walkableHeight, walkableClimb, solid);
		C_rcFilterWalkableLowHeightSpans(ctx, walkableHeight, solid);

		// The spans are captured BEFORE the erosion, since where geometry rasterised and where
		// it survived are different questions and the first is the one being debugged.
		if (outStages != null)
			CaptureSpans(solid, bmin, cellSize, cellHeight, outStages);

		if (C_rcBuildCompactHeightfield(ctx, walkableHeight, walkableClimb, solid, chf) == 0)
			return .Err(.Internal);
		if (C_rcErodeWalkableArea(ctx, walkableRadius, chf) == 0)
			return .Err(.Internal);
		if ((C_rcBuildDistanceField(ctx, chf) == 0)
			|| (C_rcBuildRegions(ctx, chf, borderSize, cMinRegionArea, cMergeRegionArea) == 0))
			return .Err(.Internal);
		if (C_rcBuildContours(ctx, chf, cMaxSimplificationError, maxEdgeLen, cset,
			(int32)rcBuildContoursFlags.RC_CONTOUR_TESS_WALL_EDGES) == 0)
			return .Err(.Internal);

		if (outStages != null)
			CaptureContours(cset, outStages);

		if (C_rcBuildPolyMesh(ctx, cset, DT_VERTS_PER_POLYGON, pmesh) == 0)
			return .Err(.Internal);
		if (C_rcBuildPolyMeshDetail(ctx, pmesh, chf, detailSampleDist, detailSampleMaxError,
			dmesh) == 0)
			return .Err(.Internal);

		let polyCount = C_rcPolyMeshGetNPolys(pmesh);
		if (polyCount == 0)
			return .Err(.NotFound);

		// Every walkable polygon gets the one flag we bake, so the default query filter
		// accepts it.
		let areas = C_rcPolyMeshGetAreas(pmesh);
		let flags = C_rcPolyMeshGetFlags(pmesh);
		for (int32 i = 0; i < polyCount; i++)
		{
			if (areas[i] == RC_WALKABLE_AREA)
				flags[i] = cPolyFlagWalk;
		}

		return CreateTileData(pmesh, dmesh, parameters, tileX, tileY, cellSize, cellHeight,
			outNavData);
	}

	private static Result<void, ErrorCode> CreateTileData(rcPolyMeshHandle pmesh,
		rcPolyMeshDetailHandle dmesh, NavigationBakeParams parameters, int32 tileX, int32 tileY,
		float cellSize, float cellHeight, List<uint8> outNavData)
	{
		float[3] pmeshMin = .();
		float[3] pmeshMax = .();
		C_rcPolyMeshGetBMin(pmesh, &pmeshMin[0]);
		C_rcPolyMeshGetBMax(pmesh, &pmeshMax[0]);

		var np = dtNavMeshCreateParams();
		np.verts = C_rcPolyMeshGetVerts(pmesh);
		np.vertCount = C_rcPolyMeshGetNVerts(pmesh);
		np.polys = C_rcPolyMeshGetPolys(pmesh);
		np.polyAreas = C_rcPolyMeshGetAreas(pmesh);
		np.polyFlags = C_rcPolyMeshGetFlags(pmesh);
		np.polyCount = C_rcPolyMeshGetNPolys(pmesh);
		np.nvp = C_rcPolyMeshGetNvp(pmesh);
		np.detailMeshes = C_rcPolyMeshDetailGetMeshes(dmesh);
		np.detailVerts = C_rcPolyMeshDetailGetVerts(dmesh);
		np.detailVertsCount = C_rcPolyMeshDetailGetNVerts(dmesh);
		np.detailTris = C_rcPolyMeshDetailGetTris(dmesh);
		np.detailTriCount = C_rcPolyMeshDetailGetNTris(dmesh);
		np.walkableHeight = parameters.AgentHeight;
		np.walkableRadius = parameters.AgentRadius;
		np.walkableClimb = parameters.AgentMaxClimb;
		np.tileX = tileX;
		np.tileY = tileY;
		np.tileLayer = 0;
		np.bmin = pmeshMin;
		np.bmax = pmeshMax;
		np.cs = cellSize;
		np.ch = cellHeight;
		np.buildBvTree = 1;

		uint8* navData = null;
		int32 navDataSize = 0;
		if ((C_dtCreateNavMeshData(&np, &navData, &navDataSize) == 0) || (navData == null)
			|| (navDataSize <= 0))
			return .Err(.Internal);

		// Copied out, because the blob outlives the allocation the backend made.
		NavigationBlob.Append(outNavData, Span<uint8>(navData, navDataSize));
		C_dtFree(navData);
		return .Ok;
	}

	/// The walkable span tops, strided and capped.
	private static void CaptureSpans(rcHeightfieldHandle solid, float[3] bmin, float cellSize,
		float cellHeight, NavigationBakeStages outStages)
	{
		let width = C_rcHeightfieldGetWidth(solid);
		let height = C_rcHeightfieldGetHeight(solid);
		let spans = C_rcHeightfieldGetSpans(solid);
		if (spans == null)
			return;

		for (int32 y = 0; y < height; y += cStageStride)
		{
			for (int32 x = 0; x < width; x += cStageStride)
			{
				if (outStages.WalkableSamples.Count >= cMaxStageSamples)
					return;

				var span = spans[x + y * width];
				while (span != null)
				{
					if (span.area != RC_NULL_AREA)
						outStages.WalkableSamples.Add(.(
							bmin[0] + ((float)x + 0.5f) * cellSize,
							bmin[1] + (float)span.smax * cellHeight,
							bmin[2] + ((float)y + 0.5f) * cellSize));
					span = span.next;
				}
			}
		}
	}

	/// The simplified contours as segment pairs: the region outlines the polygons come from.
	private static void CaptureContours(rcContourSetHandle cset, NavigationBakeStages outStages)
	{
		let count = C_rcContourSetGetNConts(cset);
		let contours = C_rcContourSetGetConts(cset);
		if ((count <= 0) || (contours == null))
			return;

		float[3] bmin = .();
		C_rcContourSetGetBMin(cset, &bmin[0]);
		let cs = C_rcContourSetGetCs(cset);
		let ch = C_rcContourSetGetCh(cset);

		for (int32 c = 0; c < count; c++)
		{
			let contour = contours[c];
			for (int32 v = 0; v < contour.nverts; v++)
			{
				// A contour is a CLOSED loop, so the last vertex pairs with the first.
				let a = &contour.verts[v * 4];
				let b = &contour.verts[((v + 1) % contour.nverts) * 4];
				outStages.ContourLines.Add(.(bmin[0] + (float)a[0] * cs,
					bmin[1] + (float)a[1] * ch, bmin[2] + (float)a[2] * cs));
				outStages.ContourLines.Add(.(bmin[0] + (float)b[0] * cs,
					bmin[1] + (float)b[1] * ch, bmin[2] + (float)b[2] * cs));
			}
		}
	}
}
