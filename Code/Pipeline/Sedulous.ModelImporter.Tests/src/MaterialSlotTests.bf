using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Model;
using Sedulous.Model.Resource;
using Sedulous.Geometry;

namespace Sedulous.ModelImporter.Tests;

/// The per mesh material slots: what a mesh's parts claim, and what its cooked submeshes
/// index once they are remapped onto those slots.
static class MaterialSlotTests
{
	private static ModelMesh PartedMesh(Span<int32> materialIndices)
	{
		uint32[6] indices = .(0, 1, 2, 0, 1, 2);
		let mesh = MeshFixture.Row("parted", 0.0f, 3, .(&indices[0], indices.Count));
		for (int32 i < (int32)materialIndices.Length)
			mesh.AddPart(.(i * 3, 3, materialIndices[i]));
		return mesh;
	}

	[Test]
	public static void ASlotListNamesEachMaterialOnceInFirstAppearanceOrder()
	{
		int32[4] used = .(7, 3, 7, -1); // three parts over two materials, one part with none
		let mesh = PartedMesh(.(&used[0], used.Count));
		defer delete mesh;

		let slots = scope List<int32>();
		MeshConvert.CollectMaterialSlots(mesh, slots);
		Test.Assert(slots.Count == 2);
		Test.Assert(slots[0] == 7); // first appearance, not sorted
		Test.Assert(slots[1] == 3);
	}

	[Test]
	public static void CookedSubmeshesIndexTheSlotsRatherThanTheModelsMaterials()
	{
		int32[4] used = .(7, 3, 7, -1);
		let mesh = PartedMesh(.(&used[0], used.Count));
		defer delete mesh;

		let source = scope StaticMeshSource();
		MeshConvert.CopyParts(mesh, source);
		Test.Assert(source.SubMaterial.Count == 4);
		Test.Assert(source.SubMaterial[0] == 0);
		Test.Assert(source.SubMaterial[1] == 1);
		Test.Assert(source.SubMaterial[2] == 0); // the repeat reads the SAME slot
		Test.Assert(source.SubMaterial[3] == -1); // no material claims no slot
	}

	[Test]
	public static void TheManifestCutsTheConcatenatedSlotsPerMesh()
	{
		let manifest = scope ModelManifestSource();
		int32[2] first = .(7, 3);
		int32[1] third = .(2);
		manifest.AddMeshMaterialSlots(.(&first[0], first.Count));
		manifest.AddMeshMaterialSlots(.()); // a held LOD slot draws nothing
		manifest.AddMeshMaterialSlots(.(&third[0], third.Count));

		Test.Assert(manifest.MaterialSlotsOf(0).Length == 2);
		Test.Assert(manifest.MaterialSlotsOf(0)[1] == 3);
		Test.Assert(manifest.MaterialSlotsOf(1).IsEmpty);
		Test.Assert(manifest.MaterialSlotsOf(2).Length == 1);
		Test.Assert(manifest.MaterialSlotsOf(2)[0] == 2);
		// Out of range, and a manifest that recorded nothing, both read as no slots.
		Test.Assert(manifest.MaterialSlotsOf(3).IsEmpty);
		Test.Assert(manifest.MaterialSlotsOf(-1).IsEmpty);
		Test.Assert(scope ModelManifestSource().MaterialSlotsOf(0).IsEmpty);
	}
}
