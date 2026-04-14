namespace Sedulous.Engine.Navigation;

using System;
using System.Collections;
using recastnavigation_Beef;

/// Owns and manages all navigation state for a scene: the navmesh,
/// pathfinding queries, crowd agents, and dynamic obstacles.
class NavWorld
{
	private NavMesh mNavMesh ~ delete _;
	private NavMeshQuery mQuery ~ delete _;
	private NavMeshQueryFilter mFilter ~ delete _;
	private CrowdManager mCrowd ~ delete _;
	private TileCache mTileCache ~ delete _;

	private int32 mMaxAgents;

	/// The navigation mesh.
	public NavMesh NavMesh => mNavMesh;

	/// The crowd manager for agent simulation.
	public CrowdManager Crowd => mCrowd;

	/// The query object for pathfinding.
	public NavMeshQuery Query => mQuery;

	/// The default query filter.
	public NavMeshQueryFilter Filter => mFilter;

	/// The tile cache for dynamic obstacles (null if no navmesh set).
	public TileCache TileCache => mTileCache;

	/// Creates a NavWorld with the specified capacity.
	public this(int32 maxAgents = 128)
	{
		mMaxAgents = maxAgents;
		mFilter = new NavMeshQueryFilter();
	}

	/// Sets or replaces the navigation mesh. Re-initializes the query and crowd.
	public void SetNavMesh(NavMesh navMesh)
	{
		// Clean up old state
		if (mCrowd != null)
		{
			delete mCrowd;
			mCrowd = null;
		}
		if (mQuery != null)
		{
			delete mQuery;
			mQuery = null;
		}
		if (mTileCache != null)
		{
			delete mTileCache;
			mTileCache = null;
		}
		if (mNavMesh != null)
			delete mNavMesh;

		mNavMesh = navMesh;

		if (mNavMesh != null)
		{
			// Initialize query
			mQuery = new NavMeshQuery();
			mQuery.Init(mNavMesh);

			// Initialize crowd
			mCrowd = new CrowdManager();
			mCrowd.Init(mNavMesh, mMaxAgents);
		}
	}

	/// Sets the navigation mesh and TileCache together (for tiled builds with dynamic obstacle support).
	public void SetNavMeshWithTileCache(NavMesh navMesh, TileCache tileCache)
	{
		// Clean up old state
		if (mCrowd != null)
		{
			delete mCrowd;
			mCrowd = null;
		}
		if (mQuery != null)
		{
			delete mQuery;
			mQuery = null;
		}
		if (mTileCache != null)
		{
			delete mTileCache;
			mTileCache = null;
		}
		if (mNavMesh != null)
			delete mNavMesh;

		mNavMesh = navMesh;
		mTileCache = tileCache;

		if (mNavMesh != null)
		{
			// Initialize query
			mQuery = new NavMeshQuery();
			mQuery.Init(mNavMesh);

			// Initialize crowd
			mCrowd = new CrowdManager();
			mCrowd.Init(mNavMesh, mMaxAgents);
		}

		// Connect TileCache to NavMesh
		if (mTileCache != null)
			mTileCache.SetNavMesh(mNavMesh);
	}

	/// Adds a crowd agent at the given position.
	/// Returns the agent index, or -1 on failure.
	public int32 AddAgent(float[3] position, in CrowdAgentParams @params)
	{
		if (mCrowd == null)
			return -1;
		return mCrowd.AddAgent(position, @params);
	}

	/// Removes a crowd agent by index.
	public void RemoveAgent(int32 agentIndex)
	{
		if (mCrowd != null)
			mCrowd.RemoveAgent(agentIndex);
	}

	/// Sets the move target for an agent. Finds the nearest poly automatically.
	/// Returns true if the target was set successfully.
	public bool RequestMoveTarget(int32 agentIndex, float[3] targetPos)
	{
		if (mCrowd == null || mQuery == null)
			return false;

		float[3] halfExtents = .(2.0f, 4.0f, 2.0f);
		PolyRef nearestRef;
		float[3] nearestPoint;

		if (mQuery.FindNearestPoly(targetPos, halfExtents, mFilter, out nearestRef, out nearestPoint) != .Success)
			return false;

		if (!nearestRef.IsValid)
			return false;

		return mCrowd.RequestMoveTarget(agentIndex, nearestRef, nearestPoint);
	}

	/// Returns whether this NavWorld has TileCache support for dynamic obstacles.
	public bool HasTileCacheSupport => mTileCache != null;

	/// Adds a cylindrical obstacle at the given position.
	/// Returns the obstacle ID, or -1 on failure.
	public int32 AddObstacle(float[3] position, float radius, float height)
	{
		if (mTileCache == null)
			return -1;

		int32 obstacleId;
		if (mTileCache.AddObstacle(position, radius, height, out obstacleId) != .Success)
			return -1;

		return obstacleId;
	}

	/// Removes a dynamic obstacle by ID.
	public void RemoveObstacle(int32 obstacleId)
	{
		if (mTileCache != null)
			mTileCache.RemoveObstacle(obstacleId);
	}

	/// Steps the crowd simulation and processes pending obstacle updates.
	public void Update(float dt)
	{
		if (mTileCache != null)
			mTileCache.Update();

		if (mCrowd != null)
			mCrowd.Update(dt);
	}

	/// Convenience: finds a path between two world positions.
	/// Returns true if a path was found, with waypoints as [x,y,z,...] in outWaypoints.
	public bool FindPath(float[3] start, float[3] end, List<float> outWaypoints)
	{
		outWaypoints.Clear();

		if (mQuery == null)
			return false;

		float[3] halfExtents = .(2.0f, 4.0f, 2.0f);

		PolyRef startRef, endRef;
		float[3] startPoint, endPoint;

		if (mQuery.FindNearestPoly(start, halfExtents, mFilter, out startRef, out startPoint) != .Success)
			return false;
		if (mQuery.FindNearestPoly(end, halfExtents, mFilter, out endRef, out endPoint) != .Success)
			return false;

		if (!startRef.IsValid || !endRef.IsValid)
			return false;

		// Find polygon path
		let polyPath = scope List<PolyRef>();
		if (mQuery.FindPath(startRef, endRef, startPoint, endPoint, mFilter, polyPath) != .Success)
			return false;

		if (polyPath.Count == 0)
			return false;

		// Convert to straight path (waypoints)
		let straightPathFlags = scope List<StraightPathFlags>();
		let straightPathRefs = scope List<PolyRef>();

		if (mQuery.FindStraightPath(startPoint, endPoint, polyPath,
			outWaypoints, straightPathFlags, straightPathRefs) != .Success)
			return false;

		return outWaypoints.Count >= 3; // At least one point (3 floats)
	}

	/// Gets the position of an agent.
	public bool GetAgentPosition(int32 agentIndex, out float[3] position)
	{
		position = default;
		if (mCrowd == null)
			return false;

		if (!mCrowd.IsAgentActive(agentIndex))
			return false;

		mCrowd.GetAgentPosition(agentIndex, out position);
		return true;
	}
}
