namespace Sedulous.Audio.Graph;

using System;
using Sedulous.Audio;

/// Audio graph node that reads samples from an AudioClip.
/// Converts source format to float32 stereo, applies volume, handles looping.
public class SourceNode : AudioNode
{
	private AudioClip mClip;
	private int32 mPlaybackPosition; // in frames
	private float mVolume = 1.0f;
	private bool mLoop;
	private bool mPlaying;
	private bool mFinished;

	/// The audio clip to play. Does not take ownership.
	public AudioClip Clip
	{
		get => mClip;
		set { mClip = value; mPlaybackPosition = 0; mFinished = false; }
	}

	/// Source volume multiplier (0.0 to 1.0).
	public float Volume
	{
		get => mVolume;
		set => mVolume = Math.Clamp(value, 0.0f, 1.0f);
	}

	/// Whether to loop playback.
	public bool Loop
	{
		get => mLoop;
		set => mLoop = value;
	}

	/// Whether this source is currently playing.
	public bool IsPlaying => mPlaying;

	/// Whether playback has finished (non-looping clip reached end).
	public bool IsFinished => mFinished;

	/// Current playback position in frames.
	public int32 PlaybackPosition => mPlaybackPosition;

	/// Starts playback from the beginning.
	public void Play()
	{
		mPlaybackPosition = 0;
		mPlaying = true;
		mFinished = false;
	}

	/// Stops playback.
	public void Stop()
	{
		mPlaying = false;
		mPlaybackPosition = 0;
	}

	/// Seeks to a specific frame position.
	public void Seek(int32 frame)
	{
		if (mClip != null)
			mPlaybackPosition = Math.Clamp(frame, 0, (int32)mClip.FrameCount);
	}

	protected override void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate)
	{
		let sampleCount = frameCount * 2;
		Internal.MemSet(buffer, 0, sampleCount * sizeof(float));

		if (!mPlaying || mClip == null || mFinished)
			return;

		let clipFrames = (int32)mClip.FrameCount;
		let clipChannels = mClip.Channels;
		let clipFormat = mClip.Format;
		let bytesPerFrame = mClip.BytesPerFrame;
		let volume = mVolume;

		int32 framesWritten = 0;

		while (framesWritten < frameCount)
		{
			if (mPlaybackPosition >= clipFrames)
			{
				if (mLoop)
				{
					mPlaybackPosition = 0;
				}
				else
				{
					mFinished = true;
					mPlaying = false;
					break;
				}
			}

			let framesToRead = Math.Min(frameCount - framesWritten, clipFrames - mPlaybackPosition);
			let srcOffset = mPlaybackPosition * bytesPerFrame;
			let srcData = mClip.Data + srcOffset;

			WriteToBuffer(buffer, framesWritten, srcData, framesToRead, clipChannels, clipFormat, volume);

			framesWritten += framesToRead;
			mPlaybackPosition += framesToRead;
		}
	}

	/// Converts source audio to float32 stereo and writes to output buffer with volume applied.
	private void WriteToBuffer(float* outBuffer, int32 outOffset, uint8* srcData, int32 frames,
		int32 channels, AudioFormat format, float volume)
	{
		for (int32 i = 0; i < frames; i++)
		{
			float left = 0;
			float right = 0;

			switch (format)
			{
			case .Int16:
				let samples = (int16*)srcData;
				if (channels == 1)
				{
					let mono = (float)samples[i] / 32768.0f;
					left = mono;
					right = mono;
				}
				else
				{
					left = (float)samples[i * 2] / 32768.0f;
					right = (float)samples[i * 2 + 1] / 32768.0f;
				}

			case .Int32:
				let samples = (int32*)srcData;
				if (channels == 1)
				{
					let mono = (float)samples[i] / 2147483648.0f;
					left = mono;
					right = mono;
				}
				else
				{
					left = (float)samples[i * 2] / 2147483648.0f;
					right = (float)samples[i * 2 + 1] / 2147483648.0f;
				}

			case .Float32:
				let samples = (float*)srcData;
				if (channels == 1)
				{
					left = samples[i];
					right = samples[i];
				}
				else
				{
					left = samples[i * 2];
					right = samples[i * 2 + 1];
				}
			}

			let outIdx = (outOffset + i) * 2;
			outBuffer[outIdx] = left * volume;
			outBuffer[outIdx + 1] = right * volume;
		}
	}
}
