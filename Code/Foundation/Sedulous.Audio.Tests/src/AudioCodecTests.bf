using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;

namespace Sedulous.Audio.Tests;

/// The codec seam: encoding, probing and decoding a container.
class AudioCodecTests
{
	/// A short tone, which is a real signal rather than silence: a decoder that dropped every
	/// sample would still round trip silence perfectly.
	private static void MakeTone(List<int16> outSamples, uint32 channels, uint32 sampleRate,
		float seconds)
	{
		let frames = (int)((float)sampleRate * seconds);
		outSamples.Clear();
		for (int frame < frames)
		{
			let phase = (float)frame / (float)sampleRate * 440.0f * 2.0f * Pi;
			let sample = (int16)(Sin(phase) * 16000.0f);
			for (uint32 c = 0; c < channels; c++)
				outSamples.Add(sample);
		}
	}

	[Test]
	public static void AToneEncodesProbesAndDecodesBack()
	{
		let samples = scope List<int16>();
		MakeTone(samples, 1, 22050, 0.1f);

		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 1, 22050, wav));
		// A canonical header, and the samples after it.
		Test.Assert(wav.Count == (44 + samples.Count * 2));

		Test.Assert(AudioCodec.Probe(wav, let metadata));
		Test.Assert(metadata.Channels == 1);
		Test.Assert(metadata.SampleRate == 22050);
		Test.Assert(metadata.FrameCount == (uint64)samples.Count);
		Test.Assert(Abs(metadata.DurationSeconds - 0.1f) < 0.01f);

		let decoded = scope List<int16>();
		Test.Assert(AudioCodec.DecodeToPcm16(wav, 0, decoded, let decodedMetadata));
		Test.Assert(decodedMetadata.Channels == 1);
		Test.Assert(decoded.Count == samples.Count);

		// Sixteen bit in, sixteen bit out, uncompressed: it comes back EXACTLY.
		for (int i < samples.Count)
			Test.Assert(decoded[i] == samples[i]);
	}

	/// A stereo source asked for one channel comes back MONO, which is the force to mono
	/// import path: a stereo source spatialises as two sources at one point and images as
	/// nothing in particular.
	[Test]
	public static void AStereoSourceDownmixesToMono()
	{
		let samples = scope List<int16>();
		MakeTone(samples, 2, 22050, 0.05f);

		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 2, 22050, wav));

		let decoded = scope List<int16>();
		Test.Assert(AudioCodec.DecodeToPcm16(wav, 1, decoded, let metadata));
		Test.Assert(metadata.Channels == 1);
		Test.Assert(decoded.Count == (samples.Count / 2));
	}

	[Test]
	public static void ADecodeToFloatAnswersTheSameShape()
	{
		let samples = scope List<int16>();
		MakeTone(samples, 2, 22050, 0.05f);

		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 2, 22050, wav));

		let decoded = scope List<float>();
		Test.Assert(AudioCodec.DecodeToFloat(wav, 0, decoded, let channels, let frames));
		Test.Assert(channels == 2);
		Test.Assert(frames == (uint64)(samples.Count / 2));
		Test.Assert(decoded.Count == samples.Count);
	}

	/// Bytes that are not audio are REFUSED rather than probed into a shape of nothing, which
	/// a caller would read as a valid empty clip.
	[Test]
	public static void NonsenseIsRefusedRatherThanProbedEmpty()
	{
		let nonsense = scope List<uint8>();
		for (int i < 128)
			nonsense.Add((uint8)i);

		Test.Assert(!AudioCodec.Probe(nonsense, let metadata));
		Test.Assert(!metadata.IsValid);

		let empty = scope List<uint8>();
		Test.Assert(!AudioCodec.Probe(empty, let none));
		Test.Assert(!none.IsValid);
	}

	/// A degenerate encode is refused: a sample count that is not a whole number of frames
	/// would write a header that disagrees with its own payload.
	[Test]
	public static void ADegenerateEncodeIsRefused()
	{
		let samples = scope List<int16>();
		samples.Add(0);
		samples.Add(0);
		samples.Add(0);

		let wav = scope List<uint8>();
		// Three samples over two channels is not a whole number of frames.
		Test.Assert(!AudioCodec.EncodeWav(samples, 2, 22050, wav));
		Test.Assert(!AudioCodec.EncodeWav(samples, 0, 22050, wav));
		Test.Assert(!AudioCodec.EncodeWav(samples, 1, 0, wav));
	}

	/// The waveform buckets the signal by PEAK, so a tone reads as loud and silence as
	/// nothing. An average would read a tone as silence too.
	[Test]
	public static void TheWaveformBucketsByPeak()
	{
		let samples = scope List<int16>();
		MakeTone(samples, 1, 22050, 0.2f);

		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 1, 22050, wav));

		let peaks = scope List<float>();
		Test.Assert(AudioCodec.BuildWaveformPeaks(wav, 32, peaks));
		Test.Assert(peaks.Count == 32);

		for (let peak in peaks)
		{
			Test.Assert(peak > 0.1f);
			Test.Assert(peak <= 1.0f);
		}
	}

	[Test]
	public static void SilenceReadsAsNearlyNothing()
	{
		let samples = scope List<int16>();
		samples.Resize(4096);
		for (int i < samples.Count)
			samples[i] = 0;

		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 1, 22050, wav));

		let peaks = scope List<float>();
		Test.Assert(AudioCodec.BuildWaveformPeaks(wav, 16, peaks));
		for (let peak in peaks)
			Test.Assert(peak < 0.001f);
	}

	[Test]
	public static void AWaveformOfNothingIsRefused()
	{
		let peaks = scope List<float>();
		let empty = scope List<uint8>();
		Test.Assert(!AudioCodec.BuildWaveformPeaks(empty, 16, peaks));

		let samples = scope List<int16>();
		MakeTone(samples, 1, 22050, 0.05f);
		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 1, 22050, wav));
		// No buckets to fill.
		Test.Assert(!AudioCodec.BuildWaveformPeaks(wav, 0, peaks));
	}
}
