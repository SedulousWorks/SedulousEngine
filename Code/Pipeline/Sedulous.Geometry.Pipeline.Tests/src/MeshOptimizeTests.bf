using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;

namespace Sedulous.Geometry.Pipeline.Tests;

/// The cook time optimisation pass.
///
/// Everything it does is a REORDER, so the cases pin what cannot change (the triangles, the
/// submesh ranges, the vertex values, the order of a non triangle stream), the win it exists
/// for (the cache miss rate falls), and the guard (malformed input passes through untouched).
class MeshOptimizeTests
{
	[Test]
	public static void AReorderKeepsTheTrianglesAndImprovesTheCacheRate()
	{
		let source = scope StaticMeshSource();
		MeshSourceFixture.HostileGrid(24, source);

		let before = scope List<Float3[3]>();
		MeshSourceFixture.SubmeshTriangles(source, 0, before);
		let vertexBytes = source.VertexBlob.Count;
		let indexCount = source.IndexData.Count;

		MeshOptimizeStats stats = .();
		MeshOptimize.OptimizeStaticMeshSource(source, &stats);

		// Every vertex is referenced here, so nothing compacts and the shape is untouched.
		Test.Assert(source.SubStart[0] == 0);
		Test.Assert(source.SubCount[0] == (int32)indexCount);
		Test.Assert(source.IndexData.Count == indexCount);
		Test.Assert(source.VertexBlob.Count == vertexBytes);
		Test.Assert(stats.TriangleSubmeshes == 1);
		Test.Assert(stats.VerticesBefore == stats.VerticesAfter);

		let after = scope List<Float3[3]>();
		MeshSourceFixture.SubmeshTriangles(source, 0, after);
		Test.Assert(MeshSourceFixture.SameTriangles(before, after));

		// The point of the pass.
		Test.Assert(stats.AcmrAfter < stats.AcmrBefore);

		// And it is IDEMPOTENT: running it again neither changes the surface nor undoes the
		// win, which a pass with a bias in it would.
		MeshOptimizeStats again = .();
		MeshOptimize.OptimizeStaticMeshSource(source, &again);
		let twice = scope List<Float3[3]>();
		MeshSourceFixture.SubmeshTriangles(source, 0, twice);
		Test.Assert(MeshSourceFixture.SameTriangles(before, twice));
		Test.Assert(again.AcmrAfter <= (stats.AcmrAfter + 1.0e-6f));
	}

	/// A line range is ORDER SENSITIVE, so it is left alone while the triangles reorder around
	/// it, and a vertex nothing references compacts away from the buffer.
	[Test]
	public static void ANonTriangleRangeKeepsItsOrderAndDeadVerticesCompact()
	{
		let source = scope StaticMeshSource();
		let vertices = scope List<StaticMeshVertex>();
		for (uint32 i < 6)
		{
			var vertex = StaticMeshVertex();
			vertex.Position = .((float)i, (float)(i * 2), 0.0f);
			vertices.Add(vertex);
		}
		MeshSourceFixture.SetVertices(source, vertices); // vertex five is referenced by nothing

		source.IndexData.AddRange(scope uint32[](0, 1, 2, 2, 1, 3));
		source.IndexData.AddRange(scope uint32[](4, 0, 3, 2));
		MeshSourceFixture.ClearSubmeshes(source);
		MeshSourceFixture.AddSubmesh(source, 0, 6, 0, .Triangles);
		MeshSourceFixture.AddSubmesh(source, 6, 4, 1, .Lines);

		let before = scope List<Float3[3]>();
		MeshSourceFixture.SubmeshTriangles(source, 0, before);
		let linesBefore = scope List<Float3>();
		for (int i < 4)
			linesBefore.Add(MeshSourceFixture.PositionOf(source, source.IndexData[6 + i]));

		MeshOptimizeStats stats = .();
		MeshOptimize.OptimizeStaticMeshSource(source, &stats);

		Test.Assert(stats.TriangleSubmeshes == 1); // the lines were not reordered
		Test.Assert(stats.VerticesBefore == 6);
		Test.Assert(stats.VerticesAfter == 5);
		Test.Assert(source.VertexBlob.Count == 5 * sizeof(StaticMeshVertex));

		let after = scope List<Float3[3]>();
		MeshSourceFixture.SubmeshTriangles(source, 0, after);
		Test.Assert(MeshSourceFixture.SameTriangles(before, after));

		// The line indices were remapped, but the POSITIONS they name, in order, are the same
		// segments: a reordered line list would draw different lines.
		for (int i < 4)
			Test.Assert(MeshSourceFixture.PositionOf(source, source.IndexData[6 + i]) == linesBefore[i]);
		for (let index in source.IndexData)
			Test.Assert(index < 5);
	}

	/// Malformed input is REFUSED rather than half fixed: a pass that reorders around a broken
	/// index would turn a visible fault into a silent one.
	[Test]
	public static void MalformedInputPassesThroughUntouched()
	{
		MeshOptimizeStats stats = .();

		let outOfRange = scope StaticMeshSource();
		let one = scope List<StaticMeshVertex>();
		one.Add(StaticMeshVertex());
		MeshSourceFixture.SetVertices(outOfRange, one);
		outOfRange.IndexData.AddRange(scope uint32[](0, 7, 0));
		MeshSourceFixture.AddSubmesh(outOfRange, 0, 3, 0, .Triangles);
		MeshOptimize.OptimizeStaticMeshSource(outOfRange, &stats);
		Test.Assert(outOfRange.IndexData[1] == 7);
		Test.Assert(stats.TriangleSubmeshes == 0);

		let badRange = scope StaticMeshSource();
		MeshSourceFixture.SetVertices(badRange, one);
		badRange.IndexData.Add(0);
		MeshSourceFixture.AddSubmesh(badRange, 0, 9, 0, .Triangles); // past the buffer
		MeshOptimize.OptimizeStaticMeshSource(badRange, &stats);
		Test.Assert(badRange.IndexData.Count == 1);
		Test.Assert(stats.TriangleSubmeshes == 0);

		let empty = scope StaticMeshSource();
		MeshOptimize.OptimizeStaticMeshSource(empty, &stats);
		Test.Assert(stats.VerticesBefore == 0);
		Test.Assert(stats.TriangleSubmeshes == 0);
	}

	/// A dense mesh grows a halving chain; one that already has a chain, or one too small to
	/// be worth it, does not.
	[Test]
	public static void ADenseMeshGrowsAHalvingChain()
	{
		let source = scope StaticMeshSource();
		MeshSourceFixture.HostileGrid(48, source);
		let lod0Indices = source.IndexData.Count;

		let added = MeshOptimize.GenerateLodChain(source);
		Test.Assert(added >= 1);
		Test.Assert(source.LodCount == (1 + added));
		Test.Assert(source.LodStart.Count == (int)added);
		Test.Assert(source.LodCoverage.Count == (int)source.LodCount);
		Test.Assert(Abs(source.LodCoverage[1] - 0.25f) < 0.001f);

		// The base is untouched, each level lands well under its predecessor, and every index
		// still points into the shared buffer.
		Test.Assert(source.SubCount[0] == (int32)lod0Indices);
		var previous = lod0Indices;
		for (uint32 level < added)
		{
			let count = (int)source.LodIndexCount[(int)level];
			Test.Assert(count > 0);
			Test.Assert(count <= ((previous * 3) / 4));
			previous = count;
		}
		let vertexCount = source.VertexBlob.Count / sizeof(StaticMeshVertex);
		for (let index in source.IndexData)
			Test.Assert(index < (uint32)vertexCount);

		// The chain survives the optimiser and the runtime fill.
		MeshOptimizeStats stats = .();
		MeshOptimize.OptimizeStaticMeshSource(source, &stats);
		let mesh = scope StaticMesh();
		source.FillStatic(mesh);
		Test.Assert(mesh.LodCount == source.LodCount);

		// An AUTHORED chain always wins: generation never runs over one.
		Test.Assert(MeshOptimize.GenerateLodChain(source) == 0);

		let tiny = scope StaticMeshSource();
		MeshSourceFixture.HostileGrid(1, tiny);
		Test.Assert(MeshOptimize.GenerateLodChain(tiny) == 0);
		Test.Assert(tiny.LodCount == 1);
	}

	/// The skinning stream runs PARALLEL to the vertices, so it takes the same permutation and
	/// the same compaction, or every vertex ends up skinned by another's bone.
	[Test]
	public static void ASkinnedSourcesParallelStreamFollowsThePermutation()
	{
		let source = scope SkinnedMeshSource();
		let vertices = scope List<StaticMeshVertex>();
		let skinning = scope List<VertexSkinning>();
		for (uint32 i < 6)
		{
			var vertex = StaticMeshVertex();
			vertex.Position = .((float)i, 0.0f, 0.0f);
			vertices.Add(vertex);

			var bind = VertexSkinning();
			bind.Joints[0] = (uint16)i; // the pairing the case checks after the shuffle
			skinning.Add(bind);
		}
		MeshSourceFixture.SetVertices(source, vertices);
		MeshSourceFixture.SetSkinning(source, skinning);

		source.IndexData.AddRange(scope uint32[](0, 1, 2, 2, 1, 3, 0, 3, 4)); // five is dead
		MeshSourceFixture.AddSubmesh(source, 0, 9, 0, .Triangles);

		MeshOptimizeStats stats = .();
		MeshOptimize.OptimizeStaticMeshSource(source, &stats);
		Test.Assert(stats.VerticesAfter == 5);
		Test.Assert(source.SkinningBlob.Count == 5 * sizeof(VertexSkinning));

		let outVertices = (StaticMeshVertex*)source.VertexBlob.Ptr;
		let outSkinning = (VertexSkinning*)source.SkinningBlob.Ptr;
		for (int i < 5)
			Test.Assert(outSkinning[i].Joints[0] == (uint16)outVertices[i].Position.X);

		// A stream that does not match REFUSES the whole pass rather than letting the two
		// diverge.
		let mismatched = scope SkinnedMeshSource();
		MeshSourceFixture.SetVertices(mismatched, vertices);
		mismatched.IndexData.AddRange(source.IndexData);
		MeshSourceFixture.AddSubmesh(mismatched, 0, 9, 0, .Triangles);
		mismatched.SkinningBlob.Count = 3 * sizeof(VertexSkinning);

		let firstBefore = mismatched.IndexData[0];
		MeshOptimize.OptimizeStaticMeshSource(mismatched, &stats);
		Test.Assert(mismatched.IndexData[0] == firstBefore);
		Test.Assert(stats.TriangleSubmeshes == 0);
	}
}
