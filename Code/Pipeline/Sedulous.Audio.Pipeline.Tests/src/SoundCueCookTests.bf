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

/// A sound cue: authored slots into weighted variants that resolve their clips.
class SoundCueCookTests
{
	private const String cRoot = "scratch_audio_cue";
	private const String cClipType = "Sedulous.Audio.Resource.AudioClipSource";
	private const String cCueType = "Sedulous.Audio.Resource.SoundCueSource";

	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	/// Sparse slots FOLD DOWN into variants, a slot weighted to nothing is dropped, and a
	/// reversed pitch range is put back in order rather than sampled backwards.
	[Test]
	public static void SlotsCookIntoWeightedVariantsThatResolveTheirClips()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }

		AudioPipeline.RegisterAll();
		AudioResources.RegisterAll();

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "rasset");

		// Two cooked clips for the cue to draw from.
		let wav = scope List<uint8>();
		WavFixture.ToneWav(0.1f, wav);
		let clipIds = scope List<Guid>();
		for (int i < 2)
		{
			let instance = database.RootGroup.CreateInstance(scope $"clip{i}", cClipType);
			Test.Assert(instance != null);

			let record = scope AudioClipSource();
			record.Channels = 1;
			record.SampleRate = 8000;
			record.DurationSeconds = 0.1f;
			record.ContainerExtension.Set("wav");
			Test.Assert(instance.WriteObject(record) case .Ok);
			Test.Assert(instance.WriteData("data", wav) case .Ok);
			clipIds.Add(instance.Id);
		}

		let asset = scope SoundCueAsset();
		asset.Slots[0].ClipId = clipIds[0];
		asset.Slots[0].Weight = 2.0f;
		asset.Slots[3].ClipId = clipIds[1]; // a gap before it, which folds away
		asset.Slots[3].Weight = 1.0f;
		asset.Slots[5].ClipId = clipIds[1];
		asset.Slots[5].Weight = 0.0f; // weighted out, so never picked and never kept
		asset.PitchMin = 1.2f;
		asset.PitchMax = 0.8f; // reversed, so the builder puts it back in order

		let cueInstance = database.RootGroup.CreateInstance("cue", cCueType);
		Test.Assert(cueInstance != null);

		let context = scope AssetBuildContext();
		context.Output = cueInstance;
		context.Database = database;
		Test.Assert(scope SoundCueAssetBuilder().Build(asset, context) case .Ok);

		let manager = scope ResourceManager(database, null);
		let clips = scope AudioClipFactory();
		let cues = scope SoundCueFactory();
		manager.AddFactory(clips);
		manager.AddFactory(cues);

		let bound = manager.Bind<SoundCue>(cueInstance.Id);
		let cue = bound.Get;
		Test.Assert(cue != null);
		Test.Assert(cue.Variants.Count == 2);
		Test.Assert(Near(cue.Variants[0].Weight, 2.0f));
		Test.Assert(cue.Variants[0].Clip != null);
		Test.Assert(cue.Variants[0].Clip.SampleRate == 8000);
		Test.Assert(cue.Variants[1].Clip != null);
		Test.Assert(Near(cue.PitchMin, 0.8f));
		Test.Assert(Near(cue.PitchMax, 1.2f));
	}
}
