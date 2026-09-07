namespace Sedulous.RHI;

/// One resource filled into a bind group slot.
///
/// A flat struct with a field per kind rather than a union, so building one is a plain
/// assignment and the factories below say which kind was meant.
struct BindGroupEntry
{
	public IBuffer Buffer = null;
	public uint64 BufferOffset = 0;
	public uint64 BufferSize = 0;
	public ITextureView TextureView = null;
	public ISampler Sampler = null;
	public IAccelStruct AccelStruct = null;

	public this() {}

	public static BindGroupEntry BufferEntry(IBuffer buffer, uint64 offset, uint64 size)
	{
		var e = BindGroupEntry();
		e.Buffer = buffer;
		e.BufferOffset = offset;
		e.BufferSize = size;
		return e;
	}

	public static BindGroupEntry TextureEntry(ITextureView view)
	{
		var e = BindGroupEntry();
		e.TextureView = view;
		return e;
	}

	public static BindGroupEntry SamplerEntry(ISampler sampler)
	{
		var e = BindGroupEntry();
		e.Sampler = sampler;
		return e;
	}

	public static BindGroupEntry AccelStructEntry(IAccelStruct accelStruct)
	{
		var e = BindGroupEntry();
		e.AccelStruct = accelStruct;
		return e;
	}
}
