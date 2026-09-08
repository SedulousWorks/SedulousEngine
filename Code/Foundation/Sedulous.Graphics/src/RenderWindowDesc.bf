using Sedulous.RHI;

namespace Sedulous.Graphics;

/// How one window presents. The SAME descriptor the main window and every runtime
/// window are configured with, so there is one path rather than a special case.
struct RenderWindowDesc
{
	public TextureFormat Format = .BGRA8UnormSrgb;
	public PresentMode PresentMode = .Fifo;
	public uint32 BufferCount = 2;

	public this() {}
}
