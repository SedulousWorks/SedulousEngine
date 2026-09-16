using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// The device.
///
/// Handles the device and queue lifecycle - creation, the loss latch, WaitIdle, fences,
/// destruction - and is the factory for everything else. A factory WebGPU cannot support
/// returns an HONEST error: callers get failures, never silent fakes.
sealed class WebGpuDevice : IDevice
{
	private WGPUInstance mInstance;
	private WGPUAdapter mAdapter;
	private WGPUDevice mDevice;
	private DeviceFeatures mFeatures = .();

	private WebGpuBlitHelper mBlitHelper = new .() ~ delete _;
	private WebGpuBufferRegistry mBufferRegistry = new .() ~ delete _;

	// ONE WebGPU queue, three RHI typed views of it. See WebGpuQueue.
	private WebGpuQueue mGraphicsQueue = new .() ~ delete _;
	private WebGpuQueue mComputeQueue = new .() ~ delete _;
	private WebGpuQueue mTransferQueue = new .() ~ delete _;

	/// The adapter's lost callback record. OWNED from AdoptLostRoute onward.
	private WebGpuDeviceLostRoute mLostRoute = null;

	private bool mLost = false;
	private bool mImmediatesSupported = false;
	private bool mForceUniformPushConstants = false;
	/// ENV_WEBGPU_WGSL: take the browser's WGSL path on desktop.
	private bool mForceWgsl = false;
	private bool mDestroyed = false;

	public WGPUDevice Handle => mDevice;
	public WGPUInstance Instance => mInstance;
	public WebGpuBlitHelper BlitHelper => mBlitHelper;

	public this(WGPUInstance instance, WGPUAdapter adapter, WGPUDevice device)
	{
		mInstance = instance;
		mAdapter = adapter;
		mDevice = device;

		let queue = wgpuDeviceGetQueue(mDevice);
		mGraphicsQueue.Initialize(instance, device, queue, .Graphics, mBufferRegistry);
		mComputeQueue.Initialize(instance, device, queue, .Compute, mBufferRegistry);
		mTransferQueue.Initialize(instance, device, queue, .Transfer, mBufferRegistry);
		mBlitHelper.Initialize(device);

		// DEBUG: force the FULL browser shader path on desktop wgpu-native - WGSL text AND
		// push constant emulation. See PreferredShaderFormat. The WGSL cook always emulates
		// push constants, browsers rejecting var<push_constant>, so the layout has to
		// emulate too or the emulated group N binding zero block mismatches a layout built
		// for native immediates.
		let raw = scope String();
		mForceWgsl = (Environment.GetEnvironmentVariable("ENV_WEBGPU_WGSL", raw) case .Ok);
		if (mForceWgsl)
			mForceUniformPushConstants = true;

		// Said out loud, the way the swap chain names its format: which shader path a run
		// took is otherwise invisible.
		//
		// This is what the device PREFERS, which is not always what it is handed. The
		// shader system honours it only on the cooked pack path; its on demand compile
		// emits SPIR-V for anything that is not DX12, whatever this says. So a forced WGSL
		// run with no pack present still runs SPIR-V, and only works because ingestion is
		// available - which it will not be in a browser.
		Console.WriteLine("[webgpu] shaders: prefers {} (SPIR-V ingestion {})",
			mForceWgsl ? "WGSL with push constants emulated (ENV_WEBGPU_WGSL)" : "SPIR-V",
			WebGpuApi.SpirvIngestion ? "available" : "unavailable");
	}

	public ~this()
	{
		Destroy();
	}

	/// The device lost callback, registered at creation by the adapter, lands here.
	public void MarkLost()
	{
		mLost = true;
	}

	/// Takes ownership of the adapter's lost callback record. Freed in Destroy, after the
	/// wgpu device is released and pending callbacks are flushed; see the ordering note
	/// there.
	public void AdoptLostRoute(WebGpuDeviceLostRoute route)
	{
		mLostRoute = route;
	}

	/// Set by the adapter: whether the device carries the Immediates feature, which is
	/// push constant support. A pipeline layout with ranges fails without it.
	public void SetImmediatesSupported(bool supported)
	{
		mImmediatesSupported = supported;
	}

	/// Set by the adapter, which stamps what the adapter reported.
	public void SetFeatures(DeviceFeatures features)
	{
		mFeatures = features;
	}

	/// Forces the uniform buffer push constant fallback even where immediates exist. Web
	/// always emulates, Dawn having no immediates, and this lets a desktop test exercise
	/// the same path against a real GPU. See WebGpuPipelineLayout and the pass encoders.
	public void SetForceUniformPushConstants(bool force)
	{
		mForceUniformPushConstants = force;
	}

	/// Whether push constants are emulated as a bound uniform buffer on this device - no
	/// immediates, or the fallback forced - rather than issued through SetImmediates.
	public bool EmulatesPushConstants => mForceUniformPushConstants || !mImmediatesSupported;

	public DeviceType Type => .WebGPU;
	public DeviceFeatures Features => mFeatures;

	/// SPIR-V ingestion is a wgpu-native instance feature that a browser never exposes, so
	/// there the cook has to feed WGSL text instead.
	///
	/// DEBUG override: ENV_WEBGPU_WGSL forces the WGSL path on desktop wgpu-native, so a
	/// desktop run exercises the EXACT browser shaders - WGSL through naga's frontend -
	/// instead of SPIR-V ingestion. A faithful, fast repro for a web render bug. Needs a
	/// WGSL shader pack.
	public ShaderFormat PreferredShaderFormat
	{
		get
		{
			if (mForceWgsl)
				return .WGSL;

			return WebGpuApi.SpirvIngestion ? .SpirV : .WGSL;
		}
	}

	/// False: WebGPU's raster orientation matches Vulkan's on BOTH shader paths, which the
	/// render backend probes prove. wgpu's runtime SPIR-V frontend applies no clip space
	/// adjustment, and the WGSL cook passes naga --keep-coordinate-space so the cooked WGSL
	/// carries the same convention. No pass needs a Y compensation on this backend.
	public bool NeedsClipSpaceYFlip => false;

	// Ray tracing has no WebGPU shape at all, so the handle sizes are zero and every
	// creation path takes IDevice's refusing default.
	public uint32 ShaderGroupHandleSize => 0;
	public uint32 ShaderGroupHandleAlignment => 0;
	public uint32 ShaderGroupBaseAlignment => 0;

	// ---- queries ----
	public IQueue GetQueue(QueueType type, uint32 index)
	{
		if (index != 0)
			return null;

		switch (type)
		{
		case .Graphics: return mGraphicsQueue;
		case .Compute: return mComputeQueue;
		case .Transfer: return mTransferQueue;
		}
	}

	public uint32 GetQueueCount(QueueType type)
	{
		return 1;
	}

	/// WebGPU guarantees 4x for the colour and depth formats the renderer uses; 8x is not
	/// a WebGPU capability. So the engine's ceiling is always available here.
	public uint32 MaxColorDepthSampleCount => 4;

	/// WebGPU guarantees ONLY 1 and 4 for the renderer's colour and depth formats. 2x is
	/// NOT guaranteed - it needs the adapter specific format features, which are not
	/// enabled - so creating a 2 sample texture or pipeline aborts the device. Callers snap
	/// 2x to 1x off this.
	public bool SupportsSampleCount(uint32 count)
	{
		return (count == 1) || (count == 4);
	}

	public FormatSupport GetFormatSupport(TextureFormat format)
	{
		// WebGPU's per format capabilities are SPEC tables rather than driver queries, so
		// this encodes the classes the renderer asks about.
		switch (format)
		{
		case .Undefined:
			return .Unsupported;

		// Depth and stencil family.
		case .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8, .Depth32Float,
			.Depth32FloatStencil8, .Stencil8:
			return .Texture | .DepthStencil;

		// BC block formats: sampled only, feature gated.
		case .BC1RGBAUnorm, .BC1RGBAUnormSrgb, .BC2RGBAUnorm, .BC2RGBAUnormSrgb,
			.BC3RGBAUnorm, .BC3RGBAUnormSrgb, .BC4RUnorm, .BC4RSnorm, .BC5RGUnorm,
			.BC5RGSnorm, .BC6HRGBUfloat, .BC6HRGBFloat, .BC7RGBAUnorm, .BC7RGBAUnormSrgb:
			return mFeatures.TextureCompressionBC ? (.Texture | .LinearFilter) : .Unsupported;

		// ASTC block formats, which is the mobile browser family: sampled only, feature
		// gated.
		case .ASTC4x4Unorm, .ASTC4x4UnormSrgb, .ASTC5x5Unorm, .ASTC5x5UnormSrgb,
			.ASTC6x6Unorm, .ASTC6x6UnormSrgb, .ASTC8x8Unorm, .ASTC8x8UnormSrgb:
			return mFeatures.TextureCompressionASTC ? (.Texture | .LinearFilter)
				: .Unsupported;

		// 16 bit norm formats have no core WebGPU equivalent at all.
		case .RGBA16Unorm, .RGBA16Snorm:
			return .Unsupported;

		// 32 bit float family: renderable and storage, NOT filterable in core.
		case .R32Float, .RG32Float, .RGBA32Float:
			return .Texture | .ColorAttachment | .StorageTexture;

		// Integer formats: renderable, never blendable or filterable.
		case .R8Uint, .R8Sint, .R16Uint, .R16Sint, .R32Uint, .R32Sint, .RG8Uint, .RG8Sint,
			.RG16Uint, .RG16Sint, .RG32Uint, .RG32Sint, .RGBA8Uint, .RGBA8Sint, .RGBA16Uint,
			.RGBA16Sint, .RGBA32Uint, .RGBA32Sint, .RGB10A2Uint:
			return .Texture | .ColorAttachment;

		// Snorm, shared exponent and packed float oddballs: sampled and filterable.
		// RG11B10 is additionally renderable through a feature on some runtimes, so this
		// stays conservatively sampled only.
		case .R8Snorm, .RG8Snorm, .RGBA8Snorm, .RGB9E5Float, .RG11B10Float:
			return .Texture | .LinearFilter;

		// Everything else in the RHI's list is the classic filterable, renderable,
		// blendable colour family.
		default:
			return .Texture | .ColorAttachment | .BlendableColor | .LinearFilter;
		}
	}

	// ---- creation ----
	public Result<IBuffer> CreateBuffer(BufferDesc desc)
	{
		let buffer = new WebGpuBuffer();
		if (buffer.Initialize(mInstance, mDevice, mGraphicsQueue.Handle, desc) case .Err)
		{
			delete buffer;
			return .Err;
		}

		mBufferRegistry.Add(buffer);
		return .Ok(buffer);
	}

	public Result<ITexture> CreateTexture(TextureDesc desc)
	{
		let texture = new WebGpuTexture();
		if (texture.Initialize(mDevice, desc) case .Err)
		{
			delete texture;
			return .Err;
		}

		return .Ok(texture);
	}

	public Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc)
	{
		let wgpuTexture = texture as WebGpuTexture;
		if (wgpuTexture == null)
			return .Err;

		let view = new WebGpuTextureView();
		if (view.Initialize(wgpuTexture.Handle, texture, desc) case .Err)
		{
			delete view;
			return .Err;
		}

		return .Ok(view);
	}

	public Result<ISampler> CreateSampler(SamplerDesc desc)
	{
		let sampler = new WebGpuSampler();
		if (sampler.Initialize(mDevice, desc) case .Err)
		{
			delete sampler;
			return .Err;
		}

		return .Ok(sampler);
	}

	public Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc)
	{
		let module = new WebGpuShaderModule();
		if (module.Initialize(mDevice, desc) case .Err)
		{
			delete module;
			return .Err;
		}

		return .Ok(module);
	}

	public Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc)
	{
		let layout = new WebGpuBindGroupLayout();
		if (layout.Initialize(mDevice, desc) case .Err)
		{
			delete layout;
			return .Err;
		}

		return .Ok(layout);
	}

	public Result<IBindGroup> CreateBindGroup(BindGroupDesc desc)
	{
		let group = new WebGpuBindGroup();
		if (group.Initialize(mDevice, desc) case .Err)
		{
			delete group;
			return .Err;
		}

		return .Ok(group);
	}

	public Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc)
	{
		let layout = new WebGpuPipelineLayout();
		if (layout.Initialize(mDevice, desc, EmulatesPushConstants) case .Err)
		{
			delete layout;
			return .Err;
		}

		return .Ok(layout);
	}

	/// No cache object exists in WebGPU, so a benign empty stand in keeps callers happy.
	public Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc)
	{
		return .Ok(new WebGpuPipelineCache());
	}

	public Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc)
	{
		let pipeline = new WebGpuRenderPipeline();
		if (pipeline.Initialize(mDevice, desc) case .Err)
		{
			delete pipeline;
			return .Err;
		}

		return .Ok(pipeline);
	}

	public Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc)
	{
		let pipeline = new WebGpuComputePipeline();
		if (pipeline.Initialize(mDevice, desc) case .Err)
		{
			delete pipeline;
			return .Err;
		}

		return .Ok(pipeline);
	}

	/// Every queue type funnels into the ONE WebGPU queue, so a pool is bookkeeping.
	public Result<ICommandPool> CreateCommandPool(QueueType queueType)
	{
		let pool = new WebGpuCommandPool();
		pool.Initialize(mDevice, mBlitHelper);
		return .Ok(pool);
	}

	public Result<IFence> CreateFence(uint64 initialValue)
	{
		return .Ok(new WebGpuFence(mInstance, mDevice, initialValue));
	}

	public Result<IQuerySet> CreateQuerySet(QuerySetDesc desc)
	{
		let querySet = new WebGpuQuerySet();
		if (querySet.Initialize(mDevice, desc) case .Err)
		{
			delete querySet;
			return .Err;
		}

		return .Ok(querySet);
	}

	public Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc)
	{
		let wgpuSurface = surface as WebGpuSurface;
		if (wgpuSurface == null)
			return .Err;

		let swapChain = new WebGpuSwapChain();
		if (swapChain.Initialize(mAdapter, mDevice, mGraphicsQueue, wgpuSurface, desc) case .Err)
		{
			delete swapChain;
			return .Err;
		}

		return .Ok(swapChain);
	}

	// ---- destruction ----
	//
	// Every path tolerates the null a failed creation handed out.
	public void DestroyBuffer(ref IBuffer x)
	{
		if (let resource = x as WebGpuBuffer)
		{
			mBufferRegistry.Remove(resource);
			delete resource;
		}

		x = null;
	}

	public void DestroyTexture(ref ITexture x)
	{
		if (let resource = x as WebGpuTexture)
			delete resource;

		x = null;
	}

	public void DestroyTextureView(ref ITextureView x)
	{
		if (let resource = x as WebGpuTextureView)
			delete resource;

		x = null;
	}

	public void DestroySampler(ref ISampler x)
	{
		if (let resource = x as WebGpuSampler)
			delete resource;

		x = null;
	}

	public void DestroyShaderModule(ref IShaderModule x)
	{
		if (let resource = x as WebGpuShaderModule)
			delete resource;

		x = null;
	}

	public void DestroyBindGroupLayout(ref IBindGroupLayout x)
	{
		if (let resource = x as WebGpuBindGroupLayout)
			delete resource;

		x = null;
	}

	public void DestroyBindGroup(ref IBindGroup x)
	{
		if (let resource = x as WebGpuBindGroup)
			delete resource;

		x = null;
	}

	public void DestroyPipelineLayout(ref IPipelineLayout x)
	{
		if (let resource = x as WebGpuPipelineLayout)
			delete resource;

		x = null;
	}

	public void DestroyPipelineCache(ref IPipelineCache x)
	{
		if (let resource = x as WebGpuPipelineCache)
			delete resource;

		x = null;
	}

	public void DestroyRenderPipeline(ref IRenderPipeline x)
	{
		if (let resource = x as WebGpuRenderPipeline)
			delete resource;

		x = null;
	}

	public void DestroyComputePipeline(ref IComputePipeline x)
	{
		if (let resource = x as WebGpuComputePipeline)
			delete resource;

		x = null;
	}

	public void DestroyCommandPool(ref ICommandPool x)
	{
		if (let resource = x as WebGpuCommandPool)
			delete resource;

		x = null;
	}

	public void DestroyFence(ref IFence x)
	{
		if (let resource = x as WebGpuFence)
			delete resource;

		x = null;
	}

	public void DestroyQuerySet(ref IQuerySet x)
	{
		if (let resource = x as WebGpuQuerySet)
			delete resource;

		x = null;
	}

	public void DestroySwapChain(ref ISwapChain x)
	{
		if (let resource = x as WebGpuSwapChain)
		{
			resource.Cleanup();
			delete resource;
		}

		x = null;
	}

	/// Nothing to do, and deliberately so: the BACKEND owns every surface it made and
	/// frees them at its own teardown, the same way the Vulkan backend does. Raptor's
	/// device deletes the surface here instead, because its backend keeps no list; doing
	/// both is a double free, and a host that calls this before Destroy hits it every
	/// time.
	public void DestroySurface(ref ISurface x)
	{
		x = null;
	}

	// ---- lifecycle ----
	public bool IsLost()
	{
		return mLost;
	}

	public void WaitIdle()
	{
		// A blocking DevicePoll drains the queue. This is the one place it is allowed to
		// block: WaitIdle waits on everything submitted, so an empty queue returns rather
		// than hanging the way a bare pending map would. On web, where the extension does
		// not exist, the queue wrapper's callback pump does the same job.
		WebGpuApi.NativeOnly.DevicePollWaitIdle(mDevice);
	}

	public void Destroy()
	{
		if (mDestroyed)
			return;

		mDestroyed = true;

		mBlitHelper.Release();
		wgpuQueueRelease(mGraphicsQueue.Handle);
		wgpuDeviceRelease(mDevice);

		// The route is freed ONLY after the device is released and its pending callbacks
		// are delivered. An orderly release fires the lost callback with reason Destroyed,
		// which never reads the route, and a REAL loss queued before this point is flushed
		// by the pump below - after which no callback can target this device, so the route
		// cannot be read again.
		if (mLostRoute != null)
		{
			wgpuInstanceProcessEvents(mInstance);
			DeleteAndNullify!(mLostRoute);
		}

		mDevice = null;
	}
}
