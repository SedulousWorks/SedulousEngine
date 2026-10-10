using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// The render managers measure their entities for the scene (ISceneEntityBounds): a mesh
/// through its world matrix, an instanced set by its merged sphere once extraction has
/// measured it.
class EntityBoundsTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void AMeshMeasuresThroughItsWorldMatrixAndASetByItsSphere()
	{
		let scene = scope Scene("world");
		let meshes = scene.AddSystem<MeshComponentManager>();
		let sets = scene.AddSystem<InstancedMeshComponentManager>();
		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let local = cube.Bounds;
		Test.Assert(local.IsValid());

		// A mesh scaled 2 and moved: its bounds through that matrix.
		let crate = scene.CreateEntity("crate");
		var transform = Transform();
		transform.Position = .(3.0f, 0.0f, 0.0f);
		transform.Scale = .(2.0f, 2.0f, 2.0f);
		scene.SetLocalTransform(crate, transform);
		let m = meshes.Add(crate);
		scene.UpdateTransforms();
		Test.Assert(!scene.EntityWorldBounds(crate, ?), "no mesh assigned yet");
		m.Mesh.SetDirect(cube);
		Test.Assert(scene.EntityWorldBounds(crate, let meshBounds));
		Test.Assert(Near(meshBounds.Min.X, 3.0f + 2.0f * local.Min.X));
		Test.Assert(Near(meshBounds.Max.X, 3.0f + 2.0f * local.Max.X));
		Test.Assert(Near(meshBounds.Max.Y, 2.0f * local.Max.Y));

		// An instanced set: nothing until extraction has measured it, then its merged sphere.
		let scatter = scene.CreateEntity("scatter");
		scene.SetLocalPosition(scatter, .(-5.0f, 0.0f, 0.0f));
		let set = sets.Add(scatter);
		set.Mesh.SetDirect(cube);
		scene.UpdateTransforms();
		Test.Assert(!scene.EntityWorldBounds(scatter, ?), "not measured by extraction yet");
		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
		Test.Assert(scene.EntityWorldBounds(scatter, let sphere));
		Test.Assert(Near(sphere.Center().X, -5.0f));
		Test.Assert(sphere.Extents().X > 0.0f);

		// An entity with neither.
		Test.Assert(!scene.EntityWorldBounds(scene.CreateEntity("empty"), ?));
	}
}
