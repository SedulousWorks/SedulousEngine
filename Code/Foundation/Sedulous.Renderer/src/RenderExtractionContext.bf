namespace Sedulous.Renderer;

using Sedulous.Core.Mathematics;

/// Context passed to IRenderDataProvider during render data extraction.
/// Contains everything a provider needs to decide what to extract and where to put it.
/// Designed to grow as we add culling, LOD, and layer filtering without changing the interface.
struct RenderExtractionContext
{
	/// Shared renderer infrastructure (frame allocator, GPU resources, materials).
	/// Component managers allocate RenderData instances from RenderContext.FrameAllocator.
	public RenderContext RenderContext;

	/// Output container — providers add render data here.
	public ExtractedRenderData RenderData;

	/// View matrix (world -> view space). For sorting key computation.
	public Matrix ViewMatrix;

	/// View-projection matrix. For frustum culling (when implemented).
	public Matrix ViewProjectionMatrix;

	/// Camera world-space position. For LOD selection and distance culling.
	public Vector3 CameraPosition;

	/// Near clip plane distance.
	public float NearPlane;

	/// Far clip plane distance.
	public float FarPlane;

	/// Current frame index for multi-buffering.
	public int32 FrameIndex;

	/// Layer mask for filtering. Objects not matching this mask are skipped.
	/// 0xFFFFFFFF = all layers (default).
	public uint32 LayerMask;

	/// LOD bias. Positive values push to lower detail, negative to higher.
	public float LODBias;

	// Future additions (won't change the interface):
	// - BoundingFrustum ViewFrustum
	// - VisibilitySet (bitfield of visible entity indices, built by spatial culler)
	// - OcclusionQueryResults
}
