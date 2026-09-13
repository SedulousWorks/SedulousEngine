using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Audio.Resource;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;

namespace Sedulous.Audio.Pipeline;

/// Folds the flat authored mixer into the wire's generic effect chain.
class AudioBusLayoutAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(AudioBusLayoutAsset);
	public Type ProductType => typeof(AudioBusLayoutSource);

	/// Two, for the custom buses.
	public int32 Version => 2;

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		let authored = (AudioBusLayoutAsset)asset;
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let name = authored.FileName.Value;
		let layout = scope AudioBusLayout();

		FoldBus(authored.Master, name, layout[.Master]);
		FoldBus(authored.Effects, name, layout[.Effects]);
		FoldBus(authored.Music, name, layout[.Music]);
		FoldBus(authored.UI, name, layout[.UI]);

		// The custom slots. A slot shadowing a fixed bus, or repeating another slot's name,
		// is SKIPPED with a warning: the mixer still works, minus one bus the author can see
		// is missing.
		for (let slot in authored.Custom)
		{
			if (slot.Name.IsEmpty)
				continue;

			if (AudioBusNames.TryParse(slot.Name, ?))
			{
				GlobalLog(.Warning,
					"Audio: the bus layout '{}' has a custom bus '{}' shadowing a fixed one, so the slot is skipped",
					name, slot.Name);
				continue;
			}

			var duplicate = false;
			for (let existing in layout.CustomBuses)
			{
				if (existing.Name == slot.Name)
				{
					duplicate = true;
					break;
				}
			}
			if (duplicate)
			{
				GlobalLog(.Warning,
					"Audio: the bus layout '{}' repeats the custom bus '{}', so the slot is skipped",
					name, slot.Name);
				continue;
			}

			let named = new AudioNamedBus();
			named.Name.Set(slot.Name);
			named.Parent.Set(slot.Parent);
			FoldBus(slot.Bus, name, named.Settings);
			layout.CustomBuses.Add(named);
		}

		// A parent CYCLE is a broken mixer and FAILS the cook, unlike an unknown parent, which
		// only warns at apply and falls back to the master bus. A cycle has no fallback: every
		// bus in it waits on another.
		if (HasParentCycle(layout, name) case .Err(let cycleError))
			return .Err(cycleError);

		let cooked = scope AudioBusLayoutSource();
		AudioBusLayoutSource.FromLayout(layout, cooked);
		return context.Output.WriteObject(cooked);
	}

	/// The flat editor fields into the generic chain, in a fixed order so the same authoring
	/// always produces the same wire.
	private static void FoldBus(AudioBusAuthoring bus, StringView assetName,
		AudioBusSettings outSettings)
	{
		outSettings.Volume = Math.Clamp(bus.Volume, 0.0f, 4.0f);
		outSettings.Muted = bus.Muted;

		if (bus.LowpassHz > 0.0f)
		{
			AudioBusEffectDesc effect = .();
			effect.Kind = .Lowpass;
			effect.FrequencyHz = bus.LowpassHz;
			outSettings.Effects.Add(effect);
		}
		if (bus.HighpassHz > 0.0f)
		{
			AudioBusEffectDesc effect = .();
			effect.Kind = .Highpass;
			effect.FrequencyHz = bus.HighpassHz;
			outSettings.Effects.Add(effect);
		}
		if (bus.DelaySeconds > 0.0f)
		{
			AudioBusEffectDesc effect = .();
			effect.Kind = .Delay;
			effect.DelaySeconds = bus.DelaySeconds;
			effect.DelayDecay = Math.Clamp(bus.DelayDecay, 0.0f, 0.99f);
			if (bus.DelayDecay >= 1.0f)
			{
				GlobalLog(.Warning,
					"Audio: the bus layout '{}' asks for a delay decay of one or more, which self oscillates, so it is clamped",
					assetName);
			}
			outSettings.Effects.Add(effect);
		}
		if (bus.ReverbWet > 0.0f)
		{
			AudioBusEffectDesc effect = .();
			effect.Kind = .Reverb;
			effect.RoomSize = Math.Clamp(bus.ReverbRoomSize, 0.0f, 1.0f);
			effect.Damping = Math.Clamp(bus.ReverbDamping, 0.0f, 1.0f);
			effect.WetLevel = Math.Clamp(bus.ReverbWet, 0.0f, 1.0f);
			outSettings.Effects.Add(effect);
		}
	}

	private static Result<void, ErrorCode> HasParentCycle(AudioBusLayout layout,
		StringView assetName)
	{
		for (int i < layout.CustomBuses.Count)
		{
			var cursor = i;
			var steps = 0;
			while (true)
			{
				let parent = layout.CustomBuses[cursor].Parent;
				if (parent.IsEmpty || AudioBusNames.TryParse(parent, ?))
					break; // it reached a fixed bus, so this chain terminates

				var found = false;
				for (int j < layout.CustomBuses.Count)
				{
					if (layout.CustomBuses[j].Name == parent)
					{
						cursor = j;
						found = true;
						break;
					}
				}
				if (!found)
					break; // an unknown parent, which is warned about at apply rather than here

				if ((cursor == i) || (++steps > layout.CustomBuses.Count))
				{
					GlobalLog(.Error,
						"Audio: the bus layout '{}' has the custom bus '{}' in a parent cycle, so the cook failed",
						assetName, layout.CustomBuses[i].Name);
					return .Err(.InvalidArgument);
				}
			}
		}
		return .Ok;
	}
}
