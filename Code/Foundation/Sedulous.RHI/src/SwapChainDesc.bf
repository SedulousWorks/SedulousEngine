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
	public StringView Label = default;

	public this() {}
}
