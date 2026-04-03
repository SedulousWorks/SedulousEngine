namespace Sedulous.Animation.Tests;

using System;
using Sedulous.Core.Mathematics;

class PropertyAnimationSamplerTests
{
	// ==================== Float Sampling ====================

	[Test]
	public static void SampleFloat_EmptyTrack_ReturnsDefault()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		let result = PropertyAnimationSampler.SampleFloat(track, 0.5f, 42.0f);
		Test.Assert(result == 42.0f);
	}

	[Test]
	public static void SampleFloat_NullTrack_ReturnsDefault()
	{
		let result = PropertyAnimationSampler.SampleFloat(null, 0.5f, 42.0f);
		Test.Assert(result == 42.0f);
	}

	[Test]
	public static void SampleFloat_SingleKeyframe_ReturnsValue()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		track.AddKeyframe(0.0f, 5.0f);
		let result = PropertyAnimationSampler.SampleFloat(track, 0.5f);
		Test.Assert(result == 5.0f);
	}

	[Test]
	public static void SampleFloat_Linear_Interpolates()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		track.AddKeyframe(0.0f, 0.0f);
		track.AddKeyframe(1.0f, 10.0f);
		let result = PropertyAnimationSampler.SampleFloat(track, 0.5f);
		Test.Assert(Math.Abs(result - 5.0f) < 0.01f);
	}

	[Test]
	public static void SampleFloat_Step_HoldsPrevious()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		track.Interpolation = .Step;
		track.AddKeyframe(0.0f, 0.0f);
		track.AddKeyframe(1.0f, 10.0f);
		let result = PropertyAnimationSampler.SampleFloat(track, 0.5f);
		Test.Assert(result == 0.0f);
	}

	[Test]
	public static void SampleFloat_WithEasing_AppliesEasing()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		track.Easing = .EaseInQuadratic;
		track.AddKeyframe(0.0f, 0.0f);
		track.AddKeyframe(1.0f, 10.0f);
		let result = PropertyAnimationSampler.SampleFloat(track, 0.5f);
		// EaseInQuadratic at 0.5 gives t=0.25, so value should be ~2.5
		Test.Assert(result < 5.0f);
	}

	// ==================== Vector3 Sampling ====================

	[Test]
	public static void SampleVector3_Linear_Interpolates()
	{
		let track = scope PropertyAnimationTrack<Vector3>("Test");
		track.AddKeyframe(0.0f, Vector3(0, 0, 0));
		track.AddKeyframe(1.0f, Vector3(10, 20, 30));
		let result = PropertyAnimationSampler.SampleVector3(track, 0.5f);
		Test.Assert(Math.Abs(result.X - 5.0f) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 10.0f) < 0.01f);
		Test.Assert(Math.Abs(result.Z - 15.0f) < 0.01f);
	}

	[Test]
	public static void SampleVector3_EmptyTrack_ReturnsDefault()
	{
		let track = scope PropertyAnimationTrack<Vector3>("Test");
		let def = Vector3(1, 2, 3);
		let result = PropertyAnimationSampler.SampleVector3(track, 0.5f, def);
		Test.Assert(result.X == 1.0f);
		Test.Assert(result.Y == 2.0f);
		Test.Assert(result.Z == 3.0f);
	}

	// ==================== Quaternion Sampling ====================

	[Test]
	public static void SampleQuaternion_Linear_Slerps()
	{
		let track = scope PropertyAnimationTrack<Quaternion>("Test");
		track.AddKeyframe(0.0f, Quaternion.Identity);
		let rot90 = Quaternion.CreateFromYawPitchRoll(Math.PI_f / 2, 0, 0);
		track.AddKeyframe(1.0f, rot90);
		let result = PropertyAnimationSampler.SampleQuaternion(track, 0.5f);
		// Midpoint should be roughly 45 degrees
		let expected = Quaternion.CreateFromYawPitchRoll(Math.PI_f / 4, 0, 0);
		let dot = Math.Abs(result.X * expected.X + result.Y * expected.Y + result.Z * expected.Z + result.W * expected.W);
		Test.Assert(dot > 0.99f);
	}

	[Test]
	public static void SampleQuaternion_Step_HoldsPrevious()
	{
		let track = scope PropertyAnimationTrack<Quaternion>("Test");
		track.Interpolation = .Step;
		track.AddKeyframe(0.0f, Quaternion.Identity);
		let rot90 = Quaternion.CreateFromYawPitchRoll(Math.PI_f / 2, 0, 0);
		track.AddKeyframe(1.0f, rot90);
		let result = PropertyAnimationSampler.SampleQuaternion(track, 0.5f);
		// Step should hold identity
		let dot = Math.Abs(result.X * Quaternion.Identity.X + result.Y * Quaternion.Identity.Y +
			result.Z * Quaternion.Identity.Z + result.W * Quaternion.Identity.W);
		Test.Assert(dot > 0.99f);
	}

	// ==================== Vector2 Sampling ====================

	[Test]
	public static void SampleVector2_Linear_Interpolates()
	{
		let track = scope PropertyAnimationTrack<Vector2>("Test");
		track.AddKeyframe(0.0f, Vector2(0, 0));
		track.AddKeyframe(1.0f, Vector2(10, 20));
		let result = PropertyAnimationSampler.SampleVector2(track, 0.5f);
		Test.Assert(Math.Abs(result.X - 5.0f) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 10.0f) < 0.01f);
	}

	// ==================== Vector4 Sampling ====================

	[Test]
	public static void SampleVector4_Linear_Interpolates()
	{
		let track = scope PropertyAnimationTrack<Vector4>("Test");
		track.AddKeyframe(0.0f, Vector4(0, 0, 0, 0));
		track.AddKeyframe(1.0f, Vector4(10, 20, 30, 40));
		let result = PropertyAnimationSampler.SampleVector4(track, 0.5f);
		Test.Assert(Math.Abs(result.X - 5.0f) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 10.0f) < 0.01f);
		Test.Assert(Math.Abs(result.Z - 15.0f) < 0.01f);
		Test.Assert(Math.Abs(result.W - 20.0f) < 0.01f);
	}

	// ==================== Multi-keyframe ====================

	[Test]
	public static void SampleFloat_ThreeKeyframes_InterpolatesCorrectSegment()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		track.AddKeyframe(0.0f, 0.0f);
		track.AddKeyframe(1.0f, 10.0f);
		track.AddKeyframe(2.0f, 0.0f);
		// At t=1.5, should interpolate between kf[1]=10 and kf[2]=0 at t=0.5
		let result = PropertyAnimationSampler.SampleFloat(track, 1.5f);
		Test.Assert(Math.Abs(result - 5.0f) < 0.01f);
	}
}
