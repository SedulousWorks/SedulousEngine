using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Geometry;
using Sedulous.Models;
using Sedulous.Animation;

namespace Sedulous.Geometry.Tooling;

/// Converts Model bone/skin data to runtime Skeleton format.
static class SkeletonConverter
{
	/// Creates a Skeleton from a Model's skin and bones.
	/// The skeleton is ordered by skin joint index so that bone indices match vertex joint indices.
	/// Non-joint ancestor nodes are appended after skin joints to preserve animated root motion.
	public static Skeleton CreateFromSkin(Model model, ModelSkin skin)
	{
		if (model == null || skin == null || skin.Joints.Count == 0)
			return null;

		// Build node-to-bone mapping for parent index remapping
		var nodeToSkinJoint = scope int32[model.Bones.Count];
		for (int i = 0; i < nodeToSkinJoint.Count; i++)
			nodeToSkinJoint[i] = -1;

		for (int32 skinJointIdx = 0; skinJointIdx < skin.Joints.Count; skinJointIdx++)
		{
			let nodeIdx = skin.Joints[skinJointIdx];
			if (nodeIdx >= 0 && nodeIdx < nodeToSkinJoint.Count)
				nodeToSkinJoint[nodeIdx] = skinJointIdx;
		}

		// Collect non-joint ancestor nodes and assign them bone indices after skin joints.
		// This ensures animated transforms on ancestor nodes (e.g. root motion on the
		// Armature node) propagate through the skeleton hierarchy instead of being lost.
		let ancestorNodes = scope List<int32>();
		CollectAncestorNodes(model, skin, nodeToSkinJoint, ancestorNodes);

		for (int32 i = 0; i < ancestorNodes.Count; i++)
			nodeToSkinJoint[ancestorNodes[i]] = (int32)skin.Joints.Count + i;

		// Create skeleton with skin joints + ancestor bones
		int32 totalBones = (int32)skin.Joints.Count + (int32)ancestorNodes.Count;
		let skeleton = new Skeleton(totalBones);

		// Create skeleton bones ordered by skin joint index
		for (int32 skinJointIdx = 0; skinJointIdx < skin.Joints.Count; skinJointIdx++)
		{
			let nodeIdx = skin.Joints[skinJointIdx];
			if (nodeIdx < 0 || nodeIdx >= model.Bones.Count)
				continue;

			let modelBone = model.Bones[nodeIdx];

			// Remap parent index from node index to skeleton bone index (includes ancestors)
			int32 parentBoneIdx = -1;
			if (modelBone.ParentIndex >= 0 && modelBone.ParentIndex < nodeToSkinJoint.Count)
				parentBoneIdx = nodeToSkinJoint[modelBone.ParentIndex];

			// Use inverse bind matrix from skin (more reliable than bone's copy)
			let ibm = (skinJointIdx < skin.InverseBindMatrices.Count)
				? skin.InverseBindMatrices[skinJointIdx]
				: Matrix.Identity;

			// Set up the bone in the skeleton
			let bone = skeleton.Bones[skinJointIdx];
			bone.Name.Set(modelBone.Name);
			bone.Index = skinJointIdx;
			bone.ParentIndex = parentBoneIdx;
			bone.InverseBindPose = ibm;
			bone.LocalBindPose = BoneTransform(modelBone.Translation, modelBone.Rotation, modelBone.Scale);

			// For bones still without a parent in the skeleton, compute RootCorrection
			// to capture any remaining ancestor transforms above the skeleton
			if (parentBoneIdx == -1 && modelBone.ParentIndex >= 0)
				bone.RootCorrection = ComputeRootCorrection(model, modelBone.ParentIndex);
		}

		// Create ancestor bones (appended after skin joints)
		for (int32 i = 0; i < ancestorNodes.Count; i++)
		{
			let nodeIdx = ancestorNodes[i];
			let modelBone = model.Bones[nodeIdx];
			let boneIdx = (int32)skin.Joints.Count + i;

			int32 parentBoneIdx = -1;
			if (modelBone.ParentIndex >= 0 && modelBone.ParentIndex < nodeToSkinJoint.Count)
				parentBoneIdx = nodeToSkinJoint[modelBone.ParentIndex];

			let bone = skeleton.Bones[boneIdx];
			bone.Name.Set(modelBone.Name);
			bone.Index = boneIdx;
			bone.ParentIndex = parentBoneIdx;
			bone.InverseBindPose = .Identity; // No vertices are weighted to ancestor bones
			bone.LocalBindPose = BoneTransform(modelBone.Translation, modelBone.Rotation, modelBone.Scale);

			// RootCorrection for topmost ancestor if it still has model ancestors
			if (parentBoneIdx == -1 && modelBone.ParentIndex >= 0)
				bone.RootCorrection = ComputeRootCorrection(model, modelBone.ParentIndex);
		}

		// Build skeleton hierarchy data
		skeleton.BuildNameMap();
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();

		return skeleton;
	}

	/// Creates a node-to-bone mapping from a skin.
	/// This maps node indices to skeleton bone indices for animation channel remapping.
	/// Includes non-joint ancestor nodes so that root motion animation channels are preserved.
	/// Caller owns the returned array.
	public static int32[] CreateNodeToBoneMapping(Model model, ModelSkin skin)
	{
		if (model == null || skin == null)
			return null;

		let mapping = new int32[model.Bones.Count];
		for (int i = 0; i < mapping.Count; i++)
			mapping[i] = -1;

		for (int32 skinJointIdx = 0; skinJointIdx < skin.Joints.Count; skinJointIdx++)
		{
			let nodeIdx = skin.Joints[skinJointIdx];
			if (nodeIdx >= 0 && nodeIdx < mapping.Count)
				mapping[nodeIdx] = skinJointIdx;
		}

		// Include ancestor nodes with same indices as skeleton creation
		let ancestorNodes = scope List<int32>();
		CollectAncestorNodes(model, skin, mapping, ancestorNodes);

		for (int32 i = 0; i < ancestorNodes.Count; i++)
		{
			let nodeIdx = ancestorNodes[i];
			if (nodeIdx >= 0 && nodeIdx < mapping.Count)
				mapping[nodeIdx] = (int32)skin.Joints.Count + i;
		}

		return mapping;
	}

	/// Collects non-joint ancestor nodes that should be included in the skeleton.
	/// For each skeleton root bone (whose parent is not a skin joint), walks up the
	/// ancestor chain and collects non-joint nodes. This ensures animated transforms
	/// on these nodes (e.g. root motion) are part of the skeleton hierarchy.
	///
	/// Scene root nodes (ParentIndex < 0) are NOT included - their transforms are
	/// captured via RootCorrection on the topmost included ancestor instead.
	private static void CollectAncestorNodes(Model model, ModelSkin skin, int32[] nodeToSkinJoint, List<int32> outAncestors)
	{
		let seen = scope HashSet<int32>();

		for (int32 skinJointIdx = 0; skinJointIdx < skin.Joints.Count; skinJointIdx++)
		{
			let nodeIdx = skin.Joints[skinJointIdx];
			if (nodeIdx < 0 || nodeIdx >= model.Bones.Count)
				continue;

			let modelBone = model.Bones[nodeIdx];

			// Only process skeleton root bones (parent not in the joint list)
			int32 parentMapping = -1;
			if (modelBone.ParentIndex >= 0 && modelBone.ParentIndex < nodeToSkinJoint.Count)
				parentMapping = nodeToSkinJoint[modelBone.ParentIndex];

			if (parentMapping >= 0 || modelBone.ParentIndex < 0)
				continue; // Parent is already mapped or this is a scene root

			// Walk up ancestor chain, collecting non-joint nodes.
			// Stop before scene root nodes (ParentIndex < 0).
			int32 current = modelBone.ParentIndex;
			while (current >= 0 && current < model.Bones.Count)
			{
				let currentBone = model.Bones[current];

				if (nodeToSkinJoint[current] >= 0)
					break; // Already a skin joint, stop

				if (currentBone.ParentIndex < 0)
					break; // Scene root - keep in RootCorrection, not as a bone

				if (seen.Add(current))
					outAncestors.Add(current);

				current = currentBone.ParentIndex;
			}
		}
	}

	/// Computes RootCorrection matrix for a bone by accumulating static transforms
	/// of all ancestors starting from the given node index up to the scene root.
	/// No explicit axis conversion is needed - loaders (FBX via MODIFY_GEOMETRY,
	/// GLTF which is natively Y-up) deliver transforms already in engine space.
	private static Matrix ComputeRootCorrection(Model model, int32 startNodeIdx)
	{
		Matrix rootCorrection = .Identity;
		int32 current = startNodeIdx;
		while (current >= 0 && current < model.Bones.Count)
		{
			let ancestor = model.Bones[current];
			ancestor.UpdateLocalTransform();
			rootCorrection = rootCorrection * ancestor.LocalTransform;
			current = ancestor.ParentIndex;
		}

		return rootCorrection;
	}
}
