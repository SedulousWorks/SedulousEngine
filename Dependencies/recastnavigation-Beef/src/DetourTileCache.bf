using System;

namespace recastnavigation_Beef;

/* Tile cache types */
typealias dtObstacleRef = uint32;
typealias dtCompressedTileRef = uint32;

/* Opaque handle types */
typealias dtTileCacheHandle = void*;
typealias dtTileCacheAllocHandle = void*;
typealias dtTileCacheCompressorHandle = void*;
typealias dtTileCacheMeshProcessHandle = void*;

/* Constants */
static
{
	public const int32 DT_TILECACHE_MAGIC = ((int32)'D' << 24 | (int32)'T' << 16 | (int32)'L' << 8 | (int32)'R');
	public const int32 DT_TILECACHE_VERSION = 1;
	public const uint8 DT_TILECACHE_NULL_AREA = 0;
	public const uint8 DT_TILECACHE_WALKABLE_AREA = 63;
	public const uint16 DT_TILECACHE_NULL_IDX = 0xffff;
	public const int32 DT_MAX_TOUCHED_TILES = 8;
}

/* Tile flags */
enum dtCompressedTileFlags : int32
{
	DT_COMPRESSEDTILE_FREE_DATA = 0x01
}

/* Obstacle states */
enum dtObstacleState : int32
{
	DT_OBSTACLE_EMPTY,
	DT_OBSTACLE_PROCESSING,
	DT_OBSTACLE_PROCESSED,
	DT_OBSTACLE_REMOVING
}

/* Obstacle types */
enum dtObstacleType : int32
{
	DT_OBSTACLE_CYLINDER,
	DT_OBSTACLE_BOX,
	DT_OBSTACLE_ORIENTED_BOX
}

/* Tile cache layer header */
[CRepr]
struct dtTileCacheLayerHeader
{
	public int32 magic;
	public int32 version;
	public int32 tx, ty, tlayer;
	public float[3] bmin;
	public float[3] bmax;
	public uint16 hmin, hmax;
	public uint8 width, height;
	public uint8 minx, maxx, miny, maxy;
}

/* Tile cache params */
[CRepr]
struct dtTileCacheParams
{
	public float[3] orig;
	public float cs, ch;
	public int32 width, height;
	public float walkableHeight;
	public float walkableRadius;
	public float walkableClimb;
	public float maxSimplificationError;
	public int32 maxTiles;
	public int32 maxObstacles;
}

/* Obstacle cylinder */
[CRepr]
struct dtObstacleCylinder
{
	public float[3] pos;
	public float radius;
	public float height;
}

/* Obstacle box */
[CRepr]
struct dtObstacleBox
{
	public float[3] bmin;
	public float[3] bmax;
}

/* Obstacle oriented box */
[CRepr]
struct dtObstacleOrientedBox
{
	public float[3] center;
	public float[3] halfExtents;
	public float[2] rotAux;
}

/* Compressed tile info */
[CRepr]
struct dtCompressedTileInfo
{
	public uint32 salt;
	public int32 compressedSize;
	public int32 dataSize;
	public uint32 flags;
}

/* Obstacle info */
[CRepr]
struct dtTileCacheObstacleInfo
{
	public uint8 type;
	public uint8 state;
	public dtObstacleCylinder cylinder;
	public dtObstacleBox @box;
	public dtObstacleOrientedBox orientedBox;
}

/* Callback function types */
function void* dtTileCacheAllocFunc(int size);
function void dtTileCacheFreeFunc(void* ptr);
function int32 dtTileCacheMaxCompressedSizeFunc(int32 bufferSize);
function dtStatus dtTileCacheCompressFunc(uint8* buffer, int32 bufferSize,
	uint8* compressed, int32 maxCompressedSize, int32* compressedSize);
function dtStatus dtTileCacheDecompressFunc(uint8* compressed, int32 compressedSize,
	uint8* buffer, int32 maxBufferSize, int32* bufferSize);
function void dtTileCacheMeshProcessFunc(int32 polyCount, uint8* polyAreas, uint16* polyFlags);

/* Functions */
static
{
	/* Tile cache management */
	[CLink]
	public static extern dtTileCacheHandle C_dtAllocTileCache();
	[CLink]
	public static extern void C_dtFreeTileCache(dtTileCacheHandle tc);

	/* Tile cache initialization */
	[CLink]
	public static extern dtStatus C_dtTileCacheInit(dtTileCacheHandle tc, dtTileCacheParams* @params,
		dtTileCacheAllocHandle alloc, dtTileCacheCompressorHandle comp, dtTileCacheMeshProcessHandle proc);

	/* Params access */
	[CLink]
	public static extern dtTileCacheParams* C_dtTileCacheGetParams(dtTileCacheHandle tc);

	/* Tile management */
	[CLink]
	public static extern int32 C_dtTileCacheGetTileCount(dtTileCacheHandle tc);
	[CLink]
	public static extern int32 C_dtTileCacheGetTileInfo(dtTileCacheHandle tc, int32 i, dtCompressedTileInfo* info);
	[CLink]
	public static extern int32 C_dtTileCacheGetTilesAt(dtTileCacheHandle tc, int32 tx, int32 ty,
		dtCompressedTileRef* tiles, int32 maxTiles);
	[CLink]
	public static extern dtCompressedTileRef C_dtTileCacheGetTileRef(dtTileCacheHandle tc, int32 i);
	[CLink]
	public static extern dtStatus C_dtTileCacheAddTile(dtTileCacheHandle tc, uint8* data, int32 dataSize,
		uint8 flags, dtCompressedTileRef* result);
	[CLink]
	public static extern dtStatus C_dtTileCacheRemoveTile(dtTileCacheHandle tc, dtCompressedTileRef @ref,
		uint8** data, int32* dataSize);

	/* Obstacle management */
	[CLink]
	public static extern int32 C_dtTileCacheGetObstacleCount(dtTileCacheHandle tc);
	[CLink]
	public static extern int32 C_dtTileCacheGetObstacleInfo(dtTileCacheHandle tc, int32 i, dtTileCacheObstacleInfo* info);
	[CLink]
	public static extern dtObstacleRef C_dtTileCacheGetObstacleRef(dtTileCacheHandle tc, int32 i);
	[CLink]
	public static extern dtStatus C_dtTileCacheAddObstacle(dtTileCacheHandle tc, float* pos,
		float radius, float height, dtObstacleRef* result);
	[CLink]
	public static extern dtStatus C_dtTileCacheAddBoxObstacle(dtTileCacheHandle tc, float* bmin,
		float* bmax, dtObstacleRef* result);
	[CLink]
	public static extern dtStatus C_dtTileCacheAddBoxObstacleOriented(dtTileCacheHandle tc, float* center,
		float* halfExtents, float yRadians, dtObstacleRef* result);
	[CLink]
	public static extern dtStatus C_dtTileCacheRemoveObstacle(dtTileCacheHandle tc, dtObstacleRef @ref);

	/* Queries */
	[CLink]
	public static extern dtStatus C_dtTileCacheQueryTiles(dtTileCacheHandle tc, float* bmin, float* bmax,
		dtCompressedTileRef* results, int32* resultCount, int32 maxResults);

	/* Update and building */
	[CLink]
	public static extern dtStatus C_dtTileCacheUpdate(dtTileCacheHandle tc, float dt, dtNavMeshHandle navmesh, int32* upToDate);
	[CLink]
	public static extern dtStatus C_dtTileCacheBuildNavMeshTilesAt(dtTileCacheHandle tc, int32 tx, int32 ty, dtNavMeshHandle navmesh);
	[CLink]
	public static extern dtStatus C_dtTileCacheBuildNavMeshTile(dtTileCacheHandle tc, dtCompressedTileRef @ref, dtNavMeshHandle navmesh);

	/* Bounds calculation */
	[CLink]
	public static extern void C_dtTileCacheCalcTightTileBounds(dtTileCacheHandle tc,
		dtTileCacheLayerHeader* header, float* bmin, float* bmax);
	[CLink]
	public static extern void C_dtTileCacheGetObstacleBounds(dtTileCacheHandle tc, int32 obstacleIdx, float* bmin, float* bmax);

	/* Custom allocator creation */
	[CLink]
	public static extern dtTileCacheAllocHandle C_dtCreateTileCacheAlloc(
		dtTileCacheAllocFunc allocFunc, dtTileCacheFreeFunc freeFunc);
	[CLink]
	public static extern void C_dtDestroyTileCacheAlloc(dtTileCacheAllocHandle alloc);

	/* Custom compressor creation */
	[CLink]
	public static extern dtTileCacheCompressorHandle C_dtCreateTileCacheCompressor(
		dtTileCacheMaxCompressedSizeFunc maxSizeFunc,
		dtTileCacheCompressFunc compressFunc,
		dtTileCacheDecompressFunc decompressFunc);
	[CLink]
	public static extern void C_dtDestroyTileCacheCompressor(dtTileCacheCompressorHandle comp);

	/* Default allocator */
	[CLink]
	public static extern dtTileCacheAllocHandle C_dtCreateDefaultTileCacheAlloc();

	/* Default passthrough compressor */
	[CLink]
	public static extern dtTileCacheCompressorHandle C_dtCreateDefaultTileCacheCompressor();

	/* Custom mesh process creation */
	[CLink]
	public static extern dtTileCacheMeshProcessHandle C_dtCreateTileCacheMeshProcess(
		dtTileCacheMeshProcessFunc processFunc);
	[CLink]
	public static extern void C_dtDestroyTileCacheMeshProcess(dtTileCacheMeshProcessHandle proc);

	/* Default mesh process */
	[CLink]
	public static extern dtTileCacheMeshProcessHandle C_dtCreateDefaultTileCacheMeshProcess();

	/* Tile cache layer building */
	[CLink]
	public static extern dtStatus C_dtBuildTileCacheLayer(dtTileCacheCompressorHandle comp,
		dtTileCacheLayerHeader* header, uint8* heights, uint8* areas,
		uint8* cons, uint8** outData, int32* outDataSize);

	/* Endian swap */
	[CLink]
	public static extern int32 C_dtTileCacheHeaderSwapEndian(uint8* data, int32 dataSize);

	/* Wrapper functions */
	public static dtTileCacheHandle dtAllocTileCache() => C_dtAllocTileCache();
	public static void dtFreeTileCache(dtTileCacheHandle tc) => C_dtFreeTileCache(tc);
	public static dtStatus dtTileCacheInit(dtTileCacheHandle tc, dtTileCacheParams* @params, dtTileCacheAllocHandle alloc, dtTileCacheCompressorHandle comp, dtTileCacheMeshProcessHandle proc) => C_dtTileCacheInit(tc, @params, alloc, comp, proc);
	public static dtTileCacheParams* dtTileCacheGetParams(dtTileCacheHandle tc) => C_dtTileCacheGetParams(tc);
	public static int32 dtTileCacheGetTileCount(dtTileCacheHandle tc) => C_dtTileCacheGetTileCount(tc);
	public static int32 dtTileCacheGetTileInfo(dtTileCacheHandle tc, int32 i, dtCompressedTileInfo* info) => C_dtTileCacheGetTileInfo(tc, i, info);
	public static int32 dtTileCacheGetTilesAt(dtTileCacheHandle tc, int32 tx, int32 ty, dtCompressedTileRef* tiles, int32 maxTiles) => C_dtTileCacheGetTilesAt(tc, tx, ty, tiles, maxTiles);
	public static dtCompressedTileRef dtTileCacheGetTileRef(dtTileCacheHandle tc, int32 i) => C_dtTileCacheGetTileRef(tc, i);
	public static dtStatus dtTileCacheAddTile(dtTileCacheHandle tc, uint8* data, int32 dataSize, uint8 flags, dtCompressedTileRef* result) => C_dtTileCacheAddTile(tc, data, dataSize, flags, result);
	public static dtStatus dtTileCacheRemoveTile(dtTileCacheHandle tc, dtCompressedTileRef @ref, uint8** data, int32* dataSize) => C_dtTileCacheRemoveTile(tc, @ref, data, dataSize);
	public static int32 dtTileCacheGetObstacleCount(dtTileCacheHandle tc) => C_dtTileCacheGetObstacleCount(tc);
	public static int32 dtTileCacheGetObstacleInfo(dtTileCacheHandle tc, int32 i, dtTileCacheObstacleInfo* info) => C_dtTileCacheGetObstacleInfo(tc, i, info);
	public static dtObstacleRef dtTileCacheGetObstacleRef(dtTileCacheHandle tc, int32 i) => C_dtTileCacheGetObstacleRef(tc, i);
	public static dtStatus dtTileCacheAddObstacle(dtTileCacheHandle tc, float* pos, float radius, float height, dtObstacleRef* result) => C_dtTileCacheAddObstacle(tc, pos, radius, height, result);
	public static dtStatus dtTileCacheAddBoxObstacle(dtTileCacheHandle tc, float* bmin, float* bmax, dtObstacleRef* result) => C_dtTileCacheAddBoxObstacle(tc, bmin, bmax, result);
	public static dtStatus dtTileCacheAddBoxObstacleOriented(dtTileCacheHandle tc, float* center, float* halfExtents, float yRadians, dtObstacleRef* result) => C_dtTileCacheAddBoxObstacleOriented(tc, center, halfExtents, yRadians, result);
	public static dtStatus dtTileCacheRemoveObstacle(dtTileCacheHandle tc, dtObstacleRef @ref) => C_dtTileCacheRemoveObstacle(tc, @ref);
	public static dtStatus dtTileCacheQueryTiles(dtTileCacheHandle tc, float* bmin, float* bmax, dtCompressedTileRef* results, int32* resultCount, int32 maxResults) => C_dtTileCacheQueryTiles(tc, bmin, bmax, results, resultCount, maxResults);
	public static dtStatus dtTileCacheUpdate(dtTileCacheHandle tc, float dt, dtNavMeshHandle navmesh, int32* upToDate) => C_dtTileCacheUpdate(tc, dt, navmesh, upToDate);
	public static dtStatus dtTileCacheBuildNavMeshTilesAt(dtTileCacheHandle tc, int32 tx, int32 ty, dtNavMeshHandle navmesh) => C_dtTileCacheBuildNavMeshTilesAt(tc, tx, ty, navmesh);
	public static dtStatus dtTileCacheBuildNavMeshTile(dtTileCacheHandle tc, dtCompressedTileRef @ref, dtNavMeshHandle navmesh) => C_dtTileCacheBuildNavMeshTile(tc, @ref, navmesh);
	public static void dtTileCacheCalcTightTileBounds(dtTileCacheHandle tc, dtTileCacheLayerHeader* header, float* bmin, float* bmax) => C_dtTileCacheCalcTightTileBounds(tc, header, bmin, bmax);
	public static void dtTileCacheGetObstacleBounds(dtTileCacheHandle tc, int32 obstacleIdx, float* bmin, float* bmax) => C_dtTileCacheGetObstacleBounds(tc, obstacleIdx, bmin, bmax);
	public static dtTileCacheAllocHandle dtCreateTileCacheAlloc(dtTileCacheAllocFunc allocFunc, dtTileCacheFreeFunc freeFunc) => C_dtCreateTileCacheAlloc(allocFunc, freeFunc);
	public static void dtDestroyTileCacheAlloc(dtTileCacheAllocHandle alloc) => C_dtDestroyTileCacheAlloc(alloc);
	public static dtTileCacheCompressorHandle dtCreateTileCacheCompressor(dtTileCacheMaxCompressedSizeFunc maxSizeFunc, dtTileCacheCompressFunc compressFunc, dtTileCacheDecompressFunc decompressFunc) => C_dtCreateTileCacheCompressor(maxSizeFunc, compressFunc, decompressFunc);
	public static void dtDestroyTileCacheCompressor(dtTileCacheCompressorHandle comp) => C_dtDestroyTileCacheCompressor(comp);
	public static dtTileCacheAllocHandle dtCreateDefaultTileCacheAlloc() => C_dtCreateDefaultTileCacheAlloc();
	public static dtTileCacheCompressorHandle dtCreateDefaultTileCacheCompressor() => C_dtCreateDefaultTileCacheCompressor();
	public static dtTileCacheMeshProcessHandle dtCreateTileCacheMeshProcess(dtTileCacheMeshProcessFunc processFunc) => C_dtCreateTileCacheMeshProcess(processFunc);
	public static void dtDestroyTileCacheMeshProcess(dtTileCacheMeshProcessHandle proc) => C_dtDestroyTileCacheMeshProcess(proc);
	public static dtTileCacheMeshProcessHandle dtCreateDefaultTileCacheMeshProcess() => C_dtCreateDefaultTileCacheMeshProcess();
	public static dtStatus dtBuildTileCacheLayer(dtTileCacheCompressorHandle comp, dtTileCacheLayerHeader* header, uint8* heights, uint8* areas, uint8* cons, uint8** outData, int32* outDataSize) => C_dtBuildTileCacheLayer(comp, header, heights, areas, cons, outData, outDataSize);
	public static int32 dtTileCacheHeaderSwapEndian(uint8* data, int32 dataSize) => C_dtTileCacheHeaderSwapEndian(data, dataSize);
}
