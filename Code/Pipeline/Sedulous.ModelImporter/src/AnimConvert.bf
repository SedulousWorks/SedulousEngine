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
/// indices: the skin's joints in its order, then the bones they hang from (SkeletonJoints), are
/// what the skeleton and every animation track are keyed by.
static class AnimConvert
{
	/// The skeleton's joints, as model bone indices, into `outJoints`: the skin's, in its order (a
	/// skinned vertex's joint indices address them), then each node the skeleton hangs from while the
	/// file makes it a bone (ModelBone.IsSkeletonBone). 3ds Max hangs a skeleton from a Dummy helper
	/// bone with no vertices of its own, and animates it with the pose (a creature's bob): it is a
	/// joint, its channels played. An empty node above (Blender's armature object, whose animation is
	/// the character's travel) stays outside: the node the skeleton hangs from, its channels the
	/// clip's model tracks. Then the node each unskinned mesh hangs under, with the nodes between it
	/// and the skeleton, when its chain reaches the skeleton: 3ds Max's Biped animates a weapon's
	/// prop node with the hand (the file does not make it a bone), and no vertex is bound to it, so
	/// without it the clip's prop channels were dropped and the weapon's bone attachment rode the
	/// pelvis. Each is appended after the skin's joints, so no vertex's joint index moves.
	public static void SkeletonJoints(Model model, ModelSkin skin, List<int32> outJoints)
	{
		outJoints.Clear();
		outJoints.AddRange(skin.Joints);
		let bones = model.Bones;
		for (int guard < bones.Length) // a malformed cycle cannot loop for ever
		{
			let hang = JointsParentNode(model, outJoints);
			if ((hang < 0) || (hang >= bones.Length) || (bones[hang] == null) || !bones[hang].IsSkeletonBone)
				break;
			outJoints.Add(hang);
		}

		let meshes = model.Meshes;
		bool Valid(int32 bone) => (bone >= 0) && (bone < bones.Length) && (bones[bone] != null);
		let chain = scope List<int32>();
		for (let node in bones)
		{
			// No mesh, or a skinned one: the palette moves it (a skin with no weights does not, so
			// a mesh is judged by its vertices, not by its node's skin index).
			if ((node == null) || (node.MeshIndex < 0) || (node.MeshIndex >= meshes.Length)
				|| ModelCook.IsSkinned(meshes[node.MeshIndex]))
				continue;
			// The node it hangs under.
			let carrier = node.ParentIndex;
			if (!Valid(carrier) || outJoints.Contains(carrier))
				continue;
			// The nodes from it up to the skeleton, joined parents first; none when it hangs apart.
			chain.Clear();
			var up = carrier;
			for (int guard = 0; Valid(up) && !outJoints.Contains(up) && (guard <= bones.Length); guard++)
			{
				chain.Add(up);
				up = bones[up].ParentIndex;
			}
			if (!Valid(up))
				continue;
			for (int i = chain.Count - 1; i >= 0; i--)
				outJoints.Add(chain[i]);
		}
	}

	/// The model's bone indices to the skeleton's joint indices (`joints`' order, SkeletonJoints). A
	/// bone not among them has no entry at all.
	public static void BuildBoneToJoint(Span<int32> joints, Dictionary<int32, int32> outMap)
	{
		outMap.Clear();
		for (int j < joints.Length)
			outMap[joints[j]] = (int32)j;
	}

	/// The model node the skeleton hangs from: the node above its joints (SkeletonJoints), minus one
	/// the scene root, minus two no joints. Its channels are the clip's model tracks.
	public static int32 SkeletonParentNode(Model model, Span<int32> joints) => JointsParentNode(model, joints);

	/// The model node the joints `joints` hang from: the parent of their first root (a joint whose
	/// parent is not among them), minus one when that root has no parent, minus two with no joints.
	/// Several roots under different nodes take the first root's: the skeleton has one model space.
	public static int32 JointsParentNode(Model model, Span<int32> joints)
	{
		let bones = model.Bones;
		for (let joint in joints)
		{
			if ((joint < 0) || (joint >= bones.Length) || (bones[joint] == null))
				continue;
			let parent = bones[joint].ParentIndex;
			if ((parent < 0) || (parent >= bones.Length))
				return -1;
			var among = false;
			for (let other in joints)
				among = among || (other == parent);
			if (!among)
				return parent;
		}
		return -2;
	}

	/// A skeleton from a skin's skeleton joints (SkeletonJoints): one bone per joint, in their order,
	/// with each local bind pose taken from the model's bone, the inverse bind from the skin
	/// (identity for a bone the skin's joints hang from: no vertex is bound to it), and the parent
	/// remapped into joint space.
	public static void SkeletonFromModel(Model model, ModelSkin skin, Span<int32> joints,
		Dictionary<int32, int32> boneToJoint, SkeletonSource outSource)
	{
		outSource.Name.Set("skeleton");

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
