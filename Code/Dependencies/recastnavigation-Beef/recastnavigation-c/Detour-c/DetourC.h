/*
 * Detour C API
 * C interface for the Detour navigation mesh library
 */

#ifndef DETOUR_C_H
#define DETOUR_C_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) && !defined(DETOUR_C_STATIC)
    #ifdef DETOUR_C_EXPORTS
        #define DETOUR_C_API __declspec(dllexport)
    #else
        #define DETOUR_C_API __declspec(dllimport)
    #endif
#else
    #define DETOUR_C_API
#endif

/* Types */
typedef unsigned int C_dtStatus;
typedef unsigned int C_dtPolyRef;
typedef unsigned int C_dtTileRef;

/* Constants */
#define C_DT_VERTS_PER_POLYGON 6
#define C_DT_NAVMESH_MAGIC ('D'<<24 | 'N'<<16 | 'A'<<8 | 'V')
#define C_DT_NAVMESH_VERSION 7
#define C_DT_NAVMESH_STATE_MAGIC ('D'<<24 | 'N'<<16 | 'M'<<8 | 'S')
#define C_DT_NAVMESH_STATE_VERSION 1
#define C_DT_EXT_LINK 0x8000
#define C_DT_NULL_LINK 0xffffffff
#define C_DT_OFFMESH_CON_BIDIR 1
#define C_DT_MAX_AREAS 64

/* Status flags */
#define C_DT_FAILURE (1u << 31)
#define C_DT_SUCCESS (1u << 30)
#define C_DT_IN_PROGRESS (1u << 29)
#define C_DT_STATUS_DETAIL_MASK 0x0ffffff
#define C_DT_WRONG_MAGIC (1 << 0)
#define C_DT_WRONG_VERSION (1 << 1)
#define C_DT_OUT_OF_MEMORY (1 << 2)
#define C_DT_INVALID_PARAM (1 << 3)
#define C_DT_BUFFER_TOO_SMALL (1 << 4)
#define C_DT_OUT_OF_NODES (1 << 5)
#define C_DT_PARTIAL_RESULT (1 << 6)
#define C_DT_ALREADY_OCCUPIED (1 << 7)

/* Tile flags */
typedef enum C_dtTileFlags {
    C_DT_TILE_FREE_DATA = 0x01
} C_dtTileFlags;

/* Straight path flags */
typedef enum C_dtStraightPathFlags {
    C_DT_STRAIGHTPATH_START = 0x01,
    C_DT_STRAIGHTPATH_END = 0x02,
    C_DT_STRAIGHTPATH_OFFMESH_CONNECTION = 0x04
} C_dtStraightPathFlags;

/* Straight path options */
typedef enum C_dtStraightPathOptions {
    C_DT_STRAIGHTPATH_AREA_CROSSINGS = 0x01,
    C_DT_STRAIGHTPATH_ALL_CROSSINGS = 0x02
} C_dtStraightPathOptions;

/* Find path options */
typedef enum C_dtFindPathOptions {
    C_DT_FINDPATH_ANY_ANGLE = 0x02
} C_dtFindPathOptions;

/* Raycast options */
typedef enum C_dtRaycastOptions {
    C_DT_RAYCAST_USE_COSTS = 0x01
} C_dtRaycastOptions;

/* Poly types */
typedef enum C_dtPolyTypes {
    C_DT_POLYTYPE_GROUND = 0,
    C_DT_POLYTYPE_OFFMESH_CONNECTION = 1
} C_dtPolyTypes;

/* Allocation hints */
typedef enum C_dtAllocHint {
    C_DT_ALLOC_PERM,
    C_DT_ALLOC_TEMP
} C_dtAllocHint;

/* Opaque handles */
typedef struct dtNavMesh_s* dtNavMeshHandle;
typedef struct dtNavMeshQuery_s* dtNavMeshQueryHandle;
typedef struct dtQueryFilter_s* dtQueryFilterHandle;

/* Polygon structure */
typedef struct C_dtPoly {
    unsigned int firstLink;
    unsigned short verts[C_DT_VERTS_PER_POLYGON];
    unsigned short neis[C_DT_VERTS_PER_POLYGON];
    unsigned short flags;
    unsigned char vertCount;
    unsigned char areaAndtype;
} C_dtPoly;

/* Poly detail structure */
typedef struct C_dtPolyDetail {
    unsigned int vertBase;
    unsigned int triBase;
    unsigned char vertCount;
    unsigned char triCount;
} C_dtPolyDetail;

/* Link structure */
typedef struct C_dtLink {
    C_dtPolyRef ref;
    unsigned int next;
    unsigned char edge;
    unsigned char side;
    unsigned char bmin;
    unsigned char bmax;
} C_dtLink;

/* BV Node */
typedef struct C_dtBVNode {
    unsigned short bmin[3];
    unsigned short bmax[3];
    int i;
} C_dtBVNode;

/* Off-mesh connection */
typedef struct C_dtOffMeshConnection {
    float pos[6];
    float rad;
    unsigned short poly;
    unsigned char flags;
    unsigned char side;
    unsigned int userId;
} C_dtOffMeshConnection;

/* Mesh header */
typedef struct C_dtMeshHeader {
    int magic;
    int version;
    int x;
    int y;
    int layer;
    unsigned int userId;
    int polyCount;
    int vertCount;
    int maxLinkCount;
    int detailMeshCount;
    int detailVertCount;
    int detailTriCount;
    int bvNodeCount;
    int offMeshConCount;
    int offMeshBase;
    float walkableHeight;
    float walkableRadius;
    float walkableClimb;
    float bmin[3];
    float bmax[3];
    float bvQuantFactor;
} C_dtMeshHeader;

/* Mesh tile */
typedef struct C_dtMeshTile {
    unsigned int salt;
    unsigned int linksFreeList;
    C_dtMeshHeader* header;
    C_dtPoly* polys;
    float* verts;
    C_dtLink* links;
    C_dtPolyDetail* detailMeshes;
    float* detailVerts;
    unsigned char* detailTris;
    C_dtBVNode* bvTree;
    C_dtOffMeshConnection* offMeshCons;
    unsigned char* data;
    int dataSize;
    int flags;
    struct C_dtMeshTile* next;
} C_dtMeshTile;

/* Nav mesh params */
typedef struct C_dtNavMeshParams {
    float orig[3];
    float tileWidth;
    float tileHeight;
    int maxTiles;
    int maxPolys;
} C_dtNavMeshParams;

/* Nav mesh create params */
typedef struct C_dtNavMeshCreateParams {
    const unsigned short* verts;
    int vertCount;
    const unsigned short* polys;
    const unsigned short* polyFlags;
    const unsigned char* polyAreas;
    int polyCount;
    int nvp;
    const unsigned int* detailMeshes;
    const float* detailVerts;
    int detailVertsCount;
    const unsigned char* detailTris;
    int detailTriCount;
    const float* offMeshConVerts;
    const float* offMeshConRad;
    const unsigned short* offMeshConFlags;
    const unsigned char* offMeshConAreas;
    const unsigned char* offMeshConDir;
    const unsigned int* offMeshConUserID;
    int offMeshConCount;
    unsigned int userId;
    int tileX;
    int tileY;
    int tileLayer;
    float bmin[3];
    float bmax[3];
    float walkableHeight;
    float walkableRadius;
    float walkableClimb;
    float cs;
    float ch;
    int buildBvTree;
} C_dtNavMeshCreateParams;

/* Raycast hit */
typedef struct C_dtRaycastHit {
    float t;
    float hitNormal[3];
    int hitEdgeIndex;
    C_dtPolyRef* path;
    int pathCount;
    int maxPath;
    float pathCost;
} C_dtRaycastHit;

/* Allocator function types */
typedef void* (*C_dtAllocFunc)(size_t size, C_dtAllocHint hint);
typedef void (*C_dtFreeFunc)(void* ptr);

/* Memory allocation */
DETOUR_C_API void C_dtAllocSetCustom(C_dtAllocFunc allocFunc, C_dtFreeFunc freeFunc);
DETOUR_C_API void* C_dtAlloc(size_t size, C_dtAllocHint hint);
DETOUR_C_API void C_dtFree(void* ptr);

/* Status helpers */
DETOUR_C_API int C_dtStatusSucceed(C_dtStatus status);
DETOUR_C_API int C_dtStatusFailed(C_dtStatus status);
DETOUR_C_API int C_dtStatusInProgress(C_dtStatus status);
DETOUR_C_API int C_dtStatusDetail(C_dtStatus status, unsigned int detail);

/* Nav mesh creation/destruction */
DETOUR_C_API dtNavMeshHandle C_dtAllocNavMesh(void);
DETOUR_C_API void C_dtFreeNavMesh(dtNavMeshHandle navmesh);

/* Nav mesh initialization */
DETOUR_C_API C_dtStatus C_dtNavMeshInit(dtNavMeshHandle navmesh, const C_dtNavMeshParams* params);
DETOUR_C_API C_dtStatus C_dtNavMeshInitSingle(dtNavMeshHandle navmesh, unsigned char* data, int dataSize, int flags);

/* Nav mesh params */
DETOUR_C_API const C_dtNavMeshParams* C_dtNavMeshGetParams(dtNavMeshHandle navmesh);

/* Tile management */
DETOUR_C_API C_dtStatus C_dtNavMeshAddTile(dtNavMeshHandle navmesh, unsigned char* data, int dataSize,
    int flags, C_dtTileRef lastRef, C_dtTileRef* result);
DETOUR_C_API C_dtStatus C_dtNavMeshRemoveTile(dtNavMeshHandle navmesh, C_dtTileRef ref,
    unsigned char** data, int* dataSize);

/* Tile queries */
DETOUR_C_API void C_dtNavMeshCalcTileLoc(dtNavMeshHandle navmesh, const float* pos, int* tx, int* ty);
DETOUR_C_API const C_dtMeshTile* C_dtNavMeshGetTileAt(dtNavMeshHandle navmesh, int x, int y, int layer);
DETOUR_C_API int C_dtNavMeshGetTilesAt(dtNavMeshHandle navmesh, int x, int y, const C_dtMeshTile** tiles, int maxTiles);
DETOUR_C_API C_dtTileRef C_dtNavMeshGetTileRefAt(dtNavMeshHandle navmesh, int x, int y, int layer);
DETOUR_C_API C_dtTileRef C_dtNavMeshGetTileRef(dtNavMeshHandle navmesh, const C_dtMeshTile* tile);
DETOUR_C_API const C_dtMeshTile* C_dtNavMeshGetTileByRef(dtNavMeshHandle navmesh, C_dtTileRef ref);
DETOUR_C_API int C_dtNavMeshGetMaxTiles(dtNavMeshHandle navmesh);
DETOUR_C_API const C_dtMeshTile* C_dtNavMeshGetTile(dtNavMeshHandle navmesh, int i);

/* Polygon queries */
DETOUR_C_API C_dtStatus C_dtNavMeshGetTileAndPolyByRef(dtNavMeshHandle navmesh, C_dtPolyRef ref,
    const C_dtMeshTile** tile, const C_dtPoly** poly);
DETOUR_C_API void C_dtNavMeshGetTileAndPolyByRefUnsafe(dtNavMeshHandle navmesh, C_dtPolyRef ref,
    const C_dtMeshTile** tile, const C_dtPoly** poly);
DETOUR_C_API int C_dtNavMeshIsValidPolyRef(dtNavMeshHandle navmesh, C_dtPolyRef ref);
DETOUR_C_API C_dtPolyRef C_dtNavMeshGetPolyRefBase(dtNavMeshHandle navmesh, const C_dtMeshTile* tile);

/* Off-mesh connections */
DETOUR_C_API C_dtStatus C_dtNavMeshGetOffMeshConnectionPolyEndPoints(dtNavMeshHandle navmesh,
    C_dtPolyRef prevRef, C_dtPolyRef polyRef, float* startPos, float* endPos);
DETOUR_C_API const C_dtOffMeshConnection* C_dtNavMeshGetOffMeshConnectionByRef(dtNavMeshHandle navmesh, C_dtPolyRef ref);

/* Polygon state */
DETOUR_C_API C_dtStatus C_dtNavMeshSetPolyFlags(dtNavMeshHandle navmesh, C_dtPolyRef ref, unsigned short flags);
DETOUR_C_API C_dtStatus C_dtNavMeshGetPolyFlags(dtNavMeshHandle navmesh, C_dtPolyRef ref, unsigned short* resultFlags);
DETOUR_C_API C_dtStatus C_dtNavMeshSetPolyArea(dtNavMeshHandle navmesh, C_dtPolyRef ref, unsigned char area);
DETOUR_C_API C_dtStatus C_dtNavMeshGetPolyArea(dtNavMeshHandle navmesh, C_dtPolyRef ref, unsigned char* resultArea);

/* Tile state */
DETOUR_C_API int C_dtNavMeshGetTileStateSize(dtNavMeshHandle navmesh, const C_dtMeshTile* tile);
DETOUR_C_API C_dtStatus C_dtNavMeshStoreTileState(dtNavMeshHandle navmesh, const C_dtMeshTile* tile,
    unsigned char* data, int maxDataSize);
DETOUR_C_API C_dtStatus C_dtNavMeshRestoreTileState(dtNavMeshHandle navmesh, C_dtMeshTile* tile,
    const unsigned char* data, int maxDataSize);

/* Nav mesh data building */
DETOUR_C_API int C_dtCreateNavMeshData(C_dtNavMeshCreateParams* params, unsigned char** outData, int* outDataSize);
DETOUR_C_API int C_dtNavMeshHeaderSwapEndian(unsigned char* data, int dataSize);
DETOUR_C_API int C_dtNavMeshDataSwapEndian(unsigned char* data, int dataSize);

/* Query filter */
DETOUR_C_API dtQueryFilterHandle C_dtAllocQueryFilter(void);
DETOUR_C_API void C_dtFreeQueryFilter(dtQueryFilterHandle filter);
DETOUR_C_API float C_dtQueryFilterGetAreaCost(dtQueryFilterHandle filter, int i);
DETOUR_C_API void C_dtQueryFilterSetAreaCost(dtQueryFilterHandle filter, int i, float cost);
DETOUR_C_API unsigned short C_dtQueryFilterGetIncludeFlags(dtQueryFilterHandle filter);
DETOUR_C_API void C_dtQueryFilterSetIncludeFlags(dtQueryFilterHandle filter, unsigned short flags);
DETOUR_C_API unsigned short C_dtQueryFilterGetExcludeFlags(dtQueryFilterHandle filter);
DETOUR_C_API void C_dtQueryFilterSetExcludeFlags(dtQueryFilterHandle filter, unsigned short flags);

/* Nav mesh query creation/destruction */
DETOUR_C_API dtNavMeshQueryHandle C_dtAllocNavMeshQuery(void);
DETOUR_C_API void C_dtFreeNavMeshQuery(dtNavMeshQueryHandle query);

/* Query initialization */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryInit(dtNavMeshQueryHandle query, dtNavMeshHandle nav, int maxNodes);

/* Standard pathfinding */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindPath(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, C_dtPolyRef endRef, const float* startPos, const float* endPos,
    dtQueryFilterHandle filter, C_dtPolyRef* path, int* pathCount, int maxPath);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindStraightPath(dtNavMeshQueryHandle query,
    const float* startPos, const float* endPos, const C_dtPolyRef* path, int pathSize,
    float* straightPath, unsigned char* straightPathFlags, C_dtPolyRef* straightPathRefs,
    int* straightPathCount, int maxStraightPath, int options);

/* Sliced pathfinding */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryInitSlicedFindPath(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, C_dtPolyRef endRef, const float* startPos, const float* endPos,
    dtQueryFilterHandle filter, unsigned int options);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryUpdateSlicedFindPath(dtNavMeshQueryHandle query,
    int maxIter, int* doneIters);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFinalizeSlicedFindPath(dtNavMeshQueryHandle query,
    C_dtPolyRef* path, int* pathCount, int maxPath);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFinalizeSlicedFindPathPartial(dtNavMeshQueryHandle query,
    const C_dtPolyRef* existing, int existingSize, C_dtPolyRef* path, int* pathCount, int maxPath);

/* Dijkstra search */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindPolysAroundCircle(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* centerPos, float radius, dtQueryFilterHandle filter,
    C_dtPolyRef* resultRef, C_dtPolyRef* resultParent, float* resultCost, int* resultCount, int maxResult);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindPolysAroundShape(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* verts, int nverts, dtQueryFilterHandle filter,
    C_dtPolyRef* resultRef, C_dtPolyRef* resultParent, float* resultCost, int* resultCount, int maxResult);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryGetPathFromDijkstraSearch(dtNavMeshQueryHandle query,
    C_dtPolyRef endRef, C_dtPolyRef* path, int* pathCount, int maxPath);

/* Local queries */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindNearestPoly(dtNavMeshQueryHandle query,
    const float* center, const float* halfExtents, dtQueryFilterHandle filter,
    C_dtPolyRef* nearestRef, float* nearestPt);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindNearestPolyEx(dtNavMeshQueryHandle query,
    const float* center, const float* halfExtents, dtQueryFilterHandle filter,
    C_dtPolyRef* nearestRef, float* nearestPt, int* isOverPoly);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryQueryPolygons(dtNavMeshQueryHandle query,
    const float* center, const float* halfExtents, dtQueryFilterHandle filter,
    C_dtPolyRef* polys, int* polyCount, int maxPolys);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindLocalNeighbourhood(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* centerPos, float radius, dtQueryFilterHandle filter,
    C_dtPolyRef* resultRef, C_dtPolyRef* resultParent, int* resultCount, int maxResult);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryMoveAlongSurface(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* startPos, const float* endPos, dtQueryFilterHandle filter,
    float* resultPos, C_dtPolyRef* visited, int* visitedCount, int maxVisitedSize);

/* Raycast */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryRaycast(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* startPos, const float* endPos, dtQueryFilterHandle filter,
    float* t, float* hitNormal, C_dtPolyRef* path, int* pathCount, int maxPath);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryRaycastEx(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* startPos, const float* endPos, dtQueryFilterHandle filter,
    unsigned int options, C_dtRaycastHit* hit, C_dtPolyRef prevRef);

/* Distance queries */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindDistanceToWall(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* centerPos, float maxRadius, dtQueryFilterHandle filter,
    float* hitDist, float* hitPos, float* hitNormal);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryGetPolyWallSegments(dtNavMeshQueryHandle query,
    C_dtPolyRef ref, dtQueryFilterHandle filter, float* segmentVerts, C_dtPolyRef* segmentRefs,
    int* segmentCount, int maxSegments);

/* Random point */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindRandomPoint(dtNavMeshQueryHandle query,
    dtQueryFilterHandle filter, float (*frand)(void), C_dtPolyRef* randomRef, float* randomPt);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryFindRandomPointAroundCircle(dtNavMeshQueryHandle query,
    C_dtPolyRef startRef, const float* centerPos, float maxRadius, dtQueryFilterHandle filter,
    float (*frand)(void), C_dtPolyRef* randomRef, float* randomPt);

/* Point queries */
DETOUR_C_API C_dtStatus C_dtNavMeshQueryClosestPointOnPoly(dtNavMeshQueryHandle query,
    C_dtPolyRef ref, const float* pos, float* closest, int* posOverPoly);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryClosestPointOnPolyBoundary(dtNavMeshQueryHandle query,
    C_dtPolyRef ref, const float* pos, float* closest);

DETOUR_C_API C_dtStatus C_dtNavMeshQueryGetPolyHeight(dtNavMeshQueryHandle query,
    C_dtPolyRef ref, const float* pos, float* height);

/* Validation */
DETOUR_C_API int C_dtNavMeshQueryIsValidPolyRef(dtNavMeshQueryHandle query,
    C_dtPolyRef ref, dtQueryFilterHandle filter);

DETOUR_C_API int C_dtNavMeshQueryIsInClosedList(dtNavMeshQueryHandle query, C_dtPolyRef ref);

DETOUR_C_API dtNavMeshHandle C_dtNavMeshQueryGetAttachedNavMesh(dtNavMeshQueryHandle query);

/* Poly helpers */
DETOUR_C_API void C_dtPolySetArea(C_dtPoly* poly, unsigned char area);
DETOUR_C_API void C_dtPolySetType(C_dtPoly* poly, unsigned char type);
DETOUR_C_API unsigned char C_dtPolyGetArea(const C_dtPoly* poly);
DETOUR_C_API unsigned char C_dtPolyGetType(const C_dtPoly* poly);

/* Detail tri edge flags */
DETOUR_C_API int C_dtGetDetailTriEdgeFlags(unsigned char triFlags, int edgeIndex);

#ifdef __cplusplus
}
#endif

#endif /* DETOUR_C_H */
