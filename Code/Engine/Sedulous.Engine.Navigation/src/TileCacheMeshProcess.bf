namespace Sedulous.Engine.Navigation;

using System;
using recastnavigation_Beef;

/// Mesh process for TileCache that sets polygon flags when tiles are built.
class TileCacheMeshProcess
{
	private dtTileCacheMeshProcessHandle mHandle;

	public this()
	{
		// Create mesh process using Beef callback
		mHandle = dtCreateTileCacheMeshProcess(=> ProcessPolygons);
	}

	public ~this()
	{
		if (mHandle != null)
		{
			dtDestroyTileCacheMeshProcess(mHandle);
			mHandle = null;
		}
	}

	/// Gets the underlying handle.
	public dtTileCacheMeshProcessHandle Handle => mHandle;

	/// Callback: process polygons to set flags.
	private static void ProcessPolygons(int32 polyCount, uint8* polyAreas, uint16* polyFlags)
	{
		// Set all non-null area polygons to walkable (flag 1)
		for (int32 i = 0; i < polyCount; i++)
		{
			if (polyAreas[i] != DT_TILECACHE_NULL_AREA)
			{
				polyFlags[i] = 1; // Walkable flag
			}
		}
	}
}
