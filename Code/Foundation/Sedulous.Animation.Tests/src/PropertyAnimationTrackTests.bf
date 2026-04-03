namespace Sedulous.Animation.Tests;

using System;
using Sedulous.Core.Mathematics;

class PropertyAnimationTrackTests
{
	// ==================== Construction ====================

	[Test]
	public static void Constructor_SetsPropertyPath()
	{
		let track = scope PropertyAnimationTrack<float>("Light.Intensity");
		Test.Assert(track.PropertyPath.Equals("Light.Intensity"));
	}

	[Test]
	public static void Constructor_DefaultInterpolation_IsLinear()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		Test.Assert(track.Interpolation == .Linear);
	}

	[Test]
	public static void Constructor_DefaultEasing_IsLinear()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		Test.Assert(track.Easing == .Linear);
	}

	[Test]
	public static void ValueType_Float()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		Test.Assert(track.ValueType == .Float);
	}

	[Test]
	public static void ValueType_Vector3()
	{
		let track = scope PropertyAnimationTrack<Vector3>("Test");
		Test.Assert(track.ValueType == .Vector3);
	}

	[Test]
	public static void ValueType_Quaternion()
	{
		let track = scope PropertyAnimationTrack<Quaternion>("Test");
		Test.Assert(track.ValueType == .Quaternion);
	}

	// ==================== Keyframes ====================

	[Test]
	public static void AddKeyframe_IncreasesCount()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		Test.Assert(track.Keyframes.Count == 0);
		track.AddKeyframe(0.0f, 1.0f);
		Test.Assert(track.Keyframes.Count == 1);
		track.AddKeyframe(1.0f, 2.0f);
		Test.Assert(track.Keyframes.Count == 2);
	}

	[Test]
	public static void SortKeyframes_SortsByTime()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		track.AddKeyframe(1.0f, 10.0f);
		track.AddKeyframe(0.0f, 0.0f);
		track.AddKeyframe(0.5f, 5.0f);
		track.SortKeyframes();
		Test.Assert(track.Keyframes[0].Time == 0.0f);
		Test.Assert(track.Keyframes[1].Time == 0.5f);
		Test.Assert(track.Keyframes[2].Time == 1.0f);
	}

	[Test]
	public static void GetDuration_ReturnsLastKeyframeTime()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		Test.Assert(track.GetDuration() == 0.0f);
		track.AddKeyframe(0.0f, 0.0f);
		track.AddKeyframe(2.5f, 1.0f);
		Test.Assert(track.GetDuration() == 2.5f);
	}

	// ==================== FindKeyframes ====================

	[Test]
	public static void FindKeyframes_EmptyTrack_ReturnsNegative()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		let (prev, next, t) = track.FindKeyframes(0.5f);
		Test.Assert(prev == -1);
		Test.Assert(next == -1);
	}

	[Test]
	public static void FindKeyframes_SingleKeyframe_ReturnsIt()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		track.AddKeyframe(1.0f, 5.0f);
		let (prev, next, t) = track.FindKeyframes(0.5f);
		Test.Assert(prev == 0);
		Test.Assert(next == 0);
		Test.Assert(t == 0.0f);
	}

	[Test]
	public static void FindKeyframes_BetweenTwo_InterpolatesFactor()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		track.AddKeyframe(0.0f, 0.0f);
		track.AddKeyframe(1.0f, 10.0f);
		let (prev, next, t) = track.FindKeyframes(0.5f);
		Test.Assert(prev == 0);
		Test.Assert(next == 1);
		Test.Assert(Math.Abs(t - 0.5f) < 0.001f);
	}

	[Test]
	public static void FindKeyframes_BeforeFirst_ClampsToFirst()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		track.AddKeyframe(1.0f, 5.0f);
		track.AddKeyframe(2.0f, 10.0f);
		let (prev, next, t) = track.FindKeyframes(0.0f);
		Test.Assert(prev == 0);
		Test.Assert(next == 0);
	}

	[Test]
	public static void FindKeyframes_AfterLast_ClampsToLast()
	{
		let track = scope PropertyAnimationTrack<float>("Test");
		track.AddKeyframe(0.0f, 0.0f);
		track.AddKeyframe(1.0f, 10.0f);
		let (prev, next, t) = track.FindKeyframes(5.0f);
		Test.Assert(prev == 1);
		Test.Assert(next == 1);
	}
}
