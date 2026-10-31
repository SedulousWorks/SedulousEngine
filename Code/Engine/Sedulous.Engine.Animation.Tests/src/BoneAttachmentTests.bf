using System;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation.Tests;

/// Bone attachments: an entity that follows one bone of the animator above it (a weapon in a
/// hand), its children riding along, while the scene runs. Standing still it stays where its node
/// put it (the rest pose's place); an unknown bone leaves it there.
class BoneAttachmentTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	private static Float3 Position(Float4x4 m) => .(m.M[3][0], m.M[3][1], m.M[3][2]);

	/// A character moved ten along X: an animator on its root playing a clip that slides the root
	/// bone two along X; a hand bone one above it; the hand's node with an attachment, a sword one
	/// along Z under it; the skinned body (the model entity) under the root at identity.
	private class Stage
	{
		public Skeleton Skeleton = new .(2);
		public AnimationClip Clip = new .("Slide", 1.0f, true) ~ delete _;
		public Scene Level = new .("attach");
		public EntityHandle Root;
		public EntityHandle Hand;
		public EntityHandle Sword;

		public this(StringView bone)
		{
			Skeleton.Bones[0].Index = 0;
			Skeleton.Bones[0].ParentIndex = -1;
			Skeleton.Bones[0].Name.Set("Root");
			Skeleton.Bones[1].Index = 1;
			Skeleton.Bones[1].ParentIndex = 0;
			Skeleton.Bones[1].Name.Set("Hand");
			Skeleton.Bones[1].LocalBindPose.Position = .(0, 1, 0);
			Skeleton.BuildNameMap();
			Skeleton.FindRootBones();
			Skeleton.BuildChildIndices();
			Skeleton.ComputeInverseBindPoses();
			Clip.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(2, 0, 0));
			Clip.GetOrCreatePositionTrack(0).AddKeyframe(1.0f, .(2, 0, 0));

			Level.AddSystem<MeshComponentManager>();
			AnimationScene.AddAnimationSceneManagers(Level);
			Root = Level.CreateEntity("Knight");
			Level.SetLocalTransform(Root, .(.(10, 0, 0), .Identity, .(1, 1, 1)));
			let body = Level.CreateEntity("Body");
			Level.SetParent(body, Root);
			let animator = Level.GetSystem<SkeletalAnimationComponentManager>().Add(Root);
			animator.Skeleton.SetDirect(Skeleton);
			animator.Clip.SetDirect(Clip);
			animator.MeshEntities.Add(EntityRef(Level.GetEntityId(body)));

			Hand = Level.CreateEntity("Hand");
			Level.SetParent(Hand, Root);
			Level.SetLocalTransform(Hand, .(.(0, 1, 0), .Identity, .(1, 1, 1)));
			Attachments.Add(Hand).Bone.Set(bone);
			Sword = Level.CreateEntity("Sword");
			Level.SetParent(Sword, Hand);
			Level.SetLocalTransform(Sword, .(.(0, 0, 1), .Identity, .(1, 1, 1)));
			Level.UpdateTransforms();
		}

		public ~this()
		{
			// The scene first: its animator borrows the skeleton and the clip.
			delete Level;
			delete Skeleton;
		}

		public BoneAttachmentComponentManager Attachments => Level.GetSystem<BoneAttachmentComponentManager>();
	}

	[Test]
	public static void AnEntityFollowsItsBoneWhileTheSceneRunsItsChildrenAlong()
	{
		let stage = scope Stage("Hand");
		stage.Level.Update(1.0f / 30.0f);
		// The root bone slid two along X, so the hand stands at 12,1,0 in the world, the sword at 12,1,1.
		let hand = Position(stage.Level.GetWorldMatrix(stage.Hand));
		Test.Assert(Near(hand.X, 12.0f));
		Test.Assert(Near(hand.Y, 1.0f));
		let sword = Position(stage.Level.GetWorldMatrix(stage.Sword));
		Test.Assert(Near(sword.X, 12.0f));
		Test.Assert(Near(sword.Z, 1.0f));
		Test.Assert(stage.Attachments.Get(stage.Hand).Runtime.Status == .Following);

		// The character moves: the hand comes along the same frame.
		stage.Level.SetLocalTransform(stage.Root, .(.(20, 0, 0), .Identity, .(1, 1, 1)));
		stage.Level.Update(1.0f / 30.0f);
		Test.Assert(Near(Position(stage.Level.GetWorldMatrix(stage.Hand)).X, 22.0f));
	}

	[Test]
	public static void StandingStillOrNamingNoBoneItStaysWhereItsNodePutIt()
	{
		let still = scope Stage("Hand");
		still.Level.SetSimulationEnabled(false);
		still.Level.Update(1.0f / 30.0f);
		Test.Assert(Near(Position(still.Level.GetWorldMatrix(still.Hand)).X, 10.0f));

		let unknown = scope Stage("Tail");
		unknown.Level.Update(1.0f / 30.0f);
		Test.Assert(Near(Position(unknown.Level.GetWorldMatrix(unknown.Hand)).X, 10.0f));
		Test.Assert(unknown.Attachments.Get(unknown.Hand).Runtime.Status == .UnknownBone);
	}
}
