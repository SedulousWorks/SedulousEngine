using System;
using SDL3;
using Sedulous.Core.Mathematics;
using Sedulous.Audio;

namespace Sedulous.Audio.SDL3;

/// SDL3 implementation of IAudioSource using SDL_AudioStream with real-time 3D panning.
class SDL3AudioSource : IAudioSource
{
	private SDL_AudioStream* mStream;
	private SDL_AudioDeviceID mDeviceId;
	private AudioClip mCurrentClip;
	private SDL_AudioFormat mClipFormat;
	private AudioSourceState mState = .Stopped;
	private float mVolume = 1.0f;
	private float mPitch = 1.0f;
	private bool mLoop;
	private Vector3 mPosition = .Zero;
	private float mMinDistance = 1.0f;
	private float mMaxDistance = 100.0f;
	private bool m3DEnabled;
	private float mMasterVolume = 1.0f;

	// 3D audio state
	private float mDistanceGain = 1.0f;
	private float mPan = 0.0f;  // -1 = left, 0 = center, +1 = right

	// Chunk-based playback tracking
	private uint32 mPlaybackPosition;  // Current position in source audio (bytes)
	private const int32 CHUNK_SIZE = 4096;  // Bytes per chunk to feed
	private uint8* mProcessBuffer;  // Buffer for processed stereo audio
	private int32 mProcessBufferSize;

	/// Creates an audio source that will bind streams to the specified device.
	public this(SDL_AudioDeviceID deviceId)
	{
		mDeviceId = deviceId;
		mProcessBufferSize = CHUNK_SIZE * 2;  // Worst case: mono->stereo doubles size
		mProcessBuffer = (uint8*)SDL3.SDL_malloc((.)mProcessBufferSize);
	}

	public ~this()
	{
		DestroyStream();
		if (mProcessBuffer != null)
		{
			SDL3.SDL_free(mProcessBuffer);
			mProcessBuffer = null;
		}
	}

	public AudioSourceState State => mState;

	public float Volume
	{
		get => mVolume;
		set => mVolume = Math.Clamp(value, 0.0f, 1.0f);
	}

	public float Pitch
	{
		get => mPitch;
		set
		{
			mPitch = Math.Max(value, 0.01f);
			if (mStream != null)
				SDL3.SDL_SetAudioStreamFrequencyRatio(mStream, mPitch);
		}
	}

	public bool Loop
	{
		get => mLoop;
		set => mLoop = value;
	}

	public Vector3 Position
	{
		get => mPosition;
		set
		{
			mPosition = value;
			m3DEnabled = true;
		}
	}

	public float MinDistance
	{
		get => mMinDistance;
		set => mMinDistance = Math.Max(value, 0.01f);
	}

	public float MaxDistance
	{
		get => mMaxDistance;
		set => mMaxDistance = Math.Max(value, mMinDistance);
	}

	public void Play(AudioClip clip)
	{
		mCurrentClip = clip;
		if (mCurrentClip == null || !mCurrentClip.IsLoaded)
			return;

		// Convert AudioFormat to SDL_AudioFormat
		mClipFormat = AudioFormatToSDL(mCurrentClip.Format);
		if (mClipFormat == .SDL_AUDIO_UNKNOWN)
			return;

		// Destroy existing stream
		DestroyStream();

		// Get device format (we'll output stereo for 3D panning)
		SDL_AudioSpec deviceSpec = .();
		if (!SDL3.SDL_GetAudioDeviceFormat(mDeviceId, &deviceSpec, null))
			return;

		// Create stream: output stereo int16 (for panning), SDL will convert to device format
		SDL_AudioSpec outputSpec = .();
		outputSpec.format = .SDL_AUDIO_S16;
		outputSpec.channels = 2;  // Always stereo for 3D panning
		outputSpec.freq = mCurrentClip.SampleRate;

		mStream = SDL3.SDL_CreateAudioStream(&outputSpec, &deviceSpec);
		if (mStream == null)
			return;

		// Bind stream to device
		if (!SDL3.SDL_BindAudioStream(mDeviceId, mStream))
		{
			SDL3.SDL_DestroyAudioStream(mStream);
			mStream = null;
			return;
		}

		// Reset playback position
		mPlaybackPosition = 0;

		// Apply pitch
		SDL3.SDL_SetAudioStreamFrequencyRatio(mStream, mPitch);

		// Feed initial chunk
		FeedAudioChunk();

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
			mPlaybackPosition = 0;
			mState = .Stopped;
		}
	}

	/// Sets the master volume from the audio system.
	public void SetMasterVolume(float masterVolume)
	{
		mMasterVolume = masterVolume;
	}

	/// Calculates 3D audio parameters (distance gain and pan) from listener position.
	public void Update3D(SDL3AudioListener listener)
	{
		if (!m3DEnabled)
		{
			mDistanceGain = 1.0f;
			mPan = 0.0f;
			return;
		}

		// Calculate distance attenuation
		let offset = mPosition - listener.Position;
		let distance = offset.Length();

		if (distance <= mMinDistance)
			mDistanceGain = 1.0f;
		else if (distance >= mMaxDistance)
			mDistanceGain = 0.0f;
		else
			mDistanceGain = 1.0f - (distance - mMinDistance) / (mMaxDistance - mMinDistance);

		// Calculate stereo pan from direction
		if (distance > 0.001f)
		{
			let direction = offset / distance;

			// Calculate listener's right vector
			let right = Vector3.Normalize(Vector3.Cross(listener.Forward, listener.Up));

			// Pan is the dot product with right vector (-1 = left, +1 = right)
			mPan = Math.Clamp(Vector3.Dot(direction, right), -1.0f, 1.0f);
		}
		else
		{
			mPan = 0.0f;
		}
	}

	/// Updates the playback state, feeds audio chunks, handles looping.
	public void UpdateState()
	{
		if (mStream == null || mState != .Playing)
			return;

		// Feed more audio if the stream needs it
		var queued = SDL3.SDL_GetAudioStreamQueued(mStream);
		if (queued < CHUNK_SIZE * 2)
		{
			FeedAudioChunk();
		}

		// Check if we've finished playing
		let clipLen = (uint32)mCurrentClip.DataLength;
		queued = SDL3.SDL_GetAudioStreamQueued(mStream);  // Re-query after potential feed
		if (mPlaybackPosition >= clipLen)
		{
			// SDL3 may keep a small residual buffer, use threshold instead of exact 0
			if (queued < 256)
			{
				if (mLoop)
				{
					mPlaybackPosition = 0;
					FeedAudioChunk();
				}
				else
				{
					mState = .Stopped;
				}
			}
		}
	}

	/// Feeds a chunk of audio with 3D panning applied.
	private void FeedAudioChunk()
	{
		if (mCurrentClip == null || mStream == null || mProcessBuffer == null)
			return;

		// Calculate how many bytes to read from source
		let remainingBytes = (uint32)mCurrentClip.DataLength - mPlaybackPosition;
		if (remainingBytes == 0)
			return;

		let srcFrameSize = (uint32)mCurrentClip.BytesPerFrame;
		if (srcFrameSize == 0)
			return;

		// Read up to CHUNK_SIZE bytes worth of frames
		var bytesToRead = Math.Min((uint32)CHUNK_SIZE, remainingBytes);
		bytesToRead = (bytesToRead / srcFrameSize) * srcFrameSize;  // Align to frame boundary

		if (bytesToRead == 0)
			return;

		let srcData = mCurrentClip.Data + mPlaybackPosition;
		let numFrames = (int32)(bytesToRead / srcFrameSize);

		// Calculate gains
		let totalGain = mVolume * mMasterVolume * mDistanceGain;

		// Calculate left/right gains from pan using constant power panning
		// At pan=0: both = 0.707 (equal power)
		// At pan=-1: left=1, right=0
		// At pan=+1: left=0, right=1
		let angle = (mPan + 1.0f) * Math.PI_f * 0.25f;  // 0 to PI/2
		let leftGain = totalGain * Math.Cos(angle);
		let rightGain = totalGain * Math.Sin(angle);

		// Process audio based on source format
		int32 outputBytes = 0;

		if (mCurrentClip.Channels == 1)
		{
			// Mono source -> stereo with panning
			outputBytes = ProcessMonoToStereo(srcData, numFrames, mClipFormat, leftGain, rightGain);
		}
		else if (mCurrentClip.Channels == 2)
		{
			// Stereo source -> apply gains to existing channels
			outputBytes = ProcessStereo(srcData, numFrames, mClipFormat, leftGain, rightGain);
		}
		else
		{
			// Other channel counts: just use distance attenuation, no panning
			// Feed directly with simple gain (less accurate but handles edge cases)
			SDL3.SDL_SetAudioStreamGain(mStream, totalGain);

			// Need to convert to our output format - for now skip complex channel counts
			mPlaybackPosition += (.)bytesToRead;
			return;
		}

		if (outputBytes > 0)
		{
			SDL3.SDL_PutAudioStreamData(mStream, mProcessBuffer, outputBytes);
		}

		mPlaybackPosition += (.)bytesToRead;
	}

	/// Processes mono audio to stereo with left/right gains.
	private int32 ProcessMonoToStereo(uint8* srcData, int32 numFrames, SDL_AudioFormat format, float leftGain, float rightGain)
	{
		// Output is always S16 stereo
		int16* outPtr = (int16*)mProcessBuffer;

		if (format == .SDL_AUDIO_S16)
		{
			int16* inPtr = (int16*)srcData;
			for (int32 i = 0; i < numFrames; i++)
			{
				let sample = (float)inPtr[i];
				outPtr[i * 2] = (int16)Math.Clamp(sample * leftGain, -32768, 32767);
				outPtr[i * 2 + 1] = (int16)Math.Clamp(sample * rightGain, -32768, 32767);
			}
			return numFrames * 4;  // 2 channels * 2 bytes per sample
		}
		else if (format == .SDL_AUDIO_S8)
		{
			int8* inPtr = (int8*)srcData;
			for (int32 i = 0; i < numFrames; i++)
			{
				let sample = (float)inPtr[i] * 256.0f;  // Scale to 16-bit range
				outPtr[i * 2] = (int16)Math.Clamp(sample * leftGain, -32768, 32767);
				outPtr[i * 2 + 1] = (int16)Math.Clamp(sample * rightGain, -32768, 32767);
			}
			return numFrames * 4;
		}
		else if (format == .SDL_AUDIO_F32)
		{
			float* inPtr = (float*)srcData;
			for (int32 i = 0; i < numFrames; i++)
			{
				let sample = inPtr[i] * 32767.0f;
				outPtr[i * 2] = (int16)Math.Clamp(sample * leftGain, -32768, 32767);
				outPtr[i * 2 + 1] = (int16)Math.Clamp(sample * rightGain, -32768, 32767);
			}
			return numFrames * 4;
		}

		return 0;
	}

	/// Processes stereo audio with left/right gains.
	private int32 ProcessStereo(uint8* srcData, int32 numFrames, SDL_AudioFormat format, float leftGain, float rightGain)
	{
		// Output is always S16 stereo
		int16* outPtr = (int16*)mProcessBuffer;

		if (format == .SDL_AUDIO_S16)
		{
			int16* inPtr = (int16*)srcData;
			for (int32 i = 0; i < numFrames; i++)
			{
				let leftSample = (float)inPtr[i * 2];
				let rightSample = (float)inPtr[i * 2 + 1];
				outPtr[i * 2] = (int16)Math.Clamp(leftSample * leftGain, -32768, 32767);
				outPtr[i * 2 + 1] = (int16)Math.Clamp(rightSample * rightGain, -32768, 32767);
			}
			return numFrames * 4;
		}
		else if (format == .SDL_AUDIO_S8)
		{
			int8* inPtr = (int8*)srcData;
			for (int32 i = 0; i < numFrames; i++)
			{
				let leftSample = (float)inPtr[i * 2] * 256.0f;
				let rightSample = (float)inPtr[i * 2 + 1] * 256.0f;
				outPtr[i * 2] = (int16)Math.Clamp(leftSample * leftGain, -32768, 32767);
				outPtr[i * 2 + 1] = (int16)Math.Clamp(rightSample * rightGain, -32768, 32767);
			}
			return numFrames * 4;
		}
		else if (format == .SDL_AUDIO_F32)
		{
			float* inPtr = (float*)srcData;
			for (int32 i = 0; i < numFrames; i++)
			{
				let leftSample = inPtr[i * 2] * 32767.0f;
				let rightSample = inPtr[i * 2 + 1] * 32767.0f;
				outPtr[i * 2] = (int16)Math.Clamp(leftSample * leftGain, -32768, 32767);
				outPtr[i * 2 + 1] = (int16)Math.Clamp(rightSample * rightGain, -32768, 32767);
			}
			return numFrames * 4;
		}

		return 0;
	}

	/// Returns true if this is a one-shot source (managed by the system).
	public bool IsOneShot { get; set; }

	/// Returns true if this source has finished playing (for one-shot cleanup).
	public bool IsFinished => mState == .Stopped;

	/// For one-shot sources, stores the 3D position for panning calculations.
	public Vector3 OneShotPosition { get; set; }

	private void DestroyStream()
	{
		if (mStream != null)
		{
			SDL3.SDL_UnbindAudioStream(mStream);
			SDL3.SDL_DestroyAudioStream(mStream);
			mStream = null;
		}
	}

	/// Converts Sedulous AudioFormat to SDL_AudioFormat.
	private static SDL_AudioFormat AudioFormatToSDL(AudioFormat format)
	{
		switch (format)
		{
		case .Int16:
			return .SDL_AUDIO_S16;
		case .Int32:
			return .SDL_AUDIO_S32;
		case .Float32:
			return .SDL_AUDIO_F32;
		}
	}
}
