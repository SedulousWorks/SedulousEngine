namespace Sedulous.Engine.Navigation;

using System;
using recastnavigation_Beef;

/// Wrapper for Detour navigation mesh.
class NavMesh
{
	private dtNavMeshHandle mHandle;
	private bool mOwnsHandle;

	/// Creates a new empty NavMesh.
	public this()
	{
		mHandle = dtAllocNavMesh();
		mOwnsHandle = true;
	}

	/// Creates a NavMesh wrapper around an existing handle.
	public this(dtNavMeshHandle handle, bool ownsHandle = false)
	{
		mHandle = handle;
		mOwnsHandle = ownsHandle;
	}

	public ~this()
	{
		if (mOwnsHandle && mHandle != null)
		{
			dtFreeNavMesh(mHandle);
			mHandle = null;
		}
	}

	/// Gets the underlying handle.
	public dtNavMeshHandle Handle => mHandle;

	/// Initializes the navmesh with parameters.
	public NavStatus Init(dtNavMeshParams* @params)
	{
		if (mHandle == null)
			return .Failure;

		let status = dtNavMeshInit(mHandle, @params);
		return StatusHelper.FromDtStatus(status);
	}

	/// Initializes the navmesh with a single tile of data.
	public NavStatus InitSingle(uint8* data, int32 dataSize, int32 flags = (.)dtTileFlags.DT_TILE_FREE_DATA)
	{
		if (mHandle == null)
			return .Failure;

		let status = dtNavMeshInitSingle(mHandle, data, dataSize, flags);
		return StatusHelper.FromDtStatus(status);
	}

	/// Gets the navmesh parameters.
	public dtNavMeshParams* GetParams()
	{
		if (mHandle == null)
			return null;
		return dtNavMeshGetParams(mHandle);
	}

	/// Adds a tile to the navmesh.
	public NavStatus AddTile(uint8* data, int32 dataSize, int32 flags, TileRef lastRef, out TileRef result)
	{
		result = default;
		if (mHandle == null)
			return .Failure;

		dtTileRef resultRef = 0;
		let status = dtNavMeshAddTile(mHandle, data, dataSize, flags, lastRef.Value, &resultRef);
		result = resultRef;
		return StatusHelper.FromDtStatus(status);
	}

	/// Removes a tile from the navmesh.
	public NavStatus RemoveTile(TileRef @ref, out uint8* data, out int32 dataSize)
	{
		data = null;
		dataSize = 0;
		if (mHandle == null)
			return .Failure;

		let status = dtNavMeshRemoveTile(mHandle, @ref.Value, &data, &dataSize);
		return StatusHelper.FromDtStatus(status);
	}

	/// Gets the maximum number of tiles.
	public int32 MaxTiles
	{
		get
		{
			if (mHandle == null)
				return 0;
			return dtNavMeshGetMaxTiles(mHandle);
		}
	}

	/// Gets a tile by index.
	public dtMeshTile* GetTile(int32 index)
	{
		if (mHandle == null)
			return null;
		return dtNavMeshGetTile(mHandle, index);
	}

	/// Gets a tile at the specified grid location.
	public dtMeshTile* GetTileAt(int32 x, int32 y, int32 layer)
	{
		if (mHandle == null)
			return null;
		return dtNavMeshGetTileAt(mHandle, x, y, layer);
	}

	/// Gets the tile reference at the specified grid location.
	public TileRef GetTileRefAt(int32 x, int32 y, int32 layer)
	{
		if (mHandle == null)
			return TileRef(0);
		return dtNavMeshGetTileRefAt(mHandle, x, y, layer);
	}

	/// Checks if a polygon reference is valid.
	public bool IsValidPolyRef(PolyRef @ref)
	{
		if (mHandle == null)
			return false;
		return dtNavMeshIsValidPolyRef(mHandle, @ref.Value) != 0;
	}

	/// Gets polygon flags.
	public NavStatus GetPolyFlags(PolyRef @ref, out uint16 flags)
	{
		flags = 0;
		if (mHandle == null)
			return .Failure;

		let status = dtNavMeshGetPolyFlags(mHandle, @ref.Value, &flags);
		return StatusHelper.FromDtStatus(status);
	}

	/// Sets polygon flags.
	public NavStatus SetPolyFlags(PolyRef @ref, uint16 flags)
	{
		if (mHandle == null)
			return .Failure;

		let status = dtNavMeshSetPolyFlags(mHandle, @ref.Value, flags);
		return StatusHelper.FromDtStatus(status);
	}

	/// Gets polygon area.
	public NavStatus GetPolyArea(PolyRef @ref, out uint8 area)
	{
		area = 0;
		if (mHandle == null)
			return .Failure;

		let status = dtNavMeshGetPolyArea(mHandle, @ref.Value, &area);
		return StatusHelper.FromDtStatus(status);
	}

	/// Sets polygon area.
	public NavStatus SetPolyArea(PolyRef @ref, uint8 area)
	{
		if (mHandle == null)
			return .Failure;

		let status = dtNavMeshSetPolyArea(mHandle, @ref.Value, area);
		return StatusHelper.FromDtStatus(status);
	}

	/// Calculates the tile location for a position.
	public void CalcTileLoc(float[3] pos, out int32 tx, out int32 ty)
	{
		tx = 0;
		ty = 0;
		if (mHandle == null)
			return;

		var mutablePos = pos;
		dtNavMeshCalcTileLoc(mHandle, &mutablePos[0], &tx, &ty);
	}
}
