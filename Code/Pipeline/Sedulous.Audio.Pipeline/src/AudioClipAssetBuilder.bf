using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Audio.Resource;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Audio.Pipeline;

/// Cooks an audio clip into its record plus the container bytes a runtime decodes.
///
/// A destructive option re-encodes, meaning decode, process, then write a wave container.
/// Everything else passes the ORIGINAL container through untouched, which keeps a compressed
/// source compressed.
class AudioClipAssetBuilder : IAssetBuilder
{
	/// The stream the container bytes travel in.
	public const String cDataStreamName = "data";

	/// The threshold a trailing silence trim measures against, about sixty decibels down.
	private const int16 cSilenceThreshold = 33;

	public Type AssetType => typeof(AudioClipAsset);
	public Type ProductType => typeof(AudioClipSource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		let clip = (AudioClipAsset)asset;
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let container = scope List<uint8>();
		if (AssetSource.ReadBytes(context, clip.FileName.Value, container) case .Err(let readError))
			return .Err(readError);

		// Validated here so an undecodable source fails the COOK rather than reaching a
		// runtime that can do nothing about it.
		if (!AudioCodec.Probe(container, var metadata))
		{
			GlobalLog(.Error, "Audio: '{}' is not decodable, so the cook failed",
				clip.FileName.Value);
			return .Err(.InvalidArgument);
		}

		let containerSuffix = scope String();
		ImportPaths.ExtensionLower(clip.FileName.Value, containerSuffix);

		if (clip.ForceMono || clip.TrimTrailingSilence || clip.Normalize)
		{
			if (ApplyTransforms(clip, container, ref metadata) case .Err(let transformError))
				return .Err(transformError);
			containerSuffix.Set("wav");
		}

		let cooked = scope AudioClipSource();
		cooked.Channels = metadata.Channels;
		cooked.SampleRate = metadata.SampleRate;
		cooked.FrameCount = metadata.FrameCount;
		cooked.DurationSeconds = metadata.DurationSeconds;
		cooked.Gain = clip.Gain;
		cooked.Loop = clip.Loop;
		cooked.LoopStartFrame = clip.LoopStartFrame;
		cooked.LoopEndFrame = clip.LoopEndFrame;
		cooked.Stream = clip.Stream;
		cooked.KeepCompressed = clip.KeepCompressed;
		cooked.ContainerExtension.Set(containerSuffix);

		if (context.Output.WriteObject(cooked) case .Err(let writeError))
			return .Err(writeError);
		return context.Output.WriteData(cDataStreamName, container);
	}

	/// Decodes, processes, and re-encodes as a wave container, replacing what was passed in.
	private static Result<void, ErrorCode> ApplyTransforms(AudioClipAsset asset,
		List<uint8> container, ref AudioClipMetadata metadata)
	{
		let samples = scope List<int16>();
		if (!AudioCodec.DecodeToPcm16(container, asset.ForceMono ? 1 : 0, samples, var decoded))
			return .Err(.InvalidArgument);

		if (asset.TrimTrailingSilence)
			TrimSilence(samples, ref decoded);

		if (asset.Normalize && !samples.IsEmpty)
			NormalizePeak(samples);

		let wav = scope List<uint8>();
		if (!AudioCodec.EncodeWav(samples, decoded.Channels, decoded.SampleRate, wav))
			return .Err(.InvalidArgument);

		container.Clear();
		container.AddRange(wav);
		metadata = decoded;
		return .Ok;
	}

	/// Drops the tail below the threshold, keeping ten milliseconds of pad so nothing clicks.
	private static void TrimSilence(List<int16> samples, ref AudioClipMetadata metadata)
	{
		if (metadata.Channels == 0)
			return;

		let frameCount = samples.Count / (int)metadata.Channels;
		var lastAudibleFrame = 0;
		for (int frame = frameCount; frame > 0; --frame)
		{
			var audible = false;
			for (uint32 channel < metadata.Channels)
			{
				let sample = samples[(frame - 1) * (int)metadata.Channels + (int)channel];
				if (Math.Abs((int)sample) > cSilenceThreshold)
				{
					audible = true;
					break;
				}
			}
			if (audible)
			{
				lastAudibleFrame = frame;
				break;
			}
		}

		let pad = (int)metadata.SampleRate / 100;
		var keepFrames = lastAudibleFrame + pad;
		if (keepFrames > frameCount)
			keepFrames = frameCount;

		samples.Count = keepFrames * (int)metadata.Channels;
		metadata.FrameCount = (uint64)keepFrames;
		metadata.DurationSeconds = (metadata.SampleRate > 0)
			? (float)((double)keepFrames / metadata.SampleRate) : 0.0f;
	}

	/// Scales so the loudest sample lands a decibel below full scale.
	private static void NormalizePeak(List<int16> samples)
	{
		var peak = 0;
		for (let sample in samples)
		{
			let magnitude = Math.Abs((int32)sample);
			if (magnitude > peak)
				peak = magnitude;
		}
		if (peak <= 0)
			return;

		let target = 0.891f * 32767.0f; // one decibel of headroom
		let scale = target / (float)peak;
		for (int i < samples.Count)
		{
			let scaled = Math.Clamp((float)samples[i] * scale, -32768.0f, 32767.0f);
			samples[i] = (int16)scaled;
		}
	}
}
