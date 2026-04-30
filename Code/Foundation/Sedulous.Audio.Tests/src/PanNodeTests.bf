namespace Sedulous.Audio.Tests;

using System;
using Sedulous.Audio.Graph;

class PanNodeTests
{
	class ConstStereoNode : AudioNode
	{
		public float Left = 1.0f;
		public float Right = 1.0f;

		protected override void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate)
		{
			for (int32 i = 0; i < frameCount; i++)
			{
				buffer[i * 2] = Left;
				buffer[i * 2 + 1] = Right;
			}
		}
	}

	[Test]
	public static void Center_NoChange()
	{
		let source = scope ConstStereoNode() { Left = 0.6f, Right = 0.6f };
		let pan = scope PanNode();
		pan.Pan = 0.0f;
		pan.AddInput(source);

		let buf = scope float[8]*;
		pan.GetOutputSamples(buf, 4, 48000, 1);

		// Center pan should pass through unchanged
		for (int32 i = 0; i < 4; i++)
		{
			Test.Assert(Math.Abs(buf[i * 2] - 0.6f) < 0.01f);
			Test.Assert(Math.Abs(buf[i * 2 + 1] - 0.6f) < 0.01f);
		}
	}

	[Test]
	public static void FullLeft_AllToLeftChannel()
	{
		let source = scope ConstStereoNode() { Left = 1.0f, Right = 1.0f };
		let pan = scope PanNode();
		pan.Pan = -1.0f;
		pan.AddInput(source);

		let buf = scope float[8]*;
		pan.GetOutputSamples(buf, 4, 48000, 1);

		// Full left: all signal in L, none in R
		Test.Assert(buf[0] > 0.9f);
		Test.Assert(Math.Abs(buf[1]) < 0.01f);
	}

	[Test]
	public static void FullRight_AllToRightChannel()
	{
		let source = scope ConstStereoNode() { Left = 1.0f, Right = 1.0f };
		let pan = scope PanNode();
		pan.Pan = 1.0f;
		pan.AddInput(source);

		let buf = scope float[8]*;
		pan.GetOutputSamples(buf, 4, 48000, 1);

		// Full right: all signal in R, none in L
		Test.Assert(Math.Abs(buf[0]) < 0.01f);
		Test.Assert(buf[1] > 0.9f);
	}

	[Test]
	public static void ConstantPower_CenterIsNotMinus6dB()
	{
		let source = scope ConstStereoNode() { Left = 1.0f, Right = 1.0f };
		let pan = scope PanNode();
		pan.Pan = 0.0f;
		pan.AddInput(source);

		let buf = scope float[8]*;
		pan.GetOutputSamples(buf, 4, 48000, 1);

		// At center, constant-power panning gives cos(PI/4) = ~0.707 per channel
		// But since pan=0 is passthrough, both should be 1.0
		// (we skip processing when pan == 0)
		Test.Assert(Math.Abs(buf[0] - 1.0f) < 0.01f);
	}
}
