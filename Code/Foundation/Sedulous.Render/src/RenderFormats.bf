using Sedulous.RHI;

namespace Sedulous.Render;

/// The formats of the forward pass's auxiliary targets, shared by the pipeline configuration
/// and the transient declarations so the two cannot disagree.
static class RenderFormats
{
	/// The view space normal, octahedrally encoded into two channels.
	public const TextureFormat GNormal = .RG16Float;
	/// The screen space motion vector, as a change in texture coordinates.
	public const TextureFormat GVelocity = .RG16Float;
	/// Roughness and metallic, both within zero to one, which the reflections read: roughness
	/// gates and fades them, and metallic tints them. Written only by the opaque permutation,
	/// like the other two.
	public const TextureFormat GMaterial = .RG8Unorm;
}
