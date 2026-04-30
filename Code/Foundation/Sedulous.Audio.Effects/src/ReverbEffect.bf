namespace Sedulous.Audio.Effects;

using System;
using Sedulous.Audio;

/// Schroeder reverb: 4 parallel comb filters + 2 series allpass filters.
public class ReverbEffect : IAudioEffect
{
	private float mRoomSize = 0.5f;
	private float mDamping = 0.5f;
	private float mWetDryMix = 0.3f;
	private bool mEnabled = true;

	// Comb filter delay lines (per channel)
	private float*[8] mCombBuffers;   // 4 combs * 2 channels
	private int32[8] mCombSizes;
	private int32[8] mCombPos;
	private float[8] mCombFilterState; // for damping

	// Allpass delay lines (per channel)
	private float*[4] mAllpassBuffers; // 2 allpass * 2 channels
	private int32[4] mAllpassSizes;
	private int32[4] mAllpassPos;

	private int32 mLastSampleRate;
	private bool mInitialized;

	// Comb delay lengths in samples at 44100Hz (Schroeder standard values)
	private static readonly int32[4] sCombDelays = .(1116, 1188, 1277, 1356);
	private static readonly int32[2] sAllpassDelays = .(225, 556);

	public StringView Name => "Reverb";

	public bool Enabled
	{
		get => mEnabled;
		set => mEnabled = value;
	}

	/// Room size (0.0 to 1.0). Affects comb filter feedback.
	public float RoomSize
	{
		get => mRoomSize;
		set => mRoomSize = Math.Clamp(value, 0.0f, 1.0f);
	}

	/// Damping (0.0 to 1.0). Higher = more high-frequency absorption.
	public float Damping
	{
		get => mDamping;
		set => mDamping = Math.Clamp(value, 0.0f, 1.0f);
	}

	/// Wet/dry mix (0.0 = dry only, 1.0 = wet only).
	public float WetDryMix
	{
		get => mWetDryMix;
		set => mWetDryMix = Math.Clamp(value, 0.0f, 1.0f);
	}

	public void Process(float* buffer, int32 frameCount, int32 sampleRate)
	{
		EnsureInitialized(sampleRate);

		let feedback = mRoomSize * 0.9f + 0.1f; // map 0-1 to 0.1-1.0
		let damp = mDamping;

		for (int32 i = 0; i < frameCount; i++)
		{
			for (int ch = 0; ch < 2; ch++)
			{
				let idx = i * 2 + ch;
				let input = buffer[idx];
				float combOut = 0;

				// 4 parallel comb filters
				for (int c = 0; c < 4; c++)
				{
					let ci = c * 2 + ch;
					let delayed = mCombBuffers[ci][mCombPos[ci]];

					// One-pole low-pass for damping
					mCombFilterState[ci] = delayed * (1.0f - damp) + mCombFilterState[ci] * damp;

					mCombBuffers[ci][mCombPos[ci]] = input + mCombFilterState[ci] * feedback;
					mCombPos[ci] = (mCombPos[ci] + 1) % mCombSizes[ci];

					combOut += delayed;
				}

				combOut *= 0.25f; // average 4 combs

				// 2 series allpass filters
				float apOut = combOut;
				for (int a = 0; a < 2; a++)
				{
					let ai = a * 2 + ch;
					let delayed = mAllpassBuffers[ai][mAllpassPos[ai]];
					let apFeedback = 0.5f;

					mAllpassBuffers[ai][mAllpassPos[ai]] = apOut + delayed * apFeedback;
					apOut = delayed - apOut * apFeedback;
					mAllpassPos[ai] = (mAllpassPos[ai] + 1) % mAllpassSizes[ai];
				}

				buffer[idx] = input * (1.0f - mWetDryMix) + apOut * mWetDryMix;
			}
		}
	}

	public void Reset()
	{
		for (int i = 0; i < 8; i++)
		{
			if (mCombBuffers[i] != null)
				Internal.MemSet(mCombBuffers[i], 0, mCombSizes[i] * sizeof(float));
			mCombPos[i] = 0;
			mCombFilterState[i] = 0;
		}
		for (int i = 0; i < 4; i++)
		{
			if (mAllpassBuffers[i] != null)
				Internal.MemSet(mAllpassBuffers[i], 0, mAllpassSizes[i] * sizeof(float));
			mAllpassPos[i] = 0;
		}
	}

	public ~this()
	{
		Dispose();
	}

	public void Dispose()
	{
		for (int i = 0; i < 8; i++)
		{
			if (mCombBuffers[i] != null)
			{
				delete mCombBuffers[i];
				mCombBuffers[i] = null;
			}
		}
		for (int i = 0; i < 4; i++)
		{
			if (mAllpassBuffers[i] != null)
			{
				delete mAllpassBuffers[i];
				mAllpassBuffers[i] = null;
			}
		}
	}

	private void EnsureInitialized(int32 sampleRate)
	{
		if (mInitialized && sampleRate == mLastSampleRate)
			return;

		Dispose(); // free old buffers

		let scale = (float)sampleRate / 44100.0f;

		for (int c = 0; c < 4; c++)
		{
			for (int ch = 0; ch < 2; ch++)
			{
				let ci = c * 2 + ch;
				// Slightly offset right channel for stereo width
				let offset = (ch == 1) ? 23 : 0;
				mCombSizes[ci] = (int32)((sCombDelays[c] + offset) * scale);
				mCombBuffers[ci] = new float[mCombSizes[ci]]*;
				Internal.MemSet(mCombBuffers[ci], 0, mCombSizes[ci] * sizeof(float));
				mCombPos[ci] = 0;
			}
		}

		for (int a = 0; a < 2; a++)
		{
			for (int ch = 0; ch < 2; ch++)
			{
				let ai = a * 2 + ch;
				mAllpassSizes[ai] = (int32)(sAllpassDelays[a] * scale);
				mAllpassBuffers[ai] = new float[mAllpassSizes[ai]]*;
				Internal.MemSet(mAllpassBuffers[ai], 0, mAllpassSizes[ai] * sizeof(float));
				mAllpassPos[ai] = 0;
			}
		}

		mCombFilterState = default;
		mLastSampleRate = sampleRate;
		mInitialized = true;
	}
}
