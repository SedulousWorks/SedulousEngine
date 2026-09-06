using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Raptor's Float4x4 cases. doctest's Approx is a relative comparison; NearlyEqual is
/// absolute, so the epsilons here are chosen to be at least as tight for the magnitudes
/// involved.
class Float4x4Tests
{
	[Test]
	public static void IdentityAndMultiply()
	{
		let id = Float4x4.Identity();
		let t = Float4x4.Translation(Float3(1.0f, 2.0f, 3.0f));

		Test.Assert(NearlyEqual(id * t, t));
		Test.Assert(NearlyEqual(t * id, t));
	}

	[Test]
	public static void TranslationLivesInTheLastRow()
	{
		let t = Float4x4.Translation(Float3(10.0f, 20.0f, 30.0f));
		Test.Assert(t.m[3][0] == 10.0f);
		Test.Assert(t.m[3][1] == 20.0f);
		Test.Assert(t.m[3][2] == 30.0f);

		let p = TransformPoint(Float3(1.0f, 1.0f, 1.0f), t);
		Test.Assert(NearlyEqual(p, Float3(11.0f, 21.0f, 31.0f)));

		// Directions ignore translation.
		Test.Assert(NearlyEqual(TransformDirection(Float3(1.0f, 0.0f, 0.0f), t),
			Float3(1.0f, 0.0f, 0.0f)));
	}

	[Test]
	public static void RotationMapsAxesUnderRowVectors()
	{
		let rz = Float4x4.RotationZ(DegreesToRadians(90.0f));
		Test.Assert(NearlyEqual(TransformDirection(Float3.UnitX, rz), Float3.UnitY));

		let ry = Float4x4.RotationY(DegreesToRadians(90.0f));
		// RotationY(90) maps +Z to +X.
		Test.Assert(NearlyEqual(TransformDirection(Float3.UnitZ, ry), Float3.UnitX));
	}

	/// Raptor does not cover RotationX. A matrix with its sign convention flipped would
	/// pass the Y and Z cases and fail here.
	[Test]
	public static void RotationXMapsYToZ()
	{
		let rx = Float4x4.RotationX(DegreesToRadians(90.0f));
		Test.Assert(NearlyEqual(TransformDirection(Float3.UnitY, rx), Float3.UnitZ));
		Test.Assert(NearlyEqual(TransformDirection(Float3.UnitZ, rx), -Float3.UnitY));
	}

	[Test]
	public static void CompositionReadsLeftToRight()
	{
		// v * (S * T): scale first, then translate.
		let st = Float4x4.Scale(Float3(2.0f, 2.0f, 2.0f))
			* Float4x4.Translation(Float3(1.0f, 0.0f, 0.0f));
		let p = TransformPoint(Float3(1.0f, 1.0f, 1.0f), st);
		Test.Assert(NearlyEqual(p, Float3(3.0f, 2.0f, 2.0f)));   // (2,2,2) + (1,0,0)
	}

	/// Composition is not commutative; the other order translates first and then scales
	/// the translation, which is the mistake this pins.
	[Test]
	public static void CompositionIsNotCommutative()
	{
		let s = Float4x4.Scale(Float3(2.0f, 2.0f, 2.0f));
		let t = Float4x4.Translation(Float3(1.0f, 0.0f, 0.0f));
		Test.Assert(NearlyEqual(TransformPoint(Float3(1.0f, 1.0f, 1.0f), t * s),
			Float3(4.0f, 2.0f, 2.0f)));   // (1,1,1)+(1,0,0) then *2
		Test.Assert(!NearlyEqual(s * t, t * s));
	}

	[Test]
	public static void AffineHelpersIn2D()
	{
		Test.Assert(Float4x4.Identity() == Float4x4.Identity());
		Test.Assert(!(Float4x4.Translation(Float3(1.0f, 0.0f, 0.0f)) == Float4x4.Identity()));

		let t = Float4x4.Translation(Float3(5.0f, 7.0f, 0.0f));
		Test.Assert(NearlyEqual(TransformPoint2D(Float2(1.0f, 2.0f), t), Float2(6.0f, 9.0f)));

		let st = Float4x4.Scale(Float3(2.0f, 3.0f, 1.0f))
			* Float4x4.Translation(Float3(1.0f, 1.0f, 0.0f));
		Test.Assert(NearlyEqual(TransformPoint2D(Float2(1.0f, 1.0f), st), Float2(3.0f, 4.0f)));

		let rz = Float4x4.RotationZ(DegreesToRadians(90.0f));
		Test.Assert(NearlyEqual(TransformPoint2D(Float2(1.0f, 0.0f), rz), Float2(0.0f, 1.0f)));
	}

	[Test]
	public static void PerspectiveHasTheExpectedProjectiveStructure()
	{
		let proj = Float4x4.PerspectiveFovRH(DegreesToRadians(90.0f), 1.0f, 1.0f, 100.0f);
		Test.Assert(proj.m[2][3] == -1.0f);            // w' = -z, right-handed
		Test.Assert(NearlyEqual(proj.m[0][0], 1.0f));  // xScale = 1/tan(45) at aspect 1
	}

	/// Raptor checks two entries of the perspective matrix. These pin the depth range,
	/// which is the part that silently differs between the D3D and GL conventions.
	[Test]
	public static void PerspectiveMapsNearAndFarToZeroAndOne()
	{
		let zNear = 1.0f;
		let zFar = 100.0f;
		let proj = Float4x4.PerspectiveFovRH(DegreesToRadians(90.0f), 1.0f, zNear, zFar);

		// A point on the near plane lands at NDC z = 0, one on the far plane at z = 1.
		let atNear = Float4(0.0f, 0.0f, -zNear, 1.0f) * proj;
		let atFar = Float4(0.0f, 0.0f, -zFar, 1.0f) * proj;
		Test.Assert(NearlyEqual(atNear.z / atNear.w, 0.0f, 1.0e-4f));
		Test.Assert(NearlyEqual(atFar.z / atFar.w, 1.0f, 1.0e-4f));
	}

	[Test]
	public static void OrthographicMapsNearAndFarToZeroAndOne()
	{
		let proj = Float4x4.OrthographicRH(4.0f, 4.0f, 1.0f, 100.0f);
		let atNear = Float4(0.0f, 0.0f, -1.0f, 1.0f) * proj;
		let atFar = Float4(0.0f, 0.0f, -100.0f, 1.0f) * proj;
		Test.Assert(NearlyEqual(atNear.z, 0.0f, 1.0e-4f));
		Test.Assert(NearlyEqual(atFar.z, 1.0f, 1.0e-4f));
	}

	/// LookAt is untested in Raptor. The camera looks down -Z, so a camera at +Z looking
	/// at the origin leaves the world axes alone.
	[Test]
	public static void LookAtPlacesTheCamera()
	{
		let view = Float4x4.LookAtRH(Float3(0.0f, 0.0f, 5.0f), Float3.Zero, Float3.UnitY);

		// The eye maps to the origin in view space.
		Test.Assert(NearlyEqual(TransformPoint(Float3(0.0f, 0.0f, 5.0f), view),
			Float3.Zero, 1.0e-4f));
		// A point in front of the camera has negative view-space z.
		Test.Assert(TransformPoint(Float3.Zero, view).z < 0.0f);
	}

	[Test]
	public static void Transposition()
	{
		let t = Float4x4.Translation(Float3(1.0f, 2.0f, 3.0f));
		let tt = Transpose(t);
		Test.Assert(tt.m[0][3] == 1.0f);
		Test.Assert(tt.m[1][3] == 2.0f);
		Test.Assert(tt.m[2][3] == 3.0f);
		Test.Assert(NearlyEqual(Transpose(tt), t));
		Test.Assert(NearlyEqual(Transpose(Float4x4.Identity()), Float4x4.Identity()));
	}

	[Test]
	public static void Determinant()
	{
		Test.Assert(NearlyEqual(Sedulous.Core.Determinant(Float4x4.Identity()), 1.0f));
		Test.Assert(NearlyEqual(
			Sedulous.Core.Determinant(Float4x4.Scale(Float3(2.0f, 3.0f, 4.0f))), 24.0f));

		// A singular matrix has zero determinant, which is what Inverse guards on.
		Test.Assert(NearlyZero(Sedulous.Core.Determinant(Float4x4.Scale(Float3.Zero))));
	}

	[Test]
	public static void InverseUndoesTheTransform()
	{
		Transform xform = .();
		xform.scale = Float3(2.0f, 0.5f, 3.0f);
		xform.rotation = Quaternion.FromAxisAngle(
			Normalized(Float3(1.0f, 2.0f, 3.0f)), DegreesToRadians(50.0f));
		xform.position = Float3(5.0f, -2.0f, 1.0f);

		let m = xform.ToMatrix();
		let inv = Inverse(m);

		Test.Assert(NearlyEqual(m * inv, Float4x4.Identity(), 1.0e-3f));
		Test.Assert(NearlyEqual(inv * m, Float4x4.Identity(), 1.0e-3f));

		let p = Float3(3.0f, 4.0f, 5.0f);
		let roundTrip = TransformPoint(TransformPoint(p, m), inv);
		Test.Assert(NearlyEqual(roundTrip, p, 1.0e-3f));

		// A singular matrix returns Identity rather than dividing by zero.
		Test.Assert(NearlyEqual(Inverse(Float4x4.Scale(Float3.Zero)), Float4x4.Identity()));
	}
}
