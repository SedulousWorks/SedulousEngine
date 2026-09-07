namespace Sedulous.RHI;

/// One slot of a bindless array to rewrite.
///
/// LayoutIndex picks which bindless binding of the group, and ArrayIndex the slot within
/// it, which is the index a shader will use.
struct BindlessUpdateEntry
{
	public uint32 LayoutIndex = 0;
	public uint32 ArrayIndex = 0;
	public IBuffer Buffer = null;
	public uint64 BufferOffset = 0;
	public uint64 BufferSize = 0;
	public ITextureView TextureView = null;
	public ISampler Sampler = null;

	public this() {}
}
