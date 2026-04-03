using System;
using System.Collections;
using dr_libs_Beef;
using Sedulous.Audio;

namespace Sedulous.Audio.Decoders;

/// FLAC audio decoder using dr_flac.
/// Decodes FLAC files to 16-bit signed integer PCM.
class FlacDecoder : IAudioDecoder
{
	/// FLAC magic bytes: "fLaC"
	private static readonly uint8[4] FLAC_MAGIC = .(0x66, 0x4C, 0x61, 0x43);

	public StringView Name => "FLAC";

	public void GetSupportedExtensions(List<StringView> outExtensions)
	{
		outExtensions.Add(".flac");
	}

	public bool CanDecode(Span<uint8> header)
	{
		if (header.Length < 4)
			return false;

		// Check for FLAC magic bytes "fLaC"
		return header[0] == FLAC_MAGIC[0] &&
		       header[1] == FLAC_MAGIC[1] &&
		       header[2] == FLAC_MAGIC[2] &&
		       header[3] == FLAC_MAGIC[3];
	}

	public Result<AudioClip> Decode(Span<uint8> data)
	{
		if (data.IsEmpty)
			return .Err;

		uint32 channels = 0;
		uint32 sampleRate = 0;
		drflac_uint64 totalFrameCount = 0;

		// Decode FLAC to 16-bit PCM
		int16* samples = drflac_open_memory_and_read_pcm_frames_s16(
			data.Ptr,
			(.)data.Length,
			&channels,
			&sampleRate,
			&totalFrameCount,
			null
		);

		if (samples == null)
			return .Err;

		// Calculate data size
		int totalSamples = (int)(totalFrameCount * channels);
		int dataSize = totalSamples * sizeof(int16);

		// Copy data to our own buffer (dr_flac uses its own allocator)
		uint8* pcmData = new uint8[dataSize]*;
		Internal.MemCpy(pcmData, samples, dataSize);

		// Free dr_flac's buffer
		drflac_free(samples, null);

		// Create AudioClip
		return .Ok(new AudioClip(
			pcmData,
			dataSize,
			(int32)sampleRate,
			(int32)channels,
			.Int16,
			ownsData: true
		));
	}
}
