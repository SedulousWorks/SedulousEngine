using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// The inverse kinematics solvers (inverse-kinematics.md P1, the tests the spec lists): a two bone
/// chain reaches a reachable target exactly from every side, keeps its bone lengths and bends in
/// the pole's plane; an unreachable target is clamped short of straight with no NaN; a straight
/// chain bends the same way every frame; weight 0 is byte for byte and 0.5 between; an aim reaches
/// within its limit, clamps beyond it and holds its up axis; bones above a chain never move; and a
/// solve never grows its cache once sized.
class InverseKinematicsTests
{
	// Pelvis(0) at y 10; a leg: Thigh(1) at the hip, Shin(2) 4 below, Foot(3) 3 below that (bent
	// forward by `kneeForward` in the bind pose), Toe(4) ahead of the foot; and a spine branch:
	// Spine(5), Neck(6), Head(7), looking down +z.
	const int32 Pelvis = 0;
	const int32 Thigh = 1;
	const int32 Shin = 2;
	const int32 Foot = 3;
	const int32 Toe = 4;
	const int32 Spine = 5;
	const int32 Neck = 6;
	const int32 Head = 7;
	const int32 BoneCount = 8;
	const float Reach = 7.0f;

	private static TwoBoneIkChain Leg => .(Thigh, Shin, Foot);

	private static void BuildBody(Skeleton skeleton, float kneeForward = 0.0f)
	{
		int32[BoneCount] parents = .(-1, Pelvis, Thigh, Shin, Foot, Pelvis, Spine, Neck);
		Float3[BoneCount] offsets = .(.(0, 10, 0), .(1, 0, 0), .(0, -4, kneeForward), .(0, -3, -kneeForward),
			.(0, 0, 1), .(0, 2, 0), .(0, 1, 0), .(0, 0.5f, 0));
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

	/// The leg as an animation leaves it: the knee bent forward 0.5 rad (the shin turns about x).
	private static void BentLeg(Skeleton skeleton, List<BoneTransform> outPose)
	{
		BindPose(skeleton, outPose);
		outPose[Shin].Rotation = Quaternion.FromAxisAngle(.(1, 0, 0), -0.5f);
	}

	private static Float3 At(ModelPoseCache cache, int32 bone) => InverseKinematics.Position(cache.At(bone));

	private static Float3 Axis(ModelPoseCache cache, int32 bone, int row)
	{
		let m = cache.At(bone);
		return Normalized(Float3(m.M[row][0], m.M[row][1], m.M[row][2]));
	}

	private static bool Finite(Span<BoneTransform> pose)
	{
		for (let t in pose)
		{
			float[7] v = .(t.Position.X, t.Position.Y, t.Position.Z, t.Rotation.X, t.Rotation.Y, t.Rotation.Z, t.Rotation.W);
			for (let x in v)
			{
				if (x.IsNaN || x.IsInfinity)
					return false;
			}
		}
		return true;
	}

	private static bool SameBytes(Span<BoneTransform> a, Span<BoneTransform> b)
		=> (a.Length == b.Length) && (Internal.MemCmp(a.Ptr, b.Ptr, a.Length * sizeof(BoneTransform)) == 0);

	private static bool Near(float a, float b, float relative)
		=> Math.Abs(a - b) <= relative * Math.Max(Math.Abs(a), Math.Abs(b));

	[Test]
	public static void ATwoBoneChainReachesAReachableTargetExactlyFromEverySideAndKeepsItsLengths()
	{
		let skeleton = scope Skeleton(BoneCount);
		BuildBody(skeleton);
		let hip = Float3(1, 10, 0);
		let pose = scope List<BoneTransform>();
		let cache = scope ModelPoseCache();
		var solved = 0;
		float[3] distances = .(1.5f, 4.0f, 6.9f);
		// Directions spread over the sphere (a golden angle spiral), at three distances inside reach.
		for (int i < 64)
		{
			let y = 1.0f - 2.0f * ((float)i + 0.5f) / 64.0f;
			let r = Math.Sqrt(1.0f - y * y);
			let phi = 2.399963f * (float)i;
			let direction = Float3(r * Math.Cos(phi), y, r * Math.Sin(phi));
			for (let distance in distances)
			{
				for (let withPole in bool[2](false, true))
				{
					BentLeg(skeleton, pose);
					cache.Build(skeleton, pose);
					var settings = TwoBoneIkSettings();
					settings.Target = hip + direction * distance;
					settings.HasPole = withPole;
					settings.Pole = hip + Float3(0, -3, 5);
					let result = InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, settings);
					Test.Assert(result.Valid);
					Test.Assert(result.Reached);
					Test.Assert(result.Error < 1.0e-4f * Reach);
					Test.Assert(Length(At(cache, Foot) - settings.Target) < 1.0e-4f * Reach);
					Test.Assert(Near(Length(At(cache, Shin) - At(cache, Thigh)), 4.0f, 1e-5f));
					Test.Assert(Near(Length(At(cache, Foot) - At(cache, Shin)), 3.0f, 1e-5f));
					Test.Assert(Finite(pose));
					if (withPole)
					{
						// The knee lies in the plane of hip, target and pole, on the pole's side.
						let toTarget = settings.Target - hip;
						let toPole = settings.Pole - hip;
						let normal = Cross(toTarget, toPole);
						if (Length(normal) > 0.1f * Length(toTarget) * Length(toPole))
						{
							let knee = At(cache, Shin) - hip;
							Test.Assert(Math.Abs(Dot(knee, Normalized(normal))) < 1.0e-3f);
							let along = Normalized(toTarget);
							Test.Assert(Dot(knee - along * Dot(knee, along), toPole - along * Dot(toPole, along)) > 0.0f);
						}
					}
					solved++;
				}
			}
		}
		Test.Assert(solved == 384);
	}

	[Test]
	public static void AnUnreachableTargetIsClampedShortOfStraightNeverNaN()
	{
		let skeleton = scope Skeleton(BoneCount);
		BuildBody(skeleton);
		let hip = Float3(1, 10, 0);
		let pose = scope List<BoneTransform>();
		let cache = scope ModelPoseCache();

		// Too far: pointed at it, stopped at 0.995 of full reach.
		{
			BentLeg(skeleton, pose);
			cache.Build(skeleton, pose);
			var settings = TwoBoneIkSettings();
			settings.Target = hip + Float3(0, 0, 20);
			let result = InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, settings);
			Test.Assert(result.Valid);
			Test.Assert(!result.Reached);
			let foot = At(cache, Foot) - hip;
			Test.Assert(Near(Length(foot), InverseKinematics.TwoBoneMaxReach * Reach, 1e-4f));
			Test.Assert(Dot(Normalized(foot), Float3(0, 0, 1)) > 1.0f - 1.0e-5f);
			Test.Assert(Near(result.Error, 20.0f - InverseKinematics.TwoBoneMaxReach * Reach, 1e-3f));
		}
		// At the chain's start: folded to its shortest, finite.
		{
			BentLeg(skeleton, pose);
			cache.Build(skeleton, pose);
			var settings = TwoBoneIkSettings();
			settings.Target = hip;
			let result = InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, settings);
			Test.Assert(result.Valid);
			Test.Assert(Finite(pose));
			Test.Assert(Near(Length(At(cache, Foot) - hip), 1.0f, 1e-3f)); // |4 - 3|
		}
		// A straight chain and a target straight behind it: finite, and reached.
		{
			BindPose(skeleton, pose); // straight down
			cache.Build(skeleton, pose);
			var settings = TwoBoneIkSettings();
			settings.Target = hip + Float3(0, 3, 0); // on the chain's line, the other way
			let result = InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, settings);
			Test.Assert(result.Valid);
			Test.Assert(Finite(pose));
			Test.Assert(result.Reached);
		}
		// Bones that do not form a chain change nothing.
		{
			BentLeg(skeleton, pose);
			let before = scope List<BoneTransform>();
			BentLeg(skeleton, before);
			cache.Build(skeleton, pose);
			var settings = TwoBoneIkSettings();
			settings.Target = hip + Float3(0, -5, 1);
			Test.Assert(!InverseKinematics.SolveTwoBone(skeleton, pose, cache, .(Thigh, Spine, Head), settings).Valid);
			Test.Assert(!InverseKinematics.SolveTwoBone(skeleton, pose, cache, .(Thigh, Shin, 99), settings).Valid);
			Test.Assert(SameBytes(pose, before));
		}
	}

	[Test]
	public static void AStraightChainBendsByTheBindPoseThenTheHingeTheSameWayEachFrame()
	{
		let hip = Float3(1, 10, 0);
		var settings = TwoBoneIkSettings();
		settings.Target = hip + Float3(0, -5, 0); // straight below: nothing in the target picks a side

		// The bind pose's bend: a knee bound forward bends forward.
		{
			let skeleton = scope Skeleton(BoneCount);
			BuildBody(skeleton, 0.3f);
			let pose = scope List<BoneTransform>();
			BindPose(skeleton, pose);
			pose[Shin].Position = .(0, -4, 0); // the animation holds it straight
			pose[Foot].Position = .(0, -3, 0);
			let cache = scope ModelPoseCache();
			cache.Build(skeleton, pose);
			Test.Assert(InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, settings).Reached);
			Test.Assert(At(cache, Shin).Z > 0.5f);
		}
		// No bind bend: the hinge decides.
		{
			let skeleton = scope Skeleton(BoneCount);
			BuildBody(skeleton);
			var hinged = settings;
			hinged.HingeAxis = .(1, 0, 0);
			let pose = scope List<BoneTransform>();
			BindPose(skeleton, pose);
			let cache = scope ModelPoseCache();
			cache.Build(skeleton, pose);
			Test.Assert(InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, hinged).Reached);
			// cross(x, -y) = -z: the mid moves toward cross(hinge, chain direction).
			Test.Assert(At(cache, Shin).Z < -0.5f);
		}
		// Nothing to go by: a fixed side, the same on every frame and on the frame after.
		{
			let skeleton = scope Skeleton(BoneCount);
			BuildBody(skeleton);
			let first = scope List<BoneTransform>();
			let second = scope List<BoneTransform>();
			BindPose(skeleton, first);
			BindPose(skeleton, second);
			let a = scope ModelPoseCache();
			let b = scope ModelPoseCache();
			a.Build(skeleton, first);
			b.Build(skeleton, second);
			Test.Assert(InverseKinematics.SolveTwoBone(skeleton, first, a, Leg, settings).Reached);
			Test.Assert(InverseKinematics.SolveTwoBone(skeleton, second, b, Leg, settings).Reached);
			Test.Assert(SameBytes(first, second));
			// The next frame starts from this bent pose: the knee stays where it went.
			let knee = At(a, Shin);
			Test.Assert(InverseKinematics.SolveTwoBone(skeleton, first, a, Leg, settings).Reached);
			Test.Assert(Length(At(a, Shin) - knee) < 1.0e-4f);
		}
	}

	[Test]
	public static void WeightNoughtIsByteForByteAHalfIsBetweenAndTheEndCanTurn()
	{
		let skeleton = scope Skeleton(BoneCount);
		BuildBody(skeleton);
		let hip = Float3(1, 10, 0);
		var settings = TwoBoneIkSettings();
		settings.Target = hip + Float3(1, -4, 3);
		settings.Pole = hip + Float3(0, 0, 5);
		settings.HasPole = true;

		let original = scope List<BoneTransform>();
		BentLeg(skeleton, original);
		let untouched = scope List<BoneTransform>();
		BentLeg(skeleton, untouched);
		let cache = scope ModelPoseCache();
		cache.Build(skeleton, untouched);
		settings.Weight = 0.0f;
		Test.Assert(InverseKinematics.SolveTwoBone(skeleton, untouched, cache, Leg, settings).Valid);
		Test.Assert(SameBytes(untouched, original));

		let full = scope List<BoneTransform>();
		BentLeg(skeleton, full);
		let fullCache = scope ModelPoseCache();
		fullCache.Build(skeleton, full);
		settings.Weight = 1.0f;
		Test.Assert(InverseKinematics.SolveTwoBone(skeleton, full, fullCache, Leg, settings).Reached);

		let half = scope List<BoneTransform>();
		BentLeg(skeleton, half);
		let halfCache = scope ModelPoseCache();
		halfCache.Build(skeleton, half);
		settings.Weight = 0.5f;
		let result = InverseKinematics.SolveTwoBone(skeleton, half, halfCache, Leg, settings);
		Test.Assert(!result.Reached);
		for (let bone in int32[2](Thigh, Shin))
		{
			let between = Slerp(original[bone].Rotation, full[bone].Rotation, 0.5f);
			Test.Assert(Math.Abs(Dot(half[bone].Rotation, between)) > 1.0f - 1.0e-6f);
		}
		let originalCache = scope ModelPoseCache();
		originalCache.Build(skeleton, original);
		Test.Assert(result.Error > 1.0e-3f);
		Test.Assert(result.Error < Length(At(originalCache, Foot) - settings.Target));

		// MatchRotation: the end bone takes the target's model rotation.
		let turned = scope List<BoneTransform>();
		BentLeg(skeleton, turned);
		let turnedCache = scope ModelPoseCache();
		turnedCache.Build(skeleton, turned);
		settings.Weight = 1.0f;
		settings.MatchRotation = true;
		settings.TargetRotation = Quaternion.FromAxisAngle(Normalized(Float3(1, 1, 0)), 0.7f);
		Test.Assert(InverseKinematics.SolveTwoBone(skeleton, turned, turnedCache, Leg, settings).Reached);
		Test.Assert(Math.Abs(Dot(InverseKinematics.RotationOf(turnedCache.At(Foot)), settings.TargetRotation)) > 1.0f - 1.0e-5f);
	}

	[Test]
	public static void ASolveRebuildsFromTheChainDownAndBonesAboveAndBesideNeverMove()
	{
		let skeleton = scope Skeleton(BoneCount);
		BuildBody(skeleton);
		let pose = scope List<BoneTransform>();
		BentLeg(skeleton, pose);
		let cache = scope ModelPoseCache();
		cache.Build(skeleton, pose);
		Float4x4[BoneCount] above = ?;
		for (int32 i < BoneCount)
			above[i] = cache.At(i);
		var settings = TwoBoneIkSettings();
		settings.Target = .(1.5f, 5, 2);
		Test.Assert(InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, settings).Reached);
		for (let bone in int32[4](Pelvis, Spine, Neck, Head))
		{
			var now = cache.At(bone);
			Test.Assert(Internal.MemCmp(&above[bone], &now, sizeof(Float4x4)) == 0);
		}
		// And what it rebuilt matches a full build of the pose it left.
		let fresh = scope ModelPoseCache();
		fresh.Build(skeleton, pose);
		for (int32 i < BoneCount)
			Test.Assert(Length(At(cache, i) - At(fresh, i)) < 1.0e-5f);
		Test.Assert(Near(Length(At(cache, Toe) - At(cache, Foot)), 1.0f, 1e-5f)); // carried along
	}

	[Test]
	public static void AnAimReachesWithinItsLimitClampsBeyondItSharesTheSwingAndHoldsItsUpAxis()
	{
		let skeleton = scope Skeleton(BoneCount);
		BuildBody(skeleton);
		int32[3] spine = .(Spine, Neck, Head);
		float[3] shares = .(0.3f, 0.5f, 1.0f);
		let head = Float3(0, 13.5f, 0);
		let pose = scope List<BoneTransform>();
		let cache = scope ModelPoseCache();

		// Within the limit: exact, every bone turned, no roll.
		{
			BindPose(skeleton, pose);
			cache.Build(skeleton, pose);
			var settings = AimIkSettings();
			settings.Target = head + Float3(3, 1, 5);
			let result = InverseKinematics.SolveAim(skeleton, pose, cache, spine, shares, settings);
			Test.Assert(result.Valid);
			Test.Assert(result.Reached);
			Test.Assert(result.Error < 1.0e-3f);
			let aim = Axis(cache, Head, 2);
			Test.Assert(Dot(aim, Normalized(settings.Target - At(cache, Head))) > 1.0f - 1.0e-6f);
			for (let bone in spine)
				Test.Assert(Math.Abs(pose[bone].Rotation.W) < 1.0f - 1.0e-4f); // each took a share
			// The up axis leans where the animated up did (straight up), turned only by the swing.
			let up = Axis(cache, Head, 1);
			let upWanted = Normalized(Float3(0, 1, 0) - aim * Dot(Float3(0, 1, 0), aim));
			Test.Assert(Dot(up, upWanted) > 1.0f - 1.0e-5f);
		}
		// Beyond the limit: stopped at MaxAngle from the animated direction.
		{
			BindPose(skeleton, pose);
			cache.Build(skeleton, pose);
			var settings = AimIkSettings();
			settings.Target = head + Float3(5, 0, -1);
			let result = InverseKinematics.SolveAim(skeleton, pose, cache, spine, shares, settings);
			Test.Assert(result.Valid);
			Test.Assert(!result.Reached);
			Test.Assert(Near(Acos(Math.Clamp(Dot(Axis(cache, Head, 2), Float3(0, 0, 1)), -1.0f, 1.0f)), 60.0f * DegToRad, 1e-3f));
			Test.Assert(Finite(pose));
		}
		// An up direction: the head rolls toward it.
		{
			BindPose(skeleton, pose);
			cache.Build(skeleton, pose);
			var settings = AimIkSettings();
			settings.Target = head + Float3(0, 0, 10);
			settings.HasUp = true;
			settings.Up = .(1, 0, 0);
			Test.Assert(InverseKinematics.SolveAim(skeleton, pose, cache, .(&spine[2], 1), .(), settings).Reached);
			Test.Assert(Dot(Axis(cache, Head, 1), Float3(1, 0, 0)) > 1.0f - 1.0e-5f);
		}
		// Weight 0: byte for byte.
		{
			BindPose(skeleton, pose);
			let original = scope List<BoneTransform>();
			BindPose(skeleton, original);
			cache.Build(skeleton, pose);
			var settings = AimIkSettings();
			settings.Target = head + Float3(3, 1, 5);
			settings.Weight = 0.0f;
			Test.Assert(InverseKinematics.SolveAim(skeleton, pose, cache, spine, shares, settings).Valid);
			Test.Assert(SameBytes(pose, original));
		}
	}

	/// A standing leg is nearly straight: the clamp short of locking must not pull it up off the
	/// ground it already reaches, toward a target where it stands or one beyond it.
	[Test]
	public static void AChainTheAnimationHoldsStraighterThanTheClampKeepsItsOwnSpan()
	{
		let skeleton = scope Skeleton(BoneCount);
		BuildBody(skeleton);
		let hip = Float3(1, 10, 0);
		let pose = scope List<BoneTransform>();
		BindPose(skeleton, pose);
		pose[Shin].Rotation = Quaternion.FromAxisAngle(.(1, 0, 0), -0.05f); // 0.9998 of full reach
		let cache = scope ModelPoseCache();
		cache.Build(skeleton, pose);
		let span = Length(At(cache, Foot) - hip);
		Test.Assert(span > InverseKinematics.TwoBoneMaxReach * Reach);
		var settings = TwoBoneIkSettings();
		settings.Target = At(cache, Foot);
		Test.Assert(InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, settings).Reached);
		settings.Target = hip + Normalized(At(cache, Foot) - hip) * 20.0f;
		InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, settings);
		Test.Assert(Near(Length(At(cache, Foot) - hip), span, 1e-5f));
	}

	/// The body's leg without its foot: the chain ends at a point 3 below the shin, carried by it.
	[Test]
	public static void ATipInTheMidBonesSpaceEndsAChainWhoseShinHasNoChild()
	{
		let skeleton = scope Skeleton(BoneCount);
		BuildBody(skeleton);
		let hip = Float3(1, 10, 0);
		var settings = TwoBoneIkSettings();
		settings.UseTip = true;
		settings.Tip = .(0, -3, 0);
		let pose = scope List<BoneTransform>();
		let cache = scope ModelPoseCache();
		Float3[3] points = .(.(1, 5, 2), .(3, 6, -1), .(1, 4, 0));
		for (let at in points)
		{
			BentLeg(skeleton, pose);
			cache.Build(skeleton, pose);
			settings.Target = at;
			let result = InverseKinematics.SolveTwoBone(skeleton, pose, cache, .(Thigh, Shin, -1), settings);
			Test.Assert(result.Valid);
			Test.Assert(result.Reached);
			Test.Assert(Length(TransformPoint(settings.Tip, cache.At(Shin)) - at) < 1.0e-4f * Reach);
			Test.Assert(Near(Length(At(cache, Shin) - hip), 4.0f, 1e-5f));
		}
	}

	/// Sedulous has no counting allocator; the solvers hold no growable storage of their own
	/// (fixed arrays only), so what could allocate per frame is the cache, and its storage must
	/// neither move nor grow once sized.
	[Test]
	public static void ASolveNeverGrowsTheCacheOnceSized()
	{
		let skeleton = scope Skeleton(BoneCount);
		BuildBody(skeleton);
		let cache = scope ModelPoseCache();
		let pose = scope List<BoneTransform>();
		BentLeg(skeleton, pose);
		int32[3] spine = .(Spine, Neck, Head);
		float[3] shares = .(0.3f, 0.5f, 1.0f);
		var leg = TwoBoneIkSettings();
		var look = AimIkSettings();
		leg.Target = .(1, 5, 1);
		look.Target = .(2, 14, 6);
		cache.Build(skeleton, pose);
		InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, leg);
		InverseKinematics.SolveAim(skeleton, pose, cache, spine, shares, look);
		let storage = cache.Model.Ptr;
		for (int frame < 20)
		{
			cache.Build(skeleton, pose);
			leg.Target = .(1.0f + 0.1f * (float)frame, 5, 1);
			look.Target = .(2, 14, 6.0f - 0.2f * (float)frame);
			InverseKinematics.SolveTwoBone(skeleton, pose, cache, Leg, leg);
			InverseKinematics.SolveAim(skeleton, pose, cache, spine, shares, look);
		}
		Test.Assert(cache.Model.Ptr == storage);
		Test.Assert(cache.Model.Length == BoneCount);
	}
}
