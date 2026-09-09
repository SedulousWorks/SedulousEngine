using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Animation;

/// Every track and event of one animation.
class AnimationClip
{
	public typealias Vec3Track = AnimationTrack<Float3>;
	public typealias QuatTrack = AnimationTrack<Quaternion>;

	public float Duration = 0.0f;
	public bool IsLooping = false;

	private String mName = new .() ~ delete _;

	public List<Vec3Track> PositionTracks = new .() ~ DeleteContainerAndItems!(_);
	public List<QuatTrack> RotationTracks = new .() ~ DeleteContainerAndItems!(_);
	public List<Vec3Track> ScaleTracks = new .() ~ DeleteContainerAndItems!(_);
	public List<AnimationEvent> Events = new .() ~ DeleteContainerAndItems!(_);

	public this() {}

	public this(StringView name, float duration = 0.0f, bool isLooping = false)
	{
		mName.Set(name);
		Duration = duration;
		IsLooping = isLooping;
	}

	public String Name => mName;

	public Vec3Track GetOrCreatePositionTrack(int32 boneIndex) =>
		GetOrCreate(PositionTracks, boneIndex);
	public QuatTrack GetOrCreateRotationTrack(int32 boneIndex) =>
		GetOrCreate(RotationTracks, boneIndex);
	public Vec3Track GetOrCreateScaleTrack(int32 boneIndex) =>
		GetOrCreate(ScaleTracks, boneIndex);

	public void SortAllKeyframes()
	{
		for (let track in PositionTracks)
			track.SortKeyframes();
		for (let track in RotationTracks)
			track.SortKeyframes();
		for (let track in ScaleTracks)
			track.SortKeyframes();
	}

	public void AddEvent(float time, StringView name)
	{
		Events.Add(new AnimationEvent(time, name));
	}

	/// A STABLE insertion sort, as for the keyframes: two events at one time keep the order
	/// they were authored in, which is the order they fire in.
	public void SortEvents()
	{
		for (int i = 1; i < Events.Count; i++)
		{
			let key = Events[i];
			var j = i;
			while ((j > 0) && (Events[j - 1].Time > key.Time))
			{
				Events[j] = Events[j - 1];
				j--;
			}
			Events[j] = key;
		}
	}

	/// Fires everything crossed in the half open span from the previous time to the current
	/// one, so an event exactly on the previous time does not fire twice.
	///
	/// The current time may run PAST the duration, which is how a loop is reported: the tail
	/// of the clip fires, then the head that was wrapped into.
	public void FireEvents(float prevTime, float currentTime, AnimationEventHandler handler)
	{
		if (Events.IsEmpty || (Duration <= 0.0f) || (handler == null))
			return;

		if ((currentTime > prevTime) && (currentTime <= Duration))
		{
			for (let event in Events)
			{
				if ((event.Time > prevTime) && (event.Time <= currentTime))
					handler(event.Name, event.Time);
			}
			return;
		}

		if (currentTime <= Duration)
			return;

		// Past the end: the tail always fires.
		for (let event in Events)
		{
			if ((event.Time > prevTime) && (event.Time <= Duration))
				handler(event.Name, event.Time);
		}

		if (!IsLooping)
			return;

		// And then whatever the wrap landed on. Subtracted rather than taken modulo so a
		// duration of nothing cannot divide, though the guard above already refuses one.
		var wrapped = currentTime;
		while (wrapped >= Duration)
			wrapped -= Duration;

		for (let event in Events)
		{
			if (event.Time <= wrapped)
				handler(event.Name, event.Time);
		}
	}

	/// The duration is the LAST keyframe across every track: a clip is as long as its
	/// longest track, not as long as whatever was authored in a field.
	public void ComputeDuration()
	{
		Duration = 0.0f;
		for (let track in PositionTracks)
		{
			if (!track.Keyframes.IsEmpty)
				Duration = Max(Duration, track.Keyframes[track.Keyframes.Count - 1].Time);
		}
		for (let track in RotationTracks)
		{
			if (!track.Keyframes.IsEmpty)
				Duration = Max(Duration, track.Keyframes[track.Keyframes.Count - 1].Time);
		}
		for (let track in ScaleTracks)
		{
			if (!track.Keyframes.IsEmpty)
				Duration = Max(Duration, track.Keyframes[track.Keyframes.Count - 1].Time);
		}
	}

	/// Resets THIS instance rather than answering a new one, so a hot reload keeps every
	/// reference to the clip valid.
	public void ClearForReload()
	{
		ClearAndDeleteItems!(PositionTracks);
		ClearAndDeleteItems!(RotationTracks);
		ClearAndDeleteItems!(ScaleTracks);
		ClearAndDeleteItems!(Events);
		Duration = 0.0f;
		IsLooping = false;
		mName.Clear();
	}

	/// The track for a bone, made if there is not one yet.
	///
	/// Generic on the VALUE rather than on the track, so one body serves the vector tracks
	/// and the rotation ones.
	private static AnimationTrack<T> GetOrCreate<T>(List<AnimationTrack<T>> tracks,
		int32 boneIndex) where T : struct
	{
		for (let existing in tracks)
		{
			if (existing.BoneIndex == boneIndex)
				return existing;
		}
		let track = new AnimationTrack<T>();
		track.BoneIndex = boneIndex;
		tracks.Add(track);
		return track;
	}
}
