using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// Detached ends, the asset pack shape (inverse-kinematics.md P4): a foot or a hand exported as
/// an IK target bone off the root, the shin or forearm with no child. The end moves itself and
/// the chain bends to meet it with the tip it had in the animated pose; a foot solve does the
/// same for each detached foot.
class DetachedIkTests
{
	// Root(0); Hips(1) at 1 under it; per side a Thigh under the hips and a Shin 0.45 below with no
	// child; the Foot an IK target bone under the ROOT, 0.1 up, where the shin's tip (0.45 below
	// it) meets it.
	const int32 Root = 0;
	const int32 Hips = 1;
	const int32 ThighL = 2;
	const int32 ShinL = 3;
	const int32 FootL = 4;
	const int32 ThighR = 5;
	const int32 ShinR = 6;
	const int32 FootR = 7;
	const int32 BoneCount = 8;

	private static void BuildDetached(Skeleton skeleton)
	{
		int32[BoneCount] parents = .(-1, Root, Hips, ThighL, Root, Hips, ThighR, Root);
		Float3[BoneCount] offsets = .(.(0, 0, 0), .(0, 1, 0), .(0.15f, 0, 0), .(0, -0.45f, 0.02f),
			.(0.15f, 0.1f, 0), .(-0.15f, 0, 0), .(0, -0.45f, 0.02f), .(-0.15f, 0.1f, 0));
		for (int32 i < BoneCount)
		{
			let bone = skeleton.Bones[i];
			bone.Index = i;
			bone.ParentIndex = parents[i];
			bone.LocalBindPose.Position = offsets[i];
		}
		skeleton.BuildNameMap();
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		skeleton.ComputeInverseBindPoses();
	}

	private static void BindPose(Skeleton skeleton, List<BoneTransform> outPose)
	{
		outPose.Clear();
		for (int32 i < skeleton.BoneCount)
			outPose.Add(skeleton.GetBone(i).LocalBindPose);
	}

	private static Float3 At(ModelPoseCache cache, int32 bone) => InverseKinematics.Position(cache.At(bone));

	private static bool Near(float a, float b, float relative = 1e-4f)
		=> Math.Abs(a - b) <= Math.Max(relative * Math.Max(Math.Abs(a), Math.Abs(b)), 1e-6f);

	[Test]
	public static void ADetachedFootMovesItselfAndTheLegBendsToMeetIt()
	{
		let skeleton = scope Skeleton(BoneCount);
		BuildDetached(skeleton);
		FootIkLeg[2] legs = .(.(.(ThighL, ShinL, FootL), .(0, 0, 0)), .(.(ThighR, ShinR, FootR), .(0, 0, 0)));
		let pose = scope List<BoneTransform>();
		let cache = scope ModelPoseCache();
		float[2] steps = .(0.2f, -0.2f);
		for (let step in steps)
		{
			BindPose(skeleton, pose);
			cache.Build(skeleton, pose);
			// Where each shin's tip meets its foot in the animated pose, in the shin's space.
			let tipL = TransformPoint(At(cache, FootL), Inverse(cache.At(ShinL)));
			let tipR = TransformPoint(At(cache, FootR), Inverse(cache.At(ShinR)));
			var state = FootIkState();
			let settings = FootIkSettings();
			FootGround[2] grounds = .(.(.(0.15f, step, 0), .(0, 1, 0)), .(.(-0.15f, 0, 0), .(0, 1, 0)));
			let r = InverseKinematics.SolveFootIk(skeleton, pose, cache, Hips, legs, grounds, settings, ref state, 0.0f);
			Test.Assert(r.Valid);
			Test.Assert(Near(At(cache, FootL).Y, 0.1f + step), "the foot on its ground");
			Test.Assert(Near(At(cache, FootR).Y, 0.1f));
			Test.Assert(Length(TransformPoint(tipL, cache.At(ShinL)) - At(cache, FootL)) < 1.0e-3f, "the leg meets it");
			Test.Assert(Length(TransformPoint(tipR, cache.At(ShinR)) - At(cache, FootR)) < 1.0e-3f);
			Test.Assert(Near(r.PelvisOffset, Math.Min(step, 0.0f)));
			for (let t in pose)
				Test.Assert(!t.Rotation.X.IsNaN && !t.Position.Y.IsNaN);
		}
	}

	[Test]
	public static void ADetachedEndMovesToTheTargetAndTheChainMeetsIt()
	{
		let skeleton = scope Skeleton(BoneCount);
		BuildDetached(skeleton);
		let pose = scope List<BoneTransform>();
		BindPose(skeleton, pose);
		let cache = scope ModelPoseCache();
		cache.Build(skeleton, pose);
		let tip = TransformPoint(At(cache, FootL), Inverse(cache.At(ShinL)));
		var settings = TwoBoneIkSettings();
		settings.Target = .(0.3f, 0.35f, 0.25f);
		settings.MatchRotation = true;
		settings.TargetRotation = Quaternion.FromAxisAngle(.(1, 0, 0), 0.4f);
		let chain = TwoBoneIkChain(ThighL, ShinL, FootL);
		let r = InverseKinematics.SolveTwoBone(skeleton, pose, cache, chain, settings);
		Test.Assert(r.Valid);
		Test.Assert(r.Reached);
		Test.Assert(Length(At(cache, FootL) - settings.Target) < 1.0e-4f);
		Test.Assert(Length(TransformPoint(tip, cache.At(ShinL)) - settings.Target) < 1.0e-3f, "the leg meets it");
		Test.Assert(Math.Abs(Dot(InverseKinematics.RotationOf(cache.At(FootL)), settings.TargetRotation)) > 1.0f - 1.0e-5f);

		// Half weight: the foot goes half way and the leg still meets it.
		let half = scope List<BoneTransform>();
		BindPose(skeleton, half);
		let halfCache = scope ModelPoseCache();
		halfCache.Build(skeleton, half);
		let from = At(halfCache, FootL);
		settings.Weight = 0.5f;
		InverseKinematics.SolveTwoBone(skeleton, half, halfCache, chain, settings);
		Test.Assert(Length(At(halfCache, FootL) - (from + (settings.Target - from) * 0.5f)) < 1.0e-4f);
		Test.Assert(Length(TransformPoint(tip, halfCache.At(ShinL)) - At(halfCache, FootL)) < 1.0e-3f);

		// An end the start carries but the mid does not, or the mid itself, has no meeting point.
		settings.Weight = 1.0f;
		Test.Assert(!InverseKinematics.SolveTwoBone(skeleton, pose, cache, .(Hips, ThighL, ThighR), settings).Valid);
		Test.Assert(!InverseKinematics.SolveTwoBone(skeleton, pose, cache, .(ThighL, ShinL, ShinL), settings).Valid);
		Test.Assert(!InverseKinematics.SolveTwoBone(skeleton, pose, cache, .(ThighL, ShinL, -1), settings).Valid);
	}
}
