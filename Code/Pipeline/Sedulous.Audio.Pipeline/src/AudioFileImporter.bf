using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Audio.Pipeline;

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
		if (ImportPaths.CopyIntoSources(context, sourcePath, fileName) case .Err(let copyError))
			return .Err(copyError);

		let stem = ImportPaths.StemOf(fileName);
		let instance = group.CreateInstance(ImportPaths.SingleAssetName(options, stem), cAssetType);
		if (instance == null)
			return .Err(.Unknown);

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
