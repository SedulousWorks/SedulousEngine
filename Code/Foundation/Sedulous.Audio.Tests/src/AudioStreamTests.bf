using System;
using Sedulous.Audio;
using Sedulous.Audio.SDL3;

namespace Sedulous.Audio.Tests;

/// Tests for IAudioStream interface and SDL3AudioStream implementation.
class AudioStreamTests
{
	// Note: SDL3AudioStream requires a valid audio device and file,
	// so these tests focus on behavior with invalid inputs (graceful failure).

	[Test]
	public static void TestStreamWithInvalidDevice()
	{
		// Creating a stream with invalid device ID (0) should fail gracefully
		let stream = scope SDL3AudioStream(0, "nonexistent.wav");

		Test.Assert(stream.IsReady == false);
	}

	[Test]
	public static void TestStreamWithNonexistentFile()
	{
		// Even with a potentially valid device, nonexistent file should fail
		let stream = scope SDL3AudioStream(0, "this_file_does_not_exist.wav");

		Test.Assert(stream.IsReady == false);
	}

	[Test]
	public static void TestStreamDefaultState()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// Invalid stream should be stopped
		Test.Assert(stream.State == .Stopped);
	}

	[Test]
	public static void TestStreamDefaultVolume()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		Test.Assert(stream.Volume == 1.0f);
	}

	[Test]
	public static void TestStreamSetVolume()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		stream.Volume = 0.5f;
		Test.Assert(stream.Volume == 0.5f);
	}

	[Test]
	public static void TestStreamVolumeClampMin()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		stream.Volume = -1.0f;
		Test.Assert(stream.Volume == 0.0f);
	}

	[Test]
	public static void TestStreamVolumeClampMax()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		stream.Volume = 2.0f;
		Test.Assert(stream.Volume == 1.0f);
	}

	[Test]
	public static void TestStreamDefaultLoop()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		Test.Assert(stream.Loop == false);
	}

	[Test]
	public static void TestStreamSetLoop()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		stream.Loop = true;
		Test.Assert(stream.Loop == true);
	}

	[Test]
	public static void TestStreamPlayWhenNotReady()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// Play should not crash when stream is not ready
		stream.Play();
		Test.Assert(stream.State == .Stopped);
	}

	[Test]
	public static void TestStreamPauseWhenNotPlaying()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// Pause should not crash when not playing
		stream.Pause();
		Test.Assert(stream.State == .Stopped);
	}

	[Test]
	public static void TestStreamResumeWhenNotPaused()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// Resume should not crash when not paused
		stream.Resume();
		Test.Assert(stream.State == .Stopped);
	}

	[Test]
	public static void TestStreamStopWhenNotPlaying()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// Stop should not crash when not playing
		stream.Stop();
		Test.Assert(stream.State == .Stopped);
	}

	[Test]
	public static void TestStreamSeekWhenNotReady()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// Seek should not crash when stream is not ready
		stream.Seek(0.5f);
		Test.Assert(stream.Position == 0.0f);
	}

	[Test]
	public static void TestStreamDurationWhenNotReady()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// Duration should be 0 when not ready
		Test.Assert(stream.Duration == 0.0f);
	}

	[Test]
	public static void TestStreamSampleRateWhenNotReady()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// SampleRate should be 0 when not ready
		Test.Assert(stream.SampleRate == 0);
	}

	[Test]
	public static void TestStreamChannelsWhenNotReady()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// Channels should be 0 when not ready
		Test.Assert(stream.Channels == 0);
	}

	[Test]
	public static void TestStreamUpdateWhenNotReady()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// Update should not crash when stream is not ready
		stream.Update();
		Test.Assert(true);
	}

	[Test]
	public static void TestStreamSetMasterVolume()
	{
		let stream = scope SDL3AudioStream(0, "test.wav");

		// SetMasterVolume should not crash
		stream.SetMasterVolume(0.5f);
		Test.Assert(true);
	}
}
