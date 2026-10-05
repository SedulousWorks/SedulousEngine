using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Animation;

/// The model space (skeleton space) matrices of a pose: built in full once per evaluation, then
/// rebuilt from a changed bone downward as the modifiers change it, so N chains do not cost N
/// full rebuilds.
class ModelPoseCache
{
	private List<Float4x4> mModel = new .() ~ delete _;
	/// Which bones a partial rebuild has reached, kept to spare an allocation per rebuild.
	private List<bool> mTouched = new .() ~ delete _;
	private uint32 mFullBuilds = 0;

	/// Every bone's model space matrix from the local pose.
	public void Build(Skeleton skeleton, Span<BoneTransform> localPoses)
	{
		mModel.Count = skeleton.BoneCount;
		skeleton.ComputeWorldPoses(localPoses, mModel);
		mFullBuilds++;
	}

	/// `bone` and everything below it, after its local transform changed. Bones above it and
	/// beside it keep their matrices.
	public void RebuildFrom(Skeleton skeleton, Span<BoneTransform> localPoses, int32 bone)
	{
		let count = skeleton.BoneCount;
		if ((bone < 0) || (bone >= count) || (mModel.Count != count))
			return;

		mTouched.Count = count;
		for (int i < count)
			mTouched[i] = false;
		mTouched[bone] = true;
		for (let index in skeleton.HierarchicalOrder)
		{
			let parent = skeleton.GetBone(index).ParentIndex;
			let below = (parent >= 0) && (parent < count) && mTouched[parent];
			if ((index == bone) || below)
			{
				mTouched[index] = true;
				skeleton.ComputeBoneWorldPose(index, localPoses, mModel);
			}
		}
	}

	public Span<Float4x4> Model => mModel;
	public Float4x4 At(int32 bone) => mModel[bone];
	/// Full builds so far: each evaluation with modifiers builds once.
	public uint32 FullBuilds => mFullBuilds;
}

/// A change to a pose between its sampling and its palette (inverse kinematics is the first).
/// `localPoses` is the pose to change, parent relative; `model` holds its model space matrices,
/// current on entry, and the modifier keeps it current (RebuildFrom the highest bone it
/// changed) for the next one.
interface IPoseModifier
{
	void Apply(Skeleton skeleton, Span<BoneTransform> localPoses, ModelPoseCache model);
}

/// A player's modifiers, BORROWED (whoever adds one removes it before it goes), run lowest
/// order first; equal orders keep the order they were added in.
class PoseModifierStack
{
	private struct Entry
	{
		public IPoseModifier Modifier;
		public int32 Order;
	}

	private List<Entry> mEntries = new .() ~ delete _;
	private ModelPoseCache mModel = new .() ~ delete _;

	public void Add(IPoseModifier modifier, int32 order = 0)
	{
		if ((modifier == null) || Contains(modifier))
			return;

		var at = mEntries.Count;
		for (int i < mEntries.Count)
		{
			if (mEntries[i].Order > order)
			{
				at = i;
				break;
			}
		}
		var entry = Entry();
		entry.Modifier = modifier;
		entry.Order = order;
		mEntries.Insert(at, entry);
	}

	public void Remove(IPoseModifier modifier)
	{
		for (int i < mEntries.Count)
		{
			if (mEntries[i].Modifier == modifier)
			{
				mEntries.RemoveAt(i);
				return;
			}
		}
	}

	public bool Contains(IPoseModifier modifier)
	{
		for (let entry in mEntries)
		{
			if (entry.Modifier == modifier)
				return true;
		}
		return false;
	}

	public bool IsEmpty => mEntries.IsEmpty;
	public int Count => mEntries.Count;
	public ModelPoseCache Model => mModel;

	/// Every modifier over `localPoses`, in order, the model space pose built once first.
	public void Apply(Skeleton skeleton, Span<BoneTransform> localPoses)
	{
		if (mEntries.IsEmpty)
			return;

		mModel.Build(skeleton, localPoses);
		for (let entry in mEntries)
			entry.Modifier.Apply(skeleton, localPoses, mModel);
	}
}
