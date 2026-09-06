using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

class TransformTests
{
	[Test]
	public static void ComposesScaleRotationTranslation()
	{
		Transform xform = .();
		xform.scale = Float3(2.0f, 2.0f, 2.0f);
		xform.rotation = Quaternion.FromAxisAngle(Float3.UnitZ, DegreesToRadians(90.0f));
		xform.position = Float3(5.0f, 0.0f, 0.0f);

		let m = xform.ToMatrix();

		// (1,0,0) -> scale 2 -> (2,0,0) -> rotate 90 about Z -> (0,2,0) -> translate -> (5,2,0)
		Test.Assert(NearlyEqual(TransformPoint(Float3.UnitX, m), Float3(5.0f, 2.0f, 0.0f)));

		// The identity transform is a no-op.
		Transform identity = .();
		Test.Assert(NearlyEqual(TransformPoint(Float3(7.0f, 8.0f, 9.0f), identity.ToMatrix()),
			Float3(7.0f, 8.0f, 9.0f)));
	}

	/// The const and the runtime default have to agree. They did not: a const is folded
	/// without running field initializers, so IdentityTransform was all zeros, including
	/// a zero scale, while `Transform t = .()` was correct. Nothing else here would have
	/// noticed, because every other case sets all three fields.
	[Test]
	public static void IdentityConstMatchesDefaultConstruction()
	{
		Transform runtime = .();
		Test.Assert(NearlyEqual(IdentityTransform.position, runtime.position));
		Test.Assert(NearlyEqual(IdentityTransform.scale, runtime.scale));
		Test.Assert(NearlyEqual(IdentityTransform.rotation, runtime.rotation));
		Test.Assert(NearlyEqual(IdentityTransform.ToMatrix(), Float4x4.Identity()));
	}

	[Test]
	public static void LerpAndIdentity()
	{
		Test.Assert(NearlyEqual(IdentityTransform.position, Float3.Zero));
		Test.Assert(NearlyEqual(IdentityTransform.scale, Float3.One));

		let a = Transform(Float3(0.0f, 0.0f, 0.0f), Quaternion.Identity, Float3(1.0f, 1.0f, 1.0f));
		let b = Transform(Float3(2.0f, 4.0f, 6.0f), Quaternion.Identity, Float3(3.0f, 3.0f, 3.0f));

		let m = Transform.Lerp(a, b, 0.5f);
		Test.Assert(NearlyEqual(m.position, Float3(1.0f, 2.0f, 3.0f)));
		Test.Assert(NearlyEqual(m.scale, Float3(2.0f, 2.0f, 2.0f)));

		let at0 = Transform.Lerp(a, b, 0.0f);
		let at1 = Transform.Lerp(a, b, 1.0f);
		Test.Assert(NearlyEqual(at0.position, a.position));
		Test.Assert(NearlyEqual(at1.position, b.position));
	}

	/// Raptor's Lerp case uses identity rotations at both ends, so the slerp inside it
	/// is never actually exercised.
	[Test]
	public static void LerpSlerpsTheRotation()
	{
		let a = Transform(Float3.Zero, Quaternion.Identity, Float3.One);
		let b = Transform(Float3.Zero,
			Quaternion.FromAxisAngle(Float3.UnitZ, DegreesToRadians(90.0f)), Float3.One);

		let mid = Transform.Lerp(a, b, 0.5f);
		let c = Cos(DegreesToRadians(45.0f));
		Test.Assert(NearlyEqual(RotateVector(mid.rotation, Float3.UnitX),
			Float3(c, c, 0.0f), 1.0e-4f));
	}

	[Test]
	public static void DecomposeRoundTripsCompose()
	{
		Transform t = .();
		t.position = Float3(3.0f, -2.0f, 7.5f);
		t.rotation = Quaternion.FromAxisAngle(Normalized(Float3(0.3f, 1.0f, -0.2f)), 1.1f);
		t.scale = Float3(2.0f, 0.5f, 3.0f);   // non-uniform

		Float3 pos = ?, scale = ?;
		Quaternion rot = ?;
		Test.Assert(Decompose(t.ToMatrix(), out pos, out rot, out scale));

		Test.Assert(NearlyEqual(pos, t.position, 1.0e-3f));
		Test.Assert(NearlyEqual(scale, t.scale, 1.0e-3f));
		// Quaternions are sign-ambiguous, so compare the magnitude of the dot.
		Test.Assert(NearlyEqual(Abs(Dot(t.rotation, rot)), 1.0f, 1.0e-3f));

		// FromMatrix reproduces the same matrix.
		let back = Transform.FromMatrix(t.ToMatrix());
		Test.Assert(NearlyEqual(back.ToMatrix(), t.ToMatrix(), 1.0e-3f));

		// A degenerate matrix fails with identity outputs.
		var flat = t;
		flat.scale.y = 0.0f;
		Test.Assert(!Decompose(flat.ToMatrix(), out pos, out rot, out scale));
		Test.Assert(scale.y == 1.0f);

		// Identity decomposes to identity.
		Test.Assert(Decompose(Float4x4.Identity(), out pos, out rot, out scale));
		Test.Assert(pos.x == 0.0f);
		Test.Assert(scale.x == 1.0f);
		Test.Assert(NearlyEqual(rot.w, 1.0f));
	}

	[Test]
	public static void RigidPartStripsScaleKeepsTranslationAndRotation()
	{
		// The nav-zone placement frame: a matrix must place world-unit-sized data
		// without warping it.
		Transform t = .();
		t.position = Float3(3.0f, -2.0f, 7.5f);
		t.rotation = Quaternion.FromAxisAngle(Normalized(Float3(0.3f, 1.0f, 0.2f)), 0.9f);
		t.scale = Float3(2.0f, 0.5f, 4.0f);

		let rigid = RigidPart(t.ToMatrix());
		Float3 pos = ?, scale = ?;
		Quaternion rot = ?;
		Test.Assert(Decompose(rigid, out pos, out rot, out scale));
		Test.Assert(NearlyEqual(pos, Float3(3.0f, -2.0f, 7.5f), 1.0e-3f));
		Test.Assert(NearlyEqual(scale, Float3.One, 1.0e-3f));
		// The same rotation, allowing the q/-q double cover.
		Test.Assert(NearlyEqual(Abs(Dot(rot, t.rotation)), 1.0f, 1.0e-3f));

		// A unit-scale matrix passes through unchanged, within rounding.
		var u = t;
		u.scale = Float3.One;
		Test.Assert(NearlyEqual(RigidPart(u.ToMatrix()), u.ToMatrix(), 1.0e-3f));

		// Documented failure behaviour: a degenerate frame cannot decompose, so
		// RigidPart falls back to translation with an IDENTITY rotation, never garbage.
		var degenerate = t;
		degenerate.scale.y = 0.0f;
		let fallback = RigidPart(degenerate.ToMatrix());
		Test.Assert(Decompose(fallback, out pos, out rot, out scale));
		Test.Assert(NearlyEqual(pos.x, 3.0f, 1.0e-3f));
		Test.Assert(NearlyEqual(rot.w, 1.0f, 1.0e-3f));
	}
}
