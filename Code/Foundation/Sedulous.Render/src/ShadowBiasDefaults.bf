namespace Sedulous.Render;

/// The shadow biases a light starts with, in one place: the light component and every renderer
/// read these.
///
/// The normal offset is in shadow TEXELS: the shader pushes a receiver along its normal by
/// this many texels of its cascade (or atlas tile), more as the surface turns from the light.
/// It stays small: the casters' slope scaled hardware bias carries acne, and a large offset
/// parts a shadow from its caster. The depth bias is the receiver's compare bias in NDC depth,
/// toward the light (depth.hlsli).
static class ShadowBiasDefaults
{
	public const float NormalBias = 0.02f;
	/// Directional: the cascades.
	public const float DepthBias = 0.0009f;
	/// Spot and point: the atlas.
	public const float LocalDepthBias = 0.0015f;
}
