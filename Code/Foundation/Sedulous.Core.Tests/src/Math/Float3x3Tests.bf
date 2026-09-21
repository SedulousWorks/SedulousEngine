using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// The identity diagonal, at compile time.
static
{
	private static void Assert_Float3x3Identity()
	{
		Compiler.Assert(sizeof(Float3x3) == 36);
	}
}

class Float3x3Tests
{
	[Test]
	public static void IdentityMultiplyTranspose()
	{
		let id = Float3x3.Identity();
		let r = Float3x3.FromMat4(Float4x4.RotationZ(DegreesToRadians(90.0f)));

		Test.Assert(NearlyEqual(id * r, r));
		Test.Assert(NearlyEqual(Transpose(Transpose(r)), r));
		Test.Assert(Float3x3.Identity()[1, 1] == 1.0f);
		Test.Assert(Float3x3.Identity()[0, 1] == 0.0f);
	}

	[Test]
	public static void RowVectorRotationMatchesFloat4x4()
	{
		let rz = Float3x3.FromMat4(Float4x4.RotationZ(DegreesToRadians(90.0f)));
		Test.Assert(NearlyEqual(Float3.UnitX * rz, Float3.UnitY));
	}

	/// FromMat4 has to take the upper-left block and drop translation. A version that
	/// read the wrong rows would still pass a pure-rotation case, so this uses a matrix
	/// carrying both.
	[Test]
	public static void FromMat4TakesTheUpperLeftAndDropsTranslation()
	{
		let m = Float4x4.Scale(Float3(2.0f, 3.0f, 4.0f))
			* Float4x4.Translation(Float3(9.0f, 8.0f, 7.0f));
		let upper = Float3x3.FromMat4(m);

		Test.Assert(upper[0, 0] == 2.0f);
		Test.Assert(upper[1, 1] == 3.0f);
		Test.Assert(upper[2, 2] == 4.0f);

		// Translation is gone: a direction scales but does not shift.
		Test.Assert(NearlyEqual(Float3.UnitX * upper, Float3(2.0f, 0.0f, 0.0f)));
	}

	[Test]
	public static void DeterminantAndInverse()
	{
		let rz = Float3x3.FromMat4(Float4x4.RotationZ(DegreesToRadians(37.0f)));
		Test.Assert(NearlyEqual(Determinant(rz), 1.0f));   // a pure rotation

		let inv = Inverse(rz);
		Test.Assert(NearlyEqual(rz * inv, Float3x3.Identity(), 1.0e-4f));

		// For a rotation the inverse is the transpose.
		Test.Assert(NearlyEqual(inv, Transpose(rz), 1.0e-4f));

		// Singular returns Identity.
		Float3x3 zero = .();
		Test.Assert(NearlyEqual(Inverse(zero), Float3x3.Identity()));
	}

	/// Inverting a rotation would not tell, since its inverse happens to equal the
	/// transpose and a transposing implementation passes. This uses a non-orthogonal matrix.
	[Test]
	public static void InverseHandlesNonOrthogonalMatrices()
	{
		let m = Float3x3(
			2.0f, 1.0f, 0.0f,
			0.0f, 3.0f, 1.0f,
			1.0f, 0.0f, 4.0f);

		Test.Assert(NearlyEqual(Determinant(m), 25.0f, 1.0e-3f));   // 2*12 - 1*(-1) + 0

		let inv = Inverse(m);
		Test.Assert(NearlyEqual(m * inv, Float3x3.Identity(), 1.0e-4f));
		Test.Assert(NearlyEqual(inv * m, Float3x3.Identity(), 1.0e-4f));

		// And it is genuinely not the transpose here.
		Test.Assert(!NearlyEqual(inv, Transpose(m), 1.0e-3f));
	}

	/// A scale matrix's determinant is the product of the scales, which pins the sign
	/// convention as well as the magnitude.
	[Test]
	public static void DeterminantOfScaleIsTheProduct()
	{
		let s = Float3x3.FromMat4(Float4x4.Scale(Float3(2.0f, 3.0f, 4.0f)));
		Test.Assert(NearlyEqual(Determinant(s), 24.0f, 1.0e-3f));

		let mirrored = Float3x3.FromMat4(Float4x4.Scale(Float3(2.0f, 3.0f, -4.0f)));
		Test.Assert(NearlyEqual(Determinant(mirrored), -24.0f, 1.0e-3f));
	}
}
