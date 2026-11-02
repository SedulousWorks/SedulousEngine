using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Audio;
using Sedulous.Editor.Core;
using Sedulous.Editor.Audio;

namespace Sedulous.Editor.Audio.Tests;

/// The import window's preview of a sound file: read off the main thread, then its waveform and its
/// facts (length, channels and rate, peak). Play needs an audio engine, which a test has none of,
/// and says so. A file that does not decode says that instead.
class SoundFilePreviewTests
{
	[Test]
	public static void ReadOffTheMainThreadThenTheWaveformWithItsLengthChannelsAndRateAndPeak()
	{
		// One second of mono 8 kHz at half scale: a peak of -6.0 dB.
		const uint32 cRate = 8000;
		let samples = scope List<int16>();
		for (uint32 i < cRate)
			samples.Add((int16)(((i % 8) < 4) ? 16384 : -16384));
		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 1, cRate, wav));
		let path = scope $"scratch_sound_file_preview.wav";
		defer DeleteFile(path);
		Test.Assert(WriteFile(path, wav) case .Ok);

		let reader = scope ImportPreviewReader();
		{
			let preview = scope SoundFilePreview(path, reader, null);
			int changed = 0;
			preview.SetOnChanged(new [&changed] () => { changed++; });
			Test.Assert(!preview.HasSound, "still reading");
			Test.Assert(preview.Facts.IsEmpty);
			reader.Finish();
			Test.Assert(changed == 1);
			Test.Assert(preview.HasSound);
			Test.Assert(!preview.Waveform.Peaks.IsEmpty);
			let facts = preview.Facts;
			Test.Assert(facts.Length == 3);
			Test.Assert(facts[0] == "1.00 s");
			Test.Assert(facts[1] == "Mono, 8000 Hz");
			Test.Assert(facts[2] == "Peak -6.0 dB");

			// No engine here: Play says so and nothing follows.
			Test.Assert(!preview.Play());
			Test.Assert(preview.State == "No audio engine");
			preview.Stop();
			Test.Assert(preview.State == "Stopped");
			Test.Assert(preview.Waveform.Playhead < 0.0f);
		}

		let missing = scope SoundFilePreview("scratch_sound_file_preview_missing.wav", reader, null);
		reader.Finish();
		Test.Assert(!missing.HasSound);
		Test.Assert(missing.Facts.IsEmpty);
	}

	[Test]
	public static void APeakIsSaidInDecibelsAndSilenceAsSilent()
	{
		Test.Assert(SoundFilePreview.PeakText(1.0f, .. scope .()) == "Peak 0.0 dB");
		Test.Assert(SoundFilePreview.PeakText(0.5f, .. scope .()) == "Peak -6.0 dB");
		Test.Assert(SoundFilePreview.PeakText(0.0f, .. scope .()) == "Silent");
	}
}
