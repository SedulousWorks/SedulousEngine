namespace Sedulous.Audio.Tests;

using System;
using Sedulous.Audio.Graph;

class SplitNodeTests
{
	class ConstNode : AudioNode
	{
		public float Value = 1.0f;

		protected override void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate)
		{
			let sampleCount = frameCount * 2;
			for (int i = 0; i < sampleCount; i++)
				buffer[i] = Value;
		}
	}

	[Test]
	public static void SingleOutput_Passthrough()
	{
		let source = scope ConstNode() { Value = 0.5f };
		let split = scope SplitNode();
		let output = scope CombineNode();

		split.AddInput(source);
		output.AddInput(split);

		let buf = scope float[8]*;
		output.GetOutputSamples(buf, 4, 48000, 1);

		for (int i = 0; i < 8; i++)
			Test.Assert(Math.Abs(buf[i] - 0.5f) < 0.001f);
	}

	[Test]
	public static void TwoOutputs_BothReceiveSignal()
	{
		let source = scope ConstNode() { Value = 0.7f };
		let split = scope SplitNode();
		let outA = scope CombineNode();
		let outB = scope CombineNode();

		split.AddInput(source);
		outA.AddInput(split);
		outB.AddInput(split);

		let bufA = scope float[8]*;
		let bufB = scope float[8]*;

		outA.GetOutputSamples(bufA, 4, 48000, 1);
		outB.GetOutputSamples(bufB, 4, 48000, 1);

		// Both outputs should receive the same signal
		for (int i = 0; i < 8; i++)
		{
			Test.Assert(Math.Abs(bufA[i] - 0.7f) < 0.001f);
			Test.Assert(Math.Abs(bufB[i] - 0.7f) < 0.001f);
		}
	}

	[Test]
	public static void SendRouting_DryAndWet()
	{
		// Simulate send routing: source -> split -> dry bus + wet bus (with volume)
		let source = scope ConstNode() { Value = 1.0f };
		let split = scope SplitNode();
		let dryBus = scope CombineNode();
		let wetBus = scope VolumeNode();
		wetBus.Volume = 0.3f; // 30% wet send

		split.AddInput(source);
		dryBus.AddInput(split);
		wetBus.AddInput(split);

		// Master sums both
		let master = scope CombineNode();
		master.AddInput(dryBus);
		master.AddInput(wetBus);

		// First eval ramps wet volume
		let buf = scope float[8]*;
		master.GetOutputSamples(buf, 4, 48000, 1);

		// Second eval at target
		let buf2 = scope float[8]*;
		master.GetOutputSamples(buf2, 4, 48000, 2);

		// Expected: 1.0 (dry) + 0.3 (wet) = 1.3
		for (int i = 0; i < 8; i++)
			Test.Assert(Math.Abs(buf2[i] - 1.3f) < 0.05f);
	}
}
