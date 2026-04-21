namespace Sedulous.Engine.Renderer;

using Sedulous.RHI;

/// Renders a screen-space overlay onto a provided target.
/// Multiple subsystems can implement this (screen UI, debug HUD, profiler).
/// Application queries all via Context.GetSubsystemsByInterface<IOverlayRenderer>(),
/// sorts by OverlayOrder, and calls each with LoadOp.Load to composite.
interface IOverlayRenderer
{
	/// Sort order for overlay rendering. Lower values render first.
	int32 OverlayOrder { get; }

	/// Render the overlay onto the target. The target already has content
	/// (blitted scene) - use LoadOp.Load to preserve it.
	void RenderOverlay(ICommandEncoder encoder, ITextureView target,
		uint32 w, uint32 h, int32 frameIndex);
}
