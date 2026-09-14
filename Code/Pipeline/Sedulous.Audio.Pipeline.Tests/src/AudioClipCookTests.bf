using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Audio.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Audio.Pipeline.Tests;

/// The clip cook: a container file through the builder into something the mixer can play.
class AudioClipCookTests
{
	private const String cSourceRoot = "scratch_audio_pipeline_src";
	private const String cCookedRoot = "scratch_audio_pipeline_out";
	private const String cProductType = "Sedulous.Audio.Resource.AudioClipSource";

	private static bool Near(float a, float b, float tolerance = 0.01f) => Abs(a - b) <= tolerance;

	private static void MakeRoots()
	{
		for (let root in scope String[](cSourceRoot, cCookedRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}
		AudioPipeline.RegisterAll();
		AudioResources.RegisterAll();
	}

	private static void RemoveRoots()
	{
		RemoveDirectoryRecursive(cSourceRoot);
		RemoveDirectoryRecursive(cCookedRoot);
	}

	private static void WriteSource(StringView name, List<uint8> bytes)
	{
		let path = scope String();
		PathJoin(cSourceRoot, name, path);
		Test.Assert(WriteFile(path, bytes) case .Ok);
	}

	/// Long OR large sources stream by default.
	///
	/// Either alone is enough: a long quiet track and a short dense one both cost more to hold
	/// resident than to read as they play.
	[Test]
	public static void TheStreamDefaultCatchesLongOrLargeSources()
	{
		Test.Assert(!AudioImportHeuristics.ShouldStreamByDefault(1.0f, 100 * 1024));
		Test.Assert(AudioImportHeuristics.ShouldStreamByDefault(11.0f, 100 * 1024));
		Test.Assert(AudioImportHeuristics.ShouldStreamByDefault(1.0f, 3 * 1024 * 1024));
		// Exactly at the line is NOT over it.
		Test.Assert(!AudioImportHeuristics.ShouldStreamByDefault(10.0f, 2 * 1024 * 1024));
	}

	/// The sampler chunk's loop points are read when present, and nothing is invented when they
	/// are not.
	[Test]
	public static void TheSamplerChunksLoopPointsParse()
	{
		let wav = scope List<uint8>();
		WavFixture.ToneWav(0.2f, wav);
		Test.Assert(!AudioImportHeuristics.ParseWavSampleLoop(wav, let absentStart, let absentEnd));

		WavFixture.AppendSampleLoop(wav, 100, 1500);
		Test.Assert(AudioImportHeuristics.ParseWavSampleLoop(wav, let start, let end));
		Test.Assert(start == 100);
		Test.Assert(end == 1500);

		let garbage = scope List<uint8>();
		for (int i < 128)
			garbage.Add((uint8)i);
		Test.Assert(!AudioImportHeuristics.ParseWavSampleLoop(garbage, let badStart, let badEnd));
	}

	/// The cook writes the CONTAINER BYTES through untouched.
	///
	/// No decoded sidecar: the codec is in the runtime anyway, and a decoded copy beside the
	/// container would double what ships to store what can be recomputed.
	[Test]
	public static void TheCookKeepsTheOriginalContainerBytes()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		let wav = scope List<uint8>();
		WavFixture.ToneWav(0.25f, wav, 8000, 2);
		WriteSource("tone.wav", wav);

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");

		let asset = scope AudioClipAsset();
		asset.FileName.Set("tone.wav");
		asset.Gain = 0.8f;
		asset.Loop = true;
		asset.LoopStartFrame = 10;
		asset.LoopEndFrame = 900;

		let instance = cookedDb.RootGroup.CreateInstance("cooked", cProductType);
		Test.Assert(instance != null);

		let context = scope AssetBuildContext();
		context.Sources = sourceMount;
		context.Output = instance;
		Test.Assert(scope AudioClipAssetBuilder().Build(asset, context) case .Ok);

		let manager = scope ResourceManager(cookedDb, null);
		let factory = scope AudioClipFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<AudioClip>(instance.Id);
		let clip = bound.Get;
		Test.Assert(clip != null);
		Test.Assert(clip.Channels == 2);
		Test.Assert(clip.SampleRate == 8000);
		Test.Assert(Near(clip.DurationSeconds, 0.25f));
		Test.Assert(Near(clip.Gain, 0.8f));
		Test.Assert(clip.Loop);
		Test.Assert(clip.LoopStartFrame == 10);
		Test.Assert(clip.LoopEndFrame == 900);
		Test.Assert(!clip.Stream);

		Test.Assert(clip.EncodedData.Count == wav.Count);
		for (int i < wav.Count)
			Test.Assert(clip.EncodedData[i] == wav[i], scope $"byte {i}");
	}

	/// A source the codec cannot read FAILS the cook rather than shipping an empty clip that
	/// plays silence with nothing said about why.
	[Test]
	public static void AnUndecodableSourceFailsTheCook()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		let garbage = scope List<uint8>();
		for (int i < 256)
			garbage.Add((uint8)i);
		WriteSource("tone.wav", garbage);

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");

		let asset = scope AudioClipAsset();
		asset.FileName.Set("tone.wav");

		let instance = cookedDb.RootGroup.CreateInstance("cooked", cProductType);
		Test.Assert(instance != null);

		let context = scope AssetBuildContext();
		context.Sources = sourceMount;
		context.Output = instance;
		Test.Assert(scope AudioClipAssetBuilder().Build(asset, context) case .Err);
	}

	/// The DESTRUCTIVE options: a downmix to one channel, a trimmed silent tail, and a peak
	/// lifted to just under full scale.
	///
	/// Destructive because they rewrite the container rather than annotate it, which is the
	/// point: the cooked clip is what ships, and a quiet stereo file with a long silent tail
	/// costs both channels and the silence at runtime.
	[Test]
	public static void TheDestructiveOptionsRewriteTheClip()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		// A quiet stereo tone with half a second of silence after it.
		let samples = scope List<int16>();
		WavFixture.Tone(0.25f, 8000, 2, samples, 0.1f);
		let toneFrames = (uint64)(samples.Count / 2);
		for (int i < 8000 / 2 * 2)
			samples.Add(0);

		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 2, 8000, wav));
		WriteSource("tone.wav", wav);

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");

		let asset = scope AudioClipAsset();
		asset.FileName.Set("tone.wav");
		asset.ForceMono = true;
		asset.TrimTrailingSilence = true;
		asset.Normalize = true;

		let instance = cookedDb.RootGroup.CreateInstance("cooked", cProductType);
		Test.Assert(instance != null);

		let context = scope AssetBuildContext();
		context.Sources = sourceMount;
		context.Output = instance;
		Test.Assert(scope AudioClipAssetBuilder().Build(asset, context) case .Ok);

		let manager = scope ResourceManager(cookedDb, null);
		let factory = scope AudioClipFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<AudioClip>(instance.Id);
		let clip = bound.Get;
		Test.Assert(clip != null);
		Test.Assert(clip.Channels == 1); // downmixed
		Test.Assert(clip.FrameCount >= toneFrames); // the tone itself is kept
		Test.Assert(clip.FrameCount < (toneFrames + 4000)); // the silence is not

		let cooked = scope List<int16>();
		Test.Assert(AudioCodec.DecodeToPcm16(clip.EncodedData, 0, cooked, var metadata));
		var peak = 0;
		for (let sample in cooked)
		{
			let magnitude = (sample < 0) ? -(int)sample : (int)sample;
			if (magnitude > peak)
				peak = magnitude;
		}
		Test.Assert(peak > 27000, scope $"peak was {peak}"); // lifted from about 3200
	}
}
