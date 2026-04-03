/*
 * DebugUtils C API
 * C interface for the Recast/Detour debug utilities
 */

#ifndef DEBUGUTILS_C_H
#define DEBUGUTILS_C_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) && !defined(DEBUGUTILS_C_STATIC)
    #ifdef DEBUGUTILS_C_EXPORTS
        #define DEBUGUTILS_C_API __declspec(dllexport)
    #else
        #define DEBUGUTILS_C_API __declspec(dllimport)
    #endif
#else
    #define DEBUGUTILS_C_API
#endif

/* Constants */
#define C_DU_PI 3.14159265f

/* Draw primitives */
typedef enum C_duDebugDrawPrimitives {
    C_DU_DRAW_POINTS,
    C_DU_DRAW_LINES,
    C_DU_DRAW_TRIS,
    C_DU_DRAW_QUADS
} C_duDebugDrawPrimitives;

/* Draw nav mesh flags */
typedef enum C_DrawNavMeshFlags {
    C_DU_DRAWNAVMESH_OFFMESHCONS = 0x01,
    C_DU_DRAWNAVMESH_CLOSEDLIST = 0x02,
    C_DU_DRAWNAVMESH_COLOR_TILES = 0x04
} C_DrawNavMeshFlags;

/* Forward declarations */
typedef struct dtNavMesh_s* dtNavMeshHandle;
typedef struct dtNavMeshQuery_s* dtNavMeshQueryHandle;
typedef struct rcHeightfield_s* rcHeightfieldHandle;
typedef struct rcCompactHeightfield_s* rcCompactHeightfieldHandle;
typedef struct rcHeightfieldLayerSet_s* rcHeightfieldLayerSetHandle;
typedef struct rcContourSet_s* rcContourSetHandle;
typedef struct rcPolyMesh_s* rcPolyMeshHandle;
typedef struct rcPolyMeshDetail_s* rcPolyMeshDetailHandle;
typedef unsigned int C_dtPolyRef;

/* Debug draw callback function types */
typedef void (*C_duDepthMaskFunc)(void* userData, int state);
typedef void (*C_duTextureFunc)(void* userData, int state);
typedef void (*C_duBeginFunc)(void* userData, C_duDebugDrawPrimitives prim, float size);
typedef void (*C_duVertexFunc)(void* userData, float x, float y, float z, unsigned int color);
typedef void (*C_duVertexUVFunc)(void* userData, float x, float y, float z, unsigned int color, float u, float v);
typedef void (*C_duEndFunc)(void* userData);

/* Opaque handles */
typedef struct duDebugDraw_s* duDebugDrawHandle;

/* Debug draw creation/destruction */
DEBUGUTILS_C_API duDebugDrawHandle C_duCreateDebugDraw(
    void* userData,
    C_duDepthMaskFunc depthMaskFunc,
    C_duTextureFunc textureFunc,
    C_duBeginFunc beginFunc,
    C_duVertexFunc vertexFunc,
    C_duVertexUVFunc vertexUVFunc,
    C_duEndFunc endFunc);
DEBUGUTILS_C_API void C_duDestroyDebugDraw(duDebugDrawHandle dd);

/* Color utilities */
DEBUGUTILS_C_API unsigned int C_duRGBA(int r, int g, int b, int a);
DEBUGUTILS_C_API unsigned int C_duRGBAf(float fr, float fg, float fb, float fa);
DEBUGUTILS_C_API unsigned int C_duIntToCol(int i, int a);
DEBUGUTILS_C_API void C_duIntToColF(int i, float* col);
DEBUGUTILS_C_API unsigned int C_duMultCol(unsigned int col, unsigned int d);
DEBUGUTILS_C_API unsigned int C_duDarkenCol(unsigned int col);
DEBUGUTILS_C_API unsigned int C_duLerpCol(unsigned int ca, unsigned int cb, unsigned int u);
DEBUGUTILS_C_API unsigned int C_duTransCol(unsigned int c, unsigned int a);
DEBUGUTILS_C_API void C_duCalcBoxColors(unsigned int* colors, unsigned int colTop, unsigned int colSide);

/* Basic drawing functions */
DEBUGUTILS_C_API void C_duDebugDrawCylinderWire(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz,
    unsigned int col, float lineWidth);
DEBUGUTILS_C_API void C_duDebugDrawBoxWire(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz,
    unsigned int col, float lineWidth);
DEBUGUTILS_C_API void C_duDebugDrawArc(duDebugDrawHandle dd,
    float x0, float y0, float z0, float x1, float y1, float z1, float h,
    float as0, float as1, unsigned int col, float lineWidth);
DEBUGUTILS_C_API void C_duDebugDrawArrow(duDebugDrawHandle dd,
    float x0, float y0, float z0, float x1, float y1, float z1,
    float as0, float as1, unsigned int col, float lineWidth);
DEBUGUTILS_C_API void C_duDebugDrawCircle(duDebugDrawHandle dd,
    float x, float y, float z, float r, unsigned int col, float lineWidth);
DEBUGUTILS_C_API void C_duDebugDrawCross(duDebugDrawHandle dd,
    float x, float y, float z, float size, unsigned int col, float lineWidth);
DEBUGUTILS_C_API void C_duDebugDrawBox(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz,
    const unsigned int* fcol);
DEBUGUTILS_C_API void C_duDebugDrawCylinder(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz,
    unsigned int col);
DEBUGUTILS_C_API void C_duDebugDrawGridXZ(duDebugDrawHandle dd,
    float ox, float oy, float oz, int w, int h, float size, unsigned int col, float lineWidth);

/* Append functions (without begin/end) */
DEBUGUTILS_C_API void C_duAppendCylinderWire(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz, unsigned int col);
DEBUGUTILS_C_API void C_duAppendBoxWire(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz, unsigned int col);
DEBUGUTILS_C_API void C_duAppendBoxPoints(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz, unsigned int col);
DEBUGUTILS_C_API void C_duAppendArc(duDebugDrawHandle dd,
    float x0, float y0, float z0, float x1, float y1, float z1, float h,
    float as0, float as1, unsigned int col);
DEBUGUTILS_C_API void C_duAppendArrow(duDebugDrawHandle dd,
    float x0, float y0, float z0, float x1, float y1, float z1,
    float as0, float as1, unsigned int col);
DEBUGUTILS_C_API void C_duAppendCircle(duDebugDrawHandle dd,
    float x, float y, float z, float r, unsigned int col);
DEBUGUTILS_C_API void C_duAppendCross(duDebugDrawHandle dd,
    float x, float y, float z, float size, unsigned int col);
DEBUGUTILS_C_API void C_duAppendBox(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz,
    const unsigned int* fcol);
DEBUGUTILS_C_API void C_duAppendCylinder(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz, unsigned int col);

/* Detour debug draw */
DEBUGUTILS_C_API void C_duDebugDrawNavMesh(duDebugDrawHandle dd, dtNavMeshHandle mesh, unsigned char flags);
DEBUGUTILS_C_API void C_duDebugDrawNavMeshWithClosedList(duDebugDrawHandle dd, dtNavMeshHandle mesh,
    dtNavMeshQueryHandle query, unsigned char flags);
DEBUGUTILS_C_API void C_duDebugDrawNavMeshNodes(duDebugDrawHandle dd, dtNavMeshQueryHandle query);
DEBUGUTILS_C_API void C_duDebugDrawNavMeshBVTree(duDebugDrawHandle dd, dtNavMeshHandle mesh);
DEBUGUTILS_C_API void C_duDebugDrawNavMeshPortals(duDebugDrawHandle dd, dtNavMeshHandle mesh);
DEBUGUTILS_C_API void C_duDebugDrawNavMeshPolysWithFlags(duDebugDrawHandle dd, dtNavMeshHandle mesh,
    unsigned short polyFlags, unsigned int col);
DEBUGUTILS_C_API void C_duDebugDrawNavMeshPoly(duDebugDrawHandle dd, dtNavMeshHandle mesh,
    C_dtPolyRef ref, unsigned int col);

/* Recast debug draw */
DEBUGUTILS_C_API void C_duDebugDrawTriMesh(duDebugDrawHandle dd,
    const float* verts, int nverts, const int* tris, const float* normals, int ntris,
    const unsigned char* flags, float texScale);
DEBUGUTILS_C_API void C_duDebugDrawTriMeshSlope(duDebugDrawHandle dd,
    const float* verts, int nverts, const int* tris, const float* normals, int ntris,
    float walkableSlopeAngle, float texScale);
DEBUGUTILS_C_API void C_duDebugDrawHeightfieldSolid(duDebugDrawHandle dd, rcHeightfieldHandle hf);
DEBUGUTILS_C_API void C_duDebugDrawHeightfieldWalkable(duDebugDrawHandle dd, rcHeightfieldHandle hf);
DEBUGUTILS_C_API void C_duDebugDrawCompactHeightfieldSolid(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf);
DEBUGUTILS_C_API void C_duDebugDrawCompactHeightfieldRegions(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf);
DEBUGUTILS_C_API void C_duDebugDrawCompactHeightfieldDistance(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf);
DEBUGUTILS_C_API void C_duDebugDrawHeightfieldLayers(duDebugDrawHandle dd, rcHeightfieldLayerSetHandle lset);
DEBUGUTILS_C_API void C_duDebugDrawRegionConnections(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha);
DEBUGUTILS_C_API void C_duDebugDrawRawContours(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha);
DEBUGUTILS_C_API void C_duDebugDrawContours(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha);
DEBUGUTILS_C_API void C_duDebugDrawPolyMesh(duDebugDrawHandle dd, rcPolyMeshHandle mesh);
DEBUGUTILS_C_API void C_duDebugDrawPolyMeshDetail(duDebugDrawHandle dd, rcPolyMeshDetailHandle dmesh);

#ifdef __cplusplus
}
#endif

#endif /* DEBUGUTILS_C_H */
