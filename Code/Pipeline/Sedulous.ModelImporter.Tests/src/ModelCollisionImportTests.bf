using System;
using Sedulous.Core;
using Sedulous.Physics.Pipeline;

namespace Sedulous.ModelImporter.Tests;

/// Collision shapes beside the meshes they are cooked from.
class ModelCollisionImportTests
{
	/// The collision array PARALLELS the meshes: a static mesh gets a shape, a skinned one
	/// stays empty, because a shape cooked from the bind pose is wrong the moment anything
	/// animates.
	[Test]
	public static void OnlyStaticMeshesGetAShape()
	{
		let fixture = scope ImportFixture("scratch_model_collision");
		let dropped = scope String();
		fixture.WriteDroppedFile("character.glb", "x", dropped);

		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);

		let options = scope ModelImportOptions();
		options.GenerateCollision = true;
		options.CollisionConvex = true;

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, options,
			prepared, null);
		Test.Assert(imported case .Ok);

		let manifest = ImportFixture.ReadManifest(imported.Value);
		Test.Assert(manifest != null);
		defer delete manifest;

		let source = manifest.Manifest;
		Test.Assert(source.CollisionGuid.Count == source.MeshGuid.Count);

		var shapeCount = 0;
		for (int i < source.CollisionGuid.Count)
		{
			if (source.MeshSkinned[i])
			{
				Test.Assert(source.CollisionGuid[i] == Guid.Empty);
				continue;
			}
			Test.Assert(source.CollisionGuid[i] != Guid.Empty);
			shapeCount++;

			let instance = fixture.Db.GetInstance(source.CollisionGuid[i]);
			Test.Assert(instance != null);
			let object = instance.ReadObject();
			Test.Assert(object != null);
			let shape = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
				as CollisionShapeAsset;
			Test.Assert(shape != null);
			defer delete shape;
			Test.Assert(shape.SourceMesh == source.MeshGuid[i]);
			Test.Assert(shape.Cook == .ConvexHull);
		}
		Test.Assert(shapeCount == 1);
	}
}
