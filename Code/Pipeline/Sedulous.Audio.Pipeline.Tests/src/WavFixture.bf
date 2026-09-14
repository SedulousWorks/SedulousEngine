using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;

namespace Sedulous.Audio.Pipeline.Tests;

/// Tones encoded as WAV, and the sampler chunk a loop point lives in.
///
/// A REAL container rather than a stand in, because the cook writes the source bytes through
/// untouched and the probe reads its metadata back out of them: a fixture that was not really
/// a WAV would measure neither.
static class WavFixture
{
	/// A sine at four hundred and forty, interleaved across the channels.
	public static void Tone(float seconds, uint32 sampleRate, uint32 channels,
		List<int16> outSamples, float amplitude = 0.5f)
	{
		let frameCount = (int)(seconds * (float)sampleRate);
		for (int frame < frameCount)
		{
			let t = (float)frame / (float)sampleRate;
			let sample = (int16)(amplitude * Math.Sin(2.0f * Math.PI_f * 440.0f * t) * 32000.0f);
			for (uint32 channel < channels)
				outSamples.Add(sample);
		}
	}

	public static void ToneWav(float seconds, List<uint8> outWav, uint32 sampleRate = 8000,
		uint32 channels = 1, float amplitude = 0.5f)
	{
		let samples = scope List<int16>();
		Tone(seconds, sampleRate, channels, samples, amplitude);
		Test.Assert(AudioCodec.EncodeWav(samples, channels, sampleRate, outWav));
	}

	private static void PushU32(List<uint8> bytes, uint32 value)
	{
		bytes.Add((uint8)(value & 0xFF));
		bytes.Add((uint8)((value >> 8) & 0xFF));
		bytes.Add((uint8)((value >> 16) & 0xFF));
		bytes.Add((uint8)((value >> 24) & 0xFF));
	}

	/// Appends a sampler chunk carrying ONE forward loop, and patches the container's size
	/// field so the file stays well formed.
	public static void AppendSampleLoop(List<uint8> wav, uint32 loopStart, uint32 loopEnd)
	{
		for (let c in scope char8[]('s', 'm', 'p', 'l'))
			wav.Add((uint8)c);
		PushU32(wav, 36 + 24); // the sampler fields plus one loop record

		for (int i < 7)
			PushU32(wav, 0); // manufacturer through to the timecode offset
		PushU32(wav, 1); // one loop
		PushU32(wav, 0); // no sampler specific data
		PushU32(wav, 0); // the loop's id
		PushU32(wav, 0); // forward
		PushU32(wav, loopStart);
		PushU32(wav, loopEnd);
		PushU32(wav, 0); // no fractional tuning
		PushU32(wav, 0); // play forever

		let riffSize = (uint32)wav.Count - 8;
		wav[4] = (uint8)(riffSize & 0xFF);
		wav[5] = (uint8)((riffSize >> 8) & 0xFF);
		wav[6] = (uint8)((riffSize >> 16) & 0xFF);
		wav[7] = (uint8)((riffSize >> 24) & 0xFF);
	}
}
