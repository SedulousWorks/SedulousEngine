using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

class QuaternionTests
{
	[Test]
	public static void RotatesVectorsAndAgreesWithItsMatrix()
	{
		let q = Quaternion.FromAxisAngle(Float3.UnitZ, DegreesToRadians(90.0f));

		// 90 degrees about Z maps +X to +Y.
		Test.Assert(NearlyEqual(RotateVector(q, Float3.UnitX), Float3.UnitY));

		// The quaternion and its matrix agree.
		let r = RotationMatrix(q);
		Test.Assert(NearlyEqual(RotateVector(q, Float3.UnitX),
			TransformDirection(Float3.UnitX, r)));
		Test.Assert(NearlyEqual(RotateVector(q, Float3(0.3f, -0.5f, 0.8f)),
			TransformDirection(Float3(0.3f, -0.5f, 0.8f), r)));

		// Identity does nothing.
		Test.Assert(NearlyEqual(RotateVector(Quaternion.Identity, Float3(1.0f, 2.0f, 3.0f)),
			Float3(1.0f, 2.0f, 3.0f)));

		// Two 45 degree rotations compose to one of 90.
		let half = Quaternion.FromAxisAngle(Float3.UnitZ, DegreesToRadians(45.0f));
		Test.Assert(NearlyEqual(RotateVector(half * half, Float3.UnitX), Float3.UnitY));
	}

	/// The Hamilton product applies its right operand first. Composing two rotations
	/// about different axes is the case where getting that backwards shows up.
	[Test]
	public static void ProductAppliesTheRightOperandFirst()
	{
		let rz = Quaternion.FromAxisAngle(Float3.UnitZ, DegreesToRadians(90.0f));
		let rx = Quaternion.FromAxisAngle(Float3.UnitX, DegreesToRadians(90.0f));

		// rz * rx applies rx first: +Y -> +Z (by rx), then +Z is unmoved by rz.
		Test.Assert(NearlyEqual(RotateVector(rz * rx, Float3.UnitY), Float3.UnitZ, 1.0e-5f));
		// The other order is different, which is the whole point.
		Test.Assert(!NearlyEqual(RotateVector(rx * rz, Float3.UnitY),
			RotateVector(rz * rx, Float3.UnitY)));
	}

	[Test]
	public static void ConjugateAndInverseUndoARotation()
	{
		let q = Quaternion.FromAxisAngle(Normalized(Float3(1.0f, 2.0f, 3.0f)), 0.7f);
		let v = Float3(0.3f, -0.5f, 0.8f);

		// For a unit quaternion the conjugate is the inverse.
		Test.Assert(NearlyEqual(RotateVector(Conjugate(q), RotateVector(q, v)), v, 1.0e-5f));
		Test.Assert(NearlyEqual(Inverse(q), Conjugate(q), 1.0e-5f));
		Test.Assert(NearlyEqual(q * Inverse(q), Quaternion.Identity, 1.0e-5f));

		// A degenerate quaternion inverts to identity rather than dividing by zero.
		Test.Assert(NearlyEqual(Inverse(Quaternion(0.0f, 0.0f, 0.0f, 0.0f)), Quaternion.Identity));
		Test.Assert(NearlyEqual(Normalized(Quaternion(0.0f, 0.0f, 0.0f, 0.0f)),
			Quaternion.Identity));
	}

	[Test]
	public static void SlerpEndpointsAndMidpoint()
	{
		let a = Quaternion.Identity;
		let b = Quaternion.FromAxisAngle(Float3.UnitZ, DegreesToRadians(90.0f));

		Test.Assert(NearlyEqual(Slerp(a, b, 0.0f), a));
		Test.Assert(NearlyEqual(Slerp(a, b, 1.0f), b));

		// Halfway between 0 and 90 degrees about Z is 45: +X maps to (cos45, sin45, 0).
		let mid = Slerp(a, b, 0.5f);
		let rotated = RotateVector(mid, Float3.UnitX);
		let c = Cos(DegreesToRadians(45.0f));
		Test.Assert(NearlyEqual(rotated, Float3(c, c, 0.0f), 1.0e-4f));
	}

	/// Slerp takes the shortest arc, so it has to negate one input when they point into
	/// opposite hemispheres. That branch, and the near-parallel lerp fallback, are easy to
	/// leave unexercised.
	[Test]
	public static void SlerpTakesTheShortestArc()
	{
		let a = Quaternion.FromAxisAngle(Float3.UnitZ, DegreesToRadians(10.0f));
		// The same rotation, negated: q and -q are the same orientation.
		let negated = Quaternion(-a.X, -a.Y, -a.Z, -a.W);

		// Interpolating between a rotation and its own double cover must not move.
		let mid = Slerp(a, negated, 0.5f);
		Test.Assert(NearlyEqual(RotateVector(mid, Float3.UnitX),
			RotateVector(a, Float3.UnitX), 1.0e-4f));

		// Nearly parallel inputs take the lerp-and-normalize path and stay unit.
		let b = Quaternion.FromAxisAngle(Float3.UnitZ, DegreesToRadians(10.001f));
		let near = Slerp(a, b, 0.5f);
		Test.Assert(NearlyEqual(Dot(near, near), 1.0f, 1.0e-4f));
	}

	[Test]
	public static void YawPitchRollRoundTrips()
	{
		let yaw = 0.8f;
		let pitch = 0.4f;    // within (-pi/2, pi/2)
		let roll = -0.3f;

		let q = FromYawPitchRoll(yaw, pitch, roll);
		float y = 0, p = 0, r = 0;
		ToYawPitchRoll(q, out y, out p, out r);
		Test.Assert(NearlyEqual(y, yaw, 1.0e-3f));
		Test.Assert(NearlyEqual(p, pitch, 1.0e-3f));
		Test.Assert(NearlyEqual(r, roll, 1.0e-3f));

		// Pure yaw about Y matches FromAxisAngle, up to the q/-q double cover.
		let qy = FromYawPitchRoll(0.6f, 0.0f, 0.0f);
		let qa = Quaternion.FromAxisAngle(Float3(0.0f, 1.0f, 0.0f), 0.6f);
		Test.Assert(NearlyEqual(Abs(Dot(qy, qa)), 1.0f, 1.0e-3f));
	}

	/// QuaternionFromRotationMatrix switches on which diagonal element dominates, so a
	/// single rotation only exercises one of its four branches. These reach all four.
	[Test]
	public static void FromRotationMatrixCoversEveryBranch()
	{
		Float3[?] axes = .(
			Float3.UnitX, Float3.UnitY, Float3.UnitZ,
			Normalized(Float3(1.0f, 1.0f, 1.0f)), Normalized(Float3(-1.0f, 2.0f, -3.0f)));
		float[?] angles = .(0.0f, 30.0f, 90.0f, 179.0f, 180.0f, 270.0f);

		for (let axis in axes)
		{
			for (let deg in angles)
			{
				let q = Quaternion.FromAxisAngle(axis, DegreesToRadians(deg));
				let back = QuaternionFromRotationMatrix(RotationMatrix(q));
				// Up to sign: q and -q are the same orientation.
				Test.Assert(NearlyEqual(Abs(Dot(q, back)), 1.0f, 1.0e-3f));
				// And the recovered rotation acts the same on a vector.
				let v = Float3(0.3f, -0.5f, 0.8f);
				Test.Assert(NearlyEqual(RotateVector(back, v), RotateVector(q, v), 1.0e-3f));
			}
		}
	}
}
