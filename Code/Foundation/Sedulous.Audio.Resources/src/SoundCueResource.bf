using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Resources;
using Sedulous.Serialization;

using static Sedulous.Resources.ResourceSerializerExtensions;

namespace Sedulous.Audio.Resources;

/// Resource wrapper for SoundCue, enabling integration with the ResourceSystem.
/// Serializes cue configuration (selection mode, entries, limits).
/// Entry clips are stored as ResourceRefs and resolved at load time.
class SoundCueResource : Resource
{
	public const int32 FileVersion = 1;
	public override ResourceType ResourceType => .("soundcue");
	public override int32 SerializationVersion => FileVersion;

	private SoundCue mCue ~ delete _;

	/// Gets the wrapped sound cue.
	public SoundCue Cue => mCue;

	/// Clip resource references for each entry (parallel to Cue.Entries).
	/// Resolved by the resource manager after loading.
	public List<ResourceRef> ClipRefs = new .() ~ { for (var r in _) r.Dispose(); delete _; };

	public this()
	{
		mCue = new SoundCue();
	}

	protected override SerializationResult OnSerialize(Serializer s)
	{
		// Selection mode
		var mode = (uint8)mCue.SelectionMode;
		s.UInt8("SelectionMode", ref mode);
		if (s.IsReading) mCue.SelectionMode = (CueSelectionMode)mode;

		// Limits
		s.Int32("MaxInstances", ref mCue.MaxInstances);
		s.Int32("Priority", ref mCue.Priority);
		s.Float("Cooldown", ref mCue.Cooldown);

		// Bus name
		s.String("BusName", mCue.BusName);

		// Entry count
		var entryCount = (int32)mCue.Entries.Count;
		s.Int32("EntryCount", ref entryCount);

		if (s.IsReading)
		{
			mCue.Entries.Clear();
			ClipRefs.Clear();

			for (int32 i = 0; i < entryCount; i++)
			{
				SoundCueEntry entry = .();
				s.Float("Weight", ref entry.Weight);
				s.Float("VolumeMin", ref entry.VolumeMin);
				s.Float("VolumeMax", ref entry.VolumeMax);
				s.Float("PitchMin", ref entry.PitchMin);
				s.Float("PitchMax", ref entry.PitchMax);

				mCue.Entries.Add(entry);

				var clipRef = ResourceRef();
				s.ResourceRef("ClipRef", ref clipRef);
				ClipRefs.Add(clipRef);
			}
		}
		else
		{
			for (int32 i = 0; i < entryCount; i++)
			{
				var entry = mCue.Entries[i];
				s.Float("Weight", ref entry.Weight);
				s.Float("VolumeMin", ref entry.VolumeMin);
				s.Float("VolumeMax", ref entry.VolumeMax);
				s.Float("PitchMin", ref entry.PitchMin);
				s.Float("PitchMax", ref entry.PitchMax);

				var clipRef = ClipRefs[i];
				s.ResourceRef("ClipRef", ref clipRef);
			}
		}

		return .Ok;
	}
}
