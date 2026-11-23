using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.PropertyAnimation;
using Sedulous.Resource;
using Sedulous.Sequence;
using Sedulous.Sequence.Resource;
using Sedulous.VFS;

namespace Sedulous.Sequence.Pipeline.Tests;

/// The authoring to runtime path for a sequence: cooked and loaded, saved and read back, and made
/// by File > New.
class SequencePipelineTests
{
	private const String cRoot = "scratch_sequence_pipeline";
	private const String cProductType = "Sedulous.Sequence.Resource.SequenceSource";

	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// A walk over two seconds, a cue at one and a hold at one and a half, at 24 frames a second.
	private static void FillAuthored(Sedulous.Sequence.Sequence sequence)
	{
		sequence.FrameRate = 24.0f;
		sequence.Bindings.Add(new .("Mentor"));
		let walk = new PropertySequenceTrack();
		walk.Name.Set("walk");
		walk.Binding = 0;
		walk.Property.ComponentType.Set(TrackTargets.cTransform);
		walk.Property.PropertyPath.Set("Position");
		walk.Property.Kind = .Float3;
		walk.Property.Channels[0].AddKey(.(0.0f, 0.0f));
		walk.Property.Channels[0].AddKey(.(2.0f, 4.0f));
		sequence.Tracks.Add(walk);
		let cues = new EventSequenceTrack();
		cues.Keys.Add(new .(1.0f, "cue", "gate"));
		sequence.Tracks.Add(cues);
		sequence.Markers.Add(new .(1.5f, "line", true));
		sequence.Duration = sequence.ComputeDuration();
	}

	[Test]
	public static void AnAssetCooksToTheContentDatabaseAndTheFactoryLoadsIt()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }
		SequenceResources.RegisterAll();
		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("seq", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;

			let asset = scope SequenceAsset();
			FillAuthored(asset.Source.Sequence);
			let builder = scope SequenceAssetBuilder();
			Test.Assert(builder.AssetType == typeof(SequenceAsset));
			Test.Assert(builder.ProductType == typeof(SequenceSource));
			let context = scope AssetBuildContext();
			context.Output = instance;
			Test.Assert(builder.Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope SequenceFactory();
		manager.AddFactory(factory);

		let loaded = manager.Bind<SequenceResource>(id).Get;
		Test.Assert(loaded != null);
		let sequence = loaded.Sequence;
		Test.Assert(Near(sequence.Duration, 2.0f));
		Test.Assert(Near(sequence.FrameRate, 24.0f));
		Test.Assert(sequence.FindBinding("Mentor") == 0);
		Test.Assert((sequence.Markers.Count == 1) && sequence.Markers[0].Hold);
		Test.Assert(sequence.Tracks.Count == 2);
		let walk = sequence.Tracks[0] as PropertySequenceTrack;
		Test.Assert(walk != null);
		Test.Assert(Near(walk.Property.Sample(1.0f).Vector.X, 2.0f));
		Test.Assert(sequence.Tracks[1] is EventSequenceTrack);
	}

	/// The asset round trips through a serializer, which is what a save and an undo step are.
	[Test]
	public static void TheAssetKeepsItsFileNameAndSequenceThroughASave()
	{
		SequenceResources.RegisterAll();
		let asset = scope SequenceAsset();
		asset.FileName.Set("Cutscenes/gate.rasset");
		FillAuthored(asset.Source.Sequence);

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			((ISerializable)asset).Serialize(writer);
		}
		stream.Seek(0, .Begin);
		let restored = scope SequenceAsset();
		{
			let reader = scope BinarySerializer(stream, .Read);
			((ISerializable)restored).Serialize(reader);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(restored.FileName.Value == "Cutscenes/gate.rasset");
		Test.Assert(restored.Source.Sequence.Tracks.Count == 2);
		Test.Assert(restored.Source.Sequence.Markers.Count == 1);
	}

	[Test]
	public static void FileNewMakesAnEmptySequence()
	{
		let registry = scope AssetCreatorRegistry();
		SequenceCreators.Register(registry);
		let creator = registry.FindByType("Sedulous.Sequence.Pipeline.SequenceAsset");
		Test.Assert(creator != null);
		Test.Assert(creator.Label == "Sequence");
		Test.Assert(creator.Category == "Animation");
	}
}
