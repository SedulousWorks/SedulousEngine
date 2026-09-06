using System;
using Sedulous.Core;
using Sedulous.Lod;

namespace Sedulous.Lod.Tests;

/// The shared LOD selection maths. Mesh chains and terrain chunks both delegate here, so a
/// mistake in any of these three functions is a mistake everywhere at once.
class LodMathTests
{
	private static bool Near(float a, float b, float tolerance = 0.01f) => Abs(a - b) <= tolerance;

	private static Span<float> Thresholds(float[3]* storage)
	{
		(*storage)[0] = 1.0f;
		(*storage)[1] = 0.25f;
		(*storage)[2] = 0.05f;
		return .(&(*storage)[0], 3);
	}

	[Test]
	public static void PerspectiveCoverageHalvesWithDistance()
	{
		let view = Float4x4.Identity();
		let projection = Float4x4.PerspectiveFovRH(HalfPi, 1.0f, 0.1f, 1000.0f);

		let at10 = LodMath.ProjectedSphereCoverage(view, projection, .(0, 0, -10.0f), 1.0f);
		let at20 = LodMath.ProjectedSphereCoverage(view, projection, .(0, 0, -20.0f), 1.0f);

		Test.Assert(Near(at10, 0.1f), scope $"coverage at 10 units was {at10}");
		Test.Assert(Near(at20, at10 * 0.5f), "twice the distance is half the coverage");
	}

	/// The bias is in LOD bias units: each one halves the coverage, which pushes selection
	/// one level coarser.
	[Test]
	public static void BiasHalvesCoveragePerUnit()
	{
		let view = Float4x4.Identity();
		let projection = Float4x4.PerspectiveFovRH(HalfPi, 1.0f, 0.1f, 1000.0f);

		let plain = LodMath.ProjectedSphereCoverage(view, projection, .(0, 0, -10.0f), 1.0f);
		let biased = LodMath.ProjectedSphereCoverage(view, projection, .(0, 0, -10.0f), 1.0f, 1.0f);
		let twice = LodMath.ProjectedSphereCoverage(view, projection, .(0, 0, -10.0f), 1.0f, 2.0f);

		Test.Assert(Near(biased, plain * 0.5f), scope $"one unit of bias gave {biased}");
		Test.Assert(Near(twice, plain * 0.25f), "two units halve it twice");
		// A negative bias pulls the other way, holding a finer level for longer.
		let finer = LodMath.ProjectedSphereCoverage(view, projection, .(0, 0, -10.0f), 1.0f, -1.0f);
		Test.Assert(Near(finer, plain * 2.0f));
	}

	/// Something at or behind the eye must produce a large finite coverage rather than a
	/// division by zero. It is about to be culled anyway; what matters is that selection
	/// does not produce a NaN that then propagates into the level index.
	[Test]
	public static void SomethingBehindTheEyeIsClampedNotDividedByZero()
	{
		let view = Float4x4.Identity();
		let projection = Float4x4.PerspectiveFovRH(HalfPi, 1.0f, 0.1f, 1000.0f);

		let behind = LodMath.ProjectedSphereCoverage(view, projection, .(0, 0, 5.0f), 1.0f);
		Test.Assert(behind > 0.0f, "clamped to a positive coverage");
		Test.Assert(behind == behind, "and not a NaN");

		let atEye = LodMath.ProjectedSphereCoverage(view, projection, .(0, 0, 0), 1.0f);
		Test.Assert(atEye > 0.0f);
		Test.Assert(atEye == atEye);
	}

	/// An orthographic projection has no perspective divide, so screen size does not change
	/// with distance. Getting this wrong makes shadow cascades pop as the light moves.
	[Test]
	public static void OrthographicCoverageIsDepthFree()
	{
		let view = Float4x4.Identity();
		let ortho = Float4x4.OrthographicRH(10.0f, 10.0f, 0.1f, 100.0f);

		let near = LodMath.ProjectedSphereCoverage(view, ortho, .(0, 0, -1.0f), 1.0f);
		let far = LodMath.ProjectedSphereCoverage(view, ortho, .(0, 0, -90.0f), 1.0f);

		Test.Assert(Near(near, far, 0.0001f), scope $"near {near}, far {far}");
		Test.Assert(near > 0.0f);
	}

	[Test]
	public static void TheThresholdWalkDescends()
	{
		float[3] storage = default;
		let thresholds = Thresholds(&storage);

		Test.Assert(LodMath.SelectLevelByCoverage(thresholds, 0.5f) == 0);
		Test.Assert(LodMath.SelectLevelByCoverage(thresholds, 0.2f) == 1);
		Test.Assert(LodMath.SelectLevelByCoverage(thresholds, 0.01f) == 2);
		Test.Assert(LodMath.SelectLevelByCoverage(thresholds, 0.0f) == 2, "nothing visible is the coarsest");
	}

	/// Exactly on a threshold stays on the FINER level. The comparison is strictly less
	/// than, so a value sitting on the boundary does not tip over.
	[Test]
	public static void ExactlyOnAThresholdStaysFiner()
	{
		float[3] storage = default;
		let thresholds = Thresholds(&storage);

		Test.Assert(LodMath.SelectLevelByCoverage(thresholds, 0.25f) == 0, "on the boundary, not past it");
		Test.Assert(LodMath.SelectLevelByCoverage(thresholds, 0.05f) == 1);
	}

	/// Degenerate tables answer level 0 rather than reading past themselves.
	[Test]
	public static void DegenerateThresholdsSelectLevelZero()
	{
		Test.Assert(LodMath.SelectLevelByCoverage(.(), 0.0f) == 0, "an empty table");

		float[1] single = .(1.0f);
		Test.Assert(LodMath.SelectLevelByCoverage(.(&single[0], 1), 0.0f) == 0, "a single entry");
	}

	/// A table that is not descending stops the walk where it breaks. Malformed data then
	/// renders too FINE, which costs performance, rather than too coarse, which is visible.
	[Test]
	public static void ANonDescendingTableStopsTheWalk()
	{
		float[3] rising = .(1.0f, 0.25f, 0.9f);
		let thresholds = Span<float>(&rising[0], 3);

		Test.Assert(LodMath.SelectLevelByCoverage(thresholds, 0.5f) == 0,
			"0.5 is above 0.25, so the walk stopped before considering 0.9");
		Test.Assert(LodMath.SelectLevelByCoverage(thresholds, 0.2f) == 2,
			"below both, so it walks the whole table");
	}

	[Test]
	public static void HysteresisHoldsThePreviousLevelNearABoundary()
	{
		float[3] storage = default;
		let thresholds = Thresholds(&storage);

		// Just under the 0.25 boundary: the raw pick is level 1, but a viewer that was on
		// level 0 stays there rather than flickering.
		Test.Assert(LodMath.ApplyCoverageHysteresis(thresholds, 0.246f, 1, 0) == 0);
		// And just over it, a viewer already on level 1 stays on 1.
		Test.Assert(LodMath.ApplyCoverageHysteresis(thresholds, 0.253f, 0, 1) == 1);
	}

	/// Away from any boundary the raw selection wins, so a level cannot be pinned by a
	/// value that has long since stopped applying.
	[Test]
	public static void HysteresisDoesNotPinAStaleLevel()
	{
		float[3] storage = default;
		let thresholds = Thresholds(&storage);

		Test.Assert(LodMath.ApplyCoverageHysteresis(thresholds, 0.8f, 0, 2) == 0, "far from the band");
		Test.Assert(LodMath.ApplyCoverageHysteresis(thresholds, 0.01f, 2, 0) == 2);
		Test.Assert(LodMath.ApplyCoverageHysteresis(thresholds, 0.246f, 1, 1) == 1, "already there");
	}

	/// A wider band holds a level across a larger coverage swing, and a zero band is the
	/// same as no hysteresis at all.
	[Test]
	public static void TheBandWidthDecidesHowFarALevelHolds()
	{
		float[3] storage = default;
		let thresholds = Thresholds(&storage);

		// 0.30 is well clear of 0.25 for the default band, so level 1 cannot hold.
		Test.Assert(LodMath.ApplyCoverageHysteresis(thresholds, 0.30f, 0, 1) == 0);
		// A band wide enough to reach the boundary holds it.
		Test.Assert(LodMath.ApplyCoverageHysteresis(thresholds, 0.30f, 0, 1, 0.25f) == 1);
		// And with no band, the raw pick always wins.
		Test.Assert(LodMath.ApplyCoverageHysteresis(thresholds, 0.246f, 1, 0, 0.0f) == 1);
	}
}
