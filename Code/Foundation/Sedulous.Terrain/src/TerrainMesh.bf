using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Terrain;

/// The SHARED chunk mesh every chunk is drawn with, and the per level index buffers over it.
///
/// One 65 by 65 vertex grid is uploaded once and drawn for EVERY chunk: per chunk instance
/// data places it in the world and the vertex shader fetches its height from the terrain
/// texture. Each level reuses the SAME vertices through a strided index buffer, which is
/// what chunked geo mipmapping is. Nothing here touches a device; the renderer only uploads
/// what these produce.
static class TerrainMesh
{
	/// Quads along a chunk's side, so 65 vertices with the edges shared between neighbours.
	public const int32 ChunkQuads = 64;
	public const int32 ChunkVerts = ChunkQuads + 1;
	/// A stride of 2^6 is 64, which is a single quad: the coarsest a chunk can get.
	public const uint32 MaxChunkLod = 6;

	/// Where the skirt copy begins in the shared vertex buffer.
	public const uint32 SurfaceVertexCount = (uint32)ChunkVerts * (uint32)ChunkVerts;

	/// Builds the shared grid's vertices: the 65 by 65 SURFACE grid, then a 65 by 65 SKIRT
	/// copy of it.
	///
	/// Each vertex is (u, v, skirtFlag) with u and v spanning zero to one row major, which
	/// the renderer maps to world XZ and to the height sample coordinate per chunk. The skirt
	/// copy SHARES the border coordinates so a skirt vertex sits directly under its surface
	/// twin, and the vertex shader drops it below the surface to plug the cracks a level of
	/// detail seam opens. Its interior vertices are never indexed; only the border ring is.
	public static void BuildChunkGridVertices(List<Float3> outVertices)
	{
		outVertices.Clear();
		outVertices.Reserve(ChunkVerts * ChunkVerts * 2);

		let span = (float)ChunkQuads;
		for (int pass < 2)
		{
			let flag = (float)pass;
			for (int32 z = 0; z < ChunkVerts; z++)
			{
				for (int32 x = 0; x < ChunkVerts; x++)
					outVertices.Add(.((float)x / span, (float)z / span, flag));
			}
		}
	}

	/// Quads along a chunk's side at a level, which is the stride 2^lod, and none past the
	/// coarsest.
	public static uint32 ChunkLodQuadsPerSide(uint32 lod) =>
		(lod > MaxChunkLod) ? 0 : ((uint32)ChunkQuads >> lod);

	/// The SURFACE index count at a level, which is the prefix of the buffer before the skirt
	/// walls: what a pass that wants no skirts draws.
	public static uint32 ChunkLodSurfaceIndexCount(uint32 lod)
	{
		let quads = ChunkLodQuadsPerSide(lod);
		return quads * quads * 6;
	}

	/// The triangle indices at a level: the surface, wound counter clockwise seen from above,
	/// FOLLOWED BY a skirt wall around the four edges.
	///
	/// Each border segment becomes a quad joining the surface's border vertices to their
	/// dropped skirt twins, so a coarser neighbour's lower edge cannot open a see through
	/// crack. A level past the coarsest produces nothing.
	public static void BuildChunkGridIndices(uint32 lod, List<uint32> outIndices)
	{
		outIndices.Clear();
		if (lod > MaxChunkLod)
			return;

		let stride = (int32)1 << lod;
		let quads = ChunkQuads / stride;
		outIndices.Reserve(quads * quads * 6 + quads * 4 * 6);

		for (int32 qz = 0; qz < quads; qz++)
		{
			for (int32 qx = 0; qx < quads; qx++)
			{
				let x0 = qx * stride;
				let z0 = qz * stride;
				let x1 = x0 + stride;
				let z1 = z0 + stride;
				let v00 = Surface(x0, z0);
				let v10 = Surface(x1, z0);
				let v01 = Surface(x0, z1);
				let v11 = Surface(x1, z1);

				outIndices.Add(v00);
				outIndices.Add(v01);
				outIndices.Add(v11);
				outIndices.Add(v00);
				outIndices.Add(v11);
				outIndices.Add(v10);
			}
		}

		// The skirt walls: one quad per border segment, its top the surface's border vertex
		// and its bottom that vertex's skirt twin. Emitted in BOTH windings, so the wall
		// plugs the seam whichever side it is seen from.
		for (int32 i = 0; i < ChunkQuads; i += stride)
		{
			let j = i + stride;
			Wall(outIndices, Surface(i, 0), Surface(j, 0), Skirt(i, 0), Skirt(j, 0));
			Wall(outIndices, Surface(i, ChunkQuads), Surface(j, ChunkQuads),
				Skirt(i, ChunkQuads), Skirt(j, ChunkQuads));
			Wall(outIndices, Surface(0, i), Surface(0, j), Skirt(0, i), Skirt(0, j));
			Wall(outIndices, Surface(ChunkQuads, i), Surface(ChunkQuads, j),
				Skirt(ChunkQuads, i), Skirt(ChunkQuads, j));
		}
	}

	private static uint32 Surface(int32 x, int32 z) => (uint32)(z * ChunkVerts + x);
	private static uint32 Skirt(int32 x, int32 z) => Surface(x, z) + SurfaceVertexCount;

	/// One wall segment, both windings.
	private static void Wall(List<uint32> outIndices, uint32 t0, uint32 t1, uint32 b0, uint32 b1)
	{
		outIndices.Add(t0); outIndices.Add(b0); outIndices.Add(b1);
		outIndices.Add(t0); outIndices.Add(b1); outIndices.Add(t1);
		outIndices.Add(t0); outIndices.Add(b1); outIndices.Add(b0);
		outIndices.Add(t0); outIndices.Add(t1); outIndices.Add(b1);
	}
}
