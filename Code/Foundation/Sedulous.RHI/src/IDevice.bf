namespace Sedulous.RHI;

using System;

/// A logical GPU device. Central object for creating and destroying resources.
///
/// Resources are created via Create* methods and destroyed via Destroy* methods.
/// Destroy methods take `ref` and null the reference after destruction.
///
/// Usage:
/// ```
/// let device = adapter.CreateDevice(desc).Value;
/// defer device.Destroy();
///
/// var buffer = device.CreateBuffer(bufDesc).Value;
/// defer device.DestroyBuffer(ref buffer);
/// ```
interface IDevice
{
	// ===== Queues =====

	/// Gets a queue by type and index.
	/// Index 0 for Graphics is always available.
	IQueue GetQueue(QueueType type, uint32 index = 0);

	/// Returns how many queues of the given type are available.
	uint32 GetQueueCount(QueueType type);

	// ===== Resource Creation =====

	/// Creates a GPU buffer.
	Result<IBuffer> CreateBuffer(BufferDesc desc);

	/// Creates a GPU texture.
	Result<ITexture> CreateTexture(TextureDesc desc);

	/// Creates a view into a texture.
	Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc);

	/// Creates a sampler.
	Result<ISampler> CreateSampler(SamplerDesc desc);

	/// Creates a shader module from pre-compiled bytecode.
	Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc);

	// ===== Binding =====

	/// Creates a bind group layout, defining the shape of a bind group.
	Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc);

	/// Creates a bind group — a set of resource bindings matching a layout.
	Result<IBindGroup> CreateBindGroup(BindGroupDesc desc);

	/// Creates a pipeline layout from bind group layouts and push constant ranges.
	Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc);

	// ===== Pipelines =====

	/// Creates a pipeline cache for faster pipeline creation on subsequent runs.
	Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc);

	/// Creates a render (graphics) pipeline.
	Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc);

	/// Creates a compute pipeline.
	Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc);

	// ===== Commands =====

	/// Creates a command pool. One pool per thread per queue type.
	Result<ICommandPool> CreateCommandPool(QueueType queueType);

	// ===== Synchronization =====

	/// Creates a timeline fence with an initial value.
	Result<IFence> CreateFence(uint64 initialValue = 0);

	// ===== Queries =====

	/// Creates a query set for timestamps, occlusion, or pipeline statistics.
	Result<IQuerySet> CreateQuerySet(QuerySetDesc desc);

	// ===== Presentation =====

	/// Creates a swap chain for presenting to a surface.
	Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc);

	// ===== Resource Destruction =====
	// All destroy methods null the reference after destroying.

	void DestroyBuffer(ref IBuffer buffer);
	void DestroyTexture(ref ITexture texture);
	void DestroyTextureView(ref ITextureView view);
	void DestroySampler(ref ISampler sampler);
	void DestroyShaderModule(ref IShaderModule module);
	void DestroyBindGroupLayout(ref IBindGroupLayout layout);
	void DestroyBindGroup(ref IBindGroup group);
	void DestroyPipelineLayout(ref IPipelineLayout layout);
	void DestroyPipelineCache(ref IPipelineCache cache);
	void DestroyRenderPipeline(ref IRenderPipeline pipeline);
	void DestroyComputePipeline(ref IComputePipeline pipeline);
	void DestroyCommandPool(ref ICommandPool pool);
	void DestroyFence(ref IFence fence);
	void DestroyQuerySet(ref IQuerySet querySet);
	void DestroySwapChain(ref ISwapChain swapChain);
	void DestroySurface(ref ISurface surface);

	// ===== Extensions =====

	/// Returns the mesh shader extension, or null if not supported.
	/// Example: `if (let meshExt = device.GetMeshShaderExt()) { ... }`
	IMeshShaderExt GetMeshShaderExt();

	/// Returns the ray tracing extension, or null if not supported.
	/// Example: `if (let rtExt = device.GetRayTracingExt()) { ... }`
	IRayTracingExt GetRayTracingExt();

	// ===== Info =====

	/// Supported features and limits for this device.
	DeviceFeatures Features { get; }

	/// Blocks until all GPU work on all queues has completed.
	void WaitIdle();

	/// Destroys the device and all remaining resources created from it.
	void Destroy();
}
