using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Audio.Tests;

/// The clip thumbnail and the audition's voice. (The pages' registrations are their own tests'; the
/// bus layout's rules are BusLayoutPageTests'.)
class AudioEditorTests
{
	private static int BarHeight(Image tile, int x)
	{
		let px = tile.PixelData;
		int rows = 0;
		for (int y < (int)tile.Height)
		{
			let p = (y * (int)tile.Width + x) * 4;
			if (px[p + 1] > 150) // the teal's green channel
				rows++;
		}
		return rows;
	}

	[Test]
	public static void TheThumbnailWaveformTracksTheClipsEnvelope()
	{
		const uint32 rate = 8000;
		let samples = scope List<int16>();
		samples.Resize(rate);
		for (uint32 i < rate)
		{
			let loud = (i >= rate / 3) && (i < (rate * 2) / 3);
			samples[i] = loud ? (((i % 8) < 4) ? (int16)28000 : (int16)-28000) : (int16)0;
		}
		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 1, rate, wav));
		let generator = scope AudioClipThumbnailGenerator();
		let tile = scope Image();
		Test.Assert(generator.Generate(wav, tile) case .Ok);
		Test.Assert(tile.Width == ThumbnailService.cThumbnailSize);
		Test.Assert(BarHeight(tile, 64) > 80); // the loud middle fills most of the strip
		Test.Assert(BarHeight(tile, 4) <= 4); // the silent edges keep only the survival midline
		Test.Assert(BarHeight(tile, 124) <= 4);

		let junk = scope uint8[16];
		Test.Assert(generator.Generate(junk, tile) case .Err);
	}

	/// A short tone whose payload is a real wav, decoded as a cooked clip would be. OWNED by the
	/// caller.
	private static AudioClip MakeToneClip(float seconds)
	{
		let samples = scope List<int16>();
		let frames = (int)(seconds * 8000.0f);
		for (int frame < frames)
			samples.Add((int16)(16000.0f * Math.Sin(2.0f * Math.PI_f * 440.0f * (float)frame / 8000.0f)));
		let clip = new AudioClip();
		if (!AudioCodec.EncodeWav(samples, 1, 8000, clip.EncodedData))
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

	/// The audition's voice: a paused audition is still the audition (the engine keeps the voice,
	/// and Play resumes it); only a finished or stopped voice ends it; none plays without an engine.
	[Test]
	public static void APausedAuditionIsStillTheAudition()
	{
		let settings = scope AudioEngineSettings();
		settings.Headless = true;
		let engine = scope AudioEngine(settings);
		let clip = MakeToneClip(0.25f);
		Test.Assert(clip != null);
		defer delete clip;

		let voice = scope AuditionVoice(engine);
		Test.Assert(voice.HasEngine);
		Test.Assert(voice.Start(clip, AudioPlayParams()));
		Test.Assert(voice.IsPlaying);
		float cursor = 0.0f;
		Test.Assert(voice.Poll(out cursor));

		voice.SetPaused(true);
		for (int i < 5)
			engine.Update(0.1f);
		Test.Assert(voice.Poll(out cursor), "paused: still the audition");
		Test.Assert(voice.IsPaused && voice.IsActive);

		voice.SetPaused(false);
		Test.Assert(voice.Poll(out cursor) && voice.IsPlaying);
		voice.SetVolume(0.5f);
		Test.Assert(Math.Abs(voice.Volume - 0.5f) < 1e-5f);

		// Played again: the last voice stopped first, one at a time.
		Test.Assert(voice.Start(clip, AudioPlayParams()));
		voice.Stop();
		for (int i < 5)
			engine.Update(0.1f);
		Test.Assert(!voice.Poll(out cursor));
		Test.Assert(!voice.IsActive);

		let none = scope AuditionVoice((Sedulous.Engine.Audio.AudioSubsystem)null);
		Test.Assert(!none.HasEngine);
		Test.Assert(!none.Start(clip, AudioPlayParams()));
	}
}
