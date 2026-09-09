using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Animation;

/// A per bone weight, which is how a layer is confined to part of the skeleton: an upper
/// body layer masks the legs to nothing so the walk underneath keeps them.
class BoneMask
{
	private List<float> mWeights = new .() ~ delete _;

	public this(int32 boneCount, float defaultWeight = 1.0f)
	{
		let count = (boneCount < 0) ? 0 : boneCount;
		mWeights.Count = count;
		for (int i < count)
			mWeights[i] = defaultWeight;
	}

	public int32 BoneCount => (int32)mWeights.Count;

	/// A bone outside the mask weighs NOTHING, so a layer never reaches a bone the mask does
	/// not know about.
	public float GetWeight(int32 boneIndex) =>
		((boneIndex >= 0) && (boneIndex < mWeights.Count)) ? mWeights[boneIndex] : 0.0f;

	public void SetWeight(int32 boneIndex, float weight)
	{
		if ((boneIndex >= 0) && (boneIndex < mWeights.Count))
			mWeights[boneIndex] = Clamp(weight, 0.0f, 1.0f);
	}

	public void SetAll(float weight)
	{
		let clamped = Clamp(weight, 0.0f, 1.0f);
		for (int i < mWeights.Count)
			mWeights[i] = clamped;
	}

	/// A bone and everything below it, which is how a limb is masked by naming its root.
	public void SetBoneChainWeight(Skeleton skeleton, int32 boneIndex, float weight)
	{
		if ((boneIndex < 0) || (boneIndex >= skeleton.BoneCount))
			return;

		let clamped = Clamp(weight, 0.0f, 1.0f);
		SetWeight(boneIndex, clamped);

		let bone = skeleton.GetBone(boneIndex);
		if (bone == null)
			return;
		for (let child in bone.Children)
			SetBoneChainWeight(skeleton, child, clamped);
	}

	public Span<float> Weights => mWeights;
}
