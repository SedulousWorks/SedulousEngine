using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// The meshes answer rays against what they draw (ISceneSurfaceQuery): the nearest hit among
/// them, the hit triangle's nearest corner in world space (scaled and moved), the entities a
/// caller turns away, and inactive ones never.
class SurfaceQueryTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void ARayFindsTheNearestMeshAndTheVertexNearestItsHit()
	{
		let scene = scope Scene("world");
		let meshes = scene.AddSystem<MeshComponentManager>();
		let cube = Primitives.Cube(2.0f); // faces at plus and minus 1
		defer delete cube;

		// A cube at x = 10, doubled: its faces at plus and minus 2 about (10, 0, 0).
		let nearCube = scene.CreateEntity("near");
		var transform = Transform();
		transform.Position = .(10.0f, 0.0f, 0.0f);
		transform.Scale = .(2.0f, 2.0f, 2.0f);
		scene.SetLocalTransform(nearCube, transform);
		meshes.Add(nearCube).Mesh.SetDirect(cube);
		// A second cube behind it, at x = 20.
		let farCube = scene.CreateEntity("far");
		scene.SetLocalPosition(farCube, .(20.0f, 0.0f, 0.0f));
		meshes.Add(farCube).Mesh.SetDirect(cube);
		scene.UpdateTransforms();

		// Along +x through (0, 0.5, 0.3): the near cube's face at x = 8 first.
		Test.Assert(scene.RaycastSurface(.(0, 0.5f, 0.3f), .(1, 0, 0), 100.0f, null, var hit));
		Test.Assert(hit.Entity == nearCube);
		Test.Assert(Near(hit.Distance, 8.0f) && Near(hit.Position.X, 8.0f));
		Test.Assert(Near(hit.Normal.X, -1.0f));
		// The face's corners are (8, +-2, +-2); the one nearest (8, 0.5, 0.3) is (8, 2, 2).
		Test.Assert(Near(hit.Vertex.X, 8.0f) && Near(hit.Vertex.Y, 2.0f) && Near(hit.Vertex.Z, 2.0f));

		// Turn the near cube away (a dragged entity never snaps onto itself): the far one.
		Test.Assert(scene.RaycastSurface(.(0, 0.5f, 0.3f), .(1, 0, 0), 100.0f, scope (entity) => entity != nearCube, out hit));
		Test.Assert(hit.Entity == farCube);
		Test.Assert(Near(hit.Distance, 19.0f));

		// Out of reach: a miss.
		Test.Assert(!scene.RaycastSurface(.(0, 0.5f, 0.3f), .(1, 0, 0), 5.0f, null, out hit));

		// An inactive entity draws nothing, so a ray meets nothing of it.
		scene.SetActive(nearCube, false);
		Test.Assert(scene.RaycastSurface(.(0, 0.5f, 0.3f), .(1, 0, 0), 100.0f, null, out hit));
		Test.Assert(hit.Entity == farCube);
	}
}
