using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.Render;

/// One textured billboard quad.
///
/// Drawn by the sprite renderer, which SHARES the blended forward pass with transparent
/// meshes so the two interleave by depth rather than one being drawn wholly over the other.
/// Its world position is the base's centre, and the texture is borrowed.
class SpriteRenderData : RenderData
{
	/// In world units.
	public Float2 Size = .(1.0f, 1.0f);
	/// The sub rectangle of an atlas, as an origin and an extent.
	public Float4 UvRect = .(0.0f, 0.0f, 1.0f, 1.0f);
	public Color Tint = .(1.0f, 1.0f, 1.0f, 1.0f);

	/// Nought faces the camera, one turns about the world's up axis, two lies in the world's
	/// horizontal plane, and three takes the axes below.
	public uint32 Orientation = 0;
	/// False composites over, true adds.
	public bool Additive = false;
	/// For the world space UI category: drawn after tone mapping, colours intact.
	public bool PostTonemap = false;

	/// The oriented case's own axes.
	public Float3 AxisRight = .(1.0f, 0.0f, 0.0f);
	public Float3 AxisUp = .(0.0f, 1.0f, 0.0f);

	public ITextureView Texture = null;
}
