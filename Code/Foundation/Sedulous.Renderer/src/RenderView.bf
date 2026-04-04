namespace Sedulous.Renderer;

using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Everything needed to render one view: camera, viewport, output target, frame state, and extracted data.
/// Multiple views can exist per frame (main camera, shadow cascades, reflection probes).
/// The pipeline renders one view at a time.
class RenderView
{
	// ==================== Camera ====================

	/// View matrix (world → view space).
	public Matrix ViewMatrix;

	/// Projection matrix (view → clip space).
	public Matrix ProjectionMatrix;

	/// Combined view-projection matrix.
	public Matrix ViewProjectionMatrix;

	/// Camera world-space position.
	public Vector3 CameraPosition;

	/// Near clip plane distance.
	public float NearPlane = 0.1f;

	/// Far clip plane distance.
	public float FarPlane = 1000.0f;

	// ==================== Viewport ====================

	/// Viewport width in pixels.
	public uint32 Width;

	/// Viewport height in pixels.
	public uint32 Height;

	/// Viewport X offset (for split-screen or atlas rendering).
	public uint32 ViewportX;

	/// Viewport Y offset.
	public uint32 ViewportY;

	// ==================== Output ====================

	/// The render target to output to (swapchain backbuffer or offscreen target).
	public ITextureView OutputTarget;

	// ==================== Frame State ====================

	/// Current frame index for multi-buffering (0 or 1 for double buffering).
	public int32 FrameIndex;

	/// Time since last frame in seconds.
	public float DeltaTime;

	/// Total elapsed time in seconds.
	public float TotalTime;

	// ==================== Render Data ====================

	/// The extracted render data for this view (meshes, lights, decals, etc.).
	/// Populated by the engine layer during extraction, consumed by pipeline passes.
	public ExtractedRenderData RenderData;
}
