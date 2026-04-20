namespace Sedulous.Renderer;

using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Render data for a projected decal.
///
/// Allocated from RenderContext.FrameAllocator - trivially destructible.
/// Submitted to RenderCategories.Decal. The DecalRenderer draws one cube per
/// entry using the decal's world matrix to place/orient the projection volume.
public class DecalRenderData : RenderData
{
	/// World matrix (positions and orients the decal volume, unit cube at origin).
	public Matrix WorldMatrix;

	/// Inverse world matrix (used in the fragment shader to project scene pixels
	/// into the decal's local [-0.5, 0.5] cube).
	public Matrix InvWorldMatrix;

	/// Decal color tint (RGBA, A = opacity).
	public Vector4 Color;

	/// Angle fade start (radians). Receiver surfaces whose normal deviates from
	/// the decal forward by less than this angle are fully opaque.
	public float AngleFadeStart;

	/// Angle fade end (radians). Beyond this angle the decal is fully faded.
	public float AngleFadeEnd;

	/// Decal material bind group (texture + sampler at set 2). Created by
	/// DecalComponentManager via MaterialSystem.
	public IBindGroup MaterialBindGroup;

	/// Material batch key (typically bind-group pointer cast to uint).
	public uint32 MaterialKey;
}
