namespace Sedulous.Audio.Tests;

using System;
using Sedulous.Audio.Graph;

class VolumeNodeTests
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
	public static void Volume_1_0_Passthrough()
	{
		let source = scope ConstNode() { Value = 0.8f };
		let vol = scope VolumeNode();
		vol.Volume = 1.0f;
		vol.AddInput(source);

		let buf = scope float[8]*;
		vol.GetOutputSamples(buf, 4, 48000, 1);

		for (int i = 0; i < 8; i++)
			Test.Assert(buf[i] == 0.8f);
	}

	[Test]
	public static void Volume_0_5_HalvesSamples()
	{
		let source = scope ConstNode() { Value = 1.0f };
		let vol = scope VolumeNode();
		vol.Volume = 0.5f;
		vol.AddInput(source);

		// First call ramps from 1.0 to 0.5
		let buf = scope float[8]*;
		vol.GetOutputSamples(buf, 4, 48000, 1);

		// After interpolation completes, second call should be at exactly 0.5
		let buf2 = scope float[8]*;
		vol.GetOutputSamples(buf2, 4, 48000, 2);

		for (int i = 0; i < 8; i++)
			Test.Assert(Math.Abs(buf2[i] - 0.5f) < 0.01f);
	}

	[Test]
	public static void Volume_0_0_ProducesSilence()
	{
		let source = scope ConstNode() { Value = 1.0f };
		let vol = scope VolumeNode();
		vol.Volume = 0.0f;
		vol.AddInput(source);

		// Ramp down
		let buf = scope float[8]*;
		vol.GetOutputSamples(buf, 4, 48000, 1);

		// Now at zero
		let buf2 = scope float[8]*;
		vol.GetOutputSamples(buf2, 4, 48000, 2);

		for (int i = 0; i < 8; i++)
			Test.Assert(Math.Abs(buf2[i]) < 0.01f);
	}

	[Test]
	public static void Interpolation_RampsSmoothly()
	{
		let source = scope ConstNode() { Value = 1.0f };
		let vol = scope VolumeNode();
		vol.Volume = 1.0f;
		vol.AddInput(source);

		// Establish at 1.0
		let buf = scope float[8]*;
		vol.GetOutputSamples(buf, 4, 48000, 1);

		// Change to 0.0 - should ramp over the buffer
		vol.Volume = 0.0f;
		let buf2 = scope float[16]*; // 8 frames
		vol.GetOutputSamples(buf2, 8, 48000, 2);

		// First sample should be close to 1.0, last sample close to 0.0
		Test.Assert(buf2[0] > 0.5f);   // near start, still high
		Test.Assert(buf2[14] < 0.2f);  // near end, close to 0
	}

	[Test]
	public static void NoInput_ProducesSilence()
	{
		let vol = scope VolumeNode();
		vol.Volume = 1.0f;

		let buf = scope float[8]*;
		for (int i = 0; i < 8; i++) buf[i] = 999.0f;

		vol.GetOutputSamples(buf, 4, 48000, 1);

		for (int i = 0; i < 8; i++)
			Test.Assert(buf[i] == 0.0f);
	}
}
