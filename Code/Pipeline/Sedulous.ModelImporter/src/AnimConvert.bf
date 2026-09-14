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

	/// A clip from a model animation: each channel becomes a dense track keyed by JOINT index.
	///
	/// A channel targeting a bone outside this skin is skipped, as is a morph weight channel,
	/// which nothing here plays.
	public static void ClipFromModel(ModelAnimation animation, Dictionary<int32, int32> boneToJoint,
		StringView name, AnimationClipSource outSource)
	{
		outSource.Name.Set(name);
		outSource.Duration = animation.Duration;
		outSource.IsLooping = true;

		for (let channel in animation.Channels)
		{
			if (channel == null)
				continue;
			if (!boneToJoint.TryGetValue(channel.TargetBone, let joint))
				continue;

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
