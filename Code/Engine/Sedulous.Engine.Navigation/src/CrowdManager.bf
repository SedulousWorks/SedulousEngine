namespace Sedulous.Engine.Navigation;

using System;
using recastnavigation_Beef;

/// Wrapper for Detour crowd manager.
class CrowdManager
{
	private dtCrowdHandle mHandle;
	private bool mOwnsHandle;

	/// Creates a new CrowdManager.
	public this()
	{
		mHandle = dtAllocCrowd();
		mOwnsHandle = true;
	}

	/// Creates a wrapper around an existing handle.
	public this(dtCrowdHandle handle, bool ownsHandle = false)
	{
		mHandle = handle;
		mOwnsHandle = ownsHandle;
	}

	public ~this()
	{
		if (mOwnsHandle && mHandle != null)
		{
			dtFreeCrowd(mHandle);
			mHandle = null;
		}
	}

	/// Gets the underlying handle.
	public dtCrowdHandle Handle => mHandle;

	/// Initializes the crowd with a navmesh.
	public bool Init(NavMesh navMesh, int32 maxAgents, float maxAgentRadius = 0.6f)
	{
		if (mHandle == null || navMesh == null)
			return false;

		return dtCrowdInit(mHandle, maxAgents, maxAgentRadius, navMesh.Handle) != 0;
	}

	/// Gets the number of agents.
	public int32 AgentCount
	{
		get
		{
			if (mHandle == null)
				return 0;
			return dtCrowdGetAgentCount(mHandle);
		}
	}

	/// Adds an agent at the specified position.
	public int32 AddAgent(float[3] pos, in CrowdAgentParams @params)
	{
		if (mHandle == null)
			return -1;

		var mutablePos = pos;

		// Convert to dtCrowdAgentParams
		dtCrowdAgentParams dtParams = .() {
			radius = @params.Radius,
			height = @params.Height,
			maxAcceleration = @params.MaxAcceleration,
			maxSpeed = @params.MaxSpeed,
			collisionQueryRange = @params.CollisionQueryRange,
			pathOptimizationRange = @params.PathOptimizationRange,
			separationWeight = @params.SeparationWeight,
			updateFlags = @params.UpdateFlags,
			obstacleAvoidanceType = @params.ObstacleAvoidanceType,
			queryFilterType = @params.QueryFilterType,
			userData = @params.UserData
		};

		return dtCrowdAddAgent(mHandle, &mutablePos[0], &dtParams);
	}

	/// Updates an agent's parameters.
	public void UpdateAgentParameters(int32 idx, in CrowdAgentParams @params)
	{
		if (mHandle == null)
			return;

		dtCrowdAgentParams dtParams = .() {
			radius = @params.Radius,
			height = @params.Height,
			maxAcceleration = @params.MaxAcceleration,
			maxSpeed = @params.MaxSpeed,
			collisionQueryRange = @params.CollisionQueryRange,
			pathOptimizationRange = @params.PathOptimizationRange,
			separationWeight = @params.SeparationWeight,
			updateFlags = @params.UpdateFlags,
			obstacleAvoidanceType = @params.ObstacleAvoidanceType,
			queryFilterType = @params.QueryFilterType,
			userData = @params.UserData
		};

		dtCrowdUpdateAgentParameters(mHandle, idx, &dtParams);
	}

	/// Removes an agent.
	public void RemoveAgent(int32 idx)
	{
		if (mHandle != null)
			dtCrowdRemoveAgent(mHandle, idx);
	}

	/// Checks if an agent is active.
	public bool IsAgentActive(int32 idx)
	{
		if (mHandle == null)
			return false;
		return dtCrowdAgentIsActive(mHandle, idx) != 0;
	}

	/// Gets an agent's state.
	public dtCrowdAgentState GetAgentState(int32 idx)
	{
		if (mHandle == null)
			return .DT_CROWDAGENT_STATE_INVALID;
		return (dtCrowdAgentState)dtCrowdAgentGetState(mHandle, idx);
	}

	/// Gets an agent's position.
	public void GetAgentPosition(int32 idx, out float[3] pos)
	{
		pos = default;
		if (mHandle != null)
			dtCrowdAgentGetPosition(mHandle, idx, &pos[0]);
	}

	/// Gets an agent's velocity.
	public void GetAgentVelocity(int32 idx, out float[3] vel)
	{
		vel = default;
		if (mHandle != null)
			dtCrowdAgentGetVelocity(mHandle, idx, &vel[0]);
	}

	/// Gets an agent's desired velocity.
	public void GetAgentDesiredVelocity(int32 idx, out float[3] dvel)
	{
		dvel = default;
		if (mHandle != null)
			dtCrowdAgentGetDesiredVelocity(mHandle, idx, &dvel[0]);
	}

	/// Gets an agent's parameters.
	public void GetAgentParams(int32 idx, out CrowdAgentParams @params)
	{
		@params = default;
		if (mHandle == null)
			return;

		dtCrowdAgentParams dtParams = default;
		dtCrowdAgentGetParams(mHandle, idx, &dtParams);

		@params = .() {
			Radius = dtParams.radius,
			Height = dtParams.height,
			MaxAcceleration = dtParams.maxAcceleration,
			MaxSpeed = dtParams.maxSpeed,
			CollisionQueryRange = dtParams.collisionQueryRange,
			PathOptimizationRange = dtParams.pathOptimizationRange,
			SeparationWeight = dtParams.separationWeight,
			UpdateFlags = dtParams.updateFlags,
			ObstacleAvoidanceType = dtParams.obstacleAvoidanceType,
			QueryFilterType = dtParams.queryFilterType,
			UserData = dtParams.userData
		};
	}

	/// Gets the number of corners in an agent's path.
	public int32 GetAgentCornerCount(int32 idx)
	{
		if (mHandle == null)
			return 0;
		return dtCrowdAgentGetCornerCount(mHandle, idx);
	}

	/// Gets an agent's corner vertices.
	public void GetAgentCornerVerts(int32 idx, float* verts, int32 maxVerts)
	{
		if (mHandle != null)
			dtCrowdAgentGetCornerVerts(mHandle, idx, verts, maxVerts);
	}

	/// Gets an agent's target state.
	public dtMoveRequestState GetAgentTargetState(int32 idx)
	{
		if (mHandle == null)
			return .DT_CROWDAGENT_TARGET_NONE;
		return (dtMoveRequestState)dtCrowdAgentGetTargetState(mHandle, idx);
	}

	/// Gets an agent's target position.
	public void GetAgentTargetPos(int32 idx, out float[3] pos)
	{
		pos = default;
		if (mHandle != null)
			dtCrowdAgentGetTargetPos(mHandle, idx, &pos[0]);
	}

	/// Requests a move target for an agent.
	public bool RequestMoveTarget(int32 idx, PolyRef @ref, float[3] pos)
	{
		if (mHandle == null)
			return false;
		var mutablePos = pos;
		return dtCrowdRequestMoveTarget(mHandle, idx, @ref.Value, &mutablePos[0]) != 0;
	}

	/// Requests a move velocity for an agent.
	public bool RequestMoveVelocity(int32 idx, float[3] vel)
	{
		if (mHandle == null)
			return false;
		var mutableVel = vel;
		return dtCrowdRequestMoveVelocity(mHandle, idx, &mutableVel[0]) != 0;
	}

	/// Resets an agent's move target.
	public bool ResetMoveTarget(int32 idx)
	{
		if (mHandle == null)
			return false;
		return dtCrowdResetMoveTarget(mHandle, idx) != 0;
	}

	/// Updates the crowd simulation.
	public void Update(float dt, dtCrowdAgentDebugInfo* debug = null)
	{
		if (mHandle != null)
			dtCrowdUpdate(mHandle, dt, debug);
	}

	/// Gets the query half extents.
	public void GetQueryHalfExtents(out float[3] halfExtents)
	{
		halfExtents = default;
		if (mHandle != null)
			dtCrowdGetQueryHalfExtents(mHandle, &halfExtents[0]);
	}

	/// Gets a query filter.
	public dtQueryFilterHandle GetFilter(int32 i)
	{
		if (mHandle == null)
			return null;
		return dtCrowdGetFilter(mHandle, i);
	}

	/// Gets an editable query filter.
	public dtQueryFilterHandle GetEditableFilter(int32 i)
	{
		if (mHandle == null)
			return null;
		return dtCrowdGetEditableFilter(mHandle, i);
	}

	/// Sets obstacle avoidance parameters.
	public void SetObstacleAvoidanceParams(int32 idx, dtObstacleAvoidanceParams* @params)
	{
		if (mHandle != null)
			dtCrowdSetObstacleAvoidanceParams(mHandle, idx, @params);
	}

	/// Gets obstacle avoidance parameters.
	public dtObstacleAvoidanceParams* GetObstacleAvoidanceParams(int32 idx)
	{
		if (mHandle == null)
			return null;
		return dtCrowdGetObstacleAvoidanceParams(mHandle, idx);
	}
}
