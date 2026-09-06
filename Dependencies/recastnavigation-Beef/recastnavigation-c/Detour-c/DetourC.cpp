/*
 * Detour C API Implementation
 */

#include "DetourC.h"
#include "DetourNavMesh.h"
#include "DetourNavMeshQuery.h"
#include "DetourNavMeshBuilder.h"
#include "DetourAlloc.h"
#include <string.h>

/* Static storage for custom allocator callbacks */
static C_dtAllocFunc s_dtAllocFunc = nullptr;
static C_dtFreeFunc s_dtFreeFunc = nullptr;

/* Wrapper functions to convert between C and C++ callback types */
static void* dtAllocWrapper(size_t size, dtAllocHint hint) {
    return s_dtAllocFunc(size, (C_dtAllocHint)hint);
}

static void dtFreeWrapper(void* ptr) {
    s_dtFreeFunc(ptr);
}

extern "C" {

/* Memory allocation */
DETOUR_C_API void C_dtAllocSetCustom(C_dtAllocFunc allocFunc, C_dtFreeFunc freeFunc) {
    s_dtAllocFunc = allocFunc;
    s_dtFreeFunc = freeFunc;
    if (allocFunc && freeFunc) {
        ::dtAllocSetCustom(dtAllocWrapper, dtFreeWrapper);
    } else {
        ::dtAllocSetCustom(nullptr, nullptr);
    }
}

DETOUR_C_API void* C_dtAlloc(size_t size, C_dtAllocHint hint) {
    return ::dtAlloc(size, (::dtAllocHint)hint);
}

DETOUR_C_API void C_dtFree(void* ptr) {
    ::dtFree(ptr);
}

/* Status helpers */
DETOUR_C_API int C_dtStatusSucceed(C_dtStatus status) {
    return ::dtStatusSucceed(status) ? 1 : 0;
}

DETOUR_C_API int C_dtStatusFailed(C_dtStatus status) {
    return ::dtStatusFailed(status) ? 1 : 0;
}

DETOUR_C_API int C_dtStatusInProgress(C_dtStatus status) {
    return ::dtStatusInProgress(status) ? 1 : 0;
}

DETOUR_C_API int C_dtStatusDetail(C_dtStatus status, unsigned int detail) {
    return ::dtStatusDetail(status, detail) ? 1 : 0;
}

/* Nav mesh creation/destruction */
DETOUR_C_API dtNavMeshHandle C_dtAllocNavMesh(void) {
    return reinterpret_cast<dtNavMeshHandle>(::dtAllocNavMesh());
}

DETOUR_C_API void C_dtFreeNavMesh(dtNavMeshHandle navmesh) {
    ::dtFreeNavMesh(reinterpret_cast<::dtNavMesh*>(navmesh));
}

/* Nav mesh initialization */
DETOUR_C_API C_dtStatus C_dtNavMeshInit(dtNavMeshHandle navmesh, const C_dtNavMeshParams* params) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->init(reinterpret_cast<const ::dtNavMeshParams*>(params));
}

DETOUR_C_API C_dtStatus C_dtNavMeshInitSingle(dtNavMeshHandle navmesh, unsigned char* data, int dataSize, int flags) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->init(data, dataSize, flags);
}

/* Nav mesh params */
DETOUR_C_API const C_dtNavMeshParams* C_dtNavMeshGetParams(dtNavMeshHandle navmesh) {
    return reinterpret_cast<const C_dtNavMeshParams*>(reinterpret_cast<::dtNavMesh*>(navmesh)->getParams());
}

/* Tile management */
DETOUR_C_API C_dtStatus C_dtNavMeshAddTile(dtNavMeshHandle navmesh, unsigned char* data, int dataSize,
    int flags, C_dtTileRef lastRef, C_dtTileRef* result) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->addTile(data, dataSize, flags, lastRef, result);
}

DETOUR_C_API C_dtStatus C_dtNavMeshRemoveTile(dtNavMeshHandle navmesh, C_dtTileRef ref,
    unsigned char** data, int* dataSize) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->removeTile(ref, data, dataSize);
}

/* Tile queries */
DETOUR_C_API void C_dtNavMeshCalcTileLoc(dtNavMeshHandle navmesh, const float* pos, int* tx, int* ty) {
    reinterpret_cast<::dtNavMesh*>(navmesh)->calcTileLoc(pos, tx, ty);
}

DETOUR_C_API const C_dtMeshTile* C_dtNavMeshGetTileAt(dtNavMeshHandle navmesh, int x, int y, int layer) {
    return reinterpret_cast<const C_dtMeshTile*>(reinterpret_cast<::dtNavMesh*>(navmesh)->getTileAt(x, y, layer));
}

DETOUR_C_API int C_dtNavMeshGetTilesAt(dtNavMeshHandle navmesh, int x, int y, const C_dtMeshTile** tiles, int maxTiles) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->getTilesAt(x, y,
        reinterpret_cast<::dtMeshTile const**>(tiles), maxTiles);
}

DETOUR_C_API C_dtTileRef C_dtNavMeshGetTileRefAt(dtNavMeshHandle navmesh, int x, int y, int layer) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->getTileRefAt(x, y, layer);
}

DETOUR_C_API C_dtTileRef C_dtNavMeshGetTileRef(dtNavMeshHandle navmesh, const C_dtMeshTile* tile) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->getTileRef(reinterpret_cast<const ::dtMeshTile*>(tile));
}

DETOUR_C_API const C_dtMeshTile* C_dtNavMeshGetTileByRef(dtNavMeshHandle navmesh, C_dtTileRef ref) {
    return reinterpret_cast<const C_dtMeshTile*>(reinterpret_cast<::dtNavMesh*>(navmesh)->getTileByRef(ref));
}

DETOUR_C_API int C_dtNavMeshGetMaxTiles(dtNavMeshHandle navmesh) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->getMaxTiles();
}

DETOUR_C_API const C_dtMeshTile* C_dtNavMeshGetTile(dtNavMeshHandle navmesh, int i) {
    return reinterpret_cast<const C_dtMeshTile*>(reinterpret_cast<const ::dtNavMesh*>(navmesh)->getTile(i));
}

/* Polygon queries */
DETOUR_C_API C_dtStatus C_dtNavMeshGetTileAndPolyByRef(dtNavMeshHandle navmesh, C_dtPolyRef ref,
    const C_dtMeshTile** tile, const C_dtPoly** poly) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->getTileAndPolyByRef(ref,
        reinterpret_cast<const ::dtMeshTile**>(tile), reinterpret_cast<const ::dtPoly**>(poly));
}

DETOUR_C_API void C_dtNavMeshGetTileAndPolyByRefUnsafe(dtNavMeshHandle navmesh, C_dtPolyRef ref,
    const C_dtMeshTile** tile, const C_dtPoly** poly) {
    reinterpret_cast<::dtNavMesh*>(navmesh)->getTileAndPolyByRefUnsafe(ref,
        reinterpret_cast<const ::dtMeshTile**>(tile), reinterpret_cast<const ::dtPoly**>(poly));
}

DETOUR_C_API int C_dtNavMeshIsValidPolyRef(dtNavMeshHandle navmesh, C_dtPolyRef ref) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->isValidPolyRef(ref) ? 1 : 0;
}

DETOUR_C_API C_dtPolyRef C_dtNavMeshGetPolyRefBase(dtNavMeshHandle navmesh, const C_dtMeshTile* tile) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->getPolyRefBase(reinterpret_cast<const ::dtMeshTile*>(tile));
}

/* Off-mesh connections */
DETOUR_C_API C_dtStatus C_dtNavMeshGetOffMeshConnectionPolyEndPoints(dtNavMeshHandle navmesh,
    C_dtPolyRef prevRef, C_dtPolyRef polyRef, float* startPos, float* endPos) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->getOffMeshConnectionPolyEndPoints(prevRef, polyRef, startPos, endPos);
}

DETOUR_C_API const C_dtOffMeshConnection* C_dtNavMeshGetOffMeshConnectionByRef(dtNavMeshHandle navmesh, C_dtPolyRef ref) {
    return reinterpret_cast<const C_dtOffMeshConnection*>(
        reinterpret_cast<::dtNavMesh*>(navmesh)->getOffMeshConnectionByRef(ref));
}

/* Polygon state */
DETOUR_C_API C_dtStatus C_dtNavMeshSetPolyFlags(dtNavMeshHandle navmesh, C_dtPolyRef ref, unsigned short flags) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->setPolyFlags(ref, flags);
}

DETOUR_C_API C_dtStatus C_dtNavMeshGetPolyFlags(dtNavMeshHandle navmesh, C_dtPolyRef ref, unsigned short* resultFlags) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->getPolyFlags(ref, resultFlags);
}

DETOUR_C_API C_dtStatus C_dtNavMeshSetPolyArea(dtNavMeshHandle navmesh, C_dtPolyRef ref, unsigned char area) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->setPolyArea(ref, area);
}

DETOUR_C_API C_dtStatus C_dtNavMeshGetPolyArea(dtNavMeshHandle navmesh, C_dtPolyRef ref, unsigned char* resultArea) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->getPolyArea(ref, resultArea);
}

/* Tile state */
DETOUR_C_API int C_dtNavMeshGetTileStateSize(dtNavMeshHandle navmesh, const C_dtMeshTile* tile) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->getTileStateSize(reinterpret_cast<const ::dtMeshTile*>(tile));
}

DETOUR_C_API C_dtStatus C_dtNavMeshStoreTileState(dtNavMeshHandle navmesh, const C_dtMeshTile* tile,
    unsigned char* data, int maxDataSize) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->storeTileState(
        reinterpret_cast<const ::dtMeshTile*>(tile), data, maxDataSize);
}

DETOUR_C_API C_dtStatus C_dtNavMeshRestoreTileState(dtNavMeshHandle navmesh, C_dtMeshTile* tile,
    const unsigned char* data, int maxDataSize) {
    return reinterpret_cast<::dtNavMesh*>(navmesh)->restoreTileState(
        reinterpret_cast<::dtMeshTile*>(tile), data, maxDataSize);
}

/* Nav mesh data building */
DETOUR_C_API int C_dtCreateNavMeshData(C_dtNavMeshCreateParams* params, unsigned char** outData, int* outDataSize) {
    return ::dtCreateNavMeshData(reinterpret_cast<::dtNavMeshCreateParams*>(params), outData, outDataSize) ? 1 : 0;
}

DETOUR_C_API int C_dtNavMeshHeaderSwapEndian(unsigned char* data, int dataSize) {
    return ::dtNavMeshHeaderSwapEndian(data, dataSize) ? 1 : 0;
}

DETOUR_C_API int C_dtNavMeshDataSwapEndian(unsigned char* data, int dataSize) {
    return ::dtNavMeshDataSwapEndian(data, dataSize) ? 1 : 0;
}

/* Query filter */
DETOUR_C_API dtQueryFilterHandle C_dtAllocQueryFilter(void) {
    return reinterpret_cast<dtQueryFilterHandle>(new ::dtQueryFilter());
}

DETOUR_C_API void C_dtFreeQueryFilter(dtQueryFilterHandle filter) {
    delete reinterpret_cast<::dtQueryFilter*>(filter);
}

DETOUR_C_API float C_dtQueryFilterGetAreaCost(dtQueryFilterHandle filter, int i) {
    return reinterpret_cast<::dtQueryFilter*>(filter)->getAreaCost(i);
}

DETOUR_C_API void C_dtQueryFilterSetAreaCost(dtQueryFilterHandle filter, int i, float cost) {
    reinterpret_cast<::dtQueryFilter*>(filter)->setAreaCost(i, cost);
}

DETOUR_C_API unsigned short C_dtQueryFilterGetIncludeFlags(dtQueryFilterHandle filter) {
    return reinterpret_cast<::dtQueryFilter*>(filter)->getIncludeFlags();
}

DETOUR_C_API void C_dtQueryFilterSetIncludeFlags(dtQueryFilterHandle filter, unsigned short flags) {
    reinterpret_cast<::dtQueryFilter*>(filter)->setIncludeFlags(flags);
}

DETOUR_C_API unsigned short C_dtQueryFilterGetExcludeFlags(dtQueryFilterHandle filter) {
    return reinterpret_cast<::dtQueryFilter*>(filter)->getExcludeFlags();
}

DETOUR_C_API void C_dtQueryFilterSetExcludeFlags(dtQueryFilterHandle filter, unsigned short flags) {
    reinterpret_cast<::dtQueryFilter*>(filter)->setExcludeFlags(flags);
}

/* Nav mesh query creation/destruction */
DETOUR_C_API dtNavMeshQueryHandle C_dtAllocNavMeshQuery(void) {
    return reinterpret_cast<dtNavMeshQueryHandle>(::dtAllocNavMeshQuery());
}

DETOUR_C_API void C_dtFreeNavMeshQuery(dtNavMeshQueryHandle query) {
    ::dtFreeNavMeshQuery(reinterpret_cast<::dtNavMeshQuery*>(query));
}

/* Query initialization */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryInit(dtNavMeshQueryHandle query, dtNavMeshHandle nav, int maxNodes) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->init(
        reinterpret_cast<const ::dtNavMesh*>(nav), maxNodes);
}

/* Standard pathfinding */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindPath(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, C_dtPolyRef endRef, const float* startPos, const float* endPos,
    dtQueryFilterHandle filter, C_dtPolyRef* path, int* pathCount, int maxPath) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->findPath(
        startRef, endRef, startPos, endPos,
        reinterpret_cast<const ::dtQueryFilter*>(filter), path, pathCount, maxPath);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindStraightPath(dtNavMeshQueryHandle query,
    const float* startPos, const float* endPos, const C_dtPolyRef* path, int pathSize,
    float* straightPath, unsigned char* straightPathFlags, C_dtPolyRef* straightPathRefs,
    int* straightPathCount, int maxStraightPath, int options) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->findStraightPath(
        startPos, endPos, path, pathSize, straightPath, straightPathFlags,
        straightPathRefs, straightPathCount, maxStraightPath, options);
}

/* Sliced pathfinding */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryInitSlicedFindPath(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, C_dtPolyRef endRef, const float* startPos, const float* endPos,
    dtQueryFilterHandle filter, unsigned int options) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->initSlicedFindPath(
        startRef, endRef, startPos, endPos,
        reinterpret_cast<const ::dtQueryFilter*>(filter), options);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryUpdateSlicedFindPath(dtNavMeshQueryHandle query,
    int maxIter, int* doneIters) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->updateSlicedFindPath(maxIter, doneIters);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFinalizeSlicedFindPath(dtNavMeshQueryHandle query,
    C_dtPolyRef* path, int* pathCount, int maxPath) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->finalizeSlicedFindPath(path, pathCount, maxPath);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFinalizeSlicedFindPathPartial(dtNavMeshQueryHandle query,
    const C_dtPolyRef* existing, int existingSize, C_dtPolyRef* path, int* pathCount, int maxPath) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->finalizeSlicedFindPathPartial(
        existing, existingSize, path, pathCount, maxPath);
}

/* Dijkstra search */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindPolysAroundCircle(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* centerPos, float radius, dtQueryFilterHandle filter,
    C_dtPolyRef* resultRef, C_dtPolyRef* resultParent, float* resultCost, int* resultCount, int maxResult) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->findPolysAroundCircle(
        startRef, centerPos, radius, reinterpret_cast<const ::dtQueryFilter*>(filter),
        resultRef, resultParent, resultCost, resultCount, maxResult);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindPolysAroundShape(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* verts, int nverts, dtQueryFilterHandle filter,
    C_dtPolyRef* resultRef, C_dtPolyRef* resultParent, float* resultCost, int* resultCount, int maxResult) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->findPolysAroundShape(
        startRef, verts, nverts, reinterpret_cast<const ::dtQueryFilter*>(filter),
        resultRef, resultParent, resultCost, resultCount, maxResult);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryGetPathFromDijkstraSearch(dtNavMeshQueryHandle query,
    C_dtPolyRef endRef, C_dtPolyRef* path, int* pathCount, int maxPath) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->getPathFromDijkstraSearch(
        endRef, path, pathCount, maxPath);
}

/* Local queries */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindNearestPoly(dtNavMeshQueryHandle query,
    const float* center, const float* halfExtents, dtQueryFilterHandle filter,
    C_dtPolyRef* nearestRef, float* nearestPt) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->findNearestPoly(
        center, halfExtents, reinterpret_cast<const ::dtQueryFilter*>(filter),
        nearestRef, nearestPt);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindNearestPolyEx(dtNavMeshQueryHandle query,
    const float* center, const float* halfExtents, dtQueryFilterHandle filter,
    C_dtPolyRef* nearestRef, float* nearestPt, int* isOverPoly) {
    bool over = false;
    C_dtStatus status = reinterpret_cast<::dtNavMeshQuery*>(query)->findNearestPoly(
        center, halfExtents, reinterpret_cast<const ::dtQueryFilter*>(filter),
        nearestRef, nearestPt, &over);
    if (isOverPoly) *isOverPoly = over ? 1 : 0;
    return status;
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryQueryPolygons(dtNavMeshQueryHandle query,
    const float* center, const float* halfExtents, dtQueryFilterHandle filter,
    C_dtPolyRef* polys, int* polyCount, int maxPolys) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->queryPolygons(
        center, halfExtents, reinterpret_cast<const ::dtQueryFilter*>(filter),
        polys, polyCount, maxPolys);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindLocalNeighbourhood(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* centerPos, float radius, dtQueryFilterHandle filter,
    C_dtPolyRef* resultRef, C_dtPolyRef* resultParent, int* resultCount, int maxResult) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->findLocalNeighbourhood(
        startRef, centerPos, radius, reinterpret_cast<const ::dtQueryFilter*>(filter),
        resultRef, resultParent, resultCount, maxResult);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryMoveAlongSurface(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* startPos, const float* endPos, dtQueryFilterHandle filter,
    float* resultPos, C_dtPolyRef* visited, int* visitedCount, int maxVisitedSize) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->moveAlongSurface(
        startRef, startPos, endPos, reinterpret_cast<const ::dtQueryFilter*>(filter),
        resultPos, visited, visitedCount, maxVisitedSize);
}

/* Raycast */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryRaycast(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* startPos, const float* endPos, dtQueryFilterHandle filter,
    float* t, float* hitNormal, C_dtPolyRef* path, int* pathCount, int maxPath) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->raycast(
        startRef, startPos, endPos, reinterpret_cast<const ::dtQueryFilter*>(filter),
        t, hitNormal, path, pathCount, maxPath);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryRaycastEx(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* startPos, const float* endPos, dtQueryFilterHandle filter,
    unsigned int options, C_dtRaycastHit* hit, C_dtPolyRef prevRef) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->raycast(
        startRef, startPos, endPos, reinterpret_cast<const ::dtQueryFilter*>(filter),
        options, reinterpret_cast<::dtRaycastHit*>(hit), prevRef);
}

/* Distance queries */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindDistanceToWall(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* centerPos, float maxRadius, dtQueryFilterHandle filter,
    float* hitDist, float* hitPos, float* hitNormal) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->findDistanceToWall(
        startRef, centerPos, maxRadius, reinterpret_cast<const ::dtQueryFilter*>(filter),
        hitDist, hitPos, hitNormal);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryGetPolyWallSegments(dtNavMeshQueryHandle query,
    C_dtPolyRef ref, dtQueryFilterHandle filter, float* segmentVerts, C_dtPolyRef* segmentRefs,
    int* segmentCount, int maxSegments) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->getPolyWallSegments(
        ref, reinterpret_cast<const ::dtQueryFilter*>(filter),
        segmentVerts, segmentRefs, segmentCount, maxSegments);
}

/* Random point */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindRandomPoint(dtNavMeshQueryHandle query,
    dtQueryFilterHandle filter, float (*frand)(void), C_dtPolyRef* randomRef, float* randomPt) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->findRandomPoint(
        reinterpret_cast<const ::dtQueryFilter*>(filter), frand, randomRef, randomPt);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindRandomPointAroundCircle(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* centerPos, float maxRadius, dtQueryFilterHandle filter,
    float (*frand)(void), C_dtPolyRef* randomRef, float* randomPt) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->findRandomPointAroundCircle(
        startRef, centerPos, maxRadius, reinterpret_cast<const ::dtQueryFilter*>(filter),
        frand, randomRef, randomPt);
}

/* Point queries */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryClosestPointOnPoly(dtNavMeshQueryHandle query,
    C_dtPolyRef ref, const float* pos, float* closest, int* posOverPoly) {
    bool over = false;
    C_dtStatus status = reinterpret_cast<::dtNavMeshQuery*>(query)->closestPointOnPoly(
        ref, pos, closest, &over);
    if (posOverPoly) *posOverPoly = over ? 1 : 0;
    return status;
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryClosestPointOnPolyBoundary(dtNavMeshQueryHandle query,
    C_dtPolyRef ref, const float* pos, float* closest) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->closestPointOnPolyBoundary(ref, pos, closest);
}

DETOUR_C_API C_dtStatus C_dtNavMeshQueryGetPolyHeight(dtNavMeshQueryHandle query,
    C_dtPolyRef ref, const float* pos, float* height) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->getPolyHeight(ref, pos, height);
}

/* Validation */
DETOUR_C_API int C_dtNavMeshQueryIsValidPolyRef(dtNavMeshQueryHandle query,
    C_dtPolyRef ref, dtQueryFilterHandle filter) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->isValidPolyRef(
        ref, reinterpret_cast<const ::dtQueryFilter*>(filter)) ? 1 : 0;
}

DETOUR_C_API int C_dtNavMeshQueryIsInClosedList(dtNavMeshQueryHandle query, C_dtPolyRef ref) {
    return reinterpret_cast<::dtNavMeshQuery*>(query)->isInClosedList(ref) ? 1 : 0;
}

DETOUR_C_API dtNavMeshHandle C_dtNavMeshQueryGetAttachedNavMesh(dtNavMeshQueryHandle query) {
    return reinterpret_cast<dtNavMeshHandle>(
        const_cast<::dtNavMesh*>(reinterpret_cast<::dtNavMeshQuery*>(query)->getAttachedNavMesh()));
}

/* Poly helpers */
DETOUR_C_API void C_dtPolySetArea(C_dtPoly* poly, unsigned char area) {
    reinterpret_cast<::dtPoly*>(poly)->setArea(area);
}

DETOUR_C_API void C_dtPolySetType(C_dtPoly* poly, unsigned char type) {
    reinterpret_cast<::dtPoly*>(poly)->setType(type);
}

DETOUR_C_API unsigned char C_dtPolyGetArea(const C_dtPoly* poly) {
    return reinterpret_cast<const ::dtPoly*>(poly)->getArea();
}

DETOUR_C_API unsigned char C_dtPolyGetType(const C_dtPoly* poly) {
    return reinterpret_cast<const ::dtPoly*>(poly)->getType();
}

/* Detail tri edge flags */
DETOUR_C_API int C_dtGetDetailTriEdgeFlags(unsigned char triFlags, int edgeIndex) {
    return ::dtGetDetailTriEdgeFlags(triFlags, edgeIndex);
}

} /* extern "C" */
