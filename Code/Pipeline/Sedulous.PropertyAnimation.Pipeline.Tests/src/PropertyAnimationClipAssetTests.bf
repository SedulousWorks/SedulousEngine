using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.PropertyAnimation;
using Sedulous.PropertyAnimation.Resource;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.PropertyAnimation.Pipeline.Tests;

/// The authoring to runtime path for a property clip.
class PropertyAnimationClipAssetTests
{
	private const String cRoot = "scratch_propanim_pipeline";
	private const String cProductType = "Sedulous.PropertyAnimation.Resource.PropertyAnimationClipSource";

	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	/// One position track running from nought to ten over a second: cooked, read back, and
	/// SAMPLED, which is the only thing that proves the keys survived in the right order.
	[Test]
	public static void ACookedClipLoadsBackAndSamples()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }

		PropertyAnimationResources.RegisterAll();

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("clip", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;

			let clip = scope PropertyAnimationClip();
			let track = new PropertyTrack();
			track.ComponentType.Set("Transform");
			track.PropertyPath.Set("Position");
			track.Kind = .Float3;
			track.Channels[0].AddKey(.(0.0f, 0.0f));
			track.Channels[0].AddKey(.(1.0f, 10.0f));
			clip.Tracks.Add(track);

			let asset = scope PropertyAnimationClipAsset();
			PropertyAnimationClipSource.FromClip(clip, asset.Source);

			let builder = scope PropertyAnimationClipAssetBuilder();
			Test.Assert(builder.AssetType == typeof(PropertyAnimationClipAsset));
			Test.Assert(builder.ProductType == typeof(PropertyAnimationClipSource));

			let context = scope AssetBuildContext();
			context.Output = instance;
			Test.Assert(builder.Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope PropertyAnimationClipFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<PropertyAnimationClip>(id);
		let clip = bound.Get;
		Test.Assert(clip != null);
		Test.Assert(clip.Tracks.Count == 1);
		Test.Assert(clip.Tracks[0].PropertyPath == "Position");
		Test.Assert(Near(clip.Tracks[0].Duration, 1.0f));
		Test.Assert(Near(clip.Tracks[0].Sample(0.5f).Vector.X, 5.0f));
	}

	/// The asset round trips through a serializer, which is what a save and an undo step are.
	[Test]
	public static void TheAssetRoundTripsThroughASerializer()
	{
		let asset = scope PropertyAnimationClipAsset();
		asset.FileName.Set("Clips/pulse.rasset");
		asset.Source.Duration = 2.5f;
		asset.Source.TrackKind.Add((uint8)TrackValueKind.Float);
		asset.Source.TrackComponent.Add(new String("Light"));
		asset.Source.TrackPath.Add(new String("Intensity"));

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			((ISerializable)asset).Serialize(writer);
		}
		stream.Seek(0, .Begin);

		let restored = scope PropertyAnimationClipAsset();
		{
			let reader = scope BinarySerializer(stream, .Read);
			((ISerializable)restored).Serialize(reader);
		}

		Test.Assert(restored.FileName.Value == "Clips/pulse.rasset");
		Test.Assert(Near(restored.Source.Duration, 2.5f));
		Test.Assert(restored.Source.TrackPath.Count == 1);
		Test.Assert(restored.Source.TrackPath[0] == "Intensity");
	}
}
