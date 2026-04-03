/*
 * DetourCrowd C API Implementation
 */

#include "DetourCrowdC.h"
#include "DetourCrowd.h"
#include "DetourNavMesh.h"
#include "DetourNavMeshQuery.h"
#include <string.h>

extern "C" {

/* Crowd management */
DETOURCROWD_C_API dtCrowdHandle C_dtAllocCrowd(void) {
    return reinterpret_cast<dtCrowdHandle>(::dtAllocCrowd());
}

DETOURCROWD_C_API void C_dtFreeCrowd(dtCrowdHandle crowd) {
    ::dtFreeCrowd(reinterpret_cast<::dtCrowd*>(crowd));
}

DETOURCROWD_C_API int C_dtCrowdInit(dtCrowdHandle crowd, int maxAgents, float maxAgentRadius, dtNavMeshHandle nav) {
    return reinterpret_cast<::dtCrowd*>(crowd)->init(maxAgents, maxAgentRadius,
        reinterpret_cast<::dtNavMesh*>(nav)) ? 1 : 0;
}

/* Obstacle avoidance params */
DETOURCROWD_C_API void C_dtCrowdSetObstacleAvoidanceParams(dtCrowdHandle crowd, int idx, const C_dtObstacleAvoidanceParams* params) {
    reinterpret_cast<::dtCrowd*>(crowd)->setObstacleAvoidanceParams(idx,
        reinterpret_cast<const ::dtObstacleAvoidanceParams*>(params));
}

DETOURCROWD_C_API const C_dtObstacleAvoidanceParams* C_dtCrowdGetObstacleAvoidanceParams(dtCrowdHandle crowd, int idx) {
    return reinterpret_cast<const C_dtObstacleAvoidanceParams*>(
        reinterpret_cast<::dtCrowd*>(crowd)->getObstacleAvoidanceParams(idx));
}

/* Agent management */
DETOURCROWD_C_API int C_dtCrowdAddAgent(dtCrowdHandle crowd, const float* pos, const C_dtCrowdAgentParams* params) {
    return reinterpret_cast<::dtCrowd*>(crowd)->addAgent(pos,
        reinterpret_cast<const ::dtCrowdAgentParams*>(params));
}

DETOURCROWD_C_API void C_dtCrowdUpdateAgentParameters(dtCrowdHandle crowd, int idx, const C_dtCrowdAgentParams* params) {
    reinterpret_cast<::dtCrowd*>(crowd)->updateAgentParameters(idx,
        reinterpret_cast<const ::dtCrowdAgentParams*>(params));
}

DETOURCROWD_C_API void C_dtCrowdRemoveAgent(dtCrowdHandle crowd, int idx) {
    reinterpret_cast<::dtCrowd*>(crowd)->removeAgent(idx);
}

/* Agent queries */
DETOURCROWD_C_API int C_dtCrowdGetAgentCount(dtCrowdHandle crowd) {
    return reinterpret_cast<::dtCrowd*>(crowd)->getAgentCount();
}

/* Agent accessors */
DETOURCROWD_C_API int C_dtCrowdAgentIsActive(dtCrowdHandle crowd, int idx) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    return (agent && agent->active) ? 1 : 0;
}

DETOURCROWD_C_API unsigned char C_dtCrowdAgentGetState(dtCrowdHandle crowd, int idx) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    return agent ? agent->state : C_DT_CROWDAGENT_STATE_INVALID;
}

DETOURCROWD_C_API int C_dtCrowdAgentIsPartial(dtCrowdHandle crowd, int idx) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    return (agent && agent->partial) ? 1 : 0;
}

DETOURCROWD_C_API void C_dtCrowdAgentGetPosition(dtCrowdHandle crowd, int idx, float* pos) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    if (agent && pos) {
        pos[0] = agent->npos[0];
        pos[1] = agent->npos[1];
        pos[2] = agent->npos[2];
    }
}

DETOURCROWD_C_API void C_dtCrowdAgentGetDesiredVelocity(dtCrowdHandle crowd, int idx, float* dvel) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    if (agent && dvel) {
        dvel[0] = agent->dvel[0];
        dvel[1] = agent->dvel[1];
        dvel[2] = agent->dvel[2];
    }
}

DETOURCROWD_C_API void C_dtCrowdAgentGetVelocity(dtCrowdHandle crowd, int idx, float* vel) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    if (agent && vel) {
        vel[0] = agent->vel[0];
        vel[1] = agent->vel[1];
        vel[2] = agent->vel[2];
    }
}

DETOURCROWD_C_API void C_dtCrowdAgentGetParams(dtCrowdHandle crowd, int idx, C_dtCrowdAgentParams* params) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    if (agent && params) {
        memcpy(params, &agent->params, sizeof(C_dtCrowdAgentParams));
    }
}

DETOURCROWD_C_API int C_dtCrowdAgentGetCornerCount(dtCrowdHandle crowd, int idx) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    return agent ? agent->ncorners : 0;
}

DETOURCROWD_C_API void C_dtCrowdAgentGetCornerVerts(dtCrowdHandle crowd, int idx, float* verts, int maxVerts) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    if (agent && verts) {
        int count = agent->ncorners < maxVerts ? agent->ncorners : maxVerts;
        memcpy(verts, agent->cornerVerts, count * 3 * sizeof(float));
    }
}

DETOURCROWD_C_API void C_dtCrowdAgentGetCornerFlags(dtCrowdHandle crowd, int idx, unsigned char* flags, int maxFlags) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    if (agent && flags) {
        int count = agent->ncorners < maxFlags ? agent->ncorners : maxFlags;
        memcpy(flags, agent->cornerFlags, count * sizeof(unsigned char));
    }
}

DETOURCROWD_C_API void C_dtCrowdAgentGetCornerPolys(dtCrowdHandle crowd, int idx, C_dtPolyRef* polys, int maxPolys) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    if (agent && polys) {
        int count = agent->ncorners < maxPolys ? agent->ncorners : maxPolys;
        memcpy(polys, agent->cornerPolys, count * sizeof(C_dtPolyRef));
    }
}

DETOURCROWD_C_API unsigned char C_dtCrowdAgentGetTargetState(dtCrowdHandle crowd, int idx) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    return agent ? agent->targetState : C_DT_CROWDAGENT_TARGET_NONE;
}

DETOURCROWD_C_API C_dtPolyRef C_dtCrowdAgentGetTargetRef(dtCrowdHandle crowd, int idx) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    return agent ? agent->targetRef : 0;
}

DETOURCROWD_C_API void C_dtCrowdAgentGetTargetPos(dtCrowdHandle crowd, int idx, float* pos) {
    const ::dtCrowdAgent* agent = reinterpret_cast<::dtCrowd*>(crowd)->getAgent(idx);
    if (agent && pos) {
        pos[0] = agent->targetPos[0];
        pos[1] = agent->targetPos[1];
        pos[2] = agent->targetPos[2];
    }
}

/* Movement requests */
DETOURCROWD_C_API int C_dtCrowdRequestMoveTarget(dtCrowdHandle crowd, int idx, C_dtPolyRef ref, const float* pos) {
    return reinterpret_cast<::dtCrowd*>(crowd)->requestMoveTarget(idx, ref, pos) ? 1 : 0;
}

DETOURCROWD_C_API int C_dtCrowdRequestMoveVelocity(dtCrowdHandle crowd, int idx, const float* vel) {
    return reinterpret_cast<::dtCrowd*>(crowd)->requestMoveVelocity(idx, vel) ? 1 : 0;
}

DETOURCROWD_C_API int C_dtCrowdResetMoveTarget(dtCrowdHandle crowd, int idx) {
    return reinterpret_cast<::dtCrowd*>(crowd)->resetMoveTarget(idx) ? 1 : 0;
}

/* Active agents */
DETOURCROWD_C_API int C_dtCrowdGetActiveAgents(dtCrowdHandle crowd, int* agents, int maxAgents) {
    ::dtCrowd* c = reinterpret_cast<::dtCrowd*>(crowd);
    ::dtCrowdAgent** agentPtrs = new ::dtCrowdAgent*[maxAgents];
    int count = c->getActiveAgents(agentPtrs, maxAgents);

    // Convert agent pointers to indices
    for (int i = 0; i < count; i++) {
        // Find the index of this agent
        for (int j = 0; j < c->getAgentCount(); j++) {
            if (c->getAgent(j) == agentPtrs[i]) {
                agents[i] = j;
                break;
            }
        }
    }

    delete[] agentPtrs;
    return count;
}

/* Update */
DETOURCROWD_C_API void C_dtCrowdUpdate(dtCrowdHandle crowd, float dt, C_dtCrowdAgentDebugInfo* debug) {
    reinterpret_cast<::dtCrowd*>(crowd)->update(dt, reinterpret_cast<::dtCrowdAgentDebugInfo*>(debug));
}

/* Filters */
DETOURCROWD_C_API dtQueryFilterHandle C_dtCrowdGetFilter(dtCrowdHandle crowd, int i) {
    return reinterpret_cast<dtQueryFilterHandle>(
        const_cast<::dtQueryFilter*>(reinterpret_cast<::dtCrowd*>(crowd)->getFilter(i)));
}

DETOURCROWD_C_API dtQueryFilterHandle C_dtCrowdGetEditableFilter(dtCrowdHandle crowd, int i) {
    return reinterpret_cast<dtQueryFilterHandle>(
        reinterpret_cast<::dtCrowd*>(crowd)->getEditableFilter(i));
}

/* Query extents */
DETOURCROWD_C_API void C_dtCrowdGetQueryHalfExtents(dtCrowdHandle crowd, float* halfExtents) {
    const float* ext = reinterpret_cast<::dtCrowd*>(crowd)->getQueryHalfExtents();
    if (ext && halfExtents) {
        halfExtents[0] = ext[0];
        halfExtents[1] = ext[1];
        halfExtents[2] = ext[2];
    }
}

/* Velocity sample count */
DETOURCROWD_C_API int C_dtCrowdGetVelocitySampleCount(dtCrowdHandle crowd) {
    return reinterpret_cast<::dtCrowd*>(crowd)->getVelocitySampleCount();
}

/* Obstacle avoidance debug data */
DETOURCROWD_C_API dtObstacleAvoidanceDebugDataHandle C_dtAllocObstacleAvoidanceDebugData(void) {
    return reinterpret_cast<dtObstacleAvoidanceDebugDataHandle>(::dtAllocObstacleAvoidanceDebugData());
}

DETOURCROWD_C_API void C_dtFreeObstacleAvoidanceDebugData(dtObstacleAvoidanceDebugDataHandle ptr) {
    ::dtFreeObstacleAvoidanceDebugData(reinterpret_cast<::dtObstacleAvoidanceDebugData*>(ptr));
}

DETOURCROWD_C_API int C_dtObstacleAvoidanceDebugDataInit(dtObstacleAvoidanceDebugDataHandle data, int maxSamples) {
    return reinterpret_cast<::dtObstacleAvoidanceDebugData*>(data)->init(maxSamples) ? 1 : 0;
}

DETOURCROWD_C_API void C_dtObstacleAvoidanceDebugDataReset(dtObstacleAvoidanceDebugDataHandle data) {
    reinterpret_cast<::dtObstacleAvoidanceDebugData*>(data)->reset();
}

DETOURCROWD_C_API int C_dtObstacleAvoidanceDebugDataGetSampleCount(dtObstacleAvoidanceDebugDataHandle data) {
    return reinterpret_cast<::dtObstacleAvoidanceDebugData*>(data)->getSampleCount();
}

DETOURCROWD_C_API void C_dtObstacleAvoidanceDebugDataGetSampleVelocity(dtObstacleAvoidanceDebugDataHandle data, int i, float* vel) {
    const float* v = reinterpret_cast<::dtObstacleAvoidanceDebugData*>(data)->getSampleVelocity(i);
    if (v && vel) {
        vel[0] = v[0];
        vel[1] = v[1];
        vel[2] = v[2];
    }
}

DETOURCROWD_C_API float C_dtObstacleAvoidanceDebugDataGetSampleSize(dtObstacleAvoidanceDebugDataHandle data, int i) {
    return reinterpret_cast<::dtObstacleAvoidanceDebugData*>(data)->getSampleSize(i);
}

DETOURCROWD_C_API float C_dtObstacleAvoidanceDebugDataGetSamplePenalty(dtObstacleAvoidanceDebugDataHandle data, int i) {
    return reinterpret_cast<::dtObstacleAvoidanceDebugData*>(data)->getSamplePenalty(i);
}

} /* extern "C" */
