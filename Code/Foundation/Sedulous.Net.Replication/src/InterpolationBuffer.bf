using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Net.Replication;

/// A per entity, per component timeline of received replicated states, sampled at a DELAYED
/// render time so low rate updates play back smoothly.
///
/// Delay agnostic: the caller passes the render time, being now minus its chosen
/// interpolation delay. Record on network receive; Sample each frame to write the
/// interpolated fields onto the live component. Genre neutral.
///
/// DIVERGES from Raptor in what a sample holds. Raptor stores each replicated field as a
/// Variant; Beef's Variant allocates, so a sample here is a flat BYTE COPY of the component
/// and the fields are read back out at their own offsets. Only replicated fields are ever
/// read, so the two behave identically, and nothing in the copy is ever dereferenced or
/// destructed.
class InterpolationBuffer
{
	private class Sample
	{
		public double Time;
		public uint8[] Bytes ~ delete _;
	}

	private class Timeline
	{
		public List<Sample> Samples = new .() ~ DeleteContainerAndItems!(_);
	}

	private class EntityTimelines
	{
		public Dictionary<uint32, Timeline> ByType = new .() ~ DeleteDictionaryAndValues!(_);
	}

	/// How far back samples are kept. Older ones are pruned, except that the last two always
	/// survive: without a pair there is nothing to bracket a render time with.
	private double mHistoryMs = 1000.0;
	private Dictionary<uint32, EntityTimelines> mEntities = new .() ~ DeleteDictionaryAndValues!(_);

	public void SetHistoryMs(double milliseconds) => mHistoryMs = milliseconds;
	public int TrackedEntities => mEntities.Count;

	/// Snapshots a component's state at `timestampMs`.
	public void Record(NetworkId id, uint32 componentTypeHash, double timestampMs, Type type,
		void* address)
	{
		if ((type == null) || (address == null))
			return;

		EntityTimelines timelines;
		if (!mEntities.TryGetValue(id.Value, out timelines))
		{
			timelines = new EntityTimelines();
			mEntities[id.Value] = timelines;
		}

		Timeline timeline;
		if (!timelines.ByType.TryGetValue(componentTypeHash, out timeline))
		{
			timeline = new Timeline();
			timelines.ByType[componentTypeHash] = timeline;
		}

		let sample = new Sample();
		sample.Time = timestampMs;
		sample.Bytes = new uint8[type.Size];
		Internal.MemCpy(&sample.Bytes[0], address, type.Size);
		timeline.Samples.Add(sample);

		let cutoff = timestampMs - mHistoryMs;
		while ((timeline.Samples.Count > 2) && (timeline.Samples[0].Time < cutoff))
		{
			delete timeline.Samples[0];
			timeline.Samples.RemoveAt(0);
		}
	}

	/// Writes the fields interpolated at `renderTimeMs` onto the component at `address`.
	/// False when no samples exist.
	///
	/// Outside the buffered window the value CLAMPS to the earliest or latest sample. There is
	/// no extrapolation: a guess past the last known state is a position the server never had,
	/// and correcting it later is a visible snap.
	public bool Sample(NetworkId id, uint32 componentTypeHash, double renderTimeMs, Type type,
		void* address)
	{
		if ((type == null) || (address == null))
			return false;

		if (!mEntities.TryGetValue(id.Value, let timelines))
			return false;
		if (!timelines.ByType.TryGetValue(componentTypeHash, let timeline))
			return false;
		if (timeline.Samples.IsEmpty)
			return false;

		let samples = timeline.Samples;

		// The first sample at or after the render time.
		var after = samples.Count;
		for (int i < samples.Count)
		{
			if (samples[i].Time >= renderTimeMs)
			{
				after = i;
				break;
			}
		}

		Sample a;
		Sample b;
		var t = 0.0f;
		if (after == 0)
		{
			// Before the window: the earliest sample.
			a = samples[0];
			b = a;
		}
		else if (after >= samples.Count)
		{
			// After the window: the latest.
			a = samples[samples.Count - 1];
			b = a;
		}
		else
		{
			a = samples[after - 1];
			b = samples[after];
			let span = b.Time - a.Time;
			t = (span > 1e-9) ? (float)((renderTimeMs - a.Time) / span) : 0.0f;
		}

		for (let field in ReplicatedLayout.Fields(type))
		{
			FieldInterpolation.Lerp(field.FieldType, &a.Bytes[field.MemberOffset],
				&b.Bytes[field.MemberOffset], t, (uint8*)address + field.MemberOffset);
		}
		return true;
	}

	/// Drops an entity's timelines, on despawn or disconnect.
	public void Forget(NetworkId id)
	{
		if (mEntities.GetAndRemove(id.Value) case .Ok(let entry))
			delete entry.value;
	}
}
