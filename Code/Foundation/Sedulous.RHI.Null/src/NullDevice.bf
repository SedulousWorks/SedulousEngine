namespace Sedulous.RHI.Null;

using System;
using System.Collections;

class NullDevice : IDevice
{
	private NullQueue mGraphicsQueue = new .(QueueType.Graphics) ~ delete _;
	private NullQueue mComputeQueue = new .(QueueType.Compute) ~ delete _;
	private NullQueue mTransferQueue = new .(QueueType.Transfer) ~ delete _;
	private NullMeshShaderExt mMeshExt = new .() ~ delete _;
	private NullRayTracingExt mRtExt = new .() ~ delete _;
	private DeviceFeatures mFeatures;

	public this()
	{
		mFeatures = NullAdapter.DefaultFeatures();
	}

	public DeviceFeatures Features => mFeatures;

	// ===== Queues =====

	public IQueue GetQueue(QueueType type, uint32 index = 0)
	{
		switch (type)
		{
		case .Compute:  return mComputeQueue;
		case .Transfer: return mTransferQueue;
		default:        return mGraphicsQueue;
		}
	}

	public uint32 GetQueueCount(QueueType type) => 1;

	// ===== Resource Creation =====

	public Result<IBuffer> CreateBuffer(BufferDesc desc)
	{
		return .Ok(new NullBuffer(desc));
	}

	public Result<ITexture> CreateTexture(TextureDesc desc)
	{
		return .Ok(new NullTexture(desc));
	}

	public Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc)
	{
		return .Ok(new NullTextureView(texture, desc));
	}

	public Result<ISampler> CreateSampler(SamplerDesc desc)
	{
		return .Ok(new NullSampler(desc));
	}

	public Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc)
	{
		return .Ok(new NullShaderModule());
	}

	// ===== Binding =====

	public Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc)
	{
		return .Ok(new NullBindGroupLayout(desc));
	}

	public Result<IBindGroup> CreateBindGroup(BindGroupDesc desc)
	{
		return .Ok(new NullBindGroup(desc.Layout));
	}

	public Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc)
	{
		return .Ok(new NullPipelineLayout());
	}

	// ===== Pipelines =====

	public Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc)
	{
		return .Ok(new NullPipelineCache());
	}

	public Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc)
	{
		return .Ok(new NullRenderPipeline(desc.Layout));
	}

	public Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc)
	{
		return .Ok(new NullComputePipeline(desc.Layout));
	}

	// ===== Commands =====

	public Result<ICommandPool> CreateCommandPool(QueueType queueType)
	{
		return .Ok(new NullCommandPool());
	}

	// ===== Synchronization =====

	public Result<IFence> CreateFence(uint64 initialValue = 0)
	{
		return .Ok(new NullFence(initialValue));
	}

	// ===== Queries =====

	public Result<IQuerySet> CreateQuerySet(QuerySetDesc desc)
	{
		return .Ok(new NullQuerySet(desc));
	}

	// ===== Presentation =====

	public Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc)
	{
		return .Ok(new NullSwapChain(desc));
	}

	// ===== Resource Destruction =====

	public void DestroyBuffer(ref IBuffer buffer)           { delete buffer; buffer = null; }
	public void DestroyTexture(ref ITexture texture)        { delete texture; texture = null; }
	public void DestroyTextureView(ref ITextureView view)   { delete view; view = null; }
	public void DestroySampler(ref ISampler sampler)        { delete sampler; sampler = null; }
	public void DestroyShaderModule(ref IShaderModule module) { delete module; module = null; }
	public void DestroyBindGroupLayout(ref IBindGroupLayout layout) { delete layout; layout = null; }
	public void DestroyBindGroup(ref IBindGroup group)      { delete group; group = null; }
	public void DestroyPipelineLayout(ref IPipelineLayout layout) { delete layout; layout = null; }
	public void DestroyPipelineCache(ref IPipelineCache cache) { delete cache; cache = null; }
	public void DestroyRenderPipeline(ref IRenderPipeline pipeline) { delete pipeline; pipeline = null; }
	public void DestroyComputePipeline(ref IComputePipeline pipeline) { delete pipeline; pipeline = null; }
	public void DestroyCommandPool(ref ICommandPool pool)   { delete pool; pool = null; }
	public void DestroyFence(ref IFence fence)              { delete fence; fence = null; }
	public void DestroyQuerySet(ref IQuerySet querySet)     { delete querySet; querySet = null; }
	public void DestroySwapChain(ref ISwapChain swapChain)  { delete swapChain; swapChain = null; }
	public void DestroySurface(ref ISurface surface)        { delete surface; surface = null; }

	// ===== Extensions =====

	public IMeshShaderExt GetMeshShaderExt() => mMeshExt;
	public IRayTracingExt GetRayTracingExt() => mRtExt;

	// ===== Info =====

	public void WaitIdle() { }
	public void Destroy() { }
}
