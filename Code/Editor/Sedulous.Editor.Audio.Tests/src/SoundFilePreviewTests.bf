using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.Audio;

namespace Sedulous.Editor.Audio.Tests;

/// The import window's preview of a sound file: read off the main thread, then its waveform and its
/// facts (length, channels and rate, peak). Play needs an audio engine, which a test has none of,
/// and says so. A file that does not decode says that instead. The file's settings show on the
/// waveform: the trimmed tail shaded, the bars normalized, as each changes.
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

		let tasks = scope TaskPool(1);
		{
			let preview = scope SoundFilePreview(path, null, tasks, null);
			int changed = 0;
			preview.SetOnChanged(new [&changed] () => { changed++; });
			Test.Assert(!preview.HasSound, "still reading");
			Test.Assert(preview.Facts.IsEmpty);
			tasks.Finish();
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

		let missing = scope SoundFilePreview("scratch_sound_file_preview_missing.wav", null, tasks, null);
		tasks.Finish();
		Test.Assert(!missing.HasSound);
		Test.Assert(missing.Facts.IsEmpty);
	}

	[Test]
	public static void TheTrimShadesTheTailItCutsAndNormalizeScalesTheBarsAsTheSettingsChange()
	{
		// One second of mono 8 kHz at half scale, then half a second of silence.
		const uint32 cRate = 8000;
		let samples = scope List<int16>();
		for (uint32 i < cRate)
			samples.Add((int16)(((i % 8) < 4) ? 16384 : -16384));
		for (uint32 i < cRate / 2)
			samples.Add(0);
		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 1, cRate, wav));
		let path = scope $"scratch_sound_file_preview_settings.wav";
		defer DeleteFile(path);
		Test.Assert(WriteFile(path, wav) case .Ok);

		let options = scope AudioImportOptions();
		let tasks = scope TaskPool(1);
		let preview = scope SoundFilePreview(path, options, tasks, null);
		tasks.Finish();
		Test.Assert(preview.HasSound);
		// Off: the waveform as it is.
		Test.Assert(preview.Waveform.CutFrom == 1.0f);
		Test.Assert(preview.Waveform.Gain == 1.0f);
		// On: the trim keeps what the cook keeps of 12000 frames, and Normalize lifts half scale to -1 dBFS.
		options.TrimTrailingSilence = true;
		options.Normalize = true;
		preview.OnSettingsChanged();
		let kept = AudioEdits.AudibleFrames(samples, 1, cRate);
		Test.Assert((kept > 8000) && (kept < 12000), "the silence cut, the sound kept");
		Test.Assert(Math.Abs(preview.Waveform.CutFrom - (float)kept / 12000.0f) < 0.001f);
		Test.Assert(Math.Abs(preview.Waveform.Gain - 0.891f * 32767.0f / 16384.0f) < 0.001f);
		// Off again: as it is.
		options.Normalize = false;
		preview.OnSettingsChanged();
		Test.Assert(preview.Waveform.Gain == 1.0f);
		Test.Assert(preview.Waveform.CutFrom < 1.0f, "the trim still on");
		Test.Assert(!preview.AsImported);
		preview.SetAsImported(true);
		Test.Assert(preview.AsImported);
	}

	[Test]
	public static void APeakIsSaidInDecibelsAndSilenceAsSilent()
	{
		Test.Assert(SoundFilePreview.PeakText(1.0f, .. scope .()) == "Peak 0.0 dB");
		Test.Assert(SoundFilePreview.PeakText(0.5f, .. scope .()) == "Peak -6.0 dB");
		Test.Assert(SoundFilePreview.PeakText(0.0f, .. scope .()) == "Silent");
	}
}
