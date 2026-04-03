namespace Sedulous.RHI.Null;

using System;
using System.Collections;

class NullBuffer : IBuffer
{
	private BufferDesc mDesc;
	private uint8* mMappedData;

	public this(BufferDesc desc)
	{
		mDesc = desc;
		// Allocate backing memory for mappable buffers
		if (desc.Memory == .CpuToGpu || desc.Memory == .GpuToCpu)
			mMappedData = new uint8[(int)desc.Size]*;
	}

	public ~this()
	{
		if (mMappedData != null)
			delete mMappedData;
	}

	public BufferDesc Desc => mDesc;
	public uint64 Size => mDesc.Size;
	public BufferUsage Usage => mDesc.Usage;

	public void* Map()
	{
		return mMappedData;
	}

	public void Unmap() { }
}

class NullTexture : ITexture
{
	private TextureDesc mDesc;
	public this(TextureDesc desc) { mDesc = desc; }
	public TextureDesc Desc => mDesc;
	public ResourceState InitialState => .Undefined;
}

class NullTextureView : ITextureView
{
	private TextureViewDesc mDesc;
	private ITexture mTexture;

	public this(ITexture texture, TextureViewDesc desc)
	{
		mTexture = texture;
		mDesc = desc;
	}

	public TextureViewDesc Desc => mDesc;
	public ITexture Texture => mTexture;
}

class NullSampler : ISampler
{
	private SamplerDesc mDesc;
	public this(SamplerDesc desc) { mDesc = desc; }
	public SamplerDesc Desc => mDesc;
}

class NullShaderModule : IShaderModule
{
}

class NullBindGroupLayout : IBindGroupLayout
{
	private List<BindGroupLayoutEntry> mEntries = new .() ~ delete _;

	public this(BindGroupLayoutDesc desc)
	{
		for (let entry in desc.Entries)
			mEntries.Add(entry);
	}

	public List<BindGroupLayoutEntry> Entries => mEntries;
}

class NullBindGroup : IBindGroup
{
	private IBindGroupLayout mLayout;

	public this(IBindGroupLayout layout) { mLayout = layout; }

	public IBindGroupLayout Layout => mLayout;
	public void UpdateBindless(Span<BindlessUpdateEntry> entries) { }
}

class NullPipelineLayout : IPipelineLayout
{
}

class NullPipelineCache : IPipelineCache
{
	public uint GetDataSize() => 0;
	public Result<int> GetData(Span<uint8> outData) => .Ok(0);
}

class NullRenderPipeline : IRenderPipeline
{
	private IPipelineLayout mLayout;
	public this(IPipelineLayout layout) { mLayout = layout; }
	public IPipelineLayout Layout => mLayout;
}

class NullComputePipeline : IComputePipeline
{
	private IPipelineLayout mLayout;
	public this(IPipelineLayout layout) { mLayout = layout; }
	public IPipelineLayout Layout => mLayout;
}

class NullFence : IFence
{
	private uint64 mValue;

	public this(uint64 initialValue) { mValue = initialValue; }

	public uint64 CompletedValue => mValue;

	public bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue)
	{
		return mValue >= value;
	}

	public void Signal(uint64 value)
	{
		if (value > mValue)
			mValue = value;
	}
}

class NullQuerySet : IQuerySet
{
	private QuerySetDesc mDesc;
	public this(QuerySetDesc desc) { mDesc = desc; }
	public QueryType Type => mDesc.Type;
	public uint32 Count => mDesc.Count;
}
