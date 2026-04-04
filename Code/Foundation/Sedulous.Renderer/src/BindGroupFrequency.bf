namespace Sedulous.Renderer;

/// Bind group frequency levels.
/// Shaders use HLSL register spaces 0-3 matching these indices.
/// The renderer binds each group at the appropriate frequency to minimize GPU state changes.
///
/// Shader convention:
///   space0 = Frame      (VP matrices, time, global lighting)
///   space1 = RenderPass (pass-specific: shadow maps, GBuffer refs)
///   space2 = Material   (textures, material params, samplers)
///   space3 = DrawCall   (world transform, per-instance data)
static class BindGroupFrequency
{
	/// Per-frame data: camera, time, global lighting, IBL, shadow atlas.
	/// Bound once per frame.
	public const int32 Frame = 0;

	/// Per-pass data: pass-specific resources (e.g., cluster grid, GBuffer inputs).
	/// Bound once per render pass.
	public const int32 RenderPass = 1;

	/// Per-material data: textures, material parameters, samplers.
	/// Bound once per material change.
	public const int32 Material = 2;

	/// Per-draw-call data: object transforms, per-instance data.
	/// Bound per draw call (or per instance group with dynamic offsets).
	public const int32 DrawCall = 3;

	/// Total number of bind group frequency levels.
	public const int32 Count = 4;
}
