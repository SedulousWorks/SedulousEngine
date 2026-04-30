namespace Sedulous.Audio.Effects;

using System;
using Sedulous.Audio;

/// Delay/echo effect with feedback using a circular buffer.
public class DelayEffect : IAudioEffect
{
	private float mDelayTime = 0.3f;
	private float mFeedback = 0.4f;
	private float mWetDryMix = 0.5f;
	private bool mEnabled = true;

	// Circular delay buffer (stereo interleaved)
	private float* mBuffer;
	private int32 mBufferSize; // in samples (stereo)
	private int32 mWritePos;
	private int32 mLastSampleRate;

	public StringView Name => "Delay";

	public bool Enabled
	{
		get => mEnabled;
		set => mEnabled = value;
	}

	/// Delay time in seconds (0.01 to 2.0).
	public float DelayTime
	{
		get => mDelayTime;
		set => mDelayTime = Math.Clamp(value, 0.01f, 2.0f);
	}

	/// Feedback amount (0.0 to 0.95). Higher = more echoes.
	public float Feedback
	{
		get => mFeedback;
		set => mFeedback = Math.Clamp(value, 0.0f, 0.95f);
	}

	/// Wet/dry mix (0.0 = dry only, 1.0 = wet only).
	public float WetDryMix
	{
		get => mWetDryMix;
		set => mWetDryMix = Math.Clamp(value, 0.0f, 1.0f);
	}

	public void Process(float* buffer, int32 frameCount, int32 sampleRate)
	{
		EnsureBuffer(sampleRate);

		let delaySamples = (int32)(mDelayTime * sampleRate) * 2; // stereo
		let sampleCount = frameCount * 2;

		for (int32 i = 0; i < sampleCount; i++)
		{
			let readPos = (mWritePos - delaySamples + mBufferSize) % mBufferSize;
			let delayed = mBuffer[readPos];

			// Write current + feedback into delay buffer
			mBuffer[mWritePos] = buffer[i] + delayed * mFeedback;

			// Mix wet/dry
			buffer[i] = buffer[i] * (1.0f - mWetDryMix) + delayed * mWetDryMix;

			mWritePos = (mWritePos + 1) % mBufferSize;
		}
	}

	public void Reset()
	{
		if (mBuffer != null)
			Internal.MemSet(mBuffer, 0, mBufferSize * sizeof(float));
		mWritePos = 0;
	}

	public ~this()
	{
		Dispose();
	}

	public void Dispose()
	{
		if (mBuffer != null)
		{
			delete mBuffer;
			mBuffer = null;
		}
	}

	private void EnsureBuffer(int32 sampleRate)
	{
		if (sampleRate == mLastSampleRate && mBuffer != null)
			return;

		mLastSampleRate = sampleRate;

		// Max 2 seconds of stereo delay
		let needed = sampleRate * 2 * 2; // 2 seconds * 2 channels
		if (mBuffer != null)
			delete mBuffer;

		mBuffer = new float[needed]*;
		mBufferSize = needed;
		Internal.MemSet(mBuffer, 0, needed * sizeof(float));
		mWritePos = 0;
	}
}
