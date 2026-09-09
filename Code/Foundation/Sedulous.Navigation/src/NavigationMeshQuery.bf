using System;
using Sedulous.Core;
using recastnavigation_Beef;

namespace Sedulous.Navigation;

/// Pathfinding against a mesh, which it BORROWS: the mesh must outlive it.
class NavigationMeshQuery
{
	/// The polygons one search may pass through, and the corners one straight path may have.
	private const int32 cMaxPathPolys = 256;
	private const int32 cMaxStraightPath = 256;
	/// The nodes the search may open. More finds a way round more, and costs more to hold.
	private const int32 cMaxNodes = 2048;

	/// How far a world point may sit off the mesh and still snap onto it. Taller than it is
	/// wide, because a point is far more often above or below the floor than beside it.
	private static float[3] sHalfExtents = .(2.0f, 4.0f, 2.0f);

	private dtNavMeshQueryHandle mQuery = default;
	/// The default: everything included, and every area at unit cost.
	private dtQueryFilterHandle mFilter = default;

	public this(NavigationMesh mesh)
	{
		if ((mesh == null) || !mesh.IsValid)
			return;

		let query = C_dtAllocNavMeshQuery();
		if (query == default)
			return;
		if (C_dtStatusFailed(C_dtNavMeshQueryInit(query, mesh.NativeHandle, cMaxNodes)) != 0)
		{
			C_dtFreeNavMeshQuery(query);
			return;
		}

		let filter = C_dtAllocQueryFilter();
		if (filter == default)
		{
			C_dtFreeNavMeshQuery(query);
			return;
		}

		mQuery = query;
		mFilter = filter;
	}

	public ~this()
	{
		if (mFilter != default)
			C_dtFreeQueryFilter(mFilter);
		if (mQuery != default)
			C_dtFreeNavMeshQuery(mQuery);
	}

	public bool IsValid => mQuery != default;

	/// The nearest point ON the mesh, within the search box. False when there is none.
	public bool FindNearestPoint(Float3 point, out Float3 outPoint)
	{
		outPoint = .(0, 0, 0);
		if (mQuery == default)
			return false;

		float[3] p = .(point.X, point.Y, point.Z);
		float[3] nearest = .();
		dtPolyRef reference = 0;

		let status = C_dtNavMeshQueryFindNearestPoly(mQuery, &p[0], &sHalfExtents[0], mFilter,
			&reference, &nearest[0]);
		if ((C_dtStatusFailed(status) != 0) || (reference == 0))
			return false;

		outPoint = .(nearest[0], nearest[1], nearest[2]);
		return true;
	}

	/// A path from one point to another.
	///
	/// Ok with a COMPLETE path when the destination is reachable; Ok with an incomplete one
	/// when the corners lead only to the nearest reachable point, which is reported rather
	/// than failed; NotFound when either end has no polygon within the search box.
	public Result<void, ErrorCode> FindPath(Float3 start, Float3 end, NavigationPath outPath)
	{
		outPath.Clear();
		if (mQuery == default)
			return .Err(.Internal);

		float[3] startPos = .(start.X, start.Y, start.Z);
		float[3] endPos = .(end.X, end.Y, end.Z);
		float[3] startNearest = .();
		float[3] endNearest = .();
		dtPolyRef startRef = 0;
		dtPolyRef endRef = 0;

		let s1 = C_dtNavMeshQueryFindNearestPoly(mQuery, &startPos[0], &sHalfExtents[0], mFilter,
			&startRef, &startNearest[0]);
		let s2 = C_dtNavMeshQueryFindNearestPoly(mQuery, &endPos[0], &sHalfExtents[0], mFilter,
			&endRef, &endNearest[0]);
		if ((C_dtStatusFailed(s1) != 0) || (C_dtStatusFailed(s2) != 0) || (startRef == 0)
			|| (endRef == 0))
			return .Err(.NotFound);

		let pathPolys = scope dtPolyRef[cMaxPathPolys];
		int32 pathCount = 0;
		let found = C_dtNavMeshQueryFindPath(mQuery, startRef, endRef, &startNearest[0],
			&endNearest[0], mFilter, &pathPolys[0], &pathCount, cMaxPathPolys);
		if ((C_dtStatusFailed(found) != 0) || (pathCount == 0))
			return .Err(.NotFound);

		// Reachable only when the corridor actually ENDS on the destination's polygon.
		// Detour also flags a partial result, and both are checked: either one alone has
		// missed a case in practice.
		let partial = (C_dtStatusDetail(found, DT_PARTIAL_RESULT) != 0)
			|| (pathPolys[pathCount - 1] != endRef);

		let straight = scope float[cMaxStraightPath * 3];
		let straightFlags = scope uint8[cMaxStraightPath];
		let straightRefs = scope dtPolyRef[cMaxStraightPath];
		int32 straightCount = 0;
		let pulled = C_dtNavMeshQueryFindStraightPath(mQuery, &startNearest[0], &endNearest[0],
			&pathPolys[0], pathCount, &straight[0], &straightFlags[0], &straightRefs[0],
			&straightCount, cMaxStraightPath, 0);
		if (C_dtStatusFailed(pulled) != 0)
			return .Err(.Internal);

		for (int32 i = 0; i < straightCount; i++)
			outPath.Corners.Add(.(straight[i * 3 + 0], straight[i * 3 + 1],
				straight[i * 3 + 2]));
		outPath.Complete = !partial;
		return .Ok;
	}
}
