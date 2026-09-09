using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.Render;

/// Everything a SCENE overlay source needs to draw into one view's output.
///
/// Scene tier content is scoped to a scene's rendered output, a heads up display canvas or a
/// billboard: a source registers once, and a shared per view pass calls it with that view's
/// real camera, so the same UI renders wherever the scene renders and projects correctly in
/// each.
struct SceneOverlayView
{
	/// The scene's identity, opaque to the renderer. A source holding per scene state matches
	/// on it.
	public void* SceneKey = null;

	/// The view's UNJITTERED camera, since overlay content must not swim with the temporal
	/// jitter the scene pass uses.
	public Float4x4 ViewProjection = .Identity();
	public Float3 CameraPosition = .(0, 0, 0);

	/// The view's sub rectangle within the target.
	public int32 ViewportX = 0;
	public int32 ViewportY = 0;
	public uint32 ViewportWidth = 0;
	public uint32 ViewportHeight = 0;

	/// The whole target's extent, in pixels.
	public uint32 TargetWidth = 0;
	public uint32 TargetHeight = 0;

	public TextureFormat TargetFormat = .BGRA8Unorm;

	/// The pass's depth stencil format, or undefined for a colour only pass. A source may
	/// record stencil work only when this is set AND matches what its own pipelines were
	/// built against.
	public TextureFormat DepthStencilFormat = .Undefined;

	public uint32 FrameIndex = 0;

	public this() {}
}
