using System;

namespace recastnavigation_Beef;

/* Constants */
static
{
	public const int32 DT_CROWDAGENT_MAX_NEIGHBOURS = 6;
	public const int32 DT_CROWDAGENT_MAX_CORNERS = 4;
	public const int32 DT_CROWD_MAX_OBSTAVOIDANCE_PARAMS = 8;
	public const int32 DT_CROWD_MAX_QUERY_FILTER_TYPE = 16;
}

/* Opaque handle types */
typealias dtCrowdHandle = void*;
typealias dtObstacleAvoidanceDebugDataHandle = void*;

/* Crowd agent states */
enum dtCrowdAgentState : int32
{
	DT_CROWDAGENT_STATE_INVALID,
	DT_CROWDAGENT_STATE_WALKING,
	DT_CROWDAGENT_STATE_OFFMESH
}

/* Move request states */
enum dtMoveRequestState : int32
{
	DT_CROWDAGENT_TARGET_NONE = 0,
	DT_CROWDAGENT_TARGET_FAILED,
	DT_CROWDAGENT_TARGET_VALID,
	DT_CROWDAGENT_TARGET_REQUESTING,
	DT_CROWDAGENT_TARGET_WAITING_FOR_QUEUE,
	DT_CROWDAGENT_TARGET_WAITING_FOR_PATH,
	DT_CROWDAGENT_TARGET_VELOCITY
}

/* Update flags */
enum dtCrowdUpdateFlags : int32
{
	DT_CROWD_ANTICIPATE_TURNS = 1,
	DT_CROWD_OBSTACLE_AVOIDANCE = 2,
	DT_CROWD_SEPARATION = 4,
	DT_CROWD_OPTIMIZE_VIS = 8,
	DT_CROWD_OPTIMIZE_TOPO = 16
}

/* Crowd neighbor */
[CRepr]
struct dtCrowdNeighbour
{
	public int32 idx;
	public float dist;
}

/* Obstacle avoidance params */
[CRepr]
struct dtObstacleAvoidanceParams
{
	public float velBias;
	public float weightDesVel;
	public float weightCurVel;
	public float weightSide;
	public float weightToi;
	public float horizTime;
	public uint8 gridSize;
	public uint8 adaptiveDivs;
	public uint8 adaptiveRings;
	public uint8 adaptiveDepth;
}

/* Crowd agent params */
[CRepr]
struct dtCrowdAgentParams
{
	public float radius;
	public float height;
	public float maxAcceleration;
	public float maxSpeed;
	public float collisionQueryRange;
	public float pathOptimizationRange;
	public float separationWeight;
	public uint8 updateFlags;
	public uint8 obstacleAvoidanceType;
	public uint8 queryFilterType;
	public void* userData;
}

/* Crowd agent debug info */
[CRepr]
struct dtCrowdAgentDebugInfo
{
	public int32 idx;
	public float[3] optStart;
	public float[3] optEnd;
	public dtObstacleAvoidanceDebugDataHandle vod;
}

/* Functions */
static
{
	/* Crowd management */
	[CLink]
	public static extern dtCrowdHandle C_dtAllocCrowd();
	[CLink]
	public static extern void C_dtFreeCrowd(dtCrowdHandle crowd);

	[CLink]
	public static extern int32 C_dtCrowdInit(dtCrowdHandle crowd, int32 maxAgents, float maxAgentRadius, dtNavMeshHandle nav);

	/* Obstacle avoidance params */
	[CLink]
	public static extern void C_dtCrowdSetObstacleAvoidanceParams(dtCrowdHandle crowd, int32 idx, dtObstacleAvoidanceParams* @params);
	[CLink]
	public static extern dtObstacleAvoidanceParams* C_dtCrowdGetObstacleAvoidanceParams(dtCrowdHandle crowd, int32 idx);

	/* Agent management */
	[CLink]
	public static extern int32 C_dtCrowdAddAgent(dtCrowdHandle crowd, float* pos, dtCrowdAgentParams* @params);
	[CLink]
	public static extern void C_dtCrowdUpdateAgentParameters(dtCrowdHandle crowd, int32 idx, dtCrowdAgentParams* @params);
	[CLink]
	public static extern void C_dtCrowdRemoveAgent(dtCrowdHandle crowd, int32 idx);

	/* Agent queries */
	[CLink]
	public static extern int32 C_dtCrowdGetAgentCount(dtCrowdHandle crowd);

	/* Agent accessors */
	[CLink]
	public static extern int32 C_dtCrowdAgentIsActive(dtCrowdHandle crowd, int32 idx);
	[CLink]
	public static extern uint8 C_dtCrowdAgentGetState(dtCrowdHandle crowd, int32 idx);
	[CLink]
	public static extern int32 C_dtCrowdAgentIsPartial(dtCrowdHandle crowd, int32 idx);
	[CLink]
	public static extern void C_dtCrowdAgentGetPosition(dtCrowdHandle crowd, int32 idx, float* pos);
	[CLink]
	public static extern void C_dtCrowdAgentGetDesiredVelocity(dtCrowdHandle crowd, int32 idx, float* dvel);
	[CLink]
	public static extern void C_dtCrowdAgentGetVelocity(dtCrowdHandle crowd, int32 idx, float* vel);
	[CLink]
	public static extern void C_dtCrowdAgentGetParams(dtCrowdHandle crowd, int32 idx, dtCrowdAgentParams* @params);
	[CLink]
	public static extern int32 C_dtCrowdAgentGetCornerCount(dtCrowdHandle crowd, int32 idx);
	[CLink]
	public static extern void C_dtCrowdAgentGetCornerVerts(dtCrowdHandle crowd, int32 idx, float* verts, int32 maxVerts);
	[CLink]
	public static extern void C_dtCrowdAgentGetCornerFlags(dtCrowdHandle crowd, int32 idx, uint8* flags, int32 maxFlags);
	[CLink]
	public static extern void C_dtCrowdAgentGetCornerPolys(dtCrowdHandle crowd, int32 idx, dtPolyRef* polys, int32 maxPolys);
	[CLink]
	public static extern uint8 C_dtCrowdAgentGetTargetState(dtCrowdHandle crowd, int32 idx);
	[CLink]
	public static extern dtPolyRef C_dtCrowdAgentGetTargetRef(dtCrowdHandle crowd, int32 idx);
	[CLink]
	public static extern void C_dtCrowdAgentGetTargetPos(dtCrowdHandle crowd, int32 idx, float* pos);

	/* Movement requests */
	[CLink]
	public static extern int32 C_dtCrowdRequestMoveTarget(dtCrowdHandle crowd, int32 idx, dtPolyRef @ref, float* pos);
	[CLink]
	public static extern int32 C_dtCrowdRequestMoveVelocity(dtCrowdHandle crowd, int32 idx, float* vel);
	[CLink]
	public static extern int32 C_dtCrowdResetMoveTarget(dtCrowdHandle crowd, int32 idx);

	/* Active agents */
	[CLink]
	public static extern int32 C_dtCrowdGetActiveAgents(dtCrowdHandle crowd, int32* agents, int32 maxAgents);

	/* Update */
	[CLink]
	public static extern void C_dtCrowdUpdate(dtCrowdHandle crowd, float dt, dtCrowdAgentDebugInfo* debug);

	/* Filters */
	[CLink]
	public static extern dtQueryFilterHandle C_dtCrowdGetFilter(dtCrowdHandle crowd, int32 i);
	[CLink]
	public static extern dtQueryFilterHandle C_dtCrowdGetEditableFilter(dtCrowdHandle crowd, int32 i);

	/* Query extents */
	[CLink]
	public static extern void C_dtCrowdGetQueryHalfExtents(dtCrowdHandle crowd, float* halfExtents);

	/* Velocity sample count */
	[CLink]
	public static extern int32 C_dtCrowdGetVelocitySampleCount(dtCrowdHandle crowd);

	/* Obstacle avoidance debug data */
	[CLink]
	public static extern dtObstacleAvoidanceDebugDataHandle C_dtAllocObstacleAvoidanceDebugData();
	[CLink]
	public static extern void C_dtFreeObstacleAvoidanceDebugData(dtObstacleAvoidanceDebugDataHandle ptr);
	[CLink]
	public static extern int32 C_dtObstacleAvoidanceDebugDataInit(dtObstacleAvoidanceDebugDataHandle data, int32 maxSamples);
	[CLink]
	public static extern void C_dtObstacleAvoidanceDebugDataReset(dtObstacleAvoidanceDebugDataHandle data);
	[CLink]
	public static extern int32 C_dtObstacleAvoidanceDebugDataGetSampleCount(dtObstacleAvoidanceDebugDataHandle data);
	[CLink]
	public static extern void C_dtObstacleAvoidanceDebugDataGetSampleVelocity(dtObstacleAvoidanceDebugDataHandle data, int32 i, float* vel);
	[CLink]
	public static extern float C_dtObstacleAvoidanceDebugDataGetSampleSize(dtObstacleAvoidanceDebugDataHandle data, int32 i);
	[CLink]
	public static extern float C_dtObstacleAvoidanceDebugDataGetSamplePenalty(dtObstacleAvoidanceDebugDataHandle data, int32 i);

	/* Wrapper functions */
	public static dtCrowdHandle dtAllocCrowd() => C_dtAllocCrowd();
	public static void dtFreeCrowd(dtCrowdHandle crowd) => C_dtFreeCrowd(crowd);
	public static int32 dtCrowdInit(dtCrowdHandle crowd, int32 maxAgents, float maxAgentRadius, dtNavMeshHandle nav) => C_dtCrowdInit(crowd, maxAgents, maxAgentRadius, nav);
	public static void dtCrowdSetObstacleAvoidanceParams(dtCrowdHandle crowd, int32 idx, dtObstacleAvoidanceParams* @params) => C_dtCrowdSetObstacleAvoidanceParams(crowd, idx, @params);
	public static dtObstacleAvoidanceParams* dtCrowdGetObstacleAvoidanceParams(dtCrowdHandle crowd, int32 idx) => C_dtCrowdGetObstacleAvoidanceParams(crowd, idx);
	public static int32 dtCrowdAddAgent(dtCrowdHandle crowd, float* pos, dtCrowdAgentParams* @params) => C_dtCrowdAddAgent(crowd, pos, @params);
	public static void dtCrowdUpdateAgentParameters(dtCrowdHandle crowd, int32 idx, dtCrowdAgentParams* @params) => C_dtCrowdUpdateAgentParameters(crowd, idx, @params);
	public static void dtCrowdRemoveAgent(dtCrowdHandle crowd, int32 idx) => C_dtCrowdRemoveAgent(crowd, idx);
	public static int32 dtCrowdGetAgentCount(dtCrowdHandle crowd) => C_dtCrowdGetAgentCount(crowd);
	public static int32 dtCrowdAgentIsActive(dtCrowdHandle crowd, int32 idx) => C_dtCrowdAgentIsActive(crowd, idx);
	public static uint8 dtCrowdAgentGetState(dtCrowdHandle crowd, int32 idx) => C_dtCrowdAgentGetState(crowd, idx);
	public static int32 dtCrowdAgentIsPartial(dtCrowdHandle crowd, int32 idx) => C_dtCrowdAgentIsPartial(crowd, idx);
	public static void dtCrowdAgentGetPosition(dtCrowdHandle crowd, int32 idx, float* pos) => C_dtCrowdAgentGetPosition(crowd, idx, pos);
	public static void dtCrowdAgentGetDesiredVelocity(dtCrowdHandle crowd, int32 idx, float* dvel) => C_dtCrowdAgentGetDesiredVelocity(crowd, idx, dvel);
	public static void dtCrowdAgentGetVelocity(dtCrowdHandle crowd, int32 idx, float* vel) => C_dtCrowdAgentGetVelocity(crowd, idx, vel);
	public static void dtCrowdAgentGetParams(dtCrowdHandle crowd, int32 idx, dtCrowdAgentParams* @params) => C_dtCrowdAgentGetParams(crowd, idx, @params);
	public static int32 dtCrowdAgentGetCornerCount(dtCrowdHandle crowd, int32 idx) => C_dtCrowdAgentGetCornerCount(crowd, idx);
	public static void dtCrowdAgentGetCornerVerts(dtCrowdHandle crowd, int32 idx, float* verts, int32 maxVerts) => C_dtCrowdAgentGetCornerVerts(crowd, idx, verts, maxVerts);
	public static void dtCrowdAgentGetCornerFlags(dtCrowdHandle crowd, int32 idx, uint8* flags, int32 maxFlags) => C_dtCrowdAgentGetCornerFlags(crowd, idx, flags, maxFlags);
	public static void dtCrowdAgentGetCornerPolys(dtCrowdHandle crowd, int32 idx, dtPolyRef* polys, int32 maxPolys) => C_dtCrowdAgentGetCornerPolys(crowd, idx, polys, maxPolys);
	public static uint8 dtCrowdAgentGetTargetState(dtCrowdHandle crowd, int32 idx) => C_dtCrowdAgentGetTargetState(crowd, idx);
	public static dtPolyRef dtCrowdAgentGetTargetRef(dtCrowdHandle crowd, int32 idx) => C_dtCrowdAgentGetTargetRef(crowd, idx);
	public static void dtCrowdAgentGetTargetPos(dtCrowdHandle crowd, int32 idx, float* pos) => C_dtCrowdAgentGetTargetPos(crowd, idx, pos);
	public static int32 dtCrowdRequestMoveTarget(dtCrowdHandle crowd, int32 idx, dtPolyRef @ref, float* pos) => C_dtCrowdRequestMoveTarget(crowd, idx, @ref, pos);
	public static int32 dtCrowdRequestMoveVelocity(dtCrowdHandle crowd, int32 idx, float* vel) => C_dtCrowdRequestMoveVelocity(crowd, idx, vel);
	public static int32 dtCrowdResetMoveTarget(dtCrowdHandle crowd, int32 idx) => C_dtCrowdResetMoveTarget(crowd, idx);
	public static int32 dtCrowdGetActiveAgents(dtCrowdHandle crowd, int32* agents, int32 maxAgents) => C_dtCrowdGetActiveAgents(crowd, agents, maxAgents);
	public static void dtCrowdUpdate(dtCrowdHandle crowd, float dt, dtCrowdAgentDebugInfo* debug) => C_dtCrowdUpdate(crowd, dt, debug);
	public static dtQueryFilterHandle dtCrowdGetFilter(dtCrowdHandle crowd, int32 i) => C_dtCrowdGetFilter(crowd, i);
	public static dtQueryFilterHandle dtCrowdGetEditableFilter(dtCrowdHandle crowd, int32 i) => C_dtCrowdGetEditableFilter(crowd, i);
	public static void dtCrowdGetQueryHalfExtents(dtCrowdHandle crowd, float* halfExtents) => C_dtCrowdGetQueryHalfExtents(crowd, halfExtents);
	public static int32 dtCrowdGetVelocitySampleCount(dtCrowdHandle crowd) => C_dtCrowdGetVelocitySampleCount(crowd);
	public static dtObstacleAvoidanceDebugDataHandle dtAllocObstacleAvoidanceDebugData() => C_dtAllocObstacleAvoidanceDebugData();
	public static void dtFreeObstacleAvoidanceDebugData(dtObstacleAvoidanceDebugDataHandle ptr) => C_dtFreeObstacleAvoidanceDebugData(ptr);
	public static int32 dtObstacleAvoidanceDebugDataInit(dtObstacleAvoidanceDebugDataHandle data, int32 maxSamples) => C_dtObstacleAvoidanceDebugDataInit(data, maxSamples);
	public static void dtObstacleAvoidanceDebugDataReset(dtObstacleAvoidanceDebugDataHandle data) => C_dtObstacleAvoidanceDebugDataReset(data);
	public static int32 dtObstacleAvoidanceDebugDataGetSampleCount(dtObstacleAvoidanceDebugDataHandle data) => C_dtObstacleAvoidanceDebugDataGetSampleCount(data);
	public static void dtObstacleAvoidanceDebugDataGetSampleVelocity(dtObstacleAvoidanceDebugDataHandle data, int32 i, float* vel) => C_dtObstacleAvoidanceDebugDataGetSampleVelocity(data, i, vel);
	public static float dtObstacleAvoidanceDebugDataGetSampleSize(dtObstacleAvoidanceDebugDataHandle data, int32 i) => C_dtObstacleAvoidanceDebugDataGetSampleSize(data, i);
	public static float dtObstacleAvoidanceDebugDataGetSamplePenalty(dtObstacleAvoidanceDebugDataHandle data, int32 i) => C_dtObstacleAvoidanceDebugDataGetSamplePenalty(data, i);
}
