using System;
using System.IO;
using Sedulous.Audio;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Audio.Resources;

/// Resource wrapper for audio clips, enabling integration with the ResourceSystem.
/// Text metadata (sample rate, channels, format) is serialized via Serialize().
/// PCM data is a binary sidecar at "<assetLocator>.bin" (derived by
/// convention - not stored).
class AudioClipResource : Resource
{
	public const int32 FileVersion = 2;

	public override ResourceType ResourceType => .("audioclip");
	public override int32 SerializationVersion => FileVersion;

	private AudioClip mClip;

	/// Audio metadata -- stored for deserialization (clip created by manager after loading sidecar).
	public int32 ClipSampleRate;
	public int32 ClipChannels;
	public int32 ClipFormat; // AudioFormat as int32

	/// Gets or sets the wrapped audio clip.
	public AudioClip Clip
	{
		get => mClip;
		set => mClip = value;
	}

	public ~this()
	{
		if (mClip != null)
			delete mClip;
	}

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (s.IsWriting && mClip != null)
		{
			ClipSampleRate = mClip.SampleRate;
			ClipChannels = mClip.Channels;
			ClipFormat = (int32)mClip.Format;
		}

		s.Int32("sampleRate", ref ClipSampleRate);
		s.Int32("channels", ref ClipChannels);
		s.Int32("format", ref ClipFormat);

		return .Ok;
	}

	/// Writes the PCM bytes to `stream`. Caller writes the text metadata
	/// via `WriteToStream` and saves these bytes to the conventional
	/// "<assetLocator>.bin" sidecar.
	public Result<void> WritePcmToStream(Stream stream)
	{
		if (mClip == null || !mClip.IsLoaded)
			return .Err;
		let pcmData = Span<uint8>(mClip.Data, mClip.DataLength);
		if (stream.TryWrite(pcmData) case .Err)
			return .Err;
		return .Ok;
	}
}
