namespace Sedulous.Editor.App;

using System;
using System.IO;
using System.Collections;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Audio;
using Sedulous.Audio.Decoders;
using Sedulous.Audio.Resources;
using Sedulous.VFS;
using Sedulous.Core.Logging.Abstractions;

/// Imports audio files (.wav, .ogg, .mp3, .flac) as AudioClipResource.
/// The source audio file is decoded to PCM and stored as a text metadata file
/// plus a binary PCM sidecar -- AudioClipResourceManager handles loading both.
class AudioAssetImporter : IAssetImporter
{
	private AudioDecoderFactory mDecoder;
	private ILogger mLogger;

	public this(AudioDecoderFactory decoder, ILogger logger = null)
	{
		mDecoder = decoder;
		mLogger = logger;
	}

	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".wav"));
		outExtensions.Add(new .(".ogg"));
		outExtensions.Add(new .(".mp3"));
		outExtensions.Add(new .(".flac"));
	}

	public Result<ImportPreview> CreatePreview(StringView sourcePath)
	{
		if (mDecoder == null)
		{
			mLogger?.LogError("Audio import preview: no decoder available for {}", sourcePath);
			return .Err;
		}

		// Decode to verify validity and get metadata
		if (mDecoder.DecodeFile(sourcePath) case .Ok(let clip))
		{
			defer delete clip;

			let preview = new ImportPreview();
			preview.SourcePath = new String(sourcePath);

			let fileName = scope String();
			Path.GetFileNameWithoutExtension(sourcePath, fileName);

			let durationStr = scope String();
			let duration = clip.Duration;
			if (duration >= 60)
				durationStr.AppendF("{0}:{1:00.0}", (int)(duration / 60), duration % 60);
			else
				durationStr.AppendF("{0:F1}s", duration);

			let item = new ImportPreviewItem();
			item.Name = new String(fileName);
			item.Extension = new String(".audioclip");
			item.TypeLabel = new String(scope $"Audio ({clip.SampleRate}Hz, {clip.Channels}ch, {durationStr})");
			item.InternalIndex = 0;
			preview.Items.Add(item);

			return .Ok(preview);
		}

		mLogger?.LogError("Audio import preview: decode failed for {}", sourcePath);
		return .Err;
	}

	public Result<void> Import(ImportPreview preview, AssetImportContext ctx)
	{
		if (preview.Items.Count == 0 || !preview.Items[0].Selected)
			return .Ok;

		if (mDecoder == null)
		{
			mLogger?.LogError("Audio import: no decoder available for {}", preview.SourcePath);
			return .Err;
		}

		mLogger?.LogInformation("Audio import: {} -> {}{}", preview.SourcePath, ctx.UriPrefix, preview.Items[0].Name);

		// Decode the audio file to PCM
		AudioClip clip;
		if (mDecoder.DecodeFile(preview.SourcePath) case .Ok(let c))
			clip = c;
		else
		{
			mLogger?.LogError("Audio import: decode failed for {}", preview.SourcePath);
			return .Err;
		}

		// Create resource with decoded PCM data
		let resource = new AudioClipResource();
		resource.Clip = clip;
		resource.Name.Set(preview.Items[0].Name);
		resource.SourcePath.Set(preview.SourcePath);
		defer delete resource;

		// Build filename, locator, sidecar locator, and URI
		let fileName = scope String();
		fileName.AppendF("{}.audioclip", preview.Items[0].Name);

		let sidecarName = scope String();
		sidecarName.AppendF("{}.bin", fileName);

		let locator = scope String();
		locator.Append(ctx.BaseLocator);
		locator.Append(fileName);

		let sidecarLocator = scope String();
		sidecarLocator.Append(ctx.BaseLocator);
		sidecarLocator.Append(sidecarName);

		let uri = scope String();
		uri.Append(ctx.UriPrefix);
		uri.Append(fileName);


		// Save text metadata
		{
			let memStream = scope MemoryStream();
			if (resource.WriteToStream(memStream, ctx.Serializer) case .Err)
			{
				mLogger?.LogError("Audio import: metadata serialization failed for {}", locator);
				return .Err;
			}
			memStream.Position = 0;
			if (ctx.Mount.Save(locator, memStream) case .Err(let err))
			{
				mLogger?.LogError("Audio import: mount save failed for {}: {}", locator, err);
				return .Err;
			}
		}

		// Save PCM sidecar
		{
			let pcmStream = scope MemoryStream();
			if (resource.WritePcmToStream(pcmStream) case .Err)
			{
				mLogger?.LogError("Audio import: PCM sidecar serialization failed for {}", sidecarLocator);
				return .Err;
			}
			pcmStream.Position = 0;
			if (ctx.Mount.Save(sidecarLocator, pcmStream) case .Err(let err))
			{
				mLogger?.LogError("Audio import: PCM sidecar save failed for {}: {}", sidecarLocator, err);
				return .Err;
			}
		}

		ctx.Index.Register(resource.Id, uri);

		mLogger?.LogInformation("Audio import: wrote {} ({} frames, {} bytes PCM)",
			uri, clip.FrameCount, clip.DataLength);
		return .Ok;
	}
}
