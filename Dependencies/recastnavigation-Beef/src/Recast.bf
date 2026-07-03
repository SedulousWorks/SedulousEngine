using System;

namespace recastnavigation_Beef;

/* Constants */
static
{
	public const float RC_PI = 3.14159265f;
	public const int32 RC_SPAN_HEIGHT_BITS = 13;
	public const int32 RC_SPAN_MAX_HEIGHT = ((1 << RC_SPAN_HEIGHT_BITS) - 1);
	public const int32 RC_SPANS_PER_POOL = 2048;
	public const uint16 RC_BORDER_REG = 0x8000;
	public const int32 RC_MULTIPLE_REGS = 0;
	public const int32 RC_BORDER_VERTEX = 0x10000;
	public const int32 RC_AREA_BORDER = 0x20000;
	public const uint16 RC_CONTOUR_REG_MASK = 0xffff;
	public const uint16 RC_MESH_NULL_IDX = 0xffff;
	public const uint8 RC_NULL_AREA = 0;
	public const uint8 RC_WALKABLE_AREA = 63;
	public const uint8 RC_NOT_CONNECTED = 0x3f;
}

/* Opaque handle types */
typealias rcContextHandle = void*;
typealias rcHeightfieldHandle = void*;
typealias rcCompactHeightfieldHandle = void*;
typealias rcHeightfieldLayerSetHandle = void*;
typealias rcContourSetHandle = void*;
typealias rcPolyMeshHandle = void*;
typealias rcPolyMeshDetailHandle = void*;

/* Log categories */
enum rcLogCategory : int32
{
	RC_LOG_PROGRESS = 1,
	RC_LOG_WARNING,
	RC_LOG_ERROR
}

/* Timer labels */
enum rcTimerLabel : int32
{
	RC_TIMER_TOTAL,
	RC_TIMER_TEMP,
	RC_TIMER_RASTERIZE_TRIANGLES,
	RC_TIMER_BUILD_COMPACTHEIGHTFIELD,
	RC_TIMER_BUILD_CONTOURS,
	RC_TIMER_BUILD_CONTOURS_TRACE,
	RC_TIMER_BUILD_CONTOURS_SIMPLIFY,
	RC_TIMER_FILTER_BORDER,
	RC_TIMER_FILTER_WALKABLE,
	RC_TIMER_MEDIAN_AREA,
	RC_TIMER_FILTER_LOW_OBSTACLES,
	RC_TIMER_BUILD_POLYMESH,
	RC_TIMER_MERGE_POLYMESH,
	RC_TIMER_ERODE_AREA,
	RC_TIMER_MARK_BOX_AREA,
	RC_TIMER_MARK_CYLINDER_AREA,
	RC_TIMER_MARK_CONVEXPOLY_AREA,
	RC_TIMER_BUILD_DISTANCEFIELD,
	RC_TIMER_BUILD_DISTANCEFIELD_DIST,
	RC_TIMER_BUILD_DISTANCEFIELD_BLUR,
	RC_TIMER_BUILD_REGIONS,
	RC_TIMER_BUILD_REGIONS_WATERSHED,
	RC_TIMER_BUILD_REGIONS_EXPAND,
	RC_TIMER_BUILD_REGIONS_FLOOD,
	RC_TIMER_BUILD_REGIONS_FILTER,
	RC_TIMER_BUILD_LAYERS,
	RC_TIMER_BUILD_POLYMESHDETAIL,
	RC_TIMER_MERGE_POLYMESHDETAIL,
	RC_MAX_TIMERS
}

/* Build contour flags */
enum rcBuildContoursFlags : int32
{
	RC_CONTOUR_TESS_WALL_EDGES = 0x01,
	RC_CONTOUR_TESS_AREA_EDGES = 0x02
}

/* Allocation hints */
enum rcAllocHint : int32
{
	RC_ALLOC_PERM,
	RC_ALLOC_TEMP
}

/* Configuration structure */
[CRepr]
struct rcConfig
{
	public int32 width;
	public int32 height;
	public int32 tileSize;
	public int32 borderSize;
	public float cs;
	public float ch;
	public float[3] bmin;
	public float[3] bmax;
	public float walkableSlopeAngle;
	public int32 walkableHeight;
	public int32 walkableClimb;
	public int32 walkableRadius;
	public int32 maxEdgeLen;
	public float maxSimplificationError;
	public int32 minRegionArea;
	public int32 mergeRegionArea;
	public int32 maxVertsPerPoly;
	public float detailSampleDist;
	public float detailSampleMaxError;
}

/* Span structure */
[CRepr]
struct rcSpan
{
	public uint32 smin; // 13 bits
	public uint32 smax; // 13 bits
	public uint32 area; // 6 bits
	public rcSpan* next;
}

/* Compact cell structure */
[CRepr]
struct rcCompactCell
{
	public uint32 index; // 24 bits
	public uint32 count; // 8 bits
}

/* Compact span structure */
[CRepr]
struct rcCompactSpan
{
	public uint16 y;
	public uint16 reg;
	public uint32 con; // 24 bits
	public uint32 h; // 8 bits
}

/* Heightfield layer structure */
[CRepr]
struct rcHeightfieldLayer
{
	public float[3] bmin;
	public float[3] bmax;
	public float cs;
	public float ch;
	public int32 width;
	public int32 height;
	public int32 minx;
	public int32 maxx;
	public int32 miny;
	public int32 maxy;
	public int32 hmin;
	public int32 hmax;
	public uint8* heights;
	public uint8* areas;
	public uint8* cons;
}

/* Contour structure */
[CRepr]
struct rcContour
{
	public int32* verts;
	public int32 nverts;
	public int32* rverts;
	public int32 nrverts;
	public uint16 reg;
	public uint8 area;
}

/* Function pointer types */
function void* rcAllocFunc(int size, rcAllocHint hint);
function void rcFreeFunc(void* ptr);
function void rcLogFunc(rcLogCategory category, char8* msg, int32 len);

/* Functions */
static
{
	/* Memory allocation */
	[CLink]
	public static extern void C_rcAllocSetCustom(rcAllocFunc allocFunc, rcFreeFunc freeFunc);
	[CLink]
	public static extern void* C_rcAlloc(int size, rcAllocHint hint);
	[CLink]
	public static extern void C_rcFree(void* ptr);

	/* Context functions */
	[CLink]
	public static extern rcContextHandle C_rcCreateContext(int32 enableLog, int32 enableTimer);
	[CLink]
	public static extern void C_rcDestroyContext(rcContextHandle ctx);
	[CLink]
	public static extern void C_rcContextEnableLog(rcContextHandle ctx, int32 state);
	[CLink]
	public static extern void C_rcContextResetLog(rcContextHandle ctx);
	[CLink]
	public static extern void C_rcContextEnableTimer(rcContextHandle ctx, int32 state);
	[CLink]
	public static extern void C_rcContextResetTimers(rcContextHandle ctx);
	[CLink]
	public static extern void C_rcContextStartTimer(rcContextHandle ctx, rcTimerLabel label);
	[CLink]
	public static extern void C_rcContextStopTimer(rcContextHandle ctx, rcTimerLabel label);
	[CLink]
	public static extern int32 C_rcContextGetAccumulatedTime(rcContextHandle ctx, rcTimerLabel label);

	/* Heightfield allocation and management */
	[CLink]
	public static extern rcHeightfieldHandle C_rcAllocHeightfield();
	[CLink]
	public static extern void C_rcFreeHeightField(rcHeightfieldHandle hf);
	[CLink]
	public static extern int32 C_rcCreateHeightfield(rcContextHandle ctx, rcHeightfieldHandle hf,
		int32 width, int32 height, float* bmin, float* bmax, float cs, float ch);

	/* Heightfield accessors */
	[CLink]
	public static extern int32 C_rcHeightfieldGetWidth(rcHeightfieldHandle hf);
	[CLink]
	public static extern int32 C_rcHeightfieldGetHeight(rcHeightfieldHandle hf);
	[CLink]
	public static extern void C_rcHeightfieldGetBMin(rcHeightfieldHandle hf, float* bmin);
	[CLink]
	public static extern void C_rcHeightfieldGetBMax(rcHeightfieldHandle hf, float* bmax);
	[CLink]
	public static extern float C_rcHeightfieldGetCs(rcHeightfieldHandle hf);
	[CLink]
	public static extern float C_rcHeightfieldGetCh(rcHeightfieldHandle hf);
	[CLink]
	public static extern rcSpan** C_rcHeightfieldGetSpans(rcHeightfieldHandle hf);

	/* Compact heightfield allocation and management */
	[CLink]
	public static extern rcCompactHeightfieldHandle C_rcAllocCompactHeightfield();
	[CLink]
	public static extern void C_rcFreeCompactHeightfield(rcCompactHeightfieldHandle chf);

	/* Compact heightfield accessors */
	[CLink]
	public static extern int32 C_rcCompactHeightfieldGetWidth(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern int32 C_rcCompactHeightfieldGetHeight(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern int32 C_rcCompactHeightfieldGetSpanCount(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern int32 C_rcCompactHeightfieldGetWalkableHeight(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern int32 C_rcCompactHeightfieldGetWalkableClimb(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern int32 C_rcCompactHeightfieldGetBorderSize(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern uint16 C_rcCompactHeightfieldGetMaxDistance(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern uint16 C_rcCompactHeightfieldGetMaxRegions(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern void C_rcCompactHeightfieldGetBMin(rcCompactHeightfieldHandle chf, float* bmin);
	[CLink]
	public static extern void C_rcCompactHeightfieldGetBMax(rcCompactHeightfieldHandle chf, float* bmax);
	[CLink]
	public static extern float C_rcCompactHeightfieldGetCs(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern float C_rcCompactHeightfieldGetCh(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern rcCompactCell* C_rcCompactHeightfieldGetCells(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern rcCompactSpan* C_rcCompactHeightfieldGetSpans(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern uint16* C_rcCompactHeightfieldGetDist(rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern uint8* C_rcCompactHeightfieldGetAreas(rcCompactHeightfieldHandle chf);

	/* Heightfield layer set */
	[CLink]
	public static extern rcHeightfieldLayerSetHandle C_rcAllocHeightfieldLayerSet();
	[CLink]
	public static extern void C_rcFreeHeightfieldLayerSet(rcHeightfieldLayerSetHandle lset);
	[CLink]
	public static extern int32 C_rcHeightfieldLayerSetGetNLayers(rcHeightfieldLayerSetHandle lset);
	[CLink]
	public static extern rcHeightfieldLayer* C_rcHeightfieldLayerSetGetLayers(rcHeightfieldLayerSetHandle lset);

	/* Contour set */
	[CLink]
	public static extern rcContourSetHandle C_rcAllocContourSet();
	[CLink]
	public static extern void C_rcFreeContourSet(rcContourSetHandle cset);
	[CLink]
	public static extern int32 C_rcContourSetGetNConts(rcContourSetHandle cset);
	[CLink]
	public static extern rcContour* C_rcContourSetGetConts(rcContourSetHandle cset);
	[CLink]
	public static extern void C_rcContourSetGetBMin(rcContourSetHandle cset, float* bmin);
	[CLink]
	public static extern void C_rcContourSetGetBMax(rcContourSetHandle cset, float* bmax);
	[CLink]
	public static extern float C_rcContourSetGetCs(rcContourSetHandle cset);
	[CLink]
	public static extern float C_rcContourSetGetCh(rcContourSetHandle cset);
	[CLink]
	public static extern int32 C_rcContourSetGetWidth(rcContourSetHandle cset);
	[CLink]
	public static extern int32 C_rcContourSetGetHeight(rcContourSetHandle cset);
	[CLink]
	public static extern int32 C_rcContourSetGetBorderSize(rcContourSetHandle cset);
	[CLink]
	public static extern float C_rcContourSetGetMaxError(rcContourSetHandle cset);

	/* Poly mesh */
	[CLink]
	public static extern rcPolyMeshHandle C_rcAllocPolyMesh();
	[CLink]
	public static extern void C_rcFreePolyMesh(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern uint16* C_rcPolyMeshGetVerts(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern uint16* C_rcPolyMeshGetPolys(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern uint16* C_rcPolyMeshGetRegs(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern uint16* C_rcPolyMeshGetFlags(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern uint8* C_rcPolyMeshGetAreas(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern int32 C_rcPolyMeshGetNVerts(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern int32 C_rcPolyMeshGetNPolys(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern int32 C_rcPolyMeshGetMaxPolys(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern int32 C_rcPolyMeshGetNvp(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern void C_rcPolyMeshGetBMin(rcPolyMeshHandle pmesh, float* bmin);
	[CLink]
	public static extern void C_rcPolyMeshGetBMax(rcPolyMeshHandle pmesh, float* bmax);
	[CLink]
	public static extern float C_rcPolyMeshGetCs(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern float C_rcPolyMeshGetCh(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern int32 C_rcPolyMeshGetBorderSize(rcPolyMeshHandle pmesh);
	[CLink]
	public static extern float C_rcPolyMeshGetMaxEdgeError(rcPolyMeshHandle pmesh);

	/* Poly mesh detail */
	[CLink]
	public static extern rcPolyMeshDetailHandle C_rcAllocPolyMeshDetail();
	[CLink]
	public static extern void C_rcFreePolyMeshDetail(rcPolyMeshDetailHandle dmesh);
	[CLink]
	public static extern uint32* C_rcPolyMeshDetailGetMeshes(rcPolyMeshDetailHandle dmesh);
	[CLink]
	public static extern float* C_rcPolyMeshDetailGetVerts(rcPolyMeshDetailHandle dmesh);
	[CLink]
	public static extern uint8* C_rcPolyMeshDetailGetTris(rcPolyMeshDetailHandle dmesh);
	[CLink]
	public static extern int32 C_rcPolyMeshDetailGetNMeshes(rcPolyMeshDetailHandle dmesh);
	[CLink]
	public static extern int32 C_rcPolyMeshDetailGetNVerts(rcPolyMeshDetailHandle dmesh);
	[CLink]
	public static extern int32 C_rcPolyMeshDetailGetNTris(rcPolyMeshDetailHandle dmesh);

	/* Utility functions */
	[CLink]
	public static extern void C_rcCalcBounds(float* verts, int32 numVerts, float* minBounds, float* maxBounds);
	[CLink]
	public static extern void C_rcCalcGridSize(float* minBounds, float* maxBounds, float cellSize, int32* sizeX, int32* sizeZ);

	/* Triangle marking */
	[CLink]
	public static extern void C_rcMarkWalkableTriangles(rcContextHandle ctx, float walkableSlopeAngle,
		float* verts, int32 numVerts, int32* tris, int32 numTris, uint8* triAreaIDs);
	[CLink]
	public static extern void C_rcClearUnwalkableTriangles(rcContextHandle ctx, float walkableSlopeAngle,
		float* verts, int32 numVerts, int32* tris, int32 numTris, uint8* triAreaIDs);

	/* Span management */
	[CLink]
	public static extern int32 C_rcAddSpan(rcContextHandle ctx, rcHeightfieldHandle hf, int32 x, int32 z,
		uint16 spanMin, uint16 spanMax, uint8 areaID, int32 flagMergeThreshold);

	/* Rasterization */
	[CLink]
	public static extern int32 C_rcRasterizeTriangle(rcContextHandle ctx, float* v0, float* v1, float* v2,
		uint8 areaID, rcHeightfieldHandle hf, int32 flagMergeThreshold);
	[CLink]
	public static extern int32 C_rcRasterizeTriangles(rcContextHandle ctx, float* verts, int32 numVerts,
		int32* tris, uint8* triAreaIDs, int32 numTris, rcHeightfieldHandle hf, int32 flagMergeThreshold);
	[CLink]
	public static extern int32 C_rcRasterizeTrianglesUShort(rcContextHandle ctx, float* verts, int32 numVerts,
		uint16* tris, uint8* triAreaIDs, int32 numTris, rcHeightfieldHandle hf, int32 flagMergeThreshold);
	[CLink]
	public static extern int32 C_rcRasterizeTrianglesSoup(rcContextHandle ctx, float* verts,
		uint8* triAreaIDs, int32 numTris, rcHeightfieldHandle hf, int32 flagMergeThreshold);

	/* Filtering */
	[CLink]
	public static extern void C_rcFilterLowHangingWalkableObstacles(rcContextHandle ctx, int32 walkableClimb, rcHeightfieldHandle hf);
	[CLink]
	public static extern void C_rcFilterLedgeSpans(rcContextHandle ctx, int32 walkableHeight, int32 walkableClimb, rcHeightfieldHandle hf);
	[CLink]
	public static extern void C_rcFilterWalkableLowHeightSpans(rcContextHandle ctx, int32 walkableHeight, rcHeightfieldHandle hf);
	[CLink]
	public static extern int32 C_rcGetHeightFieldSpanCount(rcContextHandle ctx, rcHeightfieldHandle hf);

	/* Compact heightfield building */
	[CLink]
	public static extern int32 C_rcBuildCompactHeightfield(rcContextHandle ctx, int32 walkableHeight, int32 walkableClimb,
		rcHeightfieldHandle hf, rcCompactHeightfieldHandle chf);

	/* Area manipulation */
	[CLink]
	public static extern int32 C_rcErodeWalkableArea(rcContextHandle ctx, int32 erosionRadius, rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern int32 C_rcMedianFilterWalkableArea(rcContextHandle ctx, rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern void C_rcMarkBoxArea(rcContextHandle ctx, float* boxMinBounds, float* boxMaxBounds,
		uint8 areaId, rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern void C_rcMarkConvexPolyArea(rcContextHandle ctx, float* verts, int32 numVerts,
		float minY, float maxY, uint8 areaId, rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern int32 C_rcOffsetPoly(float* verts, int32 numVerts, float offset, float* outVerts, int32 maxOutVerts);
	[CLink]
	public static extern void C_rcMarkCylinderArea(rcContextHandle ctx, float* position, float radius, float height,
		uint8 areaId, rcCompactHeightfieldHandle chf);

	/* Distance field and regions */
	[CLink]
	public static extern int32 C_rcBuildDistanceField(rcContextHandle ctx, rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern int32 C_rcBuildRegions(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
		int32 borderSize, int32 minRegionArea, int32 mergeRegionArea);
	[CLink]
	public static extern int32 C_rcBuildLayerRegions(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
		int32 borderSize, int32 minRegionArea);
	[CLink]
	public static extern int32 C_rcBuildRegionsMonotone(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
		int32 borderSize, int32 minRegionArea, int32 mergeRegionArea);

	/* Connection helpers */
	[CLink]
	public static extern void C_rcSetCon(rcCompactSpan* span, int32 direction, int32 neighborIndex);
	[CLink]
	public static extern int32 C_rcGetCon(rcCompactSpan* span, int32 direction);
	[CLink]
	public static extern int32 C_rcGetDirOffsetX(int32 direction);
	[CLink]
	public static extern int32 C_rcGetDirOffsetY(int32 direction);
	[CLink]
	public static extern int32 C_rcGetDirForOffset(int32 offsetX, int32 offsetZ);

	/* Layer, contour, polymesh building */
	[CLink]
	public static extern int32 C_rcBuildHeightfieldLayers(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
		int32 borderSize, int32 walkableHeight, rcHeightfieldLayerSetHandle lset);
	[CLink]
	public static extern int32 C_rcBuildContours(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
		float maxError, int32 maxEdgeLen, rcContourSetHandle cset, int32 buildFlags);
	[CLink]
	public static extern int32 C_rcBuildPolyMesh(rcContextHandle ctx, rcContourSetHandle cset, int32 nvp, rcPolyMeshHandle mesh);
	[CLink]
	public static extern int32 C_rcMergePolyMeshes(rcContextHandle ctx, rcPolyMeshHandle* meshes, int32 nmeshes, rcPolyMeshHandle mesh);
	[CLink]
	public static extern int32 C_rcBuildPolyMeshDetail(rcContextHandle ctx, rcPolyMeshHandle mesh, rcCompactHeightfieldHandle chf,
		float sampleDist, float sampleMaxError, rcPolyMeshDetailHandle dmesh);
	[CLink]
	public static extern int32 C_rcCopyPolyMesh(rcContextHandle ctx, rcPolyMeshHandle src, rcPolyMeshHandle dst);
	[CLink]
	public static extern int32 C_rcMergePolyMeshDetails(rcContextHandle ctx, rcPolyMeshDetailHandle* meshes, int32 nmeshes, rcPolyMeshDetailHandle mesh);

	/* Math utilities */
	[CLink]
	public static extern float C_rcSqrt(float x);

	/* Wrapper functions */
	public static void rcAllocSetCustom(rcAllocFunc allocFunc, rcFreeFunc freeFunc) => C_rcAllocSetCustom(allocFunc, freeFunc);
	public static void* rcAlloc(int size, rcAllocHint hint) => C_rcAlloc(size, hint);
	public static void rcFree(void* ptr) => C_rcFree(ptr);
	public static rcContextHandle rcCreateContext(int32 enableLog, int32 enableTimer) => C_rcCreateContext(enableLog, enableTimer);
	public static void rcDestroyContext(rcContextHandle ctx) => C_rcDestroyContext(ctx);
	public static void rcContextEnableLog(rcContextHandle ctx, int32 state) => C_rcContextEnableLog(ctx, state);
	public static void rcContextResetLog(rcContextHandle ctx) => C_rcContextResetLog(ctx);
	public static void rcContextEnableTimer(rcContextHandle ctx, int32 state) => C_rcContextEnableTimer(ctx, state);
	public static void rcContextResetTimers(rcContextHandle ctx) => C_rcContextResetTimers(ctx);
	public static void rcContextStartTimer(rcContextHandle ctx, rcTimerLabel label) => C_rcContextStartTimer(ctx, label);
	public static void rcContextStopTimer(rcContextHandle ctx, rcTimerLabel label) => C_rcContextStopTimer(ctx, label);
	public static int32 rcContextGetAccumulatedTime(rcContextHandle ctx, rcTimerLabel label) => C_rcContextGetAccumulatedTime(ctx, label);
	public static rcHeightfieldHandle rcAllocHeightfield() => C_rcAllocHeightfield();
	public static void rcFreeHeightField(rcHeightfieldHandle hf) => C_rcFreeHeightField(hf);
	public static int32 rcCreateHeightfield(rcContextHandle ctx, rcHeightfieldHandle hf, int32 width, int32 height, float* bmin, float* bmax, float cs, float ch) => C_rcCreateHeightfield(ctx, hf, width, height, bmin, bmax, cs, ch);
	public static int32 rcHeightfieldGetWidth(rcHeightfieldHandle hf) => C_rcHeightfieldGetWidth(hf);
	public static int32 rcHeightfieldGetHeight(rcHeightfieldHandle hf) => C_rcHeightfieldGetHeight(hf);
	public static void rcHeightfieldGetBMin(rcHeightfieldHandle hf, float* bmin) => C_rcHeightfieldGetBMin(hf, bmin);
	public static void rcHeightfieldGetBMax(rcHeightfieldHandle hf, float* bmax) => C_rcHeightfieldGetBMax(hf, bmax);
	public static float rcHeightfieldGetCs(rcHeightfieldHandle hf) => C_rcHeightfieldGetCs(hf);
	public static float rcHeightfieldGetCh(rcHeightfieldHandle hf) => C_rcHeightfieldGetCh(hf);
	public static rcSpan** rcHeightfieldGetSpans(rcHeightfieldHandle hf) => C_rcHeightfieldGetSpans(hf);
	public static rcCompactHeightfieldHandle rcAllocCompactHeightfield() => C_rcAllocCompactHeightfield();
	public static void rcFreeCompactHeightfield(rcCompactHeightfieldHandle chf) => C_rcFreeCompactHeightfield(chf);
	public static int32 rcCompactHeightfieldGetWidth(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetWidth(chf);
	public static int32 rcCompactHeightfieldGetHeight(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetHeight(chf);
	public static int32 rcCompactHeightfieldGetSpanCount(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetSpanCount(chf);
	public static int32 rcCompactHeightfieldGetWalkableHeight(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetWalkableHeight(chf);
	public static int32 rcCompactHeightfieldGetWalkableClimb(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetWalkableClimb(chf);
	public static int32 rcCompactHeightfieldGetBorderSize(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetBorderSize(chf);
	public static uint16 rcCompactHeightfieldGetMaxDistance(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetMaxDistance(chf);
	public static uint16 rcCompactHeightfieldGetMaxRegions(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetMaxRegions(chf);
	public static void rcCompactHeightfieldGetBMin(rcCompactHeightfieldHandle chf, float* bmin) => C_rcCompactHeightfieldGetBMin(chf, bmin);
	public static void rcCompactHeightfieldGetBMax(rcCompactHeightfieldHandle chf, float* bmax) => C_rcCompactHeightfieldGetBMax(chf, bmax);
	public static float rcCompactHeightfieldGetCs(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetCs(chf);
	public static float rcCompactHeightfieldGetCh(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetCh(chf);
	public static rcCompactCell* rcCompactHeightfieldGetCells(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetCells(chf);
	public static rcCompactSpan* rcCompactHeightfieldGetSpans(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetSpans(chf);
	public static uint16* rcCompactHeightfieldGetDist(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetDist(chf);
	public static uint8* rcCompactHeightfieldGetAreas(rcCompactHeightfieldHandle chf) => C_rcCompactHeightfieldGetAreas(chf);
	public static rcHeightfieldLayerSetHandle rcAllocHeightfieldLayerSet() => C_rcAllocHeightfieldLayerSet();
	public static void rcFreeHeightfieldLayerSet(rcHeightfieldLayerSetHandle lset) => C_rcFreeHeightfieldLayerSet(lset);
	public static int32 rcHeightfieldLayerSetGetNLayers(rcHeightfieldLayerSetHandle lset) => C_rcHeightfieldLayerSetGetNLayers(lset);
	public static rcHeightfieldLayer* rcHeightfieldLayerSetGetLayers(rcHeightfieldLayerSetHandle lset) => C_rcHeightfieldLayerSetGetLayers(lset);
	public static rcContourSetHandle rcAllocContourSet() => C_rcAllocContourSet();
	public static void rcFreeContourSet(rcContourSetHandle cset) => C_rcFreeContourSet(cset);
	public static int32 rcContourSetGetNConts(rcContourSetHandle cset) => C_rcContourSetGetNConts(cset);
	public static rcContour* rcContourSetGetConts(rcContourSetHandle cset) => C_rcContourSetGetConts(cset);
	public static void rcContourSetGetBMin(rcContourSetHandle cset, float* bmin) => C_rcContourSetGetBMin(cset, bmin);
	public static void rcContourSetGetBMax(rcContourSetHandle cset, float* bmax) => C_rcContourSetGetBMax(cset, bmax);
	public static float rcContourSetGetCs(rcContourSetHandle cset) => C_rcContourSetGetCs(cset);
	public static float rcContourSetGetCh(rcContourSetHandle cset) => C_rcContourSetGetCh(cset);
	public static int32 rcContourSetGetWidth(rcContourSetHandle cset) => C_rcContourSetGetWidth(cset);
	public static int32 rcContourSetGetHeight(rcContourSetHandle cset) => C_rcContourSetGetHeight(cset);
	public static int32 rcContourSetGetBorderSize(rcContourSetHandle cset) => C_rcContourSetGetBorderSize(cset);
	public static float rcContourSetGetMaxError(rcContourSetHandle cset) => C_rcContourSetGetMaxError(cset);
	public static rcPolyMeshHandle rcAllocPolyMesh() => C_rcAllocPolyMesh();
	public static void rcFreePolyMesh(rcPolyMeshHandle pmesh) => C_rcFreePolyMesh(pmesh);
	public static uint16* rcPolyMeshGetVerts(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetVerts(pmesh);
	public static uint16* rcPolyMeshGetPolys(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetPolys(pmesh);
	public static uint16* rcPolyMeshGetRegs(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetRegs(pmesh);
	public static uint16* rcPolyMeshGetFlags(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetFlags(pmesh);
	public static uint8* rcPolyMeshGetAreas(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetAreas(pmesh);
	public static int32 rcPolyMeshGetNVerts(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetNVerts(pmesh);
	public static int32 rcPolyMeshGetNPolys(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetNPolys(pmesh);
	public static int32 rcPolyMeshGetMaxPolys(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetMaxPolys(pmesh);
	public static int32 rcPolyMeshGetNvp(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetNvp(pmesh);
	public static void rcPolyMeshGetBMin(rcPolyMeshHandle pmesh, float* bmin) => C_rcPolyMeshGetBMin(pmesh, bmin);
	public static void rcPolyMeshGetBMax(rcPolyMeshHandle pmesh, float* bmax) => C_rcPolyMeshGetBMax(pmesh, bmax);
	public static float rcPolyMeshGetCs(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetCs(pmesh);
	public static float rcPolyMeshGetCh(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetCh(pmesh);
	public static int32 rcPolyMeshGetBorderSize(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetBorderSize(pmesh);
	public static float rcPolyMeshGetMaxEdgeError(rcPolyMeshHandle pmesh) => C_rcPolyMeshGetMaxEdgeError(pmesh);
	public static rcPolyMeshDetailHandle rcAllocPolyMeshDetail() => C_rcAllocPolyMeshDetail();
	public static void rcFreePolyMeshDetail(rcPolyMeshDetailHandle dmesh) => C_rcFreePolyMeshDetail(dmesh);
	public static uint32* rcPolyMeshDetailGetMeshes(rcPolyMeshDetailHandle dmesh) => C_rcPolyMeshDetailGetMeshes(dmesh);
	public static float* rcPolyMeshDetailGetVerts(rcPolyMeshDetailHandle dmesh) => C_rcPolyMeshDetailGetVerts(dmesh);
	public static uint8* rcPolyMeshDetailGetTris(rcPolyMeshDetailHandle dmesh) => C_rcPolyMeshDetailGetTris(dmesh);
	public static int32 rcPolyMeshDetailGetNMeshes(rcPolyMeshDetailHandle dmesh) => C_rcPolyMeshDetailGetNMeshes(dmesh);
	public static int32 rcPolyMeshDetailGetNVerts(rcPolyMeshDetailHandle dmesh) => C_rcPolyMeshDetailGetNVerts(dmesh);
	public static int32 rcPolyMeshDetailGetNTris(rcPolyMeshDetailHandle dmesh) => C_rcPolyMeshDetailGetNTris(dmesh);
	public static void rcCalcBounds(float* verts, int32 numVerts, float* minBounds, float* maxBounds) => C_rcCalcBounds(verts, numVerts, minBounds, maxBounds);
	public static void rcCalcGridSize(float* minBounds, float* maxBounds, float cellSize, int32* sizeX, int32* sizeZ) => C_rcCalcGridSize(minBounds, maxBounds, cellSize, sizeX, sizeZ);
	public static void rcMarkWalkableTriangles(rcContextHandle ctx, float walkableSlopeAngle, float* verts, int32 numVerts, int32* tris, int32 numTris, uint8* triAreaIDs) => C_rcMarkWalkableTriangles(ctx, walkableSlopeAngle, verts, numVerts, tris, numTris, triAreaIDs);
	public static void rcClearUnwalkableTriangles(rcContextHandle ctx, float walkableSlopeAngle, float* verts, int32 numVerts, int32* tris, int32 numTris, uint8* triAreaIDs) => C_rcClearUnwalkableTriangles(ctx, walkableSlopeAngle, verts, numVerts, tris, numTris, triAreaIDs);
	public static int32 rcAddSpan(rcContextHandle ctx, rcHeightfieldHandle hf, int32 x, int32 z, uint16 spanMin, uint16 spanMax, uint8 areaID, int32 flagMergeThreshold) => C_rcAddSpan(ctx, hf, x, z, spanMin, spanMax, areaID, flagMergeThreshold);
	public static int32 rcRasterizeTriangle(rcContextHandle ctx, float* v0, float* v1, float* v2, uint8 areaID, rcHeightfieldHandle hf, int32 flagMergeThreshold) => C_rcRasterizeTriangle(ctx, v0, v1, v2, areaID, hf, flagMergeThreshold);
	public static int32 rcRasterizeTriangles(rcContextHandle ctx, float* verts, int32 numVerts, int32* tris, uint8* triAreaIDs, int32 numTris, rcHeightfieldHandle hf, int32 flagMergeThreshold) => C_rcRasterizeTriangles(ctx, verts, numVerts, tris, triAreaIDs, numTris, hf, flagMergeThreshold);
	public static int32 rcRasterizeTrianglesUShort(rcContextHandle ctx, float* verts, int32 numVerts, uint16* tris, uint8* triAreaIDs, int32 numTris, rcHeightfieldHandle hf, int32 flagMergeThreshold) => C_rcRasterizeTrianglesUShort(ctx, verts, numVerts, tris, triAreaIDs, numTris, hf, flagMergeThreshold);
	public static int32 rcRasterizeTrianglesSoup(rcContextHandle ctx, float* verts, uint8* triAreaIDs, int32 numTris, rcHeightfieldHandle hf, int32 flagMergeThreshold) => C_rcRasterizeTrianglesSoup(ctx, verts, triAreaIDs, numTris, hf, flagMergeThreshold);
	public static void rcFilterLowHangingWalkableObstacles(rcContextHandle ctx, int32 walkableClimb, rcHeightfieldHandle hf) => C_rcFilterLowHangingWalkableObstacles(ctx, walkableClimb, hf);
	public static void rcFilterLedgeSpans(rcContextHandle ctx, int32 walkableHeight, int32 walkableClimb, rcHeightfieldHandle hf) => C_rcFilterLedgeSpans(ctx, walkableHeight, walkableClimb, hf);
	public static void rcFilterWalkableLowHeightSpans(rcContextHandle ctx, int32 walkableHeight, rcHeightfieldHandle hf) => C_rcFilterWalkableLowHeightSpans(ctx, walkableHeight, hf);
	public static int32 rcGetHeightFieldSpanCount(rcContextHandle ctx, rcHeightfieldHandle hf) => C_rcGetHeightFieldSpanCount(ctx, hf);
	public static int32 rcBuildCompactHeightfield(rcContextHandle ctx, int32 walkableHeight, int32 walkableClimb, rcHeightfieldHandle hf, rcCompactHeightfieldHandle chf) => C_rcBuildCompactHeightfield(ctx, walkableHeight, walkableClimb, hf, chf);
	public static int32 rcErodeWalkableArea(rcContextHandle ctx, int32 erosionRadius, rcCompactHeightfieldHandle chf) => C_rcErodeWalkableArea(ctx, erosionRadius, chf);
	public static int32 rcMedianFilterWalkableArea(rcContextHandle ctx, rcCompactHeightfieldHandle chf) => C_rcMedianFilterWalkableArea(ctx, chf);
	public static void rcMarkBoxArea(rcContextHandle ctx, float* boxMinBounds, float* boxMaxBounds, uint8 areaId, rcCompactHeightfieldHandle chf) => C_rcMarkBoxArea(ctx, boxMinBounds, boxMaxBounds, areaId, chf);
	public static void rcMarkConvexPolyArea(rcContextHandle ctx, float* verts, int32 numVerts, float minY, float maxY, uint8 areaId, rcCompactHeightfieldHandle chf) => C_rcMarkConvexPolyArea(ctx, verts, numVerts, minY, maxY, areaId, chf);
	public static int32 rcOffsetPoly(float* verts, int32 numVerts, float offset, float* outVerts, int32 maxOutVerts) => C_rcOffsetPoly(verts, numVerts, offset, outVerts, maxOutVerts);
	public static void rcMarkCylinderArea(rcContextHandle ctx, float* position, float radius, float height, uint8 areaId, rcCompactHeightfieldHandle chf) => C_rcMarkCylinderArea(ctx, position, radius, height, areaId, chf);
	public static int32 rcBuildDistanceField(rcContextHandle ctx, rcCompactHeightfieldHandle chf) => C_rcBuildDistanceField(ctx, chf);
	public static int32 rcBuildRegions(rcContextHandle ctx, rcCompactHeightfieldHandle chf, int32 borderSize, int32 minRegionArea, int32 mergeRegionArea) => C_rcBuildRegions(ctx, chf, borderSize, minRegionArea, mergeRegionArea);
	public static int32 rcBuildLayerRegions(rcContextHandle ctx, rcCompactHeightfieldHandle chf, int32 borderSize, int32 minRegionArea) => C_rcBuildLayerRegions(ctx, chf, borderSize, minRegionArea);
	public static int32 rcBuildRegionsMonotone(rcContextHandle ctx, rcCompactHeightfieldHandle chf, int32 borderSize, int32 minRegionArea, int32 mergeRegionArea) => C_rcBuildRegionsMonotone(ctx, chf, borderSize, minRegionArea, mergeRegionArea);
	public static void rcSetCon(rcCompactSpan* span, int32 direction, int32 neighborIndex) => C_rcSetCon(span, direction, neighborIndex);
	public static int32 rcGetCon(rcCompactSpan* span, int32 direction) => C_rcGetCon(span, direction);
	public static int32 rcGetDirOffsetX(int32 direction) => C_rcGetDirOffsetX(direction);
	public static int32 rcGetDirOffsetY(int32 direction) => C_rcGetDirOffsetY(direction);
	public static int32 rcGetDirForOffset(int32 offsetX, int32 offsetZ) => C_rcGetDirForOffset(offsetX, offsetZ);
	public static int32 rcBuildHeightfieldLayers(rcContextHandle ctx, rcCompactHeightfieldHandle chf, int32 borderSize, int32 walkableHeight, rcHeightfieldLayerSetHandle lset) => C_rcBuildHeightfieldLayers(ctx, chf, borderSize, walkableHeight, lset);
	public static int32 rcBuildContours(rcContextHandle ctx, rcCompactHeightfieldHandle chf, float maxError, int32 maxEdgeLen, rcContourSetHandle cset, int32 buildFlags) => C_rcBuildContours(ctx, chf, maxError, maxEdgeLen, cset, buildFlags);
	public static int32 rcBuildPolyMesh(rcContextHandle ctx, rcContourSetHandle cset, int32 nvp, rcPolyMeshHandle mesh) => C_rcBuildPolyMesh(ctx, cset, nvp, mesh);
	public static int32 rcMergePolyMeshes(rcContextHandle ctx, rcPolyMeshHandle* meshes, int32 nmeshes, rcPolyMeshHandle mesh) => C_rcMergePolyMeshes(ctx, meshes, nmeshes, mesh);
	public static int32 rcBuildPolyMeshDetail(rcContextHandle ctx, rcPolyMeshHandle mesh, rcCompactHeightfieldHandle chf, float sampleDist, float sampleMaxError, rcPolyMeshDetailHandle dmesh) => C_rcBuildPolyMeshDetail(ctx, mesh, chf, sampleDist, sampleMaxError, dmesh);
	public static int32 rcCopyPolyMesh(rcContextHandle ctx, rcPolyMeshHandle src, rcPolyMeshHandle dst) => C_rcCopyPolyMesh(ctx, src, dst);
	public static int32 rcMergePolyMeshDetails(rcContextHandle ctx, rcPolyMeshDetailHandle* meshes, int32 nmeshes, rcPolyMeshDetailHandle mesh) => C_rcMergePolyMeshDetails(ctx, meshes, nmeshes, mesh);
	public static float rcSqrt(float x) => C_rcSqrt(x);
}
