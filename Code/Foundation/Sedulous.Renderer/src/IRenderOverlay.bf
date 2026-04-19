namespace Sedulous.Renderer;

using Sedulous.RHI;

/// Extension point for screen-space overlays rendered after the 3D scene.
/// Registered with RenderSubsystem and called after blit to swapchain,
/// before present. Implementations create their own render pass with
/// LoadOp.Load to preserve the blitted content.
public interface IRenderOverlay
{
	/// Render overlay content onto the swapchain.
	void RenderOverlay(ICommandEncoder encoder, ITextureView targetView,
		uint32 width, uint32 height, int32 frameIndex);
}
