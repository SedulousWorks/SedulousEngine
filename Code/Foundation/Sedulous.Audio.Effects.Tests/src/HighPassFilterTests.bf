namespace Sedulous.Audio.Effects.Tests;

using System;
using Sedulous.Audio.Effects;

class HighPassFilterTests
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
	public static void LowFrequency_Attenuated()
	{
		let filter = scope HighPassFilter();
		filter.CutoffHz = 5000.0f;

		let frames = (int32)4096;
		let buf = scope float[frames * 2]*;
		FillSine(buf, frames, 48000, 100.0f);

		let rmsBefore = ComputeRMS(buf, frames);
		filter.Process(buf, frames, 48000);
		let rmsAfter = ComputeRMS(buf, frames);

		Test.Assert(rmsAfter < rmsBefore * 0.2f);
	}

	[Test]
	public static void HighFrequency_PassesThrough()
	{
		let filter = scope HighPassFilter();
		filter.CutoffHz = 200.0f;

		let frames = (int32)4096;
		let buf = scope float[frames * 2]*;
		FillSine(buf, frames, 48000, 5000.0f);

		let rmsBefore = ComputeRMS(buf, frames);
		filter.Process(buf, frames, 48000);
		let rmsAfter = ComputeRMS(buf, frames);

		Test.Assert(rmsAfter > rmsBefore * 0.8f);
	}
}
