using System;

namespace Sedulous.RHI;

struct BufferDesc
{
	public uint64 Size = 0;
	public BufferUsage Usage = .None;
	public MemoryLocation Memory = .GpuOnly;
	public StringView Label = default;

	public this() {}
}
