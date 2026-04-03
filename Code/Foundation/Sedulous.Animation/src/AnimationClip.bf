namespace Sedulous.Animation;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Interpolation mode for animation keyframes.
public enum InterpolationMode
{
	/// No interpolation - holds previous value until next keyframe.
	Step,
	/// Linear interpolation between keyframes.
	Linear,
	/// Cubic spline interpolation for smooth curves.
	CubicSpline
}

/// A keyframe storing a value at a specific time.
public struct Keyframe<T>
{
	/// Time in seconds from the start of the animation.
	public float Time;
	/// The value at this keyframe.
	public T Value;
	/// Incoming tangent (for cubic spline interpolation).
	public T InTangent;
	/// Outgoing tangent (for cubic spline interpolation).
	public T OutTangent;

	public this(float time, T value)
	{
		Time = time;
		Value = value;
		InTangent = default;
		OutTangent = default;
	}

	public this(float time, T value, T inTangent, T outTangent)
	{
		Time = time;
		Value = value;
		InTangent = inTangent;
		OutTangent = outTangent;
	}
}

/// An animation track containing keyframes for a single property of a bone.
public class AnimationTrack<T>
{
	/// Index of the bone this track affects.
	public int32 BoneIndex;

	/// Keyframes sorted by time.
	public List<Keyframe<T>> Keyframes = new .() ~ delete _;

	/// Interpolation mode for this track.
	public InterpolationMode Interpolation = .Linear;

	/// Adds a keyframe to the track.
	public void AddKeyframe(float time, T value)
	{
		Keyframes.Add(.(time, value));
	}

	/// Adds a keyframe with tangents for cubic spline interpolation.
	public void AddKeyframe(float time, T value, T inTangent, T outTangent)
	{
		Keyframes.Add(.(time, value, inTangent, outTangent));
	}

	/// Sorts keyframes by time. Call after adding all keyframes.
	public void SortKeyframes()
	{
		Keyframes.Sort(scope (a, b) => a.Time <=> b.Time);
	}

	/// Finds the keyframe indices surrounding the given time.
	/// Returns (prevIndex, nextIndex, t) where t is the interpolation factor.
	public (int32 prev, int32 next, float t) FindKeyframes(float time)
	{
		if (Keyframes.Count == 0)
			return (-1, -1, 0);

		if (Keyframes.Count == 1)
			return (0, 0, 0);

		// Before first keyframe
		if (time <= Keyframes[0].Time)
			return (0, 0, 0);

		// After last keyframe
		if (time >= Keyframes[Keyframes.Count - 1].Time)
		{
			let lastIdx = (int32)(Keyframes.Count - 1);
			return (lastIdx, lastIdx, 0);
		}

		// Binary search for the interval containing time
		int32 low = 0;
		int32 high = (int32)(Keyframes.Count - 1);

		while (low < high - 1)
		{
			let mid = (low + high) / 2;
			if (Keyframes[mid].Time <= time)
				low = mid;
			else
				high = mid;
		}

		let duration = Keyframes[high].Time - Keyframes[low].Time;
		let t = duration > 0 ? (time - Keyframes[low].Time) / duration : 0;
		return (low, high, t);
	}
}

/// Contains all animation tracks for a single animation.
public class AnimationClip
{
	/// Name of this animation clip.
	public String Name ~ delete _;

	/// Duration of the animation in seconds.
	public float Duration;

	/// Whether this animation should loop.
	public bool IsLooping;

	/// Position tracks (one per animated bone).
	public List<AnimationTrack<Vector3>> PositionTracks = new .() ~ DeleteContainerAndItems!(_);

	/// Rotation tracks (one per animated bone).
	public List<AnimationTrack<Quaternion>> RotationTracks = new .() ~ DeleteContainerAndItems!(_);

	/// Scale tracks (one per animated bone).
	public List<AnimationTrack<Vector3>> ScaleTracks = new .() ~ DeleteContainerAndItems!(_);

	/// Animation events sorted by time.
	public List<AnimationEvent> Events = new .() ~ DeleteContainerAndItems!(_);

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

	/// Gets or creates a position track for the specified bone.
	public AnimationTrack<Vector3> GetOrCreatePositionTrack(int32 boneIndex)
	{
		for (let track in PositionTracks)
		{
			if (track.BoneIndex == boneIndex)
				return track;
		}

		let track = new AnimationTrack<Vector3>();
		track.BoneIndex = boneIndex;
		PositionTracks.Add(track);
		return track;
	}

	/// Gets or creates a rotation track for the specified bone.
	public AnimationTrack<Quaternion> GetOrCreateRotationTrack(int32 boneIndex)
	{
		for (let track in RotationTracks)
		{
			if (track.BoneIndex == boneIndex)
				return track;
		}

		let track = new AnimationTrack<Quaternion>();
		track.BoneIndex = boneIndex;
		RotationTracks.Add(track);
		return track;
	}

	/// Gets or creates a scale track for the specified bone.
	public AnimationTrack<Vector3> GetOrCreateScaleTrack(int32 boneIndex)
	{
		for (let track in ScaleTracks)
		{
			if (track.BoneIndex == boneIndex)
				return track;
		}

		let track = new AnimationTrack<Vector3>();
		track.BoneIndex = boneIndex;
		ScaleTracks.Add(track);
		return track;
	}

	/// Sorts all keyframes in all tracks by time.
	public void SortAllKeyframes()
	{
		for (let track in PositionTracks)
			track.SortKeyframes();
		for (let track in RotationTracks)
			track.SortKeyframes();
		for (let track in ScaleTracks)
			track.SortKeyframes();
	}

	/// Adds an animation event at the specified time.
	public void AddEvent(float time, StringView name)
	{
		Events.Add(new AnimationEvent(time, name));
	}

	/// Sorts events by time. Call after adding all events.
	public void SortEvents()
	{
		Events.Sort(scope (a, b) => a.Time <=> b.Time);
	}

	/// Fires events that were crossed between prevTime and currentTime (both in absolute seconds).
	/// prevTime is the wrapped time from the previous frame.
	/// currentTime is the raw time after advancing (may exceed Duration if looping).
	public void FireEvents(float prevTime, float currentTime, AnimationEventHandler handler)
	{
		if (handler == null || Events.Count == 0 || Duration <= 0)
			return;

		// Only handle forward playback (currentTime >= prevTime or loop wrap)
		if (currentTime > prevTime && currentTime <= Duration)
		{
			// Simple case: no wrap, fire events in (prevTime, currentTime]
			for (let evt in Events)
			{
				if (evt.Time > prevTime && evt.Time <= currentTime)
					handler(evt.Name, evt.Time);
			}
		}
		else if (currentTime > Duration)
		{
			if (IsLooping)
			{
				// Looped past end: fire (prevTime, Duration] then [0, wrappedTime]
				for (let evt in Events)
				{
					if (evt.Time > prevTime && evt.Time <= Duration)
						handler(evt.Name, evt.Time);
				}

				var wrappedTime = currentTime;
				while (wrappedTime >= Duration)
					wrappedTime -= Duration;

				for (let evt in Events)
				{
					if (evt.Time <= wrappedTime)
						handler(evt.Name, evt.Time);
				}
			}
			else
			{
				// Non-looping past end: fire remaining events up to Duration
				for (let evt in Events)
				{
					if (evt.Time > prevTime && evt.Time <= Duration)
						handler(evt.Name, evt.Time);
				}
			}
		}
	}

	/// Computes the duration from the latest keyframe time.
	public void ComputeDuration()
	{
		Duration = 0;
		for (let track in PositionTracks)
		{
			if (track.Keyframes.Count > 0)
				Duration = Math.Max(Duration, track.Keyframes[track.Keyframes.Count - 1].Time);
		}
		for (let track in RotationTracks)
		{
			if (track.Keyframes.Count > 0)
				Duration = Math.Max(Duration, track.Keyframes[track.Keyframes.Count - 1].Time);
		}
		for (let track in ScaleTracks)
		{
			if (track.Keyframes.Count > 0)
				Duration = Math.Max(Duration, track.Keyframes[track.Keyframes.Count - 1].Time);
		}
	}
}
