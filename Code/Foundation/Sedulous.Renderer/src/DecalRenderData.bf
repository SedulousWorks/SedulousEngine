namespace Sedulous.Renderer;

using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Render data for a projected decal.
///
/// Allocated from RenderContext.FrameAllocator — trivially destructible.
public class DecalRenderData : RenderData
{
	/// World matrix (positions and orients the decal volume).
	public Matrix WorldMatrix;

	/// Inverse world matrix (for projection in fragment shader).
	public Matrix InvWorldMatrix;

	/// Decal color tint (RGBA, A = opacity).
	public Vector4 Color;

	/// Angle fade start (radians).
	public float AngleFadeStart;

	/// Angle fade end (radians).
	public float AngleFadeEnd;

	/// Albedo texture view.
	public ITextureView AlbedoTexture;

	/// Sampler.
	public ISampler Sampler;
}
