using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.Audio.Pipeline;

/// The audio domain's New Asset creators: a bus layout and a sound cue at their defaults.
static class AudioCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Audio Bus Layout", "Audio", typeof(AudioBusLayoutAsset), new (context) =>
			AssetCreator.CreateWritten(context.Target, context.NameOr("BusLayout"), typeof(AudioBusLayoutAsset), scope AudioBusLayoutAsset())));
		registry.Register(new AssetCreator("Sound Cue", "Audio", typeof(SoundCueAsset), new (context) =>
			AssetCreator.CreateWritten(context.Target, context.NameOr("SoundCue"), typeof(SoundCueAsset), scope SoundCueAsset())));
	}
}
