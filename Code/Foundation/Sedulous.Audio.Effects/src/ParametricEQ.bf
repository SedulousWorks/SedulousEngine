namespace Sedulous.Audio.Effects;

using System;
using Sedulous.Audio;

/// 3-band parametric equalizer: low shelf, mid peak, high shelf.
/// Each band is a biquad filter with frequency, gain, and Q controls.
public class ParametricEQ : IAudioEffect
{
	/// A single EQ band with its own biquad state.
	public struct Band
	{
		public float FrequencyHz;
		public float GainDb;
		public float Q;
	}

	private Band mLow = .() { FrequencyHz = 200.0f, GainDb = 0.0f, Q = 0.707f };
	private Band mMid = .() { FrequencyHz = 1000.0f, GainDb = 0.0f, Q = 1.0f };
	private Band mHigh = .() { FrequencyHz = 5000.0f, GainDb = 0.0f, Q = 0.707f };
	private bool mEnabled = true;
	private bool mDirty = true;
	private int32 mLastSampleRate;

	// 3 biquads * 2 channels = 6 filter states
	private float[6] mB0, mB1, mB2, mA1, mA2;
	private float[6] mX1, mX2, mY1, mY2;

	public StringView Name => "ParametricEQ";

	public bool Enabled
	{
		get => mEnabled;
		set => mEnabled = value;
	}

	/// Low shelf band.
	public ref Band Low { get mut => ref mLow; }

	/// Mid peak band.
	public ref Band Mid { get mut => ref mMid; }

	/// High shelf band.
	public ref Band High { get mut => ref mHigh; }

	/// Call after changing band parameters.
	public void MarkDirty() { mDirty = true; }

	public void Process(float* buffer, int32 frameCount, int32 sampleRate)
	{
		if (mDirty || sampleRate != mLastSampleRate)
		{
			ComputeAllCoefficients(sampleRate);
			mDirty = false;
			mLastSampleRate = sampleRate;
		}

		// Skip if all gains are 0 dB (passthrough)
		if (mLow.GainDb == 0 && mMid.GainDb == 0 && mHigh.GainDb == 0)
			return;

		for (int32 i = 0; i < frameCount; i++)
		{
			for (int ch = 0; ch < 2; ch++)
			{
				let idx = i * 2 + ch;
				var sample = buffer[idx];

				// Cascade through 3 biquads
				for (int band = 0; band < 3; band++)
				{
					let fi = band * 2 + ch;
					let x0 = sample;

					let y0 = mB0[fi] * x0 + mB1[fi] * mX1[fi] + mB2[fi] * mX2[fi]
						- mA1[fi] * mY1[fi] - mA2[fi] * mY2[fi];

					mX2[fi] = mX1[fi];
					mX1[fi] = x0;
					mY2[fi] = mY1[fi];
					mY1[fi] = y0;

					sample = y0;
				}

				buffer[idx] = sample;
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

	private void ComputeAllCoefficients(int32 sampleRate)
	{
		ComputeLowShelf(mLow, sampleRate, 0);
		ComputeLowShelf(mLow, sampleRate, 1);
		ComputePeaking(mMid, sampleRate, 2);
		ComputePeaking(mMid, sampleRate, 3);
		ComputeHighShelf(mHigh, sampleRate, 4);
		ComputeHighShelf(mHigh, sampleRate, 5);
	}

	private void ComputeLowShelf(Band band, int32 sampleRate, int fi)
	{
		let A = Math.Pow(10.0f, band.GainDb / 40.0f);
		let omega = 2.0f * Math.PI_f * band.FrequencyHz / (float)sampleRate;
		let sinO = Math.Sin(omega);
		let cosO = Math.Cos(omega);
		let alpha = sinO / (2.0f * band.Q);
		let sqrtA = Math.Sqrt(A);

		let a0 = (A + 1) + (A - 1) * cosO + 2 * sqrtA * alpha;
		mB0[fi] = (A * ((A + 1) - (A - 1) * cosO + 2 * sqrtA * alpha)) / a0;
		mB1[fi] = (2 * A * ((A - 1) - (A + 1) * cosO)) / a0;
		mB2[fi] = (A * ((A + 1) - (A - 1) * cosO - 2 * sqrtA * alpha)) / a0;
		mA1[fi] = (-2 * ((A - 1) + (A + 1) * cosO)) / a0;
		mA2[fi] = ((A + 1) + (A - 1) * cosO - 2 * sqrtA * alpha) / a0;
	}

	private void ComputePeaking(Band band, int32 sampleRate, int fi)
	{
		let A = Math.Pow(10.0f, band.GainDb / 40.0f);
		let omega = 2.0f * Math.PI_f * band.FrequencyHz / (float)sampleRate;
		let sinO = Math.Sin(omega);
		let cosO = Math.Cos(omega);
		let alpha = sinO / (2.0f * band.Q);

		let a0 = 1 + alpha / A;
		mB0[fi] = (1 + alpha * A) / a0;
		mB1[fi] = (-2 * cosO) / a0;
		mB2[fi] = (1 - alpha * A) / a0;
		mA1[fi] = (-2 * cosO) / a0;
		mA2[fi] = (1 - alpha / A) / a0;
	}

	private void ComputeHighShelf(Band band, int32 sampleRate, int fi)
	{
		let A = Math.Pow(10.0f, band.GainDb / 40.0f);
		let omega = 2.0f * Math.PI_f * band.FrequencyHz / (float)sampleRate;
		let sinO = Math.Sin(omega);
		let cosO = Math.Cos(omega);
		let alpha = sinO / (2.0f * band.Q);
		let sqrtA = Math.Sqrt(A);

		let a0 = (A + 1) - (A - 1) * cosO + 2 * sqrtA * alpha;
		mB0[fi] = (A * ((A + 1) + (A - 1) * cosO + 2 * sqrtA * alpha)) / a0;
		mB1[fi] = (-2 * A * ((A - 1) + (A + 1) * cosO)) / a0;
		mB2[fi] = (A * ((A + 1) + (A - 1) * cosO - 2 * sqrtA * alpha)) / a0;
		mA1[fi] = (2 * ((A - 1) - (A + 1) * cosO)) / a0;
		mA2[fi] = ((A + 1) - (A - 1) * cosO - 2 * sqrtA * alpha) / a0;
	}
}
