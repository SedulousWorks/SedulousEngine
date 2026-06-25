namespace Sedulous.Engine.App;

using System;
using Sedulous.RHI;

/// GPU backend selection.
public enum BackendType
{
	Vulkan,
	DX12
}

/// How the pipeline output (target-resolution texture) maps onto the
/// swapchain when sizes differ. Only meaningful when TargetWidth /
/// TargetHeight are non-zero (fixed target resolution). When the target
/// follows the window 1:1, all three modes look identical.
public enum FitMode : uint8
{
	/// Fill the swapchain. Aspect ratio of the target is ignored - if
	/// target and swapchain aspects differ the result distorts.
	Stretch,
	/// Preserve aspect ratio, center the target, fill any leftover with
	/// black bars on the over-sized axis.
	Letterbox,
	/// Preserve aspect ratio, fill the swapchain entirely by overshooting
	/// the under-sized axis (content extends past the swapchain edges and
	/// gets clipped).
	Crop
}

/// Settings for an EngineApplication.
struct EngineAppSettings
{
	/// Window title.
	public StringView Title = "Sedulous Engine";

	/// Window width.
	public int32 Width = 1280;

	/// Window height.
	public int32 Height = 720;

	/// Whether the window is resizable.
	public bool Resizable = true;

	/// Target render resolution for the pipeline output. When zero (the
	/// default), the output target tracks the window 1:1 - resizing the
	/// window resizes the render target. When non-zero, the game always
	/// renders at this fixed resolution and the swapchain blit stretches /
	/// letterboxes / crops to the actual window dimensions per FitMode.
	public int32 TargetWidth = 0;

	/// Companion to TargetWidth. Zero means follow the window.
	public int32 TargetHeight = 0;

	/// How a fixed target resolution maps onto a different-sized window
	/// during the swapchain blit. Ignored when target follows the window.
	public FitMode FitMode = .Letterbox;

	/// RHI backend to use.
	public BackendType Backend = .Vulkan;

	/// Whether to enable RHI validation layer.
	public bool EnableValidation = true;

	/// Swap chain format.
	public TextureFormat SwapChainFormat = .BGRA8UnormSrgb;

	/// Presentation mode.
	public PresentMode PresentMode = .Fifo;

	public bool EnableShaderCache = true;
}
