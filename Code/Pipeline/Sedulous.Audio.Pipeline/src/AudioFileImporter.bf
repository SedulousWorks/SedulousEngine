using System;
using System.Collections;
using System.Reflection;
using Sedulous.Audio;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Audio.Pipeline;

/// What the importer reads of a sound before it is imported (on a worker), so the import window
/// can say what each setting will do to it.
class AudioFileFacts
{
	public AudioClipMetadata Metadata = .();
	public int SizeBytes = 0;
	/// What the trim keeps.
	public int AudibleFrames = 0;
	/// The loudest sample's magnitude, of 32767.
	public int32 Peak = 0;
	/// A WAV's own loop points, which loop it whatever the setting.
	public bool LoopPoints = false;
}

/// Imports a dropped audio file.
class AudioFileImporter : IFileImporter
{
	private const String cAssetType = "Sedulous.Audio.Pipeline.AudioClipAsset";

	public StringView Label => "Audio";

	public bool Accepts(StringView @extension)
	{
		switch (@extension)
		{
		case "wav", "ogg", "mp3", "flac":
			return true;
		default:
			return false;
		}
	}

	public ImportOptions CreateOptions() => new AudioImportOptions();

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath, cAssetType, outPlan);

	public StringView AssetTypeName(StringView sourcePath) => cAssetType;

	/// Reads the sound's facts on a worker: what the settings' notes say (DescribeSetting). Import
	/// reads the file again; it needs none of this.
	public bool WantsWorkerPrepare => true;

	public Object PrepareOnWorker(StringView sourcePath)
	{
		let bytes = scope List<uint8>();
		if (ReadFile(sourcePath, bytes) case .Err)
			return null;
		let samples = scope List<int16>();
		let facts = new AudioFileFacts();
		if (!AudioCodec.DecodeToPcm16(bytes, 0, samples, out facts.Metadata))
		{
			delete facts;
			return null;
		}
		facts.SizeBytes = bytes.Count;
		facts.AudibleFrames = AudioEdits.AudibleFrames(samples, facts.Metadata.Channels, facts.Metadata.SampleRate);
		facts.Peak = AudioEdits.Peak(samples);
		let suffix = ImportPaths.ExtensionLower(sourcePath, .. scope .());
		facts.LoopPoints = (suffix == "wav") && AudioImportHeuristics.ParseWavSampleLoop(bytes, ?, ?);
		return facts;
	}

	/// What each setting does to this sound, from its facts: Stream and Loop when the sound does it
	/// anyway, Force mono on a mono sound, how much the trim cuts, how far Normalize moves its peak.
	public void DescribeSetting(StringView sourcePath, ImportOptions options, Object prepared, FieldInfo setting,
		String outEffect, String outReason)
	{
		let facts = prepared as AudioFileFacts;
		if (facts == null)
			return;
		let metadata = facts.Metadata;
		switch (setting.Name)
		{
		case "Stream":
			if (AudioImportHeuristics.ShouldStreamByDefault(metadata.DurationSeconds, facts.SizeBytes))
				outReason.Append("It streams anyway: it is over 10 s or 2 MB");
		case "ForceMono":
			if (metadata.Channels == 1)
				outReason.Append("It is mono already");
		case "Loop":
			if (facts.LoopPoints)
				outReason.Append("It loops anyway, by its own loop points");
		case "TrimTrailingSilence":
			let cut = (metadata.FrameCount > (uint64)facts.AudibleFrames) ? (int)metadata.FrameCount - facts.AudibleFrames : 0;
			if ((cut == 0) || (metadata.SampleRate == 0))
				outReason.Append("It has no silent tail");
			else
				outEffect.AppendF("Cuts {:F2} s from the end", (double)cut / metadata.SampleRate);
		case "Normalize":
			if (facts.Peak == 0)
				outReason.Append("It is silent");
			else
			{
				let gain = 20.0f * Math.Log10(AudioEdits.cNormalizeTarget / (float)facts.Peak);
				if (gain >= 0.0f)
					outEffect.Append("+");
				outEffect.AppendF("{:F1} dB", gain);
			}
		default:
		}
	}

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let bytes = scope List<uint8>();
		if (ReadFile(sourcePath, bytes) case .Err(let readError))
			return .Err(readError);

		// Probed BEFORE anything is copied, so an undecodable file is refused rather than
		// staged into the project and left to fail at cook.
		if (!AudioCodec.Probe(bytes, let metadata))
		{
			GlobalLog(.Error, "Audio: '{}' is not decodable, so the import was refused", sourcePath);
			return .Err(.InvalidArgument);
		}

		let fileName = scope String();
		// The name claimed by the clash rule, the file copied in beside any other's.
		let claimed = ImportPaths.ClaimSingleAsset(context, group, options, sourcePath, cAssetType, fileName);
		if (claimed case .Err(let claimError))
			return .Err(claimError);
		let instance = claimed.Value;

		let audioOptions = options as AudioImportOptions;
		let asset = scope AudioClipAsset();
		asset.FileName.Set(fileName);
		asset.Stream = ((audioOptions != null) && audioOptions.Stream)
			|| AudioImportHeuristics.ShouldStreamByDefault(metadata.DurationSeconds, bytes.Count);
		if (audioOptions != null)
		{
			asset.ForceMono = audioOptions.ForceMono;
			asset.Loop = audioOptions.Loop;
			asset.TrimTrailingSilence = audioOptions.TrimTrailingSilence;
			asset.Normalize = audioOptions.Normalize;
		}

		// An AUTHORED loop wins over the checkbox: the author already said where it loops in
		// whatever editor wrote the file.
		let suffix = scope String();
		ImportPaths.ExtensionLower(sourcePath, suffix);
		if ((suffix == "wav")
			&& AudioImportHeuristics.ParseWavSampleLoop(bytes, let loopStart, let loopEnd))
		{
			asset.Loop = true;
			asset.LoopStartFrame = loopStart;
			asset.LoopEndFrame = loopEnd;
		}

		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
