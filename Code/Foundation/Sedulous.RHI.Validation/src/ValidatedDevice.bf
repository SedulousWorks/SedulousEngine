using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Watches a device: what it is asked to create, what it still owns, and whether it is
/// used after it is destroyed.
///
/// It TRACKS every resource it hands out. That is what turns three silent mistakes into
/// reported ones: destroying something twice, destroying it through the wrong device, and
/// letting the device go while it still owns things.
class ValidatedDevice : IDevice
{
	private IDevice mInner;
	private bool mDestroyed = false;

	private List<ValidatedQueue> mQueues = new .() ~ DeleteContainerAndItems!(_);
	private List<ValidatedCommandPool> mPools = new .() ~ DeleteContainerAndItems!(_);
	private List<ValidatedFence> mFences = new .() ~ DeleteContainerAndItems!(_);
	private List<ValidatedSwapChain> mSwapChains = new .() ~ DeleteContainerAndItems!(_);

	private List<TrackedResources> mTracked = new .() ~ DeleteContainerAndItems!(_);
	private TrackedResources mBuffers, mTextures, mTextureViews, mSamplers, mShaderModules;
	private TrackedResources mBindGroupLayouts, mBindGroups, mPipelineLayouts, mPipelineCaches;
	private TrackedResources mRenderPipelines, mComputePipelines, mQuerySets;
	private TrackedResources mMeshPipelines, mAccelStructs, mRayTracingPipelines;
	private TrackedResources mCommandPools, mLiveFences, mLiveSwapChains;

	public this(IDevice inner)
	{
		mInner = inner;

		mBuffers = Track("Buffer");
		mTextures = Track("Texture");
		mTextureViews = Track("TextureView");
		mSamplers = Track("Sampler");
		mShaderModules = Track("ShaderModule");
		mBindGroupLayouts = Track("BindGroupLayout");
		mBindGroups = Track("BindGroup");
		mPipelineLayouts = Track("PipelineLayout");
		mPipelineCaches = Track("PipelineCache");
		mRenderPipelines = Track("RenderPipeline");
		mComputePipelines = Track("ComputePipeline");
		mQuerySets = Track("QuerySet");
		mMeshPipelines = Track("MeshPipeline");
		mAccelStructs = Track("AccelStruct");
		mRayTracingPipelines = Track("RayTracingPipeline");
		mCommandPools = Track("CommandPool");
		mLiveFences = Track("Fence");
		mLiveSwapChains = Track("SwapChain");
	}

	private TrackedResources Track(StringView name)
	{
		let tracker = new TrackedResources(name);
		mTracked.Add(tracker);
		return tracker;
	}

	public IDevice Inner => mInner;

	public DeviceType Type => mInner.Type;
	public DeviceFeatures Features => mInner.Features;
	public ShaderFormat PreferredShaderFormat => mInner.PreferredShaderFormat;
	public bool NeedsClipSpaceYFlip => mInner.NeedsClipSpaceYFlip;
	public uint32 MaxColorDepthSampleCount => mInner.MaxColorDepthSampleCount;
	public bool SupportsSampleCount(uint32 count) => mInner.SupportsSampleCount(count);
	public FormatSupport GetFormatSupport(TextureFormat format) => mInner.GetFormatSupport(format);
	public uint32 GetQueueCount(QueueType type) => mInner.GetQueueCount(type);
	public uint32 ShaderGroupHandleSize => mInner.ShaderGroupHandleSize;
	public uint32 ShaderGroupHandleAlignment => mInner.ShaderGroupHandleAlignment;
	public uint32 ShaderGroupBaseAlignment => mInner.ShaderGroupBaseAlignment;

	/// Wrapped on first access and kept, so the same queue always answers with the same
	/// wrapper and its fence bookkeeping is continuous.
	public IQueue GetQueue(QueueType type, uint32 index)
	{
		let inner = mInner.GetQueue(type, index);
		if (inner == null)
			return null;
		for (let existing in mQueues)
		{
			if (existing.Inner === inner)
				return existing;
		}
		let wrapper = new ValidatedQueue(inner);
		mQueues.Add(wrapper);
		return wrapper;
	}

	// ---- creation ----

	public Result<IBuffer> CreateBuffer(BufferDesc desc)
	{
		if (Destroyed("CreateBuffer"))
			return .Err;
		if (desc.Size == 0)
		{
			ValidationLog.Error("Device.CreateBuffer: size is zero");
			return .Err;
		}
		// A DX12 upload heap cannot allow unordered access, so read write storage on CPU
		// visible memory fails there while working elsewhere. StorageRead is the way to
		// have a mappable buffer a shader reads.
		if ((desc.Memory == .CpuToGpu) && desc.Usage.HasFlag(.Storage))
		{
			ValidationLog.Error("Device.CreateBuffer: Storage usage is not compatible with CpuToGpu memory. Use StorageRead for a read only buffer, or GpuOnly with a staging copy.");
			return .Err;
		}
		if ((desc.Memory == .GpuToCpu) && desc.Usage.HasFlag(.Storage))
		{
			ValidationLog.Error("Device.CreateBuffer: Storage usage is not compatible with GpuToCpu memory. A DX12 readback heap cannot allow unordered access.");
			return .Err;
		}
		return TrackCreated(mInner.CreateBuffer(desc), mBuffers);
	}

	public Result<ITexture> CreateTexture(TextureDesc desc)
	{
		if (Destroyed("CreateTexture"))
			return .Err;
		if ((desc.Width == 0) || (desc.Height == 0))
		{
			ValidationLog.Error("Device.CreateTexture: width or height is zero");
			return .Err;
		}
		return TrackCreated(mInner.CreateTexture(desc), mTextures);
	}

	/// The use after destroy check: a texture the device does not know about was either
	/// already destroyed or came from somewhere else, and viewing it reads freed memory.
	public Result<ITextureView> CreateTextureView(ITexture texture, TextureViewDesc desc)
	{
		if (Destroyed("CreateTextureView"))
			return .Err;
		if (texture == null)
		{
			ValidationLog.Error("Device.CreateTextureView: texture is null");
			return .Err;
		}
		if (!mTextures.Contains(texture))
			ValidationLog.Error("Device.CreateTextureView: the texture was destroyed, or was not created by this device");
		return TrackCreated(mInner.CreateTextureView(texture, desc), mTextureViews);
	}

	public Result<ISampler> CreateSampler(SamplerDesc desc)
	{
		if (Destroyed("CreateSampler"))
			return .Err;
		return TrackCreated(mInner.CreateSampler(desc), mSamplers);
	}

	public Result<IShaderModule> CreateShaderModule(ShaderModuleDesc desc)
	{
		if (Destroyed("CreateShaderModule"))
			return .Err;
		if (desc.Code.IsEmpty)
		{
			ValidationLog.Error("Device.CreateShaderModule: code is empty");
			return .Err;
		}
		return TrackCreated(mInner.CreateShaderModule(desc), mShaderModules);
	}

	public Result<IBindGroupLayout> CreateBindGroupLayout(BindGroupLayoutDesc desc)
	{
		if (Destroyed("CreateBindGroupLayout"))
			return .Err;
		return TrackCreated(mInner.CreateBindGroupLayout(desc), mBindGroupLayouts);
	}

	/// The entries are POSITIONAL against the layout's non bindless slots, so a count
	/// mismatch silently binds every resource one slot out.
	public Result<IBindGroup> CreateBindGroup(BindGroupDesc desc)
	{
		if (Destroyed("CreateBindGroup"))
			return .Err;
		if (desc.Layout == null)
		{
			ValidationLog.Error("Device.CreateBindGroup: layout is null");
			return .Err;
		}

		let layoutEntries = desc.Layout.Entries;
		int regularCount = 0;
		for (let entry in layoutEntries)
		{
			if (!IsBindless(entry.Type))
				regularCount++;
		}

		if (desc.Entries.Length != regularCount)
		{
			ValidationLog.Error(scope $"Device.CreateBindGroup: entry count ({desc.Entries.Length}) does not match the layout's non bindless entry count ({regularCount})");
			return .Err;
		}

		int entryIndex = 0;
		for (int i = 0; (i < layoutEntries.Length) && (entryIndex < desc.Entries.Length); i++)
		{
			let layoutEntry = layoutEntries[i];
			if (IsBindless(layoutEntry.Type))
				continue;

			let entry = desc.Entries[entryIndex];
			switch (layoutEntry.Type)
			{
			case .UniformBuffer, .StorageBufferReadOnly, .StorageBufferReadWrite:
				if (entry.Buffer == null)
					ValidationLog.Error(scope $"Device.CreateBindGroup: entry [{entryIndex}] expects a buffer but it is null");
			case .SampledTexture, .StorageTextureReadOnly, .StorageTextureReadWrite:
				if (entry.TextureView == null)
					ValidationLog.Error(scope $"Device.CreateBindGroup('{desc.Label}'): entry [{entryIndex}] expects a texture view but it is null");
			case .Sampler, .ComparisonSampler:
				if (entry.Sampler == null)
					ValidationLog.Error(scope $"Device.CreateBindGroup: entry [{entryIndex}] expects a sampler but it is null");
			case .AccelerationStructure:
				if (entry.AccelStruct == null)
					ValidationLog.Error(scope $"Device.CreateBindGroup: entry [{entryIndex}] expects an acceleration structure but it is null");
			default:
			}
			entryIndex++;
		}

		return TrackCreated(mInner.CreateBindGroup(desc), mBindGroups);
	}

	public Result<IPipelineLayout> CreatePipelineLayout(PipelineLayoutDesc desc)
	{
		if (Destroyed("CreatePipelineLayout"))
			return .Err;
		return TrackCreated(mInner.CreatePipelineLayout(desc), mPipelineLayouts);
	}

	public Result<IPipelineCache> CreatePipelineCache(PipelineCacheDesc desc)
	{
		if (Destroyed("CreatePipelineCache"))
			return .Err;
		return TrackCreated(mInner.CreatePipelineCache(desc), mPipelineCaches);
	}

	public Result<IRenderPipeline> CreateRenderPipeline(RenderPipelineDesc desc)
	{
		if (Destroyed("CreateRenderPipeline"))
			return .Err;
		if (desc.Layout == null)
		{
			ValidationLog.Error("Device.CreateRenderPipeline: layout is null");
			return .Err;
		}
		if (desc.Vertex.Shader.Module == null)
		{
			ValidationLog.Error("Device.CreateRenderPipeline: the vertex shader module is null");
			return .Err;
		}
		return TrackCreated(mInner.CreateRenderPipeline(desc), mRenderPipelines);
	}

	public Result<IComputePipeline> CreateComputePipeline(ComputePipelineDesc desc)
	{
		if (Destroyed("CreateComputePipeline"))
			return .Err;
		if (desc.Layout == null)
		{
			ValidationLog.Error("Device.CreateComputePipeline: layout is null");
			return .Err;
		}
		if (desc.Compute.Module == null)
		{
			ValidationLog.Error("Device.CreateComputePipeline: the compute shader module is null");
			return .Err;
		}
		return TrackCreated(mInner.CreateComputePipeline(desc), mComputePipelines);
	}

	public Result<IQuerySet> CreateQuerySet(QuerySetDesc desc)
	{
		if (Destroyed("CreateQuerySet"))
			return .Err;
		if (desc.Count == 0)
		{
			ValidationLog.Error("Device.CreateQuerySet: count is zero");
			return .Err;
		}
		return TrackCreated(mInner.CreateQuerySet(desc), mQuerySets);
	}

	public Result<ICommandPool> CreateCommandPool(QueueType queueType)
	{
		if (Destroyed("CreateCommandPool"))
			return .Err;
		if (mInner.CreateCommandPool(queueType) case .Ok(let inner))
		{
			let wrapper = new ValidatedCommandPool(inner);
			mPools.Add(wrapper);
			mCommandPools.Add(wrapper);
			return .Ok(wrapper);
		}
		return .Err;
	}

	public Result<IFence> CreateFence(uint64 initialValue)
	{
		if (Destroyed("CreateFence"))
			return .Err;
		if (mInner.CreateFence(initialValue) case .Ok(let inner))
		{
			let wrapper = new ValidatedFence(inner);
			mFences.Add(wrapper);
			mLiveFences.Add(wrapper);
			return .Ok(wrapper);
		}
		return .Err;
	}

	public Result<ISwapChain> CreateSwapChain(ISurface surface, SwapChainDesc desc)
	{
		if (Destroyed("CreateSwapChain"))
			return .Err;
		if (surface == null)
		{
			ValidationLog.Error("Device.CreateSwapChain: surface is null");
			return .Err;
		}
		if ((desc.Width == 0) || (desc.Height == 0))
		{
			ValidationLog.Error("Device.CreateSwapChain: width or height is zero");
			return .Err;
		}
		if (mInner.CreateSwapChain(surface, desc) case .Ok(let inner))
		{
			let wrapper = new ValidatedSwapChain(inner);
			mSwapChains.Add(wrapper);
			mLiveSwapChains.Add(wrapper);
			return .Ok(wrapper);
		}
		return .Err;
	}

	// ---- destruction ----

	public void DestroyBuffer(ref IBuffer x)
	{
		if (Untrack(mBuffers, x, "DestroyBuffer"))
			mInner.DestroyBuffer(ref x);
		x = null;
	}
	public void DestroyTexture(ref ITexture x)
	{
		if (Untrack(mTextures, x, "DestroyTexture"))
			mInner.DestroyTexture(ref x);
		x = null;
	}
	public void DestroyTextureView(ref ITextureView x)
	{
		if (Untrack(mTextureViews, x, "DestroyTextureView"))
			mInner.DestroyTextureView(ref x);
		x = null;
	}
	public void DestroySampler(ref ISampler x)
	{
		if (Untrack(mSamplers, x, "DestroySampler"))
			mInner.DestroySampler(ref x);
		x = null;
	}
	public void DestroyShaderModule(ref IShaderModule x)
	{
		if (Untrack(mShaderModules, x, "DestroyShaderModule"))
			mInner.DestroyShaderModule(ref x);
		x = null;
	}
	public void DestroyBindGroupLayout(ref IBindGroupLayout x)
	{
		if (Untrack(mBindGroupLayouts, x, "DestroyBindGroupLayout"))
			mInner.DestroyBindGroupLayout(ref x);
		x = null;
	}
	public void DestroyBindGroup(ref IBindGroup x)
	{
		if (Untrack(mBindGroups, x, "DestroyBindGroup"))
			mInner.DestroyBindGroup(ref x);
		x = null;
	}
	public void DestroyPipelineLayout(ref IPipelineLayout x)
	{
		if (Untrack(mPipelineLayouts, x, "DestroyPipelineLayout"))
			mInner.DestroyPipelineLayout(ref x);
		x = null;
	}
	public void DestroyPipelineCache(ref IPipelineCache x)
	{
		if (Untrack(mPipelineCaches, x, "DestroyPipelineCache"))
			mInner.DestroyPipelineCache(ref x);
		x = null;
	}
	public void DestroyRenderPipeline(ref IRenderPipeline x)
	{
		if (Untrack(mRenderPipelines, x, "DestroyRenderPipeline"))
			mInner.DestroyRenderPipeline(ref x);
		x = null;
	}
	public void DestroyComputePipeline(ref IComputePipeline x)
	{
		if (Untrack(mComputePipelines, x, "DestroyComputePipeline"))
			mInner.DestroyComputePipeline(ref x);
		x = null;
	}
	public void DestroyQuerySet(ref IQuerySet x)
	{
		if (Untrack(mQuerySets, x, "DestroyQuerySet"))
			mInner.DestroyQuerySet(ref x);
		x = null;
	}
	public void DestroySurface(ref ISurface x) => mInner.DestroySurface(ref x);

	public void DestroyCommandPool(ref ICommandPool pool)
	{
		if (pool == null)
			return;
		let tracked = Untrack(mCommandPools, pool, "DestroyCommandPool");
		if (let validated = pool as ValidatedCommandPool)
		{
			var inner = validated.Inner;
			if (tracked)
				mInner.DestroyCommandPool(ref inner);
			mPools.Remove(validated);
			delete validated;
			pool = null;
			return;
		}
		mInner.DestroyCommandPool(ref pool);
	}

	public void DestroyFence(ref IFence fence)
	{
		if (fence == null)
			return;
		let tracked = Untrack(mLiveFences, fence, "DestroyFence");
		if (let validated = fence as ValidatedFence)
		{
			var inner = validated.Inner;
			if (tracked)
				mInner.DestroyFence(ref inner);
			mFences.Remove(validated);
			delete validated;
			fence = null;
			return;
		}
		mInner.DestroyFence(ref fence);
	}

	public void DestroySwapChain(ref ISwapChain swapChain)
	{
		if (swapChain == null)
			return;
		let tracked = Untrack(mLiveSwapChains, swapChain, "DestroySwapChain");
		if (let validated = swapChain as ValidatedSwapChain)
		{
			var inner = validated.Inner;
			if (tracked)
				mInner.DestroySwapChain(ref inner);
			mSwapChains.Remove(validated);
			delete validated;
			swapChain = null;
			return;
		}
		mInner.DestroySwapChain(ref swapChain);
	}

	// ---- extensions ----

	public Result<IMeshPipeline> CreateMeshPipeline(MeshPipelineDesc desc)
	{
		if (Destroyed("CreateMeshPipeline"))
			return .Err;
		return TrackCreated(mInner.CreateMeshPipeline(desc), mMeshPipelines);
	}

	public void DestroyMeshPipeline(ref IMeshPipeline x)
	{
		if (Untrack(mMeshPipelines, x, "DestroyMeshPipeline"))
			mInner.DestroyMeshPipeline(ref x);
		x = null;
	}

	public Result<IAccelStruct> CreateAccelStruct(AccelStructDesc desc)
	{
		if (Destroyed("CreateAccelStruct"))
			return .Err;
		return TrackCreated(mInner.CreateAccelStruct(desc), mAccelStructs);
	}

	public void DestroyAccelStruct(ref IAccelStruct x)
	{
		if (Untrack(mAccelStructs, x, "DestroyAccelStruct"))
			mInner.DestroyAccelStruct(ref x);
		x = null;
	}

	public Result<IRayTracingPipeline> CreateRayTracingPipeline(RayTracingPipelineDesc desc)
	{
		if (Destroyed("CreateRayTracingPipeline"))
			return .Err;
		return TrackCreated(mInner.CreateRayTracingPipeline(desc), mRayTracingPipelines);
	}

	public void DestroyRayTracingPipeline(ref IRayTracingPipeline x)
	{
		if (Untrack(mRayTracingPipelines, x, "DestroyRayTracingPipeline"))
			mInner.DestroyRayTracingPipeline(ref x);
		x = null;
	}

	public Result<void> GetShaderGroupHandles(IRayTracingPipeline pipeline, uint32 firstGroup,
		uint32 groupCount, Span<uint8> outData)
		=> mInner.GetShaderGroupHandles(pipeline, firstGroup, groupCount, outData);

	// ---- lifecycle ----

	public bool IsLost() => mInner.IsLost();

	public void WaitIdle() => mInner.WaitIdle();

	/// Reports whatever is still outstanding before going. A resource outliving its device
	/// is a leak on every backend and a crash on some.
	public void Destroy()
	{
		if (mDestroyed)
		{
			ValidationLog.Error("Device.Destroy: already destroyed");
			return;
		}
		for (let tracker in mTracked)
		{
			if (tracker.Count > 0)
				ValidationLog.Warn(scope $"Device destroyed with {tracker.Count} live {tracker.Name}(s)");
		}
		mDestroyed = true;
		mInner.Destroy();
	}

	public int LiveCount(StringView kind)
	{
		for (let tracker in mTracked)
		{
			if (tracker.Name == kind)
				return tracker.Count;
		}
		return -1;
	}

	// ---- helpers ----

	private static bool IsBindless(BindingType type)
	{
		switch (type)
		{
		case .BindlessTextures, .BindlessSamplers, .BindlessStorageBuffers,
			.BindlessStorageTextures:
			return true;
		default:
			return false;
		}
	}

	private Result<T> TrackCreated<T>(Result<T> result, TrackedResources tracker) where T : class
	{
		if (result case .Ok(let value))
			tracker.Add(value);
		return result;
	}

	/// Takes a resource out of tracking, and says whether the destroy should go through.
	///
	/// An untracked object is a double destroy, or one from another device. The destroy is
	/// then NOT forwarded: freeing it again is a double free, and turning a mistake this
	/// layer just detected into a crash is the opposite of its job. Raptor forwards and
	/// relies on the allocator to survive it; refusing is the safer read of the same rule.
	private bool Untrack(TrackedResources tracker, Object resource, StringView operation)
	{
		if (resource == null)
			return false;
		if (tracker.Remove(resource))
			return true;
		ValidationLog.Warn(scope $"Device.{operation}: the resource was not tracked, so it is a double destroy or belongs to another device");
		return false;
	}

	private bool Destroyed(StringView operation)
	{
		if (!mDestroyed)
			return false;
		ValidationLog.Error(scope $"Device.{operation}: the device is destroyed");
		return true;
	}
}
