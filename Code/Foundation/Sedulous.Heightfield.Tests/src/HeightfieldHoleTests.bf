using System;
using Sedulous.Core;

namespace Sedulous.Heightfield.Tests;

/// The per sample cut plane and the one rule every consumer reads it by: a triangle with a cut
/// vertex is gone.
class HeightfieldHoleTests
{
	private static Heightfield MakeFlat()
	{
		let field = new Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		let sample = field.WorldYToSample(5.0f);
		for (int32 z = 0; z < 65; z++)
			for (int32 x = 0; x < 65; x++)
				field.SetSample(x, z, sample);
		return field;
	}

	[Test]
	public static void AFreshGridIsSolidAndTheCountTracksEveryCut()
	{
		let field = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		Test.Assert(!field.HasHoles);
		Test.Assert(field.HoleCount == 0);
		Test.Assert(field.Holes.Length == 65 * 65, "a byte per sample, laid out like the heights");

		field.SetHole(10, 10, true);
		Test.Assert(field.IsHole(10, 10));
		Test.Assert(field.HoleCount == 1);
		Test.Assert(field.HasHoles);

		// Setting it again is not a second cut: the count is what every consumer's early out
		// reads, so it cannot drift.
		field.SetHole(10, 10, true);
		Test.Assert(field.HoleCount == 1);

		field.SetHole(10, 10, false);
		Test.Assert(field.HoleCount == 0);
		Test.Assert(!field.HasHoles);
		field.SetHole(10, 10, false);
		Test.Assert(field.HoleCount == 0);
	}

	[Test]
	public static void ACellIsGoneWhenAnyCornerIsCutAndABlockWhenAnySampleIs()
	{
		let field = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		Test.Assert(!field.CellHasHole(4, 4), "nothing cut, so nothing to test");

		// One corner of the cell at four, four.
		field.SetHole(5, 5, true);
		Test.Assert(field.CellHasHole(4, 4));
		Test.Assert(field.CellHasHole(5, 5));
		Test.Assert(field.CellHasHole(4, 5));
		Test.Assert(field.CellHasHole(5, 4));
		Test.Assert(!field.CellHasHole(3, 3), "two cells away is untouched");

		// A block asks its whole INTERIOR, not just its corners: a coarse quad covering a cut
		// sample goes, because a hole never shrinks with distance.
		Test.Assert(field.BlockHasHole(0, 0, 8, 8));
		Test.Assert(!field.BlockHasHole(0, 0, 4, 4));
		Test.Assert(field.BlockHasHole(5, 5, 5, 5));
	}

	[Test]
	public static void SettingTheWholePlaneTakesTheCookedBlobAndRefusesAnyOtherSize()
	{
		let field = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);

		let plane = scope uint8[65 * 65];
		plane[0] = 1;
		plane[65 * 65 - 1] = 200;
		Test.Assert(field.SetHoles(plane));
		Test.Assert(field.HoleCount == 2, "any non zero byte is a cut");
		Test.Assert(field.IsHole(0, 0));
		Test.Assert(field.IsHole(64, 64));
		Test.Assert(field.Holes[0] == 255, "normalised to the canonical cut byte");

		let wrong = scope uint8[10];
		Test.Assert(!field.SetHoles(wrong), "a blob of any other size is refused");
		Test.Assert(field.HoleCount == 2, "and the plane is left as it was");
	}

	[Test]
	public static void ARayPassesThroughACutCellRatherThanHittingIt()
	{
		let field = MakeFlat();
		defer delete field;

		// Straight down over the middle of a solid field: a hit.
		let origin = Float3(0.0f, 50.0f, 0.0f);
		let down = Float3(0.0f, -1.0f, 0.0f);
		Test.Assert(field.QueryRay(origin, down, let solidT));
		Test.Assert(Math.Abs(solidT - 45.0f) < 0.5f, "the surface sits five up");

		// Cut the cell under it, and the ray goes on through to whatever sits below.
		field.CellOfLocal(0.0f, 0.0f, let cx, let cz);
		field.SetHole(cx, cz, true);
		field.SetHole(cx + 1, cz, true);
		field.SetHole(cx, cz + 1, true);
		field.SetHole(cx + 1, cz + 1, true);
		Test.Assert(!field.QueryRay(origin, down, let cutT));

		// A ray somewhere else on the same field still hits: the hole is local.
		let elsewhere = Float3(20.0f, 50.0f, 20.0f);
		Test.Assert(field.QueryRay(elsewhere, down, let farT));
		Test.Assert(Math.Abs(farT - 45.0f) < 0.5f);

		// The brushes' pick takes the cut as surface, so the same ray lands on the plane.
		Test.Assert(field.QueryRayIgnoringHoles(origin, down, let planeT));
		Test.Assert(Math.Abs(planeT - 45.0f) < 0.5f, "the plane where the terrain used to be");
	}

	/// An ANGLED ray whose crossing lies inside the cut, which is the case a straight down
	/// ray cannot tell apart: the surface rule passes through and never comes back above the
	/// field, so there is no hit at all, while the brushes' rule lands on the plane there.
	[Test]
	public static void AnAngledCrossingInsideACutIsAMissForTheSurfaceRuleAndAPlaneForTheBrushes()
	{
		let field = MakeFlat();
		defer delete field;

		// A block of cut cells about the middle, wide enough for the crossing to fall inside.
		field.CellOfLocal(0.0f, 0.0f, let cx, let cz);
		for (int32 z = cz - 2; z <= cz + 3; z++)
			for (int32 x = cx - 2; x <= cx + 3; x++)
				field.SetHole(x, z, true);

		// Entering well left and just above the surface, falling slowly: it crosses near the
		// middle, inside the cut.
		let origin = Float3(-6.0f, 5.25f, 0.0f);
		let direction = Float3(1.0f, -0.05f, 0.0f);
		Test.Assert(!field.QueryRay(origin, direction, let missed),
			"the crossing is inside the cut, and the ray never rises above the field again");

		Test.Assert(field.QueryRayIgnoringHoles(origin, direction, let t));
		let hitX = origin.X + t * (1.0f / Math.Sqrt(1.0f + 0.05f * 0.05f));
		Test.Assert(hitX > -3.0f, "and it landed on the plane inside the cut");
		Test.Assert(hitX < 3.0f);
	}

	[Test]
	public static void TheBrushesCutAndFillWithAHardEdgeAndBumpTheVersionOnce()
	{
		let field = MakeFlat();
		defer delete field;

		let before = field.Version;
		let region = HeightfieldHoles.Cut(field, 0.0f, 0.0f, 4.0f);
		Test.Assert(!region.IsEmpty, "the touched rectangle comes back for the undo and rebuild");
		Test.Assert(field.HasHoles);
		Test.Assert(field.Version == (before + 1), "once for the whole stroke");

		// A HARD edge: the centre is cut and a sample well outside the radius is not.
		field.CellOfLocal(0.0f, 0.0f, let cx, let cz);
		Test.Assert(field.IsHole(cx, cz));
		Test.Assert(!field.IsHole(cx + 20, cz + 20));

		let cutCount = field.HoleCount;
		Test.Assert(cutCount > 1);

		// Cutting the same disc again changes nothing, so the version holds.
		let held = field.Version;
		HeightfieldHoles.Cut(field, 0.0f, 0.0f, 4.0f);
		Test.Assert(field.Version == held, "nothing changed, so nothing to re-cook");

		HeightfieldHoles.Fill(field, 0.0f, 0.0f, 4.0f);
		Test.Assert(field.HoleCount == 0, "and the fill restores every one of them");
		Test.Assert(field.Version == (held + 1));
	}
}
