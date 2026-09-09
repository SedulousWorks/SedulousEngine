using System;
using Sedulous.Core;

namespace Sedulous.Animation;

/// One evaluated pose: a NON OWNING view over per bone local transforms, and the morph
/// weights beside them.
///
/// The arrays it points at must outlive it. A pose is passed down an evaluation chain many
/// times per frame, and copying the bones at each step would be the most expensive thing in
/// the graph.
struct AnimationPose
{
	public Span<BoneTransform> BoneTransforms = default;
	/// Per morph target. Empty until a clip carries any.
	public Span<float> MorphWeights = default;

	public this() {}

	public this(Span<BoneTransform> bones)
	{
		BoneTransforms = bones;
	}

	public this(Span<BoneTransform> bones, Span<float> morphs)
	{
		BoneTransforms = bones;
		MorphWeights = morphs;
	}

	public int BoneCount => BoneTransforms.Length;
	public bool HasMorphWeights => MorphWeights.Length > 0;
}
