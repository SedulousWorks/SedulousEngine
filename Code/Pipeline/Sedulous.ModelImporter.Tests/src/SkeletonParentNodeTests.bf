using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Animation.Resource;
using Sedulous.Model;
using Sedulous.ModelImporter;

namespace Sedulous.ModelImporter.Tests;

/// The node a skeleton hangs from, which the prefab puts skinned meshes under at identity
/// (inverse-kinematics.md P0a): it must be the node the joints hang from, Blender's armature
/// object, not a joint.
class SkeletonParentNodeTests
{
	[Test]
	public static void TheSkeletonsParentNodeIsTheSkinsRootJointsParent()
	{
		let model = scope Model();
		int32 Bone(StringView name, int32 parent)
		{
			let bone = new ModelBone();
			bone.Name.Set(name);
			bone.ParentIndex = parent;
			return model.AddBone(bone);
		}
		let scene = Bone("Scene", -1);
		let armature = Bone("Armature", scene);
		let hips = Bone("Hips", armature);
		let spine = Bone("Spine", hips);
		Bone("Body", armature);

		// Joints listed child first: the root is found by its parent, not by its place in the list.
		let skin = scope ModelSkin();
		skin.AddJoint(spine, Float4x4.Identity());
		skin.AddJoint(hips, Float4x4.Identity());
		Test.Assert(AnimConvert.SkeletonParentNode(model, Joints(model, skin, .. scope .())) == armature);

		// A root joint at the top of the file has no parent node: the scene root (-1).
		let top = scope ModelSkin();
		top.AddJoint(scene, Float4x4.Identity());
		top.AddJoint(armature, Float4x4.Identity());
		Test.Assert(AnimConvert.SkeletonParentNode(model, Joints(model, top, .. scope .())) == -1);

		// No joints: unknown (-2), and the prefab keeps the file's placement.
		let empty = scope ModelSkin();
		Test.Assert(AnimConvert.SkeletonParentNode(model, Joints(model, empty, .. scope .())) == -2);
	}

	private static List<int32> Joints(Model model, ModelSkin skin, List<int32> outJoints)
	{
		AnimConvert.SkeletonJoints(model, skin, outJoints);
		return outJoints;
	}

	// 3ds Max hangs a skeleton from a Dummy helper bone with no vertices of its own and animates it
	// with the pose (a creature bobbing as it idles). Left outside the skeleton, as Blender's armature
	// object is, the bob was a model track the pose never played.
	[Test]
	public static void ABoneTheSkinsJointsHangFromJoinsTheSkeletonItsAnimationPlayedAnEmptyOneDoesNot()
	{
		for (let helperIsBone in bool[2](true, false))
		{
			let model = scope Model();
			int32 Bone(StringView name, int32 parent, bool isBone)
			{
				let bone = new ModelBone();
				bone.Name.Set(name);
				bone.ParentIndex = parent;
				bone.IsSkeletonBone = isBone;
				return model.AddBone(bone);
			}
			let root = Bone("300024", -1, false);
			let dummy = Bone("Dummy001", root, helperIsBone);
			let spine = Bone("Bone001", dummy, true);
			let arm = Bone("Bone002", spine, true);
			let skin = scope ModelSkin();
			skin.AddJoint(spine, Float4x4.Identity());
			skin.AddJoint(arm, Float4x4.Identity());

			let idle = scope ModelAnimation();
			idle.Duration = 1.0f;
			let bob = new AnimationChannel();
			bob.TargetBone = dummy;
			bob.Path = .Translation;
			bob.AddKeyframe(0.0f, .(0.0f, 1.0f, 0.0f, 0.0f));
			bob.AddKeyframe(1.0f, .(0.0f, 1.6f, 0.0f, 0.0f));
			idle.AddChannel(bob);
			let wave = new AnimationChannel();
			wave.TargetBone = arm;
			wave.Path = .Rotation;
			wave.AddKeyframe(0.0f, .(0.0f, 0.0f, 0.0f, 1.0f));
			idle.AddChannel(wave);

			let joints = Joints(model, skin, .. scope .());
			let boneToJoint = scope Dictionary<int32, int32>();
			AnimConvert.BuildBoneToJoint(joints, boneToJoint);
			let skeleton = scope SkeletonSource();
			AnimConvert.SkeletonFromModel(model, skin, joints, boneToJoint, skeleton);
			let hangsFrom = AnimConvert.SkeletonParentNode(model, joints);
			let clip = scope AnimationClipSource();
			AnimConvert.ClipFromModel(idle, boneToJoint, "idle", clip, hangsFrom);
			Test.Assert(clip.TrackBone.Count == 2);
			if (helperIsBone)
			{
				// Appended after the skin's joints (no vertex's joint index moves), the skin's root
				// joint under it, the mesh's placement node above it, and its bob a track of the pose.
				Test.Assert(joints.Count == 3);
				Test.Assert(joints[2] == dummy);
				Test.Assert(skeleton.BoneName[2] == "Dummy001");
				Test.Assert(skeleton.ParentIndex[0] == 2);
				Test.Assert(skeleton.ParentIndex[2] == -1);
				Test.Assert(hangsFrom == root);
				Test.Assert(clip.TrackBone[0] == 2);
			}
			else
			{
				// An empty node: the node the skeleton hangs from, its channel the clip's model track.
				Test.Assert(joints.Count == 2);
				Test.Assert(skeleton.ParentIndex[0] == -1);
				Test.Assert(hangsFrom == dummy);
				Test.Assert(clip.TrackBone[0] == -1);
			}
			Test.Assert(clip.TrackBone[1] == 1, "the arm, wherever the helper went");
		}
	}

	// A rig whose second spine bone carries no vertices: the skin's joints are the pelvis and the
	// ribcage, with the spine between them. Left out, the ribcage rooted a skeleton of its own and
	// the upper body ignored the spine's rest and its sway.
	[Test]
	public static void ABoneBetweenTwoJointsThatNoVertexIsBoundToJoinsTheSkeletonItsAnimationPlayed()
	{
		let model = scope Model();
		int32 Bone(StringView name, int32 parent)
		{
			let bone = new ModelBone();
			bone.Name.Set(name);
			bone.ParentIndex = parent;
			bone.IsSkeletonBone = true;
			return model.AddBone(bone);
		}
		let pelvis = Bone("RigPelvis", -1);
		let spine1 = Bone("RigSpine1", pelvis);
		let spine2 = Bone("RigSpine2", spine1);
		let ribcage = Bone("RigRibcage", spine2);
		let head = Bone("RigHead", ribcage);
		let apart = Bone("Apart", -1);
		let tail = Bone("RigTail", apart); // a joint under a node the skeleton does not reach
		let skin = scope ModelSkin();
		skin.AddJoint(pelvis, Float4x4.Identity());
		skin.AddJoint(ribcage, Float4x4.Identity());
		skin.AddJoint(head, Float4x4.Identity());
		skin.AddJoint(tail, Float4x4.Identity());

		let idle = scope ModelAnimation();
		idle.Duration = 1.0f;
		let sway = new AnimationChannel();
		sway.TargetBone = spine2;
		sway.Path = .Rotation;
		sway.AddKeyframe(0.0f, .(0.0f, 0.0f, 0.0f, 1.0f));
		sway.AddKeyframe(1.0f, .(0.0f, 0.0f, 0.38f, 0.92f));
		idle.AddChannel(sway);

		let joints = Joints(model, skin, .. scope .());
		Test.Assert(joints.Count == 6, "the skin's four (no vertex's joint index moves), then the spine, parents first");
		Test.Assert(joints[0] == pelvis);
		Test.Assert(joints[3] == tail);
		Test.Assert(joints[4] == spine1);
		Test.Assert(joints[5] == spine2);
		let boneToJoint = scope Dictionary<int32, int32>();
		AnimConvert.BuildBoneToJoint(joints, boneToJoint);
		let skeleton = scope SkeletonSource();
		AnimConvert.SkeletonFromModel(model, skin, joints, boneToJoint, skeleton);
		Test.Assert(skeleton.ParentIndex[4] == 0, "spine 1 under the pelvis");
		Test.Assert(skeleton.ParentIndex[5] == 4, "spine 2 under spine 1");
		Test.Assert(skeleton.ParentIndex[1] == 5, "the ribcage under spine 2, not a root");
		Test.Assert(skeleton.ParentIndex[2] == 1, "the head under the ribcage");
		Test.Assert(skeleton.ParentIndex[3] < 0, "the tail's chain never reaches the skeleton: a root, as before");
		let clip = scope AnimationClipSource();
		AnimConvert.ClipFromModel(idle, boneToJoint, "idle", clip, AnimConvert.SkeletonParentNode(model, joints));
		Test.Assert(clip.TrackBone.Count == 1);
		Test.Assert(clip.TrackBone[0] == 5, "the spine's sway is a track of the pose");
	}

	// 3ds Max's Biped animates a weapon's prop node with the hand; the file does not make it a bone
	// and no vertex is bound to it. Left outside the skeleton, its channels were dropped and the
	// weapon rode the pelvis.
	[Test]
	public static void TheNodeAnUnskinnedMeshHangsUnderJoinsTheSkeletonItsAnimationPlayed()
	{
		let model = scope Model();
		int32 Bone(StringView name, int32 parent, bool isBone, int32 mesh = -1)
		{
			let bone = new ModelBone();
			bone.Name.Set(name);
			bone.ParentIndex = parent;
			bone.IsSkeletonBone = isBone;
			bone.MeshIndex = mesh;
			return model.AddBone(bone);
		}
		for (int i < 4)
			model.AddMesh(new ModelMesh()); // no joints or weights: unskinned
		let root = Bone("100001", -1, false);
		let bip = Bone("Bip001", root, true);
		let hand = Bone("Bip001 R Hand", bip, true);
		let prop = Bone("Bip001 Prop1", bip, false); // not a file bone
		let grip = Bone("Grip", prop, false); // the node the weapon hangs under
		Bone("Weapon", grip, false, 1);
		let apart = Bone("Stand", root, false); // a node the skeleton does not reach
		Bone("Banner", apart, false, 2);
		Bone("Hilt", hand, false, 3); // under a joint already: nothing to add
		let skin = scope ModelSkin();
		skin.AddJoint(bip, Float4x4.Identity());
		skin.AddJoint(hand, Float4x4.Identity());

		let swing = scope ModelAnimation();
		swing.Duration = 1.0f;
		let lift = new AnimationChannel();
		lift.TargetBone = prop;
		lift.Path = .Translation;
		lift.AddKeyframe(0.0f, .(0.0f, 0.0f, 0.0f, 0.0f));
		lift.AddKeyframe(1.0f, .(0.0f, 1.0f, 0.0f, 0.0f));
		swing.AddChannel(lift);

		let joints = Joints(model, skin, .. scope .());
		Test.Assert(joints.Count == 4, "the skin's two, then the prop and the grip; not the stand");
		Test.Assert(joints[0] == bip);
		Test.Assert(joints[1] == hand);
		Test.Assert(joints[2] == prop);
		Test.Assert(joints[3] == grip);
		let boneToJoint = scope Dictionary<int32, int32>();
		AnimConvert.BuildBoneToJoint(joints, boneToJoint);
		let skeleton = scope SkeletonSource();
		AnimConvert.SkeletonFromModel(model, skin, joints, boneToJoint, skeleton);
		Test.Assert(skeleton.BoneName[2] == "Bip001 Prop1");
		Test.Assert(skeleton.ParentIndex[2] == 0, "under the pelvis's joint");
		let clip = scope AnimationClipSource();
		AnimConvert.ClipFromModel(swing, boneToJoint, "swing", clip, AnimConvert.SkeletonParentNode(model, joints));
		Test.Assert(clip.TrackBone.Count == 1);
		Test.Assert(clip.TrackBone[0] == 2, "the prop's swing is a track of the pose");
	}
}
