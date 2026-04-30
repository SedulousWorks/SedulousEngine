namespace Sedulous.Audio.Effects.Tests;

using System;
using Sedulous.Audio.Effects;

class LowPassFilterTests
{
	/// Generates a buffer of constant-value stereo samples.
	static void FillConstant(float* buf, int32 frames, float value)
	{
		for (int i = 0; i < frames * 2; i++)
			buf[i] = value;
	}

	/// Generates a sine wave at the given frequency into a stereo buffer.
	static void FillSine(float* buf, int32 frames, int32 sampleRate, float freqHz, float amplitude = 1.0f)
	{
		for (int32 i = 0; i < frames; i++)
		{
			let sample = amplitude * Math.Sin(2.0f * Math.PI_f * freqHz * (float)i / (float)sampleRate);
			buf[i * 2] = sample;
			buf[i * 2 + 1] = sample;
		}
	}

	/// Computes RMS of a stereo buffer (left channel only for simplicity).
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
	public static void HighFrequency_Attenuated()
	{
		let filter = scope LowPassFilter();
		filter.CutoffHz = 500.0f;

		// Generate a 5000 Hz tone (well above cutoff)
		let frames = (int32)4096;
		let buf = scope float[frames * 2]*;
		FillSine(buf, frames, 48000, 5000.0f);

		let rmsBefore = ComputeRMS(buf, frames);

		filter.Process(buf, frames, 48000);

		let rmsAfter = ComputeRMS(buf, frames);

		// High frequency should be significantly attenuated
		Test.Assert(rmsAfter < rmsBefore * 0.2f);
	}

	[Test]
	public static void LowFrequency_PassesThrough()
	{
		let filter = scope LowPassFilter();
		filter.CutoffHz = 5000.0f;

		// Generate a 100 Hz tone (well below cutoff)
		let frames = (int32)4096;
		let buf = scope float[frames * 2]*;
		FillSine(buf, frames, 48000, 100.0f);

		let rmsBefore = ComputeRMS(buf, frames);

		filter.Process(buf, frames, 48000);

		let rmsAfter = ComputeRMS(buf, frames);

		// Low frequency should pass mostly unchanged
		Test.Assert(rmsAfter > rmsBefore * 0.8f);
	}

	[Test]
	public static void Reset_ClearsState()
	{
		let filter = scope LowPassFilter();
		filter.CutoffHz = 500.0f;

		let frames = (int32)256;
		let buf = scope float[frames * 2]*;
		FillSine(buf, frames, 48000, 5000.0f);
		filter.Process(buf, frames, 48000);

		filter.Reset();

		// After reset, processing a zero buffer should produce zeros (no artifacts from old state)
		FillConstant(buf, frames, 0.0f);
		filter.Process(buf, frames, 48000);

		for (int i = 0; i < frames * 2; i++)
			Test.Assert(Math.Abs(buf[i]) < 0.001f);
	}
}
