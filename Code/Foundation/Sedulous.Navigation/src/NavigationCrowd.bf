using System;
using Sedulous.Core;
using recastnavigation_Beef;

namespace Sedulous.Navigation;

/// A crowd bound to ONE mesh: agents steer toward their own targets and avoid one another.
///
/// The mesh is BORROWED and must outlive the crowd. One crowd per mesh, because the backend
/// builds its internal query against a single one.
class NavigationCrowd
{
	/// How far around itself an agent looks for neighbours, and how far ahead it optimises
	/// its corridor, both as multiples of its own radius.
	private const float cCollisionQueryRadii = 12.0f;
	private const float cPathOptimizationRadii = 30.0f;
	/// How hard agents push apart, and which of the backend's avoidance presets they use.
	private const float cSeparationWeight = 2.0f;
	private const uint8 cObstacleAvoidanceType = 3;

	private dtCrowdHandle mCrowd = default;

	public this(NavigationMesh mesh, int32 maxAgents, float maxAgentRadius)
	{
		if ((mesh == null) || !mesh.IsValid || (maxAgents <= 0))
			return;

		let crowd = C_dtAllocCrowd();
		if (crowd == default)
			return;

		let radius = (maxAgentRadius > 0.0f) ? maxAgentRadius : 0.6f;
		if (C_dtCrowdInit(crowd, maxAgents, radius, mesh.NativeHandle) == 0)
		{
			C_dtFreeCrowd(crowd);
			return;
		}
		mCrowd = crowd;
	}

	public ~this()
	{
		if (mCrowd != default)
			C_dtFreeCrowd(mCrowd);
	}

	public bool IsValid => mCrowd != default;

	/// Adds an agent, SNAPPED to the nearest polygon. Minus one when the crowd is full, the
	/// spawn is off the mesh, or the crowd itself never came up.
	public int32 AddAgent(Float3 position, NavigationAgentParams parameters)
	{
		if (mCrowd == default)
			return -1;

		var ap = dtCrowdAgentParams();
		FillParams(ref ap, parameters);
		ap.separationWeight = cSeparationWeight;
		ap.obstacleAvoidanceType = cObstacleAvoidanceType;
		ap.updateFlags = (uint8)((int32)dtCrowdUpdateFlags.DT_CROWD_ANTICIPATE_TURNS
			| (int32)dtCrowdUpdateFlags.DT_CROWD_OPTIMIZE_VIS
			| (int32)dtCrowdUpdateFlags.DT_CROWD_OPTIMIZE_TOPO
			| (int32)dtCrowdUpdateFlags.DT_CROWD_OBSTACLE_AVOIDANCE
			| (int32)dtCrowdUpdateFlags.DT_CROWD_SEPARATION);

		float[3] pos = .(position.X, position.Y, position.Z);
		return C_dtCrowdAddAgent(mCrowd, &pos[0], &ap);
	}

	public void RemoveAgent(int32 agentId)
	{
		if ((mCrowd != default) && (agentId >= 0))
			C_dtCrowdRemoveAgent(mCrowd, agentId);
	}

	/// Updates a LIVE agent's steering profile without removing and re-adding it, which is how
	/// a speed changes mid stride.
	///
	/// The flags and the avoidance preset the add configured are KEPT: only what the profile
	/// names is written.
	public void SetAgentParams(int32 agentId, NavigationAgentParams parameters)
	{
		if (!IsAgentValid(agentId))
			return;

		var ap = dtCrowdAgentParams();
		C_dtCrowdAgentGetParams(mCrowd, agentId, &ap);
		FillParams(ref ap, parameters);
		C_dtCrowdUpdateAgentParameters(mCrowd, agentId, &ap);
	}

	private static void FillParams(ref dtCrowdAgentParams ap, NavigationAgentParams parameters)
	{
		ap.radius = parameters.Radius;
		ap.height = parameters.Height;
		ap.maxSpeed = parameters.MaxSpeed;
		ap.maxAcceleration = parameters.MaxAcceleration;
		// Both ranges scale with the agent, so a large one looks further ahead than a small
		// one rather than every agent sharing one distance.
		ap.collisionQueryRange = parameters.Radius * cCollisionQueryRadii;
		ap.pathOptimizationRange = parameters.Radius * cPathOptimizationRadii;
	}

	/// Steers an agent toward a target, SNAPPED to the nearest polygon. False when the agent
	/// is not live or the target has no polygon within the search box.
	public bool SetTarget(int32 agentId, Float3 target)
	{
		if ((mCrowd == default) || (agentId < 0))
			return false;

		// The CROWD'S OWN query and filter, so the snap lands on exactly the polygon the crowd
		// will then steer against: a separate query could round differently at a tile seam.
		let query = C_dtCrowdGetNavMeshQuery(mCrowd);
		let filter = C_dtCrowdGetFilter(mCrowd, 0);
		if ((query == default) || (filter == default))
			return false;

		float[3] halfExtents = .();
		C_dtCrowdGetQueryHalfExtents(mCrowd, &halfExtents[0]);

		float[3] pos = .(target.X, target.Y, target.Z);
		float[3] nearest = .();
		dtPolyRef reference = 0;
		let status = C_dtNavMeshQueryFindNearestPoly(query, &pos[0], &halfExtents[0], filter,
			&reference, &nearest[0]);
		if ((C_dtStatusFailed(status) != 0) || (reference == 0))
			return false;

		return C_dtCrowdRequestMoveTarget(mCrowd, agentId, reference, &nearest[0]) != 0;
	}

	public void ClearTarget(int32 agentId)
	{
		if ((mCrowd != default) && (agentId >= 0))
			C_dtCrowdResetMoveTarget(mCrowd, agentId);
	}

	/// A step of no time is skipped: the backend divides by it.
	public void Update(float deltaTime)
	{
		if ((mCrowd != default) && (deltaTime > 0.0f))
			C_dtCrowdUpdate(mCrowd, deltaTime, null);
	}

	public bool IsAgentValid(int32 agentId)
	{
		if ((mCrowd == default) || (agentId < 0))
			return false;
		return C_dtCrowdAgentIsActive(mCrowd, agentId) != 0;
	}

	public Float3 AgentPosition(int32 agentId)
	{
		if (!IsAgentValid(agentId))
			return .(0, 0, 0);
		float[3] pos = .();
		C_dtCrowdAgentGetPosition(mCrowd, agentId, &pos[0]);
		return .(pos[0], pos[1], pos[2]);
	}

	public Float3 AgentVelocity(int32 agentId)
	{
		if (!IsAgentValid(agentId))
			return .(0, 0, 0);
		float[3] vel = .();
		C_dtCrowdAgentGetVelocity(mCrowd, agentId, &vel[0]);
		return .(vel[0], vel[1], vel[2]);
	}

	/// The agent's internals, remapped onto OUR stable contract: the state machine, how far
	/// its move request has got, what speed the crowd intends, and how much path is left.
	///
	/// This is the debugging window into why an agent is or is not moving.
	public NavigationAgentState AgentState(int32 agentId)
	{
		var state = NavigationAgentState();
		if (!IsAgentValid(agentId))
			return state;

		state.Valid = true;

		switch ((dtCrowdAgentState)C_dtCrowdAgentGetState(mCrowd, agentId))
		{
		case .DT_CROWDAGENT_STATE_WALKING: state.State = .Walking;
		case .DT_CROWDAGENT_STATE_OFFMESH: state.State = .OffMesh;
		default: state.State = .Invalid;
		}

		switch ((dtMoveRequestState)C_dtCrowdAgentGetTargetState(mCrowd, agentId))
		{
		case .DT_CROWDAGENT_TARGET_NONE: state.TargetState = .None;
		case .DT_CROWDAGENT_TARGET_VALID: state.TargetState = .Valid;
		case .DT_CROWDAGENT_TARGET_VELOCITY: state.TargetState = .Velocity;
		case .DT_CROWDAGENT_TARGET_FAILED: state.TargetState = .Failed;
		// Requesting, waiting for the queue and waiting for the path are all IN FLIGHT: the
		// difference between them is the backend's business rather than a caller's.
		default: state.TargetState = .Requesting;
		}

		state.DesiredSpeed = C_dtCrowdAgentGetDesiredSpeed(mCrowd, agentId);
		state.CornerCount = C_dtCrowdAgentGetCornerCount(mCrowd, agentId);
		return state;
	}
}
