/*
 * DetourCrowd C API
 * C interface for the Detour crowd simulation library
 */

#ifndef DETOUR_CROWD_C_H
#define DETOUR_CROWD_C_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) && !defined(DETOURCROWD_C_STATIC)
    #ifdef DETOURCROWD_C_EXPORTS
        #define DETOURCROWD_C_API __declspec(dllexport)
    #else
        #define DETOURCROWD_C_API __declspec(dllimport)
    #endif
#else
    #define DETOURCROWD_C_API
#endif

/* Forward declarations from Detour */
typedef unsigned int C_dtPolyRef;
typedef struct dtNavMesh_s* dtNavMeshHandle;
typedef struct dtQueryFilter_s* dtQueryFilterHandle;

/* Constants */
#define C_DT_CROWDAGENT_MAX_NEIGHBOURS 6
#define C_DT_CROWDAGENT_MAX_CORNERS 4
#define C_DT_CROWD_MAX_OBSTAVOIDANCE_PARAMS 8
#define C_DT_CROWD_MAX_QUERY_FILTER_TYPE 16

/* Crowd agent states */
typedef enum C_CrowdAgentState {
    C_DT_CROWDAGENT_STATE_INVALID,
    C_DT_CROWDAGENT_STATE_WALKING,
    C_DT_CROWDAGENT_STATE_OFFMESH
} C_CrowdAgentState;

/* Move request states */
typedef enum C_MoveRequestState {
    C_DT_CROWDAGENT_TARGET_NONE = 0,
    C_DT_CROWDAGENT_TARGET_FAILED,
    C_DT_CROWDAGENT_TARGET_VALID,
    C_DT_CROWDAGENT_TARGET_REQUESTING,
    C_DT_CROWDAGENT_TARGET_WAITING_FOR_QUEUE,
    C_DT_CROWDAGENT_TARGET_WAITING_FOR_PATH,
    C_DT_CROWDAGENT_TARGET_VELOCITY
} C_MoveRequestState;

/* Update flags */
typedef enum C_dtCrowdUpdateFlags {
    C_DT_CROWD_ANTICIPATE_TURNS = 1,
    C_DT_CROWD_OBSTACLE_AVOIDANCE = 2,
    C_DT_CROWD_SEPARATION = 4,
    C_DT_CROWD_OPTIMIZE_VIS = 8,
    C_DT_CROWD_OPTIMIZE_TOPO = 16
} C_dtCrowdUpdateFlags;

/* Opaque handles */
typedef struct dtCrowd_s* dtCrowdHandle;
typedef struct dtObstacleAvoidanceDebugData_s* dtObstacleAvoidanceDebugDataHandle;

/* Crowd neighbor */
typedef struct C_dtCrowdNeighbour {
    int idx;
    float dist;
} C_dtCrowdNeighbour;

/* Obstacle avoidance params */
typedef struct C_dtObstacleAvoidanceParams {
    float velBias;
    float weightDesVel;
    float weightCurVel;
    float weightSide;
    float weightToi;
    float horizTime;
    unsigned char gridSize;
    unsigned char adaptiveDivs;
    unsigned char adaptiveRings;
    unsigned char adaptiveDepth;
} C_dtObstacleAvoidanceParams;

/* Crowd agent params */
typedef struct C_dtCrowdAgentParams {
    float radius;
    float height;
    float maxAcceleration;
    float maxSpeed;
    float collisionQueryRange;
    float pathOptimizationRange;
    float separationWeight;
    unsigned char updateFlags;
    unsigned char obstacleAvoidanceType;
    unsigned char queryFilterType;
    void* userData;
} C_dtCrowdAgentParams;

/* Crowd agent debug info */
typedef struct C_dtCrowdAgentDebugInfo {
    int idx;
    float optStart[3];
    float optEnd[3];
    dtObstacleAvoidanceDebugDataHandle vod;
} C_dtCrowdAgentDebugInfo;

/* Crowd management */
DETOURCROWD_C_API dtCrowdHandle C_dtAllocCrowd(void);
DETOURCROWD_C_API void C_dtFreeCrowd(dtCrowdHandle crowd);

DETOURCROWD_C_API int C_dtCrowdInit(dtCrowdHandle crowd, int maxAgents, float maxAgentRadius, dtNavMeshHandle nav);

/* Obstacle avoidance params */
DETOURCROWD_C_API void C_dtCrowdSetObstacleAvoidanceParams(dtCrowdHandle crowd, int idx, const C_dtObstacleAvoidanceParams* params);
DETOURCROWD_C_API const C_dtObstacleAvoidanceParams* C_dtCrowdGetObstacleAvoidanceParams(dtCrowdHandle crowd, int idx);

/* Agent management */
DETOURCROWD_C_API int C_dtCrowdAddAgent(dtCrowdHandle crowd, const float* pos, const C_dtCrowdAgentParams* params);
DETOURCROWD_C_API void C_dtCrowdUpdateAgentParameters(dtCrowdHandle crowd, int idx, const C_dtCrowdAgentParams* params);
DETOURCROWD_C_API void C_dtCrowdRemoveAgent(dtCrowdHandle crowd, int idx);

/* Agent queries */
DETOURCROWD_C_API int C_dtCrowdGetAgentCount(dtCrowdHandle crowd);

/* Agent accessors - since dtCrowdAgent contains complex types, we provide individual accessors */
DETOURCROWD_C_API int C_dtCrowdAgentIsActive(dtCrowdHandle crowd, int idx);
DETOURCROWD_C_API unsigned char C_dtCrowdAgentGetState(dtCrowdHandle crowd, int idx);
DETOURCROWD_C_API int C_dtCrowdAgentIsPartial(dtCrowdHandle crowd, int idx);
DETOURCROWD_C_API void C_dtCrowdAgentGetPosition(dtCrowdHandle crowd, int idx, float* pos);
DETOURCROWD_C_API void C_dtCrowdAgentGetDesiredVelocity(dtCrowdHandle crowd, int idx, float* dvel);
DETOURCROWD_C_API void C_dtCrowdAgentGetVelocity(dtCrowdHandle crowd, int idx, float* vel);
DETOURCROWD_C_API void C_dtCrowdAgentGetParams(dtCrowdHandle crowd, int idx, C_dtCrowdAgentParams* params);
DETOURCROWD_C_API int C_dtCrowdAgentGetCornerCount(dtCrowdHandle crowd, int idx);
DETOURCROWD_C_API void C_dtCrowdAgentGetCornerVerts(dtCrowdHandle crowd, int idx, float* verts, int maxVerts);
DETOURCROWD_C_API void C_dtCrowdAgentGetCornerFlags(dtCrowdHandle crowd, int idx, unsigned char* flags, int maxFlags);
DETOURCROWD_C_API void C_dtCrowdAgentGetCornerPolys(dtCrowdHandle crowd, int idx, C_dtPolyRef* polys, int maxPolys);
DETOURCROWD_C_API unsigned char C_dtCrowdAgentGetTargetState(dtCrowdHandle crowd, int idx);
DETOURCROWD_C_API C_dtPolyRef C_dtCrowdAgentGetTargetRef(dtCrowdHandle crowd, int idx);
DETOURCROWD_C_API void C_dtCrowdAgentGetTargetPos(dtCrowdHandle crowd, int idx, float* pos);

/* Movement requests */
DETOURCROWD_C_API int C_dtCrowdRequestMoveTarget(dtCrowdHandle crowd, int idx, C_dtPolyRef ref, const float* pos);
DETOURCROWD_C_API int C_dtCrowdRequestMoveVelocity(dtCrowdHandle crowd, int idx, const float* vel);
DETOURCROWD_C_API int C_dtCrowdResetMoveTarget(dtCrowdHandle crowd, int idx);

/* Active agents */
DETOURCROWD_C_API int C_dtCrowdGetActiveAgents(dtCrowdHandle crowd, int* agents, int maxAgents);

/* Update */
DETOURCROWD_C_API void C_dtCrowdUpdate(dtCrowdHandle crowd, float dt, C_dtCrowdAgentDebugInfo* debug);

/* Filters */
DETOURCROWD_C_API dtQueryFilterHandle C_dtCrowdGetFilter(dtCrowdHandle crowd, int i);
DETOURCROWD_C_API dtQueryFilterHandle C_dtCrowdGetEditableFilter(dtCrowdHandle crowd, int i);

/* Query extents */
DETOURCROWD_C_API void C_dtCrowdGetQueryHalfExtents(dtCrowdHandle crowd, float* halfExtents);

/* Velocity sample count */
DETOURCROWD_C_API int C_dtCrowdGetVelocitySampleCount(dtCrowdHandle crowd);

/* Obstacle avoidance debug data */
DETOURCROWD_C_API dtObstacleAvoidanceDebugDataHandle C_dtAllocObstacleAvoidanceDebugData(void);
DETOURCROWD_C_API void C_dtFreeObstacleAvoidanceDebugData(dtObstacleAvoidanceDebugDataHandle ptr);
DETOURCROWD_C_API int C_dtObstacleAvoidanceDebugDataInit(dtObstacleAvoidanceDebugDataHandle data, int maxSamples);
DETOURCROWD_C_API void C_dtObstacleAvoidanceDebugDataReset(dtObstacleAvoidanceDebugDataHandle data);
DETOURCROWD_C_API int C_dtObstacleAvoidanceDebugDataGetSampleCount(dtObstacleAvoidanceDebugDataHandle data);
DETOURCROWD_C_API void C_dtObstacleAvoidanceDebugDataGetSampleVelocity(dtObstacleAvoidanceDebugDataHandle data, int i, float* vel);
DETOURCROWD_C_API float C_dtObstacleAvoidanceDebugDataGetSampleSize(dtObstacleAvoidanceDebugDataHandle data, int i);
DETOURCROWD_C_API float C_dtObstacleAvoidanceDebugDataGetSamplePenalty(dtObstacleAvoidanceDebugDataHandle data, int i);

#ifdef __cplusplus
}
#endif

#endif /* DETOUR_CROWD_C_H */
