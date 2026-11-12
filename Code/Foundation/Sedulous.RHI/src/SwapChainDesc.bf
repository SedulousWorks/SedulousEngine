using System;

namespace Sedulous.RHI;

struct SwapChainDesc
{
	public uint32 Width = 0;
	public uint32 Height = 0;
	public TextureFormat Format = .BGRA8UnormSrgb;
	/// Fifo, being the one mode every backend must support.
	public PresentMode PresentMode = .Fifo;
	public uint32 BufferCount = 2;
	/// The back buffers' sRGB or UNORM twin, to be viewable in as well (TextureDesc's
	/// AlternateViewFormat). A request, not a guarantee: ISwapChain.AlternateViewFormat says
	/// whether the device and surface honoured it.
	public TextureFormat AlternateViewFormat = .Undefined;
	/// Draw the picture turned for the display (pre-rotation): on a surface that presents turned
	/// (a phone held away from its natural orientation), the back buffers are made in the display's
	/// own orientation and the caller draws the window's picture turned into them
	/// (ISwapChain.PreRotation), so the display has no turning to do. Off, the caller draws the
	/// window as it stands and the display turns it. A request: a surface that cannot keeps
	/// PreRotation at None. Width and Height stay the window's.
	public bool PreRotate = false;
	public StringView Label = default;

	public this() {}
}
