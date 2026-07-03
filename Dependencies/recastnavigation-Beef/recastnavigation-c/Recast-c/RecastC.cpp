/*
 * Recast C API Implementation
 */

#include "RecastC.h"
#include "Recast.h"
#include "RecastAlloc.h"
#include <string.h>

/* Simple context implementation for C API */
class rcContextC : public rcContext {
public:
    rcContextC(bool logEnabled, bool timerEnabled) : rcContext(logEnabled && timerEnabled) {
        m_logEnabled = logEnabled;
        m_timerEnabled = timerEnabled;
    }
};

/* Static storage for custom allocator callbacks */
static C_rcAllocFunc s_rcAllocFunc = nullptr;
static C_rcFreeFunc s_rcFreeFunc = nullptr;

/* Wrapper functions to convert between C and C++ callback types */
static void* rcAllocWrapper(size_t size, rcAllocHint hint) {
    return s_rcAllocFunc(size, (C_rcAllocHint)hint);
}

static void rcFreeWrapper(void* ptr) {
    s_rcFreeFunc(ptr);
}

/* Memory allocation */
extern "C" {

RECAST_C_API void C_rcAllocSetCustom(C_rcAllocFunc allocFunc, C_rcFreeFunc freeFunc) {
    s_rcAllocFunc = allocFunc;
    s_rcFreeFunc = freeFunc;
    if (allocFunc && freeFunc) {
        ::rcAllocSetCustom(rcAllocWrapper, rcFreeWrapper);
    } else {
        ::rcAllocSetCustom(nullptr, nullptr);
    }
}

RECAST_C_API void* C_rcAlloc(size_t size, C_rcAllocHint hint) {
    return ::rcAlloc(size, (::rcAllocHint)hint);
}

RECAST_C_API void C_rcFree(void* ptr) {
    ::rcFree(ptr);
}

/* Context functions */
RECAST_C_API rcContextHandle C_rcCreateContext(int enableLog, int enableTimer) {
    return reinterpret_cast<rcContextHandle>(new rcContextC(enableLog != 0, enableTimer != 0));
}

RECAST_C_API void C_rcDestroyContext(rcContextHandle ctx) {
    delete reinterpret_cast<rcContextC*>(ctx);
}

RECAST_C_API void C_rcContextEnableLog(rcContextHandle ctx, int state) {
    if (ctx) reinterpret_cast<rcContext*>(ctx)->enableLog(state != 0);
}

RECAST_C_API void C_rcContextResetLog(rcContextHandle ctx) {
    if (ctx) reinterpret_cast<rcContext*>(ctx)->resetLog();
}

RECAST_C_API void C_rcContextEnableTimer(rcContextHandle ctx, int state) {
    if (ctx) reinterpret_cast<rcContext*>(ctx)->enableTimer(state != 0);
}

RECAST_C_API void C_rcContextResetTimers(rcContextHandle ctx) {
    if (ctx) reinterpret_cast<rcContext*>(ctx)->resetTimers();
}

RECAST_C_API void C_rcContextStartTimer(rcContextHandle ctx, C_rcTimerLabel label) {
    if (ctx) reinterpret_cast<rcContext*>(ctx)->startTimer((::rcTimerLabel)label);
}

RECAST_C_API void C_rcContextStopTimer(rcContextHandle ctx, C_rcTimerLabel label) {
    if (ctx) reinterpret_cast<rcContext*>(ctx)->stopTimer((::rcTimerLabel)label);
}

RECAST_C_API int C_rcContextGetAccumulatedTime(rcContextHandle ctx, C_rcTimerLabel label) {
    if (ctx) return reinterpret_cast<rcContext*>(ctx)->getAccumulatedTime((::rcTimerLabel)label);
    return -1;
}

/* Heightfield allocation and management */
RECAST_C_API rcHeightfieldHandle C_rcAllocHeightfield(void) {
    return reinterpret_cast<rcHeightfieldHandle>(::rcAllocHeightfield());
}

RECAST_C_API void C_rcFreeHeightField(rcHeightfieldHandle hf) {
    ::rcFreeHeightField(reinterpret_cast<::rcHeightfield*>(hf));
}

RECAST_C_API int C_rcCreateHeightfield(rcContextHandle ctx, rcHeightfieldHandle hf,
    int width, int height, const float* bmin, const float* bmax, float cs, float ch) {
    return ::rcCreateHeightfield(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcHeightfield*>(hf), width, height, bmin, bmax, cs, ch) ? 1 : 0;
}

/* Heightfield accessors */
RECAST_C_API int C_rcHeightfieldGetWidth(rcHeightfieldHandle hf) {
    return reinterpret_cast<::rcHeightfield*>(hf)->width;
}

RECAST_C_API int C_rcHeightfieldGetHeight(rcHeightfieldHandle hf) {
    return reinterpret_cast<::rcHeightfield*>(hf)->height;
}

RECAST_C_API void C_rcHeightfieldGetBMin(rcHeightfieldHandle hf, float* bmin) {
    ::rcHeightfield* h = reinterpret_cast<::rcHeightfield*>(hf);
    bmin[0] = h->bmin[0]; bmin[1] = h->bmin[1]; bmin[2] = h->bmin[2];
}

RECAST_C_API void C_rcHeightfieldGetBMax(rcHeightfieldHandle hf, float* bmax) {
    ::rcHeightfield* h = reinterpret_cast<::rcHeightfield*>(hf);
    bmax[0] = h->bmax[0]; bmax[1] = h->bmax[1]; bmax[2] = h->bmax[2];
}

RECAST_C_API float C_rcHeightfieldGetCs(rcHeightfieldHandle hf) {
    return reinterpret_cast<::rcHeightfield*>(hf)->cs;
}

RECAST_C_API float C_rcHeightfieldGetCh(rcHeightfieldHandle hf) {
    return reinterpret_cast<::rcHeightfield*>(hf)->ch;
}

RECAST_C_API C_rcSpan** C_rcHeightfieldGetSpans(rcHeightfieldHandle hf) {
    return reinterpret_cast<C_rcSpan**>(reinterpret_cast<::rcHeightfield*>(hf)->spans);
}

/* Compact heightfield */
RECAST_C_API rcCompactHeightfieldHandle C_rcAllocCompactHeightfield(void) {
    return reinterpret_cast<rcCompactHeightfieldHandle>(::rcAllocCompactHeightfield());
}

RECAST_C_API void C_rcFreeCompactHeightfield(rcCompactHeightfieldHandle chf) {
    ::rcFreeCompactHeightfield(reinterpret_cast<::rcCompactHeightfield*>(chf));
}

RECAST_C_API int C_rcCompactHeightfieldGetWidth(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->width;
}

RECAST_C_API int C_rcCompactHeightfieldGetHeight(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->height;
}

RECAST_C_API int C_rcCompactHeightfieldGetSpanCount(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->spanCount;
}

RECAST_C_API int C_rcCompactHeightfieldGetWalkableHeight(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->walkableHeight;
}

RECAST_C_API int C_rcCompactHeightfieldGetWalkableClimb(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->walkableClimb;
}

RECAST_C_API int C_rcCompactHeightfieldGetBorderSize(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->borderSize;
}

RECAST_C_API unsigned short C_rcCompactHeightfieldGetMaxDistance(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->maxDistance;
}

RECAST_C_API unsigned short C_rcCompactHeightfieldGetMaxRegions(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->maxRegions;
}

RECAST_C_API void C_rcCompactHeightfieldGetBMin(rcCompactHeightfieldHandle chf, float* bmin) {
    ::rcCompactHeightfield* c = reinterpret_cast<::rcCompactHeightfield*>(chf);
    bmin[0] = c->bmin[0]; bmin[1] = c->bmin[1]; bmin[2] = c->bmin[2];
}

RECAST_C_API void C_rcCompactHeightfieldGetBMax(rcCompactHeightfieldHandle chf, float* bmax) {
    ::rcCompactHeightfield* c = reinterpret_cast<::rcCompactHeightfield*>(chf);
    bmax[0] = c->bmax[0]; bmax[1] = c->bmax[1]; bmax[2] = c->bmax[2];
}

RECAST_C_API float C_rcCompactHeightfieldGetCs(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->cs;
}

RECAST_C_API float C_rcCompactHeightfieldGetCh(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->ch;
}

RECAST_C_API C_rcCompactCell* C_rcCompactHeightfieldGetCells(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<C_rcCompactCell*>(reinterpret_cast<::rcCompactHeightfield*>(chf)->cells);
}

RECAST_C_API C_rcCompactSpan* C_rcCompactHeightfieldGetSpans(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<C_rcCompactSpan*>(reinterpret_cast<::rcCompactHeightfield*>(chf)->spans);
}

RECAST_C_API unsigned short* C_rcCompactHeightfieldGetDist(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->dist;
}

RECAST_C_API unsigned char* C_rcCompactHeightfieldGetAreas(rcCompactHeightfieldHandle chf) {
    return reinterpret_cast<::rcCompactHeightfield*>(chf)->areas;
}

/* Heightfield layer set */
RECAST_C_API rcHeightfieldLayerSetHandle C_rcAllocHeightfieldLayerSet(void) {
    return reinterpret_cast<rcHeightfieldLayerSetHandle>(::rcAllocHeightfieldLayerSet());
}

RECAST_C_API void C_rcFreeHeightfieldLayerSet(rcHeightfieldLayerSetHandle lset) {
    ::rcFreeHeightfieldLayerSet(reinterpret_cast<::rcHeightfieldLayerSet*>(lset));
}

RECAST_C_API int C_rcHeightfieldLayerSetGetNLayers(rcHeightfieldLayerSetHandle lset) {
    return reinterpret_cast<::rcHeightfieldLayerSet*>(lset)->nlayers;
}

RECAST_C_API C_rcHeightfieldLayer* C_rcHeightfieldLayerSetGetLayers(rcHeightfieldLayerSetHandle lset) {
    return reinterpret_cast<C_rcHeightfieldLayer*>(reinterpret_cast<::rcHeightfieldLayerSet*>(lset)->layers);
}

/* Contour set */
RECAST_C_API rcContourSetHandle C_rcAllocContourSet(void) {
    return reinterpret_cast<rcContourSetHandle>(::rcAllocContourSet());
}

RECAST_C_API void C_rcFreeContourSet(rcContourSetHandle cset) {
    ::rcFreeContourSet(reinterpret_cast<::rcContourSet*>(cset));
}

RECAST_C_API int C_rcContourSetGetNConts(rcContourSetHandle cset) {
    return reinterpret_cast<::rcContourSet*>(cset)->nconts;
}

RECAST_C_API C_rcContour* C_rcContourSetGetConts(rcContourSetHandle cset) {
    return reinterpret_cast<C_rcContour*>(reinterpret_cast<::rcContourSet*>(cset)->conts);
}

RECAST_C_API void C_rcContourSetGetBMin(rcContourSetHandle cset, float* bmin) {
    ::rcContourSet* c = reinterpret_cast<::rcContourSet*>(cset);
    bmin[0] = c->bmin[0]; bmin[1] = c->bmin[1]; bmin[2] = c->bmin[2];
}

RECAST_C_API void C_rcContourSetGetBMax(rcContourSetHandle cset, float* bmax) {
    ::rcContourSet* c = reinterpret_cast<::rcContourSet*>(cset);
    bmax[0] = c->bmax[0]; bmax[1] = c->bmax[1]; bmax[2] = c->bmax[2];
}

RECAST_C_API float C_rcContourSetGetCs(rcContourSetHandle cset) {
    return reinterpret_cast<::rcContourSet*>(cset)->cs;
}

RECAST_C_API float C_rcContourSetGetCh(rcContourSetHandle cset) {
    return reinterpret_cast<::rcContourSet*>(cset)->ch;
}

RECAST_C_API int C_rcContourSetGetWidth(rcContourSetHandle cset) {
    return reinterpret_cast<::rcContourSet*>(cset)->width;
}

RECAST_C_API int C_rcContourSetGetHeight(rcContourSetHandle cset) {
    return reinterpret_cast<::rcContourSet*>(cset)->height;
}

RECAST_C_API int C_rcContourSetGetBorderSize(rcContourSetHandle cset) {
    return reinterpret_cast<::rcContourSet*>(cset)->borderSize;
}

RECAST_C_API float C_rcContourSetGetMaxError(rcContourSetHandle cset) {
    return reinterpret_cast<::rcContourSet*>(cset)->maxError;
}

/* Poly mesh */
RECAST_C_API rcPolyMeshHandle C_rcAllocPolyMesh(void) {
    return reinterpret_cast<rcPolyMeshHandle>(::rcAllocPolyMesh());
}

RECAST_C_API void C_rcFreePolyMesh(rcPolyMeshHandle pmesh) {
    ::rcFreePolyMesh(reinterpret_cast<::rcPolyMesh*>(pmesh));
}

RECAST_C_API unsigned short* C_rcPolyMeshGetVerts(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->verts;
}

RECAST_C_API unsigned short* C_rcPolyMeshGetPolys(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->polys;
}

RECAST_C_API unsigned short* C_rcPolyMeshGetRegs(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->regs;
}

RECAST_C_API unsigned short* C_rcPolyMeshGetFlags(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->flags;
}

RECAST_C_API unsigned char* C_rcPolyMeshGetAreas(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->areas;
}

RECAST_C_API int C_rcPolyMeshGetNVerts(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->nverts;
}

RECAST_C_API int C_rcPolyMeshGetNPolys(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->npolys;
}

RECAST_C_API int C_rcPolyMeshGetMaxPolys(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->maxpolys;
}

RECAST_C_API int C_rcPolyMeshGetNvp(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->nvp;
}

RECAST_C_API void C_rcPolyMeshGetBMin(rcPolyMeshHandle pmesh, float* bmin) {
    ::rcPolyMesh* p = reinterpret_cast<::rcPolyMesh*>(pmesh);
    bmin[0] = p->bmin[0]; bmin[1] = p->bmin[1]; bmin[2] = p->bmin[2];
}

RECAST_C_API void C_rcPolyMeshGetBMax(rcPolyMeshHandle pmesh, float* bmax) {
    ::rcPolyMesh* p = reinterpret_cast<::rcPolyMesh*>(pmesh);
    bmax[0] = p->bmax[0]; bmax[1] = p->bmax[1]; bmax[2] = p->bmax[2];
}

RECAST_C_API float C_rcPolyMeshGetCs(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->cs;
}

RECAST_C_API float C_rcPolyMeshGetCh(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->ch;
}

RECAST_C_API int C_rcPolyMeshGetBorderSize(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->borderSize;
}

RECAST_C_API float C_rcPolyMeshGetMaxEdgeError(rcPolyMeshHandle pmesh) {
    return reinterpret_cast<::rcPolyMesh*>(pmesh)->maxEdgeError;
}

/* Poly mesh detail */
RECAST_C_API rcPolyMeshDetailHandle C_rcAllocPolyMeshDetail(void) {
    return reinterpret_cast<rcPolyMeshDetailHandle>(::rcAllocPolyMeshDetail());
}

RECAST_C_API void C_rcFreePolyMeshDetail(rcPolyMeshDetailHandle dmesh) {
    ::rcFreePolyMeshDetail(reinterpret_cast<::rcPolyMeshDetail*>(dmesh));
}

RECAST_C_API unsigned int* C_rcPolyMeshDetailGetMeshes(rcPolyMeshDetailHandle dmesh) {
    return reinterpret_cast<::rcPolyMeshDetail*>(dmesh)->meshes;
}

RECAST_C_API float* C_rcPolyMeshDetailGetVerts(rcPolyMeshDetailHandle dmesh) {
    return reinterpret_cast<::rcPolyMeshDetail*>(dmesh)->verts;
}

RECAST_C_API unsigned char* C_rcPolyMeshDetailGetTris(rcPolyMeshDetailHandle dmesh) {
    return reinterpret_cast<::rcPolyMeshDetail*>(dmesh)->tris;
}

RECAST_C_API int C_rcPolyMeshDetailGetNMeshes(rcPolyMeshDetailHandle dmesh) {
    return reinterpret_cast<::rcPolyMeshDetail*>(dmesh)->nmeshes;
}

RECAST_C_API int C_rcPolyMeshDetailGetNVerts(rcPolyMeshDetailHandle dmesh) {
    return reinterpret_cast<::rcPolyMeshDetail*>(dmesh)->nverts;
}

RECAST_C_API int C_rcPolyMeshDetailGetNTris(rcPolyMeshDetailHandle dmesh) {
    return reinterpret_cast<::rcPolyMeshDetail*>(dmesh)->ntris;
}

/* Utility functions */
RECAST_C_API void C_rcCalcBounds(const float* verts, int numVerts, float* minBounds, float* maxBounds) {
    ::rcCalcBounds(verts, numVerts, minBounds, maxBounds);
}

RECAST_C_API void C_rcCalcGridSize(const float* minBounds, const float* maxBounds, float cellSize, int* sizeX, int* sizeZ) {
    ::rcCalcGridSize(minBounds, maxBounds, cellSize, sizeX, sizeZ);
}

/* Triangle marking */
RECAST_C_API void C_rcMarkWalkableTriangles(rcContextHandle ctx, float walkableSlopeAngle,
    const float* verts, int numVerts, const int* tris, int numTris, unsigned char* triAreaIDs) {
    ::rcMarkWalkableTriangles(reinterpret_cast<rcContext*>(ctx), walkableSlopeAngle,
        verts, numVerts, tris, numTris, triAreaIDs);
}

RECAST_C_API void C_rcClearUnwalkableTriangles(rcContextHandle ctx, float walkableSlopeAngle,
    const float* verts, int numVerts, const int* tris, int numTris, unsigned char* triAreaIDs) {
    ::rcClearUnwalkableTriangles(reinterpret_cast<rcContext*>(ctx), walkableSlopeAngle,
        verts, numVerts, tris, numTris, triAreaIDs);
}

/* Span management */
RECAST_C_API int C_rcAddSpan(rcContextHandle ctx, rcHeightfieldHandle hf, int x, int z,
    unsigned short spanMin, unsigned short spanMax, unsigned char areaID, int flagMergeThreshold) {
    return ::rcAddSpan(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcHeightfield*>(hf), x, z, spanMin, spanMax, areaID, flagMergeThreshold) ? 1 : 0;
}

/* Rasterization */
RECAST_C_API int C_rcRasterizeTriangle(rcContextHandle ctx, const float* v0, const float* v1, const float* v2,
    unsigned char areaID, rcHeightfieldHandle hf, int flagMergeThreshold) {
    return ::rcRasterizeTriangle(reinterpret_cast<rcContext*>(ctx), v0, v1, v2,
        areaID, *reinterpret_cast<::rcHeightfield*>(hf), flagMergeThreshold) ? 1 : 0;
}

RECAST_C_API int C_rcRasterizeTriangles(rcContextHandle ctx, const float* verts, int numVerts,
    const int* tris, const unsigned char* triAreaIDs, int numTris, rcHeightfieldHandle hf, int flagMergeThreshold) {
    return ::rcRasterizeTriangles(reinterpret_cast<rcContext*>(ctx), verts, numVerts,
        tris, triAreaIDs, numTris, *reinterpret_cast<::rcHeightfield*>(hf), flagMergeThreshold) ? 1 : 0;
}

RECAST_C_API int C_rcRasterizeTrianglesUShort(rcContextHandle ctx, const float* verts, int numVerts,
    const unsigned short* tris, const unsigned char* triAreaIDs, int numTris, rcHeightfieldHandle hf, int flagMergeThreshold) {
    return ::rcRasterizeTriangles(reinterpret_cast<rcContext*>(ctx), verts, numVerts,
        tris, triAreaIDs, numTris, *reinterpret_cast<::rcHeightfield*>(hf), flagMergeThreshold) ? 1 : 0;
}

RECAST_C_API int C_rcRasterizeTrianglesSoup(rcContextHandle ctx, const float* verts,
    const unsigned char* triAreaIDs, int numTris, rcHeightfieldHandle hf, int flagMergeThreshold) {
    return ::rcRasterizeTriangles(reinterpret_cast<rcContext*>(ctx), verts,
        triAreaIDs, numTris, *reinterpret_cast<::rcHeightfield*>(hf), flagMergeThreshold) ? 1 : 0;
}

/* Filtering */
RECAST_C_API void C_rcFilterLowHangingWalkableObstacles(rcContextHandle ctx, int walkableClimb, rcHeightfieldHandle hf) {
    ::rcFilterLowHangingWalkableObstacles(reinterpret_cast<rcContext*>(ctx), walkableClimb,
        *reinterpret_cast<::rcHeightfield*>(hf));
}

RECAST_C_API void C_rcFilterLedgeSpans(rcContextHandle ctx, int walkableHeight, int walkableClimb, rcHeightfieldHandle hf) {
    ::rcFilterLedgeSpans(reinterpret_cast<rcContext*>(ctx), walkableHeight, walkableClimb,
        *reinterpret_cast<::rcHeightfield*>(hf));
}

RECAST_C_API void C_rcFilterWalkableLowHeightSpans(rcContextHandle ctx, int walkableHeight, rcHeightfieldHandle hf) {
    ::rcFilterWalkableLowHeightSpans(reinterpret_cast<rcContext*>(ctx), walkableHeight,
        *reinterpret_cast<::rcHeightfield*>(hf));
}

RECAST_C_API int C_rcGetHeightFieldSpanCount(rcContextHandle ctx, rcHeightfieldHandle hf) {
    return ::rcGetHeightFieldSpanCount(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcHeightfield*>(hf));
}

/* Compact heightfield building */
RECAST_C_API int C_rcBuildCompactHeightfield(rcContextHandle ctx, int walkableHeight, int walkableClimb,
    rcHeightfieldHandle hf, rcCompactHeightfieldHandle chf) {
    return ::rcBuildCompactHeightfield(reinterpret_cast<rcContext*>(ctx), walkableHeight, walkableClimb,
        *reinterpret_cast<::rcHeightfield*>(hf), *reinterpret_cast<::rcCompactHeightfield*>(chf)) ? 1 : 0;
}

/* Area manipulation */
RECAST_C_API int C_rcErodeWalkableArea(rcContextHandle ctx, int erosionRadius, rcCompactHeightfieldHandle chf) {
    return ::rcErodeWalkableArea(reinterpret_cast<rcContext*>(ctx), erosionRadius,
        *reinterpret_cast<::rcCompactHeightfield*>(chf)) ? 1 : 0;
}

RECAST_C_API int C_rcMedianFilterWalkableArea(rcContextHandle ctx, rcCompactHeightfieldHandle chf) {
    return ::rcMedianFilterWalkableArea(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcCompactHeightfield*>(chf)) ? 1 : 0;
}

RECAST_C_API void C_rcMarkBoxArea(rcContextHandle ctx, const float* boxMinBounds, const float* boxMaxBounds,
    unsigned char areaId, rcCompactHeightfieldHandle chf) {
    ::rcMarkBoxArea(reinterpret_cast<rcContext*>(ctx), boxMinBounds, boxMaxBounds,
        areaId, *reinterpret_cast<::rcCompactHeightfield*>(chf));
}

RECAST_C_API void C_rcMarkConvexPolyArea(rcContextHandle ctx, const float* verts, int numVerts,
    float minY, float maxY, unsigned char areaId, rcCompactHeightfieldHandle chf) {
    ::rcMarkConvexPolyArea(reinterpret_cast<rcContext*>(ctx), verts, numVerts,
        minY, maxY, areaId, *reinterpret_cast<::rcCompactHeightfield*>(chf));
}

RECAST_C_API int C_rcOffsetPoly(const float* verts, int numVerts, float offset, float* outVerts, int maxOutVerts) {
    return ::rcOffsetPoly(verts, numVerts, offset, outVerts, maxOutVerts);
}

RECAST_C_API void C_rcMarkCylinderArea(rcContextHandle ctx, const float* position, float radius, float height,
    unsigned char areaId, rcCompactHeightfieldHandle chf) {
    ::rcMarkCylinderArea(reinterpret_cast<rcContext*>(ctx), position, radius, height,
        areaId, *reinterpret_cast<::rcCompactHeightfield*>(chf));
}

/* Distance field and regions */
RECAST_C_API int C_rcBuildDistanceField(rcContextHandle ctx, rcCompactHeightfieldHandle chf) {
    return ::rcBuildDistanceField(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcCompactHeightfield*>(chf)) ? 1 : 0;
}

RECAST_C_API int C_rcBuildRegions(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
    int borderSize, int minRegionArea, int mergeRegionArea) {
    return ::rcBuildRegions(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcCompactHeightfield*>(chf), borderSize, minRegionArea, mergeRegionArea) ? 1 : 0;
}

RECAST_C_API int C_rcBuildLayerRegions(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
    int borderSize, int minRegionArea) {
    return ::rcBuildLayerRegions(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcCompactHeightfield*>(chf), borderSize, minRegionArea) ? 1 : 0;
}

RECAST_C_API int C_rcBuildRegionsMonotone(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
    int borderSize, int minRegionArea, int mergeRegionArea) {
    return ::rcBuildRegionsMonotone(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcCompactHeightfield*>(chf), borderSize, minRegionArea, mergeRegionArea) ? 1 : 0;
}

/* Connection helpers */
RECAST_C_API void C_rcSetCon(C_rcCompactSpan* span, int direction, int neighborIndex) {
    ::rcSetCon(*reinterpret_cast<::rcCompactSpan*>(span), direction, neighborIndex);
}

RECAST_C_API int C_rcGetCon(const C_rcCompactSpan* span, int direction) {
    return ::rcGetCon(*reinterpret_cast<const ::rcCompactSpan*>(span), direction);
}

RECAST_C_API int C_rcGetDirOffsetX(int direction) {
    return ::rcGetDirOffsetX(direction);
}

RECAST_C_API int C_rcGetDirOffsetY(int direction) {
    return ::rcGetDirOffsetY(direction);
}

RECAST_C_API int C_rcGetDirForOffset(int offsetX, int offsetZ) {
    return ::rcGetDirForOffset(offsetX, offsetZ);
}

/* Layer, contour, polymesh building */
RECAST_C_API int C_rcBuildHeightfieldLayers(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
    int borderSize, int walkableHeight, rcHeightfieldLayerSetHandle lset) {
    return ::rcBuildHeightfieldLayers(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcCompactHeightfield*>(chf), borderSize, walkableHeight,
        *reinterpret_cast<::rcHeightfieldLayerSet*>(lset)) ? 1 : 0;
}

RECAST_C_API int C_rcBuildContours(rcContextHandle ctx, rcCompactHeightfieldHandle chf,
    float maxError, int maxEdgeLen, rcContourSetHandle cset, int buildFlags) {
    return ::rcBuildContours(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcCompactHeightfield*>(chf), maxError, maxEdgeLen,
        *reinterpret_cast<::rcContourSet*>(cset), buildFlags) ? 1 : 0;
}

RECAST_C_API int C_rcBuildPolyMesh(rcContextHandle ctx, rcContourSetHandle cset, int nvp, rcPolyMeshHandle mesh) {
    return ::rcBuildPolyMesh(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcContourSet*>(cset), nvp, *reinterpret_cast<::rcPolyMesh*>(mesh)) ? 1 : 0;
}

RECAST_C_API int C_rcMergePolyMeshes(rcContextHandle ctx, rcPolyMeshHandle* meshes, int nmeshes, rcPolyMeshHandle mesh) {
    return ::rcMergePolyMeshes(reinterpret_cast<rcContext*>(ctx),
        reinterpret_cast<::rcPolyMesh**>(meshes), nmeshes, *reinterpret_cast<::rcPolyMesh*>(mesh)) ? 1 : 0;
}

RECAST_C_API int C_rcBuildPolyMeshDetail(rcContextHandle ctx, rcPolyMeshHandle mesh, rcCompactHeightfieldHandle chf,
    float sampleDist, float sampleMaxError, rcPolyMeshDetailHandle dmesh) {
    return ::rcBuildPolyMeshDetail(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcPolyMesh*>(mesh), *reinterpret_cast<::rcCompactHeightfield*>(chf),
        sampleDist, sampleMaxError, *reinterpret_cast<::rcPolyMeshDetail*>(dmesh)) ? 1 : 0;
}

RECAST_C_API int C_rcCopyPolyMesh(rcContextHandle ctx, rcPolyMeshHandle src, rcPolyMeshHandle dst) {
    return ::rcCopyPolyMesh(reinterpret_cast<rcContext*>(ctx),
        *reinterpret_cast<::rcPolyMesh*>(src), *reinterpret_cast<::rcPolyMesh*>(dst)) ? 1 : 0;
}

RECAST_C_API int C_rcMergePolyMeshDetails(rcContextHandle ctx, rcPolyMeshDetailHandle* meshes, int nmeshes, rcPolyMeshDetailHandle mesh) {
    return ::rcMergePolyMeshDetails(reinterpret_cast<rcContext*>(ctx),
        reinterpret_cast<::rcPolyMeshDetail**>(meshes), nmeshes, *reinterpret_cast<::rcPolyMeshDetail*>(mesh)) ? 1 : 0;
}

/* Math utilities */
RECAST_C_API float C_rcSqrt(float x) {
    return ::rcSqrt(x);
}

} /* extern "C" */
