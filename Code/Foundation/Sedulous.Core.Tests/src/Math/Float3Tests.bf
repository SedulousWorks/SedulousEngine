using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Raptor's static_assert(Float3{1,0,0} == Float3::UnitX), plus the CRepr layout, which
/// is a compile-time fact and part of the contract because these reach GPU buffers. A
/// layout change should stop the build, not wait for a test run.
static
{
	private static void Assert_Float3ConstantsFold()
	{
		Compiler.Assert(Float3(1.0f, 0.0f, 0.0f) == Float3.UnitX);
		Compiler.Assert(Float3(0.0f, 1.0f, 0.0f) == Float3.UnitY);
		Compiler.Assert(Float3(0.0f, 0.0f, 1.0f) == Float3.UnitZ);
	}

	private static void Assert_Float3Layout()
	{
		Compiler.Assert(sizeof(Float3) == 12);
		Compiler.Assert(offsetof(Float3, X) == 0);
		Compiler.Assert(offsetof(Float3, Y) == 4);
		Compiler.Assert(offsetof(Float3, Z) == 8);
	}
}

/// Ported from Raptor's Float3 cases. Adds the division operators, Distance, the
/// indexer setter, the Float2 constructor and the anti-commutativity of Cross, none of
/// which Raptor reaches.
class Float3Tests
{
	[Test]
	public static void Arithmetic()
	{
		var a = Float3(1.0f, 2.0f, 3.0f);
		let b = Float3(4.0f, 5.0f, 6.0f);

		Test.Assert((a + b) == Float3(5.0f, 7.0f, 9.0f));
		Test.Assert((b - a) == Float3(3.0f, 3.0f, 3.0f));
		Test.Assert((a * 2.0f) == Float3(2.0f, 4.0f, 6.0f));
		Test.Assert((2.0f * a) == Float3(2.0f, 4.0f, 6.0f));
		Test.Assert((-a) == Float3(-1.0f, -2.0f, -3.0f));

		a += b;
		Test.Assert(a == Float3(5.0f, 7.0f, 9.0f));

		Test.Assert(a[0] == 5.0f);
		Test.Assert(a[2] == 9.0f);
	}

	/// The component-wise product and quotient are easy to confuse with a dot or a
	/// scale, so both are pinned to values no other reading would produce.
	[Test]
	public static void ComponentWiseProductAndQuotient()
	{
		let a = Float3(2.0f, 3.0f, 4.0f);
		let b = Float3(5.0f, 7.0f, 9.0f);

		Test.Assert((a * b) == Float3(10.0f, 21.0f, 36.0f));
		Test.Assert((Float3(10.0f, 21.0f, 36.0f) / a) == b);
		Test.Assert((Float3(2.0f, 4.0f, 6.0f) / 2.0f) == Float3(1.0f, 2.0f, 3.0f));
	}

	[Test]
	public static void CompoundAssignment()
	{
		var v = Float3(10.0f, 20.0f, 30.0f);
		v -= Float3(1.0f, 2.0f, 3.0f);
		Test.Assert(v == Float3(9.0f, 18.0f, 27.0f));
		v *= 2.0f;
		Test.Assert(v == Float3(18.0f, 36.0f, 54.0f));
		v /= 9.0f;
		Test.Assert(v == Float3(2.0f, 4.0f, 6.0f));
	}

	[Test]
	public static void Constructors()
	{
		Test.Assert(Float3() == Float3.Zero);
		Test.Assert(Float3(2.0f) == Float3(2.0f, 2.0f, 2.0f));
		Test.Assert(Float3(Float2(1.0f, 2.0f), 3.0f) == Float3(1.0f, 2.0f, 3.0f));
	}

	[Test]
	public static void IndexerReadsAndWritesEveryComponent()
	{
		var v = Float3.Zero;
		v[0] = 1.0f;
		v[1] = 2.0f;
		v[2] = 3.0f;
		Test.Assert(v == Float3(1.0f, 2.0f, 3.0f));
		Test.Assert((v[0] == 1.0f) && (v[1] == 2.0f) && (v[2] == 3.0f));
	}

	[Test]
	public static void DotCrossLengthNormalize()
	{
		Test.Assert(Dot(Float3(1.0f, 2.0f, 3.0f), Float3(4.0f, 5.0f, 6.0f)) == 32.0f);

		// Right-handed cross: X x Y = Z
		Test.Assert(Cross(Float3.UnitX, Float3.UnitY) == Float3.UnitZ);
		Test.Assert(Cross(Float3.UnitY, Float3.UnitZ) == Float3.UnitX);

		Test.Assert(LengthSquared(Float3(3.0f, 4.0f, 0.0f)) == 25.0f);
		Test.Assert(NearlyEqual(Length(Float3(3.0f, 4.0f, 0.0f)), 5.0f));

		let n = Normalized(Float3(0.0f, 8.0f, 0.0f));
		Test.Assert(NearlyEqual(n, Float3.UnitY));
		Test.Assert(NearlyEqual(Length(n), 1.0f));

		// Degenerate input yields Zero rather than a NaN from dividing by zero.
		Test.Assert(Normalized(Float3.Zero) == Float3.Zero);
	}

	/// Raptor checks two positive cross products, which a sign-flipped implementation
	/// would also pass. These pin the sign and the perpendicularity.
	[Test]
	public static void CrossIsAntiCommutativeAndPerpendicular()
	{
		Test.Assert(Cross(Float3.UnitY, Float3.UnitX) == -Float3.UnitZ);
		Test.Assert(Cross(Float3.UnitZ, Float3.UnitX) == Float3.UnitY);

		let a = Float3(1.0f, 2.0f, 3.0f);
		let b = Float3(4.0f, 5.0f, 6.0f);
		Test.Assert(Cross(a, b) == -Cross(b, a));

		let c = Cross(a, b);
		Test.Assert(NearlyZero(Dot(c, a)));
		Test.Assert(NearlyZero(Dot(c, b)));

		// Parallel inputs have no cross.
		Test.Assert(Cross(a, a * 2.0f) == Float3.Zero);
	}

	[Test]
	public static void DistanceIsSymmetricAndZeroOnItself()
	{
		Test.Assert(NearlyEqual(
			Distance(Float3(1.0f, 2.0f, 3.0f), Float3(4.0f, 6.0f, 3.0f)), 5.0f));
		Test.Assert(NearlyEqual(
			Distance(Float3(4.0f, 6.0f, 3.0f), Float3(1.0f, 2.0f, 3.0f)), 5.0f));
		Test.Assert(NearlyZero(Distance(Float3.One, Float3.One)));
	}

	[Test]
	public static void LerpMinMax()
	{
		Test.Assert(Lerp(Float3.Zero, Float3(4.0f, 8.0f, 12.0f), 0.5f)
			== Float3(2.0f, 4.0f, 6.0f));
		Test.Assert(Min(Float3(1.0f, 5.0f, 3.0f), Float3(4.0f, 2.0f, 6.0f))
			== Float3(1.0f, 2.0f, 3.0f));
		Test.Assert(Max(Float3(1.0f, 5.0f, 3.0f), Float3(4.0f, 2.0f, 6.0f))
			== Float3(4.0f, 5.0f, 6.0f));

		// Endpoints, which a Lerp with its operands swapped would fail.
		Test.Assert(Lerp(Float3.Zero, Float3.One, 0.0f) == Float3.Zero);
		Test.Assert(Lerp(Float3.Zero, Float3.One, 1.0f) == Float3.One);
	}

	[Test]
	public static void NearlyEqualIsPerComponent()
	{
		let a = Float3(1.0f, 1.0f, 1.0f);
		Test.Assert(!NearlyEqual(a, Float3(1.0f, 1.0f, 1.5f)));
		Test.Assert(NearlyEqual(a, Float3(1.0f, 1.0f, 1.5f), 0.6f));
	}

}
