using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Core;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// A loaded model's skin and animations into the cooked animation sources.
///
/// Everything here is remapped from the model's BONE indices into the skeleton's JOINT
/// indices, since the skin's joint order is what the skeleton and every animation track are
/// keyed by.
static class AnimConvert
{
	/// The model's bone indices to the skin's joint indices. A bone the skin does not use has
	/// no entry at all.
	public static void BuildBoneToJoint(ModelSkin skin, Dictionary<int32, int32> outMap)
	{
		outMap.Clear();
		let joints = skin.Joints;
		for (int j < joints.Length)
			outMap[joints[j]] = (int32)j;
	}

	/// The model node the skeleton hangs from: the parent of the skin's first root joint (a
	/// joint whose parent is not in the skin), minus one when that root has no parent, minus two
	/// for a skin with no joints. A skin with several roots under different nodes takes the
	/// first root's: the skeleton has one model space.
	public static int32 SkeletonParentNode(Model model, ModelSkin skin, Dictionary<int32, int32> boneToJoint)
	{
		let bones = model.Bones;
		for (let joint in skin.Joints)
		{
			if ((joint < 0) || (joint >= bones.Length) || (bones[joint] == null))
				continue;
			let parent = bones[joint].ParentIndex;
			if ((parent < 0) || (parent >= bones.Length))
				return -1;
			if (!boneToJoint.ContainsKey(parent))
				return parent;
		}
		return -2;
	}

	/// A skeleton from a skin: one bone per joint, in joint order, with each local bind pose
	/// taken from the model's bone, the inverse bind from the skin, and the parent remapped
	/// into joint space.
	public static void SkeletonFromModel(Model model, ModelSkin skin,
		Dictionary<int32, int32> boneToJoint, SkeletonSource outSource)
	{
		outSource.Name.Set("skeleton");

		let joints = skin.Joints;
		let inverseBinds = skin.InverseBindMatrices;
		let bones = model.Bones;

		for (int j < joints.Length)
		{
			let boneIndex = joints[j];
			let bone = ((boneIndex >= 0) && (boneIndex < bones.Length)) ? bones[boneIndex] : null;

			outSource.BoneName.Add((bone != null) ? new String(bone.Name) : new String());

			int32 parentJoint = -1;
			if ((bone != null) && (bone.ParentIndex >= 0))
			{
				if (boneToJoint.TryGetValue(bone.ParentIndex, let mapped))
					parentJoint = mapped;
			}
			outSource.ParentIndex.Add(parentJoint);

			outSource.Translation.Add((bone != null) ? bone.Translation : Float3(0, 0, 0));
			outSource.Rotation.Add((bone != null) ? bone.Rotation : Quaternion.Identity);
			outSource.Scale.Add((bone != null) ? bone.Scale : Float3(1, 1, 1));
			outSource.InverseBindPose.Add((j < inverseBinds.Length) ? inverseBinds[j]
				: Float4x4.Identity());
		}
	}

	/// A clip from a model animation: each channel becomes a dense track keyed by JOINT index. A
	/// channel on `modelNode` (the node the skeleton hangs from: Blender's armature object)
	/// becomes a MODEL track, bone minus one: the pose never plays it, and root motion may take
	/// the armature's travel from it (root-motion.md P0). Other channels on bones outside the
	/// skin, and morph weight channels, are skipped.
	public static void ClipFromModel(ModelAnimation animation, Dictionary<int32, int32> boneToJoint,
		StringView name, AnimationClipSource outSource, int32 modelNode = -2)
	{
		outSource.Name.Set(name);
		outSource.Duration = animation.Duration;
		outSource.IsLooping = true;

		for (let channel in animation.Channels)
		{
			if (channel == null)
				continue;
			int32 joint = -1;
			if (!boneToJoint.TryGetValue(channel.TargetBone, out joint))
			{
				// A bone not in this skin, unless it is the armature node: a model track.
				if ((modelNode < 0) || (channel.TargetBone != modelNode))
					continue;
				joint = -1;
			}

			TrackKind kind;
			switch (channel.Path)
			{
			case .Translation: kind = .Position;
			case .Rotation: kind = .Rotation;
			case .Scale: kind = .Scale;
			default: continue; // a morph weight channel, which nothing plays
			}

			var interpolation = InterpolationMode.Linear;
			if (channel.Interpolation == .Step)
				interpolation = .Step;
			else if (channel.Interpolation == .CubicSpline)
				interpolation = .CubicSpline;

			let keys = channel.Keyframes;
			outSource.TrackBone.Add(joint);
			outSource.TrackKindValue.Add((uint8)kind);
			outSource.TrackInterp.Add((uint8)interpolation);
			outSource.TrackStart.Add((uint32)outSource.KeyTime.Count);
			outSource.TrackCount.Add((uint32)keys.Length);

			for (int k < keys.Length)
			{
				outSource.KeyTime.Add(keys[k].Time);
				// The first three components for a position or a scale, all four for a
				// rotation, which is the layout the reader unpacks by kind.
				outSource.KeyValue.Add(keys[k].Value);
			}
		}
	}
}
