using System;
using System.Numerics;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// The SIMD compute types checked AGAINST THE PACKED ONES.
///
/// That is the whole design of this suite: Float2/3/4 and Float4x4 are the reference, being
/// the tested path everything already runs on, and every case asserts the Vector*/Matrix4
/// answer against theirs. A SIMD type that disagrees with the scalar type it stands in for is
/// worse than no SIMD type, because the disagreement appears as a wrong pixel or a wrong
/// transform rather than as a failure.
///
/// The alignment case is not decoration. These types exist to live in a register, and a
/// missing [Align(16)] turns that into an unaligned load nobody notices.
static class SimdMathTests
{
	/// Looser than Math.Epsilon: these compare a four lane path against a scalar one, and the
	/// two associate their adds differently.
	private const float cEps = 1.0e-4f;

	private static bool Eq(Vector2 v, Float2 f) => NearlyEqual(v.ToFloat2(), f, cEps);
	private static bool Eq(Vector3 v, Float3 f) => NearlyEqual(v.ToFloat3(), f, cEps);
	private static bool Eq(Vector4 v, Float4 f) => NearlyEqual(v.ToFloat4(), f, cEps);
	private static bool Eq(Matrix4 m, Float4x4 f) =>
		NearlyEqual(m.ToFloat4x4(), f, cEps);

	[Test]
	public static void TheTypesAre16ByteAligned()
	{
		Test.Assert(alignof(Vector2) == 16, scope $"Vector2 aligns to {alignof(Vector2)}");
		Test.Assert(alignof(Vector3) == 16, scope $"Vector3 aligns to {alignof(Vector3)}");
		Test.Assert(alignof(Vector4) == 16, scope $"Vector4 aligns to {alignof(Vector4)}");
		Test.Assert(alignof(Matrix4) == 16, scope $"Matrix4 aligns to {alignof(Matrix4)}");
	}

	[Test]
	public static void Vector4RoundTripsAndItsArithmeticMatchesThePackedType()
	{
		let pa = Float4(1.0f, -2.0f, 3.5f, 4.0f);
		let pb = Float4(-0.5f, 2.0f, 1.0f, -3.0f);
		let a = Vector4(pa);
		let b = Vector4(pb);

		Test.Assert(Eq(a, pa), "the load and store round trip");
		Test.Assert(Eq(a + b, pa + pb), "addition");
		Test.Assert(Eq(a - b, pa - pb), "subtraction");
		Test.Assert(Eq(a * b, .(pa.X * pb.X, pa.Y * pb.Y, pa.Z * pb.Z, pa.W * pb.W)),
			"vector times vector is COMPONENT WISE, not a dot product");
		Test.Assert(Eq(a * 2.5f, pa * 2.5f), "scaled on the right");
		Test.Assert(Eq(2.5f * a, pa * 2.5f), "and on the left");
		Test.Assert(Eq(a / 2.0f, pa * 0.5f), "divided by a scalar");
		Test.Assert(Eq(-a, -pa), "negated");
		Test.Assert(NearlyEqual(Dot(a, b), Dot(pa, pb), cEps), "Dot");
		Test.Assert(NearlyEqual(Length(a), Length(pa), cEps), "Length");
		Test.Assert(NearlyEqual(LengthSquared(a), LengthSquared(pa), cEps),
			"LengthSquared");
		Test.Assert(Eq(Normalized(a), Normalized(pa)), "Normalized");
		Test.Assert(Eq(Lerp(a, b, 0.25f), Lerp(pa, pb, 0.25f)), "Lerp");
		Test.Assert(Eq(Min(a, b), .(-0.5f, -2.0f, 1.0f, -3.0f)), "Min");
		Test.Assert(Eq(Max(a, b), .(1.0f, 2.0f, 3.5f, 4.0f)), "Max");

		var c = Vector4(pa);
		c += b;
		Test.Assert(Eq(c, pa + pb), "compound add");
		c -= b;
		Test.Assert(Eq(c, pa), "compound subtract");
		c *= 3.0f;
		Test.Assert(Eq(c, pa * 3.0f), "compound scale");
	}

	[Test]
	public static void Vector3MatchesThePackedTypeIncludingCross()
	{
		let pa = Float3(1.0f, 2.0f, 3.0f);
		let pb = Float3(-4.0f, 5.0f, -6.0f);
		let a = Vector3(pa);
		let b = Vector3(pb);

		Test.Assert(Eq(a, pa), "the load and store round trip");
		Test.Assert(Eq(a + b, pa + pb), "addition");
		Test.Assert(Eq(a - b, pa - pb), "subtraction");
		Test.Assert(Eq(a * 2.0f, pa * 2.0f), "scaled");
		Test.Assert(Eq(a / 4.0f, pa / 4.0f), "divided");
		Test.Assert(Eq(-a, -pa), "negated");
		Test.Assert(NearlyEqual(Dot(a, b), Dot(pa, pb), cEps), "Dot");
		Test.Assert(Eq(Cross(a, b), Cross(pa, pb)),
			"Cross, which is the shuffle form and the easiest thing here to get wrong");
		Test.Assert(NearlyEqual(Length(a), Length(pa), cEps), "Length");
		Test.Assert(NearlyEqual(Distance(a, b), Distance(pa, pb), cEps),
			"Distance");
		Test.Assert(Eq(Normalized(a), Normalized(pa)), "Normalized");
		Test.Assert(Eq(Lerp(a, b, 0.5f), Lerp(pa, pb, 0.5f)), "Lerp");
		Test.Assert(Eq(Min(a, b), Min(pa, pb)), "Min");
		Test.Assert(Eq(Max(a, b), Max(pa, pb)), "Max");
	}

	[Test]
	public static void Vector3KeepsItsWLaneAtZeroThroughEveryOperation()
	{
		// Dot folds ALL FOUR lanes, so a leaked w would corrupt the result rather than be
		// ignored. Running a chain of operations and then asking whether the four lane Dot
		// still agrees with the three lane one is what catches a lost invariant.
		let a = Vector3(2.0f, 3.0f, 4.0f);
		let b = Vector3(5.0f, 6.0f, 7.0f);
		let c = (a + b) * 2.0f - Cross(a, b);

		Test.Assert(NearlyEqual(Dot(c, c), LengthSquared(c.ToFloat3()), cEps),
			"a chain of ops left w nonzero, so the four lane fold no longer matches three lanes");
	}

	[Test]
	public static void Vector2MatchesThePackedType()
	{
		let pa = Float2(3.0f, 4.0f);
		let pb = Float2(1.0f, -2.0f);
		let a = Vector2(pa);
		let b = Vector2(pb);

		Test.Assert(Eq(a, pa), "the load and store round trip");
		Test.Assert(Eq(a + b, pa + pb), "addition");
		Test.Assert(Eq(a - b, pa - pb), "subtraction");
		Test.Assert(Eq(a * 2.0f, pa * 2.0f), "scaled");
		Test.Assert(NearlyEqual(Dot(a, b), Dot(pa, pb), cEps), "Dot");
		Test.Assert(NearlyEqual(Length(a), 5.0f, cEps), "the 3-4-5 triangle");
		Test.Assert(Eq(Normalized(a), Normalized(pa)), "Normalized");
		Test.Assert(Eq(Lerp(a, b, 0.5f), Lerp(pa, pb, 0.5f)), "Lerp");
	}

	[Test]
	public static void NormalizingSomethingTooSmallGivesZeroRatherThanInfinity()
	{
		Test.Assert(Eq(Normalized(Vector3(0.0f, 0.0f, 0.0f)), Float3.Zero),
			"a zero Vector3 normalises to zero");
		Test.Assert(Eq(Normalized(Vector4(0.0f)), Float4.Zero),
			"and so does a zero Vector4");
	}

	[Test]
	public static void Matrix4MultiplyAndTransformMatchThePackedType()
	{
		let t = Float4x4.Translation(.(3.0f, -1.0f, 2.0f));
		let r = Float4x4.RotationY(0.75f);
		let s = Float4x4.Scale(.(2.0f, 0.5f, 1.5f));
		let composed = s * r * t; // the packed reference

		let simd = Matrix4(s) * Matrix4(r) * Matrix4(t);

		Test.Assert(Eq(Matrix4.Identity(), Float4x4.Identity()),
			"a default Matrix4 is identity, which a skipped field initialiser would break");
		Test.Assert(Eq(Matrix4(composed), composed), "the load and store round trip");
		Test.Assert(Eq(simd, composed), "the same composition through four registers");
		Test.Assert(Eq(Transpose(simd), Transpose(composed)), "Transpose");

		let pv = Float4(1.5f, -2.0f, 0.5f, 1.0f);
		Test.Assert(Eq(Vector4(pv) * simd, pv * composed), "the row vector transform");

		let pp = Float3(4.0f, 5.0f, -6.0f);
		Test.Assert(Eq(TransformPoint(Vector3(pp), simd),
			TransformPoint(pp, composed)), "TransformPoint, translation applied");
		Test.Assert(Eq(TransformDirection(Vector3(pp), simd),
			TransformDirection(pp, composed)), "TransformDirection, translation not");
	}

	[Test]
	public static void Matrix4AgreesWithThePackedTypeOnAViewProjectionChain()
	{
		let view = Float4x4.LookAtRH(.(0, 3, 8), .(0, 0, 0), .(0, 1, 0));
		let proj = Float4x4.PerspectiveFovRH(1.0f, 16.0f / 9.0f, 0.1f, 100.0f);
		let viewProj = view * proj;

		let simdViewProj = Matrix4(view) * Matrix4(proj);
		Test.Assert(Eq(simdViewProj, viewProj), "the view projection product");

		// A real chain rather than a contrived one: the numbers here are what a camera
		// actually produces, and the accumulation is deep enough to expose an associativity
		// difference the tidy cases above would not.
		let worldPos = Float3(2.0f, 1.0f, -3.0f);
		let clipPacked = Float4(worldPos.X, worldPos.Y, worldPos.Z, 1.0f) * viewProj;
		let clipSimd = (Vector4(Float4(worldPos.X, worldPos.Y, worldPos.Z, 1.0f)) * simdViewProj)
			.ToFloat4();

		// Looser still: this one accumulates through two matrices before the compare.
		Test.Assert(NearlyEqual(clipSimd, clipPacked, 1.0e-3f),
			"the clip position through the SIMD chain");
	}
}
