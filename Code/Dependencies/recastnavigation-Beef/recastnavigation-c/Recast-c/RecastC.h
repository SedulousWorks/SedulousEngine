/*
 * Recast C API
 * C interface for the Recast navigation mesh generation library
 */

#ifndef RECAST_C_H
#define RECAST_C_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) && !defined(RECAST_C_STATIC)
    #ifdef RECAST_C_EXPORTS
        #define RECAST_C_API __declspec(dllexport)
    #else
        #define RECAST_C_API __declspec(dllimport)
    #endif
#else
    #define RECAST_C_API
#endif

/* Constants */
#define C_RC_PI 3.14159265f
#define C_RC_SPAN_HEIGHT_BITS 13
#define C_RC_SPAN_MAX_HEIGHT ((1 << C_RC_SPAN_HEIGHT_BITS) - 1)
#define C_RC_SPANS_PER_POOL 2048
#define C_RC_BORDER_REG 0x8000
#define C_RC_MULTIPLE_REGS 0
#define C_RC_BORDER_VERTEX 0x10000
#define C_RC_AREA_BORDER 0x20000
#define C_RC_CONTOUR_REG_MASK 0xffff
#define C_RC_MESH_NULL_IDX 0xffff
#define C_RC_NULL_AREA 0
#define C_RC_WALKABLE_AREA 63
#define C_RC_NOT_CONNECTED 0x3f

/* Log categories */
typedef enum C_rcLogCategory {
    C_RC_LOG_PROGRESS = 1,
    C_RC_LOG_WARNING,
    C_RC_LOG_ERROR
} C_rcLogCategory;

/* Timer labels */
typedef enum C_rcTimerLabel {
    C_RC_TIMER_TOTAL,
    C_RC_TIMER_TEMP,
    C_RC_TIMER_RASTERIZE_TRIANGLES,
    C_RC_TIMER_BUILD_COMPACTHEIGHTFIELD,
    C_RC_TIMER_BUILD_CONTOURS,
    C_RC_TIMER_BUILD_CONTOURS_TRACE,
    C_RC_TIMER_BUILD_CONTOURS_SIMPLIFY,
    C_RC_TIMER_FILTER_BORDER,
    C_RC_TIMER_FILTER_WALKABLE,
    C_RC_TIMER_MEDIAN_AREA,
    C_RC_TIMER_FILTER_LOW_OBSTACLES,
    C_RC_TIMER_BUILD_POLYMESH,
    C_RC_TIMER_MERGE_POLYMESH,
    C_RC_TIMER_ERODE_AREA,
    C_RC_TIMER_MARK_BOX_AREA,
    C_RC_TIMER_MARK_CYLINDER_AREA,
    C_RC_TIMER_MARK_CONVEXPOLY_AREA,
    C_RC_TIMER_BUILD_DISTANCEFIELD,
    C_RC_TIMER_BUILD_DISTANCEFIELD_DIST,
    C_RC_TIMER_BUILD_DISTANCEFIELD_BLUR,
    C_RC_TIMER_BUILD_REGIONS,
    C_RC_TIMER_BUILD_REGIONS_WATERSHED,
    C_RC_TIMER_BUILD_REGIONS_EXPAND,
    C_RC_TIMER_BUILD_REGIONS_FLOOD,
    C_RC_TIMER_BUILD_REGIONS_FILTER,
    C_RC_TIMER_BUILD_LAYERS,
    C_RC_TIMER_BUILD_POLYMESHDETAIL,
    C_RC_TIMER_MERGE_POLYMESHDETAIL,
    C_RC_MAX_TIMERS
} C_rcTimerLabel;

/* Build contour flags */
typedef enum C_rcBuildContoursFlags {
    C_RC_CONTOUR_TESS_WALL_EDGES = 0x01,
    C_RC_CONTOUR_TESS_AREA_EDGES = 0x02
} C_rcBuildContoursFlags;

/* Allocation hints */
typedef enum C_rcAllocHint {
    C_RC_ALLOC_PERM,
    C_RC_ALLOC_TEMP
} C_rcAllocHint;

/* Opaque handle types */
typedef struct rcContext_s* rcContextHandle;
typedef struct rcHeightfield_s* rcHeightfieldHandle;
typedef struct rcCompactHeightfield_s* rcCompactHeightfieldHandle;
typedef struct rcHeightfieldLayerSet_s* rcHeightfieldLayerSetHandle;
typedef struct rcContourSet_s* rcContourSetHandle;
typedef struct rcPolyMesh_s* rcPolyMeshHandle;
typedef struct rcPolyMeshDetail_s* rcPolyMeshDetailHandle;

/* Configuration structure */
typedef struct C_rcConfig {
    int width;
    int height;
    int tileSize;
    int borderSize;
    float cs;
    float ch;
    float bmin[3];
    float bmax[3];
    float walkableSlopeAngle;
    int walkableHeight;
    int walkableClimb;
    int walkableRadius;
    int maxEdgeLen;
    float maxSimplificationError;
    int minRegionArea;
    int mergeRegionArea;
    int maxVertsPerPoly;
    float detailSampleDist;
    float detailSampleMaxError;
} C_rcConfig;

/* Span structure (for direct access) */
typedef struct C_rcSpan {
    unsigned int smin : 13;
    unsigned int smax : 13;
    unsigned int area : 6;
    struct C_rcSpan* next;
} C_rcSpan;

/* Compact cell structure */
typedef struct C_rcCompactCell {
    unsigned int index : 24;
    unsigned int count : 8;
} C_rcCompactCell;

/* Compact span structure */
typedef struct C_rcCompactSpan {
    unsigned short y;
    unsigned short reg;
    unsigned int con : 24;
    unsigned int h : 8;
} C_rcCompactSpan;

/* Heightfield layer structure */
typedef struct C_rcHeightfieldLayer {
    float bmin[3];
    float bmax[3];
    float cs;
    float ch;
    int width;
    int height;
    int minx;
    int maxx;
    int miny;
    int maxy;
    int hmin;
    int hmax;
    unsigned char* heights;
    unsigned char* areas;
    unsigned char* cons;
} C_rcHeightfieldLayer;

/* Contour structure */
typedef struct C_rcContour {
    int* verts;
    int nverts;
    int* rverts;
    int nrverts;
    unsigned short reg;
    unsigned char area;
} C_rcContour;

/* Allocator function types */
typedef void* (*C_rcAllocFunc)(size_t size, C_rcAllocHint hint);
typedef void (*C_rcFreeFunc)(void* ptr);

/* Context log callback */
typedef void (*C_rcLogFunc)(C_rcLogCategory category, const char* msg, int len);

/* Memory allocation */
RECAST_C_API void C_rcAllocSetCustom(C_rcAllocFunc allocFunc, C_rcFreeFunc freeFunc);
RECAST_C_API void* C_rcAlloc(size_t size, C_rcAllocHint hint);
RECAST_C_API void C_rcFree(void* ptr);

/* Context functions */
RECAST_C_API rcContextHandle C_rcCreateContext(int enableLog, int enableTimer);
RECAST_C_API void C_rcDestroyContext(rcContextHandle ctx);
RECAST_C_API void C_rcContextEnableLog(rcContextHandle ctx, int state);
RECAST_C_API void C_rcContextResetLog(rcContextHandle ctx);
RECAST_C_API void C_rcContextEnableTimer(rcContextHandle ctx, int state);
RECAST_C_API void C_rcContextResetTimers(rcContextHandle ctx);
RECAST_C_API void C_rcContextStartTimer(rcContextHandle ctx, C_rcTimerLabel label);
RECAST_C_API void C_rcContextStopTimer(rcContextHandle ctx, C_rcTimerLabel label);
RECAST_C_API int C_rcContextGetAccumulatedTime(rcContextHandle ctx, C_rcTimerLabel label);

/* Heightfield allocation and management */
RECAST_C_API rcHeightfieldHandle C_rcAllocHeightfield(void);
RECAST_C_API void C_rcFreeHeightField(rcHeightfieldHandle hf);
RECAST_C_API int C_rcCreateHeightfield(rcContextHandle ctx, rcHeightfieldHandle hf,
    int width, int height, const float* bmin, const float* bmax, float cs, float ch);

/* Heightfield accessors */
RECAST_C_API int C_rcHeightfieldGetWidth(rcHeightfieldHandle hf);
RECAST_C_API int C_rcHeightfieldGetHeight(rcHeightfieldHandle hf);
RECAST_C_API void C_rcHeightfieldGetBMin(rcHeightfieldHandle hf, float* bmin);
RECAST_C_API void C_rcHeightfieldGetBMax(rcHeightfieldHandle hf, float* bmax);
RECAST_C_API float C_rcHeightfieldGetCs(rcHeightfieldHandle hf);
RECAST_C_API float C_rcHeightfieldGetCh(rcHeightfieldHandle hf);
RECAST_C_API C_rcSpan** C_rcHeightfieldGetSpans(rcHeightfieldHandle hf);

/* Compact heightfield allocation and management */
RECAST_C_API rcCompactHeightfieldHandle C_rcAllocCompactHeightfield(void);
RECAST_C_API void C_rcFreeCompactHeightfield(rcCompactHeightfieldHandle chf);

/* Compact heightfield accessors */
RECAST_C_API int C_rcCompactHeightfieldGetWidth(rcCompactHeightfieldHandle chf);
RECAST_C_API int C_rcCompactHeightfieldGetHeight(rcCompactHeightfieldHandle chf);
RECAST_C_API int C_rcCompactHeightfieldGetSpanCount(rcCompactHeightfieldHandle chf);
RECAST_C_API int C_rcCompactHeightfieldGetWalkableHeight(rcCompactHeightfieldHandle chf);
RECAST_C_API int C_rcCompactHeightfieldGetWalkableClimb(rcCompactHeightfieldHandle chf);
RECAST_C_API int C_rcCompactHeightfieldGetBorderSize(rcCompactHeightfieldHandle chf);
RECAST_C_API unsigned short C_rcCompactHeightfieldGetMaxDistance(rcCompactHeightfieldHandle chf);
RECAST_C_API unsigned short C_rcCompactHeightfieldGetMaxRegions(rcCompactHeightfieldHandle chf);
RECAST_C_API void C_rcCompactHeightfieldGetBMin(rcCompactHeightfieldHandle chf, float* bmin);
RECAST_C_API void C_rcCompactHeightfieldGetBMax(rcCompactHeightfieldHandle chf, float* bmax);
RECAST_C_API float C_rcCompactHeightfieldGetCs(rcCompactHeightfieldHandle chf);
RECAST_C_API float C_rcCompactHeightfieldGetCh(rcCompactHeightfieldHandle chf);
RECAST_C_API C_rcCompactCell* C_rcCompactHeightfieldGetCells(rcCompactHeightfieldHandle chf);
RECAST_C_API C_rcCompactSpan* C_rcCompactHeightfieldGetSpans(rcCompactHeightfieldHandle chf);
RECAST_C_API unsigned short* C_rcCompactHeightfieldGetDist(rcCompactHeightfieldHandle chf);
RECAST_C_API unsigned char* C_rcCompactHeightfieldGetAreas(rcCompactHeightfieldHandle chf);

/* Heightfield layer set */
RECAST_C_API rcHeightfieldLayerSetHandle C_rcAllocHeightfieldLayerSet(void);
RECAST_C_API void C_rcFreeHeightfieldLayerSet(rcHeightfieldLayerSetHandle lset);
RECAST_C_API int C_rcHeightfieldLayerSetGetNLayers(rcHeightfieldLayerSetHandle lset);
RECAST_C_API C_rcHeightfieldLayer* C_rcHeightfieldLayerSetGetLayers(rcHeightfieldLayerSetHandle lset);

/* Contour set */
RECAST_C_API rcContourSetHandle C_rcAllocContourSet(void);
RECAST_C_API void C_rcFreeContourSet(rcContourSetHandle cset);
RECAST_C_API int C_rcContourSetGetNConts(rcContourSetHandle cset);
RECAST_C_API C_rcContour* C_rcContourSetGetConts(rcContourSetHandle cset);
RECAST_C_API void C_rcContourSetGetBMin(rcContourSetHandle cset, float* bmin);
RECAST_C_API void C_rcContourSetGetBMax(rcContourSetHandle cset, float* bmax);
RECAST_C_API float C_rcContourSetGetCs(rcContourSetHandle cset);
RECAST_C_API float C_rcContourSetGetCh(rcContourSetHandle cset);
RECAST_C_API int C_rcContourSetGetWidth(rcContourSetHandle cset);
RECAST_C_API int C_rcContourSetGetHeight(rcContourSetHandle cset);
RECAST_C_API int C_rcContourSetGetBorderSize(rcContourSetHandle cset);
RECAST_C_API float C_rcContourSetGetMaxError(rcContourSetHandle cset);

/* Poly mesh */
RECAST_C_API rcPolyMeshHandle C_rcAllocPolyMesh(void);
RECAST_C_API void C_rcFreePolyMesh(rcPolyMeshHandle pmesh);
RECAST_C_API unsigned short* C_rcPolyMeshGetVerts(rcPolyMeshHandle pmesh);
RECAST_C_API unsigned short* C_rcPolyMeshGetPolys(rcPolyMeshHandle pmesh);
RECAST_C_API unsigned short* C_rcPolyMeshGetRegs(rcPolyMeshHandle pmesh);
RECAST_C_API unsigned short* C_rcPolyMeshGetFlags(rcPolyMeshHandle pmesh);
RECAST_C_API unsigned char* C_rcPolyMeshGetAreas(rcPolyMeshHandle pmesh);
RECAST_C_API int C_rcPolyMeshGetNVerts(rcPolyMeshHandle pmesh);
RECAST_C_API int C_rcPolyMeshGetNPolys(rcPolyMeshHandle pmesh);
RECAST_C_API int C_rcPolyMeshGetMaxPolys(rcPolyMeshHandle pmesh);
RECAST_C_API int C_rcPolyMeshGetNvp(rcPolyMeshHandle pmesh);
RECAST_C_API void C_rcPolyMeshGetBMin(rcPolyMeshHandle pmesh, float* bmin);
RECAST_C_API void C_rcPolyMeshGetBMax(rcPolyMeshHandle pmesh, float* bmax);
RECAST_C_API float C_rcPolyMeshGetCs(rcPolyMeshHandle pmesh);
RECAST_C_API float C_rcPolyMeshGetCh(rcPolyMeshHandle pmesh);
RECAST_C_API int C_rcPolyMeshGetBorderSize(rcPolyMeshHandle pmesh);
RECAST_C_API float C_rcPolyMeshGetMaxEdgeError(rcPolyMeshHandle pmesh);

/* Poly mesh detail */
RECAST_C_API rcPolyMeshDetailHandle C_rcAllocPolyMeshDetail(void);
RECAST_C_API void C_rcFreePolyMeshDetail(rcPolyMeshDetailHandle dmesh);
RECAST_C_API unsigned int* C_rcPolyMeshDetailGetMeshes(rcPolyMeshDetailHandle dmesh);
RECAST_C_API float* C_rcPolyMeshDetailGetVerts(rcPolyMeshDetailHandle dmesh);
RECAST_C_API unsigned char* C_rcPolyMeshDetailGetTris(rcPolyMeshDetailHandle dmesh);
RECAST_C_API int C_rcPolyMeshDetailGetNMeshes(rcPolyMeshDetailHandle dmesh);
RECAST_C_API int C_rcPolyMeshDetailGetNVerts(rcPolyMeshDetailHandle dmesh);
RECAST_C_API int C_rcPolyMeshDetailGetNTris(rcPolyMeshDetailHandle dmesh);

/* Utility functions */
RECAST_C_API void C_rcCalcBounds(const float* verts, int numVerts, float* minBounds, float* maxBounds);
RECAST_C_API void C_rcCalcGridSize(const float* minBounds, const float* maxBounds, float cellSize, int* sizeX, int* sizeZ);

/* Triangle marking */
RECAST_C_API void C_rcMarkWalkableTriangles(rcContextHandle ctx, float walkableSlopeAngle,
    const float* verts, int numVerts, const int* tris, int numTris, unsigned char* triAreaIDs);
RECAST_C_API void C_rcClearUnwalkableTriangles(rcContextHandle ctx, float walkableSlopeAngle,
    const float* verts, int numVerts, const int* tris, int numTris, unsigned char* triAreaIDs);

/* Span management */
RECAST_C_API int C_rcAddSpan(rcContextHandle ctx, rcHeightfieldHandle hf, int x, int z,
    unsigned short spanMin, unsigned short spanMax, unsigned char areaID, int flagMergeThreshold);

/* Rasterization */
RECAST_C_API int C_rcRasterizeTriangle(rcContextHandle ctx, const float* v0, const float* v1, const float* v2,
    unsigned char areaID, rcHeightfieldHandle hf, int flagMergeThreshold);
RECAST_C_API int C_rcRasterizeTriangles(rcContextHandle ctx, const float* verts, int numVerts,
    const int* tris, const unsigned char* triAreaIDs, int numTris, rcHeightfieldHandle hf, int flagMergeThreshold);
RECAST_C_API int C_rcRasterizeTrianglesUShort(rcContextHandle ctx, const float* verts, int numVerts,
    const unsigned short* tris, const unsigned char* triAreaIDs, int numTris, rcHeightfieldHandle hf, int flagMergeThreshold);
RECAST_C_API int C_rcRasterizeTrianglesSoup(rcContextHandle ctx, const float* verts,
    const unsigned char* triAreaIDs, int numTris, rcHeightfieldHandle hf, int flagMergeThreshold);

/* Filtering */
RECAST_C_API void C_rcFilterLowHangingWalkableObstacles(rcContextHandle ctx, int walkableClimb, rcHeightfieldHandle hf);
RECAST_C_API void C_rcFilterLedgeSpans(rcContextHandle ctx, int walkableHeight, int walkableClimb, rcHeightfieldHandle hf);
RECAST_C_API void C_rcFilterWalkableLowHeightSpans(rcContextHandle ctx, int walkableHeight, rcHeightfieldHandle hf);
RECAST_C_API int C_rcGetHeightFieldSpanCount(rcContextHandle ctx, rcHeightfieldHandle hf);

/* Compact heightfield building */
RECAST_C_API int C_rcBuildCompactHeightfield(rcContextHandle ctx, int walkableHeight, int walkableClimb,
    rcHeightfieldHandle hf, rcCompactHeightfieldHandle chf);

/* Area manipulation */
RECAST_C_API int C_rcErodeWalkableArea(rcContextHandle ctx, int erosionRadius, rcCompactHeightfieldHandle chf);
RECAST_C_API int C_rcMedianFilterWalkableArea(rcContextHandle ctx, rcCompactHeightfieldHandle chf);
RECAST_C_API void C_rcMarkBoxArea(rcContextHandle ctx, const float* boxMinBounds, const float* boxMaxBounds,
    unsigned char areaId, rcCompactHeightfieldHandle chf);
RECAST_C_API void C_rcMarkConvexPolyArea(rcContextHandle ctx, const float* verts, int numVerts,
    float minY, float maxY, unsigned char areaId, rcCompactHeightfieldHandle chf);
RECAST_C_API int C_rcOffsetPoly(const float* verts, int numVerts, float offset, float* outVerts, int maxOutVerts);
RECAST_C_API void C_rcMarkCylinderArea(rcContextHandle ctx, const float* position, float radius, float height,
    unsigned char areaId, rcCompactHeightfieldHandle chf);

/* Distance field and regions */
RECAST_C_API int C_rcBuildDistanceField(rcContextHandle ctx, rcCompactHeightfieldHandle chf);
RECAST_C_API int C_rcBuildRegions(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
    int borderSize, int minRegionArea, int mergeRegionArea);
RECAST_C_API int C_rcBuildLayerRegions(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
    int borderSize, int minRegionArea);
RECAST_C_API int C_rcBuildRegionsMonotone(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
    int borderSize, int minRegionArea, int mergeRegionArea);

/* Connection helpers */
RECAST_C_API void C_rcSetCon(C_rcCompactSpan* span, int direction, int neighborIndex);
RECAST_C_API int C_rcGetCon(const C_rcCompactSpan* span, int direction);
RECAST_C_API int C_rcGetDirOffsetX(int direction);
RECAST_C_API int C_rcGetDirOffsetY(int direction);
RECAST_C_API int C_rcGetDirForOffset(int offsetX, int offsetZ);

/* Layer, contour, polymesh building */
RECAST_C_API int C_rcBuildHeightfieldLayers(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
    int borderSize, int walkableHeight, rcHeightfieldLayerSetHandle lset);
RECAST_C_API int C_rcBuildContours(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
    float maxError, int maxEdgeLen, rcContourSetHandle cset, int buildFlags);
RECAST_C_API int C_rcBuildPolyMesh(rcContextHandle ctx, rcContourSetHandle cset, int nvp, rcPolyMeshHandle mesh);
RECAST_C_API int C_rcMergePolyMeshes(rcContextHandle ctx, rcPolyMeshHandle* meshes, int nmeshes, rcPolyMeshHandle mesh);
RECAST_C_API int C_rcBuildPolyMeshDetail(rcContextHandle ctx, rcPolyMeshHandle mesh, rcCompactHeightfieldHandle chf,
    float sampleDist, float sampleMaxError, rcPolyMeshDetailHandle dmesh);
RECAST_C_API int C_rcCopyPolyMesh(rcContextHandle ctx, rcPolyMeshHandle src, rcPolyMeshHandle dst);
RECAST_C_API int C_rcMergePolyMeshDetails(rcContextHandle ctx, rcPolyMeshDetailHandle* meshes, int nmeshes, rcPolyMeshDetailHandle mesh);

/* Math utilities */
RECAST_C_API float C_rcSqrt(float x);

#ifdef __cplusplus
}
#endif

#endif /* RECAST_C_H */
