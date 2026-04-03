using System;

namespace Sedulous.Audio;

/// Represents decoded PCM audio data ready for playback.
/// This is the standard audio format used throughout Sedulous - all audio files
/// are decoded to PCM before use.
class AudioClip : IDisposable
{
	private uint8* mData;
	private int mDataLength;
	private int32 mSampleRate;
	private int32 mChannels;
	private AudioFormat mFormat;
	private bool mOwnsData;

	/// Creates an AudioClip from PCM data.
	/// If ownsData is true, the clip takes ownership and will free the data on dispose.
	public this(uint8* data, int dataLength, int32 sampleRate, int32 channels, AudioFormat format, bool ownsData = true)
	{
		mData = data;
		mDataLength = dataLength;
		mSampleRate = sampleRate;
		mChannels = channels;
		mFormat = format;
		mOwnsData = ownsData;
	}

	public ~this()
	{
		Dispose();
	}

	public void Dispose()
	{
		if (mData != null && mOwnsData)
		{
			delete mData;
		}
		mData = null;
		mDataLength = 0;
	}

	/// Gets a pointer to the raw PCM data.
	public uint8* Data => mData;

	/// Gets the length of the PCM data in bytes.
	public int DataLength => mDataLength;

	/// Gets the audio sample format.
	public AudioFormat Format => mFormat;

	/// Gets the sample rate (e.g., 44100, 48000).
	public int32 SampleRate => mSampleRate;

	/// Gets the number of channels (1 = mono, 2 = stereo).
	public int32 Channels => mChannels;

	/// Gets whether the audio data is valid and ready for playback.
	public bool IsLoaded => mData != null && mDataLength > 0;

	/// Gets the duration of the audio clip in seconds.
	public float Duration
	{
		get
		{
			if (mData == null || mSampleRate == 0 || mChannels == 0)
				return 0;

			int bytesPerFrame = mFormat.BytesPerSample * mChannels;
			if (bytesPerFrame == 0)
				return 0;

			int totalFrames = mDataLength / bytesPerFrame;
			return (float)totalFrames / (float)mSampleRate;
		}
	}

	/// Gets the total number of PCM frames (samples per channel).
	public int FrameCount
	{
		get
		{
			if (mData == null || mChannels == 0)
				return 0;

			int bytesPerFrame = mFormat.BytesPerSample * mChannels;
			if (bytesPerFrame == 0)
				return 0;

			return mDataLength / bytesPerFrame;
		}
	}

	/// Gets the bytes per frame (bytesPerSample * channels).
	public int BytesPerFrame => mFormat.BytesPerSample * mChannels;

	/// Creates an AudioClip by copying data from a span.
	public static AudioClip FromData(Span<uint8> data, int32 sampleRate, int32 channels, AudioFormat format)
	{
		if (data.IsEmpty)
			return null;

		uint8* copy = new uint8[data.Length]*;
		Internal.MemCpy(copy, data.Ptr, data.Length);

		return new AudioClip(copy, data.Length, sampleRate, channels, format, true);
	}

	/// Creates an AudioClip from signed 16-bit integer samples.
	public static AudioClip FromInt16(Span<int16> samples, int32 sampleRate, int32 channels)
	{
		if (samples.IsEmpty)
			return null;

		int dataLen = samples.Length * sizeof(int16);
		uint8* data = new uint8[dataLen]*;
		Internal.MemCpy(data, samples.Ptr, dataLen);

		return new AudioClip(data, dataLen, sampleRate, channels, .Int16, true);
	}

	/// Creates an AudioClip from 32-bit floating point samples.
	public static AudioClip FromFloat32(Span<float> samples, int32 sampleRate, int32 channels)
	{
		if (samples.IsEmpty)
			return null;

		int dataLen = samples.Length * sizeof(float);
		uint8* data = new uint8[dataLen]*;
		Internal.MemCpy(data, samples.Ptr, dataLen);

		return new AudioClip(data, dataLen, sampleRate, channels, .Float32, true);
	}
}
