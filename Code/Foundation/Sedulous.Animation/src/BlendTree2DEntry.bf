using Sedulous.Core;

namespace Sedulous.Animation;

/// One clip placed in a two dimensional parameter space.
struct BlendTree2DEntry
{
	public Float2 Position = .(0, 0);
	/// BORROWED.
	public AnimationClip Clip = null;

	public this() {}

	public this(Float2 position, AnimationClip clip)
	{
		Position = position;
		Clip = clip;
	}
}
