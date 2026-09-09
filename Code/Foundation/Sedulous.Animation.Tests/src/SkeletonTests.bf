using System;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// The hierarchy: the lookups, the evaluation order, and the matrices a pose becomes.
class SkeletonTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// A chain of three, each translated up from its parent.
	private static void BuildChain(Skeleton skeleton)
	{
		let bones = skeleton.Bones;
		bones[0].ParentIndex = -1;
		bones[0].Name.Set("root");
		bones[0].LocalBindPose.Position = .(0, 10, 0);
		bones[1].ParentIndex = 0;
		bones[1].Name.Set("child");
		bones[1].LocalBindPose.Position = .(0, 5, 0);
		bones[2].ParentIndex = 1;
		bones[2].Name.Set("grandchild");
		bones[2].LocalBindPose.Position = .(0, 2, 0);

		skeleton.BuildNameMap();
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
	}

	[Test]
	public static void TheNameMapAndTheRootsAreFound()
	{
		let skeleton = scope Skeleton(3);
		BuildChain(skeleton);

		Test.Assert(skeleton.BoneCount == 3);
		Test.Assert(skeleton.FindBone("child") == 1);
		Test.Assert(skeleton.FindBone("grandchild") == 2);
		Test.Assert(skeleton.FindBone("missing") == -1);
		Test.Assert(skeleton.RootBones.Length == 1);
		Test.Assert(skeleton.RootBones[0] == 0);
	}

	/// A world pose ACCUMULATES down the chain: a pure translation composes additively, so
	/// the grandchild sits at the sum of all three.
	[Test]
	public static void TheWorldPosesAccumulateDownTheHierarchy()
	{
		let skeleton = scope Skeleton(3);
		BuildChain(skeleton);

		let world = scope Float4x4[3];
		skeleton.ComputeWorldPoses(default, world);

		Test.Assert(Near(world[0].M[3][1], 10.0f));
		Test.Assert(Near(world[1].M[3][1], 15.0f));
		Test.Assert(Near(world[2].M[3][1], 17.0f));
	}

	/// At the BIND pose every skinning matrix is the identity, since the inverse bind and
	/// the world pose are then each other's inverse. That is the whole invariant skinning
	/// rests on: an unanimated mesh must not move.
	[Test]
	public static void TheSkinningMatricesAreIdentityAtTheBindPose()
	{
		let skeleton = scope Skeleton(3);
		BuildChain(skeleton);
		skeleton.ComputeInverseBindPoses();

		let skin = scope Float4x4[3];
		skeleton.ComputeSkinningMatrices(default, skin);

		for (int i < 3)
		{
			Test.Assert(Near(skin[i].M[0][0], 1.0f));
			Test.Assert(Near(skin[i].M[1][1], 1.0f));
			Test.Assert(Near(skin[i].M[2][2], 1.0f));
			Test.Assert(Near(skin[i].M[3][0], 0.0f));
			Test.Assert(Near(skin[i].M[3][1], 0.0f));
			Test.Assert(Near(skin[i].M[3][2], 0.0f));
		}
	}

	/// A child declared BEFORE its parent still evaluates after it: the order is built from
	/// the hierarchy rather than assumed from the array, and an exporter is free to write
	/// them in whatever order it likes.
	[Test]
	public static void AChildDeclaredBeforeItsParentStillEvaluatesAfterIt()
	{
		let skeleton = scope Skeleton(2);
		let bones = skeleton.Bones;
		bones[0].ParentIndex = 1;
		bones[1].ParentIndex = -1;
		bones[0].LocalBindPose.Position = .(0, 1, 0);
		bones[1].LocalBindPose.Position = .(0, 100, 0);
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();

		let world = scope Float4x4[2];
		skeleton.ComputeWorldPoses(default, world);

		// In index order bone nought would miss bone one's transform entirely.
		Test.Assert(Near(world[0].M[3][1], 101.0f));
		Test.Assert(Near(world[1].M[3][1], 100.0f));
	}

	/// A bone whose parent is not there is still posed, in whatever order is left: a broken
	/// hierarchy loses its parenting, not its bones.
	[Test]
	public static void AnOrphanIsStillPosed()
	{
		let skeleton = scope Skeleton(2);
		let bones = skeleton.Bones;
		bones[0].ParentIndex = -1;
		bones[0].LocalBindPose.Position = .(0, 3, 0);
		// A parent that is not a bone, which is what an import that dropped an ancestor
		// leaves behind. No walk from a root reaches it, and it poses against nothing.
		bones[1].ParentIndex = 99;
		bones[1].LocalBindPose.Position = .(0, 7, 0);
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();

		let world = scope Float4x4[2];
		skeleton.ComputeWorldPoses(default, world);
		Test.Assert(Near(world[0].M[3][1], 3.0f));
		Test.Assert(Near(world[1].M[3][1], 7.0f));
	}
}
