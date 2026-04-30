namespace Sedulous.Audio.Tests;

using System;
using Sedulous.Audio.Graph;

class CombineNodeTests
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
	public static void SingleInput_PassesThrough()
	{
		let source = scope ConstNode() { Value = 0.5f };
		let combine = scope CombineNode();
		combine.AddInput(source);

		let buf = scope float[8]*;
		combine.GetOutputSamples(buf, 4, 48000, 1);

		for (int i = 0; i < 8; i++)
			Test.Assert(buf[i] == 0.5f);
	}

	[Test]
	public static void TwoInputs_SumsCorrectly()
	{
		let a = scope ConstNode() { Value = 0.3f };
		let b = scope ConstNode() { Value = 0.4f };
		let combine = scope CombineNode();
		combine.AddInput(a);
		combine.AddInput(b);

		let buf = scope float[8]*;
		combine.GetOutputSamples(buf, 4, 48000, 1);

		for (int i = 0; i < 8; i++)
			Test.Assert(Math.Abs(buf[i] - 0.7f) < 0.001f);
	}

	[Test]
	public static void ThreeInputs_SumsCorrectly()
	{
		let a = scope ConstNode() { Value = 0.1f };
		let b = scope ConstNode() { Value = 0.2f };
		let c = scope ConstNode() { Value = 0.3f };
		let combine = scope CombineNode();
		combine.AddInput(a);
		combine.AddInput(b);
		combine.AddInput(c);

		let buf = scope float[8]*;
		combine.GetOutputSamples(buf, 4, 48000, 1);

		for (int i = 0; i < 8; i++)
			Test.Assert(Math.Abs(buf[i] - 0.6f) < 0.001f);
	}

	[Test]
	public static void ZeroInputs_ProducesSilence()
	{
		let combine = scope CombineNode();

		let buf = scope float[8]*;
		for (int i = 0; i < 8; i++) buf[i] = 999.0f;

		combine.GetOutputSamples(buf, 4, 48000, 1);

		for (int i = 0; i < 8; i++)
			Test.Assert(buf[i] == 0.0f);
	}
}
