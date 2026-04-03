namespace Sedulous.Animation;

using System;

/// Per-bone weight mask for controlling which bones a layer affects.
/// Weight of 1.0 = fully affected, 0.0 = not affected.
class BoneMask
{
	private float[] mWeights ~ delete _;

	/// Creates a bone mask for the given bone count, initialized to the specified default weight.
	public this(int32 boneCount, float defaultWeight = 1.0f)
	{
		mWeights = new float[boneCount];
		for (int i = 0; i < boneCount; i++)
			mWeights[i] = defaultWeight;
	}

	/// Number of bones in this mask.
	public int32 BoneCount => (int32)mWeights.Count;

	/// Gets the weight for a specific bone.
	public float GetWeight(int32 boneIndex)
	{
		if (boneIndex >= 0 && boneIndex < mWeights.Count)
			return mWeights[boneIndex];
		return 0.0f;
	}

	/// Sets the weight for a specific bone.
	public void SetWeight(int32 boneIndex, float weight)
	{
		if (boneIndex >= 0 && boneIndex < mWeights.Count)
			mWeights[boneIndex] = Math.Clamp(weight, 0.0f, 1.0f);
	}

	/// Sets all bone weights to the specified value.
	public void SetAll(float weight)
	{
		let clamped = Math.Clamp(weight, 0.0f, 1.0f);
		for (int i = 0; i < mWeights.Count; i++)
			mWeights[i] = clamped;
	}

	/// Sets the weight for a bone and all its descendants in the skeleton hierarchy.
	public void SetBoneChainWeight(Skeleton skeleton, int32 boneIndex, float weight)
	{
		if (skeleton == null || boneIndex < 0 || boneIndex >= skeleton.BoneCount)
			return;

		let clamped = Math.Clamp(weight, 0.0f, 1.0f);
		SetWeight(boneIndex, clamped);

		let bone = skeleton.GetBone(boneIndex);
		if (bone != null && bone.Children != null)
		{
			for (let childIndex in bone.Children)
				SetBoneChainWeight(skeleton, childIndex, clamped);
		}
	}

	/// Gets the raw weights span for direct access.
	public Span<float> Weights => mWeights;
}
