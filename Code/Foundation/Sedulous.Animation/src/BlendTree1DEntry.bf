namespace Sedulous.Animation;

/// One clip on a blend tree's axis, at the parameter value it plays purely at.
struct BlendTree1DEntry
{
	public float Threshold = 0.0f;
	/// BORROWED.
	public AnimationClip Clip = null;

	public this() {}

	public this(float threshold, AnimationClip clip)
	{
		Threshold = threshold;
		Clip = clip;
	}
}
