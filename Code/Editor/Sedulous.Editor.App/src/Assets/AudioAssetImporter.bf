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

/// Imports audio files (.wav, .ogg, .mp3, .flac) as AudioClipResource.
/// The source audio file is decoded to PCM and stored as a text metadata file
/// plus a binary PCM sidecar -- AudioClipResourceManager handles loading both.
class AudioAssetImporter : IAssetImporter
{
	private AudioDecoderFactory mDecoder;

	public this(AudioDecoderFactory decoder)
	{
		mDecoder = decoder;
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
		if (mDecoder == null) return .Err;

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

		return .Err;
	}

	public Result<void> Import(ImportPreview preview, AssetImportContext ctx)
	{
		if (preview.Items.Count == 0 || !preview.Items[0].Selected)
			return .Ok;

		if (mDecoder == null) return .Err;

		// Decode the audio file to PCM
		AudioClip clip;
		if (mDecoder.DecodeFile(preview.SourcePath) case .Ok(let c))
			clip = c;
		else
			return .Err;

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
				return .Err;
			memStream.Position = 0;
			if (ctx.Mount.Save(locator, memStream) case .Err)
				return .Err;
		}

		// Save PCM sidecar
		{
			let pcmStream = scope MemoryStream();
			if (resource.WritePcmToStream(pcmStream) case .Err)
				return .Err;
			pcmStream.Position = 0;
			if (ctx.Mount.Save(sidecarLocator, pcmStream) case .Err)
				return .Err;
		}

		ctx.Index.Register(resource.Id, uri);

		return .Ok;
	}
}
