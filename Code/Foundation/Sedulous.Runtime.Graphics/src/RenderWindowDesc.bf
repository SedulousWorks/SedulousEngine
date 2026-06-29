using Sedulous.RHI;

namespace Sedulous.RuntimeGraphics;

/// Configuration for creating a RenderWindow (surface + swapchain).
struct RenderWindowDesc
{
	/// Pixel format of the swapchain images.
	public TextureFormat Format = .BGRA8Unorm;
	/// Presentation mode (vsync behavior).
	public PresentMode PresentMode = .Fifo;
	/// Number of swapchain back buffers (2 = double buffering, 3 = triple).
	public uint32 BufferCount = 2;
}
