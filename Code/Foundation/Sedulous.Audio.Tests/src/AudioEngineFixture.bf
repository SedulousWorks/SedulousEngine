using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Audio;

namespace Sedulous.Audio.Tests;

/// What every engine test is built out of: a tone, a clip carrying it, and a headless
/// engine to play it through.
///
/// A HEADLESS engine opens no device, so `Update` pumps the mixer itself and the whole
/// voice state machine runs deterministically here, in the cooker, and on a build machine
/// with no sound card.
static class AudioEngineFixture
{
	/// A sine at a plain amplitude, interleaved across the channels asked for.
	public static void MakeTone(float seconds, uint32 sampleRate, uint32 channels,
		List<int16> outSamples, float frequency = 440.0f, float amplitude = 0.5f)
	{
		let frameCount = (int)(seconds * (float)sampleRate);
		for (int frame = 0; frame < frameCount; frame++)
		{
			let t = (float)frame / (float)sampleRate;
			let value = amplitude * Sin(2.0f * 3.14159265f * frequency * t);
			let sample = (int16)(value * 32000.0f);
			for (uint32 channel = 0; channel < channels; channel++)
				outSamples.Add(sample);
		}
	}

	/// A clip whose encoded payload is a real wav, so the engine decodes and registers it
	/// exactly as it would a cooked one.
	///
	/// THE CALLER OWNS what comes back.
	public static AudioClip MakeToneClip(float seconds, uint32 sampleRate = 8000,
		uint32 channels = 1)
	{
		let samples = scope List<int16>();
		MakeTone(seconds, sampleRate, channels, samples);

		let clip = new AudioClip();
		if (!AudioCodec.EncodeWav(samples, channels, sampleRate, clip.EncodedData))
		{
			delete clip;
			return null;
		}
		if (!AudioCodec.Probe(clip.EncodedBytes, let metadata))
		{
			delete clip;
			return null;
		}

		clip.Channels = metadata.Channels;
		clip.SampleRate = metadata.SampleRate;
		clip.FrameCount = metadata.FrameCount;
		clip.DurationSeconds = metadata.DurationSeconds;
		return clip;
	}

	/// The default settings a test runs on: headless, a small pool so contention is
	/// reachable, and NO merge window, so two plays of one clip stay two voices unless the
	/// case is about merging.
	///
	/// A mixin, so what it hands back lives in the CALLER'S scope and needs no freeing there.
	public static mixin HeadlessSettings(uint32 voiceCount = 8, uint32 streamVoiceCount = 2,
		float dedupeWindowSeconds = 0.0f)
	{
		let settings = scope:mixin AudioEngineSettings();
		settings.Headless = true;
		settings.VoiceCount = voiceCount;
		settings.StreamVoiceCount = streamVoiceCount;
		settings.DedupeWindowSeconds = dedupeWindowSeconds;
		settings
	}

	public static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;
}
