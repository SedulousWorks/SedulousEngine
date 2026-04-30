namespace Sedulous.Audio.Tests;

using System;
using Sedulous.Audio;
using Sedulous.Audio.Graph;

class SourceNodeTests
{
	/// Creates a mono Int16 AudioClip with a simple ramp pattern for testing.
	/// Samples go: 0, 1000, 2000, 3000, ... (as int16 values)
	static AudioClip MakeTestClip(int32 frames, int32 sampleRate = 48000)
	{
		let samples = new int16[frames]*;
		for (int32 i = 0; i < frames; i++)
			samples[i] = (int16)(i * 1000);

		let clip = AudioClip.FromInt16(Span<int16>(samples, frames), sampleRate, 1);
		delete samples;
		return clip;
	}

	/// Creates a stereo Int16 AudioClip. L channel = i*1000, R channel = -(i*1000).
	static AudioClip MakeStereoTestClip(int32 frames, int32 sampleRate = 48000)
	{
		let samples = new int16[frames * 2]*;
		for (int32 i = 0; i < frames; i++)
		{
			samples[i * 2] = (int16)(i * 1000);
			samples[i * 2 + 1] = (int16)(-(i * 1000));
		}

		let clip = AudioClip.FromInt16(Span<int16>(samples, frames * 2), sampleRate, 2);
		delete samples;
		return clip;
	}

	[Test]
	public static void Play_RendersCorrectSamples()
	{
		let clip = MakeTestClip(8);
		defer delete clip;

		let node = scope SourceNode();
		node.Clip = clip;
		node.Play();

		let buf = scope float[8]*; // 4 frames stereo
		node.GetOutputSamples(buf, 4, 48000, 1);

		// Frame 0: mono 0 -> L=0, R=0
		Test.Assert(buf[0] == 0.0f);
		Test.Assert(buf[1] == 0.0f);

		// Frame 1: mono 1000/32768 -> both channels
		let expected1 = 1000.0f / 32768.0f;
		Test.Assert(Math.Abs(buf[2] - expected1) < 0.001f);
		Test.Assert(Math.Abs(buf[3] - expected1) < 0.001f);
	}

	[Test]
	public static void Play_StereoClip_PreservesChannels()
	{
		let clip = MakeStereoTestClip(8);
		defer delete clip;

		let node = scope SourceNode();
		node.Clip = clip;
		node.Play();

		let buf = scope float[8]*; // 4 frames stereo
		node.GetOutputSamples(buf, 4, 48000, 1);

		// Frame 1: L = 1000/32768, R = -1000/32768
		let expectedL = 1000.0f / 32768.0f;
		let expectedR = -1000.0f / 32768.0f;
		Test.Assert(Math.Abs(buf[2] - expectedL) < 0.001f);
		Test.Assert(Math.Abs(buf[3] - expectedR) < 0.001f);
	}

	[Test]
	public static void Play_AdvancesPosition()
	{
		let clip = MakeTestClip(16);
		defer delete clip;

		let node = scope SourceNode();
		node.Clip = clip;
		node.Play();

		let buf = scope float[8]*;
		node.GetOutputSamples(buf, 4, 48000, 1);

		Test.Assert(node.PlaybackPosition == 4);

		node.GetOutputSamples(buf, 4, 48000, 2);
		Test.Assert(node.PlaybackPosition == 8);
	}

	[Test]
	public static void Play_ReachesEnd_MarksFinished()
	{
		let clip = MakeTestClip(4);
		defer delete clip;

		let node = scope SourceNode();
		node.Clip = clip;
		node.Play();

		let buf = scope float[8]*;
		node.GetOutputSamples(buf, 4, 48000, 1);

		// Played all 4 frames, should request more on next call
		let buf2 = scope float[8]*;
		node.GetOutputSamples(buf2, 4, 48000, 2);

		Test.Assert(node.IsFinished);
		Test.Assert(!node.IsPlaying);
	}

	[Test]
	public static void Loop_WrapsAround()
	{
		let clip = MakeTestClip(4);
		defer delete clip;

		let node = scope SourceNode();
		node.Clip = clip;
		node.Loop = true;
		node.Play();

		let buf = scope float[16]*; // 8 frames stereo
		node.GetOutputSamples(buf, 8, 48000, 1);

		// Should have looped - frame 4 should match frame 0 (value 0)
		Test.Assert(!node.IsFinished);
		Test.Assert(node.IsPlaying);
		// Frame 4 (index 8,9) should be same as frame 0 (value 0)
		Test.Assert(buf[8] == 0.0f);
		Test.Assert(buf[9] == 0.0f);
	}

	[Test]
	public static void Volume_ScalesSamples()
	{
		let clip = MakeTestClip(4);
		defer delete clip;

		let node = scope SourceNode();
		node.Clip = clip;
		node.Volume = 0.5f;
		node.Play();

		let buf = scope float[8]*;
		node.GetOutputSamples(buf, 4, 48000, 1);

		// Frame 1: mono 1000/32768 * 0.5
		let expected = (1000.0f / 32768.0f) * 0.5f;
		Test.Assert(Math.Abs(buf[2] - expected) < 0.001f);
	}

	[Test]
	public static void Stop_ReturnsToBeginning()
	{
		let clip = MakeTestClip(8);
		defer delete clip;

		let node = scope SourceNode();
		node.Clip = clip;
		node.Play();

		let buf = scope float[8]*;
		node.GetOutputSamples(buf, 4, 48000, 1);
		Test.Assert(node.PlaybackPosition == 4);

		node.Stop();
		Test.Assert(node.PlaybackPosition == 0);
		Test.Assert(!node.IsPlaying);
	}

	[Test]
	public static void NoClip_ProducesSilence()
	{
		let node = scope SourceNode();
		node.Play();

		let buf = scope float[8]*;
		for (int i = 0; i < 8; i++) buf[i] = 999.0f;

		node.GetOutputSamples(buf, 4, 48000, 1);

		for (int i = 0; i < 8; i++)
			Test.Assert(buf[i] == 0.0f);
	}

	[Test]
	public static void NotPlaying_ProducesSilence()
	{
		let clip = MakeTestClip(8);
		defer delete clip;

		let node = scope SourceNode();
		node.Clip = clip;
		// Don't call Play()

		let buf = scope float[8]*;
		for (int i = 0; i < 8; i++) buf[i] = 999.0f;

		node.GetOutputSamples(buf, 4, 48000, 1);

		for (int i = 0; i < 8; i++)
			Test.Assert(buf[i] == 0.0f);
	}

	[Test]
	public static void Seek_SetsPosition()
	{
		let clip = MakeTestClip(16);
		defer delete clip;

		let node = scope SourceNode();
		node.Clip = clip;
		node.Play();
		node.Seek(8);

		Test.Assert(node.PlaybackPosition == 8);
	}
}
