using System;
using System.IO;
using SDL3;
using Sedulous.Audio;

namespace Sedulous.Audio.SDL3;

/// SDL3 implementation of IAudioStream for streaming audio from files.
class SDL3AudioStream : IAudioStream
{
	private SDL_AudioStream* mStream;
	private SDL_AudioDeviceID mDeviceId;
	private FileStream mFileStream;
	private SDL_AudioSpec mSourceSpec;
	private AudioSourceState mState = .Stopped;
	private float mVolume = 1.0f;
	private bool mLoop;
	private float mMasterVolume = 1.0f;

	// File info
	private int64 mDataOffset;    // Byte offset where audio data starts
	private int64 mDataLength;    // Length of audio data in bytes
	private int64 mCurrentPosition;  // Current read position in data

	// Streaming
	private const int32 CHUNK_SIZE = 16384;  // 16KB chunks for streaming
	private uint8[] mReadBuffer;

	/// Creates an audio stream for the given file.
	public this(SDL_AudioDeviceID deviceId, StringView filePath)
	{
		mDeviceId = deviceId;
		mReadBuffer = new uint8[CHUNK_SIZE];

		// Open file
		mFileStream = new FileStream();
		if (mFileStream.Open(filePath, .Read, .Read) case .Err)
		{
			delete mFileStream;
			mFileStream = null;
			return;
		}

		// Parse WAV header
		if (!ParseWavHeader())
		{
			delete mFileStream;
			mFileStream = null;
			return;
		}

		// Create SDL audio stream
		SDL_AudioSpec deviceSpec = .();
		if (!SDL3.SDL_GetAudioDeviceFormat(mDeviceId, &deviceSpec, null))
		{
			delete mFileStream;
			mFileStream = null;
			return;
		}

		mStream = SDL3.SDL_CreateAudioStream(&mSourceSpec, &deviceSpec);
		if (mStream == null)
		{
			delete mFileStream;
			mFileStream = null;
			return;
		}

		// Bind stream to device
		if (!SDL3.SDL_BindAudioStream(mDeviceId, mStream))
		{
			SDL3.SDL_DestroyAudioStream(mStream);
			mStream = null;
			delete mFileStream;
			mFileStream = null;
			return;
		}
	}

	public ~this()
	{
		Dispose();
	}

	public void Dispose()
	{
		if (mStream != null)
		{
			SDL3.SDL_UnbindAudioStream(mStream);
			SDL3.SDL_DestroyAudioStream(mStream);
			mStream = null;
		}

		if (mFileStream != null)
		{
			delete mFileStream;
			mFileStream = null;
		}

		if (mReadBuffer != null)
		{
			delete mReadBuffer;
			mReadBuffer = null;
		}
	}

	public float Duration
	{
		get
		{
			if (mSourceSpec.freq == 0)
				return 0;
			let frameSize = SDL3.SDL_AUDIO_FRAMESIZE(mSourceSpec);
			if (frameSize == 0)
				return 0;
			let totalFrames = mDataLength / frameSize;
			return (float)totalFrames / (float)mSourceSpec.freq;
		}
	}

	public float Position
	{
		get
		{
			if (mSourceSpec.freq == 0)
				return 0;
			let frameSize = SDL3.SDL_AUDIO_FRAMESIZE(mSourceSpec);
			if (frameSize == 0)
				return 0;
			let currentFrames = mCurrentPosition / frameSize;
			return (float)currentFrames / (float)mSourceSpec.freq;
		}
	}

	public int32 SampleRate => mSourceSpec.freq;

	public int32 Channels => mSourceSpec.channels;

	public bool IsReady => mStream != null && mFileStream != null;

	public AudioSourceState State => mState;

	public float Volume
	{
		get => mVolume;
		set
		{
			mVolume = Math.Clamp(value, 0.0f, 1.0f);
			UpdateGain();
		}
	}

	public bool Loop
	{
		get => mLoop;
		set => mLoop = value;
	}

	public void Play()
	{
		if (!IsReady)
			return;

		// Reset to beginning
		mCurrentPosition = 0;
		mFileStream.Seek(mDataOffset);
		SDL3.SDL_ClearAudioStream(mStream);

		// Feed initial data
		FeedAudioChunks();

		UpdateGain();
		mState = .Playing;
	}

	public void Pause()
	{
		if (mStream != null && mState == .Playing)
		{
			SDL3.SDL_PauseAudioStreamDevice(mStream);
			mState = .Paused;
		}
	}

	public void Resume()
	{
		if (mStream != null && mState == .Paused)
		{
			SDL3.SDL_ResumeAudioStreamDevice(mStream);
			mState = .Playing;
		}
	}

	public void Stop()
	{
		if (mStream != null)
		{
			SDL3.SDL_ClearAudioStream(mStream);
			mCurrentPosition = 0;
			mState = .Stopped;
		}
	}

	public void Seek(float position)
	{
		if (!IsReady)
			return;

		let frameSize = SDL3.SDL_AUDIO_FRAMESIZE(mSourceSpec);
		if (frameSize == 0)
			return;

		let targetFrame = (int64)(position * mSourceSpec.freq);
		var targetByte = targetFrame * frameSize;
		targetByte = Math.Clamp(targetByte, 0, mDataLength);

		// Align to frame boundary
		targetByte = (targetByte / frameSize) * frameSize;

		mCurrentPosition = targetByte;
		mFileStream.Seek(mDataOffset + mCurrentPosition);

		// Clear and refill stream
		SDL3.SDL_ClearAudioStream(mStream);
		if (mState == .Playing)
			FeedAudioChunks();
	}

	/// Sets the master volume from the audio system.
	public void SetMasterVolume(float masterVolume)
	{
		mMasterVolume = masterVolume;
		UpdateGain();
	}

	/// Updates the stream, feeding more data as needed.
	public void Update()
	{
		if (mStream == null || mState != .Playing)
			return;

		// Feed more data if needed
		let queued = SDL3.SDL_GetAudioStreamQueued(mStream);
		if (queued < CHUNK_SIZE * 2)
		{
			FeedAudioChunks();
		}

		// Check if we've finished
		if (mCurrentPosition >= mDataLength && SDL3.SDL_GetAudioStreamQueued(mStream) <= 0)
		{
			if (mLoop)
			{
				mCurrentPosition = 0;
				mFileStream.Seek(mDataOffset);
				FeedAudioChunks();
			}
			else
			{
				mState = .Stopped;
			}
		}
	}

	private void UpdateGain()
	{
		if (mStream != null)
		{
			SDL3.SDL_SetAudioStreamGain(mStream, mVolume * mMasterVolume);
		}
	}

	private void FeedAudioChunks()
	{
		if (mFileStream == null || mStream == null || mReadBuffer == null)
			return;

		// Feed up to 2 chunks to keep buffer full
		for (int i = 0; i < 2; i++)
		{
			let remaining = mDataLength - mCurrentPosition;
			if (remaining <= 0)
				break;

			let toRead = Math.Min(remaining, CHUNK_SIZE);
			switch (mFileStream.TryRead(.(&mReadBuffer[0], (.)toRead)))
			{
			case .Ok(let bytesRead):
				if (bytesRead > 0)
				{
					SDL3.SDL_PutAudioStreamData(mStream, &mReadBuffer[0], (.)bytesRead);
					mCurrentPosition += bytesRead;
				}
			case .Err:
				break;
			}
		}
	}

	/// Parses WAV header to extract format info and data offset.
	private bool ParseWavHeader()
	{
		if (mFileStream == null)
			return false;

		uint8[44] header = ?;
		switch (mFileStream.TryRead(.(&header[0], 44)))
		{
		case .Ok(let bytesRead):
			if (bytesRead < 44)
				return false;
		case .Err:
			return false;
		}

		// Check RIFF header
		if (header[0] != 'R' || header[1] != 'I' || header[2] != 'F' || header[3] != 'F')
			return false;
		if (header[8] != 'W' || header[9] != 'A' || header[10] != 'V' || header[11] != 'E')
			return false;

		// Check fmt chunk
		if (header[12] != 'f' || header[13] != 'm' || header[14] != 't' || header[15] != ' ')
			return false;

		// Parse format
		let audioFormat = *(int16*)&header[20];
		let channels = *(int16*)&header[22];
		let sampleRate = *(int32*)&header[24];
		let bitsPerSample = *(int16*)&header[34];

		if (audioFormat != 1)  // Only PCM supported
			return false;

		// Set source spec
		mSourceSpec.channels = (.)channels;
		mSourceSpec.freq = sampleRate;

		switch (bitsPerSample)
		{
		case 8:
			mSourceSpec.format = .SDL_AUDIO_S8;
		case 16:
			mSourceSpec.format = .SDL_AUDIO_S16;
		case 32:
			mSourceSpec.format = .SDL_AUDIO_F32;
		default:
			return false;
		}

		// Find data chunk
		mFileStream.Seek(12);  // After RIFF header

		uint8[8] chunkHeader = ?;
		while (true)
		{
			switch (mFileStream.TryRead(.(&chunkHeader[0], 8)))
			{
			case .Ok(let bytesRead):
				if (bytesRead < 8)
					return false;
			case .Err:
				return false;
			}

			let chunkSize = *(int32*)&chunkHeader[4];

			if (chunkHeader[0] == 'd' && chunkHeader[1] == 'a' && chunkHeader[2] == 't' && chunkHeader[3] == 'a')
			{
				// Found data chunk
				mDataOffset = mFileStream.Position;
				mDataLength = chunkSize;
				mCurrentPosition = 0;
				return true;
			}

			// Skip this chunk
			mFileStream.Seek(mFileStream.Position + chunkSize);
		}
	}
}
