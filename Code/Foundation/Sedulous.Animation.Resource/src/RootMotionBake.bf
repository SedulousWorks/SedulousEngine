using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Resource;

/// The root motion cook (root-motion.md P0): bakes a clip's root travel into its curve and, for
/// a root BONE, strips what was extracted from its own tracks so the pose plays in place.
static class RootMotionBake
{
	/// The rate the curve is baked at beside the root's own keys: a cubic or step track keeps its
	/// shape between sparse keys, the runtime reading the curve linearly.
	public const float BakeRate = 30.0f;

	/// The turn of `q` about +Y: where its forward (+Z) points, seen from above.
	public static float YawOf(Quaternion q)
	{
		let forward = RotateVector(q, .(0, 0, 1));
		return Atan2(forward.X, forward.Z);
	}

	/// The clip's track of `kind` for `bone` (minus one: a model track), or minus one.
	public static int FindTrack(AnimationClipSource clip, int32 bone, TrackKind kind)
	{
		for (int i = 0; (i < clip.TrackBone.Count) && (i < clip.TrackKindValue.Count); i++)
		{
			if ((clip.TrackBone[i] == bone) && (clip.TrackKindValue[i] == (uint8)kind))
				return i;
		}
		return -1;
	}

	/// One track of the record as a runtime track, sampled exactly as the pose samples it.
	private static void ReadTrack(AnimationClipSource clip, int track, AnimationTrack<Float3> outTrack)
	{
		if (track < 0)
			return;
		outTrack.Interpolation = (InterpolationMode)((track < clip.TrackInterp.Count) ? clip.TrackInterp[track] : 1);
		let start = (int)clip.TrackStart[track];
		for (int k = 0; (k < (int)clip.TrackCount[track]) && (start + k < clip.KeyTime.Count); k++)
		{
			let v = clip.KeyValue[start + k];
			outTrack.AddKeyframe(clip.KeyTime[start + k], .(v.X, v.Y, v.Z));
		}
	}

	private static void ReadTrack(AnimationClipSource clip, int track, AnimationTrack<Quaternion> outTrack)
	{
		if (track < 0)
			return;
		outTrack.Interpolation = (InterpolationMode)((track < clip.TrackInterp.Count) ? clip.TrackInterp[track] : 1);
		let start = (int)clip.TrackStart[track];
		for (int k = 0; (k < (int)clip.TrackCount[track]) && (start + k < clip.KeyTime.Count); k++)
		{
			let v = clip.KeyValue[start + k];
			outTrack.AddKeyframe(clip.KeyTime[start + k], .(v.X, v.Y, v.Z, v.W));
		}
	}

	/// Bakes and strips. `root` is a bone index in the clip's tracks, or minus one for the
	/// armature's own channels (model tracks: turned into model space by the inverse of the
	/// armature's rest transform `modelRest`, and never stripped, as the pose never plays them). The
	/// curve is the root's transform in its parent's space, which is model space for a skeleton
	/// root and for a model track; for a root under a parent it is model space only while its
	/// ancestors neither move nor turn, positions and yaw alike. Up is +Y; pitch and roll are never
	/// extracted, and the yaw is unwrapped, so a turn past half a circle keeps counting. False, and
	/// nothing changed, when the root has no track.
	public static bool Bake(AnimationClipSource clip, int32 root, Transform modelRest = .())
	{
		clip.RootTimes.Clear();
		clip.RootPositions.Clear();
		clip.RootYaws.Clear();
		if (!clip.RootMotionAny)
			return true;
		let positionTrack = FindTrack(clip, root, .Position);
		let rotationTrack = FindTrack(clip, root, .Rotation);
		if ((positionTrack < 0) && (rotationTrack < 0))
			return false;
		let position = scope AnimationTrack<Float3>();
		let rotation = scope AnimationTrack<Quaternion>();
		ReadTrack(clip, positionTrack, position);
		ReadTrack(clip, rotationTrack, rotation);

		// The times: the root's keys and a fixed rate across the clip, in order, once each.
		let times = scope List<float>();
		let duration = Math.Max(clip.Duration, 0.0f);
		let steps = (int)Ceil(duration * BakeRate);
		for (int i = 0; i <= steps; i++)
			times.Add(Math.Min(duration, (float)i / BakeRate));
		for (let k in position.Keyframes)
			times.Add(Math.Clamp(k.Time, 0.0f, duration));
		for (let k in rotation.Keyframes)
			times.Add(Math.Clamp(k.Time, 0.0f, duration));
		times.Sort();
		let fromRest = Inverse(modelRest.ToMatrix());
		var previousYaw = 0.0f;
		for (int i < times.Count)
		{
			if ((i > 0) && (times[i] - times[i - 1] < 1.0e-5f))
				continue;
			var p = AnimationSampler.SampleVec3(position, times[i], .(0, 0, 0));
			var q = AnimationSampler.SampleQuat(rotation, times[i], .Identity);
			if (root < 0)
			{
				// The armature moved within its parent; model space is the armature at rest.
				let moved = BoneTransform(p, q, .(1, 1, 1));
				Decompose(moved.ToMatrix() * fromRest, out p, out q, ?);
			}
			var yaw = YawOf(q);
			if (!clip.RootTimes.IsEmpty)
			{
				while (yaw - previousYaw > Pi)
					yaw -= TwoPi;
				while (yaw - previousYaw < -Pi)
					yaw += TwoPi;
			}
			previousYaw = yaw;
			clip.RootTimes.Add(times[i]);
			clip.RootPositions.Add(p);
			clip.RootYaws.Add(yaw);
		}

		if (root >= 0)
		{
			// Strip from the bone's own keys what was extracted, relative to frame 0.
			let first = clip.RootPositions[0];
			let firstYaw = clip.RootYaws[0];
			if ((positionTrack >= 0) && (clip.RootHorizontal || clip.RootVertical))
			{
				let start = (int)clip.TrackStart[positionTrack];
				for (int k < (int)clip.TrackCount[positionTrack])
				{
					var v = ref clip.KeyValue[start + k];
					if (clip.RootHorizontal)
					{
						v.X = first.X;
						v.Z = first.Z;
					}
					if (clip.RootVertical)
						v.Y = first.Y;
				}
			}
			if ((rotationTrack >= 0) && clip.RootYaw)
			{
				let start = (int)clip.TrackStart[rotationTrack];
				for (int k < (int)clip.TrackCount[rotationTrack])
				{
					var v = ref clip.KeyValue[start + k];
					let q = Quaternion(v.X, v.Y, v.Z, v.W);
					let back = Quaternion.FromAxisAngle(.(0, 1, 0), -(YawOf(q) - firstYaw));
					let kept = Normalized(back * q);
					v = .(kept.X, kept.Y, kept.Z, kept.W);
				}
			}
		}
		return true;
	}
}
