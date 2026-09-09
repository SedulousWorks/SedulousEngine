using System;
using Sedulous.Core;
using Sedulous.Particles;

namespace Sedulous.Particles.Tests;

/// The value types: ranges, curves, emission shapes and the flipbook grid.
class ParticleValueTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	[Test]
	public static void ARangeLerpsBetweenItsEnds()
	{
		let range = RangeFloat(2.0f, 6.0f);
		Test.Assert(Near(range.Evaluate(0.0f), 2.0f));
		Test.Assert(Near(range.Evaluate(1.0f), 6.0f));
		Test.Assert(Near(range.Evaluate(0.5f), 4.0f));
		Test.Assert(RangeFloat.Constant(3.0f).IsConstant);
	}

	[Test]
	public static void AColourRangeMovesOnOneFactor()
	{
		// One factor for all four channels, so the midpoint is the colour halfway between
		// the ends rather than a mixture of their channels.
		let range = RangeColor(.(0, 0, 0, 0), .(1, 2, 3, 4));
		let mid = range.Evaluate(0.5f);
		Test.Assert(Near(mid.X, 0.5f));
		Test.Assert(Near(mid.W, 2.0f));
	}

	[Test]
	public static void AnEmptyCurveIsNotActive()
	{
		Test.Assert(!ParticleCurveFloat().IsActive);
		Test.Assert(!ParticleCurveColor().IsActive);
		Test.Assert(!ParticleCurveFloat2().IsActive);
	}

	[Test]
	public static void AConstantCurveHoldsEverywhere()
	{
		Test.Assert(Near(ParticleCurveFloat.Constant(5.0f).Evaluate(0.37f), 5.0f));
	}

	[Test]
	public static void ACurveClampsOutsideItsKeys()
	{
		let curve = ParticleCurveFloat.Linear(0.0f, 10.0f);
		Test.Assert(Near(curve.Evaluate(0.0f), 0.0f));
		Test.Assert(Near(curve.Evaluate(1.0f), 10.0f));
		Test.Assert(Near(curve.Evaluate(-1.0f), 0.0f));
		Test.Assert(Near(curve.Evaluate(2.0f), 10.0f));
		Test.Assert((curve.Evaluate(0.5f) > 0.0f) && (curve.Evaluate(0.5f) < 10.0f));
	}

	[Test]
	public static void AFadeOutHoldsThenFalls()
	{
		let curve = ParticleCurveFloat.FadeOut(1.0f, 0.75f);
		Test.Assert(Near(curve.Evaluate(0.0f), 1.0f));
		Test.Assert(Near(curve.Evaluate(0.5f), 1.0f));
		Test.Assert(Near(curve.Evaluate(1.0f), 0.0f));
	}

	[Test]
	public static void ACurveDropsKeysPastItsCap()
	{
		var curve = ParticleCurveFloat();
		for (int32 i = 0; i < ParticleCurve.MaxKeys; i++)
			Test.Assert(curve.AddKey((float)i / (float)ParticleCurve.MaxKeys, 1.0f));
		// The cap is a cap, not an error: the ninth key is refused and the curve stays whole.
		Test.Assert(!curve.AddKey(1.0f, 2.0f));
		Test.Assert(curve.KeyCount == ParticleCurve.MaxKeys);
	}

	[Test]
	public static void APointShapeSamplesTheOrigin()
	{
		var rng = Random(1234);
		Float3 position;
		Float3 direction;
		EmissionShape.Point().Sample(ref rng, out position, out direction);
		Test.Assert(Near(LengthSquared(position), 0.0f));
	}

	[Test]
	public static void ASphereSamplesInsideItsRadius()
	{
		var rng = Random(1234);
		let shape = EmissionShape.Sphere(2.0f);
		for (int i = 0; i < 200; i++)
		{
			Float3 position;
			Float3 direction;
			shape.Sample(ref rng, out position, out direction);
			Test.Assert(Length(position) <= 2.01f);
			Test.Assert(Near(Length(direction), 1.0f, 0.01f));
		}
	}

	[Test]
	public static void ACircleIsFlatAndAnEdgeIsALine()
	{
		var rng = Random();
		let circle = EmissionShape.Circle(2.0f);
		let edge = EmissionShape.Edge(3.0f);
		for (int i = 0; i < 64; i++)
		{
			Float3 position;
			Float3 direction;

			circle.Sample(ref rng, out position, out direction);
			Test.Assert(Near(position.Y, 0.0f));
			Test.Assert(Length(Float3(position.X, 0.0f, position.Z)) <= 2.01f);

			edge.Sample(ref rng, out position, out direction);
			Test.Assert(Near(position.Y, 0.0f));
			Test.Assert(Near(position.Z, 0.0f));
			Test.Assert((position.X >= -3.01f) && (position.X <= 3.01f));
		}
	}

	[Test]
	public static void AnArcRestrictsTheAzimuth()
	{
		var rng = Random();
		var shape = EmissionShape.Circle(1.0f, true);
		// A quarter turn puts every sample in the first quadrant.
		shape.Arc = 0.25f;
		for (int i = 0; i < 64; i++)
		{
			Float3 position;
			Float3 direction;
			shape.Sample(ref rng, out position, out direction);
			Test.Assert(position.X >= -0.001f);
			Test.Assert(position.Z >= -0.001f);
		}
	}

	[Test]
	public static void AFlipbookWalksItsGridOverLifetime()
	{
		var flipbook = FlipbookSettings();
		flipbook.Enabled = true;
		flipbook.Columns = 4;
		flipbook.Rows = 4;
		flipbook.OverLifetime = true;
		Test.Assert(flipbook.IsActive);
		Test.Assert(flipbook.FrameCount == 16);

		let first = flipbook.FrameUV(0.0f, 0.0f);
		Test.Assert(Near(first.X, 0.0f) && Near(first.Y, 0.0f));
		Test.Assert(Near(first.Z, 0.25f) && Near(first.W, 0.25f));

		// Halfway is frame eight, which is the first cell of the third row.
		let middle = flipbook.FrameUV(0.5f, 0.0f);
		Test.Assert(Near(middle.X, 0.0f) && Near(middle.Y, 0.5f));

		let last = flipbook.FrameUV(0.999f, 0.0f);
		Test.Assert(Near(last.X, 0.75f) && Near(last.Y, 0.75f));
	}

	[Test]
	public static void ASingleFrameSheetIsNotAnAnimation()
	{
		var flipbook = FlipbookSettings();
		flipbook.Enabled = true;
		Test.Assert(!flipbook.IsActive);
	}
}
