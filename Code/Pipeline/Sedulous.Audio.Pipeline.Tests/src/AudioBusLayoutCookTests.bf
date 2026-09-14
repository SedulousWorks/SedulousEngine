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

/// The mixer's bus layout, from flat authored fields to the effect chain the engine runs.
///
/// FLAT on the authoring side on purpose: a page of numbers is what a person edits, and the
/// builder is what turns a lowpass frequency and a delay time into an ordered chain.
class AudioBusLayoutCookTests
{
	private const String cRoot = "scratch_audio_bus";
	private const String cProductType = "Sedulous.Audio.Resource.AudioBusLayoutSource";

	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	private static void MakeRoot()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		AudioPipeline.RegisterAll();
		AudioResources.RegisterAll();
	}

	/// Binds the cooked layout, running the body with it.
	private static void CookAndBind(AudioBusLayoutAsset asset,
		delegate void(AudioBusLayoutResource layout) body)
	{
		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "rasset");

		let instance = database.RootGroup.CreateInstance("mixer", cProductType);
		Test.Assert(instance != null);

		let context = scope AssetBuildContext();
		context.Output = instance;
		Test.Assert(scope AudioBusLayoutAssetBuilder().Build(asset, context) case .Ok);

		let manager = scope ResourceManager(database, null);
		let factory = scope AudioBusLayoutFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<AudioBusLayoutResource>(instance.Id);
		Test.Assert(bound.Get != null);
		body(bound.Get);
	}

	/// The flat fields become an ORDERED chain, and a value outside its range is clamped rather
	/// than carried: a delay that feeds back above unity never decays.
	[Test]
	public static void TheFlatFieldsCookIntoAnOrderedEffectChain()
	{
		MakeRoot();
		defer { RemoveDirectoryRecursive(cRoot); }

		let asset = scope AudioBusLayoutAsset();
		asset.Music.Volume = 0.5f;
		asset.UI.Muted = true;
		asset.Effects.LowpassHz = 3000.0f;
		asset.Effects.DelaySeconds = 0.2f;
		asset.Effects.DelayDecay = 1.5f; // above unity, so the builder clamps it

		CookAndBind(asset, scope (layout) =>
			{
				Test.Assert(Near(layout.Layout[AudioBus.Music].Volume, 0.5f));
				Test.Assert(layout.Layout[AudioBus.UI].Muted);

				let effects = layout.Layout[AudioBus.Effects];
				Test.Assert(effects.Effects.Count == 2);
				// The order is the chain's: filters before the delay that follows them.
				Test.Assert(effects.Effects[0].Kind == .Lowpass);
				Test.Assert(Near(effects.Effects[0].FrequencyHz, 3000.0f));
				Test.Assert(effects.Effects[1].Kind == .Delay);
				Test.Assert(Near(effects.Effects[1].DelayDecay, 0.99f));
			});
	}

	/// Custom buses cook into their own named section, sparse slots fold down, and a name that
	/// would collide is SKIPPED rather than shadowing what it collides with.
	[Test]
	public static void CustomBusSlotsFoldDownAndCollisionsAreSkipped()
	{
		MakeRoot();
		defer { RemoveDirectoryRecursive(cRoot); }

		let asset = scope AudioBusLayoutAsset();
		asset.Custom[0].Name.Set("drums");
		asset.Custom[0].Parent.Set("effects"); // a fixed parent, matched without case
		asset.Custom[0].Bus.Volume = 0.6f;
		asset.Custom[0].Bus.LowpassHz = 2500.0f;

		asset.Custom[2].Name.Set("quiet");   // a gap before it, which folds away
		asset.Custom[2].Parent.Set("drums"); // a custom bus under another
		asset.Custom[2].Bus.Muted = true;

		asset.Custom[4].Name.Set("drums"); // a duplicate name
		asset.Custom[5].Name.Set("Music"); // and one shadowing a fixed bus

		CookAndBind(asset, scope (layout) =>
			{
				Test.Assert(layout.Layout.CustomBuses.Count == 2);

				Test.Assert(layout.Layout.CustomBuses[0].Name == "drums");
				Test.Assert(layout.Layout.CustomBuses[0].Parent == "effects");
				Test.Assert(Near(layout.Layout.CustomBuses[0].Settings.Volume, 0.6f));
				Test.Assert(layout.Layout.CustomBuses[0].Settings.Effects.Count == 1);
				Test.Assert(layout.Layout.CustomBuses[0].Settings.Effects[0].Kind == .Lowpass);

				Test.Assert(layout.Layout.CustomBuses[1].Name == "quiet");
				Test.Assert(layout.Layout.CustomBuses[1].Settings.Muted);
			});
	}
}
