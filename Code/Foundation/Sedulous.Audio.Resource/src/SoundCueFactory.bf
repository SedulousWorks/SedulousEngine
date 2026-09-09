using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Resource;

namespace Sedulous.Audio.Resource;

/// Builds a cooked cue, binding each variant's clip through the manager.
///
/// SYNCHRONOUS ONLY: the binds are what record the cue to clip edges, and an edge is the
/// manager's to write on the thread that owns it. A clip binds asynchronously on its own.
class SoundCueFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<SoundCue>();

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as SoundCueSource;
		if (source == null)
		{
			delete stored;
			return null;
		}
		defer delete source;

		let cue = new SoundCue();
		cue.Mode = (SoundCueMode)source.Mode;
		cue.PitchMin = source.PitchMin;
		cue.PitchMax = source.PitchMax;
		cue.VolumeMin = source.VolumeMin;
		cue.VolumeMax = source.VolumeMax;

		let count = Min(source.ClipId.Count, source.Weight.Count);
		for (int i = 0; i < count; i++)
		{
			var variant = SoundCueVariant();
			variant.Weight = source.Weight[i];

			// A nil id is an empty slot, which resolving skips: an authored gap in a cue is
			// not an error.
			if (source.ClipId[i] != Guid())
			{
				// The bind is what records the cue to clip edge, so this is not merely a
				// lookup: it is how a reimported clip reaches every cue playing it. A clip
				// still decoding leaves the slot empty rather than stalling the cue.
				let clip = manager.Bind<AudioClip>(source.ClipId[i]);
				variant.Clip = clip.Get;
			}

			cue.Variants.Add(variant);
		}
		return cue;
	}
}
