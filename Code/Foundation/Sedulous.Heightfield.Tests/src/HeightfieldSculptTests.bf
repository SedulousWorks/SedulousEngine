using System;
using Sedulous.Core;
using Sedulous.Heightfield;

namespace Sedulous.Heightfield.Tests;

/// The sculpt brushes: what they move, what they leave alone, and what they report.
class HeightfieldSculptTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// A 129 grid over a 128 by 128 world with a Y range of zero to a hundred, so the grid
	/// centre is (64, 64) and world units and grid cells are one to one.
	private static Heightfield MakeFlat(uint16 sample = 0)
	{
		let field = new Heightfield(129, .(128.0f, 128.0f), 0.0f, 100.0f);
		for (var stored in ref field.Samples)
			stored = sample;
		return field;
	}

	[Test]
	public static void RaiseLiftsTheCentreMostAndFallsOffToTheRim()
	{
		let field = MakeFlat();
		defer delete field;
		let version = field.Version;

		let region = HeightfieldSculpt.Raise(field, 0.0f, 0.0f, 20.0f, 10.0f);

		Test.Assert(!region.IsEmpty);
		Test.Assert(field.Version == version + 1, "one re-upload signal per stroke step");
		Test.Assert((region.MinX <= 64) && (region.MaxX >= 64), "the centre is in the region");

		let center = field.GetHeightAtGrid(64, 64);
		let partWay = field.GetHeightAtGrid(74, 64);
		Test.Assert(center > 9.0f, "full weight at the centre");
		Test.Assert(center <= 10.01f, "and no more than the strength asked for");
		Test.Assert(partWay > 0.0f);
		Test.Assert(partWay < center, "the cosine falloff raised the rim less");
		Test.Assert(field.GetHeightAtGrid(0, 0) == 0.0f, "outside the radius, untouched");
	}

	/// The reported rectangle covers what was ACTUALLY touched, which is a disc rather than
	/// the scan box around it, so the corners of the box stay out of it.
	[Test]
	public static void TheRegionCoversTheDiscRatherThanItsBox()
	{
		let field = MakeFlat();
		defer delete field;

		let region = HeightfieldSculpt.Raise(field, 0.0f, 0.0f, 20.0f, 10.0f);

		Test.Assert(region.Width <= 41, scope $"the disc is 20 cells either side, got {region.Width}");
		Test.Assert(region.Height == region.Width, "and it is round");
		Test.Assert(field.GetHeightAtGrid(region.MinX, region.MinZ) == 0.0f,
			"the corner of the rectangle was never inside the disc");
	}

	[Test]
	public static void ANegativeStrengthLowersAndClampsAtTheFloor()
	{
		let field = MakeFlat(30000);
		defer delete field;

		HeightfieldSculpt.Raise(field, 0.0f, 0.0f, 20.0f, -1000.0f);
		Test.Assert(field.GetSample(64, 64) == 0, "clamped rather than wrapped");
	}

	/// And at the ceiling, which is the other end of the same clamp.
	[Test]
	public static void RaisingPastTheCeilingClamps()
	{
		let field = MakeFlat(30000);
		defer delete field;

		HeightfieldSculpt.Raise(field, 0.0f, 0.0f, 20.0f, 1000.0f);
		Test.Assert(field.GetSample(64, 64) == 65535);
	}

	[Test]
	public static void FlattenPullsTowardTheTarget()
	{
		let field = MakeFlat();
		defer delete field;
		for (var sample in ref field.Samples)
			sample = field.WorldYToSample(80.0f);

		HeightfieldSculpt.Flatten(field, 0.0f, 0.0f, 20.0f, 1.0f, 25.0f);

		Test.Assert(Near(field.GetHeightAtGrid(64, 64), 25.0f, 0.5f), "the centre reached it");
		Test.Assert(field.GetHeightAtGrid(64, 64) < 80.0f);
		Test.Assert(Near(field.GetHeightAtGrid(0, 0), 80.0f), "outside the radius, untouched");
	}

	/// A partial amount moves PART of the way, which is what makes a stroke build up over
	/// several steps rather than snapping.
	[Test]
	public static void APartialFlattenMovesPartWay()
	{
		let field = MakeFlat();
		defer delete field;
		for (var sample in ref field.Samples)
			sample = field.WorldYToSample(80.0f);

		HeightfieldSculpt.Flatten(field, 0.0f, 0.0f, 20.0f, 0.5f, 0.0f);

		let center = field.GetHeightAtGrid(64, 64);
		Test.Assert((center > 30.0f) && (center < 50.0f), scope $"halfway from 80 to 0, got {center}");
	}

	[Test]
	public static void SmoothReducesASpike()
	{
		let field = MakeFlat();
		defer delete field;
		field.SetSample(64, 64, field.WorldYToSample(90.0f));
		let before = field.GetHeightAtGrid(64, 64);

		HeightfieldSculpt.Smooth(field, 0.0f, 0.0f, 20.0f, 1.0f);
		let after = field.GetHeightAtGrid(64, 64);

		Test.Assert(after < before, "pulled toward its flat neighbourhood");
		Test.Assert(after >= 0.0f);
	}

	/// Smoothing a field that is ALREADY flat changes nothing, which is what says the
	/// neighbourhood average is the average and not a drift.
	[Test]
	public static void SmoothingAFlatFieldChangesNothing()
	{
		let field = MakeFlat(30000);
		defer delete field;

		HeightfieldSculpt.Smooth(field, 0.0f, 0.0f, 20.0f, 1.0f);
		Test.Assert(field.GetSample(64, 64) == 30000);
		Test.Assert(field.GetSample(70, 70) == 30000);
	}

	/// A brush entirely off the grid touches nothing, and says so by NOT bumping the
	/// version: a re-upload signal for an edit that never happened is wasted bandwidth.
	[Test]
	public static void ABrushOffTheGridTouchesNothing()
	{
		let field = MakeFlat();
		defer delete field;
		let version = field.Version;

		let region = HeightfieldSculpt.Raise(field, 100000.0f, 100000.0f, 5.0f, 10.0f);

		Test.Assert(region.IsEmpty);
		Test.Assert(region.Width == 0 && region.Height == 0);
		Test.Assert(field.Version == version);
	}

	/// A radius of zero or less is the same: nothing to visit.
	[Test]
	public static void ANonPositiveRadiusTouchesNothing()
	{
		let field = MakeFlat();
		defer delete field;

		Test.Assert(HeightfieldSculpt.Raise(field, 0.0f, 0.0f, 0.0f, 10.0f).IsEmpty);
		Test.Assert(HeightfieldSculpt.Raise(field, 0.0f, 0.0f, -5.0f, 10.0f).IsEmpty);
		Test.Assert(field.GetSample(64, 64) == 0);
	}

	/// An empty grid has nothing to sculpt, and answering rather than faulting is what lets a
	/// tool run against a field that failed to build.
	[Test]
	public static void SculptingAnEmptyGridIsInert()
	{
		let field = scope Heightfield();

		Test.Assert(HeightfieldSculpt.Raise(field, 0, 0, 10, 1).IsEmpty);
		Test.Assert(HeightfieldSculpt.Flatten(field, 0, 0, 10, 1, 0).IsEmpty);
		Test.Assert(HeightfieldSculpt.Smooth(field, 0, 0, 10, 1).IsEmpty);
		Test.Assert(field.Version == 1);
	}

	/// A brush overlapping the EDGE clips to the grid rather than reaching past it.
	[Test]
	public static void ABrushAtTheEdgeClipsToTheGrid()
	{
		let field = MakeFlat();
		defer delete field;

		// Centred on the low corner of the footprint.
		let region = HeightfieldSculpt.Raise(field, -64.0f, -64.0f, 20.0f, 10.0f);

		Test.Assert(!region.IsEmpty);
		Test.Assert(region.MinX == 0 && region.MinZ == 0);
		Test.Assert(field.GetHeightAtGrid(0, 0) > 9.0f, "the corner itself was raised");
	}
}
