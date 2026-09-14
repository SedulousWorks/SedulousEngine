using System;
using Sedulous.Core;

namespace Sedulous.ModelImporter.Tests;

/// A folded level still holds its manifest slot.
class ModelLodSlotTests
{
	/// A node names its mesh by MODEL mesh index. Dropping a folded level's entry shifted
	/// every later slot, so the node pointed at the wrong mesh or off the end of the array,
	/// and a generated prefab silently lost meshes on any model with authored levels.
	[Test]
	public static void AFoldedLevelHoldsAnEmptySlotSoNodeIndicesStayValid()
	{
		let fixture = scope ImportFixture("scratch_model_lodslot");
		let dropped = scope String();
		fixture.WriteDroppedFile("lodtest.glb", "x", dropped);

		let prepared = scope LoadedModel();
		ModelFixture.LevelBeforeBase(prepared.Model);

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			prepared, null);
		Test.Assert(imported case .Ok);

		let manifest = ImportFixture.ReadManifest(imported.Value);
		Test.Assert(manifest != null);
		defer delete manifest;

		let source = manifest.Manifest;
		Test.Assert(source.MeshGuid.Count == 2);
		Test.Assert(source.MeshGuid[0] == Guid.Empty); // the level, folded away
		Test.Assert(source.MeshGuid[1] != Guid.Empty); // the base, a real asset
		Test.Assert(source.NodeParent.Count == 1);
		Test.Assert(source.NodeMesh[0] == 1);

		let group = imported.Value.OwningGroup;
		let part = group.GetInstance("Part");
		Test.Assert(part != null);
		Test.Assert(part.Id == source.MeshGuid[1]);
		Test.Assert(group.GetInstance("Part_LOD1") == null);
	}
}
