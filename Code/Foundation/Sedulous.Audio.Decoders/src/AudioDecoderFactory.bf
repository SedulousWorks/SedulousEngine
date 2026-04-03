using System;
using System.Collections;
using System.IO;
using Sedulous.Audio;

namespace Sedulous.Audio.Decoders;

/// Factory for decoding audio files to PCM.
/// Automatically detects the audio format and uses the appropriate decoder.
class AudioDecoderFactory
{
	private List<IAudioDecoder> mDecoders = new .() ~ DeleteContainerAndItems!(_);

	/// Minimum header size needed for format detection.
	public const int MIN_HEADER_SIZE = 12;

	/// Creates a new AudioDecoderFactory with no registered decoders.
	/// Call RegisterDecoder or RegisterDefaultDecoders to add decoder support.
	public this()
	{
	}

	/// Registers a decoder. The factory takes ownership of the decoder.
	public void RegisterDecoder(IAudioDecoder decoder)
	{
		mDecoders.Add(decoder);
	}

	/// Registers all built-in decoders (FLAC, Vorbis, MP3, WAV, etc.).
	public void RegisterDefaultDecoders()
	{
		RegisterDecoder(new FlacDecoder());
		RegisterDecoder(new VorbisDecoder());
		RegisterDecoder(new Mp3Decoder());
		RegisterDecoder(new WavDecoder());
	}

	/// Gets the number of registered decoders.
	public int DecoderCount => mDecoders.Count;

	/// Finds a decoder that can handle the given data based on header inspection.
	public IAudioDecoder FindDecoder(Span<uint8> data)
	{
		if (data.Length < MIN_HEADER_SIZE)
			return null;

		// Check header against each decoder
		let header = data.Slice(0, Math.Min(data.Length, MIN_HEADER_SIZE));
		for (let decoder in mDecoders)
		{
			if (decoder.CanDecode(header))
				return decoder;
		}

		return null;
	}

	/// Finds a decoder that handles the given file extension.
	public IAudioDecoder FindDecoderByExtension(StringView fileExt)
	{
		let lowerExt = scope String(fileExt);
		lowerExt.ToLower();

		// Ensure extension starts with a dot
		if (!lowerExt.StartsWith('.'))
			lowerExt.Insert(0, ".");

		let extList = scope List<StringView>();
		for (let decoder in mDecoders)
		{
			extList.Clear();
			decoder.GetSupportedExtensions(extList);
			for (let ext in extList)
			{
				if (ext == lowerExt)
					return decoder;
			}
		}

		return null;
	}

	/// Decodes audio data to PCM, automatically detecting the format.
	/// Tries header-based detection first, falls back to extension hint if provided.
	public Result<AudioClip> Decode(Span<uint8> data, StringView extensionHint = default)
	{
		if (data.Length < MIN_HEADER_SIZE)
			return .Err;

		// Try header-based detection first
		if (let decoder = FindDecoder(data))
			return decoder.Decode(data);

		// Fall back to extension hint
		if (!extensionHint.IsEmpty)
		{
			if (let decoder = FindDecoderByExtension(extensionHint))
				return decoder.Decode(data);
		}

		return .Err;
	}

	/// Decodes an audio file from disk to PCM.
	public Result<AudioClip> DecodeFile(StringView filePath)
	{
		// Read file data
		let data = scope List<uint8>();
		if (File.ReadAll(filePath, data) case .Err)
			return .Err;

		if (data.Count == 0)
			return .Err;

		// Get extension for fallback detection
		let ext = scope String();
		Path.GetExtension(filePath, ext);

		return Decode(.(data.Ptr, data.Count), ext);
	}

	/// Checks if any registered decoder can handle the given file extension.
	public bool SupportsExtension(StringView fileExt)
	{
		return FindDecoderByExtension(fileExt) != null;
	}

	/// Checks if any registered decoder can decode the given data.
	public bool CanDecode(Span<uint8> data)
	{
		return FindDecoder(data) != null;
	}

	/// Gets all supported file extensions across all registered decoders.
	public void GetSupportedExtensions(List<StringView> outExtensions)
	{
		for (let decoder in mDecoders)
		{
			decoder.GetSupportedExtensions(outExtensions);
		}
	}
}
