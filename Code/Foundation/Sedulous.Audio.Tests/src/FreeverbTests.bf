using System;
using Sedulous.Audio;
using Sedulous.Core;

namespace Sedulous.Audio.Tests;

/// The reverberator's maths, with no audio backend anywhere near it.
class FreeverbTests
{
	private const int cFrames = 512;

	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// The energy in a block, which is what a tail is measured by: its samples are signed and
	/// average to nothing.
	private static float Energy(float[] samples, int from = 0)
	{
		var total = 0.0f;
		for (int i = from; i < samples.Count; i++)
			total += samples[i] * samples[i];
		return total;
	}

	private static void Impulse(float[] samples)
	{
		for (int i < samples.Count)
			samples[i] = 0.0f;
		samples[0] = 1.0f;
		samples[1] = 1.0f;
	}

	/// Wet at nothing is a passthrough: the input comes out unchanged and nothing rings after
	/// it, so a reverb turned off costs the signal nothing.
	[Test]
	public static void NoWetIsAPassthrough()
	{
		let reverb = scope FreeverbState();
		reverb.Initialize(44100);
		Test.Assert(reverb.IsInitialized);

		var parameters = AudioReverbParams();
		parameters.Wet = 0.0f;
		reverb.SetParams(parameters);

		let input = scope float[cFrames * 2];
		let output = scope float[cFrames * 2];
		Impulse(input);

		reverb.ProcessStereo(&input[0], &output[0], cFrames);

		Test.Assert(Near(output[0], 1.0f));
		Test.Assert(Near(output[1], 1.0f));
		Test.Assert(Near(Energy(output, 2), 0.0f));
	}

	/// With wet, energy is still there WELL PAST the impulse, which is what a tail is.
	[Test]
	public static void ATailRingsOnAfterTheImpulse()
	{
		let reverb = scope FreeverbState();
		reverb.Initialize(44100);

		var parameters = AudioReverbParams();
		parameters.Wet = 0.8f;
		parameters.RoomSize = 0.8f;
		parameters.Damping = 0.1f;
		reverb.SetParams(parameters);

		let input = scope float[cFrames * 2];
		let silence = scope float[cFrames * 2];
		let output = scope float[cFrames * 2];
		Impulse(input);

		reverb.ProcessStereo(&input[0], &output[0], cFrames);

		// About half a second later, there is still something there.
		var late = 0.0f;
		for (int block < 40)
		{
			reverb.ProcessStereo(&silence[0], &output[0], cFrames);
			if (block > 20)
				late += Energy(output);
		}
		Test.Assert(late > 1.0e-6f);
	}

	/// A smaller room damped harder carries LESS energy in the same late window: that is what
	/// the two knobs are for.
	[Test]
	public static void DampingAndRoomSizeShortenTheTail()
	{
		let input = scope float[cFrames * 2];
		let silence = scope float[cFrames * 2];
		let output = scope float[cFrames * 2];
		Impulse(input);

		float MeasureLateEnergy(float roomSize, float damping)
		{
			let reverb = scope FreeverbState();
			reverb.Initialize(44100);

			var parameters = AudioReverbParams();
			parameters.Wet = 0.8f;
			parameters.RoomSize = roomSize;
			parameters.Damping = damping;
			reverb.SetParams(parameters);

			reverb.ProcessStereo(&input[0], &output[0], cFrames);

			var late = 0.0f;
			for (int block < 40)
			{
				reverb.ProcessStereo(&silence[0], &output[0], cFrames);
				if (block > 20)
					late += Energy(output);
			}
			return late;
		}

		let large = MeasureLateEnergy(0.8f, 0.1f);
		let small = MeasureLateEnergy(0.2f, 0.9f);
		Test.Assert(small < (large * 0.5f));
	}

	/// The SEND form pins the dry to nothing: the voices' sends feed it alongside the dry
	/// path, so passing the dry signal through again would double it.
	[Test]
	public static void TheSendFormPassesNoDrySignalButStillRings()
	{
		let reverb = scope FreeverbState();
		reverb.Initialize(44100);

		var parameters = AudioReverbParams();
		parameters.Wet = 1.0f;
		parameters.Dry = 0.0f;
		parameters.RoomSize = 0.8f;
		parameters.Damping = 0.1f;
		reverb.SetParams(parameters);

		Test.Assert(Near(reverb.Dry, 0.0f));

		let input = scope float[cFrames * 2];
		let silence = scope float[cFrames * 2];
		let output = scope float[cFrames * 2];
		Impulse(input);

		reverb.ProcessStereo(&input[0], &output[0], cFrames);
		Test.Assert(Near(output[0], 0.0f));
		Test.Assert(Near(output[1], 0.0f));

		var tail = 0.0f;
		for (int block < 20)
		{
			reverb.ProcessStereo(&silence[0], &output[0], cFrames);
			tail += Energy(output);
		}
		Test.Assert(tail > 1.0e-6f);
	}

	/// A dry left unset TRACKS one minus the wet, which is the insert mix: the wetter it gets,
	/// the less of the original comes through, and the total stays about level.
	[Test]
	public static void AnUnsetDryTracksTheWet()
	{
		let reverb = scope FreeverbState();
		reverb.Initialize(44100);

		var parameters = AudioReverbParams();
		parameters.Wet = 0.25f;
		reverb.SetParams(parameters);
		Test.Assert(Near(reverb.Dry, 0.75f));

		parameters.Wet = 0.9f;
		reverb.SetParams(parameters);
		Test.Assert(Near(reverb.Dry, 0.1f));
	}

	/// The parameters are CLAMPED, so a value outside its range settles at the edge rather
	/// than making the feedback greater than one, which would ring louder forever.
	[Test]
	public static void TheParametersAreClamped()
	{
		let reverb = scope FreeverbState();
		reverb.Initialize(44100);

		var parameters = AudioReverbParams();
		parameters.Wet = 5.0f;
		parameters.RoomSize = 5.0f;
		parameters.Damping = -1.0f;
		reverb.SetParams(parameters);

		Test.Assert(Near(reverb.Wet, 1.0f));
		Test.Assert(Near(reverb.Dry, 0.0f));

		// And it stays finite under a long run at the extreme.
		let silence = scope float[cFrames * 2];
		let output = scope float[cFrames * 2];
		let input = scope float[cFrames * 2];
		Impulse(input);

		reverb.ProcessStereo(&input[0], &output[0], cFrames);
		for (int block < 100)
			reverb.ProcessStereo(&silence[0], &output[0], cFrames);

		for (let sample in output)
		{
			Test.Assert(sample == sample);
			Test.Assert(Abs(sample) < 1000.0f);
		}
	}

	/// The buffers scale with the RATE, so the tail is the same length in seconds whatever
	/// the engine is running at.
	[Test]
	public static void TheTailIsTheSameLengthAtAnyRate()
	{
		float MeasureTailBlocks(uint32 sampleRate)
		{
			let reverb = scope FreeverbState();
			reverb.Initialize(sampleRate);

			var parameters = AudioReverbParams();
			parameters.Wet = 1.0f;
			parameters.RoomSize = 0.7f;
			parameters.Damping = 0.2f;
			reverb.SetParams(parameters);

			// One block is a fixed number of FRAMES, so a higher rate needs more of them to
			// cover the same time. Measured in seconds, the two should agree.
			let frames = (int)(sampleRate / 20);
			let input = scope float[frames * 2];
			let silence = scope float[frames * 2];
			let output = scope float[frames * 2];
			for (int i < frames * 2)
			{
				input[i] = 0.0f;
				silence[i] = 0.0f;
			}
			input[0] = 1.0f;
			input[1] = 1.0f;

			reverb.ProcessStereo(&input[0], &output[0], (uint32)frames);

			var blocks = 0;
			for (; blocks < 200; blocks++)
			{
				reverb.ProcessStereo(&silence[0], &output[0], (uint32)frames);
				var energy = 0.0f;
				for (int i < frames * 2)
					energy += output[i] * output[i];
				if (energy < 1.0e-9f)
					break;
			}
			// Each block is a twentieth of a second at either rate.
			return (float)blocks / 20.0f;
		}

		let atStandard = MeasureTailBlocks(44100);
		let atHigher = MeasureTailBlocks(48000);
		Test.Assert(Abs(atStandard - atHigher) < (atStandard * 0.25f + 0.1f));
	}
}
