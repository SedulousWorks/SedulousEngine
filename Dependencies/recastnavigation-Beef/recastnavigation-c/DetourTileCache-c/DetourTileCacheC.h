/*
 * DetourTileCache C API
 * C interface for the Detour tile cache library
 */

#ifndef DETOUR_TILECACHE_C_H
#define DETOUR_TILECACHE_C_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) && !defined(DETOURTILECACHE_C_STATIC)
    #ifdef DETOURTILECACHE_C_EXPORTS
        #define DETOURTILECACHE_C_API __declspec(dllexport)
    #else
        #define DETOURTILECACHE_C_API __declspec(dllimport)
    #endif
#else
    #define DETOURTILECACHE_C_API
#endif

/* Forward declarations from Detour */
typedef unsigned int C_dtStatus;
typedef struct dtNavMesh_s* dtNavMeshHandle;

/* Tile cache types */
typedef unsigned int C_dtObstacleRef;
typedef unsigned int C_dtCompressedTileRef;

/* Constants */
#define C_DT_TILECACHE_MAGIC ('D'<<24 | 'T'<<16 | 'L'<<8 | 'R')
#define C_DT_TILECACHE_VERSION 1
#define C_DT_TILECACHE_NULL_AREA 0
#define C_DT_TILECACHE_WALKABLE_AREA 63
#define C_DT_TILECACHE_NULL_IDX 0xffff
#define C_DT_MAX_TOUCHED_TILES 8

/* Tile flags */
typedef enum C_dtCompressedTileFlags {
    C_DT_COMPRESSEDTILE_FREE_DATA = 0x01
} C_dtCompressedTileFlags;

/* Obstacle states */
typedef enum C_ObstacleState {
    C_DT_OBSTACLE_EMPTY,
    C_DT_OBSTACLE_PROCESSING,
    C_DT_OBSTACLE_PROCESSED,
    C_DT_OBSTACLE_REMOVING
} C_ObstacleState;

/* Obstacle types */
typedef enum C_ObstacleType {
    C_DT_OBSTACLE_CYLINDER,
    C_DT_OBSTACLE_BOX,
    C_DT_OBSTACLE_ORIENTED_BOX
} C_ObstacleType;

/* Opaque handles */
typedef struct dtTileCache_s* dtTileCacheHandle;
typedef struct dtTileCacheAlloc_s* dtTileCacheAllocHandle;
typedef struct dtTileCacheCompressor_s* dtTileCacheCompressorHandle;
typedef struct dtTileCacheMeshProcess_s* dtTileCacheMeshProcessHandle;

/* Tile cache layer header */
typedef struct C_dtTileCacheLayerHeader {
    int magic;
    int version;
    int tx, ty, tlayer;
    float bmin[3];
    float bmax[3];
    unsigned short hmin, hmax;
    unsigned char width, height;
    unsigned char minx, maxx, miny, maxy;
} C_dtTileCacheLayerHeader;

/* Tile cache params */
typedef struct C_dtTileCacheParams {
    float orig[3];
    float cs, ch;
    int width, height;
    float walkableHeight;
    float walkableRadius;
    float walkableClimb;
    float maxSimplificationError;
    int maxTiles;
    int maxObstacles;
} C_dtTileCacheParams;

/* Obstacle cylinder */
typedef struct C_dtObstacleCylinder {
    float pos[3];
    float radius;
    float height;
} C_dtObstacleCylinder;

/* Obstacle box */
typedef struct C_dtObstacleBox {
    float bmin[3];
    float bmax[3];
} C_dtObstacleBox;

/* Obstacle oriented box */
typedef struct C_dtObstacleOrientedBox {
    float center[3];
    float halfExtents[3];
    float rotAux[2];
} C_dtObstacleOrientedBox;

/* Compressed tile (read-only info) */
typedef struct C_dtCompressedTileInfo {
    unsigned int salt;
    int compressedSize;
    int dataSize;
    unsigned int flags;
} C_dtCompressedTileInfo;

/* Obstacle info (read-only) */
typedef struct C_dtTileCacheObstacleInfo {
    unsigned char type;
    unsigned char state;
    C_dtObstacleCylinder cylinder;
    C_dtObstacleBox box;
    C_dtObstacleOrientedBox orientedBox;
} C_dtTileCacheObstacleInfo;

/* Callback function types for custom allocator/compressor/mesh process */
typedef void* (*C_dtTileCacheAllocFunc)(size_t size);
typedef void (*C_dtTileCacheFreeFunc)(void* ptr);
typedef int (*C_dtTileCacheMaxCompressedSizeFunc)(int bufferSize);
typedef C_dtStatus (*C_dtTileCacheCompressFunc)(const unsigned char* buffer, int bufferSize,
    unsigned char* compressed, int maxCompressedSize, int* compressedSize);
typedef C_dtStatus (*C_dtTileCacheDecompressFunc)(const unsigned char* compressed, int compressedSize,
    unsigned char* buffer, int maxBufferSize, int* bufferSize);
typedef void (*C_dtTileCacheMeshProcessFunc)(int polyCount, unsigned char* polyAreas, unsigned short* polyFlags);

/* Tile cache management */
DETOURTILECACHE_C_API dtTileCacheHandle C_dtAllocTileCache(void);
DETOURTILECACHE_C_API void C_dtFreeTileCache(dtTileCacheHandle tc);

/* Tile cache initialization */
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheInit(dtTileCacheHandle tc, const C_dtTileCacheParams* params,
    dtTileCacheAllocHandle alloc, dtTileCacheCompressorHandle comp, dtTileCacheMeshProcessHandle proc);

/* Params access */
DETOURTILECACHE_C_API const C_dtTileCacheParams* C_dtTileCacheGetParams(dtTileCacheHandle tc);

/* Tile management */
DETOURTILECACHE_C_API int C_dtTileCacheGetTileCount(dtTileCacheHandle tc);
DETOURTILECACHE_C_API int C_dtTileCacheGetTileInfo(dtTileCacheHandle tc, int i, C_dtCompressedTileInfo* info);
DETOURTILECACHE_C_API int C_dtTileCacheGetTilesAt(dtTileCacheHandle tc, int tx, int ty,
    C_dtCompressedTileRef* tiles, int maxTiles);
DETOURTILECACHE_C_API C_dtCompressedTileRef C_dtTileCacheGetTileRef(dtTileCacheHandle tc, int i);
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheAddTile(dtTileCacheHandle tc, unsigned char* data, int dataSize,
    unsigned char flags, C_dtCompressedTileRef* result);
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheRemoveTile(dtTileCacheHandle tc, C_dtCompressedTileRef ref,
    unsigned char** data, int* dataSize);

/* Obstacle management */
DETOURTILECACHE_C_API int C_dtTileCacheGetObstacleCount(dtTileCacheHandle tc);
DETOURTILECACHE_C_API int C_dtTileCacheGetObstacleInfo(dtTileCacheHandle tc, int i, C_dtTileCacheObstacleInfo* info);
DETOURTILECACHE_C_API C_dtObstacleRef C_dtTileCacheGetObstacleRef(dtTileCacheHandle tc, int i);
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheAddObstacle(dtTileCacheHandle tc, const float* pos,
    float radius, float height, C_dtObstacleRef* result);
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheAddBoxObstacle(dtTileCacheHandle tc, const float* bmin,
    const float* bmax, C_dtObstacleRef* result);
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheAddBoxObstacleOriented(dtTileCacheHandle tc, const float* center,
    const float* halfExtents, float yRadians, C_dtObstacleRef* result);
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheRemoveObstacle(dtTileCacheHandle tc, C_dtObstacleRef ref);

/* Queries */
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheQueryTiles(dtTileCacheHandle tc, const float* bmin, const float* bmax,
    C_dtCompressedTileRef* results, int* resultCount, int maxResults);

/* Update and building */
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheUpdate(dtTileCacheHandle tc, float dt, dtNavMeshHandle navmesh, int* upToDate);
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheBuildNavMeshTilesAt(dtTileCacheHandle tc, int tx, int ty, dtNavMeshHandle navmesh);
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheBuildNavMeshTile(dtTileCacheHandle tc, C_dtCompressedTileRef ref, dtNavMeshHandle navmesh);

/* Bounds calculation */
DETOURTILECACHE_C_API void C_dtTileCacheCalcTightTileBounds(dtTileCacheHandle tc,
    const C_dtTileCacheLayerHeader* header, float* bmin, float* bmax);
DETOURTILECACHE_C_API void C_dtTileCacheGetObstacleBounds(dtTileCacheHandle tc, int obstacleIdx, float* bmin, float* bmax);

/* Custom allocator creation */
DETOURTILECACHE_C_API dtTileCacheAllocHandle C_dtCreateTileCacheAlloc(
    C_dtTileCacheAllocFunc allocFunc, C_dtTileCacheFreeFunc freeFunc);
DETOURTILECACHE_C_API void C_dtDestroyTileCacheAlloc(dtTileCacheAllocHandle alloc);

/* Custom compressor creation */
DETOURTILECACHE_C_API dtTileCacheCompressorHandle C_dtCreateTileCacheCompressor(
    C_dtTileCacheMaxCompressedSizeFunc maxSizeFunc,
    C_dtTileCacheCompressFunc compressFunc,
    C_dtTileCacheDecompressFunc decompressFunc);
DETOURTILECACHE_C_API void C_dtDestroyTileCacheCompressor(dtTileCacheCompressorHandle comp);

/* Default allocator (uses dtAlloc/dtFree) */
DETOURTILECACHE_C_API dtTileCacheAllocHandle C_dtCreateDefaultTileCacheAlloc(void);

/* Default passthrough compressor (no compression, for simple use cases) */
DETOURTILECACHE_C_API dtTileCacheCompressorHandle C_dtCreateDefaultTileCacheCompressor(void);

/* Custom mesh process creation */
DETOURTILECACHE_C_API dtTileCacheMeshProcessHandle C_dtCreateTileCacheMeshProcess(
    C_dtTileCacheMeshProcessFunc processFunc);
DETOURTILECACHE_C_API void C_dtDestroyTileCacheMeshProcess(dtTileCacheMeshProcessHandle proc);

/* Default mesh process that sets all walkable polys to flag 1 */
DETOURTILECACHE_C_API dtTileCacheMeshProcessHandle C_dtCreateDefaultTileCacheMeshProcess(void);

/* Tile cache layer building */
DETOURTILECACHE_C_API C_dtStatus C_dtBuildTileCacheLayer(dtTileCacheCompressorHandle comp,
    C_dtTileCacheLayerHeader* header, const unsigned char* heights, const unsigned char* areas,
    const unsigned char* cons, unsigned char** outData, int* outDataSize);

/* Endian swap */
DETOURTILECACHE_C_API int C_dtTileCacheHeaderSwapEndian(unsigned char* data, int dataSize);

#ifdef __cplusplus
}
#endif

#endif /* DETOUR_TILECACHE_C_H */
