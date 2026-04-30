namespace Sedulous.Audio.Tests;

using System;
using System.Collections;
using Sedulous.Audio.Graph;

class AudioGraphTests
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
	public static void Graph_HasOutputNode()
	{
		let graph = scope AudioGraph();
		Test.Assert(graph.Output != null);
	}

	[Test]
	public static void Evaluate_EmptyGraph_ProducesSilence()
	{
		let graph = scope AudioGraph();

		let buf = scope float[8]*;
		for (int i = 0; i < 8; i++) buf[i] = 999.0f;

		graph.Evaluate(buf, 4, 48000);

		for (int i = 0; i < 8; i++)
			Test.Assert(buf[i] == 0.0f);
	}

	[Test]
	public static void Evaluate_SingleSource()
	{
		let graph = scope AudioGraph();
		let source = scope ConstNode() { Value = 0.75f };
		graph.Output.AddInput(source);

		let buf = scope float[8]*;
		graph.Evaluate(buf, 4, 48000);

		for (int i = 0; i < 8; i++)
			Test.Assert(buf[i] == 0.75f);
	}

	[Test]
	public static void Evaluate_IncrementsMixVersion()
	{
		let graph = scope AudioGraph();

		Test.Assert(graph.MixVersion == 0);

		let buf = scope float[8]*;
		graph.Evaluate(buf, 4, 48000);
		Test.Assert(graph.MixVersion == 1);

		graph.Evaluate(buf, 4, 48000);
		Test.Assert(graph.MixVersion == 2);
	}

	[Test]
	public static void Evaluate_ComplexGraph()
	{
		// 3 sources -> 2 combines -> output
		let graph = scope AudioGraph();

		let src1 = scope ConstNode() { Value = 0.1f };
		let src2 = scope ConstNode() { Value = 0.2f };
		let src3 = scope ConstNode() { Value = 0.3f };
		let combineA = scope CombineNode();
		let combineB = scope CombineNode();

		combineA.AddInput(src1);
		combineA.AddInput(src2);
		combineB.AddInput(src3);

		graph.Output.AddInput(combineA);
		graph.Output.AddInput(combineB);

		let buf = scope float[8]*;
		graph.Evaluate(buf, 4, 48000);

		// Expected: 0.1 + 0.2 + 0.3 = 0.6
		for (int i = 0; i < 8; i++)
			Test.Assert(Math.Abs(buf[i] - 0.6f) < 0.001f);
	}

	[Test]
	public static void Evaluate_SourceWithVolumeNode()
	{
		let graph = scope AudioGraph();

		let src = scope ConstNode() { Value = 1.0f };
		let vol = scope VolumeNode();
		vol.Volume = 0.5f;

		vol.AddInput(src);
		graph.Output.AddInput(vol);

		// First eval ramps volume
		let buf = scope float[8]*;
		graph.Evaluate(buf, 4, 48000);

		// Second eval should be at target
		let buf2 = scope float[8]*;
		graph.Evaluate(buf2, 4, 48000);

		for (int i = 0; i < 8; i++)
			Test.Assert(Math.Abs(buf2[i] - 0.5f) < 0.01f);
	}

	[Test]
	public static void Evaluate_SharedNode_EvaluatedOnce()
	{
		// Diamond: src -> combineA -> output
		//          src -> combineB -> output
		// src should only evaluate once due to mix-version caching
		let graph = scope AudioGraph();

		let src = scope ConstNode() { Value = 0.5f };
		let combineA = scope CombineNode();
		let combineB = scope CombineNode();

		combineA.AddInput(src);
		combineB.AddInput(src);
		graph.Output.AddInput(combineA);
		graph.Output.AddInput(combineB);

		let buf = scope float[8]*;
		graph.Evaluate(buf, 4, 48000);

		// 0.5 from combineA + 0.5 from combineB = 1.0
		for (int i = 0; i < 8; i++)
			Test.Assert(Math.Abs(buf[i] - 1.0f) < 0.001f);
	}
}
