using System;

namespace recastnavigation_Beef;

/* Types */
typealias dtStatus = uint32;
typealias dtPolyRef = uint32;
typealias dtTileRef = uint32;

/* Opaque handle types */
typealias dtNavMeshHandle = void*;
typealias dtNavMeshQueryHandle = void*;
typealias dtQueryFilterHandle = void*;

/* Constants */
static
{
	public const int32 DT_VERTS_PER_POLYGON = 6;
	public const int32 DT_NAVMESH_MAGIC = ((int32)'D' << 24 | (int32)'N' << 16 | (int32)'A' << 8 | (int32)'V');
	public const int32 DT_NAVMESH_VERSION = 7;
	public const int32 DT_NAVMESH_STATE_MAGIC = ((int32)'D' << 24 | (int32)'N' << 16 | (int32)'M' << 8 | (int32)'S');
	public const int32 DT_NAVMESH_STATE_VERSION = 1;
	public const uint16 DT_EXT_LINK = 0x8000;
	public const uint32 DT_NULL_LINK = 0xffffffff;
	public const uint8 DT_OFFMESH_CON_BIDIR = 1;
	public const int32 DT_MAX_AREAS = 64;

	/* Status flags */
	public const uint32 DT_FAILURE = (1u << 31);
	public const uint32 DT_SUCCESS = (1u << 30);
	public const uint32 DT_IN_PROGRESS = (1u << 29);
	public const uint32 DT_STATUS_DETAIL_MASK = 0x00ffffff;
	public const uint32 DT_WRONG_MAGIC = (1 << 0);
	public const uint32 DT_WRONG_VERSION = (1 << 1);
	public const uint32 DT_OUT_OF_MEMORY = (1 << 2);
	public const uint32 DT_INVALID_PARAM = (1 << 3);
	public const uint32 DT_BUFFER_TOO_SMALL = (1 << 4);
	public const uint32 DT_OUT_OF_NODES = (1 << 5);
	public const uint32 DT_PARTIAL_RESULT = (1 << 6);
	public const uint32 DT_ALREADY_OCCUPIED = (1 << 7);
}

/* Tile flags */
enum dtTileFlags : int32
{
	DT_TILE_FREE_DATA = 0x01
}

/* Straight path flags */
enum dtStraightPathFlags : int32
{
	DT_STRAIGHTPATH_START = 0x01,
	DT_STRAIGHTPATH_END = 0x02,
	DT_STRAIGHTPATH_OFFMESH_CONNECTION = 0x04
}

/* Straight path options */
enum dtStraightPathOptions : int32
{
	DT_STRAIGHTPATH_AREA_CROSSINGS = 0x01,
	DT_STRAIGHTPATH_ALL_CROSSINGS = 0x02
}

/* Find path options */
enum dtFindPathOptions : int32
{
	DT_FINDPATH_ANY_ANGLE = 0x02
}

/* Raycast options */
enum dtRaycastOptions : int32
{
	DT_RAYCAST_USE_COSTS = 0x01
}

/* Poly types */
enum dtPolyTypes : int32
{
	DT_POLYTYPE_GROUND = 0,
	DT_POLYTYPE_OFFMESH_CONNECTION = 1
}

/* Allocation hints */
enum dtAllocHint : int32
{
	DT_ALLOC_PERM,
	DT_ALLOC_TEMP
}

/* Polygon structure */
[CRepr]
struct dtPoly
{
	public uint32 firstLink;
	public uint16[DT_VERTS_PER_POLYGON] verts;
	public uint16[DT_VERTS_PER_POLYGON] neis;
	public uint16 flags;
	public uint8 vertCount;
	public uint8 areaAndtype;
}

/* Poly detail structure */
[CRepr]
struct dtPolyDetail
{
	public uint32 vertBase;
	public uint32 triBase;
	public uint8 vertCount;
	public uint8 triCount;
}

/* Link structure */
[CRepr]
struct dtLink
{
	public dtPolyRef @ref;
	public uint32 next;
	public uint8 edge;
	public uint8 side;
	public uint8 bmin;
	public uint8 bmax;
}

/* BV Node */
[CRepr]
struct dtBVNode
{
	public uint16[3] bmin;
	public uint16[3] bmax;
	public int32 i;
}

/* Off-mesh connection */
[CRepr]
struct dtOffMeshConnection
{
	public float[6] pos;
	public float rad;
	public uint16 poly;
	public uint8 flags;
	public uint8 side;
	public uint32 userId;
}

/* Mesh header */
[CRepr]
struct dtMeshHeader
{
	public int32 magic;
	public int32 version;
	public int32 x;
	public int32 y;
	public int32 layer;
	public uint32 userId;
	public int32 polyCount;
	public int32 vertCount;
	public int32 maxLinkCount;
	public int32 detailMeshCount;
	public int32 detailVertCount;
	public int32 detailTriCount;
	public int32 bvNodeCount;
	public int32 offMeshConCount;
	public int32 offMeshBase;
	public float walkableHeight;
	public float walkableRadius;
	public float walkableClimb;
	public float[3] bmin;
	public float[3] bmax;
	public float bvQuantFactor;
}

/* Mesh tile */
[CRepr]
struct dtMeshTile
{
	public uint32 salt;
	public uint32 linksFreeList;
	public dtMeshHeader* header;
	public dtPoly* polys;
	public float* verts;
	public dtLink* links;
	public dtPolyDetail* detailMeshes;
	public float* detailVerts;
	public uint8* detailTris;
	public dtBVNode* bvTree;
	public dtOffMeshConnection* offMeshCons;
	public uint8* data;
	public int32 dataSize;
	public int32 flags;
	public dtMeshTile* next;
}

/* Nav mesh params */
[CRepr]
struct dtNavMeshParams
{
	public float[3] orig;
	public float tileWidth;
	public float tileHeight;
	public int32 maxTiles;
	public int32 maxPolys;
}

/* Nav mesh create params */
[CRepr]
struct dtNavMeshCreateParams
{
	public uint16* verts;
	public int32 vertCount;
	public uint16* polys;
	public uint16* polyFlags;
	public uint8* polyAreas;
	public int32 polyCount;
	public int32 nvp;
	public uint32* detailMeshes;
	public float* detailVerts;
	public int32 detailVertsCount;
	public uint8* detailTris;
	public int32 detailTriCount;
	public float* offMeshConVerts;
	public float* offMeshConRad;
	public uint16* offMeshConFlags;
	public uint8* offMeshConAreas;
	public uint8* offMeshConDir;
	public uint32* offMeshConUserID;
	public int32 offMeshConCount;
	public uint32 userId;
	public int32 tileX;
	public int32 tileY;
	public int32 tileLayer;
	public float[3] bmin;
	public float[3] bmax;
	public float walkableHeight;
	public float walkableRadius;
	public float walkableClimb;
	public float cs;
	public float ch;
	public int32 buildBvTree;
}

/* Raycast hit */
[CRepr]
struct dtRaycastHit
{
	public float t;
	public float[3] hitNormal;
	public int32 hitEdgeIndex;
	public dtPolyRef* path;
	public int32 pathCount;
	public int32 maxPath;
	public float pathCost;
}

/* Function pointer types */
function void* dtAllocFunc(int size, dtAllocHint hint);
function void dtFreeFunc(void* ptr);
function float dtRandFunc();

/* Functions */
static
{
	/* Memory allocation */
	[CLink]
	public static extern void C_dtAllocSetCustom(dtAllocFunc allocFunc, dtFreeFunc freeFunc);
	[CLink]
	public static extern void* C_dtAlloc(int size, dtAllocHint hint);
	[CLink]
	public static extern void C_dtFree(void* ptr);

	/* Status helpers */
	[CLink]
	public static extern int32 C_dtStatusSucceed(dtStatus status);
	[CLink]
	public static extern int32 C_dtStatusFailed(dtStatus status);
	[CLink]
	public static extern int32 C_dtStatusInProgress(dtStatus status);
	[CLink]
	public static extern int32 C_dtStatusDetail(dtStatus status, uint32 detail);

	/* Nav mesh creation/destruction */
	[CLink]
	public static extern dtNavMeshHandle C_dtAllocNavMesh();
	[CLink]
	public static extern void C_dtFreeNavMesh(dtNavMeshHandle navmesh);

	/* Nav mesh initialization */
	[CLink]
	public static extern dtStatus C_dtNavMeshInit(dtNavMeshHandle navmesh, dtNavMeshParams* @params);
	[CLink]
	public static extern dtStatus C_dtNavMeshInitSingle(dtNavMeshHandle navmesh, uint8* data, int32 dataSize, int32 flags);

	/* Nav mesh params */
	[CLink]
	public static extern dtNavMeshParams* C_dtNavMeshGetParams(dtNavMeshHandle navmesh);

	/* Tile management */
	[CLink]
	public static extern dtStatus C_dtNavMeshAddTile(dtNavMeshHandle navmesh, uint8* data, int32 dataSize,
		int32 flags, dtTileRef lastRef, dtTileRef* result);
	[CLink]
	public static extern dtStatus C_dtNavMeshRemoveTile(dtNavMeshHandle navmesh, dtTileRef @ref,
		uint8** data, int32* dataSize);

	/* Tile queries */
	[CLink]
	public static extern void C_dtNavMeshCalcTileLoc(dtNavMeshHandle navmesh, float* pos, int32* tx, int32* ty);
	[CLink]
	public static extern dtMeshTile* C_dtNavMeshGetTileAt(dtNavMeshHandle navmesh, int32 x, int32 y, int32 layer);
	[CLink]
	public static extern int32 C_dtNavMeshGetTilesAt(dtNavMeshHandle navmesh, int32 x, int32 y, dtMeshTile** tiles, int32 maxTiles);
	[CLink]
	public static extern dtTileRef C_dtNavMeshGetTileRefAt(dtNavMeshHandle navmesh, int32 x, int32 y, int32 layer);
	[CLink]
	public static extern dtTileRef C_dtNavMeshGetTileRef(dtNavMeshHandle navmesh, dtMeshTile* tile);
	[CLink]
	public static extern dtMeshTile* C_dtNavMeshGetTileByRef(dtNavMeshHandle navmesh, dtTileRef @ref);
	[CLink]
	public static extern int32 C_dtNavMeshGetMaxTiles(dtNavMeshHandle navmesh);
	[CLink]
	public static extern dtMeshTile* C_dtNavMeshGetTile(dtNavMeshHandle navmesh, int32 i);

	/* Polygon queries */
	[CLink]
	public static extern dtStatus C_dtNavMeshGetTileAndPolyByRef(dtNavMeshHandle navmesh, dtPolyRef @ref,
		dtMeshTile** tile, dtPoly** poly);
	[CLink]
	public static extern void C_dtNavMeshGetTileAndPolyByRefUnsafe(dtNavMeshHandle navmesh, dtPolyRef @ref,
		dtMeshTile** tile, dtPoly** poly);
	[CLink]
	public static extern int32 C_dtNavMeshIsValidPolyRef(dtNavMeshHandle navmesh, dtPolyRef @ref);
	[CLink]
	public static extern dtPolyRef C_dtNavMeshGetPolyRefBase(dtNavMeshHandle navmesh, dtMeshTile* tile);

	/* Off-mesh connections */
	[CLink]
	public static extern dtStatus C_dtNavMeshGetOffMeshConnectionPolyEndPoints(dtNavMeshHandle navmesh,
		dtPolyRef prevRef, dtPolyRef polyRef, float* startPos, float* endPos);
	[CLink]
	public static extern dtOffMeshConnection* C_dtNavMeshGetOffMeshConnectionByRef(dtNavMeshHandle navmesh, dtPolyRef @ref);

	/* Polygon state */
	[CLink]
	public static extern dtStatus C_dtNavMeshSetPolyFlags(dtNavMeshHandle navmesh, dtPolyRef @ref, uint16 flags);
	[CLink]
	public static extern dtStatus C_dtNavMeshGetPolyFlags(dtNavMeshHandle navmesh, dtPolyRef @ref, uint16* resultFlags);
	[CLink]
	public static extern dtStatus C_dtNavMeshSetPolyArea(dtNavMeshHandle navmesh, dtPolyRef @ref, uint8 area);
	[CLink]
	public static extern dtStatus C_dtNavMeshGetPolyArea(dtNavMeshHandle navmesh, dtPolyRef @ref, uint8* resultArea);

	/* Tile state */
	[CLink]
	public static extern int32 C_dtNavMeshGetTileStateSize(dtNavMeshHandle navmesh, dtMeshTile* tile);
	[CLink]
	public static extern dtStatus C_dtNavMeshStoreTileState(dtNavMeshHandle navmesh, dtMeshTile* tile,
		uint8* data, int32 maxDataSize);
	[CLink]
	public static extern dtStatus C_dtNavMeshRestoreTileState(dtNavMeshHandle navmesh, dtMeshTile* tile,
		uint8* data, int32 maxDataSize);

	/* Nav mesh data building */
	[CLink]
	public static extern int32 C_dtCreateNavMeshData(dtNavMeshCreateParams* @params, uint8** outData, int32* outDataSize);
	[CLink]
	public static extern int32 C_dtNavMeshHeaderSwapEndian(uint8* data, int32 dataSize);
	[CLink]
	public static extern int32 C_dtNavMeshDataSwapEndian(uint8* data, int32 dataSize);

	/* Query filter */
	[CLink]
	public static extern dtQueryFilterHandle C_dtAllocQueryFilter();
	[CLink]
	public static extern void C_dtFreeQueryFilter(dtQueryFilterHandle filter);
	[CLink]
	public static extern float C_dtQueryFilterGetAreaCost(dtQueryFilterHandle filter, int32 i);
	[CLink]
	public static extern void C_dtQueryFilterSetAreaCost(dtQueryFilterHandle filter, int32 i, float cost);
	[CLink]
	public static extern uint16 C_dtQueryFilterGetIncludeFlags(dtQueryFilterHandle filter);
	[CLink]
	public static extern void C_dtQueryFilterSetIncludeFlags(dtQueryFilterHandle filter, uint16 flags);
	[CLink]
	public static extern uint16 C_dtQueryFilterGetExcludeFlags(dtQueryFilterHandle filter);
	[CLink]
	public static extern void C_dtQueryFilterSetExcludeFlags(dtQueryFilterHandle filter, uint16 flags);

	/* Nav mesh query creation/destruction */
	[CLink]
	public static extern dtNavMeshQueryHandle C_dtAllocNavMeshQuery();
	[CLink]
	public static extern void C_dtFreeNavMeshQuery(dtNavMeshQueryHandle query);

	/* Query initialization */
	[CLink]
	public static extern dtStatus C_dtNavMeshQueryInit(dtNavMeshQueryHandle query, dtNavMeshHandle nav, int32 maxNodes);

	/* Standard pathfinding */
	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFindPath(dtNavMeshQueryHandle query,
		dtPolyRef startRef, dtPolyRef endRef, float* startPos, float* endPos,
		dtQueryFilterHandle filter, dtPolyRef* path, int32* pathCount, int32 maxPath);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFindStraightPath(dtNavMeshQueryHandle query,
		float* startPos, float* endPos, dtPolyRef* path, int32 pathSize,
		float* straightPath, uint8* straightPathFlags, dtPolyRef* straightPathRefs,
		int32* straightPathCount, int32 maxStraightPath, int32 options);

	/* Sliced pathfinding */
	[CLink]
	public static extern dtStatus C_dtNavMeshQueryInitSlicedFindPath(dtNavMeshQueryHandle query,
		dtPolyRef startRef, dtPolyRef endRef, float* startPos, float* endPos,
		dtQueryFilterHandle filter, uint32 options);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryUpdateSlicedFindPath(dtNavMeshQueryHandle query,
		int32 maxIter, int32* doneIters);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFinalizeSlicedFindPath(dtNavMeshQueryHandle query,
		dtPolyRef* path, int32* pathCount, int32 maxPath);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFinalizeSlicedFindPathPartial(dtNavMeshQueryHandle query,
		dtPolyRef* existing, int32 existingSize, dtPolyRef* path, int32* pathCount, int32 maxPath);

	/* Dijkstra search */
	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFindPolysAroundCircle(dtNavMeshQueryHandle query,
		dtPolyRef startRef, float* centerPos, float radius, dtQueryFilterHandle filter,
		dtPolyRef* resultRef, dtPolyRef* resultParent, float* resultCost, int32* resultCount, int32 maxResult);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFindPolysAroundShape(dtNavMeshQueryHandle query,
		dtPolyRef startRef, float* verts, int32 nverts, dtQueryFilterHandle filter,
		dtPolyRef* resultRef, dtPolyRef* resultParent, float* resultCost, int32* resultCount, int32 maxResult);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryGetPathFromDijkstraSearch(dtNavMeshQueryHandle query,
		dtPolyRef endRef, dtPolyRef* path, int32* pathCount, int32 maxPath);

	/* Local queries */
	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFindNearestPoly(dtNavMeshQueryHandle query,
		float* center, float* halfExtents, dtQueryFilterHandle filter,
		dtPolyRef* nearestRef, float* nearestPt);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFindNearestPolyEx(dtNavMeshQueryHandle query,
		float* center, float* halfExtents, dtQueryFilterHandle filter,
		dtPolyRef* nearestRef, float* nearestPt, int32* isOverPoly);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryQueryPolygons(dtNavMeshQueryHandle query,
		float* center, float* halfExtents, dtQueryFilterHandle filter,
		dtPolyRef* polys, int32* polyCount, int32 maxPolys);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFindLocalNeighbourhood(dtNavMeshQueryHandle query,
		dtPolyRef startRef, float* centerPos, float radius, dtQueryFilterHandle filter,
		dtPolyRef* resultRef, dtPolyRef* resultParent, int32* resultCount, int32 maxResult);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryMoveAlongSurface(dtNavMeshQueryHandle query,
		dtPolyRef startRef, float* startPos, float* endPos, dtQueryFilterHandle filter,
		float* resultPos, dtPolyRef* visited, int32* visitedCount, int32 maxVisitedSize);

	/* Raycast */
	[CLink]
	public static extern dtStatus C_dtNavMeshQueryRaycast(dtNavMeshQueryHandle query,
		dtPolyRef startRef, float* startPos, float* endPos, dtQueryFilterHandle filter,
		float* t, float* hitNormal, dtPolyRef* path, int32* pathCount, int32 maxPath);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryRaycastEx(dtNavMeshQueryHandle query,
		dtPolyRef startRef, float* startPos, float* endPos, dtQueryFilterHandle filter,
		uint32 options, dtRaycastHit* hit, dtPolyRef prevRef);

	/* Distance queries */
	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFindDistanceToWall(dtNavMeshQueryHandle query,
		dtPolyRef startRef, float* centerPos, float maxRadius, dtQueryFilterHandle filter,
		float* hitDist, float* hitPos, float* hitNormal);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryGetPolyWallSegments(dtNavMeshQueryHandle query,
		dtPolyRef @ref, dtQueryFilterHandle filter, float* segmentVerts, dtPolyRef* segmentRefs,
		int32* segmentCount, int32 maxSegments);

	/* Random point */
	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFindRandomPoint(dtNavMeshQueryHandle query,
		dtQueryFilterHandle filter, dtRandFunc frand, dtPolyRef* randomRef, float* randomPt);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryFindRandomPointAroundCircle(dtNavMeshQueryHandle query,
		dtPolyRef startRef, float* centerPos, float maxRadius, dtQueryFilterHandle filter,
		dtRandFunc frand, dtPolyRef* randomRef, float* randomPt);

	/* Point queries */
	[CLink]
	public static extern dtStatus C_dtNavMeshQueryClosestPointOnPoly(dtNavMeshQueryHandle query,
		dtPolyRef @ref, float* pos, float* closest, int32* posOverPoly);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryClosestPointOnPolyBoundary(dtNavMeshQueryHandle query,
		dtPolyRef @ref, float* pos, float* closest);

	[CLink]
	public static extern dtStatus C_dtNavMeshQueryGetPolyHeight(dtNavMeshQueryHandle query,
		dtPolyRef @ref, float* pos, float* height);

	/* Validation */
	[CLink]
	public static extern int32 C_dtNavMeshQueryIsValidPolyRef(dtNavMeshQueryHandle query,
		dtPolyRef @ref, dtQueryFilterHandle filter);

	[CLink]
	public static extern int32 C_dtNavMeshQueryIsInClosedList(dtNavMeshQueryHandle query, dtPolyRef @ref);

	[CLink]
	public static extern dtNavMeshHandle C_dtNavMeshQueryGetAttachedNavMesh(dtNavMeshQueryHandle query);

	/* Poly helpers */
	[CLink]
	public static extern void C_dtPolySetArea(dtPoly* poly, uint8 area);
	[CLink]
	public static extern void C_dtPolySetType(dtPoly* poly, uint8 type);
	[CLink]
	public static extern uint8 C_dtPolyGetArea(dtPoly* poly);
	[CLink]
	public static extern uint8 C_dtPolyGetType(dtPoly* poly);

	/* Detail tri edge flags */
	[CLink]
	public static extern int32 C_dtGetDetailTriEdgeFlags(uint8 triFlags, int32 edgeIndex);

	/* Wrapper functions */
	public static void dtAllocSetCustom(dtAllocFunc allocFunc, dtFreeFunc freeFunc) => C_dtAllocSetCustom(allocFunc, freeFunc);
	public static void* dtAlloc(int size, dtAllocHint hint) => C_dtAlloc(size, hint);
	public static void dtFree(void* ptr) => C_dtFree(ptr);
	public static int32 dtStatusSucceed(dtStatus status) => C_dtStatusSucceed(status);
	public static int32 dtStatusFailed(dtStatus status) => C_dtStatusFailed(status);
	public static int32 dtStatusInProgress(dtStatus status) => C_dtStatusInProgress(status);
	public static int32 dtStatusDetail(dtStatus status, uint32 detail) => C_dtStatusDetail(status, detail);
	public static dtNavMeshHandle dtAllocNavMesh() => C_dtAllocNavMesh();
	public static void dtFreeNavMesh(dtNavMeshHandle navmesh) => C_dtFreeNavMesh(navmesh);
	public static dtStatus dtNavMeshInit(dtNavMeshHandle navmesh, dtNavMeshParams* @params) => C_dtNavMeshInit(navmesh, @params);
	public static dtStatus dtNavMeshInitSingle(dtNavMeshHandle navmesh, uint8* data, int32 dataSize, int32 flags) => C_dtNavMeshInitSingle(navmesh, data, dataSize, flags);
	public static dtNavMeshParams* dtNavMeshGetParams(dtNavMeshHandle navmesh) => C_dtNavMeshGetParams(navmesh);
	public static dtStatus dtNavMeshAddTile(dtNavMeshHandle navmesh, uint8* data, int32 dataSize, int32 flags, dtTileRef lastRef, dtTileRef* result) => C_dtNavMeshAddTile(navmesh, data, dataSize, flags, lastRef, result);
	public static dtStatus dtNavMeshRemoveTile(dtNavMeshHandle navmesh, dtTileRef @ref, uint8** data, int32* dataSize) => C_dtNavMeshRemoveTile(navmesh, @ref, data, dataSize);
	public static void dtNavMeshCalcTileLoc(dtNavMeshHandle navmesh, float* pos, int32* tx, int32* ty) => C_dtNavMeshCalcTileLoc(navmesh, pos, tx, ty);
	public static dtMeshTile* dtNavMeshGetTileAt(dtNavMeshHandle navmesh, int32 x, int32 y, int32 layer) => C_dtNavMeshGetTileAt(navmesh, x, y, layer);
	public static int32 dtNavMeshGetTilesAt(dtNavMeshHandle navmesh, int32 x, int32 y, dtMeshTile** tiles, int32 maxTiles) => C_dtNavMeshGetTilesAt(navmesh, x, y, tiles, maxTiles);
	public static dtTileRef dtNavMeshGetTileRefAt(dtNavMeshHandle navmesh, int32 x, int32 y, int32 layer) => C_dtNavMeshGetTileRefAt(navmesh, x, y, layer);
	public static dtTileRef dtNavMeshGetTileRef(dtNavMeshHandle navmesh, dtMeshTile* tile) => C_dtNavMeshGetTileRef(navmesh, tile);
	public static dtMeshTile* dtNavMeshGetTileByRef(dtNavMeshHandle navmesh, dtTileRef @ref) => C_dtNavMeshGetTileByRef(navmesh, @ref);
	public static int32 dtNavMeshGetMaxTiles(dtNavMeshHandle navmesh) => C_dtNavMeshGetMaxTiles(navmesh);
	public static dtMeshTile* dtNavMeshGetTile(dtNavMeshHandle navmesh, int32 i) => C_dtNavMeshGetTile(navmesh, i);
	public static dtStatus dtNavMeshGetTileAndPolyByRef(dtNavMeshHandle navmesh, dtPolyRef @ref, dtMeshTile** tile, dtPoly** poly) => C_dtNavMeshGetTileAndPolyByRef(navmesh, @ref, tile, poly);
	public static void dtNavMeshGetTileAndPolyByRefUnsafe(dtNavMeshHandle navmesh, dtPolyRef @ref, dtMeshTile** tile, dtPoly** poly) => C_dtNavMeshGetTileAndPolyByRefUnsafe(navmesh, @ref, tile, poly);
	public static int32 dtNavMeshIsValidPolyRef(dtNavMeshHandle navmesh, dtPolyRef @ref) => C_dtNavMeshIsValidPolyRef(navmesh, @ref);
	public static dtPolyRef dtNavMeshGetPolyRefBase(dtNavMeshHandle navmesh, dtMeshTile* tile) => C_dtNavMeshGetPolyRefBase(navmesh, tile);
	public static dtStatus dtNavMeshGetOffMeshConnectionPolyEndPoints(dtNavMeshHandle navmesh, dtPolyRef prevRef, dtPolyRef polyRef, float* startPos, float* endPos) => C_dtNavMeshGetOffMeshConnectionPolyEndPoints(navmesh, prevRef, polyRef, startPos, endPos);
	public static dtOffMeshConnection* dtNavMeshGetOffMeshConnectionByRef(dtNavMeshHandle navmesh, dtPolyRef @ref) => C_dtNavMeshGetOffMeshConnectionByRef(navmesh, @ref);
	public static dtStatus dtNavMeshSetPolyFlags(dtNavMeshHandle navmesh, dtPolyRef @ref, uint16 flags) => C_dtNavMeshSetPolyFlags(navmesh, @ref, flags);
	public static dtStatus dtNavMeshGetPolyFlags(dtNavMeshHandle navmesh, dtPolyRef @ref, uint16* resultFlags) => C_dtNavMeshGetPolyFlags(navmesh, @ref, resultFlags);
	public static dtStatus dtNavMeshSetPolyArea(dtNavMeshHandle navmesh, dtPolyRef @ref, uint8 area) => C_dtNavMeshSetPolyArea(navmesh, @ref, area);
	public static dtStatus dtNavMeshGetPolyArea(dtNavMeshHandle navmesh, dtPolyRef @ref, uint8* resultArea) => C_dtNavMeshGetPolyArea(navmesh, @ref, resultArea);
	public static int32 dtNavMeshGetTileStateSize(dtNavMeshHandle navmesh, dtMeshTile* tile) => C_dtNavMeshGetTileStateSize(navmesh, tile);
	public static dtStatus dtNavMeshStoreTileState(dtNavMeshHandle navmesh, dtMeshTile* tile, uint8* data, int32 maxDataSize) => C_dtNavMeshStoreTileState(navmesh, tile, data, maxDataSize);
	public static dtStatus dtNavMeshRestoreTileState(dtNavMeshHandle navmesh, dtMeshTile* tile, uint8* data, int32 maxDataSize) => C_dtNavMeshRestoreTileState(navmesh, tile, data, maxDataSize);
	public static int32 dtCreateNavMeshData(dtNavMeshCreateParams* @params, uint8** outData, int32* outDataSize) => C_dtCreateNavMeshData(@params, outData, outDataSize);
	public static int32 dtNavMeshHeaderSwapEndian(uint8* data, int32 dataSize) => C_dtNavMeshHeaderSwapEndian(data, dataSize);
	public static int32 dtNavMeshDataSwapEndian(uint8* data, int32 dataSize) => C_dtNavMeshDataSwapEndian(data, dataSize);
	public static dtQueryFilterHandle dtAllocQueryFilter() => C_dtAllocQueryFilter();
	public static void dtFreeQueryFilter(dtQueryFilterHandle filter) => C_dtFreeQueryFilter(filter);
	public static float dtQueryFilterGetAreaCost(dtQueryFilterHandle filter, int32 i) => C_dtQueryFilterGetAreaCost(filter, i);
	public static void dtQueryFilterSetAreaCost(dtQueryFilterHandle filter, int32 i, float cost) => C_dtQueryFilterSetAreaCost(filter, i, cost);
	public static uint16 dtQueryFilterGetIncludeFlags(dtQueryFilterHandle filter) => C_dtQueryFilterGetIncludeFlags(filter);
	public static void dtQueryFilterSetIncludeFlags(dtQueryFilterHandle filter, uint16 flags) => C_dtQueryFilterSetIncludeFlags(filter, flags);
	public static uint16 dtQueryFilterGetExcludeFlags(dtQueryFilterHandle filter) => C_dtQueryFilterGetExcludeFlags(filter);
	public static void dtQueryFilterSetExcludeFlags(dtQueryFilterHandle filter, uint16 flags) => C_dtQueryFilterSetExcludeFlags(filter, flags);
	public static dtNavMeshQueryHandle dtAllocNavMeshQuery() => C_dtAllocNavMeshQuery();
	public static void dtFreeNavMeshQuery(dtNavMeshQueryHandle query) => C_dtFreeNavMeshQuery(query);
	public static dtStatus dtNavMeshQueryInit(dtNavMeshQueryHandle query, dtNavMeshHandle nav, int32 maxNodes) => C_dtNavMeshQueryInit(query, nav, maxNodes);
	public static dtStatus dtNavMeshQueryFindPath(dtNavMeshQueryHandle query, dtPolyRef startRef, dtPolyRef endRef, float* startPos, float* endPos, dtQueryFilterHandle filter, dtPolyRef* path, int32* pathCount, int32 maxPath) => C_dtNavMeshQueryFindPath(query, startRef, endRef, startPos, endPos, filter, path, pathCount, maxPath);
	public static dtStatus dtNavMeshQueryFindStraightPath(dtNavMeshQueryHandle query, float* startPos, float* endPos, dtPolyRef* path, int32 pathSize, float* straightPath, uint8* straightPathFlags, dtPolyRef* straightPathRefs, int32* straightPathCount, int32 maxStraightPath, int32 options) => C_dtNavMeshQueryFindStraightPath(query, startPos, endPos, path, pathSize, straightPath, straightPathFlags, straightPathRefs, straightPathCount, maxStraightPath, options);
	public static dtStatus dtNavMeshQueryInitSlicedFindPath(dtNavMeshQueryHandle query, dtPolyRef startRef, dtPolyRef endRef, float* startPos, float* endPos, dtQueryFilterHandle filter, uint32 options) => C_dtNavMeshQueryInitSlicedFindPath(query, startRef, endRef, startPos, endPos, filter, options);
	public static dtStatus dtNavMeshQueryUpdateSlicedFindPath(dtNavMeshQueryHandle query, int32 maxIter, int32* doneIters) => C_dtNavMeshQueryUpdateSlicedFindPath(query, maxIter, doneIters);
	public static dtStatus dtNavMeshQueryFinalizeSlicedFindPath(dtNavMeshQueryHandle query, dtPolyRef* path, int32* pathCount, int32 maxPath) => C_dtNavMeshQueryFinalizeSlicedFindPath(query, path, pathCount, maxPath);
	public static dtStatus dtNavMeshQueryFinalizeSlicedFindPathPartial(dtNavMeshQueryHandle query, dtPolyRef* existing, int32 existingSize, dtPolyRef* path, int32* pathCount, int32 maxPath) => C_dtNavMeshQueryFinalizeSlicedFindPathPartial(query, existing, existingSize, path, pathCount, maxPath);
	public static dtStatus dtNavMeshQueryFindPolysAroundCircle(dtNavMeshQueryHandle query, dtPolyRef startRef, float* centerPos, float radius, dtQueryFilterHandle filter, dtPolyRef* resultRef, dtPolyRef* resultParent, float* resultCost, int32* resultCount, int32 maxResult) => C_dtNavMeshQueryFindPolysAroundCircle(query, startRef, centerPos, radius, filter, resultRef, resultParent, resultCost, resultCount, maxResult);
	public static dtStatus dtNavMeshQueryFindPolysAroundShape(dtNavMeshQueryHandle query, dtPolyRef startRef, float* verts, int32 nverts, dtQueryFilterHandle filter, dtPolyRef* resultRef, dtPolyRef* resultParent, float* resultCost, int32* resultCount, int32 maxResult) => C_dtNavMeshQueryFindPolysAroundShape(query, startRef, verts, nverts, filter, resultRef, resultParent, resultCost, resultCount, maxResult);
	public static dtStatus dtNavMeshQueryGetPathFromDijkstraSearch(dtNavMeshQueryHandle query, dtPolyRef endRef, dtPolyRef* path, int32* pathCount, int32 maxPath) => C_dtNavMeshQueryGetPathFromDijkstraSearch(query, endRef, path, pathCount, maxPath);
	public static dtStatus dtNavMeshQueryFindNearestPoly(dtNavMeshQueryHandle query, float* center, float* halfExtents, dtQueryFilterHandle filter, dtPolyRef* nearestRef, float* nearestPt) => C_dtNavMeshQueryFindNearestPoly(query, center, halfExtents, filter, nearestRef, nearestPt);
	public static dtStatus dtNavMeshQueryFindNearestPolyEx(dtNavMeshQueryHandle query, float* center, float* halfExtents, dtQueryFilterHandle filter, dtPolyRef* nearestRef, float* nearestPt, int32* isOverPoly) => C_dtNavMeshQueryFindNearestPolyEx(query, center, halfExtents, filter, nearestRef, nearestPt, isOverPoly);
	public static dtStatus dtNavMeshQueryQueryPolygons(dtNavMeshQueryHandle query, float* center, float* halfExtents, dtQueryFilterHandle filter, dtPolyRef* polys, int32* polyCount, int32 maxPolys) => C_dtNavMeshQueryQueryPolygons(query, center, halfExtents, filter, polys, polyCount, maxPolys);
	public static dtStatus dtNavMeshQueryFindLocalNeighbourhood(dtNavMeshQueryHandle query, dtPolyRef startRef, float* centerPos, float radius, dtQueryFilterHandle filter, dtPolyRef* resultRef, dtPolyRef* resultParent, int32* resultCount, int32 maxResult) => C_dtNavMeshQueryFindLocalNeighbourhood(query, startRef, centerPos, radius, filter, resultRef, resultParent, resultCount, maxResult);
	public static dtStatus dtNavMeshQueryMoveAlongSurface(dtNavMeshQueryHandle query, dtPolyRef startRef, float* startPos, float* endPos, dtQueryFilterHandle filter, float* resultPos, dtPolyRef* visited, int32* visitedCount, int32 maxVisitedSize) => C_dtNavMeshQueryMoveAlongSurface(query, startRef, startPos, endPos, filter, resultPos, visited, visitedCount, maxVisitedSize);
	public static dtStatus dtNavMeshQueryRaycast(dtNavMeshQueryHandle query, dtPolyRef startRef, float* startPos, float* endPos, dtQueryFilterHandle filter, float* t, float* hitNormal, dtPolyRef* path, int32* pathCount, int32 maxPath) => C_dtNavMeshQueryRaycast(query, startRef, startPos, endPos, filter, t, hitNormal, path, pathCount, maxPath);
	public static dtStatus dtNavMeshQueryRaycastEx(dtNavMeshQueryHandle query, dtPolyRef startRef, float* startPos, float* endPos, dtQueryFilterHandle filter, uint32 options, dtRaycastHit* hit, dtPolyRef prevRef) => C_dtNavMeshQueryRaycastEx(query, startRef, startPos, endPos, filter, options, hit, prevRef);
	public static dtStatus dtNavMeshQueryFindDistanceToWall(dtNavMeshQueryHandle query, dtPolyRef startRef, float* centerPos, float maxRadius, dtQueryFilterHandle filter, float* hitDist, float* hitPos, float* hitNormal) => C_dtNavMeshQueryFindDistanceToWall(query, startRef, centerPos, maxRadius, filter, hitDist, hitPos, hitNormal);
	public static dtStatus dtNavMeshQueryGetPolyWallSegments(dtNavMeshQueryHandle query, dtPolyRef @ref, dtQueryFilterHandle filter, float* segmentVerts, dtPolyRef* segmentRefs, int32* segmentCount, int32 maxSegments) => C_dtNavMeshQueryGetPolyWallSegments(query, @ref, filter, segmentVerts, segmentRefs, segmentCount, maxSegments);
	public static dtStatus dtNavMeshQueryFindRandomPoint(dtNavMeshQueryHandle query, dtQueryFilterHandle filter, dtRandFunc frand, dtPolyRef* randomRef, float* randomPt) => C_dtNavMeshQueryFindRandomPoint(query, filter, frand, randomRef, randomPt);
	public static dtStatus dtNavMeshQueryFindRandomPointAroundCircle(dtNavMeshQueryHandle query, dtPolyRef startRef, float* centerPos, float maxRadius, dtQueryFilterHandle filter, dtRandFunc frand, dtPolyRef* randomRef, float* randomPt) => C_dtNavMeshQueryFindRandomPointAroundCircle(query, startRef, centerPos, maxRadius, filter, frand, randomRef, randomPt);
	public static dtStatus dtNavMeshQueryClosestPointOnPoly(dtNavMeshQueryHandle query, dtPolyRef @ref, float* pos, float* closest, int32* posOverPoly) => C_dtNavMeshQueryClosestPointOnPoly(query, @ref, pos, closest, posOverPoly);
	public static dtStatus dtNavMeshQueryClosestPointOnPolyBoundary(dtNavMeshQueryHandle query, dtPolyRef @ref, float* pos, float* closest) => C_dtNavMeshQueryClosestPointOnPolyBoundary(query, @ref, pos, closest);
	public static dtStatus dtNavMeshQueryGetPolyHeight(dtNavMeshQueryHandle query, dtPolyRef @ref, float* pos, float* height) => C_dtNavMeshQueryGetPolyHeight(query, @ref, pos, height);
	public static int32 dtNavMeshQueryIsValidPolyRef(dtNavMeshQueryHandle query, dtPolyRef @ref, dtQueryFilterHandle filter) => C_dtNavMeshQueryIsValidPolyRef(query, @ref, filter);
	public static int32 dtNavMeshQueryIsInClosedList(dtNavMeshQueryHandle query, dtPolyRef @ref) => C_dtNavMeshQueryIsInClosedList(query, @ref);
	public static dtNavMeshHandle dtNavMeshQueryGetAttachedNavMesh(dtNavMeshQueryHandle query) => C_dtNavMeshQueryGetAttachedNavMesh(query);
	public static void dtPolySetArea(dtPoly* poly, uint8 area) => C_dtPolySetArea(poly, area);
	public static void dtPolySetType(dtPoly* poly, uint8 type) => C_dtPolySetType(poly, type);
	public static uint8 dtPolyGetArea(dtPoly* poly) => C_dtPolyGetArea(poly);
	public static uint8 dtPolyGetType(dtPoly* poly) => C_dtPolyGetType(poly);
	public static int32 dtGetDetailTriEdgeFlags(uint8 triFlags, int32 edgeIndex) => C_dtGetDetailTriEdgeFlags(triFlags, edgeIndex);
}
