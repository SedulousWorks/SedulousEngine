using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;

namespace Sedulous.Animation.Tests;

/// The pose modifier stage (inverse-kinematics.md P0b): a modifier changes the pose between the
/// sample and the palette, every evaluation, so its change survives the next sample and the
/// sampled pose stays as sampled; modifiers run in their order over one model space build; a
/// partial rebuild matches a full one; and no modifier changes nothing.
class PoseModifierTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// root(0) -> child(1) -> grandchild(2), each +Y from its parent, plus a branch(3) off the root.
	private static void BuildTree(Skeleton skeleton)
	{
		int32[4] parents = .(-1, 0, 1, 0);
		float[4] ys = .(10.0f, 5.0f, 2.0f, 3.0f);
		for (int32 i < 4)
		{
			let bone = skeleton.Bones[i];
			bone.Index = i;
			bone.ParentIndex = parents[i];
			bone.LocalBindPose.Position = .(0, ys[i], 0);
		}
		skeleton.BuildNameMap();
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		skeleton.ComputeInverseBindPoses();
	}

	/// Moves one bone's local position up by `lift` and keeps the model pose current.
	private class Lift : IPoseModifier
	{
		private int32 mBone;
		private float mLift;
		private List<int32> mLog;
		private int32 mTag;
		public float SeenGrandchildY = 0.0f;

		public this(int32 bone, float lift, List<int32> log = null, int32 tag = 0)
		{
			mBone = bone;
			mLift = lift;
			mLog = log;
			mTag = tag;
		}

		public void Apply(Skeleton skeleton, Span<BoneTransform> localPoses, ModelPoseCache model)
		{
			mLog?.Add(mTag);
			localPoses[mBone].Position.Y += mLift;
			model.RebuildFrom(skeleton, localPoses, mBone);
			SeenGrandchildY = model.At(2).M[3][1];
		}
	}

	private static float WorldY(Skeleton skeleton, Span<BoneTransform> pose, int32 bone)
	{
		let cache = scope ModelPoseCache();
		cache.Build(skeleton, pose);
		return cache.At(bone).M[3][1];
	}

	/// The child's y climbs 5 -> 6 over the second.
	private static void Climb(AnimationClip clip)
	{
		clip.GetOrCreatePositionTrack(1).AddKeyframe(0.0f, .(0, 5, 0));
		clip.GetOrCreatePositionTrack(1).AddKeyframe(1.0f, .(0, 6, 0));
	}

	[Test]
	public static void AChangeSurvivesTheNextSampleAndTheSampledPoseStaysAsSampled()
	{
		let skeleton = scope Skeleton(4);
		BuildTree(skeleton);
		let clip = scope AnimationClip("Climb", 1.0f, true);
		Climb(clip);
		let player = scope AnimationPlayer(skeleton);
		let lift = scope Lift(2, 1.0f);
		player.Modifiers.Add(lift);
		player.Play(clip);

		for (int frame < 3)
		{
			player.Update(0.25f);
			player.GetSkinningMatrices();
			let sampledChildY = player.GetLocalPoses()[1].Position.Y;
			Test.Assert(Near(player.GetLocalPoses()[2].Position.Y, 2.0f), "sampled: untouched");
			Test.Assert(Near(player.GetFinalPoses()[2].Position.Y, 3.0f), "modified, every time");
			Test.Assert(Near(WorldY(skeleton, player.GetFinalPoses(), 2), 10.0f + sampledChildY + 3.0f));
		}

		// A paused player still re-runs its modifiers: a target moves whether or not the clip does.
		player.Pause();
		let more = scope Lift(2, 2.0f);
		player.Modifiers.Add(more);
		player.GetSkinningMatrices();
		Test.Assert(Near(player.GetFinalPoses()[2].Position.Y, 5.0f));
		player.Modifiers.Remove(more);
		player.Modifiers.Remove(lift);
	}

	[Test]
	public static void TheyRunLowestOrderFirstOverOneModelSpaceBuildAnEvaluation()
	{
		let skeleton = scope Skeleton(4);
		BuildTree(skeleton);
		let player = scope AnimationPlayer(skeleton);
		let log = scope List<int32>();
		let late = scope Lift(1, 1.0f, log, 2);
		let early = scope Lift(1, 1.0f, log, 1);
		let tie = scope Lift(1, 1.0f, log, 3);
		player.Modifiers.Add(late, 5);
		player.Modifiers.Add(early, -1);
		player.Modifiers.Add(tie, 5); // equal orders keep the order they were added in
		let before = player.Modifiers.Model.FullBuilds;
		player.GetSkinningMatrices();
		Test.Assert(log.Count == 3);
		Test.Assert((log[0] == 1) && (log[1] == 2) && (log[2] == 3));
		Test.Assert(player.Modifiers.Model.FullBuilds == before + 1);
		// Each saw the pose the ones before it left: the grandchild rose one more each time.
		Test.Assert(Near(early.SeenGrandchildY, 18.0f));
		Test.Assert(Near(late.SeenGrandchildY, 19.0f));
		Test.Assert(Near(tie.SeenGrandchildY, 20.0f));
		player.Modifiers.Add(early, 0); // already there: not added twice
		Test.Assert(player.Modifiers.Count == 3);
	}

	[Test]
	public static void APartialRebuildMatchesAFullOneAndLeavesTheRestAlone()
	{
		let skeleton = scope Skeleton(4);
		BuildTree(skeleton);
		let pose = scope List<BoneTransform>();
		for (int32 i < 4)
			pose.Add(skeleton.GetBone(i).LocalBindPose);
		let cache = scope ModelPoseCache();
		cache.Build(skeleton, pose);
		let rootBefore = cache.At(0);
		let branchBefore = cache.At(3);

		pose[1].Position.Y = 8.0f;
		pose[1].Rotation = Quaternion.FromAxisAngle(.(0, 0, 1), 0.5f);
		cache.RebuildFrom(skeleton, pose, 1);
		let full = scope ModelPoseCache();
		full.Build(skeleton, pose);
		for (int32 bone < 4)
		{
			for (int r < 4)
			{
				for (int c < 4)
					Test.Assert(Near(cache.At(bone).M[r][c], full.At(bone).M[r][c]));
			}
		}
		Test.Assert(cache.At(0).M[3][1] == rootBefore.M[3][1], "above the change");
		Test.Assert(cache.At(3).M[3][1] == branchBefore.M[3][1], "beside it");
	}

	[Test]
	public static void NoneChangesNothingAndTheGraphPlayerRunsThemAfterItsLayers()
	{
		let skeleton = scope Skeleton(4);
		BuildTree(skeleton);
		let clip = scope AnimationClip("Climb", 1.0f, true);
		Climb(clip);
		let plain = scope AnimationPlayer(skeleton);
		let emptied = scope AnimationPlayer(skeleton);
		let lift = scope Lift(2, 1.0f);
		emptied.Modifiers.Add(lift);
		emptied.Modifiers.Remove(lift);
		plain.Play(clip);
		emptied.Play(clip);
		plain.Update(0.4f);
		emptied.Update(0.4f);
		let a = plain.GetSkinningMatrices();
		let b = emptied.GetSkinningMatrices();
		Test.Assert(a.Length == b.Length);
		Test.Assert(Internal.MemCmp(a.Ptr, b.Ptr, a.Length * sizeof(Float4x4)) == 0, "byte for byte");

		let graph = scope AnimationGraph();
		let layer = new AnimationLayer("Base");
		layer.AddState(new AnimationGraphState("Climb", new ClipStateNode(clip), true));
		graph.AddLayer(layer);
		let player = scope AnimationGraphPlayer(graph, skeleton);
		player.Modifiers.Add(lift);
		player.Update(0.25f);
		Test.Assert(Near(player.GetLocalPoses()[2].Position.Y, 3.0f));
		// The layers combine afresh; the modifier applies again, once.
		player.Update(0.25f);
		Test.Assert(Near(player.GetLocalPoses()[2].Position.Y, 3.0f));
		player.Modifiers.Remove(lift);
	}
}
