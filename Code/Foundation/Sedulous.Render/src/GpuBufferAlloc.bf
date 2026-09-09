using Sedulous.RHI;

namespace Sedulous.Render;

/// A sub allocation out of a pooled buffer: which buffer, and where in it.
struct GpuBufferAlloc
{
	public IBuffer Buffer = null;
	public uint64 Offset = 0;
	public bool Ok = false;

	public this() {}

	public this(IBuffer buffer, uint64 offset)
	{
		Buffer = buffer;
		Offset = offset;
		Ok = true;
	}
}
