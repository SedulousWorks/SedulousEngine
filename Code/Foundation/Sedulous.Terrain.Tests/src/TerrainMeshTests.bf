using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Terrain;

namespace Sedulous.Terrain.Tests;

/// The shared chunk mesh, and the strided index buffers over it.
class TerrainMeshTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	[Test]
	public static void TheGridCarriesASurfaceAndASkirtCopy()
	{
		let vertices = scope List<Float3>();
		TerrainMesh.BuildChunkGridVertices(vertices);

		Test.Assert(vertices.Count == TerrainMesh.ChunkVerts * TerrainMesh.ChunkVerts * 2);
		Test.Assert(Near(vertices[0].X, 0.0f) && Near(vertices[0].Y, 0.0f));
		Test.Assert(Near(vertices[0].Z, 0.0f), "the surface copy comes first");
		Test.Assert(Near(vertices[TerrainMesh.SurfaceVertexCount].Z, 1.0f),
			"and the skirt copy begins where the surface ends");

		let last = vertices[vertices.Count - 1];
		Test.Assert(Near(last.X, 1.0f) && Near(last.Y, 1.0f), "the skirt shares the coordinates");
		Test.Assert(Near(last.Z, 1.0f));
	}

	/// A skirt vertex sits directly UNDER its surface twin, which is the whole point: the
	/// vertex shader drops it, and a wall between the two plugs the seam.
	[Test]
	public static void EverySkirtVertexShadowsItsSurfaceTwin()
	{
		let vertices = scope List<Float3>();
		TerrainMesh.BuildChunkGridVertices(vertices);

		for (int i < (int)TerrainMesh.SurfaceVertexCount)
		{
			let surface = vertices[i];
			let skirt = vertices[i + (int)TerrainMesh.SurfaceVertexCount];
			Test.Assert(Near(surface.X, skirt.X) && Near(surface.Y, skirt.Y));
			Test.Assert(surface.Z == 0.0f && skirt.Z == 1.0f);
		}
	}

	[Test]
	public static void EachLevelHalvesTheQuadsPerSide()
	{
		Test.Assert(TerrainMesh.ChunkLodQuadsPerSide(0) == 64);
		Test.Assert(TerrainMesh.ChunkLodQuadsPerSide(1) == 32);
		Test.Assert(TerrainMesh.ChunkLodQuadsPerSide(TerrainMesh.MaxChunkLod) == 1,
			"the coarsest chunk is one quad");
		Test.Assert(TerrainMesh.ChunkLodQuadsPerSide(TerrainMesh.MaxChunkLod + 1) == 0);
	}

	/// The surface count is the PREFIX of the buffer: a pass drawing without skirts draws
	/// exactly that many indices and stops.
	[Test]
	public static void TheSurfaceCountIsTheSkirtlessPrefix()
	{
		Test.Assert(TerrainMesh.ChunkLodSurfaceIndexCount(0) == 64 * 64 * 6);
		Test.Assert(TerrainMesh.ChunkLodSurfaceIndexCount(1) == 32 * 32 * 6);
		Test.Assert(TerrainMesh.ChunkLodSurfaceIndexCount(TerrainMesh.MaxChunkLod) == 6);
		Test.Assert(TerrainMesh.ChunkLodSurfaceIndexCount(TerrainMesh.MaxChunkLod + 1) == 0);

		let indices = scope List<uint32>();
		TerrainMesh.BuildChunkGridIndices(0, indices);
		Test.Assert(TerrainMesh.ChunkLodSurfaceIndexCount(0) < (uint32)indices.Count,
			"the skirt walls follow it");
	}

	/// Each level is its surface plus a wall around all four edges: forty eight indices per
	/// border segment, being four double sided triangles.
	[Test]
	public static void EachLevelBuildsItsSurfaceAndItsSkirt()
	{
		let lod0 = scope List<uint32>();
		TerrainMesh.BuildChunkGridIndices(0, lod0);
		Test.Assert(lod0.Count == 64 * 64 * 6 + 64 * 48);

		let lod1 = scope List<uint32>();
		TerrainMesh.BuildChunkGridIndices(1, lod1);
		Test.Assert(lod1.Count == 32 * 32 * 6 + 32 * 48);

		let coarsest = scope List<uint32>();
		TerrainMesh.BuildChunkGridIndices(TerrainMesh.MaxChunkLod, coarsest);
		Test.Assert(coarsest.Count == 6 + 48, "one quad, and one segment per edge");

		let tooCoarse = scope List<uint32>();
		TerrainMesh.BuildChunkGridIndices(TerrainMesh.MaxChunkLod + 1, tooCoarse);
		Test.Assert(tooCoarse.IsEmpty);
	}

	[Test]
	public static void EveryIndexReferencesARealVertex()
	{
		let vertices = scope List<Float3>();
		TerrainMesh.BuildChunkGridVertices(vertices);

		let indices = scope List<uint32>();
		TerrainMesh.BuildChunkGridIndices(0, indices);

		var referencesSkirt = false;
		for (let index in indices)
		{
			Test.Assert(index < (uint32)vertices.Count);
			if (index >= TerrainMesh.SurfaceVertexCount)
				referencesSkirt = true;
		}
		Test.Assert(referencesSkirt, "and the mesh does use the skirt copy");
	}

	/// Every level reuses the SAME vertices, which is what makes one upload serve them all:
	/// a coarser level indexes a subset, never anything new.
	[Test]
	public static void ACoarserLevelIndexesASubsetOfTheSameVertices()
	{
		let fine = scope List<uint32>();
		TerrainMesh.BuildChunkGridIndices(0, fine);
		let coarse = scope List<uint32>();
		TerrainMesh.BuildChunkGridIndices(2, coarse);

		let used = scope HashSet<uint32>();
		for (let index in fine)
			used.Add(index);

		for (let index in coarse)
			Test.Assert(used.Contains(index));
	}

	/// The surface is wound counter clockwise seen from above, so a chunk is not backfacing.
	[Test]
	public static void TheSurfaceIsWoundConsistently()
	{
		let vertices = scope List<Float3>();
		TerrainMesh.BuildChunkGridVertices(vertices);
		let indices = scope List<uint32>();
		TerrainMesh.BuildChunkGridIndices(0, indices);

		// Only the surface prefix: a skirt wall is deliberately double sided.
		let surfaceCount = (int)TerrainMesh.ChunkLodSurfaceIndexCount(0);
		for (int i = 0; i < surfaceCount; i += 3)
		{
			// The coordinates lie in the XZ plane with u across and v along +Z, so a triangle
			// wound counter clockwise seen from +Y has a NEGATIVE cross product here: the
			// handedness flips going from a (u, v) plane to XZ under a +Y up convention.
			let a = vertices[(int)indices[i]];
			let b = vertices[(int)indices[i + 1]];
			let c = vertices[(int)indices[i + 2]];
			let cross = (b.X - a.X) * (c.Y - a.Y) - (b.Y - a.Y) * (c.X - a.X);
			Test.Assert(cross < 0.0f, scope $"triangle {i / 3} is wound the other way");
		}
	}
}
