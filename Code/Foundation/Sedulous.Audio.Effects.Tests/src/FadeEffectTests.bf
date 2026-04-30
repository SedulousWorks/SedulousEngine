namespace Sedulous.Audio.Effects.Tests;

using System;
using Sedulous.Audio.Effects;

class FadeEffectTests
{
	[Test]
	public static void FadeOut_ReducesVolume()
	{
		let fade = scope FadeEffect();
		fade.StartFade(0.0f, 0.1f); // fade to 0 over 100ms

		let frames = (int32)4800; // 100ms at 48kHz
		let buf = scope float[frames * 2]*;
		for (int i = 0; i < frames * 2; i++)
			buf[i] = 1.0f;

		fade.Process(buf, frames, 48000);

		// First sample should be near 1.0
		Test.Assert(buf[0] > 0.9f);

		// Last sample should be near 0.0
		Test.Assert(Math.Abs(buf[(frames - 1) * 2]) < 0.05f);
	}

	[Test]
	public static void FadeIn_IncreasesVolume()
	{
		let fade = scope FadeEffect();
		fade.Reset();
		// Start from 0
		fade.StartFade(0.0f, 0.001f); // instant to 0
		let tiny = scope float[96]*;
		for (int i = 0; i < 96; i++) tiny[i] = 1.0f;
		fade.Process(tiny, 48, 48000);

		// Now fade up to 1
		fade.StartFade(1.0f, 0.1f);

		let frames = (int32)4800;
		let buf = scope float[frames * 2]*;
		for (int i = 0; i < frames * 2; i++)
			buf[i] = 1.0f;

		fade.Process(buf, frames, 48000);

		// Last sample should be near 1.0
		Test.Assert(buf[(frames - 1) * 2] > 0.9f);
	}

	[Test]
	public static void HoldsAtTarget()
	{
		let fade = scope FadeEffect();
		fade.StartFade(0.5f, 0.01f); // very short fade

		// Process enough to complete the fade
		let frames = (int32)1024;
		let buf = scope float[frames * 2]*;
		for (int i = 0; i < frames * 2; i++)
			buf[i] = 1.0f;
		fade.Process(buf, frames, 48000);

		Test.Assert(!fade.IsFading);
		Test.Assert(Math.Abs(fade.CurrentVolume - 0.5f) < 0.01f);

		// Process more - should stay at 0.5
		for (int i = 0; i < frames * 2; i++)
			buf[i] = 1.0f;
		fade.Process(buf, frames, 48000);

		for (int i = 0; i < frames * 2; i++)
			Test.Assert(Math.Abs(buf[i] - 0.5f) < 0.01f);
	}

	[Test]
	public static void Reset_RestoresToOne()
	{
		let fade = scope FadeEffect();
		fade.StartFade(0.0f, 1.0f);

		let frames = (int32)1024;
		let buf = scope float[frames * 2]*;
		for (int i = 0; i < frames * 2; i++)
			buf[i] = 1.0f;
		fade.Process(buf, frames, 48000);

		fade.Reset();

		Test.Assert(Math.Abs(fade.CurrentVolume - 1.0f) < 0.001f);
		Test.Assert(!fade.IsFading);
	}
}
