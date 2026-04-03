using System;
using System.Collections;
using dr_libs_Beef;
using Sedulous.Audio;

namespace Sedulous.Audio.Decoders;

/// WAV audio decoder using dr_wav.
/// Decodes WAV files (including RIFF, RIFX, RF64, W64, AIFF) to 16-bit signed integer PCM.
/// Supports various encodings: PCM (8/16/24/32-bit), IEEE float, A-law, u-law, ADPCM.
class WavDecoder : IAudioDecoder
{
	public StringView Name => "WAV";

	public void GetSupportedExtensions(List<StringView> outExtensions)
	{
		outExtensions.Add(".wav");
		outExtensions.Add(".wave");
	}

	public bool CanDecode(Span<uint8> header)
	{
		if (header.Length < 12)
			return false;

		// Check for RIFF header: "RIFF" + size + "WAVE"
		if (header[0] == 'R' && header[1] == 'I' && header[2] == 'F' && header[3] == 'F' &&
			header[8] == 'W' && header[9] == 'A' && header[10] == 'V' && header[11] == 'E')
			return true;

		// Check for RIFX (big-endian): "RIFX" + size + "WAVE"
		if (header[0] == 'R' && header[1] == 'I' && header[2] == 'F' && header[3] == 'X' &&
			header[8] == 'W' && header[9] == 'A' && header[10] == 'V' && header[11] == 'E')
			return true;

		// Check for RF64: "RF64" + size + "WAVE"
		if (header[0] == 'R' && header[1] == 'F' && header[2] == '6' && header[3] == '4' &&
			header[8] == 'W' && header[9] == 'A' && header[10] == 'V' && header[11] == 'E')
			return true;

		// Check for W64 (Sony Wave64): GUID starts with "riff"
		if (header[0] == 'r' && header[1] == 'i' && header[2] == 'f' && header[3] == 'f')
			return true;

		// Check for AIFF: "FORM" + size + "AIFF"
		if (header[0] == 'F' && header[1] == 'O' && header[2] == 'R' && header[3] == 'M' &&
			header[8] == 'A' && header[9] == 'I' && header[10] == 'F' && header[11] == 'F')
			return true;

		// Check for AIFC: "FORM" + size + "AIFC"
		if (header[0] == 'F' && header[1] == 'O' && header[2] == 'R' && header[3] == 'M' &&
			header[8] == 'A' && header[9] == 'I' && header[10] == 'F' && header[11] == 'C')
			return true;

		return false;
	}

	public Result<AudioClip> Decode(Span<uint8> data)
	{
		if (data.IsEmpty)
			return .Err;

		uint32 channels = 0;
		uint32 sampleRate = 0;
		drwav_uint64 totalFrameCount = 0;

		// Decode WAV to 16-bit PCM
		int16* samples = drwav_open_memory_and_read_pcm_frames_s16(
			data.Ptr,
			(.)data.Length,
			&channels,
			&sampleRate,
			&totalFrameCount,
			null
		);

		if (samples == null || totalFrameCount == 0)
			return .Err;

		// Calculate data size
		int totalSamples = (int)(totalFrameCount * channels);
		int dataSize = totalSamples * sizeof(int16);

		// Copy data to our own buffer (dr_wav uses its own allocator)
		uint8* pcmData = new uint8[dataSize]*;
		Internal.MemCpy(pcmData, samples, dataSize);

		// Free dr_wav's buffer
		drwav_free(samples, null);

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
