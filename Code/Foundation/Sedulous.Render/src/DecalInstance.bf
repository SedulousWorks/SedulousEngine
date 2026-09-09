using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.Render;

/// One screen space projected decal.
///
/// NOT a drawable: it is not dispatched through the renderers at all, but snapshotted into a
/// list the decal pass consumes, the way the lights are. Its transform is an oriented unit
/// box, whose scale is the box's size, and it projects along its own forward axis.
struct DecalInstance
{
	public Float4x4 World = .Identity();
	public Color Color = .(1.0f, 1.0f, 1.0f, 1.0f);

	/// The angle fade, in radians: full opacity until the surface tilts past the start, and
	/// gone once it tilts past the end. Without it a decal smears down every wall it grazes.
	public float FadeStart = 0.0f;
	public float FadeEnd = 1.30f;

	/// BORROWED: the application or the resource keeps it alive.
	public ITextureView Texture = null;

	public this() {}
}
