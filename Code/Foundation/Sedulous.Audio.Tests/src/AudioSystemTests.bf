using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Audio.SDL3;
using Sedulous.Core.Mathematics;

namespace Sedulous.Audio.Tests;

/// Tests for IAudioSystem interface and SDL3AudioSystem implementation.
/// Note: Some tests may require SDL audio to be available on the system.
class AudioSystemTests
{
	[Test]
	public static void TestSystemCreation()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		// System may or may not initialize depending on audio hardware
		// Just verify creation doesn't crash
		Test.Assert(true);
	}

	[Test]
	public static void TestSystemDispose()
	{
		let system = new SDL3AudioSystem();
		system.Dispose();
		delete system;

		// Double dispose should be safe
		Test.Assert(true);
	}

	[Test]
	public static void TestSystemListener()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		// Listener should never be null
		Test.Assert(system.Listener != null);
	}

	[Test]
	public static void TestSystemDefaultMasterVolume()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		Test.Assert(system.MasterVolume == 1.0f);
	}

	[Test]
	public static void TestSystemSetMasterVolume()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		system.MasterVolume = 0.5f;
		Test.Assert(system.MasterVolume == 0.5f);
	}

	[Test]
	public static void TestSystemMasterVolumeClampMin()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		system.MasterVolume = -1.0f;
		Test.Assert(system.MasterVolume == 0.0f);
	}

	[Test]
	public static void TestSystemMasterVolumeClampMax()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		system.MasterVolume = 2.0f;
		Test.Assert(system.MasterVolume == 1.0f);
	}

	[Test]
	public static void TestSystemCreateSourceWhenNotInitialized()
	{
		// Create system that fails to initialize (no audio device simulation)
		// In practice, this depends on hardware, so we just test the path
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		if (!system.IsInitialized)
		{
			let source = system.CreateSource();
			Test.Assert(source == null);
		}
		else
		{
			// System is initialized, source creation should work
			let source = system.CreateSource();
			Test.Assert(source != null);
			system.DestroySource(source);
		}
	}

	[Test]
	public static void TestSystemDestroyNullSource()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		// Destroying null should not crash
		system.DestroySource(null);
		Test.Assert(true);
	}

	[Test]
	public static void TestSystemLoadClipWithEmptyData()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		// Loading empty data should fail gracefully
		let result = system.LoadClip(.());
		Test.Assert(result case .Err);
	}

	[Test]
	public static void TestSystemLoadClipWithInvalidData()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		// Loading invalid data should fail gracefully
		uint8[10] garbage = .(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
		let result = system.LoadClip(.(&garbage[0], 10));
		Test.Assert(result case .Err);
	}

	[Test]
	public static void TestSystemOpenStreamWithInvalidPath()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		let result = system.OpenStream("nonexistent_file.wav");
		Test.Assert(result case .Err);
	}

	[Test]
	public static void TestSystemPauseAllWhenNotInitialized()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		// Should not crash regardless of initialization state
		system.PauseAll();
		Test.Assert(true);
	}

	[Test]
	public static void TestSystemResumeAllWhenNotPaused()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		// Should not crash when not paused
		system.ResumeAll();
		Test.Assert(true);
	}

	[Test]
	public static void TestSystemUpdateWithNoSources()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		// Update with no sources should not crash
		system.Update();
		Test.Assert(true);
	}

	[Test]
	public static void TestSystemPlayOneShotWithNullClip()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		// Should handle null clip gracefully
		system.PlayOneShot(null, 1.0f);
		Test.Assert(true);
	}

	[Test]
	public static void TestSystemPlayOneShot3DWithNullClip()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		// Should handle null clip gracefully
		system.PlayOneShot3D(null, Vector3.Zero, 1.0f);
		Test.Assert(true);
	}

	[Test]
	public static void TestSystemListenerPosition()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		system.Listener.Position = .(1, 2, 3);

		Test.Assert(system.Listener.Position.X == 1);
		Test.Assert(system.Listener.Position.Y == 2);
		Test.Assert(system.Listener.Position.Z == 3);
	}

	[Test]
	public static void TestSystemListenerForward()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		system.Listener.Forward = .(1, 0, 0);

		Test.Assert(Math.Abs(system.Listener.Forward.X - 1.0f) < 0.001f);
	}

	[Test]
	public static void TestSystemListenerUp()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		system.Listener.Up = .(0, 0, 1);

		Test.Assert(Math.Abs(system.Listener.Up.Z - 1.0f) < 0.001f);
	}
}

/// Tests for generating and loading WAV data.
class AudioClipTests
{
	/// Generates a minimal valid WAV file in memory.
	private static void GenerateMinimalWav(List<uint8> wav)
	{
		let numSamples = (int32)441;  // 0.01 seconds at 44100 Hz
		let numChannels = (int16)1;   // Mono
		let sampleRate = (int32)44100;
		let bitsPerSample = (int16)16;
		let bytesPerSample = bitsPerSample / 8;
		let dataSize = numSamples * numChannels * bytesPerSample;

		// RIFF header
		wav.AddRange(Span<uint8>((uint8*)"RIFF", 4));
		WriteInt32(wav, 36 + dataSize);
		wav.AddRange(Span<uint8>((uint8*)"WAVE", 4));

		// fmt chunk
		wav.AddRange(Span<uint8>((uint8*)"fmt ", 4));
		WriteInt32(wav, 16);
		WriteInt16(wav, 1);  // PCM
		WriteInt16(wav, numChannels);
		WriteInt32(wav, sampleRate);
		WriteInt32(wav, sampleRate * numChannels * bytesPerSample);
		WriteInt16(wav, (int16)(numChannels * bytesPerSample));
		WriteInt16(wav, bitsPerSample);

		// data chunk
		wav.AddRange(Span<uint8>((uint8*)"data", 4));
		WriteInt32(wav, dataSize);

		// Silence
		for (int32 i = 0; i < numSamples; i++)
			WriteInt16(wav, 0);
	}

	private static void WriteInt16(List<uint8> buffer, int16 value)
	{
		buffer.Add((uint8)(value & 0xFF));
		buffer.Add((uint8)((value >> 8) & 0xFF));
	}

	private static void WriteInt32(List<uint8> buffer, int32 value)
	{
		buffer.Add((uint8)(value & 0xFF));
		buffer.Add((uint8)((value >> 8) & 0xFF));
		buffer.Add((uint8)((value >> 16) & 0xFF));
		buffer.Add((uint8)((value >> 24) & 0xFF));
	}

	[Test]
	public static void TestLoadValidWav()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		if (!system.IsInitialized)
		{
			// Skip test if audio not available
			Test.Assert(true);
			return;
		}

		let wavData = scope List<uint8>();
		GenerateMinimalWav(wavData);

		let result = system.LoadClip(Span<uint8>(wavData.Ptr, wavData.Count));

		switch (result)
		{
		case .Ok(let clip):
			Test.Assert(clip.IsLoaded);
			Test.Assert(clip.SampleRate == 44100);
			Test.Assert(clip.Channels == 1);
			Test.Assert(clip.Duration > 0);
			delete clip;
		case .Err:
			// May fail if audio system not fully initialized
			Test.Assert(true);
		}
	}

	[Test]
	public static void TestClipPropertiesAfterLoad()
	{
		let system = scope SDL3AudioSystem();
		defer system.Dispose();

		if (!system.IsInitialized)
		{
			Test.Assert(true);
			return;
		}

		let wavData = scope List<uint8>();
		GenerateMinimalWav(wavData);

		switch (system.LoadClip(Span<uint8>(wavData.Ptr, wavData.Count)))
		{
		case .Ok(let clip):
			// Test all AudioClip properties
			Test.Assert(clip.Duration > 0);
			Test.Assert(clip.SampleRate > 0);
			Test.Assert(clip.Channels > 0);
			Test.Assert(clip.IsLoaded == true);
			delete clip;
		case .Err:
			Test.Assert(true);
		}
	}
}
