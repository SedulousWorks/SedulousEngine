using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Model;

namespace Sedulous.ModelImporter.Tests;

/// Attaching authored levels of detail to the mesh they belong to.
class LodChainTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	/// A level joins the SHARED blob and the ONE index buffer, offset past what was already
	/// there, and the coverage ladder halves per level.
	[Test]
	public static void AnAuthoredLevelAppendsIntoTheBasesChain()
	{
		let baseMesh = MeshFixture.Row("Part", 0.0f, 4, scope uint32[](0, 1, 2, 0, 2, 3));
		defer delete baseMesh;

		let source = scope StaticMeshSource();
		MeshConvert.StaticFromModel(baseMesh, source);
		Test.Assert(source.SubStart.Count == 1);

		let level = MeshFixture.Row("Part_LOD1", 100.0f, 3, scope uint32[](0, 1, 2));
		defer delete level;
		Test.Assert(LodChain.AppendFromModel(level, source));

		Test.Assert(source.LodCount == 2);
		Test.Assert(source.LodStart.Count == 1);
		Test.Assert(source.LodStart[0] == 6);
		Test.Assert(source.LodIndexCount[0] == 3);
		Test.Assert(source.VertexBlob.Count == 7 * sizeof(StaticMeshVertex));
		Test.Assert(source.IndexData.Count == 9);
		Test.Assert(source.IndexData[6] == 4); // offset past the base's four vertices
		Test.Assert(source.LodCoverage.Count == 2);
		Test.Assert(Near(source.LodCoverage[1], 0.25f));

		// The appended vertices really are the level's: its shift carries through.
		let vertices = (StaticMeshVertex*)source.VertexBlob.Ptr;
		Test.Assert(Near(vertices[4].Position.X, 100.0f));

		// A second level extends the ladder rather than restarting it.
		let second = MeshFixture.Row("Part_LOD2", 200.0f, 3, scope uint32[](0, 2, 1));
		defer delete second;
		Test.Assert(LodChain.AppendFromModel(second, source));
		Test.Assert(source.LodCount == 3);
		Test.Assert(Near(source.LodCoverage[2], 0.125f));

		// The chain survives the runtime fill: level one draws its own range.
		let mesh = scope StaticMesh();
		source.FillStatic(mesh);
		Test.Assert(mesh.LodCount == 3);
		Test.Assert(mesh.SubMeshesForLod(1)[0].StartIndex == 6);
		Test.Assert(mesh.SubMeshesForLod(1)[0].IndexCount == 3);
	}

	/// The material layout belongs to the chain as a whole, so a level that disagrees about
	/// its submeshes is refused with the base UNTOUCHED: half an appended level would draw
	/// one submesh with another's material.
	[Test]
	public static void AMismatchedLevelIsRefusedAndChangesNothing()
	{
		let baseMesh = MeshFixture.Row("Part", 0.0f, 4, scope uint32[](0, 1, 2, 0, 2, 3));
		defer delete baseMesh;
		let source = scope StaticMeshSource();
		MeshConvert.StaticFromModel(baseMesh, source);

		let twoParts = MeshFixture.Row("Part_LOD1", 300.0f, 3, scope uint32[](0, 1, 2, 0, 2, 1));
		defer delete twoParts;
		twoParts.AddPart(.(0, 3, 0));
		twoParts.AddPart(.(3, 3, 1));

		let blobBefore = source.VertexBlob.Count;
		Test.Assert(!LodChain.AppendFromModel(twoParts, source));
		Test.Assert(source.VertexBlob.Count == blobBefore);
		Test.Assert(source.LodCount == 1);
	}

	/// The skinning stream runs PARALLEL to the vertices, so a level's entries have to land
	/// beside its own vertices or every appended vertex would be skinned by the wrong bone.
	[Test]
	public static void ASkinnedLevelAppendsItsSkinningStreamInLockstep()
	{
		let baseMesh = MeshFixture.SkinnedTriangle("Part", 0.0f, 7);
		defer delete baseMesh;

		let source = scope SkinnedMeshSource();
		MeshConvert.SkinnedFromModel(baseMesh, 2, source);
		Test.Assert(source.SkinningBlob.Count == 3 * sizeof(VertexSkinning));

		let level = MeshFixture.SkinnedTriangle("Part_LOD1", 50.0f, 9);
		defer delete level;
		Test.Assert(LodChain.AppendFromModel(level, source));

		Test.Assert(source.LodCount == 2);
		Test.Assert(source.VertexBlob.Count == 6 * sizeof(StaticMeshVertex));
		Test.Assert(source.SkinningBlob.Count == 6 * sizeof(VertexSkinning));

		let skinning = (VertexSkinning*)source.SkinningBlob.Ptr;
		Test.Assert(skinning[2].Joints[0] == 7); // the base's entries are intact
		Test.Assert(skinning[3].Joints[0] == 9); // the level's follow them
		Test.Assert(source.LodStart[0] == 3);
		Test.Assert(source.IndexData[3] == 3);
	}
}
