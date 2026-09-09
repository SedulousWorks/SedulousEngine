using Sedulous.RHI;

namespace Sedulous.Render;

/// Everything a SCREEN overlay source needs to draw into one window target.
///
/// Screen tier content is window space chrome: screen UI, profiler displays, editor overlays.
/// The host makes one call per window target after the scene composed.
struct ScreenOverlayView
{
	public uint32 Width = 0;
	public uint32 Height = 0;
	public TextureFormat TargetFormat = .BGRA8Unorm;
	/// The same contract as the scene tier's: set only when the pass carries one.
	public TextureFormat DepthStencilFormat = .Undefined;
	public uint32 FrameIndex = 0;

	public this() {}
}
