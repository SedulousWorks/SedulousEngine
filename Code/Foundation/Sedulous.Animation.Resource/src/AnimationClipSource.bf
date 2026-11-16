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
///
/// A track whose bone is minus one is a MODEL track: the armature node's own channels, kept by the
/// importer for root motion; the pose never plays it. Appended last: the root
/// motion settings authored on the clip and the curve the cook baked, each its own key, so a text
/// clip from before them reads with root motion off. Cooked clips are positional and re-cook: the
/// clip builder's version moved.
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

	// Root motion: the root (a bone name; empty is the armature's own channels when the clip has
	// them, else the skeleton's first root) and which parts of its travel, every part OFF.
	[Appended]
	public String RootBone = new .() ~ delete _;
	/// The ground plane translation.
	[Appended]
	public bool RootHorizontal = false;
	/// Height: a climb; off for a walk, which keeps its bob.
	[Appended]
	public bool RootVertical = false;
	/// The turn about up, never pitch or roll.
	[Appended]
	public bool RootYaw = false;
	/// Baked at cook; empty unless root motion is on.
	[Appended]
	public List<float> RootTimes = new .() ~ delete _;
	[Appended]
	public List<Float3> RootPositions = new .() ~ delete _;
	[Appended]
	public List<float> RootYaws = new .() ~ delete _;
	/// A cubic spline's tangents (per second), parallel to KeyValue; empty when the clip has no
	/// cubic track.
	[Appended]
	public List<Float4> KeyInTangent = new .() ~ delete _;
	[Appended]
	public List<Float4> KeyOutTangent = new .() ~ delete _;

	public bool RootMotionAny => RootHorizontal || RootVertical || RootYaw;

	/// Whether the clip carries tangents for every key (it does when a track is cubic).
	public bool HasTangents => !KeyValue.IsEmpty && (KeyInTangent.Count == KeyValue.Count)
		&& (KeyOutTangent.Count == KeyValue.Count);

	/// Key `key`'s in or out tangent, zero for a clip without them.
	public Float4 TangentAt(List<Float4> from, int key) => HasTangents ? from[key] : .Zero;

	/// Every field of `other`: a cook's working copy, which the builder bakes and strips while the
	/// authored asset stays as it was.
	public void CopyFrom(AnimationClipSource other)
	{
		Name.Set(other.Name);
		Duration = other.Duration;
		IsLooping = other.IsLooping;
		TrackBone.Set(other.TrackBone);
		TrackKindValue.Set(other.TrackKindValue);
		TrackInterp.Set(other.TrackInterp);
		TrackStart.Set(other.TrackStart);
		TrackCount.Set(other.TrackCount);
		KeyTime.Set(other.KeyTime);
		KeyValue.Set(other.KeyValue);
		EventTime.Set(other.EventTime);
		ClearAndDeleteItems!(EventName);
		for (let name in other.EventName)
			EventName.Add(new String(name));
		RootBone.Set(other.RootBone);
		RootHorizontal = other.RootHorizontal;
		RootVertical = other.RootVertical;
		RootYaw = other.RootYaw;
		RootTimes.Set(other.RootTimes);
		RootPositions.Set(other.RootPositions);
		RootYaws.Set(other.RootYaws);
		KeyInTangent.Set(other.KeyInTangent);
		KeyOutTangent.Set(other.KeyOutTangent);
	}

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
		outSource.KeyInTangent.Clear();
		outSource.KeyOutTangent.Clear();

		bool cubic = false;
		for (let track in clip.PositionTracks)
			cubic |= track.Interpolation == .CubicSpline;
		for (let track in clip.RotationTracks)
			cubic |= track.Interpolation == .CubicSpline;
		for (let track in clip.ScaleTracks)
			cubic |= track.Interpolation == .CubicSpline;

		for (let track in clip.PositionTracks)
			AppendVec3Track(outSource, track, .Position);
		for (let track in clip.RotationTracks)
			AppendQuatTrack(outSource, track);
		for (let track in clip.ScaleTracks)
			AppendVec3Track(outSource, track, .Scale);
		if (!cubic)
		{
			// No cubic track: the tangents carry nothing.
			outSource.KeyInTangent.Clear();
			outSource.KeyOutTangent.Clear();
		}

		outSource.EventTime.Clear();
		ClearAndDeleteItems!(outSource.EventName);
		for (let event in clip.Events)
		{
			outSource.EventTime.Add(event.Time);
			outSource.EventName.Add(new String(event.Name));
		}

		let curve = clip.RootMotion;
		outSource.RootHorizontal = curve.Horizontal;
		outSource.RootVertical = curve.Vertical;
		outSource.RootYaw = curve.Yaw;
		outSource.RootTimes.Set(curve.Times);
		outSource.RootPositions.Set(curve.Positions);
		outSource.RootYaws.Set(curve.Yaws);
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
			// A model track: root motion's, baked into the curve, never the pose's.
			if (TrackBone[i] < 0)
				continue;
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
					let tin = TangentAt(KeyInTangent, j);
					let tout = TangentAt(KeyOutTangent, j);
					track.AddKeyframe(KeyTime[j], .(value.X, value.Y, value.Z, value.W),
						.(tin.X, tin.Y, tin.Z, tin.W), .(tout.X, tout.Y, tout.Z, tout.W));
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
					let tin = TangentAt(KeyInTangent, j);
					let tout = TangentAt(KeyOutTangent, j);
					track.AddKeyframe(KeyTime[j], .(value.X, value.Y, value.Z), .(tin.X, tin.Y, tin.Z),
						.(tout.X, tout.Y, tout.Z));
				}
			}
		}

		for (int i = 0; i < EventTime.Count; i++)
			clip.AddEvent(EventTime[i], (i < EventName.Count) ? EventName[i] : "");

		let roots = Math.Min(RootTimes.Count, Math.Min(RootPositions.Count, RootYaws.Count));
		for (int i < roots)
		{
			clip.RootMotion.Times.Add(RootTimes[i]);
			clip.RootMotion.Positions.Add(RootPositions[i]);
			clip.RootMotion.Yaws.Add(RootYaws[i]);
		}
		clip.RootMotion.Horizontal = (roots > 0) && RootHorizontal;
		clip.RootMotion.Vertical = (roots > 0) && RootVertical;
		clip.RootMotion.Yaw = (roots > 0) && RootYaw;

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
			outSource.KeyInTangent.Add(.(key.InTangent.X, key.InTangent.Y, key.InTangent.Z, 0.0f));
			outSource.KeyOutTangent.Add(.(key.OutTangent.X, key.OutTangent.Y, key.OutTangent.Z, 0.0f));
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
			outSource.KeyInTangent.Add(.(key.InTangent.X, key.InTangent.Y, key.InTangent.Z, key.InTangent.W));
			outSource.KeyOutTangent.Add(.(key.OutTangent.X, key.OutTangent.Y, key.OutTangent.Z, key.OutTangent.W));
		}
	}
}
