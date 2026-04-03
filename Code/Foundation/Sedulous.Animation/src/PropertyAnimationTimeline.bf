namespace Sedulous.Animation;

using System;
using System.Collections;
using Sedulous.Serialization;

/// An entry in a property animation timeline, binding a clip to an entity at a start time.
public class TimelineEntry : ISerializable
{
	/// Logical entity index (resolved to an actual EntityId at runtime).
	public int32 EntityIndex;

	/// Start time of this entry within the timeline.
	public float StartTime;

	/// The property animation clip for this entry (owned).
	public PropertyAnimationClip Clip ~ delete _;

	public int32 SerializationVersion => 1;

	public this()
	{
	}

	public this(int32 entityIndex, float startTime, PropertyAnimationClip clip)
	{
		EntityIndex = entityIndex;
		StartTime = startTime;
		Clip = clip;
	}

	public SerializationResult Serialize(Serializer s)
	{
		s.Int32("entityIndex", ref EntityIndex);
		s.Float("startTime", ref StartTime);

		if (s.IsWriting)
		{
			if (Clip == null)
				return .InvalidData;

			s.BeginObject("clip");
			Clip.Serialize(s);
			s.EndObject();
		}
		else
		{
			Clip = new PropertyAnimationClip();
			s.BeginObject("clip");
			Clip.Serialize(s);
			s.EndObject();
		}

		return .Ok;
	}
}

/// A timeline containing multiple property animation clips for multiple entities.
/// Used for cutscenes and multi-entity choreographed animations.
public class PropertyAnimationTimeline : ISerializable
{
	/// Name of this timeline.
	public String Name ~ delete _;

	/// Total duration in seconds.
	public float Duration;

	/// Whether this timeline should loop.
	public bool IsLooping;

	/// Timeline entries (owned).
	public List<TimelineEntry> Entries = new .() ~ DeleteContainerAndItems!(_);

	public int32 SerializationVersion => 1;

	public this()
	{
		Name = new .();
	}

	public this(StringView name, float duration = 0, bool isLooping = false)
	{
		Name = new .(name);
		Duration = duration;
		IsLooping = isLooping;
	}

	/// Adds a timeline entry.
	public TimelineEntry AddEntry(int32 entityIndex, float startTime, PropertyAnimationClip clip)
	{
		let entry = new TimelineEntry(entityIndex, startTime, clip);
		Entries.Add(entry);
		return entry;
	}

	/// Computes the duration from the latest entry end time.
	public void ComputeDuration()
	{
		Duration = 0;
		for (let entry in Entries)
		{
			if (entry.Clip != null)
			{
				let endTime = entry.StartTime + entry.Clip.Duration;
				Duration = Math.Max(Duration, endTime);
			}
		}
	}

	public SerializationResult Serialize(Serializer s)
	{
		if (s.IsWriting)
		{
			String name = scope String(Name);
			s.String("name", name);
		}
		else
		{
			Name.Clear();
			s.String("name", Name);
		}

		s.Float("duration", ref Duration);
		s.Bool("isLooping", ref IsLooping);

		s.ObjectList("entries", Entries);

		return .Ok;
	}
}
