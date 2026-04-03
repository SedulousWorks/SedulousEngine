using System;
using System.Collections;
using Sedulous.Audio;

namespace Sedulous.Audio.Decoders;

/// Interface for audio format decoders.
/// Implementations decode specific audio formats (FLAC, WAV, MP3, etc.) to PCM.
interface IAudioDecoder
{
	/// Gets the name of this decoder (e.g., "FLAC", "WAV", "MP3").
	StringView Name { get; }

	/// Gets the file extensions this decoder handles (e.g., ".flac", ".wav").
	/// Extensions should be lowercase and include the leading dot.
	void GetSupportedExtensions(List<StringView> outExtensions);

	/// Checks if this decoder can decode the given data by examining the header.
	/// Returns true if the header matches this format's magic bytes/signature.
	bool CanDecode(Span<uint8> header);

	/// Decodes audio data to PCM.
	/// Returns an AudioClip containing the decoded PCM data, or an error.
	Result<AudioClip> Decode(Span<uint8> data);
}
