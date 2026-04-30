namespace Sedulous.Audio.Effects.Tests;

using System;
using Sedulous.Audio.Effects;

class DelayEffectTests
{
	[Test]
	public static void WetDryMix_0_IsPassthrough()
	{
		let delay = scope DelayEffect();
		delay.DelayTime = 0.1f;
		delay.Feedback = 0.0f;
		delay.WetDryMix = 0.0f;

		let frames = (int32)1024;
		let buf = scope float[frames * 2]*;
		// Impulse at frame 0
		buf[0] = 1.0f;
		buf[1] = 1.0f;

		let original = scope float[frames * 2]*;
		Internal.MemCpy(original, buf, frames * 2 * sizeof(float));

		delay.Process(buf, frames, 48000);

		// Should be unchanged (dry only)
		for (int i = 0; i < frames * 2; i++)
			Test.Assert(Math.Abs(buf[i] - original[i]) < 0.001f);
	}

	[Test]
	public static void DelayedSignal_AppearsLater()
	{
		let delay = scope DelayEffect();
		delay.DelayTime = 0.01f; // 10ms = 480 frames at 48kHz
		delay.Feedback = 0.0f;
		delay.WetDryMix = 1.0f; // fully wet

		let frames = (int32)2048;
		let buf = scope float[frames * 2]*;
		// Impulse at frame 0
		buf[0] = 1.0f;
		buf[1] = 1.0f;

		delay.Process(buf, frames, 48000);

		// The echo should appear around frame 480
		// Frame 0 should be 0 (wet only, no delay yet)
		Test.Assert(Math.Abs(buf[0]) < 0.01f);

		// Around frame 480 there should be signal
		let echoFrame = 480;
		let echoSample = Math.Abs(buf[echoFrame * 2]);
		Test.Assert(echoSample > 0.5f);
	}

	[Test]
	public static void Feedback_ProducesMultipleEchoes()
	{
		let delay = scope DelayEffect();
		delay.DelayTime = 0.01f;
		delay.Feedback = 0.5f;
		delay.WetDryMix = 1.0f;

		let frames = (int32)4096;
		let buf = scope float[frames * 2]*;
		buf[0] = 1.0f;
		buf[1] = 1.0f;

		delay.Process(buf, frames, 48000);

		// First echo around 480
		let echo1 = Math.Abs(buf[480 * 2]);
		// Second echo around 960 (should be quieter)
		let echo2 = Math.Abs(buf[960 * 2]);

		Test.Assert(echo1 > 0.5f);
		Test.Assert(echo2 > 0.1f);
		Test.Assert(echo2 < echo1); // decaying
	}

	[Test]
	public static void Reset_ClearsDelayBuffer()
	{
		let delay = scope DelayEffect();
		delay.DelayTime = 0.01f;
		delay.Feedback = 0.5f;
		delay.WetDryMix = 1.0f;

		let frames = (int32)1024;
		let buf = scope float[frames * 2]*;
		buf[0] = 1.0f;
		buf[1] = 1.0f;
		delay.Process(buf, frames, 48000);

		delay.Reset();

		// Process silence - should get silence back (no leftover echoes)
		Internal.MemSet(buf, 0, frames * 2 * sizeof(float));
		delay.Process(buf, frames, 48000);

		for (int i = 0; i < frames * 2; i++)
			Test.Assert(Math.Abs(buf[i]) < 0.001f);
	}
}
