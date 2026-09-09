using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// Choosing a mesh's level of detail.
class MeshLodTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// A ninety degree field of view, which makes the projection's vertical term exactly one
	/// and the arithmetic checkable by hand.
	private static ViewCamera PerspectiveCam()
	{
		var camera = ViewCamera();
		camera.View = Float4x4.Identity();
		camera.Projection = Float4x4.PerspectiveFovRH(HalfPi, 1.0f, 0.1f, 1000.0f);
		return camera;
	}

	/// Three levels, taking over at a quarter and at a twentieth of the screen.
	private static StaticMesh ThreeLodMesh()
	{
		let mesh = new StaticMesh();
		mesh.LodCount = 3;
		mesh.LodCoverage.Add(1.0f);
		mesh.LodCoverage.Add(0.25f);
		mesh.LodCoverage.Add(0.05f);
		return mesh;
	}

	/// Coverage HALVES with distance under perspective, which is what makes the thresholds
	/// mean something in world terms.
	[Test]
	public static void CoverageHalvesWithDistance()
	{
		let camera = PerspectiveCam();

		let near = MeshLod.LodCoverageFor(camera, .(0, 0, -10.0f), 1.0f, 0.0f);
		let far = MeshLod.LodCoverageFor(camera, .(0, 0, -20.0f), 1.0f, 0.0f);

		Test.Assert(Near(near, 0.1f));
		Test.Assert(Near(far, near * 0.5f));
	}

	/// Something BEHIND the camera clamps rather than dividing by nothing or going negative.
	[Test]
	public static void SomethingBehindTheCameraStillAnswers()
	{
		let camera = PerspectiveCam();
		Test.Assert(MeshLod.LodCoverageFor(camera, .(0, 0, 5.0f), 1.0f, 0.0f) > 0.0f);
	}

	/// An orthographic view is DEPTH FREE: an object does not shrink with distance, so its
	/// coverage does not either.
	[Test]
	public static void OrthographicCoverageIgnoresDepth()
	{
		var camera = ViewCamera();
		camera.View = Float4x4.Identity();
		camera.Projection = Float4x4.OrthographicRH(10.0f, 10.0f, 0.1f, 100.0f);

		let near = MeshLod.LodCoverageFor(camera, .(0, 0, -1.0f), 1.0f, 0.0f);
		let far = MeshLod.LodCoverageFor(camera, .(0, 0, -90.0f), 1.0f, 0.0f);
		Test.Assert(Near(near, far));
	}

	/// Each unit of bias halves the effective coverage, in either direction.
	[Test]
	public static void EachUnitOfBiasHalvesTheCoverage()
	{
		let camera = PerspectiveCam();
		let unbiased = MeshLod.LodCoverageFor(camera, .(0, 0, -10.0f), 1.0f, 0.0f);

		Test.Assert(Near(MeshLod.LodCoverageFor(camera, .(0, 0, -10.0f), 1.0f, 1.0f),
			unbiased * 0.5f));
		Test.Assert(Near(MeshLod.LodCoverageFor(camera, .(0, 0, -10.0f), 1.0f, -1.0f),
			unbiased * 2.0f));
	}

	[Test]
	public static void ThePickWalksTheDescendingThresholds()
	{
		let mesh = ThreeLodMesh();
		defer delete mesh;

		Test.Assert(MeshLod.PickLodLevel(mesh, 0.50f) == 0, "large on screen, so the finest");
		Test.Assert(MeshLod.PickLodLevel(mesh, 0.25f) == 0, "exactly at the boundary");
		Test.Assert(MeshLod.PickLodLevel(mesh, 0.20f) == 1);
		Test.Assert(MeshLod.PickLodLevel(mesh, 0.04f) == 2);
		Test.Assert(MeshLod.PickLodLevel(mesh, 0.0f) == 2, "vanishing, so the coarsest");
	}

	/// A mesh with no chain is always its only level.
	[Test]
	public static void AChainlessMeshIsAlwaysLevelZero()
	{
		let mesh = scope StaticMesh();
		Test.Assert(MeshLod.PickLodLevel(mesh, 0.0f) == 0);
		Test.Assert(MeshLod.PickLodLevel(mesh, 1.0f) == 0);
	}

	/// A malformed, non descending tail STOPS the walk rather than coarsening past it: a
	/// broken chain should not make a mesh vanish into its lowest level.
	[Test]
	public static void AMalformedTailStopsTheWalk()
	{
		let mesh = ThreeLodMesh();
		defer delete mesh;
		mesh.LodCoverage[2] = 0.9f;

		Test.Assert(MeshLod.PickLodLevel(mesh, 0.5f) == 0);
	}

	/// A coverage list LONGER than the level count is clamped: selecting a level the mesh
	/// does not have would index past its submeshes.
	[Test]
	public static void TheThresholdsAreClampedToTheLevelsThatExist()
	{
		let mesh = ThreeLodMesh();
		defer delete mesh;
		mesh.LodCoverage.Add(0.001f);

		Test.Assert(MeshLod.MeshThresholds(mesh).Length == 3);
		Test.Assert(MeshLod.PickLodLevel(mesh, 0.0f) == 2);
	}

	/// Hysteresis keeps the previous level NEAR A BOUNDARY, which is where an item hovering
	/// would otherwise flicker between two levels every frame.
	[Test]
	public static void HysteresisHoldsTheLevelNearABoundary()
	{
		let mesh = ThreeLodMesh();
		defer delete mesh;

		// Just under the boundary: the raw pick drops a level, but the previous one is still
		// inside the band, so it stays.
		Test.Assert(MeshLod.PickLodLevel(mesh, 0.246f) == 1);
		Test.Assert(MeshLod.ApplyLodHysteresis(mesh, 0.246f, 1, 0) == 0);

		// And just over it, the other way.
		Test.Assert(MeshLod.PickLodLevel(mesh, 0.253f) == 0);
		Test.Assert(MeshLod.ApplyLodHysteresis(mesh, 0.253f, 0, 1) == 1);
	}

	/// FAR from any boundary the raw pick wins: hysteresis never pins a stale level.
	[Test]
	public static void HysteresisNeverPinsAStaleLevel()
	{
		let mesh = ThreeLodMesh();
		defer delete mesh;

		Test.Assert(MeshLod.ApplyLodHysteresis(mesh, 0.8f, 0, 2) == 0);
		Test.Assert(MeshLod.ApplyLodHysteresis(mesh, 0.01f, 2, 0) == 2);
		Test.Assert(MeshLod.ApplyLodHysteresis(mesh, 0.246f, 1, 1) == 1, "and matching is a no op");
	}
}
