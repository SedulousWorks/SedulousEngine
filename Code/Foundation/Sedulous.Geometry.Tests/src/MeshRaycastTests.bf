using System;
using Sedulous.Core;
using Sedulous.Geometry;

namespace Sedulous.Geometry.Tests;

/// A ray against a mesh's triangles: the nearest hit, from either side, and its nearest corner.
class MeshRaycastTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void TheNearestTriangleHitFromEitherSideAndItsNearestCorner()
	{
		// A 2 unit cube centred on the origin: its faces at plus and minus 1.
		let cube = Primitives.Cube(2.0f);
		defer delete cube;

		// Straight down onto the top face: the hit at y = 1, the normal facing the ray.
		Test.Assert(MeshRaycast.Raycast(cube, .(0.6f, 5.0f, 0.7f), .(0, -1, 0), 100.0f, var hit));
		Test.Assert(Near(hit.Distance, 4.0f));
		Test.Assert(Near(hit.Position.Y, 1.0f));
		Test.Assert(Near(hit.Normal.Y, 1.0f));
		// The corner nearest (0.6, 1, 0.7) is the top face's (1, 1, 1).
		let corner = MeshRaycast.NearestCorner(hit);
		Test.Assert(Near(corner.X, 1.0f) && Near(corner.Y, 1.0f) && Near(corner.Z, 1.0f));

		// From inside, the far face counts too (both faces).
		Test.Assert(MeshRaycast.Raycast(cube, .(0, 0, 0), .(1, 0, 0), 100.0f, out hit));
		Test.Assert(Near(hit.Distance, 1.0f));

		// A distance in units of an unnormalized direction (a world ray in the mesh's space).
		Test.Assert(MeshRaycast.Raycast(cube, .(0.2f, 5.0f, 0.2f), .(0, -2, 0), 100.0f, out hit));
		Test.Assert(Near(hit.Distance, 2.0f));

		// Out of reach, or past it: no hit.
		Test.Assert(!MeshRaycast.Raycast(cube, .(5, 5, 5), .(0, 1, 0), 100.0f, out hit));
		Test.Assert(!MeshRaycast.Raycast(cube, .(0.2f, 5.0f, 0.2f), .(0, -1, 0), 3.5f, out hit));

		// A mesh without triangles on the CPU never hits.
		let empty = scope StaticMesh();
		Test.Assert(!MeshRaycast.Raycast(empty, .(0, 5, 0), .(0, -1, 0), 100.0f, out hit));
	}
}
