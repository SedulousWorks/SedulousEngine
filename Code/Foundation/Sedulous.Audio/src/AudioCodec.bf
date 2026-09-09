using System;
using System.Collections;
using Sedulous.Core;
using miniaudio_Beef;

namespace Sedulous.Audio;

/// Probing, decoding and encoding an audio container.
///
/// The seam the editor and the importer use: they never touch the backend themselves, so
/// there is one decoder in the build rather than one per tool.
static class AudioCodec
{
	/// How many samples a decode reads at a time. A frame is that over the channel count.
	private const int cChunkSamples = 4096;

	/// Probes an encoded container for its shape. False when the bytes are not audio it can
	/// read, rather than answering a shape of nothing.
	public static bool Probe(Span<uint8> encoded, out AudioClipMetadata outMetadata)
	{
		outMetadata = .();
		if (encoded.IsEmpty)
			return false;

		let decoder = mab_decoder_create_memory(encoded.Ptr, (uint)encoded.Length,
			(uint32)mab_format.S16, 0, 0);
		if (decoder == null)
			return false;
		defer mab_decoder_destroy(decoder);

		outMetadata.Channels = mab_decoder_get_channels(decoder);
		outMetadata.SampleRate = mab_decoder_get_sample_rate(decoder);

		uint64 frames = 0;
		if (mab_decoder_get_length_frames(decoder, &frames) == 0)
		{
			outMetadata.FrameCount = frames;
			outMetadata.DurationSeconds = (outMetadata.SampleRate > 0)
				? (float)((double)frames / outMetadata.SampleRate)
				: 0.0f;
		}

		return outMetadata.IsValid;
	}

	/// Decodes to interleaved sixteen bit samples.
	///
	/// A target of nought channels keeps the source's own; ONE downmixes to mono, which is the
	/// force to mono import path and what a spatial voice needs: a stereo source spatialises
	/// as two sources at one point, which images as nothing in particular.
	public static bool DecodeToPcm16(Span<uint8> encoded, uint32 targetChannels,
		List<int16> outSamples, out AudioClipMetadata outMetadata)
	{
		outMetadata = .();
		outSamples.Clear();
		if (encoded.IsEmpty)
			return false;

		let decoder = mab_decoder_create_memory(encoded.Ptr, (uint)encoded.Length,
			(uint32)mab_format.S16, targetChannels, 0);
		if (decoder == null)
			return false;
		defer mab_decoder_destroy(decoder);

		outMetadata.Channels = mab_decoder_get_channels(decoder);
		outMetadata.SampleRate = mab_decoder_get_sample_rate(decoder);
		if (outMetadata.Channels == 0)
			return false;

		let chunk = scope int16[cChunkSamples];
		let chunkFrames = (uint64)(cChunkSamples / (int)outMetadata.Channels);

		for (;;)
		{
			uint64 read = 0;
			let result = mab_decoder_read_pcm_frames(decoder, &chunk[0], chunkFrames, &read);

			for (uint64 i = 0; i < read * outMetadata.Channels; i++)
				outSamples.Add(chunk[(int)i]);
			outMetadata.FrameCount += read;

			if ((result != 0) || (read < chunkFrames))
				break;
		}

		outMetadata.DurationSeconds = (outMetadata.SampleRate > 0)
			? (float)((double)outMetadata.FrameCount / outMetadata.SampleRate)
			: 0.0f;
		return outMetadata.FrameCount > 0;
	}

	/// Decodes to interleaved floats, which is what the mixer holds a decoded clip as.
	public static bool DecodeToFloat(Span<uint8> encoded, uint32 targetChannels,
		List<float> outSamples, out uint32 outChannels, out uint64 outFrameCount)
	{
		outChannels = 0;
		outFrameCount = 0;
		outSamples.Clear();
		if (encoded.IsEmpty)
			return false;

		let decoder = mab_decoder_create_memory(encoded.Ptr, (uint)encoded.Length,
			(uint32)mab_format.F32, targetChannels, 0);
		if (decoder == null)
			return false;
		defer mab_decoder_destroy(decoder);

		outChannels = mab_decoder_get_channels(decoder);
		if (outChannels == 0)
			return false;

		let chunk = scope float[cChunkSamples];
		let chunkFrames = (uint64)(cChunkSamples / (int)outChannels);

		for (;;)
		{
			uint64 read = 0;
			let result = mab_decoder_read_pcm_frames(decoder, &chunk[0], chunkFrames, &read);

			for (uint64 i = 0; i < read * outChannels; i++)
				outSamples.Add(chunk[(int)i]);
			outFrameCount += read;

			if ((result != 0) || (read < chunkFrames))
				break;
		}

		return outFrameCount > 0;
	}

	/// Encodes interleaved sixteen bit samples as a WAV container.
	///
	/// A canonical header and the samples after it, with no encoder state at all: WAV is the
	/// one container written back, and the import transforms are lossless into it.
	public static bool EncodeWav(Span<int16> samples, uint32 channels, uint32 sampleRate,
		List<uint8> outBytes)
	{
		outBytes.Clear();
		if ((channels == 0) || (sampleRate == 0) || ((samples.Length % (int)channels) != 0))
			return false;

		let dataBytes = (uint32)(samples.Length * sizeof(int16));
		let byteRate = sampleRate * channels * (uint32)sizeof(int16);
		let blockAlign = (uint16)(channels * (uint32)sizeof(int16));

		void PushText(StringView text)
		{
			for (int i < text.Length)
				outBytes.Add((uint8)text[i]);
		}
		void PushU32(uint32 value)
		{
			outBytes.Add((uint8)(value & 0xFF));
			outBytes.Add((uint8)((value >> 8) & 0xFF));
			outBytes.Add((uint8)((value >> 16) & 0xFF));
			outBytes.Add((uint8)((value >> 24) & 0xFF));
		}
		void PushU16(uint16 value)
		{
			outBytes.Add((uint8)(value & 0xFF));
			outBytes.Add((uint8)((value >> 8) & 0xFF));
		}

		PushText("RIFF");
		PushU32(36 + dataBytes);
		PushText("WAVE");
		PushText("fmt ");
		PushU32(16);
		// Uncompressed.
		PushU16(1);
		PushU16((uint16)channels);
		PushU32(sampleRate);
		PushU32(byteRate);
		PushU16(blockAlign);
		PushU16(16);
		PushText("data");
		PushU32(dataBytes);

		let raw = (uint8*)samples.Ptr;
		for (int i < (int)dataBytes)
			outBytes.Add(raw[i]);

		return true;
	}

	/// Reduces an encoded container to per bucket PEAK magnitudes, which is the waveform an
	/// editor draws.
	///
	/// The peak rather than the average, because an average over a bucket of an oscillating
	/// signal is nothing at all and would draw a flat line.
	public static bool BuildWaveformPeaks(Span<uint8> encoded, uint32 buckets, List<float> outPeaks)
	{
		outPeaks.Clear();
		if (encoded.IsEmpty || (buckets == 0))
			return false;

		let decoder = mab_decoder_create_memory(encoded.Ptr, (uint)encoded.Length,
			(uint32)mab_format.F32, 0, 0);
		if (decoder == null)
			return false;
		defer mab_decoder_destroy(decoder);

		let channels = mab_decoder_get_channels(decoder);
		if (channels == 0)
			return false;

		// The total drives the frame to bucket mapping. Some containers cannot report it, and
		// those are collected first and bucketed once the total is known.
		uint64 totalFrames = 0;
		mab_decoder_get_length_frames(decoder, &totalFrames);

		outPeaks.Resize((int)buckets);
		for (int i < (int)buckets)
			outPeaks[i] = 0.0f;

		let chunk = scope float[cChunkSamples];
		let chunkFrames = (uint64)(cChunkSamples / (int)channels);
		uint64 cursor = 0;
		let unknownLength = scope List<float>();

		for (;;)
		{
			uint64 read = 0;
			let result = mab_decoder_read_pcm_frames(decoder, &chunk[0], chunkFrames, &read);

			for (uint64 frame = 0; frame < read; frame++)
			{
				var peak = 0.0f;
				for (uint32 c = 0; c < channels; c++)
				{
					let magnitude = Abs(chunk[(int)(frame * channels + c)]);
					if (magnitude > peak)
						peak = magnitude;
				}

				if (totalFrames > 0)
				{
					let bucket = (int)Min((cursor + frame) * buckets / totalFrames,
						(uint64)(buckets - 1));
					if (peak > outPeaks[bucket])
						outPeaks[bucket] = peak;
				}
				else
				{
					unknownLength.Add(peak);
				}
			}

			cursor += read;
			if ((result != 0) || (read < chunkFrames))
				break;
		}

		if (cursor == 0)
		{
			outPeaks.Clear();
			return false;
		}

		if (totalFrames == 0)
		{
			// Now the total IS known, so the collected peaks can be bucketed.
			let total = (uint64)unknownLength.Count;
			for (uint64 i = 0; i < total; i++)
			{
				let bucket = (int)Min(i * buckets / total, (uint64)(buckets - 1));
				if (unknownLength[(int)i] > outPeaks[bucket])
					outPeaks[bucket] = unknownLength[(int)i];
			}
		}

		for (int i < (int)buckets)
			outPeaks[i] = Min(outPeaks[i], 1.0f);

		return true;
	}
}
