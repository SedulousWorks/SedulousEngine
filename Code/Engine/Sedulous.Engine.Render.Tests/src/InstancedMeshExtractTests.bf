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

	/// Members draw after the authored instances, where they are, on their clips; a moved one
	/// follows, an inactive or stray one is not drawn, and the set's own list stays its own.
	[Test]
	public static void MembersDrawAfterTheAuthoredInstancesWhereTheyAreOnTheirClips()
	{
		let scene = scope Scene("world");
		let sets = scene.AddSystem<InstancedMeshComponentManager>();
		let members = scene.AddSystem<InstanceMemberComponentManager>();
		let cube = Primitives.Cube(1.0f);
		defer delete cube;

		// A crowd: the set's own entity at x = 5 with one authored instance on clip 1, and two
		// guests moved as entities, on clips 2 and 3.
		let crowd = scene.CreateEntity("Guests");
		scene.SetLocalPosition(crowd, .(5, 0, 0));
		let set = sets.Add(crowd);
		set.Mesh.SetDirect(cube);
		set.InstanceClips.Add(1);
		EntityHandle Guest(StringView name, Float3 at, uint32 clip)
		{
			let e = scene.CreateEntity(name);
			scene.SetLocalPosition(e, at);
			let member = members.Add(e);
			member.InstancedMesh.Id = scene.GetEntityId(crowd);
			member.Clip = clip;
			return e;
		}
		let a = Guest("A", .(10, 0, 0), 2);
		let b = Guest("B", .(0, 0, 20), 3);
		scene.UpdateTransforms();

		uint32 firstVersion = 0;
		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
			Test.Assert(snapshot.Size == 1);
			let data = (MultiMeshRenderData)snapshot.Items[0];
			Test.Assert(data.InstanceCount == 3);
			Test.Assert(Near(data.Transforms[0].M[3][0], 5.0f), "the authored instance, entity relative");
			Test.Assert(Near(data.Transforms[1].M[3][0], 10.0f), "A at its own world position");
			Test.Assert(Near(data.Transforms[2].M[3][2], 20.0f), "B");
			Test.Assert(data.InstanceClips != null);
			Test.Assert((data.InstanceClips[0] == 1) && (data.InstanceClips[1] == 2) && (data.InstanceClips[2] == 3));
			firstVersion = data.Version;
		}

		// A member moves: its instance follows on the next extract (a new upload).
		scene.SetLocalPosition(a, .(12, 0, 0));
		scene.UpdateTransforms();
		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
			let data = (MultiMeshRenderData)snapshot.Items[0];
			Test.Assert(Near(data.Transforms[1].M[3][0], 12.0f));
			Test.Assert(data.Version != firstVersion);
		}

		// An inactive member, or one naming no instanced mesh, is not drawn.
		scene.SetActive(b, false);
		let stray = scene.CreateEntity("Stray");
		members.Add(stray).InstancedMesh.Id = Guid(9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9);
		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
			Test.Assert(((MultiMeshRenderData)snapshot.Items[0]).InstanceCount == 2);
		}

		// With no authored instances the set draws its members alone.
		set.SetInstances(default);
		set.InstanceClips.Clear();
		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
			Test.Assert(snapshot.Size == 1);
			let data = (MultiMeshRenderData)snapshot.Items[0];
			Test.Assert(data.InstanceCount == 1);
			Test.Assert(Near(data.Transforms[0].M[3][0], 12.0f));
			Test.Assert(data.InstanceClips[0] == 2);
		}
		// Members are drawn, never authored: the set's own list stays empty for a save.
		Test.Assert(set.Instances.IsEmpty);
	}
}
