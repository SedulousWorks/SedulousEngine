namespace Sedulous.Audio.Effects.Tests;

using System;
using Sedulous.Audio.Effects;

class ParametricEQTests
{
	static void FillSine(float* buf, int32 frames, int32 sampleRate, float freqHz, float amplitude = 1.0f)
	{
		for (int32 i = 0; i < frames; i++)
		{
			let sample = amplitude * Math.Sin(2.0f * Math.PI_f * freqHz * (float)i / (float)sampleRate);
			buf[i * 2] = sample;
			buf[i * 2 + 1] = sample;
		}
	}

	static float ComputeRMS(float* buf, int32 frames)
	{
		float sum = 0;
		for (int32 i = 0; i < frames; i++)
		{
			let s = buf[i * 2];
			sum += s * s;
		}
		return Math.Sqrt(sum / (float)frames);
	}

	[Test]
	public static void FlatGains_IsPassthrough()
	{
		let eq = scope ParametricEQ();
		// Default gains are 0 dB - should be passthrough

		let frames = (int32)2048;
		let buf = scope float[frames * 2]*;
		FillSine(buf, frames, 48000, 1000.0f);

		let rmsBefore = ComputeRMS(buf, frames);
		eq.Process(buf, frames, 48000);
		let rmsAfter = ComputeRMS(buf, frames);

		// Should be essentially unchanged
		Test.Assert(Math.Abs(rmsAfter - rmsBefore) < 0.01f);
	}

	[Test]
	public static void BoostedBand_IncreasesLevel()
	{
		let eq = scope ParametricEQ();
		eq.Mid = .() { FrequencyHz = 1000.0f, GainDb = 12.0f, Q = 1.0f };
		eq.MarkDirty();

		let frames = (int32)4096;
		let buf = scope float[frames * 2]*;
		FillSine(buf, frames, 48000, 1000.0f, 0.3f);

		let rmsBefore = ComputeRMS(buf, frames);
		eq.Process(buf, frames, 48000);
		let rmsAfter = ComputeRMS(buf, frames);

		// Boosted by 12 dB should roughly quadruple amplitude
		Test.Assert(rmsAfter > rmsBefore * 2.0f);
	}

	[Test]
	public static void CutBand_DecreasesLevel()
	{
		let eq = scope ParametricEQ();
		eq.Mid = .() { FrequencyHz = 1000.0f, GainDb = -12.0f, Q = 1.0f };
		eq.MarkDirty();

		let frames = (int32)4096;
		let buf = scope float[frames * 2]*;
		FillSine(buf, frames, 48000, 1000.0f, 0.5f);

		let rmsBefore = ComputeRMS(buf, frames);
		eq.Process(buf, frames, 48000);
		let rmsAfter = ComputeRMS(buf, frames);

		Test.Assert(rmsAfter < rmsBefore * 0.5f);
	}

	[Test]
	public static void BandsAreIndependent()
	{
		let eq = scope ParametricEQ();
		eq.Low = .() { FrequencyHz = 200.0f, GainDb = 6.0f, Q = 0.707f };
		eq.Mid = .() { FrequencyHz = 1000.0f, GainDb = 0.0f, Q = 1.0f }; // flat
		eq.High = .() { FrequencyHz = 5000.0f, GainDb = -6.0f, Q = 0.707f };
		eq.MarkDirty();

		// A 1000 Hz tone should be mostly unaffected (mid band is flat)
		let frames = (int32)4096;
		let buf = scope float[frames * 2]*;
		FillSine(buf, frames, 48000, 1000.0f, 0.5f);

		let rmsBefore = ComputeRMS(buf, frames);
		eq.Process(buf, frames, 48000);
		let rmsAfter = ComputeRMS(buf, frames);

		// Should be close to original (mid band is 0 dB)
		Test.Assert(Math.Abs(rmsAfter - rmsBefore) / rmsBefore < 0.3f);
	}
}
