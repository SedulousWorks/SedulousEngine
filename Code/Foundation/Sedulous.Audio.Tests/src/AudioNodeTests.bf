namespace Sedulous.Audio.Tests;

using System;
using Sedulous.Audio.Graph;

class AudioNodeTests
{
	/// Simple test node that fills buffer with a constant value.
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

	/// Test node that accumulates inputs (like CombineNode).
	class SumNode : AudioNode
	{
		protected override void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate)
		{
			AccumulateInputSamples(buffer, frameCount, sampleRate, LastMixVersion);
		}
	}

	[Test]
	public static void AddInput_ConnectsTwoNodes()
	{
		let a = scope ConstNode();
		let b = scope SumNode();

		b.AddInput(a);

		Test.Assert(b.InputCount == 1);
		Test.Assert(a.OutputCount == 1);
		Test.Assert(b.GetInput(0) == a);
		Test.Assert(a.GetOutput(0) == b);
	}

	[Test]
	public static void RemoveInput_DisconnectsNodes()
	{
		let a = scope ConstNode();
		let b = scope SumNode();

		b.AddInput(a);
		b.RemoveInput(a);

		Test.Assert(b.InputCount == 0);
		Test.Assert(a.OutputCount == 0);
	}

	[Test]
	public static void AddInput_SelfConnection_Ignored()
	{
		let a = scope SumNode();
		a.AddInput(a);
		Test.Assert(a.InputCount == 0);
	}

	[Test]
	public static void AddInput_Duplicate_Ignored()
	{
		let a = scope ConstNode();
		let b = scope SumNode();

		b.AddInput(a);
		b.AddInput(a);

		Test.Assert(b.InputCount == 1);
	}

	[Test]
	public static void AddInput_Null_Ignored()
	{
		let b = scope SumNode();
		b.AddInput(null);
		Test.Assert(b.InputCount == 0);
	}

	[Test]
	public static void DisconnectAll_RemovesAllConnections()
	{
		let a = scope ConstNode();
		let b = scope ConstNode();
		let c = scope SumNode();

		c.AddInput(a);
		c.AddInput(b);
		c.DisconnectAll();

		Test.Assert(c.InputCount == 0);
		Test.Assert(a.OutputCount == 0);
		Test.Assert(b.OutputCount == 0);
	}

	[Test]
	public static void InsertBefore_WiresCorrectly()
	{
		let source = scope ConstNode();
		let target = scope SumNode();
		let middle = scope SumNode();

		target.AddInput(source);
		target.InsertBefore(middle);

		// source -> middle -> target
		Test.Assert(source.OutputCount == 1);
		Test.Assert(source.GetOutput(0) == middle);
		Test.Assert(middle.InputCount == 1);
		Test.Assert(middle.GetInput(0) == source);
		Test.Assert(middle.OutputCount == 1);
		Test.Assert(middle.GetOutput(0) == target);
		Test.Assert(target.InputCount == 1);
		Test.Assert(target.GetInput(0) == middle);
	}

	[Test]
	public static void InsertAfter_WiresCorrectly()
	{
		let source = scope ConstNode();
		let target = scope SumNode();
		let middle = scope SumNode();

		target.AddInput(source);
		source.InsertAfter(middle);

		// source -> middle -> target
		Test.Assert(source.OutputCount == 1);
		Test.Assert(source.GetOutput(0) == middle);
		Test.Assert(middle.InputCount == 1);
		Test.Assert(middle.GetInput(0) == source);
		Test.Assert(middle.OutputCount == 1);
		Test.Assert(middle.GetOutput(0) == target);
		Test.Assert(target.InputCount == 1);
		Test.Assert(target.GetInput(0) == middle);
	}

	[Test]
	public static void MixVersionCaching_EvaluatesOncePerFrame()
	{
		let source = scope ConstNode() { Value = 0.5f };
		let outA = scope SumNode();
		let outB = scope SumNode();

		outA.AddInput(source);
		outB.AddInput(source);

		let buf = scope float[8]*;
		uint64 version = 1;

		outA.GetOutputSamples(buf, 4, 48000, version);
		// Source should now be cached at version 1
		Test.Assert(source.LastMixVersion == version);

		// Change the source value - cached result should still be returned
		source.Value = 999.0f;
		let buf2 = scope float[8]*;
		outB.GetOutputSamples(buf2, 4, 48000, version);

		// Should get the cached 0.5 value, not 999
		Test.Assert(buf2[0] == 0.5f);
	}

	[Test]
	public static void MixVersionCaching_NewVersionReEvaluates()
	{
		let source = scope ConstNode() { Value = 0.5f };
		let output = scope SumNode();
		output.AddInput(source);

		let buf = scope float[8]*;
		output.GetOutputSamples(buf, 4, 48000, 1);
		Test.Assert(buf[0] == 0.5f);

		source.Value = 0.75f;
		output.GetOutputSamples(buf, 4, 48000, 2); // new version
		Test.Assert(buf[0] == 0.75f);
	}

	[Test]
	public static void Disabled_ProducesSilence()
	{
		let source = scope ConstNode() { Value = 1.0f };
		source.Enabled = false;

		let buf = scope float[8]*;
		source.GetOutputSamples(buf, 4, 48000, 1);

		for (int i = 0; i < 8; i++)
			Test.Assert(buf[i] == 0.0f);
	}
}
