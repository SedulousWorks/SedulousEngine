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
	/// Call ResolveClips() to populate Cue.Entries[i].Clip from these refs.
	public List<ResourceRef> ClipRefs = new .() ~ { for (var r in _) r.Dispose(); delete _; };

	/// Loaded clip resource handles (kept alive for the lifetime of this resource).
	/// Populated by ResolveClips; released on destruction and on re-resolve.
	private List<ResourceHandle<AudioClipResource>> mClipHandles = new .() ~ {
		for (var h in _) h.Release();
		delete _;
	};

	public this()
	{
		mCue = new SoundCue();
	}

	/// Resolves the per-entry ClipRefs to AudioClips via the resource system and
	/// populates Cue.Entries[i].Clip. Call after load and after any mutation that
	/// changes ClipRefs (editor picker, add, remove). Releases previously-resolved
	/// handles before re-resolving.
	public bool ResolveClips(ResourceSystem resourceSystem)
	{
		if (resourceSystem == null || mCue == null)
			return false;

		for (var h in mClipHandles)
			h.Release();
		mClipHandles.Clear();

		bool allResolved = true;
		let count = (ClipRefs.Count < mCue.Entries.Count) ? ClipRefs.Count : mCue.Entries.Count;
		for (int i = 0; i < count; i++)
		{
			let clipRef = ClipRefs[i];
			var entry = mCue.Entries[i];

			if (!clipRef.IsValid)
			{
				entry.Clip = null;
				mCue.Entries[i] = entry;
				continue;
			}

			if (resourceSystem.LoadByRef<AudioClipResource>(clipRef) case .Ok(let handle))
			{
				entry.Clip = handle.Resource?.Clip;
				mCue.Entries[i] = entry;
				mClipHandles.Add(handle);
			}
			else
			{
				entry.Clip = null;
				mCue.Entries[i] = entry;
				allResolved = false;
			}
		}

		return allResolved;
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

		// Each entry gets its own object scope so the per-entry fields
		// don't collide at the top level when there is more than one entry.
		s.BeginObject("Entries");

		if (s.IsReading)
		{
			mCue.Entries.Clear();
			// Dispose the owned Path strings before dropping the refs -
			// List.Clear() does not, so a reload (re-Serialize on an
			// already-populated resource) would leak every clip path.
			for (var r in ClipRefs)
				r.Dispose();
			ClipRefs.Clear();

			for (int32 i = 0; i < entryCount; i++)
			{
				s.BeginObject(scope $"e{i}");

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

				s.EndObject();
			}
		}
		else
		{
			for (int32 i = 0; i < entryCount; i++)
			{
				s.BeginObject(scope $"e{i}");

				var entry = mCue.Entries[i];
				s.Float("Weight", ref entry.Weight);
				s.Float("VolumeMin", ref entry.VolumeMin);
				s.Float("VolumeMax", ref entry.VolumeMax);
				s.Float("PitchMin", ref entry.PitchMin);
				s.Float("PitchMax", ref entry.PitchMax);

				var clipRef = ClipRefs[i];
				s.ResourceRef("ClipRef", ref clipRef);

				s.EndObject();
			}
		}

		s.EndObject();

		return .Ok;
	}
}
