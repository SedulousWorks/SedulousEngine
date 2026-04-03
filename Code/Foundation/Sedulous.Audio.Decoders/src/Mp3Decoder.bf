using System;
using System.Collections;
using dr_libs_Beef;
using Sedulous.Audio;

namespace Sedulous.Audio.Decoders;

/// MP3 audio decoder using dr_mp3.
/// Decodes MP3 files to 16-bit signed integer PCM.
class Mp3Decoder : IAudioDecoder
{
	public StringView Name => "MP3";

	public void GetSupportedExtensions(List<StringView> outExtensions)
	{
		outExtensions.Add(".mp3");
	}

	public bool CanDecode(Span<uint8> header)
	{
		if (header.Length < 3)
			return false;

		// Check for ID3v2 tag: "ID3"
		if (header[0] == 0x49 && header[1] == 0x44 && header[2] == 0x33)
			return true;

		// Check for MP3 frame sync (0xFF followed by 0xE* or 0xF*)
		// Valid MP3 frame headers: 0xFF 0xE2-0xFF (MPEG Audio)
		if (header[0] == 0xFF && (header[1] & 0xE0) == 0xE0)
			return true;

		return false;
	}

	public Result<AudioClip> Decode(Span<uint8> data)
	{
		if (data.IsEmpty)
			return .Err;

		drmp3_config config = .();
		drmp3_uint64 totalFrameCount = 0;

		// Decode MP3 to 16-bit PCM
		int16* samples = drmp3_open_memory_and_read_pcm_frames_s16(
			data.Ptr,
			(.)data.Length,
			&config,
			&totalFrameCount,
			null
		);

		if (samples == null || totalFrameCount == 0)
			return .Err;

		// Calculate data size
		int totalSamples = (int)(totalFrameCount * config.channels);
		int dataSize = totalSamples * sizeof(int16);

		// Copy data to our own buffer (dr_mp3 uses its own allocator)
		uint8* pcmData = new uint8[dataSize]*;
		Internal.MemCpy(pcmData, samples, dataSize);

		// Free dr_mp3's buffer
		drmp3_free(samples, null);

		// Create AudioClip
		return .Ok(new AudioClip(
			pcmData,
			dataSize,
			(int32)config.sampleRate,
			(int32)config.channels,
			.Int16,
			ownsData: true
		));
	}
}
