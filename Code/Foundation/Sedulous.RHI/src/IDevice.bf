using System;
using Sedulous.Core;

namespace Sedulous.RHI;

/// The central factory: every resource, pipeline and piece of command infrastructure comes
/// from here.
///
/// Creation returns a Result and destruction takes the handle BY REFERENCE and nulls it,
/// which is what stops a destroyed object being used again through a stale variable.
interface IDevice
{
	DeviceType Type { get; }
	DeviceFeatures Features { get; }

	/// What CreateShaderModule expects here: SPIR-V for Vulkan, Null and native wgpu,
	/// DXIL for DX12, WGSL text for a browser. The shader cook picks the blob from this
	/// rather than from the backend's name.
	ShaderFormat PreferredShaderFormat { get; }

	/// True when this backend does NOT flip clip space Y in its viewport.
	///
	/// Vulkan and DX12 use a negative height viewport, which also inverts the front face
	/// winding; WebGPU's viewport cannot take a negative height and so gets no flip. A
	/// screen space pass that unprojects NDC through an inverse view projection, sky,
	/// shadows, ambient occlusion, must negate NDC Y when this is true.
	bool NeedsClipSpaceYFlip { get; }

	// ---- queries ----

	IQueue GetQueue(QueueType type, uint32 index = 0);
	uint32 GetQueueCount(QueueType type);
	FormatSupport GetFormatSupport(TextureFormat format);

	/// The highest MSAA sample count usable for BOTH colour and depth attachments.
	///
	/// Defaults to one, so a backend that has not implemented the query reports no MSAA,
	/// which is the safe answer: views clamp to single sample rather than failing.
	uint32 MaxColorDepthSampleCount => 1;

	/// Whether this EXACT count works for both colour and depth.
	///
	/// Asked per count rather than derived from the maximum, because the valid set is not
	/// simply everything up to the ceiling: WebGPU guarantees only one and four, never two.
	/// A caller must snap an unsupported count rather than assume, since an unsupported one
	/// fails texture and pipeline creation.
	bool SupportsSampleCount(uint32 count) => count <= 1;

	// ---- creation ----

	Result<IBuffer> CreateBuffer(BufferDesc desc);
	Result<ITexture> CreateTexture(TextureDesc desc);
	Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc);
	Result<ISampler> CreateSampler(SamplerDesc desc);
	Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc);
	Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc);
	Result<IBindGroup> CreateBindGroup(BindGroupDesc desc);
	Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc);
	Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc);
	Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc);
	Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc);
	Result<ICommandPool> CreateCommandPool(QueueType queueType);
	Result<IFence> CreateFence(uint64 initialValue);
	Result<IQuerySet> CreateQuerySet(QuerySetDesc desc);
	Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc);

	// ---- destruction ----

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

	// ---- mesh shaders, folded in rather than a separate object ----
	//
	// Folded in because these CREATE things, and creation has always belonged to the
	// device; only the per encoder recording is reached through a cross query. The default
	// refuses, so a backend without mesh shaders implements nothing.

	Result<IMeshPipeline> CreateMeshPipeline(MeshPipelineDesc desc) => .Err;
	void DestroyMeshPipeline(ref IMeshPipeline pipeline) {}

	// ---- ray tracing ----

	/// Shader binding table handle properties, reported by the backend once the device is
	/// created and ray tracing is enabled. A caller sizes and aligns its tables from these,
	/// and they read zero on a device without ray tracing.
	uint32 ShaderGroupHandleSize { get; }
	uint32 ShaderGroupHandleAlignment { get; }
	uint32 ShaderGroupBaseAlignment { get; }

	Result<IAccelStruct> CreateAccelStruct(AccelStructDesc desc) => .Err;
	void DestroyAccelStruct(ref IAccelStruct accelStruct) {}

	Result<IRayTracingPipeline> CreateRayTracingPipeline(
		RayTracingPipelineDesc desc) => .Err;
	void DestroyRayTracingPipeline(ref IRayTracingPipeline pipeline) {}

	/// Copies out the group handles a shader binding table is built from.
	Result<void> GetShaderGroupHandles(IRayTracingPipeline pipeline,
		uint32 firstGroup, uint32 groupCount, Span<uint8> outData) => .Err;

	// ---- lifecycle ----

	/// Whether the device has been LOST, through a GPU hang, a driver reset, or removal.
	///
	/// Sticky: once lost it cannot recover, and the caller must stop submitting and rebuild
	/// it. DX12 asks the device directly; Vulkan latches the error from submit, present and
	/// wait results.
	bool IsLost();

	void WaitIdle();
	void Destroy();
}
