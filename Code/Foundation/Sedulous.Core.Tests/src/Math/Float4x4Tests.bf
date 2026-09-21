using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Float4x4. NearlyEqual is an absolute comparison, so the epsilons here are chosen for
/// the magnitudes involved.
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
		Test.Assert(t.M[3][0] == 10.0f);
		Test.Assert(t.M[3][1] == 20.0f);
		Test.Assert(t.M[3][2] == 30.0f);

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

	/// RotationX on its own: a matrix with its sign convention flipped would pass the Y
	/// and Z cases and fail here.
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
		Test.Assert(proj.M[2][3] == -1.0f);            // w' = -z, right-handed
		Test.Assert(NearlyEqual(proj.M[0][0], 1.0f));  // xScale = 1/tan(45) at aspect 1
	}

	/// NDC depth of a point `distance` in front of a camera at the origin looking down -Z.
	private static float NdcDepthAt(Float4x4 proj, float distance)
	{
		let clip = Float4(0.0f, 0.0f, -distance, 1.0f) * proj;
		return clip.Z / clip.W;
	}

	/// The depth convention is REVERSE-Z: near maps to 1, far to 0, nearer is larger. The
	/// builders, the closed form and its inverse agree, and the reason for the switch is
	/// measurable: two surfaces 0.02 apart at 900 units are hundreds of ulps apart.
	[Test]
	public static void TheDepthConventionIsReverseZ()
	{
		Test.Assert(Projection.ReverseZ);
		Test.Assert(Projection.NdcDepthNear == 1.0f);
		Test.Assert(Projection.NdcDepthFar == 0.0f);
		Test.Assert(Projection.IsNearer(0.7f, 0.2f));
		Test.Assert(Projection.IsBackground(Projection.NdcDepthFar));
		Test.Assert(!Projection.IsBackground(1.0e-7f));

		let n = 0.1f;
		let f = 1000.0f;
		let proj = Float4x4.PerspectiveFovRH(1.0f, 16.0f / 9.0f, n, f);
		Test.Assert(NearlyEqual(NdcDepthAt(proj, n), Projection.NdcDepthNear, 1.0e-5f));
		Test.Assert(NearlyEqual(NdcDepthAt(proj, f), Projection.NdcDepthFar, 1.0e-5f));

		// Monotonic: farther is smaller, and the matrix agrees with the closed form.
		float previous = 2.0f;
		for (let d in scope float[](n, 0.5f, 1.0f, 10.0f, 100.0f, 500.0f, f))
		{
			let depth = NdcDepthAt(proj, d);
			Test.Assert(depth < previous);
			Test.Assert(NearlyEqual(depth, Projection.DepthAtDistance(d, n, f), 1.0e-5f));
			// Linearize inverts it, with a relative tolerance since the far end is large.
			Test.Assert(Abs(Projection.LinearizeDepth(depth, n, f) - d) <= d * 1.0e-4f);
			previous = depth;
		}

		// Reverse-Z spends the float where a perspective divide starves it: two surfaces
		// 0.02 apart at 900 units are far apart in ulps, where under standard-Z the gap is
		// a fraction of one at depth ~1 and they z-fight.
		let wall = NdcDepthAt(proj, 900.0f);
		let face = NdcDepthAt(proj, 900.0f - 0.02f);
		Test.Assert(face > wall);
		Test.Assert((face - wall) > 100.0f * 1.2e-7f * wall, "more than 100 ulps of the smaller value");

		// Orthographic: the same reading.
		let ortho = Float4x4.OrthographicRH(10.0f, 10.0f, 2.0f, 50.0f);
		Test.Assert(NearlyEqual(NdcDepthAt(ortho, 2.0f), Projection.NdcDepthNear, 1.0e-6f));
		Test.Assert(NearlyEqual(NdcDepthAt(ortho, 50.0f), Projection.NdcDepthFar, 1.0e-6f));
		Test.Assert(NearlyEqual(NdcDepthAt(ortho, 26.0f), 0.5f, 1.0e-6f));
	}

	/// LookAt. The camera looks down -Z, so a camera at +Z looking at the origin leaves
	/// the world axes alone.
	[Test]
	public static void LookAtPlacesTheCamera()
	{
		let view = Float4x4.LookAtRH(Float3(0.0f, 0.0f, 5.0f), Float3.Zero, Float3.UnitY);

		// The eye maps to the origin in view space.
		Test.Assert(NearlyEqual(TransformPoint(Float3(0.0f, 0.0f, 5.0f), view),
			Float3.Zero, 1.0e-4f));
		// A point in front of the camera has negative view-space z.
		Test.Assert(TransformPoint(Float3.Zero, view).Z < 0.0f);
	}

	[Test]
	public static void Transposition()
	{
		let t = Float4x4.Translation(Float3(1.0f, 2.0f, 3.0f));
		let tt = Transpose(t);
		Test.Assert(tt.M[0][3] == 1.0f);
		Test.Assert(tt.M[1][3] == 2.0f);
		Test.Assert(tt.M[2][3] == 3.0f);
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
		xform.Scale = Float3(2.0f, 0.5f, 3.0f);
		xform.Rotation = Quaternion.FromAxisAngle(
			Normalized(Float3(1.0f, 2.0f, 3.0f)), DegreesToRadians(50.0f));
		xform.Position = Float3(5.0f, -2.0f, 1.0f);

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
