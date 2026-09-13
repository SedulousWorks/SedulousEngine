using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Audio.Pipeline;

/// Weighted clip variants with a little randomisation, so a repeated sound is not identical
/// every time.
///
/// A FIXED bank of slots rather than a list, so the generic property page edits it without an
/// array editor.
[Serializable]
class SoundCueAsset : Asset
{
	public const int cSlotCount = 8;

	public List<SoundCueSlot> Slots = new .() ~ DeleteContainerAndItems!(_);

	public uint8 Mode = 0;
	public float PitchMin = 1.0f;
	public float PitchMax = 1.0f;
	public float VolumeMin = 1.0f;
	public float VolumeMax = 1.0f;

	public this()
	{
		for (int i < cSlotCount)
			Slots.Add(new SoundCueSlot());
	}
}
