using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Navigation;
using static Sedulous.Navigation.Tests.NavigationFixture;

namespace Sedulous.Navigation.Tests;

/// Pathfinding, and the debug surface the mesh reports.
class NavigationQueryTests
{
	/// A straight line through an obstacle has to DETOUR, and a destination that is not on the
	/// mesh at all fails rather than quietly answering something.
	[Test]
	public static void APathRoutesAroundAnObstacleAndAnOffMeshEndFails()
	{
		let blob = scope List<uint8>();
		Test.Assert(BakeGround(blob, 10.0f, true) case .Ok);

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blob) case .Ok);
		Test.Assert(mesh.IsValid);

		let query = scope NavigationMeshQuery(mesh);
		Test.Assert(query.IsValid);

		let path = scope NavigationPath();
		Test.Assert(query.FindPath(.(-8, 0, 0), .(8, 0, 0), path) case .Ok);
		Test.Assert(path.Complete);
		Test.Assert(path.Corners.Count >= 3, "a start, a detour corner and an end");

		var maxAbsZ = 0.0f;
		for (let corner in path.Corners)
			maxAbsZ = Max(maxAbsZ, Abs(corner.Z));
		// The box is two either side of the line, which runs along z of nought.
		Test.Assert(maxAbsZ > 1.5f, "it went round rather than through");

		let offMesh = scope NavigationPath();
		Test.Assert(query.FindPath(.(-8, 0, 0), .(100, 0, 100), offMesh) case .Err);
		Test.Assert(!offMesh.Complete);
	}

	/// A destination on the mesh but UNREACHABLE is reported rather than failed: the corners
	/// lead as far as they can, which is almost always what a caller wants.
	[Test]
	public static void ADisconnectedDestinationIsReportedIncompleteRatherThanFailed()
	{
		let verts = scope List<Float3>();
		let indices = scope List<uint32>();
		// Two islands with a gap: both ends snap onto the mesh, and nothing joins them.
		AddGround(verts, indices, -10, -3, -5, 5);
		AddGround(verts, indices, 3, 10, -5, 5);

		let blob = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.Build(verts, indices, .(), blob) case .Ok);

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blob) case .Ok);
		let query = scope NavigationMeshQuery(mesh);
		Test.Assert(query.IsValid);

		let path = scope NavigationPath();
		Test.Assert(query.FindPath(.(-6, 0, 0), .(6, 0, 0), path) case .Ok, "both ends are on it");
		Test.Assert(!path.Complete, "and there is no way between them");
	}

	[Test]
	public static void TheNearestPointSnapsOntoTheMesh()
	{
		let blob = scope List<uint8>();
		Test.Assert(BakeGround(blob, 10.0f) case .Ok);

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blob) case .Ok);
		let query = scope NavigationMeshQuery(mesh);

		// Above the floor, within the search box.
		Test.Assert(query.FindNearestPoint(.(3.0f, 2.0f, 3.0f), let onMesh));
		Test.Assert(Abs(onMesh.Y) < 1.0f);
		Test.Assert(Abs(onMesh.X - 3.0f) < 1.0f);

		// Nowhere near it.
		Test.Assert(!query.FindNearestPoint(.(500.0f, 0.0f, 500.0f), ?));
	}

	/// The debug triangles come off the LIVE mesh, which is exactly what queries path on: an
	/// outline captured at bake time would hide a load or version drift rather than show it.
	[Test]
	public static void TheDebugTrianglesEnumerateTheLiveSurface()
	{
		let blob = scope List<uint8>();
		Test.Assert(BakeGround(blob, 10.0f) case .Ok);

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blob) case .Ok);

		let tris = scope List<Float3>();
		mesh.DebugTriangles(tris);
		Test.Assert(!tris.IsEmpty);
		Test.Assert((tris.Count % 3) == 0, "whole triangles");

		// Everything sits within the ground, allowing a cell of slack at the edges.
		const float cPad = 0.3f + 0.001f;
		for (let v in tris)
		{
			Test.Assert(v.X >= (-10.0f - cPad));
			Test.Assert(v.X <= (10.0f + cPad));
			Test.Assert(v.Z >= (-10.0f - cPad));
			Test.Assert(v.Z <= (10.0f + cPad));
		}

		// APPENDS rather than fills, so several meshes may draw into one buffer.
		let firstCount = tris.Count;
		mesh.DebugTriangles(tris);
		Test.Assert(tris.Count == (firstCount * 2));
	}

	/// A query over a mesh that holds nothing is INVALID rather than crashing, and every call
	/// on it is a no-op.
	[Test]
	public static void AQueryOverAnEmptyMeshIsSafelyInvalid()
	{
		let mesh = scope NavigationMesh();
		Test.Assert(!mesh.IsValid);

		let query = scope NavigationMeshQuery(mesh);
		Test.Assert(!query.IsValid);

		let path = scope NavigationPath();
		Test.Assert(query.FindPath(.(0, 0, 0), .(1, 0, 1), path) case .Err);
		Test.Assert(!query.FindNearestPoint(.(0, 0, 0), ?));

		// And so is a crowd.
		let crowd = scope NavigationCrowd(mesh, 4, 0.6f);
		Test.Assert(!crowd.IsValid);
		Test.Assert(crowd.AddAgent(.(0, 0, 0), .()) == -1);
		Test.Assert(!crowd.IsAgentValid(0));
	}
}
