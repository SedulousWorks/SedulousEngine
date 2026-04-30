using System;
using Sedulous.Audio;
using Sedulous.Core.Mathematics;

namespace Sedulous.Audio.Tests;

class AudioSourceTests
{
	// Note: These tests create sources without a valid audio system,
	// so we test property behavior, not actual playback.

	[Test]
	public static void TestDefaultState()
	{
		let source = scope AudioSource();

		Test.Assert(source.State == .Stopped);
	}

	[Test]
	public static void TestDefaultVolume()
	{
		let source = scope AudioSource();

		Test.Assert(source.Volume == 1.0f);
	}

	[Test]
	public static void TestSetVolume()
	{
		let source = scope AudioSource();

		source.Volume = 0.5f;
		Test.Assert(source.Volume == 0.5f);
	}

	[Test]
	public static void TestVolumeClampMin()
	{
		let source = scope AudioSource();

		source.Volume = -0.5f;
		Test.Assert(source.Volume == 0.0f);
	}

	[Test]
	public static void TestVolumeClampMax()
	{
		let source = scope AudioSource();

		source.Volume = 1.5f;
		Test.Assert(source.Volume == 1.0f);
	}

	[Test]
	public static void TestDefaultPitch()
	{
		let source = scope AudioSource();

		Test.Assert(source.Pitch == 1.0f);
	}

	[Test]
	public static void TestSetPitch()
	{
		let source = scope AudioSource();

		source.Pitch = 2.0f;
		Test.Assert(source.Pitch == 2.0f);
	}

	[Test]
	public static void TestPitchClampMin()
	{
		let source = scope AudioSource();

		source.Pitch = 0.0f;
		Test.Assert(source.Pitch >= 0.01f);
	}

	[Test]
	public static void TestDefaultLoop()
	{
		let source = scope AudioSource();

		Test.Assert(source.Loop == false);
	}

	[Test]
	public static void TestSetLoop()
	{
		let source = scope AudioSource();

		source.Loop = true;
		Test.Assert(source.Loop == true);
	}

	[Test]
	public static void TestDefaultPosition()
	{
		let source = scope AudioSource();

		Test.Assert(source.Position == Vector3.Zero);
	}

	[Test]
	public static void TestSetPosition()
	{
		let source = scope AudioSource();

		source.Position = .(10, 20, 30);
		Test.Assert(source.Position.X == 10);
		Test.Assert(source.Position.Y == 20);
		Test.Assert(source.Position.Z == 30);
	}

	[Test]
	public static void TestDefaultMinDistance()
	{
		let source = scope AudioSource();

		Test.Assert(source.MinDistance == 1.0f);
	}

	[Test]
	public static void TestSetMinDistance()
	{
		let source = scope AudioSource();

		source.MinDistance = 5.0f;
		Test.Assert(source.MinDistance == 5.0f);
	}

	[Test]
	public static void TestMinDistanceClampMin()
	{
		let source = scope AudioSource();

		source.MinDistance = 0.0f;
		Test.Assert(source.MinDistance >= 0.01f);
	}

	[Test]
	public static void TestDefaultMaxDistance()
	{
		let source = scope AudioSource();

		Test.Assert(source.MaxDistance == 100.0f);
	}

	[Test]
	public static void TestSetMaxDistance()
	{
		let source = scope AudioSource();

		source.MaxDistance = 200.0f;
		Test.Assert(source.MaxDistance == 200.0f);
	}

	[Test]
	public static void TestMaxDistanceClampToMinDistance()
	{
		let source = scope AudioSource();

		source.MinDistance = 10.0f;
		source.MaxDistance = 5.0f;  // Less than min
		Test.Assert(source.MaxDistance >= source.MinDistance);
	}

	[Test]
	public static void TestIsOneShotDefaultFalse()
	{
		let source = scope AudioSource();

		Test.Assert(source.IsOneShot == false);
	}

	[Test]
	public static void TestSetIsOneShot()
	{
		let source = scope AudioSource();

		source.IsOneShot = true;
		Test.Assert(source.IsOneShot == true);
	}

	[Test]
	public static void TestIsFinishedWhenStopped()
	{
		let source = scope AudioSource();

		// Source starts stopped, so IsFinished should be true
		Test.Assert(source.IsFinished == true);
	}
}
