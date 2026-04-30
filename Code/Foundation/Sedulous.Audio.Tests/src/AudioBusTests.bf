namespace Sedulous.Audio.Tests;

using System;
using Sedulous.Audio;
using Sedulous.Audio.Graph;

/// Simple test effect that multiplies all samples by a factor.
class ScaleEffect : IAudioEffect
{
	public float Factor = 1.0f;

	public StringView Name => "Scale";
	public bool Enabled { get; set; } = true;

	public void Process(float* buffer, int32 frameCount, int32 sampleRate)
	{
		let count = frameCount * 2;
		for (int i = 0; i < count; i++)
			buffer[i] *= Factor;
	}

	public void Reset() { }
	public void Dispose() { }
}

class AudioBusTests
{
	[Test]
	public static void Bus_HasInputAndOutputNodes()
	{
		let bus = scope AudioBus("TestBus");

		Test.Assert(bus.InputNode != null);
		Test.Assert(bus.OutputNode != null);
		Test.Assert(bus.Name == "TestBus");
	}

	[Test]
	public static void Bus_VolumeControlsOutputNode()
	{
		let bus = scope AudioBus("TestBus");

		bus.Volume = 0.5f;
		Test.Assert(Math.Abs(bus.Volume - 0.5f) < 0.001f);
		Test.Assert(Math.Abs(bus.OutputNode.Volume - 0.5f) < 0.001f);
	}

	[Test]
	public static void Bus_MutedProducesSilence()
	{
		let bus = scope AudioBus("TestBus");

		bus.Muted = true;
		Test.Assert(bus.Muted);
		Test.Assert(!bus.OutputNode.Enabled);

		bus.Muted = false;
		Test.Assert(!bus.Muted);
		Test.Assert(bus.OutputNode.Enabled);
	}

	[Test]
	public static void Bus_AddEffect_InsertsInChain()
	{
		let bus = scope AudioBus("TestBus");

		let effect = new ScaleEffect() { Factor = 0.5f };
		bus.AddEffect(effect);

		Test.Assert(bus.EffectCount == 1);
		Test.Assert(bus.GetEffect(0) == effect);
	}

	[Test]
	public static void Bus_MultipleEffects_AppliedInOrder()
	{
		let bus = scope AudioBus("TestBus");

		let effectA = new ScaleEffect() { Factor = 0.5f };
		let effectB = new ScaleEffect() { Factor = 0.25f };
		bus.AddEffect(effectA);
		bus.AddEffect(effectB);

		Test.Assert(bus.EffectCount == 2);
		Test.Assert(bus.GetEffect(0) == effectA);
		Test.Assert(bus.GetEffect(1) == effectB);
	}

	[Test]
	public static void Bus_InsertEffect_AtBeginning()
	{
		let bus = scope AudioBus("TestBus");

		let effectA = new ScaleEffect() { Factor = 0.5f };
		let effectB = new ScaleEffect() { Factor = 0.25f };
		bus.AddEffect(effectA);
		bus.InsertEffect(0, effectB);

		Test.Assert(bus.EffectCount == 2);
		Test.Assert(bus.GetEffect(0) == effectB);
		Test.Assert(bus.GetEffect(1) == effectA);
	}

	[Test]
	public static void Bus_RemoveEffect_RewiresChain()
	{
		let bus = scope AudioBus("TestBus");

		let effectA = new ScaleEffect() { Factor = 0.5f };
		let effectB = new ScaleEffect() { Factor = 0.25f };
		bus.AddEffect(effectA);
		bus.AddEffect(effectB);

		let removed = bus.RemoveEffect(0);
		Test.Assert(removed == effectA);
		Test.Assert(bus.EffectCount == 1);
		Test.Assert(bus.GetEffect(0) == effectB);

		// Caller owns the removed effect
		removed.Dispose();
		delete removed;
	}

	[Test]
	public static void Bus_ClearEffects_RemovesAll()
	{
		let bus = scope AudioBus("TestBus");

		bus.AddEffect(new ScaleEffect() { Factor = 0.5f });
		bus.AddEffect(new ScaleEffect() { Factor = 0.25f });
		Test.Assert(bus.EffectCount == 2);

		bus.ClearEffects(true);
		Test.Assert(bus.EffectCount == 0);
	}

	[Test]
	public static void Bus_DefaultVolumeIsOne()
	{
		let bus = scope AudioBus("TestBus");

		Test.Assert(Math.Abs(bus.Volume - 1.0f) < 0.001f);
	}

	[Test]
	public static void Bus_GetEffect_OutOfRange_ReturnsNull()
	{
		let bus = scope AudioBus("TestBus");

		Test.Assert(bus.GetEffect(-1) == null);
		Test.Assert(bus.GetEffect(0) == null);
		Test.Assert(bus.GetEffect(99) == null);
	}
}
