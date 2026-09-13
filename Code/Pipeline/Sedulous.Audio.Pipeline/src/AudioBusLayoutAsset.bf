using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Audio.Pipeline;

/// The mixer, as the inspector edits it.
[Serializable]
class AudioBusLayoutAsset : Asset
{
	/// How many custom buses an author can add.
	public const int cCustomBusSlotCount = 8;

	public AudioBusAuthoring Master = new .() ~ delete _;
	public AudioBusAuthoring Effects = new .() ~ delete _;
	public AudioBusAuthoring Music = new .() ~ delete _;
	public AudioBusAuthoring UI = new .() ~ delete _;

	public List<AudioCustomBusSlot> Custom = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		for (int i < cCustomBusSlotCount)
			Custom.Add(new AudioCustomBusSlot());
	}
}
