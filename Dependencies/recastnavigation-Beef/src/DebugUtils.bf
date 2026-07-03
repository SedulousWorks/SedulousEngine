using System;

namespace recastnavigation_Beef;

/* Constants */
static
{
	public const float DU_PI = 3.14159265f;
}

/* Opaque handle type */
typealias duDebugDrawHandle = void*;

/* Draw primitives */
enum duDebugDrawPrimitives : int32
{
	DU_DRAW_POINTS,
	DU_DRAW_LINES,
	DU_DRAW_TRIS,
	DU_DRAW_QUADS
}

/* Draw nav mesh flags */
enum duDrawNavMeshFlags : int32
{
	DU_DRAWNAVMESH_OFFMESHCONS = 0x01,
	DU_DRAWNAVMESH_CLOSEDLIST = 0x02,
	DU_DRAWNAVMESH_COLOR_TILES = 0x04
}

/* Debug draw callback function types */
function void duDepthMaskFunc(void* userData, int32 state);
function void duTextureFunc(void* userData, int32 state);
function void duBeginFunc(void* userData, duDebugDrawPrimitives prim, float size);
function void duVertexFunc(void* userData, float x, float y, float z, uint32 color);
function void duVertexUVFunc(void* userData, float x, float y, float z, uint32 color, float u, float v);
function void duEndFunc(void* userData);

/* Functions */
static
{
	/* Debug draw creation/destruction */
	[CLink]
	public static extern duDebugDrawHandle C_duCreateDebugDraw(
		void* userData,
		duDepthMaskFunc depthMaskFunc,
		duTextureFunc textureFunc,
		duBeginFunc beginFunc,
		duVertexFunc vertexFunc,
		duVertexUVFunc vertexUVFunc,
		duEndFunc endFunc);
	[CLink]
	public static extern void C_duDestroyDebugDraw(duDebugDrawHandle dd);

	/* Color utilities */
	[CLink]
	public static extern uint32 C_duRGBA(int32 r, int32 g, int32 b, int32 a);
	[CLink]
	public static extern uint32 C_duRGBAf(float fr, float fg, float fb, float fa);
	[CLink]
	public static extern uint32 C_duIntToCol(int32 i, int32 a);
	[CLink]
	public static extern void C_duIntToColF(int32 i, float* col);
	[CLink]
	public static extern uint32 C_duMultCol(uint32 col, uint32 d);
	[CLink]
	public static extern uint32 C_duDarkenCol(uint32 col);
	[CLink]
	public static extern uint32 C_duLerpCol(uint32 ca, uint32 cb, uint32 u);
	[CLink]
	public static extern uint32 C_duTransCol(uint32 c, uint32 a);
	[CLink]
	public static extern void C_duCalcBoxColors(uint32* colors, uint32 colTop, uint32 colSide);

	/* Basic drawing functions */
	[CLink]
	public static extern void C_duDebugDrawCylinderWire(duDebugDrawHandle dd,
		float minx, float miny, float minz, float maxx, float maxy, float maxz,
		uint32 col, float lineWidth);
	[CLink]
	public static extern void C_duDebugDrawBoxWire(duDebugDrawHandle dd,
		float minx, float miny, float minz, float maxx, float maxy, float maxz,
		uint32 col, float lineWidth);
	[CLink]
	public static extern void C_duDebugDrawArc(duDebugDrawHandle dd,
		float x0, float y0, float z0, float x1, float y1, float z1, float h,
		float as0, float as1, uint32 col, float lineWidth);
	[CLink]
	public static extern void C_duDebugDrawArrow(duDebugDrawHandle dd,
		float x0, float y0, float z0, float x1, float y1, float z1,
		float as0, float as1, uint32 col, float lineWidth);
	[CLink]
	public static extern void C_duDebugDrawCircle(duDebugDrawHandle dd,
		float x, float y, float z, float r, uint32 col, float lineWidth);
	[CLink]
	public static extern void C_duDebugDrawCross(duDebugDrawHandle dd,
		float x, float y, float z, float size, uint32 col, float lineWidth);
	[CLink]
	public static extern void C_duDebugDrawBox(duDebugDrawHandle dd,
		float minx, float miny, float minz, float maxx, float maxy, float maxz,
		uint32* fcol);
	[CLink]
	public static extern void C_duDebugDrawCylinder(duDebugDrawHandle dd,
		float minx, float miny, float minz, float maxx, float maxy, float maxz,
		uint32 col);
	[CLink]
	public static extern void C_duDebugDrawGridXZ(duDebugDrawHandle dd,
		float ox, float oy, float oz, int32 w, int32 h, float size, uint32 col, float lineWidth);

	/* Append functions (without begin/end) */
	[CLink]
	public static extern void C_duAppendCylinderWire(duDebugDrawHandle dd,
		float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col);
	[CLink]
	public static extern void C_duAppendBoxWire(duDebugDrawHandle dd,
		float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col);
	[CLink]
	public static extern void C_duAppendBoxPoints(duDebugDrawHandle dd,
		float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col);
	[CLink]
	public static extern void C_duAppendArc(duDebugDrawHandle dd,
		float x0, float y0, float z0, float x1, float y1, float z1, float h,
		float as0, float as1, uint32 col);
	[CLink]
	public static extern void C_duAppendArrow(duDebugDrawHandle dd,
		float x0, float y0, float z0, float x1, float y1, float z1,
		float as0, float as1, uint32 col);
	[CLink]
	public static extern void C_duAppendCircle(duDebugDrawHandle dd,
		float x, float y, float z, float r, uint32 col);
	[CLink]
	public static extern void C_duAppendCross(duDebugDrawHandle dd,
		float x, float y, float z, float size, uint32 col);
	[CLink]
	public static extern void C_duAppendBox(duDebugDrawHandle dd,
		float minx, float miny, float minz, float maxx, float maxy, float maxz,
		uint32* fcol);
	[CLink]
	public static extern void C_duAppendCylinder(duDebugDrawHandle dd,
		float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col);

	/* Detour debug draw */
	[CLink]
	public static extern void C_duDebugDrawNavMesh(duDebugDrawHandle dd, dtNavMeshHandle mesh, uint8 flags);
	[CLink]
	public static extern void C_duDebugDrawNavMeshWithClosedList(duDebugDrawHandle dd, dtNavMeshHandle mesh,
		dtNavMeshQueryHandle query, uint8 flags);
	[CLink]
	public static extern void C_duDebugDrawNavMeshNodes(duDebugDrawHandle dd, dtNavMeshQueryHandle query);
	[CLink]
	public static extern void C_duDebugDrawNavMeshBVTree(duDebugDrawHandle dd, dtNavMeshHandle mesh);
	[CLink]
	public static extern void C_duDebugDrawNavMeshPortals(duDebugDrawHandle dd, dtNavMeshHandle mesh);
	[CLink]
	public static extern void C_duDebugDrawNavMeshPolysWithFlags(duDebugDrawHandle dd, dtNavMeshHandle mesh,
		uint16 polyFlags, uint32 col);
	[CLink]
	public static extern void C_duDebugDrawNavMeshPoly(duDebugDrawHandle dd, dtNavMeshHandle mesh,
		dtPolyRef @ref, uint32 col);

	/* Recast debug draw */
	[CLink]
	public static extern void C_duDebugDrawTriMesh(duDebugDrawHandle dd,
		float* verts, int32 nverts, int32* tris, float* normals, int32 ntris,
		uint8* flags, float texScale);
	[CLink]
	public static extern void C_duDebugDrawTriMeshSlope(duDebugDrawHandle dd,
		float* verts, int32 nverts, int32* tris, float* normals, int32 ntris,
		float walkableSlopeAngle, float texScale);
	[CLink]
	public static extern void C_duDebugDrawHeightfieldSolid(duDebugDrawHandle dd, rcHeightfieldHandle hf);
	[CLink]
	public static extern void C_duDebugDrawHeightfieldWalkable(duDebugDrawHandle dd, rcHeightfieldHandle hf);
	[CLink]
	public static extern void C_duDebugDrawCompactHeightfieldSolid(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern void C_duDebugDrawCompactHeightfieldRegions(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern void C_duDebugDrawCompactHeightfieldDistance(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf);
	[CLink]
	public static extern void C_duDebugDrawHeightfieldLayers(duDebugDrawHandle dd, rcHeightfieldLayerSetHandle lset);
	[CLink]
	public static extern void C_duDebugDrawRegionConnections(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha);
	[CLink]
	public static extern void C_duDebugDrawRawContours(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha);
	[CLink]
	public static extern void C_duDebugDrawContours(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha);
	[CLink]
	public static extern void C_duDebugDrawPolyMesh(duDebugDrawHandle dd, rcPolyMeshHandle mesh);
	[CLink]
	public static extern void C_duDebugDrawPolyMeshDetail(duDebugDrawHandle dd, rcPolyMeshDetailHandle dmesh);

	/* Wrapper functions */
	public static duDebugDrawHandle duCreateDebugDraw(void* userData, duDepthMaskFunc depthMaskFunc, duTextureFunc textureFunc, duBeginFunc beginFunc, duVertexFunc vertexFunc, duVertexUVFunc vertexUVFunc, duEndFunc endFunc) => C_duCreateDebugDraw(userData, depthMaskFunc, textureFunc, beginFunc, vertexFunc, vertexUVFunc, endFunc);
	public static void duDestroyDebugDraw(duDebugDrawHandle dd) => C_duDestroyDebugDraw(dd);
	public static uint32 duRGBA(int32 r, int32 g, int32 b, int32 a) => C_duRGBA(r, g, b, a);
	public static uint32 duRGBAf(float fr, float fg, float fb, float fa) => C_duRGBAf(fr, fg, fb, fa);
	public static uint32 duIntToCol(int32 i, int32 a) => C_duIntToCol(i, a);
	public static void duIntToColF(int32 i, float* col) => C_duIntToColF(i, col);
	public static uint32 duMultCol(uint32 col, uint32 d) => C_duMultCol(col, d);
	public static uint32 duDarkenCol(uint32 col) => C_duDarkenCol(col);
	public static uint32 duLerpCol(uint32 ca, uint32 cb, uint32 u) => C_duLerpCol(ca, cb, u);
	public static uint32 duTransCol(uint32 c, uint32 a) => C_duTransCol(c, a);
	public static void duCalcBoxColors(uint32* colors, uint32 colTop, uint32 colSide) => C_duCalcBoxColors(colors, colTop, colSide);
	public static void duDebugDrawCylinderWire(duDebugDrawHandle dd, float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col, float lineWidth) => C_duDebugDrawCylinderWire(dd, minx, miny, minz, maxx, maxy, maxz, col, lineWidth);
	public static void duDebugDrawBoxWire(duDebugDrawHandle dd, float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col, float lineWidth) => C_duDebugDrawBoxWire(dd, minx, miny, minz, maxx, maxy, maxz, col, lineWidth);
	public static void duDebugDrawArc(duDebugDrawHandle dd, float x0, float y0, float z0, float x1, float y1, float z1, float h, float as0, float as1, uint32 col, float lineWidth) => C_duDebugDrawArc(dd, x0, y0, z0, x1, y1, z1, h, as0, as1, col, lineWidth);
	public static void duDebugDrawArrow(duDebugDrawHandle dd, float x0, float y0, float z0, float x1, float y1, float z1, float as0, float as1, uint32 col, float lineWidth) => C_duDebugDrawArrow(dd, x0, y0, z0, x1, y1, z1, as0, as1, col, lineWidth);
	public static void duDebugDrawCircle(duDebugDrawHandle dd, float x, float y, float z, float r, uint32 col, float lineWidth) => C_duDebugDrawCircle(dd, x, y, z, r, col, lineWidth);
	public static void duDebugDrawCross(duDebugDrawHandle dd, float x, float y, float z, float size, uint32 col, float lineWidth) => C_duDebugDrawCross(dd, x, y, z, size, col, lineWidth);
	public static void duDebugDrawBox(duDebugDrawHandle dd, float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32* fcol) => C_duDebugDrawBox(dd, minx, miny, minz, maxx, maxy, maxz, fcol);
	public static void duDebugDrawCylinder(duDebugDrawHandle dd, float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col) => C_duDebugDrawCylinder(dd, minx, miny, minz, maxx, maxy, maxz, col);
	public static void duDebugDrawGridXZ(duDebugDrawHandle dd, float ox, float oy, float oz, int32 w, int32 h, float size, uint32 col, float lineWidth) => C_duDebugDrawGridXZ(dd, ox, oy, oz, w, h, size, col, lineWidth);
	public static void duAppendCylinderWire(duDebugDrawHandle dd, float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col) => C_duAppendCylinderWire(dd, minx, miny, minz, maxx, maxy, maxz, col);
	public static void duAppendBoxWire(duDebugDrawHandle dd, float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col) => C_duAppendBoxWire(dd, minx, miny, minz, maxx, maxy, maxz, col);
	public static void duAppendBoxPoints(duDebugDrawHandle dd, float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col) => C_duAppendBoxPoints(dd, minx, miny, minz, maxx, maxy, maxz, col);
	public static void duAppendArc(duDebugDrawHandle dd, float x0, float y0, float z0, float x1, float y1, float z1, float h, float as0, float as1, uint32 col) => C_duAppendArc(dd, x0, y0, z0, x1, y1, z1, h, as0, as1, col);
	public static void duAppendArrow(duDebugDrawHandle dd, float x0, float y0, float z0, float x1, float y1, float z1, float as0, float as1, uint32 col) => C_duAppendArrow(dd, x0, y0, z0, x1, y1, z1, as0, as1, col);
	public static void duAppendCircle(duDebugDrawHandle dd, float x, float y, float z, float r, uint32 col) => C_duAppendCircle(dd, x, y, z, r, col);
	public static void duAppendCross(duDebugDrawHandle dd, float x, float y, float z, float size, uint32 col) => C_duAppendCross(dd, x, y, z, size, col);
	public static void duAppendBox(duDebugDrawHandle dd, float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32* fcol) => C_duAppendBox(dd, minx, miny, minz, maxx, maxy, maxz, fcol);
	public static void duAppendCylinder(duDebugDrawHandle dd, float minx, float miny, float minz, float maxx, float maxy, float maxz, uint32 col) => C_duAppendCylinder(dd, minx, miny, minz, maxx, maxy, maxz, col);
	public static void duDebugDrawNavMesh(duDebugDrawHandle dd, dtNavMeshHandle mesh, uint8 flags) => C_duDebugDrawNavMesh(dd, mesh, flags);
	public static void duDebugDrawNavMeshWithClosedList(duDebugDrawHandle dd, dtNavMeshHandle mesh, dtNavMeshQueryHandle query, uint8 flags) => C_duDebugDrawNavMeshWithClosedList(dd, mesh, query, flags);
	public static void duDebugDrawNavMeshNodes(duDebugDrawHandle dd, dtNavMeshQueryHandle query) => C_duDebugDrawNavMeshNodes(dd, query);
	public static void duDebugDrawNavMeshBVTree(duDebugDrawHandle dd, dtNavMeshHandle mesh) => C_duDebugDrawNavMeshBVTree(dd, mesh);
	public static void duDebugDrawNavMeshPortals(duDebugDrawHandle dd, dtNavMeshHandle mesh) => C_duDebugDrawNavMeshPortals(dd, mesh);
	public static void duDebugDrawNavMeshPolysWithFlags(duDebugDrawHandle dd, dtNavMeshHandle mesh, uint16 polyFlags, uint32 col) => C_duDebugDrawNavMeshPolysWithFlags(dd, mesh, polyFlags, col);
	public static void duDebugDrawNavMeshPoly(duDebugDrawHandle dd, dtNavMeshHandle mesh, dtPolyRef @ref, uint32 col) => C_duDebugDrawNavMeshPoly(dd, mesh, @ref, col);
	public static void duDebugDrawTriMesh(duDebugDrawHandle dd, float* verts, int32 nverts, int32* tris, float* normals, int32 ntris, uint8* flags, float texScale) => C_duDebugDrawTriMesh(dd, verts, nverts, tris, normals, ntris, flags, texScale);
	public static void duDebugDrawTriMeshSlope(duDebugDrawHandle dd, float* verts, int32 nverts, int32* tris, float* normals, int32 ntris, float walkableSlopeAngle, float texScale) => C_duDebugDrawTriMeshSlope(dd, verts, nverts, tris, normals, ntris, walkableSlopeAngle, texScale);
	public static void duDebugDrawHeightfieldSolid(duDebugDrawHandle dd, rcHeightfieldHandle hf) => C_duDebugDrawHeightfieldSolid(dd, hf);
	public static void duDebugDrawHeightfieldWalkable(duDebugDrawHandle dd, rcHeightfieldHandle hf) => C_duDebugDrawHeightfieldWalkable(dd, hf);
	public static void duDebugDrawCompactHeightfieldSolid(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf) => C_duDebugDrawCompactHeightfieldSolid(dd, chf);
	public static void duDebugDrawCompactHeightfieldRegions(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf) => C_duDebugDrawCompactHeightfieldRegions(dd, chf);
	public static void duDebugDrawCompactHeightfieldDistance(duDebugDrawHandle dd, rcCompactHeightfieldHandle chf) => C_duDebugDrawCompactHeightfieldDistance(dd, chf);
	public static void duDebugDrawHeightfieldLayers(duDebugDrawHandle dd, rcHeightfieldLayerSetHandle lset) => C_duDebugDrawHeightfieldLayers(dd, lset);
	public static void duDebugDrawRegionConnections(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha) => C_duDebugDrawRegionConnections(dd, cset, alpha);
	public static void duDebugDrawRawContours(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha) => C_duDebugDrawRawContours(dd, cset, alpha);
	public static void duDebugDrawContours(duDebugDrawHandle dd, rcContourSetHandle cset, float alpha) => C_duDebugDrawContours(dd, cset, alpha);
	public static void duDebugDrawPolyMesh(duDebugDrawHandle dd, rcPolyMeshHandle mesh) => C_duDebugDrawPolyMesh(dd, mesh);
	public static void duDebugDrawPolyMeshDetail(duDebugDrawHandle dd, rcPolyMeshDetailHandle dmesh) => C_duDebugDrawPolyMeshDetail(dd, dmesh);
}
