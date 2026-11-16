using System;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// Sampling tracks and clips, and blending the poses that come out.
class AnimationSamplerTests
{
	private static bool Near(Float3 a, Float3 b, float epsilon = 0.001f) =>
		(Abs(a.X - b.X) <= epsilon) && (Abs(a.Y - b.Y) <= epsilon) && (Abs(a.Z - b.Z) <= epsilon);

	[Test]
	public static void AVectorTrackInterpolatesAndClamps()
	{
		let track = scope AnimationTrack<Float3>();
		track.AddKeyframe(0.0f, .(0, 0, 0));
		track.AddKeyframe(1.0f, .(10, 0, 0));

		Test.Assert(Near(AnimationSampler.SampleVec3(track, 0.0f), .(0, 0, 0)));
		Test.Assert(Near(AnimationSampler.SampleVec3(track, 0.5f), .(5, 0, 0)));
		Test.Assert(Near(AnimationSampler.SampleVec3(track, 1.0f), .(10, 0, 0)));
		Test.Assert(Near(AnimationSampler.SampleVec3(track, 2.0f), .(10, 0, 0)), "clamped");

		// No track at all answers the default, which is what leaves a bone where it was.
		Test.Assert(Near(AnimationSampler.SampleVec3(null, 0.5f, .(9, 9, 9)), .(9, 9, 9)));
	}

	/// Step HOLDS the previous value until the next key, which is what a discrete switch
	/// between poses needs.
	[Test]
	public static void StepHoldsThePreviousValue()
	{
		let track = scope AnimationTrack<Float3>();
		track.Interpolation = .Step;
		track.AddKeyframe(0.0f, .(0, 0, 0));
		track.AddKeyframe(1.0f, .(10, 0, 0));

		Test.Assert(Near(AnimationSampler.SampleVec3(track, 0.5f), .(0, 0, 0)));
	}

	/// A bone the clip says nothing about keeps its BIND pose rather than collapsing to
	/// nothing.
	[Test]
	public static void SamplingAClipLeavesUnanimatedBonesAtTheirBindPose()
	{
		let skeleton = scope Skeleton(2);
		skeleton.Bones[0].LocalBindPose.Position = .(0, 0, 0);
		skeleton.Bones[1].LocalBindPose.Position = .(7, 7, 7);

		let clip = scope AnimationClip("move", 1.0f);
		let track = clip.GetOrCreatePositionTrack(0);
		track.AddKeyframe(0.0f, .(0, 0, 0));
		track.AddKeyframe(1.0f, .(0, 10, 0));

		let poses = scope BoneTransform[2];
		AnimationSampler.SampleClip(clip, skeleton, 0.5f, poses);

		Test.Assert(Near(poses[0].Position, .(0, 5, 0)), "animated");
		Test.Assert(Near(poses[1].Position, .(7, 7, 7)), "left at the bind pose");
	}

	/// A looping clip wraps with a POSITIVE modulo, so a time before the start reads from
	/// the end rather than sampling a negative one.
	[Test]
	public static void ALoopingClipWrapsInBothDirections()
	{
		let skeleton = scope Skeleton(1);
		let clip = scope AnimationClip("spin", 2.0f, true);
		let track = clip.GetOrCreatePositionTrack(0);
		track.AddKeyframe(0.0f, .(0, 0, 0));
		track.AddKeyframe(2.0f, .(20, 0, 0));

		let poses = scope BoneTransform[1];

		AnimationSampler.SampleClip(clip, skeleton, 2.5f, poses);
		Test.Assert(Near(poses[0].Position, .(5, 0, 0)), "half a second in");

		AnimationSampler.SampleClip(clip, skeleton, -0.5f, poses);
		Test.Assert(Near(poses[0].Position, .(15, 0, 0)), "half a second from the end");
	}

	[Test]
	public static void PosesBlendAndAdd()
	{
		let a = scope BoneTransform[1];
		a[0].Position = .(0, 0, 0);
		a[0].Scale = .(1, 1, 1);
		let b = scope BoneTransform[1];
		b[0].Position = .(10, 0, 0);
		b[0].Scale = .(3, 3, 3);
		let result = scope BoneTransform[1];

		AnimationSampler.BlendPoses(a, b, 0.5f, result);
		Test.Assert(Near(result[0].Position, .(5, 0, 0)));
		Test.Assert(Near(result[0].Scale, .(2, 2, 2)));

		let basePose = scope BoneTransform[1];
		basePose[0].Position = .(1, 0, 0);
		basePose[0].Scale = .(1, 1, 1);
		let additive = scope BoneTransform[1];
		additive[0].Position = .(0, 5, 0);
		additive[0].Scale = .(1, 1, 1);

		AnimationSampler.AdditivePoses(basePose, additive, 1.0f, result);
		Test.Assert(Near(result[0].Position, .(1, 5, 0)), "the base plus the additive");

		// Half the weight is half the addition, which is what fading an overlay in means.
		AnimationSampler.AdditivePoses(basePose, additive, 0.5f, result);
		Test.Assert(Near(result[0].Position, .(1, 2.5f, 0)));
	}

	/// A rotation's cubic ignored its tangents, easing in and out of every key whatever they
	/// said. Two keys of equal value with an out-tangent of one unit a second: the curve leaves
	/// the first key at that slope.
	[Test]
	public static void ACubicTrackFollowsItsTangentsARotationsIncluded()
	{
		let move = scope AnimationTrack<Float3>();
		move.Interpolation = .CubicSpline;
		move.AddKeyframe(0.0f, .(0, 0, 0), .(0, 0, 0), .(1, 0, 0));
		move.AddKeyframe(1.0f, .(0, 0, 0), .(0, 0, 0), .(0, 0, 0));
		let x = AnimationSampler.SampleVec3(move, 0.01f).X;
		Test.Assert(Abs(x - 0.01f) <= 0.0005f, scope $"x at 0.01 s: {x}");

		let turn = scope AnimationTrack<Quaternion>();
		turn.Interpolation = .CubicSpline;
		turn.AddKeyframe(0.0f, Quaternion.Identity, .(0, 0, 0, 0), .(0, 1, 0, 0));
		turn.AddKeyframe(1.0f, Quaternion.Identity, .(0, 0, 0, 0), .(0, 0, 0, 0));
		let early = AnimationSampler.SampleQuat(turn, 0.1f);
		Test.Assert(early.Y > 0.05f, scope $"turning about y, as the tangent says: {early.Y}");
		Test.Assert(Abs(early.Y * early.Y + early.W * early.W - 1.0f) <= 0.001f, "normalized");
	}
}
