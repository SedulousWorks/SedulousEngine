namespace Sedulous.Audio.Effects;

using System;
using Sedulous.Audio;

/// Low-pass filter driven by an external distance parameter.
/// Used for 3D audio distance-based muffling. The cutoff frequency
/// is set externally by the 3D audio system based on source distance.
public class DistanceLowPassFilter : IAudioEffect
{
	private float mCutoffHz = 22050.0f;
	private float mResonance = 0.707f;
	private bool mEnabled = true;
	private bool mDirty = true;

	// Biquad coefficients
	private float mB0, mB1, mB2, mA1, mA2;

	// Per-channel state
	private float[2] mX1, mX2;
	private float[2] mY1, mY2;

	private int32 mLastSampleRate;

	public StringView Name => "DistanceLowPass";

	public bool Enabled
	{
		get => mEnabled;
		set => mEnabled = value;
	}

	/// Current cutoff frequency. Set by the 3D audio system based on distance.
	/// At close range this should be ~22050 Hz (no filtering).
	/// At far range this should be the attenuator's MaxDistanceLowPassHz.
	public float CutoffHz
	{
		get => mCutoffHz;
		set
		{
			let clamped = Math.Clamp(value, 20.0f, 22050.0f);
			if (clamped != mCutoffHz)
			{
				mCutoffHz = clamped;
				mDirty = true;
			}
		}
	}

	public void Process(float* buffer, int32 frameCount, int32 sampleRate)
	{
		// Skip if cutoff is at or near Nyquist (no filtering needed)
		if (mCutoffHz >= 20000.0f)
			return;

		if (mDirty || sampleRate != mLastSampleRate)
		{
			ComputeCoefficients(sampleRate);
			mDirty = false;
			mLastSampleRate = sampleRate;
		}

		for (int32 i = 0; i < frameCount; i++)
		{
			for (int ch = 0; ch < 2; ch++)
			{
				let idx = i * 2 + ch;
				let x0 = buffer[idx];

				let y0 = mB0 * x0 + mB1 * mX1[ch] + mB2 * mX2[ch]
					- mA1 * mY1[ch] - mA2 * mY2[ch];

				mX2[ch] = mX1[ch];
				mX1[ch] = x0;
				mY2[ch] = mY1[ch];
				mY1[ch] = y0;

				buffer[idx] = y0;
			}
		}
	}

	public void Reset()
	{
		mX1 = default;
		mX2 = default;
		mY1 = default;
		mY2 = default;
		mDirty = true;
	}

	public void Dispose() { }

	private void ComputeCoefficients(int32 sampleRate)
	{
		let omega = 2.0f * Math.PI_f * mCutoffHz / (float)sampleRate;
		let sinOmega = Math.Sin(omega);
		let cosOmega = Math.Cos(omega);
		let alpha = sinOmega / (2.0f * mResonance);

		let a0 = 1.0f + alpha;
		mB0 = ((1.0f - cosOmega) / 2.0f) / a0;
		mB1 = (1.0f - cosOmega) / a0;
		mB2 = mB0;
		mA1 = (-2.0f * cosOmega) / a0;
		mA2 = (1.0f - alpha) / a0;
	}
}
