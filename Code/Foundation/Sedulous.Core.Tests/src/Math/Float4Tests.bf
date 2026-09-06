using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Raptor covers Float4 inside two shared cases. The operators, the indexer, Lerp and
/// NearlyEqual are added here.
class Float4Tests
{
	[Test]
	public static void Basics()
	{
		let v = Float4(Float3(1.0f, 2.0f, 3.0f), 1.0f);
		Test.Assert(v.XYZ() == Float3(1.0f, 2.0f, 3.0f));
		Test.Assert(v.w == 1.0f);
		Test.Assert(Dot(Float4.One, Float4.One) == 4.0f);
	}

	[Test]
	public static void Normalize()
	{
		Test.Assert(NearlyEqual(Length(Normalized(Float4(1.0f, 2.0f, 2.0f, 4.0f))), 1.0f));
		Test.Assert(Normalized(Float4.Zero) == Float4.Zero);
	}

	[Test]
	public static void Arithmetic()
	{
		var a = Float4(1.0f, 2.0f, 3.0f, 4.0f);
		let b = Float4(5.0f, 6.0f, 7.0f, 8.0f);

		Test.Assert((a + b) == Float4(6.0f, 8.0f, 10.0f, 12.0f));
		Test.Assert((b - a) == Float4(4.0f, 4.0f, 4.0f, 4.0f));
		Test.Assert((a * 2.0f) == Float4(2.0f, 4.0f, 6.0f, 8.0f));
		Test.Assert((2.0f * a) == Float4(2.0f, 4.0f, 6.0f, 8.0f));
		Test.Assert((-a) == Float4(-1.0f, -2.0f, -3.0f, -4.0f));

		a += b;
		Test.Assert(a == Float4(6.0f, 8.0f, 10.0f, 12.0f));
		a -= b;
		Test.Assert(a == Float4(1.0f, 2.0f, 3.0f, 4.0f));
		a *= 2.0f;
		Test.Assert(a == Float4(2.0f, 4.0f, 6.0f, 8.0f));
	}

	[Test]
	public static void Constructors()
	{
		Test.Assert(Float4() == Float4.Zero);
		Test.Assert(Float4(2.0f) == Float4(2.0f, 2.0f, 2.0f, 2.0f));
		Test.Assert(Float4(Float3(1.0f, 2.0f, 3.0f), 4.0f) == Float4(1.0f, 2.0f, 3.0f, 4.0f));
	}

	/// The w component is the one an indexer written for Float3 would drop.
	[Test]
	public static void IndexerReadsAndWritesEveryComponent()
	{
		var v = Float4.Zero;
		v[0] = 1.0f;
		v[1] = 2.0f;
		v[2] = 3.0f;
		v[3] = 4.0f;
		Test.Assert(v == Float4(1.0f, 2.0f, 3.0f, 4.0f));
		Test.Assert((v[0] == 1.0f) && (v[1] == 2.0f) && (v[2] == 3.0f) && (v[3] == 4.0f));
	}

	[Test]
	public static void LengthUsesAllFourComponents()
	{
		// 1 + 4 + 4 + 16 = 25, so a Length that ignored w would report 3 instead of 5.
		Test.Assert(LengthSquared(Float4(1.0f, 2.0f, 2.0f, 4.0f)) == 25.0f);
		Test.Assert(NearlyEqual(Length(Float4(1.0f, 2.0f, 2.0f, 4.0f)), 5.0f));
	}

	[Test]
	public static void LerpAndNearlyEqual()
	{
		Test.Assert(Lerp(Float4.Zero, Float4(2.0f, 4.0f, 6.0f, 8.0f), 0.5f)
			== Float4(1.0f, 2.0f, 3.0f, 4.0f));
		Test.Assert(Lerp(Float4.Zero, Float4.One, 0.0f) == Float4.Zero);
		Test.Assert(Lerp(Float4.Zero, Float4.One, 1.0f) == Float4.One);

		Test.Assert(!NearlyEqual(Float4.One, Float4(1.0f, 1.0f, 1.0f, 1.5f)));
		Test.Assert(NearlyEqual(Float4.One, Float4(1.0f, 1.0f, 1.0f, 1.5f), 0.6f));
	}

	[Test]
	public static void LayoutIsFourTightlyPackedFloats()
	{
		Test.Assert(sizeof(Float4) == 16);
		Test.Assert(offsetof(Float4, x) == 0);
		Test.Assert(offsetof(Float4, w) == 12);
	}
}
