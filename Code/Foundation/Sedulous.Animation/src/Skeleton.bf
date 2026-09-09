using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Animation;

/// The skeletal hierarchy: the bones, and the matrices a pose turns into.
///
/// Everything is evaluated PARENTS BEFORE CHILDREN, off an order built once, so a world pose
/// reads its parent's answer rather than recomputing the chain above it for every bone.
class Skeleton
{
	private String mName = new .() ~ delete _;
	private List<Bone> mBones = new .() ~ DeleteContainerAndItems!(_);
	private List<int32> mRootBones = new .() ~ delete _;
	private List<int32> mHierarchicalOrder = new .() ~ delete _;
	private Dictionary<String, int32> mNameMap = new .() ~ delete _;

	/// Reused across skinning calls, which is the hot path: a scene's worth of skeletons
	/// evaluating every frame must not allocate to do it.
	private List<Float4x4> mWorldScratch = new .() ~ delete _;

	public this() {}

	/// A skeleton of default bones with sequential indices, which the loader then fills.
	public this(int32 boneCount)
	{
		Resize(boneCount);
	}

	public int32 BoneCount => (int32)mBones.Count;
	public List<Bone> Bones => mBones;
	public Span<int32> RootBones => mRootBones;
	public String Name => mName;

	/// Repopulates THIS instance rather than answering a new one, so a hot reload keeps
	/// every reference to the skeleton valid.
	public void ClearForReload(int32 boneCount)
	{
		ClearAndDeleteItems!(mBones);
		mRootBones.Clear();
		mHierarchicalOrder.Clear();
		mNameMap.Clear();
		mName.Clear();
		Resize(boneCount);
	}

	private void Resize(int32 boneCount)
	{
		let count = (boneCount < 0) ? 0 : boneCount;
		for (int32 i = 0; i < count; i++)
		{
			let bone = new Bone();
			bone.Index = i;
			mBones.Add(bone);
		}
	}

	/// A bone's index by name, or minus one. Needs BuildNameMap first.
	public int32 FindBone(StringView name)
	{
		// The key is the bone's OWN string, so the lookup needs one to compare against and
		// not a copy to own.
		let key = scope String(name);
		if (mNameMap.TryGetValue(key, let index))
			return index;
		return -1;
	}

	public Bone GetBone(int32 index) => InBounds(index) ? mBones[index] : null;

	/// Builds the name lookup. After every bone and its name is set.
	public void BuildNameMap()
	{
		mNameMap.Clear();
		for (let bone in mBones)
		{
			if (!bone.Name.IsEmpty)
				mNameMap[bone.Name] = bone.Index;
		}
	}

	/// Caches which bones are roots. After the parents are set.
	public void FindRootBones()
	{
		mRootBones.Clear();
		for (let bone in mBones)
		{
			if (bone.ParentIndex < 0)
				mRootBones.Add(bone.Index);
		}
	}

	/// Builds each bone's child list and the evaluation order. After the parents are set,
	/// and after the roots are found, or the order has nowhere to start.
	public void BuildChildIndices()
	{
		for (let bone in mBones)
			bone.Children.Clear();

		for (let bone in mBones)
		{
			if ((bone.ParentIndex >= 0) && InBounds(bone.ParentIndex))
				mBones[bone.ParentIndex].Children.Add(bone.Index);
		}

		BuildHierarchicalOrder();
	}

	/// The inverse of each bone's world BIND pose. After the local bind poses and the parents
	/// are set.
	public void ComputeInverseBindPoses()
	{
		let count = mBones.Count;
		mWorldScratch.Count = count;
		// An empty pose means the bind pose, which is exactly what is being inverted.
		ComputeWorldPoses(default, mWorldScratch);
		for (int i = 0; i < count; i++)
			mBones[i].InverseBindPose = Inverse(mWorldScratch[i]);
	}

	/// World space matrices from local transforms, parents first. An EMPTY set of local poses
	/// is the bind pose.
	public void ComputeWorldPoses(Span<BoneTransform> localPoses, Span<Float4x4> outWorldPoses)
	{
		if (!mHierarchicalOrder.IsEmpty)
		{
			for (let boneIndex in mHierarchicalOrder)
				ComputeBoneWorldPose(boneIndex, localPoses, outWorldPoses);
		}
		else
		{
			// No order built yet, so index order it is: correct only when the parents happen
			// to come first, which is how most exporters write them anyway.
			for (int32 i = 0; i < BoneCount; i++)
				ComputeBoneWorldPose(i, localPoses, outWorldPoses);
		}
	}

	/// The skinning matrices: the inverse bind pose then the world pose.
	///
	/// In that order because the convention is row vector, so a vertex reads left to right:
	/// vertex times inverse bind takes it into bone space, and times world puts it back.
	public void ComputeSkinningMatrices(Span<BoneTransform> localPoses,
		Span<Float4x4> outSkinningMatrices)
	{
		let count = mBones.Count;
		mWorldScratch.Count = count;
		ComputeWorldPoses(localPoses, mWorldScratch);

		for (int i = 0; i < count; i++)
		{
			if (i < outSkinningMatrices.Length)
				outSkinningMatrices[i] = mBones[i].InverseBindPose * mWorldScratch[i];
		}
	}

	private bool InBounds(int32 index) => (index >= 0) && (index < mBones.Count);

	private void ComputeBoneWorldPose(int32 boneIndex, Span<BoneTransform> localPoses,
		Span<Float4x4> outWorldPoses)
	{
		if (!InBounds(boneIndex) || (boneIndex >= outWorldPoses.Length))
			return;

		let bone = mBones[boneIndex];
		// A pose shorter than the skeleton leaves the rest at their bind pose rather than at
		// nothing, so a partial pose is still a skeleton.
		let local = (boneIndex < localPoses.Length) ? localPoses[boneIndex] : bone.LocalBindPose;
		let localMatrix = local.ToMatrix();

		if ((bone.ParentIndex >= 0) && InBounds(bone.ParentIndex)
			&& (bone.ParentIndex < outWorldPoses.Length))
			outWorldPoses[boneIndex] = localMatrix * outWorldPoses[bone.ParentIndex];
		else
			outWorldPoses[boneIndex] = localMatrix * bone.RootCorrection;
	}

	/// Breadth first from the roots, so a parent always precedes its children.
	///
	/// A bone no root reaches is APPENDED rather than dropped: a broken hierarchy still poses
	/// every bone it has, in whatever order is left.
	private void BuildHierarchicalOrder()
	{
		mHierarchicalOrder.Clear();

		let queue = scope List<int32>();
		queue.AddRange(mRootBones);

		var head = 0;
		while (head < queue.Count)
		{
			let boneIndex = queue[head++];
			mHierarchicalOrder.Add(boneIndex);
			if (InBounds(boneIndex))
				queue.AddRange(mBones[boneIndex].Children);
		}

		if (mHierarchicalOrder.Count < mBones.Count)
		{
			let ordered = scope bool[mBones.Count];
			for (let index in mHierarchicalOrder)
			{
				if (InBounds(index))
					ordered[index] = true;
			}
			for (int32 i = 0; i < mBones.Count; i++)
			{
				if (!ordered[i])
					mHierarchicalOrder.Add(i);
			}
		}
	}
}
