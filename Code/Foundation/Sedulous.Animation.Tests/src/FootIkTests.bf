using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// Feet that stand on the ground under them (inverse-kinematics.md P3), on grounds given rather
/// than probed: flat ground leaves the pose, a step up raises a foot, a step down lowers the
/// pelvis (clamped), a lifted foot is the animation's, a foot turns to its slope up to MaxTilt,
/// and the corrections ease at their rates while a zero step holds them.
class FootIkTests
{
	// A biped's hips and legs, its origin at its feet: Hips(0) at 1; per side a Thigh at the hip,
	// a Shin 0.45 below (the knee bound a little forward) and a Foot 0.45 below that, the ankle
	// 0.1 above the ground.
	const int32 Hips = 0;
	const int32 ThighL = 1;
	const int32 ShinL = 2;
	const int32 FootL = 3;
	const int32 ThighR = 4;
	const int32 ShinR = 5;
	const int32 FootR = 6;
	const int32 BipedBones = 7;

	private static void BuildBiped(Skeleton skeleton)
	{
		int32[BipedBones] parents = .(-1, Hips, ThighL, ShinL, Hips, ThighR, ShinR);
		Float3[BipedBones] offsets = .(.(0, 1, 0), .(0.15f, 0, 0), .(0, -0.45f, 0.02f), .(0, -0.45f, -0.02f),
			.(-0.15f, 0, 0), .(0, -0.45f, 0.02f), .(0, -0.45f, -0.02f));
		for (int32 i < BipedBones)
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

	private static FootIkLeg[2] Legs => .(.(.(ThighL, ShinL, FootL), .(0, 0, 0)), .(.(ThighR, ShinR, FootR), .(0, 0, 0)));

	private static FootGround Ground(float x, float height, Float3 normal = .(0, 1, 0))
		=> .(.(x, height, 0), Normalized(normal));

	private static Float3 At(ModelPoseCache cache, int32 bone) => InverseKinematics.Position(cache.At(bone));

	private static bool Near(float a, float b, float relative = 1e-4f)
		=> Math.Abs(a - b) <= Math.Max(relative * Math.Max(Math.Abs(a), Math.Abs(b)), 1e-6f);

	private class FootRun
	{
		public Skeleton Skeleton = new .(BipedBones) ~ delete _;
		public List<BoneTransform> Pose = new .() ~ delete _;
		public ModelPoseCache Cache = new .() ~ delete _;
		public FootIkState State = .();
		public FootIkSettings Settings = .();

		public this()
		{
			BuildBiped(Skeleton);
			Reset();
		}

		public void Reset()
		{
			Pose.Clear();
			for (int32 i < Skeleton.BoneCount)
				Pose.Add(Skeleton.GetBone(i).LocalBindPose);
			Cache.Build(Skeleton, Pose);
		}

		public FootIkResult Solve(FootGround left, FootGround right, float seconds = 0.0f)
		{
			Reset();
			FootGround[2] grounds = .(left, right);
			var legs = Legs;
			return InverseKinematics.SolveFootIk(Skeleton, Pose, Cache, Hips, legs, grounds, Settings, ref State, seconds);
		}
	}

	[Test]
	public static void FlatGroundAtTheAnimationsOwnLeavesThePoseAndAStepUpRaisesThatFoot()
	{
		let run = scope FootRun();
		let bound = scope ModelPoseCache();
		bound.Build(run.Skeleton, run.Pose);
		let flat = run.Solve(Ground(0.15f, 0.0f), Ground(-0.15f, 0.0f));
		Test.Assert(flat.Valid);
		Test.Assert(flat.PelvisOffset == 0.0f);
		for (int32 i < BipedBones)
			Test.Assert(Length(At(run.Cache, i) - At(bound, i)) < 1.0e-5f);

		let step = scope FootRun();
		let up = step.Solve(Ground(0.15f, 0.2f), Ground(-0.15f, 0.0f));
		Test.Assert(up.PelvisOffset == 0.0f, "nothing lower than the animation's ground");
		Test.Assert(Near(At(step.Cache, FootL).Y, 0.3f), "the ankle 0.1 above");
		Test.Assert(Near(At(step.Cache, FootR).Y, 0.1f));
		Test.Assert(up.FootError[0] < 1.0e-3f);
	}

	[Test]
	public static void AStepDownLowersThePelvisByTheDeepestCorrectionClamped()
	{
		let run = scope FootRun();
		let down = run.Solve(Ground(0.15f, -0.2f), Ground(-0.15f, 0.0f));
		Test.Assert(Near(down.PelvisOffset, -0.2f));
		Test.Assert(Near(At(run.Cache, Hips).Y, 0.8f));
		Test.Assert(Near(At(run.Cache, FootL).Y, -0.1f), "on the lower ground");
		Test.Assert(Near(At(run.Cache, FootR).Y, 0.1f), "the other knee bends");
		Test.Assert(down.FootError[0] < 1.0e-3f);
		Test.Assert(down.FootError[1] < 1.0e-3f);

		let deep = scope FootRun();
		deep.Settings.PelvisDropMax = 0.3f;
		let clamped = deep.Solve(Ground(0.15f, -0.6f), Ground(-0.15f, 0.0f));
		Test.Assert(Near(clamped.PelvisOffset, -0.3f));
		Test.Assert(Near(At(deep.Cache, Hips).Y, 0.7f));
		Test.Assert(clamped.FootError[0] > 0.0f, "the leg reaches as far as it can");
		for (let t in deep.Pose)
			Test.Assert(!t.Rotation.X.IsNaN && !t.Position.Y.IsNaN);
	}

	[Test]
	public static void ALiftedFootIsTheAnimationsAndNoGroundLeavesAFootAlone()
	{
		let run = scope FootRun();
		run.Reset();
		// The animation swings the left leg forward and up: its foot is well above LiftHeight.
		run.Pose[ThighL].Rotation = Quaternion.FromAxisAngle(.(1, 0, 0), -0.9f);
		run.Cache.Build(run.Skeleton, run.Pose);
		BoneTransform[BipedBones] swung = ?;
		for (int32 i < BipedBones)
			swung[i] = run.Pose[i];
		Test.Assert(At(run.Cache, FootL).Y > 2.0f * run.Settings.LiftHeight);
		FootGround[2] grounds = .(Ground(0.15f, 0.2f), Ground(-0.15f, 0.1f));
		var legs = Legs;
		let r = InverseKinematics.SolveFootIk(run.Skeleton, run.Pose, run.Cache, Hips, legs, grounds, run.Settings, ref run.State, 0.0f);
		Test.Assert(r.Valid);
		for (let bone in int32[3](ThighL, ShinL, FootL))
		{
			var now = run.Pose[bone];
			Test.Assert(Internal.MemCmp(&now, &swung[bone], sizeof(BoneTransform)) == 0);
		}
		Test.Assert(Near(At(run.Cache, FootR).Y, 0.2f), "the planted one still stands");

		let bare = scope FootRun();
		let none = bare.Solve(.(), .());
		Test.Assert(none.Valid);
		Test.Assert(Near(At(bare.Cache, FootL).Y, 0.1f));
	}

	[Test]
	public static void AFootTurnsToItsSlopeUpToMaxTilt()
	{
		let slope = 20.0f * DegToRad;
		let run = scope FootRun();
		run.Solve(Ground(0.15f, 0.0f, .(0, Math.Cos(slope), Math.Sin(slope))), Ground(-0.15f, 0.0f));
		let footUp = Normalized(RotateVector(InverseKinematics.RotationOf(run.Cache.At(FootL)), .(0, 1, 0)));
		Test.Assert(Dot(footUp, Float3(0, Math.Cos(slope), Math.Sin(slope))) > 1.0f - 1.0e-5f);

		let steep = 50.0f * DegToRad;
		let limited = scope FootRun();
		limited.Solve(Ground(0.15f, 0.0f, .(0, Math.Cos(steep), Math.Sin(steep))), Ground(-0.15f, 0.0f));
		let tilted = Normalized(RotateVector(InverseKinematics.RotationOf(limited.Cache.At(FootL)), .(0, 1, 0)));
		Test.Assert(Near(Acos(Math.Clamp(Dot(tilted, Float3(0, 1, 0)), -1.0f, 1.0f)), 30.0f * DegToRad, 1e-3f));
	}

	[Test]
	public static void CorrectionsEaseAtTheirRatesAndAZeroStepHoldsThem()
	{
		let run = scope FootRun();
		run.Solve(Ground(0.15f, 0.0f), Ground(-0.15f, 0.0f)); // primed on flat ground
		let dt = 1.0f / 60.0f;
		run.Solve(Ground(0.15f, 0.2f), Ground(-0.15f, 0.0f), dt);
		let risen = 0.2f * (1.0f - Exp(-run.Settings.RaiseRate * dt));
		Test.Assert(Near(run.State.Offset[0], risen));
		Test.Assert(Near(At(run.Cache, FootL).Y, 0.1f + risen));

		run.Solve(Ground(0.15f, 0.2f), Ground(-0.15f, 0.0f), 0.0f); // paused: held
		Test.Assert(Near(run.State.Offset[0], risen));

		run.Solve(Ground(0.15f, 0.0f), Ground(-0.15f, 0.0f), dt); // lowering is slower
		Test.Assert(Near(run.State.Offset[0], risen * Exp(-run.Settings.LowerRate * dt)));
	}
}
