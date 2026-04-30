namespace Sedulous.Audio;

using System;
using Sedulous.Audio.Graph;

/// A named mixing bus in the audio bus hierarchy.
/// Sources route their output to a bus. Each bus has volume, mute,
/// an ordered effects chain, and a parent bus.
interface IAudioBus
{
	/// Unique name of this bus (e.g., "Master", "SFX", "Music").
	StringView Name { get; }

	/// Bus volume multiplier (0.0 to 1.0). Applied after effects.
	float Volume { get; set; }

	/// Whether this bus is muted (output silenced but processing continues).
	bool Muted { get; set; }

	/// Parent bus this bus routes to. null for the Master bus.
	IAudioBus Parent { get; }

	/// Number of effects in this bus's chain.
	int EffectCount { get; }

	/// Gets the effect at the specified index.
	IAudioEffect GetEffect(int index);

	/// Adds an effect to the end of the chain. Bus takes ownership.
	void AddEffect(IAudioEffect effect);

	/// Inserts an effect at the specified index. Bus takes ownership.
	void InsertEffect(int index, IAudioEffect effect);

	/// Removes and returns the effect at the specified index.
	/// Caller takes ownership of the returned effect.
	IAudioEffect RemoveEffect(int index);

	/// Removes all effects.
	void ClearEffects(bool deleteEffects = true);

	/// The CombineNode that sources mix into (advanced graph access).
	CombineNode InputNode { get; }

	/// The VolumeNode at the end of the bus chain (advanced graph access).
	VolumeNode OutputNode { get; }
}
