using System;
using System.Collections;

namespace Sedulous.Audio;

/// One bus's tuning: its level, whether it is silenced, and its chain.
class AudioBusSettings
{
	public float Volume = 1.0f;
	public bool Muted = false;
	/// Applied IN ORDER between the bus and its parent. A link of no kind is skipped.
	public List<AudioBusEffectDesc> Effects = new .() ~ delete _;

	public void CopyFrom(AudioBusSettings other)
	{
		Volume = other.Volume;
		Muted = other.Muted;
		Effects.Clear();
		for (let effect in other.Effects)
			Effects.Add(effect);
	}
}
