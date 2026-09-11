using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// A device that creates real objects holding no GPU state.
///
/// Everything it hands out is heap allocated and freed through the matching Destroy, so a
/// headless test exercises the same create and destroy pairing a real backend needs and a
/// leak shows up as a leak.
class NullDevice : IDevice
{
	private NullQueue mGraphicsQueue = new .() ~ delete _;
	private NullQueue mComputeQueue = new .() ~ delete _;
	private NullQueue mTransferQueue = new .() ~ delete _;

	public this()
	{
		mGraphicsQueue.Initialize(.Graphics);
		mComputeQueue.Initialize(.Compute);
		mTransferQueue.Initialize(.Transfer);
	}

	public DeviceType Type => .Null;
	public DeviceFeatures Features { get; set; } = .();

	/// SPIR-V, matching Vulkan, so a cooked shader set built for the null backend is the
	/// one Vulkan would take.
	public ShaderFormat PreferredShaderFormat => .SpirV;

	/// False: there is no viewport to flip, and reporting true would make every screen
	/// space reconstruction test negate a Y it did not need to.
	public bool NeedsClipSpaceYFlip => false;

	public IQueue GetQueue(QueueType type, uint32 index)
	{
		switch (type)
		{
		case .Graphics: return mGraphicsQueue;
		case .Compute: return mComputeQueue;
		case .Transfer: return mTransferQueue;
		}
	}

	public uint32 GetQueueCount(QueueType type) => 1;

	/// Claims the uses a render target needs, and nothing more. Not everything: a caller
	/// asking whether a format can be a storage image should get an honest no rather than a
	/// yes it cannot rely on.
	public FormatSupport GetFormatSupport(TextureFormat format)
		=> .Texture | .ColorAttachment | .DepthStencil;

	// ---- creation ----

	public Result<IBuffer> CreateBuffer(BufferDesc desc)
	{
		let buffer = new NullBuffer();
		buffer.Initialize(desc);
		return .Ok(buffer);
	}

	public Result<ITexture> CreateTexture(TextureDesc desc)
	{
		let texture = new NullTexture();
		texture.Initialize(desc);
		return .Ok(texture);
	}

	public Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc)
	{
		let view = new NullTextureView();
		view.Initialize(texture, desc);
		return .Ok(view);
	}

	public Result<ISampler> CreateSampler(SamplerDesc desc)
	{
		let sampler = new NullSampler();
		sampler.Initialize(desc);
		return .Ok(sampler);
	}

	public Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc)
		=> .Ok(new NullShaderModule());

	public Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc)
		=> .Ok(new NullBindGroupLayout());

	public Result<IBindGroup> CreateBindGroup(BindGroupDesc desc)
		=> .Ok(new NullBindGroup());

	public Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc)
		=> .Ok(new NullPipelineLayout());

	public Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc)
		=> .Ok(new NullPipelineCache());

	public Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc)
	{
		let pipeline = new NullRenderPipeline();
		pipeline.Layout = desc.Layout;
		return .Ok(pipeline);
	}

	public Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc)
	{
		let pipeline = new NullComputePipeline();
		pipeline.Layout = desc.Layout;
		return .Ok(pipeline);
	}

	public Result<ICommandPool> CreateCommandPool(QueueType queueType)
		=> .Ok(new NullCommandPool());

	public Result<IFence> CreateFence(uint64 initialValue)
	{
		let fence = new NullFence();
		fence.Signal(initialValue);
		return .Ok(fence);
	}

	public Result<IQuerySet> CreateQuerySet(QuerySetDesc desc)
	{
		let querySet = new NullQuerySet();
		querySet.Initialize(desc);
		return .Ok(querySet);
	}

	public Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc)
	{
		let swapChain = new NullSwapChain();
		swapChain.Initialize(desc);
		return .Ok(swapChain);
	}

	// ---- destruction ----
	//
	// Each nulls the caller's handle as well as freeing, so a stale variable cannot be
	// used again.

	public void DestroyBuffer(ref IBuffer buffer) { delete buffer; buffer = null; }
	public void DestroyTexture(ref ITexture texture) { delete texture; texture = null; }
	public void DestroyTextureView(ref ITextureView view) { delete view; view = null; }
	public void DestroySampler(ref ISampler sampler) { delete sampler; sampler = null; }
	public void DestroyShaderModule(ref IShaderModule module) { delete module; module = null; }
	public void DestroyBindGroupLayout(ref IBindGroupLayout layout) { delete layout; layout = null; }
	public void DestroyBindGroup(ref IBindGroup group) { delete group; group = null; }
	public void DestroyPipelineLayout(ref IPipelineLayout layout) { delete layout; layout = null; }
	public void DestroyPipelineCache(ref IPipelineCache cache) { delete cache; cache = null; }
	public void DestroyRenderPipeline(ref IRenderPipeline pipeline) { delete pipeline; pipeline = null; }
	public void DestroyComputePipeline(ref IComputePipeline pipeline) { delete pipeline; pipeline = null; }
	public void DestroyCommandPool(ref ICommandPool pool) { delete pool; pool = null; }
	public void DestroyFence(ref IFence fence) { delete fence; fence = null; }
	public void DestroyQuerySet(ref IQuerySet querySet) { delete querySet; querySet = null; }
	public void DestroySwapChain(ref ISwapChain swapChain) { delete swapChain; swapChain = null; }
	/// A NO-OP, as in Vulkan: the BACKEND owns its surfaces and frees them with itself, so
	/// deleting one here leaves a stale pointer in its list to free a second time. It went
	/// unnoticed while the backend object was itself leaked and its destructor never ran.
	public void DestroySurface(ref ISurface surface) { surface = null; }

	// ---- extensions ----
	//
	// The null backend SUPPORTS these, unlike the interface defaults that refuse. A stub
	// exists so a mesh shader or ray tracing path can be exercised where no hardware does
	// it, and refusing here would make that path untestable.

	public Result<IMeshPipeline> CreateMeshPipeline(MeshPipelineDesc desc)
	{
		let pipeline = new NullMeshPipeline();
		pipeline.Layout = desc.Layout;
		return .Ok(pipeline);
	}

	public void DestroyMeshPipeline(ref IMeshPipeline pipeline) { delete pipeline; pipeline = null; }

	public Result<IAccelStruct> CreateAccelStruct(AccelStructDesc desc)
	{
		let accelStruct = new NullAccelStruct();
		accelStruct.Initialize(desc);
		return .Ok(accelStruct);
	}

	public void DestroyAccelStruct(ref IAccelStruct accelStruct)
	{
		delete accelStruct;
		accelStruct = null;
	}

	public Result<IRayTracingPipeline> CreateRayTracingPipeline(RayTracingPipelineDesc desc)
	{
		let pipeline = new NullRayTracingPipeline();
		pipeline.Layout = desc.Layout;
		return .Ok(pipeline);
	}

	public void DestroyRayTracingPipeline(ref IRayTracingPipeline pipeline)
	{
		delete pipeline;
		pipeline = null;
	}

	/// Writes zeroes. A shader binding table built from these addresses nothing, which is
	/// right for a backend that traces no rays, and the caller's sizing arithmetic is still
	/// exercised.
	public Result<void> GetShaderGroupHandles(IRayTracingPipeline pipeline, uint32 firstGroup,
		uint32 groupCount, Span<uint8> outData)
	{
		if (!outData.IsEmpty)
			Internal.MemSet(outData.Ptr, 0, outData.Length);
		return .Ok;
	}

	public uint32 ShaderGroupHandleSize => 32;
	public uint32 ShaderGroupHandleAlignment => 32;
	public uint32 ShaderGroupBaseAlignment => 64;

	// ---- lifecycle ----

	/// A null device cannot be lost: there is no driver to reset and no hardware to hang.
	public bool IsLost() => false;

	public void WaitIdle() {}

	/// The adapter that made it owns it, so this does nothing. Deleting itself here would
	/// double free when the backend goes down.
	public void Destroy() {}
}
