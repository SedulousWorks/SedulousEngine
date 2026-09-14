using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Animation.Resource;

/// The cooked WIRE for a clip: per track metadata indexing ONE dense keyframe pool.
///
/// Every value is a Float4, whatever the track drives: a position or a scale uses three of
/// it and a rotation all four. One pool rather than two keeps the indexing single, and the
/// wasted float is cheaper than a second set of parallel arrays to keep in step.
[Serializable]
class AnimationClipSource
{
	public String Name = new .() ~ delete _;
	public float Duration = 0.0f;
	public bool IsLooping = false;

	// Per track.
	public List<int32> TrackBone = new .() ~ delete _;
	public List<uint8> TrackKindValue = new .() ~ delete _;
	public List<uint8> TrackInterp = new .() ~ delete _;
	public List<uint32> TrackStart = new .() ~ delete _;
	public List<uint32> TrackCount = new .() ~ delete _;

	// The shared keyframe pool.
	public List<float> KeyTime = new .() ~ delete _;
	public List<Float4> KeyValue = new .() ~ delete _;

	// The events.
	public List<float> EventTime = new .() ~ delete _;
	public List<String> EventName = new .() ~ DeleteContainerAndItems!(_);

	public static void FromClip(AnimationClip clip, AnimationClipSource outSource)
	{
		outSource.Name.Set(clip.Name);
		outSource.Duration = clip.Duration;
		outSource.IsLooping = clip.IsLooping;

		outSource.TrackBone.Clear();
		outSource.TrackKindValue.Clear();
		outSource.TrackInterp.Clear();
		outSource.TrackStart.Clear();
		outSource.TrackCount.Clear();
		outSource.KeyTime.Clear();
		outSource.KeyValue.Clear();

		for (let track in clip.PositionTracks)
			AppendVec3Track(outSource, track, .Position);
		for (let track in clip.RotationTracks)
			AppendQuatTrack(outSource, track);
		for (let track in clip.ScaleTracks)
			AppendVec3Track(outSource, track, .Scale);

		outSource.EventTime.Clear();
		ClearAndDeleteItems!(outSource.EventName);
		for (let event in clip.Events)
		{
			outSource.EventTime.Add(event.Time);
			outSource.EventName.Add(new String(event.Name));
		}
	}

	/// Rebuilds a clip IN PLACE, answering false when the record is malformed and leaving
	/// the clip EMPTY.
	///
	/// FAIL CLOSED rather than salvage what parses. A clip quietly missing keyframes still
	/// animates, wrongly: a limb stops halfway through a swing, and tracing that back to a
	/// bad cook is far harder than reading a resource that refused to bind. Cooked bytes
	/// reach the runtime by paths no cook ever saw, so the check is here rather than there.
	public bool FillClip(AnimationClip clip)
	{
		clip.ClearForReload();

		let trackTotal = TrackBone.Count;
		if ((TrackStart.Count < trackTotal) || (TrackCount.Count < trackTotal))
			return false;

		let pool = Min(KeyTime.Count, KeyValue.Count);
		for (int i = 0; i < trackTotal; i++)
		{
			let start = (int)TrackStart[i];
			let count = (int)TrackCount[i];
			// Subtracted FROM the pool rather than added to the start, so a huge count
			// cannot wrap the sum back into range.
			if ((start > pool) || (count > pool - start))
				return false;
		}

		clip.Name.Set(Name);
		clip.Duration = Duration;
		clip.IsLooping = IsLooping;

		for (int i = 0; i < trackTotal; i++)
		{
			uint8 kindValue = (i < TrackKindValue.Count) ? TrackKindValue[i] : 0;
			let kind = (TrackKind)kindValue;
			// One is Linear, which is the sane default for a record that lost its modes.
			uint8 interpValue = (i < TrackInterp.Count) ? TrackInterp[i] : 1;
			let interp = (InterpolationMode)interpValue;

			let from = (int)TrackStart[i];
			let to = from + (int)TrackCount[i];

			if (kind == .Rotation)
			{
				let track = clip.GetOrCreateRotationTrack(TrackBone[i]);
				track.Interpolation = interp;
				for (int j = from; j < to; j++)
				{
					let value = KeyValue[j];
					track.AddKeyframe(KeyTime[j], .(value.X, value.Y, value.Z, value.W));
				}
			}
			else
			{
				let track = (kind == .Scale)
					? clip.GetOrCreateScaleTrack(TrackBone[i])
					: clip.GetOrCreatePositionTrack(TrackBone[i]);
				track.Interpolation = interp;
				for (int j = from; j < to; j++)
				{
					let value = KeyValue[j];
					track.AddKeyframe(KeyTime[j], .(value.X, value.Y, value.Z));
				}
			}
		}

		for (int i = 0; i < EventTime.Count; i++)
			clip.AddEvent(EventTime[i], (i < EventName.Count) ? EventName[i] : "");

		return true;
	}

	private static void AppendVec3Track(AnimationClipSource outSource,
		AnimationTrack<Float3> track, TrackKind kind)
	{
		outSource.TrackBone.Add(track.BoneIndex);
		outSource.TrackKindValue.Add((uint8)kind);
		outSource.TrackInterp.Add((uint8)track.Interpolation);
		outSource.TrackStart.Add((uint32)outSource.KeyTime.Count);
		outSource.TrackCount.Add((uint32)track.Keyframes.Count);

		for (let key in track.Keyframes)
		{
			outSource.KeyTime.Add(key.Time);
			outSource.KeyValue.Add(.(key.Value.X, key.Value.Y, key.Value.Z, 0.0f));
		}
	}

	private static void AppendQuatTrack(AnimationClipSource outSource,
		AnimationTrack<Quaternion> track)
	{
		outSource.TrackBone.Add(track.BoneIndex);
		outSource.TrackKindValue.Add((uint8)TrackKind.Rotation);
		outSource.TrackInterp.Add((uint8)track.Interpolation);
		outSource.TrackStart.Add((uint32)outSource.KeyTime.Count);
		outSource.TrackCount.Add((uint32)track.Keyframes.Count);

		for (let key in track.Keyframes)
		{
			outSource.KeyTime.Add(key.Time);
			outSource.KeyValue.Add(.(key.Value.X, key.Value.Y, key.Value.Z, key.Value.W));
		}
	}
}
