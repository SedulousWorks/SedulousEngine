using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Render.Tests;

/// An instanced set's references and its AUTHORED placement, which is what an artist scattered
/// rather than anything composed at extract.
class InstancedMeshRefTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void RefsAndAuthoredPlacementRoundTrip()
	{
		let meshId = Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		let materialId = Guid(2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);

		let blob = scope MemoryStream();
		{
			let scene = scope Scene();
			let sets = scene.AddSystem<InstancedMeshComponentManager>();
			let entity = scene.CreateEntity("Scatter");
			let component = sets.Add(entity);
			component.Mesh.SetId(meshId);
			component.Material.SetId(materialId);

			// Replace the editor workflow seed: a fresh component starts with ONE identity
			// instance.
			Test.Assert(component.Count == 1);
			Float4x4[2] authored = .(Float4x4.Translation(.(1, 0, 0)),
				Float4x4.Translation(.(0, 2, 0)));
			component.SetInstances(.(&authored[0], 2));
			component.Tints.Add(Color(1, 0, 0, 1));
			component.Tints.Add(Color(0, 1, 0, 1));

			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, scene);
			Test.Assert(writer.IsOk);
		}

		let loaded = scope Scene();
		loaded.AddSystem<InstancedMeshComponentManager>();
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		InstancedMeshComponent* component = null;
		loaded.GetSystem<InstancedMeshComponentManager>().ForEach(scope [&] (found, entity) =>
			{
				component = found;
			});
		Test.Assert(component != null);
		Test.Assert(component.Mesh.Id == meshId);
		Test.Assert(component.Material.Id == materialId);
		Test.Assert(component.Count == 2);
		Test.Assert(Near(component.Instances[0].M[3][0], 1.0f));
		Test.Assert(Near(component.Instances[1].M[3][1], 2.0f));
		Test.Assert(component.Tints.Count == 2);
		Test.Assert(Near(component.Tints[1].G, 1.0f));

		// The runtime state starts fresh, so the FIRST extract recomposes and re-uploads.
		Test.Assert(component.Version >= 1);
		Test.Assert(component.BoundsVersion == 0);
		Test.Assert(component.PosePool == null);
	}
}
