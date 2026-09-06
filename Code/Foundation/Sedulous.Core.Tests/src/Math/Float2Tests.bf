using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// The CRepr layout is a compile-time fact and part of the contract, because these reach
/// GPU buffers. A layout change should stop the build rather than wait for a test run.
static
{
	private static void Assert_Float2Layout()
	{
		Compiler.Assert(sizeof(Float2) == 8);
		Compiler.Assert(offsetof(Float2, x) == 0);
		Compiler.Assert(offsetof(Float2, y) == 4);
	}
}

/// Raptor covers Float2 only inside two shared cases. Everything else here is new:
/// Distance, DistanceSquared, the operators and the indexer are otherwise unexercised.
class Float2Tests
{
	[Test]
	public static void Basics()
	{
		Test.Assert(Dot(Float2(1.0f, 2.0f), Float2(3.0f, 4.0f)) == 11.0f);
		Test.Assert(NearlyEqual(Length(Float2(3.0f, 4.0f)), 5.0f));
	}

	[Test]
	public static void Normalize()
	{
		Test.Assert(NearlyEqual(Length(Normalized(Float2(3.0f, 4.0f))), 1.0f));
		Test.Assert(Normalized(Float2.Zero) == Float2.Zero);
	}

	[Test]
	public static void Arithmetic()
	{
		var a = Float2(1.0f, 2.0f);
		let b = Float2(3.0f, 4.0f);

		Test.Assert((a + b) == Float2(4.0f, 6.0f));
		Test.Assert((b - a) == Float2(2.0f, 2.0f));
		Test.Assert((a * 2.0f) == Float2(2.0f, 4.0f));
		Test.Assert((2.0f * a) == Float2(2.0f, 4.0f));
		Test.Assert((a * b) == Float2(3.0f, 8.0f));
		Test.Assert((Float2(4.0f, 6.0f) / 2.0f) == Float2(2.0f, 3.0f));
		Test.Assert((-a) == Float2(-1.0f, -2.0f));

		a += b;
		Test.Assert(a == Float2(4.0f, 6.0f));
		a -= b;
		Test.Assert(a == Float2(1.0f, 2.0f));
		a *= 3.0f;
		Test.Assert(a == Float2(3.0f, 6.0f));
		a /= 3.0f;
		Test.Assert(a == Float2(1.0f, 2.0f));
	}

	[Test]
	public static void Constructors()
	{
		Test.Assert(Float2() == Float2.Zero);
		Test.Assert(Float2(2.0f) == Float2(2.0f, 2.0f));
	}

	[Test]
	public static void IndexerReadsAndWritesEveryComponent()
	{
		var v = Float2.Zero;
		v[0] = 1.0f;
		v[1] = 2.0f;
		Test.Assert(v == Float2(1.0f, 2.0f));
		Test.Assert((v[0] == 1.0f) && (v[1] == 2.0f));
	}

	/// DistanceSquared exists to avoid the square root; it has to agree with Distance
	/// squared, or callers comparing squared distances get a different ordering.
	[Test]
	public static void DistanceAndDistanceSquaredAgree()
	{
		let a = Float2(1.0f, 2.0f);
		let b = Float2(4.0f, 6.0f);

		Test.Assert(NearlyEqual(Distance(a, b), 5.0f));
		Test.Assert(NearlyEqual(DistanceSquared(a, b), 25.0f));
		Test.Assert(NearlyEqual(DistanceSquared(a, b), Distance(a, b) * Distance(a, b)));
		Test.Assert(NearlyZero(DistanceSquared(a, a)));
	}

	[Test]
	public static void LerpAndNearlyEqual()
	{
		Test.Assert(Lerp(Float2.Zero, Float2(4.0f, 8.0f), 0.5f) == Float2(2.0f, 4.0f));
		Test.Assert(Lerp(Float2.Zero, Float2.One, 0.0f) == Float2.Zero);
		Test.Assert(Lerp(Float2.Zero, Float2.One, 1.0f) == Float2.One);

		Test.Assert(!NearlyEqual(Float2.One, Float2(1.0f, 1.5f)));
		Test.Assert(NearlyEqual(Float2.One, Float2(1.0f, 1.5f), 0.6f));
	}

	[Test]
	public static void ComponentConstants()
	{
		Test.Assert(Float2.UnitX == Float2(1.0f, 0.0f));
		Test.Assert(Float2.UnitY == Float2(0.0f, 1.0f));
		Test.Assert(Float2.One == Float2(1.0f, 1.0f));
		Test.Assert(Float2.Zero == Float2(0.0f, 0.0f));
	}

}
