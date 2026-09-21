using System;
using Sedulous.Core;
using Sedulous.Geometry;

namespace Sedulous.Geometry.Tests;

/// The LOD chain. The selection path is exactly where malformed data arrives: a cooked
/// mesh whose LOD table does not match its submesh count has to render coarsely rather
/// than index past the end of an array.
class MeshLodTests
{
	/// Builds a mesh with `submeshes` submeshes at level 0 and `levels` LOD levels total.
	private static StaticMesh Build(int32 submeshes, uint32 levels)
	{
		let mesh = new StaticMesh();
		for (int32 s < submeshes)
			mesh.SubMeshes.Add(.(s * 10, 10, s, .Triangles));

		mesh.LodCount = levels;
		mesh.LodCoverage.Add(1.0f);
		for (uint32 level = 1; level < levels; level++)
		{
			mesh.LodCoverage.Add(1.0f / (float)(level + 1));
			for (int32 s < submeshes)
				mesh.LodSubMeshes.Add(.((int32)(1000 * level) + s * 10, 5, s, .Triangles));
		}
		return mesh;
	}

	/// Level 0 IS SubMeshes, which is what lets every consumer written before LOD existed
	/// keep working untouched.
	[Test]
	public static void LevelZeroIsTheSubmeshList()
	{
		let mesh = Build(2, 3);
		defer delete mesh;

		let level0 = mesh.SubMeshesForLod(0);
		Test.Assert(level0.Length == 2);
		Test.Assert(level0[0].StartIndex == 0);
		Test.Assert(level0[1].StartIndex == 10);
	}

	[Test]
	public static void AOneLevelMeshAnswersLevelZeroForEveryRequest()
	{
		let mesh = Build(2, 1);
		defer delete mesh;

		Test.Assert(mesh.LodSubMeshes.IsEmpty, "a one level chain stores no extra levels");
		for (uint32 lod < 4)
		{
			let table = mesh.SubMeshesForLod(lod);
			Test.Assert(table.Length == 2);
			Test.Assert(table[0].StartIndex == 0, scope $"lod {lod} fell back to level 0");
		}
	}

	[Test]
	public static void EachLevelReturnsItsOwnSlice()
	{
		let mesh = Build(2, 3);
		defer delete mesh;

		let level1 = mesh.SubMeshesForLod(1);
		Test.Assert(level1.Length == 2);
		Test.Assert(level1[0].StartIndex == 1000);
		Test.Assert(level1[1].StartIndex == 1010);

		let level2 = mesh.SubMeshesForLod(2);
		Test.Assert(level2.Length == 2);
		Test.Assert(level2[0].StartIndex == 2000);
		Test.Assert(level2[1].StartIndex == 2010);
	}

	/// A level past the end of the chain clamps to the coarsest one rather than reading
	/// past the table.
	[Test]
	public static void ALevelBeyondTheChainClampsToTheCoarsest()
	{
		let mesh = Build(2, 3);
		defer delete mesh;

		let coarsest = mesh.SubMeshesForLod(2);
		for (uint32 lod = 3; lod < 8; lod++)
		{
			let table = mesh.SubMeshesForLod(lod);
			Test.Assert(table.Length == coarsest.Length);
			Test.Assert(table[0].StartIndex == coarsest[0].StartIndex, scope $"lod {lod} clamped");
		}
	}

	/// A table that does not match the submesh count is malformed data, and malformed data
	/// renders at level 0 rather than slicing past the end of the list.
	[Test]
	public static void AMalformedTableFallsBackToLevelZero()
	{
		let mesh = Build(2, 3);
		defer delete mesh;

		// LodCount claims three levels, so the table should hold 2 levels x 2 submeshes.
		// Drop one entry and the slice for level 2 no longer fits.
		mesh.LodSubMeshes.PopBack();

		let level2 = mesh.SubMeshesForLod(2);
		Test.Assert(level2.Length == 2);
		Test.Assert(level2[0].StartIndex == 0, "fell back to level 0 rather than running off the end");
	}

	/// A mesh claiming LOD levels while having no submeshes at all has nothing to slice.
	[Test]
	public static void AMeshWithNoSubmeshesHasNothingToSelect()
	{
		let mesh = scope StaticMesh();
		mesh.LodCount = 3;
		mesh.LodCoverage.Add(1.0f);
		mesh.LodCoverage.Add(0.5f);
		mesh.LodCoverage.Add(0.25f);

		for (uint32 lod < 4)
			Test.Assert(mesh.SubMeshesForLod(lod).Length == 0, scope $"lod {lod}");
	}

	/// Clearing for reload drops the chain back to a single level, so a reloaded mesh does
	/// not keep selecting against the table the previous contents left behind.
	[Test]
	public static void ClearForReloadDropsTheChain()
	{
		let mesh = Build(2, 3);
		defer delete mesh;

		mesh.ClearForReload();

		Test.Assert(mesh.LodCount == 1);
		Test.Assert(mesh.LodSubMeshes.IsEmpty);
		Test.Assert(mesh.LodCoverage.IsEmpty);
		Test.Assert(mesh.SubMeshesForLod(2).Length == 0);
	}
}
