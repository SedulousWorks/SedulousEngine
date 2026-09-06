/*
 * DebugUtils C API Implementation
 */

#include "DebugUtilsC.h"
#include "DebugDraw.h"
#include "DetourDebugDraw.h"
#include "RecastDebugDraw.h"
#include "DetourNavMesh.h"
#include "DetourNavMeshQuery.h"
#include "Recast.h"
#include <string.h>

/* Debug draw callback wrapper */
class duDebugDrawC : public duDebugDraw {
    void* m_userData;
    C_duDepthMaskFunc m_depthMaskFunc;
    C_duTextureFunc m_textureFunc;
    C_duBeginFunc m_beginFunc;
    C_duVertexFunc m_vertexFunc;
    C_duVertexUVFunc m_vertexUVFunc;
    C_duEndFunc m_endFunc;

public:
    duDebugDrawC(void* userData,
                 C_duDepthMaskFunc depthMaskFunc,
                 C_duTextureFunc textureFunc,
                 C_duBeginFunc beginFunc,
                 C_duVertexFunc vertexFunc,
                 C_duVertexUVFunc vertexUVFunc,
                 C_duEndFunc endFunc)
        : m_userData(userData)
        , m_depthMaskFunc(depthMaskFunc)
        , m_textureFunc(textureFunc)
        , m_beginFunc(beginFunc)
        , m_vertexFunc(vertexFunc)
        , m_vertexUVFunc(vertexUVFunc)
        , m_endFunc(endFunc) {}

    virtual ~duDebugDrawC() {}

    virtual void depthMask(bool state) {
        if (m_depthMaskFunc) m_depthMaskFunc(m_userData, state ? 1 : 0);
    }

    virtual void texture(bool state) {
        if (m_textureFunc) m_textureFunc(m_userData, state ? 1 : 0);
    }

    virtual void begin(duDebugDrawPrimitives prim, float size = 1.0f) {
        if (m_beginFunc) m_beginFunc(m_userData, (C_duDebugDrawPrimitives)prim, size);
    }

    virtual void vertex(const float* pos, unsigned int color) {
        if (m_vertexFunc) m_vertexFunc(m_userData, pos[0], pos[1], pos[2], color);
    }

    virtual void vertex(const float x, const float y, const float z, unsigned int color) {
        if (m_vertexFunc) m_vertexFunc(m_userData, x, y, z, color);
    }

    virtual void vertex(const float* pos, unsigned int color, const float* uv) {
        if (m_vertexUVFunc) m_vertexUVFunc(m_userData, pos[0], pos[1], pos[2], color, uv[0], uv[1]);
        else if (m_vertexFunc) m_vertexFunc(m_userData, pos[0], pos[1], pos[2], color);
    }

    virtual void vertex(const float x, const float y, const float z, unsigned int color, const float u, const float v) {
        if (m_vertexUVFunc) m_vertexUVFunc(m_userData, x, y, z, color, u, v);
        else if (m_vertexFunc) m_vertexFunc(m_userData, x, y, z, color);
    }

    virtual void end() {
        if (m_endFunc) m_endFunc(m_userData);
    }
};

extern "C" {

/* Debug draw creation/destruction */
DEBUGUTILS_C_API duDebugDrawHandle C_duCreateDebugDraw(
    void* userData,
    C_duDepthMaskFunc depthMaskFunc,
    C_duTextureFunc textureFunc,
    C_duBeginFunc beginFunc,
    C_duVertexFunc vertexFunc,
    C_duVertexUVFunc vertexUVFunc,
    C_duEndFunc endFunc) {
    return reinterpret_cast<duDebugDrawHandle>(
        new duDebugDrawC(userData, depthMaskFunc, textureFunc, beginFunc, vertexFunc, vertexUVFunc, endFunc));
}

DEBUGUTILS_C_API void C_duDestroyDebugDraw(duDebugDrawHandle dd) {
    delete reinterpret_cast<duDebugDrawC*>(dd);
}

/* Color utilities */
DEBUGUTILS_C_API unsigned int C_duRGBA(int r, int g, int b, int a) {
    return ::duRGBA(r, g, b, a);
}

DEBUGUTILS_C_API unsigned int C_duRGBAf(float fr, float fg, float fb, float fa) {
    return ::duRGBAf(fr, fg, fb, fa);
}

DEBUGUTILS_C_API unsigned int C_duIntToCol(int i, int a) {
    return ::duIntToCol(i, a);
}

DEBUGUTILS_C_API void C_duIntToColF(int i, float* col) {
    ::duIntToCol(i, col);
}

DEBUGUTILS_C_API unsigned int C_duMultCol(unsigned int col, unsigned int d) {
    return ::duMultCol(col, d);
}

DEBUGUTILS_C_API unsigned int C_duDarkenCol(unsigned int col) {
    return ::duDarkenCol(col);
}

DEBUGUTILS_C_API unsigned int C_duLerpCol(unsigned int ca, unsigned int cb, unsigned int u) {
    return ::duLerpCol(ca, cb, u);
}

DEBUGUTILS_C_API unsigned int C_duTransCol(unsigned int c, unsigned int a) {
    return ::duTransCol(c, a);
}

DEBUGUTILS_C_API void C_duCalcBoxColors(unsigned int* colors, unsigned int colTop, unsigned int colSide) {
    ::duCalcBoxColors(colors, colTop, colSide);
}

/* Basic drawing functions */
DEBUGUTILS_C_API void C_duDebugDrawCylinderWire(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz,
    unsigned int col, float lineWidth) {
    ::duDebugDrawCylinderWire(reinterpret_cast<::duDebugDraw*>(dd),
        minx, miny, minz, maxx, maxy, maxz, col, lineWidth);
}

DEBUGUTILS_C_API void C_duDebugDrawBoxWire(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz,
    unsigned int col, float lineWidth) {
    ::duDebugDrawBoxWire(reinterpret_cast<::duDebugDraw*>(dd),
        minx, miny, minz, maxx, maxy, maxz, col, lineWidth);
}

DEBUGUTILS_C_API void C_duDebugDrawArc(duDebugDrawHandle dd,
    float x0, float y0, float z0, float x1, float y1, float z1, float h,
    float as0, float as1, unsigned int col, float lineWidth) {
    ::duDebugDrawArc(reinterpret_cast<::duDebugDraw*>(dd),
        x0, y0, z0, x1, y1, z1, h, as0, as1, col, lineWidth);
}

DEBUGUTILS_C_API void C_duDebugDrawArrow(duDebugDrawHandle dd,
    float x0, float y0, float z0, float x1, float y1, float z1,
    float as0, float as1, unsigned int col, float lineWidth) {
    ::duDebugDrawArrow(reinterpret_cast<::duDebugDraw*>(dd),
        x0, y0, z0, x1, y1, z1, as0, as1, col, lineWidth);
}

DEBUGUTILS_C_API void C_duDebugDrawCircle(duDebugDrawHandle dd,
    float x, float y, float z, float r, unsigned int col, float lineWidth) {
    ::duDebugDrawCircle(reinterpret_cast<::duDebugDraw*>(dd), x, y, z, r, col, lineWidth);
}

DEBUGUTILS_C_API void C_duDebugDrawCross(duDebugDrawHandle dd,
    float x, float y, float z, float size, unsigned int col, float lineWidth) {
    ::duDebugDrawCross(reinterpret_cast<::duDebugDraw*>(dd), x, y, z, size, col, lineWidth);
}

DEBUGUTILS_C_API void C_duDebugDrawBox(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz,
    const unsigned int* fcol) {
    ::duDebugDrawBox(reinterpret_cast<::duDebugDraw*>(dd),
        minx, miny, minz, maxx, maxy, maxz, fcol);
}

DEBUGUTILS_C_API void C_duDebugDrawCylinder(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz,
    unsigned int col) {
    ::duDebugDrawCylinder(reinterpret_cast<::duDebugDraw*>(dd),
        minx, miny, minz, maxx, maxy, maxz, col);
}

DEBUGUTILS_C_API void C_duDebugDrawGridXZ(duDebugDrawHandle dd,
    float ox, float oy, float oz, int w, int h, float size, unsigned int col, float lineWidth) {
    ::duDebugDrawGridXZ(reinterpret_cast<::duDebugDraw*>(dd), ox, oy, oz, w, h, size, col, lineWidth);
}

/* Append functions */
DEBUGUTILS_C_API void C_duAppendCylinderWire(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz, unsigned int col) {
    ::duAppendCylinderWire(reinterpret_cast<::duDebugDraw*>(dd),
        minx, miny, minz, maxx, maxy, maxz, col);
}

DEBUGUTILS_C_API void C_duAppendBoxWire(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz, unsigned int col) {
    ::duAppendBoxWire(reinterpret_cast<::duDebugDraw*>(dd),
        minx, miny, minz, maxx, maxy, maxz, col);
}

DEBUGUTILS_C_API void C_duAppendBoxPoints(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz, unsigned int col) {
    ::duAppendBoxPoints(reinterpret_cast<::duDebugDraw*>(dd),
        minx, miny, minz, maxx, maxy, maxz, col);
}

DEBUGUTILS_C_API void C_duAppendArc(duDebugDrawHandle dd,
    float x0, float y0, float z0, float x1, float y1, float z1, float h,
    float as0, float as1, unsigned int col) {
    ::duAppendArc(reinterpret_cast<::duDebugDraw*>(dd),
        x0, y0, z0, x1, y1, z1, h, as0, as1, col);
}

DEBUGUTILS_C_API void C_duAppendArrow(duDebugDrawHandle dd,
    float x0, float y0, float z0, float x1, float y1, float z1,
    float as0, float as1, unsigned int col) {
    ::duAppendArrow(reinterpret_cast<::duDebugDraw*>(dd),
        x0, y0, z0, x1, y1, z1, as0, as1, col);
}

DEBUGUTILS_C_API void C_duAppendCircle(duDebugDrawHandle dd,
    float x, float y, float z, float r, unsigned int col) {
    ::duAppendCircle(reinterpret_cast<::duDebugDraw*>(dd), x, y, z, r, col);
}

DEBUGUTILS_C_API void C_duAppendCross(duDebugDrawHandle dd,
    float x, float y, float z, float size, unsigned int col) {
    ::duAppendCross(reinterpret_cast<::duDebugDraw*>(dd), x, y, z, size, col);
}

DEBUGUTILS_C_API void C_duAppendBox(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz,
    const unsigned int* fcol) {
    ::duAppendBox(reinterpret_cast<::duDebugDraw*>(dd),
        minx, miny, minz, maxx, maxy, maxz, fcol);
}

DEBUGUTILS_C_API void C_duAppendCylinder(duDebugDrawHandle dd,
    float minx, float miny, float minz, float maxx, float maxy, float maxz, unsigned int col) {
    ::duAppendCylinder(reinterpret_cast<::duDebugDraw*>(dd),
        minx, miny, minz, maxx, maxy, maxz, col);
}

/* Detour debug draw */
DEBUGUTILS_C_API void C_duDebugDrawNavMesh(duDebugDrawHandle dd, dtNavMeshHandle mesh, unsigned char flags) {
    ::duDebugDrawNavMesh(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::dtNavMesh*>(mesh), flags);
}

DEBUGUTILS_C_API void C_duDebugDrawNavMeshWithClosedList(duDebugDrawHandle dd, dtNavMeshHandle mesh,
    dtNavMeshQueryHandle query, unsigned char flags) {
    ::duDebugDrawNavMeshWithClosedList(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::dtNavMesh*>(mesh),
        *reinterpret_cast<const ::dtNavMeshQuery*>(query), flags);
}

DEBUGUTILS_C_API void C_duDebugDrawNavMeshNodes(duDebugDrawHandle dd, dtNavMeshQueryHandle query) {
    ::duDebugDrawNavMeshNodes(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::dtNavMeshQuery*>(query));
}

DEBUGUTILS_C_API void C_duDebugDrawNavMeshBVTree(duDebugDrawHandle dd, dtNavMeshHandle mesh) {
    ::duDebugDrawNavMeshBVTree(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::dtNavMesh*>(mesh));
}

DEBUGUTILS_C_API void C_duDebugDrawNavMeshPortals(duDebugDrawHandle dd, dtNavMeshHandle mesh) {
    ::duDebugDrawNavMeshPortals(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::dtNavMesh*>(mesh));
}

DEBUGUTILS_C_API void C_duDebugDrawNavMeshPolysWithFlags(duDebugDrawHandle dd, dtNavMeshHandle mesh,
    unsigned short polyFlags, unsigned int col) {
    ::duDebugDrawNavMeshPolysWithFlags(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::dtNavMesh*>(mesh), polyFlags, col);
}

DEBUGUTILS_C_API void C_duDebugDrawNavMeshPoly(duDebugDrawHandle dd, dtNavMeshHandle mesh,
    C_dtPolyRef ref, unsigned int col) {
    ::duDebugDrawNavMeshPoly(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::dtNavMesh*>(mesh), ref, col);
}

/* Recast debug draw */
DEBUGUTILS_C_API void C_duDebugDrawTriMesh(duDebugDrawHandle dd,
    const float* verts, int nverts, const int* tris, const float* normals, int ntris,
    const unsigned char* flags, float texScale) {
    ::duDebugDrawTriMesh(reinterpret_cast<::duDebugDraw*>(dd),
        verts, nverts, tris, normals, ntris, flags, texScale);
}

DEBUGUTILS_C_API void C_duDebugDrawTriMeshSlope(duDebugDrawHandle dd,
    const float* verts, int nverts, const int* tris, const float* normals, int ntris,
    float walkableSlopeAngle, float texScale) {
    ::duDebugDrawTriMeshSlope(reinterpret_cast<::duDebugDraw*>(dd),
        verts, nverts, tris, normals, ntris, walkableSlopeAngle, texScale);
}

DEBUGUTILS_C_API void C_duDebugDrawHeightfieldSolid(duDebugDrawHandle dd, rcHeightfieldHandle hf) {
    ::duDebugDrawHeightfieldSolid(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcHeightfield*>(hf));
}

DEBUGUTILS_C_API void C_duDebugDrawHeightfieldWalkable(duDebugDrawHandle dd, rcHeightfieldHandle hf) {
    ::duDebugDrawHeightfieldWalkable(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcHeightfield*>(hf));
}

DEBUGUTILS_C_API void C_duDebugDrawCompactHeightfieldSolid(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf) {
    ::duDebugDrawCompactHeightfieldSolid(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcCompactHeightfield*>(chf));
}

DEBUGUTILS_C_API void C_duDebugDrawCompactHeightfieldRegions(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf) {
    ::duDebugDrawCompactHeightfieldRegions(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcCompactHeightfield*>(chf));
}

DEBUGUTILS_C_API void C_duDebugDrawCompactHeightfieldDistance(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf) {
    ::duDebugDrawCompactHeightfieldDistance(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcCompactHeightfield*>(chf));
}

DEBUGUTILS_C_API void C_duDebugDrawHeightfieldLayers(duDebugDrawHandle dd, rcHeightfieldLayerSetHandle lset) {
    ::duDebugDrawHeightfieldLayers(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcHeightfieldLayerSet*>(lset));
}

DEBUGUTILS_C_API void C_duDebugDrawRegionConnections(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha) {
    ::duDebugDrawRegionConnections(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcContourSet*>(cset), alpha);
}

DEBUGUTILS_C_API void C_duDebugDrawRawContours(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha) {
    ::duDebugDrawRawContours(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcContourSet*>(cset), alpha);
}

DEBUGUTILS_C_API void C_duDebugDrawContours(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha) {
    ::duDebugDrawContours(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcContourSet*>(cset), alpha);
}

DEBUGUTILS_C_API void C_duDebugDrawPolyMesh(duDebugDrawHandle dd, rcPolyMeshHandle mesh) {
    ::duDebugDrawPolyMesh(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcPolyMesh*>(mesh));
}

DEBUGUTILS_C_API void C_duDebugDrawPolyMeshDetail(duDebugDrawHandle dd, rcPolyMeshDetailHandle dmesh) {
    ::duDebugDrawPolyMeshDetail(reinterpret_cast<::duDebugDraw*>(dd),
        *reinterpret_cast<const ::rcPolyMeshDetail*>(dmesh));
}

} /* extern "C" */
