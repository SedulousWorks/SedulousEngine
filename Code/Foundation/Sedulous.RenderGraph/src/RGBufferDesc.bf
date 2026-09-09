using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// A transient buffer the graph creates and destroys.
struct RGBufferDesc
{
	public uint64 Size = 0;
	public BufferUsage Usage = .None;

	public this() {}

	public this(uint64 size, BufferUsage usage)
	{
		Size = size;
		Usage = usage;
	}
}
