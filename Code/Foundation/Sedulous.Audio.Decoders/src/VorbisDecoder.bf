using System;
using System.Collections;
using stb_vorbis_Beef;
using Sedulous.Audio;

namespace Sedulous.Audio.Decoders;

/// OGG Vorbis audio decoder using stb_vorbis.
/// Decodes OGG Vorbis files to 16-bit signed integer PCM.
class VorbisDecoder : IAudioDecoder
{
	/// OGG magic bytes: "OggS"
	private static readonly uint8[4] OGG_MAGIC = .(0x4F, 0x67, 0x67, 0x53);

	public StringView Name => "Vorbis";

	public void GetSupportedExtensions(List<StringView> outExtensions)
	{
		outExtensions.Add(".ogg");
	}

	public bool CanDecode(Span<uint8> header)
	{
		if (header.Length < 4)
			return false;

		// Check for OGG magic bytes "OggS"
		return header[0] == OGG_MAGIC[0] &&
		       header[1] == OGG_MAGIC[1] &&
		       header[2] == OGG_MAGIC[2] &&
		       header[3] == OGG_MAGIC[3];
	}

	public Result<AudioClip> Decode(Span<uint8> data)
	{
		if (data.IsEmpty)
			return .Err;

		int32 channels = 0;
		int32 sampleRate = 0;
		int16* samples = null;

		// Decode OGG Vorbis to 16-bit PCM
		// Returns number of samples per channel, or -1 on error
		int32 sampleCount = stb_vorbis_decode_memory(
			data.Ptr,
			(int32)data.Length,
			&channels,
			&sampleRate,
			&samples
		);

		if (sampleCount <= 0 || samples == null)
			return .Err;

		// Calculate total data size (samples * channels * sizeof(int16))
		int totalSamples = sampleCount * channels;
		int dataSize = totalSamples * sizeof(int16);

		// Copy data to our own buffer (stb_vorbis uses malloc)
		uint8* pcmData = new uint8[dataSize]*;
		Internal.MemCpy(pcmData, samples, dataSize);

		// Free stb_vorbis's buffer using C's free()
		Internal.StdFree(samples);

		// Create AudioClip
		return .Ok(new AudioClip(
			pcmData,
			dataSize,
			sampleRate,
			channels,
			.Int16,
			ownsData: true
		));
	}
}
