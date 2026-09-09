using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Audio.Resource;

/// The cooked WIRE for a mixer layout: FLAT PARALLEL ARRAYS, so the serializer never nests.
///
/// The fixed four come first, in bus order, then the named buses; both index runs of ONE
/// shared effect pool. The wire stays generic even though today's editor authors a flat
/// chain, because a richer chain editor later then needs no change to the format.
// 2: the named custom bus section joined the fixed four.
[Serializable(2)]
class AudioBusLayoutSource
{
	// The fixed four, in bus order.
	public List<float> BusVolume = new .() ~ delete _;
	public List<bool> BusMuted = new .() ~ delete _;
	public List<uint32> BusEffectStart = new .() ~ delete _;
	public List<uint32> BusEffectCount = new .() ~ delete _;

	// The named buses, additive on top of the four.
	public List<String> CustomName = new .() ~ DeleteContainerAndItems!(_);
	public List<String> CustomParent = new .() ~ DeleteContainerAndItems!(_);
	public List<float> CustomVolume = new .() ~ delete _;
	public List<bool> CustomMuted = new .() ~ delete _;
	public List<uint32> CustomEffectStart = new .() ~ delete _;
	public List<uint32> CustomEffectCount = new .() ~ delete _;

	// The shared effect pool, which the runs above index.
	public List<uint8> EffectKind = new .() ~ delete _;
	public List<float> EffectFrequencyHz = new .() ~ delete _;
	public List<float> EffectDelaySeconds = new .() ~ delete _;
	public List<float> EffectDelayDecay = new .() ~ delete _;
	public List<float> EffectRoomSize = new .() ~ delete _;
	public List<float> EffectDamping = new .() ~ delete _;
	public List<float> EffectWetLevel = new .() ~ delete _;

	/// Flattens a layout into the wire, which is the cooking half.
	public static void FromLayout(AudioBusLayout layout, AudioBusLayoutSource outSource)
	{
		outSource.BusVolume.Clear();
		outSource.BusMuted.Clear();
		outSource.BusEffectStart.Clear();
		outSource.BusEffectCount.Clear();
		ClearAndDeleteItems!(outSource.CustomName);
		ClearAndDeleteItems!(outSource.CustomParent);
		outSource.CustomVolume.Clear();
		outSource.CustomMuted.Clear();
		outSource.CustomEffectStart.Clear();
		outSource.CustomEffectCount.Clear();
		outSource.EffectKind.Clear();
		outSource.EffectFrequencyHz.Clear();
		outSource.EffectDelaySeconds.Clear();
		outSource.EffectDelayDecay.Clear();
		outSource.EffectRoomSize.Clear();
		outSource.EffectDamping.Clear();
		outSource.EffectWetLevel.Clear();

		for (int bus = 0; bus < AudioBus.Count; bus++)
		{
			let settings = layout.Buses[bus];
			outSource.BusVolume.Add(settings.Volume);
			outSource.BusMuted.Add(settings.Muted);
			outSource.BusEffectStart.Add((uint32)outSource.EffectKind.Count);
			outSource.BusEffectCount.Add((uint32)settings.Effects.Count);
			AppendEffects(outSource, settings.Effects);
		}

		for (let named in layout.CustomBuses)
		{
			outSource.CustomName.Add(new String(named.Name));
			outSource.CustomParent.Add(new String(named.Parent));
			outSource.CustomVolume.Add(named.Settings.Volume);
			outSource.CustomMuted.Add(named.Settings.Muted);
			outSource.CustomEffectStart.Add((uint32)outSource.EffectKind.Count);
			outSource.CustomEffectCount.Add((uint32)named.Settings.Effects.Count);
			AppendEffects(outSource, named.Settings.Effects);
		}
	}

	/// Rebuilds a layout from the wire.
	///
	/// Every run is BOUNDED against the pool it reads from and every parallel array against
	/// the shortest of its siblings, so a malformed record yields a partial layout rather
	/// than a read past the end of an array.
	public void FillLayout(AudioBusLayout outLayout)
	{
		let buses = Min(AudioBus.Count,
			Min(Min(BusVolume.Count, BusMuted.Count),
				Min(BusEffectStart.Count, BusEffectCount.Count)));
		for (int bus = 0; bus < buses; bus++)
		{
			let settings = outLayout.Buses[bus];
			settings.Volume = BusVolume[bus];
			settings.Muted = BusMuted[bus];
			settings.Effects.Clear();
			ReadEffects(BusEffectStart[bus], BusEffectCount[bus], settings.Effects);
		}

		ClearAndDeleteItems!(outLayout.CustomBuses);
		let customs = Min(Min(CustomName.Count, CustomParent.Count),
			Min(Min(CustomVolume.Count, CustomMuted.Count),
				Min(CustomEffectStart.Count, CustomEffectCount.Count)));
		for (int i = 0; i < customs; i++)
		{
			let named = new AudioNamedBus();
			named.Name.Set(CustomName[i]);
			named.Parent.Set(CustomParent[i]);
			named.Settings.Volume = CustomVolume[i];
			named.Settings.Muted = CustomMuted[i];
			ReadEffects(CustomEffectStart[i], CustomEffectCount[i], named.Settings.Effects);
			outLayout.CustomBuses.Add(named);
		}
	}

	private static void AppendEffects(AudioBusLayoutSource outSource,
		List<AudioBusEffectDesc> effects)
	{
		for (let effect in effects)
		{
			outSource.EffectKind.Add((uint8)effect.Kind);
			outSource.EffectFrequencyHz.Add(effect.FrequencyHz);
			outSource.EffectDelaySeconds.Add(effect.DelaySeconds);
			outSource.EffectDelayDecay.Add(effect.DelayDecay);
			outSource.EffectRoomSize.Add(effect.RoomSize);
			outSource.EffectDamping.Add(effect.Damping);
			outSource.EffectWetLevel.Add(effect.WetLevel);
		}
	}

	private void ReadEffects(uint32 start, uint32 count, List<AudioBusEffectDesc> outEffects)
	{
		let pool = Min(EffectKind.Count,
			Min(Min(EffectFrequencyHz.Count, EffectDelaySeconds.Count),
				Min(Min(EffectDelayDecay.Count, EffectRoomSize.Count),
					Min(EffectDamping.Count, EffectWetLevel.Count))));

		let from = Min((int)start, pool);
		let to = Min(from + (int)count, pool);
		for (int i = from; i < to; i++)
		{
			var effect = AudioBusEffectDesc();
			effect.Kind = (AudioBusEffectKind)EffectKind[i];
			effect.FrequencyHz = EffectFrequencyHz[i];
			effect.DelaySeconds = EffectDelaySeconds[i];
			effect.DelayDecay = EffectDelayDecay[i];
			effect.RoomSize = EffectRoomSize[i];
			effect.Damping = EffectDamping[i];
			effect.WetLevel = EffectWetLevel[i];
			outEffects.Add(effect);
		}
	}
}
