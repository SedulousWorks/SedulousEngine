using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Sedulous.Animation.Resource.Tests;

/// The root motion cook (root-motion.md P0): a root's travel bakes into the clip's curve (at its
/// keys and a fixed rate) and leaves the pose in place, keeping what was not extracted; yaw is
/// unwrapped; the armature's own channels (model tracks, bone minus one) bake through the
/// armature's rest and never reach the pose; a text clip from before root motion reads with it
/// off.
class RootMotionTests
{
	private static bool Near(float a, float b, float epsilon = 1e-4f) => Math.Abs(a - b) <= epsilon;

	private static void AddTrack(AnimationClipSource clip, int32 bone, TrackKind kind, Span<float> times, Span<Float4> values,
		InterpolationMode interp = .Linear)
	{
		clip.TrackBone.Add(bone);
		clip.TrackKindValue.Add((uint8)kind);
		clip.TrackInterp.Add((uint8)interp);
		clip.TrackStart.Add((uint32)clip.KeyTime.Count);
		clip.TrackCount.Add((uint32)times.Length);
		for (int i < times.Length)
		{
			clip.KeyTime.Add(times[i]);
			clip.KeyValue.Add(values[i]);
		}
	}

	/// A one second clip: the hips (bone 0) walk 2 m forward with a bob, and a spine (bone 1)
	/// sways. Not looping, so it is sampled at its end rather than wrapped to its start.
	private static void Walk(AnimationClipSource clip)
	{
		clip.Name.Set("Walk");
		clip.Duration = 1.0f;
		clip.IsLooping = false;
		float[5] t = .(0.0f, 0.25f, 0.5f, 0.75f, 1.0f);
		Float4[5] hips = .(.(0, 1.0f, 0, 0), .(0, 1.1f, 0.5f, 0), .(0, 1.0f, 1.0f, 0), .(0, 1.1f, 1.5f, 0), .(0, 1.0f, 2.0f, 0));
		AddTrack(clip, 0, .Position, t, hips);
		float[2] s = .(0.0f, 1.0f);
		Float4[2] sway = .(.(0, 0, 0, 1), .(0, 0.0998f, 0, 0.995f));
		AddTrack(clip, 1, .Rotation, s, sway);
	}

	private static BoneTransform Pose(AnimationClipSource clip, int32 bone, float time)
	{
		let runtime = scope AnimationClip();
		Test.Assert(clip.FillClip(runtime));
		let skeleton = scope Skeleton(3);
		BoneTransform[3] poses = default;
		AnimationSampler.SampleClip(runtime, skeleton, time, poses);
		return poses[bone];
	}

	[Test]
	public static void ARootThatWalksTwoMetresBakesATwoMetreCurveAndThePosePlaysInPlace()
	{
		let clip = scope AnimationClipSource();
		Walk(clip);
		clip.RootHorizontal = true;
		Test.Assert(RootMotionBake.Bake(clip, 0));
		Test.Assert(!clip.RootTimes.IsEmpty);
		Test.Assert(clip.RootTimes.Count == clip.RootPositions.Count);
		Test.Assert(clip.RootTimes[0] == 0.0f);
		Test.Assert(Near(clip.RootTimes.Back, 1.0f));
		Test.Assert(Near(clip.RootPositions.Back.Z - clip.RootPositions[0].Z, 2.0f));
		Test.Assert(clip.RootTimes.Count >= 31, "the 30 Hz bake, not only the five keys");

		float[4] times = .(0.0f, 0.3f, 0.5f, 0.9f);
		for (let t in times)
			Test.Assert(Near(Pose(clip, 0, t).Position.Z, 0.0f), "in place");
		// Vertical off: the bob is the pose's still.
		Test.Assert(Near(Pose(clip, 0, 0.25f).Position.Y, 1.1f));
		Test.Assert(Near(Pose(clip, 0, 0.5f).Position.Y, 1.0f));
		// Another bone is untouched.
		Test.Assert(Near(Pose(clip, 1, 1.0f).Rotation.Y, 0.0998f));

		// The runtime clip carries the curve and what it extracted.
		let runtime = scope AnimationClip();
		Test.Assert(clip.FillClip(runtime));
		Test.Assert(runtime.RootMotion.Horizontal);
		Test.Assert(!runtime.RootMotion.Vertical);
		Test.Assert(runtime.RootMotion.Times.Count == clip.RootTimes.Count);

		// Vertical on: the height is the curve's as well, held at frame 0's in the pose.
		let climb = scope AnimationClipSource();
		Walk(climb);
		climb.RootVertical = true;
		Test.Assert(RootMotionBake.Bake(climb, 0));
		Test.Assert(Near(Pose(climb, 0, 0.25f).Position.Y, 1.0f));
		Test.Assert(Near(Pose(climb, 0, 0.25f).Position.Z, 0.5f), "horizontal off: still travels");
	}

	[Test]
	public static void ATurnBakesAsYawPastHalfACircleAndIsStrippedFromThePose()
	{
		let clip = scope AnimationClipSource();
		clip.Duration = 2.0f;
		float[3] t = .(0.0f, 1.0f, 2.0f);
		let a = Quaternion.FromAxisAngle(.(0, 1, 0), 0.0f);
		let b = Quaternion.FromAxisAngle(.(0, 1, 0), 2.0f);
		let c = Quaternion.FromAxisAngle(.(0, 1, 0), 4.0f); // past pi
		Float4[3] keys = .(.(a.X, a.Y, a.Z, a.W), .(b.X, b.Y, b.Z, b.W), .(c.X, c.Y, c.Z, c.W));
		AddTrack(clip, 0, .Rotation, t, keys);
		clip.RootYaw = true;
		Test.Assert(RootMotionBake.Bake(clip, 0));
		Test.Assert(Near(clip.RootYaws.Back, 4.0f, 4e-3f), "unwrapped");
		float[3] ats = .(0.5f, 1.0f, 2.0f);
		for (let at in ats)
		{
			let forward = RotateVector(Pose(clip, 0, at).Rotation, .(0, 0, 1));
			Test.Assert(Near(forward.Z, 1.0f), "faces where frame 0 did");
		}
	}

	[Test]
	public static void AStepRootKeepsItsShapeThroughTheFixedBakeRate()
	{
		let clip = scope AnimationClipSource();
		clip.Duration = 1.0f;
		float[2] t = .(0.0f, 0.5f);
		Float4[2] hop = .(.(0, 0, 0, 0), .(0, 0, 1, 0));
		AddTrack(clip, 0, .Position, t, hop, .Step);
		clip.RootHorizontal = true;
		Test.Assert(RootMotionBake.Bake(clip, 0));
		// Just before the step the curve still stands at 0; at and after it, at 1.
		for (int i < clip.RootTimes.Count)
			Test.Assert(Near(clip.RootPositions[i].Z, (clip.RootTimes[i] < 0.5f) ? 0.0f : 1.0f));
	}

	/// The armature moves 3 m along its parent's +X; at rest it is turned a quarter about +Y, so
	/// in model space (the armature at rest) that travel is +X turned by the rest's inverse.
	[Test]
	public static void TheArmaturesOwnChannelsBakeThroughItsRestAndNeverReachThePose()
	{
		let clip = scope AnimationClipSource();
		Walk(clip);
		float[2] t = .(0.0f, 1.0f);
		Float4[2] moved = .(.(0, 0, 0, 0), .(3, 0, 0, 0));
		AddTrack(clip, -1, .Position, t, moved);
		let turn = Quaternion.FromAxisAngle(.(0, 1, 0), HalfPi);
		Float4[2] still = .(.(turn.X, turn.Y, turn.Z, turn.W), .(turn.X, turn.Y, turn.Z, turn.W));
		AddTrack(clip, -1, .Rotation, t, still);
		clip.RootHorizontal = true;
		let rest = Transform(.(0, 0, 0), turn, .(1, 1, 1));
		Test.Assert(RootMotionBake.Bake(clip, -1, rest));
		let travel = clip.RootPositions.Back - clip.RootPositions[0];
		Test.Assert(Near(Length(travel), 3.0f));
		Test.Assert(Length(travel - RotateVector(Inverse(turn), .(3, 0, 0))) < 1.0e-3f);
		Test.Assert(Near(clip.RootYaws.Back, 0.0f), "at rest: no turn");
		// The bone tracks were not touched (the hips still walk), and the model tracks reach no bone.
		Test.Assert(Near(Pose(clip, 0, 1.0f).Position.Z, 2.0f));
		let runtime = scope AnimationClip();
		Test.Assert(clip.FillClip(runtime));
		for (let track in runtime.PositionTracks)
			Test.Assert(track.BoneIndex >= 0);
	}

	[Test]
	public static void OffLeavesTheClipAsItWasAndARootWithNoTrackSaysSo()
	{
		let clip = scope AnimationClipSource();
		Walk(clip);
		Test.Assert(RootMotionBake.Bake(clip, 0));
		Test.Assert(clip.RootTimes.IsEmpty);
		Test.Assert(Near(Pose(clip, 0, 1.0f).Position.Z, 2.0f));
		clip.RootHorizontal = true;
		Test.Assert(!RootMotionBake.Bake(clip, 2), "bone 2 has no track");
		Test.Assert(clip.RootTimes.IsEmpty);
	}

	[Test]
	public static void ATextClipFromBeforeRootMotionReadsWithItOff()
	{
		let walk = scope AnimationClipSource();
		Walk(walk);
		walk.RootHorizontal = true;
		Test.Assert(RootMotionBake.Bake(walk, 0));
		let text = scope String();
		{
			let writer = scope XmlSerializer();
			((ISerializable)walk).Serialize(writer);
			writer.GetOutput(text);
		}
		// The same record as a build before root motion wrote it: no settings, no curve.
		let cut = text.IndexOf("<string name=\"rootBone\"");
		Test.Assert(cut > 0, text);
		// The record is one object in the document's root: close both after the cut.
		let old = scope String(text, 0, cut);
		old.Append("</object></root>");
		let document = scope XmlDocument();
		Test.Assert(document.Parse(old) == .Ok, old);
		let reader = scope XmlSerializer(document);
		let loaded = scope AnimationClipSource();
		((ISerializable)loaded).Serialize(reader);
		Test.Assert(reader.IsOk);
		Test.Assert(!loaded.RootMotionAny);
		Test.Assert(loaded.RootTimes.IsEmpty);
		Test.Assert(loaded.TrackBone.Count == 2, "the rest still reads");

		// And the current record reads its settings and curve back.
		let current = scope XmlDocument();
		Test.Assert(current.Parse(text) == .Ok);
		let again = scope XmlSerializer(current);
		let round = scope AnimationClipSource();
		((ISerializable)round).Serialize(again);
		Test.Assert(again.IsOk);
		Test.Assert(round.RootHorizontal);
		Test.Assert(round.RootTimes.Count == walk.RootTimes.Count);
	}
}
