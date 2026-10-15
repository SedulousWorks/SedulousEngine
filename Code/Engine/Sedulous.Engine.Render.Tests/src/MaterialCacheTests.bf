using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// The per submesh material cache, which extraction refreshes from the refs EVERY frame.
class MaterialCacheTests
{
	/// The multi material symptom: slots that resolve AFTER the first frame, a cook finishing
	/// in the background, must not stay null. The cache is not a one shot resolve time
	/// snapshot, so a late bind heals without reopening anything.
	[Test]
	public static void ExtractionRefreshesTheCacheFromTheRefsEveryFrame()
	{
		let scene = scope Scene("world");
		let meshes = scene.AddSystem<MeshComponentManager>();

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let builderA = scope MaterialBuilder("a");
		let matA = builderA..Shader("forward").Build();
		defer delete matA;
		let builderB = scope MaterialBuilder("b");
		let matB = builderB..Shader("forward").Build();
		defer delete matB;

		let entity = scene.CreateEntity("multi");
		let component = meshes.Add(entity);
		component.Mesh.SetDirect(cube);

		// Two slots: the first resolved, the second a bare id, which is the pre cook state.
		var resolved = Ref<Material>(Guid());
		resolved.SetDirect(matA);
		component.Materials.Add(resolved);

		var late = Ref<Material>(Guid());
		late.SetId(Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11));
		component.Materials.Add(late);

		scene.UpdateTransforms();

		{
			let first = scope ExtractedScene();
			RenderExtract.ExtractSceneInto(scene, first);
			Test.Assert(first.Size == 1);
			let data = (MeshRenderData)first.Items[0];
			// Slot zero doubles as the whole mesh material.
			Test.Assert(data.Material == matA);
			Test.Assert(data.SubmeshMaterialCount == 2);
			// Not cooked yet.
			Test.Assert(data.SubmeshMaterials[1] == null);
		}

		// The cook lands. A direct adopt stands in for the proxy binding.
		var healed = component.Materials[1];
		healed.SetDirect(matB);
		component.Materials[1] = healed;

		{
			let second = scope ExtractedScene();
			RenderExtract.ExtractSceneInto(scene, second);
			Test.Assert(second.Size == 1);
			let data = (MeshRenderData)second.Items[0];
			// Healed, with no reopen.
			Test.Assert(data.SubmeshMaterials[1] == matB);
		}

		// A SINGLE entry list is the whole mesh path with no submesh routing, which is how the
		// older single material setup is served through the same array.
		component.Materials.RemoveAt(1);
		{
			let third = scope ExtractedScene();
			RenderExtract.ExtractSceneInto(scene, third);
			let data = (MeshRenderData)third.Items[0];
			Test.Assert(data.Material == matA);
			Test.Assert(data.SubmeshMaterialCount == 0);
		}
	}

	/// An instanced mesh of several parts (a guest's body, gown and mask) carries a material per
	/// submesh slot, as a mesh does: slot 0 is the primary, several slots route per submesh, and
	/// the view is refreshed from the refs every frame.
	[Test]
	public static void AnInstancedMaterialListDrawsAPartPerSlotAndLateBindsHeal()
	{
		let scene = scope Scene("world");
		let sets = scene.AddSystem<InstancedMeshComponentManager>();

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let builderA = scope MaterialBuilder("a");
		let matA = builderA..Shader("forward").Build();
		defer delete matA;
		let builderB = scope MaterialBuilder("b");
		let matB = builderB..Shader("forward").Build();
		defer delete matB;

		let component = sets.Add(scene.CreateEntity("crowd"));
		component.Mesh.SetDirect(cube);
		var resolved = Ref<Material>(Guid());
		resolved.SetDirect(matA);
		component.Materials.Add(resolved);
		var late = Ref<Material>(Guid());
		late.SetId(Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11));
		component.Materials.Add(late);
		scene.UpdateTransforms();

		{
			let first = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, first);
			Test.Assert(first.Size == 1);
			let data = (MultiMeshRenderData)first.Items[0];
			Test.Assert(data.Material == matA);
			Test.Assert(data.SubmeshMaterialCount == 2);
			Test.Assert(data.SubmeshMaterials[1] == null, "not cooked yet");
		}

		var healed = component.Materials[1];
		healed.SetDirect(matB);
		component.Materials[1] = healed;
		{
			let second = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, second);
			let data = (MultiMeshRenderData)second.Items[0];
			Test.Assert(data.SubmeshMaterials[1] == matB, "healed, with no reopen");
		}

		// One material covers the whole mesh: no submesh routing.
		component.SetMaterial(matB);
		{
			let third = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, third);
			let data = (MultiMeshRenderData)third.Items[0];
			Test.Assert(data.Material == matB);
			Test.Assert(data.SubmeshMaterialCount == 0);
		}

		// Runtime code with the objects in hand fills a slot each.
		component.SetMaterials(Material[2](matB, matA));
		{
			let fourth = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, fourth);
			let data = (MultiMeshRenderData)fourth.Items[0];
			Test.Assert((data.Material == matB) && (data.SubmeshMaterialCount == 2) && (data.SubmeshMaterials[1] == matA));
		}
	}
}
