using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Transform2D: eepp's Transform behaviour (translate, rotate, scale, combine, inverse,
/// transformPoint), and ToMatrix feeding TransformPoint2D (the VG DrawContext convention)
/// identically.
class Transform2DTests
{
	private const float cHalfPi = 1.57079632679489662f;

	private static void CheckPoint(Float2 got, float x, float y)
	{
		Test.Assert(Math.Abs(got.X - x) < 1e-4f, scope $"x {got.X}, expected {x}");
		Test.Assert(Math.Abs(got.Y - y) < 1e-4f, scope $"y {got.Y}, expected {y}");
	}

	[Test]
	public static void DefaultIsIdentity()
	{
		let t = Transform2D();
		Test.Assert(t.IsIdentity);
		CheckPoint(t.TransformPoint(Float2(7.0f, 9.0f)), 7.0f, 9.0f);
	}

	[Test]
	public static void Translate()
	{
		var t = Transform2D();
		t.Translate(10.0f, 20.0f);
		Test.Assert(!t.IsIdentity);
		CheckPoint(t.TransformPoint(Float2(0.0f, 0.0f)), 10.0f, 20.0f);
		CheckPoint(t.TransformPoint(Float2(5.0f, 5.0f)), 15.0f, 25.0f);
	}

	[Test]
	public static void Scale()
	{
		var t = Transform2D();
		t.Scale(2.0f, 3.0f);
		CheckPoint(t.TransformPoint(Float2(4.0f, 5.0f)), 8.0f, 15.0f);
	}

	[Test]
	public static void Rotate90Degrees()
	{
		var t = Transform2D();
		t.Rotate(cHalfPi);
		CheckPoint(t.TransformPoint(Float2(1.0f, 0.0f)), 0.0f, 1.0f);
		CheckPoint(t.TransformPoint(Float2(0.0f, 1.0f)), -1.0f, 0.0f);
	}

	[Test]
	public static void RotateAboutCenterLeavesCenterFixed()
	{
		var t = Transform2D();
		t.Rotate(cHalfPi, Float2(5.0f, 5.0f));
		CheckPoint(t.TransformPoint(Float2(5.0f, 5.0f)), 5.0f, 5.0f);
	}

	/// Translate(10, 0) then Scale(2, 2): a point is scaled first, then translated.
	[Test]
	public static void CombineAppliesRightHandFirst()
	{
		var t = Transform2D();
		t.Translate(10.0f, 0.0f).Scale(2.0f, 2.0f);
		CheckPoint(t.TransformPoint(Float2(1.0f, 1.0f)), 12.0f, 2.0f);
	}

	[Test]
	public static void MultiplyMatchesCombine()
	{
		var a = Transform2D();
		a.Translate(3.0f, 4.0f);
		var b = Transform2D();
		b.Scale(2.0f, 5.0f);
		var combined = a;
		combined.Combine(b);
		Test.Assert(NearlyEqual(combined, a * b));
	}

	[Test]
	public static void InverseRoundTrips()
	{
		var t = Transform2D();
		t.Translate(10.0f, -3.0f).Scale(2.0f, 4.0f).Rotate(0.7f);
		let inv = t.GetInverse();
		let p = Float2(6.0f, -2.0f);
		let mapped = t.TransformPoint(p);
		CheckPoint(inv.TransformPoint(mapped), p.X, p.Y);
		Test.Assert(NearlyEqual(t * inv, Transform2D.Identity));
	}

	[Test]
	public static void SingularInverseFallsBackToIdentity()
	{
		let degenerate = Transform2D(0.0f, 0.0f, 0.0f, 0.0f, 5.0f, 5.0f); // det 0
		Test.Assert(degenerate.GetInverse().IsIdentity);
	}

	[Test]
	public static void TransformRectIsTheBoundsOfItsCorners()
	{
		var t = Transform2D();
		t.Rotate(cHalfPi); // (x, y) -> (-y, x)
		let r = t.TransformRect(Rect(0.0f, 0.0f, 10.0f, 20.0f));
		Test.Assert(Math.Abs(r.X - -20.0f) < 1e-4f);
		Test.Assert(Math.Abs(r.Y - 0.0f) < 1e-4f);
		Test.Assert(Math.Abs(r.Width - 20.0f) < 1e-4f);
		Test.Assert(Math.Abs(r.Height - 10.0f) < 1e-4f);
	}

	[Test]
	public static void ToMatrixFeedsTransformPoint2DIdentically()
	{
		var t = Transform2D();
		t.Translate(12.0f, -7.0f).Rotate(0.9f).Scale(1.5f, 2.0f);
		let m = t.ToMatrix();
		Float2[4] probes = .(.(0.0f, 0.0f), .(1.0f, 0.0f), .(0.0f, 1.0f), .(-3.5f, 8.25f));
		for (let p in probes)
		{
			let viaTransform = t.TransformPoint(p);
			let viaMatrix = TransformPoint2D(p, m);
			Test.Assert(Math.Abs(viaMatrix.X - viaTransform.X) < 1e-4f);
			Test.Assert(Math.Abs(viaMatrix.Y - viaTransform.Y) < 1e-4f);
		}
	}
}
