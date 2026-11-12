using Sedulous.RHI;

namespace Sedulous.Graphics;

/// How one window presents. The SAME descriptor the main window and every runtime
/// window are configured with, so there is one path rather than a special case.
struct RenderWindowDesc
{
	public TextureFormat Format = .BGRA8UnormSrgb;
	public PresentMode PresentMode = .Fifo;
	public uint32 BufferCount = 2;
	/// Draw the picture turned for a display that presents turned (a phone held away from its
	/// natural orientation), so it has no turning to do: the frame says how (FrameContext.PreRotation)
	/// and whoever draws into the backbuffer must turn its picture. Off, the display turns it. Only a
	/// host that draws everything through the turn asks for it.
	public bool PreRotate = false;

	public this() {}
}
