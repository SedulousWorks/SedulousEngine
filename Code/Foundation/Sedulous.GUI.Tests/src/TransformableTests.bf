using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Transformable: eepp's behaviour (position, rotation and scale composed into a lazily cached
/// transform).
class TransformableTests
{
	private const float cHalfPi = 1.57079632679489662f;

	private static void CheckPoint(Float2 got, float x, float y)
	{
		Test.Assert(Math.Abs(got.X - x) < 1e-4f, scope $"x {got.X}, expected {x}");
		Test.Assert(Math.Abs(got.Y - y) < 1e-4f, scope $"y {got.Y}, expected {y}");
	}

	/// What Node does: hooks a setter to invalidate.
	private class Hooked : Transformable
	{
		public int Moves;

		public override Float2 Position
		{
			get => base.Position;
			set
			{
				base.Position = value;
				Moves++;
			}
		}
	}

	[Test]
	public static void DefaultsAreIdentity()
	{
		let t = scope Transformable();
		Test.Assert(t.Position == Float2(0.0f, 0.0f));
		Test.Assert(t.Scale == Float2(1.0f, 1.0f));
		Test.Assert(t.Rotation == 0.0f);
		Test.Assert(t.Transform.IsIdentity);
		CheckPoint(t.Transform.TransformPoint(Float2(3.0f, 4.0f)), 3.0f, 4.0f);
	}

	[Test]
	public static void PositionTranslatesPoints()
	{
		let t = scope Transformable();
		t.Position = .(10.0f, 20.0f);
		Test.Assert(t.Position == Float2(10.0f, 20.0f));
		CheckPoint(t.Transform.TransformPoint(Float2(0.0f, 0.0f)), 10.0f, 20.0f);
		CheckPoint(t.Transform.TransformPoint(Float2(5.0f, 5.0f)), 15.0f, 25.0f);
	}

	[Test]
	public static void ScaleAboutOrigin()
	{
		let t = scope Transformable();
		t.ScaleOrigin = .(10.0f, 10.0f);
		t.Scale = .(2.0f, 2.0f);
		CheckPoint(t.Transform.TransformPoint(Float2(10.0f, 10.0f)), 10.0f, 10.0f); // the origin stays fixed
		CheckPoint(t.Transform.TransformPoint(Float2(11.0f, 10.0f)), 12.0f, 10.0f);
	}

	[Test]
	public static void RotationAboutOrigin()
	{
		let t = scope Transformable();
		t.RotationOrigin = .(5.0f, 5.0f);
		t.Rotation = cHalfPi;
		CheckPoint(t.Transform.TransformPoint(Float2(5.0f, 5.0f)), 5.0f, 5.0f); // the pivot stays fixed
	}

	[Test]
	public static void RelativeMoveRotateScale()
	{
		let t = scope Transformable();
		t.Move(.(1.0f, 2.0f));
		t.Move(.(3.0f, 4.0f));
		Test.Assert(t.Position == Float2(4.0f, 6.0f));
		t.ScaleBy(.(2.0f, 3.0f));
		t.ScaleBy(.(2.0f, 1.0f));
		Test.Assert(t.Scale == Float2(4.0f, 3.0f));
		t.Rotate(0.5f);
		t.Rotate(0.25f);
		Test.Assert(Math.Abs(t.Rotation - 0.75f) < 1e-6f);
	}

	[Test]
	public static void InverseRoundTrips()
	{
		let t = scope Transformable();
		t.Position = .(10.0f, -5.0f);
		t.Scale = .(2.0f, 4.0f);
		let p = Float2(3.0f, 7.0f);
		let mapped = t.Transform.TransformPoint(p);
		CheckPoint(t.InverseTransform.TransformPoint(mapped), p.X, p.Y);
	}

	[Test]
	public static void TransformRecomputesAfterChange()
	{
		let t = scope Transformable();
		CheckPoint(t.Transform.TransformPoint(Float2(0.0f, 0.0f)), 0.0f, 0.0f);
		t.Position = .(100.0f, 0.0f);
		CheckPoint(t.Transform.TransformPoint(Float2(0.0f, 0.0f)), 100.0f, 0.0f);
	}

	/// The extra transform (CSS's `transform`) applies about its own origin, after the rest.
	[Test]
	public static void AnExtraTransformAppliesAboutItsOrigin()
	{
		let t = scope Transformable();
		t.Position = .(10.0f, 0.0f);
		var spin = Transform2D();
		spin.Rotate(cHalfPi);
		t.SetExtraTransform(spin, .(5.0f, 5.0f));
		CheckPoint(t.Transform.TransformPoint(Float2(5.0f, 5.0f)), 15.0f, 5.0f);
		CheckPoint(t.Transform.TransformPoint(Float2(6.0f, 5.0f)), 15.0f, 6.0f);
	}

	[Test]
	public static void ASubclassHooksASetterAndTheTransformStillFollows()
	{
		let t = scope Hooked();
		t.Move(.(2.0f, 3.0f));
		Test.Assert(t.Moves == 1);
		CheckPoint(t.Transform.TransformPoint(Float2(0.0f, 0.0f)), 2.0f, 3.0f);
	}
}
