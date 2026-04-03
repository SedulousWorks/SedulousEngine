namespace Sedulous.Animation.Tests;

using System;

class AnimationPoseTests
{
	[Test]
	public static void Constructor_WithBoneTransforms_SetsBoneCount()
	{
		BoneTransform[4] transforms = .();
		let pose = AnimationPose(transforms);

		Test.Assert(pose.BoneCount == 4);
		Test.Assert(pose.HasMorphWeights == false);
	}

	[Test]
	public static void Constructor_WithMorphWeights_HasMorphWeights()
	{
		BoneTransform[2] transforms = .();
		float[3] morphs = .(0.5f, 0.0f, 1.0f);
		let pose = AnimationPose(transforms, morphs);

		Test.Assert(pose.BoneCount == 2);
		Test.Assert(pose.HasMorphWeights == true);
		Test.Assert(pose.MorphWeights.Length == 3);
	}

	[Test]
	public static void EmptyPose_HasZeroBones()
	{
		let pose = AnimationPose(Span<BoneTransform>());
		Test.Assert(pose.BoneCount == 0);
		Test.Assert(pose.HasMorphWeights == false);
	}

	[Test]
	public static void BoneTransforms_AreAccessible()
	{
		BoneTransform[2] transforms = .();
		transforms[0].Position = .(1, 2, 3);
		transforms[1].Position = .(4, 5, 6);

		let pose = AnimationPose(transforms);
		Test.Assert(pose.BoneTransforms[0].Position.X == 1.0f);
		Test.Assert(pose.BoneTransforms[1].Position.X == 4.0f);
	}
}
