namespace Sedulous.Audio.Effects;

using System;
using Sedulous.Audio;

/// Dynamics compressor. Reduces dynamic range above the threshold.
public class CompressorEffect : IAudioEffect
{
	private float mThresholdDb = -20.0f;
	private float mRatio = 4.0f;
	private float mAttackMs = 10.0f;
	private float mReleaseMs = 100.0f;
	private float mMakeupGainDb = 0.0f;
	private bool mEnabled = true;

	// Envelope follower state
	private float mEnvelope;

	public StringView Name => "Compressor";

	public bool Enabled
	{
		get => mEnabled;
		set => mEnabled = value;
	}

	/// Threshold in dB (-60 to 0). Compression begins above this level.
	public float ThresholdDb
	{
		get => mThresholdDb;
		set => mThresholdDb = Math.Clamp(value, -60.0f, 0.0f);
	}

	/// Compression ratio (1.0 to 20.0). 1:1 = no compression, higher = more.
	public float Ratio
	{
		get => mRatio;
		set => mRatio = Math.Clamp(value, 1.0f, 20.0f);
	}

	/// Attack time in milliseconds. How fast compression engages.
	public float AttackMs
	{
		get => mAttackMs;
		set => mAttackMs = Math.Max(value, 0.1f);
	}

	/// Release time in milliseconds. How fast compression releases.
	public float ReleaseMs
	{
		get => mReleaseMs;
		set => mReleaseMs = Math.Max(value, 1.0f);
	}

	/// Makeup gain in dB to compensate for volume reduction.
	public float MakeupGainDb
	{
		get => mMakeupGainDb;
		set => mMakeupGainDb = Math.Clamp(value, -12.0f, 24.0f);
	}

	public void Process(float* buffer, int32 frameCount, int32 sampleRate)
	{
		let attackCoeff = Math.Exp(-1.0f / ((float)sampleRate * mAttackMs * 0.001f));
		let releaseCoeff = Math.Exp(-1.0f / ((float)sampleRate * mReleaseMs * 0.001f));
		let thresholdLinear = DbToLinear(mThresholdDb);
		let makeupLinear = DbToLinear(mMakeupGainDb);

		for (int32 i = 0; i < frameCount; i++)
		{
			// Peak detection across stereo channels
			let l = Math.Abs(buffer[i * 2]);
			let r = Math.Abs(buffer[i * 2 + 1]);
			let peak = Math.Max(l, r);

			// Envelope follower
			if (peak > mEnvelope)
				mEnvelope = attackCoeff * mEnvelope + (1.0f - attackCoeff) * peak;
			else
				mEnvelope = releaseCoeff * mEnvelope + (1.0f - releaseCoeff) * peak;

			// Compute gain reduction
			float gain = 1.0f;
			if (mEnvelope > thresholdLinear && mEnvelope > 0.0001f)
			{
				let dbOver = LinearToDb(mEnvelope) - mThresholdDb;
				let dbReduction = dbOver * (1.0f - 1.0f / mRatio);
				gain = DbToLinear(-dbReduction);
			}

			gain *= makeupLinear;

			buffer[i * 2] *= gain;
			buffer[i * 2 + 1] *= gain;
		}
	}

	public void Reset()
	{
		mEnvelope = 0;
	}

	public void Dispose() { }

	private static float DbToLinear(float db) => Math.Pow(10.0f, db / 20.0f);
	private static float LinearToDb(float linear) => 20.0f * Math.Log10(Math.Max(linear, 0.0001f));
}
