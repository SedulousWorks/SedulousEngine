using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Resource;
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
		// A second part: a multi material mesh.
		let maskId = Guid(3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);

		let blob = scope MemoryStream();
		{
			let scene = scope Scene();
			let sets = scene.AddSystem<InstancedMeshComponentManager>();
			let entity = scene.CreateEntity("Scatter");
			let component = sets.Add(entity);
			component.Mesh.SetId(meshId);
			// One per submesh slot.
			for (let id in Guid[2](materialId, maskId))
				component.Materials.Add(Ref<Material>(id));

			// Replace the editor workflow seed: a fresh component starts with ONE identity
			// instance.
			Test.Assert(component.Count == 1);
			Float4x4[2] authored = .(Float4x4.Translation(.(1, 0, 0)),
				Float4x4.Translation(.(0, 2, 0)));
			component.SetInstances(.(&authored[0], 2));
			component.Tints.Add(Color(1, 0, 0, 1));
			component.Tints.Add(Color(0, 1, 0, 1));
			// How the animated instances pick their poses is authored too.
			component.PoseAssignment = .Unison;
			component.PoseIndices.Add(3);
			component.PoseIndices.Add(5);
			component.InstanceClips.Add(0);
			component.InstanceClips.Add(2);

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
		Test.Assert(component.Materials.Count == 2);
		Test.Assert(component.Materials[0].Id == materialId);
		Test.Assert(component.Materials[1].Id == maskId);
		Test.Assert(component.Count == 2);
		Test.Assert(Near(component.Instances[0].M[3][0], 1.0f));
		Test.Assert(Near(component.Instances[1].M[3][1], 2.0f));
		Test.Assert(component.Tints.Count == 2);
		Test.Assert(Near(component.Tints[1].G, 1.0f));
		Test.Assert(component.PoseAssignment == .Unison);
		Test.Assert((component.PoseIndices.Count == 2) && (component.PoseIndices[1] == 5));
		Test.Assert((component.InstanceClips.Count == 2) && (component.InstanceClips[1] == 2));

		// The runtime state starts fresh, so the FIRST extract recomposes and re-uploads.
		Test.Assert(component.Version >= 1);
		Test.Assert(component.BoundsVersion == 0);
		Test.Assert(component.PosePool == null);
	}

	/// A version 1 record saved one material: it reads as slot 0, and the pose fields it never
	/// had keep a fresh set's.
	[Test]
	public static void AVersionOneRecordReadsItsMaterialAsSlotZero()
	{
		let meshId = Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		let materialId = Guid(2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
		let stream = scope MemoryStream();
		{
			// The version 1 fields, by hand.
			let writer = scope BinarySerializer(stream, .Write);
			var mesh = meshId;
			SerializeValue(writer, "mesh", ref mesh);
			var material = materialId;
			SerializeValue(writer, "material", ref material);
			let instances = scope List<Float4x4>() { Float4x4.Translation(.(4, 0, 0)) };
			writer.Key("instances");
			SerializeList(writer, instances);
			var color = Color(1, 1, 1, 1);
			writer.Key("color");
			Sedulous.Core.Serialization.Serialize(writer, ref color);
			let tints = scope List<Color>();
			writer.Key("tints");
			SerializeList(writer, tints);
			var visible = true;
			SerializeValue(writer, "visible", ref visible);
			var trailing = 77u;
			SerializeValue(writer, "trailing", ref trailing);
			Test.Assert(writer.IsOk);
		}

		let scene = scope Scene();
		let component = scene.AddSystem<InstancedMeshComponentManager>().Add(scene.CreateEntity("Scatter"));
		stream.Seek(0, .Begin);
		let reader = scope BinarySerializer(stream, .Read);
		reader.PushVersionScope(scope SerializedDataVersion[](.(TypeIdOf("instanced_mesh"), 1)));
		component.Serialize(reader);
		uint32 trailing = 0;
		SerializeValue(reader, "trailing", ref trailing);
		reader.PopVersionScope();
		Test.Assert(reader.IsOk);
		Test.Assert(component.Mesh.Id == meshId);
		Test.Assert((component.Materials.Count == 1) && (component.Materials[0].Id == materialId), "the one material is slot 0");
		Test.Assert((component.Count == 1) && Near(component.Instances[0].M[3][0], 4.0f));
		Test.Assert(component.PoseAssignment == .Hashed);
		Test.Assert(trailing == 77, "nothing past the version 1 fields was consumed");
	}
}
