namespace Sedulous.Animation;

using System;

/// A view into bone transforms and morph weights representing an animation pose.
/// Does not own memory - the backing arrays must outlive this struct.
struct AnimationPose
{
	/// Per-bone local transforms.
	public Span<BoneTransform> BoneTransforms;

	/// Per-morph-target weights (empty until morph target support is added).
	public Span<float> MorphWeights;

	public this(Span<BoneTransform> boneTransforms, Span<float> morphWeights = default)
	{
		BoneTransforms = boneTransforms;
		MorphWeights = morphWeights;
	}

	/// Number of bones in this pose.
	public int BoneCount => BoneTransforms.Length;

	/// Whether this pose has any morph weight data.
	public bool HasMorphWeights => MorphWeights.Length > 0;
}
