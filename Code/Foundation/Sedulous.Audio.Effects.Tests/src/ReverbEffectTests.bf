namespace Sedulous.Audio.Effects.Tests;

using System;
using Sedulous.Audio.Effects;

class ReverbEffectTests
{
	[Test]
	public static void WetDryMix_0_IsPassthrough()
	{
		let reverb = scope ReverbEffect();
		reverb.WetDryMix = 0.0f;

		let frames = (int32)1024;
		let buf = scope float[frames * 2]*;
		buf[0] = 1.0f;
		buf[1] = 1.0f;

		let original = scope float[frames * 2]*;
		Internal.MemCpy(original, buf, frames * 2 * sizeof(float));

		reverb.Process(buf, frames, 48000);

		for (int i = 0; i < frames * 2; i++)
			Test.Assert(Math.Abs(buf[i] - original[i]) < 0.001f);
	}

	[Test]
	public static void Impulse_ProducesTail()
	{
		let reverb = scope ReverbEffect();
		reverb.RoomSize = 0.8f;
		reverb.WetDryMix = 1.0f;

		let frames = (int32)4096;
		let buf = scope float[frames * 2]*;
		buf[0] = 1.0f;
		buf[1] = 1.0f;

		reverb.Process(buf, frames, 48000);

		// Check that there's signal in the tail (late samples)
		float tailEnergy = 0;
		for (int32 i = 2000; i < 4000; i++)
		{
			tailEnergy += buf[i * 2] * buf[i * 2];
		}

		// Should have some reverb tail energy
		Test.Assert(tailEnergy > 0.0001f);
	}

	[Test]
	public static void Reset_ClearsTail()
	{
		let reverb = scope ReverbEffect();
		reverb.RoomSize = 0.8f;
		reverb.WetDryMix = 1.0f;

		let frames = (int32)1024;
		let buf = scope float[frames * 2]*;
		buf[0] = 1.0f;
		buf[1] = 1.0f;
		reverb.Process(buf, frames, 48000);

		reverb.Reset();

		// Process silence - should get silence (no leftover tail)
		Internal.MemSet(buf, 0, frames * 2 * sizeof(float));
		reverb.Process(buf, frames, 48000);

		float energy = 0;
		for (int i = 0; i < frames * 2; i++)
			energy += buf[i] * buf[i];

		Test.Assert(energy < 0.001f);
	}
}
