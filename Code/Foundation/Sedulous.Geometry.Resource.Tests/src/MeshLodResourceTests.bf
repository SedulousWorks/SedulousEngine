using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Resource;

namespace Sedulous.Geometry.Resource.Tests;

/// The LOD chain across the cook and build boundary.
///
/// Raptor has no tests here at all, and this is the load path that has to survive
/// malformed data: a cooked table that disagrees with its own submesh count must render
/// at level 0 rather than slice past the end of a list.
class MeshLodResourceTests
{
	/// A two submesh, three level mesh with the levels packed into one index buffer.
	private static StaticMesh BuildChained()
	{
		let mesh = new StaticMesh();
		for (int i < 8)
			mesh.Vertices.Add(.(Float3(i, 0, 0), Float3(0, 1, 0), Float2(0, 0), 0xFFFFFFFF, Float3(1, 0, 0)));

		// 12 indices: level 0 takes 0..5, level 1 takes 6..9, level 2 takes 10..11.
		mesh.Indices.Resize(12);
		for (uint32 i < 12)
			mesh.Indices.Add(i % 8);

		mesh.SubMeshes.Add(.(0, 3, 0, .Triangles));
		mesh.SubMeshes.Add(.(3, 3, 1, .Triangles));

		mesh.LodCount = 3;
		mesh.LodCoverage.Add(1.0f);
		mesh.LodCoverage.Add(0.5f);
		mesh.LodCoverage.Add(0.25f);
		// Level 1, both submeshes, then level 2.
		mesh.LodSubMeshes.Add(.(6, 2, 0, .Triangles));
		mesh.LodSubMeshes.Add(.(8, 2, 1, .Triangles));
		mesh.LodSubMeshes.Add(.(10, 1, 0, .Triangles));
		mesh.LodSubMeshes.Add(.(11, 1, 1, .Triangles));
		return mesh;
	}

	[Test]
	public static void TheLodChainSurvivesTheRoundTrip()
	{
		let fixture = scope MeshFixture("scratch_mesh_lod");
		let source = BuildChained();
		defer delete source;

		let id = fixture.CookStatic("chained", source);
		let proxy = fixture.Manager.Bind<StaticMesh>(id);
		Test.Assert(proxy.State == .Ready);

		let built = proxy.Get;
		Test.Assert(built.LodCount == 3, scope $"got {built.LodCount} levels");
		Test.Assert(built.LodCoverage.Count == 3);
		Test.Assert(built.LodCoverage[1] == 0.5f);
		Test.Assert(built.LodSubMeshes.Count == 4);

		let level1 = built.SubMeshesForLod(1);
		Test.Assert(level1.Length == 2);
		Test.Assert(level1[0].StartIndex == 6);
		Test.Assert(level1[1].StartIndex == 8);

		let level2 = built.SubMeshesForLod(2);
		Test.Assert(level2[0].StartIndex == 10);
		Test.Assert(level2[1].StartIndex == 11);

		// A coarser level mirrors level 0's material and topology, since it never resorts.
		Test.Assert(level1[1].MaterialIndex == built.SubMeshes[1].MaterialIndex);
		Test.Assert(level2[0].Primitive == built.SubMeshes[0].Primitive);
	}

	/// A table whose length does not match LodCount times the submesh count is malformed,
	/// and collapses to a single level on load.
	[Test]
	public static void ATableOfTheWrongLengthCollapsesToOneLevel()
	{
		let fixture = scope MeshFixture("scratch_mesh_lod_short");

		let source = scope StaticMeshSource();
		source.VertexBlob.Resize(2 * sizeof(StaticMeshVertex));
		source.IndexData.Add(0); source.IndexData.Add(1); source.IndexData.Add(0);
		source.SubStart.Add(0); source.SubCount.Add(3);
		source.SubMaterial.Add(0); source.SubPrimitive.Add(0);

		source.LodCount = 3;                    // claims three levels
		source.LodCoverage.Add(1.0f);
		source.LodCoverage.Add(0.5f);
		source.LodCoverage.Add(0.25f);
		source.LodStart.Add(0);                 // but carries only one level's worth
		source.LodIndexCount.Add(1);

		let id = fixture.Store("short", "Sedulous.Geometry.StaticMeshSource", source);
		let proxy = fixture.Manager.Bind<StaticMesh>(id);

		Test.Assert(proxy.State == .Ready, "malformed LOD data is not a failed load");
		Test.Assert(proxy.Get.LodCount == 1, "it collapsed rather than slicing past the end");
		Test.Assert(proxy.Get.LodSubMeshes.IsEmpty);
		Test.Assert(proxy.Get.SubMeshes.Count == 1, "and level 0 is intact");
	}

	/// A range that falls outside the index buffer is malformed however well formed the
	/// table's shape is.
	[Test]
	public static void ARangeOutsideTheIndexBufferCollapsesToOneLevel()
	{
		let fixture = scope MeshFixture("scratch_mesh_lod_range");

		let source = scope StaticMeshSource();
		source.VertexBlob.Resize(2 * sizeof(StaticMeshVertex));
		source.IndexData.Add(0); source.IndexData.Add(1); source.IndexData.Add(0);
		source.SubStart.Add(0); source.SubCount.Add(3);
		source.SubMaterial.Add(0); source.SubPrimitive.Add(0);

		source.LodCount = 2;
		source.LodCoverage.Add(1.0f);
		source.LodCoverage.Add(0.5f);
		source.LodStart.Add(2);
		source.LodIndexCount.Add(99); // 2 + 99 is well past the three indices there are

		let id = fixture.Store("range", "Sedulous.Geometry.StaticMeshSource", source);
		let proxy = fixture.Manager.Bind<StaticMesh>(id);

		Test.Assert(proxy.State == .Ready);
		Test.Assert(proxy.Get.LodCount == 1, "an out of range level collapsed the chain");
	}

	/// A coverage list that does not have one entry per level is malformed too: selection
	/// reads coverage per level, so a short list would read past it.
	[Test]
	public static void AMismatchedCoverageListCollapsesToOneLevel()
	{
		let fixture = scope MeshFixture("scratch_mesh_lod_coverage");

		let source = scope StaticMeshSource();
		source.VertexBlob.Resize(2 * sizeof(StaticMeshVertex));
		source.IndexData.Add(0); source.IndexData.Add(1); source.IndexData.Add(0);
		source.SubStart.Add(0); source.SubCount.Add(3);
		source.SubMaterial.Add(0); source.SubPrimitive.Add(0);

		source.LodCount = 2;
		source.LodCoverage.Add(1.0f); // one entry for two levels
		source.LodStart.Add(0);
		source.LodIndexCount.Add(1);

		let id = fixture.Store("coverage", "Sedulous.Geometry.StaticMeshSource", source);
		let proxy = fixture.Manager.Bind<StaticMesh>(id);

		Test.Assert(proxy.State == .Ready);
		Test.Assert(proxy.Get.LodCount == 1);
		Test.Assert(proxy.Get.LodCoverage.IsEmpty);
	}

	/// A one level mesh cooks and loads with empty tables rather than a degenerate chain.
	[Test]
	public static void AOneLevelMeshStaysOneLevel()
	{
		let fixture = scope MeshFixture("scratch_mesh_lod_single");
		let plain = Primitives.Quad(1.0f, 1.0f);
		defer delete plain;

		let id = fixture.CookStatic("quad", plain);
		let proxy = fixture.Manager.Bind<StaticMesh>(id);

		Test.Assert(proxy.Get.LodCount == 1);
		Test.Assert(proxy.Get.LodSubMeshes.IsEmpty);
		Test.Assert(proxy.Get.LodCoverage.IsEmpty);
		Test.Assert(proxy.Get.SubMeshesForLod(1).Length == 1, "falls back to level 0");
	}
}
