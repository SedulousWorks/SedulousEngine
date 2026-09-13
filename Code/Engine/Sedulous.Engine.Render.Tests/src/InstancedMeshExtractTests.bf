using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// Instanced sets: seeded, composed with their entity, and recomposed only when something
/// actually moved.
class InstancedMeshExtractTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void ASeededSetComposesWithItsEntityAndRecomposesOnlyOnAChange()
	{
		let scene = scope Scene("world");
		let sets = scene.AddSystem<InstancedMeshComponentManager>();
		let cube = Primitives.Cube(1.0f);
		defer delete cube;

		// A fresh component is seeded with ONE identity instance, which is the editor
		// workflow: assign a mesh and see it render at the entity.
		let entity = scene.CreateEntity("scatter");
		scene.SetLocalPosition(entity, .(5, 0, 0));
		let component = sets.Add(entity);
		Test.Assert(component.Count == 1);
		component.Mesh.SetDirect(cube);
		scene.UpdateTransforms();

		uint32 firstVersion = 0;
		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
			Test.Assert(snapshot.Size == 1);
			let data = (MultiMeshRenderData)snapshot.Items[0];
			Test.Assert(data.InstanceCount == 1);
			// The identity instance times the entity's world matrix.
			Test.Assert(Near(data.Transforms[0].M[3][0], 5.0f));
			Test.Assert(Near(data.WorldCenter.X, 5.0f));
			firstVersion = data.Version;
		}

		// Moving the ENTITY moves the set: the composed transforms change and the renderer's
		// upload key bumps, even though the authored set did not change.
		scene.SetLocalPosition(entity, .(5, 7, 0));
		scene.UpdateTransforms();

		uint32 movedVersion = 0;
		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
			let data = (MultiMeshRenderData)snapshot.Items[0];
			Test.Assert(Near(data.Transforms[0].M[3][1], 7.0f));
			Test.Assert(data.Version != firstVersion);
			movedVersion = data.Version;
		}

		// Unmoved and unchanged: no recompose, so a static set stays free.
		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
			let data = (MultiMeshRenderData)snapshot.Items[0];
			Test.Assert(data.Version == movedVersion);
		}

		// Authored instances are ENTITY RELATIVE: replace the seed with two local offsets.
		Float4x4[2] authored = .(Float4x4.Translation(.(1, 0, 0)), Float4x4.Translation(.(-1, 0, 0)));
		component.SetInstances(.(&authored[0], 2));

		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
			let data = (MultiMeshRenderData)snapshot.Items[0];
			Test.Assert(data.InstanceCount == 2);
			Test.Assert(Near(data.Transforms[0].M[3][0], 6.0f));
			Test.Assert(Near(data.Transforms[1].M[3][0], 4.0f));
		}
	}
}
