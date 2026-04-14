namespace Sedulous.Engine.Navigation;

using System;
using recastnavigation_Beef;

/// Wrapper for Detour tile cache (dynamic obstacles).
class TileCache
{
	private dtTileCacheHandle mHandle;
	private dtTileCacheAllocHandle mAlloc;
	private TileCacheCompressor mCompressor ~ delete _;
	private TileCacheMeshProcess mMeshProcess ~ delete _;
	private bool mOwnsHandle;
	private NavMesh mNavMesh;

	/// Creates a new TileCache.
	public this()
	{
		mHandle = dtAllocTileCache();
		mAlloc = dtCreateDefaultTileCacheAlloc();
		mCompressor = new TileCacheCompressor();
		mMeshProcess = new TileCacheMeshProcess();
		mOwnsHandle = true;
	}

	/// Creates a wrapper around an existing handle.
	public this(dtTileCacheHandle handle, bool ownsHandle = false)
	{
		mHandle = handle;
		mOwnsHandle = ownsHandle;
	}

	public ~this()
	{
		if (mOwnsHandle)
		{
			if (mHandle != null)
			{
				dtFreeTileCache(mHandle);
				mHandle = null;
			}
			if (mAlloc != null)
			{
				dtDestroyTileCacheAlloc(mAlloc);
				mAlloc = null;
			}
		}
	}

	/// Gets the underlying handle.
	public dtTileCacheHandle Handle => mHandle;

	/// Gets the compressor handle.
	public dtTileCacheCompressorHandle CompressorHandle => mCompressor?.Handle;

	/// Gets the mesh process handle.
	public dtTileCacheMeshProcessHandle MeshProcessHandle => mMeshProcess?.Handle;

	/// Gets the allocator handle.
	public dtTileCacheAllocHandle AllocHandle => mAlloc;

	/// Sets the navmesh reference (for Update calls).
	public void SetNavMesh(NavMesh navMesh)
	{
		mNavMesh = navMesh;
	}

	/// Initializes the tile cache with explicit parameters.
	public NavStatus Init(dtTileCacheParams* tcParams)
	{
		if (mHandle == null)
			return .Failure;

		let compHandle = mCompressor != null ? mCompressor.Handle : null;
		let procHandle = mMeshProcess != null ? mMeshProcess.Handle : null;
		let status = dtTileCacheInit(mHandle, tcParams, mAlloc, compHandle, procHandle);
		return StatusHelper.FromDtStatus(status);
	}

	/// Initializes the tile cache from config.
	public NavStatus Init(NavMesh navMesh, IInputGeometryProvider geometry, in NavMeshBuildConfig config,
		float[3] worldBMin, float[3] worldBMax)
	{
		if (mHandle == null || navMesh == null)
			return .Failure;

		mNavMesh = navMesh;

		// Create tile cache params
		dtTileCacheParams tcParams = .();
		tcParams.orig = worldBMin;
		tcParams.cs = config.CellSize;
		tcParams.ch = config.CellHeight;
		tcParams.width = config.TileSize > 0 ? config.TileSize : 48;
		tcParams.height = config.TileSize > 0 ? config.TileSize : 48;
		tcParams.walkableHeight = config.AgentHeight;
		tcParams.walkableRadius = config.AgentRadius;
		tcParams.walkableClimb = config.AgentMaxClimb;
		tcParams.maxSimplificationError = config.EdgeMaxError;
		tcParams.maxTiles = 1024;
		tcParams.maxObstacles = 128;

		let compHandle = mCompressor != null ? mCompressor.Handle : null;
		let procHandle = mMeshProcess != null ? mMeshProcess.Handle : null;
		let status = dtTileCacheInit(mHandle, &tcParams, mAlloc, compHandle, procHandle);
		return StatusHelper.FromDtStatus(status);
	}

	/// Adds a compressed tile to the cache.
	public NavStatus AddTile(uint8* data, int32 dataSize, uint8 flags, out dtCompressedTileRef result)
	{
		result = 0;
		if (mHandle == null)
			return .Failure;

		let status = dtTileCacheAddTile(mHandle, data, dataSize, flags, &result);
		return StatusHelper.FromDtStatus(status);
	}

	/// Builds navmesh tiles at the specified grid location.
	public NavStatus BuildNavMeshTilesAt(int32 tx, int32 ty, NavMesh navMesh)
	{
		if (mHandle == null || navMesh == null)
			return .Failure;

		let status = dtTileCacheBuildNavMeshTilesAt(mHandle, tx, ty, navMesh.Handle);
		return StatusHelper.FromDtStatus(status);
	}

	/// Builds a specific navmesh tile from a compressed tile reference.
	public NavStatus BuildNavMeshTile(dtCompressedTileRef @ref, NavMesh navMesh)
	{
		if (mHandle == null || navMesh == null)
			return .Failure;

		let status = dtTileCacheBuildNavMeshTile(mHandle, @ref, navMesh.Handle);
		return StatusHelper.FromDtStatus(status);
	}

	/// Gets the number of tiles.
	public int32 TileCount
	{
		get
		{
			if (mHandle == null)
				return 0;
			return dtTileCacheGetTileCount(mHandle);
		}
	}

	/// Gets the number of obstacles.
	public int32 ObstacleCount
	{
		get
		{
			if (mHandle == null)
				return 0;
			return dtTileCacheGetObstacleCount(mHandle);
		}
	}

	/// Adds a cylindrical obstacle.
	public NavStatus AddObstacle(float[3] pos, float radius, float height, out int32 obstacleId)
	{
		obstacleId = -1;
		if (mHandle == null)
			return .Failure;

		var mutablePos = pos;
		dtObstacleRef @ref = 0;
		let status = dtTileCacheAddObstacle(mHandle, &mutablePos[0], radius, height, &@ref);

		if (StatusHelper.IsSuccess(status))
			obstacleId = (int32)@ref;

		return StatusHelper.FromDtStatus(status);
	}

	/// Adds a box obstacle.
	public NavStatus AddBoxObstacle(float[3] bmin, float[3] bmax, out int32 obstacleId)
	{
		obstacleId = -1;
		if (mHandle == null)
			return .Failure;

		var mutableBmin = bmin;
		var mutableBmax = bmax;
		dtObstacleRef @ref = 0;
		let status = dtTileCacheAddBoxObstacle(mHandle, &mutableBmin[0], &mutableBmax[0], &@ref);

		if (StatusHelper.IsSuccess(status))
			obstacleId = (int32)@ref;

		return StatusHelper.FromDtStatus(status);
	}

	/// Adds an oriented box obstacle.
	public NavStatus AddBoxObstacleOriented(float[3] center, float[3] halfExtents, float yRadians, out int32 obstacleId)
	{
		obstacleId = -1;
		if (mHandle == null)
			return .Failure;

		var mutableCenter = center;
		var mutableHalfExtents = halfExtents;
		dtObstacleRef @ref = 0;
		let status = dtTileCacheAddBoxObstacleOriented(mHandle, &mutableCenter[0], &mutableHalfExtents[0], yRadians, &@ref);

		if (StatusHelper.IsSuccess(status))
			obstacleId = (int32)@ref;

		return StatusHelper.FromDtStatus(status);
	}

	/// Removes an obstacle.
	public NavStatus RemoveObstacle(int32 obstacleId)
	{
		if (mHandle == null)
			return .Failure;

		let status = dtTileCacheRemoveObstacle(mHandle, (dtObstacleRef)obstacleId);
		return StatusHelper.FromDtStatus(status);
	}

	/// Updates the tile cache, processing pending obstacle changes.
	public NavStatus Update()
	{
		if (mHandle == null || mNavMesh == null)
			return .Failure;

		int32 upToDate;
		let status = dtTileCacheUpdate(mHandle, 0.0f, mNavMesh.Handle, &upToDate);
		return StatusHelper.FromDtStatus(status);
	}

	/// Updates the tile cache with delta time.
	public NavStatus Update(float dt)
	{
		if (mHandle == null || mNavMesh == null)
			return .Failure;

		int32 upToDate;
		let status = dtTileCacheUpdate(mHandle, dt, mNavMesh.Handle, &upToDate);
		return StatusHelper.FromDtStatus(status);
	}

	/// Gets obstacle bounds.
	public void GetObstacleBounds(int32 obstacleIdx, out float[3] bmin, out float[3] bmax)
	{
		bmin = default;
		bmax = default;
		if (mHandle != null)
			dtTileCacheGetObstacleBounds(mHandle, obstacleIdx, &bmin[0], &bmax[0]);
	}

	/// Gets tile cache parameters.
	public dtTileCacheParams* GetParams()
	{
		if (mHandle == null)
			return null;
		return dtTileCacheGetParams(mHandle);
	}
}
