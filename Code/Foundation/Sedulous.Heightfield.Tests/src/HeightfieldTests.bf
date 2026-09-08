using System;
using Sedulous.Core;
using Sedulous.Heightfield;

namespace Sedulous.Heightfield.Tests;

/// The grid and the sampling maths over it.
class HeightfieldTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// A 65 grid over a 64 by 64 world with a Y range of zero to ten, ramping along +X: the
	/// height at a point is then a known number rather than an assertion about itself.
	private static Heightfield MakeRampX()
	{
		let field = new Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		for (int32 z = 0; z < 65; z++)
		{
			for (int32 x = 0; x < 65; x++)
			{
				let t = (float)x / 64.0f;
				field.SetSample(x, z, (uint16)(t * 65535.0f + 0.5f));
			}
		}
		return field;
	}

	[Test]
	public static void OnlySquareGridsOfSixtyFourKPlusOneAreValid()
	{
		Test.Assert(Heightfield.IsValidSize(65));
		Test.Assert(Heightfield.IsValidSize(129));
		Test.Assert(Heightfield.IsValidSize(257));
		Test.Assert(Heightfield.IsValidSize(1025));

		Test.Assert(!Heightfield.IsValidSize(64), "one short");
		Test.Assert(!Heightfield.IsValidSize(66), "not 64k + 1");
		Test.Assert(!Heightfield.IsValidSize(1), "too small");
		Test.Assert(!Heightfield.IsValidSize(128));
	}

	/// What an importer resamples to, and never below the smallest legal grid.
	[Test]
	public static void TheNextValidSizeRoundsUp()
	{
		Test.Assert(Heightfield.NextValidSize(1) == 65);
		Test.Assert(Heightfield.NextValidSize(65) == 65, "already legal");
		Test.Assert(Heightfield.NextValidSize(66) == 129);
		Test.Assert(Heightfield.NextValidSize(129) == 129);
		Test.Assert(Heightfield.NextValidSize(200) == 257);
	}

	/// A default grid answers rather than faulting, which is what a failed build leaves.
	[Test]
	public static void AnEmptyGridIsInert()
	{
		let field = scope Heightfield();

		Test.Assert(field.IsEmpty);
		Test.Assert(field.Size == 0);
		Test.Assert(field.GetHeightAt(0.0f, 0.0f) == 0.0f);
		Test.Assert(field.GetNormalAt(0.0f, 0.0f) == Float3(0.0f, 1.0f, 0.0f));
		Test.Assert(!field.QueryRay(.(0, 100, 0), .(0, -1, 0), let ignored));
	}

	[Test]
	public static void ConstructionZeroesTheGridAndSamplesRoundTrip()
	{
		let field = scope Heightfield(65, .(64.0f, 64.0f), -5.0f, 5.0f);

		Test.Assert(!field.IsEmpty);
		Test.Assert(field.Size == 65);
		Test.Assert(field.Samples.Length == 65 * 65);
		Test.Assert(field.MinY == -5.0f);
		Test.Assert(field.MaxY == 5.0f);

		field.SetSample(3, 7, 40000);
		Test.Assert(field.GetSample(3, 7) == 40000);
		Test.Assert(field.GetSample(4, 7) == 0, "the neighbour was untouched");
	}

	/// Every instance has its OWN identity, which is what a GPU cache keys on: a freed grid's
	/// address can be handed to a fresh one, and every fresh grid starts at version one.
	[Test]
	public static void EveryGridHasItsOwnIdentity()
	{
		let first = scope Heightfield(65, .(64, 64), 0, 10);
		let second = scope Heightfield(65, .(64, 64), 0, 10);

		Test.Assert(first.Uid != second.Uid);
		Test.Assert(first.Version == second.Version, "and they both start at one");
	}

	[Test]
	public static void EditingBumpsTheVersion()
	{
		let field = scope Heightfield(65, .(64, 64), 0, 10);
		let before = field.Version;

		field.BumpVersion();
		Test.Assert(field.Version == before + 1);
	}

	[Test]
	public static void QuantisationSpansTheWorldYRange()
	{
		let field = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);

		Test.Assert(Near(field.SampleToWorldY(0.0f), 0.0f));
		Test.Assert(Near(field.SampleToWorldY(65535.0f), 10.0f));
		Test.Assert(Near(field.SampleToWorldY(32767.5f), 5.0f));

		Test.Assert(field.WorldYToSample(0.0f) == 0);
		Test.Assert(field.WorldYToSample(10.0f) == 65535);
		Test.Assert(field.WorldYToSample(-1.0f) == 0, "clamped below");
		Test.Assert(field.WorldYToSample(99.0f) == 65535, "and above");
	}

	/// A grid with no Y range at all quantises to the floor rather than dividing by zero.
	[Test]
	public static void AZeroYRangeQuantisesToTheFloor()
	{
		let field = scope Heightfield(65, .(64, 64), 5.0f, 5.0f);
		Test.Assert(field.WorldYToSample(5.0f) == 0);
		Test.Assert(field.SampleToWorldY(65535.0f) == 5.0f);
	}

	[Test]
	public static void GridPointHeightsAreExact()
	{
		let field = MakeRampX();
		defer delete field;

		Test.Assert(Near(field.GetHeightAtGrid(0, 0), 0.0f));
		Test.Assert(Near(field.GetHeightAtGrid(64, 0), 10.0f));
		Test.Assert(Near(field.GetHeightAtGrid(32, 0), 5.0f));
	}

	[Test]
	public static void HeightsBetweenGridPointsInterpolate()
	{
		let field = MakeRampX();
		defer delete field;

		// World x of zero is the grid's centre column.
		Test.Assert(Near(field.GetHeightAt(0.0f, 0.0f), 5.0f));
		Test.Assert(Near(field.GetHeightAt(-32.0f, 0.0f), 0.0f));
		Test.Assert(Near(field.GetHeightAt(32.0f, 0.0f), 10.0f));
		// Halfway between the low edge and the centre.
		Test.Assert(Near(field.GetHeightAt(-16.0f, 0.0f), 2.5f));
	}

	/// Outside the footprint CLAMPS to the nearest edge rather than falling away, so a query
	/// off the side of the terrain still answers with the terrain's height.
	[Test]
	public static void SamplingClampsAtTheEdges()
	{
		let field = MakeRampX();
		defer delete field;

		Test.Assert(Near(field.GetHeightAt(-1000.0f, 0.0f), 0.0f));
		Test.Assert(Near(field.GetHeightAt(1000.0f, 0.0f), 10.0f));
	}

	[Test]
	public static void WorldAndGridCoordinatesRoundTrip()
	{
		let field = MakeRampX();
		defer delete field;

		let samples = float[5](-32.0f, -10.0f, 0.0f, 15.5f, 32.0f);
		for (let wx in samples)
		{
			let grid = field.WorldToGrid(wx, wx);
			let world = field.GridToWorld(grid.X, grid.Y);
			Test.Assert(Near(world.X, wx, 0.001f));
			Test.Assert(Near(world.Y, wx, 0.001f));
		}

		// The footprint's corners are the grid's extremes.
		let low = field.WorldToGrid(-32.0f, -32.0f);
		Test.Assert(Near(low.X, 0.0f) && Near(low.Y, 0.0f));
		let high = field.WorldToGrid(32.0f, 32.0f);
		Test.Assert(Near(high.X, 64.0f) && Near(high.Y, 64.0f));
	}

	[Test]
	public static void AFlatFieldPointsUpAndARampTilts()
	{
		let flat = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		for (var sample in ref flat.Samples)
			sample = 30000;

		let up = flat.GetNormalAt(0.0f, 0.0f);
		Test.Assert(Near(up.X, 0.0f) && Near(up.Y, 1.0f) && Near(up.Z, 0.0f));

		let ramp = MakeRampX();
		defer delete ramp;

		let tilted = ramp.GetNormalAt(0.0f, 0.0f);
		Test.Assert(tilted.X < 0.0f, "the surface rises toward +X, so the normal leans to -X");
		Test.Assert(tilted.Y > 0.0f);
		Test.Assert(Near(tilted.Z, 0.0f));
	}

	[Test]
	public static void CellBoundsReportTheRangeOverABlock()
	{
		let field = MakeRampX();
		defer delete field;

		field.CellBounds(0, 0, 64, 64, let wholeLow, let wholeHigh);
		Test.Assert(Near(wholeLow, 0.0f) && Near(wholeHigh, 10.0f));

		field.CellBounds(0, 0, 0, 64, let firstLow, let firstHigh);
		Test.Assert(Near(firstLow, 0.0f) && Near(firstHigh, 0.0f), "the first column is all zero");

		field.CellBounds(64, 0, 64, 64, let lastLow, let lastHigh);
		Test.Assert(Near(lastLow, 10.0f) && Near(lastHigh, 10.0f), "and the last is all ten");
	}

	[Test]
	public static void AStraightDownRayHitsTheSurface()
	{
		let field = MakeRampX();
		defer delete field;

		Test.Assert(field.QueryRay(.(0.0f, 100.0f, 0.0f), .(0.0f, -1.0f, 0.0f), let t));
		Test.Assert(Near(100.0f - t, 5.0f, 0.05f), "the centre of the ramp");

		Test.Assert(field.QueryRay(.(31.9f, 100.0f, 0.0f), .(0.0f, -1.0f, 0.0f), let edgeT));
		Test.Assert(Near(100.0f - edgeT, 10.0f, 0.1f), "and the tall edge");
	}

	[Test]
	public static void ARayThatMissesTheFootprintReturnsNothing()
	{
		let field = MakeRampX();
		defer delete field;

		Test.Assert(!field.QueryRay(.(1000.0f, 100.0f, 0.0f), .(0.0f, -1.0f, 0.0f), let far));
		Test.Assert(!field.QueryRay(.(32.5f, 100.0f, 0.0f), .(0.0f, -1.0f, 0.0f), let justOutside),
			"the footprint ends at 32");
		Test.Assert(!field.QueryRay(.(0.0f, 100.0f, 0.0f), .(0.0f, 1.0f, 0.0f), let upward),
			"pointing away from the surface");
	}

	[Test]
	public static void AnAngledRayDescendsOntoTheRamp()
	{
		let field = MakeRampX();
		defer delete field;

		Test.Assert(field.QueryRay(.(-30.0f, 20.0f, 0.0f), .(1.0f, -1.0f, 0.0f), let t));

		let unit = 0.70710678f;
		let hit = Float3(-30.0f + unit * t, 20.0f - unit * t, 0.0f);
		Test.Assert(Near(hit.Y, field.GetHeightAt(hit.X, hit.Z), 0.05f));
	}

	/// A ray that STARTS below the surface hits immediately, rather than marching out the far
	/// side of the grid and reporting a miss.
	[Test]
	public static void ARayStartingUnderTheSurfaceHitsAtOnce()
	{
		let field = MakeRampX();
		defer delete field;

		Test.Assert(field.QueryRay(.(0.0f, 1.0f, 0.0f), .(0.0f, -1.0f, 0.0f), let t));
		Test.Assert(Near(t, 0.0f), "at the entry point");
	}
}
