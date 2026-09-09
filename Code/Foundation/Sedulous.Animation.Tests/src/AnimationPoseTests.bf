using System;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// The pose view, which owns nothing and counts what it points at.
class AnimationPoseTests
{
	[Test]
	public static void APoseCountsTheBonesItPointsAt()
	{
		let bones = scope BoneTransform[3];
		let pose = AnimationPose(bones);
		Test.Assert(pose.BoneCount == 3);
		Test.Assert(!pose.HasMorphWeights);
	}

	[Test]
	public static void APoseCarriesMorphWeightsBesideTheBones()
	{
		let bones = scope BoneTransform[2];
		let morphs = scope float[4];
		let pose = AnimationPose(bones, morphs);
		Test.Assert(pose.BoneCount == 2);
		Test.Assert(pose.HasMorphWeights);
		Test.Assert(pose.MorphWeights.Length == 4);
	}

	[Test]
	public static void ADefaultPoseHasNothingInIt()
	{
		let pose = AnimationPose();
		Test.Assert(pose.BoneCount == 0);
		Test.Assert(!pose.HasMorphWeights);
	}

	/// The view is over the CALLER'S array, so writing through it writes there.
	[Test]
	public static void ThePoseIsAViewRatherThanACopy()
	{
		let bones = scope BoneTransform[2];
		var pose = AnimationPose(bones);
		pose.BoneTransforms[1].Position = .(1, 2, 3);
		Test.Assert(bones[1].Position == Float3(1, 2, 3));
	}
}
