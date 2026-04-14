namespace Sedulous.Engine.Navigation;

using System;
using System.Collections;
using recastnavigation_Beef;

/// Wrapper for Detour navigation mesh query.
class NavMeshQuery
{
	private dtNavMeshQueryHandle mHandle;
	private bool mOwnsHandle;

	private const int32 MAX_POLYS = 256;
	private const int32 MAX_PATH = 256;
	private const int32 MAX_NODES = 2048;

	/// Creates a new NavMeshQuery.
	public this()
	{
		mHandle = dtAllocNavMeshQuery();
		mOwnsHandle = true;
	}

	/// Creates a wrapper around an existing handle.
	public this(dtNavMeshQueryHandle handle, bool ownsHandle = false)
	{
		mHandle = handle;
		mOwnsHandle = ownsHandle;
	}

	public ~this()
	{
		if (mOwnsHandle && mHandle != null)
		{
			dtFreeNavMeshQuery(mHandle);
			mHandle = null;
		}
	}

	/// Gets the underlying handle.
	public dtNavMeshQueryHandle Handle => mHandle;

	/// Initializes the query with a navmesh.
	public NavStatus Init(NavMesh navMesh, int32 maxNodes = MAX_NODES)
	{
		if (mHandle == null || navMesh == null)
			return .Failure;

		let status = dtNavMeshQueryInit(mHandle, navMesh.Handle, maxNodes);
		return StatusHelper.FromDtStatus(status);
	}

	/// Finds the nearest polygon to a point.
	public NavStatus FindNearestPoly(float[3] center, float[3] halfExtents, NavMeshQueryFilter filter,
		out PolyRef nearestRef, out float[3] nearestPt)
	{
		nearestRef = default;
		nearestPt = default;

		if (mHandle == null || filter == null)
			return .Failure;

		var mutableCenter = center;
		var mutableHalfExtents = halfExtents;
		dtPolyRef resultRef = 0;
		let status = dtNavMeshQueryFindNearestPoly(mHandle,
			&mutableCenter[0], &mutableHalfExtents[0], filter.Handle,
			&resultRef, &nearestPt[0]);

		nearestRef = resultRef;
		return StatusHelper.FromDtStatus(status);
	}

	/// Finds a path between two polygons.
	public NavStatus FindPath(PolyRef startRef, PolyRef endRef, float[3] startPos, float[3] endPos,
		NavMeshQueryFilter filter, List<PolyRef> path)
	{
		path.Clear();
		if (mHandle == null || filter == null)
			return .Failure;

		var mutableStartPos = startPos;
		var mutableEndPos = endPos;
		dtPolyRef* pathBuffer = scope dtPolyRef[MAX_PATH]*;
		int32 pathCount = 0;

		let status = dtNavMeshQueryFindPath(mHandle,
			startRef.Value, endRef.Value,
			&mutableStartPos[0], &mutableEndPos[0],
			filter.Handle,
			pathBuffer, &pathCount, MAX_PATH);

		for (int32 i = 0; i < pathCount; i++)
			path.Add(PolyRef(pathBuffer[i]));

		return StatusHelper.FromDtStatus(status);
	}

	/// Finds a straight path (waypoints) from a polygon path.
	public NavStatus FindStraightPath(float[3] startPos, float[3] endPos, List<PolyRef> path,
		List<float> outPath, List<StraightPathFlags> outFlags, List<PolyRef> outRefs,
		int32 options = 0)
	{
		outPath.Clear();
		outFlags.Clear();
		outRefs.Clear();

		if (mHandle == null || path.Count == 0)
			return .Failure;

		var mutableStartPos = startPos;
		var mutableEndPos = endPos;

		// Build poly path array
		dtPolyRef* pathBuffer = scope dtPolyRef[path.Count]*;
		for (int32 i = 0; i < path.Count; i++)
			pathBuffer[i] = path[i].Value;

		float* straightPath = scope float[MAX_PATH * 3]*;
		uint8* straightPathFlags = scope uint8[MAX_PATH]*;
		dtPolyRef* straightPathRefs = scope dtPolyRef[MAX_PATH]*;
		int32 straightPathCount = 0;

		let status = dtNavMeshQueryFindStraightPath(mHandle,
			&mutableStartPos[0], &mutableEndPos[0],
			pathBuffer, (int32)path.Count,
			straightPath, straightPathFlags, straightPathRefs,
			&straightPathCount, MAX_PATH, options);

		for (int32 i = 0; i < straightPathCount; i++)
		{
			outPath.Add(straightPath[i * 3 + 0]);
			outPath.Add(straightPath[i * 3 + 1]);
			outPath.Add(straightPath[i * 3 + 2]);
			outFlags.Add((StraightPathFlags)straightPathFlags[i]);
			outRefs.Add(PolyRef(straightPathRefs[i]));
		}

		return StatusHelper.FromDtStatus(status);
	}

	/// Simplified version that only outputs waypoints.
	public NavStatus FindStraightPath(float[3] startPos, float[3] endPos, List<PolyRef> path,
		List<float> outWaypoints)
	{
		let flags = scope List<StraightPathFlags>();
		let refs = scope List<PolyRef>();
		return FindStraightPath(startPos, endPos, path, outWaypoints, flags, refs);
	}

	/// Moves along the navmesh surface from start to end.
	public NavStatus MoveAlongSurface(PolyRef startRef, float[3] startPos, float[3] endPos,
		NavMeshQueryFilter filter, out float[3] resultPos, List<PolyRef> visited)
	{
		resultPos = default;
		visited?.Clear();

		if (mHandle == null || filter == null)
			return .Failure;

		var mutableStartPos = startPos;
		var mutableEndPos = endPos;
		dtPolyRef* visitedBuffer = scope dtPolyRef[MAX_POLYS]*;
		int32 visitedCount = 0;

		let status = dtNavMeshQueryMoveAlongSurface(mHandle,
			startRef.Value, &mutableStartPos[0], &mutableEndPos[0],
			filter.Handle, &resultPos[0],
			visitedBuffer, &visitedCount, MAX_POLYS);

		if (visited != null)
		{
			for (int32 i = 0; i < visitedCount; i++)
				visited.Add(PolyRef(visitedBuffer[i]));
		}

		return StatusHelper.FromDtStatus(status);
	}

	/// Performs a raycast on the navmesh.
	public NavStatus Raycast(PolyRef startRef, float[3] startPos, float[3] endPos,
		NavMeshQueryFilter filter, out float t, out float[3] hitNormal, List<PolyRef> path)
	{
		t = 0;
		hitNormal = default;
		path?.Clear();

		if (mHandle == null || filter == null)
			return .Failure;

		var mutableStartPos = startPos;
		var mutableEndPos = endPos;
		dtPolyRef* pathBuffer = scope dtPolyRef[MAX_PATH]*;
		int32 pathCount = 0;

		let status = dtNavMeshQueryRaycast(mHandle,
			startRef.Value, &mutableStartPos[0], &mutableEndPos[0],
			filter.Handle, &t, &hitNormal[0],
			pathBuffer, &pathCount, MAX_PATH);

		if (path != null)
		{
			for (int32 i = 0; i < pathCount; i++)
				path.Add(PolyRef(pathBuffer[i]));
		}

		return StatusHelper.FromDtStatus(status);
	}

	/// Finds the distance to the nearest wall.
	public NavStatus FindDistanceToWall(PolyRef startRef, float[3] centerPos, float maxRadius,
		NavMeshQueryFilter filter, out float hitDist, out float[3] hitPos, out float[3] hitNormal)
	{
		hitDist = 0;
		hitPos = default;
		hitNormal = default;

		if (mHandle == null || filter == null)
			return .Failure;

		var mutableCenterPos = centerPos;
		let status = dtNavMeshQueryFindDistanceToWall(mHandle,
			startRef.Value, &mutableCenterPos[0], maxRadius,
			filter.Handle, &hitDist, &hitPos[0], &hitNormal[0]);

		return StatusHelper.FromDtStatus(status);
	}

	/// Gets the closest point on a polygon.
	public NavStatus ClosestPointOnPoly(PolyRef @ref, float[3] pos, out float[3] closest)
	{
		closest = default;

		if (mHandle == null)
			return .Failure;

		var mutablePos = pos;
		int32 posOverPoly = 0;
		let status = dtNavMeshQueryClosestPointOnPoly(mHandle,
			@ref.Value, &mutablePos[0], &closest[0], &posOverPoly);

		return StatusHelper.FromDtStatus(status);
	}

	/// Gets the height at a position on a polygon.
	public NavStatus GetPolyHeight(PolyRef @ref, float[3] pos, out float height)
	{
		height = 0;

		if (mHandle == null)
			return .Failure;

		var mutablePos = pos;
		let status = dtNavMeshQueryGetPolyHeight(mHandle,
			@ref.Value, &mutablePos[0], &height);

		return StatusHelper.FromDtStatus(status);
	}

	/// Queries polygons within bounds.
	public NavStatus QueryPolygons(float[3] center, float[3] halfExtents, NavMeshQueryFilter filter,
		List<PolyRef> polys)
	{
		polys.Clear();

		if (mHandle == null || filter == null)
			return .Failure;

		var mutableCenter = center;
		var mutableHalfExtents = halfExtents;
		dtPolyRef* polyBuffer = scope dtPolyRef[MAX_POLYS]*;
		int32 polyCount = 0;

		let status = dtNavMeshQueryQueryPolygons(mHandle,
			&mutableCenter[0], &mutableHalfExtents[0], filter.Handle,
			polyBuffer, &polyCount, MAX_POLYS);

		for (int32 i = 0; i < polyCount; i++)
			polys.Add(PolyRef(polyBuffer[i]));

		return StatusHelper.FromDtStatus(status);
	}

	/// Finds a random point on the navmesh.
	public NavStatus FindRandomPoint(NavMeshQueryFilter filter, out PolyRef randomRef, out float[3] randomPt)
	{
		randomRef = default;
		randomPt = default;

		if (mHandle == null || filter == null)
			return .Failure;

		dtPolyRef resultRef = 0;
		let status = dtNavMeshQueryFindRandomPoint(mHandle,
			filter.Handle, => DefaultRand, &resultRef, &randomPt[0]);

		randomRef = resultRef;
		return StatusHelper.FromDtStatus(status);
	}

	/// Finds a random point within a circle.
	public NavStatus FindRandomPointAroundCircle(PolyRef startRef, float[3] centerPos, float maxRadius,
		NavMeshQueryFilter filter, out PolyRef randomRef, out float[3] randomPt)
	{
		randomRef = default;
		randomPt = default;

		if (mHandle == null || filter == null)
			return .Failure;

		var mutableCenterPos = centerPos;
		dtPolyRef resultRef = 0;
		let status = dtNavMeshQueryFindRandomPointAroundCircle(mHandle,
			startRef.Value, &mutableCenterPos[0], maxRadius,
			filter.Handle, => DefaultRand, &resultRef, &randomPt[0]);

		randomRef = resultRef;
		return StatusHelper.FromDtStatus(status);
	}

	/// Checks if a polygon reference is valid.
	public bool IsValidPolyRef(PolyRef @ref, NavMeshQueryFilter filter)
	{
		if (mHandle == null || filter == null)
			return false;
		return dtNavMeshQueryIsValidPolyRef(mHandle, @ref.Value, filter.Handle) != 0;
	}

	private static System.Random sRandom = new .() ~ delete _;

	private static float DefaultRand()
	{
		return (float)sRandom.NextDouble();
	}
}
