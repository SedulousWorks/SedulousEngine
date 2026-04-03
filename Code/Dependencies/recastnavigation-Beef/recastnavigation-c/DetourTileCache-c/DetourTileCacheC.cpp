/*
 * DetourTileCache C API Implementation
 */

#include "DetourTileCacheC.h"
#include "DetourTileCache.h"
#include "DetourTileCacheBuilder.h"
#include "DetourNavMesh.h"
#include "DetourNavMeshBuilder.h"
#include "DetourAlloc.h"
#include <string.h>

/* Custom allocator wrapper */
class dtTileCacheAllocC : public dtTileCacheAlloc {
    C_dtTileCacheAllocFunc m_allocFunc;
    C_dtTileCacheFreeFunc m_freeFunc;
public:
    dtTileCacheAllocC(C_dtTileCacheAllocFunc allocFunc, C_dtTileCacheFreeFunc freeFunc)
        : m_allocFunc(allocFunc), m_freeFunc(freeFunc) {}

    virtual void* alloc(const size_t size) {
        if (m_allocFunc) return m_allocFunc(size);
        return dtAlloc(size, DT_ALLOC_TEMP);
    }

    virtual void free(void* ptr) {
        if (m_freeFunc) m_freeFunc(ptr);
        else dtFree(ptr);
    }
};

/* Custom compressor wrapper */
class dtTileCacheCompressorC : public dtTileCacheCompressor {
    C_dtTileCacheMaxCompressedSizeFunc m_maxSizeFunc;
    C_dtTileCacheCompressFunc m_compressFunc;
    C_dtTileCacheDecompressFunc m_decompressFunc;
public:
    dtTileCacheCompressorC(C_dtTileCacheMaxCompressedSizeFunc maxSizeFunc,
                          C_dtTileCacheCompressFunc compressFunc,
                          C_dtTileCacheDecompressFunc decompressFunc)
        : m_maxSizeFunc(maxSizeFunc), m_compressFunc(compressFunc), m_decompressFunc(decompressFunc) {}

    virtual int maxCompressedSize(const int bufferSize) {
        return m_maxSizeFunc ? m_maxSizeFunc(bufferSize) : 0;
    }

    virtual dtStatus compress(const unsigned char* buffer, const int bufferSize,
                             unsigned char* compressed, const int maxCompressedSize, int* compressedSize) {
        if (m_compressFunc) return m_compressFunc(buffer, bufferSize, compressed, maxCompressedSize, compressedSize);
        return DT_FAILURE;
    }

    virtual dtStatus decompress(const unsigned char* compressed, const int compressedSize,
                               unsigned char* buffer, const int maxBufferSize, int* bufferSize) {
        if (m_decompressFunc) return m_decompressFunc(compressed, compressedSize, buffer, maxBufferSize, bufferSize);
        return DT_FAILURE;
    }
};

/* Default passthrough compressor (no compression) */
class dtTileCachePassthroughCompressor : public dtTileCacheCompressor {
public:
    virtual int maxCompressedSize(const int bufferSize) {
        return bufferSize;
    }

    virtual dtStatus compress(const unsigned char* buffer, const int bufferSize,
                             unsigned char* compressed, const int maxCompressedSize, int* compressedSize) {
        if (bufferSize > maxCompressedSize) return DT_FAILURE;
        memcpy(compressed, buffer, bufferSize);
        *compressedSize = bufferSize;
        return DT_SUCCESS;
    }

    virtual dtStatus decompress(const unsigned char* compressed, const int compressedSize,
                               unsigned char* buffer, const int maxBufferSize, int* bufferSize) {
        if (compressedSize > maxBufferSize) return DT_FAILURE;
        memcpy(buffer, compressed, compressedSize);
        *bufferSize = compressedSize;
        return DT_SUCCESS;
    }
};

/* Custom mesh process wrapper */
class dtTileCacheMeshProcessC : public dtTileCacheMeshProcess {
    C_dtTileCacheMeshProcessFunc m_processFunc;
public:
    dtTileCacheMeshProcessC(C_dtTileCacheMeshProcessFunc processFunc)
        : m_processFunc(processFunc) {}

    virtual void process(dtNavMeshCreateParams* params, unsigned char* polyAreas, unsigned short* polyFlags) {
        if (m_processFunc) {
            m_processFunc(params->polyCount, polyAreas, polyFlags);
        }
    }
};

/* Default mesh process that sets walkable polys to flag 1 */
class dtTileCacheDefaultMeshProcess : public dtTileCacheMeshProcess {
public:
    virtual void process(dtNavMeshCreateParams* params, unsigned char* polyAreas, unsigned short* polyFlags) {
        // Set all polygons to walkable (flag 1)
        for (int i = 0; i < params->polyCount; ++i) {
            // Keep area as-is, but set flag to 1 for walkable
            if (polyAreas[i] != DT_TILECACHE_NULL_AREA) {
                polyFlags[i] = 1; // Walkable flag
            }
        }
    }
};

extern "C" {

/* Tile cache management */
DETOURTILECACHE_C_API dtTileCacheHandle C_dtAllocTileCache(void) {
    return reinterpret_cast<dtTileCacheHandle>(::dtAllocTileCache());
}

DETOURTILECACHE_C_API void C_dtFreeTileCache(dtTileCacheHandle tc) {
    ::dtFreeTileCache(reinterpret_cast<::dtTileCache*>(tc));
}

/* Tile cache initialization */
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheInit(dtTileCacheHandle tc, const C_dtTileCacheParams* params,
    dtTileCacheAllocHandle alloc, dtTileCacheCompressorHandle comp, dtTileCacheMeshProcessHandle proc) {
    return reinterpret_cast<::dtTileCache*>(tc)->init(
        reinterpret_cast<const ::dtTileCacheParams*>(params),
        reinterpret_cast<::dtTileCacheAlloc*>(alloc),
        reinterpret_cast<::dtTileCacheCompressor*>(comp),
        reinterpret_cast<::dtTileCacheMeshProcess*>(proc));
}

/* Params access */
DETOURTILECACHE_C_API const C_dtTileCacheParams* C_dtTileCacheGetParams(dtTileCacheHandle tc) {
    return reinterpret_cast<const C_dtTileCacheParams*>(
        reinterpret_cast<::dtTileCache*>(tc)->getParams());
}

/* Tile management */
DETOURTILECACHE_C_API int C_dtTileCacheGetTileCount(dtTileCacheHandle tc) {
    return reinterpret_cast<::dtTileCache*>(tc)->getTileCount();
}

DETOURTILECACHE_C_API int C_dtTileCacheGetTileInfo(dtTileCacheHandle tc, int i, C_dtCompressedTileInfo* info) {
    const ::dtCompressedTile* tile = reinterpret_cast<::dtTileCache*>(tc)->getTile(i);
    if (tile && info) {
        info->salt = tile->salt;
        info->compressedSize = tile->compressedSize;
        info->dataSize = tile->dataSize;
        info->flags = tile->flags;
        return 1;
    }
    return 0;
}

DETOURTILECACHE_C_API int C_dtTileCacheGetTilesAt(dtTileCacheHandle tc, int tx, int ty,
    C_dtCompressedTileRef* tiles, int maxTiles) {
    return reinterpret_cast<::dtTileCache*>(tc)->getTilesAt(tx, ty, tiles, maxTiles);
}

DETOURTILECACHE_C_API C_dtCompressedTileRef C_dtTileCacheGetTileRef(dtTileCacheHandle tc, int i) {
    const ::dtCompressedTile* tile = reinterpret_cast<::dtTileCache*>(tc)->getTile(i);
    return reinterpret_cast<::dtTileCache*>(tc)->getTileRef(tile);
}

DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheAddTile(dtTileCacheHandle tc, unsigned char* data, int dataSize,
    unsigned char flags, C_dtCompressedTileRef* result) {
    return reinterpret_cast<::dtTileCache*>(tc)->addTile(data, dataSize, flags, result);
}

DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheRemoveTile(dtTileCacheHandle tc, C_dtCompressedTileRef ref,
    unsigned char** data, int* dataSize) {
    return reinterpret_cast<::dtTileCache*>(tc)->removeTile(ref, data, dataSize);
}

/* Obstacle management */
DETOURTILECACHE_C_API int C_dtTileCacheGetObstacleCount(dtTileCacheHandle tc) {
    return reinterpret_cast<::dtTileCache*>(tc)->getObstacleCount();
}

DETOURTILECACHE_C_API int C_dtTileCacheGetObstacleInfo(dtTileCacheHandle tc, int i, C_dtTileCacheObstacleInfo* info) {
    const ::dtTileCacheObstacle* ob = reinterpret_cast<::dtTileCache*>(tc)->getObstacle(i);
    if (ob && info) {
        info->type = ob->type;
        info->state = ob->state;
        memcpy(&info->cylinder, &ob->cylinder, sizeof(C_dtObstacleCylinder));
        memcpy(&info->box, &ob->box, sizeof(C_dtObstacleBox));
        memcpy(&info->orientedBox, &ob->orientedBox, sizeof(C_dtObstacleOrientedBox));
        return 1;
    }
    return 0;
}

DETOURTILECACHE_C_API C_dtObstacleRef C_dtTileCacheGetObstacleRef(dtTileCacheHandle tc, int i) {
    const ::dtTileCacheObstacle* ob = reinterpret_cast<::dtTileCache*>(tc)->getObstacle(i);
    return reinterpret_cast<::dtTileCache*>(tc)->getObstacleRef(ob);
}

DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheAddObstacle(dtTileCacheHandle tc, const float* pos,
    float radius, float height, C_dtObstacleRef* result) {
    return reinterpret_cast<::dtTileCache*>(tc)->addObstacle(pos, radius, height, result);
}

DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheAddBoxObstacle(dtTileCacheHandle tc, const float* bmin,
    const float* bmax, C_dtObstacleRef* result) {
    return reinterpret_cast<::dtTileCache*>(tc)->addBoxObstacle(bmin, bmax, result);
}

DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheAddBoxObstacleOriented(dtTileCacheHandle tc, const float* center,
    const float* halfExtents, float yRadians, C_dtObstacleRef* result) {
    return reinterpret_cast<::dtTileCache*>(tc)->addBoxObstacle(center, halfExtents, yRadians, result);
}

DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheRemoveObstacle(dtTileCacheHandle tc, C_dtObstacleRef ref) {
    return reinterpret_cast<::dtTileCache*>(tc)->removeObstacle(ref);
}

/* Queries */
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheQueryTiles(dtTileCacheHandle tc, const float* bmin, const float* bmax,
    C_dtCompressedTileRef* results, int* resultCount, int maxResults) {
    return reinterpret_cast<::dtTileCache*>(tc)->queryTiles(bmin, bmax, results, resultCount, maxResults);
}

/* Update and building */
DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheUpdate(dtTileCacheHandle tc, float dt, dtNavMeshHandle navmesh, int* upToDate) {
    bool upToDateBool = false;
    dtStatus status = reinterpret_cast<::dtTileCache*>(tc)->update(dt,
        reinterpret_cast<::dtNavMesh*>(navmesh), &upToDateBool);
    if (upToDate) *upToDate = upToDateBool ? 1 : 0;
    return status;
}

DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheBuildNavMeshTilesAt(dtTileCacheHandle tc, int tx, int ty, dtNavMeshHandle navmesh) {
    return reinterpret_cast<::dtTileCache*>(tc)->buildNavMeshTilesAt(tx, ty,
        reinterpret_cast<::dtNavMesh*>(navmesh));
}

DETOURTILECACHE_C_API C_dtStatus C_dtTileCacheBuildNavMeshTile(dtTileCacheHandle tc, C_dtCompressedTileRef ref, dtNavMeshHandle navmesh) {
    return reinterpret_cast<::dtTileCache*>(tc)->buildNavMeshTile(ref,
        reinterpret_cast<::dtNavMesh*>(navmesh));
}

/* Bounds calculation */
DETOURTILECACHE_C_API void C_dtTileCacheCalcTightTileBounds(dtTileCacheHandle tc,
    const C_dtTileCacheLayerHeader* header, float* bmin, float* bmax) {
    reinterpret_cast<::dtTileCache*>(tc)->calcTightTileBounds(
        reinterpret_cast<const ::dtTileCacheLayerHeader*>(header), bmin, bmax);
}

DETOURTILECACHE_C_API void C_dtTileCacheGetObstacleBounds(dtTileCacheHandle tc, int obstacleIdx, float* bmin, float* bmax) {
    const ::dtTileCacheObstacle* ob = reinterpret_cast<::dtTileCache*>(tc)->getObstacle(obstacleIdx);
    if (ob) {
        reinterpret_cast<::dtTileCache*>(tc)->getObstacleBounds(ob, bmin, bmax);
    }
}

/* Custom allocator creation */
DETOURTILECACHE_C_API dtTileCacheAllocHandle C_dtCreateTileCacheAlloc(
    C_dtTileCacheAllocFunc allocFunc, C_dtTileCacheFreeFunc freeFunc) {
    return reinterpret_cast<dtTileCacheAllocHandle>(new dtTileCacheAllocC(allocFunc, freeFunc));
}

DETOURTILECACHE_C_API void C_dtDestroyTileCacheAlloc(dtTileCacheAllocHandle alloc) {
    delete reinterpret_cast<dtTileCacheAllocC*>(alloc);
}

/* Custom compressor creation */
DETOURTILECACHE_C_API dtTileCacheCompressorHandle C_dtCreateTileCacheCompressor(
    C_dtTileCacheMaxCompressedSizeFunc maxSizeFunc,
    C_dtTileCacheCompressFunc compressFunc,
    C_dtTileCacheDecompressFunc decompressFunc) {
    return reinterpret_cast<dtTileCacheCompressorHandle>(
        new dtTileCacheCompressorC(maxSizeFunc, compressFunc, decompressFunc));
}

DETOURTILECACHE_C_API void C_dtDestroyTileCacheCompressor(dtTileCacheCompressorHandle comp) {
    delete reinterpret_cast<dtTileCacheCompressorC*>(comp);
}

/* Default allocator */
DETOURTILECACHE_C_API dtTileCacheAllocHandle C_dtCreateDefaultTileCacheAlloc(void) {
    return reinterpret_cast<dtTileCacheAllocHandle>(new dtTileCacheAlloc());
}

/* Default passthrough compressor */
DETOURTILECACHE_C_API dtTileCacheCompressorHandle C_dtCreateDefaultTileCacheCompressor(void) {
    return reinterpret_cast<dtTileCacheCompressorHandle>(new dtTileCachePassthroughCompressor());
}

/* Custom mesh process creation */
DETOURTILECACHE_C_API dtTileCacheMeshProcessHandle C_dtCreateTileCacheMeshProcess(
    C_dtTileCacheMeshProcessFunc processFunc) {
    return reinterpret_cast<dtTileCacheMeshProcessHandle>(new dtTileCacheMeshProcessC(processFunc));
}

DETOURTILECACHE_C_API void C_dtDestroyTileCacheMeshProcess(dtTileCacheMeshProcessHandle proc) {
    delete reinterpret_cast<dtTileCacheMeshProcessC*>(proc);
}

/* Default mesh process */
DETOURTILECACHE_C_API dtTileCacheMeshProcessHandle C_dtCreateDefaultTileCacheMeshProcess(void) {
    return reinterpret_cast<dtTileCacheMeshProcessHandle>(new dtTileCacheDefaultMeshProcess());
}

/* Tile cache layer building */
DETOURTILECACHE_C_API C_dtStatus C_dtBuildTileCacheLayer(dtTileCacheCompressorHandle comp,
    C_dtTileCacheLayerHeader* header, const unsigned char* heights, const unsigned char* areas,
    const unsigned char* cons, unsigned char** outData, int* outDataSize) {
    return ::dtBuildTileCacheLayer(
        reinterpret_cast<::dtTileCacheCompressor*>(comp),
        reinterpret_cast<::dtTileCacheLayerHeader*>(header),
        heights, areas, cons, outData, outDataSize);
}

/* Endian swap */
DETOURTILECACHE_C_API int C_dtTileCacheHeaderSwapEndian(unsigned char* data, int dataSize) {
    return ::dtTileCacheHeaderSwapEndian(data, dataSize) ? 1 : 0;
}

} /* extern "C" */
