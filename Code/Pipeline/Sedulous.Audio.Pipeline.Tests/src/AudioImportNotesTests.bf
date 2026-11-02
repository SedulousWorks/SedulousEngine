using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Audio.Pipeline.Tests;

/// What each of the audio import's settings says it will do to the sound at hand, from the facts
/// its importer reads on a worker, or why it cannot apply.
class AudioImportNotesTests
{
	static void Note(AudioFileImporter importer, StringView path, ImportOptions options, Object prepared, StringView label,
		String outEffect, String outReason)
	{
		Test.Assert(options.FindSetting(label, let setting));
		importer.DescribeSetting(path, options, prepared, setting, outEffect, outReason);
	}

	[Test]
	public static void EachSettingSaysWhatItDoesToThisSoundOrWhyItCannotApply()
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
		let path = scope $"scratch_audio_import_notes.wav";
		defer DeleteFile(path);
		Test.Assert(WriteFile(path, wav) case .Ok);

		let importer = scope AudioFileImporter();
		Test.Assert(importer.WantsWorkerPrepare);
		let prepared = importer.PrepareOnWorker(path);
		Test.Assert(prepared != null);
		defer delete prepared;
		let options = importer.CreateOptions();
		defer delete options;

		let effect = scope String();
		let reason = scope String();
		Note(importer, path, options, prepared, "Force mono", effect, reason);
		Test.Assert(reason == "It is mono already");
		// The trim keeps the last audible frame (8000) and a 10 ms pad: it cuts 3920 of 12000 frames.
		effect.Clear(); reason.Clear();
		Note(importer, path, options, prepared, "Trim trailing silence", effect, reason);
		Test.Assert((effect == "Cuts 0.49 s from the end") && reason.IsEmpty);
		// Half scale up to -1 dBFS.
		effect.Clear(); reason.Clear();
		Note(importer, path, options, prepared, "Normalize", effect, reason);
		Test.Assert(effect == "+5.0 dB");
		// Short, small and with no loop points of its own: nothing to say.
		effect.Clear(); reason.Clear();
		Note(importer, path, options, prepared, "Stream", effect, reason);
		Test.Assert(effect.IsEmpty && reason.IsEmpty);
		Note(importer, path, options, prepared, "Loop", effect, reason);
		Test.Assert(effect.IsEmpty && reason.IsEmpty);
		// Without the facts (a headless import), nothing to say either.
		Note(importer, path, options, null, "Force mono", effect, reason);
		Test.Assert(reason.IsEmpty);
	}

	/// The trim and the normalize count by AudioEdits, so the note and the cook agree.
	[Test]
	public static void TheTrimKeepsTheLastAudibleFrameAndAPadAndThePeakIsTheLoudestMagnitude()
	{
		int16[8] mono = .(0, 2000, -3000, 10, 0, 0, 0, 0);
		Test.Assert(AudioEdits.AudibleFrames(.(&mono[0], 8), 1, 100) == 4, "the third sample is the last audible, then one frame of pad");
		Test.Assert(AudioEdits.Peak(.(&mono[0], 8)) == 3000);
		int16[4] silent = .(0, 0, 0, 0);
		Test.Assert(AudioEdits.AudibleFrames(.(&silent[0], 4), 2, 100) == 1, "all silent: the pad alone");
		Test.Assert(AudioEdits.Peak(.(&silent[0], 4)) == 0);
	}
}
