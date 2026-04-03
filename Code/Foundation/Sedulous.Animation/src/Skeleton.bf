namespace Sedulous.Animation;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Represents a skeletal hierarchy used for animation.
public class Skeleton
{
	/// Optional name (for debugging/import).
	public String Name = new .() ~ delete _;

	/// All bones in the skeleton, indexed by bone index.
	public Bone[] Bones ~ DeleteContainerAndItems!(_);

	/// Root bone indices (bones with no parent).
	public int32[] RootBones ~ delete _;

	/// Map from bone name to bone index for fast lookup.
	private Dictionary<StringView, int32> mBoneNameMap = new .() ~ delete _;

	/// Bone indices in hierarchical order (parents before children).
	/// Used for correct world pose computation.
	private int32[] mHierarchicalOrder ~ delete _;

	/// Creates an empty skeleton.
	public this()
	{
		Bones = new .[0];
		RootBones = new .[0];
	}

	/// Creates a skeleton with the specified number of bones.
	public this(int32 boneCount)
	{
		Bones = new .[boneCount];
		for (int i = 0; i < boneCount; i++)
			Bones[i] = new Bone();
	}

	/// Gets the number of bones in this skeleton.
	public int32 BoneCount => (int32)Bones.Count;

	/// Finds a bone by name.
	/// Returns the bone index, or -1 if not found.
	public int32 FindBone(StringView name)
	{
		if (mBoneNameMap.TryGetValue(name, let index))
			return index;
		return -1;
	}

	/// Gets a bone by index.
	public Bone GetBone(int32 index)
	{
		if (index >= 0 && index < Bones.Count)
			return Bones[index];
		return null;
	}

	/// Builds the bone name lookup map.
	/// Call this after setting up all bones.
	public void BuildNameMap()
	{
		mBoneNameMap.Clear();
		for (let bone in Bones)
		{
			if (bone != null && bone.Name != null)
				mBoneNameMap[bone.Name] = bone.Index;
		}
	}

	/// Finds and caches root bones (bones with no parent).
	/// Call this after setting up all bone parent relationships.
	public void FindRootBones()
	{
		List<int32> roots = scope .();
		for (let bone in Bones)
		{
			if (bone != null && bone.ParentIndex < 0)
				roots.Add(bone.Index);
		}

		delete RootBones;
		RootBones = new int32[roots.Count];
		roots.CopyTo(RootBones);
	}

	/// Builds child bone indices for each bone.
	/// Call this after setting up all bone parent relationships.
	public void BuildChildIndices()
	{
		// Count children for each bone
		int32[] childCounts = scope int32[Bones.Count];
		for (let bone in Bones)
		{
			if (bone != null && bone.ParentIndex >= 0)
				childCounts[bone.ParentIndex]++;
		}

		// Allocate child arrays
		for (int i = 0; i < Bones.Count; i++)
		{
			if (Bones[i] != null)
			{
				delete Bones[i].Children;
				Bones[i].Children = new int32[childCounts[i]];
			}
		}

		// Fill child arrays
		int32[] childIndices = scope int32[Bones.Count];
		for (let bone in Bones)
		{
			if (bone != null && bone.ParentIndex >= 0)
			{
				let parent = Bones[bone.ParentIndex];
				parent.Children[childIndices[bone.ParentIndex]++] = bone.Index;
			}
		}

		// Build hierarchical processing order
		BuildHierarchicalOrder();
	}

	/// Builds the hierarchical order array (parents before children).
	private void BuildHierarchicalOrder()
	{
		delete mHierarchicalOrder;
		mHierarchicalOrder = new int32[Bones.Count];

		int32 orderIndex = 0;
		List<int32> queue = scope .();

		// Start with root bones
		for (let rootIndex in RootBones)
			queue.Add(rootIndex);

		// BFS to ensure all parents are processed before their children
		while (queue.Count > 0)
		{
			let boneIndex = queue.PopFront();
			mHierarchicalOrder[orderIndex++] = boneIndex;

			let bone = Bones[boneIndex];
			if (bone != null && bone.Children != null)
			{
				for (let childIndex in bone.Children)
					queue.Add(childIndex);
			}
		}

		// Handle any orphan bones not connected to root
		if (orderIndex < Bones.Count)
		{
			for (int32 i = 0; i < Bones.Count; i++)
			{
				bool found = false;
				for (int j = 0; j < orderIndex; j++)
				{
					if (mHierarchicalOrder[j] == i)
					{
						found = true;
						break;
					}
				}
				if (!found)
					mHierarchicalOrder[orderIndex++] = i;
			}
		}
	}

	/// Computes the inverse bind pose matrices for all bones.
	/// Call this after setting up all local bind poses and parent relationships.
	public void ComputeInverseBindPoses()
	{
		// First compute world bind poses
		Matrix[] worldPoses = scope Matrix[Bones.Count];
		ComputeWorldPoses(scope BoneTransform[Bones.Count], worldPoses);

		// Then invert them
		for (int i = 0; i < Bones.Count; i++)
		{
			if (Bones[i] != null)
			{
				Matrix inverted;
				Matrix.Invert(worldPoses[i], out inverted);
				Bones[i].InverseBindPose = inverted;
			}
		}
	}

	/// Computes world-space bone matrices from local transforms.
	/// @param localPoses Local transforms for each bone (or null to use bind pose).
	/// @param outWorldPoses Output array for world-space matrices.
	public void ComputeWorldPoses(Span<BoneTransform> localPoses, Span<Matrix> outWorldPoses)
	{
		// Process bones in hierarchical order (parents before children)
		// This ensures parent world poses are computed before they're needed by children
		if (mHierarchicalOrder != null)
		{
			for (let boneIndex in mHierarchicalOrder)
			{
				ComputeBoneWorldPose(boneIndex, localPoses, outWorldPoses);
			}
		}
		else
		{
			// Fallback to sequential order if hierarchy not built
			for (int32 i = 0; i < Bones.Count; i++)
			{
				ComputeBoneWorldPose(i, localPoses, outWorldPoses);
			}
		}
	}

	/// Computes the world pose for a single bone.
	private void ComputeBoneWorldPose(int32 boneIndex, Span<BoneTransform> localPoses, Span<Matrix> outWorldPoses)
	{
		let bone = Bones[boneIndex];
		if (bone == null)
		{
			outWorldPoses[boneIndex] = .Identity;
			return;
		}

		// Get local transform (from animation or bind pose)
		BoneTransform localTransform;
		if (localPoses.Length > boneIndex)
			localTransform = localPoses[boneIndex];
		else
			localTransform = bone.LocalBindPose;

		let localMatrix = localTransform.ToMatrix();

		if (bone.ParentIndex >= 0 && bone.ParentIndex < Bones.Count)
		{
			// Concatenate with parent's world matrix (parent must already be computed)
			outWorldPoses[boneIndex] = localMatrix * outWorldPoses[bone.ParentIndex];
		}
		else
		{
			// Root bone - apply RootCorrection to include missing ancestor transforms
			// (e.g. FBX coordinate conversion from Z-up to Y-up)
			outWorldPoses[boneIndex] = localMatrix * bone.RootCorrection;
		}
	}

	/// Computes final skinning matrices (world pose * inverse bind pose).
	/// @param localPoses Local transforms for each bone.
	/// @param outSkinningMatrices Output array for skinning matrices.
	public void ComputeSkinningMatrices(Span<BoneTransform> localPoses, Span<Matrix> outSkinningMatrices)
	{
		// First compute world poses
		Matrix[] worldPoses = scope Matrix[Bones.Count];
		ComputeWorldPoses(localPoses, worldPoses);

		// Then multiply by inverse bind pose
		for (int i = 0; i < Bones.Count; i++)
		{
			if (Bones[i] != null)
				outSkinningMatrices[i] = Bones[i].InverseBindPose * worldPoses[i];
			else
				outSkinningMatrices[i] = .Identity;
		}
	}
}
