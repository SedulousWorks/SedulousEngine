namespace Sedulous.Audio.Effects.Tests;

using System;
using Sedulous.Audio.Effects;

class CompressorEffectTests
{
	[Test]
	public static void BelowThreshold_Unchanged()
	{
		let comp = scope CompressorEffect();
		comp.ThresholdDb = -10.0f;
		comp.Ratio = 4.0f;
		comp.AttackMs = 0.1f;
		comp.MakeupGainDb = 0.0f;

		// Quiet signal (well below threshold)
		let frames = (int32)1024;
		let buf = scope float[frames * 2]*;
		for (int i = 0; i < frames * 2; i++)
			buf[i] = 0.01f; // very quiet

		let original = scope float[frames * 2]*;
		Internal.MemCpy(original, buf, frames * 2 * sizeof(float));

		comp.Process(buf, frames, 48000);

		// Should be mostly unchanged
		for (int i = 0; i < frames * 2; i++)
			Test.Assert(Math.Abs(buf[i] - original[i]) < 0.01f);
	}

	[Test]
	public static void AboveThreshold_Reduced()
	{
		let comp = scope CompressorEffect();
		comp.ThresholdDb = -20.0f;
		comp.Ratio = 10.0f;
		comp.AttackMs = 0.1f; // very fast attack
		comp.ReleaseMs = 1.0f;
		comp.MakeupGainDb = 0.0f;

		// Loud signal (above threshold)
		let frames = (int32)2048;
		let buf = scope float[frames * 2]*;
		for (int i = 0; i < frames * 2; i++)
			buf[i] = 0.8f;

		comp.Process(buf, frames, 48000);

		// Later samples should be reduced (after attack settles)
		let lateSample = Math.Abs(buf[2000 * 2]);
		Test.Assert(lateSample < 0.8f);
	}

	[Test]
	public static void MakeupGain_BoostsOutput()
	{
		let comp = scope CompressorEffect();
		comp.ThresholdDb = 0.0f; // won't compress
		comp.Ratio = 1.0f;
		comp.MakeupGainDb = 6.0f; // ~2x boost

		let frames = (int32)1024;
		let buf = scope float[frames * 2]*;
		for (int i = 0; i < frames * 2; i++)
			buf[i] = 0.3f;

		comp.Process(buf, frames, 48000);

		// Should be boosted
		let sample = buf[500 * 2];
		Test.Assert(sample > 0.3f);
	}

	[Test]
	public static void Reset_ClearsEnvelope()
	{
		let comp = scope CompressorEffect();
		comp.ThresholdDb = -20.0f;
		comp.Ratio = 4.0f;
		comp.AttackMs = 0.1f;

		let frames = (int32)1024;
		let buf = scope float[frames * 2]*;
		for (int i = 0; i < frames * 2; i++)
			buf[i] = 0.8f;
		comp.Process(buf, frames, 48000);

		comp.Reset();

		// After reset, quiet signal should pass through unchanged
		for (int i = 0; i < frames * 2; i++)
			buf[i] = 0.01f;
		comp.Process(buf, frames, 48000);

		for (int i = 0; i < frames * 2; i++)
			Test.Assert(Math.Abs(buf[i] - 0.01f) < 0.01f);
	}
}
